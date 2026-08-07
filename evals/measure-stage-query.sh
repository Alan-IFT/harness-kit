#!/usr/bin/env bash
# measure-stage-query.sh — what a stage-4 Developer ingests, read whole vs queried.
#
# The 01+02+03 contract read is the largest per-task cost in the pipeline: a measured
# median of 67 KB across 43 archived tasks, of which a section-level classification found
# only 48% is addressed to the Developer at all.
#
# This measures the alternative WITHOUT any authoring change. Stage documents already carry
# `## ` sections, so `doc-query` can return the sections a Developer needs and leave the
# Change ledger, the Risks analysis, the QA acceptance protocol and the Open questions
# where they are.
#
# Usage: bash evals/measure-stage-query.sh [task-slug]

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

TASK="${1:-review-write-path}"
DIR="docs/features/_archived/$TASK"
QUERY=".harness/scripts/doc-query.js"

[ -d "$DIR" ] || { echo "measure-stage-query: no such task: $DIR" >&2; exit 2; }
[ -f "$QUERY" ] || { echo "measure-stage-query: run 'npm run build' first" >&2; exit 2; }

# What a Developer actually asks for. Derived from the section-level classification in
# docs/proposals/v2-p1-blockers.md, not invented here.
TERMS=(
  "The arrangement"
  "API contracts"
  "Data model"
  "Affected modules"
  "Developer-owned conditions"
  "Sequence / flow"
  "Partition assignment"
)

whole=0
for f in "$DIR"/01_REQUIREMENT_ANALYSIS.md "$DIR"/02_SOLUTION_DESIGN.md "$DIR"/03_GATE_REVIEW.md; do
    [ -f "$f" ] && whole=$((whole + $(stat -c%s "$f")))
done

queried=0
echo "=== stage-4 ingest for task: $TASK ==="
echo
printf '%-32s %8s\n' "query" "bytes"
printf '%s\n' "-----------------------------------------"
for t in "${TERMS[@]}"; do
    out=$(node "$QUERY" --in stage --task "$TASK" --heading "$t" 2>/dev/null)
    b=${#out}
    queried=$((queried + b))
    printf '%-32s %8d\n' "$t" "$b"
done

echo
awk -v w="$whole" -v q="$queried" -v n="${#TERMS[@]}" 'BEGIN{
  printf "read 01+02+03 whole      %8.1f KB   (~%d tok)\n", w/1024, w/3.6
  printf "%d section queries        %8.1f KB   (~%d tok)\n", n, q/1024, q/3.6
  printf "\n"
  if (q > 0) printf "queried costs %.1f%% of whole  (%.1fx cheaper)\n", q*100/w, w/q
}'
echo
echo 'Note: the queries return sections from ALL stage docs of the task, including the'
echo 'rationale siblings, so this is an upper bound on what section addressing would cost.'
