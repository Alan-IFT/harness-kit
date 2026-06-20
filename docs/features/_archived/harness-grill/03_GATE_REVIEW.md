# 03 — Gate Review · T-03 harness-grill

> Stage 3 (Gate Reviewer). Mode: **full**. deferred-human: defer, do not ask. Persisted by PM (gate-reviewer is read-only).
> Upstream: 01 READY; 02 READY for Gate. Every claim verified against the LIVE repo (Glob/Grep/Read), not trusted from upstream.

## 0. Independently verified (live repo)

- **Live skill count = 15** (`Glob skills/*/SKILL.md` → 15 dirs; no `harness-grill` yet → Family A is genuinely new). `15 → 16` correct.
- **verify_all C.1/G.1/G.2 are HARDCODED NAME ARRAYS in BOTH shells** — `verify_all.sh:56/329/345`, `verify_all.ps1:69/301/327` (`@("harness",…,"harness-decision-mode")`). NOT directory-derived. SA's correction of RA item 26 is CORRECT + load-bearing: `harness-grill` MUST be appended to all six arrays AND all six labels flipped 15→16. Label-only (RA's hypothesis) would leave enforcement at 15.
- **install.{ps1,sh} BOTH directory-derived** (`install.sh:82-85`, `install.ps1:79-81`) → no per-skill array edit. Only the trailing "Use in Claude Code:" help block hardcodes a per-skill listing (soft/ungated).
- **Version stamps:** plugin.json:4 + marketplace.json:17 + both README badges :5 = `0.34.0` (4 G.3 targets). plugin.json `"skills":"./skills/"` (auto-discovery).
- **G.4 derives check count dynamically** (`${#report[@]}+1`) → stays **32** automatically (no new check); bumping to 0.35.0 makes G.4 DEMAND a `[0.35.0]` CHANGELOG heading. G.4 also pins 11 `(N checks)`-class tokens to 32 (the `32` decoys). 40-locations G.4 pin is `:26` `(32 checks)`, a DIFFERENT line from the skill-count edit at `:31` — no collision.
- **Decoys confirmed frozen:** CHANGELOG.md:74 ("the 15 skills" in v0.30.1 historical entry); harness-status:135 ("14 required assets" = health denominator, not a skill count); all 32/308/90 tokens; baseline.json `skill_count_baseline:4` (stale history).
- **Strip-list line sites exact:** Hard-rule-1 `agents/requirement-analyst.md:28`; section 8 `:23`.
- **Independent fan-out sweep** (grep `harness-decision-mode`, the 15th skill, as proxy) → 18 files, all in the SA ledger or legitimate non-enumerations. Ledger COMPLETE.

## 1. Audit checklist (8 dimensions) — all PASS

| # | Dimension | Verdict |
|---|---|---|
| 1 | Requirement completeness | PASS (28 items + 12 ACs testable; operator-run items marked) |
| 2 | Design completeness | PASS (every behavior maps to a SKILL section / agent edit / ledger row) |
| 3 | Reuse correctness | PASS (grilling ref, sibling skill shapes, T-02 CONTEXT, T-018 ledger, both installers all verified) |
| 4 | Risk coverage | PASS (R1-R9; the two non-obvious — name-array, install help drift — both caught) |
| 5 | Migration safety | PASS (purely additive; git reset rollback) |
| 6 | Boundary handling | PASS (BC-1…BC-8 each have a design response) |
| 7 | Test feasibility | PASS (AC verifiable; operator-run items correctly gated) |
| 8 | Out-of-scope clarity | PASS (O-1…O-8; "emit brief and STOP" + no Task tool makes over-build structurally hard) |

## 2. Findings (all WARN — developer-side conditions, no rollback)

- **F-1 (WARN, decoy completeness):** two frozen historical `15` surfaces the SA didn't name as decoys — `.harness/insight-index.md:35` ("the 15 skills already work") and `docs/proposals/plugin-native-redesign.html:65,136` ("15 个 skill"). Both frozen historical artifacts; MUST stay 15. Add to DO-NOT-TOUCH so the AC-9 residual-`15` sweep doesn't false-positive.
- **F-2 (WARN, README caption):** `README.md:15` captions the Pipeline group "(six task shapes…)" with exactly 6 bullets (:16-21). Placing grill as a 7th bullet makes "six" stale AND grill is conceptually pre-pipeline, not one of the six shapes. Dev must reconcile the caption (e.g. keep "six shapes" + add grill under a "(plus a pre-pipeline aligner)" qualifier). getting-started.md:38 has no hardcoded "six" — cleaner.
- **F-3 (WARN, verbatim match):** SA §4 Edit 2 paraphrases the section-8 base text; the LIVE `:23` reads "numbered, with at least 2 candidate answers each." Dev must Edit against the verbatim live string or the match fails.

## 3. Pre-answered developer questions

1. Do NOT touch the template `templates/common/AI-GUIDE.md.tmpl` Workflow table (curated 6-mode subset, no count claim; T-018 didn't touch it). Only the DOGFOOD AI-GUIDE.md Workflow table gets the new row.
2. Add `harness-grill` to the array in ALL six places (3/shell) AND flip all six labels 15→16. F.1 FAILs on one-shell-only.
3. Check count stays 32 (modifying existing checks ≠ adding one). Don't touch any 32/308/90 token or baseline.json.
4. No `.claude/skills/` copy, no harness-sync (plugin skills bind from top-level `skills/`; C.2 auto-scans `skills/**/SKILL.md` — ensure frontmatter `name:`+`description:`).
5. New `## [0.35.0]` above `## [0.34.0] - 2026-06-19`; must contain literal `harness-grill` ≥1× (G.2) + `[0.35.0]` heading (G.4). "recommend" is NOT an I.6 banned anchor (verified) — agent-rule + CHANGELOG prose are I.6-safe.

## 4. Verdict

**APPROVED FOR DEVELOPMENT.**

Conditions carried into development:
- **C1 (F-1):** treat `insight-index.md:35` + `proposals/plugin-native-redesign.html:65,136` as DO-NOT-TOUCH `15` decoys.
- **C2 (F-2):** reconcile the README "(six task shapes)" caption when adding the grill bullet.
- **C3 (F-3):** apply the recommended-answer rule against the verbatim live `:23` string.
- **C4:** run verify_all both shells at hand-off → 32/0/0 symmetric (operator-run for PS; do not invent a PASS count).
