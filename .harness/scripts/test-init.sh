#!/usr/bin/env bash
# test-init.sh — Automated regression for /harness-init (v0.2)
# Mirror of .harness/scripts/test-init.ps1. See that file for full doc.

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

# Script lives at .harness/scripts/ — repo root is two levels up.
repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
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
        SYNC_COMMAND="pwsh -NoProfile -File .harness/scripts/harness-sync.ps1"
        GUARD_COMMAND="pwsh -NoProfile -File .harness/scripts/guard-rm.ps1"
        ;;
    *)
        SYNC_COMMAND="bash .harness/scripts/harness-sync.sh"
        GUARD_COMMAND="bash .harness/scripts/guard-rm.sh"
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
    assert "harness-sync.sh was distributed" "[[ -f '$tmp/.harness/scripts/harness-sync.sh' ]]"
    if [[ -f "$tmp/.harness/scripts/harness-sync.sh" ]]; then
        if bash "$tmp/.harness/scripts/harness-sync.sh" &>/dev/null; then
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
    for f in docs/workflow.md docs/dev-map.md docs/tasks.md docs/spec/README.md evals/golden-tasks.md .harness/scripts/verify_all.ps1 .harness/scripts/verify_all.sh .harness/scripts/harness-sync.ps1; do
        assert "$f present" "[[ -f '$tmp/$f' ]]"
    done

    # AC-1 (T-007): harness scripts live under .harness/scripts/, NOT scripts/.
    # The generated tree must have no scripts/ dir and no harness file leaked there.
    assert "[AC-1] generated tree has no scripts/ directory" "[[ ! -d '$tmp/scripts' ]]"
    assert "[AC-1] no harness script leaked under scripts/" \
        "[[ ! -f '$tmp/scripts/verify_all.ps1' && ! -f '$tmp/scripts/verify_all.sh' && ! -f '$tmp/scripts/harness-sync.ps1' && ! -f '$tmp/scripts/harness-sync.sh' && ! -f '$tmp/scripts/guard-rm.ps1' && ! -f '$tmp/scripts/guard-rm.sh' && ! -f '$tmp/scripts/baseline.json' ]]"

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
    assert ".harness/scripts/guard-rm.ps1 present after init" "[[ -f '$tmp/.harness/scripts/guard-rm.ps1' ]]"
    assert ".harness/scripts/guard-rm.sh present after init" "[[ -f '$tmp/.harness/scripts/guard-rm.sh' ]]"
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
    if bash "$tmp/.harness/scripts/harness-sync.sh" --check &>/dev/null; then
        echo "  PASS  harness-sync --check is clean after init"; ((pass++))
    else
        echo "  FAIL  harness-sync --check is clean after init" >&2; ((fail++))
        failures+=("binding drift right after init")
    fi

    # === AI-native init/adopt (v0.16+) ===
    # Bidirectional: opt-out path must be byte-identical to v0.15.1 (AC-10);
    # opt-in path must produce a tailored 50-<slug>.md with all four invariants
    # satisfied. See design §10 for the assertions per project type.
    assert "[AI-out] .harness/rules/50-$project_type.md is present (static stub, opt-out path)" \
        "[[ -f '$tmp/.harness/rules/50-$project_type.md' ]]"
    assert "[AI-out] .harness/rules/50-test-project.md is NOT present (opt-out leaves stub in place)" \
        "[[ ! -f '$tmp/.harness/rules/50-test-project.md' ]]"

    # === AC-10 byte-compare (rollback round 1, M-2 + M-3) ===
    # Discrete "Q6=No, full init, end state" pass in its own temp dir, with no
    # AI-native simulation touching it. Byte-compare the resulting
    # .harness/rules/50-<type>.md against the source template (post-substitution
    # for the generic .md.tmpl case). v0.15.1 shipped these exact bytes; the
    # static templates ARE the v0.15.1 reference.
    optout_tmp=$(mktemp -d -t harness-test-optout-XXXXXX)
    # Re-run the same template-copy + substitution flow used in real init,
    # but skip harness-sync and skip the AI-native simulation — this is the
    # pure Q6=No end state.
    copy_layer "$template_root/common" "$optout_tmp" "test-project" "$project_type" "$stack"
    copy_layer "$template_root/$project_type" "$optout_tmp" "test-project" "$project_type" "$stack"

    src_static="$template_root/$project_type/.harness/rules/50-$project_type.md"
    src_tmpl="$template_root/$project_type/.harness/rules/50-$project_type.md.tmpl"
    expected_file="$optout_tmp/_expected_50.md"
    if [[ -f "$src_static" ]]; then
        cp "$src_static" "$expected_file"
    elif [[ -f "$src_tmpl" ]]; then
        cp "$src_tmpl" "$expected_file"
        substitute "$expected_file" "test-project" "$project_type" "$stack"
    else
        : > "$expected_file"  # empty sentinel; assertion will detect
    fi
    actual_file="$optout_tmp/.harness/rules/50-$project_type.md"
    # cmp -s exits 0 iff byte-identical. Also assert the expected file isn't
    # empty (catches the "no source template found" sentinel above).
    assert "[AC-10] opt-out 50-$project_type.md is byte-identical to source template (v0.15.1 reference, fresh temp dir)" \
        "[[ -s '$expected_file' && -f '$actual_file' ]] && cmp -s '$expected_file' '$actual_file'"
    rm -rf "$optout_tmp"

    mock_fixture="$tmp/.harness/scripts/ai-native-mock.json"
    assert "[AI-in] mock fixture present after init (templates/common ships it)" "[[ -f '$mock_fixture' ]]"

    # The skill's step 5b runs INSIDE the orchestrator, not as a Bash call;
    # this block mirrors its logic so test-init can exercise the same invariants
    # offline. Python3 required to parse the JSON; gate matches existing
    # init_have_python pattern from the guard-rm assertions above.
    ain_have_python=0
    if command -v python3 >/dev/null 2>&1; then
        if echo '' | python3 -c 'pass' >/dev/null 2>&1; then ain_have_python=1; fi
    fi

    if (( ain_have_python == 1 )) && [[ -f "$mock_fixture" ]]; then
        export HARNESS_AI_NATIVE_MOCK="$mock_fixture"

        # Validate four invariants via python; emit a small status file we can
        # check from bash.
        ain_status=$(python3 - "$mock_fixture" <<'PYEOF'
import json, sys
mock = json.load(open(sys.argv[1]))
rm = mock.get("rule_md","")
required = [
    "## When to read",
    "## Build / test / verify",
    "## Project structure",
    "## Stack-specific conventions",
    "## Partitioning",
    "## Stack-specific verify_all checks",
]
inv1 = True
idx = 0
for h in required:
    i = rm.find(h, idx)
    if i < 0: inv1 = False; break
    idx = i + len(h)
import re
inv2 = re.search(r"\{\{[A-Z_]+\}\}", rm) is None
inv3 = len(rm.splitlines()) <= 200
sources = re.findall(r"<!-- source: ([^ >]+) -->", rm)
print("inv1=%s inv2=%s inv3=%s n_sources=%d" % (inv1, inv2, inv3, len(sources)))
PYEOF
)
        inv1=$(echo "$ain_status" | grep -oE 'inv1=[A-Za-z]+' | cut -d= -f2)
        inv2=$(echo "$ain_status" | grep -oE 'inv2=[A-Za-z]+' | cut -d= -f2)
        inv3=$(echo "$ain_status" | grep -oE 'inv3=[A-Za-z]+' | cut -d= -f2)
        n_sources=$(echo "$ain_status" | grep -oE 'n_sources=[0-9]+' | cut -d= -f2)

        slug="test-project"
        opt_in_rule="$tmp/.harness/rules/50-$slug.md"
        static_stub="$tmp/.harness/rules/50-$project_type.md"
        ai_guide="$tmp/AI-GUIDE.md"

        # Apply the AI-native opt-in transformation (steps 5b.6 / 5b.7 / 5b.8)
        if [[ "$inv1" == "True" && "$inv2" == "True" ]]; then
            python3 - "$mock_fixture" "$opt_in_rule" <<'PYEOF'
