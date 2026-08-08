/**
 * Native tests for the seed parsers.
 *
 * The load-bearing ones are the freshness tests at the bottom. `computeSeq` is the single
 * place this system decides which of two records is newer, and it decides arithmetically on
 * purpose — the tests pin both the ordering it produces AND the two real cases from this
 * repo's history that break the rule the work order originally specified (slug-number first).
 */

import { describe, expect, it } from 'vitest';
import * as path from 'node:path';
import {
  computeSeq,
  contentHash,
  dedupe,
  firstSentence,
  groupInsightEntries,
  harvest,
  makeRecord,
  parseDelivery,
  parseGlossary,
  parseInsightFile,
  parseInsightLine,
  parseRejections,
  parseRubric,
  parseTaskBoard,
  slugify,
  taskNumber,
} from '../../src/memory-seed';

const ROOT = path.resolve(__dirname, '../..');

describe('parseInsightLine', () => {
  it('splits date, fact and evidence', () => {
    const r = parseInsightLine('- 2026-08-01 · A guard fails open under set -e. · evidence: guard-cmd-chain');
    expect(r).not.toBeNull();
    expect(r?.date).toBe('2026-08-01');
    expect(r?.fact).toBe('A guard fails open under set -e.');
    expect(r?.evidence).toEqual(['guard-cmd-chain']);
  });

  it('splits on the LAST evidence marker, because facts contain the separator too', () => {
    const r = parseInsightLine('- 2026-08-01 · a · b · c · evidence: T-17');
    expect(r?.fact).toBe('a · b · c');
    expect(r?.evidence).toEqual(['T-17']);
  });

  it('splits a multi-part evidence list', () => {
    const r = parseInsightLine('- 2026-05-16 · x · evidence: commit 336e029; v0.10.0 edit (commit 31fb520)');
    expect(r?.evidence).toEqual(['commit 336e029', 'v0.10.0 edit (commit 31fb520)']);
  });

  it('keeps an entry that carries no evidence pointer', () => {
    const r = parseInsightLine('- 2026-05-16 · a bare fact');
    expect(r?.fact).toBe('a bare fact');
    expect(r?.evidence).toEqual([]);
  });

  it('rejects the template placeholder the insight files ship', () => {
    expect(parseInsightLine('- YYYY-MM-DD · <one-sentence fact> · evidence: <task-slug or commit-sha>')).toBeNull();
  });

  it('rejects a bullet that is not an insight', () => {
    expect(parseInsightLine('- Task: `review-write-path` (T-23)')).toBeNull();
  });
});

describe('groupInsightEntries', () => {
  it('folds continuation lines into the bullet above them', () => {
    const entries = groupInsightEntries(['- 2026-08-01 · first part', '  wrapped continuation', '- 2026-08-02 · second']);
    expect(entries).toHaveLength(2);
    expect(entries[0]?.text).toBe('- 2026-08-01 · first part wrapped continuation');
  });

  it('reports the physical line each entry started on', () => {
    const entries = groupInsightEntries(['', '- a', '  b', '', '- c'], 10);
    expect(entries.map((e) => e.line)).toEqual([11, 14]);
  });

  it('does not merge across a blank line', () => {
    const entries = groupInsightEntries(['- a', '', '  orphan']);
    expect(entries).toHaveLength(1);
  });
});

describe('parseInsightFile', () => {
  it('skips the header prose and the HTML comment block', () => {
    const md = [
      '# Insight Index',
      '',
      '> Read this at the start of a task.',
      '',
      '<!-- Append below, one per line. Format:',
      '- YYYY-MM-DD · <one-sentence fact> · evidence: <ref>',
      '-->',
      '- 2026-08-01 · A real fact. · evidence: T-17',
    ].join('\n');
    const r = parseInsightFile(md, 'x.md');
    expect(r.records).toHaveLength(1);
    expect(r.unparsed).toHaveLength(0);
  });

  it('collects an unrecognised bullet instead of dropping it', () => {
    const r = parseInsightFile('- not an insight at all\n', 'x.md');
    expect(r.records).toHaveLength(0);
    expect(r.unparsed[0]?.reason).toBe('not-an-insight-bullet');
    expect(r.unparsed[0]?.line).toBe(1);
  });
});

