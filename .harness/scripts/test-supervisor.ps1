# test-supervisor.ps1 — Regression for the supervisor agent + /harness-supervise skill (v0.17.1)
#
# Verifies the static contract (agent + skill files) and exercises the anti-pattern
# detectors against three fixtures plus the T-002 archived snapshot (AC-6).
# Detection is emulated in this driver — the supervisor itself runs inside an LLM
# orchestrator; this script asserts the contract and the detector ladders the
# LLM is REQUIRED to follow per supervisor.md §"Anti-pattern catalog".
#
# Usage:
#   .\.harness\scripts\test-supervisor.ps1                 # full run
#   .\.harness\scripts\test-supervisor.ps1 -KeepTemp       # keep temp report dir for inspection

[CmdletBinding()]
param([switch]$KeepTemp)

$ErrorActionPreference = "Stop"
# Script lives at .harness/scripts/ — repo root is two levels up.
$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Push-Location $repoRoot
try {

$pass = 0
$fail = 0
$failures = @()

function Assert($name, [scriptblock]$check) {
    try {
        $r = & $check
        if ($r -eq $false) { throw "predicate returned false" }
        Write-Host "  PASS  $name" -ForegroundColor Green
        $script:pass++
    } catch {
        Write-Host "  FAIL  $name" -ForegroundColor Red
        Write-Host "        $_" -ForegroundColor DarkRed
        $script:fail++
        $script:failures += "$name :: $_"
    }
}

# --- Anti-pattern emulators (must mirror supervisor.md §"Anti-pattern catalog" ladder)
function Get-RollbackCounts($pmLogPath) {
    $counts = @{}
    if (-not (Test-Path $pmLogPath)) { return $counts }
    $stage = $null
    Get-Content $pmLogPath | ForEach-Object {
        if ($_ -match '^### Stage (\d+)') { $stage = $Matches[1] }
        elseif ($_ -match '^### Rollback') {
            if ($stage) {
                if (-not $counts.ContainsKey($stage)) { $counts[$stage] = 0 }
                $counts[$stage] = $counts[$stage] + 1
            }
        }
    }
    return $counts
}

function Get-SameStageSeverity($counts) {
    # Highest severity across stages.
    $sev = "NONE"
    foreach ($k in $counts.Keys) {
        $n = $counts[$k]
        if ($n -ge 3) { return "ALERT" }
        if ($n -ge 2 -and $sev -ne "ALERT") { $sev = "WARN" }
    }
    return $sev
}

function Get-CrossStageSeverity($counts) {
    $total = 0
    foreach ($k in $counts.Keys) { $total += $counts[$k] }
    if ($total -ge 4) { return "ALERT" }
    if ($total -eq 3) { return "WARN" }
    if ($total -eq 2) { return "INFO" }
    return "NONE"
}

function Get-MissingInterventionCount($pmLogPath) {
    # Count stage-to-stage transitions present vs intervention-check entries between them.
    # Per F-4 / supervisor.md §AP-3: stage-to-stage only; round-to-round NOT audited.
    if (-not (Test-Path $pmLogPath)) { return -1 }  # -1 = INFO only path
    $stages = @()
    $checks = @()
    Get-Content $pmLogPath | ForEach-Object {
        if ($_ -match '^### Stage (\d+)') { $stages += [int]$Matches[1] }
        elseif ($_ -match '^### Intervention check between stages (\d+)→(\d+)') {
            $checks += "$($Matches[1])→$($Matches[2])"
        }
    }
    # Distinct stage transitions (e.g. 5→6 counted once even with multiple rounds at 5)
    $distinctStages = $stages | Select-Object -Unique
    if ($distinctStages.Count -lt 2) { return 0 }
    $sorted = $distinctStages | Sort-Object
    $expected = @()
    for ($i = 0; $i -lt $sorted.Count - 1; $i++) {
        $expected += "$($sorted[$i])→$($sorted[$i+1])"
    }
    $missing = 0
    foreach ($t in $expected) {
        if ($checks -notcontains $t) { $missing++ }
    }
    return $missing
}

Write-Host "=== test-supervisor: agent + skill regression ===" -ForegroundColor Cyan
Write-Host "Repo: $repoRoot"
Write-Host ""

# --- AC-1: supervisor.md exists, <=300 lines, declares APs + allowed-tools subset
Write-Host "--- AC-1: agent contract ---" -ForegroundColor Cyan
Assert "AC-1.1 .harness/agents/supervisor.md exists" {
    Test-Path ".harness/agents/supervisor.md"
}
Assert "AC-1.2 supervisor.md <=300 lines" {
    $n = (Get-Content ".harness/agents/supervisor.md" | Measure-Object -Line).Lines
    $n -le 300
}
Assert "AC-1.3 supervisor.md declares all five anti-pattern identifiers (AP-1, AP-1b, AP-2, AP-3, AP-4)" {
    $c = Get-Content ".harness/agents/supervisor.md" -Raw
    ($c -match 'AP-1[^b0-9]') -and ($c -match 'AP-1b') -and ($c -match 'AP-2') -and ($c -match 'AP-3') -and ($c -match 'AP-4')
}
Assert "AC-1.4 supervisor.md uses the three severity words INFO/WARN/ALERT" {
    $c = Get-Content ".harness/agents/supervisor.md" -Raw
    ($c -match 'INFO') -and ($c -match 'WARN') -and ($c -match 'ALERT')
}
Assert "AC-1.5 supervisor.md declares the three verdict words HEALTHY/WATCH/INTERVENE" {
    $c = Get-Content ".harness/agents/supervisor.md" -Raw
    ($c -match 'HEALTHY') -and ($c -match 'WATCH') -and ($c -match 'INTERVENE')
}
Assert "AC-1.6 supervisor.md frontmatter 'tools:' line excludes Edit/Bash/PowerShell/Task/AskUserQuestion (NFR-4)" {
    $head = (Get-Content ".harness/agents/supervisor.md" -TotalCount 6) -join "`n"
    if ($head -notmatch '(?m)^tools:\s*(.+)$') { throw "tools: line not found" }
    $toolsLine = $Matches[1]
    $forbidden = @("Edit", "Bash", "PowerShell", "Task", "AskUserQuestion")
    foreach ($f in $forbidden) {
        # Word-boundary match so 'Task' doesn't false-positive on 'Task-tool' references in body
        if ($toolsLine -match "\b$f\b") { throw "frontmatter tools: line contains forbidden tool '$f'" }
    }
    $true
}

# --- AC-2: dogfood vs template byte-identical
Write-Host ""
Write-Host "--- AC-2: dogfood/template byte-identity ---" -ForegroundColor Cyan
Assert "AC-2.1 templates/common/.harness/agents/supervisor.md exists" {
    Test-Path "skills/harness-init/templates/common/.harness/agents/supervisor.md"
}
Assert "AC-2.2 supervisor.md is byte-identical between dogfood and template (sha256)" {
    $h1 = (Get-FileHash ".harness/agents/supervisor.md" -Algorithm SHA256).Hash
    $h2 = (Get-FileHash "skills/harness-init/templates/common/.harness/agents/supervisor.md" -Algorithm SHA256).Hash
    $h1 -eq $h2
}
Assert "AC-2.3 sync-self --check is clean (E.1 will agree)" {
    & (Join-Path $PSScriptRoot "sync-self.ps1") -Check | Out-Null
    $LASTEXITCODE -eq 0
}

# --- AC-3: skill contract
Write-Host ""
Write-Host "--- AC-3: skill contract ---" -ForegroundColor Cyan
Assert "AC-3.1 skills/harness-supervise/SKILL.md exists" {
    Test-Path "skills/harness-supervise/SKILL.md"
}
Assert "AC-3.2 SKILL.md frontmatter 'allowed-tools:' is subset of {Read, Write, Glob, Grep}" {
    $head = (Get-Content "skills/harness-supervise/SKILL.md" -TotalCount 8) -join "`n"
    if ($head -notmatch '(?m)^allowed-tools:\s*(.+)$') { throw "allowed-tools: not found" }
    $line = $Matches[1]
    $forbidden = @("Edit", "Bash", "PowerShell", "Task", "AskUserQuestion")
    foreach ($f in $forbidden) {
        if ($line -match "\b$f\b") { throw "allowed-tools line contains forbidden tool '$f'" }
    }
    # And must contain at least Read + Write
    ($line -match '\bRead\b') -and ($line -match '\bWrite\b')
}
Assert "AC-3.3 SKILL.md documents three argument shapes (<slug>, --recent, --all)" {
    $c = Get-Content "skills/harness-supervise/SKILL.md" -Raw
    ($c -match 'task-slug') -and ($c -match '--recent') -and ($c -match '--all')
}
Assert "AC-3.4 SKILL.md mentions HARNESS_SUPERVISOR_MOCK env var" {
    $c = Get-Content "skills/harness-supervise/SKILL.md" -Raw
    $c -match 'HARNESS_SUPERVISOR_MOCK'
}

# --- AC-4: HEALTHY fixture
Write-Host ""
Write-Host "--- AC-4: HEALTHY fixture ---" -ForegroundColor Cyan
$healthyPm = "skills/harness-supervise/fixtures/sample-task/PM_LOG.md"
Assert "AC-4.1 HEALTHY fixture PM_LOG exists" { Test-Path $healthyPm }
$healthyCounts = Get-RollbackCounts $healthyPm
Assert "AC-4.2 HEALTHY fixture has zero rollbacks" {
    $total = 0
    foreach ($k in $healthyCounts.Keys) { $total += $healthyCounts[$k] }
    $total -eq 0
}
Assert "AC-4.3 HEALTHY fixture AP-1 ladder = NONE" {
    (Get-SameStageSeverity $healthyCounts) -eq "NONE"
}
Assert "AC-4.4 HEALTHY fixture AP-1b ladder = NONE" {
    (Get-CrossStageSeverity $healthyCounts) -eq "NONE"
}
Assert "AC-4.5 HEALTHY fixture AP-3 missing-intervention-check count = 0" {
    (Get-MissingInterventionCount $healthyPm) -eq 0
}
Assert "AC-4.6 HEALTHY fixture verdict mapping = HEALTHY" {
    $sameStage = Get-SameStageSeverity $healthyCounts
    $crossStage = Get-CrossStageSeverity $healthyCounts
    $missing = Get-MissingInterventionCount $healthyPm
    $hasAlert = ($sameStage -eq "ALERT") -or ($missing -ge 3)
    $hasWarn = ($sameStage -eq "WARN") -or ($crossStage -eq "WARN") -or ($missing -ge 1)
    (-not $hasAlert) -and (-not $hasWarn)
}

# --- AC-5: 3-rollback ALERT fixture
Write-Host ""
Write-Host "--- AC-5: ALERT (3 same-stage rollbacks) fixture ---" -ForegroundColor Cyan
$alertPm = "skills/harness-supervise/fixtures/sample-task-three-rollbacks/PM_LOG.md"
Assert "AC-5.1 3-rollback fixture PM_LOG exists" { Test-Path $alertPm }
$alertCounts = Get-RollbackCounts $alertPm
Assert "AC-5.2 3-rollback fixture: Stage 5 has 3 rollbacks (AP-1 ALERT input)" {
    $alertCounts["5"] -eq 3
}
Assert "AC-5.3 3-rollback fixture AP-1 ladder = ALERT" {
    (Get-SameStageSeverity $alertCounts) -eq "ALERT"
}
Assert "AC-5.4 3-rollback fixture verdict mapping = INTERVENE" {
    $sameStage = Get-SameStageSeverity $alertCounts
    $hasAlert = ($sameStage -eq "ALERT")
    $hasAlert
}

# --- AC-6 (snapshot): T-002 archived state
Write-Host ""
Write-Host "--- AC-6: snapshot on T-002 archived (ai-native-init) ---" -ForegroundColor Cyan
$t002Pm = "docs/features/_archived/ai-native-init/PM_LOG.md"
Assert "AC-6.1 T-002 archived PM_LOG exists" { Test-Path $t002Pm }
$t002Counts = Get-RollbackCounts $t002Pm
Assert "AC-6.2 T-002: Stage 5 has exactly 1 rollback (AP-1 same-stage finds nothing)" {
    $t002Counts["5"] -eq 1
}
Assert "AC-6.3 T-002: Stage 6 has exactly 1 rollback (AP-1 same-stage finds nothing)" {
    $t002Counts["6"] -eq 1
}
Assert "AC-6.4 T-002 AP-1 same-stage ladder = NONE (no stage has >=2 rollbacks)" {
    (Get-SameStageSeverity $t002Counts) -eq "NONE"
}
Assert "AC-6.5 T-002 AP-1b cross-stage ladder = INFO (2 total rollbacks, different stages)" {
    (Get-CrossStageSeverity $t002Counts) -eq "INFO"
}
Assert "AC-6.6 T-002 AP-3 missing-intervention-check count = 0 (every stage-to-stage transition logged)" {
    (Get-MissingInterventionCount $t002Pm) -eq 0
}
Assert "AC-6.7 T-002 AP-4 absent (task is archived under _archived/)" {
    # If stage docs live in _archived/, AP-4 never fires.
    Test-Path "docs/features/_archived/ai-native-init/01_REQUIREMENT_ANALYSIS.md"
}
Assert "AC-6.8 T-002 verdict mapping = HEALTHY (no WARN, no ALERT)" {
    $sameStage = Get-SameStageSeverity $t002Counts
    $crossStage = Get-CrossStageSeverity $t002Counts
    $missing = Get-MissingInterventionCount $t002Pm
    $hasAlert = ($sameStage -eq "ALERT") -or ($missing -ge 3)
    $hasWarn = ($sameStage -eq "WARN") -or ($crossStage -eq "WARN") -or ($missing -ge 1) -or ($missing -eq 2)
    (-not $hasAlert) -and (-not $hasWarn)
}

# --- AC-7: HARNESS_SUPERVISOR_MOCK pattern (mock-fixture round-trip)
Write-Host ""
Write-Host "--- AC-7: HARNESS_SUPERVISOR_MOCK fixture ---" -ForegroundColor Cyan
$mockFixture = "skills/harness-supervise/fixtures/supervisor-mock.json"
Assert "AC-7.1 supervisor-mock.json exists" { Test-Path $mockFixture }
Assert "AC-7.2 supervisor-mock.json parses as JSON" {
    $null -ne (Get-Content $mockFixture -Raw | ConvertFrom-Json)
}
Assert "AC-7.3 supervisor-mock.json has 'report_md' field with verdict line" {
    $j = Get-Content $mockFixture -Raw | ConvertFrom-Json
    ($null -ne $j.report_md) -and ($j.report_md -match 'Verdict: (HEALTHY|WATCH|INTERVENE)')
}

# AC-7 mock-fixture round-trip: skill behavior simulated — when env var set,
# the mock's report_md must equal what would be written to disk verbatim.
$mockTmp = Join-Path ([System.IO.Path]::GetTempPath()) "harness-supervise-mock-$(Get-Random)"
New-Item -ItemType Directory -Path $mockTmp -Force | Out-Null
try {
    $env:HARNESS_SUPERVISOR_MOCK = (Resolve-Path $mockFixture).Path
    $mockJson = Get-Content $env:HARNESS_SUPERVISOR_MOCK -Raw | ConvertFrom-Json
    $reportBody = $mockJson.report_md
    $reportPath = Join-Path $mockTmp "SUPERVISION_REPORT.md"
    # Simulate the skill's step 3 — write the mock body verbatim.
    [System.IO.File]::WriteAllText($reportPath, $reportBody)
    Assert "AC-7.4 mock round-trip: written report bytes match mock fixture's report_md" {
        $written = Get-Content $reportPath -Raw
        # ReadAllText round-trips newlines; comparing on body content trimmed of trailing whitespace
        $written.TrimEnd() -eq $reportBody.TrimEnd()
    }
    Assert "AC-7.5 mock round-trip: last non-blank line is a valid Verdict" {
        $lines = (Get-Content $reportPath) | Where-Object { $_.Trim() -ne "" }
        $last = $lines[-1]
        $last -match '^Verdict: (HEALTHY|WATCH|INTERVENE)$'
    }
} finally {
    Remove-Item Env:HARNESS_SUPERVISOR_MOCK -ErrorAction SilentlyContinue
    if (-not $KeepTemp) {
        Remove-Item -Recurse -Force $mockTmp -ErrorAction SilentlyContinue
    } else {
        Write-Host ""
        Write-Host "Mock temp kept: $mockTmp" -ForegroundColor Yellow
    }
}

# AC-7 fallback path: unreadable mock => fall back to live detection (per supervisor.md
# §"Boundary conditions"). Simulated: env var set to non-existent path, then we check
# the path is not readable and assert the fallback decision is taken.
$fallbackTmp = Join-Path ([System.IO.Path]::GetTempPath()) "harness-supervise-fallback-$(Get-Random)"
New-Item -ItemType Directory -Path $fallbackTmp -Force | Out-Null
try {
    $env:HARNESS_SUPERVISOR_MOCK = (Join-Path $fallbackTmp "does-not-exist.json")
    Assert "AC-7.6 unreadable HARNESS_SUPERVISOR_MOCK is detected (skill must fall back to live detection)" {
        -not (Test-Path $env:HARNESS_SUPERVISOR_MOCK)
    }
} finally {
    Remove-Item Env:HARNESS_SUPERVISOR_MOCK -ErrorAction SilentlyContinue
    if (-not $KeepTemp) {
        Remove-Item -Recurse -Force $fallbackTmp -ErrorAction SilentlyContinue
    }
}

# --- Verify_all I.7 contract (in-process emulation; the real check runs in verify_all)
Write-Host ""
Write-Host "--- I.7 contract: ignored INTERVENE reports ---" -ForegroundColor Cyan

# Last 5 lines / verdict regex.
# Mirrors verify_all.ps1:439 — MUST use `-cmatch` (case-sensitive) so a lowercase
# `verdict: intervene` does NOT pass the schema check (Q-1 fixed-case decision).
# See insight-index L20 (PowerShell case-sensitivity discipline).
function Get-VerdictFromReport($path) {
    if (-not (Test-Path $path)) { return $null }
    $tail = (Get-Content $path | Where-Object { $_.Trim() -ne "" }) | Select-Object -Last 5
    foreach ($line in $tail) {
        if ($line -cmatch '^Verdict: (HEALTHY|WATCH|INTERVENE)$') { return $Matches[1] }
    }
    return $null
}

$i7Tmp = Join-Path ([System.IO.Path]::GetTempPath()) "harness-supervise-i7-$(Get-Random)"
New-Item -ItemType Directory -Path $i7Tmp -Force | Out-Null
try {
    $r1 = Join-Path $i7Tmp "report-healthy.md"
    $r2 = Join-Path $i7Tmp "report-intervene.md"
    [System.IO.File]::WriteAllText($r1, "# Title`n`nSome body.`n`nVerdict: HEALTHY`n")
    [System.IO.File]::WriteAllText($r2, "# Title`n`nSome body.`n`nVerdict: INTERVENE`n")
    # Negative-case fixtures for Q-1 fixed-case enforcement (BUG-1 regression guard).
    # The Q-1 / Architect §15 issue 1 decision: schema enforces UPPERCASE only — a
    # lowercase or mixed-case `verdict:` line MUST NOT parse as a valid verdict.
    # Mirrors insight-index L20 (PS `-match` is case-insensitive; use `-cmatch`).
    $r3 = Join-Path $i7Tmp "report-lowercase.md"
    $r4 = Join-Path $i7Tmp "report-mixedcase.md"
    [System.IO.File]::WriteAllText($r3, "# Title`n`nSome body.`n`nverdict: intervene`n")
    [System.IO.File]::WriteAllText($r4, "# Title`n`nSome body.`n`nVerdict: Intervene`n")
    Assert "I.7-emu HEALTHY report parses verdict = HEALTHY" {
        (Get-VerdictFromReport $r1) -eq "HEALTHY"
    }
    Assert "I.7-emu INTERVENE report (correct UPPERCASE) parses verdict = INTERVENE (positive Q-1 case)" {
        (Get-VerdictFromReport $r2) -eq "INTERVENE"
    }
    Assert "I.7-emu non-existent report parses verdict = null" {
        $null -eq (Get-VerdictFromReport (Join-Path $i7Tmp "absent.md"))
    }
    Assert "I.7-emu BUG-1 guard: lowercase 'verdict: intervene' does NOT parse (Q-1 fixed-case)" {
        $null -eq (Get-VerdictFromReport $r3)
    }
    Assert "I.7-emu BUG-1 guard: mixed-case 'Verdict: Intervene' does NOT parse (Q-1 fixed-case)" {
        $null -eq (Get-VerdictFromReport $r4)
    }
} finally {
    if (-not $KeepTemp) {
        Remove-Item -Recurse -Force $i7Tmp -ErrorAction SilentlyContinue
    }
}

# --- BUG-2 (v0.17.1): I.7 active-row slug match must be column-anchored
Write-Host ""
Write-Host "--- BUG-2: I.7 active-row slug match is column-anchored (no substring collision) ---" -ForegroundColor Cyan
# Emulates the verify_all.ps1 I.7 active-row regex. The slug must match a full
# pipe-delimited cell in docs/tasks.md, NOT a bare substring — otherwise a slug
# `foo` is falsely flagged active by an Active row for `foo-extra` (ADV-8).
function Get-ActiveRowMatch($tasksMd, $slug) {
    $tasksMd -split "`r?`n" | Where-Object { $_ -match "\|\s*$([regex]::Escape($slug))\s*\|" }
}
$bug2Tasks = @(
    "| ID | Slug | Stage | Mode |",
    "|---|---|---|---|",
    "| T-1 | foo-extra | development | full |",
    "| T-2 | foo | done | full |"
) -join "`n"
Assert "BUG-2 guard: slug 'foo' does NOT match the 'foo-extra' row (substring collision blocked)" {
    ((Get-ActiveRowMatch $bug2Tasks "foo") -join "`n") -notmatch 'foo-extra'
}
Assert "BUG-2 guard: slug 'foo' matches exactly its own column-anchored row" {
    ((Get-ActiveRowMatch $bug2Tasks "foo") | Measure-Object).Count -eq 1
}
Assert "BUG-2 guard: slug 'foo' does NOT match a substring inside a path cell" {
    $pathRow = "| T-3 | bar | done | full | docs/features/_archived/foo/ |"
    ((Get-ActiveRowMatch $pathRow "foo") | Measure-Object).Count -eq 0
}

# --- AP-3 round-to-round NON-trigger (F-4 binding)
Write-Host ""
Write-Host "--- F-4: AP-3 round-to-round must NOT count as missing intervention check ---" -ForegroundColor Cyan
Assert "F-4.1 T-002 has rollback rounds within Stage 5 but AP-3 missing count = 0" {
    # Re-affirms AC-6.6 from a different angle: even though Stage 5 has round 1/round 2
    # entries, no intervention check is REQUIRED between rounds.
    (Get-MissingInterventionCount $t002Pm) -eq 0
}

# --- Doc fan-out spot checks (F-3 fan-out closure on AI-GUIDE.md line 14)
Write-Host ""
Write-Host "--- Doc fan-out spot checks ---" -ForegroundColor Cyan
Assert "fan-out: AI-GUIDE.md has '7 canonical agents + 1 auxiliary (supervisor)' phrasing" {
    (Get-Content "AI-GUIDE.md" -Raw) -match 'auxiliary.*supervisor'
}
# NOTE (T-008): the 8 version/count fan-out asserts that hard-coded a release
# version + check count (v0.17.1 / 30 on AI-GUIDE×2, CHANGELOG entry, both README
# badges, plugin.json, marketplace.json, dev-map) were REMOVED here. Their coverage
# moved to where it belongs: the four-stamp version consistency is verify_all G.3,
# and the doc count-claim + current-version CHANGELOG-entry consistency is the new
# standing verify_all G.4 meta-check (derives version from plugin.json + count from
# the live recorded-step tally). test-supervisor keeps ZERO release-tracking literals
# so it never drifts on a version/count bump again. Only the 3 version-agnostic
# structural asserts (auxiliary-supervisor phrasing above, harness-status row +
# canonical-7 glob below) remain.
Assert "fan-out: harness-status SKILL.md has a supervisor (auxiliary) row" {
    (Get-Content "skills/harness-status/SKILL.md" -Raw) -match 'upervisor.*auxiliary'
}
Assert "fan-out: harness-status SKILL.md preserves the canonical-7 glob (not widened)" {
    $c = Get-Content "skills/harness-status/SKILL.md" -Raw
    $c -match '\{pm,req,sol,gate,dev,review,qa\}\*'
}

Write-Host ""
Write-Host "=== Result ===" -ForegroundColor Cyan
Write-Host "  PASS: $pass" -ForegroundColor Green
Write-Host "  FAIL: $fail" -ForegroundColor Red

if ($fail -gt 0) {
    Write-Host ""
    Write-Host "Failures:" -ForegroundColor Red
    $failures | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}
exit 0

} finally {
    Pop-Location
}
