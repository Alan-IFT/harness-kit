---
name: harness-decision-mode
description: Switch or set a harness project's decision / escalation MODE — Mode 1 (human
  decides every judgment call, the safe default), Mode 2 (the AI decides per the project's
  PRESET rubric and escalates only the red lines), or Mode 3 (the AI decides per YOUR OWN
  custom rubric). Surgically rewrites ONLY the "Active mode" line of
  .harness/rules/25-decision-policy.md; on a first switch to Mode 3 it collects your custom
  decision prompts and writes them into the rubric's Custom section. Non-destructive (clean-git
  gated, .bak per edited file), idempotent (re-picking the current mode is a clean no-op). Use
  to change HOW MUCH the AI decides on its own versus asks you first — "switch decision mode",
  "let the AI decide on its own", "make it ask me first / 人工决策", "切换决策模式",
  "让 AI 自己拿主意", "改成人工决策", "用我自己的决策规则". NOT for editing the rubric's CONTENT
  only (edit .harness/decision-rubric.md directly), NOT for output-language (/harness-language),
  NOT for layout/version upgrades (/harness-upgrade).
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, TodoWrite
---

# /harness-decision-mode

Set or switch a harness project's **decision & escalation mode** — the project-wide control over
how a judgment call is resolved when the AI hits a choice it would otherwise put to you. The full
policy lives in `.harness/rules/25-decision-policy.md`; the principles the AI decides by live in
`.harness/decision-rubric.md`. This skill flips the **Active mode** line of the policy (and, for a
first Mode-3 switch, seeds the Custom rubric).

The three modes (from `25-decision-policy.md`):

- **Mode 1 — human decides** (the safe default for new projects). The AI escalates every judgment
  call it cannot resolve from the request, the code, or an unambiguous default.
- **Mode 2 — preset-rubric autonomy.** The AI decides anything the **Preset rubric** covers,
  escalates only the red lines + uncovered/irreversible calls, and logs each autonomous decision.
- **Mode 3 — custom-rubric autonomy.** Same mechanism as Mode 2, but the AI decides by YOUR
  **Custom rubric** instead of the Preset. The red lines and the audit trail still apply.

The command rewrites **only** the single `Active mode:` line of
`.harness/rules/25-decision-policy.md` (plus, for a first Mode-3 switch with an empty Custom rubric,
the `## Custom rubric (Mode 3)` section of `.harness/decision-rubric.md`). Every other byte of every
file is preserved. It is non-destructive (a `.bak` precedes each edit; a clean git tree is required
so `git reset` is a full rollback) and idempotent (re-picking the already-active mode is a clean
no-op — no write, no `.bak`).

> This skill is the **judgment layer**, and the edit is small enough to do directly: a single-line
> replace via the `Edit` tool plus (Mode-3 only) a section-body replace. There is **no helper
> script** — unlike `/harness-language`, no heading-anchored section slicing or byte-identical
> cross-shell round-trip is needed here, so adding a `.{ps1,sh}` pair would be machinery that does
> not earn its place (`.harness/rules/15-skill-authoring.md` P6).

## When to invoke

- "Switch to Mode 2 / let the AI decide on its own" → pick Mode 2.
- "Make it ask me before deciding / 改成人工决策" → pick Mode 1.
- "Use my own decision rules / 用我自己的决策规则" → pick Mode 3 (you'll author the Custom rubric).
- "切换决策模式 / 让 AI 自己拿主意" → run it, pick the mode interactively.

## When NOT to invoke

- To change WHAT the Preset or Custom rubric SAYS without changing the mode → edit
  `.harness/decision-rubric.md` directly; this skill only flips the active mode (and seeds an empty
  Custom rubric on a first Mode-3 switch).
- To change the project's output language → `/harness-language`.
- To upgrade an old project's layout / scripts / version → `/harness-upgrade`.
- On a brand-new project that has no `.harness/rules/25-decision-policy.md` yet → run `/harness-init`
  (new projects start at Mode 1 by default), or `/harness-upgrade` to bring an old project up to the
  current layout. This skill does NOT bootstrap a missing policy file.
- On this kit's own dogfood repo casually — it targets *generated* projects (though it works here
  too; the dogfood Active mode is deliberately 2).

## Procedure

Use `TodoWrite` to track. The apply step is gated: never write without an explicit user "yes".

### 1. Precondition gate

The current working directory is the target project.

- Confirm `.git/` exists. If not → **halt**, no changes ("not a git repository").
- Refuse on a **dirty working tree** (`git status --porcelain` non-empty) with "commit or stash your
  changes first" — this preserves the `git reset` rollback path.
- Confirm `.harness/rules/25-decision-policy.md` exists. If **not** → **halt**: "this project has no
  decision-policy to switch; run `/harness-init` (new project) or `/harness-upgrade` (old project)."

### 2. Read the current Active mode

