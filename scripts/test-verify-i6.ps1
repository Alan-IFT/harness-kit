# test-verify-i6.ps1 — Regression for the verify_all I.6 gap-tolerant retired-claim matcher (v0.18.0)
#
# PowerShell twin of test-verify-i6.sh. Mirrors the same fixture corpus + assertion set.
#
# The driver does NOT dot-source verify_all.ps1 (that would run all 30 checks). It
# re-declares the I.6 matcher predicate (regex builder + per-line scan + line-scoped
# exclude) as a self-contained function, kept in lockstep with the live script by a
# structural assertion (the live $banned array must match this driver's copy,
# including entry #10's exclude=@('.claude/')).
#
# Usage:
#   .\scripts\test-verify-i6.ps1                  # full run, temp dir auto-cleaned
#   .\scripts\test-verify-i6.ps1 -KeepTemp        # keep the fixture temp dir
#   pwsh -File scripts/test-verify-i6.ps1 --emit-hits <dir>   # parity-helper mode:
#       prints "fixture<TAB>idx,idx" per file; used by test-verify-i6.sh's parity check.

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path $PSScriptRoot -Parent

# Args are parsed manually (no param block) so the bash twin can pass the raw
# `--emit-hits <dir>` flag without tripping PowerShell parameter binding.
$KeepTemp = $false
$emitHits = $false
$emitDir = $null
for ($i = 0; $i -lt $args.Count; $i++) {
    switch ($args[$i]) {
        '-KeepTemp'   { $KeepTemp = $true }
        '--keep-temp' { $KeepTemp = $true }
        '--emit-hits' { $emitHits = $true; $emitDir = $args[$i + 1] }
    }
}

# ---------------------------------------------------------------------------
# I.6 matcher predicate — a self-contained re-declaration of verify_all.ps1's
# logic (§3.2/§3.4 of the design). Kept in lockstep by the structural assertion.
# ---------------------------------------------------------------------------
$i6GapDefault = 40
# The 13-entry banned list — the 1:1 twin of verify_all.ps1's $banned.
$i6Banned = @(
    @{ anchors = @('scaffolding-only'); reason = "harness-adopt has been fully automated since v0.3"; exclude = @(); gap = $null },
    @{ anchors = @('Composed','into','`CLAUDE.md`'); reason = "rules are not composed into CLAUDE.md since v0.10"; exclude = @('not','no longer','referenced'); gap = 20 },
    @{ anchors = @('composed','by','filename','order'); reason = "rules not composed since v0.10"; exclude = @(); gap = $null },
    @{ anchors = @('composition','order','in','CLAUDE.md'); reason = "no composition in CLAUDE.md since v0.10"; exclude = @('not','no longer'); gap = $null },
    @{ anchors = @('regenerates','CLAUDE.md'); reason = "harness-sync does not regenerate CLAUDE.md since v0.10"; exclude = @(); gap = $null },
    @{ anchors = @('regenerates','`CLAUDE.md`'); reason = "harness-sync does not regenerate CLAUDE.md since v0.10"; exclude = @(); gap = $null },
    @{ anchors = @('regenerated','CLAUDE.md'); reason = "CLAUDE.md is a static stub since v0.10"; exclude = @(); gap = $null },
    @{ anchors = @('regenerated','`CLAUDE.md`'); reason = "CLAUDE.md is a static stub since v0.10"; exclude = @(); gap = $null },
    @{ anchors = @('Generated','from','.harness/rules'); reason = "CLAUDE.md not generated from rules since v0.10"; exclude = @(); gap = $null },
    @{ anchors = @('.harness/','→','CLAUDE.md'); reason = "harness-sync target is .claude/, not CLAUDE.md, since v0.10"; exclude = @('.claude/'); gap = $null },
    @{ anchors = @('harness-sync','生成','CLAUDE.md'); reason = "v0.10 起 harness-sync 不再生成 CLAUDE.md"; exclude = @('不'); gap = $null },
    @{ anchors = @('harness-sync','合成','CLAUDE.md'); reason = "v0.10 起规则不再合成进 CLAUDE.md"; exclude = @('不'); gap = $null },
    @{ anchors = @('重新生成的','CLAUDE.md'); reason = "v0.10 起 CLAUDE.md 是 stub，不再被重新生成"; exclude = @(); gap = $null }
)
$i6ExemptDirs = @("docs/features/", "参考/")

