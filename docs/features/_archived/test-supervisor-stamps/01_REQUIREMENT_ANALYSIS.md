# 01 — Requirement Analysis: test-supervisor-stamps (T-008)

> Mode: **full**. Stage 1 of the Harness pipeline.
> Inputs (read-only): `docs/features/test-supervisor-stamps/INPUT.md`, the two test-supervisor scripts, `verify_all` G.3, `.harness/insight-index.md`, `docs/tasks.md`.

## 1. Goal

Make `test-supervisor.{ps1,sh}`'s version/count fan-out assertions structurally non-drifting and re-run green, so the supervisor regression stops being a silent literal-bump trap across future releases — without re-introducing the same `v0.17.1`/`30` drift class.

## 2. In-scope behaviors

1. The 12 "Doc fan-out spot checks" in `test-supervisor.ps1` (lines 416-451) and their 12 bash twins in `test-supervisor.sh` (lines 377-409) are the only assertions in scope. Each is categorized in §7.
2. After the change, `test-supervisor.ps1` runs with **0 FAIL** at the current repo version (v0.20.0).
3. After the change, `test-supervisor.sh` runs with **0 FAIL** at the current repo version, with the same logical assertion set as the PS twin (PS/Bash symmetry — insight L13/L20).
4. No assertion in test-supervisor that is meant to track releases contains a hardcoded `vX.Y.Z` version literal or a hardcoded check-count literal after the change.
5. A recurrence-prevention mechanism is in place such that a future version or check-count bump cannot leave test-supervisor silently red (the mechanism is the SA's choice — see §8).
6. `verify_all.ps1` and `verify_all.sh` continue to pass: `31/31` both shells, OR `(31+N)/(31+N)` if the SA's chosen mechanism adds N new checks, with each new check justified.
7. Any edit to `verify_all` itself passes `verify_all`'s own gate (dogfood self-consistency — insight L26 exempt-list discipline applies if a new banned/whitelist token is introduced).
8. The three version-agnostic structural assertions (category (c) in §7) are preserved in behavior: they continue to assert the supervisor phrasing and the canonical-7 glob.

## 3. Out-of-scope

1. The supervisor agent redesign or any of its non-version assertions (AC-1 through AC-7, BUG-2, F-4, I.7-emu blocks in test-supervisor).
2. Any broad `verify_all` refactor beyond what the recurrence-prevention requirement (§2.5) minimally needs.
3. The relocation work (delivered in T-007).
4. Bumping or reconciling the count/version stamps in the *consumer* docs themselves (AI-GUIDE, dev-map, README, manual-e2e-test) beyond whatever the chosen test-supervisor mechanism reads — fixing those docs' own drift is verify_all's concern, not this task's.

## 4. Boundary conditions

1. **Missing source file**: if the chosen mechanism derives the expected version from `.claude-plugin/plugin.json`, the assert must fail loudly (not silently pass) when that file is absent or unparseable.
2. **Empty / malformed version**: a `plugin.json` with no `version` field, or a non-`x.y.z` value, yields a clear FAIL, not a green pass.
3. **Count source absent**: if the "N checks" claim is derived from a runtime count and that count cannot be obtained (e.g. verify_all not runnable in the test context), the behavior is a defined FAIL or an explicit documented skip — never a silent pass. The SA decides which (§8 Q3).
4. **Cross-shell divergence**: PS and SH must compute the same expected value from the same source; a value present in one shell's logic but absent in the other is a defect (insight L13 — both shells change together).
5. **CHANGELOG entry**: the CHANGELOG assert currently looks for a `[0.17.1]` heading. The current version's CHANGELOG entry must exist; a derive-based version must locate the entry for the *current* version, not a fixed literal.

## 5. Acceptance criteria (refined from INPUT AC-1..AC-5)

Each is verifiable by a command or observable file state.

- **AC-1** — `test-supervisor.ps1` exits 0 with `FAIL: 0` at v0.20.0. Verify: run the script, read its `=== Result ===` block.
- **AC-2** — `test-supervisor.sh` exits 0 with `FAIL: 0` at v0.20.0, and its fan-out assertion set is the logical twin of the PS version (same checks, same source-of-truth). Verify: run the script; diff the two fan-out blocks for logical correspondence.
- **AC-3** — No hardcoded release-tracking literal remains in the fan-out asserts of either shell. Verify by grep over `test-supervisor.{ps1,sh}`: the regexes `v?0\.17\.1`, `0\.20\.0`, and a bare check-count literal (`30`/`31` used as the expected count) return **zero hits in the fan-out block** for any assert whose value is meant to track releases. (Category-(c) structural asserts legitimately contain no version literal and are unaffected.)
- **AC-4** — A simulated version bump does not require editing test-supervisor and does not leave it silently red. Verify by reasoning or fixture: with the chosen mechanism, changing `plugin.json.version` to a hypothetical next value makes the fan-out asserts track that value (derive path) OR the asserts no longer exist in test-supervisor and the value is gated elsewhere (remove path). Either way, no manual edit of test-supervisor is needed and no assert silently passes against a stale literal.
- **AC-5** — `verify_all` is `31/31` PASS in both shells, or `(31+N)/(31+N)` with each of the N new checks justified in the design. Verify: run both `verify_all` shells; read summary.
- **AC-6** — A recurrence-prevention mechanism exists and is demonstrably load-bearing: either test-supervisor is wired so a future drift surfaces at the gate, OR the asserts are structurally derive-from-source so drift cannot occur, OR a new verify_all meta-check enforces the stamps against `plugin.json`. Verify: the mechanism is named in the design and exercised by at least one observable check/run.

## 6. Non-functional requirements (only material ones)

1. **PS/Bash symmetry** (binding, insight L13/L20): both shells change together; case-sensitive PS string operators (`-cmatch`/`-ccontains`/`-cnotin`) where a fixed-case contract applies.
2. **Dogfood self-consistency** (insight L26): if the mechanism touches `verify_all`, any verbatim banned-phrase/whitelist copy must be added to the relevant exempt list, and the change must pass `verify_all` itself.
3. **Gate latency** (soft): if the SA wires the whole test-supervisor suite into verify_all, gate wall-clock grows; a lightweight meta-check is the lower-cost alternative. This is a trade-off input for the SA, not a hard limit.

## 7. Ground-truth enumeration — the 12 fan-out asserts (both shells)

`verify_all` G.3 (verify_all.ps1:333-355) checks version consistency across **exactly four** stamps: `plugin.json`, `marketplace.json`, `README.md` badge, `README.zh-CN.md` badge. It does **not** cover CHANGELOG, AI-GUIDE, dev-map, or any check-count claim.

Categories: **(a)** duplicates G.3; **(b)** count/version claim not covered by G.3; **(c)** supervisor-structural, version-agnostic.

| # | PS line | SH line | Assertion (current literal) | Cat |
|---|---|---|---|---|
| 1 | 416-418 | 377-379 | AI-GUIDE `auxiliary.*supervisor` phrasing | **(c)** |
| 2 | 419-421 | 380-382 | AI-GUIDE `30/30 at v0.17.1` | **(b)** |
| 3 | 422-424 | 383-385 | AI-GUIDE `30 checks at v0.17.1` | **(b)** |
| 4 | 425-427 | 386-388 | CHANGELOG `[0.17.1]` entry | **(a)\*** |
| 5 | 428-430 | 389-391 | README.md badge `version-0.17.1-` | **(a)** |
| 6 | 431-433 | 392-394 | README.zh-CN badge `version-0.17.1-` | **(a)** |
| 7 | 434-437 | 395-397 | plugin.json version `0.17.1` | **(a)** |
| 8 | 438-441 | 398-400 | marketplace.json version `0.17.1` | **(a)** |
| 9 | 442-444 | 401-403 | dev-map `30 checks at v0.17.1` | **(b)** |
| 10 | 445-447 | 404-406 | harness-status `upervisor.*auxiliary` row | **(c)** |
| 11 | 448-451 | 407-409 | harness-status canonical-7 glob `{pm,req,sol,gate,dev,review,qa}*` | **(c)** |

\* #4 CHANGELOG is a version stamp but the CHANGELOG file is **not** in G.3's four-stamp set, so removing it from test-supervisor would leave the current-version CHANGELOG entry unchecked anywhere. The SA decides whether that gap matters (§8 Q1).

Summary: **3 structural asserts** (#1, #10, #11) are version-agnostic and stay. **5 asserts** (#5, #6, #7, #8 — and #4 partially) **duplicate G.3** and are redundant version-stamp checks. **3 asserts** (#2, #3, #9) are **count+version claims** (`N checks at vX`) that G.3 does **not** cover.

The check-count claim ("31 checks") also lives in AI-GUIDE.md:36,69, dev-map.md:60,133, README.md:159, manual-e2e-test.md:3, and is derivable at runtime from verify_all's summary `$pass` count — but no current check enforces it (insight L14: count claims need manual sync).

## 8. Design decisions deferred to the Solution Architect

These are mechanism choices, not requirement ambiguities the user must arbitrate. Each is framed with the trade-off; the SA picks and the Gate Reviewer vets.

**Q1 — Disposition of the version/count fan-out asserts.**
Options (from INPUT): (A) **Remove** the version/count asserts (categories (a) and (b)), keeping only the 3 structural asserts (#1/#10/#11), relying on G.3 for version consistency; (B) **Derive** the expected version from `.claude-plugin/plugin.json` at runtime so the asserts self-heal; (C) **Combination** — remove the (a) asserts that duplicate G.3, and convert the (b) count+version claims to derive N+version from source.
Trade-offs the SA must weigh: (A) is simplest but drops the count-claim coverage and the CHANGELOG-current-entry check entirely (no other check covers them); (B) keeps coverage but keeps test-supervisor as the owner of project-wide stamp consistency, which is arguably G.3's job, not the supervisor regression's; (C) minimizes redundancy while preserving the count-claim coverage but is the most code. Constraint: whatever is removed must not leave a *previously-green* coverage silently uncovered without a conscious decision.

**Q2 — Recurrence-prevention mechanism (the AC-6 requirement).**
Options: (i) wire `test-supervisor` into `verify_all` so it can never silently drift; (ii) add a lightweight `verify_all` meta-check that asserts test-supervisor's expected stamps match `plugin.json` (without running the whole suite); (iii) rely solely on a derive-from-source design that structurally can't drift (no new gate wiring).
Trade-offs: (i) maximizes coverage but adds the most gate latency and couples the gate to the supervisor fixtures; (ii) is low-latency and targeted but adds a new check (so AC-5 becomes `(31+N)/...`); (iii) adds zero gate surface but only works if Q1 chooses a pure-derive path with no removable-but-uncovered gaps. SA recommends; Gate vets the latency/coupling.

**Q3 — Source of truth for the "N checks" count, if a count-claim assert survives Q1.**
The count is derivable at runtime from `verify_all`'s summary `$pass` (verify_all.ps1:626) but there is no static literal that is the canonical "number of checks." Question for SA: is the count derived by running `verify_all` and reading its emitted count (couples the supervisor test to a full gate run), or is the count claim dropped from test-supervisor entirely and (if coverage is desired) enforced by a verify_all self-referential meta-check that compares its own emitted count to the doc claims? Boundary §4.3 applies: if the count can't be obtained, FAIL or documented-skip, never silent pass.

## 9. Related tasks

- **T-003 / supervisor-agent** (`docs/features/_archived/supervisor-agent/`) — shipped test-supervisor at v0.17.1; the snapshot literals originate here. BUG-1 there established the PS `-cmatch` fixed-case discipline (insight L20) that AC-2's symmetry requirement inherits.
- **T-007 / scripts-relocation** (`docs/features/_archived/scripts-relocation/`) — surfaced and deferred this exact drift; its 06_TEST_REPORT.md:64-67 re-confirmed the 7 fan-out failures are pre-existing version-literal drift (not path drift), and §350-391 of its 04_DEVELOPMENT.md document the consumer-doc count stamps that this task must not double-fix. T-007 also reinforced two-up root resolution (insight L31), already present in test-supervisor (ps1:18 / sh:7).
- **Insight L14** (count claims need manual sync) and **L18/L26** (recurrence guards in verify_all) are the cost/benefit precedent the SA should reference for Q2.

## 10. Verdict

**READY** — 3 design decisions (Q1, Q2, Q3 in §8) are deferred to the Solution Architect; they are mechanism choices, not requirement ambiguities. The user's principle ("no band-aid, kill the drift class") fully determines "done"; no user-facing arbitration is required.
