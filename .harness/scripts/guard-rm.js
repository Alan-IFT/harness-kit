"use strict";
/**
 * guard-rm — destructive-command PreToolUse guard for Claude Code.
 * TypeScript port of guard-rm.{sh,ps1} (v2 migration, stage 2).
 *
 * Invoked by settings hooks.PreToolUse before every Bash tool call. Reads the tool
 * input as JSON on stdin; exits 0 to allow, 2 to BLOCK with a stderr message.
 *
 * Blocks when ANY destructive verb (rm / rmdir / unlink / Remove-Item / del /
 * erase / Clear-RecycleBin / shred / srm / find -delete) targets a path that
 * resolves OUTSIDE the nearest .git/ ancestor of cwd.
 *
 * The rule is evaluated at EVERY command position — not just the first token of
 * each top-level pipe segment. Positions reached through `;`, `&&`, `||`, `&`, a
 * newline, a subshell/brace group, a command or process substitution, an
 * argv-carrier (`xargs`, `env`, `timeout`, `find -exec`, …) or a nested
 * interpreter (`bash -c`, `pwsh -c`, …) are all judged.
 *
 * Override: prepend `HARNESS_ALLOW_OUTSIDE_RM=1 ` to the command, or set it in the
 * hook process environment, for a single call.
 *
 * THIS IS A FAIL-CLOSED HOOK. Both failure modes are silent and asymmetric: an
 * uncaught throw exits non-zero and reads as a BLOCK, killing every subsequent Bash
 * call including the one that would fix it; a wrong ALLOW leaves no trace at all.
 * Structural doubt therefore resolves to BLOCK — see `parseFailed`.
 *
 * The section numbers below match the shell original so the two can be diffed by
 * eye. Equivalence is enforced mechanically by `tools/diff-guard-rm.sh`, which
 * drives both implementations over the 87-case corpus in evals/guard-rm-cases.md.
 *
 * See `.harness/rules/75-safety-hook.md` for the full contract and disable path.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.tokenize = tokenize;
exports.splitPipes = splitPipes;
exports.splitPositions = splitPositions;
exports.hasScannerTrigger = hasScannerTrigger;
exports.resolveLeaf = resolveLeaf;
exports.isDescendant = isDescendant;
exports.skipPrefix = skipPrefix;
exports.extractCommand = extractCommand;
exports.main = main;
const fs = require("node:fs");
const path = require("node:path");
const MAX_COMMAND = 8192;
const MAX_ECHOED_COMMAND = 300;
const MAX_DEPTH = 2;
/** Verb sets. Bash verbs are matched case-insensitively, as the shell twin does. */
const DESTRUCTIVE_VERBS = new Set([
    'rm',
    'rmdir',
    'unlink',
    'remove-item',
    'del',
    'erase',
    'clear-recyclebin',
    'shred',
    'srm',
]);
/**
 * Argv-carrier verbs. NOT destructive: they never cause a block by themselves,
 * they only expose further command positions. Exact, case-sensitive POSIX names.
 */
const CARRIER_VERBS = new Set([
    'xargs',
    'env',
    'nohup',
    'nice',
    'time',
    'timeout',
    'command',
    'exec',
    'find',
]);
const PWSH_VERBS = new Set(['pwsh', 'powershell']);
const SHELL_VERBS = new Set(['bash', 'sh', 'dash', 'zsh', 'ksh']);
const RESERVED_WORDS = new Set([
    'if', 'then', 'elif', 'else', 'fi', 'while', 'until', 'do', 'done',
    'for', 'select', 'case', 'esac', 'in', 'function', 'coproc', '!', '{', '}',
]);
const isDestructiveVerb = (t) => DESTRUCTIVE_VERBS.has(t.toLowerCase());
const isCarrierVerb = (t) => CARRIER_VERBS.has(t);
const isPwshVerb = (t) => PWSH_VERBS.has(t.toLowerCase());
const isShellVerb = (t) => SHELL_VERBS.has(t.toLowerCase());
/** Mutable judgement state, mirroring the shell twin's globals. */
let parseFailed = false;
let segmentOffending = [];
let repoRoot = '';
// ---------------------------------------------------------------- 5. tokenizer
/**
 * Whitespace-aware quote tokenizer. Quotes toggle state and are dropped, so `''`
 * still yields one (empty) token. Returns null on unbalanced quotes.
 */
