# test-init.ps1 — Automated regression for /harness-init (v0.2)
#
# Simulates a full init in a temp directory:
#   1. Copy common + project-type templates with placeholder substitution
#      (.tmpl files; no .append handling — v0.2 doesn't use .append).
#   2. Run the project's own harness-sync to generate .claude/ + CLAUDE.md.
#   3. Assert the resulting structure.
#
# Implements Golden Tasks #1 (fullstack) and #2 (backend).
#
# Usage:
#   .\scripts\test-init.ps1              # both project types
#   .\scripts\test-init.ps1 -Type fullstack
#   .\scripts\test-init.ps1 -KeepTemp    # leave temp dir for inspection

[CmdletBinding()]
param(
    [ValidateSet("all", "both", "fullstack", "backend", "generic")]
    [string]$Type = "all",
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

function Copy-TemplateLayer {
    param(
        [string]$Source,
        [string]$Target,
        [hashtable]$Vars
    )
    if (-not (Test-Path $Source)) { throw "source missing: $Source" }

    Get-ChildItem -Path $Source -Recurse -File | ForEach-Object {
        $rel = $_.FullName.Substring($Source.Length).TrimStart('\','/')
        $destRel = $rel
        $needsSubst = $false

        if ($destRel.EndsWith(".tmpl")) {
            $destRel = $destRel.Substring(0, $destRel.Length - 5)
            $needsSubst = $true
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
        $syncCmd = if ($IsWindows -or $env:OS -eq "Windows_NT") {
            "pwsh -File scripts/harness-sync.ps1"
        } else {
            "bash scripts/harness-sync.sh"
        }
        $vars = @{
            "PROJECT_NAME" = "test-project"
            "PROJECT_TYPE" = $ProjectType
            "STACK"        = $Stack
            "TODAY"        = $today
            "ENABLE_HOOK"  = "false"
            "SYNC_COMMAND" = $syncCmd
        }

        # 1) copy templates (common, then overlay)
        Copy-TemplateLayer -Source (Join-Path $templateRoot "common") -Target $tmp -Vars $vars
        Copy-TemplateLayer -Source (Join-Path $templateRoot $ProjectType) -Target $tmp -Vars $vars

        # 2) run the embedded harness-sync to generate .claude/ + CLAUDE.md
        $syncScript = Join-Path $tmp "scripts/harness-sync.ps1"
        Assert "harness-sync.ps1 was distributed" { Test-Path $syncScript }
        if (Test-Path $syncScript) {
            $env:HARNESS_TEST = "1"  # not used currently but reserved
            & pwsh -File $syncScript | Out-Null
            $syncExit = $LASTEXITCODE
            Assert "harness-sync exited cleanly" { $syncExit -eq 0 }
        }

        # === Source-of-truth (.harness/) assertions ===
        $agents = @("pm-orchestrator","requirement-analyst","solution-architect",
                    "gate-reviewer","developer","code-reviewer","qa-tester")
        foreach ($a in $agents) {
            Assert ".harness/agents/$a.md (SOT)" { Test-Path (Join-Path $tmp ".harness/agents/$a.md") }
        }

        # Partition agents: fullstack and backend have them in v0.5+; generic has none by default
        $partitionAgents = switch ($ProjectType) {
            "fullstack" { @("dev-frontend", "dev-backend", "dev-db") }
            "backend"   { @("dev-api", "dev-services", "dev-db") }
            "generic"   { @() }
        }
        foreach ($p in $partitionAgents) {
            Assert ".harness/agents/$p.md (partition SOT)" { Test-Path (Join-Path $tmp ".harness/agents/$p.md") }
            Assert ".harness/agents/$p.md placeholder substituted" {
                $content = Get-Content (Join-Path $tmp ".harness/agents/$p.md") -Raw
                ($content -notmatch '\{\{[A-Z_]+\}\}') -and ($content -match "test-project")
            }
        }

        Assert ".harness/rules/00-core.md (composed base)" { Test-Path (Join-Path $tmp ".harness/rules/00-core.md") }
        Assert ".harness/rules/50-$ProjectType.md (overlay)" { Test-Path (Join-Path $tmp ".harness/rules/50-$ProjectType.md") }

        # .harness/skills/ is fullstack/backend-only; generic ships without them (user fills in)
        if ($ProjectType -ne "generic") {
            foreach ($s in @("build","test","verify")) {
                Assert ".harness/skills/$s/SKILL.md (SOT)" { Test-Path (Join-Path $tmp ".harness/skills/$s/SKILL.md") }
            }
        }

        # === Generated artifacts (.claude/ + CLAUDE.md) ===
        foreach ($a in $agents) {
            Assert ".claude/agents/$a.md (generated)" { Test-Path (Join-Path $tmp ".claude/agents/$a.md") }
        }
        foreach ($p in $partitionAgents) {
            Assert ".claude/agents/$p.md (generated partition)" { Test-Path (Join-Path $tmp ".claude/agents/$p.md") }
        }
        if ($ProjectType -ne "generic") {
            foreach ($s in @("build","test","verify")) {
                Assert ".claude/skills/$s/SKILL.md (generated)" { Test-Path (Join-Path $tmp ".claude/skills/$s/SKILL.md") }
            }
        }
        Assert ".claude/settings.json (direct binding artifact)" { Test-Path (Join-Path $tmp ".claude/settings.json") }
        Assert "AI-GUIDE.md (v0.10 tool-agnostic entry)" { Test-Path (Join-Path $tmp "AI-GUIDE.md") }
        Assert "CLAUDE.md (v0.10 bootstrap stub)" { Test-Path (Join-Path $tmp "CLAUDE.md") }
        Assert ".github/copilot-instructions.md (v0.10 bootstrap stub)" {
            Test-Path (Join-Path $tmp ".github/copilot-instructions.md")
        }
        Assert "copilot-instructions.md has applyTo frontmatter" {
            $head = Get-Content (Join-Path $tmp ".github/copilot-instructions.md") -TotalCount 5
            ($head -join "`n") -match 'applyTo:\s*"\*\*"'
        }

        # === Content correctness ===
        Assert "CLAUDE.md is a stub (references AI-GUIDE.md, no GENERATED marker)" {
            $c = Get-Content (Join-Path $tmp "CLAUDE.md") -Raw
            ($c -match "AI-GUIDE\.md") -and ($c -notmatch "GENERATED FILE") -and ($c.Length -lt 2000)
        }
        Assert "copilot-instructions.md is a stub (references AI-GUIDE.md)" {
            $c = Get-Content (Join-Path $tmp ".github/copilot-instructions.md") -Raw
            ($c -match "AI-GUIDE\.md") -and ($c.Length -lt 2000)
        }
        Assert "AI-GUIDE.md indexes project-type rule overlay" {
            (Get-Content (Join-Path $tmp "AI-GUIDE.md") -Raw) -match "50-$ProjectType\.md"
        }
        Assert "AI-GUIDE.md indexes every .harness/rules/*.md file (matches user-project verify_all E.5)" {
            $guide = Get-Content (Join-Path $tmp "AI-GUIDE.md") -Raw
            $missing = @()
            Get-ChildItem -Path (Join-Path $tmp ".harness/rules") -Filter "*.md" -File | ForEach-Object {
                if ($guide -notmatch [regex]::Escape(".harness/rules/$($_.Name)")) { $missing += $_.Name }
            }
            if ($missing.Count -gt 0) {
                Write-Host ("  Rules NOT indexed: " + ($missing -join ", ")) -ForegroundColor Yellow
                $false
            } else { $true }
        }
        Assert "PROJECT_NAME substituted into rules" {
            (Get-Content (Join-Path $tmp ".harness/rules/00-core.md") -Raw) -match "test-project"
        }
        Assert "TODAY substituted into rules" {
            (Get-Content (Join-Path $tmp ".harness/rules/00-core.md") -Raw) -match $today
        }
        Assert "STACK substituted into rules" {
            (Get-Content (Join-Path $tmp ".harness/rules/00-core.md") -Raw) -match [regex]::Escape($Stack)
        }
        Assert "PROJECT_NAME substituted into AI-GUIDE.md" {
            (Get-Content (Join-Path $tmp "AI-GUIDE.md") -Raw) -match "test-project"
        }
        Assert "PROJECT_NAME substituted into CLAUDE.md stub" {
            (Get-Content (Join-Path $tmp "CLAUDE.md") -Raw) -match "test-project"
        }

        # === Docs / scripts / evals ===
        foreach ($f in @("docs/workflow.md","docs/dev-map.md","docs/tasks.md","docs/spec/README.md",
                         "evals/golden-tasks.md","scripts/verify_all.ps1","scripts/verify_all.sh",
                         "scripts/harness-sync.sh")) {
            Assert "$f present" { Test-Path (Join-Path $tmp $f) }
        }

        # === Cleanliness ===
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
        Assert "no .tmpl files leaked" {
            $leaked = Get-ChildItem -Path $tmp -Recurse -Filter "*.tmpl" -File
            if ($leaked) { throw "leaked: $($leaked.FullName -join ', ')" }
            $true
        }
        Assert "no .append files anywhere (v0.2 removed them)" {
            $leaked = Get-ChildItem -Path $tmp -Recurse -Filter "*.append" -File
            if ($leaked) { throw "found: $($leaked.FullName -join ', ')" }
            $true
        }

        # === Layer 2 binding consistency right after init ===
        Assert "harness-sync --check is clean after init" {
            $check = Join-Path $tmp "scripts/harness-sync.ps1"
            & pwsh -File $check -Check | Out-Null
            $LASTEXITCODE -eq 0
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

Write-Host "=== test-init: simulating /harness-init flow (v0.2) ===" -ForegroundColor Cyan
Write-Host "Repo: $repoRoot"

if ($Type -in @("all", "both", "fullstack")) {
    Test-Type -ProjectType "fullstack" -Stack "Next.js + NestJS + Postgres"
}
if ($Type -in @("all", "both", "backend")) {
    Test-Type -ProjectType "backend" -Stack "FastAPI + Postgres"
}
if ($Type -in @("all", "generic")) {
    Test-Type -ProjectType "generic" -Stack "Rust CLI tool"
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
