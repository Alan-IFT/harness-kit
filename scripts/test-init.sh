#!/usr/bin/env bash
# test-init.sh — Automated regression for /harness-init (v0.2)
# Mirror of scripts/test-init.ps1. See that file for full doc.

set -uo pipefail

TYPE="all"
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

# NOTE: -NoProfile on Windows mirrors harness-init/SKILL.md step 5 rule.
# Without it, every Bash tool call eats $PROFILE startup cost (NFR-Perf).
# See 06_TEST_REPORT.md D-3 (3.7s p50 → 10ms with -NoProfile).
case "${OSTYPE:-}" in
    msys*|cygwin*|win32)
        SYNC_COMMAND="pwsh -NoProfile -File scripts/harness-sync.ps1"
        GUARD_COMMAND="pwsh -NoProfile -File scripts/guard-rm.ps1"
        ;;
    *)
        SYNC_COMMAND="bash scripts/harness-sync.sh"
        GUARD_COMMAND="bash scripts/guard-rm.sh"
        ;;
esac

substitute() {
    local file="$1" project_name="$2" project_type="$3" stack="$4"
    local tmp; tmp=$(mktemp)
    sed \
        -e "s|{{PROJECT_NAME}}|$project_name|g" \
        -e "s|{{PROJECT_TYPE}}|$project_type|g" \
        -e "s|{{STACK}}|$stack|g" \
        -e "s|{{TODAY}}|$today|g" \
        -e "s|{{ENABLE_HOOK}}|false|g" \
        -e "s|{{SYNC_COMMAND}}|$SYNC_COMMAND|g" \
        -e "s|{{GUARD_COMMAND}}|$GUARD_COMMAND|g" \
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

    # Partition agents: fullstack and backend have them in v0.5+; generic has none
    case "$project_type" in
        fullstack) partition_agents="dev-frontend dev-backend dev-db" ;;
        backend)   partition_agents="dev-api dev-services dev-db" ;;
        generic)   partition_agents="" ;;
    esac
    for p in $partition_agents; do
        assert ".harness/agents/$p.md (partition SOT)" "[[ -f '$tmp/.harness/agents/$p.md' ]]"
        assert ".harness/agents/$p.md placeholder substituted" "! grep -qE '\{\{[A-Z_]+\}\}' '$tmp/.harness/agents/$p.md' && grep -q 'test-project' '$tmp/.harness/agents/$p.md'"
    done
    assert ".harness/rules/00-core.md (composed base)" "[[ -f '$tmp/.harness/rules/00-core.md' ]]"
    assert ".harness/rules/50-$project_type.md (overlay)" "[[ -f '$tmp/.harness/rules/50-$project_type.md' ]]"
    if [[ "$project_type" != "generic" ]]; then
        for s in build test verify; do
            assert ".harness/skills/$s/SKILL.md (SOT)" "[[ -f '$tmp/.harness/skills/$s/SKILL.md' ]]"
        done
    fi

    # Generated artifacts
    for a in pm-orchestrator requirement-analyst solution-architect gate-reviewer developer code-reviewer qa-tester; do
        assert ".claude/agents/$a.md (generated)" "[[ -f '$tmp/.claude/agents/$a.md' ]]"
    done
    for p in $partition_agents; do
        assert ".claude/agents/$p.md (generated partition)" "[[ -f '$tmp/.claude/agents/$p.md' ]]"
    done
    if [[ "$project_type" != "generic" ]]; then
        for s in build test verify; do
            assert ".claude/skills/$s/SKILL.md (generated)" "[[ -f '$tmp/.claude/skills/$s/SKILL.md' ]]"
        done
    fi
    assert ".claude/settings.json (direct binding artifact)" "[[ -f '$tmp/.claude/settings.json' ]]"
    assert "AI-GUIDE.md (v0.10 tool-agnostic entry)" "[[ -f '$tmp/AI-GUIDE.md' ]]"
    assert "CLAUDE.md (v0.10 bootstrap stub)" "[[ -f '$tmp/CLAUDE.md' ]]"
    assert ".github/copilot-instructions.md (v0.10 bootstrap stub)" "[[ -f '$tmp/.github/copilot-instructions.md' ]]"
    assert "copilot-instructions.md has applyTo frontmatter" "head -5 '$tmp/.github/copilot-instructions.md' | grep -q 'applyTo:'"

    # Content correctness
    assert "CLAUDE.md is a stub (references AI-GUIDE.md, no GENERATED marker, small)" \
        "grep -q 'AI-GUIDE.md' '$tmp/CLAUDE.md' && ! grep -q 'GENERATED FILE' '$tmp/CLAUDE.md' && [[ \$(wc -c < '$tmp/CLAUDE.md') -lt 2000 ]]"
    assert "copilot-instructions.md is a stub (references AI-GUIDE.md)" \
        "grep -q 'AI-GUIDE.md' '$tmp/.github/copilot-instructions.md' && [[ \$(wc -c < '$tmp/.github/copilot-instructions.md') -lt 2000 ]]"
    assert "AI-GUIDE.md indexes project-type rule overlay" \
        "grep -q '50-$project_type.md' '$tmp/AI-GUIDE.md'"
    # AI-GUIDE.md indexes EVERY rule file (matches user-project verify_all E.5)
    missing_rules=""
    if [[ -d "$tmp/.harness/rules" ]]; then
        while IFS= read -r r; do
            rname=$(basename "$r")
            grep -q ".harness/rules/$rname" "$tmp/AI-GUIDE.md" || missing_rules="$missing_rules $rname"
        done < <(find "$tmp/.harness/rules" -maxdepth 1 -name '*.md' -type f)
    fi
    assert "AI-GUIDE.md indexes every .harness/rules/*.md file (matches user-project verify_all E.5)" \
        "[[ -z '$missing_rules' ]]"
    [[ -n "$missing_rules" ]] && echo "    Rules NOT indexed:$missing_rules" >&2
    assert "PROJECT_NAME substituted into rules" "grep -q 'test-project' '$tmp/.harness/rules/00-core.md'"
    assert "TODAY substituted into rules" "grep -q '$today' '$tmp/.harness/rules/00-core.md'"
    assert "STACK substituted into rules" "grep -qF '$stack' '$tmp/.harness/rules/00-core.md'"
    assert "PROJECT_NAME substituted into AI-GUIDE.md" "grep -q 'test-project' '$tmp/AI-GUIDE.md'"
    assert "PROJECT_NAME substituted into CLAUDE.md stub" "grep -q 'test-project' '$tmp/CLAUDE.md'"

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

    # Guard-rm + PreToolUse hook wired (v0.15+).
    # Five assertions per project type to match test-init.ps1's granularity
    # (177 total across the 3 project types).
    assert "scripts/guard-rm.ps1 present after init" "[[ -f '$tmp/scripts/guard-rm.ps1' ]]"
    assert "scripts/guard-rm.sh present after init" "[[ -f '$tmp/scripts/guard-rm.sh' ]]"
    # Probe python3 with a real invocation — Windows can have a Microsoft Store
    # stub that satisfies `command -v` but exits non-zero on real run.
    init_have_python=0
    if command -v python3 >/dev/null 2>&1; then
        if echo '' | python3 -c 'pass' >/dev/null 2>&1; then init_have_python=1; fi
    fi
    if (( init_have_python == 1 )); then
        # JSON parses
        if python3 -c "import json; json.load(open('$tmp/.claude/settings.json'))" 2>/dev/null; then
            echo "  PASS  .claude/settings.json parses as JSON"; ((pass++))
        else
            echo "  FAIL  .claude/settings.json parses as JSON" >&2
            ((fail++)); failures+=("settings.json JSON parse")
        fi
        # matcher == Bash
        if python3 -c "
