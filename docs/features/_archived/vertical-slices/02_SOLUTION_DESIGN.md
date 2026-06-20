# 02 — Solution Design: vertical-slices (T-06)

> Mode: **full** · Architect stage · deferred-human mode: defer, do not ask.
> Upstream: `01_REQUIREMENT_ANALYSIS.md` verdict = **READY**. PM accepted the RA's recommended OQ defaults.
> OQ defaults adopted (PM-accepted): OQ-1 → (a) bump 0.36.0 → 0.37.0 · OQ-2 → (a) single source in `skills/harness-plan/SKILL.md` · OQ-3 → (a) all three (batch + stream + BATCH_PLAN template) carry a one-line by-name pointer · OQ-4 → (a)+hedge "~120k tokens on current state-of-the-art models".

## 1. Architecture summary

This is a Markdown-only, additive authoring-discipline change to shipped plugin content. One new short section — the **task-decomposition discipline** (tracer-bullet vertical slice + smart-zone sizing) — is authored ONCE in `skills/harness-plan/SKILL.md` (the canonical "decompose a design into tasks" step) under a stable heading. The three places that author task/pool rows — `skills/harness-batch/SKILL.md`, `skills/harness-stream/SKILL.md`, and `docs/batches/_template/BATCH_PLAN.md` — each gain a single by-name pointer to that section (compose-by-name per rule 15 P8 + single-source-of-truth per T-04), never a pasted copy and never a deep `../other/FILE.md` link. Because the edited SKILL.md files are distributed plugin content, the change carries a minor version bump (0.36.0 → 0.37.0) + CHANGELOG entry. No skill is added/removed (16 held), no `verify_all` check is added/removed (32 held), no column schema changes, and no `harness-sync` is needed (the `.harness/skills/` mirror is empty — skills are edited directly under top-level `skills/`).

## 2. Affected modules

| File | New / Edit | Role |
|---|---|---|
| `skills/harness-plan/SKILL.md` | edit (new section) | **single source** of the discipline |
| `skills/harness-batch/SKILL.md` | edit (1 line) | by-name pointer |
| `skills/harness-stream/SKILL.md` | edit (1 line) | by-name pointer |
| `docs/batches/_template/BATCH_PLAN.md` | edit (1 line) | by-name pointer (in `## Column reference`) |
| `.claude-plugin/plugin.json` | edit (version) | G.3 stamp |
| `.claude-plugin/marketplace.json` | edit (`plugins[0].version`) | G.3 stamp |
| `README.md` | edit (version badge) | G.3 stamp |
| `README.zh-CN.md` | edit (version badge) | G.3 stamp |
| `CHANGELOG.md` | edit (prepend `## [0.37.0]`) | G.4 claim/version record |

No `agents/*.md`, no `.harness/scripts/*`, no `verify_all`, no template under `skills/harness-init/templates/`, no `CONTEXT.md`, no `.harness/rules/*`, no `.harness/insight-index.md` touched.

## 3. The single-source section (EXACT text + insertion point)

**Home:** `skills/harness-plan/SKILL.md`.
**Heading (stable name the pointers reference):** `## Task-decomposition discipline`.
**Insertion point:** AFTER the `## Procedure` block (which ends at the resumable-output paragraph, current line 39) and BEFORE `## Output` (current line 41). Rationale: the Procedure step 5 produces `02_SOLUTION_DESIGN.md` (where a design becomes tasks); the discipline is the quality bar ON that decomposition, so it reads naturally immediately after the procedure and before the output manifest. It is additive — the Procedure steps are unchanged.

**Exact section text to insert** (terse — two named concepts + one operational rule; no restatement of the harness-plan/batch/stream procedures):

```markdown
## Task-decomposition discipline

When you split a design into tasks (or pool/batch rows), each task is a **tracer-bullet vertical slice**, sized to the **smart zone**:

- **Tracer-bullet vertical slice** — a task is a thin path that cuts end-to-end through *every layer the change touches* (e.g. schema → API → UI → tests) and is independently demoable/verifiable on its own. It is **NOT a horizontal slice of one layer** (not "all the schema", then "all the API"). A completed slice ships value alone; a half-finished horizontal layer ships nothing.
- **Smart zone** — size a task so its full reasoning fits one model reasoning window (approximately one window, ~120k tokens on current state-of-the-art models — a heuristic, not a hard gate). A unit of work that would overflow that window is split into smaller vertical slices, or handed off, **before** the model degrades.

**A good task / pool row** is therefore one vertical slice that (a) is independently verifiable, (b) names only real consumption dependencies (`Depends on` = "this row uses an artifact the other row produces", never "same area"), and (c) fits the smart zone.
```

