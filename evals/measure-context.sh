#!/usr/bin/env bash
# measure-context.sh — baseline A instrument for the v2 migration.
#
# Measures the context an agent must ingest under TODAY'S access pattern
# ("read the whole document"). Re-run after P1 to produce the delta.
#
# Bytes are the primary metric: exact, reproducible, tool-independent.
# Token figures are ESTIMATES at a stated divisor — Claude's tokenizer is not
# public, so the authoritative token number must come from a live session
# measurement (cache_creation_input_tokens), the same way 60,804 was captured.
# The migration's acceptance bar is a RATIO, for which bytes are a sound proxy.
#
# Usage: bash evals/measure-context.sh [--json]

set -uo pipefail

CPT=3.6   # chars per token, estimate divisor for dense technical markdown
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

JSON=0
[ "${1:-}" = "--json" ] && JSON=1

sz() { [ -f "$1" ] && stat -c%s "$1" 2>/dev/null || echo 0; }
dirsz() { find "$1" -type f -name '*.md' -printf '%s\n' 2>/dev/null | awk '{s+=$1} END{print s+0}'; }
tok() { awk -v b="$1" -v c="$CPT" 'BEGIN{printf "%.0f", b/c}'; }
kb()  { awk -v b="$1" 'BEGIN{printf "%.1f", b/1024}'; }

row() { printf "  %-46s %9s KB  ~%7s tok\n" "$1" "$(kb "$2")" "$(tok "$2")"; }

# ---------------------------------------------------------------- 1. resident
# TIER 1 — unconditional. Every session pays these, per CLAUDE.md + AI-GUIDE.md:22-23.
#
# `.harness/insight-index.md` was a TIER 1 member when this instrument was written and is not
# one now: `.harness/rules/05-insight-index.md` says "never a whole-file read", and three
# contracts carry the query form. The file is 20.6 KB and a scoped query over it is measured
# below, so counting it whole overstates the opening by the difference. Both figures print —
# the instrument states which access pattern it is modelling rather than picking one silently.
tier1_files=(
  "CLAUDE.md"
  "AI-GUIDE.md"
  ".harness/rules/00-core.md"
)
queried_files=(
  ".harness/insight-index.md"
)
# TIER 2 — conditional. Loaded only when a stated trigger fires. AI-GUIDE.md is
# explicit that rule fragments are selectively loaded ("do not load all of them"),
# and operator-obligations.md is "not on any always-read path".
tier2_files=(
  "CONTEXT.md"
  ".harness/rejected-decisions.md"
  ".harness/operator-obligations.md"
  ".harness/decision-rubric.md"
  "docs/tasks.md"
  "docs/dev-map.md"
)
tier1_total=0; tier2_total=0
rules_total=$(dirsz ".harness/rules")
rules_rest=$((rules_total - $(sz ".harness/rules/00-core.md")))

# What a queried store actually costs, measured rather than assumed. Terms are drawn from the
# index's own entries so the probe is representative of a real lookup, and the MEDIAN is taken
# because a query cost has a long tail — one broad term is not the typical case and one narrow
# term is not either.
queried_cost=0
queried_whole=0
for f in "${queried_files[@]}"; do queried_whole=$((queried_whole + $(sz "$f"))); done
if command -v node >/dev/null 2>&1 && [ -f .harness/scripts/doc-query.js ]; then
  qtmp=$(mktemp)
  for term in verify_all placeholder hook template insight archive; do
    node .harness/scripts/doc-query.js --in memory --doc insight-index "$term" 2>/dev/null | wc -c >> "$qtmp"
  done
  sort -n "$qtmp" -o "$qtmp"
  qn=$(wc -l < "$qtmp")
  [ "$qn" -gt 0 ] && queried_cost=$(awk -v n="$qn" 'NR==int((n+1)/2){print $1}' "$qtmp")
  rm -f "$qtmp"
fi

