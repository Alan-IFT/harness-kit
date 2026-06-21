# Task Input — resilient-hooks (T-12)

**Mode:** full · **Dispatched by:** /harness-stream default pool, PM in main thread (sub-agents: Bash yes, PowerShell/Task no).
**deferred-human mode:** defer, do not ask.
**Depends on:** — (independent).

## Goal (one sentence)

Eliminate the per-turn `Stop hook error: bash: .harness/scripts/harness-sync.sh: No such file or directory` by (A) making the harness lifecycle hooks **fail-open and cwd-independent** (guard the script path + anchor it to `$CLAUDE_PROJECT_DIR`, so a missing/unreachable/wrong-OS script no-ops silently instead of erroring every turn), and (B) stopping the plugin from distributing this repo's **dogfood `.claude/settings.json`** (move the dev hooks to a gitignored `.claude/settings.local.json` so the published plugin carries no leakable hooks).

## Root-cause analysis (confirmed this session — build on it, re-verify before relying)

A real consumer report: every turn errors `Stop hook error: ... bash: .harness/scripts/harness-sync.sh: No such file or directory`.

**Layer 1 — the ACTIVE cause: the Stop hook is brittle.** A harness project's `.claude/settings.json` wires `Stop → {{SYNC_COMMAND}}` = `bash .harness/scripts/harness-sync.sh` (Unix) or `pwsh -NoProfile -File .harness/scripts/harness-sync.ps1` (Windows) — a RELATIVE path with NO existence guard. The hook fires on EVERY turn. If the script can't be resolved at hook time, the interpreter emits "No such file or directory" and Claude Code surfaces it every turn. The script is unresolvable when: (a) it's missing (project predates the v0.20 `.harness/scripts/` relocation, or a partial setup), (b) Claude Code was launched from a SUBDIRECTORY so the relative path doesn't resolve against the project root, or (c) the OS variant mismatches. The error's `bash` variant confirms it is a PROJECT-level hook (non-Windows or hand-switched per the `_doc_sync_hook` note), NOT this repo (whose dogfood hook is the pwsh variant) and NOT a plugin leak.
- T-020 (v0.31.0) only attacked this from the "ensure the script lands" side (presence-gated rewire + congruence assert in init/adopt/upgrade/migrate). It did NOT make the hook itself resilient, so it does nothing for projects set up before v0.31.0, cwd mismatches, or any later disappearance. **The hook itself must degrade gracefully.**

**Layer 2 — a LATENT hygiene defect (not the active cause): the plugin ships dogfood settings.** Every cached plugin version (0.19.0–0.31.0) bundles this repo's root `.claude/settings.json` (the dev/dogfood hooks). Per Claude Code docs (confirmed via claude-code-guide): a plugin's bundled `.claude/settings.json` is **NOT loaded** as active hooks — plugin hooks must live in `hooks/hooks.json` or the `plugin.json` `hooks` field, using `${CLAUDE_PLUGIN_ROOT}` paths, and hook commands run with cwd = the user's project. So the bundled dogfood settings is inert for users today, but distributing dev config is wrong and a future Claude Code change or a user copying it could activate it. Clean it up.

## Authoritative Claude Code facts (from claude-code-guide, this session)
- Plugin hooks load ONLY from `hooks/hooks.json` or `plugin.json` `hooks` field — NOT from a plugin's bundled `.claude/settings.json`.
- Plugin/user hook commands run with **cwd = the user's current project** (so a project-relative path needs `$CLAUDE_PROJECT_DIR` to be cwd-robust).
- `.claude/settings.local.json` is the correct home for personal/dogfood hooks that must NOT be committed/distributed (gitignored, local-only, same load precedence for local dev).

## Scope guidance (for the analyst — make testable; REUSE; keep lightweight; decompose if needed)

In scope:
1. **(A) Resilient hook command form** for the harness lifecycle hooks (at least the Stop/harness-sync hook; assess whether the PreToolUse/guard-rm, UserPromptSubmit/ambient-prompt, SessionStart/ambient-reset hooks need the same — guard-rm especially must NOT be weakened). The new form: anchor the script to `$CLAUDE_PROJECT_DIR` AND no-op silently (exit 0) when the script is absent. Design the EXACT Unix (bash) and Windows (pwsh) command strings. Apply to: the distributed template `skills/harness-init/templates/common/.claude/settings.json.tmpl` (+ the `{{SYNC_COMMAND}}`/`{{GUARD_COMMAND}}` derivation in harness-init / harness-adopt), and the `/harness-upgrade` + `migrate-scripts-layout` repair path so EXISTING projects get rewritten to the resilient form.
2. **(B) Stop distributing dogfood hooks**: move this repo's root `.claude/settings.json` hooks (Stop/PreToolUse/UserPromptSubmit/SessionStart) to `.claude/settings.local.json` (gitignored), leaving the committed/distributed `.claude/settings.json` with NO leakable hooks (or removed). Confirm `.claude/settings.local.json` is gitignored (add if not). Keep local dogfood behavior working.

Out of scope (unless analyst argues): converting the plugin to ship hooks via `hooks/hooks.json` (the harness Stop hook is a PER-PROJECT dev-sync, NOT something the plugin should run globally — it should NOT be a plugin hook at all); changing what harness-sync DOES; a new verify_all check (prefer the resilient design over a guard — feedback_design_over_guards).

## Insights to honor (verify before relying)
- The `{{SYNC_COMMAND}}`/`{{GUARD_COMMAND}}` placeholders are OS-picked at init (Windows→pwsh/.ps1, Unix→bash/.sh) — the resilient form must be defined for BOTH and stay byte-symmetric in spirit.
- verify_all surfaces that touch this: **J.1** (settings.json schema integrity — `.claude/` + template; the new command strings must keep the schema valid and the `$schema` URL/hook-key enum intact), the T-020 **E.4b/D.4b** hook↔script congruence rows + **test-init**'s "every settings hook command path exists on disk" + "ambient/sync command is the OS-picked variant" assertions + **test-harness-upgrade**'s dangling-hook repair + congruence-exit-4 probes. A changed command form will ripple into these — the Architect must enumerate every assertion that parses the hook command string (the T-020 four-file-lockstep discipline).
- guard-rm is a SAFETY hook — fail-open is WRONG for it (a missing guard-rm must NOT silently allow destructive commands). Treat the sync/ambient hooks (convenience) differently from guard-rm (safety). The analyst must draw this line explicitly.
- `$CLAUDE_PROJECT_DIR` is the Claude-Code-provided project-root env var (mattpocock's git-guardrails uses `"$CLAUDE_PROJECT_DIR"/...`). Confirm it's available in all four hook events.
- Cross-shell parity insights (T-012/T-014/T-021): write-time newline, pwsh console encoding, byte-identity for generated files — apply if any script generates the settings.
- Decompose per T-06 if > one smart-zone task (e.g. A = resilient hook in template+dogfood+upgrade; B = stop-distributing-dogfood-settings).
