# Test Report — T-11b `entropy-watch-harness`

> Stage 6 (QA Tester). Mode: full (pure-wiring slice). deferred-human: defer, do not ask.
> Scope: T-11b's 9 attributable files (T-11a + stream bookkeeping co-mingled in working tree).
> Bash available; PowerShell denied to sub-agents → PS side marked operator-pending (never faked).
> Upstream read: 01 (RA, READY) · 02 (SD, READY) · 04 (DEV, READY FOR REVIEW) · 05 (CR, APPROVED).

This slice is documentation wiring over the T-11a core (no new script/skill/state/check), so the
verification is inspection/grep of the wiring prose + the shared `entropy-cadence` script smoke
(the contract the new `/harness` wiring relies on). Every claim below carries tool output.

## Test plan

| Acceptance criterion | Test case(s) | Evidence |
|---|---|---|
| AC-1 below-threshold → no scan/section | Cadence smoke: `check` at count 1/2/4 → `NOT-DUE` | Probe L / AC-2 reproducer |
| AC-2 ≥N → one scan + `## Entropy watch` + reset | Independent threshold reproducer: prime 4 → NOT-DUE; 5th → DUE; swept → NOT-DUE | AC-2 reproducer |
| AC-3 plain `check`, NO `--first-of-session` | grep pm-orchestrator (only the negation) + flag-distinction proof at count=1 | Probe C + AC-3 reproducer |
| AC-4 non-blocking / fail-open, verdict never changes | Inspect §6a subsection prose (`non-blocking and fail-open`, missing-artifact omit-but-swept) + script exit-0 on every arm | pm-orchestrator:202-204,226-227; Probe L (all exit=0) |
| AC-5 DRY — one home + one pointer | grep `entropy-cadence` across agents/+skills/; harness SKILL.md count | Probe A + Probe B |
| AC-6 counts + version 0.42.0 | 4 version stamps + CHANGELOG `[0.42.0]`; 17/8/32 grep; verify_all 32/32 | Probe J + Probe G + verify_all |
| AC-7 unified shared counter | Single `.harness/entropy-watch.state` advanced/reset by the same CLI both surfaces call | AC-2 reproducer (one state file) + Probe A |

## Boundary tests added

This is a doc-wiring slice; no new automated test files are added (per DRY/no-new-check mandate
the test surface is the existing `test-supervisor.sh` for the supervisor.md F-1 edit, plus the
shared `entropy-cadence.sh` smoke). Boundaries exercised via independent reproducers:

- Counter at 1, 2, 4 (below N=5) → `NOT-DUE` (fail-open counter-only behavior).
- Counter at exactly N=5 → `DUE` (threshold arm fires once).
- `swept` → counter back to 0, subsequent `check` → `NOT-DUE` (no re-trigger).
- `--first-of-session` at count=1 → `DUE` (proves the stream flag is NOT a no-op → AC-3 non-vacuous).
- Every `check`/`delivered`/`swept` invocation → exit 0 (fail-open contract intact).
- State file gitignored → no test residue persists into git.

## Adversarial tests (one independent reproducer per AC; hypothesis stated before running)

Verdict is based on whether the implementation **survived** the probe, not on the developer's
own claims. Reproducers written from the acceptance criteria, not from 04_DEVELOPMENT.md.

