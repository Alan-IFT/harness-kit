# 03 — Gate Review: stream-auto-decompose (T-021)

> Mode: full · Reviewer: gate-reviewer · Date: 2026-06-12
> Inputs: `01_REQUIREMENT_ANALYSIS.md` (READY) + `02_SOLUTION_DESIGN.md` (READY) — both verified against the live tree, not trusted.
> Decision policy: Mode 2 — D-1 and all dispatch rulings adjudicated per `.harness/decision-rubric.md`; no red line touched.
> (Materialized verbatim by PM — the gate-reviewer thread had no Write tool; content authored by gate-reviewer.)

## 1. Audit checklist (8 dimensions)

| # | Dimension | Verdict | Reason |
|---|---|---|---|
| 1 | Requirement completeness | PASS | FR-1..FR-11 are observable/testable; counter-examples pin the negative space; all cited anchors (`SKILL.md:76,94,141`, hook ps1:46-62/sh:43-59) verified exact. |
| 2 | Design completeness | PASS | Every FR maps to a concrete edit site with shipped verbatim text for the load-bearing pieces (§3.1 triage section, §3.5 hard rule, §4 hook block). |
| 3 | Reuse correctness | PASS | Reuse table verified file-by-file: pool schema (`docs/batches/_template/BATCH_PLAN.md:9`), `## Notes` carrier (`:15`), failure semantics (`SKILL.md:102-104`), worked-example precedent (`docs/batches/README.md:52-56`), mode table (`AI-GUIDE.md:86-99`) — all exist as claimed. |
| 4 | Risk coverage | PASS | R1-R6 are the real risks; two unflagged residues found, both advisory (F-1, F-2). |
| 5 | Migration safety | PASS | Text-only, single commit, revert=rollback; consumer hook lag is benign and self-heals via `/harness-upgrade` (S2 refresh set includes the ambient pair — verified `CHANGELOG.md:15`). |
| 6 | Boundary handling | PASS | Empty/ambiguous/N=1/collision/failure/concurrency all specified; termination is triple-layered (see ruling 2). |
| 7 | Test feasibility | PASS | AC-1..AC-8 all mechanically checkable; one internal tension between the drafted text and QA's ≤198-line assert (F-2). |
| 8 | Out-of-scope clarity | PASS | RA §3 lists 9 explicit exclusions; the normative §3.1 text itself carves out `ADD`/hand-written rows, so the Developer cannot over-build by accident. |

## 2. Dispatch rulings (PM items 1-8)

