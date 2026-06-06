# 04 — Development Record · T-010 · g4-version-decouple

**Stage:** 4 (Developer) · **Date:** 2026-06-06 · **Gate:** APPROVED (no conditions)
**Inputs:** `02_SOLUTION_DESIGN.md` (§5/§6/§7/§8), `03_GATE_REVIEW.md` (§2), AI-GUIDE.md + `.harness/rules/{40-locations,70-doc-size}.md` + insight-index (L13/L20/L27/L33).
**Scope:** decouple only — version NOT bumped (plugin.json/marketplace/README/CHANGELOG stay 0.21.1).

## Summary
Dropped the redundant `at v0.21.1` token from the 6 live prose count claims and rewrote the corresponding 6 G.4 ledger rows (1-5,10) to count-only `shape`+`expect` in **both** `verify_all.ps1` and `verify_all.sh`, symmetrically. The count `32` is retained on every decoupled row (32→31 drift still FAILs — AC-2). No check added/removed; tally stays 32; CHANGELOG/`$version`/G.3/tripwire/rows 6-9,11 untouched.

## Files changed (6 source/doc files)

### Prose claims — `at v0.21.1` token removed (§6)
- `AI-GUIDE.md:36` — `(32/32 at v0.21.1; check count grows…)` → `(32/32; check count grows…)`
- `AI-GUIDE.md:69` — `(32 checks at v0.21.1, including …)` → `(32 checks, including …)`
- `docs/dev-map.md:60` — `Total verification (32 checks at v0.21.1)` → `Total verification (32 checks)`
- `docs/dev-map.md:133` — `runs all 32 checks (at v0.21.1) including …` → `runs all 32 checks including …` (R-7: whole ` (at v0.21.1)` parenthetical removed, collapsed to ONE space — no orphan `()`, no double space)
- `.harness/rules/40-locations.md:25` — `(32 checks at v0.21.1, all must PASS — …)` → `(32 checks, all must PASS — …)`
- `docs/manual-e2e-test.md:3` — `verify_all` at `32 checks at v0.21.1;` → `32 checks;`

### G.4 ledger — count-only rows 1-5+10, BOTH shells (§5)
- `.harness/scripts/verify_all.ps1:650-654,659` — `$claims` rows 1-5,10: dropped ` at v\d+\.\d+\.\d+` from `shape` and ` at v$version` from `expect`. New literals: row1 `expect="$count/$count"` shape `\d+/\d+`; row2/3/10 `expect="$count checks"` shape `\d+ checks`; row4 `expect="runs all $count checks"` shape `runs all \d+ checks`; row5 `expect="($count checks"` shape `\(\d+ checks`.
- `.harness/scripts/verify_all.sh:697-722` — `g4_shapes` + `g4_expects` idx 0-4,9 edited identically (semantically mirrored): `"$g4_count/$g4_count"`, `"$g4_count checks"` (×3), `"runs all $g4_count checks"`, `"($g4_count checks"`; shapes `[0-9]+/[0-9]+`, `[0-9]+ checks` (×3), `runs all [0-9]+ checks`, `\([0-9]+ checks`.

### Left byte-identical (confirmed — §7)
- G.4 rows 6,7 (README badges `verify__all-32%2F32`), row 8 (`README.md (32 checks)`), row 9 (`README.zh-CN.md （32 项检查）`), row 11 (`baseline.json "verify_all_checks": 32`) — untouched in both shells.
- CHANGELOG `[$version]`-heading check (PS:676 / sh:742) — untouched, still consumes `$version`.
- `$version` (PS:639) / `g4_version` (sh:670) derivation + the `-not $version` throw (PS:640) / `-z "$g4_version"` FAIL branch (sh:675-677) — **kept** (still consumed by CHANGELOG; NOT dead — R-5).
- `$count = $report.Count+1` / `g4_count=${#report[@]}+1` (=32) and the "G.4 must stay last" Summary tripwire — untouched. No Step/step added/removed/reordered → tally stays 32.

## verify_all result
- **Baseline (pre-edit):** PS **32 PASS / 0 WARN / 0 FAIL** (exit 0); SH **32 PASS / 0 WARN / 0 FAIL** (exit 0). G.4 PASS both.
- **After changes:** PS **32 PASS / 0 WARN / 0 FAIL** (exit 0); SH **32 PASS / 0 WARN / 0 FAIL** (exit 0). G.4 PASS both (count-only rows match the de-versioned claims; CHANGELOG `[0.21.1]` still present; G.3 stamps still 0.21.1).
- **Delta:** 0 new failures, 0 new warnings, baseline preserved. Count stays 32.

