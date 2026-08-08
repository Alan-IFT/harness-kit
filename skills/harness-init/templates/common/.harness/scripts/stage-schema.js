"use strict";
/**
 * stage-schema — which sections a stage contract declares, and which role each one is
 * addressed to.
 *
 * ## The gap this closes
 *
 * T-18 `stage-contract-split` typed every stage document: the authoring agent's contract
 * declares an exact section list, and `agents/requirement-analyst.md` states the rule in
 * one clause — "never invent a section". Measured across the 44 archived tasks plus the
 * live one, that instruction binds nothing:
 *
 *   01_REQUIREMENT_ANALYSIS   0/44 documents conform; 210 of 446 headings are declared
 *   02_SOLUTION_DESIGN        0/43 documents conform; 115 of 692 headings are declared
 *   03_GATE_REVIEW            2/44 documents conform;  72 of 295 headings are declared
 *
 * The most recent task (T-24, authored after the typed schema landed) emitted a 02 with 16
 * sections of which 5 are declared. So the schema is guidance nothing reads back, which is
 * the failure `.harness/rejected-decisions.md` names under `stage-bloat-prohibitions-only`:
 * "a prohibition depends on compliance and has nothing enforcing it".
 *
 * ## What this adds
 *
 * The section list becomes machine-readable, and each section gains its READERS — the roles
 * that must obey it. `docs/proposals/v2-p1-blockers.md` §3 selected this shape over the
 * migration brief's handoff card for two reasons that still hold: the consumer reads the
 * ORIGINAL section (so nothing needs keeping in sync, and `stage-doc-summary-header` does
 * not attach), and the routing is checkable rather than requested.
 *
 * Readers are declared HERE and not beside the section list. A subagent's system prompt is
 * its agent file's body, so a column that no authoring agent needs — the author writes every
 * section of its own schema regardless of who reads it — would be paid on every dispatch to
 * buy nothing. The same argument moved the section list itself out of `agents/<role>.md` and
 * into `.harness/playbooks/<role>.md` at P4: a schema table is needed once, when the document
 * is written. `--check` gates this file against whichever file carries the table, so the two
 * still cannot drift silently.
 *
 * ## Why an unknown heading is KEPT, not dropped
 *
 * Selection drops a section only when the schema declares it AND declares it addressed
 * elsewhere. A heading this file does not recognise is returned. That is what makes the
 * mechanism safe to ship against 44 non-conforming archives: it can lower the prize, never
 * the completeness. Conformance raises the prize; it is not a precondition for correctness.
 *
 * Addressing is a DEFAULT, not a wall. Any role can still name any section:
 *   node .harness/scripts/doc-query.js --in stage --task <slug> --heading '<Section>'
 *
 * Usage:
 *   node .harness/scripts/stage-schema.js --map [--for <role>]
 *   node .harness/scripts/stage-schema.js --lint --task <slug>
 *   node .harness/scripts/stage-schema.js --check          # needs .harness/playbooks/*.md
 * Exit: 0 clean, 1 findings, 2 usage error.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.STAGE_SCHEMA = exports.ROLES = void 0;
exports.resolveRole = resolveRole;
exports.normalizeHeading = normalizeHeading;
exports.specFor = specFor;
exports.resolveSection = resolveSection;
exports.select = select;
exports.docsAddressedTo = docsAddressedTo;
exports.headingsOf = headingsOf;
exports.lintDocument = lintDocument;
exports.lintTask = lintTask;
exports.sectionsDeclaredBy = sectionsDeclaredBy;
exports.checkAgainstContracts = checkAgainstContracts;
exports.run = run;
const fs = require("node:fs");
const path = require("node:path");
exports.ROLES = [
    'requirement-analyst',
    'solution-architect',
    'gate-reviewer',
    'developer',
    'code-reviewer',
    'qa-tester',
    'pm-orchestrator',
];
/** Short aliases, so `--for dev` works from a hand-typed command line. */
const ROLE_ALIASES = {
    ra: 'requirement-analyst',
    analyst: 'requirement-analyst',
    sa: 'solution-architect',
    architect: 'solution-architect',
    gr: 'gate-reviewer',
    gate: 'gate-reviewer',
    dev: 'developer',
    cr: 'code-reviewer',
    review: 'code-reviewer',
    qa: 'qa-tester',
    pm: 'pm-orchestrator',
};
function resolveRole(name) {
    const v = name.trim().toLowerCase();
    if (exports.ROLES.includes(v))
        return v;
    return ROLE_ALIASES[v] ?? null;
}
const SA = 'solution-architect';
const GR = 'gate-reviewer';
const DEV = 'developer';
const CR = 'code-reviewer';
const QA = 'qa-tester';
const PM = 'pm-orchestrator';
const RA = 'requirement-analyst';
/**
 * The routing table.
 *
 * Two entries deliberately drop a role that a generous reading would include, and each is
 * the mechanism doing its job rather than an oversight:
 *
 *   03 `## Findings`         — not addressed to the Developer. The gate discharges findings
 *                              into `## Binding conditions`, which its own contract calls
 *                              authoritative, and `04_DEVELOPMENT.md`'s
 *                              `## Condition disposition` takes one row per binding
 *                              condition. Findings are addressed to the upstream authors
 *                              who must fix the document. It is the largest section of a
 *                              gate review (9.3 KB of 26.5 KB in T-24).
 *   02 `## Verification plan` — not addressed to the Developer. It states what will be run
 *                              and against which acceptance criterion; the criteria
 *                              themselves are binding on the Developer from 01, and the
 *                              plan's consumer is QA and the gate.
 */
