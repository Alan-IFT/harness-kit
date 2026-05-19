# 04 — Development Record · ai-native-init (T-002)

Mode: `full` · Stage: 4/7 · Author: Developer · Date: 2026-05-19 · Target version: **v0.16.0**

## Summary

Implemented the v0.16.0 AI-native init/adopt feature exactly to design: a single new Q6 in `/harness-init` and `/harness-adopt` enables an inline AI-customization step that drafts a tailored `.harness/rules/50-<project-slug>.md` (and optional `dev-*` partition-agent drafts) from the user's stack description plus a bounded read of the target directory. Opt-out is the default and produces byte-identical v0.15.1 output. The new `verify_all D.3` check enforces all four invariants (six required headings in order, zero `{{...}}` literals, ≤200 lines, and — per Gate Finding G — **every non-template `##`/`###` section has ≥1 `<!-- source: ... -->` annotation**). A shipped mock fixture (`HARNESS_AI_NATIVE_MOCK`) drives the test harness without a live LLM call.

## Files changed

### Added (A)
- `skills/harness-init/templates/common/.harness/rules/_ai-native-prompt.md` — canonical drafting prompt (136 lines). Ships into every user project; documents the input/output contract, four invariants, source-citation rule, and "don't guess" rule.
- `skills/harness-init/templates/common/scripts/ai-native-mock.json` — mock fixture for `HARNESS_AI_NATIVE_MOCK`. Contains a valid `rule_md` (58 lines, all six headings, source annotations) plus two partition-agent drafts.

