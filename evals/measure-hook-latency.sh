#!/usr/bin/env bash
# measure-hook-latency.sh — what the destructive-command guard costs per Bash tool call.
#
# `guard-rm` runs on EVERY Bash tool call as a PreToolUse hook, so its start-up cost is paid
# hundreds of times per task and is the one number that could have vetoed the TypeScript port.
# The migration brief set the ceiling at 20 ms and asked for the figure to be recorded; a
# figure recorded once and never re-derived is a claim, not a measurement, so this is the
# instrument that re-derives it.
#
# Two paths are timed because both ship and both must stay under the ceiling:
#   allow  — a benign command, the overwhelmingly common case (parse, decide, exit 0)
#   block  — a destructive command outside the repo, which walks the full scanner
#
# The MEDIAN is reported alongside the mean: process start-up has a long right tail from
# scheduler noise, and a mean over a handful of runs reports the tail rather than the cost.
#
# Usage: bash evals/measure-hook-latency.sh [runs]   (default 50)

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

RUNS="${1:-50}"
GUARD=".harness/scripts/guard-rm.sh"
[ -f "$GUARD" ] || { echo "measure-hook-latency: $GUARD missing" >&2; exit 2; }
command -v node >/dev/null 2>&1 || { echo "measure-hook-latency: node not on PATH" >&2; exit 2; }

# The payload shape is the hook's own contract: PreToolUse hands the tool input as JSON on
# stdin. Both fixtures are inert — the block case is judged, never executed.
allow_payload='{"tool_name":"Bash","tool_input":{"command":"git status --short"}}'
block_payload='{"tool_name":"Bash","tool_input":{"command":"rm -rf /etc/nonexistent-probe"}}'

time_path() { # name payload expected_exit
    local name="$1" payload="$2" want="$3" tmp
    tmp=$(mktemp)
    local i start end
    for ((i = 0; i < RUNS; i++)); do
        start=$(date +%s%N)
        printf '%s' "$payload" | bash "$GUARD" >/dev/null 2>&1
        local rc=$?
        end=$(date +%s%N)
        if [ "$rc" -ne "$want" ]; then
            echo "measure-hook-latency: $name returned $rc, expected $want — the fixture no longer" >&2
            echo "  exercises the path it names; fix the fixture before trusting the number." >&2
            rm -f "$tmp"
            return 1
        fi
        echo $(((end - start) / 1000000)) >> "$tmp"
    done
    sort -n "$tmp" -o "$tmp"
    awk -v n="$RUNS" -v label="$name" '
      { v[NR] = $1; s += $1 }
      END {
        printf "  %-6s  median %3d ms   mean %5.1f ms   min %3d ms   max %3d ms\n",
               label, v[int((NR + 1) / 2)], s / NR, v[1], v[NR]
      }' "$tmp"
    med=$(awk -v n="$RUNS" 'NR==int((n+1)/2){print $1}' "$tmp")
    rm -f "$tmp"
    echo "$med" > "/tmp/hook-latency-$name.median"
}

echo "=== guard-rm PreToolUse latency, ${RUNS} runs per path ==="
echo "    (wall clock around a full process start, as the hook actually pays it)"
echo
time_path allow "$allow_payload" 0 || exit 1
time_path block "$block_payload" 2 || exit 1
echo

worst=0
for p in allow block; do
    m=$(cat "/tmp/hook-latency-$p.median" 2>/dev/null || echo 0)
    [ "$m" -gt "$worst" ] && worst=$m
    rm -f "/tmp/hook-latency-$p.median"
done

echo "  ceiling (v2 migration brief): 20 ms"
if [ "$worst" -le 20 ]; then
    echo "  worst median: ${worst} ms — UNDER the ceiling"
else
    echo "  worst median: ${worst} ms — OVER the ceiling; the guard is on every Bash call, so this"
    echo "  is a per-call tax on every task. Re-open the single-binary option before shipping."
    exit 1
fi