# ------------------------------------------------------- 2. agent dispatch cost
agent_total=0
agent_max=0
agent_max_name=""
for f in agents/*.md; do
  s=$(sz "$f"); agent_total=$((agent_total + s))
  [ "$s" -gt "$agent_max" ] && { agent_max=$s; agent_max_name="$(basename "$f")"; }
done
agent_n=$(ls agents/*.md 2>/dev/null | wc -l)

# --------------------------------------- 3. stage-4 contract read (01+02+03)
tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT
for d in docs/features/_archived/*/; do
  a=$(sz "$d/01_REQUIREMENT_ANALYSIS.md")
  b=$(sz "$d/02_SOLUTION_DESIGN.md")
  c=$(sz "$d/03_GATE_REVIEW.md")
  t=$((a + b + c))
  [ "$t" -gt 0 ] && echo "$t $(basename "$d")" >> "$tmp"
done
sort -n "$tmp" -o "$tmp"
n=$(wc -l < "$tmp")
if [ "$n" -gt 0 ]; then
  s4_median=$(awk -v n="$n" 'NR==int((n+1)/2){print $1}' "$tmp")
  s4_mean=$(awk '{s+=$1} END{printf "%.0f", s/NR}' "$tmp")
  s4_max=$(tail -1 "$tmp" | cut -d' ' -f1)
  s4_max_name=$(tail -1 "$tmp" | cut -d' ' -f2)
  s4_min=$(head -1 "$tmp" | cut -d' ' -f1)
else
  s4_median=0; s4_mean=0; s4_max=0; s4_max_name="-"; s4_min=0
fi

# ------------------------------------------------------------ 4. archive bulk
archive_total=$(find docs/features/_archived -type f -printf '%s\n' 2>/dev/null | awk '{s+=$1} END{print s+0}')
delivery_total=$(find docs/features/_archived -name '07_DELIVERY.md' -printf '%s\n' 2>/dev/null | awk '{s+=$1} END{print s+0}')
design_total=$(find docs/features/_archived -name '02_SOLUTION_DESIGN.md' -printf '%s\n' 2>/dev/null | awk '{s+=$1} END{print s+0}')

for f in "${tier1_files[@]}"; do tier1_total=$((tier1_total + $(sz "$f"))); done
for f in "${tier2_files[@]}"; do tier2_total=$((tier2_total + $(sz "$f"))); done
always_read=$tier1_total
conditional=$((tier2_total + rules_rest))

if [ "$JSON" = "1" ]; then
  printf '{"tier1_bytes":%d,"tier2_bytes":%d,"rules_bytes":%d,"conditional_bytes":%d,' \
    "$tier1_total" "$tier2_total" "$rules_total" "$conditional"
  printf '"agent_total_bytes":%d,"agent_count":%d,"agent_max_bytes":%d,' \
    "$agent_total" "$agent_n" "$agent_max"
  printf '"stage4_median_bytes":%d,"stage4_mean_bytes":%d,"stage4_max_bytes":%d,' \
    "$s4_median" "$s4_mean" "$s4_max"
  printf '"archive_bytes":%d,"delivery_bytes":%d,' "$archive_total" "$delivery_total"
  printf '"queried_whole_bytes":%d,"queried_cost_bytes":%d,"chars_per_token":%s}\n' \
    "$queried_whole" "$queried_cost" "$CPT"
  exit 0
fi

