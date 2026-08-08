/**
 * eval-set — the P0 control set, parsed, and its CLAIMS checked.
 *
 * ## The gap this closes
 *
 * `evals/retrieval-eval.md` is the instrument every acceptance decision in this migration is
 * argued from. `eval-anchors` already fails the build when a citation stops resolving — that
 * check exists because five `guard-rm.sh` anchors kept pointing at lines 191, 711 and 903 of
 * a file that the TypeScript port had shortened to twelve, and nothing noticed for a whole
 * working session.
 *
 * An anchor resolving says the FILE is still there. It says nothing about whether the
 * expected answer is still TRUE. Measured when this module was written, four of ten CODE
 * items were stale against their own anchors:
 *
 *   C4  named `hostOs` in hook-spec's public surface — deleted at v0.49.0
 *   C5  "32 checks"                                  — 35 since v0.49.0
 *   C8  "agents ≤300 lines + 24 KB each"             — ≤3 KB since v0.50.0
 *   C10 "Mapping 10's four compiled `.js` files"     — six, plus Mapping 11
 *
 * Every one of them had a resolving anchor. The instrument was wrong in the direction that
 * matters most: it would have scored a correct answer as a MISS and a stale one as a HIT.
 *
 * ## What this checks, and what it cannot
 *
 * The rule is mechanical: **every backticked token in an Expected-answer cell must occur
 * literally in that row's anchor file.** That catches a deleted or renamed symbol, which is
 * how the control set actually rots — code moves, prose does not.
 *
 * It does NOT catch a wrong number written as prose ("32 checks"), because a bare integer
 * cannot be resolved against a file without knowing what counts it. Those are found by
 * reading, and the limit is stated here rather than left for a reader to discover. Where a
 * count matters, write it backticked against a pinned source so this check can see it.
 *
 * Usage:
 *   node .harness/scripts/eval-set.js --list [--category CODE]
 *   node .harness/scripts/eval-set.js --check
 * Exit: 0 clean, 1 findings, 2 usage error.
 */

import * as fs from 'node:fs';
import * as path from 'node:path';

export const CONTROL_SET = 'evals/retrieval-eval.md';

export type Category = 'CODE' | 'MEM' | 'RULE' | 'STATE';

export const CATEGORIES: readonly Category[] = ['CODE', 'MEM', 'RULE', 'STATE'];

export interface EvalCase {
  readonly id: string;
  readonly category: Category;
  readonly question: string;
  readonly expected: string;
  readonly anchor: string;
  /** 1-based line of the row in the control set, so a finding is navigable. */
  readonly line: number;
}

/** A backticked token that no longer occurs in the row's anchor file. */
export interface ClaimFinding {
  readonly id: string;
  readonly line: number;
  readonly token: string;
  readonly kind: 'symbol-absent' | 'anchor-unreadable';
  readonly anchorPath: string;
}

// ---------------------------------------------------------------------------- parse

/**
 * Split a markdown table row into cells.
 *
 * A cell may contain an escaped pipe (`\|`) — the schema tables use them inside shape
 * descriptions — so the split is on unescaped pipes only. Getting this wrong shifts every
 * later column by one and turns the whole file into findings.
 */
export function splitRow(row: string): string[] {
  const cells: string[] = [];
  let cur = '';
  for (let i = 0; i < row.length; i++) {
    const ch = row[i] as string;
    if (ch === '\\' && row[i + 1] === '|') {
      cur += '|';
      i++;
      continue;
    }
    if (ch === '|') {
      cells.push(cur);
      cur = '';
      continue;
    }
    cur += ch;
  }
  cells.push(cur);
  // A markdown row opens and closes with a pipe, so the first and last cells are empty.
  return cells.slice(1, -1).map((c) => c.trim());
}

const ID_RE = /^([CMRS])(\d+)$/;

const CATEGORY_OF: Readonly<Record<string, Category>> = {
  C: 'CODE',
  M: 'MEM',
  R: 'RULE',
  S: 'STATE',
};

