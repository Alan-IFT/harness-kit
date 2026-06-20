# 03 — Gate Review · T-04 skill-authoring-vocab

> Stage 3 (Gate Reviewer). Mode: full. deferred-human: defer. Persisted by PM (gate-reviewer read-only).
> Upstream: 01 READY · 02 READY. Every load-bearing claim re-verified against the live tree, source glossary, and live I.6 banned list.

## Audit checklist (8 dimensions) — all PASS
1 Requirement completeness · 2 Design completeness · 3 Reuse correctness · 4 Risk coverage · 5 Migration safety · 6 Boundary handling · 7 Test feasibility · 8 Out-of-scope clarity — **PASS** each. No WARN, no FAIL.

## Independent verification
1. **Dogfood-only / no fan-out — CONFIRMED.** `Glob **/15-skill-authoring.md*` → exactly one hit (`.harness/rules/`), none under `templates/`. AI-GUIDE:75/106: rules referenced-not-composed, `sync-self` does NOT sync `.harness/rules/`. So no version bump / README / CHANGELOG / skill-count / plugin.json / harness-sync. Skill-count-decoy insight (2026-06-19) does not bind (no count claim touched).
2. **Additive-only / P1-P8 byte-stable — FEASIBLE.** Live file: P8 body ends line 62, blank 63, `## Deliberately not adopted` line 64. Insertion strictly between 62 and 64 + one sibling sentence joined to the provenance paragraph (lines 6-10). No P1-P8 body line is an edit target.
3. **≤200 cap (I.2) — REALISTIC.** Live 81 lines; +27 ≈ 108; ~92 headroom. `70-doc-size.md:25` confirms the cap.
4. **7 concepts faithful + correctly dispositioned + source credited — CONFIRMED** (cross-checked vs source GLOSSARY.md): leading word→P1 (generalization), no-op test→P2 (named handle), completion criterion *(new)*, premature completion *(new)*, sediment/sprawl→P5+cap, single source of truth→anti-bloat stance, user/model-invoked load lens *(new)*. The 3 genuinely-new are correctly NOT mapped to any P1-P8 (AC-4). Provenance sentence credits mattpocock/skills writing-great-skills while preserving the Anthropic line.
5. **No new check, no I.6 anchor — CONFIRMED.** Live banned list (verify_all.ps1:486-501) = 14 entries on scaffolding-only / CLAUDE.md composition·regeneration / 生成·合成 / 全程中文 — the designed wording contains none. Count stays 32 (no guard accreted; honors [[feedback_design_over_guards]]).
6. **Meets the rule's OWN bar** — terse named handles, no no-op restatements, one co-located block, single-source, 108≪200 (no sprawl). No self-contradiction.
7. **Insight-index** — no contradiction; the 2026-06-08 self-trip insight is honored by R-1 (wording avoids every literal anchor).

## Pre-answered developer questions
1. Insert between live line 62 and 64; reuse blank 63 as lead-in; add a trailing blank before `## Deliberately not adopted`. Touch lines 1-62 only for the provenance sentence.
2. Provenance: append ONE sentence to the paragraph ending "…mechanisms this repo already has." naming mattpocock/skills writing-great-skills / GLOSSARY.md; do NOT reword the Anthropic line/URL.
3. Rewording/wrap is free, but keep "CLAUDE.md", "composed", "regenerate", "生成/合成", "全程中文" OUT of the prose (I.6), and don't re-map a *(new)* concept onto a P-number.
4. No version/README/CHANGELOG/skill-count/harness-sync. `git diff --name-only` at delivery shows only `.harness/rules/15-skill-authoring.md` + this task's stage docs.
5. Done = verify_all green (no new I.2/I.6 WARN, 32 checks) + grep the 7 terms + cross-refs present + 3 new marked *(new)* + `git diff` shows P1-P8 byte-stable.

## Verdict
**APPROVED FOR DEVELOPMENT.** 0 FAIL / 0 WARN; all claims independently re-verified; the design clears the bar of the very rule it edits. No escalation needed.
