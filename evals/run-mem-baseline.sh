#!/usr/bin/env bash
# run-mem-baseline.sh — configuration B (search) for the MEM category of
# evals/retrieval-eval.md, measured against configuration A (read the whole document).
#
# §5.3 of the migration brief requires this before any memory backend is adopted: Letta
# measured plain grep + file reads at 74.0% on LoCoMo against mem0's self-reported 68.5%,
# so a backend that does not beat search here does not get merged.
#
# FOUR ARMS, because "grep" is not one thing:
#   A   read-whole-document — today's access pattern. Cost = the file's full size.
#   B1  repo-wide search that SKIPS dot-directories — ripgrep's default, and what an agent
#       writes by reflex. Claude Code's Grep tool is ripgrep-backed, so this is the live
#       case, not a hypothetical one.
#   B2  the same search with dot-directories included — the corrected reflex.
#   B3  the same search SCOPED to the memory documents, 2 lines of context — what an agent
#       that already knows where to look does.
#   B5  `doc-query --in memory` — the stores are named in the tool, and the unit returned is the
#       WHOLE ENTRY containing the match. Built because B1 and B3/B4 measured two problems
#       a better backend does not fix: an unscoped search misses everything under a
#       dot-directory, and a line window either truncates a fact or drags in its neighbours.
#   B4  scoped, but with an ENTRY-SIZED context window. B3's misses are not search failures:
#       these stores hold one fact per long wrapped paragraph, so a narrow line window
#       finds the keyword and truncates the evidence. B4 tests whether the fix is the
#       retrieval UNIT rather than the retrieval BACKEND.
#
# Scoring is mechanical: a hit means the expected evidence string appears in that arm's
# output, and tokens are that output's size at the divisor measure-context.sh uses. No
# judge model is involved, deliberately — see the LoCoMo note in the eval set.
#
# Usage: bash evals/run-mem-baseline.sh [--verbose]

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

CPT=3.6
CAP=20000
VERBOSE=0
[ "${1:-}" = "--verbose" ] && VERBOSE=1

# This host has no ripgrep binary, but `grep -rn --exclude-dir=.*` reproduces ripgrep's
# default dot-directory behaviour exactly, which is what B1 needs to measure.
command -v grep >/dev/null 2>&1 || { echo "run-mem-baseline: grep not found" >&2; exit 2; }

# The four documents that carry decided history. Scoping to these is not cheating: it is
# the whole claim a memory layer makes — that it knows which store holds the answer.
MEM_DOCS=(.harness/insight-index.md .harness/rejected-decisions.md .harness/decision-rubric.md CONTEXT.md)

# id | search term (as an agent would phrase it) | expected evidence | home document
#
# Terms must be LITERAL: they are handed to grep and to a substring search alike, so a
# regex-flavoured term measures the term format rather than the arm. The evidence check is
# case-insensitive for the same reason — an entry that writes BRACKET in caps has still
# answered a question about brackets.
CASES=(
  'M1|path-scoped|no tool grant in this runtime is|.harness/rejected-decisions.md'
  'M2|plugin cache|version-scoped plugin cache|.harness/insight-index.md'
  # M3's answer lives in verify_all.sh, not in a memory store, so the scoped arms cannot
  # reach it BY CONSTRUCTION. Kept and marked rather than dropped: it is the eval set's
  # own mis-categorisation, and deleting it would hide a real fact about the item.
  'M3|warns|exit 1|.harness/scripts/verify_all.sh'
  'M4|dot-directories|--hidden|.harness/insight-index.md'
  'M5|reasoning-effort|deferred|.harness/rejected-decisions.md'
  'M6|fail-closed PreToolUse|unwired template copy|.harness/insight-index.md'
  'M7|git status|elided|.harness/insight-index.md'
  'M8|numstat|content digest|.harness/insight-index.md'
  'M9|SUPERSEDES|wrapped entry survives|.harness/insight-index.md'
  'M10|persist-duty|in-band|.harness/rejected-decisions.md'
  'M11|Read, Glob, Grep|transcribe|.harness/insight-index.md'
  'M12|ugrep|bracket|.harness/insight-index.md'
)

a_tok=0; b1_tok=0; b2_tok=0; b3_tok=0; b4_tok=0; b5_tok=0
b1_hit=0; b2_hit=0; b3_hit=0; b4_hit=0; b5_hit=0; n=0; capped=0
MEMSEARCH=.harness/scripts/doc-query.js

tok() { awk -v b="$1" -v c="$CPT" 'BEGIN{printf "%.0f", b/c}'; }

printf '%-5s %-8s %-7s %-6s %-8s %8s %8s %8s %8s\n' \
    "id" "all-dir" "scoped" "entry" "memsrch" "A tok" "B2 tok" "B4 tok" "B5 tok"
printf '%s\n' "-------------------------------------------------------------------------"

