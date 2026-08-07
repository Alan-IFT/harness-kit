> Contract portion. Rationale: 06_RATIONALE.md (absent = none written).

## Test plan

| Acceptance criterion | Test case(s) | File |
|---|---|---|
| AC-1 (stage 3) — one reviewer contract yields the writer's name, unconditionally | full read of the shipped file; ADV-1 grep for any surviving conditional write clause; sentence-level write-act classifier | `agents/gate-reviewer.md:14-16`; classifier in `06_RATIONALE.md` §1 |
| AC-1 (stage 5) — same | full read; same two probes | `agents/code-reviewer.md:14-16` |
| AC-2 — orchestrator contract yields its own stage-3/5 obligation | full read of `:26-53`; ADV-2 contradiction hunt over every `gate-reviewer`/`code-reviewer` mention in the file | `agents/pm-orchestrator.md:30,:32,:44-53` |
| AC-3 — role × act table, one owner per cell, no empty, no contradicted | table rebuilt from the three shipped files (not from `05_RATIONALE.md` §A); ADV-2 + ADV-3 as the contradiction probes | `06_RATIONALE.md` §2 |
| AC-4 — code reviewer's hard rules and `## What you produce` agree | read both sites; ADV-3 grep over every read-only assertion in the file | `agents/code-reviewer.md:101` vs `:14-16` |
| AC-5 — every attribution site dispositioned | fingerprint sweep (`--hidden`) + disposition of the two sites CR-3/G-24 named | `06_RATIONALE.md` §3 |
| AC-6 — `verify_all` 32/0/0, exit 0, count read from the run | three live runs of `.harness/scripts/verify_all.sh` | `06_RATIONALE.md` §4 |
| AC-7 — every capped file ≤ 300 by live count | `wc -l` over all eight agent contracts | `06_RATIONALE.md` §4 |
| AC-8 — behavioral: produced file carries (a) opening line, (b) declared sections, (c) no round/changelog section | observation on the probe bytes (variant A, variant B, differential control) | `scratchpad/ac8/**` |
| AC-9 — round 2 replaced in place, round record to `PM_LOG.md` only | sha/diff across rounds; `PM_LOG.md` inspection; heading scan for an appended round section | `scratchpad/ac8/variant{A,B}/` |
| AC-10 — mutation: deleting each write-act statement leaves AC-1/AC-2 unanswered | three mutants cut on working copies in scratch, then re-classified | `scratchpad/mut/{pm,gr,cr}.md` |
| AC-11 — 32 identifiers, none renamed | identifier list extracted from each of the three runs, compared to `04_DEVELOPMENT.md:35` | `06_RATIONALE.md` §4 |
| AC-12 — no `.ps1` surface created by this task | `git status --porcelain` for `??` rows + fingerprint exclusion | `06_RATIONALE.md` §3 |

`## Boundary tests added` and `## Adversarial tests` below carry the probes that are not one-to-one
with a criterion. **No executable test was added**: R-11 freezes the check count at 32 and this
change has no executable surface, so every probe here is a re-runnable command published in
`06_RATIONALE.md` rather than a new row in a driver.

## Adversarial tests

Each row states the failure I expected before running, an independent reproducer I wrote from the
acceptance criterion (never from `04_DEVELOPMENT.md`'s or `05_RATIONALE.md`'s own method), and the
measured outcome. Full runs in `06_RATIONALE.md`.

