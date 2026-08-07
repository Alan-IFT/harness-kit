#!/usr/bin/env bash
# install-hooks.sh - Install the harness-kit git pre-commit hook, and bootstrap the
# machine-local Claude settings file when (and only when) this project has no
# lifecycle hooks wired at all.
#
# Why the pre-commit hook: .harness/ is the source of truth; CLAUDE.md +
# .github/copilot-instructions.md are generated. Claude Code keeps them fresh via a
# Stop hook in .claude/settings.json, but that Stop hook is Claude-Code-specific — it
# does NOT fire for GitHub Copilot, Cursor, or hand-edits. This pre-commit hook is the
# tool-agnostic backstop: any commit that includes stale generated artifacts is
# blocked, regardless of who or what edited .harness/.
#
# Why the settings bootstrap (T-13): a project whose committed .claude/settings.json
# declares NO lifecycle hooks has no working guard, no doc-sync Stop hook and no
# ambient hooks. When that is the case AND no .claude/settings.local.json exists yet,
# this installer writes one from the hook wiring spec (.harness/scripts/hook-spec),
# using the host OS's byte-forms. It never overwrites an existing machine-local file,
# never writes a backup, and never touches .gitignore.
#
# Usage:
#   bash .harness/scripts/install-hooks.sh
#
# Exit codes:
#   0  success (pre-commit installed; machine-local settings bootstrapped OR
#      deliberately not touched — the report says which)
#   1  not a git repository (nothing written)
#   3  committed .claude/settings.json exists but is structurally unparseable
#      (nothing written at all — not even the pre-commit hook)
#   4  the hook wiring spec did not yield a complete set of non-empty commands
#      (nothing written to .claude/)
#   5  writing or confirming the machine-local settings file failed. On the WRITE
#      path (step 6) the target is left ABSENT, never half-written; on the terminal
#      CONFIRMATION path (step 7) the rename already succeeded, so the target is
#      left PRESENT-but-unconfirmed and the diagnostic says so and tells you to
#      remove it and re-run.
#
# To disable the pre-commit hook: rm .git/hooks/pre-commit
# To remove the machine-local hooks: rm .claude/settings.local.json

set -euo pipefail

# Script lives at .harness/scripts/ — repo root is two levels up.
repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
git_dir="$repo_root/.git"
scripts_dir="$repo_root/.harness/scripts"
committed_settings="$repo_root/.claude/settings.json"
local_settings="$repo_root/.claude/settings.local.json"

if [ ! -d "$git_dir" ]; then
    echo "Not a git repo: $repo_root has no .git/. Run 'git init' first." >&2
    exit 1
fi

# --- settings_hook_state <path> -> absent | unparseable | empty | present -----------
# A deliberately shallow structural probe: no jq, no python3 (the Git-for-Windows MSYS
# shell has neither). It answers exactly one question — does this settings file declare
# a non-empty lifecycle-hooks block? — and it fails SAFE: a misjudgment can only
# suppress a write, never cause a wrong one.
#   0a nothing at the path (not even a dangling symlink)      -> absent
#   0b exists but is not a regular file                       -> present (read nothing)
#   1  empty after whitespace strip, or does not start with { -> unparseable
#      and end with }
#   2  no "hooks" followed (after optional whitespace) by :   -> empty
#   3  that : is not followed by {                            -> unparseable
#   4  first non-whitespace byte after that { is }            -> empty, else present
# Step 2's anchor is the QUOTED key, so a prose mention of hooks in a doc string does
# not match, and an escaped \"hooks\" never matches either (the byte before `hooks` is
# a backslash, not a quote).
settings_hook_state() {
    local shs_path="$1" shs_content shs_squeezed shs_rest shs_ws
    if [ ! -e "$shs_path" ] && [ ! -L "$shs_path" ]; then
        printf '%s' "absent"; return 0
    fi
    if [ ! -f "$shs_path" ]; then
        printf '%s' "present"; return 0
    fi
    shs_content="$(cat "$shs_path" 2>/dev/null || true)"
    shs_squeezed="$(printf '%s' "$shs_content" | tr -d '[:space:]')"
    if [ -z "$shs_squeezed" ]; then printf '%s' "unparseable"; return 0; fi
    if [ "${shs_squeezed:0:1}" != "{" ] || [ "${shs_squeezed: -1}" != "}" ]; then
        printf '%s' "unparseable"; return 0
    fi
    if [[ "$shs_content" != *'"hooks"'* ]]; then printf '%s' "empty"; return 0; fi
    shs_rest="${shs_content#*'"hooks"'}"
    shs_ws="${shs_rest%%[![:space:]]*}"; shs_rest="${shs_rest#"$shs_ws"}"
    if [ "${shs_rest:0:1}" != ":" ]; then printf '%s' "empty"; return 0; fi
    shs_rest="${shs_rest:1}"
    shs_ws="${shs_rest%%[![:space:]]*}"; shs_rest="${shs_rest#"$shs_ws"}"
    if [ "${shs_rest:0:1}" != "{" ]; then printf '%s' "unparseable"; return 0; fi
    shs_rest="${shs_rest:1}"
    shs_ws="${shs_rest%%[![:space:]]*}"; shs_rest="${shs_rest#"$shs_ws"}"
    if [ "${shs_rest:0:1}" = "}" ]; then printf '%s' "empty"; return 0; fi
    printf '%s' "present"
}

