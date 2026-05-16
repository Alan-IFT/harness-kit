#!/usr/bin/env bash
# verify_all.sh — Verification for the harness-engineering repo itself
set -uo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

errors=0
warns=0
declare -a report

step() {
    local id="$1" name="$2" status="$3" detail="${4:-}"
    case "$status" in
        PASS) echo "[$id] $name ... PASS" ;;
        WARN) echo "[$id] $name ... WARN"; ((warns++)) ;;
        FAIL) echo "[$id] $name ... FAIL"; [[ -n "$detail" ]] && echo "      $detail"; ((errors++)) ;;
    esac
    report+=("$id|$name|$status")
}

echo "=== verify_all (harness-engineering repo) ==="
echo ""

# A.1 — secrets / env
env_committed=$(git ls-files '*.env' '.env*' 2>/dev/null | grep -vE 'example|sample|tmpl' || true)
secrets=$(git grep -E "(api[_-]?key|secret|password|token)[[:space:]]*[:=][[:space:]]*[\"'][^\"']{12,}[\"']" \
    -- ':!*.md' ':!scripts/verify_all*' ':!skills/*' 2>/dev/null || true)
if [[ -n "$env_committed" || -n "$secrets" ]]; then
    step "A.1" "No accidentally-committed env or secrets" "FAIL" "${env_committed}${secrets}"
else
    step "A.1" "No accidentally-committed env or secrets" "PASS"
fi

# A.2 — 参考/ not tracked
tracked_ref=$(git ls-files -- '参考/' 2>/dev/null || true)
[[ -z "$tracked_ref" ]] && step "A.2" "参考/ not tracked" "PASS" || step "A.2" "参考/ not tracked" "FAIL" "$tracked_ref"

# B.1 — top-level files
missing=""
for f in README.md LICENSE CHANGELOG.md; do
    [[ -f "$f" ]] || missing="$missing $f"
done
[[ -z "$missing" ]] && step "B.1" "README / LICENSE / CHANGELOG present" "PASS" || step "B.1" "README / LICENSE / CHANGELOG present" "FAIL" "missing:$missing"

# B.2 — install scripts
[[ -f install.ps1 && -f install.sh ]] && step "B.2" "Install scripts present" "PASS" || step "B.2" "Install scripts present" "FAIL"

# C.1 — skills
missing_skills=""
for s in harness harness-init harness-adopt harness-verify harness-status harness-plan harness-explore harness-goal harness-intervene; do
    [[ -f "skills/$s/SKILL.md" ]] || missing_skills="$missing_skills $s"
done
[[ -z "$missing_skills" ]] && step "C.1" "All 9 skills present" "PASS" || step "C.1" "All 9 skills present" "FAIL" "missing:$missing_skills"

# C.2 — frontmatter sanity
bad=""
while IFS= read -r f; do
    head=$(head -10 "$f")
    [[ "$head" =~ "---" ]] || bad="$bad\n$f: missing frontmatter"
    [[ "$head" =~ "name:" ]] || bad="$bad\n$f: missing name:"
    [[ "$head" =~ "description:" ]] || bad="$bad\n$f: missing description:"
done < <(find skills -name SKILL.md -type f)
[[ -z "$bad" ]] && step "C.2" "Skill frontmatter sanity" "PASS" || step "C.2" "Skill frontmatter sanity" "FAIL" "$(echo -e $bad)"

# D.1 — template agents
tpl_dir="skills/harness-init/templates/common/.harness/agents"
missing_a=""
for a in pm-orchestrator requirement-analyst solution-architect gate-reviewer developer code-reviewer qa-tester; do
    [[ -f "$tpl_dir/$a.md" ]] || missing_a="$missing_a $a"
done
[[ -z "$missing_a" ]] && step "D.1" "Template agents complete" "PASS" || step "D.1" "Template agents complete" "FAIL" "missing:$missing_a"

# D.2 — placeholder whitelist
bad_ph=""
while IFS= read -r f; do
    while IFS= read -r ph; do
        case "$ph" in
            "{{PROJECT_NAME}}"|"{{PROJECT_TYPE}}"|"{{STACK}}"|"{{TODAY}}"|"{{ENABLE_HOOK}}"|"{{SYNC_COMMAND}}") ;;
            *) bad_ph="$bad_ph\n$f: $ph" ;;
        esac
    done < <(grep -oE '\{\{[A-Z_]+\}\}' "$f" | sort -u)
