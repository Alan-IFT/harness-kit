# 04 — Implementation · T-14 `hook-truth-status`

**Mode**: `full` · **Stage**: 4 (developer, single-developer mode) · **Date**: 2026-07-31 · **rounds 1-3**
**Binding inputs**: `01_REQUIREMENT_ANALYSIS.md` (READY), `02_SOLUTION_DESIGN.md` round 2 (READY),
`03_GATE_REVIEW.md` round 2 (**APPROVED FOR DEVELOPMENT**, four conditions in §R2-8), `06_TEST_REPORT.md`
(round 3). **deferred-human mode**: defer, do not ask — no `AskUserQuestion` in any round; no `BLOCKED`
condition arose. **Every tally below is pasted from the run that produced it (NFR-6); none is derived by
arithmetic.**

## Pre-edit tree baseline

Design §10.1 **step 0** / gate Q-4, `git status --porcelain` **before the first edit**. The tree already
carries T-13's delivered-but-uncommitted changes, so AC-11 is the **delta** between this listing and the
post-edit listing in §5 — not the post-edit listing itself.

```
 M .claude-plugin/marketplace.json
 M .claude-plugin/plugin.json
 M .harness/insight-index.md
 M .harness/rules/40-locations.md
 M .harness/rules/75-safety-hook.md
 M .harness/scripts/baseline.json
 M .harness/scripts/install-hooks.ps1
 M .harness/scripts/install-hooks.sh
 M .harness/scripts/sync-self.ps1
 M .harness/scripts/sync-self.sh
 M .harness/scripts/test-init.ps1
 M .harness/scripts/test-init.sh
 M .harness/scripts/verify_all.ps1
 M .harness/scripts/verify_all.sh
 M AI-GUIDE.md
 M CHANGELOG.md
 M CONTEXT.md
 M README.md
 M README.zh-CN.md
 M docs/batches/default/BATCH_PLAN.md
 M docs/batches/default/STREAM_LOG.md
 M docs/dev-map.md
 M docs/features/_archived/insight-history.md
 M docs/features/_archived/resilient-hooks/04_IMPLEMENTATION.md
 M docs/features/_archived/resilient-hooks/06_QA_REPORT.md
 M docs/tasks.md
 M skills/harness-init/templates/common/.harness/rules/75-safety-hook.md.tmpl
 M skills/harness-init/templates/common/.harness/scripts/install-hooks.ps1
 M skills/harness-init/templates/common/.harness/scripts/install-hooks.sh
?? .harness/scripts/hook-spec.ps1
?? .harness/scripts/hook-spec.sh
?? docs/features/_archived/hook-truth-spec/
?? docs/features/hook-truth-status/
?? docs/proposals/frontier-gaps-2026-07.md
?? skills/harness-init/templates/common/.harness/scripts/hook-spec.ps1
?? skills/harness-init/templates/common/.harness/scripts/hook-spec.sh
```

