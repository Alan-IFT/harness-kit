# 05 — Code Review · ai-safety-guardrails

- Task: `T-001 / ai-safety-guardrails`
- Mode: `full`
- Reviewer: Code Reviewer
- Date: 2026-05-17

## Gate condition verification

| Condition | Verdict | Evidence |
|---|---|---|
| **C-1**: `test-init.{ps1,sh}` asserts PreToolUse + guard-rm in fixture | PASS | `test-init.ps1:249-263` (5 PS asserts × 3 project types); `test-init.sh:188-249` (mirror with python3-real-probe + grep fallback). |
| **C-2**: AI-GUIDE.md script-pairs line accurate | PASS | `AI-GUIDE.md:69` reads "+ 4 script pairs (harness-sync, install-hooks, archive-task, guard-rm)" — 4 names = 4 count. Pre-existing 4/3 drift fixed. |
| **C-3**: `40-locations.md` placeholder count says "(7 allowed)" | PASS | `40-locations.md:29`. Matches the 7-entry whitelist in `verify_all.{ps1,sh}` D.2. |
| **C-4**: Multi-surface consistency | PASS | 3× 60-tool-handoff with identical Copilot continuous-mode subsection; 3× copilot-instructions.md with the "unless ... continuous mode" red line; 3× AI-GUIDE with 75-safety-hook index + sub-agent callout + AI-tool-flow-modes section. zh translations use 连续模式 / 走全流程 / 子 agent 派发. |

## 6-dimension audit

| # | Dimension | Verdict | Reasoning |
|---|---|---|---|
| 1 | Logic correctness | PASS w/ MINORS | Algorithm matches design §4.2 step-by-step. Tokenizer quote-aware; sudo-strip handles `-E`/`-H`/`-u <user>`; nested pwsh depth-2 cap → BLOCK; `..` normalization safe; leaf-only symlink policy. One MINOR robustness gap in bash JSON extractor (M-1). |
| 2 | Requirement fidelity | PASS | All 19 in-scope items + A/B/C/D acceptance criteria mapped (table below). |
| 3 | Design fidelity | PASS | BLOCK message verbatim per §4.4; F.2 ID per §6.1; `{{GUARD_COMMAND}}` placeholder preserved; sync-self diff matches §10. F-5 gate-finding correctly identified as misread (template `F.*` = user-project size-WARN group, dogfood `I.*` is the rename — verified in `templates/generic/scripts/verify_all.ps1.tmpl:151-204`). |
| 4 | Performance | PASS w/ MINOR | PS guard avoids spawning git; straight-line `.git/` walk. Bash guard probes python3 with real invocation before trusting it. MINOR: bash + python3 fallback spawns 2-3 subprocesses on Git-Bash-Windows (M-2). |
| 5 | Security | PASS | Override env var per-call only; no committed file sets `HARNESS_ALLOW_OUTSIDE_RM=1` (Grep verified). Existing `Bash(rm -rf /:*)` deny kept. BLOCK includes absolute path + repoRoot for observability. 8 KB truncation defends against pathological inputs. |
| 6 | Maintainability | PASS w/ MINORS | Code commented at section boundaries; algorithm pseudo-code recognizable in source. Three nits: `_TOKENS`/`_SEGS` globals (necessary; noted in code), hard-coded verb list (per req §1), JSON-key pseudo-comments (idiomatic). |

## Findings (severity-ranked)

### CRITICAL — none

### MAJOR — none

### MINOR

- **[M-1] `scripts/guard-rm.sh:48-55`** — JSON command extractor regex over-captures when payload contains additional keys after `command`. Mitigation: tokenizer-failure → exit 0 (allow) for unknown verbs OR → BLOCK for unbalanced quotes; python3-first path avoids this entirely. Latent fragility; non-blocking.
- **[M-2] `scripts/guard-rm.sh:30-32`** — Bash fallback spawns python3 twice (probe + parse); 50-200ms on Git-Bash-Windows, exceeds 50ms NFR there. Acceptable: dogfood is Windows-pwsh; native Unix bash is ~1ms. CHANGELOG note recommended.
- **[M-3] `scripts/guard-rm.ps1:62`** — `$findPredicates` array conflated with non-find flag skip; fail-open safe (rm doesn't take -name) but worth documenting.
- **[M-4] `scripts/test-init.sh:23`** — pre-existing `declare -a failures`; safe under happy path (no empty-array read). Out of scope.
- **[M-5] `scripts/guard-rm.ps1:202`** — Pwsh `/c` detection slightly broader than design (harmless).
- **[M-6] `scripts/guard-rm.ps1:170-179`** — `__PARSE_FAIL__` sentinel string is fragile (extremely unlikely collision); `[ref]$parseFailed` would be cleaner.

### NIT

- **[N-1]** `test-guard-rm.ps1:36` — env-var reset before each iteration but only re-set inside `if ($c.override)`; order-coupling smell since override case is last.
- **[N-2]** `.claude/settings.json:21, 32` — JSON-pseudo-comment underscore keys (consistent with v0.9 pattern).
- **[N-3]** Unbalanced-quote case not exercised by fixture; consider adding `rm -rf "/etc/foo` → BLOCK case.
- **[N-4]** `docs/tasks.md:9` row `T-001` stage = `code-review` (correct in-flight state).

## Requirement coverage

| Criterion | Implementation | Status |
|---|---|---|
| A1-A5 (D1+D2 docs) | AI-GUIDE × 3, 60-tool-handoff × 3, copilot-instructions × 3, harness-status SKILL.md §3b | OK |
| B1 (guard-rm in 4 surfaces) | dogfood + template SOT, ps1+sh | OK |
| B2 (11 fixtures + driver) | `evals/guard-rm-cases.md` + `test-guard-rm.{ps1,sh}` 11/11 PASS | OK |
| B3/B4 (live transcript) | DEFERRED to QA | DEFERRED |
| C1-C8 (install surfaces) | settings.json × 2, harness-init/adopt/status SKILL, sync-self × 2, verify_all F.2 × 2, test-init × 2, 75-safety-hook × 3 | OK |
| D1 (verify_all PASS) | 27/27 (PM-verified) | OK |
| D2 (tasks.md done) | DEFERRED to stage 7 | DEFERRED |
| D3 (CHANGELOG entry) | `CHANGELOG.md` 0.15.0 section covers D1+D2+D3 | OK |
| D4 (README badges) | both READMEs at 0.15.0 / 27/27 / 177/177; v0.15.0 roadmap row | OK |
| D5 (adversarial test for override) | DEFERRED to QA | DEFERRED |

## Verdict

**APPROVED**

No CRITICAL or MAJOR findings. All 4 gate conditions C-1..C-4 verified satisfied. All 19 in-scope items map to implementations. Design fidelity high; developer's two principled deviations (F-5 misread + C-2 fix-don't-propagate) check out under inspection. Six MINORs and four NITs are notes for follow-up — none block merge. Routing to PM for QA dispatch (stage 6).
