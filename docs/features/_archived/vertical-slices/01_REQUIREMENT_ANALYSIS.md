# 01 — Requirement Analysis: vertical-slices (T-06)

> Mode: **full** · Analyst stage · deferred-human mode: defer, do not ask.
> Inputs (read-only): `docs/features/vertical-slices/INPUT.md`, the mattpocock/skills reference clone, the live harness-plan/batch/stream skills + BATCH_PLAN template.

## 1. Goal

Add a task-decomposition discipline — **tracer-bullet vertical slices** (each task a thin, independently-verifiable end-to-end slice, not a horizontal layer) plus **smart-zone task-sizing** (size each task to fit one reasoning window) — single-sourced in the harness skill where a design is decomposed into tasks, and referenced by name from the skills/template that author task rows.

## 2. In-scope behaviors

Numbered, testable. "Discipline text" = the concise vertical-slice + smart-zone guidance authored by this task.

1. The discipline text is authored in **exactly one** SKILL.md file (the single source), under a named, stable heading.
2. The discipline text defines the **tracer-bullet vertical slice**: a task is a thin path that cuts end-to-end through every layer the change touches and is independently demoable/verifiable on its own; it is explicitly NOT a horizontal slice of a single layer.
3. The discipline text defines **smart-zone task-sizing**: a task is sized so its full reasoning fits within one model reasoning window (stated as approximately 120k tokens), and a unit of work that would exceed that window is split into smaller slices or handed off before reasoning degrades.
4. The discipline text states the decomposition rule operationally for this repo's artifacts: a good task / pool row is one vertical slice that (a) is independently verifiable, (b) names real consumption dependencies only, and (c) fits the smart zone.
5. Every other location that authors task rows references the single source **by name** (a named heading / skill name), not by pasting a copy of the discipline text and not by a deep relative-path link (`../other/FILE.md`). The locations that must carry such a reference: the two task-consuming skills (`harness-batch`, `harness-stream`) and/or the row-authoring template (`docs/batches/_template/BATCH_PLAN.md`) — final set fixed by the architect, but at minimum the discipline is reachable from the place where pool/batch rows are authored.
6. The discipline text is terse: it adds the two named concepts and the decomposition rule without restating the existing harness-plan / batch / stream procedures.
7. No skill is added and no skill is removed: the count of skills under `skills/` is unchanged after this task (editing existing skills, not adding one).
8. No `verify_all` check is added, removed, or renumbered by this task; the check count is unchanged.
9. The BATCH_PLAN.md **column schema** (`ID | Slug | Goal | Mode | Depends on | Status`) is unchanged.
10. After this task, top-level `skills/` edits require no `harness-sync` run (the `.harness/skills/` mirror is empty); this is confirmed-and-relied-on, not changed.
11. The repo passes `.harness/scripts/verify_all` with the same PASS/total it had before the change (no new WARN, no new FAIL introduced by the edit).
12. If the edited SKILL.md files are distributed plugin content (shipped to users), the change carries a semantic-version bump in `.claude-plugin/plugin.json` (and its mirrored version surfaces) plus a CHANGELOG entry, per the shipped-content precedent; the bump does not change any "N skills" or "N checks" count claim.

## 3. Out-of-scope