| AC | Hypothesis ("I expect failure when…") | Reproducer | Outcome |
|---|---|---|---|
| AC-1 | G5's deletion left a *different* conditional somewhere, so the answer is still conditioned on a fact stated elsewhere in the file | ADV-1 (NEW): `grep -niE 'if you (have\|had) no .?(Write\|write)\|if you cannot write\|when you have no write\|if the PM\|unless you' agents/gate-reviewer.md agents/code-reviewer.md` | **Survived** — `(none)`. No conditional survives in either file; `:14-16` answers unconditionally in both. |
| AC-2 | the file contradicts itself: `:10` says "You do not write requirements, designs, or code yourself" and `:95-99` names the PM as a writer, so a reader gets two answers | ADV-2 (NEW): full read of `:9-22`, `:26-53`, `:93-99` + `grep -niE 'gate-reviewer\|code-reviewer' agents/pm-orchestrator.md` (5 hits, each classified) | **Survived** — `:10`'s object set is {requirements, designs, code} and carries "yourself"; P5 (`:48`) says the transcription authors no part; `:95-99` names a different path (`PM_LOG.md`) and a different act. `:118` and `:192` say "skip"/"produced", no write verb. No contradicted cell. |
| AC-3 | the "emit the header" act or the "correct in place on round N ≥ 2" act is claimed by two roles once the anaphors are resolved on the shipped bytes | table rebuilt from the three files by hand (`06_RATIONALE.md` §2), not read from `05_RATIONALE.md` §A | **Survived** — 9 acts × 2 stages, every cell exactly one owner, no empty cell, no contradicted cell. Round N ≥ 2 splits cleanly: author the corrected body (reviewer, `gr:34-35`/`cr:36-37`) vs overwrite the path (PM, `pm:52-53`). |
| AC-4 | a *third* read-only assertion elsewhere in `code-reviewer.md` still contradicts authorship, so the two sites agree only because the audit looked at two of three | ADV-3 (NEW): `grep -niE 'read-only\|do not (edit\|modify\|write)\|never (edit\|write)\|Editing' agents/gate-reviewer.md agents/code-reviewer.md` | **Survived** — 5 hits total, all extensional or scoped: `cr:100` (code), `cr:101` (K5, with the "author but do not persist" pointer), `cr:175` / `gr:123` ("Editing code" / "Editing upstream documents"), `gr:86` (G6). None asserts the role does not author its own report. |
| AC-5 | the developer's `--hidden` correction still leaves an attribution site outside the published set | fingerprint sweep (NEW): `grep -rn --hidden --exclude-dir=.git -lE "the PM Orchestrator writes them\|Stage-3 / stage-5 transcription\|see the transcription rule below\|verbatim, authoring no part" .` | **Survived, with one publication gap confirmed** — 6 files, exactly the 3 agent contracts + 3 of this task's own docs. The two sites CR-3/G-24 named (`skills/harness-init/SKILL.md:83,:291`) are role-name enumerations with no verb; disposition published in `06_RATIONALE.md` §3. Filed **QA-5**. |
| AC-6 / AC-11 | the developer's 32/0/0 was a single lucky run, or an identifier moved | three live runs of `bash .harness/scripts/verify_all.sh`, identifier list extracted from each | **Survived** — `PASS: 32  WARN: 0  FAIL: 0`, exit 0, ×3. Identifier sequence md5 `3c71cadb…` identical across all three and equal to `04_DEVELOPMENT.md:35`. |
| AC-7 | the count skew `05_RATIONALE.md` §C describes means some file is really over 300 | `wc -l agents/*.md` over all eight, not only the four cited | **Survived** — 296 / 125 / 177 / 287 for the four; max over all eight is 296. Four lines of headroom on the capped file. |
| AC-8 | the writer normalised the body — a trailing newline, a re-wrap, or a helpfully-inserted heading — so the file is *shaped like* the return without being it | observation on bytes: `sed -n 1p`, `grep -n '^#'`, `tail -3`, round/changelog scan, `tail -c1 \| od`, `sha256sum` over both variants | **Survived** — (a) line 1 is the declared line verbatim; (b) exactly the 5 declared headings in declared order, nothing else; (c) no round/changelog/superseded heading; last byte `0a`; **variant A and variant B are byte-identical to each other** (`3f1aac85…`). |
| AC-8 control | the control passes (a) anyway, which would mean the observable is not caused by the contract text | same observation on `returned_body_CONTROL.md` and on `control/` | **FAILED as required** — line 1 is `# 03 — Gate Review: review-write-path (T-23)`; headings are `## 1. Audit checklist … ## 4. Verdict`; no `03_GATE_REVIEW.md` was written. Control must-fail holds; bound in **QA-6/RES-B**. |
| AC-9 | round 2 appended rather than replaced, or the round record leaked into the document — the exact T-22 shape | `diff returned_body_POST.md round2_body.md`; heading scan of the round-2 file; `cat variant{A,B}/PM_LOG.md` | **Survived** — 2 changed lines (`:39` severity, `:81` verdict), same 81 lines, same path, no `## Round N` heading, `PM_LOG.md` is exactly one line: `round 2 · verdict raised to APPROVED, G-20 downgraded to MINOR · G-20`. |
| AC-9 (T-22 lesson) | the round-2 edit is line-count-preserving, so `wc -l` and a line diff both miss it | `wc -lc` + `sha256sum` on both rounds | **Confirmed the hazard, arrangement survived** — 81 lines both rounds, 17693 → 17677 bytes; only the digest moves. Instrument choice mattered. |
| AC-10 | CR-5 is right that P4 dies with P3, and something *else* also dies that leaves the file incoherent rather than merely unanswered | three cuts on working copies (NEW script, `06_RATIONALE.md` §5), then the sentence-level write-act classifier | **Bites exactly as CR-5 predicts** — shipped files have 1 write-act statement each; mutants have **0**. PM residue is P1, P2, P5, P6, P7 (**not** P4, as `02` predicted). Mutant `gate-reviewer` retains only `**You hold no write capability.**` plus antecedent-less anaphors. |
| AC-12 | this task created a `.ps1` and the operator list must move | `git status --porcelain \| grep '^??'` + fingerprint exclusion of every `.ps1` in the tree | **Survived** — three untracked `.ps1` exist (`hook-spec.ps1` ×2, `test-archive-task.ps1`) and **none carries this task's fingerprint**; they belong to earlier rows in this drain. This task's six paths contain no `.ps1`. Operator list stays 25 (17 + 8). |
| **C-11 / G-20** | the two readings of "ends with its `## Verdict` line" disagree on real documents, and a strict writer would have wedged the round | ADV-5 (NEW): both readings applied to 5 real stage-3/5 documents | **Ambiguity reproduced 5/5; arrangement survived** — heading-reading FAILs on every conforming document ever produced here, token-reading PASSes on all 5. Both probe writers applied the **verdict-token** reading; **neither routed back a compliant body**, so C-11's `BLOCKED ON DESIGN` trigger did not fire. Per C-11 this pass is *not* evidence of unambiguity. Filed **QA-2**. |
| **C-12 / G-21** | observable (e) as `02` writes it cannot be measured, because shipped G8 orders header-then-body | re-derivation against `gate-reviewer.md:65-69` + inspection of the handed artifacts for a header | **(e) NOT MEASURED, and unsatisfiable as written** — G8 says "End your final message with a header, then the body", so a *conforming* message ends with the **body**. Independently, the handed files are body-only (`returned_body_POST.md` line 1 is the declared opening line; no header anywhere), so no header survived the handover. What I could measure: the control writer's log records the control arm returned **no header at all**. Filed **QA-1**. Never reported as passed. |
| **C-13 / G-22** | executing step 6(a)'s `:14-15` citation literally measures G1 and mis-scores (a) | live re-derivation before any comparison | **Stale citation confirmed; not executed** — `agents/gate-reviewer.md:14-16` is G1; the declared opening line is at `:18-19` (`agents/code-reviewer.md:18-19` for stage 5). (a) was scored against the `:19` string. |
| **G-25 confound** | "a `tools:` line is not self-enforcing" is a real runtime property, which would undercut OQ-1's decisive leg | ADV-6 (NEW): search every genuine review-stage dispatch in the repo for a shell claim or a no-shell admission; check the registered tool grants in the build a real dispatch loads | **Alternative explanation confirmed; claim is an artifact** — 15 stage-3/5 documents across ≥13 dispatches record `Read/Glob/Grep only`, "no shell", "no execution"; **zero** counter-instances. The one shell-holding arm was dispatched `general-purpose` (C-7). Adjudication in `06_RATIONALE.md` §6. Filed **QA-4** in narrowed form; **the striking claim does not reach permanent memory.** |

