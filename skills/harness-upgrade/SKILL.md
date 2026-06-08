---
name: harness-upgrade
description: Upgrade an already-initialized but stale harness project to the current
  plugin layout — relocate scripts to .harness/scripts/, re-install the pre-commit
  hook, rewire settings hook paths, regenerate verify_all from the current type
  template — non-destructively, idempotently, with a dry-run preview, then prove it
  with a green verify_all. Use when a project HAS harness but is OLD; for projects
  with no harness at all use /harness-adopt.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, PowerShell, AskUserQuestion, TodoWrite
---

# /harness-upgrade

Bring a project that was initialized with an **older** harness-kit version up to the
**current** plugin layout: scripts under `.harness/scripts/`, a pre-commit hook pointing
at the new path, settings hook paths rewired, and a freshly-regenerated per-type
`verify_all` — non-destructively, idempotently, with a dry-run preview, then proven with
a green `verify_all`.

> This skill is the **judgment layer**. All mechanical work is done by one deterministic
> helper, `upgrade-project.{ps1,sh}`, which the skill bootstraps from the plugin template
> cache and drives with explicit flags. The skill does NO path string-replacement, NO
> `git mv`, NO settings byte-editing, NO template substitution itself.

## When to invoke

- The project **already has** harness assets (`.claude/settings.json`, `.harness/`, or
  a top-level `scripts/harness-sync.*`) but is on an **old layout** (pre-`.harness/scripts/`).
- For a project with **no** harness at all → use `/harness-adopt` instead.
- For a brand-new empty project → use `/harness-init`.

## Procedure

Use `TodoWrite` to track. Stages are gated: never apply without an explicit user "yes".

### 1. Target & precondition gate

The current working directory is the target.

- Confirm `.git/` exists. If not → **halt**, no changes ("not a git repository").
- Confirm SOME harness setup exists: `.claude/settings.json` OR `.harness/` OR a
  top-level `scripts/harness-sync.*`. If **none** → **halt**, point the user at
  `/harness-adopt` ("this project has no harness setup; use /harness-adopt to add it").
- Refuse on a **dirty working tree** (`git status --porcelain` non-empty) with "commit
  or stash your changes first" — this preserves the `git reset` rollback path for all
  tracked edits. (The helper's `.bak` covers the two untracked surfaces: the pre-commit
  hook and `.claude/settings.json`.)

### 2. Locate the plugin template cache + read the target version

Resolve the plugin template root, in this order (first hit wins):

1. **`$CLAUDE_PLUGIN_ROOT`** if set → `$CLAUDE_PLUGIN_ROOT/skills/harness-init/templates`.
   This is best-effort only; it may be unset. If unset, just fall through — do NOT
   depend on it.
2. **Versioned plugin cache glob (load-bearing):**
   `~/.claude/plugins/cache/harness-kit-marketplace/harness-kit/*/skills/harness-init/templates`.
   If multiple versions match, pick the **highest semver** directory.
3. **Dev / marketplace-less fallbacks:**
   `~/.claude/plugins/cache/*/harness-kit/*/skills/harness-init/templates`, then
   `~/.claude/skills/harness-init/templates` (the `/harness-adopt`-era fallback).
