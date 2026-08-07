#!/usr/bin/env bash
# test-guard-rm.sh — Drive evals/guard-rm-cases.md against a guard-rm.sh copy.
#
#   bash .harness/scripts/test-guard-rm.sh [guard-path]
#
# [guard-path] defaults to $repo_root/.harness/scripts/guard-rm.sh. Pass an
# alternate path to drive a staged template copy or a scratch mutant WITHOUT
# touching the live PreToolUse hook.
#
# Out-of-scope for verify_all (v0.15). Use arr=() not declare -a per insight 2026-05-16.
set -uo pipefail

# Script lives at .harness/scripts/ — repo root is two levels up.
repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
guard="${1:-$repo_root/.harness/scripts/guard-rm.sh}"
cd "$repo_root"

if [[ ! -f "$guard" ]]; then
    echo "test-guard-rm: guard not found: $guard" >&2
    exit 1
fi
echo "  guard under test: $guard"

pass=0
fail=0
failures=()

# ROW ENCODING — flat 4-tuples iterated in strides of 4: id, cmd, override,
# expected. There is deliberately NO delimiter: the previous `id|cmd|…` form
# truncated any command containing `|` and fed the guard a different command
# than the row claimed.
#
# QUOTING RULE (mandatory): single-quote — or use $'…' — every row whose text
# contains `$`, a backtick or `$(`. A DOUBLE-quoted element containing `$(` is
# command-substituted WHEN THE ARRAY IS DEFINED, i.e. the driver would really
# run the deletion on the developer's machine.
cases=(
    "1" "rm -rf /" "0" "BLOCK"
    "2" "rm -rf /etc" "0" "BLOCK"
    "3" "rm -rf ~/Desktop/foo" "0" "BLOCK"
    "4" "rm -rf ../../../tmp" "0" "BLOCK"
    "5" "rm -rf build/" "0" "ALLOW"
    "6" "rm -rf node_modules" "0" "ALLOW"
    "7" 'Remove-Item -Recurse C:\Windows' "0" "BLOCK"
    "8" 'pwsh -c "Remove-Item -Recurse C:\Windows"' "0" "BLOCK"
    "9" "find /etc -delete" "0" "BLOCK"
    "10" "find . -name '*.log' -delete" "0" "ALLOW"
    "11" "rm -rf /etc/foo" "1" "ALLOW"
    # v0.15.1 rollback hardening — regressions for D-1 / D-2 (find-predicate-skip applied to every verb).
    "12" 'Remove-Item -Path C:\Windows -Recurse' "0" "BLOCK"
    "13" "rm -name /etc/passwd" "0" "BLOCK"
    "14" "rm -path /etc -delete" "0" "BLOCK"
    "15" "rm -type f /etc/x" "0" "BLOCK"
    "16" "rm -mtime +0 /etc/x" "0" "BLOCK"
    "17" "find /tmp -name '*.log' -delete" "0" "BLOCK"

    # --- T-17 guard-cmd-chain · AC-1 bypass matrix (every row must BLOCK) ---
    "a" "rm -rf /etc/harness-guard-probe" "0" "BLOCK"
    "b" "echo hi && rm -rf /etc/harness-guard-probe" "0" "BLOCK"
    "c" "true; rm -rf /etc/harness-guard-probe" "0" "BLOCK"
    "d" "false || rm -rf /etc/harness-guard-probe" "0" "BLOCK"
    "e" "sleep 0 & rm -rf /etc/harness-guard-probe" "0" "BLOCK"
    "f" $'echo hi\nrm -rf /etc/harness-guard-probe' "0" "BLOCK"
    "f2" $'echo hi\r\nrm -rf /etc/harness-guard-probe' "0" "BLOCK"
    "g" "( cd /tmp && rm -rf /etc/harness-guard-probe )" "0" "BLOCK"
    "h" "{ rm -rf /etc/harness-guard-probe ; }" "0" "BLOCK"
    # SINGLE-quoted: a double-quoted element here would run the deletion at
    # array-definition time (gate C-5).
    "i" 'echo $(rm -rf /etc/harness-guard-probe)' "0" "BLOCK"
    "j" "ls | xargs rm -rf /etc/harness-guard-probe" "0" "BLOCK"
    "k" "ls | xargs -I {} rm -rf /etc/harness-guard-probe" "0" "BLOCK"
    "l" "env FOO=1 rm -rf /etc/harness-guard-probe" "0" "BLOCK"
    "m" "nohup rm -rf /etc/harness-guard-probe" "0" "BLOCK"
    "n" "timeout 5 rm -rf /etc/harness-guard-probe" "0" "BLOCK"
    "o" "find . -name '*.log' -exec rm -rf /etc/harness-guard-probe ;" "0" "BLOCK"
    "p" "FOO=1 rm -rf /etc/harness-guard-probe" "0" "BLOCK"
    "q" 'echo hi | head -1 && Remove-Item -Recurse C:\Windows' "0" "BLOCK"
    "r" 'bash -c "rm -rf /etc/harness-guard-probe"' "0" "BLOCK"

    # --- AC-3 legitimate-form corpus (exit 0 for every row EXCEPT L10) ---
    "L1" "cd sub && rm -rf ./node_modules" "0" "ALLOW"
    "L2" "npm run build && rm -rf dist/tmp" "0" "ALLOW"
    "L3" "rm -rf build && mkdir build" "0" "ALLOW"
    "L4" "git status; rm -rf .cache" "0" "ALLOW"
    "L5" "test -d node_modules && rm -rf node_modules || echo none" "0" "ALLOW"
    "L6" "find . -name '*.pyc' -delete" "0" "ALLOW"
    "L7" 'echo "rm -rf /etc/harness-guard-probe"' "0" "ALLOW"
    "L8" 'grep -rn "rm -rf /etc/harness-guard-probe" .' "0" "ALLOW"
    "L9" $'cat > ./guard-probe.txt <<\'EOF\'\nrm -rf /etc/harness-guard-probe\nEOF' "0" "ALLOW"
    # L10: expected BLOCK, unchanged from pre-change. The body\'s lone
    # apostrophe leaves tokenize() unbalanced, so this line ALREADY blocks;
    # flipping it to ALLOW would violate IS-2. One instance of a class.
    "L10" $'cat > ./guard-probe.txt <<\'EOF\'\nrm -rf /etc/harness-guard-probe # don\'t\nEOF' "0" "BLOCK"
    "L11" 'printf %s '"'"'{"tool_input":{"command":"echo hi && rm -rf /etc/x"}}'"'"' | bash .harness/scripts/guard-rm.sh' "0" "ALLOW"
    "L12" "bash .harness/scripts/test-guard-rm.sh" "0" "ALLOW"
    "L13" 'git commit -m "guard: block rm -rf outside root"' "0" "ALLOW"
    "L14" "HARNESS_ALLOW_OUTSIDE_RM=1 rm -rf /etc/harness-guard-probe" "0" "ALLOW"

    # --- AC-5 fail-closed ---
    "F1" 'echo hi && rm -rf "/etc/harness-guard-probe' "0" "BLOCK"
    "F2" 'echo "$(basename "$(dirname "$(pwd)")")"' "0" "BLOCK"
    "F3" $'cat <<EOF\nrm -rf /etc/harness-guard-probe' "0" "BLOCK"

    # --- AC-6 verb set unchanged: these stay deliberately unguarded ---
    "V1" "mv /etc/harness-guard-probe ." "0" "ALLOW"
    "V2" "cp x /etc/harness-guard-probe" "0" "ALLOW"
    "V3" "echo hi > /etc/harness-guard-probe" "0" "ALLOW"

    # --- Gate condition C-10: backtick + process substitution ---
    "C10a" 'echo `rm -rf /etc/harness-guard-probe`' "0" "BLOCK"
    "C10b" "cat <(rm -rf /etc/harness-guard-probe)" "0" "BLOCK"

    # --- Gate condition C-11: PARAM / ARITH interiors are verbatim-until-closer ---
    "C11a" 'echo $((1 << 3))' "0" "ALLOW"
    "C11b" 'echo "${HOME}"' "0" "ALLOW"

    # --- Gate condition C-12: CR is a scanner trigger in its own right ---
    "C12cr" $'echo hi\rrm -rf /etc/harness-guard-probe' "0" "BLOCK"
    "C12tee" "tee >(rm -rf /etc/harness-guard-probe)" "0" "BLOCK"

    # --- Gate condition C-14: pin the pre-declared C-1 over-block so a future
    # "fix" cannot silently re-open the monotonicity regression (F-2). ---
    "C14" "rm -rf ./build | tee /tmp/x.log" "0" "BLOCK"

    # --- Gate condition C-13 + prefix-strip regressions ---
    "P1" "A=1 rm -rf /etc/harness-guard-probe" "0" "BLOCK"
    "P2" "A+=1 rm -rf /etc/harness-guard-probe" "0" "BLOCK"
    "P3" "sudo rm -rf /etc/harness-guard-probe" "0" "BLOCK"
    "P4" "sudo -u root rm -rf /etc/harness-guard-probe" "0" "BLOCK"
    "P5" "for f in x; do rm -rf /etc/harness-guard-probe; done" "0" "BLOCK"

    # --- Override fail-closed shape (the three bypass paths) ---
    "O1" "echo x && HARNESS_ALLOW_OUTSIDE_RM=1 rm -rf /etc/harness-guard-probe" "0" "BLOCK"
    "O2" "env HARNESS_ALLOW_OUTSIDE_RM=1 rm -rf /etc/harness-guard-probe" "0" "BLOCK"
    "O3" 'bash -c "HARNESS_ALLOW_OUTSIDE_RM=1 rm -rf /etc/harness-guard-probe"' "0" "BLOCK"

    # --- Carrier false-positive boundary + B-3 empty positions ---
    "N1" "ls | xargs grep rm" "0" "ALLOW"
    "N2" "echo hi ; ; rm -rf ./build" "0" "ALLOW"
    "N3" "rm -rf ./build &&" "0" "ALLOW"
    "N4" "timeout 5 env FOO=1 nice -n 10 make" "0" "ALLOW"

    # --- ANSI-C quoting. The sq_ansi flag keeps the SCANNER in step with bash,
    # but the retained pre-change pass still counts every `'`, so an odd
    # apostrophe parity BLOCKs exactly as it does today (§10.2 item 11). ---
    "Q1" 'echo $'"'"'it\'"'"'s fine'"'"'' "0" "BLOCK"
    "Q2" 'echo $'"'"'its fine'"'"' && rm -rf /etc/harness-guard-probe' "0" "BLOCK"

    # --- Accepted over-block (AC-4 / OQ-6a), pinned so it cannot regress
    # silently. A BACKSLASH-ESCAPED quote pair that SPANS a top-level separator
    # yields a scanner position with odd quote parity, which the byte-unchanged
    # tokenize() then rejects -> BLOCK. W2/W3 are the boundary: the same text
    # with real quotes, and the same escaped pair without a separator inside,
    # both stay ALLOW. See .harness/rules/75-safety-hook.md. ---
    "W1" 'echo \"a ; b\"' "0" "BLOCK"
    "W2" 'echo "a ; b"' "0" "ALLOW"
    "W3" 'echo \"a b\"' "0" "ALLOW"
    # W4 is single-quoted (inner `'` written as '"'"') because it contains `$`:
    # the quoting rule above is a safety rule, not a per-row escape analysis.
    "W4" 'sh -c '"'"'cd \"$CLAUDE_PROJECT_DIR\" 2>/dev/null && bash .harness/scripts/guard-rm.sh'"'"'' "0" "ALLOW"

    # --- Round 2 (code review A-3): an ESCAPED `\>` / `\<` before `&` is NOT a
    # redirect — bash reads the escaped character as text, so the `&` really is
    # a separator and the following command must be judged. R3 is the boundary:
    # a REAL `>&` dup-redirect makes `rm` a redirect target word, not a command,
    # and must stay ALLOW. See row 12 in split_positions. ---
    "R1" 'echo a\>& rm -rf /etc/harness-guard-probe' "0" "BLOCK"
    "R2" 'echo a\<& rm -rf /etc/harness-guard-probe' "0" "BLOCK"
    "R3" 'echo a>& rm -rf /etc/harness-guard-probe' "0" "ALLOW"

    # --- Round 2 (code review A-2): accepted over-block — a here-document fed
    # to a shell interpreter is judged as a command string. ---
    "H1" $'bash <<EOF\nrm -rf /etc/harness-guard-probe\nEOF' "0" "BLOCK"

    # --- Round 3 (code review CR2-1): a LEADING `&` sits at i == 0, where the
    # round-2 `redir_i` sentinel -1 equalled `i - 1` and appended instead of
    # flushing. The sentinel is now -2 (outside the domain of `i - 1`). R4 pins
    # boundary B-3 (an empty position between separators must not change the
    # verdict); R5 pins the executable vector — `&` is PowerShell's call
    # operator and the guard recurses into `pwsh -c` strings, so the collision
    # fired at depth 1 too. R5 is row 8 plus one character. ---
    "R4" '& rm -rf /etc/harness-guard-probe' "0" "BLOCK"
    "R5" 'pwsh -c "& Remove-Item -Recurse C:\Windows"' "0" "BLOCK"
)

