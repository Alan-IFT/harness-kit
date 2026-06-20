# 02 — Solution Design · T-03 harness-grill

> Stage 2 (Solution Architect). Mode: **full**. Upstream: `01_REQUIREMENT_ANALYSIS.md` — Verdict **READY**.
> PM ACCEPTED the RA recommended defaults for all 5 OQs; this design adopts them (OQ-1=a Pipeline group,
> OQ-2=a propose-and-confirm kebab slug, OQ-3=a confirm-before-overwrite, OQ-4=English-only SKILL.md w/ 中文
> triggers, OQ-5=a lazy-maintain CONTEXT.md inline). deferred-human mode: defer, do not ask.
>
> Grounded by LIVE reads of: `INPUT.md`, `AI-GUIDE.md`, `.harness/insight-index.md`, `docs/dev-map.md`,
> `.harness/rules/15-skill-authoring.md` + 20/40, `agents/requirement-analyst.md`, `skills/harness-explore`
> + `harness-language` + `harness-status` SKILLs, the mattpocock `grilling` / `grill-with-docs` reference
> SKILLs, `verify_all.{sh,ps1}` C.1/C.2/G.1/G.2/G.3/G.4 sites (read in full), `install.{sh,ps1}`,
> `test-init.sh`, `baseline.json`, `plugin.json`, `marketplace.json`, `README.md` + `README.zh-CN.md`,
> `docs/getting-started.md`, `docs/manual-e2e-test.md`, `.harness/rules/40-locations.md`, `CHANGELOG.md`,
> and the T-018 `decision-mode-skill/02_SOLUTION_DESIGN.md` §7 + **Amendment 1** (the canonical ledger shape).

## 1. Architecture summary

A documentation + skill change, no runtime/binary code. Two deliverables plus the standard new-skill release
fan-out: (A) a NEW user-invoked plugin skill `skills/harness-grill/SKILL.md` — a relentless one-question-at-a-
time, pre-pipeline ALIGNMENT interview that recommends an answer per question, self-answers from the codebase
where it can, composes with `CONTEXT.md` under the T-02 SOFT contract, and writes an aligned brief to a feature
`docs/features/<slug>/INPUT.md` the existing pipeline / `/harness-stream` pool consumes (it is NOT a pipeline
stage and does NOT change `pm-orchestrator` routing); (B) a one-line **standing rule** on
`agents/requirement-analyst.md` that every Open Question carries a Recommended answer, reconciled so it does
not collide with Hard-rule-1's "recommend" strip-list; (C) the **15→16 skill-count release fan-out** at
version **0.35.0** — READMEs, CHANGELOG, AI-GUIDE Workflow-entry, getting-started, manual-e2e, 40-locations,
dev-map, and the C.1/G.1/G.2 verify_all skill-enumeration arrays + labels in BOTH shells. **No new verify_all
check** (check count stays **32**, G.4 unaffected except for the version-stamp + CHANGELOG-heading it already
gates). **No test-init / baseline change** (grill is a top-level plugin skill, not a generated-project
template asset; test-init asserts no plugin-skill count — verified). **No install.{ps1,sh} edit needed** for
the skill list (both are directory-derived — verified) — only a soft help-text listing is flagged.

## 2. Affected modules / files

### Family A — new plugin skill
- `skills/harness-grill/SKILL.md` — **NEW**. Top-level plugin skill, sibling of the other `/harness-*`
  skills. C.1 (verify_all) enumerates a hardcoded name array — `harness-grill` MUST be added to it (see §7;
  the C.1 loop is NOT directory-derived, contra RA item 26 — resolved here).

### Family B — standing rule (framework agent, plugin-native, NO sync)
- `agents/requirement-analyst.md` — **EDIT**. Add the Recommended-answer standing rule + reconcile the
  Hard-rule-1 strip-list. Edited in place per AI-GUIDE "Editing rules" (Claude Code auto-discovers
  `harness-kit:requirement-analyst`; framework agents are plugin-native — no harness-sync).

### Family C — release fan-out (the 15→16 + 0.35.0 stamp)
- `.claude-plugin/plugin.json` — EDIT `"version"` 0.34.0 → 0.35.0.
- `.claude-plugin/marketplace.json` — EDIT `plugins[0].version` 0.34.0 → 0.35.0.
- `README.md` — EDIT version badge + count claims + new skill bullet (§7).
- `README.zh-CN.md` — EDIT mirror (§7).
- `CHANGELOG.md` — EDIT: new `## [0.35.0]` section (§7).
- `AI-GUIDE.md` — EDIT: `:7` count + new Workflow-entry row (§7).
- `docs/getting-started.md` — EDIT: `:36` count + new skill bullet (§7).
- `docs/manual-e2e-test.md` — EDIT: `:7/:34/:49/:60` counts + add `harness-grill` to each enumeration (§7).
- `.harness/rules/40-locations.md` — EDIT: `:31` `All 15 skills` → `All 16 skills` (§7).
- `docs/dev-map.md` — EDIT: skills-tree row + a `Skill: harness-grill` lookup row (§7).
- `.harness/scripts/verify_all.sh` — EDIT: C.1/G.1/G.2 arrays + labels (§7).
- `.harness/scripts/verify_all.ps1` — EDIT: C.1/G.1/G.2 arrays + labels (§7, F.1 symmetry).

