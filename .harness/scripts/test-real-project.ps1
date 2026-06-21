# test-real-project.ps1 — Integration test: apply harness-init templates
# onto a fixture project that already has code, then run harness-sync.
#
# Differs from test-init.ps1: test-init operates on an empty dir; this script
# operates on a fixture under tests/fixtures/, validating that overlay onto
# existing files works (no clobbering, .gitignore preserved, package manifest
# intact, etc.).
#
# Usage:
#   .\.harness\scripts\test-real-project.ps1                # both fixtures
#   .\.harness\scripts\test-real-project.ps1 -Type fullstack
#   .\.harness\scripts\test-real-project.ps1 -KeepTemp

[CmdletBinding()]
param(
    [ValidateSet("both", "fullstack", "backend")]
    [string]$Type = "both",
    [switch]$KeepTemp
)

$ErrorActionPreference = "Stop"
# Script lives at .harness/scripts/ — repo root is two levels up.
$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$templateRoot = Join-Path $repoRoot "skills/harness-init/templates"
$fixturesRoot = Join-Path $repoRoot "tests/fixtures"
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

function Copy-Tree {
    param([string]$Source, [string]$Target)
    if (-not (Test-Path $Source)) { throw "source missing: $Source" }
    Get-ChildItem -Path $Source -Recurse -File | ForEach-Object {
        $rel = $_.FullName.Substring($Source.Length).TrimStart('\','/')
        $dst = Join-Path $Target $rel
        $dstDir = Split-Path $dst -Parent
        if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
        Copy-Item -Path $_.FullName -Destination $dst -Force
    }
}

function Copy-TemplateLayer {
    param([string]$Source, [string]$Target, [hashtable]$Vars)
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
        if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
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

function Test-Fixture {
    param([string]$ProjectType, [string]$FixtureName, [string]$Stack)

    Write-Host ""
    Write-Host "=== Integration: $FixtureName ($ProjectType / $Stack) ===" -ForegroundColor Cyan

    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) "harness-int-$(Get-Random)"
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null

    try {
        # 1) copy fixture (existing project shape)
        Copy-Tree -Source (Join-Path $fixturesRoot $FixtureName) -Target $tmp

        # Snapshot key existing files for later integrity check
        $preFiles = @{}
        Get-ChildItem -Path $tmp -Recurse -File | ForEach-Object {
            $preFiles[$_.FullName.Substring($tmp.Length).TrimStart('\','/')] = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
        }

        # 2) overlay harness templates
        $isWin = ($IsWindows -or $env:OS -eq "Windows_NT")
        $vars = @{
            "PROJECT_NAME" = $FixtureName
            "PROJECT_TYPE" = $ProjectType
            "STACK"        = $Stack
            "TODAY"        = $today
            "ENABLE_HOOK"  = "false"
            # T-12: live FIXTURE-AUTHORING site — the *_COMMAND values are the RESILIENT form
            # (convenience hooks fail-OPEN + $CLAUDE_PROJECT_DIR-anchored; guard-rm fail-CLOSED,
            # NO `|| exit 0`). JSON-escaped bytes copied byte-identical from test-init.ps1 (AC-7).
            # Copy-TemplateLayer uses .Replace() (ordinal-literal), so the `&`/`$env:` are safe.
            "SYNC_COMMAND" = if ($isWin) { 'pwsh -NoProfile -Command \"Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR -EA SilentlyContinue; if (Test-Path -LiteralPath .harness/scripts/harness-sync.ps1 -PathType Leaf) { & pwsh -NoProfile -File .harness/scripts/harness-sync.ps1 }; exit 0\"' } else { 'sh -c ''cd \"$CLAUDE_PROJECT_DIR\" 2>/dev/null && [ -f .harness/scripts/harness-sync.sh ] && exec bash .harness/scripts/harness-sync.sh || exit 0''' }
            "GUARD_COMMAND" = if ($isWin) { 'pwsh -NoProfile -Command \"Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR; & pwsh -NoProfile -File .harness/scripts/guard-rm.ps1\"' } else { 'sh -c ''cd \"$CLAUDE_PROJECT_DIR\" 2>/dev/null && bash .harness/scripts/guard-rm.sh''' }
            "AMBIENT_PROMPT_COMMAND" = if ($isWin) { 'pwsh -NoProfile -Command \"Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR -EA SilentlyContinue; if (Test-Path -LiteralPath .harness/scripts/ambient-prompt.ps1 -PathType Leaf) { & pwsh -NoProfile -File .harness/scripts/ambient-prompt.ps1 }; exit 0\"' } else { 'sh -c ''cd \"$CLAUDE_PROJECT_DIR\" 2>/dev/null && [ -f .harness/scripts/ambient-prompt.sh ] && exec bash .harness/scripts/ambient-prompt.sh || exit 0''' }
            "AMBIENT_RESET_COMMAND"  = if ($isWin) { 'pwsh -NoProfile -Command \"Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR -EA SilentlyContinue; if (Test-Path -LiteralPath .harness/scripts/ambient-reset.ps1 -PathType Leaf) { & pwsh -NoProfile -File .harness/scripts/ambient-reset.ps1 }; exit 0\"' } else { 'sh -c ''cd \"$CLAUDE_PROJECT_DIR\" 2>/dev/null && [ -f .harness/scripts/ambient-reset.sh ] && exec bash .harness/scripts/ambient-reset.sh || exit 0''' }
        }
        Copy-TemplateLayer -Source (Join-Path $templateRoot "common") -Target $tmp -Vars $vars
        Copy-TemplateLayer -Source (Join-Path $templateRoot $ProjectType) -Target $tmp -Vars $vars

        # 3) run distributed harness-sync
        $syncScript = Join-Path $tmp ".harness/scripts/harness-sync.ps1"
        Assert "harness-sync.ps1 was distributed" { Test-Path $syncScript }
        & pwsh -File $syncScript | Out-Null
        Assert "harness-sync exited cleanly" { $LASTEXITCODE -eq 0 }

        # 4) Existing fixture files preserved
        foreach ($rel in $preFiles.Keys) {
            $abs = Join-Path $tmp $rel
            Assert "existing file preserved: $rel" {
                if (-not (Test-Path $abs)) { throw "deleted!" }
                $now = (Get-FileHash $abs -Algorithm SHA256).Hash
                if ($now -ne $preFiles[$rel]) { throw "modified! was $($preFiles[$rel]), now $now" }
                $true
            }
        }

        # 5) Harness SOT + generated artifacts present
        # v0.30 cutover: the 7 generic framework agents are PLUGIN-provided (harness-kit:<name>),
        # NOT copied into the project — assert they are ABSENT in both the SOT and generated trees.
        # Partition dev-* still ship locally and sync. (Mirrors the test-init flip; the operator
        # reconciles baseline.json counts from a captured run.)
        $agents = @("pm-orchestrator","requirement-analyst","solution-architect",
                    "gate-reviewer","developer","code-reviewer","qa-tester")
        foreach ($a in $agents) {
            Assert ".harness/agents/$a.md ABSENT (plugin-provided)" { -not (Test-Path (Join-Path $tmp ".harness/agents/$a.md")) }
            Assert ".claude/agents/$a.md ABSENT (plugin-provided)" { -not (Test-Path (Join-Path $tmp ".claude/agents/$a.md")) }
        }
        $partitionAgents = if ($ProjectType -eq "fullstack") {
            @("dev-frontend","dev-backend","dev-db")
        } else {
            @("dev-api","dev-services","dev-db")
        }
        foreach ($p in $partitionAgents) {
            Assert ".harness/agents/$p.md (partition)" { Test-Path (Join-Path $tmp ".harness/agents/$p.md") }
            Assert ".claude/agents/$p.md (generated)" { Test-Path (Join-Path $tmp ".claude/agents/$p.md") }
        }
        Assert ".harness/rules/00-core.md" { Test-Path (Join-Path $tmp ".harness/rules/00-core.md") }
        Assert ".harness/rules/50-$ProjectType.md" { Test-Path (Join-Path $tmp ".harness/rules/50-$ProjectType.md") }
        Assert "AI-GUIDE.md (v0.10 tool-agnostic entry)" { Test-Path (Join-Path $tmp "AI-GUIDE.md") }
        Assert "CLAUDE.md (v0.10 bootstrap stub)" { Test-Path (Join-Path $tmp "CLAUDE.md") }
        Assert ".claude/settings.json (direct copy)" { Test-Path (Join-Path $tmp ".claude/settings.json") }
        Assert ".github/copilot-instructions.md (v0.10 bootstrap stub)" { Test-Path (Join-Path $tmp ".github/copilot-instructions.md") }

        # 6) Binding consistency
        Assert "harness-sync --check is clean" {
            & pwsh -File $syncScript -Check | Out-Null
            $LASTEXITCODE -eq 0
        }

        # 7) AI-GUIDE.md indexes the project-type rule overlay
        Assert "AI-GUIDE.md indexes 50-$ProjectType.md" {
            (Get-Content (Join-Path $tmp "AI-GUIDE.md") -Raw) -match "50-$ProjectType\.md"
        }
        Assert "CLAUDE.md stub references AI-GUIDE.md" {
            (Get-Content (Join-Path $tmp "CLAUDE.md") -Raw) -match "AI-GUIDE\.md"
        }

        # 8) Fixture-specific source files intact
        if ($ProjectType -eq "fullstack") {
            Assert "fixture src/server.ts intact" { Test-Path (Join-Path $tmp "src/server.ts") }
            Assert "fixture tests/server.test.ts intact" { Test-Path (Join-Path $tmp "tests/server.test.ts") }
            Assert "fixture package.json intact" { Test-Path (Join-Path $tmp "package.json") }
        } else {
            Assert "fixture src/main.py intact" { Test-Path (Join-Path $tmp "src/main.py") }
            Assert "fixture tests/test_main.py intact" { Test-Path (Join-Path $tmp "tests/test_main.py") }
            Assert "fixture pyproject.toml intact" { Test-Path (Join-Path $tmp "pyproject.toml") }
        }

        # 9) .gitignore preserved
        Assert ".gitignore preserved" {
            $gi = Get-Content (Join-Path $tmp ".gitignore") -Raw -ErrorAction Stop
            if ($ProjectType -eq "fullstack") {
                $gi -match "node_modules"
            } else {
                $gi -match "__pycache__"
            }
        }

        # === T-020: run the generated type verify_all on the fixture (AC-3 / AC-4) ===
        # First flip the tree to a healthy v0.30 SINGLE-DEV state: remove partition
        # agents from BOTH sides (absence of .harness/agents/ is healthy; binding
        # stays clean because both sides are removed). Then assert the agents-layout
        # and hook-congruence rows. Runs LAST in this fixture (tree mutated, then
        # discarded).
        Remove-Item (Join-Path $tmp ".harness/agents") -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item (Join-Path $tmp ".claude/agents") -Recurse -Force -ErrorAction SilentlyContinue
        $t20AgentsRow = if ($ProjectType -eq "backend") { "D.3" } else { "E.3" }
        $t20CongRow   = if ($ProjectType -eq "backend") { "D.4b" } else { "E.4b" }
        Push-Location $tmp
        try {
            $t20Out = (& pwsh -NoProfile -File (Join-Path $tmp ".harness/scripts/verify_all.ps1") -Quick 2>&1) -join "`n"
        } finally { Pop-Location }
        $t20ALine = ($t20Out.Split("`n") | Where-Object { $_.Contains("[$t20AgentsRow]") } | Select-Object -First 1)
        $t20CLine = ($t20Out.Split("`n") | Where-Object { $_.Contains("[$t20CongRow]") } | Select-Object -First 1)
        Assert "[T-020] healthy v0.30 single-dev fixture: $t20AgentsRow agents-layout PASS (AC-3)" {
            "$t20ALine".Contains("PASS")
        }
        Assert "[T-020] healthy v0.30 single-dev fixture: $t20CongRow hook-congruence PASS (AC-4 healthy half)" {
            "$t20CLine".Contains("PASS")
        }
        # Mutation: delete the sync scripts -> the congruence row must FAIL, naming
        # the missing path and the fix command (AC-4).
        Remove-Item (Join-Path $tmp ".harness/scripts/harness-sync.sh") -Force -ErrorAction SilentlyContinue
        Remove-Item (Join-Path $tmp ".harness/scripts/harness-sync.ps1") -Force -ErrorAction SilentlyContinue
        Push-Location $tmp
        try {
            $t20Out2 = (& pwsh -NoProfile -File (Join-Path $tmp ".harness/scripts/verify_all.ps1") -Quick 2>&1) -join "`n"
        } finally { Pop-Location }
        $t20CLine2 = ($t20Out2.Split("`n") | Where-Object { $_.Contains("[$t20CongRow]") } | Select-Object -First 1)
        Assert "[T-020] dangling fixture: $t20CongRow FAILs (AC-4)" {
            "$t20CLine2".Contains("FAIL")
        }
        Assert "[T-020] dangling fixture: FAIL names the missing path + fix command (AC-4)" {
            $t20Out2.Contains('missing script: .harness/scripts/harness-sync.') -and $t20Out2.Contains('fix: run /harness-upgrade')
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

Write-Host "=== test-real-project: overlay Harness onto fixture projects ===" -ForegroundColor Cyan

if ($Type -in @("both", "fullstack")) {
    Test-Fixture -ProjectType "fullstack" -FixtureName "todo-fullstack" -Stack "Node + TypeScript + node:test"
}
if ($Type -in @("both", "backend")) {
    Test-Fixture -ProjectType "backend" -FixtureName "todo-backend" -Stack "Python + pytest"
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
