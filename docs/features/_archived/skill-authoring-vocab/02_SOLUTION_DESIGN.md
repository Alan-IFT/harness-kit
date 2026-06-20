# 02 — Solution Design · T-04 `skill-authoring-vocab`

**Mode:** full · **Stage:** 2 (Solution Architect) · **deferred-human:** defer, do not ask
**Upstream:** `01_REQUIREMENT_ANALYSIS.md` verdict `READY` (§9) — design proceeds on it.
**Verdict:** `READY` (see §12)

PM accepted the RA's recommended OQ defaults: **OQ-1 (a)** single appended section, **OQ-2 (a)** seven concepts only (no router skill), **OQ-3 (a)** one-sentence load lens. This design is built on those three.

## 1. Architecture summary

This is a **single-file, additive documentation edit** with no code, schema, API, or runtime surface. One new section is appended to `.harness/rules/15-skill-authoring.md` — a compact "Named vocabulary" block of terse handles distilled from mattpocock/skills `writing-great-skills`, each cross-referenced to the rule's existing principles P1–P8 where a handle already exists, or marked genuinely new where none does. The existing eight principles and all other sections stay byte-stable. System-level change: the dogfood skill-authoring rule gains crisper named handles; nothing it indexes, syncs to, or is referenced by changes.

## 2. Affected modules

| File | Role | Change |
|---|---|---|
| `c:\Programs\HarnessEngineering\.harness\rules\15-skill-authoring.md` | the dogfood skill-authoring quality-bar rule (live, ~81 lines) | **edit** — append one section + extend the provenance line |

No other file is touched. Confirmed against the live tree (RA §7 dogfood-only audit, re-verified below in §9).

## 3. Module decomposition

Not applicable — no new module, no new public API, no new symbol. The deliverable is prose inside an existing markdown rule fragment.

## 4. Data model changes

None. Static doc; no schema, no table, no migration.

## 5. API contracts

None. No request/response surface.

## 6. Sequence / flow

No runtime flow changes. The only "flow" is consumption-time: when an author triggers `15-skill-authoring.md` (per AI-GUIDE.md line 25 trigger "when authoring or changing a skill or agent"), they now also read the appended named-vocabulary handles after the eight principles. Progressive-disclosure order is preserved: identity → when-to-read → P1–P8 → (new) Named vocabulary → Deliberately not adopted → Adversarial check.

## 7. The exact edit (implementation contract)

The Developer makes **two** additive changes to `c:\Programs\HarnessEngineering\.harness\rules\15-skill-authoring.md`. Both are additive; no P1–P8 line is rewritten, renumbered, reordered, or deleted.

### 7a. Extend the provenance line (credit the source — AC-6)

The existing provenance sentence (current lines 6–10, the "Distilled from Anthropic's …" paragraph) keeps the Anthropic attribution intact (NFR provenance-honesty: both sources coexist). Append one sibling sentence to that same paragraph, immediately after the existing sentence that ends `… and mapped onto the mechanisms this repo already has.`:

> The named vocabulary in "Named vocabulary" below is distilled from mattpocock/skills `writing-great-skills` (its `GLOSSARY.md`).

This is the one-line attribution. Do not overwrite the Anthropic line.

### 7b. Append the new section

Insert a new `##` section **between** the existing `## The principles …` block (ends at current line 62, after P8) and the existing `## Deliberately not adopted` block (current line 64). Exact content to write:

```markdown
## Named vocabulary (mattpocock/skills)

Crisp handles for the ideas above — reuse these as the canonical words when reviewing a
skill. Each maps to an existing principle, or is marked **new** where this rule had no handle.

- **Leading word** (a.k.a. *Leitwort*) — a compact pretrained concept the model thinks *with*
  while running the skill; repeated as a token (never a sentence) it anchors a region of
  behaviour for the fewest tokens. Generalizes **P1** ("write for the model"): word the
  `description:` and the body with the leading words you actually type when you want the skill.
- **No-op test** — "does this line change behaviour versus the model's default?" If not, it is
  a no-op: you pay load to say what the model already does. The named handle for **P2** ("don't
  state the obvious"); it is also how you grade whether a leading word still beats the default.
- **Completion criterion** *(new — no prior handle)* — the bar that tells the agent a unit of
  work is done, on two axes: **checkable** (clear — can it tell done from not-done?) and
  **exhaustive** (demanding — "every X accounted for", not "produce a list"). The strongest
  criteria are both.
- **Premature completion** *(new — no prior handle)* — ending a step before it is genuinely
  done, attention slipping to *being* done. Defence, in order: **sharpen the criterion first**
  (local, cheap); only if it is irreducibly fuzzy *and* you observe the rush, **hide the later
  steps** by splitting the sequence across a real context boundary.
- **Sediment / sprawl** — the two length faults this rule's anti-bloat stance prunes against:
  **sediment** is stale layers never cleared (adding feels safe, removing feels risky);
  **sprawl** is length itself even when every line is live and unique. Cure both via the **P5**
  progressive-disclosure ladder and the `70-doc-size.md` cap — the ≤200-line cap this very file
  is held to.
- **Single source of truth** — each meaning lives in exactly one authoritative place; its
  violation is **duplication**. This is the repo's existing anti-bloat stance ("delete
  duplication rather than guard it", see "Deliberately not adopted") given its name.
- **User-invoked vs model-invoked** *(new lens)* — keep the `description:` and the skill is
  model-invoked (agent-discoverable, reachable by other skills, pays a per-turn **context
  load**); strip it and it is user-invoked (zero context load, but spends the human's
  **cognitive load** — they become the index of which skill to reach for).
```