### NOT touched (resolved mechanical items + decoys)
- `install.ps1`, `install.sh` — skill list is directory-derived (both shells, verified); no edit needed for
  enumeration. The trailing "Use in Claude Code:" help block hardcodes a per-skill listing that omits
  `harness-grill` — see §11 (soft, ungated; recommend adding for honesty, flag to operator).
- `.harness/scripts/test-init.{ps1,sh}` + `baseline.json` — no plugin-skill-count assertion exists (verified:
  zero `grill`/`skills present`/`All N skills` matches in test-init.sh; `baseline.json:skill_count_baseline:4`
  is a stale 2026-05-15 historical number, not a live 15/16 tally). No edit, no recapture.
- `.claude/skills/`, `.harness/skills/` — both EMPTY (verified by Glob). Plugin skills bind ONLY from
  top-level `skills/`; harness-sync/E.2 mirror `.harness/skills ↔ .claude/skills` (both empty). `harness-grill`
  needs NO `.claude/skills/` copy and NO sync run — same as all 15 existing skills (resolves NFR-4).
- DO-NOT-TOUCH count decoys (BC-8 / insight L26): `CHANGELOG.md:74` "the 15 skills" (frozen v0.30.1 historical
  entry); `skills/harness-status/SKILL.md:135` "All 14 required assets" (health denominator, not a skill
  count); every `32`/`(32 checks)`/`（32 项检查）`/`32%2F32` CHECK-count token; the `308`/`90` test badges
  (test counts, unchanged by this task).

## 3. Module decomposition — `skills/harness-grill/SKILL.md`

A pure interview skill: NO `.{ps1,sh}` helper. Rationale (rule 15 P6/P7): the work is Read/Glob/Grep (to
self-answer + read CONTEXT.md), AskUserQuestion (the interview), and Write/Edit (the brief + optional CONTEXT.md
sharpen). There is no cross-shell file-rewrite engine, no byte-identity / section-slicing problem — so a
`.{ps1,sh}` pair would add NFR-1 parity burden for nothing (mirrors the T-018 decision NOT to add a helper).

### 3.1 Frontmatter `description:` (rule 15 P1 — model-facing, EN + 中文 triggers, when-NOT delta)

```
---
name: harness-grill
description: Relentlessly interview the user ONE question at a time to pin down what they
  actually want BEFORE any pipeline runs — a pre-pipeline alignment session that walks the
  design tree, gives a recommended answer for every question, explores the codebase to
  self-answer instead of asking when the repo already decides it, reads CONTEXT.md for
  canonical terms when present, and emits an aligned brief to docs/features/<slug>/INPUT.md
  that /harness, /harness-plan, or the /harness-stream pool then consumes. User-invoked
  only (you start the session deliberately); it does not write design, code, or findings
  and does not change the 7-stage pipeline. Use when "grill me on this", "interview me
  about this plan", "pin down what I actually want before we build", "stress-test my
  requirement first", "拷问我的需求", "逐条对齐需求", "动手前先把需求问清楚", "先把需求拷问
  清楚再开干". NOT /harness (requirement already clear enough to ship), NOT /harness-plan
  (vet an existing design, not discover the requirement), NOT /harness-explore (feasibility
  "can we even do X?" research) — grill is the "I'm not sure I've said what I actually
  want yet" front-end that PRECEDES all three.
allowed-tools: Read, Write, Edit, Glob, Grep, AskUserQuestion, TodoWrite
---
```

`allowed-tools` notes:
- **NO `Task`** — grill does NOT dispatch the pipeline (item 11; it stops at the brief).
- **NO `Bash`/`PowerShell`** — no helper, no script run; keeps it tool-light (rule 15). `Write`+`Edit` create
  the brief / sharpen CONTEXT.md.
- **`AskUserQuestion`** is the interview engine (one question per turn — see §3.4).

### 3.2 User-invoked-only posture (item 10, O-1)

Claude Code auto-fires a skill from its `description:` triggers. Grill's triggers are all explicit, deliberate
phrasings a human types to *start an alignment session* ("grill me", "拷问我的需求") — they do not match
incidental requests, so it does not auto-fire on ordinary asks. The SKILL.md body states plainly: "This is a
deliberately user-started session. Do not invoke it as a side effect of another task." (The reference
`grill-with-docs` uses a `disable-model-invocation: true` frontmatter flag; Claude Code's plugin-skill schema
does not expose that key — none of the 15 existing skills use it — so the posture is carried by the
deliberate-trigger description + the explicit prose statement, consistent with how every sibling skill is
authored. This is the OQ-10/item-10 "exact mechanism is the Architect's to specify" resolution.)

