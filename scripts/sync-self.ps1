# sync-self.ps1
# Sync the source-of-truth agent definitions from
#   skills/harness-init/templates/common/.claude/agents/
# to
#   .claude/agents/
#
# Run this after editing any agent file in either location.
# The verify_all script enforces these two are byte-identical.

[CmdletBinding()]
param([switch]$Check)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path $PSScriptRoot -Parent
$source = Join-Path $repoRoot "skills/harness-init/templates/common/.claude/agents"
$target = Join-Path $repoRoot ".claude/agents"

if (-not (Test-Path $source)) {
    Write-Error "Source folder missing: $source"
    exit 1
}
if (-not (Test-Path $target)) {
    New-Item -ItemType Directory -Path $target -Force | Out-Null
}

$sourceFiles = Get-ChildItem -Path $source -Filter "*.md" -File
$drift = @()

foreach ($f in $sourceFiles) {
    $dst = Join-Path $target $f.Name
    $copy = $true

    if (Test-Path $dst) {
        $srcHash = (Get-FileHash $f.FullName -Algorithm SHA256).Hash
        $dstHash = (Get-FileHash $dst -Algorithm SHA256).Hash
        if ($srcHash -eq $dstHash) {
            $copy = $false
        } else {
            $drift += $f.Name
        }
    } else {
        $drift += $f.Name
    }

    if ($Check) {
        # Read-only: just report drift, don't write
        continue
    }

    if ($copy) {
        Copy-Item -Path $f.FullName -Destination $dst -Force
        Write-Host "Synced $($f.Name)" -ForegroundColor Green
    }
}

# Check for orphans in target (files at root that aren't in source)
$targetFiles = Get-ChildItem -Path $target -Filter "*.md" -File
foreach ($f in $targetFiles) {
    $src = Join-Path $source $f.Name
    if (-not (Test-Path $src)) {
        Write-Host "WARN: orphan in target: $($f.Name)" -ForegroundColor Yellow
        $drift += "(orphan) $($f.Name)"
    }
}

if ($Check) {
    if ($drift.Count -gt 0) {
        Write-Host "Drift detected:" -ForegroundColor Red
        $drift | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
        exit 1
    } else {
        Write-Host "In sync." -ForegroundColor Green
        exit 0
    }
}

Write-Host ""
Write-Host "Sync complete." -ForegroundColor Cyan