/**
 * Parse every case row out of the control set.
 *
 * Rows are recognised by their ID cell (`C1`, `M12`, `R8`, `S6`) rather than by tracking
 * which `##` section the reader is inside. The category IS the id prefix, so a case cannot
 * end up in the wrong bucket by a heading being reworded, and a table that moves sections
 * still parses.
 */
export function parseCases(content: string): EvalCase[] {
  const out: EvalCase[] = [];
  const lines = content.split('\n');
  let fenced = false;
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i] as string;
    if (/^\s*```/.test(line)) {
      fenced = !fenced;
      continue;
    }
    if (fenced) continue;
    if (!line.startsWith('|')) continue;
    const cells = splitRow(line);
    if (cells.length < 4) continue;
    const m = ID_RE.exec(cells[0] as string);
    if (m === null) continue;
    const category = CATEGORY_OF[m[1] as string];
    if (category === undefined) continue;
    out.push({
      id: cells[0] as string,
      category,
      question: cells[1] as string,
      expected: cells[2] as string,
      anchor: cells[3] as string,
      line: i + 1,
    });
  }
  return out;
}

// ---------------------------------------------------------------------------- claims

/** Backticked spans, in order, deduplicated. */
export function backticked(cell: string): string[] {
  const out: string[] = [];
  const seen = new Set<string>();
  for (const m of cell.matchAll(/`([^`]+)`/g)) {
    const t = (m[1] as string).trim();
    if (t === '' || seen.has(t)) continue;
    seen.add(t);
    out.push(t);
  }
  return out;
}

/**
 * Which tokens are worth resolving.
 *
 * A backticked span is only a checkable claim when it names an IDENTIFIER a file can contain
 * literally. Everything else is excluded, each exclusion for a reason a first run produced:
 *
 *  - a path (`src/guard-rm.ts`) — that is the ANCHOR's job, and `eval-anchors` already
 *    resolves it; re-checking it here would double-report one defect.
 *  - a span with whitespace (`## reviewer-write-grant`, `tools:` line) — prose, not a symbol.
 *  - a regex or a shape (`[A-J]\.[0-9]+`) — the row is DESCRIBING a pattern, not naming a
 *    thing; the file contains what the pattern matches, never the pattern.
 *  - a dotted placeholder with no lowercase (`X.N`, `G.4`) — a check-id template, same case.
 *    All-caps WITHOUT a dot (`TOOLS`, `EVENTS`) is a real exported symbol and stays checked.
 *  - a bare integer — a number cannot be resolved against a file without knowing what counts
 *    it. See the header: this is the stated limit, not an oversight.
 */
export function isCheckableToken(token: string): boolean {
  if (/\s/.test(token)) return false;
  if (token.includes('/')) return false;
  if (!/^[A-Za-z_][A-Za-z0-9_.-]*$/.test(token)) return false;
  if (token.includes('.') && !/[a-z]/.test(token)) return false;
  return true;
}

/**
 * Expand a single `*` inside one path segment.
 *
 * The control set writes `docs/features/_archived/*\/PM_LOG.md` when the answer is "in every
 * archived task". Treating that as unreadable reported the row as a finding, which is the
 * check crying wolf about its own input — and a check that cries wolf gets disabled. One
 * star in one segment is the whole grammar the control set uses; anything richer should be
 * written as a concrete path rather than met with a glob engine.
 */
function expandStar(pattern: string, root: string): string[] {
  const parts = pattern.split('/');
  const at = parts.findIndex((p) => p.includes('*'));
  if (at < 0) return [pattern];
  const head = parts.slice(0, at).join('/');
  const tail = parts.slice(at + 1).join('/');
  const re = new RegExp(`^${(parts[at] as string).split('*').map((s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')).join('.*')}$`);
  let entries: string[];
  try {
    entries = fs.readdirSync(path.join(root, head));
  } catch {
    return [];
  }
  return entries
    .filter((e) => re.test(e))
    .map((e) => (tail === '' ? `${head}/${e}` : `${head}/${e}/${tail}`))
    .sort();
}

