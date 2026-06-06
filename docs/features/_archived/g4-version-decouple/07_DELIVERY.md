# Delivery Summary — g4-version-decouple (T-010)

- **Task:** Decouple the prose verify_all count claims from the version — G.4 validates them COUNT-only (against the live tally) — so a count-unchanged release no longer has to bump a version token in 6 docs (the "treadmill" T-009 flagged). Version consistency stays gated where it has a single source of truth: G.3 (plugin/marketplace/README badges) + G.4's CHANGELOG `[version]`-entry check.
- **Mode:** full (7-stage)
- **Version:** v0.21.1 → **v0.21.2** (patch — internal G.4 refactor; check count UNCHANGED at 32)
- **Stages:** RA (01, no bounce) → SA (02) → Gate (03, APPROVED no conditions) → Dev (04) → CR (05, APPROVED) → QA (06, **FAIL → D-1**) → Dev rework → CR re-review (APPROVED) → QA re-verify (PASS) → Delivery + v0.21.2 ship.
- **Rollbacks:** 1 (stage 4). **QA caught a MAJOR defect (D-1) that BOTH the Gate Reviewer and Code Reviewer missed** — the value of adversarial mutation testing. See Insight.
- **Final verify_all:** PS **32/32 PASS** (0 WARN, 0 FAIL), G.3 + G.4 PASS. Bash G.3 (0.21.2) + G.4 PASS via verbatim-block probe (full `verify_all.sh` wedges on the pre-existing I.6 MSYS fork-storm — see Outstanding §1).
- **What shipped:**
  - The 6 prose count claims (AI-GUIDE:36,:69; dev-map:60,:133; 40-locations:25; manual-e2e:3) de-versioned — they state the count without an "at vX" token.
  - G.4 (both shells) validates those 6 rows COUNT-only (the count stays in the expect literal, so a count drift still FAILs — the T-008 property is preserved); rows 6-11 + the CHANGELOG `[version]` check + the `$version` derivation + the tripwire are unchanged.
  - The v0.21.2 ship bump self-demonstrated the win: it touched only 5 files (plugin/marketplace/README×2/CHANGELOG) and did NOT touch any of the 6 prose claims.
- **D-1 (the caught defect):** de-versioning collapsed two same-file claims into a substring relationship — row 3's `expect="32 checks"` (dev-map:60) is a substring of row 4's `runs all 32 checks` (dev-map:133), and G.4 matches whole-FILE, so a dev-map:60-only count drift was silently masked by line 133. Fixed: row 3 now keys on `(32 checks)`, unique to L60. A systematic same-file-uniqueness audit of all 11 G.4 rows confirmed no other collision.
- **Files changed:** `verify_all.{ps1,sh}` (G.4 count-only rows 1-5+10 + row-3 D-1 fix + comment), 6 prose claim files (de-version), `plugin.json` + `marketplace.json` + `README.md` + `README.zh-CN.md` + `CHANGELOG.md` (v0.21.2).

## Outstanding (pre-existing, surfaced during T-010 — NOT introduced here)

1. **`verify_all.sh` wedges on the I.6 `git ls-files × grep` MSYS fork-storm (exit 124) on this Windows host.** I.6 spawns ~3354 grep processes; under Git-for-Windows MSYS the full bash run intermittently hangs after I.7 (3 of 4 runs). PowerShell `verify_all.ps1` is unaffected (the authoritative gate here); bash G.4/G.3 were verified via a verbatim-block probe. This makes `verify_all.sh` unreliable for full-suite CI on Windows. Recommended follow-up: optimize I.6's bash matcher (batch the grep, or gate the fork-count) so `verify_all.sh` completes reliably. Out of T-010 scope.

## Insight

- 2026-06-06 · When a verify_all-style gate validates multiple claims against the WHOLE file via a substring `.Contains`/`== *..*` test, every claim that shares a file must have an `expect` literal that is UNIQUE within that file — otherwise one claim's expected string is satisfied by another claim's text and a drift in the first claim is silently masked. T-010 de-versioning collapsed two dev-map.md claims (`32 checks` ⊂ `runs all 32 checks`) into exactly this trap; the Gate Reviewer and Code Reviewer both reasoned "the count is in the expect → drift caught" and MISSED it, but QA's per-claim mutation testing caught it (set L60 alone to `31` → still PASS). Fix: make each same-file claim's expect file-unique (here `(32 checks)`); and when reviewing a whole-file-match gate, audit same-file expect-uniqueness explicitly, not just per-claim count-presence. · evidence: T-010 D-1, verify_all G.4 row-3 + the same-file-uniqueness audit
