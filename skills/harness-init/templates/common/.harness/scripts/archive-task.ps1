# archive-task.ps1 — Archive a completed task: harvest insights, move stage docs.
# Mirror of archive-task.sh.
#
# Usage:
#   pwsh -File .harness/scripts/archive-task.ps1 -Task <task-slug>
#   pwsh -File .harness/scripts/archive-task.ps1 -Task <task-slug> -DryRun
#
# What it does:
#   1. Find docs/features/<task-slug>/
#   2. For EVERY '## Insight' (or '## Insights') section in 07_DELIVERY.md that is
#      not inside a fenced code block, append its insight ENTRIES — each bullet
#      line plus every continuation line wrapped under it — to
#      .harness/insight-index.md.
#   3. Move docs/features/<task-slug>/ -> docs/features/_archived/<task-slug>/
#   4. If .harness/insight-index.md exceeds 30 insight ENTRIES, rotate the oldest
#      entries (all their lines) to docs/features/_archived/insight-history.md.
#
# Never deletes. Only moves and appends. Exit 3 = a line inside the harvested
# section or inside the stored index could not be classified; nothing is written.
#
# PowerShell hazard notes (this file is NOT agent-executable — insight
# 2026-06-21): PS parses the WHOLE file before executing, so a syntax error in a
# never-taken branch is fatal to the file; new variables carry an `at` prefix so
# none can collide with a read-only automatic such as $IsWindows; every binary
# `-join` is fully parenthesised before it meets a `+` (binary -join binds BELOW
# +); every multi-part message is built with -f.

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Task,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
# Script lives at .harness/scripts/ — repo root is two levels up.
$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

$taskDir = Join-Path $repoRoot "docs/features/$Task"
$archivedRoot = Join-Path $repoRoot "docs/features/_archived"
$archivedTaskDir = Join-Path $archivedRoot $Task
$insightIndex = Join-Path $repoRoot ".harness/insight-index.md"
$insightHistory = Join-Path $archivedRoot "insight-history.md"

# ---------------------------------------------------------------------------
# INSIGHT-SCAN — the single entry-boundary algorithm, used for the delivery
# section AND for the stored index (T-20 / 02_SOLUTION_DESIGN.md §C).
#
# MATCHER REGISTER: every pattern below is evaluated by the .NET regex engine
# only. `\s` is the sole whitespace spelling permitted here; `[ \t]` inside a
# bracket expression is banned in both twins (insight 2026-08-01).
# ---------------------------------------------------------------------------
$atReEntry = '^\s*-\s+'
$atReBlank = '^\s*$'
$atReBreak = '^\s{0,3}(-{3,}|\*{3,}|_{3,})\s*$'
$atReHeading = '^#{2,6}\s'
$atReSectionHead = '^##\s+Insights?\s*$'
$atReSectionEnd = '^##\s'
# A fenced code block opener/closer: 0-3 leading spaces then >= 3 backticks or
# >= 3 tildes. Group 1 is the marker run, group 2 the rest of the line (the info
# string on an opener; it must be blank on a closer). The backticks are literal
# here because PowerShell does NOT process a backtick inside a single-quoted
# string — do not retype this literal into a double-quoted one.
$atReFence = '^\s{0,3}((?:`{3,})|(?:~{3,}))(.*)$'

# Strip ALL trailing whitespace (a CR included, so a CRLF document needs no
# special case) and leave leading whitespace untouched. .TrimEnd() only —
# .Trim() is forbidden anywhere in the harvest path, it eats leading indent.
function Get-NormalisedLines {
    param([AllowEmptyCollection()][AllowNull()][string[]]$AtRaw)
    $atOut = [System.Collections.Generic.List[string]]::new()
    if ($null -ne $AtRaw) {
        foreach ($atLine in $AtRaw) { $atOut.Add($atLine.TrimEnd()) }
    }
    return , $atOut.ToArray()
}

