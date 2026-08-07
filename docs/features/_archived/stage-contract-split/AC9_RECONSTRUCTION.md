# AC-9 reconstruction — T-15 `hook-truth-verify-scope` under the stage-contract split

> Artifact for FR-10 / AC-9. New file in **this** task's folder; every span below was read from
> `docs/features/_archived/hook-truth-verify-scope/` **read-only**. No archived file was edited.

## Method (declared, not implied)

**Whole-section attribution at `##` / `###` boundaries**, not per-unit classification. Each section
is attributed to the destination of its **dominant** unit class under
`.harness/rules/70-doc-size.md` `## Stage-doc boundary rule`. Every section whose units are mixed
is listed below with its per-line adjustment, so the residual attribution error is published rather
than hidden. Section spans are half-open at the next heading; the arithmetic reconciles to each
file's exact `wc -l`.

This reconstruction is a **pure re-homing** of T-15's prose. It does not re-author. The further
reduction available from the typed shapes in each stage's `## What you produce` schema is real but
is **not** counted here, because counting it would require rewriting archived text and the
measurement would stop being falsifiable.

## Baselines (from `01_REQUIREMENT_ANALYSIS.md` §2.2 / §2.3, re-measured)

| File | Lines |
|---|---|
| `01_REQUIREMENT_ANALYSIS.md` | 254 |
| `02_SOLUTION_DESIGN.md` | 1152 |
| `03_GATE_REVIEW.md` | 243 |
| `04_DEVELOPMENT.md` | 903 |
| `05_CODE_REVIEW.md` | 196 |

Ingest today: stage 4 reads 01+02+03 = **1649**; stage 5 reads 01+02+04 = **2309**; stage 6 reads
01+02+04+05 = **2505**.

## 01_REQUIREMENT_ANALYSIS.md — 254L

