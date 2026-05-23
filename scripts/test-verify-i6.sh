#!/usr/bin/env bash
# test-verify-i6.sh — Regression for the verify_all I.6 gap-tolerant retired-claim matcher (v0.18.0)
# Bash twin of test-verify-i6.ps1. Mirrors the same fixture corpus + assertion set.
#
# The driver does NOT source verify_all.sh (that would run all 30 checks). It
# re-declares the I.6 matcher predicate (regex builder + per-line scan + line-scoped
# exclude) as a self-contained function, kept in lockstep with the live script by a
# structural assertion (the live i6_banned array must match this driver's copy
# verbatim, including entry #10's exclude=.claude/).
#
# Usage:
#   bash scripts/test-verify-i6.sh              # full run, temp dir auto-cleaned
#   bash scripts/test-verify-i6.sh --keep-temp  # keep the fixture temp dir for inspection
set -uo pipefail

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

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
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
    ps_out=$("$ps_exe" -NoProfile -File "$repo_root/scripts/test-verify-i6.ps1" --emit-hits "$fx_tmp" 2>/dev/null)
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
# Assertion 3 — structural lockstep: the live verify_all.sh + verify_all.ps1
# banned lists match this driver's i6_banned verbatim (13 entries), and the
# exempt-dir lists contain docs/features/.
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
live_banned=()
while IFS= read -r ln; do live_banned+=("$ln"); done < <(extract_i6_banned scripts/verify_all.sh)
self_banned=()
while IFS= read -r ln; do self_banned+=("$ln"); done < <(extract_i6_banned "$0")
lockstep_sh=1
if [[ "${#live_banned[@]}" -ne 13 ]]; then
    lockstep_sh=0
    echo "    verify_all.sh i6_banned entry count = ${#live_banned[@]}, expected 13"
elif [[ "${#live_banned[@]}" -ne "${#self_banned[@]}" ]]; then
    lockstep_sh=0
    echo "    entry count mismatch: verify_all.sh=${#live_banned[@]} driver=${#self_banned[@]}"
else
    for i in "${!live_banned[@]}"; do
        if [[ "${live_banned[$i]}" != "${self_banned[$i]}" ]]; then
            lockstep_sh=0
            echo "    entry #$((i+1)) mismatch:"
            echo "      verify_all.sh: ${live_banned[$i]}"
            echo "      driver       : ${self_banned[$i]}"
        fi
    done
fi
assert "structural lockstep: verify_all.sh i6_banned (13 entries) matches driver verbatim" "$lockstep_sh"

# verify_all.ps1 must have exactly 13 banned hashtables and entry #10 carries exclude=.claude/
ps1_count=$(grep -cE "^\s*@\{ anchors = @\(" scripts/verify_all.ps1 || true)
[[ "$ps1_count" == "13" ]] \
    && assert "structural lockstep: verify_all.ps1 \$banned has 13 entries" 1 \
    || assert "structural lockstep: verify_all.ps1 \$banned has 13 entries (got $ps1_count)" 0
grep -qF "anchors = @('.harness/','→','CLAUDE.md'); reason" scripts/verify_all.ps1 \
    && grep -E "anchors = @\('\.harness/'" scripts/verify_all.ps1 | grep -qF "exclude = @('.claude/')" \
    && assert "structural lockstep: verify_all.ps1 entry #10 carries exclude=@('.claude/')" 1 \
    || assert "structural lockstep: verify_all.ps1 entry #10 carries exclude=@('.claude/')" 0

# exempt-dir docs/features/ present in both scripts
grep -qE '"docs/features/"' scripts/verify_all.sh \
    && assert "structural lockstep: verify_all.sh exempt-dir includes docs/features/" 1 \
    || assert "structural lockstep: verify_all.sh exempt-dir includes docs/features/" 0
grep -qE '"docs/features/"' scripts/verify_all.ps1 \
    && assert "structural lockstep: verify_all.ps1 exempt-dir includes docs/features/" 1 \
    || assert "structural lockstep: verify_all.ps1 exempt-dir includes docs/features/" 0

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
if i6_dir_exempt "scripts/verify_all.sh"; then
    assert "F-2: a non-exempt path (scripts/verify_all.sh) is NOT dir-exempt" 0
else
    assert "F-2: a non-exempt path (scripts/verify_all.sh) is NOT dir-exempt" 1
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
