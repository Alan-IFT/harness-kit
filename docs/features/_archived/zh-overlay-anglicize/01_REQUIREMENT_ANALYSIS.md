# 01 — Requirement Analysis · T-015 / zh-overlay-anglicize

> Stage 1 of the Harness pipeline. Mode: **full**. Author: Requirement Analyst.
> Inputs (read-only): the PM dispatch intent (this folder's `PM_LOG.md`), the live i18n/zh overlay
> (`skills/harness-init/templates/i18n/zh/`), the English originals in `templates/common/` + type dirs,
> `skills/harness-init/SKILL.md` (overlay-application step 4.3), `test-init.{ps1,sh}` (the zh regression),
> and T-013's delivery (`docs/features/_archived/lang-policy-split/07_DELIVERY.md`).
> No `INPUT.md` file is present in the task folder; the PM dispatch intent in `PM_LOG.md` is the request of record.

## 1. Goal

Make a generated `{{LANG}}=zh` project's STATIC shipped scaffolding language-consistent with the output-language policy it declares (T-013: AI-facing → English) by removing the Chinese translations of AI-facing framework files from the zh overlay so they fall through to the English `common/` layer, while keeping genuinely human-facing files Chinese and preserving the T-013 policy text exactly as shipped.

## 2. The mechanism this task relies on (read before the table)

`SKILL.md` step 4.3 (lines 104-108) applies the language overlay **on top of** the already-copied English `common/` + type layers: "Copy everything under `templates/i18n/<lang>/common/` → target root (overwrites the English files)" and "Files **not** in the overlay … stay in English." Therefore:

- **ANGLICIZE a file = DELETE it from `templates/i18n/zh/`.** No English file is authored; the existing English `common/` (or type) version is simply not overwritten, so it ships verbatim. Every zh overlay file already has a confirmed English original in `templates/common/` or the type dir (verified by Glob — all 16 fall-through targets exist), so no fall-through gap is introduced.
- **KEEP-ZH a file = leave the zh overlay file in place**, unchanged.
- **SPECIAL a file = edit the zh overlay file in place**: replace the non-policy framework BODY with the English `common/` body, and retain the T-013 Chinese policy section/line byte-for-byte as shipped.

This task changes only **template/static-content language (the (B) layer in T-013's §3 framing)**. It does NOT touch the runtime OUTPUT-language policy (the (A) layer — already shipped by T-013) and does NOT touch harness-kit's own dogfood repo.

## 3. Classification table (the centerpiece) — per overlay file, generated zh project

Legend: **ANGLICIZE** = remove from zh overlay, fall through to English `common/`/type · **KEEP-ZH** = leave the Chinese overlay file as-is · **SPECIAL** = anglicize the non-policy body in place, keep the T-013 Chinese policy section/line verbatim.
"Primary consumer" = who chiefly reads this file **in a generated project at task time**.

| # | Overlay file (`templates/i18n/zh/…`) | Primary consumer | Decision | Rationale (one line) |
|---|---|---|---|---|
| F-1 | `common/AI-GUIDE.md.tmpl` | The AI, before each task | **ANGLICIZE** | Self-named AI entry index; the policy says AI-facing → English; English `common/` original is the canonical index. |
| F-2 | `common/.harness/rules/00-core.md.tmpl` | The AI (rules) **+ carries the T-013 policy** | **SPECIAL** | AI reads it as rules → body anglicized; the "输出语言（按消费者分流）" section is the T-013 policy declaration and stays Chinese exactly as shipped. |
| F-3 | `common/.harness/rules/05-insight-index.md.tmpl` | The AI (cross-task-memory contract) | **ANGLICIZE** | Rule fragment the AI loads when deciding non-trivial work; AI-facing. |
| F-4 | `common/.harness/rules/60-tool-handoff.md` | The AI (tool-switch protocol) | **ANGLICIZE** | Rule fragment governing agent/tool handoff; AI-facing. |
| F-5 | `common/.harness/rules/75-safety-hook.md.tmpl` | The AI (guardrail contract) | **ANGLICIZE** | Rule fragment describing the destructive-command hook; AI-facing. |
| F-6 | `common/.harness/insight-index.md.tmpl` | The AI (cross-task memory store) | **ANGLICIZE** | The seed memory file the AI reads at task start and appends to; T-013 already routes its runtime content EN; AI-facing. |
| F-7 | `common/CLAUDE.md.tmpl` | Claude Code tool stub **+ policy line** | **SPECIAL** | Tool bootstrap stub the AI reads; anglicize the bootstrap body, keep the one-line T-013 Chinese policy summary verbatim. |
| F-8 | `common/.github/copilot-instructions.md.tmpl` | Copilot tool stub **+ policy line** | **SPECIAL** | Symmetric tool stub; anglicize the bootstrap body, keep the one-line T-013 Chinese policy summary verbatim. |
| F-9 | `common/docs/workflow.md` | The AI (pipeline definition it follows) | **ANGLICIZE** | The 7-stage process reference every agent follows; consumed as a coordination contract, not human onboarding prose; AI-facing. |
| F-10 | `common/docs/dev-map.md.tmpl` | The AI (navigation index) | **ANGLICIZE** | Developer agent reads it before coding to avoid reinventing; T-013 routes its runtime appends EN; AI navigation artifact → AI-facing. |
| F-11 | `common/docs/tasks.md.tmpl` | The AI (task board it parses/appends) | **ANGLICIZE** | A coordination ledger keyed by IDs/slugs/stage tokens the AI parses and appends to; T-013 routes its runtime rows EN; the seed header is AI-facing scaffolding. |
| F-12 | `common/docs/spec/README.md` | The human, to write SPECs | **KEEP-ZH** | A guide a human reads before hand-authoring a SPEC; human-facing (the policy's "human-facing → Chinese" category); not AI-consumed at task time. |
| F-13 | `common/evals/golden-tasks.md.tmpl` | The human, to manually re-run regressions | **KEEP-ZH** | Instructions a human follows to manually re-run golden tasks and eyeball results ("人工扫一眼"); human-operated regression checklist → human-facing. |
| F-14 | `fullstack/.harness/rules/50-fullstack.md` | The AI (type-specific rules) | **ANGLICIZE** | Type rule fragment the AI loads as rules; same class as F-3/F-4/F-5; AI-facing. |
| F-15 | `backend/.harness/rules/50-backend.md` | The AI (type-specific rules) | **ANGLICIZE** | Type rule fragment (partition-Developer ownership rules); AI-facing. |
| F-16 | `generic/.harness/rules/50-generic.md.tmpl` | The AI (type-specific rules stub) | **ANGLICIZE** | Near-empty type rule stub the AI fills from the stack description; AI-facing. |

**Net per category:** ANGLICIZE (delete) = 11 files (F-1, F-3, F-4, F-5, F-6, F-9, F-10, F-11, F-14, F-15, F-16). SPECIAL (edit-in-place) = 3 files (F-2, F-7, F-8). KEEP-ZH (untouched) = 2 files (F-12, F-13).

### Borderline-call evidence (the four files where AI-facing vs human-facing was weighed, not assumed)

- **F-9 `workflow.md` → ANGLICIZE.** It is the pipeline definition each agent reads ("动手前先读 `docs/workflow.md`"). `AI-GUIDE.md` already lists it under "Project documents" as the process reference the AI consults; it is structurally an agent coordination contract, not a contributor onboarding narrative (the project's human-onboarding prose lives in README/getting-started, which are not in the overlay). Primary consumer = AI.
- **F-10 `dev-map.md.tmpl` → ANGLICIZE.** Its own header says "Developer agent 写代码前会读这个文件"; it is the AI's navigation index. T-013 already classified its runtime appends as English (C-5). Shipping a Chinese seed under an English-appended file is the exact inconsistency this task removes.
- **F-11 `tasks.md.tmpl` → ANGLICIZE.** The body is a board the AI parses (ID/slug/stage tokens) and appends English rows to (T-013 C-4). The seed prose has no human-onboarding-only content; consistency with the EN-appended runtime content and the English `common/` board favors anglicizing the seed.
- **F-13 `golden-tasks.md.tmpl` → KEEP-ZH.** Unlike F-9/F-10/F-11, this file's audience is explicitly a human operator running a manual eyeball pass ("然后人工扫一眼"); it is an instructions-for-humans checklist, not an AI-consumed fixture. It matches the policy's "human-facing → Chinese" and is left Chinese.

## 4. In-scope behaviors (numbered, testable)

1. The 11 ANGLICIZE files (F-1, F-3, F-4, F-5, F-6, F-9, F-10, F-11, F-14, F-15, F-16) are removed from `skills/harness-init/templates/i18n/zh/`.
2. After removal, a `{{LANG}}=zh` init produces, for each ANGLICIZE file, content byte-identical to the corresponding English `templates/common/` (or type-dir) render with the same placeholder values — i.e. the English version, not a Chinese one.
3. The 3 SPECIAL files (F-2, F-7, F-8) remain in the zh overlay; their non-policy framework body becomes the English `common/` body, while the T-013 Chinese policy section/line is retained byte-for-byte as currently shipped.
4. For `00-core.md.tmpl` (F-2), the retained policy section is the "输出语言（按消费者分流）" section (the two ZH/EN consumer lists + the DUAL→EN tie-break + the "不要在同一份产物里混用语言" + the change-instruction line), unchanged; every other section ("这个项目怎么开发", "红线", "风格 / 约定", "各种东西在哪里", "拿不准时") becomes its English `common/` counterpart.
5. For `CLAUDE.md.tmpl` (F-7) and `copilot-instructions.md.tmpl` (F-8), the single Chinese "输出语言：…" policy line is retained verbatim; every other line (the ruleset pointer, the red-lines block, the static-stub note, and the copilot frontmatter `applyTo`) becomes its English `common/` counterpart.
6. The 2 KEEP-ZH files (F-12 `docs/spec/README.md`, F-13 `evals/golden-tasks.md.tmpl`) are unchanged.
7. `SKILL.md` step 4.3 (lines 107-108) is updated: the enumerated zh-overlay file list reflects only the files that remain in the overlay (the 3 SPECIAL + 2 KEEP-ZH = 5 files), and the "Files **not** in the overlay … stay in English" sentence is reconciled so it no longer contradicts the now-anglicized AI-facing files.
8. The EN path (`{{LANG}}=en`) is unchanged: an English init is byte-identical to before this task.
9. CHANGELOG gets a T-015 entry and the plugin version is bumped per the repo's version/claim-consistency rule (a shipped-template content change is a releasable change — confirm scope per §10 D-2).
10. No new `{{...}}` placeholder is introduced; the ANGLICIZE files' fall-through targets are the existing, already-D.2-clean English templates.

## 5. Out-of-scope (explicitly NOT this iteration)

1. harness-kit's own dogfood repo (its `AI-GUIDE.md` / `00-core.md` / `CLAUDE.md` are English regardless and are not shipped templates).
2. The `{{LANG}}=en` path (an English project has one language; no overlay applies).
3. The RUNTIME output-language policy (the (A) layer — T-013 already shipped the three-way split; this task is the static (B) layer only).
4. Reversing or re-wording the T-013 policy text itself (kept verbatim; any re-wording is gated on OQ-1).
5. Translating the missing rule fragments `65-intervention.md` / `70-doc-size.md` into Chinese — they were never in the zh overlay (pre-existing incompleteness), and anglicizing the AI-facing rules makes that incompleteness moot rather than something to fix here.
6. Any new language overlay beyond `zh`.
7. Retroactively rewriting already-generated user projects (a `/harness-upgrade` content-refresh concern; separate task surface).
8. Adding a new `{{...}}` placeholder or any per-init language-granularity toggle.

## 6. Boundary conditions

1. **Null/absent INPUT.md** — handled: the PM dispatch intent in `PM_LOG.md` is the request of record; flagged at the top.
2. **Fall-through target missing** — cannot occur: all 16 English originals are confirmed present (Glob), so removing any zh overlay file always lands on a real English template; if a future contributor deletes an English original, test-init's existing presence assertions catch it.
3. **Placeholder integrity after removal** — the ANGLICIZE fall-through targets are the existing English `.tmpl` files, already passing test-init's recursive `\{\{[A-Z_]+\}\}` no-unresolved-placeholder scan; removing the zh duplicates introduces no new placeholder and leaves no stray token.
4. **SPECIAL body/policy seam** — the SPECIAL edit must keep the policy section's exact bytes (including its surrounding blank lines and the change-instruction line) so the T-013 text and its I.6-relevant markers are preserved; the body around it is the English `common/` text. The seam is between the policy `##` section and the adjacent `##` sections.
5. **`{{LANG}}=en` non-leak** — no English-path file is altered; the SPECIAL files only exist in the zh overlay, so the en render is untouched.
6. **Type-dir coverage** — F-14/F-15/F-16 are type-specific; ANGLICIZE-by-deletion must remove the zh copy under each type dir, and a `{{LANG}}=zh` init of EACH type (fullstack/backend/generic) must then fall through to that type's English `50-*.md`.
7. **Empty/seed-only files** — F-6 (`insight-index.md.tmpl`) and F-16 (`50-generic.md.tmpl`) are near-empty seed/stub files; anglicizing them is a clean delete (their English originals are the same near-empty shape).
8. **Cross-shell symmetry** — any test-init assertion added/changed must be PS+Bash symmetric (project NFR); the zh assertions are pure-grep and must tolerate the no-`python3` Bash path.
9. **I.6 self-trip** — describing this task (in docs, CHANGELOG, insight harvest) must not write the retired blunt-Chinese banned anchor literal that T-013 added; the SPECIAL files retain the policy text that is already I.6-clean as shipped (do not introduce the banned phrasing while editing the body).

## 7. Acceptance criteria (QA-verifiable via test-init on a generated zh project)

- **AC-1**: After the change, a `{{LANG}}=zh` init produces an `AI-GUIDE.md` byte-identical to the English `common/AI-GUIDE.md.tmpl` render (no Chinese AI-GUIDE). Verifiable by comparing the zh-init `AI-GUIDE.md` to the en-init `AI-GUIDE.md` for the same vars.
- **AC-2**: A `{{LANG}}=zh` init's `.harness/rules/05-insight-index.md`, `60-tool-handoff.md`, `75-safety-hook.md`, `.harness/insight-index.md`, `docs/workflow.md`, `docs/dev-map.md`, `docs/tasks.md`, and the type `.harness/rules/50-<type>.md` are each byte-identical to their English `common/`/type renders (the AI-facing files are now English).
- **AC-3**: A `{{LANG}}=zh` init's `.harness/rules/00-core.md` has an English framework body (its "How this project is developed", "Hard rules", "What lives where", etc. match the English `common/` text) BUT retains the T-013 Chinese policy section verbatim (the "输出语言（按消费者分流）" heading and its two consumer lists are present and Chinese).
- **AC-4**: A `{{LANG}}=zh` init's `CLAUDE.md` and `.github/copilot-instructions.md` have an English body (ruleset pointer + red-lines + static-stub note) but retain the one Chinese "输出语言：…" policy line verbatim.
- **AC-5**: A `{{LANG}}=zh` init's `docs/spec/README.md` remains Chinese (the "项目 SPEC" guide is unchanged).
- **AC-6**: A `{{LANG}}=zh` init's `evals/golden-tasks.md` remains Chinese (the "Golden Tasks — 轻量回归任务集" checklist is unchanged).
- **AC-7**: A `{{LANG}}=en` init is byte-identical to its pre-T-015 output (EN path untouched). Verifiable by diff against the prior render.
- **AC-8**: The existing `test-init` zh assertions still pass: `[zh] 00-core.md overlaid`, `[zh] policy lists a Chinese-artifact marker (给用户的交付总结)`, `[zh] policy lists an English-artifact marker (commit message)`, and `[zh] retired blunt 全程 phrasing is absent` — because the T-013 policy section (which contains both markers) is retained in the SPECIAL F-2 edit.
- **AC-9**: `test-init` gains **inverse-assertion coverage** for the anglicized files: it asserts BOTH that the human-facing files are still Chinese (presence of a ZH marker in `docs/spec/README.md` and `evals/golden-tasks.md`) AND that the AI-facing files are now the English version (presence of an EN-only marker / absence of a known ZH marker in `AI-GUIDE.md`, a rule fragment, `workflow.md`, `dev-map.md`, `tasks.md`). Added symmetrically in `test-init.ps1` and `test-init.sh`; `baseline.json` counts updated to a captured run.
- **AC-10**: `SKILL.md` step 4.3's zh-overlay file list names only the 5 files that remain in the overlay (the 3 SPECIAL + 2 KEEP-ZH) and no longer lists any anglicized file; no surviving sentence claims the zh overlay translates `AI-GUIDE.md` / the rule fragments / `workflow.md` / `dev-map.md` / `tasks.md`.
- **AC-11**: `verify_all` passes on the harness-kit repo (32/32, both shells) — including I.6 (no retired-claim regression: the retained policy text is the already-green T-013 text; no banned anchor is introduced), D.2 (no new placeholder), and G.3/G.4 (version/claim consistency after the bump).
- **AC-12**: CHANGELOG has a T-015 entry and the version is bumped; G.3/G.4 stay green. Check count stays 32 and skill count stays 14 (no new check, no new skill).

## 8. Non-functional requirements & downstream obligations the Architect must carry

- **NFR-1 (cross-platform symmetry)**: every added/changed test-init assertion is PS+Bash symmetric and pure-grep (no `python3` dependence on the Bash path).
- **NFR-2 (doc-size)**: removing overlay files and anglicizing bodies only shrinks generated files; no I.* doc-size cap is approached. The SKILL.md step-4.3 edit must not grow `SKILL.md` past any cap.
- **D-obligation 1 (inverse assertion — insight 2026-05-16)**: removing overlay files changes what a zh project contains; the test-init zh fixture MUST assert both presence (human-facing stays ZH) AND the new state (AI-facing is now the English version). A one-sided "still present" assertion would hide the very drift this task introduces. **This is the load-bearing test obligation.**
- **D-obligation 2 (version-worthy, NOT check/skill/placeholder change)**: per G.3/G.4 + insight 2026-06-05, a shipped-template content change is version-worthy → bump plugin.json/marketplace.json/README badges + CHANGELOG. Confirm: NO new verify_all check (count stays 32), NO new skill (stays 14), NO new `{{...}}` placeholder (D.2 untouched). The Architect confirms this scope.
- **D-obligation 3 (SKILL.md step-4.3 doc-drift)**: the enumerated overlay list at SKILL.md lines 107-108 currently advertises the full translated set; it must be updated to the post-anglicize remaining set, and the "files not in the overlay stay in English" sentence reconciled (it becomes the rule that DELIVERS this task's behavior). Failing to update it leaves a documented-vs-actual contradiction.
- **D-obligation 4 (I.6 self-trip — insight 2026-06-08 / T-013)**: when writing CHANGELOG / the insight harvest / any scanned doc describing this task, do NOT write the retired blunt-Chinese banned anchor literal; the SPECIAL edits preserve the already-I.6-clean T-013 policy text and must not reintroduce the banned phrasing in the anglicized body.
- **D-obligation 5 (baseline.json)**: the test-init assertion count changes (new inverse assertions, possibly fewer/more zh checks); `baseline.json` test_init PS/bash totals must be reconciled to a captured run, not hand-estimated (insight 2026-06-04 / T-007: never paste a tally that was not produced by a real run).
- **D-obligation 6 (type-dir deletion completeness)**: ANGLICIZE of F-14/F-15/F-16 means deleting the zh copy under EACH of `fullstack/`, `backend/`, `generic/`; the regression must exercise at least one zh-init per type (or assert the type 50-* fall-through for the type the zh fixture uses, plus a note for the others).

## 9. Related tasks (linked, not re-described)

- **T-013 / lang-policy-split** (`docs/features/_archived/lang-policy-split/`) — established the three-way OUTPUT policy and **explicitly logged this task as its follow-up** (07_DELIVERY.md: "prune/anglicize AI-facing files in the zh overlay so shipped scaffolding matches the policy"). Its §3 (A)/(B) distinction is the conceptual basis; its OQ-3 deferred exactly this work. The T-013 policy text this task preserves lives in F-2/F-7/F-8.
- **T-002 / ai-native-init** (`docs/features/_archived/ai-native-init/`) — established the i18n/zh overlay mechanics and the SKILL.md overlay-application order this task exploits.
- **T-012 / harness-upgrade-skill** (`docs/features/_archived/harness-upgrade-skill/`) — the content-refresh path for already-generated projects; relevant to the deferred-migration out-of-scope item (§5.7).
- **T-014 / harness-language-skill** (`docs/features/_archived/harness-language-skill/`) — the `/harness-language` init-time policy mechanism; relevant to OQ-3 below (whether the policy-carrying files could be served via that mechanism instead of duplicated SPECIAL overlay files).
- **T-008 / test-supervisor-stamps** + **T-010 / g4-version-decouple** — the G.3/G.4 version/claim gates AC-11/AC-12 must keep green.
- **Insight 2026-05-16 (one-sided assertion)** — directly governs D-obligation 1 / AC-9.

## 10. Open questions for the user (each with a recommended default)

> Most classifications are clear best-practice and are set as defaults in §3, not escalated. Only the three genuine forks below are raised. Recommended defaults are attached; the PM may approve-by-default and advance.

**OQ-1 — Policy-section PROSE language in the SPECIAL files: keep Chinese as T-013 shipped, or also anglicize it?**
The §3 SPECIAL decision keeps the T-013 policy section/line Chinese (the framework body around it becomes English). One could argue the policy section's PROSE should ALSO be English for full internal consistency (the file would then be 100% English; only the policy's MEANING — the three-way split — is what matters, and that meaning is language-independent).
(a) **Keep the policy section/line Chinese exactly as T-013 shipped (recommended default).** Does not reverse or re-touch T-013; the policy is the one place a zh user is guaranteed to read the language rule, so Chinese there has standalone value; smallest blast radius; preserves the existing test-init markers (AC-8) and the I.6-clean text.
(b) Anglicize the policy prose too (the whole SPECIAL file becomes English). Fuller consistency, but re-opens T-013's shipped text, breaks the existing `给用户的交付总结` test marker, and removes the one Chinese touchpoint that tells a zh user the policy.

**OQ-2 — `tasks.md.tmpl` (F-11) seed: ANGLICIZE (default) or KEEP-ZH?**
A genuine borderline. The board is AI-parsed and AI-appends English rows (T-013 C-4), which argues ANGLICIZE for consistency. But the seed header's "约定" / "任务怎么关联" prose is read by a human PM-style user setting up conventions early in a project.
(a) **ANGLICIZE (recommended default).** The file is fundamentally an AI-parsed coordination ledger; T-013 already routes its runtime content EN, so a Chinese seed under English rows is internally inconsistent; consistency with the English `common/` board.
(b) KEEP-ZH. Treat the seed's convention prose as human-facing onboarding. Product impact: a zh user reads the board conventions in Chinese, at the cost of a mixed-language board (Chinese header, English rows).

**OQ-3 (architecture flag for the SA, not a user-preference fork) — serve the policy-carrying files via the T-014 `/harness-language` init-time mechanism instead of three duplicated SPECIAL overlay files?**
The 3 SPECIAL files duplicate the English `common/` body just to carry a small Chinese policy block. An alternative: ship only the English `common/` versions (no SPECIAL overlay files) and have init invoke the T-014 language-policy mechanism to splice the Chinese policy block in, removing the body duplication.
(a) **Keep the policy-carrying files as SPECIAL overlay files (recommended default).** Simplest, no new init-time coupling, no change to the overlay-application contract; the SA evaluates but the default is the straightforward in-overlay edit.
(b) Wire the policy block via the T-014 mechanism at init. Removes body duplication but adds init-time coupling and a new failure surface; flagged for the SA to weigh, default to (a).

## 11. Verdict

**BLOCKED ON USER** — three open questions remain (OQ-1, OQ-2, OQ-3). OQ-1 (policy-prose language) and OQ-2 (`tasks.md` seed) are user-preference forks; OQ-3 is an architecture option flagged for the Solution Architect with a safe default. Recommended defaults are attached to all three. If the PM accepts all defaults as-is, the requirement collapses to: **delete the 11 AI-facing files from the zh overlay (fall through to English `common/`); edit the 3 policy-carrying files in place (English body, Chinese T-013 policy text kept verbatim); leave `docs/spec/README.md` and `evals/golden-tasks.md` Chinese; update SKILL.md step 4.3; add inverse test-init assertions; bump version + CHANGELOG; no new check / skill / placeholder.** The PM may approve-by-default and advance to the Solution Architect, or route the forks to the user.
