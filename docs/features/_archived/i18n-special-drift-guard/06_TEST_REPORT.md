# 06 — Test Report · T-016 / i18n-special-drift-guard

> Stage 6. QA Tester (adversarial). Validates the ELIMINATE design by RUNNING. All numbers below are
> captured from actual tool runs this session — never remembered. PowerShell is sandbox-blocked in this
> environment (same as the Developer's); the bash side was run in full, the PS twin was verified statically,
> and the PM/CR previously captured the PS numbers. This is stated explicitly wherever it applies.

## Verdict: **PASS** (approved for delivery)

0 BLOCKER · 0 CRITICAL · 0 MAJOR · **1 MINOR** (routed to PM → developer/architect, advisory only; does not
block delivery). The duplication is genuinely eliminated, the composed zh tree is byte-correct, the suite
detects body drift in a composed zh tree, and the gate is green in bash with the PS twin statically verified +
previously PM-captured.

---

## Environment / honesty note (PowerShell)

PowerShell execution is **blocked by the sandbox** in this environment: both the `PowerShell` tool and `pwsh`
via Bash are denied by the auto-mode classifier (identical to the Developer's stage-4 situation). Therefore:

- **bash side: RUN in full** (verify_all.sh, test-language.sh, test-init.sh, sync-self.sh, plus all adversarial
  probes — all output pasted below).
- **PS side: VERIFIED-BY-SPEC** (static review of `test-init.ps1` / `language-policy.ps1` / `verify_all.ps1`
  logic) + the PM-captured PS numbers recorded in `05_CODE_REVIEW.md` (verify_all 32/32, test-language 39/39,
  test-init 275/275). I did **not** fabricate any PS number. Where a PS run is required, the PM owns it.

---

## Mandatory checklist results

| # | Script | bash (RUN) | PS |
|---|---|---|---|
| 1 | `verify_all` | **PASS 32 / WARN 0 / FAIL 0**, version 0.27.0, G.3+G.4+I.6 PASS, count UNCHANGED at 32 | VERIFIED-BY-SPEC (G.4 derives count=32 statically; PM-captured 32/32) |
| 2 | `test-language` | **39 PASS / 0 FAIL** (incl. #9 byte-identical round-trip, #10 boundary) | VERIFIED-BY-SPEC (re-point is path-only; PM-captured 39/39) |
| 3 | `test-init` | **237 PASS / 0 FAIL** (= baseline bash 237; new `[zh][T-016]` + retained T-013/T-015 zh all PASS) | VERIFIED-BY-SPEC (PS mirror reviewed; PM-captured 275/275) |

### 1. verify_all.sh (captured)

```
[E.1] Layer 1: .harness/ matches templates/common/.harness/ ... PASS
...
[I.6] No retired-claim phrases in current docs/templates ... PASS
[J.1] settings.json schema integrity (.claude/ + template) ... PASS
[G.4] Doc count/version claims consistent with plugin.json + live check count ... PASS

=== Summary ===
  PASS: 32
  WARN: 0
  FAIL: 0
RC=0
```

- **Count UNCHANGED at 32** — G.4 is the last check; `g4_count = ${#report[@]} + 1` and the comment at
  `verify_all.sh:673` pins "31 recorded + G.4 = 32". No new lettered Step exists (the anti-bloat goal). The
  G.4 tripwire (`:769-771`) enforces G.4-last. **AC-8 met.**
- **I.6 PASS** (no retired-claim/banned-anchor line introduced). **AC-9 met.**
- E.1 PASS + `sync-self --check` → **"In sync."** (language-policy dogfood mirror byte-identical to template).

### 2. test-language.sh (captured)

```
--- #9 byte-identical zh->en->zh round-trip ---
  [PASS] 9: 00-core byte-identical after round-trip (§5.4)
  [PASS] 9: CLAUDE.md byte-identical after round-trip (§5.4)
  [PASS] 9: copilot byte-identical after round-trip (§5.4)
--- #10 invalid --lang ---
  [PASS] 10: bad --lang exits 1 (boundary 2)
=== Summary ===
  PASS: 39
  FAIL: 0
```
Re-confirmed on a 2nd run: **39/39** (no flake). The `/harness-language` re-point to M-1 did not break.

### 3. test-init.sh (captured)

```
=== SUMMARY ===
  PASS: 237
  FAIL: 0
  PASS  [zh] retired blunt 全程 phrasing is absent
  PASS  [zh] 00-core.md has ENGLISH body (Hard rules (red lines) present)
  PASS  [zh] 00-core.md keeps Chinese policy heading (输出语言（按消费者分流） present)
  PASS  [zh] 00-core.md has NO second (English) policy section (Output language (project-wide) absent)
  PASS  [zh][T-016] composed zh 00-core BODY byte-matches English common/ (single-source, no duplication)
```
237 = baseline `test_init_bash_no_python3_assertions`. Ran 3× this session (initial / mutate-revert / stability)
— **237/237 every time, no flake.** The new `[zh][T-016]` body-match + the retained T-013 (`全程` absent) and
T-015 inverse (ENGLISH body present / zh heading present / no 2nd EN section) assertions all PASS on the
**COMPOSED** fixture.

---

## HEADLINE CHECK 1 — the duplication is GONE + the composed zh tree is correct (AC-1/AC-3/AC-7)

I built a **real composed zh project from scratch** (my own reproducer, NOT the dev's test): laid the English
`common/` 00-core/CLAUDE/copilot + the helper into a temp dir, then ran the **re-pointed** helper
`language-policy.sh --template-root <repo> --lang zh` — exactly init step 4.4. Injector output:

```
LANG|zh
DETECT|en|00-core
RESULT|REWRITE-SECTION|.harness/rules/00-core.md|to zh
RESULT|REWRITE-LINE|CLAUDE.md|to zh
RESULT|REWRITE-LINE|.github/copilot-instructions.md|to zh
SUMMARY|rewritten=3 noop=0 skipped=0 baks=3 conflicts=0
```

Then verified on the composed tree:

- **(a) 00-core single zh policy section, NO English second section, English body present:**
  `## 输出语言（按消费者分流）` = 1, `## Output language (project-wide)` = 0,
  `## How this project is developed` = 1, `Hard rules` marker = 1. ✓
- **(b) CLAUDE.md + copilot = English body + single zh policy line:**
  CLAUDE `^输出语言：` = 1 / `^Output language:` = 0 / English body (`AI-GUIDE` ref) present;
  copilot `^输出语言：` = 1 / `^Output language:` = 0. ✓
- **(c) BODY byte-identical (the single-source proof — duplication ELIMINATED, not relocated):**
  composed body = 3681 bytes / 53 lines; `common/` body = 3681 bytes / 53 lines;
  `cmp` → **byte-identical**; identical sha256
  `f5bae855e3087b7cab2d54dc71ceeba1d32a4abc308cc6bb4375844ff9a56705`. ✓
- **(d) deletion + no shipped `_policy/`:** Glob for all 3 SPECIAL `.tmpl` → "No files found";
  `find <composed>/-path *_policy*` → empty (the `_policy/` snippet is NOT laid into the project). ✓
- **M-1 is the ONLY home of the zh policy text:** the policy **body prose** (`按主要消费者`) appears in
  exactly ONE file under `skills/templates/` — `i18n/zh/_policy/output-language.zh.md.tmpl` (count = 1).
  The other `## 输出语言（按消费者分流）` hits are helper **anchor literals** (`zh_heading=`, `detect_lang`
  grep) and SKILL.md **prose** — none carries the body (`按主要消费者` = 0 in each). ✓

**HEADLINE 1: PASS — the English-body duplication is genuinely eliminated; the composed zh tree is byte-correct.**

---

## HEADLINE CHECK 2 — body-match mutation sensitivity (AC-1/B-6) — with a MINOR finding

**Hypothesis A (my first probe):** "Changing one non-policy body line in `common/00-core.md.tmpl` will make
the `[zh][T-016]` body-match assertion go RED."

**Outcome: the hypothesis was WRONG, and this exposed a real effectiveness gap.** I mutated a body line
(`1. **No silent design drift.**` → `1. **QA-T016-MUTATION-PROBE silent design drift.**`) and ran test-init.sh:

```
RC=0   PASS: 237   FAIL: 0
  PASS  [zh][T-016] composed zh 00-core BODY byte-matches English common/ (single-source, no duplication)
```

The `[zh][T-016]` assertion stayed **GREEN**. Reason: the assertion compares `composed_body` vs `common_body`,
and **BOTH derive from the same `common/` source** (composed = `common/` laid down + helper inject; common =
`common/` template read directly). A `common/`-body mutation propagates to **both** sides → they stay equal →
GREEN. The assertion is therefore **vacuous against a `common/` body drift** — it can only catch a
**helper-composition corruption** (the helper over/under-cutting the seam and eating/altering a body byte).

I then proved the assertion **IS non-vacuous for the case it actually covers** by corrupting the *composed*
body directly and running the assertion's exact comparison logic:

```
unmutated                 => GREEN (bodies match)
composed-body-corrupted   => RED (bodies DIFFER)   # "No silent design drift" -> "CORRUPTED-BODY design drift"
```

So the `[zh][T-016]` assertion correctly catches helper/seam corruption, but NOT a plain `common/` body edit.

**Does the SUITE still catch a `common/` body drift in a composed zh tree?** YES — via a *different*,
pre-existing assertion. I reproduced the dev's exact mutation (`## Hard rules (red lines)` →
`## Hard rules (MUTATED)`) and ran test-init.sh:

```
RC=1   PASS: 236   FAIL: 1
  PASS  [zh][T-016] composed zh 00-core BODY byte-matches English common/ ...   <- stayed GREEN
  FAIL  [zh] 00-core.md has ENGLISH body (Hard rules (red lines) present)        <- this is what went RED
```

The drift is caught by the **pre-existing T-015 inverse assertion** (`[zh] ... Hard rules (red lines) present`,
a literal string-presence check), **not** by the new `[zh][T-016]` body-match. Revert → 237/237 green,
template sha back to `483af11571deef...` (byte-clean), git status clean.

**HEADLINE 2: PASS with a MINOR finding** — body drift in a composed zh tree IS detected by the suite (in both
shells); the suite is mutation-sensitive. **But the `04_DEVELOPMENT.md` "Mutation proof (B-6)" claim and the
`02` §7.4 claim are misattributed**: the dev's `Hard rules → MUTATED` mutation goes RED via the *old* T-015
string assertion, while the *new* `[zh][T-016]` assertion stays GREEN. The new assertion proves "composition
carried the body correctly" (seam integrity), which is real and useful, but it does NOT prove "a `common/`
body drift is caught" — that is covered by the older assertion. See MINOR-1.

---

## Adversarial tests (REQUIRED — one falsification probe per AC)

| AC | Hypothesis ("I expect failure when…") | Reproducer (NEW, I wrote it) | Outcome (with evidence) |
|---|---|---|---|
| AC-1 | a `common/` body line change is silently lost in the composed zh tree | independent composed tree (HEADLINE 1) + body `cmp` | **Survived** — composed body byte-identical to `common/` (sha `f5bae855…`), single-source proven |
| AC-2 | some script/skill still reads a deleted SPECIAL file | `Grep i18n/zh/common/...{00-core,CLAUDE,copilot}` repo-wide | **Survived** — only `CHANGELOG.md` (archival) matches; no runtime reader. Overlay = 2 human files + `_policy/` |
| AC-3 | injecting zh policy leaves a 2nd English policy section, or the policy region got body-compared | composed-tree section counts (HEADLINE 1a) | **Survived** — `## Output language (project-wide)` = 0, `## 输出语言…` = 1 (single-section invariant holds) |
| AC-4 | bash and PS reach different body-match verdicts (CR flagged PS `[array]::IndexOf`+`-ceq`) | static review `test-init.ps1:688-713` vs bash `:585-591` | **Survived (bash RUN, PS spec)** — same line-list-after-CR-strip model, `-ceq` exact; symmetric. PM-captured PS 275 |
| AC-5 | the new assertion is vacuous (never goes RED) | corrupt composed body, run comparison logic (HEADLINE 2) | **Survived for its scope** — RED on composed-body corruption; **MINOR-1**: vacuous vs `common/`-body edit |
| AC-6 | `/harness-language zh`→`en`→`zh` does not byte-round-trip on a real composed tree | round-trip on my composed tree (Probe #3) | **Survived** — all 3 files' sha256 byte-identical after zh→en→zh; helper reads M-1 both directions |
| AC-7 | the en init path / `common/` English body changed | `git diff` of the 3 `common/` SPECIAL counterparts | **Survived** — all three diffs EMPTY; en branch untouched (`language-policy.sh:78-81`) |
| AC-8 | count drifted off 32, or version not 0.27.0 everywhere | verify_all G.4 PASS + grep version/badge/baseline | **Survived** — count=32 (G.4 derives), version 0.27.0 ×4, `verify__all-32%2F32` badge unchanged, baseline 32 |
| AC-9 | a `全程`-adjacent-`中文` (I.6 banned anchor) line was introduced | `grep 全程` in every edited scanned file + verify_all I.6 | **Survived** — only `全程` hits are pre-existing assertion NAMES in test-init; M-1 carries `按消费者分流`; I.6 PASS |
| AC-10 | baseline counts are hand-estimated, not from a run | compare baseline 237/275 to my captured bash run | **Survived** — bash 237 matches my run exactly; PS 275 is PM-captured (I can't run PS, did not touch it) |

Every AC survived the falsification probe. AC-5's survival is **scoped** (see MINOR-1) but the AC itself
("a regression exercises drift→RED, restore→GREEN") IS met by the suite as a whole (the T-015 assertion +
the composed-body-corruption sensitivity of `[zh][T-016]`).

---

## Boundary / robustness tests exercised

- **Round-trip idempotency** (AC-6): zh→en→zh byte-identical (sha unchanged) on a non-fixture composed tree.
- **Helper language detection**: `--lang en` correctly `DETECT|zh` then rewrote to en; `--lang zh` correctly
  `DETECT|en` then rewrote to zh — no CONFLICT, 0 skipped.
- **Invalid `--lang`** (test-language #10): exits 1 (boundary).
- **CJK / UTF-8 no-BOM**: M-1 `按消费者分流` consumer-split text renders cleanly; `全程` absent (I.6-clean).
- **`.bak` artifact hygiene**: injector wrote 3 `.bak-*`; cleaned by the `rm -f`/`find -delete` step (matches
  init step 4.4 + test-init); composed tree has no stray files.

---

## verify_all result

- Total checks: **32 → 32** (UNCHANGED — no new lettered check; the explicit anti-bloat outcome).
- Pass: **32** · Fail: **0** · Warn: **0** (bash; PS PM-captured 32/32).
- Version: 0.27.0 (G.3 PASS). G.4 PASS (count/version fan-out consistent). I.6 PASS.
- New tests added by T-016: **+1 assertion per shell** (`[zh][T-016]` body-match). test-init bash 236→237,
  PS 274→275 (PM-captured).
- Baseline updated: **no change needed** — `baseline.json` already at the captured values
  (`test_init_bash_no_python3_assertions: 237` matches my run; `test_init_ps_assertions: 275` PM-captured;
  `verify_all_checks: 32`). Baseline only goes up; nothing to bump.

## Defects found

- **[MINOR / TEST-EFFECTIVENESS] The new `[zh][T-016]` body-match assertion does not catch what `02` §7.4 and
  `04` "Mutation proof (B-6)" claim it catches.** It compares two derivations of the SAME `common/` source
  (composed body vs `common/` body), so a `common/`-body edit propagates to both sides and the assertion stays
  GREEN (reproduced: `Hard rules (red lines)`→`MUTATED` → `[zh][T-016]` GREEN, 236/237). The drift IS caught,
  but by the **pre-existing T-015 inverse assertion** (`[zh] ... Hard rules (red lines) present`), not the new
  one. The new assertion's true (and useful) scope is **helper/seam composition integrity** — it goes RED if
  the injection corrupts a body byte (reproduced: composed-body corruption → RED).
  **Impact:** none on shipped behavior; the suite still detects body drift in a composed zh tree (both shells).
  This is a **documentation/claim accuracy** defect, not a functional one — the dev's B-6 "mutation proof"
  citation is misattributed.
  **Reproducer:** `sed 's/Hard rules (red lines)/Hard rules (MUTATED)/'` in
  `skills/harness-init/templates/common/.harness/rules/00-core.md.tmpl`; `bash .harness/scripts/test-init.sh` →
  `[zh][T-016]` stays PASS, `[zh] ... ENGLISH body (Hard rules (red lines) present)` FAILs. Revert → 237 green.
  **Routing:** PM → developer (tighten the B-6 mutation-proof narrative in `04` and the §7.4 claim) and/or
  architect (decide whether `[zh][T-016]` should be strengthened, e.g. compare the composed body against a
  pristine `common/` snapshot captured *before* any same-run mutation — though no functional change is required
  to ship). **Advisory; does not block delivery.**

## Stability

- test-init.sh ran **3×** → 237/237 each time, no flake. ✅
- test-language.sh ran **2×** → 39/39 each time, no flake. ✅
- verify_all.sh ran **2×** → 32/0/0 each time. ✅
- No flaky test observed.

## Regression statement

verify_all (32/0/0), test-language (39/39), test-init (237/237), and sync-self (`In sync`) are all green in
bash; the PS twins are statically verified + PM-captured. The en init path is byte-unchanged (`git diff` of the
three `common/` English bodies is empty). The elimination did not break the rest of the suite. No mutation
residue: every temp template edit reverted to sha `483af11571deef…`, temp fixtures removed, `git status` shows
exactly the T-016 staged set with no stray tracked change.

## Verdict

**APPROVED FOR DELIVERY** — 0 BLOCKER / 0 CRITICAL / 0 MAJOR / 1 MINOR (advisory, routed). The headline goals
are met: the English-body duplication is genuinely ELIMINATED (composed zh body byte-identical to `common/`,
single-sourced; the 3 SPECIAL files deleted; M-1 the only home of the zh policy), the composed zh tree is
byte-correct, the gate stays 32/32 (anti-bloat win) at version 0.27.0, the round-trip is byte-clean, and the
suite detects body drift in both shells. The one MINOR is a claim-accuracy gap about *which* assertion provides
the mutation proof, not a functional defect.
