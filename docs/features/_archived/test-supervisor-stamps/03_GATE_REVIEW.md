# 03 — Gate Review · test-supervisor-stamps (T-008)

> Stage 3 (Gate Reviewer). Verdict vocabulary: APPROVED FOR DEVELOPMENT / CHANGES REQUIRED / REJECTED. Upstream 01=READY, 02=READY. Read-only; every claim verified against the live tree. Persisted verbatim by PM (GR is read-only).

## 1. Audit checklist

| # | Dimension | Verdict | Reason |
|---|---|---|---|
| 1 | Requirement completeness | PASS | AC-1..AC-6 each tied to a runnable command/grep; boundary conditions cover missing/malformed plugin.json + cross-shell divergence. |
| 2 | Design completeness | **FAIL** | Option-C mechanism sound, but §5 one-time-sync set is INCOMPLETE: omits `.harness/rules/40-locations.md:25` "31 items" + `README.zh-CN.md:5` badge `verify__all-31%2F31`; G.4 §4 gates neither → the drift this task kills survives in 2 files. |
| 3 | Reuse correctness | PASS | `extract_json_version()` (verify_all.sh:354-358), Step/step wrappers, G.3 ConvertFrom-Json, `$report`/`report[]` accumulators all verified present + reusable. |
| 4 | Risk coverage | PASS (note) | 3 self-flagged risks are the real ones; R6 self-tally + R8 badge `%2F` correctly anticipated. Missed: README Roadmap/CHANGELOG "N checks" rows (F-3). |
| 5 | Migration safety | PASS | Internal tooling; single-commit, clean `git revert`. |
| 6 | Boundary handling | PASS | Missing/unparseable plugin.json → loud FAIL; count always in-memory; self-reference off-by-one handled (verified). |
| 7 | Test feasibility | PASS | QA forward-drift sim (bump plugin.json in throwaway copy, assert G.4 FAILs, revert) is the correct adversarial proof of AC-4/AC-6. |
| 8 | Out-of-scope clarity | PASS | 02 §12 explicit (no version-bump, no test-supervisor wire-in, no unrelated tally fixes). |

## 2. Focus-point adjudication

**Focus 1 — G.4 altitude: JUSTIFIED, not over-built.** The lighter "just remove asserts, leave count drift ungated" is the status quo that insight L14 calls an unsolved recurring pain. AC-6 requires the mechanism be demonstrably load-bearing; pure derive-in-test (Option B) can't satisfy it because test-supervisor isn't run by verify_all — it would self-heal the test while doc claims rot unobserved (the actual 5-release hole). G.4 (~30 lines/shell, subprocess-free) converts silent-red into a hard gate FAIL. Altitude correct: stamp/count consistency is the gate's job, G.3's neighbour. **Confirmed.**

