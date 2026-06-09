# 02 — Solution Design · T-016 / i18n-special-drift-guard

> Stage 2 of the Harness pipeline. Mode: **full** (7-stage). Author: Solution Architect.
> Upstream: `01_REQUIREMENT_ANALYSIS.md` (verdict **READY**) + `PM_LOG.md` OQ-1 resolution.
> **Chosen mechanism: ELIMINATE** (not GUARD) — per the user's explicit steer recorded in
> `PM_LOG.md:54-68`: *"不断加守卫会使项目越来越臃肿;优秀的设计才是大家都喜爱的"*. The duplication is
> removed at the root rather than guarded, so the `verify_all` check count stays **32 (no bloat)**.
> All file:line citations are against the harness-kit repo at this commit (2026-06-09).

---

## 0. Feasibility verdict (the make-or-break — stated FIRST)

**FEASIBLE. ELIMINATE via init-composition is clean and low-risk. Not BLOCKED.**

The three load-bearing facts, each code-grounded:

1. **Init is AI-orchestrated, and already runs scripts mid-flow.** `skills/harness-init/SKILL.md` step 4
   ("Copy template files") is executed by the orchestrator model copying/rendering templates; step 5b
   already runs an inline transform driven by env-var mock scripts (`HARNESS_AI_NATIVE_MOCK`,
   `SKILL.md:193-204`), and step 6 runs `harness-sync` as a real shell invocation (`SKILL.md:288-296`).
   So injecting a post-copy script step for the zh path is the **same shape** as existing init steps —
   not a new capability.

2. **The injection helper is bootstrapped INTO the project before it is needed.** `language-policy.{ps1,sh}`
   ships under `templates/common/.harness/scripts/` (confirmed: `Glob skills/harness-init/templates/common/.harness/scripts/language-policy.{sh,ps1}`), so step 4.1 (copy `common/` → target) lays it
   into the new project's `.harness/scripts/`. After that copy it is available to run against the project
   root — exactly as `/harness-language` self-bootstraps it (`harness-language/SKILL.md:130-133`).

3. **`/harness-language` ALREADY performs this exact injection, and is regression-tested green.** The helper's
   `--lang zh` path rewrites `00-core.md`'s policy section + `CLAUDE.md`/copilot's policy line from canonical
   zh text (`language-policy.sh:207-300`, `.ps1:221-302`), and `test-language.{sh,ps1}` proves en→zh→en
   round-trips are byte-identical (test #9, `test-language.sh:229-244`; 39/39 both shells per
   `baseline.json:19-20`). "init zh = init en + inject the zh policy" reuses a transform that is already
   shipped, tested, and idempotent. No new mechanism is invented.

The only genuinely new artifact is **one single-source file** holding the canonical zh policy text (so the
helper has somewhere to read it from once the 3 SPECIAL files are deleted), plus the helper's zh-source
re-point. Both are small, localized, and fully testable. **No new runtime dependency** (NFR-2 holds — helper
stays bash-builtin + awk on bash, .NET string ops on PS). **The en path is byte-untouched** (the helper's en
branch still reads `common/` inline; en init lays `common/` directly — no composition). The no-network /
idempotence guarantees are preserved (the helper is already idempotent; the injection runs locally on files
just laid down). **test-init can model the composition** (it already invokes scripts in-fixture — `test-init.sh:100`
runs `harness-sync.sh`; the migrate test runs `migrate-scripts-layout.sh` at `:482`). Therefore the fallback
GUARD is **not** needed.

---

## 1. Architecture summary

Today the i18n/zh overlay carries **three SPECIAL `.tmpl` files** whose English framework BODY is a verbatim
copy of `templates/common/` (the duplication T-015 §10 R-2 flagged), differing only in a per-language policy
region. This design **removes that duplication at the source**: the canonical Chinese policy text is relocated
into ONE new single-source file (`templates/i18n/zh/_policy/output-language.zh.md.tmpl`); `/harness-language`'s
zh branch is re-pointed to read its policy section + line from that single source; `/harness-init` (and
`/harness-adopt`) stop overlaying the three SPECIAL files and instead **COMPOSE** a zh project — lay the English
`common/` 00-core/CLAUDE/copilot, then INJECT the zh policy via the existing `language-policy` helper; and the
**3 SPECIAL files are deleted**. The i18n/zh overlay shrinks to the 2 genuinely human-facing files. The English
duplication is structurally gone — nothing left to drift — so **no new `verify_all` check is added** (count
stays **32**). This is a mechanism/template change, version-worthy: **0.26.0 → 0.27.0**.

---

## 2. Affected modules (file paths, existing repo)

