# 01 — Requirement Analysis · T-013 / lang-policy-split

> Stage 1 of the Harness pipeline. Mode: **full**. Author: Requirement Analyst.
> Inputs (read-only): the PM dispatch intent (verbatim below), the existing v0.7.0 zh language policy,
> `skills/harness-init/SKILL.md`, the i18n/zh overlay, both READMEs, `docs/manual-e2e-test.md`.
> No INPUT.md file was present in the task folder; the verbatim intent in the PM dispatch is treated as the request of record.

## 1. Goal

Replace the generated zh-project's blunt "everything in Chinese" output-language policy with a three-way split that routes each AI-produced artifact to English or Chinese by its primary consumer.

## 2. Verbatim intent (read-only)

When a user picks Chinese at init (`{{LANG}}=zh`), today's policy is "EVERYTHING in Chinese" (`00-core.md.tmpl` "输出语言（全项目）"). Replace it with:

- **Conversational replies to the human** → Chinese.
- **AI-facing artifacts** (primarily consumed by downstream agents / the LLM) → English.
- **Human-facing artifacts** (primarily read by humans) → Chinese.

Rationale held by the user: the LLM reads English at least as well; English keeps AI-facing artifacts consistent with the (English) framework internals and smaller; humans get Chinese where they actually read.

**Scope = the GENERATED user projects** (the zh overlay policy text + SKILL.md Q5 text + the two READMEs + manual-e2e-test). NOT harness-kit's own dogfood repo (whose `CLAUDE.md` / policy stays English regardless). The English (`{{LANG}}=en`) path is unaffected — an English project has no split, everything is English.

## 3. Key distinction this requirement pins down (read before the table)

There are **two different things** the word "language" can mean here, and conflating them is the single biggest ambiguity in this task:

- **(A) Runtime AI OUTPUT language** — what an agent *writes at task time* into a generated artifact (a 04_DEVELOPMENT.md it authors, a chat reply, a tasks.md row it appends). This is what the policy governs. The three-way split is a rule about **(A)**.
- **(B) Template/static-content language** — the language the *shipped `.tmpl` skeleton files themselves* are written in (e.g. `AI-GUIDE.md.tmpl`, `00-core.md.tmpl`, `docs/workflow.md`). The zh overlay today translates many of these into Chinese. These are static scaffolding, not runtime output.

The policy text being rewritten lives in **(B)** (the zh `00-core.md.tmpl`), but it *governs* **(A)**. Whether the new policy ALSO triggers re-classifying some currently-Chinese **(B)** template files back to English (because they are AI-facing) is a real, separable decision — see OQ-3. The classification table in §4 is written for **(A)** (runtime output) unless a row explicitly says "(template)".

## 4. Classification table (the centerpiece) — runtime AI output, zh project

Legend: **EN** = English · **ZH** = Chinese · **DUAL** = read by both audiences, tie-broken with stated rule.

