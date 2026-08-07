/**
 * Native test suite for memory-search.
 *
 * The behaviour under test is the reason the tool exists: entries come back WHOLE, the
 * stores are named so none can be silently missed, and an empty result says where it
 * looked. Each of those was a measured failure of plain search in
 * `evals/run-mem-baseline.sh`.
 */

import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import * as fs from 'node:fs';
import * as os from 'node:os';
import * as path from 'node:path';
import { run, search, splitEntries } from '../../src/memory-search';

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
  sandbox = fs.mkdtempSync(path.join(os.tmpdir(), 'memory-search-test-'));
});
afterEach(() => {
  fs.rmSync(sandbox, { recursive: true, force: true });
});

describe('splitEntries', () => {
  it('keeps a wrapped bullet together as one entry', () => {
    const doc = ['# Header', '', '- first fact', '  continued here', '  and here', '- second fact'].join('\n');
    const entries = splitEntries(doc, /^- /);
    expect(entries).toHaveLength(2);
    expect(entries[0]?.text).toBe('- first fact\n  continued here\n  and here');
    expect(entries[1]?.text).toBe('- second fact');
  });

  it('drops the document header, which belongs to no entry', () => {
    const doc = ['# Title', '> a note', '', '- only fact'].join('\n');
    expect(splitEntries(doc, /^- /)).toHaveLength(1);
  });

  it('reports 1-based line numbers', () => {
    const doc = ['# Title', '', '- fact'].join('\n');
    expect(splitEntries(doc, /^- /)[0]?.line).toBe(3);
  });

  it('splits heading-delimited stores too', () => {
    const doc = ['## alpha', 'body a', '## beta', 'body b'].join('\n');
    const entries = splitEntries(doc, /^## /);
    expect(entries.map((e) => e.text)).toEqual(['## alpha\nbody a', '## beta\nbody b']);
  });

  it('returns nothing for a document with no entries', () => {
    expect(splitEntries('just prose\nmore prose', /^- /)).toEqual([]);
  });
});

describe('search returns whole entries', () => {
  const STORE = [{ file: 'notes.md', opens: /^- /, primary: true }];

  it('returns the entire entry when the match is on a continuation line', () => {
    // This is the B3/B4 failure: a line window finds the keyword and truncates the fact.
    write('notes.md', ['- opening line', '  middle', '  the NEEDLE is far down here'].join('\n'));
    const hits = search('needle', STORE, sandbox);
    expect(hits).toHaveLength(1);
    expect(hits[0]?.text).toContain('opening line');
    expect(hits[0]?.text).toContain('NEEDLE');
  });

  it('matches case-insensitively', () => {
    write('notes.md', '- a BRACKET EXPRESSION fact');
    expect(search('bracket', STORE, sandbox)).toHaveLength(1);
  });

  it('does not drag in the neighbouring entry', () => {
    write('notes.md', ['- alpha needle', '- beta unrelated'].join('\n'));
    const hits = search('needle', STORE, sandbox);
    expect(hits).toHaveLength(1);
    expect(hits[0]?.text).not.toContain('beta');
  });

  it('treats a store this project does not carry as absent, not as an error', () => {
    expect(search('anything', STORE, sandbox)).toEqual([]);
  });
});

describe('cli', () => {
  const seed = (): void => {
    write('.harness/insight-index.md', ['# Insights', '', '- 2026-01-01 · a fact about widgets', '  with a continuation'].join('\n'));
    write('.harness/rejected-decisions.md', ['# Declined', '', '## widget-rewrite', '- **Decision:** declined.'].join('\n'));
    write('.harness/operator-obligations.md', ['# Duties', '', '### OB-1 — a widget duty on Windows'].join('\n'));
  };

  it('searches the primary stores by default and finds both', () => {
    seed();
    const r = invoke('widget');
    expect(r.code).toBe(0);
    expect(r.out).toContain('.harness/insight-index.md:3');
    expect(r.out).toContain('.harness/rejected-decisions.md:3');
  });

  it('leaves the off-path store out until --all', () => {
    seed();
    expect(invoke('widget').out).not.toContain('operator-obligations');
    expect(invoke('--all', 'widget').out).toContain('operator-obligations');
  });

  it('joins multi-word terms rather than treating them as separate queries', () => {
    seed();
    expect(invoke('about', 'widgets').code).toBe(0);
  });

  it('prints locations only under --files', () => {
    seed();
    const r = invoke('--files', 'widget');
    expect(r.out).toContain('.harness/insight-index.md:3');
    expect(r.out).not.toContain('continuation');
  });

  it('says WHERE it looked when nothing matches', () => {
    // A bare "no results" is indistinguishable from having searched the wrong place —
    // the exact failure that scored arm B1 at 0/12 while returning zero bytes.
    seed();
    const r = invoke('nothing-matches-this');
    expect(r.code).toBe(1);
    expect(r.out).toContain('Searched');
    expect(r.out).toContain('.harness/insight-index.md');
    expect(r.out).toContain('--all');
  });

  it('does not suggest --all when --all was already used', () => {
    seed();
    expect(invoke('--all', 'nothing-matches-this').out).not.toContain('Re-run with --all');
  });

  it('prints usage and exits 2 with no term', () => {
    const r = invoke();
    expect(r.code).toBe(2);
    expect(r.out).toContain('usage: memory-search');
  });
});
