# 03 — Gate Review · T-18 `stage-contract-split`

> Contract portion. Rationale: 03_RATIONALE.md (absent = none written).
> Persisted verbatim by PM: the gate-reviewer is read-only (no `Write`/`Edit` tool by contract).

- **Mode**: `full` (`/harness-stream` drain, deferred-human mode) · round 3, focused re-approval
- **Upstream**: `01` **READY** (481L, unchanged) · `02` **READY** (499L, rewritten normative rows) · `06` **CHANGES REQUIRED** (QA-1 CRITICAL, QA-2/3/4 MAJOR, QA-5/6 MINOR) routed 2→3
- **Schema gap (boundary-rule row 5)**: this front-matter block fits no declared stage-3 shape; "upstream `02` is READY" is a statement stage 4 must verify, so it is contract. Recorded as a `## Findings` row (F-34) per `agents/gate-reviewer.md:26-29`, not as an invented section.

## Dimension audit

| # | Dimension | Result | Reason |
|---|---|---|---|
| 1 | Requirement completeness | **PASS** | `01` is untouched and its AC-1 ("total and deterministic; exactly one destination per unit") proved to be a criterion that actually falsifies — it caught two successive versions of the construct it measures, which is what a testable criterion is for. |
| 2 | Design completeness | **PASS** | Every QA defect routed to stage 2 has a named corrective in the normative text (QA-1 → the six-step ladder; QA-2 → row 2's byte-form exclusion; QA-3 → row 6 inheriting row 5's definition plus a destination and a gap instruction), QA-4/QA-6 have ledger row E29, and QA-5 is decided in §5 with its reason. |
| 3 | Reuse correctness | **WARN** | §8's new `DELIVERED` row checks out — all four driver lines exist and read as claimed (`harness-stream/SKILL.md:67,126`; `harness-batch/SKILL.md:51,81`) — but the two skills are cited as reuse while appearing in no ledger row, no frozen-set row and no verification step (F-30). |
| 4 | Risk coverage | **WARN** | R9 now states the author-declared predicate as the residual and withdraws the unreproducible "zero units" clause, but no risk row covers the class insight-index L38 names — the prose sentences elsewhere that restate the amended row and now contradict it (F-25). |
| 5 | Migration safety | **PASS** | E29 adds headings to a *template*, so the 40 archived deliveries stay unedited and no AP-2 threshold moves; §10 order 2 applies E9 and E29 to one file in one pass with `git checkout --` rollback; and the edit raises the minimum conforming stage-7 document above the 15-line threshold without touching it, which discharges RES-1's margin-0 in the safe direction. |
| 6 | Boundary handling | **WARN** | The ladder is total by category — "Not units" is a general clause with examples, so QA's U-2 (`---`) is closed — and all three disputed units reach exactly one destination in my independent walk; three residual imprecisions remain at steps 1, 5 and 6 (F-27, F-28, F-29), none of which changed a destination in any construction I could build. |
| 7 | Test feasibility | **WARN** | V-2 now names six required probe classes including an unmarked-prose candidate and V-12 makes QA-4's fix measurable against the artifact, but no step verifies the two shipped sentences that restate the amended row 2 (F-25) and no step exercises the drivers E29's new token feeds (F-30). |
| 8 | Out-of-scope clarity | **PASS** | §14 restates every exclusion and adds the QA-5 decline with its stated reason and a `rejected-decisions.md:176` record I verified present; count stays 32, the operator PowerShell list stays at sixteen unrenumbered items, AP-2 thresholds and `_archived/**` are explicitly frozen, and no cap changes. |

## Findings

