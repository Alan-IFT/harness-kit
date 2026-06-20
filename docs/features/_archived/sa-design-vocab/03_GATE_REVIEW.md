# 03 — Gate Review · T-07 sa-design-vocab

> Stage 3 (Gate Reviewer). Mode: full (final task). deferred-human: defer. Persisted by PM (gate-reviewer read-only).
> Upstream: 01 READY · 02 READY. Verify-don't-trust against the live tree (agent file, source SKILL, rule 15, insight-index, verify_all G.3/G.4/I.3/I.6 bodies).

## Audit checklist (8 dimensions) — all PASS. No WARN, no FAIL.

## Verification evidence
- **Insertion additive:** solution-architect.md = 122 content lines; last section `## What "bad" looks like` ends :122; 12-section output contract at :14-29. New `##` section appended after :122 — lines 1-122 byte-unchanged. Real.
- **Optional-lens (anti-railroad, key risk):** 3 affordance signals — heading `## Design vocabulary (optional lens)`; lead "A lens you **may** reach for … leading words to think *with*, not a checklist and not a required `02_SOLUTION_DESIGN.md` field"; flow note "a design that never mentions a single term is still complete/conformant". Framed as T-04 "leading words" (rule 15 P4 anti-railroad confirmed at 15-skill-authoring.md). Zero mandate.
- **7 terms + 3 principles source-faithful** (vs codebase-design/SKILL.md): module (scale-agnostic); **interface = everything a caller must know, NOT just the type signature**; **depth = leverage per unit of interface, line-ratio reading explicitly rejected** (the key fidelity point — correct); seam (where interface lives); adapter (concrete thing at a seam); leverage (caller payoff); locality (maintainer payoff); deletion test; "interface is the test surface"; "one adapter = hypothetical seam, two = real".
- **design-it-twice EXCLUDED / DEEPENING pointer-only:** one combined deferred line, names only, no procedure.
- **Version 0.37.0→0.38.0:** live pre-state 0.37.0 on all 4 G.3 surfaces (plugin.json:4, marketplace.json:17, README.md:5, README.zh-CN.md:5). G.3 (verify_all.sh:350-372) requires all 4 match; G.4 (700-786) requires a `[0.38.0]` CHANGELOG heading matching plugin.json. Bump is necessary+sufficient.
- **No count token / no new check:** G.4 derives count = live `${#report[@]}+1` = 32; no check added → all 11 count claims stay valid untouched. README edit = version token only (32/308/90 badges intact). CHANGELOG restates 16/8/32 unchanged. tasks.md:14 + STREAM_LOG:29 version-token matches are frozen T-06 delivery rows (not G.3/G.4 surfaces; T-03 decoy discipline).
- **I.3:** ~145 projected ≤300 (WARN-only cap). **I.6:** 14 banned anchors (verify_all.sh:521-536, CLAUDE.md-gen + zh-policy) don't overlap the vocabulary; agents/ scanned but clean; no forward `name.ext:NNN` in prose (HR6); CHANGELOG I.6-exempt.
- **Plugin-native direct edit:** no `solution-architect.md.tmpl` (no template copy), no `.harness/agents/dev-*.md` (single-Developer mode), no sync. Insight-index: no contradiction (2026-06-05 + 2026-06-19 actively support).

## Findings
None. 0 WARN, 0 FAIL.

## Pre-answered developer questions
1. Append one blank line after line 122, then the section; preserve single trailing newline; `git diff` shows insertions only.
2. The §3 block is wrapped in a FOUR-backtick `````markdown` display fence — paste only the INNER content (the `## Design vocabulary (optional lens)` section), NOT the outer fence. Inner content has no triple-backticks.
3. No 33rd check, no test-verify-i6 touch; I.6 4-file lockstep NOT triggered (no banned/exempt entry added); g4_count stays 32.
4. README edit = `version-0.37.0-blue`→`version-0.38.0-blue` token ONLY (line 5); leave 32/308/90 badges.
5. Green bar: verify_all 32/32 (G.3 0.38.0 ×4; G.4 [0.38.0] + counts 32; I.3 ~145; I.6 clean). PS half operator-pending.

## Verdict
**APPROVED FOR DEVELOPMENT.** All 8 dimensions PASS, 0 WARN/FAIL. Exact verbatim section, real additive insertion, 3 anti-railroad affordance signals + zero mandate, source-faithful definitions (interface/depth fidelity verified), design-it-twice excluded, 0.37.0→0.38.0 across 4 stamps + [0.38.0], no count token touched, no new check, no I.6 list change, direct plugin-native edit, ~145 ≤300. No route-back.
