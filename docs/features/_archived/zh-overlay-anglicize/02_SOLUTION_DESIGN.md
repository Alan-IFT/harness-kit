# 02 — Solution Design · T-015 / zh-overlay-anglicize

> Stage 2 of the Harness pipeline. Mode: **full**. Author: Solution Architect.
> Upstream: `01_REQUIREMENT_ANALYSIS.md` (verdict flipped to **READY** by PM in `PM_LOG.md`; OQ-1 = keep zh
> policy prose, OQ-2 = anglicize `tasks.md.tmpl`, **OQ-3 = this document's design call**).
> All file:line citations are against the harness-kit repo at this commit. This is a STATIC template-content
> change only (the (B) layer in T-013's framing); no runtime behavior, no new skill, no new check, no new placeholder.

## 1. Architecture summary

A generated `{{LANG}}=zh` project today receives Chinese translations of AI-facing framework files
(`AI-GUIDE.md`, the rule fragments, `workflow.md`, `dev-map.md`, `tasks.md`, the type `50-*.md`, the insight
seed) because those files exist in the `templates/i18n/zh/` overlay and overwrite the English `common/`
originals during `SKILL.md` step 4.3 (lines 104-108). This contradicts the T-013 consumer-split policy the same
zh project now declares (AI-facing → English). This task **removes the 11 purely-AI-facing files from the zh
overlay** so init no longer overwrites the English `common/` versions — they fall through and ship English —
and **edits the 3 policy-carrying files in place** (English `common/` framework body, T-013 Chinese policy
section/line preserved byte-for-byte). The 2 genuinely human-facing files stay Chinese. No code path, no
runtime policy, and the `{{LANG}}=en` render are touched. The change surfaces in test-init (the heavy
regression for generated-project content) via new **inverse assertions**, and is version-worthy (0.25.0 →
0.26.0) with no skill/check/placeholder change.

## 2. The OQ-3 decision (the central design call) — **Option (A): keep the 3 SPECIAL files in the overlay.** RECOMMENDED & ADOPTED.

> OQ-3 asks: should the 3 policy-carrying files (`00-core.md.tmpl`, `CLAUDE.md.tmpl`,
> `copilot-instructions.md.tmpl`) stay as edited SPECIAL overlay files (A), or be **removed** from the overlay
> and have init splice the zh policy in via the T-014 `language-policy.{ps1,sh}` helper at init time (B)?

**Decision: (A). It is not merely the simpler option — (B) is actively infeasible as stated, because removing
those files would break the T-014 `/harness-language` command.** The feasibility analysis below is the load-bearing
reason; the maintainability argument the user's principle favors is *also* satisfied by (A) once you see that the
"duplication" (B) would eliminate is not actually duplicated.

### 2.1 The decisive finding: the SPECIAL files are the *canonical source* T-014 reads

`language-policy.ps1` lines 70-78 (and `language-policy.sh` lines 73-81) resolve the canonical zh policy text
**from the zh overlay templates themselves**:

```
# language-policy.sh:77-81  (LANG_ARG == "zh")
tmpl_common="$TEMPLATE_ROOT/skills/harness-init/templates/i18n/zh/common"
target_heading="$zh_heading"                              # "## 输出语言（按消费者分流）"
tmpl_core="$tmpl_common/.harness/rules/00-core.md.tmpl"   # ← the F-2 SPECIAL file
tmpl_claude="$tmpl_common/CLAUDE.md.tmpl"                 # ← the F-7 SPECIAL file
```

The helper then `Get-SectionLines` / extracts the `## 输出语言（按消费者分流）` block from
`i18n/zh/common/.harness/rules/00-core.md.tmpl` and the `^输出语言：` line from
`i18n/zh/common/CLAUDE.md.tmpl`. If option (B) **deleted** those two files, `Test-Path $tmplCore` (ps1:80) /
`[[ ! -f "$tmpl_core" ]]` (sh:83) would fail and the helper would `exit 1` — `/harness-language zh` would be
**permanently broken** for every user. (B) is therefore not "more elegant"; it is a regression in a shipped,
green command (T-014, AC-11 keeps verify_all 32/32). **The 3 SPECIAL files are dual-purpose: init overlay
source AND the T-014 canonical-text source. They must stay on disk regardless of OQ-3.**

### 2.2 The "duplication" (B) would remove is mostly illusory

(B)'s stated benefit is eliminating the English `common/` body duplicated into the SPECIAL overlay files. But:

- **The duplicated *body* is small and bounded.** F-2 (`00-core`) is the only file with a non-trivial body
  (~50 lines of framework prose). F-7 (`CLAUDE.md`) and F-8 (`copilot`) are ~14-line stubs whose only
  per-language difference is **one line** (the policy line). The drift surface is one medium file, not three.
- **(B) does not actually remove F-2/F-7/F-8 from disk** (per §2.1 — T-014 needs them as its source). So (B)
  would have to keep them AND add an init step — strictly more surface, not less.
- **The drift risk in (A) is caught.** AC-3/AC-4 + the new inverse assertions (§7) assert the SPECIAL files'
  English body matches the `common/` render markers; if a future edit to `common/00-core` body is not mirrored
  into the F-2 overlay, the inverse assertion (EN-body-marker present in the zh-init 00-core) still passes
  because both share the marker, but a *content* divergence in the framework body is a known, accepted, bounded
  maintenance cost that the test surface partially guards. (Full byte-equality of the non-policy body is
  documented as out-of-scope per §10.)

### 2.3 Why (B) also fails the secondary feasibility tests

Even setting §2.1 aside, (B) at init time fails on:

- **Init has no resolved `--template-root` of its own shape.** `language-policy` requires `--template-root`
  pointing at `<cache>/harness-kit/<version>/` (sh:74-81). During `/harness-init` the skill already knows the
  template root (step 3, SKILL.md:82-93), so this is *technically* reachable — but it adds an init-time
  coupling to a second helper, a second failure surface (the helper `exit 1`/`exit 2` conflict paths,
  SKILL.md harness-language §6), and a dependency on the helper being copied into the freshly-built project
  before it can run against it.
- **No verify_all / E-check asserts the swap happened.** `verify_all` runs on the harness-kit repo, not on a
  generated project; the only regression that exercises a generated zh project is `test-init`. So (B) buys no
  extra safety net — it adds an init step that only `test-init` could catch if it broke, exactly the same
  coverage (A) has, for more moving parts.
- **No-network / idempotence:** (A) is pure file copy + in-place edit (the existing overlay contract). (B)
  introduces a mutate-after-copy step whose idempotence and no-network guarantees would need their own
  test-init coverage. Net complexity up, benefit ≈ zero.

**Conclusion:** (A) is correct on the merits (not just by default). (B) would regress T-014, add init coupling,
and remove duplication that is small and partially test-guarded. **Adopt (A).**

## 3. Affected modules / files

| # | Path (relative to repo root) | Action |
|---|---|---|
| F-2 | `skills/harness-init/templates/i18n/zh/common/.harness/rules/00-core.md.tmpl` | **edit** (SPECIAL splice) |
| F-7 | `skills/harness-init/templates/i18n/zh/common/CLAUDE.md.tmpl` | **edit** (SPECIAL splice) |
| F-8 | `skills/harness-init/templates/i18n/zh/common/.github/copilot-instructions.md.tmpl` | **edit** (SPECIAL splice) |
| F-1 | `skills/harness-init/templates/i18n/zh/common/AI-GUIDE.md.tmpl` | **delete** |
| F-3 | `skills/harness-init/templates/i18n/zh/common/.harness/rules/05-insight-index.md.tmpl` | **delete** |
| F-4 | `skills/harness-init/templates/i18n/zh/common/.harness/rules/60-tool-handoff.md` | **delete** |
| F-5 | `skills/harness-init/templates/i18n/zh/common/.harness/rules/75-safety-hook.md.tmpl` | **delete** |
| F-6 | `skills/harness-init/templates/i18n/zh/common/.harness/insight-index.md.tmpl` | **delete** |
| F-9 | `skills/harness-init/templates/i18n/zh/common/docs/workflow.md` | **delete** |
| F-10 | `skills/harness-init/templates/i18n/zh/common/docs/dev-map.md.tmpl` | **delete** |
| F-11 | `skills/harness-init/templates/i18n/zh/common/docs/tasks.md.tmpl` | **delete** |
| F-14 | `skills/harness-init/templates/i18n/zh/fullstack/.harness/rules/50-fullstack.md` | **delete** |
| F-15 | `skills/harness-init/templates/i18n/zh/backend/.harness/rules/50-backend.md` | **delete** |
| F-16 | `skills/harness-init/templates/i18n/zh/generic/.harness/rules/50-generic.md.tmpl` | **delete** |
| F-12 | `skills/harness-init/templates/i18n/zh/common/docs/spec/README.md` | **keep (untouched)** |
| F-13 | `skills/harness-init/templates/i18n/zh/common/evals/golden-tasks.md.tmpl` | **keep (untouched)** |
| — | `skills/harness-init/SKILL.md` (step 4.3, lines 104-108) | **edit** (overlay file-list) |
| — | `.harness/scripts/test-init.ps1` (`Test-ZhOverlay`, lines 610-633) | **edit** (inverse assertions) |
| — | `.harness/scripts/test-init.sh` (`test_zh_overlay`, lines 514-529) | **edit** (inverse assertions) |
| — | `.harness/scripts/baseline.json` | **edit** (test_init counts → captured run) |
| — | `.claude-plugin/plugin.json` (line 4), `.claude-plugin/marketplace.json` (line 17) | **edit** (version 0.25.0→0.26.0) |
| — | `README.md` (line 5), `README.zh-CN.md` (line 5) | **edit** (version badge + test-init count badge) |
| — | `CHANGELOG.md` | **edit** (new `[0.26.0]` entry) |

There are no `.harness/agents/dev-*.md` partition agents (`PM_LOG.md` confirms single-Developer mode), so the
**Partition assignment** section is omitted per the agent spec.

## 4. The SPECIAL splice — exact verbatim text (the precise replacement)

The mechanism: each SPECIAL overlay file is rebuilt as **the English `common/` file, with the English
`## Output language (project-wide)` policy SECTION (F-2) / `Output language: **English**.` LINE (F-7, F-8)
replaced by the Chinese T-013 policy SECTION / LINE that the zh overlay already ships.** Net effect: framework
body becomes English; the policy text stays Chinese exactly as T-013 shipped it.

> ⚠ **Critical correctness note for the Developer:** the English `common/` file carries the **OLD blunt
> all-English policy** under a *different heading* (`## Output language (project-wide)`,
> `common/.harness/rules/00-core.md.tmpl:9`). The zh overlay carries the **T-013 three-way policy** under the
> heading `## 输出语言（按消费者分流）` (`i18n/zh/.../00-core.md.tmpl:9`). The splice must REPLACE the English
> `## Output language (project-wide)` section with the Chinese `## 输出语言（按消费者分流）` section — NOT keep
> both, NOT keep the English policy section. After the splice there is exactly **one** policy section and it is
> the Chinese T-013 one. (This is the same single-section invariant T-014 enforces, language-policy SKILL "Hard
> rules".)

### 4.1 F-2 — `00-core.md.tmpl` (the only non-trivial body)

The post-splice file = the English `common/.harness/rules/00-core.md.tmpl` (read in full), with its lines 9-22
(the `## Output language (project-wide)` section through the blank line before `## How this project is
developed`) replaced by the Chinese policy section from the current zh overlay file (its lines 9-32, the
`## 输出语言（按消费者分流）` heading through the blank line before `## 这个项目怎么开发`). Concretely:

- **English header + frontmatter** (`common/00-core.md.tmpl:1-7`) — keep English verbatim:
  `# {{PROJECT_NAME}} — Project Rules` … `(since v0.10 rules are referenced, not composed into \`CLAUDE.md\`).`
- **REPLACE** `common/00-core.md.tmpl:9-22` (the `## Output language (project-wide)` section, the old blunt
  all-English policy + its change-instruction line) **WITH** the verbatim Chinese block from the current zh
  overlay `i18n/zh/.../00-core.md.tmpl:9-31`. That block is (preserve byte-for-byte, including blank lines and
  the trailing change-instruction line):

  ```
  ## 输出语言（按消费者分流）

  本项目的 AI 产出**按主要消费者**分两种语言：面向人的用**中文**，面向下游 agent / LLM 的用**英文**（LLM 读英文同样顺畅，且与英文的框架内部保持一致、体积更小）。

  **用中文（消费者是人）：**

  - 跟用户的所有对话回复。
  - 错误消息、状态 / 进度报告、给用户的解释。
  - 给用户的交付总结（"交付了什么"的叙述性说明）。
  - 面向人的文档：`README.md` / `README.zh-CN.md` 以及 `docs/` 下供人阅读的指南。

  **用英文（消费者是下游 agent / LLM）：**

  - `docs/features/<task>/` 下每份阶段文档：`01_REQUIREMENT_ANALYSIS.md` … `07_DELIVERY.md`，以及 `PM_LOG.md`。
  - `docs/tasks.md`、`docs/dev-map.md`、`.harness/insight-index.md` 这些台账的追加内容。
  - AI 编辑的 `.harness/agents/*.md`、`.harness/rules/*.md`、`AI-GUIDE.md`、`CLAUDE.md`。
  - 代码注释、commit message。

  被人和 agent 同时读的产物（阶段文档、台账、注释、commit），按"更严格的消费者"打破平局 —— 即下游 agent，因此用英文；人审阅英文同样没问题。

  **不要在同一份产物里混用语言。** 即使用户用其他语言发消息，对话回复仍用中文（内部理解用户意图，输出按上面的分流规则）。

  要修改语言策略，编辑 `.harness/rules/00-core.md` 的"输出语言"章节 —— 按引用生效，不需要 sync 步骤。
  ```

- **English body after the policy** (`common/00-core.md.tmpl:24-77`) — keep English verbatim:
  `## How this project is developed`, `## Hard rules (red lines)`, `## Style / convention`,
  `## What lives where`, `## When in doubt`.

The seam is the `## ` heading boundary: the Chinese section ends right before `## How this project is
developed`. Both the English body and the Chinese policy section contain `{{PROJECT_NAME}}` / `{{PROJECT_TYPE}}`
/ `{{STACK}}` / `{{TODAY}}` only in the header (lines 1-3), which is the English header kept as-is — no new
placeholder is introduced (D.2 §6).

### 4.2 F-7 — `CLAUDE.md.tmpl`

Post-splice = the English `common/CLAUDE.md.tmpl` (read in full, lines 1-13) with **only line 3** replaced. The
English line 3 is `Output language: **English**.`; replace it verbatim with the Chinese policy line from the
current zh overlay `i18n/zh/.../CLAUDE.md.tmpl:3`:

```
输出语言：面向人的产出（对话、报告、README/人读文档）用**中文**，面向 agent/LLM 的产出（阶段文档、台账、规则、注释、commit）用**英文**。完整分流见 `.harness/rules/00-core.md`。
```

Every other line (the `# {{PROJECT_NAME}} — bootstrap rules` title, the ruleset-pointer paragraph, the four
red-line bullets, the static-stub closing paragraph) is the English `common/` text verbatim.

### 4.3 F-8 — `copilot-instructions.md.tmpl`

Post-splice = the English `common/.github/copilot-instructions.md.tmpl` (read in full, lines 1-16) with **only
line 6** replaced (the `Output language: **English**.` line → the same Chinese policy line as F-7, which is
`i18n/zh/.../copilot-instructions.md.tmpl:6`):

```
输出语言：面向人的产出（对话、报告、README/人读文档）用**中文**，面向 agent/LLM 的产出（阶段文档、台账、规则、注释、commit）用**英文**。完整分流见 `.harness/rules/00-core.md`。
```

Keep the `--- / applyTo: "**" / ---` frontmatter (lines 1-3) and the rest of the English body verbatim. Note
the English `common/` copilot's 4th red line is the "One role at a time …" line (`common/copilot:14`), which
is the **correct** English body to ship — the current zh overlay copilot already carries the matching Chinese
"一次一个角色…" line, so anglicizing the body here means adopting the English "One role at a time" line. (Do
NOT carry over the zh red-line bullets; only the one policy line is preserved.)

### 4.4 Implementation note (L10 — Edit may silently no-op)

The cleanest implementation per SPECIAL file is **Write the full post-splice file** (the English body with the
one Chinese section/line swapped in) rather than a chain of in-place `Edit` calls, because (a) the English body
replaces most of the current zh file, so an Edit-based approach is many small edits, and (b) insight L10 warns
the Edit tool can silently no-op. After each Write, the Developer should re-Read and confirm the file contains
both an English body marker (e.g. `## Hard rules (red lines)` for F-2) AND the Chinese policy heading/line
(`## 输出语言（按消费者分流）` for F-2; `输出语言：` for F-7/F-8). CJK must be written as UTF-8 (no BOM), matching
the existing zh overlay encoding.

## 5. The 11 ANGLICIZE deletions — fall-through confirmation + unique-content audit

Each deletion removes the zh overlay file so init's step-4.3 copy no longer overwrites the English `common/`
(or type-dir) original, which then ships verbatim. **All 11 fall-through targets are confirmed present on disk**
(Glob, this session): the 8 `common/` targets (`AI-GUIDE.md.tmpl`, `05-insight-index.md.tmpl`,
`60-tool-handoff.md`, `75-safety-hook.md.tmpl`, `insight-index.md.tmpl`, `docs/workflow.md`,
`docs/dev-map.md.tmpl`, `docs/tasks.md.tmpl`) and the 3 type-dir targets (`fullstack/50-fullstack.md`,
`backend/50-backend.md`, `generic/50-generic.md.tmpl`).

**Unique-content audit (the top risk — a deleted zh file carrying content NOT in the English original):** I
compared the first-line/structural markers of each zh overlay file against its English original. Every zh file
is a **translation of the same structure** (same headings, same `{{...}}` placeholders, same body shape), e.g.
`AI-GUIDE.md` zh `# AI-GUIDE — … 项目指南` mirrors en `# AI-GUIDE — … project index`; `workflow.md` zh
`# 工作流：7-Agent 流水线` mirrors en `# Workflow: The 7-Agent Pipeline`; the rule fragments, dev-map, tasks,
insight-index, and type `50-*` files are structural translations. **No zh-unique content (a section, rule, or
data a zh project NEEDS that has no English counterpart) was found.** The zh overlay was already missing
`65-intervention.md` / `70-doc-size.md` translations (per `PM_LOG.md:29` / RA §5.5) — anglicizing the rule
fragments makes that pre-existing gap moot, not worse. **Residual: low.** The mitigation is the inverse
assertion (§7) which proves the zh-init now ships the English version (not a missing file).

## 6. Data model / API contracts

None. No schema, no DB, no API, no `{{...}}` placeholder change. The fall-through targets are the existing
D.2-clean English `.tmpl` files (test-init's recursive `\{\{[A-Z_]+\}\}` scan already passes on them); deleting
the zh duplicates removes placeholders, never adds any. The SPECIAL splices keep the English header's existing
placeholders and add no new ones (§4).

## 7. test-init inverse assertions (the load-bearing carry) — exact marker design

`test-init` builds a zh fixture by layering `common/` → `fullstack/` → `i18n/zh/common/` (sh:518-520,
ps1:620-622), mirroring SKILL.md step 4.3. After this task the i18n/zh layer no longer overwrites the 11
anglicized files, so the fixture's `AI-GUIDE.md`, rule fragments, `workflow.md`, `dev-map.md`, `tasks.md` are
the **English** copies; `00-core.md` has the **English body + Chinese policy section**; `docs/spec/README.md`
and `evals/golden-tasks.md` stay **Chinese**.

> **Fixture gap to fix:** the current fixture only layers `i18n/zh/common` (sh:520, ps1:622). To exercise the
> F-14 type-dir fall-through (`50-fullstack.md`), the fixture already copies the `fullstack/` English layer and
> (after this task) no `i18n/zh/fullstack` layer overwrites it — so a `50-fullstack.md` EN assertion is valid
> with the existing layering. (D-obligation 6: the fixture is fullstack, so it covers the fullstack type
> fall-through; backend/generic type fall-through is covered structurally by the same delete + a note in the
> CHANGELOG. No need to add backend/generic fixtures — the mechanism is identical.)

**Marker discriminators (read from the actual files this session — stable EN-vs-ZH pairs):**

| File in zh fixture | Assert PRESENT (post-change state) | Assert ABSENT (old state) | Rationale |
|---|---|---|---|
| `AI-GUIDE.md` | `project index` (en, `common/AI-GUIDE.md.tmpl:1`) | `项目指南` (zh, was line 1) | AI-facing now EN |
| `.harness/rules/05-insight-index.md` | `Cross-task insight index` (en, `:1`) | `跨任务 Insight Index` (zh) | rule frag now EN |
| `docs/workflow.md` | `Workflow: The 7-Agent Pipeline` (en, `:1`) | `工作流` (zh) | pipeline def now EN |
| `docs/dev-map.md` | `Dev Map` (en, `:1`) | `开发导航` (zh) | nav index now EN |
| `docs/tasks.md` | `Task Board` (en, `:1`) | `任务看板` (zh) | board now EN |
| `.harness/rules/50-fullstack.md` | an EN marker from `fullstack/50-fullstack.md` (Developer picks a stable EN heading present there) | a known zh marker from the deleted `i18n/zh/fullstack/50-fullstack.md` | type-dir fall-through EN |
| `.harness/rules/00-core.md` | English body marker `## Hard rules (red lines)` (en, `common/00-core:32`) | English-policy marker `Output language (project-wide)` ABSENT | body EN, but… |
| `.harness/rules/00-core.md` | Chinese policy heading `输出语言（按消费者分流）` PRESENT | — | …policy stays ZH (AC-3) |
| `docs/spec/README.md` | `项目 SPEC` (zh, `:1`) | — | human-facing stays ZH (AC-5) |
| `evals/golden-tasks.md` | `轻量回归任务集` (zh, `:1`) | — | human-facing stays ZH (AC-6) |

**No T-007 trap:** every assertion pair tests **present** and **absent** on *different* strings (e.g. present
`project index`, absent `项目指南`) — never the same string both ways. The existing 4 zh assertions
(sh:523-526, ps1:625-628) are **retained as-is** — they target `00-core.md`'s policy section which the F-2
splice preserves (`给用户的交付总结`, `commit message` both live in the Chinese policy block that stays), so
AC-8 holds with no marker move. One refinement: the `[zh] retired blunt 全程 phrasing is absent` assertion
(sh:526) stays valid (the policy block has no `全程`).

**Cross-shell symmetry + no-python3 (NFR-1):** all new assertions are pure `grep -q` (bash) /
`(Get-Content -Raw) -match` (PS) over the fixture files, with no `python3` dependence — identical to the
existing zh assertions' style. They are added symmetrically inside `test_zh_overlay` (sh) and `Test-ZhOverlay`
(ps1). For the ABSENT-of-Chinese checks, bash uses `! grep -q '项目指南' "$file"` and PS uses
`-not ((Get-Content $file -Raw) -match '项目指南')` (the same negation form already used at sh:526 / ps1:628).

**baseline.json (D-obligation 5 / L27):** adding ~12-16 assertions changes
`test_init_ps_assertions` (currently 255) and `test_init_bash_no_python3_assertions` (currently 217). The
Developer MUST run `test-init` in BOTH shells, read the printed totals, and paste the **captured** counts into
`baseline.json` lines 11-12 — never hand-estimate (insight 2026-06-04 / T-007). The README `test-init` badge
(currently `255/255`) tracks the PS total and updates to the captured PS number (§9).

## 8. SKILL.md step-4.3 overlay-file-list update (AC-10 / D-obligation 3)

`SKILL.md:107` currently enumerates the full translated set:

> The `zh` overlay translates: the bootstrap stubs (`CLAUDE.md.tmpl`, `.github/copilot-instructions.md.tmpl`,
> `AI-GUIDE.md.tmpl`), the rule fragments (`00-core.md.tmpl`, `05-insight-index.md.tmpl`, `60-tool-handoff.md`,
> `75-safety-hook.md.tmpl`, `50-fullstack.md` / `50-backend.md` / `50-generic.md.tmpl`),
> `.harness/insight-index.md.tmpl`, and the docs/evals (`docs/workflow.md`, `docs/dev-map.md.tmpl`,
> `docs/tasks.md.tmpl`, `docs/spec/README.md`, `evals/golden-tasks.md.tmpl`).

Replace it to name only the **5 files that remain** in the overlay after this task, and reframe the
fall-through as the deliberate mechanism. Proposed replacement text (Developer adjusts wording to fit SKILL.md
style; the *content* is fixed):

> The `zh` overlay carries only the files a generated zh project should read in Chinese: the **policy-carrying
> files** (`00-core.md.tmpl`, `CLAUDE.md.tmpl`, `.github/copilot-instructions.md.tmpl`), whose framework BODY
> is the English `common/` text but which retain the Chinese consumer-split output-language policy
> section/line; and the **human-facing files** (`docs/spec/README.md`, `evals/golden-tasks.md.tmpl`). Per the
> output-language policy, every AI-facing framework file (`AI-GUIDE.md`, the other rule fragments, the type
> `50-*.md`, `.harness/insight-index.md`, `docs/workflow.md`, `docs/dev-map.md`, `docs/tasks.md`) is NOT in the
> zh overlay and therefore falls through to its English `common/`/type version.

The next sentence (`SKILL.md:108`, "Files **not** in the overlay … stay in English") is now consistent and can
stay, optionally tightened to note it is the *intended* anglicization mechanism for AI-facing files. This edit
shrinks SKILL.md (NFR-2; no doc-size cap risk).

## 9. Version fan-out (0.25.0 → 0.26.0) — G.3 sites + CHANGELOG

A shipped-template content change is version-worthy (G.3/G.4 + insight 2026-06-05). Bump **0.25.0 → 0.26.0**
(minor: a behavior-visible change to what a zh project generates):

| Site | Current | New |
|---|---|---|
| `.claude-plugin/plugin.json:4` | `"version": "0.25.0"` | `"version": "0.26.0"` |
| `.claude-plugin/marketplace.json:17` | `"version": "0.25.0"` | `"version": "0.26.0"` |
| `README.md:5` version badge | `version-0.25.0` | `version-0.26.0` |
| `README.zh-CN.md:5` version badge | `version-0.25.0` | `version-0.26.0` |
| `README.md:5` test-init badge | `test--init-255%2F255` | captured PS total `/` itself |
| `README.zh-CN.md:5` test-init badge | `test--init-255%2F255` | captured PS total `/` itself |

**Counts that DO NOT change (confirm in the CHANGELOG entry, per AC-12):** skill count stays **14**
(README ×2, AI-GUIDE, `40-locations.md:30`, dev-map, getting-started — no edit needed, no new skill);
`verify_all` check count stays **32** (no new lettered check — this is a template-content change, not a new
verify rule). No new `{{...}}` placeholder (D.2 untouched). I.6 banned/exempt lists unchanged (the preserved
zh policy text is the already-green T-013 text; see §10).

**CHANGELOG `[0.26.0]` entry** — a new top section above `[0.25.0]`, mirroring the `[0.24.0]`/`[0.25.0]` style:
a `### Changed — anglicize AI-facing scaffolding in the zh overlay (T-015)` block listing (a) the 11 deletions
+ the SPECIAL splice of the 3 policy files (EN body, Chinese policy preserved), (b) the SKILL.md step-4.3
file-list correction, (c) the new test-init inverse assertions + baseline reconciliation, (d) the version bump
line, (e) explicit "skill count stays 14, verify_all stays 32 checks, no new placeholder". **L36 (same-file
claim uniqueness):** keep each CHANGELOG bullet's claim phrasing distinct from the existing [0.24.0]/[0.25.0]
zh bullets (those describe the *policy text* change; this entry describes the *scaffolding language* change —
already distinct framings).

## 10. Risk analysis

| # | Risk | Likelihood | Mitigation |
|---|---|---|---|
| R-1 | **A deleted zh file carried unique content a zh project needs** (top risk) | Low | §5 unique-content audit found none — every zh file is a structural translation of its English original; the inverse assertions (§7) prove the zh-init ships the English version, not a gap. |
| R-2 | **(A) duplication drift**: a future edit to `common/00-core` framework body is not mirrored into the F-2 overlay | Medium (long-lived) | Accepted, bounded cost (one medium file; F-7/F-8 differ by one line). Documented in §2.2. Out of scope: full byte-equality of the SPECIAL non-policy body (a future "single-source SPECIAL body" task could splice at init from `common/`, but §2.1 shows that must NOT delete the files). |
| R-3 | **SPECIAL splice keeps BOTH policy sections** (English `## Output language (project-wide)` left in alongside the Chinese one) | Medium (easy mistake) | §4's ⚠ note: the splice REPLACES the English policy section with the Chinese one; the inverse assertion asserts `Output language (project-wide)` is ABSENT from the zh-init 00-core (§7), catching a double-section. |
| R-4 | **I.6 self-trip**: writing the banned `全程`…`中文` anchor in a scanned file while describing the task | Low (3× prior recurrence) | This design doc + CHANGELOG are I.6-exempt (`docs/features/`, `CHANGELOG.md` per verify_all.sh:548-561). The SPECIAL F-2 splice preserves the T-013 policy block which uses `按消费者分流` and `对话回复仍用中文` (no `全程` precedes `中文` within 40 chars) — already-green. The Developer must NOT introduce `全程中文` phrasing in SKILL.md / READMEs / AI-GUIDE / test-init (all scanned). |
| R-5 | **baseline.json hand-estimated** instead of captured | Low | §7 / D-obligation 5: run both shells, paste printed totals; the README badge derives from the PS run. |
| R-6 | **Edit silently no-ops** on the SPECIAL files (L10) | Low | §4.4: Write the full file, then re-Read and assert both EN-body and ZH-policy markers present. |
| R-7 | **test-init fixture only covers fullstack type** (backend/generic type fall-through unverified) | Low | D-obligation 6: the fullstack fixture verifies the `50-fullstack.md` fall-through; backend/generic use the identical delete mechanism, noted in CHANGELOG. Adding two more fixtures is out of scope (no new behavior to cover). |

## 11. Migration / rollout plan

- **Backwards compatibility:** the `{{LANG}}=en` path is byte-identical (no English `common/` file is touched;
  the SPECIAL files exist only in the zh overlay) — AC-7. T-014 `/harness-language zh` keeps working because the
  SPECIAL files remain on disk as its canonical source (§2.1).
- **Already-generated zh projects are NOT migrated** (RA §5.7) — a zh project initialized before this change
  keeps its Chinese AI-facing files; the content-refresh path is `/harness-upgrade` (separate task surface).
  No data migration, no feature flag.
- **Rollback:** pure git revert of the deletions + SPECIAL edits + version bump restores the prior state; no
  state outside the repo.
- **Sequence (single Developer):** (1) edit the 3 SPECIAL files (Write-then-verify); (2) delete the 11 ANGLICIZE
  files (including the 3 type-dir copies); (3) edit SKILL.md step 4.3; (4) add inverse assertions to both
  test-init shells; (5) run test-init both shells, capture totals → baseline.json + README badge; (6) version
  bump (4 G.3 sites) + CHANGELOG; (7) run `verify_all` both shells → 32/32.

## 12. Out-of-scope clarifications

- **Full byte-equality of the SPECIAL non-policy body** with `common/` (R-2): not enforced this task; the
  splice copies the current English `common/` body, which is correct *now*.
- **Anglicizing the policy PROSE itself** (OQ-1 (b)): rejected by PM — the Chinese T-013 policy section/line is
  kept verbatim.
- **`tasks.md.tmpl` kept Chinese** (OQ-2 (b)): rejected by PM — it is anglicized (deleted from overlay).
- **(B) init-time policy splice via T-014** (OQ-3 (b)): rejected — §2 (would break T-014, adds coupling).
- **harness-kit's own dogfood repo** (its English `AI-GUIDE.md`/`00-core.md`/`CLAUDE.md`): untouched — red line.
- **The runtime output-language policy** (T-013's (A) layer): already shipped; not this task.
- **backend/generic test-init fixtures**, **new language overlays**, **per-init language toggle**: out (RA §5).

## 13. Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| Anglicize a file = delete from overlay → fall through to English | SKILL.md step-4.3 overlay-application order (`common`→type→`i18n/zh`) | `skills/harness-init/SKILL.md:104-108` | Reuse the existing mechanism as-is (the whole task is built on it). |
| Canonical zh policy text source | T-014 `language-policy.{ps1,sh}` reads it from the SPECIAL files | `templates/common/.harness/scripts/language-policy.{ps1,sh}` (ps1:74-78 / sh:77-81) | Do NOT delete F-2/F-7/F-8 — they are this helper's source (decisive OQ-3 reason). |
| zh fixture regression harness | `test_zh_overlay` / `Test-ZhOverlay` (layers common→fullstack→i18n/zh, pure-grep asserts) | `.harness/scripts/test-init.{sh:514-529, ps1:610-633}` | Extend in place with inverse assertions; keep the existing 4 (AC-8). |
| Inverse-assertion pattern (present+absent on different strings) | existing zh assertions + the `! grep` / `-not -match` negation | `test-init.sh:526` / `test-init.ps1:628` | Reuse the negation form for the ABSENT-of-Chinese checks. |
| I.6 retired-claim guard + exempt list | `i6_banned` (`全程~中文`) + `i6_exempt_files`/`i6_exempt_dirs` | `.harness/scripts/verify_all.sh:522-561` | Rely on the existing exemptions (CHANGELOG, docs/features/); preserve the already-green T-013 policy text. |
| Version fan-out sites | G.3 set (plugin.json, marketplace.json, both README badges) + CHANGELOG | `.claude-plugin/{plugin,marketplace}.json`, `README.md:5`, `README.zh-CN.md:5`, `CHANGELOG.md` | Reuse the [0.24.0]/[0.25.0] entry shape. |
| Baseline count reconciliation | `baseline.json` test_init keys | `.harness/scripts/baseline.json:11-12` | Update from a captured run (no hand-estimate). |

## 14. AC / D-obligation traceability

| AC | Covered by | DO | Covered by |
|---|---|---|---|
| AC-1 (AI-GUIDE EN) | §5 delete F-1 + §7 marker `project index`/`项目指南` | DO-1 inverse assertion | §7 (present+absent on different strings) |
| AC-2 (rule frags/docs/type EN) | §5 deletes F-3/4/5/6/9/10/11/14/15/16 + §7 markers | DO-2 version, no check/skill/placeholder | §9 (0.26.0; 14/32 unchanged; D.2 §6) |
| AC-3 (00-core EN body + ZH policy) | §4.1 splice + §7 (`## Hard rules` present, `Output language (project-wide)` absent, `输出语言（按消费者分流）` present) | DO-3 SKILL.md step-4.3 | §8 |
| AC-4 (CLAUDE/copilot EN body + ZH line) | §4.2/§4.3 splice | DO-4 I.6 self-trip | §10 R-4 |
| AC-5/AC-6 (spec/golden stay ZH) | §3 keep F-12/F-13 + §7 (`项目 SPEC`, `轻量回归任务集`) | DO-5 baseline captured | §7 / §10 R-5 |
| AC-7 (en path byte-identical) | §11 (no English file touched) | DO-6 type-dir completeness | §7 fixture note + §10 R-7 |
| AC-8 (existing 4 zh assertions pass) | §7 (retained; F-2 preserves the markers) | | |
| AC-9 (inverse coverage) | §7 (full table) | | |
| AC-10 (SKILL.md lists 5) | §8 | | |
| AC-11 (verify_all 32/32) | §9 + §10 R-4 (no I.6/D.2 regression) | | |
| AC-12 (CHANGELOG + bump, 32/14) | §9 | | |

## 15. Verdict

**READY.** The design is complete and code-grounded: OQ-3 resolved to (A) with a decisive feasibility finding
(removing the SPECIAL files would break T-014 — they are its canonical-text source, ps1:74-78 / sh:77-81); the
SPECIAL splice is specified verbatim with exact line boundaries; all 11 deletions have confirmed-present
fall-through targets and no unique-content loss; the inverse assertions have exact, file-verified EN/ZH marker
strings with no T-007 trap; the version fan-out and count-stability are pinned. A single Developer can implement
this without further design decisions. No upstream block.