### 3.3 SKILL.md body — section map (progressive disclosure, rule 15 P5; target ~comparable to siblings,
well under the implicit ~215-line `/harness-language` budget; AI-GUIDE row + this skill stay lean)

1. **`# /harness-grill`** + one-line purpose.
2. **When to invoke** — the deliberate-start triggers; "you have a fuzzy idea and want it pinned before the
   pipeline spends effort on the wrong target."
3. **When NOT to invoke** (item 8/9, the bright-line delta — REQUIRED): the three sibling deltas, verbatim
   intent from RA item 9:
   - Requirement already clear enough to ship → `/harness`.
   - You have a design and want it vetted (not to discover the requirement) → `/harness-plan`.
   - "Can we even do X?" feasibility → `/harness-explore`.
   - Grill is PRE-pipeline alignment; it produces a brief and STOPS — it never runs the pipeline, writes
     design/code, or produces findings.
4. **The interview engine** (items 3,4,5):
   - One question at a time; wait for the user's answer before asking the next (NEVER batch — see Anti-patterns).
   - Walk the design tree, resolving dependencies between decisions one by one until a shared understanding.
   - Every question is presented WITH the skill's own **Recommended answer** (user may accept / override /
     refine).
   - **Explore-codebase-to-self-answer**: before asking, check whether the repo already answers it (existing
     conventions, file locations, prior art, what a symbol does). If yes → resolve it yourself, state what you
     found + the chosen resolution, and do NOT ask the user (BC-3).
5. **CONTEXT.md composition** (item 6, BC-1, OQ-5=a): read `CONTEXT.md` at repo root if present; use its
   canonical terms when phrasing questions and writing the brief. If you coin or sharpen a domain term during
   the interview, lazy-maintain it inline in `CONTEXT.md` (bold term + 1–2 sentence definition + `_Avoid_:`
   synonyms) — the same SOFT contract RA/SA already follow (T-02). If `CONTEXT.md` is absent: proceed without
   it, never block, never print a setup pointer, never create it just to populate it (create/sharpen ONLY when
   a term is genuinely coined).
6. **The terminal artifact — the aligned brief** (item 7, OQ-2=a, OQ-3=a, BC-4/5/6):
   - **Slug (OQ-2=a):** propose a kebab-case `<slug>` derived from the agreed goal and confirm it with the
     user (fall back to a user-supplied slug). Mirrors how PM already slugs tasks.
   - **Path:** `docs/features/<slug>/INPUT.md`. Create the `docs/features/<slug>/` path as needed (BC-6 — do
     not fail on absent parent dir).
   - **Collision (OQ-3=a, BC-4):** if the target `INPUT.md` already exists → confirm-before-overwrite (never
     silent clobber; never silently overwrite an unrelated brief). Offer a different slug on decline.
   - **Brief shape** (so the requirement-analyst can consume it as INPUT.md): a one-sentence Goal; the
     resolved decisions (each: question → agreed answer, noting where it was self-answered from the codebase);
     any residual open items; and — if relevant — a "Glossary touches" note listing terms coined/sharpened in
     CONTEXT.md. The brief is the requirement-analyst's input, NOT a requirement spec itself (it does not
     pre-empt the RA's 9-section doc).
   - **Early end (BC-5):** if the user ends before alignment is complete, write whatever was agreed and record
     the residual open items in the brief — no silent loss of the partial interview.
   - **Empty/"I don't know" answer (BC-2):** adopt the Recommended answer as the working default and continue;
     never hang waiting on a perfect answer.
7. **Not a pipeline stage** (item 11, O-3): grill does NOT alter `pm-orchestrator` routing or the 7-stage flow;
   it is a standalone front-end emitting an INPUT.md the existing pipeline consumes. After writing the brief it
   tells the user how to pick it up (`/harness <slug>` or drop the slug into a `/harness-stream` pool).
8. **Anti-patterns** (item 8 — REQUIRED, names ≥2 prohibitions):
   - Asking multiple questions in one turn (bewildering — one at a time, always).
   - Asking the user a question the codebase already answers (explore and resolve it instead).
   - (plus) Silently overwriting an existing brief; running the pipeline / writing design or code (out of
     scope — emit the brief and stop); blocking on absent `CONTEXT.md`.

### 3.4 Interview-engine contract (invariants, not a rigid script — rule 15 P4)

State the invariants and let the agent adapt: (i) exactly one open question per turn; (ii) every question
carries a Recommended answer; (iii) self-answer from the repo before asking; (iv) the loop terminates when the
user signals alignment OR ends the session; (v) the single terminal side effect is the brief at
`docs/features/<slug>/INPUT.md` (+ optional CONTEXT.md sharpen). No step-by-step railroad.

## 4. Standing rule on `agents/requirement-analyst.md` (Family B) — the strip-list reconciliation

