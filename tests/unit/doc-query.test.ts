/**
 * Native test suite for doc-query.
 *
 * The behaviours under test are the ones the measurements bought:
 *   - a unit comes back WHOLE, because a line window either truncates a fact or drags in
 *     its neighbour (8/12 at ±2 lines, 10/12 at ±10, against 11/12 whole);
 *   - the unit boundary is resolved PER FILE, because one class-wide pattern shredded every
 *     decision record into bullets and cost 11/12 → 10/12;
 *   - heading matching answers "which section is X" rather than "where is X mentioned",
 *     which on stage documents is the difference between 1.4x and 11.6x;
 *   - an empty result names what it searched, because a bare "no results" is
 *     indistinguishable from having searched the wrong place.
 */

import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import * as fs from 'node:fs';
import * as os from 'node:os';
import * as path from 'node:path';
import { run, query, splitUnits, DOC_CLASSES, filesOf } from '../../src/doc-query';

let sandbox = '';

const write = (rel: string, body: string): void => {
  const p = path.join(sandbox, rel);
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, body);
};

const invoke = (...argv: string[]): { code: number; out: string } => {
  const lines: string[] = [];
  const code = run(argv, sandbox, (s) => lines.push(s));
  return { code, out: lines.join('\n') };
};

beforeEach(() => {
  sandbox = fs.mkdtempSync(path.join(os.tmpdir(), 'doc-query-test-'));
});
afterEach(() => {
  fs.rmSync(sandbox, { recursive: true, force: true });
});

describe('splitUnits', () => {
  it('keeps a wrapped bullet together as one unit', () => {
    const doc = ['# Header', '', '- first fact', '  continued', '  and more', '- second fact'].join('\n');
    const units = splitUnits(doc, /^- /);
    expect(units).toHaveLength(2);
    expect(units[0]?.text).toBe('- first fact\n  continued\n  and more');
  });

  it('drops the document header, which belongs to no unit', () => {
    expect(splitUnits(['# Title', '> note', '', '- only'].join('\n'), /^- /)).toHaveLength(1);
  });

  it('reports 1-based line numbers', () => {
    expect(splitUnits(['# T', '', '- fact'].join('\n'), /^- /)[0]?.line).toBe(3);
  });

  it('returns nothing when no line opens a unit', () => {
    expect(splitUnits('just prose', /^- /)).toEqual([]);
  });
});

describe('the unit boundary is per file, not per class', () => {
  // This is the regression that cost 11/12 -> 10/12: a heading-delimited store uses
  // bullets INSIDE a unit, so a combined `^(- |#{2,6} )` shreds each record.
  const memory = DOC_CLASSES.find((c) => c.scope === 'memory');

  it('opens insight-index units on a bullet', () => {
    expect(memory?.opens('.harness/insight-index.md').source).toBe('^- ');
  });

  it('opens every other store on a heading', () => {
    for (const f of ['.harness/rejected-decisions.md', 'CONTEXT.md', '.harness/decision-rubric.md']) {
      expect(memory?.opens(f).test('## slug'), f).toBe(true);
      expect(memory?.opens(f).test('- a bullet'), f).toBe(false);
    }
  });

  it('returns a whole decision record, not the bullet the match sat on', () => {
    write('.harness/rejected-decisions.md',
      ['# Declined', '', '## widget-rewrite', '- **Decision:** declined.', '- **Why:** it costs a NEEDLE.', '', '## other', '- unrelated'].join('\n'));
    const hits = query('needle', sandbox, { scope: 'memory' });
    expect(hits).toHaveLength(1);
    expect(hits[0]?.text).toContain('## widget-rewrite');
    expect(hits[0]?.text).toContain('**Decision:** declined.');
    expect(hits[0]?.text).not.toContain('## other');
  });
});

