# Playbook — Developer (stage 4)

Read by `harness-kit:developer` as its first action. The agent contract carries the rules that must
hold when this file is missing; everything below is the procedure and the output schema.

## Output schema — `04_DEVELOPMENT.md`

The contract portion opens with the line
`> Contract portion. Rationale: 04_RATIONALE.md (absent = none written).`
and carries exactly these sections, each in its declared shape:

| Section | Shape |
|---|---|
| `## Summary` | ≤3 statements: what was built |
| `## Files changed` | rows `path \| what changed \| ledger id` |
| `## verify_all result` | `key: value` lines — baseline / after / delta |
| `## Design drift` | rows `id \| design item \| what was done instead \| why`; write `None.` when empty |
| `## Condition disposition` | rows `gate condition id \| disposition \| evidence` — one row per binding condition the gate assigned you |
| `## Open issues for review` | statements — things you noticed but could not fix in this pass |
| `## Dev-map updates` | statements — lines added to `docs/dev-map.md` |
| `## Insight to surface` | one **physical** line per insight, `<one-sentence fact> · evidence: <file:line or commit>`. A wrapped bullet is harvested whole, but an unclassifiable line makes `archive-task` refuse at exit 3 — keep the section to bullets and blank lines. Omit the section if nothing surfaced — do not write filler |
| `## Verdict` | one line: `READY FOR REVIEW` |

`## Insight to surface` is what the PM consolidates into `07_DELIVERY.md`'s `## Insight` section,
which `archive-task` harvests into `.harness/insight-index.md`.

A unit that fits no declared shape is classified by the `## Stage-doc boundary rule` in
`.harness/rules/70-doc-size.md`. If that rule sends it to the contract and no section can hold it,
name the gap in `## Open issues for review` — never invent a section, never add a changelog. **If
that rule fragment has no such section** (an older project), apply the schema above as written and
proceed. Do not block.

## The rationale portion — `04_RATIONALE.md`

Written **only when non-empty**, opening with
`> Rationale portion for 04_DEVELOPMENT.md. Non-binding.`
It carries full tool transcripts, measurement narratives, the argument behind a drift decision, and
anything else the boundary rule sends to `rationale`.

## Workflow

1. Load the upstream **contract sections addressed to you** —
   `node .harness/scripts/doc-query.js --for developer --task <slug>`. It returns the sections of
   `01_REQUIREMENT_ANALYSIS.md`, `02_SOLUTION_DESIGN.md` and `03_GATE_REVIEW.md` you must obey,
   verbatim and in document order; a section is withheld only when the schema addresses it to
   someone else, and a heading it does not recognise is returned in full. Ask for any withheld
   section by name (`--in stage --heading '<Section>' --task <slug>`) — the routing is a default,
   not a wall.

   Open a rationale **only** when a trigger fires: **T4.1** you are about to record `DESIGN DRIFT`
   (`02_RATIONALE.md`); **T4.2** a contract row is ambiguous or contradicts another
   (`02_RATIONALE.md`, or `01_RATIONALE.md` when the row is an acceptance criterion); **T4.3** you
   are about to write `BLOCKED ON DESIGN` (`02_RATIONALE.md`); **T4.4** you are reworking after
   code-review or QA defects (`05_RATIONALE.md` / `06_RATIONALE.md`). If a trigger fires and the
   rationale is absent, record one line ("reached for `0N_RATIONALE.md` under T4.x; absent;
   proceeded") and continue — never block, never fabricate. A missing **contract** portion is
   different: return `BLOCKED ON UPSTREAM`.
2. Read `AI-GUIDE.md` (project rules entry) → follow its index to load the relevant
   `.harness/rules/*.md` fragments. Query the insight index for project-specific gotchas —
   `node .harness/scripts/doc-query.js --in memory --doc insight-index <term>`, never a whole-file
   read (`.harness/rules/05-insight-index.md`).
3. Read `docs/dev-map.md`.
4. Read every file the design says you will modify. Confirm they exist and have the expected shape.
5. Run `verify_all` once to capture a **baseline**.
6. Use `TodoWrite` to plan the implementation in small steps.
7. Implement step by step. After each major step, save and continue.
8. Run `verify_all` again and compare to the baseline. New failures, errors, or warnings must be
   fixed before proceeding. "It is a pre-existing issue" is not valid unless verified against the
   baseline.
9. When all steps are done and `verify_all` passes:
   - Update `docs/dev-map.md` if project structure changed.
   - Write `04_DEVELOPMENT.md` per the schema above, plus `04_RATIONALE.md` if the boundary rule
     sent anything there.
   - **If implementation surfaced a non-obvious project truth** that beat your prior (something not
     in the `01`–`03` docs and not derivable in <10 minutes from reading the codebase), flag it
     under `## Insight to surface` as **one physical line**.

## Escalation

| Situation | What you write, then stop |
|---|---|
| Design gap discovered during implementation | `BLOCKED ON DESIGN` |
| Required external capability missing (e.g. an MCP server) | `BLOCKED ON CAPABILITY` |
| Upstream contract portion missing | `BLOCKED ON UPSTREAM` |
| `verify_all` fails with errors you cannot resolve in 3 attempts | escalate to the PM |
| A production-risky action is required (drop table, force push) | never auto-execute; escalate |

## Calibration

Done means the `verify_all` delta reads "0 new failures, baseline preserved or improved", the
implementation matches the design with every deviation flagged, `dev-map.md` reflects new files and
modules, and tests cover the new behaviour. Not done: skipping `verify_all`, deleting failing tests
instead of fixing them, silent design drift, or "it works on my machine".
