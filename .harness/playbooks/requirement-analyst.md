# Playbook — Requirement Analyst (stage 1)

Read by `harness-kit:requirement-analyst` as its first action. The agent contract carries the
rules that must hold when this file is missing; everything below is the procedure, the output
schema, and the mode variants.

## Output schema — `01_REQUIREMENT_ANALYSIS.md`

The contract portion opens with the line
`> Contract portion. Rationale: 01_RATIONALE.md (absent = none written).`
and carries exactly these sections, each in its declared shape:

| Section | Shape |
|---|---|
| `## Goal` | one statement — the problem, no marketing language |
| `## In-scope behaviors` | `**FR-n** — <binding statement>.`, ≤3 sentences each, testable |
| `## Out of scope` | numbered statements, one line each — what is explicitly NOT being done |
| `## Boundary conditions` | `**BC-n** — <condition> → <required behaviour>.` (null, empty, max size, concurrency, error paths) |
| `## Acceptance criteria` | rows `id \| criterion \| class [S]/[B] \| verification` — each verifiable by compile, test, or observable behavior |
| `## Non-functional requirements` | statements, each carrying a number or a named artifact; only if material |
| `## Resolved questions` | rows `id \| question (one line) \| binding answer` — the answer is a **binding statement**, not a recommendation |
| `## Verdict` | one line: `READY` / `BLOCKED ON USER` (do NOT mark ready if a question has no binding answer) |

A unit that fits no declared shape here is classified by the `## Stage-doc boundary rule` in
`.harness/rules/70-doc-size.md`. If that rule sends it to the contract and no section above can
hold it, record the schema gap as a `## Resolved questions` row — never invent a section, never
add a changelog. **If that rule fragment has no such section** (an older project), apply the
schema above as written and proceed. Do not block.

## The rationale portion — `01_RATIONALE.md`

Written **only when non-empty**, opening with
`> Rationale portion for 01_REQUIREMENT_ANALYSIS.md. Non-binding.`
It carries the evidence narrative and measurements, the related-tasks survey (link `docs/tasks.md`
entries for similar prior work here, do not re-describe them), each question's candidate answers
and the argument that selected among them, and anything else the boundary rule sends to
`rationale`. That rule is the single source — point at it by name, restate no part of it.

Each `## Resolved questions` answer is still your own resolution, which the PM/Architect adopts
unless overridden — written as a binding statement, with the candidates it beat living in the
rationale. This holds in every mode.

## Workflow

1. Read the user task description from `docs/features/<task-slug>/INPUT.md` (provided by the PM).
   The dispatch prompt indicates the task **mode** (full / plan / explore / goal) — read it.
2. Read `AI-GUIDE.md` (project index) → load the relevant `.harness/rules/*.md` fragments by their
   "when to read" triggers.
3. Query the insight index for terms from the request — an entry that applies affects how you write
   requirements (e.g. a stack quirk may constrain in-scope behaviors). You hold no `Bash`, so use
   `Grep` with an explicit `path`; see `.harness/rules/05-insight-index.md`.
4. Read `docs/tasks.md`. List any related historical tasks.
5. For each related task: read its `01_REQUIREMENT_ANALYSIS.md` and note what is already decided.
6. Read `docs/spec/` for any standing project SPECs.
7. If a project glossary (`CONTEXT.md`, usually at repo root) is present, skim it and use its
   canonical terms; if you coin or sharpen a domain term while writing, record it there inline
   (bold term + 1–2 sentence definition + `_Avoid_:` synonyms). Likewise, if
   `.harness/rejected-decisions.md` is present, skim it before proposing scope — if a request
   matches a prior decline, surface that decision rather than re-litigating it; when something is
   deliberately declined, append a record there per `.harness/rules/25-decision-policy.md`. Either
   file being absent is fine — neither is ever a precondition.
8. Draft the contract portion **per the mode** (below), routing each unit with the boundary rule.
   Write `01_RATIONALE.md` only if the rule sent something there.
9. Turn every ambiguity into a `## Resolved questions` row with a binding answer; put its candidates
   and the argument that chose between them in `01_RATIONALE.md`.
10. An ambiguity with no binding answer you can give → `BLOCKED ON USER`. Stop; the PM routes back.
11. Every question resolved → `READY`. The PM advances per the mode.

## Mode-specific output

| Mode | What `01_REQUIREMENT_ANALYSIS.md` contains |
|---|---|
| `full` (default) | The full contract schema above, plus `01_RATIONALE.md` when non-empty. The canonical case. |
| `plan` | Same as `full`. The plan-mode pipeline still runs RA → SA → GR; you write a complete requirement spec. |
| `explore` | **Light variant, contract portion only**: the Question being explored (1–3 sentences) + Success criteria for the exploration ("how will we know we have an answer") + Candidates to investigate. **No acceptance criteria, no user stories, no NFRs.** Exploration ≠ feature. Verdict is `READY` if the question is well-posed; `BLOCKED ON USER` if the question itself is unclear. |
| `goal` | The goal statement + measurable success criterion + budget usually arrive as PM input. RA may not be invoked at all; if invoked, write a one-paragraph summary of the goal context. |

When in doubt about which mode you are in, write `BLOCKED ON MODE UNCLEAR` and stop.

## Calibration

A requirement is done when a tester can verify it without asking you anything. Two failure shapes
recur and are worth naming: an untestable predicate ("the system should be fast" — no metric), and
an under-specified action ("save the file" — null path? max size? overwrite? format?). A third is
specific to rule 7: "change the field on the function around the middle of the handler file"
anchors forward-looking prose to a transient location. Name the interface and the behaviour instead.
