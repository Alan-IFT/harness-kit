/**
 * Native tests for the SQLite sink.
 *
 * Three properties carry weight here and each has a test that would fail loudly if it broke:
 * idempotence (a re-seed writes nothing), freshness (a superseded record never reaches a
 * reader), and the token budget (whole records only — a half record reads as a complete one).
 */

import { describe, expect, it } from 'vitest';
import {
  DEFAULT_TOKEN_BUDGET,
  MemoryDbPathError,
  SqliteSink,
  resolveDbPath,
  toMatchQuery,
} from '../../src/memory-sink';
import { SeedRecord, makeRecord } from '../../src/memory-seed';

function rec(over: Partial<SeedRecord> & { title: string }): SeedRecord {
  return makeRecord({
    kind: over.kind ?? 'insight',
    title: over.title,
    body: over.body ?? over.title,
    date: over.date ?? '2026-01-01',
    sourceTask: over.sourceTask ?? '',
    evidence: over.evidence ?? [],
    tags: over.tags ?? [],
    ...(over.id === undefined ? {} : { id: over.id }),
    ...(over.seq === undefined ? {} : { seq: over.seq }),
  });
}

const sink = (): SqliteSink => new SqliteSink(':memory:');

describe('resolveDbPath', () => {
  it('prefers HARNESS_MEMORY_DB', () => {
    expect(resolveDbPath('/repo', { HARNESS_MEMORY_DB: '/tmp/x.db' })).toBe('/tmp/x.db');
  });

  it('falls back to CLAUDE_PLUGIN_DATA, then to the repo-local state directory', () => {
    expect(resolveDbPath('/repo', { CLAUDE_PLUGIN_DATA: '/data' })).toBe('/data/memory.db');
    expect(resolveDbPath('/repo', {})).toBe('/repo/.harness/state/memory.db');
  });

  it('refuses a path inside CLAUDE_PLUGIN_ROOT, which a plugin update discards', () => {
    expect(() =>
      resolveDbPath('/repo', { CLAUDE_PLUGIN_ROOT: '/cache/hk/0.52.0', CLAUDE_PLUGIN_DATA: '/cache/hk/0.52.0/data' }),
    ).toThrow(MemoryDbPathError);
  });

  it('allows a sibling of the plugin root whose path merely shares a prefix', () => {
    expect(() => resolveDbPath('/repo', { CLAUDE_PLUGIN_ROOT: '/cache/hk', HARNESS_MEMORY_DB: '/cache/hk-data/m.db' })).not.toThrow();
  });
});

describe('toMatchQuery', () => {
  it('ORs the content words and drops the stop words', () => {
    expect(toMatchQuery('what did we decide about the guard?')).toBe('"decide" OR "guard"');
  });

  it('quotes every token so punctuation cannot be read as FTS5 syntax', () => {
    // `NEAR`, `OR` and the parentheses are FTS5 operators; unquoted they are a syntax error.
    // Single characters are dropped as noise, which is why `(x)` contributes nothing.
    expect(toMatchQuery('verify_all "NEAR" OR (x) hook*')).toBe('"verify_all" OR "near" OR "hook"');
  });

  it('returns empty for a query with nothing searchable in it', () => {
    expect(toMatchQuery('the a of ???')).toBe('');
  });
});

describe('upsert', () => {
  it('inserts once, then skips an unchanged re-run entirely', () => {
    const s = sink();
    const records = [rec({ title: 'alpha guard' }), rec({ title: 'beta guard' })];
    expect(s.upsert(records)).toEqual({ inserted: 2, updated: 0, skipped: 0 });
    expect(s.upsert(records)).toEqual({ inserted: 0, updated: 0, skipped: 2 });
    s.close();
  });

  it('updates in place when the content changed but the seq did not', () => {
    const s = sink();
    s.upsert([rec({ id: 'insight:x', title: 'first', seq: 10 })]);
    expect(s.upsert([rec({ id: 'insight:x', title: 'second', seq: 10 })])).toEqual({ inserted: 0, updated: 1, skipped: 0 });
    expect(s.stats().total).toBe(1);
    s.close();
  });

  it('keeps the old row and marks the new one as superseding it', () => {
    const s = sink();
    s.upsert([rec({ id: 'insight:x', title: 'old', seq: 10 })]);
    s.upsert([rec({ id: 'insight:x', title: 'new', seq: 20 })]);
    const st = s.stats();
    expect(st.total).toBe(2);
    expect(st.current).toBe(1);
    expect(s.recent(null, 5)[0]?.supersedes).toBe('insight:x@10');
    s.close();
  });
});