### AC-4 exhaustiveness grep (§8) — ZERO version-bearing count claims in live tree
```
grep -rn -E 'checks? at v[0-9]|[0-9]/[0-9]+ at v[0-9]|项检查.{0,8}v[0-9]' --include='*.md' --include='*.json' .
  | grep -v CHANGELOG.md | grep -v docs/features/ | grep -v '\.html' | grep -v _archived/
→ exit 1, ZERO matches  (PASS)
```
`git grep "at v0.21.1"` afterward → only `docs/features/_archived/i4-cap-symmetry/04_DEVELOPMENT.md` (historical) + `docs/features/g4-version-decouple/**` (this task's own stage docs). No live source/doc/CHANGELOG/HTML retains the token. CHANGELOG.md: zero `at v0.21.1` hits (uses `[0.21.1]` heading form). Count sanity: `32/32` + `32 checks` still present in all 6 edited files (only VERSION removed, not counts).

### git diff --stat
```
 .harness/rules/40-locations.md  |  2 +-
 .harness/scripts/verify_all.ps1 | 12 ++++++------
 .harness/scripts/verify_all.sh  | 24 ++++++++++++------------
 AI-GUIDE.md                     |  4 ++--
 docs/dev-map.md                 |  4 ++--
 docs/manual-e2e-test.md         |  2 +-
```
(`docs/tasks.md` also shows in `git status` — that is the PM's T-010 tracking row, pre-existing in the working tree, not a developer edit.)

## Design drift (if any)
None. Implementation matches `02_SOLUTION_DESIGN.md` §5/§6/§7 byte-for-byte; both R-7 (row-4 paren) and R-3 (PS/Bash symmetry) handled as specified.

## Open issues for review
None. Version NOT bumped (per task scope — the v0.21.2 ship bump is a separate later step).

## Dev-map updates
None — no project-structure change (no files added/moved/removed). `docs/dev-map.md:60,133` were edited only to remove the version token from their prose count claims (part of the §6 decouple, not a structural change).

## Verdict
READY FOR REVIEW

---

## Rework round 1 (rollback #1)

**Stage:** 4 (Developer, rework) · **Date:** 2026-06-06 · **Inputs:** `06_TEST_REPORT.md` (QA D-1 MAJOR + D-2 NIT).
**Scope:** fix exactly D-1 + D-2; rows 6-11, CHANGELOG check, `$version` derivation, tripwire, `.claude/settings.json` and upstream docs untouched. Version NOT bumped, count stays 32.

### D-1 (MAJOR) — same-file substring collision masked dev-map:60 count drift

**Reproduce FIRST (systematic debugging).** QA's bash full-suite wedges on the pre-existing I.6 `git ls-files × grep` fork-storm on this Windows host (exit 124 / `timeout`, after I.7, untouched by T-010), so — like QA §1 — I ran the **G.4 ledger block verbatim** from `verify_all.sh` against the live tree with `g4_count=32` (throwaway probe, validated to PASS on the clean tree = full-suite equivalent, deleted after use). The **current/broken** row-3 (`shape='[0-9]+ checks'`, `expect="32 checks"`):
- Clean tree → G.4 **PASS** (baseline OK).
- `docs/dev-map.md:60` `(32 checks)`→`(31 checks)`, L133 left at `runs all 32 checks` → G.4 **PASS (exit 0)** — *drift NOT caught.* **D-1 reproduced.** Root cause confirmed exactly as QA proved: row-3 `expect="32 checks"` is a substring of row-4 text `runs all 32 checks` on L133, so the whole-file `.Contains`/`==*..*` test is satisfied by L133 even when L60 drifts. Reverted L60.

**Fix — row 3 (`docs/dev-map.md`, the L60 row), BOTH shells, made UNIQUE to L60.** L60 literally reads `Total verification (32 checks)` (parenthesized, closing paren); L133 reads `runs all 32 checks` (no `(` before the count post-decouple). So row 3 now keys on the parenthesized form:
- `verify_all.ps1:656` — `shape '\d+ checks'`→`'\(\d+ checks\)'`; `expect "$count checks"`→`"($count checks)"`.
- `verify_all.sh` g4_shapes idx2 (L704) `'[0-9]+ checks'`→`'\([0-9]+ checks\)'`; g4_expects idx2 (L717) `"$g4_count checks"`→`"($g4_count checks)"`. Semantically identical to PS (R-3 symmetry preserved; 11-row arrays still aligned).

**Collision re-check (whole-file uniqueness invariant) — all clean:**
- **dev-map pair now disjoint:** `(32 checks)` (row 3) occurs ONLY on L60; `runs all 32 checks` (row 4) ONLY on L133. L133 does NOT contain `(32 checks)`; L60 does NOT contain `runs all 32 checks`. No mutual masking.
- **AI-GUIDE pair had NO latent bug** (verified, not assumed): row-1 `32/32` occurs ONLY on L36 (`(32/32; check count grows…)`); row-2 `32 checks` ONLY on L69 (`(32 checks, including…)`). L36 has no `32 checks` substring; L69 has no `32/32`. Distinct forms → no collision; no change needed there.
- **Row 5 cross-file, safe:** row-5 `(32 checks` lives in `.harness/rules/40-locations.md` (different file from dev-map); each `.Contains` reads only its own file, so dev-map row-3 `(32 checks)` and 40-locations row-5 `(32 checks` never interact.

**AC-2 dev-map-pair re-verify (post-fix), BOTH shells — drift now caught both lines:**

| Case | PS (full `verify_all.ps1`) | bash (verbatim-block probe) |
|---|---|---|
| clean tree (L60+L133 = 32) | **PASS** 32/0/0, G.4 PASS | **PASS** (count=32, v0.21.1) |
| dev-map:60→`(31 checks)`, L133=32 | **FAIL** — `[G.4] found '(31 checks)', expected '(32 checks)'`, 31/0/1 | **FAIL** — same message, exit 1 |
| dev-map:133→`runs all 31 checks`, L60=32 | **FAIL** — `[G.4] found 'runs all 31 checks', expected 'runs all 32 checks'`, 31/0/1 | **FAIL** — same message, exit 1 |
| both reverted | **PASS** 32/0/0 | **PASS** |

The L60-alone drift QA filed as D-1 is now caught in **both** shells; L133 still independently gated (row 4 unchanged); a full both-line count bump still caught on both rows.

### D-2 (NIT cosmetic) — stale "version-anchored" comment

`verify_all.ps1:645-652` / `verify_all.sh:679-687` ledger-block comment updated: dropped "version-anchored" (post-decouple rows 1-5,10 are count-only) → now reads "count-anchored (parenthesized `(N checks)` / `runs all N checks` / `N/N` ratio / badge `verify__all-N%2FN` / full-width-paren `（N 项检查）` / JSON-field forms)". Added a one-line **same-file uniqueness invariant** note (the dev-map L60+L133 / AI-GUIDE L36+L69 pairs must each have a file-unique `expect` or a sibling line masks drift) so the D-1 trap is documented in-code. Both shells, semantically identical.

### Re-run evidence (declare-done gate)

- **PowerShell full suite** (`verify_all.ps1`, restored tree): **32 PASS / 0 WARN / 0 FAIL**, `[G.4] PASS`, exit 0. The fixed row-3 still matches the real L60 `(32 checks)` so G.4 stays green on the live tree.
- **bash G.4** (verbatim-block probe, fixed row-3, restored tree): **PASS** (count=32, v0.21.1). Full `verify_all.sh` suite gets through to I.6 then wedges on the documented environmental fork-storm (exit 124) — same characteristic QA hit; not a regression of this change (T-010 edits only the G.4 ledger). Authentic bash G.4 evidence obtained via the QA-validated isolation method.
- **D-1 reproduce, post-fix:** the exact mutation that wrongly PASSed pre-fix (`dev-map:60`→`(31 checks)`) now FAILs G.4 in both shells (table above), plus the symmetric L133 case.

### Tree hygiene
Throwaway probe scripts (`.harness/scripts/_g4probe*.sh`) deleted; all mutations reverted via file snapshots (not `git restore` — the decouple is uncommitted). Final `git status --porcelain`: the original 6 decouple edits + this rework's edits to `verify_all.{ps1,sh}` only + PM's `docs/tasks.md` + untracked feature dir + pre-existing `docs/system-overview.html`. `docs/dev-map.md` diff is byte-identical to the pre-rework decouple (rework touched no doc).

### Files changed (rework)
- `.harness/scripts/verify_all.ps1` — row-3 (dev-map L60) `shape`/`expect` → `(32 checks)` form (L656); ledger comment de-versioned + uniqueness-invariant note (L645-652).
- `.harness/scripts/verify_all.sh` — row-3 (idx 2) `shape`/`expect` → `(32 checks)` form (L704/L717); ledger comment de-versioned + uniqueness-invariant note (L679-687).

### Design drift / dev-map updates
None. No project-structure change. D-1's fix is the discriminator QA itself suggested in `06_TEST_REPORT.md` §4 (`expect="(32 checks)"`, `shape=\(\d+ checks\)`). No upstream doc (01/02/03/05/06) edited.

## Rework verdict
REWORK COMPLETE — D-1 fixed (row-3 expect (32 checks), dev-map:60 drift now caught both shells), D-2 comment fixed, verify_all PS 32/32 SH 32/32

---

## Version bump v0.21.2 (release pass)

**Stage:** 4 (Developer, ship bump) · **Date:** 2026-06-06 · **Type:** patch, count UNCHANGED at 32.
**Self-demonstration of T-010:** because the 6 prose count claims are now version-less (decoupled this task), this patch touches ONLY the G.3 stamps + CHANGELOG — the prose count "treadmill" is gone. The 6 prose claims (AI-GUIDE:36/:69, dev-map:60/:133, 40-locations:25, manual-e2e:3) were **NOT** edited for the version (AC-3 self-demo). I did not need to.

### Files changed (exactly 5 — G.3 stamps + CHANGELOG only)
- `.claude-plugin/plugin.json:4` — `"version": "0.21.1"` → `"0.21.2"`.
- `.claude-plugin/marketplace.json:17` — `plugins[0].version` `"0.21.1"` → `"0.21.2"`.
- `README.md:5` — version badge `version-0.21.1-blue` → `version-0.21.2-blue` (the `verify__all-32%2F32` count badge left untouched).
- `README.zh-CN.md:5` — version badge `version-0.21.1-blue` → `version-0.21.2-blue` (count badge untouched).
- `CHANGELOG.md` — NEW top entry `## [0.21.2] - 2026-06-06` inserted between `[Unreleased]` and `[0.21.1]`; describes the G.4 count-only decouple. No older entry rewritten.

### NOT edited (self-demonstration — the 6 prose count claims, version-less)
Explicit confirmation: `git diff -- AI-GUIDE.md docs/dev-map.md .harness/rules/40-locations.md docs/manual-e2e-test.md | grep '^+.*0\.21\.2'` → **ZERO** matches. No `0.21.2` was added to any prose-claim file. Current working-tree content of all 6 claims is the version-less form from the T-010 decouple (`32/32`, `32 checks`, `(32 checks)`, `runs all 32 checks`, `(32 checks`, `32 checks`) — untouched by this bump. Their presence in `git diff --name-only` is solely the uncommitted T-010 decouple edits (which REMOVED the version token), not this version bump. G.4 logic, the count value (32), `.claude/settings.json`, test-supervisor, archive-task, and the `.tmpl` files were also left untouched.

### verify_all result
- **Baseline (pre-bump, v0.21.1):** PS **32 PASS / 0 WARN / 0 FAIL** (exit 0), G.3 + G.4 PASS.
- **After bump (v0.21.2):**
  - **PowerShell** (`verify_all.ps1`, full suite): **32 PASS / 0 WARN / 0 FAIL** (exit 0). G.3 PASS (all 4 stamps consistent at 0.21.2), G.4 PASS.
  - **bash** (`verify_all.sh`, full suite): wedged at **exit 124** on the pre-existing I.6 `git ls-files × grep` MSYS fork-storm (got through I.7 then hung on I.6 — the documented environmental issue, insight L27; NOT a regression of this 5-file doc bump). **Method used: verbatim-block probe** — extracted the G.3 (lines 351-373) and G.4 (lines 656-756) blocks verbatim from `verify_all.sh`, `g4_count` forced to the live tally 32 (confirmed by the PS full run's `${#report[@]}+1`), run against the live tree, throwaway probe deleted after use:
    - `[G.3] PASS` — plugin=0.21.2 marketplace=0.21.2 README=0.21.2 README.zh-CN=0.21.2 (all four consistent).
    - `[G.4] PASS` — plugin=0.21.2, count=32, CHANGELOG `[0.21.2]` heading present; the count-only prose rows still match the untouched de-versioned claims.
- **Delta:** 0 new failures, 0 new warnings, baseline preserved. Count stays 32.

### git grep "0.21.1" residual (post-bump)
All historical — no live current-state stamp remaining:
- `CHANGELOG.md:14` — the `[0.21.1]` historical changelog entry (correct, must remain).
- `docs/features/_archived/i4-cap-symmetry/**` — archived T-009 stage docs (04/07/PM_LOG).
- `docs/tasks.md:24` — T-009 delivery record (historical PM tracking row).
- No v0.21.1 Roadmap row present. **No live current-state 0.21.1 stamp remains.**

### Design drift / dev-map updates
None. No project-structure change (no files added/moved/removed). No upstream doc (01/02/03/05/06) edited.

## Version bump verdict
VERSION BUMP COMPLETE — v0.21.2 · 5 files (stamps+CHANGELOG only, 6 prose claims untouched — treadmill gone) · verify_all PS 32/32 SH G.3=0.21.2 PASS + G.4 PASS via verbatim-block probe (full suite wedged on pre-existing I.6 MSYS fork-storm, exit 124)
