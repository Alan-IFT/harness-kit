#!/usr/bin/env bash
# test-language.sh — Regression for the /harness-language mechanical layer (T-014).
# Mirror of test-language.ps1. See that file for full doc.
#
# Drives language-policy.sh against synthetic generated-project fixtures (each its OWN
# temp dir — insight L22), then asserts the end state. --template-root = this repo root.
#
# The fixtures and assertions reference the CURRENT canonical markers only (the zh
# consumer-split heading + the human-side / agent-side discriminants); they never embed
# the retired single-language phrasing, so this driver stays clear of the verify_all I.6
# guard and is NOT in the I.6 exempt-FILE list.
#
# Usage:
#   bash .harness/scripts/test-language.sh
#   bash .harness/scripts/test-language.sh --keep-temp

set -uo pipefail

# Script lives at .harness/scripts/ — repo root is two levels up.
repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
helper="$repo_root/.harness/scripts/language-policy.sh"

KEEP_TEMP=false
[[ "${1:-}" == "--keep-temp" ]] && KEEP_TEMP=true

pass=0
fail=0
failed=()
tmp_dirs=()

# Markers (built from pieces / current canonical text only — never the retired form).
zh_heading="输出语言（按消费者分流）"
en_heading="Output language (project-wide)"
zh_human_marker='用**中文**'      # human-side consumer line discriminant
zh_agent_marker='用**英文**'      # agent-side consumer line discriminant

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

contains() { case "$2" in *"$1"*) return 0 ;; *) return 1 ;; esac; }

# --- fixture builder. lang=en|zh; flags: no_copilot=1 mangled=1 git=1 ---------------
# Builds a minimal generated-project shape with the policy section + lines in <lang>.
new_fixture() {
    local lang="$1" no_copilot="${2:-0}" mangled="${3:-0}" do_git="${4:-1}"
    local dir
    dir="$(mktemp -d -t "language-${lang}-XXXXXX")"
    mkdir -p "$dir/.harness/rules" "$dir/.github"

    if [[ "$mangled" == "1" ]]; then
        # 00-core with NO recognizable policy heading.
        {
            echo "# Demo — Project Rules"
            echo ""
            echo "## Output langauge (typo, unmatched)"
            echo ""
            echo "some body"
            echo ""
            echo "## How this project is developed"
            echo ""
            echo "keep"
        } > "$dir/.harness/rules/00-core.md"
    elif [[ "$lang" == "en" ]]; then
        {
            echo "# Demo — Project Rules"
            echo ""
            echo "> intro"
            echo ""
            echo "## Output language (project-wide)"
            echo ""
            echo "old en body"
            echo ""
            echo "## How this project is developed"
            echo ""
            echo "keep me"
        } > "$dir/.harness/rules/00-core.md"
    else
        {
            echo "# Demo — Project Rules"
            echo ""
            echo "> intro"
            echo ""
            echo "## 输出语言（按消费者分流）"
            echo ""
            echo "old zh body"
            echo ""
            echo "## 这个项目怎么开发"
            echo ""
            echo "keep me"
        } > "$dir/.harness/rules/00-core.md"
    fi

    if [[ "$lang" == "en" || "$mangled" == "1" ]]; then
        printf '# Demo — bootstrap rules\n\nOutput language: **English**.\n\nmore\n' > "$dir/CLAUDE.md"
        [[ "$no_copilot" == "1" ]] || printf -- '---\napplyTo: "**"\n---\n# Demo\n\nOutput language: **English**.\n\nmore\n' > "$dir/.github/copilot-instructions.md"
    else
        printf '# Demo — bootstrap rules\n\n输出语言：面向人的产出用**中文**，面向 agent 的产出用**英文**。\n\nmore\n' > "$dir/CLAUDE.md"
        [[ "$no_copilot" == "1" ]] || printf -- '---\napplyTo: "**"\n---\n# Demo\n\n输出语言：面向人的产出用**中文**，面向 agent 的产出用**英文**。\n\nmore\n' > "$dir/.github/copilot-instructions.md"
    fi

    if [[ "$do_git" == "1" ]]; then
        ( cd "$dir" && git init -q && git config user.email "t@example.com" && git config user.name "test" \
          && git add -A >/dev/null 2>&1 && git commit -q -m "fixture" >/dev/null 2>&1 )
    fi
    echo "$dir"
}

RUN_OUT=""
RUN_CODE=0
invoke() {
    local dir="$1"; shift
    RUN_OUT="$(cd "$dir" && bash "$helper" --template-root "$repo_root" "$@" 2>&1)"
    RUN_CODE=$?
}

cleanup() {
    if [[ "$KEEP_TEMP" == false ]]; then
        for d in "${tmp_dirs[@]}"; do [[ -d "$d" ]] && rm -rf "$d"; done
    else
        echo "Kept temp dirs:"
        for d in "${tmp_dirs[@]}"; do echo "  $d"; done
    fi
}
trap cleanup EXIT

