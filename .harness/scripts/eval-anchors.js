"use strict";
/**
 * eval-anchors — verify that every anchor in the evaluation control set still resolves.
 *
 * ## Why
 *
 * `evals/retrieval-eval.md` is the instrument every acceptance decision in the v2 migration
 * is argued from. Its items cite evidence as `path:line`. Those citations rot: the
 * shell-to-TypeScript migration turned `guard-rm.sh` into a twelve-line launcher, and five
 * anchors kept pointing at lines 191, 711, 903 of a file that now ends at 12. Nothing
 * noticed, because only the MEM category had a runner and the rest were scored by reading.
 *
 * An instrument that must be read by a human to be scored will rot silently. This makes the
 * control set self-checking instead: a citation that no longer resolves is a gate failure,
 * not a quiet lie.
 *
 * ## What it checks
 *
 * For every backticked anchor in an evals document:
 *   - the file exists;
 *   - every line number cited is within it.
 *
 * It does NOT check that the line still says what the item claims. Line CONTENT cannot be
 * verified without restating the answer, and a restatement is a copy nothing keeps in sync —
 * the `stage-doc-summary-header` decline. Range checking is the part that is mechanically
 * decidable, and it is the part that caught the real rot.
 *
 * The durable fix is to cite a SYMBOL rather than a line, which survives a refactor. This
 * check is what makes the difference visible while that migration happens.
 *
 * Usage:
 *   node .harness/scripts/eval-anchors.js [--json]
 * Exit: 0 all resolve, 1 stale anchors found, 2 the evals directory is unreadable.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.parseAnchors = parseAnchors;
exports.resolveTarget = resolveTarget;
exports.checkAnchors = checkAnchors;
exports.auditEvals = auditEvals;
exports.run = run;
const fs = require("node:fs");
const path = require("node:path");
/**
 * A backticked CITATION: a path carrying a directory separator, or any filename carrying a
 * line number. Either mark distinguishes evidence from prose.
 *
 * A bare backticked filename is neither. `PM_LOG.md`, `settings.json` and `03_GATE_REVIEW.md`
 * appear throughout the control set as generic nouns, and reading those as citations
 * produced six false positives on the first run. A check that cries wolf gets disabled,
 * which is worse than not having one, so the matcher requires a mark.
 */
const ANCHOR_RE = /`((?:[A-Za-z0-9_.\-]+\/)*[A-Za-z0-9_.\-]+\.(?:sh|ps1|ts|js|md|json))((?::\d+(?:[-–,]\d+)*)?)`/g;
/** True when the citation carries a directory or a line number. */
function isCitation(target, suffix) {
    return target.includes('/') || suffix !== '';
}
function parseAnchors(source, content) {
    const out = [];
    const lines = content.split('\n');
    for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        for (const m of line.matchAll(ANCHOR_RE)) {
            const target = m[1];
            const suffix = m[2] ?? '';
            if (target === undefined)
                continue;
            if (!isCitation(target, suffix))
                continue;
            const nums = suffix === '' ? [] : suffix.slice(1).split(/[-–,]/).map((n) => Number.parseInt(n, 10)).filter((n) => !Number.isNaN(n));
            out.push({ source, sourceLine: i + 1, target, lines: nums, raw: m[0] });
        }
    }
    return out;
}
/**
 * Resolve a cited path. Citations are written the way a reader would say them, so a bare
 * `verify_all.sh` means the one under `.harness/scripts/`. Only paths that resolve nowhere
 * are reported.
 */
function resolveTarget(target, root) {
    const candidates = [target, `.harness/scripts/${target}`, `docs/${target}`, `.harness/${target}`, `evals/${target}`];
    for (const c of candidates) {
        const abs = path.join(root, c);
        if (fs.existsSync(abs) && fs.statSync(abs).isFile())
            return c;
    }
    return null;
}
function checkAnchors(anchors, root) {
    const stale = [];
    const lineCounts = new Map();
    for (const a of anchors) {
        const resolved = resolveTarget(a.target, root);
        if (resolved === null) {
            stale.push({ ...a, reason: 'missing file', detail: `no file at ${a.target}` });
            continue;
        }
        if (a.lines.length === 0)
            continue;
        let count = lineCounts.get(resolved);
        if (count === undefined) {
            count = fs.readFileSync(path.join(root, resolved), 'utf8').split('\n').length;
            lineCounts.set(resolved, count);
        }
        const over = a.lines.filter((n) => n > count);
        if (over.length > 0) {
            stale.push({
                ...a,
                reason: 'line out of range',
                detail: `${resolved} has ${count} lines; cited ${over.join(', ')}`,
            });
        }
    }
    return stale;
}
function auditEvals(root) {
    const dir = path.join(root, 'evals');
    const files = fs.readdirSync(dir).filter((f) => f.endsWith('.md')).sort();
    const anchors = files.flatMap((f) => parseAnchors(f, fs.readFileSync(path.join(dir, f), 'utf8')));
    return { anchors, stale: checkAnchors(anchors, root) };
}
function run(argv, root, out) {
    let result;
    try {
        result = auditEvals(root);
    }
    catch {
        out('eval-anchors: cannot read evals/');
        return 2;
    }
    if (argv.includes('--json')) {
        out(JSON.stringify(result.stale, null, 2));
        return result.stale.length === 0 ? 0 : 1;
    }
    if (result.stale.length === 0) {
        out(`eval-anchors: all ${result.anchors.length} anchors resolve.`);
        return 0;
    }
    out(`eval-anchors: ${result.stale.length} of ${result.anchors.length} anchors no longer resolve.`);
    out('');
    for (const s of result.stale) {
        out(`  ${s.source}:${s.sourceLine}  ${s.raw}`);
        out(`    ${s.reason} — ${s.detail}`);
    }
    out('');
    out('An anchor is evidence. One that points nowhere is a claim with no support, and the');
    out('durable fix is to cite a SYMBOL rather than a line — a symbol survives a refactor.');
    return 1;
}
if (require.main === module) {
    const root = path.resolve(__dirname, '../..');
    process.exit(run(process.argv.slice(2), root, (s) => process.stdout.write(`${s}\n`)));
}
