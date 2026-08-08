"use strict";
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
 * the memory stores already carry entries, so the unit boundary exists today. The refinement
 * this left open — marking each section with its intended consumer — has since landed in
 * `stage-schema.ts` and is reached from here as `--for <role>`, which returns the sections of
 * a task's stage contracts that the role must obey. It stayed a refinement rather than a
 * precondition: a heading the schema does not recognise is still returned.
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
 *   node .harness/scripts/doc-query.js --for <role> --task <slug>
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.DEFAULT_BUDGET = exports.DOC_CLASSES = void 0;
exports.stageScopeAllows = stageScopeAllows;
exports.splitUnits = splitUnits;
exports.filesOf = filesOf;
exports.query = query;
exports.addressedRead = addressedRead;
exports.run = run;
const fs = require("node:fs");
const path = require("node:path");
const stage_schema_1 = require("./stage-schema");
const MEMORY_FILES = new Set([
    '.harness/insight-index.md',
    '.harness/rejected-decisions.md',
    '.harness/decision-rubric.md',
    '.harness/operator-obligations.md',
    'CONTEXT.md',
]);
exports.DOC_CLASSES = [
    {
        scope: 'memory',
        dir: '',
        matches: (p) => MEMORY_FILES.has(p),
        // The insight index stores one fact per bullet plus its wrapped continuation lines.
        // A glossary stores one term per bold lead-in: `CONTEXT.md` carries 42 of them under a
        // SINGLE `## Language` heading, so delimiting it by heading made the entire 13.1 KB
        // glossary one unit — and any query whose term appeared anywhere in it returned all
        // 13.1 KB, which is more than reading `.harness/insight-index.md` whole. A heading still
        // opens a unit there, for a project whose glossary is written as `### Term` instead.
        // Every other store delimits by heading and uses bullets INSIDE a unit.
        opens: (p) => p === '.harness/insight-index.md' ? /^- / : p === 'CONTEXT.md' ? /^(\*\*|#{2,6} )/ : /^#{2,6} /,
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
/**
 * What an archived task is still visible as, when the query did not ask for it.
 *
 * `docs/features/_archived/` holds 7.4 MB across 44 tasks. A bare `--in stage <term>` searched
 * all of it and returned **1.4–1.7 MB** — around 400k tokens — for terms as ordinary as
 * `rollback` or `baseline`. A retrieval tool whose failure mode is destroying the context of
 * the agent that called it is worse than one that finds too little, and nothing in the tool
 * said so.
 *
 * A finished task's cross-task reader is its delivery record: `07_DELIVERY.md` averages 6.8 KB
 * and carries the verdicts, the rollback causes and the insight. The other six documents are
 * addressed to the stages of a pipeline that has already finished. So an archived task is
 * visible by its delivery record by default, and whole when the query names it — `--task
 * <slug>` — or asks for the archive explicitly with `--archived`.
 */
function stageScopeAllows(rel, opts) {
    if (!rel.includes('/_archived/'))
        return true;
    if (opts.archived === true)
        return true;
    if (opts.task !== undefined && rel.includes(`/${opts.task}/`))
        return true;
    return /07_DELIVERY\.md$/.test(rel);
}
/**
 * Default byte budget for a TERM search.
 *
 * A budget is not a cap on what matched — it is a cap on what is printed in one answer, and
 * the count of what was not printed is printed instead. Silence about the remainder would be
 * the same defect in a different place: an agent cannot narrow a query it does not know was
 * over-broad.
 *
 * 32 KB is ~9k tokens at the divisor `evals/measure-context.sh` uses — large enough that every
 * arm of the 12-item MEM control set fits whole, small enough that no single query can consume
 * a stage's opening budget. `--for` is exempt: it is a directed read of named sections, not a
 * search, and truncating it would drop binding text.
 */
exports.DEFAULT_BUDGET = 32768;
/** Split a document into units. Text before the first opener is the header and is dropped. */
function splitUnits(content, opens) {
    const lines = content.split('\n');
    const units = [];
    let cur = [];
    let start = 0;
    const flush = () => {
        if (cur.length > 0)
            units.push({ file: '', line: start + 1, text: cur.join('\n').replace(/\s+$/, '') });
        cur = [];
    };
    for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        if (opens.test(line)) {
            flush();
            start = i;
            cur = [line];
        }
        else if (cur.length > 0) {
            cur.push(line);
        }
    }
    flush();
    return units;
}
function walk(root, rel, recursive, out) {
    let entries;
    try {
        entries = fs.readdirSync(path.join(root, rel), { withFileTypes: true });
    }
    catch {
        return;
    }
    for (const e of entries) {
        const child = rel === '' ? e.name : `${rel}/${e.name}`;
        if (e.isDirectory()) {
            if (recursive && e.name !== 'node_modules' && e.name !== '.git')
                walk(root, child, recursive, out);
        }
        else if (e.isFile()) {
            out.push(child);
        }
    }
}
/** Every file belonging to `cls`, as project-relative paths. */
function filesOf(cls, root) {
    if (cls.dir === '') {
        // A root-anchored class enumerates its members directly rather than walking the tree.
        return [...MEMORY_FILES].filter((f) => fs.existsSync(path.join(root, f)));
    }
    const found = [];
    walk(root, cls.dir, cls.recursive, found);
    return found.filter((f) => cls.matches(f)).sort();
}
function query(term, root, opts) {
    const needle = term.toLowerCase();
    const classes = exports.DOC_CLASSES.filter((c) => opts.scope === 'all' || c.scope === opts.scope);
    const hits = [];
    for (const cls of classes) {
        for (const rel of filesOf(cls, root)) {
            if (cls.scope === 'stage' && opts.task !== undefined && !rel.includes(`/${opts.task}/`))
                continue;
            if (cls.scope === 'stage' && !stageScopeAllows(rel, opts))
                continue;
            if (opts.doc !== undefined && !rel.includes(opts.doc))
                continue;
            let content;
            try {
                content = fs.readFileSync(path.join(root, rel), 'utf8');
            }
            catch {
                continue;
            }
            for (const unit of splitUnits(content, cls.opens(rel))) {
                const haystack = opts.heading === true ? (unit.text.split('\n')[0] ?? '') : unit.text;
                if (haystack.toLowerCase().includes(needle))
                    hits.push({ ...unit, file: rel });
            }
        }
    }
    return hits;
}
/**
 * The sections of a task's stage contracts that `role` must obey.
 *
 * A `## ` section is the unit here, not the `^#{2,3} ` the term search uses: a `### `
 * subheading is part of the section it sits under, and returning it separately would let a
 * declared section arrive without the heading that addresses it.
 */
function addressedRead(root, role, task) {
    const cls = exports.DOC_CLASSES.find((c) => c.scope === 'stage');
    const out = [];
    for (const rel of filesOf(cls, root)) {
        if (!rel.includes(`/${task}/`))
            continue;
        const doc = path.basename(rel, '.md');
        if ((0, stage_schema_1.specFor)(doc) === null)
            continue; // PM_LOG and 07_DELIVERY have no downstream reader
        let content;
        try {
            content = fs.readFileSync(path.join(root, rel), 'utf8');
        }
        catch {
            continue;
        }
        const kept = [];
        const droppedSections = [];
        const undeclared = [];
        for (const unit of splitUnits(content, /^## /)) {
            const heading = (unit.text.split('\n')[0] ?? '').replace(/^##\s*/, '').trim();
            const verdict = (0, stage_schema_1.select)(doc, heading, role);
            if (verdict.undeclared)
                undeclared.push(heading);
            if (verdict.keep)
                kept.push({ ...unit, file: rel });
            else
                droppedSections.push(heading);
        }
        if (kept.length > 0 || droppedSections.length > 0) {
            out.push({ file: rel, kept, droppedSections, undeclared, wholeBytes: Buffer.byteLength(content) });
        }
    }
    return out;
}
function runAddressed(root, role, task, out, filesOnly) {
    const docs = addressedRead(root, role, task);
    if (docs.length === 0) {
        out(`No stage contract for task ${JSON.stringify(task)} under docs/features/.`);
        return 1;
    }
    let whole = 0;
    let addressed = 0;
    for (const d of docs) {
        const bytes = d.kept.reduce((n, u) => n + Buffer.byteLength(u.text) + 1, 0);
        whole += d.wholeBytes;
        addressed += bytes;
        out('');
        out(`--- ${d.file}  (${d.kept.length} section(s), ${bytes} of ${d.wholeBytes} bytes addressed to ${role}${d.droppedSections.length > 0 ? `; ${d.droppedSections.length} addressed elsewhere` : ''})`);
        if (d.undeclared.length > 0) {
            // Named, not hidden: an undeclared section was returned in full, so the reader is
            // complete, but the document is off-schema and its author is the one who can fix it.
            out(`    note: not in the declared schema, returned in full: ${d.undeclared.map((h) => `"${h}"`).join(', ')}`);
        }
        if (!filesOnly)
            for (const u of d.kept)
                out(u.text);
    }
    out('');
    out(`# ${addressed} of ${whole} bytes addressed to ${role}${whole > 0 ? ` (${((addressed / whole) * 100).toFixed(0)}%)` : ''}`);
    return 0;
}
function parseScope(argv) {
    const i = argv.indexOf('--in');
    const v = i >= 0 ? argv[i + 1] : undefined;
    if (v === 'memory' || v === 'stage' || v === 'rules' || v === 'all')
        return v;
    return 'all';
}
function run(argv, root, out) {
    const flags = new Set(argv.filter((a) => a.startsWith('--')));
    const scope = parseScope(argv);
    const taskIdx = argv.indexOf('--task');
    const task = taskIdx >= 0 ? argv[taskIdx + 1] : undefined;
    const forIdx = argv.indexOf('--for');
    if (forIdx >= 0) {
        const raw = argv[forIdx + 1];
        const role = raw === undefined ? null : (0, stage_schema_1.resolveRole)(raw);
        if (role === null) {
            out(`--for takes a role. Known: ${stage_schema_1.ROLES.join(', ')}.`);
            return 2;
        }
        if (task === undefined) {
            out('--for needs --task <slug>: addressing is per task, not per repository.');
            return 2;
        }
        return runAddressed(root, role, task, out, flags.has('--files'));
    }
    // Positional terms only: drop flags and the values that belong to them.
    const consumed = new Set();
    for (let i = 0; i < argv.length; i++) {
        const a = argv[i];
        if (a === '--in' || a === '--task' || a === '--for' || a === '--doc' || a === '--budget') {
            consumed.add(i);
            consumed.add(i + 1);
        }
        else if (a.startsWith('--')) {
            consumed.add(i);
        }
    }
    const term = argv.filter((_, i) => !consumed.has(i)).join(' ');
    if (flags.has('--list')) {
        const listOpts = { task, archived: flags.has('--archived') };
        for (const cls of exports.DOC_CLASSES.filter((c) => scope === 'all' || c.scope === scope)) {
            for (const f of filesOf(cls, root)) {
                if (cls.scope === 'stage' && !stageScopeAllows(f, listOpts))
                    continue;
                out(`${cls.scope}\t${f}`);
            }
        }
        return 0;
    }
    if (term === '') {
        out('usage: doc-query <term> [--in memory|stage|rules|all] [--doc <path-substring>]');
        out('                         [--task <slug>] [--archived] [--budget <bytes>]');
        out('                         [--heading] [--files] [--list]');
        out('       doc-query --for <role> --task <slug>');
        out('');
        out('Returns whole UNITS — an insight entry, a decision record, a stage-doc section —');
        out('never a line window and never the whole document.');
        out('');
        out(`A term search prints at most ${exports.DEFAULT_BUDGET} bytes and says how many units it did`);
        out('not print. An archived task is searchable by its 07_DELIVERY.md; --task <slug> or');
        out('--archived opens the rest of it.');
        out('');
        out('--heading matches the unit\'s opening line only. Use it to ask WHICH SECTION IS X;');
        out('omit it to ask WHERE IS X MENTIONED. On stage documents the first is 6x cheaper.');
        out('');
        out('--doc narrows to one store: "query the insight index" is `--in memory --doc');
        out('insight-index`, which does not also search the 49 KB obligations ledger.');
        out('');
        out('--for returns the sections of a task\'s stage contracts addressed to that role, in');
        out('document order. A section is dropped only when the schema addresses it elsewhere;');
        out('an unrecognised heading is returned. See `stage-schema.js --map`.');
        return 2;
    }
    const docIdx = argv.indexOf('--doc');
    const doc = docIdx >= 0 ? argv[docIdx + 1] : undefined;
    const archived = flags.has('--archived');
    const budgetIdx = argv.indexOf('--budget');
    const budgetRaw = budgetIdx >= 0 ? argv[budgetIdx + 1] : undefined;
    const budget = budgetRaw === undefined ? exports.DEFAULT_BUDGET : Number(budgetRaw);
    if (!Number.isFinite(budget) || budget < 0) {
        out('--budget takes a byte count; 0 means no budget.');
        return 2;
    }
    const hits = query(term, root, { scope, task, doc, archived, heading: flags.has('--heading') });
    if (hits.length === 0) {
        // Naming what was searched is the point. A bare "no results" is indistinguishable from
        // having searched the wrong place, which is exactly how an unscoped search scores 0/12
        // while looking like it worked.
        const classes = exports.DOC_CLASSES.filter((c) => scope === 'all' || c.scope === scope);
        const count = classes.reduce((n, c) => n + filesOf(c, root).filter((f) => doc === undefined || f.includes(doc)).length, 0);
        out(`No unit matches ${JSON.stringify(term)}.`);
        out(`Searched ${count} document(s) in scope ${JSON.stringify(scope)}${doc ? ` matching ${JSON.stringify(doc)}` : ''}${task ? ` for task ${task}` : ''}.`);
        if (doc !== undefined)
            out('Widen by dropping --doc.');
        else if (scope !== 'all')
            out('Widen with --in all.');
        return 1;
    }
    const filesOnly = flags.has('--files');
    out(`${hits.length} unit${hits.length === 1 ? '' : 's'} match ${JSON.stringify(term)}:`);
    let spent = 0;
    let shown = 0;
    for (const hit of hits) {
        // The budget is checked BEFORE printing, so truncation always lands on a unit boundary.
        // Half a fact is worse than a named absence — that is the same property the whole-unit
        // return exists for, applied to the answer as a whole.
        // Everything printed for this hit counts, separator included, so the reported spend is the
        // answer's real size rather than its body's.
        const sep = `--- ${hit.file}:${hit.line}`;
        const cost = Buffer.byteLength(sep) + 2 + (filesOnly ? 0 : Buffer.byteLength(hit.text) + 1);
        // `shown > 0` guarantees the first match is always printed, however large it is. A budget
        // that can return nothing reads as "no such fact", which is the failure an unscoped search
        // already makes and the one this tool exists to stop making.
        if (budget > 0 && shown > 0 && spent + cost > budget)
            break;
        spent += cost;
        shown += 1;
        out('');
        out(sep);
        if (!filesOnly)
            out(hit.text);
    }
    if (shown < hits.length) {
        out('');
        out(`# ${shown} of ${hits.length} units shown; ${spent} B of the ${budget} B budget spent.`);
        out('# Narrow with --doc / --task / --heading, or raise it with --budget <bytes> (0 = none).');
    }
    return 0;
}
if (require.main === module) {
    const root = path.resolve(__dirname, '../..');
    process.exit(run(process.argv.slice(2), root, (s) => process.stdout.write(`${s}\n`)));
}
