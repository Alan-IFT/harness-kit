# 04 — Development Record · T-13 `hook-truth-spec`

**Mode**: `full` · **Stage**: 4 (developer) · **Date**: 2026-07-31
**Upstream**: `01_REQUIREMENT_ANALYSIS.md` (READY + Amendment 1) · `02_SOLUTION_DESIGN.md` (READY, rework 1) · `03_GATE_REVIEW.md` (**APPROVED FOR DEVELOPMENT**, 8/8 PASS)
**Version**: `0.44.0` → `0.45.0` (OQ-7a — version strings only)

## Summary

Added the two-shell **hook wiring spec** `hook-spec.{ps1,sh}` to `templates/common/.harness/scripts/`
(byte-mirrored into this repo by `sync-self` Mapping 9): a pure CLI owning the
`(hook tool × target OS) → command byte-form` table plus each tool's `event`, `matcher` and
fail-open/fail-closed `semantics`. Extended `install-hooks.{ps1,sh}` to bootstrap a missing
`.claude/settings.local.json` from that spec when — and only when — the committed settings declares
no lifecycle hooks and no machine-local file exists. Byte-identity with today's forms is proven
executably against the **live** derivation helper for all 8 `(tool, OS)` cells. The `verify_all`
check count stays **32**; the destructive-command guard stays **fail-CLOSED** on every path.
Reworked three times (code review ×2, QA ×1); each rework's section is below, oldest first.

## Rework round 1 — code review

**CHANGES REQUIRED** (0 CRITICAL, 1 MAJOR, 7 MINOR, 4 NIT); every finding adjudicated below, nothing
silent; floor re-confirmed green (**32 / 0 / 0**) first. *(Compacted in rework 3 — the reviewer's
carried table at `05_CODE_REVIEW.md` §0 holds the long form and confirms every disposition.)*

- **M-1 (MAJOR) — FIXED.** Arity is exact (`sh:205` / `.ps1:244`, through the existing **exit 4**
  path, naming expected *and* actual), and **both design-mandated step-7 literals are restored**
  alongside the spec-derived per-tool checks (`sh:285-286` / `.ps1:341-346`, ordinal `IndexOf` on
  PS). FC-1 re-verified at zero hits afterwards — neither literal carries the token. A new
  executable row (7) in `test_install_bootstrap` (stub truncating `tools` to 3 ids ⇒
  exit 4, nothing written) took the bootstrap block from 30 to **31** assertions and the pinned bash
  tally **353 → 354**, from a captured run.
- **FIXED**: m-1 (separate `write_failed` / `confirm_failed` handlers, `sh:225-230,272-277` ·
  `.ps1:267-272,327-332`) · m-2 (`mkdir`/`New-Item` failure now reaches exit 5, `sh:234` ·
  `.ps1:274-283`) · m-4 (Win32 `-Filter` twin equivalence by exact-name exclusion + `@()`,
  `test-init.ps1:1135-1142`; DEV-7) · m-5 (attribution corrected to **T-12 / v0.44.0 → HEAD**, and
  the archive contradiction settled **empirically**, below) · m-6 (`Test-InstallBootstrap` fixtures
  host-bound, `test-init.ps1:1005-1019`) · n-1 (`while IFS= read -r` over a here-string,
  `sh:181-199`) · n-2 (`chmod` checks `$LASTEXITCODE`, `.ps1:160-170`).
- **DECLINED, recorded**: m-3 — the `& pwsh … 2>&1` native captures under
  `$ErrorActionPreference = "Stop"`; every mitigation changes error semantics in a driver I cannot
  execute, the failure mode is loud, and it is test-driver-only. Promoted to **binding operator
  item 6** with an exact site list (re-enumerated each round; **seven** sites after rework 3).
- **No action, confirmed as read**: n-3 (`exit 1` unreachable but the observable exit is still 1) ·
  n-4 (spec queried before `mkdir`; strictly better — an exit-4 run leaves no directory behind).
- **PM-owned, untouched**: m-7 (`docs/tasks.md` ledger row D11).

Both mirror halves are byte-identical (`diff` clean on all four pairs) and `sync-self --check`
reports **In sync**.

## Implemented, mapped to FR / AC

| Item | Where | Serves |
|---|---|---|
| Spec CLI: `tools`, `event`, `matcher`, `semantics`, `command <tool> <os>`, `hostos`; exit **2** + empty stdout + stderr diagnostic on any unrecognized query/tool/os/arity. Lives in `templates/common/`, so a generated project carries it (ledger A1-A4 + `sync-self` Mapping 9) | `…/templates/common/.harness/scripts/hook-spec.{sh,ps1}` (§3.1) | FR-1, FR-2, FR-4, FR-6, FR-7, AC-1, AC-2, B-1 |
| The four command shapes transcribed verbatim from `upgrade-project`'s helper; tool id interpolated into ` .harness/scripts/<tool>.<ext>` | `hook-spec.sh:100-116`, `hook-spec.ps1:99-113` | FR-3, FR-5, AC-3, AC-4 |
| `settings_hook_state` / `Get-SettingsHookState` — 4-state shallow probe, jq-free, explicit 3-way existence probe | `install-hooks.sh:69-94`, `.ps1:79-100` | B-4, B-5, B-6, B-7, gate Minor 1 |
| §8 truth table, first match wins, rows 1-5 | `install-hooks.sh:96-163`, `.ps1:102-179` | FR-8, FR-9, FR-10, FR-13, AC-5, AC-6, AC-7 |
| W-1 non-swallowing capture (`if ! v="$(…)"` + separate `[ -n ]`), tool list captured **before** the loop | `install-hooks.sh:165-193` | B-2, FC-4 |
| Generated file: canonical `.json` `$schema`, root-only `_comment`/`_hook_semantics`, four real event names, 2-space indent, LF, BOM-free, one trailing `\n` | `install-hooks.sh:236-263`, `.ps1:285-310` | FR-11, B-13, AC-10 (bash half) |
| Temp-then-rename, then terminal confirmation **re-read from disk** | `install-hooks.sh:265-295`, `.ps1:312-359` | B-8, B-10, FC-4 |
| Report: created path + four wired events with the fail-closed call-out + removal command in this shell's form + machine-local/`.gitignore` advisory; no `.gitignore` touched on any path | `install-hooks.sh:297-307`, `.ps1:361-369` | FR-12, B-15, AC-14, NFR-4c |
| Exit codes 0 / 1 (unchanged) / 3 / 4 / 5 | both installers' headers | FR-13, B-5, B-2, B-8 |
| `hook-spec` added to `sync-self` (Mapping 9) and to F.1's hardcoded array **in both shells** + the PS Step label | `sync-self.{sh,ps1}`, `verify_all.sh:284`, `.ps1:269-271` | OQ-6a, AC-11 |
| AC-3 oracle block + installer bootstrap block, both twins | `test-init.{sh,ps1}` | AC-1…AC-7, AC-9 shape |
| Fixture restructure to eight unconditional `EXP_*` / `$exp*` + host re-binding | `test-init.sh:46-93`, `.ps1:33-80` | AC-3 group A′, R-6 |
| Docs: safety-hook disable path (repo + `.tmpl`), dev-map, AI-GUIDE, 40-locations, CHANGELOG `## [0.45.0]` | see files changed | FR-15, FR-16, AC-13 |
| Version fan-out `plugin.json` / `marketplace.json` / both README **version badges only** | — | OQ-7a, AC-12, G.3 |

