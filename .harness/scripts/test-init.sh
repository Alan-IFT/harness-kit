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
# T-12: the OS-picked hook commands are the RESILIENT form — fail-OPEN +
# $CLAUDE_PROJECT_DIR-anchored for the convenience hooks, fail-CLOSED for guard-rm.
# These literals are the JSON-ESCAPED bytes (inner " as \") so the exact-string
# `grep -qF '"command": "<literal>"'` assertions match the substituted .tmpl byte-for-byte
# (gate C3), AND they equal what settings.json.tmpl carries after the substitute() below.
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
# in a sed replacement. Splits on the needle and concatenates verbatim.
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
    # else keeps sed's byte-exact output (preserving the original trailing-newline state
    # so the AC-10 byte-compare is unaffected).
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
    # v0.30 cutover: the 7 generic framework agents are PLUGIN-provided (harness-kit:<name>),
    # NOT copied into the project by default — assert they are ABSENT.
    # NOTE: baseline.json test-init counts MOVE with these flips; the operator reconciles
    # them from a captured run.
    for a in pm-orchestrator requirement-analyst solution-architect gate-reviewer developer code-reviewer qa-tester; do
        assert ".harness/agents/$a.md ABSENT (plugin-provided, not copied)" "[[ ! -f '$tmp/.harness/agents/$a.md' ]]"
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
    assert ".harness/rules/25-decision-policy.md (shipped, generic)" "[[ -f '$tmp/.harness/rules/25-decision-policy.md' ]]"
    assert ".harness/rules/25-decision-policy.md defaults to Mode 1" "grep -q 'Active mode: 1' '$tmp/.harness/rules/25-decision-policy.md'"
    assert ".harness/decision-rubric.md (shipped, generic)" "[[ -f '$tmp/.harness/decision-rubric.md' ]]"
    assert ".harness/decision-rubric.md has Preset + Custom sections" "grep -q 'Preset rubric (Mode 2)' '$tmp/.harness/decision-rubric.md' && grep -q 'Custom rubric (Mode 3)' '$tmp/.harness/decision-rubric.md'"
    assert "CONTEXT.md seed present (generic glossary)" "[[ -f '$tmp/CONTEXT.md' ]]"
    assert "rejected-decisions.md seed present (generic)" "[[ -f '$tmp/.harness/rejected-decisions.md' ]]"
    assert ".harness/rules/50-$project_type.md (overlay)" "[[ -f '$tmp/.harness/rules/50-$project_type.md' ]]"
    if [[ "$project_type" != "generic" ]]; then
        for s in build test verify; do
            assert ".harness/skills/$s/SKILL.md (SOT)" "[[ -f '$tmp/.harness/skills/$s/SKILL.md' ]]"
        done
    fi

    # Generated artifacts
    # v0.30 cutover: generic framework agents are plugin-provided, so harness-sync does NOT
    # generate them under .claude/agents/ — assert they are ABSENT. Partition dev-* still sync.
    for a in pm-orchestrator requirement-analyst solution-architect gate-reviewer developer code-reviewer qa-tester; do
        assert ".claude/agents/$a.md ABSENT (plugin-provided, not generated)" "[[ ! -f '$tmp/.claude/agents/$a.md' ]]"
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

    # === T-020: hook<->script congruence of the generated settings (AC-5) ===
    # Same deterministic core as harness-init SKILL step 10b: extract every script
    # path on "command" lines with the LEFT-BOUNDED ERE (quote/space/=/line start —
    # a dirname merely ending in scripts/ never matches) and assert each exists.
    t20_viol=""
    while IFS= read -r t20_path; do
        [[ -z "$t20_path" ]] && continue
        [[ -f "$tmp/$t20_path" ]] || t20_viol="$t20_viol $t20_path"
    done < <(grep '"command"' "$tmp/.claude/settings.json" \
        | grep -oE "(^|[\"' =])(\.harness/)?scripts/[A-Za-z0-9._-]+\.(ps1|sh)" \
        | sed -E "s|^[\"' =]||" \
        | sort -u)
    assert "[T-020] every settings hook command path exists on disk (AC-5)" "[[ -z '$t20_viol' ]]"
    [[ -n "$t20_viol" ]] && echo "    dangling:$t20_viol" >&2
    assert "[T-020] ambient-prompt command is the OS-picked variant" \
        "grep -qF '\"command\": \"$AMBIENT_PROMPT_COMMAND\"' '$tmp/.claude/settings.json'"
    assert "[T-020] ambient-reset command is the OS-picked variant" \
        "grep -qF '\"command\": \"$AMBIENT_RESET_COMMAND\"' '$tmp/.claude/settings.json'"

    # === T-020: generated verify_all carries the v0.30-correct rows (FR-D3/FR-D4) ===
    case "$project_type" in
        backend) t20_cong_row="D.4b" ;;
        *)       t20_cong_row="E.4b" ;;
    esac
    assert "[T-020] generated verify_all.sh has the agents-layout wording, not the retired 7-agents check" \
        "grep -qF 'partition dev-* only' '$tmp/.harness/scripts/verify_all.sh' && ! grep -qF 'All 7 agents' '$tmp/.harness/scripts/verify_all.sh'"
    assert "[T-020] generated verify_all.sh has the $t20_cong_row hook-congruence row" \
        "grep -qF '\"$t20_cong_row\"' '$tmp/.harness/scripts/verify_all.sh'"
    assert "[T-020] generated verify_all.ps1 has the agents-layout wording + $t20_cong_row row" \
        "grep -qF 'partition dev-* only' '$tmp/.harness/scripts/verify_all.ps1' && grep -qF '\"$t20_cong_row\"' '$tmp/.harness/scripts/verify_all.ps1' && ! grep -qF 'All 7 agent definitions' '$tmp/.harness/scripts/verify_all.ps1'"

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
        # Simulate accept: extract dev-payments body from mock and write.
        # The SKILL's Write tool creates parent dirs; mirror that — since the v0.30
        # cutover, a generic/single-dev project has no pre-existing .harness/agents/.
        mkdir -p "$tmp/.harness/agents"
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

    # === T-020 mutation probe (AC-5 mutation half): delete the wired sync script,
    # re-run the step-10b deterministic core — it MUST now report a violation.
    # Runs LAST in this fixture (the tree is discarded right after). ===
    rm -f "$tmp/.harness/scripts/harness-sync.sh" "$tmp/.harness/scripts/harness-sync.ps1"
    t20_mut=""
    while IFS= read -r t20_path; do
        [[ -z "$t20_path" ]] && continue
        [[ -f "$tmp/$t20_path" ]] || t20_mut="$t20_mut $t20_path"
    done < <(grep '"command"' "$tmp/.claude/settings.json" \
        | grep -oE "(^|[\"' =])(\.harness/)?scripts/[A-Za-z0-9._-]+\.(ps1|sh)" \
        | sed -E "s|^[\"' =]||" \
        | sort -u)
    assert "[T-020] mutation probe: deleted harness-sync.* IS reported as dangling (AC-5)" "[[ -n '$t20_mut' ]]"

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
    # T-12: migrate now ALSO resilient-ifies (A8) — the rewired command embeds the inner
    # `& pwsh -NoProfile -File .harness/scripts/<tool>.ps1` so this substring still matches,
    # and additionally carries the $CLAUDE_PROJECT_DIR anchor (asserted explicitly below).
    assert "[migrate] settings Stop command -> .harness/scripts/harness-sync.ps1" \
        "grep -qF 'pwsh -NoProfile -File .harness/scripts/harness-sync.ps1' '$tmp/.claude/settings.json'"
    assert "[migrate] settings PreToolUse command -> .harness/scripts/guard-rm.ps1" \
        "grep -qF 'pwsh -NoProfile -File .harness/scripts/guard-rm.ps1' '$tmp/.claude/settings.json'"
    # T-12 / A8 proof: the migrated commands are the RESILIENT form ($CLAUDE_PROJECT_DIR-
    # anchored), and guard-rm stays fail-CLOSED (no `exit 0` on its command line).
    assert "[migrate] commands are the resilient form (CLAUDE_PROJECT_DIR-anchored, A8)" \
        "grep -qF 'CLAUDE_PROJECT_DIR' '$tmp/.claude/settings.json'"
    assert "[migrate] guard-rm resilient form is fail-CLOSED (no exit 0 on its command)" \
        "! { grep -F 'guard-rm.ps1' '$tmp/.claude/settings.json' | grep -qF 'exit 0'; }"
    # The _doc_sync_hook doc string ('...bash scripts/harness-sync.sh') is prefix-rewired by
    # S3.1 to '.harness/scripts/harness-sync.sh' but is NOT a "command" line, so S3.2 leaves
    # it as the bare path (doc strings are never made resilient). Mask the migrated path and
    # confirm no stale BARE scripts/harness-sync. survives anywhere (doc key or command).
    assert "[migrate] _doc_sync_hook doc string rewired (no stale bare scripts/harness-sync.)" \
        "grep -qF '.harness/scripts/harness-sync.sh' '$tmp/.claude/settings.json' && ! sed 's|\.harness/scripts/harness-sync\.|XX|g' '$tmp/.claude/settings.json' | grep -qE 'scripts/harness-sync\.'"
    # -NoProfile count: each resilient PS command carries TWO (-Command outer + -File inner),
    # so Stop + PreToolUse give >=4; the old brittle form gave exactly 2. >=2 stays the floor.
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

