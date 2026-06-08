# test-language.ps1 — Regression for the /harness-language mechanical layer (T-014).
#
# Drives language-policy.ps1 against synthetic generated-project fixtures (each its OWN
# temp dir — insight L22), then asserts the end state. -TemplateRoot = this repo root.
#
# The fixtures and assertions reference the CURRENT canonical markers only (the zh
# consumer-split heading + the human-side / agent-side discriminants); they never embed
# the retired single-language phrasing, so this driver stays clear of the verify_all I.6
# guard and is NOT in the I.6 exempt-FILE list.
#
# Usage:
#   pwsh -File .harness/scripts/test-language.ps1
#   pwsh -File .harness/scripts/test-language.ps1 -KeepTemp

[CmdletBinding()]
param([switch]$KeepTemp)

$ErrorActionPreference = "Stop"
# $PSScriptRoot is .harness/scripts/, so the repo root is two levels up.
$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$helper = Join-Path $repoRoot ".harness/scripts/language-policy.ps1"

$pass = 0
$fail = 0
$failed = @()
$tmpDirs = @()

# Markers (current canonical text only — never the retired single-language form).
$zhHeading      = "输出语言（按消费者分流）"
$enHeading      = "Output language (project-wide)"
$zhHumanMarker  = '用**中文**'
$zhAgentMarker  = '用**英文**'

function Assert($name, $cond) {
    if ($cond) {
        Write-Host "  [PASS] $name"
        $script:pass++
    } else {
        Write-Host "  [FAIL] $name"
        $script:fail++
        $script:failed += $name
    }
}

function Write-Utf8($path, $text) {
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    # LF-only, no BOM — match the bash `printf`/heredoc fixtures byte-for-byte.
    [System.IO.File]::WriteAllText($path, ($text -replace "`r`n", "`n"), [System.Text.UTF8Encoding]::new($false))
}

