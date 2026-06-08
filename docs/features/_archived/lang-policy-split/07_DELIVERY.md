# Delivery Summary — T-013 lang-policy-split

- **Task:** Refine harness-kit's v0.7.0 project-level output-language feature. For a `{{LANG}}=zh`
  generated project, replace the blunt "全程中文 / everything in Chinese" policy with a THREE-WAY
  split: conversational replies → Chinese; AI-facing output → English; human-facing output → Chinese.
- **Mode:** full (7-stage).
- **Stages traversed:** 1 Requirement (2026-06-08) → OQ resolution (user-delegated, all 6 RA defaults) →
  2 Design → 3 Gate (**CHANGES REQUIRED** — F-1 missed I.6 site) → 3b Architect amendment (exempt the
  archived snapshot) → 4 Developer → 5 Code Review (APPROVED, 2 MINOR) → 5b comment polish → 6 QA
  (PASS, 11/11 adversarial) → 7 Delivery.
- **Rollbacks:** 1 (Gate→Architect: F-1, the I.6 retired-phrase sweep missed `docs/project-overview.html:314`;
  fixed by exemption, not rewrite — it's a frozen v0.17.0 snapshot).
- **Final verify_all:** **PASS — 32/32, 0 WARN, 0 FAIL** (PM-run on delivery; reproduced 32/32 BOTH shells
  by Dev + QA). G.3=0.24.0, G.4 ok, I.6 PASS, skill 13, checks 32.
- **Baseline changes:** check count stays 32; skill count stays 13; version **0.23.0 → 0.24.0**;
  baseline.json bumped (test_init 251→255 PS / 213→217 bash; test_verify_i6 56→58; +1 I.6 banned entry,
  13→14). New first-ever test-init zh language assertion.

## What shipped (18 files)

- **Policy rewrite:** zh `00-core.md.tmpl` "输出语言（按消费者分流）" — two explicit ZH/EN consumer lists +
  DUAL→EN tie-break; `CLAUDE.md.tmpl` + `copilot-instructions.md.tmpl` symmetric one-line summaries;
  SKILL.md Q5 + step-4.3 stale-overlay-list fix; README.md + README.zh-CN.md policy sections;
  manual-e2e-test Q5. No surviving "全程中文 / every AI output in Chinese". Zero new `{{...}}`.
- **I.6 guard (4-file lockstep):** new `全程~中文` banned-line + `docs/project-overview.html` exemption,
  mirrored across `verify_all.{ps1,sh}` AND `test-verify-i6.{ps1,sh}`; `I6ExpectedEntryCount` 13→14.
- **First test-init zh assertion:** `Test-ZhOverlay`/`test_zh_overlay` (symmetric, pure-grep, no-python3,
  present/absent on different strings).
- **Version + CHANGELOG:** 0.24.0 across plugin.json/marketplace.json/2 README badges; `[Unreleased]`
  renamed to `[0.24.0] - 2026-06-08` absorbing the already-shipped ambient-stream (T-011) bullets + the
  T-013 entry (no orphan/sibling).

## Scope discipline / out-of-scope

- The (A)/(B) distinction held: this iteration changed the runtime-OUTPUT-language policy (A) only. The
  zh overlay's AI-facing *template* files (AI-GUIDE.md.tmpl, rule fragments, etc.) stay Chinese this
  iteration — re-translating them to English to fully match "AI-facing → English" is a **logged follow-up**
  (T-014 candidate: "prune/anglicize AI-facing files in the zh overlay so shipped scaffolding matches the policy").
- EN path (`{{LANG}}=en`) byte-unchanged (AC-7). harness-kit's own dogfood repo untouched (its CLAUDE.md stays English).
- Already-generated user projects are not migrated (a `/harness-upgrade` content-refresh concern, separate).

## Outstanding notes for the user

- Pre-existing, out-of-scope: the `test--init-NNN/NNN` README badge encodes the PS total on both sides
  (Bash is 217); badge convention, prose at README:162 is correct. Not fixed here.
- The T-014 follow-up above is the natural next step if you want the generated zh project's AI-facing
  *scaffolding* (not just its output policy) to also be English.

## Insight

- 2026-06-08 · The verify_all I.6 guard is a FOUR-file lockstep, not two: the banned-phrase list AND the exempt-files list are each mirrored in `verify_all.{ps1,sh}` AND `test-verify-i6.{ps1,sh}`, and `test-verify-i6` holds a hard `I6ExpectedEntryCount` that MUST bump with every banned-list add/remove (and asserts the exempt arrays element-wise). So adding one I.6 banned or exempt entry = 4 array edits + 1 count bump in 2 drivers; editing only the two verify_all arrays passes verify_all but FAILs test-verify-i6. · evidence: T-013, Gate F-1 + architect Amendment 1
- 2026-06-08 · A CJK substring CAN be a verify_all I.6 banned-anchor safely cross-shell: I.6 uses `grep -E -i` (NOT the MSYS-aborting `grep -F -i`) on bash + `[regex]::new(...,IgnoreCase)` over UTF-16 on PS, and CJK ordered-anchor entries already shipped green pre-T-013 (生成/合成/重新生成的). A new `全程~中文`-style entry just follows that pattern — but the on-disk file must be saved UTF-8 and the new policy text must avoid the banned anchor sequence so the guard doesn't self-trip. · evidence: T-013, verify_all I.6 + QA cross-shell mutation probe