done < <(find skills/harness-init/templates -type f \( -name '*.tmpl' -o -name '*.append' \))
[[ -z "$bad_ph" ]] && step "D.2" "Placeholders documented" "PASS" || step "D.2" "Placeholders documented" "FAIL" "$(echo -e $bad_ph)"

# E.1 — Layer 1: templates/common/ → repo .harness/ + harness-sync
if bash "$repo_root/scripts/sync-self.sh" --check &>/dev/null; then
    step "E.1" "Layer 1: .harness/ matches templates/common/.harness/" "PASS"
else
    step "E.1" "Layer 1: .harness/ matches templates/common/.harness/" "FAIL" "Run scripts/sync-self.sh"
fi

# E.2 — Layer 2: .harness/ → .claude/ (agents + skills only in v0.10)
if bash "$repo_root/scripts/harness-sync.sh" --check &>/dev/null; then
    step "E.2" "Layer 2: .claude/agents and .claude/skills synced from .harness/" "PASS"
else
    step "E.2" "Layer 2: .claude/agents and .claude/skills synced from .harness/" "FAIL" "Run scripts/harness-sync.sh"
fi

# E.3 — rule sources present
missing_e3=""
for f in .harness/agents/pm-orchestrator.md .harness/agents/developer.md; do
    [[ -f "$f" ]] || missing_e3="$missing_e3 $f"
done
rule_count=$(find .harness/rules -name '*.md' -type f 2>/dev/null | wc -l)
[[ -z "$missing_e3" ]] && (( rule_count >= 1 )) && step "E.3" "Rule sources present" "PASS" || step "E.3" "Rule sources present" "FAIL" "missing:$missing_e3 rules_count=$rule_count"

# E.4 — bootstrap files (AI-GUIDE.md + CLAUDE.md + copilot-instructions.md stubs)
gen_missing=""
for f in AI-GUIDE.md CLAUDE.md .github/copilot-instructions.md; do
    [[ -f "$f" ]] || gen_missing="$gen_missing $f"
done
stub_bad=""
for stub in CLAUDE.md .github/copilot-instructions.md; do
    if [[ -f "$stub" ]] && ! grep -q "AI-GUIDE.md" "$stub"; then
        stub_bad="$stub_bad $stub"
    fi
done
[[ -d .claude/agents ]] || gen_missing="$gen_missing .claude/agents"
if [[ -z "$gen_missing" && -z "$stub_bad" ]]; then
    step "E.4" "Bootstrap files present and stubs reference AI-GUIDE.md" "PASS"
else
    step "E.4" "Bootstrap files present and stubs reference AI-GUIDE.md" "FAIL" "missing:$gen_missing stub_no_ref:$stub_bad"
fi

# E.4b — AI-GUIDE.md must index every .harness/rules/*.md (and vice versa)
e4b_problems=""
if [[ ! -f AI-GUIDE.md ]]; then
    e4b_problems="AI-GUIDE.md missing"
elif [[ ! -d .harness/rules ]]; then
    : # skip silently; E.3 already flagged
else
    # forward: every rule file must be referenced in AI-GUIDE.md
    while IFS= read -r r; do
        name=$(basename "$r")
        if ! grep -qF ".harness/rules/$name" AI-GUIDE.md; then
            e4b_problems="$e4b_problems\nNot indexed in AI-GUIDE.md: $name"
        fi
    done < <(find .harness/rules -maxdepth 1 -name '*.md' -type f)

    # reverse: every reference in AI-GUIDE.md must point to an existing file
    while IFS= read -r ref; do
        if [[ ! -f ".harness/rules/$ref" ]]; then
            e4b_problems="$e4b_problems\nAI-GUIDE.md references non-existent rule: .harness/rules/$ref"
        fi
    done < <(grep -oE '\.harness/rules/[0-9A-Za-z_\-]+\.md' AI-GUIDE.md | sed 's|\.harness/rules/||' | sort -u)
fi
if [[ -z "$e4b_problems" ]]; then
    step "E.4b" "AI-GUIDE.md indexes every .harness/rules/*.md (and vice versa)" "PASS"
