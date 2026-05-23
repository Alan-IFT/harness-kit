# 03 — Gate Review

## Scope of this review

This Gate Review covers the `01_REQUIREMENT_ANALYSIS.md` and `02_SOLUTION_DESIGN.md` produced by PM (transcribed from the interactive brainstorming session). The user explicitly selected 方案 A out of three architectural options during that session; this Gate Review confirms the transcribed design matches what the user approved and surfaces any risks Developer should mitigate.

## Findings

### F-1: Requirement completeness — OK

The 10 acceptance criteria in `01_REQUIREMENT_ANALYSIS.md` cover the user's three stated principles (UX, SWE-standards, maintainability) and the two AskUserQuestion responses (multi-source tasks, full-autonomy-with-strong-signal-stop). The "out of scope" section explicitly defers four reasonable items (auto-import, parallel, retry, plan-to-batch generation) to future versions — preventing scope creep without losing them.

### F-2: Design coherence — OK

方案 A keeps pm-orchestrator's contract unchanged. The new skill sits **strictly above** pm-orchestrator, dispatches one task at a time, and only sees per-task summaries. This satisfies the context-bloat concern raised by the user: the batch skill itself accumulates ~5 lines per task in BATCH_LOG.md, dispatches each task's full machinery into a sub-agent context. No multi-level agent nesting is required.

### F-3: Dogfood symmetry — OK

The new skill follows the same structure as the existing `/harness-goal`: a SKILL.md with allowed-tools including `Task`, a procedure that uses TodoWrite for tracking, sequential per-iteration (here per-task) dispatch, stop signals on `verify_all` regression. Users already familiar with `/harness-goal` will find `/harness-batch` self-explanatory.

### F-4: Version-bump correctness — OK

v0.18.2 → v0.19.0 is the right semver bump (MINOR for new feature, no breaking changes). The four version-stamp locations (plugin.json, marketplace.json, README.md badge, README.zh-CN.md badge) are correctly identified. Note: G.3 will FAIL hard if any of the four is missed; Developer must update all in the same commit.

### F-5: `verify_all` hardcoded skill-list update — POTENTIAL FOOTGUN

Three locations in EACH of `verify_all.{ps1,sh}` hardcode the 10-skill list (C.1, G.1, G.2). The new skill must be added to all six locations. Missing any one will cause `verify_all` to FAIL at the corresponding check. Per Insight L5, this is the exact failure mode (release ships features but leaves verify_all lists stale) that has happened before. Developer: do a final `grep -n 'harness-supervise' scripts/verify_all.*` after edits to confirm the new skill appears in all six places.

### F-6: BATCH_LOG.md vs BATCH_REPORT.md distinction — OK

The design distinguishes the append-only event log (BATCH_LOG.md, written during execution) from the terminal summary (BATCH_REPORT.md, written once at end). This matches the existing pattern of PM_LOG.md vs 07_DELIVERY.md in single-task mode. Good separation of concerns.

### F-7: Resume semantics — slight concern, not a blocker

The resume rule "if `07_DELIVERY.md` exists AND verdict is `DELIVERED` → mark done, skip" relies on parsing the verdict from a markdown file. This is brittle if the delivery doc format changes (e.g. someone reorders sections). Recommendation for Developer: keep the verdict parser tolerant (search the file for any line matching `^- Final verify_all result: PASS` as a secondary fallback), and document the parsing rule in the SKILL.md so future agents know what they're relying on. Not blocking — current single-task pm-orchestrator does similar markdown parsing.

### F-8: Document size discipline — OK

- skills/harness-batch/SKILL.md: target ~180 lines (no cap on SKILL.md files, but our existing skills run 80-180; we're in range).
- docs/batches/README.md: target ≤80 lines per AC-6.
- 01-03 stage docs: this Gate Review + the analyses + design total ~350 lines, comfortably under the rule 70 soft cap on per-task docs.
- AI-GUIDE.md new row: +1 line, no cap concern (current 99/200).
- CHANGELOG.md new section: ~30 lines, no cap.

### F-9: No new `.harness/rules/` fragment needed — confirmed

The skill operates entirely on existing patterns (insight-index, intervention.md, archive-task). No new project-level invariant emerges. If, after real use, a new rule emerges (e.g. "batches must have a goal-statement"), add a rule fragment then — not now.

### F-10: No template changes — confirmed

Skills are distributed via the Claude Code Plugin manifest (`plugin.json` `skills: ./skills/`), not via `templates/common/` overlay. New skill ships to users automatically when they install the plugin; no `sync-self` mirroring needed.

## Verdict

**APPROVED FOR DEVELOPMENT**

The design is internally consistent, matches the user's explicit selection of 方案 A, respects existing pipeline contracts, and has clear acceptance criteria. The two attention items (F-5: 6-location hardcoded list update; F-7: verdict-parsing tolerance) are surfaced for Developer to mitigate during implementation.

PM may proceed to dispatch Developer.
