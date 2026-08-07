"use strict";
/**
 * capability-audit — cross-check what each agent contract INSTRUCTS against what its
 * `tools:` line GRANTS.
 *
 * ## The defect class this closes
 *
 * A contract can name a duty its agent is physically incapable of performing, and nothing
 * notices. It has happened three times in this project:
 *
 *   - `gate-reviewer` and `code-reviewer` declare `Read, Glob, Grep` while their
 *     `## What you produce` sections name stage documents they must create. Latent for as
 *     long as both contracts existed; the orchestrator transcribes on their behalf.
 *   - `pm-orchestrator` is told twice, emphatically, to run `.harness/scripts/archive-task`
 *     — "skipping it is the #1 cause of long-term bloat" — and to call `entropy-cadence`,
 *     while holding neither `Bash` nor `PowerShell`.
 *   - The v2 migration's first pass told six agents to run a query script; five of them
 *     cannot run any script at all.
 *
 * Every instance was found by someone reading carefully. That is not a mechanism.
 * `.harness/rejected-decisions.md` names the remedy directly: `reviewer-write-grant` may be
 * re-surfaced "with a path-scoped write capability, **or a check that reads an agent's
 * `tools:` line**". This is that check.
 *
 * ## How it decides
 *
 * Only HIGH-PRECISION demands are reported, because a false positive here trains people to
 * ignore the check, which is worse than not having it. A demand is recognised only from an
 * imperative form naming a concrete artifact — "run `.harness/scripts/x`", "run
 * `verify_all`", "dispatch via the Task tool" — never from prose that merely mentions a
 * capability. A contract that DISCLAIMS a duty ("you never write", "PM transcribes on your
 * behalf") is prose, and prose cannot demand.
 *
 * Exemptions are declared in the contract itself, in-band, so the reason travels with the
 * text rather than living in this file:
 *
 *     <!-- capability-audit: allow Bash — the orchestrator transcribes on this role's behalf -->
 *
 * Usage:
 *   node .harness/scripts/capability-audit.js [--json]
 * Exit: 0 clean, 1 mismatches found, 2 could not read the agent directory.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.grantedTools = grantedTools;
exports.exemptions = exemptions;
exports.demandsOf = demandsOf;
exports.auditContract = auditContract;
exports.auditDir = auditDir;
exports.run = run;
const fs = require("node:fs");
const path = require("node:path");
/**
 * Patterns that constitute a demand. Each must be an IMPERATIVE naming a concrete artifact.
 *
 * Deliberately narrow. `guard-rm`'s own history is the argument: a matcher that fires on
 * the wrong thing is worse than one that fires on less, because the first gets disabled.
 */
const DEMANDS = [
    // "Run `.harness/scripts/x`", "call `.harness/scripts/x`", "Run `verify_all`", or an
    // explicit `pwsh` form. Either shell satisfies it — the repo ships both twins.
    {
        capability: ['Bash', 'PowerShell'],
        re: /\b(run|call|invoke|execute)\b[^.\n]{0,40}`[^`\n]*(\.harness\/scripts\/|verify_all|pwsh)[^`\n]*`/i,
    },
    // "Write your decision into `X.md`".
    { capability: ['Write'], re: /\bwrite\b[^.\n]{0,40}(into|to)\b[^.\n]{0,40}`[^`\n]+\.md`/i },
    // "dispatch ... via the Task tool".
    { capability: ['Task'], re: /\bTask tool\b/ },
];
const EXEMPT_RE = /<!--\s*capability-audit:\s*allow\s+([A-Za-z]+)/g;
/** The `tools:` frontmatter line, as a set. An absent line means every tool is inherited. */
function grantedTools(contract) {
    const m = /^tools:\s*(.+)$/m.exec(contract);
    if (m === null || m[1] === undefined)
        return null; // inherits everything
    return new Set(m[1].split(',').map((t) => t.trim()).filter((t) => t !== ''));
}
function exemptions(contract) {
    const out = new Set();
    for (const m of contract.matchAll(EXEMPT_RE))
        if (m[1] !== undefined)
            out.add(m[1]);
    return out;
}
/** Every demand a contract's body makes. Frontmatter and fenced blocks are skipped. */
function demandsOf(contract) {
    const lines = contract.split('\n');
    const found = [];
    let inFrontmatter = false;
    let inFence = false;
    for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        if (i === 0 && line.trim() === '---') {
            inFrontmatter = true;
            continue;
        }
        if (inFrontmatter) {
            if (line.trim() === '---')
                inFrontmatter = false;
            continue;
        }
        // A fenced block is an EXAMPLE, not an instruction. Treating one as a demand is the
        // mistake T-23 recorded from the other direction — an example contradicting its rule.
        if (/^\s*```/.test(line)) {
            inFence = !inFence;
            continue;
        }
        if (inFence)
            continue;
        for (const d of DEMANDS) {
            if (d.re.test(line))
                found.push({ capability: d.capability, line: i + 1, text: line.trim() });
        }
    }
    return found;
}
function auditContract(name, contract) {
    const granted = grantedTools(contract);
    if (granted === null)
        return []; // inherits every tool; nothing can be missing
    const allowed = exemptions(contract);
    const out = [];
    for (const d of demandsOf(contract)) {
        // ANY of the alternatives satisfies the demand.
        if (d.capability.some((c) => granted.has(c)))
            continue;
        if (d.capability.some((c) => allowed.has(c)))
            continue;
        out.push({ agent: name, capability: d.capability, line: d.line, text: d.text });
    }
    return out;
}
function auditDir(dir) {
    const files = fs.readdirSync(dir).filter((f) => f.endsWith('.md')).sort();
    return files.flatMap((f) => auditContract(f.replace(/\.md$/, ''), fs.readFileSync(path.join(dir, f), 'utf8')));
}
function run(argv, root, out) {
    const dir = path.join(root, 'agents');
    let findings;
    try {
        findings = auditDir(dir);
    }
    catch {
        out(`capability-audit: cannot read ${dir}`);
        return 2;
    }
    if (argv.includes('--json')) {
        out(JSON.stringify(findings, null, 2));
        return findings.length === 0 ? 0 : 1;
    }
    if (findings.length === 0) {
        out('capability-audit: every instruction is within its agent\'s granted tools.');
        return 0;
    }
    out(`capability-audit: ${findings.length} instruction(s) demand a tool the agent does not hold.`);
    out('');
    for (const f of findings) {
        out(`  ${f.agent}.md:${f.line} needs ${f.capability.join(' or ')}`);
        out(`    ${f.text.slice(0, 140)}`);
    }
    out('');
    out('Resolve by granting the tool, moving the duty to a role that holds it, or — when the');
    out('duty is genuinely performed by someone else — declaring it in-band:');
    out('  <!-- capability-audit: allow <Tool> — <who performs it instead> -->');
    return 1;
}
if (require.main === module) {
    const root = path.resolve(__dirname, '../..');
    process.exit(run(process.argv.slice(2), root, (s) => process.stdout.write(`${s}\n`)));
}
