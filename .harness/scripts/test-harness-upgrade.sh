#!/usr/bin/env bash
# test-harness-upgrade.sh — Regression for the /harness-upgrade mechanical layer (T-012).
# Mirror of test-harness-upgrade.ps1. See that file for full doc.
#
# Drives upgrade-project.sh against synthetic "old-layout" fixtures (each its OWN temp
# dir — insight L22), then asserts the end state. --template-root = this repo root.
#
# Usage:
#   bash .harness/scripts/test-harness-upgrade.sh
#   bash .harness/scripts/test-harness-upgrade.sh --keep-temp

set -uo pipefail

# Script lives at .harness/scripts/ — repo root is two levels up.
repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
helper="$repo_root/.harness/scripts/upgrade-project.sh"

KEEP_TEMP=false
[[ "${1:-}" == "--keep-temp" ]] && KEEP_TEMP=true

pass=0
fail=0
failed=()
tmp_dirs=()

assert() {
    local name="$1" cond="$2"
    if [[ "$cond" == "0" ]]; then
        echo "  [PASS] $name"
        pass=$((pass + 1))
    else
        echo "  [FAIL] $name"
        fail=$((fail + 1))
        failed+=("$name")
    fi
}

# --- fixture builder. flags: customized=1 no_markers=1 custom_hook=1 -------------
new_old_fixture() {
    local label="$1" customized="${2:-0}" no_markers="${3:-0}" custom_hook="${4:-0}"
    local dir
    dir="$(mktemp -d -t "harness-upgrade-${label}-XXXXXX")"
    (
        cd "$dir" || exit 1
        git init -q
        git config user.email "t@example.com"
        git config user.name "test"
        mkdir -p scripts .claude

        cat > scripts/harness-sync.ps1 <<'EOF'
# old harness-sync.ps1 (pre-T-007). Repo root derived ONE level up (WRONG after relocation).
$repoRoot = Split-Path $PSScriptRoot -Parent
if (-not (Test-Path (Join-Path $repoRoot ".git"))) {
    Write-Error "harness-sync: wrong root $repoRoot"
    exit 3
}
Write-Host "ok root=$repoRoot"
exit 0
EOF
        printf '#!/bin/sh\nexit 0\n' > scripts/harness-sync.sh

        local inner
        if [[ "$no_markers" == "1" ]]; then
            if [[ "$customized" == "1" ]]; then
                printf '# old verify_all (no markers)\n# --- B. Build ---\nstep "B.1" "Build" "PASS"\ncargo build\n' > scripts/verify_all.ps1
            else
                printf '# old verify_all (no markers)\n# --- B. Build ---\nstep "B.1" "Build" "SKIP"\n' > scripts/verify_all.ps1
            fi
        else
            if [[ "$customized" == "1" ]]; then
                inner='# --- B. Build ---
step "B.1" "Build" "PASS"
cargo build --release'
            else
                inner='# --- B. Build ---
step "B.1" "Build" "SKIP"'
            fi
            {
                echo "# old verify_all (with markers)"
                echo "# >>> HARNESS:B-CUSTOM:BEGIN (your build/test/lint checks live here; preserved across /harness-upgrade) <<<"
                echo "$inner"
                echo "# >>> HARNESS:B-CUSTOM:END <<<"
            } > scripts/verify_all.ps1
        fi
        cp scripts/verify_all.ps1 scripts/verify_all.sh

        printf '# user script\n' > scripts/my-custom.ps1
        printf '{"test_count":0}' > scripts/baseline.json

        cat > .claude/settings.json <<'EOF'
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "hooks": {
    "Stop": [ { "hooks": [ { "type": "command", "command": "pwsh -NoProfile -File scripts/harness-sync.ps1" } ] } ],
    "PreToolUse": [ { "matcher": "Bash", "hooks": [ { "type": "command", "command": "pwsh -NoProfile -File scripts/guard-rm.ps1" } ] } ]
  }
}
EOF

        mkdir -p .git/hooks
        if [[ "$custom_hook" == "1" ]]; then
            printf '#!/bin/sh\n# MY OWN HOOK - do not touch\necho hi\n' > .git/hooks/pre-commit
        else
            cat > .git/hooks/pre-commit <<'EOF'
#!/bin/sh
# harness-kit pre-commit hook.
# Blocks the commit if .harness/ has drifted from CLAUDE.md or .github/copilot-instructions.md.
# Tool-agnostic: catches edits from Claude Code, Copilot, Cursor, or hand-typed.
set -e
_drift=0
if command -v pwsh >/dev/null 2>&1 && [ -f scripts/harness-sync.ps1 ]; then
    pwsh -File scripts/harness-sync.ps1 -Check >/dev/null 2>&1 || _drift=1
elif command -v bash >/dev/null 2>&1 && [ -f scripts/harness-sync.sh ]; then
    bash scripts/harness-sync.sh --check >/dev/null 2>&1 || _drift=1
else
    echo "harness-kit pre-commit: neither pwsh nor bash found; skipping drift check." >&2
    exit 0
fi
if [ "$_drift" = "1" ]; then
    echo "" >&2
    echo "harness-kit: drift between .harness/ and .claude/." >&2
    echo "  .claude/agents/ and/or .claude/skills/ are stale relative to .harness/." >&2
    echo "" >&2
    echo "  Fix: pwsh -File .harness/scripts/harness-sync.ps1   (Windows)" >&2
    echo "       bash .harness/scripts/harness-sync.sh          (macOS / Linux)" >&2
    echo "  Then: git add .claude/ && git commit ..." >&2
    echo "" >&2
    echo "  Note: edits to .harness/rules/ do NOT need sync (referenced by AI-GUIDE.md, not composed)." >&2
    echo "  Bypass once (NOT recommended): git commit --no-verify" >&2
    exit 1
fi
EOF
        fi

        git add -A >/dev/null 2>&1
        git commit -q -m "old fixture" >/dev/null 2>&1
    )
    echo "$dir"
}

