# test-verify-i6.ps1 — Regression for the verify_all I.6 gap-tolerant retired-claim matcher (v0.18.0+)
#
# PowerShell twin of test-verify-i6.sh. Mirrors the same fixture corpus + assertion set.
#
# The driver does NOT dot-source verify_all.ps1 (that would run all 30 checks). It
# re-declares the I.6 matcher predicate (regex builder + per-line scan + line-scoped
# exclude) as a self-contained function, kept in lockstep with the live script by a
# structural assertion (the live $banned array must match this driver's copy,
# including entry #10's exclude=@('.claude/')).
#
# Driver-vs-live lockstep matrix (v0.18+ T-005 hardening — both rows × both columns
# do verbatim per-entry × 4-field comparison; no cell is count-only):
#
#                    | verify_all.sh | verify_all.ps1 |
#     test-verify.sh | verbatim      | verbatim       |
#     test-verify.ps1| verbatim      | verbatim       |
#
# Usage:
#   .\.harness\scripts\test-verify-i6.ps1                  # full run, temp dir auto-cleaned
#   .\.harness\scripts\test-verify-i6.ps1 -KeepTemp        # keep the fixture temp dir
#   pwsh -File .harness/scripts/test-verify-i6.ps1 --emit-hits <dir>   # parity-helper mode:
#       prints "fixture<TAB>idx,idx" per file; used by test-verify-i6.sh's parity check.

$ErrorActionPreference = "Stop"
# Script lives at .harness/scripts/ — repo root is two levels up.
$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

# Single canonical "no value" sentinel (T-005 design §3.2 / Q-1). Used by Format-I6Field
# so an empty-string field from a bash record and a $null / @() field from a PS hashtable
# both collapse to one renderable token before the comparator runs.
$script:I6_EMPTY = '<empty>'

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

# The canonical list for I.6 exempt FILES at this driver's version. Element-wise
# equality against verify_all.{ps1,sh} is asserted by Assertion 3c (T-005 §3.5).
$i6ExemptFiles = @(
    "CHANGELOG.md",
    "architecture.html",
    "docs/walkthrough.html",
    ".harness/scripts/verify_all.ps1",
    ".harness/scripts/verify_all.sh",
    ".harness/scripts/test-verify-i6.ps1",
    ".harness/scripts/test-verify-i6.sh"
)
# Single source of truth for the banned-list entry count. Bumping to 14 = edit here
# AND in test-verify-i6.sh's i6_expected_entry_count.
$script:I6ExpectedEntryCount = 13

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

# Test-I6FileExempt PATH — byte-mirror of verify_all.ps1's inline `$exempt -contains $file`
# membership test. `-ccontains` is MANDATORY (insight L7): default `-contains` is
# case-insensitive and would return $true for CHANGELOG.MD vs CHANGELOG.md, masking
# a future casing-drift bug between PS and bash.
function Test-I6FileExempt($p) {
    return ($i6ExemptFiles -ccontains $p)
}

# Combined predicate used by Assertion 7 (AC-12 / AC-13): file-exempt OR dir-exempt.
# Mirrors the live verify_all.ps1 skip order at lines 528-531.
function Test-I6Exempt($p) {
    if (Test-I6FileExempt $p) { return $true }
    return (Test-I6DirExempt $p)
}

# Format-I6Field VALUE — normalize a field value (string / array / $null) into a
# single renderable canonical token. Empty / $null / @() all collapse to $script:I6_EMPTY.
# Arrays render as `~`-joined to match the bash record format (T-005 §3.2 / Q-1).
function Format-I6Field($value) {
    if ($null -eq $value) { return $script:I6_EMPTY }
    if ($value -is [array]) {
        if ($value.Count -eq 0) { return $script:I6_EMPTY }
        return ($value -join '~')
    }
    # String / int / other scalar
    $s = [string]$value
    if ($s -eq '') { return $script:I6_EMPTY }
    return $s
}

