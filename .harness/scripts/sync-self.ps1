# sync-self.ps1 — Repo-specific dogfood sync.
#
# This repo distributes templates/common/ as the source of truth for user projects.
# It also dogfoods that content in its own .harness/ and .harness/scripts/. This script
# keeps the two in sync (Layer 1).
#
# Synchronizes (templates/common/ → repo root):
#   .harness/scripts/harness-sync.ps1         → .harness/scripts/harness-sync.ps1
#   .harness/scripts/harness-sync.sh          → .harness/scripts/harness-sync.sh
#   .harness/scripts/install-hooks.ps1        → .harness/scripts/install-hooks.ps1
#   .harness/scripts/install-hooks.sh         → .harness/scripts/install-hooks.sh
#   .harness/scripts/archive-task.ps1         → .harness/scripts/archive-task.ps1
#   .harness/scripts/archive-task.sh          → .harness/scripts/archive-task.sh
#   .harness/scripts/guard-rm.ps1             → .harness/scripts/guard-rm.ps1
#   .harness/scripts/guard-rm.sh              → .harness/scripts/guard-rm.sh
#   .harness/scripts/migrate-scripts-layout.ps1 → .harness/scripts/migrate-scripts-layout.ps1
#   .harness/scripts/migrate-scripts-layout.sh  → .harness/scripts/migrate-scripts-layout.sh
#   .harness/scripts/upgrade-project.ps1        → .harness/scripts/upgrade-project.ps1
#   .harness/scripts/upgrade-project.sh         → .harness/scripts/upgrade-project.sh
#   .harness/scripts/language-policy.ps1        → .harness/scripts/language-policy.ps1
#   .harness/scripts/language-policy.sh         → .harness/scripts/language-policy.sh
#
# Run before commit if you've edited any of the above. verify_all step E.1 FAILs
# on drift.
#
# Usage:
#   .\.harness\scripts\sync-self.ps1            # do the sync
#   .\.harness\scripts\sync-self.ps1 -Check     # report drift only; exit 0 if in sync, 1 otherwise

[CmdletBinding()]
param([switch]$Check)

$ErrorActionPreference = "Stop"
# $PSScriptRoot is now .harness/scripts/, so the repo root is two levels up.
$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$templateCommon = Join-Path $repoRoot "skills/harness-init/templates/common"

if (-not (Test-Path $templateCommon)) {
    Write-Error "templates/common/ not found at $templateCommon"
    exit 1
}

# Mapping: source (under templates/common/) → target (under repo root)
# (Agent mappings removed at v0.30.0: the framework agents are now plugin-native,
#  edited directly in the top-level agents/ dir — there is no agent copy to mirror.
#  Partition dev-* agents ship via the type overlays, not through sync-self.)
$mappings = @(
    @{ from = ".harness/scripts/harness-sync.ps1"; to = ".harness/scripts/harness-sync.ps1"; type = "file" }
    @{ from = ".harness/scripts/harness-sync.sh"; to = ".harness/scripts/harness-sync.sh"; type = "file" }
    @{ from = ".harness/scripts/install-hooks.ps1"; to = ".harness/scripts/install-hooks.ps1"; type = "file" }
    @{ from = ".harness/scripts/install-hooks.sh"; to = ".harness/scripts/install-hooks.sh"; type = "file" }
    @{ from = ".harness/scripts/archive-task.ps1"; to = ".harness/scripts/archive-task.ps1"; type = "file" }
    @{ from = ".harness/scripts/archive-task.sh"; to = ".harness/scripts/archive-task.sh"; type = "file" }
    @{ from = ".harness/scripts/guard-rm.ps1"; to = ".harness/scripts/guard-rm.ps1"; type = "file" }
    @{ from = ".harness/scripts/guard-rm.sh"; to = ".harness/scripts/guard-rm.sh"; type = "file" }
    @{ from = ".harness/scripts/migrate-scripts-layout.ps1"; to = ".harness/scripts/migrate-scripts-layout.ps1"; type = "file" }
    @{ from = ".harness/scripts/migrate-scripts-layout.sh"; to = ".harness/scripts/migrate-scripts-layout.sh"; type = "file" }
    @{ from = ".harness/scripts/upgrade-project.ps1"; to = ".harness/scripts/upgrade-project.ps1"; type = "file" }
    @{ from = ".harness/scripts/upgrade-project.sh"; to = ".harness/scripts/upgrade-project.sh"; type = "file" }
    @{ from = ".harness/scripts/language-policy.ps1"; to = ".harness/scripts/language-policy.ps1"; type = "file" }
    @{ from = ".harness/scripts/language-policy.sh"; to = ".harness/scripts/language-policy.sh"; type = "file" }
)

$drift = @()

function Sync-File($src, $dst) {
    $needsCopy = $true
    if (Test-Path $dst) {
        $srcHash = (Get-FileHash $src -Algorithm SHA256).Hash
        $dstHash = (Get-FileHash $dst -Algorithm SHA256).Hash
        if ($srcHash -eq $dstHash) { $needsCopy = $false }
    }
    return $needsCopy
}

foreach ($m in $mappings) {
    $src = Join-Path $templateCommon $m.from
    $dst = Join-Path $repoRoot $m.to

    if (-not (Test-Path $src)) {
        Write-Host "WARN: source missing: $src" -ForegroundColor Yellow
        continue
    }

    if ($m.type -eq "file") {
        if (Sync-File $src $dst) {
            $drift += $m.to
            if (-not $Check) {
                $dstDir = Split-Path $dst -Parent
                if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
                Copy-Item -Path $src -Destination $dst -Force
                Write-Host "Synced $($m.to)" -ForegroundColor Green
            }
        }
    } elseif ($m.type -eq "dir-of-md") {
        if (-not (Test-Path $dst)) {
            if ($Check) {
                $drift += "$($m.to) (missing)"
            } else {
                New-Item -ItemType Directory -Path $dst -Force | Out-Null
            }
        }
        Get-ChildItem -Path $src -Filter "*.md" -File | ForEach-Object {
            $fileDst = Join-Path $dst $_.Name
            if (Sync-File $_.FullName $fileDst) {
                $drift += "$($m.to)/$($_.Name)"
                if (-not $Check) {
                    Copy-Item -Path $_.FullName -Destination $fileDst -Force
                    Write-Host "Synced $($m.to)/$($_.Name)" -ForegroundColor Green
                }
            }
        }
        # Orphan check: files at dst not in src
        if (Test-Path $dst) {
            Get-ChildItem -Path $dst -Filter "*.md" -File | ForEach-Object {
                if (-not (Test-Path (Join-Path $src $_.Name))) {
                    $drift += "$($m.to)/$($_.Name) (orphan)"
                    if (-not $Check) {
                        Remove-Item $_.FullName -Force
                        Write-Host "Removed orphan $($m.to)/$($_.Name)" -ForegroundColor Yellow
                    }
                }
            }
        }
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

if ($drift.Count -eq 0) {
    Write-Host "Already in sync." -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "Sync-self complete." -ForegroundColor Cyan
}