# Invoke-InsightScan -AtLines <array> -AtMode section|index -AtLo n -AtHi n
#   $AtLo/$AtHi are 0-based inclusive offsets; $AtHi < $AtLo is an empty range.
function Invoke-InsightScan {
    param(
        [AllowEmptyCollection()][AllowNull()][string[]]$AtLines,
        [string]$AtMode,
        [int]$AtLo,
        [int]$AtHi
    )

    $atKind = @{}
    $atELo = [System.Collections.Generic.List[int]]::new()
    $atEHi = [System.Collections.Generic.List[int]]::new()
    $atUnaccounted = [System.Collections.Generic.List[int]]::new()
    $atHdrEnd = $AtLo - 1
    $atOpenAt = -1
    $atCommentAt = -1
    $atCs = $false
    $atStopped = $false
    $atInEntry = $false
    $atSeenEntry = $false
    $atCont = 0
    $atIgn = 0
    $atFooter = 0

    # --- Pass A — header block (mode 'index' only) -------------------------
    # Comment state is a FIXED-STRING scan registered with no regex engine:
    # every '<!--' sets it true and every '-->' sets it false, in left-to-right
    # occurrence order (the token-TYPE reading — a second '<!--' inside an open
    # comment is idempotent, '<!-- x --> <!--' ends open). An entry-start line
    # inside an open comment does NOT end the header block, which keeps the
    # shipped insight-index.md.tmpl example line out of the entry set.
    if ($AtMode -eq 'index') {
        for ($atI = $AtLo; $atI -le $AtHi; $atI++) {
            $atLine = $AtLines[$atI]
            if ((-not $atCs) -and ($atLine -match $atReEntry)) {
                $atHdrEnd = $atI - 1
                $atStopped = $true
                break
            }
            $atRest = $atLine
            while ($atRest.Length -gt 0) {
                $atPosOpen = $atRest.IndexOf('<!--')
                $atPosClose = $atRest.IndexOf('-->')
                if (($atPosOpen -lt 0) -and ($atPosClose -lt 0)) { break }
                if (($atPosOpen -ge 0) -and (($atPosClose -lt 0) -or ($atPosOpen -lt $atPosClose))) {
                    $atCs = $true
                    $atCommentAt = $atI
                    $atRest = $atRest.Substring($atPosOpen + 4)
                } else {
                    $atCs = $false
                    $atRest = $atRest.Substring($atPosClose + 3)
                }
            }
        }
        if (-not $atStopped) {
            $atHdrEnd = $AtHi
            # A comment still OPEN at EOF swallows the whole file into the
            # header block, so every stored entry would read as 0 and every
            # later harvest would be appended INSIDE the comment, silently, at
            # exit 0. Report the opening line as UNACCOUNTED so this refuses
            # here and WARNs in verify_all I.4 instead of corrupting the index.
            if ($atCs) { $atOpenAt = $atCommentAt }
        }
    }

    # --- Pass B — kinds ----------------------------------------------------
    for ($atI = $AtLo; $atI -le $AtHi; $atI++) {
        $atLine = $AtLines[$atI]
        if (($AtMode -eq 'index') -and ($atI -le $atHdrEnd)) {
            $atKind[$atI] = 'I'; $atInEntry = $false; continue
        }
        if ($atLine -match $atReBlank) {
            $atKind[$atI] = 'I'; $atInEntry = $false; continue
        }
        if ($atLine -match $atReEntry) {
            $atKind[$atI] = 'E'
            $atELo.Add($atI)
            $atEHi.Add($atI)
            $atInEntry = $true
            $atSeenEntry = $true
            continue
        }
        if (($AtMode -eq 'section') -and (-not $atSeenEntry)) {
            $atKind[$atI] = 'I'; $atInEntry = $false; continue
        }
        # A '##'/'###'... heading line is NEVER a continuation. It terminates
        # the open entry and is UNACCOUNTED, in BOTH modes — so a heading that
        # drifts into an index or under a bullet is refused loudly instead of
        # being absorbed into an entry and rotated into insight-history.md.
        if ($atLine -match $atReHeading) {
            $atKind[$atI] = 'U'; $atInEntry = $false; continue
        }
        if ($atInEntry) {
            $atKind[$atI] = 'C'
            $atEHi[$atEHi.Count - 1] = $atI
            continue
        }
        $atKind[$atI] = 'U'
    }

    # --- Pass C — terminal footer (mode 'section' only) --------------------
    if (($AtMode -eq 'section') -and ($atEHi.Count -gt 0)) {
        $atE = $atEHi[$atEHi.Count - 1]
        $atF = -1
        for ($atI = $atE + 1; $atI -le $AtHi; $atI++) {
            if ($AtLines[$atI] -match $atReBreak) { $atF = $atI; break }
        }
        if ($atF -ge 0) {
            for ($atI = $atF; $atI -le $AtHi; $atI++) {
                # Pass C can only demote UNACCOUNTED -> ignorable. An
                # entry-start or continuation line is never made ignorable here
                # — enforced literally, not by convention.
                if ($atKind[$atI] -eq 'U') { $atKind[$atI] = 'I' }
                $atFooter = $atFooter + 1
            }
        }
    }

    if ($atOpenAt -ge 0) { $atKind[$atOpenAt] = 'U' }

    for ($atI = $AtLo; $atI -le $AtHi; $atI++) {
        if ($atKind[$atI] -eq 'I') { $atIgn = $atIgn + 1 }
        elseif ($atKind[$atI] -eq 'C') { $atCont = $atCont + 1 }
        elseif ($atKind[$atI] -eq 'U') { $atUnaccounted.Add($atI) }
    }

    return @{
        HeaderEnd     = $atHdrEnd
        EntryLo       = $atELo
        EntryHi       = $atEHi
        Entries       = $atELo.Count
        Continuation  = $atCont
        Ignorable     = $atIgn
        Footer        = $atFooter
        Unaccounted   = $atUnaccounted
        OpenCommentAt = $atOpenAt
    }
}

