/**
 * Native test suite for the guard-rm TypeScript port.
 *
 * WHY THIS EXISTS SEPARATELY FROM tools/diff-guard-rm.sh: the differential is a
 * MIGRATION instrument. It proves the port matches guard-rm.sh, and it dies the day
 * that file is deleted. These tests are what remains — so a port must have them
 * before its shell twin can be removed, not after.
 *
 * Everything here drives `judge()` in-process. No subprocess, no chdir, no stdin.
 */

import { describe, expect, it } from 'vitest';
import * as path from 'node:path';
import {
  judge,
  tokenize,
  splitPipes,
  splitPositions,
  resolveLeaf,
  isDescendant,
  skipPrefix,
  extractCommand,
  hasScannerTrigger,
} from '../../src/guard-rm';

/** This repository is the cwd every case is judged from; its root is the guard's boundary. */
const REPO = path.resolve(__dirname, '../..');
/** A path that is outside REPO on any machine. */
const OUT = '/etc/harness-guard-probe';

const payloadFor = (command: string): string => JSON.stringify({ tool_input: { command } });

/** Judge a command from the repo root with no environment override. */
const verdict = (command: string) => judge(payloadFor(command), REPO, undefined);

const expectBlock = (command: string): void => {
  const v = verdict(command);
  expect(v.code, `expected BLOCK for: ${command}`).toBe(2);
  expect(v.stderr).toContain('BLOCKED');
};

const expectAllow = (command: string): void => {
  const v = verdict(command);
  expect(v.code, `expected ALLOW for: ${command}\n${v.stderr}`).toBe(0);
};

describe('destructive verb set', () => {
  // One case per member. A verb pinned by no test can be dropped silently — which is
  // exactly what an anti-vacuity run caught for `shred` against the 87-case corpus.
  const VERBS = ['rm', 'rmdir', 'unlink', 'Remove-Item', 'del', 'erase', 'Clear-RecycleBin', 'shred', 'srm'];

  it.each(VERBS)('blocks `%s` targeting a path outside the repo', (verb) => {
    expectBlock(`${verb} ${OUT}`);
  });

  it.each(VERBS)('allows `%s` targeting a path inside the repo', (verb) => {
    expectAllow(`${verb} build/artifact`);
  });

  it.each(['RM', 'rM', 'ReMoVe-ItEm', 'SHRED', 'CLEAR-RECYCLEBIN'])(
    'matches verb `%s` case-insensitively',
    (verb) => {
      expectBlock(`${verb} ${OUT}`);
    },
  );

  it('does not treat a non-verb as destructive', () => {
    expectAllow(`echo ${OUT}`);
    expectAllow(`cat ${OUT}`);
    expectAllow(`remover ${OUT}`);
  });
});

describe('path boundary', () => {
  it('blocks absolute paths outside the repo', () => {
    expectBlock('rm -rf /');
    expectBlock('rm -rf /etc');
    expectBlock('rm -rf /etc/foo');
  });

  it('allows paths inside the repo', () => {
    expectAllow('rm -rf build/');
    expectAllow('rm -rf node_modules');
    expectAllow('rm -rf ./docs/features');
  });

  it('blocks a relative path that escapes the repo', () => {
    expectBlock('rm -rf ../../../tmp');
  });

  it('expands ~ before deciding', () => {
    // Regression for the fail-open bug the stage-2 differential exposed: bash's
    // `${p#~/}` tilde-expanded the PATTERN, stripped nothing, and produced
    // `$HOME/~/rest`. That spurious segment absorbs a later `..`, so with a repo
    // root at $HOME an outside path could collapse to an inside one.
    const home = process.env['HOME'] || '/';
    expect(resolveLeaf('~/Desktop/foo', REPO)).toBe(`${home}/Desktop/foo`);
    expect(resolveLeaf('~', REPO)).toBe(home);
    expectBlock('rm -rf ~/Desktop/foo');
  });

  it('blocks Windows-style absolute paths', () => {
    expectBlock('Remove-Item -Recurse C:\\Windows');
  });
});

describe('every command position is judged', () => {
  it.each([
    ['and-chain', `echo hi && rm -rf ${OUT}`],
    ['semicolon', `true; rm -rf ${OUT}`],
    ['or-chain', `false || rm -rf ${OUT}`],
    ['background', `sleep 0 & rm -rf ${OUT}`],
    ['newline', `echo hi\nrm -rf ${OUT}`],
    ['crlf', `echo hi\r\nrm -rf ${OUT}`],
    ['subshell', `( cd /tmp && rm -rf ${OUT} )`],
    ['brace group', `{ rm -rf ${OUT} ; }`],
    ['command substitution', `echo $(rm -rf ${OUT})`],
    ['backtick', `echo \`rm -rf ${OUT}\``],
    ['process substitution', `diff <(rm -rf ${OUT}) b`],
    ['pipe', `ls | rm -rf ${OUT}`],
  ])('blocks through %s', (_label, cmd) => {
    expectBlock(cmd);
  });
});