This satisfies AC-1 (both concepts defined in one SKILL.md), AC-4 (explicit "NOT a horizontal slice of one layer" + "independently demoable/verifiable on its own"), AC-5 (window size + "split or hand off before degrading"), behavior 4 (operational good-row rule with the three sub-conditions), and behavior 6 (terse — no procedure restatement). The `Depends on` parenthetical reuses the stream's own "REAL consumption" wording (harness-stream Ingest-triage "Depends on" line) so the discipline aligns with the existing triage rule rather than contradicting it.

## 4. The three by-name pointers (EXACT one-liners + insertion points)

Each pointer names the single source by **skill name + heading** (compose-by-name; no `../` path). All three are honored (OQ-3 (a)) because each is a genuinely distinct authoring surface: the template is where a human hand-authors rows, harness-stream is where chat/ambient ingest normalizes rows, harness-batch is where a frozen list is parsed. None of the three pointers is noise — see §10 for why none is narrowed.

**4a. `skills/harness-batch/SKILL.md`** — append to the existing `## Required input` section (after current line 34, the "copy it … fill in the task table, then re-invoke" paragraph), where a user is told to fill the task table:

```markdown
When you author the rows, make each one a tracer-bullet vertical slice that fits the smart zone — see `harness-plan` → "Task-decomposition discipline".
```

**4b. `skills/harness-stream/SKILL.md`** — append one sentence to the END of the `## Ingest triage (one row or many)` section (after current line 103, the "resume, de-dup, SKIP, edits, and failure semantics apply identically" paragraph). This is where the stream normalizes natural language into rows, so the quality bar belongs adjacent to the triage mechanics (it does NOT change the triage logic — behavior 6 / out-of-scope 6):

```markdown
Each row the triage writes (and each hand-authored row) should be a tracer-bullet vertical slice sized to the smart zone — see `harness-plan` → "Task-decomposition discipline" for what makes a good row.
```

**4c. `docs/batches/_template/BATCH_PLAN.md`** — append one bullet to the `## Column reference` section (after the existing `**Status**` bullet, current line 27), since that section already defines what each column means and a human authoring rows reads it:

```markdown
- **What makes a good row** — each row should be a tracer-bullet vertical slice (a thin end-to-end change, independently verifiable, NOT a horizontal layer) sized to the smart zone (~120k-token reasoning window). See `harness-plan` → "Task-decomposition discipline".
```

These satisfy AC-2 (pointers reference by name only; defining sentences live only in harness-plan), AC-3 (all three row-authoring locations carry a by-name reference; none uses a deep `../other/FILE.md` link), behavior 5 (reachable from where rows are authored), and NFR-2 (compose-by-name, matching how batch/stream already name `/harness-plan`).

## 5. Data model / API / schema changes

None. No code, no schema, no `verify_all` check, no JSON config except the version stamps. The BATCH_PLAN column schema (`ID | Slug | Goal | Mode | Depends on | Status`) is byte-unchanged (behavior 9 / AC-8 / AC-11). The 4c pointer is appended to `## Column reference` PROSE, not to the table header row.

## 6. Flow (how the discipline reaches an author)

```
design (02_SOLUTION_DESIGN.md) ─decompose→ tasks/rows
        │
        ├─ /harness-plan author reads ── harness-plan §"Task-decomposition discipline"  ◀── SINGLE SOURCE
        │
        ├─ /harness-batch author reads ─ harness-batch §"Required input" ──by name──▶ (same section)
        ├─ /harness-stream ingest reads  harness-stream §"Ingest triage" ──by name──▶ (same section)
        └─ human filling template reads  BATCH_PLAN §"Column reference"  ──by name──▶ (same section)
```

One definition; three named pointers resolve to it. Editing the discipline later changes exactly one file (single source of truth).