| # | File | Change | Why |
|---|---|---|---|
| M-1 | `skills/harness-init/templates/i18n/zh/_policy/output-language.zh.md.tmpl` | **NEW** | The single-source canonical zh policy text (section + line) the helper reads. |
| M-2 | `skills/harness-init/templates/common/.harness/scripts/language-policy.sh` | **edit** | Re-point the zh-source resolution (`tmpl_common`/`tmpl_core`/`tmpl_claude` for `--lang zh`) to M-1. |
| M-3 | `skills/harness-init/templates/common/.harness/scripts/language-policy.ps1` | **edit** | PS mirror of M-2 (`$tmplCommon`/`$tmplCore`/`$tmplClaude` for `-Lang zh`). |
| M-4 | `.harness/scripts/language-policy.sh` | **edit (re-sync)** | Dogfood mirror of M-2 (sync-self; edit the template then re-sync, or edit both — see §9 risk R-4). |
| M-5 | `.harness/scripts/language-policy.ps1` | **edit (re-sync)** | Dogfood mirror of M-3. |
| M-6 | `skills/harness-init/templates/i18n/zh/common/.harness/rules/00-core.md.tmpl` | **DELETE** (F-2) | English-body duplication eliminated; zh project composes 00-core from `common/` + injection. |
| M-7 | `skills/harness-init/templates/i18n/zh/common/CLAUDE.md.tmpl` | **DELETE** (F-7) | English-body duplication eliminated; zh project composes CLAUDE.md from `common/` + injection. |
| M-8 | `skills/harness-init/templates/i18n/zh/common/.github/copilot-instructions.md.tmpl` | **DELETE** (F-8) | English-body duplication eliminated; zh project composes copilot from `common/` + injection. |
| M-9 | `skills/harness-init/SKILL.md` | **edit** | Step 4.3 zh-overlay list (drop the 3 SPECIAL files) + a NEW step 4.4 "for zh, inject the policy". |
| M-10 | `skills/harness-adopt/SKILL.md` | **edit** | Mirror the zh composition for the adopt path (`SKILL.md:275-284`). |
| M-11 | `.harness/scripts/test-init.sh` | **edit** | `test_zh_overlay` (`:514-574`): COMPOSE the zh fixture (lay `common`+`fullstack`, run the helper) + NEW positive byte-match assertion. |
| M-12 | `.harness/scripts/test-init.ps1` | **edit** | `Test-ZhOverlay` (`:610-677`): PS mirror of M-11. |
| M-13 | `.claude-plugin/plugin.json` | **edit** | `version` 0.26.0 → 0.27.0 (`:4`). |
| M-14 | `.claude-plugin/marketplace.json` | **edit** | `version` 0.26.0 → 0.27.0 (`:17`). |
| M-15 | `README.md` | **edit** | version badge `version-0.26.0` → `0.27.0` (`:5`). |
| M-16 | `README.zh-CN.md` | **edit** | version badge `version-0.26.0` → `0.27.0` (`:5`). |
| M-17 | `CHANGELOG.md` | **edit** | new `## [0.27.0]` heading + entry. |
| M-18 | `.harness/scripts/baseline.json` | **edit** | reconcile `test_init_*` counts from a CAPTURED two-shell run (AC-10 / L27). |

> NOTE: `verify_all.{ps1,sh}` is **NOT** in this list — that is the whole point. No new check; count stays 32.

---

## 3. The single-source: location + shape + verbatim content (M-1)

### 3.1 Location & shape — decision

**Chosen location:** `skills/harness-init/templates/i18n/zh/_policy/output-language.zh.md.tmpl`

**Chosen shape:** ONE markdown file that contains BOTH the canonical zh policy SECTION (heading-anchored, the
00-core form) AND the canonical zh policy LINE (`输出语言：…`, the CLAUDE/copilot form), so the existing helper
extractors find both with their existing anchors and **zero extractor-logic change**.

**Why this shape (vs two files, or an en symmetric file):**

- The helper reads the **section** with `extract_section_to` (heading anchor `## 输出语言（按消费者分流）`,
  span `[heading, next "## ")`, `language-policy.sh:120-134`) and the **line** with `extract_line_to`
  (`^输出语言：` anchor, `:137-143`). If ONE file carries the section first and the line later, both anchors
  resolve in that single file → the re-point is just two path assignments, no extractor change. (PS mirror:
  `Get-SectionLines` `.ps1:136-150` + `Get-PolicyLine` `:153-158`.)
- A `_policy/` subdir (leading underscore) is **outside** the overlay layers init copies (`common/`,
  `<type>/`, `i18n/zh/common/`, `i18n/zh/<type>/`), so it is never laid into a generated project — it is a
  pure template-source asset the helper reads via `--template-root`, exactly like the SPECIAL files were. It is
  not a `.tmpl` the init copy walks (init copies `i18n/zh/common/` and `i18n/zh/<type>/`, not `i18n/zh/_policy/`).
- **No `.en.md` is created.** OQ-1's "possibly `.en.md` for symmetry" is declined: the en policy text already
  single-sources from `templates/common/.harness/rules/00-core.md.tmpl` + `common/CLAUDE.md.tmpl` (the helper's
  en branch reads those inline, `language-policy.sh:73-75`), and the en path must stay byte-unchanged (hard
  constraint B-7/AC-7). Adding an en file would be churn with no consumer. Symmetry is asymmetric here *by
  design* — en is the base, zh is the injected delta.

> The `.tmpl` suffix is retained so the file participates in nothing init-side but is consistent with sibling
> policy-bearing templates. The helper reads it RAW (it never substitutes `{{...}}` — the section/line carry no
> placeholders; see §3.3). It is **not** rendered or copied; only Read.

### 3.2 The file's exact content (verbatim T-013 text — byte-for-byte from the files being deleted)

The new M-1 file is the concatenation of the two extractable regions, in this order: **(A)** the zh policy
SECTION as it exists in the deleted `i18n/zh/common/.harness/rules/00-core.md.tmpl:9-31`, then **(B)** the zh
policy LINE as it exists in the deleted `i18n/zh/common/CLAUDE.md.tmpl:3`. A wrapping comment line and a
following `## ` sentinel heading bound the section so `extract_section_to`'s `[heading, next "## ")` span
terminates correctly (it currently terminates on `## How this project is developed`; here it must terminate on
a sentinel).

The file content the Developer writes is **exactly** (UTF-8, no BOM, LF line endings):

```
<!-- Single-source canonical zh output-language policy (T-016). Read at runtime by
     language-policy.{ps1,sh} (--lang zh); the SECTION below feeds 00-core, the LINE
     feeds CLAUDE.md + copilot. Do NOT add {{...}} placeholders. -->

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

## _policy-line-sentinel (not emitted; bounds the section span above)

输出语言：面向人的产出（对话、报告、README/人读文档）用**中文**，面向 agent/LLM 的产出（阶段文档、台账、规则、注释、commit）用**英文**。完整分流见 `.harness/rules/00-core.md`。
```