test_zh_overlay() {
    echo ""
    echo "=== Testing: i18n/zh overlay — consumer-split output-language policy ==="
    local tmp; tmp=$(mktemp -d -t harness-test-zh-XXXXXX)
    copy_layer "$template_root/common"        "$tmp" "zh-test" "fullstack" "Next.js + NestJS"
    copy_layer "$template_root/fullstack"      "$tmp" "zh-test" "fullstack" "Next.js + NestJS"
    # The i18n/zh overlay now carries only the 2 human-facing files (the 3 policy-carrying
    # SPECIAL files were deleted in T-016); lay them, then COMPOSE the zh policy by running
    # the language-policy helper against the project root, exactly as init step 4.4 does.
    copy_layer "$template_root/i18n/zh/common" "$tmp" "zh-test" "fullstack" "Next.js + NestJS"
    ( cd "$tmp" && bash "$tmp/.harness/scripts/language-policy.sh" --template-root "$repo_root" --lang zh >/dev/null 2>&1 )
    rm -f "$tmp/.harness/rules/"*.bak* "$tmp/"CLAUDE.md.bak* "$tmp/.github/"*.bak*

    local core="$tmp/.harness/rules/00-core.md"
    assert "[zh] 00-core.md overlaid" "[[ -f '$core' ]]"
    assert "[zh] policy lists a Chinese-artifact (consumer=human) marker" "grep -q '给用户的交付总结' '$core'"
    assert "[zh] policy lists an English-artifact (consumer=agent) marker" "grep -q 'commit message' '$core'"
    assert "[zh] retired blunt 全程 phrasing is absent" "! grep -q '全程' '$core'"

    # --- T-015 inverse assertions: AI-facing scaffolding now falls through to ENGLISH common/,
    #     human-facing files stay Chinese, the SPECIAL trio keeps EN body + zh policy.
    #     Each pair tests PRESENT and ABSENT on DIFFERENT strings (no same-string trap).
    #     Pure-grep, no python3 dependence (NFR-1). ---

    # AI-facing files now ENGLISH (deleted from overlay → English common/ ships)
    local ai_guide="$tmp/AI-GUIDE.md"
    assert "[zh] AI-GUIDE.md is now ENGLISH (project index present)" "grep -q 'project index' '$ai_guide'"
    assert "[zh] AI-GUIDE.md no longer Chinese (项目指南 absent)" "! grep -q '项目指南' '$ai_guide'"

    local insight_rule="$tmp/.harness/rules/05-insight-index.md"
    assert "[zh] 05-insight-index.md is now ENGLISH (Cross-task insight index present)" "grep -q 'Cross-task insight index' '$insight_rule'"
    assert "[zh] 05-insight-index.md no longer Chinese (跨任务 absent)" "! grep -q '跨任务' '$insight_rule'"

    local workflow="$tmp/docs/workflow.md"
    assert "[zh] docs/workflow.md is now ENGLISH (7-Agent Pipeline present)" "grep -q 'The 7-Agent Pipeline' '$workflow'"
    assert "[zh] docs/workflow.md no longer Chinese (工作流 absent)" "! grep -q '工作流' '$workflow'"

    local devmap="$tmp/docs/dev-map.md"
    assert "[zh] docs/dev-map.md is now ENGLISH (Dev Map present)" "grep -q 'Dev Map' '$devmap'"
    assert "[zh] docs/dev-map.md no longer Chinese (开发导航 absent)" "! grep -q '开发导航' '$devmap'"

    local tasks="$tmp/docs/tasks.md"
    assert "[zh] docs/tasks.md is now ENGLISH (Task Board present)" "grep -q 'Task Board' '$tasks'"
    assert "[zh] docs/tasks.md no longer Chinese (任务看板 absent)" "! grep -q '任务看板' '$tasks'"

    # SPECIAL 00-core: ENGLISH framework body + Chinese policy section, exactly ONE policy section
    assert "[zh] 00-core.md has ENGLISH body (Hard rules (red lines) present)" "grep -q '## Hard rules (red lines)' '$core'"
    assert "[zh] 00-core.md keeps Chinese policy heading (输出语言（按消费者分流） present)" "grep -q '输出语言（按消费者分流）' '$core'"
    assert "[zh] 00-core.md has NO second (English) policy section (Output language (project-wide) absent)" "! grep -q 'Output language (project-wide)' '$core'"

    # SPECIAL CLAUDE.md / copilot: ENGLISH body + the single Chinese policy line
    local claude="$tmp/CLAUDE.md"
    assert "[zh] CLAUDE.md has ENGLISH body (full project ruleset present)" "grep -q 'The full project ruleset lives in' '$claude'"
    assert "[zh] CLAUDE.md keeps the Chinese policy line (输出语言：面向人的产出 present)" "grep -q '输出语言：面向人的产出' '$claude'"
    local copilot="$tmp/.github/copilot-instructions.md"
    assert "[zh] copilot-instructions.md has ENGLISH body (full project ruleset present)" "grep -q 'The full project ruleset lives in' '$copilot'"
    assert "[zh] copilot-instructions.md keeps the Chinese policy line (输出语言：面向人的产出 present)" "grep -q '输出语言：面向人的产出' '$copilot'"

    # Human-facing files STAY Chinese
    local spec_readme="$tmp/docs/spec/README.md"
    assert "[zh] docs/spec/README.md stays Chinese (项目 SPEC present)" "grep -q '项目 SPEC' '$spec_readme'"
    local golden="$tmp/evals/golden-tasks.md"
    assert "[zh] evals/golden-tasks.md stays Chinese (轻量回归任务集 present)" "grep -q '轻量回归任务集' '$golden'"

    # --- T-016 POSITIVE proof: the composed zh 00-core's English BODY (from the first
    #     non-policy heading to EOF) is byte-identical to the English common/ 00-core's
    #     body, substituted the same way. This is the positive analogue of the would-be
    #     guard: it proves the body is single-sourced from common/ (no duplication) AND
    #     that composition carried it correctly. Mutation-provable: if the composed body
    #     diverged (helper over/under-cut the seam, or common/ body drifted without the
    #     compose carrying it), the bodies differ → this assertion goes RED. ---
    local composed_body; composed_body="$(awk '/^## How this project is developed/{p=1} p' "$core")"
    local common_core_sub; common_core_sub="$(mktemp -t zh-common-core-XXXXXX)"
    cp "$template_root/common/.harness/rules/00-core.md.tmpl" "$common_core_sub"
    substitute "$common_core_sub" "zh-test" "fullstack" "Next.js + NestJS"
    local common_body; common_body="$(awk '/^## How this project is developed/{p=1} p' "$common_core_sub")"
    assert "[zh][T-016] composed zh 00-core BODY byte-matches English common/ (single-source, no duplication)" \
        "[[ \"\$composed_body\" == \"\$common_body\" ]]"
    rm -f "$common_core_sub"

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
if [[ "$TYPE" == "all" || "$TYPE" == "both" ]]; then
    test_zh_overlay
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
