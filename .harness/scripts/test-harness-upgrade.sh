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
# T-12 / A8 proof: the rewritten command is the RESILIENT form (carries the
# $CLAUDE_PROJECT_DIR anchor), not the bare brittle `-File .harness/scripts/...`.
assert "A: settings rewritten to the resilient form (CLAUDE_PROJECT_DIR-anchored, AC-8)" "$(contains 'CLAUDE_PROJECT_DIR' "$set_content" && echo 0 || echo 1)"
# T-12 / A5 proof: guard-rm (PreToolUse) is resilient-anchored too but fail-CLOSED —
# its resilient form has NO `exit 0` fallback (the convenience Stop form does).
assert "A: guard-rm resilient form is fail-CLOSED (no exit 0 in its command)" \
    "$(printf '%s\n' "$set_content" | grep -F 'guard-rm.ps1' | grep -qF 'exit 0' && echo 1 || echo 0)"
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
assert "A: verify_all.sh regenerated with current E.* check (AC-4)" "$(contains 'partition dev-* only' "$va_content" && echo 0 || echo 1)"
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
assert "D: spliced verify_all also has current E.* structure (regen body)" "$(contains 'partition dev-* only' "$d_va" && echo 0 || echo 1)"

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

# ============================ T-020 fixtures ======================================
# Token pieces: assembled so this driver source carries no literal {{NAME}} token
# (insight 2026-06-08). Used by fixtures P / P2 and the no-token-left assertions.
t20_o="{{"
t20_c="}}"
t20_tok="${t20_o}SYNC_COMMAND${t20_c}"
# T-12: the OS-picked SYNC command is now the RESILIENT (fail-open + $CLAUDE_PROJECT_DIR-
# anchored) form. t20_pick holds the JSON-ESCAPED bytes (inner " as \") so the exact
# `"command": "<t20_pick>"` grep matches the raw on-disk settings byte-for-byte (gate C3).
# t20_run is the same command in shell-runnable form (un-escaped) for the `eval` real-run
# probe; CLAUDE_PROJECT_DIR is set to the fixture root there so the anchor resolves and the
# script actually runs (gate C5 / F4) instead of exiting 0 via the fail-open empty-var path.
case "${OSTYPE:-}" in
    msys*|cygwin*|win32)
        t20_pick='pwsh -NoProfile -Command \"Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR -EA SilentlyContinue; if (Test-Path -LiteralPath .harness/scripts/harness-sync.ps1 -PathType Leaf) { & pwsh -NoProfile -File .harness/scripts/harness-sync.ps1 }; exit 0\"'
        # Real-run probe (gate C5): the WIRED resilient string embeds pwsh's `$env:` which
        # bash `eval` would mangle (under `set -u`, `$env` is an unbound bash var). So run
        # a bash-safe equivalent that anchors to the project root the same way the resilient
        # command does (cd to $CLAUDE_PROJECT_DIR, presence-gate, invoke the inner script
        # with the SAME `-NoProfile -File` it uses) — this genuinely exercises the script
        # run, not the fail-open empty-var path.
        t20_run='cd "$CLAUDE_PROJECT_DIR" 2>/dev/null && [ -f .harness/scripts/harness-sync.ps1 ] && pwsh -NoProfile -File .harness/scripts/harness-sync.ps1 || exit 0'
        ;;
    *)
        t20_pick="sh -c 'cd \\\"\$CLAUDE_PROJECT_DIR\\\" 2>/dev/null && [ -f .harness/scripts/harness-sync.sh ] && exec bash .harness/scripts/harness-sync.sh || exit 0'"
        t20_run='cd "$CLAUDE_PROJECT_DIR" 2>/dev/null && [ -f .harness/scripts/harness-sync.sh ] && bash .harness/scripts/harness-sync.sh || exit 0'
        ;;
esac

