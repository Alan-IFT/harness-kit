# Development Record — ambient-stream

> Stage 4 · developer · mode: full · 2026-06-08
> Inputs: 01 (READY), 02 (READY), 03 (APPROVED WITH CONDITIONS, C1-C5).

## Summary

Implemented the minimal ambient chat-driven stream as an enhancement to the existing `/harness-stream` skill (no new skill). Added the no-arg default-pool path, the `.harness/ambient.flag` gate, ambient enter/exit chat keywords, and a new `UserPromptSubmit` heartbeat hook (`ambient-prompt.{ps1,sh}`) shipped in both the dogfood `.harness/scripts/` and the distributed template, wired into the template `settings.json.tmpl` with `-NoProfile`. The dogfood `.claude/settings.json` change is PROPOSED only (block below), not applied. No new placeholder, no new verify_all lettered check, no version/count bump.

## Files changed

- `.harness/scripts/ambient-prompt.ps1` — NEW. UserPromptSubmit hook (dogfood, Windows). Drains stdin, walks to `.git` root, no-op unless `.harness/ambient.flag` exists; when present prints the ingest+drain instruction block to stdout. Always exits 0 (never blocks a turn). `$ErrorActionPreference='SilentlyContinue'` for fail-open.
- `.harness/scripts/ambient-prompt.sh` — NEW. Unix twin (byte-aware lockstep with the .ps1 semantics). `set -uo pipefail`, no arrays, `.git`-walk, `[[ -f flag ]]` gate, here-doc instruction block, exit 0.
- `skills/harness-init/templates/common/.harness/scripts/ambient-prompt.ps1` — NEW. Template copy (byte-identical to the dogfood .ps1, minus nothing — identical content).
- `skills/harness-init/templates/common/.harness/scripts/ambient-prompt.sh` — NEW. Template copy (byte-identical to the dogfood .sh).
- `skills/harness-init/templates/common/.claude/settings.json.tmpl` — EDIT. Added a root `_ambient_hook` doc key (documents the no-op-unless-flag behavior + the non-Windows `bash` swap + the `-NoProfile` rationale) and a `UserPromptSubmit` entry inside `hooks` with command `pwsh -NoProfile -File .harness/scripts/ambient-prompt.ps1`. `$schema` unchanged (canonical `.json`). No doc key inside `hooks` (J.1-clean).
- `skills/harness-stream/SKILL.md` — EDIT. New "Ambient mode (no-arg default pool + chat heartbeat)" section (how it works / enter-exit / per-turn behavior / ambient-vs-/loop); updated "The pool" with the no-arg auto-create branch; updated the frontmatter `description`; updated Procedure step 1 for the no-arg default-pool path; added an ambient hard rule.
- `.gitignore` — EDIT. Added `.harness/ambient.flag` (transient runtime state, beside `.harness/intervention.md`).
- `.harness/scripts/verify_all.ps1` — EDIT. F.1 pair list + step name gain `ambient-prompt` (dogfood pair existence; NOT a new lettered check).
- `.harness/scripts/verify_all.sh` — EDIT. F.1 pair list gains `ambient-prompt` (twin).
- `README.md` — EDIT. Ambient note appended to the harness-stream bullet.
- `README.zh-CN.md` — EDIT. 中文 ambient 说明 appended to the harness-stream bullet.
- `CHANGELOG.md` — EDIT. New `[Unreleased]` "Added — ambient chat-driven stream mode" subsection.
- `docs/dev-map.md` — EDIT. Added `ambient-prompt.{ps1,sh}` to the scripts tree + `default/` note on the batches dir.
- `AI-GUIDE.md` — EDIT. Added the `ambient-prompt.{ps1,sh}` line under "Scripts (the moving parts)".

NOT changed (red line, propose-only): `.claude/settings.json` (dogfood).

## Proposed dogfood `.claude/settings.json` change (PROPOSE-ONLY — do NOT apply automatically)

Add this block to the `hooks` object of `c:\Programs\HarnessEngineering\.claude\settings.json` (after the existing `PreToolUse` entry), and optionally add the matching `_ambient_hook` doc key at root (mirroring `_doc_sync_hook` / `_guard_hook`). The dogfood is Windows, so the command is the `.ps1` with `-NoProfile`:

```json
    "UserPromptSubmit": [
      { "hooks": [ { "type": "command", "command": "pwsh -NoProfile -File .harness/scripts/ambient-prompt.ps1" } ] }
    ]
```

After paste, the `hooks` object should read (Stop + PreToolUse unchanged, UserPromptSubmit added):

```json
  "hooks": {
    "Stop": [
      { "hooks": [ { "type": "command", "command": "pwsh -NoProfile -File .harness/scripts/harness-sync.ps1" } ] }
    ],
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [ { "type": "command", "command": "pwsh -NoProfile -File .harness/scripts/guard-rm.ps1" } ] }
    ],
    "UserPromptSubmit": [
      { "hooks": [ { "type": "command", "command": "pwsh -NoProfile -File .harness/scripts/ambient-prompt.ps1" } ] }
    ]
  }
```

