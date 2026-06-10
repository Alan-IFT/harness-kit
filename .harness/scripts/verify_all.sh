#!/usr/bin/env bash
# verify_all.sh — Verification for the harness-engineering repo itself
set -uo pipefail

# Script lives at .harness/scripts/ — repo root is two levels up.
repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$repo_root"

errors=0
warns=0
# Use `report=()` instead of `declare -a report` — under `set -u`, the latter
# can leak an empty index-0 element on some bash versions, making
# `printf '%s\n' "${report[@]}"` emit an extra empty line and underreport
# the PASS counter by 1 (per user-feedback insight on `set -u` array init).
report=()

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
    -- ':!*.md' ':!.harness/scripts/verify_all*' ':!skills/*' 2>/dev/null || true)
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
for s in harness harness-init harness-adopt harness-verify harness-status harness-plan harness-explore harness-goal harness-intervene harness-supervise harness-batch harness-stream harness-upgrade harness-language harness-decision-mode; do
    [[ -f "skills/$s/SKILL.md" ]] || missing_skills="$missing_skills $s"
done
[[ -z "$missing_skills" ]] && step "C.1" "All 15 skills present" "PASS" || step "C.1" "All 15 skills present" "FAIL" "missing:$missing_skills"

# C.2 — frontmatter sanity
bad=""
while IFS= read -r f; do
    head=$(head -10 "$f")
    [[ "$head" =~ "---" ]] || bad="$bad\n$f: missing frontmatter"
    [[ "$head" =~ "name:" ]] || bad="$bad\n$f: missing name:"
    [[ "$head" =~ "description:" ]] || bad="$bad\n$f: missing description:"
done < <(find skills -name SKILL.md -type f)
[[ -z "$bad" ]] && step "C.2" "Skill frontmatter sanity" "PASS" || step "C.2" "Skill frontmatter sanity" "FAIL" "$(echo -e $bad)"

# D.1 — plugin agents (top-level agents/ dir, auto-discovered as harness-kit:<name>)
tpl_dir="agents"
missing_a=""
for a in pm-orchestrator requirement-analyst solution-architect gate-reviewer developer code-reviewer qa-tester; do
    [[ -f "$tpl_dir/$a.md" ]] || missing_a="$missing_a $a"
done
[[ -z "$missing_a" ]] && step "D.1" "Plugin agents present" "PASS" || step "D.1" "Plugin agents present" "FAIL" "missing:$missing_a"

# D.2 — placeholder whitelist
bad_ph=""
while IFS= read -r f; do
    while IFS= read -r ph; do
        case "$ph" in
            "{{PROJECT_NAME}}"|"{{PROJECT_TYPE}}"|"{{STACK}}"|"{{TODAY}}"|"{{ENABLE_HOOK}}"|"{{SYNC_COMMAND}}"|"{{GUARD_COMMAND}}") ;;
            *) bad_ph="$bad_ph\n$f: $ph" ;;
        esac
    done < <(grep -oE '\{\{[[:space:]]*[A-Za-z_][A-Za-z0-9_]*[[:space:]]*\}\}' "$f" | sort -u)
done < <(find skills/harness-init/templates -type f \( -name '*.tmpl' -o -name '*.append' \))
[[ -z "$bad_ph" ]] && step "D.2" "Placeholders documented" "PASS" || step "D.2" "Placeholders documented" "FAIL" "$(echo -e $bad_ph)"

# D.3 — AI-generated 50-*.md sanity (per-section, per Gate Finding G)
# For every .harness/rules/50-*.md:
#   (a) all six required headings present in order
#   (b) zero {{...}} literals
#   (c) every non-template '## ' / '### ' section has >=1 <!-- source: <tag> -->
#       annotation with a tag in the allowed set
d3_problems=""
d3_required_headings=(
    "## When to read"
    "## Build / test / verify"
    "## Project structure"
    "## Stack-specific conventions"
    "## Partitioning"
    "## Stack-specific verify_all checks"
)
d3_allowed_tags=(user-q2 top-level-glob package.json Cargo.toml pyproject.toml requirements.txt go.mod pom.xml README.md)
d3_files=()
if [[ -d .harness/rules ]]; then
    while IFS= read -r f; do d3_files+=("$f"); done < <(find .harness/rules -maxdepth 1 -name '50-*.md' -type f 2>/dev/null)