## 7. Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| Single-source a discipline + reference by name | T-04 "single source of truth" + "compose by name" handles | `.harness/rules/15-skill-authoring.md` (P8 + Named-vocabulary "Single source of truth") | Reuse as the governing pattern — define once, point by name |
| By-name skill reference convention | batch/stream already name `/harness-plan` in prose | `skills/harness-batch/SKILL.md:13,26`; `skills/harness-stream/SKILL.md:26` | Reuse the same convention; no new pathing introduced |
| "REAL consumption" dependency wording | stream Ingest-triage `Depends on` rule | `skills/harness-stream/SKILL.md:97` | Reuse the phrasing in the good-row rule so they agree, not duplicate-and-drift |
| Vertical-slice / tracer-bullet definition | mattpocock `to-issues` `<vertical-slice-rules>` | `c:\Programs\_research\mattpocock-skills\skills\engineering\to-issues\SKILL.md:29-35` | Adapt the concept (thin end-to-end path, demoable alone, NOT a horizontal layer); do NOT import the issue-tracker template/quiz/publish flow (out-of-scope 4) |
| Smart-zone framing | mattpocock `ask-matt` smart-zone | `c:\Programs\_research\mattpocock-skills\skills\engineering\ask-matt\SKILL.md:30` | Adapt the ~120k heuristic + "hand off before degrading"; drop the `/handoff` `/compact` `/prototype` flow (out-of-scope 5) |
| Version-stamp + CHANGELOG fan-out for shipped-content edits | T-05 (durable-brief) 4-stamp + `[x.y.z]` precedent | `docs/features/_archived/durable-brief/02_SOLUTION_DESIGN.md`; live `CHANGELOG.md:8-16` | Reuse the exact 4-stamp + CHANGELOG pattern, bumped 0.36.0 → 0.37.0 |
| Discipline-as-guard? | (deliberately none) | — | NO new `verify_all` check (out-of-scope 3 / feedback_design_over_guards) — this is authoring guidance, not a gate |

## 8. Risk analysis

1. **Pointer drifts from the single source** (a future edit renames the heading, breaking the three by-name pointers). *Mitigation:* the pointers name a **stable heading** (`## Task-decomposition discipline`) and a skill **name** (not a line number — RA boundary condition 1 / T-05 Hard rule 6), so they survive line moves; a heading rename is a known touchpoint and would be a single grep (`Task-decomposition discipline`) to catch all three call sites. No `verify_all` coupling is added (intentionally — guidance, not gate).
2. **I.6 self-trip** — the new prose introduces a banned retired-claim anchor. *Mitigation:* checked the live 14-entry I.6 banned list (`verify_all.sh:521-536`); none of its anchors (CLAUDE.md composition, harness-adopt scaffolding, 全程中文, etc.) overlaps "vertical slice / tracer bullet / smart zone / decomposition". The new words are clear. The design doc itself is under `docs/features/` (I.6-exempt subtree, `verify_all.sh:557-560`), so quoting is safe here. Save all edits UTF-8.
3. **Accidental count-claim flip on the version bump** — touching README/CHANGELOG risks flipping a "16 skills / 8 agents / 32 checks" token. *Mitigation:* the CHANGELOG `[0.37.0]` body explicitly restates the counts as UNCHANGED (per T-05 precedent + T-03 decoy-set insight); no count token is edited anywhere; G.4 would FAIL on a count/version contradiction and acts as the backstop. The four G.3 stamps are the ONLY numeric edits (version 0.36.0 → 0.37.0).
4. **Doc-size cap (soft) on harness-plan** — adding a section grows the file. *Mitigation:* harness-plan is currently ~62 lines; +~12 lines stays far under any concern (skills have no hard line cap in `verify_all`; rule 70 token economy honored by single-sourcing instead of tripling). The three pointers are one line each (NFR-1).
5. **Pointer reads as noise / over-instruction** — three near-identical sentences across three files could feel redundant. *Mitigation:* each is ONE line, at a different authoring surface, pointing (not pasting) at the single source — the redundancy is three thin pointers, not three definitions; this is exactly the single-source pattern's intended shape. See §10 for the explicit narrow-vs-keep judgment.

## 9. Migration / rollout plan

Additive, no migration, no feature flag, no backwards-compat surface (Markdown guidance only). Rollout = the version bump.

1. Edit `skills/harness-plan/SKILL.md` — insert §3 section between `## Procedure` and `## Output`.
2. Edit the three pointers (§4a/4b/4c).
3. Bump version stamps to **0.37.0**: `.claude-plugin/plugin.json` (`version`), `.claude-plugin/marketplace.json` (`plugins[0].version`), `README.md` badge (line 5 `version-0.36.0-blue` → `version-0.37.0-blue`), `README.zh-CN.md` badge (line 5).
4. Prepend the `## [0.37.0]` CHANGELOG entry (§ below) above `## [0.36.0]`.
5. Run `.harness/scripts/verify_all` — expect 32/32 PASS, same total as task start (AC-9). G.3 sees 0.37.0 across four stamps; G.4 sees the `[0.37.0]` heading + consistent counts; I.3 caps OK; I.6 clean.

**Rollback:** revert the 9 file edits; no state to unwind.

### Version stamp targets (G.3) — bump 0.36.0 → 0.37.0

| Surface | File | Edit |
|---|---|---|
| plugin.json | `.claude-plugin/plugin.json` | `"version": "0.37.0"` (line 4) |
| marketplace.json | `.claude-plugin/marketplace.json` | `plugins[0].version = "0.37.0"` (line 17) |
| README badge | `README.md` | `version-0.37.0-blue` shield (line 5) |
| README.zh-CN badge | `README.zh-CN.md` | `version-0.37.0-blue` shield (line 5) |

