#!/usr/bin/env bash
# test-verify-i6.sh — Regression for the verify_all I.6 gap-tolerant retired-claim matcher (v0.18.0+)
# Bash twin of test-verify-i6.ps1. Mirrors the same fixture corpus + assertion set.
#
# The driver does NOT source verify_all.sh (that would run all 30 checks). It
# re-declares the I.6 matcher predicate (regex builder + per-line scan + line-scoped
# exclude) as a self-contained function, kept in lockstep with the live script by a
# structural assertion (the live i6_banned array must match this driver's copy
# verbatim, including entry #10's exclude=.claude/).
#
# Driver-vs-live lockstep matrix (v0.18+ T-005 hardening — both rows × both columns
# do verbatim per-entry × 4-field comparison; no cell is count-only):
#
#                    | verify_all.sh | verify_all.ps1 |
#     test-verify.sh | verbatim      | verbatim       |
#     test-verify.ps1| verbatim      | verbatim       |
#
# Usage:
#   bash .harness/scripts/test-verify-i6.sh              # full run, temp dir auto-cleaned
#   bash .harness/scripts/test-verify-i6.sh --keep-temp  # keep the fixture temp dir for inspection
set -uo pipefail

# Single canonical "no value" sentinel (T-005 design §3.2 / Q-1). Used by
# i6_format_field so empty fields in bash records, `$null` in PS source, and
# empty PS arrays all collapse to one renderable token before the comparator runs.
I6_EMPTY='<empty>'

KEEP_TEMP=false
EMIT_HITS=false
EMIT_DIR=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --keep-temp) KEEP_TEMP=true; shift ;;
        --emit-hits) EMIT_HITS=true; EMIT_DIR="${2:-}"; shift 2 ;;
        *) echo "Unknown arg: $1" >&2; exit 1 ;;
    esac
done

# Script lives at .harness/scripts/ — repo root is two levels up.
repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$repo_root"

pass=0
fail=0
failures=()

assert() {
    local name="$1" ok="$2"
    if [[ "$ok" == "1" ]]; then
        echo "  PASS  $name"
        pass=$((pass + 1))
    else
        echo "  FAIL  $name"
        fail=$((fail + 1))
        failures+=("$name")
    fi
}

# ---------------------------------------------------------------------------
# I.6 matcher predicate — a self-contained re-declaration of verify_all.sh's
# logic (§3.2/§3.3 of the design). Kept in lockstep by the structural assertion.
# ---------------------------------------------------------------------------
i6_gap_default=40
# The 13-entry banned list — must be byte-identical to verify_all.sh's i6_banned.
i6_banned=(
    "scaffolding-only|harness-adopt has been fully automated since v0.3||"
    "Composed~into~\`CLAUDE.md\`|rules are not composed into CLAUDE.md since v0.10|not~no longer~referenced|20"
    "composed~by~filename~order|rules not composed since v0.10||"
    "composition~order~in~CLAUDE.md|no composition in CLAUDE.md since v0.10|not~no longer|"
    "regenerates~CLAUDE.md|harness-sync does not regenerate CLAUDE.md since v0.10||"
    "regenerates~\`CLAUDE.md\`|harness-sync does not regenerate CLAUDE.md since v0.10||"
    "regenerated~CLAUDE.md|CLAUDE.md is a static stub since v0.10||"
    "regenerated~\`CLAUDE.md\`|CLAUDE.md is a static stub since v0.10||"
    "Generated~from~.harness/rules|CLAUDE.md not generated from rules since v0.10||"
    ".harness/~→~CLAUDE.md|harness-sync target is .claude/, not CLAUDE.md, since v0.10|.claude/|"
    "harness-sync~生成~CLAUDE.md|v0.10 起 harness-sync 不再生成 CLAUDE.md|不|"
    "harness-sync~合成~CLAUDE.md|v0.10 起规则不再合成进 CLAUDE.md|不|"
    "重新生成的~CLAUDE.md|v0.10 起 CLAUDE.md 是 stub，不再被重新生成||"
)
i6_exempt_dirs=(
    "docs/features/"
    "参考/"
)
# The canonical list for I.6 exempt FILES at this driver's version. Element-wise
# equality against verify_all.{ps1,sh} is asserted by Assertion 3c (T-005 §3.5).
i6_exempt_files=(
    "CHANGELOG.md"
    "architecture.html"
    "docs/walkthrough.html"
    ".harness/scripts/verify_all.ps1"
    ".harness/scripts/verify_all.sh"
    ".harness/scripts/test-verify-i6.ps1"
    ".harness/scripts/test-verify-i6.sh"
)
# Single source of truth for the banned-list entry count. Bumping to 14 = edit here
# AND in test-verify-i6.ps1's $script:I6ExpectedEntryCount.
i6_expected_entry_count=13

