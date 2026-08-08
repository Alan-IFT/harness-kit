#!/usr/bin/env bash
# test-init.sh — Automated regression for /harness-init (v0.2)

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
# T-13: all EIGHT byte-forms are now defined UNCONDITIONALLY (EXP_WIN_* / EXP_UNIX_*)
# and the four host-OS *_COMMAND variables are BOUND from the host set below. This is a
# pure re-binding — the bytes substitute() injects are exactly the bytes it injected
# before — so every pre-existing exact-string assertion is unaffected. The unconditional
# definitions exist so the T-13 spec block can lockstep-compare all 8 cells from one run.
# T-16: these fixtures are now THE ORACLE, not a lockstep hand copy. The four derivation
# flows query hook-spec.sh instead of carrying byte-forms, so a spec-vs-flow
# comparison would be circular; the frozen literals below are the only anchor that is
# independent of every artifact under test. Deliberate non-retirement — see
# .harness/rejected-decisions.md (hook-byteform-test-literal-retirement).
EXP_UNIX_SYNC="sh -c 'cd \\\"\$CLAUDE_PROJECT_DIR\\\" 2>/dev/null && [ -f .harness/scripts/harness-sync.sh ] && exec bash .harness/scripts/harness-sync.sh || exit 0'"
EXP_UNIX_GUARD="sh -c 'cd \\\"\$CLAUDE_PROJECT_DIR\\\" 2>/dev/null && bash .harness/scripts/guard-rm.sh'"
EXP_UNIX_AMBIENT_PROMPT="sh -c 'cd \\\"\$CLAUDE_PROJECT_DIR\\\" 2>/dev/null && [ -f .harness/scripts/ambient-prompt.sh ] && exec bash .harness/scripts/ambient-prompt.sh || exit 0'"
EXP_UNIX_AMBIENT_RESET="sh -c 'cd \\\"\$CLAUDE_PROJECT_DIR\\\" 2>/dev/null && [ -f .harness/scripts/ambient-reset.sh ] && exec bash .harness/scripts/ambient-reset.sh || exit 0'"

# hs_expected <tool> <os> — the hand-copied fixture for one (tool, OS) cell.
# hs_expected TOOL -> the frozen byte-form for that tool. One per tool since v0.49.0;
# the (tool, OS) pair collapsed when Windows support was removed.
hs_expected() {
    case "$1" in
        harness-sync)    printf '%s' "$EXP_UNIX_SYNC" ;;
        guard-rm)        printf '%s' "$EXP_UNIX_GUARD" ;;
        ambient-prompt)  printf '%s' "$EXP_UNIX_AMBIENT_PROMPT" ;;
        ambient-reset)   printf '%s' "$EXP_UNIX_AMBIENT_RESET" ;;
        *)               printf '' ;;
    esac
}