function tokenize(s) {
    const tokens = [];
    let cur = '';
    let inSingle = false;
    let inDouble = false;
    let hasContent = false;
    for (let i = 0; i < s.length; i++) {
        const ch = s[i];
        if (!inSingle && !inDouble && (ch === ' ' || ch === '\t')) {
            if (hasContent) {
                tokens.push(cur);
                cur = '';
                hasContent = false;
            }
            continue;
        }
        if (!inDouble && ch === "'") {
            inSingle = !inSingle;
            hasContent = true;
            continue;
        }
        if (!inSingle && ch === '"') {
            inDouble = !inDouble;
            hasContent = true;
            continue;
        }
        cur += ch;
        hasContent = true;
    }
    if (inSingle || inDouble)
        return null;
    if (hasContent)
        tokens.push(cur);
    return tokens;
}
const trim = (s) => s.replace(/^[ \t\n\r\f\v]+/, '').replace(/[ \t\n\r\f\v]+$/, '');
// ------------------------------------------------------------- 6. pipe splitter
/** Split top-level pipes (not inside quotes). Quote characters are retained. */
function splitPipes(s) {
    const segs = [];
    let cur = '';
    let inSingle = false;
    let inDouble = false;
    for (let i = 0; i < s.length; i++) {
        const ch = s[i];
        if (!inDouble && ch === "'")
            inSingle = !inSingle;
        if (!inSingle && ch === '"')
            inDouble = !inDouble;
        if (ch === '|' && !inSingle && !inDouble) {
            segs.push(trim(cur));
            cur = '';
            continue;
        }
        cur += ch;
    }
    segs.push(trim(cur));
    return segs;
}
/** Bytes the dispatch rows react to. Anything else is appended verbatim (row 24). */
const SPECIAL = new Set(['\\', "'", '"', '`', '$', '<', '>', '&', '|', ';', '(', ')', '{', '}', '#', '\n', '\r']);
/**
 * Single-pass lexer emitting the substrings at which a shell would begin parsing a
 * simple command. It never resolves paths, never looks at verbs and never forks.
 *
 * CMDSUB/BQ/PROCSUB/GROUP_PAREN/GROUP_BRACE count toward the depth bound (2);
 * PARAM/ARITH/VPAREN/VBRACE do not — they exist only so their closer is matched
 * rather than read as a separator.
 *
 * Returns null on unresolvable structure; the caller then blocks, fail-closed.
 */
