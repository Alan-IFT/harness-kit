/**
 * Native test suite for eval-anchors, plus the standing assertion that the shipped control
 * set has no rotted citations.
 *
 * The control set is the instrument every acceptance decision in this migration is argued
 * from. When the shell-to-TypeScript migration turned `guard-rm.sh` into a twelve-line
 * launcher, five of its anchors kept pointing at lines 191, 711 and 903 — and nothing
 * noticed, because only one of the four categories had a runner and the rest were scored by
 * reading. The last test in this file is what makes that impossible to repeat.
 */

import { describe, expect, it } from 'vitest';
import * as path from 'node:path';
import { parseAnchors, checkAnchors, resolveTarget, auditEvals } from '../../src/eval-anchors';

const ROOT = path.resolve(__dirname, '../..');

describe('what counts as a citation', () => {
  it('takes a path with a directory', () => {
    const got = parseAnchors('t.md', 'see `.harness/scripts/guard-rm.sh` for detail');
    expect(got).toHaveLength(1);
    expect(got[0]?.target).toBe('.harness/scripts/guard-rm.sh');
  });

  it('takes a bare filename when it carries a line number', () => {
    const got = parseAnchors('t.md', 'see `verify_all.sh:823`');
    expect(got).toHaveLength(1);
    expect(got[0]?.lines).toEqual([823]);
  });

  it('IGNORES a bare filename with neither mark', () => {
    // `PM_LOG.md` and `settings.json` appear throughout the control set as generic nouns.
    // Reading those as citations produced six false positives on the first run, and a check
    // that cries wolf gets disabled.
    expect(parseAnchors('t.md', 'the task\'s `PM_LOG.md` records it')).toEqual([]);
    expect(parseAnchors('t.md', 'edit `settings.json` by hand')).toEqual([]);
  });

  it('ignores prose that is not backticked', () => {
    expect(parseAnchors('t.md', 'see .harness/scripts/guard-rm.sh:711 for detail')).toEqual([]);
  });

  it('parses ranges and lists', () => {
    expect(parseAnchors('t.md', '`a/b.sh:79-119`')[0]?.lines).toEqual([79, 119]);
    expect(parseAnchors('t.md', '`a/b.sh:1,2,3`')[0]?.lines).toEqual([1, 2, 3]);
    // An en dash is what a writer actually types in a range.
    expect(parseAnchors('t.md', '`a/b.sh:79–119`')[0]?.lines).toEqual([79, 119]);
  });

  it('records where the citation appears, for a usable report', () => {
    const got = parseAnchors('t.md', ['line one', 'see `a/b.sh:5`'].join('\n'));
    expect(got[0]?.sourceLine).toBe(2);
    expect(got[0]?.source).toBe('t.md');
  });
});

describe('resolution', () => {
  it('resolves a path written the way a reader says it', () => {
    // The control set writes `verify_all.sh`, meaning the one under .harness/scripts/.
    expect(resolveTarget('verify_all.sh', ROOT)).toBe('.harness/scripts/verify_all.sh');
    expect(resolveTarget('.harness/scripts/verify_all.sh', ROOT)).toBe('.harness/scripts/verify_all.sh');
  });

  it('returns null when nothing resolves', () => {
    expect(resolveTarget('no/such/file.sh', ROOT)).toBeNull();
  });
});

describe('staleness detection', () => {
  it('reports a citation past the end of its file', () => {
    const anchors = parseAnchors('t.md', '`.harness/scripts/guard-rm.sh:9999`');
    const stale = checkAnchors(anchors, ROOT);
    expect(stale).toHaveLength(1);
    expect(stale[0]?.reason).toBe('line out of range');
  });

  it('reports a citation to a file that does not exist', () => {
    const stale = checkAnchors(parseAnchors('t.md', '`no/such/file.md`'), ROOT);
    expect(stale).toHaveLength(1);
    expect(stale[0]?.reason).toBe('missing file');
  });

  it('accepts a citation with no line number as long as the file exists', () => {
    expect(checkAnchors(parseAnchors('t.md', '`.harness/scripts/verify_all.sh`'), ROOT)).toEqual([]);
  });

  it('accepts a line number inside the file', () => {
    expect(checkAnchors(parseAnchors('t.md', '`.harness/scripts/guard-rm.sh:1`'), ROOT)).toEqual([]);
  });
});

describe('the shipped control set', () => {
  it('has no citation that fails to resolve', () => {
    const { anchors, stale } = auditEvals(ROOT);
    expect(anchors.length).toBeGreaterThan(20); // the check must not pass by finding nothing
    expect(stale.map((s) => `${s.source}:${s.sourceLine} ${s.raw} — ${s.detail}`)).toEqual([]);
  });
});