describe('search', () => {
  it('finds a record by a word from its body', () => {
    const s = sink();
    s.upsert([rec({ title: 'the destructive-command guard fails open under set -e' })]);
    expect(s.search('guard').records).toHaveLength(1);
    s.close();
  });

  it('returns ONLY the newer record of a superseded pair — the conflict case', () => {
    // The hand-built conflict from the acceptance list: one decision, overturned later.
    const s = sink();
    s.upsert([
      rec({ id: 'decision:agent-cap', kind: 'decision', title: 'agent contracts are capped at 300 lines and 24 KB', date: '2026-08-01', sourceTask: 'T-18' }),
      rec({ id: 'decision:agent-cap', kind: 'decision', title: 'agent contracts are capped at 3 KB, workflow moves to a playbook', date: '2026-08-08', sourceTask: 'T-25' }),
    ]);
    const hits = s.search('agent contracts capped');
    expect(hits.records).toHaveLength(1);
    expect(hits.records[0]?.title).toContain('3 KB');
    expect(hits.records[0]?.date).toBe('2026-08-08');
    // The overturned decision is still on disk, and still not retrievable.
    expect(s.stats().total).toBe(2);
    expect(s.stats().current).toBe(1);
    s.close();
  });

  it('filters by kind', () => {
    const s = sink();
    s.upsert([rec({ title: 'guard note', kind: 'insight' }), rec({ title: 'guard choice', kind: 'decision' })]);
    expect(s.search('guard', { kinds: ['decision'] }).records.map((r) => r.kind)).toEqual(['decision']);
    s.close();
  });

  it('packs whole records only and reports the budget it stopped at', () => {
    const s = sink();
    s.upsert(Array.from({ length: 20 }, (_, i) => rec({ title: `guard finding number ${i} ${'padding '.repeat(40)}` })));
    const res = s.search('guard', { tokenBudget: 400, limit: 50 });
    expect(res.tokensUsed).toBeLessThanOrEqual(400);
    expect(res.tokensBudget).toBe(400);
    expect(res.truncated).toBe(true);
    expect(res.records.length).toBeGreaterThan(0);
    for (const r of res.records) expect(r.body.endsWith('padding ')).toBe(true);
    s.close();
  });

  it('honours the limit and flags that it dropped matches', () => {
    const s = sink();
    s.upsert(Array.from({ length: 8 }, (_, i) => rec({ title: `guard item ${i}` })));
    const res = s.search('guard', { limit: 3 });
    expect(res.records).toHaveLength(3);
    expect(res.truncated).toBe(true);
    s.close();
  });

  it('defaults to a 2000-token budget', () => {
    const s = sink();
    s.upsert([rec({ title: 'guard' })]);
    expect(s.search('guard').tokensBudget).toBe(DEFAULT_TOKEN_BUDGET);
    s.close();
  });

  it('returns nothing, and does not throw, for an unsearchable query', () => {
    const s = sink();
    s.upsert([rec({ title: 'guard' })]);
    expect(s.search('the of a').records).toHaveLength(0);
    s.close();
  });
});

describe('recent', () => {
  it('orders by seq descending and honours the kind filter', () => {
    const s = sink();
    s.upsert([
      rec({ id: 'insight:a', title: 'a', seq: 1 }),
      rec({ id: 'insight:b', title: 'b', seq: 3 }),
      rec({ id: 'decision:c', kind: 'decision', title: 'c', seq: 2 }),
    ]);
    expect(s.recent(null, 10).map((r) => r.title)).toEqual(['b', 'c', 'a']);
    expect(s.recent('decision', 10).map((r) => r.title)).toEqual(['c']);
    s.close();
  });

  it('never surfaces a superseded row', () => {
    const s = sink();
    s.upsert([rec({ id: 'insight:x', title: 'old', seq: 1 })]);
    s.upsert([rec({ id: 'insight:x', title: 'new', seq: 2 })]);
    expect(s.recent(null, 10).map((r) => r.title)).toEqual(['new']);
    s.close();
  });
});

describe('round trip', () => {
  it('preserves evidence, tags and supersedes through the database', () => {
    const s = sink();
    const r = makeRecord({
      kind: 'rejection',
      title: 'no proxy layer',
      body: 'declined',
      date: '2026-08-08',
      sourceTask: 'T-25',
      evidence: ['a.md:1', 'T-25'],
      tags: ['kind:rejection', 'verdict:declined'],
      supersedes: 'rejection:no-proxy@1',
    });
    s.upsert([r]);
    expect(s.recent(null, 1)[0]).toEqual(r);
    s.close();
  });
});