for row in "${CASES[@]}"; do
    IFS='|' read -r id term evidence home <<< "$row"
    n=$((n + 1))

    a_bytes=$(stat -c%s "$home" 2>/dev/null || echo 0)
    a_tok=$((a_tok + $(tok "$a_bytes")))

    b1_out=$(grep -rn -C2 --exclude-dir='.*' -- "$term" . 2>/dev/null | head -c "$CAP")
    b2_out=$(grep -rn -C2 -- "$term" . 2>/dev/null | head -c "$CAP")
    b3_out=$(grep -n -C2 -- "$term" "${MEM_DOCS[@]}" 2>/dev/null | head -c "$CAP")
    b4_out=$(grep -n -C10 -- "$term" "${MEM_DOCS[@]}" 2>/dev/null | head -c "$CAP")
    b5_out=$(node "$MEMSEARCH" --in memory "$term" 2>/dev/null | head -c "$CAP")

    for arm in 1 2 3 4 5; do
        case $arm in
            1) out="$b1_out" ;;
            2) out="$b2_out" ;;
            3) out="$b3_out" ;;
            4) out="$b4_out" ;;
            5) out="$b5_out" ;;
        esac
        bytes=${#out}
        [ "$bytes" -ge "$CAP" ] && capped=$((capped + 1))
        ok="MISS"
        printf '%s' "$out" | grep -qiF -- "$evidence" && ok="hit"
        case $arm in
            1) b1_bytes=$bytes; b1_ok=$ok; [ "$ok" = "hit" ] && b1_hit=$((b1_hit + 1)) ;;
            2) b2_bytes=$bytes; b2_ok=$ok; [ "$ok" = "hit" ] && b2_hit=$((b2_hit + 1)) ;;
            3) b3_bytes=$bytes; b3_ok=$ok; [ "$ok" = "hit" ] && b3_hit=$((b3_hit + 1)) ;;
            4) b4_bytes=$bytes; b4_ok=$ok; [ "$ok" = "hit" ] && b4_hit=$((b4_hit + 1)) ;;
            5) b5_bytes=$bytes; b5_ok=$ok; [ "$ok" = "hit" ] && b5_hit=$((b5_hit + 1)) ;;
        esac
    done

    b1_tok=$((b1_tok + $(tok "$b1_bytes")))
    b2_tok=$((b2_tok + $(tok "$b2_bytes")))
    b3_tok=$((b3_tok + $(tok "$b3_bytes")))
    b4_tok=$((b4_tok + $(tok "$b4_bytes")))
    b5_tok=$((b5_tok + $(tok "$b5_bytes")))

    printf '%-5s %-8s %-7s %-6s %-8s %8s %8s %8s %8s\n' \
        "$id" "$b2_ok" "$b3_ok" "$b4_ok" "$b5_ok" \
        "$(tok "$a_bytes")" "$(tok "$b2_bytes")" "$(tok "$b4_bytes")" "$(tok "$b5_bytes")"
    [ "$VERBOSE" = "1" ] && printf '      term=%q  evidence=%q\n' "$term" "$evidence"
done

echo
printf 'accuracy   A  read-whole   %2d/%d   (by construction — the answer is in the file read)\n' "$n" "$n"
printf 'accuracy   B1 skip-dot     %2d/%d\n' "$b1_hit" "$n"
printf 'accuracy   B2 all dirs     %2d/%d\n' "$b2_hit" "$n"
printf 'accuracy   B3 scoped       %2d/%d\n' "$b3_hit" "$n"
printf 'accuracy   B4 entry-sized %2d/%d\n' "$b4_hit" "$n"
printf 'accuracy   B5 doc-query    %2d/%d\n' "$b5_hit" "$n"
echo
printf 'tokens     A  read-whole  %7d\n' "$a_tok"
printf 'tokens     B1 skip-dot    %7d\n' "$b1_tok"
printf 'tokens     B2 all dirs    %7d\n' "$b2_tok"
printf 'tokens     B3 scoped      %7d\n' "$b3_tok"
printf 'tokens     B4 entry-sized %7d\n' "$b4_tok"
printf 'tokens     B5 doc-query    %6d\n' "$b5_tok"
echo
awk -v a="$a_tok" -v b="$b2_tok" -v c="$b3_tok" -v d="$b4_tok" -v e="$b5_tok" 'BEGIN{
  if (b > 0) printf "B2 costs %5.1f%% of A  (%.1fx cheaper)\n", b*100/a, a/b
  if (c > 0) printf "B3 costs %5.1f%% of A  (%.1fx cheaper, and %.1fx cheaper than B2)\n", c*100/a, a/c, b/c
  if (d > 0) printf "B4 costs %5.1f%% of A  (%.1fx cheaper)\n", d*100/a, a/d
  if (e > 0) printf "B5 costs %5.1f%% of A  (%.1fx cheaper)\n", e*100/a, a/e
}'
echo
printf 'NOTE: %d arm-runs hit the %d-byte capture cap, so those costs are FLOORS.\n' "$capped" "$CAP"
echo '      A memory backend must beat the BEST search arm to be worth adopting.'
