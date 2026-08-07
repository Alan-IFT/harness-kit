/**
 * task-state — the durable half of a task's progress.
 *
 * ## Why this exists
 *
 * `TodoWrite` is session-scoped. Close the session and it is gone. But the pipeline's
 * safety rule — **three consecutive rollbacks at the same stage stops and asks the human** —
 * is counted from conversation history, so it silently resets across a session boundary. A
 * task that has already burned three rounds at stage 4 looks brand new to the next session,
 * and the rule that exists to stop a loop does not fire.
 *
 * That is the whole justification. This file is not a record of what happened; it is the
 * few counters a decision depends on.
 *
 * ## The boundary that matters
 *
 * This is deliberately NOT a rebuilt `PM_LOG.md`. The distinction is the difference between
 * what the v2 migration deleted and what it keeps:
 *
 *                  deleted                          kept here
 *   content        prose restating a task           structured verdicts and counts
 *   size           121 KB per task                  under 1 KB per task
 *   how it is read whole, into context              a few fields
 *
 * The 4 KB ceiling is enforced **at write time**, not by a later audit. A file that would
 * exceed it is refused with the reason, because a size gate that reports after the fact
 * still leaves the bloated file on disk and the habit intact. Prefer a design that makes the
 * failure impossible over one that forbids it.
 *
 * Usage:
 *   node .harness/scripts/task-state.js show <slug>
 *   node .harness/scripts/task-state.js init <slug> --mode full
 *   node .harness/scripts/task-state.js verdict <slug> --stage 3 --verdict "BLOCKED ON DESIGN"
 *   node .harness/scripts/task-state.js advance <slug> --stage 4
 *   node .harness/scripts/task-state.js block <slug> --reason "needs a human decision on X"
 *   node .harness/scripts/task-state.js unblock <slug>
 */

import * as fs from 'node:fs';
import * as path from 'node:path';

/** A task state file may never exceed this. Enforced on write, never after. */
export const MAX_BYTES = 4096;

export type Mode = 'full' | 'plan' | 'explore' | 'goal';

export interface Verdict {
  stage: number;
  round: number;
  verdict: string;
}

export interface TaskState {
  slug: string;
  mode: Mode;
  /** The stage the task is currently at, 1-7. */
  stage: number;
  /** Rounds spent at each stage, keyed by stage number. */
  rounds: Record<string, number>;
  verdicts: Verdict[];
  /** Non-null when the task is waiting on a human. */
  blocked: string | null;
}

export const ROLLBACK_LIMIT = 3;

export function statePath(root: string, slug: string): string {
  return path.join(root, '.harness', 'state', `${slug}.json`);
}

export function emptyState(slug: string, mode: Mode): TaskState {
  return { slug, mode, stage: 1, rounds: {}, verdicts: [], blocked: null };
}

/**
 * Serialize, refusing anything over the ceiling.
 *
 * The message names what to remove, because the only way this file grows is someone putting
 * prose in a verdict string — which is the failure mode the ceiling exists to prevent.
 */
export function serialize(state: TaskState): string {
  const text = `${JSON.stringify(state, null, 2)}\n`;
  if (Buffer.byteLength(text, 'utf8') > MAX_BYTES) {
    throw new Error(
      `task-state: ${state.slug} would be ${Buffer.byteLength(text, 'utf8')} bytes, over the ${MAX_BYTES}-byte ceiling. ` +
        'This file holds counters, not narrative — a verdict is a verdict word, not a paragraph. ' +
        'The reasoning belongs in the task folder.',
    );
  }
  return text;
}

export function load(root: string, slug: string): TaskState | null {
  try {
    return JSON.parse(fs.readFileSync(statePath(root, slug), 'utf8')) as TaskState;
  } catch {
    return null;
  }
}

export function save(root: string, state: TaskState): void {
  const p = statePath(root, state.slug);
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, serialize(state));
}

/**
 * Consecutive rounds recorded at `stage` counting back from the most recent verdict.
 *
 * "Consecutive" is the load-bearing word. Three rollbacks at stage 4 spread across a task
 * that advanced and came back is a different situation from three in a row, and the rule the
 * pipeline actually states is about the latter.
 */
export function consecutiveAt(state: TaskState, stage: number): number {
  let n = 0;
  for (let i = state.verdicts.length - 1; i >= 0; i--) {
    if (state.verdicts[i]?.stage === stage) n += 1;
    else break;
  }
  return n;
}

/** True when the pipeline must stop and ask a human rather than route again. */
export function mustEscalate(state: TaskState, stage: number): boolean {
  return consecutiveAt(state, stage) >= ROLLBACK_LIMIT;
}

/**
 * Record a verdict, and move the task to that stage.
 *
 * The move is not a convenience. Without it the file can hold "currently at stage 1" beside
 * "three consecutive rounds at stage 4" — a state unreachable in reality, and one where the
 * escalation query silently answers about the wrong stage. A smoke test produced exactly
 * that: three rollbacks recorded, `show` exiting 0. A verdict IS evidence of where the task
 * is, so the two cannot be set independently.
 */
