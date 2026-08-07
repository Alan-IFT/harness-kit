# guard-rm cases — acceptance B2 fixture

> Driven by `.harness/scripts/test-guard-rm.{ps1,sh}` (added v0.15.0). Each row is one
> simulated PreToolUse invocation: the input command is sent on stdin as the
> minimal `{"tool_input":{"command":"…"}}` JSON shape Claude Code emits, and
> the guard's exit code (0 = ALLOW, 2 = BLOCK) is compared against the
> expected verdict. Cwd for each case is the repo root (this repo).
>
> Since v0.46.0 both drivers take an optional guard path
> (`bash .harness/scripts/test-guard-rm.sh [guard-path]`,
> `pwsh -File .harness/scripts/test-guard-rm.ps1 -Guard <path>`) so a staged
> template copy or a scratch mutant can be driven **without** touching the live
> PreToolUse hook. This fixture and both drivers are maintained in lockstep:
> every driver case has a row here and vice versa (87 ↔ 87).

| # | Input command | Env | Expected verdict | Why |
|---|---|---|---|---|
| 1 | `rm -rf /` | — | BLOCK | `/` is outside any reasonable `$repoRoot`. |
| 2 | `rm -rf /etc` | — | BLOCK | `/etc` is outside repo. |
| 3 | `rm -rf ~/Desktop/foo` | — | BLOCK | `~` expands to a path outside the repo on every dev machine. |
| 4 | `rm -rf ../../../tmp` | — | BLOCK | `../../../tmp` from cwd resolves above the repo root. |
| 5 | `rm -rf build/` | — | ALLOW | Inside repo (in-project deletion is allowed by design). |
| 6 | `rm -rf node_modules` | — | ALLOW | Inside repo. |
| 7 | `Remove-Item -Recurse C:\Windows` | — | BLOCK | Absolute Windows path outside the repo. |
| 8 | `pwsh -c "Remove-Item -Recurse C:\Windows"` | — | BLOCK | Nested pwsh — inner command re-tokenized and same rule applies. |
| 9 | `find /etc -delete` | — | BLOCK | `find … -delete` is destructive; `/etc` is outside. |
| 10 | `find . -name '*.log' -delete` | — | ALLOW | `find . …` resolves under cwd (inside repo). |
| 11 | `rm -rf /etc/foo` | `HARNESS_ALLOW_OUTSIDE_RM=1` | ALLOW | Override env var bypasses the guard. |
| 12 | `Remove-Item -Path C:\Windows -Recurse` | — | BLOCK | Regression for D-1 (PS `-Path` named param previously matched find-predicate `-path` case-insensitively and skipped the path arg). |
| 13 | `rm -name /etc/passwd` | — | BLOCK | Regression for D-2 (find-predicate skip was applied to every verb, not just `find`). |
| 14 | `rm -path /etc -delete` | — | BLOCK | Combined verb+predicate confusion — even with both `-path` and `-delete` flags, `/etc` is still walked as a path token. |
| 15 | `rm -type f /etc/x` | — | BLOCK | Same root cause as D-2 — `-type` was in the find-predicate list and trick `f` into being skipped. |
| 16 | `rm -mtime +0 /etc/x` | — | BLOCK | Same root cause — `-mtime` skip used to consume `+0`, letting `/etc/x` slip past. |
| 17 | `find /tmp -name '*.log' -delete` | — | BLOCK | `find … -delete` outside repo — the `find`-vs-`rm` gating must still block `/tmp` paths under the `find` branch. |

## T-17 `guard-cmd-chain` (v0.46.0) — every command position is judged

`OUT` below is `/etc/harness-guard-probe`, a path outside the repo. No deletion is
performed: the guard is fed JSON on stdin exactly as rows 1-17 are.

### AC-1 — bypass matrix (each row reached a destructive verb the old guard never judged)

