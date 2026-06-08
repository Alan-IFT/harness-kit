# 06 — Test Report · T-013 / lang-policy-split

> Stage 6. Author: QA Tester. Adversarial verification contract enforced (`.harness/agents/qa-tester.md`).
> Every number below is from a REAL captured run on this box (Windows 11, PowerShell native + Git-bash MSYS,
> **no python3** in MSYS — confirmed). Nothing is remembered from `04_DEVELOPMENT.md`; the Dev's claims were
> independently reproduced. The #1 behavioral probe (does the policy reach a generated zh project?) and the
> #1 risk probe (I.6 CJK cross-shell mutation) were both run with captured output.

## Verdict

**PASS — APPROVED FOR DELIVERY.** 0 BLOCKER · 0 CRITICAL · 0 MAJOR · 0 MINOR (functional). 1 informational
note (pre-existing badge convention, already flagged by CR as a NIT — not a defect). Every AC-1..AC-10 has an
independent adversarial reproducer that the implementation **survived**. The mutation probe proved the
`全程~中文` I.6 banned-line is load-bearing (it FAILs verify_all when the pattern is reintroduced into a
tracked non-exempt file, and PASSes again when removed) in BOTH shells.

---

## Mandatory execution checklist — captured results (both shells)

### 1. verify_all — 32/32, 0 WARN, 0 FAIL, skill 13, version 0.24.0, I.6 PASS both shells

**Bash (MSYS), clean tree:**
```
[G.1] README references all 13 skills ... PASS
[C.1] All 13 skills present ... PASS
[G.3] Version stamps consistent across plugin/marketplace/README ... PASS
[I.6] No retired-claim phrases in current docs/templates ... PASS
[G.4] Doc count/version claims consistent with plugin.json + live check count ... PASS
=== Summary ===  PASS: 32   WARN: 0   FAIL: 0
```

**PowerShell, clean tree:**
```
[C.1] All 13 skills present with SKILL.md ... PASS
[G.3] Version stamps consistent across plugin.json / marketplace.json / README badges ... PASS
[I.6] No retired-claim phrases in current docs/templates (FAIL on resurgence) ... PASS
[G.4] Doc count/version claims consistent with plugin.json + live check count ... PASS
=== Summary ===  PASS: 32   WARN: 0   FAIL: 0
```

Version confirmed 0.24.0 at all 4 G.3 sites (captured):
```
plugin.json:        "version": "0.24.0"
marketplace.json:   "version": "0.24.0"
README.md badge:    version-0.24.0-blue ... verify__all-32%2F32 ... test--init-255%2F255
README.zh-CN.md:    version-0.24.0-blue ... verify__all-32%2F32 ... test--init-255%2F255
```
Both shells re-run GREEN (32/0/0) AFTER my `baseline.json` bump (G.4 reads `"verify_all_checks": 32` — unchanged).

> Console note: the PS `verify_all` run renders the `[A.2] 参考/` check label and the `[I.6]` reason string as
> mojibake (`�ο�/`, `ȫ��`) — this is the **OEM console codepage** rendering of CJK in stdout, NOT a
> file-content corruption. The matcher operates on .NET UTF-16 strings (proven by the mutation probe firing
> correctly); the on-disk files round-trip clean (see encoding probe).

### 2. test-verify-i6 — 58/58 both shells (14-entry banned + 4-element exempt lockstep)

**Bash:** `=== Result ===  PASS: 58  FAIL: 0`
**PowerShell:** `=== Result ===  PASS: 58  FAIL: 0`

