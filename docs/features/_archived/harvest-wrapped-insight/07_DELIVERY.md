# Delivery Summary

- **Task:** T-20 `harvest-wrapped-insight` — make a wrapped `## Insight` bullet survive harvest with its continuation lines and evidence pointers, and make truncation detectable instead of silent at exit 0.
- **Mode:** full (7 stages), dispatched from a `/harness-stream` drain under `deferred-human mode`.
- **Delivered into:** the existing **unreleased v0.46.0** — no version bump. `plugin.json` already read `0.46.0` and T-16, T-17 and T-18 all delivered into that same unreleased version.

## Stages traversed

All on 2026-08-01.

| Stage | Rounds | Outcome |
|---|---|---|
| 1 requirement-analyst | 4 | `BLOCKED ON USER` → `READY`; rounds 3 and 4 were single-clause corrections |
| 2 solution-architect | 4 | `READY`; rounds 3 and 4 were prose-only |
| 3 gate-reviewer | 2 | `BLOCKED ON REQUIREMENTS` → **`APPROVED WITH CONDITIONS`** (X-6..X-12) |
| 4 developer | 4 | `READY FOR REVIEW` |
| 5 code-reviewer | 4 | `CHANGES REQUESTED` ×2 → **`APPROVED WITH NITS`**, "nothing remains that should block delivery" |
| 6 qa-tester | 2 | `CHANGES REQUIRED` → **`APPROVED FOR DELIVERY`**, 0 blocking |
| 7 PM | 1 | this document |

## Rollbacks

**Three**, plus one document-correction return I ruled separately.

1. **Stage 3 → 1.** The gate declined the architect's "closer block" widening: its rule order made a post-break bullet *ignorable*, re-creating inside the fix the exact defect class the task exists to remove. It also reversed my own stage-1 in-scope ruling on the template cap repair, on a measurement I had not made — the shipped template ships a 9-line header, so `F.4` already WARNs today and this task aggravates magnitude rather than flipping a verdict. I accepted the reversal without defending it.
2. **Stage 5 → 4.** Two MAJOR test-driver defects: a fixture-integrity row whose range was the one-element set, and an `AC-15` row hard-coding a count over a live corpus that this task's own archive would grow.
3. **Stage 6 → 4.** QA's `QA-1`, the serious one — see below.

