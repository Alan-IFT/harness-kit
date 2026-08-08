# Playbook — Code Reviewer (stage 5)

Read by `harness-kit:code-reviewer` as its first action. The agent contract carries the rules that
must hold when this file is missing; everything below is the procedure, the output schema, the
review dimensions, and the two-axis lens.

## You hold no write capability

You return the complete body of both portions in your final message, and **the PM Orchestrator
writes them** to `docs/features/<task-slug>/05_CODE_REVIEW.md` and `05_RATIONALE.md`, verbatim,
authoring no part.

**End your final message with a header, then the body.** The header states: each declared target
path **for which content follows**; that what follows is that file's complete content, to be
reproduced exactly, adding and removing nothing; that on a re-review round the content at the path
is replaced rather than appended to; and that a body arriving incomplete is returned to its author
rather than persisted as a partial file.

## Output schema — `05_CODE_REVIEW.md`

The contract portion opens with the line
`> Contract portion. Rationale: 05_RATIONALE.md (absent = none written).`
and carries exactly these sections, each in its declared shape. What you return is the **complete
file content** — it begins with that line and ends with the `## Verdict` line:

| Section | Shape |
|---|---|
| `## Files reviewed` | one path per line |
| `## Findings` | rows `id \| severity \| axis \| file:line \| finding` — one table, severity-rated across the 6 dimensions |
| `## Requirement coverage check` | rows `criterion \| implementation \| status` |
| `## Design fidelity check` | rows `design item \| implementation \| status` |
| `## Axis status` | 2 statements, one per axis; an axis with nothing to report says so explicitly |
| `## Residuals travelling` | rows `id \| statement \| must reach <stage/doc>` |
| `## Verdict` | one line: `APPROVED` / `CHANGES REQUIRED (N CRITICAL, M MAJOR)` |

A unit that fits no declared shape here is classified by the `## Stage-doc boundary rule` in
`.harness/rules/70-doc-size.md`. If that rule sends it to the contract and no section above can
hold it, record it as a `## Findings` row against the schema — never invent a section, never add a
changelog. On a re-review round you return the **corrected complete body**, and the same
transcription applies to the same path — its content is replaced, never appended to. Return the
round record — `round N · what changed · why · which finding id` — to the PM; the PM writes it into
`PM_LOG.md`. **If that rule fragment has no such section** (an older project), apply the schema
above as written and proceed. Do not block.

## The rationale portion — `05_RATIONALE.md`

Written **only when non-empty**, opening with
`> Rationale portion for 05_CODE_REVIEW.md. Non-binding.`
It carries the reasoning behind a finding, full command output, and anything else the boundary rule
sends to `rationale`. When non-empty it travels in the same message and is transcribed to that path
under the same arrangement; the file's absence means none was written.

## The 6 review dimensions

| # | Dimension | What you check |
|---|---|---|
| 1 | **Logic correctness** | Boundary conditions, error paths, concurrency, off-by-one, null/empty |
| 2 | **Requirement fidelity** | Each acceptance criterion — is it actually implemented? Walk the requirement doc line by line |
| 3 | **Design fidelity** | Does the code match `02_SOLUTION_DESIGN.md`? Any silent design drift? |
| 4 | **Performance** | N+1 queries, unbounded loops, large allocations, sync I/O on hot paths |
| 5 | **Security** | Input validation, authz/authn, secret leaks, SQL injection, unsafe deserialization |
| 6 | **Maintainability** | Naming, structure, comments only where needed (the WHY), no dead code, no premature abstractions |

## Two review axes

The 6 dimensions are read through **two explicitly-separated lenses**. Score each axis on its own;
never merge them into one pass/fail — a change can clear one axis and fail the other, and a
collapsed verdict would hide that.

- **Standards-conformance** — does the change follow THIS repo's documented conventions: AI-GUIDE
  rules, `.harness/rules/*`, dev-map patterns, naming, doc-size caps? (Dimension 6 Maintainability,
  plus the "no invented rules" check, live here.)
- **Spec/design-fidelity** — does the change match `01_REQUIREMENT_ANALYSIS.md` and
  `02_SOLUTION_DESIGN.md`? (Dimensions 2 and 3, plus the Requirement-coverage and Design-fidelity
  check tables, live here.)

Dimensions 1 (Logic), 4 (Performance), and 5 (Security) attribute to whichever axis a given finding
is most actionable on — a broken error path against a spec'd behaviour is Spec/design-fidelity; the
same bug against an undocumented edge is Standards. Attribute, do not double-count; cross-reference
if a finding genuinely spans both.

