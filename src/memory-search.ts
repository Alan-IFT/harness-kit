/**
 * memory-search — entry-aware search over this project's decided history.
 *
 * WHY THIS EXISTS. `evals/run-mem-baseline.sh` measured four retrieval arms over the MEM
 * control set and found two problems that are not fixed by a better backend:
 *
 *   1. A repo-wide search that skips dot-directories scores **0 of 12** and returns zero
 *      bytes, so it reads as "no results" rather than "wrong search". Every memory store
 *      in this project lives under `.harness/`, and ripgrep — which Claude Code's Grep
 *      tool is built on — skips dot-directories by default.
 *   2. A scoped search at ±2 lines scores 7/12 and at ±10 lines scores 9/12, because one
 *      fact is stored as one long wrapped paragraph. A line window either truncates the
 *      fact or drags in its neighbours.
 *
 * This tool answers both by construction rather than by instruction: the stores are named
 * here so they cannot be missed, and the unit returned is the **whole entry** containing
 * the match, so a hit is never a window into a fact.
 *
 * It deliberately does NOT summarise, index or copy anything. The entry it prints is the
 * original text at its original location — the `stage-doc-summary-header` decline applies
 * to memory as much as to stage documents: a distilled copy is one nothing keeps in sync.
 *
 * Usage:
 *   node .harness/scripts/memory-search.js <term> [--all] [--files]
 *     --all    search every store, including the ones off the default path
 *     --files  print matching entry locations only, without their bodies
 */

import * as fs from 'node:fs';
import * as path from 'node:path';

/** How an entry begins, per store. Everything up to the next start belongs to it. */
interface Store {
  file: string;
  /** A line that opens a new entry. */
  opens: RegExp;
  /** Included in the default (no --all) search set. */
  primary: boolean;
}

const STORES: readonly Store[] = [
  // Hard-won truths. One entry is one bullet plus every wrapped continuation line.
  { file: '.harness/insight-index.md', opens: /^- /, primary: true },
  // Declined options. One entry is one `## slug` section.
  { file: '.harness/rejected-decisions.md', opens: /^## /, primary: true },
  // The principles autonomous decisions are made by.
  { file: '.harness/decision-rubric.md', opens: /^#{2,6} /, primary: true },
  // Canonical terms.
  { file: 'CONTEXT.md', opens: /^#{2,6} /, primary: true },
  // Outstanding human duties — off the default path because it is long and rarely the
  // answer, but reachable with --all.
  { file: '.harness/operator-obligations.md', opens: /^#{2,6} /, primary: false },
];

export interface Entry {
  file: string;
  /** 1-based line number of the entry's opening line. */
  line: number;
  text: string;
}

/** Split a document into entries. Text before the first opener is the header, dropped. */
export function splitEntries(content: string, opens: RegExp): Entry[] {
  const lines = content.split('\n');
  const entries: Entry[] = [];
  let cur: string[] = [];
  let start = 0;

  const flush = (): void => {
    if (cur.length > 0) {
      entries.push({ file: '', line: start + 1, text: cur.join('\n').replace(/\s+$/, '') });
    }
    cur = [];
  };

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i] as string;
    if (opens.test(line)) {
      flush();
      start = i;
      cur = [line];
    } else if (cur.length > 0) {
      cur.push(line);
    }
  }
  flush();
  return entries;
}

/** Every entry in `stores` whose text contains `term`, case-insensitively. */
export function search(term: string, stores: readonly Store[], root: string): Entry[] {
  const needle = term.toLowerCase();
  const hits: Entry[] = [];
  for (const store of stores) {
    const abs = path.join(root, store.file);
    let content: string;
    try {
      content = fs.readFileSync(abs, 'utf8');
    } catch {
      continue; // a store this project does not carry is not an error
    }
    for (const entry of splitEntries(content, store.opens)) {
      if (entry.text.toLowerCase().includes(needle)) {
        hits.push({ ...entry, file: store.file });
      }
    }
  }
  return hits;
}

export function run(argv: readonly string[], root: string, out: (s: string) => void): number {
  const flags = new Set(argv.filter((a) => a.startsWith('--')));
  const terms = argv.filter((a) => !a.startsWith('--'));
  const term = terms.join(' ');

  if (term === '') {
    out('usage: memory-search <term> [--all] [--files]');
    out('');
    out('Searches this project\'s decided history and prints WHOLE entries, never line windows.');
    out('Default stores:');
    for (const s of STORES.filter((x) => x.primary)) out(`  ${s.file}`);
    out('With --all, also:');
    for (const s of STORES.filter((x) => !x.primary)) out(`  ${s.file}`);
    return 2;
  }

  const stores = flags.has('--all') ? STORES : STORES.filter((s) => s.primary);
  const hits = search(term, stores, root);

  if (hits.length === 0) {
    // Say which stores were searched. A bare "no results" is the failure mode this tool
    // exists to remove: it is indistinguishable from having searched the wrong place.
    out(`No entry matches ${JSON.stringify(term)}.`);
    out(`Searched ${stores.length} store(s): ${stores.map((s) => s.file).join(', ')}`);
    if (!flags.has('--all')) out('Re-run with --all to include the stores off the default path.');
    return 1;
  }

  out(`${hits.length} entr${hits.length === 1 ? 'y' : 'ies'} match ${JSON.stringify(term)}:`);
  for (const hit of hits) {
    out('');
    out(`--- ${hit.file}:${hit.line}`);
    if (!flags.has('--files')) out(hit.text);
  }
  return 0;
}

if (require.main === module) {
  const root = path.resolve(__dirname, '../..');
  process.exit(run(process.argv.slice(2), root, (s) => process.stdout.write(`${s}\n`)));
}
