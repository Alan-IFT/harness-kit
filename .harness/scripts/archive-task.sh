#!/usr/bin/env bash
# archive-task.sh — Archive a completed task: harvest insights, move stage docs.
#
# Usage:
#   bash .harness/scripts/archive-task.sh --task <task-slug>
#   bash .harness/scripts/archive-task.sh --task <task-slug> --dry-run
#
# Harvesting is ENTRY-based, not line-based (T-20): an insight ENTRY is one
# bullet line plus every continuation line wrapped under it, and every line of
# the entry is carried through. EVERY `## Insight` section of the delivery
# document is harvested, and a heading inside a fenced code block is not a
# heading. Exit 3 = a line inside a harvested section or inside the stored
# index could not be classified, or a code fence was left open; nothing is
# written.

set -euo pipefail

TASK=""
DRY_RUN=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --task) TASK="$2"; shift 2 ;;
        --dry-run) DRY_RUN=true; shift ;;
        *) echo "Unknown arg: $1" >&2; exit 1 ;;
    esac
done

if [[ -z "$TASK" ]]; then
    echo "Usage: archive-task.sh --task <task-slug> [--dry-run]" >&2
    exit 1
fi

# Script lives at .harness/scripts/ — repo root is two levels up.
repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
task_dir="$repo_root/docs/features/$TASK"
archived_root="$repo_root/docs/features/_archived"
archived_task_dir="$archived_root/$TASK"
insight_index="$repo_root/.harness/insight-index.md"
insight_history="$archived_root/insight-history.md"

# ---------------------------------------------------------------------------
# INSIGHT-SCAN — the single entry-boundary algorithm, used for the delivery
# section AND for the stored index (T-20 / 02_SOLUTION_DESIGN.md §C).
#
# MATCHER REGISTER: every pattern below is evaluated by bash's `[[ =~ ]]`
# POSIX-ERE engine ONLY. Each is held in a variable and left UNQUOTED at the
# match site (quoting turns an ERE into a literal). `[ \t]` is banned inside any
# bracket expression here — it is a tab to awk but the class {space, backslash,
# t} to GNU grep 3.11 (insight 2026-08-01). Use [[:space:]].
#
# SET -E DISCIPLINE (this script runs `set -euo pipefail`; verify_all.sh does
# NOT use -e): never write `(( n++ ))` as a standalone statement (it returns the
# OLD value, so it exits the script at n == 0) and never leave a bare `[[ =~ ]]`
# or an `&&` AND-list as the last command of a function body or of a branch.
# Use n=$((n+1)) and wrap every test in `if`.
# ---------------------------------------------------------------------------
RE_ENTRY='^[[:space:]]*-[[:space:]]'
RE_BLANK='^[[:space:]]*$'
RE_BREAK='^[[:space:]]{0,3}(-{3,}|\*{3,}|_{3,})[[:space:]]*$'
RE_HEADING='^#{2,6}[[:space:]]'
RE_SECTION_HEAD='^##[[:space:]]+Insights?[[:space:]]*$'
RE_SECTION_END='^##[[:space:]]'
# A fenced code block opener/closer: 0-3 leading spaces then >= 3 backticks or
# >= 3 tildes. Capture 1 is the marker run, capture 2 the rest of the line (the
# info string on an opener; it must be blank on a closer).
RE_FENCE='^[[:space:]]{0,3}(`{3,}|~{3,})(.*)$'

LINES=()
DIAG=()

