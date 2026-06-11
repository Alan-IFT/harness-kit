# Test Report — sync-hook-dangling-ref (T-020)

Mode: full · QA: qa-tester · Date: 2026-06-11
Upstream: `01_REQUIREMENT_ANALYSIS.md` (AC-1..AC-8, B1–B12) · `02_SOLUTION_DESIGN.md` (§10, AC-9)
· `03_GATE_REVIEW.md` (C1–C4) · `04_DEVELOPMENT.md` (incl. rework round 1) · `05_CODE_REVIEW.md`
(APPROVED-WITH-NOTES; AC-7 cross-shell `cmp` + B8/M3 probe confirmation routed to QA).

Every number below is from a captured run on this machine (Windows 11, Git-Bash + pwsh 2026-06-11).
No tallies were copied from 04 — the regression battery was re-run independently.

## Test plan (per acceptance criterion)

| Criterion | Test case(s) | Where | Verdict |
|---|---|---|---|
| AC-1 RC-1 migrate fixture | suite fixtures M1/M2/M3 + QA independent reproducer (probe 2: dry-run + apply, both shells) | `test-harness-upgrade.{sh,ps1}` + probe 2 | **PASS** |
| AC-2 dangling repair + rerun no-op | suite fixtures H/H2 + QA user-scenario replay (probe 1: dry-run, apply, hook fire, re-run) | `test-harness-upgrade.{sh,ps1}` + probe 1 | **PASS** |
| AC-3 diagnosis (status §3c + healthy v0.30 fixture) | prose surface text-verified (`harness-status/SKILL.md:89-110,155`: ok / not wired / DANGLING / MALFORMED / interpreter WARN; retired asset rows gone, plugin-provided note at `:34`); deterministic half via generated E.3/E.4b runs (probe 1 §5) + test-real-project healthy legs | SKILL grep + probe 1 + `test-real-project.{sh,ps1}` | **PASS** (prose half is text-verified — model-executed steps are not mechanically runnable) |
| AC-4 consumer verify_all FAIL/PASS rows | generated generic `verify_all.{sh,ps1}` run healthy (E.3 PASS, E.4b PASS) and dangled (E.4b FAIL naming path + fix), both shells (probe 1 §5–6); backend D.3/D.4b via test-real-project both shells | probe 1 + `test-real-project.{sh,ps1}` | **PASS** |
| AC-5 init/adopt invariant + mutation probe | `test-init.{sh,ps1}` (congruence assert, OS-picked ambient asserts, delete-harness-sync mutation probe) — bash 270/0, ps 308/0; init 10b / adopt step-6 prose verified (`harness-init/SKILL.md:406,495`, `harness-adopt/SKILL.md:198,249-250,311-314,324-333`) | suite + SKILL grep | **PASS** |
| AC-6 settings integrity after rewires | probes 2/3: JSON parses (pwsh ConvertFrom-Json), `$schema` canonical, `_*` doc keys + key order preserved, `.bak` exactly-when-changed (1 on change, 0 on re-run) | probes 2/3 | **PASS** |
| AC-7 cross-shell byte-identity + mirrors | QA obligation — 4 per-fixture `cmp` runs (below) + `sync-self --check` = "In sync." | probes 2/3 + chain | **PASS** on every designed (LF/canonical) fixture; adversarial CRLF extension diverges → defect D-1 (MINOR, pre-existing) |
| AC-8 gate + tallies | `verify_all` 32/0/0 both shells; all suites green (table below); re-run 32/0/0 after this report landed | chains + final re-run | **PASS** |
| AC-9 placeholder repair (gate C3 / B7) | suite fixtures P/P2 + QA independent probes: 4-token repair fixture (probe 3), gated-off crafted-template fixture (probe 4 E5), forced non-Windows OS-pick branch (probe 5) | suites + probes 3/4/5 | **PASS** |

