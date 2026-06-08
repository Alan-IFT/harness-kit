---
name: harness-language
description: Set, switch (English <-> Chinese), or refresh a harness project's
  output-language policy by surgically rewriting only the three policy-bearing surfaces
  (.harness/rules/00-core.md section + CLAUDE.md top line + .github/copilot-instructions.md
  top line) to the target language's current canonical text — non-destructively,
  idempotently, with a dry-run preview and a .bak per edited file. Self-bootstraps the
  canonical text from the plugin template cache, so even an old project that predates the
  current policy can pull it. Use to change a project's working language or to refresh a
  stale policy; for layout upgrades use /harness-upgrade.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, PowerShell, AskUserQuestion, TodoWrite
---

# /harness-language

Set / switch / refresh a harness project's **output-language policy** — the project-wide
rule that decides which language the project's AI produces. Two target states are
supported:

- **`en`** — the single-language English policy (everything the project's AI produces is
  English).
- **`zh`** — the consumer-split Chinese policy (human-facing output in Chinese,
  agent/LLM-facing artifacts in English; the current canonical split).

The command rewrites **only** the three policy-bearing surfaces of the *target project*:

1. `.harness/rules/00-core.md` — the policy SECTION (heading-anchored).
2. `CLAUDE.md` — the single top policy LINE.
3. `.github/copilot-instructions.md` — the single top policy LINE.

Nothing else in the project changes. It is non-destructive (a `.bak` precedes every edit;
a clean git tree is required so `git reset` is a full rollback), idempotent (a second run
on an already-current project is a clean no-op), and reversible (`en` -> `zh` -> `en`
restores the exact original bytes, because all text is pulled from the plugin templates).

> This skill is the **judgment layer**. All mechanical work — locating the policy section
> by its canonical heading, slicing it, substituting the canonical block, swapping the
> one-line policy, writing the `.bak`, the byte-identity NOOP — is done by one
> deterministic helper, `language-policy.{ps1,sh}`, which the skill bootstraps from the
> plugin template cache and drives with explicit flags. The skill does NO markdown
> string-replacement and embeds NO policy text itself.

## When to invoke

- `/harness-language en` — make the project English-only.
- `/harness-language zh` — make the project use the consumer-split Chinese policy.
- `/harness-language` (no arg) — **refresh** the project's CURRENT language to the latest
  canonical text (useful for an old project initialized before the policy was refined).
- For a layout/version upgrade (scripts, hooks, verify_all) → use `/harness-upgrade`.
- For a brand-new project → use `/harness-init` (it asks the language at init).

## Procedure

Use `TodoWrite` to track. Stages are gated: never apply without an explicit user "yes".

### 1. Target & precondition gate

The current working directory is the target project.

- Confirm `.git/` exists. If not → **halt**, no changes ("not a git repository").
- Refuse on a **dirty working tree** (`git status --porcelain` non-empty) with "commit or
  stash your changes first" — this preserves the `git reset` rollback path. (The helper's
  `.bak` covers any untracked policy surface.)
- Confirm at least one of `.harness/rules/00-core.md` OR `CLAUDE.md` exists. If **neither**
  → **halt**, point the user at `/harness-init` (empty project) or `/harness-adopt`
  (no-harness project): "this project has no language-policy surface to operate on".

### 2. Validate the argument