**Focus 2 — Self-referential count (RISK B): logic CORRECT, verified.**
- (a) Every prior check appends exactly once to `$report`/`report[]` (PS:26,29,35 all 3 branches; SH:24 in the executed branch). 31 distinct Step IDs counted (A.1→J.1), matching live 31/31.
- (b) Last check today is J.1 (PS:574 / SH:650), right before Summary (PS:623 / SH:656). G.4 inserted there is genuinely last.
- (c) Count derived from `$report.Count`/`${#report[@]}` (step count) NOT `$pass` → status-independent (a WARN on I.1-I.5 doesn't change it). Correct SOT for a *checks* count.
- (d) Residual fragility: `+1` is correct ONLY while G.4 is last. Mitigation = Developer pin-comment (convention, not mechanical guard). Acceptable, but a latent trap for the next contributor → **CONDITION** (pin-comment in both shells; consider a Summary tripwire `$report.Count == derived`). No off-by-one ships as designed.

**Focus 3 — 31→32 fan-out (RISK A): INCOMPLETE → blocking.** Independent grep of the live tree found two missed live claims:
- **F-1 (must-fix) `.harness/rules/40-locations.md:25`** — "verify_all checks (31 items at v0.20.0...)". Live current-state claim, in NEITHER §5 edit list NOR G.4 §4 table. Uses "items" not "checks" so G.4's pattern wouldn't even match it. After G.4 lands it says "31 items" while reality is 32, uncaught — the exact L14 drift re-created. Owner: 02 §4+§5.
- **F-2 (must-fix) `README.zh-CN.md:5`** — badge `verify__all-31%2F31`. Design lists only README.md:5. G.3 validates the zh-CN *version* badge but NOT the count badge. Silently stays `31%2F31`. Owner: 02 §4+§5 (add to edit list AND G.4 table).
Neither makes verify_all FAIL after the bump (G.4 doesn't read them) — so they're silent-drift gaps, which is WORSE for AC-6 (ships claiming the drift class is dead while 2 claims still drift).
- **F-3 (note, non-blocking)** — README.md:262-268 + CHANGELOG roadmap rows ("stays 30 checks", "30→31 checks") describe PAST releases; must NOT be bumped (would falsify history). G.4's parenthesized `\(\d+ checks\)` pattern correctly targets only README.md:159, not bare roadmap rows — Developer must keep it anchored to the parenthesized form.
- **F-4 (note)** — `docs/walkthrough.html:717` "31 checks..." is an I.6-exempt historical HTML snapshot; G.4 doesn't read HTML; no action (recorded for exhaustiveness).

**Focus 4 — 57/53 self-tally (RISK C): CORRECTLY identified.** `manual-e2e-test.md:3` reads "57 assertions / 53". Design (§5, §9-R6) flags removal of 8 asserts invalidates it, scopes it in-bounds, mandates recount FROM A CAPTURED RUN (cites L32), gives 57→49/53→45 as sanity only. Right. PASS.

**Focus 5 — Coverage continuity: VERIFIED complete.** G.3 (verify_all.ps1:333-355) validates only 4 stamps via `version-(\d+\.\d+\.\d+)-`; does NOT read CHANGELOG. So removed assert #4 (CHANGELOG `[0.17.1]`) is genuinely uncovered by G.3 and correctly re-homed to G.4's CHANGELOG sub-check. Count #2/#3/#9 → G.4 count; stamp duplicators #5/#6/#7/#8 → G.3; structural #1/#10/#11 → kept. No orphan. PASS.

**Focus 6 — Insight compliance.** L13 symmetry: required, and the F-1/F-2 additions must land in BOTH shells. L19 backtick: G.4 literals are backtick-free (keep them so). L20/L23 case-sensitivity: N/A (digits + lowercase tokens, not a fixed-case contract) — design's reasoning confirmed. L30: G.4 reads plugin.json+docs only, doesn't touch settings/J.1. I.6/L26: verify_all.{ps1,sh} are already wholesale-exempt (PS:520-521/SH:551-552); G.4 literals aren't banned anchors → no new exemption needed. L31 two-up root: inherited. Compliant.

**Focus 7 — AC verifiability.** AC-1..AC-4/AC-6 mechanically testable; the QA temp-fixture bump (plugin.json 0.20.0→0.21.0, assert test-supervisor green + G.4 FAILs on stale docs, revert) is sound. AC-5 (`32/32` both shells) is conditional on F-1/F-2 being added to the one-time sync (else G.4 FAILs its own first run).

## 3. Pre-answered developer questions
1. SH plugin/marketplace asserts are at :395-397 / :398-400 (design table transposed) — **match by assertion text, not line number** (design's own footnote). 
2. Bump README.zh-CN.md:5 + 40-locations.md:25 too (F-1/F-2) — don't ship without them.
3. Do NOT touch CHANGELOG/Roadmap "30→31 checks" history rows (F-3); keep G.4's README regex on the parenthesized `(N checks)` form.
4. Get the 49/45 tally from a real run (L32), not 57−8/53−8.
5. If a check is added after G.4 later, `+1` undercounts — pin-comment both shells + consider a Summary tripwire.

## 4. Verdict

The mechanism is the right design at the right altitude — self-reference math verified correct against the real scripts (31 prior steps, G.4 is the 32nd, `$report.Count + 1` status-independent and exact in both shells), removed-assert re-homing complete, insight-compliance sound. **But** the §5 one-time-sync set and the G.4 §4 validation table are incomplete: they miss `.harness/rules/40-locations.md:25` ("31 items") and `README.zh-CN.md:5` (`verify__all-31%2F31`), so the task as designed would ship with the very L14 drift class still alive in two files — a direct contradiction of AC-6. Design-doc gap (02 §4+§5), not a requirement ambiguity → routes to solution-architect for a bounded edit, not a redesign.

**GATE VERDICT: CHANGES REQUIRED** — G.4 sound but its doc-claim sweep is incomplete: 02 §4+§5 must add `40-locations.md:25` and `README.zh-CN.md:5` to BOTH the one-time 31→32 edit list AND G.4's validation table, and add the "keep G.4 last" pin-comment as a binding condition. Route to solution-architect.

---

## Re-review (rollback #1, focused) — VERDICT: CHANGES REQUIRED (1)

Read-only verification of the SA's bounded rework against the live tree. G.4 mechanism NOT re-litigated.

- **F-1 (`40-locations.md:25`) — RESOLVED.** Live line 25 = `` `.harness/scripts/verify_all` checks (31 items at v0.20.0, all must PASS...) ``; the normalize "31 items"→"32 checks at v0.20.0" reads naturally and is matched by `\(\d+ checks at v\d+\.\d+\.\d+`. Now in BOTH §4 table + §5 ledger.
- **F-2 (`README.zh-CN.md:5`) — RESOLVED.** Live badge `verify__all-31%2F31` confirmed; now in §4 + §5 with the `%2F` pattern. (G.3 covers only the zh-CN version badge, not this count badge — correctly noted.)
- **F-3 (parenthesized regex) — INCORPORATED.** §4 + §9-R10 bind the Developer to `\(\d+ checks\)`. Verified the discriminator: README Roadmap rows 260-268 + CHANGELOG rows use BARE forms (`stays 30 checks`, `30 → 31`), so a parenthesized pattern matches only README.md:159 and never the history rows. Protection real + necessary.
- **Pin-comment condition — BOUND.** §6 binds the "G.4 MUST remain LAST" comment in BOTH shells. Summary tripwire left RECOMMENDED (not REQUIRED) — acceptable (pin-comment satisfies the condition; tripwire is a ~2-line backstop, not AC-load-bearing).
- **`dev-map.md:133` self-catch — CORRECT.** Live line 133 = `runs all 31 checks (at v0.20.0)` (version in its own parens), not matched by `\d+ checks at v…`; the new `runs all \d+ checks \(at v\d+\.\d+\.\d+\)` sub-pattern is right. Both dev-map lines (60 + 133) now gated.
- **1:1 ledger — internally consistent for the 9 listed lines**, and `manual-e2e-test.md:3`'s `57/53` self-tally correctly EXCLUDED from G.4 (R6-scoped recount). BUT the ledger is not the COMPLETE set of live count claims (see F-5).

### F-5 (must-fix) — `.harness/scripts/baseline.json:10` `"verify_all_checks": 31`
A live, machine-readable, hand-maintained verify_all count claim, missing from §4 + §5. Evidence it's the L14 drift class: CHANGELOG:120 (`baseline.json: verify_all_checks 30 → 31`), CHANGELOG:260/:291 (`unchanged at 30` in patch releases — release-tracked); verify_all.{ps1,sh} do NOT read this field (grep: 0 hits) → pure hand-maintained drift surface. After G.4 → 32, baseline.json says 31, uncaught. Add to §4 (G.4 row: substring `"verify_all_checks": $count`) + §5 (31→32 edit). Same shape as F-1/F-2.

### F-6 (note, non-blocking) — `docs/system-overview.html:230,691` (`31 verify checks` / `31 项检查`)
Live `31`-claims, but HTML (design excludes HTML from G.4 per F-4 / walkthrough.html:717 precedent) AND untracked (`?? docs/system-overview.html`), a stale standalone snapshot (its own badge reads `v0.18.2`). Consistent with F-4 → no gate action; SA should add a one-line F-4-style note so §5's exhaustiveness claim explicitly covers this newly-appeared file.

**GATE VERDICT: CHANGES REQUIRED (1)** — exhaustiveness re-scan found `baseline.json:10` `"verify_all_checks": 31`, a live hand-maintained count claim of the same L14 drift class, missing from §4 G.4 table + §5 ledger. Bounded edit → solution-architect (G.4 mechanism unchanged).

---

## Re-review #2 (rollback #2, convergence confirmation) — VERDICT: APPROVED FOR DEVELOPMENT

Independent exhaustive grep over the live tree, cross-checked against the SA's §5.1 EXHAUSTIVE LEDGER. G.4 mechanism settled (not re-litigated).

- **F-5 (`baseline.json:10` `"verify_all_checks": 31`) — RESOLVED.** In §4 (string-substring `"verify_all_checks": $count`, no JSON parse — verify_all doesn't read the field) + §5. L13 symmetry stated.
- **F-7 (`README.zh-CN.md:159` `（30 项检查）`) — RESOLVED.** Live line confirmed stale at 30 (EN twin reads 31); gated 30→32 with full-width-paren `（\d+ 项检查）` pattern; bare zh roadmap rows (262-270) excluded. §4 row 9 + §5.
- **F-6 (`system-overview.html` ×4 lines: 230/288/584/691) — EXEMPTION DEFENSIBLE.** Untracked, banner reads v0.18.2, HTML; consistent with F-4 walkthrough.html precedent + L18 labeled-snapshot exemption.
- **CONVERGENCE CHECK — independent exhaustive sweep (`verify_all_checks`, `%2F3\d`, `31/31`, `31 checks/items/项`, `项检查`, `\b30\b`/`\b31\b`/`\b32\b` near check/verify):** every live, tracked, non-historical count claim is in the 11 BUMP+GATE rows. ZERO new claims. `\b32\b` sweep → no half-bumped doc. All exempt hits fall in stated classes.
- **1:1 integrity — CONFIRMED 11↔11.** §4 G.4 table = 11 count rows (10 doc + baseline.json substring) + 1 CHANGELOG presence row; §5.1 ledger = 11 BUMP+GATE. Map 1:1 by file:line.
- **Uniform target 32 — CONFIRMED.** All 11 land at 32 in one commit (baseline 31→32; zh:159 double-jump 30→32 reconciling staleness; rest 31→32). G.4's derived `$report.Count + 1` = 32 validates all against one source.
- **Insight compliance — sound.** L14 (the drift class) now fully gated; L13 symmetry on new rows; G.4 last + pin-comment bound; L18/L26 HTML exemption pre-established; L20/L23 N/A.

Non-blocking note: `docs/tasks.md:21,22` `31/31 PASS` are frozen "Completed tasks" delivery records (bare-form, no `at vX` adjacency → no G.4 pattern matches them; bumping would falsify T-006/T-007 records). Stated-rule-covered + pattern-immune; not a gap, no rework.

**GATE VERDICT: APPROVED FOR DEVELOPMENT** — the §5.1 ledger is genuinely exhaustive (11 BUMP+GATE, 1:1 with G.4, uniform target 32), independent sweep found zero new live claims, F-5/F-7 resolved, F-6 defensible. No 3rd rollback; no escalation.
