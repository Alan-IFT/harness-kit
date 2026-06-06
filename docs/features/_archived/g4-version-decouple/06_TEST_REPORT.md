# 06 — Test Report · T-010 · g4-version-decouple

**Stage:** 6 (QA Tester) · **Date:** 2026-06-06 · **Shells:** PowerShell 7 + git-bash (`C:\Program Files\Git\bin\bash.exe`, not the WindowsApps stub).
**Method:** adversarial mutation of the live tree; every mutation reverted by restoring a pre-QA file snapshot (NOT `git restore` — the decouple is uncommitted working-tree state). Tree integrity proven against a baseline `git diff` sha after every probe.

> **Note on revert method:** the 6 decouple edits are **uncommitted** working-tree changes. `git restore <file>` would discard them (it restores from HEAD = the OLD versioned text). All reverts use `cp <snapshot> <file>` from a pre-QA backup so the developer's uncommitted decouple is preserved. A single early `git restore` mis-step was caught and fully repaired (the file was returned byte-identical to the developer state; `git diff --stat` matches `04_DEVELOPMENT.md` exactly).

---

## 1. Mechanical verification (real output)

| Check | PowerShell | git-bash (full suite) |
|---|---|---|
| Total | **32 PASS / 0 WARN / 0 FAIL** | **32 PASS / 0 WARN / 0 FAIL** (run #1, clean) |
| `[G.4]` | PASS | PASS |
| `[G.3]` stamps (still 0.21.1) | PASS | PASS |
| G.4 CHANGELOG `[0.21.1]` | present, check passes | present, check passes |
| G.4 last + tripwire | green (G.4 is final recorded check) | green |
| exit code | 0 | 0 |

The 6 live claim lines were read and confirmed de-versioned (no `at v0.21.1`): `AI-GUIDE.md:36` `(32/32; check count grows…)`, `AI-GUIDE.md:69` `(32 checks, including…)`, `docs/dev-map.md:60` `(32 checks)`, `docs/dev-map.md:133` `runs all 32 checks including…`, `.harness/rules/40-locations.md:25` `(32 checks, all must PASS…)`, `docs/manual-e2e-test.md:3` `verify_all` at `32 checks;`.

**git-bash full-suite note:** `verify_all.sh` completed cleanly on the first run, then **intermittently wedged at the I.6 step** (the `git ls-files` × banned-phrase `grep` fork-storm at `verify_all.sh:561-593`) on 3 of 4 subsequent attempts on this Windows host — a **pre-existing environment/perf characteristic of I.6, untouched by T-010** (T-010 edits only the G.4 ledger). To obtain authentic bash G.4 evidence without the I.6 hang, cross-shell G.4 probes (§2) were run through a throwaway harness that pre-seeds `report` with 31 entries (so `g4_count = 32`) and executes the **G.4 ledger block copied verbatim** from `verify_all.sh:670-752`. It was validated to reproduce the full-suite result exactly: G.4 PASS, count=32, version=0.21.1 on the clean tree. Harness deleted after use; tree pristine.

---

## 2. Adversarial tests (REQUIRED — ≥1 per AC)

Independent reproducers written from the ACs (not from `04`'s test code). Each has a stated failure hypothesis; verdict = whether the implementation survived.

| AC | Hypothesis ("I expect FAIL when…") | Reproducer (NEW, I wrote it) | Outcome (tool output) |
|---|---|---|---|
| **AC-1** | a live claim still carries `at v0.21.1` | read 6 lines + grep | **Survived** — all 6 de-versioned, zero `at v0.21.1` |
| **AC-2 r1** | AI-GUIDE:36 `32/32`→`31/31` | mutate L36, PS+sh G.4 | **Survived (caught)** — G.4 FAIL `found '31/31', expected '32/32'` |
| **AC-2 r2** | AI-GUIDE:69 `32 checks`→`31` | mutate L69, PS G.4 | **Survived (caught)** — G.4 FAIL `found '31 checks', expected '32 checks'` |
| **AC-2 r3** | dev-map:60 `(32 checks)`→`(31 checks)` | mutate L60 **only**, PS+sh G.4 | **FAILED — drift NOT caught.** G.4 **PASS** (masked). Filed **MAJOR / D-1** |
| **AC-2 r4** | dev-map:133 `runs all 32`→`31` | mutate L133, PS+sh G.4 | **Survived (caught)** — G.4 FAIL `found 'runs all 31 checks', expected 'runs all 32 checks'` |
| **AC-2 r5** | 40-locations:25 `(32 checks`→`(31` | mutate L25, PS+sh G.4 | **Survived (caught)** — G.4 FAIL `found '(31 checks', expected '(32 checks'` |
| **AC-2 r10** | manual-e2e:3 `at 32 checks`→`31` | mutate L3, PS G.4 | **Survived (caught)** — G.4 FAIL `found '31 checks', expected '32 checks'` |
| **AC-3** | count-unchanged `0.21.2` bump forces a prose-claim edit | bump plugin.json, 6 claims untouched, PS+sh | **Survived** — see §2.2 (treadmill gone, version still gated) |
| **AC-4** | a 7th live version-bearing count claim remains | full-tree `git grep` (working tree) | **Survived** — zero live hits; all matches are CHANGELOG/HTML/_archived/feature-docs |
| **No-false-match** | G.4 reacts to a historical CHANGELOG count | mutate CHANGELOG `26→88 checks at v0.14` | **Survived** — G.4 unaffected (PASS), ignores history |

### 2.1 AC-2 mutation matrix — the load-bearing property (centerpiece)

For each decoupled claim, the count `32` was mutated to `31`/`33` in **that one doc line only**, then `verify_all` G.4 was run. Expectation per the QA brief: G.4 FAILs naming that file.

| # | File:line | Mutation | PS G.4 | sh G.4 | Caught? |
|---|---|---|---|---|---|
| r1 | `AI-GUIDE.md:36` | `32/32`→`31/31` | FAIL | FAIL | yes |
| r2 | `AI-GUIDE.md:69` | `32 checks`→`31` | FAIL | (parity, r-cls) | yes |
| **r3** | **`docs/dev-map.md:60`** | **`(32 checks)`→`(31 checks)`** | **PASS** | **PASS** | **NO — masked** |
| r4 | `docs/dev-map.md:133` | `runs all 32`→`31` | FAIL | FAIL | yes |
| r5 | `.harness/rules/40-locations.md:25` | `(32 checks`→`(31` | FAIL | FAIL | yes |
| r10 | `docs/manual-e2e-test.md:3` | `at 32 checks`→`31` | FAIL | (parity, r-cls) | yes |

Both shells were exercised for the brief's required representative rows (r4 `runs all`, r5 `(N checks`) plus the defective r3, and gave **identical verdicts** on the same tree state.

**The r3 defect — root cause (proven, not inferred):** G.4's load-bearing test is a **whole-file** substring check (`$raw.Contains($c.expect)` PS:666 / `[[ "$g4_raw" == *"$g4_expect"* ]]` sh:732). After T-010, row 3's `expect` was shortened from `"32 checks at v0.21.1"` to **`"32 checks"`**, which is a substring of row 4's text `runs all 32 checks` on `docs/dev-map.md:133`. So when L60 alone drifts to `(31 checks)`, the file **still contains** `"32 checks"` (via L133) → contains-test true → row 3 silently passes.

- **Pre-T-010 this drift WAS caught** (proven by reconstructing HEAD): row-3 expect `"32 checks at v0.21.1"` appears ONLY on L60 (L133 read `runs all 32 checks (at v0.21.1)` — the `(` breaks the substring). Mutating HEAD L60→`31 checks at v0.21.1` removes the only occurrence → G.4 would FAIL. **T-010 introduced the masking** by collapsing two formerly-distinct expects into a substring relationship.
- **Mitigation that limits blast radius:** row 4 (`"runs all 32 checks"`, L133) still independently catches drift on L133, and a normal full count-bump edits **both** dev-map lines → caught (verified: "both drift" → G.4 FAIL on both rows). The unprotected case is narrow: `docs/dev-map.md:60` drifts while L133 stays correct (a partial/typo edit to the tree annotation). No false-PASS on any other file.

### 2.2 AC-3 — treadmill gone (count-unchanged version bump), both shells

Fixture: `plugin.json` `0.21.1`→`0.21.2` (count stays 32); the 6 prose claims **NOT** touched.

- **Run A (no CHANGELOG `[0.21.2]`):** PS & sh G.4 **FAIL on ONLY** `CHANGELOG.md: missing '[0.21.2]' heading` — **none of the 6 prose claims is named.** `[G.3]` also FAILs (badges still 0.21.1). → version is still gated at stamps (G.3) + CHANGELOG (G.4), and the bump did **not** require editing the prose claims.
- **Run B (add CHANGELOG `[0.21.2]`, claims still untouched):** PS & sh G.4 **PASS**; G.3 still FAILs (only plugin.json bumped, badges not). → the count-only prose claims satisfy G.4 at the new version with **zero edits**. **The per-release "bump 6 prose strings" treadmill is gone, with no loss of version gating.**

### 2.3 AC-4 — exhaustive removal (working-tree sweep)

`git grep` (no rev = working tree) for `checks? at v[0-9]` / `[0-9]/[0-9]+ at v[0-9]` / `项检查…v[0-9]`, excluding CHANGELOG/`*.html`/`docs/features/**`/`_archived/**` → **ZERO live hits.** Unrestricted sweep: every remaining version+count string lives only in `CHANGELOG.md`, `architecture.html`, `docs/features/_archived/**`, or `docs/features/g4-version-decouple/**` (all legitimately out of scope). Control: `git grep HEAD …` still finds the OLD tokens on `AI-GUIDE.md:69` / `docs/dev-map.md:60`, proving the pattern is live and HEAD carries them — i.e. the working-tree zero is the decouple, not a broken pattern.

### 2.4 Historical immunity / no false-match

Mutating a historical `CHANGELOG.md` count (`26 checks at v0.14`→`88 checks at v0.14`) leaves G.4 **PASS** — G.4's ledger reads only the 11 designated claim files; CHANGELOG is consulted solely for the `[$version]` heading, never its body counts. No false-match on dated HTML either (G.4 never reads `*.html`).

---

## 3. Regression / parity

- **Count gating intact on 5/6 decoupled rows + the realistic both-line dev-map edit** (only the narrow `docs/dev-map.md:60`-alone case regressed — D-1).
- **No version coverage lost:** G.3 stamps + G.4 CHANGELOG heading still gate the release version (AC-3 proves both still FAIL when only one is bumped).
- **Tripwire / count derivation / rows 6-9,11 / `$version` derivation** untouched — count stays 32, G.4 is the last recorded check.
- **Cross-shell parity:** PS and bash G.4 give identical verdicts on every probed tree state (baseline, r1/r3/r4/r5 drift, AC-3 run A/B).
- **Stability:** PS `verify_all` ran 5× across the session, deterministic 32/32 each time. The bash full-suite I.6 wedge is environmental (fork-storm), not a flaky test of the change under review; isolated G.4 harness ran deterministically.

---

## 4. Defects found

- **[MAJOR] D-1 — `docs/dev-map.md:60` count drift is silently uncaught by G.4 (both shells). → RESOLVED in rollback #1 (see `## Re-verify (rollback #1)`); kept here for the record.**
  Row 3's de-versioned `expect="32 checks"` (`verify_all.ps1:652` / `verify_all.sh:713`) is a substring of row 4's `runs all 32 checks` on `docs/dev-map.md:133`, so the whole-file `.Contains`/`==*..*` test passes even when L60 reads `(31 checks)`. **Reproducer:** set `docs/dev-map.md:60` to `Total verification (31 checks)`, leave L133 unchanged, run `verify_all` → **G.4 PASS** (expected FAIL). Pre-T-010 the same drift FAILed (HEAD reconstruction). **Blast radius limited:** row 4 still gates L133; a both-line count bump is caught. **Not a BLOCKER** (suite green, happy path works, no data loss; the file is still count-gated for the common case) but it **re-opens the exact "count drift slips through" class T-008/G.4 exists to close**, for one specific line. **Fix is dev-scope** (route via PM): give row 3 a count-adjacent discriminator that is NOT a substring of row 4 — e.g. `expect="(32 checks)"` with shape `\(\d+ checks\)` for `docs/dev-map.md:60` (the line literally reads `(32 checks)`), mirrored in both shells. QA does not edit production code.

- **[NIT / cosmetic] D-2 — stale comment.** `verify_all.ps1:647` / `verify_all.sh:680-681` still say patterns "stay … version-anchored"; post-decouple rows 1-5,10 are no longer version-anchored. Behavior correct. Already flagged in `05_CODE_REVIEW.md` NIT; PM-scope (fold into the v0.21.2 ship pass). Not fixed by QA.

---

## 5. Final clean-tree confirmation

`git status --porcelain` = the developer's 6 source edits (`.harness/rules/40-locations.md`, `.harness/scripts/verify_all.{ps1,sh}`, `AI-GUIDE.md`, `docs/dev-map.md`, `docs/manual-e2e-test.md`) + PM's `docs/tasks.md` + untracked `docs/features/g4-version-decouple/` + pre-existing untracked `docs/system-overview.html`. **Working-tree `git diff` sha matches the pre-QA baseline** — every mutation reverted, the QA harness removed, no stray QA artifact. Final PS `verify_all` on the restored tree: **32 PASS / 0 WARN / 0 FAIL, G.4 PASS.**

---

## 6. Verdict

**CHANGES REQUIRED (1 MAJOR defect).** AC-1, AC-3, AC-4, no-false-match, cross-shell parity, and 5/6 of AC-2 all pass. **AC-2 fails for `docs/dev-map.md:60` (D-1):** a single-line count drift there is silently uncaught by G.4 in both shells — a T-010-introduced regression of the load-bearing count-coupling property, exactly the failure class the QA brief flags as a BUG ("If ANY of the 6 fails to catch the drift, that's a BUG"). Severity is MAJOR not CRITICAL because the file stays count-gated via row 4 for the realistic both-line edit and there is no false-PASS elsewhere. Route D-1 back to the developer via PM (one-row `expect`/`shape` change in both shells); D-2 NIT is PM-scope.

**Doc path:** `c:\Programs\HarnessEngineering\docs\features\g4-version-decouple\06_TEST_REPORT.md`

---

## Re-verify (rollback #1) · 2026-06-06 · D-1 fix re-test

**Scope:** re-verify the D-1 fix (row 3 / dev-map:60 now keys on file-unique `(32 checks)` / shape `\(\d+ checks\)`, both shells, per `04` Rework round 1 + `05` re-review) holds and nothing regressed. **Both shells.** Method: adversarial mutation of the live tree → observe → revert via pre-QA file snapshots (NOT `git restore` — the decouple is uncommitted). Baseline working-tree `git diff` sha `e206b15…` re-asserted after the AC-2 matrix and at the end.

**Bash method:** full `verify_all.sh` was attempted (`timeout 90`) — it got through G.3 then **wedged at the I.6 `git ls-files × grep` fork-storm (exit 124)**, the documented pre-existing MSYS env issue, NOT T-010 (which edits only the G.4 ledger). So authentic bash G.4 verdicts came from the **verbatim G.4-ledger-block probe** (`verify_all.sh:670-756` copied byte-for-byte, real `step()`/`extract_json_version()` helpers, `report` pre-seeded to 31 → `g4_count=32`). **Validated:** clean tree → probe G.4 **PASS, count=32, v0.21.1** = matches the PS full-run exactly. Throwaway probe scripts deleted after use.

### 1. Mechanical (restored tree)
- **PS `verify_all.ps1`: 32 PASS / 0 WARN / 0 FAIL, exit 0, [G.3] PASS, [G.4] PASS, tripwire silent (G.4 last).** Live `docs/dev-map.md:60` reads `Total verification (32 checks)` → row-3 `(32 checks)` matched → G.4 green.
- **bash G.4 (verbatim-block probe): PASS, count=32, v0.21.1.**

### 2. D-1 REGRESSION re-test — the bug that was missed (both shells) ✅ NOW CAUGHT
| Mutation (L60/L133 isolated) | PS G.4 | bash G.4 (probe) |
|---|---|---|
| `dev-map:60` `(32 checks)`→`(31 checks)`, **L133 left at 32** | **FAIL** `docs/dev-map.md: found '(31 checks)', expected '(32 checks)'` (31/0/1, exit 2) | **FAIL** same msg (errors=1) |
| `dev-map:133` `runs all 32`→`runs all 31`, **L60 left at 32** | **FAIL** `docs/dev-map.md: found 'runs all 31 checks', expected 'runs all 32 checks'` (31/0/1) | **FAIL** same msg |

The exact L60-alone drift that wrongly **PASSed** pre-fix now **FAILs naming dev-map.md** in both shells. **D-1 RESOLVED.** Row 4 still independently gates L133 (no regression from the row-3 shape change). Both reverted.

### 3. Full AC-2 matrix re-run — all 6 rows catch single-line drift (both shells)
One mutation at a time (`32→31`), G.4 run, FAIL must name the right file, then revert. **All 6 caught in BOTH shells** (exceeds brief's "≥PS for all 6"); previously-passing 5 did **not** regress under the row-3 shape change:

| # | File:line | Mutation | PS | bash | Caught? |
|---|---|---|---|---|---|
| r1 | `AI-GUIDE.md:36` | `32/32`→`31/31` | FAIL `found '31/31'` | FAIL | ✅ |
| r2 | `AI-GUIDE.md:69` | `(32 checks`→`(31 checks` | FAIL `found '31 checks'` | FAIL | ✅ |
| **r3** | **`docs/dev-map.md:60`** | **`(32 checks)`→`(31 checks)`** | **FAIL `found '(31 checks)'`** | **FAIL** | ✅ **(was D-1, now fixed)** |
| r4 | `docs/dev-map.md:133` | `runs all 32`→`31` | FAIL `found 'runs all 31 checks'` | FAIL | ✅ |
| r5 | `.harness/rules/40-locations.md:25` | `(32 checks`→`(31 checks` | FAIL `found '(31 checks'` | FAIL | ✅ |
| r10 | `docs/manual-e2e-test.md:3` | verify_all `32 checks`→`31` | FAIL `found '31 checks'` | FAIL | ✅ |

AI-GUIDE pair (L36/L69) and dev-map pair (L60/L133) both confirmed collision-free; r5 `(31 checks` did not collide with dev-map row-3 `(32 checks)` (cross-file file-pinning). `E.1` stayed PASS during the 40-locations mutation (repo-bespoke fragment, not template-synced).

### 4. AC-3 re-confirm — treadmill still gone (both shells)
Temp plugin.json `0.21.1`→`0.21.2` (count stays 32, **6 prose claims untouched**):
- **Run A (no CHANGELOG `[0.21.2]`):** G.4 FAILs on **ONLY** `CHANGELOG.md: missing '[0.21.2]' heading` — **zero prose claims named**; G.3 also FAILs on badges (PS 30/0/2; bash probe errors=1). Both shells identical.
- **Run B (add CHANGELOG `[0.21.2]`, claims still untouched):** G.4 **PASS** both shells (count-only prose satisfies the new version with zero edits); G.3 still FAILs (badges not bumped).
→ Version stays gated at G.3 stamps + G.4 CHANGELOG heading; the per-release "bump 6 prose strings" treadmill is gone. Reverted.

### 5. No new false-match from the row-3 shape change ✅
`(32 checks)` lives live on exactly two files: `docs/dev-map.md:60` (row 3) and `README.md:159` (row 8); all other hits are in `docs/features/_archived/**` (G.4 never reads them) — no HTML hit. Rows 3 & 8 share the literal but each reads ONLY its own pinned `file`. Proven bidirectionally: dev-map:60 drift → names dev-map (step 2); **reverse probe** `README.md:159` `(32 checks)`→`(31 checks)` with dev-map:60 intact → G.4 FAILs naming **`README.md: found '(31 checks)'`, NOT dev-map** (both shells). Neither same-literal row masks the other. Reverted.

### 6. Clean tree
Throwaway probe scripts deleted. `git status --porcelain` = the 6 developer decouple+rework edits (`40-locations.md`, `verify_all.{ps1,sh}`, `AI-GUIDE.md`, `dev-map.md`, `manual-e2e-test.md`) + PM's `docs/tasks.md` + untracked feature dir + pre-existing `docs/system-overview.html`. **Working-tree `git diff` sha == pre-QA baseline `e206b15…`** — every mutation reverted, no QA artifact. Final PS `verify_all`: **32 PASS / 0 WARN / 0 FAIL, G.4 PASS, exit 0.** `baseline.json` `verify_all_checks: 32` unchanged (decouple adds no check; bumping it would break G.4 row 11) — baseline preserved.

### Re-verify verdict
**APPROVED FOR DELIVERY.** D-1 RESOLVED — the dev-map:60-alone count drift is now caught in both shells; all 6 AC-2 rows catch single-line drift; AC-3 treadmill stays gone; no new false-match from the row-3 `(32 checks)` shape (file-pinning holds bidirectionally); cross-shell parity on every probed state; clean tree; suite 32/32. D-2 NIT (comment) was fixed by the developer and verified by CR. No new defects. (D-2  "version-anchored"→"count-anchored" comment fix folds naturally into the later v0.21.2 ship pass; not a blocker.)

**QA VERDICT: PASS** — D-1 fix holds in both shells, all 6 AC-2 rows + AC-3 re-confirmed, clean tree, verify_all 32/32 (bash G.4 via verbatim-block probe; full-suite I.6 wedge is pre-existing env, not T-010).
**Doc path:** `c:\Programs\HarnessEngineering\docs\features\g4-version-decouple\06_TEST_REPORT.md`
