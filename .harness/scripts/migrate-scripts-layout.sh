#!/usr/bin/env bash
# migrate-scripts-layout.sh — One-shot upgrade: scripts/ -> .harness/scripts/ (T-007)
# Mirror of migrate-scripts-layout.ps1. See that file for full doc.
#
# For an already-initialized Harness project that placed its harness-owned scripts
# under scripts/. Moves the known harness-owned scripts to .harness/scripts/ and
# rewires the two hook command strings in .claude/settings.json.
#
# Idempotent: a second run is a clean no-op (exit 0). Only the KNOWN harness-owned
# set is touched; your own scripts/<custom> files are never moved.
#
# Usage:
#   bash .harness/scripts/migrate-scripts-layout.sh             # migrate
#   bash .harness/scripts/migrate-scripts-layout.sh --dry-run   # print plan, change nothing
#   bash .harness/scripts/migrate-scripts-layout.sh --force     # overwrite existing targets
#
# Exit codes:
#   0  migrated, or already migrated / nothing to do
#   1  user error (no .claude/settings.json)

set -uo pipefail

DRY_RUN=false
FORCE=false
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --force)   FORCE=true ;;
        *) echo "Unknown argument: $arg" >&2; exit 1 ;;
    esac
done

# Run from the project root (the directory that contains .claude/ and scripts/).
root="$(pwd)"
settings="$root/.claude/settings.json"
src_dir="$root/scripts"
dst_dir="$root/.harness/scripts"

if [[ ! -f "$settings" ]]; then
    echo "migrate-scripts-layout: no .claude/settings.json found at $settings." >&2
    echo "  Run this from the root of an initialized Harness project." >&2
    exit 1
fi

# Known harness-owned movable set (filename-preserved). NOT a blanket scripts/*.
# verification_history.log is intentionally excluded — it regenerates at the new path.
known=(
    verify_all.ps1 verify_all.sh
    harness-sync.ps1 harness-sync.sh
    guard-rm.ps1 guard-rm.sh
    install-hooks.ps1 install-hooks.sh
    archive-task.ps1 archive-task.sh
    baseline.json
)

in_git=false
[[ -d "$root/.git" ]] && in_git=true

plan=()

for name in "${known[@]}"; do
    src="$src_dir/$name"
    dst="$dst_dir/$name"
    [[ -f "$src" ]] || continue
    if [[ -e "$dst" && "$FORCE" == false ]]; then
        plan+=("SKIP  scripts/$name (already present at .harness/scripts/$name; use --force to overwrite)")
        continue
    fi
    plan+=("MOVE  scripts/$name -> .harness/scripts/$name")
    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$dst_dir"
        tracked=false
        if [[ "$in_git" == true ]] && git ls-files --error-unmatch "scripts/$name" &>/dev/null; then
            tracked=true
        fi
        if [[ "$tracked" == true ]]; then
            [[ "$FORCE" == true && -e "$dst" ]] && rm -f "$dst"
            git mv -f "scripts/$name" ".harness/scripts/$name" >/dev/null
        else
            mv -f "$src" "$dst"
        fi
    fi
done

# Settings rewire — surgical substring replace on the RAW text (never re-serialize:
# that would reorder keys and strip _comment / _doc_sync_hook doc keys). Replaces
# ALL occurrences of the two harness command path prefixes (Stop command,
# PreToolUse command, permissions.allow entry, _doc_sync_hook doc string).
# Compute the transformed settings text. The sed pipeline rewrites both path
# prefixes, then collapses any double prefix (`.harness/.harness/scripts/`) that
# results when an already-migrated `.harness/scripts/...` substring matched the
# `scripts/...` target. This makes the transform a fixed point: already-migrated
# text maps to itself, so a second run is a true no-op (no .bak, no write).
settings_new="$(sed -e 's|scripts/harness-sync\.|.harness/scripts/harness-sync.|g' \
                    -e 's|scripts/guard-rm\.|.harness/scripts/guard-rm.|g' \
                    -e 's|\.harness/\.harness/scripts/|.harness/scripts/|g' \
                    "$settings")"

needs_settings=false
if [[ "$settings_new" != "$(cat "$settings")" ]]; then
    needs_settings=true
fi

if [[ "$needs_settings" == true ]]; then
    plan+=("EDIT  .claude/settings.json (rewire harness-sync + guard-rm hook paths)")
    if [[ "$DRY_RUN" == false ]]; then
        stamp="$(date +%Y%m%dT%H%M%S)"
        bak="$settings.bak-$stamp"
        cp "$settings" "$bak"
        printf '%s\n' "$settings_new" > "$settings"
        echo "Backed up settings.json -> $bak"
    fi
fi

if (( ${#plan[@]} == 0 )); then
    echo "Already migrated / nothing to do."
    exit 0
fi

if [[ "$DRY_RUN" == true ]]; then
    echo "=== migrate-scripts-layout (dry run) ==="
    for p in "${plan[@]}"; do echo "  $p"; done
    echo "(dry run — no changes written)"
    exit 0
fi

echo "=== migrate-scripts-layout ==="
for p in "${plan[@]}"; do echo "  $p"; done
echo "Done."
exit 0