Gate-condition spot confirmations (independent of 04's evidence):

| Cond | QA confirmation |
|---|---|
| C1 | Fresh false-positive probe: settings wiring `bash build-scripts/deploy.sh` (exists), `bash my-scripts/tool.sh` (absent), `RUNNER=scripts/run-me.sh` (absent) → only the `=`-bounded `scripts/run-me.sh` flagged, exit 4; superstring dirnames never matched. Output in Adversarial §A-C1. |
| C2 | Exit-4 SKILL row verified at `harness-upgrade/SKILL.md:155`: verbatim relay, manual-restore for user-custom files, explicit co-occurring exit-2/3 remediation processing, dry-run-leg semantics with plan presentation unchanged. |
| C3 | §6.2.5 behavior reproduced independently: dry-run `PLAN\|REWIRE-PLACEHOLDER` + untouched file; apply rewires all 4 tokens OS-picked, braces-free records, 1 `.bak`, re-run NOOP; gated-off token left verbatim + exit 4 (probe 4 E5); non-Windows pick branch exercised via OSTYPE override (probe 5). |
| C4 | `harness-adopt/SKILL.md:324-333`: merge-mode terminal assertion includes JSON-parses, canonical `$schema`, valid hook event keys, `_*`-key survival; flow failure withholds success summary. Text-verified (prose surface). |

## Regression tally table (QA-captured runs vs 04's claims)

| Suite | Shell | QA result | 04/rework claim | Delta |
|---|---|---|---|---|
| `verify_all` | bash | **32 PASS / 0 WARN / 0 FAIL** | 32/0/0 | 0 |
| `verify_all` | pwsh | **32 PASS / 0 WARN / 0 FAIL** | 32/0/0 | 0 |
| `sync-self --check` | bash | **"In sync."** | In sync. | 0 |
| `test-harness-upgrade` | bash | **79/0** (×3 runs) | 79/0 | 0 |
| `test-harness-upgrade` | pwsh | **80/0** (×2 runs) | 80/0 | 0 |
| `test-init` | bash | **270/0** (no-python3 path) | 270/0 | 0 |
| `test-init` | pwsh | **308/0** | 308/0 | 0 |
| `test-real-project` | bash | **90/0** | 90/0 | 0 |
| `test-real-project` | pwsh | **90/0** | 90/0 | 0 |
| `test-supervisor` | bash / pwsh | **45/0** / **49/0** | 45/0, 49/0 | 0 |
| `test-verify-i6` | bash / pwsh | **58/0** / **58/0** | 58/0 | 0 |
| `test-language` | bash / pwsh | **39/0** / **39/0** | 39/0 | 0 |
| `test-guard-rm` | bash / pwsh | **17/0** / **17/0** | (untouched surface) | 0 |

Every tally matches `baseline.json` exactly; baseline was already raised by the developer
(+68 net) and QA runs confirm every figure → **no baseline edit needed** (nothing moved up
or down relative to the recorded values).

## AC-7 cross-shell `cmp` results (QA obligation from 05)

Twin fixture copies; sh helper on copy A, ps1 helper on copy B; `cmp` of the resulting
`.claude/settings.json` bytes:

| Fixture (settings-writing path) | cmp result |
|---|---|
| migrate, RC-1 broken (gated rewire, partial) | **byte-identical** |
| migrate, healthy legacy (full rewire) | **byte-identical** |
| upgrade S3.1 legacy prefix rewire (full old-layout project) | **byte-identical** |
| upgrade S3.0 placeholder repair (4 literal tokens) | **byte-identical** |
| upgrade rewire on CRLF settings (QA adversarial extension, not a designed fixture) | **DIFFER** — sh output LF-only (389 B), ps1 preserves CRLF (401 B) → defect D-1 below |

## Boundary tests exercised

- B1/B2 (settings absent / no hooks key): suite fixtures (skip/`not wired` paths) — green in both drivers.
- B3/B4 (legacy path, single-variant): probe 2 — only the present variant rewired; absent variant's hook left on the still-existing legacy path; explicit CONGRUENCE-FAIL when wired target missing.
- B5 (`.harness/scripts/` exists but empty): probe 1 fixture — repaired, exit 0.
- B7 (literal placeholder): probes 3/4/5 — repaired when target can land, flagged + exit 4 when not.
- B8 (CRLF / BOM / read-only / failed write): BOM preserved byte-for-byte (probe 4 E1); read-only-settings write failure loud (suite M3, 3× bash + 2× pwsh); CRLF = D-1 (line endings normalized by the bash helpers on MSYS — loud, valid JSON, see defects).
- B9 (dry-run): dry-run never wrote in any probe; congruence findings included in plan; documented additive-only asymmetry confirmed to behave exactly as documented (Adversarial §A-B9).
- B10 (idempotence): re-runs NOOP with zero writes/`.bak` in probes 1/2/3 and suite fixtures.
- B11 (single-dev v0.30): probe 1 — hook fire exits 0, generated E.3 PASS with no `.harness/agents/`.
- B12 (non-git): all QA fixtures were non-git (mv fallback path) — behavior held.

## Adversarial tests (REQUIRED, one per acceptance criterion)

All reproducers below were written by QA from the ACs (not copied from the drivers); fixtures
live under `%TEMP%\qa-t020\`. Each row states the pre-run failure hypothesis and what was observed.

| AC | Hypothesis ("I expect failure when…") | Reproducer (NEW, QA-written) | Outcome |
|---|---|---|---|
| AC-1 | the unconditional double-prefix collapse sed still rewires the sync path even when its target never landed, recreating the dangle | probe 2: pre-relocation fixture, Stop = `bash scripts/harness-sync.sh`, source deleted; migrate dry-run + apply, both shells | **Survived** — Stop stays on the legacy path, guard-rm (whose target landed) is rewired, `CONGRUENCE-FAIL … missing scripts/harness-sync.sh` + `/harness-upgrade` hint printed, exit 4 in dry-run AND apply, no "Done." success line; both shells byte-identical settings |
| AC-2 | repair leaves the dangle when `.harness/scripts/` exists but is empty (B5) and no legacy `scripts/` exists to move from | probe 1: exact user replay — settings from the shipped template OS-picked as a Linux init (bash everywhere), empty `.harness/scripts/` | **Survived** — symptom first reproduced verbatim (`bash: .harness/scripts/harness-sync.sh: No such file or directory`, rc=127); dry-run plans 14 REFRESHes + projected-congruence OK + writes nothing; apply lands harness-sync pair + guard-rm pair + ambient pair, exit 0; hook fire now rc=0 "Already in sync."; re-run NOOP, 0 new `.bak`, byte-identical; the bash variant was NOT re-picked to pwsh (OQ-5 honored) |
| AC-3 | the status SKILL still carries the retired seven-agents asset row and would mis-report a healthy v0.30 project | grep battery over `harness-status/SKILL.md` | **Survived** — retired phrase count 0; plugin-provided note present; §3c carries all four states + interpreter-unavailable WARN + §7 routing line |
| AC-4 | E.4b misses a dangle when the wired command line carries TWO path tokens (multi-token extraction breaks on first match) | probe 4 E3: Stop command = `bash .harness/scripts/harness-sync.sh && bash .harness/scripts/extra-helper.sh` | **Survived** — upgrade exits 4 naming only `extra-helper.sh` (harness-sync landed via S2, correctly not flagged); generated E.4b FAILs with `hook command references missing script: .harness/scripts/extra-helper.sh — fix: run /harness-upgrade` |
| AC-5 | a generated tree whose harness-sync was deleted mid-flow passes the terminal congruence surface silently | probe 1 §6 (post-generation dangle) + `test-init` mutation probe (both shells) | **Survived** — generated E.4b flips to FAIL naming path + fix in both shells; test-init's 10b-core mutation probe green (270/0, 308/0) |
| AC-6 | the raw-text rewire corrupts a settings.json that starts with a UTF-8 BOM (first-line parsing / write path) | probe 4 E1: BOM-prefixed legacy settings through a full upgrade apply | **Survived** — rewire lands, BOM preserved (`ef bb bf` first 3 bytes), JSON parses, exit 0 |
| AC-7 | sh/ps1 twins diverge on the placeholder-repair write (PS trailing-newline trap family) | probe 3: twin fixtures, 4-token repair, sh vs ps1, `cmp` | **Survived** on all 4 designed fixture classes (table above) — **FAILED on the CRLF extension** (D-1, MINOR, pre-existing: MSYS sed strips CR on piped input; `printf 'a\r\nb\r\n' \| sed -e 's\|x\|y\|g'` → `a\nb\n` captured) |
| AC-8 | concurrent/repeated suite runs flake (temp-dir collisions, ordering) | both chains run concurrently + test-harness-upgrade ×3 bash ×2 pwsh | **Survived** — zero flakes, identical tallies every run |
| AC-9 | the OS-pick repairs to a variant whose target is NOT the one the template can land, or substitutes even when the template lacks the script | probe 4 E5 (crafted template root minus harness-sync.*) + probe 5 (OSTYPE=linux-gnu override) | **Survived** — gated-off token left verbatim, `GAP\|template-missing` ×2 + `CONFLICT\|congruence\|… unresolved placeholder token`, exit 4, no `REWIRE-PLACEHOLDER`; Linux-pick branch rewires to `bash .harness/scripts/harness-sync.sh`, target lands, fire rc=0 |

Key captured evidence (one line each; full logs under `%TEMP%\qa-t020\`):

```
pre-repair hook fire: rc=127 out=bash: .harness/scripts/harness-sync.sh: No such file or directory
post-repair hook fire: rc=0 out=[Already in sync.]
CONGRUENCE-FAIL  "command": "bash scripts/harness-sync.sh" -> missing scripts/harness-sync.sh   (migrate, exit 4)
RESULT|REWIRE-PLACEHOLDER|.claude/settings.json (SYNC_COMMAND -> pwsh -NoProfile -File .harness/scripts/harness-sync.ps1)
RESULT|REWIRE-PLACEHOLDER|.claude/settings.json (SYNC_COMMAND -> bash .harness/scripts/harness-sync.sh)   (OSTYPE=linux-gnu branch)
CONFLICT|congruence|… -> missing .harness/scripts/extra-helper.sh   (multi-token line, exit 4)
CONFLICT|congruence|… -> missing scripts/run-me.sh   (C1 probe: ONLY the =-bounded token; build-scripts/my-scripts not flagged)
[E.3] Agents layout v0.30+ (.harness/agents/ = partition dev-* only) ... PASS   (healthy)  /  WARN (legacy copy)  /  PASS (dev-* only)
[E.4b] Hook commands resolve to existing scripts ... FAIL + "missing script: .harness/scripts/harness-sync.sh — fix: run /harness-upgrade"
```

### A-C1 — C1 false-positive probe (verbatim)

```
=== C1 probe rc=4 ===
CONFLICT|congruence|{ "hooks": [ { "type": "command", "command": "RUNNER=scripts/run-me.sh bash -c run" } ] } -> missing scripts/run-me.sh
(no other congruence conflicts; build-scripts/deploy.sh and my-scripts/tool.sh never extracted)
```

### A-B9 — dry-run/apply asymmetry behaves exactly as documented

Fixture: Stop hook custom-wired to `bash scripts/archive-task.sh`, file present at the legacy
path. Dry-run exit **0** (additive-only projection, as the helper comment documents); apply
exit **4** with `CONFLICT|congruence|… -> missing scripts/archive-task.sh` after S1 moves the
file. Loud on apply (`conflicts=1`), never silent. This matches the recorded B9 note in both
helper comment blocks (reviewer MINOR 2) — behaves-as-documented, not a defect.

### QA instrument errata (honesty record)

Two probe-4 assertions initially mis-fired due to QA-side instrument bugs, not product bugs:
(1) an E.4b grep ran under `set -o pipefail`, so the matched grep was overridden by
verify_all's expected exit 2 — manual re-run shows the correct FAIL row (pasted above);
(2) the in-probe CRLF "preserved" check used `grep -c $'\r'`, which mis-counted; the
authoritative byte-count instrument (`tr -cd '\r' | wc -c`) in an isolated re-run shows
8 CR before → 0 CR after the sh apply, which is the basis of D-1.

## Defects found

- **[MINOR, pre-existing — not a T-020 regression] D-1: bash helpers normalize CRLF settings.json to LF on first rewire (MSYS only).**
  Repro: `printf '…\r\n…' > .claude/settings.json` (CRLF), legacy-layout fixture, run
  `bash upgrade-project.sh … ` apply on Git-Bash/Windows → written settings is LF-only
  (CR bytes 8 → 0); `upgrade-project.ps1` preserves CRLF → cross-shell `cmp` diverges on this
  input. Root cause: this MSYS GNU sed 4.9 strips CR on piped input (one-liner repro above);
  the S3 sed pipeline predates T-020 (pre-T-020 it ran *unconditionally*, so exposure was
  strictly wider before this task). Impact: one-time, loud (REWIRE record + `.bak`), JSON
  valid, keys/order/doc keys intact, idempotent from run 2; Linux/macOS bash (the bash
  helper's primary platform) is unaffected; Windows users get the ps1 helper by OS-pick.
  Recommendation: record alongside the design-R1 trailing-newline nuance in the OQ-4
  follow-up task — no rework of T-020 warranted.
- **[NIT, already routed in 05 as non-blocking] sh E.4b FAIL detail prints a leading blank line**
  (unquoted `$(echo -e $e4b_bad)`) — observed in probe 1/probe 4 output; cosmetic, FAIL row
  + path + fix text all present. No new action.

## verify_all result

- Total dogfood checks: 32 → **32** (no check added/removed — NFR-4/G.4 satisfied; count discipline confirmed by I.6/G.4 PASS).
- bash: **32 PASS / 0 WARN / 0 FAIL**; pwsh: **32 PASS / 0 WARN / 0 FAIL** (QA-captured).
- Re-run after this report file landed (E.6-class scan includes it): **32 PASS / 0 WARN / 0 FAIL**.
- New tests added this task (developer, QA-confirmed): +42 test-harness-upgrade (37→79 / 38→80), +21 test-init per shell, +8 test-real-project per shell.
- Baseline updated: **no change needed** — `baseline.json` already records the raised counts; every value independently re-confirmed by QA runs.
- QA wrote no new driver assertions into the suite: every gap QA identified was already covered by the developer's fixtures (H/I/P/P2/M1-M3) or belongs to the pre-existing D-1 family (routed to the OQ-4 follow-up, where a CRLF fixture should be added alongside the fix decision).

## Stability

- `test-harness-upgrade.sh` ran 3×, `test-harness-upgrade.ps1` 2× — identical tallies (79/0, 80/0), zero flakes.
- bash and pwsh chains ran concurrently (randomized temp dirs) — no cross-contamination, all green.
- Probe fixtures re-ran idempotently (B10 re-run legs) with byte-identical results.

## Verdict

**PASS-WITH-NOTES → APPROVED FOR DELIVERY.**

The shipped change set (1) repairs the exact reported project state via the `/harness-upgrade`
helper — symptom reproduced verbatim, then eliminated, idempotently; (2) every confirmed
producing flow now ends loud (exit 4 / CONGRUENCE-FAIL / flow-failure prose) instead of
silently dangling — adversarial attempts to recreate the dangle through migrate, upgrade,
multi-token commands, crafted template roots, and gated-off placeholders all failed to
produce a silent end state; (3) the dangle is diagnosed by the generated E.4b/D.4b row,
`/harness-status` §3c text, and the exit-4 contract; (4) full regression battery green in
both shells with tallies matching 04 and `baseline.json` exactly.

Notes (non-blocking): D-1 (MINOR, pre-existing, MSYS-only CRLF normalization) routed to the
OQ-4 template-docs follow-up together with the already-recorded R1 trailing-newline nuance
and the sh/ps E.4b output cosmetics; `docs/tasks.md` row update remains PM-owned at delivery.