/**
 * Every readable path an anchor cell names, without its line suffix.
 *
 * An anchor may name more than one file (`verify_all.sh`; pin at `baseline.json:10`), and a
 * token satisfying ANY of them is satisfied — the row cites them together because the answer
 * spans them.
 */
export function anchorPaths(anchor: string, root: string): string[] {
  const out: string[] = [];
  for (const tok of backticked(anchor)) {
    const bare = tok.replace(/:[\d,\-–\s]+$/, '').trim();
    if (bare === '' || /\s/.test(bare)) continue;
    for (const cand of [bare, path.join('.harness/scripts', bare), path.join('src', bare)]) {
      const hits = cand.includes('*') ? expandStar(cand, root) : [cand];
      let landed = false;
      for (const h of hits) {
        try {
          if (fs.statSync(path.join(root, h)).isFile()) {
            out.push(h);
            landed = true;
          }
        } catch {
          /* not this one */
        }
      }
      if (landed) break;
    }
  }
  return [...new Set(out)];
}

/** Check every case's Expected-answer symbols against its anchor files. */
export function checkClaims(cases: readonly EvalCase[], root: string): ClaimFinding[] {
  const findings: ClaimFinding[] = [];
  const cache = new Map<string, string>();
  const read = (rel: string): string => {
    const hit = cache.get(rel);
    if (hit !== undefined) return hit;
    let body = '';
    try {
      body = fs.readFileSync(path.join(root, rel), 'utf8');
    } catch {
      body = '';
    }
    cache.set(rel, body);
    return body;
  };

  for (const c of cases) {
    const tokens = backticked(c.expected).filter(isCheckableToken);
    if (tokens.length === 0) continue;
    const paths = anchorPaths(c.anchor, root);
    if (paths.length === 0) {
      // Only a row that HAS a checkable claim needs a readable anchor to check it against.
      findings.push({ id: c.id, line: c.line, token: tokens[0] as string, kind: 'anchor-unreadable', anchorPath: c.anchor });
      continue;
    }
    const corpus = paths.map(read).join('\n');
    for (const t of tokens) {
      if (!corpus.includes(t)) {
        findings.push({ id: c.id, line: c.line, token: t, kind: 'symbol-absent', anchorPath: paths.join(', ') });
      }
    }
  }
  return findings;
}

export function loadCases(root: string): EvalCase[] {
  return parseCases(fs.readFileSync(path.join(root, CONTROL_SET), 'utf8'));
}

// ---------------------------------------------------------------------------- cli

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
    out(`eval-set: cannot read ${CONTROL_SET}`);
    return 2;
  }

  if (flags.has('--list')) {
    const only = valueOf('--category')?.toUpperCase();
    for (const c of cases) {
      if (only !== undefined && c.category !== only) continue;
      out(`${c.id}\t${c.category}\t${c.question}`);
    }
    return 0;
  }

  if (flags.has('--check')) {
    const findings = checkClaims(cases, root);
    if (findings.length === 0) {
      const per = CATEGORIES.map((k) => `${k} ${cases.filter((c) => c.category === k).length}`).join(', ');
      out(`${cases.length} control-set cases (${per}); every backticked claim resolves in its anchor.`);
      return 0;
    }
    for (const f of findings) {
      out(`${CONTROL_SET}:${f.line}: ${f.id}: ${f.kind}: \`${f.token}\` not in ${f.anchorPath}`);
    }
    return 1;
  }

  out('usage: eval-set --list [--category CODE|MEM|RULE|STATE]');
  out('       eval-set --check');
  out('');
  out('--list   every case in the P0 control set');
  out('--check  does each Expected answer still name symbols its anchor contains');
  return 2;
}

if (require.main === module) {
  const root = path.resolve(__dirname, '../..');
  process.exit(run(process.argv.slice(2), root, (s) => process.stdout.write(`${s}\n`)));
}