**C-9, discharged.** Observable **(d)** — "the file is byte-identical to the returned body" — is
captured by the party under test: the PM is both the writer and the only party that could record
what the sub-agent returned, so a uniformly-reshaping writer passes (d). My **AC-8 verdict rests on
(a), (b) and (c)**, which are absolute against the schema in `agents/gate-reviewer.md:18-29` and
need no artifact the writer produced. (d) and (e) are corroboration only: (d) reproduces for round 2
(`variantA` = `variantB` = `round2_body.md`, sha `3f1aac85…`), and (e) is **not measured** (QA-1).
One corroboration is stronger than (d) alone and is *not* self-referential: **variant A and variant
B produced byte-identical files** while holding different instruction sets (P-block vs in-band
header only), so a reshaping writer would have had to reshape identically under two different
inputs.

**The probe's method bound, stated.** Each writer received the returned body as a **scratch file
path**, not inline in a message. That licenses the claim that the writer *persisted what it was
given without altering it* — the P5 "authors no part" property — and it licenses (a)–(c), which are
properties of the bytes on disk. It does **not** license any claim about the PM's ability to
**receive** a body intact across a message boundary: truncation, re-wrapping and elision in the
message channel are precisely what a file hand-off removes, and RES-2 (interior loss) and B-4
(oversized return) are therefore **untested by this probe**, not merely bounded by it. It also
weakens P6(c), whose subject is a *header in a message*: with the payload arriving by path, the
header/portion correspondence has nothing to range over — which is exactly the vacuity the control
writer recorded rather than passing.

