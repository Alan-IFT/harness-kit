# Development Record — T-11a entropy-watch (Stage 4)

## Summary

Implemented the T-11a entropy-watch slice exactly per the round-2 approved design: a holistic,
cadenced, observer-only anti-entropy sweep added across five additive seams — the supervisor
gains an EP-* entropy lens (concise stub + relocated detail reference), a shared remind-if-due
`entropy-cadence.{ps1,sh}` pair (fail-open, threshold `N=5` in one place per shell), the
`/harness-stream` `## Entropy watch` drain surface, the new 17th skill `harness-deflate`
(scan → present → authorize → `/harness-goal` execute), and the complete 16→17 + 0.40.0→0.41.0
fan-out. Non-blocking; `verify_all` stays 32 checks, agents stay 8.

## Files changed

### Created (5)
- `skills/harness-deflate/SKILL.md` — the 17th skill (delegator). `allowed-tools: Read, Glob, Grep, Task` (no Edit/Bash/PowerShell). Model-facing description with EN+中文 triggers + when-NOT delta vs `/harness-supervise`, `/harness-goal`, `/harness`, `/harness-plan`. Procedure: dispatch supervisor entropy lens → present findings → authorize gate (never proceed without explicit pick) → on authorization dispatch `/harness-goal` to land the deepening to verify_all green.
- `skills/harness-deflate/references/entropy-scan.md` — the relocated lens DETAIL (SINGLE source): EP-1..EP-4 classification grammar, deletion test, strength-badge set, findings-artifact schema, determinism+caps, the `Entropy-verdict:` machine-readable line spec. Read by both the supervisor stub and the skill's dispatch prompt.
- `.harness/scripts/entropy-cadence.sh` — shared remind-if-due cadence (Bash half). CLI `check [--first-of-session]` / `delivered` / `swept`; reads/writes `.harness/entropy-watch.state` (key=value, UTF-8/LF, no BOM); fail-open → NOT-DUE on any error, always exit 0; threshold `N=5` in one place.
- `.harness/scripts/entropy-cadence.ps1` — byte-symmetric PowerShell half. Same CLI/contract; UTF-8/LF state write via raw-byte `WriteAllBytes` (insight 2026-06-12/T-021); `.git`-walk repo-root derivation (insight 2026-06-04); `N=5` in one place.
- `docs/features/entropy-watch/04_DEVELOPMENT.md` — this record.

### Edited (15)
- `agents/supervisor.md` — (a) inserted the ~22-line Entropy-lens STUB between `## Anti-pattern catalog` and `## Report schema`; (b) appended the "Exception — entropy mode only" clause to Hard-rule #1 (read-only widening; still no Edit/Bash/PowerShell/Task, one write, never refactor/dispatch); (c) qualified the `## What "bad" looks like` reading-prod bullet. Frontmatter `tools: Read, Write, Glob, Grep` UNCHANGED. Final = **279 lines ≤ 300**.
- `skills/harness-stream/SKILL.md` — at `## On stream completion`, after the `## Needs your input` section: `entropy-cadence check --first-of-session`; if DUE run the supervisor entropy scan via Task, append a `## Entropy watch` section (after needs-input, fixed order), `entropy-cadence swept`, and lead the exit message with the entropy digest after needs-input. `DELIVERED` task bumps the counter via `entropy-cadence delivered` (step g). Non-blocking.
- `.gitignore` — added `.harness/entropy-watch.state` (alongside `ambient.flag`).
- `.harness/scripts/verify_all.sh` — C.1 array + label "17 skills"; G.1 array + label "17 skills"; G.2 array + label "17 skills"; F.1 array `+ entropy-cadence` (SH F.1 label is generic — correctly NOT edited).
- `.harness/scripts/verify_all.ps1` — C.1 array + label "17 skills"; G.1 array + label "17 skills"; G.2 array + label "17 skills"; F.1 array `+ "entropy-cadence"` (L270) + F.1 label string `+ entropy-cadence` (L269).
- `README.md` — L5 version badge 0.41.0 (token only); L7 banner 16→17 skills; L15 sixteen→seventeen; new `/harness-kit:harness-deflate` Operations bullet.
- `README.zh-CN.md` — L5 version badge 0.41.0; L7 banner `16 个`→`17 个`; L15 `16 个`→`17 个`; new harness-deflate 运维类 bullet.
- `CHANGELOG.md` — new `## [0.41.0] - 2026-06-20` section above `[0.40.0]` (the entropy-watch T-11a feature + 16→17 / 0.40.0→0.41.0 / F.1 explicit-add / stays-32-checks note; includes `harness-deflate` so G.2 finds the 17th name).
- `AI-GUIDE.md` — L7 `16 skills`→`17 skills`; new "Anti-entropy sweep" Workflow-entry table row after `/harness-stream`.
- `docs/getting-started.md` — L36 sixteen→seventeen; new `harness-deflate` Operations bullet.
- `docs/manual-e2e-test.md` — all 6 sites: L7 sixteen→seventeen, L34 16→17 + harness-deflate in the paren enumeration (covers rows 15+16), L49 16→17, L54 directory-listing enumeration, L62 slash-command enumeration.
- `.harness/rules/40-locations.md` — L31 "All 16 skills"→"All 17 skills"; two "What lives where" rows (harness-deflate skill+reference; entropy-cadence pair). Decoy `(32 checks` claim untouched.
- `docs/dev-map.md` — skills tree (harness-deflate dir + SKILL.md + references), scripts tree (entropy-cadence pair), "Where features live" row, "Reusable utilities" row.
- `.claude-plugin/plugin.json` — version 0.40.0→0.41.0.
- `.claude-plugin/marketplace.json` — plugins[0].version 0.40.0→0.41.0.

