#!/usr/bin/env bash
# diff-guard-rm.sh — differential gate for the guard-rm TypeScript port.
#
# guard-rm is fail-CLOSED and wired into PreToolUse, so the port is never allowed
# near the hook path until it agrees with the shell twin. Two independent arms:
#
#   ARM 1 (corpus)      Drives the committed 87-case corpus through BOTH guards
#                       via test-guard-rm.sh's [guard-path] parameter, which exists
#                       precisely so a candidate can be driven without touching the
#                       live hook. The port is reached through a shim, so the corpus
#                       is used as-is and never duplicated.
#
#   ARM 2 (raw diff)    Replays the same inputs directly against both guards and
#                       compares exit code AND stderr byte-for-byte. Arm 1 only
#                       checks the verdict matches the table; two implementations
#                       can both be "correct" there while disagreeing on the message
#                       a human reads when blocked.
#
# Usage: bash tools/diff-guard-rm.sh

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

SH=".harness/scripts/guard-rm.sh"
JS=".harness/scripts/guard-rm.js"
SHIM="$(mktemp -t guard-rm-shim-XXXXXX.sh)"
trap 'rm -f "$SHIM" "$SHIM.out"' EXIT

if [ ! -f "$JS" ]; then
    echo "diff-guard-rm: $JS missing — run 'npm run build' first" >&2
    exit 2
fi

# The driver invokes its guard as `bash "$guard"`, so the shim must be a shell file
# that hands stdin to node unchanged.
printf '#!/usr/bin/env bash\nexec node %s/%s "$@"\n' "$ROOT" "$JS" > "$SHIM"

echo "=== ARM 1: 87-case corpus, both guards ==="
echo
sh_res=$(bash .harness/scripts/test-guard-rm.sh "$ROOT/$SH" 2>&1 | tail -3)
js_res=$(bash .harness/scripts/test-guard-rm.sh "$SHIM" 2>&1 | tail -3)

sh_pass=$(printf '%s' "$sh_res" | sed -n 's/.*PASS: \([0-9]*\).*/\1/p')
sh_fail=$(printf '%s' "$sh_res" | sed -n 's/.*FAIL: \([0-9]*\).*/\1/p')
js_pass=$(printf '%s' "$js_res" | sed -n 's/.*PASS: \([0-9]*\).*/\1/p')
js_fail=$(printf '%s' "$js_res" | sed -n 's/.*FAIL: \([0-9]*\).*/\1/p')

printf '  shell twin : PASS=%s FAIL=%s\n' "${sh_pass:-?}" "${sh_fail:-?}"
printf '  TS port    : PASS=%s FAIL=%s\n' "${js_pass:-?}" "${js_fail:-?}"

arm1=0
if [ "${js_fail:-1}" != "0" ] || [ "${js_pass:-0}" != "${sh_pass:-x}" ]; then
    arm1=1
    echo
    echo "  ARM 1 FAILED — per-case detail for the port:"
    bash .harness/scripts/test-guard-rm.sh "$SHIM" 2>&1 | grep -E '^\s+FAIL' | head -25
fi

echo
echo "=== ARM 2: exit code + stderr, byte-for-byte ==="
echo

pass=0
fail=0

compare() {
    local cmd="$1" label="$2"
    local payload sh_err js_err sh_rc js_rc
    payload=$(CMD="$cmd" node -e 'process.stdout.write(JSON.stringify({tool_input:{command:process.env.CMD}}))')

    sh_err=$(printf '%s' "$payload" | bash "$SH" 2>&1 >/dev/null)
    sh_rc=$(printf '%s' "$payload" | bash "$SH" >/dev/null 2>/dev/null; echo $?)
    js_err=$(printf '%s' "$payload" | node "$JS" 2>&1 >/dev/null)
    js_rc=$(printf '%s' "$payload" | node "$JS" >/dev/null 2>/dev/null; echo $?)

    if [ "$sh_rc" = "$js_rc" ] && [ "$sh_err" = "$js_err" ]; then
        pass=$((pass + 1))
    else
        fail=$((fail + 1))
        printf '  FAIL  %s\n' "$label"
        printf '        sh  rc=%s err=%s\n' "$sh_rc" "$(printf '%s' "$sh_err" | head -2 | tr '\n' '~')"
        printf '        js  rc=%s err=%s\n' "$js_rc" "$(printf '%s' "$js_err" | head -2 | tr '\n' '~')"
    fi
}

