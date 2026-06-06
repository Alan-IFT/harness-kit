# Task Input — g4-version-decouple (T-010)

## Origin
Flagged in T-009's 07_DELIVERY §Outstanding-1 as a design reflection; user approved running it ("继续").

## Problem — the count-claim version treadmill
T-008's G.4 meta-check anchors every "N checks at vX" prose count claim's VERSION token to the current `plugin.json` version. So every release — INCLUDING a patch that does NOT change the check count — must bump the version token in 6 prose claims in lockstep, or G.4 FAILs. G.4 names any miss (so it's guided, not error-prone), but it is per-release churn and an avoidable duplication.

DRY analysis: the VERSION has a single source of truth (`plugin.json`, with G.3 validating the plugin/marketplace/README badges). The prose count claims **duplicate** that version ("at vX") on top of the count — that duplication is the churn. The COUNT genuinely needs to live in prose (gated by G.4 against the live tally); the VERSION does not.

## The 6 version-bearing count claims (live, all "32 ... at v0.21.1")
1. `AI-GUIDE.md:36` — "...all PASS checks are green (32/32 at v0.21.1; check count grows with releases)..."
2. `AI-GUIDE.md:69` — "total verification (32 checks at v0.21.1, including ...)"
3. `docs/dev-map.md:60` — "Total verification (32 checks at v0.21.1)"
4. `docs/dev-map.md:133` — "runs all 32 checks (at v0.21.1) ..."
5. `.harness/rules/40-locations.md:25` — "verify_all checks (32 checks at v0.21.1, all must PASS — count grows with releases):"
6. `docs/manual-e2e-test.md:3` — "... `verify_all` at 32 checks at v0.21.1; ..." (NOTE: the SAME line lists test-init 251/213, test-supervisor 49/45, test-verify-i6 56/56 — all version-LESS; only verify_all carries a version → internally inconsistent.)

All 6 read as **living current-state** statements (e.g. #1 literally says "check count grows with releases"), not deliberate "validated-at-vX" snapshots. So dropping the version token suits all six (RA/SA to confirm none is genuinely a snapshot stamp).

## Goal (one line)
Decouple the prose count claims from the version: G.4 validates the COUNT (against the live tally) only — drop the version-token coupling for these claims — so a count-unchanged release stops touching them. Keep version consistency where it belongs: G.3 (plugin/marketplace/README badges) + G.4's CHANGELOG `[version]`-heading presence check (both legitimately bump every release).

## Design crux for SA (NOT pre-decided)
1. **Per-claim disposition:** confirm all 6 are living-current-state (drop "at vX") vs any genuine snapshot that should keep+bump a version. (Prior read: all 6 are living.)
2. **G.4 simplification (both shells):** change the count-claim validation from "count + version" to "count only"; KEEP the CHANGELOG `[version]`-heading check (validates against plugin.json — legitimate). Ensure G.4 still catches a wrong COUNT (the T-008 load-bearing property must survive).
3. **Completeness/exhaustiveness:** find EVERY "N checks at vX" / "N/N at vX" version-bearing count claim (same exhaustive-sweep discipline that took T-008 two rollbacks) so none is left with a stale, now-unchecked version token. After this change G.4 won't catch a leftover version token in a count claim — so the removal must be complete.
4. **Does this weaken drift protection?** After decoupling, is any version-consistency coverage LOST that matters? (Stamps still G.3-gated; CHANGELOG entry still G.4-gated; only the prose count-claim version annotation goes ungated — because it no longer exists.) Confirm the net is strictly-better, not a regression.

## Acceptance criteria (refine in stage 1)
- AC-1: The 6 prose count claims state the count WITHOUT a version token (or, for any the SA rules a true snapshot, keep+document why).
- AC-2: G.4 (both shells) validates the count claims for COUNT-against-live-tally only; the CHANGELOG `[version]` check is retained; G.4 still FAILs on a wrong count (T-008 property preserved) — proven by QA mutation.
- AC-3: A simulated count-unchanged version bump (plugin.json patch in a temp fixture) makes G.4 pass WITHOUT editing any prose count claim (the treadmill is gone) — while G.3 still requires the stamps to bump.
- AC-4: Exhaustive: no live prose count claim retains a version token; verified by grep.
- AC-5: verify_all 32/32 PASS BOTH shells, 0 WARN, 0 FAIL. No new check (count stays 32). PS/Bash symmetry (L13).

## Out of scope
- The G.3 stamp-version checks (plugin/marketplace/README badges legitimately bump per release — unchanged).
- The CHANGELOG `[version]` heading check (unchanged).
- Changing the check count or adding a check.
- The historical/snapshot files (CHANGELOG history, dated HTMLs, `_archived/**`, tasks.md delivery records) — never touched.
