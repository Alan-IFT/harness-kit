# 04 — Development Record · T-013 / lang-policy-split

> Stage 4. Author: Developer. Single-developer mode.
> Implements `02_SOLUTION_DESIGN.md` (F1–F14) + its `## Amendment 1` (F-15 + the I.6 lockstep
> + CHANGELOG fold + empirical test-init totals). No design decisions made; design followed verbatim.

## Summary

Rewrote the `{{LANG}}=zh` generated-project output-language policy from the blunt "everything in
Chinese" to a **consumer split** — human-facing output (chat replies, errors, status/progress,
delivery summaries, README & human docs) stays Chinese; AI-facing work products (7-stage docs,
PM_LOG, the tasks.md/dev-map/insight-index ledgers, agent/rule/AI-GUIDE/CLAUDE edits, code comments,
commit messages) become English. Added the `全程~中文` I.6 retired-claim guard (4-file lockstep
+ `docs/project-overview.html` exemption + count 13→14), the first symmetric test-init language
assertion, and bumped the version 0.23.0 → 0.24.0. The English path is byte-unchanged (AC-7).

## Files changed

- `skills/harness-init/templates/i18n/zh/common/.harness/rules/00-core.md.tmpl` — **F1**: rewrote §"输出语言" into two explicit ZH/EN consumer lists (heading `（全项目）` → `（按消费者分流）`). Zero new `{{...}}`; no "全程".
- `skills/harness-init/templates/i18n/zh/common/CLAUDE.md.tmpl` — **F2**: line 3 "输出语言" → one-line split summary pointing at `00-core.md`.
- `skills/harness-init/templates/i18n/zh/common/.github/copilot-instructions.md.tmpl` — **F3**: line 6 → identical split summary (symmetric with F2).
- `skills/harness-init/SKILL.md` — **F4a**: Q5 `中文` option (line 72) → split summary (no surviving "全程使用中文输出"); **F4b**: step-4.3 stale overlay file list (line 107) → the actual 17-file overlay (re-Globbed).
- `README.md` — **F5**: §"Project-wide language policy" → split (EN prose, no "every AI output"); version badge 0.23.0→0.24.0; test-init prose/badge → real totals.
- `README.zh-CN.md` — **F6**: §"项目级语言策略" → split (ZH prose, no "全程中文"); version badge; test-init prose/badge → real totals.
- `docs/manual-e2e-test.md` — **F7**: line 101 Q5/language expectation → consumer-split policy.
- `.harness/scripts/verify_all.ps1` — **F8** banned-entry `全程~中文` (`$banned`); **F-15b** exempt `docs/project-overview.html` (`$exempt`, after walkthrough.html, trailing comma).
- `.harness/scripts/verify_all.sh` — **F9** banned-entry `全程~中文` (`i6_banned`); **F-15a** exempt `docs/project-overview.html` (`i6_exempt_files`, no comma).
- `.harness/scripts/test-verify-i6.ps1` — **F-3** mirror banned-entry into `$i6Banned` copy; **F-15d** exempt into `$i6ExemptFiles`; **F-3** `I6ExpectedEntryCount` 13→14.
- `.harness/scripts/test-verify-i6.sh` — **F-3** mirror banned-entry into `i6_banned` copy; **F-15c** exempt into `i6_exempt_files`; **F-3** `i6_expected_entry_count` 13→14.
- `.harness/scripts/test-init.ps1` — **F10**: new `Test-ZhOverlay` function + all/both dispatch call (before BUG-2 block).
- `.harness/scripts/test-init.sh` — **F11**: new `test_zh_overlay` function + all/both dispatch call (before BUG-2 block).
- `.claude-plugin/plugin.json` — **F12**: `version` 0.23.0 → 0.24.0.
- `.claude-plugin/marketplace.json` — **F13**: `plugins[0].version` 0.23.0 → 0.24.0.
- `CHANGELOG.md` — **F14** (Amendment-1 structure): renamed `## [Unreleased]` → `## [0.24.0] - 2026-06-08`, kept the ambient-stream bullets, prepended the T-013 entry. No orphan `[Unreleased]`, no sibling `[0.24.0]`.