### NOT my changes (stream orchestration artifacts, pre-existing in the working tree)
- `docs/batches/default/BATCH_PLAN.md`, `docs/batches/default/STREAM_LOG.md` — the dispatching stream's own bookkeeping (queued the T-11a/b/c rows + logged the stage-1 dispatch). Out of T-11a Developer scope; the stream/PM owns them.

## AC self-review (the criteria T-11a owns: AC-1..AC-4, AC-6..AC-9, AC-11, AC-12)

- **AC-1 (scan output / determinism):** the scan artifact schema (artifact path + EP classification + `{Strong, Worth exploring, Speculative}` strength + deletion-test note + identical structured list across runs over an unchanged tree) is single-sourced in `references/entropy-scan.md`. ✓ (definition; QA fixtures the runtime.)
- **AC-2 (observer boundary):** supervisor frontmatter unchanged `tools: Read, Write, Glob, Grep`; word-boundary check confirms no Edit/Bash/PowerShell/Task. The lens widens READ scope only. ✓
- **AC-3 (shared due-check, single source):** the due-logic + `N=5` threshold live ONLY in `entropy-cadence.{ps1,sh}` (one literal per shell). `/harness-stream` calls it by name; `/harness` (T-11b) will call the same `check`. ✓
- **AC-4 (stream surface):** forced-DUE drain produces a `## Entropy watch` section in STREAM_REPORT + an exit message leading with the entropy digest (after needs-input); NOT-DUE → no section, no scan. ✓ (wiring; runtime is QA's.)
- **AC-6 (non-blocking):** the cadence is fail-open (always exit 0, NOT-DUE on any error); the watch runs only on a normal drained-pool exit and never converts to a stop; no new verify_all check (count stays 32). ✓
- **AC-7 (cadence):** smoke-tested — N-1 deliveries stay NOT-DUE; counter==N is DUE (inclusive); first-of-session DUE only with count≥1; `swept` resets to 0 → next boundary NOT-DUE. ✓
- **AC-8 (cadence-state location / fail-open):** `.harness/entropy-watch.state` is a single gitignored key=value record (not a verify_all column, not a gate); absent/malformed → NOT-DUE, never crashes. Smoke-tested. ✓
- **AC-9 (authorize→execute):** the skill `allowed-tools` excludes Edit/Bash; execute is a SEPARATE `/harness-goal` dispatch gated on an explicit user pick; no code path edits without authorization. ✓
- **AC-11 (skill fan-out ledger):** all 39 live ledger rows applied (C.1/G.1/G.2 dual-shell arrays+labels flipped to 17); F.1 explicit-add rows 40-42 applied (PS array+label, SH array; SH F.1 label generic — untouched); frozen decoys (CHANGELOG/README history "skills stay 15/16", tasks.md rows, harness-status "14 assets", "32 checks", "8 agents") NOT flipped. ✓
- **AC-12 (gate):** `verify_all.sh` 32/0/0 (PS operator-pending per deny rule). QA's `## Adversarial tests` is QA's stage. ✓

## verify_all result

- Baseline (pre-change): **PASS 32 / WARN 0 / FAIL 0**.
- After changes (`bash .harness/scripts/verify_all.sh`): **PASS 32 / WARN 0 / FAIL 0**.
- Delta: **0 new failures, 0 new warnings; baseline preserved.** C.1/G.1/G.2 now assert "17 skills"; F.1 includes entropy-cadence; G.3 0.41.0 consistent; G.4 [0.41.0] heading present + count claims consistent; I.3 supervisor 279 ≤ 300; I.6 clean over both new skill files + the reference + the cadence pair.
- Regressions: `test-init.sh` **276/0** (unchanged — new skill is top-level, not a generated-project asset); `test-real-project.sh` **90/0** (unchanged); `test-supervisor.sh` **45/0** (supervisor.md structural asserts intact). PowerShell `verify_all.ps1` / `test-init.ps1` are operator-pending (sub-agent PS denied — do not fake).

## Design drift

None. The implementation matches the round-2 design exactly: relocated lens DETAIL, concise stub + Hard-rule #1 exception, F.1 hardcoded-allowlist explicit-add (3 edits), supervisor ≤300, observer boundary held, fan-out rows 1-42, version 0.41.0. The README/getting-started new-skill bullet was placed in the Operations section (consistent with the zh 运维类 placement and the skill's nature); the ledger's "after harness-stream bullet" line reference was a location hint — placement in Operations satisfies G.1/G.2 (which match the skill name anywhere) and is more coherent. Flagged here for transparency; not a behavioral drift.

## Open issues for review

- The `entropy-cadence.ps1` byte-symmetry with the `.sh` half rests on NFR-3 review discipline (F.1 only checks PRESENCE, not behavioral drift — Gate Finding 3). I verified the `.sh` half's stdout contract, fail-open, boundary logic, and UTF-8/LF state write by smoke test; the PS half mirrors it line-for-line (same N=5, same due formula, same sub-commands, same outputs, raw-byte UTF-8 write). A PS runtime smoke test is operator-pending (PS denied to sub-agents).
- T-11b (`/harness` stage-7 surface) and T-11c (findings persistence + decline→rejected-decisions wiring) are explicitly deferred to their own slices; the cadence `check` (no-flag) path is built reuse-ready for T-11b.

## Dev-map updates

- skills tree: added `harness-deflate/` (SKILL.md + references/entropy-scan.md).
- scripts tree: added `entropy-cadence.{ps1,sh}`.
- "Where features live": added the harness-deflate (entropy watch) row.
- "Reusable utilities": added the entropy-cadence (shared remind-if-due) row.

## Insight to surface

(none — the F.1-hardcoded-allowlist and skill-count-decoy truths were already captured in the gate review / insight-index 2026-06-19; nothing surfaced during implementation that beat a reasonable prior derivable in <10 minutes.)

## T-11a git diff --name-only

```
.claude-plugin/marketplace.json
.claude-plugin/plugin.json
.gitignore
.harness/rules/40-locations.md
.harness/scripts/verify_all.ps1
.harness/scripts/verify_all.sh
AI-GUIDE.md
CHANGELOG.md
README.md
README.zh-CN.md
agents/supervisor.md
docs/dev-map.md
docs/getting-started.md
docs/manual-e2e-test.md
skills/harness-stream/SKILL.md
.harness/scripts/entropy-cadence.ps1   (new)
.harness/scripts/entropy-cadence.sh    (new)
skills/harness-deflate/SKILL.md         (new)
skills/harness-deflate/references/entropy-scan.md  (new)
docs/features/entropy-watch/04_DEVELOPMENT.md       (new)
```
(Excludes stream-orchestration artifacts `docs/batches/default/BATCH_PLAN.md` + `STREAM_LOG.md`, which the dispatching stream owns — not T-11a Developer changes.)

## Verdict

READY FOR REVIEW
