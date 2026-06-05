#!/usr/bin/env bash
# test-guard-rm.sh — Drive evals/guard-rm-cases.md against .harness/scripts/guard-rm.sh
# Out-of-scope for verify_all (v0.15). Use arr=() not declare -a per insight 2026-05-16.
set -uo pipefail

# Script lives at .harness/scripts/ — repo root is two levels up.
repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
guard="$repo_root/.harness/scripts/guard-rm.sh"
cd "$repo_root"

pass=0
fail=0
failures=()

# Each case: id|cmd|override|expected
cases=(
    "1|rm -rf /|0|BLOCK"
    "2|rm -rf /etc|0|BLOCK"
    "3|rm -rf ~/Desktop/foo|0|BLOCK"
    "4|rm -rf ../../../tmp|0|BLOCK"
    "5|rm -rf build/|0|ALLOW"
    "6|rm -rf node_modules|0|ALLOW"
    "7|Remove-Item -Recurse C:\\Windows|0|BLOCK"
    '8|pwsh -c "Remove-Item -Recurse C:\\Windows"|0|BLOCK'
    "9|find /etc -delete|0|BLOCK"
    "10|find . -name '*.log' -delete|0|ALLOW"
    "11|rm -rf /etc/foo|1|ALLOW"
    # v0.15.1 rollback hardening — regressions for D-1 / D-2 (find-predicate-skip applied to every verb).
    "12|Remove-Item -Path C:\\Windows -Recurse|0|BLOCK"
    "13|rm -name /etc/passwd|0|BLOCK"
    "14|rm -path /etc -delete|0|BLOCK"
    "15|rm -type f /etc/x|0|BLOCK"
    "16|rm -mtime +0 /etc/x|0|BLOCK"
    "17|find /tmp -name '*.log' -delete|0|BLOCK"
)

# JSON-encode a command string into the {"tool_input":{"command":"..."}} shape.
# Only use python if a real Python is installed (Windows can have a MS-Store stub
# that fakes `command -v` success then exits non-zero on real invocation).
_have_python=0
if command -v python3 >/dev/null 2>&1; then
    if echo '' | python3 -c 'pass' >/dev/null 2>&1; then _have_python=1; fi
fi
encode_payload() {
    local cmd="$1"
    if (( _have_python == 1 )); then
        python3 -c '
import json, sys
print(json.dumps({"tool_input":{"command": sys.argv[1]}}))
' "$cmd"
    else
        # Fallback: minimal escaping (\ and ").
        local esc="${cmd//\\/\\\\}"
        esc="${esc//\"/\\\"}"
        printf '{"tool_input":{"command":"%s"}}' "$esc"
    fi
}

for row in "${cases[@]}"; do
    id="${row%%|*}"; rest="${row#*|}"
    cmd="${rest%%|*}"; rest="${rest#*|}"
    override="${rest%%|*}"; expected="${rest#*|}"

    payload=$(encode_payload "$cmd")
    unset HARNESS_ALLOW_OUTSIDE_RM
    if [[ "$override" == "1" ]]; then export HARNESS_ALLOW_OUTSIDE_RM=1; fi

    printf '%s' "$payload" | bash "$guard" >/dev/null 2>&1
    exit_code=$?

    if [[ "$override" == "1" ]]; then unset HARNESS_ALLOW_OUTSIDE_RM; fi

    case "$exit_code" in
        0) actual="ALLOW" ;;
        2) actual="BLOCK" ;;
        *) actual="UNKNOWN(exit=$exit_code)" ;;
    esac

    if [[ "$actual" == "$expected" ]]; then
        printf "  PASS  case %2s: %s -> %s\n" "$id" "$cmd" "$actual"
        ((pass++))
    else
        printf "  FAIL  case %2s: %s -> got %s, expected %s\n" "$id" "$cmd" "$actual" "$expected" >&2
        ((fail++))
        failures+=("case $id: expected $expected, got $actual")
    fi
done

echo ""
echo "=== test-guard-rm summary ==="
echo "  PASS: $pass"
echo "  FAIL: $fail"
if (( fail > 0 )); then
    echo ""
    echo "Failures:" >&2
    for f in "${failures[@]}"; do echo "  - $f" >&2; done
    exit 1
fi
exit 0