| id | severity | owning upstream doc + section | finding |
|---|---|---|---|
| F-22 | MINOR | `02` §6 E22, §7 P11 | Two closed per-task-document enumerations of the E25/E26/E27 class remain unledgered (`skills/harness-goal/SKILL.md:66-72`, `skills/harness-plan/SKILL.md:53-57`); both are output manifests, so neither misroutes a read. |
| **F-25** | **MAJOR** | `02` §2 ("the agreement paragraph (`:84-89`) stay byte-identical") + §6 E1, E17 | E1 freezes `70-doc-size.md:84-85`, whose clause "row 2 makes every declared shape contract" the round-3 amendment falsifies for a byte-form, and `CONTEXT.md:62-63` carries the same unconditional claim under an E17 cell that says "verifies presence only" — so following the ledger literally ships two prose sentences contradicting the amended row at the exact seam QA-2 broke (insight L38's class). |
| F-26 | MINOR | `02` §6 E17, shipped at `CONTEXT.md:72` | E17's round-3 glossary term collides with an existing one: `CONTEXT.md` now defines `**Byte-form**` twice with two different meanings (`:72` this task's; `:132` T-13's hook-command byte sequence), and nothing instructs anyone to notice. |
| F-27 | MINOR | `02` §2 unit ladder step 1 | Step 1 is triggered by section membership ("inside a section whose shape … declares") but two of its own enumerated units — the `> Contract portion.` header line and `key: value` front-matter lines — sit outside any section, and content inside a declared section that does not *fit* the declared shape matches step 1 without being named a unit; destinations were stable in every construction I built, because row 2 requires *fitting*. |
| F-28 | MINOR | `02` §2 unit ladder steps 5 vs 6 | Step 6's justification for splitting a paragraph ("when its sentences reach different destinations the paragraph splits") is not applied to step 5, so identical mixed content routes whole as a top-level bullet and splits as a paragraph, letting a row-10 sentence ride into the contract on a row-5 sibling. |
| F-29 | MINOR | `02` §2 unit ladder step 6 | Step 6 is the ladder's terminal step ("Otherwise…") but names its unit as "one sentence", so a top-level non-sentence fragment — a bold lead-in ending in a colon (`_archived/stream-defer-human/02:92`), a bare `key: value` line outside a declared shape — is named no unit by any step, and its two defensible readings (unit → row 14 rationale; non-unit → travels with what it introduces) land in different places. |
| F-30 | MINOR | `02` §6 E29, §7 (no P row), §11 V-12 | E29 puts a `DELIVERED`/blocked token into the delivery template that two drivers already read as a resume key, and while the effect on `harness-stream:67,126` and on `harness-batch:51,81`'s *primary* check is favourable (today those checks have no token to land on), `harness-batch:81`'s secondary fallback `Final verify_all result: PASS` still marks a non-`DELIVERED` delivery as done — and E29 makes such a delivery an authored form for the first time. |
| F-31 | MINOR | `02` §3 stage-7 row | The row created to fix a count claim off by one carries a count claim off by one: it calls `pm-orchestrator.md:199-207` "the existing **eight**-field list" and the template has nine bullets, one marked `<optional>`. |
| F-32 | MINOR | `02` §2 row 5, §13 | Row 5's "binding" predicate is a judgement whose mis-read direction is **starvation** — a binding sentence read as an argument lands in a rationale no consumer opens without a trigger — and §13 grades only the opposite direction (prose leaking into the contract); `_archived/hook-truth-verify-scope/02:236` sentence 1 walks to row 5 for me and to row 12 under QA's P-08 reading. |
| F-33 | MINOR | `02` §2 rows 5 and 6 | Rows 5 and 6 instruct "name the gap in the change ledger", a section only stage 2's schema declares, while the six agents each name a different destination (`## Resolved questions`, `## Findings`, `## Open issues for review`, `## Defects found`, `## Change ledger`) — so a cross-stage normative row hardcodes one stage's section name, and round 3 propagated it into row 6. |
| F-34 | MINOR | `02` §3 (all seven schemas) | The `- **Mode**` / `- **Upstream**` front-matter block is now the fourth instance in this task's own folder of a class row 5 sends to the contract that no schema declares (`02:9-11`, `06:7`, `04`, and this document), so every stage will log the same gap in perpetuity — four repetitions read as a missing declared shape rather than the designed exception Q-9 called it. |

## Binding conditions

| id | condition | owner stage | discharged by |
|---|---|---|---|
| C-1 | `verify_all` bash **PASS 32 / WARN 0 / FAIL 0**, exit 0, count 32, baseline captured before the first round-3 write. | 4 | travels |
| C-2 | No script, no `baseline.json`, no version stamp, no PowerShell surface; operator PowerShell list stays at **sixteen** unrenumbered items. | 4 | travels |
| C-3 | `## Adversarial tests` and `## Insight` byte-identical, matchers unchanged in all three template pairs and `archive-task.{sh,ps1}`; E29 must additionally leave `archive-task.sh:51`'s awk harvest bound intact (`## Verdict` after `## Insight` terminates the scan; it must not match `^##\s+Insights?\s*$`). | 4 / 6 | travels |
| C-4 | Every `agents/*.md` ≤300 and `.harness/rules/*.md` ≤200 by `wc -l` after the last edit, both figures recorded; publish `70-doc-size.md` and `pm-orchestrator.md` explicitly. | 4 | travels |
| C-5 | AC-1's probe runs against the **effective** rule (§2 and the §3 schema the unit would live in). | 6 | **discharged** — and it is what surfaced QA-1 and QA-2 |
| C-6 | V-4's expected observable restated against the real divergences. | 2 | **discharged** — QA A-7 reproduced exactly five |
| C-7 | E4's `## Byte-form specification` guards ship verbatim, and E1 must ship row 5's parenthetical in its amended form ("a fenced block **or a blockquote** is never a statement") plus row 6's inheritance of it, uncompressed. | 4 | travels — now belt to row 2's braces |
| C-8 | The row-4 / byte-form discrimination test is classified independently by developer and QA on candidates the design has **not** pre-walked; any disagreement is reported as an AC-1 failure, never reconciled. | 6 | travels — re-scope to the round-3 rule |
| C-9 | Row-4 bound restated so both conjuncts quantify over statements of the constraint. | 4 | **discharged** — shipped at `70-doc-size.md:76-82`, polarity verified correct |
| C-10 | E28 authored against what each template actually contains; the by-reference form recorded. | 4 | **discharged** — §6 E28 + V-11 now say "inline **or** by reference"; drift D-3 |
| C-11 | AP-2 thresholds are re-measured and **published**, never tuned; `agents/supervisor.md:93-101` byte-unchanged after E29. | 4 / 6 | travels — narrowed to V-12 |
| C-12 | F-22, F-26, F-27, F-29, F-31, F-32, F-33, F-34 are recorded for **disposition, not fix**: one line each in `## Condition disposition` stating addressed or deliberately left, with a reason. | 4 | travels |
| **C-13** | Before E1/E2 ship, reconcile the two sentences that restate the pre-amendment row 2: `70-doc-size.md:84-85` (the design's own current-state wording is at `02` §2's agreement paragraph — transcribe it, do not author it) and `CONTEXT.md:62-63`'s "contract by construction". Record as a `## Design drift` row if either wording differs from its source (F-25). | 4 | new |
| **C-14** | V-2's probe records **every** row that matches each unit, not only the first (insight L21: a first-match reading hides the hole), and adds five units: a multi-sentence top-level bullet outside a declared section; a top-level non-sentence fragment ending in a colon; a blockquote **not** marked verbatim; a fence nested inside a list item; and the FR-9 header line. Developer and QA classify independently; disagreement is an AC-1 failure. | 4 / 6 | new |
| **C-15** | Desk-check E29's token against the four driver lines (`harness-stream/SKILL.md:67,126`, `harness-batch/SKILL.md:51,81`) and record the disposition in `## Open issues for review`. Change no skill file — neither is in the ledger or the frozen set (F-30). | 4 | new |

## Pre-answered developer questions

| id | question | answer |
|---|---|---|
| Q-1 | "Run `sync-self` after editing `70-doc-size.md` + `.tmpl`?" | **No.** `sync-self.sh:58-93` maps 8 script pairs only; `E.1` runs `sync-self --check` and is unaffected. E1/E2 are hand-maintained lockstep — edit both, diff both (V-4). |
| Q-2 | "Will adding lines break `G.4`?" | **No.** `G.4` matches whole-file substrings, and its `[<version>]` requirement is met by the existing `## [0.46.0]`. Create no new version heading. |
| Q-4 | "Is WARN 0 the real baseline?" | Capture it yourself before the first edit and paste it; the tree carries ~89 uncommitted files and per insight L31 a claim about a dirty tree is not a proof. |
| Q-6 | "If the boundary rule and a stage schema disagree, which wins?" | For a **non-byte-form** in a declared section they cannot disagree (row 2). For a **byte-form** the rule wins by design — row 2 hands it to rows 3/4/9 even though the section would have accepted it. If you find a third case, that **is** the AC-1 failure: report it in `## Open issues for review`, do not adjudicate it. |
| Q-7 | "May I edit `_archived/`?" | **Never** (D3, `01` §6.6). E21 is a new file in this task's own folder and reads the archive read-only. |
| Q-8 | "§2 says the ladder ships but the worked walks and BF-1 do not — where is the line?" | `02` §2's opening paragraph now draws it explicitly: ship the ladder, "Not units", the "Verbatim byte-form" definition and rows 2/5/6; do **not** ship the row-4 *note*, the worked-walk table, BF-1 or the `01`/BC/FR pointers. "The row-4 note does not ship" means `02` §2's commentary about the bound — the bound itself at `70-doc-size.md:76-82` stays byte-identical, as E1's own cell says. |
| Q-9 | "My front-matter fits no declared shape — where does it go?" | **Row 5 → contract**, and report the gap where **your own agent** tells you to (`developer.md:21` → `## Open issues for review`), not "in the change ledger" — the rule's wording is stage-2-specific (F-33). |
| **Q-11** | "E1 projects `70-doc-size.md` 156 → ~170. Is that enough?" | Measured: the block at `02` §2:57-78 is 22 lines replacing 5, so expect **~173**, not ~170 — still 27 lines under the cap, so the split contingency does not fire. If it ever does, `E.4b` (`verify_all.sh:232-257`) is a **FAIL**-level check requiring the new fragment to be indexed in `AI-GUIDE.md` in the same pass. |
| **Q-12** | "E29 puts `## Summary` / `## Verdict` inside `pm-orchestrator.md`'s fenced template — does any check read agent headings?" | None that I read: `I.1`–`I.5` count lines only, `E.4b` matches rule filenames against `AI-GUIDE.md`, and AP-2 reads stage docs under `docs/features/`. Place `## Verdict` **after** `## Insight` as E29 says — that bounds `archive-task`'s harvest instead of extending it. |
| **Q-13** | "QA-4 says the minimum delivery is exactly 15 = the threshold. Do I raise the threshold?" | **No** — C-11 forbids it and §14 puts it out of scope. E29 fixes it from the authoring side: two mandatory headings raise the minimum conforming document above 15 without moving a threshold. V-12 re-measures and **publishes whatever it is**, including if it is still tight. |

## Verdict

**APPROVED WITH CONDITIONS** — C-1…C-4, C-7, C-8, C-11…C-15 travel to stage 4 and QA; C-5, C-6, C-9, C-10 are discharged.
