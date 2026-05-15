#!/usr/bin/env bash
# test-init.sh — Automated regression for /harness-init (v0.2)
# Mirror of scripts/test-init.ps1. See that file for full doc.

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

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
template_root="$repo_root/skills/harness-init/templates"
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

substitute() {
    local file="$1" project_name="$2" project_type="$3" stack="$4"
    local tmp; tmp=$(mktemp)
    sed \
        -e "s|{{PROJECT_NAME}}|$project_name|g" \
        -e "s|{{PROJECT_TYPE}}|$project_type|g" \
        -e "s|{{STACK}}|$stack|g" \
        -e "s|{{TODAY}}|$today|g" \
        -e "s|{{ENABLE_HOOK}}|false|g" \
        "$file" > "$tmp"
    mv "$tmp" "$file"
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

test_type() {
    local project_type="$1" stack="$2"
    echo ""
    echo "=== Testing: $project_type ($stack) ==="

    local tmp; tmp=$(mktemp -d -t harness-test-XXXXXX)

    copy_layer "$template_root/common" "$tmp" "test-project" "$project_type" "$stack"
    copy_layer "$template_root/$project_type" "$tmp" "test-project" "$project_type" "$stack"

    # Run embedded harness-sync to generate .claude/ + CLAUDE.md
    assert "harness-sync.sh was distributed" "[[ -f '$tmp/scripts/harness-sync.sh' ]]"
    if [[ -f "$tmp/scripts/harness-sync.sh" ]]; then
        if bash "$tmp/scripts/harness-sync.sh" &>/dev/null; then
            echo "  PASS  harness-sync exited cleanly"
            ((pass++))
        else
            echo "  FAIL  harness-sync exited cleanly" >&2
            ((fail++))
            failures+=("harness-sync exit nonzero")
        fi
    fi

    # SOT (.harness/) assertions
    for a in pm-orchestrator requirement-analyst solution-architect gate-reviewer developer code-reviewer qa-tester; do
        assert ".harness/agents/$a.md (SOT)" "[[ -f '$tmp/.harness/agents/$a.md' ]]"
    done
    assert ".harness/rules/00-core.md (composed base)" "[[ -f '$tmp/.harness/rules/00-core.md' ]]"
    assert ".harness/rules/50-$project_type.md (overlay)" "[[ -f '$tmp/.harness/rules/50-$project_type.md' ]]"
    for s in build test verify; do
        assert ".harness/skills/$s/SKILL.md (SOT)" "[[ -f '$tmp/.harness/skills/$s/SKILL.md' ]]"
    done

    # Generated artifacts
    for a in pm-orchestrator requirement-analyst solution-architect gate-reviewer developer code-reviewer qa-tester; do
        assert ".claude/agents/$a.md (generated)" "[[ -f '$tmp/.claude/agents/$a.md' ]]"
    done
    for s in build test verify; do
        assert ".claude/skills/$s/SKILL.md (generated)" "[[ -f '$tmp/.claude/skills/$s/SKILL.md' ]]"
    done
    assert ".claude/settings.json (direct binding artifact)" "[[ -f '$tmp/.claude/settings.json' ]]"
    assert "CLAUDE.md (generated)" "[[ -f '$tmp/CLAUDE.md' ]]"

    # Content correctness
    assert "CLAUDE.md has generated marker" "grep -q 'THIS FILE IS GENERATED' '$tmp/CLAUDE.md'"
    assert "CLAUDE.md contains overlay marker for $project_type" "grep -q '$project_type-specific rules' '$tmp/CLAUDE.md'"
    assert "PROJECT_NAME substituted into rules" "grep -q 'test-project' '$tmp/.harness/rules/00-core.md'"
    assert "TODAY substituted into rules" "grep -q '$today' '$tmp/.harness/rules/00-core.md'"
    assert "STACK substituted into rules" "grep -qF '$stack' '$tmp/.harness/rules/00-core.md'"

    # Docs / scripts / evals
    for f in docs/workflow.md docs/dev-map.md docs/tasks.md docs/spec/README.md evals/golden-tasks.md scripts/verify_all.ps1 scripts/verify_all.sh scripts/harness-sync.ps1; do
        assert "$f present" "[[ -f '$tmp/$f' ]]"
    done

    # Cleanliness
    if grep -rE '\{\{[A-Z_]+\}\}' "$tmp" --include="*.md" --include="*.json" --include="*.sh" --include="*.ps1" &>/dev/null; then
        echo "  FAIL  no unresolved placeholders anywhere" >&2
        ((fail++)); failures+=("unresolved placeholders")
    else
        echo "  PASS  no unresolved placeholders anywhere"; ((pass++))
    fi
    leaked=$(find "$tmp" -name "*.tmpl" -type f 2>/dev/null)
    [[ -z "$leaked" ]] && { echo "  PASS  no .tmpl files leaked"; ((pass++)); } || { echo "  FAIL  leaked: $leaked" >&2; ((fail++)); }
    leaked=$(find "$tmp" -name "*.append" -type f 2>/dev/null)
    [[ -z "$leaked" ]] && { echo "  PASS  no .append files anywhere (v0.2 removed them)"; ((pass++)); } || { echo "  FAIL  found: $leaked" >&2; ((fail++)); }

    # Binding consistency right after init
    if bash "$tmp/scripts/harness-sync.sh" --check &>/dev/null; then
        echo "  PASS  harness-sync --check is clean after init"; ((pass++))
    else
        echo "  FAIL  harness-sync --check is clean after init" >&2; ((fail++))
        failures+=("binding drift right after init")
    fi

    if [[ "$KEEP" == true ]]; then
        echo ""
        echo "Temp dir kept: $tmp"
    else
        rm -rf "$tmp"
    fi
}

echo "=== test-init: simulating /harness-init flow (v0.2) ==="
echo "Repo: $repo_root"

if [[ "$TYPE" == "both" || "$TYPE" == "fullstack" ]]; then
    test_type "fullstack" "Next.js + NestJS + Postgres"
fi
if [[ "$TYPE" == "both" || "$TYPE" == "backend" ]]; then
    test_type "backend" "FastAPI + Postgres"
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