function splitPositions(s) {
    const positions = [];
    let buf = '';
    const kinds = [];
    const sbufs = [];
    const sqst = [];
    let depth = 0;
    let st = 'N';
    // Meaningful ONLY while st === 'SQ'; re-set on every SQ entry.
    let sqAnsi = false;
    /**
     * Index at which row 12 last appended a redirection operator. Row 15 uses it
     * instead of the raw byte at i-1. The sentinel MUST stay -2, not -1: row 15
     * compares against `i - 1`, whose domain is {-1, 0, … len-2}, so -1 collides at
     * i === 0 and appends a leading `&` instead of flushing it — fail-OPEN, and `&`
     * is PowerShell's call operator. Pinned by driver rows R4 / R5.
     */
    let redirI = -2;
    const hdq = [];
    const hdstrip = [];
    let hdhead = 0;
    let hdline = '';
    const top = () => (kinds.length > 0 ? kinds[kinds.length - 1] : '');
    const flush = () => {
        const t = trim(buf);
        if (t !== '')
            positions.push(t);
        buf = '';
    };
    const pushV = (kind) => {
        kinds.push(kind);
        sbufs.push('');
        sqst.push('N');
    };
    const popV = () => {
        kinds.pop();
        sbufs.pop();
        sqst.pop();
    };
    /** Returns false when the depth bound would be exceeded → parse failure. */
    const pushCmd = (kind, savedBuf, savedSt) => {
        depth += 1;
        if (depth > MAX_DEPTH)
            return false;
        kinds.push(kind);
        sbufs.push(savedBuf);
        sqst.push(savedSt);
        return true;
    };
    /** Pops a command-bearing frame, returning the saved buffer and quote state. */
    const popCmd = () => {
        const savedBuf = kinds.length > 0 ? sbufs[sbufs.length - 1] : '';
        const savedSt = kinds.length > 0 ? sqst[sqst.length - 1] : 'N';
        depth -= 1;
        popV();
        return { buf: savedBuf, st: savedSt };
    };
    const len = s.length;
    let i = 0;
    while (i < len) {
        const ch = s[i];
        const frame = top();
        // ---- verbatim frames: copy bytes until the matching closer ----
        if (frame === 'PARAM' || frame === 'ARITH' || frame === 'VPAREN' || frame === 'VBRACE') {
            if (ch === '\\') {
                buf += s.substr(i, 2);
                i += 2;
                continue;
            }
            if (ch === '$') {
                if (s.substr(i, 3) === '$((') {
                    buf += '$((';
                    i += 3;
                    pushV('ARITH');
                    continue;
                }
                if (s.substr(i, 2) === '${') {
                    buf += '${';
                    i += 2;
                    pushV('PARAM');
                    continue;
                }
            }
            if (ch === ')' && frame === 'ARITH' && s.substr(i, 2) === '))') {
                buf += '))';
                i += 2;
                popV();
                continue;
            }
            if (ch === '(') {
                buf += '(';
                i += 1;
                pushV('VPAREN');
                continue;
            }
            if (ch === '{') {
                buf += '{';
                i += 1;
                pushV('VBRACE');
                continue;
            }
            if (ch === ')' && frame === 'VPAREN') {
                buf += ')';
                i += 1;
                popV();
                continue;
            }
            if (ch === '}' && (frame === 'PARAM' || frame === 'VBRACE')) {
                buf += '}';
                i += 1;
                popV();
                continue;
            }
            buf += ch;
            i += 1;
            continue;
        }
        // ---- comment: discard bytes to end of line ----
        if (st === 'C') {
            if (ch === '\n' || ch === '\r') {
                flush();
                if (hdhead < hdq.length) {
                    st = 'H';
                    hdline = '';
                }
                else {
                    st = 'N';
                }
            }
            i += 1;
            continue;
        }
        // ---- here-document body: data, never a command position ----
        if (st === 'H') {
            if (ch === '\n' || ch === '\r') {
                let cmpline = hdline;
                if (hdstrip[hdhead] === true)
                    cmpline = cmpline.replace(/^\t+/, '');
                if (cmpline === hdq[hdhead]) {
                    hdhead += 1;
                    if (hdhead >= hdq.length)
                        st = 'N';
                }
                hdline = '';
            }
            else {
                hdline += ch;
            }
            i += 1;
            continue;
        }
        // ---- hoisted row 24: bytes no dispatch row keys on behave alike in N/SQ/DQ ----
        if (!SPECIAL.has(ch)) {
            buf += ch;
            i += 1;
            continue;
        }
        // ---- row 1: backslash ----
        if (ch === '\\') {
            if (st === 'SQ' && !sqAnsi) {
                buf += '\\';
                i += 1;
            }
            else {
                buf += s.substr(i, 2);
                i += 2;
            }
            continue;
        }
        // ---- row 2: single quote ----
        if (ch === "'") {
            if (st === 'N') {
                const prev = i > 0 ? s[i - 1] : '';
                buf += "'";
                st = 'SQ';
                sqAnsi = prev === '$';
            }
            else if (st === 'SQ') {
                buf += "'";
                st = 'N';
            }
            else {
                buf += "'";
            }
            i += 1;
            continue;
        }
        // ---- row 3: double quote ----
        if (ch === '"') {
            if (st === 'N') {
                buf += '"';
                st = 'DQ';
            }
            else if (st === 'DQ') {
                buf += '"';
                st = 'N';
            }
            else {
                buf += '"';
            }
            i += 1;
            continue;
        }
        // ---- SQ: every remaining row is "append" ----
        if (st === 'SQ') {
            buf += ch;
            i += 1;
            continue;
        }
        // ---- row 4: backtick (self-toggling frame; pushes at N and at DQ) ----
        if (ch === '`') {
            if (top() === 'BQ') {
                flush();
                const restored = popCmd();
                buf = restored.buf;
                st = restored.st;
            }
            else {
                if (!pushCmd('BQ', buf, st))
                    return null;
                buf = '';
                st = 'N';
            }
            i += 1;
            continue;
        }
        // Multi-character lookahead is only needed for these lead bytes.
        let two = '';
        let three = '';
        if (ch === '$' || ch === '<' || ch === '>' || ch === '&') {
            two = s.substr(i, 2);
            three = s.substr(i, 3);
        }
        // ---- row 5: $(( ----
        if (three === '$((') {
            buf += three;
            i += 3;
            pushV('ARITH');
            continue;
        }
        // ---- row 6: $( ----
        if (two === '$(') {
            if (!pushCmd('CMDSUB', buf, st))
                return null;
            buf = '';
            st = 'N';
            i += 2;
            continue;
        }
        // ---- row 7: ${ ----
        if (two === '${') {
            buf += two;
            i += 2;
            pushV('PARAM');
            continue;
        }
        // ---- row 9: <<< ----
        if (three === '<<<') {
            buf += '<<<';
            i += 3;
            continue;
        }
        // ---- row 10: << (here-document; NORMAL only) ----
        if (two === '<<' && st === 'N') {
            buf += '<<';
            i += 2;
            let strip = false;
            if (s[i] === '-') {
                strip = true;
                buf += '-';
                i += 1;
            }
            while (i < len && (s[i] === ' ' || s[i] === '\t')) {
                buf += s[i];
                i += 1;
            }
            let w = '';
            const c2 = s[i];
            if (c2 === "'" || c2 === '"') {
                const qch = c2;
                buf += qch;
                i += 1;
                while (i < len && s[i] !== qch) {
                    w += s[i];
                    buf += s[i];
                    i += 1;
                }
                if (i >= len)
                    return null;
                buf += qch;
                i += 1;
            }
            else {
                while (i < len) {
                    let c = s[i];
                    if (c === ' ' || c === '\t' || c === '\n' || c === '\r')
                        break;
                    if (c === ';' || c === '&' || c === '|')
                        break;
                    if (c === '(' || c === ')' || c === '<' || c === '>')
                        break;
                    if (c === '\\') {
                        buf += '\\';
                        i += 1;
                        if (i >= len)
                            break;
                        c = s[i];
                    }
                    w += c;
                    buf += c;
                    i += 1;
                }
            }
            if (w !== '') {
                hdq.push(w);
                hdstrip.push(strip);
            }
            continue;
        }
        // ---- row 11: <( / >( (process substitution; NORMAL only) ----
        if (st === 'N' && (two === '<(' || two === '>(')) {
            if (!pushCmd('PROCSUB', buf, st))
                return null;
            buf = '';
            st = 'N';
            i += 2;
            continue;
        }
        // ---- rows 12-23: NORMAL-only redirections, separators and frames ----
        if (st === 'N') {
            // ---- row 12: plain redirection operator ----
            if (ch === '>' || ch === '<') {
                buf += ch;
                redirI = i;
                i += 1;
                continue;
            }
            if (two === '&&') {
                flush();
                i += 2;
                continue;
            }
            if (two === '&>') {
                buf += '&>';
                i += 2;
                continue;
            }
            // ---- row 15 ----
            if (ch === '&') {
                if (redirI === i - 1)
                    buf += '&';
                else
                    flush();
                i += 1;
                continue;
            }
            if (ch === '|') {
                flush();
                i += 1;
                continue;
            }
            if (ch === ';') {
                flush();
                i += 1;
                continue;
            }
            if (ch === '(') {
                flush();
                if (!pushCmd('GROUP_PAREN', '', 'N'))
                    return null;
                i += 1;
                continue;
            }
            if (ch === ')') {
                const f = top();
                if (f === 'CMDSUB' || f === 'PROCSUB') {
                    flush();
                    const restored = popCmd();
                    buf = restored.buf;
                    st = restored.st;
                }
                else if (f === 'GROUP_PAREN') {
                    flush();
                    popCmd();
                }
                else {
                    // `case` arm terminator and friends: flush, no pop.
                    flush();
                }
                i += 1;
                continue;
            }
            if (ch === '{') {
                if (trim(buf) === '') {
                    flush();
                    if (!pushCmd('GROUP_BRACE', '', 'N'))
                        return null;
                }
                else {
                    buf += '{';
                }
                i += 1;
                continue;
            }
            if (ch === '}') {
                if (top() === 'GROUP_BRACE') {
                    flush();
                    popCmd();
                }
                else {
                    buf += '}';
                }
                i += 1;
                continue;
            }
            if (ch === '\n' || ch === '\r') {
                flush();
                if (hdhead < hdq.length) {
                    st = 'H';
                    hdline = '';
                }
                i += 1;
                continue;
            }
            if (ch === '#') {
                if (buf === '' || buf.endsWith(' ') || buf.endsWith('\t'))
                    st = 'C';
                else
                    buf += '#';
                i += 1;
                continue;
            }
        }
        // ---- row 24: any other byte ----
        buf += ch;
        i += 1;
    }
    // ---- end of input (total) ----
    if (st === 'SQ' || st === 'DQ')
        return null;
    if (st === 'H') {
        // A terminator on the final line with no trailing newline still ends the body.
        let cmpline = hdline;
        if (hdstrip[hdhead] === true)
            cmpline = cmpline.replace(/^\t+/, '');
        if (cmpline === hdq[hdhead])
            hdhead += 1;
    }
    if (hdhead < hdq.length)
        return null;
    if (kinds.length > 0)
        return null;
    flush();
    return positions;
}
// ------------------------------------------------------- 6c. fast-path trigger
/** The scanner can only emit a boundary splitPipes does not when one of these is present. */
function hasScannerTrigger(s) {
    return (s.includes(';') || s.includes('&') || s.includes('(') || s.includes(')') ||
        s.includes('{') || s.includes('}') || s.includes('`') || s.includes('<') ||
        s.includes('>') || s.includes('\\') || s.includes('\n') || s.includes('\r'));
}
// -------------------------------------------------------------- 7. path checks
/** Leaf-only normalize: no realpath, no symlink chase. */
function resolveLeaf(p, cwd) {
    if (p.length >= 2 && p.startsWith('"') && p.endsWith('"'))
        p = p.slice(1, -1);
    if (p.length >= 2 && p.startsWith("'") && p.endsWith("'"))
        p = p.slice(1, -1);
    const home = process.env['HOME'] || '/';
    if (p === '~')
        p = home;
    else if (p.startsWith('~/'))
        p = `${home}/${p.slice(2)}`;
    let abs = p;
    const isAbsolute = abs.startsWith('/') || abs.startsWith('\\') || /^[A-Za-z]:/.test(abs);
    if (!isAbsolute)
        abs = `${cwd}/${abs}`;
    // Collapse `.` and `..`, keeping the first field verbatim so a leading `/`
    // survives as an empty first element exactly as the shell's IFS split does.
    const parts = abs.split('/');
    const stack = [];
    for (let k = 0; k < parts.length; k++) {
        const part = parts[k];
        if (k === 0) {
            stack.push(part);
            continue;
        }
        if (part === '' || part === '.')
            continue;
        if (part === '..') {
            if (stack.length > 1)
                stack.pop();
            continue;
        }
        stack.push(part);
    }
    const result = stack.join('/');
    return result === '' ? '/' : result;
}
function isDescendant(child, parent) {
    child = child.replace(/[/\\]$/, '');
    parent = parent.replace(/[/\\]$/, '');
    if (child === parent)
        return true;
    return child.startsWith(`${parent}/`);
}
// ------------------------------------------------------------ 8. classification
/** Advance past assignment prefixes, `sudo` (with -E/-H/-u USER) and reserved words. */
function skipPrefix(toks) {
    const n = toks.length;
    let idx = 0;
    while (idx < n) {
        const t = toks[idx];
        // 1. Assignment prefix: NAME=value or NAME+=value.
        if (t.includes('=')) {
            let name = t.slice(0, t.indexOf('='));
            if (name.endsWith('+'))
                name = name.slice(0, -1);
            if (name !== '' && /^[A-Za-z0-9_]+$/.test(name) && !/^[0-9]/.test(name)) {
                idx += 1;
                continue;
            }
        }
        // 2. sudo [-E|-H|-u USER]
        if (t === 'sudo') {
            idx += 1;
            while (idx < n) {
                const s = toks[idx];
                if (s === '-E' || s === '-H') {
                    idx += 1;
                    continue;
                }
                if (s === '-u' && idx + 1 < n) {
                    idx += 2;
                    continue;
                }
                break;
            }
            continue;
        }
        // 3. Shell reserved words and stray group braces.
        if (RESERVED_WORDS.has(t)) {
            idx += 1;
            continue;
        }
        break;
    }
    return idx;
}
/** Skip flags, honour `--`, resolve every remaining token as a path. */
function walkPaths(start, toks) {
    let afterDoubleDash = false;
    for (let j = start; j < toks.length; j++) {
        const t = toks[j];
        if (!afterDoubleDash) {
            if (t === '--') {
                afterDoubleDash = true;
                continue;
            }
            // NOTE: find-predicate skip intentionally disabled here. No destructive verb
            // other than `find` takes -name/-path/etc., so any such flag is either user
            // error or adversarial — treat subsequent tokens as paths. (D-1 / D-2.)
            if (t.startsWith('-') && t.length > 1)
                continue;
        }
        const abs = resolveLeaf(t, process.cwd());
        if (!isDescendant(abs, repoRoot))
            segmentOffending.push(abs);
    }
}
/** Matches pwsh's command-string flags: -c / -command / -commandwithargs (ci) and /c. */
function isPwshCommandFlag(t) {
    if (t === '/c')
        return true;
    const lower = t.toLowerCase();
    return lower === '-c' || lower === '-command' || lower === '-commandwithargs';
}
function classifySegment(segment, depth) {
    if (depth > MAX_DEPTH) {
        parseFailed = true;
        return;
    }
    const tokens = tokenize(segment);
    if (tokens === null) {
        parseFailed = true;
        return;
    }
    const ntok = tokens.length;
    if (ntok === 0)
        return;
    const idx = skipPrefix(tokens);
    if (idx >= ntok)
        return;
    const verb = tokens[idx];
    const afterVerb = idx + 1;
    // Nested pwsh / powershell.
    if (isPwshVerb(verb)) {
        for (let j = afterVerb; j < ntok; j++) {
            if (isPwshCommandFlag(tokens[j])) {
                if (j + 1 >= ntok) {
                    parseFailed = true;
                    return;
                }
                classifyCommandString(tokens[j + 1], depth + 1);
                return;
            }
        }
        return;
    }
    // Nested POSIX-shell interpreters. Deliberately broader than "find -c": every
    // non-option token is judged as a command string, so `bash --rcfile foo -c "…"`
    // is covered and `bash script.sh` degrades to judging the literal string.
    if (isShellVerb(verb)) {
        for (let j = afterVerb; j < ntok; j++) {
            const t = tokens[j];
            if (!t.startsWith('-'))
                classifyCommandString(t, depth + 1);
        }
        return;
    }
    // Argv carriers. The scan runs to the end and NEVER returns — `find` is a carrier
    // AND has its own -delete branch below, and both must run, in this order.
    if (isCarrierVerb(verb)) {
        for (let j = afterVerb; j < ntok; j++) {
            const t = tokens[j];
            if (isDestructiveVerb(t)) {
                walkPaths(j + 1, tokens);
            }
            else if (isPwshVerb(t) || isShellVerb(t)) {
                for (let k = j + 1; k < ntok; k++) {
                    if (!tokens[k].startsWith('-')) {
                        classifyCommandString(tokens[k], depth + 1);
                        break;
                    }
                }
            }
        }
    }
    // find with -delete.
    if (verb === 'find') {
        if (!tokens.includes('-delete'))
            return;
        for (let j = afterVerb; j < ntok; j++) {
            const t = tokens[j];
            if (t.startsWith('-'))
                break;
            const abs = resolveLeaf(t, process.cwd());
            if (!isDescendant(abs, repoRoot))
                segmentOffending.push(abs);
        }
        return;
    }
    // Other destructive verbs.
    if (!isDestructiveVerb(verb))
        return;
    walkPaths(afterVerb, tokens);
}
/**
 * The union step and the single entry point for "judge this command string".
 *
 * INVARIANT: the candidate list contains the input string itself at EVERY depth,
 * including 0. Do NOT make this depth-conditional — decomposition strictly narrows
 * each verb's token walk, so dropping it would flip BLOCKs to ALLOW, a silent
 * fail-OPEN regression.
 */
