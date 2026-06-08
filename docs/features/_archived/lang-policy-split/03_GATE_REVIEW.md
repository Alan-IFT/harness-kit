# 03 — Gate Review · T-013 / lang-policy-split

> Stage 3. Reviewer: Gate Reviewer (read-only). Persisted by PM.
> Reviewed against the resolved OQ baseline (all 6 RA defaults accepted; PM_LOG).

## Verdict: CHANGES REQUIRED — 1 BLOCKING, 3 ADVISORY

Design is structurally sound and the #1 risk (CJK-I.6 cross-shell) is verified correct. One
blocking gap: the I.6 retired-phrase sweep missed a live tracked non-exempt file that contains the
exact retired phrase the new banned-line targets → adding the banned-line as designed FAILs verify_all.

## 8-dimension audit
| # | Dimension | Result | Reason |
|---|---|---|---|
| 1 | Requirement completeness | PASS | §4 table + §8 ACs concrete/verifiable; OQ baseline fully resolved. |
| 2 | Design completeness | **FAIL** | I.6 sweep missed `docs/project-overview.html:314` (F-1). |
| 3 | Reuse correctness | PASS | I.6 matcher (`grep -E` not `-F`), copy_layer sig, test_migrate dispatch, G.3 4-site gate all verified as cited. |
| 4 | Risk coverage | WARN | R4 ("banned-line too broad") materialized as a concrete missed hit (F-1). |
| 5 | Migration safety | PASS | Pure content/script; git revert restores 0.23.0; EN path provably untouched. |
| 6 | Boundary handling | PASS | present/absent assertions use DIFFERENT strings (no T-007 trap); no-python3 path = pure greps; zero new `{{...}}`. |
| 7 | Test feasibility | PASS | zh fixture feasible — copy_layer strips `.tmpl` + substitutes PROJECT_NAME/PROJECT_TYPE/STACK/TODAY; no `{{LANG}}` in any zh body. |
| 8 | Out-of-scope clarity | PASS | (A)/(B) discipline honored; OQ-3 deferred; EN path byte-unchanged; dogfood untouched. |

## CJK-I.6 verification (the most important check) — CORRECT, verified in both live matchers
- Mechanism: `verify_all.sh:571` `grep -E -n -i -m1` (ERE, not `grep -F` → no MSYS SIGABRT); exclude via bash `nocasematch` glob (`:582-587`). `verify_all.ps1:541` `[regex]::new(...,IgnoreCase)` over UTF-16 (CJK-safe) + `IndexOf(OrdinalIgnoreCase)`. No `grep -F` anywhere in I.6.
- CJK literals already ship green: `verify_all.sh:533-535` / `verify_all.ps1:498-500` (生成/合成/重新生成的). Proposed `全程~中文` ordered-anchor fits the exact structure (empty gap field → `i6_gap_default=40`).
- New policy text never contains "全程" → cannot self-trip. test-init absence-assert isolates bare `全程` on its own line (never 全程+中文 together) → not tripped.
- Conclusion: matcher not broken, guard does not self-trip. The #1 risk resolution holds.

## Findings

### F-1 — BLOCKING — missed I.6 site `docs/project-overview.html:314` (→ solution-architect)
The design's sweep (§9.2/§9.4) + F-list do not include `docs/project-overview.html`, but it is a
live, git-tracked, NON-exempt scanned file and line 314 contains `中文项目全程中文` ("全程" immediately
followed by "中文", gap 0). Adding the `全程~中文` banned-line → **I.6 FAILs on this file** → verify_all
FAILs → CLAUDE.md red line + AC-8 violated.
- Git-tracked (AI-GUIDE:65 lists it as a deliverable; not in the `??` untracked list, unlike sibling `docs/system-overview.html`).
- NOT in I.6 exempt list (which holds only `architecture.html` + `docs/walkthrough.html`, `verify_all.sh:549-550`).
- `docs/walkthrough.html:284` has "全程" but no "中文" within 40 chars + is exempt anyway → non-hit.
- Fix (architect's call): (i) add to F-list + rewrite line 314, OR (ii) add to I.6 exempt-files as a dated snapshot like its siblings. **PM note: the file is an explicit archived v0.17.0 snapshot (`docs/project-overview.html:765` "生成于 2026-05-19 · Harness Kit v0.17.0 · 本页面归档于...") — same class as the exempt architecture.html/walkthrough.html → exemption is the consistent fix; do NOT rewrite a frozen snapshot.**

### F-2 — ADVISORY — read test-init count baseline empirically (§10.5)
Design computes PS 227→231 / Bash 191→195; badge reads `test--init-227%2F227`. Counts are informational (not G.3/G.4-gated). Dev: stamp from the real run, not arithmetic.

### F-3 — ADVISORY — mirror the new I.6 entry into `test-verify-i6.{ps1,sh}` (§9.5)
Those files hold a verbatim copy of the banned list (comment at `verify_all.sh:518`) and are themselves I.6-exempt (`verify_all.sh:553-554`). Add `全程~中文` there too or the lockstep regression FAILs. Run `test-verify-i6` both shells.

### F-4 — ADVISORY — CHANGELOG `[Unreleased]` adjudication (architect's flagged question)
Live CHANGELOG: `## [Unreleased]` (`:8`) holds shipped ambient-stream (T-011) work (commits f500942/01502c0, self-described "no version bump"); `## [0.23.0]` (`:26`) is T-012. **PM/Gate recommendation: fold the ambient `[Unreleased]` content into `[0.24.0]`** — rename `[Unreleased]` → `## [0.24.0] - 2026-06-08`, append the T-013 entry, leave NO orphan `[Unreleased]`. Rationale: cutting 0.24.0 means the ambient work is now released; leaving it perpetually "Unreleased" under a newer section is dishonest (Keep-a-Changelog). Either structure keeps G.2/G.4 green (G.2 needs only the 13 skill mentions — no new skill; G.4 reads version from manifests + count from `$report.Count`, not CHANGELOG layout).

## Pre-answered Dev questions
1. verify_all won't pass until F-1 resolved (project-overview.html:314 trips it). 2. zh fixture DOES produce `.harness/rules/00-core.md` (copy_layer:67). 3. Insert `test_zh_overlay` before the dispatch block (`test-init.sh:514`), called in all/both arm like `test_migrate` (`:526-528`), BEFORE the BUG-2 block (`:530-541`). 4. The 4 G.3 version sites (plugin.json:4, marketplace.json:17, README.md:5, README.zh-CN.md:5) are the only live 0.23.0 to touch. 5. No new verify_all Step → check count stays 32, skill count 13.

## Carries for Dev (once F-1 fixed)
1. F-1 first (exempt project-overview.html). 2. Lockstep: `全程~中文` into verify_all.{ps1,sh} AND both test-verify-i6 copies same change. 3. UTF-8 save + re-Read (L10); run BOTH shells for test-init/test-verify-i6/verify_all; empirical badge totals.
