# Task Input — test-supervisor-stamps (T-008)

## Origin
Surfaced during T-007 (scripts-relocation) and deferred as a clean separate task per "don't bundle unrelated changes." The user approved running it now ("继续").

## Problem
`.harness/scripts/test-supervisor.{ps1,sh}` contains a block of "Doc fan-out spot checks" (PS lines ~419-444; the `.sh` peer mirrors them) that **hardcode the version literal `v0.17.1` and check-count `30`**:
- `30/30 at v0.17.1`, `30 checks at v0.17.1` (AI-GUIDE.md, dev-map.md)
- `[0.17.1]` CHANGELOG entry, `version-0.17.1-` README + README.zh-CN badges
- `plugin.json` / `marketplace.json` version `0.17.1`

These were a correct snapshot when the supervisor shipped at v0.17.1 (T-003), but were never bumped across v0.18.0/.1/.2, v0.19.0, v0.20.0. They have been **silently RED since ~v0.17→v0.18**, undiscovered because `test-supervisor` is NOT wired into `verify_all` (the 31-check gate), so nothing surfaced the drift.

## Why a band-aid is wrong (decision principle: long-term maintainability)
Simply bumping the literals `0.17.1 → 0.20.0` re-creates the exact drift trap: they'll go stale again at v0.21.0. The fix must remove the *drift class*, not the current symptom.

## Goal (one line)
Make `test-supervisor`'s version/count assertions non-drifting (derive expected values from the single source of truth, or remove them as misplaced), and prevent silent recurrence — so the supervisor regression is green and STAYS green across future version bumps without manual literal edits.

## Design tension for SA to resolve (NOT pre-decided)
1. **Are these checks even in the right place?** They assert *project version-stamp consistency*, which is `verify_all` G.3's job (plugin/marketplace/README), not the *supervisor agent's* behavior. Candidate approaches:
   - (A) **Remove** the version/count fan-out asserts from test-supervisor (keep only supervisor-specific structural asserts: the `auxiliary supervisor` phrasing, the canonical-7 glob). Rely on G.3 for version consistency; address the count-claim coverage separately.
   - (B) **Derive** the expected version from `.claude-plugin/plugin.json` at runtime so the asserts self-heal (never a literal to bump).
   - (C) Combination: remove the version-stamp asserts that duplicate G.3; convert the count-claim asserts (AI-GUIDE/dev-map "N checks at vX") to derive N + version from source of truth.
2. **Should `test-supervisor` be wired into `verify_all`** so it can never silently drift again? Trade-off: gate coverage vs. gate latency / coupling. Alternative: a lightweight verify_all meta-check that test-supervisor's expected stamps match plugin.json, without running the whole supervisor suite. SA recommends; Gate vets.
3. The "N checks" count claim (currently 31) has its OWN drift history (insight L14: count claims need manual sync). If a derive-from-source approach is chosen, where is the count's source of truth? (verify_all emits the count at runtime — is that derivable in a test?)

## Acceptance criteria (refine in stage 1)
- AC-1: `test-supervisor.ps1` AND `.sh` run fully green (0 FAIL) at the current version, with PS/Bash symmetry (insight L13/L20).
- AC-2: No hardcoded version literal (`0.17.1`, `0.20.0`, or any specific `vX.Y.Z`) remains in test-supervisor's fan-out asserts where the value should track releases — verified by grep.
- AC-3: A future version bump (simulate by bumping plugin.json in a temp fixture, or by reasoning) does NOT require editing test-supervisor, and would NOT leave it silently red.
- AC-4: `verify_all` stays 31/31 PASS both shells (or +N if a new meta-check is added — justified).
- AC-5: Recurrence prevention is in place per the SA's chosen mechanism (wired into verify_all OR a derive-from-source design that structurally can't drift).

## Out of scope
- The relocation work (done in T-007).
- Redesigning the supervisor agent itself or its non-version assertions.
- Broad refactor of verify_all beyond what AC-5 needs.
