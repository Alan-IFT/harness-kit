# 05 — Code Review · T-013 / lang-policy-split

> Stage 5. Code Reviewer (read-only). Persisted by PM. Reviewed against 02 + Amendment 1, 01 ACs, 03 gate findings.

## Verdict: APPROVED

0 BLOCKING · 0 MAJOR · 2 MINOR · 1 NIT. Faithful to design + Amendment 1; every AC met; F-1 (exemption)
+ F-2/F-3/F-4 advisories all discharged; CJK + the 4-file I.6 lockstep byte-correct.

## Findings
### MINOR (→ developer, non-blocking)
- **[MAINT] `test-verify-i6.ps1:51` + `test-verify-i6.sh:64`** — banned-array header comments still say
  "The 13-entry banned list" while the array holds 14 and the count constant is correctly 14. Stale
  comment only (the constant, not the comment, gates the assertion). 2-char fix.

### NIT
- **[STYLE] `README.md:5` / `README.zh-CN.md:5`** — `test--init-255%2F255` badge encodes the PS total on
  both sides while true Bash total is 217 (prose at line 162 states both correctly). Pre-existing badge
  convention (prior `227/227` did the same); informational, not G-gated. Awareness only.

## Focus-area verification (all PASS)
- **CJK round-trip/encoding — PASS.** `全程~中文` anchor byte-correct + identical across all 4 files
  (verify_all.ps1:501/.sh:536, test-verify-i6.ps1:66/.sh:79; same reason string). Exempt
  `docs/project-overview.html` element-wise identical across all 4 exempt arrays (index 3, after
  walkthrough.html; PS trailing-comma vs bash no-comma per Amendment-1). No mojibake/BOM.
- **I.6 self-trip — PASS.** F1 policy (`00-core.md.tmpl:9-31`) has NO `全程` (heading "按消费者分流");
  banned-line needs 全程+中文 ordered ≤40 chars on one line → cannot self-trip, still catches old variants.
- **Tree-wide `全程` sweep — PASS exhaustive.** project-overview.html:314 now exempt in all 4 arrays (not
  rewritten — frozen-snapshot decision honored); walkthrough.html:284 non-hit + exempt; scripts auto-exempt;
  test-init carries bare `全程` alone (non-hit); SKILL.md:72 + README.zh-CN.md:143 old lines GONE. No new non-exempt hit.
- **I.6 lockstep count — PASS.** Exactly 14 entries in all 4 banned arrays; `I6ExpectedEntryCount`=14 in
  both drivers (test-verify-i6.ps1:84/.sh:99). Internally consistent — no fabricated tally.
- **Policy fidelity (AC-2) — PASS.** F1's two lists match §4 (ZH=chat/errors/status/human-delivery/human docs;
  EN=stage docs/PM_LOG/ledgers/agent-rule-AIGUIDE-CLAUDE/comments/commits); DUAL→EN tie-break stated (line 27).
  CLAUDE.md.tmpl:3 + copilot:6 byte-identical one-liners (AC-1/AC-3).
- **No surviving blunt claim (AC-4/5) — PASS.** No 全程中文/every AI output/AI 全程/全程使用中文 in any live non-exempt site.
- **EN path byte-unchanged (AC-7) — PASS.** common/00-core.md.tmpl + common/CLAUDE.md.tmpl untouched.
- **No new placeholder — PASS.** Only the pre-existing 4 header placeholders; policy block has zero; `<task>` uses angle brackets.
- **test-init zh assertion (AC-9) — PASS.** Test-ZhOverlay(ps:610)/test_zh_overlay(sh:514): 4 pure-grep asserts
  (exists + ZH marker 给用户的交付总结 present + EN marker "commit message" present + 全程 absent), present/absent on
  DIFFERENT strings (no T-007 trap), no python3, symmetric, before BUG-2 block, inspects real overlaid zh 00-core.md. +4 reconciles.
- **CHANGELOG (F-4) — PASS.** [Unreleased]→[0.24.0] - 2026-06-08; ambient T-011 bullets kept; T-013 prepended; no orphan/sibling.
- **Version fan-out (AC-10) — PASS.** 0.24.0 at plugin.json:4, marketplace.json:17, both badges:5; verify_all 32, skill 13.

## Residual risk profile for QA (verify by RUNNING)
Single most important: run `verify_all` + `test-verify-i6` + `test-init` in BOTH PowerShell and Bash (MSYS, no
python3) on a real box; confirm the CJK `全程~中文` banned-line behaves correctly cross-shell:
1. verify_all I.6 PASS both shells (must NOT trip on exempt project-overview.html; must NOT self-trip on new split text — only provable by a real grep/regex run).
2. test-verify-i6 PASS both shells (14-entry + 4-element exempt lockstep across the 4 arrays).
3. test-init PASS both shells; confirm empirical totals (PS 255 / Bash 217); confirm CJK assert literals round-trip
   through copy_layer substitution into the generated fixture (zh-overlay asserts FAIL loudly, not silently, on encoding mangle).
   Dev noted a transient mid-edit MSYS parse-error false alarm — trust only a fresh full run.

Routing: none required (APPROVED). The 2 MINOR stale comments are optional polish; do not block merge/QA.