# LF, no BOM, on both harvest targets. Set-Content / Add-Content are forbidden
# on the index and the history file: they emit [Environment]::NewLine, which is
# CRLF on Windows and breaks byte-identity with the bash twin.
function Write-InsightFile {
    param(
        [string]$AtPath,
        [AllowEmptyCollection()][AllowNull()][string[]]$AtBody,
        [switch]$AtAppend
    )
    $atText = ''
    if (($null -ne $AtBody) -and ($AtBody.Count -gt 0)) {
        $atText = ($AtBody -join "`n") + "`n"
    }
    $atEnc = [System.Text.UTF8Encoding]::new($false)
    if ($AtAppend) {
        [System.IO.File]::AppendAllText($AtPath, $atText, $atEnc)
    } else {
        [System.IO.File]::WriteAllText($AtPath, $atText, $atEnc)
    }
}

if (-not (Test-Path $taskDir)) {
    Write-Error "Task directory not found: $taskDir"
    exit 1
}

if (Test-Path $archivedTaskDir) {
    Write-Error "Task already archived: $archivedTaskDir"
    exit 1
}

# Step 1: harvest insight ENTRIES from 07_DELIVERY.md (if present)
$deliveryFile = Join-Path $taskDir "07_DELIVERY.md"
$atDiag = [System.Collections.Generic.List[string]]::new()
$atHarvest = [System.Collections.Generic.List[string]]::new()
$atHEntries = 0
$atHCont = 0
$atHIgn = 0
$atHFooter = 0
$atHUnacc = 0
$atHQuoted = 0
if (Test-Path $deliveryFile) {
    # Get-Content walks the LINE ARRAY and strips both \n and \r\n terminators,
    # and it KEEPS an unterminated final line. Get-Content -Raw + -split "`n"
    # would leave a CR residue that .Trim() then hid.
    $atRaw = $null
    try {
        $atRaw = @(Get-Content -Path $deliveryFile)
    } catch {
        [Console]::Error.WriteLine(('Delivery document not readable: {0}' -f $deliveryFile))
        exit 1
    }
    $atDLines = Get-NormalisedLines -AtRaw $atRaw
    $atDN = $atDLines.Count
    # --- SECTION DISCOVERY -------------------------------------------------
    # ALL matching headings open a section and EVERY one of them is harvested.
    # Scanning only the first (and breaking) silently discarded every later
    # '## Insight' section at exit 0.
    #
    # A heading inside a FENCED CODE BLOCK is not a heading, and a '##' inside
    # one does not terminate a section: a document *about* this section quotes
    # the heading, and reading the quote as the section harvests documentation
    # while (pre-fix) hiding the real section entirely. Fence state is tracked
    # over the whole document, in one walk, for both the opener and the
    # terminator, so the two can never disagree about where a section is.
    $atSecLo = [System.Collections.Generic.List[int]]::new()
    $atSecHi = [System.Collections.Generic.List[int]]::new()
    $atFenceChar = ''
    $atFenceLen = 0
    $atFenceAt = -1
    $atCurLo = -1
    for ($atI = 0; $atI -lt $atDN; $atI++) {
        $atLine = $atDLines[$atI]
        $atFm = [regex]::Match($atLine, $atReFence)
        if ($atFm.Success) {
            $atMark = $atFm.Groups[1].Value
            $atInfo = $atFm.Groups[2].Value
            if ($atFenceChar -eq '') {
                # CommonMark: a backtick fence's info string may hold no backtick.
                if (($atMark.Substring(0, 1) -ne '`') -or (-not $atInfo.Contains('`'))) {
                    $atFenceChar = $atMark.Substring(0, 1)
                    $atFenceLen = $atMark.Length
                    $atFenceAt = $atI
                }
            } elseif (($atMark.Substring(0, 1) -eq $atFenceChar) -and ($atMark.Length -ge $atFenceLen) -and ($atInfo -match $atReBlank)) {
                $atFenceChar = ''
                $atFenceLen = 0
                $atFenceAt = -1
            }
            continue
        }
        if ($atFenceChar -ne '') {
            # Skipping a quoted heading is a DECISION, not a silence: count it
            # so the run reports it. A '## Insight' inside a fence is normal in
            # a document about this section, but "we ignored a heading" must
            # never be inferable only from a missing entry.
            if ($atLine -match $atReSectionHead) { $atHQuoted = $atHQuoted + 1 }
            continue
        }
        if ($atLine -match $atReSectionHead) {
            if ($atCurLo -ge 0) { $atSecLo.Add($atCurLo); $atSecHi.Add($atI - 1) }
            $atCurLo = $atI + 1
            continue
        }
        if (($atLine -match $atReSectionEnd) -and ($atCurLo -ge 0)) {
            $atSecLo.Add($atCurLo)
            $atSecHi.Add($atI - 1)
            $atCurLo = -1
        }
    }
    if ($atCurLo -ge 0) { $atSecLo.Add($atCurLo); $atSecHi.Add($atDN - 1) }
    # A fence still OPEN at EOF hides every heading after it, so a real section
    # can vanish at exit 0. Report the opening line and refuse — the same
    # treatment the index's unbalanced '<!--' gets, for the same reason.
    if ($atFenceAt -ge 0) {
        $atDiag.Add(('{0}:{1}: unterminated code fence opened here: {2}' -f $deliveryFile, ($atFenceAt + 1), $atDLines[$atFenceAt]))
        $atHUnacc = $atHUnacc + 1
    }
    for ($atS = 0; $atS -lt $atSecLo.Count; $atS++) {
        $atSec = Invoke-InsightScan -AtLines $atDLines -AtMode 'section' -AtLo $atSecLo[$atS] -AtHi $atSecHi[$atS]
        $atHEntries = $atHEntries + $atSec.Entries
        $atHCont = $atHCont + $atSec.Continuation
        $atHIgn = $atHIgn + $atSec.Ignorable
        $atHFooter = $atHFooter + $atSec.Footer
        $atHUnacc = $atHUnacc + $atSec.Unaccounted.Count
        for ($atE = 0; $atE -lt $atSec.Entries; $atE++) {
            for ($atI = $atSec.EntryLo[$atE]; $atI -le $atSec.EntryHi[$atE]; $atI++) {
                $atHarvest.Add($atDLines[$atI])
            }
        }
        foreach ($atU in $atSec.Unaccounted) {
            $atDiag.Add(('{0}:{1}: unaccounted line: {2}' -f $deliveryFile, ($atU + 1), $atDLines[$atU]))
        }
    }
}

