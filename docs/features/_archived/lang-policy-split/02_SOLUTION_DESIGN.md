# 02 — Solution Design · T-013 / lang-policy-split

> Stage 2 of the Harness pipeline. Mode: **full**. Author: Solution Architect.
> Upstream verdict: `01_REQUIREMENT_ANALYSIS.md` = **READY** (PM accepted all 6 RA defaults; see `PM_LOG.md` OQ-resolution block).
> This is a docs-and-templates content change to the *shipped init templates* + SKILL.md + READMEs + manual-e2e + the I.6 guard + one symmetric test-init assertion + a version bump. **No production source code.** Single-developer mode (no `.harness/agents/dev-*.md`).

---

## 1. Architecture summary

When a user picks Chinese at init (`{{LANG}}=zh`), the generated project today carries a **blunt "everything in Chinese"** output-language policy (zh overlay `00-core.md.tmpl` §"输出语言（全项目）"). This task rewrites that policy — and its advertised summaries in `CLAUDE.md`/`copilot-instructions` stubs, SKILL.md Q5, both READMEs, and manual-e2e — into a **three-way runtime-output split**: chat replies / errors / status / human-facing delivery messages / human docs → **Chinese**; all AI-facing work products (7-stage docs, ledgers, rules, agents, AI-GUIDE/CLAUDE edits, code comments, commit messages) → **English**. The change is **text-only** inside the existing zh overlay (no new placeholder, no overlay structural change, no template re-translation — OQ-3 deferred). The English (`{{LANG}}=en`) path stays **byte-unchanged**. To keep the retired blunt phrasing from creeping back, an I.6 retired-claim banned-line is added (CJK-safe via the existing gap-tolerant ordered-anchor matcher), the first-ever test-init language assertion is added (symmetric PS+Bash, no-python3-tolerant) on a new zh-overlay fixture, and the version fans out 0.23.0 → 0.24.0.

---

## 2. Affected modules / files

| # | File (absolute under repo root) | Kind | Change |
|---|---|---|---|
| F1 | `skills/harness-init/templates/i18n/zh/common/.harness/rules/00-core.md.tmpl` | template (zh overlay) | **rewrite §"输出语言（全项目）"** (the primary edit) |
| F2 | `skills/harness-init/templates/i18n/zh/common/CLAUDE.md.tmpl` | template (zh overlay) | rewrite top "输出语言：**中文**。" line |
| F3 | `skills/harness-init/templates/i18n/zh/common/.github/copilot-instructions.md.tmpl` | template (zh overlay) | rewrite top "输出语言：**中文**。" line (symmetric with F2) |
| F4 | `skills/harness-init/SKILL.md` | skill | Q5 `中文 (Chinese)` option text (line 72) + step-4.3 stale overlay file list (line 107, D-3) |
| F5 | `README.md` | doc | §"Project-wide language policy" (lines 141-145) + version badge + test-init count badge/prose |
| F6 | `README.zh-CN.md` | doc | §"项目级语言策略" (lines 141-145) + version badge + test-init count prose |
| F7 | `docs/manual-e2e-test.md` | doc | Q5/language expectation (line 101) |
| F8 | `.harness/scripts/verify_all.ps1` | script | I.6 banned-line entry (add to `$banned`, ~line 500) |
| F9 | `.harness/scripts/verify_all.sh` | script | I.6 banned-line entry (add to `i6_banned`, ~line 535) — 1:1 twin of F8 |
| F10 | `.harness/scripts/test-init.ps1` | script | new `Test-ZhOverlay` function + dispatch call (AC-9) |
| F11 | `.harness/scripts/test-init.sh` | script | new `test_zh_overlay` function + dispatch call (AC-9) — symmetric twin of F10 |
| F12 | `.claude-plugin/plugin.json` | manifest | `version` 0.23.0 → 0.24.0 |
| F13 | `.claude-plugin/marketplace.json` | manifest | `plugins[0].version` 0.23.0 → 0.24.0 |
| F14 | `CHANGELOG.md` | doc | new `[0.24.0]` entry |

**Files explicitly NOT touched** (proves scope discipline / AC-7 / OQ-3):
- The EN-path templates `skills/harness-init/templates/common/.harness/rules/00-core.md.tmpl` and `.../common/CLAUDE.md.tmpl` — **byte-unchanged** (AC-7, OQ-6=a).
- The dogfood repo's own `CLAUDE.md` / `.harness/rules/00-core.md` — out of scope (DO-6 red line; dogfood stays English).
- All other zh overlay files (`AI-GUIDE.md.tmpl`, `05-insight-index.md.tmpl`, `75-safety-hook.md.tmpl`, `insight-index.md.tmpl`, `workflow.md`, etc.) — OQ-3 deferred (the (B) re-translation is the logged T-014 follow-up).
- `verify_all` D.2 placeholder whitelists — no new `{{...}}` (DO-2).

---

## 3. The exact rewritten zh policy text — F1 (`00-core.md.tmpl`)

This is the **primary rewrite** (AC-2). The policy text remains **Chinese prose** describing the split — per OQ-3 we are NOT migrating the AI-facing template body to English this iteration; we only rewrite the OUTPUT-POLICY *content*. The (B) re-translation of the rest of the file is the logged follow-up, out of scope here.

### Current block — `00-core.md.tmpl` lines 9-22 (verbatim, the REMOVE target)

```markdown
## 输出语言（全项目）

**本项目所有 AI 产出必须使用中文。** 适用于：

- 跟用户的所有对话回复。
- Agent 之间的交接（PM 派发、Architect 描述等）。
- `docs/features/<task>/` 下每份阶段文档：`01_REQUIREMENT_ANALYSIS.md`、`02_SOLUTION_DESIGN.md`、`03_GATE_REVIEW.md`、`04_DEVELOPMENT.md`、`05_CODE_REVIEW.md`、`06_TEST_REPORT.md`、`07_DELIVERY.md`、以及 `PM_LOG.md`。
- 对 `docs/tasks.md` 和 `docs/dev-map.md` 的更新。
- 错误消息、状态报告、给用户的解释。
- 适当的代码注释。

**不要混用语言。** 即使用户用其他语言发消息，也用中文回答（内部理解用户意图，外部输出中文）。这样仓库里所有产出都对所有协作者可读。

要修改项目语言，编辑 `.harness/rules/00-core.md` 的"输出语言"章节 —— 按引用生效，不需要 sync 步骤。
```

### Proposed replacement block (verbatim — Developer types this exactly)

```markdown
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

**Why two explicit lists (AC-2):** the requirement §4 net-headline is *Chinese = chat/errors/status/human-delivery/human-docs; English = stage docs/ledgers/rules-agents-guide-edits/comments/commits*. Rendering it as a ZH-list + EN-list (each a bullet block under a bold header) is the most unambiguous form for a downstream agent to follow at task time and is exactly what AC-9's test asserts (one marker from each list).

**Size check (NFR-2):** the file is 77 lines today; this block grows §"输出语言" from 14 lines to ~23 lines, net file ~86 lines — far under the I.2 200-line WARN cap. No size risk.

**Placeholder check (DO-2 / test-init regression):** the new block contains **zero** `{{...}}` tokens. The only braces are the literal `docs/features/<task>/` path (already present in the original, uses `<task>` angle brackets, not `{{ }}` — does not match `\{\{[A-Za-z_]...\}\}`). Safe against the test-init recursive placeholder scan (test-init.sh:187 / .ps1 BUG-2 regex).

**Heading rename note for the Developer:** the section heading changes from `## 输出语言（全项目）` to `## 输出语言（按消费者分流）`. The CLAUDE.md/copilot stubs and the SKILL.md note refer to it only as the "输出语言" section (substring), so the rename does not break any pointer. **AI-GUIDE index check:** the zh `AI-GUIDE.md.tmpl` indexes `00-core.md` as a file, not by sub-heading — confirm with a grep during dev (no heading-level reference expected).