| AC | Hypothesis ("I expect failure when…") | Reproducer (NEW, I wrote this) | Outcome (with tool output) |
|---|---|---|---|
| AC-5 (DRY) | the `/harness` 3-step call-sequence is forked into `skills/harness/SKILL.md` (a second divergent copy) | `grep -rn "entropy-cadence" agents/ skills/` + `grep -cn "entropy-cadence" skills/harness/SKILL.md` | **Survived.** `entropy-cadence delivered/check/swept` call-sequence appears in `agents/pm-orchestrator.md` ONLY (L205/208/210/228). `skills/harness/SKILL.md` → **0** occurrences (pointer-only). The `skills/harness-stream/SKILL.md:126` + L162-173 `entropy-cadence` hits are the SEPARATE T-11a stream surface (drain-boundary block with `--first-of-session`), not a `/harness` fork. |
| AC-3 | the boundary silently uses `--first-of-session`, OR the plain check is vacuous (== first-of-session) | `grep -n "first-of-session" agents/pm-orchestrator.md` + flag-distinction proof at count=1 | **Survived.** pm-orchestrator has exactly ONE `first-of-session` hit — the explicit negation "WITHOUT `--first-of-session`" (L211). Proof the flag is load-bearing: at count=1, plain `check` → `NOT-DUE`, `check --first-of-session` → `DUE`. The plain-check choice is a real, correct distinction. |
| AC-1 / AC-2 | the plain counter fires below N, or fails to fire at N (off-by-one) | prime 4 deliveries → check; 5th delivery → check; swept → check (against the live shared script) | **Survived.** count=4 → `NOT-DUE`; count=5 → `DUE`; after `swept` → `NOT-DUE`. Exactly-N trigger, no off-by-one, resets cleanly. |
| AC-7 (unified counter) | `/harness` and `/harness-stream` write different state files (counter not unified) | inspect the single `.harness/entropy-watch.state` the CLI reads/writes; both surfaces call the same `entropy-cadence` CLI | **Survived.** One state file (`delivered_since_sweep` + `last_sweep`); both pm-orchestrator (L208) and harness-stream (L126) call the same `entropy-cadence delivered`. No second state file exists. |
| AC-4 (non-blocking/fail-open) | a cadence error or DUE sweep alters/halts the delivery verdict | inspect §6a prose; confirm every script arm exits 0 | **Survived.** Subsection opens "non-blocking and fail-open … never changes the delivery verdict, never gates or halts" (pm-orchestrator:202-204); step 4 omits the section but still runs `swept` on a missing artifact (L226-227); every `check`/`delivered`/`swept` arm exited 0 in the smoke (Probe L). |
| AC-6 (counts/version) | a count silently flipped (17→18 / 8→9 / 32→33) or a stamp is stale 0.41.0 | grep 17/8/32 claims + 4 version stamps + CHANGELOG heading | **Survived.** 17 skills / 8 framework agents / 32 checks all intact (Probe G); 8 physical agents in `agents/`; 4 stamps = 0.42.0, no stale 0.41.0 in plugin/marketplace; CHANGELOG `## [0.42.0]` above `[0.41.0]`. |
| Goal-guard (RA §10 / SD risk-1) | the entropy watch fires for `goal` mode (shared stage-7) instead of being guarded out | inspect the FIRST sentence of the §6a subsection | **Survived.** Subsection heading L196 `(… full mode only)`; FIRST sentence (L198): "This fires only when the task `mode` is `full` … For `goal` mode, SKIP this entire subsection." Guard is unmissable, not buried. |
| F-1 (supervisor enumeration) | a stale "only … two dispatchers" wording remains after adding `/harness` | grep supervisor.md "invoked only via" enumeration + stale-"two" scan | **Survived.** `/harness` single-task delivery named as a 3rd entropy dispatcher in all 3 spots (L23 Hard-rule-1 exception, L134 `## Entropy lens` heading, L137-138 blockquote). No stale "two"/"both deflate and stream" wording. test-supervisor.sh PASS 45/0 → structural asserts (AP-ids/severity/tools/≤300) intact. supervisor.md = 280 lines (≤300). |
| F-2 (dev-map parenthetical) | a stale "(and later `/harness`)" / "later" parenthetical remains | grep dev-map.md "later" | **Survived.** Zero "later" occurrences. The entropy-cadence row (L174) now reads "called by `/harness-stream` AND `/harness`" (shipped state). |
| Cadence smoke (shared counter) | the `entropy-cadence` pair the new wiring relies on is broken (T-11b touched no script) | full `check`/`delivered`/`swept` cycle against the live `.sh` | **Survived.** `check`→`NOT-DUE`, `delivered`→`count=N`, `swept`→`reset`; all exit 0 (fail-open). T-11b touched no script; the pair the `/harness` wiring depends on is intact. |
| No-decoy-flip | the harness-status "14 assets" decoy got swept along with the real count claims | grep harness-status SKILL.md "asset" | **Survived.** "All 14 required assets present" (harness-status SKILL.md:135) untouched — decoy correctly left alone. |

