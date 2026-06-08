# 03 — Gate Review: ambient-stream

> Stage 3 · gate-reviewer · mode: full · 2026-06-08
> Inputs: `01_REQUIREMENT_ANALYSIS.md` (READY), `02_SOLUTION_DESIGN.md` (READY).
> Independent verification: claims checked against live files, not trusted.

## Verification performed (code/file reads)

- `verify_all.ps1:270-297` (F.1 + F.2) and `verify_all.sh:283-289` (F.1) — confirmed F.1 pair list is exactly `verify_all, sync-self, harness-sync, test-init, test-real-project` in BOTH shells, and it checks **only dogfood `.harness/scripts/`** existence (NOT template copies). Adding `ambient-prompt` is a one-line list extension, not a new lettered check. **CONFIRMED.**
- `verify_all.ps1:574-621` (J.1) + `verify_all.sh:611-643` — confirmed `UserPromptSubmit` is already in BOTH J.1 hook-event enums (ps1:579, sh:612). No enum change needed; `$schema` canonical constant is `https://json.schemastore.org/claude-code-settings.json` in both. **CONFIRMED.**
- `verify_all.ps1:94-95` (D.2) — allowed-placeholder whitelist is the 7 documented placeholders; design's decision to add NO new placeholder means D.2 is untouched. **CONFIRMED the no-placeholder path is viable.**
- `.gitignore:46-50` — existing `# Harness — ephemeral intervention signal` group ignores `.harness/intervention.md`; adding `.harness/ambient.flag` beside it is consistent. **CONFIRMED convention.**
- `guard-rm.{ps1,sh}` — confirmed the reusable hook shape (stdin JSON read, `.git`-ancestor walk for repo root, exit codes, `set -uo pipefail`, `arr=()`). The design's "reuse the shape, simpler" is accurate. **CONFIRMED.**
- `.claude/settings.json:22-29` (dogfood) — Stop + PreToolUse hooks both use `pwsh -NoProfile -File ...`; design's "mirror this command shape" is grounded; the dogfood file is the propose-only target. **CONFIRMED.**
- `settings.json.tmpl:36-58` — `hooks` object holds Stop + PreToolUse with `{{SYNC_COMMAND}}`/`{{GUARD_COMMAND}}`; root carries `_doc_sync_hook`/`_guard_hook` doc keys (NOT inside `hooks`). Design's "doc key at root, `UserPromptSubmit` inside hooks" matches the existing safe pattern. **CONFIRMED.**
- `skills/harness-stream/SKILL.md` — confirmed the existing Procedure loop (re-read pool, topo frontier, pm-orchestrator dispatch, resume by skipping DELIVERED) is reusable as-is; ambient is a new entry path into the same loop. **CONFIRMED reuse.**
- `docs/batches/_template/BATCH_PLAN.md` — confirmed it has `<batch-id>` + 3 example rows; the design's "copy, replace `<batch-id>`→`default`, strip example rows" is a concrete, doable transform. **CONFIRMED.**
- `.harness/insight-index.md` — checked all 26 data lines: L17 (`-NoProfile`), L30 (schema two-ways), L11 (placeholder→D.2), L16/L20/L23 (PS case operators), L31 (repo-root depth), L21 (CHANGELOG). The design explicitly addresses each (R2, R4, no-placeholder, §3.1 case note, R7 `.git`-walk-not-PSScriptRoot, R8). **No insight contradicts the design.**

## 1. Audit checklist (8 dimensions)

| # | Dimension | Verdict | Reason |
|---|---|---|---|
| 1 | Requirement completeness | PASS | 15 in-scope behaviors are testable; the 2 open questions are resolved in the design (§3.3, §3.4) within the converged scope. |
| 2 | Design completeness | PASS | Every in-scope behavior maps to a design section (no-arg pool §3.4; flag §3.2; enter/exit §3.3; hook §3.1; twins+wiring §2; docs §2). |
| 3 | Reuse correctness | PASS | Reuse audit (§7) cites real files; the stream loop, guard-rm shape, intervention-flag convention, and J.1 enum all verified to exist as claimed. |
| 4 | Risk coverage | PASS | R1-R8 cover the real risks; the missed-risk hunt below adds one WARN (W1) the design partially covers. |
| 5 | Migration safety | PASS | Purely additive; backwards compatible; instant rollback (delete flag). No data migration. |
| 6 | Boundary handling | PASS | RA §4 + design cover flag present/absent, non-requirement message, duplicate, empty pool, idempotent enter/exit, stale flag, concurrency (serial), pwsh cost. |
| 7 | Test feasibility | PASS | All 13 ACs are verifiable (file presence, hook stdout with/without flag, grep `-NoProfile`, J.1, git diff for propose-only). |
| 8 | Out-of-scope clarity | PASS | §10 is explicit: no /loop, no parallel, no new skill/check/placeholder/version bump, hook does not judge "is requirement" (agent does). |

## 2. Findings (WARN — none block development)