## Files changed

**New (4)** — `templates/common/.harness/scripts/hook-spec.sh` (the spec / SOT; its header names the
full T-16 hand-off surface incl. the raw-escaping copies) and `hook-spec.ps1` (PS twin:
single-quoted `-f` literals, `$targetOs` to dodge the automatic-variable collision, no here-string),
plus their `.harness/scripts/` mirrors produced by `sync-self`, never hand-written.

**Edited (17)**
- `install-hooks.{sh,ps1}` in **both** halves — the bootstrap; PS pre-commit body moved from `@'…'@` to line-array + `WriteAllText` (OQ-5 / D-2).
- `sync-self.{sh,ps1}` — Mapping 9 + PS header list. `verify_all.{sh,ps1}` — F.1 array element + PS Step label; **no check added/removed/narrowed**.
- `test-init.{sh,ps1}` — fixture restructure, oracle loader, `test_hook_spec` / `Test-HookSpec`, `test_install_bootstrap` / `Test-InstallBootstrap`, plus the pre-existing defect fix below. `baseline.json` — bash tally + `_qa_note_t13`.
- `.harness/rules/75-safety-hook.md` + its `.tmpl` (FR-15); `docs/dev-map.md`, `AI-GUIDE.md`, `.harness/rules/40-locations.md`, `CHANGELOG.md` (FR-16); `plugin.json`, `marketplace.json`, both READMEs — **version string only**.