## verify_all result

- Total checks: 32 → 32 (no new check; G.4 stays last — no count flip).
- Pass: **32**
- Fail: **0** (must be 0 to approve — met)
- Warn: **0**
- G.3: all 4 version stamps consistent at **0.42.0** (PASS).
- G.4: CHANGELOG `## [0.42.0]` heading + count claims consistent with plugin.json + live check count (PASS).
- I.6: No retired-claim phrases in current docs/templates (PASS).
- I.3: agent definitions ≤300 — pm-orchestrator 250, supervisor 280 (PASS).
- New automated tests added: 0 (doc-wiring slice; no-new-check mandate). Reproducers run live, not committed.
- Baseline updated: **no** (test counts unchanged — `verify_all_checks` stays 32; supervisor bash assertions stay 45; baseline only goes up and nothing increased).

```
=== Summary ===
  PASS: 32
  WARN: 0
  FAIL: 0
```

PowerShell side (`verify_all.ps1`, `test-supervisor.ps1`): **operator-pending** — PowerShell is
denied to sub-agents per the harness's known constraint. Not run, not faked. PM/operator to run
`pwsh .harness/scripts/verify_all.ps1` (expect 32/0/0) and `test-supervisor.ps1` (expect 49 PS asserts).

## test-supervisor.sh result

```
=== Result ===
  PASS: 45
  FAIL: 0
```

Supervisor.md F-1 edit verified: structural asserts (AP-ids, severity scheme, tools whitelist,
≤300 cap, doc fan-out) all intact. supervisor.md = **280 lines** (≤300). Baseline
`test_supervisor_bash_no_python3_assertions` = 45, unchanged (no increase).

## Defects found

None. No BLOCKER / CRITICAL / MAJOR / MINOR defects.

## Stability

- `verify_all.sh` run within this session: 32/0/0, consistent with the developer's recorded run
  and the baseline `verify_all_checks: 32`. Deterministic md/grep checks — no flakes observed.
- `test-supervisor.sh`: 45/0, deterministic structural asserts — no flakes observed.
- `entropy-cadence.sh` smoke: ran the full cycle twice (smoke + AC-2 reproducer); identical
  contracted stdout (`NOT-DUE`/`count=N`/`DUE`/`reset`) and exit 0 each time — no flakes.
- State file left clean at `delivered_since_sweep=0` after the reproducers (no test residue;
  the file is gitignored → no tracked-change residue either).

## Verdict

**APPROVED FOR DELIVERY** — 0 defects. verify_all.sh 32/0/0; test-supervisor.sh 45/0.
All 7 ACs survived independent adversarial reproducers; goal-guard is the first sentence of the
§6a subsection; the `/harness` call-sequence home is `agents/pm-orchestrator.md` ONLY (harness
SKILL.md is pointer-only with 0 `entropy-cadence` occurrences); plain `check` (no
`--first-of-session`) confirmed and proven a real distinction; F-1 names `/harness` as the 3rd
entropy dispatcher with no stale "two" wording; F-2 removed the "later" parenthetical; no count
flip (17/8/32 + 314/90 badges + "14 assets" decoy intact); version 0.42.0 across 4 stamps +
CHANGELOG `[0.42.0]`; the shared `entropy-cadence` pair the wiring relies on is intact and
fail-open. PowerShell side operator-pending (denied to sub-agents — not faked).
