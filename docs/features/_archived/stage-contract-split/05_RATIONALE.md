# 05_RATIONALE.md — Code Review · T-18 `stage-contract-split` (round 3)

> Rationale portion for 05_CODE_REVIEW.md. Non-binding.
> Persisted verbatim by PM: the code-reviewer is read-only (no `Write`/`Edit` tool by contract).

**Why this portion exists.** Round 2's review carried its walks as prose paragraphs inside the
contract and logged the schema gap. The boundary rule's row 12 sends a measurement narrative or an
evidence citation supporting a contract unit to the rationale, so this round the walks live here and
the `## Findings` rows stay self-contained — QA should not need this file to re-test a finding, and
T6.3 exists for the case where it does.

**Files opened**: both `70-doc-size.md` twins (full); `agents/pm-orchestrator.md`, `code-reviewer.md`,
`solution-architect.md:16-57`, `supervisor.md:88-115`; `CONTEXT.md:50-79,176-186`; `CHANGELOG.md:1-25`;
`.harness/scripts/archive-task.{sh,ps1}` + both `templates/common/` twins; `skills/harness-batch/SKILL.md:45-86`;
`skills/harness-stream/SKILL.md`; `02:1-248`; `03`; `03_RATIONALE`; `04`; `06`; `PM_LOG.md:400-443`;
`docs/tasks.md:1-14`; six repo-wide sweeps.

**AC-2, walked against the shipped bytes with the row-2 guard removed.** The point of doing it twice
is that C-7 made the whole structural claim rest on one agent file; after the amendment it should
rest on the rule as well, and it does. Unit = `_archived/hook-truth-verify-scope/02:126-160`, a
35-line bash fence. Ladder **step 2** makes it one unit, fence lines included. Row 1: the enclosing
heading is `### 3.1 Bash — …`, read by no shipped mechanism. Row 2: **excluded** — the design offers
it as the characters to be transcribed, which is the shipped definition at `:62-66`, so rows 3/4/9
decide it; and independently, of the twelve declared stage-2 shapes the only byte-carrying one is
`## Byte-form specification`, gated at `agents/solution-architect.md:24` on rows 3/4 having matched.
Row 3: no acceptance criterion demanded those characters — T-15's own `:118-122` withdrew the
byte-level recipe as unsatisfiable. Row 4: **rejected**, because a shorter multi-satisfiable statement
exists (`AC9_RECONSTRUCTION.md:72-74` publishes it). Rows 5 and 6: rejected on the fence clause, twice
now. Rows 7, 8: no. **Row 9 → `no home`**, with the rule itself directing the author to write the
constraint under row 5. The belt and the braces each hold alone.

**QA-3's smuggle, re-run by me against the shipped row 6.** `**OQ-3's answer**:` followed by a
115-line fence. Step 2 makes the fence its own unit — the lead-in is a separate unit — so the fence
walks rows 1–4 as above, then meets `:83`, which now reads "row 5's definition applies: one sentence,
and a fenced block or a blockquote is never a statement". Row 6 rejects it on exactly the clause row 5
rejects it on, and it falls to **row 9**. The blockquote variant dies on "or a blockquote". This is
the attack that broke round 2's text; it is closed in the bytes, not in a report about them.

**CR-12 — the walk that produces a third outcome.** Unit: one sentence introduced on the previous
line by "replace `SKILL.md:115` with:", written as plain prose — not fenced, not blockquoted — and
fitting no declared shape of the authoring stage. Ladder: step 2 no, step 3 no (no `>` run), step 5
no, **step 6** names the sentence. Rows: 1 no; **2 is inapplicable**, because it requires the unit to
*fit* a declared shape and this one does not — so its exclusion never fires; 3 no; **4 rejected**
whenever a strictly shorter, multi-satisfiable statement of the constraint exists; **5 matches** — it
is one sentence, not a fence, not a blockquote, and it binds a later stage to transcribe it →
**contract**. Row 9 is never reached. `03_RATIONALE.md:14` predicts "row 4 … or row 9. Either way it
no longer enters an arbitrary `stmt` section unlabelled"; here it enters the contract as a row-5
statement, unlabelled, without the `## Byte-form specification` gate.