if ($atHEntries -gt 0) {
    Write-Host ('Harvested {0} insight entry(ies) from 07_DELIVERY.md:' -f $atHEntries) -ForegroundColor Cyan
    foreach ($atLine in $atHarvest) { Write-Host ('  {0}' -f $atLine) -ForegroundColor DarkGray }
}

# Step 2: read the stored index and rotate it if it would exceed 30 ENTRIES
if (-not (Test-Path $insightIndex)) {
    Write-Warning ".harness/insight-index.md missing — creating empty"
}

$atILines = @()
if (Test-Path $insightIndex) {
    $atILines = Get-NormalisedLines -AtRaw @(Get-Content -Path $insightIndex)
}
$atIdx = Invoke-InsightScan -AtLines $atILines -AtMode 'index' -AtLo 0 -AtHi ($atILines.Count - 1)
$atIdxEntries = $atIdx.Entries
$atIdxUnacc = $atIdx.Unaccounted.Count
$atHeader = [System.Collections.Generic.List[string]]::new()
for ($atI = 0; $atI -le $atIdx.HeaderEnd; $atI++) { $atHeader.Add($atILines[$atI]) }
foreach ($atU in $atIdx.Unaccounted) {
    if (($atIdx.OpenCommentAt -ge 0) -and ($atU -eq $atIdx.OpenCommentAt)) {
        $atDiag.Add(('{0}:{1}: unterminated HTML comment opened here: {2}' -f $insightIndex, ($atU + 1), $atILines[$atU]))
    } else {
        $atDiag.Add(('{0}:{1}: unaccounted line: {2}' -f $insightIndex, ($atU + 1), $atILines[$atU]))
    }
}