# Test-I6FieldEq A B — the ONLY new comparator in the lockstep code. `-ceq` is
# MANDATORY (insight L7/L17/L20/L23 — default `-eq` is case-insensitive and would
# mojibake-mask a CJK-vs-mojibake mismatch).
function Test-I6FieldEq($a, $b) {
    return ((Format-I6Field $a) -ceq (Format-I6Field $b))
}

# Get-ShI6BannedRecords PATH -> array of [pscustomobject] with properties
# (anchors[], reason, exclude[], gap). Parses verify_all.sh's i6_banned source text
# (T-005 §3.3 / Q-2). No bash invocation — pure PS text walk.
#
# Backtick-decode (R-1 / insight L19): bash double-quoted strings escape the literal
# backtick as `\``. The PS array source uses single-quoted strings with literal `,
# so both sides must decode to the same canonical token. The replace below uses a
# single-quoted regex literal so PS does not interpret the backslash-backtick.
function Get-ShI6BannedRecords($path) {
    $out = @()
    $inArr = $false
    $rawIdx = 0
    foreach ($l in (Get-Content -LiteralPath $path -Encoding UTF8)) {
        if ($l -cmatch '^i6_banned=\(') { $inArr = $true; continue }
        if ($inArr -and $l -cmatch '^\)') { $inArr = $false; continue }
        if (-not $inArr) { continue }
        $line = $l.Trim()
        if ($line -eq '') { continue }
        $rawIdx++
        # Peel one leading `"` and one trailing `"` (literal bash double-quote wrapper).
        if ($line.StartsWith('"') -and $line.EndsWith('"')) {
            $line = $line.Substring(1, $line.Length - 2)
        }
        # Decode `\`` -> `` ` `` (entries #2, #6, #8 carry the backtick anchor).
        $decoded = $line -replace '\\`', '`'
        # PS `-split` on a regex with no limit preserves trailing empty fields by
        # default (verified: "a|b||" -> 4 parts). A `-1` limit would NOT split at
        # all, which is the opposite of what we want.
        $parts = $decoded -split '\|'
        if ($parts.Count -ne 4) {
            throw "Get-ShI6BannedRecords: entry #$rawIdx has $($parts.Count) fields (expected 4): raw=$l"
        }
        $anchors = if ($parts[0] -eq '') { @() } else { $parts[0] -split '~' }
        $exclude = if ($parts[2] -eq '') { @() } else { $parts[2] -split '~' }
        $out += [pscustomobject]@{
            anchors = [string[]]$anchors
            reason  = [string]$parts[1]
            exclude = [string[]]$exclude
            gap     = [string]$parts[3]
        }
    }
    return ,$out
}

# Get-Ps1BannedRecords PATH -> the same shape as Get-ShI6BannedRecords, but parsed
# from verify_all.ps1's $banned source text. The parser is line-anchored on the
# literal `@{ anchors = @(` opener (R-2 mitigation: don't depend on column position).
# A future innocent line-wrap of a record fails closed (count != 13).
function Get-Ps1BannedRecords($path) {
    $out = @()
    $raw = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    $rawIdx = 0
    foreach ($l in ($raw -split "`r?`n")) {
        if ($l -cnotmatch '^\s*@\{\s*anchors\s*=\s*@\(') { continue }
        $rawIdx++
        # Extract each field by literal-keyword regex (whitespace-tolerant before
        # the keyword and between `=` operators).
        $anchorsRaw = $null; $reason = $null; $excludeRaw = $null; $gap = $null
        if ($l -cmatch "anchors\s*=\s*@\(([^)]*)\)") { $anchorsRaw = $Matches[1] }
        if ($l -cmatch 'reason\s*=\s*"([^"]*)"')      { $reason     = $Matches[1] }
        if ($l -cmatch "exclude\s*=\s*@\(([^)]*)\)") { $excludeRaw = $Matches[1] }
        if ($l -cmatch 'gap\s*=\s*(\$null|\d+)')     { $gap        = $Matches[1] }
        if ($null -eq $anchorsRaw -or $null -eq $reason -or $null -eq $excludeRaw -or $null -eq $gap) {
            throw "Get-Ps1BannedRecords: entry #$rawIdx field-extract failed: raw=$l"
        }
        # Split `'tok1','tok2',...` -> ('tok1','tok2'); strip whitespace and the surrounding
        # single quotes. Empty list ('@()') yields an empty array.
        $parseList = {
            param($body)
            $t = $body.Trim()
            if ($t -eq '') { return @() }
            $items = $t -split ','
            $r = @()
            foreach ($it in $items) {
                $s = $it.Trim()
                if ($s.StartsWith("'") -and $s.EndsWith("'")) {
                    $s = $s.Substring(1, $s.Length - 2)
                }
                $r += $s
            }
            return ,$r
        }
        $anchors = & $parseList $anchorsRaw
        $exclude = & $parseList $excludeRaw
        # Normalize `$null` (the PS literal token) to the empty-sentinel via a blank string —
        # Format-I6Field will collapse it to <empty>.
        $gapNorm = if ($gap -ceq '$null') { '' } else { $gap }
        $out += [pscustomobject]@{
            anchors = [string[]]$anchors
            reason  = [string]$reason
            exclude = [string[]]$exclude
            gap     = [string]$gapNorm
        }
    }
    return ,$out
}