else
    step "E.4b" "AI-GUIDE.md indexes every .harness/rules/*.md (and vice versa)" "FAIL" "$(echo -e $e4b_problems)"
fi

# E.5 — docs
missing_p=""
for f in docs/workflow.md docs/dev-map.md docs/tasks.md docs/getting-started.md docs/concepts.md; do
    [[ -f "$f" ]] || missing_p="$missing_p $f"
done
[[ -z "$missing_p" ]] && step "E.5" "Docs present" "PASS" || step "E.5" "Docs present" "FAIL" "missing:$missing_p"

# E.6 — evals
[[ -f "evals/golden-tasks.md" ]] && step "E.6" "evals/golden-tasks.md present" "PASS" || step "E.6" "evals/golden-tasks.md present" "FAIL"

# E.7 — stale .harness/intervention.md (v0.13+)
if [[ -f .harness/intervention.md ]]; then
    tracked_int=$(git ls-files -- '.harness/intervention.md' 2>/dev/null || true)
    if [[ -n "$tracked_int" ]]; then
        step "E.7" "No stale .harness/intervention.md tracked" "WARN" "intervention.md is tracked — should be gitignored"
    else
        step "E.7" "No stale .harness/intervention.md tracked" "PASS"
    fi
else
    step "E.7" "No stale .harness/intervention.md tracked" "PASS"
fi

# F.1 — script symmetry
missing_sym=""
for pair in verify_all sync-self harness-sync test-init test-real-project; do
    [[ -f "scripts/$pair.ps1" ]] || missing_sym="$missing_sym scripts/$pair.ps1"
    [[ -f "scripts/$pair.sh" ]] || missing_sym="$missing_sym scripts/$pair.sh"
done
[[ -z "$missing_sym" ]] && step "F.1" "Script pairs (.ps1 + .sh) present" "PASS" || step "F.1" "Script pairs present" "FAIL" "missing:$missing_sym"

# G.1 — README mentions skills
readme=$(cat README.md)
miss_r=""
for s in harness harness-init harness-adopt harness-verify harness-status harness-plan harness-explore harness-goal harness-intervene; do
    grep -q "$s" <<< "$readme" || miss_r="$miss_r $s"
done
[[ -z "$miss_r" ]] && step "G.1" "README references all 9 skills" "PASS" || step "G.1" "README references all 9 skills" "FAIL" "missing:$miss_r"

# H.1 — fixtures
missing_fix=""
for f in tests/fixtures/todo-fullstack/package.json tests/fixtures/todo-fullstack/src/server.ts \
         tests/fixtures/todo-backend/pyproject.toml tests/fixtures/todo-backend/src/main.py; do
    [[ -f "$f" ]] || missing_fix="$missing_fix $f"
done
[[ -z "$missing_fix" ]] && step "H.1" "Test fixtures present" "PASS" || step "H.1" "Test fixtures present" "FAIL" "missing:$missing_fix"

# G.2 — CHANGELOG mentions skills
cl=$(cat CHANGELOG.md)
miss_c=""
for s in harness harness-init harness-adopt harness-verify harness-status harness-plan harness-explore harness-goal harness-intervene; do
    grep -q "$s" <<< "$cl" || miss_c="$miss_c $s"
done
[[ -z "$miss_c" ]] && step "G.2" "CHANGELOG references all 9 skills" "PASS" || step "G.2" "CHANGELOG references all 9 skills" "FAIL" "missing:$miss_c"

# G.3 — Version stamps consistent across plugin.json / marketplace.json / README badges
# Extracts the FIRST "version": "X.Y.Z" from each JSON (both manifests have a single version field today)
# and the first version-X.Y.Z badge token from each README. All four must match.
extract_json_version() {
    grep -oE '"version"[[:space:]]*:[[:space:]]*"[0-9]+\.[0-9]+\.[0-9]+"' "$1" 2>/dev/null \
        | head -1 \
        | grep -oE '[0-9]+\.[0-9]+\.[0-9]+'
}
extract_readme_badge_version() {
    grep -oE 'version-[0-9]+\.[0-9]+\.[0-9]+-' "$1" 2>/dev/null \
        | head -1 \
        | grep -oE '[0-9]+\.[0-9]+\.[0-9]+'
}
plugin_v=$(extract_json_version .claude-plugin/plugin.json)
market_v=$(extract_json_version .claude-plugin/marketplace.json)
readme_v=$(extract_readme_badge_version README.md)
zh_v=$(extract_readme_badge_version README.zh-CN.md)
if [[ -n "$plugin_v" && "$plugin_v" == "$market_v" && "$plugin_v" == "$readme_v" && "$plugin_v" == "$zh_v" ]]; then
    step "G.3" "Version stamps consistent across plugin/marketplace/README" "PASS"