---

## 4. The stub top-line edits — F2 (`CLAUDE.md.tmpl`) + F3 (`copilot-instructions.md.tmpl`)

Both stubs must stay **symmetric** (AC-1, AC-3): same one-line split summary, both pointing at `00-core.md` for the full table.

### F2 — `CLAUDE.md.tmpl` line 3

**Before:**
```markdown
输出语言：**中文**。
```
**After:**
```markdown
输出语言：面向人的产出（对话、报告、README/人读文档）用**中文**，面向 agent/LLM 的产出（阶段文档、台账、规则、注释、commit）用**英文**。完整分流见 `.harness/rules/00-core.md`。
```

### F3 — `copilot-instructions.md.tmpl` line 6

**Before:**
```markdown
输出语言：**中文**。
```
**After:** (identical string to F2 — symmetric stub)
```markdown
输出语言：面向人的产出（对话、报告、README/人读文档）用**中文**，面向 agent/LLM 的产出（阶段文档、台账、规则、注释、commit）用**英文**。完整分流见 `.harness/rules/00-core.md`。
```

These are ~15-line static stubs (init writes once, never regenerated — SKILL.md §4 / `00-core.md.tmpl` red line 7). The one-line summary keeps them tiny while pointing at the authoritative table. No placeholder introduced.

---

## 5. SKILL.md Q5 rewrite + step-4.3 doc-drift fix — F4

### F4a — Q5 `中文 (Chinese)` option text — SKILL.md line 72 (AC-4)

**Before (line 72):**
```markdown
   - `中文 (Chinese)` — **项目内 AI 全程使用中文输出**。包括：对话回复、agent 间交接、所有任务阶段文档、tasks.md / dev-map.md 更新、错误消息、状态报告。即使用户用其他语言提问，AI 也用中文回答。
```
**After (line 72):**
```markdown
   - `中文 (Chinese)` — **按消费者分流**：面向人的产出（对话回复、错误消息、状态/进度报告、给用户的交付总结、README 及人读文档）用**中文**；面向下游 agent/LLM 的产出（01–07 阶段文档、PM_LOG、tasks.md/dev-map/insight-index 台账、agent/rule/AI-GUIDE/CLAUDE 编辑、代码注释、commit message）用**英文**。即使用户用其他语言提问，对话回复仍用中文。
```

**Confirm no surviving blunt sentence (AC-4):** the phrase "全程使用中文输出" / "全程中文" is **removed** and does not appear elsewhere in SKILL.md (grep `全程` during dev; the only match today is this line). The `English (default)` option (line 71) is left **semantically unchanged** (English project = everything English; OQ-6=a).

### F4b — step-4.3 stale overlay file list — SKILL.md line 107 (D-obligation 3)

**Before (line 107):**
```markdown
   - The `zh` overlay translates: `00-core.md.tmpl`, `50-fullstack.md` or `50-backend.md`, `docs/workflow.md`, `docs/dev-map.md.tmpl`, `docs/tasks.md.tmpl`, `docs/spec/README.md`, `evals/golden-tasks.md.tmpl`.
```

The **actual** overlay contents (Globbed `skills/harness-init/templates/i18n/zh/**/*`, 17 files):
`00-core.md.tmpl`, `05-insight-index.md.tmpl`, `60-tool-handoff.md`, `75-safety-hook.md.tmpl`, `50-fullstack.md` / `50-backend.md` / `50-generic.md.tmpl`, `AI-GUIDE.md.tmpl`, `CLAUDE.md.tmpl`, `.github/copilot-instructions.md.tmpl`, `.harness/insight-index.md.tmpl`, `docs/workflow.md`, `docs/dev-map.md.tmpl`, `docs/tasks.md.tmpl`, `docs/spec/README.md`, `evals/golden-tasks.md.tmpl`.

**After (line 107):**
```markdown
   - The `zh` overlay translates: the bootstrap stubs (`CLAUDE.md.tmpl`, `.github/copilot-instructions.md.tmpl`, `AI-GUIDE.md.tmpl`), the rule fragments (`00-core.md.tmpl`, `05-insight-index.md.tmpl`, `60-tool-handoff.md`, `75-safety-hook.md.tmpl`, `50-fullstack.md` / `50-backend.md` / `50-generic.md.tmpl`), `.harness/insight-index.md.tmpl`, and the docs/evals (`docs/workflow.md`, `docs/dev-map.md.tmpl`, `docs/tasks.md.tmpl`, `docs/spec/README.md`, `evals/golden-tasks.md.tmpl`).
```

This is an **opportunistic correctness fix** (RA §11 DO-3 recommends fixing it since we edit Q5 nearby). It changes documentation only, no behavioral effect on the copy logic. The Developer should re-Glob immediately before editing to confirm the list hasn't drifted further.

---

## 6. README ×2 edits — F5 / F6 (AC-5)

### F5 — `README.md` §"Project-wide language policy" lines 143-145 (EN prose)

**Before (lines 143-145):**
```markdown
A Chinese team picks `中文` at init — every AI output across the project is in Chinese: chat replies, agent hand-offs, per-task documents, status reports, error messages. Even if you write in another language, AI responds in Chinese. The policy is enforced via a top-level `Output language` section in CLAUDE.md.

English projects work the same way: nothing leaks in another language.
```
**After:**
```markdown
A Chinese team picks `中文` at init — output is **split by consumer**: human-facing output (chat replies, status reports, error messages, delivery summaries, README and human docs) is in **Chinese**; AI-facing work products (the 7-stage per-task documents, PM_LOG, the tasks.md / dev-map / insight-index ledgers, agent / rule / AI-GUIDE / CLAUDE edits, code comments, commit messages) are in **English** — the LLM reads English fine and it stays consistent with the English framework internals. Even if you write in another language, chat replies stay Chinese. The split is defined in the project's `.harness/rules/00-core.md` "输出语言" section.

English projects have a single language — everything is English, no split.
```
**Confirm AC-5:** no surviving "every AI output … in Chinese" sentence (the old line 143 phrase is replaced; grep `every AI output` after edit → 0 hits in README.md).

### F6 — `README.zh-CN.md` §"项目级语言策略" lines 143-145 (ZH prose)

