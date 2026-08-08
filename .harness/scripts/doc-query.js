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
exports.DOC_CLASSES = void 0;
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
        if (a === '--in' || a === '--task' || a === '--for' || a === '--doc') {
            consumed.add(i);
            consumed.add(i + 1);
        }
        else if (a.startsWith('--')) {
            consumed.add(i);
        }
    }
    const term = argv.filter((_, i) => !consumed.has(i)).join(' ');
    if (flags.has('--list')) {
        for (const cls of exports.DOC_CLASSES.filter((c) => scope === 'all' || c.scope === scope)) {
            for (const f of filesOf(cls, root))
                out(`${cls.scope}\t${f}`);
        }
        return 0;
    }
    if (term === '') {
        out('usage: doc-query <term> [--in memory|stage|rules|all] [--doc <path-substring>]');
        out('                         [--task <slug>] [--heading] [--files] [--list]');
        out('       doc-query --for <role> --task <slug>');
        out('');
        out('Returns whole UNITS — an insight entry, a decision record, a stage-doc section —');
        out('never a line window and never the whole document.');
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
    const hits = query(term, root, { scope, task, doc, heading: flags.has('--heading') });
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
    out(`${hits.length} unit${hits.length === 1 ? '' : 's'} match ${JSON.stringify(term)}:`);
    for (const hit of hits) {
        out('');
        out(`--- ${hit.file}:${hit.line}`);
        if (!flags.has('--files'))
            out(hit.text);
    }
    return 0;
}
if (require.main === module) {
    const root = path.resolve(__dirname, '../..');
    process.exit(run(process.argv.slice(2), root, (s) => process.stdout.write(`${s}\n`)));
}