describe('parseDelivery', () => {
  const doc = [
    '# Delivery Summary',
    '',
    '## Summary',
    '',
    '- Task: `demo` (T-42) — do the thing.',
    '- Mode: **full** (stages 1-7)',
    '- Rollbacks: **2** — the gate returned twice.',
    '- Final verify_all result: **PASS 32 / WARN 0 / FAIL 0**',
    '- Something Else: ignored',
    '',
    '## Insight',
    '',
    '- 2026-08-02 · An insight that wraps',
    '  onto a second line. · evidence: T-42',
    '',
    '## Verdict',
    '',
    'DELIVERED',
  ].join('\n');

  it('pulls the contract key bullets and ignores unknown keys', () => {
    const f = parseDelivery(doc);
    expect(f.summary['Mode']).toBe('**full** (stages 1-7)');
    expect(f.summary['Rollbacks']).toBe('**2** — the gate returned twice.');
    expect(f.summary['Something Else']).toBeUndefined();
  });

  it('reads the verdict and the task id', () => {
    const f = parseDelivery(doc);
    expect(f.verdict).toBe('DELIVERED');
    expect(f.taskId).toBe('T-42');
    expect(f.date).toBe('2026-08-02');
  });

  it('keeps a wrapped insight whole', () => {
    const f = parseDelivery(doc);
    expect(f.insights).toHaveLength(1);
    expect(f.insights[0]?.text).toContain('onto a second line');
  });

  it('matches ## Insight BARE, exactly as archive-task harvests it', () => {
    // A suffixed heading is skipped by `archive-task.sh`; indexing it here would put insights
    // into memory that the project's own harvester never accepted.
    const f = parseDelivery('## Insight (carried)\n\n- 2026-08-02 · x · evidence: y\n');
    expect(f.insights).toHaveLength(0);
    expect(parseDelivery('## Insights\n\n- 2026-08-02 · x · evidence: y\n').insights).toHaveLength(1);
  });

  it('finds a bare verdict token when the document has no ## Verdict heading', () => {
    expect(parseDelivery('# D\n\nsome prose\n\n**DECLINED**\n').verdict).toBe('DECLINED');
  });
});

describe('parseRejections', () => {
  const md = [
    '## design-it-twice',
    '- **Decision:** deferred (not now).',
    '- **Why:** a parallel-exploration pattern; useful but not yet pulled in.',
    '- **Origin:** T-07 design-vocab discussion.',
    '',
    '## some-approach',
    '- **Decision:** declined.',
    '- **Why:** it duplicates an existing router.',
    '- **Adopted instead:** the AI-GUIDE workflow-entry table.',
    '- **Origin:** batch.',
  ].join('\n');

  it('marks a deferral as deferred and a decline as declined', () => {
    const r = parseRejections(md, 'rej.md');
    const deferred = r.records.find((x) => x.id === 'rejection:design-it-twice');
    expect(deferred?.tags).toContain('verdict:deferred');
    expect(r.records.find((x) => x.id === 'rejection:some-approach')?.tags).toContain('verdict:declined');
  });

  it('emits a paired decision only when the entry names what was adopted', () => {
    const r = parseRejections(md, 'rej.md');
    expect(r.records.filter((x) => x.kind === 'decision').map((x) => x.id)).toEqual(['decision:some-approach']);
  });

  it('folds a wrapped field value into that field', () => {
    const r = parseRejections('## x\n- **Why:** first line\n  second line\n', 'rej.md');
    expect(r.records[0]?.body).toContain('first line second line');
  });

  it('reports a heading carrying no Decision or Why', () => {
    const r = parseRejections('## empty-one\nprose only\n', 'rej.md');
    expect(r.records).toHaveLength(0);
    expect(r.unparsed[0]?.reason).toBe('no Decision/Why fields');
  });
});

