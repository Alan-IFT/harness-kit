# PM Log — ambient-stream

- Task: ambient-stream — add a minimal "ambient chat-driven stream" mode (start once, no pool-id, keep typing requirements, AI folds each into a default pool and drains until empty; no /loop, no re-invocation)
- Mode: full (7-stage pipeline)
- Started: 2026-06-08
- Developer mode: SINGLE (no `.harness/agents/dev-*.md` partition agents found)

## Pre-flight (How-to-start contract)

- 2026-06-08 · Created `docs/features/ambient-stream/` + this PM_LOG.
- 2026-06-08 · Checked `.harness/intervention.md` → ABSENT (no pending intervention).
- 2026-06-08 · Read `.harness/insight-index.md` (26 data lines). Surfacing relevant entries into SA/Dev dispatch:
  - L17 pwsh hooks need `-NoProfile` (p50 3.7s vs 10ms).
  - L30 settings.json schema breaks two ways (key placement inside `hooks`; `$schema` missing `.json`) — consult upstream first; J.1 gates it.
  - L11 new `{{...}}` placeholder → BOTH verify_all D.2 whitelists.
  - L16/L20/L23 PS string operators case-insensitive by default — use `-cmatch`/`-ccontains`/`-cnotin` for fixed-case contracts in new PS logic.
  - L31 a script's repo-root derivation is depth-sensitive — `.harness/scripts/` is two levels up.
  - L21 doc-resync sweeps forget CHANGELOG — include it explicitly.
  - L33 count/version claim change is version-worthy (G.4) — minimal version aims to NOT change counts.
  - L10 Edit tool may report SUCCESS without applying — re-Read/Grep to verify.
  - L12 sync-self syncs `.harness/agents/` + 4 script pairs only, NOT rules.
- 2026-06-08 · Read `docs/tasks.md` — most relevant prior: parallel-stream was deferred (commit 01502c0); `/harness-stream` shipped v0.22.0 (commit 2e134ea) with ADD intervention keyword. Existing `harness-stream` SKILL.md already has living-pool draining via pm-orchestrator; this task ADDS no-arg default pool + ambient enter/exit + UserPromptSubmit heartbeat hook. Added `ambient-stream` row with `mode: full`.
- 2026-06-08 · Read `docs/dev-map.md` — relevant modules: `skills/harness-stream/SKILL.md`, `skills/harness-init/templates/common/.claude/settings.json.tmpl`, `.harness/scripts/`, `templates/common/.harness/scripts/`, README EN+zh, CHANGELOG, AI-GUIDE, dev-map.

## Stage transitions

### Stage 1 — requirement-analyst (2026-06-08)
- Dispatched RA (mode: full). Wrote `INPUT.md` + `01_REQUIREMENT_ANALYSIS.md`.
- Verdict: **READY**. 15 in-scope behaviors, 13 ACs, 2 open questions delegated to SA (default-pool seed content; enter/exit surface) — both intra-design refinements with recommended defaults, bounded by the converged design. No blocking ambiguity.
- Intervention check after stage: ABSENT.
- Decision: **ADVANCE to Stage 2 (solution-architect)**.

### Stage 2 — solution-architect (2026-06-08)
- Dispatched SA with surfaced insights (L17/L30/L11/L16-L20-L23/L31/L21/L33). Wrote `02_SOLUTION_DESIGN.md`.
- Key design decisions: ENHANCE harness-stream (no new skill); flag = `.harness/ambient.flag` (gitignored, beside intervention.md); enter/exit via chat keywords ("ambient on"/"ambient off"); default pool `docs/batches/default/BATCH_PLAN.md` auto-created from `_template` with EMPTY table; new `UserPromptSubmit` hook `ambient-prompt.{ps1,sh}` twins (dogfood+template) using guard-rm's `.git`-walk shape, always exit 0, prints instruction only when flag present; NO new placeholder (literal command + root `_ambient_hook` doc key); add `ambient-prompt` to F.1 list (not a lettered check); no version/count bump.
- Verdict: **READY**. Both RA open questions resolved within converged design.
- Intervention check after stage: ABSENT.
- Decision: **ADVANCE to Stage 3 (gate-reviewer)**.