exports.STAGE_SCHEMA = [
    {
        stage: 1,
        doc: '01_REQUIREMENT_ANALYSIS',
        agent: 'requirement-analyst',
        sections: [
            { name: 'Goal', readers: [SA, GR, DEV, CR, QA] },
            { name: 'In-scope behaviors', readers: [SA, GR, DEV, CR, QA] },
            { name: 'Out of scope', readers: [SA, GR, DEV, CR, QA] },
            { name: 'Boundary conditions', readers: [SA, GR, DEV, CR, QA] },
            { name: 'Acceptance criteria', readers: [SA, GR, DEV, CR, QA] },
            { name: 'Non-functional requirements', readers: [SA, GR, DEV, CR, QA], optional: true },
            { name: 'Resolved questions', readers: [SA, GR, DEV, CR, QA] },
            { name: 'Verdict', readers: [PM] },
        ],
    },
    {
        stage: 2,
        doc: '02_SOLUTION_DESIGN',
        agent: 'solution-architect',
        sections: [
            { name: 'Architecture summary', readers: [GR, DEV, CR, QA] },
            { name: 'Change ledger', readers: [GR, DEV, CR] },
            { name: 'Interfaces', readers: [GR, DEV, CR, QA] },
            { name: 'Constraints', readers: [GR, DEV, CR, QA] },
            { name: 'Byte-form specification', readers: [GR, DEV, CR], optional: true },
            { name: 'Frozen set', readers: [GR, DEV, CR] },
            { name: 'Migration & edit sequence', readers: [GR, DEV, CR] },
            { name: 'Out of scope', readers: [GR, DEV, CR, QA] },
            { name: 'Verification plan', readers: [GR, CR, QA] },
            { name: 'Residuals travelling', readers: [GR, DEV, CR, QA] },
            { name: 'Partition assignment', readers: [GR, DEV], optional: true },
            { name: 'Verdict', readers: [PM] },
        ],
    },
    {
        stage: 3,
        doc: '03_GATE_REVIEW',
        agent: 'gate-reviewer',
        sections: [
            { name: 'Dimension audit', readers: [PM] },
            { name: 'Findings', readers: [PM, RA, SA] },
            { name: 'Binding conditions', readers: [DEV, CR, QA, PM] },
            { name: 'Pre-answered developer questions', readers: [DEV] },
            { name: 'Verdict', readers: [PM] },
        ],
    },
    {
        stage: 4,
        doc: '04_DEVELOPMENT',
        agent: 'developer',
        sections: [
            { name: 'Summary', readers: [CR, QA] },
            { name: 'Files changed', readers: [CR, QA] },
            { name: 'verify_all result', readers: [CR, QA, PM] },
            { name: 'Design drift', readers: [CR, QA, PM] },
            { name: 'Condition disposition', readers: [CR, PM] },
            { name: 'Open issues for review', readers: [CR, QA] },
            { name: 'Dev-map updates', readers: [PM] },
            { name: 'Insight to surface', readers: [PM], optional: true },
            { name: 'Verdict', readers: [PM] },
        ],
    },
    {
        stage: 5,
        doc: '05_CODE_REVIEW',
        agent: 'code-reviewer',
        sections: [
            { name: 'Files reviewed', readers: [PM] },
            { name: 'Findings', readers: [DEV, QA, PM] },
            { name: 'Requirement coverage check', readers: [QA, PM] },
            { name: 'Design fidelity check', readers: [DEV, PM] },
            { name: 'Axis status', readers: [PM] },
            { name: 'Residuals travelling', readers: [DEV, QA, PM] },
            { name: 'Verdict', readers: [PM] },
        ],
    },
    {
        stage: 6,
        doc: '06_TEST_REPORT',
        agent: 'qa-tester',
        sections: [
            { name: 'Test plan', readers: [PM] },
            { name: 'Adversarial tests', readers: [PM] },
            { name: 'Boundary tests added', readers: [PM] },
            { name: 'verify_all result', readers: [PM] },
            { name: 'Defects found', readers: [DEV, PM] },
            { name: 'Stability', readers: [DEV, PM] },
            { name: 'Verdict', readers: [PM] },
        ],
    },
];
/**
 * Reduce a heading to its comparison form.
 *
 * Generous on purpose. Every archived document numbers its sections (`## 3. In-scope
 * behaviors`) and several hyphenate differently (`## Out-of-scope`); refusing those spends
 * the mechanism's only enforcement signal on typography rather than on invented sections,
 * which is the thing worth catching. No two declared names collide under this reduction —
 * a unit test asserts it, so the generosity cannot silently merge two sections.
 */
