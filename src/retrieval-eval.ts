/**
 * retrieval-eval — the P0 batch runner: score a retrieval configuration against the control
 * set, deterministically, with no model in the loop.
 *
 * ## What it measures, and why that is the honest question
 *
 * The brief asks for hit rate, mean tokens and mean time over the control set. It does NOT
 * ask whether a model answers well — that would need a judge model, and the control set's own
 * opening section is an argument against judge models: LoCoMo's judges accept 62.81% of
 * deliberately-wrong but topically-related responses.
 *
 * So this scores the half that is actually mechanical and actually the subject of the
 * migration: **given a retrieval configuration, does the expected fact end up in front of the
 * agent, and at what cost?** A configuration that never surfaces the fact cannot be rescued by
 * a better model, and one that surfaces it inside 400 KB has not won.
 *
 * A case is a HIT when every checkable token of its Expected answer appears in the retrieved
 * text, PARTIAL when at least one does, MISS when none do. Score is `HIT + 0.5·PARTIAL`, the
 * same arithmetic the control set already specifies for the manual protocol — so a run of this
 * and a careful read agree on the scale, and only the judgment differs.
 *
 * ## Configurations
 *
 *   whole   read every anchor file end to end          — the pre-migration access pattern
 *   grep    grep the repo for the case's query terms    — the §5.3 baseline that must be run
 *                                                          before any memory backend is adopted
 *   query   doc-query over the store the case belongs to — what the contracts now specify
 *
 * `whole` is the ceiling by construction: it reads the file the answer was taken from, so it
 * scores ~1.0 and its interest is entirely in the BYTES column. Reporting it is the point —
 * a config is only worth adopting if it holds accuracy while moving that column.
 *
 * ## Repeatability
 *
 * No clock, no network, no model, no randomness in scoring. `--json` omits timings so two runs
 * are byte-identical; the human report prints them because a cost with no time column hides
 * the one axis a grep can lose on.
 *
 * Usage:
 *   node .harness/scripts/retrieval-eval.js --config query [--category MEM] [--json]
 *   node .harness/scripts/retrieval-eval.js --compare
 * Exit: 0 always when the run completes (this is an instrument, not a gate); 2 on usage error.
 */

import { execFileSync } from 'node:child_process';
import * as fs from 'node:fs';
import * as path from 'node:path';

import {
  type Category,
  type EvalCase,
  CATEGORIES,
  anchorPaths,
  backticked,
  isCheckableToken,
  loadCases,
} from './eval-set';

export const CONFIGS = ['whole', 'grep', 'query', 'memory'] as const;
export type Config = (typeof CONFIGS)[number];

export interface CaseResult {
  readonly id: string;
  readonly category: Category;
  readonly outcome: 'HIT' | 'PARTIAL' | 'MISS' | 'N/A';
  readonly found: number;
  readonly wanted: number;
  readonly bytes: number;
  readonly ms: number;
  readonly terms: readonly string[];
}

export interface Report {
  readonly config: Config;
  readonly results: readonly CaseResult[];
}

// ---------------------------------------------------------------------------- query terms

/**
 * English words that carry no retrieval signal. Deliberately short: a long stop list is a
 * tuning knob, and a tuning knob on the instrument is how an instrument starts agreeing with
 * whoever last touched it.
 */
const STOP = new Set([
  'what', 'which', 'where', 'when', 'why', 'how', 'who', 'does', 'did', 'do', 'is', 'are',
  'was', 'were', 'the', 'a', 'an', 'and', 'or', 'of', 'to', 'in', 'on', 'for', 'from', 'by',
  'at', 'it', 'its', 'this', 'that', 'with', 'into', 'was', 'be', 'been', 'has', 'have',
  'must', 'not', 'no', 'any', 'each', 'every', 'many', 'much', 'one', 'two', 'if', 'then',
  'than', 'as', 'so', 'but', 'you', 'your', 'they', 'their', 'there', 'here', 'about',
]);

/**
 * The terms a configuration searches for, derived from the question alone.
 *
 * Backticked spans first — a question that names a symbol is asking about that symbol. Then
 * the longest remaining words. Capped at three, because an unbounded term list turns every
 * grep into a whole-repo read and the cost column stops meaning anything.
 *
 * Derivation is printed in the report. A case that scores badly because its terms came out
 * wrong is then visible as a derivation problem rather than a retrieval one — the alternative,
 * hand-writing a query per case, tunes the instrument to the answer.
 */
