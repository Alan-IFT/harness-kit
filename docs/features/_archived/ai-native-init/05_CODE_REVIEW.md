# 05 — Code Review · ai-native-init (T-002)

Mode: `full` · Stage: 5/7 · Author: Code Reviewer (read-only; persisted by PM) · Date: 2026-05-19

## 6-dimension audit

| # | Dimension | Verdict | Evidence |
|---|---|---|---|
| 1 | Logic correctness | PASS | D.3 (PS+Bash) is per-section as required (Gate Finding G). Bash uses `d3_files=()` safe init (insight L13). `_ai-native-prompt.md` has no `{{...}}` leak. Mock has source annotations on all 6 sections. |
| 2 | Requirement fidelity | WARN | 10/12 ACs verifiable. AC-2 (≤100 entry cap) not asserted; AC-3/AC-10 asserted only as file existence, not byte equality. |
| 3 | Design fidelity | PASS | All §4 change-set entries touched. All 4 Gate findings (A/D/F/G) honored at concrete code locations. |
| 4 | Performance | PASS | D.3 iterates only `50-*.md` files. Mock fixture short-circuits live LLM. Input caps in SKILL.md. |
| 5 | Security | PASS | 50 KB manifest cap, 100-entry Glob cap, no shell injection, reserved-name filter present. |
| 6 | Maintainability | WARN | CHANGELOG drift on 219/222 number. Otherwise clean. |

## Findings

### CRITICAL — none.

### MAJOR

- **M-1 / DOC-DRIFT** — `CHANGELOG.md:45,47` say "219 assertions" / "v0.16.0 / 29 / 219" while every other release file says **222 PS / 186 Bash**. The exact failure mode insight-index L14 was created to prevent, in the release that claimed to sweep L14.
- **M-2 / TEST** — `scripts/test-init.{ps1,sh}` AC-10 ("byte-identical to v0.15.1 output when opt-out chosen") asserted only as `Test-Path`. No byte-level comparison against a v0.15.1 frozen reference. AC-10 is the load-bearing backwards-compat claim.
- **M-3 / TEST** — `scripts/test-init.{ps1,sh}` `[AI-out]` and `[AI-in]` assertions execute in the **same temp dir** back-to-back. No discrete "Q6=No, full init, end state" test pass. A regression breaking only the Q6=No branch could pass test-init.

### MINOR

- **R-1 / COVERAGE** — AC-2 has zero test coverage (defensible: cap lives in SKILL.md prose).
- **R-2 / DOC** — `04_DEVELOPMENT.md:12` says `_ai-native-prompt.md` is 136 lines; actual is 178.
- **R-3 / TEST** — `scripts/test-init.sh:347` uses unquoted `$n_sources` in `(( ... ))` — risk of parse error masking real failure.
- **R-4 / TEST** — D.3 is vacuously passing in this repo (no `.harness/rules/50-*.md` exists). Consider committing positive/negative fixtures.

### NIT

- **N-1 / STYLE** — `scripts/verify_all.sh:152-159` two-pass regex+allowed-tag lookup deserves a comment for maintainers.
- **N-2 / STYLE** — `SKILL.md:76-80` Q6 description is one 1100-char paragraph.

## Spot-check: 4 binding Gate findings

| Finding | Honored | Evidence |
|---|---|---|
| A — zh AI-GUIDE.md.tmpl conditional | YES | `templates/i18n/zh/common/AI-GUIDE.md.tmpl:23` has the marker, parallel to English `:23`. |
| D — AI-GUIDE.md:35 AND :67 bumped | YES | Both lines now `29/29 at v0.16.0` / `29 checks at v0.16.0`. (But sweep incomplete in CHANGELOG — see M-1.) |
| F — re-Read every Write/Edit | YES | `SKILL.md:233-237` (write+re-Read) and `:254-257` (Edit+re-Read); harness-adopt mirrors at `:150`. |
| G — D.3 per-section (not file-global) | YES | `verify_all.ps1:147-178` loops over heading-split sections; `verify_all.sh:130-174` mirrors via awk. |

