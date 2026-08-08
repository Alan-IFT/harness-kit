#!/usr/bin/env bash
# measure-stage-query.sh — what a stage-4 Developer ingests, read whole vs addressed.
#
# The 01+02+03 contract read is the largest per-task cost in the pipeline: a measured median
# of 67 KB across 43 archived tasks. `doc-query --for <role>` returns only the sections the
# schema addresses to that role, and returns any heading the schema does not recognise, so
# an off-schema document costs the saving and never the completeness.
#
# That asymmetry is what this instrument exists to keep visible: the saving is a function of
# CONFORMANCE, and every task in the archive predates the check that enforces it. Run with no
# argument to sweep the whole corpus; the per-task figures are what will move as documents
# start conforming.
#
# The section list is NOT hardcoded here. An earlier revision of this script carried seven
# hand-copied heading names taken from one task's classification; by the time the schema was
# machine-readable, five of the seven no longer existed in any contract. Ask the tool.
#
# Usage: bash evals/measure-stage-query.sh [task-slug]

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

QUERY=".harness/scripts/doc-query.js"
[ -f "$QUERY" ] || { echo "measure-stage-query: run 'npm run build' first" >&2; exit 2; }
command -v node >/dev/null 2>&1 || { echo "measure-stage-query: node not on PATH" >&2; exit 2; }

ROLE="${ROLE:-developer}"

measure() { # slug -> "addressed whole"
    node "$QUERY" --for "$ROLE" --task "$1" --files 2>/dev/null |
        awk '/^# [0-9]+ of [0-9]+ bytes/ { print $2, $4 }'
}

# Per-DOCUMENT accounting, split by whether that document uses only declared sections.
# The split is the point: it separates what the mechanism returns today from what it returns
# once the shape check has been enforcing for a while.
conf_a=0; conf_w=0; conf_n=0
off_a=0;  off_w=0;  off_n=0
tally() { # slug
    local slug="$1" dirty file a w
    dirty=$(node .harness/scripts/stage-schema.js --lint --task "$slug" 2>/dev/null |
        awk -F: '/: (undeclared|missing)/ { print $1 }' | sort -u)
    while read -r file a w; do
        [ -n "${w:-}" ] || continue
        if printf '%s\n' "$dirty" | grep -qxF "$file"; then
            off_a=$((off_a + a)); off_w=$((off_w + w)); off_n=$((off_n + 1))
        else
            conf_a=$((conf_a + a)); conf_w=$((conf_w + w)); conf_n=$((conf_n + 1))
        fi
    done < <(node "$QUERY" --for "$ROLE" --task "$slug" --files 2>/dev/null |
        awk '/^--- /{ gsub(/[(,]/,"",$0); print $2, $5, $7 }')
}

if [ $# -ge 1 ]; then
    slug="$1"
    echo "=== stage ingest for $ROLE on task: $slug ==="
    echo
    node "$QUERY" --for "$ROLE" --task "$slug" --files
    echo
    echo "Sections withheld are recoverable by name:"
    echo "  node $QUERY --in stage --task $slug --heading '<Section>'"
    exit 0
fi

echo "=== stage ingest for $ROLE, whole corpus ==="
echo
printf '%-34s %10s %10s %7s\n' "task" "addressed" "whole" "share"
printf '%s\n' "----------------------------------------------------------------"

total_a=0
total_w=0
n=0
conforming=0
for d in docs/features/_archived/*/ docs/features/*/; do
    slug=$(basename "$d")
    case "$slug" in _archived|_supervision|_template) continue;; esac
    read -r a w <<<"$(measure "$slug")"
    [ -n "${w:-}" ] || continue
    [ "$w" -gt 0 ] || continue
    total_a=$((total_a + a))
    total_w=$((total_w + w))
    n=$((n + 1))
    if node .harness/scripts/stage-schema.js --lint --task "$slug" >/dev/null 2>&1; then
        conforming=$((conforming + 1))
        mark="*"
    else
        mark=""
    fi
    tally "$slug"
    printf '%-34s %10d %10d %6d%% %s\n' "$slug" "$a" "$w" "$((a * 100 / w))" "$mark"
done

echo
awk -v a="$total_a" -v w="$total_w" -v n="$n" -v c="$conforming" \
    -v ca="$conf_a" -v cw="$conf_w" -v cn="$conf_n" \
    -v oa="$off_a" -v ow="$off_w" -v on="$off_n" 'BEGIN{
  printf "%d tasks, %d with every stage contract conforming (* above)\n", n, c
  printf "corpus:            addressed %8.1f KB of %8.1f KB  ->  %.2fx, %d%% returned\n", a/1024, w/1024, w/a, a*100/w
  if (cn > 0)
    printf "conforming docs:   addressed %8.1f KB of %8.1f KB  ->  %.2fx, %d%% returned  (n=%d)\n", ca/1024, cw/1024, cw/ca, ca*100/cw, cn
  if (on > 0)
    printf "off-schema docs:   addressed %8.1f KB of %8.1f KB  ->  %.2fx, %d%% returned  (n=%d)\n", oa/1024, ow/1024, ow/oa, oa*100/ow, on
  printf "\nThe two lines are the same mechanism against different documents. The corpus figure\n"
  printf "is the floor — every archived task predates the shape check. The conforming line is\n"
  printf "what the routing returns when the schema is actually obeyed.\n"
}'
