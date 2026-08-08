# Rejected decisions — deliberately not adopted (and why)

> Deliberately-declined requests / approaches + why, so a re-proposal finds the prior
> decision instead of re-litigating it. **Read** at a non-trivial decide-point before
> proposing a new approach / feature; **append** when something is deliberately declined
> (a real rejection — or a `deferred` "not now", marked as such). One record per concept;
> a re-occurrence adds its origin to that record, not a second record. Sibling memory:
> `.harness/insight-index.md` (truths), `.harness/decision-rubric.md` (autonomy principles),
> `CONTEXT.md` (glossary). Soft self-discipline: if this grows past ~one screen, compact
> merged/obsolete records — no gate enforces size.

## design-it-twice
- **Decision:** deferred (not now).
- **Why:** a parallel-exploration design pattern; useful but not yet pulled in — the
  solution-architect lens already names it as a future option. Re-surface when a genuinely
  high-stakes design call warrants exploring two approaches in parallel.
- **Origin:** mattpocock-adoption batch (T-07 design-vocab discussion).

## ask-matt-router
- **Decision:** declined.
- **Why:** a "which sibling skill / role handles this" router. The AI-GUIDE "Workflow entry"
  table already routes a request to the right mode/skill, so a second router is duplication.
- **Origin:** mattpocock-adoption batch.

## issue-tracker-dedup
- **Decision:** declined.
- **Why:** this repo has no issue tracker; the upstream one-file-per-concept dedup + auto-matching
  machinery is built for a tracker with many requests per concept. At this repo's scale a single
  human-read file carries the institutional-memory value at a fraction of the surface.