echo "=== test-language (bash) ==="

# --- #1 en -> zh switch (AC-3, AC-6) ---
echo ""
echo "--- #1 en -> zh switch ---"
f1="$(new_fixture en)"; tmp_dirs+=("$f1")
invoke "$f1" --lang zh
assert "1: exits 0" "$([[ "$RUN_CODE" -eq 0 ]] && echo 0 || echo 1)"
core1="$(cat "$f1/.harness/rules/00-core.md")"
assert "1: 00-core has zh heading (AC-3)" "$(contains "$zh_heading" "$core1" && echo 0 || echo 1)"
assert "1: 00-core has human-side ZH marker" "$(contains "$zh_human_marker" "$core1" && echo 0 || echo 1)"
assert "1: 00-core has agent-side EN marker" "$(contains "$zh_agent_marker" "$core1" && echo 0 || echo 1)"
assert "1: old en heading gone (AC-6 single section)" "$(contains "$en_heading" "$core1" && echo 1 || echo 0)"
assert "1: exactly one policy heading (AC-6)" "$([[ "$(grep -c '输出语言（按消费者分流）' "$f1/.harness/rules/00-core.md")" -eq 1 ]] && echo 0 || echo 1)"
assert "1: '## How this project is developed' preserved" "$(contains '## How this project is developed' "$core1" && echo 0 || echo 1)"
assert "1: 'keep me' preserved (surgical)" "$(contains 'keep me' "$core1" && echo 0 || echo 1)"
assert "1: CLAUDE.md zh line" "$(contains '输出语言：' "$(cat "$f1/CLAUDE.md")" && echo 0 || echo 1)"
assert "1: copilot zh line" "$(contains '输出语言：' "$(cat "$f1/.github/copilot-instructions.md")" && echo 0 || echo 1)"
assert "1: .bak written per file" "$([[ -n "$(ls "$f1/.harness/rules/"*.bak* 2>/dev/null)" && -n "$(ls "$f1/"CLAUDE.md.bak* 2>/dev/null)" ]] && echo 0 || echo 1)"

# --- #2 idempotence of the switch (AC-2) ---
echo ""
echo "--- #2 idempotent re-run zh ---"
bak_before="$(ls "$f1/.harness/rules/"*.bak* 2>/dev/null | wc -l)"
invoke "$f1" --lang zh
assert "2: 2nd run exits 0 (AC-2)" "$([[ "$RUN_CODE" -eq 0 ]] && echo 0 || echo 1)"
assert "2: 2nd run all NOOP (AC-2)" "$(contains 'NOOP|.harness/rules/00-core.md' "$RUN_OUT" && echo 0 || echo 1)"
bak_after="$(ls "$f1/.harness/rules/"*.bak* 2>/dev/null | wc -l)"
assert "2: no new .bak on no-op (AC-2)" "$([[ "$bak_before" -eq "$bak_after" ]] && echo 0 || echo 1)"

# --- #3 zh -> en switch (AC-1, AC-6) ---
echo ""
echo "--- #3 zh -> en switch ---"
f3="$(new_fixture zh)"; tmp_dirs+=("$f3")
invoke "$f3" --lang en
assert "3: exits 0" "$([[ "$RUN_CODE" -eq 0 ]] && echo 0 || echo 1)"
core3="$(cat "$f3/.harness/rules/00-core.md")"
assert "3: 00-core has en heading (AC-1)" "$(contains "$en_heading" "$core3" && echo 0 || echo 1)"
assert "3: en single-language body present" "$(contains 'must be in English' "$core3" && echo 0 || echo 1)"
assert "3: old zh heading gone (AC-6)" "$(contains "$zh_heading" "$core3" && echo 1 || echo 0)"
assert "3: zh '## 这个项目怎么开发' preserved" "$(contains '## 这个项目怎么开发' "$core3" && echo 0 || echo 1)"
assert "3: CLAUDE.md en line" "$(contains 'Output language: **English**.' "$(cat "$f3/CLAUDE.md")" && echo 0 || echo 1)"

# --- #4 idempotence of en (AC-2) ---
echo ""
echo "--- #4 idempotent re-run en ---"
invoke "$f3" --lang en
assert "4: re-run en all NOOP (AC-2)" "$(contains 'NOOP|.harness/rules/00-core.md' "$RUN_OUT" && echo 0 || echo 1)"

# --- #5 dry-run leaves the fixture unchanged (AC-5, NFR-2) ---
echo ""
echo "--- #5 dry-run unchanged ---"
f5="$(new_fixture zh)"; tmp_dirs+=("$f5")
before5="$(cd "$f5" && git status --porcelain)"
invoke "$f5" --lang en --dry-run
assert "5: dry-run exits 0" "$([[ "$RUN_CODE" -eq 0 ]] && echo 0 || echo 1)"
assert "5: dry-run prints PLAN lines" "$(contains 'PLAN|REWRITE-SECTION' "$RUN_OUT" && echo 0 || echo 1)"
after5="$(cd "$f5" && git status --porcelain)"
assert "5: dry-run made no git-visible change (NFR-2)" "$([[ "$before5" == "$after5" ]] && echo 0 || echo 1)"
assert "5: dry-run wrote no .bak" "$([[ -z "$(ls "$f5/.harness/rules/"*.bak* 2>/dev/null)" ]] && echo 0 || echo 1)"

