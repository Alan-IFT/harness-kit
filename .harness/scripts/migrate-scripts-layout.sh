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
#   4  end-state assertion failure (T-020): a wired hook command references (or, in
#      dry-run, would reference) a missing script, or a move did not land.
#      Remediation: run /harness-upgrade to re-land current scripts + rewire hooks.

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
planned_moves=""
move_failed=false

for name in "${known[@]}"; do
    src="$src_dir/$name"
    dst="$dst_dir/$name"
    [[ -f "$src" ]] || continue
    if [[ -e "$dst" && "$FORCE" == false ]]; then
        plan+=("SKIP  scripts/$name (already present at .harness/scripts/$name; use --force to overwrite)")
        continue
    fi
    plan+=("MOVE  scripts/$name -> .harness/scripts/$name")
    planned_moves="$planned_moves $name"
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
        # Move verification (T-020 / FR-P2): under `set -uo` (no -e) a failed git mv /
        # mv would otherwise pass silently. A failed move leaves the source in place,
        # so the presence-gated settings rewire below simply stays OFF for that
        # variant — no new dangle is ever created by a failed move; the run is marked
        # incongruent and exits 4.
        if [[ ! -f "$dst" ]]; then
            plan+=("MOVE-FAILED  scripts/$name (move did not land — see git output above)")
            move_failed=true
        fi
    fi
done

# target_present <name>: is .harness/scripts/<name> on disk (apply mode: moves above
# already ran, disk is ground truth) or projected to land there (dry-run: a planned
# MOVE counts)? Gates the per-variant settings rewire below (T-020 / FR-P2).
target_present() {
    local tp_name="$1"
    [[ -f "$dst_dir/$tp_name" ]] && return 0
    if [[ "$DRY_RUN" == true ]]; then
        case " $planned_moves " in *" $tp_name "*) return 0 ;; esac
    fi
    return 1
}

# --- hook-spec adapter (T-16) ---------------------------------------------------
# This flow no longer CARRIES any hook command byte-form: it ASKS the hook wiring
# spec (hook-spec.sh), the single source of truth for `(tool, target OS) -> command`.
# resilient_cmd is RETIRED. This flow runs from a project root with NO template-root
# argument and may execute in a project that predates the spec entirely, so "spec
# absent" is a normal, expected state — see the SPEC-GAP branch below.
#
# FUNCTIONS + inert scalars ONLY: nothing below runs at definition time and no flow
# variable is READ at definition time. Candidate resolution is LAZY (first query) and
# memoised, so it happens long after $dst_dir is bound.
#
# Failure convention — there is NO third return path: either exit 0 with the spec's
# bytes in hsa_out, or non-zero with hsa_out="". No default, no fallback, no embedded
# copy. That is what keeps guard-rm fail-CLOSED by construction: a caller with no
# answer writes NOTHING and can never emit a permissive guard command.
#
# NEVER write x="$(hsa_command ...)": command substitution forks a subshell and every
# cache write dies with it. Use the out variable hsa_out. `$(hsa_path)` IS fine — it
# is a pure reader.
#
# Cross-shell prohibition (spec header): this adapter only ever forms `hook-spec.sh`
# candidates and runs them with `bash`, so the MSYS CR-corruption is unreachable.
hsa_bin=""            # ""  = not resolved yet
                      # "-" = resolved, NOT FOUND (a real path can never be "-")
hsa_out=""            # the last successful answer; "" after any failure
hsa_n=0               # cache length; the three arrays below are index-addressed
hsa_keys=(); hsa_vals=(); hsa_rcs=()   # parallel indexed arrays, <=9 entries, linear scan
                                       # (deliberately NOT `declare -A`: bash 3.2 compatible,
                                       #  matching the rest of this file)

hsa_resolve() {                         # lazy; the body runs at most once per run
    [[ -n "$hsa_bin" ]] && return 0
    local c
    local cands=()
    cands+=("$(dirname -- "$0")/hook-spec.sh")        # unconditional, so the expansion
    [[ -n "${dst_dir:-}" ]] && cands+=("$dst_dir/hook-spec.sh")   # below is never an
    for c in "${cands[@]}"; do                        # empty-array expansion under set -u
        [[ -f "$c" ]] && { hsa_bin="$c"; return 0; }
    done
    hsa_bin="-"
    return 0
}

hsa_path() {
    if [[ "$hsa_bin" == "-" || -z "$hsa_bin" ]]; then printf '%s' "not found"
    else printf '%s' "$hsa_bin"; fi
}

