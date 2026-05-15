#!/usr/bin/env bash
# sync-self.sh — Repo-specific dogfood sync (templates/common/ → repo root)
# Mirror of sync-self.ps1. See that file for full doc.
#
# Usage:
#   ./scripts/sync-self.sh          # copy
#   ./scripts/sync-self.sh --check  # report drift only; exit 0 if in sync, 1 otherwise

set -uo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
template_common="$repo_root/skills/harness-init/templates/common"

CHECK=false
[[ "${1:-}" == "--check" ]] && CHECK=true

[[ -d "$template_common" ]] || { echo "templates/common/ not found at $template_common" >&2; exit 1; }

declare -a drift

sync_file() {
    local src="$1" dst="$2" label="$3"
    if [[ -f "$dst" ]] && cmp -s "$src" "$dst"; then
        return 0  # in sync
    fi
    drift+=("$label")
    if [[ "$CHECK" == false ]]; then
        mkdir -p "$(dirname "$dst")"
        cp "$src" "$dst"
        echo "Synced $label"
    fi
}

sync_dir_of_md() {
    local src_dir="$1" dst_dir="$2" label_prefix="$3"
    [[ -d "$src_dir" ]] || { echo "WARN: source missing: $src_dir" >&2; return; }
    mkdir -p "$dst_dir"

    for f in "$src_dir"/*.md; do
        [[ -f "$f" ]] || continue
        name=$(basename "$f")
        dst="$dst_dir/$name"
        sync_file "$f" "$dst" "$label_prefix/$name"
    done

    # Orphan check
    for f in "$dst_dir"/*.md; do
        [[ -f "$f" ]] || continue
        name=$(basename "$f")
        if [[ ! -f "$src_dir/$name" ]]; then
            drift+=("$label_prefix/$name (orphan)")
            [[ "$CHECK" == false ]] && rm -f "$f" && echo "Removed orphan $label_prefix/$name"
        fi
    done
}

# Mapping 1: agents
sync_dir_of_md "$template_common/.harness/agents" "$repo_root/.harness/agents" ".harness/agents"

# Mapping 2: harness-sync scripts
sync_file "$template_common/scripts/harness-sync.ps1" "$repo_root/scripts/harness-sync.ps1" "scripts/harness-sync.ps1"
sync_file "$template_common/scripts/harness-sync.sh"  "$repo_root/scripts/harness-sync.sh"  "scripts/harness-sync.sh"

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

if (( ${#drift[@]} == 0 )); then
    echo "Already in sync."
else
    echo ""
    echo "Sync-self complete."
fi