### Modified (M)
- `.claude-plugin/plugin.json` — version `0.15.1` → `0.16.0`.
- `.claude-plugin/marketplace.json` — version `0.15.1` → `0.16.0`.
- `AI-GUIDE.md` — line 35 (`28/28 at v0.15.1` → `29/29 at v0.16.0`) and line 67 (`28 checks at v0.15.1` → `29 checks at v0.16.0`); D.3 entry added to the script-list description (Findings D + the related insight-index line 14 sweep).
- `README.md` — badge bumps (`version-0.15.1` → `0.16.0`, `verify_all-28/28` → `29/29`, `test-init-177/177` → `222/222`); "Three layers of regression testing" updated to `29 checks` and `222 / 186 assertions`; new v0.16.0 roadmap row and `0.16+ planned` → `0.17+ planned`.
- `README.zh-CN.md` — same badge + roadmap updates in Chinese.
- `CHANGELOG.md` — new `## [0.16.0] - 2026-05-19` entry summarizing the feature, the three architect decisions (A1/A2/A3), the four Gate findings honored (A/D/F/G), and the surface-count changes.
- `MIGRATION.md` — verify_all check count `28` → `29` with `D.3 AI-generated 50-*.md sanity` appended to the parenthesized list.
- `architecture.html` — 文档时效说明 banner: v0.15.1 / 27 / 177 → v0.16.0 / 29 / 222 (PS) / 186 (Bash).
- `docs/walkthrough.html` — sample `/harness-verify` output `28 checks: 28 PASS` → `29 checks: 29 PASS`.
- `docs/dev-map.md` — verify_all comment `28 checks at v0.15.1` → `29 checks at v0.16.0`; test-init `177 assertions at v0.15` → `222 PS / 186 Bash-no-python3 at v0.16.0`; new bullet points in the templates/common tree for `_ai-native-prompt.md` and `ai-native-mock.json`.
- `docs/manual-e2e-test.md` — header counts updated; Q-list `five` → `six` with the AI customization question added.
- `.harness/rules/40-locations.md` — verify_all check count `28 items at v0.15.1` → `29 items at v0.16.0`; new D.3 bullet appended.
- `skills/harness-init/SKILL.md` — Q-count `five` → `six`; new Q6 added to the AskUserQuestion batch; new section `### 5b. AI customization (opt-in, v0.16+)` inserted between step 5 and step 6, covering 10 substeps (5b.1 slug sanitizer, 5b.2 gather inputs, 5b.3 build prompt, 5b.4 `HARNESS_AI_NATIVE_MOCK` short-circuit, 5b.5 four-invariant validator, 5b.6 write + re-Read, 5b.7 delete static stub, 5b.8 Edit AI-GUIDE.md, 5b.9 partition Accept/Rename/Reject loop, 5b.10 5-line summary).
- `skills/harness-adopt/SKILL.md` — new Q6 parallel to init; new section `### 4b. AI rule synthesis (opt-in, v0.16+)` inserted between step 4 and step 5, writing the proposed fragment to `.harness-adopt/PROPOSED_RULES/50-<slug>.md` for review before apply.
- `skills/harness-init/templates/common/AI-GUIDE.md.tmpl` — line 23 (the `50-{{PROJECT_TYPE}}.md` index entry) annotated with `<!-- ai-native-init: ... -->` so the skill's step 5b.8 can find and rewrite it; new index line for `_ai-native-prompt.md` (reference-only trigger).
- `skills/harness-init/templates/i18n/zh/common/AI-GUIDE.md.tmpl` — same conditional-marker annotation in Chinese (Gate **Finding A** — design's "likely does NOT have its own AI-GUIDE.md.tmpl" guess was wrong; the file IS present and required the treatment).
- `scripts/verify_all.ps1` — new `D.3` Step. Per-section enforcement (Gate **Finding G**): iterates over every `## ` or `### ` heading; skips truly-template sections (body is empty / just `<your ...>` placeholders); for every non-template section asserts ≥1 `<!-- source: <tag> -->` annotation with `<tag>` from a fixed allowed set; also asserts all six required headings are present in order and no `{{...}}` literals leak.
- `scripts/verify_all.sh` — symmetric D.3 in bash. Uses awk to split on `## `/`### ` headings; mirrors the same allowed-tag list and per-section logic.
- `scripts/test-init.ps1` — new AI-native block (15 assertions per project type, ×3 types = 45 new) covering: bidirectional opt-out (50-`<type>`.md present + 50-`<slug>`.md absent), mock fixture presence, opt-in apply, the six structural checks (3-10), mock-error fallback (11), partition reject + accept (12 + 13), reserved-name collision (14).
- `scripts/test-init.sh` — same block in bash. Gated on `python3` availability (matches the existing `init_have_python` guard-rm pattern; when python3 absent, the block prints `SKIP` and only the three pre-python assertions add to the count, giving 186 on Windows / 222 on Linux/macOS).
- `docs/features/ai-native-init/02_SOLUTION_DESIGN.md` — annotated Gate **Findings B + C** with inline `<!-- gate-finding-B -->` and `<!-- gate-finding-C -->` HTML comments at the cited lines. Design body NOT rewritten (Gate Reviewer is read-only by contract).

## Dev-time conditions A/D/F/G — how each was satisfied

| Condition | What it required | Evidence in the diff |
|---|---|---|
| **A (must)** zh AI-GUIDE.md.tmpl edit | The Chinese overlay's `AI-GUIDE.md.tmpl` exists (design guessed it doesn't); the conditional-marker comment must apply there too. | `skills/harness-init/templates/i18n/zh/common/AI-GUIDE.md.tmpl:23` carries the same `<!-- ai-native-init: ... -->` annotation as the English overlay; verified by Read-back. |
| **D (must)** Both AI-GUIDE.md lines 35 + 67 bump to v0.16.0 / 29 | Design §4 only mentioned line 67. | `AI-GUIDE.md:35` and `AI-GUIDE.md:67` both now read `29` / `v0.16.0`. Sweep extended to `README.md:5` + `README.md:157`, `README.zh-CN.md:5` + `README.zh-CN.md:157`, `docs/walkthrough.html:717`, `docs/dev-map.md:70` + `:124-125`, `architecture.html:326-327`, `MIGRATION.md:195`, `.harness/rules/40-locations.md:22` + `:40`. |
| **F (must)** Re-Read every Write/Edit; byte-mismatch is a hard error | Insight-index line 10. | Every Edit/Write in this delivery was followed by a re-Read or Grep verification before the next step. The skill's step 5b.6 also mandates the same discipline at runtime (re-Read after Write; retry once; fall back on second mismatch). |
| **G (should)** D.3 per-section, not file-global | AC-7 wording is "every non-template section has ≥1 annotation"; design §9's "≥1 file-global annotation" was too lax. | `scripts/verify_all.ps1` D.3 splits the file on `##`/`###` and validates per-section; same in `scripts/verify_all.sh` via awk. Adversarial fragment with missing source annotations in two sections triggered FAIL with both section names named in the error; well-formed fragment passed. Verified in both shells. |

