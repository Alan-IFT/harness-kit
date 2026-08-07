/**
 * Native test suite for the hook-spec TypeScript port.
 *
 * Per constraint 5 of docs/proposals/v2-ts-migration.md: tools/diff-hook-spec.sh compares
 * the port against hook-spec.sh and dies with that file. These tests assert the CONTRACT
 * and are what remains after the shell twins are deleted.
 *
 * The spec is a pure function over a tiny input space, so the coverage here is
 * EXHAUSTIVE rather than sampled: every tool, every OS, every query.
 */

import { describe, expect, it } from 'vitest';
import {
  TOOLS,
  EVENTS,
  isTool,
  matcherOf,
  semanticsOf,
  commandOf,
  hostOs,
  type Tool,
  type TargetOs,
} from '../../src/hook-spec';

const OSES: readonly TargetOs[] = ['windows', 'unix'];

describe('the tool set', () => {
  it('has exactly four ids in a fixed order', () => {
    expect(TOOLS).toEqual(['harness-sync', 'guard-rm', 'ambient-prompt', 'ambient-reset']);
  });

  it('recognises exactly those four', () => {
    for (const t of TOOLS) expect(isTool(t)).toBe(true);
    for (const t of ['', 'rm', 'harness_sync', 'Guard-Rm', 'hook-spec']) {
      expect(isTool(t), `${t} must not be a tool`).toBe(false);
    }
  });

  it('maps each tool to a distinct lifecycle event', () => {
    const events = TOOLS.map((t) => EVENTS[t]);
    expect(events).toEqual(['Stop', 'PreToolUse', 'UserPromptSubmit', 'SessionStart']);
    // Four DISTINCT events is a wiring invariant install-hooks depends on: four
    // duplicate events would emit duplicate JSON keys and wire one hook instead of four.
    expect(new Set(events).size).toBe(4);
  });
});

describe('matcher and semantics', () => {
  it('gives the guard the Bash matcher and everything else the none sentinel', () => {
    expect(matcherOf('guard-rm')).toBe('Bash');
    for (const t of TOOLS.filter((x) => x !== 'guard-rm')) expect(matcherOf(t)).toBe('none');
  });

  it('never answers with an empty string', () => {
    // `none` is a reserved NON-EMPTY sentinel, so empty is never a successful answer.
    for (const t of TOOLS) {
      expect(matcherOf(t)).not.toBe('');
      expect(semanticsOf(t)).not.toBe('');
      expect(EVENTS[t]).not.toBe('');
    }
  });

  it('marks only the guard fail-closed', () => {
    expect(semanticsOf('guard-rm')).toBe('fail-closed');
    for (const t of TOOLS.filter((x) => x !== 'guard-rm')) expect(semanticsOf(t)).toBe('fail-open');
  });
});

