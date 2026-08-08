/**
 * Native test suite for capability-audit.
 *
 * The check exists to close a defect class that appeared three times and was caught by a
 * careful reader every time. Its value depends entirely on two properties, so both are
 * tested harder than the happy path:
 *
 *   - it FIRES on a real mismatch (otherwise it is a green light over a hole);
 *   - it does NOT fire on prose, examples, or disclaimers (otherwise it gets disabled,
 *     which is worse than never having existed).
 */

import { describe, expect, it } from 'vitest';
import * as fs from 'node:fs';
import * as path from 'node:path';
import * as os from 'node:os';
import {
  auditContract,
  auditMcpDir,
  auditMcpGrants,
  demandsOf,
  exemptions,
  grantedTools,
  knownMcpTools,
} from '../../src/capability-audit';

const contract = (tools: string | null, body: string): string =>
  ['---', 'name: x', ...(tools === null ? [] : [`tools: ${tools}`]), '---', '', body].join('\n');

describe('grantedTools', () => {
  it('parses the frontmatter list', () => {
    expect(grantedTools(contract('Read, Glob, Grep', 'x'))).toEqual(new Set(['Read', 'Glob', 'Grep']));
  });

  it('returns null when no tools line is present, meaning every tool is inherited', () => {
    expect(grantedTools(contract(null, 'x'))).toBeNull();
  });

  it('an agent that inherits every tool can never be in violation', () => {
    expect(auditContract('x', contract(null, 'Run `.harness/scripts/archive-task`.'))).toEqual([]);
  });
});

describe('it fires on a real mismatch', () => {
  it.each([
    ['a script invocation', 'Run `.harness/scripts/archive-task --task <slug>` on completion.', 'Bash'],
    ['a verify_all invocation', 'You run `verify_all` before declaring done.', 'Bash'],
    ['a call form', 'Call `.harness/scripts/entropy-cadence delivered` once per task.', 'Bash'],
    ['an explicit pwsh form', 'Run `pwsh -File .harness/scripts/x.ps1`.', 'PowerShell'],
    ['a file write', 'Write your decision into `PM_LOG.md`.', 'Write'],
    ['a dispatch', 'Dispatch each stage via the Task tool.', 'Task'],
  ])('reports %s', (_label, body, capability) => {
    const found = auditContract('x', contract('Read, Glob, Grep', body));
    expect(found).toHaveLength(1);
    expect(found[0]?.capability).toContain(capability);
  });

  it('reports every offending line, not just the first', () => {
    const body = ['Run `.harness/scripts/a`.', 'filler', 'Run `.harness/scripts/b`.'].join('\n');
    expect(auditContract('x', contract('Read', body))).toHaveLength(2);
  });

  it('reports the 1-based line number of the instruction', () => {
    const found = auditContract('x', contract('Read', ['filler', 'Run `.harness/scripts/a`.'].join('\n')));
    expect(found[0]?.line).toBe(7);
  });
});

describe('it does not fire on things that are not instructions', () => {
  it('says nothing when the tool IS granted', () => {
    expect(auditContract('x', contract('Read, Bash', 'Run `.harness/scripts/archive-task`.'))).toEqual([]);
  });

  it('ignores the frontmatter itself', () => {
    // The `tools:` line names Task; that is a grant, not a demand.
    expect(demandsOf(contract('Read, Glob', 'nothing here')).length).toBe(0);
  });

  it('ignores fenced blocks, which are examples rather than instructions', () => {
    const body = ['```bash', 'Run `.harness/scripts/archive-task`', '```'].join('\n');
    expect(auditContract('x', contract('Read', body))).toEqual([]);
  });

  it('does not read a disclaimer as a demand', () => {
    const body = [
      'You never write files; the orchestrator transcribes your body verbatim.',
      'You hold no Bash and must not attempt to run scripts.',
      'Editing upstream documents is forbidden.',
    ].join('\n');
    expect(auditContract('x', contract('Read, Glob, Grep', body))).toEqual([]);
  });

  it('does not fire on a bare mention of a script path', () => {
    const body = 'See `.harness/scripts/archive-task` for how insights are harvested.';
    expect(auditContract('x', contract('Read', body))).toEqual([]);
  });
});

describe('in-band exemptions', () => {
  const body = [
    '<!-- capability-audit: allow Write — the orchestrator transcribes on this role\'s behalf -->',
    'Write your verdict into `03_GATE_REVIEW.md`.',
  ].join('\n');

  it('parses the declared tool', () => {
    expect(exemptions(body)).toEqual(new Set(['Write']));
  });

  it('either shell satisfies a script invocation', () => {
    // The repo ships a .sh and a .ps1 for every tool, so holding one is enough.
    const body = 'Run `.harness/scripts/archive-task`.';
    expect(auditContract('x', contract('Read, Bash', body))).toEqual([]);
    expect(auditContract('x', contract('Read, PowerShell', body))).toEqual([]);
    expect(auditContract('x', contract('Read', body))).toHaveLength(1);
  });

  it('suppresses only the declared capability', () => {
    expect(auditContract('x', contract('Read, Glob, Grep', body))).toEqual([]);
    const alsoBash = `${body}\nRun \`.harness/scripts/archive-task\`.`;
    const found = auditContract('x', contract('Read, Glob, Grep', alsoBash));
    expect(found).toHaveLength(1);
    expect(found[0]?.capability).toContain('Bash');
  });
});