i6_build_regex() {                       # $1 = ~-joined anchors  $2 = gap budget
    local anchors="$1" gap="$2" out="" first=1 tok esc
    local IFS='~'
    for tok in $anchors; do
        esc=$(printf '%s' "$tok" | sed 's/[.[\](){}*+?|^$\\]/\\&/g')
        if (( first )); then out="$esc"; first=0; else out="${out}.{0,${gap}}${esc}"; fi
    done
    printf '%s' "$out"
}

# i6_scan_file FILE — emits one "INDEX:line_no" line per banned entry that hits the
# file (INDEX is 1-based into i6_banned). Empty output = no hit. Mirrors the
# verify_all.sh per-file inner loop including the line-scoped exclude.
i6_scan_file() {
    local scan_file="$1"
    [[ -f "$scan_file" ]] || return 0
    local idx=0 entry e_anchors e_reason e_exclude e_gap rx match line_no full_line
    for entry in "${i6_banned[@]}"; do
        idx=$((idx + 1))
        IFS='|' read -r e_anchors e_reason e_exclude e_gap <<< "$entry"
        rx=$(i6_build_regex "$e_anchors" "${e_gap:-$i6_gap_default}")
        match=$(grep -E -n -i -m1 -- "$rx" "$scan_file" 2>/dev/null) || continue
        line_no="${match%%:*}"
        full_line="${match#*:}"
        local excluded=0
        if [[ -n "$e_exclude" ]]; then
            local xtoks=() old_ifs="$IFS"
            IFS='~'; read -r -a xtoks <<< "$e_exclude"; IFS="$old_ifs"
            shopt -s nocasematch
            local xtok
            for xtok in "${xtoks[@]}"; do
                [[ -z "$xtok" ]] && continue
                [[ "$full_line" == *"$xtok"* ]] && { excluded=1; break; }
            done
            shopt -u nocasematch
        fi
        (( excluded )) && continue
        printf '%s:%s\n' "$idx" "$line_no"
    done
}

# i6_dir_exempt PATH — returns 0 (exempt) if PATH is under an exempt dir.
i6_dir_exempt() {
    local p="$1" ed
    for ed in "${i6_exempt_dirs[@]}"; do
        [[ "$p" == "$ed"* ]] && return 0
    done
    return 1
}

# i6_file_exempt PATH — byte-mirror of verify_all.sh's exempt-files membership test.
# `[[ == ]]` with quoted RHS is case-sensitive literal — symmetric to PS's
# `-ccontains` (insight L7 / NFR-4).
i6_file_exempt() {
    local p="$1" ef
    for ef in "${i6_exempt_files[@]}"; do
        [[ "$p" == "$ef" ]] && return 0
    done
    return 1
}

# i6_exempt PATH — combined predicate: file-exempt OR dir-exempt. Mirrors live
# verify_all.sh skip order at lines 562-565.
i6_exempt() {
    i6_file_exempt "$1" && return 0
    i6_dir_exempt "$1"
}

# i6_format_field VALUE — normalize a field value to a single renderable canonical
# token. Empty string collapses to $I6_EMPTY; everything else passes through.
# Bash records are already `~`-joined for lists, so no array-path branch is needed.
i6_format_field() {
    if [[ -z "$1" ]]; then printf '%s' "$I6_EMPTY"; else printf '%s' "$1"; fi
}

# i6_field_eq A B — the ONLY new comparator in the lockstep code. `[[ == ]]` with
# explicit double-quoted RHS is case-sensitive literal (no glob, no case-fold).
i6_field_eq() {
    [[ "$(i6_format_field "$1")" == "$(i6_format_field "$2")" ]]
}

# ---------------------------------------------------------------------------
# Fixture corpus — design §7.2. One file per case. Shared by --emit-hits mode
# and the full regression run.
# ---------------------------------------------------------------------------
# fixture -> "ENTRY" expected hit (entry index, 1-based) or "NONE"
fx_names=(  fx-bypass.md fx-adjacent.md fx-accurate.md fx-case.md fx-meta-backtick.md \
            fx-meta-arrow.md fx-arrow-accurate.md fx-gap-exact.md fx-gap-over.md \
            fx-negation-pre.md fx-historical.md fx-empty.md fx-multiline.md \
            fx-e1.md fx-e3.md fx-e4.md fx-e9.md fx-e11.md fx-e12.md fx-e13.md )
