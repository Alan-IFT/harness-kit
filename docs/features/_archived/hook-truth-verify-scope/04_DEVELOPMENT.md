# 04 — Development Record — T-15 `hook-truth-verify-scope` (mode `full`)

- Upstream: `01` **READY** (assessment PROCEED) · `02` round 2 **READY** · `03` round 2 **APPROVED FOR DEVELOPMENT**
- Date: 2026-08-01 · deferred-human mode: defer, do not ask (no `AskUserQuestion` raised)
- **`verify_all` PASSED** — `PASS: 32 / WARN: 0 / FAIL: 0`, `exit=0`, pasted at S6 below.
- **Filename note (not a design change):** the design's ledger row **L8** names this file
  `04_IMPLEMENTATION.md`. The PM dispatched stage 4 with an explicit instruction to write
  `04_DEVELOPMENT.md` (the canonical stage-4 name in `agents/developer.md`). This document is that
  file; nothing else about L8 changed — it still carries every pasted run and the one new operator
  PowerShell item.

## Summary

`verify_all`'s `F.2` stopped being a two-source check (tracked repository content **plus** a settings
file selected at run time from machine state) and became a single-source check over tracked
repository content only, in both shells. The settings-file evidence-selection block and its three
wiring greps are deleted; the four guard-script presence tests and the two distributed-template
assertions remain, all at **FAIL** severity, all emitted through the one existing `step`/`Step` call
site — so the gate still records exactly 32 checks. The template's `PreToolUse` assertion is now
anchored to the JSON **key** form (unanchored it was vacuous), and the PowerShell twin was
restructured to the accumulate-then-throw idiom its bash twin already used. No guard script, settings
file, hook, `.gitignore` entry or pinned baseline count was touched.

## Files changed

| # | Path | What changed |
|---|---|---|
| L1 | `.harness/scripts/verify_all.sh` | `F.2` block replaced per design §3.1 — settings-file selection + 3 wiring greps deleted; B2 anchored to `"PreToolUse"[[:space:]]*:`; label and comment rewritten |
| L2 | `.harness/scripts/verify_all.ps1` | `F.2` block replaced per design §3.2 — same six facts, same token strings, plus accumulate-then-throw restructure (B-9) |
| L3 | `.harness/rules/40-locations.md:42` | the one live doc line naming a settings file as this check's subject |
| L4 | `AI-GUIDE.md:74` | `F.2 guard-rm wiring` → `F.2 guard-rm scripts + settings-template wiring` (the `32 checks` `G.4` literal on the same line survives — re-read below) |
| L5 | `CHANGELOG.md` | one `### Changed — hook-truth-verify-scope (T-15): …` block appended at the end of the existing `## [0.46.0]` section, immediately before `## [0.45.0]` |
| L6 | `CONTEXT.md` | one new glossary term, **Settings template**, inserted after **Machine-local settings** |
| L7 | `.harness/rejected-decisions.md` | one record appended, `## verify-gate-machine-hook-assertion` |
| L8 | `docs/features/hook-truth-verify-scope/04_DEVELOPMENT.md` | this file (new) |

No new file under `.harness/scripts/`, no new module, no new dependency, no new check.
`verify_all.{sh,ps1}` is not in `sync-self`'s mirror set and `.harness/rules/` is never synced, so
no `sync-self` run was required for L1–L7 (confirmed by `E.1` staying green across every run).

---

# Verification plan execution (design §11, S0 → S12)

Every tally below is pasted from the run that produced it. Nothing is re-derived arithmetically.

## S0 — pre-state (measured, not assumed)

```
$ git rev-parse HEAD
cb0ed57f5c390cbcbdc3c22c9c5e749125136204
```

`git status --porcelain` (full output, 37 modified + 9 untracked):

```
 M .claude-plugin/marketplace.json          M .harness/scripts/test-init.ps1
 M .claude-plugin/plugin.json               M .harness/scripts/test-init.sh
 M .harness/insight-index.md                M .harness/scripts/verify_all.ps1
 M .harness/rules/40-locations.md           M .harness/scripts/verify_all.sh
 M .harness/rules/75-safety-hook.md         M AI-GUIDE.md
 M .harness/scripts/baseline.json           M CHANGELOG.md
 M .harness/scripts/guard-rm.ps1            M CONTEXT.md
 M .harness/scripts/guard-rm.sh             M README.md
 M .harness/scripts/install-hooks.ps1       M README.zh-CN.md
 M .harness/scripts/install-hooks.sh        M docs/batches/default/BATCH_PLAN.md
 M .harness/scripts/sync-self.ps1           M docs/batches/default/STREAM_LOG.md
 M .harness/scripts/sync-self.sh            M docs/dev-map.md
 M .harness/scripts/test-guard-rm.ps1       M docs/features/_archived/insight-history.md
 M .harness/scripts/test-guard-rm.sh        M docs/features/_archived/resilient-hooks/04_IMPLEMENTATION.md
 M docs/features/_archived/resilient-hooks/06_QA_REPORT.md
 M docs/tasks.md                            M evals/guard-rm-cases.md
 M skills/harness-init/templates/common/.harness/rules/75-safety-hook.md.tmpl
 M skills/harness-init/templates/common/.harness/scripts/guard-rm.ps1
 M skills/harness-init/templates/common/.harness/scripts/guard-rm.sh
 M skills/harness-init/templates/common/.harness/scripts/install-hooks.ps1
 M skills/harness-init/templates/common/.harness/scripts/install-hooks.sh
 M skills/harness-status/SKILL.md
?? .harness/scripts/hook-spec.ps1            ?? docs/features/_archived/hook-truth-status/
?? .harness/scripts/hook-spec.sh             ?? docs/features/hook-truth-verify-scope/
?? docs/features/_archived/guard-cmd-chain/  ?? docs/proposals/frontier-gaps-2026-07.md
?? docs/features/_archived/hook-truth-spec/  ?? skills/…/common/.harness/scripts/hook-spec.ps1
                                             ?? skills/…/common/.harness/scripts/hook-spec.sh
```

(the two-column layout above is only line-economy in this document; the run's own output is one
name per line and every name is reproduced.)

**Process note (round 2, reviewer observation — recorded, no re-run).** `02` §11 S0 singles this one
paste out for **verbatim** treatment ("the *full* output, not a summary"), and reflowing it into two
columns is a *transformation* of that paste even though it is lossless: all 37 modified + 9 untracked
names are present, the disclosure above is explicit, and stage 5 independently reconstructed both
counts from the reflowed list and found them exact. It also sits in tension with this document's own
size justification ("no pasted run was shortened"). Raw one-name-per-line would have cost ~37 lines.
Noted for the record and for future stage-4 practice — a paste the design marks verbatim should be
pasted raw, not reflowed — not as a defect requiring re-measurement.

```
$ grep -n '"version"' .claude-plugin/plugin.json
4:  "version": "0.46.0",
$ head -12 CHANGELOG.md   (relevant lines)
## [0.46.0] - 2026-07-31
### Fixed — guard-cmd-chain (T-17): the destructive-command guard now judges every command position
$ wc -l .harness/rules/75-safety-hook.md
200 .harness/rules/75-safety-hook.md
$ grep -n '"verify_all_checks"' .harness/scripts/baseline.json
10:  "verify_all_checks": 32,
```

