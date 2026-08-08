# Playbook — Solution Architect (stage 2)

Read by `harness-kit:solution-architect` as its first action. The agent contract carries the rules
that must hold when this file is missing; everything below is the procedure, the output schema,
and the optional design lens.

## Output schema — `02_SOLUTION_DESIGN.md`

The contract portion opens with the line
`> Contract portion. Rationale: 02_RATIONALE.md (absent = none written).`
and carries exactly these sections, each in its declared shape:

| Section | Shape |
|---|---|
| `## Architecture summary` | ≤3 statements: what changes, what does not, where the seam is |
| `## Change ledger` | rows `id \| absolute path \| new/edit \| what changes \| partition` — **total** over every touched file |
| `## Interfaces` | rows `id \| surface \| shape (signature / route / table / heading) \| invariant` — new module APIs, schema/migration shapes, request/response envelopes and call flow all land here |
| `## Constraints` | `**K-n** — <binding statement the implementer must satisfy>.` One imperative sentence naming an actor and an obligation. This is the residual home for a binding statement that fits no other shape |
| `## Byte-form specification` | rows `id \| artifact \| exact byte-form \| boundary-rule row matched \| test result`. **Present only when boundary-rule row 3 or row 4 matched** |
| `## Frozen set` | rows `path \| why frozen` — what the implementer must not touch |
| `## Migration & edit sequence` | rows `order \| edit ids \| precondition \| rollback` — backwards compatibility, flags, data migration, rollback |
| `## Out of scope` | statements, one line each — design boundaries this design does NOT cover |
| `## Verification plan` | rows `step id \| what is run/measured \| expected observable \| AC` |
| `## Residuals travelling` | rows `id \| statement \| must reach <stage/doc>` |
| `## Partition assignment` | the table below (REQUIRED when `.harness/agents/dev-*.md` files exist) |
| `## Verdict` | one line: `READY` / `BLOCKED` (with reason and which agent should resolve) |

**`## Byte-form specification` is the only shape that may carry raw bytes, and it is gated.** It is
present only when the boundary rule's row 3 or row 4 matched, and each row must name the row that
admitted the bytes and state that row's test result. Without both of those columns, row 2 becomes
an unconditional bypass of rows 3, 4 and 9 — never drop them, never fold the section in without
its gate.

A unit that fits no declared shape here is classified by the `## Stage-doc boundary rule` in
`.harness/rules/70-doc-size.md`. If that rule sends it to the contract and no section above can
hold it, **name the gap as a `## Change ledger` row** — never invent a section, never add a
changelog. **If that rule fragment has no such section** (an older project), apply the schema above
as written and proceed. Do not block.

## The rationale portion — `02_RATIONALE.md`

Written **only when non-empty**, opening with
`> Rationale portion for 02_SOLUTION_DESIGN.md. Non-binding.`
It carries the **reuse audit** (still mandatory — it is addressed to the gate, which reads this
portion by default), the **risk analysis**, option comparisons, measurement narratives, evidence
citations, and anything else the boundary rule sends to `rationale`. That rule is the single
source — point at it by name, restate no part of it.

## Workflow

