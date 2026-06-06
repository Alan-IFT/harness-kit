# 05 — Code Review · g4-version-decouple (T-010)

> Stage 5. Independent audit of 04 against 02 (§5/§6/§7) + 03 AC-2 proof. Verified at file:line. Persisted by PM (CR read-only).

## Findings: BLOCKER 0 · MAJOR 0 · MINOR 0 · NIT 1

## 1. AC-2 preserved (critical) — VERIFIED, no degradation
All 6 decoupled rows, both shells — every new `expect` keeps the count `32` + a count-adjacent discriminator (none degraded to a count-less loose match):
| Row | File | PS expect | Bash expect | 32→31→FAIL? |
|---|---|---|---|---|
| 1 | AI-GUIDE:36 | `"$count/$count"` (:650) | `"$g4_count/$g4_count"` (:711) | yes |
| 2 | AI-GUIDE:69 | `"$count checks"` (:651) | (:712) | yes |
| 3 | dev-map:60 | `"$count checks"` (:652) | (:713) | yes |
| 4 | dev-map:133 | `"runs all $count checks"` (:653) | (:714) | yes |
| 5 | 40-locations:25 | `"($count checks"` (:654) | (:715) | yes |
| 10 | manual-e2e:3 | `"$count checks"` (:659) | (:720) | yes |
Load-bearing test = literal-contains (PS:666 `.Contains` / sh:732 `== *..*`). A doc saying `31 checks` → `32 checks` not a substring → contains false → shape ERE reports `found '31 checks', expected '32 checks'` → FAIL. Intact every row, both shells. `$count`=`$report.Count+1`=32.

## 2. The 6 prose edits — VERIFIED clean
`at v0.21.1` gone from each; surrounding prose preserved; each de-versioned line still CONTAINS its G.4 expect literal: AI-GUIDE:36 `(32/32; check count grows...)`; AI-GUIDE:69 `(32 checks, including...)`; dev-map:60 `(32 checks)`; dev-map:133 `runs all 32 checks including ...` (**R-7 clean** — whole `(at v0.21.1)` removed, ONE space, no orphan `()`); 40-locations:25 `(32 checks, all must PASS — ...)`; manual-e2e:3 `verify_all at 32 checks;` (sibling counts 251/213, 49/45, 56/56 untouched).

## 3. Untouched surfaces — VERIFIED
Rows 6,7 (badges), 8 (`(\d+ checks\)`), 9 (`（\d+ 项检查）`), 11 (baseline.json) shape/expect unchanged both shells; source literals live (README `(32 checks)`, README.zh `（32 项检查）`, baseline `"verify_all_checks": 32`). CHANGELOG `[$version]` check present (PS:675-678/sh:742-744; `[0.21.1]` heading live). `$version`+`throw` guard (PS:638-640) / `g4_version`+`-z` FAIL (sh:670,675-677) KEPT (R-5, consumed by CHANGELOG). Tally `$report.Count+1` + tripwire unchanged; no Step added/removed; 11 rows; tally 32.

## 4. No version bump — VERIFIED
plugin.json/marketplace.json/README badges/CHANGELOG all still 0.21.1. Dev correctly deferred the bump to the separate ship step.

## 5. AC-4 exhaustiveness — VERIFIED (independent grep)
Own grep (`checks? at v` / `\d/\d+ at v` / `项检查…v`) over live `*.md`/`*.json` → matches ONLY in CHANGELOG history + `docs/features/**` (exempt). ZERO live count claims retain a version token. No 7th claim missed.

## 6. No false-match / no regression — VERIFIED
HTML scan for the count-only literals (`runs all 32 checks`, `(32 checks`, `32/32`, `（32 项检查）`, `32%2F32`) → ZERO HTML hits (snapshots carry OLD counts + `N checks at vX`, distinct form). `expect`-contains short-circuits (`continue`) before the shape ERE in both shells → stale history can't false-PASS. G.4 still PASS on de-versioned docs; CHANGELOG check still gates version.