**Before (lines 143-145):**
```markdown
中文团队 init 时选 `中文` — 项目里 AI 全程中文输出：对话回复、agent 间交接、阶段文档、状态报告、错误消息。即使你用其他语言提问，AI 也用中文回答。机制：CLAUDE.md 顶部的 `Output language` 章节。

英文项目同理 — 不会有别的语言混入。
```
**After:**
```markdown
中文团队 init 时选 `中文` — 产出**按消费者分流**：面向人的产出（对话回复、状态报告、错误消息、交付总结、README 及人读文档）用**中文**；面向 agent/LLM 的产出（7-stage 阶段文档、PM_LOG、tasks.md / dev-map / insight-index 台账、agent / rule / AI-GUIDE / CLAUDE 编辑、代码注释、commit message）用**英文** —— LLM 读英文同样顺畅，也与英文框架内部保持一致。即使你用其他语言提问，对话回复仍用中文。分流定义在项目的 `.harness/rules/00-core.md` "输出语言" 章节。

英文项目只有一种语言 —— 全英文，不分流。
```
**Confirm AC-5:** no surviving "AI 全程中文输出" sentence (the old line 143 phrase "项目里 AI 全程中文输出" is replaced; grep `全程中文` after edit → 0 hits in README.zh-CN.md). **This phrase is precisely what the I.6 banned-line in §9 catches** — so this edit and the guard are co-designed.

> **Note for the version fan-out:** F5/F6 also carry the badge + test-init-count edits — see §10.

---

## 7. manual-e2e-test edit — F7 (AC-6)

`docs/manual-e2e-test.md` line 101 is a single bullet inside the B.2 "six questions" list:
```markdown
   - Output language (English / 中文)
```
This line is **language-neutral** (it just names the question), so it does **not** assert the old blunt policy and needs no change for correctness. **However**, AC-6 requires the Q5/language *expectation* to match the new policy. The cleanest minimal edit is to expand that bullet so a manual tester knows what to verify:

**Before (line 101):**
```markdown
   - Output language (English / 中文)
```
**After (line 101):**
```markdown
   - Output language (English / 中文) — picking `中文` yields a **consumer-split** policy (human-facing output Chinese, AI-facing output English) in the generated `.harness/rules/00-core.md` "输出语言" section, not an "everything Chinese" policy.
```

Developer should also grep `manual-e2e-test.md` for any B.3 inspection step that quotes the old policy ("全程"/"everything in Chinese"); the read of lines 85-124 shows B.3 inspects file *existence/stub-ness*, not policy *content*, so no further manual-e2e edit is required. Confirm with a `全程` / `everything in Chinese` grep over the file during dev.

---

## 8. EN-path no-op proof — AC-7

The English-path templates are **byte-unchanged**. For the record, the EN policy is a *single-language* policy (no split), as required by §7.2 / OQ-6=a:

- `skills/harness-init/templates/common/.harness/rules/00-core.md.tmpl` lines 9-22, §"Output language (project-wide)":
  > **Everything this project's AI produces must be in English.** … (8 bullets) … **Do not mix languages.** … To change the project language, edit this "Output language" section …
- `skills/harness-init/templates/common/CLAUDE.md.tmpl` line 3:
  > `Output language: **English**.`

Neither file is in the F-list of edits. **AC-7 verification (for QA):** `git diff` of these two paths after the task must be empty. The Developer must NOT touch them.

---

## 9. I.6 retired-claim banned-line — F8 / F9 (D-obligation 1 / AC-8) — and the CJK cross-shell risk

### 9.1 The CJK cross-shell risk — investigated, RESOLVED

RA flagged this as the #1 risk: insight L27 says Git-for-Windows MSYS GNU grep `grep -F -i` SIGABRTs, and CJK substring matching differs between PS and bash. **I read the actual I.6 implementation in both shells** and the risk is already mitigated by the existing design:

- **bash matcher** (`verify_all.sh` lines 537-591): builds an ERE from `~`-delimited plain-text anchors via `i6_build_regex` (sed-escapes metacharacters), then matches with **`grep -E -n -i -m1`** — that is `grep -E` (ERE), **NOT `grep -F`**. The MSYS `grep -F -i` SIGABRT bug does not apply. The exclude-token test uses **bash `nocasematch` glob `[[ "$line" == *"$xtok"* ]]`** (lines 582-587), explicitly chosen *because* `grep -F -i` aborts on MSYS (the in-code comment at lines 580-581 says exactly this). So no `grep -F` anywhere in I.6.
- **PS matcher** (`verify_all.ps1` lines 502-558): builds the pattern with `[regex]::Escape` and matches via `[regex]::new(..., IgnoreCase)` over .NET strings (UTF-16, fully CJK-safe); exclude uses `String.IndexOf(..., OrdinalIgnoreCase)`. No grep at all.
- **Proof CJK literals already work in BOTH**: the banned list ALREADY contains three CJK entries — `verify_all.sh` lines 533-535 (`harness-sync~生成~CLAUDE.md`, `harness-sync~合成~CLAUDE.md`, `重新生成的~CLAUDE.md`) and their 1:1 PS twins `verify_all.ps1` lines 498-500. These ship today and `verify_all` is green on this repo, so CJK anchors in the ordered-anchor matcher are a **proven, supported pattern** in both shells. `test-verify-i6.{ps1,sh}` asserts the two lists stay in lockstep.

**Chosen approach:** add ONE new CJK banned-entry to each list, using the **same ordered-anchor structure** as the existing `生成`/`合成` CJK entries (NOT a raw single CJK substring, NOT `grep -F`). This is the safest, already-validated path. **No structural/ASCII-anchor fallback needed** — the existing mechanism handles CJK correctly.

### 9.2 The retired phrase and the exact banned-entry

The phrase being retired is the blunt **"AI 全程使用中文输出 / 全程中文输出 / 项目里 AI 全程中文输出"** family (SKILL.md Q5 old line 72, README.zh-CN old line 143, `00-core.md.tmpl` old "本项目所有 AI 产出必须使用中文"). The stable, unique CJK anchor common to the retired claim is **"全程" + "中文"** in order (the "everything-in-Chinese" assertion). The new split text never says "全程" (it says "按消费者分流") — verified against the §3/§5/§6 replacement blocks: none contains "全程".

**bash — add to `i6_banned` (verify_all.sh, after line 535, inside the array):**
```bash
    "全程~中文|v0.24.0 起 zh 策略按消费者分流，不再全程中文（T-013）||"
```

**PowerShell — add to `$banned` (verify_all.ps1, after line 500, inside the array; add a trailing comma to the current last entry line 500):**
```powershell
        @{ anchors = @('全程','中文'); reason = "v0.24.0 起 zh 策略按消费者分流，不再全程中文（T-013）"; exclude = @(); gap = $null }
```

Anchors `全程` then `中文` within the default 40-char gap. This catches the old "AI **全程**使用**中文**输出", "项目里 AI **全程中文**输出", "全程中文" — every retired blunt variant — while the new split text (which has no "全程") is untouched.

### 9.3 The new text does NOT trip the new banned-line — verified

- New `00-core.md.tmpl` block (§3): no "全程". ✅
- New `CLAUDE.md.tmpl` / `copilot` line (§4): no "全程". ✅
- New SKILL.md Q5 (§5a): no "全程". ✅
- New README.zh-CN (§6): no "全程". ✅
- The new policy *does* contain "中文" many times, but the entry requires **both** "全程" AND "中文" in order on one line — "中文" alone never matches.

### 9.4 Exempt-list handling