fx_expect=( 5 5 NONE 5 6 \
            10 NONE 5 NONE \
            NONE NONE NONE NONE \
            1 3 4 9 11 12 13 )

new_fixture_corpus() {                # $1 = target dir
    local d="$1"
    local w='printf %s'
    printf '%s' "harness-sync regenerates the static stub CLAUDE.md"                              > "$d/fx-bypass.md"
    printf '%s' "regenerates CLAUDE.md"                                                           > "$d/fx-adjacent.md"
    printf '%s' ".claude/agents/ is regenerated by harness-sync from .harness/agents/"            > "$d/fx-accurate.md"
    printf '%s' "Harness-sync Regenerates the CLAUDE.md stub"                                     > "$d/fx-case.md"
    printf '%s' 'harness-sync regenerates `CLAUDE.md`'                                            > "$d/fx-meta-backtick.md"
    printf '%s' ".harness/ → CLAUDE.md"                                                           > "$d/fx-meta-arrow.md"
    printf '%s' ".harness/agents + .harness/skills → .claude/ (CLAUDE.md is a static stub since v0.10)" > "$d/fx-arrow-accurate.md"
    printf '%s' "regenerates$(printf '%.0sX' $(seq 1 40))CLAUDE.md"                               > "$d/fx-gap-exact.md"
    printf '%s' "regenerates$(printf '%.0sX' $(seq 1 41))CLAUDE.md"                               > "$d/fx-gap-over.md"
    printf '%s' 'rules are referenced, not composed into `CLAUDE.md`'                             > "$d/fx-negation-pre.md"
    printf '%s\n%s' 'The original v0.2 design' \
        'composed `.harness/rules/*.md` into a single `CLAUDE.md` so the AI could read it'        > "$d/fx-historical.md"
    : > "$d/fx-empty.md"
    printf '%s\n%s\n' 'regenerates' 'CLAUDE.md'                                                   > "$d/fx-multiline.md"
    printf '%s' "this skill is scaffolding-only for now"                                          > "$d/fx-e1.md"
    printf '%s' "rules are composed by filename order at startup"                                 > "$d/fx-e3.md"
    printf '%s' "the composition order in CLAUDE.md is alphabetical"                              > "$d/fx-e4.md"
    printf '%s' "CLAUDE.md is Generated from .harness/rules at sync time"                         > "$d/fx-e9.md"
    printf '%s' "harness-sync 生成 CLAUDE.md 的过程"                                              > "$d/fx-e11.md"
    printf '%s' "harness-sync 合成 CLAUDE.md 的旧流程"                                            > "$d/fx-e12.md"
    printf '%s' "这是重新生成的 CLAUDE.md 文件"                                                   > "$d/fx-e13.md"
    # AC-14 negative-regression fixture (T-005 §6): a banned-phrase file at a
    # non-exempt path inside the temp dir. The matcher MUST report a hit; if the
    # exemption predicate ever returns true for all paths (a future-bug scenario),
    # this fixture flips first.
    printf '%s' "harness-sync regenerates CLAUDE.md"                                              > "$d/fx-ac14-nonexempt.md"
}

# --- --emit-hits mode: write the corpus into EMIT_DIR, print "fixture<TAB>idx idx"
# per file, exit. Used by the PS twin's cross-shell parity assertion.
if [[ "$EMIT_HITS" == "true" ]]; then
    [[ -d "$EMIT_DIR" ]] || { echo "--emit-hits requires an existing directory" >&2; exit 2; }
    new_fixture_corpus "$EMIT_DIR"
    for name in "${fx_names[@]}"; do
        raw=$(i6_scan_file "$EMIT_DIR/$name")
        idxs=$(printf '%s\n' "$raw" | grep -oE '^[0-9]+' | sort -n | tr '\n' ' ' | sed 's/ $//')
        if [[ -n "$idxs" ]]; then printf '%s\t%s\n' "$name" "$idxs"; else printf '%s\n' "$name"; fi
    done
    exit 0
fi

echo "=== test-verify-i6: I.6 gap-tolerant matcher regression (bash) ==="
echo "Repo: $repo_root"
echo ""