# JSON-encode a command string into the {"tool_input":{"command":"..."}} shape.
# Only use python if a real Python is installed (Windows can have a MS-Store stub
# that fakes `command -v` success then exits non-zero on real invocation).
_have_python=0
if command -v python3 >/dev/null 2>&1; then
    if echo '' | python3 -c 'pass' >/dev/null 2>&1; then _have_python=1; fi
fi

# Literal replace-all, immune to bash 5.2 patsub_replacement (`&` in the
# replacement). Copied from .harness/scripts/upgrade-project.sh.
tg_replace_all() {
    local rest="$1" needle="$2" repl="$3" out=""
    while [[ "$rest" == *"$needle"* ]]; do
        out="$out${rest%%"$needle"*}$repl"
        rest="${rest#*"$needle"}"
    done
    printf '%s' "$out$rest"
}

encode_payload() {
    local cmd="$1"
    if (( _have_python == 1 )); then
        python3 -c '
import json, sys
print(json.dumps({"tool_input":{"command": sys.argv[1]}}))
' "$cmd"
    else
        # Fallback: minimal escaping (\, ", and the whitespace escapes — without
        # the last a multi-line row could not be expressed on a no-python3 host).
        local esc="${cmd//\\/\\\\}"
        esc="${esc//\"/\\\"}"
        local _lf _cr _tab
        _lf=$(printf '\nx'); _lf="${_lf%x}"
        _cr=$(printf '\rx'); _cr="${_cr%x}"
        _tab=$(printf '\tx'); _tab="${_tab%x}"
        esc=$(tg_replace_all "$esc" "$_lf" '\n')
        esc=$(tg_replace_all "$esc" "$_cr" '\r')
        esc=$(tg_replace_all "$esc" "$_tab" '\t')
        printf '{"tool_input":{"command":"%s"}}' "$esc"
    fi
}

n=${#cases[@]}
r=0
while (( r < n )); do
    id="${cases[$r]}"
    cmd="${cases[$((r+1))]}"
    override="${cases[$((r+2))]}"
    expected="${cases[$((r+3))]}"
    r=$((r + 4))

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
        printf "  PASS  case %3s: %s -> %s\n" "$id" "$cmd" "$actual"
        ((pass++))
    else
        printf "  FAIL  case %3s: %s -> got %s, expected %s\n" "$id" "$cmd" "$actual" "$expected" >&2
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