export function queryTerms(question: string): string[] {
  const ticked = backticked(question).filter((t) => !/\s/.test(t) && t.length > 2);
  const words = question
    .replace(/`[^`]*`/g, ' ')
    .toLowerCase()
    .split(/[^a-z0-9_-]+/)
    .filter((w) => w.length > 3 && !STOP.has(w));
  words.sort((a, b) => b.length - a.length || a.localeCompare(b));
  const out: string[] = [];
  for (const t of [...ticked, ...words]) {
    if (out.length >= 3) break;
    if (!out.includes(t)) out.push(t);
  }
  return out;
}

// ---------------------------------------------------------------------------- retrieval

/**
 * Which doc-query store a category's answers live in.
 *
 * CODE maps to `rules` and that is not a mapping — it is the absence of one. `doc-query` has
 * memory, stage and rules classes; none of them indexes source. A CODE question under the
 * `query` config therefore scores whatever happens to be restated in `.harness/rules/`, and
 * scores it low. That is the measurement, not a bug in it: source retrieval is what P5's
 * codegraph is for, and the control set already records that CODE cannot gate P5 on this repo
 * because codegraph v1.5.0 indexes neither bash nor the shell half of this codebase.
 */
const STORE_OF: Readonly<Record<Category, string>> = {
  CODE: 'rules',
  MEM: 'memory',
  RULE: 'rules',
  STATE: 'stage',
};

function runNode(root: string, args: readonly string[]): string {
  try {
    return execFileSync(process.execPath, args, { cwd: root, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
  } catch (e) {
    const out = (e as { stdout?: string }).stdout;
    return typeof out === 'string' ? out : '';
  }
}

function runGrep(root: string, terms: readonly string[]): string {
  let acc = '';
  for (const t of terms) {
    try {
      acc += execFileSync(
        'grep',
        ['-rIn', '--exclude-dir=.git', '--exclude-dir=node_modules', '-F', t, '.'],
        { cwd: root, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 },
      );
    } catch {
      /* grep exits 1 on no match; an empty contribution is the correct result */
    }
  }
  return acc;
}

export function retrieve(c: EvalCase, config: Config, root: string, terms: readonly string[]): string {
  if (config === 'whole') {
    return anchorPaths(c.anchor, root)
      .map((p) => {
        try {
          return fs.readFileSync(path.join(root, p), 'utf8');
        } catch {
          return '';
        }
      })
      .join('\n');
  }
  if (config === 'grep') return runGrep(root, terms);
  if (config === 'memory') {
    // The seeded memory layer, asked the WHOLE question rather than the extracted terms: FTS5
    // ranks by how many of a question's words a record carries, so splitting the question into
    // separate single-term calls throws away the ranking signal the other configs cannot use.
    return runNode(root, ['.harness/scripts/memory.js', 'search', c.question, '--limit', '10', '--budget', '4000']);
  }
  let acc = '';
  for (const t of terms) {
    acc += runNode(root, ['.harness/scripts/doc-query.js', '--in', STORE_OF[c.category], t]);
  }
  return acc;
}

// ---------------------------------------------------------------------------- scoring

export function scoreCase(c: EvalCase, retrieved: string): { outcome: CaseResult['outcome']; found: number; wanted: number } {
  const wanted = backticked(c.expected).filter(isCheckableToken);
  if (wanted.length === 0) {
    // No mechanically checkable claim: the Expected answer is prose. Reported as its own
    // outcome and EXCLUDED from the denominator, never folded into MISS. Eighteen of the
    // thirty-six cases are this shape, so scoring them as misses would have pinned every
    // configuration at ~0.5 and made the ceiling look like the floor — an instrument that
    // reports the same number for a good config and a bad one has stopped being one.
    return { outcome: 'N/A', found: 0, wanted: 0 };
  }
  const found = wanted.filter((t) => retrieved.includes(t)).length;
  if (found === wanted.length) return { outcome: 'HIT', found, wanted: wanted.length };
  if (found > 0) return { outcome: 'PARTIAL', found, wanted: wanted.length };
  return { outcome: 'MISS', found, wanted: wanted.length };
}

export function runConfig(cases: readonly EvalCase[], config: Config, root: string): Report {
  const results: CaseResult[] = [];
  for (const c of cases) {
    const terms = queryTerms(c.question);
    const t0 = process.hrtime.bigint();
    const retrieved = retrieve(c, config, root, terms);
    const ms = Number(process.hrtime.bigint() - t0) / 1e6;
    const { outcome, found, wanted } = scoreCase(c, retrieved);
    results.push({ id: c.id, category: c.category, outcome, found, wanted, bytes: retrieved.length, ms, terms });
  }
  return { config, results };
}

export interface Summary {
  /** Cases this runner can score — the score's denominator. */
  readonly n: number;
  /** Cases whose Expected answer is prose. Reported, never scored. */
  readonly na: number;
  readonly hit: number;
  readonly partial: number;
  readonly miss: number;
  readonly score: number;
  /** Mean over EVERY case, scorable or not: retrieval costs the same either way. */
  readonly meanBytes: number;
}

export function summarize(results: readonly CaseResult[]): Summary {
  const scorable = results.filter((r) => r.outcome !== 'N/A');
  const n = scorable.length;
  const hit = scorable.filter((r) => r.outcome === 'HIT').length;
  const partial = scorable.filter((r) => r.outcome === 'PARTIAL').length;
  return {
    n,
    na: results.length - n,
    hit,
    partial,
    miss: n - hit - partial,
    score: n === 0 ? 0 : (hit + 0.5 * partial) / n,
    meanBytes: results.length === 0 ? 0 : Math.round(results.reduce((a, r) => a + r.bytes, 0) / results.length),
  };
}

// ---------------------------------------------------------------------------- cli

const kb = (b: number): string => (b / 1024).toFixed(1);
const tok = (b: number): number => Math.round(b / 3.6);

function printReport(rep: Report, out: (s: string) => void, verbose: boolean): void {
  out(`config: ${rep.config}`);
  out('');
  out('  cat  scored  n/a   HIT  PART  MISS   score   mean bytes   ~mean tok');
  const line = (label: string, s: Summary): string =>
    `  ${label.padEnd(6)}${String(s.n).padStart(4)}${String(s.na).padStart(6)}   ${String(s.hit).padStart(3)}   ` +
    `${String(s.partial).padStart(3)}   ${String(s.miss).padStart(3)}   ${s.score.toFixed(3)}   ` +
    `${kb(s.meanBytes).padStart(8)} KB   ${String(tok(s.meanBytes)).padStart(9)}`;
  for (const k of CATEGORIES) {
    const rows = rep.results.filter((r) => r.category === k);
    if (rows.length === 0) continue;
    out(line(k, summarize(rows)));
  }
  const all = summarize(rep.results);
  out('  ---');
  out(line('ALL', all));
  if (!verbose) return;
  out('');
  out('  per case (terms are DERIVED from the question — a bad score may be a bad derivation)');
  for (const r of rep.results) {
    out(`  ${r.id.padEnd(4)} ${r.outcome.padEnd(8)} ${String(r.found)}/${String(r.wanted)}  ${kb(r.bytes).padStart(9)} KB  [${r.terms.join(', ')}]`);
  }
}

export function run(argv: readonly string[], root: string, out: (s: string) => void): number {
  const flags = new Set(argv.filter((a) => a.startsWith('--')));
  const valueOf = (name: string): string | undefined => {
    const i = argv.indexOf(name);
    return i >= 0 && i + 1 < argv.length ? argv[i + 1] : undefined;
  };

  let cases: EvalCase[];
  try {
    cases = loadCases(root);
  } catch {
    out('retrieval-eval: cannot read the control set');
    return 2;
  }

  const only = valueOf('--category')?.toUpperCase();
  if (only !== undefined) {
    if (!(CATEGORIES as readonly string[]).includes(only)) {
      out(`retrieval-eval: unknown category '${only}' (CODE|MEM|RULE|STATE)`);
      return 2;
    }
    cases = cases.filter((c) => c.category === only);
  }

  const wanted: Config[] = flags.has('--compare')
    ? [...CONFIGS]
    : [(valueOf('--config') ?? 'query') as Config];
  for (const c of wanted) {
    if (!(CONFIGS as readonly string[]).includes(c)) {
      out(`retrieval-eval: unknown config '${c}' (${CONFIGS.join('|')})`);
      return 2;
    }
  }

  const reports = wanted.map((c) => runConfig(cases, c, root));

  if (flags.has('--json')) {
    // Timings are omitted so two runs of the same tree are byte-identical — the control set
    // asks for a repeatable instrument, and a wall-clock field makes that impossible.
    out(
      JSON.stringify(
        reports.map((r) => ({
          config: r.config,
          all: summarize(r.results),
          byCategory: Object.fromEntries(
            CATEGORIES.map((k) => [k, summarize(r.results.filter((x) => x.category === k))]),
          ),
          cases: r.results.map(({ id, category, outcome, found, wanted: w, bytes, terms }) => ({
            id,
            category,
            outcome,
            found,
            wanted: w,
            bytes,
            terms,
          })),
        })),
      ),
    );
    return 0;
  }

  const scorable = cases.filter((c) => backticked(c.expected).filter(isCheckableToken).length > 0).length;
  out('=== P0 control set — retrieval score ===');
  out(`    ${cases.length} cases, ${scorable} of them mechanically scorable; the other ${cases.length - scorable} carry a`);
  out('    prose Expected answer and need a reader. HIT = every checkable Expected token');
  out('    present in the retrieved text; score = (HIT + 0.5*PARTIAL) over the scorable ones.');
  out('');
  for (const r of reports) {
    printReport(r, out, flags.has('--verbose'));
    out('');
  }
  if (reports.some((r) => r.config === 'query')) {
    out('  CODE under `query` is measuring an absence: doc-query has no source-code store, so a');
    out('  CODE question scores only what happens to be restated in `.harness/rules/`. That gap');
    out('  is what P5 exists to close; it is not a defect in this run.');
    out('');
  }
  if (reports.length > 1) {
    out('  Read the two columns together. `whole` is the ceiling by construction — it reads the');
    out('  file the answer was taken from. A configuration is worth adopting when it holds that');
    out('  score while moving the bytes column, not when it wins either one alone.');
  }
  return 0;
}

if (require.main === module) {
  const root = path.resolve(__dirname, '../..');
  process.exit(run(process.argv.slice(2), root, (s) => process.stdout.write(`${s}\n`)));
}
