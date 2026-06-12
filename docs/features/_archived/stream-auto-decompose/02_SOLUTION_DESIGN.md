# 02 — Solution Design: stream-auto-decompose (T-021)

> Mode: full · Architect: solution-architect · Date: 2026-06-12
> Input: `docs/features/stream-auto-decompose/01_REQUIREMENT_ANALYSIS.md` (verdict READY)
> Decision policy: Mode 2 — autonomous calls recorded in §11. Change class: Markdown-skill + hook-script-text only; zero executable logic, zero schema change.

## 1. Architecture summary

`/harness-stream` gains one new in-skill contract section ("Ingest triage") that both stream-authored ingest channels (Procedure 3a chat ingest, ambient turns) bind to by explicit pointer; the hard rule at `skills/harness-stream/SKILL.md:141` is amended from "never invent rows" to "rows may be *derived* only by partitioning one user requirement, union ≡ original"; the four hand-lockstep ambient hook files get a +2-line pointer-level update; and the doc fan-out (README ×2, CHANGELOG, batches README, version bump to 0.32.0) is synced. The triage criteria live exactly once (in the SKILL), the hook carries a pointer — drift between carriers is eliminated by construction, not guarded.

## 2. Affected modules

| File | Action |
|---|---|
| `skills/harness-stream/SKILL.md` | EDIT — object of change (§3) |
| `.harness/scripts/ambient-prompt.ps1:46-62` / `.sh:43-59` | EDIT — instruction block (§4) |
| `skills/harness-init/templates/common/.harness/scripts/ambient-prompt.{ps1,sh}` | EDIT — same block, byte-lockstep per pair (§4) |
| `README.md:5,21,274` / `README.zh-CN.md:5,21,276` | EDIT — bullet sentence, roadmap row, version badge (§5) |
| `CHANGELOG.md` | EDIT — new `[0.32.0]` section (§5) |
| `.claude-plugin/plugin.json:4` + `.claude-plugin/marketplace.json:17` | EDIT — `0.31.0` → `0.32.0` (§5) |
| `docs/batches/README.md:33` | EDIT — one triage sentence (§5) |
| `AI-GUIDE.md:93`, `.harness/rules/25-decision-policy.md:53`, `skills/harness-intervene/SKILL.md:42`, `.harness/rules/65-intervention.md:53`, `skills/harness-batch/SKILL.md:71`, `docs/harness-stream.html` | CHECK-ONLY / NO CHANGE — verified in §5 |

No new files, scripts, hooks, checks, or dependencies.

## 3. SKILL.md editorial architecture (the object of change)

Current file: 153 lines. Post-edit budget: **≤ 198 lines** (see Risk R2). Six edit sites:

### 3.1 New section `## Ingest triage (one row or many)` — inserted between line 82 ("Ambient vs the `/loop` chat driver" section end) and line 84 (`## Procedure`)

Placement rationale: adjacent to BOTH consumers (ambient section ends :82, Procedure starts :84); both bind to it with a one-line pointer, so the criteria exist once in the file. Ship this text (≤ 34 lines; normative payload, Developer applies verbatim modulo line-wrap):

```markdown
## Ingest triage (one row or many)

Applies wherever the STREAM normalizes natural language into pool rows: chat-channel
ingest (Procedure 3a) and ambient turns. It NEVER applies to rows the user authored —
an `ADD <slug> — <goal>` line or a hand-written pool row is honored verbatim as ONE
task, at the user's chosen granularity, and an existing row is never re-triaged.

**Triage test — decompose only when BOTH hold:**
1. The message contains two or more outcomes that are each *independently verifiable
   deliverables* — each could pass its own QA and reach DELIVERED on its own (signals:
   an "and"-chain or enumeration of distinct outcomes; outcomes touching distinct
   subsystems or artifact classes; phased phrasing — "X, then Y" / "先…再…").
2. No single one-sentence Goal can state the requirement without conjoining those outcomes.

**NOT complex (always one row):** a single deliverable with wide fan-out (one change
echoed across many files); long prose describing one outcome; a list of acceptance
details for one outcome.

**When the test fires, write N ≥ 2 `pending` rows (same columns, no schema change):**
- **Slug:** derive a base slug from the requirement; every sub-row slug starts with
  `<base>-` (e.g. `csv-export-endpoint`, `csv-export-button`). Add one provenance line
  to the pool's `## Notes` section: `Decomposed <base>-* (N rows) ← "<original
  requirement, one line>" (YYYY-MM-DD)`.