Lockstep assertions captured (PS, identical in bash):
```
PASS  structural lockstep: verify_all.sh i6_banned entry count equals I6ExpectedEntryCount
PASS  structural lockstep: verify_all.sh i6_banned matches driver verbatim (per-entry x 4 fields)
PASS  structural lockstep: verify_all.ps1 $banned entry count equals I6ExpectedEntryCount
PASS  structural lockstep: verify_all.ps1 $banned matches driver verbatim (per-entry x 4 fields)
PASS  exempt-file lockstep: verify_all.ps1 $exempt equals canonical (element-wise)
PASS  exempt-file lockstep: verify_all.sh i6_exempt_files equals canonical (element-wise)
PASS  file-exempt predicate: docs/project-overview.html is reported exempt
PASS  combined exempt: docs/project-overview.html skipped (file-exempt)
```
`I6ExpectedEntryCount = 14` (test-verify-i6.ps1:84) / `i6_expected_entry_count=14` (test-verify-i6.sh:99).
The `全程~中文` banned entry is **byte-identical across all 4 files** (verify_all.{ps1,sh}, test-verify-i6.{ps1,sh}),
same reason string `v0.24.0 起 zh 策略按消费者分流，不再全程中文（T-013）` — captured via grep, CJK intact, no mojibake.

### 3. test-init — PS 255 / Bash 217 (matches Dev's claim); zh language assertion runs and passes

**PowerShell (`-Type all`):**
```
PASS  [zh] 00-core.md overlaid
PASS  [zh] policy lists a Chinese-artifact (consumer=human) marker
PASS  [zh] policy lists an English-artifact (consumer=agent) marker
PASS  [zh] retired blunt 全程 phrasing is absent   (console shows 'ȫ��' — codepage only; assert passed)
=== Result ===  PASS: 255  FAIL: 0
```
**Bash (default `all`, no python3):**
```
PASS  [zh] 00-core.md overlaid
PASS  [zh] policy lists a Chinese-artifact (consumer=human) marker
PASS  [zh] policy lists an English-artifact (consumer=agent) marker
PASS  [zh] retired blunt 全程 phrasing is absent   (bash terminal renders 全程 cleanly)
=== Result ===  PASS: 217  FAIL: 0
```
The new `Test-ZhOverlay` / `test_zh_overlay` block ran and all 4 assertions passed in both shells — matching
the Dev's claimed totals (255 PS / 217 Bash) exactly. (Bash arg note: the `.sh` driver takes `--type`, not a
positional; running with no args defaults to `all` and exercises the zh block.)

---

## Test plan (each AC → reproducer)

| Acceptance criterion | Independent reproducer | File / target | Result |
|---|---|---|---|
| AC-1 zh CLAUDE.md top line states split + points at 00-core | I built a real zh init fixture (common→fullstack→i18n/zh overlay) and Read the generated `CLAUDE.md:3` | generated `CLAUDE.md` | PASS |
| AC-2 zh 00-core.md two explicit ZH/EN lists matching §4 | inspected generated `.harness/rules/00-core.md` §"输出语言（按消费者分流）" | generated `00-core.md` | PASS |
| AC-3 copilot stub matches CLAUDE.md split summary | byte-compared the 输出语言 line of both generated stubs | generated `.github/copilot-instructions.md` | PASS |
| AC-4 SKILL Q5 split; no surviving "全程使用中文" | `grep 全程 skills/harness-init/SKILL.md` → 0 | SKILL.md | PASS |
| AC-5 both READMEs split; no "every AI output"/"全程中文" | `grep 'every AI output' README.md`=0; `grep 全程中文 README.zh-CN.md`=0 | both READMEs | PASS |
| AC-6 manual-e2e Q5 expectation updated | `grep` line 101 — names consumer-split, "not an 'everything Chinese' policy" | docs/manual-e2e-test.md | PASS |
| AC-7 en 00-core/CLAUDE byte-unchanged | `git diff HEAD` of the 2 EN templates = empty; generated EN project inspected | common/ templates | PASS |
| AC-8 verify_all passes; I.6 retired-claim guard added | verify_all 32/32 both shells; mutation probe proves the banned-line is live | verify_all.{ps1,sh} | PASS |
| AC-9 test-init both shells; first symmetric language assertion | test-init 255/217; Test-ZhOverlay/test_zh_overlay present + symmetric | test-init.{ps1,sh} | PASS |
| AC-10 CHANGELOG entry + version bump; G.3/G.4 green | `[0.24.0] - 2026-06-08` present, no orphan [Unreleased]; G.3/G.4 PASS | CHANGELOG, manifests, badges | PASS |