### Stage 3 — gate-reviewer (2026-06-08)
- Dispatched GR (mode: full). Independently verified design claims against live files: F.1 list (both shells), J.1 enum has UserPromptSubmit (both shells), D.2 untouched by no-placeholder path, .gitignore convention, guard-rm shape, settings tmpl/dogfood hook shape, stream loop reuse, _template transform, all 26 insights non-contradicting.
- 8/8 dimensions PASS. 3 WARNs (W1 template-twin not machine-guarded → QA byte-compare; W2 no dogfood F-check for ambient since propose-only; W3 placeholder-vs-literal trade accepted) → folded into Conditions C1-C5.
- Verdict: **APPROVED WITH CONDITIONS** (explicit PASS-class verdict; Stage-4 gate satisfied).
- Intervention check after stage: ABSENT.
- Decision: **ADVANCE to Stage 4 (developer)** honoring C1-C5. Single Developer mode.

### Stage 4 — developer (2026-06-08)
- Dispatched generic `developer` (single mode) with surfaced insights + C1-C5. All code/doc edits completed:
  - NEW: `.harness/scripts/ambient-prompt.{ps1,sh}` (dogfood) + `skills/harness-init/templates/common/.harness/scripts/ambient-prompt.{ps1,sh}` (template) — byte-identical content per twin.
  - EDIT: `settings.json.tmpl` (UserPromptSubmit + root `_ambient_hook`), `skills/harness-stream/SKILL.md` (Ambient mode section + no-arg pool + description + procedure + hard rule), `.gitignore` (`.harness/ambient.flag`), `verify_all.{ps1,sh}` (F.1 list +ambient-prompt), README EN+zh, CHANGELOG [Unreleased], dev-map, AI-GUIDE.
  - NOT changed: dogfood `.claude/settings.json` (propose-only; exact block in 04 + to be carried to 07).
- C1-C5 all honored. No design drift. 1 insight surfaced (UserPromptSubmit stdout = injected turn context; fail-open exit 0).
- **verify_all NOT executed by Developer — BLOCKED ON CAPABILITY.** This orchestration session exposes only file tools (Read/Write/Edit/Glob/Grep); no Bash/PowerShell execution function is available to run `.harness/scripts/verify_all.ps1`. Per the red line "do not declare done until verify_all PASSes" + insight L32 (no fabricated tallies) + the qa iron rule "no tool evidence = no claim", I will NOT paste a fake PASS Summary.
- Intervention check after stage: ABSENT.

### Stage gate (before Stage 5) — NOT SATISFIED
- The gate "Stage 4 must show `verify_all` PASSED" cannot be met in this session because no shell-execution capability exists here. The developer agent's contract has `Bash, PowerShell` tools and QA's too — in a normal Claude Code session these run; in THIS session they are not in the available function set.
- **PM decision: HARD STOP — BLOCKED ON CAPABILITY (missing shell execution).** Per pm-orchestrator "When to stop and ask the user" → "An agent reports a missing external capability". I do NOT advance to Code Review/QA/Delivery on an unverified build, and I do NOT fabricate the gate.
- Remaining work for whoever has shell access (one command, then the pipeline resumes from Stage 5):
  1. `pwsh -NoProfile -File .harness/scripts/verify_all.ps1` (Windows) — expect PASS 32 / WARN 0 / FAIL 0; paste the real Summary into 04 + 07.
  2. If PASS → Code Review (diff the 4 ambient-prompt files for byte-identity per pair) → QA (adversarial: flag ON injects, flag OFF no-op, default-pool auto-create, enter→exit, resume-after-partial-drain, `-NoProfile` present, settings schema valid) → Delivery (carry the propose-only dogfood block) → `archive-task --task ambient-stream`.
  3. If FAIL → route back to Stage 4 with the failing check.