- **Origin:** mattpocock-adoption batch (this file's own basis).

## to-prd
- **Decision:** declined.
- **Why:** a request-to-PRD conversion flow tied to an issue tracker / many-stakeholder intake;
  this repo's intake is the 7-stage pipeline starting at the requirement-analyst, so a separate
  PRD stage is redundant weight.
- **Origin:** mattpocock-adoption batch.

## triage
- **Decision:** declined.
- **Why:** an inbound-request triage workflow presupposing a queue of external requests; this
  single-maintainer repo has no such queue, and the pipeline's PM routing already triages tasks.
- **Origin:** mattpocock-adoption batch.

## skill-usage-telemetry
- **Decision:** declined.
- **Why:** a per-call hook logging every skill invocation to find under-triggering skills. It is
  a standing per-call cost for a single-maintainer project and cuts against the repo's anti-bloat
  line — no resident hook unless it prevents a concrete hazard. Gather usage ad hoc if ever needed.
- **Origin:** migrated here from `.harness/rules/15-skill-authoring.md` "Deliberately not adopted".

## skills-teach-handoff-writing-personal
- **Decision:** declined (skill family).
- **Why:** the upstream `teach`, `handoff`, `writing-*`, and `personal` skills target a human
  knowledge-base / personal-workflow audience, not an AI-development pipeline distribution — out
  of fit for what this repo ships.
- **Origin:** mattpocock-adoption batch (non-fit tier).

## skills-git-guardrails-setup-pre-commit
- **Decision:** declined.
- **Why:** the upstream `git-guardrails` and `setup-pre-commit` skills overlap this repo's existing
  `guard-rm` PreToolUse safety hook and `install-hooks` pre-commit installer — adopting them would
  duplicate mechanisms we already ship.
- **Origin:** mattpocock-adoption batch.

## skills-tdd-diagnosing-bugs
- **Decision:** declined.
- **Why:** TDD and bug-diagnosis practice is already covered by this repo's engineering rules and
  the QA/code-reviewer stages of the pipeline; a separate skill for each would restate covered
  ground.
- **Origin:** mattpocock-adoption batch.

## decision-mapping
- **Decision:** declined.
- **Why:** an unshipped (`in-progress/`) upstream draft that builds a separate "decision map" of
  numbered investigation tickets with `blocked_by` edges, a frontier, and fog of war. Every concept
  maps 1:1 onto a live harness surface: the map = the `BATCH_PLAN.md` pool, a ticket = a pool row,
  `blocked_by` = the `Depends on` column, frontier = the topological frontier (`/harness-stream`
  already uses that word), fog of war = the append-only pool, session-sizing = the T-06 smart zone,
  ticket-types Research/Prototype = `/harness-explore`, Discuss/bootstrap = `/harness-grill`'s
  one-question-at-a-time design-tree interview, resume = the stream resume semantics. The only
  candidate delta (a pre-task investigation map for the loose-idea phase before pool rows exist,
  resolving open *questions* not tasks) is already owned by `/harness-grill` (questions) +
  `/harness-explore` (research/prototype) handing into the BATCH_PLAN frontier. Building it would be a
  parallel map format competing with the pool — exactly the duplication this batch already declined
  for `to-prd` (decision-mapping's own hand-off target), `ask-matt-router`, and `triage`. A MINIMAL
  note restating the loose-idea→questions→decompose flow was considered and rejected too: not a gap
  (grill's description already states that flow) and it risks introducing a competing term set.
- **Origin:** mattpocock-adoption batch (T-10, the final / assess-first item; assessment at
  `docs/features/planning-decision-map/01_REQUIREMENT_ANALYSIS.md`).

## entropy-findings-store
- **Decision:** declined.
- **Why:** a standalone open/fixed findings store re-encodes a re-derived fact; the entropy scan
  re-derives OPEN/FIXED each run (fixed == no-longer-surfaced, open == re-derived from the live
  tree), so a separate log would add a file plus a read/write cycle plus a drift surface to
  duplicate a property the design already has by construction. Declines are the only state that needs
  memory, and they reuse this T-09 file. Lightweight / design-over-guards line.
- **Origin:** T-11c entropy-watch-persist scope-down (RA + architect).

## verify-gate-machine-hook-assertion
- **Decision:** declined.
- **Why:** asserting in `verify_all` that THIS machine has the guard hook wired — including the
  "assert only when `.claude/settings.local.json` is present" conditional form — has no correct
  formulation: the documented durable opt-out is a present machine-local file with an empty hooks
  object (`.harness/rules/75-safety-hook.md`), so a presence-conditional FAIL turns a legitimate
  state into a gate failure, and an unconditional one fails every clean checkout and every CI run.
  A repository gate answers repository questions; the machine dimension is owned by
  `/harness-status` §0 "Effective hook source". A "compensating" extra check was declined with it.
- **Origin:** T-15 `hook-truth-verify-scope` (OQ-2, OQ-6), narrowing `F.2`.

## hook-byteform-test-literal-retirement
- **Decision:** declined (the test-side literals are deliberately RETAINED).
- **Why:** T-16 retired every hook-command byte-form copy from the four *derivation flows*
  (`upgrade-project.{sh,ps1}`, `migrate-scripts-layout.{sh,ps1}`, and the two `SKILL.md`
  placeholder tables), which now query `hook-spec.{sh,ps1}`. Retiring the *test* copies as well
  was considered and declined: a test must not derive its expectation from the artifact under
  test. Once the flows delegate, a spec-vs-flow oracle compares the spec with itself — green, and
  measuring nothing — so `test-init.{sh,ps1}`'s `EXP_*` / `$exp*` fixtures were re-anchored as THE
  oracle instead. `test-real-project.{sh,ps1}` is a fixture-AUTHORING site (it builds the
  fixture's final settings) and has the same reason plus a stronger one. `test-harness-upgrade`'s
  `t20_pick` is the one standing flow-emitted-vs-independent-literal anchor and must stay
  independent. The raw-shell / raw-pwsh / post-`ConvertFrom-Json` literals are DIFFERENT escaping
  levels the spec deliberately does not emit. All five sites are enumerated with their reasons in
  `hook-spec.{sh,ps1}`'s header.
- **Origin:** T-16 `hook-truth-derivation` (OQ-1(b), OQ-6(b)).

## stage-doc-summary-header
- **Decision:** declined (red line for T-18 and after).
- **Why:** a per-document summary header on each stage doc, so a downstream stage could read the
  header instead of the body. A summary is a copy of the body that must be hand-kept in sync with
  it — the exact duplication class T-13…T-17 spent five tasks eliminating, and nothing gates the
  copy against its original. The corollary that replaced it: a stage **contract** is the ORIGINAL
  binding text addressed directly to its consumers, never a distilled copy of a fuller body.
- **Origin:** T-18 `stage-contract-split` (operator, pre-dispatch; recorded at RA).

## stage-bloat-prohibitions-only
- **Decision:** declined (superseded by a structural design).
- **Why:** the first framing of the stage-doc bloat problem was three prohibitions — "do not
  pre-write implementation literals", "move changelogs out", "do not invent constraints in briefs".
  Rejected before dispatch: a prohibition depends on compliance and has nothing enforcing it, so a
  stage could still emit a 110 KB document full of pre-written implementation text without
  violating any structure. The standing direction is to prefer a design that makes the failure
  impossible over a patch that forbids it. Re-surfacing "just tell the agents to write less" is
  this record.
- **Origin:** T-18 `stage-contract-split` (operator, pre-dispatch; recorded at RA).

## boundary-rule-in-agent-file
- **Decision:** declined.
- **Why:** hosting the stage-doc contract/rationale boundary rule's normative text inside one
  framework agent (`agents/*.md`), with the other agents referencing it by name. Framework agents
  are plugin-native, so in a generated project they have **no project-relative path** — the six
  non-hosting agents could not *read* a rule they must execute at authoring time. The T-05
  reference-don't-restate pattern works for preserving a *nuance* across two agents
  (`pm-orchestrator` → `requirement-analyst` Hard rule 6); it does not work for a rule that must be
  applied. The rule lives in `.harness/rules/70-doc-size.md` (+ its `/harness-init` template twin)
  instead, whose existing read-trigger already fires at the decision point. Also corrected here: rule
  fragments **are** distributed to generated projects, via the template overlay — `sync-self`'s lack
  of a rules mapping is a dogfood-mirroring choice, not a distribution gap.
- **Origin:** T-18 `stage-contract-split` (architect, OQ-2 override D-1).

## upgrade-rule-content-refresh
- **Decision:** declined for T-18 (recorded as a standing follow-up, not dropped).
- **Why:** T-18 hosts the stage-doc boundary rule in `.harness/rules/70-doc-size.md`, which
  `/harness-init` lays down but `/harness-upgrade` deliberately does **not** refresh
  (`skills/harness-upgrade/SKILL.md:231` — "Agent / skill / **rule** content refresh" is out of
  scope v1; `CHANGELOG.md:1394` records the same for this file by name). Extending `/harness-upgrade`
  to overwrite rule fragments was considered and declined: fragments are **bespoke per repo** by
  design (`AI-GUIDE.md:76`), so a content refresh would clobber a project's own edits — the exact
  reason the exclusion exists. The residual (an installed project whose plugin-native agents cite a
  rule section its fragment does not yet carry) is handled instead by a **degradation clause** in
  each agent contract: absent the section, the agent applies its own `## What you produce` schema and
  proceeds without blocking. A future `--include-rules` with a three-way merge is the real fix.
- **Origin:** T-18 `stage-contract-split` (architect, round 2, gate finding F-9).

## ambiguity-trigger-at-review-stages
- **Decision:** declined.
- **Why:** QA measured that stages 2, 4 and 6 each carry an "ambiguous / under-specified contract"
  rationale trigger while stages 5 and 7 do not, and asked for the asymmetry to be closed or
  justified. Adding the broad trigger there was considered and declined: stages 5 and 7 **audit or
  compose** what already exists, and a reviewer that resolves an ambiguity by reading the rationale
  **hides** the defect it should raise as a finding — the trigger would convert a reportable defect
  into a silent repair. What was added instead is the narrow, measured case: a contract row citing an
  identifier (`R-n`, `OQ-n`, a finding id) that **no contract portion defines** is not an ambiguity
  to report but a row that cannot be read at all, so T5.4 / T7.3 open the rationale of the stage that
  owns the identifier (live instance:
  `docs/features/_archived/hook-truth-derivation/05_CODE_REVIEW.md:458` carries a bare `R-1` into
  `07_DELIVERY.md`).
- **Origin:** T-18 `stage-contract-split` (architect, round 3, QA-5).

## hook-spec-raw-query
- **Decision:** deferred (declined for T-16; recorded as a follow-up, not dropped).
- **Why:** the shell-level / raw-pwsh consumers (`test-harness-upgrade`'s raw probes,
  `test-guard-rm.{sh,ps1}`, `evals/guard-rm-cases.md`) carry a DIFFERENT escaping level from the
  one `hook-spec` emits, and the guard cases are guard *input data*, not a wiring copy. Retiring
  them needs a new `raw` query — i.e. a change to the source of truth's contract and to its
  arity / anti-vacuity gates — inside a task whose whole point was that consumers change and the
  source does not. Designed first, then adopted.
- **Origin:** T-16 `hook-truth-derivation` (OQ-7(b)).

## byte-form-subpart-classification
- **Decision:** declined (operator ruling, 2026-08-01) — the residual is published, not closed.
- **Why:** the stage-doc boundary rule's classification unit ladder makes a declared shape's own unit
  the unit ("sub-parts are never classified separately"), so row 2's byte-form exclusion tests the
  container and never its contents: a byte-form that fits on **one line** inside a table cell reaches
  the contract ungated (QA-7), and two ladder steps name the FR-9 header line with different
  destinations (QA-8, 0 observed misroutes). Making the rule see sub-parts, or carving the header line
  out of step 3, was considered and declined: that clause exists precisely to close QA-1's determinism
  demand, so fixing one reopens the other. More fundamentally, asking the structure to decide whether
  one line of characters is an interface shape or an implementation literal is asking **structure to
  perform a semantic judgement** — a change-ledger row must quote its target state, that being what a
  change ledger is for. Forced closure would buy the remaining few percent by introducing
  misclassification, which is a worse defect than the one it closes. The measured symptom the task was
  launched against — design documents embedding large verbatim blocks of implementation text — is the
  **multi-line** class, and that class is structurally homeless now; the surviving class is different
  and was not what cost 250–420 KB per task. **The honest boundary is better than a false total**, so
  the guarantee is stated as *structural for multi-line forms, compliance for anything that fits on
  one line* and the two findings travel as `RES-QA7` / `RES-QA8`
  (`docs/features/stage-contract-split/02_SOLUTION_DESIGN.md` §13). Re-surface only with a mechanism
  that classifies sub-parts **without** reintroducing two destinations for one unit.
- **Origin:** T-18 `stage-contract-split` (QA round 2, QA-7/QA-8; operator ruling at the stage-6
  boundary, 2026-08-01).

## insight-refusal-bypass-flag
- **Decision:** declined (T-20, 2026-08-01) — `archive-task` gains no flag that lets an
  unclassifiable line through.
- **Why:** the escape is to correct the delivery document (or the index), which takes seconds; a
  bypass flag reintroduces the exact silent path the task exists to remove, and it would be reached
  by the one caller least able to judge the loss — an automated stage-7 archive. The refusal is loud
  (exit 3, one stderr diagnostic per offending line naming path, 1-based line number and text), it
  happens before any create/write/append/move, and `--dry-run` reproduces it for free.
- **Origin:** T-20 `harvest-wrapped-insight` (OQ-7, design `K-19` / `K-48a`).

## insight-prose-i6-banned-phrase
- **Decision:** declined (T-20, 2026-08-01) — no `verify_all` `I.6` banned-phrase entry is added to
  enforce the corrected "wrapped bullets are dropped" prose.
- **Why:** `test-verify-i6.{sh,ps1}` hold a verbatim copy of the banned list at
  `verify_all.sh:566-581`, so one added entry moves the frozen `test_verify_i6_*_assertions` pair in
  both shells — and the PowerShell half cannot be re-measured on this host. The phrase itself is
  ordinary English ("silently dropped"), so an anchor for it would be a false-positive engine over
  every future document. The prose is corrected at its sources instead (agent contracts, the two rule
  fragments and their template twins, `AI-GUIDE.md`, `docs/concepts.md`, the index header block).
- **Origin:** T-20 `harvest-wrapped-insight` (design `K-48b`).

## shared-insight-parse-module
- **Decision:** declined (T-20, 2026-08-01) — `INSIGHT-SCAN` is written four times (both
  `archive-task` twins, both `verify_all` `I.4` arms) rather than extracted into a shared
  `insight-parse.{sh,ps1}`.
- **Why:** `verify_all` would then depend, at gate time, on a mirrored script that `verify_all`'s own
  `E.1` is what checks — a cycle — and the missing-module fallback would itself be a second
  predicate, which is the defect class the task closes. The cost is stated rather than hidden: the
  state machine's cross-copy agreement is proven **by test**, not by construction — `K-61`'s
  raw-marker oracle plus the discriminating fixtures for the bash pair, and operator item 17 for the
  PowerShell pair. Re-surface only with a mechanism that removes the `E.1` cycle.
- **Origin:** T-20 `harvest-wrapped-insight` (design §M.1 / `K-48c`, gate `K-67`).

## stage-model-tiering
- **Decision:** model-swap lever **declined**; reasoning-effort lever **deferred** (not now) — two
  levers of one concept in one record; neither marking generalises to the other.
- **Why:** with six of the eight roles each excluded on positive evidence, the addressable set is
  requirement-analyst + solution-architect — the two roles whose errors propagate furthest here.
  Downgrading them pays only while it induces fewer than roughly 0.02–0.83 extra rollbacks per task
  (0.6%–44% relative, across the whole published surface); stress-testing moved that bar in **both**
  directions, and the decline holds at its most BUILD-favourable corner too, because nothing here
  measures a per-stage rollback rate, at any resolution, across a ten-task history. (Individual
  rollbacks ARE attributed to a causing stage in each task's `PM_LOG.md` — 19 of 19 checked — but
  nothing aggregates them into a rate, which is what a before/after comparison would need.)
  The saving is a proportional discount on a bill that is 78% cache traffic; context reduction is
  the safer lever. The agents are also plugin-native: a tier set here reaches every installed
  project on the next plugin update with no per-project override, so it can be neither trialled nor
  withdrawn per consumer. The effort lever is deferred rather than declined because it keeps the
  capability ceiling, but its key spelling, value set and plugin-native applicability are
  unconfirmed upstream. Re-surface only with all three of **F-1** a per-call context-volume
  measurement putting the delegated share at the top of the published 6.7–45% band, **F-2** a
  rollback-attribution instrument resolving that surface per originating stage (sub-1% at its low
  end, so a ≥20-task baseline is a floor, not a sufficiency), and **F-3** a per-project tier
  override, making a downgrade reversible by the consumer that experiences it.
- **Origin:** T-22 `stage-model-tiering`. It overrides `docs/batches/default/BATCH_PLAN.md:37`
  ("**Wire** the per-agent model and reasoning-effort declarations…") and qualifies `:41`; both are
  quoted and answered at `docs/features/_archived/stage-model-tiering/02_SOLUTION_DESIGN.md` §16.1.

## reviewer-write-grant
- **Decision:** declined.
- **Why:** adding `Write` to `gate-reviewer` and `code-reviewer` so each creates its own stage
  document. It removes the indirection and makes the lost-record failure impossible, which is the
  direction `stage-bloat-prohibitions-only` prefers — but no tool grant in this runtime is
  path-scoped, so the grant that lets the gate reviewer write `03_GATE_REVIEW.md` also lets it
  overwrite `02_SOLUTION_DESIGN.md`. It buys structural enforcement of a **duty** whose failure is
  visible on the produced artifact (and is now falsifiable on every run) by surrendering structural
  enforcement of the **independence invariant**, whose failure — a verifier silently amending the
  work it judges — leaves no artifact at all. The precedent usually cited for it argues the other
  way: `agents/supervisor.md:283` holds `Write` while asserting that editing upstream docs is
  "forbidden by tools whitelist anyway", which is false of a `Write` grant. Re-surface only with a
  path-scoped write capability, or a check that reads an agent's `tools:` line.
- **Origin:** T-23 `review-write-path` (architect, OQ-1; the requirement's two-conjunct override
  condition was tested and its second conjunct failed).

## persist-duty-in-mode-skills
- **Decision:** declined.
- **Why:** restating the stage-3/stage-5 transcription duty inside each PM-driving mode skill
  (`/harness`, `/harness-plan`, `/harness-stream`, `/harness-batch`), because a main-session agent
  playing PM loads the skill rather than `agents/pm-orchestrator.md`. Four hand-synced copies of one
  sentence, each adding dispatch-time ingest cost — the property T-18 bought. Pointing the skills at
  the agent contract instead is the `boundary-rule-in-agent-file` decline (a plugin-native agent has
  no project-relative path in a generated project). Adopted instead: the author's own contract makes
  it end its final message with the target paths, so the instruction travels **in-band with the
  body** and reaches every caller without any of them reading anything extra.
- **Origin:** T-23 `review-write-path` (architect, OQ-3 extension).

## obligation-prose-gate
- **Decision:** declined.
- **Why:** adding a `verify_all` check that keeps release-gating operator obligations out of
  `.harness/scripts/baseline.json` once T-24 gave them a home in `.harness/operator-obligations.md`.
  **Four** mechanisms were tested; the first three add a check id, the fourth does not, and all four
  fail or are declined on measurement rather than on taste.
  1. *Length*, pin-file side — "no `_qa_note_*` value exceeds N characters". Implementable, and it
     fires on the historical narrative T-24 deliberately **keeps** in band (all four notes stay
     multi-KB after the excision), so passing it would force a deletion the task's own scope forbids.
  2. *Imperative verbs*, pin-file side — ban `must` / `confirm` / `expect` / `run` inside a
     `_qa_note_*` value. Fails decisively: the text that must **stay** is itself imperative
     ("Do not invent one", "do NOT re-baseline it upward"), so an obligation and a pin-writing
     constraint are lexically indistinguishable while the rule separating them is semantic.
  3. *Ledger-side* — "ids are unique". This one **does** have a mechanical form, so no blanket
     "no predicate exists" claim is made. Declined on three grounds: the task's requirement pins the
     check count where it is; it guards a different failure (a duplicate id, not a homeless
     obligation); and moving the count cascades through `G.4`'s eleven-file array plus the ungated
     twelfth site `CONTRIBUTING.md:22` that EP-003 names.
  4. **An `I.6` banned-list entry — adds no check id.** `i6_banned` is a data-driven array
     (`verify_all.sh:640-655`), the scan walks every tracked file via `git ls-files` (`:742`) and
     `step "I.6"` is called once, so an added record costs no `step` call and the check count does
     not move — grounds 1-3 all quantify over adding a check id and none of them reaches it.
     Declined on two of its own. **(a)** `verify_all.sh:636-638` and `:673-674` record that
     `test-verify-i6.{sh,ps1}` hold a **verbatim copy** of the list, so one added record moves both
     `test_verify_i6_bash_assertions` and `test_verify_i6_ps_assertions`, and the PowerShell half
     cannot be re-measured on this host — it would manufacture a new PowerShell operator obligation
     inside the very change whose subject is that such obligations cannot be discharged here, and
     reopen `insight-prose-i6-banned-phrase`. **(b)** `I.6` has file *exemptions* and no
     *inclusions*, so any anchor sharp enough to match obligation prose in the pin file matches the
     obligation ledger too, whose entire content is that prose.
  Adopted instead, two levers, both verifiable by reading rather than by running: the pin file's own
  `notes` value says in band that it pins numeric baselines only and that an obligation is written in
  the ledger, and `agents/qa-tester.md` — the one agent contract naming the pin file as a stage
  output — names the ledger as the destination and the append rule.
- **Re-surface condition:** an obligation landing in `.harness/scripts/baseline.json` again after
  this change. That is observable, not hypothetical: the anti-entropy sweep that produced **EP-002**
  (`skills/harness-deflate/`, cadence `.harness/scripts/entropy-cadence.{ps1,sh}`) runs on a cadence
  and reads the pin file. One recurrence measures the design lever as having failed and makes a
  check justified.
- **Origin:** T-24 `operator-obligation-home` (architect, OQ-8; developer stage 4).

## baseline-json-prose-excision

- **Request:** the v2 migration brief's P1 line item — `.harness/scripts/baseline.json` is 14.8 KB
  of which ~90% is `_qa_note_*` prose; delete all of it and keep only numbers.
- **Decision:** DECLINED as written. The prose is not the defect the brief describes.
- **Why:** T-24 `operator-obligation-home` already excised the *obligations* out of those notes into
  `.harness/operator-obligations.md`, and made two rulings that a blanket deletion would reverse.
  **(a)** 19 obligation entries carry `Origin: … .harness/scripts/baseline.json:_qa_note_tNN` as
  their **enumerating source**; deleting the notes leaves 19 provenance anchors pointing at nothing,
  which is worse than the prose, because an obligation whose origin cannot be read is one nobody can
  audit. **(b)** T-24 ruled explicitly that the *pin-writing constraint* — "only after (a)–(e) may a
  PowerShell tally be recorded, transcribed from that run" — **stays in band with the key it
  constrains**. A constraint on a key that lives away from the key is the failure
  `stage-doc-summary-header` names, in the other direction.
  Measured against the brief's own test: the file is on no always-read path (`evals/measure-context.sh`
  places it in neither tier), so the deletion buys no context. It costs 19 anchors and one settled
  ruling to buy repository bytes nothing pays for.
- **Adopted instead:** nothing. The notes stay until something reads them wrongly.
- **Re-surface condition:** the notes acquiring a *reader* that must not see prose — a check that
  parses the file structurally, or an agent contract that instructs reading it whole. Either makes
  the shape a real cost rather than an aesthetic one, and the excision can then be designed with the
  19 anchors re-pointed at `docs/features/_archived/<slug>/` in the same change.
- **Origin:** v2 migration, P1 line item, evaluated 2026-08-08.