function New-Fixture($lang, $noCopilot = $false, $mangled = $false, $doGit = $true) {
    $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("language-$lang-" + [System.IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Path (Join-Path $dir ".harness/rules") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $dir ".github") -Force | Out-Null

    if ($mangled) {
        $core = "# Demo — Project Rules`n`n## Output langauge (typo, unmatched)`n`nsome body`n`n## How this project is developed`n`nkeep`n"
    } elseif ($lang -eq "en") {
        $core = "# Demo — Project Rules`n`n> intro`n`n## Output language (project-wide)`n`nold en body`n`n## How this project is developed`n`nkeep me`n"
    } else {
        $core = "# Demo — Project Rules`n`n> intro`n`n## 输出语言（按消费者分流）`n`nold zh body`n`n## 这个项目怎么开发`n`nkeep me`n"
    }
    Write-Utf8 (Join-Path $dir ".harness/rules/00-core.md") $core

    if ($lang -eq "en" -or $mangled) {
        Write-Utf8 (Join-Path $dir "CLAUDE.md") "# Demo — bootstrap rules`n`nOutput language: **English**.`n`nmore`n"
        if (-not $noCopilot) {
            Write-Utf8 (Join-Path $dir ".github/copilot-instructions.md") "---`napplyTo: `"**`"`n---`n# Demo`n`nOutput language: **English**.`n`nmore`n"
        }
    } else {
        Write-Utf8 (Join-Path $dir "CLAUDE.md") "# Demo — bootstrap rules`n`n输出语言：面向人的产出用**中文**，面向 agent 的产出用**英文**。`n`nmore`n"
        if (-not $noCopilot) {
            Write-Utf8 (Join-Path $dir ".github/copilot-instructions.md") "---`napplyTo: `"**`"`n---`n# Demo`n`n输出语言：面向人的产出用**中文**，面向 agent 的产出用**英文**。`n`nmore`n"
        }
    }

    if ($doGit) {
        Push-Location $dir
        try {
            git init -q
            git config user.email "t@example.com"
            git config user.name "test"
            git add -A *> $null
            git commit -q -m "fixture" *> $null
        } finally { Pop-Location }
    }
    return $dir
}

$script:RunOut = ""
$script:RunCode = 0
function Invoke-Helper($dir, [string[]]$cliArgs) {
    Push-Location $dir
    try {
        $script:RunOut = (& pwsh -NoProfile -File $helper -TemplateRoot $repoRoot @cliArgs 2>&1 | Out-String)
        $script:RunCode = $LASTEXITCODE
    } finally { Pop-Location }
}

function Read-Raw($path) {
    if (-not (Test-Path $path)) { return "" }
    return [System.IO.File]::ReadAllText($path, [System.Text.UTF8Encoding]::new($false))
}

try {
    Write-Host "=== test-language (PowerShell) ==="

    # --- #1 en -> zh switch (AC-3, AC-6) ---
    Write-Host ""
    Write-Host "--- #1 en -> zh switch ---"
    $f1 = New-Fixture "en"; $tmpDirs += $f1
    Invoke-Helper $f1 @("-Lang", "zh")
    Assert "1: exits 0" ($script:RunCode -eq 0)
    $core1 = Read-Raw (Join-Path $f1 ".harness/rules/00-core.md")
    Assert "1: 00-core has zh heading (AC-3)" ($core1.Contains($zhHeading))
    Assert "1: 00-core has human-side ZH marker" ($core1.Contains($zhHumanMarker))
    Assert "1: 00-core has agent-side EN marker" ($core1.Contains($zhAgentMarker))
    Assert "1: old en heading gone (AC-6 single section)" (-not $core1.Contains($enHeading))
    $headingCount = ([regex]::Matches($core1, [regex]::Escape("输出语言（按消费者分流）"))).Count
    Assert "1: exactly one policy heading (AC-6)" ($headingCount -eq 1)
    Assert "1: '## How this project is developed' preserved" ($core1.Contains("## How this project is developed"))
    Assert "1: 'keep me' preserved (surgical)" ($core1.Contains("keep me"))
    Assert "1: CLAUDE.md zh line" ((Read-Raw (Join-Path $f1 "CLAUDE.md")).Contains("输出语言："))
    Assert "1: copilot zh line" ((Read-Raw (Join-Path $f1 ".github/copilot-instructions.md")).Contains("输出语言："))
    $hasBak = (Get-ChildItem (Join-Path $f1 ".harness/rules") -Filter "*.bak*" -ErrorAction SilentlyContinue) -and (Get-ChildItem $f1 -Filter "CLAUDE.md.bak*" -ErrorAction SilentlyContinue)
    Assert "1: .bak written per file" ([bool]$hasBak)

    # --- #2 idempotence of the switch (AC-2) ---
    Write-Host ""
    Write-Host "--- #2 idempotent re-run zh ---"
    $bakBefore = (Get-ChildItem (Join-Path $f1 ".harness/rules") -Filter "*.bak*" -ErrorAction SilentlyContinue).Count
    Invoke-Helper $f1 @("-Lang", "zh")
    Assert "2: 2nd run exits 0 (AC-2)" ($script:RunCode -eq 0)
    Assert "2: 2nd run all NOOP (AC-2)" ($script:RunOut.Contains("NOOP|.harness/rules/00-core.md"))
    $bakAfter = (Get-ChildItem (Join-Path $f1 ".harness/rules") -Filter "*.bak*" -ErrorAction SilentlyContinue).Count
    Assert "2: no new .bak on no-op (AC-2)" ($bakBefore -eq $bakAfter)

    # --- #3 zh -> en switch (AC-1, AC-6) ---
    Write-Host ""
    Write-Host "--- #3 zh -> en switch ---"
    $f3 = New-Fixture "zh"; $tmpDirs += $f3
    Invoke-Helper $f3 @("-Lang", "en")
    Assert "3: exits 0" ($script:RunCode -eq 0)
    $core3 = Read-Raw (Join-Path $f3 ".harness/rules/00-core.md")
    Assert "3: 00-core has en heading (AC-1)" ($core3.Contains($enHeading))
    Assert "3: en single-language body present" ($core3.Contains("must be in English"))
    Assert "3: old zh heading gone (AC-6)" (-not $core3.Contains($zhHeading))
    Assert "3: zh '## 这个项目怎么开发' preserved" ($core3.Contains("## 这个项目怎么开发"))
    Assert "3: CLAUDE.md en line" ((Read-Raw (Join-Path $f3 "CLAUDE.md")).Contains("Output language: **English**."))

    # --- #4 idempotence of en (AC-2) ---
    Write-Host ""
    Write-Host "--- #4 idempotent re-run en ---"
    Invoke-Helper $f3 @("-Lang", "en")
    Assert "4: re-run en all NOOP (AC-2)" ($script:RunOut.Contains("NOOP|.harness/rules/00-core.md"))

    # --- #5 dry-run leaves the fixture unchanged (AC-5, NFR-2) ---
    Write-Host ""
    Write-Host "--- #5 dry-run unchanged ---"
    $f5 = New-Fixture "zh"; $tmpDirs += $f5
    Push-Location $f5; $before5 = (git status --porcelain | Out-String); Pop-Location
    Invoke-Helper $f5 @("-Lang", "en", "-DryRun")
    Assert "5: dry-run exits 0" ($script:RunCode -eq 0)
    Assert "5: dry-run prints PLAN lines" ($script:RunOut.Contains("PLAN|REWRITE-SECTION"))
    Push-Location $f5; $after5 = (git status --porcelain | Out-String); Pop-Location
    Assert "5: dry-run made no git-visible change (NFR-2)" ($before5 -eq $after5)
    Assert "5: dry-run wrote no .bak" (-not (Get-ChildItem (Join-Path $f5 ".harness/rules") -Filter "*.bak*" -ErrorAction SilentlyContinue))

    # --- #6 no-arg detect + refresh on a current zh project (AC-4) ---
    Write-Host ""
    Write-Host "--- #6 no-arg detect (DETECT record) ---"
    $f6 = New-Fixture "zh"; $tmpDirs += $f6
    Invoke-Helper $f6 @("-Lang", "zh", "-DryRun")
    Assert "6: DETECT|zh|00-core emitted (AC-4)" ($script:RunOut.Contains("DETECT|zh|00-core"))
    Invoke-Helper $f6 @("-Lang", "zh")
    Assert "6: refresh to current zh rewrites to canonical text (AC-4)" ((Read-Raw (Join-Path $f6 ".harness/rules/00-core.md")).Contains($zhHumanMarker))

    # --- #7 missing copilot tolerated (AC-8) ---
    Write-Host ""
    Write-Host "--- #7 missing copilot SKIP ---"
    $f7 = New-Fixture "en" $true; $tmpDirs += $f7
    Invoke-Helper $f7 @("-Lang", "zh")
    Assert "7: exits 0 without copilot (AC-8)" ($script:RunCode -eq 0)
    Assert "7: copilot reported SKIP (AC-8)" ($script:RunOut.Contains("SKIP|.github/copilot-instructions.md|absent"))
    Assert "7: 00-core still rewritten" ((Read-Raw (Join-Path $f7 ".harness/rules/00-core.md")).Contains($zhHeading))

    # --- #8 hand-mangled heading -> CONFLICT, exit 2, file unchanged (AC-7) ---
    Write-Host ""
    Write-Host "--- #8 hand-mangled heading conflict ---"
    $f8 = New-Fixture "en" $false $true; $tmpDirs += $f8
    $core8Before = Read-Raw (Join-Path $f8 ".harness/rules/00-core.md")
    Invoke-Helper $f8 @("-Lang", "en")
    Assert "8: exits 2 on conflict (AC-7)" ($script:RunCode -eq 2)
    Assert "8: CONFLICT|section surfaced (AC-7)" ($script:RunOut.Contains("CONFLICT|section"))
    Assert "8: 00-core unchanged without -Force (AC-7)" ($core8Before -eq (Read-Raw (Join-Path $f8 ".harness/rules/00-core.md")))
    Invoke-Helper $f8 @("-Lang", "en", "-Force")
    Assert "8: -Force inserts the section (exit 0)" ($script:RunCode -eq 0)
    Assert "8: inserted en heading present after -Force" ((Read-Raw (Join-Path $f8 ".harness/rules/00-core.md")).Contains($enHeading))

    # --- #9 byte-identical zh -> en -> zh round-trip (the R7/§5.4 hazard) ---
    Write-Host ""
    Write-Host "--- #9 byte-identical zh->en->zh round-trip ---"
    $f9 = New-Fixture "zh"; $tmpDirs += $f9
    Invoke-Helper $f9 @("-Lang", "zh")
    $snapCore = Read-Raw (Join-Path $f9 ".harness/rules/00-core.md")
    $snapClaude = Read-Raw (Join-Path $f9 "CLAUDE.md")
    $snapCopilot = Read-Raw (Join-Path $f9 ".github/copilot-instructions.md")
    Invoke-Helper $f9 @("-Lang", "en")
    Invoke-Helper $f9 @("-Lang", "zh")
    Assert "9: 00-core byte-identical after round-trip (§5.4)" ($snapCore -ceq (Read-Raw (Join-Path $f9 ".harness/rules/00-core.md")))
    Assert "9: CLAUDE.md byte-identical after round-trip (§5.4)" ($snapClaude -ceq (Read-Raw (Join-Path $f9 "CLAUDE.md")))
    Assert "9: copilot byte-identical after round-trip (§5.4)" ($snapCopilot -ceq (Read-Raw (Join-Path $f9 ".github/copilot-instructions.md")))

    # --- #10 bad -Lang halts (boundary 2) ---
    Write-Host ""
    Write-Host "--- #10 invalid -Lang ---"
    $f10 = New-Fixture "en"; $tmpDirs += $f10
    # -Lang has a ValidateSet so an invalid value is rejected at param binding (non-zero exit).
    Push-Location $f10
    try {
        & pwsh -NoProfile -File $helper -TemplateRoot $repoRoot -Lang fr *> $null
        $code10 = $LASTEXITCODE
    } finally { Pop-Location }
    Assert "10: bad -Lang exits non-zero (boundary 2)" ($code10 -ne 0)

    Write-Host ""
    Write-Host "=== Summary ==="
    Write-Host "  PASS: $pass"
    Write-Host "  FAIL: $fail"
    if ($fail -gt 0) {
        Write-Host "  Failed:"
        $failed | ForEach-Object { Write-Host "    - $_" }
    }
}
finally {
    if (-not $KeepTemp) {
        foreach ($d in $tmpDirs) { if (Test-Path $d) { Remove-Item $d -Recurse -Force -ErrorAction SilentlyContinue } }
    } else {
        Write-Host "Kept temp dirs:"
        $tmpDirs | ForEach-Object { Write-Host "  $_" }
    }
}

if ($fail -gt 0) { exit 1 }
exit 0
