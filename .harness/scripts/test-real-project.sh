#!/usr/bin/env bash
# test-real-project.sh — Integration test: apply harness-init templates onto
# a fixture project that already has code, then run harness-sync.
# Mirror of test-real-project.ps1. See that file for full doc.

set -uo pipefail

TYPE="both"
KEEP=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --type) TYPE="$2"; shift 2 ;;
        --keep) KEEP=true; shift ;;
        *) echo "Unknown arg: $1" >&2; exit 1 ;;
    esac
done

# Script lives at .harness/scripts/ — repo root is two levels up.
repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
template_root="$repo_root/skills/harness-init/templates"
fixtures_root="$repo_root/tests/fixtures"
today=$(date +%Y-%m-%d)

pass=0
fail=0
declare -a failures

assert() {
    local name="$1" cond="$2"
    if eval "$cond" &>/dev/null; then
        echo "  PASS  $name"
        ((pass++))
    else
        echo "  FAIL  $name" >&2
        ((fail++))
        failures+=("$name")
    fi
}

# T-12: this is a live FIXTURE-AUTHORING site (builds the fixture's FINAL settings),
# so the *_COMMAND values are the RESILIENT form — fail-OPEN + $CLAUDE_PROJECT_DIR-anchored
# for the convenience hooks, fail-CLOSED (no `|| exit 0`) for guard-rm. JSON-ESCAPED bytes
# (inner " as \") so the substituted settings match the resilient literals byte-for-byte.
# These literals are copied byte-identical from test-init.sh (AC-7: no surviving brittle
# authoring form for the convenience hooks).
case "${OSTYPE:-}" in
    msys*|cygwin*|win32)
        SYNC_COMMAND='pwsh -NoProfile -Command \"Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR -EA SilentlyContinue; if (Test-Path -LiteralPath .harness/scripts/harness-sync.ps1 -PathType Leaf) { & pwsh -NoProfile -File .harness/scripts/harness-sync.ps1 }; exit 0\"'
        GUARD_COMMAND='pwsh -NoProfile -Command \"Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR; & pwsh -NoProfile -File .harness/scripts/guard-rm.ps1\"'
        AMBIENT_PROMPT_COMMAND='pwsh -NoProfile -Command \"Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR -EA SilentlyContinue; if (Test-Path -LiteralPath .harness/scripts/ambient-prompt.ps1 -PathType Leaf) { & pwsh -NoProfile -File .harness/scripts/ambient-prompt.ps1 }; exit 0\"'
        AMBIENT_RESET_COMMAND='pwsh -NoProfile -Command \"Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR -EA SilentlyContinue; if (Test-Path -LiteralPath .harness/scripts/ambient-reset.ps1 -PathType Leaf) { & pwsh -NoProfile -File .harness/scripts/ambient-reset.ps1 }; exit 0\"'
        ;;
    *)
        SYNC_COMMAND="sh -c 'cd \\\"\$CLAUDE_PROJECT_DIR\\\" 2>/dev/null && [ -f .harness/scripts/harness-sync.sh ] && exec bash .harness/scripts/harness-sync.sh || exit 0'"
        GUARD_COMMAND="sh -c 'cd \\\"\$CLAUDE_PROJECT_DIR\\\" 2>/dev/null && bash .harness/scripts/guard-rm.sh'"
        AMBIENT_PROMPT_COMMAND="sh -c 'cd \\\"\$CLAUDE_PROJECT_DIR\\\" 2>/dev/null && [ -f .harness/scripts/ambient-prompt.sh ] && exec bash .harness/scripts/ambient-prompt.sh || exit 0'"
        AMBIENT_RESET_COMMAND="sh -c 'cd \\\"\$CLAUDE_PROJECT_DIR\\\" 2>/dev/null && [ -f .harness/scripts/ambient-reset.sh ] && exec bash .harness/scripts/ambient-reset.sh || exit 0'"
        ;;
esac

