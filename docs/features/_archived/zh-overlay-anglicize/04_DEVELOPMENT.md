# Development Record · T-015 / zh-overlay-anglicize

> Stage 4 of the Harness pipeline. Mode: **full**. Author: Developer (single-developer mode).
> Implements `02_SOLUTION_DESIGN.md` (APPROVED in `03_GATE_REVIEW.md`) exactly. No design decisions made
> by the Developer except the Gate-delegated F-1 type-dir-coverage choice (documented below).

## Summary

Anglicized the AI-facing static scaffolding shipped to a generated `{{LANG}}=zh` project so it matches the
T-013 consumer-split policy the project declares (AI-facing → English). Removed the 11 purely-AI-facing files
from the `i18n/zh` overlay (they now fall through to the English `common/`/type originals), spliced the 3
policy-carrying files in place (English `common/` framework body + the byte-for-byte T-013 Chinese policy
section/line), left the 2 human-facing files Chinese, added symmetric PS+Bash inverse assertions to test-init,
corrected the SKILL.md step-4.3 overlay file-list, and fanned out the 0.25.0 → 0.26.0 version bump.

## Files changed

### Deletions (11 ANGLICIZE — `git rm`, each falls through to a confirmed-present English original)
- `skills/harness-init/templates/i18n/zh/common/AI-GUIDE.md.tmpl` → falls to `common/AI-GUIDE.md.tmpl` (`# AI-GUIDE — … project index`)
- `…/i18n/zh/common/.harness/rules/05-insight-index.md.tmpl` → `common/.harness/rules/05-insight-index.md.tmpl` (`# 05 — Cross-task insight index`)
- `…/i18n/zh/common/.harness/rules/60-tool-handoff.md` → `common/.harness/rules/60-tool-handoff.md`
- `…/i18n/zh/common/.harness/rules/75-safety-hook.md.tmpl` → `common/.harness/rules/75-safety-hook.md.tmpl`
- `…/i18n/zh/common/.harness/insight-index.md.tmpl` → `common/.harness/insight-index.md.tmpl`
- `…/i18n/zh/common/docs/workflow.md` → `common/docs/workflow.md` (`# Workflow: The 7-Agent Pipeline`)
- `…/i18n/zh/common/docs/dev-map.md.tmpl` → `common/docs/dev-map.md.tmpl` (`# Dev Map — …`)
- `…/i18n/zh/common/docs/tasks.md.tmpl` → `common/docs/tasks.md.tmpl` (`# Task Board — …`)
- `…/i18n/zh/fullstack/.harness/rules/50-fullstack.md` → `fullstack/.harness/rules/50-fullstack.md` (`## Fullstack-specific rules`)
- `…/i18n/zh/backend/.harness/rules/50-backend.md` → `backend/.harness/rules/50-backend.md`
- `…/i18n/zh/generic/.harness/rules/50-generic.md.tmpl` → `generic/.harness/rules/50-generic.md.tmpl`

All 11 fall-through targets were verified present on disk before deletion (Glob + head-1 marker check). After
deletion the `i18n/zh/{fullstack,backend,generic}` dirs are empty and gone; no empty dirs left behind. The
`i18n/zh` overlay now contains exactly **5** files (3 SPECIAL + 2 KEEP-ZH).

### SPECIAL splices (3 — edit in place, English body + byte-for-byte T-013 zh policy)
- `…/i18n/zh/common/.harness/rules/00-core.md.tmpl` — rewrote as the English `common/00-core.md.tmpl` with its
  English `## Output language (project-wide)` section (en `:9-22`) REPLACED by the Chinese
  `## 输出语言（按消费者分流）` section from the prior zh overlay (zh `:9-31`). Verified: EN header (`:1-7`) and
  the entire EN body (`## How this project is developed` → EOF) are **byte-identical** to `common/` (diff =
  empty); only the policy section is Chinese.
- `…/i18n/zh/common/CLAUDE.md.tmpl` — the English `common/CLAUDE.md.tmpl` with **only line 3** swapped to the
  Chinese policy line. Verified: `diff` vs `common/` shows exactly one differing line (line 3).
- `…/i18n/zh/common/.github/copilot-instructions.md.tmpl` — the English `common/` copilot with **only line 6**
  swapped to the same Chinese policy line. Verified: `diff` vs `common/` shows exactly one differing line (line 6).

### KEEP-ZH (untouched)
- `…/i18n/zh/common/docs/spec/README.md` (`# 项目 SPEC`)
- `…/i18n/zh/common/evals/golden-tasks.md.tmpl` (`# Golden Tasks — 轻量回归任务集`)

### Other edits
- `skills/harness-init/SKILL.md` — step 4.3 overlay file-list rewritten to name only the 5 remaining files and
  frame the not-in-overlay rule as the deliberate anglicization mechanism (design §8 / AC-10).
