#!/usr/bin/env bash
# upgrade-project.sh — Deterministic mechanical layer for /harness-upgrade (T-012).
# Mirror of upgrade-project.ps1. See that file for the full doc + stdout contract.
#
# Brings an already-initialized but STALE harness project up to the current plugin
# layout: relocate scripts to .harness/scripts/, content-refresh the depth-sensitive
# scripts from the current template (so their two-up repo-root derivation is correct —
# relocation alone is NOT enough; insight L31 / DO-1), re-install the pre-commit hook,
# rewire .claude/settings.json hook paths (raw-text, never re-serialized), and
# regenerate verify_all from the current type template while preserving the user's
# B.* customizations.
#
# Run from the PROJECT ROOT. cwd-derived (depth-independent).
#
# Usage:
#   bash upgrade-project.sh --template-root <abs> --type generic --stack "Rust CLI"
#   bash upgrade-project.sh --template-root <abs> --type fullstack --dry-run
#
# Exit codes: 0 success; 1 precondition error; 2 verify_all refresh-blocked (no --force);
#             3 hook conflict (non-stock pre-commit).

set -uo pipefail

DRY_RUN=false
FORCE=false
TYPE=""
STACK=""
PROJECT_NAME=""
TEMPLATE_ROOT=""
TODAY=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)        DRY_RUN=true; shift ;;
        --force)          FORCE=true; shift ;;
        --type)           TYPE="${2:-}"; shift 2 ;;
        --stack)          STACK="${2:-}"; shift 2 ;;
        --project-name)   PROJECT_NAME="${2:-}"; shift 2 ;;
        --template-root)  TEMPLATE_ROOT="${2:-}"; shift 2 ;;
        --today)          TODAY="${2:-}"; shift 2 ;;
        *) echo "upgrade-project: unknown argument: $1" >&2; exit 1 ;;
    esac
done

root="$(pwd)"

# --- preconditions --------------------------------------------------------------
if [[ -z "$TEMPLATE_ROOT" ]]; then
    echo "upgrade-project: --template-root is required (the resolved plugin template cache root)." >&2
    exit 1
fi
template_common_scripts="$TEMPLATE_ROOT/skills/harness-init/templates/common/.harness/scripts"
template_type_scripts="$TEMPLATE_ROOT/skills/harness-init/templates/$TYPE/.harness/scripts"
if [[ ! -d "$template_common_scripts" ]]; then
    echo "upgrade-project: template common scripts not found at $template_common_scripts." >&2
    exit 1
fi
if [[ -z "$TYPE" ]]; then
    echo "upgrade-project: --type is required (fullstack|backend|generic)." >&2
    exit 1
fi
case "$TYPE" in
    fullstack|backend|generic) : ;;
    *) echo "upgrade-project: bad --type '$TYPE' (fullstack|backend|generic)." >&2; exit 1 ;;
esac
if [[ ! -d "$template_type_scripts" ]]; then
    echo "upgrade-project: template type scripts not found at $template_type_scripts." >&2
    exit 1
fi

has_settings=false;  [[ -f "$root/.claude/settings.json" ]] && has_settings=true
has_harness=false;   [[ -d "$root/.harness" ]] && has_harness=true
has_old_sync=false;  { [[ -f "$root/scripts/harness-sync.ps1" ]] || [[ -f "$root/scripts/harness-sync.sh" ]]; } && has_old_sync=true
if [[ "$has_settings" == false && "$has_harness" == false && "$has_old_sync" == false ]]; then
    echo "upgrade-project: this does not look like a harness project (no .claude/settings.json, no .harness/, no scripts/harness-sync.*). Use /harness-adopt for a no-harness project." >&2
    exit 1
fi

[[ -z "$PROJECT_NAME" ]] && PROJECT_NAME="$(basename "$root")"
[[ -z "$TODAY" ]] && TODAY="$(date +%Y-%m-%d)"
stamp="$(date +%Y%m%dT%H%M%S)"

n_moved=0; n_rewritten=0; n_rewired=0; n_added=0; n_conflicts=0
exit_code=0

emit() { printf '%s\n' "$1"; }
verb_prefix() { if [[ "$DRY_RUN" == true ]]; then echo "PLAN"; else echo "RESULT"; fi; }

emit "TYPE|$TYPE"

