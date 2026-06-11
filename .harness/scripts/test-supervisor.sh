#!/usr/bin/env bash
# test-supervisor.sh — Regression for the supervisor agent + /harness-supervise skill (v0.17.1)
# Bash twin of test-supervisor.ps1. Mirrors the same assertion set.
set -uo pipefail

# Script lives at .harness/scripts/ — repo root is two levels up.
repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$repo_root"

pass=0
fail=0
failures=()

assert() {
    local name="$1"
    local ok="$2"
    if [[ "$ok" == "1" ]]; then
        echo "  PASS  $name"
        pass=$((pass + 1))
    else
        echo "  FAIL  $name"
        fail=$((fail + 1))
        failures+=("$name")
    fi
}

# Detection emulators — must mirror supervisor.md §"Anti-pattern catalog" ladder.
get_rollback_counts() {
    # Outputs lines: stage<TAB>count
    local pmlog="$1"
    [[ -f "$pmlog" ]] || return 0
    awk '
        /^### Stage [0-9]+/ { match($0, /Stage ([0-9]+)/, m); stage = m[1]; next }
        /^### Rollback/ { if (stage != "") counts[stage]++ }
        END { for (s in counts) print s "\t" counts[s] }
    ' "$pmlog"
}

same_stage_severity() {
    # arg: counts text (multi-line)
    local counts_text="$1"
    local max=0
    while IFS=$'\t' read -r _stage n; do
        [[ -z "${n:-}" ]] && continue
        (( n > max )) && max=$n
    done <<< "$counts_text"
    if (( max >= 3 )); then echo "ALERT"
    elif (( max >= 2 )); then echo "WARN"
    else echo "NONE"
    fi
}

cross_stage_severity() {
    local counts_text="$1"
    local total=0
    while IFS=$'\t' read -r _stage n; do
        [[ -z "${n:-}" ]] && continue
        total=$((total + n))
    done <<< "$counts_text"
    if (( total >= 4 )); then echo "ALERT"
    elif (( total == 3 )); then echo "WARN"
    elif (( total == 2 )); then echo "INFO"
    else echo "NONE"
    fi
}

