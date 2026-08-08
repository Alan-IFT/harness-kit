/**
 * Native tests for the P0 batch runner.
 *
 * The cheap configurations shell out (grep over the repo, doc-query per term), so the tests
 * here exercise the pure halves — term derivation, scoring, summarising — plus one end-to-end
 * run of the `whole` configuration, which reads files and nothing else. A runner whose scoring
 * is untested reports a number nobody can argue with, which is worse than no number.
 */

import { describe, expect, it } from 'vitest';
import * as path from 'node:path';
import { loadCases, parseCases } from '../../src/eval-set';
import {
  CONFIGS,
  queryTerms,
  run,
  runConfig,
  scoreCase,
  summarize,
  type CaseResult,
} from '../../src/retrieval-eval';

const ROOT = path.resolve(__dirname, '../..');

const caseOf = (row: string) => parseCases(row)[0]!;

describe('queryTerms', () => {
  it('prefers a backticked symbol — a question naming one is asking about it', () => {
    expect(queryTerms('What does `isDescendant` decide?')[0]).toBe('isDescendant');
  });

  it('drops stop words and short words', () => {
    expect(queryTerms('What is the of and to')).toEqual([]);
  });

  it('caps at three, so a grep cannot become a whole-repo read', () => {
    expect(queryTerms('alphabetical beautifully consequential deliberately extraordinary')).toHaveLength(3);
  });

  it('is deterministic for the same question', () => {
    const q = 'Which checks are the doc-size guards?';
    expect(queryTerms(q)).toEqual(queryTerms(q));
  });

  it('orders the derived words longest first, ties alphabetically', () => {
    expect(queryTerms('gamma alphabet beta')).toEqual(['alphabet', 'gamma', 'beta']);
  });
});

describe('scoreCase', () => {
  const c = caseOf('| C1 | q | `alpha` and `beta` | `src/eval-set.ts` |');

  it('HIT when every checkable token is present', () => {
    expect(scoreCase(c, 'alpha beta').outcome).toBe('HIT');
  });

  it('PARTIAL when some are', () => {
    const r = scoreCase(c, 'alpha only');
    expect(r.outcome).toBe('PARTIAL');
    expect(r.found).toBe(1);
    expect(r.wanted).toBe(2);
  });

  it('MISS when none are', () => {
    expect(scoreCase(c, 'nothing relevant').outcome).toBe('MISS');
  });

  it('N/A for a prose answer, never MISS', () => {
    // Folding the 18 prose cases into MISS pinned every configuration near 0.5 and made the
    // ceiling read as the floor.
    const prose = caseOf('| C1 | q | a prose answer | `src/eval-set.ts` |');
    const r = scoreCase(prose, '');
    expect(r.outcome).toBe('N/A');
    expect(r.wanted).toBe(0);
  });
});

describe('summarize', () => {
  const mk = (outcome: CaseResult['outcome'], bytes: number): CaseResult => ({
    id: 'X', category: 'CODE', outcome, found: 0, wanted: 0, bytes, ms: 0, terms: [],
  });

  it('scores over the scorable cases only', () => {
    const s = summarize([mk('HIT', 100), mk('MISS', 100), mk('N/A', 100)]);
    expect(s.n).toBe(2);
    expect(s.na).toBe(1);
    expect(s.score).toBe(0.5);
  });

  it('counts a PARTIAL as a half', () => {
    expect(summarize([mk('HIT', 0), mk('PARTIAL', 0)]).score).toBe(0.75);
  });

  it('means bytes over EVERY case — retrieval costs the same whether scorable or not', () => {
    expect(summarize([mk('HIT', 100), mk('N/A', 300)]).meanBytes).toBe(200);
  });

  it('reports zero rather than dividing by zero on an empty set', () => {
    expect(summarize([])).toMatchObject({ n: 0, score: 0, meanBytes: 0 });
  });
});

describe('the whole configuration against the shipped set', () => {
  const rep = runConfig(loadCases(ROOT), 'whole', ROOT);

  it('is the ceiling by construction — it reads the file the answer was taken from', () => {
    const s = summarize(rep.results);
    expect(s.score).toBe(1);
    expect(s.n).toBeGreaterThan(10);
  });

  it('is repeatable — a second run agrees case for case', () => {
    const again = runConfig(loadCases(ROOT), 'whole', ROOT);
    expect(again.results.map((r) => [r.id, r.outcome, r.bytes])).toEqual(
      rep.results.map((r) => [r.id, r.outcome, r.bytes]),
    );
  });
});

describe('cli', () => {
  const capture = (argv: string[]): { code: number; lines: string[] } => {
    const lines: string[] = [];
    const code = run(argv, ROOT, (s) => lines.push(s));
    return { code, lines };
  };

  it('rejects an unknown config rather than silently defaulting', () => {
    expect(capture(['--config', 'telepathy']).code).toBe(2);
  });

  it('rejects an unknown category', () => {
    expect(capture(['--category', 'PROSE', '--config', 'whole']).code).toBe(2);
  });

  it('emits json with no timing field, so two runs are byte-identical', () => {
    const { code, lines } = capture(['--config', 'whole', '--category', 'RULE', '--json']);
    expect(code).toBe(0);
    const parsed = JSON.parse(lines.join('')) as { config: string; cases: { id: string }[] }[];
    expect(parsed[0]?.config).toBe('whole');
    expect(lines.join('')).not.toContain('"ms"');
  });

  it('names every configuration in its usage surface', () => {
    expect([...CONFIGS]).toEqual(['whole', 'grep', 'query']);
  });
});