# Minimal fixture: settings-only project (no scripts/ dir), Stop hook pre-wired to
# the NEW path whose file does not exist anywhere — the user's reported state.
new_dangling_fixture() {
    local label="$1" stop_cmd="$2"
    local dir
    dir="$(mktemp -d -t "harness-upgrade-${label}-XXXXXX")"
    (
        cd "$dir" || exit 1
        git init -q
        git config user.email "t@example.com"
        git config user.name "test"
        mkdir -p .claude build-scripts
        printf '#!/bin/sh\necho deploy\nexit 0\n' > build-scripts/deploy.sh
        cat > .claude/settings.json <<EOF
{
  "\$schema": "https://json.schemastore.org/claude-code-settings.json",
  "_doc_sync_hook": "Stop hook runs harness-sync.",
  "hooks": {
    "Stop": [ { "hooks": [ { "type": "command", "command": "$stop_cmd" } ] } ],
    "UserPromptSubmit": [ { "hooks": [ { "type": "command", "command": "bash build-scripts/deploy.sh" } ] } ]
  }
}
EOF
        git add -A >/dev/null 2>&1
        git commit -q -m "dangling fixture" >/dev/null 2>&1
    )
    echo "$dir"
}

# Crafted template root whose common/scripts LACKS harness-sync.* (fixtures I / P2).
crafted="$(mktemp -d -t "harness-upgrade-crafted-XXXXXX")"; tmp_dirs+=("$crafted")
mkdir -p "$crafted/skills/harness-init/templates"
cp -r "$repo_root/skills/harness-init/templates/common"  "$crafted/skills/harness-init/templates/common"
cp -r "$repo_root/skills/harness-init/templates/generic" "$crafted/skills/harness-init/templates/generic"
rm -f "$crafted/skills/harness-init/templates/common/.harness/scripts/harness-sync.ps1" \
      "$crafted/skills/harness-init/templates/common/.harness/scripts/harness-sync.sh"

# --- Fixture H (design §10 "Fixture G"): dangling repair (AC-2 / FR-R1 / FR-R2) ---
echo ""
echo "--- Fixture H: dangling-hook repair + C1 custom-hook false-positive guard ---"
h="$(new_dangling_fixture dangling "bash .harness/scripts/harness-sync.sh")"; tmp_dirs+=("$h")
invoke_upgrade "$h"
assert "H: helper exits 0 (repair completes, AC-2)" "$([[ "$RUN_CODE" -eq 0 ]] && echo 0 || echo 1)"
assert "H: wired target .harness/scripts/harness-sync.sh exists after repair (AC-2)" "$([[ -f "$h/.harness/scripts/harness-sync.sh" ]] && echo 0 || echo 1)"
( cd "$h" && bash .harness/scripts/harness-sync.sh >/dev/null 2>&1 ); h_sync_code=$?
assert "H: invoking the wired command from project root exits 0 (AC-2 runtime)" "$([[ "$h_sync_code" -eq 0 ]] && echo 0 || echo 1)"
# T-12 / A8 proof: the dangling bare `bash .harness/scripts/harness-sync.sh` is repaired
# to the RESILIENT form (fail-open + $CLAUDE_PROJECT_DIR-anchored), not left brittle.
h_set="$(cat "$h/.claude/settings.json")"
assert "H: repaired Stop command is the resilient form (CLAUDE_PROJECT_DIR-anchored, AC-8)" "$(contains 'CLAUDE_PROJECT_DIR' "$h_set" && echo 0 || echo 1)"
assert "H: repaired Stop command is fail-OPEN (carries the convenience exit 0 terminator)" "$(contains '|| exit 0' "$h_set" && echo 0 || echo 1)"
# Real-run probe (gate C5 / F4): anchor to the project root the same way the resilient
# command does (cd to $CLAUDE_PROJECT_DIR, presence-gate, invoke the inner script) so the
# script actually runs, instead of the fail-open empty-var path. bash-safe equivalent (the
# wired string's pwsh `$env:` would be mangled by bash eval under `set -u`).
h_run='cd "$CLAUDE_PROJECT_DIR" 2>/dev/null && [ -f .harness/scripts/harness-sync.sh ] && bash .harness/scripts/harness-sync.sh || exit 0'
( cd "$h" && CLAUDE_PROJECT_DIR="$h" eval "$h_run" >/dev/null 2>&1 ); h_wired_code=$?
assert "H: invoking the wired RESILIENT command (anchored) exits 0 (AC-2 runtime)" "$([[ "$h_wired_code" -eq 0 ]] && echo 0 || echo 1)"
assert "H: no CONFLICT|congruence in output (end state congruent)" "$(contains 'CONFLICT|congruence' "$RUN_OUT" && echo 1 || echo 0)"
assert "H: [C1] custom build-scripts/deploy.sh hook NOT flagged (left-bounded ERE)" "$(contains 'build-scripts' "$RUN_OUT" && echo 1 || echo 0)"
h_set_before="$(cat "$h/.claude/settings.json")"
h_bak_before=$(ls "$h/.claude/"settings.json.bak-* 2>/dev/null | wc -l)
invoke_upgrade "$h"
assert "H2: re-run exits 0 (FR-R2 idempotent)" "$([[ "$RUN_CODE" -eq 0 ]] && echo 0 || echo 1)"
h_bak_after=$(ls "$h/.claude/"settings.json.bak-* 2>/dev/null | wc -l)
assert "H2: re-run wrote no new settings .bak (FR-R2)" "$([[ "$h_bak_before" == "$h_bak_after" ]] && echo 0 || echo 1)"
assert "H2: settings byte-identical after re-run (FR-R2)" "$([[ "$h_set_before" == "$(cat "$h/.claude/settings.json")" ]] && echo 0 || echo 1)"

