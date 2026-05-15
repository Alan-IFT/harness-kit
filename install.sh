#!/usr/bin/env bash
# install.sh — Install Harness Engineering skills into Claude Code
#
# Usage:
#   ./install.sh                  # install to ~/.claude/skills (global)
#   ./install.sh --project .      # install to ./.claude/skills (project-local)
#   ./install.sh --dry-run        # show what would happen
#   ./install.sh --uninstall      # remove the installed skills

set -euo pipefail

PROJECT=""
DRY_RUN=false
UNINSTALL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --project) PROJECT="$2"; shift 2 ;;
        --dry-run) DRY_RUN=true; shift ;;
        --uninstall) UNINSTALL=true; shift ;;
        -h|--help)
            grep '^# ' "$0" | sed 's/^# //'
            exit 0 ;;
        *) echo "Unknown arg: $1" >&2; exit 1 ;;
    esac
done

repo_root="$(cd "$(dirname "$0")" && pwd)"
skills_source="$repo_root/skills"

if [[ ! -d "$skills_source" ]]; then
    echo "Error: skills/ folder not found at $skills_source" >&2
    exit 1
fi

if [[ -n "$PROJECT" ]]; then
    resolved=$(cd "$PROJECT" && pwd)
    target="$resolved/.claude/skills"
    scope="project: $resolved"
else
    target="$HOME/.claude/skills"
    scope="global: $HOME"
fi

skills=(harness-init harness-adopt harness-verify harness-status)

echo ""
echo "Harness Engineering install"
echo "  Scope:  $scope"
echo "  Target: $target"
echo "  Skills: ${skills[*]}"
echo ""

if [[ "$UNINSTALL" == true ]]; then
    for skill in "${skills[@]}"; do
        path="$target/$skill"
        if [[ -d "$path" ]]; then
            if [[ "$DRY_RUN" == true ]]; then
                echo "[dry-run] Would remove $path"
            else
                rm -rf "$path"
                echo "Removed $skill"
            fi
        else
            echo "$skill not present, skipping"
        fi
    done
    echo ""
    echo "Done."
    exit 0
fi

# Install
if [[ ! -d "$target" ]]; then
    if [[ "$DRY_RUN" == true ]]; then
        echo "[dry-run] Would create $target"
    else
        mkdir -p "$target"
    fi
fi

for skill in "${skills[@]}"; do
    src="$skills_source/$skill"
    dst="$target/$skill"

    if [[ ! -d "$src" ]]; then
        echo "WARN: source missing: $src" >&2
        continue
    fi

    if [[ -d "$dst" ]]; then
        echo "Existing $skill found, replacing..."
        [[ "$DRY_RUN" == false ]] && rm -rf "$dst"
    fi

    if [[ "$DRY_RUN" == true ]]; then
        echo "[dry-run] Would copy $src -> $dst"
    else
        cp -r "$src" "$dst"
        echo "Installed $skill"
    fi
done

echo ""
echo "Done."
echo ""
echo "Use in Claude Code:"
echo "  /harness-init     in an empty project"
echo "  /harness-adopt    in an existing project"
echo "  /harness-verify   run the project's verify_all"
echo "  /harness-status   inspect Harness assets"
