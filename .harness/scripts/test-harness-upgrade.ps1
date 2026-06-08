# test-harness-upgrade.ps1 — Regression for the /harness-upgrade mechanical layer (T-012).
#
# PowerShell twin of test-harness-upgrade.sh. Drives upgrade-project.ps1 against
# synthetic "old-layout" fixtures (each its OWN temp dir — insight L22, never a shared
# $tmp) built with `git init` + a pre-T-007 scripts/ layout, then asserts the end state.
#
# --template-root for the helper = this repo root (its skills/harness-init/templates/
# IS the current template source).
#
# Usage:
#   .\.harness\scripts\test-harness-upgrade.ps1
#   .\.harness\scripts\test-harness-upgrade.ps1 -KeepTemp
#
# I.6 note: this file embeds fixture strings; it lives at .harness/scripts/ (NOT under
# templates/), so D.2 does not scan it. Added to the I.6 exempt-FILE list only if a
# fixture string trips a banned phrase (it does not — fixtures are build-command text).

$ErrorActionPreference = "Stop"
# Script lives at .harness/scripts/ — repo root is two levels up.
$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

$KeepTemp = $false
foreach ($a in $args) { if ($a -eq '-KeepTemp' -or $a -eq '--keep-temp') { $KeepTemp = $true } }

$helper = Join-Path $repoRoot ".harness/scripts/upgrade-project.ps1"

$pass = 0
$fail = 0
$failed = @()

function Assert($name, [scriptblock]$cond) {
    $ok = $false
    try { $ok = (& $cond) -eq $true } catch { $ok = $false }
    if ($ok) {
        Write-Host "  [PASS] $name" -ForegroundColor Green
        $script:pass++
    } else {
        Write-Host "  [FAIL] $name" -ForegroundColor Red
        $script:fail++
        $script:failed += $name
    }
}

