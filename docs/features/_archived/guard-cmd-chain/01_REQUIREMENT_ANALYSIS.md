# 01 — Requirement Analysis · T-17 `guard-cmd-chain`

- Mode: **full** · Stage 1 (requirement-analyst) · Security task
- deferred-human mode: **defer, do not ask** — every ambiguity below is an Open Question
  carrying a labelled `Recommended:` answer (§9). Under Mode 2 (`.harness/rules/25-decision-policy.md`)
  these are red-line-5 (security-sensitive) calls that would normally escalate; deferred-human
  mode converts each into a recorded recommendation the PM/Architect adopts unless the operator
  overrides it at review.

> **Round 2 (2026-07-31) — surgical correction after gate review round 1.**
> The two findings `03_GATE_REVIEW.md` routed to the requirement-analyst are applied here; nothing
> else in this document moved.
>
> - **F-10** (gate §2.2) — AC-3's header read "exit 0 for every row", which contradicted **IS-2** for
>   row **L10**: L10 already BLOCKs pre-change (its lone `'` leaves `tokenize()` unbalanced,
>   `guard-rm.sh:114` → `parse_failed`), so exit 0 would be a BLOCK→ALLOW flip. The header now
>   excepts L10 and row L10 states BLOCK as its expected verdict. A security invariant outranks a
>   false-positive-budget header, and the resolution belongs in the criterion QA executes — not
>   buried in the design.
> - **F-11** (gate §5 Q3) — AC-4's corpus was sourced from the session transcript / `git log`,
>   neither of which is a file any agent can read, so the criterion was unverifiable. The corpus is
>   now bound to four enumerated in-repo artifact sets, and the test report must quote the source
>   artifact per corpus line. Folded in per gate **F-2**: AC-4's differential run is now stated as
>   the **proof obligation for IS-2**, which is *not* provable by inspection. AC-4's over-block
>   cross-reference is also corrected from OQ-4 (baseline pinning) to OQ-6a (over-block disposition)
>   — the original pointed at the wrong Open Question.
>
> All six Open Questions (§9) stand at their `Recommended:` answers, adopted by the PM and binding.
> Every other AC, IS-*, B-* and NFR-* is byte-unchanged from round 1.
>
> **Round 3 (2026-07-31) — surgical amendment after code review.** `05_CODE_REVIEW.md` §3 finding
> **A-1** (MAJOR) is applied to **NFR-1 only**: its +20 ms clause is recorded as **waived** by the PM
> under Mode 2 with the measured figures, the O(n²) root cause, the bounding facts, the satisfied
> second clause, and a recommended chunked-indexing follow-up. Nothing else in this document moved —
> the six Open Questions, AC-3 and AC-4 included.
>
> **Round 4 (2026-07-31) — one-sentence accuracy correction.** NFR-1's "Residual obligation"
> paragraph claimed a follow-up pool row *is opened* for chunked indexing. No such row exists; the
> claim is corrected to what is true — a **recommended, not-yet-scheduled** follow-up that the PM
> surfaces to the operator. The waiver text itself (WAIVED heading, measured table, root cause,
> bounding facts, decision basis) is byte-unchanged.

---

## 1. Goal

The destructive-command guard judges only the first token of each top-level pipe segment, so a
destructive verb reached through `&&`, `;`, `||`, `&`, a newline, a subshell/brace group, a
command substitution, or an argv-carrying intermediary such as `xargs` is never judged at all;
make the guard evaluate **every command position in a command line** under the existing
out-of-project-root rule, without changing what counts as a destructive verb.

---

## 2. Evidence — the reproduced bypass, confirmed by code reading

The stream reproduced five exit codes without performing any deletion. I have no Bash tool, so I
confirmed the mechanism by reading `.harness/scripts/guard-rm.sh` and its PowerShell twin.
**My code reading agrees with the reported table on all five rows; there is no contradiction.**

The two facts that produce every row:

- **F-A** — `tokenize()` splits on space and tab **only** (`.harness/scripts/guard-rm.sh:99-113`).
  `&&`, `||`, `;`, `&`, newline, `(`, `)`, `{`, `}` are therefore ordinary characters glued into
  whatever token they touch.
- **F-B** — `split_pipes()` splits on `|` only (`guard-rm.sh:133`), and `classify_segment()` takes
  the verb as `tokens[idx]` after an optional `sudo` prefix (`guard-rm.sh:213-224`); a segment whose
  verb is not in `destructive_verbs_ci` (`guard-rm.sh:83`) returns with no offending paths
  (`guard-rm.sh:272`), and the walker then exits 0 (`guard-rm.sh:321`).

