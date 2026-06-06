# 02 — Solution Design · T-010 · g4-version-decouple

**Mode:** full · **Stage:** 2 (Solution Architect) · **Date:** 2026-06-06
**Upstream verdict:** `01_REQUIREMENT_ANALYSIS.md` §11 = **READY** (4 design decisions D1-D4 deferred here).
**Inputs read (this session):** `INPUT.md`; `01_REQUIREMENT_ANALYSIS.md`; `.harness/insight-index.md` (L13/L19/L20/L33/L34); `.claude-plugin/plugin.json` (`version=0.21.1`); `.harness/scripts/verify_all.ps1:625-699` (G.4 + tripwire); `.harness/scripts/verify_all.sh:660-758` (G.4 + tripwire); all 6 live claim lines; full-tree grep for `checks? at v\d | \d/\d+ at v\d | 项检查…v\d`.

---

## 1. Architecture summary

This is a **doc-truth + gate-coupling refactor**, no production runtime code. The system has one version source of truth (`.claude-plugin/plugin.json`, gated by G.3 badges + G.4's CHANGELOG `[version]`-heading check). Six prose count claims today **duplicate** that version by carrying a redundant `at v0.21.1` token alongside their genuinely-prose-resident check count. T-010 deletes the `at vX` token from those 6 claims and, in lockstep, rewrites the corresponding 6 G.4 ledger rows (rows 1-5,10) in **both** `verify_all.ps1` and `verify_all.sh` so they assert the **count only** while staying anchored enough to (a) still FAIL on a wrong count and (b) never falsely match a historical CHANGELOG/HTML row. Everything else in G.4 — the already-count-only rows (6-9,11), the CHANGELOG `[version]`-heading check, the `$version`/plugin.json derivation (still consumed by CHANGELOG), the `$report.Count+1` = 32 tally, and the "G.4 must stay last" tripwire — is **byte-identical**. Net: the version keeps exactly one gated home; the prose count claims stop being a per-release treadmill.

---

## 2. Affected modules (file paths from the existing repo)

| File | Role | Change |
|---|---|---|
| `.harness/scripts/verify_all.ps1` | PS gate, G.4 block (`:649-661` claims array) | Edit 6 rows (1,2,3,4,5,10) → count-only `shape`+`expect` |
| `.harness/scripts/verify_all.sh` | Bash gate, G.4 block (`:697-722` parallel arrays) | Edit the symmetric 6 rows → count-only `shape`+`expect` |
| `AI-GUIDE.md` | dogfood consumer doc | Edit `:36` + `:69` — drop `at v0.21.1` token |
| `docs/dev-map.md` | dogfood consumer doc | Edit `:60` + `:133` — drop `at v0.21.1` token |
| `.harness/rules/40-locations.md` | dogfood rule doc | Edit `:25` — drop `at v0.21.1` token |
| `docs/manual-e2e-test.md` | dogfood test checklist | Edit `:3` — drop `at v0.21.1` token |

No new files, no new dependencies, no schema/API. `CHANGELOG.md` gets a normal `[0.21.2]` release entry at ship (see §10 / D4 note), not touched by the decouple logic itself.

---

## 3. Module decomposition

Not applicable — no new modules. This is an edit-in-place refactor of one logical unit (the G.4 claim ledger) and its 6 truth sources. The "public API" of G.4 is unchanged: it is `Step "G.4" {…}` (PS) / `step "G.4" … "PASS|FAIL"` (sh), still the last recorded check, still deriving `count = report+1`.

---

## 4. Data model changes

None. No schema, no tables, no JSON shape change. `.harness/scripts/baseline.json` (`"verify_all_checks": 32`, G.4 row 11) is **untouched** — it is already count-only and carries no version.

---

## 5. The crux — D2: exact G.4 edits (both shells, symmetric)

### 5.1 Design rule for the new count-only patterns

Each decoupled row must satisfy two constraints simultaneously:

- **C-1 (AC-2, hard / T-008 property):** the `expect` literal must remain **specific to the count** so a `32→31` drift produces `found '…', expected '…'` and FAILs. The load-bearing test is the literal `$raw.Contains($c.expect)` (PS) / `[[ == *"$g4_expect"* ]]` (sh); the `shape` ERE only improves the FAIL message. Therefore `expect` must keep its **count-adjacent discriminator** (the surrounding `(`, `runs all`, `checks)`, etc.) — never a bare `checks`.
- **C-2 (no false match of a historical row):** the `shape` ERE must stay **anchored** to the same parenthesized / `runs all` / phrase discriminators the row used pre-T-010, minus only the `at v…` clause. A bare `[0-9]+ checks` shape would match historical CHANGELOG rows like `29 checks at v0.16.0` and the dated HTML `19 项检查`. Keeping the parenthesis / `runs all` / word anchors prevents that — and the `expect`-literal contains-test is evaluated **first** and short-circuits (`continue`) on the live doc, so the shape ERE is only ever reached on an already-failing doc, where the worst case is a slightly-off FAIL message, never a false PASS.

> Why the new shapes can't false-PASS: a PASS requires `expect.Contains` to be true. None of the new `expect` literals (`32/32`, `(32 checks)`-style with the row's own bracketing, `runs all 32 checks`, `(32 checks`, `verify_all` … `32 checks`) is a substring that appears in any historical/HTML file (those all read `N checks at vX`, a different string). So a stale historical row can never satisfy a live row's `expect` → no false PASS. Verified against the grep in §8.

