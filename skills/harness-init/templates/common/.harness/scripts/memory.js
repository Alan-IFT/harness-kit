"use strict";
/**
 * memory — seed the project's decision trail into the memory layer, and query it.
 *
 * The seeder is deterministic end to end: markdown in, records out, no model in the loop.
 * That is a measured choice, not a shortcut — the sources here already carry an explicit
 * schema, and on structured input LLM extraction does not beat plain chunking.
 *
 * Usage:
 *   node .harness/scripts/memory.js seed [--from <root>] [--dry-run] [--verbose] [--no-prune]
 *   node .harness/scripts/memory.js stats
 *   node .harness/scripts/memory.js search <query> [--kinds a,b] [--limit N] [--budget N]
 *   node .harness/scripts/memory.js recent [--kind insight] [--limit N]
 *   node .harness/scripts/memory.js roles          # the §3 role table, run as a smoke check
 * Add --json to any query command for machine-readable output.
 * Exit: 0 ok, 1 nothing found / unparsed input, 2 usage error.
 *
 * `--from` names the PROJECT ROOT to harvest, not a directory of decision files. The work
 * order wrote it as `--from docs/decisions/`, which assumes the P1 backup has already split
 * the sources out; it has not run in this repo, so the sources are still at their original
 * paths and the harvester addresses them by name (see `harvest` in memory-seed.ts). Pointing
 * `--from` at a project root works for both layouts — a split-out `docs/decisions/` would be
 * added there as another source, not as a different meaning for this flag.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.ROLE_QUESTIONS = void 0;
exports.run = run;
const fs = require("fs");
const path = require("path");
const memory_seed_1 = require("./memory-seed");
const memory_sink_1 = require("./memory-sink");
/** The §3 table: what each role asks on its first turn, and which kinds should answer it. */
exports.ROLE_QUESTIONS = [
    { role: 'requirement-analyst', question: 'has this requirement been proposed and declined before', kinds: ['rejection', 'outcome'] },
    { role: 'solution-architect', question: 'how was this stage contract designed and which approaches were rejected', kinds: ['decision', 'rejection', 'term'] },
    { role: 'gate-reviewer', question: 'has approving this kind of gate finding gone wrong afterwards', kinds: ['insight', 'outcome'] },
    { role: 'developer', question: 'what are the traps in the verify_all hook and template sync path', kinds: ['insight', 'decision'] },
    { role: 'code-reviewer', question: 'which mistakes recur in this codebase reviews', kinds: ['insight'] },
    { role: 'qa-tester', question: 'which tests are vacuous or flaky and which edges have blown up', kinds: ['insight'] },
    { role: 'pm-orchestrator', question: 'which kinds of task tend to roll back', kinds: ['outcome'] },
];
function parseArgs(argv) {
    const flags = new Set();
    const opts = new Map();
    const rest = [];
    const cmd = argv[0] ?? '';
    for (let i = 1; i < argv.length; i += 1) {
        const a = argv[i];
        if (!a.startsWith('--')) {
            rest.push(a);
            continue;
        }
        const eq = a.indexOf('=');
        if (eq > 0) {
            opts.set(a.slice(0, eq), a.slice(eq + 1));
            continue;
        }
        const next = argv[i + 1];
        if (next !== undefined && !next.startsWith('--')) {
            opts.set(a, next);
            i += 1;
        }
        else {
            flags.add(a);
        }
    }
    return { cmd, flags, opts, rest };
}
function fmt(rec, out) {
    out(`  [${rec.kind}] ${rec.title}`);
    out(`      seq ${rec.seq}  ${rec.date === '' ? 'no-date' : rec.date}  ${rec.tags.join(' ')}`);
    if (rec.evidence.length > 0)
        out(`      evidence: ${rec.evidence.join('; ')}`);
    if (rec.supersedes !== undefined)
        out(`      supersedes: ${rec.supersedes}`);
}
function openSink(root, out) {
    try {
        return new memory_sink_1.SqliteSink((0, memory_sink_1.resolveDbPath)(root));
    }
    catch (err) {
        if (err instanceof memory_sink_1.MemoryDbPathError) {
            out(`memory: ${err.message}`);
            return null;
        }
        throw err;
    }
}
function run(argv, root, out) {
    const { cmd, flags, opts, rest } = parseArgs(argv);
    const json = flags.has('--json');
    const num = (k, dflt) => {
        const v = opts.get(k);
        const n = v === undefined ? NaN : Number(v);
        return Number.isFinite(n) && n > 0 ? n : dflt;
    };
    const kinds = (opts.get('--kinds') ?? opts.get('--kind') ?? '')
        .split(',')
        .map((k) => k.trim())
        .filter((k) => memory_seed_1.SEED_KINDS.includes(k));
    if (cmd === 'seed') {
        const from = path.resolve(root, opts.get('--from') ?? '.');
        const result = (0, memory_seed_1.harvest)(from);
        const byKind = {};
        for (const r of result.records)
            byKind[r.kind] = (byKind[r.kind] ?? 0) + 1;
        out(`Harvested ${result.records.length} records from ${path.relative(root, from) || '.'}`);
        for (const s of result.sources)
            out(`  ${s.source.padEnd(46)} ${String(s.records).padStart(4)} records  ${s.unparsed} unparsed`);
        out('');
        for (const k of memory_seed_1.SEED_KINDS)
            out(`  ${k.padEnd(10)} ${byKind[k] ?? 0}`);
        const core = (byKind['insight'] ?? 0) + (byKind['decision'] ?? 0);
        out(`  ${'—'.padEnd(10)} insight + decision = ${core} (acceptance floor: 60)`);
        if (result.unparsed.length > 0) {
            out('');
            out(`${result.unparsed.length} unparsed line(s) — first ${Math.min(10, result.unparsed.length)}:`);
            for (const u of result.unparsed.slice(0, flags.has('--verbose') ? result.unparsed.length : 10)) {
                out(`  ${u.source}:${u.line}  [${u.reason}]  ${u.text.slice(0, 110)}`);
            }
        }
        if (flags.has('--dry-run')) {
            out('');
            out('--dry-run: nothing written.');
            return 0;
        }
        const sink = openSink(root, out);
        if (sink === null)
            return 2;
        let res;
        let st;
        let pruned = 0;
        try {
            res = sink.upsert(result.records);
            if (!flags.has('--no-prune'))
                pruned = sink.prune(new Set(result.records.map((r) => r.id)));
            st = sink.stats();
        }
        finally {
            sink.close(); // checkpoints the WAL, so the size below is the real on-disk size
        }
        out('');
        out(`Wrote ${sink.dbPath}`);
        out(`  inserted ${res.inserted}  updated ${res.updated}  skipped ${res.skipped}  pruned ${pruned}`);
        out(`  ${st.current} current records of ${st.total} rows; db ${dbSize(sink.dbPath)}`);
        return 0;
    }
    if (cmd === 'stats') {
        const sink = openSink(root, out);
        if (sink === null)
            return 2;
        try {
            const st = sink.stats();
            if (json) {
                out(JSON.stringify({ ...st, dbPath: sink.dbPath }, null, 2));
                return 0;
            }
            out(`${sink.dbPath}  (${dbSize(sink.dbPath)})`);
            out(`  ${st.current} current records, ${st.total} rows total`);
            for (const k of memory_seed_1.SEED_KINDS)
                out(`  ${k.padEnd(10)} ${st.byKind[k] ?? 0}`);
            return st.total === 0 ? 1 : 0;
        }
        finally {
            sink.close();
        }
    }
    if (cmd === 'search') {
        const query = rest.join(' ');
        if (query === '') {
            out('memory search: needs a query');
            return 2;
        }
        const sink = openSink(root, out);
        if (sink === null)
            return 2;
        try {
            const opt = {
                limit: num('--limit', memory_sink_1.DEFAULT_LIMIT),
                tokenBudget: num('--budget', memory_sink_1.DEFAULT_TOKEN_BUDGET),
            };
            if (kinds.length > 0)
                opt.kinds = kinds;
            const res = sink.search(query, opt);
            if (json) {
                out(JSON.stringify(res, null, 2));
                return res.records.length === 0 ? 1 : 0;
            }
            out(`${res.records.length} result(s)  ${res.tokensUsed}/${res.tokensBudget} tok${res.truncated ? '  (truncated)' : ''}`);
            for (const r of res.records)
                fmt(r, out);
            return res.records.length === 0 ? 1 : 0;
        }
        finally {
            sink.close();
        }
    }
    if (cmd === 'recent') {
        const sink = openSink(root, out);
        if (sink === null)
            return 2;
        try {
            const recs = sink.recent(kinds[0] ?? null, num('--limit', memory_sink_1.DEFAULT_LIMIT));
            if (json) {
                out(JSON.stringify(recs, null, 2));
                return recs.length === 0 ? 1 : 0;
            }
            for (const r of recs)
                fmt(r, out);
            return recs.length === 0 ? 1 : 0;
        }
        finally {
            sink.close();
        }
    }
    if (cmd === 'roles') {
        const sink = openSink(root, out);
        if (sink === null)
            return 2;
        let empty = 0;
        try {
            for (const rq of exports.ROLE_QUESTIONS) {
                const res = sink.search(rq.question, { kinds: rq.kinds, limit: num('--limit', 3) });
                const top = res.records[0];
                out(`${rq.role.padEnd(21)} ${res.records.length} hit(s), ${res.tokensUsed} tok`);
                out(`  q: ${rq.question}`);
                if (top === undefined) {
                    empty += 1;
                    out('  → NOTHING FOUND');
                }
                else {
                    for (const r of res.records)
                        out(`  → [${r.kind}] ${r.title.slice(0, 150)}`);
                }
                out('');
            }
        }
        finally {
            sink.close();
        }
        out(empty === 0 ? 'every role question returns at least one record.' : `${empty} role question(s) returned nothing.`);
        return empty === 0 ? 0 : 1;
    }
    out('usage: memory seed [--from <root>] [--dry-run] [--verbose] [--no-prune]');
    out('       memory stats [--json]');
    out('       memory search <query> [--kinds insight,decision] [--limit N] [--budget N] [--json]');
    out('       memory recent [--kind insight] [--limit N] [--json]');
    out('       memory roles');
    out('');
    out(`kinds: ${memory_seed_1.SEED_KINDS.join(', ')}`);
    out('db:    $HARNESS_MEMORY_DB, else $CLAUDE_PLUGIN_DATA/memory.db, else .harness/state/memory.db');
    return 2;
}
function dbSize(p) {
    try {
        const b = fs.statSync(p).size;
        return b < 1024 * 1024 ? `${(b / 1024).toFixed(1)} KB` : `${(b / 1024 / 1024).toFixed(2)} MB`;
    }
    catch {
        return 'unknown size';
    }
}
if (require.main === module) {
    const root = path.resolve(__dirname, '../..');
    process.exit(run(process.argv.slice(2), root, (s) => process.stdout.write(`${s}\n`)));
}