fi
if (( ${#d3_files[@]} > 0 )); then
    for f in "${d3_files[@]}"; do
        fname=$(basename "$f")
        content=$(cat "$f")
        # (b) zero {{...}} literals
        # v0.16.0 BUG-2 rollback round 2: regex broadened to catch whitespace-padded
        # ('{{ PROJECT_NAME }}') and lowercase ('{{project_name}}') variants too.
        if grep -qE '\{\{[[:space:]]*[A-Za-z_][A-Za-z0-9_]*[[:space:]]*\}\}' "$f"; then
            d3_problems="${d3_problems}${fname}: leaked placeholder {{...}}"$'\n'
        fi
        # (a) six required headings present in order
        idx=0
        for h in "${d3_required_headings[@]}"; do
            # find first occurrence of $h starting at offset $idx
            sub="${content:idx}"
            # use grep -F with -b for byte offset
            pos=$(printf '%s' "$sub" | grep -bF -- "$h" 2>/dev/null | head -1 | cut -d: -f1)
            if [[ -z "$pos" ]]; then
                d3_problems="${d3_problems}${fname}: missing required heading '$h' (or out of order)"$'\n'
                break
            fi
            idx=$((idx + pos + ${#h}))
        done
        # (c) per-section sources. Split by '^## ' or '^### ' lines using awk.
        # For each section, capture its body; if body has non-whitespace content
        # that isn't only `<your ...>` placeholders, require >=1 <!-- source: tag -->.
        awk_out=$(awk -v file="$fname" -v allowed_tags="${d3_allowed_tags[*]}" '
            BEGIN {
                in_section = 0
                heading = ""
                body = ""
                n_allowed = split(allowed_tags, tags, " ")
                for (i = 1; i <= n_allowed; i++) allowed[tags[i]] = 1
            }
            function check_section() {
                if (!in_section) return
                # Trim body and check if it is template-only
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", body)
                if (body == "") return
                # template-only heuristic: body is just `<your ...>` placeholders / bullets / whitespace
                tmp = body
                gsub(/<your[^>]*>/, "", tmp)
                gsub(/<command[^>]*>/, "", tmp)
                gsub(/[-[:space:]]/, "", tmp)
                if (tmp == "") return
                # Non-template: require at least one <!-- source: tag -->
                n = 0
                src = body
                while (match(src, /<!-- source: [^ >]+ -->/)) {
                    n++
                    tag = substr(src, RSTART + length("<!-- source: "))
                    sub(/ -->.*/, "", tag)
                    if (!(tag in allowed)) {
                        print file ": section " heading " has unknown source tag " tag
                    }
                    src = substr(src, RSTART + RLENGTH)
                }
                if (n == 0) {
                    print file ": section " heading " has non-template content but no <!-- source: ... --> annotation"
                }
            }
            /^##[#]?[[:space:]]+[^[:space:]]/ {
                check_section()
                heading = $0
                body = ""
                in_section = 1
                next
            }
            in_section { body = body $0 "\n" }
            END { check_section() }
        ' "$f")
        if [[ -n "$awk_out" ]]; then
            d3_problems="${d3_problems}${awk_out}"$'\n'
        fi
    done
fi
if [[ -z "$d3_problems" ]]; then
    step "D.3" "AI-generated 50-*.md sanity (per-section sources, headings, no placeholders)" "PASS"
else
    step "D.3" "AI-generated 50-*.md sanity (per-section sources, headings, no placeholders)" "FAIL" "$d3_problems"
fi

# E.1 — Layer 1: templates/common/ → repo .harness/ + harness-sync
if bash "$repo_root/.harness/scripts/sync-self.sh" --check &>/dev/null; then
    step "E.1" "Layer 1: .harness/ matches templates/common/.harness/" "PASS"
else
    step "E.1" "Layer 1: .harness/ matches templates/common/.harness/" "FAIL" "Run .harness/scripts/sync-self.sh"
fi

# E.2 — Layer 2: .harness/ → .claude/ (agents + skills only in v0.10)
if bash "$repo_root/.harness/scripts/harness-sync.sh" --check &>/dev/null; then
    step "E.2" "Layer 2: .claude/agents and .claude/skills synced from .harness/" "PASS"
else
    step "E.2" "Layer 2: .claude/agents and .claude/skills synced from .harness/" "FAIL" "Run .harness/scripts/harness-sync.sh"
fi

# E.3 — rule sources present
missing_e3=""
for f in agents/pm-orchestrator.md agents/developer.md; do
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
for pair in verify_all sync-self harness-sync test-init test-real-project ambient-prompt ambient-reset upgrade-project language-policy; do
    [[ -f ".harness/scripts/$pair.ps1" ]] || missing_sym="$missing_sym .harness/scripts/$pair.ps1"
    [[ -f ".harness/scripts/$pair.sh" ]] || missing_sym="$missing_sym .harness/scripts/$pair.sh"
done
[[ -z "$missing_sym" ]] && step "F.1" "Script pairs (.ps1 + .sh) present" "PASS" || step "F.1" "Script pairs present" "FAIL" "missing:$missing_sym"

# F.2 — Guard-rm scripts and PreToolUse wiring present (v0.15+)
f2_problems=""
for f in .harness/scripts/guard-rm.ps1 .harness/scripts/guard-rm.sh \
         skills/harness-init/templates/common/.harness/scripts/guard-rm.ps1 \
         skills/harness-init/templates/common/.harness/scripts/guard-rm.sh; do
    [[ -f "$f" ]] || f2_problems="$f2_problems missing:$f"
done
# Dogfood .claude/settings.json must contain a PreToolUse hook calling guard-rm.
# Use grep heuristic (avoid jq dependency); mirrors G.3's grep approach.
if [[ -f .claude/settings.json ]]; then
    if ! grep -q '"PreToolUse"' .claude/settings.json; then
        f2_problems="$f2_problems .claude/settings.json:no_PreToolUse"
    fi
    if ! grep -q '"matcher"[[:space:]]*:[[:space:]]*"Bash"' .claude/settings.json; then
        f2_problems="$f2_problems .claude/settings.json:no_Bash_matcher"
    fi
    if ! grep -qE 'guard-rm\.(ps1|sh)' .claude/settings.json; then
        f2_problems="$f2_problems .claude/settings.json:no_guard-rm_command"
    fi
else
    f2_problems="$f2_problems missing:.claude/settings.json"
fi
# Template .claude/settings.json.tmpl must have {{GUARD_COMMAND}} + PreToolUse
tmpl=skills/harness-init/templates/common/.claude/settings.json.tmpl
if [[ -f "$tmpl" ]]; then
    grep -q '{{GUARD_COMMAND}}' "$tmpl" || f2_problems="$f2_problems $tmpl:no_GUARD_COMMAND_placeholder"
    grep -q 'PreToolUse' "$tmpl" || f2_problems="$f2_problems $tmpl:no_PreToolUse"
else
    f2_problems="$f2_problems missing:$tmpl"
fi
if [[ -z "$f2_problems" ]]; then
    step "F.2" "Guard-rm scripts and PreToolUse wiring present" "PASS"
else
    step "F.2" "Guard-rm scripts and PreToolUse wiring present" "FAIL" "$f2_problems"
fi

# G.1 — README mentions skills
readme=$(cat README.md)
miss_r=""
for s in harness harness-init harness-adopt harness-verify harness-status harness-plan harness-explore harness-goal harness-intervene harness-supervise harness-batch harness-stream harness-upgrade harness-language harness-decision-mode; do
    grep -q "$s" <<< "$readme" || miss_r="$miss_r $s"
done
[[ -z "$miss_r" ]] && step "G.1" "README references all 15 skills" "PASS" || step "G.1" "README references all 15 skills" "FAIL" "missing:$miss_r"

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
for s in harness harness-init harness-adopt harness-verify harness-status harness-plan harness-explore harness-goal harness-intervene harness-supervise harness-batch harness-stream harness-upgrade harness-language harness-decision-mode; do
    grep -q "$s" <<< "$cl" || miss_c="$miss_c $s"
done
[[ -z "$miss_c" ]] && step "G.2" "CHANGELOG references all 15 skills" "PASS" || step "G.2" "CHANGELOG references all 15 skills" "FAIL" "missing:$miss_c"

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

# I.3 — Each plugin agents/*.md ≤300 lines
i3_over=""
if [[ -d agents ]]; then
    while IFS= read -r f; do
        n=$(wc -l < "$f")
        (( n > 300 )) && i3_over="$i3_over $f:${n}L"
    done < <(find agents -maxdepth 1 -name '*.md' -type f)
fi
if [[ -n "$i3_over" ]]; then
    step "I.3" "Agent definitions ≤300 lines each" "WARN" "over cap:$i3_over"
else
    step "I.3" "Agent definitions ≤300 lines each" "PASS"
fi

# I.4 — insight-index ≤30 evidence lines (defense-in-depth; archive-task normally rotates)
if [[ -f .harness/insight-index.md ]]; then
    n=$(grep -c '^[[:space:]]*-[[:space:]]' .harness/insight-index.md || true)
    if (( n > 30 )); then
        step "I.4" "insight-index.md ≤30 evidence lines" "WARN" "$n evidence lines — archive-task auto-rotates; manual overflow"
    else
        step "I.4" "insight-index.md ≤30 evidence lines" "PASS"
    fi
else
    step "I.4" "insight-index.md ≤30 evidence lines" "PASS"
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

# I.7 — Ignored INTERVENE supervision reports (v0.17+, WARN-only)
# Passive guard for the supervisor agent. Globs every
# docs/features/<slug>/SUPERVISION_REPORT.md (not _archived/), reads the last
# 5 non-blank lines for the verdict, and WARNs if Verdict: INTERVENE has been
# ignored on an active task whose row in docs/tasks.md is not Completed/Archived
# and whose file mtime is >48h ago.
i7_stale=""
if [[ -d docs/features ]]; then
    # NOTE: loop variable is `report_file` (NOT `report`) — `report` is the global
    # array used by step() to accumulate the audit log; reusing the name clobbers
    # it via implicit scalar→array coercion and corrupts the PASS counter.
    while IFS= read -r report_file; do
        [[ -z "$report_file" ]] && continue
        # exclude _archived/ and _supervision/
        case "$report_file" in
            *_archived*) continue ;;
            *_supervision*) continue ;;
        esac
        slug=$(basename "$(dirname "$report_file")")
        # Last 5 non-blank lines, look for verdict
        verdict=""
        while IFS= read -r line; do
            if [[ "$line" =~ ^Verdict:\ (HEALTHY|WATCH|INTERVENE)$ ]]; then
                verdict="${BASH_REMATCH[1]}"
                break
            fi
        done < <(grep -v '^[[:space:]]*$' "$report_file" | tail -n 5)
        [[ "$verdict" != "INTERVENE" ]] && continue
        # Is the slug an active row in docs/tasks.md (not Completed/Archived)?
        is_active=0
        if [[ -f docs/tasks.md ]]; then
            while IFS= read -r row; do
                if [[ "$row" != *Completed* && "$row" != *Archived* ]]; then
                    is_active=1
                    break
                fi
            # BUG-2 fix (v0.17.1): column-anchored match — require the slug as a
            # full pipe-delimited cell, not a bare substring, so `foo` is not
            # matched by a `foo-extra` row. PS twin: verify_all.ps1 I.7.
            done < <(grep -E -- "\|[[:space:]]*${slug}[[:space:]]*\|" docs/tasks.md || true)
        fi
        (( is_active == 1 )) || continue
        # mtime > 48h ago?
        if [[ "$(uname)" == "Darwin" ]]; then
            mtime=$(stat -f %m "$report_file" 2>/dev/null || echo 0)
        else
            mtime=$(stat -c %Y "$report_file" 2>/dev/null || echo 0)
        fi
        now=$(date +%s)
        age_hours=$(( (now - mtime) / 3600 ))
        if (( age_hours > 48 )); then
            i7_stale="$i7_stale $report_file(INTERVENE,${age_hours}h,slug=$slug)"
        fi
    done < <(find docs/features -maxdepth 3 -name SUPERVISION_REPORT.md -type f 2>/dev/null)
fi
if [[ -n "$i7_stale" ]]; then
    step "I.7" "Ignored INTERVENE supervision reports (WARN if >48h old on active task)" "WARN" "stale:$i7_stale"
else
    step "I.7" "Ignored INTERVENE supervision reports (WARN if >48h old on active task)" "PASS"
fi

# I.6 — Retired-claim guard (gap-tolerant since v0.18.0). Phrases that used to be
# accurate but were retired by a documented architectural change. Resurgence = drift,
# not history. As of v0.18.0 the matcher is a gap-tolerant ordered-anchor scan: each
# banned entry is an ordered list of literal anchor tokens, and a file hits when all
# anchors appear in order on ONE line within a bounded gap (default 40 chars, per-entry
# overridable). Each entry may also carry literal `exclude` tokens — if any appears
# anywhere on the matched LINE (line-scoped), the match is rejected, so accurate negated
# prose ("rules are NOT composed into CLAUDE.md") does not FAIL.
#
# Record format (`|`-delimited fields, `~`-delimited inner lists):
#     anchors~tokens | reason | exclude~tokens | gap
# Anchors/exclusions are PLAIN TEXT — the script escapes every regex metacharacter, so
# authoring stays a one-line edit. NEVER put a literal `~` or `|` in any anchor, reason,
# or exclude token: it corrupts the record split. When a retired claim becomes accurate
# again, delete the line rather than carve a file-level exception.
# History-bearing files (CHANGELOG, architecture.html, walkthrough.html, verify_all
# itself, and the test-verify-i6 regression drivers — which hold a verbatim copy of
# this banned list) are exempt; the whole docs/features/ subtree is exempt because
# per-task stage docs must quote retired claims to design the guard.
i6_gap_default=40
i6_banned=(
    "scaffolding-only|harness-adopt has been fully automated since v0.3||"
    "Composed~into~\`CLAUDE.md\`|rules are not composed into CLAUDE.md since v0.10|not~no longer~referenced|20"
    "composed~by~filename~order|rules not composed since v0.10||"
    "composition~order~in~CLAUDE.md|no composition in CLAUDE.md since v0.10|not~no longer|"
    "regenerates~CLAUDE.md|harness-sync does not regenerate CLAUDE.md since v0.10||"
    "regenerates~\`CLAUDE.md\`|harness-sync does not regenerate CLAUDE.md since v0.10||"
    "regenerated~CLAUDE.md|CLAUDE.md is a static stub since v0.10||"
    "regenerated~\`CLAUDE.md\`|CLAUDE.md is a static stub since v0.10||"
    "Generated~from~.harness/rules|CLAUDE.md not generated from rules since v0.10||"
    ".harness/~→~CLAUDE.md|harness-sync target is .claude/, not CLAUDE.md, since v0.10|.claude/|"
    "harness-sync~生成~CLAUDE.md|v0.10 起 harness-sync 不再生成 CLAUDE.md|不|"
    "harness-sync~合成~CLAUDE.md|v0.10 起规则不再合成进 CLAUDE.md|不|"
    "重新生成的~CLAUDE.md|v0.10 起 CLAUDE.md 是 stub，不再被重新生成||"
    "全程~中文|v0.24.0 起 zh 策略按消费者分流，不再全程中文（T-013）||"
)
# Build an ERE from a ~-delimited anchor list, escaping each token to match literally.
i6_build_regex() {                       # $1 = ~-joined anchors  $2 = gap budget
    local anchors="$1" gap="$2" out="" first=1 tok esc
    local IFS='~'
    for tok in $anchors; do
        esc=$(printf '%s' "$tok" | sed 's/[.[\](){}*+?|^$\\]/\\&/g')
        if (( first )); then out="$esc"; first=0; else out="${out}.{0,${gap}}${esc}"; fi
    done
    printf '%s' "$out"
}
i6_exempt_files=(
    "CHANGELOG.md"
    "architecture.html"
    "docs/walkthrough.html"
    "docs/project-overview.html"
    ".harness/scripts/verify_all.ps1"
    ".harness/scripts/verify_all.sh"
    ".harness/scripts/test-verify-i6.ps1"
    ".harness/scripts/test-verify-i6.sh"
)
i6_exempt_dirs=(
    "docs/features/"
    "参考/"
)
# Pre-build each banned entry's fields + regex ONCE, before the file loop. A regex
# depends only on its entry, but i6_build_regex forks `sed` per anchor token, so the
# previous per-(file × entry) rebuild (~330 × 14 ≈ 4.6k builds → ~30k forks) dominated
# I.6 wall-clock on MSYS far more than the scan itself did. Hoisting it makes I.6 run in
# seconds, not minutes. (The PS twin already builds each regex once per entry — this aligns.)
i6_anchors_a=(); i6_reason_a=(); i6_exclude_a=(); i6_rx_a=()
for entry in "${i6_banned[@]}"; do
    IFS='|' read -r e_anchors e_reason e_exclude e_gap <<< "$entry"
    i6_anchors_a+=("$e_anchors"); i6_reason_a+=("$e_reason"); i6_exclude_a+=("$e_exclude")
    i6_rx_a+=("$(i6_build_regex "$e_anchors" "${e_gap:-$i6_gap_default}")")
done
i6_hits=""
while IFS= read -r scan_file; do
    skip=0
    for ex in "${i6_exempt_files[@]}"; do [[ "$scan_file" == "$ex" ]] && { skip=1; break; }; done
    (( skip == 1 )) && continue
    for ed in "${i6_exempt_dirs[@]}"; do [[ "$scan_file" == "$ed"* ]] && { skip=1; break; }; done
    (( skip == 1 )) && continue
    [[ -f "$scan_file" ]] || continue
    # Read the file ONCE into memory, then scan in-process — no `grep` subprocess per
    # (file × banned-entry). The previous engine spawned up to two greps per pair
    # (~330 files × 14 entries × 2 ≈ 9k processes), pathologically slow on Windows/MSYS.
    # This mirrors the PS twin's `Get-Content -Raw` + per-line `[regex]::Match` scan.
    i6_lines=()
    mapfile -t i6_lines < "$scan_file" 2>/dev/null
    for ((bi = 0; bi < ${#i6_banned[@]}; bi++)); do
        e_anchors="${i6_anchors_a[$bi]}"; e_reason="${i6_reason_a[$bi]}"; e_exclude="${i6_exclude_a[$bi]}"
        rx="${i6_rx_a[$bi]}"
        # Tokenize the line-scoped exclude list once per entry (unchanged semantics).
        xtoks=()
        if [[ -n "$e_exclude" ]]; then
            old_ifs="$IFS"; IFS='~'; read -r -a xtoks <<< "$e_exclude"; IFS="$old_ifs"
        fi
        # First regex-matching line wins (grep -m1 parity): on the FIRST line that the
        # ERE matches, decide hit-or-exclude and STOP — do not fall through to a later
        # line even when the first match is exclude-suppressed.
        line_no=0
        for full_line in "${i6_lines[@]}"; do
            line_no=$((line_no + 1))
            # `$rx` MUST stay unquoted so `[[ =~ ]]` treats it as the ERE (quoting it
            # would make it a literal and silently break every match). `nocasematch`
            # makes both the regex match AND the `== *glob*` exclude case-insensitive,
            # replacing the old `grep -i`; it is unset on every exit path so it never
            # leaks into later checks. Uses bash builtins only — no `grep -F -i`, which
            # SIGABRTs on the MSYS GNU grep 3.0 shipped with Git-for-Windows.
            shopt -s nocasematch
            if [[ "$full_line" =~ $rx ]]; then
                span="${BASH_REMATCH[0]}"
                # Line-scoped exclude: reject if any exclude token appears anywhere on
                # the whole matched line. Mirrors the PS `IndexOf` twin exactly.
                excluded=0
                for xtok in "${xtoks[@]}"; do
                    [[ -z "$xtok" ]] && continue
                    [[ "$full_line" == *"$xtok"* ]] && { excluded=1; break; }
                done
                shopt -u nocasematch
                (( excluded )) || i6_hits="${i6_hits}${scan_file}:${line_no} : [${e_anchors}] — ${e_reason} | matched: \"${span:0:120}\""$'\n'
                break
            fi
            shopt -u nocasematch
        done
    done
done < <(git ls-files 2>/dev/null)
if [[ -n "$i6_hits" ]]; then
    step "I.6" "No retired-claim phrases in current docs/templates" "FAIL" "Retired-claim phrases found in live files:
${i6_hits}"
else
    step "I.6" "No retired-claim phrases in current docs/templates" "PASS"
fi

# J.1 — settings.json schema integrity (v0.18.2+)
# See .harness/rules/80-settings-schema.md for the workflow contract.
# Catches the two recurring failure modes hand-edits keep producing:
#   1. Invalid key inside the `hooks` object (additionalProperties:false in schema).
#   2. $schema URL missing the `.json` suffix — redirects to a non-JSON MIME so
#      editors silently flag the whole file as invalid.
# Pure bash + grep — no python/jq dependency (verify_all must run on the
# Git-for-Windows MSYS shell that lacks both). The parser only extracts the
# `$schema` line and the keys inside the top-level `hooks` object; that is
# sufficient to detect both known failure classes without a full JSON parser.
j1_canonical='https://json.schemastore.org/claude-code-settings.json'
j1_valid_hook_events="PreToolUse PostToolUse PostToolUseFailure PermissionRequest PermissionDenied Notification UserPromptSubmit UserPromptExpansion Stop StopFailure SubagentStart SubagentStop PreCompact PostCompact PostToolBatch Elicitation ElicitationResult TeammateIdle TaskCompleted TaskCreated Setup InstructionsLoaded CwdChanged FileChanged ConfigChange WorktreeCreate WorktreeRemove SessionStart SessionEnd"
j1_targets=(".claude/settings.json" "skills/harness-init/templates/common/.claude/settings.json.tmpl")
j1_failures=""
for jt in "${j1_targets[@]}"; do
    [[ -f "$jt" ]] || continue
    # $schema URL check
    schema_url=$(grep -E '^[[:space:]]*"\$schema"[[:space:]]*:' "$jt" | head -1 | \
        sed -E 's/^[[:space:]]*"\$schema"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')
    if [[ -n "$schema_url" && "$schema_url" != "$j1_canonical" ]]; then
        j1_failures="${j1_failures}${jt}: \$schema='${schema_url}' (expected '${j1_canonical}' — non-.json URL serves wrong MIME, breaks editor validation)"$'\n'
    fi
    # Extract keys inside the top-level "hooks": { ... } block. The block ends
    # at the first '}' at indent level 2 (two-space indent matches our template).
    in_hooks=0
    while IFS= read -r jline; do
        if (( in_hooks == 0 )); then
            [[ "$jline" =~ ^[[:space:]]*\"hooks\"[[:space:]]*: ]] && in_hooks=1
            continue
        fi
        # Stop at the closing brace of the hooks block (assumes 2-space indent).
        [[ "$jline" =~ ^[[:space:]]{0,2}\}[[:space:]]*,?[[:space:]]*$ ]] && break
        # Match a key like:   "Foo": ...   at hooks-child indent.
        if [[ "$jline" =~ ^[[:space:]]+\"([^\"]+)\"[[:space:]]*: ]]; then
            jkey="${BASH_REMATCH[1]}"
            # Skip nested keys (hooks[].hooks[] inner objects) — those live
            # two levels deeper. Only direct children of the hooks object are
            # at column 4 (4 spaces). Use indent depth as the discriminator.
            indent="${jline%%\"*}"
            indent_len="${#indent}"
            (( indent_len == 4 )) || continue
            # Is jkey in the valid event list? Word-boundary match.
            if [[ " $j1_valid_hook_events " != *" $jkey "* ]]; then
                j1_failures="${j1_failures}${jt}: hooks.${jkey} is not a valid Claude Code hook event (schema rejects; move doc keys to root)"$'\n'
            fi
        fi
    done < "$jt"
done
if [[ -n "$j1_failures" ]]; then
    step "J.1" "settings.json schema integrity (.claude/ + template)" "FAIL" "settings.json schema violations:
${j1_failures}"
else
    step "J.1" "settings.json schema integrity (.claude/ + template)" "PASS"
fi

# G.4 — Doc count/version claims consistent with plugin.json + live check count (T-008).
# Every place a consumer doc states the verify_all check count and/or the release
# version must agree with (a) plugin.json.version and (b) the live recorded-step count;
# plus a CHANGELOG heading for the current version must exist. This is the standing
# forcing-function that kills the count/version doc-drift class at the gate (G.3's
# neighbour); test-supervisor no longer carries any release-tracking literal.
#
# +-----------------------------------------------------------------------------+
# | G.4 MUST remain the LAST check. Its count is derived as ${#report[@]} + 1    |
# | (sh) / $report.Count + 1 (PS), where the +1 is G.4 itself (its own record    |
# | is appended only AFTER this branch runs). Adding ANY check after G.4 makes   |
# | that derivation undercount -- insert new checks ABOVE this block, never below|
# | The Summary tripwire below cross-checks ${#report[@]} vs this derived value. |
# +-----------------------------------------------------------------------------+
g4_version=$(extract_json_version .claude-plugin/plugin.json)
# Count = recorded steps so far (31) + G.4 itself = the shipped check count (32).
# Status-independent: a WARN on a doc-size check does NOT change the *check* count.
g4_count=$(( ${#report[@]} + 1 ))
g4_bad=""
if [[ -z "$g4_version" ]]; then
    step "G.4" "Doc count/version claims consistent with plugin.json + live check count" "FAIL" \
        "could not read version from .claude-plugin/plugin.json"
else
    # Parallel arrays (file | shape-ERE | exact SOT-derived expected substring).
    # Patterns stay count-anchored (parenthesized `(N checks)` / `runs all N checks` /
    # `N/N` ratio / badge `verify__all-N%2FN` / full-width-paren `（N 项检查）` /
    # JSON-field forms) so historical bare Roadmap/CHANGELOG rows are never matched.
    # The expected substring is the load-bearing test (literal `[[ == *..* ]]`, mirrors
    # PS `.Contains()`); the shape ERE only improves the FAIL message. NOTE: two rows
    # can target the SAME file (dev-map.md L60+L133, AI-GUIDE.md L36+L69) — because the
    # test is whole-file, each row's expect MUST be unique within its file or a sibling
    # line silently masks drift (the dev-map L60 `(N checks)` vs L133 `runs all N checks`).
    g4_files=(
        "AI-GUIDE.md"
        "AI-GUIDE.md"
        "docs/dev-map.md"
        "docs/dev-map.md"
        ".harness/rules/40-locations.md"
        "README.md"
        "README.zh-CN.md"
        "README.md"
        "README.zh-CN.md"
        "docs/manual-e2e-test.md"
        ".harness/scripts/baseline.json"
    )
    g4_shapes=(
        '[0-9]+/[0-9]+'
        '[0-9]+ checks'
        '\([0-9]+ checks\)'
        'runs all [0-9]+ checks'
        '\([0-9]+ checks'
        'verify__all-[0-9]+%2F[0-9]+'
        'verify__all-[0-9]+%2F[0-9]+'
        '\([0-9]+ checks\)'
        '（[0-9]+ 项检查）'
        '[0-9]+ checks'
        '"verify_all_checks": [0-9]+'
    )
    g4_expects=(
        "$g4_count/$g4_count"
        "$g4_count checks"
        "($g4_count checks)"
        "runs all $g4_count checks"
        "($g4_count checks"
        "verify__all-$g4_count%2F$g4_count"
        "verify__all-$g4_count%2F$g4_count"
        "($g4_count checks)"
        "（$g4_count 项检查）"
        "$g4_count checks"
        "\"verify_all_checks\": $g4_count"
    )
    for i in "${!g4_files[@]}"; do
        g4_f="${g4_files[$i]}"
        g4_shape="${g4_shapes[$i]}"
        g4_expect="${g4_expects[$i]}"
        if [[ ! -f "$g4_f" ]]; then
            g4_bad="${g4_bad}${g4_f}: file missing (expected '${g4_expect}')"$'\n'
            continue
        fi
        g4_raw=$(cat "$g4_f")
        [[ "$g4_raw" == *"$g4_expect"* ]] && continue
        g4_found=$(grep -oE -m1 -- "$g4_shape" "$g4_f" 2>/dev/null || true)
        if [[ -n "$g4_found" ]]; then
            g4_bad="${g4_bad}${g4_f}: found '${g4_found}', expected '${g4_expect}'"$'\n'
        else
            g4_bad="${g4_bad}${g4_f}: no '${g4_shape}' claim found, expected '${g4_expect}'"$'\n'
        fi
    done
    # CHANGELOG heading for the current version must exist (re-homed from the removed
    # test-supervisor CHANGELOG assert; G.3 never reads CHANGELOG).
    if ! grep -qF -- "[$g4_version]" CHANGELOG.md 2>/dev/null; then
        g4_bad="${g4_bad}CHANGELOG.md: missing '[$g4_version]' heading for current version"$'\n'
    fi
    if [[ -n "$g4_bad" ]]; then
        step "G.4" "Doc count/version claims consistent with plugin.json + live check count" "FAIL" \
            "doc count/version claims out of sync with plugin.json=$g4_version, live count=$g4_count:
${g4_bad}"
    else
        step "G.4" "Doc count/version claims consistent with plugin.json + live check count" "PASS"
    fi
fi

# Summary
echo ""
echo "=== Summary ==="
pass_count=$(printf '%s\n' "${report[@]}" | grep -c PASS || true)
# G.4 self-reference tripwire: G.4 derived the expected count as (${#report[@]} + 1)
# from inside its own branch (before its record was appended). Now that every record
# IS appended, the G.4 record must be the LAST one. If a check was added after G.4,
# the derived count under-counts -- FAIL loudly. (Mechanical backstop for the binding
# "G.4 must stay last" pin-comment above the G.4 block.)
g4_last="${report[${#report[@]}-1]}"
if [[ "${g4_last%%|*}" != "G.4" ]]; then
    echo "  TRIPWIRE FAIL: G.4 is not the last recorded check (last='${g4_last%%|*}') — a check was added after G.4; its count derivation under-counts. Move new checks ABOVE G.4."
    ((errors++))
fi
echo "  PASS: $pass_count"
echo "  WARN: $warns"
echo "  FAIL: $errors"

ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
printf '{"timestamp":"%s","pass":%d,"warn":%d,"fail":%d}\n' "$ts" "$pass_count" "$warns" "$errors" >> .harness/scripts/verification_history.log

(( errors > 0 )) && exit 2
(( warns > 0 )) && exit 1
exit 0