describe('parseGlossary', () => {
  const md = [
    '## Language',
    '',
    '**Frontier**:',
    'The set of pool tasks that are runnable right now.',
    '_Avoid_: ready set, runnable queue',
    '',
    '**Pool** (living pool):',
    'The mutable list a stream drains.',
  ].join('\n');

  it('reads term, definition and the avoid list', () => {
    const r = parseGlossary(md, 'CONTEXT.md');
    expect(r.records).toHaveLength(2);
    expect(r.records[0]?.id).toBe('term:frontier');
    expect(r.records[0]?.body).toContain('runnable right now');
    expect(r.records[0]?.body).toContain('ready set, runnable queue');
  });

  it('keeps a parenthesised alias out of the term name', () => {
    expect(parseGlossary(md, 'CONTEXT.md').records[1]?.id).toBe('term:pool');
  });

  it('tags the term with its glossary section', () => {
    expect(parseGlossary(md, 'CONTEXT.md').records[0]?.tags).toContain('glossary:language');
  });
});

describe('parseRubric', () => {
  it('turns each standing preference into a decision record', () => {
    const md = [
      '## Preset rubric (Mode 2)',
      '',
      '### Standing preferences',
      '',
      '- **Lightweight over heavy.** Drop over-built modules;',
      '  prefer the smallest thing that meets the bar.',
      '- **Honest reporting, always.** Never fabricate tallies.',
    ].join('\n');
    const r = parseRubric(md, 'rub.md');
    expect(r.records).toHaveLength(2);
    expect(r.records[0]?.kind).toBe('decision');
    expect(r.records[0]?.id).toBe('decision:rubric-lightweight-over-heavy');
    expect(r.records[0]?.body).toContain('smallest thing that meets the bar');
  });
});

describe('parseTaskBoard', () => {
  const md = [
    '## Active tasks',
    '| ID | Slug | Stage | Mode | Started | Doc folder |',
    '|---|---|---|---|---|---|',
    '| _(none)_ | | | | | |',
    '',
    '## Completed tasks',
    '| ID | Slug | Outcome | Completed | Doc folder |',
    '|---|---|---|---|---|',
    '| T-23 | review-write-path | Delivered v0.46.0 (1 rollback) | 2026-08-02 | `docs/features/_archived/review-write-path/` |',
  ].join('\n');

  it('reads completed rows and skips the header and the empty active row', () => {
    const r = parseTaskBoard(md, 'tasks.md');
    expect(r.rows).toHaveLength(1);
    expect(r.rows[0]?.slug).toBe('review-write-path');
    expect(r.rows[0]?.completed).toBe('2026-08-02');
    expect(r.rows[0]?.active).toBe(false);
    expect(r.unparsed).toHaveLength(0);
  });
});

// ── freshness ────────────────────────────────────────────────────────────────

describe('computeSeq — the deterministic freshness key', () => {
  it('orders by date first', () => {
    expect(computeSeq('2026-08-02', 'T-23')).toBeGreaterThan(computeSeq('2026-08-01', 'T-99'));
  });

  it('breaks a same-day tie by task number', () => {
    expect(computeSeq('2026-08-01', 'T-20')).toBeGreaterThan(computeSeq('2026-08-01', 'T-17'));
  });

  it('does NOT let the slug number invert this repo\'s two numbering families', () => {
    // The real regression the work order's "slug number first" rule would have caused: the
    // task board restarted at T-01, so T-022 (2026-06-13) predates T-02 (2026-06-19) and
    // T-003 (2026-05-19) predates T-03 (2026-06-19) — as integers they interleave and collide.
    expect(taskNumber('T-022')).toBe(22);
    expect(taskNumber('T-02')).toBe(2);
    expect(taskNumber('T-003')).toBe(taskNumber('T-03'));
    expect(computeSeq('2026-06-19', 'T-02')).toBeGreaterThan(computeSeq('2026-06-13', 'T-022'));
    expect(computeSeq('2026-06-19', 'T-03')).toBeGreaterThan(computeSeq('2026-05-19', 'T-003'));
  });

  it('sorts a dateless record below every dated one rather than crashing', () => {
    expect(computeSeq('', '')).toBe(0);
    expect(computeSeq('', 'T-99')).toBeLessThan(computeSeq('2026-01-01', 'T-01'));
  });
});