echo "=== baseline A — context cost under today's access pattern ==="
echo "    (bytes exact; tokens estimated at ${CPT} chars/token)"
echo
echo "1a. TIER 1 — UNCONDITIONAL (every session pays this)"
for f in "${tier1_files[@]}"; do row "$f" "$(sz "$f")"; done
echo "  ---"
row "TIER 1 TOTAL" "$tier1_total"
echo
echo "1b. QUERIED, NOT READ (the contracts forbid the whole-file read)"
for f in "${queried_files[@]}"; do row "  $f whole" "$(sz "$f")"; done
row "  one scoped query, median of 6 real terms" "$queried_cost"
echo
echo "1c. TIER 2 — CONDITIONAL (only when a trigger fires)"
for f in "${tier2_files[@]}"; do row "$f" "$(sz "$f")"; done
row ".harness/rules/ (12 remaining fragments)" "$rules_rest"
echo "  ---"
row "TIER 2 TOTAL (worst case, all triggers fire)" "$conditional"
echo
echo "2. PER-DISPATCH AGENT CONTRACT (one loads per sub-agent)"
row "all ${agent_n} agents combined" "$agent_total"
row "largest single: ${agent_max_name}" "$agent_max"
echo
echo "3. STAGE-4 DEVELOPER CONTRACT READ (01+02+03), n=${n} archived tasks"
row "median" "$s4_median"
row "mean" "$s4_mean"
row "min" "$s4_min"
row "max (${s4_max_name})" "$s4_max"
echo
echo "4. ARCHIVE BULK (deletion candidate, §9.1)"
row "docs/features/_archived total" "$archive_total"
row "  of which 07_DELIVERY (keep -> memory)" "$delivery_total"
row "  of which 02_SOLUTION_DESIGN (drop)" "$design_total"
echo
echo "=== P1 acceptance proxy ==="
dev=$(sz agents/developer.md)
# P4 moved the procedure and the output schema out of the contract and into a playbook the
# agent Reads as its first action. Both are counted. Charging only the contract would report
# a saving that is a relocation: the bytes still arrive in the same context, in the same turn.
pb=$(sz .harness/playbooks/developer.md)
legacy_tier1=$((always_read + queried_whole))
opening=$((legacy_tier1 + dev + pb + s4_median))
echo "  LEGACY pattern — read every store and every upstream contract whole"
row "  tier 1 + insight-index read whole" "$legacy_tier1"
row "  developer.md + its playbook" "$((dev + pb))"
row "  01+02+03 median" "$s4_median"
echo "  ---"
row "  STAGE-4 OPENING (legacy)" "$opening"
echo

