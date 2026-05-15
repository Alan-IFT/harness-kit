# install.ps1 — Install Harness Engineering skills into Claude Code
#
# Usage:
#   .\install.ps1                  # install to ~/.claude/skills (global)
#   .\install.ps1 -Project .       # install to ./.claude/skills (project-local)
#   .\install.ps1 -DryRun          # show what would happen
#   .\install.ps1 -Uninstall       # remove the installed skills

[CmdletBinding()]
param(
    [string]$Project = "",
    [switch]$DryRun,
    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"
$repoRoot = $PSScriptRoot
$skillsSource = Join-Path $repoRoot "skills"

if (-not (Test-Path $skillsSource)) {
    Write-Error "skills/ folder not found at $skillsSource. Are you running install.ps1 from the repo root?"
    exit 1
}

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

$skills = @("harness-init", "harness-adopt", "harness-verify", "harness-status")

Write-Host ""
Write-Host "Harness Engineering install" -ForegroundColor Cyan
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
    exit 0
}

# Install
if (-not (Test-Path $target)) {
    if ($DryRun) {
        Write-Host "[dry-run] Would create $target" -ForegroundColor Yellow
    } else {
        New-Item -ItemType Directory -Path $target -Force | Out-Null
    }
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
        if (-not $DryRun) {
            Remove-Item -Recurse -Force $dst
        }
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
Write-Host "  /harness-init     in an empty project"
Write-Host "  /harness-adopt    in an existing project"
Write-Host "  /harness-verify   run the project's verify_all"
Write-Host "  /harness-status   inspect Harness assets"