describe('scopes', () => {
  const seed = (): void => {
    write('.harness/insight-index.md', ['# I', '', '- a WIDGET fact', '  continued'].join('\n'));
    write('.harness/rules/70-doc-size.md', ['# R', '', '## Widget caps', 'body'].join('\n'));
    write('docs/features/_archived/task-a/02_SOLUTION_DESIGN.md', ['# D', '', '## Widget design', 'body'].join('\n'));
    write('docs/features/_archived/task-b/02_SOLUTION_DESIGN.md', ['# D', '', '## Widget design', 'other'].join('\n'));
  };

  it('searches every class by default', () => {
    seed();
    const out = invoke('widget').out;
    expect(out).toContain('.harness/insight-index.md');
    expect(out).toContain('.harness/rules/70-doc-size.md');
    expect(out).toContain('task-a/02_SOLUTION_DESIGN.md');
  });

  it.each([
    ['memory', '.harness/insight-index.md', '.harness/rules/'],
    ['rules', '.harness/rules/70-doc-size.md', '.harness/insight-index.md'],
    ['stage', 'task-a/02_SOLUTION_DESIGN.md', '.harness/rules/'],
  ])('--in %s includes %s and excludes %s', (scope, included, excluded) => {
    seed();
    const out = invoke('--in', scope, 'widget').out;
    expect(out).toContain(included);
    expect(out).not.toContain(excluded);
  });

  it('--task narrows the stage class to one slug', () => {
    seed();
    const out = invoke('--in', 'stage', '--task', 'task-a', 'widget').out;
    expect(out).toContain('task-a');
    expect(out).not.toContain('task-b');
  });

  it('ignores stage documents that are not numbered contracts or PM_LOG', () => {
    const stage = DOC_CLASSES.find((c) => c.scope === 'stage');
    expect(stage?.matches('docs/features/x/02_SOLUTION_DESIGN.md')).toBe(true);
    expect(stage?.matches('docs/features/x/PM_LOG.md')).toBe(true);
    expect(stage?.matches('docs/features/x/INPUT.md')).toBe(false);
    expect(stage?.matches('docs/features/x/SUPERVISION_REPORT.md')).toBe(false);
  });
});

describe('--heading answers a different question from a body match', () => {
  const seed = (): void => {
    write('docs/features/live/02_SOLUTION_DESIGN.md',
      ['# D', '', '## API contracts', 'the shape', '', '## Risks', 'a risk that mentions API contracts again', '', '## Change ledger', 'more prose about API contracts'].join('\n'));
  };

  it('a body match returns every section that mentions the phrase', () => {
    seed();
    expect(query('api contracts', sandbox, { scope: 'stage' })).toHaveLength(3);
  });

  it('a heading match returns only the section that IS it', () => {
    seed();
    const hits = query('api contracts', sandbox, { scope: 'stage', heading: true });
    expect(hits).toHaveLength(1);
    expect(hits[0]?.text).toContain('the shape');
  });

  it('the CLI exposes it as --heading', () => {
    seed();
    expect(invoke('--in', 'stage', 'api contracts').out).toContain('3 units');
    expect(invoke('--in', 'stage', '--heading', 'api contracts').out).toContain('1 unit');
  });
});