import json, sys
mock = json.load(open(sys.argv[1]))
open(sys.argv[2], "w", encoding="utf-8").write(mock["rule_md"])
PYEOF
            rm -f "$static_stub"
            # Edit AI-GUIDE.md to swap the index line
            python3 - "$ai_guide" "$project_type" "$slug" <<'PYEOF'
import sys
path, ptype, slug = sys.argv[1], sys.argv[2], sys.argv[3]
content = open(path, "r", encoding="utf-8").read()
content = content.replace("50-%s.md" % ptype, "50-%s.md" % slug)
open(path, "w", encoding="utf-8").write(content)
PYEOF
        fi

        # 14 assertions per design §10 (numbered to match test-init.ps1)
        assert "[AI-in] (3) 50-$slug.md exists after opt-in apply" "[[ -f '$opt_in_rule' ]]"
        assert "[AI-in] (4) 50-$project_type.md does NOT exist (replaced by 50-$slug.md)" "[[ ! -f '$static_stub' ]]"
        assert "[AI-in] (5) opt-in file contains no <your build/test/linter> placeholders" \
            "! grep -qE '<your build command>|<your test command>|<your linter>' '$opt_in_rule'"
        assert "[AI-in] (6) opt-in file has all six required headings present in order" "[[ '$inv1' == 'True' ]]"
        assert "[AI-in] (7) opt-in file has >=1 <!-- source: ... --> annotation" "(( $n_sources >= 1 ))"
        assert "[AI-in] (8) AI-GUIDE.md references 50-$slug.md, NOT 50-$project_type.md" \
            "grep -qF '50-$slug.md' '$ai_guide' && ! grep -qF '.harness/rules/50-$project_type.md' '$ai_guide'"
        assert "[AI-in] (9) opt-in file has zero {{...}} literals (D.2 protection)" "[[ '$inv2' == 'True' ]]"
        assert "[AI-in] (10) opt-in file has line count <=200" "[[ '$inv3' == 'True' ]]"

        # Mock-error path (11): unreadable mock → fallback. We just verify the
        # detection logic; static stub is already gone from the apply above, so
        # use a sub-temp.
        err_tmp=$(mktemp -d -t harness-test-mockerr-XXXXXX)
        echo "# stub" > "$err_tmp/50-$project_type.md"
        export HARNESS_AI_NATIVE_MOCK="$err_tmp/does-not-exist.json"
        assert "[AI-in] (11) mock-error path: unreadable mock detected, static stub preserved (fallback)" \
            "[[ ! -f \$HARNESS_AI_NATIVE_MOCK && -f '$err_tmp/50-$project_type.md' ]]"
        rm -rf "$err_tmp"

        # Partition acceptance / rejection (12 + 13)
        assert "[AI-in] (12) partition draft NOT written under reject decision (no agent file before accept)" \
            "[[ ! -f '$tmp/.harness/agents/dev-payments.md' ]]"
        # Simulate accept: extract dev-payments body from mock and write
        python3 - "$mock_fixture" "$tmp/.harness/agents/dev-payments.md" <<'PYEOF'