# Runs the helper from $1 with extra args $2.., captures combined output + code.
RUN_OUT=""
RUN_CODE=0
invoke_upgrade() {
    local dir="$1"; shift
    RUN_OUT="$(cd "$dir" && bash "$helper" --type generic --stack "Rust CLI" --template-root "$repo_root" --today 2026-06-08 "$@" 2>&1)"
    RUN_CODE=$?
}

contains() { case "$2" in *"$1"*) return 0 ;; *) return 1 ;; esac; }

cleanup() {
    if [[ "$KEEP_TEMP" == false ]]; then
        for d in "${tmp_dirs[@]}"; do [[ -d "$d" ]] && rm -rf "$d"; done
    else
        echo "Kept temp dirs:"
        for d in "${tmp_dirs[@]}"; do echo "  $d"; done
    fi
}
trap cleanup EXIT

echo "=== test-harness-upgrade (bash) ==="

# --- Fixture A: old-baseline real upgrade (AC-1..AC-5, AC-9) ---
echo ""
echo "--- Fixture A: old-baseline real upgrade ---"
a="$(new_old_fixture baseline)"; tmp_dirs+=("$a")
invoke_upgrade "$a"
assert "A: helper exits 0" "$([[ "$RUN_CODE" -eq 0 ]] && echo 0 || echo 1)"
assert "A: harness-sync.ps1 relocated to .harness/scripts/" "$([[ -f "$a/.harness/scripts/harness-sync.ps1" ]] && echo 0 || echo 1)"
assert "A: harness-sync.ps1 removed from scripts/" "$([[ ! -f "$a/scripts/harness-sync.ps1" ]] && echo 0 || echo 1)"
assert "A: custom scripts/my-custom.ps1 untouched (AC-1)" "$([[ -f "$a/scripts/my-custom.ps1" ]] && echo 0 || echo 1)"
relocated="$(cat "$a/.harness/scripts/harness-sync.ps1")"
assert "A: relocated harness-sync.ps1 is two-up (content-refreshed, AC-5)" "$(contains 'two levels up' "$relocated" && echo 0 || echo 1)"
assert "A: relocated harness-sync.ps1 no longer carries one-up WRONG marker" "$(contains 'wrong root' "$relocated" && echo 1 || echo 0)"
# AC-5 runtime — invoke the relocated bash harness-sync from project root, must find root.
( cd "$a" && bash "$a/.harness/scripts/harness-sync.sh" --check >/dev/null 2>&1 ); sync_code=$?
assert "A: relocated harness-sync runs from project root and finds repo root (AC-5 runtime)" "$([[ "$sync_code" -eq 0 ]] && echo 0 || echo 1)"
set_content="$(cat "$a/.claude/settings.json")"
assert "A: settings rewired to .harness/scripts/ (AC-3)" "$(contains '.harness/scripts/harness-sync.' "$set_content" && echo 0 || echo 1)"
# Negative: no bare `-File scripts/harness-sync` (the unambiguous old command form);
# the rewired `.harness/scripts/harness-sync` is fine (it embeds "scripts/harness-sync").
assert "A: settings no longer references bare scripts/harness-sync (AC-3)" "$(contains '-File scripts/harness-sync' "$set_content" && echo 1 || echo 0)"
# JSON parse: prefer real python3 (NOT the Windows Store stub, which prints a "Python
# was not found" notice and exits non-zero — insight L27 family); else node; else skip.
real_python=""
if command -v python3 >/dev/null 2>&1 && python3 -c 'print(1)' >/dev/null 2>&1; then real_python="python3"
elif command -v python >/dev/null 2>&1 && python -c 'print(1)' >/dev/null 2>&1; then real_python="python"; fi
if [[ -n "$real_python" ]]; then
    ( echo "$set_content" | "$real_python" -c 'import json,sys; json.load(sys.stdin)' >/dev/null 2>&1 ); json_ok=$?
    assert "A: settings still parses as JSON (AC-3)" "$([[ "$json_ok" -eq 0 ]] && echo 0 || echo 1)"