## Boundary tests added

- **Empty rationale (B-1).** No rationale portion was returned by any arm; no `03_RATIONALE.md`
  exists under `variantA/`, `variantB/` or `control/`. Absence is the normal state. *The converse
  case — a rationale portion returned and transcribed — has no behavioral row (QA-6).*
- **Round N ≥ 2 (B-2).** Exercised in both variants: same path, content replaced, 2-line delta, no
  appended section, round record in `PM_LOG.md` only (1 line, no round section in the document).
- **Line-count-preserving mutation (T-22 insight).** Round 2 is 81 lines before and after; the
  change is visible only in the digest. Verified with `sha256sum`, not with `wc -l` or a line diff.
- **Terminal-bracket boundary.** Both readings of P6(b) applied to 5 real documents (ADV-5).
- **Cap boundary (B-9).** `wc -l` over all eight agent contracts, not only the four cited: max 296,
  cap 300.
- **Non-intact return (B-4/B-11).** Exercised once, by the control: two of three pre-write checks
  failed → nothing written, nothing repaired, route-back recorded. *Single-condition failures and a
  clean P6(c) failure have no row (QA-6).*
- **Twin lockstep (R5).** `cmp docs/workflow.md skills/harness-init/templates/common/docs/workflow.md`
  → byte-identical.
- **Tool-grant freeze (S5).** `grep -n '^tools:' agents/*.md` — all eight unchanged; both reviewers
  remain `Read, Glob, Grep`.
- **Zero-footprint boundary.** Every artifact I created lives under the session scratch root; the
  six touched paths and `baseline.json` were digested before and after this stage and are unmoved.

## verify_all result

```
total_checks: 32          (before: 32 — 04_DEVELOPMENT.md:30-31)
pass: 32
fail: 0
warn: 0
exit_code: 0
runs: 3 (identical tally and identical identifier sequence, md5 3c71cadb914686c248a60ec4d9e71a28)
identifiers: A.1 A.2 B.1 B.2 C.1 C.2 D.1 D.2 D.3 E.1 E.2 E.3 E.4 E.4b E.5 E.6 E.7
             F.1 F.2 G.1 H.1 G.2 G.3 I.1 I.2 I.3 I.4 I.5 I.7 I.6 J.1 G.4   (32, unchanged, none renamed)
new_tests_added: 0        (R-11 freezes the count at 32; this change has no executable surface.
                           13 re-runnable QA probes are published in 06_RATIONALE.md instead.)
baseline_updated: no      (no key moves. verify_all_checks stays 32; no assertion tally changed;
                           nothing lowered. baseline.json digest unchanged across this stage.)
line_counts (live wc -l): pm-orchestrator 296 · gate-reviewer 125 · code-reviewer 177 ·
                          supervisor 287 · max over all eight agents 296 · cap 300 · WARN 0
```