describe('argv carriers and nested interpreters', () => {
  it.each(['xargs', 'env', 'nohup', 'nice', 'time', 'timeout', 'command', 'exec'])(
    'blocks through carrier `%s`',
    (carrier) => {
      expectBlock(`${carrier} rm -rf ${OUT}`);
    },
  );

  it('blocks through xargs with an option', () => {
    expectBlock(`ls | xargs -I {} rm -rf ${OUT}`);
  });

  it('blocks through find -exec', () => {
    expectBlock(`find . -name '*.log' -exec rm -rf ${OUT} ;`);
  });

  it.each(['bash', 'sh', 'dash', 'zsh', 'ksh'])('blocks through nested `%s -c`', (shell) => {
    expectBlock(`${shell} -c "rm -rf ${OUT}"`);
  });

  it.each(['pwsh', 'powershell', 'PWSH'])('blocks through nested `%s -c`', (shell) => {
    expectBlock(`${shell} -c "Remove-Item -Recurse C:\\Windows"`);
  });

  it('blocks through an assignment prefix and sudo', () => {
    expectBlock(`FOO=1 rm -rf ${OUT}`);
    expectBlock(`sudo rm -rf ${OUT}`);
    expectBlock(`sudo -u root rm -rf ${OUT}`);
    expectBlock(`sudo -E -H rm -rf ${OUT}`);
  });
});

describe('find -delete', () => {
  it('blocks when the search root is outside', () => {
    expectBlock('find /etc -delete');
    expectBlock("find /tmp -name '*.log' -delete");
  });

  it('allows when the search root is inside', () => {
    expectAllow("find . -name '*.log' -delete");
  });

  it('allows find without -delete even outside', () => {
    expectAllow("find /etc -name '*.log'");
  });
});

describe('literal text is not a command position', () => {
  it.each([
    ['echoed string', `echo "rm -rf ${OUT}"`],
    ['grep pattern', `grep -rn "rm -rf ${OUT}" .`],
    ['comment', `# rm -rf ${OUT}`],
    ['heredoc body', `cat > ./probe.txt <<'EOF'\nrm -rf ${OUT}\nEOF`],
  ])('allows %s', (_label, cmd) => {
    expectAllow(cmd);
  });
});

describe('overrides', () => {
  it('honours the environment variable', () => {
    const v = judge(payloadFor(`rm -rf ${OUT}`), REPO, '1');
    expect(v.code).toBe(0);
    expect(v.stderr).toContain('override active');
  });

  it('honours a leading command-text prefix', () => {
    const v = verdict(`HARNESS_ALLOW_OUTSIDE_RM=1 rm -rf ${OUT}`);
    expect(v.code).toBe(0);
    expect(v.stderr).toContain('override active');
  });

  it('does NOT let a non-leading prefix self-authorize', () => {
    // Re-applying the prefix per position would make this allow itself.
    expectBlock(`echo x && HARNESS_ALLOW_OUTSIDE_RM=1 rm -rf ${OUT}`);
  });

  it('requires the value to be exactly 1', () => {
    expectBlock(`HARNESS_ALLOW_OUTSIDE_RM=0 rm -rf ${OUT}`);
    expectBlock(`HARNESS_ALLOW_OUTSIDE_RM=11 rm -rf ${OUT}`);
  });
});

describe('fail-closed on unresolvable structure', () => {
  it('blocks on an unbalanced quote', () => {
    const v = verdict("rm -rf 'a");
    expect(v.code).toBe(2);
    expect(v.stderr).toContain('could not parse');
  });

  it('blocks on an unterminated here-document', () => {
    const v = verdict(`cat > f <<'EOF'\nrm -rf ${OUT}`);
    expect(v.code).toBe(2);
    expect(v.stderr).toContain('could not parse');
  });

  it('blocks past the nesting depth bound', () => {
    const v = verdict('$( $( $( rm -rf /etc/x ) ) )');
    expect(v.code).toBe(2);
    expect(v.stderr).toContain('could not parse');
  });
});

