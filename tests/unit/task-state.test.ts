/**
 * Native test suite for task-state.
 *
 * The file exists for one decision: whether three consecutive rounds at a stage have been
 * spent, so the pipeline stops and asks a human instead of routing again. That rule was
 * counted from conversation history and therefore reset at every session boundary. The
 * escalation tests below are the point of the whole module.
 *
 * The 4 KB ceiling is the other load-bearing property: it is what keeps this from growing
 * back into the prose ledger the migration deleted, and it is enforced on write rather than
 * by a later audit, because an audit leaves the bloated file on disk.
 */

import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import * as fs from 'node:fs';
import * as os from 'node:os';
import * as path from 'node:path';
import {
  run,
  load,
  save,
  emptyState,
  recordVerdict,
  advance,
  consecutiveAt,
  mustEscalate,
  serialize,
  statePath,
  summarize,
  MAX_BYTES,
  ROLLBACK_LIMIT,
  type TaskState,
} from '../../src/task-state';

let sandbox = '';

const invoke = (...argv: string[]): { code: number; out: string } => {
  const lines: string[] = [];
  const code = run(argv, sandbox, (s) => lines.push(s));
  return { code, out: lines.join('\n') };
};

beforeEach(() => {
  sandbox = fs.mkdtempSync(path.join(os.tmpdir(), 'task-state-test-'));
});
afterEach(() => {
  fs.rmSync(sandbox, { recursive: true, force: true });
});

describe('the escalation rule survives a session boundary', () => {
  const threeAtStage4 = (): TaskState => {
    let s = emptyState('t', 'full');
    s = advance(s, 4);
    for (let i = 0; i < 3; i++) s = recordVerdict(s, 4, 'BLOCKED ON DESIGN');
    return s;
  };

  it('counts consecutive rounds at a stage', () => {
    expect(consecutiveAt(threeAtStage4(), 4)).toBe(3);
  });

  it('escalates at the limit and not before', () => {
    let s = advance(emptyState('t', 'full'), 4);
    for (let i = 1; i < ROLLBACK_LIMIT; i++) {
      s = recordVerdict(s, 4, 'BLOCKED');
      expect(mustEscalate(s, 4), `after ${i}`).toBe(false);
    }
    s = recordVerdict(s, 4, 'BLOCKED');
    expect(mustEscalate(s, 4)).toBe(true);
  });

  it('does NOT escalate when the rounds are not consecutive', () => {
    // Three rollbacks at stage 4 spread across a task that advanced and came back is a
    // different situation from three in a row, and the stated rule is about the latter.
    let s = emptyState('t', 'full');
    s = recordVerdict(s, 4, 'BLOCKED');
    s = recordVerdict(s, 4, 'BLOCKED');
    s = recordVerdict(s, 5, 'APPROVED');
    s = recordVerdict(s, 4, 'BLOCKED');
    expect(consecutiveAt(s, 4)).toBe(1);
    expect(mustEscalate(s, 4)).toBe(false);
  });

  it('survives a round trip through disk — the whole reason the file exists', () => {
    save(sandbox, threeAtStage4());
    const reloaded = load(sandbox, 't');
    expect(reloaded).not.toBeNull();
    expect(mustEscalate(reloaded as TaskState, 4)).toBe(true);
  });

  it('reports the escalation through the exit code, not only the text', () => {
    save(sandbox, threeAtStage4());
    const r = invoke('show', 't');
    expect(r.code).toBe(3);
    expect(r.out).toContain('ESCALATE');
    expect(r.out).toContain('Stop and ask the human');
  });

  it('a verdict moves the task to that stage, so the two can never disagree', () => {
    // Found by a smoke test: three rollbacks recorded at stage 4 while `stage` stayed 1,
    // so the escalation query answered about stage 1 and `show` exited 0.
    let s = emptyState('t', 'full');
    s = recordVerdict(s, 4, 'BLOCKED ON DESIGN');
    expect(s.stage).toBe(4);
    s = recordVerdict(s, 4, 'BLOCKED ON DESIGN');
    s = recordVerdict(s, 4, 'BLOCKED ON DESIGN');
    expect(mustEscalate(s, s.stage)).toBe(true);
  });

  it('advance still moves the stage forward on a pass', () => {
    let s = recordVerdict(emptyState('t', 'full'), 3, 'APPROVED');
    expect(s.stage).toBe(3);
    s = advance(s, 4);
    expect(s.stage).toBe(4);
    expect(consecutiveAt(s, 4)).toBe(0);
  });

  it('keeps per-stage round counters independent of the consecutive streak', () => {
    let s = emptyState('t', 'full');
    s = recordVerdict(s, 3, 'APPROVED WITH CONDITIONS');
    s = recordVerdict(s, 4, 'BLOCKED ON DESIGN');
    s = recordVerdict(s, 4, 'BLOCKED ON DESIGN');
    expect(s.rounds).toEqual({ '3': 1, '4': 2 });
  });
});

