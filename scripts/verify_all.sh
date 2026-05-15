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
for s in harness-init harness-adopt harness-verify harness-status; do
    [[ -f "skills/$s/SKILL.md" ]] || missing_skills="$missing_skills $s"
done
[[ -z "$missing_skills" ]] && step "C.1" "All 4 skills present" "PASS" || step "C.1" "All 4 skills present" "FAIL" "missing:$missing_skills"

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
tpl_dir="skills/harness-init/templates/common/.claude/agents"
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
            "{{PROJECT_NAME}}"|"{{PROJECT_TYPE}}"|"{{STACK}}"|"{{TODAY}}"|"{{ENABLE_HOOK}}") ;;
            *) bad_ph="$bad_ph\n$f: $ph" ;;
        esac
    done < <(grep -oE '\{\{[A-Z_]+\}\}' "$f" | sort -u)
done < <(find skills/harness-init/templates -type f \( -name '*.tmpl' -o -name '*.append' \))
[[ -z "$bad_ph" ]] && step "D.2" "Placeholders documented" "PASS" || step "D.2" "Placeholders documented" "FAIL" "$(echo -e $bad_ph)"

# E.1 — self-template consistency
if bash "$repo_root/scripts/sync-self.sh" --check &>/dev/null; then
    step "E.1" "Root .claude/agents matches templates" "PASS"
else
    step "E.1" "Root .claude/agents matches templates" "FAIL" "Run scripts/sync-self.sh to fix"
fi

# E.2 — project rules
missing_p=""
for f in CLAUDE.md docs/workflow.md docs/dev-map.md docs/tasks.md docs/getting-started.md docs/concepts.md; do
    [[ -f "$f" ]] || missing_p="$missing_p $f"
done
[[ -z "$missing_p" ]] && step "E.2" "Project rules present" "PASS" || step "E.2" "Project rules present" "FAIL" "missing:$missing_p"

# E.3 — evals
[[ -f "evals/golden-tasks.md" ]] && step "E.3" "evals/golden-tasks.md present" "PASS" || step "E.3" "evals/golden-tasks.md present" "FAIL"

# F.1 — script symmetry
missing_sym=""
for pair in verify_all sync-self; do
    [[ -f "scripts/$pair.ps1" ]] || missing_sym="$missing_sym scripts/$pair.ps1"
    [[ -f "scripts/$pair.sh" ]] || missing_sym="$missing_sym scripts/$pair.sh"
done
[[ -z "$missing_sym" ]] && step "F.1" "Script pairs (.ps1 + .sh) present" "PASS" || step "F.1" "Script pairs present" "FAIL" "missing:$missing_sym"

# G.1 — README mentions skills
readme=$(cat README.md)
miss_r=""
for s in harness-init harness-adopt harness-verify harness-status; do
    grep -q "$s" <<< "$readme" || miss_r="$miss_r $s"
done
[[ -z "$miss_r" ]] && step "G.1" "README references all skills" "PASS" || step "G.1" "README references all skills" "FAIL" "missing:$miss_r"

# G.2 — CHANGELOG mentions skills
cl=$(cat CHANGELOG.md)
miss_c=""
for s in harness-init harness-adopt harness-verify harness-status; do
    grep -q "$s" <<< "$cl" || miss_c="$miss_c $s"
done
[[ -z "$miss_c" ]] && step "G.2" "CHANGELOG references all skills" "PASS" || step "G.2" "CHANGELOG references all skills" "FAIL" "missing:$miss_c"

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