## 7. PS/Bash symmetry (L13) — VERIFIED
6 edits semantically identical: PS `$claims` idx 1-5,10 ↔ sh `g4_shapes`/`g4_expects` idx 0-4,9; same token deleted, mirrored EREs (`\d+`↔`[0-9]+`), `g4_files` order matches PS row order.

## NIT
- [MAINT] `verify_all.ps1:647-648` / `verify_all.sh:680-681` block comment still says patterns "stay … version-anchored"; post-decouple rows 1-5,10 are no longer version-anchored. Cosmetic only (behavior correct; design §7 flagged as non-required). → PM will fold the 1-line comment fix into the v0.21.2 ship pass.

## Coverage / fidelity
AC-1 ✅ · AC-2 ✅ (count kept all rows both shells) · AC-3 ✅ (mechanism: claims count-only; CHANGELOG+G.3 retain version) · AC-4 ✅ (grep zero) · AC-5 ✅ (tally/tripwire unchanged, symmetric, PS/SH 32/32). §5.2/§5.3/§6/§7 fidelity ✅; `$version` kept ✅; no bump ✅.

## Verdict
**CODE REVIEW VERDICT: APPROVED** — all 5 ACs satisfied, AC-2 count-drift FAIL preserved on every decoupled row in both shells, independent AC-4 grep shows zero version-bearing count claims; only a cosmetic comment NIT (folded into the ship pass).

---

## Re-review (rollback #1) — VERDICT: APPROVED

Focused verification of the D-1 fix + a systematic same-file-uniqueness audit (the bug class the original review missed).

**D-1 fix — VERIFIED both shells.** Row 3 (dev-map:60) now `shape=\(\d+ checks\)` / `expect="(32 checks)"` (PS:656; sh idx2 :704/:717). `(32 checks)` occurs ONLY on dev-map L60 (L133 `runs all 32 checks` has no `(` before the count) → a L60 `(32 checks)`→`(31 checks)` drift removes the file's only occurrence → whole-file Contains FALSE → FAIL. Row 4 still L133-unique. AC-2 holds (count `32` kept in expect).

**Systematic same-file-uniqueness audit (all 11 rows) — NO other collision.** G.4 matches whole-FILE, so multi-row files need each `expect` file-unique:
| File | Rows | Expects | Unique? |
|---|---|---|---|
| AI-GUIDE.md | 1,2 | `32/32` (L36), `32 checks` (L69) | YES (was always safe) |
| dev-map.md | 3,4 | `(32 checks)` (L60), `runs all 32 checks` (L133) | YES (D-1 fix) |
| README.md | 6,8 | `verify__all-32%2F32` (L5), `(32 checks)` (L159) | YES (distinct forms) |
| README.zh-CN.md | 7,9 | `verify__all-32%2F32` (L5), `（32 项检查）` (L159) | YES |
Single-row files (40-locations row5, manual-e2e row10, baseline row11) — no same-file collision possible. **Cross-file same-expect non-interfering:** row 3 `(32 checks)` (dev-map) and row 8 `(32 checks)` (README) share the string but each row reads ONLY its own `file`/`g4_files[i]` → cannot mask each other (verified the file-pinning). Only the dev-map pair was ever collision-prone; now fixed.

**D-2 comment — VERIFIED.** "version-anchored"→"count-anchored" both shells, + the same-file uniqueness invariant now documented in-code at the trap site.

**Scope/regression — VERIFIED.** Only verify_all.{ps1,sh} changed (row-3 + comment); rows 1,2,4-11 + CHANGELOG check + `$version` derivation/guards + tripwire untouched; count 32; plugin.json 0.21.1 (no bump). (verify_all.sh full run not runnable here — pre-existing I.6 MSYS wedge; reasoned from code + dev's PS full-run + bash verbatim-block probe; QA to re-execute the mutation matrix.)

**CODE REVIEW VERDICT: APPROVED** — D-1 resolved (file-unique `(32 checks)` both shells, L60-alone drift now FAILs), systematic audit finds no other same-file collision, D-2 fixed, no regression, no bump.
