# Code Review — sync-hook-dangling-ref (T-020)

Mode: full · Reviewer: code-reviewer · Date: 2026-06-11
Upstream: `01_REQUIREMENT_ANALYSIS.md` (READY) · `02_SOLUTION_DESIGN.md` (READY, incl. §6.2.5) · `03_GATE_REVIEW.md` (GO-WITH-CONDITIONS C1–C4) · `04_DEVELOPMENT.md` (READY FOR REVIEW)

## Files reviewed

Helpers (template source + dogfood mirror, line-number-identical → mirror identity corroborated; E.1/`sync-self --check` is the byte gate):
- `skills/harness-init/templates/common/.harness/scripts/migrate-scripts-layout.sh` / `.ps1` (+ `.harness/scripts/` mirrors)
- `skills/harness-init/templates/common/.harness/scripts/upgrade-project.sh` / `.ps1` (+ `.harness/scripts/` mirrors)

Templates / SKILLs:
- `skills/harness-init/templates/common/.claude/settings.json.tmpl`
- `skills/harness-init/templates/{generic,fullstack,backend}/.harness/scripts/verify_all.{sh,ps1}.tmpl` (6 files)
- `skills/harness-init/SKILL.md` · `skills/harness-adopt/SKILL.md` · `skills/harness-upgrade/SKILL.md` · `skills/harness-status/SKILL.md`

Gate + drivers: `.harness/scripts/verify_all.{sh,ps1}` (D.2) · `test-harness-upgrade.{sh,ps1}` · `test-init.{sh,ps1}` · `test-real-project.{sh,ps1}` · `test-supervisor.{sh,ps1}`

Stamps / records: `.claude-plugin/plugin.json` · `.claude-plugin/marketplace.json` · `CHANGELOG.md` · `README.md` · `README.zh-CN.md` · `.harness/scripts/baseline.json` · `docs/dev-map.md` · `docs/tasks.md`

## Findings

### CRITICAL
None.

### MAJOR