import json
d=json.load(open('$tmp/.claude/settings.json'))
assert d['hooks']['PreToolUse'][0]['matcher']=='Bash'
" 2>/dev/null; then
            echo "  PASS  .claude/settings.json PreToolUse[0].matcher == 'Bash'"; ((pass++))
        else
            echo "  FAIL  .claude/settings.json PreToolUse[0].matcher == 'Bash'" >&2
            ((fail++)); failures+=("settings.json matcher")
        fi
        # command references guard-rm
        if python3 -c "
import json
d=json.load(open('$tmp/.claude/settings.json'))
assert 'guard-rm' in d['hooks']['PreToolUse'][0]['hooks'][0]['command']
" 2>/dev/null; then
            echo "  PASS  .claude/settings.json PreToolUse command references guard-rm"; ((pass++))
        else
            echo "  FAIL  .claude/settings.json PreToolUse command references guard-rm" >&2
            ((fail++)); failures+=("settings.json guard-rm command")
        fi
    else
        # Grep fallback — three separate assertions to match the PS granularity.
        if grep -q '"PreToolUse"' "$tmp/.claude/settings.json"; then
            echo "  PASS  .claude/settings.json parses as JSON (grep: has PreToolUse key)"; ((pass++))
        else
            echo "  FAIL  .claude/settings.json parses as JSON" >&2
            ((fail++)); failures+=("settings.json JSON parse")
        fi
        if grep -q '"matcher"[[:space:]]*:[[:space:]]*"Bash"' "$tmp/.claude/settings.json"; then
            echo "  PASS  .claude/settings.json PreToolUse[0].matcher == 'Bash' (grep)"; ((pass++))
        else
            echo "  FAIL  .claude/settings.json PreToolUse[0].matcher == 'Bash'" >&2
            ((fail++)); failures+=("settings.json matcher")
        fi
        if grep -qE 'guard-rm\.(ps1|sh)' "$tmp/.claude/settings.json"; then
            echo "  PASS  .claude/settings.json PreToolUse command references guard-rm (grep)"; ((pass++))
        else
            echo "  FAIL  .claude/settings.json PreToolUse command references guard-rm" >&2
            ((fail++)); failures+=("settings.json guard-rm command")
        fi
    fi

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

if [[ "$TYPE" == "all" || "$TYPE" == "both" || "$TYPE" == "fullstack" ]]; then
    test_type "fullstack" "Next.js + NestJS + Postgres"
fi
if [[ "$TYPE" == "all" || "$TYPE" == "both" || "$TYPE" == "backend" ]]; then
    test_type "backend" "FastAPI + Postgres"
fi
if [[ "$TYPE" == "all" || "$TYPE" == "generic" ]]; then
    test_type "generic" "Rust CLI tool"
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
