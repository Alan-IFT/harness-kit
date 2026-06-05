# migrate-scripts-layout.ps1 — One-shot upgrade: scripts/ -> .harness/scripts/ (T-007)
#
# For an already-initialized Harness project that placed its harness-owned scripts
# under scripts/ (the pre-T-007 layout). Moves the known harness-owned scripts to
# .harness/scripts/ and rewires the two hook command strings in .claude/settings.json.
#
# Idempotent: safe to run repeatedly. A second run is a clean no-op (exit 0).
# Only the KNOWN harness-owned set is touched — your own scripts/<custom> files
# are never moved.
#
# Usage:
#   pwsh -File .harness/scripts/migrate-scripts-layout.ps1            # migrate
#   pwsh -File .harness/scripts/migrate-scripts-layout.ps1 -DryRun    # print plan, change nothing
#   pwsh -File .harness/scripts/migrate-scripts-layout.ps1 -Force     # overwrite existing targets
#
# Exit codes:
#   0  migrated, or already migrated / nothing to do
#   1  user error (not a Harness project — no .claude/settings.json)

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# Run from the project root (the directory that contains .claude/ and scripts/).
$root = (Get-Location).Path
$settings = Join-Path $root ".claude/settings.json"
$srcDir = Join-Path $root "scripts"
$dstDir = Join-Path $root ".harness/scripts"

if (-not (Test-Path $settings)) {
    [Console]::Error.WriteLine("migrate-scripts-layout: no .claude/settings.json found at $settings.")
    [Console]::Error.WriteLine("  Run this from the root of an initialized Harness project.")
    exit 1
}

# The known harness-owned movable set (filename-preserved). NOT a blanket scripts/*.
# verification_history.log is intentionally excluded — it regenerates at the new path.
$known = @(
    "verify_all.ps1", "verify_all.sh",
    "harness-sync.ps1", "harness-sync.sh",
    "guard-rm.ps1", "guard-rm.sh",
    "install-hooks.ps1", "install-hooks.sh",
    "archive-task.ps1", "archive-task.sh",
    "baseline.json"
)

$inGit = (Test-Path (Join-Path $root ".git"))
$movedAny = $false
$plan = @()

foreach ($name in $known) {
    $src = Join-Path $srcDir $name
    $dst = Join-Path $dstDir $name

    if (-not (Test-Path $src)) {
        # Source absent: either already migrated (dst present) or not part of this project.
        continue
    }
    if ((Test-Path $dst) -and -not $Force) {
        $plan += "SKIP  scripts/$name (already present at .harness/scripts/$name; use -Force to overwrite)"
        continue
    }
    $plan += "MOVE  scripts/$name -> .harness/scripts/$name"
    if (-not $DryRun) {
        if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
        $tracked = $false
        if ($inGit) {
            git ls-files --error-unmatch "scripts/$name" *> $null
            $tracked = ($LASTEXITCODE -eq 0)
        }
        if ($tracked) {
            if ($Force -and (Test-Path $dst)) { Remove-Item $dst -Force }
            git mv -f "scripts/$name" ".harness/scripts/$name" | Out-Null
        } else {
            Move-Item -Path $src -Destination $dst -Force
        }
        $movedAny = $true
    } else {
        $movedAny = $true
    }
}

# Settings rewire — surgical case-sensitive substring replace on the RAW text.
# Never re-serialize: that would reorder keys and strip the _comment / _doc_sync_hook
# documentation keys. We replace ALL occurrences of the two harness command path
# prefixes, which covers the Stop command, the PreToolUse command, the
# permissions.allow entry, AND the _doc_sync_hook doc string (4 sites total).
$raw = Get-Content $settings -Raw
$new = $raw.Replace("scripts/harness-sync.", ".harness/scripts/harness-sync.")
$new = $new.Replace("scripts/guard-rm.", ".harness/scripts/guard-rm.")
# Collapse any double prefix produced when an already-migrated `.harness/scripts/...`
# substring matched the `scripts/...` replace target. This makes the transform a
# true fixed point: running it on already-migrated text yields the same text.
$new = $new.Replace(".harness/.harness/scripts/", ".harness/scripts/")
# Only an actual content change counts as needing a settings write (idempotent:
# already-migrated text is a fixed point -> $new -ceq $raw -> no .bak, no write).
$needsSettings = ($new -cne $raw)

if ($needsSettings) {
    $plan += "EDIT  .claude/settings.json (rewire harness-sync + guard-rm hook paths)"
    if (-not $DryRun) {
        $stamp = (Get-Date).ToString("yyyyMMddTHHmmss")
        $bak = "$settings.bak-$stamp"
        Copy-Item -Path $settings -Destination $bak -Force
        [System.IO.File]::WriteAllText($settings, $new)
        Write-Host "Backed up settings.json -> $bak" -ForegroundColor DarkGray
    }
}

# Report
if ($plan.Count -eq 0) {
    Write-Host "Already migrated / nothing to do." -ForegroundColor Green
    exit 0
}

if ($DryRun) {
    Write-Host "=== migrate-scripts-layout (dry run) ===" -ForegroundColor Cyan
    $plan | ForEach-Object { Write-Host "  $_" }
    Write-Host "(dry run — no changes written)" -ForegroundColor Yellow
    exit 0
}

Write-Host "=== migrate-scripts-layout ===" -ForegroundColor Cyan
$plan | ForEach-Object { Write-Host "  $_" }
Write-Host "Done." -ForegroundColor Green
exit 0