hsa_query() {                           # $1 = cache key, $2.. = spec argv
    local k="$1"; shift
    local i v rc
    for (( i = 0; i < hsa_n; i++ )); do          # C-STYLE loop over an explicit counter.
        if [[ "${hsa_keys[$i]}" == "$k" ]]; then # NEVER `for i in "${!hsa_keys[@]}"`: an
            hsa_out="${hsa_vals[$i]}"            # empty-array expansion is an UNBOUND
            return "${hsa_rcs[$i]}"              # VARIABLE error under set -u on bash
        fi                                       # < 4.4, incl. the macOS 3.2 this array
    done                                         # choice exists for.
    hsa_resolve
    v=""; rc=1
    if [[ "$hsa_bin" != "-" ]]; then
        v="$(bash "$hsa_bin" "$@" 2>/dev/null)"; rc=$?     # set -uo, no -e: capture rc explicitly
        (( rc == 0 )) && [[ -n "$v" ]] || { v=""; rc=1; }  # exit 2 AND empty stdout both land here
    fi
    hsa_keys[$hsa_n]="$k"; hsa_vals[$hsa_n]="$v"; hsa_rcs[$hsa_n]="$rc"
    hsa_n=$(( hsa_n + 1 ))
    hsa_out="$v"
    return "$rc"
}

hsa_command() { hsa_query "cmd/$1/$2" command "$1" "$2"; }
hsa_hostos()  { hsa_query "hostos"    hostos; }

# str_replace_all <haystack> <needle> <replacement> — literal replace-all immune to
# bash 5.2's `&`-means-matched-text rule in ${var//pat/repl} (the resilient command
# carries a literal `&`). Splits on the needle and concatenates verbatim. Mirrors PS
# String.Replace (already literal).
str_replace_all() {
    local rest="$1" needle="$2" repl="$3" out=""
    while [[ "$rest" == *"$needle"* ]]; do
        out="$out${rest%%"$needle"*}$repl"
        rest="${rest#*"$needle"}"
    done
    printf '%s' "$out$rest"
}

# Settings rewire — surgical substring replace on the RAW text (never re-serialize:
# that would reorder keys and strip _comment / _doc_sync_hook doc keys). Replaces
# ALL occurrences of the harness command path prefixes (Stop command, PreToolUse
# command, permissions.allow entry, _doc_sync_hook doc string).
# T-020 (RC-1 fix): each of the four {harness-sync,guard-rm} x {ps1,sh} variants is
# rewired ONLY when its target is (projected) present at .harness/scripts/ — a rewire
# can no longer point a hook at a file that never landed. The unconditional double-
# prefix collapse stays last, so the transform remains a fixed point: already-migrated
# text maps to itself and a second run is a true no-op (no .bak, no write).
# Known cosmetic nuance (gate F-4): when only ONE shell variant's target is present,
# doc strings that mention both variants end half-migrated (the absent variant keeps
# the old path). Idempotent and harmless — the congruence scan below only checks
# "command" lines, never doc keys.
settings_new="$(cat "$settings")"
for tool_ext in harness-sync.ps1 harness-sync.sh guard-rm.ps1 guard-rm.sh; do
    if target_present "$tool_ext"; then
        tool_base="${tool_ext%.*}"
        tool_suffix="${tool_ext##*.}"
        settings_new="$(printf '%s\n' "$settings_new" \
            | sed -e "s|scripts/$tool_base\.$tool_suffix|.harness/scripts/$tool_base.$tool_suffix|g")"
    fi
done
settings_new="$(printf '%s\n' "$settings_new" | sed -e 's|\.harness/\.harness/scripts/|.harness/scripts/|g')"

# Brittle -> resilient rewrite (T-12 / A8, design §4.3). The prefix rewire above only
# adds `.harness/`; it does NOT make the hook fail-open/closed + $CLAUDE_PROJECT_DIR-
# anchored. For each {tool}x{ext}, if the `.harness/`-prefixed brittle command VALUE is
# present verbatim AND its target is (projected) present, swap the WHOLE value for the
# OS-picked resilient string. Pure ordinal bash substring replace (no sed) so the
# resilient `&`/`|`/`;` are inert. Double-quote-bounded needle -> idempotent (a second
# run sees the resilient value, not the bare brittle "command", so no .bak churn — B10)
# and gated on target_present so a brittle command pointing at a missing script is left
# for the terminal scan to flag. R4: only the harness tool names are eligible.
for s32_tool in harness-sync guard-rm ambient-prompt ambient-reset; do
    for s32_ext in ps1 sh; do
        s32_target="$s32_tool.$s32_ext"
        target_present "$s32_target" || continue
        if [[ "$s32_ext" == "ps1" ]]; then
            s32_brittle="pwsh -NoProfile -File .harness/scripts/$s32_target"
            s32_os=windows
        else
            s32_brittle="bash .harness/scripts/$s32_target"
            s32_os=unix
        fi
        s32_needle="\"$s32_brittle\""
        if [[ "$settings_new" == *"$s32_needle"* ]]; then
            # T-16: the byte-form comes from the hook wiring spec. Spec unavailable =>
            # the EXISTING command value is left byte-untouched (never emptied, never
            # improvised) and a SPEC-GAP record enters the plan. Exit stays 0: the value
            # is the pre-existing one and its target was already proven present, so a
            # partially repairable project does not become unrepairable.
            if hsa_command "$s32_tool" "$s32_os"; then
                s32_cmd="$hsa_out"
                settings_new="$(str_replace_all "$settings_new" "$s32_needle" "\"$s32_cmd\"")"
            else
                plan+=("SPEC-GAP  .claude/settings.json ($s32_tool.$s32_ext: hook wiring spec unavailable at $(hsa_path) — command left unchanged; run /harness-upgrade)")
            fi
        fi
    done
