# Delivery Summary

- **Task:** `ambient-stream` — minimal "ambient chat-driven stream": start once with no pool-id, then every chat message folds a requirement into the default pool and drains it through the pipeline (no `/loop`, serial, resume free).
- **Mode:** full (7-stage)
- **Stages traversed:** 1 RA (2026-06-08, READY) → 2 SA (READY) → 3 Gate (APPROVED WITH CONDITIONS C1-C5) → 4 Developer (complete, C1-C5 honored) → 5 Code Review (APPROVED, 0 BLOCKER/MAJOR/MINOR) → 6 QA (PASS, 0 defects) → 7 Delivery (this doc).
- **Rollbacks:** 0.
- **Final verify_all result:** **PASS — 32 / WARN 0 / FAIL 0** (run twice via `verify_all.sh`: once by the PM, once independently by QA; both exit 0). PowerShell `.ps1` twin was NOT executed — PowerShell is denied in this session — but is byte-identical-in-logic to the `.sh` (Code Review + QA confirmed) and is covered by F.1 symmetry; **the user should run `verify_all.ps1` once on Windows to close AC-11(.ps1).**
- **Baseline changes:** none. `verify_all` check count stays **32**; plugin version stays **0.22.0**; skill count stays **12**. No new lettered check, no new placeholder, no version/count bump (CHANGELOG entry is under `[Unreleased]`).
- **Outstanding risks:**
  1. The dogfood `.claude/settings.json` hook is **proposed, not applied** (red line). Ambient mode is inert in THIS repo until the user pastes the `UserPromptSubmit` block (below). For end users of harness-kit it ships wired via the template `settings.json.tmpl`.
  2. `.ps1` hook + `verify_all.ps1` await a one-time Windows execution by the user.
  3. The dogfood↔template byte-identity of `ambient-prompt.{ps1,sh}` is held by discipline (sync-self does not mirror them; F.1 checks existence only) — Code Review + QA confirmed identity at this delivery.

## Files changed (this task; `docs/system-overview.html` is a pre-existing untracked file, unrelated — untouched)

New:
- `.harness/scripts/ambient-prompt.ps1`, `.harness/scripts/ambient-prompt.sh` (dogfood hook twins)
- `skills/harness-init/templates/common/.harness/scripts/ambient-prompt.ps1`, `…/ambient-prompt.sh` (template twins)
- `docs/features/ambient-stream/` (stage docs 01-07 + PM_LOG)

Modified:
- `skills/harness-stream/SKILL.md` (Ambient mode section, no-arg default pool, frontmatter, Procedure step 1, hard rule)
- `skills/harness-init/templates/common/.claude/settings.json.tmpl` (UserPromptSubmit hook `-NoProfile` + root `_ambient_hook` doc key)
- `.harness/scripts/verify_all.ps1`, `…/verify_all.sh` (F.1 pair list += `ambient-prompt`)
- `.gitignore` (`.harness/ambient.flag`)
- `README.md`, `README.zh-CN.md`, `CHANGELOG.md`, `AI-GUIDE.md`, `docs/dev-map.md`, `docs/tasks.md`

NOT changed (red line): `.claude/settings.json` (dogfood — propose-only).

## Propose-only dogfood `.claude/settings.json` change (apply by hand to activate ambient mode in THIS repo)

Add inside the top-level `hooks` object, after the existing `PreToolUse` entry:

```json
    "UserPromptSubmit": [
      { "hooks": [ { "type": "command", "command": "pwsh -NoProfile -File .harness/scripts/ambient-prompt.ps1" } ] }
    ]
```

Optional root doc key (after `_guard_hook`, mirroring the existing doc keys — it must be at ROOT, never inside `hooks`):

```json
  "_ambient_hook": "UserPromptSubmit hook runs ambient-prompt on every user turn. No-op unless .harness/ambient.flag exists; when present, injects an ingest+drain instruction for docs/batches/default/BATCH_PLAN.md. -NoProfile required. macOS/Linux: bash .harness/scripts/ambient-prompt.sh. See skills/harness-stream/SKILL.md 'Ambient mode'.",
```

J.1-clean: `UserPromptSubmit` is a valid hook event; doc key at root; `$schema` stays the canonical `.json` URL.

## How to use it (after applying the block)

1. Enter ambient mode: say **"ambient on"** (中文 **"开启环境模式"**), or invoke `/harness-stream` with no pool-id. The skill writes `.harness/ambient.flag` and ensures `docs/batches/default/BATCH_PLAN.md` exists (empty table).
2. Just type requirements. Each message is folded into the default pool and ready tasks are drained through the full pipeline until the pool is empty, then it waits.
3. Leave ambient mode: say **"ambient off"** (中文 **"关闭环境模式"**) or delete `.harness/ambient.flag`.

Limitation by design: ambient mode advances **on your messages** (your typing is the heartbeat) — it does not progress while you are silent. Unattended/idle progress is a separate `/loop` concern, intentionally out of scope for this minimal version.

## Insight

- 2026-06-08 · A Claude Code `UserPromptSubmit` hook's stdout is injected into the turn as added context, so a flag-gated hook that prints an instruction block (and nothing when the flag is absent) is enough to turn each user message into a scheduler heartbeat — no `/loop`, no background process — provided the hook always exits 0 (fail-open) so a bug never wedges chat. · evidence: ambient-stream, .harness/scripts/ambient-prompt.{ps1,sh}
