# 05 — Code Review · T-022 `stream-defer-human`

- Mode: full · Reviewer: code-reviewer · Date: 2026-06-13
- Method: read 01/02/03/04; read every "Files changed" surface against design §2-§9 normative text; tree-wide greps for `AskUserQuestion`, `deferred-human mode`, non-ASCII, stale stop/halt phrasing; spot-checked NO-CHANGE surfaces.
- Note: sub-agent threads carry no Write tool in this harness (per 03:7); content authored by code-reviewer, materialized verbatim by PM.

## Files reviewed (live tree)
- `skills/harness-stream/SKILL.md` (199 lines — matches 04 claim)
- `agents/pm-orchestrator.md` (206 lines, ≤300 — matches 04 claim)
- `.harness/scripts/ambient-prompt.{ps1,sh}` + `skills/harness-init/templates/common/.harness/scripts/ambient-prompt.{ps1,sh}`
- `docs/batches/_template/BATCH_PLAN.md`, `docs/batches/README.md`
- `README.md`, `README.zh-CN.md`, `CHANGELOG.md`, `.claude-plugin/{plugin,marketplace}.json`
- Spot-checked NO-CHANGE: `skills/harness-batch/SKILL.md`, `.harness/rules/25-decision-policy.md`, `docs/getting-started.md`, `docs/dev-map.md`, `AI-GUIDE.md`

## Design-fidelity walk-through (load-bearing seams)

| Design seam | Implementation | Status |
|---|---|---|
| Step g 3rd arm: NEEDS-HUMAN→`needs-human`, queue entry, only `Depends on` descendants, never-perform, never-halt | SKILL.md:125 — verbatim-in-meaning incl. "mark **only** this row's own `Depends on` descendants" + "NEVER perform the action … NEVER halt" | OK |
| FAILED→failed, plain-BLOCKED→blocked stay distinct (honest tallies) | SKILL.md:126 — "any other `BLOCKED` … NOT prefixed `NEEDS-HUMAN` → `blocked`"; step h tally has 4 distinct buckets (:127) | OK |
| Discriminator = `NEEDS-HUMAN` prefix token only, no free-text parse | SKILL.md:125 self-identifying verdict; routes on prefix | OK |
| (c)/(d) bright line in Stop conditions | SKILL.md:143 — verbatim: request defers / guard-rm block halts; :137 names the 3 hazards; :145 drained-pool "does not halt, just finishes" | OK |
| pm-orchestrator: never interactive-ask under stream, never auto-decide reserved point, MUST return structured verdict | pm-orchestrator.md:206 (stream branch) + new Hard rule 6 (:22) | OK |
| Dispatch signal `deferred-human mode: defer, do not ask` in step d only | SKILL.md:120 — present in stream dispatch; NOT in batch (grep confirms) | OK |
| Resume set + `needs-human` | SKILL.md:118 — `needs-human` joined to re-runnable enumeration verbatim | OK |
| Report FIRST `## Needs your input` + `None.` empty rule + entry format | SKILL.md:149 + 168-174 (format matches §3 byte-for-byte) | OK |
| Exit message LEADS with digest | SKILL.md:156 — "leads … BEFORE the done/failed/blocked tally" | OK |
| STREAM_LOG NEEDS-HUMAN line format | SKILL.md:165 — matches §3 | OK |
| Hard rule "needs-human is best-effort like a failure" | SKILL.md:184 | OK |
| Step e verdict list +`BLOCKED: NEEDS-HUMAN` | SKILL.md:121 | OK |
| Description frontmatter +defer clause; allowed-tools −`AskUserQuestion` | SKILL.md:3 / :4 | OK |
| Status enum +`needs-human` | BATCH_PLAN.md:27 — verbatim per §2 | OK |

**No design drift.** The "Deferred-human queue" subsection (SKILL.md:158-174) is the §3 formats placed in-skill so step g's "record the queue entry" resolves to a concrete format — within §3/§7 intent, not a deviation (04:42 disclosed it honestly).

## Findings

### BLOCKING
None.

### MAJOR
None.

### minor
- **m-1 [MAINT]** `skills/harness-stream/SKILL.md:151` — the per-task report row says "link to docs/features/_archived/<slug>/ (or docs/features/<slug>/)" but a `needs-human` / `failed` / `blocked` row is NOT archived (archive-task runs only on delivery). For a deferred row the link target won't exist yet. Pre-existing wording inherited from the failed/blocked case (same gap applies to them today), so not a regression this task introduced; harmless (the row still renders). Optional: note that unfinished rows link to the live `docs/features/<slug>/`. Not blocking.

### NIT
- **n-1 [STYLE]** `CHANGELOG.md:14` — the 0.33.0 entry's first bullet is one long paragraph (denser than the 0.32.0 sub-bullets). Pure preference; format heading itself matches predecessors. No action.

## Binding-condition verification