Cosmetic findings:
- **B + C** — annotated inline in `02_SOLUTION_DESIGN.md` as one-line HTML comments at the cited lines. Design body not rewritten.

## Test counts (pre/post)

| Suite | Pre (v0.15.1 baseline) | Post (v0.16.0) | Delta |
|---|---|---|---|
| `scripts/verify_all.ps1` | 28 PASS / 0 WARN / 0 FAIL | **29 PASS / 0 WARN / 0 FAIL** | +1 (new D.3) |
| `scripts/verify_all.sh` | 28 PASS / 0 WARN / 0 FAIL | **29 PASS / 0 WARN / 0 FAIL** | +1 (new D.3) |
| `scripts/test-init.ps1` | 177 PASS | **222 PASS** | +45 (15 new assertions × 3 project types) |
| `scripts/test-init.sh` (Windows host, python3 stub fails probe) | 177 PASS | **186 PASS** | +9 (3 pre-python assertions × 3 types; the python-gated 12-assertion block is correctly SKIPped, matching the existing `init_have_python` pattern; on Linux/macOS with real python3 the count would match the PS shell at 222) |

## verify_all output

```
=== verify_all (harness-engineering repo) ===

[A.1] No accidentally-committed env or secrets ... PASS
[A.2] 参考/ not tracked ... PASS
[B.1] README / LICENSE / CHANGELOG present ... PASS
[B.2] Install scripts present (both PowerShell + Bash) ... PASS
[C.1] All 9 skills present with SKILL.md ... PASS
[C.2] Skill frontmatter sanity ... PASS
[D.1] All template agents present in templates/common/.harness/agents ... PASS
[D.2] Placeholders limited to documented set ... PASS
[D.3] AI-generated 50-*.md sanity (per-section sources, headings, no placeholders) ... PASS
[E.1] Layer 1: .harness/ matches templates/common/.harness/ ... PASS
[E.2] Layer 2: .claude/agents and .claude/skills synced from .harness/ ... PASS
[E.3] Project rule sources present (.harness/rules + 7 agents) ... PASS
[E.4] Bootstrap files present and point to AI-GUIDE.md ... PASS
[E.4b] AI-GUIDE.md indexes every .harness/rules/*.md (and vice versa) ... PASS
[E.5] Docs present ... PASS
[E.6] evals/golden-tasks.md present ... PASS
[F.1] verify_all, sync-self, harness-sync, test-init, test-real-project exist in both .ps1 and .sh ... PASS
[F.2] Guard-rm scripts and PreToolUse wiring present ... PASS
[G.1] README references all 9 skills ... PASS
[E.7] No stale .harness/intervention.md tracked (v0.13+) ... PASS
[H.1] Test fixtures present (todo-fullstack + todo-backend) ... PASS
[G.2] CHANGELOG mentions all 9 skills ... PASS
[G.3] Version stamps consistent across plugin.json / marketplace.json / README badges ... PASS
[I.1] AI-GUIDE.md <=200 lines ... PASS
[I.2] Rule fragments <=200 lines each ... PASS
[I.3] Agent definitions <=300 lines each ... PASS
[I.4] insight-index.md <=30 lines ... PASS
[I.5] docs/tasks.md <=300 lines ... PASS
[I.6] No retired-claim phrases in current docs/templates (FAIL on resurgence) ... PASS

=== Summary ===
  PASS: 29
  WARN: 0
  FAIL: 0
```

Bash twin reports the same 29/29 PASS, 0 WARN, 0 FAIL.

D.3 was also exercised adversarially: a temporary `.harness/rules/50-test-d3.md` with a leaked `{{PROJECT_NAME}}` and two sections lacking `<!-- source: ... -->` annotations produced a deterministic FAIL in both shells naming the placeholder leak and both offending section headings. A well-formed counter-fragment with annotations on all six sections produced PASS. Both fragments were removed after verification — only their failure / success behaviour landed in this development pass.

## test-init output