# --- S1 relocation --------------------------------------------------------------
# INVARIANT: refresh_set (S2 below) == known minus verify_all.{ps1,sh} and baseline.json.
# These two literal arrays are hand-maintained — if you edit one, update the other.
known=(
    verify_all.ps1 verify_all.sh
    harness-sync.ps1 harness-sync.sh
    guard-rm.ps1 guard-rm.sh
    install-hooks.ps1 install-hooks.sh
    archive-task.ps1 archive-task.sh
    migrate-scripts-layout.ps1 migrate-scripts-layout.sh
    baseline.json
)
src_dir="$root/scripts"
dst_dir="$root/.harness/scripts"
in_git=false
[[ -d "$root/.git" ]] && in_git=true

for name in "${known[@]}"; do
    src_file="$src_dir/$name"
    dst_file="$dst_dir/$name"
    [[ -f "$src_file" ]] || continue
    if [[ -e "$dst_file" && "$FORCE" == false ]]; then
        emit "$(verb_prefix)|SKIP|scripts/$name (already at .harness/scripts/$name; --force to overwrite)"
        continue
    fi
    emit "$(verb_prefix)|MOVE|scripts/$name -> .harness/scripts/$name"
    n_moved=$((n_moved + 1))
    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$dst_dir"
        tracked=false
        if [[ "$in_git" == true ]] && git ls-files --error-unmatch "scripts/$name" &>/dev/null; then
            tracked=true
        fi
        if [[ "$tracked" == true ]]; then
            [[ "$FORCE" == true && -e "$dst_file" ]] && rm -f "$dst_file"
            git mv -f "scripts/$name" ".harness/scripts/$name" >/dev/null
        else
            mv -f "$src_file" "$dst_file"
        fi
    fi
done

# --- S2 content-refresh of depth-sensitive scripts (the L31 / DO-1 fix) ---------
# INVARIANT: refresh_set == known (S1 above) minus verify_all.{ps1,sh} and baseline.json.
# Hand-maintained literal arrays — keep in sync; edit one, update the other.
refresh_set=(
    harness-sync.ps1 harness-sync.sh
    install-hooks.ps1 install-hooks.sh
    archive-task.ps1 archive-task.sh
    guard-rm.ps1 guard-rm.sh
    migrate-scripts-layout.ps1 migrate-scripts-layout.sh
)
for name in "${refresh_set[@]}"; do
    tmpl_file="$template_common_scripts/$name"
    [[ -f "$tmpl_file" ]] || continue
    dst_file="$dst_dir/$name"
    if [[ -f "$dst_file" ]] && cmp -s "$tmpl_file" "$dst_file"; then
        emit "$(verb_prefix)|NOOP|.harness/scripts/$name (already current)"
        continue
    fi
    is_new=false
    [[ -f "$dst_file" ]] || is_new=true
    emit "$(verb_prefix)|REFRESH|.harness/scripts/$name (from current template)"
    if [[ "$is_new" == true ]]; then n_added=$((n_added + 1)); else n_rewritten=$((n_rewritten + 1)); fi
    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$dst_dir"
        cp "$tmpl_file" "$dst_file"
    fi
done

# --- S3 settings rewire (verbatim raw-text replace; NEVER re-serialize — DO-3) ---
settings="$root/.claude/settings.json"
if [[ ! -f "$settings" ]]; then
    emit "RESULT|SKIP|.claude/settings.json absent — settings rewire skipped (non-Claude-Code project)"
else
    settings_new="$(sed -e 's|scripts/harness-sync\.|.harness/scripts/harness-sync.|g' \
                        -e 's|scripts/guard-rm\.|.harness/scripts/guard-rm.|g' \
                        -e 's|\.harness/\.harness/scripts/|.harness/scripts/|g' \
                        "$settings")"
    if [[ "$settings_new" != "$(cat "$settings")" ]]; then
        emit "$(verb_prefix)|REWIRE|.claude/settings.json (harness-sync + guard-rm hook paths)"
        n_rewired=$((n_rewired + 1))
        if [[ "$DRY_RUN" == false ]]; then
            bak="$settings.bak-$stamp"
            cp "$settings" "$bak"
            emit "BAK|$bak"
            printf '%s\n' "$settings_new" > "$settings"
        fi
    else
        emit "RESULT|NOOP|.claude/settings.json already rewired"
    fi
fi

# --- S4 hook (re)install --------------------------------------------------------
read -r -d '' current_hook_body <<'EOF'
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
# install-hooks.sh writes the body via a heredoc, so the on-disk stock hook ends with a
# trailing newline. Match that exactly when (re)writing.
current_hook_file_content="$current_hook_body"$'\n'