describe('the size ceiling is enforced on write', () => {
  it('refuses a state that would exceed it', () => {
    const s = emptyState('t', 'full');
    s.verdicts.push({ stage: 4, round: 1, verdict: 'x'.repeat(MAX_BYTES) });
    expect(() => serialize(s)).toThrow(/over the 4096-byte ceiling/);
  });

  it('names the cause rather than just the number', () => {
    const s = emptyState('t', 'full');
    s.blocked = 'y'.repeat(MAX_BYTES);
    expect(() => serialize(s)).toThrow(/counters, not narrative/);
  });

  it('leaves NO file behind when a write is refused', () => {
    // An audit that reports after the fact still leaves the bloated file on disk.
    save(sandbox, emptyState('t', 'full'));
    const before = fs.readFileSync(statePath(sandbox, 't'), 'utf8');
    const r = invoke('verdict', 't', '--stage', '4', '--verdict', 'z'.repeat(MAX_BYTES));
    expect(r.code).toBe(2);
    expect(fs.readFileSync(statePath(sandbox, 't'), 'utf8')).toBe(before);
  });

  it('a realistic task stays far under the ceiling', () => {
    let s = emptyState('slim-verify-all', 'full');
    for (let stage = 1; stage <= 7; stage++) {
      s = recordVerdict(s, stage, 'APPROVED WITH CONDITIONS');
      s = recordVerdict(s, stage, 'BLOCKED ON DESIGN');
    }
    const bytes = Buffer.byteLength(serialize(s), 'utf8');
    expect(bytes).toBeLessThan(1500);
  });
});

describe('cli', () => {
  it('init creates a state at stage 1', () => {
    expect(invoke('init', 't', '--mode', 'full').code).toBe(0);
    expect(load(sandbox, 't')?.stage).toBe(1);
  });

  it('init refuses to overwrite existing progress', () => {
    invoke('init', 't', '--mode', 'full');
    invoke('advance', 't', '--stage', '5');
    const r = invoke('init', 't', '--mode', 'full');
    expect(r.code).toBe(1);
    expect(r.out).toContain('refusing to overwrite');
    expect(load(sandbox, 't')?.stage).toBe(5);
  });

  it('rejects an unrecognized mode', () => {
    expect(invoke('init', 't', '--mode', 'turbo').code).toBe(2);
  });

  it('tells a cold session how to start when no state exists', () => {
    const r = invoke('show', 'nope');
    expect(r.code).toBe(1);
    expect(r.out).toContain('task-state init nope');
  });

  it('block and unblock round-trip', () => {
    invoke('init', 't', '--mode', 'full');
    invoke('block', 't', '--reason', 'needs a human decision on the acceptance bar');
    expect(load(sandbox, 't')?.blocked).toContain('acceptance bar');
    expect(invoke('show', 't').out).toContain('BLOCKED —');
    invoke('unblock', 't');
    expect(load(sandbox, 't')?.blocked).toBeNull();
  });

  it('advance moves the stage without touching the verdict history', () => {
    invoke('init', 't', '--mode', 'full');
    invoke('verdict', 't', '--stage', '3', '--verdict', 'APPROVED');
    invoke('advance', 't', '--stage', '4');
    const s = load(sandbox, 't');
    expect(s?.stage).toBe(4);
    expect(s?.verdicts).toHaveLength(1);
  });

  it('rejects a malformed verdict call rather than writing a partial record', () => {
    invoke('init', 't', '--mode', 'full');
    expect(invoke('verdict', 't', '--stage', 'four', '--verdict', 'x').code).toBe(2);
    expect(load(sandbox, 't')?.verdicts).toEqual([]);
  });

  it('prints usage with no arguments', () => {
    expect(invoke().code).toBe(2);
    expect(invoke().out).toContain('usage: task-state');
  });
});

describe('summarize is what a cold session reads instead of asking', () => {
  it('states the mode, the stage and the streak', () => {
    let s = advance(emptyState('slim', 'goal'), 4);
    s = recordVerdict(s, 4, 'BLOCKED ON DESIGN');
    const text = summarize(s).join('\n');
    expect(text).toContain('mode goal');
    expect(text).toContain('at stage 4');
    expect(text).toContain(`1/${ROLLBACK_LIMIT}`);
  });

  it('says so plainly when a task has not started', () => {
    expect(summarize(emptyState('t', 'full')).join('\n')).toContain('none yet');
  });
});
