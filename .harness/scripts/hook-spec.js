"use strict";
/**
 * hook-spec — the hook wiring spec (T-13), TypeScript port (v2 migration, stage 1).
 *
 * THE single source of truth for `hook tool -> command byte-form` plus each tool's
 * failure semantics, lifecycle event name and matcher.
 *
 * Pure and side-effect-free: no file I/O, no parsing, no substitution, and nothing
 * read from the environment. Changing a byte here changes every consumer, and there
 * is nowhere else to change it.
 *
 * THE TARGET-OS AXIS IS GONE. It existed to choose between a `pwsh` byte-form and an
 * `sh` one; Windows support was removed, so the choice has one branch and a function
 * of one argument replaced a function of two. With it went the `hostos` query — a
 * process asking which OS it runs on is only meaningful when the answer changes the
 * answer to something else.
 *
 * CONTRACT (byte-identical to the retired shell twins; proven by
 * `tools/diff-hook-spec.sh`, which enumerates the entire input space)
 *   hook-spec tools                -> the 4 tool ids, fixed order, one per line
 *   hook-spec event <tool>         -> Stop | PreToolUse | UserPromptSubmit | SessionStart
 *   hook-spec matcher <tool>       -> Bash (guard-rm) | none (the other three)
 *   hook-spec semantics <tool>     -> fail-open | fail-closed
 *   hook-spec command <tool>       -> the JSON-string-body command (inner " already \")
 *   anything else / bad arity      -> NOTHING on stdout, diagnostic on stderr, exit 2
 *
 * Invariants a consumer may rely on: purity (fixed arguments -> fixed bytes) and
 * totality (exit 0 <=> non-empty stdout; exit 2 <=> empty stdout + non-empty stderr).
 * `none` is a reserved non-empty sentinel for "this event takes no matcher", so an
 * empty string is never a successful answer.
 *
 * guard-rm is fail-CLOSED BY DESIGN: its command carries no `|| exit 0` and no
 * trailing `exit 0`, so a missing or unreachable guard yields a non-zero exit and
 * the Bash tool call is BLOCKED. Never add a fallback to that branch.
 * See .harness/rules/75-safety-hook.md.
 *
 * Usage:
 *   node .harness/scripts/hook-spec.js command guard-rm
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.EVENTS = exports.TOOLS = void 0;
exports.isTool = isTool;
exports.matcherOf = matcherOf;
exports.semanticsOf = semanticsOf;
exports.commandOf = commandOf;
exports.run = run;
/** The four recognized tool ids, in the fixed order `tools` emits them. */
exports.TOOLS = ['harness-sync', 'guard-rm', 'ambient-prompt', 'ambient-reset'];
const QUERIES = 'tools|event|matcher|semantics|command';
/**
 * A backslash-escaped double quote. The emitted command is destined for a JSON
 * string body, so its inner quotes arrive already escaped. Held as a named
 * constant because getting this wrong is invisible until a hook fails to fire.
 */
const ESCQ = '\\"';
exports.EVENTS = {
    'harness-sync': 'Stop',
    'guard-rm': 'PreToolUse',
    'ambient-prompt': 'UserPromptSubmit',
    'ambient-reset': 'SessionStart',
};
function isTool(value) {
    return exports.TOOLS.includes(value);
}
function matcherOf(tool) {
    return tool === 'guard-rm' ? 'Bash' : 'none';
}
function semanticsOf(tool) {
    return tool === 'guard-rm' ? 'fail-closed' : 'fail-open';
}
/**
 * The two literal command shapes. This is their only home — do not retype them,
 * and do not post-process the result anywhere.
 *
 * The tool id is interpolated into a space-preceded bare ` .harness/scripts/<tool>.sh`
 * path so the existing congruence extraction in the verify gate keeps working.
 */
function commandOf(tool) {
    if (tool === 'guard-rm') {
        return `sh -c 'cd ${ESCQ}$CLAUDE_PROJECT_DIR${ESCQ} 2>/dev/null && bash .harness/scripts/${tool}.sh'`;
    }
    return (`sh -c 'cd ${ESCQ}$CLAUDE_PROJECT_DIR${ESCQ} 2>/dev/null && ` +
        `[ -f .harness/scripts/${tool}.sh ] && exec bash .harness/scripts/${tool}.sh || exit 0'`);
}
function die(message) {
    process.stderr.write(`hook-spec: ${message}\n`);
    process.exit(2);
}
function emit(...lines) {
    process.stdout.write(lines.map((line) => `${line}\n`).join(''));
}
/** `argv` excludes the node binary and this script's path. */
function run(argv) {
    const query = argv[0] ?? '';
    // Argument count excluding the query itself, mirroring the shell twins' `$# - 1`.
    const arity = Math.max(argv.length - 1, 0);
    switch (query) {
        case 'tools': {
            if (arity !== 0) {
                die(`unrecognized arity for query 'tools': expected 0 arguments, got ${arity}`);
            }
            emit(...exports.TOOLS);
            return;
        }
        case 'event':
        case 'matcher':
        case 'semantics': {
            if (arity !== 1) {
                die(`unrecognized arity for query '${query}': expected 1 argument, got ${arity}`);
            }
            const tool = argv[1] ?? '';
            if (!isTool(tool))
                die(`unrecognized tool: ${tool}`);
            if (query === 'event')
                emit(exports.EVENTS[tool]);
            else if (query === 'matcher')
                emit(matcherOf(tool));
            else
                emit(semanticsOf(tool));
            return;
        }
        case 'command': {
            if (arity !== 1) {
                die(`unrecognized arity for query 'command': expected 1 argument, got ${arity}`);
            }
            const tool = argv[1] ?? '';
            if (!isTool(tool))
                die(`unrecognized tool: ${tool}`);
            emit(commandOf(tool));
            return;
        }
        case '':
            die(`unrecognized query: <none> (expected ${QUERIES})`);
            break;
        default:
            die(`unrecognized query: ${query} (expected ${QUERIES})`);
    }
}
if (require.main === module) {
    run(process.argv.slice(2));
    process.exit(0);
}