| Reported row | Exit | Lines that produce it |
|---|---|---|
| `rm -rf <outside>` | 2 | verb `rm` matched at `guard-rm.sh:264-272`; path token resolved and found outside root at `:149-196`, `:293-297`; block emitted `:321-336` |
| `echo hi && rm -rf <outside>` | 0 | F-A → `&&` is a plain token; F-B → verb is `echo`; return at `:272`, exit 0 at `:321` |
| `true; rm -rf <outside>` | 0 | F-A → `;` glues into `true;`; F-B → verb is `true;`; return at `:272` |
| `ls \| xargs rm -rf <outside>` | 0 | `split_pipes` yields two segments (`:133`); segment 2's verb is `xargs`; return at `:272` |
| `rm -rf ./build` | 0 | verb `rm`, leaf resolves under `repo_root` (`:188-196`), no offending path, exit 0 at `:321` |

The PowerShell twin is structurally identical and carries the same gap:
`Get-Tokens` whitespace-only (`guard-rm.ps1:71-93`), `Split-Pipes` on `|` only (`:101-118`),
verb = `$tokens[$idx]` (`:194`), non-destructive early return (`:235`).

**This is a specification gap, not a coding slip.** `.harness/rules/75-safety-hook.md:36` states the
trigger as "first token after optional `sudo`" and the out-of-scope list (`:126-127`) names `mv`,
`cp` and redirection but never shell operator chaining — the behavior matches the written spec, so
the rule document and its template twin become false the moment this ships.

**Two further findings from the same read (both feed §9):**

- **E-1 — the documented bash override works by accident.** `guard-rm.sh:60` reads
  `HARNESS_ALLOW_OUTSIDE_RM` from the **hook process environment**, but `.harness/rules/75-safety-hook.md:66-72`
  documents writing it as a **command-text prefix** (`HARNESS_ALLOW_OUTSIDE_RM=1 rm -rf /tmp/x`).
  A command-text prefix reaches exit 0 only because `tokens[0]` is the assignment, so the verb is
  unrecognized (`:223`, `:272`) — the override branch never runs and **no audit line is emitted**.
  Any change that makes assignment prefixes transparent turns that documented form into a BLOCK.
  Not executable here; QA must capture the real verdicts.
- **E-2 — the guard is wired fail-closed and is live in this session.**
  `.claude/settings.local.json:22` wires `sh -c 'cd "$CLAUDE_PROJECT_DIR" 2>/dev/null && bash .harness/scripts/guard-rm.sh'`
  with no `|| exit 0`. A bash syntax error exits 2, which is byte-indistinguishable from a BLOCK
  verdict — a malformed guard blocks **every** Bash tool call for every downstream agent.

---

## 3. In-scope behaviors

**Terminology.** A **command position** is an offset in a command line at which a shell begins
parsing a new simple command. The guard's post-change claim is stated over command positions.

**IS-1 — Coverage claim (total).** The guard evaluates the destructive-verb rule at every command
position it can identify in one command line. The table below is **total**: row 19 states what
happens to every form not named in rows 1-18.

| # | Command-line form | Post-change guard behavior |
|---|---|---|
| 1 | Single simple command | Verb judged (unchanged) |
| 2 | `A ; B` · `A && B` · `A \|\| B` · `A & B` · newline- or CRLF-separated | Every position judged |
| 3 | `A \| B` · `A \|& B` | Every position judged (`\|` already; the `&` residue of `\|&` now too) |
| 4 | `( A ; B )` subshell · `{ A ; B ; }` brace group (any nesting depth ≤ 2) | Inner positions judged |
| 5 | `$( A )` and backtick command substitution | Inner positions judged |
| 6 | `<( A )` / `>( A )` process substitution | Inner positions judged |
| 7 | Leading `VAR=value` assignment prefixes | Transparent — the real verb is judged (see OQ-1 for the `HARNESS_ALLOW_OUTSIDE_RM=1` prefix) |
| 8 | `sudo [-E\|-H\|-u USER]` prefix | Transparent (unchanged) |
| 9 | Argv-carrier verb — minimum binding set: `xargs`, `env`, `nohup`, `nice`, `time`, `timeout`, `command`, `exec`, and `find … -exec` / `-execdir` | Every remaining token is a candidate command position; a destructive verb among them is judged. Never silently skipped |
| 10 | Nested interpreter carrying a command string: `pwsh -c` / `powershell -c` (existing), `bash -c` / `sh -c` (OQ-5) | Inner string re-parsed at depth+1; depth > 2 → BLOCK |
| 11 | Quoted literal text that merely **contains** a destructive verb | Not a command position → ALLOW (unchanged) |
| 12 | Here-document body (`<<WORD` / `<<-WORD` / `<<'WORD'` … terminator) | Body is data, not command positions → ALLOW. Unterminated body → BLOCK |
| 13 | Comment: `#` beginning a token outside quotes, to end of line | Not a command position → ALLOW |
| 14 | Redirection operators and targets (`> f`, `2>&1`, `>>`) | Not command positions; not judged (verb set unchanged — §4) |
| 15 | Indirection: `eval "$X"`, `$CMD`, aliases, shell functions, `./script.sh`, `bash script.sh` | **Not covered** — the guard reads literal command text only. Documented residual |
| 16 | Verb spelled path-qualified (`/bin/rm`) or escape-spelled (`\rm`) | **Not covered** — documented residual (OQ-3) |
| 17 | Relative path in a position preceded by a `cd` / `pushd` in the same line | Resolved against the guard's own cwd, not the simulated cwd — documented residual (OQ-2) |
| 18 | Unbalanced quotes · nesting past depth 2 · unterminated here-document · any structure the parser cannot resolve | **BLOCK** (fail-closed) |
| 19 | **Any form not listed above** | Judged as a command position wherever one can be identified; where structure cannot be resolved, row 18 applies. The guard never *removes* a position it judged before this change (IS-2) |

