# harness-sync.ps1
# Binding sync: .harness/ (tool-agnostic source of truth) → .claude/ + CLAUDE.md
#
# This script is the v0.2 binding layer for Claude Code. Run it after editing
# anything under .harness/ — verify_all enforces consistency, so a forgotten
# sync becomes a FAIL.
#
# Usage:
#   harness-sync.ps1                # do the sync
#   harness-sync.ps1 -Check         # report drift only; exit 0 if in sync, 1 otherwise
#
# Sync rules:
#   .harness/agents/*.md  → .claude/agents/*.md   (byte-identical copy)
#   .harness/rules/*.md   → CLAUDE.md             (composed in filename order,
#                                                   with a generated header)
#   .harness/skills/*/    → .claude/skills/*/     (byte-identical copy; if present)

[CmdletBinding()]
param([switch]$Check)

$ErrorActionPreference = "Stop"

# Locate project root (parent of scripts/, where .harness/ lives)
$scriptDir = $PSScriptRoot
$projectRoot = Split-Path $scriptDir -Parent

$harnessDir = Join-Path $projectRoot ".harness"
$claudeDir  = Join-Path $projectRoot ".claude"
$claudeMd   = Join-Path $projectRoot "CLAUDE.md"

if (-not (Test-Path $harnessDir)) {
    Write-Error "No .harness/ found at $harnessDir. This project has not been Harness-bound. Run /harness-init or /harness-adopt first."
    exit 1
}

$drift = @()

# ---------- Compose CLAUDE.md from .harness/rules/ ----------
$rulesDir = Join-Path $harnessDir "rules"
$composedClaudeMd = $null

if (Test-Path $rulesDir) {
    $ruleFiles = Get-ChildItem -Path $rulesDir -Filter "*.md" -File | Sort-Object Name
    if ($ruleFiles.Count -gt 0) {
        $header = @"
<!-- THIS FILE IS GENERATED FROM .harness/rules/ — DO NOT EDIT DIRECTLY -->
<!-- Edit .harness/rules/*.md and run scripts/harness-sync.ps1 -->

"@
        $bodies = $ruleFiles | ForEach-Object { (Get-Content $_.FullName -Raw).TrimEnd() }
        $composedClaudeMd = $header + ($bodies -join "`n`n") + "`n"
    }
}

if ($composedClaudeMd) {
    if (Test-Path $claudeMd) {
        $current = Get-Content $claudeMd -Raw
        if ($current -ne $composedClaudeMd) {
            $drift += "CLAUDE.md (out of sync with .harness/rules/)"
            if (-not $Check) {
                [System.IO.File]::WriteAllText($claudeMd, $composedClaudeMd)
                Write-Host "Synced CLAUDE.md (from .harness/rules/)" -ForegroundColor Green
            }
        }
    } else {
        $drift += "CLAUDE.md (missing)"
        if (-not $Check) {
            [System.IO.File]::WriteAllText($claudeMd, $composedClaudeMd)
            Write-Host "Created CLAUDE.md (from .harness/rules/)" -ForegroundColor Green
        }
    }
}

# ---------- Copy .harness/agents/ → .claude/agents/ ----------
$harnessAgents = Join-Path $harnessDir "agents"
$claudeAgents  = Join-Path $claudeDir  "agents"

if (Test-Path $harnessAgents) {
    if (-not (Test-Path $claudeAgents)) {
        if ($Check) {
            $drift += ".claude/agents/ (missing)"
        } else {
            New-Item -ItemType Directory -Path $claudeAgents -Force | Out-Null
        }
    }

    Get-ChildItem -Path $harnessAgents -Filter "*.md" -File | ForEach-Object {
        $dst = Join-Path $claudeAgents $_.Name
        $needsCopy = $true
        if (Test-Path $dst) {
            if ((Get-FileHash $_.FullName -Algorithm SHA256).Hash -eq (Get-FileHash $dst -Algorithm SHA256).Hash) {
                $needsCopy = $false
            } else {
                $drift += ".claude/agents/$($_.Name) (out of sync)"
            }
        } else {
            $drift += ".claude/agents/$($_.Name) (missing)"
        }
        if ($needsCopy -and (-not $Check)) {
            Copy-Item -Path $_.FullName -Destination $dst -Force
            Write-Host "Synced .claude/agents/$($_.Name)" -ForegroundColor Green
        }
    }

    # Orphans: files in .claude/agents/ not in .harness/agents/
    if (Test-Path $claudeAgents) {
        Get-ChildItem -Path $claudeAgents -Filter "*.md" -File | ForEach-Object {
            if (-not (Test-Path (Join-Path $harnessAgents $_.Name))) {
                $drift += ".claude/agents/$($_.Name) (orphan — not in .harness/agents/)"
                if (-not $Check) {
                    Remove-Item $_.FullName -Force
                    Write-Host "Removed orphan .claude/agents/$($_.Name)" -ForegroundColor Yellow
                }
            }
        }
    }
}

# ---------- Copy .harness/skills/ → .claude/skills/ ----------
$harnessSkills = Join-Path $harnessDir "skills"
$claudeSkills  = Join-Path $claudeDir  "skills"

if (Test-Path $harnessSkills) {
    # Mirror via directory hashing (simpler: just re-copy all files and detect drift)
    Get-ChildItem -Path $harnessSkills -Recurse -File | ForEach-Object {
        $rel = $_.FullName.Substring($harnessSkills.Length).TrimStart('\','/')
        $dst = Join-Path $claudeSkills $rel
        $needsCopy = $true
        if (Test-Path $dst) {
            if ((Get-FileHash $_.FullName -Algorithm SHA256).Hash -eq (Get-FileHash $dst -Algorithm SHA256).Hash) {
                $needsCopy = $false
            } else {
                $drift += ".claude/skills/$rel (out of sync)"
            }
        } else {
            $drift += ".claude/skills/$rel (missing)"
        }
        if ($needsCopy -and (-not $Check)) {
            $dstDir = Split-Path $dst -Parent
            if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
            Copy-Item -Path $_.FullName -Destination $dst -Force
            Write-Host "Synced .claude/skills/$rel" -ForegroundColor Green
        }
    }
}

# ---------- Report ----------
if ($Check) {
    if ($drift.Count -gt 0) {
        Write-Host "Drift detected ($($drift.Count) item(s)):" -ForegroundColor Red
        $drift | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
        Write-Host ""
        Write-Host "Fix: run scripts/harness-sync.ps1 (without -Check)" -ForegroundColor Yellow
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
    Write-Host "Sync complete ($($drift.Count) item(s) updated)." -ForegroundColor Cyan
}