fx_tmp=$(mktemp -d -t harness-verify-i6-XXXXXX 2>/dev/null || mktemp -d)
cleanup() {
    if [[ "$KEEP_TEMP" == "true" ]]; then
        echo ""
        echo "Fixture temp kept: $fx_tmp"
    else
        rm -rf "$fx_tmp" 2>/dev/null || true
    fi
}
trap cleanup EXIT
new_fixture_corpus "$fx_tmp"

# ---------------------------------------------------------------------------
# Assertion 1 — behavioral: per fixture, the matcher hits/does-not-hit as expected.
# ---------------------------------------------------------------------------
echo "--- Assertion 1: per-fixture behavioral hit/no-hit ---"
declare -A bash_hits   # fixture -> "idx idx ..." (space-joined entry indexes)
for i in "${!fx_names[@]}"; do
    name="${fx_names[$i]}"
    expect="${fx_expect[$i]}"
    raw=$(i6_scan_file "$fx_tmp/$name")
    idxs=$(printf '%s\n' "$raw" | grep -oE '^[0-9]+' | sort -n | tr '\n' ' ' | sed 's/ $//')
    bash_hits["$name"]="$idxs"
    if [[ "$expect" == "NONE" ]]; then
        [[ -z "$idxs" ]] && assert "$name expects NO hit" 1 \
                          || assert "$name expects NO hit (got entry $idxs)" 0
    else
        [[ " $idxs " == *" $expect "* ]] \
            && assert "$name expects HIT on entry #$expect" 1 \
            || assert "$name expects HIT on entry #$expect (got '$idxs')" 0
    fi
done

# ---------------------------------------------------------------------------
# Assertion 2 — cross-shell parity: the PS twin produces the identical hit set.
# ---------------------------------------------------------------------------
echo ""
echo "--- Assertion 2: cross-shell parity (bash vs PowerShell) ---"
ps_exe=""
for cand in pwsh powershell; do
    command -v "$cand" >/dev/null 2>&1 && { ps_exe="$cand"; break; }
done
if [[ -z "$ps_exe" ]]; then
    assert "cross-shell parity (PowerShell not found — SKIPPED)" 1
else
    # The PS twin exposes --emit-hits FX_TMP: prints "fixture<TAB>idx,idx" per file.
    ps_out=$("$ps_exe" -NoProfile -File "$repo_root/.harness/scripts/test-verify-i6.ps1" --emit-hits "$fx_tmp" 2>/dev/null)
    parity_ok=1
    for name in "${fx_names[@]}"; do
        ps_line=$(printf '%s\n' "$ps_out" | grep -F "$name"$'\t' | head -1)
        ps_idxs="${ps_line#*$'\t'}"
        [[ "$ps_line" == "$name" ]] && ps_idxs=""   # no tab => no hits
        # normalize: comma-or-space joined, sorted
        ps_norm=$(printf '%s' "$ps_idxs" | tr ', ' '\n\n' | grep -oE '[0-9]+' | sort -n | tr '\n' ' ' | sed 's/ $//')
        bash_norm="${bash_hits[$name]}"
        if [[ "$ps_norm" != "$bash_norm" ]]; then
            parity_ok=0
            echo "    divergence on $name: bash='$bash_norm' ps='$ps_norm'"
        fi
    done
    assert "cross-shell parity: bash and PowerShell agree on every fixture's hit set" "$parity_ok"
fi

# ---------------------------------------------------------------------------
# Assertion 3 — structural lockstep with the live verify_all scripts.
# T-005 split: 3a = verify_all.sh banned-list, 3b = verify_all.ps1 banned-list,
# 3c = exempt-file + exempt-dir lockstep. All four-field verbatim, both shells.
# ---------------------------------------------------------------------------
echo ""
echo "--- Assertion 3: structural lockstep with live verify_all ---"

