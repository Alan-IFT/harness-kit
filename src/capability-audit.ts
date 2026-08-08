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
 *     while holding no `Bash` at all.
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

import * as fs from 'node:fs';
import * as path from 'node:path';

/** A capability an instruction can demand. Named exactly as a `tools:` line spells it. */
export type Capability = 'Bash' | 'Write' | 'Edit' | 'Task';

export interface Demand {
  /**
   * Capabilities that would satisfy this demand — ANY one of them suffices.
   *
   * Kept as a list after the Windows removal collapsed its original motivating case (a
   * script invocation used to be satisfiable by `Bash` OR `PowerShell`, since every tool
   * shipped both). A demand with more than one satisfier is a real shape, not an artefact
   * of that pair, and modelling it as separate demands reported the same line twice.
   */
  capability: Capability[];
  /** 1-based line in the contract. */
  line: number;
  /** The instruction, trimmed, as evidence. */
  text: string;
}

export interface Finding {
  agent: string;
  capability: Capability[];
  line: number;
  text: string;
}

/**
 * A granted MCP tool name that no configured server provides.
 *
 * The mirror of the demand direction, and it fails more quietly. A contract that INSTRUCTS
 * beyond its grant produces a visible error when the agent tries; a contract that GRANTS a
 * name nothing resolves produces nothing at all — Claude Code drops the unresolvable entry,
 * the subagent starts normally, and the capability is simply absent. Nobody is told.
 *
 * The name has two parts that are easy to get wrong independently. A plugin-provided server
 * is addressed as `mcp__plugin_<plugin>_<server>__<tool>`, not `mcp__<server>__<tool>` — the
 * v2 migration brief specifies the latter — and each tool's own name is repeated inside it
 * (`codegraph_explore`, not `explore`). Both were verified against a live `tools/list`.
 */
export interface McpFinding {
  agent: string;
  tool: string;
  reason: 'unknown-server' | 'unknown-tool';
  known: string[];
}

/**
 * Patterns that constitute a demand. Each must be an IMPERATIVE naming a concrete artifact.
 *
 * Deliberately narrow. `guard-rm`'s own history is the argument: a matcher that fires on
 * the wrong thing is worse than one that fires on less, because the first gets disabled.
 */
const DEMANDS: ReadonlyArray<{ capability: Capability[]; re: RegExp }> = [
  // "Run `.harness/scripts/x`", "call `.harness/scripts/x`", "Run `verify_all`".
  {
    capability: ['Bash'],
    re: /\b(run|call|invoke|execute)\b[^.\n]{0,40}`[^`\n]*(\.harness\/scripts\/|verify_all)[^`\n]*`/i,
  },
  // "Write your decision into `X.md`".
  { capability: ['Write'], re: /\bwrite\b[^.\n]{0,40}(into|to)\b[^.\n]{0,40}`[^`\n]+\.md`/i },
  // "dispatch ... via the Task tool".
  { capability: ['Task'], re: /\bTask tool\b/ },
];

const EXEMPT_RE = /<!--\s*capability-audit:\s*allow\s+([A-Za-z]+)/g;

/** The `tools:` frontmatter line, as a set. An absent line means every tool is inherited. */
export function grantedTools(contract: string): Set<string> | null {
  const m = /^tools:\s*(.+)$/m.exec(contract);
  if (m === null || m[1] === undefined) return null; // inherits everything
  return new Set(m[1].split(',').map((t) => t.trim()).filter((t) => t !== ''));
}

export function exemptions(contract: string): Set<string> {
  const out = new Set<string>();
  for (const m of contract.matchAll(EXEMPT_RE)) if (m[1] !== undefined) out.add(m[1]);
  return out;
}

/** Every demand a contract's body makes. Frontmatter and fenced blocks are skipped. */
export function demandsOf(contract: string): Demand[] {
  const lines = contract.split('\n');
  const found: Demand[] = [];
  let inFrontmatter = false;
  let inFence = false;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i] as string;
    if (i === 0 && line.trim() === '---') {
      inFrontmatter = true;
      continue;
    }
    if (inFrontmatter) {
      if (line.trim() === '---') inFrontmatter = false;
      continue;
    }
    // A fenced block is an EXAMPLE, not an instruction. Treating one as a demand is the
    // mistake T-23 recorded from the other direction — an example contradicting its rule.
    if (/^\s*```/.test(line)) {
      inFence = !inFence;
      continue;
    }
    if (inFence) continue;

    for (const d of DEMANDS) {
      if (d.re.test(line)) found.push({ capability: d.capability, line: i + 1, text: line.trim() });
    }
  }
  return found;
}

export function auditContract(name: string, contract: string): Finding[] {
  const granted = grantedTools(contract);
  if (granted === null) return []; // inherits every tool; nothing can be missing
  const allowed = exemptions(contract);
  const out: Finding[] = [];
  for (const d of demandsOf(contract)) {
    // ANY of the alternatives satisfies the demand.
    if (d.capability.some((c) => granted.has(c))) continue;
    if (d.capability.some((c) => allowed.has(c))) continue;
    out.push({ agent: name, capability: d.capability, line: d.line, text: d.text });
  }
  return out;
}