### 5.2 PS — `.harness/scripts/verify_all.ps1`, the 6 rows in the `$claims = @(…)` array

Only rows 1-5 and 10 change; rows 6-9 and 11 stay byte-identical. The `at v$version` clause leaves both `shape` and `expect`:

| Row | Current `shape` | Current `expect` | **New `shape`** | **New `expect`** |
|---|---|---|---|---|
| 1 `AI-GUIDE.md` | `\d+/\d+ at v\d+\.\d+\.\d+` | `"$count/$count at v$version"` | `\d+/\d+` | `"$count/$count"` |
| 2 `AI-GUIDE.md` | `\d+ checks at v\d+\.\d+\.\d+` | `"$count checks at v$version"` | `\d+ checks` | `"$count checks"` |
| 3 `docs/dev-map.md` | `\d+ checks at v\d+\.\d+\.\d+` | `"$count checks at v$version"` | `\d+ checks` | `"$count checks"` |
| 4 `docs/dev-map.md` | `runs all \d+ checks \(at v\d+\.\d+\.\d+\)` | `"runs all $count checks (at v$version)"` | `runs all \d+ checks` | `"runs all $count checks"` |
| 5 `.harness/rules/40-locations.md` | `\(\d+ checks at v\d+\.\d+\.\d+` | `"($count checks at v$version"` | `\(\d+ checks` | `"($count checks"` |
| 10 `docs/manual-e2e-test.md` | `\d+ checks at v\d+\.\d+\.\d+` | `"$count checks at v$version"` | `\d+ checks` | `"$count checks"` |