# --- Step 2: probe the committed settings BEFORE writing anything -------------------
# A structurally broken committed settings file means "change nothing" — this is the
# only path on which the pre-commit hook is not installed.
if { [ -e "$committed_settings" ] || [ -L "$committed_settings" ]; } && [ ! -f "$committed_settings" ]; then
    echo "Committed settings path is not a regular file: $committed_settings" >&2
    echo "  Nothing was written. Fix the path and re-run." >&2
    exit 3
fi
committed_state="$(settings_hook_state "$committed_settings")"
if [ "$committed_state" = "unparseable" ]; then
    echo "Committed settings file does not parse structurally: $committed_settings" >&2
    echo "  Nothing was written. Fix the file and re-run." >&2
    exit 3
fi

# --- Step 3: install the git pre-commit hook (unchanged behavior) -------------------
hooks_dir="$git_dir/hooks"
mkdir -p "$hooks_dir"
hook_path="$hooks_dir/pre-commit"

cat > "$hook_path" <<'EOF'
#!/bin/sh
# harness-kit pre-commit hook.
# Blocks the commit if .harness/ has drifted from CLAUDE.md or .github/copilot-instructions.md.
# Tool-agnostic: catches edits from Claude Code, Copilot, Cursor, or hand-typed.
set -e
_drift=0
if command -v pwsh >/dev/null 2>&1 && [ -f .harness/scripts/harness-sync.ps1 ]; then
    pwsh -File .harness/scripts/harness-sync.ps1 -Check >/dev/null 2>&1 || _drift=1
elif command -v bash >/dev/null 2>&1 && [ -f .harness/scripts/harness-sync.sh ]; then
    bash .harness/scripts/harness-sync.sh --check >/dev/null 2>&1 || _drift=1
else
    echo "harness-kit pre-commit: neither pwsh nor bash found; skipping drift check." >&2
    exit 0
fi
if [ "$_drift" = "1" ]; then
    echo "" >&2
    echo "harness-kit: drift between .harness/ and .claude/." >&2
    echo "  .claude/agents/ and/or .claude/skills/ are stale relative to .harness/." >&2
    echo "" >&2
    echo "  Fix: pwsh -File .harness/scripts/harness-sync.ps1   (Windows)" >&2
    echo "       bash .harness/scripts/harness-sync.sh          (macOS / Linux)" >&2
    echo "  Then: git add .claude/ && git commit ..." >&2
    echo "" >&2
    echo "  Note: edits to .harness/rules/ do NOT need sync (referenced by AI-GUIDE.md, not composed)." >&2
    echo "  Bypass once (NOT recommended): git commit --no-verify" >&2
    exit 1
fi
EOF

chmod +x "$hook_path"
echo "Installed pre-commit hook at $hook_path"
echo "  Runs harness-sync --check before every commit."
echo "  Disable: rm $hook_path"

# --- Step 4: bootstrap decision (first match wins) ----------------------------------
if [ "$committed_state" = "present" ]; then
    echo "Committed settings already declares lifecycle hooks - no machine-local file created."
    exit 0
fi
# Keys on PRESENCE alone, never on content: an unparseable local file, a local file
# holding an empty hooks object (the persistent operator opt-out) and a non-regular
# file at that path all land here and are left byte-untouched.
if [ "$(settings_hook_state "$local_settings")" != "absent" ]; then
    echo "Machine-local settings already present at $local_settings - left byte-untouched, no backup written."
    exit 0
fi

