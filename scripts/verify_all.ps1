# verify_all.ps1 — Verification for the harness-engineering repo itself (tooling/skills project)
#
# Differs from project-template verify_all: checks Markdown / Shell / template integrity / self-consistency
# rather than build & test of a runtime stack.

[CmdletBinding()]
param([switch]$Quick)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path $PSScriptRoot -Parent
Push-Location $repoRoot
try {

$report = @()
$errors = 0
$warns = 0

function Step($id, $name, [scriptblock]$action) {
    Write-Host "[$id] $name ..." -NoNewline
    try {
        $r = & $action
        if ($r -eq $false) {
            Write-Host " WARN" -ForegroundColor Yellow
            $script:warns++
            $script:report += [pscustomobject]@{ id=$id; name=$name; status="WARN" }
        } else {
            Write-Host " PASS" -ForegroundColor Green
            $script:report += [pscustomobject]@{ id=$id; name=$name; status="PASS" }
        }
    } catch {
        Write-Host " FAIL" -ForegroundColor Red
        Write-Host "       $_" -ForegroundColor DarkRed
        $script:errors++
        $script:report += [pscustomobject]@{ id=$id; name=$name; status="FAIL"; error="$_" }
    }
}

Write-Host "=== verify_all (harness-engineering repo) ===" -ForegroundColor Cyan
Write-Host ""

# A. Hygiene
Step "A.1" "No accidentally-committed env or secrets" {
    $envFiles = git ls-files '*.env' '.env*' 2>$null | Where-Object { $_ -notmatch 'example|sample|tmpl' }
    if ($envFiles) { throw ".env committed:`n$envFiles" }
    $secrets = git grep -E "(?i)(api[_-]?key|secret|password|token)\s*[:=]\s*['""][^'""]{12,}['""]" -- ':!*.md' ':!scripts/verify_all*' ':!skills/*' 2>$null
    if ($secrets) { throw "Possible secret:`n$secrets" }
}

Step "A.2" "参考/ not tracked" {
    $tracked = git ls-files -- '参考/' 2>$null
    if ($tracked) { throw "参考/ should be gitignored but is tracked:`n$tracked" }
}

# B. Required top-level files
Step "B.1" "README / LICENSE / CHANGELOG present" {
    foreach ($f in @("README.md", "LICENSE", "CHANGELOG.md")) {
        if (-not (Test-Path $f)) { throw "Missing $f" }
    }
}

Step "B.2" "Install scripts present (both PowerShell + Bash)" {
    if (-not (Test-Path "install.ps1")) { throw "install.ps1 missing" }
    if (-not (Test-Path "install.sh")) { throw "install.sh missing" }
}

# C. Skills structure
Step "C.1" "All 8 skills present with SKILL.md" {
    foreach ($s in @("harness", "harness-init", "harness-adopt", "harness-verify", "harness-status", "harness-plan", "harness-explore", "harness-goal")) {
        $p = "skills/$s/SKILL.md"
        if (-not (Test-Path $p)) { throw "Missing $p" }
    }
}

Step "C.2" "Skill frontmatter sanity" {
    $bad = @()
    Get-ChildItem skills -Recurse -Filter "SKILL.md" | ForEach-Object {
        $head = Get-Content $_.FullName -TotalCount 10
        if (-not ($head -match '^---')) { $bad += "$($_.FullName) — missing frontmatter" }
        if (-not ($head -match '^name:')) { $bad += "$($_.FullName) — missing name:" }
        if (-not ($head -match '^description:')) { $bad += "$($_.FullName) — missing description:" }
    }
    if ($bad.Count -gt 0) { throw "Skill frontmatter issues:`n$($bad -join "`n")" }
}

# D. Templates
Step "D.1" "All template agents present in templates/common/.harness/agents" {
    $tplAgents = "skills/harness-init/templates/common/.harness/agents"
    foreach ($a in @("pm-orchestrator","requirement-analyst","solution-architect","gate-reviewer","developer","code-reviewer","qa-tester")) {
        if (-not (Test-Path "$tplAgents/$a.md")) { throw "Missing template agent: $a" }
    }
}

Step "D.2" "Placeholders limited to documented set" {
    $allowed = @("{{PROJECT_NAME}}", "{{PROJECT_TYPE}}", "{{STACK}}", "{{TODAY}}", "{{ENABLE_HOOK}}", "{{SYNC_COMMAND}}")
    $tmplFiles = Get-ChildItem skills/harness-init/templates -Recurse -File | Where-Object {
        $_.Name -match '\.(tmpl|append)$'
    }
    $bad = @()
    foreach ($f in $tmplFiles) {
        $content = Get-Content $f.FullName -Raw
        $found = [regex]::Matches($content, '\{\{[A-Z_]+\}\}') | ForEach-Object { $_.Value } | Sort-Object -Unique
        foreach ($p in $found) {
            if ($p -notin $allowed) { $bad += "$($f.Name): unknown placeholder $p" }
        }
    }
    if ($bad.Count -gt 0) { throw "Unknown placeholders:`n$($bad -join "`n")" }
}

# E. Self-consistency (dogfood — two layers)
# Layer 1: templates/common/ → repo .harness/ + scripts/harness-sync
Step "E.1" "Layer 1: .harness/ matches templates/common/.harness/" {
    & (Join-Path $PSScriptRoot "sync-self.ps1") -Check
    if ($LASTEXITCODE -ne 0) { throw "Layer 1 drift — run scripts/sync-self.ps1 to fix" }
}

# Layer 2: .harness/ → .claude/ (binding, agents + skills only in v0.10)
Step "E.2" "Layer 2: .claude/agents and .claude/skills synced from .harness/" {
    & (Join-Path $PSScriptRoot "harness-sync.ps1") -Check
    if ($LASTEXITCODE -ne 0) { throw "Layer 2 drift — run scripts/harness-sync.ps1 to fix" }
}

Step "E.3" "Project rule sources present (.harness/rules + 7 agents)" {
    foreach ($f in @(".harness/agents/pm-orchestrator.md", ".harness/agents/developer.md")) {
        if (-not (Test-Path $f)) { throw "Missing $f" }
    }
    $rules = Get-ChildItem -Path ".harness/rules" -Filter "*.md" -File -ErrorAction SilentlyContinue
    if ($rules.Count -lt 1) { throw "No .harness/rules/*.md files found" }
}

Step "E.4" "Bootstrap files present and point to AI-GUIDE.md" {
    foreach ($f in @("AI-GUIDE.md", "CLAUDE.md", ".github/copilot-instructions.md")) {
        if (-not (Test-Path $f)) { throw "Missing $f" }
    }
    foreach ($stub in @("CLAUDE.md", ".github/copilot-instructions.md")) {
        $c = Get-Content $stub -Raw
        if ($c -notmatch 'AI-GUIDE\.md') { throw "$stub does not reference AI-GUIDE.md — stub broken" }
    }
    if (-not (Test-Path ".claude/agents")) { throw "Missing .claude/agents/ (run harness-sync)" }
}

Step "E.5" "Docs present" {
    foreach ($f in @("docs/workflow.md", "docs/dev-map.md", "docs/tasks.md", "docs/getting-started.md", "docs/concepts.md")) {
        if (-not (Test-Path $f)) { throw "Missing $f" }
    }
}

Step "E.6" "evals/golden-tasks.md present" {
    if (-not (Test-Path "evals/golden-tasks.md")) { throw "Missing evals/golden-tasks.md" }
}

# F. Symmetry (PowerShell <-> Bash pairs)
Step "F.1" "verify_all, sync-self, harness-sync, test-init, test-real-project exist in both .ps1 and .sh" {
    foreach ($pair in @("verify_all", "sync-self", "harness-sync", "test-init", "test-real-project")) {
        if (-not (Test-Path "scripts/$pair.ps1")) { throw "Missing scripts/$pair.ps1" }
        if (-not (Test-Path "scripts/$pair.sh")) { throw "Missing scripts/$pair.sh" }
    }
}

Step "F.2" "Install scripts symmetric" {
    if (-not (Test-Path "install.ps1")) { throw "install.ps1 missing" }
    if (-not (Test-Path "install.sh")) { throw "install.sh missing" }
}

# G. Documentation hygiene
Step "G.1" "README references all 8 skills" {
    $readme = Get-Content "README.md" -Raw
    foreach ($s in @("harness", "harness-init", "harness-adopt", "harness-verify", "harness-status", "harness-plan", "harness-explore", "harness-goal")) {
        if ($readme -notmatch [regex]::Escape($s)) { throw "README missing skill mention: $s" }
    }
}

Step "H.1" "Test fixtures present (todo-fullstack + todo-backend)" {
    foreach ($f in @("tests/fixtures/todo-fullstack/package.json",
                     "tests/fixtures/todo-fullstack/src/server.ts",
                     "tests/fixtures/todo-backend/pyproject.toml",
                     "tests/fixtures/todo-backend/src/main.py")) {
        if (-not (Test-Path $f)) { throw "Missing fixture file: $f" }
    }
}

Step "G.2" "CHANGELOG mentions all 8 skills" {
    $cl = Get-Content "CHANGELOG.md" -Raw
    foreach ($s in @("harness", "harness-init", "harness-adopt", "harness-verify", "harness-status", "harness-plan", "harness-explore", "harness-goal")) {
        if ($cl -notmatch [regex]::Escape($s)) { throw "CHANGELOG missing skill mention: $s" }
    }
}

# Summary
Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
$pass = ($report | Where-Object status -eq "PASS").Count
Write-Host "  PASS: $pass" -ForegroundColor Green
Write-Host "  WARN: $warns" -ForegroundColor Yellow
Write-Host "  FAIL: $errors" -ForegroundColor Red

# Append history
$historyEntry = [pscustomobject]@{
    timestamp = (Get-Date).ToString("o")
    pass = $pass; warn = $warns; fail = $errors
    report = $report
}
$historyEntry | ConvertTo-Json -Depth 5 -Compress | Add-Content -Path "scripts/verification_history.log"

if ($errors -gt 0) { exit 2 }
if ($warns -gt 0) { exit 1 }
exit 0

} finally {
    Pop-Location
}