# --- #6 no-arg detect + refresh on a current zh project (AC-4) ---
echo ""
echo "--- #6 no-arg detect (DETECT record) ---"
f6="$(new_fixture zh)"; tmp_dirs+=("$f6")
# helper requires --lang; the no-arg DETECT is observed by running with the detected lang
# in dry-run and checking the DETECT record + that a same-lang apply is a clean refresh.
invoke "$f6" --lang zh --dry-run
assert "6: DETECT|zh|00-core emitted (AC-4)" "$(contains 'DETECT|zh|00-core' "$RUN_OUT" && echo 0 || echo 1)"
invoke "$f6" --lang zh
assert "6: refresh to current zh rewrites to canonical text (AC-4)" "$(contains "$zh_human_marker" "$(cat "$f6/.harness/rules/00-core.md")" && echo 0 || echo 1)"

# --- #7 missing copilot tolerated (AC-8) ---
echo ""
echo "--- #7 missing copilot SKIP ---"
f7="$(new_fixture en 1)"; tmp_dirs+=("$f7")
invoke "$f7" --lang zh
assert "7: exits 0 without copilot (AC-8)" "$([[ "$RUN_CODE" -eq 0 ]] && echo 0 || echo 1)"
assert "7: copilot reported SKIP (AC-8)" "$(contains 'SKIP|.github/copilot-instructions.md|absent' "$RUN_OUT" && echo 0 || echo 1)"
assert "7: 00-core still rewritten" "$(contains "$zh_heading" "$(cat "$f7/.harness/rules/00-core.md")" && echo 0 || echo 1)"

# --- #8 hand-mangled heading -> CONFLICT, exit 2, file unchanged (AC-7) ---
echo ""
echo "--- #8 hand-mangled heading conflict ---"
f8="$(new_fixture en 0 1)"; tmp_dirs+=("$f8")
core8_before="$(cat "$f8/.harness/rules/00-core.md")"
invoke "$f8" --lang en
assert "8: exits 2 on conflict (AC-7)" "$([[ "$RUN_CODE" -eq 2 ]] && echo 0 || echo 1)"
assert "8: CONFLICT|section surfaced (AC-7)" "$(contains 'CONFLICT|section' "$RUN_OUT" && echo 0 || echo 1)"
assert "8: 00-core unchanged without --force (AC-7)" "$([[ "$core8_before" == "$(cat "$f8/.harness/rules/00-core.md")" ]] && echo 0 || echo 1)"
invoke "$f8" --lang en --force
assert "8: --force inserts the section (exit 0)" "$([[ "$RUN_CODE" -eq 0 ]] && echo 0 || echo 1)"
assert "8: inserted en heading present after --force" "$(contains "$en_heading" "$(cat "$f8/.harness/rules/00-core.md")" && echo 0 || echo 1)"

# --- #9 byte-identical zh -> en -> zh round-trip (the R7/§5.4 hazard) ---
echo ""
echo "--- #9 byte-identical zh->en->zh round-trip ---"
f9="$(new_fixture zh)"; tmp_dirs+=("$f9")
# Normalize to a first canonical zh state, snapshot it, then en -> zh and compare bytes.
invoke "$f9" --lang zh
snap_core="$(mktemp)"; snap_claude="$(mktemp)"; snap_copilot="$(mktemp)"
tmp_dirs+=("$snap_core" "$snap_claude" "$snap_copilot")
cp "$f9/.harness/rules/00-core.md" "$snap_core"
cp "$f9/CLAUDE.md" "$snap_claude"
cp "$f9/.github/copilot-instructions.md" "$snap_copilot"
invoke "$f9" --lang en
invoke "$f9" --lang zh
assert "9: 00-core byte-identical after round-trip (§5.4)" "$(cmp -s "$snap_core" "$f9/.harness/rules/00-core.md" && echo 0 || echo 1)"
assert "9: CLAUDE.md byte-identical after round-trip (§5.4)" "$(cmp -s "$snap_claude" "$f9/CLAUDE.md" && echo 0 || echo 1)"
assert "9: copilot byte-identical after round-trip (§5.4)" "$(cmp -s "$snap_copilot" "$f9/.github/copilot-instructions.md" && echo 0 || echo 1)"

# --- #10 bad --lang halts (boundary 2) ---
echo ""
echo "--- #10 invalid --lang ---"
f10="$(new_fixture en)"; tmp_dirs+=("$f10")
invoke "$f10" --lang fr
assert "10: bad --lang exits 1 (boundary 2)" "$([[ "$RUN_CODE" -eq 1 ]] && echo 0 || echo 1)"

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