# --- Fixture I (design §10 "Fixture H"): incongruent end state (FR-P3) -----------
echo ""
echo "--- Fixture I: incongruent end state (template + project both lack the script) ---"
i_fix="$(mktemp -d -t "harness-upgrade-incongruent-XXXXXX")"; tmp_dirs+=("$i_fix")
(
    cd "$i_fix" || exit 1
    git init -q
    git config user.email "t@example.com"
    git config user.name "test"
    mkdir -p .claude
    cat > .claude/settings.json <<'EOF'
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "hooks": {
    "Stop": [ { "hooks": [ { "type": "command", "command": "pwsh -NoProfile -File scripts/harness-sync.ps1" } ] } ]
  }
}
EOF
    git add -A >/dev/null 2>&1
    git commit -q -m "incongruent fixture" >/dev/null 2>&1
)
RUN_OUT="$(cd "$i_fix" && bash "$helper" --type generic --stack "Rust CLI" --template-root "$crafted" --today 2026-06-08 2>&1)"
RUN_CODE=$?
assert "I: GAP|template-missing emitted for harness-sync (FR-P3)" "$(contains 'GAP|template-missing|absent|.harness/scripts/harness-sync.' "$RUN_OUT" && echo 0 || echo 1)"
assert "I: CONFLICT|congruence names the missing path (FR-P3)" "$(contains 'CONFLICT|congruence' "$RUN_OUT" && contains 'missing scripts/harness-sync.ps1' "$RUN_OUT" && echo 0 || echo 1)"
assert "I: helper exits 4 (congruence failure wins)" "$([[ "$RUN_CODE" -eq 4 ]] && echo 0 || echo 1)"
i_set="$(cat "$i_fix/.claude/settings.json")"
assert "I: settings still references the LEGACY path (no dangling rewire)" "$(contains '-File scripts/harness-sync.ps1' "$i_set" && echo 0 || echo 1)"
assert "I: settings NOT rewired to .harness/scripts/harness-sync.ps1" "$(contains '-File .harness/scripts/harness-sync.ps1' "$i_set" && echo 1 || echo 0)"