elif command -v node >/dev/null 2>&1; then
    ( echo "$set_content" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{JSON.parse(s)})' >/dev/null 2>&1 ); json_ok=$?
    assert "A: settings still parses as JSON (AC-3)" "$([[ "$json_ok" -eq 0 ]] && echo 0 || echo 1)"
else
    assert "A: settings still parses as JSON (AC-3, no JSON parser — SKIPPED)" "0"
fi
hook_content="$(cat "$a/.git/hooks/pre-commit")"
assert "A: pre-commit hook references .harness/scripts/harness-sync (AC-2)" "$(contains '.harness/scripts/harness-sync.' "$hook_content" && echo 0 || echo 1)"
va_content="$(cat "$a/.harness/scripts/verify_all.sh")"
assert "A: verify_all.sh regenerated with current E.* check (AC-4)" "$(contains 'agents in .harness/agents' "$va_content" && echo 0 || echo 1)"
assert "A: verify_all.sh has no unsubstituted {{...}} (AC-4)" "$(echo "$va_content" | grep -qE '\{\{[A-Za-z_]+\}\}' && echo 1 || echo 0)"
assert "A: migrate-scripts-layout.sh present after upgrade (AC-9)" "$([[ -f "$a/.harness/scripts/migrate-scripts-layout.sh" ]] && echo 0 || echo 1)"
assert "A: upgrade SUMMARY line emitted" "$(contains 'SUMMARY|added=' "$RUN_OUT" && echo 0 || echo 1)"

# --- Fixture A re-run: idempotence (AC-6) ---
echo ""
echo "--- Fixture A re-run: idempotence ---"
invoke_upgrade "$a"
assert "A2: 2nd run exits 0 (AC-6)" "$([[ "$RUN_CODE" -eq 0 ]] && echo 0 || echo 1)"
assert "A2: 2nd run reports NOOP for verify_all (AC-6)" "$(contains 'NOOP|verify_all' "$RUN_OUT" && echo 0 || echo 1)"

# --- Fixture B: dry-run leaves fixture unchanged (AC-7) ---
echo ""
echo "--- Fixture B: dry-run ---"
b="$(new_old_fixture dryrun)"; tmp_dirs+=("$b")
before="$(cd "$b" && git status --porcelain)"
invoke_upgrade "$b" --dry-run
assert "B: dry-run exits 0 (AC-7)" "$([[ "$RUN_CODE" -eq 0 ]] && echo 0 || echo 1)"
assert "B: dry-run prints PLAN lines (AC-7)" "$(contains 'PLAN|MOVE' "$RUN_OUT" && echo 0 || echo 1)"
assert "B: dry-run leaves scripts/harness-sync.ps1 in place (AC-7)" "$([[ -f "$b/scripts/harness-sync.ps1" ]] && echo 0 || echo 1)"
assert "B: dry-run did not create .harness/scripts/harness-sync.ps1 (AC-7)" "$([[ ! -f "$b/.harness/scripts/harness-sync.ps1" ]] && echo 0 || echo 1)"
after="$(cd "$b" && git status --porcelain)"
assert "B: dry-run made no git-visible change (AC-7)" "$([[ "$before" == "$after" ]] && echo 0 || echo 1)"