**IS-2 — Monotonicity invariant.** The set of command positions the post-change guard evaluates is a
**superset** of the set the pre-change guard evaluated. No command line that BLOCKs before this
change ALLOWs after it.

**IS-3 — Fail-closed preserved.** Every parse outcome the guard cannot resolve exits 2 with the
existing "could not parse" class of message. Any new failure mode introduced by the wider parse
blocks; none passes.

**IS-4 — No false-negative-by-quoting.** Separator recognition (`;`, `&&`, `||`, `&`, `|`, newline)
is quote-aware: a separator inside a single- or double-quoted region is not a separator. A
backslash-escaped quote inside a double-quoted region is a literal character, not a quote-state
toggle.

**IS-5 — Existing behavior preserved exactly.** In-project destructive commands ALLOW; the 17
existing `evals/guard-rm-cases.md` rows keep their verdicts; nested-pwsh re-tokenization with
bounded recursion (depth 2) works; the environment-variable override exits 0 before any parsing and
emits its audit line; the "no `.git/` ancestor → WARN + exit 0" branch (`guard-rm.sh:74-77`) is the
guard's one deliberate fail-open and stays unchanged.

**IS-6 — BLOCK message quality.** A block arising from a non-leading command position names the
offending path(s) and the same override instructions as today, so the transcript stays actionable.

**IS-7 — Regression driver extended.** `.harness/scripts/test-guard-rm.{sh,ps1}` and its fixture
`evals/guard-rm-cases.md` gain the bypass matrix (§6 AC-1) and the legitimate-form corpus (§6 AC-3)
in lockstep — every driver case has a fixture row and vice versa.

**IS-8 — Documentation truth restored.** `.harness/rules/75-safety-hook.md` and
`skills/harness-init/templates/common/.harness/rules/75-safety-hook.md.tmpl` are updated in lockstep
so that: the "first token after optional `sudo`" trigger description is replaced by the coverage
claim of IS-1; the out-of-scope list explicitly states that operator chaining **is** now covered;
and rows 15-17 of IS-1 are named as documented residual limitations.

**IS-9 — Cross-shell and template lockstep.** Both shells implement IS-1..IS-6 symmetrically, and the
repo copy stays byte-identical with the distributed template copy (sync-self Mapping 5,
`.harness/scripts/sync-self.sh:74-76`, whose **source** is `skills/harness-init/templates/common/`).

---

## 4. Out of scope (explicit non-goals)

1. **Widening the destructive verb set.** `mv`, `cp`, output redirection (`>`), `truncate`, `dd`,
   `git clean` stay out. This task fixes *reachability* of the existing set only.
2. **Verb-spelling normalization** — `/bin/rm`, `\rm` (IS-1 row 16). Disclosed, not fixed (OQ-3).
3. **cwd simulation across `cd`** (IS-1 row 17). Disclosed, not fixed (OQ-2).
4. **Indirection resolution** — `eval`, variable expansion, aliases, functions, invoked scripts
   (IS-1 row 15). Structurally out of reach for a text-only PreToolUse guard.
5. **A new `verify_all` check.** The gate's F.2 checks that the guard scripts exist and are wired,
   not what they do; it stays that way. Precedent: T-016 eliminated a defect class with the check
   count held at 32.
6. **The other two pool rows** — narrowing the gate's guard check, and re-pointing the four
   command-derivation flows. Untouched.
7. **`docs/proposals/frontier-gaps-2026-07.md`** — untracked operator backlog. Not edited, not cited
   as a requirement, not included in any commit.
8. **Reconciling the frozen PowerShell items** (the eight enumerated T-13 operator items and the
   deliberately unreconciled `test_init_ps_assertions` / README badges). This task **adds** its own
   PowerShell surface to that standing list and reconciles nothing already frozen.

