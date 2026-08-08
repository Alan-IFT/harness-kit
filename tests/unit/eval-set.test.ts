/**
 * Native tests for the control-set parser and its claim checker, plus the standing assertion
 * that the shipped control set carries no rotted claim.
 *
 * `eval-anchors` already fails the build on a citation that stops resolving. It passed clean
 * while four of ten CODE items were false — a resolving anchor says the FILE is still there
 * and nothing about whether the answer still is. The last test in this file is what closes
 * that half of the gap.
 */

import { describe, expect, it } from 'vitest';
import * as path from 'node:path';
import {
  CATEGORIES,
  anchorPaths,
  backticked,
  checkClaims,
  isCheckableToken,
  loadCases,
  parseCases,
  run,
  splitRow,
} from '../../src/eval-set';

const ROOT = path.resolve(__dirname, '../..');

describe('splitRow', () => {
  it('splits an ordinary row', () => {
    expect(splitRow('| C1 | q | a | anchor |')).toEqual(['C1', 'q', 'a', 'anchor']);
  });

  it('keeps an escaped pipe inside its cell', () => {
    // The schema tables write `id \| path \| what changes`. Splitting on it shifts every
    // later column by one and turns the whole file into findings.
    expect(splitRow('| C1 | rows `a \\| b` | x | y |')).toEqual(['C1', 'rows `a | b`', 'x', 'y']);
  });

  it('trims surrounding space', () => {
    expect(splitRow('|  a  |  b  |')).toEqual(['a', 'b']);
  });
});

describe('parseCases', () => {
  const doc = [
    '| ID | Question | Expected answer | Anchor |',
    '|---|---|---|---|',
    '| C1 | q1 | `alpha` | `src/x.ts` |',
    '| M3 | q2 | prose | `docs/y.md` |',
    '| X9 | not a category | z | z |',
    '| not-an-id | q | a | b |',
  ].join('\n');

  it('takes a row per case and reads the category from the id', () => {
    const cases = parseCases(doc);
    expect(cases.map((c) => c.id)).toEqual(['C1', 'M3']);
    expect(cases.map((c) => c.category)).toEqual(['CODE', 'MEM']);
  });

  it('reports a 1-based line so a finding is navigable', () => {
    expect(parseCases(doc)[0]?.line).toBe(3);
  });

  it('ignores a table inside a fenced block', () => {
    const fenced = ['```markdown', '| C1 | q | a | b |', '```'].join('\n');
    expect(parseCases(fenced)).toEqual([]);
  });

  it('does not depend on which heading the row sits under', () => {
    // The category IS the id prefix, so a reworded section heading cannot misfile a case.
    const moved = ['## MEM', '| C1 | q | `alpha` | `src/x.ts` |'].join('\n');
    expect(parseCases(moved)[0]?.category).toBe('CODE');
  });
});

describe('backticked', () => {
  it('returns spans in order without duplicates', () => {
    expect(backticked('`a`, `b`, then `a` again')).toEqual(['a', 'b']);
  });

  it('returns nothing for prose', () => {
    expect(backticked('no code spans here')).toEqual([]);
  });
});

describe('isCheckableToken', () => {
  it('takes an identifier', () => {
    expect(isCheckableToken('isDescendant')).toBe(true);
    expect(isCheckableToken('TOOLS')).toBe(true);
    expect(isCheckableToken('archive-task')).toBe(true);
  });

  it('rejects a path — that is the anchor checker\'s job, and double-reporting one defect is noise', () => {
    expect(isCheckableToken('src/guard-rm.ts')).toBe(false);
  });

  it('rejects prose and regexes', () => {
    expect(isCheckableToken('## reviewer-write-grant')).toBe(false);
    expect(isCheckableToken('[A-J]\\.[0-9]+')).toBe(false);
  });

  it('rejects a dotted placeholder but keeps a dotted filename', () => {
    // `X.N` and `G.4` are check-id templates: the file contains what they match, never them.
    expect(isCheckableToken('X.N')).toBe(false);
    expect(isCheckableToken('G.4')).toBe(false);
    expect(isCheckableToken('settings.json')).toBe(true);
  });

  it('rejects a bare integer — the stated limit', () => {
    expect(isCheckableToken('35')).toBe(false);
  });
});