# --- Fixture P: B7 literal-placeholder repair (gate C3 / AC-9) --------------------
echo ""
echo "--- Fixture P: literal-placeholder repair (B7 / gate C3) ---"
p_fix="$(new_dangling_fixture placeholder "$t20_tok")"; tmp_dirs+=("$p_fix")
invoke_upgrade "$p_fix" --dry-run
assert "P: dry-run plans the placeholder repair (PLAN|REWIRE-PLACEHOLDER)" "$(contains 'PLAN|REWIRE-PLACEHOLDER' "$RUN_OUT" && contains 'SYNC_COMMAND' "$RUN_OUT" && echo 0 || echo 1)"
assert "P: dry-run leaves the token in place (B9)" "$(contains "$t20_tok" "$(cat "$p_fix/.claude/settings.json")" && echo 0 || echo 1)"
assert "P: dry-run exits 0 (projected state congruent)" "$([[ "$RUN_CODE" -eq 0 ]] && echo 0 || echo 1)"
invoke_upgrade "$p_fix"
assert "P: apply emits RESULT|REWIRE-PLACEHOLDER (AC-9)" "$(contains 'RESULT|REWIRE-PLACEHOLDER' "$RUN_OUT" && echo 0 || echo 1)"
assert "P: apply exits 0 (AC-9)" "$([[ "$RUN_CODE" -eq 0 ]] && echo 0 || echo 1)"
p_set="$(cat "$p_fix/.claude/settings.json")"
assert "P: wired command equals the OS-picked variant (AC-9)" "$(contains "\"command\": \"$t20_pick\"" "$p_set" && echo 0 || echo 1)"
assert "P: no assembled token opener remains in settings (AC-9)" "$(contains "$t20_o" "$p_set" && echo 1 || echo 0)"
# T-12: the resilient string no longer ends in the script path (it ends in `0\"` / `0'`),
# so extract the .harness/scripts/<name>.<ext> token via the same left-bounded ERE the
# congruence scans use, not "last space-token".
p_target="$(printf '%s\n' "$t20_pick" \
    | grep -oE "(^|[\"' =])(\.harness/)?scripts/[A-Za-z0-9._-]+\.(ps1|sh)" \
    | sed -E "s|^[\"' =]||" | head -1)"
assert "P: the picked command's target file exists (AC-9)" "$([[ -f "$p_fix/$p_target" ]] && echo 0 || echo 1)"
# Exercise the REAL run path (gate C5 / F4): set CLAUDE_PROJECT_DIR so the resilient
# anchor resolves to the fixture root and the script actually runs, instead of exiting 0
# via the fail-open empty-var branch. Use the shell-runnable t20_run (not the JSON-escaped
# t20_pick). The harness-sync.sh that just landed exits 0 -> the wired command exits 0.
( cd "$p_fix" && CLAUDE_PROJECT_DIR="$p_fix" eval "$t20_run" >/dev/null 2>&1 ); p_run_code=$?
assert "P: invoking the repaired wired command from project root exits 0 (AC-9)" "$([[ "$p_run_code" -eq 0 ]] && echo 0 || echo 1)"
p_bak_count=$(ls "$p_fix/.claude/"settings.json.bak-* 2>/dev/null | wc -l)
assert "P: exactly one settings .bak written by the repair (FR-R3)" "$([[ "$p_bak_count" -eq 1 ]] && echo 0 || echo 1)"
assert "P: _doc_sync_hook doc key preserved (raw-text edit, AC-6)" "$(contains '_doc_sync_hook' "$p_set" && echo 0 || echo 1)"
assert "P: \$schema canonical after repair (AC-6)" "$(contains 'json.schemastore.org/claude-code-settings.json' "$p_set" && echo 0 || echo 1)"
invoke_upgrade "$p_fix"
assert "P2nd: re-run exits 0 and is a settings NOOP (B10)" "$([[ "$RUN_CODE" -eq 0 ]] && contains 'NOOP|.claude/settings.json' "$RUN_OUT" && echo 0 || echo 1)"
p_bak_count2=$(ls "$p_fix/.claude/"settings.json.bak-* 2>/dev/null | wc -l)
assert "P2nd: no new .bak on re-run (B10)" "$([[ "$p_bak_count" == "$p_bak_count2" ]] && echo 0 || echo 1)"
assert "P2nd: settings byte-identical after re-run (B10)" "$([[ "$p_set" == "$(cat "$p_fix/.claude/settings.json")" ]] && echo 0 || echo 1)"

# --- Fixture P2: gated-off placeholder creates no new dangle (§6.2.5 gate) --------
echo ""
echo "--- Fixture P2: gated-off placeholder (template cannot land the target) ---"
p2_fix="$(new_dangling_fixture placeholder2 "$t20_tok")"; tmp_dirs+=("$p2_fix")
RUN_OUT="$(cd "$p2_fix" && bash "$helper" --type generic --stack "Rust CLI" --template-root "$crafted" --today 2026-06-08 2>&1)"
RUN_CODE=$?
assert "P2: token NOT substituted when the gate is off (no new dangle)" "$(contains "$t20_tok" "$(cat "$p2_fix/.claude/settings.json")" && echo 0 || echo 1)"
assert "P2: no REWIRE-PLACEHOLDER emitted" "$(contains 'REWIRE-PLACEHOLDER' "$RUN_OUT" && echo 1 || echo 0)"
assert "P2: terminal scan flags the unresolved token (CONFLICT|congruence)" "$(contains 'CONFLICT|congruence' "$RUN_OUT" && contains 'unresolved placeholder token' "$RUN_OUT" && echo 0 || echo 1)"
assert "P2: helper exits 4" "$([[ "$RUN_CODE" -eq 4 ]] && echo 0 || echo 1)"

# --- Fixtures M1 / M2: migrate-scripts-layout RC-1 + healthy (AC-1 / B10) ---------
echo ""
echo "--- Fixture M1: migrate with missing source (RC-1 / AC-1) ---"
migrate_helper="$repo_root/.harness/scripts/migrate-scripts-layout.sh"
new_prereloc_fixture() {
    # $1=label  $2=with_sync (1 = scripts/harness-sync.* present)
    local label="$1" with_sync="$2"
    local dir
    dir="$(mktemp -d -t "harness-migrate-${label}-XXXXXX")"
    (
        cd "$dir" || exit 1
        git init -q
        git config user.email "t@example.com"
        git config user.name "test"
        mkdir -p scripts .claude
        printf '# vfa\n' > scripts/verify_all.ps1
        printf '# vfa\n' > scripts/verify_all.sh
        printf '# guard\n' > scripts/guard-rm.ps1
        printf '# guard\n' > scripts/guard-rm.sh
        if [[ "$with_sync" == "1" ]]; then
            printf '# sync\n' > scripts/harness-sync.ps1
            printf '# sync\n' > scripts/harness-sync.sh
        fi
        cat > .claude/settings.json <<'EOF'
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "hooks": {
    "Stop": [ { "hooks": [ { "type": "command", "command": "pwsh -NoProfile -File scripts/harness-sync.ps1" } ] } ],
    "PreToolUse": [ { "matcher": "Bash", "hooks": [ { "type": "command", "command": "pwsh -NoProfile -File scripts/guard-rm.ps1" } ] } ]
  }
}
EOF
        git add -A >/dev/null 2>&1
        git commit -q -m "pre-relocation fixture" >/dev/null 2>&1
    )
    echo "$dir"
}
m1="$(new_prereloc_fixture rc1 0)"; tmp_dirs+=("$m1")
m1_out="$(cd "$m1" && bash "$migrate_helper" 2>&1)"; m1_code=$?
assert "M1: migrate exits 4 (RC-1 made loud, AC-1)" "$([[ "$m1_code" -eq 4 ]] && echo 0 || echo 1)"
assert "M1: CONGRUENCE-FAIL names the missing path (AC-1)" "$(contains 'CONGRUENCE-FAIL' "$m1_out" && contains 'missing scripts/harness-sync.ps1' "$m1_out" && echo 0 || echo 1)"
m1_set="$(cat "$m1/.claude/settings.json")"
assert "M1: settings NOT rewired to a dangling .harness path (AC-1)" "$(contains '-File .harness/scripts/harness-sync.ps1' "$m1_set" && echo 1 || echo 0)"
assert "M1: present variant guard-rm still rewired (gated per variant)" "$(contains '-File .harness/scripts/guard-rm.ps1' "$m1_set" && echo 0 || echo 1)"

