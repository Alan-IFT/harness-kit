# INPUT — ai-safety-guardrails

**Submitted by user, 2026-05-16**

> 以用户体验好，符合软件工程标准，长期易使用易维护为原则来决策；你来决策就可以了，我只看结果是否符合需求；所以需要你根据我要求的原则来决策，然后执行，最后返回给我改动详情，当前情况等我需要关注的信息；所有commit都由你来操作

> 当前架构，好像没法实现当在github copilot中使用时，copilot自动扮演agent实现按架构顺序开发（已实现？）；当在cladue code，自动让claude code创建sub agent，调用agent team实现快速开发（未实现？）；还需要增加rm项目外内容都限制检查钩子（这个功能要能实现在所有使用harness-kit的项目上自动添加，避免AI出现不可控行为）

## PM-extracted scope (decided by PM under user mandate "你来决策就可以了")

The user raised three concerns; PM interprets them as one cohesive task — **AI safety guardrails** — with three deliverables:

### D1. Clarify Copilot agent-flow behavior (documentation)
The user asks: *"is Copilot auto-routing through agents already implemented?"* Current design (see `.harness/rules/60-tool-handoff.md`) is intentional **manual one-role-at-a-time** — Copilot has no programmatic sub-agent dispatch, so user-driven role switching is the safe pattern. Deliverable: a clearer statement of this **in `AI-GUIDE.md` and `60-tool-handoff.md`**, plus an **opt-in "continuous mode"** instruction that lets Copilot self-route stages 1→7 inside one chat when the user explicitly asks (`走全流程` / `continuous mode`) — with a hard "STOP and ask user at every Gate Review" safety check.

### D2. Confirm Claude Code sub-agent dispatch (documentation)
The user asks: *"is Claude Code auto-sub-agent dispatch not yet implemented?"* It **is** implemented — PM Orchestrator already uses Claude Code's `Task` tool to spawn sub-agents (see `.harness/agents/pm-orchestrator.md` lines 5, 108-129). Deliverable: a one-paragraph callout in `AI-GUIDE.md` + a status snippet in `harness-status` skill so the next user doesn't have the same misconception.

### D3. Add an "rm outside project" safety hook (real feature)
The user wants a hook that blocks AI from running destructive commands (`rm`, `Remove-Item`, `del`, `rmdir`, etc.) targeting paths **outside the current project root**. It must auto-install on **every** project that uses harness-kit — both new (`/harness-init`) and existing-but-adopted (`/harness-adopt`), and on the dogfood repo itself.

Constraints under user's stated principles ("good UX, SE standards, long-term maintainable"):
- Must not break legitimate in-project deletes (build artifacts, temp files).
- Must work cross-platform: bash + PowerShell.
- Must be tool-agnostic in spirit, even if mechanically Claude-Code-bound (Claude Code is the only AI tool here with programmatic hooks; for Copilot/Cursor it remains documented best-practice + the deny list in `.claude/settings.json`).
- Must be visible / overridable (good UX): the user must be able to see why a command was blocked and explicitly override if they meant it.

## Acceptance signal

- `scripts/verify_all` PASS
- The three deliverables exist and are self-consistent across `.harness/`, `templates/`, dogfood `.claude/`, and `docs/`.
- The user can read 07_DELIVERY.md and understand: (a) the current state of D1+D2, (b) what changed for D3, (c) anything they need to do.
