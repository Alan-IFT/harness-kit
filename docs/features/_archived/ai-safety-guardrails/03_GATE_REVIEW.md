# 03 — Gate Review · ai-safety-guardrails

- Task: `T-001 / ai-safety-guardrails`
- Mode: `full`
- Reviewer: Gate Reviewer
- Date: 2026-05-16
- Upstream: `01_REQUIREMENT_ANALYSIS.md` (verdict READY), `02_SOLUTION_DESIGN.md` (verdict READY FOR GATE REVIEW)

## 1. Code-grounding verifications

| Design claim | File / line | Verified? | Notes |
|---|---|---|---|
| `verify_all.ps1:94` has `$allowed` array (placeholder whitelist) | Line 94 of `scripts/verify_all.ps1` | **YES** | Confirmed; current whitelist has 6 entries: `{{PROJECT_NAME}}, {{PROJECT_TYPE}}, {{STACK}}, {{TODAY}}, {{ENABLE_HOOK}}, {{SYNC_COMMAND}}`. |
| `verify_all.sh:79` has `case` pattern for placeholders | Line 79 of `scripts/verify_all.sh` | **YES** | Confirmed; same 6 placeholders. |
| F.2 was vacated in v0.14.x — comment at line 193 | `scripts/verify_all.ps1:193` | **YES** | Confirmed: `# (F.2 removed v0.14.x — was a literal duplicate of B.2; Bash never had it.)`. |
| `AI-GUIDE.md:58` says "+ 4 script pairs" but names 3 | `AI-GUIDE.md:58` | **YES, pre-existing off-by-one drift** | See F-3. |
| `harness-init/SKILL.md:139` has `{{SYNC_COMMAND}}` OS-detect block | line 139 | **YES** | Confirmed. |
| E.4b at `verify_all.ps1:141` / `.sh:126` is bidirectional | both files | **YES** | Adding `75-safety-hook.md` auto-covered for dogfood. |
| `Glob` `.harness/agents/dev-*.md` empty | — | **YES** | Single-developer partition is correct. |
| zh overlay translates `60-tool-handoff.md` | `templates/i18n/zh/common/.harness/rules/60-tool-handoff.md` | **YES** | Present (no `.tmpl` suffix). |
| zh overlay translates `AI-GUIDE.md.tmpl` | `templates/i18n/zh/common/AI-GUIDE.md.tmpl` | **YES** | Confirmed. |
| `evals/` exists | `evals/golden-tasks.md` present | **YES** | New `guard-rm-cases.md` fits convention. |
| `sync-self.ps1:34-42` is the `$mappings` array | — | **YES** | 7 entries; insertion point after line 41 is sound. |
| `sync-self.sh:57-70` is the mappings region | — | **YES** | 4 mappings present; Mapping 5 insertion after 70 is correct. |
| `pm-orchestrator.md` line 4 + 108-129 | — | **YES** | D2 callout source is accurate. |
| `.claude/settings.json` has `hooks.Stop` array | — | **YES** | Additive PreToolUse insertion preserves existing. |
| `templates/common/.claude/settings.json.tmpl:41` has `{{SYNC_COMMAND}}` | — | **YES** | `{{GUARD_COMMAND}}` analogue is sound. |
| Insight ledger entries cited by design | `.harness/insight-index.md` | **YES** | All 5 referenced insights are present verbatim. |

## 2. Eight-dimension audit

| # | Dimension | Verdict | Reasoning |
|---|---|---|---|
| 1 | Requirement → design coverage | **PASS** | Every in-scope item 1-19 maps to files. No orphan decision. |
| 2 | Code grounding | **PASS** | All cited paths and line numbers verified. |
| 3 | Reuse correctness | **PASS** | Cross-shell skeleton, `{{SYNC_COMMAND}}` analogy, E.4b auto-coverage all sound. No existing path-outside-root helper missed. |
| 4 | Risk coverage | **PASS w/ obs** | R1-R12 cover real risks. F-1: nested-pwsh recursion DoS not enumerated (mitigation in algorithm — minor). |
| 5 | Migration safety | **PASS** | Additive shape, re-adopt for migration, settings.json carve-out preserved. |
| 6 | Boundary handling | **PASS** | B1-B17 all addressed in algorithm §4.2 + design §5.5. |
| 7 | Test feasibility | **WARN** | Acceptance C7 says test-init must end with PreToolUse + guard-rm present — but design §3 does NOT list test-init.{ps1,sh} as MODIFY, and current test-init.ps1:163 only `Test-Path` on settings.json. See F-2. |
| 8 | Out-of-scope clarity | **PASS** | Carve-outs explicit; no scope creep risk. |