echo ""
echo "--- Fixture M2: healthy migrate unchanged (B10) ---"
m2="$(new_prereloc_fixture healthy 1)"; tmp_dirs+=("$m2")
m2_out="$(cd "$m2" && bash "$migrate_helper" 2>&1)"; m2_code=$?
assert "M2: healthy migrate exits 0" "$([[ "$m2_code" -eq 0 ]] && echo 0 || echo 1)"
m2_set="$(cat "$m2/.claude/settings.json")"
assert "M2: settings rewired to .harness/scripts/harness-sync.ps1" "$(contains '-File .harness/scripts/harness-sync.ps1' "$m2_set" && echo 0 || echo 1)"
# T-12 / A8: migrate also resilient-ifies the brittle command (CLAUDE_PROJECT_DIR anchor).
assert "M2: migrated command is the resilient form (CLAUDE_PROJECT_DIR-anchored, A8)" "$(contains 'CLAUDE_PROJECT_DIR' "$m2_set" && echo 0 || echo 1)"
m2_bak_before=$(ls "$m2/.claude/"settings.json.bak-* 2>/dev/null | wc -l)
m2_out2="$(cd "$m2" && bash "$migrate_helper" 2>&1)"; m2_code2=$?
m2_bak_after=$(ls "$m2/.claude/"settings.json.bak-* 2>/dev/null | wc -l)
assert "M2: second run exits 0 and writes no new .bak (B10)" "$([[ "$m2_code2" -eq 0 && "$m2_bak_before" == "$m2_bak_after" ]] && echo 0 || echo 1)"