# Literal replace-all (no sed): immune to bash 5.2's `&`-means-matched-text rule in
# ${var//pat/repl} AND to sed delimiter/metachar collisions. The T-12 resilient command
# values carry `&` (`& pwsh`), `|` (unix `||`), `;`, and `{`/`}` — none of which are safe
# in a sed replacement. Splits on the needle and concatenates verbatim. (Mirrors test-init.sh.)
ti_replace_all() {
    local rest="$1" needle="$2" repl="$3" out=""
    while [[ "$rest" == *"$needle"* ]]; do
        out="$out${rest%%"$needle"*}$repl"
        rest="${rest#*"$needle"}"
    done
    printf '%s' "$out$rest"
}

substitute() {
    local file="$1" project_name="$2" project_type="$3" stack="$4"
    local tmp; tmp=$(mktemp)
    # The simple scalar placeholders stay on sed (their values are plain text).
    sed \
        -e "s|{{PROJECT_NAME}}|$project_name|g" \
        -e "s|{{PROJECT_TYPE}}|$project_type|g" \
        -e "s|{{STACK}}|$stack|g" \
        -e "s|{{TODAY}}|$today|g" \
        -e "s|{{ENABLE_HOOK}}|false|g" \
        "$file" > "$tmp"
    # The four command placeholders carry the resilient strings (sed-unsafe metachars),
    # so substitute them with the literal replace-all helper on the file content. Only
    # files that actually carry a command placeholder are rewritten this way; everything
    # else keeps sed's byte-exact output.
    if grep -q '{{SYNC_COMMAND}}\|{{GUARD_COMMAND}}\|{{AMBIENT_PROMPT_COMMAND}}\|{{AMBIENT_RESET_COMMAND}}' "$tmp"; then
        local content; content="$(cat "$tmp")"
        content="$(ti_replace_all "$content" "{{SYNC_COMMAND}}" "$SYNC_COMMAND")"
        content="$(ti_replace_all "$content" "{{GUARD_COMMAND}}" "$GUARD_COMMAND")"
        content="$(ti_replace_all "$content" "{{AMBIENT_PROMPT_COMMAND}}" "$AMBIENT_PROMPT_COMMAND")"
        content="$(ti_replace_all "$content" "{{AMBIENT_RESET_COMMAND}}" "$AMBIENT_RESET_COMMAND")"
        printf '%s\n' "$content" > "$file"
        rm -f "$tmp"
    else
        mv "$tmp" "$file"
    fi
}

copy_tree() {
    local source="$1" target="$2"
    [[ -d "$source" ]] || { echo "source missing: $source" >&2; exit 1; }
    find "$source" -type f | while read -r f; do
        rel="${f#$source/}"
        dst="$target/$rel"
        mkdir -p "$(dirname "$dst")"
        cp "$f" "$dst"
    done
}

copy_layer() {
    local source="$1" target="$2" project_name="$3" project_type="$4" stack="$5"
    [[ -d "$source" ]] || { echo "source missing: $source" >&2; exit 1; }
    find "$source" -type f | while read -r f; do
        rel="${f#$source/}"
        if [[ "$rel" == *.tmpl ]]; then
            dest_rel="${rel%.tmpl}"
            dest="$target/$dest_rel"
            mkdir -p "$(dirname "$dest")"
            cp "$f" "$dest"
            substitute "$dest" "$project_name" "$project_type" "$stack"
        else
            dest="$target/$rel"
            mkdir -p "$(dirname "$dest")"
            cp "$f" "$dest"
        fi
    done
}