export function recordVerdict(state: TaskState, stage: number, verdict: string): TaskState {
  const round = (state.rounds[String(stage)] ?? 0) + 1;
  return {
    ...state,
    stage,
    rounds: { ...state.rounds, [String(stage)]: round },
    verdicts: [...state.verdicts, { stage, round, verdict }],
  };
}

export function advance(state: TaskState, stage: number): TaskState {
  return { ...state, stage };
}

/** A one-screen summary. This is what a cold session reads instead of asking the operator. */
export function summarize(state: TaskState): string[] {
  const out = [
    `${state.slug} — mode ${state.mode}, at stage ${state.stage}`,
    `  rounds: ${Object.keys(state.rounds).length === 0 ? 'none yet' : Object.entries(state.rounds).map(([s, n]) => `stage ${s}×${n}`).join(', ')}`,
  ];
  const recent = state.verdicts.slice(-3);
  if (recent.length > 0) {
    out.push('  recent verdicts:');
    for (const v of recent) out.push(`    stage ${v.stage} round ${v.round}: ${v.verdict}`);
  }
  const streak = consecutiveAt(state, state.stage);
  if (streak > 0) {
    out.push(`  consecutive rounds at stage ${state.stage}: ${streak}/${ROLLBACK_LIMIT}`);
  }
  if (mustEscalate(state, state.stage)) {
    out.push(`  ESCALATE — ${ROLLBACK_LIMIT} consecutive rounds at stage ${state.stage}. Stop and ask the human.`);
  }
  if (state.blocked !== null) out.push(`  BLOCKED — ${state.blocked}`);
  return out;
}

function flagValue(argv: readonly string[], name: string): string | undefined {
  const i = argv.indexOf(name);
  return i >= 0 ? argv[i + 1] : undefined;
}

export function run(argv: readonly string[], root: string, out: (s: string) => void): number {
  const cmd = argv[0] ?? '';
  const slug = argv[1] ?? '';

  if (cmd === '' || slug === '') {
    out('usage: task-state <show|init|verdict|advance|block|unblock> <slug> [flags]');
    out('');
    out('Holds the counters a routing decision depends on, and nothing else.');
    out(`Refuses to write past ${MAX_BYTES} bytes — a verdict is a verdict word, not a paragraph.`);
    return 2;
  }

  if (cmd === 'init') {
    const mode = (flagValue(argv, '--mode') ?? 'full') as Mode;
    if (!['full', 'plan', 'explore', 'goal'].includes(mode)) {
      out(`task-state: unrecognized mode ${JSON.stringify(mode)} (full|plan|explore|goal)`);
      return 2;
    }
    if (load(root, slug) !== null) {
      out(`task-state: ${slug} already exists — refusing to overwrite progress.`);
      return 1;
    }
    save(root, emptyState(slug, mode));
    out(`task-state: created ${statePath('', slug).replace(/^\//, '')} (mode ${mode})`);
    return 0;
  }

  const state = load(root, slug);
  if (state === null) {
    out(`task-state: no state for ${JSON.stringify(slug)}. Create it with: task-state init ${slug} --mode full`);
    return 1;
  }

  switch (cmd) {
    case 'show': {
      for (const line of summarize(state)) out(line);
      // Exit 3 makes the escalation actionable from a shell, not merely printed.
      return mustEscalate(state, state.stage) ? 3 : 0;
    }
    case 'verdict': {
      const stage = Number.parseInt(flagValue(argv, '--stage') ?? '', 10);
      const verdict = flagValue(argv, '--verdict');
      if (Number.isNaN(stage) || verdict === undefined) {
        out('task-state: verdict needs --stage <n> --verdict "<word>"');
        return 2;
      }
      const next = recordVerdict(state, stage, verdict);
      try {
        save(root, next);
      } catch (e) {
        out(String(e instanceof Error ? e.message : e));
        return 2;
      }
      for (const line of summarize(next)) out(line);
      return mustEscalate(next, stage) ? 3 : 0;
    }
    case 'advance': {
      const stage = Number.parseInt(flagValue(argv, '--stage') ?? '', 10);
      if (Number.isNaN(stage)) {
        out('task-state: advance needs --stage <n>');
        return 2;
      }
      save(root, advance(state, stage));
      out(`task-state: ${slug} now at stage ${stage}`);
      return 0;
    }
    case 'block': {
      const reason = flagValue(argv, '--reason');
      if (reason === undefined) {
        out('task-state: block needs --reason "<what the human must decide>"');
        return 2;
      }
      try {
        save(root, { ...state, blocked: reason });
      } catch (e) {
        out(String(e instanceof Error ? e.message : e));
        return 2;
      }
      out(`task-state: ${slug} blocked — ${reason}`);
      return 0;
    }
    case 'unblock': {
      save(root, { ...state, blocked: null });
      out(`task-state: ${slug} unblocked`);
      return 0;
    }
    default:
      out(`task-state: unrecognized command ${JSON.stringify(cmd)}`);
      return 2;
  }
}

if (require.main === module) {
  const root = path.resolve(__dirname, '../..');
  process.exit(run(process.argv.slice(2), root, (s) => process.stdout.write(`${s}\n`)));
}