(Optional root doc key, right after `_guard_hook`:)

```json
  "_ambient_hook": "UserPromptSubmit hook runs ambient-prompt on every user turn. No-op unless .harness/ambient.flag exists; when present, injects an ingest+drain instruction for docs/batches/default/BATCH_PLAN.md. -NoProfile required. macOS/Linux: bash .harness/scripts/ambient-prompt.sh. See skills/harness-stream/SKILL.md 'Ambient mode'.",
```

This keeps the dogfood J.1-clean: `UserPromptSubmit` is a valid hook event; the doc key is at root, not inside `hooks`; `$schema` stays canonical.

## verify_all result

**BLOCKED ON CAPABILITY — could not execute `verify_all`.** The Developer agent in this session has only file tools (Read/Write/Edit/Glob/Grep); no shell-execution tool (Bash/PowerShell) is available to actually run `.harness/scripts/verify_all.ps1`. Per the qa/dev iron rule "no tool evidence = no claim" and insight L32 (a reported tally never produced by a real run is a defect), I am NOT pasting a fabricated PASS Summary.

Static verification performed instead (each of the 32 checks reasoned against the live diff; see 03_GATE_REVIEW verification + below). I assert no check is *expected* to regress, but this is NOT a substitute for a real run:

- **F.1** — `ambient-prompt.ps1`/`.sh` exist in dogfood `.harness/scripts/`; list extended in both shells. Expected PASS.
- **F.2** — dogfood `.claude/settings.json` PreToolUse→guard-rm untouched. Expected PASS.
- **J.1** — template `settings.json.tmpl`: `$schema` canonical; `UserPromptSubmit` is in the J.1 enum (ps1:579 / sh:612); the only new `hooks` child key is `UserPromptSubmit` (4-space indent); `_ambient_hook` is at root. Dogfood unchanged. Expected PASS.
- **D.2** — no new `{{...}}` placeholder added (literal command used). Whitelist untouched. Expected PASS.
- **E.1** — `ambient-prompt` not in sync-self's mirror set; agents + the 4 mirrored scripts untouched. Expected PASS.
- **E.4b** — no new rule file. Expected PASS.
- **G.1/G.2/G.3/G.4** — skill mentions intact; version stays 0.22.0; count stays 32; CHANGELOG `[0.22.0]` heading present. Expected PASS.
- **I.1** — AI-GUIDE.md now 102 lines (cap 200). **I.4** — insight-index 26 evidence lines (cap 30). **I.2/I.3/I.5** — no rule/agent/tasks oversize introduced. **I.6** — no retired-claim phrases introduced; `docs/features/` exempt anyway. Expected PASS/WARN-free.

**The PM MUST run `.harness/scripts/verify_all` (Windows → `.ps1`) before Code Review/QA/Delivery and treat its real Summary as the gate.** If it FAILs, route back here.

## Design drift

None. Implementation matches `02_SOLUTION_DESIGN.md` exactly (default pool path, flag path, enter/exit keywords, hook contract, no-placeholder decision, F.1 extension). C1-C5 honored:
- C1: all four ambient-prompt files authored in one pass with identical content.
- C2: no verify_all check asserting the dogfood ambient hook; F.1 list extended only.
- C3: doc note at root `_ambient_hook`; `$schema` canonical; `-NoProfile` present.
- C4: CHANGELOG + SKILL.md + README EN/zh + dev-map + AI-GUIDE all swept.
- C5: both F.1 twins and both ambient-prompt twins in lockstep.

## Open issues for review

- The ambient-prompt dogfood↔template byte-identity is by discipline (sync-self does not mirror it; F.1 only checks existence). Code Reviewer should diff the two .ps1 and the two .sh for byte-identity; QA should byte-compare too (R3 / C1).
- verify_all was NOT run by the Developer (capability gap). The real run is a hard gate the PM/QA must execute.

## Dev-map updates

- Added `.harness/scripts/ambient-prompt.{ps1,sh}` line under the scripts tree.
- Annotated `docs/batches/` with the `default/` no-arg ambient pool note.

## Insight to surface

- 2026-06-08 · A Claude Code `UserPromptSubmit` hook's stdout is injected into the turn as added context, so a flag-gated hook that prints an instruction block (and nothing when the flag is absent) is sufficient to turn each user message into a scheduler heartbeat — no `/loop`, no background process; the hook must always exit 0 (fail-open) so a bug never wedges chat. · evidence: ambient-stream, .harness/scripts/ambient-prompt.{ps1,sh}

## Verdict

READY FOR REVIEW (with the explicit BLOCKED-ON-CAPABILITY caveat: verify_all not executed by Developer; PM must run it as the gate).
