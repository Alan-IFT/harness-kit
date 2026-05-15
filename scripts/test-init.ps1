# test-init.ps1 — Automated regression for /harness-init's template copy logic
#
# Simulates what /harness-init does (template discovery, file copy, placeholder
# substitution, .tmpl/.append handling) in a temp directory, then asserts the
# result has the expected shape. Cleans up automatically.
#
# Implements Golden Tasks #1 (fullstack) and #2 (backend) from evals/golden-tasks.md.
#
# Usage:
#   .\scripts\test-init.ps1               # both project types
#   .\scripts\test-init.ps1 -Type fullstack
#   .\scripts\test-init.ps1 -KeepTemp     # don't delete the temp dir at the end

[CmdletBinding()]
param(
    [ValidateSet("both", "fullstack", "backend")]
    [string]$Type = "both",
    [switch]$KeepTemp
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path $PSScriptRoot -Parent
$templateRoot = Join-Path $repoRoot "skills/harness-init/templates"
$today = (Get-Date).ToString("yyyy-MM-dd")

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

function Copy-Template {
    param(
        [string]$Source,
        [string]$Target,
        [hashtable]$Vars
    )
    if (-not (Test-Path $Source)) { throw "source missing: $Source" }

    Get-ChildItem -Path $Source -Recurse -File | ForEach-Object {
        $rel = $_.FullName.Substring($Source.Length).TrimStart('\','/')
        $destRel = $rel

        # .tmpl files become real files with placeholder substitution
        if ($destRel.EndsWith(".tmpl")) {
            $destRel = $destRel.Substring(0, $destRel.Length - 5)
            $needsSubst = $true
        } elseif ($destRel.EndsWith(".append")) {
            # Append to base CLAUDE.md
            $baseFile = Join-Path $Target "CLAUDE.md"
            if (Test-Path $baseFile) {
                Add-Content -Path $baseFile -Value (Get-Content $_.FullName -Raw)
            }
            return
        } else {
            $needsSubst = $false
        }

        $destPath = Join-Path $Target $destRel
        $destDir = Split-Path $destPath -Parent
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }

        if ($needsSubst) {
            $content = Get-Content $_.FullName -Raw
            foreach ($k in $Vars.Keys) {
                $content = $content -replace [regex]::Escape("{{$k}}"), $Vars[$k]
            }
            # Substitute the substitution result back into the file
            [System.IO.File]::WriteAllText($destPath, $content)
        } else {
            Copy-Item -Path $_.FullName -Destination $destPath -Force
        }
    }
}

function Test-Type {
    param([string]$ProjectType, [string]$Stack)

    Write-Host ""
    Write-Host "=== Testing: $ProjectType ($Stack) ===" -ForegroundColor Cyan

    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) "harness-test-$(Get-Random)"
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null

    try {
        $vars = @{
            "PROJECT_NAME" = "test-project"
            "PROJECT_TYPE" = $ProjectType
            "STACK"        = $Stack
            "TODAY"        = $today
            "ENABLE_HOOK"  = "false"
        }

        Copy-Template -Source (Join-Path $templateRoot "common") -Target $tmp -Vars $vars
        Copy-Template -Source (Join-Path $templateRoot $ProjectType) -Target $tmp -Vars $vars

        # === Assertions ===

        # All 7 agents present
        $agents = @("pm-orchestrator","requirement-analyst","solution-architect",
                    "gate-reviewer","developer","code-reviewer","qa-tester")
        foreach ($a in $agents) {
            Assert "agent: $a.md" { Test-Path (Join-Path $tmp ".claude/agents/$a.md") }
        }

        # 3 stack skills
        foreach ($s in @("build","test","verify")) {
            Assert "skill: $s/SKILL.md" { Test-Path (Join-Path $tmp ".claude/skills/$s/SKILL.md") }
            Assert "skill: $s/SKILL.md.tmpl removed" { -not (Test-Path (Join-Path $tmp ".claude/skills/$s/SKILL.md.tmpl")) }
        }

        # Settings + rules
        Assert "settings.json (no .tmpl suffix)" { Test-Path (Join-Path $tmp ".claude/settings.json") }
        Assert "CLAUDE.md present" { Test-Path (Join-Path $tmp "CLAUDE.md") }
        Assert "CLAUDE.md.tmpl removed" { -not (Test-Path (Join-Path $tmp "CLAUDE.md.tmpl")) }

        # Append worked (project-type overlay)
        Assert "CLAUDE.md contains overlay marker" {
            $content = Get-Content (Join-Path $tmp "CLAUDE.md") -Raw
            $content -match "$ProjectType-specific rules"
        }

        # Docs
        Assert "docs/workflow.md" { Test-Path (Join-Path $tmp "docs/workflow.md") }
        Assert "docs/dev-map.md" { Test-Path (Join-Path $tmp "docs/dev-map.md") }
        Assert "docs/tasks.md" { Test-Path (Join-Path $tmp "docs/tasks.md") }
        Assert "docs/spec/README.md" { Test-Path (Join-Path $tmp "docs/spec/README.md") }

        # Evals
        Assert "evals/golden-tasks.md" { Test-Path (Join-Path $tmp "evals/golden-tasks.md") }

        # Scripts (both PowerShell + Bash)
        Assert "scripts/verify_all.ps1" { Test-Path (Join-Path $tmp "scripts/verify_all.ps1") }
        Assert "scripts/verify_all.sh"  { Test-Path (Join-Path $tmp "scripts/verify_all.sh") }
        Assert "scripts/verify_all.ps1.tmpl removed" { -not (Test-Path (Join-Path $tmp "scripts/verify_all.ps1.tmpl")) }
        Assert "scripts/verify_all.sh.tmpl removed"  { -not (Test-Path (Join-Path $tmp "scripts/verify_all.sh.tmpl")) }

        # Placeholder substitution worked
        Assert "PROJECT_NAME substituted in CLAUDE.md" {
            (Get-Content (Join-Path $tmp "CLAUDE.md") -Raw) -match "test-project"
        }
        Assert "TODAY substituted in CLAUDE.md" {
            (Get-Content (Join-Path $tmp "CLAUDE.md") -Raw) -match $today
        }
        Assert "STACK substituted in CLAUDE.md" {
            (Get-Content (Join-Path $tmp "CLAUDE.md") -Raw) -match [regex]::Escape($Stack)
        }
        Assert "no unresolved placeholders anywhere" {
            $bad = @()
            Get-ChildItem -Path $tmp -Recurse -File | Where-Object {
                $_.Extension -in @(".md", ".json", ".sh", ".ps1")
            } | ForEach-Object {
                $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
                if ($content -match '\{\{[A-Z_]+\}\}') { $bad += $_.FullName }
            }
            if ($bad.Count -gt 0) { throw "unresolved placeholders in:`n$($bad -join "`n")" }
            $true
        }

        # No .tmpl or .append leaked through
        Assert "no .tmpl files leaked to output" {
            $leaked = Get-ChildItem -Path $tmp -Recurse -Filter "*.tmpl" -File
            if ($leaked) { throw "leaked: $($leaked.FullName -join ', ')" }
            $true
        }
        Assert "no .append files leaked to output" {
            $leaked = Get-ChildItem -Path $tmp -Recurse -Filter "*.append" -File
            if ($leaked) { throw "leaked: $($leaked.FullName -join ', ')" }
            $true
        }

    } finally {
        if (-not $KeepTemp) {
            Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
        } else {
            Write-Host ""
            Write-Host "Temp dir kept: $tmp" -ForegroundColor Yellow
        }
    }
}

Write-Host "=== test-init: simulating /harness-init template copy ===" -ForegroundColor Cyan
Write-Host "Repo: $repoRoot"

if ($Type -in @("both", "fullstack")) {
    Test-Type -ProjectType "fullstack" -Stack "Next.js + NestJS + Postgres"
}
if ($Type -in @("both", "backend")) {
    Test-Type -ProjectType "backend" -Stack "FastAPI + Postgres"
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