Read `.harness/rules/25-decision-policy.md` and find the single line matching
`Active mode: <N>` (the canonical line is bold: `**Active mode: 2 (preset-rubric autonomy …).**`).

- If exactly one such line is found → `current = N` (1, 2, or 3). Display it ("current = Mode N").
- If **no** recognizable `Active mode:` line, or **more than one** → **halt** with a conflict
  message ("could not find a single 'Active mode' line in 25-decision-policy.md; it may be
  hand-mangled — fix it by hand or restore from backup"). NEVER guess or write into an
  unrecognized structure.

### 3. Pick the target mode

`AskUserQuestion`: present Mode 1 / Mode 2 / Mode 3 as options, each with a one-line description of
what it does (text from "The three modes" above). **Pre-select the current mode.** The user picks one.

### 4. Idempotency

If `target == current` → report "already Mode N — nothing to do" and **stop** (no write, no `.bak`).

### 5. Confirm and apply the Active-mode line

1. Compute the new Active-mode line by replacing only the mode digit + its short parenthetical label,
   preserving the rest of the line's prose. The canonical labels:
   - Mode 1: `**Active mode: 1 (human decides — the safe default).**`
   - Mode 2: `**Active mode: 2 (preset-rubric autonomy, "balanced" calibration).**`
   - Mode 3: `**Active mode: 3 (custom-rubric autonomy).**`
   (Keep the surrounding lines — the "New projects … default to Mode 1 … Switch with
   `/harness-decision-mode`" sentence below it — unchanged.)
2. Show the single-line diff (old → new). `AskUserQuestion`: "Apply this change? [yes / no]".
3. On **"yes"**: write a timestamped `.bak` of `25-decision-policy.md`, then `Edit` the one
   `Active mode:` line (exact old-string → new-string). On **"no"** → stop, change nothing.

### 6. Mode-3 Custom-rubric capture (only when switching TO Mode 3)

If `target == 3`:

1. Read `.harness/decision-rubric.md` and locate the `## Custom rubric (Mode 3)` section body.
2. **If the body is empty** (only the instruction blockquote + the `_(empty …)_` placeholder, no
   authored bullets):
   - `AskUserQuestion` (use the free-text **"Other"** option) collecting the user's custom decision
     prompts — the principles they want the AI to decide by. Offer to gather several (e.g. "add
     another?" loop) and let them finish.
   - Write a `.bak` of `decision-rubric.md`, then `Edit` the Custom-section body: replace the
     `_(empty …)_` placeholder with the user's bullets (keep the instruction blockquote above it).
3. **If the body is already non-empty** → leave it untouched; just report that Mode 3 now reads the
   existing Custom rubric. (To change its content, the user edits `decision-rubric.md` directly.)

### 7. Final report

```
Set decision mode: Mode <M> -> Mode <N>
25-decision-policy.md:  Active-mode line rewritten
decision-rubric.md:     <Custom rubric seeded with N prompts | unchanged>
Backups:                <.bak paths>
```

No `verify_all` run is required — this edits policy prose, not scripts. The new mode takes effect the
next time an agent hits a decision point.

## Hard rules

- **Non-destructive.** Clean git tree is a precondition (rollback = `git reset`); every edited file
  gets a timestamped `.bak`.
- **Surgical scope.** Only the single `Active mode:` line changes (plus the Custom-rubric body on a
  first Mode-3 switch). Every other byte of every file is preserved.
- **Idempotent.** Re-picking the already-active mode is a clean no-op (no write, no `.bak`).
- **Confirm before write.** Never rewrite the Active-mode line without an explicit "yes".
- **No bootstrap.** If `25-decision-policy.md` is absent, halt and point at `/harness-init` /
  `/harness-upgrade`; do not fabricate a policy file.
- **Red lines are untouchable.** This skill changes only the mode; the red lines in
  `25-decision-policy.md` apply in all three modes and are never edited here.

## Anti-patterns

- Don't proceed past the plan without an explicit "yes".
- Don't write into a hand-mangled `25-decision-policy.md` with no recognizable single Active-mode
  line — surface the conflict and stop.
- Don't clobber a non-empty Custom rubric on a Mode-3 switch — only seed it when empty.
- Don't add a `.{ps1,sh}` helper for this — the edit is a one-line replace; a cross-shell pair would
  be unearned machinery (rule 15 P6).
- Don't use this to edit the rubric's CONTENT — that's a direct edit of `.harness/decision-rubric.md`.
- Don't confuse this with `/harness-language` (output language) or `/harness-upgrade` (layout).

## Out of scope

- Bootstrapping a missing `25-decision-policy.md` / `decision-rubric.md` (that's `/harness-init` /
  `/harness-upgrade`).
- Editing or curating the Preset rubric, or validating the Custom prompts the user supplies.
- Changing the red lines (a fixed safety floor, never mode-dependent).
- Any per-agent rubric integration beyond flipping the project-wide Active mode.