> **Byte-equivalence requirement (the load-bearing constraint).** Lines from `## 输出语言（按消费者分流）`
> through the blank line *before* `## _policy-line-sentinel` must be **byte-identical** to the current
> `i18n/zh/common/.harness/rules/00-core.md.tmpl:9-31` (so `extract_section_to` yields the SAME bytes it yields
> today — test-language #9 round-trip + test-init composed-body assertions both depend on this). The final
> `输出语言：…` line must be **byte-identical** to the current `i18n/zh/common/CLAUDE.md.tmpl:3`. The Developer
> produces M-1 by COPYING those exact spans out of the to-be-deleted files **before** deleting them — never by
> re-typing the Chinese (re-typing risks a CJK punctuation drift that breaks the byte-identity tests).

### 3.3 Why the section-span terminator works

`extract_section_to` (and `Get-SectionLines`) copies from the heading line until the next line matching `^## `
(exclusive). Today that terminator is `## How this project is developed` (00-core's next heading). In M-1 the
terminator is the sentinel `## _policy-line-sentinel …`. Because the span is `[heading, next "## ")` and
**includes the trailing blank line** before the sentinel (per the T-014 inclusive-span convention, insight-index
`:38`), the extracted section is byte-identical to today's extraction (which also includes the trailing blank
line before `## How this project is developed`). The sentinel heading is consumed by neither extractor (the
section extractor stops *before* it; the line extractor matches `^输出语言：`, not `^## `), so the only emitted
line below it is the policy line. **C-7 seam correctness is preserved by construction.**

---

## 4. The `/harness-language` source re-point (M-2…M-5) — exact lines

The ONLY change is *where the zh branch reads the canonical text from*. The en branch is untouched.

### 4.1 bash — `language-policy.sh` (M-2, mirror to M-4)

Current (`:73-81`):

```bash
if [[ "$LANG_ARG" == "en" ]]; then
    tmpl_common="$TEMPLATE_ROOT/skills/harness-init/templates/common"
    target_heading="$en_heading"
else
    tmpl_common="$TEMPLATE_ROOT/skills/harness-init/templates/i18n/zh/common"
    target_heading="$zh_heading"
fi
tmpl_core="$tmpl_common/.harness/rules/00-core.md.tmpl"
tmpl_claude="$tmpl_common/CLAUDE.md.tmpl"
```

New: the zh branch points `tmpl_core` AND `tmpl_claude` at the single-source file; the en branch is unchanged.

```bash
if [[ "$LANG_ARG" == "en" ]]; then
    tmpl_core="$TEMPLATE_ROOT/skills/harness-init/templates/common/.harness/rules/00-core.md.tmpl"
    tmpl_claude="$TEMPLATE_ROOT/skills/harness-init/templates/common/CLAUDE.md.tmpl"
    target_heading="$en_heading"
else
    tmpl_core="$TEMPLATE_ROOT/skills/harness-init/templates/i18n/zh/_policy/output-language.zh.md.tmpl"
    tmpl_claude="$tmpl_core"   # single source carries BOTH the section and the line
    target_heading="$zh_heading"
fi
```

The two `[[ ! -f "$tmpl_core" ]]` / `[[ ! -f "$tmpl_claude" ]]` precondition guards (`:83-90`) still fire with
the new paths (C-2 missing-source → exit 1 with the path named). The extractors (`:120-143`) are **unchanged**.

### 4.2 PowerShell — `language-policy.ps1` (M-3, mirror to M-5)

Current (`:70-78`):

```powershell
if ($Lang -eq "en") {
    $tmplCommon = Join-Path $TemplateRoot "skills/harness-init/templates/common"
    $targetHeading = $enHeading
} else {
    $tmplCommon = Join-Path $TemplateRoot "skills/harness-init/templates/i18n/zh/common"
    $targetHeading = $zhHeading
}
$tmplCore   = Join-Path $tmplCommon ".harness/rules/00-core.md.tmpl"
$tmplClaude = Join-Path $tmplCommon "CLAUDE.md.tmpl"
```

New:

```powershell
if ($Lang -eq "en") {
    $tmplCore   = Join-Path $TemplateRoot "skills/harness-init/templates/common/.harness/rules/00-core.md.tmpl"
    $tmplClaude = Join-Path $TemplateRoot "skills/harness-init/templates/common/CLAUDE.md.tmpl"
    $targetHeading = $enHeading
} else {
    $tmplCore   = Join-Path $TemplateRoot "skills/harness-init/templates/i18n/zh/_policy/output-language.zh.md.tmpl"
    $tmplClaude = $tmplCore
    $targetHeading = $zhHeading
}
```

The `Test-Path $tmplCore` / `Test-Path $tmplClaude` guards (`:80-87`) and the extractors (`:136-158`) are
**unchanged**.

### 4.3 Confirmation both zh + en still resolve

- **zh:** `extract_section_to` finds `## 输出语言（按消费者分流）` in M-1 (present, §3.2) → byte-identical
  section. `extract_line_to` finds `^输出语言：` in M-1 (present, §3.2 last line) → byte-identical line. Both
  non-empty → no `exit 1`. ✔ (B-4 / AC-6)
- **en:** unchanged paths; `## Output language (project-wide)` + `^Output language:` resolve from `common/` as
  before → byte-identical en output. ✔ (B-7 / AC-7)
- **Round-trip (test-language #9):** en→zh→zh produces byte-identical files iff M-1's section/line bytes equal
  what the SPECIAL files yielded today — guaranteed by the §3.2 copy-don't-retype rule. ✔

> Update the helper's header doc comment block in both files (bash `:12-15`, PS `:10-13`) to say the zh source
> is the `_policy/output-language.zh.md.tmpl` single source (not the i18n/zh SPECIAL files). This keeps the
> self-documenting "single source of truth" claim accurate. (Cosmetic; not behavior.)

---

## 5. The init-injection step (M-9 SKILL.md edit) — composition, idempotency, safety

### 5.1 What changes in `skills/harness-init/SKILL.md`

**(a) Step 4.3 zh-overlay file list (`SKILL.md:104-108`).** Today it lists the 3 policy-carrying files as part
of the zh overlay. Rewrite to state the overlay now carries ONLY the 2 human-facing files
(`docs/spec/README.md`, `evals/golden-tasks.md.tmpl`), and the policy-carrying surfaces are no longer overlaid
— they are COMPOSED in a new step 4.4.

**(b) NEW step 4.4 "Inject the zh output-language policy (zh init only)".** Inserted immediately after step 4.3,
before step 5 (placeholder substitution). Exact instruction:

> ### 4.4 Inject the output-language policy (only if Q5 = 中文)
>
> For a `zh` project, the English `common/` `00-core.md`, `CLAUDE.md`, and
> `.github/copilot-instructions.md` were laid down by step 4.1 and are still English. Convert their policy
> region to the canonical Chinese policy by running the **already-distributed** helper against the project root
> (it was copied into `.harness/scripts/` by step 4.1):
>
> ```powershell
> pwsh -NoProfile -File .harness/scripts/language-policy.ps1 -TemplateRoot <template-root> -Lang zh   # Windows
> # or
> bash .harness/scripts/language-policy.sh --template-root <template-root> --lang zh                  # macOS/Linux
> ```
>
> `<template-root>` is the directory **above** `skills/harness-init/templates` (the resolved plugin/skill root
> discovered in step 3) — the same value `/harness-language` uses. The helper:
> - rewrites the `## Output language (project-wide)` section in `.harness/rules/00-core.md` to the Chinese
>   `## 输出语言（按消费者分流）` section (REWRITE-SECTION),
> - rewrites the `Output language: **English**.` line in `CLAUDE.md` + copilot to the Chinese policy line
>   (REWRITE-LINE),
> - leaves every other byte untouched.
>
> Run this **before** step 5 placeholder substitution (the policy section/line carry no `{{...}}` tokens, so
> order is not load-bearing for them, but running pre-substitution keeps the helper reading clean template
> bytes and matches test-init's compose order). The helper writes timestamped `.bak` files; **delete the
> `*.bak-*` files it creates** after the run (they are an artifact of the rewrite path, not wanted in a fresh
> init tree). Then proceed to step 5.

**(c) Anti-pattern note.** Add to the "Anti-patterns" section: *"Do not re-create the deleted i18n/zh SPECIAL
files; the zh policy is single-sourced and injected (step 4.4)."*

### 5.2 Idempotency & safety

- **Idempotent.** The helper NOOPs when the target already matches (`write_or_noop` `cmp -s`, `:189-193`;
  PS `Write-OrNoop` `-ceq`, `.ps1:200-207`). A fresh `common/` 00-core has the EN section → the helper does a
  single REWRITE-SECTION, then is a no-op on any re-run. No double-injection risk.
- **No-network / local-only.** The helper reads M-1 from the resolved template root and writes only the three
  project files — no network, matching the init "no network" guarantee.
- **No new placeholder.** The section/line carry no `{{...}}` (C-5); D.2 unchanged; step 5's substitution still
  runs over `{{PROJECT_NAME}}` etc. in the header lines (which came from English `common/`, unchanged).
- **CONFLICT path inert here.** The helper's `exit 2` CONFLICT only fires when 00-core has *neither* canonical
  heading (`:240-244`). A freshly-copied English `common/` 00-core always has `## Output language
  (project-wide)` → `has_heading=true` → REWRITE-SECTION, never CONFLICT. So init never needs `--force`.
- **`.bak` cleanup.** Init deletes the `*.bak-*` files (step 4.4 instruction) so the generated tree is clean
  (test-init asserts no stray files via the placeholder/`.tmpl`/`.append` scans, `test-init.sh:187-196`; `.bak`
  is not in those globs, but a clean tree is the contract).

### 5.3 `/harness-adopt` mirror (M-10)

`harness-adopt/SKILL.md:275-284` ("Language handling") describes the same overlay copy. Apply the parallel
edit: drop the 3 SPECIAL files from the zh overlay description and add the same step-4.4-style injection
("after the English copy, run `language-policy --lang zh` against the project root"). The helper is laid into
the adopted project by the same `common/` copy adopt performs. Same idempotency/safety reasoning.

---

## 6. The 3 deletions + no-other-readers confirmation (M-6/M-7/M-8)

Delete:
1. `skills/harness-init/templates/i18n/zh/common/.harness/rules/00-core.md.tmpl` (F-2)
2. `skills/harness-init/templates/i18n/zh/common/CLAUDE.md.tmpl` (F-7)
3. `skills/harness-init/templates/i18n/zh/common/.github/copilot-instructions.md.tmpl` (F-8)

After deletion the i18n/zh overlay contains exactly **2** files (`Glob skills/harness-init/templates/i18n/zh/**/*`
today returns 5; minus 3 = 2): `i18n/zh/common/docs/spec/README.md` and
`i18n/zh/common/evals/golden-tasks.md.tmpl` — both human-facing KEEP-ZH (per CHANGELOG `[0.26.0]:16`).

**No-other-readers audit (grep-grounded).** I grepped the repo for runtime reads of these three paths
(`Grep "i18n/zh/common"` + `Grep "i18n.zh.*00-core|...CLAUDE|...copilot"`). Findings:

| Reader | Path | Kind | Action |
|---|---|---|---|
| `language-policy.sh:77` (+`.ps1:74`) | `i18n/zh/common` (zh source) | **runtime read** | Re-pointed (§4) — the ONLY runtime reader. |
| `.harness/scripts/test-init.sh:520` / `.ps1:622` | `i18n/zh/common` (fixture layer) | **test read** | Re-modelled to COMPOSE (§7). |
| `skills/harness-adopt/SKILL.md:279` | `templates/i18n/zh/common/` (prose) | doc instruction | Edited (M-10) to compose, not overlay the SPECIAL files. |
| `skills/harness-init/SKILL.md:104-108` | zh overlay prose | doc instruction | Edited (M-9) to drop the 3 SPECIAL files. |
| `CHANGELOG.md`, `docs/features/_archived/**`, `docs/features/i18n-special-drift-guard/01_*`, `.harness/insight-index.md:39-40` | various | **historical docs** | No action — these are archival/log references, not runtime readers. |

**Conclusion: the only runtime reader is `/harness-language`'s helper, which §4 re-points; the only test reader
is test-init, which §7 re-models. No script, skill, rule, or AI-GUIDE entry reads these three files at run
time.** Deletion is safe. (This matches insight-index `:39`'s own warning — "grep the OTHER scripts/skills for
reads of that path" — applied and cleared.)

---

## 7. The test-init fixture update (M-11/M-12) — COMPOSE, and the positive proof

### 7.1 The change: overlay → compose

`test_zh_overlay` (`test-init.sh:514-574`) / `Test-ZhOverlay` (`test-init.ps1:610-677`) today lay
`common → fullstack → i18n/zh/common`. Replace the third `copy_layer i18n/zh/common` with a COMPOSE step that
mirrors init's step 4.4:

```bash
# bash (test-init.sh, in test_zh_overlay) — replace the i18n/zh/common copy_layer line:
copy_layer "$template_root/common"   "$tmp" "zh-test" "fullstack" "Next.js + NestJS"
copy_layer "$template_root/fullstack" "$tmp" "zh-test" "fullstack" "Next.js + NestJS"
# NEW: lay the 2 human-facing zh files (overlay minus the deleted SPECIAL trio),
copy_layer "$template_root/i18n/zh/common" "$tmp" "zh-test" "fullstack" "Next.js + NestJS"
# NEW: then INJECT the zh policy via the helper (the elimination's compose step),
( cd "$tmp" && bash "$tmp/.harness/scripts/language-policy.sh" --template-root "$repo_root" --lang zh >/dev/null 2>&1 )
rm -f "$tmp/.harness/rules/"*.bak* "$tmp/"CLAUDE.md.bak* "$tmp/.github/"*.bak*  # drop rewrite .bak artifacts
```

> The `copy_layer i18n/zh/common` line stays (it now copies only the 2 human-facing files — `docs/spec/README.md`,
> `evals/golden-tasks.md.tmpl` — which the human-facing assertions at `:568-571` still need). The injection runs
> AFTER it, against the project root, exactly as init step 4.4 does. PS mirror: insert the analogous
> `& pwsh -NoProfile -File "$tmp/.harness/scripts/language-policy.ps1" -TemplateRoot $repoRoot -Lang zh` after
> the three `Copy-TemplateLayer` calls, then `Remove-Item` the `*.bak-*`.

The substitution caveat: `copy_layer` substitutes `{{PROJECT_NAME}}` etc. when it copies `common/` (so 00-core's
header is already `zh-test`-substituted before injection). The helper only rewrites the policy section/line
(no placeholders), so the composed 00-core has substituted header + injected zh policy + English body — exactly
what the overlay produced. The existing `grep -q 'test-project'`-style substitution assertions are in
`test_type` (not `test_zh_overlay`), and `test_zh_overlay` uses `zh-test`; both remain satisfied.

### 7.2 Existing assertions: confirmed to STILL HOLD on the composed result

The composed 00-core/CLAUDE/copilot are byte-for-byte the SAME content the overlay produced today (English body
from `common/`, zh policy from the canonical text — now sourced via M-1 instead of the SPECIAL file). Therefore:

- **T-015 inverse assertions hold:**
  - AI-facing English fall-through (`:535-553` / PS `:636-653`): AI-GUIDE/insight/workflow/dev-map/tasks are
    laid by `common`/`fullstack` only (never in the zh overlay) → unchanged by this task → still English. ✔
  - SPECIAL 00-core "ENGLISH body present" (`## Hard rules (red lines)`, `:555` / `:656`): the body comes from
    `common/` 00-core (English) and the helper does NOT touch it → present. ✔
  - SPECIAL 00-core "Chinese policy heading present" (`输出语言（按消费者分流）`, `:556` / `:657`): injected
    by the helper → present. ✔
  - SPECIAL 00-core "NO second English policy section" (`Output language (project-wide)` absent, `:557` /
    `:658`): the helper REWRITE-SECTION *replaces* the EN section (single-section invariant,
    `harness-language/SKILL.md:187-188`) → the EN heading is gone. ✔
  - SPECIAL CLAUDE/copilot "ENGLISH body present" + "Chinese policy line present" (`:560-566` / `:661-666`):
    body from `common/` (English) + line injected by helper (`输出语言：面向人的产出…`) → both present. ✔
- **The 4 T-013 zh policy assertions hold** (`:524-526` consumer markers + `:526` no `全程`): the injected
  section is the canonical T-013 text (M-1 §3.2) → markers present, `全程` absent. ✔
- **Human-facing Chinese assertions hold** (`:568-571` / `:669-672`): the 2 KEEP-ZH files are still in the zh
  overlay and still copied → Chinese. ✔

### 7.3 NEW positive assertion (the proof that replaces the would-be guard)

Add ONE new assertion (both shells) that proves the duplication is GONE **and** the composition produced the
canonical body — i.e. the composed zh 00-core's English BODY (after excluding the policy section) is
byte-identical to the English `common/` 00-core's body. This is the positive analogue of the guard the user did
not want: instead of a standing `verify_all` check, the test proves the single-source composition is correct.

```bash
# bash: extract the body-after-policy from both the composed zh 00-core and the English common/ 00-core,
# strip the policy section [policy heading, next "## "), compare the remainders byte-for-byte.
# Use the helper's own section-span convention so the seam matches.
composed_body="$(awk '/^## How this project is developed/{p=1} p' "$tmp/.harness/rules/00-core.md")"
# common/ template, substituted the same way (PROJECT_NAME=zh-test etc.) so headers match:
common_core_sub="$(mktemp)"; cp "$template_root/common/.harness/rules/00-core.md.tmpl" "$common_core_sub"
substitute "$common_core_sub" "zh-test" "fullstack" "Next.js + NestJS"
common_body="$(awk '/^## How this project is developed/{p=1} p' "$common_core_sub")"
assert "[zh][T-016] composed zh 00-core BODY byte-matches English common/ (single-source, no duplication)" \
    "[[ \"\$composed_body\" == \"\$common_body\" ]]"
rm -f "$common_core_sub"
```

> This asserts the body from `## How this project is developed` onward (the non-policy body, the exact region
> that was duplicated) is identical between the composed zh tree and the English source — proving the body is
> single-sourced from `common/`. PS mirror: select-string from `## How this project is developed` to EOF on
> both, compare with `-ceq`. The header (lines 1-7) is identical too (both from `common/`, both substituted),
> but anchoring the comparison at the body removes any policy-region ambiguity. This is the B-1 "ELIMINATE
> proves the body single-sources correctly" requirement made concrete (RA §3 B-1).

### 7.4 Mutation-proof (B-6) without a standing check

The positive assertion is non-vacuous by construction: it COMPOSES (lays `common` body + injects policy) and
then compares the composed body to `common`. If a future edit changed `common/` 00-core's body but the
composition mechanism failed to carry it (e.g. the helper accidentally rewrote body lines), the assertion goes
RED. If the helper's section seam regressed (over/under-cutting), the composed body would differ → RED. This
is the test-encoded mutation proof; it lives in the test suite, not as `verify_all` bloat. (B-6 satisfied via
test-init, per RA's ELIMINATE mapping §9.)

---

## 8. Version + count fan-out (M-13…M-18) — the anti-bloat confirmation

### 8.1 Check count STAYS 32 (the win)

**No lettered `verify_all` check is added.** Therefore the live count stays **32**, and **every "32 checks" /
"32/32" claim site is UNCHANGED**. Specifically these do NOT move (contrast RA §6.1, which was written for the
GUARD branch):

- `AI-GUIDE.md:36` `32/32` — unchanged. `AI-GUIDE.md:69` `32 checks` — unchanged.
- `docs/dev-map.md:65` `(32 checks)` — unchanged. `docs/dev-map.md:145` `runs all 32 checks` — unchanged.
- `.harness/rules/40-locations.md:25` `(32 checks` — unchanged.
- `README.md:5` / `README.zh-CN.md:5` `verify__all-32%2F32` badge + `(32 checks)` text — unchanged.
- `docs/manual-e2e-test.md` `32 checks` — unchanged.
- `.harness/scripts/baseline.json:10` `"verify_all_checks": 32` — unchanged.

G.4 derives the count from the live `report[]` tally and gates those sites; since the tally stays 32 and the
prose stays 32, G.4 is GREEN with no edits. **This is the structural anti-bloat outcome the user asked for.**

### 8.2 Version fan-out (the ONLY count-class change) — 0.26.0 → 0.27.0

Version-worthy: a mechanism + template change (delete 3 files, re-point a helper, change init/adopt
composition). G.3 gates version co-location. Edit exactly:

| Site | Current | New | Gate |
|---|---|---|---|
| `.claude-plugin/plugin.json:4` | `"version": "0.26.0"` | `0.27.0` | G.3 |
| `.claude-plugin/marketplace.json:17` | `"version": "0.26.0"` | `0.27.0` | G.3 |
| `README.md:5` (badge) | `version-0.26.0-blue` | `version-0.27.0-blue` | G.3 |
| `README.zh-CN.md:5` (badge) | `version-0.26.0-blue` | `version-0.27.0-blue` | G.3 |
| `CHANGELOG.md` | (top is `[0.26.0]`) | new `## [0.27.0] - 2026-06-09` heading + entry above it | G.4 CHANGELOG-heading check |

> **L36 same-file uniqueness:** in `README.md`/`README.zh-CN.md` line 5, the version token `version-0.26.0`
> is distinct from the unchanged `verify__all-32%2F32`, `test--init-274%2F274`, `integration-82%2F82` badges —
> edit ONLY the version substring; leave the others byte-exact. (The verify_all + integration badges do NOT
> move under ELIMINATE.)

### 8.3 test-init counts (baseline reconciliation, M-18, AC-10)

The zh fixture changes structure: it drops the implicit "i18n/zh SPECIAL overlay copy" and adds (a) the helper
injection invocation (no new assertion for the invocation itself unless desired) and (b) ONE new positive
body-match assertion (§7.3). Net assertion delta per shell: **+1** (the new T-016 body-match assert); the
existing 18 zh assertions are retained (they hold on the composed result, §7.2). So:

- `test_init_ps_assertions`: 274 → **275** (expected; CONFIRM from a captured run).
- `test_init_bash_no_python3_assertions`: 236 → **237** (expected; CONFIRM from a captured run).

> These numbers are the SA's *expectation*; per L27 / AC-10 the Developer MUST paste the ACTUAL captured
> two-shell `test-init` totals into `baseline.json:11-12` and update the `README.md:5` `test--init-274%2F274`
> badge to the captured PS total. Do NOT hand-ship the estimate. `test_language_*` stays **39/39** both shells
> (the re-point preserves byte-output; the regression must pass unchanged — `baseline.json:19-20`).

---

## 9. Risk analysis (≥3, each with mitigation)

| # | Risk | Likelihood | Mitigation |
|---|---|---|---|
| R-1 | **CJK byte-drift in M-1** — if the Developer re-types the Chinese instead of copying it, a full-width punctuation or character differs → `extract_section_to` yields different bytes → test-language #9 round-trip FAILs and test-init body assertions still pass but `/harness-language zh` ships subtly-wrong text. | Med | §3.2 mandates COPY the exact spans out of the to-be-deleted SPECIAL files **before** deleting them (Read F-2:9-31 + F-7:3, paste verbatim). L10: re-Read M-1 after Write; diff the extracted section/line against the originals before deleting them. test-language #9 is the byte-identity backstop. |
| R-2 | **Section-span seam off-by-one** — the sentinel terminator (`## _policy-line-sentinel`) cuts the section span differently than `## How this project is developed` did (e.g. trailing-blank-line handling), so the injected section gains/loses a blank line vs today. | Med | §3.3: keep the SAME inclusive-span convention; the blank line before the sentinel belongs to the section exactly as the blank line before `## How this project is developed` did today (insight `:38`). Verify by: extract from M-1 and `cmp` against extract from the old F-2 (both via the helper) BEFORE deleting F-2 — a one-time dev check. |
| R-3 | **Init can't resolve `<template-root>` at step 4.4** — the helper needs the resolved plugin/skill root; if init has not captured it, the injection can't run. | Low | Init step 3 ("Locate the template directory", `SKILL.md:82-93`) ALREADY resolves the template dir (it must, to copy from it). Step 4.4 reuses that same resolved path (the dir containing `skills/harness-init/templates`). `/harness-language` proves this discovery is reliable (`harness-language/SKILL.md:73-92`). If discovery somehow fails, init already cannot copy templates → it halts before 4.4 regardless. |
| R-4 | **Dogfood mirror desync (sync-self)** — `language-policy.{ps1,sh}` exists both as template (`skills/.../common/.harness/scripts/`) and dogfood mirror (`.harness/scripts/`); E.1 (`verify_all.sh:193-198`) byte-compares them. Editing only one side → E.1 FAIL. | Med | Edit the TEMPLATE (M-2/M-3) then run `sync-self` to propagate to the dogfood mirror (M-4/M-5), OR edit both identically. After the change run `sync-self --check`; E.1 must be green. (This is the standard template↔dogfood discipline; insight: red-line note in the dispatch.) |
| R-5 | **`.bak` artifacts leak into a generated tree** — the helper writes `*.bak-*` on rewrite; if init/adopt/test-init don't clean them, the fresh tree is dirty. | Low | Step 4.4 (M-9) + adopt (M-10) + test-init (M-11/12) all explicitly `rm`/`Remove-Item` the `*.bak-*` after the injection. test-init's no-stray-file contract (`:187-196`) is the backstop. |
| R-6 | **I.6 self-trip** — describing the relocated zh policy in a scanned file (M-1, SKILL.md, CHANGELOG, test code) could write a banned anchor. | Low | The relocated text is the T-013 anchor-free canonical form (consumer-split, `按消费者分流`); it carries NO retired blunt-Chinese anchor (insight `:36`; CHANGELOG `[0.26.0]:19` already confirms "preserved T-013 policy text is I.6-clean"). M-1 is the canonical text verbatim → I.6-clean by inheritance. Do not write the literal banned anchor in any prose describing it. Save all files UTF-8 no-BOM. |

---

## 10. Migration / rollout plan

- **Backwards compatibility — generated projects.** Already-generated zh projects are NOT migrated (O-3). They
  carry their own composed/overlaid policy already; nothing reads the deleted template files at *their* runtime.
  `/harness-language` / `/harness-upgrade` remain the surfaces to refresh an old project, and `/harness-language
  zh` now reads M-1 (transparent to the user — same canonical text).
- **The en path is byte-unchanged** (B-7/AC-7): en init lays `common/` directly, no injection; the helper's en
  branch reads `common/` inline as before. No en regression surface.
- **No feature flag needed** — this is a template/mechanism refactor with identical observable output (the
  composed zh tree equals the old overlaid zh tree byte-for-byte). The "migration" is internal to the kit.
- **Rollout sequence (single Developer):**
  1. Create M-1 (copy the exact zh section + line out of F-2/F-7/F-8 — §3.2).
  2. Re-point the helper template (M-2/M-3); `sync-self` to the dogfood mirror (M-4/M-5); `sync-self --check`
     green (E.1).
  3. Run `test-language.{sh,ps1}` → must be 39/39 both shells (proves the re-point preserved zh+en output).
  4. Delete F-2/F-7/F-8 (M-6/M-7/M-8).
  5. Edit SKILL.md step 4.3+4.4 (M-9) and adopt SKILL.md (M-10).
  6. Re-model test-init zh fixture to COMPOSE + add the body-match assertion (M-11/M-12); run both shells,
     capture totals.
  7. Reconcile `baseline.json` test-init counts from the captured run (M-18); update README test-init badge if
     PS total changed.
  8. Version fan-out 0.26.0→0.27.0 (M-13…M-16) + CHANGELOG `[0.27.0]` (M-17).
  9. `verify_all` 32/32 both shells (no new check; G.3/G.4 green).
- **Rollback:** `git reset` — all changes are in tracked template/script/doc files; no data migration, no
  external state.

---

## 11. Out-of-scope clarifications

- **No `verify_all` check is added or changed** (the explicit anti-bloat outcome). E.1 and all other checks are
  untouched; count stays 32.
- **No en `_policy` file** (§3.1) — en single-sources from `common/` already; adding one would be churn.
- **No policy-prose change** (O-1) — the Chinese T-013 text moves verbatim; not reworded.
- **No new language overlay** beyond zh (O-2). No migration of existing projects (O-3). The harness-kit dogfood
  English `AI-GUIDE.md`/`00-core.md`/`CLAUDE.md`/copilot are untouched (O-4, red-line).
- **The 2 human-facing zh files** (`docs/spec/README.md`, `evals/golden-tasks.md.tmpl`) stay in the overlay,
  Chinese, unchanged.
- **No new `{{...}}` placeholder** (D.2 unchanged).
- **GUARD (OQ-1a) is explicitly NOT pursued** — the user steered to ELIMINATE; this design supersedes RA §6's
  GUARD-default ACs via RA §9's ELIMINATE re-mapping (B-1 proven by the composed body-match test, not a check).

---

## 12. Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| Inject zh policy section + line into 00-core/CLAUDE/copilot | `language-policy.{ps1,sh}` REWRITE-SECTION / REWRITE-LINE | `skills/harness-init/templates/common/.harness/scripts/language-policy.{ps1,sh}` (+ dogfood mirror `.harness/scripts/`) | **Reuse as the composition engine** — re-point its zh source (§4), drive it from init step 4.4 + test-init. The elegant unification: "init zh = init en + `/harness-language zh`". |
| Heading-anchored section extraction (`[heading, next "## ")`) | `extract_section_to` / `Get-SectionLines` | `language-policy.sh:120-134` / `.ps1:136-150` | Reuse **unchanged** — only the source path changes, not the extractor. |
| Policy-line extraction (`^输出语言：`) | `extract_line_to` / `Get-PolicyLine` | `language-policy.sh:137-143` / `.ps1:153-158` | Reuse unchanged — finds the line in M-1. |
| Run a script against a fixture mid-test | `test_zh_overlay` already runs `harness-sync.sh` (`:100`) and `migrate-scripts-layout.sh` (`:482`) in-fixture | `.harness/scripts/test-init.{sh,ps1}` | Reuse the pattern — add the helper invocation to the zh fixture (§7.1). |
| Byte-identity body comparison (the positive proof) | `cmp -s` / `-ceq` idiom + the en→zh→zh round-trip pattern | `test-language.sh:242-244` (#9); E.1 `verify_all.sh:193-198` | Reuse the idiom for the composed-body assertion (§7.3) — a test, not a standing check. |
| Canonical zh policy text (the bytes to relocate) | F-2:9-31 (section) + F-7:3 (line) | `i18n/zh/common/.harness/rules/00-core.md.tmpl` + `CLAUDE.md.tmpl` | **Relocate verbatim** into M-1 (copy, never re-type — R-1) before deleting the originals. |
| Template discovery for the helper's `--template-root` | init step 3 resolution; `/harness-language` glob chain | `harness-init/SKILL.md:82-93`; `harness-language/SKILL.md:73-92` | Reuse the resolved path for step 4.4. (none new) |

---

## 13. Sequence / flow

**zh init (new composition flow):**

```
/harness-init (Q5 = 中文)
  step 3   resolve <template-root>  ──────────────┐
  step 4.1 copy common/  → target           (lays English 00-core/CLAUDE/copilot
           (incl. .harness/scripts/language-policy.{ps1,sh})  + the helper itself)
  step 4.2 copy fullstack/ → target
  step 4.3 copy i18n/zh/common/ → target    (ONLY 2 human-facing files now)
  step 4.4 RUN  language-policy --lang zh --template-root <root>   ◄── NEW
             ├─ reads M-1  i18n/zh/_policy/output-language.zh.md.tmpl  (single source)
             ├─ REWRITE-SECTION 00-core: EN policy → zh 输出语言（按消费者分流）
             ├─ REWRITE-LINE   CLAUDE.md + copilot: EN line → zh 输出语言：…
             └─ rm *.bak-*
  step 5   substitute {{PROJECT_NAME}} … (policy region has none)
  step 6   harness-sync …
  ⇒ composed zh tree  ==  (byte-for-byte)  the old overlaid zh tree
```

**`/harness-language zh` (re-pointed source):**

```
/harness-language zh
  → language-policy --lang zh --template-root <cache>
      tmpl_core = tmpl_claude = i18n/zh/_policy/output-language.zh.md.tmpl   ◄── re-pointed (§4)
      extract_section_to (## 输出语言（按消费者分流）)  → 00-core section
      extract_line_to    (^输出语言：)                  → CLAUDE/copilot line
  ⇒ identical canonical text as before; test-language 39/39 still green
```

---

## 14. AC / DO traceability

| AC (RA §6, ELIMINATE-mapped §9) | How this design satisfies it |
|---|---|
| AC-1 / B-1 (body single-sources; drift impossible) | Duplication DELETED (§6); composed body proven == `common/` body by the new test-init assertion (§7.3). |
| AC-2 / B-3 (current tree passes) | No new check; existing 32/32 unchanged; test-init composes green (§7.2). |
| AC-3 / B-2 (policy region intentional diff preserved) | The helper REWRITE-SECTION/LINE injects the zh policy; en≠zh by design, no comparison FAILs (no guard exists). |
| AC-6 / B-4 (`/harness-language zh` works) | Re-point preserves byte-output; test-language 39/39 (§4.3, §8.3). |
| AC-7 / B-7 (en byte-unchanged) | en branch untouched; en init lays `common/` directly (§4.1, §10). |
| AC-8 / B-8 (count+version consistent) | Count STAYS 32 (no check added, §8.1); version 0.26.0→0.27.0 (§8.2). |
| AC-9 / B-9 (no I.6 self-trip; gate green) | T-013 anchor-free text relocated verbatim (R-6); 32/32 both shells. |
| AC-10 (baseline from captured run) | M-18: test-init counts pasted from actual two-shell run, not estimated (§8.3). |
| B-5 (cross-shell parity) | Helper + test-init edited in BOTH shells; helper already cross-shell-parity-proven (insight `:38`). |
| B-6 (mutation-proven) | The composed-body assertion goes RED if composition/seam regresses (§7.4). |

> **DO traceability:** DO = "eliminate the duplication root cause via good design, no new guard, count stays 32"
> (PM_LOG `:54-68`). Satisfied: 3 SPECIAL files deleted (root cause gone), zero new `verify_all` checks
> (count 32), zh policy single-sourced + injected via the reused T-014 helper (good design / unification).

---

## 15. Partition assignment

Single-Developer mode (no `.harness/agents/dev-*.md` — confirmed `PM_LOG.md:15-16`). All files owned by the one
Developer. Dispatch order = the §10 rollout sequence (M-1 → re-point+sync → test-language → deletions →
SKILL.md → test-init → baseline → version → verify_all). Strict sequential (each step gates the next:
re-point must precede deletion so test-language proves the source before the SPECIAL files vanish). No
parallelism.

---

## 16. Verdict

**READY.**

init-composition is **FEASIBLE** and low-risk (§0): init is AI-orchestrated and already runs scripts mid-flow;
the injection helper ships into the project before it is needed; and `/harness-language` already performs this
exact zh injection with a green 39/39 regression. The ELIMINATE design is concrete and complete: the
single-source location/shape is chosen (`i18n/zh/_policy/output-language.zh.md.tmpl`, one file carrying both the
section and the line, §3); the `/harness-language` zh-source re-point is specified to the exact line (§4) with
en+zh resolution confirmed; the init step-4.4 injection + idempotency/safety is specified (§5) and mirrored for
adopt; the 3 deletions are audited to have **no other runtime reader** beyond the re-pointed helper (§6); the
test-init fixture is re-modelled to COMPOSE with a NEW positive body-match assertion replacing the would-be
guard (§7); and the version fan-out is 0.26.0→0.27.0 with the **`verify_all` check count staying 32** (the
explicit anti-bloat win, §8). Residual risk is the CJK byte-drift / section-seam pair (R-1/R-2), mitigated by
copy-don't-retype + a pre-delete `cmp` of the extracted section against the original, with test-language #9 as
the byte-identity backstop. No upstream block; the requirement is fully satisfied by ELIMINATE.
