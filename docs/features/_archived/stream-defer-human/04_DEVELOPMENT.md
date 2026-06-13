# Development Record · T-022 `stream-defer-human`

## Summary
`/harness-stream` now DEFERS a task needing human input (new distinct `needs-human` status) instead of blocking: it records the exact ask, blocks only that row's `Depends on` descendants, keeps draining everything runnable, and surfaces all asks together at stream end (FIRST `## Needs your input` section of STREAM_REPORT.md + the exit message leads with the digest). pm-orchestrator returns a self-identifying `BLOCKED: NEEDS-HUMAN — …` verdict under a stream and never auto-decides a human-reserved point to dodge blocking. Editorial/contract change only — no executable logic, no new file, no new `verify_all` check. Version 0.32.0 → 0.33.0.

## Files changed
- `skills/harness-stream/SKILL.md` — description frontmatter +defer clause; `allowed-tools` -`AskUserQuestion`; ambient step 1 (:76) + Procedure 3a (:115) ambiguity sentences → record-and-keep-draining; step b resume set +`needs-human`; step d dispatch (:120) +`deferred-human mode: defer, do not ask` signal; step e (:121) verdict list +`BLOCKED: NEEDS-HUMAN`; step g (:123-126) THIRD outcome arm (`needs-human`, descendants-only, never-perform, never-halt); step h tally +`needs-human`; Stop conditions +(c)/(d) bright line; On stream completion → report leads with `## Needs your input` + exit-message-leads sentence + new "Deferred-human queue" subsection (STREAM_LOG line + report entry formats); Hard rules +needs-human-is-best-effort.
- `agents/pm-orchestrator.md` — "When to stop and ask the user" (:193→) reconciled with stream dispatch (interactive vs stream branch; structured return; no-auto-decide; hard-safety-not-a-deferral); new Hard rule 6.
- `docs/batches/_template/BATCH_PLAN.md` (:27) — Status enum +`needs-human` value.
- `docs/batches/README.md` — Streams section +defer sentence.
- `README.md` + `README.zh-CN.md` — version badge 0.32.0→0.33.0; headline stream bullet +deferred-human clause; new append-only `0.33.0` milestone row.
- `CHANGELOG.md` — new `## [0.33.0] - 2026-06-13` section (matches prior heading format; counts stated 15/32).
- `.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json` — version → 0.33.0.
- `.harness/scripts/ambient-prompt.{ps1,sh}` + `skills/harness-init/templates/common/.harness/scripts/ambient-prompt.{ps1,sh}` — the one ambiguity sentence replaced ASCII-only, 4-file lockstep (surrounding pre-existing non-ASCII untouched).

NOT edited (per F-2 / scope): `skills/harness-batch/SKILL.md`, any test driver, `verify_all.{ps1,sh}`, any `*.html`, `docs/getting-started.md` (F-3 optional), `.harness/rules/*`. (`docs/tasks.md` was touched by the pipeline/PM, not by the Developer.)

## verify_all result
- Baseline (before changes): bash PASS 32 / WARN 0 / FAIL 0 · PowerShell PASS 32 / WARN 0 / FAIL 0.
- After changes: bash PASS 32 / WARN 0 / FAIL 0 · PowerShell PASS 32 / WARN 0 / FAIL 0.
- Delta: 0 new failures, 0 new warnings; baseline preserved. Count stays 32 checks / 15 skills.
- Regression drivers (captured): test-init bash 270/0 · ps 308/0; test-real-project bash 90/0 · ps 90/0; test-supervisor bash 45/0 · ps 49/0 (all green; no driver edited).

## Binding-condition compliance
- **F-1 (ASCII-only ambient edit):** the 4 carriers' new sentence (sh:54-55, ps1:57-58) verified pure ASCII via `grep -nP '[^\x00-\x7F]'` = 0 hits on the new lines; the surrounding pre-existing em-dashes / `≡` (sh:50,53 / ps1:53,55 region) were NOT rewritten. No dependency on the (unimplemented) console-encoding fix; the false "already neutralizes" clause was not transcribed anywhere.
- **F-2 (batch out of scope):** `skills/harness-batch/SKILL.md` not edited; no `deferred-human mode` signal added to batch (`grep` = 0). CHANGELOG states batch correctly: "halt policy keys on a `FAILED` verdict, not `BLOCKED`, so it merely receives a richer message; its behavior is unchanged" — no "batch keeps stopping on it" claim.
- **Standing AC:** verify_all 32/0/0 both shells; G.3 four-way version all `0.33.0` (plugin.json + marketplace.json + 2 README badges); G.4 `[0.33.0]` heading present + counts 32/15 unchanged; ambient 4-file byte-lockstep verified (`cmp` dogfood↔template per extension = IDENTICAL; ps1↔sh emitted block CR-stripped = IDENTICAL; `{{` token = 0); `agents/pm-orchestrator.md` = 206 lines (≤300); I.6 PASS (no banned anchor touched).

## Verification commands run (captured, not fabricated)
- `bash .harness/scripts/verify_all.sh` → 32/0/0
- `pwsh -NoProfile -File .harness/scripts/verify_all.ps1` → 32/0/0
- `bash test-init.sh` 270/0 · `pwsh test-init.ps1` 308/0
- `bash test-real-project.sh` 90/0 · `pwsh test-real-project.ps1` 90/0
- `bash test-supervisor.sh` 45/0 · `pwsh test-supervisor.ps1` 49/0
- C-4: `cmp` per extension (IDENTICAL ×2); CR-stripped ps1↔sh emitted block (IDENTICAL); `grep -nP '[^\x00-\x7F]'` new lines (0); `grep '{{'` ×4 (0).

## Final line counts
- `skills/harness-stream/SKILL.md` = 199 lines.
- `agents/pm-orchestrator.md` = 206 lines (cap 300).

## Design drift
None. All edits applied per design §2-§9 verbatim sites. The design's STREAM_LOG/report entry formats (§3) were added as a "Deferred-human queue" subsection under "On stream completion" so step g's "append a `NEEDS-HUMAN` line" and "record the queue entry" reference a concrete in-skill format — within design §3/§7 intent, not a deviation.

## Open issues for review
- None blocking. The `union ≡ the message` line in the ambient block (sh:53 / ps1:55) still carries a pre-existing `≡` (and the header em-dashes) — left untouched per F-1; DEFECT-1 (console-encoding fix) remains a separate backlog item, out of scope here.

## Dev-map updates
None — no module/folder added, moved, or removed (only the standard per-task `docs/features/stream-defer-human/` doc folder).

## Verdict
READY FOR REVIEW