describe('the shipped contracts', () => {
  const dir = path.resolve(__dirname, '../../agents');

  it('every agent contract is within its granted tools', () => {
    const findings = fs
      .readdirSync(dir)
      .filter((f) => f.endsWith('.md'))
      .flatMap((f) => auditContract(f, fs.readFileSync(path.join(dir, f), 'utf8')));
    expect(findings).toEqual([]);
  });

  it('pm-orchestrator holds the Bash its lifecycle duties require', () => {
    // It is told twice, emphatically, to run archive-task — "the #1 cause of long-term
    // bloat" if skipped — and three times to call entropy-cadence.
    const pm = fs.readFileSync(path.join(dir, 'pm-orchestrator.md'), 'utf8');
    expect(grantedTools(pm)?.has('Bash')).toBe(true);
  });

  it('neither reviewer holds a write capability', () => {
    // reviewer-write-grant: the independence invariant is enforced by tool grant, and no
    // grant in this runtime is path-scoped, so Write here would also permit overwriting
    // the very design under review.
    for (const f of ['gate-reviewer.md', 'code-reviewer.md']) {
      const granted = grantedTools(fs.readFileSync(path.join(dir, f), 'utf8'));
      expect(granted?.has('Write'), f).toBe(false);
      expect(granted?.has('Edit'), f).toBe(false);
      expect(granted?.has('Bash'), f).toBe(false);
    }
  });
});

describe('granted MCP tool names', () => {
  // The mirror direction, and the quieter one: an unresolvable name is DROPPED, the subagent
  // starts, and the capability is simply absent. Nothing errors, so nothing is noticed.
  const sandbox = (mcp: unknown, plugin: string | null): string => {
    const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'mcp-audit-test-'));
    fs.writeFileSync(path.join(dir, '.mcp.json'), JSON.stringify(mcp));
    if (plugin !== null) {
      fs.mkdirSync(path.join(dir, '.claude-plugin'));
      fs.writeFileSync(path.join(dir, '.claude-plugin', 'plugin.json'), JSON.stringify({ name: plugin }));
    }
    return dir;
  };
  const cfg = {
    mcpServers: { codegraph: { env: { CODEGRAPH_MCP_TOOLS: 'explore,node,status' } } },
  };

  it('addresses a plugin server as mcp__plugin_<plugin>_<server>__<tool>', () => {
    const root = sandbox(cfg, 'harness-kit');
    const known = knownMcpTools(root);
    expect(known.servers).toContain('plugin_harness-kit_codegraph');
    expect(known.tools).toContain('mcp__plugin_harness-kit_codegraph__codegraph_explore');
    fs.rmSync(root, { recursive: true, force: true });
  });

  it('rejects the bare mcp__<server>__<tool> form the migration brief specifies', () => {
    const root = sandbox(cfg, 'harness-kit');
    const f = auditMcpGrants('dev', contract('Read, mcp__codegraph__codegraph_explore', 'x'), knownMcpTools(root));
    expect(f).toHaveLength(1);
    expect(f[0]?.reason).toBe('unknown-server');
    fs.rmSync(root, { recursive: true, force: true });
  });

  it('rejects a tool the server does not publish', () => {
    const root = sandbox(cfg, 'harness-kit');
    const g = 'Read, mcp__plugin_harness-kit_codegraph__codegraph_callers';
    const f = auditMcpGrants('dev', contract(g, 'x'), knownMcpTools(root));
    expect(f[0]?.reason).toBe('unknown-tool');
    fs.rmSync(root, { recursive: true, force: true });
  });

  it('rejects the short tool name, which omits the server prefix inside it', () => {
    const root = sandbox(cfg, 'harness-kit');
    const f = auditMcpGrants('dev', contract('Read, mcp__plugin_harness-kit_codegraph__explore', 'x'), knownMcpTools(root));
    expect(f[0]?.reason).toBe('unknown-tool');
    fs.rmSync(root, { recursive: true, force: true });
  });

  it('accepts a server-level grant, which names no single tool', () => {
    const root = sandbox(cfg, 'harness-kit');
    const known = knownMcpTools(root);
    expect(auditMcpGrants('dev', contract('Read, mcp__plugin_harness-kit_codegraph', 'x'), known)).toEqual([]);
    expect(auditMcpGrants('dev', contract('Read, mcp__plugin_harness-kit_codegraph__*', 'x'), known)).toEqual([]);
    fs.rmSync(root, { recursive: true, force: true });
  });

  it('says nothing about the tools of a server that publishes no list', () => {
    // Silence beats a false accusation: an unknown tool set cannot disprove a name.
    const root = sandbox({ mcpServers: { other: {} } }, 'harness-kit');
    const known = knownMcpTools(root);
    expect(known.tools.size).toBe(0);
    expect(auditMcpGrants('dev', contract('Read, mcp__plugin_harness-kit_other__anything', 'x'), known)).toEqual([]);
    fs.rmSync(root, { recursive: true, force: true });
  });

  it('leaves non-MCP tools and an inheriting contract alone', () => {
    const root = sandbox(cfg, 'harness-kit');
    const known = knownMcpTools(root);
    expect(auditMcpGrants('dev', contract('Read, Write, Bash', 'x'), known)).toEqual([]);
    expect(auditMcpGrants('dev', contract(null, 'x'), known)).toEqual([]);
    fs.rmSync(root, { recursive: true, force: true });
  });

  it('is clean against this repo — every granted codegraph name resolves', () => {
    const repo = path.resolve(__dirname, '../..');
    expect(auditMcpDir(path.join(repo, 'agents'), repo)).toEqual([]);
  });
});