# --- Step 5: query the hook wiring spec ---------------------------------------------
# EVERY capture uses the non-swallowing `if ! v="$(...)"` form: this script runs under
# `set -e`, so a bare command substitution would abort with the child's status and the
# designed exit 4 would be unreachable. Emptiness is checked separately.
spec="$scripts_dir/hook-spec.sh"
spec_fail() {
    echo "Hook wiring spec did not answer: $1" >&2
    echo "  Nothing was written to .claude/. Check $spec and re-run." >&2
    exit 4
}
[ -f "$spec" ] || spec_fail "spec script missing at $spec"

if ! host_os="$(bash "$spec" hostos)"; then spec_fail "hostos"; fi
[ -n "$host_os" ] || spec_fail "hostos (empty answer)"
if ! spec_tools="$(bash "$spec" tools)"; then spec_fail "tools"; fi
[ -n "$spec_tools" ] || spec_fail "tools (empty answer)"

declare -a wired_events=() wired_tools=() wired_matchers=() wired_semantics=() wired_commands=()
# Read the id list LINE BY LINE. An unquoted `for tool in $spec_tools` would be
# glob-exposed: a `*` anywhere in the spec's answer would expand against the cwd.
while IFS= read -r tool; do
    [ -n "$tool" ] || continue
    if ! t_event="$(bash "$spec" event "$tool")"; then spec_fail "event $tool"; fi
    [ -n "$t_event" ] || spec_fail "event $tool (empty answer)"
    if ! t_matcher="$(bash "$spec" matcher "$tool")"; then spec_fail "matcher $tool"; fi
    [ -n "$t_matcher" ] || spec_fail "matcher $tool (empty answer)"
    if ! t_semantics="$(bash "$spec" semantics "$tool")"; then spec_fail "semantics $tool"; fi
    [ -n "$t_semantics" ] || spec_fail "semantics $tool (empty answer)"
    if ! t_command="$(bash "$spec" command "$tool" "$host_os")"; then spec_fail "command $tool $host_os"; fi
    [ -n "$t_command" ] || spec_fail "command $tool $host_os (empty answer)"
    wired_events+=("$t_event")
    wired_tools+=("$tool")
    wired_matchers+=("$t_matcher")
    wired_semantics+=("$t_semantics")
    wired_commands+=("$t_command")
