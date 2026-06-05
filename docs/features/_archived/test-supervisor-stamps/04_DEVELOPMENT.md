# Development Record — test-supervisor-stamps (T-008)

## Summary
Removed the 8 hard-coded version/count fan-out asserts from `test-supervisor.{ps1,sh}`
(keeping the 3 version-agnostic structural asserts), added a new standing `verify_all`
G.4 meta-check (both shells) that derives the version from `plugin.json` and the check
count from the live recorded-step tally and validates all 11 doc count claims + the
current-version CHANGELOG heading, and one-time-bumped all 11 count claims to **32** in
lockstep so G.4 passes on first run. test-supervisor now carries zero release-tracking
literals; the count/version doc-drift class is killed at the gate.

## Files changed
- `.harness/scripts/test-supervisor.ps1` — removed the 8 version/count fan-out asserts
  (#2/#3 AI-GUIDE `30/30`+`30 checks at v0.17.1`, #4 CHANGELOG `[0.17.1]`, #5/#6 README+zh
  `version-0.17.1-` badges, #7 plugin.json, #8 marketplace.json, #9 dev-map `30 checks`),
  replaced with an explanatory note; kept #1 (`auxiliary.*supervisor`), #10
  (`upervisor.*auxiliary` row), #11 (canonical-7 glob `{pm,req,sol,gate,dev,review,qa}*`).
- `.harness/scripts/test-supervisor.sh` — same 8 removed / 3 kept (matched by assert TEXT;
  the `.sh` numbering + plugin/marketplace transposition handled by text-match per §4 note).
- `.harness/scripts/verify_all.ps1` — added Step `G.4` immediately before the Summary block
  (now at ~ps1:632, the LAST Step), with the binding pin-comment above it and a Summary
  tripwire (`$report[-1].id -ne "G.4"` → FAIL) below `$pass`. Reuses G.3's `ConvertFrom-Json`
  version read; count = `$report.Count + 1` (status-independent).
- `.harness/scripts/verify_all.sh` — symmetric `step "G.4"` before the Summary block (LAST
  step), same pin-comment + Summary tripwire (`${g4_last%%|*} != G.4`). Reuses
  `extract_json_version` (sh:354-358); count = `${#report[@]} + 1`.
- `AI-GUIDE.md` — :36 `31/31 at v0.20.0`→`32/32`; :69 `31 checks at v0.20.0`→`32 checks`.
- `docs/dev-map.md` — :60 `(31 checks at v0.20.0)`→`32`; :133 `runs all 31 checks (at v0.20.0)`→`32`.
- `.harness/rules/40-locations.md` — :25 `(31 items at v0.20.0...)`→`(32 checks at v0.20.0...)`
  (bump 31→32 AND normalize "items"→"checks" in one edit, per F-1).
- `README.md` — :5 badge `verify__all-31%2F31`→`32%2F32`; :159 `(31 checks)`→`(32 checks)`.
- `README.zh-CN.md` — :5 badge `verify__all-31%2F31`→`32%2F32`; :159 `（30 项检查）`→`（32 项检查）`
  (straight 30→32, reconciling the one-release staleness, per F-7).
- `docs/manual-e2e-test.md` — :3 `verify_all at 31 checks at v0.20.0`→`32 checks` AND the
  test-supervisor self-tally `57 assertions / 53`→`49 / 45` (R6 recount from a real run).
- `.harness/scripts/baseline.json` — :10 `"verify_all_checks": 31`→`32` (F-5, string-gated by
  G.4, no JSON parse); :13/:14 `test_supervisor_*` `57/53`→`49/45` (R6 self-tally, machine twin
  of manual-e2e-test:3 — no script reads these keys; kept consistent so they don't drift).

The 11 BUMP+GATE count claims (§5.1 ledger) are: AI-GUIDE×2, dev-map×2, 40-locations:25,
README badge+`(N checks)`, README.zh badge+`（N 项检查）`, manual-e2e-test:3, baseline.json:10.
All now read 32, 1:1 with the 11 G.4 validation rows.

## verify_all result
- Baseline: **PS 31/31 PASS · 0 WARN · 0 FAIL** · **SH 31 checks: 30 PASS · 1 WARN (I.4) · 0 FAIL**
  (the I.4 WARN is a PRE-EXISTING cross-shell discrepancy — PS `Measure-Object -Line` counts
  insight-index.md as 30, bash `wc -l` as 33; present identically before this task, unrelated).
- After changes: **PS 32/32 PASS · 0 WARN · 0 FAIL · RC 0** · **SH 32 checks: 31 PASS · 1 WARN
  (same pre-existing I.4) · 0 FAIL**. G.4 is the LAST check and PASSes in both; tripwire silent.
- Delta: **0 new failures, 0 new WARNs.** Baseline preserved + 1 new gated check (G.4) added,
  raising the standing count 31→32. The status-independent count derivation is proven by the
  bash run: 31 PASS + 1 WARN = 32 checks, and G.4 still derived 32 (recorded-step count, not the
  PASS count of 31) and validated every doc against 32 — exactly the R4 anti-flicker behavior.

## test-supervisor result
- Baseline: **PS 50 PASS / 7 FAIL · SH 46 PASS / 7 FAIL** — the 7 failing asserts were the stale
  `v0.17.1`/`30` fan-out asserts (repo is at v0.20.0/31), which empirically confirmed the task
  premise: those literals had already drifted to RED. (The 8th removed assert, CHANGELOG
  `[0.17.1]`, still PASSed since that historical entry exists.)
- After removing 8 (7 failing + 1 passing): **PS 49 PASS / 0 FAIL (RC 0) · SH 45 PASS / 0 FAIL** —
  both green. These are the REAL captured tallies (matching the design's 49/45 sanity), now
  written into `manual-e2e-test.md:3` and `baseline.json:13,14`.

## Design drift (if any)
None to the mechanism. Two scope-consistent decisions, flagged for the reviewer:
- **baseline.json:13,14 self-tally also updated (57/53→49/45).** §9-R6 explicitly mandates
  correcting the manual-e2e-test:3 self-tally a removal invalidates; the design's §5.1 ledger
  classes baseline.json:13,14 as the same "test-supervisor-self-tally" metric. Removing 8 asserts
  staled BOTH the prose copy and its machine twin, so I corrected both for consistency. No script
  asserts these keys (grep: 0 hits in any `.ps1`/`.sh`), so this cannot break a gate. Not a
  mechanism change; flagged as a minor in-scope extension of R6.
- **PS/SH I.4 WARN discrepancy left untouched** (pre-existing, out of scope; insight-index.md is
  not a T-008 file and the design does not mention trimming it).

## Open issues for review
- The bash `verify_all.sh` takes ~3-4 min in this Git-for-Windows MSYS environment, dominated by
  the I.6 retired-claim grep loop (per insight L27/L28 MSYS grep is slow). G.4 itself adds only
  ~11 file reads + string compares (negligible, ~G.3-class), confirmed not the bottleneck. Not a
  defect — just slow to run; both shells complete with RC reflecting only the pre-existing I.4 WARN.

## Dev-map updates
No new files/modules added (G.4 is a new check inside an existing script). `docs/dev-map.md`'s
existing `verify_all (31 checks ...)` claims (:60, :133) were bumped to 32 as part of the §5
count sweep. No structural/layout change to record.

## Insight to surface (optional)
- verify_all.sh's I.6 retired-claim grep loop makes the whole bash gate take ~3-4 min under
  Git-for-Windows MSYS (per-file × per-banned-entry `grep -E`); auto-background it and read the
  result from a repo-local file rather than expecting fast foreground completion. · evidence:
  T-008 dev runs, `.harness/scripts/verify_all.sh:561-593` I.6 loop

## Verdict
READY FOR REVIEW

---

## Version bump v0.21.0 (release pass)

Release-ships the T-008 work by bumping the project version `v0.20.0 → v0.21.0`
(minor — adds a new standing gate check, count grew 31→32) so the new 32nd check
(**G.4**) ships truthfully. v0.20.0 already shipped (T-007) with 31 checks, so the
T-008 count claims (set to "32 checks at v0.20.0") had to move their VERSION token to
v0.21.0 while KEEPING the count at 32. Done in lockstep across the full L14 fan-out;
the new G.4 check was used as the completeness oracle.

### Files changed (version token only; count stays 32)

**G.3-gated stamps (version → 0.21.0):**
- `.claude-plugin/plugin.json:4` — `"version": "0.20.0"` → `"0.21.0"`.
- `.claude-plugin/marketplace.json:17` — `plugins[0].version` `"0.20.0"` → `"0.21.0"`.
- `README.md:5` — version badge `version-0.20.0-blue` → `version-0.21.0-blue`
  (the `verify__all-32%2F32` count badge carries NO version token — left untouched).
- `README.zh-CN.md:5` — version badge `version-0.20.0-blue` → `version-0.21.0-blue`
  (count badge untouched).

**Version-bearing COUNT claims (VERSION token → v0.21.0, count KEPT at 32):**
- `AI-GUIDE.md:36` — `32/32 at v0.20.0` → `32/32 at v0.21.0`.
- `AI-GUIDE.md:69` — `32 checks at v0.20.0` → `32 checks at v0.21.0`.
- `docs/dev-map.md:60` — `(32 checks at v0.20.0)` → `(32 checks at v0.21.0)`.
- `docs/dev-map.md:133` — `runs all 32 checks (at v0.20.0)` → `... (at v0.21.0)`.
- `.harness/rules/40-locations.md:25` — `(32 checks at v0.20.0` → `(32 checks at v0.21.0`.
- `docs/manual-e2e-test.md:3` — `verify_all at 32 checks at v0.20.0` → `... v0.21.0`.

**CHANGELOG:**
- `CHANGELOG.md` — NEW top entry `## [0.21.0] - 2026-06-05` inserted between
  `## [Unreleased]` and `## [0.20.0]`, describing the T-008 supervisor hardening
  (8 fan-out asserts removed + new standing G.4 meta-check; check count 31 → 32).
  Older entries untouched. (CHANGELOG is the #1 L14 miss — this IS the entry.)

The count-bearing-but-version-less claims were deliberately LEFT at 32 (no version
token to bump): `README.md:159` `(32 checks)`, `README.zh-CN.md:159` `（32 项检查）`,
both `verify__all-32%2F32` badges, and `baseline.json:10` `"verify_all_checks": 32`.

### How G.4 confirmed completeness (the oracle)

G.4 reads the version from `plugin.json` (now 0.21.0) and the check count from the
live recorded-step tally (32), then string-validates every one of the 11 doc count/
version claims plus the `[<version>]` CHANGELOG heading. After the plugin.json bump,
any count claim still reading `v0.20.0` would have made G.4 FAIL and named the exact
file/found-value/expected-value. Both shells ran G.4 to **PASS** at v0.21.0/32 — that
is the machine proof that the fan-out is complete and no version-bearing claim was
missed. G.3 also PASSed (4-way stamp consistency at 0.21.0). The `[0.21.0]` CHANGELOG
heading sub-check (re-homed from the removed test-supervisor assert) confirmed the
CHANGELOG entry is present.

### Real verify_all tallies (both shells)

- **PowerShell** (`.harness/scripts/verify_all.ps1`): **PASS 32 · WARN 0 · FAIL 0** —
  32/32 PASS. `[G.3] ... PASS`, `[G.4] ... PASS`. RC 0.
- **Bash** (`.harness/scripts/verify_all.sh`): **PASS 31 · WARN 1 · FAIL 0** —
  31 PASS + 1 WARN (`[I.4] insight-index.md ≤30 lines ... WARN`, the PRE-EXISTING
  cross-shell line-count divergence, out of scope and untouched) + 0 FAIL. `[G.3] PASS`,
  `[G.4] PASS`. SH_RC=1 reflects only that pre-existing I.4 WARN.
- Matches the expected end state exactly: PS 32/32 PASS; SH 31 PASS + 1 I.4 WARN +
  0 FAIL. **0 FAIL in both shells — the gate is met.**

### Post-bump `git grep "0.20.0"` residual (all historical — confirmed)

No live current-state v0.20.0 stamp remains. Remaining hits are all legitimately
historical:
- `CHANGELOG.md:14,32,34-37` — the historical `## [0.20.0] - 2026-06-04` entry + its
  own change-list prose (a release record, must not be rewritten).
- `README.md:268` / `README.zh-CN.md:270` — the `0.20.0 | done` / `0.20.0 | 已交付`
  Roadmap milestone rows (historical, count-less, not version-stamp claims).
- `docs/features/_archived/scripts-relocation/**` — archived T-007 stage docs.
- `docs/tasks.md:22` — T-007 delivery record.

All four G.3-gated stamps and all six version-bearing count claims now read 0.21.0.
**No live v0.20.0 stamp still present.**

### Design drift
None. Pure release-ship fan-out per the task spec; mechanism (G.3/G.4, test-supervisor)
untouched; check count held at 32; I.4 WARN and baseline.json test_init counts left
out of scope as instructed.

### Verdict
VERSION BUMP COMPLETE — v0.21.0