# Extract the i6_banned record lines (source text, trimmed) from a bash file —
# lines between 'i6_banned=(' and the closing ')'. Both verify_all.sh and this
# driver use identical bash source escaping, so comparing source text is exact.
extract_i6_banned() {
    awk '/^i6_banned=\(/{f=1;next} f&&/^\)/{f=0} f{print}' "$1" \
        | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

# Symmetric counterpart for the PS-side: projects verify_all.ps1's $banned array
# into the same bash-record canonical form `anchors|reason|exclude|gap` so the
# same i6_field_eq comparator can be used. The sed pipeline extracts each field
# by literal-keyword anchor (R-2 mitigation: not column-positional). Lists inside
# `@('a','b',...)` are tokenized and `~`-joined to match the bash record shape.
# Fails closed: any line whose extraction returns < 4 fields produces a record
# the count assertion (A3b-1) catches.
extract_ps_banned_records() {
    local ps_path="$1" line anchors reason exclude gap parse_list
    # parse_list `'a','b','c'` -> `a~b~c` (strip surrounding ', join on ~)
    parse_list() {
        local body="$1" t s out=""
        body="${body## }"; body="${body%% }"
        [[ -z "$body" ]] && { printf ''; return 0; }
        local IFS=','
        for t in $body; do
            s="$t"
            s="${s##[[:space:]]}"; s="${s%%[[:space:]]}"
            # strip one leading ' and one trailing ' (PS single-quoted token)
            [[ "$s" == \'*\' ]] && s="${s#\'}" && s="${s%\'}"
            if [[ -z "$out" ]]; then out="$s"; else out="${out}~${s}"; fi
        done
        printf '%s' "$out"
    }
    while IFS= read -r line; do
        # Match only lines that open an entry (literal-keyword anchored).
        [[ "$line" =~ ^[[:space:]]*@\{[[:space:]]*anchors[[:space:]]*=[[:space:]]*@\( ]] || continue
        # Anchors body — between `anchors = @(` and the next `)`
        anchors=$(printf '%s' "$line" | sed -n 's/.*anchors[[:space:]]*=[[:space:]]*@(\([^)]*\)).*/\1/p')
        # Reason — between `reason = "` and the next `"`
        reason=$(printf '%s' "$line"  | sed -n 's/.*reason[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p')
        # Exclude body — between `exclude = @(` and the next `)`
        exclude=$(printf '%s' "$line" | sed -n 's/.*exclude[[:space:]]*=[[:space:]]*@(\([^)]*\)).*/\1/p')
        # Gap — integer or the literal `$null` token; `$null` -> empty
        gap=$(printf '%s' "$line"     | sed -n 's/.*gap[[:space:]]*=[[:space:]]*\(\$null\|[0-9][0-9]*\).*/\1/p')
        [[ "$gap" == "\$null" ]] && gap=""
        anchors=$(parse_list "$anchors")
        exclude=$(parse_list "$exclude")
        printf '%s|%s|%s|%s\n' "$anchors" "$reason" "$exclude" "$gap"
    done < "$ps_path"
}

# ----- 3a — verify_all.sh i6_banned vs driver -----
live_banned=()
while IFS= read -r ln; do live_banned+=("$ln"); done < <(extract_i6_banned .harness/scripts/verify_all.sh)
self_banned=()
while IFS= read -r ln; do self_banned+=("$ln"); done < <(extract_i6_banned "$0")
# Strip the literal bash double-quote wrapper "..." from each record and decode
# the bash backslash-backtick escape (\` -> `). Entries #2 / #6 / #8 use this escape
# to carry the literal `CLAUDE.md` code-span anchor in a bash double-quoted string;
# the PS source uses single-quoted strings with literal backticks. Both sides
# normalize to the same canonical token only after this decode (insight L19 / R-1).
strip_wrap() {
    local s="$1"
    [[ "$s" == \"*\" ]] && { s="${s#\"}"; s="${s%\"}"; }
    # bash parameter substitution: \\\` matches literal `\``
    s="${s//\\\`/\`}"
    printf '%s' "$s"
}

lockstep_sh_count=1
if [[ "${#live_banned[@]}" -ne "$i6_expected_entry_count" ]]; then
    lockstep_sh_count=0
    echo "    verify_all.sh i6_banned entry count = ${#live_banned[@]}, expected $i6_expected_entry_count"
fi
assert "structural lockstep: verify_all.sh i6_banned entry count equals I6ExpectedEntryCount" "$lockstep_sh_count"

lockstep_sh=1
if [[ "${#live_banned[@]}" -ne "${#self_banned[@]}" ]]; then
    lockstep_sh=0
    echo "    count mismatch: verify_all.sh=${#live_banned[@]} driver=${#self_banned[@]}"
else
    for i in "${!live_banned[@]}"; do
        live_rec=$(strip_wrap "${live_banned[$i]}")
        self_rec=$(strip_wrap "${self_banned[$i]}")
        # Split each record on `|` into 4 fields. Use a sentinel index, not the
        # global `failures` array — insight L24 (loop-var name discipline).
        IFS='|' read -r live_a live_r live_e live_g <<< "$live_rec"
        IFS='|' read -r self_a self_r self_e self_g <<< "$self_rec"
        for f in anchors reason exclude gap; do
            case "$f" in
                anchors) lv="$live_a"; sv="$self_a" ;;
                reason)  lv="$live_r"; sv="$self_r" ;;
                exclude) lv="$live_e"; sv="$self_e" ;;
                gap)     lv="$live_g"; sv="$self_g" ;;
            esac
            if ! i6_field_eq "$lv" "$sv"; then
                lockstep_sh=0
                echo "    entry #$((i+1)) field $f mismatch: live=$(i6_format_field "$lv") driver=$(i6_format_field "$sv")"
            fi
        done
    done
fi
assert "structural lockstep: verify_all.sh i6_banned matches driver verbatim (per-entry x 4 fields)" "$lockstep_sh"

# ----- 3b — verify_all.ps1 $banned vs driver -----
ps1_recs=()
while IFS= read -r ln; do ps1_recs+=("$ln"); done < <(extract_ps_banned_records .harness/scripts/verify_all.ps1)
lockstep_ps_count=1
if [[ "${#ps1_recs[@]}" -ne "$i6_expected_entry_count" ]]; then
    lockstep_ps_count=0
    echo "    verify_all.ps1 \$banned entry count = ${#ps1_recs[@]}, expected $i6_expected_entry_count"
fi
assert "structural lockstep: verify_all.ps1 \$banned entry count equals I6ExpectedEntryCount" "$lockstep_ps_count"

lockstep_ps=1
if [[ "${#ps1_recs[@]}" -ne "${#self_banned[@]}" ]]; then
    lockstep_ps=0
    echo "    count mismatch: verify_all.ps1=${#ps1_recs[@]} driver=${#self_banned[@]}"
else
    for i in "${!ps1_recs[@]}"; do
        live_rec="${ps1_recs[$i]}"
        self_rec=$(strip_wrap "${self_banned[$i]}")
        IFS='|' read -r live_a live_r live_e live_g <<< "$live_rec"
        IFS='|' read -r self_a self_r self_e self_g <<< "$self_rec"
        for f in anchors reason exclude gap; do
            case "$f" in
                anchors) lv="$live_a"; sv="$self_a" ;;
                reason)  lv="$live_r"; sv="$self_r" ;;
                exclude) lv="$live_e"; sv="$self_e" ;;
                gap)     lv="$live_g"; sv="$self_g" ;;
            esac
            if ! i6_field_eq "$lv" "$sv"; then
                lockstep_ps=0
                echo "    entry #$((i+1)) field $f mismatch: live=$(i6_format_field "$lv") driver=$(i6_format_field "$sv")"
            fi
        done
    done
