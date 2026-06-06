#!/usr/bin/env bash
# install.sh — Install Harness Kit skills into Claude Code.
#
# Three install paths exist:
#
#   1. (Recommended) Claude Code plugin marketplace — runs inside Claude Code:
#        /plugin marketplace add Alan-IFT/harness-kit
#        /plugin install harness-kit@harness-kit-marketplace
#      Versioned, auditable, official path. This script doesn't drive that;
#      run the slash commands above in any Claude Code session.
#
#   2. (Fallback) Direct copy to ~/.claude/skills/ — this script.
#      Use when plugin path isn't available or you want plain skills layout.
#
#   3. (Dev mode) Run locally from a cloned repo: ./install.sh
#
# Curl one-liner:
#   curl -fsSL https://raw.githubusercontent.com/Alan-IFT/harness-kit/main/install.sh | sh
#
# Usage (local):
#   ./install.sh                  # install to ~/.claude/skills (global)
#   ./install.sh --project .      # install to ./.claude/skills
#   ./install.sh --dry-run        # preview, no writes
#   ./install.sh --uninstall      # remove

set -euo pipefail

PROJECT=""
DRY_RUN=false
UNINSTALL=false
# Override via env: HARNESS_KIT_REPO=https://github.com/fork/harness-kit BRANCH=dev
REPO_URL="${HARNESS_KIT_REPO:-https://github.com/Alan-IFT/harness-kit}"
BRANCH="${HARNESS_KIT_BRANCH:-main}"

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

# Decide skill source: either a local repo (when running ./install.sh from a
# clone) or fetch from $REPO_URL (when piped via curl).
script_dir="$(cd "$(dirname "$0")" 2>/dev/null && pwd || pwd)"
if [[ -d "$script_dir/skills/harness-init" ]]; then
    SOURCE_MODE=local
    skills_source="$script_dir/skills"
else
    SOURCE_MODE=remote
    if ! command -v git >/dev/null 2>&1; then
        echo "Error: git is required to fetch harness-kit. Install git first." >&2
        exit 1
    fi
    tmp_dir=$(mktemp -d -t harness-kit-XXXXXX)
    trap 'rm -rf "$tmp_dir"' EXIT
    echo "Fetching harness-kit from $REPO_URL ($BRANCH)..."
    git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$tmp_dir/repo" >/dev/null 2>&1 || {
        echo "Error: git clone failed. Check network or override HARNESS_KIT_REPO." >&2
        exit 1
    }
    skills_source="$tmp_dir/repo/skills"
fi

if [[ -n "$PROJECT" ]]; then
    resolved=$(cd "$PROJECT" && pwd)
    target="$resolved/.claude/skills"
    scope="project: $resolved"
else
    target="$HOME/.claude/skills"
    scope="global: $HOME"
fi

skills=(harness harness-init harness-adopt harness-verify harness-status harness-plan harness-explore harness-goal harness-batch harness-stream harness-intervene harness-supervise)

echo ""
echo "Harness Kit install"
echo "  Source: $SOURCE_MODE${SOURCE_MODE:+ ($skills_source)}"
echo "  Scope:  $scope"
echo "  Target: $target"
echo "  Skills: ${skills[*]}"
echo ""

if [[ "$UNINSTALL" == true ]]; then
    for skill in "${skills[@]}"; do
        path="$target/$skill"
        if [[ -d "$path" ]]; then
            if [[ "$DRY_RUN" == true ]]; then echo "[dry-run] Would remove $path"
            else rm -rf "$path"; echo "Removed $skill"
            fi
        else
            echo "$skill not present, skipping"
        fi
    done
    echo ""
    echo "Done."
    exit 0
fi

if [[ ! -d "$target" ]]; then
    if [[ "$DRY_RUN" == true ]]; then echo "[dry-run] Would create $target"
    else mkdir -p "$target"
    fi
fi

for skill in "${skills[@]}"; do
    src="$skills_source/$skill"
    dst="$target/$skill"

    if [[ ! -d "$src" ]]; then echo "WARN: source missing: $src" >&2; continue; fi

    if [[ -d "$dst" ]]; then
        echo "Existing $skill found, replacing..."
        [[ "$DRY_RUN" == false ]] && rm -rf "$dst"
    fi

    if [[ "$DRY_RUN" == true ]]; then echo "[dry-run] Would copy $src -> $dst"
    else cp -r "$src" "$dst"; echo "Installed $skill"
    fi
done

echo ""
echo "Done."
echo ""
echo "Use in Claude Code:"
echo "  /harness-init     in an empty project"
echo "  /harness-adopt    in an existing project"
echo "  /harness          full 7-stage pipeline (real feature / bug / refactor)"
echo "  /harness-plan     design-only mode (RA + SA + GR, no Dev)"
echo "  /harness-explore  research/feasibility (light RA + findings.md)"
echo "  /harness-goal     open-ended Dev + QA loop within a budget"
echo "  /harness-batch    run a fixed list of tasks through the pipeline (fail-stop)"
echo "  /harness-stream   drain a living task pool you keep topping up (best-effort)"
echo ""
echo "  /harness-init     bootstrap an empty project with Harness skeleton"
echo "  /harness-adopt    add Harness to an existing project"
echo "  /harness-verify   run the project's verify_all"
echo "  /harness-status   inspect Harness assets"
echo "  /harness-intervene  redirect / pause / add-task to an inflight pipeline (soft Ctrl-C)"
echo "  /harness-supervise  observer-only health check of a task folder"
echo ""
echo "Tip: for versioned/auditable install, prefer the plugin path inside Claude Code:"
echo "  /plugin marketplace add Alan-IFT/harness-kit"
echo "  /plugin install harness-kit@harness-kit-marketplace"
