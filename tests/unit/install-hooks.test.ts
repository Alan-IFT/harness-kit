/**
 * Native test suite for the install-hooks TypeScript port.
 *
 * Per constraint 5 of docs/proposals/v2-ts-migration.md: the differential in
 * tools/diff-install-hooks.sh dies with install-hooks.sh, so this is what remains.
 * These tests assert the CONTRACT (exit codes, the write/refuse decision, the bytes
 * that reach disk) rather than agreement with the shell twin.
 */

import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import * as fs from 'node:fs';
import * as os from 'node:os';
import * as path from 'node:path';
import { run, settingsHookState, buildSettingsBody } from '../../src/install-hooks';
import { TOOLS, EVENTS, matcherOf, semanticsOf, commandOf } from '../../src/hook-spec';

let sandbox = '';

const write = (rel: string, body: string): void => {
  const p = path.join(sandbox, rel);
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, body);
};

const read = (rel: string): string => fs.readFileSync(path.join(sandbox, rel), 'utf8');
const exists = (rel: string): boolean => fs.existsSync(path.join(sandbox, rel));

interface Run {
  code: number;
  out: string;
  err: string;
}

const invoke = (): Run => {
  const outLines: string[] = [];
  const errLines: string[] = [];
  const code = run(
    sandbox,
    (s) => outLines.push(s),
    (s) => errLines.push(s),
  );
  return { code, out: outLines.join('\n'), err: errLines.join('\n') };
};

beforeEach(() => {
  sandbox = fs.mkdtempSync(path.join(os.tmpdir(), 'install-hooks-test-'));
});

afterEach(() => {
  fs.rmSync(sandbox, { recursive: true, force: true });
});

describe('git repository requirement', () => {
  it('exits 1 and writes nothing when there is no .git/', () => {
    const r = invoke();
    expect(r.code).toBe(1);
    expect(r.err).toContain('Not a git repo');
    expect(exists('.git/hooks/pre-commit')).toBe(false);
    expect(exists('.claude/settings.local.json')).toBe(false);
  });
});

describe('committed settings probe', () => {
  beforeEach(() => fs.mkdirSync(path.join(sandbox, '.git'), { recursive: true }));

  it('exits 3 and installs NOTHING when the committed file does not parse', () => {
    write('.claude/settings.json', 'not json at all\n');
    const r = invoke();
    expect(r.code).toBe(3);
    // The only path on which even the pre-commit hook is skipped.
    expect(exists('.git/hooks/pre-commit')).toBe(false);
    expect(exists('.claude/settings.local.json')).toBe(false);
  });

  it('exits 3 on an empty committed file', () => {
    write('.claude/settings.json', '');
    expect(invoke().code).toBe(3);
  });

  it('exits 3 when the committed path is a directory', () => {
    fs.mkdirSync(path.join(sandbox, '.claude/settings.json'), { recursive: true });
    const r = invoke();
    expect(r.code).toBe(3);
    expect(r.err).toContain('not a regular file');
  });

  it('does not bootstrap when the committed file already declares hooks', () => {
    write('.claude/settings.json', '{ "hooks": { "Stop": [] } }\n');
    const r = invoke();
    expect(r.code).toBe(0);
    expect(r.out).toContain('no machine-local file created');
    expect(exists('.git/hooks/pre-commit')).toBe(true);
    expect(exists('.claude/settings.local.json')).toBe(false);
  });

  it('bootstraps when the committed hooks object is empty', () => {
    write('.claude/settings.json', '{ "hooks": {} }\n');
    expect(invoke().code).toBe(0);
    expect(exists('.claude/settings.local.json')).toBe(true);
  });

  it('bootstraps when there is no hooks key at all', () => {
    write('.claude/settings.json', '{ "model": "opus" }\n');
    expect(invoke().code).toBe(0);
    expect(exists('.claude/settings.local.json')).toBe(true);
  });

  it('anchors on the QUOTED key, so a prose mention does not count as wired', () => {
    write('.claude/settings.json', '{ "_comment": "this project wires hooks elsewhere" }\n');
    expect(invoke().code).toBe(0);
    expect(exists('.claude/settings.local.json')).toBe(true);
  });
});

describe('machine-local file is never overwritten', () => {
  beforeEach(() => fs.mkdirSync(path.join(sandbox, '.git'), { recursive: true }));

  it.each([
    ['the operator opt-out (empty hooks object)', '{ "hooks": {} }\n'],
    ['an unparseable local file', 'garbage\n'],
    ['a fully wired local file', '{ "hooks": { "Stop": [ {} ] } }\n'],
  ])('leaves %s byte-untouched', (_label, body) => {
    write('.claude/settings.local.json', body);
    const r = invoke();
    expect(r.code).toBe(0);
    expect(r.out).toContain('left byte-untouched');
    expect(read('.claude/settings.local.json')).toBe(body);
  });

  it('writes no backup file', () => {
    write('.claude/settings.local.json', '{ "hooks": {} }\n');
    invoke();
    const entries = fs.readdirSync(path.join(sandbox, '.claude'));
    expect(entries).toEqual(['settings.local.json']);
  });
});