- **[LOGIC/B8] `skills/harness-init/templates/common/.harness/scripts/migrate-scripts-layout.sh:186-190` (mirrored at `.harness/scripts/migrate-scripts-layout.sh`) — apply-mode terminal scan reads the in-memory text, not the written file; a failed settings write ends silently dangling with exit 0.** The scan loop is `done <<< "$settings_new"` in **both** modes, but the write at `:147` (`printf '%s\n' "$settings_new" > "$settings"`) is unchecked under `set -uo` (no `-e`). Trigger (B8's enumerated condition — read-only settings.json, disk-full, AV lock): S1 moves succeed (files leave `scripts/`), `cp` of the `.bak` succeeds, the `printf` redirection fails, disk keeps the OLD legacy-path hooks whose targets were just moved away — yet the scan validates the never-landed in-memory rewired text, finds 0 violations, prints "Backed up… / Done." and **exits 0**. That is a reachable silent-dangle end state, the exact thing FR-P1 forbids ("Silent danglement is never a reachable end state") and AC-1's contract excludes. It also contradicts the helper's own comment (`:153-155` "disk is ground truth") and design §4.1 ("In apply mode the disk is ground truth because the scan runs last"). `upgrade-project.sh:509-513` does this correctly (`scan_text="$(cat "$settings")"` in apply mode) — migrate deviates from its sibling. **Correct fix (~3 lines + mirror re-sync):** in apply mode scan `"$(cat "$settings")"`; keep `$settings_new` for dry-run. Apply the same to `migrate-scripts-layout.ps1:159` for parity and comment-truth (the PS twin is only *incidentally* loud — `$ErrorActionPreference = "Stop"` aborts on a failed `WriteAllText` — but its comment makes the same false "disk is ground truth" claim). Re-run M-fixture legs after the fix; consider a driver probe (read-only settings → expect exit 4 / explicit failure) since neither driver currently exercises B8's write-failure half.

### MINOR

- **[DOC] `docs/tasks.md:9`** — the T-020 row still reads "BLOCKED before stage 1 … no stage ran, no code touched" while shipping inside the very change set that contains the full implementation. Stale board state inside the delivery; PM must update the row before commit (board upkeep is PM-owned — routing note, not a developer rework item).
- **[LOGIC] `upgrade-project.sh:524-535` / `upgrade-project.ps1:550-554` and `migrate-scripts-layout.sh:173-185` / `.ps1:166-174`** — dry-run congruence projection is additive-only: a hook wired to a **legacy** `scripts/<name>` whose file exists now but is planned to MOVE is reported congruent in dry-run (disk test passes) yet exits 4 on apply (file moved, no rewire for non-sync/guard names). Dry-run plan can omit a violation apply will raise — B9 says the plan "includes the congruence findings". Only reachable for hooks custom-wired to known non-`harness-sync`/`guard-rm` scripts at legacy paths; document the asymmetry in the helper comment or subtract planned-away legacy paths in the projection.
- **[MAINT] `upgrade-project.sh:263` / `upgrade-project.ps1:282`** — the single `REWIRE|.claude/settings.json (harness-sync + guard-rm hook paths)` record is also emitted when the only change was a placeholder repair (e.g. an ambient token), misnaming what changed; the per-file `n_rewired` semantics are fine (per design), but the detail string could say "hook command paths".

### NIT

- **[MAINT] `migrate-scripts-layout.ps1:55,95,97`** — `$movedAny` is now write-only (dead); the sh twin has no counterpart. Remove.
- **[STYLE] generic/fullstack/backend `verify_all.sh.tmpl` E.4b/D.4b FAIL line (e.g. generic `:118`)** — unquoted `$(echo -e $e4b_bad)` collapses layout via word-splitting (charset-bounded paths make it safe, just untidy); also the sh row dedupes paths (`sort -u`) while the PS row (`.ps1.tmpl:137-147`) reports duplicates undeduped — cosmetic within-pair output divergence, both still FAIL identically.
- **[MAINT] `upgrade-project.sh:182`** — `cp … 2>/dev/null` discards the OS error reason; the `CONFLICT|refresh` record would be more actionable carrying it.
- **[DOC, pre-existing/out-of-scope per OQ-4]** — `generic/verify_all.ps1.tmpl:10` and `fullstack/verify_all.ps1.tmpl:6` usage headers still show the pre-relocation `.\scripts\verify_all.ps1` path. Not introduced by T-020; candidate for the template-docs follow-up.

## Gate conditions C1–C4

| Cond | Verdict | Evidence |
|---|---|---|
| C1 | **MET** | Left-bounded ERE `(^|["' =])(\.harness/)?scripts/…` verified in all five consumers, both shells: `migrate-scripts-layout.sh:187`/`.ps1:158`, `upgrade-project.sh:542`/`.ps1:536`, generic `sh.tmpl:112`/`ps1.tmpl:136`, fullstack `sh:208`/`ps1:172`, backend `sh:223`/`ps1:194`; prose copies in init `SKILL.md:412`, adopt `:328`, status `:98`. 04 pastes a real matcher run (negative control count=0, `=`-bounded positive still caught) and the end-to-end H-fixture `build-scripts/deploy.sh` guard exists in both drivers (`test-harness-upgrade.sh:333`, `.ps1:350`). PS regexes have no IgnoreCase; case-sensitive ops throughout. |
| C2 | **MET** | `harness-upgrade/SKILL.md:155` — exit-4 row instructs verbatim relay, manual-restore for user-custom files, explicit co-occurrence processing of `VERIFY-HALT`/`CONFLICT\|verify_all` (exit-2 remediation) and `CONFLICT\|hook` (exit-3 remediation), and the dry-run-leg semantics with plan presentation unchanged. Mechanically the scan is the last `exit_code` writer in both shells. |
| C3 | **MET** | §6.2.5 implemented verbatim: S3.0 first pass (`upgrade-project.sh:216-243`, `.ps1:236-263`), assembled tokens (`ph_o="{{"`/`"{" + "{"` — no full literal token in any shipped file; `grep -qF`+`${var//…}` sh, ordinal `.Contains/.Replace` PS), OS pick per the four-row table, `target_present` gate (disk in apply; planned-MOVE/template-carried projection in dry-run), braces-free `REWIRE-PLACEHOLDER` record, `.bak`/`n_rewired`/write path untouched, B10 fixed point. Fixtures P (dry-run + apply + re-run) and P2 (gated-off → token intact, `CONFLICT\|congruence` unresolved-token, exit 4) in both drivers. |
| C4 | **MET** | `harness-adopt/SKILL.md:324-341` — terminal assertion plus, after any merge-mode write: JSON parses, `$schema` exactly the canonical `.json` URL, hook keys valid event names, pre-existing root `_*` doc keys survived; flow failure withholds the success summary. |

## Requirement coverage check

| Criterion | Implementation | Status |
|---|---|---|
| FR-P1 (no flow ends dangling, never silent) | terminal scans: migrate `sh:152-202`/`ps1:142-188`; upgrade S6 `sh:494-547`/`ps1:517-563`; init 10b; adopt step-6 | ⚠️ MAJOR — bash migrate apply-mode scan misses the failed-write path (B8); all other paths covered |
| FR-P2 (migrate gated rewire) | `migrate-scripts-layout.sh:103-134`, `.ps1:114-126` + MOVE-FAILED `:93-96`/`:91-94` | ✅ |
| FR-P3 (upgrade S2/S3 congruent) | `upgrade-project.sh:155-206` (GAP/cp-verify) + S3 gates + S6 exit 4 | ✅ |
| FR-P4 (init/adopt terminal step) | `harness-init/SKILL.md:406-424,495`; `harness-adopt/SKILL.md:324-341` | ✅ |
| FR-P5 (hook stays for all shapes) | no conditionalization anywhere; status §1 note | ✅ |
| FR-D1/FR-D2 (status congruence, all events + interpreter WARN) | `harness-status/SKILL.md:82-115` | ✅ |
| FR-D3 (v0.30-accurate surfaces) | status `:34-37` (count 14, §6 `:135` consistent); E.3/D.3 replaced in all 6 templates | ✅ |
| FR-D4 (consumer verify_all FAIL row) | E.4b/D.4b in all 6 templates, outside B-CUSTOM, SKIP-without-settings (B1) | ✅ |
| FR-R1/FR-R2/FR-R3 (repair, idempotent, raw-text/.bak) | S2 widened refresh set + fixtures H/H2/P/P2nd | ✅ |
| FR-R4 (diagnose-only cross-OS) | status §3c WARN `:109-112`; no auto-rewrite of runnable variants | ✅ |
| FR-R5 (no-harness → adopt) | `upgrade-project.sh:78-81` unchanged | ✅ |
| AC-1 | fixtures M1/M2, both shells (`test-harness-upgrade.sh:411-465`, `.ps1:435-499`) | ✅ |
| AC-2 | fixtures H/H2, both shells, incl. runtime invocation | ✅ |
| AC-3 | status SKILL §3c (prose surface) + healthy-fixture E.3 PASS legs in test-real-project | ✅ |
| AC-4 | test-real-project healthy + dangling legs; sh driver runs `verify_all.sh`, ps driver runs `verify_all.ps1` — both shells | ✅ |
| AC-5 | test-init congruence assert + OS-picked ambient asserts + mutation probe (`test-init.sh:277-306,484-496`; `.ps1:307-344`) | ✅ |
| AC-6 | fixture P JSON/`$schema`/`_doc_sync_hook`/.bak-iff-changed asserts; fixture A JSON parse | ✅ |
| AC-7 | within-driver re-run byte-identity ✅; cross-shell per-fixture `cmp` is the QA-stage half per design §10 (dev did an ad-hoc spot check) — **QA must run it** | ⚠️ deferred-to-QA by design |
| AC-8 | 32/32 both shells + tallies pasted; baseline.json matches every claimed count; QA re-confirms | ✅ |
| AC-9 (gate C3) | fixtures P/P2 both shells | ✅ |
| B1–B12 | walked individually; B1/B2/B3/B4/B5/B6/B7/B9*/B10/B11/B12 hold (*B9 has the MINOR additive-projection asymmetry); **B8 broken on the bash-migrate write-failure path (the MAJOR)** | ⚠️ |
| NFR-1..6 | parity ops correct (`-cnotin`/`-ccontains`/no-IgnoreCase/`.Split("`n")`); mirrors line-identical; gate 32; tallies captured; dogfood settings untouched | ✅ |

## Design fidelity check

| Design item | Implementation | Status |
|---|---|---|
| §4.1 scan, line-scoped, fail-open, C1-bounded | all five consumers, both shells | ✅ (except the §4.1 "disk is ground truth" clause in migrate — the MAJOR) |
| §5.1 exit 4 additive; healthy runs exit 0 | helper headers + B10 fixtures | ✅ |
| §5.2 record kinds (GAP/CONFLICT-refresh/-congruence, REWIRE-PLACEHOLDER braces-free) | helpers + `harness-upgrade/SKILL.md:126-139` | ✅ |
| §5.3/§6.3 ambient placeholders + `_ambient_hook` rewording | `settings.json.tmpl:6,64,74`; D.2 ×2 shells (9-entry whitelist) | ✅ |
| §5.4 refresh set + restated INVARIANT comments | `upgrade-project.sh:96-99,142-154`, `.ps1:107-110,157-169` | ✅ |
| §6.1–§6.2 (incl. §6.2.5) | as audited above | ✅ |
| §6.4–§6.7 SKILL changes | verified incl. asset count 14 / health-score recount | ✅ |
| §6.8 E.3 WARN + E.4b/D.4b outside B-CUSTOM | all 6 templates; WARN branch supported by both step harnesses | ✅ |
| §6.9 no new check (32), no I.6 change | CHANGELOG `[0.31.0]`, stamps 0.31.0 ×4 surfaces | ✅ |
| Scope creep | none found — every change traces to a design row or an adjudicated drift below | ✅ |

**Drift adjudication (developer's 4 declared items):**
1. Fixture relabel G/H→H/I — naming-only collision with the pre-existing Fixture G; assertions match design 1:1. **Legitimate.**
2. Upgrade dry-run projection also counts planned S1 MOVEs — strictly more faithful to what apply does; §4.1's generic clause covers it; apply behavior identical. **Legitimate** (and the related additive-only asymmetry is recorded as MINOR above, present in the design itself).
3. test-supervisor fan-out fix — the designed §6.7 row removal breaks 2 pre-existing structural asserts; updating them to assert the new state (not deleting) is the correct fan-out; counts unchanged; hidden coupling surfaced as an insight candidate. **Legitimate; the gap was the design's, properly escalated via 04.**
4. test-real-project `{{GUARD_COMMAND}}` substitution — precondition of the designed healthy-fixture E.4b-PASS assertion (a literal token on a command line is an E.4b FAIL by this task's own row). **Legitimate, necessity correctly argued.**

## 04 internal-consistency audit

All tallies reconcile: test-harness-upgrade 78 source asserts − 2 unexecuted JSON-parse alternates = 76 bash / 77 ps (= 37/38 + 39); test-init +21 = 7 new × 3 types (308 ps / 270 bash-no-python3 — remainder explained by the pre-existing python3 gate); test-real-project +8 = 4 × 2 fixtures (90); test-supervisor 45/49 unchanged (asserts updated in place); baseline.json matches every number; README/zh badges and CHANGELOG claims match code (D.2 7→9, count stays 32, v0.31.0 on plugin.json + marketplace.json + both badges). No unexplained remainder, no fabricated-tally signature.

## Verdict

**REWORK** — 1 blocking finding (MAJOR), everything else non-blocking.

Required before merge:
1. **[MAJOR]** `migrate-scripts-layout.{sh,ps1}` (template source, then `sync-self`): apply-mode terminal scan must read the written settings file from disk (`upgrade-project` S6 pattern), keeping `$settings_new` only for dry-run — closes the B8 silent-dangle window and makes the "disk is ground truth" comment true. Re-run both driver suites; recommend a read-only-settings probe for the write-failure half.

Route to PM: also carry the `docs/tasks.md` row update (MINOR, PM-owned) into delivery, and hand QA the AC-7 cross-shell per-fixture `cmp` obligation plus the B8 write-failure probe suggestion.

## Re-review addendum — rework round 1 (focused)

Mode: focused re-review · Reviewer: code-reviewer · Date: 2026-06-11
Scope: the REWORK item (MAJOR [LOGIC/B8]) + new M3 probe + taken optional notes. PM-verified tallies (sync-self "In sync", 79/0 + 80/0, 32/0/0 ×2) treated as given.

1. **MAJOR [LOGIC/B8] — VERIFIED FIXED** in all four copies. `migrate-scripts-layout.sh:172-176` (template = mirror, line-identical) selects `scan_text="$(cat "$settings")"` in apply mode and keeps `$settings_new` only for dry-run; `.ps1:160` mirrors it (`Get-Content $settings -Raw` vs `$new`). The failed-write trigger now ends in `CONGRUENCE-FAIL … missing scripts/<name>` + exit 4 — FR-P1's silent-dangle window is closed and the `:152-169`/`:138-156` comment is now true. No regression in the surrounding code: gated rewire (`sh:126-134`/`ps1:112-118`), C1-bounded ERE (`sh:197`/`ps1:159`), placeholder detection (`sh:171,180`/`ps1:158,164`), and B10 double-prefix collapse are byte-unchanged from the reviewed version; dry-run behavior is identical to pre-rework.
2. **M3 probe — GENUINE, not vacuous.** `test-harness-upgrade.sh:467-486` / `.ps1:503-528`: with-sync fixture wires `-File scripts/harness-sync.ps1`, moves succeed, write hits a read-only settings. Pre-rework sh code would have scanned the never-landed in-memory text (all `.harness/` targets exist post-move) and exited 0 with "Done." — the three asserts (exit 4 / CONGRUENCE-FAIL names the legacy path / disk untouched) discriminate exactly that. SKIP guard is sound: enforceability is probed by an actual append-open (`sh:478`, `ps1:515`), not by trusting chmod/IsReadOnly success; when unenforceable it self-disables (no assertion emitted — no false-PASS, per insight 2026-06-09), and the +3/+3 tally deltas confirm it ran enforced on this machine. Writability restored in both branches (`sh:486`, `ps1:528`). Note (non-blocking): the ps1 leg exercises the loud-abort path (WriteAllText throws before the scan), which is the PS twin's correct failure mode; the sh leg is the one that exercises the scan-re-read itself — together they cover both shells' B8 behavior.
3. **Optional notes — taken cleanly, no collateral.** REWIRE detail → `(hook command paths)` in all four upgrade-project copies (`sh:263`/`ps1:282` ×2); no doc/driver pinned the old string (remaining hits are migrate's EDIT plan line, where "harness-sync + guard-rm" is still literally accurate). `$movedAny` fully gone (grep: only review-doc mentions remain). B9 asymmetry comment landed in all 8 helper copies (migrate + upgrade × 2 shells × template/mirror) — exceeds the MINOR's ask.
4. **Nothing else changed.** New-assert math reconciles exactly: +3 sh / +3 ps = the three M3 asserts per shell; M1/M2/H/I/P/P2 assertion bodies match the previously reviewed state. NIT [DOC]: 04's attribution "+2 M3 probes, +1 M-fixture assert" is imprecise — all three new asserts are M3-labeled; harmless.

Outstanding from the full review, unchanged and correctly routed (not rework items): `docs/tasks.md` row (PM, at delivery); AC-7 cross-shell `cmp` (QA); OQ-4 template usage-header follow-up; sh/ps E.4b output cosmetics.

## Verdict (re-review)
**APPROVED-WITH-NOTES** (0 CRITICAL, 0 MAJOR; notes are non-blocking)