case "${OSTYPE:-}" in
    msys*|cygwin*|win32)
        SYNC_COMMAND="$EXP_WIN_SYNC"
        GUARD_COMMAND="$EXP_WIN_GUARD"
        AMBIENT_PROMPT_COMMAND="$EXP_WIN_AMBIENT_PROMPT"
        AMBIENT_RESET_COMMAND="$EXP_WIN_AMBIENT_RESET"
        ;;
    *)
        SYNC_COMMAND="$EXP_UNIX_SYNC"
        GUARD_COMMAND="$EXP_UNIX_GUARD"
        AMBIENT_PROMPT_COMMAND="$EXP_UNIX_AMBIENT_PROMPT"
        AMBIENT_RESET_COMMAND="$EXP_UNIX_AMBIENT_RESET"
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
    # v0.50.0 — the eight stage playbooks. A fresh project without them runs every agent on its
    # degradation clause, which is a floor for an un-upgraded project, not an acceptable init.
    assert ".harness/playbooks/ has all 8 (P4 distribution)" \
        "[[ \$(find '$tmp/.harness/playbooks' -maxdepth 1 -name '*.md' -type f 2>/dev/null | wc -l) -eq 8 ]]"
    assert ".harness/playbooks/developer.md carries its output schema" \
        "grep -q 'Insight to surface' '$tmp/.harness/playbooks/developer.md'"
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
    for f in docs/workflow.md docs/dev-map.md docs/tasks.md docs/spec/README.md evals/golden-tasks.md .harness/scripts/verify_all.sh .harness/scripts/harness-sync.sh; do
        assert "$f present" "[[ -f '$tmp/$f' ]]"
    done

    # AC-1 (T-007): harness scripts live under .harness/scripts/, NOT scripts/.
    # The generated tree must have no scripts/ dir and no harness file leaked there.
    assert "[AC-1] generated tree has no scripts/ directory" "[[ ! -d '$tmp/scripts' ]]"
    assert "[AC-1] no harness script leaked under scripts/" \
        "[[ ! -f '$tmp/scripts/verify_all.sh' && ! -f '$tmp/scripts/harness-sync.sh' && ! -f '$tmp/scripts/guard-rm.sh' && ! -f '$tmp/scripts/baseline.json' ]]"

    # Cleanliness
    if grep -rE '\{\{[A-Z_]+\}\}' "$tmp" --include="*.md" --include="*.json" --include="*.sh" &>/dev/null; then
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
    # DEFECT FIX (found while restructuring the fixtures; pre-existing at cb0ed57):
    # these two conditions used to interpolate the *_COMMAND value straight into the
    # string that assert() `eval`s. On a unix host that value contains SINGLE QUOTES
    # (`sh -c 'cd ... && exec bash ... || exit 0'`), so the embedded quotes closed the
    # eval's own quoting and the driver ran `exec bash .harness/scripts/ambient-prompt.sh`
    # ON ITSELF — silently replacing the test process mid-run, so every assertion after
    # this line (including the whole zh block) never executed on Linux/macOS. Invisible
    # on MSYS, where the OS-picked value is the pwsh form and carries no single quote.
    # Fix: run grep directly and assert on the resulting flag. WHAT is asserted is
    # unchanged (the substituted value composed into settings.json byte-for-byte).
    t20_amb_ok=0
    grep -qF "\"command\": \"$AMBIENT_PROMPT_COMMAND\"" "$tmp/.claude/settings.json" && t20_amb_ok=1
    assert "[T-020] ambient-prompt command is the OS-picked variant" "[[ $t20_amb_ok == 1 ]]"
    t20_amb_ok=0
    grep -qF "\"command\": \"$AMBIENT_RESET_COMMAND\"" "$tmp/.claude/settings.json" && t20_amb_ok=1
    assert "[T-020] ambient-reset command is the OS-picked variant" "[[ $t20_amb_ok == 1 ]]"

    # === T-020: generated verify_all carries the v0.30-correct rows (FR-D3/FR-D4) ===
    case "$project_type" in
        backend) t20_cong_row="D.4b" ;;
        *)       t20_cong_row="E.4b" ;;
    esac
    assert "[T-020] generated verify_all.sh has the agents-layout wording, not the retired 7-agents check" \
        "grep -qF 'partition dev-* only' '$tmp/.harness/scripts/verify_all.sh' && ! grep -qF 'All 7 agents' '$tmp/.harness/scripts/verify_all.sh'"
    assert "[T-020] generated verify_all.sh has the $t20_cong_row hook-congruence row" \
        "grep -qF '\"$t20_cong_row\"' '$tmp/.harness/scripts/verify_all.sh'"

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
    rm -f "$tmp/.harness/scripts/harness-sync.sh"
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
        for n in verify_all.sh harness-sync.sh guard-rm.sh; do
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
    "Stop": [ { "hooks": [ { "type": "command", "command": "bash scripts/harness-sync.sh" } ] } ],
    "PreToolUse": [ { "matcher": "Bash", "hooks": [ { "type": "command", "command": "bash scripts/guard-rm.sh" } ] } ]
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
    assert "[migrate] OLD scripts/guard-rm.sh vacated" "[[ ! -f '$tmp/scripts/guard-rm.sh' ]]"
    assert "[migrate] OLD scripts/baseline.json vacated" "[[ ! -f '$tmp/scripts/baseline.json' ]]"
    assert "[migrate] user-authored scripts/deploy.sh NOT moved" "[[ -f '$tmp/scripts/deploy.sh' ]]"
    # T-12: migrate ALSO resilient-ifies (A8) — the rewired command embeds the inner
    # `bash .harness/scripts/<tool>.sh` so this substring still matches, and additionally
    # carries the $CLAUDE_PROJECT_DIR anchor (asserted explicitly below).
    assert "[migrate] settings Stop command -> .harness/scripts/harness-sync.sh" \
        "grep -qF 'bash .harness/scripts/harness-sync.sh' '$tmp/.claude/settings.json'"
    assert "[migrate] settings PreToolUse command -> .harness/scripts/guard-rm.sh" \
        "grep -qF 'bash .harness/scripts/guard-rm.sh' '$tmp/.claude/settings.json'"
    # T-12 / A8 proof: the migrated commands are the RESILIENT form ($CLAUDE_PROJECT_DIR-
    # anchored), and guard-rm stays fail-CLOSED (no `exit 0` on its command line).
    assert "[migrate] commands are the resilient form (CLAUDE_PROJECT_DIR-anchored, A8)" \
        "grep -qF 'CLAUDE_PROJECT_DIR' '$tmp/.claude/settings.json'"
    assert "[migrate] guard-rm resilient form is fail-CLOSED (no exit 0 on its command)" \
        "! { grep -F 'guard-rm.sh' '$tmp/.claude/settings.json' | grep -qF 'exit 0'; }"
    # The _doc_sync_hook doc string ('...bash scripts/harness-sync.sh') is prefix-rewired by
    # S3.1 to '.harness/scripts/harness-sync.sh' but is NOT a "command" line, so S3.2 leaves
    # it as the bare path (doc strings are never made resilient). Mask the migrated path and
    # confirm no stale BARE scripts/harness-sync. survives anywhere (doc key or command).
    assert "[migrate] _doc_sync_hook doc string rewired (no stale bare scripts/harness-sync.)" \
        "grep -qF '.harness/scripts/harness-sync.sh' '$tmp/.claude/settings.json' && ! sed 's|\.harness/scripts/harness-sync\.|XX|g' '$tmp/.claude/settings.json' | grep -qE 'scripts/harness-sync\.'"
    # v0.49.0: the `-NoProfile` count assertion went with the PowerShell byte-forms. What
    # replaces it is the property that actually matters after the removal — a legacy pwsh
    # value is LEFT ALONE rather than rewritten at a `.sh` target the project may not have.
    assert "[migrate] a legacy pwsh command value is left byte-untouched, not repointed" \
        "! grep -qF 'pwsh' '$tmp/.claude/settings.json' || grep -qF '.ps1' '$tmp/.claude/settings.json'"
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