| # | Input command | Env | Expected verdict | Why |
|---|---|---|---|---|
| a | `rm -rf OUT` | — | BLOCK | Control — already blocked before this change. |
| b | `echo hi && rm -rf OUT` | — | BLOCK | `&&` chain — the old guard judged only `echo`. |
| c | `true; rm -rf OUT` | — | BLOCK | `;` chain. |
| d | `false \|\| rm -rf OUT` | — | BLOCK | `\|\|` chain. Also the row that the old `id\|cmd\|…` driver encoding could not express. |
| e | `sleep 0 & rm -rf OUT` | — | BLOCK | Background `&` separator. |
| f | `echo hi` + LF + `rm -rf OUT` | — | BLOCK | Newline separator. |
| f2 | `echo hi` + CRLF + `rm -rf OUT` | — | BLOCK | CRLF separator (B-10). |
| g | `( cd /tmp && rm -rf OUT )` | — | BLOCK | Subshell group. |
| h | `{ rm -rf OUT ; }` | — | BLOCK | Brace group. |
| i | `echo $(rm -rf OUT)` | — | BLOCK | Command substitution. **Driver rows for this case must be single-quoted** — a double-quoted array element would run the deletion when the array is defined. |
| j | `ls \| xargs rm -rf OUT` | — | BLOCK | Argv carrier `xargs`. |
| k | `ls \| xargs -I {} rm -rf OUT` | — | BLOCK | Carrier with an option that contains `{}` (must not open a brace group). |
| l | `env FOO=1 rm -rf OUT` | — | BLOCK | Carrier `env`. |
| m | `nohup rm -rf OUT` | — | BLOCK | Carrier `nohup`. |
| n | `timeout 5 rm -rf OUT` | — | BLOCK | Carrier `timeout`. |
| o | `find . -name '*.log' -exec rm -rf OUT ;` | — | BLOCK | `find` runs the carrier scan FIRST (no return), then its byte-unchanged `-delete` branch. |
| p | `FOO=1 rm -rf OUT` | — | BLOCK | Assignment prefix is transparent. |
| q | `echo hi \| head -1 && Remove-Item -Recurse C:\Windows` | — | BLOCK | Pipe + `&&` mixed; Windows verb in the last position. |
| r | `bash -c "rm -rf OUT"` | — | BLOCK | Nested POSIX-shell interpreter (OQ-5a). |

### AC-3 — legitimate-form corpus (exit 0 for every row **except L10**)

| # | Input command | Env | Expected verdict | Why |
|---|---|---|---|---|
| L1 | `cd sub && rm -rf ./node_modules` | — | ALLOW | Chained in-project clean. `cd` is deliberately not modelled (OQ-2a). |
| L2 | `npm run build && rm -rf dist/tmp` | — | ALLOW | Build-then-clean chain. |
| L3 | `rm -rf build && mkdir build` | — | ALLOW | Destructive verb leading, in-project. |
| L4 | `git status; rm -rf .cache` | — | ALLOW | `;`-chained in-project clean. |
| L5 | `test -d node_modules && rm -rf node_modules \|\| echo none` | — | ALLOW | Three-operator chain. |
| L6 | `find . -name '*.pyc' -delete` | — | ALLOW | Carrier scan finds nothing; `-delete` branch resolves under cwd. |
| L7 | `echo "rm -rf OUT"` | — | ALLOW | Quoted literal is data, not a command position. |
| L8 | `grep -rn "rm -rf OUT" .` | — | ALLOW | Searching for the string. The carrier/verb test keys on the VERB position, not on token presence. |
| L9 | `cat > ./guard-probe.txt <<'EOF'` … body containing `rm -rf OUT` … `EOF` | — | ALLOW | Agents write files this way; a block here would cripple the toolchain. The scanner emits no position from here-doc body text. |
| L10 | The same here-document with an apostrophe in the body | — | **BLOCK** | **Not a defect and not a singleton.** The body's lone `'` leaves the byte-unchanged `tokenize()` unbalanced, so this line ALREADY blocks; flipping it to ALLOW would violate the monotonicity invariant (IS-2). One instance of the accepted over-block class recorded in `.harness/rules/75-safety-hook.md`. |
| L11 | `printf %s '{"tool_input":…}' \| bash .harness/scripts/guard-rm.sh` | — | ALLOW | **Load-bearing**: this is how the guard is tested. If it self-blocked, the suite could not run. |
| L12 | `bash .harness/scripts/test-guard-rm.sh` | — | ALLOW | Running the suite. |
| L13 | `git commit -m "guard: block rm -rf outside root"` | — | ALLOW | Commit messages naming the verb. |
| L14 | `HARNESS_ALLOW_OUTSIDE_RM=1 rm -rf OUT` | — | ALLOW | Documented command-text override form. Now exits 0 **with the audit line** (before this change it exited 0 silently through the unknown-verb path). |

### AC-5 fail-closed · AC-6 verb set unchanged

| # | Input command | Env | Expected verdict | Why |
|---|---|---|---|---|
| F1 | `echo hi && rm -rf "OUT` | — | BLOCK | Unbalanced quote in a chained line. |
| F2 | `echo "$(basename "$(dirname "$(pwd)")")"` | — | BLOCK | Nesting past depth 2 (B-5). |
| F3 | `cat <<EOF` + LF + `rm -rf OUT` (no terminator) | — | BLOCK | Unterminated here-document. |
| V1 | `mv OUT .` | — | ALLOW | `mv` is deliberately **not** a destructive verb (out of scope). |
| V2 | `cp x OUT` | — | ALLOW | `cp` likewise. |
| V3 | `echo hi > OUT` | — | ALLOW | Output redirection likewise. |

