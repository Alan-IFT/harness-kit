# 01 — Requirement Analysis · T-010 · g4-version-decouple

**Mode:** full · **Stage:** 1 (Requirement Analyst) · **Date:** 2026-06-06
**Inputs (read-only):** `docs/features/g4-version-decouple/INPUT.md`; `.harness/scripts/verify_all.{ps1,sh}` G.4 block; the 6 live claim lines; `docs/tasks.md`; `.harness/insight-index.md` (L33 = T-008 G.4 origin; L34 = T-009 same-quantity discipline).

---

## 1. Goal

Decouple the six "N checks at vX" prose count claims from the release version: `verify_all` G.4 validates their COUNT against the live step tally only and stops gating a version token on them, so a count-unchanged release no longer has to bump those six prose strings in lockstep — while version consistency stays gated where it has a single source of truth (G.3 badges + G.4's CHANGELOG `[version]`-heading check).

---

## 2. Grounding — current G.4 behavior (verified by reading both shells)

G.4 (PS `verify_all.ps1:637-682`, sh `verify_all.sh:670-752`) validates an **11-row claim ledger** plus a standalone CHANGELOG heading check. It derives `version` from `.claude-plugin/plugin.json` (`0.21.1`) and `count` from `$report.Count + 1` / `${#report[@]} + 1` (= live shipped check count, `32`). Each row asserts the doc literally `.Contains()` / `== *..*` an exact SOT-derived expected substring.

The 11 rows split cleanly by whether the EXPECTED substring embeds `at v$version`:

| # | File | Expected substring (current) | Carries version? | T-010 disposition |
|---|---|---|---|---|
| 1 | `AI-GUIDE.md` | `$count/$count at v$version` | **YES** | → count-only |
| 2 | `AI-GUIDE.md` | `$count checks at v$version` | **YES** | → count-only |
| 3 | `docs/dev-map.md` | `$count checks at v$version` | **YES** | → count-only |
| 4 | `docs/dev-map.md` | `runs all $count checks (at v$version)` | **YES** | → count-only |
| 5 | `.harness/rules/40-locations.md` | `($count checks at v$version` | **YES** | → count-only |
| 6 | `README.md` | `verify__all-$count%2F$count` | no | **unchanged** (already count-only) |
| 7 | `README.zh-CN.md` | `verify__all-$count%2F$count` | no | **unchanged** (already count-only) |
| 8 | `README.md` | `($count checks)` | no | **unchanged** (already count-only) |
| 9 | `README.zh-CN.md` | `（$count 项检查）` | no | **unchanged** (already count-only) |
| 10 | `docs/manual-e2e-test.md` | `$count checks at v$version` | **YES** | → count-only |
| 11 | `.harness/scripts/baseline.json` | `"verify_all_checks": $count` | no | **unchanged** (already count-only) |
| — | `CHANGELOG.md` (separate check) | contains `[$version]` heading | **YES (version-only)** | **unchanged** (legitimate per-release bump) |

The six version-bearing rows are **1, 2, 3, 4, 5, 10** — identical to INPUT's list. Five already-count-only rows (6-9, 11) and the CHANGELOG heading check are out of scope and stay byte-identical.

### 2.1 Exhaustive sweep — the version-bearing count-claim set is exactly these 6

Independently grepped the whole tree for `\d+ checks? at v\d`, `\d+/\d+ at v\d`, `at v\d+\.\d+\.\d+`, the Chinese `项检查 … v\d` variant, and the `verify__all-\d+%2F\d+` badge form. Every **live, non-historical** version-bearing verify_all count claim is one of the six below (exact current text):

1. `AI-GUIDE.md:36` — `...all PASS checks are green (32/32 at v0.21.1; check count grows with releases)...` (G.4 row 1)
2. `AI-GUIDE.md:69` — `...total verification (32 checks at v0.21.1, including ...)` (G.4 row 2)
3. `docs/dev-map.md:60` — `← Total verification (32 checks at v0.21.1)` (G.4 row 3)
4. `docs/dev-map.md:133` — `...runs all 32 checks (at v0.21.1) including both --check modes` (G.4 row 4)
5. `.harness/rules/40-locations.md:25` — ``.harness/scripts/verify_all` checks (32 checks at v0.21.1, all must PASS — count grows with releases):`` (G.4 row 5)
6. `docs/manual-e2e-test.md:3` — `...verify_all` at 32 checks at v0.21.1; ...` (G.4 row 10) — same line lists test-init `251`/`213`, test-supervisor `49`/`45`, test-verify-i6 `56/56`, all version-LESS → only verify_all is internally inconsistent today.

**Everything else carrying a version-vs-count string is out of scope and confirmed not a live prose count claim:**
- README/README.zh-CN badges `verify__all-32%2F32`, `(32 checks)`, `（32 项检查）`, `baseline.json "verify_all_checks": 32` — already count-only (G.4 rows 6-9, 11); no version token to remove.
- `CHANGELOG.md` count/version lines (e.g. `:348`, `:409`, `:490`) — historical release records; G.4 patterns are anchored to never match bare CHANGELOG rows; never touched.
- `architecture.html:326,502` (`v0.17.4 … 30 … 检查`, `19 项检查（v0.1 是 15）`) and `docs/system-overview.html:584` (`v0.18.2 的 31 个检查`) — dated/labeled HTML snapshots, already HTML-exempt in T-008's ledger; never touched.
- `docs/features/_archived/**`, all `*_REQUIREMENT_ANALYSIS/SOLUTION_DESIGN/DEVELOPMENT.md`, `tasks.md` delivery records, `INPUT.md` — historical stage docs; never touched.

The set is closed at 6. (T-008's sweep took 2 rollbacks for missing scattered claims; this set was re-confirmed by live grep, not by hand-listing.)

---

## 3. In-scope behaviors (testable)

1. Each of the six claims (§2.1 #1-#6) states the verify_all check count WITHOUT a version token in its live text after this change.
2. G.4 rows 1, 2, 3, 4, 5, 10 (both shells) match those claims on COUNT only — the EXPECTED substring and the `shape` regex for these rows contain no `v$version` / `at v\d+\.\d+\.\d+` component.
3. G.4 rows 6, 7, 8, 9, 11 (badges / `(N checks)` / `（N 项检查）` / baseline.json) remain byte-identical (already count-only).
4. G.4's standalone CHANGELOG `[$version]`-heading presence check remains byte-identical and still gates the per-release version.
5. G.4's count derivation (`$report.Count + 1` / `${#report[@]} + 1` = `32`) and the "G.4 must remain last" tripwire remain byte-identical.
6. After the change, G.4 still FAILs when any of rows 1-11 drifts from the live count (the T-008 count-coupling property), and still FAILs when CHANGELOG lacks the current `[$version]` heading.
7. PS and Bash G.4 blocks stay symmetric (rule L20 / L13 PS↔Bash symmetry): the same six rows lose the version token in both, identically.

---

## 4. Out-of-scope (explicitly NOT done this iteration)

1. G.3 stamp/badge version checks (plugin / marketplace / README `version-0.21.1` badge) — unchanged; they remain the version SOT gate.
2. The CHANGELOG `[$version]` heading check — unchanged.
3. The check COUNT value (`32`) and the count-against-live-tally coupling — unchanged; only the VERSION coupling is removed.
4. Adding, removing, or reordering any verify_all check — count stays 32; G.4 stays last.
5. The five already-count-only G.4 rows (badges, `(N checks)`, `（N 项检查）`, baseline.json).
6. Historical / snapshot files: `CHANGELOG.md` body, dated HTMLs (`architecture.html`, `docs/system-overview.html`, `docs/project-overview.html`, walkthrough), `docs/features/_archived/**`, `tasks.md` delivery records.
7. Whether any of the six claims should be reworded beyond removing the version token (e.g. prose polish) — only the `at vX` token is in scope.

---

## 5. Boundary / edge conditions

- **Partial removal (the dangerous boundary):** after this change G.4 no longer gates a version token on rows 1-5,10, so a leftover stale `at v0.21.1` on any of the six would be **silently unchecked**. Removal across all six must be complete (AC-4). This is the exact recurrence vector that gave T-008 two rollbacks.
- **Shape-regex still matches the new text:** the `shape` regex is only for the FAIL message, but it must still match the new count-only prose so a count drift yields the precise `found '…', expected '…'` message rather than the weaker `no claim found`. The new shape must drop the `at v…` component yet still anchor each row (parenthesized / `runs all` / full-width-paren) so historical bare CHANGELOG/Roadmap rows are never matched.
- **Count = 32 unchanged:** no release/version bump is required by this task itself; plugin.json stays `0.21.1` unless the SA/PM rule a ship-version bump for the change (the change does not alter the count, so the six claims do not need a count edit either — only the version token is deleted).
- **CHANGELOG absent / version unreadable:** existing G.4 behavior (FAIL on missing `[$version]`; FAIL on unreadable plugin.json version) is preserved unchanged.
- **Empty / missing claim file:** existing per-row "file missing" branch preserved.

---

## 6. Acceptance criteria (refined from INPUT AC-1..AC-5; each verifiable)

- **AC-1** — All six claims (§2.1 #1-#6) state the count with **no** version token in live text. *Verify:* read each line; none contains `at v0.21.1` (or any `at v\d+\.\d+\.\d+`).
- **AC-2 (hard — T-008 property preserved)** — G.4 (both shells) still FAILs on a WRONG COUNT. *Verify (QA mutation):* mutate any one of the 11 rows' count (e.g. `32`→`31`) in a temp copy, run `verify_all.{ps1,sh}`; G.4 FAILs naming that file. Revert. Removing the version coupling removes **only** version gating, not count gating.
- **AC-3 (treadmill gone)** — A simulated count-UNCHANGED version bump (`plugin.json` patch `0.21.1`→`0.21.2` in a temp fixture, count still 32) makes G.4 PASS WITHOUT editing any of the six prose count claims — while a missing CHANGELOG `[0.21.2]` heading still FAILs G.4, and G.3 still requires the badges to bump. *Verify:* temp-fixture run; observe G.4 PASS on the six prose claims, and G.4 FAIL re-appears only if the CHANGELOG heading is missing.
- **AC-4 (exhaustive)** — No live prose count claim retains a version token. *Verify:* `grep -rn` for `checks? at v` / `\d/\d at v` over the live tree (excluding `CHANGELOG.md`, dated HTMLs, `docs/features/_archived/**`, `tasks.md`) returns zero hits.
- **AC-5** — `verify_all` reports **32 PASS / 0 WARN / 0 FAIL in BOTH shells**, G.4 PASS, no new check (count stays 32), G.4 remains the last check, tripwire green. PS↔Bash G.4 symmetric (rule L20). *Verify:* run both scripts.

---

## 7. Non-functional requirements (material only)

- **Symmetry (L20 / insight L13):** the six rows must be edited identically in `verify_all.ps1` and `verify_all.sh`. A one-shell edit is a defect class this project has shipped before.
- **No regression in drift protection (strictly-better requirement):** the net change must lose **no version-consistency coverage that matters** — version stays gated via G.3 (badges) + G.4 CHANGELOG heading; only the prose count-claim's redundant version annotation goes ungated, *because it ceases to exist*. The SA must affirm this (D4 below).

---

## 8. Design decisions surfaced for the SA (NOT pre-decided here)

> RA states the requirement; the SA chooses the mechanism. Four decisions:

- **D1 — Per-claim disposition.** Confirm all six are *living current-state* statements (drop `at vX`) and none is a deliberate "validated-at-vX" snapshot. *RA reading:* all six read as living (#1 literally says "check count grows with releases"; #6's own line already lists the four sibling tools version-LESS) → all six → count-only. SA confirms or flags any genuine snapshot.
- **D2 — Exact G.4 simplification (both shells).** How to make rows 1,2,3,4,5,10 count-only: rewrite each `expect` to drop `at v$version` and each `shape` to drop the version component while keeping the row anchored. Retain the CHANGELOG `[$version]` check and the count-against-live-tally coupling (the T-008 load-bearing property). SA specifies the exact new `expect` + `shape` per row.
- **D3 — Which rows change vs stay.** Rows 1-5,10 change; rows 6-9,11 + the CHANGELOG check + count derivation + tripwire stay byte-identical. SA confirms the change surface is exactly these six rows × two shells + the six doc lines.
- **D4 — Net strictly-better, no regression.** Affirm decoupling weakens no version coverage that matters (stamps → G.3; changelog → G.4; the prose version annotation simply no longer exists, so nothing it "protected" is lost). SA states this explicitly.

---

## 9. Related tasks

- **T-008 / `test-supervisor-stamps`** (`docs/features/_archived/test-supervisor-stamps/`) — added the standing G.4 meta-check and the 11-claim ledger this task edits. Its 06_TEST_REPORT AC-6 proves the count-coupling is load-bearing (the property AC-2 here must preserve). Its 2 design rollbacks (F-1/F-2/F-5/F-7) are the precedent for the exhaustive-sweep discipline (§2.1). Insight L33.
- **T-009 / `i4-cap-symmetry`** (`docs/features/_archived/i4-cap-symmetry/`) — last touched the same six claims (version stamp `0.21.0`→`0.21.1`); its 07_DELIVERY §Outstanding-1 is the origin of this task. Insight L34 ("gate, remediation, and intent must count the same quantity") is the spirit here: the count stays gated, the version stops being doubly-gated.
- **Insight L13 / L20** — PS↔Bash symmetry; both shells' G.4 edited identically.

---

## 10. Open questions for user

None. The requirement is fully determinable from INPUT + the verified code: the six-claim set is closed (§2.1), all six are living-current-state (D1, RA reading affirmed pending SA confirm), the count-coupling preservation is a hard AC (AC-2), and scope boundaries are unambiguous. The four design decisions (§8) are mechanism choices owned by the SA, not requirement ambiguities.

---

## 11. Verdict

**READY.** No user bounce required. Four design decisions (§8 D1-D4) deferred to the Solution Architect. Six version-bearing prose count claims confirmed (§2.1).