| Span | Section | Destination | Lines | Row |
|---|---|---|---|---|
| 11–84 | `## 0. ASSESS-FIRST — is this row still worth building?` | rationale | 74 | 12 |
| 208–218 | `## 7. Related tasks` | rationale | 11 | 12 |
| — | everything else (title, goal, in-scope, out-of-scope, boundary conditions, acceptance criteria, NFRs, open questions' answers, verdict) | contract | 169 | 2 |

**Contract 169 · rationale 85 · routing log 0.** 169 + 85 = 254 ✓

## 02_SOLUTION_DESIGN.md — 1152L

| Span | Section | Destination | Lines | Row |
|---|---|---|---|---|
| 124–163 | `### 3.1 Bash — verify_all.sh, replacing :290-334` | **no home** | 40 | 9 |
| 164–240 | `### 3.2 PowerShell — verify_all.ps1, replacing :276-310` | **no home** | 77 | 9 |
| 493–504 | `### 8.1 CONTEXT.md append (exact)` | **no home** | 12 | 9 |
| 505–519 | `### 8.2 .harness/rejected-decisions.md append (exact)` | **no home** | 15 | 9 |
| 455–472 | `## 7. Reuse audit` | rationale | 18 | 12 |
| 547–626 | `## 10. Risk analysis` | rationale | 80 | 12 |
| 916–988 | `### 11.3 Evidence budget` | rationale | 73 | 12 |
| 1012–1023 | `## 14. Decided autonomously` | rationale | 12 | 12 |
| 1053–1074 | `## 16. Round 2 changelog` | routing log | 22 | 8 |
| 1075–1109 | `## 17. Round 3 changelog` | routing log | 35 | 8 |
| 1110–1152 | `## 18. Round 4 changelog` | routing log | 43 | 8 |
| — | everything else | contract | 725 | 2 / 5 |

**Contract 725 · rationale 183 · routing log 100 · no home 144.** 725 + 183 + 100 + 144 = 1152 ✓

The four `no home` spans are the flagship case AC-2 names: `:126-240` is a finished bash +
PowerShell body plus an 11-line comment destined verbatim for `verify_all`. Walked through the
table in order it reaches **row 9** — row 1 (no mechanism-read heading), row 2 (no declared shape
carries bytes; the only one that can, `## Byte-form specification`, is present only when row 3 or
row 4 matched), row 3 (no acceptance criterion demanded those characters), row 4 (a functional
statement — "the check asserts the four guard-rm files exist and the settings template carries
`{{GUARD_COMMAND}}` inside an anchored `PreToolUse` key" — is strictly shorter and satisfiable by
many spellings, so the disqualifier exists), row 5 (a fenced block is never a statement), rows 6–8
(no). **The replacement**, in the reconstructed contract, is one `## Constraints` statement:

> **K-1** — `verify_all`'s guard-wiring check asserts, in both shells and with identical basis and
> FAIL severity, that the four `guard-rm` files exist and that the settings template carries
> `{{GUARD_COMMAND}}` and a `"command"` key inside its `PreToolUse` containment window.

### Mixed sections in `02` and their adjustment

- `:162` sits inside the 124–163 span and is a contract statement charged to `no home` (−1 contract).
- `## 15. Verdict` (1024–1052, charged wholly to contract) carries ~6 lines of closing narrative
  that are rationale (+6 rationale, −6 contract).
- Net residual error ≤ 7 lines against 1152 — under 0.7 points of the reduction figure.

## 03_GATE_REVIEW.md — 243L

Attributed independently rather than inherited from the design's estimate.

| Span | Section | Destination | Lines |
|---|---|---|---|
| 1–8 | title + provenance note + upstream-verdict confirmation | contract | 8 |
| 9–28 | `## 0. Ruling on R-1 / D-1` | rationale | 20 |
| 29–43 | `## 1. Eight-dimension audit` | contract | 15 |
| 44–75 | `## 2. Findings` | contract | 32 |
| 76–101 | `## 3. Verified PASS statements` | rationale | 26 |
| 102–110 | `## 4. Predicted developer questions` | contract | 9 |
| 111–123 | `## 5. Conditions (binding)` | contract | 13 |
| 124–129 | `## 6. Verdict` | contract | 6 |
| 130–143 | round-2 document front matter + re-review scope | routing log | 14 |
| 144–158 | round 2 `## 1. Condition-by-condition ruling` — the 10-row `C-n \| ruling \| basis` table | contract | 15 |
| 159–194 | round 2 `### Verification of the load-bearing factual claims` | rationale | 36 |
| 195–214 | round 2 `## 2. New findings` | contract | 20 |
| 215–227 | round 2 `## 3. Invariants` | rationale | 13 |
| 228–243 | round 2 `## 4. Verdict` + six residual items | contract | 16 |

**Contract 134 · rationale 95 · routing log 14.** 134 + 95 + 14 = 243 ✓

Three deliberate departures from a lower estimate, each taken because the declared method attributes
at `##` **and `###`** boundaries and each block's dominant unit class is contract:

- the round-2 `## 4. Verdict` block is charged to **contract** because its six "residual items the
  developer carries into stage 4" are binding statements a later stage must satisfy (row 5, landing
  in `## Binding conditions`);
- the round-1 front matter is charged to contract because "upstream `01`/`02` are READY" is a
  statement stage 4 must verify;
- the round-2 `## 1. Condition-by-condition ruling` is **split at the `###` on `:159`**: its
  144–158 head is a 10-row condition table whose content is the stage-3 `## Binding conditions`
  `discharged by` column — contract by row 2 — while the `### Verification of the load-bearing
  factual claims` remainder is the gate's reasoning, rationale by row 12. Charging the whole 51-line
  span to rationale, as an earlier pass did, ran in the **optimistic** direction; 15 lines move back
  to contract, which lowers the reported reduction. That is the correct direction for a floor.