The collision (RA item 15, BC-7): the agent's **Hard rule 1** is `**No ambiguous words.** Strip "maybe",
"should", "could", "probably", "suggest", "recommend".` — it bans the bare word "recommend". The new standing
rule REQUIRES a labelled "Recommended:" answer per Open Question. Reconcile by **scoping the ban to requirement
PROSE and exempting the labelled Open-Questions field**, so both coexist with zero ambiguity for a reader.

Two precise edits (both `Edit`, no other section changes — O-7 keeps the analyst otherwise unchanged):

**Edit 1 — Hard rule 1 (scope the ban + carve the exemption), at `agents/requirement-analyst.md:28`:**

> 1. **No ambiguous words in requirement statements.** Strip "maybe", "should", "could", "probably",
>    "suggest", "recommend" from in-scope behaviors, acceptance criteria, and boundary conditions — these are
>    binding statements and must be unambiguous. *(Exception: the labelled `Recommended:` answer on an Open
>    Question in section 8 is a deliberate, allowed construct — see "What you produce" §8; the ban is on
>    hedging requirement prose, not on a clearly-labelled recommended answer.)*

**Edit 2 — section 8 of "What you produce" (the standing rule), at `agents/requirement-analyst.md:23`:**

> 8. **Open questions for user**: numbered, each with at least 2 candidate answers AND a labelled
>    **`Recommended:`** answer (the analyst's recommended resolution, which the PM/Architect adopts unless
>    overridden). This is a standing rule — it holds in every mode, and it is exactly the behavior the analyst
>    already performs under deferred-human mode, generalized.

Why this wording is safe:
- The ban now reads "in requirement statements" / "from in-scope behaviors, acceptance criteria, and boundary
  conditions" — the *binding* prose where hedging is genuinely harmful. The Open-Questions Recommended field is
  explicitly exempted, so a reader sees no contradiction (AC-5: "a reviewer reads section 8 + Hard rules and
  confirms coherence").
- The word "recommend" still cannot appear as a hedge in a requirement sentence (Hard rule 1 intact there); it
  appears ONLY as the labelled `Recommended:` field — a distinct, named construct, not a hedge.
- **I.6 caution (NFR-5):** the word "recommend" is NOT an I.6 banned anchor (the I.6 list is the
  CLAUDE.md/zh-policy retired-claims set — verified in `verify_all.sh` `i6_banned`), so these edits do not
  touch the I.6 four-file lockstep. No retired claim is introduced.

This edit is also self-consistent with THIS very RA doc and the archived T-018/T-02 RA docs, which already
carry a `Recommended:` field per Open Question — the rule codifies existing practice.

## 5. Sequence / flow (the grill session, happy + edge paths)

```
/harness-grill
 1. (optional) read CONTEXT.md at repo root → load canonical terms   [absent → proceed, no block]
 2. establish the fuzzy goal from the user's opening ask
 3. LOOP, one question per turn, walking the design tree:
      a. pick the next unresolved decision
      b. can the REPO answer it? (Read/Glob/Grep existing conventions, prior art, symbols)
            ──yes──► resolve it yourself; state finding + chosen resolution; record; goto (a)
            ──no───► present ONE question + a Recommended answer
                     wait for the user's answer
                        accept / refine ─► record the agreed answer
                        empty / "don't know" (BC-2) ─► adopt Recommended as working default; record
                     (if a term is coined/sharpened → lazy-maintain CONTEXT.md inline)  [OQ-5=a]
      c. aligned? ──no──► goto (a)   ;   user ends early (BC-5) ──► break with residual items
 4. propose a kebab-case <slug> from the goal; confirm with user           [OQ-2=a]
 5. target docs/features/<slug>/INPUT.md exists?
        ──yes──► confirm-before-overwrite; on decline → new slug           [OQ-3=a, BC-4]
        ──no───► create docs/features/<slug>/ as needed                    [BC-6]
 6. Write the aligned brief (Goal · resolved decisions · residual open items · glossary touches)
 7. report: brief path + how to pick it up (/harness <slug> or drop into a /harness-stream pool)
    [grill STOPS here — no pipeline run, no design, no code]               [item 11, O-3, O-5]