export function auditDir(dir: string): Finding[] {
  const files = fs.readdirSync(dir).filter((f) => f.endsWith('.md')).sort();
  return files.flatMap((f) => auditContract(f.replace(/\.md$/, ''), fs.readFileSync(path.join(dir, f), 'utf8')));
}

// ---------------------------------------------------------------- MCP tool names

/**
 * The MCP tool names a plugin's `.mcp.json` makes addressable.
 *
 * Derived, never listed: the server names come from `mcpServers`, the plugin prefix from
 * `.claude-plugin/plugin.json`, and each server's tool set from the env var that server uses
 * to publish one. Only `CODEGRAPH_MCP_TOOLS` is understood today; a server that advertises no
 * such list contributes its name for the server-level check and nothing for the tool-level
 * one, so an unknown server can never turn into a false accusation about its tools.
 */
export function knownMcpTools(root: string): { servers: Set<string>; tools: Set<string> } {
  const servers = new Set<string>();
  const tools = new Set<string>();

  let plugin = '';
  try {
    plugin = JSON.parse(fs.readFileSync(path.join(root, '.claude-plugin', 'plugin.json'), 'utf8')).name ?? '';
  } catch {
    /* not a plugin repo: the prefix is empty and only bare server names resolve */
  }

  let cfg: { mcpServers?: Record<string, { env?: Record<string, string> }> };
  try {
    cfg = JSON.parse(fs.readFileSync(path.join(root, '.mcp.json'), 'utf8'));
  } catch {
    return { servers, tools };
  }

  for (const [server, spec] of Object.entries(cfg.mcpServers ?? {})) {
    const addressed = plugin === '' ? server : `plugin_${plugin}_${server}`;
    servers.add(addressed);
    const list = spec.env?.[`${server.toUpperCase()}_MCP_TOOLS`];
    if (list === undefined) continue;
    for (const t of list.split(',').map((s) => s.trim()).filter((s) => s !== '')) {
      // A server publishes short names; it exposes them prefixed with its own.
      tools.add(`mcp__${addressed}__${server}_${t}`);
    }
  }
  return { servers, tools };
}

/** Granted `mcp__…` names that no configured server provides. */
export function auditMcpGrants(name: string, contract: string, known: ReturnType<typeof knownMcpTools>): McpFinding[] {
  const granted = grantedTools(contract);
  if (granted === null) return [];
  const out: McpFinding[] = [];
  for (const t of granted) {
    if (!t.startsWith('mcp__')) continue;
    const server = t.slice('mcp__'.length).split('__')[0] ?? '';
    if (!known.servers.has(server)) {
      out.push({ agent: name, tool: t, reason: 'unknown-server', known: [...known.servers].sort() });
      continue;
    }
    // A server-level grant (`mcp__server` or `mcp__server__*`) names no single tool.
    if (t === `mcp__${server}` || t === `mcp__${server}__*`) continue;
    if (known.tools.size > 0 && !known.tools.has(t)) {
      out.push({ agent: name, tool: t, reason: 'unknown-tool', known: [...known.tools].sort() });
    }
  }
  return out;
}

export function auditMcpDir(dir: string, root: string): McpFinding[] {
  const known = knownMcpTools(root);
  const files = fs.readdirSync(dir).filter((f) => f.endsWith('.md')).sort();
  return files.flatMap((f) => auditMcpGrants(f.replace(/\.md$/, ''), fs.readFileSync(path.join(dir, f), 'utf8'), known));
}

export function run(argv: readonly string[], root: string, out: (s: string) => void): number {
  const dir = path.join(root, 'agents');
  let findings: Finding[];
  let mcp: McpFinding[];
  try {
    findings = auditDir(dir);
    mcp = auditMcpDir(dir, root);
  } catch {
    out(`capability-audit: cannot read ${dir}`);
    return 2;
  }

  if (argv.includes('--json')) {
    out(JSON.stringify({ demands: findings, mcpGrants: mcp }, null, 2));
    return findings.length === 0 && mcp.length === 0 ? 0 : 1;
  }

  if (mcp.length > 0) {
    out(`capability-audit: ${mcp.length} granted MCP tool name(s) resolve to nothing.`);
    out('');
    for (const f of mcp) {
      out(`  ${f.agent}.md grants ${f.tool} — ${f.reason}`);
    }
    const known = mcp[0]?.known ?? [];
    if (known.length > 0) {
      out('');
      out('  Addressable today:');
      for (const k of known) out(`    ${k}`);
    }
    out('');
    out('An unresolvable name is DROPPED silently: the subagent starts and the capability is');
    out('simply absent. Fix the name, or remove the grant.');
    return 1;
  }

  if (findings.length === 0) {
    out('capability-audit: every instruction is within its agent\'s granted tools, and every');
    out('granted MCP tool name resolves.');
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