normalize_hook() {
    # Collapse old one-up path prefix to two-up, drop CR, strip leading/trailing blank
    # lines, so the stock-vs-custom test ignores path-depth + CRLF.
    printf '%s' "$1" \
        | sed -e 's|scripts/harness-sync\.|.harness/scripts/harness-sync.|g' \
              -e 's|\.harness/\.harness/scripts/harness-sync\.|.harness/scripts/harness-sync.|g' \
              -e 's|\r$||' \
        | sed -e '/./,$!d' | tac | sed -e '/./,$!d' | tac
}

hook_path="$root/.git/hooks/pre-commit"
norm_current="$(normalize_hook "$current_hook_body")"
if [[ ! -d "$root/.git" ]]; then
    emit "RESULT|SKIP|.git absent — pre-commit hook not installed"
elif [[ ! -f "$hook_path" ]]; then
    emit "$(verb_prefix)|HOOK-INSTALL|.git/hooks/pre-commit (was absent)"
    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$root/.git/hooks"
        printf '%s' "$current_hook_file_content" > "$hook_path"
        chmod +x "$hook_path"
    fi
else
    existing="$(cat "$hook_path")"
    if [[ "$(normalize_hook "$existing")" == "$norm_current" ]]; then
        if cmp -s "$hook_path" <(printf '%s' "$current_hook_file_content"); then
            emit "RESULT|NOOP|.git/hooks/pre-commit already current"
        else
            emit "$(verb_prefix)|HOOK-INSTALL|.git/hooks/pre-commit (was stock pre-T-007; refreshed to new path)"
            if [[ "$DRY_RUN" == false ]]; then
                bak="$hook_path.bak-$stamp"
                cp "$hook_path" "$bak"
                emit "BAK|$bak"
                printf '%s' "$current_hook_file_content" > "$hook_path"
                chmod +x "$hook_path"
            fi
        fi
    else
        emit "CONFLICT|hook|.git/hooks/pre-commit is non-stock (hand-customized) — NOT overwritten; merge the drift check in manually"
        n_conflicts=$((n_conflicts + 1))
        exit_code=3
    fi
fi

# --- S5 verify_all regenerate (splice / regen / halt) ---------------------------
begin_marker="# >>> HARNESS:B-CUSTOM:BEGIN"
end_marker="# >>> HARNESS:B-CUSTOM:END"

substitute_placeholders() {
    # $1 = file path; prints substituted content. Only the 3 whitelisted placeholders.
    # The placeholder tokens are assembled from pieces (o + NAME + c) rather than written
    # as double-brace literals, so this helper file does NOT itself contain an
    # unsubstituted placeholder token — keeps test-init's "no unresolved placeholders"
    # cleanliness check happy when the helper is copied into a generated project. Still the
    # same 3 D.2-whitelisted names; no new placeholder introduced.
    local stack_val="$STACK"
    [[ -z "$stack_val" ]] && stack_val="$TYPE"
    local o="{{" c="}}"
    sed -e "s|${o}PROJECT_NAME${c}|$PROJECT_NAME|g" \
        -e "s|${o}STACK${c}|$stack_val|g" \
        -e "s|${o}TODAY${c}|$TODAY|g" \
        "$1"
}

# Returns 0 (true) if exactly one BEGIN, one END, BEGIN strictly before END.
markers_clean() {
    local file_content="$1"
    local nb ne
    # -F (fixed string, never combined with -i) — markers contain ( ) > < which are
    # regex-significant; L27 only bans the -F -i combination, -F alone is safe.
    nb=$(printf '%s\n' "$file_content" | grep -cF -- "$begin_marker" || true)
    ne=$(printf '%s\n' "$file_content" | grep -cF -- "$end_marker" || true)
    [[ "$nb" -eq 1 && "$ne" -eq 1 ]] || return 1
    local bl el
    bl=$(printf '%s\n' "$file_content" | grep -nF -- "$begin_marker" | head -1 | cut -d: -f1)
    el=$(printf '%s\n' "$file_content" | grep -nF -- "$end_marker" | head -1 | cut -d: -f1)
    [[ "$bl" -lt "$el" ]] || return 1
    return 0
}

# Prints the inner block (lines strictly between BEGIN and END).
marker_inner_block() {
    printf '%s\n' "$1" | awk -v b="$begin_marker" -v e="$end_marker" '
        index($0,b)==1 {inb=1; next}
        index($0,e)==1 {inb=0}
        inb==1 {print}
    '
}