1. Rewriting the harness-plan / harness-batch / harness-stream procedures (only an additive discipline section + references).
2. Changing the BATCH_PLAN.md column schema.
3. Adding a new `verify_all` check or a new guard for the discipline (per [[feedback_design_over_guards]]; the discipline is authoring guidance, not a gate).
4. Importing the GitHub-issue-tracker template (`<issue-template>`, triage labels, publish-to-tracker, quiz-the-user loop) from mattpocock's `to-issues` verbatim — this repo uses BATCH_PLAN rows, not an issue tracker.
5. Adding the mattpocock context-hygiene / `/handoff` / `/compact` / `/prototype` flow (those are separate skills not in this repo's scope here).
6. Changing the ingest-triage decomposition logic in `harness-stream` (the existing "one row or many" triage stays as-is; this task adds the *quality bar* for what a good row is, not new triage mechanics).
7. Adding the discipline to any agent (`agents/*.md`) — the home is a skill, not a pipeline agent.

## 4. Boundary conditions

1. **Single-source target stability** — the referenced heading/anchor in the single source must be a stable name that the referencing files can name without a line number (forward-looking references carry no file:line per Hard rule 6).
2. **No duplication** — the discipline's defining sentences appear in exactly one file; the other files contain only a by-name pointer. (Single source of truth; rule 15 named handle.)
3. **I.6 retired-claim guard** — the added text introduces no banned anchor phrase; the doc is saved UTF-8 so no anchor self-trips.
4. **Doc-size** — additions are terse; no edited SKILL.md is pushed over its `70-doc-size.md` soft cap (skills have no hard line cap in `verify_all`, but the cap + token economy apply).
5. **Count-claim integrity** — the change must not contradict any "16 skills / 8 agents / 32 checks" claim; if a version bump occurs, count claims stay pinned to their already-true values (G.4 gate would FAIL on a count/version contradiction).
6. **Empty `.harness/skills/` mirror** — relied upon, not modified; if it were non-empty the edit would require `harness-sync`, but it is empty (verified).
7. **Smart-zone number** — the "~120k tokens" figure is stated as an approximate heuristic, not a hard gate; no code enforces it.
8. **Cross-shell / Windows** — this is a Markdown-only edit; no `.ps1`/`.sh` parity surface is touched, so no cross-shell byte-identity concern arises.

## 5. Acceptance criteria

Each is verifiable by inspection, grep, or `verify_all`.

- **AC-1** The two named concepts (tracer-bullet vertical slice; smart-zone ~120k task-sizing) are both present and defined in exactly one SKILL.md file.
- **AC-2** A grep for the discipline's defining sentences returns hits in only that one file (no pasted duplicate in the other skills / template). Pointers elsewhere reference it by name only.
- **AC-3** Each row-authoring location (`harness-batch`, `harness-stream`, and/or `docs/batches/_template/BATCH_PLAN.md` — per the architect's chosen set) contains a by-name reference to the single source; none contains a deep `../other/FILE.md` path link.
- **AC-4** The vertical-slice definition explicitly states "NOT a horizontal slice of one layer" (the discriminating clause) and "independently demoable/verifiable on its own".
- **AC-5** The smart-zone definition states the approximate window size and the "split or hand off before degrading" action.
- **AC-6** `skills/` skill count is unchanged (16) — grep / directory count before vs after.
- **AC-7** `verify_all` check count is unchanged (32); no new check file/block.
- **AC-8** BATCH_PLAN.md column header row is byte-unchanged.
- **AC-9** `.harness/scripts/verify_all` PASSes at the same total it had at task start (no new WARN/FAIL from the edit).
- **AC-10** If the edit is shipped plugin content: `plugin.json` version is bumped one semantic step, a CHANGELOG `## [x.y.z]` entry describes the change, and the bump introduces no count-claim contradiction (G.4 green). If the architect demonstrates with evidence the edit is dogfood-only (not distributed), no version bump is required — but the SKILL.md files under `skills/` ARE the distributed plugin content, so the default expectation is a bump (see OQ-1).
- **AC-11** No `agents/*.md` and no BATCH_PLAN column schema changed.

## 6. Non-functional requirements

- **NFR-1 (token economy)** Additions are terse — the discipline is single-sourced (one definition) rather than tripled across three skills; net added lines minimized. (`70-doc-size.md`, rule 15 P2 no-op test, single-source-of-truth handle.)
- **NFR-2 (compose-by-name)** References resolve by name per rule 15 P8, matching how the 7-stage pipeline and existing skills reference siblings — no new cross-file pathing convention introduced.
- **NFR-3 (durability)** Per requirement-analyst Hard rule 6, the discipline text and references are behavioral/by-name and carry no forward-looking file:line anchors (those go stale). Backward-looking evidence citations are exempt (not applicable here — this is authoring text, not an evidence section).

## 7. Related tasks

- **T-05 / `durable-brief`** (`docs/features/_archived/durable-brief/`) — shipped the single-source-of-truth handle in practice: a discipline defined once in one agent and referenced (not restated) by another. This task applies the same single-source + reference-by-name pattern to skills. Also the source of Hard rule 6 (no forward-looking file:line in forward-looking specs).
- **T-04 / `skill-authoring-vocab`** (`docs/features/_archived/skill-authoring-vocab/`) — added the "single source of truth" and "compose by name" named handles to `.harness/rules/15-skill-authoring.md`; this task is a direct application of those handles. (Note: T-04 was dogfood-rule-only → no version bump; this task edits distributed skill content → bump expected — the distinction in OQ-1.)
- **T-02 / `context-glossary`** and **T-03 / `harness-grill`** — sibling items of the same mattpocock/skills adoption batch; show the pattern of folding one external idea into harness-kit's own surfaces additively.
- **harness-batch-skill (T-006, archived)** and **ambient-stream / stream-auto-decompose / stream-defer-human** — established the BATCH_PLAN row model and the stream's ingest-triage that this discipline's "good row" quality bar sits alongside.

## 8. Open questions for user (deferred-human mode: recommended answer given, not asked)

Per deferred-human mode these are resolved by the **Recommended** answer below and passed to the architect; none blocks. They are recorded for traceability and operator override.

**OQ-1 — Version bump?**
The edited SKILL.md files live under top-level `skills/`, which `plugin.json` declares as distributed plugin content (`"skills": "./skills/"`). Editing distributed skill content is a shipped change.
- (a) Bump the patch/minor version + add a CHANGELOG entry (treat as shipped content, like every prior SKILL.md edit).
- (b) No bump (treat as internal authoring guidance, like the T-04 dogfood-rule edit).
- **Recommended: (a)** — a minor bump (0.36.0 → 0.37.0), because the change adds user-visible decomposition behavior to three shipped skills, unlike T-04 which edited a non-distributed `.harness/rules/` fragment. NO count claim flips (still 16 skills / 8 agents / 32 checks).

**OQ-2 — Where is the single source?**
- (a) A new short section in `skills/harness-plan/SKILL.md` (where a design is decomposed into tasks).
- (b) A new short section in `docs/batches/_template/BATCH_PLAN.md` `## Column reference` (where rows are authored).
- (c) A new shared note file referenced by all.
- **Recommended: (a)** — harness-plan is the canonical decomposition step and is named by the batch/stream skills' "When NOT to invoke" tables already, so a by-name reference to a harness-plan section is natural and avoids a new shared file. The architect confirms the exact heading.

**OQ-3 — Which files carry the by-name reference?**
- (a) Both task-consuming skills (`harness-batch`, `harness-stream`) + the BATCH_PLAN template.
- (b) Only the BATCH_PLAN template (the one place rows are physically authored).
- (c) Only the two skills.
- **Recommended: (a)** — the template is where a human authors rows by hand and the two skills are where the stream/batch normalize rows, so all three benefit from a pointer; each is a one-line by-name reference (cheap, NFR-1 honored). The architect may narrow to the row-authoring template + harness-stream ingest if duplication of the pointer itself becomes noise.

**OQ-4 — Smart-zone number wording.**
- (a) State "~120k tokens" explicitly (matches the source).
- (b) State "one reasoning window" without a number (number ages with models).
- **Recommended: (a) with a hedge** — state "approximately one reasoning window (~120k tokens on current state-of-the-art models)" so the heuristic is concrete but explicitly model-relative and not a hard gate.

## 9. Verdict

**READY.**

All ambiguities are resolved by recommended answers under deferred-human mode (defer, do not ask); none is a hard blocker and each carries a concrete default the architect can adopt or the operator can override. The single-source home, the reference set, the no-count-change / no-new-check constraints, and the version-bump expectation are all testable. The live file structure (harness-plan's Procedure step where decomposition happens; the batch/stream skills already referencing siblings by name; the BATCH_PLAN template's `## Column reference`) supports a clean single-source + reference-by-name implementation. The architect proceeds with the recommended defaults unless the operator overrides.