# --- Fixture M3: failed settings write is loud (B8 write-failure half) ------------
# The moves succeed but the settings write hits a read-only file: the terminal scan
# re-reads DISK (not the in-memory rewired text), finds the legacy paths whose targets
# just moved away, and exits 4 — the pre-rework code validated the never-landed
# in-memory text and exited 0 silently dangling.
echo ""
echo "--- Fixture M3: read-only settings -> write failure is loud (B8) ---"
m3="$(new_prereloc_fixture writefail 1)"; tmp_dirs+=("$m3")
chmod a-w "$m3/.claude/settings.json"
# Precondition probe: environments that ignore the write bit (e.g. root on POSIX)
# cannot simulate the failed write — self-disable instead of shipping a flaky probe.
if (printf '' >> "$m3/.claude/settings.json") 2>/dev/null; then
    echo "  [SKIP] M3: read-only settings.json not enforceable here (root?) — write-failure probe skipped"
else
    m3_out="$(cd "$m3" && bash "$migrate_helper" 2>&1)"; m3_code=$?
    assert "M3: failed settings write exits 4, not silent 0 (B8)" "$([[ "$m3_code" -eq 4 ]] && echo 0 || echo 1)"
    assert "M3: CONGRUENCE-FAIL names the still-legacy on-disk path (B8)" "$(contains 'CONGRUENCE-FAIL' "$m3_out" && contains 'missing scripts/harness-sync.ps1' "$m3_out" && echo 0 || echo 1)"
    assert "M3: failed write left settings untouched on disk" "$(contains '-File scripts/harness-sync.ps1' "$(cat "$m3/.claude/settings.json")" && echo 0 || echo 1)"