describe('bootstrap output', () => {
  beforeEach(() => fs.mkdirSync(path.join(sandbox, '.git'), { recursive: true }));

  it('installs an executable pre-commit hook that runs the drift check', () => {
    invoke();
    const body = read('.git/hooks/pre-commit');
    expect(body).toContain('harness-sync.sh --check');
    expect(body).not.toContain('pwsh');
    expect(fs.statSync(path.join(sandbox, '.git/hooks/pre-commit')).mode & 0o111).toBeTruthy();
  });

  it('overwrites a stale pre-commit hook', () => {
    write('.git/hooks/pre-commit', '#!/bin/sh\necho stale\n');
    invoke();
    expect(read('.git/hooks/pre-commit')).not.toContain('echo stale');
  });

  it('writes every tool from the spec, with no leftover temp file', () => {
    expect(invoke().code).toBe(0);
    const body = read('.claude/settings.local.json');
    for (const tool of TOOLS) {
      expect(body, `event for ${tool}`).toContain(`"${EVENTS[tool]}": [`);
      expect(body, `command for ${tool}`).toContain(commandOf(tool));
    }
    expect(fs.readdirSync(path.join(sandbox, '.claude')).filter((f) => f.includes('.tmp-'))).toEqual([]);
  });

  it('carries the fail-closed guard event and matcher literally', () => {
    invoke();
    const body = read('.claude/settings.local.json');
    expect(body).toContain('"PreToolUse"');
    expect(body).toContain('"matcher": "Bash"');
    expect(semanticsOf('guard-rm')).toBe('fail-closed');
  });

  it('emits no matcher key for the three matcher-less events', () => {
    invoke();
    const body = read('.claude/settings.local.json');
    // `none` is the spec's sentinel and must never reach the file as a literal.
    expect(body).not.toContain('"matcher": "none"');
    expect((body.match(/"matcher":/g) ?? []).length).toBe(1);
  });

  it('produces parseable JSON declaring exactly the four events', () => {
    invoke();
    const parsed = JSON.parse(read('.claude/settings.local.json')) as { hooks: Record<string, unknown> };
    expect(Object.keys(parsed.hooks).sort()).toEqual(
      TOOLS.map((t) => EVENTS[t]).sort(),
    );
  });

  it('reports each wired hook with its semantics', () => {
    const r = invoke();
    expect(r.out).toContain('Wired 4 lifecycle hooks');
    for (const tool of TOOLS) {
      expect(r.out).toContain(tool);
      expect(r.out).toContain(semanticsOf(tool));
    }
  });
});

describe('settingsHookState', () => {
  beforeEach(() => fs.mkdirSync(path.join(sandbox, '.claude'), { recursive: true }));
  const at = (rel: string): string => path.join(sandbox, rel);

  it('reports absent for a path with nothing at it', () => {
    expect(settingsHookState(at('.claude/nope.json'))).toBe('absent');
  });

  it('reports present for a directory', () => {
    fs.mkdirSync(at('.claude/dir.json'));
    expect(settingsHookState(at('.claude/dir.json'))).toBe('present');
  });

  it.each([
    ['empty file', '', 'unparseable'],
    ['whitespace only', '   \n\t ', 'unparseable'],
    ['not an object', 'null', 'unparseable'],
    ['no hooks key', '{ "a": 1 }', 'empty'],
    ['hooks not followed by colon', '{ "hooks" 1 }', 'empty'],
    ['hooks colon not followed by brace', '{ "hooks": [] }', 'unparseable'],
    ['empty hooks object', '{ "hooks": {} }', 'empty'],
    ['non-empty hooks object', '{ "hooks": { "Stop": [] } }', 'present'],
  ])('classifies %s as %s', (_label, body, expected) => {
    write('.claude/probe.json', body);
    expect(settingsHookState(at('.claude/probe.json'))).toBe(expected);
  });

  it('does not match an escaped key inside a string', () => {
    write('.claude/probe.json', '{ "_doc": "the \\"hooks\\": { block is documented here" }');
    expect(settingsHookState(at('.claude/probe.json'))).toBe('empty');
  });
});

describe('buildSettingsBody', () => {
  const wiring = TOOLS.map((tool) => ({
    tool,
    event: EVENTS[tool],
    matcher: matcherOf(tool),
    semantics: semanticsOf(tool),
    command: commandOf(tool),
  }));

  it('ends with exactly one trailing newline', () => {
    const body = buildSettingsBody(wiring);
    expect(body.endsWith('}\n')).toBe(true);
    expect(body.endsWith('}\n\n')).toBe(false);
  });

  it('interpolates commands verbatim, without re-quoting', () => {
    const body = buildSettingsBody(wiring);
    // The guard command carries a literal `\"` pair; it must survive untouched.
    expect(body).toContain(commandOf('guard-rm'));
  });

  it('separates events with commas except the last', () => {
    const body = buildSettingsBody(wiring);
    expect(body).toContain('    ],\n');
    expect(body).toContain('    ]\n  }\n}\n');
  });
});
