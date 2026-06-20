# 01 — Requirement Analysis — durable-brief (T-05)

**Mode:** full · **Stage:** 1 (Requirement Analyst) · **Verdict:** see §9
**deferred-human mode:** defer, do not ask (every Open Question carries a `Recommended:` answer; PM/Architect adopt it unless overridden).

## 1. Goal

Fold an agent-brief **durability discipline** (behavioral-not-procedural; complete testable acceptance criteria; explicit out-of-scope; no forward-looking file-path/line-number anchors) into the `requirement-analyst` Hard rules / "What good looks like" and the `pm-orchestrator` dispatch-prompt contract, with an explicit boundary that the rule governs only the FORWARD-LOOKING brief and never the BACKWARD-LOOKING `file:line` EVIDENCE the insight-index and stage docs legitimately cite.

## 2. In-scope behaviors

Numbered, testable. "RA" = `agents/requirement-analyst.md`; "PM" = `agents/pm-orchestrator.md`.

1. **RA gains a durability Hard rule.** `agents/requirement-analyst.md`'s "Hard rules" section contains a new rule stating that the requirement spec is written **behaviorally, not procedurally**: it describes *what* the system does and names interfaces / types / contracts / config shapes, and it does **not** anchor forward-looking requirement statements to file paths or line numbers (those go stale across refactors and across the time a task waits).
2. **RA "What good looks like" reflects durability.** The "What good looks like" (and/or "What bad looks like") list gains at least one behavioral-vs-procedural contrast — a "good" entry phrased as a behavioral/interface statement and a "bad" entry phrased as a `path:line` procedural instruction — so the discipline has a concrete positive and negative exemplar.
3. **The forward/backward boundary is stated explicitly in RA.** The new RA rule carries an explicit exception clause: the file-path/line-number ban applies to forward-looking requirement prose (in-scope behaviors, acceptance criteria, boundary conditions, the brief the pipeline builds FROM); it does **not** apply to backward-looking **EVIDENCE** citations, which continue to cite `file:line` as proof exactly as `.harness/rules/05-insight-index.md` and stage-doc evidence already require.
4. **PM dispatch contract gains a durability one-liner.** `agents/pm-orchestrator.md`'s dispatch / "How to start a task" contract gains one terse statement that a dispatch prompt to a downstream stage carries the **behavioral intent + acceptance criteria + scope boundary**, not procedural `file:line` instructions — while the existing instruction to surface applicable `insight-index` lines (which DO carry `file:line` evidence) is preserved unchanged.
5. **Acceptance criteria already-present requirement is reinforced, not duplicated.** The RA already requires "complete, testable, verifiable acceptance criteria" (sections 5 + "What good looks like"). The durability edit references / reinforces that existing requirement rather than adding a second, competing acceptance-criteria rule.
6. **Edits are additive and terse.** No existing RA Hard rule, RA 9-section output structure, or PM routing/rollback/mode logic is removed or rewritten; the change is purely additive prose within the existing sections.
7. **No new banned anchor is introduced into any scanned file.** The new rule text, this requirement doc, and all downstream stage docs avoid writing a literal phrase that would trip the `verify_all` I.6 retired-claim guard; no I.6 banned-list or exempt-list entry is added or changed.
8. **Version + CHANGELOG fan-out is applied (agent-CONTENT change).** Because `agents/*.md` are plugin-native shipped assets, editing their content is a shipped-behavior change: `plugin.json` version is bumped (0.35.0 → next), a CHANGELOG entry is added, and version-badge / marketplace fan-out is applied per the repo's standing convention — while every agent-COUNT claim (8 framework agents) and skill-COUNT claim (16) and check-COUNT claim (32) stays unchanged (this is a content edit, not a count flip).

## 3. Out-of-scope

1. Rewriting the RA's existing 9-section output structure or any existing Hard rule's substance.
2. Changing `pm-orchestrator` routing, rollback rules, mode table, or intervention protocol.
3. Any change that bans, restricts, or rewords `file:line` citations in `.harness/insight-index.md`, in `.harness/rules/05-insight-index.md`, or in stage-doc **EVIDENCE** sections — these legitimately cite `file:line` as proof and are explicitly protected by behavior 3.
4. Adding a new `verify_all` check, a new I.6 banned/exempt entry, or any new gate.
5. Importing mattpocock's GitHub-issue-specific template (`## Agent Brief` / `gh issue create` / `ready-for-agent` / labels) verbatim — the discipline is adapted to the harness brief format, not copy-pasted.
6. Editing any agent other than `requirement-analyst` and `pm-orchestrator`.
7. Editing template copies under `skills/harness-init/templates/` (framework agents are plugin-native and edited only in top-level `agents/` since v0.30 — no sync, no template copy).
8. Editing `docs/spec/`, `CLAUDE.md`, `.github/copilot-instructions.md`, or `.claude/` (red-line / no-sync-target files).