1. Read the upstream **contract**: `01_REQUIREMENT_ANALYSIS.md`. Verdict must be `READY`; if not,
   return `BLOCKED ON UPSTREAM`. Note the **mode** from the dispatch prompt. Open `01_RATIONALE.md`
   **only** when a trigger fires: **T2.1** a contract statement you must design to is ambiguous or
   self-contradictory; **T2.2** you are about to override a `## Resolved questions` answer; **T2.3**
   you are about to return `BLOCKED ON UPSTREAM`; **T2.4** you are on a rework round (then also read
   `03_GATE_REVIEW.md` and `03_RATIONALE.md` for the per-finding reasoning). If a trigger fires and
   the rationale is absent, record one line ("reached for `01_RATIONALE.md` under T2.x; absent;
   proceeded") and continue — never block, never fabricate.
2. Read `AI-GUIDE.md` and load relevant `.harness/rules/*.md` fragments by their triggers (carry
   constraints from `50-<project-type>.md` and any partitioning rules).
3. Query the insight index for terms from the requirement — an entry about a stack quirk may
   constrain your design. You hold no `Bash`, so use `Grep` with an explicit `path`; see
   `.harness/rules/05-insight-index.md` for why an unscoped search returns nothing.
4. Read `docs/dev-map.md` for project structure and existing patterns.
5. If `CONTEXT.md` is present, use its canonical names for new modules / files / symbols, and record
   any term you introduce or sharpen inline (bold term + 1–2 sentence definition + `_Avoid_:`
   synonyms). If `.harness/rejected-decisions.md` is present, check it before introducing a new
   approach — if it was already declined, surface that decision rather than re-designing it; when
   you deliberately decline an approach, append a record per `.harness/rules/25-decision-policy.md`.
   Either file being absent is fine — neither ever blocks the design.
6. Grep the codebase for symbols related to the requirement.
7. Draft the contract. Every touched file gets a `## Change ledger` row; every module you add or
   reshape gets an `## Interfaces` row. The **reasons** for each choice are rationale, not contract.
8. Run the reuse audit into `02_RATIONALE.md` (format below).
9. Risk analysis into `02_RATIONALE.md`: at least 3 risks, each with its mitigation.
10. Fill `## Migration & edit sequence`: if data or API shapes change, one row per ordered step with
    its precondition and rollback.
11. Everything fits → `READY`. Else → `BLOCKED` with a specific reason.

## Mode-specific note

The mode does **not** change the document's structure — it is always the full design. What changes
is what happens after:

| Mode | After this agent |
|---|---|
| `full` | GR reviews; if APPROVED, Developer implements |
| `plan` | GR reviews; if APPROVED FOR DEVELOPMENT, **the pipeline stops**. The user later runs `/harness` on the same slug to continue from Developer, so your design **must** be complete enough to hand off to a future session — cite paths absolutely, and be explicit about assumptions that might shift |
| `explore` | You are usually **not invoked**. If invoked anyway, write a one-paragraph technical overview, not a full design |
| `goal` | You are not invoked — the goal IS the design intent, and the Developer iterates directly |

## Reuse audit format (a `02_RATIONALE.md` section)

```markdown
## Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| User session check | `requireAuth()` middleware | `src/middleware/auth.ts` | Reuse as-is |
| Email sending | `MailService` | `src/services/mail.ts` | Extend with new template |
| PDF rendering | (none found) | — | New module justified |
```

## Partition assignment format (REQUIRED when `.harness/agents/dev-*.md` exists)

```markdown
## Partition assignment

| File | Partition | New / Edit | Dependency |
|---|---|---|---|
| `prisma/schema.prisma` | dev-db | edit (add Export model) | — |
| `src/server/exports.ts` | dev-backend | new | dev-db |
| `apps/web/components/ExportButton.tsx` | dev-frontend | new | dev-backend (consumes API) |

## Dispatch order

1. dev-db
2. dev-backend
3. dev-frontend

## Parallelism

None — strict sequential because frontend consumes backend which consumes DB.
```

If a single partition covers the whole task, still include the table — clarity matters more than
table size. In single-Developer projects (no `dev-*.md` under `.harness/agents/`), omit the section.

## Calibration

The change ledger is **total**: a file the developer touches that has no row is a design defect. A
design is done when a junior developer could implement it without a further design decision — which
means no "we could use either Redis or in-memory" (pick one, with a reason), no "the service should
be scalable" (quantify or remove), and no finished function body pasted in (the bytes are the
developer's to author; the contract carries the constraint they must satisfy).

## Design vocabulary (optional lens)

Leading words to think *with* when sharpening a module boundary — not a checklist, not a required
field. Aim for **deep modules**: a lot of behaviour behind a small interface, at a clean seam.

- **Module** — anything with an interface and an implementation (a function, class, package, or a
  tier-spanning slice). Scale-agnostic; not "component"/"service".
- **Interface** — everything a caller must know to use it correctly: the type signature *and*
  invariants, ordering constraints, error modes, required config, performance characteristics.
- **Depth** — leverage per unit of interface: how much behaviour a caller exercises per unit of
  interface they must learn. Deep = much behaviour behind a small interface.
- **Seam** — where the interface lives: a place you can alter behaviour without editing in that
  place. Where the seam goes is its own decision, separate from what sits behind it.
- **Adapter** — a concrete thing that satisfies an interface at a seam (a role/slot, not a substance).
- **Leverage** — the caller's payoff from depth: one implementation pays back across N call sites.
- **Locality** — the maintainer's payoff: change, bugs, and verification concentrate in one place.

When the lens is useful:

- **The deletion test.** Imagine deleting the module. If complexity vanishes, it was a pass-through;
  if complexity reappears across N callers, it earned its keep.
- **The interface is the test surface.** Callers and tests cross the same seam — if you need to test
  *past* the interface, the module is probably the wrong shape.
- **One adapter means a hypothetical seam; two means a real one.** Do not introduce a seam unless
  something actually varies across it.

_Future options (not used here): finer dependency categories (in-process / local-substitutable /
remote-owned / true-external) and a design-it-twice parallel-exploration pattern — both deferred._
