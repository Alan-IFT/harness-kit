# 06 — Test Report · T-014 / harness-language-skill

> Stage 6. QA Tester. Adversarial verification by RUNNING in BOTH shells (PowerShell 7.6
> native + Git-bash MSYS 5.2). Every number below is captured live this pass — none are
> carried over from `04_DEVELOPMENT.md`. The Dev claimed `pwsh` was deny-blocked in their
> session; in THIS session `pwsh` runs, so the PS twin (which the Dev could not capture) is
> reproduced here from scratch.

## Verdict: PASS — APPROVED FOR DELIVERY

0 defects. All 13 ACs survived independent adversarial reproducers in both shells. The #1
residual risk (cross-shell END-STATE byte parity, T-012 DEFECT-1 class) holds for BOTH
switch directions. `verify_all` 32/32/0 both shells; `test-language` 39/39 both shells;
`test-init` unbroken (255 PS / 217 bash-no-python3). Baseline bumped (test-language added,
additive) and verify_all re-run green after.

---

## Environment

- bash: GNU bash 5.2.37 (x86_64-pc-msys), GNU Awk 5.3.2.
- pwsh: PowerShell 7.6.0 (runs fine this session — the Dev's deny-block did not apply here).
- python3: a non-functional Windows-Store stub (`Python was not found…`) → the bash
  `test-init` path correctly hits its no-python3 branch (AI-native blocks SKIPped) → 217,
  matching the baseline's `test_init_bash_no_python3_assertions`.

---

## 1. Mandatory checklist — captured results (BOTH shells)

### 1.1 `verify_all` — 32 / 0 / 0 both shells, skill 14, version 0.25.0, I.6 PASS

bash `verify_all.sh` (exit 0):
```
[C.1] All 14 skills present ... PASS
[G.1] README references all 14 skills ... PASS
[G.2] CHANGELOG references all 14 skills ... PASS
[G.3] Version stamps consistent across plugin/marketplace/README ... PASS
[I.6] No retired-claim phrases in current docs/templates ... PASS
[J.1] settings.json schema integrity (.claude/ + template) ... PASS
[G.4] Doc count/version claims consistent with plugin.json + live check count ... PASS
=== Summary ===  PASS: 32  WARN: 0  FAIL: 0
```

pwsh `verify_all.ps1` (exit 0):
```
[F.1] verify_all, sync-self, harness-sync, test-init, test-real-project, ambient-prompt,
      ambient-reset, upgrade-project, language-policy exist in both .ps1 and .sh ... PASS
[G.1] README references all 14 skills ... PASS
[G.2] CHANGELOG mentions all 14 skills ... PASS
[G.3] Version stamps consistent across plugin.json / marketplace.json / README badges ... PASS
[I.6] No retired-claim phrases in current docs/templates (FAIL on resurgence) ... PASS
[G.4] Doc count/version claims consistent with plugin.json + live check count ... PASS
=== Summary ===  PASS: 32  WARN: 0  FAIL: 0
```
F.1 lists `language-policy` (the new helper pair, name-only); check count held at 32.

### 1.2 `test-language` — 39 / 0 both shells (incl. byte-identical round-trip #9)

bash `test-language.sh` (exit 0): `PASS: 39  FAIL: 0`. The three round-trip asserts:
```
[PASS] 9: 00-core byte-identical after round-trip (§5.4)
[PASS] 9: CLAUDE.md byte-identical after round-trip (§5.4)
[PASS] 9: copilot byte-identical after round-trip (§5.4)
```
pwsh `test-language.ps1` (exit 0): `PASS: 39  FAIL: 0`, same three round-trip asserts PASS.

### 1.3 `test-init` — NOT broken by the new template helper

- pwsh `test-init.ps1`: `PASS: 255  FAIL: 0` (exit 0).
- bash `test-init.sh`: `PASS: 217  FAIL: 0` (exit 0) — AI-native blocks SKIPped (no python3).

Both match the baseline exactly → the new `templates/common/.harness/scripts/language-policy.*`
file did not disturb the init scaffold.

### 1.4 `sync-self --check` — In sync (E.1 byte-identity of the new pair)

- bash `sync-self.sh --check` → `In sync.` (exit 0).
- pwsh `sync-self.ps1 -Check` → `In sync.` (exit 0).

The dogfood `.harness/scripts/language-policy.{ps1,sh}` mirror is byte-identical to its
template source (Mapping 8 / mirror set 6→7), and verify_all E.1 PASSes.

---

## 2. Cross-shell END-STATE byte parity (the #1 residual risk — CR §"Residual risk for QA" item 1)

**Method (independent reproducer, NOT the dev's test):** hand-built a realistic en-project
fixture (`00-core.md` with the canonical en policy heading + an unrelated `## SENTINEL
SECTION` + `## How this project is developed`; `CLAUDE.md`; `.github/copilot-instructions.md`
with YAML frontmatter). Made two byte-identical clean copies (same sha256). Ran the **bash**
helper on one and the **pwsh** helper on the other, then `cmp` the three result files ACROSS
the two shells. Repeated for the reverse direction with a zh-project fixture seeded from the
real zh templates.

### zh direction (en-project → `--lang zh`)
Both shells emit the identical stdout contract (`DETECT|en|00-core`, 3× `REWRITE-…`, 3 `BAK`,
`SUMMARY|rewritten=3 noop=0 skipped=0 baks=3 conflicts=0`, exit 0). Cross-shell `cmp`:
```
BYTE-IDENTICAL: .harness/rules/00-core.md   sha fed9b597…c8cd (both shells)
BYTE-IDENTICAL: CLAUDE.md                   sha 46046d7e…fc52 (both shells)
BYTE-IDENTICAL: .github/copilot-instructions.md  sha 89ebf380…84a8 (both shells)
overall zh parity: PASS
```

### en direction (zh-project → `--lang en`)
Both shells: `DETECT|zh|00-core`, 3× REWRITE, exit 0. Cross-shell `cmp`:
```
BYTE-IDENTICAL: .harness/rules/00-core.md
BYTE-IDENTICAL: CLAUDE.md
BYTE-IDENTICAL: .github/copilot-instructions.md
en parity overall: PASS
```

### CRLF-input variant (parity under a CRLF target)
Built a CRLF en-project, ran zh in each shell: outputs are byte-identical across shells AND
contain **0** CR bytes (0x0d) — CRLF normalizes to LF identically in both shells (authoritative
`od -An -tx1 | grep -c '^0d'` = 0 for both).

**Result: the #1 risk is CLEARED.** Bash-produced and PS-produced end states are byte-identical
for all three files in both switch directions and under CRLF input. (This is the property test
#9 does NOT assert — #9 is within-shell. This report adds the cross-shell assertion the CR
flagged as "claimed, not auto-asserted".)

---

## 3. Test plan (AC → reproducer)

| AC | Reproducer (independent, RUN this pass) | File / fixture |
|---|---|---|
| AC-1 zh→en switch | hand-built zh fixture → `--lang en`, content + cross-shell cmp | §2 en dir, §4 |
| AC-2 idempotence | 2nd `--lang zh` on now-zh proj, both shells | §4 |
| AC-3 en→zh switch | hand-built en fixture → `--lang zh`, content + cmp | §2 zh dir, §4 |
| AC-4 no-arg detect | `--lang <ph> --dry-run` on en & zh & CLAUDE-only fixtures | §4 |
| AC-5 surgical scope | sentinel + sibling sections + exact diff confinement | §4 |
| AC-6 single section | heading counts (old gone, new=1) | §4 |
| AC-7 conflict | hand-mangled heading → CONFLICT exit 2 → `--force` insert | §4 |
| AC-8 missing surface | en proj sans copilot → SKIP, exit 0 | §4 |
| AC-9 gates | helper neither-surface exit 1; bad-arg exit 1; SKILL git/clean prose | §4 + VERIFIED-BY-SPEC |
| AC-10 self-bootstrap | stale-body project → applied == template slice (not own text) | §4 |
| AC-11 upgrade hint | exactly 1 `/harness-language` line in harness-upgrade SKILL.md | §4 |
| AC-12 gate + fan-out | verify_all 32/32 both shells, version/count/six-shapes sweep | §1, §5 |
| AC-13 no placeholder | no `{{...}}` literal in helper/test; D.2 PASS unchanged | §4 |

## Boundary tests added / exercised
- Null/absent surfaces: 00-core absent (DETECT falls back to CLAUDE), copilot absent (SKIP),
  neither 00-core nor CLAUDE (exit 1).
- Invalid argument: `--lang fr` (bash exit 1 actionable; PS ValidateSet bind-reject exit 1).
- Missing `--template-root` → exit 1.
- CJK/encoding: zh three-way text round-trips with no mojibake; 0 CR bytes on output.
- CRLF input normalization (cross-shell identical).
- Hand-mangled heading (conflict path) + `--force` insert.

---

## 4. Adversarial tests (REQUIRED — one falsification probe per AC, with captured evidence)

Each row states the failure hypothesis BEFORE running, then the outcome. Verdict is "did the
implementation SURVIVE", not "did the dev's test pass".

| AC | Hypothesis ("I expect failure when…") | Reproducer (NEW, I wrote it) | Outcome |
|---|---|---|---|
| AC-1 | zh→en leaves a stray zh heading or loses the zh sibling section | bash + pwsh `--lang en` on zh fixture | **Survived** — en heading=1, zh heading=0, single-language en body present, `## 这个项目怎么开发` sibling preserved, en CLAUDE line present |
| AC-2 | 2nd identical run rewrites due to a trailing-newline mismatch, writes a new .bak | re-run `--lang zh` on now-zh proj, both shells | **Survived** — all 3 `NOOP`, `baks=0`, sha unchanged, no new .bak (both shells) |
| AC-3 | en→zh installs the section but mangles the trailing blank line | bash + pwsh `--lang zh` on en fixture | **Survived** — zh heading + human-side + agent-side markers present, exactly one heading |
| AC-4 | DETECT mis-reports the current language; or dry-run still writes | `--lang <ph> --dry-run` on en, zh, and 00-core-absent fixtures | **Survived** — `DETECT|en\|00-core`, `DETECT|zh\|00-core`, `DETECT|zh\|CLAUDE` (fallback); 0 file changes, 0 .bak |
| AC-5 | the section replace spills outside [heading, next "##") and eats a neighbouring line | inserted `SENTINEL-UNIQUE-MARKER-12345` in a sibling section; `diff` seed vs result | **Survived** — `diff` confined to lines 5–10 (the policy section only); sentinel + intro + dev section byte-unchanged; the other CLAUDE line preserved |
| AC-6 | both an old and a new policy heading remain after a switch | grep both canonical headings post-switch | **Survived** — exactly one heading (en=0/zh=1 after zh; en=1/zh=0 after en) |
| AC-7 | a hand-mangled heading silently corrupts the file or auto-inserts | typo'd heading, `--lang en` no `--force` | **Survived** — `CONFLICT\|section`, exit 2, 00-core sha unchanged; `--force` → INSERT-SECTION exit 0, mangled section preserved |
| AC-8 | a missing copilot file is treated as an error (non-zero exit) | en proj without `.github/copilot-instructions.md`, `--lang zh` | **Survived** — `SKIP\|.github/copilot-instructions.md\|absent`, 00-core+CLAUDE rewritten, exit 0 |
| AC-9 | the helper proceeds with no policy surface, or an invalid lang | neither 00-core nor CLAUDE; `--lang fr`; no `--template-root` | **Survived** — exit 1 with actionable stderr in each case; SKILL git-repo/clean-tree gates VERIFIED-BY-SPEC (skill-layer, no live git tree to mutate) |
| AC-10 | the helper echoes the project's OWN stale text back instead of the template's | stale-body zh fixture → `--lang zh`; compare applied section to template slice | **Survived** — stale body gone; applied 00-core section byte-EQUALS the template slice; canonical tie-break sentence present |
| AC-11 | zero or duplicate upgrade hints | `grep -c harness-language skills/harness-upgrade/SKILL.md` | **Survived** — exactly 1 hint line (no auto-invocation) |
| AC-12 | a stale 13/thirteen or 0.24.0 left somewhere; or six-shapes bumped | live-tree sweep | **Survived** — 14/fourteen/14个 everywhere, 0 stale 13/thirteen/0.24.0 in live docs, "six task shapes"/"6 种任务形态" unchanged, "32 checks" untouched |
| AC-13 | a new `{{...}}` placeholder slipped into the helper → D.2 churn | grep `{{` in helper/test/skill | **Survived** — 0 `{{...}}` in helper/test; the only hit (SKILL.md:212) is prose naming what is OUT of scope; D.2 PASS unchanged |

### Evidence excerpts (selected)

AC-4 DETECT fallback (00-core absent, CLAUDE zh line present):
```
LANG|en
DETECT|zh|CLAUDE
PLAN|SKIP|.harness/rules/00-core.md|absent
PLAN|REWRITE-LINE|CLAUDE.md|to en
```

AC-5 surgical diff (en seed vs zh result, 00-core) — changes confined to the policy section:
```
5c5  ## Output language (project-wide)  →  ## 输出语言（按消费者分流）
7c7  (old en body)                       →  (canonical zh body)
9,10c9,27  - stale bullet a/b            →  (canonical zh consumer-split list)
```
Lines 1–4 and everything from `## SENTINEL SECTION` onward: NOT in the diff (untouched).

AC-7 conflict then `--force`:
```
CONFLICT|section|.harness/rules/00-core.md|no recognizable policy heading   (exit 2, unchanged)
… --force …
RESULT|INSERT-SECTION|.harness/rules/00-core.md|to en   (exit 0; mangled heading preserved)
```

AC-10 self-bootstrap: `applied section == template section (PASS)` — the applied 00-core
policy slice is byte-equal to `i18n/zh/.../00-core.md.tmpl` lines 9–32, not the project's
stale body.

---

## 5. Fan-out verification (AC-12)

- Version **0.25.0** at all 4 G.3 sites: `plugin.json:4`, `marketplace.json:17`,
  `README.md:5` badge, `README.zh-CN.md:5` badge. Zero `0.24.0` left in live config/docs.
- Skill count **14**: README×2 (14 skills / fourteen / 14 个), AI-GUIDE:7, getting-started:36
  (fourteen), manual-e2e-test (all enumerations), 40-locations:30 (All 14 skills). Zero stale
  `13 skills`/`thirteen`/`All 13 skills` in live docs.
- `harness-language` in all three verify_all skill arrays (bash C.1/G.1/G.2 ×3, PS ×3 — each a
  14-element list); in README + CHANGELOG (G.1/G.2 name-match); `language-policy` in F.1.
- `[0.25.0]` CHANGELOG section present.
- "six task shapes" / "6 种任务形态" UNCHANGED; "32 checks" in 40-locations untouched.

---

## 6. I.6 self-trip regression (T-013 class)

- `verify_all` I.6 = PASS in BOTH shells (live run, §1.1).
- Independent repo-wide grep of the banned token `全程`: every hit is in an EXEMPT file
  (`docs/features/` subtree, `CHANGELOG.md`, `verify_all.{ps1,sh}`, `test-verify-i6.{ps1,sh}`,
  `walkthrough.html`/`project-overview.html`) or `test-init.{ps1,sh}`. None of the T-014
  NEW/edited SCANNED files (SKILL.md, both helpers, both tests, AI-GUIDE, README×2,
  getting-started, manual-e2e, 40-locations, the harness-upgrade hint, dev-map) contain `全程`.
- The I.6 trigger is `全程` adjacent to `中文`; a same-line co-occurrence check across all
  T-014 scanned files returns **none**. (test-init's `全程` is a standalone "is absent"
  assertion description that never co-occurs with `中文`.) Build ships no self-trip.

---

## 7. SKILL-layer behaviors I could not execute (honest scope)

The interactive `AskUserQuestion` confirm (plan→apply, ambiguous-language ask, insert/abort)
and the git-repo / clean-working-tree precondition gates live in `skills/harness-language/SKILL.md`
(the judgment layer), not in the helper. I cannot drive AskUserQuestion or a live git tree from a
test harness. These are **VERIFIED-BY-SPEC**: SKILL.md Stage 1 encodes the git/dirty/min-surface
gates; Stage 4 encodes detect-then-ASK (pre-filled for refresh, no-default for ambiguous, never
guess); Stage 5 the dry-run→present→confirm→apply; Stage 6 the exit-2 CONFLICT→AskUserQuestion
(insert/abort)→`--force` mediation. Frontmatter declares `AskUserQuestion, Bash, PowerShell`. The
Step-4 wording fix (CR MINOR `[MAINT]`) is applied (placeholder `--lang <either> --dry-run` to
read DETECT). The underlying helper mechanics these gates drive (DETECT record, exit 0/1/2,
`--force` insert, dry-run-writes-nothing) are all RUN-verified above.

---

## 8. Stability

- `test-language.sh` ran 3× → `PASS: 39  FAIL: 0` every run.
- `test-language.ps1` ran 3× → `PASS: 39  FAIL: 0` every run.
- No flakes observed despite timestamped `.bak` and `mktemp` per fixture. ✅
- (The PS console echo renders the test's own CJK label strings as mojibake under the active
  console codepage, but the actual file BYTES are correct — proven by the byte-identity
  asserts and the independent `cmp`/`sha256`/`od` checks in §2.)

---

## 9. verify_all result (count deltas)

- Total verify_all checks: 32 → 32 (unchanged — new skill needs no new lettered Step).
- Pass: 32. Fail: 0. Warn: 0. (both shells)
- New driver added to the suite: `test-language` (39 PS / 39 bash) — net test count UP.
- `test-init` unchanged (255 / 217). `test-verify-i6` lockstep untouched.
- Baseline updated: **yes** — added `test_language_ps_assertions: 39` and
  `test_language_bash_assertions: 39` to `.harness/scripts/baseline.json` (additive; no value
  lowered). G.4 only reads `verify_all_checks` from baseline, so this is informational and
  gate-neutral. **verify_all re-run after the baseline edit: 32/0/0 both shells, I.6 + G.4 PASS.**

---

## 10. Defects found

None. 0 BLOCKER, 0 CRITICAL, 0 MAJOR, 0 MINOR. The two CR-documented MINORs (PS ValidateSet
generic message; the resolved Step-4 wording) and the NIT (`LANG_ARG`) were re-confirmed as
accepted-and-correct — not defects:
- PS `-Lang fr` → exit 1, no change (bind-time ValidateSet reject). Contract-equivalent to
  bash's actionable exit 1; test #10 accommodates (`-ne 0`).
- `LANG_ARG` (bash) correctly avoids clobbering the `$LANG` locale env var.

---

## 11. Verdict

**PASS — APPROVED FOR DELIVERY.**

All 13 ACs survived independent adversarial reproducers in both shells. The #1 residual risk —
cross-shell END-STATE byte parity — is cleared for both switch directions and under CRLF input.
`verify_all` 32/32/0, `test-language` 39/39, `test-init` 255/217, `sync-self` In-sync, I.6 green
— all in BOTH shells, all RUN this pass. No defect to route. Baseline bumped (additive) and the
gate re-confirmed green afterward.