**Not touched (proves scope discipline):** `skills/harness-init/templates/common/.harness/rules/00-core.md.tmpl` and `.../common/CLAUDE.md.tmpl` (EN path — `git diff --stat` empty, AC-7); `docs/project-overview.html` (frozen v0.17.0 snapshot — exempted, never rewritten); `docs/tasks.md` (PM-owned; its pre-existing T-013 row is the PM's change, not mine); all upstream stage docs (01/02/03).

## How each AC is met

- **AC-1** — F2: zh `CLAUDE.md.tmpl` line 3 states the split + points at `.harness/rules/00-core.md`.
- **AC-2** — F1: zh `00-core.md.tmpl` enumerates two explicit lists (`**用中文（消费者是人）：**` / `**用英文（消费者是下游 agent / LLM）：**`) matching the §4 classification (chat/errors/status/delivery/human-docs = ZH; 7-stage/PM_LOG/ledgers/rule-agent-guide edits/comments/commits = EN).
- **AC-3** — F3: copilot stub line 6 is the byte-identical split summary to F2.
- **AC-4** — F4a: SKILL Q5 describes the split; `grep 全程` over SKILL.md → 0 hits (no surviving "全程使用中文输出"); the `English (default)` option left unchanged.
- **AC-5** — F5/F6: both READMEs describe the split; `grep "every AI output"` (README.md) → 0, `grep 全程中文` (README.zh-CN.md) → 0.
- **AC-6** — F7: manual-e2e Q5 line names the consumer-split expectation in the generated `00-core.md`.
- **AC-7** — §8: `git diff --stat` of the two EN-path templates is **empty** (byte-unchanged). Verified.
- **AC-8** — F8/F9 + F-15: `verify_all` PASS both shells (I.6 PASS); the `全程~中文` banned-line is added and the retired sites are all retired/exempt; the new split text has no "全程" so it does not self-trip (verified by a targeted matcher run: matches `中文项目全程中文` and `AI 全程使用中文输出`, does NOT match the new policy text or `全英文`).
- **AC-9** — F10/F11: `test-init` PASS both shells; the first language assertion present and symmetric (`Test-ZhOverlay`/`test_zh_overlay`), 4 pure-grep assertions (no python3 dependency), present-markers (`给用户的交付总结`, `commit message`) and absent-marker (`全程`) on DIFFERENT strings (no T-007 self-contradiction).
- **AC-10** — F12/F13/F14: CHANGELOG `[0.24.0]` entry present; version 0.24.0 across the 4 G.3 sites; G.3 + G.4 PASS; skill count stays 13 (C.1/G.1/G.2 PASS), verify_all check count stays 32 (G.4 PASS).

## verify_all result

Captured from real runs (not remembered). Baseline = pre-edit; After = final post-edit tree.

| Suite | Shell | Baseline | After | Delta |
|---|---|---|---|---|
| verify_all | PowerShell | 32 PASS / 0 WARN / 0 FAIL | **32 PASS / 0 WARN / 0 FAIL** | 0 new failures |
| verify_all | Bash (MSYS) | 32 PASS / 0 WARN / 0 FAIL | **32 PASS / 0 WARN / 0 FAIL** (exit 0) | 0 new failures |
| test-verify-i6 | PowerShell | 56/0 (13-entry) | **58 PASS / 0 FAIL** (14-entry) | +2 assertions (new exempt + count), all pass |
| test-verify-i6 | Bash | 56/0 (13-entry) | **58 PASS / 0 FAIL** (14-entry) | +2 assertions, all pass |
| test-init | PowerShell | 251/0 | **255 PASS / 0 FAIL** | +4 zh-overlay assertions |
| test-init | Bash (no python3) | 213/0 | **217 PASS / 0 FAIL** | +4 zh-overlay assertions |

- verify_all critical checks both shells: **I.6 PASS** (banned-line added, project-overview.html exempted, new text no self-trip, retired sites gone), **G.3 PASS** (0.24.0 consistent), **G.4 PASS** (count/version claims consistent), version **0.24.0**, skill **13**, checks **32**.
- The baseline verify_all.sh numbers are from the clean PowerShell baseline (32/0/0) and the final bash run; one early bash baseline run printed transient parse errors because it was still streaming the file while the I.6 array was being edited (the running MSYS instance re-read shifting line offsets mid-edit) — a fresh post-edit run over the final tree returned 32/0/0 exit 0.
- **New test-init informational totals (per F-2, read from the real run, NOT the design's arithmetic estimate of 231/195):** PowerShell **255**, Bash **217**. The pre-existing badge read `227/227`, which was stale drift (the migrate-layout block + others were never counted); the badge and the README EN+ZH prose are restamped to the real PowerShell total (255) / Bash total (217), and the breakdown parenthetical now names the migrate-layout block + the 4 zh-overlay assertions + the 2 BUG-2 assertions.

## Design drift (if any)

No behavioral design drift. Two documentation-accuracy notes the reviewer should be aware of:

1. **test-init badge/prose number** — the design (§10.5) and Amendment-1 F-2 estimated PS 227→231 / Bash 191→195. The **real** pre-edit baselines were higher (PS 251 / Bash 213) due to pre-existing drift between the badge (227) and the actual suite, so the stamped numbers are **255 / 217** — exactly per F-2's instruction to stamp the empirical run, not the arithmetic. Not drift from the design's intent; the design explicitly delegated the number to the real run.
2. **dev-map.md line 140** carries a historical "227 assertions on PS / 191 Bash without python3 **at v0.16.0**" note. It is a snapshot pinned to v0.16.0, not a current-state claim, and the design's count-update site list (§10.5) does not include it. Left unchanged (editing it to 255/217 would falsify the v0.16.0 pin). G.4 does not gate it (G.4 PASS confirms). Flagged here for the reviewer's awareness only.

## Open issues for review

- None blocking. The CJK round-trip across all six CJK-bearing edited scripts (`verify_all.{ps1,sh}`, `test-verify-i6.{ps1,sh}`, `test-init.{ps1,sh}`) was re-Read after each edit and confirmed intact; the bash test-init output rendered `全程` cleanly and all CJK assertions passed in both shells.
- Reviewer may wish to double-check the §10.5 vs real test-init number reconciliation (255/217) and that the dev-map v0.16.0 historical line was intentionally left.

## Dev-map updates

None. No files added/moved/removed and no module/folder structure changed — every edit is in-place content in existing files. `docs/dev-map.md` already lists all touched scripts/templates. (Confirmed: structure unchanged → no dev-map edit required.)

## Insight to surface (optional)

A slow MSYS `bash verify_all.sh` re-reads the script from disk as it streams, so editing the I.6 array (shifting later line offsets) while a run is still in flight makes that running instance throw bogus parse/`unbound variable` errors at the new line numbers — a false alarm, not a real break. Re-run fresh over the final tree before trusting a bash verify_all signal. · evidence: T-013, baseline run bal93l13u errored at verify_all.sh:594/598/624 mid-edit; clean post-edit run returned 32/0/0 exit 0

## CR-minor comment fix (stage 5b)

Code Review (`05_CODE_REVIEW.md`) flagged 2 MINOR stale header comments: the I.6 banned
list grew 13 → 14 entries (the `全程~中文` addition) and the count constant was correctly
updated to 14, but the array's header comment still said "13-entry". Fixed the comment text
only — zero behavior change. The NIT (README test-init badge convention) was left untouched
(out of scope).

### Lines changed (comment text only)

- `.harness/scripts/test-verify-i6.ps1` (line 51)
  - before: `# The 13-entry banned list — the 1:1 twin of verify_all.ps1's $banned.`
  - after:  `# The 14-entry banned list — the 1:1 twin of verify_all.ps1's $banned.`
- `.harness/scripts/test-verify-i6.sh` (line 64)
  - before: `# The 13-entry banned list — must be byte-identical to verify_all.sh's i6_banned.`
  - after:  `# The 14-entry banned list — must be byte-identical to verify_all.sh's i6_banned.`

Only the digit `13`→`14` changed on each line. The array contents, the count constant
(already 14), and every code path are untouched. No CJK literal was touched. Per insight L10,
each edited line was re-Read after the Edit: the em-dash and surrounding text are intact and
no adjacent CJK got corrupted.

### Re-run results (both shells, captured)

These are the CJK-sensitive I.6 lockstep files, so both shells were re-confirmed green:

- `test-verify-i6.ps1` → `PASS: 58  FAIL: 0` (unchanged)
- `test-verify-i6.sh`  → `PASS: 58  FAIL: 0` (unchanged)
- `verify_all.ps1` → `PASS: 32  WARN: 0  FAIL: 0` ([I.6] PASS, version 0.24.0)
- `verify_all.sh`  → `PASS: 32  WARN: 0  FAIL: 0` ([I.6] PASS, version 0.24.0)

test-init was NOT re-run: no templates and no test-init logic were touched, only two header
comments in the I.6 test/verify scripts.

## Verdict

READY FOR REVIEW