fi
chmod u+w "$m3/.claude/settings.json" 2>/dev/null || true

# --- Fixture Z: AC-5 RUNTIME fail-closed mutation probe (T-12) ---------------------
# The fail-CLOSED safety invariant was previously only STRUCTURAL (asserting the guard
# command string carries no `exit 0`). This is the codified RUNTIME mutation the code
# review asked for: build the resilient guard command, attempt a genuinely destructive
# call, and assert the guard BLOCKS it when present — then DELETE guard-rm and assert
# the same command exits NON-zero (never a silent allow). guard-rm convenience hooks may
# fail open; the safety hook may not. A regression here is a release blocker.
echo ""
echo "--- Fixture Z: AC-5 runtime fail-closed mutation probe (T-12) ---"
z_guard_src="$repo_root/.harness/scripts/guard-rm.sh"
if [[ ! -f "$z_guard_src" ]]; then
    echo "  [SKIP] Z: guard-rm.sh not found in repo — runtime probe skipped"
else
    z="$(mktemp -d -t "harness-upgrade-ac5-XXXXXX")"; tmp_dirs+=("$z")
    mkdir -p "$z/.harness/scripts"
    ( cd "$z" && git init -q )   # guard needs a .git ancestor to be active
    cp "$z_guard_src" "$z/.harness/scripts/guard-rm.sh"
    # The resilient bash guard command, transcribed from design §3.4 (fail-CLOSED: no exit 0).
    z_guard_cmd='sh -c '\''cd "$CLAUDE_PROJECT_DIR" 2>/dev/null && bash .harness/scripts/guard-rm.sh'\'''
    z_destructive='{"tool_input":{"command":"rm -rf /etc/harness-ac5-outside-target"}}'
    z_benign='{"tool_input":{"command":"ls -la"}}'

    # Z1: guard PRESENT -> destructive call is BLOCKED (non-zero).
    ( export CLAUDE_PROJECT_DIR="$z"; cd "$z"; printf '%s' "$z_destructive" | eval "$z_guard_cmd" ) >/dev/null 2>&1
    z1_rc=$?
    assert "Z1: guard PRESENT blocks a destructive out-of-repo rm (rc!=0)" "$([[ "$z1_rc" -ne 0 ]] && echo 0 || echo 1)"

    # Z1b: sanity — a benign call is ALLOWED (rc=0), proving the guard is not blanket-blocking.
    ( export CLAUDE_PROJECT_DIR="$z"; cd "$z"; printf '%s' "$z_benign" | eval "$z_guard_cmd" ) >/dev/null 2>&1
    z1b_rc=$?
    assert "Z1b: guard PRESENT allows a benign command (rc=0, guard genuinely ran)" "$([[ "$z1b_rc" -eq 0 ]] && echo 0 || echo 1)"

    # Z2: MUTATE — delete guard-rm.sh -> the same command must exit NON-zero (fail-CLOSED).
    rm -f "$z/.harness/scripts/guard-rm.sh"
    ( export CLAUDE_PROJECT_DIR="$z"; cd "$z"; printf '%s' "$z_destructive" | eval "$z_guard_cmd" ) >/dev/null 2>&1
    z2_rc=$?
    assert "Z2: guard ABSENT (mutation) -> command exits non-zero, never silent-allow (fail-CLOSED)" "$([[ "$z2_rc" -ne 0 ]] && echo 0 || echo 1)"

    # Z3: degenerate empty \$CLAUDE_PROJECT_DIR + absent guard -> still non-zero (fail-CLOSED).
    ( export CLAUDE_PROJECT_DIR=""; cd "$z"; printf '%s' "$z_destructive" | eval "$z_guard_cmd" ) >/dev/null 2>&1
    z3_rc=$?
    assert "Z3: empty CLAUDE_PROJECT_DIR + absent guard -> non-zero (fail-CLOSED degenerate)" "$([[ "$z3_rc" -ne 0 ]] && echo 0 || echo 1)"
fi

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
