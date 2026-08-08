/**
 * Native test suite for the hook-spec TypeScript port.
 *
 * Per constraint 5 of docs/proposals/v2-ts-migration.md: tools/diff-hook-spec.sh compared
 * the port against hook-spec.sh and died with that file. These tests assert the CONTRACT
 * and are what remains after the shell twins were deleted.
 *
 * The spec is a pure function over a tiny input space, so the coverage here is
 * EXHAUSTIVE rather than sampled: every tool, every query. The target-OS axis is gone with
 * Windows support — `commandOf` takes one argument, and a `pwsh` byte-form reappearing is
 * now a defect these tests assert against rather than a branch they cover.
 */

import { describe, expect, it } from 'vitest';
import { TOOLS, EVENTS, isTool, matcherOf, semanticsOf, commandOf, type Tool } from '../../src/hook-spec';

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
  it('answers for every tool', () => {
    for (const t of TOOLS) expect(commandOf(t), t).not.toBe('');
  });

  it('interpolates the tool id into a space-preceded bare path', () => {
    // The verify gate extracts ` .harness/scripts/<tool>.sh` by that shape; losing the
    // leading space or the bare form would silently break its congruence check.
    for (const t of TOOLS) expect(commandOf(t)).toContain(` .harness/scripts/${t}.sh`);
  });

  it('names no PowerShell — a returning twin is a defect, not a platform', () => {
    for (const t of TOOLS) {
      expect(commandOf(t), t).not.toContain('pwsh');
      expect(commandOf(t), t).not.toContain('.ps1');
    }
  });

  it('escapes inner quotes for a JSON string body', () => {
    // The command lands in a JSON value unmodified, so its inner quotes must already be
    // backslash-escaped. Getting this wrong is invisible until a hook fails to fire.
    for (const t of TOOLS) {
      const bare = commandOf(t).replace(/\\"/g, '');
      expect(bare, `${t} has an unescaped quote`).not.toContain('"');
    }
  });

  it('gives the guard NO fallback — it is fail-closed by design', () => {
    // A missing or unreachable guard must yield a non-zero exit so the Bash tool call is
    // BLOCKED. Adding `|| exit 0` here would silently disarm the guardrail.
    const cmd = commandOf('guard-rm');
    expect(cmd, 'guard must not swallow failure').not.toContain('exit 0');
    expect(cmd).not.toContain('[ -f ');
  });

  it('gives every NON-guard tool a fallback so a missing script exits 0', () => {
    for (const t of TOOLS.filter((x) => x !== 'guard-rm')) expect(commandOf(t), t).toContain('exit 0');
  });

  it('anchors to the project directory before running anything', () => {
    for (const t of TOOLS) expect(commandOf(t)).toContain('$CLAUDE_PROJECT_DIR');
  });

  it('is pure — the same argument gives the same bytes', () => {
    for (const t of TOOLS) expect(commandOf(t)).toBe(commandOf(t));
  });

  it('gives every tool a distinct command', () => {
    const all = TOOLS.map((t) => commandOf(t));
    expect(new Set(all).size).toBe(all.length);
  });
});

describe('frozen byte-forms', () => {
  // An INDEPENDENT statement of the four shapes. These literals are deliberately typed
  // out rather than derived, for the same reason the shell drivers' EXP_* fixtures were
  // retained (rejected-decisions: hook-byteform-test-literal-retirement): a test must not
  // take its expectation from the artifact under test. If a change here is intended, the
  // change is to BOTH this literal and the implementation, never to one alone.
  const EXPECTED: Record<Tool, string> = {
    'harness-sync': `sh -c 'cd \\"$CLAUDE_PROJECT_DIR\\" 2>/dev/null && [ -f .harness/scripts/harness-sync.sh ] && exec bash .harness/scripts/harness-sync.sh || exit 0'`,
    'guard-rm': `sh -c 'cd \\"$CLAUDE_PROJECT_DIR\\" 2>/dev/null && bash .harness/scripts/guard-rm.sh'`,
    'ambient-prompt': `sh -c 'cd \\"$CLAUDE_PROJECT_DIR\\" 2>/dev/null && [ -f .harness/scripts/ambient-prompt.sh ] && exec bash .harness/scripts/ambient-prompt.sh || exit 0'`,
    'ambient-reset': `sh -c 'cd \\"$CLAUDE_PROJECT_DIR\\" 2>/dev/null && [ -f .harness/scripts/ambient-reset.sh ] && exec bash .harness/scripts/ambient-reset.sh || exit 0'`,
  };

  it.each(TOOLS)('%s matches its frozen byte-form', (tool) => {
    expect(commandOf(tool)).toBe(EXPECTED[tool]);
  });
});
