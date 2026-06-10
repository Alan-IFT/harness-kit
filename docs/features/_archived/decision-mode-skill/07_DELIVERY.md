# Delivery — decision-mode-skill (T-018)

- Date: 2026-06-10
- Status: **DELIVERED**
- Final verify_all result: PASS (32/0/0)

## What shipped (v0.28.0)

A 15th skill `/harness-decision-mode` — an interactive Mode 1/2/3 switcher — plus **Mode 3
(user-custom rubric)** added to the decision/escalation policy, with the whole policy mechanism
(generic defaults, `Active mode: 1`) distributed to every project `/harness-init` scaffolds.
The dogfood repo keeps its seeded personal Preset and stays on Mode 2.

## Verification

`verify_all.sh` 32/0/0 (~45s); `test-init.sh` 249/0 (matches baseline). Fan-out audited green
incl. the ungated `getting-started` / `manual-e2e` surfaces. PowerShell twins are symmetric but
operator-unrun (deny rule) — `test_init_ps_assertions=287` unverified here (see 06).

## Surfaced for operator review-after (per RA, deferred deliberately)

- **OQ-1 — pre-existing install-array gap (a real latent bug, NOT introduced here):** `install.ps1`
  / `install.sh` list only **13 of 15** skills — `harness-upgrade` and `harness-language` (added in
  v0.23 / v0.25) were never added to the install arrays. This release added only the new
  `harness-decision-mode` (scope discipline — the RA flagged the wider gap for a user ruling rather
  than expand T-018's scope). **`verify_all` does NOT gate the install array**, so the gap is
  invisible to the gate. Effect: a `curl | sh` / install-script install omits those two skills.
  Worth a small follow-up fix (add the two names to both arrays) — operator's call.
- **OQ-2 — zh policy template deferred:** the shipped policy + rubric are English-only under
  `templates/common/`, consistent with the v0.26 consumer-split anglicization (AI-facing scaffolding
  is English). No Chinese template copy was added. This is correct/consistent, not a gap.

## Insight

No new evidence-backed insight to harvest — T-018 reconfirms the skill-add fan-out-completeness
discipline already captured in insight-index (L5 / L24): the Gate's independent live-tree re-grep
caught the `getting-started.md` "fourteen" omission the SA's ledger missed (round-1 F-1), exactly
the recurring class. Index left at 30 lines per the operator's context-budget preference.
