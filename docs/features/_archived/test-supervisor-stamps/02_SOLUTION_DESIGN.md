# 02 — Solution Design: test-supervisor-stamps (T-008)

> Mode: **full**. Stage 2 of the Harness pipeline. Upstream `01_REQUIREMENT_ANALYSIS.md` verdict = **READY**.
> Guiding principle (binding, user): long-term maintainability — the chosen design must make it
> structurally impossible (or gate-caught) for these asserts to silently drift across future
> version/check-count bumps. No hand-edited version literal per release.

## 1. Architecture summary

Split the drifting "Doc fan-out spot checks" by ownership: the 5 asserts that re-verify
project version stamps (README/plugin/marketplace/CHANGELOG) are **removed** from
test-supervisor because they duplicate or belong with `verify_all` G.3, not the supervisor
regression; the 3 supervisor-structural asserts **stay** unchanged; and the genuinely-uncovered
gap — the **`N checks at vX.Y.Z` doc-claim consistency** (AI-GUIDE×2, dev-map×1, README×1,
manual-e2e-test×1) plus the **current-version CHANGELOG entry** — moves to a **new standing
`verify_all` meta-check G.4** that derives both the version (from `.claude-plugin/plugin.json`)
and the check count (from `verify_all`'s own live PASS tally) and validates every doc claim
against those two sources of truth. test-supervisor keeps zero release-tracking literals; the
drift class dies at the gate, where it should have lived all along.

## 2. Decisions (Q1 / Q2 / Q3 resolved)

### Q1 — Disposition of the 12 fan-out asserts → **Option C (remove the stamp duplicators, relocate the count-claim coverage to a gate)**

Per-assert disposition (numbering and categories from §7 of `01_REQUIREMENT_ANALYSIS.md`):

| # | PS line | SH line | Assertion (current literal) | Cat | Disposition | Where coverage lands |
|---|---|---|---|---|---|---|
| 1 | 416-418 | 377-379 | AI-GUIDE `auxiliary.*supervisor` phrasing | (c) | **KEEP as-is** | test-supervisor (version-agnostic) |
| 2 | 419-421 | 380-382 | AI-GUIDE `30/30 at v0.17.1` | (b) | **REMOVE** | verify_all G.4 (new) |
| 3 | 422-424 | 383-385 | AI-GUIDE `30 checks at v0.17.1` | (b) | **REMOVE** | verify_all G.4 (new) |
| 4 | 425-427 | 386-388 | CHANGELOG `[0.17.1]` entry | (a*) | **REMOVE** | verify_all G.4 (new — current-version entry) |
| 5 | 428-430 | 389-391 | README.md badge `version-0.17.1-` | (a) | **REMOVE** | verify_all G.3 (existing) |
| 6 | 431-433 | 392-394 | README.zh-CN badge `version-0.17.1-` | (a) | **REMOVE** | verify_all G.3 (existing) |
| 7 | 434-437 | 398-400 | plugin.json version `0.17.1` | (a) | **REMOVE** | verify_all G.3 (existing) + it is the SOT |
| 8 | 438-441 | 395-397* | marketplace.json version `0.17.1` | (a) | **REMOVE** | verify_all G.3 (existing) |
| 9 | 442-444 | 401-403 | dev-map `30 checks at v0.17.1` | (b) | **REMOVE** | verify_all G.4 (new) |
| 10 | 445-447 | 404-406 | harness-status `upervisor.*auxiliary` row | (c) | **KEEP as-is** | test-supervisor (version-agnostic) |
| 11 | 448-451 | 407-409 | harness-status canonical-7 glob | (c) | **KEEP as-is** | test-supervisor (version-agnostic) |

\* SH line numbers differ from PS and are not strictly monotonic vs the PS order (marketplace/plugin
are swapped in the `.sh` block). The Developer must match by **assertion text**, not by line number.

**Rationale.** test-supervisor is the *supervisor-agent contract regression*. Asserts #5–#8 literally
re-implement G.3's four-stamp consistency check inside the wrong test — that is duplication, and
because test-supervisor is not gated, the duplicate was the silently-rotting copy. Asserts #2/#3/#9
are not duplicates (G.3 does not cover count claims), but their natural owner is still the gate, not
the supervisor regression: a "does AI-GUIDE's check-count claim match reality" assertion has nothing
to do with the supervisor agent's behavior. So removing all of #2–#9 from test-supervisor is correct
*provided their coverage is reconstituted at the gate* (Q2). The three category-(c) asserts (#1/#10/#11)
are genuine supervisor-structural checks (the "auxiliary supervisor" phrasing in AI-GUIDE that the
supervisor agent's existence implies, the harness-status auxiliary row, and the canonical-7 glob that
must not be widened to include the auxiliary agent) — they contain no version literal and stay verbatim.

**Constraint satisfied** (§8 Q1 of stage 1: "whatever is removed must not leave a previously-green
coverage silently uncovered"): the only coverage that test-supervisor uniquely held was the
**current-version CHANGELOG entry** (#4 — CHANGELOG is not in G.3's four-stamp set) and the
**count-claim coverage** (#2/#3/#9). Both are explicitly reconstituted in G.4 (Q2). Nothing is dropped.

### Q2 — Recurrence prevention → **Option (ii): one new lightweight `verify_all` meta-check G.4**

Reject (i) "wire test-supervisor into verify_all": it adds the full supervisor fixture suite to the
gate's wall-clock and couples the gate to fixtures unrelated to stamp drift (NFR-3, soft latency).
Reject (iii) "pure derive-in-test, no gate": test-supervisor is **not run by verify_all**, so a
derive-only design self-heals the *test* but still leaves the *doc claims* (AI-GUIDE/dev-map/README/
manual-e2e) ungated — which is the actual hole that let this rot for 5 releases. A derive-only test
would pass forever regardless of whether the docs are right, defeating AC-6's "demonstrably load-bearing".

**Chosen: G.4** — a new standing check in `verify_all.{ps1,sh}` that:
1. reads the **version** from `.claude-plugin/plugin.json` (the single SOT, same source G.3 already trusts);
2. reads the **check count** from `verify_all`'s own live PASS tally (`$pass` / `$pass_count`) — the
   number is computed at runtime, never a literal (Q3);
3. asserts every consumer-doc **`<N> checks at v<X>` / `<N>/<N> at v<X>`** claim and the
   **bare `<N> checks`** / **badge `verify_all-<N>%2F<N>`** claim matches `(count, version)`; and
4. asserts a **`[<version>]` CHANGELOG heading exists** for the current version.

This is the STANDING gate that was missing. It is ~30 lines/shell (comparable to I.7), runs no
subprocess, and turns "doc count drift" from an undetectable silent-red into a hard FAIL at the gate
that every release already runs. AC-5 becomes **32/32** (31 existing + G.4); the new check is justified
here.

### Q3 — Source of truth for the "N checks" count → **verify_all's own runtime PASS tally, read in-process**

There is no canonical static "number of checks" literal anywhere, and there must not be one (a literal
is itself a drift point). G.4 runs **last** in `verify_all`, after every other `Step`/`step` has
executed, so the count is already materialized:

- **PS** (`verify_all.ps1:626`): `$pass = ($report | Where-Object status -eq "PASS").Count` is computed
  in the Summary block. G.4 must compute the *expected* check count **including itself but excluding its
  own pass/fail outcome's effect on the tally** — see §6 (self-reference). The clean approach: G.4 derives
  the count as **`$report.Count + 1`** (total checks recorded so far, plus G.4 itself which has not yet
  appended its own record at the moment its action body runs), independent of PASS/WARN/FAIL status, so a
  WARN on a doc-size check does not change the *check count*. The doc claim is a count of *checks*, not of
  *passes*; deriving from `$report.Count` (all recorded steps) is the correct, status-independent SOT.
- **Bash** (`verify_all.sh:659`): `pass_count=$(printf '%s\n' "${report[@]}" | grep -c PASS)`. The
  symmetric count is **`${#report[@]} + 1`** (array length of recorded steps + G.4 itself), again
  status-independent.

**Why `report.Count + 1`, not the PASS count:** the doc claims read "31 checks", i.e. the number of
verification steps, which is invariant to whether any step WARNs. Using the PASS count would make the
doc claim flicker to 30 whenever a WARN-only doc-size check (I.1–I.5) trips — a false FAIL. The count of
*recorded steps* (`$report.Count` / `${#report[@]}`) is the stable SOT. At the moment G.4's body runs it
has recorded 31 prior steps and is the 32nd, so expected = 31 + 1 = 32... **but the docs claim the count
that ships, which after this task is 32.** See §6 for the exact bootstrapping sequence and the doc-value
this resolves to.

**Boundary §4.3 (count unobtainable):** in `verify_all`'s own process the count is always obtainable
(it is in-memory). G.4 has no external dependency for the count, so the "documented-skip vs FAIL"
boundary does not arise here — it would only arise if test-supervisor tried to derive the count by
*running* verify_all, which this design deliberately avoids. test-supervisor no longer touches the count
at all.

## 3. Affected modules

| File | Role | Change |
|---|---|---|
| `.harness/scripts/test-supervisor.ps1` | supervisor regression (PS) | remove 8 asserts (#2–#9), keep 3 (#1/#10/#11) |
| `.harness/scripts/test-supervisor.sh` | supervisor regression (bash) | remove the 8 twin asserts, keep the 3 twins |
| `.harness/scripts/verify_all.ps1` | repo gate (PS) | add Step `G.4` before the Summary block |
| `.harness/scripts/verify_all.sh` | repo gate (bash) | add `step "G.4" ...` before the Summary block |
| `AI-GUIDE.md` | consumer doc | **no edit** — already says `31/31 at v0.20.0` & `31 checks at v0.20.0`; G.4 will require updating these to the new count (see §5) |
| `docs/dev-map.md` | consumer doc | edit the count claim to the new shipped count (§5) |
| `README.md` | consumer doc | edit badge + `(N checks)` to the new count (§5) |
| `README.zh-CN.md` | consumer doc | edit BOTH the `verify__all-N%2FN` count badge (line 5) AND the `（N 项检查）` zh count claim (line 159, currently STALE at 30) to the new count (§5) — G.3 covers the *version* badge here, NOT either count claim |
| `.harness/rules/40-locations.md` | consumer doc (rule fragment) | edit the `(N items/checks at vX)` count claim on line 25 to the new count (§5); wording normalized "items"→"checks" so one G.4 pattern covers it |
| `docs/manual-e2e-test.md` | consumer doc | edit `at N checks at vX` to the new count (§5) |
| `.harness/scripts/baseline.json` | machine-readable baseline | edit `"verify_all_checks": N` on line 10 to the new count (§5); G.4 gates it by string-substring, NOT JSON parse (F-5) |
| `CHANGELOG.md` | release log | add a `[<new-version>]` entry (release-cut concern; see §5 / out-of-scope) |

## 4. Module decomposition — the new G.4 check

**Name:** `G.4` "Doc count/version claims consistent with plugin.json + live check count".

**Responsibility (single):** every place a consumer doc states the verify_all check count and/or the
release version must agree with (a) `plugin.json.version` and (b) the live recorded-step count. Plus:
a CHANGELOG heading for the current version exists.

**Inputs (no literals):**
- `version` ← `plugin.json.version` (PS: `ConvertFrom-Json`; bash: the existing `extract_json_version`
  helper at `verify_all.sh:354-358` — **reuse it**, do not re-implement).
- `count` ← PS `$report.Count + 1`; bash `${#report[@]} + 1` (§3/§6).

**Claims validated (the SOT-derived expected strings):**

| Doc | Pattern to find | Expected substring built from SOT |
|---|---|---|
| `AI-GUIDE.md` | `\d+/\d+ at v\d+\.\d+\.\d+` | `"$count/$count at v$version"` |
| `AI-GUIDE.md` | `\d+ checks at v\d+\.\d+\.\d+` | `"$count checks at v$version"` |
| `docs/dev-map.md` (line 60) | `\d+ checks at v\d+\.\d+\.\d+` | `"$count checks at v$version"` |
| `docs/dev-map.md` (line 133) | `runs all \d+ checks \(at v\d+\.\d+\.\d+\)` — **parenthesized `checks (at vX)` form** (see F-1b note) | `"runs all $count checks (at v$version)"` |
| `.harness/rules/40-locations.md` | `\(\d+ checks at v\d+\.\d+\.\d+` (line 25; see F-1 wording note below) | `"($count checks at v$version"` |
| `README.md` | badge `verify__all-\d+%2F\d+` | `"verify__all-$count%2F$count"` |
| `README.zh-CN.md` | badge `verify__all-\d+%2F\d+` (same `%2F` form as README.md; G.3 covers only the *version* badge here) | `"verify__all-$count%2F$count"` |
| `README.md` | `\(\d+ checks\)` — **parenthesized form ONLY** (see F-3 below) | `"($count checks)"` |
| `README.zh-CN.md` (line 159) | `（\d+ 项检查）` — **full-width-parenthesized zh form ONLY** (see F-7 below; the zh twin of `README.md:159`, currently stale at 30) | `"（$count 项检查）"` |
| `docs/manual-e2e-test.md` | `verify_all.* at \d+ checks at v\d+\.\d+\.\d+` | `"$count checks at v$version"` |
| `.harness/scripts/baseline.json` (line 10) | substring `"verify_all_checks": \d+` — **string-compare, NO JSON parse** (see F-5 below) | `"\"verify_all_checks\": $count"` |
| `CHANGELOG.md` | `\[$version\]` heading present | literal `"[$version]"` |

**F-1 wording note (`40-locations.md:25`).** The live line reads `... checks (31 items at v0.20.0, all
must PASS — count grows with releases)` — it says **"items"**, not "checks", so the standard
`\(\d+ checks at v…\)` pattern would not match it as-is. **Chosen resolution: normalize the wording to
the standard form** — the Developer changes `(N items at vX...)` → `(N checks at vX...)` on line 25 as
part of the one-time §5 edit (the items in the bulleted list below line 25 *are* the checks, so "checks"
reads naturally). This lets the **single existing parenthesized `\(\d+ checks at v\d+\.\d+\.\d+` G.4
pattern cover both `dev-map.md` and `40-locations.md:25`** with no special-case sub-pattern — the more
uniform, lower-maintenance option (the alternative — a bespoke `(N items)` sub-pattern carried inside
G.4 — is explicitly rejected as an extra divergent pattern to maintain in both shells). After this
one-time normalize, G.4 validates `40-locations.md:25` exactly like `dev-map.md:60`.

**F-1b note (`dev-map.md:133` distinct form).** The two dev-map count claims are NOT the same shape:
`dev-map.md:60` is `... (31 checks at v0.20.0)` (the `checks at vX` adjacency), but `dev-map.md:133` is
`runs all 31 checks (at v0.20.0)` — the version sits in its OWN parentheses *after* "checks", so the
`\d+ checks at v…` pattern does **not** match line 133. G.4 therefore carries a **second dev-map
sub-pattern** `runs all \d+ checks \(at v\d+\.\d+\.\d+\)` for line 133 (both shells). Both dev-map lines
are gated; neither is left to drift. (We do NOT normalize line 133's wording — `runs all N checks (at
vX)` is a deliberate sentence and the parenthesized version is fine to gate as-is; only `40-locations.md`
needed the "items"→"checks" normalize to share the line-60 pattern.)

**F-3 instruction to Developer (README count pattern — do NOT widen the regex).** G.4's README count
check MUST stay anchored to the **parenthesized** `\(\d+ checks\)` form (matches only `README.md:159`).
It must **NOT** be loosened to a bare `\d+ checks` — that would match the historical Roadmap rows
(`README.md:258-268`) and the CHANGELOG `"30 checks"` / `"30→31 checks"` rows, which describe **past
releases** and must never be bumped (bumping them would falsify release history). Keep the parentheses
in the pattern. This same discipline applies to the `40-locations.md` `(N checks at vX)` form, which is
likewise parenthesized and version-anchored, so it cannot collide with bare historical rows.

**F-5 instruction to Developer (`.harness/scripts/baseline.json:10` — gate via SUBSTRING, not JSON parse).**
Live line 10 is `"verify_all_checks": 31,` — a machine-readable, **hand-maintained** count claim of the
same L14 drift class (evidence: CHANGELOG:120 `verify_all_checks 30 → 31`, CHANGELOG:260/:291 `unchanged
at 30` in patch releases — it is release-tracked). Confirmed by direct read of the file. Critically,
`verify_all.{ps1,sh}` do **NOT** read this field (grep `verify_all_checks` over both scripts: 0 hits) —
it is a pure hand-maintained drift surface, so after G.4 bumps the live count to 32 it would silently say
31. G.4 gates it with the **string substring** `"verify_all_checks": $count` (i.e. the literal
double-quoted-key + space + integer, no comma). **Do NOT `ConvertFrom-Json` / `jq`-parse it for this row**
— a raw substring `-match` / `grep -F` style compare is sufficient, symmetric across shells, and avoids
coupling G.4 to a JSON parser for one integer (the rest of baseline.json's keys are irrelevant to the
count claim and must not be touched). Same shape as the F-1/F-2 doc-claim rows. **L13 symmetry:** the
substring compare is implemented in BOTH `verify_all.ps1` (`-match '"verify_all_checks": '+$count`) and
`verify_all.sh` (`grep -F "\"verify_all_checks\": $count"`) in lockstep — no shell-specific construct.
  - **Long-term-maintainability sub-decision (SA recommendation): (a) gate+bump it like the other claims
    for THIS task — do NOT make it derived now.** Rationale: option (b) — having `verify_all` itself
    *write* `verify_all_checks` from the live `$report.Count` so the field becomes derived (self-healing,
    no hand-maintenance) — is genuinely the cleaner end-state, but it (i) makes `verify_all` *mutate a
    tracked file* on every run, which is a new side-effect class that needs its own design (idempotence,
    dirty-tree-in-CI, the `--check` vs write split) and (ii) expands THIS task's blast radius well beyond
    the bounded G.4 doc-sweep. So: **gate+bump now (option a); record option (b) as a documented follow-up
    only** (see §12 Out-of-scope / §9-R11). G.4 gating the field is itself the forcing function that makes
    the eventual derive-it refactor low-risk (any drift FAILs loudly in the meantime).

**F-7 instruction to Developer (`README.zh-CN.md:159` — the zh twin of README.md:159, gate via the
full-width-paren zh form).** Live line 159 is `` - `verify_all`（30 项检查）— 仓库本身健康度 `` — a LIVE,
TRACKED, **markdown** count claim that is the Chinese-locale twin of `README.md:159` and is **already one
release stale** (it reads `30`; the EN twin already reads `31`). It is the exact L14 drift class and was
missed by every prior sweep. G.4 must gate it with the **full-width-parenthesized** zh pattern
`（\d+ 项检查）` and expect `（$count 项检查）`. Like the EN `(N checks)` form, the parentheses are the
discriminator: the bare zh Roadmap rows (`README.zh-CN.md:260-270`, e.g. `verify_all 仍 30 项检查`,
`28 → 29`, `30 → 31 项`) describe **past releases** and must NOT be bumped — the full-width-paren
`（\d+ 项检查）` pattern matches only line 159 and never the bare roadmap rows (verified: roadmap rows use
no full-width parens around the count). Do NOT loosen this to a bare `\d+ 项检查`. Because line 159 is
currently `30` (not `31`), the one-time §5 edit takes it **straight to `32`** (skipping 31), reconciling
the stale value at the same time the count bumps. **L13 symmetry:** the full-width-paren match is identical
in PS (`-match '（'+$count+' 项检查）'`) and bash (`grep -E "（$count 项检查）"`) — the `（…）` are literal
UTF-8 characters in both shells; ensure both source files are saved UTF-8 (verify_all.{ps1,sh} already are).

**Output contract:** PASS if every doc contains the SOT-derived string; FAIL (throw in PS / `step
... FAIL` in bash) listing each doc whose claim ≠ derived value, e.g.
`AI-GUIDE.md: found '31 checks at v0.20.0', expected '32 checks at v0.20.0'`.

**Behavioral notes (per boundary conditions §4 of stage 1):**
- Missing/unparseable `plugin.json` → loud FAIL (mirror G.3, which already throws). Do not silently pass.
- A doc that does not contain the expected pattern at all → FAIL (not skip): the claim is required to exist.
- The check is **string-derived**, so a future version bump to `0.21.0` + a count change to 33 makes G.4
  expect `33 checks at v0.21.0` automatically; the release-cutter updates the docs to match, and G.4 is
  the forcing function (this is the recurrence kill).

## 5. The current-tree reconciliation (what the docs must say so G.4 passes on commit)

**Critical bootstrapping fact (read the real tree):** most consumer docs already say **`31 ... at
v0.20.0`** (synced in T-007), but the exhaustive sweep below found TWO that are already stale at `30`
(`README.zh-CN.md:159`) or `31`-as-JSON (`baseline.json:10`). The **complete, provably-exhaustive** set of
live BUMP+GATE count claims that move to **32** (all verified against the tree by the §5.1 sweep below) —
including the F-1/F-2 claims the gate review #0 found, the F-5 baseline.json claim review #1 found, and the
**F-7 `README.zh-CN.md:159` claim this round's own sweep found**:
- `AI-GUIDE.md:36` — `31/31 at v0.20.0`; `AI-GUIDE.md:69` — `31 checks at v0.20.0`
- `docs/dev-map.md:60` — `31 checks at v0.20.0`; `docs/dev-map.md:133` — `runs all 31 checks (at v0.20.0)`
- `.harness/rules/40-locations.md:25` — `(31 items at v0.20.0, all must PASS — ...)` **(F-1)**
- `README.md:5` — badge `verify__all-31%2F31`; `README.md:159` — `(31 checks)`
- `README.zh-CN.md:5` — badge `verify__all-31%2F31` **(F-2)**; `README.zh-CN.md:159` — `（30 项检查）` **(F-7, was stale at 30)**
- `docs/manual-e2e-test.md:3` — `verify_all at 31 checks at v0.20.0`
- `.harness/scripts/baseline.json:10` — `"verify_all_checks": 31` **(F-5)**

Adding G.4 makes the live count **32**. So on the commit that lands G.4, **every claim above must
become `32`** or G.4 fails its own gate (dogfood self-consistency, AC-7/L26 spirit). The version stays
`0.20.0` **unless this task is released as a new version** — that is the release-cutter's call, not this
design's (see Out-of-scope). The Developer's edit set for the current tree is therefore:

- `31/31 at v0.20.0` → `32/32 at v0.20.0` (AI-GUIDE.md:36)
- `31 checks at v0.20.0` → `32 checks at v0.20.0` (AI-GUIDE.md:69, dev-map.md:60, manual-e2e-test.md:3)
- `runs all 31 checks (at v0.20.0)` → `runs all 32 checks (at v0.20.0)` (dev-map.md:133)
- `(31 items at v0.20.0, all must PASS — ...)` → `(32 checks at v0.20.0, all must PASS — ...)`
  (`.harness/rules/40-locations.md:25`) — **two edits in one: bump 31→32 AND normalize "items"→"checks"**
  so the single G.4 `\(\d+ checks at v…\)` pattern covers this line. **(F-1)**
- badge `verify__all-31%2F31` → `verify__all-32%2F32` (README.md:5)
- `(31 checks)` → `(32 checks)` (README.md:159)
- badge `verify__all-31%2F31` → `verify__all-32%2F32` (README.zh-CN.md:5) **(F-2)**
- `（30 项检查）` → `（32 项检查）` (README.zh-CN.md:159) — **straight 30→32** (it was already one release
  stale at 30; this reconciles it AND bumps it in one edit). Keep the full-width parens `（…）`. **(F-7)**
- `"verify_all_checks": 31` → `"verify_all_checks": 32` (`.harness/scripts/baseline.json:10`) — JSON value
  edit; G.4 string-compares the substring, no parser. **(F-5)**
- CHANGELOG: a `[0.20.0]` heading already exists (T-007), so G.4's CHANGELOG sub-check passes today
  without edit. If the release-cutter bumps to `0.21.0`, they add `[0.21.0]` and re-run; G.4 enforces it.

### §5.1 EXHAUSTIVE LEDGER (provably-complete enumeration — every live representation of the count)

To make the "exhaustive" claim **defensible by construction** (and end the rollback loop), the SA ran an
own exhaustive Grep sweep over the live tree for EVERY representation of the check count and dispositioned
every hit. Searches run (case-insensitive where relevant): `verify_all_checks` · `%2F31` / `%2F32` ·
`31/31` · `31 checks` / `31 items` / `31 项` / `31 verify` / `项检查` / `个检查` / `检查项` ·
`\b31\b` (full word, near check/verify context) · `\b32\b` (catch any partially-bumped doc) · plus zh
prose `个 verify_all 检查` / `项检查`. Each hit below is dispositioned into exactly one class.

| # | file:line | exact live text (count token) | disposition |
|---|---|---|---|
| 1 | `AI-GUIDE.md:36` | `31/31 at v0.20.0` | **BUMP+GATE** → §4 row 1 |
| 2 | `AI-GUIDE.md:69` | `31 checks at v0.20.0` | **BUMP+GATE** → §4 row 2 |
| 3 | `docs/dev-map.md:60` | `(31 checks at v0.20.0)` | **BUMP+GATE** → §4 row 3 |
| 4 | `docs/dev-map.md:133` | `runs all 31 checks (at v0.20.0)` | **BUMP+GATE** → §4 row 4 |
| 5 | `.harness/rules/40-locations.md:25` | `(31 items at v0.20.0, all must PASS — ...)` | **BUMP+GATE** (+normalize items→checks) → §4 row 5 **(F-1)** |
| 6 | `README.md:5` | badge `verify__all-31%2F31` | **BUMP+GATE** → §4 row 6 |
| 7 | `README.zh-CN.md:5` | badge `verify__all-31%2F31` | **BUMP+GATE** → §4 row 7 **(F-2)** |
| 8 | `README.md:159` | `verify_all` `(31 checks)` | **BUMP+GATE** → §4 row 8 |
| 9 | `README.zh-CN.md:159` | `` `verify_all`（30 项检查）`` | **BUMP+GATE** (straight 30→32; was stale) → §4 row 9 **(F-7)** |
| 10 | `docs/manual-e2e-test.md:3` | `verify_all ... 31 checks at v0.20.0` | **BUMP+GATE** → §4 row 10 |
| 11 | `.harness/scripts/baseline.json:10` | `"verify_all_checks": 31` | **BUMP+GATE** (string substring) → §4 row 11 **(F-5)** |
| — | `docs/system-overview.html:230` | `31 verify checks` | **HTML-exempt** (untracked, dated snapshot — badge reads `v0.18.2`) **(F-6)** |
| — | `docs/system-overview.html:288` | `31 个 verify_all 检查项（A–J 分类）` | **HTML-exempt** (same file, same snapshot) **(F-6)** |
| — | `docs/system-overview.html:584` | `v0.18.2 的 31 个检查分类（节选）` | **HTML-exempt** (same file; literally version-stamped v0.18.2) **(F-6)** |
| — | `docs/system-overview.html:691` | `31 项检查全 PASS` | **HTML-exempt** (same file, same snapshot) **(F-6)** |
| — | `docs/walkthrough.html:717` | `31 checks: 31 PASS, 0 WARN, 0 FAIL` | **HTML-exempt** (I.6-exempt dated HTML snapshot) **(F-4 precedent)** |
| — | `architecture.html:326` | `30 个 verify_all 检查` | **HTML-exempt** (tracked but explicitly dated `v0.17.4`; not even at current count) |
| — | `architecture.html:502` | `19 项检查（v0.1 是 15）` | **HTML-exempt** (tracked, dated `v0.5/v0.6` snapshot; historical) |
| — | `README.md:258-268` | `stays 30 checks` / `28 → 29` / `30 → 31 checks` / `stays 31 checks` | **historical-Roadmap-exempt** (past releases; BARE form, not parenthesized → §4 pattern can't match) |
| — | `README.zh-CN.md:260-270` | `仍 30 项检查` / `28 → 29` / `30 → 31 项` | **historical-Roadmap-exempt** (zh, past releases; BARE form, no full-width parens → §4 pattern can't match) |
| — | `CHANGELOG.md:37,71,118,120,126,260,291` | `stays at 31` / `30 → 31` / `unchanged at 30` / `30/30 → 31/31` | **historical-CHANGELOG-exempt** (each row describes a past release) |
| — | `MIGRATION.md:231` | `verify_all now has 29 checks (...)` | **historical-migration-narrative-exempt** ("After (v0.2)" column; frozen at the migration moment, never maintained forward; parens hold a check-LIST, not a count) |
| — | `docs/manual-e2e-test.md:3` | `57 assertions / 53` | **test-supervisor-self-tally** (NOT a verify_all count; corrected under §9-R6 by a different rule, NOT gated by G.4) |
| — | `.harness/scripts/baseline.json:13,14` | `test_supervisor_ps_assertions: 57` / `_bash...: 53` | **test-supervisor-self-tally** (R6 territory; not the verify_all count) |
| — | `skills/.../i18n/zh/common/docs/workflow.md:96` | `verify_all 加一项检查` | **not-a-count** ("add one check" instruction in a template, no number) |
| — | `evals/golden-tasks.md:41`, `docs/walkthrough.html:637-638`, `skills/harness-status/SKILL.md:54` | `~32 assertions` / `controller:31,32` / `14:32:11Z` | **not-a-count** (eval assertions / source-line refs / a timestamp — unrelated to the verify_all check count) |

**Exhaustive-ledger summary: 11 BUMP+GATE lines (8 files) + every other live hit dispositioned into one of
five exempt classes = the complete live set.** The 11 BUMP+GATE lines are **1:1 with the 11 §4 G.4
validation rows** (count #1–#10 doc rows + the baseline.json substring row; the CHANGELOG `[version]`
heading row is a presence-check, not a count claim, so it has no ledger row). All 11 move to **32** in this
one commit. Every remaining grep hit across all the sweep patterns appears in the exempt block above
(HTML, historical-Roadmap/CHANGELOG/migration, test-supervisor-self-tally, not-a-count), and `_archived/**`
+ this task's own `docs/features/test-supervisor-stamps/**` were filtered out as non-live narrative. No live
verify_all count claim is left ungated.

**Exclusion-rule statement (why each exempt class is provably safe to skip):**
- **HTML-exempt** — `*.html` files are dated visual snapshots: every one carries its own version badge/banner
  (`v0.18.2`, `v0.17.4`, `v0.5/v0.6`) and is regenerated wholesale, not line-edited; G.4 never reads HTML
  (consistent with the I.6 HTML exemption and the F-4 walkthrough.html precedent). `system-overview.html`
  is additionally **untracked** (`?? docs/system-overview.html`). Gating these would mean re-rendering a
  whole snapshot every count bump — wrong tool for the job.
- **historical-Roadmap/CHANGELOG/migration-exempt** — these rows describe the state **of a past release**
  (`stays 30 checks`, `30 → 31`, `now has 29 checks`); bumping them would **falsify release history**. They
  are discriminated mechanically from the live claims by form: live claims are **parenthesized + (for the
  doc-table claims) version-anchored** (`(N checks)`, `（N 项检查）`, `(N checks at vX)`); historical rows
  are **bare** (`stays N checks`, `仍 N 项检查`). G.4's parenthesized patterns match only the live lines.
- **`_archived/**`-exempt** — everything under `docs/features/_archived/**` (and the active task's own
  `docs/features/test-supervisor-stamps/**`) is delivery-record narrative of past tasks; never a live claim,
  never gated (the sweep filtered these out; the only in-scope `docs/features/**` hits are this design's own).
- **test-supervisor-self-tally** — `57/53` (and the matching `baseline.json` `test_supervisor_*` keys) are
  test-supervisor's **assertion** count, a different metric; this task *does* invalidate them (§9-R6) but
  they are fixed by a recount, not by G.4's verify_all-count gate.
- **not-a-count** — hits where `31`/`32` is a timestamp, a source-line reference, an eval assertion count,
  or the word "check" with no number; no count claim, nothing to gate.

(`manual-e2e-test.md:3`'s *separate* `57/53` test-supervisor **self-tally** is corrected under §9-R6 by a
different rule and is NOT gated by G.4.) After this edit, **no live verify_all count claim is left ungated**
— the F-1/F-2/F-5/F-7 silent-drift gaps every review round surfaced are all closed, and the exempt classes
are stated as rules, not as a case-by-case list.

> Note this is exactly the manual fan-out that L14 warned about — but now it is a **one-time** sync
> performed *because a new gated check forces it*, after which the gate (not a human) guards it forever.
> This is the intended end-state: the count claim has a forcing function.

**verify_all's own banner/comments:** `verify_all.ps1:69` / `.sh:56` enumerate 11 skills, not counts;
no version/count literal lives inside verify_all itself, so no self-exemption is needed beyond the
count derivation. The **manual-e2e-test.md** line also states `test-supervisor.ps1 at 57 assertions /
.sh at 53` — those are **out of scope** (they are test-supervisor's own assertion tally, not the
verify_all count; G.4 does not touch them, and removing 8 asserts will change them — see §8 Risk R6).

## 6. Ordering / bootstrapping (self-reference safety)

The hazard: G.4 counts checks, and G.4 is itself a check. Off-by-one is the classic trap.

**Safe sequence (both shells):**
1. G.4 is added as the **last** `Step`/`step` in the file, immediately **before** the `# Summary` block
   (PS: insert before line 623 `# Summary`; bash: before line 656 `# Summary`). Placing it last means
   every other check has already appended its record.
2. Inside G.4's body, the recorded-steps array holds the **31 prior** checks. G.4 has **not yet**
   appended its own record (PS appends in the `Step` wrapper *after* the action returns; bash appends in
   `step` *after* the inline branch runs). So at body-execution time:
   - PS: `$report.Count` = 31 → expected count = `$report.Count + 1` = **32** (the `+1` is G.4 itself).
   - bash: `${#report[@]}` = 31 → expected = `${#report[@]} + 1` = **32**.
3. This makes the derived count **status-independent** (WARN on I.1–I.5 does not change it) and
   **self-inclusive-correct** (the `+1` accounts for G.4 without double-counting, because G.4's own
   record is appended only after its body returns).
4. **Verification of the +1:** after the full run, the Summary's PASS tally will be 32 (all green) and
   `$report.Count` will be 32. G.4's body saw 31 and added 1 → 32. Consistent. If a future check is added
   *after* G.4 (do not do this — keep G.4 last), the `+1` would undercount.

**CONDITION — pin-comment (BINDING, both shells).** Because the `+1` self-reference is correct **only
while G.4 is the final Step/step**, the Developer MUST place an explicit pin-comment immediately above
G.4 in **both** `verify_all.ps1` and `verify_all.sh` (L13 symmetry) stating the invariant verbatim, e.g.:

```
# G.4 MUST remain the LAST check. Its count is derived as `$report.Count + 1`
# (PS) / `${#report[@]} + 1` (sh), where the `+1` is G.4 itself. Adding ANY
# check after G.4 makes that derivation undercount — insert new checks ABOVE this.
```

This is a binding condition, not a suggestion: GR flagged it as a "latent trap for the next contributor"
and made it a verdict CONDITION. The pin-comment ships in the same commit as G.4.

**Optional Summary tripwire (RECOMMENDED — include it).** As cheap belt-and-suspenders, the Developer
SHOULD add a one-line assertion in the Summary block that the count G.4 derived equals the final recorded
count — PS: `$report.Count` (which is 32 after G.4 appends) vs G.4's derived value; sh: `${#report[@]}`
vs the derived value. If they diverge, a check was added after G.4 and the build should FAIL loudly rather
than silently miscount. Recommendation: **include it** — it is ~2 lines/shell, no subprocess, and converts
the "keep G.4 last" convention from a comment-only honour-system into a mechanical guard that catches the
exact regression the pin-comment warns about. (The pin-comment remains mandatory regardless; the tripwire
is the mechanical backstop the GR suggested.)

**Alternative considered and rejected:** computing the count from the Summary's `$pass` after the loop
would require G.4 to run *after* the count is known, i.e. in the Summary block, which is not a `Step` and
would not itself be counted — reintroducing an off-by-one and a non-gated code path. The `report.Count +
1` from inside the last Step is the clean invariant.

## 7. Sequence / flow

```
verify_all run
  ├─ A.1 ... J.1            (31 checks, each appends to $report / report[])
  └─ G.4 (NEW, last Step)
        ├─ version  ← plugin.json.version            (reuse extract_json_version in bash)
        ├─ count    ← $report.Count + 1  /  ${#report[@]} + 1   (= 32)
        ├─ for each doc claim:
        │     expected = build string from (count, version)
        │     if doc !contains expected → collect failure
        ├─ CHANGELOG: assert "[<version>]" heading exists
        └─ PASS if no failures else FAIL(list)
  └─ Summary: PASS=32  (G.4 record now appended)

test-supervisor run (unchanged structurally)
  ├─ AC-1 ... F-4          (all supervisor-contract asserts, untouched)
  └─ Doc fan-out block: now ONLY #1 (auxiliary phrasing), #10 (harness-status row),
                        #11 (canonical-7 glob) — zero version/count literals
```

## 8. Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| Read version from SOT (bash) | `extract_json_version()` | `.harness/scripts/verify_all.sh:354-358` | **Reuse as-is** in G.4 |
| Read version from SOT (PS) | `ConvertFrom-Json` of plugin.json | `verify_all.ps1:334` (G.3) | **Reuse pattern** |
| Step/FAIL idiom + record append | `Step` / `step` wrappers | `verify_all.ps1:19-37`, `verify_all.sh:17-25` | **Reuse** — G.4 is a normal Step |
| Live check count | `$pass` / `$pass_count` derive-from-`$report` | `verify_all.ps1:626`, `verify_all.sh:659` | Pattern reused, but G.4 uses `$report.Count`/`${#report[@]}` (status-independent) |
| Throw-with-detail on mismatch | G.3 mismatch `throw`/`step FAIL` | `verify_all.ps1:351-354`, `verify_all.sh:370-373` | **Reuse phrasing** for FAIL detail |
| Removing asserts cleanly | the 3 kept category-(c) asserts | `test-supervisor.ps1:416-418,445-451` / `.sh:377-379,404-409` | Keep verbatim; delete the 8 between/around them |
| Case-sensitive contract regex | `-cmatch` discipline | insight L20, `verify_all.ps1:440` | N/A for G.4 (version/count are not fixed-case-sensitive tokens), but PS string ops here are plain `-match`/substring — no case contract |

Reuse audit is non-empty and confirms G.4 is an extension of existing G.3 machinery, not a new subsystem.

## 9. Risk analysis

| # | Risk | Mitigation |
|---|---|---|
| R1 | A removed assert was the *only* coverage of something (CHANGELOG current-version entry #4, count claims #2/#3/#9). | G.4 explicitly reconstitutes both: CHANGELOG `[<version>]` heading sub-check + the count-claim validation. Verified by the Q1 disposition table mapping every removed assert to a new owner. |
| R2 | G.4 double-counts or off-by-ones the check total (self-reference). | §6: G.4 is the **last** Step; derive `$report.Count + 1` from inside the body where its own record is not yet appended. Developer comment pins "G.4 must stay last". QA simulates (§10) and confirms 32. |
| R3 | PS/Bash asymmetry — G.4 computes a different count or validates different docs in one shell. | Both shells validate the **same doc-claim table** (§4) from the **same two sources**; bash reuses `extract_json_version`. AC-2/L13 symmetry: Developer edits both in lockstep; QA runs both and diffs the count. |
| R4 | Deriving from PASS count (not step count) makes G.4 flicker to 31 on a WARN-only doc-size check. | §3/§6: derive from `$report.Count`/`${#report[@]}` (recorded steps, status-independent), **not** `$pass`/`pass_count`. Explicitly chosen for this reason. |
| R5 | The one-time doc sync (31→32) is itself forgotten, so G.4 FAILs on first run. | §5 gives the exact edit list with file:line. This is the *intended* forcing-function behavior — if the dev forgets, the gate catches it immediately (proves G.4 is load-bearing, AC-6). |
| R6 | Removing 8 test-supervisor asserts changes its own assertion tally (manual-e2e-test.md:3 says `57/53`), creating a *new* stale claim. | Out-of-scope §4.4 of stage 1 says do not re-fix consumer-doc tallies beyond what the mechanism reads — but a tally that this task *makes wrong* must be corrected to avoid creating drift. Developer updates manual-e2e-test.md's `57 assertions / 53` to the post-removal tally (PS removes 8 → 49; bash removes 8 → 45) **as measured by an actual run** (insight L32 — paste from a captured run, never guess). This is a doc-text edit, not a new gate. |
| R7 | Gate latency grows. | G.4 does only file reads + string compares, no subprocess (unlike "wire in test-supervisor"). Negligible (~5 file reads), comparable to G.2/G.3. |
| R8 | A README badge uses URL-encoded `%2F` and `verify__all` (double underscore) — a naive pattern misses it. | §4 expected string uses the exact shields.io encoding `verify__all-$count%2F$count` (confirmed from `README.md:5` AND `README.zh-CN.md:5`). Developer must match the literal badge token, not a `/`-form, in **both** README files. |
| R9 | Live count claims outside the originally-listed set stay stale after the bump and silently drift (the exact L14 class this task kills) — successive GR rounds found `40-locations.md:25` ("31 items"), `README.zh-CN.md:5` (`verify__all-31%2F31`), `baseline.json:10` (`"verify_all_checks": 31`), and the SA's own §5.1 sweep found `README.zh-CN.md:159` (`（30 项检查）`, already stale at 30) ungated. | All four are now (a) in the §5 one-time edit set, (b) in the §4 G.4 validation table 1:1, so G.4 FAILs if any drifts. The **§5.1 EXHAUSTIVE LEDGER** is the closing move: the SA ran an own provably-complete Grep sweep (`verify_all_checks`, `%2F31/32`, `31/31`, `31 checks/items/项/verify`, `项检查`, `\b31\b`, `\b32\b`) and dispositioned **every** hit into BUMP+GATE (11) or one of five exempt classes (HTML / historical-Roadmap-CHANGELOG-migration / `_archived` / test-supervisor-self-tally / not-a-count), with the exclusion rule stated for each class. G.4's 11 count rows are 1:1 with the 11 BUMP+GATE lines. No live verify_all count claim is left ungated. |
| R11 | **Residual limitation (honest):** G.4 gates a **FIXED enumerated list** of files/patterns. A count claim added to a **NEW file in the future** (e.g. a new doc that says "32 checks") would NOT be auto-gated — G.4 doesn't discover claims, it validates known ones. | Accepted residual, with a real mitigation: G.4 **FAILs whenever the live count changes** (the next time a check is added, every one of the 11 enumerated claims is forced to 33 in the same commit, and the developer/GR is doing a count-claim sweep *anyway* at that moment). That forced re-sweep is the discovery mechanism for any new claim site. The class is converted from "silently rots for 5 releases" (the original L14 hole) to "re-audited on every count change". A heavier alternative (G.4 greps the whole tree for `\bN checks\b` and asserts all equal the live count) was considered and rejected for THIS task: it would FAIL on every historical Roadmap/CHANGELOG row and need a large exclusion list — higher maintenance than the enumerated list, and out of this bounded task's scope. Recorded as a follow-up option in §12. |
| R12 | `baseline.json.verify_all_checks` stays hand-maintained → it can drift again at the next count bump (only the gate, not derivation, protects it). | This round gates+bumps it (F-5 option a), which catches drift loudly. The cleaner end-state (option b: `verify_all` *writes* the field from `$report.Count`, making it derived) is recorded as a **documented follow-up** in §12 — deliberately NOT implemented here to keep this task bounded and avoid giving `verify_all` a tracked-file write side-effect without its own design. G.4 gating the field de-risks that future refactor (drift FAILs in the interim). |
| R10 | G.4's README/40-locations count regex is widened to a bare `\d+ checks` and starts matching historical Roadmap/CHANGELOG "30→31 checks" rows, which describe past releases and must never be bumped (would falsify history). | §4 F-3 instruction: keep the pattern anchored to the **parenthesized** `\(\d+ checks\)` (README) / version-anchored `\(\d+ checks at v…\)` (40-locations) form. Those forms match only README.md:159 + 40-locations.md:25, never bare roadmap rows. Developer must NOT loosen the regex. |

## 10. Test strategy for QA (adversarial proof the drift class is dead)

QA must demonstrate **both** directions:

1. **AC-1/AC-2 (green now):** run `test-supervisor.ps1` and `.sh` → `FAIL: 0` at v0.20.0; the fan-out
   block contains only the 3 structural asserts; grep both files for `0\.17\.1`, `0\.20\.0`, and a bare
   count literal in the fan-out region → **zero hits** (AC-3).
2. **AC-5 (gate green at new count):** run `verify_all.ps1` and `.sh` → `32/32` PASS both shells; confirm
   G.4 PASSes and the Summary reads 32.
3. **AC-4/AC-6 forward-drift simulation (the key adversarial test):** in a throwaway working copy (or a
   temp fixture), bump `plugin.json.version` `0.20.0 → 0.21.0` **without editing test-supervisor**. Assert:
   (a) `test-supervisor` still `FAIL: 0` (it no longer references the version, proving no test edit needed);
   (b) `verify_all` G.4 now **FAILs** because the docs still say `v0.20.0` — proving the gate *catches*
   the drift that previously rotted silently. Then update the docs to `0.21.0` and re-run → G.4 PASS.
   Revert the fixture.
4. **Count-drift catch (must cover EVERY formerly-ungated file F-1/F-2/F-5/F-7):** deliberately edit one
   doc claim (`32 checks` → `31 checks` in dev-map.md) and run `verify_all` → G.4 **FAILs** naming that
   doc. Revert. Then repeat the same single-claim-revert probe for EACH of:
   - **`40-locations.md:25`** (`32 checks`→`31 checks`) **(F-1)**
   - **`README.zh-CN.md:5`** (`verify__all-32%2F32`→`...-31%2F31`) **(F-2)**
   - **`.harness/scripts/baseline.json:10`** (`"verify_all_checks": 32`→`"...": 31`) **(F-5 — proves the
     string-substring gate works on JSON without a parser)**
   - **`README.zh-CN.md:159`** (`（32 项检查）`→`（31 项检查）`) **(F-7 — proves the full-width-paren zh
     pattern gates and does NOT also FAIL on the bare zh roadmap rows)**

   G.4 must FAIL on each, proving every formerly-ungated claim is now gated. This, plus probing one of the
   already-gated lines, proves **all 11 count claims in the §5.1 EXHAUSTIVE LEDGER are gated 1:1**. As a
   negative control, QA should also confirm that editing a HISTORICAL row (e.g. README.md:260 `stays 30
   checks` → `stays 99 checks`, or README.zh-CN.md:262 `仍 30 项检查`) does **NOT** make G.4 FAIL — proving
   the parenthesized patterns correctly exclude historical rows (the F-3/F-7 discriminator).
5. **Self-reference correctness:** confirm G.4's derived count (32) equals the Summary PASS count (32)
   in a fully-green run — the `+1` is correct, not off-by-one (R2/R4).
6. **Boundary:** temporarily rename `plugin.json` → run `verify_all` → G.4 FAILs loudly (not silent pass),
   satisfying §4.1/§4.3. Restore.

QA captures real run output for every tally it reports (insight L32).

## 11. Migration / rollout plan

- **Backwards compatibility:** no public API; this is internal tooling. No feature flag.
- **Sequence (single commit, single Developer):**
  1. Edit `verify_all.ps1` + `verify_all.sh`: add G.4 as the last Step (before Summary), with the
     binding pin-comment above it and the recommended Summary tripwire (§6 CONDITION).
  2. Edit the **8 files / 11 count-claim lines** per §5's exhaustive ledger: AI-GUIDE.md (×2），
     dev-map.md (×2), `40-locations.md:25` (bump 31→32 **and** normalize "items"→"checks"),
     README.md (badge + `(N checks)`), README.zh-CN.md (badge + `（N 项检查）` line 159, the latter a
     straight **30→32**), manual-e2e-test.md:3, and `.harness/scripts/baseline.json:10`
     (`"verify_all_checks"` JSON value) — all to `32`.
  3. Edit `test-supervisor.ps1` + `.sh`: remove the 8 asserts, keep the 3.
  4. Edit `manual-e2e-test.md`: correct the test-supervisor tally (R6) from a captured run.
  5. Run both `verify_all` shells → must be `32/32`; run both `test-supervisor` shells → `FAIL: 0`.
- **Rollback:** revert the commit; the docs return to `31` and the gate to `31/31`. No data migration.
- **Template sync:** verify_all and test-supervisor are dogfood-only scripts (not in
  `skills/harness-init/templates/`), so no template twin to sync (per insight L12 — sync-self does not
  cover these). Confirm via `sync-self --check` staying clean (test-supervisor AC-2.3 already asserts it).

## 12. Out-of-scope clarifications

- Not re-deriving the **version** in test-supervisor (Option B): rejected — the version belongs to G.3/G.4
  at the gate, not the supervisor regression.
- Not wiring test-supervisor into verify_all (Q2 option i): rejected on latency/coupling.
- Not bumping the repo to a new release version — `plugin.json` stays `0.20.0`; if a release is cut, the
  cutter bumps it and G.4 forces the doc fan-out. CHANGELOG `[0.20.0]` already exists.
- Not touching test-supervisor's non-version asserts (AC-1..AC-7, BUG-1/2, F-4, I.7-emu).
- Not re-fixing unrelated consumer-doc tallies (test-init counts, integration badge) except the
  test-supervisor self-tally that *this* task invalidates (R6).
- **FOLLOW-UP (documented, NOT in this task) — derive `baseline.json.verify_all_checks`.** The cleaner
  long-term fix is to have `verify_all` itself *write* `verify_all_checks` from the live `$report.Count`
  (option b in §4 F-5), making the field derived and eliminating the hand-maintenance entirely. Deferred
  because it gives `verify_all` a tracked-file write side-effect that needs its own design (idempotence,
  `--check` vs write mode, dirty-tree-in-CI). This task gates+bumps the field (option a) so any drift FAILs
  loudly meanwhile; the eventual refactor is then low-risk. (See §9-R12.)
- **FOLLOW-UP (documented, NOT in this task) — auto-discover NEW count-claim sites.** G.4 gates a fixed
  enumerated list; a count claim added to a *new* file in the future isn't auto-gated until the next
  count-change sweep catches it (§9-R11). A whole-tree `\bN checks\b` discovery scan with a historical-row
  exclusion list could close this, but is rejected here as higher-maintenance and out of scope.

## 13. Partition assignment

`.harness/agents/dev-*.md` glob → **no files found**. The project is in **single-Developer mode**;
the Partition assignment table is omitted per the contract. One Developer owns all edits in §11's
single-commit sequence (dogfood scripts + docs, no frontend/backend/db split).

## 14. Verdict

**READY.** All three deferred decisions (Q1 remove-the-duplicators / Q2 new gated G.4 meta-check / Q3
count derived from the live recorded-step tally) are resolved with rationale grounded in the real files.
The design eliminates the drift class (test-supervisor holds zero release-tracking literals) and installs
a standing forcing function (G.4) so the count/version doc claims can never silently rot again. No
upstream gap; no new dependency. Developer can implement without further design decisions.

---

DESIGN COMPLETE — approach: remove the 8 stamp/count asserts from test-supervisor (keep the 3 structural ones), relocate count-claim + CHANGELOG-entry coverage into a new standing `verify_all` G.4 meta-check that derives version from plugin.json and count from the live recorded-step tally (`$report.Count + 1`), one-time-syncing the **8 files / 11 count-claim lines** to 32 (incl. `40-locations.md:25`, `README.zh-CN.md:5`, `README.zh-CN.md:159`, and `.harness/scripts/baseline.json:10`) so the new gate passes and guards forever. §5.1 carries the provably-exhaustive ledger: 11 BUMP+GATE lines (1:1 with §4) + every other live hit dispositioned into five stated exclusion classes.

REWORK NOTE (rollback #1, GR CHANGES REQUIRED): G.4 mechanism CONFIRMED sound — unchanged. Bounded doc-gap fixes applied: (F-1) added `40-locations.md:25` to §4 G.4 table + §5 edit list, normalizing "31 items"→"32 checks" so one parenthesized G.4 pattern covers it; (F-2) added `README.zh-CN.md:5` count badge to both (G.3 covers only its *version* badge); (F-3) stated the Developer instruction to keep G.4's README/40-locations count regex anchored to the parenthesized `(N checks)` form so it never matches historical Roadmap/CHANGELOG rows; (CONDITION) added the binding "G.4 must stay last" pin-comment requirement for both shells plus the recommended Summary tripwire. §5 ledger and §4 table now match 1:1 — no live count claim left ungated.

REWORK NOTE (rollback #2, GR CHANGES REQUIRED (1) — exhaustiveness re-scan): G.4 mechanism CONFIRMED sound — unchanged. **Convergence move:** the SA ran its OWN provably-exhaustive Grep sweep over live tracked files (`verify_all_checks`, `%2F31/32`, `31/31`, `31 checks/items/项/verify`, `项检查`, `\b31\b`, `\b32\b`) and built the **§5.1 EXHAUSTIVE LEDGER** dispositioning every hit. Fixes applied: (F-5) added `.harness/scripts/baseline.json:10` `"verify_all_checks": 31` to §4 (string-substring gate, NO JSON parse — confirmed by reading the file) + §5 edit list; recommended option (a) gate+bump now, with derive-it (option b) as a documented §12 follow-up. (F-6) recorded ALL FOUR `docs/system-overview.html` count lines (230/288/584/691 — not just the two the GR cited) as HTML+untracked+stale-snapshot (badge `v0.18.2`), excluded from G.4 per the F-4 walkthrough.html precedent. (F-7, SA-found) the own sweep additionally caught `README.zh-CN.md:159` `（30 项检查）` — a live TRACKED markdown count claim, the zh twin of `README.md:159`, already one release STALE at 30 and missed by every prior round; added to §4 + §5 (straight 30→32) with a full-width-paren `（\d+ 项检查）` pattern that excludes the bare zh roadmap rows. Ledger is now **11 BUMP+GATE lines (8 files) ↔ 11 §4 G.4 rows, 1:1**, plus every other live hit dispositioned into five stated exclusion classes (HTML / historical-Roadmap-CHANGELOG-migration / `_archived` / test-supervisor-self-tally / not-a-count). Residual limitation (fixed-list gating, not auto-discovery) stated honestly in §9-R11 with the count-change-forces-resweep mitigation.

DESIGN RISK: the new G.4 raises the live check count to 32, which requires a one-time fan-out edit of **8 files / 11 count-claim lines** (to 32) in the SAME commit — AI-GUIDE.md(×2), dev-map.md(×2), 40-locations.md:25, README.md(×2 = badge+`(N checks)`), README.zh-CN.md(×2 = badge:5 + `（N 项检查）`:159, the latter a straight 30→32), manual-e2e-test.md:3, and `.harness/scripts/baseline.json:10` (§5.1 EXHAUSTIVE LEDGER, now including the F-1/F-2/F-5 files prior reviews found AND the F-7 `README.zh-CN.md:159` the SA's own exhaustive sweep found). If the Developer lands G.4 without all of them, verify_all FAILs on its own gate (intended forcing-function behavior, but flag it so GR/QA expect the coupled edit). See §5/§9-R5,R9. RESIDUAL (R11): G.4 gates a fixed enumerated list, so a count claim in a future NEW file isn't auto-gated until the next count-change forces a re-sweep — stated honestly; whole-tree discovery is a §12 follow-up.

DESIGN RISK: G.4's count derivation is self-referential — it MUST remain the final Step and derive `$report.Count + 1` (recorded-step count, not PASS count) in BOTH shells; an off-by-one or a PASS-count derivation would make the gate flicker or miscount. The §6 CONDITION (binding pin-comment in both shells + recommended Summary tripwire `$report.Count` vs derived value) guards "G.4 stays last". See §3/§6/§9-R2,R4.

DESIGN RISK: removing 8 test-supervisor asserts invalidates the `57 assertions / 53` self-tally in `docs/manual-e2e-test.md:3`; the Developer must correct it from a captured run (insight L32), or a new stale claim is created. See §9-R6.

Doc path: c:\Programs\HarnessEngineering\docs\features\test-supervisor-stamps\02_SOLUTION_DESIGN.md