- **F-1 (ASCII-only ambient edit): SATISFIED.** Grep `[^\x00-\x7F]` on all 4 carriers returns hits ONLY in pre-existing surrounding text (header em-dashes, the `[harness-kit ambient mode — ACTIVE]` line, `union ≡ the message`, `— when it bundles`, `(serial — never parallel)`, `session-scoped —`). The NEW ambiguity sentence (sh:54-55 / ps1:57-58: "If it is ambiguous, do not guess and do not block: record a needs-human clarification note to STREAM_REPORT.md "Needs your input" and keep draining. A plain question/aside creates NO row.") is 0 non-ASCII — colon-separated, no em-dash, no `≡`, no `{{`. Surrounding `≡`/em-dashes were NOT rewritten (out-of-scope respected). No `[Console]::OutputEncoding` dependency added (ps1 still emits at the raw codepage; the false "already neutralizes" clause was not transcribed anywhere — 04:25). The 4 emitted blocks are textually identical across both extensions and dogfood↔template (read-verified; 04 captured `cmp`/CR-strip IDENTICAL).
- **F-2 (batch untouched): SATISFIED.** `skills/harness-batch/SKILL.md` has zero `needs-human`/`NEEDS-HUMAN`/`deferred-human mode` content (grep). It retains its own legitimate `AskUserQuestion` in allowed-tools (:4, pre-existing, out of scope) and keys its strong-signal stop on `FAILED` (:62), not `BLOCKED` (step f :57 maps `BLOCKED`→`blocked`+continue). The CHANGELOG (:18) states this correctly: "halt policy keys on a `FAILED` verdict, not `BLOCKED`, so it merely receives a richer message; its behavior is unchanged" — NO "batch keeps stopping on it" claim anywhere (grep clean in README ×2 + CHANGELOG).
- **Standing AC: SATISFIED (per captured tallies in 04; doc-side independently verified).** Version 0.33.0 four-way: plugin.json:4, marketplace.json:17, README.md:5 badge, README.zh-CN.md:5 badge — all `0.33.0`. CHANGELOG `## [0.33.0] - 2026-06-13` heading matches predecessor format. Counts stated 15 skills / 32 checks (badges show 32/32). pm-orchestrator.md = 206 ≤300. No `{{` in carriers. verify_all 32/0/0 both shells + regression drivers green are PM-held captures (04:18-35); no internal contradiction in the claimed numbers.

## Requirement coverage (AC-1..AC-9 + in-scope 1-12)

| Criterion | Implementation | Status |
|---|---|---|
| AC-1 verify_all 32/0/0, 32/15 unchanged | 04 captures; counts unmoved (badges, CHANGELOG :20) | OK |
| AC-2 version lockstep + `[0.33.0]` heading | 4-way = 0.33.0; CHANGELOG :8 | OK |
| AC-3 no retired-claim trip (I.6) | No banned anchor touched (defer/halt not on banned list); 04 I.6 PASS | OK |
| AC-4 size caps | pm-orchestrator 206, SKILL 199 | OK |
| AC-5 ASCII-only hook text | F-1 above | OK |
| AC-6 taxonomy unambiguous, (c)/(d) bright line explicit | SKILL.md:137/143 + pm-orchestrator:206 | OK |
| AC-7 pm-orchestrator contract binding | :206 structured return + no-auto-decide + Hard rule 6 (:22); reconciled :194-206 | OK |
| AC-8 every behavior surface synced | §9 fan-out all present (SKILL, pm-orch, BATCH_PLAN, batches README, README×2, CHANGELOG, versions) | OK |
| AC-9 adversarial: no mid-drain blocking prompt; report leads; resume free | `AskUserQuestion` gone from stream + all 4 hooks; SKILL.md:149/156/118 | OK |
| In-scope 1-12 | step g routing (125-126), no-halt (125), queue entry 5 fields (165/171), distinct marker (BATCH_PLAN:27), descendants-only (125), no blocking ask (76/115), structured return (pm-orch:206), dispatch signal (120), FIRST report section (149), lead digest (156), free resume (118), ingest defer (76/115) | OK |

## Adversarial reading
- **Over-deferral (swallow a Mode 2/3 decision):** guarded — pm-orchestrator:206 ties the deferral set to "a point the active decision mode reserves" and Hard rule 6 forbids auto-deciding-to-avoid-blocking; rubric-covered calls still self-resolve (25-decision-policy.md:67 step 2). WHO-vs-WHEN composition is stated (CHANGELOG :15, NFR-8). No over-deferral hole.
- **(c)/(d) misread (defer a real guard-rm block):** guarded — SKILL.md:143 + :141 (guard-rm is a hard stop) + pm-orchestrator:206 ("a hard-safety event … is NOT a needs-human deferral"). Tie-break d-wins preserved.
- **Token confusion (NEEDS-HUMAN vs dependency-block):** guarded — routing on the `NEEDS-HUMAN` prefix token only (:125); plain `BLOCKED`→`blocked` (:126); no collision with `BLOCKED ON PARTITION` (a different marker).
- **Queue entry omitting the actual question:** guarded — both formats (:165, :171) mandate verbatim `ask=` / `Ask:` + `unblock=` / `Unblocks when:`; pm-orchestrator return shape carries `<verbatim question> — <what unblocks it>` (:206).

## Internal consistency
Resume (:118) absorbs `needs-human` correctly; K-empty-passes exit (:128), mirror-to-pool (:185), best-effort framing (:137) all compose with the new arm; report `## Needs your input` ordering/format (:149/168-174) matches what step g records (:125); exit message genuinely leads with the digest (:156). No surviving "ask via AskUserQuestion" in the stream (the one hit at `harness-adopt/SKILL.md:242` is an unrelated file-overwrite prompt). NO-CHANGE one-liners (getting-started:45, dev-map:57, AI-GUIDE:93) stay accurate under "(best-effort)" — correctly untouched.

## Verdict
**APPROVED.** 0 BLOCKING, 0 MAJOR, 1 minor (m-1, pre-existing link-target wording, optional), 1 NIT. Design fidelity verbatim-in-meaning across every load-bearing seam; F-1, F-2, and all standing-AC conditions satisfied; requirement AC-1..AC-9 + in-scope 1-12 all covered; no design drift; no stale/contradictory phrasing in the live tree. Route to QA (stage 6).