- `.harness/scripts/test-init.ps1` (`Test-ZhOverlay`) + `.harness/scripts/test-init.sh` (`test_zh_overlay`) —
  +19 inverse assertions each (symmetric, pure-grep, no-python3-tolerant). Existing 4 T-013 zh assertions kept.
- `.harness/scripts/baseline.json` — `test_init_ps_assertions` 255 → 274, `test_init_bash_no_python3_assertions`
  217 → 236 (captured two-shell run; see below).
- `.claude-plugin/plugin.json:4`, `.claude-plugin/marketplace.json:17` — version 0.25.0 → 0.26.0.
- `README.md:5`, `README.zh-CN.md:5` — version badge 0.25.0 → 0.26.0; test-init badge 255 → 274.
- `CHANGELOG.md` — new `[0.26.0] - 2026-06-09` entry (the deletions + SPECIAL splices + SKILL.md fix + inverse
  assertions + baseline reconciliation + version bump + explicit "skill 14 / check 32 / no new placeholder").

## SPECIAL splice — single-section verification (R-3 / Gate Top-3 #1)

For `00-core.md.tmpl`, after Write I re-Read (grep over the file) and confirmed the single-policy-section invariant:
- `## Hard rules (red lines)` — **PRESENT** (English body marker)
- `## 输出语言（按消费者分流）` — **PRESENT** (Chinese T-013 policy heading)
- `Output language (project-wide)` — **ABSENT** (no leftover English policy section → no double-section)
- AC-8 markers preserved: `给用户的交付总结` PRESENT, `commit message` PRESENT, `全程` ABSENT (I.6-clean)
- placeholders: only `{{PROJECT_NAME}} {{PROJECT_TYPE}} {{STACK}} {{TODAY}}` (the EN header set; no new token)

For `CLAUDE.md.tmpl` / copilot: each has exactly **1** `输出语言` policy line, the English `Output language:
**English**.` line is gone, the English body (`The full project ruleset lives in …`, red-lines block) is
present, and only `{{PROJECT_NAME}}` appears. CJK saved UTF-8 (grep matched the exact CJK headings — no mojibake).

## test-init inverse assertions + the F-1 type-dir decision

**F-1 decision: option (b) — type-dir deletions are AUDIT-ONLY (no vacuous coverage shipped).**

The zh fixture layers `common → fullstack → i18n/zh/common` but never `i18n/zh/fullstack` (test-init.sh:518-520
/ ps1:620-622). An EN-marker assertion on `50-fullstack.md` would therefore pass *regardless* of the F-14
deletion (the English `fullstack/50-fullstack.md` ships from layer 2 pre-deletion) → vacuous, exactly the Gate
F-1 finding. Option (a) (add an `i18n/zh/fullstack` fixture layer) is **infeasible** here, not merely
non-cheap: `copy_layer` throws/exits on a missing source dir (ps1:53 `throw "source missing"`, sh:69 `exit 1`),
and the `i18n/zh/fullstack` dir is the very thing the F-14 deletion removes — so a layer call would error, and
guarding it would make the call a no-op that still leaves the English file from layer 2 (still vacuous). I
therefore did NOT write a `50-fullstack.md` assertion. The 3 type-dir deletions (F-14/F-15/F-16) are audited as
fall-through-confirmed: all 3 English targets (`templates/{fullstack,backend,generic}/.harness/rules/50-*`) are
present on disk, and the CHANGELOG records them as audit-only. This honors Gate F-1 / insight 2026-05-16
(no one-sided/vacuous assertion claiming coverage it lacks).

**Assertions added (per file, PRESENT and ABSENT on DIFFERENT strings — no T-007 same-string trap):**

| zh-fixture file | PRESENT (EN, post-change) | ABSENT (ZH, old) |
|---|---|---|
| `AI-GUIDE.md` | `project index` | `项目指南` |
| `.harness/rules/05-insight-index.md` | `Cross-task insight index` | `跨任务` |
| `docs/workflow.md` | `The 7-Agent Pipeline` | `工作流` |
| `docs/dev-map.md` | `Dev Map` | `开发导航` |
| `docs/tasks.md` | `Task Board` | `任务看板` |
| `00-core.md` (SPECIAL) | `## Hard rules (red lines)` + `输出语言（按消费者分流）` | `Output language (project-wide)` |
| `CLAUDE.md` (SPECIAL) | `The full project ruleset lives in` + `输出语言：面向人的产出` | — |
| `copilot-instructions.md` (SPECIAL) | `The full project ruleset lives in` + `输出语言：面向人的产出` | — |
| `docs/spec/README.md` (KEEP-ZH) | `项目 SPEC` | — |
| `evals/golden-tasks.md` (KEEP-ZH) | `轻量回归任务集` | — |

The existing 4 T-013 zh assertions (`00-core.md overlaid`, the two policy markers, the `全程`-absent guard) are
retained unchanged — they target `00-core.md`, a SPECIAL file that stays, and the F-2 splice preserves their
markers (AC-8). +19 assertions per shell.