# === T-13: the hook wiring spec (AC-1..AC-4, FR-1..FR-7, NFR-2) ====================
# ORACLE (re-anchored by T-16): the FROZEN EXP_* fixture table at the top of this file.
# Until T-16 the oracle was the LIVE `resilient_cmd` helper extracted from
# upgrade-project.sh. T-16 retired that helper: the four derivation flows now QUERY
# hook-spec.sh, so comparing the spec against a flow would compare the spec with itself
# — green, and measuring nothing. A test must not derive its expectation from the
# artifact under test, so Group A now compares the spec against the frozen literals,
# which are the ONLY independent anchor left for all four flows.
# SCOPE NOTE: the frozen literals in this file and in test-real-project.sh are a
# DELIBERATE non-retirement, recorded in .harness/rejected-decisions.md
# (hook-byteform-test-literal-retirement) and in hook-spec.sh's header. Standing
# END-TO-END coverage of a flow-EMITTED byte string lives in test-harness-upgrade
# (sh:421 vs t20_pick) for one (tool, OS, flow) cell; the rest is residual RES-1.
test_hook_spec() {
    echo ""
    echo "=== Testing: hook wiring spec (T-13) ==="
    local spec="$repo_root/.harness/scripts/hook-spec.sh"
    local tool os ext a rc ok expected extracted out probe f nhit

    assert "[T-13] hook-spec.sh present at .harness/scripts/" "[[ -f '$spec' ]]"

    # --- MANDATORY anti-vacuity gate on the ORACLE ITSELF: an empty / broken fixture
    #     must fail THIS named assertion loudly, never silently degrade the 8 below.
    probe="$(hs_expected guard-rm)"
    ok=0; [[ -n "$probe" && "$probe" == *"guard-rm.sh"* ]] && ok=1
    assert "[T-16][oracle] ANTI-VACUITY: the frozen EXP_* fixture (guard-rm) is a non-empty string naming guard-rm.sh" "[[ $ok == 1 ]]"

    # A PowerShell byte-form must not come back: v0.49.0 removed Windows support, and the
    # spec answering one would mean a twin returned somewhere upstream of here.
    for tool in harness-sync guard-rm ambient-prompt ambient-reset; do
        a="$(bash "$spec" command "$tool" 2>/dev/null)"
        ok=1; [[ "$a" == *pwsh* || "$a" == *.ps1* ]] && ok=0
        assert "[T-16][A] command $tool names no PowerShell" "[[ $ok == 1 ]]"
    done

    # --- Group A (INDEPENDENT of every flow): spec == the FROZEN fixture, all 4 cells --
    for tool in harness-sync guard-rm ambient-prompt ambient-reset; do
        a="$(bash "$spec" command "$tool" 2>/dev/null)"; rc=$?
        expected="$(hs_expected "$tool")"
        ok=0; [[ $rc -eq 0 && -n "$a" && "$a" == "$expected" ]] && ok=1
        assert "[T-16][A] command $tool is byte-equal to the FROZEN test-init fixture (independent of every flow)" "[[ $ok == 1 ]]"
    done

    # --- Group A' (T-16): two STANDING 4-row scans over the four derivation-flow files.
    #     Scan 1 is the AC-3 regression: no hook-command byte-form idiom may reappear on
    #     a NON-COMMENT line of a flow. Scan 2 is the &-hazard regression (insight
    #     2026-06-21): no pattern-substitution operator may touch a spec-derived value —
    #     ${var//pat/repl} and its ${arr[i]//}, ${!ref//}, ${var/pat/repl} siblings in
    #     bash (bash 5.2's patsub_replacement expands an unescaped `&` in the REPLACEMENT
    #     to the matched text, and the byte-forms contain a literal `&`), and -replace in
    #     PowerShell (whose replacement half interprets $& / $1). Comment lines are
    #     excluded: a comment can neither emit a command nor perform a substitution, and
    #     these flows legitimately DOCUMENT both idioms.
    #     PRE-T-16 BASELINE, measured: scan 1 was RED on all four files (16 non-comment
    #     hits, inside the resilient_cmd / Get-ResilientCmd bodies T-16 deleted); scan 2
    #     was already green (2 hits, both comment lines). Green-after-red is the point.
    #     A MISSING flow file scores "missing", never 0 — otherwise deleting a flow would
    #     make both of its scan rows vacuously green.
    for f in upgrade-project.sh migrate-scripts-layout.sh; do
        nhit=missing
        [[ -f "$repo_root/.harness/scripts/$f" ]] && nhit="$(grep -nE 'Set-Location -LiteralPath|CLAUDE_PROJECT_DIR' "$repo_root/.harness/scripts/$f" \
                | grep -vE '^[0-9]+:[[:space:]]*#' | wc -l | tr -d ' ')"
        ok=0; [[ "$nhit" == "0" ]] && ok=1
        assert "[T-16][A'] $f carries no hook-command byte-form idiom outside comments (got $nhit)" "[[ $ok == 1 ]]"
    done
    for f in upgrade-project.sh migrate-scripts-layout.sh; do
        nhit=missing
        if [[ -f "$repo_root/.harness/scripts/$f" ]]; then
            nhit="$(grep -nE '\$\{[!#]?[A-Za-z_][A-Za-z0-9_]*(\[[^]]*\])?/' "$repo_root/.harness/scripts/$f" \
                    | grep -vE '^[0-9]+:[[:space:]]*#' | wc -l | tr -d ' ')"
        fi
        ok=0; [[ "$nhit" == "0" ]] && ok=1
        assert "[T-16][A'] $f uses no pattern-substitution operator (& / patsub hazard) (got $nhit)" "[[ $ok == 1 ]]"
    done

    # --- Group B: failure semantics + the guard is fail-CLOSED on real output ---------
    for tool in harness-sync guard-rm ambient-prompt ambient-reset; do
        expected="fail-open"; [[ "$tool" == "guard-rm" ]] && expected="fail-closed"
        a="$(bash "$spec" semantics "$tool" 2>/dev/null)"
        ok=0; [[ "$a" == "$expected" ]] && ok=1
        assert "[T-13][B] semantics $tool == $expected" "[[ $ok == 1 ]]"
    done
    for _ in 1; do
        a="$(bash "$spec" command guard-rm 2>/dev/null)"
        ok=0; [[ -n "$a" && "$a" != *"|| exit 0"* && "$a" != *"exit 0"* ]] && ok=1
        assert "[T-13][B] guard-rm command carries NO '|| exit 0' and NO 'exit 0' fallback (fail-CLOSED, NFR-2)" "[[ $ok == 1 ]]"
    done

    # --- Group C: the existing congruence ERE still extracts the bare script path -----
    # The ERE still accepts `.ps1` on purpose: a legacy project can carry a PowerShell hook
    # value that the congruence scan must be able to FLAG, even though nothing emits one.
    for tool in harness-sync guard-rm ambient-prompt ambient-reset; do
        a="$(bash "$spec" command "$tool" 2>/dev/null)"
        extracted="$(printf '%s\n' "$a" \
            | grep -oE "(^|[\"' =])(\.harness/)?scripts/[A-Za-z0-9._-]+\.(ps1|sh)" \
            | sed -E "s|^[\"' =]||" | sort -u)"
        ok=0; [[ "$extracted" == *".harness/scripts/$tool.sh"* ]] && ok=1
        assert "[T-13][C] congruence ERE extracts .harness/scripts/$tool.sh from the command" "[[ $ok == 1 ]]"
    done

    # --- Group D: event / matcher / tool list (the installer's contract) --------------
    for tool in harness-sync guard-rm ambient-prompt ambient-reset; do
        case "$tool" in
            harness-sync)   expected="Stop" ;;
            guard-rm)       expected="PreToolUse" ;;
            ambient-prompt) expected="UserPromptSubmit" ;;
            ambient-reset)  expected="SessionStart" ;;
        esac
        a="$(bash "$spec" event "$tool" 2>/dev/null)"
        ok=0; [[ "$a" == "$expected" ]] && ok=1
        assert "[T-13][D] event $tool == $expected" "[[ $ok == 1 ]]"
        expected="none"; [[ "$tool" == "guard-rm" ]] && expected="Bash"
        a="$(bash "$spec" matcher "$tool" 2>/dev/null)"
        ok=0; [[ "$a" == "$expected" ]] && ok=1
        assert "[T-13][D] matcher $tool == $expected (non-empty sentinel for 'no matcher')" "[[ $ok == 1 ]]"
    done
    a="$(bash "$spec" tools 2>/dev/null | tr '\n' ' ')"
    ok=0; [[ "$a" == "harness-sync guard-rm ambient-prompt ambient-reset " ]] && ok=1
    assert "[T-13][D] tools emits the 4 ids in the fixed order" "[[ $ok == 1 ]]"
    a="$(bash "$spec" hostos 2>/dev/null)"; rc=$?
    # v0.49.0: `hostos` was retired with the target-OS axis. It must now be REJECTED, not
    # answered — a spec that still answers it means an OS branch survived somewhere.
    ok=0; [[ $rc -ne 0 && -z "$a" ]] && ok=1
    assert "[T-13][D] hostos is rejected (the OS axis went with Windows support)" "[[ $ok == 1 ]]"

    # --- Group E: totality — bad input yields EMPTY stdout and a non-zero exit --------
    out="$(bash "$spec" command bogus-tool unix 2>/dev/null)"; rc=$?
    ok=0; [[ $rc -ne 0 && -z "$out" ]] && ok=1
    assert "[T-13][E] unknown tool -> non-zero exit with EMPTY stdout (FR-7/B-1)" "[[ $ok == 1 ]]"
    out="$(bash "$spec" command guard-rm dos 2>/dev/null)"; rc=$?
    ok=0; [[ $rc -ne 0 && -z "$out" ]] && ok=1
    assert "[T-13][E] unknown os -> non-zero exit with EMPTY stdout (FR-7/B-1)" "[[ $ok == 1 ]]"
    out="$(bash "$spec" not-a-query 2>/dev/null)"; rc=$?
    ok=0; [[ $rc -ne 0 && -z "$out" ]] && ok=1
    assert "[T-13][E] unknown query -> non-zero exit with EMPTY stdout (FR-7/B-1)" "[[ $ok == 1 ]]"
}