4. **None resolve → halt** with an actionable message ("could not locate the harness-kit
   plugin template cache; reinstall the plugin or pass the path manually") and change
   nothing. The helper is never invoked.

The helper's `--template-root` is the directory **above** `skills/harness-init/templates`
— i.e. the resolved cache root `<cache>/harness-kit/<version>/` (the directory that
contains `skills/`). Read `<that>/.claude-plugin/plugin.json` `version` for the **target
version**, and cross-check it against the `<version>` path segment. Surface the
target version (e.g. "Target version: x.y.z") and the project's detected starting
state in the plan you show the user — this is human-facing prose, not a parsed line
(the helper does not emit a `TARGET-VERSION|` record).

> The helper itself does ZERO cache discovery — discovery is judgment (fallbacks, "which
> version"), so it stays in this AI layer. The helper is a pure deterministic transform
> driven by `--template-root`.

### 3. Detect the project type (detect-then-ASK; never silently guess)

Pre-fill the project type from, in order:

1. The `.harness/rules/50-<type>.md` filename (`50-fullstack.md` → fullstack, etc.).
2. Else the old `verify_all`'s header line `=== verify_all (<type>) ===`.

Then **always** confirm with `AskUserQuestion`, pre-filled:

- **Project type** — Fullstack / Backend / Generic.
- For **Generic** only: collect the free-text **stack** string (`{{STACK}}`) from the
  user — it cannot be reliably recovered. (Non-generic templates hardcode their stack
  text, but still pass `--stack` for the substitution the template expects.)

### 4. Self-bootstrap the helper from the cache

Copy `upgrade-project.{ps1,sh}` (and `migrate-scripts-layout.{ps1,sh}` for parity, so
the project ends with the current helpers present) from the resolved
`<template-root>/skills/harness-init/templates/common/.harness/scripts/` into the
project's `.harness/scripts/`. **Do not assume** these pre-exist (the chicken-and-egg
case — a stale project will not have `upgrade-project` yet). Create `.harness/scripts/`
if needed.

> The helper is **cwd-derived (depth-independent)**, so it runs correctly whether you
> invoke it from `scripts/` (before relocation) or `.harness/scripts/` (after).

### 5. Plan (dry-run) → present → confirm → apply

1. Invoke the helper with `--dry-run`, passing `--template-root`, `--type`, `--stack`
   (and `--project-name` / `--today` if you want reproducible output):

   ```
   pwsh -File .harness/scripts/upgrade-project.ps1 -TemplateRoot <abs> -Type <t> -Stack "<s>" -DryRun
   # or
   bash .harness/scripts/upgrade-project.sh --template-root <abs> --type <t> --stack "<s>" --dry-run
   ```

2. **Parse the machine-readable stdout** (one record per line, pipe-delimited):

   | Prefix | Meaning |
   |---|---|
   | `PLAN\|<verb>\|<detail>` | planned action (dry-run) |
   | `RESULT\|<verb>\|<detail>` | applied action |
   | `GAP\|<id>\|<present\|absent>\|<detail>` | gap diagnosis |
   | `TYPE\|<type>` | resolved type |
   | `BAK\|<path>` | backup written |
   | `CONFLICT\|<kind>\|<detail>` | surfaced conflict (hook / verify_all) |
   | `SUMMARY\|added=.. moved=.. rewritten=.. rewired=.. conflicts=..` | totals |

   `<verb>` ∈ `MOVE REFRESH REWIRE HOOK-INSTALL HOOK-SKIP VERIFY-REGEN VERIFY-SPLICE
   VERIFY-HALT SKIP NOOP`.

3. Present the gap report + the plan to the user (every file added / moved / rewritten /
   rewired, the target version, the `.bak` locations). Ask via `AskUserQuestion`:
   `Apply this plan? [yes / no]`.

4. On **"yes"**, re-invoke the helper for real (drop `--dry-run`).

### 6. Branch on the helper's exit code

| Exit | Meaning | Skill action |
|---|---|---|
| `0` | success / nothing-to-do / dry-run printed | continue to step 7 |
| `1` | precondition / user error | surface the helper's stderr, halt |
| `2` | **verify_all refresh-blocked** — the old `verify_all` carried custom B.* checks but had no `HARNESS:B-CUSTOM` markers, so a safe splice was impossible | show the user the old B.* block + the `.bak` path; ask to confirm overwrite → re-invoke with `-Force`/`--force`, or abort. NEVER guess a splice. |
| `3` | **hook conflict** — a non-stock (hand-customized) `.git/hooks/pre-commit` was found and NOT overwritten | relay the `CONFLICT|hook|...` line; the rest of the upgrade still completed. Tell the user to merge the drift check in manually. |

### 7. Final gate + report

1. Run `verify_all` (from `.harness/scripts/`).
2. Surface its **PASS/WARN/FAIL summary verbatim** — never swallow a non-zero result. A
   green result is the success signal; a non-green result is shown as-is.
3. Print the upgrade summary:

   ```
   ✅ Upgraded <path> to harness-kit <target-version>

   Starting state:   <detected gaps>
   Scripts moved:    <list>           (scripts/ -> .harness/scripts/)
   Scripts refreshed:<list>           (content-refreshed for correct two-up root derivation)
   verify_all:       <SPLICE | REGEN> (B.* customizations preserved / reset; .bak written)
   Hook:             <installed | refreshed | conflict>
   Settings:         <rewired | skipped (no .claude/settings.json) | already current>
   Backups:          <.bak paths>
   verify_all result: PASS <n> / WARN <n> / FAIL <n>
   ```

Tip: to set or refresh this project's output-language policy (English <-> Chinese), run /harness-language.

## Why content-refresh, not just relocation (the L31 fix)

Relocation alone (`git mv scripts/x .harness/scripts/x`) preserves the OLD file content.
A depth-sensitive script (`harness-sync`, `install-hooks`, `archive-task`) derives the
repo root as a FIXED number of levels up from its own location. The pre-`.harness/scripts/`
copies derived root **one-up**; from `.harness/scripts/` they must derive it **two-up**.
So the helper's step S2 **unconditionally byte-overwrites** those scripts with the current
template content (which is already two-up). This is invisible to a path-string sweep and
is the single non-obvious correctness fix this skill carries. `verify_all` is regenerated
from the type `.tmpl` (it is cwd-derived, so it is regenerated, not flat-copied).

## verify_all refresh (preserve user B.* customizations)

The helper FULL-REGENERATES `verify_all.{ps1,sh}` from the current type `.tmpl` (the only
deterministic / idempotent / parity-testable path), but **never silently loses** a user's
B.* build/test/lint checks:

- Old file has clean `HARNESS:B-CUSTOM:BEGIN`/`END` markers **and** a customized block →
  **verbatim SPLICE** of the old block into the fresh file (`VERIFY-SPLICE`).
- Clean markers + stub-only block → take the fresh template (`VERIFY-REGEN`).
- **No** clean markers + the old B.* looks customized → **HALT** (exit 2) for explicit
  `--force`; the `.bak` preserves the old checks for manual re-apply.
- No markers + stub-only → safe regenerate.

Always writes a timestamped `.bak`. Byte-identical output → NOOP (no write, no `.bak`).

## Hard rules

- **Non-destructive.** Clean git tree is a precondition (rollback = `git reset`); the
  two untracked surfaces (pre-commit hook, `.claude/settings.json`) get a `.bak`.
- **Never re-serialize `.claude/settings.json`** — the helper does a surgical raw-text
  path rewrite that preserves the file shape and the `_*` documentation keys.
- **Never overwrite a hand-customized pre-commit hook** — detect non-stock content and
  surface it as a conflict (exit 3).
- **Never silently discard user B.* checks** — splice when cleanly delimited, else halt
  for confirmation.
- **Idempotent.** A second run is a clean no-op ("already current / nothing to do").
- **Surface verify_all verbatim** — a non-green result is shown, not hidden.

## Anti-patterns

- Don't run the upgrade on a project with no harness at all — route to `/harness-adopt`.
- Don't guess the project type for substitution — always confirm via `AskUserQuestion`.
- Don't proceed past the plan without an explicit "yes".
- Don't hand-edit settings / hooks / scripts yourself — drive the helper.
- Don't depend on `$CLAUDE_PLUGIN_ROOT` being set — the glob fallback chain is the
  load-bearing discovery path.

## Out of scope (v1)

- Agent / skill / rule **content** refresh (scripts + hooks + settings + verify_all only;
  a future `--include-agents` is deferred).
- The v0.1.x → v0.2.0 `CLAUDE.md` → `.harness/rules/` split (use `MIGRATION.md`).
- Adopting harness into a no-harness project (`/harness-adopt`).
- Downgrade (newer project → older plugin).
- Package installs, CI edits, network calls.
