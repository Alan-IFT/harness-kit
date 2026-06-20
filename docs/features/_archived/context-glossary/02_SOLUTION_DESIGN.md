# 02 — Solution Design · context-glossary (T-02)

**Mode:** full · **Stage:** 2 (Solution Architect) · **Date:** 2026-06-19
**Upstream verdict:** `01_REQUIREMENT_ANALYSIS.md` = **READY** (13 in-scope behaviors, 10 ACs; all 5 OQs answered with PM-accepted defaults).
**Decision mode:** Mode 2 · **deferred-human:** defer-with-recommendation, do not ask.

All paths in this doc are absolute (plan-mode handoff discipline). This is a pure docs+template+agent-prose+index task — no runtime code, no new dependency, no new `verify_all` check, no new template placeholder.

---

## 1. Architecture summary

harness-kit gains a **domain-glossary memory layer** (`CONTEXT.md`: tight single-sentence-or-two definitions, each with an `_Avoid_:` synonym list, project-specific terms only). It is added in two intentionally-non-byte-synced copies — a **real dogfood file at the repo root** (`c:\Programs\HarnessEngineering\CONTEXT.md`, seeded with this repo's genuine vocabulary) and a **generic, placeholder-free template seed** under `skills\harness-init\templates\common\CONTEXT.md` so every `/harness-init` project receives a starter glossary at its own root. The glossary is wired into the `requirement-analyst` and `solution-architect` agent contracts as a **SOFT dependency** (read-if-present for canonical naming + lazy-maintain inline + graceful degradation when absent — no setup pointer, no `BLOCKED`-on-absent), indexed once in the AI-GUIDE.md **Memory layer**, and recorded in `docs/dev-map.md`. This is the exact dual-purpose pattern already proven by `.harness/decision-rubric.md` (generic in the template, operator-real in the dogfood; `sync-self` mirrors neither — it touches only the 7 script pairs). No `verify_all` guard is added (check count stays **32**); a minor version bump (**v0.34.0**) stamps the user-visible change to generated-project output.

---

## 2. Affected modules (file paths)

**New files (2):**
- `c:\Programs\HarnessEngineering\CONTEXT.md` — repo-root dogfood glossary (real harness-kit terms).
- `c:\Programs\HarnessEngineering\skills\harness-init\templates\common\CONTEXT.md` — generic template seed (skeleton; placeholder-free; lands at each generated project's root).

**Edited files (8):**
- `c:\Programs\HarnessEngineering\agents\requirement-analyst.md` — add SOFT-dependency reference (currently 74 lines; cap 300).
- `c:\Programs\HarnessEngineering\agents\solution-architect.md` — add analogous SOFT-dependency reference (currently 122 lines; cap 300).
- `c:\Programs\HarnessEngineering\AI-GUIDE.md` — one new Memory-layer index line (currently 109 lines; cap 200 — I.1).
- `c:\Programs\HarnessEngineering\docs\dev-map.md` — one location-table row + tree note.
- `c:\Programs\HarnessEngineering\.harness\scripts\test-init.ps1` — add a seed-present + placeholder-free assertion (count moves).
- `c:\Programs\HarnessEngineering\.harness\scripts\test-init.sh` — symmetric assertion (count moves).
- `c:\Programs\HarnessEngineering\.claude-plugin\plugin.json` — version `0.33.0` → `0.34.0` (G.3-gated).
- `c:\Programs\HarnessEngineering\.claude-plugin\marketplace.json` — version `0.33.0` → `0.34.0` (G.3-gated).
- `c:\Programs\HarnessEngineering\README.md` — version badge `0.33.0` → `0.34.0` (G.3-gated).
- `c:\Programs\HarnessEngineering\README.zh-CN.md` — version badge `0.33.0` → `0.34.0` (G.3-gated).
- `c:\Programs\HarnessEngineering\CHANGELOG.md` — new `[0.34.0]` heading (G.4-gated: the heading must exist).
- `c:\Programs\HarnessEngineering\.harness\scripts\baseline.json` — reconcile `test_init_ps_assertions` + `test_init_bash_no_python3_assertions` from a captured run (tracking field; NOT gated).

> Edited-file count varies with the version-stamp fan-out (README ×2, plugin.json, marketplace.json, CHANGELOG are the standard G.3/G.4 set). They are bundled under §5 (version stamp) and §9 (rollout). `test-real-project` baseline keys are addressed in §6.

---

## 3. Module decomposition

This task adds **content artifacts**, not code modules — so "public API" here = the file's structure/contract that downstream consumers (the two agents, AI-GUIDE, init) rely on.

### 3.1 Dogfood `CONTEXT.md` (repo root)

**Responsibility:** the canonical glossary of harness-kit's own single-context domain vocabulary; the file the RA/SA read when working *in this repo* and lazily extend.

**Structure (contract — follows `c:\Programs\_research\mattpocock-skills\skills\engineering\domain-modeling\CONTEXT-FORMAT.md` exactly):**

```md
# Harness Kit

Harness Kit is a Claude Code plugin that ships a 7-agent AI-development pipeline and
project templates. This glossary pins the project's own domain terms so the pipeline
names files, symbols, and stage docs consistently. (Single context; if the repo ever
splits into multiple bounded contexts, a root CONTEXT-MAP.md would index them — not
needed today.)

## Language

**Frontier**:
{1-2 sentence definition}
_Avoid_: {synonyms not to use}

**Pool** (living pool):
{def}
_Avoid_: {…}

**Ambient**:
{def}
_Avoid_: {…}

… (≥3 terms total to satisfy AC-1; canonical candidate set in behavior 3:
frontier, pool, ambient, partition agent (dev-*), stage doc, verdict, insight,
rollback, dogfood, template overlay, soft vs hard dependency)
```

**Authoring constraints the developer MUST honor (design, not content):**
- Opens with a `#` context title (`# Harness Kit`) + 1-2 sentence context description (AC-1).
- `## Language` subheading, then term entries (a flat list is acceptable per CONTEXT-FORMAT "Rules"; group under sub-subheadings only if natural clusters emerge).
- **≥3** term entries (AC-1), each = a **bold term** + 1-2 sentence definition + an `_Avoid_:` line (AC-1, AC-2). The single-context future sentence (OQ-5) is the parenthetical in the context description above — costs one clause, no extra section.
- Terms drawn ONLY from the behavior-3 candidate set (harness-kit-specific; AC-2). The exact subset + the `_Avoid_` synonyms are **content authoring** — the developer picks them; this design does not pre-pick wording (per behavior 3, RA explicitly defers it).
- **No implementation detail** (behavior 4): definitions say what a term *is*, never "how it works", never a file path as the definition. (E.g. *frontier* = "the set of tasks currently runnable…", NOT "the rows in BATCH_PLAN.md whose Depends-on are satisfied, computed by step g".)
- **No I.6 banned-anchor phrase** (boundary 5 / AC-10): the root `CONTEXT.md` is in a non-exempt location and IS I.6-scanned. The 14 live banned anchors (`verify_all.{ps1,sh}` I.6 block) concern retired architectural claims (agent-copy, version claims, blunt-language) — none concern glossaries/domain-terms — so this is a "do not author one in" constraint, low collision risk. Definitions of *rollback*, *verdict*, *insight*, *partition agent* must be phrased without reproducing a banned ordered-anchor sequence.

### 3.2 Template seed `CONTEXT.md` (`templates\common\`)

**Responsibility:** the starter glossary every generated project receives at its root, instructing the project to add its own terms — GENERIC, not a copy of §3.1.

**Structure (contract):**

```md
# {Your Project} Domain Glossary

One or two sentences describing this project's domain. Replace this line, then add
your project's domain terms below — one bold term, a tight 1-2 sentence definition,
and an _Avoid_ line of synonyms not to use. Keep it to terms specific to THIS
project (not general programming concepts). Single context; if you grow multiple
bounded contexts, index them from a root CONTEXT-MAP.md.

## Language

**ExampleTerm**:
A one-or-two-sentence definition of what this term IS in your domain.
_Avoid_: synonym-you-do-not-want, another-synonym
```

**Authoring constraints (design):**
- **Zero `{{PLACEHOLDER}}` tokens** (behavior 7, boundary 4, AC-3): the seed is a `.md` and IS in scope of `test-init`'s recursive `\{\{[A-Z_]+\}\}` scan (`test-init.ps1:269-279`, `.sh` twin). Use prose like `{Your Project}` with **single** braces and lowercase words — the scan matches only DOUBLE-brace UPPER_SNAKE (`\{\{[A-Z_]+\}\}`), so `{Your Project}` is safe. Do **not** add any new placeholder to the D.2 whitelist (behavior 7 / out-of-scope 7).
- **Generic** (behavior 6, AC-3): the seed carries an `ExampleTerm` skeleton, not this repo's real terms. It MUST differ from §3.1 (AC-3 `diff`). `sync-self` does NOT mirror it (it mirrors only the 7 script pairs — `CONTEXT.md` is not a script pair), so the two copies legitimately diverge, exactly like `decision-rubric.md` (dogfood `c:\Programs\HarnessEngineering\.harness\decision-rubric.md` vs template `…\templates\common\.harness\decision-rubric.md` already differ today).
- **Must NOT trip a `.tmpl` rule:** name it `CONTEXT.md`, NOT `CONTEXT.md.tmpl` — it has no placeholders to substitute, so it ships verbatim (like `templates\common\.harness\rules\60-tool-handoff.md` and `…\decision-rubric.md`, which are non-`.tmpl` verbatim assets). The "no .tmpl leaked" scan (`test-init.ps1:280-283`) is satisfied because there is no `.tmpl` to leak.
- **No I.6 banned anchor** (AC-10): the seed text is generic example prose; trivially safe.

### 3.3 SOFT-dependency wiring — the agent prose

**Responsibility:** make the RA and SA *use* `CONTEXT.md` for canonical naming and *lazily maintain* it, while degrading gracefully when it is absent (boundary 1, AC-4/AC-5). Implements the soft-vs-hard split from `c:\Programs\_research\mattpocock-skills\docs\adr\0001-explicit-setup-pointer-only-for-hard-dependencies.md`: SOFT deps get vague-prose reference + graceful degradation, NO setup pointer.

**Exact prose to add (OQ-4 = minimal/token-light; this is the contract — paste verbatim, adjust only whitespace).**

For `c:\Programs\HarnessEngineering\agents\requirement-analyst.md` — append as a new item in the **Workflow** list (after current step 6 "Read `docs/spec/`…", renumbering the rest), so it sits among the read-inputs and stays within the agent's purpose density:

> N. If a project glossary (`CONTEXT.md`, usually at repo root) is present, skim it and use its canonical terms when naming things in the requirement doc; if you coin or sharpen a domain term while writing, record it there inline (bold term + 1-2 sentence definition + `_Avoid_:` synonyms). If there is no `CONTEXT.md`, just proceed — it is a convenience, never a precondition.

For `c:\Programs\HarnessEngineering\agents\solution-architect.md` — append as a new item in the **Workflow** list (after current step 4 "Read `docs/dev-map.md`…", renumbering the rest):

> N. If a project glossary (`CONTEXT.md`, usually at repo root) is present, read it and use its canonical names for new modules / files / symbols; if you introduce or sharpen a domain term in the design, record it there inline (bold term + 1-2 sentence definition + `_Avoid_:` synonyms). If there is no `CONTEXT.md`, just proceed — it never blocks the design.

**Why this exact wording (boundary 1, AC-4/AC-5, OQ-4):**
- "if present / usually at repo root" = read-if-present, vague-prose location (no hard "run X first" / no `/setup` pointer → honors ADR-0001 SOFT discipline and behavior 10).
- "record it there inline" = lazy-maintain (behaviors 8-9); references the §3.1 format so the maintained entry stays well-formed.
- "just proceed — it is a convenience, never a precondition / it never blocks the design" = explicit graceful-degradation clause + explicit no-`BLOCKED`-on-absent (boundary 1, AC-4/AC-5, behavior 10).
- One sentence each (OQ-4 = minimal). RA goes from 74 → ~75 lines, SA from 122 → ~123 lines — both far under the 300-line cap (boundary 6).
- Placed inside the existing **Workflow** numbered list rather than as a new `##` section: keeps token cost to one line, avoids a new heading, and lands the instruction exactly where the agent reads its other inputs. The fuller maintenance discipline (challenge / cross-reference / scenario-stress) from `…\domain-modeling\SKILL.md` is deliberately NOT imported (out-of-scope item 3; deferred to a possible future skill).

### 3.4 AI-GUIDE.md Memory-layer index line

**Responsibility:** one index entry so any tool discovers the glossary (behavior 11, AC-6).

**Exact line to add** under the **Memory layer** bullet list in `c:\Programs\HarnessEngineering\AI-GUIDE.md` (currently the list has `insight-index.md` and `decision-rubric.md` at lines 37-38), appended as a third bullet matching their shape (`**path** — description; when-to-read trigger`):

> - **`CONTEXT.md`** (repo root) — the project's domain glossary: tight definitions + `_Avoid_` synonyms for project-specific terms. Read it when naming modules/files/symbols or writing a requirement/design so naming stays canonical; maintain it inline when you coin or sharpen a term. Absent is fine — it is a convenience, not a gate.

Keeps AI-GUIDE.md at ~110 lines (≤200, I.1 / AC-6). Mirrors the existing memory-layer entries' "what + when-to-read" shape (behavior 11).

### 3.5 dev-map.md location entry

**Responsibility:** record where both `CONTEXT.md` copies live (behavior 12, AC-7).

**Exact additions to `c:\Programs\HarnessEngineering\docs\dev-map.md`:**

1. A row in the **"Where features live"** table (after the `Project templates` row):

   | Feature area | Files | Notes |
   |---|---|---|
   | Domain glossary (`CONTEXT.md`) | repo-root `CONTEXT.md` (dogfood, real terms) + `skills/harness-init/templates/common/CONTEXT.md` (generic seed) | Dual-purpose like `decision-rubric.md`: generic in the template, real in the dogfood; NOT byte-synced (sync-self touches only the 7 script pairs). SOFT dependency referenced by RA/SA. Single context; multi-context via a future root `CONTEXT-MAP.md`. |

2. (Optional, low-cost) a line in the top-level-layout tree comment near `AI-GUIDE.md` (line ~105) noting `CONTEXT.md ← domain glossary (memory layer; dogfood + template seed)`. This is nice-to-have; the table row is the AC-7 satisfier.

> Note: `docs/dev-map.md` carries G.4-gated check-count claims at lines 60 (`(32 checks)`) and 133 (`runs all 32 checks`). The new content MUST NOT alter those strings. Since the check count stays 32, no edit to those lines is needed — leave them exactly as-is.

---

## 4. Data model changes

None. No schema, no DB, no JSON schema change. `baseline.json` gets a value reconciliation on two existing integer fields (§6) — not a structural change.

---

## 5. API contracts / version stamp

No runtime/HTTP API. The "contract" surface that changes is the **release-stamp set** (OQ-3 = minor bump).

**Version: `0.33.0` → `0.34.0`** (minor — adds a new always-present generated-project asset; user-visible change to `/harness-init` output, consistent with how prior asset-adding tasks versioned, e.g. `decision-rubric` at v0.28.0).

**G.3-gated stamps (all four must agree — `verify_all` G.3 FAILs on drift):**
- `c:\Programs\HarnessEngineering\.claude-plugin\plugin.json` → `"version": "0.34.0"`
- `c:\Programs\HarnessEngineering\.claude-plugin\marketplace.json` → `plugins[0].version` = `"0.34.0"`
- `c:\Programs\HarnessEngineering\README.md` badge → `version-0.34.0-`
- `c:\Programs\HarnessEngineering\README.zh-CN.md` badge → `version-0.34.0-`

**G.4-gated:** `c:\Programs\HarnessEngineering\CHANGELOG.md` MUST gain a `## [0.34.0]` heading (G.4 asserts a heading for the current `plugin.json` version exists). Add a CHANGELOG entry under `[0.34.0]` describing the glossary asset + SOFT wiring; explicitly note "skill count stays 15; `verify_all` stays 32 checks; no new check, no new placeholder; no I.6 list change."

**G.4 count-claims — UNCHANGED.** The check count stays 32, so every `$count`-derived claim (AI-GUIDE.md `32/32` + `32 checks`, dev-map `(32 checks)` + `runs all 32 checks`, 40-locations `(32 checks`, both READMEs `verify__all-32%2F32` + `(32 checks)` / `（32 项检查）`, manual-e2e `32 checks`, baseline.json `"verify_all_checks": 32`) stays at 32. **Do not touch any of them.** This is the key reason no new guard was chosen (OQ-1): a new check would have forced 11 count-claim edits + this version bump; a pure asset add only triggers the version stamp.

---

## 6. Test / baseline reconciliation obligation

Adding an always-present template asset shifts `test-init`'s generated-asset assertion totals (boundary 4a, AC-9). Concretely:

**test-init — add ONE symmetric assertion in BOTH shells** (so the seed is actually regressed, not just silently shipped):
- `c:\Programs\HarnessEngineering\.harness\scripts\test-init.ps1`: after the `.harness/decision-rubric.md` assertions (~line 170-171), add e.g.
  `Assert "CONTEXT.md seed present (generic glossary)" { Test-Path (Join-Path $tmp "CONTEXT.md") }`
  and optionally `Assert "CONTEXT.md seed is generic (not byte-identical to repo dogfood)"` comparing against the repo-root `CONTEXT.md` (AC-3 diff). The existing "no unresolved placeholders" scan (`test-init.ps1:269-279`) ALREADY globs every generated `.md`, so the seed's placeholder-free property (AC-3 / behavior 7) is auto-covered — no extra assertion needed for that.
- `c:\Programs\HarnessEngineering\.harness\scripts\test-init.sh`: the byte-identical-behavior twin assertion (F.1 parity — every `.ps1` has a matching `.sh`).

**Baseline reconcile (bookkeeping, NOT gated):**
- `c:\Programs\HarnessEngineering\.harness\scripts\baseline.json` fields `test_init_ps_assertions` (currently 308) and `test_init_bash_no_python3_assertions` (currently 270) must be **updated to the totals from a real captured run** after the new assertion(s) land — NOT hand-incremented (per insight 2026-06-04 fabricated-tally and the dev-map test-init note: "operator reconciles baseline.json from a captured run"). The exact new numbers depend on how many assertions the developer adds (1 present-check, or 2 with the diff-check) × the 3 project types the test loops (generic/fullstack/backend). The developer captures the run and pastes the totals.
- These two fields are **tracking metrics**, NOT enforced by any `verify_all` check (grep confirms verify_all reads only `verify_all_checks` from baseline.json — G.4 row). So a stale value does not FAIL the gate; the obligation is honesty/traceability discipline, applied symmetrically in both shells (NFR-1, boundary 8).

**test-real-project:** its driver (`test-real-project.ps1` / `.sh`) overlays `common/` onto a real fixture and does NOT enumerate every asset by name (it has no per-asset present-count that the seed would shift; baseline keys `test_real_project_ps_assertions` / `…_bash_assertions` = 90/90). The seed rides along in the overlay; if the developer's captured run shows those totals unchanged, leave 90/90; if a real-project assertion is added, reconcile from the captured run. **Re-run both `test-real-project` shells and reconcile only what the captured run shows moved** — do not pre-edit.

**i18n/zh:** the generic English seed in `common/` passes through to zh-generated projects unchanged (the zh overlay carries only KEEP-ZH human-facing files — `i18n/zh/common/docs/spec/README.md`, `…/evals/golden-tasks.md.tmpl` — and the `_policy` snippet; AI-facing scaffolding falls through to English `common/` since T-015/T-016). **No zh `CONTEXT.md` overlay is created.** test-init's zh fixture layers `common→<type>→i18n/zh/common`, so the seed present-check passes in the zh path too (it lives in `common`).

---

## 7. Reuse audit

| Need | Existing code/asset | File path | Decision |
|---|---|---|---|
| Glossary file format (definition + `_Avoid_`, single vs multi-context) | reference `CONTEXT-FORMAT.md` | `c:\Programs\_research\mattpocock-skills\skills\engineering\domain-modeling\CONTEXT-FORMAT.md` | Reuse format verbatim as the §3.1/§3.2 structure |
| Dual-purpose asset (generic template + real dogfood, NOT byte-synced) | `decision-rubric.md` pair | dogfood `c:\Programs\HarnessEngineering\.harness\decision-rubric.md` vs template `…\templates\common\.harness\decision-rubric.md` | Reuse the exact pattern (T-018 precedent); seed = generic, dogfood = real |
| Non-`.tmpl` verbatim template asset (no placeholder substitution) | `60-tool-handoff.md`, `decision-rubric.md`, `25-decision-policy.md` in `templates\common\` | `c:\Programs\HarnessEngineering\skills\harness-init\templates\common\.harness\…` | Reuse: ship `CONTEXT.md` as a plain `.md` (not `.tmpl`), so the placeholder-scan & no-tmpl-leaked checks pass for free |
| SOFT vs HARD dependency wiring principle | ADR-0001 | `c:\Programs\_research\mattpocock-skills\docs\adr\0001-explicit-setup-pointer-only-for-hard-dependencies.md` | Reuse principle: vague-prose reference + graceful degradation, no setup pointer (§3.3) |
| Memory-layer index entry shape | existing AI-GUIDE Memory-layer bullets | `c:\Programs\HarnessEngineering\AI-GUIDE.md:36-38` | Reuse shape for the new `CONTEXT.md` bullet (§3.4) |
| dev-map location-table convention | "Where features live" table | `c:\Programs\HarnessEngineering\docs\dev-map.md:140-156` | Reuse the table; add one row (§3.5) |
| test-init asset-present assertion idiom | `Assert "… (shipped, generic)" { Test-Path … }` | `c:\Programs\HarnessEngineering\.harness\scripts\test-init.ps1:168-171` | Reuse idiom for the seed-present assertion (§6) |
| Recursive no-unresolved-placeholder scan | existing `\{\{[A-Z_]+\}\}` glob | `c:\Programs\HarnessEngineering\.harness\scripts\test-init.ps1:269-279` (+ `.sh` twin) | Reuse as-is — auto-covers AC-3 placeholder-free for the seed; no edit |
| Version-stamp gate (G.3) + count/version claim gate (G.4) | `verify_all` G.3/G.4 | `c:\Programs\HarnessEngineering\.harness\scripts\verify_all.ps1:332-352, 638-687` | Reuse: G.3 will gate the 4-way version bump; G.4 will gate the CHANGELOG heading. No new claim. |
| Baseline reconcile-from-captured-run discipline | dev-map test-init note + insight 2026-06-04 | `c:\Programs\HarnessEngineering\docs\dev-map.md:164`, `.harness\insight-index.md` (fabricated-tally line) | Reuse discipline (§6) |
| New `verify_all` guard for CONTEXT.md | (none — deliberately not built) | — | NOT added (OQ-1 = (a); [[feedback_design_over_guards]]; behavior 1 of out-of-scope; check count stays 32) |
| New template placeholder | (none — seed is placeholder-free) | — | NOT added (behavior 7; D.2 whitelist unchanged at 7) |

The reuse audit is dense: every piece of this task reuses an existing pattern (`decision-rubric.md` duality, the verbatim-`.md` template idiom, the memory-layer bullet shape, the placeholder scan, the G.3/G.4 gates). The only genuinely-new artifacts are the two `CONTEXT.md` files themselves, and even their format is reused from the reference repo.

---

## 8. Sequence / flow

**Authoring-time (this task, by the developer):**
```
1. Write dogfood  c:\…\CONTEXT.md            (real terms; §3.1 contract)
2. Write seed     …\templates\common\CONTEXT.md  (generic; §3.2 contract; ≠ #1)
3. Edit agents/requirement-analyst.md + agents/solution-architect.md  (§3.3 prose)
4. Edit AI-GUIDE.md memory-layer bullet      (§3.4)
5. Edit docs/dev-map.md location row          (§3.5)
6. Bump version 0.33.0→0.34.0 in plugin.json + marketplace.json + 2 README badges
   + add CHANGELOG [0.34.0] heading            (§5)
7. Add test-init seed-present assertion (ps1 + sh)  (§6)
8. RUN test-init (both shells) → CAPTURE PASS totals → reconcile baseline.json
   test_init_* fields from the captured run     (§6)
9. RUN test-real-project (both shells) → reconcile only if the captured run moved
10. RUN verify_all (both shells) → expect 32/32 PASS  (G.3 sees 0.34.0 everywhere,
    G.4 sees CHANGELOG [0.34.0] + count still 32)
```

**Runtime (a future generated project):**
```
/harness-init  → lays common/ overlay → project root now has a generic CONTEXT.md
                                          (placeholder-free; passes test-init scan)
… later, a task runs …
requirement-analyst  → (workflow step) sees CONTEXT.md present → uses canonical terms,
                       records a coined term inline   |  OR absent → proceeds normally
solution-architect   → (workflow step) sees CONTEXT.md present → canonical module names,
                       records a coined term inline   |  OR absent → proceeds normally
```
Graceful degradation is the "OR absent → proceeds normally" branch in both — no `BLOCKED`, no setup pointer (boundary 1, AC-4/AC-5).

---

## 9. Migration / rollout plan

- **Backwards compatibility:** fully additive. Existing repos are unaffected (the agents tolerate `CONTEXT.md` absent — boundary 1). Existing generated projects do not retroactively gain the seed (they would on a future `/harness-upgrade` content-refresh; out-of-scope this round — no upgrade-project change is made here).
- **Feature flag:** none needed (SOFT dependency = self-gating by presence).
- **Rollout order (single Developer — no `dev-*` agents in `.harness/agents/`, so no partitioning):**
  1. Author the two `CONTEXT.md` files (§3.1, §3.2).
  2. Wire the two agents + AI-GUIDE + dev-map (§3.3-3.5).
  3. Add the test-init assertion (both shells) (§6).
  4. Version stamp + CHANGELOG (§5).
  5. Capture runs, reconcile baseline (§6), then `verify_all` both shells (§8).
- **Rollback:** delete the two `CONTEXT.md` files, revert the agent/AI-GUIDE/dev-map/test-init/baseline edits, revert the version stamp to 0.33.0. Nothing persistent or stateful was created; rollback is a pure `git revert`. OQ-2 (location) and OQ-3 (version) are both cheap to change if the operator overrides.

---

## 10. Out-of-scope clarifications (design boundaries)

This design does NOT cover (carried from RA §3, restated as design boundaries):
- No `verify_all` guard/check for `CONTEXT.md` (presence/format/drift) — check count stays 32 (OQ-1=(a)).
- No `CONTEXT-MAP.md` multi-context machinery — single-context only; multi-context is a one-clause future note (OQ-5).
- No standalone `domain-modeling` skill — the maintenance discipline is folded into the one-line RA/SA prose (OQ-4=(a)); the fuller `SKILL.md` discipline is explicitly deferred.
- No ADR machinery (`docs/adr/`, ADR-FORMAT) — this repo uses per-task `02_SOLUTION_DESIGN.md`.
- No `_Avoid_`-term lint/enforcement — the list is advisory glossary content.
- No retroactive renaming sweep of existing docs/agents to the new canonical terms.
- No new template placeholder — D.2 whitelist stays at 7 (behavior 7).
- No `/harness-upgrade` change to retrofit the seed into already-generated projects.
- Exact term subset + `_Avoid_` wording in the dogfood file = content authoring (RA deferred it to the developer); this design fixes only the structure/constraints, not the prose.

---

## 11. Partition assignment

`.harness/agents/` holds **no `dev-*` partition agents** in this repo (confirmed: dev-map.md:63 "empty in this repo"; AI-GUIDE.md:15). This repo runs **single-Developer mode**. Per the agent contract, the partition table is therefore omitted — one Developer implements all files in the §8 order. (If this were a partitioned project, all artifacts here would fall to a single docs/tooling partition anyway — there is no frontend/backend/db split in a markdown+script task.)

---

## 12. Risk analysis

| # | Risk | Likelihood | Mitigation |
|---|---|---|---|
| R-1 | Seed accidentally written as `CONTEXT.md.tmpl` or with a `{{UPPER_SNAKE}}` token → `test-init` placeholder/`.tmpl`-leaked scan FAILs (boundary 4). | Med | §3.2 mandates plain `.md` + single-brace lowercase `{Your Project}`; the existing scan (`test-init.ps1:269-283`) is the catch; developer runs test-init before declaring done. |
| R-2 | Dogfood `CONTEXT.md` definition reproduces an I.6 banned-anchor sequence (e.g. when defining *rollback* / *verdict* / *insight*) → I.6 FAIL (boundary 5, AC-10). | Low | §3.1 flags it; the 14 live anchors concern retired claims (agent-copy/version/blunt-language), none about glossaries; `verify_all` I.6 is the exhaustive catch (insight 2026-05-23: rely on verify_all as the canonical scan, not hand-reasoning). |
| R-3 | Baseline `test_init_*` counts hand-incremented instead of captured from a real run → fabricated-tally class (insight 2026-06-04). | Med | §6 mandates capture-then-paste; the dev-map note already codifies this; PM runs the tests (sub-agents have no Bash) and reconciles from the actual output. |
| R-4 | Cross-shell asymmetry — assertion added to `.ps1` but not `.sh` (or counts reconciled in one shell only) → F.1 parity FAIL / silent count drift (NFR-1, boundary 8). | Med | §6 mandates the symmetric `.sh` twin + symmetric reconcile; F.1 gate catches a missing `.sh` change. |
| R-5 | Version bumped in plugin.json but a stamp missed (marketplace/README) → G.3 FAIL; or CHANGELOG heading omitted → G.4 FAIL. | Med | §5 enumerates the exact 4 stamps + the CHANGELOG heading; both gates catch omissions; this is the well-trodden release path (every recent task did it). |
| R-6 | Seed drifts toward a byte-copy of the dogfood (developer pastes real terms into the seed) → AC-3 violation, and a generated project ships harness-kit's own vocabulary. | Low | §3.2 + AC-3 require generic `ExampleTerm` content + a `diff`-differs assertion in test-init (§6); reviewer checks AC-3. |
| R-7 | RA/SA prose drifts into a HARD-dependency phrasing (a setup pointer or `BLOCKED`-on-absent) → violates ADR-0001 / behavior 10 / boundary 1. | Low | §3.3 gives verbatim SOFT prose with the explicit graceful-degradation clause; reviewer checks AC-4/AC-5 for absence of setup pointer & `BLOCKED`. |

---

## 13. Design notes (deferred-human accepted defaults)

- **OQ-1 = (a) no guard** — designed in; check count stays 32. Agreed (no concrete hazard; [[feedback_design_over_guards]]).
- **OQ-2 = repo root** — `c:\Programs\HarnessEngineering\CONTEXT.md` + seed at generated-project root. Agreed (reference convention for single-context; most discoverable).
- **OQ-3 = minor bump to v0.34.0** — proposed exact number per G.3/G.4 stamp consistency (current 0.33.0; next minor). The developer/PM may finalize a different number at delivery if a concurrent task also bumps; if so, stamp all four + CHANGELOG to that number consistently.
- **OQ-4 = (a) minimal** — one sentence per agent (§3.3). Agreed (NFR-2 token economy + 300-line cap headroom; fuller discipline deferred to a future skill).
- **OQ-5 = (a) one future line** — placed as a parenthetical clause in the dogfood/seed context description and the dev-map note (§3.1/§3.2/§3.5). Agreed (minimal token cost).

No disagreement with any accepted default; nothing re-opened. No genuine human-reserved decision arose, so no `BLOCKED: NEEDS-HUMAN` is emitted.

---

## 14. Verdict

**READY.**

The design is complete and self-contained: two new `CONTEXT.md` files with fully-specified structure and authoring constraints, verbatim SOFT-dependency prose for both agents, the exact AI-GUIDE memory-layer line, the exact dev-map row, the version-stamp set (v0.34.0) with the gates that enforce it, and the test-init assertion + baseline-reconcile obligation (both shells). No new `verify_all` check (count stays 32), no new template placeholder (D.2 stays at 7), no new dependency. Every artifact reuses an existing repo pattern; a developer can implement this without further design decisions.