# --- fixture builder: a pre-T-007 old-layout project in a fresh temp dir ----------
function New-OldFixture($label, [switch]$Customized, [switch]$NoMarkers, [switch]$CustomHook) {
    $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("harness-upgrade-$label-" + [System.Guid]::NewGuid().ToString("N").Substring(0, 8))
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    Push-Location $dir
    try {
        git init -q | Out-Null
        git config user.email "t@example.com" | Out-Null
        git config user.name "test" | Out-Null

        New-Item -ItemType Directory -Path (Join-Path $dir "scripts") -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $dir ".claude") -Force | Out-Null

        # OLD harness-sync.ps1 with the pre-T-007 ONE-up root derivation.
        $oldSync = @'
# old harness-sync.ps1 (pre-T-007). Repo root derived ONE level up (WRONG after relocation).
$repoRoot = Split-Path $PSScriptRoot -Parent
if (-not (Test-Path (Join-Path $repoRoot ".git"))) {
    Write-Error "harness-sync: wrong root $repoRoot"
    exit 3
}
Write-Host "ok root=$repoRoot"
exit 0
'@
        Set-Content -Path (Join-Path $dir "scripts/harness-sync.ps1") -Value $oldSync -NoNewline
        Set-Content -Path (Join-Path $dir "scripts/harness-sync.sh") -Value "#!/bin/sh`nexit 0`n" -NoNewline

        # OLD verify_all (short) — either stub B.* or customized, with or without markers.
        if ($NoMarkers) {
            if ($Customized) {
                $vbody = "# old verify_all (no markers)`n# --- B. Build ---`nstep `"B.1`" `"Build`" `"PASS`"`n& cargo build`n"
            } else {
                $vbody = "# old verify_all (no markers)`n# --- B. Build ---`nstep `"B.1`" `"Build`" `"SKIP`"`n"
            }
        } else {
            $inner = if ($Customized) {
                "# --- B. Build ---`nstep `"B.1`" `"Build`" `"PASS`"`n& cargo build --release`n"
            } else {
                "# --- B. Build ---`nstep `"B.1`" `"Build`" `"SKIP`"`n"
            }
            $vbody = "# old verify_all (with markers)`n# >>> HARNESS:B-CUSTOM:BEGIN (your build/test/lint checks live here; preserved across /harness-upgrade) <<<`n$inner# >>> HARNESS:B-CUSTOM:END <<<`n"
        }
        Set-Content -Path (Join-Path $dir "scripts/verify_all.ps1") -Value $vbody -NoNewline
        Set-Content -Path (Join-Path $dir "scripts/verify_all.sh") -Value $vbody -NoNewline

        # A non-harness custom script that must NEVER be moved.
        Set-Content -Path (Join-Path $dir "scripts/my-custom.ps1") -Value "# user script`n" -NoNewline

        # baseline.json
        Set-Content -Path (Join-Path $dir "scripts/baseline.json") -Value '{"test_count":0}' -NoNewline

        # OLD settings.json referencing the old scripts/ path.
        $settings = @'
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "hooks": {
    "Stop": [ { "hooks": [ { "type": "command", "command": "pwsh -NoProfile -File scripts/harness-sync.ps1" } ] } ],
    "PreToolUse": [ { "matcher": "Bash", "hooks": [ { "type": "command", "command": "pwsh -NoProfile -File scripts/guard-rm.ps1" } ] } ]
  }
}
'@
        Set-Content -Path (Join-Path $dir ".claude/settings.json") -Value $settings -NoNewline

        # pre-commit hook: stock pre-T-007 (old path) or hand-customized.
        New-Item -ItemType Directory -Path (Join-Path $dir ".git/hooks") -Force | Out-Null
        if ($CustomHook) {
            Set-Content -Path (Join-Path $dir ".git/hooks/pre-commit") -Value "#!/bin/sh`n# MY OWN HOOK - do not touch`necho hi`n" -NoNewline
        } else {
            # The pre-T-007 stock hook = current body with scripts/ instead of .harness/scripts/.
            $stockOld = @'
#!/bin/sh
# harness-kit pre-commit hook.
# Blocks the commit if .harness/ has drifted from CLAUDE.md or .github/copilot-instructions.md.
# Tool-agnostic: catches edits from Claude Code, Copilot, Cursor, or hand-typed.
set -e
_drift=0
if command -v pwsh >/dev/null 2>&1 && [ -f scripts/harness-sync.ps1 ]; then
    pwsh -File scripts/harness-sync.ps1 -Check >/dev/null 2>&1 || _drift=1
elif command -v bash >/dev/null 2>&1 && [ -f scripts/harness-sync.sh ]; then
    bash scripts/harness-sync.sh --check >/dev/null 2>&1 || _drift=1
else
    echo "harness-kit pre-commit: neither pwsh nor bash found; skipping drift check." >&2
    exit 0
fi
if [ "$_drift" = "1" ]; then
    echo "" >&2
    echo "harness-kit: drift between .harness/ and .claude/." >&2
    echo "  .claude/agents/ and/or .claude/skills/ are stale relative to .harness/." >&2
    echo "" >&2
    echo "  Fix: pwsh -File .harness/scripts/harness-sync.ps1   (Windows)" >&2
    echo "       bash .harness/scripts/harness-sync.sh          (macOS / Linux)" >&2
    echo "  Then: git add .claude/ && git commit ..." >&2
    echo "" >&2
    echo "  Note: edits to .harness/rules/ do NOT need sync (referenced by AI-GUIDE.md, not composed)." >&2
    echo "  Bypass once (NOT recommended): git commit --no-verify" >&2
    exit 1
fi
'@
            Set-Content -Path (Join-Path $dir ".git/hooks/pre-commit") -Value $stockOld -NoNewline
        }

        git add -A | Out-Null
        git commit -q -m "old fixture" | Out-Null
    } finally {
        Pop-Location
    }
    return $dir
}

function Invoke-Upgrade($dir, [string[]]$extra) {
    Push-Location $dir
    try {
        $argList = @("-Type", "generic", "-Stack", "Rust CLI", "-TemplateRoot", $repoRoot, "-Today", "2026-06-08") + $extra
        $out = & pwsh -NoProfile -File $helper @argList 2>&1
        $code = $LASTEXITCODE
        return @{ out = ($out -join "`n"); code = $code }
    } finally {
        Pop-Location
    }
}

$tmpDirs = @()