function normalizeHeading(raw) {
    return raw
        .replace(/^#+\s*/, '')
        .replace(/^\d+[.)]?\s+/, '')
        .toLowerCase()
        .replace(/&/g, ' and ')
        .replace(/[^a-z0-9]+/g, ' ')
        .trim();
}
function specFor(doc) {
    return exports.STAGE_SCHEMA.find((s) => s.doc === doc) ?? null;
}
/** The declared section a heading resolves to, or null when the schema does not know it. */
function resolveSection(doc, heading) {
    const spec = specFor(doc);
    if (spec === null)
        return null;
    const key = normalizeHeading(heading);
    return spec.sections.find((s) => normalizeHeading(s.name) === key) ?? null;
}
/**
 * Decide one section's fate for one reader.
 *
 * The asymmetry is the safety property: a section is dropped only on a POSITIVE statement
 * that someone else owns it. Silence keeps it.
 */
function select(doc, heading, role) {
    const section = resolveSection(doc, heading);
    if (section === null)
        return { keep: true, undeclared: true, section: null };
    return { keep: section.readers.includes(role), undeclared: false, section };
}
/** Every stage document that declares at least one section addressed to `role`. */
function docsAddressedTo(role) {
    return exports.STAGE_SCHEMA.filter((s) => s.sections.some((x) => x.readers.includes(role))).map((s) => s.doc);
}
/** Headings of a document, in order, with their 1-based line numbers. */
function headingsOf(content) {
    const out = [];
    const lines = content.split('\n');
    let fenced = false;
    for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        if (/^\s*```/.test(line))
            fenced = !fenced;
        if (!fenced && /^## /.test(line))
            out.push({ heading: line.replace(/^##\s*/, '').trim(), line: i + 1 });
    }
    return out;
}
function lintDocument(doc, content, file) {
    const spec = specFor(doc);
    if (spec === null)
        return [];
    const findings = [];
    const seen = new Set();
    for (const h of headingsOf(content)) {
        const section = resolveSection(doc, h.heading);
        if (section === null)
            findings.push({ file, line: h.line, kind: 'undeclared', heading: h.heading });
        else
            seen.add(normalizeHeading(section.name));
    }
    for (const s of spec.sections) {
        if (s.optional === true)
            continue;
        if (!seen.has(normalizeHeading(s.name)))
            findings.push({ file, line: 0, kind: 'missing', heading: s.name });
    }
    return findings;
}
/** Lint every stage contract present in a task folder. */
function lintTask(root, slug) {
    const candidates = [path.join('docs', 'features', slug), path.join('docs', 'features', '_archived', slug)];
    const dir = candidates.find((c) => fs.existsSync(path.join(root, c))) ?? null;
    if (dir === null)
        return { dir: null, findings: [] };
    const findings = [];
    for (const spec of exports.STAGE_SCHEMA) {
        const rel = path.join(dir, `${spec.doc}.md`);
        let content;
        try {
            content = fs.readFileSync(path.join(root, rel), 'utf8');
        }
        catch {
            continue; // a stage the task never reached is not a finding
        }
        findings.push(...lintDocument(spec.doc, content, rel));
    }
    return { dir, findings };
}
// -------------------------------------------------------------------------- check
/**
 * Read the section list an agent contract declares.
 *
 * The contracts all use one shape — a `| Section | Shape |` table whose first cell is a
 * backticked `## Name`. Parsing that rather than a hand-kept duplicate is the point: the
 * contract stays the place a section list is edited.
 */
function sectionsDeclaredBy(contract) {
    const lines = contract.split('\n');
    const out = [];
    let inTable = false;
    for (const line of lines) {
        if (/^\|\s*Section\s*\|\s*Shape\s*\|/.test(line)) {
            inTable = true;
            continue;
        }
        if (!inTable)
            continue;
        if (!line.startsWith('|')) {
            inTable = false;
            continue;
        }
        if (/^\|\s*-+/.test(line))
            continue;
        const cell = line.split('|')[1] ?? '';
        const m = /`##\s+([^`]+)`/.exec(cell);
        if (m)
            out.push(m[1].trim());
    }
    return out;
}
/**
 * Cross-check `STAGE_SCHEMA` against the documents that declare the same lists.
 *
 * Those lists used to live in `agents/<role>.md`. At the P4 slimming they moved to
 * `.harness/playbooks/<role>.md`, because a subagent's system prompt IS its agent file and a
 * schema table is only needed at the moment the document is written — not on every dispatch.
 * The gate follows the table: whichever file carries the `| Section | Shape |` table is the
 * file this reads back, so the two still cannot drift silently.
 */
function checkAgainstContracts(playbooksDir) {
    const findings = [];
    for (const spec of exports.STAGE_SCHEMA) {
        for (const s of spec.sections) {
            if (s.readers.length === 0)
                findings.push({ doc: spec.doc, kind: 'no-reader', section: s.name });
        }
        let contract;
        try {
            contract = fs.readFileSync(path.join(playbooksDir, `${spec.agent}.md`), 'utf8');
        }
        catch {
            findings.push({ doc: spec.doc, kind: 'contract-missing', section: `${spec.agent}.md` });
            continue;
        }
        const declared = sectionsDeclaredBy(contract);
        if (declared.length === 0) {
            findings.push({ doc: spec.doc, kind: 'no-table', section: `${spec.agent}.md` });
            continue;
        }
        const here = new Set(spec.sections.map((s) => normalizeHeading(s.name)));
        const there = new Set(declared.map(normalizeHeading));
        for (const d of declared)
            if (!here.has(normalizeHeading(d)))
                findings.push({ doc: spec.doc, kind: 'only-in-contract', section: d });
        for (const s of spec.sections)
            if (!there.has(normalizeHeading(s.name)))
                findings.push({ doc: spec.doc, kind: 'only-in-schema', section: s.name });
    }
    return findings;
}
// ---------------------------------------------------------------------------- cli
function printMap(out, role) {
    for (const spec of exports.STAGE_SCHEMA) {
        const rows = spec.sections.filter((s) => role === null || s.readers.includes(role));
        if (rows.length === 0)
            continue;
        out(`${spec.doc}  (authored by ${spec.agent})`);
        for (const s of rows) {
            const flag = s.optional === true ? ' [optional]' : '';
            out(role === null ? `  ## ${s.name}${flag}  ->  ${s.readers.join(', ')}` : `  ## ${s.name}${flag}`);
        }
        out('');
    }
}
function run(argv, root, out) {
    const flags = new Set(argv.filter((a) => a.startsWith('--')));
    const valueOf = (name) => {
        const i = argv.indexOf(name);
        return i >= 0 ? argv[i + 1] : undefined;
    };
    let role = null;
    const forVal = valueOf('--for');
    if (forVal !== undefined) {
        role = resolveRole(forVal);
        if (role === null) {
            out(`Unknown role ${JSON.stringify(forVal)}. Known: ${exports.ROLES.join(', ')}.`);
            return 2;
        }
    }
    if (flags.has('--map')) {
        printMap(out, role);
        return 0;
    }
    if (flags.has('--lint')) {
        const slug = valueOf('--task');
        if (slug === undefined) {
            out('usage: stage-schema --lint --task <slug>');
            return 2;
        }
        const { dir, findings } = lintTask(root, slug);
        if (dir === null) {
            out(`No task folder for ${JSON.stringify(slug)} under docs/features/.`);
            return 2;
        }
        if (findings.length === 0) {
            out(`${dir}: every stage contract present conforms to its declared schema.`);
            return 0;
        }
        for (const f of findings) {
            if (f.kind === 'undeclared')
                out(`${f.file}:${f.line}: undeclared section "## ${f.heading}"`);
            else
                out(`${f.file}: missing required section "## ${f.heading}"`);
        }
        out('');
        out('An undeclared section means content landed where no downstream role is addressed.');
        out('Route it with `.harness/rules/70-doc-size.md` `## Stage-doc boundary rule`: into a');
        out('declared section (`## Constraints` is the residual home for a binding statement), or');
        out('into the sibling `0N_RATIONALE.md`.');
        return 1;
    }
    if (flags.has('--check')) {
        const playbooksDir = valueOf('--playbooks') ?? path.join(root, '.harness', 'playbooks');
        const findings = checkAgainstContracts(playbooksDir);
        if (findings.length === 0) {
            const n = exports.STAGE_SCHEMA.reduce((a, s) => a + s.sections.length, 0);
            out(`${n} sections across ${exports.STAGE_SCHEMA.length} stage contracts; schema and playbooks agree.`);
            return 0;
        }
        for (const f of findings)
            out(`${f.doc}: ${f.kind}: ${f.section}`);
        return 1;
    }
    out('usage: stage-schema --map [--for <role>]');
    out('       stage-schema --lint --task <slug>');
    out('       stage-schema --check [--playbooks <dir>]');
    out('');
    out('--map   who reads which section of which stage contract');
    out('--lint  does a task\'s stage contracts use only their declared sections');
    out('--check does this table still agree with the playbooks that declare it');
    return 2;
}
if (require.main === module) {
    const root = path.resolve(__dirname, '../..');
    process.exit(run(process.argv.slice(2), root, (s) => process.stdout.write(`${s}\n`)));
}