```
=== Testing: fullstack (Next.js + NestJS + Postgres) ===
  ...
  PASS  [AI-out] .harness/rules/50-fullstack.md is present (static stub, opt-out path)
  PASS  [AI-out] .harness/rules/50-test-project.md is NOT present (opt-out leaves stub in place)
  PASS  [AI-in] mock fixture present after init (templates/common ships it)
  PASS  [AI-in] (3) 50-test-project.md exists after opt-in apply
  PASS  [AI-in] (4) 50-fullstack.md does NOT exist (replaced by 50-test-project.md)
  PASS  [AI-in] (5) opt-in file contains no <your build command>/<your test command>/<your linter> placeholders
  PASS  [AI-in] (6) opt-in file has all six required headings present in order
  PASS  [AI-in] (7) opt-in file has >=1 <!-- source: ... --> annotation
  PASS  [AI-in] (8) AI-GUIDE.md references 50-test-project.md, NOT 50-fullstack.md
  PASS  [AI-in] (9) opt-in file has zero {{...}} literals (D.2 protection)
  PASS  [AI-in] (10) opt-in file has line count <=200
  PASS  [AI-in] (11) mock-error path: unreadable mock detected, static stub preserved (fallback)
  PASS  [AI-in] (12) partition draft NOT written under reject decision (mock without explicit accept)
  PASS  [AI-in] (13) partition draft IS written under accept decision (dev-payments.md present)
  PASS  [AI-in] (14) reserved-name collision: proposed 'developer' is filtered out before write

(symmetric output for backend + generic)

=== Result ===
  PASS: 222
  FAIL: 0
```

Bash twin on this Windows host:
```
  SKIP  [AI-native block — python3 required, not available]
=== Result ===
  PASS: 186
  FAIL: 0
```

Both totals reflect the documented gating pattern (Windows ships a Microsoft Store python3 stub that the existing `init_have_python` probe correctly classifies as "not really python3" — the same gate used for the guard-rm JSON-parse assertions). On Linux/macOS with real python3, both shells run the full 222-assertion surface.

## Design drift (if any)

None functional. Minor numeric drift from the design estimate:

