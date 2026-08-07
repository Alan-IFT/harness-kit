# v2 P1 — three blockers, one viable alternative, and a revised target

> Written 2026-08-07 on branch `v2-migration`, after P0. Measured, not argued.
> **P1 as specified in the migration brief cannot be executed as written.** Three of its
> mechanisms re-propose designs this repo already declined on evidence. A fourth
> assumption — that T-18 left the contract-size problem unsolved in a way §8 would fix —
> is half right: the problem is unsolved, but §8 is not the fix.

## 1. What blocks it

| Brief mechanism | Collides with | Why the decline holds |
|---|---|---|
| **§8 handoff card** — a ≤25-line `BINDING`/`EVIDENCE` card the downstream stage reads instead of the stage document | `stage-doc-summary-header` — **declined, red line for T-18 and after** | "A summary is a copy of the body that must be hand-kept in sync with it… and nothing gates the copy against its original." The replacing corollary: a stage contract is **the original binding text addressed directly to its consumers, never a distilled copy of a fuller body.** |
| **§8.2 "nothing over 25 lines may be a handoff artifact"** | `stage-bloat-prohibitions-only` — declined | "A prohibition depends on compliance and has nothing enforcing it." The standing direction is to prefer a design that makes the failure impossible over a patch that forbids it. Re-surfacing "just tell the agents to write less" *is* that record. |
| **§6.3 move methodology out of `agents/*.md` into a skill, load on demand** | `boundary-rule-in-agent-file` — declined | Framework agents are plugin-native and therefore have **no project-relative path in a generated project** — they cannot *read* a rule they must apply at authoring time. That decline is exactly why the text lives in `.harness/rules/` (distributed via template overlay), **the directory §9.1 deletes.** |

The third row is circular and is the sharpest of the three: §9.1 removes the only carrier
that a plugin-native agent can reliably read applied normative text from, and §6.3 then
requires agents to read applied normative text from somewhere else. Both cannot hold.

## 2. What T-18 actually achieved (measured)

T-18 `stage-contract-split` is the accepted structural answer to stage-doc bloat: every
stage document splits into a contract plus an optional `0N_RATIONALE.md`. **It did not
reduce contract size.**

`01+02+03` totals, 43 archived tasks, split by whether the task carries `0N_RATIONALE.md`
files (the post-T-18 marker):

| Set | n | mean |
|---|---:|---:|
| Post-T-18 | 4 | **105.7 KB** |
| Pre-T-18 | 39 | 68.7 KB |

All four post-T-18 tasks rank in the top 9 of 43 by contract size. **Causation is not
claimed** — n=4, and recent tasks are plausibly more complex. What is established is
narrower and sufficient: the split moved rationale into sibling files without shrinking
the contract, so the size problem §8 targets is real and still open.

Inspection of a post-T-18 contract (`review-write-path/02_SOLUTION_DESIGN.md`, 49.6 KB)
shows it is **not prose bloat** — it is 28 structured sections of genuine binding content,
with 27.1 KB of rationale already correctly split out. There is nothing left to forbid.

## 3. The viable alternative — address sections to consumers

The two declines define the shape of an admissible fix: it must read the **original** text
(not a copy), and it must be **structural** (not a prohibition).

T-18 addressed content to consumers at the **document** level — contract vs rationale. The
next increment is to do it at the **section** level: each section of a stage contract
declares its consumer(s), and a stage loads only the sections addressed to it.

This is admissible where §8 is not:

- **Not a copy.** The consumer reads the original section. Nothing needs syncing, so the
  `stage-doc-summary-header` objection does not attach.
- **Not a prohibition.** No one is told to write less. Sections are routed, and the routing
  is machine-checkable — an unaddressed section is a gate failure, which is the
  "make the failure impossible" direction `stage-bloat-prohibitions-only` demands.
- **Carrier survives.** The rule lives in `.harness/rules/70-doc-size.md`, whose existing
  read-trigger already fires at authoring time — the carrier `boundary-rule-in-agent-file`
  selected, and which therefore must **not** be deleted by §9.

### Measured prize

`review-write-path/02_SOLUTION_DESIGN.md`, sections classified by whether stage 4 needs them:

| | bytes | share |
|---|---:|---:|
| Developer-addressed (`D-1`…`D-8`, Architecture summary, Affected modules, Sequence/flow, Data model, API contracts, Developer-owned conditions, Partition assignment) | 23,864 | **48%** |
| Addressed elsewhere (Change ledger 7.7 KB, Risks 5.6 KB, What QA must be able to do 5.1 KB, Migration plan, Audit-set derivation, OQ-1, Open questions, Out-of-scope, Verdict) | 25,578 | 52% |

## 4. The consequence for the acceptance bar

Section addressing cuts the Developer's stage-2 read roughly in half. Extrapolated across
`01+02+03` for that task: ~94.9 KB → ~35 KB, about **2.7×**.

**The adopted bar is ≥6× (P0, `evals/retrieval-eval.md`). P1 alone cannot reach it.**

This is not a defect in P1 — it is the brief's own thesis arriving on schedule. The
remaining factor comes from **querying instead of reading**, which is what P2 (CodeGraph)
and P3 (memory layer) exist to provide. The honest phase targets:

| Phase | Mechanism | Realistic contribution |
|---|---|---|
| P1 | section addressing + safe deletions + skill-listing shrink | ~2.5–3× on the stage-4 ingest |
| P2 | `codegraph_explore` replaces whole-repo grep and full-file reads | code-shaped questions only |
| P3 | memory layer replaces reading `insight-index` / `rejected-decisions` / archived docs | the remainder |

**Do not hold P1 to the ≥6× bar.** Hold it to ~2.5–3× plus "no `RULE` regression in the
control set", and carry the ≥6× bar to end-of-P3.

## 5. Ordering correction, restated

1. `.harness/rules/` **is not deletable in P1.** It is the carrier `boundary-rule-in-agent-file`
   selected precisely because plugin-native agents cannot read anything else. Individual
   fragments may be merged or trimmed; the directory stays.
2. `insight-index.md`, `rejected-decisions.md`, `CONTEXT.md` move at the **end of P3**, when
   the memory layer that receives them exists. `rejected-decisions.md` governs this migration
   — every blocker in §1 above was found in it.
3. `R8`'s fix-level column (`docs/concepts.md:228–243`) is rewritten in the same commit as
   whatever deletion finally lands.

## 6. What is safe to delete in P1 regardless

Deletions with no carrier role and no consumer among the surviving agents — mechanical,
and independent of how §3 is resolved:

- state/scratch files: `.harness/entropy-watch.state`, `.harness/ambient.flag`
- the 7 skills §9.1 names (`harness-init`, `-adopt`, `-upgrade`, `-status`, `-intervene`,
  `-language`, `-supervise`) and their dedicated scripts — worth ~740 tok off the
  **resident** skill listing, the only measured floor reduction available
- archived-task bulk: tar `docs/features/_archived/` out of the repo **after** harvesting
  each `07_DELIVERY.md` (290 KB total) and `insight-history.md` (38 KB) into whatever P3
  lands. 6.4 MB leaves; 328 KB is kept.

Deleting the 7 skills also deletes `/harness-init`, which is how new projects are created.
**That is a product decision, not a cleanup** — it is the difference between harness-kit
being a distributable toolkit and being this repo's private workflow. It is listed here
because §9.1 lists it, not because it is safe.