fi
assert "structural lockstep: verify_all.ps1 \$banned matches driver verbatim (per-entry x 4 fields)" "$lockstep_ps"

# ----- 3c — exempt-file + exempt-dir lockstep, element-wise -----
extract_array_block() {                  # $1 = file, $2 = bash array name like i6_exempt_files
    awk -v name="$2" '
        $0 ~ "^"name"=\\(" {f=1; next}
        f && /^\)/ {f=0}
        f { print }
    ' "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/^"//' -e 's/"$//'
}
extract_ps_exempt_list() {               # $1 = verify_all.ps1, $2 = PS variable name (exempt | exemptDirs)
    # Capture the body between `$<name> = @(` and the next `)`. The block may be
    # single-line (e.g. `$exemptDirs = @("docs/features/", "参考/")`) OR multi-line
    # (e.g. `$exempt = @( ... )`); both cases are handled. Character classes
    # `[$]` and `[(]` avoid awk's regex-escape pitfalls (literal `$` would be the
    # end-of-line anchor; literal `(` would open a group).
    awk -v name="$2" '
        BEGIN { open = "[$]" name "[[:space:]]*=[[:space:]]*@[(]" }
        !f && $0 ~ open {
            sub(open, "", $0)
            f = 1
        }
        f {
            if (match($0, /[)]/)) {
                print substr($0, 1, RSTART - 1)
                f = 0
                next
            }
            print
        }
    ' "$1" \
        | tr ',' '\n' \
        | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
        | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//" \
        | grep -v '^$'
}

sh_exempt_files=()
while IFS= read -r ln; do sh_exempt_files+=("$ln"); done < <(extract_array_block .harness/scripts/verify_all.sh i6_exempt_files)
sh_exempt_dirs=()
while IFS= read -r ln; do sh_exempt_dirs+=("$ln"); done < <(extract_array_block .harness/scripts/verify_all.sh i6_exempt_dirs)
ps1_exempt_files=()
while IFS= read -r ln; do ps1_exempt_files+=("$ln"); done < <(extract_ps_exempt_list .harness/scripts/verify_all.ps1 exempt)
ps1_exempt_dirs=()
while IFS= read -r ln; do ps1_exempt_dirs+=("$ln"); done < <(extract_ps_exempt_list .harness/scripts/verify_all.ps1 exemptDirs)