describe('dedupe', () => {
  const mk = (id: string, seq: number, body: string) =>
    makeRecord({ id, kind: 'insight', title: id, body, seq, date: '', sourceTask: '', evidence: [], tags: [] });

  it('keeps the higher seq and records what it superseded', () => {
    const out = dedupe([mk('a', 10, 'old'), mk('a', 20, 'new')]);
    expect(out).toHaveLength(1);
    expect(out[0]?.body).toBe('new');
    expect(out[0]?.supersedes).toBe('a@10');
  });

  it('is order-independent', () => {
    expect(dedupe([mk('a', 20, 'new'), mk('a', 10, 'old')])[0]?.body).toBe('new');
  });

  it('leaves an identical duplicate untouched, with no supersedes marker', () => {
    const out = dedupe([mk('a', 10, 'same'), mk('a', 20, 'same')]);
    expect(out).toHaveLength(1);
    expect(out[0]?.supersedes).toBeUndefined();
  });
});

describe('slugify / contentHash', () => {
  it('gives two long titles sharing a prefix distinct ids', () => {
    const prefix = 'a very long insight sentence that goes on and on and on for quite a while indeed';
    expect(slugify(`${prefix} one`)).not.toBe(slugify(`${prefix} two`));
  });

  it('is stable across calls', () => {
    expect(slugify('Stage doc')).toBe(slugify('Stage doc'));
    expect(contentHash('t', 'b')).toBe(contentHash('t', 'b'));
    expect(contentHash('t', 'b')).not.toBe(contentHash('t', 'c'));
  });

  it('truncates a long fact to a scannable title', () => {
    expect(firstSentence('x'.repeat(500)).length).toBeLessThanOrEqual(241);
  });
});

// ── the shipped corpus ───────────────────────────────────────────────────────

describe('harvest on this repository', () => {
  const result = harvest(ROOT);

  it('clears the acceptance floor of 60 insight + decision records', () => {
    const n = result.records.filter((r) => r.kind === 'insight' || r.kind === 'decision').length;
    expect(n).toBeGreaterThanOrEqual(60);
  });

  it('produces records of every kind', () => {
    for (const k of ['decision', 'insight', 'rejection', 'term', 'outcome']) {
      expect(result.records.filter((r) => r.kind === k).length).toBeGreaterThan(0);
    }
  });

  it('leaves no record without an id, a title or a content hash', () => {
    for (const r of result.records) {
      expect(r.id).not.toBe('');
      expect(r.title).not.toBe('');
      expect(r.contentHash).toHaveLength(64);
    }
  });

  it('assigns every id exactly once', () => {
    const ids = result.records.map((r) => r.id);
    expect(new Set(ids).size).toBe(ids.length);
  });

  it('is deterministic — two harvests of the same tree agree byte for byte', () => {
    expect(JSON.stringify(harvest(ROOT))).toBe(JSON.stringify(result));
  });

  it('leaves only the two known-benign unparsed lines', () => {
    // Both are correct refusals, not parser gaps: the insight-history file really does carry
    // the template's own placeholder bullet (harvested verbatim, once), and T-24
    // `operator-obligation-home` really has no `07_DELIVERY.md` — it never wrote stages 4-7,
    // though its output did ship in 9036590. Any THIRD entry here is a regression.
    expect(result.unparsed.map((u) => u.reason).sort()).toEqual([
      'archived task has no 07_DELIVERY.md',
      'template-placeholder',
    ]);
  });
});