---

## 5. Boundary conditions

| ID | Condition | Required behavior |
|---|---|---|
| B-1 | Empty stdin, or JSON without `tool_input.command` | Exit 0 (unchanged: `guard-rm.sh:23`, `:57`) |
| B-2 | Command longer than 8192 characters | Truncated as today (`guard-rm.sh:80`). If truncation leaves an unresolvable structure, BLOCK (B-4). The verdict for a >8192-character here-document write is captured and documented |
| B-3 | Empty position between separators (`a ;; b`, trailing `&&`, leading `;`) | No crash, no unhandled array read (`name=()` per insight 2026-05-16), verdict unchanged from the same line without the empty position |
| B-4 | Unbalanced single or double quotes | BLOCK (existing `guard-rm.sh:114`, `:316-319`) |
| B-5 | Nesting deeper than depth 2 (groups, substitutions, nested interpreters) | BLOCK with the parse-failure message (existing `guard-rm.sh:201`) |
| B-6 | No `.git/` ancestor of cwd | WARN to stderr, exit 0 — unchanged (`guard-rm.sh:74-77`) |
| B-7 | `HARNESS_ALLOW_OUTSIDE_RM=1` present in the hook process environment | Exit 0 with the audit line before any parsing — unchanged (`guard-rm.sh:60-63`) |
| B-8 | Separator characters inside quotes | Not separators (IS-4) |
| B-9 | Backslash-escaped quote inside a double-quoted region | Literal character, no quote-state toggle (IS-4) |
| B-10 | Newline / CRLF inside the command string | Newline is a separator; a `\r` does not become part of a verb or path token |
| B-11 | Multiple offending paths across several positions | All reported, de-duplication not required; exit 2 once |
| B-12 | Concurrent hook invocations (parallel Bash tool calls) | The guard stays stateless: no temp files, no shared writes, no lock |
| B-13 | A destructive verb appearing only inside a here-document body, a comment, or a quoted literal | ALLOW (IS-1 rows 11-13) |
| B-14 | String rewriting inside the guard or its driver | Uses the repo's literal-replacement helper, never bare `${var//needle/repl}` with a replacement that can contain `&` (bash 5.2 `patsub_replacement`, insight 2026-06-21) |

---

## 6. Acceptance criteria

Every criterion below is verified by a **captured exit code from a real run**, never by code reading.
`OUT` denotes a path outside the project root (e.g. `/etc/harness-guard-probe`); no deletion is
performed — the guard is fed JSON on stdin exactly as `test-guard-rm.sh` already does.

**AC-1 — Bypass matrix blocks (exit 2 for every row).**

| Row | Command fed to the guard |
|---|---|
| a | `rm -rf OUT` (control — already blocks) |
| b | `echo hi && rm -rf OUT` |
| c | `true; rm -rf OUT` |
| d | `false \|\| rm -rf OUT` |
| e | `sleep 0 & rm -rf OUT` |
| f | `echo hi` + newline + `rm -rf OUT` |
| g | `( cd /tmp && rm -rf OUT )` |
| h | `{ rm -rf OUT ; }` |
| i | `echo $(rm -rf OUT)` |
| j | `ls \| xargs rm -rf OUT` |
| k | `ls \| xargs -I {} rm -rf OUT` |
| l | `env FOO=1 rm -rf OUT` |
| m | `nohup rm -rf OUT` |
| n | `timeout 5 rm -rf OUT` |
| o | `find . -name '*.log' -exec rm -rf OUT ;` |
| p | `FOO=1 rm -rf OUT` |
| q | `echo hi \| head -1 && Remove-Item -Recurse C:\Windows` |
| r | `bash -c "rm -rf OUT"` (conditional on OQ-5) |

**AC-2 — Existing behavior preserved.** All 17 current `evals/guard-rm-cases.md` rows keep their
verdicts in a captured run of `.harness/scripts/test-guard-rm.sh`; the nested-pwsh case (row 8) and
the depth-2 recursion bound still hold; the environment-variable override (row 11) still exits 0
**and its audit line is captured from stderr**.

**AC-3 — Legitimate-form corpus (exit 0 for every row except L10, captured).** These are the false
positives the design tension is about.

**L10 is the single exception, and it is not a defect.** L10's expected verdict is **BLOCK (exit 2)**,
unchanged from pre-change. Its lone apostrophe leaves the existing `tokenize()` quote count unbalanced
(`guard-rm.sh:114` → `parse_failed`), so L10 BLOCKs today; making it exit 0 would be a BLOCK→ALLOW
flip, which **IS-2 forbids**. IS-2 outranks this criterion's false-positive budget. QA records L10 as
a **PASS when it exits 2**, and there is no reading of AC-3 under which L10 is expected to exit 0.
Every other row in the table below is exit 0.