describe('anchorPaths', () => {
  it('resolves a repo-relative path', () => {
    expect(anchorPaths('`src/eval-set.ts`', ROOT)).toEqual(['src/eval-set.ts']);
  });

  it('strips a line suffix', () => {
    expect(anchorPaths('`AI-GUIDE.md:27`', ROOT)).toEqual(['AI-GUIDE.md']);
  });

  it('finds a bare script name under .harness/scripts/', () => {
    expect(anchorPaths('`verify_all.sh`', ROOT)).toEqual(['.harness/scripts/verify_all.sh']);
  });

  it('expands one star in one segment', () => {
    const got = anchorPaths('`docs/features/_archived/*/07_DELIVERY.md`', ROOT);
    expect(got.length).toBeGreaterThan(10);
    expect(got.every((p) => p.endsWith('/07_DELIVERY.md'))).toBe(true);
  });

  it('returns nothing for an unresolvable anchor rather than throwing', () => {
    expect(anchorPaths('`no/such/file.md`', ROOT)).toEqual([]);
  });
});

describe('checkClaims', () => {
  it('flags a symbol the anchor no longer contains', () => {
    const cases = parseCases('| C1 | q | `thisSymbolDoesNotExistAnywhere` | `src/eval-set.ts` |');
    const findings = checkClaims(cases, ROOT);
    expect(findings).toHaveLength(1);
    expect(findings[0]?.kind).toBe('symbol-absent');
  });

  it('passes a symbol the anchor does contain', () => {
    const cases = parseCases('| C1 | q | `isCheckableToken` | `src/eval-set.ts` |');
    expect(checkClaims(cases, ROOT)).toEqual([]);
  });

  it('says nothing about a prose answer — it has no claim to check', () => {
    const cases = parseCases('| C1 | q | plain prose answer | `src/eval-set.ts` |');
    expect(checkClaims(cases, ROOT)).toEqual([]);
  });

  it('reports an unreadable anchor only when there IS a claim behind it', () => {
    const withClaim = parseCases('| C1 | q | `alpha` | `no/such/file.md` |');
    expect(checkClaims(withClaim, ROOT).map((f) => f.kind)).toEqual(['anchor-unreadable']);
    const withoutClaim = parseCases('| C1 | q | prose | `no/such/file.md` |');
    expect(checkClaims(withoutClaim, ROOT)).toEqual([]);
  });
});

describe('the shipped control set', () => {
  it('parses into every category', () => {
    const cases = loadCases(ROOT);
    for (const k of CATEGORIES) {
      expect(cases.filter((c) => c.category === k).length).toBeGreaterThan(0);
    }
    expect(cases.length).toBeGreaterThanOrEqual(30); // the brief's floor
  });

  it('carries no rotted claim — every backticked Expected token resolves in its anchor', () => {
    expect(checkClaims(loadCases(ROOT), ROOT)).toEqual([]);
  });

  it('every case id is unique', () => {
    const ids = loadCases(ROOT).map((c) => c.id);
    expect(new Set(ids).size).toBe(ids.length);
  });
});

describe('cli', () => {
  const capture = (argv: string[]): { code: number; lines: string[] } => {
    const lines: string[] = [];
    const code = run(argv, ROOT, (s) => lines.push(s));
    return { code, lines };
  };

  it('--check exits 0 on the shipped set', () => {
    expect(capture(['--check']).code).toBe(0);
  });

  it('--list filters by category', () => {
    const { code, lines } = capture(['--list', '--category', 'RULE']);
    expect(code).toBe(0);
    expect(lines.every((l) => l.includes('\tRULE\t'))).toBe(true);
  });

  it('prints usage and exits 2 with no recognised flag', () => {
    expect(capture([]).code).toBe(2);
  });
});