- **Goal:** one sentence, exactly ONE independently verifiable deliverable per row.
  **Union invariant:** the union of the sub-row Goals must equal the original message —
  no invented scope, no dropped scope. If any requested outcome cannot be placed in
  exactly one row, that is ambiguity: ask, don't guess.
- **Depends on:** chain only REAL consumption (row B uses an artifact or behavior row A
  produces). Independent siblings stay unchained (`—`) so a failed sibling never blocks them.
- **Mode:** per row via the normal workflow-entry mapping (default `full`; a pure
  research sub-step may be `explore`).
- **Fixed point:** every produced row must FAIL test 1 on its own (exactly one
  deliverable), so re-running triage on any produced row returns it unchanged.
- De-duplicate each sub-row against existing slugs/goals, as for any new row.
- **Announce** in the ack which IDs/slugs were created from the requirement and the
  dependency shape; correct a wrong split via the pool, `SKIP`, or `/harness-intervene`.

A requirement that fails the test gets exactly today's one-row path — no marker, no
announcement. Once written, derived rows are ordinary pool rows: resume, de-dup, `SKIP`,
edits, and failure semantics apply identically.
```

### 3.2 Procedure 3a (`SKILL.md:94`) — replace the singular normalization clause

Old: `**normalize it into a `pending` row** in `BATCH_PLAN.md` (assign …)`
New: `**normalize it into `pending` row(s) per "Ingest triage" above** — one row, or N decomposed rows when the triage test fires (assign `ID`/`Slug`/`Goal`/`Mode`/`Depends on` per row)` — rest of the sentence (de-dup, ambiguity-ask) unchanged.

### 3.3 `ADD` bullet (`SKILL.md:95`) — append the AD-1 clarifier

Append to the `ADD` bullet: `(user-authored: honored verbatim as ONE row, never triaged)`. This lands the AD-1 clarifying clause here instead of editing the three CHECK-ONLY files (decision D-4).

### 3.4 Ambient step 1 (`SKILL.md:76`) — relax `Mode=full`, bind to triage

New: `**Ingest.** If your message reads as a requirement (not a question or aside), normalize it into `docs/batches/default/BATCH_PLAN.md` per "Ingest triage" below — one `pending` row, or N decomposed rows when the triage test fires (`Mode` per row, default `full`), de-duplicating against existing slugs/goals first. If a message is ambiguous, ask before creating a row — never guess. A plain question/aside creates **no** row.`

### 3.5 Hard rule (`SKILL.md:141`) — exact replacement (FR-7)

Old line: `- **Never widen scope silently beyond what the user asked.** New rows must come from the user (chat / pool / `ADD`), never invented by the stream.`

New (ship verbatim):

```markdown
- **Never widen scope beyond what the user asked.** Every row traces to a user
  requirement (chat / pool / `ADD`). The stream may *derive* rows only by partitioning
  ONE user requirement at ingest (see Ingest triage), and the union of the derived
  Goals must equal the original requirement — no invented scope, no dropped scope.
  Work the user did not ask for is never added; rows the user authored (`ADD` lines,
  hand-written pool rows) are never split or rewritten.