describe('command byte-forms', () => {
  it('answers for every (tool, os) pair', () => {
    for (const t of TOOLS) {
      for (const os of OSES) {
        expect(commandOf(t, os), `${t}/${os}`).not.toBe('');
      }
    }
  });

  it('interpolates the tool id into a space-preceded bare path', () => {
    // The verify gate extracts ` .harness/scripts/<tool>.<ext>` by that shape; losing the
    // leading space or the bare form would silently break its congruence check.
    for (const t of TOOLS) {
      expect(commandOf(t, 'unix')).toContain(` .harness/scripts/${t}.sh`);
      expect(commandOf(t, 'windows')).toContain(` .harness/scripts/${t}.ps1`);
    }
  });

  it('escapes inner quotes for a JSON string body', () => {
    // The command lands in a JSON value unmodified, so its inner quotes must already be
    // backslash-escaped. Getting this wrong is invisible until a hook fails to fire.
    for (const t of TOOLS) {
      for (const os of OSES) {
        const cmd = commandOf(t, os);
        const bare = cmd.replace(/\\"/g, '');
        expect(bare, `${t}/${os} has an unescaped quote`).not.toContain('"');
      }
    }
  });

  it('gives the guard NO fallback on either OS — it is fail-closed by design', () => {
    // A missing or unreachable guard must yield a non-zero exit so the Bash tool call is
    // BLOCKED. Adding `|| exit 0` here would silently disarm the guardrail.
    for (const os of OSES) {
      const cmd = commandOf('guard-rm', os);
      expect(cmd, `${os} guard must not swallow failure`).not.toContain('exit 0');
      expect(cmd).not.toContain('Test-Path');
      expect(cmd).not.toContain('[ -f ');
    }
  });

  it('gives every NON-guard tool a fallback so a missing script exits 0', () => {
    for (const t of TOOLS.filter((x) => x !== 'guard-rm')) {
      expect(commandOf(t, 'unix'), `${t} unix`).toContain('exit 0');
      expect(commandOf(t, 'windows'), `${t} windows`).toContain('exit 0');
    }
  });

  it('anchors to the project directory before running anything', () => {
    for (const t of TOOLS) {
      expect(commandOf(t, 'unix')).toContain('$CLAUDE_PROJECT_DIR');
      expect(commandOf(t, 'windows')).toContain('$env:CLAUDE_PROJECT_DIR');
    }
  });

  it('is pure — the same arguments give the same bytes', () => {
    for (const t of TOOLS) {
      for (const os of OSES) {
        expect(commandOf(t, os)).toBe(commandOf(t, os));
      }
    }
  });

  it('gives every (tool, os) pair a distinct command', () => {
    const all = TOOLS.flatMap((t) => OSES.map((os) => commandOf(t, os)));
    expect(new Set(all).size).toBe(all.length);
  });
});

describe('hostOs', () => {
  it('answers windows or unix and nothing else', () => {
    expect(['windows', 'unix']).toContain(hostOs());
  });

  it('agrees with the running platform', () => {
    expect(hostOs()).toBe(process.platform === 'win32' ? 'windows' : 'unix');
  });
});

describe('frozen byte-forms', () => {
  // An INDEPENDENT statement of the four shapes. These literals are deliberately typed
  // out rather than derived, for the same reason the shell drivers' EXP_* fixtures were
  // retained (rejected-decisions: hook-byteform-test-literal-retirement): a test must not
  // take its expectation from the artifact under test. If a change here is intended, the
  // change is to BOTH this literal and the implementation, never to one alone.
  const EXPECTED: Record<Tool, Record<TargetOs, string>> = {
    'harness-sync': {
      unix: `sh -c 'cd \\"$CLAUDE_PROJECT_DIR\\" 2>/dev/null && [ -f .harness/scripts/harness-sync.sh ] && exec bash .harness/scripts/harness-sync.sh || exit 0'`,
      windows: `pwsh -NoProfile -Command \\"Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR -EA SilentlyContinue; if (Test-Path -LiteralPath .harness/scripts/harness-sync.ps1 -PathType Leaf) { & pwsh -NoProfile -File .harness/scripts/harness-sync.ps1 }; exit 0\\"`,
    },
    'guard-rm': {
      unix: `sh -c 'cd \\"$CLAUDE_PROJECT_DIR\\" 2>/dev/null && bash .harness/scripts/guard-rm.sh'`,
      windows: `pwsh -NoProfile -Command \\"Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR; & pwsh -NoProfile -File .harness/scripts/guard-rm.ps1\\"`,
    },
    'ambient-prompt': {
      unix: `sh -c 'cd \\"$CLAUDE_PROJECT_DIR\\" 2>/dev/null && [ -f .harness/scripts/ambient-prompt.sh ] && exec bash .harness/scripts/ambient-prompt.sh || exit 0'`,
      windows: `pwsh -NoProfile -Command \\"Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR -EA SilentlyContinue; if (Test-Path -LiteralPath .harness/scripts/ambient-prompt.ps1 -PathType Leaf) { & pwsh -NoProfile -File .harness/scripts/ambient-prompt.ps1 }; exit 0\\"`,
    },
    'ambient-reset': {
      unix: `sh -c 'cd \\"$CLAUDE_PROJECT_DIR\\" 2>/dev/null && [ -f .harness/scripts/ambient-reset.sh ] && exec bash .harness/scripts/ambient-reset.sh || exit 0'`,
      windows: `pwsh -NoProfile -Command \\"Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR -EA SilentlyContinue; if (Test-Path -LiteralPath .harness/scripts/ambient-reset.ps1 -PathType Leaf) { & pwsh -NoProfile -File .harness/scripts/ambient-reset.ps1 }; exit 0\\"`,
    },
  };

  it.each(TOOLS)('%s matches its frozen unix byte-form', (tool) => {
    expect(commandOf(tool, 'unix')).toBe(EXPECTED[tool].unix);
  });

  it.each(TOOLS)('%s matches its frozen windows byte-form', (tool) => {
    expect(commandOf(tool, 'windows')).toBe(EXPECTED[tool].windows);
  });
});
