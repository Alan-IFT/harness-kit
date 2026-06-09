# Delivery Summary — T-016 i18n-special-drift-guard

- **Task:** resolve the T-015 R-2 accepted-duplication risk. The 3 SPECIAL i18n/zh files duplicated the
  English framework BODY from `templates/common/`, which could silently drift. **Per the user's steer —
  prefer eliminating the root cause via good design over accreting verify_all guards (guard-accretion =
  bloat)** — this ELIMINATES the duplication rather than guarding it.
- **Mode:** full (7-stage).
- **Stages traversed:** 1 Requirement (2026-06-09) → user steer (GUARD → ELIMINATE) → OQ-1 = ELIMINATE →
  2 Design (feasible) → 3 Gate (APPROVED, 0 blocking / 4 advisory) → 4 Developer → (PM ran the PS side: Dev
  sandbox blocked pwsh) → 5 Code Review (APPROVED, 1 minor) → 5b prose polish → 6 QA (PASS, 0 blocking; 1
  claim-accuracy minor) → 7 Delivery.
- **Rollbacks:** 0.
- **Final verify_all:** **PASS — 32/32, 0 WARN, 0 FAIL** (PM-run, PS; bash by Dev+QA). **Check count UNCHANGED
  at 32** — the anti-bloat win. version **0.27.0**, I.6 PASS.
- **Baseline changes:** **check count stays 32 (NO new check added)**; skill count stays 14; version **0.26.0 →
  0.27.0**; baseline test-init **274→275 (ps)** / **236→237 (sh)** from the one new composition-integrity assertion.

## What shipped

- **ELIMINATED the duplication at the root.** The 3 SPECIAL i18n/zh files (`00-core.md.tmpl`, `CLAUDE.md.tmpl`,
  `copilot-instructions.md.tmpl`) are DELETED. The English framework body now lives in exactly ONE place
  (`templates/common/`); there is no second copy to drift.
- **Single-source the zh policy:** new `skills/harness-init/templates/i18n/zh/_policy/output-language.zh.md.tmpl`
  holds ONLY the zh policy (section + line). The leading-`_policy/` dir is a sibling of `common/` under
  `i18n/zh/`, OUTSIDE every overlay-copy path → never laid into a generated project (pure template-source).
- **`/harness-language` re-pointed** (template helper + dogfood mirror via sync-self) to read the zh policy from
  the snippet; the en source stays `common/` inline (en path byte-unchanged). Extractor logic unchanged.
- **init COMPOSES** (SKILL.md step 4.4 + the adopt mirror): a zh project lays the English `common/` files, then
  runs `/harness-language zh` to inject the policy. "init zh = init en + /harness-language zh" — init and the
  command now share ONE tested mechanism.
- **test-init re-modelled** to COMPOSE (not overlay) + ONE new `[zh][T-016]` composition-integrity assertion
  (composed zh body == `common/` body). Existing T-015 inverse + 4 T-013 zh assertions retained, all green on
  the composed fixture.
- **Version 0.26.0→0.27.0** (4 G.3 sites) + CHANGELOG `[0.27.0]`. The `32 checks` / `verify__all-32%2F32` claims
  are UNCHANGED — the point of this task.

## Notes for the user

- **Why this is better than a guard:** the duplication is GONE, so silent drift is now **impossible by
  construction** — not "possible but caught." The verify_all check count stays 32 (no bloat). init and
  `/harness-language` are unified on one mechanism (less to maintain).
- **Claim-accuracy note (from QA):** the new `[zh][T-016]` test verifies **composition integrity** (the init
  injection doesn't corrupt the body), NOT "drift between two copies" — because after elimination there is only
  ONE copy, so a `common/` edit moves both sides of its comparison together (a real `common/` regression is
  still caught by the retained T-015 string assertion). This is the natural consequence of single-sourcing; the
  test is kept as a useful composition-integrity guard, framed accurately here (the Dev/Design "B-6 mutation
  proof" wording overstated it; the persistent record corrects it).

## Insight

- 2026-06-09 · After ELIMINATING a duplication by single-sourcing (one canonical copy + a derived/composed output), a "body-match" test that compares the COMPOSED output against its SINGLE SOURCE is a COMPOSITION-INTEGRITY check (does the transform corrupt the body?), NOT a drift-catcher — editing the single source moves BOTH sides of the comparison together, so it stays GREEN on a source edit. This is correct + desirable: single-sourcing makes drift impossible-by-construction, so there is nothing left to "catch." Don't describe such a test as "catches drift" (QA caught exactly this overstatement); a genuine regression in the single source is caught by an independent string/semantic assertion, not by comparing the source to a copy of itself. · evidence: T-016 QA, test-init `[zh][T-016]` assertion
- 2026-06-09 · Eliminating a necessary duplication can REUSE an existing runtime tool as the composition step instead of adding a guard: T-016 removed the i18n/zh body-duplication by having init run the T-014 `/harness-language` helper to inject the policy into the English `common/` files ("init zh = init en + /harness-language zh"), single-sourcing the policy into a non-overlaid `_policy/` snippet. Net: the verify_all check count stayed 32 (no new guard) while the root cause vanished — prefer this over accreting a drift-guard check. · evidence: T-016, SKILL.md step 4.4 + language-policy re-point