```

Subset check: the old meaning ("rows come from the user, the stream invents nothing") is strictly preserved — "every row traces to a user requirement" + "work the user did not ask for is never added". `.harness/rules/25-decision-policy.md:52-53` ("new features / tasks the user did not request are never invented autonomously (mirrors the `/harness-stream` rule)") stays truthful unedited — verified against the new wording. I.6 safety: the banned list (`verify_all.sh:521-536`) contains only CLAUDE.md-composition entries + the zh `全程/中文` entry; no proposed sentence contains any banned ordered-anchor sequence (AD-4: the retired sentence is NOT added to the list).

### 3.6 description (`SKILL.md:3`), Anti-patterns (`:144-149`), Cost (`:151-153`)

- **description:** insert before "Use when you want to fire requirements…": `Complex multi-part requirements are triaged at ingest and auto-decomposed into N dependency-staged rows (a simple requirement stays one row; ADD lines and hand-written rows are honored as-written).` (rule 15 P1: this is the trigger phrase for "把大需求自动拆小" type asks.)
- **Anti-patterns:** add one bullet: `- **Do not** decompose a single deliverable just because it fans out across many files, nor an `ADD` line or hand-written pool row — triage applies only where the stream normalizes natural language, and only when the triage test fires.`
- **Cost (`:153`):** append: `A decomposed requirement costs N × (full 7-stage) — the same as if you had filed the N rows by hand; triage itself adds no overhead.`
- Intro `:9`, timing section `:47` ("mirrors any chat-supplied requirement into the pool"): CHECK-ONLY — neither makes a 1:1 claim; "mirrors the requirement" stays true when the mirror is N rows.

## 4. Ambient carrier lockstep (4 files, FR-11 / NFR-1)

Decision D-3: the hook block gets a **pointer + one-line contract summary**, not the criteria — criteria live once in SKILL §Ingest triage. Replace step 1 of the emitted block (currently `ambient-prompt.ps1:52-55` / `.sh:49-52`, identical in the two template copies) with (ship verbatim; +2 emitted lines, NFR-1-compliant):

```text
  1. If THIS user message reads as a requirement (not a question/aside), normalize it
     into the default pool: ONE `pending` row, or — when it bundles several independently
     verifiable deliverables — N rows per skills/harness-stream/SKILL.md "Ingest triage"
     (shared slug prefix, real `Depends on` only, union ≡ the message; Mode per row,
     default full). De-duplicate against existing slugs/goals first. If it is ambiguous,
     ask before creating a row — do not guess. A plain question/aside creates NO row.