Final intended PS array (rows 6-9,11 shown unchanged for the developer's reference):

```powershell
$claims = @(
    @{ file = "AI-GUIDE.md";                    shape = '\d+/\d+';                  expect = "$count/$count" }
    @{ file = "AI-GUIDE.md";                    shape = '\d+ checks';               expect = "$count checks" }
    @{ file = "docs/dev-map.md";                shape = '\d+ checks';               expect = "$count checks" }
    @{ file = "docs/dev-map.md";                shape = 'runs all \d+ checks';      expect = "runs all $count checks" }
    @{ file = ".harness/rules/40-locations.md"; shape = '\(\d+ checks';             expect = "($count checks" }
    @{ file = "README.md";                      shape = 'verify__all-\d+%2F\d+';    expect = "verify__all-$count%2F$count" }
    @{ file = "README.zh-CN.md";                shape = 'verify__all-\d+%2F\d+';    expect = "verify__all-$count%2F$count" }
    @{ file = "README.md";                      shape = '\(\d+ checks\)';           expect = "($count checks)" }
    @{ file = "README.zh-CN.md";                shape = '（\d+ 项检查）';            expect = "（$count 项检查）" }
    @{ file = "docs/manual-e2e-test.md";        shape = '\d+ checks';               expect = "$count checks" }
    @{ file = ".harness/scripts/baseline.json"; shape = '"verify_all_checks": \d+'; expect = ('"verify_all_checks": ' + $count) }
)
```

`$version` is **still read** at the top of the Step body (`:638-640`) and **still used** by the CHANGELOG check (`:676`). It is no longer referenced by the 6 count rows — but it is **not dead** (CHANGELOG still consumes it). Do **not** remove the `$version` derivation. (See D3.)

### 5.3 Bash — `.harness/scripts/verify_all.sh`, the 3 parallel arrays

Symmetric edit to the same 6 indices (0,1,2,3,4,9 in the 0-based parallel arrays; index 9 = manual-e2e-test, the 10th file):

`g4_shapes` (drop the ` at v[0-9]+\.[0-9]+\.[0-9]+` tail on the 6 rows):

```bash
g4_shapes=(
    '[0-9]+/[0-9]+'
    '[0-9]+ checks'
    '[0-9]+ checks'
    'runs all [0-9]+ checks'
    '\([0-9]+ checks'
    'verify__all-[0-9]+%2F[0-9]+'
    'verify__all-[0-9]+%2F[0-9]+'
    '\([0-9]+ checks\)'
    '（[0-9]+ 项检查）'
    '[0-9]+ checks'
    '"verify_all_checks": [0-9]+'
)
```

`g4_expects` (drop ` at v$g4_version` on the 6 rows):

```bash
g4_expects=(
    "$g4_count/$g4_count"
    "$g4_count checks"
    "$g4_count checks"
    "runs all $g4_count checks"
    "($g4_count checks"
    "verify__all-$g4_count%2F$g4_count"
    "verify__all-$g4_count%2F$g4_count"
    "($g4_count checks)"
    "（$g4_count 项检查）"
    "$g4_count checks"
    "\"verify_all_checks\": $g4_count"
)
```

`g4_files` array — **byte-identical** (no change). `g4_version=$(extract_json_version …)` at `:670` — **stays** (consumed by the CHANGELOG check at `:742-743`). The `if [[ -z "$g4_version" ]]` FAIL branch (`:675-677`) **stays** — CHANGELOG still needs a readable version. (See D3.)

### 5.4 What count drift looks like after the edit (C-1 walk-through)

Mutate `docs/dev-map.md:60` `(32 checks)` → `(31 checks)`. Live count is 32 → `expect="32 checks"` (row 3). `Contains("32 checks")` is now false (doc says `31 checks`). Shape `\d+ checks` matches `31 checks` → FAIL message `docs/dev-map.md: found '31 checks', expected '32 checks'`. **G.4 FAILs.** Same for `32/32`→`31/31` on row 1 (`\d+/\d+` shape), `runs all 32`→`runs all 31` on row 4, etc. AC-2 preserved on every decoupled row. The CHANGELOG check and rows 6-9,11 retain their pre-T-010 drift behavior untouched.

---

## 6. The 6 doc-claim edits (D1)

**D1 verdict: all 6 are living-current-state statements → drop `at vX`. No genuine "validated-at-vX" snapshot among them.** Evidence per line below (read live this session; surrounding prose preserved byte-for-byte except the deleted token):

| # | File:line | Current live text (exact) | New text (exact) | Living-state evidence |
|---|---|---|---|---|
| 1 | `AI-GUIDE.md:36` | `…all PASS checks are green (32/32 at v0.21.1; check count grows with releases) — this is the gate…` | `…all PASS checks are green (32/32; check count grows with releases) — this is the gate…` | Self-declares "check count grows with releases" → explicitly NOT a frozen snapshot. Delete ` at v0.21.1`, keep `; check count grows…`. |
| 2 | `AI-GUIDE.md:69` | `…total verification (32 checks at v0.21.1, including I.1-I.5 …).` | `…total verification (32 checks, including I.1-I.5 …).` | Describes the script's current behavior. Delete ` at v0.21.1`, keep the `, including …` list. |
| 3 | `docs/dev-map.md:60` | `│       ├── verify_all.{ps1,sh}         ← Total verification (32 checks at v0.21.1)` | `│       ├── verify_all.{ps1,sh}         ← Total verification (32 checks)` | Tree annotation of current script. Delete ` at v0.21.1` (keep closing `)` and the tree spacing exactly). |
| 4 | `docs/dev-map.md:133` | `… — runs all 32 checks (at v0.21.1) including both \`--check\` modes` | `… — runs all 32 checks including both \`--check\` modes` | Describes what `verify_all` does now. Delete ` (at v0.21.1)` **including its parentheses** (the parens existed only to wrap the version); keep one space between `checks` and `including`. |
| 5 | `.harness/rules/40-locations.md:25` | `` `.harness/scripts/verify_all` checks (32 checks at v0.21.1, all must PASS — count grows with releases): `` | `` `.harness/scripts/verify_all` checks (32 checks, all must PASS — count grows with releases): `` | Says "count grows with releases" → living. Delete ` at v0.21.1`, keep `, all must PASS — count grows with releases):`. |
| 6 | `docs/manual-e2e-test.md:3` | `…; \`.harness/scripts/verify_all\` at 32 checks at v0.21.1; \`.harness/scripts/test-supervisor.ps1\` at 49…` | `…; \`.harness/scripts/verify_all\` at 32 checks; \`.harness/scripts/test-supervisor.ps1\` at 49…` | The same line lists test-init / test-supervisor / test-verify-i6 counts **version-LESS** → verify_all was the lone inconsistent one. Delete ` at v0.21.1`, keep the trailing `;`. |

**Row 4 nuance (flag for developer):** unlike the other five, row 4's version token is wrapped in its own parentheses `(at v0.21.1)`. The deletion must remove the whole parenthetical, leaving `runs all 32 checks including` — collapse to a single space, no orphan `()`. The new G.4 row-4 `expect="runs all 32 checks"` and `shape='runs all \d+ checks'` match this exactly.

---

## 7. D3 — what STAYS in G.4 (byte-identical)

| Item | PS loc | sh loc | Status |
|---|---|---|---|
| Rows 6,7 (README badges `verify__all-32%2F32`) | `:655-656` | idx 5,6 | unchanged |
| Row 8 (`README.md` `(32 checks)`) | `:657` | idx 7 | unchanged |
| Row 9 (`README.zh-CN.md` `（32 项检查）`) | `:658` | idx 8 | unchanged |
| Row 11 (`baseline.json` `"verify_all_checks": 32`) | `:660` | idx 10 | unchanged |
| CHANGELOG `[$version]`-heading check | `:675-678` | `:742-744` | **unchanged — the legitimate per-release version gate kept in G.4** |
| `$version` / `g4_version` derivation | `:638-640` | `:670` (+`:675-677` FAIL branch) | **stays — still consumed by CHANGELOG; NOT dead** |
| `count` = `$report.Count+1` / `${#report[@]}+1` (= 32) | `:643` | `:673` | unchanged |
| "G.4 must stay last" tripwire | `:695-698` | `:758+` | unchanged |
| `count` doc-string / comments | `:641-648` | `:671-683` | comment text may keep "version" wording; behavior unchanged. Developer may lightly retune the `count/version` comment to `count` for the 6 rows, but this is cosmetic and **not required** for any AC. |

**Dead-code check (explicit):** after the edit, is `$version` derivation dead? **No.** It is still read by the CHANGELOG check (PS `:676`, sh `:742`). Removing it would break CHANGELOG gating. It becomes unused **only by the 6 count rows**, which is the intended decoupling. Keep it. The `if (-not $version) throw` / `if [[ -z "$g4_version" ]]` guard also stays (CHANGELOG needs a readable version).

---

## 8. Exhaustiveness guard (AC-4) — all 6 version tokens removed, zero remain

The closed set of live version-bearing count claims is **exactly these 6** (re-confirmed by full-tree grep this session, not hand-listed — per insight L33 discipline):

1. `AI-GUIDE.md:36` — `32/32 at v0.21.1`
2. `AI-GUIDE.md:69` — `32 checks at v0.21.1`
3. `docs/dev-map.md:60` — `(32 checks at v0.21.1)`
4. `docs/dev-map.md:133` — `runs all 32 checks (at v0.21.1)`
5. `.harness/rules/40-locations.md:25` — `(32 checks at v0.21.1`
6. `docs/manual-e2e-test.md:3` — `verify_all at 32 checks at v0.21.1`

**Confirmation grep (must return ZERO hits over the live tree after the edit):**

```bash
# PowerShell-friendly (run from repo root); excludes the legitimately-versioned history surfaces.
grep -rnE 'checks? at v[0-9]|[0-9]/[0-9]+ at v[0-9]|项检查.{0,8}v[0-9]' \
  --include='*.md' --include='*.json' \
  . \
  | grep -v 'CHANGELOG.md' \
  | grep -v 'docs/features/' \
  | grep -v '\.html'
```

This session's pre-change run of the same pattern returned exactly the 6 live hits above plus only: `CHANGELOG.md` history rows, `architecture.html:502` (dated HTML, T-008-exempt), and `docs/features/**` stage docs (INPUT/RA/_archived — all out of scope). After the edit the same grep over the live tree must be empty. **Critical (AC-4 rationale):** after decoupling, G.4 no longer gates a version token on the count rows, so a *leftover* `at v0.21.1` on any of the six would be **silently unchecked** — exactly the recurrence vector that gave T-008 two rollbacks. The grep above is the mechanical completeness proof; QA must run it (test (c) §11).

---

## 9. Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| Count-vs-live-tally gate (the property to preserve) | G.4 `$report.Count+1` ledger | `verify_all.ps1:643-672` / `verify_all.sh:673-739` | **Reuse / edit in place** — only the version clause of 6 rows leaves; the count-coupling mechanism is reused verbatim |
| Per-release version gate to retain | G.4 CHANGELOG `[$version]` check | `verify_all.ps1:675-678` / `verify_all.sh:742-744` | **Reuse as-is** — this is where version stays gated inside G.4 |
| Version SOT badge gate | G.3 plugin/marketplace/README version checks | `verify_all.sh:364-365` (and the G.3 block) | **Reuse as-is** — unchanged; the other version home |
| Version derivation | `extract_json_version` (sh) / `ConvertFrom-Json` (PS) | `verify_all.sh:354,670` / `verify_all.ps1:638` | **Reuse as-is** — keep for CHANGELOG, drop only from count rows |
| Exhaustive drift scan | `verify_all` itself as canonical scanner + raw `grep` | `verify_all.{ps1,sh}` | **Reuse** as the AC-2/AC-5 oracle; §8 grep as the AC-4 oracle (insight L28: use verify_all as the canonical exhaustive scan, not hand-reasoning) |
| Tripwire "G.4 last" | Summary self-reference check | `verify_all.ps1:695-698` / `verify_all.sh:758+` | **Reuse as-is** — count stays 32, no check added/removed, tripwire untouched |
| Retired-claim phrase guard (I.6) | banned-phrase scan | `verify_all.{ps1,sh}` I.6 block | **No interaction** — "at vX" is not an I.6 banned phrase; this task does not add one (the count claims still legitimately state a count, only the version token goes) |

Reuse audit is non-empty and proves the design extends existing machinery rather than reinventing it.

---

## 10. D4 — net strictly-better, no version coverage lost

After T-010, version consistency that **matters** stays fully gated:

- **Stamp versions** (plugin.json / marketplace.json / README `version-0.21.1` badge) → **G.3** (unchanged). This is the version SOT gate.
- **CHANGELOG per-release entry** (`[0.21.x]` heading) → **G.4's CHANGELOG check** (unchanged, still reads `$version`).
- **Prose count-claim version annotation** (`at vX` on the 6 rows) → **deleted, not un-gated.** Nothing it "protected" is lost, because the redundant duplicate ceases to exist. The count it sat next to is **still** gated against the live tally (rows 1-5,10 keep their count assertion).

So the only thing that stops being checked is a token that no longer exists. There is **no** version-consistency regression. Strictly-better: one source of truth for the version (plugin.json via G.3 + CHANGELOG), zero per-release prose-version churn.

**Self-demonstration (also QA AC-3):** the T-010 ship bump to **v0.21.2** will itself prove the treadmill is gone — bumping plugin.json/marketplace/README badges (G.3) and adding the `CHANGELOG [0.21.2]` heading (G.4 CHANGELOG check) will make verify_all green **without touching any of the 6 prose count claims** (they no longer carry a version, and the count is still 32). If, after the decouple, a v0.21.2 bump still required editing the 6 claims, the decouple would have failed. It will not. (See §11 test (b).)

**Decision on this task's own ship version:** the count does NOT change (stays 32) and no check is added — so per §5 of the RA's boundary analysis, the 6 claims need no count edit. However, the source change to `verify_all.{ps1,sh}` + 6 docs is a shippable behavioral change to the gate, so it is release-worthy. Recommend ship as **v0.21.2** (patch): bump G.3 stamps + add `CHANGELOG [0.21.2]` entry **as the normal release step**, which doubles as the AC-3 self-demonstration. The decouple edits themselves do not depend on the version bump and can land first; the bump is the closing release action. (PM/release-cutter owns the final version number; v0.21.2 is the SA recommendation.)

---

## 11. Test strategy for QA

| # | AC | Procedure | Expected |
|---|---|---|---|
| a | **AC-2 (hard)** | In a temp copy, mutate **one** count in any of the 11 rows (e.g. `docs/dev-map.md:60` `(32 checks)`→`(31 checks)`; also test row 1 `32/32`→`31/31` and row 4 `runs all 32`→`runs all 31`). Run `verify_all.ps1` and `verify_all.sh`. Revert. | G.4 **FAILs** in both shells, naming the mutated file with `found '31 …', expected '32 …'`. Count-coupling preserved on the decoupled rows. |
| b | **AC-3 (treadmill gone)** | Temp fixture: patch `plugin.json` `0.21.1`→`0.21.2` (count still 32), bump G.3-relevant stamps/badges + add a `CHANGELOG [0.21.2]` heading, but **do NOT touch any of the 6 prose count claims.** Run both shells. Then re-run with the `CHANGELOG [0.21.2]` heading **removed**. | First run: **G.4 PASS** with the 6 claims untouched (treadmill gone) and G.3 PASS once badges bumped. Second run (no CHANGELOG heading): **G.4 FAILs** on the missing `[0.21.2]` heading → confirms CHANGELOG gate retained. |
| c | **AC-4 (exhaustive)** | Run the §8 confirmation grep over the live tree after the edit. | **Zero hits** — no live prose count claim retains a version token. |
| d | **AC-5 / AC-1** | Run `verify_all.ps1` and `verify_all.sh` on the real (post-edit) repo. Read all 6 claim lines. | **32/32 PASS, 0 WARN, 0 FAIL in BOTH shells**; G.4 PASS; G.4 is last; tripwire green; the 6 lines contain no `at v0.21.1`. Diff the 6 G.4 rows across the two shells to confirm symmetric edit (insight L13/L20). |

QA must run **both** shells for every applicable test — the one-shell-edit defect class has shipped here before (insight L13/L20).

---

## 12. Risk analysis

| # | Risk | Likelihood | Mitigation |
|---|---|---|---|
| R-1 | **Count-only pattern so loose it stops catching count drift** (violates AC-2). E.g. a developer simplifies `expect` to bare `"checks"`. | Med | §5.1 C-1 mandates the `expect` literal keep its count + count-adjacent discriminator (`32/32`, `(32 checks`, `runs all 32 checks`, `32 checks`). §5.4 walks the 32→31 FAIL on each row. QA test (a) is the hard gate. The `expect` **literal**, not the `shape` ERE, is the load-bearing assertion — keep the digit in it. |
| R-2 | **New shape falsely matches a historical/HTML row** (false PASS). | Low | The `expect`-`Contains` test runs **first** and short-circuits on the live doc, so the `shape` ERE only ever runs on an already-failing doc (worst case: imperfect FAIL message, never a false PASS). Additionally none of the new `expect` literals is a substring of any historical row (those read `N checks at vX`, a distinct string) — verified by the §8 grep. New shapes keep their `(` / `runs all` / `）` anchors. |
| R-3 | **PS/Bash asymmetry** — one shell edited, the other not (the project has shipped this before, insight L13/L20). | Med-High | §5.2/§5.3 give both shells' exact arrays. QA test (a)+(d) runs and diffs **both** shells. The change surface is mechanically symmetric: same 6 indices, same token deleted. |
| R-4 | **A 7th (leftover) version token in a count claim left stale** — after decouple G.4 no longer catches it (silent eyesore). T-008's exact rollback vector. | Med | §8 closes the set at 6 via full-tree grep (not hand-listing); QA test (c) re-runs that grep post-edit for zero hits (AC-4). |
| R-5 | **Version-derivation code mistaken for dead and removed** — would break the CHANGELOG gate. | Low-Med | §7 + D3 explicitly state `$version`/`g4_version` (and its FAIL/`-z` guard) **stays** — still consumed by CHANGELOG (PS `:676`, sh `:742`). Do not delete. QA test (b) second run (missing CHANGELOG heading must still FAIL) catches an accidental removal. |
| R-6 | **Tally accidentally changes** (a row added/removed/reordered, count derivation drifts off 32). | Low | §4/§7: no check added/removed, count stays 32, `report+1` and tripwire untouched. QA test (d) confirms 32/32 + tripwire green. |
| R-7 | **Row-4 parenthesis orphan** — deleting `(at v0.21.1)` leaves `()` or a double space, so the new `expect="runs all 32 checks"` no longer `Contains`-matches. | Med | §6 row-4 nuance: remove the whole `(at v0.21.1)` parenthetical and collapse to a single space → `runs all 32 checks including`. QA test (d) (G.4 PASS) catches a mismatch. |

All risks have a mitigation; none is a blocker.

---

## 13. Migration / rollout plan

- **Backwards compatibility:** the gate stays at 32 checks; downstream user projects that `init`/`adopt` from templates are unaffected (this is a dogfood-repo doc + dogfood-gate change; the **template** `verify_all` for user projects is a separate generated artifact and is **out of scope** unless a sync rule says otherwise — see §14). No feature flag needed.
- **Sequence:** (1) edit the 6 G.4 rows in `verify_all.ps1`; (2) mirror identically in `verify_all.sh`; (3) edit the 6 doc claim lines (§6); (4) run both shells → 32/32 PASS; (5) run §8 grep → zero hits; (6) closing release step: bump G.3 stamps + add `CHANGELOG [0.21.2]` (= AC-3 self-demo). Order (1)-(5) is the decouple; (6) is the normal ship. Steps (1)-(3) are independent of (6).
- **Rollback:** the change is local to one G.4 block × 2 shells + 6 doc lines. If verify_all FAILs unexpectedly, `git revert` of the doc edits and the G.4 rows restores the prior version-coupled behavior (count gating was never removed, so a partial revert is safe). T-008's lesson (insight L33) — re-confirm completeness via grep, not by eyeballing — is encoded in QA test (c).
- **Data migration:** none.

---

## 14. Out-of-scope clarifications (design boundaries)

1. **Template `verify_all`** — **confirmed non-issue this session:** `glob templates/**/verify_all.*` returns **no files**, i.e. there is no template-side `verify_all` carrying a parallel G.4 ledger to keep in sync. `verify_all` is bespoke to the dogfood repo (consistent with insight L12: `sync-self` mirrors only 4 specific scripts — `verify_all` is not one of them). No template fan-out is required. (Recorded so a future session does not re-investigate.)
2. **G.3 stamp/badge checks** — unchanged (the version SOT gate).
3. **CHANGELOG `[version]` heading check** — unchanged (the per-release version gate inside G.4).
4. **The check COUNT (32) and the count-against-tally coupling** — unchanged; only version coupling is removed.
5. **Adding/removing/reordering any check** — none; G.4 stays last.
6. **Already-count-only rows 6-9,11** — unchanged.
7. **Historical/snapshot files** — `CHANGELOG.md` body, dated HTMLs (`architecture.html`, `docs/system-overview.html`, etc.), `docs/features/_archived/**`, `tasks.md`, `INPUT.md` — never touched.
8. **Prose polish beyond the version token** — out of scope; only the `at vX` token (and, for row 4, its wrapping parens) is removed.

---

## 15. Partition assignment

`.harness/agents/dev-*.md` glob returned **no files** → this project uses **single-Developer mode**. No partition table required. One Developer implements all of §2 in a single pass: G.4 (both shells, symmetric) first, then the 6 doc lines, then verify-both-shells + grep.

---

## 16. Verdict

**READY.** All four design decisions resolved:
- **D1** — all 6 claims are living-current-state → drop `at vX`; exact new wording specified per line (§6).
- **D2** — exact count-only `shape`+`expect` specified for all 6 rows in BOTH shells (§5); count drift still FAILs (§5.4); no historical/HTML false-match (§5.1 C-2).
- **D3** — rows 6-9,11 + CHANGELOG check + count derivation + tripwire stay byte-identical; `$version` derivation **stays** (CHANGELOG still consumes it — not dead) (§7).
- **D4** — net strictly-better: stamps→G.3, CHANGELOG→G.4, prose version annotation deleted-not-ungated; the v0.21.2 ship is the self-demonstration (§10).

No new dependencies. Change surface is closed: 6 G.4 rows × 2 shells + 6 doc lines. Implementable by a junior developer from §5/§6 without further design decisions.

---

**DESIGN COMPLETE — 6 claims decoupled, G.4 count-only for rows 1-5+10, CHANGELOG+G.3 version-gates retained**

**DESIGN RISK:** None blocking. The two implementation-time traps are **R-7** (row-4 `(at v0.21.1)` parenthesis-orphan — remove the whole parenthetical, collapse to one space) and **R-3** (PS/Bash asymmetry — edit both shells' 6 rows identically); both are gated by QA test (d) and the §8 grep. Template-side parity was investigated and confirmed a non-issue (§14.1: no `templates/**/verify_all.*` exists).

**Doc path:** `c:\Programs\HarnessEngineering\docs\features\g4-version-decouple\02_SOLUTION_DESIGN.md`