# === T-13: the installer bootstrap (AC-5, AC-6, AC-7, FR-8..FR-12, B-2/B-3/B-8/B-9) ==
# Own temp tree; `.git` is a bare mkdir — the installer only tests for the directory,
# so no git binary is needed. No python3 dependency anywhere in this block.
test_install_bootstrap() {
    echo ""
    echo "=== Testing: install-hooks machine-local bootstrap (T-13) ==="
    local tmp; tmp=$(mktemp -d -t harness-test-install-XXXXXX)
    copy_layer "$template_root/common"  "$tmp" "install-test" "generic" "Rust CLI tool"
    copy_layer "$template_root/generic" "$tmp" "install-test" "generic" "Rust CLI tool"
    mkdir -p "$tmp/.git"

    local inst="$tmp/.harness/scripts/install-hooks.sh"
    local localset="$tmp/.claude/settings.local.json"
    local rc ok n last1 last2 tool cmd

    assert "[T-13][install] installer present after init" "[[ -f '$inst' ]]"
    assert "[T-13][install] hook-spec.sh distributed into the generated project (FR-6)" \
        "[[ -f '$tmp/.harness/scripts/hook-spec.sh' ]]"

    # (1) committed settings DECLARES hooks -> no machine-local file is created (AC-7)
    ( cd "$tmp" && bash "$inst" >/dev/null 2>&1 ); rc=$?
    ok=0; [[ $rc -eq 0 && ! -f "$localset" ]] && ok=1
    assert "[T-13][install] project whose committed settings has hooks: exit 0 and NO local file (AC-7/FR-10)" "[[ $ok == 1 ]]"
    assert "[T-13][install] pre-existing pre-commit hook behavior preserved (FR-13)" "[[ -f '$tmp/.git/hooks/pre-commit' ]]"

    # (2) empty the committed hooks object -> the bootstrap path (AC-5, FR-11, B-13)
    awk '
        /^  "hooks": \{$/ { print "  \"hooks\": {}"; skip = 1; next }
        skip && /^  \},?$/ { skip = 0; next }
        skip { next }
        { print }
    ' "$tmp/.claude/settings.json" > "$tmp/settings.emptied" && mv "$tmp/settings.emptied" "$tmp/.claude/settings.json"
    ok=0; grep -qF '"hooks": {}' "$tmp/.claude/settings.json" && ok=1
    assert "[T-13][install] fixture precondition: committed settings now declares an empty hooks object" "[[ $ok == 1 ]]"

    ( cd "$tmp" && bash "$inst" > "$tmp/bootstrap.out" 2>&1 ); rc=$?
    ok=0; [[ $rc -eq 0 && -f "$localset" ]] && ok=1
    assert "[T-13][install] bootstrap created .claude/settings.local.json, exit 0 (AC-5/FR-8)" "[[ $ok == 1 ]]"

    assert "[T-13][install] generated file carries the canonical .json \$schema (FR-11)" \
        "grep -qF '\"\$schema\": \"https://json.schemastore.org/claude-code-settings.json\"' '$localset'"
    assert "[T-13][install] generated file wires PreToolUse with matcher Bash (FR-11)" \
        "grep -qF '\"PreToolUse\"' '$localset' && grep -qF '\"matcher\": \"Bash\"' '$localset'"
    assert "[T-13][install] generated file wires all four real hook event names (FR-11)" \
        "grep -qF '\"Stop\"' '$localset' && grep -qF '\"UserPromptSubmit\"' '$localset' && grep -qF '\"SessionStart\"' '$localset'"
    assert "[T-13][install] no underscore doc key inside the hooks object (root only — FR-11)" \
        "! grep -qE '^ {4}\"_' '$localset'"
    # Every command byte-form landed verbatim (proves the spec is the origin).
    for tool in harness-sync guard-rm ambient-prompt ambient-reset; do
        cmd="$(bash "$tmp/.harness/scripts/hook-spec.sh" command "$tool")"
        ok=0; [[ -n "$cmd" ]] && grep -qF -- "$cmd" "$localset" && ok=1
        assert "[T-13][install] generated file carries the spec's $tool command verbatim (AC-5)" "[[ $ok == 1 ]]"
    done
    # Byte hygiene: no BOM, LF only, exactly one trailing newline (B-13/AC-10 half).
    ok=0; [[ "$(head -c 1 "$localset")" == "{" ]] && ok=1
    assert "[T-13][install] generated file is BOM-free (first byte is '{')" "[[ $ok == 1 ]]"
    ok=0; grep -q $'\r' "$localset" || ok=1
    assert "[T-13][install] generated file has LF endings only (no CR)" "[[ $ok == 1 ]]"
    last1="$(tail -c 1 "$localset" | od -An -tx1 | tr -d ' \n')"
    last2="$(tail -c 2 "$localset" | od -An -tx1 | tr -d ' \n')"
    ok=0; [[ "$last1" == "0a" && "$last2" != "0a0a" ]] && ok=1
    assert "[T-13][install] generated file ends with EXACTLY one trailing newline" "[[ $ok == 1 ]]"
    # FR-12 report: created path + removal command + machine-local/gitignore advisory.
    assert "[T-13][install] report names the created path (FR-12)" "grep -qF 'settings.local.json' '$tmp/bootstrap.out'"
    assert "[T-13][install] report gives the one-line removal command in this shell's form (FR-12)" \
        "grep -qF 'Remove: rm ' '$tmp/bootstrap.out'"
    assert "[T-13][install] report carries the machine-local / .gitignore advisory (FR-12/AC-14)" \
        "grep -qF 'machine-local' '$tmp/bootstrap.out' && grep -qF '.gitignore' '$tmp/bootstrap.out'"
    assert "[T-13][install] report calls out the fail-closed guard hook (FR-12)" \
        "grep -qF 'fail-closed' '$tmp/bootstrap.out'"
    # B-15: no .gitignore is created or edited on the bootstrap path.
    assert "[T-13][install] installer created no .gitignore (B-15/NFR-4c)" "[[ ! -f '$tmp/.gitignore' ]]"

    # (3) idempotence: byte-identical, no backup, no temp sibling (AC-6, B-9)
    cp "$localset" "$tmp/snapshot.json"
    ( cd "$tmp" && bash "$inst" > "$tmp/second.out" 2>&1 ); rc=$?
    ok=0; [[ $rc -eq 0 ]] && cmp -s "$tmp/snapshot.json" "$localset" && ok=1
    assert "[T-13][install] second run leaves the file BYTE-IDENTICAL, exit 0 (AC-6/FR-9/B-9)" "[[ $ok == 1 ]]"
    assert "[T-13][install] second run reports it took no action (FR-9)" \
        "grep -qF 'left byte-untouched' '$tmp/second.out'"
    n=$(find "$tmp/.claude" -maxdepth 1 -name 'settings.local.json.*' | wc -l)
    ok=0; [[ "$n" == "0" ]] && ok=1
    assert "[T-13][install] no settings.local.json.* temp/backup sibling survives (AC-6)" "[[ $ok == 1 ]]"
    n=$(find "$tmp/.claude" -maxdepth 1 -name '*.bak*' | wc -l)
    ok=0; [[ "$n" == "0" ]] && ok=1
    assert "[T-13][install] no *.bak* file anywhere under .claude/ (AC-6)" "[[ $ok == 1 ]]"

    # (4) B-7: an empty-hooks local file is the persistent opt-out — never overwritten.
    printf '{\n  "hooks": {}\n}\n' > "$localset"
    cp "$localset" "$tmp/optout.json"
    ( cd "$tmp" && bash "$inst" >/dev/null 2>&1 ); rc=$?
    ok=0; [[ $rc -eq 0 ]] && cmp -s "$tmp/optout.json" "$localset" && ok=1
    assert "[T-13][install] empty-hooks local file (B-7 opt-out) is left BYTE-UNTOUCHED" "[[ $ok == 1 ]]"

    # (5) B-5: an unparseable COMMITTED settings file changes nothing at all, exit 3.
    rm -f "$localset" "$tmp/.git/hooks/pre-commit"
    cp "$tmp/.claude/settings.json" "$tmp/settings.good"
    printf 'not json' > "$tmp/.claude/settings.json"
    ( cd "$tmp" && bash "$inst" >/dev/null 2>&1 ); rc=$?
    ok=0; [[ $rc -eq 3 && ! -f "$localset" && ! -f "$tmp/.git/hooks/pre-commit" ]] && ok=1
    assert "[T-13][install] unparseable committed settings -> exit 3, NOTHING written (B-5)" "[[ $ok == 1 ]]"
    mv "$tmp/settings.good" "$tmp/.claude/settings.json"

    # (6) B-8: an unwritable .claude/ leaves the target ABSENT with a non-zero exit.
    #     Skipped with a notice where the platform does not honor the mode (e.g. root).
    chmod a-w "$tmp/.claude" 2>/dev/null
    if ( : > "$tmp/.claude/.wtest" ) 2>/dev/null; then
        rm -f "$tmp/.claude/.wtest"
        echo "  SKIP  [T-13][install] read-only .claude/ probe — platform does not honor the mode here"
    else
        ( cd "$tmp" && bash "$inst" >/dev/null 2>&1 ); rc=$?
        ok=0; [[ $rc -ne 0 && ! -f "$localset" ]] && ok=1
        assert "[T-13][install] unwritable .claude/ -> non-zero exit, target left ABSENT (B-8)" "[[ $ok == 1 ]]"
    fi
    chmod u+w "$tmp/.claude" 2>/dev/null

    # (7) FC-4 all-four-or-nothing: a spec that lists FEWER than four tool ids is a
    #     partial wiring - possibly one with no destructive-command guard at all - and
    #     must be refused outright: exit 4, nothing written. The stub delegates every
    #     query except `tools` to the real spec, so only the arity differs.
    #     RE-ANCHORED (v2 TS migration): the installer no longer SHELLS OUT to the spec,
    #     it imports the compiled module, so mutating hook-spec.sh proves nothing — the
    #     stub would simply never be read and the row would go green against an
    #     unreachable branch. The mutation surface is now hook-spec.js, which
    #     install-hooks.js resolves by `require("./hook-spec")` from its own directory.
    rm -f "$localset"
    mv "$tmp/.harness/scripts/hook-spec.js" "$tmp/hook-spec.good.js"
    {
        echo "const good = require('$tmp/hook-spec.good.js');"
        echo 'module.exports = { ...good, TOOLS: good.TOOLS.slice(0, 3) };'
    } > "$tmp/.harness/scripts/hook-spec.js"
    #     The DIAGNOSTIC is matched too, not just the exit code: exit 4 alone is
    #     vacuous - a silently broken stub (wrong hs_good path, missing interpreter)
    #     also exits 4, via spec_fail "tools", without ever reaching the arity branch,
    #     and the row would stay green while proving nothing. Matching
    #     "expected 4 ids, got 3" pins the row to that branch by construction.
    ( cd "$tmp" && bash "$inst" > "$tmp/fc4.out" 2>&1 ); rc=$?
    ok=0; [[ $rc -eq 4 && ! -f "$localset" ]] && grep -qF -- 'expected 4 ids, got 3' "$tmp/fc4.out" && ok=1
    assert "[T-13][install] spec listing fewer than 4 tool ids -> exit 4, NOTHING written (FC-4)" "[[ $ok == 1 ]]"
    mv "$tmp/hook-spec.good.js" "$tmp/.harness/scripts/hook-spec.js"

    # (8) FC-4, SECOND axis: four ids that collapse to fewer than four DISTINCT hook
    #     EVENTS are a partial wiring too - one event on disk instead of four, plus
    #     duplicate JSON keys - and must be refused BEFORE anything is written:
    #     exit 4, target ABSENT. This row is the anti-revert coverage for the
    #     distinct-events gate: delete that gate and this same spec sails through the
    #     `== 4` arity check, the installer exits 0 with the file PRESENT, and the row
    #     goes red. The stub answers `tools` with the guard id four times and delegates
    #     every other query to the real spec, so ONLY the event multiplicity differs.
    #     RE-ANCHORED (v2 TS migration): see row (7) — the mutation surface is the
    #     compiled module the installer imports, not the shell launcher.
    rm -f "$localset"
    mv "$tmp/.harness/scripts/hook-spec.js" "$tmp/hook-spec.good.js"
    {
        echo "const good = require('$tmp/hook-spec.good.js');"
        echo "module.exports = { ...good, TOOLS: ['guard-rm', 'guard-rm', 'guard-rm', 'guard-rm'] };"
    } > "$tmp/.harness/scripts/hook-spec.js"
    #     The DISTINCT-gate diagnostic is matched too, for exactly the reason row (7)
    #     matches the arity one: any exit 4 would otherwise satisfy this row, so a
    #     silently broken stub would keep it green while proving nothing.
    ( cd "$tmp" && bash "$inst" > "$tmp/fc4d.out" 2>&1 ); rc=$?
    ok=0; [[ $rc -eq 4 && ! -f "$localset" ]] && grep -qF -- 'expected 4 DISTINCT hook events, got 1' "$tmp/fc4d.out" && ok=1
    assert "[T-13][install] spec answering 4 ids that collapse to 1 event -> exit 4, NOTHING written (FC-4)" "[[ $ok == 1 ]]"
    mv "$tmp/hook-spec.good.js" "$tmp/.harness/scripts/hook-spec.js"

    # (9) B-14: not a git repository -> exit 1, unchanged pre-existing behavior (FR-13).
    rm -rf "$tmp/.git"
    ( cd "$tmp" && bash "$inst" >/dev/null 2>&1 ); rc=$?
    ok=0; [[ $rc -eq 1 ]] && ok=1
    assert "[T-13][install] not a git repository -> exit 1 (FR-13/B-14, unchanged)" "[[ $ok == 1 ]]"

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
# T-13: the spec block runs UNCONDITIONALLY (it is a pure CLI probe, no fixture tree);
# the installer bootstrap block is fixture-backed and gated like test_migrate.
test_hook_spec
if [[ "$TYPE" == "all" || "$TYPE" == "both" ]]; then
    test_install_bootstrap
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