**Edited in rework 1** — files already listed above (`install-hooks.{sh,ps1}` ×2 halves,
`test-init.{sh,ps1}`, `baseline.json`, `CHANGELOG.md`) plus two **archived** documents annotated
append-only under the coordinator's scope grant (DEV-8):
`_archived/resilient-hooks/04_IMPLEMENTATION.md` (correction block after the `verify_all result`
section, original `278/0` line verbatim above it) and `…/06_QA_REPORT.md` (correction block after
§6's baseline line; original table, totals line and baseline line verbatim above it).
**Edited in rework 2** — `install-hooks.{sh,ps1}` ×2 halves, `test-init.{sh,ps1}`, `baseline.json`,
`CHANGELOG.md`. **Edited in rework 3** — `test-init.{sh,ps1}` and `baseline.json` **only**; no
production file changed.

**Not edited, deliberately**: `docs/tasks.md` (ledger D11 — PM owns it, which also keeps the T-13
ID-collision hazard off my surface); `upgrade-project.*`, `migrate-scripts-layout.*`,
`test-harness-upgrade.*`, both SKILL prose tables (T-16); `.claude/settings.json` and every other
red-line file. Decoys verified below.

## verify_all result

Baseline captured immediately before any edit and again after everything, in **every** round. Only
the two `test-init` tallies ever moved, and only when a round added an assertion — always from a
capture (rework 1: 353 → 354; rework 3: 354 → **355**).

| Driver | Captured (current, rework 3) | Baseline key |
|---|---|---|
| `verify_all.sh` | `PASS: 32  WARN: 0  FAIL: 0`, 32 check lines | `verify_all_checks` 32 — unchanged |
| `test-init.sh` (python3) | `PASS: 391  FAIL: 0`, exit 0 | not a pinned key |
| `test-init.sh` (**no-python3**) | `PASS: 355  FAIL: 0`, exit 0, 3 SKIP | `test_init_bash_no_python3_assertions` **278 → 355** |
| `test-real-project` · `test-harness-upgrade` · `test-verify-i6` · `test-language` | `90/0` · `89/0` · `58/0` · `39/0` | all unchanged; none of those files was edited |
| `test-supervisor.sh` | `46/0` python3-present on this box; `45/0` under the shim | pinned key is the *no-python3* **45** |
| `sync-self --check` / `harness-sync --check` | `In sync.` / no drift | — |

**Delta: 0 new failures, 0 new warnings, check count unchanged at 32.** `[F.1]`, `[F.2]`, `[E.1]`,
`[J.1]`, `[G.3]`, `[G.4]` all PASS in the final run, made **after** the dogfood bootstrap, so AC-8 is
satisfied from the bootstrapped state. The no-python3 condition was produced with a
`python3` shim that exists but exits non-zero — exactly the Microsoft-Store-stub reality the driver's
own probe is written for.

**Tally decomposition (checkable, not asserted)** — from the captured run, not from this document:
`278` pre-existing (unchanged, R-6 satisfied) `+ 77` new T-13 (45 spec block + 32 installer block)
`= 355`. Two independent corroborations: `391 − 355 = 36 = 3 × 12`, the documented per-type size of
the python3-gated AI-native block; and the pre-change driver, once un-truncated, itself captures
exactly **278** (evidence below).

## Pre-existing defect found and fixed (not in the design — flagged for review)

*(Compacted in rework 3; the reviewer re-derived and granted the whole account in
`05_CODE_REVIEW.md` §4, which holds the long form.)*

`DEFECT-DEV-1` · `test-init.sh` at HEAD `cb0ed57`. The two `[T-020] … OS-picked variant` assertions
interpolated a `*_COMMAND` value into the string `assert()` **evals**. On a unix host that value
contains single quotes, so eval's quoting ended mid-value and the driver ran
`exec bash .harness/scripts/ambient-prompt.sh` **on itself** — every later assertion, the whole zh
block included, silently never executed. Invisible on MSYS, where the OS-picked value is the `pwsh`
form and carries no single quote. **Exposure window: T-12 / v0.44.0 → HEAD** (corrected in
rework 1): the single-quote-bearing unix byte-form arrived with `upgrade-project.sh:112-114` in
T-12; the `[T-020]` rows are older than T-12 and were harmless until that commit.

**Before / after, captured.** `cb0ed57` was extracted into a scratch **git worktree** and run
unmodified here: last line `PASS [T-020] every settings hook command path exists on disk (AC-5)`,
then `EXIT=1` — 72 PASS lines, 0 FAIL, **no `=== Result ===` line**, empty stderr. With **only** the
eval fix applied to that same pre-change driver and the no-python3 shim on `PATH`:
`PASS: 278 / FAIL: 0`, `EXIT=0`, 3 SKIP.

**Which record is wrong.** The reviewer flagged a contradiction with this repo's archive
(`_archived/resilient-hooks/04_IMPLEMENTATION.md:122`, `06_QA_REPORT.md:138,145,148` report a *bash*
`test-init.sh 278/0` for T-12). The capture settles it empirically: **that archived run record is
the wrong one** — a truncated driver cannot print a summary line. The tally was hand-derived as
276 + 2; the *value* 278 is right, the *run* never happened. **My own sub-claim that "the pinned 278
was a complete tally on Windows" was equally unverified and is withdrawn.** Both archived documents
are annotated in place (original text verbatim, correction appended). This is the **second**
occurrence of the failure mode already at `.harness/insight-index.md:12`; see "Insight to surface".

**Why I fixed it rather than reporting it**: my new blocks run after that point, so with the defect
live the design's own mandatory captured run (AC-3, AC-5) is unobtainable on any unix host. The fix
is minimal and semantics-preserving — `grep` directly, assert on the resulting flag; *what* is
asserted is unchanged. The PS twin was never affected (scriptblocks, not `eval`) — `.ps1:379-384`.

## AC-3 evidence — 8 × (tool, OS) against the live oracle

Oracle = `resilient_cmd` extracted by awk range + `eval` from `upgrade-project.sh` (never sourced —
that file `exit 1`s at load). Independent for all 8; **none host-OS-only**, because the helper takes
the OS as a parameter. In the captured `test-init.sh` run the `[T-13][oracle]` anti-vacuity row and
all **8** `[T-13][A] command <tool> <windows|unix> is byte-equal to the live resilient_cmd oracle`
rows are **PASS** — and it is a *call-through*, so a missed extraction fails that named row rather
than passing the eight silently. Groups A′ (8, lockstep-only, labelled as such), B (4 semantics + 2
fail-closed), C (8 congruence-ERE extractions), D (8 event/matcher + `tools` order + `hostos`) and
E (3 empty-stdout/non-zero rows) are all PASS in the same run.

Two additional **source-level** lockstep checks (no substitute for the operator's PS run): the four
PS `Get-HookSpecCommand` literals are **byte-identical** to `upgrade-project.ps1`'s
`Get-ResilientCmd` literals (4/4, diff clean), and the eight `test-init.ps1` fixture literals are
**byte-identical to the committed ones** (8/8) — the restructure is a pure re-binding.

## FC-1…FC-4 — the guard is still fail-CLOSED

*(Re-run in full after every round, most recently rework 3.)*

| # | Command run | Result |
|---|---|---|
| FC-1 | `grep -n 'guard-rm'` over **all four** installers | **zero hits** (grep exit 1). Neither restored step-7 literal carries the token; the value comes only from the loop over `hook-spec tools` (`install-hooks.sh:168,178,184` / `.ps1:63,215,221`) |
| FC-2 | `grep -nE '^[^#]*(\$\{[A-Za-z_]+//\|sed \|-replace\|\.Replace\()'` over both installers + both specs, all four halves | **zero hits on any code line** (raw hits are comment text). The value reaches the JSON body by plain expansion (`sh:255` / `.ps1:303`) and is compared unmodified (`sh:293` / `.ps1:356`) — **B-12 is unreachable, not merely handled** |
| FC-3 | live `command guard-rm windows\|unix`, scanned for a fallback | `\|\| exit 0` absent · `exit 0` absent · `-EA SilentlyContinue` absent, both OS; `-NoProfile` ×2 on Windows (NFR-3). The same two byte-forms are asserted on **live output** every run by `[T-13][B]` |
| FC-4 | `grep -n 'HARNESS_ALLOW_OUTSIDE_RM'` over both installers + both specs | **zero hits**. Every exit between "decided to bootstrap" and "confirmed on disk" is non-zero: `sh:172` exit 4 (`spec_fail`) · `:229` exit 5 (`write_failed`) · `:276` exit 5 (`confirm_failed`). The only exit 0 after step 5 is the step-8 report, reached **only** after the step-7 re-read-from-disk confirmation (tmp write `:265`, rename `:266`, literal greps `:285-286`, per-tool greps `:289-293`) |

ALL-FOUR-OR-NOTHING is enforced on **both axes**, each through the design's exit 4 naming expected
*and* actual: `sh:205` `(( n_wired == 4 ))` (ids) + `sh:214` `(( n_distinct == 4 ))` (events) /
`.ps1:244` `-ne 4` + `.ps1:256` `$nDistinct -ne 4`. **Both axes are now asserted executably**, one
`test_install_bootstrap` row each (rows 7 and 8, the latter added in rework 3), each proven
load-bearing by deletion mutation.

## AC-5 / AC-6 / AC-9 / AC-14 — dogfood evidence on this repo

**AC-5 / AC-6 / AC-8 / AC-14** — compacted in rework 3: §"Rework round 3" carries the current
end-to-end re-run verbatim (delete → install → exit 0 with all three FR-12 elements → `cmp`
BYTE-IDENTICAL → second run byte-untouched, no sibling → no `.gitignore` line, `!!` ignored →
`verify_all` 32/0/0 from the bootstrapped state). **NFR-1**: all four `"command"` values equal the
hand-written T-12 file's, byte-for-byte.

**AC-9**, driven through the PreToolUse command **parsed back out of the generated file** (behind an
anti-vacuity check: non-empty and names `guard-rm.sh`): `rm -rf /tmp/hk-outside-probe` and
`rm -rf ~/Documents` → exit **2, BLOCKED** (*"destructive command targets path outside project
root"*); `rm -rf node_modules`, `rm -rf docs/features/_scratch`, `git status` → exit **0, ALLOWED**;
the same wired command with the **guard script absent** (throwaway tree) → **127, BLOCKED** —
fail-CLOSED, never a silent allow.

**Decoys (design §11) — all 12 verified byte-untouched**: `10-self-consistency.md`, the three
`SKILL.md`s, `docs/v0.11-changes.html`, `evals/golden-tasks.md`, `.gitignore`,
`.claude/settings.json`, `.harness/insight-index.md`, `upgrade-project.*`,
`migrate-scripts-layout.*`, `test-harness-upgrade.*`. Historical CHANGELOG 7-count lines intact,
zero historical `## [x.y.z]` headings removed, README diff is the **version badge only**
(`verify__all-32%2F32` + `test--init-316%2F316` unchanged in both), the five live mirror-set sites
all read 8, and no live "7 script pairs" claim survives outside CHANGELOG history.

## Design drift / deviations (all additive, none weakening)

| # | Deviation | Why | Risk |
|---|---|---|---|
| DEV-1 | **`DESIGN DRIFT`** — fixed the pre-existing `test-init.sh` eval quote break-out (section above) | the design's own mandatory captured runs are unobtainable on a unix host without it; the driver was `exec`ing itself away | none: *what* is asserted is unchanged; PS twin untouched |
| DEV-2 | §3.2 step 0b's role-dependent answer is implemented as an explicit non-regular pre-check at the **committed** call site (`install-hooks.sh:99-103`, `.ps1:105-110`), keeping `settings_hook_state <path>` single-argument | the designed behavior is role-dependent but the designed signature is not; a call-site pre-check delivers the exact §8 row-1/row-3 outcomes without widening the signature | none: behavior is exactly as specified (probe-tested) |
| DEV-3 | Added `$PSNativeCommandUseErrorActionPreference = $false` to `install-hooks.ps1` and to both new PS test blocks | the **PS analogue of W-1**: PowerShell 7.4+ turns a non-zero *native* exit code into a terminating error under `$ErrorActionPreference = Stop`, which would pre-empt the designed `exit 4` exactly as `set -e` does in bash. The design's W-1 section only covers bash | none: scoped to the file/function; makes the designed exit codes reachable |
| DEV-4 | ~~The step-7 confirmation derives `"PreToolUse"` / `"matcher": "Bash"` from the spec's own answers instead of hard-coding them~~ — **WITHDRAWN in rework 1 (M-1).** The two design-mandated literals are restored alongside the spec-derived checks, and the arity check is `== 4`, not `> 0` | the reviewer was right: neither literal contains `guard-rm`, so FC-1's zero-hit grep never required dropping them, and `> 0` let a short tool list produce a partial wiring that exited 0 | none — see rework section |
| DEV-5 | Every **emitted** installer message is pure US-ASCII in both twins (three em-dashes → `-`); comments keep them | insight 2026-06-12: `pwsh` stdout follows the host ANSI codepage, so an em-dash in a report line reaches a UTF-8 consumer as mojibake on a zh-CN box — and the two shells would then emit different bytes for the same report | none |
| DEV-6 | `docs/tasks.md` (ledger row D11) **not** edited | PM owns that file and updates both the active row and the completion entry; this also removes the T-13 ID-collision hazard from my surface | none — flagged so PM does not assume it is done |
| DEV-7 | **rework 1** — `test-init.ps1`'s AC-6 sibling row excludes `settings.local.json` by exact name and wraps the result in `@()` (m-4) | the Win32 wildcard engine's legacy `name.*` semantics are not `find -name`'s; the bash twin can never match the target itself, so this makes the twins equivalent **by construction** instead of by hope. Strictly a symmetry fix — the assertion's meaning ("no temp/backup sibling survives") is unchanged and nothing legitimate is hidden | PS is unexecutable here, so it is also kept as binding operator item **#7** |
| DEV-8 | **rework 1** — two **archived** T-12 stage documents were annotated (original text preserved, correction appended) | the archive contradiction the reviewer found was surfaced by this row, and leaving a knowingly-false captured-run claim in the repo would re-seed it; scope granted by the coordinator for this row only. The DO-NOT-TOUCH decoy list is a different surface and stayed frozen | none — append-only annotation, no historical number rewritten |

No design decision was taken; nothing in the design was overridden. No test was deleted or narrowed.

## Gate advisories A-1…A-8 — disposition

**A-1 Done** — the spec header's T-16 pointer list cites `test-harness-upgrade.ps1:296,299` (both
branches) alongside `.sh:296,306`. **A-2 Done** — both twins' spec blocks carry a `SCOPE NOTE`: the
oracle reads `upgrade-project`'s copy only; `migrate-scripts-layout.{sh:117,ps1:36}` holds a second,
uncompared copy (the spec header lists it too). **A-3 Done** — PS anti-vacuity is
`Get-ResilientCmd guard-rm $true` → non-empty **and** contains `guard-rm.ps1`, as a call-through.
**A-4 Acknowledged** — the `eval` of extracted text is new here; re-verified before use (awk range
prints `upgrade-project.sh:102-117` inclusive, the body declares `local rc_tool rc_win` and touches
nothing else, `eval` is not on I.6's banned list, no driver shadows `resilient_cmd`). **A-5 Done** —
the `git status` evidence comes from the **dogfood** run, not the fixture. **A-6 Closed by FC-4** —
zero `HARNESS_ALLOW_OUTSIDE_RM` hits. **A-7 Verified untouched** — `docs/v0.11-changes.html`,
`evals/golden-tasks.md` byte-unmodified. **A-8 Carried** — operator item 4 / `_qa_note_t13`:
`verify_all.ps1:290-291` hard-parses the generated file where `verify_all.sh:304` only greps.

## What I could NOT verify — PowerShell (NFR-5)

**PowerShell is not executable in this runtime** (`which pwsh` → not found). Every `.ps1` I touched
is **green-by-symmetry-only**. Mechanically checked instead: PS command literals diffed byte-for-byte
against the live `Get-ResilientCmd`; the eight PS fixtures diffed against the committed ones; the PS
pre-commit line array diffed line-for-line against the bash heredoc (27 = 27); brace/paren balance
unmoved; no `Set-Content` / `Out-File` on any code line; no here-string left in `install-hooks.ps1`;
no parameter collides with an automatic variable. None of that substitutes for running it.

**Mandatory operator verification items (binding, for 07_DELIVERY):**

1. `[…Language.Parser]::ParseFile` on every touched `.ps1`: `hook-spec.ps1` (template + repo),
   `install-hooks.ps1` (template + repo), `test-init.ps1`, `sync-self.ps1`, `verify_all.ps1`.
2. `pwsh -File .harness/scripts/install-hooks.ps1` in a clone with `.claude/settings.local.json`
   deleted: exit 0, file created with the **Windows** byte-forms, FR-12 report, idempotent re-run.
3. `test-init.ps1` — confirm `Test-HookSpec` and `Test-InstallBootstrap` are green, then **reconcile
   `test_init_ps_assertions`** (still pinned at **316**, deliberately unreconciled) and only then move
   the README `test--init-316%2F316` badge. Both READMEs move together.
4. `verify_all.ps1` — it hard-parses the generated `settings.local.json` with `ConvertFrom-Json`
   (advisory A-8) where the bash twin only greps: the only place a malformed generated file surfaces.
5. **AC-10 cross-shell byte-identity** of the generated `settings.local.json` (and of the generated
   pre-commit hook) is unproven until step 2 runs and the bytes are `cmp`-compared against the bash
   twin's output on the same host.
6. **(m-3, rework 1; site list re-enumerated in rework 3 — CR r-7 / QA n-8)**
   `test-init.ps1:1073,1120,1161,1180,1215,1246,1256` — **seven** `& pwsh … 2>&1` **native-command**
   captures under script-scope `$ErrorActionPreference = "Stop"`. `2>&1` on a native command is new
   here, and `$PSNativeCommandUseErrorActionPreference` governs exit-code→error conversion, **not**
   stderr→`NativeCommandError`. Rows `:1161` (exit 3), `:1215` (exit 4, arity),
   `:1246` (exit 4, distinct events) and `:1256` (exit 1) deliberately drive the installer's stderr
   paths. If PS raises there the throw escapes `Test-InstallBootstrap`'s `try`/`finally`, is caught
   by no `Assert`, and kills the driver mid-run. **Confirm the driver reaches its own
   `=== Result ===` line**; if it does not, wrap those captures so stderr cannot raise.
7. **(m-4, added in rework 1)** `test-init.ps1:1140` `Get-ChildItem -Filter "settings.local.json.*"`
   uses the Win32 wildcard engine, whose legacy `name.*` semantics differ from the bash twin's
   `find -name` (`test-init.sh:938`). The target is now excluded by exact name (DEV-7), making the
   twins equivalent by construction — **confirm the AC-6 sibling row is green on Windows**.
8. **(added in rework 2 — the QA-flagged conditional 8th, now unconditional; widened in rework 3)**
   the four-distinct-events gate `install-hooks.ps1:245-259` and **both** FC-4 rows —
   `test-init.ps1:1190-1221` (arity) and `:1223-1252` (distinct events, added in rework 3) — are new
   PS code that **only the bash twins were executed for**. Include `install-hooks.ps1` (template +
   repo) in item 1's `ParseFile` sweep and **re-run item 2 after this patch**. Three PS-specific
   points to confirm: `Sort-Object -Unique` is case-insensitive (stricter, never looser — bound
   n-11); the diagnostic uses `-f` because `-join` binds **looser** than `+`, so
   `"a" + $n + ($x -join ' ')` would silently re-associate into `("a" + $n + $x) -join " …"`; and
   `Test-InstallBootstrap` is now **32** `Assert` calls, matching the bash twin — the number to
   reconcile `test_init_ps_assertions` against in item 3. **Eighth and last — no ninth.**

## Rework round 2 — QA (PASS WITH DEFECTS: r-1, r-6, r-2, n-6)

| Finding | What changed | Where |
|---|---|---|
| **r-1 + r-6 + the mixed-duplicate case** | Added a **four-DISTINCT-events** gate immediately after the `== 4` arity gate, routed through the same `spec_fail`/`Stop-OnSpecFailure` → `exit 4` path. Arity counts *ids*; this counts *events*. Because each tool maps to exactly one event and there are only four tools, an id set that drops the destructive-command guard can only reach 4 by repeating another tool — so r-6's row is caught here too, and the refusal happens **before** the write, which is why the guardless residue never comes into existence. §8 row 3 is untouched, as required. | `install-hooks.sh:205-214` · `.ps1:244-259`, all four mirror halves |
| **r-2** | The FC-4 row no longer accepts *any* exit 4: it captures the installer's output and additionally matches the arity branch's own diagnostic `expected 4 ids, got 3`. Non-vacuous by construction; assertion **count unchanged** (folded into the existing `assert`, no new row). | `test-init.sh:974-993` · `.ps1:1190-1222` |
| **n-6** | Exit-code header now distinguishes the two exit-5 sub-paths: on the **write** path the target is left ABSENT; on the **terminal-confirmation** path the rename already succeeded, so it is left present-but-unconfirmed and the diagnostic says so. | `install-hooks.{sh,ps1}:31-35`, all four files |

### Adjudicated additionally (nothing silent)

- **FIXED (mine).** My first draft of the new comment used the literal token `guard-rm` and broke
  **FC-1's zero-hit grep** in all four installers. Reworded to "the destructive-command guard";
  FC-1 re-verified at **zero hits** afterwards.
- **FIXED — defect in the form I was handed.** QA supplied only the PS *count* expression. My first
  PS diagnostic read `"…" + $n + ": " + ($wired | …) -join ' ' + ")"`, which is wrong: `-join` binds
  **looser** than `+`, so it re-associates. Rebuilt with `-f`, the file's existing idiom
  (`install-hooks.ps1:365` — corrected in rework 3, CR n-8; `:347` is the step-7 `for` header). Same
  class: the PS FC-4 capture joins an array by hand rather than `| Out-String`, which re-wraps at the
  host buffer width and could split the matched phrase.
- **DECLINED, recorded.** BSD/macOS `wc -l` pads (`got        1`) — cosmetic only, the arithmetic
  comparison is unaffected, and bare `wc -l` is this repo's convention on both supported hosts.
- ~~**DECLINED by mandate.** The distinct-events gate has no in-suite regression row, because the
  assertion count had to stay unmoved.~~ — **WITHDRAWN in rework 3**: that constraint came from the
  round-2 dispatch brief, not from the scope bar (OQ-9a / §3.6 forbid a new *driver pair*, not a new
  assertion, and rework 1 had already moved this key 353 → 354 from a capture). Row landed, below.
- **CHANGELOG.md:29-33 corrected** — the same n-6 falsehood sat in a live release claim; the exit-4
  description now also names the distinct-events refusal (T-13's own section, not a historical
  heading). `baseline.json:_qa_note_t13` gained the eighth operator item; **no numeric key moved** in
  round 2 — every pinned tally was re-captured identical.

### Captured re-verification, round 2 *(historical — both `test-init` tallies moved +1 in rework 3, whose section carries the current numbers)*

`verify_all` 32/0/0 (32 check lines) · `test-init.sh` 390/0 (py3) and 354/0 (no-py3, 3 SKIP) ·
90/0 · 89/0 · 58/0 · 39/0 · 45/0 · both `--check`s `In sync.` exit 0. The 7-row degradation matrix
was re-measured against the patched installer with the same result the rework-3 re-measurement
below reproduces. **r-2 proven non-vacuous in both directions, full-suite**: QA's r-2b mutation
(stub `hs_good` repointed at a nonexistent path) gives **389 / 1** with the FC-4 row the *only* red
(it was 390/0 green before), and the r-2a mutation (arity → `> 0`, gate left in) also **389 / 1**,
same single red — the anti-revert property survives, now carried by the diagnostic rather than the
exit code alone. *(Re-measured in rework 3 at 354/1, same single red.)*

FC-1…FC-4 were re-verified after the round-2 change and again in rework 3 (table above). Nothing in
round 2 or 3 touches `guard-rm.{ps1,sh}` or `hook-spec.{ps1,sh}`, so NFR-2's 6×10 probe is
unaffected and was **not** re-run — I claim no re-measurement of it. **Design drift: none** — §8
row 3 is byte-untouched and the fix is an earlier refusal inside row 5, exactly as FC-4 ("all four
**events** or nothing") reads.

## Rework round 3 — CR round 3 (APPROVED WITH NITS) + QA round 2 (PASS WITH DEFECTS)

**No production code changed this round.** The four installer and two spec files are byte-identical
to what CR round 3 approved (`sha256 b543f2da…` on both `install-hooks.sh` halves before and after;
all four mirror pairs `diff`-clean; `sync-self --check` `In sync.`). The change set is one new test
row per twin, the baseline it moves, and documentation.

| Finding | What changed | Where |
|---|---|---|
| **QA r-7 (MINOR)** — the distinct-events gate had **no anti-revert coverage** (QA deleted both gate lines from both bash halves and got a fully green 390/0 + 32/0/0) | One new in-suite row per twin, row (8) of `test_install_bootstrap`. It mutates the **artifact**: a stub answering `tools` with the guard id **four times** (4 ids → 1 distinct event) and delegating every other query, then asserts **exit 4 + target ABSENT + the distinct-gate diagnostic** `expected 4 DISTINCT hook events, got 1`. Same anti-vacuity construction as the hardened r-2 row, so it cannot pass on an unrelated exit 4. | `test-init.sh:996-1018` · `test-init.ps1:1223-1252` |
| **CR r-7 / QA n-8 (MINOR)** — `baseline.json:_qa_note_t13` operator check (a) still cited `test-init.ps1:…,1207,1216` | Re-enumerated the **whole** site list from the current file rather than patching two numbers: `1073, 1120, 1161, 1180, 1215, 1246, 1256` — **seven** `& pwsh … 2>&1` native captures (the round-3 row adds `:1246` and shifts the tail). Operator item 6 below carries the identical list. | `baseline.json:_qa_note_t13` |
| **CR n-8 (NIT)** | `-f` idiom cite corrected `.ps1:347` → **`install-hooks.ps1:365`**. | rework-2 section above |
| **CR n-9 (NIT)** | The three stale rows in "Implemented, mapped to FR / AC" re-derived from the current files: Generated file `sh:236-263` / `.ps1:285-310`; Temp-then-rename + confirmation `sh:265-295` / `.ps1:312-359`; Report `sh:297-307` / `.ps1:361-369`. | that table |

**The decline PM withdrew.** Rework 2 declined this row on the ground that the assertion count had
to stay unmoved. That constraint came from the dispatch brief, not the scope bar; QA is right that
no such rule exists. The bullet is struck through above rather than deleted, and the count moved —
**from a capture**, never hand-derived.

### The new row is load-bearing — deletion mutations, captured

Mutations applied to **both** bash halves, restored from a pre-mutation copy and re-hashed identical
(`b543f2da…`) after every run. Control = the unmutated tree at **355 / 0**.

```
control (no mutation)                                PASS: 355  FAIL: 0
A  both gate lines deleted (install-hooks.sh:213-214) PASS: 354  FAIL: 1  <- the new row, ONLY red
B  only the comparison deleted (:214)                 PASS: 354  FAIL: 1  <- the new row, ONLY red
C  only the count deleted (:213)                      PASS: 338  FAIL: 17 <- new row red among them
D  arity reverted to `> 0` (:205, gate left in)       PASS: 354  FAIL: 1  <- the r-2 ARITY row red,
                                                                            the new row still PASS
```

A and B are the property QA asked for: revert the gate and exactly one row goes red, and it is this
one. C is the `set -u` blow-up (`n_distinct` unbound) — load-bearing, noisily. **D shows the two rows
partition the two gates**: the arity row pins the id axis, the new row the event axis, neither
covering for the other.

### Captured re-verification (rework 3 — every number from a run I made this round)

```
verify_all.sh          PASS: 32  WARN: 0  FAIL: 0   exit 0, 32 check lines  (re-run AFTER the dogfood)
test-init.sh (py3)     PASS: 391  FAIL: 0  exit 0   test-init.sh (no-py3) PASS: 355 FAIL: 0 exit 0, 3 SKIP
test-real-project 90/0 · test-harness-upgrade 89/0 · test-verify-i6 58/0 · test-language 39/0
test-supervisor (no-py3) 45/0   sync-self --check "In sync." 0   harness-sync --check "In sync." 0
```

**Baseline moved, from that capture**: `test_init_bash_no_python3_assertions` **354 → 355**; the
`_qa_note_t13` decomposition re-derived to `278 + 45 + 32 = 355` with `391 − 355 = 36 = 3 × 12`
intact. **No other numeric key moved** — `verify_all_checks` **32**, `test_init_ps_assertions`
**316** (deliberately unreconciled). Both README badges frozen: `verify__all-32%2F32` and
`test--init-316%2F316` byte-unchanged in both files (the `test--init` badge tracks the **PowerShell**
count, which does not move here). `docs/tasks.md` untouched.

**7-row degradation matrix, re-measured this round** in an independent scratch tree (only
`install-hooks.sh` + `hook-spec.sh` + a bare `.git` + an empty-hooks committed settings), artifact
mutated, **both runs per row** — identical to round 2:

```
1 four distinct        run1+run2 exit 0 PRESENT, all four events on disk
2 four dupes w/guard   run1+run2 exit 4 ABSENT "expected 4 DISTINCT hook events, got 1: PreToolUse x4"
3 four mixed dupes     run1+run2 exit 4 ABSENT "...got 3: Stop PreToolUse PreToolUse SessionStart"
4 four ids, no guard   run1+run2 exit 4 ABSENT "...got 3: Stop Stop UserPromptSubmit SessionStart"
5/6/7 3 ids · 5 ids · one bogus id  run1+run2 exit 4 ABSENT ("expected 4 ids, got 3" / "got 5" / unrecognized tool)
```
Row 1's file in that scratch tree hashes to `sha256 536f3e01…b49a9` — the live file's bytes, derived
in a tree that shares no state with it.

**Live dogfood, end-to-end, re-run**: `rm .claude/settings.local.json` → install → **exit 0** with
the full FR-12 report (created path · four `event -> tool (semantics)` rows incl. `PreToolUse ->
guard-rm (fail-closed)` · `Remove: rm <abs path>` · machine-local/`.gitignore` advisory) → `cmp` vs
the pre-delete snapshot **BYTE-IDENTICAL** at
`sha256 536f3e0125cb58592ee2ab00883845356409b9764595c0966f32be507d9b49a9` → second run "left
byte-untouched, no backup written", exit 0, still byte-identical → **0** `settings.local.json.*` /
`*.bak*` / `*.tmp*` siblings → `git status --porcelain -- .gitignore` and `git diff --stat --
.gitignore` both **0 lines**, `git check-ignore -v` → `.gitignore:60`, status `!!`. `verify_all` was
then re-run **from that bootstrapped state**: 32 / 0 / 0 (AC-8).

### QA n-7 (NIT) — decided: recorded as a known bound, not closed

The bash gate counts **lines** (`printf … | sort -u | wc -l`), so an `event` answer carrying an
embedded newline (`SessionStart\nUserPromptSubmit`) yields 5 lines / 4 unique and slips through.
**Decision: record, do not patch.** Reason: closing it needs new validation in all four installer
halves — two of them PowerShell I cannot execute — to defend against a spec that has already broken
its own single-token totality contract (`hook-spec.sh:30-32`); that contract, not the installer, is
the defect's home, and a strictly-narrower-than-r-1 hardening is not worth fresh unverifiable PS
code in the final round.

### Known bounds + records to carry into `07_DELIVERY.md`

- **n-10 (CR)** — the distinct gate's closure of r-6 assumes `hook-spec` has **exactly four** tools.
  A future **fifth** tool with a fifth distinct event would let a guardless 4-id answer satisfy
  `n_distinct == 4`, be written, then fail step 7 → exit 5 with a guardless file present, which §8
  row 3 blesses at exit 0 on the next run. Requires **adding** to the spec, not degrading it. Owner:
  solution-architect **if** a fifth tool is ever specced.
- **n-11 (CR)** — `sort -u` is case-sensitive, `Sort-Object -Unique` is not: on a *mutated* spec
  answering e.g. `Stop`/`stop` the PS twin refuses where bash proceeds. Stricter on PS, never
  looser; disclosed in the code comment (`.ps1:251-252`) and in `_qa_note_t13`. Record-only.
- **n-7 (QA)** — the line-vs-answer bound above, with its reason. Record-only. **n-12 (CR)** —
  superseded: the decline it accepted is withdrawn and the row landed.
- **The eight binding NFR-5 operator items verbatim** (list above), the **DEV-8 coordinator scope
  grant** for the archived-document annotation — without which that edit would have been
  out-of-scope, so it must be on the delivery record for any later audit — and the
  **tally-fabrication second-occurrence insight** for `.harness/insight-index.md` at archive time
  (not appended now: that file is a DO-NOT-TOUCH decoy until `archive-task` runs).

### PowerShell (NFR-5) — still **eight** items, **no ninth**

`pwsh` remains absent (`which pwsh` → not found). The new PS row at `test-init.ps1:1223-1252` is
**green-by-symmetry-only**; I claim no PS verification of it. It adds **no ninth** operator item — it
*widens three existing ones*, in place rather than by appending: item **3** (the driver has one more
row; `Test-InstallBootstrap` is 32 `Assert`s per twin, the number to reconcile
`test_init_ps_assertions` against), item **6** (site list 6 → **7**), item **8** (the gate's PS-side
coverage is now two rows, both unexecuted here). The same widening is mirrored into
`baseline.json:_qa_note_t13`, the copy that travels to the operator. Items 1, 2, 4, 5, 7 are
unchanged and still binding.

## Dev-map updates

No structural change in rework 1, 2 or 3 — no file was added, moved or removed in any rework, so
`docs/dev-map.md` needs no further edit beyond the round-0 rows below.

- Template **and** repo script trees: new `hook-spec.{ps1,sh}` rows; the `install-hooks` row notes
  the bootstrap. `.claude/settings.local.json` row **appended**: installer-regenerable from the spec,
  and an empty hooks object keeps hooks off (`(T-12 v0.44)` attribution left intact).
- "Two layers of consistency" `7 script pairs` → `8`, and both
  `sync-self touches only the 7/8 script pairs` parentheticals → 8.
- `## Reusable utilities`: Layer-1 row → 8 pairs with `hook-spec` added to the name list, **plus a new
  `Hook wiring spec` row** describing the CLI, the totality contract and the fail-closed split.

## Insight to surface

- A cross-shell test-driver assertion that string-interpolates a *value* into a condition the driver later `eval`s is host-conditionally self-destructing: this repo's `test-init.sh` `[T-020]` rows had been running `exec bash .harness/scripts/ambient-prompt.sh` **on the driver itself** on every unix host from T-12 / v0.44.0 onward — silently skipping every later assertion and printing no summary line at all — while staying invisible on MSYS because only the unix byte-form contains single quotes. Assert on a precomputed flag, never on an eval'd string carrying a shell-command value. · evidence: `cb0ed57` run from a scratch worktree stops after 72 PASSes with no `=== Result ===` line, exit 1; with only the eval fix it prints `PASS: 278`; fixed tally 278 → 355 = 278 pre-existing + 77 new
- **Tally fabrication has now happened twice** — a pass/fail number that no run ever produced survived into a stage doc again: T-12's archived `test-init.sh 278/0` **bash** result (`_archived/resilient-hooks/04_IMPLEMENTATION.md:122`, `06_QA_REPORT.md:138,145,148`) was hand-derived as 276 + 2 on a box where the driver provably could not reach its summary line. The number was right, which is exactly why nobody noticed. A reviewer cross-checking a tally against the *archive* — not just against arithmetic — is what surfaced it, and only re-running the pre-change artifact settled it. Cross-check every reported tally against the artifact that allegedly produced it. · evidence: `.harness/insight-index.md:12` (2026-06-04, first occurrence) + the two annotated archive files above

## Verdict

**READY FOR REVIEW** (rework round 3 complete)

`verify_all` **PASS 32 / WARN 0 / FAIL 0** (32 check lines, re-run from the bootstrapped state);
`test-init.sh` **391 / 0** (python3) and **355 / 0** (no-python3, 3 SKIP); the other five bash drivers
green at their pinned baselines (90 · 89 · 58 · 39 · 45); both `--check`s `In sync.` The guard is
fail-CLOSED on every path with FC-1…FC-4 re-verified and the 7-row degradation matrix re-measured;
the generated file is still byte-identical at `sha256 536f3e01…b49a9`. **AC-10 and the PowerShell
half of everything remain green-by-symmetry-only**, carrying **eight** binding operator items.

Rework 1: **M-1 fixed** — `== 4` arity through the design's `exit 4` path, both step-7 literals
restored alongside the spec-derived checks, both shells, both mirror halves; the archive
contradiction **settled empirically** and both archived documents annotated append-only.
Rework 2: **r-1, r-6 and the mixed-duplicate case closed by construction** — a four-distinct-events
gate refuses *before* the write, so the guardless residue §8 row 3 would have blessed cannot come
into existence; row 3 and the happy-path bytes untouched. **r-2** closed by matching the arity
diagnostic, non-vacuous in both directions. **n-6** corrected in all four headers and the CHANGELOG.

Rework 3: **r-7 closed** — the distinct-events gate now has in-suite anti-revert coverage, one row
per twin, mutating the *artifact*; deleting the gate turns exactly that one row red (354/1), and the
arity revert still turns exactly the r-2 row red, so the two rows partition the two gates. The
baseline moved **354 → 355 from that capture**, and `_qa_note_t13`'s operator site list was
re-enumerated whole (seven sites) rather than patched. **n-7 decided and recorded** with its reason;
**n-10, n-11** recorded; **n-8, n-9** citation fixes landed; the withdrawn rework-2 decline is
struck through in place rather than deleted. **No production code changed this round** — all four
installers and both specs are byte-identical to what CR round 3 approved. No out-of-scope file was
touched, no decoy moved, both README badges frozen, `docs/tasks.md` untouched, no tally hand-derived.