function classifyCommandString(s, depth) {
    if (depth > MAX_DEPTH) {
        parseFailed = true;
        return;
    }
    const plist = [s];
    const seen = new Set([s]);
    for (const seg of splitPipes(s)) {
        if (!seen.has(seg)) {
            seen.add(seg);
            plist.push(seg);
        }
    }
    if (hasScannerTrigger(s)) {
        const positions = splitPositions(s);
        if (positions === null) {
            parseFailed = true;
            return;
        }
        for (const seg of positions) {
            if (!seen.has(seg)) {
                seen.add(seg);
                plist.push(seg);
            }
        }
    }
    for (const seg of plist) {
        if (parseFailed)
            return;
        if (seg === '')
            continue;
        classifySegment(seg, depth);
    }
}
// -------------------------------------------------------------------- 1. input
/** Extract `.tool_input.command`, falling back to the shell twin's heuristic. */
function extractCommand(payload) {
    try {
        const data = JSON.parse(payload);
        if (data && typeof data === 'object') {
            const toolInput = data['tool_input'];
            if (toolInput && typeof toolInput === 'object') {
                const command = toolInput['command'];
                if (typeof command === 'string')
                    return command;
            }
        }
        return '';
    }
    catch {
        // Heuristic fallback for the one-level Claude Code shape, matching the shell
        // twin byte-for-byte: greedy-match between `"command":"` and the closing `"}`.
        const flat = payload.replace(/\n/g, '');
        const m = /"command"[ \t]*:[ \t]*"(.*)"[ \t]*}/.exec(flat);
        if (m === null || m[1] === undefined)
            return '';
        let cmd = m[1];
        // Whitespace escapes first, then \" before \\ so a literal \\ survives.
        cmd = cmd.split('\\n').join('\n').split('\\r').join('\r').split('\\t').join('\t');
        cmd = cmd.split('\\"').join('"');
        cmd = cmd.split('\\\\').join('\\');
        return cmd;
    }
}
/** Walk up to the nearest `.git/` ancestor of cwd; '' when there is none. */
function findRepoRoot(startDir) {
    let dir = startDir;
    for (;;) {
        try {
            if (fs.statSync(path.join(dir, '.git')).isDirectory())
                return dir;
        }
        catch {
            // not a repo root; keep walking
        }
        const parent = path.dirname(dir);
        if (parent === dir)
            return '';
        dir = parent;
    }
}
const OVERRIDE_MESSAGE = 'harness-kit guard-rm: override active (HARNESS_ALLOW_OUTSIDE_RM=1) — allowing destructive command.';
const PARSE_FAIL_MESSAGE = 'harness-kit guard-rm: BLOCKED — could not parse the command safely (unbalanced quotes, ' +
    'nesting past depth 2, or an unterminated here-document); override with HARNESS_ALLOW_OUTSIDE_RM=1 if intended.';