### Gate conditions C-10 … C-14, prefix strip, override shape, boundaries

| # | Input command | Env | Expected verdict | Why |
|---|---|---|---|---|
| C10a | `` echo `rm -rf OUT` `` | — | BLOCK | C-10: a backtick at NORMAL with an empty stack **pushes** a frame. Appending would be a false negative. |
| C10b | `cat <(rm -rf OUT)` | — | BLOCK | Process substitution. |
| C11a | `echo $((1 << 3))` | — | ALLOW | C-11: arithmetic interiors are verbatim-until-closer — `<<` must NOT be read as a here-doc there. |
| C11b | `echo "${HOME}"` | — | ALLOW | C-11: parameter-expansion interiors are verbatim-until-closer; the `}` must close the frame. |
| C12cr | `echo hi` + CR + `rm -rf OUT` | — | BLOCK | C-12: a bare CR is a scanner trigger and a separator in its own right. |
| C12tee | `tee >(rm -rf OUT)` | — | BLOCK | C-12: `>(` output process substitution. |
| C14 | `rm -rf ./build \| tee /tmp/x.log` | — | BLOCK | **Pre-declared, deliberate over-block.** The union contains the input string itself at every depth (invariant C-1), so `rm`'s token walk crosses the `\|` and reaches `/tmp/x.log`. Pinned by this row so a future "fix" cannot silently re-open the monotonicity regression. |
| P1 | `A=1 rm -rf OUT` | — | BLOCK | One-letter assignment prefix. |
| P2 | `A+=1 rm -rf OUT` | — | BLOCK | C-13: `NAME+=value` is also an assignment prefix. |
| P3 | `sudo rm -rf OUT` | — | BLOCK | The `sudo` strip moved into `_skip_prefix` unchanged. |
| P4 | `sudo -u root rm -rf OUT` | — | BLOCK | `sudo -u USER` two-token skip. |
| P5 | `for f in x; do rm -rf OUT; done` | — | BLOCK | Shell reserved words are stripped, so `do rm …` is judged. |
| O1 | `echo x && HARNESS_ALLOW_OUTSIDE_RM=1 rm -rf OUT` | — | BLOCK | The override is **not** self-authorizing mid-chain: only a leading prefix on the whole line counts. |
| O2 | `env HARNESS_ALLOW_OUTSIDE_RM=1 rm -rf OUT` | — | BLOCK | Line starts with `env`, so no override; `env` is a carrier. |
| O3 | `bash -c "HARNESS_ALLOW_OUTSIDE_RM=1 rm -rf OUT"` | — | BLOCK | The prefix inside a nested interpreter string is an ordinary assignment. |
| N1 | `ls \| xargs grep rm` | — | ALLOW | Carrier scan dispatches at `rm` and finds no path token. |
| N2 | `echo hi ; ; rm -rf ./build` | — | ALLOW | Empty position between separators (B-3): no crash, verdict unchanged. |
| N3 | `rm -rf ./build &&` | — | ALLOW | Trailing separator (B-3). |
| N4 | `timeout 5 env FOO=1 nice -n 10 make` | — | ALLOW | Stacked carriers do not consume recursion depth. |
| Q1 | `echo $'it\'s fine'` | — | BLOCK | ANSI-C quoting. The `sq_ansi` flag keeps the **scanner** in step with bash, but the retained pre-change `tokenize()` still counts every `'`, so an odd apostrophe parity blocks exactly as it did before this change. |
| Q2 | `echo $'its fine' && rm -rf OUT` | — | BLOCK | Even apostrophe parity: the `&&` position is judged and the outside path is caught. |
| W1 | `echo \"a ; b\"` | — | BLOCK | **Accepted over-block.** A backslash-escaped quote pair that SPANS a top-level separator yields a scanner position with odd quote parity, which the byte-unchanged `tokenize()` rejects. |
| W2 | `echo "a ; b"` | — | ALLOW | Boundary for W1: the same text with real quotes. |
| W3 | `echo \"a b\"` | — | ALLOW | Boundary for W1: the same escaped pair with no separator between them. |
| W4 | `sh -c 'cd \"$CLAUDE_PROJECT_DIR\" 2>/dev/null && bash .harness/scripts/guard-rm.sh'` | — | ALLOW | The live unix hook byte-form must not self-block. |
| R1 | `echo a\>& rm -rf OUT` | — | BLOCK | **Round-2 code-review finding A-3.** An *escaped* `\>` is text, so the `&` is a real separator and `rm -rf OUT` is a command position. Reading the raw byte at `i-1` (design §3.1 row 15) made this a false negative; row 12 now records where a redirection operator was actually appended. |
| R2 | `echo a\<& rm -rf OUT` | — | BLOCK | Same for `\<&`. |
| R3 | `echo a>& rm -rf OUT` | — | ALLOW | Boundary for R1/R2: a REAL `>&` dup-redirect — `rm` is the redirect target word, not a command — must not be flushed into a position. |
| H1 | `bash <<EOF` + LF + `rm -rf OUT` + LF + `EOF` | — | BLOCK | **Accepted over-block** (round-2 finding A-2): every non-option token of a shell interpreter is judged as a command string, and here that token is the here-document fragment. Direction is over-block; use the override. |
| R4 | `& rm -rf OUT` | — | BLOCK | **Round-3 code-review finding CR2-1.** A LEADING `&` sits at `i == 0`, where round 2's `redir_i` sentinel `-1` equalled `i - 1`, so the `&` was appended and the whole line became one position with the verb `&`. Pins boundary **B-3**: `rm -rf OUT` BLOCKs, so `& rm -rf OUT` must BLOCK too. The sentinel is now `-2`, outside the domain of `i - 1`. |
| R5 | `pwsh -c "& Remove-Item -Recurse C:\Windows"` | — | BLOCK | Same defect at depth 1 — the executable vector. `&` is PowerShell's *call operator*, and the guard recurses into `pwsh -c` strings, so the inner string's `&` is at `i == 0` of the recursed scan. This is row 8 plus one character. |

