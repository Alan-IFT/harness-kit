# Test Report — decision-mode-skill (T-018)

- QA: operator
- Verdict: **PASS**

## Evidence (captured runs, 2026-06-10)

- `bash .harness/scripts/verify_all.sh` → **32 PASS / 0 WARN / 0 FAIL** (~45s). Relevant checks:
  C.1 "All 15 skills present", G.1/G.2 "references all 15 skills", G.3 version stamps consistent
  (0.28.0), G.4 count/version claims, I.6 retired-claim, E.4b AI-GUIDE↔rules index — all PASS.
- `bash .harness/scripts/test-init.sh` → **249 PASS / 0 FAIL**; equals `baseline.json`
  `test_init_bash_no_python3_assertions = 249`. Includes the 2 new assertions (shipped
  `25-decision-policy.md` present + defaults to `Active mode: 1`).
- **Fan-out audit (grep):** README / README.zh-CN / AI-GUIDE / getting-started / manual-e2e all
  state 15 / fifteen; zero stale "fourteen"; the new skill is in both README skill lists and the
  AI-GUIDE workflow-entry table.

## Operator could NOT run (flagged honestly — insight L23/L27, no fabrication)

- `verify_all.ps1` / `test-init.ps1`: **PowerShell is deny-blocked in this environment → NOT run.**
  They are symmetric edits to the verified `.sh` side (same skill-array additions, same 14→15
  labels). `baseline.json` records `test_init_ps_assertions = 287`; **this PS tally was not
  operator-verified** — confirm on a Windows shell before relying on it. (Not gate-enforced:
  `verify_all` does not execute `test-init`, so a wrong PS count would not FAIL the gate.)

## Adversarial / regression notes

- Skill description triggers reviewed for over-broad matching — the "NOT for /harness-language,
  NOT for /harness-upgrade, NOT for editing rubric content" deltas disambiguate the siblings.
- The shipped Active mode defaulting to 1 means zero behavior change for existing generated
  projects on upgrade (additive/backwards-compatible).

PASS → Delivery.