## Boundary / encoding tests added & exercised

- **CJK round-trip** of the generated zh `00-core.md`: `od -An -tx1` of the `给用户的交付总结` marker matches the
  raw UTF-8 bytes (`e7 bb 99 e7 94 a8 e6 88 b7 e7 9a 84 e4 ba a4 e4 bb 98 e6 80 bb e7 bb 93`) exactly.
- **No replacement char**: zero contiguous `ef bf bd` (U+FFFD) bytes in the generated file; no UTF-8 BOM
  (first bytes `23 20 71` = `# q`).
- **No-python3 Bash path**: MSYS has no python3 (`python3` absent) — the zh-overlay assertions are pure greps
  and run unconditionally; confirmed they execute and pass without python3.
- **I.6 self-trip boundary**: the test-init scripts carry the bare `全程` literal alone (no `中文` on the same
  line) → correctly NOT exempt and do NOT trip the `全程~中文` banned-line.

## Adversarial tests (REQUIRED — one+ predicted-failure probe per AC, independent reproducers)

> For every AC I wrote down "I expect this to FAIL because …", built a reproducer **from the AC, not from the
> Dev's test code**, ran it, and recorded whether the implementation survived. All reproducers are independent
> (my own zh/en fixtures, my own git-tracked mutation file, direct file inspection).