The fourth stage-4 return would have tripped the three-rollback stop rule. I ruled it a **document-correction return rather than a rollback**, on the grounds that the code output was approved (the reviewer's words were "the code is right"), only a sibling record was stale, no code change or re-run was implied, and the trajectory was convergent rather than circling. The reviewer explicitly declined to soften that finding's severity to influence my routing and I did not use its restraint as cover; the full reasoning is in `PM_LOG.md`, together with the complement I bound myself to — escalate rather than reason past the rule a second time. It was not needed.

## Final verify_all result

**PASS 32 / WARN 0 / FAIL 0**, exit 0 — re-run three times by QA on this host and confirmed identical, with the check count of 32 counted from the run's own output rather than read from `baseline.json`. `verify_all` exits 1 on `warns > 0` in this repo, so a WARN would have been a gate failure.

Supporting runs, each independently re-executed by QA rather than accepted from the developer:

- `test-archive-task.sh` — **186 PASS / 0 FAIL**, exit 0, three runs with byte-identical stdout.
- The same driver against the git-extracted **pre-change** script — **84 PASS / 102 FAIL**, exit 1. Corroborated at the label level, not by totals: all 186 post-run PASS labels unique, 84 + 102 unique, set difference empty in both directions, and the stderr failure labels counted at 102.
- `sync-self.sh --check` — `In sync.`, exit 0; both `archive-task` mirror pairs byte-identical.
- Archived-corpus census — 41 delivery documents, 34 carrying a matching section, **34 clean / 0 unaccounted / 3 footer-bearing**, measured with QA's own walker.
- A randomized differential fuzz against an independently written CommonMark-plus-contract parser: **1181 documents across 4 seeds, 0 violations** of no-loss, no-silence and unterminated-refuses.

## Baseline changes

- New key `test_archive_task_bash_assertions`: **186** (transcribed from the run; the driver pair is new).
- `verify_all_checks`: **32**, unmoved. No check was added; `I.4` gained a condition and kept its id.
- New note `_qa_note_t20` carrying operator PowerShell item **17**. The standing list was at sixteen items and none was renumbered or reconciled.

## What was actually wrong, and what was fixed

The harvester emitted only lines matching the bullet marker, so a wrapped bullet lost every continuation line — silently, at exit 0, with the console echo reprinting the truncated first line so the result looked correct.

**Rotation was worse than the brief predicted.** The dispatch anticipated that rotation would *orphan* continuation lines. It did not: it derived its "header" as every non-bullet line in the whole index and re-emitted that block first, so a stored continuation line was **hoisted above every entry**. The analyst found this at stage 1 and the gate confirmed it independently.

Both are closed. Harvest, rotation, the stored-index read and the `I.4` gate now derive their answer from one classification of one file, so the three-way agreement the task required holds by the check running a single scan rather than by two predicates being maintained in step. An unaccounted line refuses at exit 3 **before any create, write, append or move** — QA verified the ordering directly, including with rotation pending.

## Outstanding risks

Everything below is measured and published, not inferred.

- **The unterminated-fence refusal is broader than it needs to be.** It fires whenever a fence is open at end of file, including when that fence provably hid no heading. Accepted as shipped because it errs loud every time — exit 3, nothing written, the opening line named — and because two independently executed censuses of all 41 archived delivery documents agree that it cannot fire on any of them.
- **A fenced code block inside a `## Insight` section is the one live hazard.** Directly under an entry, a bullet inside it becomes a real index entry and the fence markers reach the index at exit 0. After a blank line it refuses. This is `QA-9`, worth one driver row and one comment correction in a follow-up.
- **Pre-existing channels this task did not widen**, each reproduced so the bound is measured: content after a terminal thematic break is discarded at exit 0 with only a blank-inflated footer count as signal; a section authored with asterisk or numbered bullets is discarded whole; a balanced HTML comment closed after stored entries absorbs them permanently at `I.4` PASS; rotation is not transactional; and `--task ../../victim` traverses. All were byte-identical in the pre-change script.
- **The PowerShell twins ship green-by-symmetry.** PowerShell is not executable by agents here, so operator item 17 is the only evidence for them and it is mandatory rather than optional.
- **The generated-project cap check still counts physical lines.** The gate ruled repairing it scope expansion — it already WARNs today, before this task — and it is queued as a follow-up with both defects named by path and line in the requirement's out-of-scope section.

## Files changed

Shipped scripts: `.harness/scripts/archive-task.sh` and `.ps1`, their two `templates/common/` mirrors, and `.harness/scripts/verify_all.sh` and `.ps1` (`I.4` only). New dogfood-only driver pair `.harness/scripts/test-archive-task.sh` and `.ps1`. Supporting: `.harness/scripts/baseline.json`, `.harness/insight-index.md` (header sentence only — no entry line was edited), `.harness/rejected-decisions.md`, `CONTEXT.md`, `AI-GUIDE.md`, `docs/dev-map.md`, `docs/concepts.md`, `docs/tasks.md`, `CHANGELOG.md`, `.harness/rules/05-insight-index.md`, `.harness/rules/70-doc-size.md` and both template twins, `agents/pm-orchestrator.md`, `agents/developer.md`.

The working tree carries six sibling tasks' delivered-but-uncommitted changes, so a whole-tree diff is not this task's diff; the ledger above is the authoritative list.

## Notable process results

Recorded because they are what the pipeline bought, and because two of them are stages correcting themselves.

- **QA found a regression five stages had passed.** The first fix scanned only the first matching heading where the pre-change script re-armed on every one, dropping a harvested entry at exit 0 on a fixture inside the design's own regression floor. The task's entire subject is content silently discarded at exit 0, and the fix had opened a second channel for exactly that.
- **QA predicted a failure of this delivery and I acted on it.** It reproduced that a delivery document quoting a `## Insight` heading inside a fenced block would lose every real insight at exit 0 — "a shape this task's own delivery doc is unusually likely to have". The developer closed it in the script; QA then measured the residual precisely enough to give me a rule, and this document was written to it.
- **The code reviewer published why it had missed the regression**, as a reusable method rather than an apology: a regression floor is verified by the class it covers, never by the fixture it runs. Applying that test to its own next round produced two further findings.
- **The developer caught its own fix costing coverage.** Relaxing two exact-count assertions to floors silently voided anti-revert coverage, because the pre-change script prints no tally line and an unguarded shell expansion returns its operand unchanged — so the floor went green against the very script it exists to detect. Only the re-run caught it, and the repair was verified by diffing failure label sets rather than totals.
- **Three agents corrected a figure of mine.** My routing log claimed a label-set cardinality that was arithmetically impossible; the reviewer found it, QA upheld it at the artifact. In a task about a figure that looked right while being wrong, the PM produced one.

## Next steps for the user

1. **Run operator PowerShell item 17** in `baseline.json` — a parse check over all four `.ps1` files plus a run reproducing the acceptance criteria and the `QA-1` cases. This is the only evidence the PowerShell twins will ever have; items 1-16 are unchanged.
2. **Queue the follow-up** named in the requirement's out-of-scope section: the generated-project cap check's counted quantity, and the shipped `insight-index.md.tmpl` header sentence and example line.
3. **Consider `QA-9`** — one driver row plus one comment correction for a bullet inside a fenced block within an insight section.
4. When authoring a `07_DELIVERY.md`, keep fenced code blocks out of the `## Insight` section and keep every fence in the document balanced.

## Insight

These four entries are written in the **wrapped** form the task set out to make safe. The brief permitted this once the fix was proven, and it is: AC-1 verified, QA's live-shape reproducer landed four wrapped entries with their continuation lines against a copy of the real 30-entry index, and this archive is the end-to-end proof on the real artifact. The result was verified by re-reading the index, not by trusting the console echo — which is the failure this task exists to remove.

- 2026-08-01 · SUPERSEDES the 2026-08-01 entry stating that `archive-task`'s harvester drops the continuation lines of a wrapped bullet and that "one physical line per insight" is therefore a hard input contract. Both halves are now false: a wrapped entry survives harvest and rotation whole, and the index's cap counts entries rather than physical lines. What remains true from that entry is the shape of the hazard it recorded — a transport defect that reports success while discarding content is invisible to a gate that counts markers instead of content.
  · evidence: T-20, this archive
- 2026-08-01 · A regression floor is verified by the **class** it covers, never by the fixture it runs — and the question that finds the hole is the complementary one nobody asks: *which members of the admissible class does no row instantiate?* A code review checked that a byte-identity fixture was inside the design's stated admissible class and that the comparison was byte-level, and passed it twice; every fixture instantiating that class happened to be single-section, so a second member of the same class, on which pre and post differed at exit 0, went unnoticed until an adversarial stage with a shell constructed one. Applying the complementary question to the next round's new rows immediately produced two further findings.
  · evidence: T-20, QA-1 vs the round-2 AC-4 verification
- 2026-08-01 · Relaxing a frozen `== N` assertion to a `>= N` floor can silently void anti-revert coverage, because a pre-change script's output degrades to *garbage* rather than to a small number: bash's `${var##*needle}` returns its operand **unchanged** when the needle is absent, so an unguarded parse of an absent tally line turned every unmeasured item into a counted one and the floor went green against the very script it exists to detect. The totals barely moved (82/99 → 71/81 in an intermediate state), so only re-running the differential and diffing failure **label sets** exposed it. A relaxed assertion obliges you to re-measure the pre-change run, and to seed its parse with a non-numeric sentinel.
  · evidence: T-20, dev rounds 2-3 strict-parse fix
- 2026-08-01 · A tool that parses Markdown *about itself* must treat fenced blocks as opaque, and the skip must be **printed** rather than merely performed — the report is a precondition of the rule, not decoration. Making the harvester ignore a `## Insight` heading quoted inside a fence closes a real loss channel (a delivery document documenting the very heading it carries would otherwise harvest its own documentation example and rotate a genuine entry out at exit 0), but an unreported narrowing is inferable only from an entry that never arrived, which is the same silent-discard shape. Track the fence state **once** so opener and terminator cannot disagree about where a section is; scoping fence-awareness to discovery and leaving classification alone is what keeps a fenced line loud rather than ignorable.
  · evidence: T-20, K-71 + the Quoted-headings report
