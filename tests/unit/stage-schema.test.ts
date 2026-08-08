/**
 * Native test suite for stage-schema.
 *
 * The properties under test are the ones that make section addressing safe to run against a
 * corpus where 0 of 44 archived requirement documents conform to their declared schema:
 *
 *   - an UNRECOGNISED heading is kept, so an off-schema document costs the saving and never
 *     the completeness — this is the whole reason the mechanism could ship at all;
 *   - a section is withheld only on a positive statement that another role owns it;
 *   - heading normalisation is generous enough to accept the numbering every real document
 *     uses, and no two declared names collide under it;
 *   - the routing table and the authoring contracts that declare the same section lists are
 *     checked against each other, because they are one fact written twice.
 */

import { describe, expect, it } from 'vitest';
import * as fs from 'node:fs';
import * as os from 'node:os';
import * as path from 'node:path';
import {
  ROLES,
  STAGE_SCHEMA,
  checkAgainstContracts,
  docsAddressedTo,
  headingsOf,
  lintDocument,
  lintTask,
  normalizeHeading,
  resolveRole,
  resolveSection,
  run,
  sectionsDeclaredBy,
  select,
  specFor,
} from '../../src/stage-schema';

const repoRoot = path.resolve(__dirname, '../..');

const sandboxWith = (files: Record<string, string>): string => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'stage-schema-test-'));
  for (const [rel, body] of Object.entries(files)) {
    const p = path.join(dir, rel);
    fs.mkdirSync(path.dirname(p), { recursive: true });
    fs.writeFileSync(p, body);
  }
  return dir;
};

describe('normalizeHeading', () => {
  it('accepts the section numbering every archived document uses', () => {
    expect(normalizeHeading('## 3. In-scope behaviors')).toBe(normalizeHeading('## In-scope behaviors'));
  });

  it('accepts a hyphen where the schema writes a space', () => {
    expect(normalizeHeading('## Out-of-scope')).toBe(normalizeHeading('## Out of scope'));
  });

  it('reads & and the word and as the same conjunction', () => {
    expect(normalizeHeading('Migration & edit sequence')).toBe(normalizeHeading('Migration and edit sequence'));
  });

  it('does not merge two declared names anywhere in the schema', () => {
    for (const spec of STAGE_SCHEMA) {
      const keys = spec.sections.map((s) => normalizeHeading(s.name));
      expect(new Set(keys).size, `${spec.doc} has colliding section names`).toBe(keys.length);
    }
  });

  it('refuses a heading that merely starts with a declared name', () => {
    // The live task's `## 13. Change ledger and cap arithmetic` is a different section from
    // `## Change ledger`, and the lint saying so is the signal, not a false positive.
    expect(resolveSection('02_SOLUTION_DESIGN', '## 13. Change ledger and cap arithmetic')).toBeNull();
    expect(resolveSection('02_SOLUTION_DESIGN', '## 13. Change ledger')?.name).toBe('Change ledger');
  });
});

describe('select', () => {
  it('keeps an unrecognised heading — completeness is never traded for the saving', () => {
    const v = select('02_SOLUTION_DESIGN', '## 4. Transcription map', 'developer');
    expect(v).toEqual({ keep: true, undeclared: true, section: null });
  });

  it('withholds a declared section only when it is addressed elsewhere', () => {
    expect(select('03_GATE_REVIEW', '## Findings', 'developer').keep).toBe(false);
    expect(select('03_GATE_REVIEW', '## Binding conditions', 'developer').keep).toBe(true);
  });

  it('treats a document outside the schema as entirely unrecognised', () => {
    expect(select('07_DELIVERY', '## Summary', 'developer')).toEqual({ keep: true, undeclared: true, section: null });
  });
});