else
    step "G.3" "Version stamps consistent across plugin/marketplace/README" "FAIL" \
        "plugin.json=$plugin_v marketplace.json=$market_v README.md=$readme_v README.zh-CN.md=$zh_v (bump all four together when cutting a release)"
fi

# --- I. Document size caps (v0.14+, WARN-only; see .harness/rules/70-doc-size.md) ---

# I.1 — AI-GUIDE.md ≤200 lines
if [[ -f AI-GUIDE.md ]]; then
    n=$(wc -l < AI-GUIDE.md)
    if (( n > 200 )); then
        step "I.1" "AI-GUIDE.md ≤200 lines" "WARN" "$n lines (cap 200) — see .harness/rules/70-doc-size.md"
    else
        step "I.1" "AI-GUIDE.md ≤200 lines" "PASS"
    fi
else
    step "I.1" "AI-GUIDE.md ≤200 lines" "PASS"
fi

# I.2 — Each .harness/rules/*.md ≤200 lines
i2_over=""
if [[ -d .harness/rules ]]; then
    while IFS= read -r f; do
        n=$(wc -l < "$f")
        (( n > 200 )) && i2_over="$i2_over $f:${n}L"
    done < <(find .harness/rules -maxdepth 1 -name '*.md' -type f)
fi
if [[ -n "$i2_over" ]]; then
    step "I.2" "Rule fragments ≤200 lines each" "WARN" "over cap:$i2_over"
else
    step "I.2" "Rule fragments ≤200 lines each" "PASS"
fi

# I.3 — Each .harness/agents/*.md ≤300 lines
i3_over=""
if [[ -d .harness/agents ]]; then
    while IFS= read -r f; do
        n=$(wc -l < "$f")
        (( n > 300 )) && i3_over="$i3_over $f:${n}L"
    done < <(find .harness/agents -maxdepth 1 -name '*.md' -type f)
fi
if [[ -n "$i3_over" ]]; then
    step "I.3" "Agent definitions ≤300 lines each" "WARN" "over cap:$i3_over"
else
    step "I.3" "Agent definitions ≤300 lines each" "PASS"
fi

# I.4 — insight-index ≤30 lines (defense-in-depth; archive-task normally rotates)
if [[ -f .harness/insight-index.md ]]; then
    n=$(wc -l < .harness/insight-index.md)
    if (( n > 30 )); then
        step "I.4" "insight-index.md ≤30 lines" "WARN" "$n lines — archive-task auto-rotates; manual overflow"
    else
        step "I.4" "insight-index.md ≤30 lines" "PASS"
    fi
else
    step "I.4" "insight-index.md ≤30 lines" "PASS"
fi

# I.5 — docs/tasks.md ≤300 lines
if [[ -f docs/tasks.md ]]; then
    n=$(wc -l < docs/tasks.md)
    if (( n > 300 )); then
        step "I.5" "docs/tasks.md ≤300 lines" "WARN" "$n lines — rotate oldest Completed rows to docs/tasks-archive.md"
    else
        step "I.5" "docs/tasks.md ≤300 lines" "PASS"
    fi
else
    step "I.5" "docs/tasks.md ≤300 lines" "PASS"
fi

# Summary
echo ""
echo "=== Summary ==="
pass_count=$(printf '%s\n' "${report[@]}" | grep -c PASS || true)
echo "  PASS: $pass_count"
echo "  WARN: $warns"
echo "  FAIL: $errors"

ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
printf '{"timestamp":"%s","pass":%d,"warn":%d,"fail":%d}\n' "$ts" "$pass_count" "$warns" "$errors" >> scripts/verification_history.log

(( errors > 0 )) && exit 2
(( warns > 0 )) && exit 1
exit 0