missing_intervention_count() {
    local pmlog="$1"
    [[ -f "$pmlog" ]] || { echo "-1"; return; }
    # Scope: distinct stage numbers vs intervention-check entries between consecutive distinct stages.
    # Round-to-round events within a single stage are NOT audited (F-4).
    local stages
    stages=$(grep -oE '^### Stage [0-9]+' "$pmlog" | grep -oE '[0-9]+' | awk '!seen[$0]++' | sort -n)
    local checks
    checks=$(grep -oE '^### Intervention check between stages [0-9]+→[0-9]+' "$pmlog" | grep -oE '[0-9]+→[0-9]+' || true)
    local stages_arr=()
    while IFS= read -r s; do [[ -n "$s" ]] && stages_arr+=("$s"); done <<< "$stages"
    if (( ${#stages_arr[@]} < 2 )); then echo "0"; return; fi
    local missing=0
    local i
    for ((i = 0; i < ${#stages_arr[@]} - 1; i++)); do
        local from="${stages_arr[i]}"
        local to="${stages_arr[i+1]}"
        local key="${from}→${to}"
        if ! grep -qF -- "$key" <<< "$checks"; then
            missing=$((missing + 1))
        fi
    done
    echo "$missing"
}

verdict_from_report() {
    local report="$1"
    [[ -f "$report" ]] || { echo ""; return; }
    # last 5 non-blank lines
    local tail
    tail=$(grep -v '^[[:space:]]*$' "$report" | tail -n 5)
    while IFS= read -r line; do
        if [[ "$line" =~ ^Verdict:\ (HEALTHY|WATCH|INTERVENE)$ ]]; then
            echo "${BASH_REMATCH[1]}"
            return
        fi
    done <<< "$tail"
    echo ""
}

echo "=== test-supervisor: agent + skill regression (bash) ==="
echo "Repo: $repo_root"
echo ""

# --- AC-1: agent contract
# v0.30 cutover: supervisor is plugin-native — single source at top-level agents/supervisor.md.
echo "--- AC-1: agent contract ---"
sup_path="agents/supervisor.md"
[[ -f "$sup_path" ]] && assert "AC-1.1 $sup_path exists (plugin-native)" 1 || assert "AC-1.1 $sup_path exists (plugin-native)" 0
sup_lines=$(wc -l < "$sup_path")
(( sup_lines <= 300 )) && assert "AC-1.2 supervisor.md <=300 lines ($sup_lines)" 1 || assert "AC-1.2 supervisor.md <=300 lines ($sup_lines)" 0

sup_content=$(cat "$sup_path")
ap_ok=1
for ap in "AP-1" "AP-1b" "AP-2" "AP-3" "AP-4"; do
    grep -qF "$ap" <<< "$sup_content" || ap_ok=0
done
assert "AC-1.3 supervisor.md declares all five anti-pattern identifiers" "$ap_ok"

sev_ok=1
for sev in "INFO" "WARN" "ALERT"; do
    grep -qF "$sev" <<< "$sup_content" || sev_ok=0
done
assert "AC-1.4 supervisor.md uses INFO/WARN/ALERT severity words" "$sev_ok"

ver_ok=1
for ver in "HEALTHY" "WATCH" "INTERVENE"; do
    grep -qF "$ver" <<< "$sup_content" || ver_ok=0
done
assert "AC-1.5 supervisor.md declares HEALTHY/WATCH/INTERVENE verdict words" "$ver_ok"

# Frontmatter tools: line must exclude Edit/Bash/PowerShell/Task/AskUserQuestion (NFR-4)
tools_line=$(head -6 "$sup_path" | grep -E '^tools:' | head -1)
tools_ok=1
for f in "Edit" "Bash" "PowerShell" "Task" "AskUserQuestion"; do
    if grep -qE "\b${f}\b" <<< "$tools_line"; then tools_ok=0; fi
done
assert "AC-1.6 supervisor.md frontmatter excludes Edit/Bash/PowerShell/Task/AskUserQuestion" "$tools_ok"

# --- AC-2: plugin-native single source (v0.30 cutover)
# The supervisor is now a single plugin-native source; there is NO templates/common copy
# to keep byte-identical (the byte-identity invariant retired with the agent cutover).
echo ""
echo "--- AC-2: plugin-native single source ---"
[[ ! -f skills/harness-init/templates/common/.harness/agents/supervisor.md ]] && assert "AC-2.1 no templates/common supervisor copy (single plugin source)" 1 || assert "AC-2.1 no templates/common supervisor copy (single plugin source)" 0
[[ ! -f .harness/agents/supervisor.md ]] && assert "AC-2.2 no .harness/agents supervisor copy (plugin-native at agents/)" 1 || assert "AC-2.2 no .harness/agents supervisor copy (plugin-native at agents/)" 0
if bash "$repo_root/.harness/scripts/sync-self.sh" --check &>/dev/null; then
    assert "AC-2.3 sync-self --check is clean" 1
else
    assert "AC-2.3 sync-self --check is clean" 0
fi

# --- AC-3: skill contract
echo ""
echo "--- AC-3: skill contract ---"
[[ -f skills/harness-supervise/SKILL.md ]] && assert "AC-3.1 SKILL.md exists" 1 || assert "AC-3.1 SKILL.md exists" 0

allowed_line=$(head -8 skills/harness-supervise/SKILL.md | grep -E '^allowed-tools:' | head -1)
allowed_ok=1
for f in "Edit" "Bash" "PowerShell" "Task" "AskUserQuestion"; do
    if grep -qE "\b${f}\b" <<< "$allowed_line"; then allowed_ok=0; fi
done
grep -qE '\bRead\b' <<< "$allowed_line" || allowed_ok=0
grep -qE '\bWrite\b' <<< "$allowed_line" || allowed_ok=0
assert "AC-3.2 SKILL.md allowed-tools is subset of {Read, Write, Glob, Grep}" "$allowed_ok"

skill_content=$(cat skills/harness-supervise/SKILL.md)
args_ok=1
for s in "task-slug" "\-\-recent" "\-\-all"; do
    grep -qE "$s" <<< "$skill_content" || args_ok=0
done
assert "AC-3.3 SKILL.md documents three argument shapes" "$args_ok"

grep -qF "HARNESS_SUPERVISOR_MOCK" <<< "$skill_content" \
    && assert "AC-3.4 SKILL.md mentions HARNESS_SUPERVISOR_MOCK" 1 \
    || assert "AC-3.4 SKILL.md mentions HARNESS_SUPERVISOR_MOCK" 0

# --- AC-4: HEALTHY fixture
echo ""
echo "--- AC-4: HEALTHY fixture ---"
healthy_pm="skills/harness-supervise/fixtures/sample-task/PM_LOG.md"
[[ -f "$healthy_pm" ]] && assert "AC-4.1 HEALTHY fixture PM_LOG exists" 1 || assert "AC-4.1 HEALTHY fixture PM_LOG exists" 0
healthy_counts=$(get_rollback_counts "$healthy_pm")
healthy_total=0
while IFS=$'\t' read -r _s n; do [[ -n "${n:-}" ]] && healthy_total=$((healthy_total + n)); done <<< "$healthy_counts"
(( healthy_total == 0 )) && assert "AC-4.2 HEALTHY fixture has zero rollbacks" 1 || assert "AC-4.2 HEALTHY fixture has zero rollbacks ($healthy_total)" 0

[[ "$(same_stage_severity "$healthy_counts")" == "NONE" ]] \
    && assert "AC-4.3 HEALTHY AP-1 ladder = NONE" 1 \
    || assert "AC-4.3 HEALTHY AP-1 ladder = NONE" 0
[[ "$(cross_stage_severity "$healthy_counts")" == "NONE" ]] \
    && assert "AC-4.4 HEALTHY AP-1b ladder = NONE" 1 \
    || assert "AC-4.4 HEALTHY AP-1b ladder = NONE" 0
healthy_missing=$(missing_intervention_count "$healthy_pm")
[[ "$healthy_missing" == "0" ]] \
    && assert "AC-4.5 HEALTHY AP-3 missing-intervention-check count = 0" 1 \
    || assert "AC-4.5 HEALTHY AP-3 missing-intervention-check count = $healthy_missing" 0

# Verdict mapping
healthy_sevA=$(same_stage_severity "$healthy_counts")
healthy_sevB=$(cross_stage_severity "$healthy_counts")
healthy_verdict_ok=1
if [[ "$healthy_sevA" == "ALERT" || "$healthy_sevA" == "WARN" || "$healthy_sevB" == "WARN" || "$healthy_sevB" == "ALERT" || "$healthy_missing" -ge 1 ]]; then
    healthy_verdict_ok=0
fi
assert "AC-4.6 HEALTHY fixture verdict mapping = HEALTHY" "$healthy_verdict_ok"

# --- AC-5: 3-rollback fixture
echo ""
echo "--- AC-5: 3-rollback ALERT fixture ---"
alert_pm="skills/harness-supervise/fixtures/sample-task-three-rollbacks/PM_LOG.md"
[[ -f "$alert_pm" ]] && assert "AC-5.1 3-rollback fixture PM_LOG exists" 1 || assert "AC-5.1 3-rollback fixture PM_LOG exists" 0
alert_counts=$(get_rollback_counts "$alert_pm")
alert_stage5=$(echo "$alert_counts" | awk -F'\t' '$1=="5" {print $2}')
[[ "$alert_stage5" == "3" ]] \
    && assert "AC-5.2 3-rollback fixture: Stage 5 has 3 rollbacks" 1 \
    || assert "AC-5.2 3-rollback fixture: Stage 5 has 3 rollbacks (got '$alert_stage5')" 0
[[ "$(same_stage_severity "$alert_counts")" == "ALERT" ]] \
    && assert "AC-5.3 3-rollback fixture AP-1 ladder = ALERT" 1 \
    || assert "AC-5.3 3-rollback fixture AP-1 ladder = ALERT" 0
[[ "$(same_stage_severity "$alert_counts")" == "ALERT" ]] \
    && assert "AC-5.4 3-rollback fixture verdict = INTERVENE" 1 \
    || assert "AC-5.4 3-rollback fixture verdict = INTERVENE" 0

# --- AC-6 (snapshot): T-002 archived
echo ""
echo "--- AC-6: snapshot on T-002 archived (ai-native-init) ---"
t002_pm="docs/features/_archived/ai-native-init/PM_LOG.md"
[[ -f "$t002_pm" ]] && assert "AC-6.1 T-002 PM_LOG exists" 1 || assert "AC-6.1 T-002 PM_LOG exists" 0
t002_counts=$(get_rollback_counts "$t002_pm")
t002_s5=$(echo "$t002_counts" | awk -F'\t' '$1=="5" {print $2}')
t002_s6=$(echo "$t002_counts" | awk -F'\t' '$1=="6" {print $2}')
[[ "$t002_s5" == "1" ]] \
    && assert "AC-6.2 T-002: Stage 5 = 1 rollback" 1 \
    || assert "AC-6.2 T-002: Stage 5 = 1 rollback (got '$t002_s5')" 0
[[ "$t002_s6" == "1" ]] \
    && assert "AC-6.3 T-002: Stage 6 = 1 rollback" 1 \
    || assert "AC-6.3 T-002: Stage 6 = 1 rollback (got '$t002_s6')" 0
[[ "$(same_stage_severity "$t002_counts")" == "NONE" ]] \
    && assert "AC-6.4 T-002 AP-1 same-stage = NONE" 1 \
    || assert "AC-6.4 T-002 AP-1 same-stage = NONE" 0
[[ "$(cross_stage_severity "$t002_counts")" == "INFO" ]] \
    && assert "AC-6.5 T-002 AP-1b cross-stage = INFO" 1 \
    || assert "AC-6.5 T-002 AP-1b cross-stage = INFO" 0
t002_missing=$(missing_intervention_count "$t002_pm")
[[ "$t002_missing" == "0" ]] \
    && assert "AC-6.6 T-002 AP-3 missing = 0" 1 \
    || assert "AC-6.6 T-002 AP-3 missing = 0 (got '$t002_missing')" 0
[[ -f "docs/features/_archived/ai-native-init/01_REQUIREMENT_ANALYSIS.md" ]] \
    && assert "AC-6.7 T-002 archived under _archived/ (AP-4 cannot fire)" 1 \
    || assert "AC-6.7 T-002 archived under _archived/ (AP-4 cannot fire)" 0

t002_sevA=$(same_stage_severity "$t002_counts")
t002_sevB=$(cross_stage_severity "$t002_counts")
t002_verdict_ok=1
if [[ "$t002_sevA" == "ALERT" || "$t002_sevA" == "WARN" || "$t002_sevB" == "WARN" || "$t002_sevB" == "ALERT" || "$t002_missing" -ge 1 ]]; then
    t002_verdict_ok=0
fi
assert "AC-6.8 T-002 verdict mapping = HEALTHY" "$t002_verdict_ok"

# --- AC-7: HARNESS_SUPERVISOR_MOCK
echo ""
echo "--- AC-7: HARNESS_SUPERVISOR_MOCK fixture ---"
mock_fixture="skills/harness-supervise/fixtures/supervisor-mock.json"
[[ -f "$mock_fixture" ]] && assert "AC-7.1 supervisor-mock.json exists" 1 || assert "AC-7.1 supervisor-mock.json exists" 0

# Parse via python3 if available; gate the JSON-validation assertion otherwise (same pattern as test-init.sh:198-201)
if command -v python3 >/dev/null 2>&1 && python3 -c 'import json' >/dev/null 2>&1; then
    python3 -c "
import json,sys
with open('$mock_fixture','r',encoding='utf-8') as f: d=json.load(f)
sys.exit(0 if 'report_md' in d and 'Verdict:' in d['report_md'] else 1)
" >/dev/null 2>&1 \
        && assert "AC-7.2 supervisor-mock.json parses and has report_md with verdict line" 1 \
        || assert "AC-7.2 supervisor-mock.json parses and has report_md with verdict line" 0
else
    # python3 absent — gate the deep parse, but at least confirm the file has the verdict literal
    grep -qF "Verdict: HEALTHY" "$mock_fixture" \
        && assert "AC-7.2 supervisor-mock.json contains 'Verdict: HEALTHY' (python3 absent — shallow grep)" 1 \
        || assert "AC-7.2 supervisor-mock.json contains 'Verdict: HEALTHY' (python3 absent — shallow grep)" 0
fi

# Mock round-trip in its own temp dir
mock_tmp=$(mktemp -d -t harness-supervise-mock-XXXXXX 2>/dev/null || mktemp -d)
trap 'rm -rf "$mock_tmp" 2>/dev/null || true' EXIT
report_path="$mock_tmp/SUPERVISION_REPORT.md"
if command -v python3 >/dev/null 2>&1 && python3 -c 'import json' >/dev/null 2>&1; then
    python3 -c "
import json
with open('$mock_fixture','r',encoding='utf-8') as f: d=json.load(f)
with open('$report_path','w',encoding='utf-8',newline='') as g: g.write(d['report_md'])
"
    if [[ -f "$report_path" ]]; then
        # Last non-blank line must be Verdict: ...
        last_line=$(grep -v '^[[:space:]]*$' "$report_path" | tail -n 1)
        if [[ "$last_line" =~ ^Verdict:\ (HEALTHY|WATCH|INTERVENE)$ ]]; then
            assert "AC-7.3 mock round-trip: last non-blank line is a valid Verdict" 1
        else
            assert "AC-7.3 mock round-trip: last non-blank line is a valid Verdict (got '$last_line')" 0
        fi
    else
        assert "AC-7.3 mock round-trip: report file written" 0
    fi
fi

# Separate temp dir for the unreadable-mock fallback (insight L15: bidirectional → separate dirs)
fallback_tmp=$(mktemp -d -t harness-supervise-fallback-XXXXXX 2>/dev/null || mktemp -d)
trap 'rm -rf "$mock_tmp" "$fallback_tmp" 2>/dev/null || true' EXIT
fallback_path="$fallback_tmp/does-not-exist.json"
[[ ! -f "$fallback_path" ]] \
    && assert "AC-7.4 unreadable HARNESS_SUPERVISOR_MOCK is detected (skill must fall back)" 1 \
    || assert "AC-7.4 unreadable HARNESS_SUPERVISOR_MOCK is detected (skill must fall back)" 0

# --- I.7 contract in-process emulation
echo ""
echo "--- I.7 contract: ignored INTERVENE reports ---"
i7_tmp=$(mktemp -d -t harness-supervise-i7-XXXXXX 2>/dev/null || mktemp -d)
trap 'rm -rf "$mock_tmp" "$fallback_tmp" "$i7_tmp" 2>/dev/null || true' EXIT
printf '# Title\n\nSome body.\n\nVerdict: HEALTHY\n' > "$i7_tmp/report-healthy.md"
printf '# Title\n\nSome body.\n\nVerdict: INTERVENE\n' > "$i7_tmp/report-intervene.md"
# Negative-case fixture for Q-1 fixed-case enforcement (BUG-1 cross-shell symmetry guard).
# Bash `[[ =~ ]]` is case-sensitive by default, so this assertion is implicit;
# we add it explicitly to mirror the PS BUG-1 regression guard.
printf '# Title\n\nSome body.\n\nverdict: intervene\n' > "$i7_tmp/report-lowercase.md"

[[ "$(verdict_from_report "$i7_tmp/report-healthy.md")" == "HEALTHY" ]] \
    && assert "I.7-emu HEALTHY report parses verdict = HEALTHY" 1 \
    || assert "I.7-emu HEALTHY report parses verdict = HEALTHY" 0
[[ "$(verdict_from_report "$i7_tmp/report-intervene.md")" == "INTERVENE" ]] \
    && assert "I.7-emu INTERVENE report (correct UPPERCASE) parses verdict = INTERVENE (positive Q-1 case)" 1 \
    || assert "I.7-emu INTERVENE report (correct UPPERCASE) parses verdict = INTERVENE (positive Q-1 case)" 0
[[ -z "$(verdict_from_report "$i7_tmp/absent.md")" ]] \
    && assert "I.7-emu non-existent report parses verdict = empty" 1 \
    || assert "I.7-emu non-existent report parses verdict = empty" 0
[[ -z "$(verdict_from_report "$i7_tmp/report-lowercase.md")" ]] \
    && assert "I.7-emu BUG-1 guard: lowercase 'verdict: intervene' does NOT parse (Q-1 fixed-case)" 1 \
    || assert "I.7-emu BUG-1 guard: lowercase 'verdict: intervene' does NOT parse (Q-1 fixed-case)" 0

# --- BUG-2 (v0.17.1): I.7 active-row slug match is column-anchored
echo ""
echo "--- BUG-2: I.7 active-row slug match is column-anchored (no substring collision) ---"
# Emulates the verify_all.sh I.7 active-row grep — column-anchored, not substring.
# A slug `foo` must NOT be flagged active by an Active row for `foo-extra` (ADV-8).
bug2_tasks="$i7_tmp/bug2-tasks.md"
printf '| ID | Slug | Stage | Mode |\n|---|---|---|---|\n| T-1 | foo-extra | development | full |\n| T-2 | foo | done | full |\n' > "$bug2_tasks"
bug2_match=$(grep -E -- "\|[[:space:]]*foo[[:space:]]*\|" "$bug2_tasks" || true)
if [[ "$bug2_match" != *foo-extra* ]]; then
    assert "BUG-2 guard: slug 'foo' does NOT match the 'foo-extra' row (substring collision blocked)" 1
else
    assert "BUG-2 guard: slug 'foo' does NOT match the 'foo-extra' row (substring collision blocked)" 0
fi
bug2_count=$(printf '%s\n' "$bug2_match" | grep -c . || true)
[[ "$bug2_count" == "1" ]] \
    && assert "BUG-2 guard: slug 'foo' matches exactly its own column-anchored row" 1 \
    || assert "BUG-2 guard: slug 'foo' matches exactly its own column-anchored row (got $bug2_count)" 0
bug2_path=$(grep -E -- "\|[[:space:]]*foo[[:space:]]*\|" <<< '| T-3 | bar | done | full | docs/features/_archived/foo/ |' || true)
[[ -z "$bug2_path" ]] \
    && assert "BUG-2 guard: slug 'foo' does NOT match a substring inside a path cell" 1 \
    || assert "BUG-2 guard: slug 'foo' does NOT match a substring inside a path cell" 0

# --- F-4 binding
echo ""
echo "--- F-4: AP-3 round-to-round does NOT count as missing intervention check ---"
[[ "$t002_missing" == "0" ]] \
    && assert "F-4.1 T-002 has round-to-round entries but missing count = 0" 1 \
    || assert "F-4.1 T-002 has round-to-round entries but missing count = $t002_missing" 0

# --- Doc fan-out spot checks
echo ""
echo "--- Doc fan-out spot checks ---"
grep -qE 'auxiliary.*supervisor' AI-GUIDE.md \
    && assert "fan-out: AI-GUIDE.md mentions 'auxiliary (supervisor)' phrasing" 1 \
    || assert "fan-out: AI-GUIDE.md mentions 'auxiliary (supervisor)' phrasing" 0
# NOTE (T-008): the 8 version/count fan-out asserts that hard-coded a release
# version + check count (v0.17.1 / 30 on AI-GUIDE×2, CHANGELOG entry, both README
# badges, plugin.json, marketplace.json, dev-map) were REMOVED here. Their coverage
# moved to where it belongs: the four-stamp version consistency is verify_all G.3,
# and the doc count-claim + current-version CHANGELOG-entry consistency is the new
# standing verify_all G.4 meta-check (derives version from plugin.json + count from
# the live recorded-step tally). test-supervisor keeps ZERO release-tracking literals
# so it never drifts on a version/count bump again. Only the 3 version-agnostic
# structural asserts (auxiliary-supervisor phrasing above, harness-status note +
# retired glob below) remain.
# T-020 (v0.31): harness-status no longer lists the supervisor / canonical-7 rows as
# project ASSETS — framework agents (incl. supervisor) are plugin-provided since
# v0.30. Assert the NEW state: the plugin-provided note names the supervisor, and
# the retired .claude/agents canonical-7 glob row is GONE.
grep -qE '\(7 \+ supervisor\).*plugin-provided' skills/harness-status/SKILL.md \
    && assert "fan-out: harness-status SKILL.md notes framework agents (7 + supervisor) are plugin-provided" 1 \
    || assert "fan-out: harness-status SKILL.md notes framework agents (7 + supervisor) are plugin-provided" 0
grep -qF '{pm,req,sol,gate,dev,review,qa}*' skills/harness-status/SKILL.md \
    && assert "fan-out: harness-status SKILL.md retired the canonical-7 asset glob (v0.30 truth)" 0 \
    || assert "fan-out: harness-status SKILL.md retired the canonical-7 asset glob (v0.30 truth)" 1

echo ""
echo "=== Result ==="
echo "  PASS: $pass"
echo "  FAIL: $fail"

if (( fail > 0 )); then
    echo ""
    echo "Failures:"
    for f in "${failures[@]}"; do echo "  - $f"; done
    exit 1
fi
exit 0