import json, sys
mock = json.load(open(sys.argv[1]))
for p in mock.get("partition_agents", []):
    if p["name"] == "dev-payments":
        open(sys.argv[2], "w", encoding="utf-8").write(p["body"])
        break
PYEOF
        assert "[AI-in] (13) partition draft IS written under accept decision (dev-payments.md present)" \
            "[[ -f '$tmp/.harness/agents/dev-payments.md' ]]"

        # Reserved-name collision (14): a mock proposing 'developer' must be dropped.
        # We simulate the filter result, since the live code path is inside the skill.
        filter_result=$(python3 - <<'PYEOF'
reserved = {"pm-orchestrator","requirement-analyst","solution-architect","gate-reviewer","developer","code-reviewer","qa-tester"}
proposed = [{"name":"developer"},{"name":"dev-realtime"}]
remaining = [p for p in proposed if p["name"] not in reserved]
print(len(remaining), remaining[0]["name"] if remaining else "")
PYEOF
)
        assert "[AI-in] (14) reserved-name collision: proposed 'developer' is filtered out before write" \
            "[[ '$filter_result' == '1 dev-realtime' ]]"

        unset HARNESS_AI_NATIVE_MOCK
    else
        # Python missing — skip AI-native block (mirrors existing init_have_python gate)
        echo "  SKIP  [AI-native block — python3 required, not available]"
    fi

    if [[ "$KEEP" == true ]]; then
        echo ""
        echo "Temp dir kept: $tmp"
    else
        rm -rf "$tmp"
    fi
}

