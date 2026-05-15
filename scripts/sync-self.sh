#!/usr/bin/env bash
# sync-self.sh — sync template agents to root .claude/agents
# Usage:
#   ./scripts/sync-self.sh          # copy
#   ./scripts/sync-self.sh --check  # report drift only (CI mode)

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
source_dir="$repo_root/skills/harness-init/templates/common/.claude/agents"
target_dir="$repo_root/.claude/agents"

CHECK=false
[[ "${1:-}" == "--check" ]] && CHECK=true

if [[ ! -d "$source_dir" ]]; then
    echo "Source folder missing: $source_dir" >&2
    exit 1
fi
mkdir -p "$target_dir"

drift=()

for f in "$source_dir"/*.md; do
    name=$(basename "$f")
    dst="$target_dir/$name"
    copy=true
    if [[ -f "$dst" ]]; then
        if cmp -s "$f" "$dst"; then
            copy=false
        else
            drift+=("$name")
        fi
    else
        drift+=("$name")
    fi

    if [[ "$CHECK" == true ]]; then
        continue
    fi

    if [[ "$copy" == true ]]; then
        cp "$f" "$dst"
        echo "Synced $name"
    fi
done

# Orphan check
for f in "$target_dir"/*.md; do
    [[ -e "$f" ]] || continue
    name=$(basename "$f")
    if [[ ! -f "$source_dir/$name" ]]; then
        echo "WARN: orphan in target: $name" >&2
        drift+=("(orphan) $name")
    fi
done

if [[ "$CHECK" == true ]]; then
    if (( ${#drift[@]} > 0 )); then
        echo "Drift detected:" >&2
        for d in "${drift[@]}"; do echo "  - $d" >&2; done
        exit 1
    else
        echo "In sync."
        exit 0
    fi
fi

echo ""
echo "Sync complete."