# K-4: strip ALL trailing whitespace (a CR included, so a CRLF document needs no
# special case) and leave leading whitespace untouched. Applied to LINES before
# classification and before any write.
normalise_lines() {
    local i t
    for (( i = 0; i < ${#LINES[@]}; i++ )); do
        t="${LINES[i]##*[![:space:]]}"
        LINES[i]="${LINES[i]%"$t"}"
    done
    return 0
}

# insight_scan <section|index> <lo> <hi>
#   lo/hi are 0-based inclusive offsets into LINES; hi < lo is an empty range.
# Writes: SCAN_HDR_END SCAN_E_LO[] SCAN_E_HI[] SCAN_KIND[] SCAN_ENTRIES
#         SCAN_CONT SCAN_IGN SCAN_FOOTER SCAN_UNACC SCAN_UNACC_IDX[]
insight_scan() {
    local mode="$1" lo="$2" hi="$3"
    local i e f last line rest pre pos_open pos_close
    local cs=0 open_at=-1 stopped=0 in_entry=0 seen_entry=0

    SCAN_HDR_END=$(( lo - 1 ))
    SCAN_E_LO=(); SCAN_E_HI=(); SCAN_KIND=(); SCAN_UNACC_IDX=()
    SCAN_ENTRIES=0; SCAN_CONT=0; SCAN_IGN=0; SCAN_FOOTER=0; SCAN_UNACC=0
    SCAN_OPEN_AT=-1
    f=-1

    # --- Pass A — header block (mode `index` only, K-7) ---------------------
    # Comment state is a FIXED-STRING scan registered with no regex engine:
    # every `<!--` sets it true and every `-->` sets it false, in left-to-right
    # occurrence order (the token-TYPE reading, gate Q-2 — a second `<!--`
    # inside an open comment is idempotent, `<!-- x --> <!--` ends open).
    # An entry-start line inside an open comment does NOT end the header block,
    # which is what keeps the shipped insight-index.md.tmpl example line out of
    # the entry set (K-64 / B-19 / BC-24).
    if [[ "$mode" == "index" ]]; then
        for (( i = lo; i <= hi; i++ )); do
            line="${LINES[i]}"
            if (( cs == 0 )) && [[ $line =~ $RE_ENTRY ]]; then
                SCAN_HDR_END=$(( i - 1 )); stopped=1; break
            fi
            rest="$line"
            while [[ -n "$rest" ]]; do
                pos_open=-1; pos_close=-1
                if [[ "$rest" == *'<!--'* ]]; then pre="${rest%%'<!--'*}"; pos_open=${#pre}; fi
                if [[ "$rest" == *'-->'* ]];  then pre="${rest%%'-->'*}";  pos_close=${#pre}; fi
                if (( pos_open < 0 && pos_close < 0 )); then break; fi
                if (( pos_open >= 0 && ( pos_close < 0 || pos_open < pos_close ) )); then
                    cs=1; open_at=$i; rest="${rest:$(( pos_open + 4 ))}"
                else
                    cs=0; rest="${rest:$(( pos_close + 3 ))}"
                fi
            done
        done
        if (( stopped == 0 )); then
            SCAN_HDR_END=$hi
            # X-10 / G-17: a comment still OPEN at EOF swallows the whole file
            # into the header block, so every stored entry would read as 0 and
            # every later harvest would be appended INSIDE the comment, silently,
            # at exit 0. Report the opening line as UNACCOUNTED so this refuses
            # here and WARNs in verify_all I.4 instead of corrupting the index.
            if (( cs == 1 )); then SCAN_OPEN_AT=$open_at; fi
        fi
    fi

    # --- Pass B — kinds -----------------------------------------------------
    for (( i = lo; i <= hi; i++ )); do
        line="${LINES[i]}"
        if [[ "$mode" == "index" ]] && (( i <= SCAN_HDR_END )); then
            SCAN_KIND[i]="I"; in_entry=0; continue
        fi
        if [[ $line =~ $RE_BLANK ]]; then
            SCAN_KIND[i]="I"; in_entry=0; continue
        fi
        if [[ $line =~ $RE_ENTRY ]]; then
            SCAN_KIND[i]="E"; SCAN_E_LO+=("$i"); SCAN_E_HI+=("$i")
            in_entry=1; seen_entry=1; continue
        fi
        if [[ "$mode" == "section" ]] && (( seen_entry == 0 )); then
            SCAN_KIND[i]="I"; in_entry=0; continue
        fi
        # X-8: a `##`/`###`… heading line is NEVER a continuation (the contract's
        # `Continuation line` definition). It terminates the open entry and is
        # UNACCOUNTED, in BOTH modes — so a heading that drifts into an index or
        # under a bullet is refused loudly instead of being absorbed into an
        # entry and rotated into insight-history.md.
        if [[ $line =~ $RE_HEADING ]]; then
            SCAN_KIND[i]="U"; in_entry=0; continue
        fi
        if (( in_entry == 1 )); then
            SCAN_KIND[i]="C"
            last=$(( ${#SCAN_E_HI[@]} - 1 ))
            SCAN_E_HI[last]=$i
            continue
        fi
        SCAN_KIND[i]="U"
    done

    # --- Pass C — terminal footer (mode `section` only) ---------------------
    if [[ "$mode" == "section" ]] && (( ${#SCAN_E_HI[@]} > 0 )); then
        last=$(( ${#SCAN_E_HI[@]} - 1 ))
        e=${SCAN_E_HI[last]}
        for (( i = e + 1; i <= hi; i++ )); do
            if [[ ${LINES[i]} =~ $RE_BREAK ]]; then f=$i; break; fi
        done
        if (( f >= 0 )); then
            for (( i = f; i <= hi; i++ )); do
                # K-62: pass C can only demote UNACCOUNTED -> ignorable. An
                # entry-start or continuation line is never made ignorable here
                # — enforced literally, not by convention.
                if [[ "${SCAN_KIND[i]}" == "U" ]]; then SCAN_KIND[i]="I"; fi
                SCAN_FOOTER=$(( SCAN_FOOTER + 1 ))
            done
        fi
    fi

    if (( SCAN_OPEN_AT >= 0 )); then SCAN_KIND[SCAN_OPEN_AT]="U"; fi

    SCAN_ENTRIES=${#SCAN_E_LO[@]}
    for (( i = lo; i <= hi; i++ )); do
        case "${SCAN_KIND[i]}" in
            I) SCAN_IGN=$(( SCAN_IGN + 1 )) ;;
            C) SCAN_CONT=$(( SCAN_CONT + 1 )) ;;
            U) SCAN_UNACC=$(( SCAN_UNACC + 1 )); SCAN_UNACC_IDX+=("$i") ;;
        esac
    done
    return 0
}

# Append one diagnostic per unaccounted line of the scan just run: file path,
# 1-based line number IN THAT FILE, and the line's text.
scan_diagnostics() {
    local path="$1" i
    for i in "${SCAN_UNACC_IDX[@]}"; do
        if (( SCAN_OPEN_AT >= 0 && i == SCAN_OPEN_AT )); then
            DIAG+=("${path}:$(( i + 1 )): unterminated HTML comment opened here: ${LINES[i]}")
        else
            DIAG+=("${path}:$(( i + 1 )): unaccounted line: ${LINES[i]}")
        fi
    done
    return 0
}

if [[ ! -d "$task_dir" ]]; then
    echo "Task directory not found: $task_dir" >&2
    exit 1
fi

if [[ -d "$archived_task_dir" ]]; then
    echo "Task already archived: $archived_task_dir" >&2
    exit 1
fi

# Step 1: harvest insight ENTRIES from 07_DELIVERY.md
delivery_file="$task_dir/07_DELIVERY.md"
HARVEST=()   # `arr=()` not `declare -a arr` — `set -u` aborts on empty `${#arr[@]}` per insight L13
h_entries=0; h_cont=0; h_ign=0; h_footer=0; h_unacc=0; h_quoted=0
if [[ -f "$delivery_file" ]]; then
    if [[ ! -r "$delivery_file" ]]; then
        echo "Delivery document not readable: $delivery_file" >&2
        exit 1
    fi
    # X-9: `mapfile -t` KEEPS an unterminated final line. The `while IFS= read -r`
    # idiom this replaced DROPS it — which, when that line is a continuation line,
    # is exactly the silent continuation loss this change exists to repair.
    LINES=()
    mapfile -t LINES < "$delivery_file"
    normalise_lines
    d_n=${#LINES[@]}
    # --- SECTION DISCOVERY (QA-1) ------------------------------------------
    # ALL matching headings open a section and EVERY one of them is harvested.
    # Scanning only the first (and `break`ing) silently discarded every later
    # `## Insight` section at exit 0; the pre-change awk re-armed its flag on
    # every matching heading, so this is the B-11 regression floor as well.
    #
    # A heading inside a FENCED CODE BLOCK is not a heading, and a `##` inside
    # one does not terminate a section: a document *about* this section quotes
    # the heading, and reading the quote as the section harvests documentation
    # while (pre-fix) hiding the real section entirely. Fence state is tracked
    # over the whole document, in one walk, for both the opener and the
    # terminator, so the two can never disagree about where a section is.
    SEC_LO=(); SEC_HI=()
    fence_char=""; fence_len=0; fence_at=-1; cur_lo=-1
    for (( i = 0; i < d_n; i++ )); do
        line="${LINES[i]}"
        if [[ $line =~ $RE_FENCE ]]; then
            mark="${BASH_REMATCH[1]}"; info="${BASH_REMATCH[2]}"
            if [[ -z "$fence_char" ]]; then
                # CommonMark: a backtick fence's info string may hold no backtick.
                if [[ "${mark:0:1}" != '`' || "$info" != *'`'* ]]; then
                    fence_char="${mark:0:1}"; fence_len=${#mark}; fence_at=$i
                fi
            elif [[ "${mark:0:1}" == "$fence_char" ]] && (( ${#mark} >= fence_len )) \
                 && [[ $info =~ $RE_BLANK ]]; then
                fence_char=""; fence_len=0; fence_at=-1
            fi
            continue
        fi
        if [[ -n "$fence_char" ]]; then
            # Skipping a quoted heading is a DECISION, not a silence: count it
            # so the run reports it. A `## Insight` inside a fence is normal in
            # a document about this section, but "we ignored a heading" must
            # never be inferable only from a missing entry.
            if [[ $line =~ $RE_SECTION_HEAD ]]; then h_quoted=$(( h_quoted + 1 )); fi
            continue
        fi
        if [[ $line =~ $RE_SECTION_HEAD ]]; then
            if (( cur_lo >= 0 )); then SEC_LO+=("$cur_lo"); SEC_HI+=($(( i - 1 ))); fi
            cur_lo=$(( i + 1 )); continue
        fi
        if [[ $line =~ $RE_SECTION_END ]] && (( cur_lo >= 0 )); then
            SEC_LO+=("$cur_lo"); SEC_HI+=($(( i - 1 ))); cur_lo=-1
        fi
    done
    if (( cur_lo >= 0 )); then SEC_LO+=("$cur_lo"); SEC_HI+=($(( d_n - 1 ))); fi
    # A fence still OPEN at EOF hides every heading after it, so a real section
    # can vanish at exit 0. Report the opening line and refuse — the same
    # treatment the index's unbalanced `<!--` gets (D-2), for the same reason.
    if (( fence_at >= 0 )); then
        DIAG+=("${delivery_file}:$(( fence_at + 1 )): unterminated code fence opened here: ${LINES[fence_at]}")
        h_unacc=$(( h_unacc + 1 ))
    fi
    for (( s = 0; s < ${#SEC_LO[@]}; s++ )); do
        insight_scan section "${SEC_LO[s]}" "${SEC_HI[s]}"
        h_entries=$(( h_entries + SCAN_ENTRIES )); h_cont=$(( h_cont + SCAN_CONT ))
        h_ign=$(( h_ign + SCAN_IGN ));             h_footer=$(( h_footer + SCAN_FOOTER ))
        h_unacc=$(( h_unacc + SCAN_UNACC ))
        for (( e = 0; e < SCAN_ENTRIES; e++ )); do
            for (( i = ${SCAN_E_LO[e]}; i <= ${SCAN_E_HI[e]}; i++ )); do
                HARVEST+=("${LINES[i]}")
            done
        done
        scan_diagnostics "$delivery_file"
    done
fi

if (( h_entries > 0 )); then
    echo "Harvested $h_entries insight entry(ies) from 07_DELIVERY.md:"
    for (( i = 0; i < ${#HARVEST[@]}; i++ )); do echo "  ${HARVEST[i]}"; done
fi

# Step 2: read the stored index and rotate it if it would exceed 30 ENTRIES
if [[ ! -f "$insight_index" ]]; then
    echo "Warning: .harness/insight-index.md missing — creating empty"
fi

LINES=()
if [[ -f "$insight_index" ]]; then
    mapfile -t LINES < "$insight_index"
    normalise_lines
fi
insight_scan index 0 $(( ${#LINES[@]} - 1 ))
idx_entries=$SCAN_ENTRIES
idx_unacc=$SCAN_UNACC
IDX_HDR=()
for (( i = 0; i <= SCAN_HDR_END; i++ )); do IDX_HDR+=("${LINES[i]}"); done
IDX_LINES=("${LINES[@]}")
IDX_E_LO=("${SCAN_E_LO[@]}")
IDX_E_HI=("${SCAN_E_HI[@]}")
scan_diagnostics "$insight_index"

total_after=$(( idx_entries + h_entries ))
rotate_count=0
refusing=false
if (( h_unacc > 0 || idx_unacc > 0 )); then refusing=true; fi
if [[ "$refusing" == false ]] && (( total_after > 30 )); then
    rotate_count=$(( total_after - 30 ))
    # BC-14 clamp: never read past the end of the stored entry list.
    if (( rotate_count > idx_entries )); then rotate_count=$idx_entries; fi
fi
index_after=$(( idx_entries - rotate_count + h_entries ))
if [[ "$refusing" == true ]]; then index_after=$idx_entries; fi

# The tally prints on EVERY terminating path, refusal included, so an echo that
# looks complete can never accompany discarded content (B-5 / K-18).
echo "Insight tally: entries $h_entries, continuation lines $h_cont, ignorable lines $h_ign (terminal footer $h_footer), unaccounted lines $h_unacc"
if (( h_quoted > 0 )); then
    echo "Quoted headings: $h_quoted '## Insight' heading(s) inside a code fence were not harvested"
fi
echo "Index tally: entries $idx_entries, unaccounted lines $idx_unacc, entries after run $index_after"

if [[ "$refusing" == true ]]; then
    echo "archive-task: refusing to harvest — $(( h_unacc + idx_unacc )) unclassifiable line(s); nothing written." >&2
    for (( i = 0; i < ${#DIAG[@]}; i++ )); do echo "  ${DIAG[i]}" >&2; done
    exit 3
fi

if (( rotate_count > 0 )); then
    echo "Rotating $rotate_count old insight entry(ies) to insight-history.md"
fi

# --- write phase: nothing above this line creates, writes, appends or moves ---
if [[ "$DRY_RUN" == false && ! -f "$insight_index" ]]; then
    touch "$insight_index"
fi

if (( total_after > 30 )); then
    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$archived_root"
        if (( rotate_count > 0 )); then
            if [[ ! -f "$insight_history" ]]; then
                printf '# Insight history (rotated from .harness/insight-index.md)\n\n' > "$insight_history"
            fi
            printf '\n## Rotated %s\n\n' "$(date +%Y-%m-%d)" >> "$insight_history"
            for (( e = 0; e < rotate_count; e++ )); do
                for (( i = ${IDX_E_LO[e]}; i <= ${IDX_E_HI[e]}; i++ )); do
                    printf '%s\n' "${IDX_LINES[i]}" >> "$insight_history"
                done
            done
        fi
        # Rewrite: header block verbatim and FIRST, then retained entries in
        # their original order, then the harvested entries (B-8 / B-9). The
        # header is emitted from the pass-A range, never by filtering the file
        # for non-bullet lines — that filter is what hoisted stray lines.
        {
            for (( i = 0; i < ${#IDX_HDR[@]}; i++ )); do printf '%s\n' "${IDX_HDR[i]}"; done
            for (( e = rotate_count; e < idx_entries; e++ )); do
                for (( i = ${IDX_E_LO[e]}; i <= ${IDX_E_HI[e]}; i++ )); do
                    printf '%s\n' "${IDX_LINES[i]}"
                done
            done
            for (( i = 0; i < ${#HARVEST[@]}; i++ )); do printf '%s\n' "${HARVEST[i]}"; done
        } > "$insight_index.tmp"
        mv "$insight_index.tmp" "$insight_index"
    fi
elif (( h_entries > 0 )); then
    if [[ "$DRY_RUN" == false ]]; then
        for (( i = 0; i < ${#HARVEST[@]}; i++ )); do printf '%s\n' "${HARVEST[i]}" >> "$insight_index"; done
    fi
fi

# Step 3: move task dir
if [[ "$DRY_RUN" == false ]]; then
    mkdir -p "$archived_root"
    mv "$task_dir" "$archived_task_dir"
fi

# Step 4: report
echo ""
if [[ "$DRY_RUN" == true ]]; then
    echo "[DRY RUN] No files written. Would have:"
    echo "  - Appended $h_entries insight entry(ies) to .harness/insight-index.md"
    echo "  - Rotated $rotate_count old insight entry(ies) to insight-history.md"
    echo "  - Moved $task_dir -> $archived_task_dir"
else
    echo "Archived task: $TASK"
    echo "  Stage docs:   $archived_task_dir"
    if (( h_entries > 0 )); then
        echo "  Insights:     +$h_entries entry(ies) to .harness/insight-index.md"
    fi
    if (( rotate_count > 0 )); then
        echo "  Rotated:      $rotate_count -> $insight_history"
    fi
fi