function main() {
    let payload = '';
    try {
        payload = fs.readFileSync(0, 'utf8');
    }
    catch {
        return 0;
    }
    if (payload === '')
        return 0;
    let cmd = extractCommand(payload);
    if (cmd === '')
        return 0;
    // 2. Override env var.
    if (process.env['HARNESS_ALLOW_OUTSIDE_RM'] === '1') {
        process.stderr.write(`${OVERRIDE_MESSAGE}\n`);
        return 0;
    }
    // 2b. Command-text override prefix. Evaluated EXACTLY ONCE, on the top-level
    // command, before the .git/ walk and before any parsing — never per position.
    // Re-applying it per position would make
    // `echo x && HARNESS_ALLOW_OUTSIDE_RM=1 rm -rf /etc/x` self-authorizing.
    const ovrTrim = cmd.replace(/^[ \t\n\r\f\v]+/, '');
    if (ovrTrim.startsWith('HARNESS_ALLOW_OUTSIDE_RM=1 ') || ovrTrim.startsWith('HARNESS_ALLOW_OUTSIDE_RM=1\t')) {
        process.stderr.write(`${OVERRIDE_MESSAGE}\n`);
        return 0;
    }
    // 3. Nearest .git/ ancestor.
    repoRoot = findRepoRoot(process.cwd());
    if (repoRoot === '') {
        process.stderr.write('harness-kit guard-rm: WARN no .git/ ancestor — guard inactive.\n');
        return 0;
    }
    // 4. Truncate (boundary B11).
    cmd = cmd.slice(0, MAX_COMMAND);
    // 9. Judge every command position.
    parseFailed = false;
    segmentOffending = [];
    classifyCommandString(cmd, 0);
    if (parseFailed) {
        process.stderr.write(`${PARSE_FAIL_MESSAGE}\n`);
        return 2;
    }
    if (segmentOffending.length === 0)
        return 0;
    // 10. Emit BLOCK message.
    const lines = [
        'harness-kit guard-rm: BLOCKED — destructive command targets path outside project root.',
        `  Command: ${cmd.slice(0, MAX_ECHOED_COMMAND)}`,
        '  Offending path(s):',
        ...segmentOffending.map((p) => `    - ${p} (outside ${repoRoot})`),
        '  Override (only if you really mean this): re-issue the command with the env var',
        '    HARNESS_ALLOW_OUTSIDE_RM=1 set for that single call.',
        '  See .harness/rules/75-safety-hook.md to fully disable.',
    ];
    process.stderr.write(`${lines.join('\n')}\n`);
    return 2;
}
if (require.main === module) {
    // A throw here would exit non-zero, which reads as a BLOCK. That is the correct
    // direction for a fail-closed guard, but it must be deliberate rather than a
    // stack trace, so the failure is named.
    try {
        process.exit(main());
    }
    catch (err) {
        process.stderr.write(`harness-kit guard-rm: BLOCKED — guard raised an internal error (${String(err)}); ` +
            'override with HARNESS_ALLOW_OUTSIDE_RM=1 if intended.\n');
        process.exit(2);
    }
}