## Defects found

| id | severity | reproducer | file:line |
|---|---|---|---|
| QA-1 | MINOR | Read `agents/gate-reviewer.md:65` ("End your final message with a header, **then the body**") against `02_SOLUTION_DESIGN.md:437` observable (e) ("the returned message ended with the G8 header"). A conforming message ends with the body, so (e) fails every compliant run. Independently, the handed probe artifacts are body-only, so (e) has no measurable subject. | `docs/features/review-write-path/02_SOLUTION_DESIGN.md:437` vs `agents/gate-reviewer.md:65-69`, `agents/code-reviewer.md:48-52` |
| QA-2 | MINOR | ADV-5: apply both readings of "ends with its `## Verdict` line" to the 5 real stage-3/5 documents. Heading-reading FAILs 5/5; token-reading PASSes 5/5. A writer taking the heading reading routes back a correct body and the reviewer returns the same body — the round wedges instead of failing loudly. | `agents/pm-orchestrator.md:50`; `agents/gate-reviewer.md:21`; `agents/code-reviewer.md:21` |
| QA-3 | MINOR (residual, C-14) | Read `agents/pm-orchestrator.md:49-50` end to end: it obliges the writer to check the body "begins with that document's declared opening line" and no document the writer loads states what that line is. Deliberate — C-3 bars the header from carrying the schema — so the check is shape-recognition, not string comparison. R-2 holds for the duty, not for the duty's predicate. **Not repaired here.** | `agents/pm-orchestrator.md:49-50` |
| QA-4 | MINOR (residual, C-14) — **narrowed after adjudication** | The claim as raised ("a `tools: Read, Glob, Grep` line does not constrain the agent") is **not supported**: it is an artifact of the reproduction method (`general-purpose` dispatch, contract pasted as prompt text). ADV-6: 15 stage-3/5 documents across ≥13 genuine dispatches record `Read/Glob/Grep only`/"no shell"/"no execution"; zero counter-instances. What *is* true and worth recording: **a contract delivered as text carries no tool enforcement** — the same class as RES-1 (a header instructs, it does not enforce) and RES-3 (the loader gap). `agents/gate-reviewer.md:86` / `agents/code-reviewer.md:101` are sound for a plugin-dispatched stage. **Not repaired here.** | `agents/gate-reviewer.md:86`, `agents/code-reviewer.md:101` |
| QA-5 | MINOR | Re-run S2 with `--hidden`: `skills/harness-init/SKILL.md:83` (reserved-name guard) and `:291` (role enumeration) carry no disposition in `04_DEVELOPMENT.md:236-248`. Both are bare role-name enumerations with no authoring or writing verb — the same class as `_ai-native-prompt.md:22-23` and the `verify_all`/`test-init` role lists, which *are* published. **Disposition published in `06_RATIONALE.md` §3; the file needs no edit; `04`'s table still lacks the row.** | `04_DEVELOPMENT.md:236-248` vs `skills/harness-init/SKILL.md:83,:291` |
| QA-6 | MINOR | Enumerate the admissible class the behavioral arm covers (T-20 discipline: *which members does no row instantiate?*). Three members have **zero** rows: **(i) stage 5** — `05_CODE_REVIEW.md` has a different opening line, 7 sections and a different verdict vocabulary; K1–K8 are verified on paper only. **(ii) rationale portion present** — every arm returned none, so "a returned rationale portion is transcribed to `03_RATIONALE.md`" (P3's second clause, G4/K4, R-6) is never exercised. **(iii) a clean P6(c) failure** — the control failed (a) and (b) together and its (c) was recorded as vacuous, so no row isolates P6(c). Bound on the control (RES-B): it is `HEAD` = pre-T-18, so its must-fail on (a) is over-determined — it validates the **apparatus**; necessity for *this task's* sentences rests on AC-10, which is where I placed it. | `02_SOLUTION_DESIGN.md:430-438` (protocol); artifacts under `scratchpad/ac8/` |
| QA-7 | NIT | The contract loaded into **this** stage-6 session is character-identical to `~/.claude/plugins/cache/harness-kit-marketplace/harness-kit/0.44.0/agents/qa-tester.md:14-16` — the pre-T-18 four-item list, not the working tree's `:15-25` schema. RES-4 / G-10 fires a **fourth** time, at a fourth stage, in this task. It would have made this report open with `# Test Report` and no marker line — the exact E-10 shape the task exists to prevent. Avoided by reading the working-tree contract. | `agents/qa-tester.md:15-25` vs the 0.44.0 cache build |

No BLOCKER, no CRITICAL, no MAJOR. QA-1 … QA-3 and QA-6 are defects in **upstream protocol and
contract text**, each discharged in-round by the binding condition that anticipated it (C-11 … C-14,
RES-B); none is a defect in the shipped change. QA-4 is adjudicated and narrowed. QA-5 and QA-7 are
publication and provenance notes.

**Residuals travelling to `07_DELIVERY.md`:** QA-1 (observable (e) is unsatisfiable as written —
correct it or drop it before the protocol is reused), QA-2 (P6(b)'s two readings), QA-3 (P6(a)'s
undefined predicate), QA-4 (narrowed: prose contracts delivered as text carry no tool enforcement —
**do not harvest the strong form**), QA-6 (the three uninstantiated class members, and the bound on
the control), QA-7 (RES-4's fourth firing). RES-1 … RES-5 and RES-E travel unchanged. RES-A and
RES-D are **closed** by this stage; RES-B and RES-C are **discharged** (bound stated, citations
re-derived live).

## Stability

- `verify_all` ran **3 times**: `PASS: 32  WARN: 0  FAIL: 0`, exit 0 on every run. No flake.
- The identifier sequence is byte-stable across all three runs (md5 `3c71cadb914686c248a60ec4d9e71a28`)
  and equals the sequence `04_DEVELOPMENT.md:35` published, so no check was renamed or reordered.
- The AC-8/AC-9 probe is a single-shot artifact and cannot be re-run from this stage (no `Task`
  tool). Its stability evidence is **cross-arm agreement rather than repetition**: two writers with
  different instruction sets produced byte-identical files.
- **Zero footprint confirmed by digest, not by `git status`** (T-22: an in-hunk, line-count-
  preserving edit is invisible to `git status`, `git diff --numstat` and `wc -l` simultaneously).
  The six touched paths and `.harness/scripts/baseline.json` were `sha256sum`-ed before and after
  this stage and are unmoved. Every file I created lives under the session scratch root; the only
  files this stage adds to the repository are `06_TEST_REPORT.md` and `06_RATIONALE.md`. One
  further path moved and is named rather than glossed: `verify_all.sh:930` appends one JSON row per
  run to `.harness/scripts/verification_history.log`, so my four runs added four
  `{"pass":32,"warn":0,"fail":0}` rows. That file is git-ignored (`git status --porcelain` returns
  nothing for it) and is the gate's own bookkeeping, not a hand edit — but "zero footprint" is an
  absolute and a QA report should not carry one that a `find -newermt` sweep contradicts.
- **RES-D closed.** `git diff --stat` scoped to the six named paths: `agents/code-reviewer.md` 68,
  `agents/gate-reviewer.md` 81, `agents/pm-orchestrator.md` 80, `docs/workflow.md` 6,
  `AI-GUIDE.md.tmpl` 8, the `workflow.md` twin 6 — 6 files, 191 insertions, 58 deletions. That is a
  **path-level** result only and is *not* read as this task's hunk set: `HEAD` is v0.44.0, so those
  hunks carry T-18 … T-22 as well (the whole `docs/workflow.md` paragraph containing A3 is a T-18
  addition, and A3's one-word edit inside it is invisible in the diff — QA-2's cousin). The footprint
  is therefore established **positively** by fingerprint: this task's wording appears in exactly
  6 files (3 agent contracts + 3 of this task's own docs), and A3/A4's wording in exactly the
  2 `workflow.md` twins. The dirty set was never read as evidence.

## Verdict

APPROVED FOR DELIVERY