**Resolution of the HEAD-vs-version-files contradiction (condition C-5 / gate F-7b) — measured, NOT
reconciled.** The environment snapshot claimed `HEAD = cb0ed57 (v0.44.0)` with a **clean** status.
The measurement shows the HEAD is right and the **clean claim is wrong**: 37 tracked files are
modified and 9 paths are untracked. So `plugin.json = 0.46.0` and `CHANGELOG ## [0.46.0]` are
*uncommitted working-tree* facts belonging to the T-13/T-14/T-17 siblings, not to HEAD. There is no
contradiction to fix — R-7 is **load-bearing, not belt-and-braces**, and the S1 rsync overlay is what
makes the scratch tree measure the artifact under test rather than v0.44.0. Left exactly as found.

**Note (a) — the run-appended log is untracked (gate residual item 5).**

```
$ git ls-files --error-unmatch .harness/scripts/verification_history.log
error: pathspec '.harness/scripts/verification_history.log' did not match any file(s) known to git
Did you forget to 'git add'?
ls-files exit=1
```

Non-zero exit ⇒ never tracked ⇒ the repeated S6/S7/S8 runs cannot pollute the `git diff --name-only`
evidence S11/S12 depend on. Closed permanently.

**Developer baseline (not a design step).** One `bash .harness/scripts/verify_all.sh` on the live
tree *before* any edit: `PASS: 32 / WARN: 0 / FAIL: 0`, `exit=0` — the live machine has the
machine-local hooks installed, which is exactly why the defect is invisible here and fatal on a
clean checkout.

## S1 — scratch clean tree

```
$ git worktree add --detach .t15-clean HEAD
Preparing worktree (detached HEAD cb0ed57)
HEAD is now at cb0ed57 feat(v0.44.0): resilient lifecycle hooks + Windows repair-path fixes (T-12)
$ rsync -a --delete --exclude '.git' --exclude '.t15-clean' \
        --exclude '.claude/settings.local.json' ./ .t15-clean/     # exit 0
$ ls .t15-clean/.claude/ ;  ls -l .claude/settings.local.json
settings.json                                  # scratch: machine-local file ABSENT
-rw-rw-r-- 1 alan alan 2051 Jul 31 17:09 .claude/settings.local.json   # live: untouched
```

`rsync` was present, so the `tar | tar` fallback was not needed. **What this tree is** (design
§11 S1, round-2 correction): the current working tree, minus `.claude/settings.local.json`, laid over
HEAD's index — *not* a clean checkout. The git-driven checks inside it (`A.1`, `A.2`, `E.7`, `I.6`
via `git ls-files`) enumerate HEAD's file list, not the overlaid one. `F.2` reads none of its inputs
through git, so the stale index cannot move its verdict either way.

## S2 — AC-3, the pre-change measurement (run before any code was written)

```
=== verify_all (harness-engineering repo) ===

[A.1] No accidentally-committed env or secrets ... PASS
[A.2] 参考/ not tracked ... PASS
[B.1] README / LICENSE / CHANGELOG present ... PASS
[B.2] Install scripts present ... PASS
[C.1] All 17 skills present ... PASS
[C.2] Skill frontmatter sanity ... PASS
[D.1] Plugin agents present ... PASS
[D.2] Placeholders documented ... PASS
[D.3] AI-generated 50-*.md sanity (per-section sources, headings, no placeholders) ... PASS
[E.1] Layer 1: .harness/ matches templates/common/.harness/ ... PASS
[E.2] Layer 2: .claude/agents and .claude/skills synced from .harness/ ... PASS
[E.3] Rule sources present ... PASS
[E.4] Bootstrap files present and stubs reference AI-GUIDE.md ... PASS
[E.4b] AI-GUIDE.md indexes every .harness/rules/*.md (and vice versa) ... PASS
[E.5] Docs present ... PASS
[E.6] evals/golden-tasks.md present ... PASS
[E.7] No stale .harness/intervention.md tracked ... PASS
[F.1] Script pairs (.ps1 + .sh) present ... PASS
[F.2] Guard-rm scripts and PreToolUse wiring present ... FAIL
       .claude/settings.json:no_PreToolUse .claude/settings.json:no_Bash_matcher .claude/settings.json:no_guard-rm_command
[G.1] README references all 17 skills ... PASS
[H.1] Test fixtures present ... PASS
[G.2] CHANGELOG references all 17 skills ... PASS
[G.3] Version stamps consistent across plugin/marketplace/README ... PASS
[I.1] AI-GUIDE.md ≤200 lines ... PASS
[I.2] Rule fragments ≤200 lines each ... PASS
[I.3] Agent definitions ≤300 lines each ... PASS
[I.4] insight-index.md ≤30 evidence lines ... PASS
[I.5] docs/tasks.md ≤300 lines ... PASS
[I.7] Ignored INTERVENE supervision reports (WARN if >48h old on active task) ... PASS
[I.6] No retired-claim phrases in current docs/templates ... PASS
[J.1] settings.json schema integrity (.claude/ + template) ... PASS
[G.4] Doc count/version claims consistent with plugin.json + live check count ... PASS

=== Summary ===
  PASS: 31
  WARN: 0
  FAIL: 1
exit=2
```

The assertion under test held exactly as stated: `[F.2] … FAIL` with the three-token
`.claude/settings.json:…` detail, `exit=2`. **No non-`F.2` red appeared**, so the S2 discrepancy rule
had nothing to absorb — the stale-index concern did not materialise into a single red line.

## S3 — AC-10, never-installed half (health report §0, executed against the scratch tree)

Inputs read (read-only): `C1 = .t15-clean/.claude/settings.local.json` → `ls` reports
*No such file or directory*; `C2 = .t15-clean/.claude/settings.json` → parses, top-level keys
`['$schema','_comment','_hooks_moved','permissions','hooks']`, `hooks` is a dict with **0** keys.

Applying `skills/harness-status/SKILL.md` §0: Step 0.1 → C1 `absent`, C2 `empty`. Step 0.2 →
`UNKNOWN_FILES` empty. Step 0.3 → no candidate is `present`. Step 0.4 → `SOURCE = none`,
`SOURCE_KIND = none`, C1 state `absent` ⇒ `MACHINE_STATE = never-installed`. Step 0.5 line:

```
Hook source:  none — consulted .claude/settings.local.json (absent) and .claude/settings.json (empty)
```

§3b verdict — row 2 is the first match (`SOURCE = none` ∧ `never-installed`):

```
Safety hook:  NOT INSTALLED ON THIS MACHINE — no lifecycle hooks in .claude/settings.local.json (absent) or .claude/settings.json
```

no health point. The machine dimension is reported, distinctly, exactly where T-14 put it.

## S4 — dismantle (first)

```
$ git worktree remove --force .t15-clean   # exit 0
$ git worktree prune                       # exit 0
$ git status --porcelain | grep t15-clean  # exit 1 → no match
$ ls -d .t15-clean                         # No such file or directory
```

## S5 — implement L1–L7

Applied per §8. Every edited file was re-read after the edit. The two `G.4`-load-bearing literals on
edited lines survived:

```
$ sed -n '74p' AI-GUIDE.md
- `.harness/scripts/verify_all.{ps1,sh}` — total verification (32 checks, including I.1-I.5 doc-size
  WARN guards + F.2 guard-rm scripts + settings-template wiring + I.6 gap-tolerant retired-claim
  guard + I.7 ignored-INTERVENE-report guard + D.3 AI-generated 50-*.md sanity + J.1 settings.json
  schema integrity). **Must PASS before declaring done.**            ← single line in the file
$ sed -n '74p' AI-GUIDE.md | grep -c '32 checks'   → 1
$ sed -n '29p' .harness/rules/40-locations.md
`.harness/scripts/verify_all` checks (32 checks, all must PASS — count grows with releases):
```

