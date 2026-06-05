---
applyTo: "**"
---
# harness-kit — bootstrap rules

Output language: **English**.

The full project ruleset lives in `AI-GUIDE.md` (root) and `.harness/rules/*.md`. **Before starting any task, read `AI-GUIDE.md` once and then selectively load only the rule fragments whose "when to read" trigger applies** — do not load all of them.

Red lines (never violate):
- Do not hand-edit `.claude/` — it is agent runtime config: `settings.json` is the live startup config (propose changes; the user applies them), `agents/`+`skills/` are sync-generated from `.harness/` (edit the source there).
- Do not edit `CLAUDE.md` or this file — static stubs, written once at init.
- Do not declare a task done until `.harness/scripts/verify_all` PASSes
- One role at a time **unless the user has explicitly enabled continuous mode** (see `60-tool-handoff.md`). Read the relevant `.harness/agents/<name>.md` and follow that contract; do not silently switch roles mid-turn

This file is **static** — written once and intentionally minimal so it never inflates the persistent context budget. Everything else is in `AI-GUIDE.md` or `.harness/`.