| Row | Command | Why it must pass |
|---|---|---|
| L1 | `cd sub && rm -rf ./node_modules` | Chained in-project clean |
| L2 | `npm run build && rm -rf dist/tmp` | Build-then-clean chain |
| L3 | `rm -rf build && mkdir build` | Destructive verb leading, in-project |
| L4 | `git status; rm -rf .cache` | `;`-chained in-project clean |
| L5 | `test -d node_modules && rm -rf node_modules \|\| echo none` | Three-operator chain |
| L6 | `find . -name '*.pyc' -delete` | Existing row 10 |
| L7 | `echo "rm -rf OUT"` | Quoted literal is data |
| L8 | `grep -rn "rm -rf OUT" .` | Searching for the string |
| L9 | `cat > /tmp-in-repo/f <<'EOF'` … body containing `rm -rf OUT` … `EOF` | Agents write files this way; a block here cripples the toolchain |
| L10 | The same here-document with an apostrophe in the body | **Expected verdict: BLOCK (exit 2) — not exit 0.** The odd `'` unbalances `tokenize()` (`guard-rm.sh:114` → `parse_failed`), so this line BLOCKs pre-change; IS-2 forbids flipping it to ALLOW. Verdict captured; recorded as an accepted over-block per OQ-6a. One instance of a class, not a singleton — every pre-change parse failure survives the change |
| L11 | `printf '%s' '{"tool_input":{"command":"echo hi && rm -rf OUT"}}' \| bash .harness/scripts/guard-rm.sh` | **Load-bearing**: this is how the guard is tested. If it self-blocks, the suite cannot run |
| L12 | `bash .harness/scripts/test-guard-rm.sh` | Running the suite |
| L13 | `git commit -m "guard: block rm -rf outside root"` | Commit messages naming the verb |
| L14 | `HARNESS_ALLOW_OUTSIDE_RM=1 rm -rf OUT` | Documented override form (see OQ-1; verdict + audit line both captured) |

**AC-4 — Differential run: the proof of IS-2, and no new false positives beyond the enumerated set.**

**AC-4 is the proof obligation for IS-2.** Monotonicity is **not** provable by inspection: the
nested-interpreter path narrows a verb's token walk one level down, which flips
`pwsh -c "Remove-Item -Recurse ./tmp | Tee-Object C:\log"` from BLOCK to ALLOW (gate review F-2,
`03_GATE_REVIEW.md` §2.1). A captured differential run is therefore the only evidence accepted for
IS-2; code reading does not satisfy this criterion.

**Corpus — readable in-repo artifacts only.** The corpus is at least 40 distinct command lines, every
one harvested from a file in this repository. These are the permitted sources, and the only ones:

| # | Source artifact | What counts as a corpus line |
|---|---|---|
| S1 | `README.md`, `docs/getting-started.md`, `docs/dev-map.md` | Each command line inside a fenced code block |
| S2 | `docs/features/_archived/*/06_TEST_REPORT.md` and `docs/features/_archived/*/04_*.md` | Each `Command:` / invocation line, and each command line inside a fenced block |
| S3 | `.harness/scripts/hook-spec.sh` and `.harness/scripts/hook-spec.ps1` | Each emitted hook command byte-form |
| S4 | `AI-GUIDE.md` | Each `.harness/scripts/*` invocation line |

Session transcripts and `git log` are **not** corpus sources: Bash tool calls never enter git history
and no transcript is a file any agent can read, so a criterion sourced from either is unverifiable.

_Evidence the 40-line floor is reachable: S2 alone yields 269+ matching invocation lines across 46
archived stage docs (grep of `(bash|pwsh) …/.harness/scripts` and `.harness/scripts/*.{sh,ps1}`,
2026-07-31). S4 is low-yield — `AI-GUIDE.md:72-86` lists script **paths** in prose, so a line counts
from S4 only where it is written as a full invocation._

**Auditability.** The test report carries one row per corpus line, recording: the command line, its
**source artifact path**, the pre-change verdict, and the post-change verdict. A corpus line without
a quoted source artifact does not count toward the 40. This makes AC-4 checkable rather than trusted.

**Pass condition.** The pre-change guard and the post-change guard produce **identical** verdicts on
every corpus line. The AC-1 rows are the sole permitted difference, and they flip ALLOW→BLOCK. Any
ALLOW→BLOCK flip outside the AC-1 rows is fixed, or recorded in `.harness/rules/75-safety-hook.md` as
an accepted over-block with its rationale (OQ-6a). **Any BLOCK→ALLOW flip, on any line, at any
recursion depth, fails AC-4 and fails IS-2** — it is neither recordable nor waivable.