| # | Artifact (zh project, at task time) | Primary consumer | Class | One-line rationale |
|---|---|---|---|---|
| C-1 | Conversational replies to the human (chat) | Human | **ZH** | Fixed by the request; the human is the sole consumer of a chat turn. |
| C-2 | 7-stage docs `01_REQUIREMENT_ANALYSIS … 07_DELIVERY.md` | Downstream agent (primary) + human reviewer | **EN** (DUAL→EN) | Each doc is the *input contract* for the next agent; the downstream LLM is the stricter consumer, and a human reviewer reads English fine. Tie-break to EN. **Escalated as OQ-1** because it is the user-preference fork. |
| C-3 | `PM_LOG.md` | Downstream agents (coordination ledger) | **EN** | Machine-coordination scratchpad consumed by the PM and every stage; not a human deliverable. |
| C-4 | `docs/tasks.md` (task board rows the AI appends) | Agents + human at a glance | **EN** (DUAL→EN) | A coordination ledger keyed by IDs/slugs/stage tokens the agents parse; status tokens stay English for grep/consistency with the framework. |
| C-5 | `docs/dev-map.md` (entries the AI appends) | Agents (navigation) + human | **EN** (DUAL→EN) | Navigation index the agents read to locate code; consistency with English paths/headings. |
| C-6 | `.harness/insight-index.md` (lines the AI appends) | Agents (cross-task memory) | **EN** | Read by agents at task start to constrain decisions; AI-facing memory. |
| C-7 | `.harness/agents/*.md` (if the AI authors/edits one, e.g. a new dev-partition) | LLM (agent definitions) | **EN** | Status quo since inception (CHANGELOG: LLM reads English fine, keeps size down). Pure AI-facing. **Confirm-status-quo as OQ-2.** |
| C-8 | `.harness/rules/*.md` (rule fragments the AI authors/edits, incl. `50-<slug>.md`) | LLM (rules) | **EN** | AI-facing instructions consumed by every agent; consistency with the (English) framework rule set. |
| C-9 | `AI-GUIDE.md` / `CLAUDE.md` (edits the AI makes post-init) | LLM (project index/stub) | **EN** | Name says it: AI-facing entry/stub, read by the LLM before each task. |
| C-10 | `README.md` / `README.zh-CN.md` / human-facing `docs/*` guides the AI writes | Human | **ZH** | Onboarding/marketing prose a human reads; the human is the consumer. (`README.zh-CN.md` is the zh-audience file.) |
| C-11 | Error messages surfaced to the human | Human | **ZH** | The human acts on them. |
| C-12 | Status reports / progress summaries to the human | Human | **ZH** | The human consumes them. |
| C-13 | Delivery summary prose addressed to the human (the "what shipped" narrative in 07/handoff) | Human | **ZH** | Human-facing closeout. (The 07_DELIVERY.md *file* is C-2/EN; a chat-level delivery message to the human is ZH.) |
| C-14 | Code comments | Human editing + LLM reading | **EN** (DUAL→EN) | Lives inside source files that are English-keyworded; consistency with code identifiers and the framework convention. **Escalated as OQ-4** (a defensible argument exists for ZH comments in a zh team's own app code). |
| C-15 | Commit messages | Human (git log) + tooling/convention | **EN** (DUAL→EN) | The repo's commit convention (imperative, ≤72-char first line) and grep-ability favor English; read by both humans and tooling. **Escalated as OQ-5.** |
| C-16 | Spec / requirement prose the human writes in `docs/spec/` | Human-authored (not AI output) | n/a | Out of scope — human writes these; the policy binds AI output only. |

**Net headline for the policy text:** Chinese = chat replies, error messages, status/progress reports, delivery messages to the human, human-facing READMEs/guides. English = the 7-stage stage docs, PM_LOG, tasks.md / dev-map / insight-index ledgers, agent/rule/AI-GUIDE/CLAUDE edits, code comments, commit messages.

## 5. In-scope behaviors (numbered, testable)

1. The generated zh project's policy section (`00-core.md` "输出语言（全项目）") states the three-way split: it names which artifacts are produced in Chinese and which in English, matching §4 (after OQ resolution).
2. The generated zh project's `CLAUDE.md` top "输出语言" line is updated from the blunt "中文" to a one-line statement of the split that points at `00-core.md` for the full table.
3. The generated zh project's `.github/copilot-instructions.md` top "输出语言" line is updated symmetrically with `CLAUDE.md` (same stub, both tools).
4. SKILL.md Q5's `中文 (Chinese)` option description is rewritten from "项目内 AI 全程使用中文输出 …（everything ZH）" to the three-way split summary; the `English (default)` option description is left semantically unchanged (English project = everything English; **confirm via OQ-6**, see §9).
5. `README.md` §"Project-wide language policy" and `README.zh-CN.md` §"项目级语言策略" are rewritten from "every AI output in Chinese" to the three-way split summary.
6. `docs/manual-e2e-test.md` language-step expectation (≈line 101 Q5 wording, and the B.3 inspection of a generated zh project if it asserts policy content) is updated to the new policy.
7. The `{{LANG}}=zh` overlay-application logic in SKILL.md step 4.3 is unchanged in mechanism (the zh overlay still applies); only the policy *content* inside the overlaid files changes. (Whether AI-facing template files leave the zh overlay is OQ-3.)
8. CHANGELOG gets an entry; the version is bumped per the repo's claim/version-consistency rule (a content change to shipped templates is a releasable change).
9. The English (`{{LANG}}=en`) policy text in `templates/common/.harness/rules/00-core.md.tmpl` and `CLAUDE.md.tmpl` is left functionally unchanged (English project → everything English; no split). Confirm via OQ-6.

## 6. Out-of-scope (explicitly NOT this iteration)

1. harness-kit's own dogfood `CLAUDE.md` / `00-core.md` / policy (stays English — this task only touches the shipped templates + SKILL.md + docs).
2. Adding a new `{{...}}` placeholder. The split is fixed policy *text*, not a per-init toggle, so no new placeholder is introduced. (If OQ resolution demanded a toggle, that becomes a follow-up — flagged D-obligation.)
3. Any new language overlay beyond `zh` (no `ja`, `fr`, etc.).
4. Retroactively rewriting already-generated user projects (no migration tool change; `/harness-upgrade` content-refresh is a separate task surface — flagged as a downstream obligation, not done here).
5. Changing the EN path into a split (an English project has one language).
6. Re-translating the *bodies* of the zh overlay's docs (`workflow.md`, etc.) — only the policy section and the advertised wording change, unless OQ-3 re-classifies specific AI-facing template files.
7. Re-classifying agent definitions away from English (status quo kept unless OQ-2 says otherwise).

## 7. Boundary conditions

1. **Null/absent INPUT.md** — handled: the PM dispatch intent is the request of record; flagged at the top.
2. **`{{LANG}}=en` path** — must remain a single-language (English) policy; no split phrasing leaks into the en templates.
3. **Mixed-language user input** — preserved from today's rule: a user message in any language still yields chat replies in Chinese (C-1); the agent translates intent internally.
4. **DUAL artifacts** — every artifact read by both audiences (C-2, C-4, C-5, C-14, C-15) has an explicit tie-break rule in §4; none is left "writer's choice".
5. **Template-language vs runtime-output-language** (the §3 (A)/(B) split) — the policy text change (B) must not be silently assumed to re-translate AI-facing template files; that re-classification is gated on OQ-3.
6. **`README.zh-CN.md` vs `README.md`** — both are human-facing; both get the rewritten policy section in their respective languages (the policy *describes* the split; it is itself documentation prose).
7. **Symmetry** — any test assertion ADDED for the policy must be cross-platform symmetric (PS + Bash), per the project rule, even though the policy is content not script.
8. **Error path: overlay missing a file** — unchanged behavior; out of scope (no overlay structural change unless OQ-3).
9. **Max size / doc-size caps** — the rewritten `00-core.md` policy section must not push the file past the I.* doc-size WARN cap; the split table is concise (the Architect sizes it).

## 8. Acceptance criteria (QA-verifiable on a generated zh project / via test-init)

- **AC-1**: A `{{LANG}}=zh` init produces a `CLAUDE.md` whose top "输出语言" line states the three-way split (not the blunt "中文") and points at `00-core.md`. Verifiable by inspecting the generated file.
- **AC-2**: That project's `.harness/rules/00-core.md` "输出语言" section enumerates, as two explicit lists, the Chinese artifacts (chat replies, error messages, status/progress reports, human-facing delivery messages, README/human docs) and the English artifacts (7-stage docs, PM_LOG, tasks.md/dev-map/insight-index, agent/rule/AI-GUIDE/CLAUDE edits, code comments, commit messages) — matching §4 after OQ resolution.
- **AC-3**: That project's `.github/copilot-instructions.md` top "输出语言" line matches `CLAUDE.md`'s (same split summary, same pointer).
- **AC-4**: SKILL.md Q5 `中文 (Chinese)` option text describes the three-way split; no surviving sentence asserts "AI 全程使用中文输出 / everything in Chinese".
- **AC-5**: `README.md` and `README.zh-CN.md` language-policy sections describe the split; no surviving sentence asserts "every AI output in Chinese / AI 全程中文输出".
- **AC-6**: `docs/manual-e2e-test.md` Q5/language expectation matches the new policy.
- **AC-7**: A `{{LANG}}=en` init's `00-core.md` + `CLAUDE.md` policy text is byte-unchanged from pre-T-013 (the EN path is untouched). Verifiable by diff against the prior templates.
- **AC-8**: `verify_all` passes on the harness-kit repo (no I.6 retired-claim regression for any "everything in Chinese" phrasing the rewrite retires; if a phrase is retired, its I.6 banned-line is added — D-obligation below).
- **AC-9**: `test-init` passes both shells; any new language assertion is present and symmetric in `test-init.ps1` and `test-init.sh` (currently there are ZERO language assertions — see §11 NFR/obligations).
- **AC-10**: CHANGELOG has a T-013 entry and the version is bumped; all count/version claim checks (G.3/G.4) stay green.

## 9. Open questions for the user (each with a recommended default)

> Verdict is gated on these. Recommended defaults are provided so the PM can resolve fast.

**OQ-1 — 7-stage docs (`01…07`, the C-2 DUAL fork): EN or ZH?**
The genuine fork. Downstream agent is the stricter consumer; a human reviewer reads English fine; English keeps stage docs consistent with the framework. But a zh team's reviewers may prefer reading these long docs in Chinese.
(a) **EN (recommended default)** — tie-break to the stricter consumer; consistent, smaller, matches the user's stated rationale.
(b) ZH — optimize for the human reviewer's reading comfort over agent/framework consistency.
(c) Split: the machine-structured sections (ACs, tables, verdicts) in EN; the narrative prose in ZH — rejected as a default (raises authoring complexity and per-agent ambiguity).

**OQ-2 — agent definitions `.harness/agents/*.md`: keep English (status quo) or follow the new policy?**
(a) **Keep English (recommended default)** — unchanged since inception; pure AI-facing; CHANGELOG-documented rationale (size + LLM reads English). The new policy reinforces this.
(b) Follow policy (would put them in ZH as "AI-facing → English" already says EN, so this only matters if AI-facing were ever ZH — it is not). Effectively a no-op; default (a) is safe.

**OQ-3 — template/static-content re-classification (the §3 (B) question): does this iteration ALSO move currently-Chinese AI-facing template files back to English in the zh overlay?**
Today the zh overlay ships Chinese versions of `AI-GUIDE.md.tmpl`, `00-core.md.tmpl`, the rule fragments, `docs/workflow.md`, `insight-index.md.tmpl`, etc. Under "AI-facing → English", several of these are AI-facing.
(a) **No — this iteration changes only the OUTPUT-language policy text, not which template files the zh overlay translates (recommended default).** Smallest, safest change; the template-vs-runtime distinction (§3) means a Chinese AI-GUIDE template does not violate a runtime-output policy. Re-classifying templates is a larger, separable refactor.
(b) Yes — also prune AI-facing files from the zh overlay so the shipped skeleton matches the policy. Larger blast radius (overlay ↔ common symmetry, test-init, doc-size), recommend deferring to a follow-up task.

**OQ-4 — code comments (C-14): EN or ZH?**
(a) **EN (recommended default)** — comments live among English code identifiers; framework convention.
(b) ZH — a zh team writing comments for their own future selves. Defensible; user-preference.

**OQ-5 — commit messages (C-15): EN or ZH?**
(a) **EN (recommended default)** — the repo's commit convention + git-log grep-ability + tooling.
(b) ZH — human-readability for a zh team's git history.

**OQ-6 — English (`{{LANG}}=en`) policy text: confirm "leave unchanged"?**
(a) **Yes, leave the en templates byte-unchanged (recommended default)** — an English project has one language; no split applies.
(b) Add a parallel "all English (no split needed)" sentence to the en `00-core.md` for symmetry of documentation. Cosmetic; default (a) avoids churn.

## 10. Related tasks (linked, not re-described)

- **T-002 / ai-native-init** (`docs/features/_archived/ai-native-init/`) — established the i18n/zh overlay mechanics and the BUG-2 placeholder-regex regression; the overlay-application order this task relies on was set there.
- **T-012 / harness-upgrade-skill** (`docs/features/_archived/harness-upgrade-skill/`) — the content-refresh path for already-generated projects; relevant to the deferred-migration obligation (§6.4).
- **T-008 / test-supervisor-stamps** + **T-010 / g4-version-decouple** — the G.3/G.4 version/claim-consistency gates AC-10 must keep green.
- **T-004 / i6-semantic-guard** — the I.6 retired-claim guard that AC-8 must satisfy if the rewrite retires an "everything in Chinese" phrasing.

## 11. Non-functional requirements & downstream obligations the Architect must carry

- **NFR-1 (cross-platform symmetry)**: any test assertion added is PS+Bash symmetric. The policy is content, not script, but a new test assertion is a script change.
- **NFR-2 (doc-size)**: rewritten `00-core.md` policy section stays under the I.* WARN cap.
- **D-obligation 1 (I.6 retired-claim guard)**: if the rewrite *retires* a phrase like "项目内 AI 全程使用中文输出" / "every AI output in Chinese", add the corresponding I.6 banned-line so a future contributor cannot reintroduce it (insight-index L18/T-004 pattern). Verify the rewrite's own new text does not trip an existing I.6 line.
- **D-obligation 2 (no new placeholder)**: the split is fixed text, so D.2 placeholder whitelist is untouched (insight L11) — *unless* OQ resolution turns the split into a toggle, which would require a new `{{...}}` in BOTH verify_all.ps1 and .sh D.2 whitelists.
- **D-obligation 3 (SKILL step-4.3 doc drift)**: SKILL.md step 4.3's enumerated zh-overlay file list (line 107) is already STALE vs the actual overlay contents (the real overlay also contains `AI-GUIDE.md.tmpl`, `05-insight-index.md.tmpl`, `75-safety-hook.md.tmpl`, `insight-index.md.tmpl`, `copilot-instructions.md.tmpl`). The Architect notes this; whether to fix it in this task is a scoping call (recommend: fix the one line opportunistically since we're editing Q5 nearby).
- **D-obligation 4 (test coverage gap)**: `test-init.{ps1,sh}` currently asserts NOTHING about language/zh policy (confirmed: zero matches). AC-9 adds the first such assertion — it must be symmetric and must tolerate the no-python3 Bash path.
- **D-obligation 5 (overlay ↔ common symmetry)**: only triggered if OQ-3 = (b); otherwise no symmetry obligation beyond the policy text.
- **D-obligation 6 (version/claim consistency)**: per G.3/G.4 + insight L33, a shipped-template content change is version-worthy; bump plus CHANGELOG.

## 12. Verdict

**BLOCKED ON USER** — six open questions remain (OQ-1 … OQ-6), of which OQ-1 (7-stage docs EN/ZH) and OQ-3 (template re-classification scope) are the load-bearing forks. Recommended defaults are attached to every question; if the PM accepts all six defaults as-is, the requirement collapses to: *Chinese = chat / errors / status / human messages / human docs; English = everything AI-facing (stage docs, ledgers, rules, agents, comments, commits); zh overlay template files unchanged; en path unchanged.* The PM may approve-by-default and advance, or route the forks to the user.