# --- Fixture C: custom (non-stock) hook surfaced as conflict (BC-7) ---
echo ""
echo "--- Fixture C: custom hook conflict ---"
c="$(new_old_fixture customhook 0 0 1)"; tmp_dirs+=("$c")
invoke_upgrade "$c"
assert "C: helper exits 3 on non-stock hook (BC-7)" "$([[ "$RUN_CODE" -eq 3 ]] && echo 0 || echo 1)"
assert "C: CONFLICT|hook surfaced (BC-7)" "$(contains 'CONFLICT|hook' "$RUN_OUT" && echo 0 || echo 1)"
assert "C: custom hook NOT overwritten (BC-7)" "$(contains 'MY OWN HOOK' "$(cat "$c/.git/hooks/pre-commit")" && echo 0 || echo 1)"

# --- Fixture D: marker-customized verify_all is SPLICE-preserved (AC-13 merge) ---
echo ""
echo "--- Fixture D: B.* splice preserve ---"
d="$(new_old_fixture splice 1)"; tmp_dirs+=("$d")
invoke_upgrade "$d"
assert "D: helper exits 0 (splice path)" "$([[ "$RUN_CODE" -eq 0 ]] && echo 0 || echo 1)"
assert "D: VERIFY-SPLICE emitted (AC-13 merge)" "$(contains 'VERIFY-SPLICE' "$RUN_OUT" && echo 0 || echo 1)"
d_va="$(cat "$d/.harness/scripts/verify_all.sh")"
assert "D: spliced verify_all retains user cargo build check (AC-13 merge)" "$(contains 'cargo build --release' "$d_va" && echo 0 || echo 1)"
assert "D: spliced verify_all also has current E.* structure (regen body)" "$(contains 'agents in .harness/agents' "$d_va" && echo 0 || echo 1)"

# --- Fixture E: no-marker customized verify_all HALTs (AC-13 regenerate-warn) ---
echo ""
echo "--- Fixture E: B.* halt (no markers + custom) ---"
e="$(new_old_fixture halt 1 1)"; tmp_dirs+=("$e")
invoke_upgrade "$e"
assert "E: helper exits 2 (refresh-blocked, AC-13 warn branch)" "$([[ "$RUN_CODE" -eq 2 ]] && echo 0 || echo 1)"
assert "E: VERIFY-HALT emitted" "$(contains 'VERIFY-HALT' "$RUN_OUT" && echo 0 || echo 1)"
invoke_upgrade "$e" --force
assert "E: --force completes the upgrade (exit 0)" "$([[ "$RUN_CODE" -eq 0 ]] && echo 0 || echo 1)"
assert "E: --force wrote verify_all (REGEN)" "$([[ -f "$e/.harness/scripts/verify_all.sh" ]] && echo 0 || echo 1)"

# --- Fixture F: non-Claude-Code project (no .claude/settings.json) (BC-15 / OQ-9) ---
echo ""
echo "--- Fixture F: non-CC project (no settings) ---"
f="$(new_old_fixture noncc)"; tmp_dirs+=("$f")
rm -f "$f/.claude/settings.json"
invoke_upgrade "$f"
assert "F: helper exits 0 without settings (BC-15)" "$([[ "$RUN_CODE" -eq 0 ]] && echo 0 || echo 1)"
assert "F: settings rewire SKIPPED with note (OQ-9)" "$(contains 'SKIP|.claude/settings.json absent' "$RUN_OUT" && echo 0 || echo 1)"
assert "F: scripts still relocated without settings" "$([[ -f "$f/.harness/scripts/harness-sync.ps1" ]] && echo 0 || echo 1)"

# --- Fixture G: no-harness bare repo halts (BC-2 / AC-11) ---
echo ""
echo "--- Fixture G: no-harness halt ---"
g="$(mktemp -d -t "harness-upgrade-noharness-XXXXXX")"; tmp_dirs+=("$g")
( cd "$g" && git init -q )
invoke_upgrade "$g"
assert "G: bare git repo (no harness) exits 1 (BC-2/AC-11)" "$([[ "$RUN_CODE" -eq 1 ]] && echo 0 || echo 1)"

echo ""
echo "=== Summary ==="
echo "  PASS: $pass"
echo "  FAIL: $fail"
if (( fail > 0 )); then
    echo "  Failed:"
    for f in "${failed[@]}"; do echo "    - $f"; done
    exit 1
fi
exit 0