try {
    Write-Host "=== test-harness-upgrade (PowerShell) ===" -ForegroundColor Cyan

    # --- Fixture A: old-baseline real upgrade (AC-1..AC-5, AC-9) ---
    Write-Host "`n--- Fixture A: old-baseline real upgrade ---" -ForegroundColor Cyan
    $a = New-OldFixture "baseline"; $tmpDirs += $a
    $r = Invoke-Upgrade $a @()
    Assert "A: helper exits 0" { $r.code -eq 0 }
    Assert "A: harness-sync.ps1 relocated to .harness/scripts/" { Test-Path (Join-Path $a ".harness/scripts/harness-sync.ps1") }
    Assert "A: harness-sync.ps1 removed from scripts/" { -not (Test-Path (Join-Path $a "scripts/harness-sync.ps1")) }
    Assert "A: custom scripts/my-custom.ps1 untouched (AC-1)" { Test-Path (Join-Path $a "scripts/my-custom.ps1") }
    # AC-5 — the relocated harness-sync derives root TWO-up and is byte-refreshed.
    $relocated = Get-Content (Join-Path $a ".harness/scripts/harness-sync.ps1") -Raw
    Assert "A: relocated harness-sync.ps1 is two-up (content-refreshed, AC-5)" { $relocated -match 'two levels up' -and $relocated -match 'Split-Path \(Split-Path \$\w+ -Parent\) -Parent' }
    Assert "A: relocated harness-sync.ps1 no longer carries one-up WRONG marker" { $relocated -notmatch 'wrong root' }
    # AC-5 runtime — invoke the relocated script from project root, it must find root.
    Push-Location $a
    try {
        & pwsh -NoProfile -File (Join-Path $a ".harness/scripts/harness-sync.ps1") -Check *> $null
        $syncCode = $LASTEXITCODE
    } finally { Pop-Location }
    Assert "A: relocated harness-sync runs from project root and finds repo root (AC-5 runtime)" { $syncCode -eq 0 }
    # AC-3 — settings rewired + still parses.
    $set = Get-Content (Join-Path $a ".claude/settings.json") -Raw
    Assert "A: settings rewired to .harness/scripts/ (AC-3)" { $set -match '\.harness/scripts/harness-sync\.' }
    # No bare `-File scripts/harness-sync` (unambiguous old form); the rewired
    # `.harness/scripts/harness-sync` legitimately embeds "scripts/harness-sync".
    Assert "A: settings no longer references bare scripts/harness-sync (AC-3)" { -not $set.Contains('-File scripts/harness-sync') }
    Assert "A: settings still parses as JSON (AC-3)" { ($set | ConvertFrom-Json) -ne $null }
    # AC-2 — hook points at new path.
    $hook = Get-Content (Join-Path $a ".git/hooks/pre-commit") -Raw
    Assert "A: pre-commit hook references .harness/scripts/harness-sync (AC-2)" { $hook -match '\.harness/scripts/harness-sync\.' }
    # AC-4 — verify_all regenerated with current check set + no placeholders.
    $va = Get-Content (Join-Path $a ".harness/scripts/verify_all.ps1") -Raw
    Assert "A: verify_all.ps1 regenerated with current E.* check (AC-4)" { $va -match 'E\.3' -or $va -match 'agent definitions' }
    Assert "A: verify_all.ps1 has no unsubstituted {{...}} (AC-4)" { $va -notmatch '\{\{[A-Za-z_]+\}\}' }
    # AC-9 — self-bootstrap: migrate-scripts-layout now present (refreshed in).
    Assert "A: migrate-scripts-layout.ps1 present after upgrade (AC-9)" { Test-Path (Join-Path $a ".harness/scripts/migrate-scripts-layout.ps1") }
    Assert "A: upgrade SUMMARY line emitted" { $r.out -match 'SUMMARY\|added=' }

    # --- Fixture A re-run: idempotence (AC-6) ---
    Write-Host "`n--- Fixture A re-run: idempotence ---" -ForegroundColor Cyan
    $r2 = Invoke-Upgrade $a @()
    Assert "A2: 2nd run exits 0 (AC-6)" { $r2.code -eq 0 }
    Assert "A2: 2nd run reports NOOP for verify_all (AC-6)" { $r2.out -match 'NOOP\|verify_all' }
    Assert "A2: 2nd run does not REWIRE settings again (fixed point)" { $r2.out -notmatch 'REWIRE\|' -or $r2.out -match 'NOOP\|.claude/settings.json' }

    # --- Fixture B: dry-run leaves fixture unchanged (AC-7) ---
    Write-Host "`n--- Fixture B: dry-run ---" -ForegroundColor Cyan
    $b = New-OldFixture "dryrun"; $tmpDirs += $b
    $before = (git -C $b status --porcelain)
    $rb = Invoke-Upgrade $b @("-DryRun")
    Assert "B: dry-run exits 0 (AC-7)" { $rb.code -eq 0 }
    Assert "B: dry-run prints PLAN lines (AC-7)" { $rb.out -match 'PLAN\|MOVE' }
    Assert "B: dry-run leaves scripts/harness-sync.ps1 in place (AC-7)" { Test-Path (Join-Path $b "scripts/harness-sync.ps1") }
    Assert "B: dry-run did not create .harness/scripts/harness-sync.ps1 (AC-7)" { -not (Test-Path (Join-Path $b ".harness/scripts/harness-sync.ps1")) }
    $after = (git -C $b status --porcelain)
    Assert "B: dry-run made no git-visible change (AC-7)" { "$before" -eq "$after" }

    # --- Fixture C: custom (non-stock) hook surfaced as conflict (BC-7) ---
    Write-Host "`n--- Fixture C: custom hook conflict ---" -ForegroundColor Cyan
    $c = New-OldFixture "customhook" -CustomHook; $tmpDirs += $c
    $rc = Invoke-Upgrade $c @()
    Assert "C: helper exits 3 on non-stock hook (BC-7)" { $rc.code -eq 3 }
    Assert "C: CONFLICT|hook surfaced (BC-7)" { $rc.out -match 'CONFLICT\|hook' }
    Assert "C: custom hook NOT overwritten (BC-7)" { (Get-Content (Join-Path $c ".git/hooks/pre-commit") -Raw) -match 'MY OWN HOOK' }

    # --- Fixture D: marker-customized verify_all is SPLICE-preserved (AC-13 merge) ---
    Write-Host "`n--- Fixture D: B.* splice preserve ---" -ForegroundColor Cyan
    $d = New-OldFixture "splice" -Customized; $tmpDirs += $d
    $rd = Invoke-Upgrade $d @()
    Assert "D: helper exits 0 (splice path)" { $rd.code -eq 0 }
    Assert "D: VERIFY-SPLICE emitted (AC-13 merge)" { $rd.out -match 'VERIFY-SPLICE' }
    $dva = Get-Content (Join-Path $d ".harness/scripts/verify_all.ps1") -Raw
    Assert "D: spliced verify_all retains user cargo build check (AC-13 merge)" { $dva -match 'cargo build --release' }
    Assert "D: spliced verify_all also has current E.* structure (regen body)" { $dva -match 'agent definitions' -or $dva -match 'E\.3' }

    # --- Fixture E: no-marker customized verify_all HALTs (AC-13 regenerate-warn) ---
    Write-Host "`n--- Fixture E: B.* halt (no markers + custom) ---" -ForegroundColor Cyan
    $e = New-OldFixture "halt" -Customized -NoMarkers; $tmpDirs += $e
    $re = Invoke-Upgrade $e @()
    Assert "E: helper exits 2 (refresh-blocked, AC-13 warn branch)" { $re.code -eq 2 }
    Assert "E: VERIFY-HALT emitted" { $re.out -match 'VERIFY-HALT' }
    # --force regenerates (the .bak preserved the old checks).
    $ref = Invoke-Upgrade $e @("-Force")
    Assert "E: --force completes the upgrade (exit 0)" { $ref.code -eq 0 }
    Assert "E: --force wrote verify_all (REGEN)" { $ref.out -match 'VERIFY-REGEN\|ps1' -or (Test-Path (Join-Path $e ".harness/scripts/verify_all.ps1")) }

    # --- Fixture F: non-Claude-Code project (no .claude/settings.json) (BC-15 / OQ-9) ---
    Write-Host "`n--- Fixture F: non-CC project (no settings) ---" -ForegroundColor Cyan
    $f = New-OldFixture "noncc"; $tmpDirs += $f
    Remove-Item (Join-Path $f ".claude/settings.json") -Force
    $rf = Invoke-Upgrade $f @()
    Assert "F: helper exits 0 without settings (BC-15)" { $rf.code -eq 0 }
    Assert "F: settings rewire SKIPPED with note (OQ-9)" { $rf.out -match 'SKIP\|.claude/settings.json absent' }
    Assert "F: scripts still relocated without settings" { Test-Path (Join-Path $f ".harness/scripts/harness-sync.ps1") }

    # --- Fixture G: no-harness bare repo halts (BC-2 / AC-11) ---
    Write-Host "`n--- Fixture G: no-harness halt ---" -ForegroundColor Cyan
    $g = Join-Path ([System.IO.Path]::GetTempPath()) ("harness-upgrade-noharness-" + [System.Guid]::NewGuid().ToString("N").Substring(0, 8))
    New-Item -ItemType Directory -Path $g -Force | Out-Null
    $tmpDirs += $g
    Push-Location $g
    try { git init -q | Out-Null } finally { Pop-Location }
    $rg = Invoke-Upgrade $g @()
    Assert "G: bare git repo (no harness) exits 1 (BC-2/AC-11)" { $rg.code -eq 1 }

    Write-Host "`n=== Summary ===" -ForegroundColor Cyan
    Write-Host "  PASS: $pass" -ForegroundColor Green
    Write-Host "  FAIL: $fail" -ForegroundColor Red
    if ($fail -gt 0) {
        Write-Host "  Failed:" -ForegroundColor Red
        $failed | ForEach-Object { Write-Host "    - $_" -ForegroundColor Red }
    }
} finally {
    if (-not $KeepTemp) {
        foreach ($d in $tmpDirs) {
            if (Test-Path $d) { Remove-Item $d -Recurse -Force -ErrorAction SilentlyContinue }
        }
    } else {
        Write-Host "Kept temp dirs:" -ForegroundColor Yellow
        $tmpDirs | ForEach-Object { Write-Host "  $_" }
    }
}

if ($fail -gt 0) { exit 1 }
exit 0