- If an argument is present and is not `en` or `zh` → **halt** ("only en|zh are
  supported"), change nothing.

### 3. Locate the plugin template cache + read the target version

Resolve the plugin template root, in this order (first hit wins) — identical to
`/harness-upgrade`:

1. **`$CLAUDE_PLUGIN_ROOT`** if set → `$CLAUDE_PLUGIN_ROOT/skills/harness-init/templates`.
   Best-effort only; if unset, fall through — do NOT depend on it.
2. **Versioned plugin cache glob (load-bearing):**
   `~/.claude/plugins/cache/harness-kit-marketplace/harness-kit/*/skills/harness-init/templates`.
   On multiple matches pick the **highest semver** directory.
3. **Dev / marketplace-less fallbacks:**
   `~/.claude/plugins/cache/*/harness-kit/*/skills/harness-init/templates`, then
   `~/.claude/skills/harness-init/templates`.
4. **None resolve → halt** ("could not locate the harness-kit plugin template cache;
   reinstall the plugin"). The helper is never invoked.

The helper's `--template-root` is the directory **above** `skills/harness-init/templates`
— the resolved cache root `<cache>/harness-kit/<version>/` (the directory that contains
`skills/`). Read `<that>/.claude-plugin/plugin.json` `version` and surface it in the plan
as human prose ("Target policy version: x.y.z").

> The helper does ZERO cache discovery — discovery is judgment, so it stays in this AI
> layer. The helper is a pure deterministic transform driven by `--template-root`. The
> canonical policy text is read ONLY from the resolved templates, never fabricated and
> never sourced from the target project — so a stale project that does not already contain
> the canonical text still gets the correct target text.

### 4. Determine the target language (detect-then-ASK; never silently guess)

- **Explicit `en`/`zh`** → that is the target. Detection still runs (to report "switching
  from <X> to <Y>" or "already <Y>"), but the choice is fixed by the argument.
- **No-arg refresh** → you have no language yet, but the helper REQUIRES `--lang`. To read
  the current language WITHOUT changing anything, invoke the helper with a placeholder
  `--lang <either en|zh> --dry-run` purely to capture the `DETECT|<lang>|<source>` record
  from stdout — the helper emits `DETECT|...` unconditionally after arg-validation and
  before any mutation, and `--dry-run` writes nothing, so the placeholder language is
  inert. Then **confirm the detected language with `AskUserQuestion`**, pre-filled:
  "Detected `<lang>`. Refresh to the current canonical `<lang>` policy? [yes / switch to
  the other language / cancel]". The confirmed value becomes the real `--lang` from step 5.
- **Ambiguous** (`DETECT|ambiguous|...`: conflicting sources or no recognizable policy
  surface) → `AskUserQuestion` with **no pre-filled default** ("Could not determine the
  current language. Set it to: [en / zh / cancel]"). Never guess.

Detection order (the helper computes it): `.harness/rules/00-core.md` policy heading →
`CLAUDE.md` top policy line → `.github/copilot-instructions.md` top policy line; first
confident hit wins.

### 5. Plan (dry-run) → present → confirm → apply

1. Invoke the helper with `--dry-run`:

   ```
   pwsh -File <root>/.harness/scripts/language-policy.ps1 -TemplateRoot <abs> -Lang <en|zh> -DryRun
   # or
   bash <root>/.harness/scripts/language-policy.sh --template-root <abs> --lang <en|zh> --dry-run
   ```

   (Drive whichever copy is present in the target project's `.harness/scripts/`; if the
   project has no `language-policy.*` yet, copy it from
   `<template-root>/skills/harness-init/templates/common/.harness/scripts/` first — the
   same self-bootstrap `/harness-upgrade` does for its helper.)

2. **Parse the machine-readable stdout** (one record per line, pipe-delimited):

   | Prefix | Meaning |
   |---|---|
   | `LANG\|<en\|zh>` | resolved target language |
   | `DETECT\|<en\|zh\|ambiguous>\|<source>` | current-language inference (`00-core`/`CLAUDE`/`copilot`/`none`) |
   | `PLAN\|<verb>\|<file>\|<detail>` | planned action (dry-run) |
   | `RESULT\|<verb>\|<file>\|<detail>` | applied action |
   | `BAK\|<path>` | backup written |
   | `SKIP\|<file>\|<reason>` | absent policy surface tolerated (e.g. no copilot file) |
   | `CONFLICT\|section\|<file>\|<detail>` | no recognizable policy heading in 00-core.md |
   | `SUMMARY\|rewritten=.. noop=.. skipped=.. baks=.. conflicts=..` | totals |

   `<verb>` ∈ `REWRITE-SECTION REWRITE-LINE INSERT-SECTION NOOP SKIP`.

3. Present the plan to the user: which files will change, whether this is a switch
   (`<X>` -> `<Y>`) or a same-language refresh, the target policy version, and the `.bak`
   locations. Then `AskUserQuestion`: `Apply this plan? [yes / no]`.

4. On **"yes"**, re-invoke the helper for real (drop `--dry-run`).

### 6. Branch on the helper's exit code

| Exit | Meaning | Skill action |
|---|---|---|
| `0` | success / nothing-to-do / dry-run printed | continue to step 7 |
| `1` | precondition / arg error (bad `--lang`, missing `--template-root`, no surface) | surface the helper's stderr, halt |
| `2` | **section-conflict** — `00-core.md` exists but carries neither canonical policy heading (hand-mangled or absent) | relay the `CONFLICT\|section\|...` line; run `AskUserQuestion` "00-core.md has no recognizable Output-language policy section. Insert the canonical `<lang>` section? [insert / abort]". On **insert** → re-invoke with `--force` (the helper inserts the section before the first `## ` heading, or at EOF). On **abort** → halt, change nothing. NEVER auto-insert without the explicit answer. |

### 7. Final report

Print the summary:

```
Set <path> output-language policy to <lang> (policy version <target-version>)

Switched:    <X> -> <Y>   (or: refreshed <lang> / already current — nothing to do)
00-core.md:  <REWRITE-SECTION | INSERT-SECTION | NOOP>
CLAUDE.md:   <REWRITE-LINE | NOOP | SKIP (absent)>
copilot:     <REWRITE-LINE | NOOP | SKIP (absent)>
Backups:     <.bak paths>
```

If the project has its own `verify_all`, you MAY suggest the user re-run it — but the
command edits policy prose, not scripts, so no verify_all run is required by this command.

## Hard rules

- **Non-destructive.** Clean git tree is a precondition (rollback = `git reset`); every
  edited file gets a timestamped `.bak`.
- **Surgical scope.** Only the `00-core.md` policy section and the single `CLAUDE.md` /
  copilot policy line change; every other byte of every file is preserved.
- **Single section invariant.** After a switch, `00-core.md` has exactly one policy heading
  and one policy section — the old-language section (heading + body) is the unit replaced.
- **Idempotent.** A second run with the same target is a clean no-op (no write, no `.bak`).
- **Self-bootstrapping, single source of text.** The canonical en/zh text comes ONLY from
  the resolved plugin templates — never fabricated, never copied from the target project.
- **Detect-then-confirm.** Never write without an explicit user answer when the language is
  inferred (no-arg refresh) or ambiguous, and never auto-insert into an unrecognized
  `00-core.md` structure.

## Anti-patterns

- Don't hand-edit the three policy files yourself — drive the helper.
- Don't proceed past the plan without an explicit "yes".
- Don't guess the current language when detection is ambiguous — ask.
- Don't auto-insert a policy section into a hand-mangled `00-core.md` — surface the
  conflict and ask.
- Don't depend on `$CLAUDE_PLUGIN_ROOT` being set — the glob fallback chain is the
  load-bearing discovery path.
- Don't run this against this kit's own dogfood repo — it targets *generated* projects.

## Out of scope (v1)

- Whole-project content translation (only the three policy surfaces; translating docs /
  READMEs / agent files is a separate follow-up).
- Languages other than `en` and `zh`.
- A persisted `PROJECT_LANG` marker / a new `{{...}}` placeholder (detection from the
  existing policy prose is reliable; no new placeholder is introduced).
- The other i18n overlay files beyond the three policy surfaces.