# Get-ShI6ExemptFiles PATH -> ordered string[] of the i6_exempt_files entries in
# verify_all.sh. Extracts the array block, peels the surrounding double quotes.
function Get-ShI6ExemptFiles($path) {
    $out = @()
    $inArr = $false
    foreach ($l in (Get-Content -LiteralPath $path -Encoding UTF8)) {
        if ($l -cmatch '^i6_exempt_files=\(') { $inArr = $true; continue }
        if ($inArr -and $l -cmatch '^\)') { $inArr = $false; continue }
        if (-not $inArr) { continue }
        $line = $l.Trim()
        if ($line -eq '') { continue }
        if ($line.StartsWith('"') -and $line.EndsWith('"')) {
            $line = $line.Substring(1, $line.Length - 2)
        }
        $out += $line
    }
    return ,$out
}

# Get-ShI6ExemptDirs PATH -> ordered string[] of i6_exempt_dirs from verify_all.sh.
function Get-ShI6ExemptDirs($path) {
    $out = @()
    $inArr = $false
    foreach ($l in (Get-Content -LiteralPath $path -Encoding UTF8)) {
        if ($l -cmatch '^i6_exempt_dirs=\(') { $inArr = $true; continue }
        if ($inArr -and $l -cmatch '^\)') { $inArr = $false; continue }
        if (-not $inArr) { continue }
        $line = $l.Trim()
        if ($line -eq '') { continue }
        if ($line.StartsWith('"') -and $line.EndsWith('"')) {
            $line = $line.Substring(1, $line.Length - 2)
        }
        $out += $line
    }
    return ,$out
}