describe('the routing table itself', () => {
  it('gives every section at least one reader', () => {
    for (const spec of STAGE_SCHEMA) {
      for (const s of spec.sections) {
        expect(s.readers.length, `${spec.doc} ## ${s.name} is addressed to no one`).toBeGreaterThan(0);
      }
    }
  });

  it('names only known roles', () => {
    for (const spec of STAGE_SCHEMA) {
      for (const s of spec.sections) {
        for (const r of s.readers) expect(ROLES).toContain(r);
      }
    }
  });

  it('addresses something to every role that consumes an upstream contract', () => {
    for (const role of ROLES) {
      if (role === 'requirement-analyst') continue; // stage 1 consumes no stage contract but its own findings
      expect(docsAddressedTo(role).length, `${role} reads nothing`).toBeGreaterThan(0);
    }
  });

  it('covers stages 1 through 6 and stops there', () => {
    // 07_DELIVERY has no in-pipeline consumer, so it has no routing to declare.
    expect(STAGE_SCHEMA.map((s) => s.stage)).toEqual([1, 2, 3, 4, 5, 6]);
    expect(specFor('07_DELIVERY')).toBeNull();
  });
});

describe('sectionsDeclaredBy', () => {
  it('reads the section column of a contract schema table', () => {
    const contract = [
      '## What you produce',
      '',
      '| Section | Shape |',
      '|---|---|',
      '| `## Goal` | one statement |',
      '| `## Verdict` | one line |',
      '',
      'prose after the table',
    ].join('\n');
    expect(sectionsDeclaredBy(contract)).toEqual(['Goal', 'Verdict']);
  });

  it('ignores a table that is not the schema table', () => {
    const contract = ['| Mode | What it contains |', '|---|---|', '| `## Goal` | not a schema row |'].join('\n');
    expect(sectionsDeclaredBy(contract)).toEqual([]);
  });
});

describe('checkAgainstContracts', () => {
  it('is clean against this repo — the table and the playbooks agree', () => {
    expect(checkAgainstContracts(path.join(repoRoot, '.harness', 'playbooks'))).toEqual([]);
  });

  // The gate follows the table. At P4 the schema tables moved from `agents/<role>.md` to
  // `.harness/playbooks/<role>.md`; pointing `--check` at the old home has to report the loss
  // rather than pass on an empty read, or the split silently un-gates itself.
  it('reports the slimmed agent contracts as tableless, not as clean', () => {
    const findings = checkAgainstContracts(path.join(repoRoot, 'agents'));
    expect(findings.every((f) => f.kind === 'no-table')).toBe(true);
    expect(findings).toHaveLength(STAGE_SCHEMA.length);
  });

  it('reports a section a contract declares and the table does not', () => {
    const dir = sandboxWith({
      'requirement-analyst.md': ['| Section | Shape |', '|---|---|', '| `## Invented` | x |'].join('\n'),
    });
    const findings = checkAgainstContracts(dir);
    expect(findings.some((f) => f.kind === 'only-in-contract' && f.section === 'Invented')).toBe(true);
    expect(findings.some((f) => f.kind === 'only-in-schema' && f.section === 'Goal')).toBe(true);
    fs.rmSync(dir, { recursive: true, force: true });
  });

  it('reports a missing contract rather than passing silently', () => {
    const dir = sandboxWith({ 'placeholder.txt': 'x' });
    expect(checkAgainstContracts(dir).some((f) => f.kind === 'contract-missing')).toBe(true);
    fs.rmSync(dir, { recursive: true, force: true });
  });
});

describe('headingsOf', () => {
  it('ignores a ## line inside a fenced block', () => {
    const doc = ['## Real', '', '```markdown', '## Not a section', '```', '', '## Also real'].join('\n');
    expect(headingsOf(doc).map((h) => h.heading)).toEqual(['Real', 'Also real']);
  });

  it('reports 1-based lines', () => {
    expect(headingsOf(['# T', '', '## Goal'].join('\n'))[0]?.line).toBe(3);
  });
});