function Build-I6Regex($anchors, $gap) {
    ($anchors | ForEach-Object { [regex]::Escape($_) }) -join "(.{0,$gap})"
}

# Scan-I6File PATH -> array of 1-based entry indexes that hit the file. Mirrors
# the verify_all.ps1 per-file inner loop including the line-scoped exclude.
function Scan-I6File($scanFile) {
    $result = @()
    if (-not (Test-Path -LiteralPath $scanFile -PathType Leaf)) { return $result }
    $content = Get-Content -LiteralPath $scanFile -Raw -ErrorAction SilentlyContinue
    if (-not $content) { return $result }
    $lines = $content -split "`r?`n"
    for ($idx = 0; $idx -lt $i6Banned.Count; $idx++) {
        $b = $i6Banned[$idx]
        $gap = if ($null -ne $b.gap) { $b.gap } else { $i6GapDefault }
        $rx = [regex]::new((Build-I6Regex $b.anchors $gap), [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        foreach ($line in $lines) {
            $m = $rx.Match($line)
            if (-not $m.Success) { continue }
            $excluded = $false
            foreach ($x in $b.exclude) {
                if ($line.IndexOf($x, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                    $excluded = $true; break
                }
            }
            if ($excluded) { continue }
            $result += ($idx + 1)
            break
        }
    }
    return $result
}

function Test-I6DirExempt($p) {
    foreach ($d in $i6ExemptDirs) { if ($p.StartsWith($d)) { return $true } }
    return $false
}

# ---------------------------------------------------------------------------
# Fixture corpus — design §7.2. Written into an isolated temp dir (insight L12).
# Shared by the full run and by --emit-hits mode.
# ---------------------------------------------------------------------------
function New-FixtureCorpus($dir) {
    $w = { param($name, $body) [System.IO.File]::WriteAllText((Join-Path $dir $name), $body) }
    & $w "fx-bypass.md"         "harness-sync regenerates the static stub CLAUDE.md"
    & $w "fx-adjacent.md"       "regenerates CLAUDE.md"
    & $w "fx-accurate.md"       ".claude/agents/ is regenerated by harness-sync from .harness/agents/"
    & $w "fx-case.md"           "Harness-sync Regenerates the CLAUDE.md stub"
    & $w "fx-meta-backtick.md"  'harness-sync regenerates `CLAUDE.md`'
    & $w "fx-meta-arrow.md"     ".harness/ $([char]0x2192) CLAUDE.md"
    & $w "fx-arrow-accurate.md" ".harness/agents + .harness/skills $([char]0x2192) .claude/ (CLAUDE.md is a static stub since v0.10)"
    & $w "fx-gap-exact.md"      ("regenerates" + ("X" * 40) + "CLAUDE.md")
    & $w "fx-gap-over.md"       ("regenerates" + ("X" * 41) + "CLAUDE.md")
    & $w "fx-negation-pre.md"   'rules are referenced, not composed into `CLAUDE.md`'
    & $w "fx-historical.md"     ("The original v0.2 design`n" + 'composed `.harness/rules/*.md` into a single `CLAUDE.md` so the AI could read it')
    & $w "fx-empty.md"          ""
    & $w "fx-multiline.md"      "regenerates`nCLAUDE.md`n"
    & $w "fx-e1.md"             "this skill is scaffolding-only for now"
    & $w "fx-e3.md"             "rules are composed by filename order at startup"
    & $w "fx-e4.md"             "the composition order in CLAUDE.md is alphabetical"
    & $w "fx-e9.md"             "CLAUDE.md is Generated from .harness/rules at sync time"
    & $w "fx-e11.md"            "harness-sync 生成 CLAUDE.md 的过程"
    & $w "fx-e12.md"            "harness-sync 合成 CLAUDE.md 的旧流程"
    & $w "fx-e13.md"            "这是重新生成的 CLAUDE.md 文件"
}

# fixture name -> expected hit (entry index, 1-based) or 'NONE'
$fxExpect = [ordered]@{
    "fx-bypass.md"         = 5
    "fx-adjacent.md"       = 5
    "fx-accurate.md"       = "NONE"
    "fx-case.md"           = 5
    "fx-meta-backtick.md"  = 6
    "fx-meta-arrow.md"     = 10
    "fx-arrow-accurate.md" = "NONE"
    "fx-gap-exact.md"      = 5
    "fx-gap-over.md"       = "NONE"
    "fx-negation-pre.md"   = "NONE"
    "fx-historical.md"     = "NONE"
    "fx-empty.md"          = "NONE"
    "fx-multiline.md"      = "NONE"
    "fx-e1.md"             = 1
    "fx-e3.md"             = 3
    "fx-e4.md"             = 4
    "fx-e9.md"             = 9
    "fx-e11.md"            = 11
    "fx-e12.md"            = 12
    "fx-e13.md"            = 13
}

# ===========================================================================
# --emit-hits mode: write the corpus into the dir given by the bash twin,
# print "fixture<TAB>comma-joined-indexes" per file, and exit. Used so the
# bash parity assertion can compare against this exact engine.
# ===========================================================================
if ($emitHits) {
    if (-not $emitDir -or -not (Test-Path $emitDir)) {
        Write-Error "--emit-hits requires an existing directory"
        exit 2
    }
    foreach ($name in $fxExpect.Keys) {
        $hits = Scan-I6File (Join-Path $emitDir $name)
        if ($hits.Count -gt 0) {
            [Console]::Out.WriteLine("$name`t" + ($hits -join ","))
        } else {
            [Console]::Out.WriteLine("$name")
        }
    }
    exit 0
}

# ===========================================================================
# Full regression run.
# ===========================================================================
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

Push-Location $repoRoot
try {

Write-Host "=== test-verify-i6: I.6 gap-tolerant matcher regression ===" -ForegroundColor Cyan
Write-Host "Repo: $repoRoot"
Write-Host ""

$fxTmp = Join-Path ([System.IO.Path]::GetTempPath()) "harness-verify-i6-$(Get-Random)"
New-Item -ItemType Directory -Path $fxTmp -Force | Out-Null
try {
    New-FixtureCorpus $fxTmp

    # -----------------------------------------------------------------------
    # Assertion 1 — behavioral: per fixture, hit/no-hit matches Expected.
    # -----------------------------------------------------------------------
    Write-Host "--- Assertion 1: per-fixture behavioral hit/no-hit ---" -ForegroundColor Cyan
    $psHits = @{}
    foreach ($name in $fxExpect.Keys) {
        $hits = @(Scan-I6File (Join-Path $fxTmp $name))
        $psHits[$name] = $hits
        $expect = $fxExpect[$name]
        if ($expect -eq "NONE") {
            Assert "$name expects NO hit" { $hits.Count -eq 0 }
        } else {
            Assert "$name expects HIT on entry #$expect" { $hits -contains [int]$expect }
        }
    }

    # -----------------------------------------------------------------------
    # Assertion 2 — cross-shell parity: the bash twin agrees on every hit set.
    # -----------------------------------------------------------------------
    Write-Host ""
    Write-Host "--- Assertion 2: cross-shell parity (PowerShell vs bash) ---" -ForegroundColor Cyan
    # Prefer Git-for-Windows bash, NOT the WSL launcher stub that `Get-Command bash`
    # resolves first on Windows. Derive it from git's install root (git.exe lives in
    # <Git>\cmd\, bash.exe in <Git>\bin\), then fall back to known paths.
    $bashExe = $null
    $gitCmd = Get-Command git -ErrorAction SilentlyContinue
    if ($gitCmd) {
        $gitRoot = Split-Path (Split-Path $gitCmd.Source -Parent) -Parent
        $cand = Join-Path $gitRoot "bin\bash.exe"
        if (Test-Path $cand) { $bashExe = $cand }
    }
    if (-not $bashExe) {
        foreach ($cand in @(
            "C:\Program Files\Git\bin\bash.exe",
            "C:\Program Files (x86)\Git\bin\bash.exe",
            "/usr/bin/bash", "/bin/bash")) {
            if (Test-Path $cand) { $bashExe = $cand; break }
        }
    }
    if (-not $bashExe) {
        $cmd = Get-Command bash -ErrorAction SilentlyContinue
        # Skip the WindowsApps WSL launcher stub — it is not a POSIX bash.
        if ($cmd -and $cmd.Source -notmatch 'WindowsApps') { $bashExe = $cmd.Source }
    }
    if (-not $bashExe) {
        Assert "cross-shell parity (bash not found — SKIPPED)" { $true }
    } else {
        # The bash twin exposes --emit-hits: prints "fixture<TAB>idx idx" per file.
        $bashOut = & $bashExe "$repoRoot/scripts/test-verify-i6.sh" --emit-hits $fxTmp 2>$null
        $parityOk = $true
        foreach ($name in $fxExpect.Keys) {
            $line = $bashOut | Where-Object { $_ -like "$name`t*" -or $_ -eq $name } | Select-Object -First 1
            $bashIdxs = @()
            if ($line -and $line.Contains("`t")) {
                $bashIdxs = ($line -split "`t", 2)[1] -split '[,\s]+' |
                    Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_ }
            }
            $bashNorm = ($bashIdxs | Sort-Object) -join ' '
            $psNorm = (@($psHits[$name]) | Sort-Object) -join ' '
            if ($bashNorm -ne $psNorm) {
                $parityOk = $false
                Write-Host "    divergence on ${name}: ps='$psNorm' bash='$bashNorm'" -ForegroundColor DarkRed
            }
        }
        Assert "cross-shell parity: PowerShell and bash agree on every fixture's hit set" { $parityOk }
    }

    # -----------------------------------------------------------------------
    # Assertion 3 — structural lockstep with the live verify_all scripts.
    # -----------------------------------------------------------------------
    Write-Host ""
    Write-Host "--- Assertion 3: structural lockstep with live verify_all ---" -ForegroundColor Cyan

    # verify_all.sh's i6_banned and test-verify-i6.sh's i6_banned are both bash
    # source with identical escaping — extract the record lines (source text) from
    # each and compare verbatim. test-verify-i6.sh's $i6Banned is the bash twin of
    # this driver's $i6Banned, so this transitively locks the PS array too.
    function Get-ShI6Banned($path) {
        $out = @()
        $inArr = $false
        foreach ($l in (Get-Content $path)) {
            if ($l -match '^i6_banned=\(') { $inArr = $true; continue }
            if ($inArr -and $l -match '^\)') { $inArr = $false; continue }
            if ($inArr) { $out += $l.Trim() }
        }
        $out
    }
    $liveBanned = Get-ShI6Banned "scripts/verify_all.sh"
    $selfBanned = Get-ShI6Banned "scripts/test-verify-i6.sh"
    Assert "structural lockstep: verify_all.sh i6_banned has 13 entries" {
        $liveBanned.Count -eq 13
    }
    Assert "structural lockstep: verify_all.sh i6_banned matches test-verify-i6.sh verbatim" {
        if ($liveBanned.Count -ne $selfBanned.Count) {
            throw "count mismatch: verify_all.sh=$($liveBanned.Count) test-verify-i6.sh=$($selfBanned.Count)"
        }
        for ($i = 0; $i -lt $liveBanned.Count; $i++) {
            if ($liveBanned[$i] -ne $selfBanned[$i]) {
                throw "entry #$($i+1) mismatch:`n      verify_all.sh    : $($liveBanned[$i])`n      test-verify-i6.sh: $($selfBanned[$i])"
            }
        }
        $true
    }

    # verify_all.ps1: 13 banned hashtables, entry #10 carries exclude=@('.claude/').
    $ps1Raw = Get-Content "scripts/verify_all.ps1" -Raw
    $ps1Count = ([regex]::Matches($ps1Raw, '(?m)^\s*@\{ anchors = @\(')).Count
    Assert "structural lockstep: verify_all.ps1 `$banned has 13 entries" { $ps1Count -eq 13 }
    Assert "structural lockstep: verify_all.ps1 entry #10 carries exclude=@('.claude/')" {
        $ps1Raw -match "anchors = @\('\.harness/','$([char]0x2192)','CLAUDE\.md'\); reason = [^\n]*exclude = @\('\.claude/'\)"
    }
    Assert "structural lockstep: verify_all.sh exempt-dir includes docs/features/" {
        (Get-Content "scripts/verify_all.sh" -Raw) -match '"docs/features/"'
    }
    Assert "structural lockstep: verify_all.ps1 exempt-dir includes docs/features/" {
        $ps1Raw -match '"docs/features/"'
    }

    # -----------------------------------------------------------------------
    # Assertion 4 — no-error on metacharacter/Unicode fixtures.
    # -----------------------------------------------------------------------
    Write-Host ""
    Write-Host "--- Assertion 4: no error on metacharacter/Unicode fixtures ---" -ForegroundColor Cyan
    Assert "no-error: metacharacter/Unicode fixtures scan without throwing" {
        foreach ($name in @("fx-meta-backtick.md","fx-meta-arrow.md","fx-arrow-accurate.md","fx-e11.md","fx-e12.md","fx-e13.md")) {
            $null = Scan-I6File (Join-Path $fxTmp $name)
        }
        $true
    }

    # -----------------------------------------------------------------------
    # Assertion 5 — gap boundary (AC-9).
    # -----------------------------------------------------------------------
    Write-Host ""
    Write-Host "--- Assertion 5: gap boundary ---" -ForegroundColor Cyan
    Assert "gap boundary: 40-char gap (fx-gap-exact) HITs" {
        @($psHits["fx-gap-exact.md"]).Count -gt 0
    }
    Assert "gap boundary: 41-char gap (fx-gap-over) does NOT hit" {
        @($psHits["fx-gap-over.md"]).Count -eq 0
    }

    # -----------------------------------------------------------------------
    # Assertion 6 — F-1 / F-2 / F-4 / Rev-4 regression.
    # -----------------------------------------------------------------------
    Write-Host ""
    Write-Host "--- Assertion 6: F-1 / F-2 / F-4 / Rev-4 regression ---" -ForegroundColor Cyan
    Assert "F-1: fx-negation-pre (negation before anchors) does NOT hit" {
        @($psHits["fx-negation-pre.md"]).Count -eq 0
    }
    Assert "F-4: fx-historical (concepts.md two-line layout) does NOT hit under gap=20" {
        @($psHits["fx-historical.md"]).Count -eq 0
    }
    Assert "Rev-4: fx-arrow-accurate (README repo-layout line) does NOT hit (.claude/ exclude)" {
        @($psHits["fx-arrow-accurate.md"]).Count -eq 0
    }
    Assert "F-2: docs/features/<task>/ stage-doc path is exempt from I.6" {
        Test-I6DirExempt "docs/features/some-task/03_GATE_REVIEW.md"
    }
    Assert "F-2: a non-exempt path (scripts/verify_all.ps1) is NOT dir-exempt" {
        -not (Test-I6DirExempt "scripts/verify_all.ps1")
    }

} finally {
    if (-not $KeepTemp) {
        Remove-Item -Recurse -Force $fxTmp -ErrorAction SilentlyContinue
    } else {
        Write-Host ""
        Write-Host "Fixture temp kept: $fxTmp" -ForegroundColor Yellow
    }
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

} finally {
    Pop-Location
}
