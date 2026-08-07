/**
 * doc-query — return the UNITS of a project document that answer a question, never the
 * document.
 *
 * ## Why one tool instead of three
 *
 * Three separate problems in this project turned out to be one shape:
 *
 *   memory stores   20.6 KB read whole, six times per 7-stage task
 *   stage contracts 67 KB of 01+02+03 read whole at stage 4, of which a measured 48%
 *                   is addressed to the Developer at all
 *   rule fragments  65 KB, loaded whole when a trigger fires
 *
 * Each is a document composed of addressable units where the consumer needs some units,
 * not the document. Solving them one store at a time produces three tools and three
 * instructions that drift; solving the shape produces one of each.
 *
 * ## What it does not do
 *
 * It does not summarise, index, embed or copy. The text it prints is the original at its
 * original location — `stage-doc-summary-header` was declined precisely because a distilled
 * copy is one nothing keeps in sync, and that decline applies to every document class here.
 *
 * It also requires **no authoring change**. Stage documents already carry `## ` sections and
 * the memory stores already carry entries, so the unit boundary exists today. Marking each
 * section with its intended consumer would narrow results further, but it is a refinement,
 * not a precondition — which is what makes this shippable without touching seven contracts.
 *
 * ## Measured properties it exists to preserve
 *
 * From `evals/run-mem-baseline.sh` over 12 control items:
 *   - An unscoped repo search scores 0/12 and returns ZERO BYTES, reading as "no results"
 *     rather than "wrong search", because every store lives under a dot-directory and
 *     ripgrep skips those by default.
 *   - A line window scores 8/12 at ±2 and 10/12 at ±10, because a unit is longer than any
 *     fixed window: it either truncates the answer or drags in its neighbour.
 *   - Returning whole units from named documents scores 11/12 at 18x fewer tokens. The one
 *     miss is an item whose answer is not in any document class.
 *
 * Usage:
 *   node .harness/scripts/doc-query.js <term> [--in memory|stage|rules|all] [--task <slug>]
 *                                             [--files] [--list]
 */

import * as fs from 'node:fs';
import * as path from 'node:path';

export type Scope = 'memory' | 'stage' | 'rules' | 'all';

/**
 * A document class: where its documents live and what opens a unit inside them.
 *
 * `opens` is the whole contract. Everything from one opener up to the next is one unit,
 * and a unit is what a query returns.
 */
export interface DocClass {
  scope: Exclude<Scope, 'all'>;
  /** Directory to walk, relative to the project root. '' means the root itself. */
  dir: string;
  /** Which files in `dir` belong to this class. */
  matches: (relPath: string) => boolean;
  /**
   * What opens a new unit, resolved PER FILE.
   *
   * The unit boundary is a property of the document, not of the class. Collapsing it to one
   * class-wide pattern was measured wrong: `.harness/insight-index.md` opens units with
   * `- `, while `.harness/rejected-decisions.md` opens them with `## ` and uses `- ` inside
   * a record's body. A combined `^(- |#{2,6} )` splits every decision record into fragments,
   * so a match returns one bullet instead of the record — 10/12 on the control set against
   * 11/12 with per-file rules.
   */
  opens: (relPath: string) => RegExp;
  /** Walk sub-directories of `dir`. */
  recursive: boolean;
}

const MEMORY_FILES = new Set([
  '.harness/insight-index.md',
  '.harness/rejected-decisions.md',
  '.harness/decision-rubric.md',
  '.harness/operator-obligations.md',
  'CONTEXT.md',
]);