1. **D-1 (single-sourced criteria) — CONFIRMED, meets AC-1's intent.** AC-1's intent is that an agent entering by either channel is *bound* by the criteria, not that the text appears twice. Both consumers carry a binding "per 'Ingest triage'" pointer inside the same 153-line file; duplication would recreate the intra-file drift class the operator's design-over-duplication preference and the T-016 insight (single-sourcing eliminates drift by construction) exist to kill. Condition C-1: pointers stay binding ("per"), never advisory ("see also") — drafted text already complies. QA must test AC-1 under this reading.
2. **Termination / fixed point — PASS.** Three independent layers prevent re-decomposition: (a) triage's only object is the incoming *message* being normalized — ambient step 1 triages "THIS user message", Procedure 3a triages "message(s) delivered with this tick's turn"; the per-turn pool re-read feeds *drain*, never triage; (b) §3.1: "an existing row is never re-triaged"; (c) the fixed-point bullet makes every produced row fail test 1. A produced row's Goal can never re-enter triage on a later pass because pool rows are never triage inputs. See F-4 for one wording-generality condition.
3. **Hard-rule amendment — PASS, union-equivalence both directions.** No added work: "Work the user did not ask for is never added" + "every row traces to a user requirement". No dropped work: "union of the derived Goals must equal the original requirement — no invented scope, no dropped scope". Dropping "silently" makes the rule strictly stronger. Restatement sweep (grep-verified): `SKILL.md:140` (mirror-to-pool) — consistent, N rows still mirror; `SKILL.md:142` ("never treat chat as tasks unless the flag is present") — flag-gating, orthogonal, untouched; Anti-patterns `:144-149` — no scope restatement; `skills/harness-batch/SKILL.md:71`, `skills/harness-intervene/SKILL.md:42`, `.harness/rules/65-intervention.md:53` — `ADD` semantics unchanged, wording stays true; `.harness/rules/25-decision-policy.md:52-53` — "tasks the user did not request are never invented autonomously (mirrors the `/harness-stream` rule)" stays truthful against the amended rule, no touch needed. Hook blocks carry "union ≡ the message" — consistent.
4. **Lockstep completeness — PASS.** All four carriers read; emitted blocks currently textually identical across the four; step 1 sits exactly at ps1:52-55 / sh:49-52 as cited; +2-line arithmetic correct (4→6 lines). Parity contract is checkable as defined (CR-stripped ps1↔sh block identity; dogfood↔template whole-file byte compare per extension). Test drivers grep-verified: **command-wiring asserts only** — `test-init.ps1:107,109,328,586,699`, `test-init.sh:45,51,291`, `test-real-project.ps1:113-114`, `test-real-project.sh:44-45,50-51`; no driver asserts on the emitted block's content; the placeholder scan stays green (no `{{` in the proposed text). RA AC-8 claim confirmed.
5. **Fan-out completeness — PASS, no missed surface.** Independent sweep: the singular-ingest wording lives only in `SKILL.md:76,94` + the four hook files (grep evidence). Candidates checked and clean: `docs/concepts.md` / `docs/workflow.md` / `evals/golden-tasks.md` — zero stream mentions; `docs/getting-started.md:45`, `docs/dev-map.md:57,96-97,115`, `docs/manual-e2e-test.md:36/54/62`, `docs/tasks.md`, `skills/harness-status/SKILL.md:111,115`, `skills/harness-adopt/SKILL.md:189,313,336`, `skills/harness-init/SKILL.md:189-190` — enumerations/hook-wiring only, no granularity claims; `docs/batches/README.md:19` "one row per task" is batch-plan *authoring*, not stream ingest — correctly untouched; no EN html carries a normalize-into-row claim; `docs/harness-stream.html` self-pins v0.22.0 (`<title>` line 6 + badge line 57) — RA's snapshot ruling is sound (precedent: project-overview.html). G.4 ledger: all 11 rows checked — none pins harness-stream SKILL text or any count this change moves. The design's one addition beyond RA §6 (README badges, D-6) was the only real gap, and it caught it.
6. **Version/G.4 compliance — PASS** (one citation correction, F-3). `plugin.json:4` and `marketplace.json:17` both read `0.31.0`; bump set complete. G.4 (`verify_all.sh:700-786`): CHANGELOG `[0.32.0]` heading check at `:776` satisfied same-commit; the 11 count-claims all stay `32` and untouched; README G.4 expects are the count badge only (`:737-738,750-751`), so the roadmap row's literal "32 checks" (which matches the live count) cannot interfere; no new G.4 rows → no same-file expect-uniqueness trap. G.1/G.2 enumerate 15 skill names (`verify_all.sh:329,345`) — no new skill, counts stay 15/32.
7. **I.6 safety — PASS.** Banned list read (`verify_all.sh:521-536`, 14 entries): all are CLAUDE.md-composition anchors + `全程~中文` + "scaffolding-only". None of the drafted §3.1 / §3.5 / hook / README / batches-README sentences contains any banned ordered-anchor sequence (none even mentions CLAUDE.md; no zh-policy sequence). CHANGELOG and `docs/features/` are exempt (`:516-519,547-560`). AD-4 (no new banned entry) is consistent with the 4-file-lockstep cost (insight 2026-06-08). Final authority remains the run (AC-6) — run, don't reason.
8. **Riskiest unflagged residue** — F-1 below (live-session ambient arming during QA's hook probe).

## 3. Findings

- **F-1 (ADVISORY · design §12.2)** — QA's hook-parity probe runs all four hooks "with `.harness/ambient.flag` present" without specifying isolation. Creating that flag in THIS repo arms ambient mode for the operator's live session: the next real user turn injects the ambient block and triggers a live ingest+drain of `docs/batches/default/` mid-task. Required action (QA dispatch condition): run the probe in an isolated temp root (a temp dir containing a `.git` marker + the flag + copies of the four scripts — the hooks resolve the root by walking up from CWD, so this fully isolates them), or delete the flag within the same turn it is created.
- **F-2 (ADVISORY · design §3 / §12.7)** — Budget arithmetic is internally inconsistent: §3 claims the new section is "≤ 34 lines" but the drafted block is 40 physical lines (heading + blanks included); summing the drafted edits (153 + ~41 + 5 net hard-rule + 1 anti-pattern bullet + wraps) projects ~200-202 lines against the self-imposed ≤198 that QA step 7 asserts. Applying the text verbatim breaks the design's own QA assert. Required action (Developer): trim §3.1 wording per the design's own R2 fallback — contract terms (applies-to scope, both criteria, three counter-examples, slug/union/deps/mode/fixed-point/dedup/announce, 1:1 fallback) are untrimmable; or PM re-baselines the QA assert. No verify_all gate counts skill lines, so this is discipline, not a gate risk.
- **F-3 (ADVISORY · design §5 badge row)** — The README version badge is attributed to "repo convention (CHANGELOG.md:23)"; it is in fact hard-gated by **G.3** (`verify_all.sh:363-370` extracts both README badge versions and compares them to plugin.json). No plan change needed — the badges are already in the edit set — but the Developer should know omitting them FAILs G.3, not merely convention.
- **F-4 (ADVISORY · design §3.1 first paragraph)** — The never-re-triage clause rides in the sentence about user-authored rows ("It NEVER applies to rows the user authored — … and an existing row is never re-triaged"). Binding interpretation, confirmed here: the clause is general — ANY existing pool row, user-authored or stream-derived, is never re-triaged; triage's only input is the message being normalized. The Developer must preserve this generality through any F-2 trimming or line re-wrapping.

No BLOCKING findings.

## 4. High-probability developer questions (pre-answered)

1. *Must the criteria appear in both Procedure 3a and the ambient section?* No — D-1 confirmed (ruling 1). Single section + binding "per 'Ingest triage'" pointers in both consumers.
2. *Exact version-bump set?* `plugin.json:4`, `marketplace.json:17`, `README.md:5` badge, `README.zh-CN.md:5` badge (G.3-gated), CHANGELOG `[0.32.0]` heading (G.4:776-gated) — all in one commit.
3. *Do I edit `25-decision-policy.md:53`?* No — verified truthful against the amended rule. CHECK-ONLY stays CHECK-ONLY.
4. *Hook lockstep mechanics?* Replace only step 1 of the emitted block (ps1:52-55 / sh:49-52) in all four files, one commit, native EOL per file, no `{{` anywhere, no sync-self (hand-lockstep pair per `AI-GUIDE.md:81`). Verify: dogfood↔template byte compare per extension; ps1↔sh CR-stripped block identity.
5. *Will any test driver break?* No driver pins hook block content or harness-stream SKILL text (grep-verified, §2.4). They must stay green WITHOUT modification — if one reds, that is a defect in the change, not the driver.
6. *Is "32 checks" in the new README roadmap row G.4-safe?* Yes — README's G.4 expect is the badge form only, and the literal matches the live count.

## 5. Verdict

**APPROVED FOR DEVELOPMENT.**

Binding conditions for the Developer:
- **C-1** Apply D-1 as confirmed: binding pointers, no criteria duplication (ruling 1).
- **C-2** Preserve through any trimming: the union invariant + "never add unrequested work" + "user-authored rows never split" trio (§3.5), and the *general* never-re-triage clause (F-4).
- **C-3** Resolve F-2: trim §3.1 wording to land `skills/harness-stream/SKILL.md` ≤ 198 lines, or surface to PM for a QA re-baseline before QA runs.
- **C-4** All four hook carriers in one commit, +2 emitted lines, no `{{` token (F-3 noted: badges are G.3-gated).

Binding condition for QA: run the hook-execution probes in an isolated temp root, never by arming `.harness/ambient.flag` in the live repo (F-1); test AC-1 under the D-1 reading.