```

## 6. The COMPLETE 15→16 skill-count fan-out ledger (live-grep-backed)

> This is the project's #1 recurring failure surface (insight L24/L5; getting-started.md "fourteen skills" bit
> T-018's Gate F-1). Every surface below was confirmed against the LIVE repo (grep + Read), not reasoned from
> the RA list. **Gating column is authoritative.** Each `15`→`16` / `fifteen`→`sixteen` site is exact.

### 6.1 Version stamps (gated G.3 — all four must match; G.4 also reads plugin.json + CHANGELOG heading)

| # | File | Site (live) | Change | Gated by |
|---|---|---|---|---|
| 1 | `.claude-plugin/plugin.json` | `:4` `"version": "0.34.0"` | → `0.35.0` | G.3 + G.4 |
| 2 | `.claude-plugin/marketplace.json` | `:17` `"version": "0.34.0"` (plugins[0]) | → `0.35.0` | G.3 |
| 3 | `README.md` | `:5` badge `version-0.34.0-blue` | → `version-0.35.0-blue` | G.3 |
| 4 | `README.zh-CN.md` | `:5` badge `version-0.34.0-blue` | → `version-0.35.0-blue` | G.3 |

### 6.2 Skill-count claims + skill-list enumerations (15→16 / fifteen→sixteen + add a `harness-grill` entry)

| # | File | Site (live) | Current → Target | Gated by |
|---|---|---|---|---|
| 5 | `README.md` | `:7` `(15 skills + 8 framework agents` | `16 skills` | prose (G.1 gates name presence, not count) |
| 6 | `README.md` | `:13` `gives any project fifteen AI skills:` | `sixteen AI skills` | prose |
| 7 | `README.md` | `:15-21` **Pipeline skills** list (OQ-1=a) | add `/harness-kit:harness-grill` bullet, framed "runs before the pipeline to align the requirement" | G.1 (name) |
| 8 | `README.zh-CN.md` | `:7` `（15 个 skills + 8 个框架 agent` | `16 个 skills` | prose |
| 9 | `README.zh-CN.md` | `:13` `给任何项目装上 15 个 AI skill：` | `16 个 AI skill` | prose |
| 10 | `README.zh-CN.md` | `:15-21` **流水线类** list (mirror #7) | add `/harness-kit:harness-grill` bullet (中文) | G.1 (name) |
| 11 | `CHANGELOG.md` | top (above `## [0.34.0]`) | new `## [0.35.0]` section; MUST contain literal `harness-grill` ≥1× and note `15 → 16` + version bump | G.2 (name) + G.4 (heading) |
| 12 | `AI-GUIDE.md` | `:7` `distributes 15 skills + templates` | `16 skills` | prose |
| 13 | `AI-GUIDE.md` | Workflow-entry table (`:88-99`) | add a `/harness-grill` row (EN + 中文 triggers agreeing with the SKILL.md `description:`, rule 15 P1) | prose (≤200-line cap, AC-10) |
| 14 | `docs/getting-started.md` | `:36` `makes fifteen skills available` | `sixteen skills` | — (ungated, MANUAL — the surface that bit T-018) |
| 15 | `docs/getting-started.md` | `:38-45` **Pipeline** group (mirror README #7) | add a `harness-grill` bullet | — (ungated) |
| 16 | `docs/manual-e2e-test.md` | `:7` `load the fifteen skills?` | `sixteen` | — (ungated) |
| 17 | `docs/manual-e2e-test.md` | `:34` `"Would copy" for all 15 skills (harness, …)` | `16 skills` + add `harness-grill` to the parenthetical enumeration | — (ungated) |
| 18 | `docs/manual-e2e-test.md` | `:49` `"Installed" for all 15 skills. … list them:` + `:53-54` comment list | `16 skills` + add `harness-grill` to the post-completion listing | — (ungated) |
| 19 | `docs/manual-e2e-test.md` | `:60` `the fifteen /harness-* commands appear (…)` | `sixteen` + add `/harness-grill` to the command enumeration | — (ungated) |
| 20 | `.harness/rules/40-locations.md` | `:31` `All 15 skills present with valid frontmatter` | `All 16 skills` | — (ungated, MANUAL) |
| 21 | `docs/dev-map.md` | `:44-57` skills tree | add a `harness-grill/SKILL.md` row (mirror the `harness-language`/`harness-decision-mode` tree rows) | — |
| 22 | `docs/dev-map.md` | `:144-156` "Where features live" table | add a `Skill: harness-grill` lookup row | — |

### 6.3 verify_all skill-enumeration arrays + labels (BOTH shells — RA item 26 CORRECTED: loops are NAME-ARRAY, not directory-derived)

The C.1/G.1/G.2 loops iterate a **hardcoded skill-name array** in both shells (verified: `verify_all.sh:56,329,345`;
`verify_all.ps1:69,301,327`). So each loop needs `harness-grill` ADDED to the array **and** its label flipped
15→16 — NOT label-only.

| # | File | Site (live) | Change | Gated by |
|---|---|---|---|---|
| 23 | `.harness/scripts/verify_all.sh` | `:56` C.1 `for s in harness … harness-decision-mode;` | append ` harness-grill` to the array | self (C.1) |
| 24 | `.harness/scripts/verify_all.sh` | `:59` label `"All 15 skills present"` (×2 PASS/FAIL strings) | `All 16 skills present` | self |
| 25 | `.harness/scripts/verify_all.sh` | `:329` G.1 `for s in … harness-decision-mode;` | append ` harness-grill` | self (G.1) |
| 26 | `.harness/scripts/verify_all.sh` | `:332` label `"README references all 15 skills"` (×2) | `all 16 skills` | self |
| 27 | `.harness/scripts/verify_all.sh` | `:345` G.2 `for s in … harness-decision-mode;` | append ` harness-grill` | self (G.2) |
| 28 | `.harness/scripts/verify_all.sh` | `:348` label `"CHANGELOG references all 15 skills"` (×2) | `all 16 skills` | self |
| 29 | `.harness/scripts/verify_all.ps1` | `:69` C.1 `@("harness", …, "harness-decision-mode")` | append `, "harness-grill"` | F.1 (ps/sh parity) |
| 30 | `.harness/scripts/verify_all.ps1` | `:68` label `"All 15 skills present with SKILL.md"` | `All 16 skills` | F.1 |
| 31 | `.harness/scripts/verify_all.ps1` | `:301` G.1 array | append `, "harness-grill"` | F.1 |
| 32 | `.harness/scripts/verify_all.ps1` | `:299` label `"README references all 15 skills"` | `all 16 skills` | F.1 |
| 33 | `.harness/scripts/verify_all.ps1` | `:327` G.2 array | append `, "harness-grill"` | F.1 |
| 34 | `.harness/scripts/verify_all.ps1` | `:325` label `"CHANGELOG mentions all 15 skills"` | `all 16 skills` | F.1 |

### 6.4 Which verify_all checks ENFORCE the count after these edits

- **C.1** — `skills/harness-grill/SKILL.md` must exist (FAILs if Family A is missing) AND its label reads `16`.
- **C.2** — frontmatter sanity: the new SKILL.md must have `---` + `name:` + `description:` (auto-scans
  `skills/**/SKILL.md`).
- **G.1** — README.md must contain the literal `harness-grill` (array add) — gates name presence.
- **G.2** — CHANGELOG.md must contain the literal `harness-grill` (array add) — gates the CHANGELOG mention.
- **G.3** — plugin.json / marketplace.json / both README badges all read `0.35.0`.
- **G.4** — plugin.json version `0.35.0` ⇒ CHANGELOG.md MUST have a `[0.35.0]` heading (else G.4 FAIL); G.4 also
  pins the CHECK count (32) — **unchanged**, so its 11 `(N checks)` count rows are NOT touched (DO-NOT-TOUCH).
- The ungated surfaces (#14-20) have NO check — CR/QA grep the live tree for residual `15`/`fifteen` SKILL
  tokens (AC-9) while confirming the `32`/`(32 checks)`/`14 required assets`/`308`/`90` decoys are untouched.

### 6.5 The COMPLETE surface list (file roll-up, for the gate ledger)

Skill-count / skill-list / version surfaces touched by this task — **13 files**:
1. `.claude-plugin/plugin.json`
2. `.claude-plugin/marketplace.json`
3. `README.md`
4. `README.zh-CN.md`
5. `CHANGELOG.md`
6. `AI-GUIDE.md`
7. `docs/getting-started.md`
8. `docs/manual-e2e-test.md`
9. `.harness/rules/40-locations.md`
10. `docs/dev-map.md`
11. `.harness/scripts/verify_all.sh`
12. `.harness/scripts/verify_all.ps1`
13. (soft, ungated, recommended) `install.ps1` + `install.sh` help-text listing — see §11.

DO-NOT-TOUCH count decoys (confirm UNTOUCHED at CR/QA): `CHANGELOG.md:74` "the 15 skills" (frozen history);
`skills/harness-status/SKILL.md:135` "All 14 required assets"; all `32` / `(32 checks)` / `（32 项检查）` /
`32%2F32` CHECK tokens; `308`/`90` test badges; `baseline.json:skill_count_baseline:4` (stale history).

## 7. Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| Skill shape (When-NOT + Anti-patterns + model-facing description) | `/harness-explore` SKILL | `skills/harness-explore/SKILL.md` (When-NOT `:20`, Anti-patterns `:79`) | **Reuse the pattern** (sibling delta, anti-patterns surface) |
| Description authoring (EN+中文 triggers, when-NOT delta vs siblings) | `/harness-language`, `/harness-decision-mode` descriptions | `skills/harness-language/SKILL.md:3-10`; archived T-018 §3 | Mirror the bilingual-trigger + when-NOT shape |
| The interview engine (one-at-a-time, recommended answer, explore-to-self-answer) | mattpocock `grilling` | `c:\Programs\_research\mattpocock-skills\skills\productivity\grilling\SKILL.md` | Adapt its 3 invariants into §3.4 (our idiom + brief emission) |
| CONTEXT.md SOFT-dependency contract (read-if-present, lazy-maintain, graceful-degrade) | T-02 RA/SA wording | `agents/requirement-analyst.md:42`; `AI-GUIDE.md:39` | Reuse verbatim contract (§3 step 5) |
| New-skill release fan-out ledger shape | T-018 §7 + Amendment 1 | `docs/features/_archived/decision-mode-skill/02_SOLUTION_DESIGN.md:203-353` | Mirror its ledger discipline (§6 here) |
| Directory-derived install (no per-skill array) | `install.{sh,ps1}` | `install.sh:82-85`, `install.ps1:79-81` | Reuse as-is — no edit (NFR-6 confirmed both shells) |
| Skill-count enumeration sites | verify_all C.1/G.1/G.2 | `.harness/scripts/verify_all.{sh,ps1}` | Edit arrays + labels (§6.3) — NOT directory-derived |
| Interview UI | `AskUserQuestion` | — | Standard tool; no helper |
| Brief / file write | `Write`, `Edit` | — | Direct; no `.{ps1,sh}` pair (§3 rationale) |

## 8. Risk analysis

- **R1 — Skill-count fan-out drift (recurring, insight L24/L5; the #1 historical failure).** A `15`/`fifteen`
  left somewhere → C.1/G.1/G.2 FAIL or a silent prose lie; or a `harness-grill` enumeration entry missed.
  *Mitigation:* §6 exhaustive live-grep ledger (22 doc sites + 12 verify_all sites); Dev runs verify_all
  (operator-run); CR + QA grep every `15`/`fifteen` SKILL token and confirm each flipped, while confirming the
  `32`/`14 required assets`/`308`/`90`/historical-CHANGELOG decoys are UNTOUCHED (BC-8, insight L26).
- **R2 — RA assumed verify_all loops are directory-derived (item 26), but they are NAME-ARRAY.** Editing only
  the labels (the RA's stated minimal edit) would leave the arrays at 15 → C.1/G.1/G.2 would NOT enforce
  `harness-grill` and could even pass while the README/CHANGELOG silently omit it. *Mitigation:* §6.3 corrects
  this explicitly — both the ARRAY and the label change in both shells; F.1 catches ps/sh asymmetry.
- **R3 — Strip-list collision left unreconciled → self-contradicting agent contract (BC-7).** A reviewer
  reading Hard-rule-1 ("strip 'recommend'") next to the new "Recommended:" rule sees a contradiction.
  *Mitigation:* §4 scopes the ban to requirement PROSE and explicitly exempts the labelled Open-Questions
  field; AC-5 reviewer-coherence check. No I.6 anchor touched (NFR-5).
- **R4 — verify_all C.1/G.1/G.2 ps/sh drift (F.1).** Editing one shell only. *Mitigation:* §6.3 pairs every
  edit across shells; F.1 FAILs on asymmetry; CR audits both shells line-for-line.
- **R5 — Grill auto-fires / behaves as a pipeline stage (O-1, O-3, item 11).** A too-broad description could
  make it fire on incidental asks, or the body could imply it runs the pipeline. *Mitigation:* §3.2
  deliberate-trigger-only description + explicit "user-started, do not auto-invoke" prose; §3.3 §7 + §5
  state it STOPS at the brief; NO `Task` in allowed-tools (it physically cannot dispatch the pipeline).
- **R6 — Brief silently clobbers an existing INPUT.md (BC-4).** *Mitigation:* OQ-3=a confirm-before-overwrite
  in §3 step 6 / §5 step 5; the SKILL.md Anti-patterns names silent overwrite as prohibited.
- **R7 — Doc-size cap breach (rule 70 / AC-10).** AI-GUIDE.md is at 110 lines; one Workflow-entry row + a
  one-word count edit keeps it well under 200. *Mitigation:* keep the row to one table line; CR confirms I.1
  PASS and the Workflow triggers agree with the SKILL.md description (AC-10).
- **R8 — I.6 self-trip (insight L30/L31, NFR-5).** T-03 RETIRES no claim; the I.6 four-file lockstep is NOT
  touched. *Mitigation:* the new CHANGELOG/SKILL/AI-GUIDE/brief text avoids the I.6 banned anchors (the
  CLAUDE.md/zh-policy retired set — none of which this task's prose contains); CR/QA confirm I.6 PASS.
- **R9 — fabricated test/version tally (insight L23/T-007).** No test-init/baseline change here, so no tally
  to fabricate — but the operator-run verify_all/test badges must come from a real run, never hand-typed.
  *Mitigation:* AC-11 marks verify_all as [operator-run]; sub-agents have no Bash, so Dev does NOT invent a
  PASS count — the operator runs it PS-side and reconciles.

## 9. Migration / rollout plan

- **Backwards compatible / additive.** New skill file + an additive agent-contract rule + count/version
  bumps. No data, no API, no schema. No existing behavior changes.
- **Binding:** `harness-grill` is a top-level plugin skill — Claude Code auto-discovers it from `skills/`
  (the same mechanism as the 15 existing skills). No `.claude/skills/` copy, no harness-sync run (NFR-4).
- **Generated projects:** unaffected — grill is a plugin skill, not a `templates/` asset; nothing ships into
  generated projects' trees (so no test-init change).
- **Rollback:** green-tree hand-off; the operator's `git reset` reverts everything (HARD CONSTRAINT — no
  commit/tag by a sub-agent, O-6).
- **Release stamp:** version **0.35.0** (a skill-count change is version-worthy, insight L24). G.3 stamp
  targets: plugin.json, marketplace.json, README.md badge, README.zh-CN.md badge. CHANGELOG `[0.35.0]` heading
  (G.4-gated). Check count stays **32** (no new check — O-4). Skill-count claims move 15→16 (G.4 does NOT gate
  skill count; C.1/G.1/G.2 labels + the ungated surfaces carry it).

## 10. Out-of-scope clarifications (design boundaries)

- No `grill.{ps1,sh}` helper — the skill is an interview (Read/Glob/Grep/AskUserQuestion/Write/Edit), §3.
- No model-invocation / auto-firing (O-1) — user-invoked only; no `Task` in allowed-tools.
- No new `verify_all` check (O-4) — check count stays 32; the C.1/G.x edits modify existing checks.
- No pipeline-stage / pm-orchestrator change (O-3, item 11) — grill emits a brief and stops.
- No auto-decomposition of the brief into staged sub-tasks (O-5) — that is `/harness-stream` ingest triage's
  job; grill emits a single aligned INPUT.md.
- No zh `i18n/zh/` overlay copy of the SKILL (O-8, OQ-4) — English SKILL.md with 中文 triggers in the
  description; plugin skills are not in the overlay set.
- No refactor of the requirement-analyst beyond the one-line rule + the scoped-ban exemption (O-7).
- No test-init / baseline edit — no plugin-skill-count assertion exists there (verified).
- No git commit / push / tag (O-6) — green tree; operator stamps and ships.

## 11. Design notes / items to flag to the operator

- **Install help-text (soft, ungated, RECOMMENDED).** `install.{ps1,sh}` enumerate the skill list correctly
  (directory-derived) so the actual install includes `harness-grill` automatically — NFR-6 holds for BOTH
  shells (verified). HOWEVER, the trailing human-readable "Use in Claude Code:" block in both scripts
  (`install.sh:137-154`, `install.ps1:141-156`) hardcodes a per-skill listing that does NOT include
  `harness-grill`. This is the same class as the manual-e2e listing — not gated, but it is a skill enumeration
  that drifts. **Recommendation:** add a `/harness-grill` help line to both scripts' help blocks (symmetric,
  F.1-safe — these are echo/Write-Host lines, no logic), for honesty and parity. Not strictly required by any
  AC; included as a §6.5 row-13 soft surface. (If the operator prefers minimal scope, it can be deferred — but
  it would then be a known stale enumeration, like the pre-T-018 install array gap.)
- **RA item 26 correction (load-bearing).** RA item 26/NFR(mech-i) hypothesized the C.1/G.1/G.2 loops might be
  directory-derived ("if so the label strings are the only edits"). They are NOT — they are hardcoded name
  arrays in both shells. §6.3 is authoritative: ADD `harness-grill` to each array AND flip each label. A
  label-only edit would be incomplete.
- **README.zh-CN count tokens are Arabic, not 十六.** RA items 19/AC-7 mention `十五→十六`; the LIVE zh README
  uses `15 个 skills` / `15 个 AI skill` (Arabic numerals), not 十五. §6.2 #8/#9 use the exact live strings.
  CR/QA should grep `15 个` (zh) not 十五.
- **OQ-1=a placement caveat (design note, not a re-open).** Listing grill in the README/getting-started
  **Pipeline** group is the PM-accepted default. Minor tension: grill is pre-pipeline and conceptually a
  front-door, not one of the "six task shapes" the Pipeline group enumerates. The brief framing ("runs before
  the pipeline to align the requirement") resolves it; if the operator later prefers a "Pre-pipeline"
  mini-group, that is a cosmetic, reversible follow-up. Adopted as-is per PM acceptance.

## 12. Partition assignment

N/A — single Developer mode. There are no `.harness/agents/dev-*.md` files in this repo (verified: `.harness/agents/`
holds partition `dev-*` agents only and is empty here; framework agents are plugin-native). The generic
`harness-kit:developer` implements all three families (A new skill, B agent-rule edit, C fan-out).

## 13. Verdict

**READY for Gate Review.**

The design is complete enough to implement without further design decisions: the new SKILL.md content is fully
specified (description, when-NOT delta vs all three siblings, interview engine, CONTEXT.md SOFT composition,
brief emission with slug/collision/early-end/empty-answer handling, anti-patterns, user-invoked posture); the
strip-list collision is reconciled with exact wording at the exact line sites (§4); the 15→16 fan-out ledger is
exhaustive and live-grep-backed (§6: 22 doc sites + 12 verify_all sites across 13 files, with the gating column
and the DO-NOT-TOUCH decoys named); install parity is confirmed (both shells directory-derived — no edit
needed, soft help-text flagged); the version is 0.35.0 with G.3 stamp targets + the G.4 CHANGELOG heading
named; check count stays 32 (no new check); and the mechanical items (i)–(iv) are all resolved (loops are
name-array NOT directory-derived — corrected; plugin skills bind from top-level `skills/` only, no sync; the
exact reconciling wording; both install shells directory-derived). Carries the 5 PM-accepted RA defaults. CR/QA
have explicit grep duties for R1/R3 and the decoy-confirmation.