## 4. Boundary conditions

- **Null / absent target section:** if a referenced subsection heading (e.g. "What good looks like") is not found verbatim in the live agent file, the editor stops and reports rather than inventing a new heading — the two target files were read at this stage and both sections exist (RA "Hard rules" + "What good looks like"; PM "Hard rules" + "How to start a task" / dispatch contract).
- **Empty edit (no-op risk):** an edit that leaves both agent files byte-unchanged fails acceptance — the durability rule text MUST be present in the live files (greppable), not merely described in a stage doc.
- **Size cap (max):** I.3 caps agent definitions at 300 lines. RA is ~75 lines, PM ~207 lines. After additive terse edits each MUST stay ≤300 lines (`verify_all` I.3). Keep each addition to a few lines.
- **Self-trip (I.6):** the new rule text must phrase the ban behaviorally WITHOUT writing a literal banned-anchor sequence; the delivery insight harvest (07) must likewise avoid quoting any literal banned anchor (this exact failure mode bit T-013's delivery archive).
- **Contradiction (the #1 design tension):** the new "no file:line in the brief" rule MUST NOT read as a blanket ban — if read without the forward/backward scope it would contradict `05-insight-index.md` (which REQUIRES `file:line` evidence) and every existing insight line (e.g. `verify_all.ps1:439`). The scope clause (behavior 3) is the boundary that prevents self-contradiction.
- **Error path (concurrency / staleness):** the rule's own justification is that `file:line` anchors in a forward-looking brief go stale; the rule text states the *reason* (refactor/time-resilience) so a future editor understands why evidence is exempt but the brief is not.

## 5. Acceptance criteria

Each is independently verifiable.

1. **AC-1 (RA durability rule present):** `agents/requirement-analyst.md` contains a Hard rule (or equivalently-binding clause in "What good looks like") asserting behavioral-not-procedural requirement prose AND no forward-looking file-path/line-number anchors — verifiable by reading the file / a grep for the rule's distinctive phrase.
2. **AC-2 (good/bad exemplar present):** RA's "What good looks like" / "What bad looks like" contains a behavioral-vs-procedural contrast pair — verifiable by inspection.
3. **AC-3 (forward/backward boundary explicit):** the RA rule text explicitly exempts backward-looking EVIDENCE citations from the ban and names that insight-index / stage-doc evidence keeps citing `file:line` — verifiable by inspection; the absence of this clause is an automatic rollback.
4. **AC-4 (PM dispatch one-liner present):** `agents/pm-orchestrator.md`'s dispatch contract contains one statement that dispatch prompts carry behavioral intent + acceptance criteria + scope boundary, not procedural file:line instructions — verifiable by inspection.
5. **AC-5 (insight-surfacing preserved):** PM's existing instruction to surface applicable `insight-index` lines (which carry `file:line` evidence) into dispatch prompts is byte-present and unweakened after the edit — verifiable by inspection / diff.
6. **AC-6 (no contradiction with 05-insight-index):** `.harness/rules/05-insight-index.md`, `.harness/insight-index.md`, and stage-doc EVIDENCE conventions are byte-unchanged; the new rule's scope clause does not assert anything those files contradict — verifiable by diff (those files untouched) + a read-through of the new clause.
7. **AC-7 (caps + gate green):** `agents/requirement-analyst.md` ≤300 lines and `agents/pm-orchestrator.md` ≤300 lines; `.harness/scripts/verify_all` PASSes (32/32, including I.3 size and I.6 retired-claim) on both shells (PS run is operator-pending per the standing deny-rule pattern).
8. **AC-8 (version + CHANGELOG fan-out):** `plugin.json` version bumped from 0.35.0; a CHANGELOG entry describes the agent-content change and states counts unchanged (16 skills / 8 framework agents / 32 checks); version-badge + marketplace fan-out applied per convention; `verify_all` G.3/G.4 (version/claim consistency) green — verifiable by gate.
9. **AC-9 (additive only):** a diff of both agent files shows only additions / minimal in-place rewording within existing sections — no existing Hard rule, output-section, or routing rule deleted — verifiable by `git diff`.

## 6. Non-functional requirements

- **NFR-1 (durability of the rule itself):** the new rule text names *behaviors and interfaces* and contains no `path:line` anchor, so it is itself an exemplar of the discipline it states (self-consistency).
- **NFR-2 (terseness / context budget):** additions are minimal — a few lines per file — to respect I.3 caps and the project's "reference don't paste" doc-size discipline (`70-doc-size.md`).
- **NFR-3 (cross-shell parity):** the gate must pass on both PowerShell and bash; any insight harvested at delivery must be UTF-8-safe and I.6-clean.

## 7. Related tasks

- **T-03 / harness-grill** (`docs/features/_archived/harness-grill/`) — last edited `agents/requirement-analyst.md`; introduced the standing `Recommended:`-per-Open-Question rule and reconciled Hard-rule-1's strip-list (ban scoped to requirement prose, labelled field exempt). This task layers the durability rule onto that same Hard-rules surface; the existing strip-list-scoping pattern is the model for how to scope the new ban.
- **T-02 / context-glossary** (`docs/features/_archived/context-glossary/`) — added a SOFT-dependency Workflow step to RA + solution-architect; precedent for an additive, terse agent-content edit that bumped the version (0.33→0.34) with no count flip.
- **T-022 / stream-defer-human** (`docs/features/_archived/stream-defer-human/`) — last edited `agents/pm-orchestrator.md` (Hard rule 6 + "When to stop and ask"); precedent for an additive PM-content edit that bumped the version (0.32→0.33) with counts unchanged. Confirms the dispatch/escalation surface is the right place for the PM one-liner.
- **T-019 / agents-cutover** (`docs/features/_archived/agents-cutover/`) — established that framework agents are plugin-native (`harness-kit:<name>`), edited only in top-level `agents/`, no sync/template copy; the reason behavior 7 (out-of-scope) excludes template edits.
- **Source (read-only):** `c:\Programs\_research\mattpocock-skills\skills\engineering\triage\AGENT-BRIEF.md` (durability-over-precision principles + good/bad examples) and `…\skills\deprecated\qa\SKILL.md` (no file paths/line numbers; behaviors not code; durable after refactors).

## 8. Open questions for user (deferred — each has a Recommended answer)

1. **Where exactly does the new RA durability rule live — a 6th Hard rule, or folded into "What good looks like"?**
   (a) Add it as RA Hard rule 6 (binding, top-of-mind alongside the other rules).
   (b) Fold it into "What good looks like" / "What bad looks like" only (lighter touch).
   (c) Both — a one-line Hard rule + a good/bad exemplar pair.
   **Recommended:** (c). The discipline is binding enough to be a Hard rule, and the good/bad contrast pair is the highest-signal way to teach behavioral-vs-procedural (mirrors mattpocock's own good/bad framing). Behaviors 1 + 2 already assume both surfaces.

2. **Does the forward/backward boundary clause live in the RA file, the PM file, or both?**
   (a) RA only (it owns the brief; PM merely forwards).
   (b) PM only.
   (c) Both, tersely.
   **Recommended:** (a) as the authoritative statement, with the PM one-liner (behavior 4) phrased so it does not need to restate the boundary — it says "carry behavioral intent + AC + scope, not procedural file:line" and leaves the evidence-exemption to RA. This keeps PM's addition to a single line and avoids duplicating the nuanced clause in two places (one source of truth).

3. **Is a version bump + CHANGELOG entry warranted for this agent-CONTENT change?**
   (a) Yes — bump `plugin.json` (0.35.0 → 0.36.0) + CHANGELOG, counts unchanged.
   (b) No — treat as a dogfood-only rule edit (like T-04, which did NOT bump because it touched only `.harness/rules/`).
   **Recommended:** (a) Yes, bump. **Finding:** the repo convention is decisive — `agents/*.md` are plugin-native SHIPPED assets, and every prior task that edited an agent's *content* bumped the version with counts held constant: T-02 (RA + architect → 0.34.0), T-03 (RA → 0.35.0), T-022 (PM → 0.33.0). The no-bump precedent (T-04) applies ONLY to `.harness/rules/` dogfood edits, which are NOT shipped. This is a MINOR bump (0.35.0 → 0.36.0): additive agent behavior, no count flip (16 skills / 8 framework agents / 32 checks all stay), so G.3/G.4 require the version+CHANGELOG move but no count-claim fan-out.

4. **How far does behavior 2's good/bad exemplar go — generic, or repo-specific?**
   (a) Generic ("name the interface/type, not the line it lives on").
   (b) Repo-specific (cite that an insight-index EVIDENCE line legitimately uses `file:line` but a requirement statement must not).
   **Recommended:** (a) for the good/bad list (keeps it portable and terse), with the repo-specific forward/backward nuance carried by the boundary clause (behavior 3 / OQ-2), not the exemplar. Avoids writing a literal `file:line` token in the exemplar that could approach an I.6 anchor and keeps the list short.

## 9. Verdict

**READY.**

Rationale: the request is well-scoped, the two target files and the protected evidence-citation files were read at this stage, the #1 design tension (forward brief vs backward evidence) is resolved by an explicit in-scope behavior (3) + acceptance criterion (AC-3 / AC-6), and the version-bump question is answered by a decisive repo convention. All four Open Questions are non-blocking: each carries a `Recommended:` answer the Architect adopts unless the operator overrides, per the standing deferred-human discipline. No ambiguity forces a human decision before design can proceed.

- In-scope behaviors: **8**
- Acceptance criteria: **9**
- Open questions: **4** (all non-blocking, recommended-answered → proceedable)