# Get-Ps1ExemptList PATH ARRAY_NAME -> ordered string[] of a `$<ArrayName> = @(...)`
# block in verify_all.ps1. Used for both $exempt (files) and $exemptDirs.
function Get-Ps1ExemptList($path, $arrayName) {
    $out = @()
    $raw = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    $opener = '\$' + [regex]::Escape($arrayName) + '\s*=\s*@\('
    $pattern = "(?s)$opener(.*?)\)"
    $m = [regex]::Match($raw, $pattern)
    if (-not $m.Success) { return ,$out }
    $body = $m.Groups[1].Value
    foreach ($tok in ($body -split ',')) {
        $s = $tok.Trim().TrimEnd(',').Trim()
        if ($s -eq '') { continue }
        if ($s.StartsWith('"') -and $s.EndsWith('"')) {
            $s = $s.Substring(1, $s.Length - 2)
        } elseif ($s.StartsWith("'") -and $s.EndsWith("'")) {
            $s = $s.Substring(1, $s.Length - 2)
        }
        $out += $s
    }
    return ,$out
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
    # AC-14 negative-regression fixture (T-005 §6): a banned-phrase file at a
    # non-exempt path inside the temp dir. The matcher MUST report a hit; if the
    # exemption predicate ever returns $true for all paths (a future-bug scenario),
    # this fixture flips first.
    & $w "fx-ac14-nonexempt.md" "harness-sync regenerates CLAUDE.md"
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
        $bashOut = & $bashExe "$repoRoot/.harness/scripts/test-verify-i6.sh" --emit-hits $fxTmp 2>$null
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
    # T-005 split: 3a = verify_all.sh banned-list, 3b = verify_all.ps1 banned-list,
    # 3c = exempt-file + exempt-dir lockstep. All four-field verbatim, both shells.
    # -----------------------------------------------------------------------
    Write-Host ""
    Write-Host "--- Assertion 3: structural lockstep with live verify_all ---" -ForegroundColor Cyan

    # Parse both sources into the same canonical 4-tuple shape, then per-entry
    # × 4-field equality through Test-I6FieldEq.
    $shLiveRecs   = Get-ShI6BannedRecords ".harness/scripts/verify_all.sh"
    $ps1LiveRecs  = Get-Ps1BannedRecords  ".harness/scripts/verify_all.ps1"
    # Driver's own canonical = the $i6Banned hashtable array declared above. Project
    # it into the same canonical shape.
    $driverRecs = @()
    foreach ($b in $i6Banned) {
        $driverRecs += [pscustomobject]@{
            anchors = [string[]]$b.anchors
            reason  = [string]$b.reason
            exclude = [string[]]($b.exclude)
            gap     = if ($null -eq $b.gap) { '' } else { [string]$b.gap }
        }
    }

    # ----- 3a — verify_all.sh i6_banned vs driver -----
    Assert "structural lockstep: verify_all.sh i6_banned entry count equals I6ExpectedEntryCount" {
        if ($shLiveRecs.Count -ne $script:I6ExpectedEntryCount) {
            throw "verify_all.sh i6_banned has $($shLiveRecs.Count) entries, expected $($script:I6ExpectedEntryCount)"
        }
        $true
    }
    Assert "structural lockstep: verify_all.sh i6_banned matches driver verbatim (per-entry x 4 fields)" {
        if ($shLiveRecs.Count -ne $driverRecs.Count) {
            throw "count mismatch: verify_all.sh=$($shLiveRecs.Count) driver=$($driverRecs.Count)"
        }
        for ($i = 0; $i -lt $shLiveRecs.Count; $i++) {
            $live = $shLiveRecs[$i]; $self = $driverRecs[$i]
            foreach ($f in @('anchors','reason','exclude','gap')) {
                if (-not (Test-I6FieldEq $live.$f $self.$f)) {
                    throw "entry #$($i+1) field $f mismatch: live=$(Format-I6Field $live.$f) driver=$(Format-I6Field $self.$f)"
                }
            }
        }
        $true
    }

    # ----- 3b — verify_all.ps1 `$banned vs driver -----
    Assert "structural lockstep: verify_all.ps1 `$banned entry count equals I6ExpectedEntryCount" {
        if ($ps1LiveRecs.Count -ne $script:I6ExpectedEntryCount) {
            throw "verify_all.ps1 `$banned has $($ps1LiveRecs.Count) entries, expected $($script:I6ExpectedEntryCount)"
        }
        $true
    }
    Assert "structural lockstep: verify_all.ps1 `$banned matches driver verbatim (per-entry x 4 fields)" {
        if ($ps1LiveRecs.Count -ne $driverRecs.Count) {
            throw "count mismatch: verify_all.ps1=$($ps1LiveRecs.Count) driver=$($driverRecs.Count)"
        }
        for ($i = 0; $i -lt $ps1LiveRecs.Count; $i++) {
            $live = $ps1LiveRecs[$i]; $self = $driverRecs[$i]
            foreach ($f in @('anchors','reason','exclude','gap')) {
                if (-not (Test-I6FieldEq $live.$f $self.$f)) {
                    throw "entry #$($i+1) field $f mismatch: live=$(Format-I6Field $live.$f) driver=$(Format-I6Field $self.$f)"
                }
            }
        }
        $true
    }

    # ----- 3c — exempt-file + exempt-dir lockstep, element-wise -----
    $shExemptFiles  = Get-ShI6ExemptFiles ".harness/scripts/verify_all.sh"
    $shExemptDirs   = Get-ShI6ExemptDirs  ".harness/scripts/verify_all.sh"
    $ps1ExemptFiles = Get-Ps1ExemptList   ".harness/scripts/verify_all.ps1" "exempt"
    $ps1ExemptDirs  = Get-Ps1ExemptList   ".harness/scripts/verify_all.ps1" "exemptDirs"

    $compareList = {
        param($live, $canonical, $label)
        if ($live.Count -ne $canonical.Count) {
            throw "$label count mismatch: live=$($live.Count) canonical=$($canonical.Count)"
        }
        for ($i = 0; $i -lt $live.Count; $i++) {
            if (-not ($live[$i] -ceq $canonical[$i])) {
                throw "$label element #$($i+1) mismatch: live='$($live[$i])' canonical='$($canonical[$i])'"
            }
        }
        $true
    }

    Assert "exempt-file lockstep: verify_all.ps1 `$exempt equals canonical (element-wise)" {
        & $compareList $ps1ExemptFiles $i6ExemptFiles "verify_all.ps1 `$exempt"
    }
    Assert "exempt-file lockstep: verify_all.sh i6_exempt_files equals canonical (element-wise)" {
        & $compareList $shExemptFiles $i6ExemptFiles "verify_all.sh i6_exempt_files"
    }
    Assert "exempt-dir lockstep: verify_all.ps1 `$exemptDirs equals canonical (element-wise)" {
        & $compareList $ps1ExemptDirs $i6ExemptDirs "verify_all.ps1 `$exemptDirs"
    }
    Assert "exempt-dir lockstep: verify_all.sh i6_exempt_dirs equals canonical (element-wise)" {
        & $compareList $shExemptDirs $i6ExemptDirs "verify_all.sh i6_exempt_dirs"
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
    Assert "F-2: a non-exempt path (.harness/scripts/verify_all.ps1) is NOT dir-exempt" {
        -not (Test-I6DirExempt ".harness/scripts/verify_all.ps1")
    }

    # -----------------------------------------------------------------------
    # Assertion 7 — AC-8 permanent fixture coverage (T-005 §3.6 / §8).
    # File-exempt predicate, dir-exempt fixture path, combined predicate, and
    # AC-14 negative-regression on a real file at a non-exempt path.
    # -----------------------------------------------------------------------
    Write-Host ""
    Write-Host "--- Assertion 7: AC-8 permanent fixture coverage ---" -ForegroundColor Cyan

    # 7.1 file-exempt predicate positive corpus — every canonical exempt path is exempt.
    foreach ($exemptPath in $i6ExemptFiles) {
        Assert "file-exempt predicate: $exemptPath is reported exempt" {
            Test-I6FileExempt $exemptPath
        }
    }

    # 7.2 file-exempt predicate negative corpus — three known non-exempt paths.
    $negFileCorpus = @("README.md", "docs/concepts.md", ".harness/scripts/harness-sync.sh")
    foreach ($nonExempt in $negFileCorpus) {
        Assert "file-exempt predicate: $nonExempt is NOT reported exempt" {
            -not (Test-I6FileExempt $nonExempt)
        }
    }

    # 7.3 combined predicate vs dir-exempt synthetic path (AC-12).
    Assert "combined exempt: docs/features/some-task/03_GATE_REVIEW.md skipped (dir-exempt)" {
        Test-I6Exempt "docs/features/some-task/03_GATE_REVIEW.md"
    }

    # 7.4 combined predicate vs every canonical exempt-file path (AC-13).
    foreach ($exemptPath in $i6ExemptFiles) {
        Assert "combined exempt: $exemptPath skipped (file-exempt)" {
            Test-I6Exempt $exemptPath
        }
    }

    # 7.5 AC-14 negative regression — physical file at non-exempt path with banned
    # content MUST hit. This guards against a future bug that makes the exemption
    # predicate return $true for all paths.
    Assert "AC-14 negative regression: non-exempt fixture with banned content HITs" {
        $hits = @(Scan-I6File (Join-Path $fxTmp "fx-ac14-nonexempt.md"))
        $hits.Count -gt 0
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
