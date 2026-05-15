#!/usr/bin/env bash
# test-init.sh — Automated regression for /harness-init template copy logic.
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
    # macOS sed wants -i ''; GNU sed wants -i. Use a temp file for portability.
    local tmp
    tmp=$(mktemp)
    sed \
        -e "s|{{PROJECT_NAME}}|$project_name|g" \
        -e "s|{{PROJECT_TYPE}}|$project_type|g" \
        -e "s|{{STACK}}|$stack|g" \
        -e "s|{{TODAY}}|$today|g" \
        -e "s|{{ENABLE_HOOK}}|false|g" \
        "$file" > "$tmp"
    mv "$tmp" "$file"
}

copy_template() {
    local source="$1" target="$2" project_name="$3" project_type="$4" stack="$5"

    [[ -d "$source" ]] || { echo "source missing: $source" >&2; exit 1; }

    # First, handle .tmpl and regular files (skip .append for now)
    find "$source" -type f ! -name "*.append" | while read -r f; do
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

    # Then handle .append files (append to existing CLAUDE.md)
    find "$source" -type f -name "*.append" | while read -r f; do
        if [[ -f "$target/CLAUDE.md" ]]; then
            cat "$f" >> "$target/CLAUDE.md"
        fi
    done
}

test_type() {
    local project_type="$1" stack="$2"
    echo ""
    echo "=== Testing: $project_type ($stack) ==="

    local tmp
    tmp=$(mktemp -d -t harness-test-XXXXXX)

    copy_template "$template_root/common" "$tmp" "test-project" "$project_type" "$stack"
    copy_template "$template_root/$project_type" "$tmp" "test-project" "$project_type" "$stack"

    # === Assertions ===
    for a in pm-orchestrator requirement-analyst solution-architect gate-reviewer developer code-reviewer qa-tester; do
        assert "agent: $a.md" "[[ -f '$tmp/.claude/agents/$a.md' ]]"
    done

    for s in build test verify; do
        assert "skill: $s/SKILL.md" "[[ -f '$tmp/.claude/skills/$s/SKILL.md' ]]"
        assert "skill: $s/SKILL.md.tmpl removed" "[[ ! -f '$tmp/.claude/skills/$s/SKILL.md.tmpl' ]]"
    done

    assert "settings.json (no .tmpl suffix)" "[[ -f '$tmp/.claude/settings.json' ]]"
    assert "CLAUDE.md present" "[[ -f '$tmp/CLAUDE.md' ]]"
    assert "CLAUDE.md.tmpl removed" "[[ ! -f '$tmp/CLAUDE.md.tmpl' ]]"
    assert "CLAUDE.md contains overlay marker" "grep -q '$project_type-specific rules' '$tmp/CLAUDE.md'"

    assert "docs/workflow.md" "[[ -f '$tmp/docs/workflow.md' ]]"
    assert "docs/dev-map.md" "[[ -f '$tmp/docs/dev-map.md' ]]"
    assert "docs/tasks.md" "[[ -f '$tmp/docs/tasks.md' ]]"
    assert "docs/spec/README.md" "[[ -f '$tmp/docs/spec/README.md' ]]"
    assert "evals/golden-tasks.md" "[[ -f '$tmp/evals/golden-tasks.md' ]]"
    assert "scripts/verify_all.ps1" "[[ -f '$tmp/scripts/verify_all.ps1' ]]"
    assert "scripts/verify_all.sh"  "[[ -f '$tmp/scripts/verify_all.sh' ]]"
    assert "scripts/verify_all.ps1.tmpl removed" "[[ ! -f '$tmp/scripts/verify_all.ps1.tmpl' ]]"
    assert "scripts/verify_all.sh.tmpl removed"  "[[ ! -f '$tmp/scripts/verify_all.sh.tmpl' ]]"

    assert "PROJECT_NAME substituted" "grep -q 'test-project' '$tmp/CLAUDE.md'"
    assert "TODAY substituted" "grep -q '$today' '$tmp/CLAUDE.md'"
    assert "STACK substituted" "grep -qF '$stack' '$tmp/CLAUDE.md'"

    if grep -rE '\{\{[A-Z_]+\}\}' "$tmp" --include="*.md" --include="*.json" --include="*.sh" --include="*.ps1" &>/dev/null; then
        echo "  FAIL  no unresolved placeholders anywhere" >&2
        ((fail++))
        failures+=("unresolved placeholders")
    else
        echo "  PASS  no unresolved placeholders anywhere"
        ((pass++))
    fi

    leaked=$(find "$tmp" -name "*.tmpl" -type f 2>/dev/null)
    [[ -z "$leaked" ]] && { echo "  PASS  no .tmpl leaked"; ((pass++)); } || { echo "  FAIL  leaked: $leaked" >&2; ((fail++)); }

    leaked=$(find "$tmp" -name "*.append" -type f 2>/dev/null)
    [[ -z "$leaked" ]] && { echo "  PASS  no .append leaked"; ((pass++)); } || { echo "  FAIL  leaked: $leaked" >&2; ((fail++)); }

    if [[ "$KEEP" == true ]]; then
        echo ""
        echo "Temp dir kept: $tmp"
    else
        rm -rf "$tmp"
    fi
}

echo "=== test-init: simulating /harness-init template copy ==="
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