- `CHANGELOG.md` is auto-exempt (`i6_exempt_files` / `$exempt`) — the `[0.24.0]` entry MAY quote "全程中文" when describing what was retired. ✅ no action.
- `docs/features/` whole subtree is exempt — **this design doc** (which quotes "全程中文" repeatedly) and `01_REQUIREMENT_ANALYSIS.md` are auto-exempt. ✅ no action.
- `verify_all.{ps1,sh}` and `test-verify-i6.{ps1,sh}` are auto-exempt — they hold the banned literal itself. ✅ no action.
- **`test-init.{ps1,sh}` near-miss check:** the new test-init assertion (§10) asserts the **ABSENCE** of "全程" in the generated fixture, so the assert string in test-init is the bare literal `全程`. test-init is **scanned** by I.6 (not exempt). Does the bare `全程` token, alone, trip the `全程~中文` entry? **No** — the entry needs both anchors on one line in order. The test-init assert line will reference `全程` and (separately) the marker strings, but as long as **no single line in test-init contains both "全程" and "中文" in that order**, it is safe. **Design constraint for the Developer:** in the test-init absence-assertion, name the retired token as the bare CJK literal `全程` ONLY (do not write "全程中文" or "全程...中文" on one line). See §10 for the exact assert strings, which satisfy this. If a stray near-miss is unavoidable, add `.harness/scripts/test-init.ps1` + `.sh` to the I.6 exempt-files list — but the §10 design avoids needing that.
- **`README.zh-CN.md` after edit:** the new prose (§6) has no "全程" — not a near-miss, not exempt-needing. ✅

### 9.5 Lockstep requirement

`verify_all.ps1` $banned and `verify_all.sh` i6_banned MUST stay 1:1 (asserted by `test-verify-i6`). The Developer adds the entry to BOTH in the same change; `test-verify-i6.{ps1,sh}` will need the same entry added to their verbatim copies of the banned list (read those two files during dev and mirror the addition — they are the I.6 regression drivers and hold a copy per the comment at verify_all.sh:518). **Carry to Developer:** grep `test-verify-i6` for how it stores the banned-list copy and add the `全程~中文` entry there too, or the lockstep assertion fails.

---

## 10. The first test-init language assertion — F10 / F11 (AC-9 / D-obligation 4) — and the version-count fan-out

### 10.1 Feasibility findings (read of test-init.{ps1,sh})

- **No zh fixture exists today.** `test_type()` (sh:87) / `Test-Type` (ps:83) copy **only** `common` + `$project_type` layers; they never apply the i18n/zh overlay and `substitute()`/`$vars` do not even define `{{LANG}}`. There are **zero** language assertions today (confirmed — grep of test-init.sh for zh/输出语言/Chinese returns only python3 probes and rule-overlay file paths).
- The cleanest, lowest-risk slot is a **dedicated new function** (`test_zh_overlay` / `Test-ZhOverlay`) invoked once after `test_migrate`, mirroring `test_migrate`'s self-contained structure — NOT folded into the per-type loop (folding would change the per-type assertion counts the README badges encode as "3 project types × 75 PS / 63 Bash"). A standalone block adds a clean, countable delta.
- The fixture build reuses the existing `copy_layer` / `Copy-TemplateLayer` helper: copy `common`, then `fullstack` (any type works; fullstack is fine), **then `i18n/zh/common`** as a third overlay layer (mirrors SKILL.md step 4.3). `{{LANG}}` is never needed as a substitution because the policy is fixed text — the existing `substitute()`/`$vars` handle the other placeholders in the zh `00-core.md.tmpl` (`PROJECT_NAME`, `PROJECT_TYPE`, `STACK`, `TODAY`). No `{{LANG}}` placeholder appears in any zh template body, so no new substitution key is required.
- **No-python3 tolerance:** the assertions are pure file-content greps (`grep -q` / `Select-String`), no python3 — they run unconditionally, like the structural assertions. They do NOT go behind the `init_have_python` gate.

### 10.2 The assertion design (present+absent on DIFFERENT strings — avoids the T-007 contradiction trap)

Three assertions per shell, all over the overlaid `$tmp/.harness/rules/00-core.md`:

1. **ZH-list marker PRESENT** — assert a string that lives only in the Chinese-artifacts list: `给用户的交付总结`.
2. **EN-list marker PRESENT** — assert a string that lives only in the English-artifacts list: `commit message`.
3. **Retired phrasing ABSENT** — assert the bare CJK token `全程` does NOT appear.