describe('lintDocument', () => {
  const full = STAGE_SCHEMA[2]?.sections.map((s) => `## ${s.name}`).join('\n\n') ?? '';

  it('passes a conforming document', () => {
    expect(lintDocument('03_GATE_REVIEW', full, '03.md')).toEqual([]);
  });

  it('flags an invented heading with its line', () => {
    const findings = lintDocument('03_GATE_REVIEW', `${full}\n\n## Round-1 closure`, '03.md');
    expect(findings).toHaveLength(1);
    expect(findings[0]?.kind).toBe('undeclared');
    expect(findings[0]?.heading).toBe('Round-1 closure');
  });

  it('flags a required section that is absent', () => {
    const findings = lintDocument('03_GATE_REVIEW', '## Verdict', '03.md');
    expect(findings.filter((f) => f.kind === 'missing').map((f) => f.heading)).toContain('Binding conditions');
  });

  it('does not require an optional section', () => {
    const sections = STAGE_SCHEMA[1]?.sections ?? [];
    const body = sections.filter((s) => s.optional !== true).map((s) => `## ${s.name}`).join('\n\n');
    expect(lintDocument('02_SOLUTION_DESIGN', body, '02.md')).toEqual([]);
  });
});

describe('lintTask', () => {
  it('finds a task in the archive as readily as in the live folder', () => {
    const dir = sandboxWith({ 'docs/features/_archived/t/03_GATE_REVIEW.md': '## Verdict' });
    expect(lintTask(dir, 't').dir).toBe(path.join('docs', 'features', '_archived', 't'));
    fs.rmSync(dir, { recursive: true, force: true });
  });

  it('does not treat a stage the task never reached as a finding', () => {
    const dir = sandboxWith({
      'docs/features/t/03_GATE_REVIEW.md': (STAGE_SCHEMA[2]?.sections ?? []).map((s) => `## ${s.name}`).join('\n\n'),
    });
    expect(lintTask(dir, 't').findings).toEqual([]);
    fs.rmSync(dir, { recursive: true, force: true });
  });
});

describe('cli', () => {
  const invoke = (root: string, ...argv: string[]): { code: number; out: string } => {
    const lines: string[] = [];
    const code = run(argv, root, (s) => lines.push(s));
    return { code, out: lines.join('\n') };
  };

  it('--map narrows to one role', () => {
    const all = invoke(repoRoot, '--map');
    const dev = invoke(repoRoot, '--map', '--for', 'dev');
    expect(all.code).toBe(0);
    expect(dev.out).toContain('## Binding conditions');
    expect(dev.out).not.toContain('## Dimension audit');
  });

  it('rejects an unknown role instead of returning an empty map', () => {
    expect(invoke(repoRoot, '--map', '--for', 'nobody').code).toBe(2);
  });

  it('accepts the long role name and the short alias alike', () => {
    expect(resolveRole('qa-tester')).toBe('qa-tester');
    expect(resolveRole('QA')).toBe('qa-tester');
    expect(resolveRole('nope')).toBeNull();
  });

  it('--lint exits 1 with findings and 0 without', () => {
    const dirty = sandboxWith({ 'docs/features/t/03_GATE_REVIEW.md': '## Made up' });
    expect(invoke(dirty, '--lint', '--task', 't').code).toBe(1);
    fs.rmSync(dirty, { recursive: true, force: true });

    const clean = sandboxWith({
      'docs/features/t/03_GATE_REVIEW.md': (STAGE_SCHEMA[2]?.sections ?? []).map((s) => `## ${s.name}`).join('\n\n'),
    });
    expect(invoke(clean, '--lint', '--task', 't').code).toBe(0);
    fs.rmSync(clean, { recursive: true, force: true });
  });

  it('--lint says so when the task folder does not exist', () => {
    const dir = sandboxWith({ 'placeholder.txt': 'x' });
    const r = invoke(dir, '--lint', '--task', 'absent');
    expect(r.code).toBe(2);
    expect(r.out).toContain('No task folder');
    fs.rmSync(dir, { recursive: true, force: true });
  });

  it('prints usage and exits 2 with no mode', () => {
    expect(invoke(repoRoot).code).toBe(2);
  });
});
