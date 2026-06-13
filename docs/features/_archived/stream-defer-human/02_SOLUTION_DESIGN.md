# 02 — Solution Design · T-022 `stream-defer-human`

- Mode: full · Upstream verdict: `01_REQUIREMENT_ANALYSIS.md` = READY FOR DESIGN (verified).
- Object of change: editorial/contract only — `skills/harness-stream/SKILL.md` + `agents/pm-orchestrator.md` + the 4 ambient-hook carriers + the doc/version fan-out. No executable logic beyond the instruction text the ambient hook injects.
- Decision policy: Mode 2 — D-1/D-2 below resolved per `.harness/decision-rubric.md` (Prime directive #1 good operator experience, #2 honest reporting, #3 long-term maintainability). No red line touched (defer **replaces** the blocking-ask mechanism for honoring escalation; it does not change *who* decides — `25-decision-policy.md` red lines stay intact).

## 1. Architecture summary

`/harness-stream`'s per-task drain currently has a 2-way verdict switch (DELIVERED→done, FAILED/BLOCKED→failed/blocked) and two mid-drain blocking prompts (ingest-ambiguity `AskUserQuestion` at SKILL.md:76/115). This design adds a **third verdict arm** — a self-identifying `BLOCKED: NEEDS-HUMAN — …` return from pm-orchestrator marks the row a new `needs-human` status, records a deferred-human queue entry, blocks only the row's `Depends on` descendants, and **continues draining**. Both mid-drain blocking prompts are replaced by "record a needs-human clarification entry and keep draining". All deferred asks aggregate into a new **FIRST** `## Needs your input` section of `STREAM_REPORT.md`, and the exit chat message **leads** with that digest. Resume is unchanged — a `needs-human` row is re-evaluated exactly like `blocked` (SKILL.md:118). No new file, no new `verify_all` check, no schema column.

## 2. Status model (resolves D-1)

**Decision: add a distinct status value `needs-human`** (RA's recommendation), not a `blocked` reason-class. Rationale: honest tallies (Prime #2) — a row deferred for the human must not be counted as "blocked by a failed dependency"; a distinct value makes the report and the dependents rule trivially separable with no parsing of a free-text reason.

**Safety of adding the value (verified):**
- The enum is enumerated only as prose in `docs/batches/_template/BATCH_PLAN.md:27` and `docs/batches/README.md:19` (Column reference / lifecycle). NO `verify_all` check pins the Status enum (grepped — G/I/E/F families never assert pool Status values), and no batch-plan validation step lists allowed values. Adding a value is safe.
- The stream's own transitions compose: resume semantics (SKILL.md:118) treat **every** status that is not "07_DELIVERY DELIVERED / verify_all PASS" as re-runnable — it enumerates `pending / in-progress / failed / blocked` as the re-evaluated set. A `needs-human` row joins that set verbatim, so it is re-runnable on resume exactly like `blocked`/`failed` with no new resume mechanism.

**Exact enum edit** (`docs/batches/_template/BATCH_PLAN.md:27`):

> - **Status** — `pending` (initial) | `in-progress` | `done` | `failed` | `blocked` | `needs-human` (deferred — `/harness-stream` set it aside pending the human input recorded in `STREAM_REPORT.md` "Needs your input"; re-runs on resume once you answer) | `skipped`. The skill writes; the user reads.

`docs/batches/README.md` carries no enum list inline (the lifecycle bullet at :19 only names the column shape), so the only enum edit is the BATCH_PLAN template; the README gets the stream-taxonomy sentence in §7.

## 3. Deferred-human queue mechanism

**Decision: dual-write, no new file type.** (a) A running log line per deferral in `STREAM_LOG.md` (loses nothing if the stream is killed mid-run — `STREAM_LOG.md` is append-only and already written per task at step d/e); (b) report-time aggregation into `STREAM_REPORT.md`'s `## Needs your input` section at exit (the human-facing surface). The report is *derivable* from the log lines, so a mid-run kill loses nothing: re-invoking re-drains the still-`needs-human` rows and re-emits the report. No third file (anti-bloat, Prime #3).

**STREAM_LOG.md entry** (one line, appended at step g when the arm fires; format mirrors the existing dispatch/record lines):

```
<ISO-8601 UTC> · <id> · NEEDS-HUMAN · slug=<slug> · stage=<raising stage/agent> · ask="<verbatim question or missing info>" · unblock="<what input resolves it>"
```

**STREAM_REPORT.md `## Needs your input` entry** (one block per deferred item):

```
- <id> `<slug>` — raised by <stage/agent>
  - Ask: <verbatim question or missing info>
  - Unblocks when: <what input resolves it (pool edit / ADD / /harness-intervene / chat)>
```

Each entry's fields (RA in-scope item 3): **task id, slug, raising stage/agent, the verbatim question/missing-info, what input unblocks it.** Ingest-ambiguity entries (§5) have `id = —` (no row was created) and `stage = ingest`.

## 4. Per-task outcome routing edit (SKILL.md step g)

The verdict switch gains a THIRD arm and the pm-orchestrator return must **self-identify** needs-human so the stream never confuses it with a dependency-`blocked`. **Replace SKILL.md:123-125** (the `g. Best-effort outcome` bullet body) with:

> - **g. Best-effort outcome.** Update the row `Status` from the verdict (keep the verdicts distinct so the report tallies stay honest):
>   - `DELIVERED` → `done`.
>   - `BLOCKED: NEEDS-HUMAN — <verbatim ask> — <what unblocks it>` (the pm-orchestrator's self-identifying needs-human verdict — see `agents/pm-orchestrator.md` "When to stop and ask the user") → set this row `needs-human`; append a `NEEDS-HUMAN` line to `STREAM_LOG.md` and record the queue entry (id, slug, raising stage, verbatim ask, unblock) for the report's "Needs your input" section; mark **only** this row's own `Depends on` descendants `blocked`; **then keep going** to the next ready task. NEVER perform the action the task requested (e.g. a deploy/production-write authorization request defers — it is not executed) and NEVER halt the stream.
>   - `FAILED` → `failed`; any other `BLOCKED` (a dependency-driven or generic block, NOT prefixed `NEEDS-HUMAN`) → `blocked`. In either case also mark every *downstream* task whose `Depends on` chain includes this row `blocked`, **then keep going**. (A task failure is best-effort, never a stream-level stop.)

**Distinguishing needs-human from dependency-blocked:** the pm-orchestrator return string is the discriminator — a needs-human deferral carries the literal `NEEDS-HUMAN` token immediately after `BLOCKED:` (defined in §4 of `pm-orchestrator.md` below); any other `BLOCKED` payload routes to `blocked`. The stream does not parse free text — it switches on the `NEEDS-HUMAN` prefix token only. This keeps tallies honest (`needs-human` ≠ `blocked` ≠ `failed`).

Step **e (Record)** already logs the verdict; add to its parenthetical the new verdict so it is recognized: amend SKILL.md:121 "verdict `DELIVERED`/`BLOCKED`/`FAILED`" → "verdict `DELIVERED` / `BLOCKED` / `BLOCKED: NEEDS-HUMAN — …` / `FAILED`".

Step **h (Report)** tally line (SKILL.md:126) gains the new bucket:

> - **h. Report.** Emit a one-line status: `<id> <verdict> · queue: <pending> pending / <failed> failed / <blocked> blocked / <needs-human> needs-human`.

## 5. pm-orchestrator contract edit (`agents/pm-orchestrator.md`, currently 200 lines — ≤300 cap holds with room)

Two surgical edits. **(A) Replace the "When to stop and ask the user" section (pm-orchestrator.md:193-200)** with a stream-aware version:

> ## When to stop and ask the user
>
> Some points genuinely belong to the human — the active **decision mode** (`.harness/rules/25-decision-policy.md`) decides which (Mode 1: any judgment call; Mode 2/3: a red line, or a rubric-uncovered / irreversible call). Examples:
> - Same stage rolled back 3 times in a row.
> - Conflicting requirements you cannot resolve via the analyst agent.
> - An agent reports a missing external capability (e.g. a tool not in MCP).
> - A safety-critical **action requested** (production write, deployment, signing) — you authorize nothing; the human does.
>
> **How you surface it depends on who dispatched you:**
> - **Interactively (a user-run `/harness` task):** stop, summarize state, ask. Do not improvise.
> - **Under a stream/batch (the dispatch prompt carries `deferred-human mode: defer, do not ask`):** an interactive ask is unavailable. **Return a structured verdict** `BLOCKED: NEEDS-HUMAN — <verbatim question or missing info> — <what input would unblock it>` and stop the task cleanly. Do NOT attempt an interactive ask. Do NOT silently auto-decide a point the active decision mode reserves for the human just to avoid blocking — that violates `25-decision-policy.md`; defer-and-surface instead. (A hard-safety event — `guard-rm` block, `verify_all` FAIL — is NOT a needs-human deferral: report it as the stream's hard-stop signal, unchanged.)

**(B) Add one Hard rule** after pm-orchestrator.md:21 (rule 5):

> 6. **Never auto-decide a reserved point to avoid blocking.** When a decision belongs to the human under the active decision mode, escalate it — interactively if user-run, or as a `BLOCKED: NEEDS-HUMAN — …` verdict when run under a stream/batch. Avoiding a block is never a reason to make the human's call for them.

This reconciles the existing line "Safety-critical action requested" (which previously had no stream path) with stream-driven dispatch (AC-7). Net line delta ≈ +12 → ~212 lines, well under 300 (I.3).

**Dispatch-prompt signal (SKILL.md step d, SKILL.md:120):** the stream already dispatches `harness-kit:pm-orchestrator` with the mode. Amend SKILL.md:120 to add the defer signal to the dispatch prompt:

> **Dispatch `harness-kit:pm-orchestrator` via the `Task` tool** (mode `full` unless the row says otherwise), in its OWN context, **and include in the dispatch prompt the line `deferred-human mode: defer, do not ask` so the sub-agent knows interactive asks are unavailable and returns a `BLOCKED: NEEDS-HUMAN — …` verdict instead** (see `agents/pm-orchestrator.md`). The stream never sees the stage docs, only the return summary.

## 6. Ingest-ambiguity defer (resolves D-2)

**Decision: uniform defer** (RA item 12 / D-2) — every mid-drain ambiguity records a needs-human clarification entry and the stream keeps draining; no driver-conditional exception (Prime #3 one rule over a special case). No guessed row is created.

**SKILL.md:76 (ambient step 1)** — replace `If a message is ambiguous, ask before creating a row — never guess.` with:

> If a message is ambiguous (you cannot file it as exactly one well-formed task), do NOT guess and do NOT block: record a needs-human clarification entry ("clarify before I can file this as a task: <the ambiguous message verbatim>") to the deferred-human queue and keep draining. A plain question/aside creates no row.

**SKILL.md:115 (Procedure 3a)** — replace `if a message is ambiguous, ask via `AskUserQuestion` before creating a row rather than guessing.` with:

> if a message is ambiguous, do NOT guess and do NOT issue a blocking prompt: record a needs-human clarification entry (`stage=ingest`, verbatim message, "clarify before I can file this as a task") to the deferred-human queue and continue draining.

**`AskUserQuestion` removal from `allowed-tools` (SKILL.md:4):** after these two edits, grep confirms `AskUserQuestion` has NO remaining call site in the skill (the only two were :76 and :115). Removing it is the honest signal that this skill never blocks mid-drain. **Edit SKILL.md:4** to drop `AskUserQuestion`:

> allowed-tools: Read, Write, Edit, Glob, Grep, Bash, PowerShell, TodoWrite, Task

(`test-supervisor.{ps1,sh}` matches `AskUserQuestion` only in supervisor-frontmatter asserts, RA §7 — not the stream's list, so removal pins no test driver.)

**The 4 ambient-hook carriers** — `.harness/scripts/ambient-prompt.{ps1,sh}` + `skills/harness-init/templates/common/.harness/scripts/ambient-prompt.{ps1,sh}`. The injected block step 1 currently ends (sh:53-54 / ps1:53-54): `If it is ambiguous, ask before creating a row — do not guess.` **Replace that sentence in all four files** with ASCII-only text (no em-dash, no `≡`, no `{{`):

> If it is ambiguous, do not guess and do not block: record a needs-human clarification note to STREAM_REPORT.md "Needs your input" and keep draining. A plain question/aside creates NO row.

**Lockstep discipline (T-021):** the edit is byte-identical across the two extensions per file (dogfood↔template byte-identical per extension), and ps1↔sh identical after CR-strip. The replacement sentence uses ASCII `--`-free phrasing (uses a colon, not a dash) to stay clear of the existing non-ASCII dash family. **Scope note:** this edit changes ONLY the one ambiguity sentence; the surrounding block keeps its existing (pre-T-022) text including its existing em-dashes — rewriting them is out of scope (would balloon the diff and risk I.6), and the 2026-06-12 console-encoding fix already neutralizes the pwsh mojibake risk for the *existing* chars. The NEW sentence is ASCII-only per AC-5 so we introduce no new non-ASCII.

## 7. Consolidated end-of-run surface (SKILL.md "On stream completion" + step h)

**STREAM_REPORT.md gains a FIRST, prominent section.** Amend SKILL.md:146-153 ("On stream completion") so `## Needs your input` is the FIRST section of the report, before the per-task rows:

> Write `docs/batches/<pool-id>/STREAM_REPORT.md`, **leading with a `## Needs your input` section** (FIRST, before the per-task table) enumerating every deferred item — each `needs-human` row AND each ingest-ambiguity clarification — using the entry format in "Deferred-human queue" (id, slug, raising stage, verbatim ask, unblock). **If there are no deferred items, the section reads `None.`** Then:
> - Per-task row: `<id> | <slug> | <verdict> | link …` (unchanged).
> - Aggregate: done / failed / blocked / **needs-human** / skipped counts, passes run, final `verify_all` summary.
> - The failed / blocked / needs-human rows remain resume-resolvable: supply the input (pool edit / `ADD` / `/harness-intervene` / chat), re-invoke `/harness-stream <pool-id>`, and the stream re-runs only the unfinished rows via the existing resume semantics (a row whose `07_DELIVERY.md` is not DELIVERED is re-evaluated and runnable — SKILL.md "Resume semantics").
> - Stop reason if a hard stop fired.

**The exit chat message LEADS with the human-ask digest.** Add a sentence to "On stream completion" (and it governs step h's final emission):

> On exit, the message to the user **leads** with the needs-input digest — the count of deferred items and each ask verbatim — BEFORE the done/failed/blocked tally. A run that completed with deferrals is not "all done": surface "N item(s) need your input" first. If the queue is empty, lead with the normal tally.

**Resume wording confirmed:** no new mechanism. SKILL.md:118 resume semantics already re-evaluate any non-DELIVERED row; `needs-human` is added to that re-runnable set in §2. The report's "Unblocks when" field tells the user exactly which channel supplies the input.

## 8. Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| Per-task event log | `STREAM_LOG.md` append lines (step d/e) | `skills/harness-stream/SKILL.md:120-121` | Reuse — add one `NEEDS-HUMAN` line format |
| Terminal summary surface | `STREAM_REPORT.md` writer | `skills/harness-stream/SKILL.md:144-153` | Extend — prepend `## Needs your input` + new count |
| Dependents-blocking rule | `Depends on`-scoped `blocked` propagation | `skills/harness-stream/SKILL.md:125` | Reuse verbatim for needs-human descendants |
| Resume of unfinished rows | non-DELIVERED = re-evaluated/runnable | `skills/harness-stream/SKILL.md:118` | Reuse — `needs-human` joins the set, no new mechanism |
| Stop-and-ask contract | "When to stop and ask the user" | `agents/pm-orchestrator.md:193-200` | Extend with stream-aware defer return |
| Dispatch prompt carrying mode | step d Task dispatch | `skills/harness-stream/SKILL.md:120` | Extend — add defer signal line |
| Ambient ambiguity instruction | injected block step 1 | `.harness/scripts/ambient-prompt.{ps1,sh}` + 2 template copies | Edit one sentence, 4-file lockstep |
| Status enum | prose enumeration | `docs/batches/_template/BATCH_PLAN.md:27` | Extend — add `needs-human` value |
| Distinct deferred status value | (none — `blocked` conflates dependency-block) | — | New value `needs-human` justified (honest tallies) |

No new dependency, no new file, no new `verify_all` check (re-confirmed: RA §4 / decision-rubric "a new check must prevent a concrete hazard" — the hazard here is doc drift, already covered by G.3/G.4/I.6; the behavior is editorial).

## 9. Doc fan-out plan + version (0.32.0 → 0.33.0)

| Surface | File:line | Edit |
|---|---|---|
| Skill description frontmatter | `skills/harness-stream/SKILL.md:3` | Append: "A task that needs human input (clarification, a human-reserved decision, or authorization for a safety-critical action) is **deferred** — set aside, its dependents blocked, the stream keeps draining — and surfaced together at stream end; it does not halt the stream." Keep ≤ frontmatter norm. |
| AskUserQuestion in allowed-tools | `skills/harness-stream/SKILL.md:4` | Remove `AskUserQuestion` (§6) |
| Ambient step 1 ambiguity | `skills/harness-stream/SKILL.md:76` | §6 |
| Procedure 3a ambiguity | `skills/harness-stream/SKILL.md:115` | §6 |
| Dispatch defer signal | `skills/harness-stream/SKILL.md:120` | §5 |
| Record verdict list | `skills/harness-stream/SKILL.md:121` | §4 |
| Step g outcome switch | `skills/harness-stream/SKILL.md:123-125` | §4 (third arm) |
| Step h tally | `skills/harness-stream/SKILL.md:126` | §4 |
| Stop conditions (taxonomy clarity) | `skills/harness-stream/SKILL.md:134-142` | Add ONE sentence: "A class-(c) needs-human deferral is NOT a hard stop — only these three hazards halt. The bright line: a *request for* a safety-critical action **defers** (the action is not performed); a `guard-rm` *block of a destructive command already attempted* **halts**." |
| On stream completion | `skills/harness-stream/SKILL.md:144-153` | §3/§7 (report + queue + chat-lead) |
| Hard rules | `skills/harness-stream/SKILL.md:155-163` | Add: "A needs-human deferral is best-effort like a failure — set the row `needs-human`, block only its `Depends on` descendants, surface at end, never halt and never perform the deferred action." |
| pm-orchestrator stop-and-ask | `agents/pm-orchestrator.md:193-200` | §5(A) |
| pm-orchestrator hard rule | `agents/pm-orchestrator.md:21` (after) | §5(B) |
| Status enum | `docs/batches/_template/BATCH_PLAN.md:27` | §2 |
| batches README Streams bullet | `docs/batches/README.md:28` | Add: "A task needing human input is **deferred** (`needs-human` status) — set aside with its dependents blocked, the stream keeps going, and all asks are surfaced in `STREAM_REPORT.md`'s `## Needs your input` section." |
| README headline stream bullet | `README.md:21` | Append a "deferred-human" clause to the Best-effort sentence (parallel to zh) |
| README.zh-CN headline | `README.zh-CN.md:21` | Mirror clause in Chinese |
| README milestone row | `README.md:275` (after v0.32.0) | New append-only `\| 0.33.0 \| done \| **Stream defer-human** … \|` row; do NOT rewrite v0.22/0.32 rows |
| README.zh-CN milestone | `README.zh-CN.md` (milestone table) | Mirror row |
| CHANGELOG | `CHANGELOG.md:7` (top) | New `## [0.33.0] - 2026-06-13` entry (G.4-gated heading) |
| Version manifests (G.3) | `.claude-plugin/plugin.json:4`, `.claude-plugin/marketplace.json:17` | `0.32.0` → `0.33.0` |
| README badges (G.3) | `README.md:5`, `README.zh-CN.md:5` | `version-0.32.0` → `version-0.33.0` |

**Version math (verified against G.3/G.4 logic, verify_all.sh:350-371 / :686-786):** G.3 is the 4-way version equality (plugin.json + marketplace.json + 2 README badges) — all four bump to 0.33.0. G.4 reads **counts** (32/32 etc.) against plugin.json version and requires a `[<version>]` CHANGELOG heading — counts stay 15 skills / 32 checks (no new skill, no new check), so only the `[0.33.0]` heading is the G.4-relevant add. `AI-GUIDE.md:93` workflow-entry stream trigger text does NOT change (triggers unchanged) — no edit. `docs/dev-map.md:57` one-liner ("best-effort, picks up mid-run additions") describes the mechanism, not the stop taxonomy — its phrasing stays accurate, no edit (RA "only if incomplete"). `docs/concepts.md` / `docs/workflow.md` grep-clean for stream stop prose — no edit.

## 10. Risk analysis

| # | Risk | Mitigation |
|---|---|---|
| a | A stage agent or the stream "helpfully" emits a blocking prompt despite the defer rule. | Defer is the **unambiguous default**: `AskUserQuestion` is removed from `allowed-tools` (SKILL.md:4) so the skill physically cannot block-ask; the dispatch prompt carries `deferred-human mode: defer, do not ask` (§5); pm-orchestrator's contract names the structured return as the ONLY stream path. Three reinforcing layers, frontmatter being the enforceable one (insight 2026-05-19 "frontmatter is the only enforceable boundary"). |
| b | needs-human silently swallows a point the decision mode reserves for the human (auto-decided to avoid blocking). | New pm-orchestrator Hard rule 6 (§5B): "Never auto-decide a reserved point to avoid blocking" — defer-and-surface, never auto-decide. The composition is explicit (NFR-8): decision policy chooses *who*; this feature chooses *when* (end, not mid-drain). Red lines in `25-decision-policy.md` unchanged. |
| c | Drift between the SKILL ambient section and the 4 hook files. | §6 specifies the byte-identical sentence for all four files with the T-021 lockstep discipline (ps1↔sh CR-strip identity, dogfood↔template per-extension byte-identity); QA verifies via `cmp`/CR-strip compare (§11). |
| d | Over-deferral — deferring something the AI could decide under Mode 2/3. | The rule is scoped: defer **only** (i) a true ambiguity / missing capability, or (ii) a point the *active decision mode genuinely reserves* for the human — NOT "anything mildly uncertain". pm-orchestrator first applies the rubric (`25-decision-policy.md` step 2: rubric-covered → decide and log), and defers only what step 3 escalates. Wording in §5(A) ties the deferral set to the decision-mode reservation, not to uncertainty. |
| e | The (c)/(d) bright line misread — a real `guard-rm` block deferred instead of halting. | The Stop-conditions edit (§9, SKILL.md:134-142) states the bright line verbatim: "a *request for* a safety-critical action defers (action not performed); a `guard-rm` *block of a destructive command already attempted* halts." pm-orchestrator §5(A) repeats it ("a hard-safety event … is NOT a needs-human deferral"). The same-task tie-break (RA §5) — d always wins — is the existing hard-stop precedence; needs-human never overrides a hard stop. |

## 11. Verification plan (for QA)

- **verify_all 32/32 both shells** (PS + bash; PM runs) — count stays 32, skills 15 (AC-1).
- **G.3 green** — 4-way version all = 0.33.0 (plugin.json, marketplace.json, both README badges). **G.4 green** — count claims unchanged (32/15), `[0.33.0]` CHANGELOG heading present (AC-2).
- **Ambient hook 4-file byte-lockstep** — `cmp` dogfood↔template per extension; CR-strip ps1↔sh identity; **no `{{` token** (test-init placeholder scan) and **no non-ASCII** in the NEW sentence (AC-5; grep the edited sentence for `[^\x00-\x7F]`).
- **I.6 clean** — new prose introduces no banned anchor; the "best-effort never halts" wording is extended, not contradicted — re-check only if a banned anchor is touched (it is not). If untouched, no 4-file I.6 lockstep edit (insight 2026-06-08).
- **Size caps** — `agents/pm-orchestrator.md` ≤300 (≈212 after edit; I.3); SKILL.md and edited docs under rule-70 caps (I.1/I.2).
- **Adversarial doc-reading probes (AC-9):**
  - "Does any unattended-drain surface still tell the stream to block on `AskUserQuestion` mid-drain?" → expect NO hit (grep `AskUserQuestion` in SKILL.md + 4 hooks = 0).
  - "Is the bright line between safety-request-defer and guard-rm-halt unambiguous?" → a reviewer can classify both into distinct buckets from SKILL.md:134-142 + pm-orchestrator §5(A).
  - "Does a `needs-human` row resume correctly?" → SKILL.md resume semantics enumerate it among re-runnable statuses (§2).
  - "Do tallies separate needs-human from failed/blocked?" → step h + report aggregate carry a distinct `needs-human` count.
  - "Does the exit message lead with the human-ask digest?" → §7 governs step h.

## 12. Partition assignment

Single-developer mode — `.harness/agents/` carries no `dev-*.md` files in this repo (confirmed: empty per AI-GUIDE.md:15). The whole change is editorial Markdown + hook-text in one cohesive surface; one Developer applies all edits. No partition table needed; dispatch order is the single Developer.

## 13. Out-of-scope clarifications

- `/harness-batch` halt policy is unchanged; it simply receives a richer `BLOCKED: NEEDS-HUMAN — …` message and keeps stopping on it (D-4, non-goal preserved).
- No new pool-schema **column** (only a Status **value**).
- No parallelism, no idle/background progress, no duplicate-suppression of re-deferred asks (RA §5 — v1).
- The three hard-safety stops (class d) are not weakened.
- Existing non-ASCII chars in the surrounding hook block are NOT rewritten (scope/I.6 risk); only the one new sentence is added ASCII-only.

## 14. Verdict

**READY FOR GATE.** No upstream gap; all design-shaping decisions (D-1 distinct `needs-human` value; D-2 uniform defer; `AskUserQuestion` removed from allowed-tools; dual-write log+report queue, no new file; pm-orchestrator structured return + new hard rule) are resolved with file:line citations and verbatim normative text. Version 0.32.0 → 0.33.0; counts unchanged (15/32). A Developer can apply this without further design decisions.