$atTotalAfter = $atIdxEntries + $atHEntries
$atRotateCount = 0
$atRefusing = ($atHUnacc -gt 0) -or ($atIdxUnacc -gt 0)
if ((-not $atRefusing) -and ($atTotalAfter -gt 30)) {
    $atRotateCount = $atTotalAfter - 30
    # Clamp: never read past the end of the stored entry list.
    if ($atRotateCount -gt $atIdxEntries) { $atRotateCount = $atIdxEntries }
}
$atIndexAfter = $atIdxEntries - $atRotateCount + $atHEntries
if ($atRefusing) { $atIndexAfter = $atIdxEntries }

# The tally prints on EVERY terminating path, refusal included, so an echo that
# looks complete can never accompany discarded content.
Write-Host ('Insight tally: entries {0}, continuation lines {1}, ignorable lines {2} (terminal footer {3}), unaccounted lines {4}' -f $atHEntries, $atHCont, $atHIgn, $atHFooter, $atHUnacc)
if ($atHQuoted -gt 0) {
    Write-Host ("Quoted headings: {0} '## Insight' heading(s) inside a code fence were not harvested" -f $atHQuoted)
}
Write-Host ('Index tally: entries {0}, unaccounted lines {1}, entries after run {2}' -f $atIdxEntries, $atIdxUnacc, $atIndexAfter)

if ($atRefusing) {
    [Console]::Error.WriteLine(('archive-task: refusing to harvest — {0} unclassifiable line(s); nothing written.' -f ($atHUnacc + $atIdxUnacc)))
    foreach ($atD in $atDiag) { [Console]::Error.WriteLine(('  {0}' -f $atD)) }
    exit 3
}