Note for AC-11: `CHANGELOG.md` (T-13's uncommitted delivery) and the untracked
`docs/features/hook-truth-status/` are **already** here, so this task's edits to them add no porcelain line;
their per-file evidence is the `git diff --stat` below.

## Summary

`skills/harness-status/SKILL.md` gained a new **§0 Effective hook source** — one resolution step per run over
`.claude/settings.local.json` → `.claude/settings.json`, a four-state probe with a six-field result — and every
hook-related output (§1's guard row, §3b, §3c, §6's guard point, §7's fix line) now reads that one answer and
names the file it resolved instead of carrying its own hardcoded `.claude/settings.json` literal. §3b became
an eight-row first-match-wins decision table quantified over the paths extracted from the guard command; §3c
enumerates its rows from the hook wiring spec with a labelled whole-answer fallback; §7's blanket
`/harness-upgrade` became a six-branch table over `SOURCE_KIND` × `OTHER_DECLARES` × `MACHINE_STATE` (made
first-match-wins in round 3). `CHANGELOG.md` gained a subsection under the existing unreleased `## [0.45.0]`
heading. No script, settings file, template, installer, gate check or `.ps1` was touched.

## The four gate conditions (§R2-8) — stated

*(All `SKILL.md:<n>` citations in this section and the ledger below are **pre-round-3**; `## Round 3` carries
the current anchors.)*

**1. F-9 — bound on design §3.3 property 2.** Property 2 ("a command that merely *mentions* `guard-rm.sh`
yields `GUARD_PATHS = ∅` ⇒ row 6, never row 8") holds **only for mentions that are not left-bounded
extractable paths**. An extractable, existing guard path in a **non-executing** position — e.g.
`sh -c 'cd "$CLAUDE_PROJECT_DIR" && echo see .harness/scripts/guard-rm.sh && bash .harness/scripts/harness-sync.sh'` —
lands on **row 8** on a command that never invokes the guard. **Known, out-of-scope residual of the syntactic
determination FR-11 mandates**: separating an executed position from a quoted one needs shell-grammar analysis
that FR-11 (existence of *the extracted path*) and FR-18 (no judgment about intent) do not authorise and design
§12.3 excludes; unreachable through harness-generated wiring (`hook-spec.sh:99-114` emits four literal shapes,
none mentioning a path it does not execute). The shipped skill never asserts the unqualified absolute — "**in a
non-extractable position** … lands on row 6" (`SKILL.md:176-178`). **QA asserts P-6c as written**, not
generalised to "any mention".

**2. F-10 — the matcher adjunct on row 4.** **Decision: no adjunct prints on rows 1-4** — multiplicity `(b)`,
matcher and interpreter `(c)` are scoped to **rows 5-8 only** (`SKILL.md:189-191`). On row 4 `K = 0`, so no
`GUARD_ENTRY` exists; `(absent)` is defined for *an entry with no `matcher` key*, not for *no entry*, so
printing it there is a category error, and row 4's verdict line already conveys the absence. One shared scope
removes the FR-18 judgment call the gate flagged. **QA asserts exactly that** (P-7: none of `guard entries
matched:`, `matcher:`, `interpreter:`).

**3. F-11 — §5.2 (c)'s fail-closed clause, and the spec invocation count.** **Decision: `<semantics>` is
SUBSTITUTED from `hook-spec semantics guard-rm`, not shipped literal** (`SKILL.md:199`, documented `:209-211`).
Literal would make the `N+3` query decorative, hollow out D-2's justification for exceeding NFR-4's budget, and
restate a fact the spec and `75-safety-hook.md` own (insight 2026-06-20); no output divergence today (the spec
returns exactly `fail-closed`, captured below). Under §3c's fallback the skill directs the report to the
**literal** `fail-closed` plus a pointer at `75-safety-hook.md`, which design §3.2 licenses. **Actual count
(D-2): `N + 3` = 7** — `tools` ×1, `event <id>` ×4, `matcher` ×1, `semantics` ×1; `command`/`hostos` never
invoked. Accepted deviation from NFR-4's literal `1 + N` = 5 (a constant `+2`, independent of `N`); the RA
wording correction is an archive-time edit. Pinned at `SKILL.md:236`, so QA asserts rather than recomputes it.

**4. Preconditions.** §10.1 **step 0** satisfied (pre-edit porcelain baseline above, captured before the first
edit; AC-11 is the delta in §5). §10.1 **step 5b** satisfied: `insight-index.md` **not** hand-edited (30
evidence lines, I.4 PASS); insight goes to `07_DELIVERY.md` and lands only via `archive-task`.

## Files changed

1. `skills/harness-status/SKILL.md` — the whole behavioral change; per-section ledger below (rounds 1 and 3).
2. `CHANGELOG.md` — new `### Fixed — hook-truth-status (T-14): …` subsection under the existing
   `## [0.45.0] - 2026-07-31` heading (OQ-6 **Branch A**), **no version stamp moved**; untouched in round 3.
3. `docs/features/hook-truth-status/04_IMPLEMENTATION.md` — this document.

Nothing else: the whole §7.3 OUT set is untouched — every `.ps1`, `verify_all` F.2 (T-15) and its I.6 list, the
four derivation flows (T-16), both `test-supervisor` twins, `insight-index.md`, `docs/tasks.md`,
`.claude/settings*.json`, `install-hooks`, `hook-spec`, the settings template, `CONTEXT.md`, `docs/dev-map.md`,
the gate-F-8 files and `docs/proposals/frontier-gaps-2026-07.md`; §5's delta proves it.

### Per-section ledger for `skills/harness-status/SKILL.md`

| Section | What changed |
|---|---|
| **§0 (new)**, `:15-75` | Steps 0.1-0.5: candidate precedence, the four-state probe with the `{"PreToolUse": []}` tie rule and the explicit "this table wins over the installer's probe" clause, unknown-precedence, resolution + `OTHER_DECLARES`, the machine dimension (`never-installed` / `opt-out`), and the five pinned `Hook source:` forms |
| **§1**, `:94-103` | Guard row's Path cell → "effective hook source (§0), `hooks.PreToolUse` entry referencing `guard-rm`"; the `Present?` predicate pinned (rows 5-8 present, rows 1-4 not) with its deliberate asymmetry against §6's `+1` stated in the report's own words. **Row count still 14.** The §1 note at `:105-108` is **untouched, byte-identical** — the structurally-pinned `(7 + supervisor) … plugin-provided` line stays unbroken |
| **§3b**, `:135-220` | Rewritten: detection vs extraction, `PATHS` / `GUARD_PATHS`, the 8-row first-match-wins table with §5.2 (a)'s pinned verdict strings, the three quantifier rationales, row 6's rationale, the adjunct block (§5.2 (b)/(c) + matcher), the cross-file note, and the pointer to §7's fix table. The retired `DISABLED — .claude/settings.json has no PreToolUse for Bash` string is **deleted** (0 occurrences; no I.6 entry added) |
| **§3c**, `:222-293` | Header: the spec query plan (`N+3` = 7), the shell-twin rule, the never-byte-compare rule, the whole-answer fallback with its label; `Hook congruence (from <SOURCE>):` header forms; `not wired` re-defined against the effective hook source with the `SOURCE = none` case; `DANGLING`/`MALFORMED` fix lines re-pointed at §7 (see Design drift); the closing sentence now says §3b reads the **same** `SOURCE`. The extraction pattern at `:263` was **copied, not retyped — byte-identical**, escaped `\.harness/` and **unescaped** `.` before `(ps1\|sh)` included (design F-5, gate Q-12) |
| **§6**, `:317-319` | The `+1` bullet now reads "**installed and wired** — §3b row 8 … The *other* shell twin is not required" (OQ-4a). `All 14 required assets → +6` and `Total possible: 12` **unchanged** |
| **§7**, `:335-345` | The blanket `/harness-upgrade` line replaced by §5.3's six-branch table keyed on `SOURCE_KIND` × `OTHER_DECLARES` × `MACHINE_STATE`, including the `OTHER_DECLARES = true` branch that prints the removal **alone** and explicitly forbids chaining the installer |
| **Anti-patterns**, `:352-360` | Three new lines: never re-read a settings path outside §0 (the R-7 re-inlining guard, made reviewable); never report a guard healthy on an unverified wiring; never auto-repair or propose rewriting a runnable user-chosen command |

## verify_all result

`bash .harness/scripts/verify_all.sh`, **before** the first edit (baseline) and **after** the round-1 edits; all
32 named rows printed `PASS` in the same order in both (`[F.2]`, `[G.3]`, `[I.4]`, `[I.6]`, `[J.1]`, `[G.4]`
included). Summaries pasted from those runs — round 1 pre-edit `PASS: 32 / WARN: 0 / FAIL: 0`, round 1
post-edit `PASS: 32 / WARN: 0 / FAIL: 0` (`## Round 3` keeps the full `=== Summary ===` banners).
**Round 2 re-run, pasted from that run: `PASS: 32 / WARN: 0 / FAIL: 0`** *(round 3 re-runs both — see
`## Round 3`)*. **Delta: 0 new failures, 0 new warnings, baseline preserved**; check count **32**, no check
added, removed or narrowed (NFR-3, AC-9). G.4 PASSes with a CHANGELOG heading for the manifest's version
(AC-12); I.4 with the insight index untouched at 30 lines; I.6 PASSes (R-9); the stage doc trips nothing
(`docs/features/**` is I.6-exempt, which is why it may quote the retired string).

### OQ-6 tripwire (design §9) — run at delivery time

**Branch A is live** — `0.45.0` is neither committed nor tagged and the manifest still reads `0.45.0`, so the
entry was folded in as a `###` subsection under `## [0.45.0]`, **no version stamp moved**, Branch B not taken:

```
$ git log --oneline -1
cb0ed57 feat(v0.44.0): resilient lifecycle hooks + Windows repair-path fixes (T-12)
$ git tag --list 'v0.45.0*'
(no output)
$ grep -n '"version"' .claude-plugin/plugin.json
4:  "version": "0.45.0",
$ grep -n '^## \[0.45.0\]' CHANGELOG.md
8:## [0.45.0] - 2026-07-31
$ grep -n '^### Fixed — hook-truth-status' CHANGELOG.md
42:### Fixed — hook-truth-status (T-14): the health report reads the settings file the hooks actually live in
```

### `test-supervisor` (design §10.1 step 3) — structurally-pinned touchpoint

`bash .harness/scripts/test-supervisor.sh`, three captures on this **python3-present** host — round 1 pre-edit,
round 1 post-edit, round 2 — all with an identical tail, pasted once **from the round-2 run**; both
structurally-pinned fan-out assertions printed `PASS` in every capture, so §10.1 step 6's escalation did not
trigger and **no driver was edited in either shell** (AC-10, OQ-7a, NFR-5):

```
=== Result ===
  PASS: 46
  FAIL: 0
$ grep -nE '\(7 \+ supervisor\).*plugin-provided' skills/harness-status/SKILL.md
105:Note: the framework agents (7 + supervisor) are **plugin-provided** (`harness-kit:<name>`)
$ grep -cF '{pm,req,sol,gate,dev,review,qa}*' skills/harness-status/SKILL.md
0
```

**TALLY NOTE — the `46` vs `baseline.json:16`'s `45` is not drift, and `baseline.json:16` must not move.**
*(Corrected in round 2; round 1's "stale since v0.31.0" diagnosis was false — CR MAJOR-1.)* That key is
`test_supervisor_bash_no_python3_assertions`; AC-7.3 (`test-supervisor.sh:293-310`) sits inside `if command -v
python3 …; then` with **no `else` branch**, so the one driver yields **45 without python3 and 46 with it**. `45`
is the *correct, current* value and a python3-present run exceeding it is the intended state — same convention
at `baseline.json:23` (`_qa_note_t13`). So `baseline.json:16` is **out of bounds for comparison in either
direction** and was not touched (OUT per design §4/§7.3); reconciling it to 46 would corrupt a correct frozen
count. **AC-10's basis is self-comparison: 46 → 46 on this host across this task's edits, both fan-out
assertions green.** Design §10.1 step 3 and §10.2's `(45/0, …)` carry the mis-derivation. *(QA corroborated the
split independently with a no-python3 shim — `06_TEST_REPORT.md:379-386`.)*

## Self-execution of the new §0 → §3b → §3c procedure against this repository

Design §10.1 step 4, executed with `Bash` + `Read`/`Glob` on this working tree. **Round-3 compression note
(doc-size cap):** round 1's intermediate captures (candidate states, detection/extraction, adjuncts, the 7 spec
invocations with exit codes) are **re-executed and pasted verbatim post-fix** under `## Round 3`; retained here
are round 1's derivation and rendered output, which is what AC-1/AC-2 assert.
**§0**: both candidates are regular files that parse as JSON objects (`hooks` keys **4** / **0**) ⇒
`UNKNOWN_FILES = ∅`, Step 0.2 does not fire; Step 0.3 makes C1 `SOURCE`, `SOURCE_KIND = machine-local`, C2
`empty` ⇒ `OTHER_DECLARES = false`, `MACHINE_STATE = installed`; Step 0.4 does not apply.
**§3b**: `K = 1`; `PATHS = GUARD_PATHS = {.harness/scripts/guard-rm.sh}`, existing; no `{{…}}`; first token
`sh` on PATH (`/usr/bin/sh`) ⇒ first match wins: row 1 no (`UNKNOWN_FILES = ∅`), rows 2-3 no (`SOURCE ≠
none`), row 4 no (`K = 1`), row 5 no, row 6 no (`GUARD_PATHS ≠ ∅`), row 7 no (nothing missing) ⇒ **row 8**,
`|PATHS| = 1` form, **+1**; §1's guard row **present** (row 8 ∈ {5,6,7,8}); matcher `Bash` = the spec's answer
so no `— non-canonical matcher`; interpreter on PATH so no `<semantics>` clause; no cross-file note; no fix
line. **§3c**: 7 invocations, all exit 0 with non-empty stdout ⇒ fallback not taken, no label;
`.harness/scripts/hook-spec.sh` is this shell's twin, the `.ps1` twin was never invoked.

**Rendered output (round 1) — §0 form 1 of §5.1, §3b, §3c:**

```
Hook source:  .claude/settings.local.json (machine-local settings)                  — committed .claude/settings.json declares no lifecycle hooks
Sub-agent dispatch:  enabled (Claude Code via Task tool)
Safety hook:         installed and wired (guard-rm in PreToolUse of .claude/settings.local.json; matcher "Bash")
  guard entries matched:  1
  matcher:  "Bash"
  interpreter:  sh (on PATH)
Hook congruence (from .claude/settings.local.json):
  Stop:              ok
  PreToolUse:        ok
  UserPromptSubmit:  ok
  SessionStart:      ok
```

**What it establishes** (QA re-captures independently): **AC-1** — guard **installed and wired**, source named
`.claude/settings.local.json`; **AC-2** — four congruence rows all `ok`, same source, no `not wired`. Against
the **pre-edit** text the same repository state yields `DISABLED — .claude/settings.json has no PreToolUse for
Bash` and four `not wired` rows, the defect this task removes. Per gate Q-11 the `|PATHS| > 1` row-8 form and
rows 5/6/7 are **not** exercisable here (`|PATHS| = 1`, `K = 1`) — they are QA's, via fixtures outside the tree.

## `git status --porcelain` after the changes, and the AC-11 delta

Both porcelain captures were written to files and diffed; the post-edit listing is the pre-edit baseline above
plus **one** line ("reference, don't paste"), and the delta is the criterion, pasted from the run:

```
29a30
>  M skills/harness-status/SKILL.md
$ git diff --stat -- skills/harness-status/SKILL.md CHANGELOG.md
 CHANGELOG.md                   |  96 +++++++++++++++++
 skills/harness-status/SKILL.md | 237 ++++++++++++++++++++++++++++++++++++-----
 2 files changed, 307 insertions(+), 26 deletions(-)
$ awk '/^\| Asset \| Path \| Present/,/^$/' skills/harness-status/SKILL.md | grep -c '^| '
15          # 1 header + 14 data rows -> required-asset row count is 14, unchanged
$ grep -c 'DISABLED — .claude/settings.json has no PreToolUse for Bash' skills/harness-status/SKILL.md
0           # retired string removed; no I.6 banned-phrase entry added (OQ-9a)
```

**Exactly one new porcelain line**, and it is §7.3 IN row 1; the two other IN files were already in the baseline
(`CHANGELOG.md` ` M` from T-13, `docs/features/hook-truth-status/` `??`), so the `--stat` above is their
evidence. `CHANGELOG.md`'s 96 insertions / 0 deletions are consistent with a pure subsection insert moving no
existing line (historical entries at `:86`, `:368`, `:924` and every version stamp untouched); `All 14 required
assets present → +6` and `Total possible: 12` are byte-unchanged in §6. **No hook script, settings file,
template, installer or gate check is modified by this task** (AC-11).

## Design drift

One item, flagged for the reviewer. *(Round 3 adds no new drift — see `## Round 3`.)*
**`DESIGN DRIFT` (minor, FR-8-driven) — §3c's `DANGLING` / `MALFORMED` fix lines were re-pointed at §7's
conditional table.** Design §3.4 lists these two fix lines neither as kept nor as changed, and §7.3's ledger
row 1 summarises the §3c edit as "header + source sentence". Left untouched, §3c would have kept printing the
blanket `Fix line: run /harness-upgrade to re-land current scripts and rewire hook paths` — which on this very
repository (`SOURCE_KIND = machine-local`) **cannot reach the file the report just named**. FR-8 is absolute,
§5.3 is a report-wide fix-line contract (not a §7-only one), and §3b was explicitly re-pointed at it, so
leaving §3c blanket would ship the report contradicting itself on the defect class this task removes (design
risk R-7). NFR-2 preserved: the `DANGLING`/`MALFORMED` **tokens** are byte-unchanged so `/harness-upgrade`'s
repair trigger (`skills/harness-upgrade/SKILL.md:29-33`) still fires; the committed case still names
`/harness-upgrade` in the same words; only the machine-local case defers to §7. **Round-2 status: adjudicated
CORRECT and in ledger** (CR Adjudication 2) — FR-8's final sentence is report-wide, not §3b-scoped; the round-1
revert offer was **not** taken and these 8 lines stand.

No other deviation: the extraction pattern was copied, not retyped, and the dot not "fixed" (gate Q-12); rows
6/7/8 quantify over `PATHS` / `GUARD_PATHS` exactly as §3.3 specifies; the §5.1, §5.2 (a)/(b)/(c), §5.3 and
§5.4 pinned strings are reproduced verbatim with their `<…>` slots.

## Open issues for review

1. **WITHDRAWN in round 2 — `baseline.json:16` needs no reconciliation and must not be moved** (CR MAJOR-1's
   false diagnosis; see the corrected tally note). Nothing for PM/QA to reconcile.
2. **§3c's interpreter WARN still names only `pwsh` / `bash`** (pre-round-3 `:287-290`) while every shipped unix
   hook command's first token is `sh`, so it can never fire here. Design §3.4 lists that WARN as **unchanged**,
   so it stands; §3b's adjunct does name `sh`. Worth a backlog row.
3. **Gate F-8's three stale T-12 hook-location claims** (`AI-GUIDE.md:110`, `docs/getting-started.md:180-182`,
   `.harness/rules/60-tool-handoff.md:72-74`) remain false and were **not** edited, per design §12.11 — PM
   carries them to the stream.
4. **F-9's residual is shipped, not closed** (condition 1): bounded and unreachable through harness-generated
   wiring, but a live false-green class for a hand-written hook command.
5. **PowerShell (NFR-5): no `.ps1` touched**; no operator PowerShell item added to `baseline.json:23`, and no
   PowerShell verification is claimed or performed. **Known nit, not reopened (CR MINOR-1)**: §3c's
   committed-wiring fix line restates §5.3's pinned string in a second byte-form; a QA byte-assertion should
   target the §7 table row, not §3c.

## Dev-map updates

**None.** No file, module or directory was added, moved or removed — the product edits are inside two existing
files, and `docs/dev-map.md`'s two `harness-status` entries (`:50`, `:163`) make no hook-source claim, so
nothing in it is falsified (design §7.3 lists it as OUT).

## Insight to surface (optional)

A `*_no_python3_*` key in `baseline.json` is **not comparable** to a python3-present run — the driver's
python3-gated blocks make the two tallies legitimately different — so a design quoting such a key as a run
expectation mis-derives it and routes a "reconciliation" at a correct frozen count (design §10.1 step 3 quoted
`45` for a host whose runs yield 46). · evidence: `test-supervisor.sh:293-310` (AC-7.3, python3-gated, no
`else`) vs `baseline.json:16`, precedent at `baseline.json:23`

## Round 3

**Input**: QA's `06_TEST_REPORT.md` — `CHANGES REQUIRED (2 MAJOR)`. PM scope: **two one-clause fixes in
`skills/harness-status/SKILL.md`, nothing else** — exactly what round 3 changed (plus this document).
`guard-rm.sh` (QA's out-of-band CRITICAL, PM-routed to the stream), `baseline.json`, `CHANGELOG.md`,
`insight-index.md`, `verify_all`, every driver and `.ps1`, the derivation flows and the gate-F-8 files were
**not touched**; the porcelain delta below proves it. The guard was neither disabled nor weakened — it
**blocked one round-3 Bash call** ("could not parse nested pwsh command safely"), re-issued in a form it
accepts. **No `AskUserQuestion`** (deferred-human mode); every tally is pasted from the round-3 run that
produced it (NFR-6).

### Fix 1 — MAJOR-1: §0 Step 0.1 is now total

`SKILL.md:29` — the `unreadable` row gained one clause: "…, or it parses but a top-level `hooks` key is present
whose value is **not** a JSON object (`[]`, a string, a number, `true`, `null`)"; `:41-45` states totality. The
direction is the strict one — a wrong-typed `hooks` is `unreadable` ⇒ Step 0.2 ⇒ `MACHINE_STATE = unknown` ⇒
§3b row 1 ⇒ **no health point**, never QA's Reading B (`installed and wired`, `+1`). Totality re-derived by
evaluating the four row conditions **independently** (no first-match short-circuit), counting matches per input:

```
input                                  PRE-fix rows matched         POST-fix rows matched
<nothing at the path>                  1 ['absent']                 1 ['absent']
<a directory>                          1 ['unreadable']             1 ['unreadable']
not json at all                        1 ['unreadable']             1 ['unreadable']
{ "hooks": { "PreToolUse": [           1 ['unreadable']             1 ['unreadable']
[]  (top-level array)                  1 ['unreadable']             1 ['unreadable']
{}                                     1 ['empty']                  1 ['empty']
{"hooks":{}}                           1 ['empty']                  1 ['empty']
{"hooks":{"PreToolUse":[]}}            1 ['present']                1 ['present']
{"hooks":[]}          <- QA MAJOR-1    0 []                         1 ['unreadable']
{"hooks":"x"}                          0 []                         1 ['unreadable']
{"hooks":null}                         0 []                         1 ['unreadable']
{"hooks":3}                            0 []                         1 ['unreadable']
{"hooks":true}                         0 []                         1 ['unreadable']
POST-fix inputs NOT landing on exactly one state: 0
```

**No previously-classified input changed state**; the five that matched **none** now land on `unreadable` — the
hole closed in the fail-safe direction only. The shipped sentence "the installer's probe also calls that shape
unparseable" is asserted, not assumed (`settings_hook_state` sourced read-only out of `install-hooks.sh:69-94`;
the `.ps1` twin mirrors it at `install-hooks.ps1:96` — **read, not executed**, NFR-5):

```
installer settings_hook_state wrongtype.json -> unparseable      # content: { "hooks": [] }
installer settings_hook_state right.json     -> present
```

### Fix 2 — MAJOR-2: §7 is first-match-wins with the `MACHINE_STATE` rows first

- `:343-345` — lead-in now reads "**conditional on §0's result**, and **first match wins** — exactly one line,
  in this row order"; `:347-354` — the three `MACHINE_STATE` rows moved **above** the three `SOURCE_KIND` rows,
  **no cell text changed** (all six §5.3 pinned strings byte-identical, only order moved); `:356-361` — why the
  order is load-bearing: Step 0.2 lets resolution continue so `unknown` can coexist with a `SOURCE_KIND`, while
  `never-installed`/`opt-out` imply `SOURCE_KIND = none` and never contend.
- `:225-228` (§3b, QA's `:219`) — "keyed on `SOURCE_KIND`" → "keyed on §0's **result** with first match wins —
  row 1 (`UNKNOWN_FILES` non-empty) therefore takes §7's `MACHINE_STATE = unknown` line, never a `SOURCE_KIND`
  line, even when a candidate still resolved."
- `:287-291` (§3c's `DANGLING` fix-line pointer) — same key correction, "keyed on §0's `SOURCE_KIND`" → "keyed
  on §0's result with first match wins. When that selects `SOURCE_KIND = committed` it is …". **Disclosed as an
  in-scope extension of fix 2, not new scope**: identical defect (a second pointer naming the wrong key) in the
  identical state — left alone, §3c would still route the P-11 state to `/harness-upgrade`, the FR-8 violation
  this fix removes. No other §3c byte moved.

### Self-check on QA's exact inputs, round 3, against the fixed text

```
#### MAJOR-1 input: C1 = {"hooks": []}, C2 healthy
  .claude/settings.local.json  -> unreadable
  .claude/settings.json        -> present
  UNKNOWN_FILES=['.claude/settings.local.json']  SOURCE=.claude/settings.json  SOURCE_KIND=committed  OTHER_DECLARES=False  MACHINE_STATE=unknown
  sec.3b row 1: UNKNOWN - .claude/settings.local.json could not be read or parsed; guard state undetermined
  sec.6 guard health point = 0
  sec.7 row selected (first match wins): MACHINE_STATE = unknown
  sec.7 fix line: inspect .claude/settings.local.json - it is loaded by Claude Code but this report could not parse it

#### MAJOR-2 input: C1 truncated JSON, C2 healthy (unknown AND committed)
  UNKNOWN_FILES=['.claude/settings.local.json']  SOURCE=.claude/settings.json  SOURCE_KIND=committed  OTHER_DECLARES=False  MACHINE_STATE=unknown
  sec.7 row selected (first match wins): MACHINE_STATE = unknown
  sec.7 fix line: inspect .claude/settings.local.json - it is loaded by Claude Code but this report could not parse it
```

`{"hooks": []}` now lands on **exactly one** state, and the `unknown ∧ committed` state selects a fix line
naming **the file the report named** — `/harness-upgrade` unreachable there. All six §7 branches stay
individually reachable (same run, one fixture per branch, `sec.7 row selected` lines only):

```
reach: SOURCE_KIND = committed                  -> SOURCE_KIND = committed
reach: machine-local, OTHER_DECLARES = false    -> SOURCE_KIND = machine-local, OTHER_DECLARES = false
reach: machine-local, OTHER_DECLARES = true     -> SOURCE_KIND = machine-local, OTHER_DECLARES = true
reach: MACHINE_STATE = never-installed          -> MACHINE_STATE = never-installed
reach: MACHINE_STATE = opt-out                  -> MACHINE_STATE = opt-out
```

### Re-execution of §0 → §3b → §3c against this repository, round 3, post-fix

```
=== §0 Step 0.1 — candidate states (post-fix table, incl. new hooks-type clause) ===
-rw-rw-r-- 1 alan alan 2051 Jul 31 17:09 .claude/settings.local.json
.claude/settings.local.json -> parses; hooks is an object, keys = 4 (PreToolUse,SessionStart,Stop,UserPromptSubmit) -> present
-rw-rw-r-- 1 alan alan 964 Jul 31 10:42 .claude/settings.json
.claude/settings.json -> parses; hooks is an object with 0 keys -> empty
=== §3b detection/extraction + §3c congruence, SOURCE = .claude/settings.local.json ===
K = 1
  matcher=Bash  command=sh -c 'cd "$CLAUDE_PROJECT_DIR" 2>/dev/null && bash .harness/scripts/guard-rm.sh'
PATHS = ['.harness/scripts/guard-rm.sh']
GUARD_PATHS = ['.harness/scripts/guard-rm.sh']
missing on disk = []
unresolved {{...}} = False
first token = sh          (=== interpreter on PATH? === /usr/bin/sh)
  Stop:              ok
  PreToolUse:        ok
  UserPromptSubmit:  ok
  SessionStart:      ok
=== §3c spec query plan (N+3 = 7) ===
harness-sync / guard-rm / ambient-prompt / ambient-reset      tools exit=0
  event harness-sync   -> Stop (exit=0)          event guard-rm       -> PreToolUse (exit=0)
  event ambient-prompt -> UserPromptSubmit (exit=0)   event ambient-reset  -> SessionStart (exit=0)
  matcher guard-rm   -> Bash (exit=0)            semantics guard-rm -> fail-closed (exit=0)
```

*(The `tools` list and the four `event` lines are re-wrapped from the captured run to fit the cap; every token
and exit code is verbatim.)* Row selection is unchanged by the fix — rows 1-7 all miss ⇒ **row 8**, `+1`,
`Hook source: .claude/settings.local.json (machine-local settings)`, four congruence rows `ok`: **byte-identical
to round 1's verdict, no regression.**

### Verification tallies — round 3

`verify_all.sh` and `test-supervisor.sh` each run **before** the round-3 edits, **again after**, and a third
time after this document was written — identical numbers all three times; the four summaries below are pasted
from their own runs. All 32 `verify_all` rows printed `PASS` every time; both structurally-pinned fan-out
assertions printed `PASS` in every `test-supervisor` run (post-edit tail below). `baseline.json:16`'s `45` is
the correct no-python3 value on this python3-present host and was **not** touched.

```
=== Summary ===   <- round 3, pre-edit      === Summary ===   <- round 3, post-edit
  PASS: 32                                    PASS: 32
  WARN: 0                                     WARN: 0
  FAIL: 0                                     FAIL: 0

  PASS  fan-out: harness-status SKILL.md notes framework agents (7 + supervisor) are plugin-provided
  PASS  fan-out: harness-status SKILL.md retired the canonical-7 asset glob (v0.30 truth)
=== Result ===    <- round 3, pre-edit      === Result ===    <- round 3, post-edit
  PASS: 46                                    PASS: 46
  FAIL: 0                                     FAIL: 0
```

Frozen counts and the AC-11 delta, pasted from the round-3 post-edit commands (`$ diff` operands: the round-1
pre-edit porcelain baseline listed at the top of this document vs. the post-edit `git status --porcelain`):

```
$ awk '/^\| Asset \| Path \| Present/,/^$/' skills/harness-status/SKILL.md | grep -c '^| '
15                        # 1 header + 14 data rows -> 14 required-asset rows, unchanged
$ grep -c 'DISABLED — .claude/settings.json has no PreToolUse for Bash' skills/harness-status/SKILL.md
0
$ grep -n 'All 14 required assets\|Total possible' skills/harness-status/SKILL.md
321:- All 14 required assets present → +6 health points
328:- Total possible: 12
$ grep -c '^- ' .harness/insight-index.md
30                        # I.4 cap intact; index not hand-edited in any round
$ diff r1_pre.txt r3_post.txt
29a30
>  M skills/harness-status/SKILL.md
$ wc -l skills/harness-status/SKILL.md
376 skills/harness-status/SKILL.md
```

**Delta vs the round-1 pre-edit baseline is still exactly one line, `M skills/harness-status/SKILL.md`** —
`CHANGELOG.md` and `docs/features/hook-truth-status/` were already in that baseline, neither was touched this
round (`git diff --stat -- skills/harness-status/SKILL.md` → `1 file changed, 228 insertions(+), 27
deletions(-)`, cumulative over rounds 1+3), and the fixtures live in the scratchpad outside the repo, unleaked.

### Round-3 drift and open issues

**No round-3 design drift**: both fixes tighten the shipped text toward FR-8/FR-18 without changing a single
§5.1-§5.4 pinned string or any verdict this repository produces, and the §3c pointer correction is disclosed
above rather than silently folded in. Round 1's single `DESIGN DRIFT` item stands as adjudicated. Open:
(1) **`guard-rm.sh` CRITICAL-OOB-1 untouched by design** (PM ruling: new stream task) — pre-existing, T-14
changes no hook script, and it must not ride an in-flight row whose requirement/design/gate never examined it;
**not worked around, not weakened**. (2) QA's MINOR-1…MINOR-4, NIT-1, CR MINOR-2/-4, F-9's residual and the
design's P-20/P-21 probe-spec defects remain **PM backlog / design-owned**, per the round-3 scope statement.
(3) Round-1/2 line citations are **pre-round-3** (the fixes inserted lines in §0, §3b, §7); `## Round 3`'s
anchors are current, against `wc -l` **376**.

## Verdict

**READY FOR REVIEW**

Round 3 fixed QA's two MAJORs in `skills/harness-status/SKILL.md` and nothing else: Step 0.1 is now **total**
(13 inputs, each landing on exactly one state, 0 unclassified, no previously-classified input moved), and §7 is
**first match wins** with the `MACHINE_STATE` rows first, so the `unknown ∧ committed` state can no longer print
`/harness-upgrade` against a file it cannot reach. Round-3 runs: `verify_all` **32/0/0** and `test-supervisor`
**46/0**, each pre- **and** post-edit on this python3-present host; this repository still reports **installed and
wired** from `.claude/settings.local.json` with four `ok` congruence rows; AC-11 delta still exactly
`M skills/harness-status/SKILL.md`. Rounds 1-2's records above are compressed in prose only — their evidence is
retained or superseded by a round-3 re-capture of the same procedure.