describe('cli', () => {
  it('says WHERE it looked when nothing matches', () => {
    write('.harness/insight-index.md', '- a fact');
    const r = invoke('nothing-matches');
    expect(r.code).toBe(1);
    expect(r.out).toContain('Searched');
    expect(r.out).toContain('document(s)');
  });

  it('suggests widening only when the scope was narrowed', () => {
    write('.harness/insight-index.md', '- a fact');
    expect(invoke('--in', 'memory', 'nope').out).toContain('--in all');
    expect(invoke('nope').out).not.toContain('--in all');
  });

  it('prints locations only under --files', () => {
    write('.harness/insight-index.md', ['- a WIDGET fact', '  with a body'].join('\n'));
    const r = invoke('--files', 'widget');
    expect(r.out).toContain('.harness/insight-index.md:1');
    expect(r.out).not.toContain('with a body');
  });

  it('--list enumerates the documents in scope without searching', () => {
    write('.harness/insight-index.md', '- x');
    write('.harness/rules/00-core.md', '## y');
    const r = invoke('--list');
    expect(r.code).toBe(0);
    expect(r.out).toContain('memory\t.harness/insight-index.md');
    expect(r.out).toContain('rules\t.harness/rules/00-core.md');
  });

  it('does not treat a flag value as part of the search term', () => {
    write('.harness/insight-index.md', '- a fact about memory');
    // `--in memory` must not also search for the word "memory" positionally.
    expect(invoke('--in', 'memory', 'fact').out).toContain('1 unit');
  });

  it('joins multi-word terms into one query', () => {
    write('.harness/insight-index.md', '- a fact about widgets');
    expect(invoke('about', 'widgets').code).toBe(0);
  });

  it('prints usage and exits 2 with no term', () => {
    const r = invoke();
    expect(r.code).toBe(2);
    expect(r.out).toContain('usage: doc-query');
  });

  it('treats a document class this project does not carry as empty, not an error', () => {
    expect(filesOf(DOC_CLASSES[1] as never, sandbox)).toEqual([]);
    expect(invoke('anything').code).toBe(1);
  });
});

describe('--for: the addressed read', () => {
  const gateReview = [
    '> Contract portion. Rationale: 03_RATIONALE.md (absent = none written).',
    '',
    '## Dimension audit',
    'audit body',
    '',
    '## Findings',
    'findings body',
    '',
    '## Binding conditions',
    'C-1 do the thing',
    '',
    '## Pre-answered developer questions',
    'Q-1 answered',
    '',
    '## 9. Round-1 closure',
    'invented section body',
    '',
    '## Verdict',
    'APPROVED',
  ].join('\n');

  it('returns the addressed sections and withholds the ones addressed elsewhere', () => {
    write('docs/features/t/03_GATE_REVIEW.md', gateReview);
    const r = invoke('--for', 'developer', '--task', 't');
    expect(r.code).toBe(0);
    expect(r.out).toContain('C-1 do the thing');
    expect(r.out).toContain('Q-1 answered');
    expect(r.out).not.toContain('findings body');
    expect(r.out).not.toContain('audit body');
  });

  it('returns an unrecognised section in full and names it', () => {
    write('docs/features/t/03_GATE_REVIEW.md', gateReview);
    const r = invoke('--for', 'developer', '--task', 't');
    expect(r.out).toContain('invented section body');
    expect(r.out).toContain('not in the declared schema');
    expect(r.out).toContain('"9. Round-1 closure"');
  });

  it('keeps a subheading with the section that addresses it', () => {
    write('docs/features/t/03_GATE_REVIEW.md', ['## Binding conditions', '### C-1', 'detail'].join('\n'));
    expect(invoke('--for', 'developer', '--task', 't').out).toContain('### C-1');
  });

  it('skips a document with no in-pipeline consumer', () => {
    write('docs/features/t/07_DELIVERY.md', '## Summary\nx');
    write('docs/features/t/PM_LOG.md', '## Round 1\nx');
    write('docs/features/t/03_GATE_REVIEW.md', gateReview);
    const r = invoke('--for', 'developer', '--task', 't');
    expect(r.out).not.toContain('07_DELIVERY');
    expect(r.out).not.toContain('PM_LOG');
  });

  it('reads an archived task as readily as a live one', () => {
    write('docs/features/_archived/t/03_GATE_REVIEW.md', gateReview);
    expect(invoke('--for', 'developer', '--task', 't').code).toBe(0);
  });

  it('refuses without a task, because addressing is per task', () => {
    const r = invoke('--for', 'developer');
    expect(r.code).toBe(2);
    expect(r.out).toContain('--task');
  });

  it('refuses an unknown role rather than returning nothing', () => {
    expect(invoke('--for', 'nobody', '--task', 't').code).toBe(2);
  });

  it('reports that the task has no stage contract instead of printing an empty read', () => {
    const r = invoke('--for', 'developer', '--task', 'absent');
    expect(r.code).toBe(1);
    expect(r.out).toContain('No stage contract');
  });
});