done

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

# --- Terminal hook<->script congruence scan (T-020 / FR-P1) -----------------------
# Asserts the END STATE: every script path referenced by a `"command"` line in the
# FINAL settings text resolves to a file that exists (apply mode: the text is RE-READ
# from disk after the moves + write, so a settings write that never landed — read-only
# file, disk full — is caught too; disk is ground truth) or is projected to exist
# (dry-run scans the in-memory projection: a planned MOVE counts). Any miss prints an
# explicit CONGRUENCE-FAIL line and the run exits 4 — silent danglement is never a
# reachable end state.
# Known asymmetry (B9): the dry-run projection is ADDITIVE-only — a hook wired to a
# legacy scripts/<name> that exists NOW but is planned to MOVE still passes the disk
# test in dry-run, yet apply exits 4 after the move; apply is authoritative.
# The path ERE is LEFT-BOUNDED (quote / space / `=` / line start) so a custom hook
# whose dirname merely ENDS in `scripts/` (e.g. build-scripts/deploy.sh) can never
# match (gate C1). Anything the ERE cannot parse is ignored — fail-open diagnosis
# (R4): the scan only flags PARSED tokens whose target file is missing.
# Line-scoping to "command" lines is deliberate: permissions.allow entries and the
# _doc_sync_hook / _ambient_hook doc strings mention BOTH shell variants and must not
# force both to exist (only the wired variant is load-bearing).
cong_lines=()
ph_open="{{"   # assembled at runtime: this shipped helper must not carry a literal token
if [[ "$DRY_RUN" == true ]]; then
    scan_text="$settings_new"
else
    scan_text="$(cat "$settings")"
fi
while IFS= read -r cmd_line; do
    case "$cmd_line" in *'"command"'*) : ;; *) continue ;; esac
    trimmed="$(printf '%s' "$cmd_line" | sed -e 's|^[[:space:]]*||' -e 's|[[:space:]]*$||')"
    if [[ "$cmd_line" == *"$ph_open"* ]]; then
        cong_lines+=("CONGRUENCE-FAIL  $trimmed -> unresolved placeholder token")
    fi
    while IFS= read -r ref_path; do
        [[ -z "$ref_path" ]] && continue
        present=false
        [[ -f "$root/$ref_path" ]] && present=true
        if [[ "$present" == false && "$DRY_RUN" == true ]]; then
            case "$ref_path" in
                .harness/scripts/*)
                    ref_name="${ref_path#.harness/scripts/}"
                    case " $planned_moves " in *" $ref_name "*) present=true ;; esac
                    ;;
            esac
        fi
        [[ "$present" == false ]] && cong_lines+=("CONGRUENCE-FAIL  $trimmed -> missing $ref_path")
    done < <(printf '%s\n' "$cmd_line" \
        | grep -oE "(^|[\"' =])(\.harness/)?scripts/[A-Za-z0-9._-]+\.(ps1|sh)" \
        | sed -E "s|^[\"' =]||" \
        | sort -u)
done <<< "$scan_text"

print_congruence() {
    (( ${#cong_lines[@]} == 0 )) && return 0
    local cl
    for cl in "${cong_lines[@]}"; do echo "  $cl"; done
    echo "  hint: run /harness-upgrade to re-land current scripts and rewire hook paths"
}

final_exit=0
if [[ "$move_failed" == true ]] || (( ${#cong_lines[@]} > 0 )); then
    final_exit=4
fi

if (( ${#plan[@]} == 0 )); then
    if (( final_exit == 0 )); then
        echo "Already migrated / nothing to do."
        exit 0
    fi
    echo "=== migrate-scripts-layout ==="
    print_congruence
    exit "$final_exit"
fi

if [[ "$DRY_RUN" == true ]]; then
    echo "=== migrate-scripts-layout (dry run) ==="
    for p in "${plan[@]}"; do echo "  $p"; done
    print_congruence
    echo "(dry run — no changes written)"
    exit "$final_exit"
fi

echo "=== migrate-scripts-layout ==="
for p in "${plan[@]}"; do echo "  $p"; done
print_congruence
if (( final_exit == 0 )); then
    echo "Done."
fi
exit "$final_exit"