describe('input handling', () => {
  it('allows an empty payload', () => {
    expect(judge('', REPO, undefined).code).toBe(0);
  });

  it('allows a payload with no command', () => {
    expect(judge(JSON.stringify({ tool_input: {} }), REPO, undefined).code).toBe(0);
  });

  it('extracts the command from well-formed JSON', () => {
    expect(extractCommand(payloadFor('rm -rf /etc'))).toBe('rm -rf /etc');
  });

  it('falls back to the heuristic on malformed JSON', () => {
    expect(extractCommand('{"tool_input":{"command":"rm -rf /etc"}')).toBe('rm -rf /etc');
  });

  it('unescapes whitespace and quotes in the heuristic path', () => {
    expect(extractCommand('{"command":"echo \\"a\\"\\nrm -rf /etc"}')).toBe('echo "a"\nrm -rf /etc');
  });

  it('reports the offending path and the repo root in the block message', () => {
    const v = verdict('rm -rf /etc/passwd');
    expect(v.stderr).toContain('    - /etc/passwd (outside ');
    expect(v.stderr).toContain(REPO);
    expect(v.stderr).toContain('HARNESS_ALLOW_OUTSIDE_RM=1 set for that single call.');
  });
});

describe('lexer units', () => {
  it('tokenize drops quotes and splits on unquoted whitespace', () => {
    expect(tokenize('rm -rf "a b" c')).toEqual(['rm', '-rf', 'a b', 'c']);
    expect(tokenize("echo 'x  y'")).toEqual(['echo', 'x  y']);
    expect(tokenize('')).toEqual([]);
  });

  it('tokenize yields an empty token for empty quotes', () => {
    expect(tokenize("a ''")).toEqual(['a', '']);
  });

  it('tokenize returns null on an unbalanced quote', () => {
    expect(tokenize("rm 'a")).toBeNull();
    expect(tokenize('rm "a')).toBeNull();
  });

  it('splitPipes ignores pipes inside quotes and keeps quote characters', () => {
    expect(splitPipes('a | b')).toEqual(['a', 'b']);
    expect(splitPipes('echo "a | b"')).toEqual(['echo "a | b"']);
  });

  it('splitPositions finds each separator-delimited position', () => {
    expect(splitPositions('a && b')).toEqual(['a', 'b']);
    expect(splitPositions('a; b')).toEqual(['a', 'b']);
    expect(splitPositions('a\nb')).toEqual(['a', 'b']);
  });

  it('splitPositions treats a here-document body as data', () => {
    expect(splitPositions("cat <<'EOF'\nrm -rf /etc\nEOF")).toEqual(["cat <<'EOF'"]);
  });

  it('splitPositions returns null on unresolvable structure', () => {
    expect(splitPositions("echo 'a")).toBeNull();
    expect(splitPositions("cat <<'EOF'\nbody")).toBeNull();
  });

  it('splitPositions keeps an escaped redirect from swallowing a following &', () => {
    // Pinned by driver rows R4/R5: the sentinel must stay outside the domain of i-1.
    const got = splitPositions('echo a\\>& rm -rf /etc/x');
    expect(got).not.toBeNull();
    expect(got).toContain('rm -rf /etc/x');
  });

  it('hasScannerTrigger fires only on structural bytes', () => {
    expect(hasScannerTrigger('rm -rf /etc')).toBe(false);
    expect(hasScannerTrigger('a && b')).toBe(true);
    expect(hasScannerTrigger('a; b')).toBe(true);
  });

  it('skipPrefix advances past assignments, sudo and reserved words', () => {
    expect(skipPrefix(['FOO=1', 'rm'])).toBe(1);
    expect(skipPrefix(['FOO=1', 'BAR=2', 'rm'])).toBe(2);
    expect(skipPrefix(['sudo', '-u', 'root', 'rm'])).toBe(3);
    expect(skipPrefix(['then', 'rm'])).toBe(1);
    expect(skipPrefix(['rm'])).toBe(0);
    // `1FOO=x` is not a valid assignment name, so it is the verb position.
    expect(skipPrefix(['1FOO=x', 'rm'])).toBe(0);
  });

  it('resolveLeaf collapses . and .. without touching the filesystem', () => {
    expect(resolveLeaf('a/b/../c', '/repo')).toBe('/repo/a/c');
    expect(resolveLeaf('./a', '/repo')).toBe('/repo/a');
    expect(resolveLeaf('/a/../..', '/repo')).toBe('/');
    expect(resolveLeaf('/etc', '/repo')).toBe('/etc');
  });

  it('resolveLeaf strips one layer of surrounding quotes', () => {
    expect(resolveLeaf('"/etc"', '/repo')).toBe('/etc');
    expect(resolveLeaf("'/etc'", '/repo')).toBe('/etc');
  });

  it('isDescendant is true for self and children only', () => {
    expect(isDescendant('/repo', '/repo')).toBe(true);
    expect(isDescendant('/repo/a', '/repo')).toBe(true);
    expect(isDescendant('/repo/', '/repo')).toBe(true);
    expect(isDescendant('/repository', '/repo')).toBe(false);
    expect(isDescendant('/', '/repo')).toBe(false);
    expect(isDescendant('/etc', '/repo')).toBe(false);
  });
});
