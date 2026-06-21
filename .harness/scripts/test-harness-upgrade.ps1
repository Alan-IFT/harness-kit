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
    # T-12 / A8 proof: the rewritten command is the RESILIENT form ($CLAUDE_PROJECT_DIR-
    # anchored), not the bare brittle `-File .harness/scripts/...`.
    Assert "A: settings rewritten to the resilient form (CLAUDE_PROJECT_DIR-anchored, AC-8)" { $set.Contains('CLAUDE_PROJECT_DIR') }
    # T-12 / A5 proof: guard-rm (PreToolUse) is resilient-anchored but fail-CLOSED — its
    # resilient form carries NO `exit 0` fallback (the convenience Stop form does).
    Assert "A: guard-rm resilient form is fail-CLOSED (no exit 0 in its command)" {
        $gLine = ($set -split "`n") | Where-Object { $_.Contains('guard-rm.ps1') }
        -not ($gLine -join "`n").Contains('exit 0')
    }
    # AC-2 — hook points at new path.
    $hook = Get-Content (Join-Path $a ".git/hooks/pre-commit") -Raw
    Assert "A: pre-commit hook references .harness/scripts/harness-sync (AC-2)" { $hook -match '\.harness/scripts/harness-sync\.' }
    # AC-4 — verify_all regenerated with current check set + no placeholders.
    $va = Get-Content (Join-Path $a ".harness/scripts/verify_all.ps1") -Raw
    Assert "A: verify_all.ps1 regenerated with current E.* check (AC-4)" { $va.Contains('partition dev-* only') }
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
    Assert "D: spliced verify_all also has current E.* structure (regen body)" { $dva.Contains('partition dev-* only') }

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

    # ============================ T-020 fixtures ======================================
    # Token pieces: assembled so this driver source carries no literal {{NAME}} token
    # (insight 2026-06-08). Used by fixtures P / P2 and the no-token-left assertions.
    $t20o = "{" + "{"
    $t20c = "}" + "}"
    $t20tok = $t20o + "SYNC_COMMAND" + $t20c
    # T-12: the OS-picked SYNC command is now the RESILIENT (fail-open + $CLAUDE_PROJECT_DIR-
    # anchored) form. $t20pick holds the JSON-ESCAPED bytes (inner " as \") so the exact
    # `"command": "<t20pick>"` match equals the raw on-disk settings byte-for-byte (gate C3).
    # $t20run is a runnable equivalent (gate C5): it anchors to $env:CLAUDE_PROJECT_DIR the
    # same way the wired command does, presence-gates, and invokes the inner script — so the
    # script actually runs rather than exiting 0 via the fail-open empty-var path.
    if ($IsWindows -or $env:OS -eq "Windows_NT") {
        $t20pick = 'pwsh -NoProfile -Command \"Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR -EA SilentlyContinue; if (Test-Path -LiteralPath .harness/scripts/harness-sync.ps1 -PathType Leaf) { & pwsh -NoProfile -File .harness/scripts/harness-sync.ps1 }; exit 0\"'
        $t20run = 'Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR -EA SilentlyContinue; if (Test-Path -LiteralPath .harness/scripts/harness-sync.ps1 -PathType Leaf) { & pwsh -NoProfile -File .harness/scripts/harness-sync.ps1 }; exit 0'
    } else {
        $t20pick = 'sh -c ''cd \"$CLAUDE_PROJECT_DIR\" 2>/dev/null && [ -f .harness/scripts/harness-sync.sh ] && exec bash .harness/scripts/harness-sync.sh || exit 0'''
        $t20run = 'bash -c ''cd "$CLAUDE_PROJECT_DIR" 2>/dev/null && [ -f .harness/scripts/harness-sync.sh ] && bash .harness/scripts/harness-sync.sh || exit 0'''
    }

    # Minimal fixture: settings-only project (no scripts/ dir), Stop hook pre-wired to
    # the NEW path whose file does not exist anywhere — the user's reported state.
    function New-DanglingFixture($label, $stopCmd) {
        $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("harness-upgrade-$label-" + [System.Guid]::NewGuid().ToString("N").Substring(0, 8))
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Push-Location $dir
        try {
            git init -q | Out-Null
            git config user.email "t@example.com" | Out-Null
            git config user.name "test" | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $dir ".claude") -Force | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $dir "build-scripts") -Force | Out-Null
            Set-Content -Path (Join-Path $dir "build-scripts/deploy.sh") -Value "#!/bin/sh`necho deploy`nexit 0`n" -NoNewline
            $settingsBody = @'
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "_doc_sync_hook": "Stop hook runs harness-sync.",
  "hooks": {
    "Stop": [ { "hooks": [ { "type": "command", "command": "__STOP_CMD__" } ] } ],
    "UserPromptSubmit": [ { "hooks": [ { "type": "command", "command": "bash build-scripts/deploy.sh" } ] } ]
  }
}
'@
            $settingsBody = $settingsBody.Replace("__STOP_CMD__", $stopCmd)
            Set-Content -Path (Join-Path $dir ".claude/settings.json") -Value $settingsBody -NoNewline
            git add -A | Out-Null
            git commit -q -m "dangling fixture" | Out-Null
        } finally { Pop-Location }
        return $dir
    }

    # Crafted template root whose common/scripts LACKS harness-sync.* (fixtures I / P2).
    $crafted = Join-Path ([System.IO.Path]::GetTempPath()) ("harness-upgrade-crafted-" + [System.Guid]::NewGuid().ToString("N").Substring(0, 8))
    $tmpDirs += $crafted
    New-Item -ItemType Directory -Path (Join-Path $crafted "skills/harness-init/templates") -Force | Out-Null
    Copy-Item -Recurse -Path (Join-Path $repoRoot "skills/harness-init/templates/common")  -Destination (Join-Path $crafted "skills/harness-init/templates/common")
    Copy-Item -Recurse -Path (Join-Path $repoRoot "skills/harness-init/templates/generic") -Destination (Join-Path $crafted "skills/harness-init/templates/generic")
    Remove-Item (Join-Path $crafted "skills/harness-init/templates/common/.harness/scripts/harness-sync.ps1") -Force
    Remove-Item (Join-Path $crafted "skills/harness-init/templates/common/.harness/scripts/harness-sync.sh") -Force

    function Invoke-UpgradeWithRoot($dir, $tmplRoot, [string[]]$extra) {
        Push-Location $dir
        try {
            $argList = @("-Type", "generic", "-Stack", "Rust CLI", "-TemplateRoot", $tmplRoot, "-Today", "2026-06-08") + $extra
            $out = & pwsh -NoProfile -File $helper @argList 2>&1
            $code = $LASTEXITCODE
            return @{ out = ($out -join "`n"); code = $code }
        } finally { Pop-Location }
    }

    # --- Fixture H (design §10 "Fixture G"): dangling repair (AC-2 / FR-R1 / FR-R2) ---
    Write-Host "`n--- Fixture H: dangling-hook repair + C1 custom-hook false-positive guard ---" -ForegroundColor Cyan
    $h = New-DanglingFixture "dangling" "pwsh -NoProfile -File .harness/scripts/harness-sync.ps1"
    $tmpDirs += $h
    $rh = Invoke-Upgrade $h @()
    Assert "H: helper exits 0 (repair completes, AC-2)" { $rh.code -eq 0 }
    Assert "H: wired target .harness/scripts/harness-sync.ps1 exists after repair (AC-2)" { Test-Path (Join-Path $h ".harness/scripts/harness-sync.ps1") }
    Push-Location $h
    try {
        & pwsh -NoProfile -File (Join-Path $h ".harness/scripts/harness-sync.ps1") *> $null
        $hSyncCode = $LASTEXITCODE
    } finally { Pop-Location }
    Assert "H: invoking the wired command from project root exits 0 (AC-2 runtime)" { $hSyncCode -eq 0 }
    # T-12 / A8 proof: the dangling bare `pwsh -File .harness/scripts/harness-sync.ps1` is
    # repaired to the RESILIENT form ($CLAUDE_PROJECT_DIR-anchored, fail-open exit 0), not
    # left brittle.
    $hSet = Get-Content (Join-Path $h ".claude/settings.json") -Raw
    Assert "H: repaired Stop command is the resilient form (CLAUDE_PROJECT_DIR-anchored, AC-8)" { $hSet.Contains('CLAUDE_PROJECT_DIR') }
    Assert "H: repaired Stop command is fail-OPEN (carries the convenience exit 0 terminator)" { $hSet.Contains('exit 0') }
    # Real-run probe via the wired resilient command (gate C5 / F4): set CLAUDE_PROJECT_DIR
    # so the anchor resolves and the script actually runs (not the fail-open empty-var path).
    Push-Location $h
    $hPrevCpd = $env:CLAUDE_PROJECT_DIR
    try {
        $env:CLAUDE_PROJECT_DIR = $h
        Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR -EA SilentlyContinue
        if (Test-Path -LiteralPath .harness/scripts/harness-sync.ps1 -PathType Leaf) { & pwsh -NoProfile -File .harness/scripts/harness-sync.ps1 *> $null }
        $hWiredCode = $LASTEXITCODE
    } finally { $env:CLAUDE_PROJECT_DIR = $hPrevCpd; Pop-Location }
    Assert "H: invoking the wired RESILIENT command (anchored) exits 0 (AC-2 runtime)" { $hWiredCode -eq 0 }
    Assert "H: no CONFLICT|congruence in output (end state congruent)" { $rh.out -notmatch 'CONFLICT\|congruence' }
    Assert "H: [C1] custom build-scripts/deploy.sh hook NOT flagged (left-bounded regex)" { -not $rh.out.Contains('build-scripts') }
    $hSetBefore = Get-Content (Join-Path $h ".claude/settings.json") -Raw
    $hBakBefore = (Get-ChildItem (Join-Path $h ".claude") -Filter "settings.json.bak-*" -File -ErrorAction SilentlyContinue).Count
    $rh2 = Invoke-Upgrade $h @()
    Assert "H2: re-run exits 0 (FR-R2 idempotent)" { $rh2.code -eq 0 }
    $hBakAfter = (Get-ChildItem (Join-Path $h ".claude") -Filter "settings.json.bak-*" -File -ErrorAction SilentlyContinue).Count
    Assert "H2: re-run wrote no new settings .bak (FR-R2)" { $hBakBefore -eq $hBakAfter }
    Assert "H2: settings byte-identical after re-run (FR-R2)" { (Get-Content (Join-Path $h ".claude/settings.json") -Raw) -ceq $hSetBefore }

    # --- Fixture I (design §10 "Fixture H"): incongruent end state (FR-P3) -----------
    Write-Host "`n--- Fixture I: incongruent end state (template + project both lack the script) ---" -ForegroundColor Cyan
    $iFix = Join-Path ([System.IO.Path]::GetTempPath()) ("harness-upgrade-incongruent-" + [System.Guid]::NewGuid().ToString("N").Substring(0, 8))
    New-Item -ItemType Directory -Path $iFix -Force | Out-Null
    $tmpDirs += $iFix
    Push-Location $iFix
    try {
        git init -q | Out-Null
        git config user.email "t@example.com" | Out-Null
        git config user.name "test" | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $iFix ".claude") -Force | Out-Null
        $iSettings = @'
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "hooks": {
    "Stop": [ { "hooks": [ { "type": "command", "command": "pwsh -NoProfile -File scripts/harness-sync.ps1" } ] } ]
  }
}
'@
        Set-Content -Path (Join-Path $iFix ".claude/settings.json") -Value $iSettings -NoNewline
        git add -A | Out-Null
        git commit -q -m "incongruent fixture" | Out-Null
    } finally { Pop-Location }
    $ri = Invoke-UpgradeWithRoot $iFix $crafted @()
    Assert "I: GAP|template-missing emitted for harness-sync (FR-P3)" { $ri.out -match 'GAP\|template-missing\|absent\|\.harness/scripts/harness-sync\.' }
    Assert "I: CONFLICT|congruence names the missing path (FR-P3)" { ($ri.out -match 'CONFLICT\|congruence') -and $ri.out.Contains('missing scripts/harness-sync.ps1') }
    Assert "I: helper exits 4 (congruence failure wins)" { $ri.code -eq 4 }
    $iSet = Get-Content (Join-Path $iFix ".claude/settings.json") -Raw
    Assert "I: settings still references the LEGACY path (no dangling rewire)" { $iSet.Contains('-File scripts/harness-sync.ps1') }
    Assert "I: settings NOT rewired to .harness/scripts/harness-sync.ps1" { -not $iSet.Contains('-File .harness/scripts/harness-sync.ps1') }

    # --- Fixture P: B7 literal-placeholder repair (gate C3 / AC-9) --------------------
    Write-Host "`n--- Fixture P: literal-placeholder repair (B7 / gate C3) ---" -ForegroundColor Cyan
    $pFix = New-DanglingFixture "placeholder" $t20tok
    $tmpDirs += $pFix
    $rpDry = Invoke-Upgrade $pFix @("-DryRun")
    Assert "P: dry-run plans the placeholder repair (PLAN|REWIRE-PLACEHOLDER)" { ($rpDry.out -match 'PLAN\|REWIRE-PLACEHOLDER') -and $rpDry.out.Contains('SYNC_COMMAND') }
    Assert "P: dry-run leaves the token in place (B9)" { (Get-Content (Join-Path $pFix ".claude/settings.json") -Raw).Contains($t20tok) }
    Assert "P: dry-run exits 0 (projected state congruent)" { $rpDry.code -eq 0 }
    $rp = Invoke-Upgrade $pFix @()
    Assert "P: apply emits RESULT|REWIRE-PLACEHOLDER (AC-9)" { $rp.out -match 'RESULT\|REWIRE-PLACEHOLDER' }
    Assert "P: apply exits 0 (AC-9)" { $rp.code -eq 0 }
    $pSet = Get-Content (Join-Path $pFix ".claude/settings.json") -Raw
    Assert "P: wired command equals the OS-picked variant (AC-9)" { $pSet.Contains('"command": "' + $t20pick + '"') }
    Assert "P: no assembled token opener remains in settings (AC-9)" { -not $pSet.Contains($t20o) }
    # T-12: the resilient string no longer ends in the script path (it ends in `0\"`/`0'`),
    # so extract the .harness/scripts/<name>.<ext> token via the same left-bounded regex the
    # congruence scans use, not "last space-token".
    $pTok = [regex]::Match($t20pick, '(^|["'' =])((\.harness/)?scripts/[A-Za-z0-9._-]+\.(ps1|sh))')
    $pTarget = $pTok.Groups[2].Value
    Assert "P: the picked command's target file exists (AC-9)" { Test-Path (Join-Path $pFix $pTarget) }
    # Real-run probe (gate C5 / F4): set CLAUDE_PROJECT_DIR so the resilient anchor resolves
    # to the fixture root and the script actually runs, instead of the fail-open empty-var
    # path. Run $t20run (the runnable equivalent) rather than the JSON-escaped $t20pick.
    Push-Location $pFix
    $prevCpd = $env:CLAUDE_PROJECT_DIR
    try {
        $env:CLAUDE_PROJECT_DIR = $pFix
        Invoke-Expression $t20run *> $null
        $pRunCode = $LASTEXITCODE
    } finally { $env:CLAUDE_PROJECT_DIR = $prevCpd; Pop-Location }
    Assert "P: invoking the repaired wired command from project root exits 0 (AC-9)" { $pRunCode -eq 0 }
    $pBakCount = (Get-ChildItem (Join-Path $pFix ".claude") -Filter "settings.json.bak-*" -File -ErrorAction SilentlyContinue).Count
    Assert "P: exactly one settings .bak written by the repair (FR-R3)" { $pBakCount -eq 1 }
    Assert "P: _doc_sync_hook doc key preserved (raw-text edit, AC-6)" { $pSet.Contains('_doc_sync_hook') }
    Assert "P: settings still parses as JSON with canonical `$schema (AC-6)" {
        $j = $pSet | ConvertFrom-Json
        $j.'$schema' -ceq 'https://json.schemastore.org/claude-code-settings.json'
    }
    $rp2 = Invoke-Upgrade $pFix @()
    Assert "P2nd: re-run exits 0 and is a settings NOOP (B10)" { ($rp2.code -eq 0) -and ($rp2.out -match 'NOOP\|\.claude/settings\.json') }
    $pBakCount2 = (Get-ChildItem (Join-Path $pFix ".claude") -Filter "settings.json.bak-*" -File -ErrorAction SilentlyContinue).Count
    Assert "P2nd: no new .bak on re-run (B10)" { $pBakCount -eq $pBakCount2 }
    Assert "P2nd: settings byte-identical after re-run (B10)" { (Get-Content (Join-Path $pFix ".claude/settings.json") -Raw) -ceq $pSet }

    # --- Fixture P2: gated-off placeholder creates no new dangle (§6.2.5 gate) --------
    Write-Host "`n--- Fixture P2: gated-off placeholder (template cannot land the target) ---" -ForegroundColor Cyan
    $p2Fix = New-DanglingFixture "placeholder2" $t20tok
    $tmpDirs += $p2Fix
    $rp2g = Invoke-UpgradeWithRoot $p2Fix $crafted @()
    Assert "P2: token NOT substituted when the gate is off (no new dangle)" { (Get-Content (Join-Path $p2Fix ".claude/settings.json") -Raw).Contains($t20tok) }
    Assert "P2: no REWIRE-PLACEHOLDER emitted" { $rp2g.out -notmatch 'REWIRE-PLACEHOLDER' }
    Assert "P2: terminal scan flags the unresolved token (CONFLICT|congruence)" { ($rp2g.out -match 'CONFLICT\|congruence') -and $rp2g.out.Contains('unresolved placeholder token') }
    Assert "P2: helper exits 4" { $rp2g.code -eq 4 }

    # --- Fixtures M1 / M2: migrate-scripts-layout RC-1 + healthy (AC-1 / B10) ---------
    Write-Host "`n--- Fixture M1: migrate with missing source (RC-1 / AC-1) ---" -ForegroundColor Cyan
    $migrateHelper = Join-Path $repoRoot ".harness/scripts/migrate-scripts-layout.ps1"
    function New-PrerelocFixture($label, [switch]$WithSync) {
        $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("harness-migrate-$label-" + [System.Guid]::NewGuid().ToString("N").Substring(0, 8))
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Push-Location $dir
        try {
            git init -q | Out-Null
            git config user.email "t@example.com" | Out-Null
            git config user.name "test" | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $dir "scripts") -Force | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $dir ".claude") -Force | Out-Null
            Set-Content -Path (Join-Path $dir "scripts/verify_all.ps1") -Value "# vfa`n" -NoNewline
            Set-Content -Path (Join-Path $dir "scripts/verify_all.sh") -Value "# vfa`n" -NoNewline
            Set-Content -Path (Join-Path $dir "scripts/guard-rm.ps1") -Value "# guard`n" -NoNewline
            Set-Content -Path (Join-Path $dir "scripts/guard-rm.sh") -Value "# guard`n" -NoNewline
            if ($WithSync) {
                Set-Content -Path (Join-Path $dir "scripts/harness-sync.ps1") -Value "# sync`n" -NoNewline
                Set-Content -Path (Join-Path $dir "scripts/harness-sync.sh") -Value "# sync`n" -NoNewline
            }
            $mSettings = @'
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "hooks": {
    "Stop": [ { "hooks": [ { "type": "command", "command": "pwsh -NoProfile -File scripts/harness-sync.ps1" } ] } ],
    "PreToolUse": [ { "matcher": "Bash", "hooks": [ { "type": "command", "command": "pwsh -NoProfile -File scripts/guard-rm.ps1" } ] } ]
  }
}
'@
            Set-Content -Path (Join-Path $dir ".claude/settings.json") -Value $mSettings -NoNewline
            git add -A | Out-Null
            git commit -q -m "pre-relocation fixture" | Out-Null
        } finally { Pop-Location }
        return $dir
    }
    $m1 = New-PrerelocFixture "rc1"
    $tmpDirs += $m1
    Push-Location $m1
    try {
        $m1out = (& pwsh -NoProfile -File $migrateHelper 2>&1) -join "`n"
        $m1code = $LASTEXITCODE
    } finally { Pop-Location }
    Assert "M1: migrate exits 4 (RC-1 made loud, AC-1)" { $m1code -eq 4 }
    Assert "M1: CONGRUENCE-FAIL names the missing path (AC-1)" { $m1out.Contains('CONGRUENCE-FAIL') -and $m1out.Contains('missing scripts/harness-sync.ps1') }
    $m1Set = Get-Content (Join-Path $m1 ".claude/settings.json") -Raw
    Assert "M1: settings NOT rewired to a dangling .harness path (AC-1)" { -not $m1Set.Contains('-File .harness/scripts/harness-sync.ps1') }
    Assert "M1: present variant guard-rm still rewired (gated per variant)" { $m1Set.Contains('-File .harness/scripts/guard-rm.ps1') }

    Write-Host "`n--- Fixture M2: healthy migrate unchanged (B10) ---" -ForegroundColor Cyan
    $m2 = New-PrerelocFixture "healthy" -WithSync
    $tmpDirs += $m2
    Push-Location $m2
    try {
        & pwsh -NoProfile -File $migrateHelper *> $null
        $m2code = $LASTEXITCODE
    } finally { Pop-Location }
    Assert "M2: healthy migrate exits 0" { $m2code -eq 0 }
    $m2Set = Get-Content (Join-Path $m2 ".claude/settings.json") -Raw
    Assert "M2: settings rewired to .harness/scripts/harness-sync.ps1" { $m2Set.Contains('-File .harness/scripts/harness-sync.ps1') }
    # T-12 / A8: migrate also resilient-ifies the brittle command (CLAUDE_PROJECT_DIR anchor).
    Assert "M2: migrated command is the resilient form (CLAUDE_PROJECT_DIR-anchored, A8)" { $m2Set.Contains('CLAUDE_PROJECT_DIR') }
    $m2BakBefore = (Get-ChildItem (Join-Path $m2 ".claude") -Filter "settings.json.bak-*" -File -ErrorAction SilentlyContinue).Count
    Push-Location $m2
    try {
        & pwsh -NoProfile -File $migrateHelper *> $null
        $m2code2 = $LASTEXITCODE
    } finally { Pop-Location }
    $m2BakAfter = (Get-ChildItem (Join-Path $m2 ".claude") -Filter "settings.json.bak-*" -File -ErrorAction SilentlyContinue).Count
    Assert "M2: second run exits 0 and writes no new .bak (B10)" { ($m2code2 -eq 0) -and ($m2BakBefore -eq $m2BakAfter) }

    # --- Fixture M3: failed settings write is loud (B8 write-failure half) ------------
    # The moves succeed but the settings write hits a read-only file: the helper must
    # fail loudly (the PS twin aborts on the thrown WriteAllText — explicit non-zero
    # exit), never print the success line, and leave the on-disk settings untouched.
    Write-Host "`n--- Fixture M3: read-only settings -> write failure is loud (B8) ---" -ForegroundColor Cyan
    $m3 = New-PrerelocFixture "writefail" -WithSync
    $tmpDirs += $m3
    $m3Settings = Join-Path $m3 ".claude/settings.json"
    Set-ItemProperty -Path $m3Settings -Name IsReadOnly -Value $true
    # Precondition probe: environments that ignore the read-only bit (e.g. root on
    # POSIX) cannot simulate the failed write — self-disable instead of going flaky.
    $m3Enforced = $true
    try { [System.IO.File]::AppendAllText($m3Settings, ""); $m3Enforced = $false } catch { }
    if (-not $m3Enforced) {
        Write-Host "  [SKIP] M3: read-only settings.json not enforceable here (root?) — write-failure probe skipped" -ForegroundColor Yellow
    } else {
        Push-Location $m3
        try {
            $m3out = (& pwsh -NoProfile -File $migrateHelper 2>&1) -join "`n"
            $m3code = $LASTEXITCODE
        } finally { Pop-Location }
        Assert "M3: failed settings write fails loudly, not silent 0 (B8)" { $m3code -ne 0 }
        Assert "M3: no success line on a failed write (B8)" { -not $m3out.Contains("Done.") }
        Assert "M3: failed write left settings untouched on disk" { (Get-Content $m3Settings -Raw).Contains('-File scripts/harness-sync.ps1') }
    }
    Set-ItemProperty -Path $m3Settings -Name IsReadOnly -Value $false

    # --- Fixture Z: AC-5 RUNTIME fail-closed mutation probe (T-12) ------------------
    # Codifies the runtime fail-CLOSED invariant the code review asked for: build the
    # resilient pwsh guard command, attempt a destructive call, assert the guard BLOCKS
    # it when present, then DELETE guard-rm.ps1 and assert the same command exits
    # NON-zero (never a silent allow). Mirror of the bash Fixture Z.
    Write-Host "`n--- Fixture Z: AC-5 runtime fail-closed mutation probe (T-12) ---" -ForegroundColor Cyan
    $zGuardSrc = Join-Path $repoRoot ".harness/scripts/guard-rm.ps1"
    if (-not (Test-Path $zGuardSrc)) {
        Write-Host "  [SKIP] Z: guard-rm.ps1 not found in repo — runtime probe skipped" -ForegroundColor Yellow
    } else {
        $z = Join-Path ([System.IO.Path]::GetTempPath()) ("harness-upgrade-ac5-" + [System.Guid]::NewGuid().ToString("N").Substring(0, 8))
        New-Item -ItemType Directory -Path (Join-Path $z ".harness/scripts") -Force | Out-Null
        $tmpDirs += $z
        Push-Location $z; try { & git init -q } finally { Pop-Location }
        Copy-Item -Path $zGuardSrc -Destination (Join-Path $z ".harness/scripts/guard-rm.ps1")
        $zGuard = Join-Path $z ".harness/scripts/guard-rm.ps1"
        $zDestructive = '{"tool_input":{"command":"rm -rf /etc/harness-ac5-outside-target"}}'
        $zBenign = '{"tool_input":{"command":"ls -la"}}'
        # Resilient pwsh guard command, transcribed from design 3.4 (fail-CLOSED: no exit 0).
        $env:CLAUDE_PROJECT_DIR = $z
        Push-Location $z
        try {
            # Z1: guard PRESENT -> destructive call BLOCKED (non-zero).
            $zDestructive | & pwsh -NoProfile -Command "Set-Location -LiteralPath `$env:CLAUDE_PROJECT_DIR; & pwsh -NoProfile -File .harness/scripts/guard-rm.ps1" *> $null
            $z1rc = $LASTEXITCODE
            Assert "Z1: guard PRESENT blocks a destructive out-of-repo rm (rc!=0)" { $z1rc -ne 0 }
            # Z1b: benign call ALLOWED (rc=0).
            $zBenign | & pwsh -NoProfile -Command "Set-Location -LiteralPath `$env:CLAUDE_PROJECT_DIR; & pwsh -NoProfile -File .harness/scripts/guard-rm.ps1" *> $null
            $z1brc = $LASTEXITCODE
            Assert "Z1b: guard PRESENT allows a benign command (rc=0, guard genuinely ran)" { $z1brc -eq 0 }
            # Z2: MUTATE — delete guard-rm.ps1 -> same command exits NON-zero (fail-CLOSED).
            Remove-Item -Force $zGuard
            $zDestructive | & pwsh -NoProfile -Command "Set-Location -LiteralPath `$env:CLAUDE_PROJECT_DIR; & pwsh -NoProfile -File .harness/scripts/guard-rm.ps1" *> $null
            $z2rc = $LASTEXITCODE
            Assert "Z2: guard ABSENT (mutation) -> command exits non-zero, never silent-allow (fail-CLOSED)" { $z2rc -ne 0 }
        } finally { Pop-Location; Remove-Item Env:CLAUDE_PROJECT_DIR -ErrorAction SilentlyContinue }
    }

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