if ($atRotateCount -gt 0) {
    Write-Host ('Rotating {0} old insight entry(ies) to insight-history.md' -f $atRotateCount) -ForegroundColor Yellow
}

# --- write phase: nothing above this line creates, writes, appends or moves ---
if ((-not $DryRun) -and (-not (Test-Path $insightIndex))) {
    New-Item -ItemType File -Path $insightIndex -Force | Out-Null
}

if ($atTotalAfter -gt 30) {
    if (-not $DryRun) {
        if (-not (Test-Path $archivedRoot)) { New-Item -ItemType Directory -Path $archivedRoot -Force | Out-Null }
        if ($atRotateCount -gt 0) {
            if (-not (Test-Path $insightHistory)) {
                Write-InsightFile -AtPath $insightHistory -AtBody @('# Insight history (rotated from .harness/insight-index.md)', '')
            }
            $atBlock = [System.Collections.Generic.List[string]]::new()
            $atBlock.Add('')
            $atBlock.Add(('## Rotated {0}' -f (Get-Date -Format 'yyyy-MM-dd')))
            $atBlock.Add('')
            for ($atE = 0; $atE -lt $atRotateCount; $atE++) {
                for ($atI = $atIdx.EntryLo[$atE]; $atI -le $atIdx.EntryHi[$atE]; $atI++) {
                    $atBlock.Add($atILines[$atI])
                }
            }
            Write-InsightFile -AtPath $insightHistory -AtBody $atBlock.ToArray() -AtAppend
        }
        # Rewrite: header block verbatim and FIRST, then retained entries in
        # their original order, then the harvested entries. The header comes
        # from the pass-A range, never from filtering the file for non-bullet
        # lines — that filter is what hoisted stray lines to the top.
        $atNew = [System.Collections.Generic.List[string]]::new()
        foreach ($atLine in $atHeader) { $atNew.Add($atLine) }
        for ($atE = $atRotateCount; $atE -lt $atIdxEntries; $atE++) {
            for ($atI = $atIdx.EntryLo[$atE]; $atI -le $atIdx.EntryHi[$atE]; $atI++) {
                $atNew.Add($atILines[$atI])
            }
        }
        foreach ($atLine in $atHarvest) { $atNew.Add($atLine) }
        Write-InsightFile -AtPath $insightIndex -AtBody $atNew.ToArray()
    }
} elseif ($atHEntries -gt 0) {
    if (-not $DryRun) {
        Write-InsightFile -AtPath $insightIndex -AtBody $atHarvest.ToArray() -AtAppend
    }
}

# Step 3: move task directory to _archived/
if (-not $DryRun) {
    if (-not (Test-Path $archivedRoot)) { New-Item -ItemType Directory -Path $archivedRoot -Force | Out-Null }
    Move-Item -Path $taskDir -Destination $archivedTaskDir
}

# Step 4: report
if ($DryRun) {
    Write-Host ""
    Write-Host "[DRY RUN] No files written. Would have:" -ForegroundColor Yellow
    Write-Host ('  - Appended {0} insight entry(ies) to .harness/insight-index.md' -f $atHEntries)
    Write-Host ('  - Rotated {0} old insight entry(ies) to insight-history.md' -f $atRotateCount)
    Write-Host ('  - Moved {0} -> {1}' -f $taskDir, $archivedTaskDir)
} else {
    Write-Host ""
    Write-Host ('Archived task: {0}' -f $Task) -ForegroundColor Green
    Write-Host ('  Stage docs:   {0}' -f $archivedTaskDir)
    if ($atHEntries -gt 0) {
        Write-Host ('  Insights:     +{0} entry(ies) to .harness/insight-index.md' -f $atHEntries)
    }
    if ($atRotateCount -gt 0) {
        Write-Host ('  Rotated:      {0} -> {1}' -f $atRotateCount, $insightHistory)
    }
}
