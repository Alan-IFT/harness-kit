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
tier1_files=(
  "CLAUDE.md"
  "AI-GUIDE.md"
  ".harness/rules/00-core.md"
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
  printf '"archive_bytes":%d,"delivery_bytes":%d,"chars_per_token":%s}\n' \
    "$archive_total" "$delivery_total" "$CPT"
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
echo "1b. TIER 2 — CONDITIONAL (only when a trigger fires)"
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
opening=$((always_read + dev + s4_median))
echo "  Developer stage-4 opening = tier1 + developer contract + 01/02/03 median"
row "  tier 1 (unconditional)" "$always_read"
row "  developer.md" "$dev"
row "  01+02+03 median" "$s4_median"
echo "  ---"
row "  STAGE-4 OPENING" "$opening"
echo
echo "  Which lever is bigger, per task:"
row "  §9 delete rules/ (once per session)" "$rules_total"
row "  §8 handoff card replaces 01/02/03 (EVERY task)" "$s4_median"
echo
echo "  Brief's measured resident prompt: 60804 tok (live session, authoritative)"
echo "  Target after P1:                  <10000 tok  (6.1x reduction)"
