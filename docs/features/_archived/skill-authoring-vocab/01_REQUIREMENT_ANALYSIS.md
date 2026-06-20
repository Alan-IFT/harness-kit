# 01 — Requirement Analysis · T-04 `skill-authoring-vocab`

**Mode:** full · **Stage:** 1 (Requirement Analyst) · **deferred-human:** defer, do not ask
**Verdict:** `READY` (see §9)

## 1. Goal

Additively enrich the dogfood rule `.harness/rules/15-skill-authoring.md` with a high-value named subset of the skill-design vocabulary from mattpocock/skills `writing-great-skills`, mapping each new term onto the rule's existing eight principles or mechanisms where one exists, without rewriting or renumbering those eight principles.

## 2. In-scope behaviors (numbered, testable)

The single deliverable is an edited `.harness/rules/15-skill-authoring.md`. After the edit:

1. The file introduces the named concept **leading word** (a.k.a. *Leitwort*), defined as a compact pretrained concept the model thinks with, and states it generalizes the existing P1 idea "write the description for the model."
2. The file introduces the named concept **completion criterion** with both of its axes named: **checkable** (clear: agent can tell done from not-done) and **exhaustive** (demanding: "every X accounted for", not "produce a list").
3. The file introduces the named failure mode **premature completion**, defined as ending a step before it is genuinely done, and names its defence order: sharpen the completion criterion first; hide post-completion steps (split the sequence) only if the criterion is irreducibly fuzzy and the rush is observed.
4. The file introduces the **no-op test** ("does this line change behavior versus the model's default?") and states it formalizes / is the named handle for the existing P2 "don't state the obvious."
5. The file introduces the paired pruning failure modes **sediment** (stale layers never cleared) and **sprawl** (length itself, even when every line is live and unique), and states a pruning discipline that ties to the existing P5 / `70-doc-size.md` cap (and which this very rule is bound by — the ≤200-line cap).
6. The file introduces **single source of truth** (each meaning lives in exactly one authoritative place) and names **duplication** as its violation, connecting to the repo's existing "delete duplication rather than guard it" anti-bloat line.
7. The file introduces the **user-invoked vs model-invoked** lens, including the cost pair **context load** (the per-turn cost a model-invoked `description:` imposes) vs **cognitive load** (the cost a user-invoked skill imposes on the human-as-index), framed as the choice "keep the `description:` (model-invoked, reachable by other skills, pays context load) vs strip it (user-invoked, zero context load)."
8. Each concept in items 1-7 that maps to an existing principle is explicitly cross-referenced to that principle by its existing number (no-op test → P2; leading word → P1; sediment/sprawl pruning → P5/P2; single source of truth → the anti-bloat line / "Deliberately not adopted") or marked as genuinely new (completion criterion, premature completion, context-load/cognitive-load lens) where no existing handle exists.
9. The file's existing eight principles (P1-P8) remain present, retain their numbers, and retain their existing meaning (additive only — no rewrite, no renumber, no deletion of P1-P8 content).
10. The file credits the source mattpocock/skills `writing-great-skills` (a one-line attribution; the existing "Distilled from Anthropic's..." provenance line is extended or a sibling line is added — the new vocabulary's origin is named).
11. The file remains ≤200 physical lines (verify_all I.2 cap; currently ~81 lines).
12. The file introduces no text that trips the verify_all I.6 retired-claim guard (no banned anchor sequence written in scanned prose).

## 3. Out-of-scope (explicitly NOT this iteration)

1. Rewriting, renumbering, reordering, or deleting any of the existing eight principles P1-P8.
2. Importing the full ~18-term glossary verbatim. Excluded terms (low marginal value given existing coverage or token economy): predictability, description, context pointer, granularity, router skill, information hierarchy, co-location, branch, progressive disclosure (already P5), steps, post-completion steps (named only inside the premature-completion defence, not as a standalone heading), legwork, reference, external reference, relevance. These may be *named in passing* inside another concept's definition but earn no standalone treatment.
3. Any change to a distributed/template asset (`templates/`), any `plugin.json` version bump, any README / CHANGELOG / skill-count edit, any new verify_all check, any harness-sync run. (See §7 confirmation — this file is dogfood-only.)
4. Any change to `AI-GUIDE.md`'s index line for this rule (it already describes the rule adequately; the trigger and one-line summary do not require editing for an additive vocabulary enrichment — Architect may revisit, but it is not required by this requirement).
5. Editing `CONTRIBUTING.md` (the mechanical checklist the rule points at).
6. Authoring or changing any actual skill / agent file (this task edits the *rule about* authoring, not any authored asset).

## 4. Boundary conditions

- **Line cap (max size):** final file ≤200 lines (verify_all I.2). Currently ~81. Budget headroom ~119 lines; the additions are token-economical — the rule preaches anti-bloat, so it practices it (terse named handles, not full glossary prose).
- **Empty/null:** not applicable (no runtime input; this is a static doc edit).
- **Existing-content preservation:** P1-P8 text, the "When to read" block, "Deliberately not adopted", and "Adversarial check" sections are preserved; any net-new text is additive (new section(s) and/or additive clauses appended to existing principle bodies).
- **I.6 guard (error path):** the new prose contains no banned retired-claim anchor sequence (insight 2026-06-08 — a doc that writes the literal banned anchor self-trips I.6). Concretely: avoid writing the literal retired blunt-Chinese policy phrasing or any other I.6 banned ordered-anchor token run in scanned prose.
- **Encoding:** if any non-ASCII (CJK or em-dash) is added, the file stays UTF-8 (the repo convention; I.6 scans UTF-8/UTF-16 cleanly only for correctly-encoded files).
- **Concurrency:** not applicable (single static file, no runtime concurrency).
- **Cross-reference integrity:** every "→ Px" mapping the new text asserts must point at a principle number that still exists and still means what the cross-reference claims (P1-P8 unchanged, so this holds by construction once §2.9 is satisfied).

## 5. Acceptance criteria (each verifiable)

| # | Criterion | How verified |
|---|---|---|
| AC-1 | The file names all seven required concepts: **leading word**, **completion criterion** (checkable + exhaustive), **premature completion**, **no-op test**, **sediment** + **sprawl**, **single source of truth**, **user-invoked vs model-invoked** (with context load vs cognitive load). | grep each named term in the edited file; all present. |
| AC-2 | `no-op test` is explicitly tied to existing **P2**, and `leading word` is explicitly tied to / generalizes existing **P1**. | Read the new text; the P2/P1 cross-reference is literally present. |
| AC-3 | `sediment`/`sprawl` pruning is tied to existing **P5** and/or `70-doc-size.md`; `single source of truth` is tied to the existing anti-bloat / "Deliberately not adopted" stance. | Read the new text; the cross-reference is present. |
| AC-4 | Genuinely-new concepts with no prior handle (**completion criterion**, **premature completion**, **context-load/cognitive-load lens**) are present and are NOT falsely claimed to map to an existing principle. | Read the new text; no false-mapping claim. |
| AC-5 | All eight existing principles P1-P8 are present, numbered 1-8, with their original meaning intact (additive only). | Diff against current file: P1-P8 lines unchanged or only additively extended; no deletion, no renumber. |
| AC-6 | The source mattpocock/skills `writing-great-skills` is credited (one-line attribution). | grep for the attribution; present. |
| AC-7 | Final file ≤200 lines. | `verify_all` I.2 PASSes (no new WARN/FAIL for this file); or `(Get-Content file).Count -le 200`. |
| AC-8 | `verify_all` is green at the gate with no new FAIL and no new WARN attributable to this edit (specifically I.2 and I.6). | Run `.harness/scripts/verify_all`; compare check tally to pre-edit baseline. |
| AC-9 | No fan-out artifact changed: `plugin.json` version, README, CHANGELOG, skill-count claims, and `templates/` are byte-untouched by this task. | `git status` / `git diff --name-only` shows only `.harness/rules/15-skill-authoring.md` (plus the `docs/features/skill-authoring-vocab/` stage docs). |

## 6. Non-functional requirements

- **Token economy (material):** the additions must be terse named-handle prose, not transplanted glossary essays. The rule itself is the canonical anti-bloat / no-op / sprawl authority in this repo, so verbose additions would be self-contradicting. Target: the new material costs the minimum lines that still defines each handle and its mapping. (This is a real constraint, not boilerplate — it is the I.2 cap plus the rule's own thesis.)
- **Provenance honesty:** credit is to mattpocock/skills `writing-great-skills`; the existing Anthropic "how we use skills" provenance is preserved (both sources coexist — do not overwrite the Anthropic line).
- No performance, security, or compatibility NFRs apply (static dogfood doc, not shipped, not executed).

## 7. Related tasks & confirmation

- **T-04 is idea ③ of the mattpocock/skills adoption batch.** Siblings:
  - **T-03 `harness-grill`** (`docs/features/_archived/harness-grill/`) — idea ②. Established the standing requirement-analyst rule "recommend an answer per Open Question" (applied in §9 below).
  - **T-02 `context-glossary`** (`docs/features/_archived/context-glossary/`) — idea ①. Established the `CONTEXT.md` domain-glossary layer and the dogfood-vs-template "dual-purpose / not byte-synced" pattern; reinforced [[feedback_design_over_guards]] (no new verify_all check unless a hazard demands it — honored here: this task adds no check).
- **The file under edit:** `c:\Programs\HarnessEngineering\.harness\rules\15-skill-authoring.md` (live, ~81 lines).
- **Source (read-only):** `c:\Programs\_research\mattpocock-skills\skills\productivity\writing-great-skills\{SKILL.md,GLOSSARY.md}`.

**Dogfood-only / no-fan-out confirmation (verified against the live repo):**
- `Glob **/15-skill-authoring.md*` returns exactly one hit: `.harness\rules\15-skill-authoring.md`. There is **no** copy under `templates/`. → It is NOT distributed.
- `AI-GUIDE.md` confirms (a) rules are *referenced, not composed* — "No sync needed. AI tools follow the reference" (line 106); (b) `sync-self` "does NOT sync `.harness/rules/` — those are bespoke per repo" (line 75).
- INPUT.md insight (line 28) asserts the same and is now confirmed true.
- **Conclusion:** editing this file triggers **no** version bump, **no** README/CHANGELOG/skill-count fan-out, **no** `plugin.json` change, **no** harness-sync. Scope is the single rule file. (If the Architect later finds a hidden distributed copy, that re-opens scope — but the live tree shows none.)

## 8. Open questions for user

All deferred (deferred-human mode: each has ≥2 candidates + a recommended answer; none blocks — recommendations are safe additive choices).

**OQ-1 — Structural placement of the new vocabulary.**
(a) Append a single new section "Named vocabulary (mattpocock/skills)" after "The principles", each term a one-line bullet with its `→ Px` mapping.
(b) Weave each new term into the body of the existing principle it maps to (e.g. add "(the *no-op test*)" inside P2), and add a small new section only for the genuinely-new terms.
(c) A short glossary-style table (term · one-line def · maps to).
*Recommended:* **(a)** — a single additive section is the lowest-risk way to keep P1-P8 byte-stable (satisfies AC-5 by construction) while concentrating the new handles in one co-located block, and it is the most token-economical.

**OQ-2 — Whether to also name the "router skill / user-invoked-multiplied" cure.**
(a) Include only the seven required concepts (router skill stays out per §3.2).
(b) Add a one-clause mention of **router skill** as the cure when user-invoked skills multiply, since it rides for nearly free on the user-vs-model lens already being added.
*Recommended:* **(a)** — keep to the named seven for token economy; router skill is explicitly out-of-scope and the repo currently has no proliferation of user-invoked skills to cure, so it would be a no-op addition by the rule's own test.

**OQ-3 — Depth of the context-load vs cognitive-load lens.**
(a) One sentence naming the pair and the keep-vs-strip-`description:` tradeoff.
(b) A short paragraph also covering granularity (when to split a skill, which load each split spends).
*Recommended:* **(a)** — granularity is out-of-scope (§3.2) and the one-sentence framing is enough to give the named handle; the deeper split-economics belong to the source glossary the credit line points readers to.

## 9. Verdict

`READY`.

Rationale: scope is a single additive edit to a confirmed dogfood-only file with no fan-out; the seven required named concepts and their mappings are fully enumerated and testable; the three open questions are presentation/depth choices, each with a safe recommended answer that the downstream pipeline can proceed on without user input (per deferred-human mode and the T-03 standing recommend-an-answer rule). No ambiguity blocks design or implementation.