# i6_compare_lists LABEL LIVE_ARRAY_NAME CANONICAL_ARRAY_NAME — element-wise equality.
# Sets the global $list_cmp_ok to 1/0 (we cannot return arrays from bash).
i6_compare_lists() {
    local label="$1" live_name="$2" canon_name="$3"
    local -n live_arr="$live_name"
    local -n canon_arr="$canon_name"
    list_cmp_ok=1
    if [[ "${#live_arr[@]}" -ne "${#canon_arr[@]}" ]]; then
        list_cmp_ok=0
        echo "    $label count mismatch: live=${#live_arr[@]} canonical=${#canon_arr[@]}"
        return
    fi
    local i
    for i in "${!live_arr[@]}"; do
        if [[ "${live_arr[$i]}" != "${canon_arr[$i]}" ]]; then
            list_cmp_ok=0
            echo "    $label element #$((i+1)) mismatch: live='${live_arr[$i]}' canonical='${canon_arr[$i]}'"
        fi
    done
}

i6_compare_lists "verify_all.ps1 \$exempt" ps1_exempt_files i6_exempt_files
assert "exempt-file lockstep: verify_all.ps1 \$exempt equals canonical (element-wise)" "$list_cmp_ok"
i6_compare_lists "verify_all.sh i6_exempt_files" sh_exempt_files i6_exempt_files
assert "exempt-file lockstep: verify_all.sh i6_exempt_files equals canonical (element-wise)" "$list_cmp_ok"
i6_compare_lists "verify_all.ps1 \$exemptDirs" ps1_exempt_dirs i6_exempt_dirs
assert "exempt-dir lockstep: verify_all.ps1 \$exemptDirs equals canonical (element-wise)" "$list_cmp_ok"
i6_compare_lists "verify_all.sh i6_exempt_dirs" sh_exempt_dirs i6_exempt_dirs
assert "exempt-dir lockstep: verify_all.sh i6_exempt_dirs equals canonical (element-wise)" "$list_cmp_ok"

# ---------------------------------------------------------------------------
# Assertion 4 — no-error: the metacharacter / Unicode fixtures produce no stderr.
# ---------------------------------------------------------------------------
echo ""
echo "--- Assertion 4: no stderr on metacharacter/Unicode fixtures ---"
noerr_ok=1
for name in fx-meta-backtick.md fx-meta-arrow.md fx-arrow-accurate.md fx-e11.md fx-e12.md fx-e13.md; do
    err=$(i6_scan_file "$fx_tmp/$name" 2>&1 1>/dev/null)
    if [[ -n "$err" ]]; then
        noerr_ok=0
        echo "    stderr on $name: $err"
    fi
done
assert "no-error: metacharacter/Unicode fixtures scan without stderr" "$noerr_ok"

# ---------------------------------------------------------------------------
# Assertion 5 — gap boundary (AC-9): fx-gap-exact HIT, fx-gap-over NO-hit.
# ---------------------------------------------------------------------------
echo ""
echo "--- Assertion 5: gap boundary ---"
[[ -n "${bash_hits[fx-gap-exact.md]}" ]] \
    && assert "gap boundary: 40-char gap (fx-gap-exact) HITs" 1 \
    || assert "gap boundary: 40-char gap (fx-gap-exact) HITs" 0
[[ -z "${bash_hits[fx-gap-over.md]}" ]] \
    && assert "gap boundary: 41-char gap (fx-gap-over) does NOT hit" 1 \
    || assert "gap boundary: 41-char gap (fx-gap-over) does NOT hit" 0

# ---------------------------------------------------------------------------
# Assertion 6 — F-1 / F-2 / F-4 / Rev-4 regression.
# ---------------------------------------------------------------------------
echo ""
echo "--- Assertion 6: F-1 / F-2 / F-4 / Rev-4 regression ---"
# F-1: negation word BEFORE the anchors is still line-scoped-excluded.
[[ -z "${bash_hits[fx-negation-pre.md]}" ]] \
    && assert "F-1: fx-negation-pre (negation before anchors) does NOT hit" 1 \
    || assert "F-1: fx-negation-pre (negation before anchors) does NOT hit" 0