export const DOC_CLASSES: readonly DocClass[] = [
  {
      scope: 'memory',
    dir: '',
    matches: (p) => MEMORY_FILES.has(p),
    // The insight index stores one fact per bullet plus its wrapped continuation lines.
    // Every other store delimits by heading and uses bullets INSIDE a unit.
    opens: (p) => (p === '.harness/insight-index.md' ? /^- / : /^#{2,6} /),
    recursive: true,
  },
  {
    // Stage contracts: 01_REQUIREMENT_ANALYSIS through 07_DELIVERY, plus PM_LOG, under
    // both the live and archived task folders.
    scope: 'stage',
    dir: 'docs/features',
    matches: (p) => /(^|\/)(0[1-7]_[A-Z_]+|PM_LOG)\.md$/.test(p),
    opens: () => /^#{2,3} /,
    recursive: true,
  },
  {
    scope: 'rules',
    dir: '.harness/rules',
    matches: (p) => p.endsWith('.md'),
    opens: () => /^#{2,3} /,
    recursive: false,
  },
];

export interface Unit {
  file: string;
  /** 1-based line of the unit's opening line. */
  line: number;
  text: string;
}

/** Split a document into units. Text before the first opener is the header and is dropped. */
export function splitUnits(content: string, opens: RegExp): Unit[] {
  const lines = content.split('\n');
  const units: Unit[] = [];
  let cur: string[] = [];
  let start = 0;

  const flush = (): void => {
    if (cur.length > 0) units.push({ file: '', line: start + 1, text: cur.join('\n').replace(/\s+$/, '') });
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
  return units;
}

function walk(root: string, rel: string, recursive: boolean, out: string[]): void {
  let entries: fs.Dirent[];
  try {
    entries = fs.readdirSync(path.join(root, rel), { withFileTypes: true });
  } catch {
    return;
  }
  for (const e of entries) {
    const child = rel === '' ? e.name : `${rel}/${e.name}`;
    if (e.isDirectory()) {
      if (recursive && e.name !== 'node_modules' && e.name !== '.git') walk(root, child, recursive, out);
    } else if (e.isFile()) {
      out.push(child);
    }
  }
}

/** Every file belonging to `cls`, as project-relative paths. */
export function filesOf(cls: DocClass, root: string): string[] {
  if (cls.dir === '') {
    // A root-anchored class enumerates its members directly rather than walking the tree.
    return [...MEMORY_FILES].filter((f) => fs.existsSync(path.join(root, f)));
  }
  const found: string[] = [];
  walk(root, cls.dir, cls.recursive, found);
  return found.filter((f) => cls.matches(f)).sort();
}

export interface QueryOptions {
  scope: Scope;
  /** Restrict the `stage` class to one task slug. */
  task?: string | undefined;
  /**
   * Match the unit's OPENING LINE only, not its body.
   *
   * This is the difference between "where is X mentioned" and "which unit is X". Measured:
   * a body match for a common phrase like `The arrangement` returns 45 KB because the
   * phrase recurs across sections, so term search over stage documents costs 73% of
   * reading them whole — barely worth doing. A heading match returns exactly the named
   * section. Memory stores want the body match (the question IS a term); stage documents
   * and rule fragments want this one (the question is which section belongs to me).
   */
  heading?: boolean | undefined;
}

export function query(term: string, root: string, opts: QueryOptions): Unit[] {
  const needle = term.toLowerCase();
  const classes = DOC_CLASSES.filter((c) => opts.scope === 'all' || c.scope === opts.scope);
  const hits: Unit[] = [];

  for (const cls of classes) {
    for (const rel of filesOf(cls, root)) {
      if (cls.scope === 'stage' && opts.task !== undefined && !rel.includes(`/${opts.task}/`)) continue;
      let content: string;
      try {
        content = fs.readFileSync(path.join(root, rel), 'utf8');
      } catch {
        continue;
      }
      for (const unit of splitUnits(content, cls.opens(rel))) {
        const haystack = opts.heading === true ? (unit.text.split('\n')[0] ?? '') : unit.text;
        if (haystack.toLowerCase().includes(needle)) hits.push({ ...unit, file: rel });
      }
    }
  }
  return hits;
}

function parseScope(argv: readonly string[]): Scope {
  const i = argv.indexOf('--in');
  const v = i >= 0 ? argv[i + 1] : undefined;
  if (v === 'memory' || v === 'stage' || v === 'rules' || v === 'all') return v;
  return 'all';
}

export function run(argv: readonly string[], root: string, out: (s: string) => void): number {
  const flags = new Set(argv.filter((a) => a.startsWith('--')));
  const scope = parseScope(argv);
  const taskIdx = argv.indexOf('--task');
  const task = taskIdx >= 0 ? argv[taskIdx + 1] : undefined;

  // Positional terms only: drop flags and the values that belong to them.
  const consumed = new Set<number>();
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i] as string;
    if (a === '--in' || a === '--task') {
      consumed.add(i);
      consumed.add(i + 1);
    } else if (a.startsWith('--')) {
      consumed.add(i);
    }
  }
  const term = argv.filter((_, i) => !consumed.has(i)).join(' ');

  if (flags.has('--list')) {
    for (const cls of DOC_CLASSES.filter((c) => scope === 'all' || c.scope === scope)) {
      for (const f of filesOf(cls, root)) out(`${cls.scope}\t${f}`);
    }
    return 0;
  }

  if (term === '') {
    out('usage: doc-query <term> [--in memory|stage|rules|all] [--task <slug>]');
    out('                         [--heading] [--files] [--list]');
    out('');
    out('Returns whole UNITS — an insight entry, a decision record, a stage-doc section —');
    out('never a line window and never the whole document.');
    out('');
    out('--heading matches the unit\'s opening line only. Use it to ask WHICH SECTION IS X;');
    out('omit it to ask WHERE IS X MENTIONED. On stage documents the first is 6x cheaper.');
    return 2;
  }

  const hits = query(term, root, { scope, task, heading: flags.has('--heading') });

  if (hits.length === 0) {
    // Naming what was searched is the point. A bare "no results" is indistinguishable from
    // having searched the wrong place, which is exactly how an unscoped search scores 0/12
    // while looking like it worked.
    const classes = DOC_CLASSES.filter((c) => scope === 'all' || c.scope === scope);
    const count = classes.reduce((n, c) => n + filesOf(c, root).length, 0);
    out(`No unit matches ${JSON.stringify(term)}.`);
    out(`Searched ${count} document(s) in scope ${JSON.stringify(scope)}${task ? ` for task ${task}` : ''}.`);
    if (scope !== 'all') out('Widen with --in all.');
    return 1;
  }

  out(`${hits.length} unit${hits.length === 1 ? '' : 's'} match ${JSON.stringify(term)}:`);
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
