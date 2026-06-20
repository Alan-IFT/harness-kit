# 06 — Test Report · T-03 harness-grill

> Stage 6 (QA Tester). Mode: **full**. deferred-human: defer, do not ask.
> Upstream: 01 READY · 02 READY · 03 APPROVED (C1-C4) · 04 READY FOR REVIEW · 05 APPROVED.
> Adversarial, tool-evidenced validation. Sub-agents are PowerShell-denied here → every `.ps1`
> twin is **operator-pending** (READ, not RUN — never faked). Bash gates RUN and captured live.

## Test plan

| Acceptance criterion | Test case(s) / verification | Evidence |
|---|---|---|
| AC-1 SKILL.md exists, rule-15 `description:` (EN+中文 triggers + when-NOT delta vs 3 siblings) | C.2 frontmatter scan; Read `skills/harness-grill/SKILL.md:1-18` | C.2 PASS; `name:`+`description:` present; triggers + NOT-/harness/-plan/-explore delta in frontmatter |
| AC-2 interview engine (one-at-a-time wait, recommended/question, self-answer, CONTEXT.md SOFT, emit brief) | Read body `:55-107` | All five behaviors documented + graceful-absent CONTEXT.md |
| AC-3 When-NOT + Anti-patterns (multi-question + ask-what-codebase-answers) | Read `:36-46`, `:116-126` | Both prohibitions named verbatim |
| AC-4 user-invoked, pre-pipeline, no stage/routing change; cannot dispatch | `allowed-tools` grep (no `Task`/`Bash`/`PowerShell`) | `:17` = Read,Write,Edit,Glob,Grep,AskUserQuestion,TodoWrite — no Task ⇒ mechanically cannot run pipeline |
| AC-5 RA standing recommended-answer rule, no strip-list contradiction | Read `agents/requirement-analyst.md:23`+`:28` | `:23` requires labelled `Recommended:`; `:28` bans lowercase hedge in PROSE with explicit Exception → §8. Scoped, coherent |
| AC-6 version 0.35.0 ×4 stamps | verify_all **G.3** | G.3 PASS (plugin.json / marketplace.json / both README badges = 0.35.0) |
| AC-7 both READMEs list grill + 16/sixteen; CHANGELOG `[0.35.0]` w/ literal grill | G.1, G.2, G.4 | G.1/G.2/G.4 PASS; grill literal ×1 README, ×4 CHANGELOG |
| AC-8 verify_all C.1/G.1/G.2 reference 16, PASS; G.4 PASS; check count stays 32 | full verify_all run | C.1/G.1/G.2 = "16 skills" PASS; G.4 PASS; **32** checks |
| AC-9 every ungated count surface → 16 + grill entry; decoys untouched | live-tree residual-15 sweep + decoy reverse-check | 0 live residual 15/fifteen/十五; all 6 surfaces at 16; all decoys intact |
| AC-10 AI-GUIDE ≤200 + Workflow triggers agree w/ description | `wc -l`; I.1 | 110 lines (≤200); I.1 PASS |
| AC-11 bash 32/0/0 + test-init green + integration green; PS twin | bash runs (RUN); PS (operator-pending) | sh 32/0/0, test-init 273/0, test-real-project 90/0; **PS twin operator-pending** |
| AC-12 green git tree, no commit/tag | `git status` | In-flight tree only (prior-stage edits + new artifacts); no commit by QA |

## Boundary tests verified (documented in SKILL.md, validated by Read)