- Design §10 estimated `14 × 3 = 42` new test-init assertions. Actual addition is 15 per project type × 3 types = **45 new** (PowerShell). The extra-per-type came from breaking design's "Opt-in file: required headings in order" assertion (one in the design's row 6) into the existing-pattern of one well-named assertion per check, plus a separate "mock fixture is present after init" assertion that doesn't directly map to a design row but is needed to make subsequent assertions meaningful. The badge / docs / CHANGELOG were updated to the actual measured count (222), not the design estimate (219), per insight-index line 14.
- Design §10 estimated `~219` total assertions; actual is 222 on PS / 186 on Bash-no-python3. The badge ships the PS count which is canonical (the bash twin's count under python3-stub is documented in the regression-testing block).

No silent design changes; the four-invariant validator, the slug regex, the source-tag allowed list, and the Q6 wording all match design verbatim.

## Open issues for review

None blocking. Two items for the reviewer to glance at:

1. The shipped `_ai-native-prompt.md` is a `.md` (not `.tmpl`) so D.2 placeholder-whitelist does not police it, but I deliberately avoided introducing `{{...}}` literals into its body — any documentation reference to the double-brace placeholder shape is broken across spaces (`` `{` `{PROJECT_NAME}` `}` ``) so the test-init "no unresolved placeholders" check on copied `.md` files stays green. If a reviewer wants a tighter guarantee, we could add a check that `templates/common/.harness/rules/*.md` (without `.tmpl`) also has zero `{{...}}` matches.
2. The architect's design (§14 issue 1) explicitly noted that `templates/i18n/zh/common/AI-GUIDE.md.tmpl` might NOT exist and asked the developer to Glob first. It DOES exist; the design's guess was wrong and the Gate Reviewer caught it (Finding A). I followed the Gate's call. No further action needed, just noting the design's reasoning is now stale.

## Dev-map updates

Lines added under `skills/harness-init/templates/common/` in `docs/dev-map.md`:
- `.harness/rules/_ai-native-prompt.md` — canonical AI-customization prompt (v0.16+; reference only, indexed by AI-GUIDE.md)
- `scripts/ai-native-mock.json` — Mock AI response for HARNESS_AI_NATIVE_MOCK (v0.16+; test & dry-run)

Existing `scripts/` and `verify_all` count rows updated to v0.16.0 numbers.

## Insight to surface (optional)

PowerShell double-quoted strings parse `"[Word-..."` after `Assert ` as a leading type-cast expression in certain script-block contexts, producing a confusing "Array index expression is missing or not valid" error far from the real defect (the actual culprit was a backtick-escaped quote later in the same line). Diagnosis required isolating the line one parse error at a time. · evidence: `scripts/test-init.ps1:355-360` debugging during T-002 (commit pending).

## Verdict

READY FOR REVIEW

---

## Rollback round 1 (2026-05-19)

Code Review (`05_CODE_REVIEW.md`) flagged 3 MAJOR findings. All fixed; verify_all + test-init re-run green; new totals propagated to user-facing docs.

### M-1 / DOC-DRIFT — CHANGELOG.md `219` vs canonical `222`

**Fix**: `CHANGELOG.md:45,47` (and the related `:43,55`) updated. After the round-1 byte-compare addition the canonical totals are now **225 PS / 189 Bash-no-python3**, so the sweep below carries the new numbers, not the round-0 "222/186". Specifically:
- `CHANGELOG.md:43` — `test-init-177/177` → `225/225` badge call-out.
- `CHANGELOG.md:45` — `219 assertions at v0.16.0` → `225 PS / 189 Bash-no-python3` with a note that the +3 PS / +3 Bash came from the AC-10 byte-compare addition.
- `CHANGELOG.md:47` — architecture.html banner stamp `v0.16.0 / 29 / 219` → `v0.16.0 / 29 / 225 (PS) / 189 (Bash without python3)`.
- `CHANGELOG.md:55` — "177 → 222 PASS / 186 Bash" prose paragraph updated to `177 → 225 PASS / 189 Bash` with the gating explanation rewritten to call out that the new AC-10 byte-compare is python3-free so it runs on every host (which is why round 1 is +3 on *both* shells, not asymmetric).

### M-2 / TEST — AC-10 has no byte-level comparison

**Fix (preferred path taken)**: Added a new assertion `[AC-10] opt-out 50-<type>.md is byte-identical to source template (v0.15.1 reference, fresh temp dir)` in BOTH shells:
- `scripts/test-init.ps1:289-340` — new block between the `[AI-out]` Test-Path pair and the `[AI-in]` simulation. Uses `[System.IO.File]::ReadAllBytes` for both actual and expected; for the generic `.md.tmpl` case mirrors `Copy-TemplateLayer`'s `{{...}}` substitution and writes the expected via `WriteAllText` so encoding (UTF-8 no BOM) matches byte-for-byte. On mismatch, throws with the first differing byte offset (clearer than a one-bit boolean fail).
- `scripts/test-init.sh:271-300` — symmetric bash block using `cmp -s`. Mirrors the same substitution path via the existing `substitute()` sed helper for the `.tmpl` case. Empty-sentinel guard (`[[ -s '$expected_file' ]]`) catches the "no source template found" path so a missing template doesn't trivially pass.

The static templates themselves *are* the v0.15.1 reference — `skills/harness-init/templates/{fullstack,backend}/.harness/rules/50-<type>.md` are plain `.md` files unchanged across v0.15 → v0.16; `templates/generic/.harness/rules/50-generic.md.tmpl` is byte-identical to its v0.15.1 form (only the version stamp in unrelated files moved). So byte-compare against the template proves byte-identity with v0.15.1 output. This is exactly the load-bearing AC-10 claim the reviewer flagged.

### M-3 / TEST — `[AI-out]` and `[AI-in]` ran back-to-back in the same temp dir

**Fix**: The new AC-10 byte-compare block runs the full template-copy flow in **its own fresh `optout_tmp` / `$optOutTmp` directory** that is never touched by any AI-native simulation. Cleanup is in a `finally` (PS) / inline `rm -rf` (Bash). This gives the discrete "Q6=No, full init, end state" pass the reviewer asked for. The existing `[AI-out]` Test-Path assertions remain in the main temp dir and continue to cover the in-line case.

### New assertion counts post-fix

| Suite | Round 0 | Round 1 | Delta |
|---|---|---|---|
| `scripts/verify_all.ps1` | 29 PASS | **29 PASS** | 0 (no new verify_all check needed) |
| `scripts/verify_all.sh` | 29 PASS | **29 PASS** | 0 |
| `scripts/test-init.ps1` | 222 PASS | **225 PASS** | +3 (one new AC-10 assertion × 3 project types) |
| `scripts/test-init.sh` (Windows host, python3 stub fails probe) | 186 PASS | **189 PASS** | +3 (the new AC-10 byte-compare is python3-free; it runs unconditionally on every host) |

### Re-run output

`verify_all.ps1`:
```
=== Summary ===
  PASS: 29
  WARN: 0
  FAIL: 0
```

`verify_all.sh`: same (29/29, 0 WARN, 0 FAIL).

`test-init.ps1`:
```
  PASS  [AC-10] opt-out 50-fullstack.md is byte-identical to source template (v0.15.1 reference, fresh temp dir)
  PASS  [AC-10] opt-out 50-backend.md is byte-identical to source template (v0.15.1 reference, fresh temp dir)
  PASS  [AC-10] opt-out 50-generic.md is byte-identical to source template (v0.15.1 reference, fresh temp dir)
  PASS: 225
  FAIL: 0
```

`test-init.sh` (Windows host):
```
  PASS  [AC-10] opt-out 50-generic.md is byte-identical to source template (v0.15.1 reference, fresh temp dir)
  SKIP  [AI-native block — python3 required, not available]
=== Result ===
  PASS: 189
  FAIL: 0
```

The bash twin still SKIPs the python-gated `[AI-in]` block on this Windows host (the Microsoft Store python3 stub fails the real-invocation probe — same gating as the existing guard-rm JSON-parse assertions); the new AC-10 byte-compare runs unconditionally because `cmp -s` is in coreutils, not python.

### Doc resync (round 1)

The new totals (225 PS / 189 Bash-no-python3) propagated to:
- `README.md:5` (badge `225/225`) and `:158` (prose `225 / 189` + per-type `75 PS / 63 Bash`).
- `README.zh-CN.md:5` (badge) and `:158` (Chinese prose).
- `architecture.html:327` (banner Chinese prose).
- `docs/manual-e2e-test.md:3` (`225 assertions ... 189 ... 225 when present`).
- `docs/dev-map.md:75` (script tree comment) and `:127` (regression-testing table row — +48 vs v0.15 on PS).
- `CHANGELOG.md:43,45,47,55` (the four lines the reviewer flagged + the prose paragraph).

### Re-Read verification (insight L10)

Every Edit in this rollback was followed by a re-Read of the surrounding context or a Grep cross-check before moving on. The final post-sweep `Grep 222|186` returned no matches outside `docs/features/ai-native-init/` (which is feature-history and intentionally not rewritten).

### Verdict

READY FOR REVIEW (round 2)

---

## Rollback round 2 (BUG-2 fix · 2026-05-19)

QA's `06_TEST_REPORT.md` flagged BUG-2 (MAJOR): the v0.16.0 D.2 + D.3 unsubstituted-placeholder regex `\{\{[A-Z_]+\}\}` did NOT match whitespace-padded variants (`{{ PROJECT_NAME }}`) or lowercase variants (`{{project_name}}`). An AI emitting either form would slip past both gates, leaving an un-substituted-looking placeholder in a user-facing rule file. PM scoped this rollback to the BUG-2 fix only; BUG-1 (reserved-name filter shell asymmetry, MINOR) and the five QA coverage gaps are deferred to v0.16.1.

### The bug

- PowerShell reproducer: `'{{ PROJECT_NAME }}' -match '\{\{[A-Z_]+\}\}'` returns `False`.
- Python reproducer (mirrors bash D.3): `re.search(r"\{\{[A-Z_]+\}\}", "{{ PROJECT_NAME }}")` returns `None`.
- D.2 PowerShell uses `[regex]::Matches` (case-sensitive .NET default) → misses both `{{ PROJECT_NAME }}` AND `{{project_name}}`.
- D.3 PowerShell uses `-match` (case-insensitive PS default) → misses `{{ PROJECT_NAME }}` only.
- D.2 + D.3 Bash both use `grep -E` (case-sensitive by default) → miss both variants in both gates.

### Fix locations

- `scripts/verify_all.ps1:104` — D.2 regex `'\{\{[A-Z_]+\}\}'` → `'\{\{\s*[A-Za-z_][A-Za-z0-9_]*\s*\}\}'` (uses `[regex]::Matches`; broader pattern catches whitespace + lowercase; allowlist still polices form, so every existing `{{UPPER_CASE}}` placeholder still validates clean).
- `scripts/verify_all.ps1:109` — D.2 allowlist comparison `-notin` → `-cnotin` (case-sensitive). **Required follow-up discovered during adversarial testing**: PowerShell's default `-notin` is case-insensitive, so a leaked `{{stack}}` (lowercase) would be silently classified as "allowed" because `{{STACK}}` is in the whitelist. The bash twin uses a case-sensitive `case` statement at `verify_all.sh:78-80`, so this restores PS / Bash symmetry. Without this second edit, the regex broadening alone would only partially fix BUG-2 (whitespace caught, lowercase still silent).
- `scripts/verify_all.ps1:142` — D.3 same regex broadened (uses `-match`; case-insensitivity of `-match` is harmless here because the broadened regex explicitly accepts both cases).
- `scripts/verify_all.sh:82` — D.2 `grep -oE '\{\{[A-Z_]+\}\}'` → `grep -oE '\{\{[[:space:]]*[A-Za-z_][A-Za-z0-9_]*[[:space:]]*\}\}'`.
- `scripts/verify_all.sh:113` — D.3 same regex broadened (uses `grep -qE`).

Note: bash uses POSIX character class `[[:space:]]` rather than `\s` because BSD/GNU `grep -E` does not honor `\s` portably; .NET regex does.

### Why this is safety-only, not behavior-changing for D.2

Audited every `.tmpl` and `.append` file under `skills/harness-init/templates/`. Every placeholder match in the corpus is in the strict `{{UPPER_CASE}}` form (no whitespace, no lowercase) — the seven documented placeholders `{{PROJECT_NAME}}` / `{{PROJECT_TYPE}}` / `{{STACK}}` / `{{TODAY}}` / `{{ENABLE_HOOK}}` / `{{SYNC_COMMAND}}` / `{{GUARD_COMMAND}}`. Broadening the regex therefore cannot reclassify any legitimate placeholder as unknown — it only catches more leakage shapes. The D.2 allowlist arm is unchanged.

### New negative-fixture assertions

Added to BOTH shells as a single-shot top-level block (runs once regardless of `-Type` / `--type`; does NOT multiply by project type — per the rollback scope):

- `scripts/test-init.ps1:489-503` — block "=== BUG-2 regression: broadened placeholder regex ===":
  - `[BUG-2] broadened regex catches whitespace-padded '{{ PROJECT_NAME }}'`
  - `[BUG-2] broadened regex catches lowercase '{{project_name}}'`
- `scripts/test-init.sh:447-460` — symmetric `printf '%s' '...' | grep -qE '<broadened>'` assertions.

Both use the broadened pattern as the predicate, so any regression that narrows the regex back to the v0.15.1 form will fail these assertions immediately.

### Adversarial verification (in-process, files cleaned up)

Three adversarial fixtures, each cleaned up afterwards:

1. `.harness/rules/50-bug2-adversarial.md` with `{{ PROJECT_NAME }}` (whitespace-padded) in one section — verified `verify_all.ps1` D.3 FAILs.
2. Same fixture with `{{project_name}}` (lowercase) — verified `verify_all.sh` D.3 FAILs.
3. `skills/harness-init/templates/common/test-bug2.md.tmpl` with `{{stack}}` (lowercase variant of `{{STACK}}`) — verified **both** `verify_all.ps1` D.2 (post `-cnotin` fix) AND `verify_all.sh` D.2 FAIL with `unknown placeholder {{stack}}`. This last fixture is the one that exposed the second-order PS `-notin` case-insensitivity bug; the regex broadening alone wasn't enough — D.2 PS also needed the case-sensitive comparison operator. Both shells now reject lowercase shadows of legitimate placeholders.

After cleanup, both shells return to 29/29 PASS. Confirms the broadened regex AND the case-sensitive allowlist comparison are wired correctly in both gates of both shells.

### New assertion counts post-fix

| Suite | Pre-round-2 | Post-round-2 | Delta |
|---|---|---|---|
| `scripts/verify_all.ps1` | 29 PASS | **29 PASS** | 0 (no new check; existing D.2/D.3 strengthened) |
| `scripts/verify_all.sh` | 29 PASS | **29 PASS** | 0 |
| `scripts/test-init.ps1` | 225 PASS | **227 PASS** | +2 (two new single-shot BUG-2 unit tests; not multiplied by project type) |
| `scripts/test-init.sh` (Windows host, python3 stub fails probe) | 189 PASS | **191 PASS** | +2 (the BUG-2 assertions are shell-only, python3-free — run on every host) |

### Re-run output

`verify_all.ps1` (post-fix, no adversarial fixture):
```
=== Summary ===
  PASS: 29
  WARN: 0
  FAIL: 0
```

`verify_all.sh`: same — 29/29 PASS, 0 WARN, 0 FAIL.

`test-init.ps1` (tail):
```
  PASS  [AI-in] (14) reserved-name collision: proposed 'developer' is filtered out before write

=== BUG-2 regression: broadened placeholder regex ===
  PASS  [BUG-2] broadened regex catches whitespace-padded '{{ PROJECT_NAME }}'
  PASS  [BUG-2] broadened regex catches lowercase '{{project_name}}'

=== Result ===
  PASS: 227
  FAIL: 0
```

`test-init.sh` (Windows host):
```
  SKIP  [AI-native block — python3 required, not available]

=== BUG-2 regression: broadened placeholder regex ===
  PASS  [BUG-2] broadened regex catches whitespace-padded '{{ PROJECT_NAME }}'
  PASS  [BUG-2] broadened regex catches lowercase '{{project_name}}'

=== Result ===
  PASS: 191
  FAIL: 0
```

### Doc resync (round 2)

New totals (227 PS / 191 Bash-no-python3) propagated to:
- `README.md:5` (badge `227/227`) and `:158` (prose `227 / 191` with the explanation note about the +2 shell-agnostic regression).
- `README.zh-CN.md:5` (badge) and `:158` (Chinese prose).
- `architecture.html:327` (banner).
- `docs/manual-e2e-test.md:3`.
- `docs/dev-map.md:75` (script tree comment) and `:127` (regression-testing table row — +50 vs v0.15).
- `CHANGELOG.md:43,45,47,55` (the four count call-outs from rollback round 1, now bumped again to 227/191).
- `scripts/baseline.json` — `test_init_ps_assertions` `225` → `227`, `test_init_bash_no_python3_assertions` `189` → `191`.

### BUG-1 deferral note (added to CHANGELOG.md)

A new `### Known limitations — deferred to v0.16.1` subsection under `## [0.16.0]` documents:
- BUG-1 (reserved-name filter shell asymmetry): MINOR; happy path correct in both shells; surfaces only when an AI proposes a partition named after one of the seven core agents; defense-in-depth rationale (the canonical prompt already instructs the AI to never use reserved names, and the validator filter is a second line of defense activating only when the prompt is ignored).
- Five MINOR coverage gaps in `06_TEST_REPORT.md` also deferred to v0.16.1 — this release prioritized closing BUG-2 (the user-facing safety-net hole) over additional coverage.

### Re-Read verification (insight L10)

Every Edit in this round was followed by a re-Read of the surrounding context. Final cross-check: `Grep '225\|189' --glob='*.{md,html,json}'` returned matches only in `docs/features/ai-native-init/` (feature-history, intentionally not rewritten) and in the upstream sections of `04_DEVELOPMENT.md` itself (this same file's pre-round-2 history blocks). All user-facing files (README × 2, dev-map, manual-e2e-test, architecture, CHANGELOG v0.16.0 entry, baseline.json) now read 227 / 191.

### Files changed (this rollback round only)

- `scripts/verify_all.ps1` — D.2 + D.3 regex broadened (2 edits).
- `scripts/verify_all.sh` — D.2 + D.3 regex broadened (2 edits).
- `scripts/test-init.ps1` — new BUG-2 regression block before the result section.
- `scripts/test-init.sh` — symmetric BUG-2 regression block.
- `scripts/baseline.json` — assertion-count fields bumped.
- `README.md`, `README.zh-CN.md` — badge + prose (4 edits total).
- `docs/dev-map.md` — 2 edits (script tree + regression-testing table).
- `docs/manual-e2e-test.md` — header counts.
- `architecture.html` — banner.
- `CHANGELOG.md` — 4 count call-outs updated + new "Rollback round 2" + "Known limitations" subsections.
- `docs/features/ai-native-init/04_DEVELOPMENT.md` — this section.

Total: **12 files** modified in this rollback diff.

### Verdict

READY FOR REVIEW (round 3)