**R2-4 honoured.** `.harness/rules/40-locations.md:41` ("Script pairs (.ps1 + .sh) for verify_all /
harness-sync / sync-self / test-init / test-real-project" — stale, names 5 of `F.1`'s 11 pairs) sits
immediately above the edit target and was **left exactly as it is**. Only `:42` moved in that file.
File length unchanged at 51 lines.

**R-2 mitigation.** `grep -c 'step "F.2"' .harness/scripts/verify_all.sh` → **2**, both inside the
one `if/else` (mutually exclusive branches) ⇒ one recorded step. The summary below prints `PASS: 32`,
which is the independent confirmation.

## S6 — AC-1, the live gate

```
[F.2] Guard-rm scripts and settings-template guard wiring present ... PASS
[G.4] Doc count/version claims consistent with plugin.json + live check count ... PASS

=== Summary ===
  PASS: 32
  WARN: 0
  FAIL: 0
exit=0
```

All 32 lines printed `PASS`; the full run is reproduced above at S2's shape with `F.2` green and the
new label. **`verify_all` PASSED.**

## S7 — AC-5 / AC-6 anti-vacuity, mutating the ARTIFACT

Four mutations, one at a time, each restored with a green re-run before the next. No other driver was
run while a mutation was active. **§11.1 was re-read first**: `.harness/scripts/guard-rm.sh` and
`.harness/scripts/guard-rm.ps1` (assertions A1/A2) were **never** renamed, moved, emptied or deleted
at any point — verified after M1 by `ls -l` showing both still present at their live sizes (37750 /
40565 bytes, mtime `Jul 31 23:55`, i.e. untouched since before this task began).

### M1 — falsifies the A1–A4 loop (template copy `guard-rm.sh` → `guard-rm.sh.t15bak`)

```
[E.1] Layer 1: .harness/ matches templates/common/.harness/ ... FAIL
      Run .harness/scripts/sync-self.sh
[F.2] Guard-rm scripts and settings-template guard wiring present ... FAIL
       missing:skills/harness-init/templates/common/.harness/scripts/guard-rm.sh

=== Summary ===
  PASS: 30
  WARN: 0
  FAIL: 2
exit=2
```

Matches the round-2 corrected expectation exactly: **two** FAILs, `PASS: 30 / WARN: 0 / FAIL: 2`,
`exit=2`. `sync-self.sh` was **not** run in write mode (hard rule 4). Restore by rename-back →
`PASS: 32 / WARN: 0 / FAIL: 0`, `exit=0`.

**Gate residual note (b) — the exhaustiveness derivation, pasted from `03_GATE_REVIEW.md` round 2 §1,
because `02` asserts the two-FAIL total without deriving it.** Every consumer of the mutated path:

> `sync-self.sh:74-76` is Mapping 5; `sync_file` (`:22-33`) records drift when
> `[[ -f "$dst" ]] && cmp -s "$src" "$dst"` fails, which a renamed-away **source** does; `--check`
> exits 1 (`:95-103`); `verify_all.sh:194-198` renders that as `[E.1] … FAIL`. I then enumerated
> every consumer of the mutated path to confirm the total is **exactly two**, which the design
> asserts but does not derive:
>
> - `F.2` (`verify_all.sh:293-294`) → FAIL
> - `E.1` (via Mapping 5) → FAIL
> - `F.1` (`:284`, PS `:270`) → green. Its pair list is `verify_all sync-self harness-sync test-init
>   test-real-project ambient-prompt ambient-reset upgrade-project language-policy entropy-cadence
>   hook-spec` — **`guard-rm` is absent**, *and* F.1 only ever tests `.harness/scripts/$pair.*`, never
>   a template path, so it could not fire on M1 even if `guard-rm` were listed.
> - `D.2` (`:88`) enumerates only `*.tmpl`/`*.append` → green
> - `I.6` (`:583-633`) enumerates `git ls-files` and skips a tracked-but-missing path at `:589`; the
>   `.t15bak` residue is untracked → green
> - `E.2`/`harness-sync` mirrors only `.harness/{agents,skills}` → green
> - `J.1` (`:657`) does not list it; `G.4` count unaffected → green
>
> ⇒ `PASS: 30 / WARN: 0 / FAIL: 2`, `exit=2` is right.

The run above is the measured confirmation of that derivation, check-for-check.

### M2 — falsifies B1 (`{{GUARD_COMMAND}}` → `XGUARD_COMMANDX` in the settings template)

```
[F.2] Guard-rm scripts and settings-template guard wiring present ... FAIL
       skills/harness-init/templates/common/.claude/settings.json.tmpl:no_GUARD_COMMAND_placeholder

=== Summary ===
  PASS: 31
  WARN: 0
  FAIL: 1
exit=2
```

Exactly one FAIL, one token; `D.2` stayed green (it rejects only *unknown* placeholders, never
requires presence). Restored by the reverse `sed`, verified **byte-identical** to a pre-mutation copy
by `cmp`; re-run → `PASS: 32 / WARN: 0 / FAIL: 0`, `exit=0`.

### M3 — falsifies B2 and proves R-1 closed (delete the `"PreToolUse": [ … ]` array, keep `_guard_hook`)

```
[F.2] Guard-rm scripts and settings-template guard wiring present ... FAIL
       skills/harness-init/templates/common/.claude/settings.json.tmpl:no_GUARD_COMMAND_placeholder skills/harness-init/templates/common/.claude/settings.json.tmpl:no_PreToolUse_block

=== Summary ===
  PASS: 31
  WARN: 0
  FAIL: 1
exit=2
```

`FAIL: 1` and `exit=2` match the design. **The detail does not** — see *Design drift / discrepancy 2*
below; the run is recorded as it ran and the expectation was not edited.

The doc string at `:5` was confirmed present throughout
(`"_guard_hook": "PreToolUse hook auto-runs guard-rm before every Bash tool call…`), which is what
makes this mutation the proof of R-1. Read-only cross-check against the **mutated** file:

```
$ grep -q 'PreToolUse' <tmpl>                       → exit 0   # the OLD unanchored test still PASSes
$ grep -qE '"PreToolUse"[[:space:]]*:' <tmpl>       → exit 1   # the NEW anchored test correctly FAILs
$ grep -n 'PreToolUse' <tmpl>
5:  "_guard_hook": "PreToolUse hook auto-runs guard-rm before every Bash tool ca…
```

B-8 was false in both shells before this change and is true now. Restored by re-inserting the array;
`cmp` against the pre-mutation copy → byte-identical; re-run → `32 / 0 / 0`, `exit=0`.

### M4 — falsifies B0 (`settings.json.tmpl` → `settings.json.tmpl.t15bak`)

```
[D.2] Placeholders documented ... PASS
[E.1] Layer 1: .harness/ matches templates/common/.harness/ ... PASS
[J.1] settings.json schema integrity (.claude/ + template) ... PASS
[F.2] Guard-rm scripts and settings-template guard wiring present ... FAIL
       missing:skills/harness-init/templates/common/.claude/settings.json.tmpl

=== Summary ===
  PASS: 31
  WARN: 0
  FAIL: 1
exit=2
```

Exactly one FAIL and — the load-bearing part — **exactly one token**, which is the evidence that B1
and B2 are correctly gated behind B0 (a missing template yields one token, not three). The asymmetry
with M1 held: `E.1` stayed **green**, confirming the template is not in the mirror set. `D.2` and
`J.1` also green, as the round-2 co-failure-freedom derivation predicted. Rename restored; `cmp`
byte-identical; no `.t15bak` residue anywhere (`ls … | grep -i t15bak` → exit 1).

**Final S7 green:** `PASS: 32 / WARN: 0 / FAIL: 0`, `exit=0`.

**AC-6.** Every one of the four mutation runs printed the status word `FAIL`. No run printed `WARN`
for `F.2` or for anything else — `WARN: 0` in all four summaries.

## S8 — AC-2 (scratch tree rebuilt by the identical construction, from the changed live tree)

```
=== verify_all (harness-engineering repo) ===

[A.1] No accidentally-committed env or secrets ... PASS
[A.2] 参考/ not tracked ... PASS
[B.1] README / LICENSE / CHANGELOG present ... PASS
[B.2] Install scripts present ... PASS
[C.1] All 17 skills present ... PASS
[C.2] Skill frontmatter sanity ... PASS
[D.1] Plugin agents present ... PASS
[D.2] Placeholders documented ... PASS
[D.3] AI-generated 50-*.md sanity (per-section sources, headings, no placeholders) ... PASS
[E.1] Layer 1: .harness/ matches templates/common/.harness/ ... PASS
[E.2] Layer 2: .claude/agents and .claude/skills synced from .harness/ ... PASS
[E.3] Rule sources present ... PASS
[E.4] Bootstrap files present and stubs reference AI-GUIDE.md ... PASS
[E.4b] AI-GUIDE.md indexes every .harness/rules/*.md (and vice versa) ... PASS
[E.5] Docs present ... PASS
[E.6] evals/golden-tasks.md present ... PASS
[E.7] No stale .harness/intervention.md tracked ... PASS
[F.1] Script pairs (.ps1 + .sh) present ... PASS
[F.2] Guard-rm scripts and settings-template guard wiring present ... PASS
[G.1] README references all 17 skills ... PASS
[H.1] Test fixtures present ... PASS
[G.2] CHANGELOG references all 17 skills ... PASS
[G.3] Version stamps consistent across plugin/marketplace/README ... PASS
[I.1] AI-GUIDE.md ≤200 lines ... PASS
[I.2] Rule fragments ≤200 lines each ... PASS
[I.3] Agent definitions ≤300 lines each ... PASS
[I.4] insight-index.md ≤30 evidence lines ... PASS
[I.5] docs/tasks.md ≤300 lines ... PASS
[I.7] Ignored INTERVENE supervision reports (WARN if >48h old on active task) ... PASS
[I.6] No retired-claim phrases in current docs/templates ... PASS
[J.1] settings.json schema integrity (.claude/ + template) ... PASS
[G.4] Doc count/version claims consistent with plugin.json + live check count ... PASS

=== Summary ===
  PASS: 32
  WARN: 0
  FAIL: 0
exit=0
```

`ls .t15-clean/.claude/` → `settings.json` only, and `ls -l .claude/settings.local.json` showed the
live file present and unmodified (2051 bytes, `Jul 31 17:09`) both before and after. **The S2 → S8
differential is AC-2**: same construction, same commands, the only variable is the `F.2` edit —
`FAIL exit=2` became `PASS exit=0`. Again **no non-`F.2` red**, in either direction.

**QA addition (iii) — B-3, the documented opt-out.** Inside the scratch tree only (the live file was
never involved), `.t15-clean/.claude/settings.local.json` was *written* as `{"hooks": {}}` — the
durable opt-out state, a **present** machine-local file with an empty hooks object:

```
[F.2] Guard-rm scripts and settings-template guard wiring present ... PASS
[J.1] settings.json schema integrity (.claude/ + template) ... PASS

=== Summary ===
  PASS: 32
  WARN: 0
  FAIL: 0
exit=0
```

B-3 holds: the gate does not judge a legitimate opt-out. (This is the state that makes the
presence-conditional formulation unsound, per RA E-3 / OQ-2 — now demonstrated, not just argued.)

Scratch tree dismantled again: `remove --force` exit 0, `prune` exit 0, `git status --porcelain |
grep t15-clean` exit 1, `git worktree list` shows only the main worktree.

## S9 — AC-10, installed-and-wired half (live tree, read-only)

`C1 = .claude/settings.local.json` parses, `hooks` is a dict with keys
`['Stop','PreToolUse','UserPromptSubmit','SessionStart']` ⇒ `present`. `C2 = .claude/settings.json`
parses, `hooks` is a dict with **0** keys ⇒ `empty`. Step 0.2 → no unknowns. Step 0.3 → `SOURCE =`
C1, `SOURCE_KIND = machine-local`, `OTHER_DECLARES = false`, `MACHINE_STATE = installed`.

```
Hook source:  .claude/settings.local.json (machine-local settings)  — committed .claude/settings.json declares no lifecycle hooks
```

§3b: one `PreToolUse` entry, `matcher = 'Bash'`, command
`sh -c 'cd "$CLAUDE_PROJECT_DIR" 2>/dev/null && bash .harness/scripts/guard-rm.sh'` ⇒ `K = 1`;
`PATHS = GUARD_PATHS = {.harness/scripts/guard-rm.sh}`, which exists on disk. Row 8 matches:

```
Safety hook:  installed and wired (guard-rm in PreToolUse of .claude/settings.local.json; matcher "Bash")
```

**+1** health point. **FR-9 / AC-10 discharged by execution in both directions**: the machine
dimension did not disappear — it is reported, and it distinguishes never-installed (S3) from
installed-and-wired (S9), naming the file it read in each case.

## S10 — AC-8, the pinned guard regression driver

```
$ bash .harness/scripts/test-guard-rm.sh      # exit 0
  PASS  case  R5: pwsh -c "& Remove-Item -Recurse C:\Windows" -> BLOCK

=== test-guard-rm summary ===
  PASS: 87
  FAIL: 0
```

87 / 0, unmoved. `baseline.json` pins re-read and unchanged: `verify_all_checks: 32` (`:10`),
`test_guard_rm_bash_assertions: 87` (`:23`). See *discrepancy 3* for why the design's
"`baseline.json` absent from `git diff --name-only`" phrasing could not be satisfied literally and
what was measured instead.

## S11 — AC-7 / NFR-2 close-out

```
$ wc -l .harness/rules/75-safety-hook.md
200 .harness/rules/75-safety-hook.md          ← identical to the S0 measurement
$ grep -n '"verify_all_checks"' .harness/scripts/baseline.json
10:  "verify_all_checks": 32,
$ grep -n '"version"' .claude-plugin/plugin.json .claude-plugin/marketplace.json
.claude-plugin/plugin.json:4:  "version": "0.46.0",
.claude-plugin/marketplace.json:17:      "version": "0.46.0",
```

No version stamp moved (`G.3` and `G.4` both PASS in S6). `.harness/rules/75-safety-hook.md` is
**200 lines at S0 and 200 lines at S11**, and T-15 did not open it for writing at all — the stale
claim at its `:150-151` (gate F-9) was **not** repaired, per C-10.

**Freeze evidence, restated honestly (discrepancy 3).** `git diff --name-only` cannot serve as the
freeze proof here, because 37 files — including most of §9's frozen list — were **already** modified
at S0 by uncommitted sibling work. The sound substitute is a **combination of two measurements, and
it needs both**: the S0→S11 dirty-set difference *plus* the per-file mtime table below. The
difference **alone is not sound** — it compares *filenames*, so it is structurally blind to a content
edit inside a file that was already dirty at S0, and most of §9's frozen list was in exactly that
state (`75-safety-hook.md`, `insight-index.md`, `baseline.json`, both READMEs, `docs/dev-map.md`,
`BATCH_PLAN.md`, `evals/guard-rm-cases.md`, both live guard scripts, both `test-guard-rm` drivers,
`skills/harness-status/SKILL.md`, both template guard scripts, two archived stage docs). For every
one of those the difference would report "no new name" whether or not T-15 had edited them. What
actually carries the freeze claim is the **mtime table**, because an mtime *does* move on a content
edit to an already-dirty file; the difference's job is the narrower one of showing which paths T-15
newly dirtied. First, the difference:

```
S0 dirty count:  37
S11 dirty count: 38
names in the S11 diff that were NOT dirty at S0:
  .harness/rejected-decisions.md
names dirty at S0 but no longer:
  (none)
untracked set: unchanged (same 9 paths)
```

T-15 newly dirtied **exactly one** path, `.harness/rejected-decisions.md` — ledger row **L7**. Every
other file it edited (L1–L6) was already dirty at S0. Second, and this is the measurement the freeze
claim actually rests on — per-file mtime, ordered against the first T-15 write at
`2026-08-01 02:29:37`; anything older than that stamp cannot have been written by this task,
including the already-dirty files the difference cannot see into:

| File | mtime | Verdict |
|---|---|---|
| `.harness/scripts/verify_all.sh` … `.harness/rejected-decisions.md` (all 7 edited) | `2026-08-01 02:29:37` → `02:30:48` | edited by T-15, as ledgered |
| `.harness/rules/75-safety-hook.md` | `2026-08-01 01:14:04` | untouched (predates the first T-15 write) |
| `.harness/scripts/baseline.json` | `2026-07-31 23:57:33` | untouched |
| `.harness/scripts/guard-rm.sh` / `.ps1` | `2026-07-31 23:55:04` | untouched — never mutated, per §11.1 |
| `.claude/settings.local.json` / `.claude/settings.json` / `.gitignore` | `2026-07-31 17:09` / `10:42` / `10:42` | untouched (NFR-1) |
| `README.md`, `README.zh-CN.md`, `MIGRATION.md`, `CONTRIBUTING.md`, `docs/dev-map.md`, `docs/manual-e2e-test.md`, `docs/project-overview.html`, `BATCH_PLAN.md`, `.harness/insight-index.md`, `evals/guard-rm-cases.md`, `test-guard-rm.{sh,ps1}`, `skills/harness-status/SKILL.md`, all three type-overlay `verify_all.sh.tmpl` | all ≤ `2026-08-01 01:30` | untouched |
| `skills/harness-init/templates/common/.claude/settings.json.tmpl` | `2026-08-01 02:34:15` | **mtime moved, content did not** — the M2/M3/M4 mutate-and-restore cycle. Absent from `git diff --name-only` and `cmp`-identical to its pre-mutation copy. Reported, not hidden. |

**QA addition (ii) discharged in that form: no frozen §9 surface was modified by T-15.** One residual
is reachable by *neither* measurement and is named rather than hidden: frozen **content inside files
T-15 legitimately edited** — `CHANGELOG.md`'s historical sections and `AI-GUIDE.md:42`. Those were
checked by direct re-read instead: `AI-GUIDE.md:42` still reads `32/32`, and all six historical `F.2`
rows in `CHANGELOG.md` (`:217`, `:741`, `:757`, `:1248`, `:1282`, `:1303`) still carry their old text.

## S12 — AC-4 / AC-11 by inspection

The shipped bash `F.2` (`verify_all.sh`, header comment through the `step … "FAIL"` line) is
**byte-equal** to design §3.1. The shipped PowerShell `F.2` (`verify_all.ps1`, `Step "F.2" { … }`)
matches §3.2 **statement-for-statement, with the comment body expanded as §3.2 directs** — byte
equality is not available there and would in fact be *worse* fidelity: §3.2's fence carries the
parenthetical `# (same comment body as the bash twin…)` in place of the comment, so the shipped file
carries the actual 11-line header plus the 4-line inner comment that the parenthetical instructs the
implementer to write. The two comment bodies are in lockstep across the two files. Cited rather than
re-pasted (rule 70 "reference, don't paste"); both were printed in full and read during this step.

**AC-4 — measured.** Counting only **code** lines (comment lines stripped), inside the `F.2` block:

| Pattern | bash | PowerShell |
|---|---|---|
| `settings\.local\.json` | **0** | **0** |
| `ConvertFrom-Json` | **0** | **0** |
| a settings-file path `\.claude/settings(\.local)?\.json` **not** followed by `.tmpl` | **0** | **0** |

Neither implementation reads any settings file inside the check. See *discrepancy 4* for why the
design's literal "zero occurrences" recipe over the whole block cannot be satisfied by the design's
own prescribed comment.

**C-4 / hazard-5 audit of the PS scriptblock, statement by statement** (the checklist is what gets
reused, not the sample, so it was re-applied to the shipped body): `$problems = @()` assignment;
`foreach` whose body is `if (…) { $problems += … }`; `$tmpl = …` assignment; `if (Test-Path $tmpl)` —
`Test-Path` is consumed by the condition, never a bare statement; `$tmplText = Get-Content $tmpl -Raw`
assignment (`-Raw` present); two `if` bodies that are `+=` accumulations; an `else` with a `+=`; and
`throw ($problems -join ' ')`, parenthesised, no `+`. **No statement emits to the pipeline** — no bare
`Test-Path` line, no `$problems + …` where `+=` was meant, no `Write-Output`, no unassigned
`Get-Content`. `${tmpl}` braces present at both interpolation sites; no collision with a read-only
automatic. `ConvertFrom-Json` survives elsewhere in the file (`:348`, `:349`, `:618`, `:659`) — none
in `F.2`.

**AC-11 — the live doc surface.** The old label `Guard-rm scripts and PreToolUse wiring present` now
appears in **zero live files** (remaining hits: 4 archived stage docs — `_archived/ai-native-init`,
`_archived/ai-safety-guardrails`×2, `_archived/harness-batch-skill`, `_archived/hook-truth-status` —
plus this task's own `02`). The new label appears in exactly the two scripts. Re-running the §8
sweeps, the only **live** doc lines stating this check's coverage are `40-locations.md:42` (L3) and
`AI-GUIDE.md:74` (L4), both now consistent with the shipped behaviour. Every other `F.2` mention is a
frozen historical row, unedited: `MIGRATION.md:231` (the "29 checks" decoy), `README.md:262` /
`README.zh-CN.md:264` (0.15.0 roadmap rows), historical CHANGELOG entries (`:217`, `:741`, `:757`,
`:1248`, `:1282`, `:1303`), `docs/tasks.md:18`, and `BATCH_PLAN.md:38` (append-only pool rationale,
still true — `F.2` does still assert the template's wiring). `docs/dev-map.md` states no `F.2`
coverage at all.

`docs/tasks.md:18` is called out explicitly because it is the one sibling in this list that states
the **retired** behaviour in the **present tense**: T-12's delivered row reads "F.2 reads guard
evidence from settings.local.json (fallback), J.1 adds it as a target". It is nonetheless **frozen**,
in the same class as `CHANGELOG.md:217` — a delivered-task row is a historical record of what T-12
shipped, not a live statement of current coverage — so it was **read and left unedited**. Rewriting a
delivered row would falsify the archive; the live surface that must track behaviour is L3 + L4, and
both were corrected.

**QA addition (i) — L3 is review-protected, not gate-protected.** `.harness/rules/40-locations.md:42`
was reverted to its pre-T-15 (now live-false) wording and the gate re-run:

```
[E.4b] … PASS   [I.6] … PASS   [G.4] … PASS
=== Summary ===
  PASS: 32
  WARN: 0
  FAIL: 0
exit=0
```

**No check catches it.** The subtlety `G.4` itself documents is confirmed: `40-locations.md` **is** in
`g4_files`, but its shape is `\([0-9]+ checks` — the literal on `:29`, not `:42`, so a whole-file test
passes with `:42` wrong. The eleven `g4_files` entries were re-read from `verify_all.sh:720-731`:
`AI-GUIDE.md`×2, `docs/dev-map.md`×2, `.harness/rules/40-locations.md`, `README.md`×2,
`README.zh-CN.md`×2, `docs/manual-e2e-test.md`, `.harness/scripts/baseline.json`. A `grep -c
CONTRIBUTING` over that array returns **0**, so `CONTRIBUTING.md:22` ("the gate currently runs 32
checks", read and left untouched) is **review-protected, not gate-protected** — condition C-6's
distinction, published from that evidence rather than from memory. L3 was restored immediately and
the gate re-run green (`32 / 0 / 0`, `exit=0`).

---

## PowerShell surface added to the standing operator list

`pwsh` is **absent on this host** (`command -v pwsh` → not found), so `verify_all.ps1` is
**green-by-symmetry only**: it was implemented as a complete, symmetric body (never a diff, never a
partial form), matching design §3.2 statement for statement, and audited against all five named
hazards above. No claim is made that it ran.

The **eight T-13 items and the ten T-17 items are untouched and unreconciled.** T-15 appends exactly
one item, following T-17's precedent:

> **11.** `verify_all.ps1` `F.2` (T-15). (a) `[Parser]::ParseFile` over
> `.harness/scripts/verify_all.ps1` — PowerShell parses the whole file before executing, so a
> syntax error in the rewritten `F.2` block kills the entire gate on Windows. (b) Run
> `pwsh -File .harness/scripts/verify_all.ps1`; expect `PASS 32 / WARN 0 / FAIL 0` and confirm the
> `[F.2]` line prints the **new** label. (c) Confirm `F.2` PASSes with no
> `.claude/settings.local.json` present — **in a fresh clone or the scratch tree, never by moving or
> emptying the live file**. (d) Multi-problem rendering: with the template's `{{GUARD_COMMAND}}`
> removed **and** one **template** guard script renamed at the same time (never
> `.harness/scripts/guard-rm.*` — that is the live fail-closed hook), confirm the FAIL detail names
> **both** problems in one message (this is the `-join`-precedence / accumulator check) and that the
> status is `FAIL`, not `WARN`. Expect `[E.1]` to be red as well while the template script is
> renamed — that is the mirrored-pair co-fire, not a defect; do **not** run `sync-self` in write mode
> to clear it. Restore both by renaming/editing back. (e) Confirm the `[F.2]` line never prints
> `WARN`: a WARN here would mean a statement in the block leaked to the pipeline (§3.2 hazard 5), and
> WARN exits 1.

Bash already demonstrated (d)'s multi-problem rendering incidentally at M3, which produced two tokens
in one `F.2` message — see discrepancy 2. The PS twin's accumulator is the code path that must
reproduce it.

## Gate residual items carried into stage 4 (03 round 2, §4)

| # | Item | Disposition |
|---|---|---|
| **R2-1** | The S7 DANGER block's *mechanism* is wrong — `cp` from a missing source fails and leaves the destination byte-intact (`sync_file` does `mkdir -p` + `cp`, no truncation, no `rm` on that path, no `errexit`), so it could **not** have seized the toolchain | **Prohibition honoured regardless.** `sync-self.sh` was never run in write mode at any point in this task. Recorded here so that if it is ever run by accident, the response is `git status` + `wc -l .harness/scripts/guard-rm.sh` — **never** hand-repairing a ~900-line security script, which would be the actual destructive act |
| **R2-2** | §3.2 hazard 5's example (`@("missing:x") -eq $false` reads truthy) is wrong — it filters to `@()` and reads as PASS; the genuine WARN vector is an emitted Boolean `$false`/`0`, e.g. a bare `Test-Path` line | **Rule applied at full strength, not downgraded.** The allow/forbid rule bans *all* pipeline emission, a strict superset of the dangerous cases, and the shipped block was audited statement-by-statement against it (S12). The first forbidden item on the list — a bare `Test-Path $f` — is precisely the real vector, and there is none in the block |
| **R2-3** | The `.t15bak` suffix's stated necessity is overstated (the real constraint is "ends in neither `.tmpl` nor `.append`", and `D.2` would have passed either way) | Renamed **verbatim as written**: `settings.json.tmpl.t15bak`. `D.2` was green in the M4 run, as predicted by both readings |
| **R2-4** | `.harness/rules/40-locations.md:41` is stale (names 5 of 11 `F.1` pairs) | **Left alone.** Only `:42` moved in that file; the S12 claim is therefore true as written |
| **Note (a)** | `git ls-files --error-unmatch …/verification_history.log` at S0 | Run; **exit 1** (untracked). Pasted at S0 |
| **Note (b)** | M1's two-FAIL exhaustiveness derivation lives in `03` §1, not in `02` | Pasted in full at S7 M1, alongside the actual run |

## Design drift / discrepancies

Nothing was re-architected and no expectation was edited to match a run. Five items, all recorded for
the reviewer.

1. **`DESIGN DRIFT` (cosmetic) — stage-doc filename.** Ledger L8 says `04_IMPLEMENTATION.md`; the PM
   dispatched with an explicit instruction to write `04_DEVELOPMENT.md`. This file is the L8
   artifact under the canonical stage-4 name. No content of L8 changed.

2. **`DESIGN DRIFT` (expectation vs run) — M3's FAIL detail carries two tokens, not one.** §11 S7 M3
   predicts the detail `…settings.json.tmpl:no_PreToolUse_block`; the run produced
   `…:no_GUARD_COMMAND_placeholder …:no_PreToolUse_block`. **Cause:** the template's only
   `{{GUARD_COMMAND}}` occurrence sits at `settings.json.tmpl:54`, *inside* the `"PreToolUse": [ … ]`
   array spanning `:48-58`, so deleting the array necessarily deletes the placeholder and B1 fires
   alongside B2. The design's summary-level prediction (`PASS: 31`, `FAIL: 1`, `exit=2`) is
   **correct** — `FAIL: 1` counts failing *checks*, and only `F.2` failed. **Neither the run nor the
   expectation was altered**, and no isolating substitute mutation was invented. AC-5 is still
   discharged for B2: `no_PreToolUse_block` is a token the old unanchored grep could never produce —
   proven by the read-only pattern comparison pasted at M3 (old exit 0, new exit 1, same file). Side
   benefit: this is the only run that exercises bash's multi-problem accumulation (B-9) end to end.

3. **`DESIGN DRIFT` (unsatisfiable-as-written measurement) — "absent from `git diff --name-only`".**
   S10 requires that of `baseline.json`; S11/QA(ii) require it of `75-safety-hook.md` and every
   frozen surface. **All were already in that diff at S0**, from the uncommitted sibling work the S0
   measurement exposed — the check cannot pass on this tree whatever T-15 does. Substituted the sound
   equivalent, pasted at S11: the S0→S11 dirty-set difference (exactly one new name,
   `.harness/rejected-decisions.md` = L7) plus mtime ordering against the first T-15 write. Flagged
   because the substitution is mine, not the design's.

4. **`DESIGN DRIFT` (self-inconsistent inspection recipe) — AC-4's "zero occurrences".** §3 verifies
   AC-4 by "zero occurrences of `settings.local.json`, `.claude/settings.json`, `ConvertFrom-Json`"
   inside the block — but the design's **own** prescribed comment names both settings paths in order
   to state that the check reads neither, and the template path `…/.claude/settings.json.tmpl`
   contains `.claude/settings.json` as a prefix. A literal whole-block count therefore returns 3
   (bash) and cannot return 0. The comment was **not** trimmed to make a number look right; AC-4 was
   measured on code lines with the template path excluded — **0 / 0 / 0 in both shells** (S12 table).

5. **Observation, not drift — one frozen file's mtime moved.**
   `skills/harness-init/templates/common/.claude/settings.json.tmpl` carries an mtime inside the T-15
   session because M2/M3/M4 mutated and restored it. Its **content** is byte-identical to its
   pre-mutation state (`cmp` verified after every restore) and it is absent from
   `git diff --name-only`. Reported rather than omitted.

## Open issues for review

- **`verify_all.ps1` is green-by-symmetry only.** `pwsh` is not installed on this host. Operator item
  11 above is the discharge path. This is the accepted residual risk R-4, declared not hidden.
- **The repository-head-versus-version-files contradiction is measured and deliberately unreconciled**
  (S0): HEAD is `cb0ed57` (v0.44.0) and the working tree is 37 files dirty carrying the unreleased
  0.46.0 stamps. Out of scope for T-15; noted so nobody "fixes" it.
- **Not verified (and not required by any AC):** that the *pre-change* check would have FAILed on the
  B-3 opt-out state. Reconstructing the pre-change body to run it would have meant hand-assembling an
  artifact and calling it a measurement; the argument for B-3's unsoundness stands on RA E-3 and on
  the code as read. Available to QA if wanted.
- **`.harness/rules/40-locations.md:41` and `.harness/rules/75-safety-hook.md:150-151` remain stale**
  by explicit instruction (R2-4, C-10/F-9). Both are backlog for a separate task; neither was
  repaired here.
- **PM-carried, untouched by the Developer:** `.harness/insight-index.md` is at exactly 30/30 `I.4`
  bullets, so the stage-7 harvest must **rotate**, not append (condition C-8). It was read but not
  trimmed. Ledger row **L9** (`docs/tasks.md` / `BATCH_PLAN.md` status) is also PM-owned and untouched.
- **This document is over the 500-line stage-doc cap** (`.harness/rules/70-doc-size.md`), a soft,
  WARN-level policy with no `I.*` mechanism over `docs/features/`. The overage is almost entirely
  evidence the design makes **mandatory and verbatim**: the full S0 `git status --porcelain`, the
  complete S2 and S8 runs, four mutation results with restores, and the gate's M1 exhaustiveness
  derivation quoted per residual note (b). Prose was trimmed instead; no pasted run was shortened,
  because the alternative — summarising a tally — is the exact failure this project archived twice.
  Flagged for the reviewer rather than resolved unilaterally.
- **Nothing was committed.** The tree is left green; the operator commits.

## Dev-map updates

**None required.** No file was added, moved or removed under any module (the only new file is this
stage doc under `docs/features/<slug>/`, which `docs/dev-map.md` covers generically). `docs/dev-map.md`
was searched for `F.2`, `guard-rm`, `PreToolUse` and `32 check`: its `:87` `(32 checks)` and `:184`
`runs all 32 checks` are `G.4` rows and the count did not move; its `:102`/`:106`/`:181`/`:182` rows
describe the guard scripts, the driver and the mirror set, none of which this task changed. No line
in it states what `F.2` covers, so there is nothing to correct.

## Insight to surface

- On a working tree carrying uncommitted sibling work, "the frozen file is absent from
  `git diff --name-only`" is not a freeze proof — 37 files were already dirty at S0, so the design's
  and the gate's shared freeze check could not pass regardless of what this task did; the sound
  substitutes are the **S0-dirty-set → close-out-dirty-set difference** (T-15 newly dirtied exactly
  one path) and **mtime ordering against the first edit of the session**. · evidence: T-15 S0 vs S11,
  `02_SOLUTION_DESIGN.md:692,694-699` vs the measured 37-file S0 `git status --porcelain`
- An anti-vacuity mutation that deletes a **container** falsifies every assertion whose evidence
  lives inside it: deleting `"PreToolUse": [ … ]` (`settings.json.tmpl:48-58`) also deletes the only
  `{{GUARD_COMMAND}}` at `:54`, so M3 fired two tokens where architect and gate both predicted one.
  Check containment before predicting a single-token detail; the check-level count (`FAIL: 1`) was
  still right, which is what makes the mis-prediction easy to miss. · evidence: T-15 M3 run vs
  `02_SOLUTION_DESIGN.md:640-646`

## Round 2 corrections (post-review, doc-record only)

`05_CODE_REVIEW.md` returned **APPROVED** (0 CRITICAL, 0 MAJOR). The PM routed four doc-record
corrections to stage 4. **No shipped code logic moved in this round** — `verify_all.sh`,
`verify_all.ps1`, both guard scripts, both settings files, `.gitignore` and every pinned baseline are
untouched; the only non-doc file edited is `CHANGELOG.md`, and only by one word.

| # | Finding | File | Change |
|---|---|---|---|
| 1 | MINOR `[SPEC/DESIGN]` (`CHANGELOG.md:83` inherited the design's "six facts" miscount) | `CHANGELOG.md:83` | "All **six** assertions stay at FAIL severity" → "All **seven**". The check asserts seven facts: A1–A4 (four guard-script paths), B0 (template exists), B1 (placeholder), B2 (hook key). One word; the sibling T-17 rows above and the `## [0.46.0]` heading were not touched. The design-text half of the same miscount is the architect's, not mine |
| 2 | MINOR `[STANDARDS/DOC]` (S11 freeze claim overstated, and headed for permanent memory) | `04` S11 | The prose said the S0→S11 dirty-set difference "is the equivalent measurement that *is* sound". It is **not sound alone**: a difference over *filenames* cannot see a content edit to a file that was already dirty at S0, and most of §9's frozen list was in that state. Rewritten to state the substitute is the **combination** — difference **plus** mtime table — with the mtime table named as what actually carries the freeze claim, matching the already-correct Insight bullet that goes to `.harness/insight-index.md`. The residual neither measurement reaches (frozen content *inside* files T-15 legitimately edited: `CHANGELOG.md` history, `AI-GUIDE.md:42`) is now named and was re-checked by direct read |
| 3 | MINOR `[SPEC/DOC]` (AC-11 enumeration omitted a frozen sibling) | `04` S12 | `docs/tasks.md:18` added to the enumeration of surviving `F.2` mentions, with the reason it is called out — it is the only one stating the retired behaviour in the **present tense** ("F.2 reads guard evidence from settings.local.json (fallback)") — and the ruling that it is **frozen-historical**, same class as `CHANGELOG.md:217`. Also added the previously-omitted `CHANGELOG.md:1282` to the historical-row list. **`docs/tasks.md` was read and NOT edited** |
| 4 | NIT `[DOC]` ("byte-equal to §3.1 / §3.2 respectively") | `04` S12 | Split the claim. Bash is byte-equal to §3.1. PowerShell is **statement-for-statement with the comment body expanded as §3.2 directs** — §3.2's fence carries the parenthetical `# (same comment body as the bash twin…)` where the shipped file carries the real 11-line header (`verify_all.ps1:276-286`) plus the 4-line inner comment (`:294-297`), so the shipped PS is *better* fidelity than byte-equality, not worse |
| — | MINOR `[STANDARDS/PROCESS]` (S0 paste reflowed into two columns) | `04` S0 | **Recorded as a process note, no re-run.** Every name was preserved, the transformation was disclosed, and stage 5 independently reconstructed 37 + 9 exactly. Noted as future stage-4 practice: a paste the design marks verbatim should be pasted raw |

Not actioned here, by routing: the design-text "six facts" miscount, the unsatisfiable AC-4 recipe,
the stage-doc evidence-budget collision and the B1/B2 containment residual (T-16) are
**solution-architect**; AC-12's second half and the containment residual statement are
**`07_DELIVERY.md`**; `.harness/insight-index.md` rotation at 30/30 is **PM**, and it was read but
**not trimmed** this round.

**Round-2 gate re-run** (`bash .harness/scripts/verify_all.sh`, pasted from the run, not re-derived):

```
[I.6] No retired-claim phrases in current docs/templates ... PASS
[J.1] settings.json schema integrity (.claude/ + template) ... PASS
[G.4] Doc count/version claims consistent with plugin.json + live check count ... PASS

=== Summary ===
  PASS: 32
  WARN: 0
  FAIL: 0
exit=0
```

**No-code-moved evidence (mtime, same method as S11).** The first round-2 write landed at
`2026-07-31 19:04:50 UTC` (`CHANGELOG.md`); the only other file written after it is this document
(`19:07:03`). Everything else predates it, so nothing else was written this round:
`verify_all.sh` `18:29:37` / `verify_all.ps1` `18:29:57` (round-1 writes), `guard-rm.sh` /
`guard-rm.ps1` `15:55:04`, `docs/tasks.md` `17:31:29` (sibling work — **read, not edited**),
`.claude/settings.local.json` `09:09:15`, `.claude/settings.json` `02:42:09`.

Round-2 invariants re-measured after the edits: `wc -l .harness/rules/75-safety-hook.md` → **200**
(md5 `5c432df8…`, identical to the pre-round-2 reading — untouched); `wc -l
.harness/insight-index.md` → **38** lines / **30** `I.4` bullets, md5 `a65110aa…` unchanged — **not
trimmed**; `I.4` and `I.2` both PASS above.

## Round 3 correction (post-QA, one CHANGELOG line)

`06_QA_REPORT.md` returned **APPROVED FOR DELIVERY**; NIT-1 was routed to the PM and delegated
here. **No shipped code logic moved in this round either** — the only file written is
`CHANGELOG.md`, and only inside the `### Changed — hook-truth-verify-scope (T-15)` bullet list.

**The finding.** The `F.2` bullet enumerated the retained assertions as *four guard-script paths +
two template assertions* while correctly totalling **seven**. The missing item is **B0**, the
template-presence assertion that gates B1/B2 and that anti-vacuity mutation **M4** (S7) exists to
falsify. This is the identical 4+2 under-enumeration that produced the original "six" miscount
corrected in round 2 — the architect traced and closed the design-side copy the same round
(`02_SOLUTION_DESIGN.md` §1 now reads "three distributed-template assertions … seven facts in
total"). `CHANGELOG.md` was the last copy carrying the wrong enumeration.

Before (`CHANGELOG.md`, second and third physical lines of the `F.2` bullet):

```
  file in either shell. It asserts the four guard scripts exist (repo pair + distributed template
  pair) and that `templates/common/.claude/settings.json.tmpl` carries `{{GUARD_COMMAND}}` and a
  `"PreToolUse"` hook key. All seven assertions stay at **FAIL** severity; none was softened.
```

After:

```
  file in either shell. It asserts the four guard scripts exist (repo pair + distributed template
  pair) and three facts about `templates/common/.claude/settings.json.tmpl`: that the template
  exists, that it carries `{{GUARD_COMMAND}}`, and that it carries a `"PreToolUse"` hook key. All
  seven assertions stay at **FAIL** severity; none was softened.
```

4 + 3 = the seven the same sentence already claimed, and the three now match table rows B0 / B1 /
B2 of `02_SOLUTION_DESIGN.md` §3. The bullet's opening sentence, the following four bullets, the
sibling T-17 rows above and the `## [0.46.0]` heading are byte-unchanged; no historical entry was
touched.

**Round-3 gate re-run** (`bash .harness/scripts/verify_all.sh`, pasted from the run — the CHANGELOG
is gate-relevant through the `G.2` / `G.4` / `I.6` doc-consistency meta-checks):

```
[I.6] No retired-claim phrases in current docs/templates ... PASS
[J.1] settings.json schema integrity (.claude/ + template) ... PASS
[G.4] Doc count/version claims consistent with plugin.json + live check count ... PASS

=== Summary ===
  PASS: 32
  WARN: 0
  FAIL: 0
```

A baseline run taken **before** the edit read the same `32 / 0 / 0`, so the delta is zero — the
edit neither fixed nor broke a check; it corrects prose the gate does not tally.

**Round-3 invariants re-measured after the edit** (transcribed from the commands, never derived):
`wc -l .harness/rules/75-safety-hook.md` → **200**, md5 `5c432df8…` — byte-identical to the
round-2 reading, so unmodified; `.harness/insight-index.md` **38** lines / **30** `I.4` bullets,
md5 `a65110aa…` unchanged — read but **not trimmed** (rotation at 30/30 is the PM's job at
delivery); the pinned guard-driver count `baseline.json:23
test_guard_rm_bash_assertions: 87` untouched (mtime `2026-07-31 23:57:33`, predating this round).
mtime evidence that nothing else was written: `CHANGELOG.md` `2026-08-01 03:37:55` is the only
file after the round-2 close, against `verify_all.sh` `02:29:37`, `verify_all.ps1` `02:29:57`,
`guard-rm.sh` `2026-07-31 23:55:04`, `75-safety-hook.md` `01:14:04`, `insight-index.md` `01:25:59`.

## Verdict

**READY FOR REVIEW** — `verify_all` **PASSED** at `PASS: 32 / WARN: 0 / FAIL: 0`, `exit=0`
(re-confirmed after the round-2 doc corrections, pasted above);
S0–S12 executed and pasted; all four anti-vacuity mutations run, each restored byte-identically with
a green re-run; every retained assertion at FAIL severity; check count flat at 32; no new check;
`test-guard-rm` 87 / 0; `75-safety-hook.md` 200 lines before and after; both guard scripts and
`.claude/settings.local.json` never touched.