## Notes for the driver

- The driver MUST set cwd to the harness-kit repo root before each invocation
  (the guard walks `.git/` ancestors of cwd).
- The driver MUST clear `HARNESS_ALLOW_OUTSIDE_RM` from the environment
  between cases unless the row specifies it.
- Exit codes are the contract: 0 = allowed, 2 = blocked. The stderr message
  is informational; the driver does not assert on its exact content (those
  asserts would lock in formatting and slow down future tweaks).
- **Row quoting is a safety rule, not style.** Single-quote (bash `'…'` / PS
  `'…'`) or use `$'…'` for every row whose text contains `$`, a backtick or
  `$(`. A double-quoted bash array element or PS hashtable value containing
  `$(` is command-substituted **when the array is defined** — case `i`
  (`echo $(rm -rf OUT)`) would really run the deletion on the developer's
  machine. The bash driver stores rows as flat 4-tuples iterated in strides of
  four, with **no delimiter**: the previous `id|cmd|override|expected` form
  truncated any command containing `|` (cases `d`, `q`, `L5`, `L11`) and fed
  the guard a different command than the row claimed.
- When reading a run, check that each new row's command **echoes back intact**
  in its PASS line — that is the detector for a truncated or pre-expanded row —
  and that the run ends with a `=== test-guard-rm summary ===` line. A missing
  summary line is a failure (a mid-suite truncation), not a pass.
