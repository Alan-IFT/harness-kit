# 05 — Code Review · i4-cap-symmetry (T-009)

> Stage 5. Independent audit of 04 against 02 (§5/D1-D4) + 03 conditions C-1..C-5. Verified at file:line. Persisted by PM (CR read-only).

## Focus verification
1. **I.4 both shells (core):** PS:398 `@(Get-Content … | Where-Object { $_ -match '^\s*-\s+' }).Count` (`@()` intact); bash:419 `grep -c '^[[:space:]]*-[[:space:]]' … || true` (`|| true` intact, C-1; live `set -uo pipefail` confirmed). Regexes membership-equivalent — reasoned through `- 2026-..` (both match), `---` HR (both reject), blank (both reject), `  - sub` (both match). `>30` threshold + WARN/PASS preserved (PS:399 / bash:420). "evidence lines" wording updated in BOTH shells, no half-update. ✅
2. **No new check / tally:** 32 PS Steps (Grep); I.4 is one in-place Step; G.4 derives `${#report[@]}+1=32` (comment confirms 31+G.4). Tally held at 32. ✅
3. **Cross-shell symmetry (L13):** both count matching *records* not newline separators → immune to no-trailing-newline + CRLF (the off-by-one that caused the original split). Could not disagree on a real index. Live Grep = 25 → both PASS. ✅
4. **Rule doc-sync + C-3:** `05-insight-index.md:5,25` + `70-doc-size.md:27` → "evidence lines"; the 3 `.tmpl` siblings (under `skills/harness-init/templates/...`) still "30 lines"/"30 行" — NOT edited (C-3 ✅). E.4b path index untouched; I.6 anchors contain no "lines"/"evidence"/"30" → wording swap safe. ✅
5. **baseline ↔ manual-e2e (D4/C-4):** `manual-e2e-test.md:3` = 251/213; `baseline.json:11,12` = 251/213 (already canonical, no edit); stale 227/191 corrected in manual-e2e. Internally consistent + plausible. Verification ceiling: CR can't re-run test-init to confirm the capture (G.4 doesn't gate test_init counts) — rests on Dev discipline + QA re-run. ✅
6. **Scope:** settings.json, G.4, archive-task, insight-index.md itself all untouched; only the 6 design-specified files. Remaining bash `wc -l` (:379/393/407/431) are the legit total-line I.1/I.2/I.3/I.5 checks. ✅
7. **WARN genuinely RESOLVED not masked:** PASSes because correct metric = 25 (<30), NOT threshold loosening (`>30` intact) or neutering. A ≥31-evidence-line index would still fire the WARN in both shells. ✅

## Findings
- **BLOCKER:** none. **MAJOR:** none.
- **MINOR [LOGIC]** bash I.4 uses BRE `grep -c` while archive-task.sh:69 uses ERE `grep -E`; the dev doc's "verbatim regex" overstates it. NOT a defect — pattern has no ERE-only metachars (`*`, `[[:space:]]`, literal `-`, `^` identical in BRE/ERE) → same count. Wording-precision note only.
- **NIT [MAINT]** `.harness/insight-index.md:3` header blockquote still "≤30 lines." — correctly left untouched (D2/OOS, no index edit).
- **NIT [MAINT]** `docs/dev-map.md:134` (version-pinned "at v0.16.0", historical) + `docs/project-overview.html:299` (visual artifact) still carry stale 227/191 — outside the design's reconcile scope (§2 scoped to manual-e2e:3 + baseline:11,12). Noted for awareness.

## Coverage / fidelity
AC-1/6 parity ✅ · AC-3 metric≡rotation ✅ · AC-5 count=32 ✅ · AC-7 doc-sync safe ✅ · C-1..C-5 all met (C-4/C-5 rely on Dev's reported run — QA to re-confirm) · D1 data-metric ✅ · D2 no-rotate ✅ · D3 byte-identical+`@()`+`||true` ✅ · D4 baseline canonical ✅. No design drift.

## Verdict
**CODE REVIEW VERDICT: APPROVED** — I.4 now counts 25 evidence lines (<30) identically in both shells, WARN genuinely resolved not masked, tally held at 32, doc-sync + C-3 templates correct; only 1 MINOR + 2 NIT, all non-blocking. (QA should independently re-run test-init to close the 251/213 capture ceiling + verify both-shell verdict parity on synthetic over/under-cap fixtures.)
