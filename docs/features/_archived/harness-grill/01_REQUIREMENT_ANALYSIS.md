# 01 — Requirement Analysis · T-03 harness-grill

> Stage 1 (Requirement Analyst). Mode: **full**. deferred-human mode: defer, do not ask — every Open
> Question carries ≥2 candidates + a recommended answer; Verdict READY when all recommendations are safe
> Mode-2 defaults.
> Source-of-truth assets read (read-only): `INPUT.md`, `AI-GUIDE.md`, `.harness/insight-index.md`,
> `docs/tasks.md`, `.harness/rules/15-skill-authoring.md`, `agents/requirement-analyst.md`,
> `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `README.md`, `README.zh-CN.md`,
> `docs/getting-started.md`, `docs/manual-e2e-test.md`, `docs/dev-map.md`, `.harness/rules/40-locations.md`,
> `.harness/scripts/verify_all.{ps1,sh}` (C.1/G.1/G.2/G.3/G.4 sites), `install.sh`,
> `skills/harness/SKILL.md`, `skills/harness-explore/SKILL.md`, `skills/harness-status/SKILL.md`,
> `skills/harness-decision-mode/SKILL.md`, the T-018 + T-014 archived stage docs, the mattpocock
> `grilling` / `grill-with-docs` / `ask-matt` reference SKILLs, `CONTEXT.md` (read-if-present).

## 1. Goal

Ship a 16th plugin skill `/harness-grill` — a user-invoked, pre-pipeline, one-question-at-a-time
alignment interview that recommends an answer per question, self-answers from the codebase where it can,
reads `CONTEXT.md` if present, and writes an aligned brief to a feature `INPUT.md` — plus a one-line
standing rule on `agents/requirement-analyst.md` that every Open Question carries a recommended answer,
as release **v0.35.0**.

## 2. In-scope behaviors (numbered, testable)

### A. New skill `skills/harness-grill/SKILL.md` (the interview front-end)

1. A new top-level plugin skill directory `skills/harness-grill/` containing a `SKILL.md` (FRAMEWORK
   skill shipped by the plugin under top-level `skills/`, like the other `/harness-*` skills — NOT under
   `.harness/skills/`, so no `harness-sync` of it is required; verify_all C.1 enumerates `skills/*/`).
2. The SKILL.md `description:` frontmatter meets rule 15 P1: it leads with concrete EN + 中文 trigger
   phrases a user would actually type for a deliberate alignment session (e.g. "grill me on this",
   "interview me about this plan", "pin down what I actually want before we build", "拷问我的需求",
   "逐条对齐需求", "动手前先把需求问清楚") and carries an explicit *when-NOT-to-invoke* delta against
   the sibling work-starting skills `/harness`, `/harness-plan`, `/harness-explore` (see item 9).
3. The SKILL.md documents the **interview engine**: the skill interviews the user **one question at a
   time**, waiting for the user's answer to each question before asking the next (never batches multiple
   questions in a single turn), walking the design tree until a shared understanding is reached.
4. The SKILL.md documents that **each question is presented with the skill's own recommended answer**
   (the user can accept, override, or refine it) — the grilling-engine "recommended answer per question"
   behavior.
5. The SKILL.md documents **explore-codebase-to-self-answer**: when a question can be answered by reading
   the repository (existing conventions, file locations, prior art, what a symbol already does) the skill
   investigates and resolves it itself instead of asking the user.
6. The SKILL.md documents that the skill **reads `CONTEXT.md` if present** (repo root) and uses its
   canonical terms when phrasing questions and writing the brief; if the skill coins or sharpens a domain
   term during the interview it MAY record it inline in `CONTEXT.md` (term + 1–2 sentence definition +
   `_Avoid_:` synonyms). Absence of `CONTEXT.md` is handled gracefully — the skill proceeds without it and
   never blocks on it (SOFT dependency, no precondition, no setup pointer).
7. The SKILL.md documents the **terminal artifact**: at the end of an aligned session the skill writes an
   **aligned brief** to a feature `INPUT.md` (under `docs/features/<task-slug>/INPUT.md`) so that a
   subsequent `/harness`, `/harness-plan`, or the `/harness-stream` pool can pick it up as the
   requirement-analyst's input. The brief captures the agreed goal, the resolved decisions, and any
   residual open items.
8. The SKILL.md contains a **"When NOT to invoke"** surface and an **"Anti-patterns"** section
   (rule 15 P3): the when-NOT surface states the bright-line delta vs siblings (item 9); the anti-patterns
   surface names at least "asking multiple questions in one turn" and "asking the user a question the
   codebase already answers" as prohibited.
9. The **when-NOT delta vs siblings** is explicit and bright-line: `/harness-grill` is a PRE-pipeline,
   interactive, human-deliberately-started ALIGNMENT session that produces a brief and stops; it does NOT
   itself run the pipeline, write design, write code, or produce findings. Use `/harness` when the
   requirement is already clear enough to ship; `/harness-plan` to vet a design (not to discover the
   requirement); `/harness-explore` for "can we even do X?" feasibility research. `/harness-grill` is the
   "I'm not sure I've said what I actually want yet" front-end that precedes any of them.
10. The SKILL.md states that `/harness-grill` is **user-invoked only** (the human starts an alignment
    session deliberately) — it is NOT model-invoked / auto-firing. (If the chosen authoring mechanism has
    a model-invocation toggle, the SKILL.md is configured so the skill is not auto-fired; exact mechanism
    is the Architect's to specify.)
11. The SKILL.md is NOT a new pipeline stage and does NOT alter `pm-orchestrator` routing or the
    7-stage flow — it is a standalone front-end skill that emits an `INPUT.md` the existing pipeline
    consumes.
12. SKILL.md stays within doc-size discipline (rule 70 / rule 15 P5: progressive disclosure, no bloat;
    comparable in length to the other `/harness-*` skills, ~comparable to `/harness-language`’s ~215
    lines — no hard numeric cap on SKILL.md, but no front-loading).

### B. Standing rule on `agents/requirement-analyst.md` (the second deliverable)

13. `agents/requirement-analyst.md` gains a one-line **standing rule**: every Open Question in section 8
    of `01_REQUIREMENT_ANALYSIS.md` carries a **recommended answer** (in addition to its ≥2 candidate
    answers). This generalizes to a standing rule the behavior the analyst already performs under
    deferred-human mode.
14. The rule is added as a framework-agent edit to the plugin-native top-level `agents/requirement-analyst.md`
    directly (no sync — Claude Code auto-discovers `harness-kit:requirement-analyst`; agents are edited in
    place per AI-GUIDE "Editing rules").
15. The rule is consistent with the agent's existing contract: section 8's stated "with at least 2
    candidate answers each" and Hard-rule-1's strip-list (which currently bans the word "recommend") are
    reconciled so the new "recommended answer" requirement does not contradict the strip-list. (The
    strip-list bans ambiguity-hedging words in *requirement statements*; a labelled "Recommended:" answer
    on an Open Question is a distinct, allowed construct — the Architect specifies the exact wording so the
    two do not collide.)

### C. New-skill release fan-out (each is an AC for Gate/CR/QA; SA produces the exhaustive ledger)

> This is the project's #1 recurring failure surface (insight L24/L5; getting-started.md "fourteen skills"
> bit T-018's Gate F-1). The Architect MUST produce an exhaustive, live-grep-backed `15→16` /
> `fifteen→sixteen` / `十五→十六` count-claim ledger (T-018 §7 + T-014 §11 are the canonical shapes).
> The list below is the RA-confirmed surface set; the SA ledger is authoritative for exact line sites.

16. `.claude-plugin/plugin.json` `version`: `0.34.0` → `0.35.0` (gated G.3). *(A skill-count change is
    version-worthy — insight L24.)*
17. `.claude-plugin/marketplace.json` version field → `0.35.0` (gated G.3).
18. `README.md`: version badge `0.34.0` → `0.35.0`; the `15 skills` (`:7`) and `fifteen` (`:13`) claims →
    `16` / `sixteen`; a new skill bullet for `/harness-kit:harness-grill` under the appropriate group
    (Setup vs Operations vs a pre-pipeline grouping — SA decides placement); any test badges that move
    (verify_all / test-init counts) reconciled to post-change real-run values.
19. `README.zh-CN.md`: mirror of README.md — skill bullet added, `15`/十五 → `16`/十六 count claims
    (`:7`, `:13`), version badge, moved test badges.
20. `CHANGELOG.md`: a new `## [0.35.0]` section above the prior top entry, describing the feature; it MUST
    contain the literal token `harness-grill` at least once (G.2 requires every skill name to appear in
    CHANGELOG) and note the skill-count `15 → 16` and version bump.
21. `AI-GUIDE.md` (dogfood): `:7` `15 skills` → `16 skills`; AND a new "Workflow entry" table row for
    `/harness-grill` (its EN + 中文 triggers, consistent with the SKILL.md description per rule 15 P1).
    AI-GUIDE.md must stay ≤200 lines after the edit (rule I.1; currently 110).
22. `docs/getting-started.md`: `:36` `fifteen skills` → `sixteen skills`; add a `harness-grill` bullet in
    the appropriate group (mirror README placement). *(Ungated — MANUAL; this is the surface that bit
    T-018.)*
23. `docs/manual-e2e-test.md`: every `fifteen`/`15 skills` claim → `sixteen`/`16 skills` (`:7`, `:34`,
    `:49`, `:60`) AND `harness-grill` added to each skill enumeration / command listing. *(Ungated —
    MANUAL.)*
24. `.harness/rules/40-locations.md`: `:31` `All 15 skills` → `All 16 skills`. *(Ungated — MANUAL.)*
25. `docs/dev-map.md`: a new `harness-grill/SKILL.md` line in the skills tree (mirror the existing
    `harness-language` / `harness-decision-mode` tree rows) and a `Skill: harness-grill` row in the
    location lookup table.
26. `.harness/scripts/verify_all.sh`: the C.1, G.1, G.2 skill-enumeration loops continue to enumerate
    `skills/*/` (so they auto-pick `harness-grill`), and their label strings `"All 15 skills present"` /
    `"references all 15 skills"` / `"... all 15 skills"` become `16`. (Confirm whether the loops are
    directory-derived; if so the label strings are the only edits — SA produces the exact ledger.)
27. `.harness/scripts/verify_all.ps1`: the C.1/G.1/G.2 twin — same label edits as item 26, symmetric
    (verify_all F.1 ps/sh parity).
28. `.harness/scripts/test-init.{ps1,sh}` + `baseline.json`: extended ONLY if test-init asserts a skill
    count or a shipped-asset set that this task moves. The grill skill is a PLUGIN skill (top-level
    `skills/`, NOT shipped into generated projects' `templates/`), so the expectation is **no test-init
    change**; the Architect confirms from the test-init assertions. Any baseline number is reconciled to a
    real captured run, never fabricated (insight L23/T-007).

## 3. Out-of-scope

- O-1. **Making `/harness-grill` model-invoked / auto-firing.** It is user-invoked — the human starts an
  alignment session deliberately (INPUT scope-guidance).
- O-2. **A separate domain-modeling skill.** `CONTEXT.md` maintenance folds into the grill interview + the
  RA/SA prose (per T-02); no `/harness-domain-model` or equivalent is created.
- O-3. **Changing the pipeline stage count or `pm-orchestrator` routing.** Grill is a PRE-pipeline
  front-end, not a stage; the 7-stage pipeline and its dispatch are untouched.
- O-4. **A `verify_all` guard/check dedicated to grill** (rule 15 P6 + [[feedback_design_over_guards]] —
  no new check unless it prevents a concrete hazard). The C.1/G.x label/count edits are modifications of
  existing checks, not a new check; the check count stays **32**.
- O-5. **Auto-decomposing the grill brief into staged sub-tasks** — that is `/harness-stream` ingest
  triage's job (T-021); grill emits a single aligned `INPUT.md`.
- O-6. **Git commit / push / release tag** — the operator's, not a sub-agent's (red line). Sub-agents
  leave a green tree; the operator stamps and ships.
- O-7. **Refactoring the requirement-analyst beyond the one-line recommended-answer rule** — the analyst's
  batch-doc model, sections, and workflow are otherwise unchanged.
- O-8. **A Chinese (`i18n/zh/`) overlay copy of the grill SKILL** — SKILL.md is AI-facing English
  scaffolding (the v0.26 language model); no zh overlay copy. (See OQ-4.)

## 4. Boundary conditions

- BC-1. **`CONTEXT.md` absent** → the skill proceeds with no glossary; it does not block, does not print a
  setup pointer, and does not create `CONTEXT.md` solely to populate it (it MAY create/sharpen it only when
  a term is genuinely coined during the interview). Graceful-degrade is mandatory (SOFT dependency, item 6).
- BC-2. **User gives an empty / one-word / "I don't know" answer to a question** → the skill offers its
  recommended answer as the working default and continues (it never hangs waiting on a perfect answer).
- BC-3. **A question is fully answerable from the codebase** → the skill resolves it from the repo and does
  NOT ask the user (item 5); it MAY state what it found and the chosen resolution.
- BC-4. **The aligned-brief target `docs/features/<task-slug>/INPUT.md` already exists** → the skill does
  not silently overwrite an unrelated brief; behavior on collision (new slug / confirm-overwrite / append)
  is specified by the Architect (see OQ-3). Default expectation: write under a task-slug the user/skill
  agree on; if that file exists, confirm before overwriting.
- BC-5. **User ends the session before alignment is complete** → the skill writes whatever was agreed and
  records the residual open items in the brief (no silent loss of the partial interview).
- BC-6. **No `docs/features/` directory yet** → the skill creates the feature folder path as needed when
  writing the brief (it does not fail because the parent dir is absent).
- BC-7. **Existing `agents/requirement-analyst.md` Hard-rule-1 strip-list contains "recommend"** → the
  added standing rule (item 13) must not be self-contradicted by that strip-list; the reconciliation
  (item 15) is a correctness boundary, not a stylistic nicety.
- BC-8. **Skill-count token disambiguation** — when flipping `15→16`, the live tree contains count tokens
  that are NOT skill counts and MUST NOT be touched: the `32` / "32 checks" verify_all CHECK count (G.4),
  and `harness-status/SKILL.md:135` "All 14 required assets" (a health-denominator, not a skill count).
  Insight L26 (same-file / cross-file count-token discrimination) applies — the SA ledger must mark these
  as DO-NOT-TOUCH decoys for CR/QA.

## 5. Acceptance criteria

Each maps to in-scope items; sub-agents have no Bash and PowerShell is operator-side here, so the run gate
is **[operator-run]**.

- AC-1. `skills/harness-grill/SKILL.md` exists with a rule-15-compliant `description:` (EN + 中文
  triggers + a when-NOT delta vs `/harness`, `/harness-plan`, `/harness-explore`). (Items 1, 2, 9.)
- AC-2. The SKILL.md documents: one-question-at-a-time interview waiting on each answer; a recommended
  answer per question; explore-codebase-to-self-answer; reads `CONTEXT.md` if present (graceful when
  absent); emits an aligned brief to a feature `INPUT.md`. (Items 3–7.)
- AC-3. The SKILL.md contains a "When NOT to invoke" section and an "Anti-patterns" section, the latter
  naming the multi-question-per-turn and ask-what-the-codebase-answers prohibitions. (Item 8.)
- AC-4. The SKILL.md states grill is user-invoked (not auto-firing) and is a pre-pipeline front-end that
  does NOT change stage count or pm-orchestrator routing. (Items 10, 11.)
- AC-5. `agents/requirement-analyst.md` carries a standing one-line rule that every Open Question includes
  a recommended answer, with no contradiction against the existing Hard-rule-1 strip-list or section-8
  wording. (Items 13–15.) A reviewer reads section 8 + Hard rules and confirms coherence.
- AC-6. `plugin.json` + `marketplace.json` + both READMEs' version badges all read `0.35.0`
  (verify_all **G.3** PASS). **[operator-run]** (Items 16–19.)
- AC-7. Both READMEs list `/harness-grill` and claim `16` / `sixteen` (+十六) skills; `CHANGELOG.md` has a
  `[0.35.0]` section containing the literal `harness-grill`. (Items 18–20.)
- AC-8. verify_all **C.1 / G.1 / G.2** reference all **16** skills (the directory-derived loops pick up
  `harness-grill`; labels read `16`) and PASS; **G.4** (claim↔version consistency) PASSes; check count
  stays **32**. **[operator-run]** (Items 26, 27.)
- AC-9. Every ungated skill-count surface flipped to `16`/`sixteen`/`十六` with a `harness-grill` entry
  added where the surface enumerates skills: `AI-GUIDE.md`, `docs/getting-started.md`,
  `docs/manual-e2e-test.md`, `.harness/rules/40-locations.md`, `docs/dev-map.md`. A reviewer greps the live
  tree for every residual `15`/`fifteen`/`十五` SKILL token and confirms each flipped — while the `32`
  CHECK count and `harness-status` "14 required assets" tokens are confirmed UNTOUCHED. (Items 21–25; BC-8.)
- AC-10. `AI-GUIDE.md` ≤ 200 lines after the new Workflow-entry row; its Workflow-entry triggers agree
  with the SKILL.md `description:` (rule 15 P1). (Item 21.)
- AC-11. **[operator-run] gate:** `bash .harness/scripts/verify_all.sh` = 32 PASS / 0 WARN / 0 FAIL;
  PowerShell twin equivalent; if (and only if) templates changed, `test-init` green and `baseline.json`
  reconciled to a real run. (Item 28.)
- AC-12. **Green git tree** at hand-off — no commit, no tag (O-6).

## 6. Non-functional requirements

- NFR-1. **PS/SH symmetry** — any `verify_all` label/loop edit on `.ps1` is mirrored on `.sh`
  (rule 30 #20; verify_all F.1). No new helper script is anticipated (the grill skill is an interview, not
  a file-rewrite engine — it uses Read/Glob/Grep/Write/AskUserQuestion). If the SA introduces any
  `.{ps1,sh}` pair, byte-identical cross-shell output is required where it writes files (insight L25/L29).
- NFR-2. **Doc-size caps (rule 70):** `AI-GUIDE.md` ≤ 200 after edit; `SKILL.md` lean per rule 15 P5
  (progressive disclosure — push any reference detail to a sibling file the skill points at on demand
  rather than front-loading); READMEs / dev-map within their existing budgets.
- NFR-3. **No new placeholder** introduced without registering it in `harness-init/SKILL.md` + the D.2
  whitelist in both verify_all shells (rule 10 #10). Default: introduce none (the grill SKILL is a plugin
  skill, not a template; it ships no `{{placeholder}}`).
- NFR-4. **Self-consistency (rule 10):** the new SKILL is a plugin skill under top-level `skills/`; it
  reaches `.claude/skills/` via `harness-sync` (E.2) at session end. The agent edit is to the plugin-native
  top-level `agents/` (no sync). The SA confirms whether dogfood `.claude/skills/harness-grill/` must exist
  for E.2 to PASS or whether plugin skills live only under top-level `skills/` (mechanical — resolve from
  the E.2 check + how the other 15 skills bind; no user input).
- NFR-5. **No I.6 self-trip (insight L30/L31):** T-03 RETIRES no banned claim, so the I.6 four-file
  lockstep is NOT touched. Any new doc text (CHANGELOG, SKILL.md, AI-GUIDE row) must avoid existing I.6
  banned anchors; SA/Dev/CR confirm I.6 PASS.
- NFR-6. **Install scripts need NO edit** — `install.{ps1,sh}` derive the skill list from the source tree
  (`for skill_dir in "$skills_source"/*/`), so `harness-grill` is auto-included (the old hardcoded-array
  fan-out gap was removed; confirm the `.ps1` twin is equally directory-derived — if not, that asymmetry
  is the SA's to flag, not silently leave).

## 7. Related tasks

- **T-018 `decision-mode-skill`** (`docs/features/_archived/decision-mode-skill/`) — the canonical recent
  "add a skill" task: the complete `14→15` release fan-out ledger (`02_SOLUTION_DESIGN.md` §7 + Amendment 1
  §A1.1/A1.2) is the template for this task's `15→16` ledger; its Gate F-1 (the missed
  `docs/getting-started.md` "fourteen skills" surface) is the exact trap to avoid here. SKILL-authoring
  shape (description, When-NOT, Anti-patterns) mirrored.
- **T-014 `harness-language-skill`** (`docs/features/_archived/harness-language-skill/`) — the other
  canonical skill-add; `02_SOLUTION_DESIGN.md` §11 fan-out ledger shape; the `13→14` count flip across
  README/AI-GUIDE/manual-e2e/40-locations.
- **T-006 `harness-batch-skill`** — first "add a skill" task; the skill-count-drift rollback (M-1) that
  established the count fan-out as the #1 recurring failure.
- **T-02 `context-glossary`** (`docs/features/_archived/context-glossary/`) — SHIPPED `CONTEXT.md` as a
  SOFT dependency (read-if-present + lazy-maintain + graceful-degrade, no precondition, no BLOCKED). The
  grill skill composes with it under exactly that SOFT contract (item 6, BC-1).
- **T-021 `stream-auto-decompose`** — the ingest-triage that decomposes a complex requirement into staged
  rows; relevant to O-5 (grill emits a single brief; decomposition is stream's job, not grill's).
- **T-016 `i18n-special-drift-guard`** — operator preference "design out the root cause; don't accrete
  guards" ([[feedback_design_over_guards]]) — relevant to O-4 (no new check).

## 8. Open questions for user

> deferred-human mode: each carries ≥2 candidates + a **Recommended** answer. None blocks design — all
> recommendations are safe Mode-2 defaults that respect the HARD CONSTRAINTS (scope-expansion red line,
> green-tree, no new guard). The Architect adopts the recommendation unless the user (or a
> `/harness-intervene` NOTE) overrides.

1. **OQ-1 (README/getting-started skill grouping):** `/harness-grill` is a pre-pipeline alignment
   front-end. Which group does its bullet go under? (a) the **Pipeline** group (it precedes the pipeline),
   (b) the **Setup** group, (c) the **Operations** group, (d) a new "Pre-pipeline" mini-group.
   **Recommended: (a)** list it adjacent to `/harness` / `/harness-plan` in the Pipeline group with a one
   phrase "runs before the pipeline to align the requirement" qualifier — it is conceptually the front-door
   to the pipeline, and adding a new group risks churning the README/getting-started structure for one
   item. Safe Mode-2 default (placement is cosmetic, reversible).

2. **OQ-2 (slug source for the emitted brief):** how does the skill determine `<task-slug>` for the
   `docs/features/<task-slug>/INPUT.md` it writes? (a) the skill proposes a slug from the aligned goal and
   confirms it with the user, (b) the user supplies the slug up front, (c) the skill writes to a fixed
   staging path (e.g. `docs/features/_grill-draft/INPUT.md`) and leaves slug assignment to the PM at pickup.
   **Recommended: (a)** propose-and-confirm a kebab-case slug from the goal (consistent with how the PM
   already slugs tasks); falls back to (b) if the user names one. Safe default — keeps the brief
   self-describing and pipeline-ready.

3. **OQ-3 (collision when the target `INPUT.md` already exists):** (a) confirm-before-overwrite, (b) refuse
   and ask for a different slug, (c) silently overwrite. **Recommended: (a)** confirm-before-overwrite
   (never silent-clobber — mirrors the non-destructive posture of `/harness-language` / `/harness-decision-
   mode`); (c) is rejected outright. Safe default.

4. **OQ-4 (zh overlay copy of the grill SKILL):** ship a Chinese `i18n/zh/` overlay copy of
   `harness-grill/SKILL.md` now, or keep SKILL.md English-only (AI-facing scaffolding) with 中文 triggers
   inside the English description? **Recommended: English-only SKILL.md with 中文 triggers in the
   `description:`** (the v0.26 language model: AI-facing scaffolding is English; the description carries
   bilingual triggers for matching). Plugin skills are not part of the `i18n/zh/` overlay set. Safe default
   consistent with all 15 existing skills. (O-8.)

5. **OQ-5 (does grill update `CONTEXT.md` autonomously, or only propose?):** when the interview coins/
   sharpens a domain term, does the skill (a) write it into `CONTEXT.md` inline as it goes (lazy-maintain,
   matching the RA/SA SOFT-dependency contract from T-02), or (b) only list proposed glossary additions in
   the brief for the user/RA to apply? **Recommended: (a)** lazy-maintain inline (this is exactly the T-02
   "maintain it inline when you coin or sharpen a term" contract the RA/SA already follow; keeping grill
   symmetric avoids a divergent glossary discipline). Safe default; the edit is additive and git-visible.

> **Mechanical (Architect resolves, no user input):** (i) whether the verify_all C.1/G.1/G.2 loops are
> directory-derived (so only labels flip) or name-listed (so the loop arrays also change) — read the loop
> bodies; (ii) whether dogfood `.claude/skills/harness-grill/` must exist for E.2 to PASS or plugin skills
> bind only from top-level `skills/` (NFR-4); (iii) the exact wording reconciling the new recommended-answer
> rule with Hard-rule-1's "recommend" strip-list (item 15, BC-7); (iv) whether the `install.ps1` twin is
> directory-derived like `install.sh` (NFR-6).

## 9. Verdict

**READY (with recommended defaults).**

Rationale: the INPUT brief is highly prescriptive (it pre-decides the skill home, the user-invoked posture,
the SOFT `CONTEXT.md` composition, the no-new-check / no-stage-change boundaries, and the second
deliverable). The five Open Questions are genuine residual choices, but every one has a safe Mode-2 default
that respects the HARD CONSTRAINTS — none blocks the Architect. The mechanical items (i)–(iv) are resolved
by the Architect from the checks/scripts, not by the user. The Architect should adopt the recommended
answers unless the user (or a `/harness-intervene` NOTE) overrides; OQ-1 (grouping) and OQ-4 (zh overlay)
are the only ones with any user-visible surface and both are cosmetic/reversible. Recommend the PM advance
to Stage 2 (Solution Architect) carrying these defaults; the SA's load-bearing deliverable is the
exhaustive live-grep `15→16` count-claim ledger (T-018 §7 / Amendment 1 is the template — do not miss
`getting-started.md`).
