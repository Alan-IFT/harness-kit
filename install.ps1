# install.ps1 — Install Harness Kit skills into Claude Code (Windows).
#
# Three install paths exist:
#
#   1. (Recommended) Claude Code plugin marketplace — runs inside Claude Code:
#        /plugin marketplace add Alan-IFT/harness-kit
#        /plugin install harness-kit@harness-kit-marketplace
#      Versioned, auditable, official path. This script doesn't drive that;
#      run the slash commands above in any Claude Code session.
#
#   2. (Fallback) Direct copy to ~/.claude/skills/ — this script.
#      Use when plugin path isn't available or you want plain skills layout.
#
#   3. (Dev mode) Run locally from a cloned repo: .\install.ps1
#
# Iwr one-liner:
#   iwr -useb https://raw.githubusercontent.com/Alan-IFT/harness-kit/main/install.ps1 | iex
#
# Usage (local):
#   .\install.ps1                  # install to ~/.claude/skills (global)
#   .\install.ps1 -Project .       # install to ./.claude/skills
#   .\install.ps1 -DryRun          # preview, no writes
#   .\install.ps1 -Uninstall       # remove

[CmdletBinding()]
param(
    [string]$Project = "",
    [switch]$DryRun,
    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"

# Override via env: $env:HARNESS_KIT_REPO = "https://github.com/fork/harness-kit"
$repoUrl = if ($env:HARNESS_KIT_REPO) { $env:HARNESS_KIT_REPO } else { "https://github.com/Alan-IFT/harness-kit" }
$branch  = if ($env:HARNESS_KIT_BRANCH) { $env:HARNESS_KIT_BRANCH } else { "main" }

# Decide source: either local (script ran from cloned repo) or remote (curl one-liner)
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
if (Test-Path (Join-Path $scriptDir "skills/harness-init")) {
    $sourceMode = "local"
    $skillsSource = Join-Path $scriptDir "skills"
    $tmpDir = $null
} else {
    $sourceMode = "remote"
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Error "git is required to fetch harness-kit. Install git first."
        exit 1
    }
    $tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) "harness-kit-$(Get-Random)"
    New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
    Write-Host "Fetching harness-kit from $repoUrl ($branch)..." -ForegroundColor Cyan
    & git clone --depth 1 --branch $branch $repoUrl (Join-Path $tmpDir "repo") 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "git clone failed. Check network or override HARNESS_KIT_REPO."
        Remove-Item -Recurse -Force $tmpDir -ErrorAction SilentlyContinue
        exit 1
    }
    $skillsSource = Join-Path $tmpDir "repo/skills"
}

try {

if ($Project) {
    $resolvedProject = (Resolve-Path $Project).Path
    $target = Join-Path $resolvedProject ".claude/skills"
    $scope = "project: $resolvedProject"
} else {
    $homeDir = $HOME
    if (-not $homeDir) { $homeDir = $env:USERPROFILE }
    $target = Join-Path $homeDir ".claude/skills"
    $scope = "global: $homeDir"
}

$skills = @("harness", "harness-init", "harness-adopt", "harness-verify", "harness-status", "harness-plan", "harness-explore", "harness-goal", "harness-batch", "harness-stream", "harness-intervene", "harness-supervise", "harness-decision-mode")

Write-Host ""
Write-Host "Harness Kit install" -ForegroundColor Cyan
Write-Host "  Source: $sourceMode ($skillsSource)"
Write-Host "  Scope:  $scope"
Write-Host "  Target: $target"
Write-Host "  Skills: $($skills -join ', ')"
Write-Host ""

if ($Uninstall) {
    foreach ($skill in $skills) {
        $skillTarget = Join-Path $target $skill
        if (Test-Path $skillTarget) {
            if ($DryRun) {
                Write-Host "[dry-run] Would remove $skillTarget" -ForegroundColor Yellow
            } else {
                Remove-Item -Recurse -Force $skillTarget
                Write-Host "Removed $skill" -ForegroundColor Green
            }
        } else {
            Write-Host "$skill not present, skipping" -ForegroundColor DarkGray
        }
    }
    Write-Host ""
    Write-Host "Done." -ForegroundColor Cyan
    return
}

if (-not (Test-Path $target)) {
    if ($DryRun) { Write-Host "[dry-run] Would create $target" -ForegroundColor Yellow }
    else { New-Item -ItemType Directory -Path $target -Force | Out-Null }
}

foreach ($skill in $skills) {
    $src = Join-Path $skillsSource $skill
    $dst = Join-Path $target $skill

    if (-not (Test-Path $src)) {
        Write-Host "WARN: source missing: $src" -ForegroundColor Yellow
        continue
    }

    if (Test-Path $dst) {
        Write-Host "Existing $skill found, replacing..." -ForegroundColor Yellow
        if (-not $DryRun) { Remove-Item -Recurse -Force $dst }
    }

    if ($DryRun) {
        Write-Host "[dry-run] Would copy $src -> $dst" -ForegroundColor Yellow
    } else {
        Copy-Item -Recurse -Path $src -Destination $dst
        Write-Host "Installed $skill" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Done." -ForegroundColor Cyan
Write-Host ""
Write-Host "Use in Claude Code:" -ForegroundColor White
Write-Host "  /harness          full 7-stage pipeline (real feature / bug / refactor)"
Write-Host "  /harness-plan     design-only mode (RA + SA + GR, no Dev)"
Write-Host "  /harness-explore  research/feasibility (light RA + findings.md)"
Write-Host "  /harness-goal     open-ended Dev + QA loop within a budget"
Write-Host "  /harness-batch    run a fixed list of tasks through the pipeline (fail-stop)"
Write-Host "  /harness-stream   drain a living task pool you keep topping up (best-effort)"
Write-Host ""
Write-Host "  /harness-init     bootstrap an empty project with Harness skeleton"
Write-Host "  /harness-adopt    add Harness to an existing project"
Write-Host "  /harness-verify   run the project's verify_all"
Write-Host "  /harness-status   inspect Harness assets"
Write-Host "  /harness-intervene  redirect / pause / add-task to an inflight pipeline (soft Ctrl-C)"
Write-Host "  /harness-supervise  observer-only health check of a task folder"
Write-Host "  /harness-decision-mode  switch how much the AI decides on its own (Mode 1/2/3)"
Write-Host ""
Write-Host "Tip: for versioned/auditable install, prefer the plugin path inside Claude Code:" -ForegroundColor Cyan
Write-Host "  /plugin marketplace add Alan-IFT/harness-kit"
Write-Host "  /plugin install harness-kit@harness-kit-marketplace"

} finally {
    if ($tmpDir -and (Test-Path $tmpDir)) {
        Remove-Item -Recurse -Force $tmpDir -ErrorAction SilentlyContinue
    }
}