# Returns 0 (true) if the inner block is stub-only (no real B.* command).
block_is_stub() {
    local block="$1" line t
    while IFS= read -r line; do
        t="$(printf '%s' "$line" | sed -e 's|^[[:space:]]*||' -e 's|[[:space:]]*$||')"
        [[ -z "$t" ]] && continue
        case "$t" in
            \#*) continue ;;
            *SKIP*) continue ;;
            Step\ *|step\ *) continue ;;
            '{'|'}') continue ;;
            return\ *) continue ;;
            *) return 1 ;;
        esac
    done <<< "$block"
    return 0
}

# Returns 0 (true) if an OLD non-marker verify_all carries custom B.* checks.
old_b_customized() {
    local file_content="$1" line t
    while IFS= read -r line; do
        t="$(printf '%s' "$line" | sed -e 's|^[[:space:]]*||' -e 's|[[:space:]]*$||')"
        # bash step "B.x" ... with a non-SKIP status
        if [[ "$t" == step\ \"B.* ]] && [[ "$t" != *'"SKIP"'* ]]; then return 0; fi
        case "$t" in
            \#*) continue ;;
            *cargo*|*pytest*|*"npm "*|*"pnpm "*|*"yarn "*|*"go build"*|*"go test"*|*dotnet*|*gradle*|*mvn*|*ruff*|*mypy*|*eslint*|*tsc*) return 0 ;;
        esac
    done <<< "$file_content"
    return 1
}

for shell in ps1 sh; do
    proj_file="$dst_dir/verify_all.$shell"
    tmpl_file="$template_type_scripts/verify_all.$shell.tmpl"
    if [[ ! -f "$tmpl_file" ]]; then
        emit "RESULT|SKIP|verify_all.$shell (no type template)"
        continue
    fi
    fresh="$(substitute_placeholders "$tmpl_file")"

    verb="VERIFY-REGEN"
    final_text="$fresh"
    if [[ -f "$proj_file" ]]; then
        old_raw="$(cat "$proj_file")"
        if markers_clean "$old_raw"; then
            old_block="$(marker_inner_block "$old_raw")"
            if block_is_stub "$old_block"; then
                verb="VERIFY-REGEN"
            else
                # SPLICE old block into fresh
                if markers_clean "$fresh"; then
                    final_text="$(printf '%s\n' "$fresh" | awk -v b="$begin_marker" -v e="$end_marker" -v blk="$old_block" '
                        index($0,b)==1 { print; print blk; skip=1; next }
                        index($0,e)==1 { skip=0 }
                        skip==1 { next }
                        { print }
                    ')"
                    verb="VERIFY-SPLICE"
                else
                    verb="VERIFY-REGEN"
                fi
            fi
        else
            if old_b_customized "$old_raw" && [[ "$FORCE" == false ]]; then
                emit "VERIFY-HALT|$shell"
                emit "CONFLICT|verify_all|verify_all.$shell has no HARNESS:B-CUSTOM markers but appears to carry custom B.* checks — left untouched (nothing lost). Re-run with --force to overwrite; a timestamped .bak will be written first, preserving your old checks."
                n_conflicts=$((n_conflicts + 1))
                exit_code=2
                continue
            fi
            verb="VERIFY-REGEN"
        fi
    fi

    # Idempotence: byte-identical -> NOOP.
    if [[ -f "$proj_file" ]] && [[ "$(cat "$proj_file")" == "$final_text" ]]; then
        emit "RESULT|NOOP|verify_all.$shell already current"
        continue
    fi

    is_new=false
    [[ -f "$proj_file" ]] || is_new=true
    emit "$(verb_prefix)|$verb|verify_all.$shell"
    if [[ "$is_new" == true ]]; then n_added=$((n_added + 1)); else n_rewritten=$((n_rewritten + 1)); fi
    if [[ "$DRY_RUN" == false ]]; then
        if [[ -f "$proj_file" ]]; then
            bak="$proj_file.bak-$stamp"
            cp "$proj_file" "$bak"
            emit "BAK|$bak"
        fi
        printf '%s\n' "$final_text" > "$proj_file"
    fi
done

emit "SUMMARY|added=$n_added moved=$n_moved rewritten=$n_rewritten rewired=$n_rewired conflicts=$n_conflicts"
exit "$exit_code"