```

Mechanics (defect-class citations):
- The text sits inside a PS single-quoted here-string `@'…'@` (`ambient-prompt.ps1:46-62`) and a quoted heredoc `<<'EOF'` (`ambient-prompt.sh:43-59`) — both literal, no interpolation, no `{{…}}` token introduced (insight 2026-06-08 placeholder-scan stays green).
- Parity contract (matches AC-3): **ps1 ↔ sh = CR-stripped textual identity** of the emitted block (each file keeps its native EOL; PS here-strings inherit the file's CRLF — do not chase byte-identity across shells, per the insight-family 2026-06-08 WriteAllText/newline line); **dogfood ↔ template = byte-identity per extension** (`fc`/`cmp` of the whole file pair is the cheapest assertion since the pairs are currently byte-identical — verified by reading both `.sh` copies).
- All four files edited in one commit; no `sync-self` involvement (`AI-GUIDE.md:81`: ambient pair is hand-lockstep, not in the mirror set).

## 5. Doc fan-out plan (every EDIT precise; G-gates honored)

| Surface | Exact edit |
|---|---|
| `README.md:21` | Append to the stream bullet, before the "**Ambient mode:**" sentence: `Complex multi-part requirements are auto-decomposed at ingest into dependency-staged sub-task rows (simple ones stay one row; rows you author — \`ADD\` / hand-written — run as-written).` |
| `README.md:274` (after the 0.31.0 row) | New roadmap row: `\| 0.32.0 \| done \| **Stream ingest triage / auto-decomposition**: /harness-stream (chat-under-/loop + ambient) triages each normalized requirement — a complex multi-part requirement becomes N dependency-staged pool rows (shared slug prefix + Notes provenance line, real deps only, Mode per row), a simple one stays 1 row; hard rule amended to the union-equivalence invariant (derive by partitioning one user requirement; never invent or drop scope; user-authored rows never split). Ambient hook block updated in 4-file lockstep. No schema change; \`verify_all\` stays 32 checks, skills stay 15. \|` |
| `README.zh-CN.md:21` + after `:276` | Mirror both edits in zh (bullet sentence + roadmap row). |
| `README.md:5` + `README.zh-CN.md:5` | Version badge `version-0.31.0-blue` → `version-0.32.0-blue`. Not G.4-gated (G.4 pins only the count badge `verify__all-32%2F32`, `verify_all.sh:750-751`) but required by repo convention (`CHANGELOG.md:23` "plugin.json, marketplace.json, both README badges"). RA §6 gap — added here. |
| `CHANGELOG.md` | New top section `## [0.32.0] - 2026-06-12`, heading `### Added — Stream ingest triage: /harness-stream auto-decomposes complex requirements (T-021)`. Bullets: SKILL triage section + amended hard rule (union invariant); 4-file ambient hook lockstep edit (+2 emitted lines); README ×2 + docs/batches/README sentence; closing line `Version 0.31.0 → 0.32.0 (plugin.json, marketplace.json, both README badges). Skill count stays **15**; \`verify_all\` stays **32** checks; no I.6 banned/exempt-list change; no pool-schema change.` CHANGELOG is I.6-exempt (`verify_all.sh:516-519`) — wording is unconstrained, but keep the union phrasing anyway. |
| `.claude-plugin/plugin.json:4`, `.claude-plugin/marketplace.json:17` | `"version": "0.32.0"`. |
| `docs/batches/README.md:33` | After the "New work enters a running stream…" sentence, add: `At ingest the stream triages each requirement it normalizes: a complex multi-part one is decomposed into several dependency-staged rows (shared slug prefix + a \`## Notes\` provenance line); rows you write yourself are honored as-is.` |

**G-gate compliance (read, not assumed):** G.4 (`verify_all.sh:700-786`) checks (a) count-anchored claims in 11 files — all stay `32`, untouched (no new check, AD-5); (b) `CHANGELOG.md` contains a `[<plugin.json version>]` heading (`:776`) — satisfied by the `[0.32.0]` section landing in the same commit as the plugin.json bump. We add **no** new G.4 rows, so the same-file expect-uniqueness trap (insight 2026-06-06) is not re-entered. G.1/G.2 count skills — count stays 15. New roadmap rows are shape-safe: G.4's count patterns are anchored (`(N checks)` etc., `verify_all.sh:710-712`), and the proposed row text contains no `N checks`/`N/N`-shaped claim other than the literal "32 checks", which matches the live count.

**CHECK-ONLY verdicts (verified this design):** `AI-GUIDE.md:93` stream trigger text makes no granularity claim — no edit. `.harness/rules/25-decision-policy.md:53` stays truthful (§3.5). `skills/harness-intervene/SKILL.md:42`, `.harness/rules/65-intervention.md:53`, `skills/harness-batch/SKILL.md:71` — `ADD` semantics unchanged (AD-1); the clarifier lands in harness-stream only (D-4). `docs/harness-stream.html` — version-pinned v0.22.0 snapshot, NOT refreshed (D-5, per AD-6).

## 6. Sequence / flow (one ambient turn, complex message)

```
user msg ──UserPromptSubmit hook──> [ambient block: "ONE row, or N rows per SKILL 'Ingest triage'"]
  └─> agent loads skills/harness-stream/SKILL.md
        1. ambiguity gate (unchanged, first)        — ambiguous? ask, stop.
        2. triage test (§3.1): both criteria hold?  — no  → 1 row, today's path.
                                                    — yes → N rows: <base>-* slugs,
                                                      union check, real deps only,
                                                      Mode/row, Notes provenance line,
                                                      per-row de-dup, announce split.
        3. drain frontier via pm-orchestrator (unchanged, SKILL.md:97-106)
           failure semantics unchanged: failed row blocks transitive dependents only.
```

Resume answer (dispatch Q-e, stated for QA): on a later session/resume, derived rows are **indistinguishable from user-filed rows by design** — resume semantics (`SKILL.md:97`) read only `Status`/`07_DELIVERY.md`; the Notes line is inert provenance for the human reader; the stream never re-triages an existing row (§3.1 first paragraph).

## 7. Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| Pool row schema + per-row de-dup | batch plan format | `docs/batches/_template/BATCH_PLAN.md:9`, `skills/harness-stream/SKILL.md:94` | Reuse unchanged (FR-4) |
| Failure/blocking semantics for groups | best-effort + `Depends on` blocking | `skills/harness-stream/SKILL.md:102-104` | Reuse as-is (FR-8); no group semantics |
| Per-row Mode assignment | workflow-entry trigger table | `AI-GUIDE.md:86-99` | Reuse by reference |
| Ambiguity gate | "ask before creating a row" | `skills/harness-stream/SKILL.md:76,94` | Kept first, unchanged (FR-9) |
| Provenance carrier | `## Notes (optional)` section | `docs/batches/_template/BATCH_PLAN.md:15` | Reuse — no new column (FR-5) |
| Decomposition shape precedent | batch worked example (3 csv-export rows, real dep chain) | `docs/batches/README.md:43-57` | §3.1 slug example mirrors it deliberately |
| User correction channels | pool edit / `SKIP` / intervene | `skills/harness-stream/SKILL.md:96`, `skills/harness-intervene/SKILL.md` | Reuse (FR-10 announcement points at them) |
| Hook carrier + lockstep discipline | ambient instruction block | `.harness/scripts/ambient-prompt.{ps1,sh}:46-62/43-59`, `AI-GUIDE.md:81` | Extend text only; architecture untouched |

No new module, dependency, or mechanism — the entire feature composes existing surfaces (NFR-4).

## 8. Risk analysis

| # | Risk | Mitigation (designed-in, not guarded) |
|---|---|---|
| R1 | **Over-decomposition** — verbose single-deliverable asks get split | Conjunctive two-part test (BOTH must hold) + three explicit NOT-complex counter-examples in the SKILL (§3.1) + anti-pattern bullet (§3.6) + announcement gives the user a same-turn correction path (FR-10). QA probe (iv) targets exactly this. |
| R2 | **SKILL.md budget creep** — 153 lines + ~40 net | Hard budget ≤ 198 lines (§3). No `verify_all` I.* row gates skills (I.1-I.5 cover AI-GUIDE/rules/agents/insight/tasks), so this is rule-15-P5 discipline, not a gate; if §3.1 cannot fit, the Developer trims wording, never the contract terms (slug/union/deps/mode/fixed-point/announce). |
| R3 | **I.6 self-trip** in new wording | Banned list read (`verify_all.sh:521-536`): all entries are CLAUDE.md-composition + zh-policy anchors; no proposed sentence contains a banned ordered-anchor sequence. CHANGELOG + docs/features/ are exempt anyway (`:516-519`). Final authority: the verify_all RUN (insight 2026-05-23: run, don't reason). |
| R4 | **Carrier drift** (SKILL vs hook text) | Root-cause design: criteria single-sourced in SKILL; hook holds a pointer + 1-line summary whose only semantic load is "one row or N per SKILL". A stale hook in an existing project still opens with "Act per skills/harness-stream/SKILL.md" — the plugin-current SKILL governs; the hook self-heals via `/harness-upgrade` (its S2 refresh set already includes the ambient pair, `CHANGELOG.md:15`). |
| R5 | **ps1/sh emission mismatch** (known defect class, insight 2026-06-08) | Literal here-string/heredoc only — no interpolation; parity contract fixed at CR-stripped ps1↔sh identity + dogfood↔template byte-identity (§4); QA asserts by running both hooks with the flag present and `cmp`-ing CR-stripped output. |
| R6 | **Unfaithful union** (dropped/invented scope in a split) | The union invariant is the amended HARD rule (§3.5), not advice; "cannot place an outcome in exactly one row" is defined as ambiguity → ask (FR-9 step 3); announcement (FR-10) exposes the split for immediate correction. |

## 9. Migration / rollout

Text-only; no data, no flags, no migration. Backwards compatibility: existing pools and user-authored rows are untouched (AD-2); old `STREAM_LOG`/`REPORT` formats unchanged. Rollout: single commit, version 0.32.0; consumers get the new SKILL instantly via `/plugin update` (plugin-provided), while their project-local ambient hook text lags until `/harness-upgrade` — benign by design (R4). Rollback = revert the commit; no state to unwind.

## 10. Out-of-scope (inherited verbatim from RA §3)

`ADD` lines and pre-existing rows never triaged; `/harness-batch`, `/harness-plan`, parallelism, pool schema, verify_all check set, I.6 list, hook architecture, mid-task re-decomposition — all unchanged. This design adds nothing beyond RA §2.

## 11. Recorded design decisions (Mode 2)

- **D-1 (AC-1 refinement — flag for Gate Reviewer):** the triage criteria live ONCE in the new §Ingest triage; Procedure 3a and the ambient section each carry a *binding* pointer ("normalize per 'Ingest triage'"), not a duplicate of the criteria. A strict reading of AC-1 ("both contain the triage instruction with FR-2 criteria") would duplicate ~20 lines twice inside one 153-line file — exactly the intra-file drift class the operator's design-over-guards preference exists to eliminate, and a rule-15-P2/P5 violation. The intent (an agent reading either channel is bound by the criteria) is met. Gate should confirm or bounce this reading.
- **D-2:** traceability = shared `<base>-` slug prefix **plus** one `## Notes` provenance line (prefix alone can collide with coincidentally-similar pre-existing slugs; the Notes line makes grouping positively decidable from `BATCH_PLAN.md` alone — FR-5).
- **D-3:** hook block = pointer + one-line contract summary, +2 emitted lines (NFR-1 lean bound), criteria not duplicated.
- **D-4:** AD-1 clarifying clause lands only in `skills/harness-stream/SKILL.md:95`; the three CHECK-ONLY `ADD` surfaces stay untouched (minimal fan-out).
- **D-5:** `docs/harness-stream.html` not refreshed (AD-6 snapshot precedent, `AI-GUIDE.md:68`).
- **D-6:** version = **0.32.0**; README version badges added to the bump set beyond RA §6 (convention evidence `CHANGELOG.md:23`).
- **D-7:** §Ingest triage placed between the ambient section and `## Procedure` (adjacent to both consumers).

## 12. Verification plan (for QA stage; PM runs the gate)

1. `.harness/scripts/verify_all` **32/32 PASS, both shells** (PM-run; covers G.1-G.4 incl. the `[0.32.0]` CHANGELOG↔plugin.json pairing and I.6 — run, don't reason).
2. **Hook lockstep:** with `.harness/ambient.flag` present, run all four `ambient-prompt` files (`echo '{}' |` each); assert ps1↔sh CR-stripped output identity and dogfood↔template whole-file byte-identity per extension; assert exactly +2 lines vs the v0.31.0 block; assert no `{{` in any of the four files (test-init's placeholder scan must stay green — no token is introduced).
3. **AC-5 adversarial probes** (skill-text dictates outcome unambiguously): (i) single deliverable → 1 row; (ii) "and"-chain of independent deliverables → N rows, `Depends on: —` everywhere; (iii) "X then Y" phased → real chain; (iv) one change echoed across many files → 1 row (counter-example holds). Plus a fixed-point probe: feed any produced sub-row Goal back through the triage test → must read "simple".
4. **Stale-claim grep** (AC-7): live surfaces (excluding `docs/features/`, `CHANGELOG.md`, `docs/harness-stream.html`) contain no remaining singular-only ingest claim — probe for `into a \`pending\` row` and `Mode=full` in the four hook files + SKILL, and adversarially for any surface still implying 1:1 ingest ("one row per requirement"-shaped text).
5. **Hard-rule truth pair:** new `SKILL.md` hard rule contains the union invariant + retained "never add unrequested work" + "user-authored rows never split"; `.harness/rules/25-decision-policy.md:53` unchanged and still truthful against it.
6. **Doc fan-out:** §5 table fully landed (bullet ×2, roadmap ×2, badges ×2, CHANGELOG, plugin/marketplace, batches README); `AC-8` regression drivers untouched and green (`test-init` ambient asserts are command-wiring only — `test-init.ps1:328`, `test-init.sh:291`).
7. **Budget:** `skills/harness-stream/SKILL.md` ≤ 198 lines.

## Verdict

**READY** (for Gate review). No requirement gap found; all RA acceptance criteria are mapped to concrete edits; one deliberate AC-1 refinement (D-1) is flagged for the Gate Reviewer's explicit confirmation.
