#!/usr/bin/env bash
# diff-hook-spec.sh — differential gate for the hook-spec TypeScript port.
#
# The spec is a pure function over a tiny, fully enumerable input space, so this
# does not sample: it runs EVERY input through both implementations and requires
# byte-identical stdout, stderr and exit code.
#
# The comparison is against the shell twin as committed, never against a value the
# port itself produced — a port that reshapes uniformly would pass a self-derived
# check. Run before any cutover; a single mismatch blocks it.
#
# Usage: bash tools/diff-hook-spec.sh [--verbose]

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

SH=".harness/scripts/hook-spec.sh"
JS=".harness/scripts/hook-spec.js"

VERBOSE=0
[ "${1:-}" = "--verbose" ] && VERBOSE=1

if [ ! -f "$JS" ]; then
    echo "diff-hook-spec: $JS missing — run 'npm run build' first" >&2
    exit 2
fi

pass=0
fail=0

# Compare one argument vector across both implementations.
compare() {
    local -a args=("$@")
    local label="${args[*]}"
    [ ${#args[@]} -eq 0 ] && label="<no args>"

    local sh_out sh_err sh_rc js_out js_err js_rc
    sh_out=$(bash "$SH" "${args[@]}" 2>/tmp/hs_sh_err); sh_rc=$?
    sh_err=$(cat /tmp/hs_sh_err)
    js_out=$(node "$JS" "${args[@]}" 2>/tmp/hs_js_err); js_rc=$?
    js_err=$(cat /tmp/hs_js_err)

    local why=""
    [ "$sh_out" != "$js_out" ] && why="stdout"
    [ "$sh_rc" != "$js_rc" ] && why="${why:+$why,}exit"
    [ "$sh_err" != "$js_err" ] && why="${why:+$why,}stderr"

    if [ -z "$why" ]; then
        pass=$((pass + 1))
        [ "$VERBOSE" = "1" ] && printf '  ok    %s\n' "$label"
    else
        fail=$((fail + 1))
        printf '  FAIL  %s  (%s)\n' "$label" "$why"
        printf '        sh  rc=%s out=%q err=%q\n' "$sh_rc" "$sh_out" "$sh_err"
        printf '        js  rc=%s out=%q err=%q\n' "$js_rc" "$js_out" "$js_err"
    fi
}

TOOLS=(harness-sync guard-rm ambient-prompt ambient-reset)
OSES=(windows unix)

echo "=== hook-spec differential: shell twin vs TypeScript port ==="
echo

echo "-- success space (exhaustive) --"
compare tools
for t in "${TOOLS[@]}"; do
    compare event "$t"
    compare matcher "$t"
    compare semantics "$t"
    for o in "${OSES[@]}"; do
        compare command "$t" "$o"
    done
done
compare hostos

echo
echo "-- error space --"
compare                                  # empty query
compare bogus                            # unknown query
compare tools extra                      # arity: tools takes 0
compare hostos extra                     # arity: hostos takes 0
compare event                            # arity: event takes 1
compare event guard-rm extra             # arity: event takes 1
compare matcher                          # arity
compare semantics                        # arity
compare command guard-rm                 # arity: command takes 2
compare command guard-rm unix extra      # arity: command takes 2
compare event not-a-tool                 # unknown tool
compare matcher not-a-tool
compare semantics not-a-tool
compare command not-a-tool unix          # unknown tool checked before os
compare command guard-rm not-an-os       # unknown os
compare command guard-rm UNIX            # os is case-sensitive
compare command guard-rm Windows
compare EVENT guard-rm                   # query is case-sensitive

rm -f /tmp/hs_sh_err /tmp/hs_js_err

echo
echo "=== $((pass + fail)) cases: $pass identical, $fail divergent ==="
[ "$fail" -eq 0 ] || exit 1
echo "Byte-identical across the whole input space."