# The Developer no longer reads 01/02/03 whole — its contract opens with
# `doc-query --for developer`, which returns the sections addressed to it and returns any
# heading the schema does not recognise. So the figure above is the LEGACY pattern, and this
# one is what the current contract costs. The gap between them is conformance, nothing else:
# `evals/measure-stage-query.sh` splits the same corpus by whether a document obeys its schema.
if [ -f .harness/scripts/doc-query.js ] && command -v node >/dev/null 2>&1; then
  addr_tmp=$(mktemp)
  for d in docs/features/_archived/*/ docs/features/*/; do
    slug=$(basename "$d")
    case "$slug" in _archived|_supervision|_template) continue;; esac
    node .harness/scripts/doc-query.js --for developer --task "$slug" --files 2>/dev/null |
      awk '/^--- /{ gsub(/[(,]/,"",$0); if ($2 ~ /0[123]_/) a+=$5 } END{ if (a>0) print a }' >> "$addr_tmp"
  done
  sort -n "$addr_tmp" -o "$addr_tmp"
  an=$(wc -l < "$addr_tmp")
  if [ "$an" -gt 0 ]; then
    s4_addr=$(awk -v n="$an" 'NR==int((n+1)/2){print $1}' "$addr_tmp")
    current=$((always_read + queried_cost + dev + pb + s4_addr))
    echo "  AS THE CONTRACTS NOW SPECIFY IT — query the index, read the addressed sections"
    row "  tier 1 (read whole)" "$always_read"
    row "  one insight query (median)" "$queried_cost"
    row "  developer.md (contract, resident in every dispatch)" "$dev"
    row "  .harness/playbooks/developer.md (read once, on dispatch)" "$pb"
    row "  01+02+03 addressed median, n=${an}" "$s4_addr"
    echo "  ---"
    row "  STAGE-4 OPENING (current)" "$current"
    echo

    # What still stands between the current figure and the bar, priced item by item. Every
    # line is a measured quantity from this run, not an estimate of future work: the point is
    # that the remaining distance is arithmetic, so a change either moves it or does not.
    bar=$(awk -v c="$CPT" 'BEGIN{printf "%.0f", 10000*c}')

    # THE CEILING CONFORMANCE CAN REACH, computed structurally rather than extrapolated.
    #
    # This block used to price one lever: "if 01/02/03 conformed (3.67x, measured)". That
    # factor is real and it is about the wrong documents. `measure-stage-query.sh` derives it
    # from the nine stage documents in the whole archive that conform — and NOT ONE of them is
    # a 01 or a 02. They are two 03s, two 04s, two 05s and three 06s, from four tasks, three of
    # which are the tasks that built this machinery. Applying it to a quantity made of 01+02+03
    # extrapolated across document types, and 02 alone is over half that quantity.
    #
    # What conformance actually changes is the ADDRESSED FRACTION: how many of a document's
    # declared sections the schema routes to this role. That is knowable exactly, from the
    # schema, with no sample at all — and for the Developer it is nearly everything, because
    # the requirement and the design are written FOR the developer:
    #
    #     01  7 of 8 sections addressed        02  10 of 12        03  2 of 5
    #
    # So a perfectly conforming 01+02+03 still reaches the Developer nearly whole. The section
    # counts below are read live from the schema, so this bound moves when the routing does.
    b01=$(node .harness/scripts/stage-schema.js --map 2>/dev/null | awk '/^01_/{f=1;next} /^$/{f=0} f&&/^  ##/{n++} END{print n+0}')
    d01=$(node .harness/scripts/stage-schema.js --map --for developer 2>/dev/null | awk '/^01_/{f=1;next} /^$/{f=0} f&&/^  ##/{n++} END{print n+0}')
    b02=$(node .harness/scripts/stage-schema.js --map 2>/dev/null | awk '/^02_/{f=1;next} /^$/{f=0} f&&/^  ##/{n++} END{print n+0}')
    d02=$(node .harness/scripts/stage-schema.js --map --for developer 2>/dev/null | awk '/^02_/{f=1;next} /^$/{f=0} f&&/^  ##/{n++} END{print n+0}')
    b03=$(node .harness/scripts/stage-schema.js --map 2>/dev/null | awk '/^03_/{f=1;next} /^$/{f=0} f&&/^  ##/{n++} END{print n+0}')
    d03=$(node .harness/scripts/stage-schema.js --map --for developer 2>/dev/null | awk '/^03_/{f=1;next} /^$/{f=0} f&&/^  ##/{n++} END{print n+0}')
    frac=$(awk -v a="$d01" -v b="$b01" -v c="$d02" -v d="$b02" -v e="$d03" -v f="$b03" \
      'BEGIN{ if(b*d*f==0){print "1.00"} else {print (a/b*0.30 + c/d*0.57 + e/f*0.13)} }')
    conformed=$(awk -v a="$s4_addr" -v f="$frac" 'BEGIN{printf "%.0f", a*f}')

    echo "  GAP TO THE BAR — ${bar} B is 10,000 tok at ${CPT} chars/token"
    row "  current" "$current"
    echo "      sections the schema addresses to the Developer: 01 ${d01}/${b01} · 02 ${d02}/${b02} · 03 ${d03}/${b03}"
    row "  - the most perfect conformance can withhold" "$((s4_addr - conformed))"
    echo "  ---"
    remaining=$((current - (s4_addr - conformed)))
    row "  floor under perfect conformance" "$remaining"
    if [ "$remaining" -gt "$bar" ]; then
      row "  STILL over the bar by" "$((remaining - bar))"
      echo "      Routing cannot close this. The requirement and the design are written FOR the"
      echo "      Developer, so the schema addresses almost all of them to it however well they"
      echo "      conform. What is left is DOCUMENT SIZE: median 02 is 35.4 KB, and its cap was"
      echo "      500 lines with no byte arm until v0.52.0 — the wrong-unit hole that the caps"
      echo "      table already names three times for other documents."
    else
      echo "      Under the bar. Re-measure live before claiming it."
    fi
  fi
  rm -f "$addr_tmp"
fi
echo
echo "  Brief's measured resident prompt: 60804 tok (live session, authoritative)"
echo "  Target after P1:                  <10000 tok  (6.1x reduction)"