| AC | Hypothesis ("I expect failure when…") | Reproducer (NEW, I wrote this) | Outcome (captured) |
|---|---|---|---|
| **AC-2 / AC-9** (#1 behavioral) | the split exists only in the `.tmpl`, not in a really-generated project; the overlay drops or mojibakes the policy | Drove a real `{{LANG}}=zh` init (common→fullstack→**i18n/zh/common** overlay, SKILL §4.3 order) into a throwaway temp dir with my own `copy_layer`+`sed` substitution; Read the generated `.harness/rules/00-core.md` | **Survived.** Generated file carries `## 输出语言（按消费者分流）`, the two explicit lists `**用中文（消费者是人）：**` and `**用英文（消费者是下游 agent / LLM）：**`, ZH marker `给用户的交付总结` and EN marker `commit message` both present, **zero `全程`**. Policy reaches the user, not just the template. |
| **AC-1** | the generated CLAUDE.md still carries the blunt standalone `输出语言：**中文**。` | grep generated `CLAUDE.md:3` for the blunt line; grep for the split summary | **Survived.** Line 3 = the split summary pointing at `00-core.md`; blunt standalone line **gone** (grep for `输出语言：**中文**。$` → 0). |
| **AC-3** | the copilot stub drifted from CLAUDE.md (asymmetric) | bash byte-compare of the 输出语言 line from both generated stubs (`[[ "$a" == "$b" ]]`) | **Survived.** IDENTICAL split summary; no `全程` in either stub. |
| **AC-4** | a surviving `全程使用中文` sentence elsewhere in SKILL.md | `grep -n 全程 skills/harness-init/SKILL.md` | **Survived.** 0 hits. |
| **AC-5** | a surviving blunt claim in either README | `grep 'every AI output' README.md`; `grep 全程中文 README.zh-CN.md`; tree-wide `git grep` excluding exempt areas for `全程中文 / 全程使用中文 / every AI output / AI 全程` | **Survived.** 0 non-exempt survivors of every variant. |
| **AC-6** | manual-e2e still positively asserts the old "everything Chinese" policy | `grep` line 101 + `grep 'everything in Chinese\|全程' docs/manual-e2e-test.md` | **Survived.** Line 101 states consumer-split; "everything Chinese" appears only as an explicit negation; no positive blunt claim. |
| **AC-7** (en untouched) | the en templates were touched, or zh/split phrasing leaked into the en path | `git diff HEAD` of the 2 EN templates (expect empty); generated a real `{{LANG}}=en` project and inspected its 00-core + CLAUDE.md for CJK/split phrasing | **Survived.** EN diff EMPTY (byte-unchanged); generated EN 00-core = `**Everything this project's AI produces must be in English.**` (single language, no split); `Output language: **English**.`; no CJK, no split phrasing. |
| **AC-8** (#1 risk) | the `全程~中文` banned-line is dead/cosmetic — reintroducing the retired phrasing would NOT be caught | **MUTATION:** wrote a tracked scratch file `qa-i6-mutation-probe.md` containing `本项目全程中文输出测试。`, `git add`ed it (tracked → scanned, non-exempt), ran verify_all I.6 in BOTH shells; then removed + re-ran | **Survived — banned-line is LOAD-BEARING.** With mutation: **bash I.6 FAIL** `qa-i6-mutation-probe.md:3 : [全程~中文] … matched: "全程中文"` → 31 PASS / 1 FAIL; **PS I.6 FAIL** same file → 31 PASS / 1 FAIL. After removal: I.6 PASS, 32/0/0 both shells, `git status` pristine. |
| **AC-8** (exemption load-bearing) | the exemption is vacuous (project-overview.html doesn't actually contain the banned phrase) | `grep 全程中文 docs/project-overview.html`; confirm tracked; confirm in exempt list both shells | **Survived.** `:314` contains `中文项目全程中文` (gap 0); file IS tracked; IS exempt in both shells. Combined with the mutation probe (matcher fires on a non-exempt tracked file with the identical pattern), this proves I.6 passes only **because** of the exemption, not a broken matcher. The frozen v0.17.0 snapshot is honestly preserved (not rewritten). |
| **AC-9** | the zh language assertion doesn't actually run, or self-trips I.6, or the CJK literal mangles on save | confirmed `Test-ZhOverlay`(ps:610)/`test_zh_overlay`(sh:514) fire (captured 4 PASS lines each shell); checked no test-init line has `全程`+`中文` together | **Survived.** Assertions run + pass in both shells; bare `全程` alone on the absence-assert line → no self-trip; scripts correctly NOT in exempt list; verify_all stays 32/32. |
| **AC-10** | an orphan `[Unreleased]`, a duplicate `[0.24.0]`, or a version-site missed | grep CHANGELOG for `[0.24.0]`, `[Unreleased]`, count `[0.24.0]`; grep 4 version sites; G.3/G.4 from verify_all | **Survived.** `[0.24.0] - 2026-06-08` present (1×), **no orphan [Unreleased]**, holds BOTH T-013 lang-split AND ambient-stream T-011 bullets; 0.24.0 at all 4 G.3 sites; G.3 + G.4 PASS both shells. |

### Mutation-probe captured output (the load-bearing evidence)

Bash, mutation present:
```
[I.6] No retired-claim phrases in current docs/templates ... FAIL
      Retired-claim phrases found in live files:
qa-i6-mutation-probe.md:3 : [全程~中文] — v0.24.0 起 zh 策略按消费者分流，不再全程中文（T-013） | matched: "全程中文"
  PASS: 31   WARN: 0   FAIL: 1
```
PowerShell, mutation present (CJK label is codepage mojibake; the match still fired):
```
[I.6] No retired-claim phrases in current docs/templates (FAIL on resurgence) ... FAIL
qa-i6-mutation-probe.md:3 : [ȫ��~����] … matched: "ȫ������"
  PASS: 31   WARN: 0   FAIL: 1
```
Both shells, mutation removed:
```
[I.6] No retired-claim phrases in current docs/templates ... PASS
  PASS: 32   WARN: 0   FAIL: 0
```
`git status --porcelain` after removal = the original 17-path T-013 changeset, **no QA residue**.

### Encoding round-trip captured output (generated zh 00-core.md)

```
raw bytes 给用户的交付总结 : e7 bb 99 e7 94 a8 e6 88 b7 e7 9a 84 e4 ba a4 e4 bb 98 e6 80 bb e7 bb 93
stored bytes (after "- "): 2d 20 e7 bb 99 e7 94 a8 e6 88 b7 e7 9a 84 e4 ba a4 e4 bb 98 e6 80 bb e7 bb 93  ✅ identical
U+FFFD (efbfbd) contiguous in file : NONE -> clean
BOM (first 3 bytes) : 23 20 71  (= "# q", no UTF-8 BOM)
```

## verify_all result

- Total checks: 32 → 32 (no new check; I.6 banned-entry rides inside the existing I.6 Step, exemption rides inside existing arrays).
- Pass: 32 · Fail: 0 · Warn: 0 — **both shells** (PowerShell native + Git-bash MSYS).
- Tests added by Dev (T-013), independently reproduced: test-init +4/shell (251→255 PS, 213→217 Bash);
  test-verify-i6 +2/shell (56→58 both). QA added **no new test files** — the Dev's `test_zh_overlay`/`Test-ZhOverlay`
  + the I.6 lockstep already encode the ACs; I verified them with independent reproducers per the adversarial contract.
- Baseline updated: **yes** — `.harness/scripts/baseline.json` bumped (only upward): `test_init_ps_assertions`
  251→255, `test_init_bash_no_python3_assertions` 213→217, `test_verify_i6_ps_assertions` 56→58,
  `test_verify_i6_bash_assertions` 56→58, `last_verify` → 2026-06-08. `verify_all_checks` left at 32.
  verify_all re-run GREEN both shells after the bump (G.4 reads `verify_all_checks`, unchanged).

## Regression guard

verify_all (32/32/0), test-init (255/217), and test-verify-i6 (58/58) all GREEN in **both** shells over the
final tree — the template/script/manifest/doc edits did not break any pre-existing check. EN path is provably
byte-unchanged (AC-7 `git diff` empty). No verify_all Step added/removed; skill count 13; check count 32.

## Defects found

None requiring routing. (No BLOCKER / CRITICAL / MAJOR / MINOR functional defect.)

Informational only (NOT a defect — already noted by CR as a NIT, pre-existing convention, not G-gated):
- The `test--init-255%2F255` badge on both READMEs encodes the PowerShell total (255) on both sides while the
  true Bash total is 217 (the README line-162 prose states both correctly: "255 … on PowerShell; 217 on Bash").
  This is the long-standing badge convention (the prior `227/227` did the same) and is informational, not
  gated by G.3/G.4. No routing needed; awareness only.

## Stability

- `test-verify-i6` (the CJK cross-shell hot path) ran **3× per shell** — 58/58 every time, no flakes.
- `verify_all` ran **4×** total across the mutation cycle + final — deterministic (32/0/0 clean, 31/1 with
  mutation, 32/0/0 after removal).
- `test-init` ran once per shell (255/217); assertions are deterministic pure greps over a freshly-built
  fixture; combined with the 58/58 CJK-matcher stability this is not a flaky surface.
- Transient false alarm noted by Dev (a mid-edit MSYS `bash verify_all.sh` re-reading shifting line offsets):
  **not reproduced** — every QA run was over the static final tree and returned clean.

## Verdict

**APPROVED FOR DELIVERY.**

All AC-1..AC-10 survived independent adversarial reproducers; the #1 behavioral probe (policy lands in a real
generated zh project, byte-clean) and the #1 risk probe (I.6 `全程~中文` mutation FAIL→remove→PASS, both shells)
both confirm the implementation. verify_all 32/32/0, test-verify-i6 58/58, test-init 255/217 — all GREEN in
PowerShell and Git-bash MSYS. Baseline bumped upward and re-verified green. `git status` for tracked files is
pristine (only the intended T-013 changeset; the QA mutation file and temp fixtures were removed).