done <<< "$spec_tools"
n_wired=${#wired_tools[@]}
# ALL FOUR OR NOTHING (design section 10, FC-4). Not `> 0`: a spec that ever answered
# with fewer than four ids - one that dropped the destructive-command guard, say -
# would otherwise produce a PARTIAL wiring that still passed the step-7 confirmation
# (which is derived from those same answers) and exited 0 with a green report.
(( n_wired == 4 )) || spec_fail "tools (expected 4 ids, got $n_wired)"
# ... and FOUR DISTINCT EVENTS. Arity alone counts IDS, not events: four duplicate
# ids (or a mixed set with one repeat) satisfies `== 4`, satisfies the step-7 literals
# whenever the destructive-command guard is among them, and satisfies every per-tool check
# (which would compare the same command to itself), so the installer would exit 0
# having wired ONE event instead of four - and would emit duplicate JSON keys. Runs
# AFTER the arity check on purpose: with fewer than 4 ids the operator wants the
# arity diagnostic, and this line's `${wired_events[@]}` needs a populated array.
n_distinct=$(printf '%s\n' "${wired_events[@]}" | sort -u | wc -l)
(( n_distinct == 4 )) || spec_fail "tools (expected 4 DISTINCT hook events, got $n_distinct: ${wired_events[*]})"

# --- Step 6: build the body and write it atomically ---------------------------------
# The spec's return values land in the JSON body UNMODIFIED: no substitution, no
# re-quoting, no sed / -replace anywhere on a command value. That is what makes the
# bash 5.2 patsub_replacement hazard (an unescaped & in ${var//needle/repl} expanding
# to the matched text — these commands carry a literal `& pwsh`) unreachable here
# rather than merely handled.
tmp_settings="$local_settings.tmp-$$"
# STEP 6 diagnostic only: everything below it runs before the rename, so the target
# genuinely never existed. Step 7 has its own handler - do not reuse this one there.
write_failed() {
    rm -f "$tmp_settings"
    echo "Failed to write the machine-local settings file: $1" >&2
    echo "  $local_settings was left absent - nothing partial was persisted." >&2
    exit 5
}
# `|| write_failed` is what keeps B-8's exit 5 reachable here: a bare mkdir failure
# would abort under `set -e` with exit 1, which this file's header documents as
# "not a git repository".
mkdir -p "$repo_root/.claude" || write_failed "could not create $repo_root/.claude"

doc_comment="Machine-local Claude Code hooks generated by .harness/scripts/install-hooks from the hook wiring spec (.harness/scripts/hook-spec), using this host's byte-forms. Never distributed. Remove this file to drop the hooks; re-run the installer to recreate it. The installer never overwrites an existing copy."
doc_semantics="Stop, UserPromptSubmit and SessionStart are fail-open: a missing or unreachable script exits 0 silently. PreToolUse is fail-CLOSED: it carries no exit-0 fallback, so a missing guard blocks the Bash tool call rather than silently disarming the destructive-command guardrail. To keep every hook off permanently, leave this file in place with an empty hooks object - the installer never overwrites an existing file. See .harness/rules/75-safety-hook.md."

declare -a body=()
body+=("{")
body+=("  \"\$schema\": \"https://json.schemastore.org/claude-code-settings.json\",")
body+=("  \"_comment\": \"$doc_comment\",")
body+=("  \"_hook_semantics\": \"$doc_semantics\",")
body+=("  \"hooks\": {")
i=0
while (( i < n_wired )); do
    body+=("    \"${wired_events[$i]}\": [")
    body+=("      {")
    if [ "${wired_matchers[$i]}" != "none" ]; then
        body+=("        \"matcher\": \"${wired_matchers[$i]}\",")
    fi
    body+=("        \"hooks\": [")
    body+=("          {")
    body+=("            \"type\": \"command\",")
    body+=("            \"command\": \"${wired_commands[$i]}\"")
    body+=("          }")
    body+=("        ]")
    body+=("      }")
    if (( i == n_wired - 1 )); then body+=("    ]"); else body+=("    ],"); fi
    i=$(( i + 1 ))
done
body+=("  }")
body+=("}")

printf '%s\n' "${body[@]}" > "$tmp_settings" || write_failed "could not write $tmp_settings"
mv -f "$tmp_settings" "$local_settings" || write_failed "could not move $tmp_settings into place"

# --- Step 7: terminal confirmation — re-read FROM DISK, never the in-memory body ----
# STEP 7 diagnostic: these misses happen AFTER the rename succeeded, so the target IS
# present and step 6's "left absent" wording would be a lie. Separate handler, per
# design section 6 (step 6 = target absent; step 7 = stderr, exit 5, no success line).
confirm_failed() {
    echo "Machine-local settings failed terminal confirmation: $1" >&2
    echo "  $local_settings is present but was NOT confirmed complete." >&2
    echo "  Remove it and re-run: rm $local_settings" >&2
    exit 5
}
confirm="$(cat "$local_settings" 2>/dev/null || true)"
[ -n "$confirm" ] || confirm_failed "the file is empty or unreadable after the write"
# The two LITERAL confirmations the design pins. They are deliberately hard-coded and
# deliberately kept ALONGSIDE the per-tool checks below: those are derived from the
# spec's own answers, so on their own they prove only that the file contains whatever
# the spec said. These two prove the destructive-command guard's event and matcher
# specifically reached disk.
grep -qF -- '"PreToolUse"' "$local_settings" || confirm_failed 'the literal "PreToolUse" event is missing on disk'
grep -qF -- '"matcher": "Bash"' "$local_settings" || confirm_failed 'the literal "matcher": "Bash" is missing on disk'
i=0
while (( i < n_wired )); do
    grep -qF -- "\"${wired_events[$i]}\": [" "$local_settings" || confirm_failed "event ${wired_events[$i]} is missing on disk"
    if [ "${wired_matchers[$i]}" != "none" ]; then
        grep -qF -- "\"matcher\": \"${wired_matchers[$i]}\"" "$local_settings" || confirm_failed "matcher ${wired_matchers[$i]} is missing on disk"
    fi
    grep -qF -- "${wired_commands[$i]}" "$local_settings" || confirm_failed "the ${wired_tools[$i]} command is missing on disk"
    i=$(( i + 1 ))
done

# --- Step 8: the report (visible, reversible, correctly classified) -----------------
echo "Created machine-local Claude settings at $local_settings"
echo "  Wired $n_wired lifecycle hooks from the hook wiring spec ($host_os byte-forms):"
i=0
while (( i < n_wired )); do
    printf '    %-16s -> %-14s (%s)\n' "${wired_events[$i]}" "${wired_tools[$i]}" "${wired_semantics[$i]}"
    i=$(( i + 1 ))
done
echo "  Remove: rm $local_settings"
echo "  This file is machine-local: it is never distributed, and it belongs in .gitignore"
echo "  if this project tracks its .claude/ directory. The installer changes no ignore rules."