## verify_all result

- **Baseline (pre-change):** verify_all.ps1 = **32 PASS / 0 WARN / 0 FAIL**; verify_all.sh = **32 PASS / 0 WARN / 0 FAIL**.
- **After changes:** verify_all.ps1 = **32 PASS / 0 WARN / 0 FAIL**; verify_all.sh = **32 PASS / 0 WARN / 0 FAIL**.
- **Delta:** 0 new failures, 0 new warnings. All 32 checks green in both shells, including G.3 (version stamps
  consistent at 0.26.0), G.4 (doc count/version claims consistent with plugin.json + live check count), C.1/G.1/G.2
  (14 skills, unchanged), D.2 (no new placeholder), I.6 (no retired-claim resurgence / no self-trip).

## test-init result (captured two-shell run — NOT hand-estimated; F-6 / insight 2026-06-04)

- **test-init.ps1:** baseline **255/255** PASS → after **274/274** PASS, 0 FAIL (+19).
- **test-init.sh (no-python3 path):** baseline **217/217** PASS → after **236/236** PASS, 0 FAIL (+19).
  - Note: on this machine `command -v python3` succeeds but the real-invocation probe (`echo '' | python3 -c
    'pass'`) FAILS (Microsoft Store stub), so the bash run executes the no-python3 path — confirmed by 3
    `SKIP [AI-native block — python3 required, not available]` lines. The 236 is genuinely the
    `test_init_bash_no_python3_assertions` count. Reproduced the script's exact probe to confirm.
- The 19 new zh inverse assertions PASS in both shells; the 4 existing T-013 zh assertions still PASS.
- `baseline.json` + README test-init badge updated from these captured numbers (255→274, 217→236).

## `/harness-language zh` dependency (T-014) — intact

The 3 SPECIAL files remain on disk. `language-policy.sh:80-81` (and the ps1 equivalent) read ONLY
`i18n/zh/common/.harness/rules/00-core.md.tmpl` (extracts the `## 输出语言（按消费者分流）` section) and
`i18n/zh/common/CLAUDE.md.tmpl` (extracts the `输出语言：` line) — both preserved byte-for-byte. None of the 11
deleted files are referenced by the helper. So `/harness-language zh` keeps working (verified by reading the
helper's template-resolution block + confirming both files present after edits).

## I.6 self-trip check (insight 2026-06-08, 3× recurrence)

Grepped every edited SCANNED file for `全程`: SKILL.md / README.md / README.zh-CN.md / the 3 SPECIAL templates =
**0**. The only `全程` is in the pre-existing retained `[zh] retired blunt 全程 phrasing is absent` assertion
(test-init.ps1:628 / .sh:526), which has no `中文` on the line — identical to the pre-T-015 green state. No new
`全程…中文` anchor introduced. CHANGELOG is I.6-exempt regardless. verify_all I.6 PASS confirms.

## No stray placeholder (T-012 scan)

Confirmed no new `{{...}}` token: the SPECIAL files keep only their EN-header placeholders; deletions remove
placeholders. test-init's recursive `\{\{[A-Z_]+\}\}` scan passes (part of the 274/236 PASS). D.2 PASS.

## EN path untouched

`git diff` (working tree + staged) shows **no change** under `skills/harness-init/templates/common/` — the
English originals and the en render are byte-identical. AC-7 holds.

## Design drift (if any)

None functional. One documentation refinement vs the design text:
- Design §7's fixture note claimed the existing layering already covers the `50-fullstack.md` fall-through;
  Gate F-1 corrected this (the fixture never layers `i18n/zh/fullstack` → such an assertion is vacuous). I
  followed the **Gate F-1** ruling and my Developer brief, choosing option (b) (audit-only type-dir deletions,
  no vacuous assertion) rather than the design §7 wording. This is the Gate-delegated decision, not silent
  drift — flagged here for the reviewer. Not a `DESIGN DRIFT` of behavior; the shipped templates match the
  design exactly.

## Open issues for review

- `docs/dev-map.md` does not enumerate the `i18n/zh/` overlay file list anywhere (its tree shows `common/` /
  `fullstack/` / `backend/` only), so the deletions/splices change no existing dev-map line — no dev-map edit
  was required for structural accuracy. The historical v0.16.0-pinned test-init count annotation on dev-map.md
  line 146 ("227 assertions on PS / 191 Bash … at v0.16.0") is a frozen snapshot, left unchanged (not a live claim).
- `docs/tasks.md` shows as modified in git status — that edit was made by the PM at dispatch (records T-015
  active), NOT by the Developer. Left untouched per the brief (PM owns it).

## Dev-map updates

None required — the zh overlay file list is not described in `docs/dev-map.md`; no structural line changed.

## Verdict

READY FOR REVIEW
