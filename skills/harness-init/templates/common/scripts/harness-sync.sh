#!/usr/bin/env bash
# harness-sync.sh
# Binding sync: .harness/ → .claude/ + CLAUDE.md (Claude Code binding for v0.2+).
# Mirror of harness-sync.ps1. See that file for full doc.
#
# Usage:
#   ./scripts/harness-sync.sh         # do the sync
#   ./scripts/harness-sync.sh --check # report drift; exit 0 if in sync, 1 otherwise

set -uo pipefail

CHECK=false
[[ "${1:-}" == "--check" ]] && CHECK=true

script_dir="$(cd "$(dirname "$0")" && pwd)"
project_root="$(cd "$script_dir/.." && pwd)"

harness_dir="$project_root/.harness"
claude_dir="$project_root/.claude"
claude_md="$project_root/CLAUDE.md"
github_dir="$project_root/.github"
copilot_instr="$github_dir/copilot-instructions.md"

if [[ ! -d "$harness_dir" ]]; then
    echo "Error: No .harness/ at $harness_dir. Run /harness-init or /harness-adopt first." >&2
    exit 1
fi

declare -a drift

# ---------- Compose CLAUDE.md from .harness/rules/ ----------
rules_dir="$harness_dir/rules"
composed=""
if [[ -d "$rules_dir" ]]; then
    rule_files=("$rules_dir"/*.md)
    if [[ -f "${rule_files[0]}" ]]; then
        # Sort by filename
        IFS=$'\n' sorted=($(printf '%s\n' "${rule_files[@]}" | sort))
        unset IFS

        composed_tmp=$(mktemp)
        {
            echo "> ⚠️ **GENERATED FILE — DO NOT EDIT DIRECTLY**"
            echo ">"
            echo "> Source of truth: \`.harness/rules/*.md\` (composed in filename order)"
            echo "> After editing the source, run \`scripts/harness-sync.sh\` (or \`.ps1\`) to regenerate."
            echo "> \`verify_all\` will FAIL if this file drifts from the source."
            echo ""
            echo "<!-- generated marker: keep in sync with harness-sync output -->"
            echo ""
            for f in "${sorted[@]}"; do
                content=$(cat "$f")
                content="${content%"${content##*[![:space:]]}"}"
                echo "$content"
                echo ""
            done
        } > "$composed_tmp"

        if [[ -f "$claude_md" ]]; then
            if ! cmp -s "$composed_tmp" "$claude_md"; then
                drift+=("CLAUDE.md (out of sync with .harness/rules/)")
                if [[ "$CHECK" == false ]]; then
                    cp "$composed_tmp" "$claude_md"
                    echo "Synced CLAUDE.md (from .harness/rules/)"
                fi
            fi
        else
            drift+=("CLAUDE.md (missing)")
            if [[ "$CHECK" == false ]]; then
                cp "$composed_tmp" "$claude_md"
                echo "Created CLAUDE.md (from .harness/rules/)"
            fi
        fi

        # ---------- Compose .github/copilot-instructions.md from .harness/rules/ ----------
        # Same composed rules with Copilot frontmatter, lets GitHub Copilot users
        # in the same repo pick up project rules. Agents and skills are NOT mirrored
        # here — Copilot has its own format (deferred to v0.8+).
        copilot_tmp=$(mktemp)
        {
            echo "---"
            echo "applyTo: \"**\""
            echo "---"
            echo "> ⚠️ **GENERATED FILE — DO NOT EDIT DIRECTLY**"
            echo ">"
            echo "> Source of truth: \`.harness/rules/*.md\` (composed in filename order)"
            echo "> After editing the source, run \`scripts/harness-sync.sh\` (or \`.ps1\`) to regenerate."
            echo "> \`verify_all\` will FAIL if this file drifts from the source."
            echo ""
            echo "<!-- generated marker: keep in sync with harness-sync output -->"
            echo ""
            for f in "${sorted[@]}"; do
                content=$(cat "$f")
                content="${content%"${content##*[![:space:]]}"}"
                echo "$content"
                echo ""
            done
        } > "$copilot_tmp"

        if [[ -f "$copilot_instr" ]]; then
            if ! cmp -s "$copilot_tmp" "$copilot_instr"; then
                drift+=(".github/copilot-instructions.md (out of sync with .harness/rules/)")
                if [[ "$CHECK" == false ]]; then
                    mkdir -p "$github_dir"
                    cp "$copilot_tmp" "$copilot_instr"
                    echo "Synced .github/copilot-instructions.md (from .harness/rules/)"
                fi
            fi
        else
            drift+=(".github/copilot-instructions.md (missing)")
            if [[ "$CHECK" == false ]]; then
                mkdir -p "$github_dir"
                cp "$copilot_tmp" "$copilot_instr"
                echo "Created .github/copilot-instructions.md (from .harness/rules/)"
            fi
        fi
        rm -f "$composed_tmp" "$copilot_tmp"
    fi
fi

# ---------- Copy .harness/agents/ → .claude/agents/ ----------
harness_agents="$harness_dir/agents"
claude_agents="$claude_dir/agents"

if [[ -d "$harness_agents" ]]; then
    if [[ ! -d "$claude_agents" ]]; then
        if [[ "$CHECK" == true ]]; then
            drift+=(".claude/agents/ (missing)")
        else
            mkdir -p "$claude_agents"
        fi
    fi

    for f in "$harness_agents"/*.md; do
        [[ -f "$f" ]] || continue
        name=$(basename "$f")
        dst="$claude_agents/$name"
        if [[ -f "$dst" ]]; then
            if ! cmp -s "$f" "$dst"; then
                drift+=(".claude/agents/$name (out of sync)")
                [[ "$CHECK" == false ]] && cp "$f" "$dst" && echo "Synced .claude/agents/$name"
            fi
        else
            drift+=(".claude/agents/$name (missing)")
            [[ "$CHECK" == false ]] && cp "$f" "$dst" && echo "Synced .claude/agents/$name"
        fi
    done

    # Orphans
    if [[ -d "$claude_agents" ]]; then
        for f in "$claude_agents"/*.md; do
            [[ -f "$f" ]] || continue
            name=$(basename "$f")
            if [[ ! -f "$harness_agents/$name" ]]; then
                drift+=(".claude/agents/$name (orphan)")
                [[ "$CHECK" == false ]] && rm -f "$f" && echo "Removed orphan .claude/agents/$name"
            fi
        done
    fi
fi

# ---------- Copy .harness/skills/ → .claude/skills/ ----------
harness_skills="$harness_dir/skills"
claude_skills="$claude_dir/skills"

if [[ -d "$harness_skills" ]]; then
    while IFS= read -r f; do
        rel="${f#$harness_skills/}"
        dst="$claude_skills/$rel"
        if [[ -f "$dst" ]]; then
            if ! cmp -s "$f" "$dst"; then
                drift+=(".claude/skills/$rel (out of sync)")
                if [[ "$CHECK" == false ]]; then
                    mkdir -p "$(dirname "$dst")"
                    cp "$f" "$dst"
                    echo "Synced .claude/skills/$rel"
                fi
            fi
        else
            drift+=(".claude/skills/$rel (missing)")
            if [[ "$CHECK" == false ]]; then
                mkdir -p "$(dirname "$dst")"
                cp "$f" "$dst"
                echo "Synced .claude/skills/$rel"
            fi
        fi
    done < <(find "$harness_skills" -type f)
fi

# ---------- Report ----------
if [[ "$CHECK" == true ]]; then
    if (( ${#drift[@]} > 0 )); then
        echo "Drift detected (${#drift[@]} item(s)):" >&2
        for d in "${drift[@]}"; do echo "  - $d" >&2; done
        echo "" >&2
        echo "Fix: run scripts/harness-sync.sh (without --check)" >&2
        exit 1
    else
        echo "In sync."
        exit 0
    fi
fi

if (( ${#drift[@]} == 0 )); then
    echo "Already in sync."
else
    echo ""
    echo "Sync complete (${#drift[@]} item(s) updated)."
fi
