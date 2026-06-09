# Test Report · T-015 / zh-overlay-anglicize

> Stage 6 of the Harness pipeline. Author: QA Tester. Adversarial contract enforced.
> Verdict is based on whether the implementation **survived RUNNING**, with REAL captured
> output for every claim. All numbers below were produced by runs in THIS session — none
> remembered or copied from `04_DEVELOPMENT.md` (those were reproduced independently).

## Headline result

**APPROVED FOR DELIVERY (PASS).** 0 BLOCKER · 0 CRITICAL · 0 MAJOR · 0 MINOR defects.

The two load-bearing real-behavior checks both PASS against an independently-generated zh project:

1. **Generated-zh-tree inspection (#1):** a `{{LANG}}=zh` project, built by an *independent* QA reproducer of
   SKILL.md step-4 overlay layering (`common → fullstack → i18n/zh/common → i18n/zh/fullstack`), ships the
   AI-facing scaffolding in **English** (byte-identical to the EN render) and the human-facing files in
   **Chinese**, with `00-core.md` carrying an English body + exactly ONE Chinese policy section. The shipped
   scaffolding now matches the policy it declares.
2. **`/harness-language zh` (T-014) cross-task dependency (#2):** the real `language-policy.{sh,ps1}` helper,
   run against the EDITED SPECIAL files, STILL extracts and applies the `## 输出语言（按消费者分流）` section and
   the `输出语言：` line. The body anglicization did **not** break the helper's section-extraction. No regression.

## Test plan (AC → test)

| Acceptance criterion | Test case(s) | Evidence source |
|---|---|---|
| AC-1 AI-GUIDE EN | `[zh] AI-GUIDE.md is now ENGLISH` / `…no longer Chinese`; independent gen + diff vs EN | test-init both shells; QA reproducer |
| AC-2 rule frags/docs/type-50 EN | `[zh] 05-insight-index/workflow/dev-map/tasks …`; 50-fullstack fall-through; diff IDENTICAL vs EN (9 files) | test-init; QA reproducer diff |
| AC-3 00-core EN body + ZH policy, single section | `[zh] 00-core.md has ENGLISH body` + `keeps Chinese policy heading` + `NO second (English) policy section` | test-init; QA reproducer diff (body tail IDENTICAL) |
| AC-4 CLAUDE/copilot EN body + ZH line | `[zh] CLAUDE.md/copilot … ENGLISH body` + `keeps the Chinese policy line` | test-init; QA reproducer diff (exactly 1 line) |
| AC-5 spec/README stays ZH | `[zh] docs/spec/README.md stays Chinese (项目 SPEC)` | test-init; QA reproducer |
| AC-6 golden-tasks stays ZH | `[zh] evals/golden-tasks.md stays Chinese (轻量回归任务集)` | test-init; QA reproducer |
| AC-7 EN path byte-identical | `git diff` under `templates/common/` + EN type dirs = EMPTY | git diff (working + staged) |
| AC-8 existing 4 T-013 zh assertions pass | `[zh] 00-core overlaid` + 2 markers + `全程 absent` | test-init both shells |
| AC-9 inverse coverage non-vacuous | reverted-deletion probe → assertion FAILs | independent revert simulation |
| AC-10 SKILL.md lists 5 | SKILL.md:107 names the 5; AI-facing described as NOT-in-overlay | grep SKILL.md |
| AC-11 verify_all 32/32 both shells | verify_all.ps1 + .sh runs | captured below |
| AC-12 CHANGELOG + bump, 32/14 | version fan-out + counts | grep + verify_all |

## Mandatory execution checklist (RUN, both shells)

### 1. verify_all — BOTH shells = 32 PASS / 0 WARN / 0 FAIL

**PowerShell `verify_all.ps1`** (full Summary):

```
=== Summary ===
  PASS: 32
  WARN: 0
  FAIL: 0
```
Key checks (all PASS): `[C.1] All 14 skills present`, `[G.3] Version stamps consistent`,
`[I.6] No retired-claim phrases in current docs/templates ... PASS`, `[J.1] settings.json schema integrity`,
`[G.4] Doc count/version claims consistent with plugin.json + live check count`.

**Git-bash `verify_all.sh`** (full Summary, exit 0):

```
[C.1] All 14 skills present ... PASS
...
[I.6] No retired-claim phrases in current docs/templates ... PASS
[J.1] settings.json schema integrity (.claude/ + template) ... PASS
[G.4] Doc count/version claims consistent with plugin.json + live check count ... PASS

=== Summary ===
  PASS: 32
  WARN: 0
  FAIL: 0
```

Both shells: **32/32, 0 WARN, 0 FAIL, I.6 PASS, 14 skills, version checks PASS.** ✅ (AC-11)

### 2. test-init — reproduced 274 (PS) / 236 (Bash no-python3)

**PowerShell `test-init.ps1`:**
```
=== Result ===
  PASS: 274
  FAIL: 0
```

**Git-bash `test-init.sh`** (no-python3 path confirmed — 3 `SKIP [AI-native block — python3 required, not available]`):
```
=== Result ===
  PASS: 236
  FAIL: 0
```

Both reproduce the Dev's claimed 274/236 exactly. The 23 `[zh]` assertions (4 existing T-013 + 19 new inverse)
all PASS in both shells. The no-python3 bash path is environment-specific (Microsoft Store python3 stub) and
was confirmed by the 3 SKIP lines. ✅ (AC-8, AC-9)

All 23 `[zh]` assertions captured PASSing (bash, CJK renders correctly):
```
PASS  [zh] 00-core.md overlaid
PASS  [zh] policy lists a Chinese-artifact (consumer=human) marker
PASS  [zh] policy lists an English-artifact (consumer=agent) marker
PASS  [zh] retired blunt 全程 phrasing is absent
PASS  [zh] AI-GUIDE.md is now ENGLISH (project index present)
PASS  [zh] AI-GUIDE.md no longer Chinese (项目指南 absent)
PASS  [zh] 05-insight-index.md is now ENGLISH (Cross-task insight index present)
PASS  [zh] 05-insight-index.md no longer Chinese (跨任务 absent)
PASS  [zh] docs/workflow.md is now ENGLISH (7-Agent Pipeline present)
PASS  [zh] docs/workflow.md no longer Chinese (工作流 absent)
PASS  [zh] docs/dev-map.md is now ENGLISH (Dev Map present)
PASS  [zh] docs/dev-map.md no longer Chinese (开发导航 absent)
PASS  [zh] docs/tasks.md is now ENGLISH (Task Board present)
PASS  [zh] docs/tasks.md no longer Chinese (任务看板 absent)
PASS  [zh] 00-core.md has ENGLISH body (Hard rules (red lines) present)
PASS  [zh] 00-core.md keeps Chinese policy heading (输出语言（按消费者分流） present)
PASS  [zh] 00-core.md has NO second (English) policy section (Output language (project-wide) absent)
PASS  [zh] CLAUDE.md has ENGLISH body (full project ruleset present)
PASS  [zh] CLAUDE.md keeps the Chinese policy line (输出语言：面向人的产出 present)
PASS  [zh] copilot-instructions.md has ENGLISH body (full project ruleset present)
PASS  [zh] copilot-instructions.md keeps the Chinese policy line (输出语言：面向人的产出 present)
PASS  [zh] docs/spec/README.md stays Chinese (项目 SPEC present)
PASS  [zh] evals/golden-tasks.md stays Chinese (轻量回归任务集 present)
```

## HEADLINE PROBE #1 — inspect a REAL generated zh project (AC-1..AC-6, AC-9)

I did **not** trust the developer's test fixture. I wrote an independent reproducer (`/tmp/qa_zh_init.sh`) that
replicates SKILL.md step-4 layering exactly: `cp -a common → fullstack → i18n/zh/common → i18n/zh/fullstack`,
then strips `.tmpl` suffixes. The `i18n/zh/fullstack` layer is **absent** (confirmed by the reproducer:
`(layer absent: …/i18n/zh/fullstack)`), so the fullstack `50-*` falls through to the English layer-2 version.
I then inspected the generated tree and diffed it against an independently-generated EN tree (no overlay).

**AC-1 / AC-2 — AI-facing files are ENGLISH, byte-identical to the EN render:**
```
IDENTICAL  AI-GUIDE.md                          (L1: # AI-GUIDE — {{PROJECT_NAME}} project index)
IDENTICAL  .harness/rules/05-insight-index.md   (L1: # 05 — Cross-task insight index)
IDENTICAL  .harness/rules/60-tool-handoff.md
IDENTICAL  .harness/rules/75-safety-hook.md
IDENTICAL  .harness/insight-index.md
IDENTICAL  docs/workflow.md                     (L1: # Workflow: The 7-Agent Pipeline)
IDENTICAL  docs/dev-map.md                      (L1: # Dev Map — {{PROJECT_NAME}})
IDENTICAL  docs/tasks.md                        (L1: # Task Board — {{PROJECT_NAME}})
IDENTICAL  .harness/rules/50-fullstack.md       (EN 'Fullstack-specific rules' present)
```
Each Chinese marker (`项目指南 工作流 任务看板 开发导航 跨任务 工具交接 安全`) is **absent** from every one of these files.

**AC-3 — `.harness/rules/00-core.md`: English body + EXACTLY ONE Chinese policy section:**
```
EN body '## Hard rules (red lines)' present?           : YES
ZH policy '## 输出语言（按消费者分流）' present?            : YES
EN-policy '## Output language (project-wide)' ABSENT?  : YES absent (good)
count of '输出语言（按消费者分流）' occurrences            : 1
count of '## Output language' (any) occurrences        : 0
```
diff (zh 00-core vs EN 00-core) is confined to the policy section only; **the body after the policy section
(`## How this project is developed` → EOF) is byte-IDENTICAL** between zh and EN. No double-section, no body
corruption.

**AC-4 — CLAUDE.md + copilot: English body + single Chinese policy line:**
```
CLAUDE.md  : diff vs EN = exactly line 3 (Output language: **English**. → 输出语言：面向人的产出…); count '输出语言'=1
copilot    : diff vs EN = exactly line 6 (same swap); 'applyTo' frontmatter present; count '输出语言'=1
```
The English `Output language: **English**.` line is absent from both (no leftover).

**AC-5 / AC-6 — human-facing files stay Chinese:**
```
docs/spec/README.md       L1: # 项目 SPEC                        ('项目 SPEC' present: YES)
evals/golden-tasks.md     L1: # Golden Tasks — 轻量回归任务集      ('轻量回归任务集' present: YES)
```

**This is the behavioral proof:** a shipped zh project now reads AI-facing scaffolding in English and
human-facing files in Chinese — matching the T-013 consumer-split policy it declares. ✅

## HEADLINE PROBE #2 — `/harness-language zh` (T-014) still works after anglicization (CR residual risk d)

The T-014 helper resolves its canonical zh policy from the EDITED SPECIAL files
(`i18n/zh/common/.harness/rules/00-core.md.tmpl` + `CLAUDE.md.tmpl`). If body anglicization broke the
section-extraction, `/harness-language zh` would be permanently broken — a BLOCKING cross-task regression.
I ran the **real helper** against a throwaway EN project, `--template-root <repo>`, `--lang zh`.

**Dry-run (proves section-extraction succeeds without mutating) — `language-policy.sh`, EXIT=0:**
```
LANG|zh
DETECT|en|00-core
PLAN|REWRITE-SECTION|.harness/rules/00-core.md|to zh
PLAN|REWRITE-LINE|CLAUDE.md|to zh
PLAN|REWRITE-LINE|.github/copilot-instructions.md|to zh
SUMMARY|rewritten=3 noop=0 skipped=0 baks=0 conflicts=0
```

**Real apply — `language-policy.sh --lang zh`, EXIT=0 (the Chinese three-way policy LANDED):**
```
RESULT|REWRITE-SECTION|.harness/rules/00-core.md|to zh
RESULT|REWRITE-LINE|CLAUDE.md|to zh
RESULT|REWRITE-LINE|.github/copilot-instructions.md|to zh
SUMMARY|rewritten=3 noop=0 skipped=0 baks=3 conflicts=0
```
Post-apply verification on the project surface:
```
00-core heading now : ## 输出语言（按消费者分流）
00-core has '给用户的交付总结' (zh marker)? : YES
00-core has EN policy heading still?       : NO (good, single section)
CLAUDE.md policy line now zh?              : YES
copilot policy line now zh?               : YES
EN body still present (## Hard rules)?     : YES
```

**Cross-shell symmetry — `language-policy.ps1 -Lang zh -DryRun`, EXIT=0:** identical PLAN output
(`PLAN|REWRITE-SECTION … PLAN|REWRITE-LINE … rewritten=3 conflicts=0`).

**T-014 dependency is INTACT in both shells.** The body anglicization did not break the helper's
section-extraction — the design's load-bearing OQ-3 assumption holds against execution. ✅

## Adversarial tests (REQUIRED — one falsification probe per AC, with captured evidence)

| AC | Hypothesis ("I expect failure when…") | Reproducer (NEW, QA-authored unless noted) | Outcome (with tool output) |
|---|---|---|---|
| AC-1 | the zh overlay still ships a Chinese AI-GUIDE → en/zh diff non-empty | independent overlay-layer reproducer + `diff EN zh AI-GUIDE.md` | **Survived** — `IDENTICAL AI-GUIDE.md`; `项目指南` absent; `project index` present |
| AC-2 | a deleted rule-frag/doc/type-50 leaks a Chinese marker | grep each ZH marker over the generated zh tree; diff 9 files vs EN | **Survived** — all 9 `IDENTICAL`; every ZH marker absent; `50-fullstack` EN |
| AC-3 | the splice left BOTH policy sections (double-section, R-3) | grep `## Output language (project-wide)` + count policy headings in gen 00-core | **Survived** — EN-policy heading count=0, ZH-policy count=1, body tail IDENTICAL to EN |
| AC-4 | the splice altered more than the policy line, or dropped it | `diff` gen CLAUDE/copilot vs EN render | **Survived** — exactly 1 line differs each (L3 / L6); `输出语言` count=1 each |
| AC-5 | spec/README got anglicized by collateral | grep `项目 SPEC` in gen `docs/spec/README.md` | **Survived** — present; L1 `# 项目 SPEC` |
| AC-6 | golden-tasks got anglicized by collateral | grep `轻量回归任务集` in gen `evals/golden-tasks.md` | **Survived** — present; L1 `# Golden Tasks — 轻量回归任务集` |
| AC-7 | a SPECIAL edit or deletion leaked into the EN `common/` path | `git diff` + `git diff --cached` under `templates/common/` + EN type dirs | **Survived** — both diffs EMPTY; status shows only i18n/zh `D`+`M` |
| AC-8 | the F-2 splice dropped a T-013 marker (`给用户的交付总结` / `commit message` / `全程`) | run the 4 retained T-013 assertions both shells | **Survived** — all 4 PASS both shells |
| AC-9 | the inverse assertion is VACUOUS (passes even if a deletion is reverted) | restore the pre-T-015 Chinese AI-GUIDE from `HEAD` into a throwaway overlay, run the exact assertion logic | **Survived (assertion is REAL)** — BOTH inverse checks FAIL on the reverted tree (see below) |
| AC-10 | SKILL.md still advertises translating an AI-facing file | grep SKILL.md:107-108 | **Survived** — lists the 5 remaining; AI-facing files described as NOT-in-overlay/fall-through |
| AC-11 | verify_all regresses (I.6/G.3/G.4) in one shell | run verify_all.ps1 + .sh | **Survived** — 32/32 both shells, I.6/G.3/G.4 PASS |
| AC-12 | version/count drift (skill≠14, check≠32, badge≠274) | grep plugin/marketplace/README/CHANGELOG/baseline | **Survived** — 0.26.0 ×4 sites, badge 274, skill 14, check 32, CHANGELOG `[0.26.0]` |

### AC-9 non-vacuity probe — the most important adversarial check (captured)

Hypothesis: "the new inverse assertions might pass regardless of whether the deletion happened." I recovered the
pre-T-015 Chinese AI-GUIDE from `git show HEAD:…/i18n/zh/common/AI-GUIDE.md.tmpl` (L1 `# AI-GUIDE — {{PROJECT_NAME}}
项目指南`), injected it into a throwaway overlay (simulating a reverted deletion), generated the tree, and ran the
EXACT test-init assertion logic:
```
Reverted-deletion tree: AI-GUIDE.md L1 = # AI-GUIDE — {{PROJECT_NAME}} 项目指南
  [A] PRESENT 'project index'  -> FAIL  <-- catches revert
  [B] ABSENT  '项目指南'        -> FAIL  <-- catches revert
```
**Both inverse assertions FAIL on the reverted tree.** The assertions are genuinely discriminating — not
vacuous. (Entirely in `/tmp`; the repo's deletion was never restored — confirmed `AI-GUIDE.md.tmpl: No such
file` under `i18n/zh/common/` afterward, and `git status` shows no QA residue.)

## Deletion adversarial (AC-2) — captured

```
i18n/zh file count = 5 (exactly):
  .github/copilot-instructions.md.tmpl   (SPECIAL)
  .harness/rules/00-core.md.tmpl         (SPECIAL)
  CLAUDE.md.tmpl                         (SPECIAL)
  docs/spec/README.md                    (KEEP-ZH)
  evals/golden-tasks.md.tmpl             (KEEP-ZH)
```
All 11 ANGLICIZE files gone from disk AND git (`git ls-files i18n/zh/{fullstack,backend,generic}` = empty;
type dirs absent). Each EN fall-through target confirmed present (the 9 `IDENTICAL` diffs in Probe #1 +
`50-backend`/`50-generic` EN originals on disk).

## Boundary tests covered
- **Unicode/CJK (UTF-8 no BOM):** the Chinese policy section/line/headings grep-match exactly in both shells —
  no mojibake in the generated files (terminal rendering of CJK is a display artifact; the byte-level greps PASS).
- **Single-section invariant (R-3):** count of `输出语言（按消费者分流）` = 1 and `## Output language` = 0 in gen 00-core.
- **Empty/seed-only files:** `insight-index.md` (F-6) and the type `50-*` stubs fall through cleanly (IDENTICAL).
- **Type-dir fall-through (D-obligation 6):** fullstack `50-fullstack.md` EN via independent gen; backend/generic
  EN originals present on disk + their `[AC-10] opt-out 50-*.md byte-identical` test-init assertions PASS.
- **Cross-shell symmetry (NFR-1):** every probe re-run in PS and Bash; both green. No-python3 bash path exercised.

## Regression statement
- **verify_all 32/32 both shells + test-init 274/236 both shells** = the overlay reduction broke nothing in the
  rest of the suite.
- **EN path untouched (AC-7):** `git diff` (working + staged) under `templates/common/` and EN type dirs is EMPTY.
  All three en-type fixtures (fullstack/backend/generic) and the migrate-scripts-layout group still PASS in full.
- **T-014 `/harness-language zh` intact** (Probe #2) — the cross-task dependency holds.

## Stability
- `test-init.sh` ran 3× consecutively: **236/0, 236/0, 236/0** — no flakes. The new zh assertions are pure-grep
  over a freshly-built temp tree (no timing/concurrency). ✅

## verify_all result
- Total tests (test-init): 274 (PS) / 236 (Bash no-python3) — reproduced, unchanged from baseline.
- verify_all: **32 PASS / 0 WARN / 0 FAIL** both shells.
- New tests added by QA: 0 (the 19 inverse assertions per shell were shipped by the Developer; QA independently
  verified them present, passing, and **non-vacuous**). Per the QA adversarial contract, the verdict rests on the
  independent reproducers (Probes #1/#2/AC-9), which the implementation survived.
- Baseline updated: **no** — `baseline.json` already holds the captured 274/236 (`verify_all_checks`:32), and my
  reproduced runs match exactly. No increase, no downward edit. (Baseline-only-goes-up rule respected; count
  unchanged because this task adds project-content assertions already reconciled by the Developer.)

## Defects found
None. 0 BLOCKER · 0 CRITICAL · 0 MAJOR · 0 MINOR. Nothing routed.

## Verdict
**APPROVED FOR DELIVERY (PASS).**

Every acceptance criterion AC-1..AC-12 survived an independent falsification probe with captured tool evidence.
The two headline real-behavior checks both hold: an independently-generated zh project ships AI-facing
scaffolding in English + human-facing files in Chinese (matching the declared policy), and `/harness-language zh`
(T-014) still resolves and applies the Chinese policy from the edited SPECIAL files. verify_all 32/32 and
test-init 274/236 reproduced in both shells; EN path byte-unchanged; the inverse assertions proven non-vacuous;
no flakes; clean git tree (no QA residue).