OUT="/etc/harness-guard-probe"
compare "rm -rf /"                                              "abs root"
compare "rm -rf /etc"                                           "abs outside"
compare "rm -rf ~/Desktop/foo"                                  "tilde"
compare "rm -rf ../../../tmp"                                   "dotdot escape"
compare "rm -rf build/"                                         "inside repo"
compare "rm -rf node_modules"                                   "inside repo bare"
compare "Remove-Item -Recurse C:\\Windows"                      "windows abs"
compare "pwsh -c \"Remove-Item -Recurse C:\\Windows\""          "nested pwsh"
compare "find /etc -delete"                                     "find -delete outside"
compare "find . -name '*.log' -delete"                          "find -delete inside"
compare "rm -name /etc/passwd"                                  "D-2 predicate"
compare "rm -type f /etc/x"                                     "D-2 type"
compare "echo hi && rm -rf $OUT"                                "and-chain"
compare "true; rm -rf $OUT"                                     "semicolon"
compare "false || rm -rf $OUT"                                  "or-chain"
compare "sleep 0 & rm -rf $OUT"                                 "background"
compare "( cd /tmp && rm -rf $OUT )"                            "subshell"
compare "{ rm -rf $OUT ; }"                                     "brace group"
compare "echo \$(rm -rf $OUT)"                                  "cmdsub"
compare "ls | xargs rm -rf $OUT"                                "xargs carrier"
compare "env FOO=1 rm -rf $OUT"                                 "env carrier"
compare "timeout 5 rm -rf $OUT"                                 "timeout carrier"
compare "find . -name '*.log' -exec rm -rf $OUT ;"              "find -exec"
compare "FOO=1 rm -rf $OUT"                                     "assignment prefix"
compare "bash -c \"rm -rf $OUT\""                               "nested bash"
compare "echo \"rm -rf $OUT\""                                  "quoted literal, allow"
compare "grep -rn \"rm -rf $OUT\" ."                            "grep literal, allow"
compare "sudo rm -rf /etc/x"                                    "sudo"
compare "sudo -u root rm -rf /etc/x"                            "sudo -u"
compare "rm -rf 'a"                                             "unbalanced quote"
compare "\$( \$( \$( rm -rf /etc/x ) ) )"                       "depth bound"
compare "cat > f <<'EOF'
rm -rf $OUT
EOF"                                                            "heredoc body is data"
compare "cat > f <<'EOF'
rm -rf $OUT"                                                    "unterminated heredoc"
compare "echo a\\>& rm -rf /etc/x"                              "escaped redirect then &"
compare "# rm -rf /etc/x"                                       "comment"
compare "\`rm -rf /etc/x\`"                                     "backtick"

# --- verb-set coverage ---
# Added after an anti-vacuity run showed that removing `shred` from the port's verb
# set was caught by NEITHER arm: the 87-case corpus instantiates only some of the 9
# destructive verbs, so the rest were pinned by nothing. One row per member, plus a
# case-folding probe, so the set cannot silently lose a member again.
for v in rm rmdir unlink Remove-Item del erase Clear-RecycleBin shred srm; do
    compare "$v /etc/harness-verb-probe"                        "verb: $v"
done
compare "RM -rf /etc/harness-verb-probe"                        "verb: RM (upper)"
compare "ReMoVe-ItEm /etc/harness-verb-probe"                   "verb: ReMoVe-ItEm (mixed)"
compare "SHRED /etc/harness-verb-probe"                         "verb: SHRED (upper)"

# --- carrier and interpreter coverage, same reasoning ---
for c in xargs env nohup nice time timeout command exec; do
    compare "$c rm -rf $OUT"                                    "carrier: $c"
done
for sh in bash sh dash zsh ksh; do
    compare "$sh -c \"rm -rf $OUT\""                            "interpreter: $sh"
done
compare "powershell -Command \"Remove-Item C:\\Windows\""       "interpreter: powershell"

echo
echo "  $((pass + fail)) raw cases: $pass identical, $fail divergent"

echo
echo "=== result ==="
if [ "$arm1" -eq 0 ] && [ "$fail" -eq 0 ]; then
    echo "  Both arms clean — the port matches the shell twin."
    exit 0
fi
echo "  DIVERGENT — do not cut over."
exit 1