## 3. Findings

### F-1 (MINOR, design): Risk table missing nested-pwsh recursion abuse row
Cosmetic; mitigation already in algorithm (depth-2 cap → BLOCK).

### F-2 (MEDIUM, design): `test-init.{ps1,sh}` not in MODIFY list yet C7 depends on it
**Fix**: add `scripts/test-init.ps1` and `scripts/test-init.sh` to file plan as MODIFY with:
- Assert rendered `.claude/settings.json` parses as JSON, `hooks.PreToolUse[0].matcher == "Bash"`, `hooks.PreToolUse[0].hooks[0].command` contains `guard-rm`.
- Assert `scripts/guard-rm.ps1` and `scripts/guard-rm.sh` exist in the rendered fixture.

### F-3 (LOW): Propagated off-by-one in `AI-GUIDE.md:58`
Current line says "+ 4 script pairs (harness-sync, install-hooks, archive-task)" — count says 4, names list 3. Design proposed "+ 5 ... (… + guard-rm)" — would propagate the drift.
**Fix**: write "+ 4 script pairs (harness-sync, install-hooks, archive-task, guard-rm)" — accurate count, accurate list.

### F-4 (LOW): `.harness/rules/40-locations.md:29` placeholder count drift
Says "Placeholder whitelist enforced (5 allowed)" — actual is 6 today, becomes 7 after `{{GUARD_COMMAND}}`. Design §3 row 26 only mentions 26→27 and F.2 line.
**Fix**: also bump "(5 allowed)" → "(7 allowed)" in 40-locations.md:29.

### F-5 (LOW, opportunistic): template `AI-GUIDE.md.tmpl:26` says `F.*` not `I.*`
Pre-existing drift; not in this task's scope; can be bundled opportunistically.

### F-6 (INFO): C8 acceptance auto-covered by E.4b for dogfood; template + zh covered by §7.4 enumeration. Confirmed.

### F-7 (INFO): `.tmpl` suffix on `75-safety-hook.md.tmpl` consistent with the majority of sibling fragments.

## 4. High-probability questions during development

| # | Likely Q | Pre-answer |
|---|---|---|
| Q1 | `sync-self` orphan-removal for new file mappings? | Orphan logic applies only to `type="dir-of-md"`. The two new mappings are `type="file"` — safe. |
| Q2 | Preserve JSON key order in settings.json? | Yes; append PreToolUse after `Stop` in the existing `hooks` object. |
| Q3 | Acceptance C7 requires test-init changes — Architect didn't list them. Add assertions? | YES — see F-2 fix. |
| Q4 | Ship `scripts/test-guard-rm.{ps1,sh}` driver for `evals/guard-rm-cases.md`? | YES — acceptance B2 needs "a small driver script exercises them". Don't add to verify_all (out of scope v0.15). |
| Q5 | bash JSON extraction robustness? | Parse-failure → BLOCK by design (§4.1). sed heuristic + python-if-available is the contract. |
| Q6 | AI-GUIDE.md:58 count bump? | Write "4 pairs (… + guard-rm)" — fix don't propagate. |
| Q7 | README badges to bump? | `version-0.14.0`→`0.15.0`, `verify__all-26%2F26`→`27%2F27` in BOTH `README.md` and `README.zh-CN.md`. `test-init` badge depends on whether C-1 (F-2) adds new assertions — if yes, bump by 2; if not, unchanged. |

## 5. Verdict

**APPROVED WITH CONDITIONS**

Design is sound and grounded. Conditions for Developer (Code Reviewer will verify in stage 5):

1. **C-1 (F-2)**: extend `scripts/test-init.ps1` and `scripts/test-init.sh` with PreToolUse + guard-rm assertions.
2. **C-2 (F-3)**: write "+ 4 script pairs (harness-sync, install-hooks, archive-task, guard-rm)" at `AI-GUIDE.md:58`. Fix don't propagate.
3. **C-3 (F-4)**: bump "(5 allowed)" → "(7 allowed)" in `.harness/rules/40-locations.md:29`.
4. **C-4**: re-Read or Grep after every Edit on multi-surface files (insight 2026-05-16 Edit-tool false success).
5. **C-5 (F-1, optional)**: Architect may add R13 row; not blocking.

No upstream rollback. PM dispatches Developer with these 5 conditions in the dispatch prompt.