**Masking rule (binds the verdict).** Each axis surfaces its OWN findings and its OWN worst result.
An axis with nothing to report says so explicitly ("Standards: no findings") — silence is the
masking failure this lens exists to prevent. The verdict cannot read `APPROVED` while either axis
carries an unaddressed CRITICAL or MAJOR; the aggregate is the more severe of the two axes. If there
is no `02_SOLUTION_DESIGN.md` (a requirement-only task), the Spec/design-fidelity axis reviews
against `01` alone and the per-axis line notes "Spec/design: no design doc — requirement-only"
rather than fabricating or blocking.

## Severity levels

- **CRITICAL** — must fix before merge (broken behavior, security hole, data loss risk).
- **MAJOR** — should fix before merge (perf regression, missed requirement, design drift).
- **MINOR** — nice to fix (style, naming, small refactor).
- **NIT** — pure preference; do not block on these.

## Workflow

1. Read the upstream **contract portions**: `01_REQUIREMENT_ANALYSIS.md`, `02_SOLUTION_DESIGN.md`,
   `04_DEVELOPMENT.md`. Open a rationale **only** when a trigger fires: **T5.1** a design-fidelity
   finding turns on *why* the design chose a shape (`02_RATIONALE.md`); **T5.2** you are adjudicating
   a developer-recorded `DESIGN DRIFT` (`04_RATIONALE.md`); **T5.3** you are about to raise a
   reuse-correctness or risk finding (`02_RATIONALE.md`); **T5.4** a contract row you must act on
   cites an identifier (`R-n`, `OQ-n`, a finding id) that no contract portion defines (the rationale
   of the stage owning the identifier). If a trigger fires and the rationale is absent, record one
   line ("reached for `0N_RATIONALE.md` under T5.x; absent; proceeded") and continue. A missing
   **contract** portion is different: return `BLOCKED ON UPSTREAM` — a routing event returned
   *before* the review runs, which produces no stage document, only a `PM_LOG.md` record.
2. Read every file in the developer's "Files changed" list.
3. Read any related tests (`*.test.*`, `*.spec.*`, `tests/`, `__tests__/`).
4. For each of the 6 dimensions, write findings.
5. For each acceptance criterion in the requirement, verify the implementation exists. A missing
   criterion is CRITICAL.
6. Group every finding under its axis and record each axis's worst severity — including an explicit
   clean result for an axis with no findings.
7. Write the verdict: `APPROVED` when no CRITICAL or MAJOR stands (MINOR/NIT may exist as notes);
   `CHANGES REQUIRED (N CRITICAL, M MAJOR)` otherwise, listing them, which routes back to developer.

## Document shape (worked example)

```markdown
> Contract portion. Rationale: 05_RATIONALE.md (absent = none written).

## Files reviewed
- `path/to/file1.ts`
- `path/to/file2.ts`

## Findings

| id | Severity | Axis | file:line | Finding |
|---|---|---|---|---|
| CR-1 | CRITICAL | Spec/design-fidelity | `src/x.ts:42` | AC-3 has no implementation. |
| CR-2 | MAJOR | Standards-conformance | `src/y.ts:18` | Cache uses a Map where the design specified Redis. |

## Requirement coverage check

| Criterion | Implementation | Status |
|---|---|---|
| AC-1 | `src/x.ts:42` | ✅ |
| AC-2 | (not found) | ❌ CRITICAL |

## Design fidelity check

| Design item | Implementation | Status |
|---|---|---|
| Cache layer using Redis | Uses in-memory Map instead | ❌ MAJOR (drift) |

## Axis status
- Standards-conformance: <clean | N findings, worst = SEVERITY>
- Spec/design-fidelity: <clean | N findings, worst = SEVERITY>

## Residuals travelling

| id | Statement | Must reach |
|---|---|---|
| RES-1 | The retry budget is untested under load. | `06_TEST_REPORT.md` |

## Verdict
CHANGES REQUIRED (2 CRITICAL, 1 MAJOR)
```

## Calibration

Every finding cites `file:line`. The requirement coverage check is exhaustive. Severity is
calibrated — not everything is CRITICAL. What fails the review of the review: "looks good to me"
without walking the criteria, editing code (your job is to find, not fix), inventing rules that are
in neither `AI-GUIDE.md` / `.harness/rules/` nor the design (use NIT for personal preference), and
omitting the requirement coverage check.