Under the new structure the two round blocks collapse into **one** set of sections corrected in
place — the 14 routing-log lines and the duplicated headings disappear — so 134 is an upper bound,
not a floor.

## 04_DEVELOPMENT.md — 903L

| Span | Section | Destination | Lines |
|---|---|---|---|
| 1–46 | title, `## Summary`, `## Files changed` | contract | 46 |
| 47–651 | `## S0` … `## S12` — captured runs, transcripts, per-step evidence | rationale | 605 |
| 652–681 | `## PowerShell surface added to the standing operator list` | contract | 30 |
| 682–692 | `## Gate residual items carried into stage 4` | contract | 11 |
| 693–735 | `## Design drift / discrepancies` | contract | 43 |
| 736–761 | `## Open issues for review` | contract | 26 |
| 762–770 | `## Dev-map updates` | contract | 9 |
| 771–785 | `## Insight to surface` | contract | 15 |
| 786–832 | `## Round 2 corrections (post-review, doc-record only)` | routing log | 47 |
| 833–895 | `## Round 3 correction (post-QA, one CHANGELOG line)` | routing log | 63 |
| 896–903 | `## Verdict` | contract | 8 |

**Contract 188 · rationale 605 · routing log 110.** 188 + 605 + 110 = 903 ✓

**Adjustment (published, applied):** the `## verify_all result` counts live inside the S-section
transcripts and are charged to rationale by whole-section attribution, but under the new schema
they are a 5-line `kv` contract section. Contract is therefore reported as **193**, rationale as
**600**. The adjustment is applied in the conservative direction — it makes the reduction smaller.

## 05_CODE_REVIEW.md — 196L

| Span | Section | Destination | Lines |
|---|---|---|---|
| 1–10 | title, provenance note, upstream verdicts, tooling limitation | contract | 10 |
| 11–24 | `## Files reviewed` | contract | 14 |
| 25–53 | `## Findings` | contract | 29 |
| 54–91 | `## Rulings on the four self-reported discrepancies` | rationale | 38 |
| 92–127 | `## Independent verification` | rationale | 36 |
| 128–155 | `## Requirement coverage check` | contract | 28 |
| 156–177 | `## Design fidelity check` | contract | 22 |
| 178–184 | `## Axis status` | contract | 7 |
| 185–196 | `## Verdict` | contract | 12 |

**Contract 122 · rationale 74 · routing log 0.** 122 + 74 = 196 ✓

## Result — lines each downstream stage must read

| Stage | Reads | Before | After | Reduction |
|---|---|---|---|---|
| 4 developer | 01 + 02 + 03 contracts | 1649 | 169 + 725 + 134 = **1028** | **37.7 %** |
| 5 code-reviewer | 01 + 02 + 04 contracts | 2309 | 169 + 725 + 193 = **1087** | **52.9 %** |
| 6 qa-tester | 01 + 02 + 04 + 05 contracts | 2505 | 169 + 725 + 193 + 122 = **1209** | **51.7 %** |

**AC-9's binding figure is stage 4 at ≥30 %. Measured: 37.7 % — met, with 7.7 points of margin.**

The design's §11.2 published 40.1 % for stage 4 on an estimate of ≈94 contract lines for
`03_GATE_REVIEW.md`. Attributed section by section against the live file, `03`'s contract measures
**134**, so the honest figure is **37.7 %**, not 40.1 %. The smaller number is reported rather than
the design's; under-reporting is the only safe direction for a criterion stated as a floor, and
where an attribution was arguable it was resolved toward contract for the same reason.

## Stated limitation

The reconstructed `02` contract is **725 lines** — still above the 500-line per-stage-doc cap. That
is a property of re-homing archived prose without re-authoring it, and it is exactly what the
typed shapes are for: `## 3. Module decomposition`'s 336 surviving contract lines become
`## Interfaces` rows and `## Constraints` statements in a document written under the new schema.
None of that reduction is counted above.