The present-markers (#1, #2) and the absent-marker (#3) are **different strings** — so there is no T-007-style "assert X present AND X absent" self-contradiction. #1 proves the ZH list rendered, #2 proves the EN list rendered (together: the split is present, AC-2), #3 proves the blunt policy is gone (AC-8 reinforcement at the generated-output layer).

**CJK-I.6 safety of the assert lines (per §9.4):** `全程` appears alone on the absence-assert line; `commit message` and `给用户的交付总结` are on different lines. No single test-init line contains "全程" + "中文" in order ⇒ the new I.6 banned-line is not tripped by test-init ⇒ no exempt entry needed.

### 10.3 Bash — `test_zh_overlay()` (F11), insert before the dispatch block (~sh line 513), call it in the `all`/`both` arms

```bash
test_zh_overlay() {
    echo ""
    echo "=== Testing: i18n/zh overlay — consumer-split output-language policy ==="
    local tmp; tmp=$(mktemp -d -t harness-test-zh-XXXXXX)
    copy_layer "$template_root/common"        "$tmp" "zh-test" "fullstack" "Next.js + NestJS"
    copy_layer "$template_root/fullstack"      "$tmp" "zh-test" "fullstack" "Next.js + NestJS"
    copy_layer "$template_root/i18n/zh/common" "$tmp" "zh-test" "fullstack" "Next.js + NestJS"

    local core="$tmp/.harness/rules/00-core.md"
    assert "[zh] 00-core.md overlaid" "[[ -f '$core' ]]"
    assert "[zh] policy lists a Chinese-artifact (consumer=human) marker" "grep -q '给用户的交付总结' '$core'"
    assert "[zh] policy lists an English-artifact (consumer=agent) marker" "grep -q 'commit message' '$core'"
    assert "[zh] retired blunt 全程 phrasing is absent" "! grep -q '全程' '$core'"

    [[ "$KEEP" == true ]] && echo "Temp dir kept: $tmp" || rm -rf "$tmp"
}
```
Dispatch (mirror `test_migrate`'s arm, sh:526):
```bash
if [[ "$TYPE" == "all" || "$TYPE" == "both" ]]; then
    test_zh_overlay
fi
```

### 10.4 PowerShell — `Test-ZhOverlay` (F10), symmetric twin, insert before dispatch (~ps line 610)

```powershell
function Test-ZhOverlay {
    Write-Host ""
    Write-Host "=== Testing: i18n/zh overlay — consumer-split output-language policy ===" -ForegroundColor Cyan
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) "harness-test-zh-$(Get-Random)"
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
    try {
        $vars = @{ "PROJECT_NAME"="zh-test"; "PROJECT_TYPE"="fullstack"; "STACK"="Next.js + NestJS";
                   "TODAY"=$today; "ENABLE_HOOK"="false";
                   "SYNC_COMMAND"="pwsh -NoProfile -File .harness/scripts/harness-sync.ps1";
                   "GUARD_COMMAND"="pwsh -NoProfile -File .harness/scripts/guard-rm.ps1" }
        Copy-TemplateLayer -Source (Join-Path $templateRoot "common")        -Target $tmp -Vars $vars
        Copy-TemplateLayer -Source (Join-Path $templateRoot "fullstack")      -Target $tmp -Vars $vars
        Copy-TemplateLayer -Source (Join-Path $templateRoot "i18n/zh/common") -Target $tmp -Vars $vars

        $core = Join-Path $tmp ".harness/rules/00-core.md"
        Assert "[zh] 00-core.md overlaid" { Test-Path $core }
        Assert "[zh] policy lists a Chinese-artifact (consumer=human) marker" { (Get-Content $core -Raw) -match '给用户的交付总结' }
        Assert "[zh] policy lists an English-artifact (consumer=agent) marker" { (Get-Content $core -Raw) -match 'commit message' }
        Assert "[zh] retired blunt 全程 phrasing is absent" { -not ((Get-Content $core -Raw) -match '全程') }
    } finally {
        if (-not $KeepTemp) { Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue }
        else { Write-Host "Temp dir kept: $tmp" -ForegroundColor Yellow }
    }
}
```
Dispatch (mirror Test-Migrate arm, ps:622):
```powershell
if ($Type -in @("all", "both")) {
    Test-ZhOverlay
}
```

> **Encoding note for the Developer (carry):** both test-init scripts must be saved/edited as **UTF-8** so the CJK assert literals (`给用户的交付总结`, `全程`) survive. The scripts already contain CJK in other contexts? — confirm the existing file encoding before editing (read with the editor's raw bytes); if the PS script is not already UTF-8-with-BOM-safe for CJK, the `-match` on a CJK literal could mis-fire. Existing CJK in verify_all.ps1 (`生成`/`合成`) proves the repo's PS tooling handles CJK literals, so this is low-risk, but the Developer should verify the saved encoding after edit and re-run both shells (L10: Edit may silently no-op).

### 10.5 Count fan-out (informational badge only — NOT a verify_all check)

The zh block adds **4 assertions per shell** (1 existence + 3 policy). New totals: PS **227 → 231**; Bash **191 → 195** (the 4 are pure greps, no python3, so they run on both). These counts appear ONLY in:
- `README.md` line 5 badge `test--init-227%2F227` → `test--init-231%2F231`.
- `README.md` line 162 prose `227 assertions on PowerShell; 191 on Bash` → `231 … 195`, and the parenthetical `3 project types × 75 PS / 63 Bash, plus 2 shell-agnostic BUG-2` should gain `, plus 4 shell-agnostic zh-overlay policy assertions`.
- `README.zh-CN.md` line 162 prose `PowerShell 227 断言；不带 python3 的 Bash 191` → `231 … 195` with the same parenthetical addition in Chinese.

These are **not** gated by G.3/G.4 (G.3 = version stamps only; G.4 = verify_all check count + release version, derived from `$report.Count`, which is unaffected because no Step is added). The test-init counts are informational; the Developer updates them for accuracy. **The Developer must run both `test-init.ps1` and `test-init.sh` and read off the actual PASS totals** to confirm 231/195 before stamping the badge (the exact pre-existing totals should be re-confirmed empirically, not trusted from the badge, in case an intervening change shifted them).

---

## 11. Version fan-out 0.23.0 → 0.24.0 — F12 / F13 / F14 (D-obligation 6 / AC-10)

A shipped-template content change is version-worthy (insight L33). Current version 0.23.0 (post-T-012). Bump to **0.24.0** (minor: behavior change to generated projects, backward-compatible — already-generated projects are untouched).

G.3 enforces version identity across **exactly four** sites (read of verify_all.ps1:333-355):

| Site | File | Change |
|---|---|---|
| plugin manifest | `.claude-plugin/plugin.json` line 4 | `"version": "0.23.0"` → `"0.24.0"` |
| marketplace | `.claude-plugin/marketplace.json` line 17 | `"version": "0.23.0"` → `"0.24.0"` |
| README badge | `README.md` line 5 | `version-0.23.0-blue` → `version-0.24.0-blue` |
| README.zh badge | `README.zh-CN.md` line 5 | `version-0.23.0-blue` → `version-0.24.0-blue` |

**CHANGELOG (F14):** there is an existing `[Unreleased]` section (CHANGELOG.md line 8) holding the ambient-stream work. Add the T-013 entry. **Decision:** add a new `## [0.24.0] - 2026-06-08` section **above** the existing `## [0.23.0]` line 26, and roll the `[Unreleased]` ambient-stream content into it OR keep `[Unreleased]` and add a sibling `[0.24.0]`. **Recommended:** since the version IS being cut to 0.24.0 and the `[Unreleased]` ambient-stream change explicitly says "no version bump", keep `[Unreleased]` as-is and insert a new `## [0.24.0] - 2026-06-08` block between `[Unreleased]` and `[0.23.0]`, describing only the T-013 lang-policy split. (If the PM wants the ambient-stream work folded into 0.24.0, that is a PM call at delivery; this design treats them as independent and only owns the T-013 entry.) **Carry to Developer:** confirm with PM whether `[Unreleased]` rolls into 0.24.0; default = keep separate.

CHANGELOG `[0.24.0]` entry must mention: the consumer-split zh policy, the files touched, and (for G.2 — "CHANGELOG mentions all 13 skills") **does not need a skill mention** because no skill is added.

**Count invariants (AC-10):** skill count stays **13** (C.1 / G.1 / G.2 — no new skill); verify_all check count stays **32** (G.4 — the test-init zh block adds NO verify_all Step; the I.6 edit adds a banned *entry* inside the existing I.6 Step, not a new Step). G.4's `$count` is unchanged ⇒ all G.4 doc-count claims (AI-GUIDE, dev-map, 40-locations, README "(32 checks)", manual-e2e, baseline.json) stay correct and are **not touched**.

**Same-file uniqueness (L36):** the only same-file repeated claim touched is the version badge string `version-0.X.Y-blue`, which is unique per README. The G.4 `$count` literals are untouched. No L36 collision introduced.

---

## 12. Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| Retired-claim guard for a Chinese phrase | I.6 gap-tolerant ordered-anchor matcher with CJK entries | `.harness/scripts/verify_all.{ps1,sh}` (sh:522-592, ps:470-565) | **Reuse as-is** — add one CJK `全程~中文` entry in the existing format; mechanism already CJK-safe (proven by `生成`/`合成` entries) |
| I.6 lockstep regression | banned-list verbatim copy + fixtures | `.harness/scripts/test-verify-i6.{ps1,sh}` | **Extend** — mirror the new entry into the copies |
| test-init fixture build (copy + substitute) | `copy_layer` / `Copy-TemplateLayer` helpers | `.harness/scripts/test-init.{sh,ps1}` (sh:67, ps:47) | **Reuse** — call with a third `i18n/zh/common` layer |
| Standalone test-init block pattern | `test_migrate` / `Test-Migrate` self-contained function + dispatch arm | `.harness/scripts/test-init.{sh,ps1}` (sh:442, ps:493) | **Reuse the pattern** — clone shape for `test_zh_overlay` |
| no-python3 tolerance | pure-grep assertions outside the `*_have_python` gate | `.harness/scripts/test-init.sh` (the structural `assert` lines) | **Reuse** — policy assertions are pure greps |
| version identity gate | G.3 (4-site) + G.4 (count) | `.harness/scripts/verify_all.ps1` (333, 637) | **Reuse** — bump the 4 G.3 sites; G.4 count untouched |
| EN single-language policy reference | `templates/common/.harness/rules/00-core.md.tmpl` §"Output language" | (same) | **Reuse as the byte-unchanged baseline** (AC-7) — do not edit |
| zh overlay file inventory | the 17-file overlay | `skills/harness-init/templates/i18n/zh/**` | **Reuse the Glob** to fix the stale SKILL.md list (D-3) |
| (new) split-policy prose | (none — this is the deliverable content) | — | New text justified: the requirement IS a content rewrite |

---

## 13. Risk analysis

| # | Risk | Likelihood | Mitigation |
|---|---|---|---|
| R1 | **CJK in I.6 cross-shell** — a Chinese banned-line breaks in MSYS grep or mis-matches in PS (insight L27). | Low (was High before investigation) | **Resolved in §9.1**: I.6 uses `grep -E` (not `grep -F`) + bash `nocasematch` and PS `[regex]::new(IgnoreCase)`; three CJK entries already ship green. New entry reuses that exact structure. Dev re-runs `verify_all` both shells + `test-verify-i6` both shells as the gate. |
| R2 | **test-init regression** — the rewritten zh `00-core.md.tmpl` introduces a stray `{{...}}` and the recursive placeholder scan (test-init.sh:187) fails for the whole zh fixture. | Low | §3 replacement block verified to contain zero `{{...}}`; the new `test_zh_overlay` itself runs the structural fixture through `copy_layer` which substitutes the real placeholders. Dev runs both test-init shells (the mandatory gate). |
| R3 | **CJK encoding in test-init / I.6 literals** — a non-UTF-8 save mangles `全程` / `给用户的交付总结` so the assert mis-fires or the banned-line never matches. | Medium | §10.4 carry-note: save both test-init scripts UTF-8; existing CJK in verify_all.ps1 proves the toolchain handles it. Dev re-Reads after edit (L10) and runs both shells; a mangled literal makes the zh-overlay assert FAIL loudly (not silently pass). |
| R4 | **New banned-line is too broad** — `全程~中文` matches legitimate prose somewhere in the tracked tree. | Low | "全程" + "中文" in order within 40 chars is the retired blunt claim's signature; grep the whole tree for `全程` during dev — the only non-exempt hit after the rewrite should be zero (CHANGELOG/docs/features are exempt). If a legit hit exists, narrow the anchors or exempt that file. |
| R5 | **L36 / G.4 count drift** — Dev accidentally edits a `(32 checks)` claim or the test-init zh block is mistaken for a new verify_all Step. | Low | §11 is explicit: no new Step, count stays 32; G.4 derives count from `$report.Count` automatically; Dev touches none of the count-claim files. |
| R6 | **Symmetry drift** — PS and Bash test-init / I.6 edits diverge. | Medium | Every F-pair (F8/F9, F10/F11) is specified as a 1:1 twin with verbatim blocks; `test-verify-i6` asserts I.6 lockstep; Dev runs both shells. |
| R7 | **README test-init count guessed wrong** — badge stamped 231/195 but actual differs. | Low | §10.5: Dev reads the actual PASS totals from running both shells before stamping; counts are informational (not G-gated) so a wrong number is a cosmetic miss, caught by re-run. |

---

## 14. Migration / rollout plan

- **Backward compatibility:** already-generated user projects are **not** migrated (§6.4 out-of-scope; `/harness-upgrade` content-refresh is a separate task surface). This change affects only *new* `{{LANG}}=zh` inits and the advertised docs.
- **Feature flags:** none. The split is fixed policy text, not a toggle (DO-2, no new placeholder).
- **EN path:** untouched (AC-7) — zero migration risk for English projects.
- **Rollback:** pure content/doc/script revert — `git revert` of the single commit restores 0.23.0 behavior; no data, no schema, no runtime state.
- **Sequence for the Developer (suggested order):**
  1. F1 (00-core.md.tmpl rewrite) — the substance.
  2. F2/F3 (stubs), F4 (SKILL Q5 + step-4.3), F5/F6 (READMEs prose), F7 (manual-e2e) — the advertised summaries.
  3. F8/F9 + test-verify-i6 copies (I.6 banned-line) — re-run `test-verify-i6` both shells.
  4. F10/F11 (test-init zh block) — re-run `test-init` both shells; read actual counts.
  5. F12/F13 (version) + F5/F6 badges + F5/F6 test-init-count prose + F14 (CHANGELOG).
  6. Final: `verify_all` both shells must PASS (red line); re-Read every edited file (L10).

---

## 15. Out-of-scope clarifications (design boundaries)

- **(B) template re-translation** (moving AI-facing zh-overlay files like `AI-GUIDE.md.tmpl`, rule fragments, `workflow.md` back to English) — **deferred** (OQ-3=a; logged as T-014 candidate in PM_LOG). This design rewrites only the OUTPUT-POLICY *content*; the surrounding zh template prose stays Chinese.
- **The dogfood repo's own policy** (`CLAUDE.md`, `.harness/rules/00-core.md` at repo root) — out of scope, stays English (DO-6 red line).
- **EN-path templates** — byte-unchanged (AC-7).
- **New language overlays** (ja/fr) — out of scope.
- **Retroactive migration** of already-generated zh projects — out of scope.
- **No new `{{...}}` placeholder** — the split is fixed text (DO-2); D.2 whitelists untouched.
- **`[Unreleased]` ambient-stream content** — independent; this design owns only the T-013 CHANGELOG entry (PM decides at delivery whether to fold).

---

## 16. AC traceability

| AC | Requirement | Satisfied by |
|---|---|---|
| AC-1 | zh `CLAUDE.md` top line states the split + points at 00-core | F2 (§4) |
| AC-2 | zh `00-core.md` enumerates two explicit ZH/EN lists matching §4 | F1 (§3) |
| AC-3 | zh `copilot-instructions.md` top line matches CLAUDE.md | F3 (§4, identical string to F2) |
| AC-4 | SKILL Q5 describes the split; no "全程使用中文" survives | F4a (§5) |
| AC-5 | README ×2 describe the split; no "every AI output in Chinese / AI 全程中文输出" survives | F5 + F6 (§6) |
| AC-6 | manual-e2e Q5/language expectation updated | F7 (§7) |
| AC-7 | en `00-core.md`/`CLAUDE.md` byte-unchanged | §8 (no edit; QA diffs empty) |
| AC-8 | verify_all passes; I.6 banned-line for retired phrasing added | F8 + F9 (§9) |
| AC-9 | test-init passes both shells; first symmetric language assertion present | F10 + F11 (§10) |
| AC-10 | CHANGELOG entry + version bump; G.3/G.4 green; counts 13/32 | F12 + F13 + F14 (§11) |

## 17. D-obligation discharge

| D | Obligation | Discharge |
|---|---|---|
| D1 | I.6 retired-claim banned-line for "全程中文/every AI output in Chinese" | §9 — `全程~中文` CJK entry in both shells + test-verify-i6 copies; CJK cross-shell risk investigated & resolved |
| D2 | No new `{{...}}` placeholder | §3/§4/§15 — split is fixed text; D.2 whitelists untouched |
| D3 | Fix stale SKILL step-4.3 overlay file list | F4b (§5) — corrected to the actual 17-file overlay (Globbed) |
| D4 | First-ever test-init language assertion, symmetric, no-python3-tolerant | F10 + F11 (§10) — 4 pure-grep assertions per shell on a new zh fixture |
| D5 | Overlay ↔ common symmetry | Not triggered (OQ-3=a; no overlay structural change) — N/A |
| D6 | Version/claim consistency | §11 — 0.23.0→0.24.0 across 4 G.3 sites + CHANGELOG; counts 13/32 unchanged |

---

## 18. Partition assignment

Single-developer mode (no `.harness/agents/dev-*.md` — confirmed in PM_LOG). All 14 files (F1-F14) go to the single `developer`. Dispatch order = the §14 sequence. No inter-partition coordination. (Table included per agent-spec note that single-partition tasks still list the assignment.)

| File group | Partition | Order |
|---|---|---|
| F1-F7 (templates + skill + docs prose) | developer | 1 |
| F8/F9 + test-verify-i6 (I.6 guard) | developer | 2 |
| F10/F11 (test-init zh block) | developer | 3 |
| F12-F14 (version + CHANGELOG + badges) | developer | 4 |

---

## 19. Verdict

**READY.**

Rationale: the requirement is `READY` with all 6 OQs resolved to defaults; every edit is grounded in actual file:line with verbatim before/after; the #1 risk (CJK in I.6 cross-shell) was investigated against the real matcher implementation and **resolved** by reusing the existing, already-green CJK-anchor mechanism (`grep -E`, not `grep -F`); no new placeholder, no new verify_all Step, no skill/check-count change (stays 13/32); the EN path is provably byte-unchanged (AC-7); and the first symmetric test-init language assertion is feasible via a new self-contained zh-overlay fixture reusing existing helpers. A junior developer can implement this from §3-§11 verbatim without further design decisions.

**Carries to Developer (do not lose):**
1. Mirror the I.6 `全程~中文` entry into `test-verify-i6.{ps1,sh}` banned-list copies (§9.5) or the lockstep assertion fails.
2. Save test-init scripts UTF-8; re-Read after edit (L10); run BOTH shells for test-init AND test-verify-i6 AND verify_all.
3. Read the actual test-init PASS totals before stamping the 231/195 badge (§10.5).
4. Confirm with PM whether `[Unreleased]` ambient-stream folds into 0.24.0 (§11) — default keep separate.
5. Re-Glob the zh overlay before the SKILL step-4.3 list edit (§5) in case it drifted.

**For the Gate Reviewer (residual to scrutinize):** R3 (CJK encoding round-trip in the two test-init scripts) and R6 (PS/Bash symmetry of the two new function pairs) are the only non-trivial residuals; both are verifiable by running all four scripts in both shells. Everything else is mechanical text substitution against quoted before/after blocks.

---

## Amendment 1 (Gate F-1 + advisories)

> Author: Solution Architect. Surgical amendment in response to `03_GATE_REVIEW.md`. Scope: F-1 (BLOCKING) fix + fold-in of F-2/F-3/F-4 advisories into one coherent design. No part of §1-§19 above is redesigned; this section **adds** edits and **corrects** the §9.2/§9.4 sweep narrative.

### A1.1 — The blocking gap (Gate F-1), confirmed

The §9.2/§9.4 retired-phrase sweep and the F-list (§2) missed one **live, git-tracked, NON-exempt** scanned file: **`docs/project-overview.html:314`** contains `中文项目全程中文` — "全程" immediately followed by "中文" (gap 0). When the Developer adds the `全程~中文` I.6 banned-line (§9.2), **I.6 FAILs on this file → verify_all FAILs → AC-8 + the CLAUDE.md "verify_all must PASS" red line are violated.** The build cannot go green as §9 currently stands.

**The file is a frozen, dated archived snapshot** — `docs/project-overview.html:765` reads `生成于 2026-05-19 · Harness Kit v0.17.0 · 本页面归档于 docs/project-overview.html`; AI-GUIDE.md:65 describes it as the "HTML, v0.17.0 snapshot". This is the **same class** as the two snapshot HTMLs already in the I.6 exempt-files list (`architecture.html`, `docs/walkthrough.html`), and Insight L18 explicitly contemplates "labeled-snapshot HTMLs" as an I.6 exemption class.

**Decision: exempt the file (Gate's option ii) — do NOT rewrite line 314.** Rewriting a frozen, dated v0.17.0 snapshot to change its historical "全程中文" wording would falsify an archived artifact (the snapshot honestly records what the v0.17.0 policy *was*). Exemption is the consistent, honest fix — exactly the rationale that already exempts `architecture.html` / `docs/walkthrough.html`.

### A1.2 — F-15: add `docs/project-overview.html` to the I.6 exempt-files list — FOUR sites, lockstep

The I.6 exempt-files array is **mirrored in four places**, and `test-verify-i6` asserts **element-wise (ordered) lockstep** across all four via its Assertion 3c (`test-verify-i6.sh:517-520`, `test-verify-i6.ps1:581-585`). Editing only the two live `verify_all.{ps1,sh}` arrays would FAIL the 3c lockstep assertion → `test-verify-i6` FAILs. **All four arrays must receive the identical new entry at the identical ordered position.**

**Canonical insertion position (all four):** immediately **after** `docs/walkthrough.html`, i.e. appended to the snapshot-HTML cluster (CHANGELOG.md, architecture.html, docs/walkthrough.html, **→ docs/project-overview.html ←**, then the four script paths). Element-wise compare is order-sensitive, so the position must be byte-identical across all four files.

The four exact edits (exact file:line + exact string to insert):

| # | File | Anchor line (current) | Insert AFTER it |
|---|---|---|---|
| F-15a | `.harness/scripts/verify_all.sh` | `:550` `    "docs/walkthrough.html"` | `    "docs/project-overview.html"` |
| F-15b | `.harness/scripts/verify_all.ps1` | `:519` `        "docs/walkthrough.html",` | `        "docs/project-overview.html",` |
| F-15c | `.harness/scripts/test-verify-i6.sh` | `:89` `    "docs/walkthrough.html"` | `    "docs/project-overview.html"` |
| F-15d | `.harness/scripts/test-verify-i6.ps1` | `:74` `        "docs/walkthrough.html",` | `        "docs/project-overview.html",` |

**Punctuation note for the Developer:** the bash arrays (`.sh`) are **newline-separated, no commas** — add the entry with no trailing comma and matching 4-space indent (`    "docs/project-overview.html"`). The PS arrays (`.ps1`) are **comma-separated** — `docs/walkthrough.html` is NOT the last element (the four script paths follow it), so it already ends in a comma; just insert the new line `        "docs/project-overview.html",` (8-space indent, trailing comma) below it. No trailing-comma toggling is needed on any neighbor in any of the four files (the new entry is interior, never last).

**No new exempt-DIR** is added — `docs/project-overview.html` is a single file, exempted at file granularity exactly like its two snapshot-HTML siblings. The `i6_exempt_dirs` arrays (`docs/features/`, `参考/`) are untouched, so the exempt-DIR 3c lockstep assertions are unaffected.

This **supersedes §9.4's** claim that no exempt-files edit is needed. §9.4 correctly handled CHANGELOG/docs-features/scripts/test-init, but missed this archived HTML; F-15 closes that gap.

### A1.3 — Re-grep confirmation: the sweep is now exhaustive (no second missed site)

I re-ran `grep 全程` across the entire tree. Every live `全程` occurrence, classified against the `全程~中文` banned-line (both anchors, in order, within 40 chars, on one line):

| File:line | Has 中文 within 40 chars after 全程? | Exempt? | Verdict |
|---|---|---|---|
| `docs/project-overview.html:314` (`中文项目全程中文`) | **Yes** (gap 0) | NO (until F-15) | **F-1 hit → fixed by F-15 exemption** |
| `docs/walkthrough.html:284` (`…贯穿全程。`) | No (sentence ends `全程。`) | Yes (already exempt) | Non-hit (both reasons) |
| `README.zh-CN.md:143` (`AI 全程中文输出`) | Yes | No | **Rewritten by F6 → "全程" removed → post-edit non-hit** |
| `skills/harness-init/SKILL.md:72` (`全程使用中文输出`) | Yes | No | **Rewritten by F4a → "全程" removed → post-edit non-hit** |
| `docs/features/lang-policy-split/*` (PM_LOG, 01, 02, 03) | various | Yes (`docs/features/` dir-exempt) | Non-hit (dir-exempt) |

`docs/system-overview.html` is **UNtracked** (the `??` entry in git status) → not in `git ls-files` → not scanned by I.6 → not a concern. There is **no second missed live non-exempt site**: after F4a + F6 remove "全程" from SKILL.md and README.zh-CN.md, and F-15 exempts project-overview.html, the only remaining live `全程`-bearing files are either dir-exempt (`docs/features/`) or file-exempt (`docs/walkthrough.html`, now `docs/project-overview.html`). The sweep is exhaustive.

### A1.4 — Version/count impact: UNCHANGED

F-15 adds an **exempt-list entry**, not a verify_all Step. Therefore:
- verify_all check count stays **32** (G.4 `$report.Count` unaffected — no Step added/removed).
- skill count stays **13** (no skill touched).
- version fan-out stays **0.23.0 → 0.24.0** across the same four G.3 sites (§11).
- `test-verify-i6` assertion count rises by 0 *new* assertions — the exempt-file/dir lockstep assertions (3c) are pre-existing; F-15 keeps them GREEN by mirroring the entry, it does not add an assertion. (The I.6 banned-line addition from §9 likewise rides inside existing assertions, not new ones.)

No badge or count claim beyond the §10.5 test-init totals and §11 version changes is affected by F-15.

### A1.5 — CHANGELOG structure decision (Gate F-4) — SUPERSEDES §11's "keep separate" default

The live `CHANGELOG.md` has `## [Unreleased]` (`:8`) holding the **already-shipped** ambient-stream (T-011) work (commits f500942 / 01502c0, self-described "no version bump"); `## [0.23.0]` (`:26`) is T-012.

**Decision (adopting the Gate F-4 recommendation, which overrides the §11 "default = keep separate" line):** **rename the existing `## [Unreleased]` → `## [0.24.0] - 2026-06-08`** and **append the T-013 lang-policy-split entry to that same section.** Leave **NO** orphan `## [Unreleased]`, and do **NOT** create a sibling `## [0.24.0]` section.

Rationale: cutting 0.24.0 *releases* the ambient-stream work that has been sitting under `[Unreleased]`; leaving it perpetually "Unreleased" beneath a newer dated section would be dishonest per Keep-a-Changelog. Folding it into the dated `[0.24.0]` is the honest record. Both G.2 (needs only the 13 skill mentions — no new skill) and G.4 (reads version from manifests + count from `$report.Count`, not CHANGELOG layout) stay green under this structure.

**Explicit instruction to the Developer:** the F14 edit is now: open `CHANGELOG.md`, change the line `## [Unreleased]` to `## [0.24.0] - 2026-06-08`, keep the existing ambient-stream bullets under it, and **append** the T-013 bullets (consumer-split zh policy; files touched; I.6 `全程~中文` guard added; first test-init zh-overlay language assertion; `docs/project-overview.html` added to I.6 exempt list). Do not add a separate `[0.24.0]` heading; do not leave an empty `[Unreleased]`.

### A1.6 — Re-stated advisories (so the Developer has them inline, not lost)

These were already in the §13/§19 carries; re-stated here per the Gate so the amendment is self-contained:

- **F-2 (test-init counts — empirical):** the §10.5 PS 227→231 / Bash 191→195 figures are **arithmetic estimates**, and the counts are informational (not G.3/G.4-gated). The Developer must **run both `test-init.ps1` and `test-init.sh` and read the actual PASS totals** before stamping the `test--init-NNN%2F...` badge and the README prose — do not trust the arithmetic or the pre-existing badge in case an intervening change shifted the baseline.
- **F-3 (mirror the BANNED-line into the test-verify-i6 copies):** `test-verify-i6.{ps1,sh}` hold a **verbatim copy of the 13-entry banned list** (`test-verify-i6.sh:65` / `.ps1:51`) gated by `I6ExpectedEntryCount` (`test-verify-i6.sh:95` / `.ps1:80`), and 3c asserts the live `i6_banned`/`$banned` match the driver copy **verbatim per-entry**. Adding `全程~中文` (§9.2) to the two live arrays makes the count 13→14; the Developer must therefore: (a) add the `全程~中文` entry to BOTH test-verify-i6 banned-list copies, AND (b) **bump `I6ExpectedEntryCount` from 13 to 14** at its single-source-of-truth line in BOTH drivers (`test-verify-i6.sh:95`-region / `test-verify-i6.ps1:80`-region — read the exact assignment line during dev). Without (b), the count-equality 3a/3b assertions FAIL even with the entry mirrored.

> **Combined I.6 lockstep checklist for the Developer (banned-list AND exempt-list now both move):**
> 1. `全程~中文` banned-entry → `verify_all.sh` `i6_banned` + `verify_all.ps1` `$banned` + `test-verify-i6.sh` `i6_banned` copy + `test-verify-i6.ps1` banned copy (4 files).
> 2. `I6ExpectedEntryCount` 13 → 14 in `test-verify-i6.{sh,ps1}` (2 files).
> 3. `docs/project-overview.html` exempt-entry → `verify_all.sh` `i6_exempt_files` + `verify_all.ps1` `$exempt` + `test-verify-i6.sh` `i6_exempt_files` + `test-verify-i6.ps1` `$i6ExemptFiles` (4 files, identical ordered position after `docs/walkthrough.html`).
> 4. Save all UTF-8 (CJK in the banned entry); re-Read after edit (L10); run `test-verify-i6` AND `verify_all` in **both** shells — both must PASS.

### A1.7 — Amended verdict

**READY** (unchanged verdict, design now complete).

The single BLOCKING gap (F-1) is closed by F-15 (exempt `docs/project-overview.html` at all four lockstep sites, exact file:line + string above); the re-grep confirms no second missed site; the version/count invariants (13 skills / 32 checks / 0.24.0) are unchanged; F-2/F-3/F-4 advisories are folded in (empirical test-init totals; banned-line + `I6ExpectedEntryCount` mirrored into the test-verify-i6 copies; CHANGELOG `[Unreleased]`→`[0.24.0]` fold, no orphan). A junior developer can implement §3-§11 plus this Amendment 1 verbatim without further design decisions.