- BC-1 CONTEXT.md absent → proceed, no block, no setup pointer, no create-to-populate (`:81-83`). ✓
- BC-2 empty / "I don't know" answer → adopt Recommended default, never hang (`:70-71`). ✓
- BC-3 question answerable from repo → self-answer, do not ask (`:66-69`). ✓
- BC-4 target INPUT.md exists → confirm-before-overwrite, never silent clobber (`:94-95`). ✓
- BC-5 early end → write agreed + residual items, no silent loss (`:105-107`). ✓
- BC-6 no docs/features/ dir → create path as needed (`:92-93`). ✓
- BC-7 strip-list "recommend" collision → reconciled (`agents/requirement-analyst.md:28` Exception). ✓
- BC-8 count-token disambiguation → 32/14/308/90 decoys confirmed UNTOUCHED (see Adversarial #3). ✓

## Adversarial tests (REQUIRED — one predicted failure per gated AC + decoy probes)

The verdict rests on whether the implementation **survived** these probes, not on the
developer's own claims. Each carries a stated failure hypothesis, an independent reproducer,
and pasted tool output.

| AC / surface | Hypothesis ("I expect failure when…") | Reproducer (NEW, I wrote/ran this) | Outcome (tool output) |
|---|---|---|---|
| AC-7/AC-8 (README fan-out) | the G.1 grill enforcement is fake — removing the README bullet still passes | **Mutation A:** `sed -i` delete `/harness-kit:harness-grill` bullet → `verify_all.sh` | **G.1 FAILED** → 31/0/1 exit 2. Load-bearing. RESTORED → 32/0/0. README byte-identical to pre-mutation. |
| AC-7/AC-8 (CHANGELOG fan-out) | G.2 is fake — removing the `harness-grill` literal still passes | **Mutation B:** `sed 's/harness-grill/harness-XXXX/g' CHANGELOG.md` → `verify_all.sh` | **G.2 FAILED** → 31/0/1 exit 2 (G.4 still PASS — heading intact, proving G.2 gates the *name*). RESTORED → 32/0/0. CHANGELOG byte-identical. |
| AC-9 (decoy integrity) | the 15→16 sweep over-flipped a frozen 15/14 decoy to 16 | grep `insight-index.md:35`, `proposals/plugin-native-redesign.html:65/136`, CHANGELOG `:85/:95/:109`, `tasks.md:15/16/28/30`, `harness-status:135` | All read **15 / 14**, NOT 16. `insight-index:35`="the 15 skills"; html:65/136="15 个 skill"; harness-status:135="All 14 required assets". Survived. |
| AC-1/C.2 (discoverability) | the new SKILL.md is missing `name:`/`description:` → not discoverable / C.2 false-pass | `head -3 SKILL.md`; `ls -1 skills/*/SKILL.md \| wc -l` | `name: harness-grill` + `description:` present; **exactly 16** `skills/*/SKILL.md`. Survived. |
| AC-5 (strip-list non-contradiction) | the agent file both REQUIRES and FORBIDS a recommended answer | Read `requirement-analyst.md:23` + `:28` | `:23` requires labelled `Recommended:`; `:28` bans lowercase hedge **in requirement statements** + explicit Exception → §8. No contradiction. Survived. |
| AC-8/NFR-1 (cross-shell symmetry) | ps1 twin is NOT mirrored (array/label drift) — sh edited, ps1 stale | grep "16 skills"/grill in BOTH `verify_all.sh` + `verify_all.ps1` (ps READ, not RUN) | Both shells: 3 arrays carry `harness-grill`, 3 labels read "16 skills" (sh 56/59,329/332,345/348; ps 69/68,301/299,327/325). Mirrored. Survived. |
| NFR-5 (I.6 self-trip) | the new SKILL/agent/CHANGELOG text trips an I.6 retired-claim anchor | full verify_all I.6 + anchor sweep of new non-exempt artifacts | I.6 PASS; only matches are pre-existing *negating* lines (AI-GUIDE:110 "No regeneration", getting-started:136 "not composed") carrying the `not`/`no longer` exclusion token. "recommend" is NOT an I.6 anchor. Survived. |
| AC-4 (cannot dispatch pipeline) | grill can run the pipeline / scripts (Task/Bash in allowed-tools) | grep `allowed-tools:` | `:17` excludes Task/Bash/PowerShell. Mechanically cannot dispatch. Survived. |
| AC-10 (AI-GUIDE cap) | the new Workflow row pushed AI-GUIDE >200 lines | `wc -l AI-GUIDE.md` + I.1 | 110 lines; I.1 PASS. Survived. |
| AC-11 (test-init unchanged) | grill leaked into a template asset → test-init count moved | `test-init.sh` run + grep grill/skill_count in test-init.{sh,ps1} | 273/0 (unchanged); zero grill/skill-count assertion in test-init. Survived. |

### Mutation evidence (pasted)

**Mutation A — README bullet removed → G.1 FAIL:**
```
[C.1] All 16 skills present ... PASS
[G.1] README references all 16 skills ... FAIL
[G.2] CHANGELOG references all 16 skills ... PASS
  PASS: 31   WARN: 0   FAIL: 1   (exit 2)
```
Restore → `[G.1] ... PASS` / `PASS: 32 WARN: 0 FAIL: 0` (exit 0); README diff vs pre-mutation backup = empty.

**Mutation B — `harness-grill` literal removed from CHANGELOG → G.2 FAIL:**
```
[G.1] README references all 16 skills ... PASS
[G.2] CHANGELOG references all 16 skills ... FAIL
[G.3] Version stamps consistent ... PASS
[G.4] Doc count/version claims consistent ... PASS
  PASS: 31   WARN: 0   FAIL: 1   (exit 2)
```
Restore → `[G.2] ... PASS` / `PASS: 32 WARN: 0 FAIL: 0`; CHANGELOG diff vs pre-mutation backup = empty.

## verify_all result

- Total checks: **32 → 32** (no new check — O-4 honored; check count is dynamic and stayed 32).
- Pass: **32**
- Fail: **0** (required for approval ✓)
- Warn: **0**
- C.1 "All 16 skills present" PASS · C.2 frontmatter PASS · G.1/G.2 "all 16 skills" PASS · G.3 0.35.0 PASS · G.4 PASS · I.1 (≤200) PASS · I.6 PASS · F.1 ps/sh-pairs PASS.
- New automated tests added: **0** (justified — grill is a doc/skill artifact whose ACs are
  enforced by existing C.1/C.2/G.1/G.2; mutations A/B prove those checks are load-bearing for
  grill specifically. No new test asserts grill because no new behavioral surface is scriptable
  beyond what the existing checks already gate. Adversarial mutations served as the QA reproducers.)
- Baseline updated: **no** (already reconciled by a prior stage to the live values — verify_all_checks
  32, test_init_bash 273, test_real_project_bash 90 — all matching my captured runs; nothing to move
  up, nothing moved down).

### Bash gates (RUN, live)

| Gate | Expected | Actual | Result |
|---|---|---|---|
| `bash .harness/scripts/verify_all.sh` | 32 / 0 / 0 | **32 PASS / 0 WARN / 0 FAIL** (exit 0) | ✓ |
| `bash .harness/scripts/test-init.sh` | 273 / 0 | **273 PASS / 0 FAIL** (exit 0) | ✓ (unchanged — grill not a template asset) |
| `bash .harness/scripts/test-real-project.sh` | 90 / 0 | **90 PASS / 0 FAIL** (exit 0) | ✓ |

### Operator-pending (PowerShell — denied to sub-agents, NOT faked)

| Gate | Expected | Status |
|---|---|---|
| `pwsh -File .harness/scripts/verify_all.ps1` | 32 / 0 / 0 | **operator-pending** (ps1 READ: 3 arrays + 3 labels mirrored sh — structurally correct for a 32/0/0) |
| `pwsh -File .harness/scripts/test-init.ps1` | green (308) | **operator-pending** (no test-init change) |
| `pwsh -File .harness/scripts/test-real-project.ps1` | green (90) | **operator-pending** |

## Defects found

**None.** 0 BLOCKER / 0 CRITICAL / 0 MAJOR / 0 MINOR.

Carried-forward NIT from CR (not a T-03 defect): `install.sh:139` / `install.ps1:141` help-text
is a manually-maintained per-skill enumeration that will drift on the next skill. Ungated,
SA-flagged §11, parity restored for grill. Not actionable here.

## Stability

- `verify_all.sh` ran **3 consecutive times** → 32 PASS / 0 FAIL each. No flakes. ✓
- Mutation/restore cycle confirmed deterministic (both fail-then-restore returned exactly 32/0/0).

## Verdict

**PASS** (PASS WITH NOTES on the operator-pending PowerShell twins — PS-denied to sub-agents,
read-verified as mirrored, never faked).

All 12 acceptance criteria validated; both load-bearing mutations (README fan-out / CHANGELOG
literal) proved the 15→16 gating is real, not cosmetic; every frozen 15/14 decoy confirmed
untouched; cross-shell symmetry mirrored; I.6 not self-tripped; AI-GUIDE within cap; the
strip-list reconciliation is coherent (require labelled `Recommended:`, ban only the lowercase
hedge in prose). Bash gates 32/0/0 · 273/0 · 90/0. Zero defects. The only remaining item is the
[operator-run] PowerShell verify_all/test-init/test-real-project twins.