### CHANGELOG `[0.37.0]` entry (G.4) — prepend above `## [0.36.0]`

```markdown
## [0.37.0] - 2026-06-20

### Added — vertical-slices: a tracer-bullet + smart-zone task-decomposition discipline single-sourced in harness-plan (T-06)

`/harness-plan` gains a **Task-decomposition discipline** section defining two named concepts adapted from mattpocock's `to-issues` + `ask-matt`: a task is a **tracer-bullet vertical slice** (a thin end-to-end path through every layer the change touches, independently demoable/verifiable on its own — NOT a horizontal slice of one layer) sized to the **smart zone** (approximately one model reasoning window, ~120k tokens on current state-of-the-art models — split or hand off before reasoning degrades). The discipline is **single-sourced** in `skills/harness-plan/SKILL.md`; the three places that author task/pool rows reference it **by name** (no pasted copy, no deep path link).

- **`skills/harness-plan/SKILL.md`**: new `## Task-decomposition discipline` section (between `## Procedure` and `## Output`) — the two named concepts plus the operational "a good task/row is one vertical slice that is independently verifiable, names only real consumption dependencies, and fits the smart zone" rule. Additive; the Procedure steps are unchanged.
- **`skills/harness-batch/SKILL.md`**, **`skills/harness-stream/SKILL.md`**, **`docs/batches/_template/BATCH_PLAN.md`**: one by-name pointer each (in `## Required input`, the `## Ingest triage` tail, and `## Column reference` respectively) to the harness-plan section — compose-by-name (rule 15 P8) + single source of truth (T-04). The batch/stream procedures and the BATCH_PLAN column schema are unchanged.
- Version 0.36.0 → 0.37.0 (plugin.json, marketplace.json, both README version badges). Counts unchanged: **16 skills / 8 framework agents / 32 checks**. No new `verify_all` check (the discipline is authoring guidance, not a gate); no I.6 banned/exempt-list change; no BATCH_PLAN column-schema change; no `harness-sync` needed (top-level `skills/` edited directly; `.harness/skills/` mirror is empty).
```

## 10. Out-of-scope clarifications

- Does NOT rewrite the harness-plan/batch/stream procedures — additive section + three one-line pointers only (out-of-scope 1).
- Does NOT change the BATCH_PLAN column schema (out-of-scope 2 / AC-8).
- Does NOT add a `verify_all` check or any guard for the discipline (out-of-scope 3; feedback_design_over_guards — guidance, not a gate).
- Does NOT import the GitHub-issue template / triage labels / publish-to-tracker / quiz-the-user loop from `to-issues` (out-of-scope 4 — this repo uses BATCH_PLAN rows).
- Does NOT add the `/handoff` `/compact` `/prototype` context-hygiene flow from `ask-matt` (out-of-scope 5).
- Does NOT change the stream's ingest-triage "one row or many" decomposition LOGIC (out-of-scope 6 — only adds the quality bar adjacent to it).
- Does NOT add the discipline to any `agents/*.md` (out-of-scope 7 — the home is a skill).

**On narrowing the pointer set (RA's OQ-3 escape hatch):** I keep all three. None is noise: the template pointer serves the hand-authoring path, the stream pointer serves the ingest/ambient normalization path, and the batch pointer serves the frozen-list authoring path — three distinct entry points, each a single line, each resolving to one definition. Dropping any one would leave an authoring surface that silently omits the quality bar. The redundancy is three thin pointers (cheap, NFR-1 honored), not three definitions (the thing single-sourcing forbids).

## 11. Partition assignment

**Omitted — not applicable.** No `.harness/agents/dev-*.md` partition agents exist in this repo (confirmed: glob `.harness/agents/dev-*.md` → none). The task runs in **single Developer mode**; the plugin `harness-kit:developer` implements all edits in dependency order: (1) the harness-plan single-source section, (2) the three by-name pointers, (3) the four G.3 version stamps, (4) the CHANGELOG `[0.37.0]` entry, (5) `verify_all`.

## 12. Verdict

**READY.**

The single-source home (`skills/harness-plan/SKILL.md` → `## Task-decomposition discipline`), the exact section text, the three exact by-name pointers + their insertion points, the four G.3 stamp targets, the G.4 CHANGELOG entry, and the no-count-flip / no-new-check / no-sync confirmations are all concrete and testable. The I.6 banned list, the empty `.harness/skills/` mirror, the 16-skill / 32-check counts, and the BATCH_PLAN schema were all verified against the live tree, not assumed. A developer can implement this without further design decisions.
```