- **W1 — Template twin existence is NOT machine-guarded.** F.1 (both shells) checks only the **dogfood** `.harness/scripts/` pair, and `ambient-prompt` is NOT in `sync-self`'s mirror set (E.1), so **nothing in `verify_all` asserts the two TEMPLATE copies (`skills/harness-init/templates/common/.harness/scripts/ambient-prompt.{ps1,sh}`) exist or match the dogfood copies.** The design acknowledges this (R3) and pushes it to a QA byte-compare. This is acceptable for the minimal version (matching how test-* scripts and the template guard-rm copies are handled), but the Developer MUST author all FOUR files in one pass and QA MUST byte-compare dogfood↔template. Responsible doc: design §2 note + R3 (already addressed). **Condition C1 below makes it binding.**
- **W2 — F.2 precedent vs ambient wiring.** F.2 asserts the dogfood `.claude/settings.json` HAS a PreToolUse→guard-rm hook. There is deliberately NO equivalent F-check asserting the dogfood has the `UserPromptSubmit`→ambient hook, because the dogfood settings change is **propose-only** (the human applies it). The Developer must NOT add such an assertion (it would FAIL until the human pastes the block, and the red line forbids the Developer applying it). Responsible: design §2 + red line (already correct). Recorded so the Developer/Reviewer don't "helpfully" add an F-check. **Condition C2.**
- **W3 — Placeholder-vs-literal trade is a judgment call.** Design §5 ships a literal Windows-default command in the template + a root `_ambient_hook` doc-key documenting the non-Windows swap, rather than a new `{{AMBIENT_COMMAND}}` placeholder, to avoid the L11 D.2 fan-out. This is internally consistent with the existing `_doc_sync_hook`/`_guard_hook` OS-swap documentation precedent, and is the correct minimal choice. **Accepted** — but the Developer must put the doc note at ROOT (never inside `hooks`) per J.1/rule 80. **Condition C3.**

No FAIL. No WARN routes back to RA or SA — all are conditions on the Developer, appropriate for full mode.

## 3. High-probability developer questions (pre-answered)

1. **"Where exactly does the hook get the repo root?"** → Use the `.git`-ancestor WALK (copy guard-rm's loop), NOT `$PSScriptRoot` two-up arithmetic (insight L31 / R7). The flag is checked at `<repoRoot>/.harness/ambient.flag`.
2. **"Does the hook need to parse the UserPromptSubmit JSON?"** → No. It may ignore stdin entirely; it only tests flag existence. Read-and-discard stdin is fine (or ignore). It must NEVER block — always exit 0.
3. **"How does the agent receive the instruction?"** → A `UserPromptSubmit` hook's stdout is injected by Claude Code as additional context for that turn. So the hook simply prints the instruction block to stdout. (Do NOT use any block/deny exit semantics.)
4. **"Should I touch the dogfood `.claude/settings.json`?"** → NO. Red line. Produce the EXACT JSON block in `04_DEVELOPMENT.md` for the human; edit ONLY `settings.json.tmpl`.
5. **"Do I need a new `{{...}}` placeholder?"** → No (design §5). Use the literal `pwsh -NoProfile -File .harness/scripts/ambient-prompt.ps1` in the template + a root `_ambient_hook` doc key for the bash swap. So D.2 whitelists are NOT touched.
6. **"Will this bump the version or a count claim?"** → No. F.1 list extension is not a lettered check; no skill added; no count claim changes. Add only a CHANGELOG `[Unreleased]` entry. Run G.3/G.4 to confirm green without a bump.

## 4. Conditions (APPROVED WITH CONDITIONS)

- **C1** — Author ALL FOUR ambient-prompt files (dogfood `.ps1`+`.sh` AND template `.ps1`+`.sh`) in one pass; keep them byte-aware in lockstep (sync-self does NOT mirror them). QA byte-compares dogfood↔template.
- **C2** — Do NOT add any `verify_all` check asserting the dogfood `.claude/settings.json` has the ambient hook (it is propose-only). Adding `ambient-prompt` to the F.1 pair list is allowed and expected (dogfood pair existence only).
- **C3** — Any settings.json doc note goes at ROOT (`_ambient_hook`), never inside the `hooks` object (J.1 / rule 80). Keep `$schema` canonical `.json`. pwsh command MUST include `-NoProfile`.
- **C4** — Doc sweep MUST include CHANGELOG.md (`[Unreleased]`) + harness-stream SKILL.md + README EN+zh + dev-map.md (+ AI-GUIDE.md for the new script pair). No version/count token changes (insight L21, L33).
- **C5** — verify_all MUST PASS on the user's shell (Windows → `.ps1`); keep both F.1 twins and both ambient-prompt twins in lockstep.

## 5. Verdict

**APPROVED WITH CONDITIONS** — requirement and design are complete, feasible, and grounded; all conditions C1-C5 are developer-time constraints already anticipated by the design. Development may proceed to Stage 4 honoring C1-C5.
