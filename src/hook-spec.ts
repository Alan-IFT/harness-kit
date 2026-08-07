/**
 * hook-spec — the hook wiring spec (T-13), TypeScript port (v2 migration, stage 1).
 *
 * THE single source of truth for `(hook tool, target OS) -> command byte-form`
 * plus each tool's failure semantics, lifecycle event name and matcher.
 *
 * Pure and side-effect-free: no file I/O, no parsing, no substitution. Only the
 * `hostos` query reads the environment. Changing a byte here changes every
 * consumer, and there is nowhere else to change it.
 *
 * This port replaces the `hook-spec.{sh,ps1}` twin pair. One implementation runs
 * on both host operating systems, so the cross-shell divergence class that the
 * twins carried — and the operator obligations that existed only because the
 * PowerShell side could not be executed here — do not apply to it.
 *
 * CONTRACT (byte-identical to the retired shell twins; proven by
 * `tools/diff-hook-spec.sh`, which enumerates the entire input space)
 *   hook-spec tools                -> the 4 tool ids, fixed order, one per line
 *   hook-spec event <tool>         -> Stop | PreToolUse | UserPromptSubmit | SessionStart
 *   hook-spec matcher <tool>       -> Bash (guard-rm) | none (the other three)
 *   hook-spec semantics <tool>     -> fail-open | fail-closed
 *   hook-spec command <tool> <os>  -> the JSON-string-body command (inner " already \")
 *   hook-spec hostos               -> windows | unix  (the host this process runs on)
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
 *   node .harness/scripts/hook-spec.js command guard-rm unix
 */

/** The four recognized tool ids, in the fixed order `tools` emits them. */
const TOOLS = ['harness-sync', 'guard-rm', 'ambient-prompt', 'ambient-reset'] as const;
type Tool = (typeof TOOLS)[number];

const OSES = ['windows', 'unix'] as const;
type TargetOs = (typeof OSES)[number];

const QUERIES = 'tools|event|matcher|semantics|command|hostos';

/**
 * A backslash-escaped double quote. The emitted command is destined for a JSON
 * string body, so its inner quotes arrive already escaped. Held as a named
 * constant because getting this wrong is invisible until a hook fails to fire.
 */
const ESCQ = '\\"';

const EVENTS: Record<Tool, string> = {
  'harness-sync': 'Stop',
  'guard-rm': 'PreToolUse',
  'ambient-prompt': 'UserPromptSubmit',
  'ambient-reset': 'SessionStart',
};

function isTool(value: string): value is Tool {
  return (TOOLS as readonly string[]).includes(value);
}

function isTargetOs(value: string): value is TargetOs {
  return (OSES as readonly string[]).includes(value);
}

function matcherOf(tool: Tool): string {
  return tool === 'guard-rm' ? 'Bash' : 'none';
}

function semanticsOf(tool: Tool): string {
  return tool === 'guard-rm' ? 'fail-closed' : 'fail-open';
}

/**
 * The four literal command shapes. This is their only home — do not retype them,
 * and do not post-process the result anywhere.
 *
 * The tool id is interpolated into a space-preceded bare ` .harness/scripts/<tool>.<ext>`
 * path so the existing congruence extraction in the verify gate keeps working.
 */
function commandOf(tool: Tool, os: TargetOs): string {
  if (os === 'windows') {
    if (tool === 'guard-rm') {
      return (
        `pwsh -NoProfile -Command ${ESCQ}Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR; ` +
        `& pwsh -NoProfile -File .harness/scripts/${tool}.ps1${ESCQ}`
      );
    }
    return (
      `pwsh -NoProfile -Command ${ESCQ}Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR -EA SilentlyContinue; ` +
      `if (Test-Path -LiteralPath .harness/scripts/${tool}.ps1 -PathType Leaf) ` +
      `{ & pwsh -NoProfile -File .harness/scripts/${tool}.ps1 }; exit 0${ESCQ}`
    );
  }
  if (tool === 'guard-rm') {
    return `sh -c 'cd ${ESCQ}$CLAUDE_PROJECT_DIR${ESCQ} 2>/dev/null && bash .harness/scripts/${tool}.sh'`;
  }
  return (
    `sh -c 'cd ${ESCQ}$CLAUDE_PROJECT_DIR${ESCQ} 2>/dev/null && ` +
    `[ -f .harness/scripts/${tool}.sh ] && exec bash .harness/scripts/${tool}.sh || exit 0'`
  );
}

/** The host this process runs on. The only query that reads the environment. */
function hostOs(): TargetOs {
  return process.platform === 'win32' ? 'windows' : 'unix';
}

function die(message: string): never {
  process.stderr.write(`hook-spec: ${message}\n`);
  process.exit(2);
}

function emit(...lines: string[]): void {
  process.stdout.write(lines.map((line) => `${line}\n`).join(''));
}

/** `argv` excludes the node binary and this script's path. */
export function run(argv: readonly string[]): void {
  const query = argv[0] ?? '';
  // Argument count excluding the query itself, mirroring the shell twins' `$# - 1`.
  const arity = Math.max(argv.length - 1, 0);

  switch (query) {
    case 'tools': {
      if (arity !== 0) {
        die(`unrecognized arity for query 'tools': expected 0 arguments, got ${arity}`);
      }
      emit(...TOOLS);
      return;
    }
    case 'event':
    case 'matcher':
    case 'semantics': {
      if (arity !== 1) {
        die(`unrecognized arity for query '${query}': expected 1 argument, got ${arity}`);
      }
      const tool = argv[1] ?? '';
      if (!isTool(tool)) die(`unrecognized tool: ${tool}`);
      if (query === 'event') emit(EVENTS[tool]);
      else if (query === 'matcher') emit(matcherOf(tool));
      else emit(semanticsOf(tool));
      return;
    }
    case 'command': {
      if (arity !== 2) {
        die(`unrecognized arity for query 'command': expected 2 arguments, got ${arity}`);
      }
      const tool = argv[1] ?? '';
      if (!isTool(tool)) die(`unrecognized tool: ${tool}`);
      const os = argv[2] ?? '';
      if (!isTargetOs(os)) die(`unrecognized os: ${os} (expected 'windows' or 'unix')`);
      emit(commandOf(tool, os));
      return;
    }
    case 'hostos': {
      if (arity !== 0) {
        die(`unrecognized arity for query 'hostos': expected 0 arguments, got ${arity}`);
      }
      emit(hostOs());
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
