# 02 — Solution Design · rejected-decisions-memory (T-09)

**Mode:** full · **Stage:** 2 (Solution Architect) · **Date:** 2026-06-20
**Upstream verdict:** `01_REQUIREMENT_ANALYSIS.md` = **READY** (11 in-scope behaviors, 11 ACs; all 5 OQs answered with PM-accepted defaults).
**Decision mode:** Mode 2 · **deferred-human:** defer-with-recommendation, do not ask.

All paths in this doc are absolute (plan-mode handoff discipline). This is a pure
docs + template + agent-prose + rule-prose + index task — no runtime code, no new dependency,
no new `verify_all` check, no new template placeholder, no count flip. It is the **fourth
memory-kind** built on the exact T-02 `CONTEXT.md` dual-purpose blueprint.

---

## 1. Architecture summary

harness-kit gains a **rejected-decisions memory layer** — a single append-only Markdown file
recording "we deliberately decided NOT to do X, and why" so a future session re-proposing an
already-declined request or approach finds the prior decision instead of re-litigating it. It
ships in two intentionally-non-byte-synced copies, exactly like `CONTEXT.md` and
`decision-rubric.md`: a **real dogfood file** at `c:\Programs\HarnessEngineering\.harness\rejected-decisions.md`
(seeded with this repo's genuine declines from the mattpocock-adoption batch) and a **generic,
placeholder-free template seed** at `…\skills\harness-init\templates\common\.harness\rejected-decisions.md`
(an empty-but-ready skeleton that instructs each generated project to record its own declines).
The **read-at-decide / append-on-decline habit is single-sourced** in
`c:\Programs\HarnessEngineering\.harness\rules\25-decision-policy.md` (the rule that loads exactly
at a decide/escalate point), and the two memory-reading agents (`requirement-analyst` step 7,
`solution-architect` step 5) gain a one-line SOFT pointer at their existing memory-read site
(read-if-present, lazy-maintain, graceful-degrade — no setup pointer, never `BLOCKED`-on-absent).
The file is indexed once in the AI-GUIDE.md **Memory layer** block as the fourth distinct kind,
recorded in `docs/dev-map.md`, and the existing `15-skill-authoring.md` "Deliberately not adopted"
telemetry entry is **reconciled to single-source** (its rationale migrates into the new file; the
skill-authoring rule keeps a one-line pointer, not a divergent second copy). No `verify_all` guard
is added (check count stays **32**); a minor version bump (**v0.39.0 → v0.40.0**) stamps the
user-visible change (a new always-present generated-project asset), with **no count flip
(16 skills / 8 framework agents / 32 checks unchanged)**.

---

## 2. Affected modules (file paths)

**New files (2):**
- `c:\Programs\HarnessEngineering\.harness\rejected-decisions.md` — repo-root-of-`.harness` dogfood (real harness-kit declines; §3.1).
- `c:\Programs\HarnessEngineering\skills\harness-init\templates\common\.harness\rejected-decisions.md` — generic template seed (skeleton; placeholder-free; lands at each generated project's `.harness/`; §3.2).

**Edited files — content (5):**
- `c:\Programs\HarnessEngineering\.harness\rules\25-decision-policy.md` — single-source the read/append habit (currently 100 lines; cap 200 — I.2/I.3; §3.3).
- `c:\Programs\HarnessEngineering\agents\requirement-analyst.md` — one-line SOFT pointer at workflow step 7 (currently 78 lines; cap 300; §3.4).
- `c:\Programs\HarnessEngineering\agents\solution-architect.md` — one-line SOFT pointer at workflow step 5 (currently 145 lines; cap 300; §3.4).
- `c:\Programs\HarnessEngineering\.harness\rules\15-skill-authoring.md` — replace the telemetry rationale with a one-line pointer (currently 116 lines; cap 200; §3.5).
- `c:\Programs\HarnessEngineering\AI-GUIDE.md` — one new Memory-layer index line (currently 111 lines; cap 200 — I.1; §3.6).

**Edited files — index/location (1):**
- `c:\Programs\HarnessEngineering\docs\dev-map.md` — one location-table row + one tree-comment line (§3.7).

**Edited files — test (2):**
- `c:\Programs\HarnessEngineering\.harness\scripts\test-init.ps1` — one seed-present assertion (count moves; §6).
- `c:\Programs\HarnessEngineering\.harness\scripts\test-init.sh` — symmetric assertion (count moves; §6).

**Edited files — version stamp (5) + baseline (1):**
- `c:\Programs\HarnessEngineering\.claude-plugin\plugin.json` — `0.39.0` → `0.40.0` (G.3-gated).
- `c:\Programs\HarnessEngineering\.claude-plugin\marketplace.json` — `plugins[0].version` `0.39.0` → `0.40.0` (G.3-gated).
- `c:\Programs\HarnessEngineering\README.md` — version badge `0.39.0` → `0.40.0` (G.3-gated).
- `c:\Programs\HarnessEngineering\README.zh-CN.md` — version badge `0.39.0` → `0.40.0` (G.3-gated).
- `c:\Programs\HarnessEngineering\CHANGELOG.md` — new `## [0.40.0]` heading (G.4-gated).
- `c:\Programs\HarnessEngineering\.harness\scripts\baseline.json` — reconcile `test_init_ps_assertions` (currently 308) + `test_init_bash_no_python3_assertions` from a captured run (tracking field; NOT gated; §6).

> The version-stamp fan-out (README ×2, plugin.json, marketplace.json, CHANGELOG) is the
> standard G.3/G.4 set, bundled under §5. The README `test-init-308/308` badge may shift by the
> per-type assertion delta — reconcile it from the captured run with the badge (§6, §9).

---

## 3. Module decomposition

This task adds **content artifacts**, not code — so "public API" = each file's structure/contract
that downstream consumers (the decision rule, the two agents, AI-GUIDE, init) rely on.

### 3.1 Dogfood `.harness/rejected-decisions.md`

**Responsibility:** the canonical record of harness-kit's own deliberately-declined requests
and approaches; read when this repo hits a non-trivial decide-point, appended when something
is deliberately declined.

**Structure (contract — a tight header + one short record per declined concept):**

```md
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
```

**Authoring constraints the developer MUST honor (design, not exact prose):**
- **Header ≤6 lines** of substance (behavior #2, AC-1): states what it is, when-to-read, when-to-append, the one-record-per-concept rule, the three sibling memory pointers, and the **soft size note with NO numeric gate** (OQ-2 = (b); behavior #2). The block-quote above is the contract; whitespace may be adjusted to land at ≤6 visible substance lines.
- **One record per concept** (behavior #3, boundary "duplicate concept"), each a `## kebab-handle` heading + the four fields: **decision** (declined / deferred — behavior #4), **why** (substantive: scope / technical constraint / strategic choice — never "we don't want it"), and **origin**. Target ≤~8 lines per record.
- **`deferred` vs `declined`** is explicit (behavior #4, boundary "deferral vs rejection"): `design-it-twice` is the only `deferred` seed; the rest are `declined`. When ambiguous, mark `deferred` (the safer marker).
- **Seed set = the named batch declines** (behavior #5): the nine `##` records above cover `design-it-twice` (deferred), `ask-matt-router`, `issue-tracker-dedup`, `to-prd`, `triage`, `skill-usage-telemetry`, and the three non-fit skill-family groups (`teach`/`handoff`/`writing-*`/`personal`, `git-guardrails`/`setup-pre-commit`, `tdd`/`diagnosing-bugs`). Grouping the non-fit skill families into three records (rather than nine one-liners) honors token economy while keeping each `why` substantive.
- **Origin citations are backward-looking evidence** (behavior #11): "origin: mattpocock-adoption batch" / "migrated from 15-skill-authoring.md" is an evidence-style backward reference (permitted by the T-05 forward/backward boundary). Do NOT write forward-looking file:line anchors as origins — name the batch/concept, not a transient line.
- **No I.6 banned-anchor sequence** (boundary "I.6 self-trip", AC-10): this file is in a **non-exempt** location (`.harness/`, not `docs/features/`, not in `i6_exempt_files`), so `verify_all` I.6 scans it. The 14 live banned anchors concern retired claims about **CLAUDE.md generation/composition** (`Composed into CLAUDE.md`, `regenerates CLAUDE.md`, `Generated from .harness/rules`, `.harness/ → CLAUDE.md`, etc.), the retired **`scaffolding-only` harness-adopt** claim, and the retired **`全程中文`** claim. None of the seed records touch those topics, so this is a "do not author one in" constraint, low collision risk. Concretely: **do not** phrase any record about CLAUDE.md being generated/composed/regenerated from rules, and **do not** use `全程中文`; the skill/issue-tracker/telemetry declines naturally avoid all of them. The exhaustive catch is `verify_all` I.6 (the developer runs it before declaring done).

### 3.2 Template seed `…\templates\common\.harness\rejected-decisions.md`

**Responsibility:** the starter rejected-decisions file every generated project receives in its
`.harness/`, instructing the project to record its OWN declines — GENERIC, not a copy of §3.1.

**Structure (contract):**

```md
# Rejected decisions — deliberately not adopted (and why)

> Deliberately-declined requests / approaches + why, so a re-proposal finds the prior
> decision instead of re-litigating it. **Read** at a non-trivial decide-point before
> proposing a new approach / feature; **append** when something is deliberately declined
> (a real rejection — or a `deferred` "not now", marked as such). One record per concept;
> a re-occurrence adds its origin to that record, not a second record. Sibling memory:
> `.harness/insight-index.md` (truths), `.harness/decision-rubric.md` (autonomy principles),
> `CONTEXT.md` (glossary). Soft self-discipline: if this grows past ~one screen, compact
> merged/obsolete records — no gate enforces size.

<!-- No declines recorded yet. When your project deliberately turns something down, add a
     record below: a short kebab-case handle as an `## heading`, then the decision
     (declined / deferred), a substantive why (scope / constraint / strategic choice — not
     "we don't want it"), and the origin (which request / task raised it). Example shape: -->

## example-declined-concept
- **Decision:** declined.
- **Why:** a one-or-two-sentence substantive reason this is out of scope for your project
  (a scope boundary, a technical constraint, or a strategic choice). Delete this example
  once you record a real decline.
- **Origin:** the request / task that raised it.
```

**Authoring constraints (design):**
- **Zero `{{PLACEHOLDER}}` tokens** (behavior #7, AC-3): the seed is an `.md` in scope of `test-init`'s recursive `\{\{[A-Z_]+\}\}` scan (`test-init.sh:204`, ps1 twin). Write plain prose only — no `{{...}}`. **Do NOT add any placeholder to the D.2 whitelist** (out-of-scope #8; whitelist stays at 7).
- **Generic** (behavior #7, AC-3): the seed carries one `example-declined-concept` stub + an HTML-comment instruction, NOT this repo's real declines. It MUST differ from §3.1 (AC-3 — they are not byte-identical). `sync-self` does NOT mirror it (it mirrors only the 7 script pairs — §8), so the two copies legitimately diverge, exactly like `decision-rubric.md` and `CONTEXT.md` do today.
- **Plain `.md`, not `.tmpl`** (matches `…\templates\common\.harness\decision-rubric.md` and `…\rules\25-decision-policy.md`, which ship verbatim): there are no placeholders to substitute, so it ships byte-for-byte; the "no `.tmpl` leaked" scan is satisfied because there is no `.tmpl`.
- **I.6-safe** (AC-10): the template seed is ALSO non-exempt (it's under `templates/common/.harness/`, scanned by `git ls-files`), so the same no-banned-anchor constraint applies. The generic example prose trivially avoids all 14 anchors.
- **Header byte-identical to §3.1's header is acceptable** (the header is generic instruction, not repo-specific content); the BODY is what must differ (generic stub vs nine real records). AC-3's "not byte-identical" is satisfied by the body difference.

### 3.3 Single-source the habit — `25-decision-policy.md` (canonical)

**Responsibility:** wire the read-at-decide / append-on-decline habit into the rule that loads
exactly at a decide/escalate point (OQ-3 = (a); behavior #10). This is the **one canonical place**;
everything else points here.

**Exact insertion (the contract — paste, adjust only whitespace):** add a bullet to the existing
**"When to read this"** list in `c:\Programs\HarnessEngineering\.harness\rules\25-decision-policy.md`
(currently a single bullet at lines 18-22), so the habit loads on the same trigger the policy
already loads on:

> - **At a non-trivial decide-point, also consult `.harness/rejected-decisions.md`** (the
>   deliberately-declined-options memory) before proposing a new approach/feature — if the thing
>   was already declined, surface that decision instead of re-litigating it. When you (or the user)
>   **deliberately decline** a request/approach, **append** a short record there (concept handle ·
>   `declined`/`deferred` · substantive why · origin); a re-occurrence adds its origin to the
>   existing record. The file is a SOFT convenience — absent (a project that predates it) is fine,
>   never a precondition, never a `BLOCKED`.

**Why here + this wording (behavior #10, OQ-3, boundaries):**
- The decide-point is precisely when `25-decision-policy.md` loads (its "When to read" = "whenever an agent is about to ask / decide"), so the read-at-decide habit reaches **every** decide-point, not just the RA/SA stages.
- "append a short record there" references the §3.1 four-field format so a maintained record stays well-formed (single-source: the format lives in the file's own header; the rule names the fields tersely).
- "SOFT convenience — absent is fine, never a precondition, never a `BLOCKED`" = the explicit graceful-degradation + no-`BLOCKED`-on-absent clause (boundary "file absent", the `CONTEXT.md` soft-dependency model).
- Rule 25 goes from 100 → ~107 lines (≤200, I.2/I.3; AC-6). One bullet, no new heading.

### 3.4 SOFT pointers from RA + SA (one line each, reference-not-restate)

**Responsibility:** the two agents that already read the memory layer at decision time gain a
one-line SOFT pointer that **references** the §3.3 habit rather than restating it (behavior #10,
the T-05 single-source discipline). These are NOT the canonical habit — they point at it.

**Decision: keep them (do not drop), but make them pure pointers.** The RA/SA do not always load
`25-decision-policy.md` (it loads on the would-ask trigger); a one-line pointer at their existing
memory-read step makes the file discoverable at the exact step where they already read the other
memory-layer siblings (`CONTEXT.md`, insight-index). This mirrors the proven T-02 `CONTEXT.md`
soft-read placement. The cost is one line per agent, far under the 300-line cap, and it is a
**reference** ("see `25-decision-policy.md`"), so the habit text stays single-sourced (AC-6: the
rule prose appears in exactly one canonical place; the others point to it by name).

For `c:\Programs\HarnessEngineering\agents\requirement-analyst.md` — append to **workflow step 7**
(the existing `CONTEXT.md` soft-read line), as a trailing sentence:

> Likewise, if `.harness/rejected-decisions.md` is present, skim it before proposing scope — if a
> request matches a prior decline, surface that decision rather than re-litigating it; when
> something is deliberately declined, append a record there per `.harness/rules/25-decision-policy.md`.
> Absent is fine — never a precondition.

For `c:\Programs\HarnessEngineering\agents\solution-architect.md` — append to **workflow step 5**
(the existing `CONTEXT.md` soft-read line), as a trailing sentence:

> Likewise, if `.harness/rejected-decisions.md` is present, check it before introducing a new
> approach/module — if it was already declined, surface that decision rather than re-designing it;
> when you deliberately decline an approach, append a record there per
> `.harness/rules/25-decision-policy.md`. Absent is fine — it never blocks the design.

**Why this wording:** "if present / skim it / absent is fine — never a precondition / never blocks"
= read-if-present + graceful-degradation, no setup pointer (the SOFT model, boundary "file absent",
AC-6). "append … **per `25-decision-policy.md`**" = reference-not-restate: the agents point at the
canonical habit; they do not carry their own copy of the format/trigger prose. RA 78 → ~80 lines,
SA 145 → ~147 lines — both far under 300.

### 3.5 Reconcile `15-skill-authoring.md` (single-source the telemetry decline)

**Responsibility:** the existing "Deliberately not adopted → skill-usage telemetry" rationale
(`15-skill-authoring.md:99-106`) is reconciled with the new file so the decision is not stated as
two divergent rationales (behavior #6, OQ-4 = (a), AC-8).

**Decision: (a) replace the rationale paragraph with a one-line pointer.** The telemetry decline's
substantive rationale **migrates** into `.harness/rejected-decisions.md` (§3.1 `skill-usage-telemetry`
record, with `Origin: migrated here from 15-skill-authoring.md`). `15-skill-authoring.md` keeps the
**heading** so a skill author still finds it, but its body becomes a one-line pointer (SSOT — rule 15's
own "Single source of truth" principle; no second drifting copy).

**Exact replacement** for the body of the `## Deliberately not adopted` section in
`c:\Programs\HarnessEngineering\.harness\rules\15-skill-authoring.md` (currently lines 99-106):

> ## Deliberately not adopted
>
> Project-wide declined options (incl. **skill-usage telemetry / per-call usage logging** — the
> blog's "log every invocation" hook, which we decline as a standing per-call cost that buys nothing
> for a single-maintainer repo) now live in **`.harness/rejected-decisions.md`** with their reasons.
> Record a new skill/agent-authoring decline there, not here — one source, no drift.

**Why:** keeps the heading discoverable for skill authors, names the telemetry decline so a reader
mid-section still recognizes it, but holds the **rationale once** in the rejected-decisions file
(AC-8: the two files do not state two different reasons for the telemetry decline). Rule 15 goes
116 → ~112 lines (shorter; ≤200). The migrated record's `why` (§3.1) is the SAME reason, not a new
one — no divergence.

### 3.6 AI-GUIDE.md Memory-layer index line

**Responsibility:** one index entry so any tool discovers the file as the fourth memory kind
(behavior #8, AC-4).

**Exact line to add** as a fourth bullet in the **Memory layer** block of
`c:\Programs\HarnessEngineering\AI-GUIDE.md` (currently three bullets at lines 37-39:
insight-index, decision-rubric, CONTEXT.md), matching their `**path** — what; when-to-read` shape:

> - **`.harness/rejected-decisions.md`** — deliberately-declined requests/approaches + why (the
>   fourth memory kind: declined options, distinct from truths / autonomy principles / glossary).
>   Read it at a non-trivial decide-point before proposing a new approach/feature; append a record
>   when something is deliberately declined. The habit is governed by `25-decision-policy.md`.
>   Absent is fine — a convenience, not a gate.

Keeps AI-GUIDE.md at ~112 lines (≤200, I.1 / AC-4). States the distinction in one phrase ("the
fourth memory kind: declined options, distinct from …") so the four kinds stay non-overlapping
(NFR memory-layer distinctness). The `16 skills` / `32 checks` count strings elsewhere in AI-GUIDE
are **untouched** (no count flip).

### 3.7 dev-map.md location entry

**Responsibility:** record where both copies live (behavior #9, AC-5).

**Exact additions to `c:\Programs\HarnessEngineering\docs\dev-map.md`:**

1. A row in the **"Where features live"** table (after the `Domain glossary (CONTEXT.md)` row at
   line 152):

   | Feature area | Files | Notes |
   |---|---|---|
   | Rejected-decisions memory (`.harness/rejected-decisions.md`) | repo `.harness/rejected-decisions.md` (dogfood, real declines) + `skills/harness-init/templates/common/.harness/rejected-decisions.md` (generic seed) | Fourth memory kind (declined options + why). Dual-purpose like `CONTEXT.md` / `decision-rubric.md`: generic seed in the template, real in the dogfood; NOT byte-synced (sync-self touches only the 7 script pairs). Read/append habit single-sourced in `.harness/rules/25-decision-policy.md`; SOFT pointers from RA/SA. No gate. |

2. A line in the `.harness/` tree comment near `decision-rubric.md` (line ~80):
   `│   ├── rejected-decisions.md           ← Memory layer (4th kind): deliberately-declined options + why; read/append at decide-points (v0.40+; dual-purpose dogfood + template seed)`

> Note: `docs/dev-map.md` carries G.4-gated check-count claims (`(32 checks)` at lines 82, 166;
> `runs all 32 checks` at line 166). The check count stays 32, so **leave those strings exactly
> as-is** — no edit.

---

## 4. Data model changes

None. No schema, no DB, no JSON-schema change. `baseline.json` gets a value reconciliation on two
existing integer fields (§6) — not a structural change.

---

## 5. API contracts / version stamp

No runtime/HTTP API. The "contract" surface that changes is the **release-stamp set** (OQ-5 = minor
bump, no count flip).

**Version: `0.39.0` → `0.40.0`** (minor — adds a new always-present generated-project asset; the
template seed ships into every `/harness-init` output, exactly like `CONTEXT.md` bumped a minor at
T-02). This is a version-worthy distributed change but **NOT** a count change (T-008
count↔version insight).

**G.3-gated stamps (all four must agree — `verify_all` G.3 FAILs on drift):**
- `c:\Programs\HarnessEngineering\.claude-plugin\plugin.json` → `"version": "0.40.0"`
- `c:\Programs\HarnessEngineering\.claude-plugin\marketplace.json` → `plugins[0].version` = `"0.40.0"`
- `c:\Programs\HarnessEngineering\README.md` badge → `version-0.40.0-blue`
- `c:\Programs\HarnessEngineering\README.zh-CN.md` badge → `version-0.40.0-blue`

**G.4-gated:** `c:\Programs\HarnessEngineering\CHANGELOG.md` MUST gain a `## [0.40.0] - <date>`
heading (G.4 asserts a heading for the current `plugin.json` version exists). The CHANGELOG entry
describes the rejected-decisions memory + seed + habit wiring, and explicitly states:
**"counts unchanged: 16 skills / 8 framework agents / 32 checks; no new `verify_all` check; no new
template placeholder (D.2 stays at 7); no I.6 banned/exempt-list change; not byte-synced by
sync-self."**

**G.4 count-claims — UNCHANGED.** The check count stays 32 and the skill count stays 16, so every
`$count`-derived claim (AI-GUIDE `32/32`/`32 checks`/`16 skills`, dev-map `(32 checks)`/`runs all 32
checks`, README EN+zh `verify__all-32%2F32`/`(32 checks)`/`（32 项检查）`/`16 skills`/`16 个技能`,
baseline `"verify_all_checks": 32`) stays put. **Do not touch any of them.** This is the key reason
no new guard was chosen (out-of-scope #2): a new check would force ~11 count-claim edits; a pure
asset add triggers only the version stamp.

**The `test-init` badge** (`test--init-308/308` in both READMEs) shifts by the per-type assertion
delta (one new assert × the 3 project types the test loops = +3 → 311; confirm from the captured
run). Reconcile that badge with the captured `test-init` total (§6) — it is a real number, not a
gated G.3/G.4 claim, but keep it honest.

---

## 6. Test / baseline reconciliation obligation

Adding an always-present template asset shifts `test-init`'s generated-asset assertion totals
(boundary "empty file", AC-3). Concretely:

**test-init — add ONE symmetric assertion in BOTH shells**, immediately after the existing
`CONTEXT.md seed present` assertion (`test-init.sh:140`; ps1 twin at the same place):
- `c:\Programs\HarnessEngineering\.harness\scripts\test-init.sh`:
  `assert "rejected-decisions.md seed present (generic)" "[[ -f '$tmp/.harness/rejected-decisions.md' ]]"`
- `c:\Programs\HarnessEngineering\.harness\scripts\test-init.ps1`: the matching
  `Assert "rejected-decisions.md seed present (generic)" { Test-Path (Join-Path $tmp ".harness/rejected-decisions.md") }` (F.1 parity — every `.ps1` assertion has a `.sh` twin).

The existing recursive **no-unresolved-placeholder scan** (`test-init.sh:204`, ps1 twin) ALREADY
globs every generated `.md`, so the seed's placeholder-free property (AC-3 / behavior #7) is
**auto-covered** — no extra assertion needed for that. (No diff-vs-dogfood assertion is needed: the
seed lands in a generated project that has no repo-dogfood to compare against; AC-3's "not
byte-identical" is a one-time reviewer check, not a test-init regression.)

**Baseline reconcile (bookkeeping, NOT gated):**
- `c:\Programs\HarnessEngineering\.harness\scripts\baseline.json` fields `test_init_ps_assertions`
  (currently 308) and `test_init_bash_no_python3_assertions` must be **updated to the totals from a
  real captured run** after the new assertion lands — NOT hand-incremented (insight 2026-06-04
  fabricated-tally; dev-map test-init note: "operator reconciles baseline.json from a captured run").
  The delta is +1 assertion × the 3 project types the test loops (generic/fullstack/backend) = +3
  on each shell's total; the developer/PM captures the run and pastes the actual totals.
- These two fields are **tracking metrics**, NOT enforced by any `verify_all` check (verify_all
  reads only `verify_all_checks` from baseline.json). A stale value does not FAIL the gate; the
  obligation is honesty/traceability, applied symmetrically in both shells (NFR token-economy /
  boundary cross-shell).

**test-real-project:** its driver overlays `common/` onto a real fixture and does NOT enumerate
every asset by name (baseline keys `test_real_project_ps_assertions` / `…_bash_assertions` = 90/90).
The seed rides along in the overlay; if the captured run shows 90/90 unchanged, leave them. **Re-run
both `test-real-project` shells and reconcile only what the captured run shows moved** — do not
pre-edit.

**i18n/zh:** the generic English seed in `common/` passes through to zh-generated projects unchanged
(the zh overlay carries only KEEP-ZH human-facing files + the `_policy` snippet; AI-facing
scaffolding falls through to English `common/`). **No zh `rejected-decisions.md` overlay is created.**
test-init's zh fixture layers `common→<type>→i18n/zh/common`, so the seed present-check passes in the
zh path too (it lives in `common`).

---

## 7. Reuse audit

| Need | Existing code/asset | File path | Decision |
|---|---|---|---|
| Dual-purpose memory-layer file (generic template seed + real dogfood, NOT byte-synced) | `CONTEXT.md` pair (T-02); `decision-rubric.md` pair | dogfood `c:\Programs\HarnessEngineering\CONTEXT.md` + `.harness\decision-rubric.md` vs template `…\templates\common\CONTEXT.md` + `…\.harness\decision-rubric.md` | Reuse the exact pattern (§3.1/§3.2); seed = generic, dogfood = real, sync-self mirrors neither |
| Non-`.tmpl` verbatim template asset (no placeholder substitution) | `decision-rubric.md`, `25-decision-policy.md`, `60-tool-handoff.md`, `CONTEXT.md` in `templates\common\` | `c:\Programs\HarnessEngineering\skills\harness-init\templates\common\.harness\…` | Reuse: ship `rejected-decisions.md` as plain `.md` (not `.tmpl`) → placeholder-scan + no-tmpl-leaked checks pass for free |
| SOFT-dependency wiring (read-if-present, graceful degrade, no setup pointer) | T-02 `CONTEXT.md` soft-read prose in RA step 7 / SA step 5 | `c:\Programs\HarnessEngineering\agents\requirement-analyst.md:43`, `agents\solution-architect.md:45` | Reuse the exact placement + soft phrasing (§3.4); append to the SAME step |
| Single-source a habit in the rule that loads at its trigger | `25-decision-policy.md` "When to read" + the decision/escalation habit | `c:\Programs\HarnessEngineering\.harness\rules\25-decision-policy.md:16-22` | Reuse: add the read/append bullet here (the decide-point trigger); RA/SA reference it (§3.3, §3.4) |
| Single-source-the-boundary, reference-not-restate | T-05 durable-brief single-source discipline | `docs\features\_archived\durable-brief\02_SOLUTION_DESIGN.md` | Reuse: habit lives once in rule 25; RA/SA/AI-GUIDE/15-skill-authoring point to it (§3.3-3.6) |
| Memory-layer index entry shape | existing AI-GUIDE Memory-layer bullets (3) | `c:\Programs\HarnessEngineering\AI-GUIDE.md:36-39` | Reuse the `**path** — what; when-to-read` shape for the 4th bullet (§3.6) |
| dev-map location-table convention | "Where features live" table; `CONTEXT.md` row | `c:\Programs\HarnessEngineering\docs\dev-map.md:143-152` | Reuse the table; add one row + one tree line (§3.7) |
| test-init asset-present assertion idiom | `assert "CONTEXT.md seed present (generic glossary)"` | `c:\Programs\HarnessEngineering\.harness\scripts\test-init.sh:140` (+ ps1 twin) | Reuse idiom for the seed-present assertion (§6) |
| Recursive no-unresolved-placeholder scan | existing `\{\{[A-Z_]+\}\}` recursive glob | `c:\Programs\HarnessEngineering\.harness\scripts\test-init.sh:204` (+ ps1 twin) | Reuse as-is — auto-covers AC-3 placeholder-free; no edit |
| Version-stamp gate (G.3) + count/version claim gate (G.4) | `verify_all` G.3/G.4 | `c:\Programs\HarnessEngineering\.harness\scripts\verify_all.sh` G.3/G.4 blocks (+ ps1 twin) | Reuse: G.3 gates the 4-way bump; G.4 gates the CHANGELOG heading; no count claim changes |
| I.6 retired-claim guard (scope + banned list) | `verify_all` I.6 banned-anchor scan (14 entries) | `c:\Programs\HarnessEngineering\.harness\scripts\verify_all.sh:521-536` (+ ps1 twin) | Reuse as the catch; author records to avoid all 14 anchors (§3.1, §3.2 constraints) |
| Baseline reconcile-from-captured-run discipline | dev-map test-init note + insight 2026-06-04 | `c:\Programs\HarnessEngineering\docs\dev-map.md:167`, `.harness\insight-index.md` (fabricated-tally line) | Reuse discipline (§6) |
| Existing ad-hoc "Deliberately not adopted" practice | telemetry entry in `15-skill-authoring.md` | `c:\Programs\HarnessEngineering\.harness\rules\15-skill-authoring.md:99-106` | Migrate rationale into the new file; leave a one-line pointer (§3.5) — this IS the practice being generalized |
| Upstream `.out-of-scope/` KB shape (why / prior-requests / when-to-write) | reference (read-only) | `c:\Programs\_research\mattpocock-skills\skills\engineering\triage\OUT-OF-SCOPE.md` | Reuse the per-concept "why + origin" idea in single-file form (out-of-scope #1: no per-concept directory at this scale) |
| New `verify_all` guard for rejected-decisions.md | (none — deliberately not built) | — | NOT added (OQ-2; feedback_design_over_guards; out-of-scope #2; check count stays 32) |
| New template placeholder | (none — seed is placeholder-free) | — | NOT added (behavior #7; D.2 whitelist stays at 7) |
| Per-concept directory / auto-matching machinery | (none — single file at this scale) | — | NOT added (out-of-scope #1, #3) |

The reuse audit is dense: every piece reuses an existing pattern (`CONTEXT.md` duality, the
verbatim-`.md` template idiom, the SOFT-read placement, the single-source-the-habit discipline, the
memory-layer bullet shape, the placeholder scan, the G.3/G.4/I.6 gates). The only genuinely-new
artifacts are the two `rejected-decisions.md` files; even their per-record shape is reused from the
upstream `.out-of-scope/` KB (in single-file form) and the existing `15-skill-authoring.md` practice.

---

## 8. Sequence / flow

**Authoring-time (this task, by the developer):**
```
1. Write dogfood  c:\…\.harness\rejected-decisions.md         (real declines; §3.1 contract)
2. Write seed     …\templates\common\.harness\rejected-decisions.md  (generic; §3.2; body ≠ #1)
3. Edit rule 25  .harness/rules/25-decision-policy.md          (canonical read/append bullet; §3.3)
4. Edit agents   requirement-analyst.md step 7 + solution-architect.md step 5  (SOFT pointers; §3.4)
5. Edit rule 15  .harness/rules/15-skill-authoring.md          (telemetry → one-line pointer; §3.5)
6. Edit AI-GUIDE.md memory-layer 4th bullet                    (§3.6)
7. Edit docs/dev-map.md location row + tree line               (§3.7)
8. Bump 0.39.0→0.40.0 in plugin.json + marketplace.json + 2 README badges
   + add CHANGELOG [0.40.0] heading (counts-unchanged note)    (§5)
9. Add test-init seed-present assertion (ps1 + sh)             (§6)
10. RUN test-init (both shells) → CAPTURE PASS totals → reconcile baseline.json
    test_init_* fields + the README test-init badge from the captured run  (§5, §6)
11. RUN test-real-project (both shells) → reconcile only if the captured run moved (§6)
12. RUN verify_all (both shells) → expect 32/32 PASS
    (G.3 sees 0.40.0 everywhere; G.4 sees CHANGELOG [0.40.0] + counts still 16/32;
     I.6 scans both new files and PASSes — no banned anchor)   (§3.1 I.6 constraint)
```

**Runtime (a future generated project):**
```
/harness-init  → lays common/ overlay → project .harness/ now has a generic
                 rejected-decisions.md  (placeholder-free; passes test-init scan)
… later, a task / session hits a decide-point …
25-decision-policy.md loads (would-ask trigger) → reads rejected-decisions.md if present:
    matches a prior decline → surface it, don't re-litigate
    deliberately declines something now → append a record
requirement-analyst (step 7) / solution-architect (step 5) → soft-read it if present;
    point at rule 25 for the append habit   |  OR absent → proceed normally
```
Graceful degradation is the "OR absent → proceed normally" branch everywhere — no `BLOCKED`, no
setup pointer (boundary "file absent", AC-6).

---

## 9. Migration / rollout plan

- **Backwards compatibility:** fully additive. Existing repos and existing generated projects are
  unaffected (every consumer treats the file as SOFT — boundary "file absent"). Existing generated
  projects do not retroactively gain the seed (they would on a future `/harness-upgrade`
  content-refresh; out of scope this round — no upgrade-project change here).
- **Feature flag:** none needed (SOFT dependency = self-gating by presence).
- **Single-source migration (the only "migration"):** the `15-skill-authoring.md` telemetry
  rationale moves into `.harness/rejected-decisions.md`. Sequence: write the dogfood record FIRST
  (§3.1, step 1), THEN replace the rule-15 body with the pointer (§3.5, step 5) — so the rationale
  is never momentarily homeless. Rollback restores the rule-15 paragraph from git.
- **Rollout order (single Developer — no `dev-*` agents in `.harness/agents/`):** the §8 steps 1-12
  in order.
- **Rollback:** delete the two `rejected-decisions.md` files, revert the rule-25 / rule-15 /
  RA / SA / AI-GUIDE / dev-map / test-init / baseline edits, revert the version stamp to 0.39.0.
  Nothing persistent/stateful was created; rollback is a pure `git revert`. OQ choices (location,
  size-note, version number) are all cheap to change if the operator overrides.

---

## 10. Out-of-scope clarifications (design boundaries)

This design does NOT cover (carried from RA §4, restated as design boundaries):
- No `verify_all` guard/check for the file (presence/format/drift/size) — check count stays 32
  (OQ-2; feedback_design_over_guards).
- No per-concept directory (`.out-of-scope/` style) — single append-only file at this repo's scale
  (out-of-scope #1).
- No issue-tracker dedup automation, concept-similarity matching, or "surface the prior decision"
  automation — matching is a human/agent reading the file (out-of-scope #3).
- No overloading of `.harness/insight-index.md` with declined-options content — insight-index stays
  ≤30 hard-won TRUTHS; this is a separate file (out-of-scope #4, NFR memory-layer distinctness).
- No hard size cap enforced by a gate — soft self-discipline note only (out-of-scope #5).
- No automatic re-opening/reversing of past decisions — removing/revising a record is a manual human
  act (out-of-scope #6).
- No migration of OTHER future batches' declines — this iteration seeds only the named
  mattpocock-batch declines (out-of-scope #7).
- No skill-count or check-count flip — 16 skills / 32 checks unchanged (out-of-scope #8).
- No new template placeholder — D.2 whitelist stays at 7.
- No `/harness-upgrade` change to retrofit the seed into already-generated projects.
- No zh `rejected-decisions.md` overlay — the generic English seed falls through to zh projects (§6).
- A new `## Custom rubric (Mode 3)`-style section or any decision-rubric edit — the habit lives in
  rule 25, not the rubric (the rubric is autonomy principles, a distinct memory kind).

---

## 11. Partition assignment

`.harness/agents/` holds **no `dev-*` partition agents** in this repo (confirmed: dev-map.md:64
"empty in this repo"; AI-GUIDE.md:15). This repo runs **single-Developer mode**. Per the agent
contract, the partition table is therefore omitted — one Developer implements all files in the §8
order. (Were this partitioned, all artifacts here — markdown + two `test-init` script edits — fall to
a single docs/tooling partition anyway; there is no frontend/backend/db split in this task.)

---

## 12. Risk analysis

| # | Risk | Likelihood | Mitigation |
|---|---|---|---|
| R-1 | A seed record (dogfood or template) reproduces an I.6 banned-anchor sequence → I.6 FAIL (boundary "I.6 self-trip", AC-10). Both files are non-exempt and scanned. | Low-Med | §3.1/§3.2 enumerate the 3 banned topic-classes (CLAUDE.md generate/compose, `scaffolding-only`, `全程中文`) and forbid them in records; the seed topics (telemetry, issue-tracker, skill families) naturally avoid all 14 anchors; `verify_all` I.6 is the exhaustive catch the developer runs before declaring done (insight 2026-05-23: rely on verify_all, not hand-reasoning). |
| R-2 | Telemetry decision duplicated as two divergent rationales (left in rule 15 AND added to the new file) → AC-8 violation, drift. | Med | §3.5 mandates REPLACE-with-pointer, not duplicate; the migrated record's `why` is the SAME reason; reviewer checks AC-8 (the two files state one reason). |
| R-3 | Template seed written with a `{{UPPER_SNAKE}}` token or as `.tmpl` → test-init placeholder / no-tmpl-leaked scan FAILs (behavior #7, AC-3). | Low | §3.2 mandates plain `.md`, zero `{{...}}`; the existing recursive scan (`test-init.sh:204`) is the catch; developer runs test-init before declaring done. |
| R-4 | Baseline `test_init_*` counts hand-incremented instead of captured → fabricated-tally class (insight 2026-06-04). | Med | §6 mandates capture-then-paste; the dev-map note codifies it; PM runs the tests (sub-agents have no Bash) and reconciles from real output, including the README test-init badge. |
| R-5 | Cross-shell asymmetry — assertion added to `.ps1` but not `.sh` (or counts reconciled in one shell only) → F.1 parity FAIL / silent count drift. | Med | §6 mandates the symmetric `.sh` twin + symmetric reconcile; F.1 gate catches a missing twin. |
| R-6 | Version bumped in plugin.json but a stamp missed (marketplace/README) → G.3 FAIL; or CHANGELOG heading omitted → G.4 FAIL; or a count string edited by accident → count drift. | Med | §5 enumerates the exact 4 stamps + CHANGELOG heading + the DO-NOT-TOUCH count-claim list; G.3/G.4 catch omissions; this is the well-trodden release path. |
| R-7 | RA/SA pointer drifts into HARD-dependency phrasing (a setup pointer or `BLOCKED`-on-absent) → violates the SOFT model / behavior #10 / boundary "file absent". | Low | §3.4 gives verbatim SOFT prose with the explicit "absent is fine — never a precondition / never blocks" clause; reviewer checks AC-6 for absence of setup pointer & `BLOCKED`. |
| R-8 | Seed body drifts toward a byte-copy of the dogfood (developer pastes real declines into the seed) → AC-3 violation; a generated project ships harness-kit's own declines. | Low | §3.2 + AC-3 require a generic `example-declined-concept` stub; the body must differ from §3.1's nine records; reviewer checks AC-3. |
| R-9 | A future contributor "helpfully" adds a size gate / verify_all check for the file → contradicts OQ-2 / feedback_design_over_guards / out-of-scope #2. | Low | The header's soft-size note explicitly says "no gate enforces size"; the new file itself records the no-guard stance is by design (and `issue-tracker-dedup` / the no-machinery posture is seeded). |

---

## 13. Design notes (deferred-human accepted defaults)

- **OQ-1 = (a) `.harness/rejected-decisions.md`** — co-located with the existing `.harness/` memory
  siblings (insight-index, decision-rubric). Agreed (matches "the four memory kinds live together";
  needs no new directory).
- **OQ-2 = (b) soft size note, NO gate** — designed into the header (§3.1/§3.2); check count stays
  32. Agreed (feedback_design_over_guards; mirrors `docs/tasks.md` manual rotation).
- **OQ-3 = (a) `25-decision-policy.md` canonical**, RA/SA carry pointers — §3.3/§3.4. Agreed
  (the decide-point is exactly when rule 25 loads; reaches every decide-point, not just RA/SA).
- **OQ-4 = (a) replace rule-15 telemetry rationale with a one-line pointer** — §3.5. Agreed (SSOT;
  no second drifting copy; heading kept for discoverability).
- **OQ-5 = (a) MINOR bump to v0.40.0, no count flip** — §5; current `plugin.json` is 0.39.0, next
  minor is 0.40.0. Agreed (distributed template asset = version-worthy, like T-02; counts unchanged
  per T-008). If a concurrent task also bumps, stamp all four + CHANGELOG to the finalized number
  consistently.

On the SOFT-pointer question raised in the dispatch (drop the RA/SA one-liners and rely on rule 25
alone?): **kept them**, because rule 25 loads on the would-ask trigger, not at the RA/SA memory-read
step where the other memory-layer siblings are already read — a one-line pointer at that step makes
the file discoverable without restating the habit (it references rule 25). This is the proven T-02
`CONTEXT.md` placement; the cost is one line per agent. They are pure pointers, so the habit stays
single-sourced (AC-6).

No disagreement with any accepted default; nothing re-opened. No genuine human-reserved decision
arose, so no `BLOCKED: NEEDS-HUMAN` is emitted.

---

## 14. Verdict

**READY.**

The design is complete and self-contained: two new `rejected-decisions.md` files with fully-specified
structure, the nine seed records (one `deferred`, eight `declined`) covering every named batch decline,
authoring constraints (≤6-line header, four-field records, deferral marker, I.6-safe phrasing,
placeholder-free generic seed), the canonical read/append habit in `25-decision-policy.md` with
verbatim insertion text, the one-line SOFT pointers for RA/SA, the single-source reconciliation of the
`15-skill-authoring.md` telemetry entry, the AI-GUIDE memory-layer line, the dev-map row, the
version-stamp set (v0.40.0) with the gates that enforce it, and the test-init assertion +
baseline-reconcile obligation (both shells). Confirmed: **no new `verify_all` check (count stays 32),
no count flip (16 skills / 8 framework agents / 32 checks), no new template placeholder (D.2 stays at
7), placeholder-free seed, not byte-synced by sync-self (mirrors only the 7 script pairs), I.6-safe
(records avoid all 14 banned anchors).** Every artifact reuses an existing repo pattern; a developer
can implement this without further design decisions.