### 7c. Line budget (AC-7 — hard constraint ≤200)

| Component | Lines added |
|---|---|
| 7a provenance sibling sentence (joined into existing paragraph) | +1 |
| 7b heading + intro (`## …`, blank, 2 intro lines, blank) | +5 |
| 7b seven bullets (avg ~3 wrapped lines each, per wording above) | +21 |
| trailing blank before `## Deliberately not adopted` | +1 (already present; reused) |

**Projected final line count: ~81 + 27 ≈ 108 lines.** Headroom to the 200-line cap: ~92 lines. Well under. (Developer may reflow bullets; the contract is "all seven handles present, terse, mapped" — exact wrap is free as long as the file stays ≤200.)

## 8. Reuse audit

| Need | Existing code/idiom | File path | Decision |
|---|---|---|---|
| "Write for the model" handle | P1 | `.harness/rules/15-skill-authoring.md:23-27` | Reuse — `leading word` cross-references / generalizes P1 (AC-2) |
| "Don't state the obvious" handle | P2 | `.harness/rules/15-skill-authoring.md:29-31` | Reuse — `no-op test` is the named handle for P2 (AC-2) |
| Length/bloat discipline | P5 progressive disclosure | `.harness/rules/15-skill-authoring.md:44-49` | Reuse — `sediment`/`sprawl` pruning ties to P5 (AC-3) |
| Doc-size cap authority | `70-doc-size.md` 200-line rule-fragment cap | `.harness/rules/70-doc-size.md:25` | Reuse — `sprawl` cure cites the cap this file lives under (AC-3) |
| Anti-duplication stance | "delete duplication rather than guard it" | `.harness/rules/15-skill-authoring.md:64-71` ("Deliberately not adopted") | Reuse — `single source of truth` names that existing stance (AC-3) |
| Provenance pattern | "Distilled from Anthropic's …" line | `.harness/rules/15-skill-authoring.md:6-10` | Extend — add mattpocock sibling sentence, preserve Anthropic (AC-6) |
| Source definitions | the full 18-term glossary | `c:\Programs\_research\mattpocock-skills\skills\productivity\writing-great-skills\GLOSSARY.md` | Read-only source — distill the high-value 7, do not transplant verbatim (NFR token economy) |
| Section ordering convention | identity → when-to-read → principles → not-adopted → adversarial | `.harness/rules/15-skill-authoring.md` (whole) | Reuse — insert new section between principles and "Deliberately not adopted" |
| New-handle prose for `completion criterion` / `premature completion` / load-lens | (none — no prior handle in this repo) | — | New text justified: RA §2 items 2,3,7 require these genuinely-new handles; no existing idiom covers them (AC-4) |

The reuse audit is non-empty and dominant: 6 of 7 handles map to existing principles or stances; only 3 concepts (completion criterion, premature completion, context/cognitive-load lens) are genuinely new — and those are correctly NOT claimed to map to an existing principle (AC-4).

## 9. Risk analysis