## AC verification

| AC | Asserted at | Status |
|---|---|---|
| AC-1 | `test-init.ps1:344-349` + Bash :342-345 | PASS |
| AC-2 | (none — SKILL prose only) | MINOR (R-1) |
| AC-3 | `test-init.ps1:282-287, 344-345` (Test-Path only) | WARN (M-2, M-3) |
| AC-4 | `test-init.ps1:385-397` | PASS |
| AC-5 | `test-init.ps1:362` + Bash :351 | PASS |
| AC-6 | `verify_all.ps1:118-145`; `test-init.ps1:301-315` | PASS |
| AC-7 | `verify_all.ps1:160-178` (per-section) | PASS (Finding G honored) |
| AC-8 | `verify_all.ps1:136-138`; `test-init.ps1:317, 361` | PASS |
| AC-9 | `docs/manual-e2e-test.md:3` + 8 other files | WARN (CHANGELOG drift, M-1) |
| AC-10 | (Test-Path only, not byte cmp) | WARN (M-2, M-3) |
| AC-11 | `test-init.ps1:367-381` | PASS |
| AC-12 | 29/29 PASS confirmed | PASS |

## Verdict

# `CHANGES REQUIRED`

PM action: route back to Developer to address the 3 MAJOR findings:

1. **M-1** — Edit `CHANGELOG.md:45,47` from "219" → "222 PS / 186 Bash" matching the rest of the release.
2. **M-2 / M-3** — Two acceptable resolutions:
   - **(preferred)** Add a byte-comparison assertion for the opt-out path against a frozen v0.15.1 reference (snapshot the `50-<type>.md` template content as a known-good string in test-init), AND run opt-out and opt-in as separate test invocations in separate temp dirs.
   - **(acceptable, less rigorous)** Down-scope the AC-10 claim in `04_DEVELOPMENT.md` and CHANGELOG to "structural identity; byte-identical guarantee deferred", and update the FR/AC numbering in 01_REQUIREMENT_ANALYSIS.md with a `<!-- code-review-M-2/M-3 -->` note.

MINOR/NIT findings (R-1..R-4, N-1, N-2) may be deferred to v0.16.1 or addressed inline at Developer's discretion if the M-* fixes are trivial.

Re-review required after Developer's fix.

---

## Round 2 — post-rollback audit (2026-05-19)

### M-1 — RESOLVED
- `CHANGELOG.md:43,45,47,55` now consistently say 225 PS / 189 Bash-no-python3.
- Canonical fan-out reconciled: `README.md:5,158`, `README.zh-CN.md:5,158`, `architecture.html:327`, `docs/dev-map.md:75,127`, `docs/manual-e2e-test.md:3`.
- Remaining "219" occurrences confined to feature-folder historical docs (02/04/05/PM_LOG) — by-design audit trail, not release-facing.

### M-2 — RESOLVED
- PS `test-init.ps1:289-340`: genuine byte-compare via `[System.IO.File]::ReadAllBytes` with per-byte loop, not file-size or first-N-chars.
- Bash `test-init.sh:271-300`: `cmp -s` (POSIX byte-exact) with `[[ -s ... && -f ... ]]` precondition guarding the "no source template" sentinel.
- `.md.tmpl` substitution faithfully mirrors `Copy-TemplateLayer` (PS) and calls `substitute` (Bash).

### M-3 — RESOLVED
- PS uses `$optOutTmp = Join-Path ... "harness-test-optout-$(Get-Random)"` (distinct basename, own try/finally cleanup).
- Bash uses `mktemp -d -t harness-test-optout-XXXXXX` (distinct template, own `rm -rf`).
- AC-10 byte-compare runs only inside the opt-out dir; AI-native opt-in simulation never touches it.

### New regressions — none
- No conflict markers, no TODO/FIXME introduced in `scripts/`.
- NIT (not blocking): PS byte-compare inline-re-implements `Copy-TemplateLayer`'s substitution — acceptable test-internal duplication.

### Round-2 verdict

# `APPROVED`

Advance to QA Tester.
