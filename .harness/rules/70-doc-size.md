# 70 — Document size policy (harness-kit dogfood)

## What this is

Soft caps on the size of long-lived and per-task documents, so AI tools don't burn
context budget reading bloated files. **WARN-level**, surfaced by `verify_all`'s
`I.*` group (this repo) — user projects shipped via `/harness-init` get the same
caps under their own `F.*` group.

The rule has two halves: **size caps** (the numeric budget) and **process
discipline** (how to live under the cap without losing information).

## When to read this

- Before adding a new rule fragment or agent definition.
- Before pasting evidence into a stage doc (`01_*.md`…`07_*.md`) or `PM_LOG.md`.
- **Before writing any section of a stage doc** — the boundary rule below decides where each unit goes.
- When `verify_all` flags an `I.*` / `F.*` WARN.

## Caps

| Document | Cap | Why this number | If exceeded |
|---|---|---|---|
| `AI-GUIDE.md` | 200 lines | Always-on entry; reread every task. | Trim to index-only; move prose to `docs/concepts.md` |
| `CLAUDE.md` | 50 lines | Static bootstrap stub; not a content destination. | Move content into `.harness/rules/*.md` |
| `.harness/rules/*.md` (each) | 200 lines | Loaded selectively; should fit comfortably with 2–3 siblings. | Split into `70a-…` / `70b-…` with distinct triggers |
| `agents/*.md` (each) | 300 lines | Loaded when the agent is dispatched. This is the path `verify_all` I.3 checks — in THIS repo the framework agents are plugin-native at `agents/`. Partition `dev-*` agents live at `.harness/agents/` (empty here; that is where a generated project's agents sit) and carry the same cap. | Refactor responsibilities, or move stable doc to `docs/` |
| `.harness/insight-index.md` | 30 insight entries | Loaded at every task start by PM. | `.harness/scripts/archive-task` auto-rotates oldest to `docs/features/_archived/insight-history.md` |
| `docs/tasks.md` | 300 lines | Loaded at every task start by PM. | Move oldest Completed rows to `docs/tasks-archive.md` (manual today; tooling later) |
| Per-task `PM_LOG.md` | 500 lines | PM rereads for resume; downstream agents read for context. | "Compaction" pattern below |
| Per-task stage doc (`0[1-7]_*.md`) | 500 lines each | Read by the next stage's agent. | "Reference, don't paste" pattern below |

## Stage-doc boundary rule

Every unit of stage-doc content has exactly one of four destinations:

- **contract** — the numbered stage document (`01_*.md`…`07_*.md`): the binding portion a
  downstream stage reads by default.
- **rationale** — the optional sibling `0N_RATIONALE.md` (same folder, same stage number, written
  only when non-empty): reasoning the gate reads by default and other stages read only when one of
  their own named triggers fires.
- **routing log** — `PM_LOG.md`.
- **no home** — there is no location to write it in this task's documents at all.

**Classification unit — apply in order; the first step that matches names the unit.**

1. **Declared shape.** Inside a section whose shape the authoring agent's `## What you produce`
   schema declares, the shape's own unit is the unit: one table row, one `**K-n** —` statement line,
   one `key: value` line, the `> Contract portion.` header line. Sub-parts are never classified
   separately.
2. **Fenced block.** A fenced block is one unit, fence lines included, however long.
3. **Blockquote.** An unbroken `>` run is one unit, however many sentences it contains.
4. **Table row.** Each body row of a table is one unit.
5. **List item.** Each top-level list item, together with its nested sub-items, is one unit.
6. **Sentence.** Otherwise the unit is one sentence ending at top level. **A paragraph is never a
   unit**: when its sentences reach different destinations the paragraph splits and each sentence is
   written at its own destination.

**Not units.** Markdown structure that carries no content — a heading, a blank line, a horizontal
rule, a table header row, a fence's language tag — is not classified.

**Verbatim byte-form.** A unit is *destined verbatim* when the document offers it as the characters
to be transcribed into a shipped artifact: introduced by "replace X with", "insert", "exactly" or
"verbatim", or presented as a quotation or fence of that artifact's text. A statement of **what the
artifact must satisfy** is not a byte-form, however normative — the byte-form is the transcription,
the constraint is the requirement.

**Headings.** A heading is not itself classified; it travels with the units it contains. When a
section's units split across destinations, the **section splits**: the heading is written in each
destination receiving ≥1 unit, and the rationale copy opens with a one-line pointer to the
contract copy.

**Precedence.** Rows are evaluated **top to bottom; first match wins**. Redundancy between rows is
harmless; a hole is not — row 14 is terminal and reachable by any unit.

| # | If the unit is… | Destination |
|---|---|---|
| 1 | under a heading a **shipped mechanism reads** — `## Adversarial tests` in `06_TEST_REPORT.md`, `## Insight` in `07_DELIVERY.md` | **contract**, in that exact file; heading bytes frozen |
| 2 | a unit fitting a **declared shape** of the contract schema for the stage that authors it, **and not destined verbatim for a shipped artifact** (if it is, rows 3, 4 and 9 decide it) | **contract** |
| 3 | an exact byte-form whose **character identity is itself an acceptance criterion** | **contract**, written **once**; every other mention cites it |
| 4 | **normative text a shipped artifact must carry**, where no statement of the constraint is both *strictly shorter* than the text **and** satisfiable by *more than one* artifact | **contract**, once, under `## Byte-form specification`, **with the test's result stated in the row** |
| 5 | a **binding statement** any later stage, the operator, or the release gate must satisfy, obey, verify, or not touch, that fits no declared shape (a *statement* is one sentence; a fenced block or a blockquote is never a statement) | **contract** — and the schema lacks a section: name the gap in the change ledger |
| 6 | the **answer** to a resolved question, restated as a binding statement — row 5's definition applies: one sentence, and a fenced block or a blockquote is never a statement | **contract**, in the stage's resolved-question section — and the schema lacks one: name the gap in the change ledger |
| 7 | an excerpt of **≤5 lines** cited as proof inside a contract row | **contract** |
| 8 | a record of what changed between rounds of this stage, a superseded finding, a rollback cause, or any claim about an earlier draft of this document | **routing log** (`PM_LOG.md`) |
| 9 | a body of characters destined **verbatim** for a shipped artifact — source code, comment prose, or document prose — and rows 3/4 did not match | **no home**; write instead, under row 5, the constraint the artifact must satisfy |
| 10 | a summary or paraphrase of another unit **in the same document** | **no home** |
| 11 | a question's text beyond one line, its candidate options, or the argument that selected among them | **rationale** |
| 12 | an argument, option comparison, reuse finding, risk statement, measurement narrative, or evidence citation supporting a unit classified by rows 1–7 | **rationale** |
| 13 | a captured tool run, transcript, or excerpt **longer than 5 lines** | **rationale** |
| 14 | **otherwise** | **rationale** (terminal default) |

**Row 4 is bounded, not negotiable.** Row 4 matches only when **no** statement of the constraint
is both strictly shorter than the text and satisfiable by more than one artifact. Both conjuncts
quantify over *statements of the constraint*, never over the body itself. For any body of source
code such a statement **exists** — a functional description of what the code must do is shorter
than the code and is satisfied by more than one spelling of it (rename a variable; it still
satisfies). Row 4 therefore never matches source code. It matches only prose whose meaning **is**
its exact wording, and the row that carries it must state the result of that test.

**Rule ↔ schema agreement is by construction.** Row 2 makes every declared shape contract, so the
table and a stage schema cannot give opposite answers for a declared section — except for a
byte-form, which row 2 now hands to rows 3/4/9 rather than blessing. A schema's fallback re-enters
this table exactly once. A unit that is both binding and a round record hits row 2 or row 5 before
row 8 — it lands in the contract as **current state**, and the separate fact *that it changed* hits
row 8. Row 10 is why no per-document summary header exists: a stage contract is the original
binding text addressed directly to its consumers, never a distilled copy of a fuller body.

**No stage document carries a changelog, round-record, or superseded-finding section.** On
completing a rework round, a stage agent returns the round record — `round N · what changed · why ·
which finding id` — to the PM in its final message, and the PM writes it into `PM_LOG.md`. The
stage document is corrected **in place** to current state.

## Process discipline

### Rule 1 — Reference, don't paste

Stage-doc authors (Architect, Developer, QA especially) MUST cite code by
`path/to/file.ts:42-58` instead of pasting the lines verbatim.

Two reasons:
- A citation refers to the **current** code; a paste decays as the codebase evolves.
- A 16-line snippet pasted costs 16+ lines of doc; the same citation costs one.

When raw evidence is genuinely necessary (an extracted error message, a config
fragment that doesn't live in repo) keep it to **≤5 lines**.

### Rule 2 — PM_LOG.md compaction at the cap

If an active task's `PM_LOG.md` is approaching 500 lines (mostly a `goal`-mode
risk), PM compacts:

1. Identify "stably past" stages (current stage = N; stages 1..N-2 are stably past).
2. Prepend `## Compacted stages 1..N-2 (YYYY-MM-DD)` with **one-line summaries** of each.
3. Delete the verbose entries for those stages from the body.
4. Keep the last 2 stages' entries full and chronological.

Compaction is PM-owned. Never delegate to a downstream agent (they're reading
the file). Do not compact mid-stage — only at stage boundaries.

### Rule 3 — `docs/tasks.md` rotation

When the Completed table exceeds ~30 rows, move the oldest 50% to
`docs/tasks-archive.md`. Keep the active table small so PM's task-start read is
cheap. (Manual today; a `scripts/compact-tasks` may land in a later release.)

### Rule 4 — Always archive completed tasks

The single biggest size guardrail: run `.harness/scripts/archive-task --task <slug>` on
every completed `full` / `goal` task. It:

- Harvests `## Insight` entries — each bullet plus every line wrapped under it — from `07_DELIVERY.md` into `.harness/insight-index.md` (auto-rotates overflow by entry).
- Moves stage docs + `PM_LOG.md` to `docs/features/_archived/<slug>/`.

Skipping `archive-task` is the **#1 cause of long-term bloat** — insight-index
fills up manually, stage docs pile under `docs/features/`, and verify_all's size
checks start firing a month later.

PM is responsible for triggering archive at end of full/goal mode
(see `pm-orchestrator.md` step 10).

## Adversarial check

Before adding a new section to ANY of the docs above, ask:

> Would a future AI tool, loading this file fresh, need this content to make
> a decision in the next 10 minutes?

- **Yes** → write it.
- **Nice to have** → write it under `docs/concepts.md` or `docs/_archived/`, not in the index.
- **One-time observation about a task** → write it in a stage doc that gets archived.

The cap is a budget. Cuts are made by removing what doesn't earn its line, not
by mechanical truncation.