test_migrate() {
    # AC-5 (T-007): downgrade-then-migrate regression for migrate-scripts-layout.sh.
    echo ""
    echo "=== Testing: migrate-scripts-layout (downgrade-then-migrate) ==="
    local tmp; tmp=$(mktemp -d -t harness-test-migrate-XXXXXX)
    copy_layer "$template_root/common" "$tmp" "migrate-test" "generic" "Rust CLI tool"
    copy_layer "$template_root/generic" "$tmp" "migrate-test" "generic" "Rust CLI tool"

    (
        cd "$tmp" || exit 1
        git init -q 2>/dev/null

        # Synthetic downgrade: move .harness/scripts/* back to scripts/*
        mkdir -p scripts
        for n in verify_all.ps1 verify_all.sh harness-sync.ps1 harness-sync.sh guard-rm.ps1 guard-rm.sh; do
            [[ -f ".harness/scripts/$n" ]] && mv ".harness/scripts/$n" "scripts/$n"
        done
        # baseline.json isn't a template file (generated post-init); synthesize one at
        # the OLD path (scripts/) so the helper's baseline.json move branch is exercised.
        echo '{"test_count":0}' > scripts/baseline.json
        echo "echo deploy" > scripts/deploy.sh   # user-authored — must NOT move
        mkdir -p .claude
        # OLD-layout settings.json (pre-T-007 paths) so the helper has a genuine rewrite.
        cat > .claude/settings.json <<'SETTINGS'
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "_doc_sync_hook": "On macOS/Linux change the Stop hook command to: bash scripts/harness-sync.sh",
  "permissions": { "allow": [ "Bash(bash scripts/harness-sync.sh:*)" ] },
  "hooks": {
    "Stop": [ { "hooks": [ { "type": "command", "command": "pwsh -NoProfile -File scripts/harness-sync.ps1" } ] } ],
    "PreToolUse": [ { "matcher": "Bash", "hooks": [ { "type": "command", "command": "pwsh -NoProfile -File scripts/guard-rm.ps1" } ] } ]
  }
}
SETTINGS
        git add -A 2>/dev/null; git -c user.email=t@t -c user.name=t commit -qm downgrade 2>/dev/null
    )

    local helper="$tmp/.harness/scripts/migrate-scripts-layout.sh"
    assert "[migrate] helper present after init" "[[ -f '$helper' ]]"

    ( cd "$tmp" && bash "$helper" >/dev/null 2>&1 )
    assert "[migrate] exit 0" "( cd '$tmp' && bash '$helper' >/dev/null 2>&1 )"  # second invocation also clean

    assert "[migrate] .harness/scripts/verify_all.sh present" "[[ -f '$tmp/.harness/scripts/verify_all.sh' ]]"
    assert "[migrate] .harness/scripts/harness-sync.sh present" "[[ -f '$tmp/.harness/scripts/harness-sync.sh' ]]"
    assert "[migrate] .harness/scripts/baseline.json present" "[[ -f '$tmp/.harness/scripts/baseline.json' ]]"
    assert "[migrate] OLD scripts/harness-sync.sh vacated" "[[ ! -f '$tmp/scripts/harness-sync.sh' ]]"
    assert "[migrate] OLD scripts/guard-rm.ps1 vacated" "[[ ! -f '$tmp/scripts/guard-rm.ps1' ]]"
    assert "[migrate] OLD scripts/baseline.json vacated" "[[ ! -f '$tmp/scripts/baseline.json' ]]"
    assert "[migrate] user-authored scripts/deploy.sh NOT moved" "[[ -f '$tmp/scripts/deploy.sh' ]]"
    assert "[migrate] settings Stop command -> .harness/scripts/harness-sync.ps1" \
        "grep -qF 'pwsh -NoProfile -File .harness/scripts/harness-sync.ps1' '$tmp/.claude/settings.json'"
    assert "[migrate] settings PreToolUse command -> .harness/scripts/guard-rm.ps1" \
        "grep -qF 'pwsh -NoProfile -File .harness/scripts/guard-rm.ps1' '$tmp/.claude/settings.json'"
    assert "[migrate] _doc_sync_hook doc string rewired (no stale bare scripts/harness-sync.)" \
        "grep -qF '.harness/scripts/harness-sync.sh' '$tmp/.claude/settings.json' && ! sed 's|\.harness/scripts/harness-sync\.|XX|g' '$tmp/.claude/settings.json' | grep -qE 'scripts/harness-sync\.'"
    assert "[migrate] -NoProfile retained (>=2 hits)" \
        "(( \$(grep -c -- '-NoProfile' '$tmp/.claude/settings.json') >= 2 ))"
    assert "[migrate] \$schema unchanged" \
        "grep -qF 'json.schemastore.org/claude-code-settings.json' '$tmp/.claude/settings.json'"
    assert "[migrate] a .bak backup was written" \
        "ls '$tmp/.claude/'settings.json.bak-* >/dev/null 2>&1"

    # Idempotency: count .bak before a fresh run; a clean no-op writes none.
    local bak_before; bak_before=$(ls "$tmp/.claude/"settings.json.bak-* 2>/dev/null | wc -l)
    ( cd "$tmp" && bash "$helper" >/dev/null 2>&1 )
    local bak_after; bak_after=$(ls "$tmp/.claude/"settings.json.bak-* 2>/dev/null | wc -l)
    assert "[migrate] second run wrote NO new .bak (true no-op)" "[[ '$bak_before' == '$bak_after' ]]"

    [[ "$KEEP" == true ]] && echo "Temp dir kept: $tmp" || rm -rf "$tmp"
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
if [[ "$TYPE" == "all" || "$TYPE" == "both" ]]; then
    test_migrate
fi

# BUG-2 regression (v0.16.0 rollback round 2): verify the broadened D.2/D.3
# regex catches whitespace-padded and lowercase placeholder variants that the
# v0.15.1 pattern '\{\{[A-Z_]+\}\}' missed. Single-shot in-process unit test;
# runs once regardless of $TYPE to keep coverage small but explicit. Uses ERE
# matching the verify_all.sh pattern.
broadened_regex='\{\{[[:space:]]*[A-Za-z_][A-Za-z0-9_]*[[:space:]]*\}\}'
echo ""
echo "=== BUG-2 regression: broadened placeholder regex ==="
assert "[BUG-2] broadened regex catches whitespace-padded '{{ PROJECT_NAME }}'" \
    "printf '%s' '{{ PROJECT_NAME }}' | grep -qE '$broadened_regex'"
assert "[BUG-2] broadened regex catches lowercase '{{project_name}}'" \
    "printf '%s' '{{project_name}}' | grep -qE '$broadened_regex'"

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