| # | Risk | Likelihood | Mitigation |
|---|---|---|---|
| R-1 | New prose accidentally trips the verify_all **I.6** retired-claim guard (a banned ordered-anchor run in scanned prose self-trips — insight 2026-06-08, T-013). | Low | Verified the live banned list (`verify_all.ps1:486-501`): all 14 anchors concern `harness-sync`/`CLAUDE.md` composition·regeneration, `scaffolding-only`, and `全程中文`. The designed vocabulary wording (§7) touches **none** of those token sequences. Developer must not introduce any of those literals; QA confirms via a clean `verify_all` I.6. |
| R-2 | Edit drifts a P1–P8 line (rewrite/renumber/reorder), breaking AC-5 and every `→ Px` cross-reference the new text asserts. | Low–Med | Edit is **append-only** between two stable section boundaries plus one sibling sentence into the provenance paragraph; no P1–P8 body is the edit target. QA: `git diff` must show P1–P8 lines unchanged (byte-stable), only additive hunks. |
| R-3 | Additions bloat the file past the **I.2/200-line** cap, or are verbose enough to be self-contradicting (the rule preaches anti-bloat). | Low | Budget is explicit (§7c): ~108 projected vs 200 cap. Wording is terse named-handle prose, 1–3 lines per handle (the rule's own thesis applied to itself). QA: `(Get-Content file).Count -le 200`. |
| R-4 | A genuinely-new concept is falsely cross-referenced to an existing principle (violates AC-4), or a required concept/axis is omitted (violates AC-1). | Low | §7b marks the three new concepts `*(new …)*` explicitly and supplies the checkable+exhaustive axes inline; AC-1 lists every required term for a post-edit grep. |
| R-5 | A hidden distributed copy of the file under `templates/` exists, re-opening fan-out scope (version bump / README / CHANGELOG / skill-count). | Very Low | RA §7 audit (`Glob **/15-skill-authoring.md*` → one hit) re-confirmed: AI-GUIDE.md:75 states `sync-self` does NOT sync `.harness/rules/`; line 106 states rules are referenced not composed. No `templates/` copy. Dogfood-only stands (§11). |

## 10. Migration / rollout plan

Not applicable. No data, no API shape, no feature flag, no backward-compatibility surface. This is a static doc edit consumed by reference (AI-GUIDE.md:106 — "No sync needed"). Rollback = `git revert` of the single hunk. No migration steps.

## 11. Out-of-scope clarifications (design boundaries)

This design does NOT cover, and the Developer must NOT do, any of:

1. Rewriting, renumbering, reordering, or deleting any of P1–P8 (RA §3.1).
2. Importing the full ~18-term glossary; the excluded terms (predictability, description, context pointer, granularity, **router skill**, information hierarchy, co-location, branch, progressive-disclosure-as-its-own-term, steps, post-completion-steps-as-a-heading, legwork, reference, external reference, relevance) get **no standalone heading** — they may only be named in passing inside a kept handle's body (RA §3.2; OQ-2 (a) confirms router skill stays out).
3. Any `plugin.json` version bump, README / CHANGELOG / skill-count edit, or `templates/` change (RA §3.3 — see §11-confirmations below).
4. Any new `verify_all` check (honors [[feedback_design_over_guards]] — no guard accreted; RA §7 T-02 precedent).
5. Any `harness-sync` / `sync-self` run (rules are referenced, not synced — AI-GUIDE.md:75,106).
6. Editing `AI-GUIDE.md`'s index line for this rule (RA §3.4 — its trigger/summary already describe the rule adequately for an additive vocabulary enrichment).
7. Editing `CONTRIBUTING.md` (RA §3.5) or authoring/changing any actual skill or agent file (RA §3.6).
8. Deepening the load lens beyond one sentence (OQ-3 (a) — granularity/split-economics belong to the source glossary the credit line points at).

### §11 confirmations (explicitly requested)

- **No version bump** — confirmed. Editing a `.harness/rules/*.md` fragment changes no count/version claim; the count-ledger version-bump rule (insights T-008/T-018/T-03) applies only to skill-count / check-count claims, none of which this edit touches.
- **No fan-out** — confirmed. `git diff --name-only` after this task must show only `.harness/rules/15-skill-authoring.md` plus the `docs/features/skill-authoring-vocab/` stage docs (AC-9). The skill-count decoy set (insight 2026-06-19) is untouched.
- **No new check** — confirmed. The 32-check `verify_all` tally is unchanged; this design adds zero gates.
- **No harness-sync** — confirmed. `.harness/rules/` is bespoke per repo and not in any sync mirror set (AI-GUIDE.md:75).
- **Dogfood-only** — confirmed. No `templates/` copy exists; the file is consumed by reference.

## 12. Partition assignment

Not applicable — no `.harness/agents/dev-*.md` partition agents exist in this repo (`Glob .harness/agents/dev-*.md` → no files; AI-GUIDE.md:15 confirms `.harness/agents/` is empty here). Single-Developer mode. The one affected file is owned by the single Developer.

## 13. Verdict

`READY`.

Rationale: the requirement is `READY` and fully enumerated; the deliverable is a single additive edit to one confirmed dogfood-only file, specified to the exact wording and insertion point (§7), with a budgeted line count (~108 ≤ 200), a non-empty reuse audit proving 6 of 7 handles map to existing principles, three named risks each with a concrete mitigation, and explicit confirmation of no-fan-out / no-new-check / no-version-bump / no-harness-sync. A developer can implement this without further design decisions.