# F-4: historical two-line layout — anchors land on line 2, composed->into gap 23 > gap=20.
[[ -z "${bash_hits[fx-historical.md]}" ]] \
    && assert "F-4: fx-historical (concepts.md two-line layout) does NOT hit under gap=20" 1 \
    || assert "F-4: fx-historical (concepts.md two-line layout) does NOT hit under gap=20" 0
# Rev-4: entry #10's .claude/ exclude clears the README repo-layout line.
[[ -z "${bash_hits[fx-arrow-accurate.md]}" ]] \
    && assert "Rev-4: fx-arrow-accurate (README repo-layout line) does NOT hit (.claude/ exclude)" 1 \
    || assert "Rev-4: fx-arrow-accurate (README repo-layout line) does NOT hit (.claude/ exclude)" 0
# F-2: a synthetic docs/features/<task>/03_GATE_REVIEW.md path is exempt.
if i6_dir_exempt "docs/features/some-task/03_GATE_REVIEW.md"; then
    assert "F-2: docs/features/<task>/ stage-doc path is exempt from I.6" 1
else
    assert "F-2: docs/features/<task>/ stage-doc path is exempt from I.6" 0
fi
if i6_dir_exempt ".harness/scripts/verify_all.sh"; then
    assert "F-2: a non-exempt path (.harness/scripts/verify_all.sh) is NOT dir-exempt" 0
else
    assert "F-2: a non-exempt path (.harness/scripts/verify_all.sh) is NOT dir-exempt" 1
fi

# ---------------------------------------------------------------------------
# Assertion 7 — AC-8 permanent fixture coverage (T-005 §3.6 / §8).
# File-exempt predicate, dir-exempt fixture path, combined predicate, and
# AC-14 negative-regression on a real file at a non-exempt path.
# ---------------------------------------------------------------------------
echo ""
echo "--- Assertion 7: AC-8 permanent fixture coverage ---"

# 7.1 file-exempt predicate positive corpus — every canonical exempt path is exempt.
for exempt_entry in "${i6_exempt_files[@]}"; do
    if i6_file_exempt "$exempt_entry"; then
        assert "file-exempt predicate: $exempt_entry is reported exempt" 1
    else
        assert "file-exempt predicate: $exempt_entry is reported exempt" 0
    fi
done

# 7.2 file-exempt predicate negative corpus — three known non-exempt paths.
neg_file_corpus=( "README.md" "docs/concepts.md" ".harness/scripts/harness-sync.sh" )
for nonexempt_entry in "${neg_file_corpus[@]}"; do
    if i6_file_exempt "$nonexempt_entry"; then
        assert "file-exempt predicate: $nonexempt_entry is NOT reported exempt" 0
    else
        assert "file-exempt predicate: $nonexempt_entry is NOT reported exempt" 1
    fi
done

# 7.3 combined predicate vs dir-exempt synthetic path (AC-12).
if i6_exempt "docs/features/some-task/03_GATE_REVIEW.md"; then
    assert "combined exempt: docs/features/some-task/03_GATE_REVIEW.md skipped (dir-exempt)" 1
else
    assert "combined exempt: docs/features/some-task/03_GATE_REVIEW.md skipped (dir-exempt)" 0
fi

# 7.4 combined predicate vs every canonical exempt-file path (AC-13).
for exempt_entry in "${i6_exempt_files[@]}"; do
    if i6_exempt "$exempt_entry"; then
        assert "combined exempt: $exempt_entry skipped (file-exempt)" 1
    else
        assert "combined exempt: $exempt_entry skipped (file-exempt)" 0
    fi
done

# 7.5 AC-14 negative regression — physical file at non-exempt path with banned
# content MUST hit. This guards against a future bug that makes the exemption
# predicate return true for all paths.
ac14_raw=$(i6_scan_file "$fx_tmp/fx-ac14-nonexempt.md")
ac14_idxs=$(printf '%s\n' "$ac14_raw" | grep -oE '^[0-9]+' | sort -n | tr '\n' ' ' | sed 's/ $//')
if [[ -n "$ac14_idxs" ]]; then
    assert "AC-14 negative regression: non-exempt fixture with banned content HITs" 1
else
    assert "AC-14 negative regression: non-exempt fixture with banned content HITs" 0
fi

echo ""
echo "=== Result ==="
echo "  PASS: $pass"
echo "  FAIL: $fail"

if (( fail > 0 )); then
    echo ""
    echo "Failures:"
    for f in "${failures[@]}"; do echo "  - $f"; done
    exit 1
fi
exit 0