test_fixture() {
    local project_type="$1" fixture_name="$2" stack="$3"
    echo ""
    echo "=== Integration: $fixture_name ($project_type / $stack) ==="

    local tmp; tmp=$(mktemp -d -t harness-int-XXXXXX)

    copy_tree "$fixtures_root/$fixture_name" "$tmp"

    # Snapshot existing files
    local snap; snap=$(mktemp)
    find "$tmp" -type f | while read -r f; do
        rel="${f#$tmp/}"
        echo "$rel:$(sha256sum "$f" | cut -d' ' -f1)" >> "$snap"
    done

    copy_layer "$template_root/common" "$tmp" "$fixture_name" "$project_type" "$stack"
    copy_layer "$template_root/$project_type" "$tmp" "$fixture_name" "$project_type" "$stack"

    # Run distributed harness-sync
    assert "harness-sync.sh distributed" "[[ -f '$tmp/.harness/scripts/harness-sync.sh' ]]"
    if bash "$tmp/.harness/scripts/harness-sync.sh" &>/dev/null; then
        echo "  PASS  harness-sync exited cleanly"
        ((pass++))
    else
        echo "  FAIL  harness-sync exited cleanly" >&2
        ((fail++))
        failures+=("harness-sync nonzero exit")
    fi

    # Existing files preserved
    while IFS=':' read -r rel hash; do
        [[ -z "$rel" ]] && continue
        abs="$tmp/$rel"
        if [[ -f "$abs" ]]; then
            now=$(sha256sum "$abs" | cut -d' ' -f1)
            if [[ "$now" == "$hash" ]]; then
                echo "  PASS  existing file preserved: $rel"
                ((pass++))
            else
                echo "  FAIL  existing file modified: $rel" >&2
                ((fail++))
            fi
        else
            echo "  FAIL  existing file deleted: $rel" >&2
            ((fail++))
        fi
    done < "$snap"
    rm -f "$snap"

    # Harness assets
    # v0.30 cutover: the 7 generic framework agents are PLUGIN-provided (harness-kit:<name>),
    # NOT copied into the project — assert they are ABSENT in both the SOT and generated trees.
    # Partition dev-* still ship locally and sync. (Mirrors the test-init flip; the operator
    # reconciles baseline.json counts from a captured run.)
    for a in pm-orchestrator requirement-analyst solution-architect gate-reviewer developer code-reviewer qa-tester; do
        assert ".harness/agents/$a.md ABSENT (plugin-provided)" "[[ ! -f '$tmp/.harness/agents/$a.md' ]]"
        assert ".claude/agents/$a.md ABSENT (plugin-provided)" "[[ ! -f '$tmp/.claude/agents/$a.md' ]]"
    done
    if [[ "$project_type" == "fullstack" ]]; then
        real_partitions="dev-frontend dev-backend dev-db"
    else
        real_partitions="dev-api dev-services dev-db"
    fi
    for p in $real_partitions; do
        assert ".harness/agents/$p.md (partition)" "[[ -f '$tmp/.harness/agents/$p.md' ]]"
        assert ".claude/agents/$p.md (generated)" "[[ -f '$tmp/.claude/agents/$p.md' ]]"
    done
    assert ".harness/rules/00-core.md" "[[ -f '$tmp/.harness/rules/00-core.md' ]]"
    assert ".harness/rules/50-$project_type.md" "[[ -f '$tmp/.harness/rules/50-$project_type.md' ]]"
    assert "AI-GUIDE.md (v0.10 tool-agnostic entry)" "[[ -f '$tmp/AI-GUIDE.md' ]]"
    assert "CLAUDE.md (v0.10 bootstrap stub)" "[[ -f '$tmp/CLAUDE.md' ]]"
    assert ".claude/settings.json (direct copy)" "[[ -f '$tmp/.claude/settings.json' ]]"
    assert ".github/copilot-instructions.md (v0.10 bootstrap stub)" "[[ -f '$tmp/.github/copilot-instructions.md' ]]"

    # Binding consistency
    if bash "$tmp/.harness/scripts/harness-sync.sh" --check &>/dev/null; then
        echo "  PASS  harness-sync --check is clean"
        ((pass++))
    else
        echo "  FAIL  harness-sync --check is clean" >&2
        ((fail++))
    fi

    # AI-GUIDE.md indexes the overlay; CLAUDE.md stub points to AI-GUIDE.md
    assert "AI-GUIDE.md indexes 50-$project_type.md" "grep -q '50-$project_type.md' '$tmp/AI-GUIDE.md'"
    assert "CLAUDE.md stub references AI-GUIDE.md" "grep -q 'AI-GUIDE.md' '$tmp/CLAUDE.md'"

    # Fixture source intact
    if [[ "$project_type" == "fullstack" ]]; then
        assert "fixture src/server.ts intact" "[[ -f '$tmp/src/server.ts' ]]"
        assert "fixture tests/server.test.ts intact" "[[ -f '$tmp/tests/server.test.ts' ]]"
        assert "fixture package.json intact" "[[ -f '$tmp/package.json' ]]"
    else
        assert "fixture src/main.py intact" "[[ -f '$tmp/src/main.py' ]]"
        assert "fixture tests/test_main.py intact" "[[ -f '$tmp/tests/test_main.py' ]]"
        assert "fixture pyproject.toml intact" "[[ -f '$tmp/pyproject.toml' ]]"
    fi

    # .gitignore preserved
    if [[ "$project_type" == "fullstack" ]]; then
        assert ".gitignore preserved" "grep -q 'node_modules' '$tmp/.gitignore'"
    else
        assert ".gitignore preserved" "grep -q '__pycache__' '$tmp/.gitignore'"
    fi

    # === T-020: run the generated type verify_all on the fixture (AC-3 / AC-4) ===
    # First flip the tree to a healthy v0.30 SINGLE-DEV state: remove partition
    # agents from BOTH sides (absence of .harness/agents/ is healthy; binding stays
    # clean because both sides are removed). Then assert the agents-layout and
    # hook-congruence rows. Runs LAST in this fixture (tree mutated, then discarded).
    rm -rf "$tmp/.harness/agents" "$tmp/.claude/agents"
    if [[ "$project_type" == "backend" ]]; then
        t20_agents_row="D.3"; t20_cong_row="D.4b"
    else
        t20_agents_row="E.3"; t20_cong_row="E.4b"
    fi
    t20_va_out="$(cd "$tmp" && bash .harness/scripts/verify_all.sh --quick 2>/dev/null)"
    t20_a_line="$(printf '%s\n' "$t20_va_out" | grep -F "[$t20_agents_row]" | head -1)"
    t20_c_line="$(printf '%s\n' "$t20_va_out" | grep -F "[$t20_cong_row]" | head -1)"
    assert "[T-020] healthy v0.30 single-dev fixture: $t20_agents_row agents-layout PASS (AC-3)" \
        "[[ '$t20_a_line' == *PASS* ]]"
    assert "[T-020] healthy v0.30 single-dev fixture: $t20_cong_row hook-congruence PASS (AC-4 healthy half)" \
        "[[ '$t20_c_line' == *PASS* ]]"
    # Mutation: delete the sync scripts -> the congruence row must FAIL, naming the
    # missing path and the fix command (AC-4).
    rm -f "$tmp/.harness/scripts/harness-sync.sh" "$tmp/.harness/scripts/harness-sync.ps1"
    t20_va_out2="$(cd "$tmp" && bash .harness/scripts/verify_all.sh --quick 2>/dev/null)"
    t20_c_line2="$(printf '%s\n' "$t20_va_out2" | grep -F "[$t20_cong_row]" | head -1)"
    assert "[T-020] dangling fixture: $t20_cong_row FAILs (AC-4)" "[[ '$t20_c_line2' == *FAIL* ]]"
    t20_detail_ok=0
    if printf '%s' "$t20_va_out2" | grep -q 'missing script: .harness/scripts/harness-sync.' \
       && printf '%s' "$t20_va_out2" | grep -qF 'fix: run /harness-upgrade'; then
        t20_detail_ok=1
    fi
    assert "[T-020] dangling fixture: FAIL names the missing path + fix command (AC-4)" \
        "[[ '$t20_detail_ok' == '1' ]]"

    if [[ "$KEEP" == true ]]; then
        echo ""
        echo "Temp dir kept: $tmp"
    else
        rm -rf "$tmp"
    fi
}

echo "=== test-real-project: overlay Harness onto fixture projects ==="

if [[ "$TYPE" == "both" || "$TYPE" == "fullstack" ]]; then
    test_fixture "fullstack" "todo-fullstack" "Node + TypeScript + node:test"
fi
if [[ "$TYPE" == "both" || "$TYPE" == "backend" ]]; then
    test_fixture "backend" "todo-backend" "Python + pytest"
fi

echo ""
echo "=== Result ==="
echo "  PASS: $pass"
echo "  FAIL: $fail"

if (( fail > 0 )); then
    echo ""
    echo "Failures:" >&2
    for f in "${failures[@]}"; do echo "  - $f" >&2; done
    exit 1
fi
exit 0