**AC-5 — Fail-closed.** Captured exit 2 for: unbalanced quote in a chained line; a group/substitution
nested past depth 2; an unterminated here-document. Captured exit 0 with the WARN line for the
no-`.git/`-ancestor case. No input in the AC-1 or fail-closed sets yields exit 0.

**AC-6 — Verb set unchanged.** A diff of the destructive verb list (`guard-rm.sh:83`,
`guard-rm.ps1:57-60`) shows no added or removed member. Captured exit 0 for `mv OUT .`, `cp x OUT`
and `echo hi > OUT` — still deliberately unguarded.

**AC-7 — Symmetry and lockstep.** Both shells carry the change; `.harness/scripts/sync-self` reports
no drift for the `guard-rm` pair; `.harness/rules/75-safety-hook.md` and its `.tmpl` twin carry the
same coverage claim (hand-maintained — `.harness/rules/` is not in sync-self's mirror set).

**AC-8 — Gate green, count frozen.** `.harness/scripts/verify_all.sh` PASSes with **32 checks**, no
check added, no check removed.

**AC-9 — Documentation truth.** No sentence remains in either rule copy that describes the trigger as
the first token; the residual limitations (IS-1 rows 15-17) are named; the failure-mode table covers
the new BLOCK causes.

**AC-10 — Driver anti-revert.** Deleting the new chaining logic from a scratch copy of the guard
turns the AC-1 rows red in `test-guard-rm.sh` (mutation proof that the new assertions are
load-bearing, per the T-11a precedent that presence-checks alone prove nothing).

**AC-11 — Live-guard continuity.** The repo copy of the guard is runnable and correct at every
intermediate state; `test-guard-rm.sh` is re-run and its tally captured after each edit; the final
tally is quoted from the run that produced it, never derived arithmetically (insight 2026-07-31).

**AC-12 — PowerShell debt recorded.** This task's PowerShell surface is appended to the standing
operator PS list (`[Parser]::ParseFile` over `guard-rm.ps1` + `test-guard-rm.ps1`, then a
`test-guard-rm.ps1` run), with no attempt to reconcile the frozen items.

---

## 7. Non-functional requirements

- **NFR-1 — Latency. Clause 1 WAIVED (round 3, 2026-07-31); clause 2 SATISFIED.** The guard runs
  before *every* Bash tool call.

  **As originally written (round 1, retained verbatim as the record):** "Post-change wall-clock on an
  8192-character worst-case command line is within +20 ms of the pre-change guard on the same host,
  both figures captured. If the measurement contradicts the 50 ms budget claimed in
  `.harness/rules/75-safety-hook.md:58-62` and its failure-mode row, the rule document is corrected
  to the measured truth. Profile before optimizing (insight 2026-06-09): no per-token subprocess
  spawn is added."

  **Clause 1 (+20 ms) is WAIVED. It was not met, and the delivered guard does not meet it.** Measured
  (`04_DEVELOPMENT.md` "NFR results", adjudicated in `05_CODE_REVIEW.md` §3 finding A-1 and §5.4):

  | Case | Pre-change | Post-change | Delta |
  |---|---|---|---|
  | 8192-character worst case | 1487 ms | **2251 ms** | **+764 ms** — the +20 ms clause missed by ~38× |
  | Typical command | 49 ms | 46 ms | −3 ms (faster) |
  | Typical redirecting command | 39 ms | 33 ms | −6 ms (faster) |

  **Root cause, profiled not guessed.** Bash `${s:$i:1}` is O(i), so one character pass over an
  n-character string is O(n²). The **pre-change** guard already made two such passes (`tokenize`,
  `split_pipes`); the change adds a third. 1487 × 1.5 ≈ 2251, so the measurement and the mechanism
  agree arithmetically. **Clause 1 was therefore infeasible as written for *any* added pass** — a
  requirement defect at least as much as a code defect, and this requirement document owns it.

  **Bounding facts that make the waiver safe** (all verified, not assumed): the command is truncated
  to 8192 characters before any parsing, so the worst case is bounded at ~2.3 s and cannot approach a
  hook timeout; the guard's *security* behaviour is unaffected by the cost; there is **no fail-open
  path** — every parse outcome the guard cannot resolve still exits 2 (IS-3); and the common path got
  *faster*, because the fork-free verb test removed ~20 `printf | tr` subprocess spawns per segment.
  The "no per-token subprocess spawn is added" sentence of the original clause holds; spawns were
  removed, not added.

  **Clause 2 (correct the rule document to the measured truth) is SATISFIED.** The never-true "under
  50 ms" claim is removed from both rule-document copies — `.harness/rules/75-safety-hook.md` and
  `skills/harness-init/templates/common/.harness/rules/75-safety-hook.md.tmpl` — and replaced with
  the measured figures. Verified by the code reviewer in both copies (`05_CODE_REVIEW.md` §3 A-1).

  **Residual obligation — recommended follow-up, not yet scheduled, and not work in this task.**
  **Chunked indexing** is recommended: read a 256-character window (`chunk="${s:$base:256}"`) and
  index inside the chunk, which cuts the constant by ~256× without changing the algorithm's shape.
  **No pool row and no task-board entry exist for it at the time of writing** — scheduling belongs to
  the operator, not to this task. The PM surfaces the recommendation in `07_DELIVERY.md` and in the
  return summary to the `/harness-stream` drain, which is the channel that can actually schedule it.
  It carries the developer's caveat, which is binding on any such follow-up: **any length cap
  introduced along the way must fail closed (BLOCK, not skip)**, or it becomes a trivial bypass.
  Rewriting the hot loop of a live, fail-closed pre-tool hook inside this task, to chase a worst case
  nobody has hit, was rejected as the worse risk.

  **Who decided, and on what basis.** The PM waived clause 1 under Mode 2
  (`.harness/rules/25-decision-policy.md`, `.harness/decision-rubric.md`), on the rubric lines
  *"profile before optimizing — fix the measured bottleneck, not the obvious-looking suspect"*,
  *"lightweight over heavy — the smallest thing that meets the bar"*, and *"honest reporting,
  always"*. Red lines were checked first and none applies: this is not a security-sensitive choice,
  because the guard's security behaviour is unchanged, the worst case is bounded, and no path fails
  open. The operator can spot-check this waiver against the measured table above and reverse it by
  reinstating clause 1 with a feasible number and scheduling the chunked-indexing follow-up into this
  task's scope.
- **NFR-2 — No new dependency.** No `realpath`, no `git` invocation, no new interpreter requirement;
  the existing python3-optional JSON path and its heuristic fallback stay intact.
- **NFR-3 — Live-guard safety.** A malformed guard exits 2 and blocks every Bash call (E-2). Edits
  therefore land through the Write/Edit tools, which the `matcher: Bash` PreToolUse hook does not
  govern — that is the repair path if the guard is ever left unrunnable. The change is sequenced so
  the guard is valid after every individual edit.
- **NFR-4 — Cross-shell parity.** PowerShell is not executable by agents here; the `.ps1` twin is
  green-by-symmetry only and carries the known agent-unexecutable-PS hazards (whole-file parse
  before execution; automatic-variable collisions; the bash quoting idiom not porting) — insight
  2026-06-21.
- **NFR-5 — Security posture.** The change may only narrow what passes. No configuration, no
  environment variable, and no committed file may weaken the guard; the per-call override stays the
  single, visible, audited escape hatch.

---

## 8. Related tasks

| Task | Why it matters here |
|---|---|
| **T-001 `ai-safety-guardrails`** — `docs/features/_archived/ai-safety-guardrails/` | Origin of the guard, the eval fixture and the 50 ms / leaf-only path contract this task must preserve |
| **T-14 `hook-truth-status`** — `docs/features/_archived/hook-truth-status/` | Surfaced this exact bypass out-of-band ("only inspects the first verb of each top-level PIPE segment"); also the source of the totality discipline applied to IS-1 |
| **T-13 `hook-truth-spec`** — `docs/features/hook-truth-spec/` | `hook-spec` declares `guard-rm` fail-CLOSED; owner of the standing operator PowerShell list this task appends to |
| **T-12 `resilient-hooks`** — `docs/features/_archived/resilient-hooks/` | Moved the dogfood hooks to the gitignored machine-local settings and kept guard-rm fail-closed; source of the bash 5.2 `patsub_replacement` hazard (B-14) |
| **T-016 `i18n-special-drift-guard`** — `docs/features/_archived/i18n-special-drift-guard/` | Precedent for eliminating a defect class with the check count held at 32 (AC-8) |
| **T-11a `entropy-watch`** — `docs/features/_archived/entropy-watch/` | Precedent that a presence-checking gate is load-bearing only against a missing artifact — hence AC-10 mutates the guard, not the gate array |

Glossary: `CONTEXT.md` supplies **Gate**, **Dogfood**, **Template overlay**, **Machine-local
settings**, **Hook wiring spec** as used above. This document coins one term worth pinning:
**command position** (IS-1). `.harness/rejected-decisions.md` contains no record touching the guard's
parsing scope; the nearest entry (`skills-git-guardrails-setup-pre-commit`) declines *adopting
upstream guard skills*, which does not bear on fixing this guard.

---

## 9. Open questions for the operator (each with a `Recommended:` answer)

**OQ-1 — What does a `HARNESS_ALLOW_OUTSIDE_RM=1` prefix written in the command text mean?**
Today it passes silently through the unknown-verb path with no audit line (E-2, E-1). Once
assignment prefixes become transparent (IS-1 row 7), the documented form would BLOCK.
(a) Special-case it: recognized in command text, exit 0 with the same audit line, all other
assignment prefixes transparent. (b) Drop the command-text form: only the process environment
counts, and the rule document is corrected. (c) Leave all assignment prefixes opaque — keeps
`FOO=1 rm -rf OUT` as an open bypass.
**Recommended: (a).** It preserves the documented UX, makes an override that is currently silent
*auditable*, and closes the `FOO=1` bypass. It weakens nothing relative to today, where the same
prefix already passes. (c) is unacceptable for a task whose whole point is closing this class.

**OQ-2 — Does the guard model `cd` when resolving relative paths in a chain?**
After this change `cd /tmp && rm -rf ./x` is *evaluated*, resolves `./x` against the guard's cwd,
and is judged in-project — an honest edge of the new coverage claim.
(a) Out of scope: document as a named residual limitation (IS-1 row 17) and queue a follow-up pool
row. (b) Simulate cwd for literal `cd` targets and block when the target is non-literal.
**Recommended: (a).** (b) opens a second axis (path resolution) inside a task scoped to
reachability, doubles the false-positive surface against AC-3 L1 (`cd sub && rm -rf ./node_modules`),
and does so in a task whose artifact must stay runnable at every step. Documenting an edge is
cheaper and more honest than shipping a half-modelled cwd.

**OQ-3 — Are `/bin/rm` and `\rm` in scope?**
Both bypass the guard today even when written on their own.
(a) Out of scope: disclose as IS-1 row 16 and queue a follow-up row. (b) Normalize the verb
(basename, strip one leading backslash) in this task.
**Recommended: (a).** The dispatch binds AC-5 "the destructive verb set is unchanged … this task
fixes reachability of the existing verb set, nothing more", and verb spelling is the recognition
axis, not the reachability axis. Disclosing it in the coverage claim is mandatory either way.

**OQ-4 — Should `test-guard-rm`'s assertion count be pinned in `.harness/scripts/baseline.json`?**
It is the only driver here that is not pinned, and `verify_all` only checks that `baseline.json`
exists (`verify_all.sh:743`) — pinning is a ledger, not a gate.
(a) Pin the bash key only (`test_guard_rm_bash_assertions`), leave the PS twin unpinned/unreconciled
with a note, add no check. (b) Leave unpinned. (c) Wire the driver into `verify_all` — forbidden by
AC-8.
**Recommended: (a).** The count is python3-independent (the interpreter affects only payload
encoding in `test-guard-rm.sh:40-57`), so the key needs no host qualifier — which avoids the
mis-derived-key trap of insight 2026-07-31. Pinning makes a silently shrinking security suite
visible to the next agent that reads the baseline, at the cost of one line and zero gate surface.
The PS key stays out until an operator run produces a real tally.

**OQ-5 — Are `bash -c` / `sh -c` inner command strings in scope?**
`pwsh -c` is already re-tokenized (`guard-rm.sh:228-241`); `bash -c "rm -rf OUT"` is the same
reachability class and passes today.
(a) In scope, reusing the existing depth-bounded recursion (AC-1 row r binds). (b) Out of scope,
documented as a residual.
**Recommended: (a).** It is the most obvious bypass a reader will try next, the mechanism already
exists and is bounded at depth 2, and leaving it open would make the coverage claim read as evasive.
This adds a reachability path, not a verb, so it stays inside AC-5.

**OQ-6 — What happens to an over-block discovered outside the AC-3 corpus?**
(a) Fix it if it is a form a developer would realistically type; otherwise record it in
`.harness/rules/75-safety-hook.md` as an accepted over-block with its rationale, and keep the
verdict. (b) Fix every over-block before shipping.
**Recommended: (a).** Fail-closed is the guard's stated posture, so an over-block is a usability
cost rather than a safety defect; (b) has no bounded end condition and would stall a security fix on
exotic inputs. The rule document's failure-mode table is the right home for the accepted cases.

---

## 10. Verdict

**READY.**

Six open questions are recorded; none is blocking. Each has a `Recommended:` answer that the
Architect adopts unless the operator overrides it at review — that is the standing deferred-human
resolution, and each recommendation has a safe default (disclose-and-defer, or fail-closed). No
`BLOCKED: NEEDS-HUMAN` marker is emitted: the operator authorized this task and its security scope
explicitly, and no recommendation weakens the guard relative to its current behavior.

Downstream, the Architect must treat IS-1 as the contract to design against (it is total by
construction — row 19 covers the unenumerated), AC-3/AC-4 as the false-positive budget, and NFR-3 as
a constraint on the *shape* of the change, not merely on its content.