Why this is MINOR and not MAJOR. AC-1 measures totality and determinism, and both hold: the unit gets
exactly one destination by one row, reproducibly. What the path costs is *labelling*, not containment
— and at one sentence the byte-form and the constraint row 9 would have you write instead are
materially the same text. The class QA sized at 27 of 38 was blockquoted-and-marked content, and row
5's syntactic blockquote clause closes it regardless of author intent, which is the stronger property
the gate's rationale correctly credits. My correction is narrow: the concession `02` §13 row 4 and R9
grade for *unmarked* prose should be stated for *marked one-sentence* prose too. The mirror-image
direction — a binding sentence mis-read as an argument and starved in a rationale — is F-32, left for
disposition, and my walk does not change it.

**CR-10 — reconstructing the minimum delivery.** From `agents/pm-orchestrator.md:199-232`, omitting
the two fields the template marks optional (`Outstanding risks: <if any>`, `Next steps for user:
<optional>`): `# Delivery Summary` · blank · `## Summary` · blank · seven `kv` fields · blank ·
`## Verdict` · blank · `DELIVERED` = **15**. AP-2's stage-7 minimum is 15, so this passes with zero
slack; one further omission WARNs. The gate's dimension-5 PASS reason at `03:18` — "the edit raises
the minimum conforming stage-7 document above the 15-line threshold" — is falsified by the shipped
template, and the developer published the counter-measurement instead of tuning the threshold, which
is the behaviour C-11 and Q-13 asked for and the right call. The unledgered two-line fix is already
mandated elsewhere: `02` §3:147-148 says every contract opens with the FR-9 header line, and stage 7
is the only contract whose authoring template omits it.

**CR-9 — why a transcription can be faithful and still wrong.** I compared `70-doc-size.md:101-103`
word for word against `02` §2:131-133 and they are identical, which is precisely what C-13 demanded
("transcribe it, do not author it"). The defect travelled with the source: "row 2 **now** hands to
rows 3/4/9 **rather than blessing**" is a two-clause claim about a superseded draft, shipped into a
rule fragment whose reader — especially the `/harness-init` twin's reader in a fresh project — has no
access to the draft being contrasted. The rule routes exactly this class to `PM_LOG.md` at row 8 and
forbids it in a stage document three paragraphs later. Flagging the source rather than the transcriber
is the only correct attribution here; had the developer smoothed the wording, that would have been the
finding instead.

**On the `archive-task` boundary.** I checked this against the script rather than the report because a
mis-placed heading changes what gets harvested silently, with no error and no WARN — the exact
false-green `02` §3:160-164 exists to prevent. Two properties matter and both hold: `## Verdict`
cannot match `^##[[:space:]]+Insights?[[:space:]]*$`, and it does match the terminator
`/^##[[:space:]]/`, so the harvest window is `## Insight` → `## Verdict` and returns only the real
bullets. One ordering assumption is worth naming for whoever edits this template next: the guarantee
depends on `## Summary`'s `kv` bullets sitting **above** `## Insight`. They do, and `:194-195` fixes
`## Verdict` last, so the produced document is safe; but the awk has no notion of section order, and
an editor who moved `## Insight` above the field list would harvest nine `kv` lines into
`insight-index.md` without any check firing.

**On what I could not verify.** No `Bash` means no `git diff`, so every "byte-unchanged" claim in my
contract portion is a content-read against a recorded specification, not a diff: `agents/supervisor.md`
`:93-101` reads exactly as `02` §3/§6 record it and no minimum-line value differs, which is strong but
is not the byte-identity C-11 asks for; the row-4 bound reads exactly as round 2 recorded it, at
`:93-99` rather than the `:94-100` the drift row cites. The mtime argument `04:94` offers for
`supervisor.md` is not evidence I can check at all. QA holds the diff, the `verify_all` run and the
unit probe, and RES-4 says so rather than letting the gap decay into an assumption.
