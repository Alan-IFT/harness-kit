# test-archive-task.ps1 — Drive archive-task.ps1's INSIGHT-SCAN harvester (T-20).
#
#   pwsh -File .harness/scripts/test-archive-task.ps1 [-ArchiveTask <path>]
#
# -ArchiveTask defaults to $repoRoot/.harness/scripts/archive-task.ps1. Every
# case runs against a FRESH sandbox repo root under the system temp directory
# with the script under test copied into its .harness/scripts/ — archive-task
# derives its repo root two levels up from its own location, so a copy is
# mandatory. No case writes anywhere under the real repository; the archived
# corpus (AC-15) is read read-only and classified in a sandbox.
#
# Symmetric twin of test-archive-task.sh, case for case, with exactly TWO
# exceptions, both of which are exceptions by nature rather than by omission:
#   - AC-4's pre/post regression floor is BASH-ONLY by design (B-11); this
#     twin's floor is B-18 — byte-identity of its index/history output against
#     the post-change BASH output for identical input, which is what the AC-1
#     expected-bytes fixture pins here and what operator item 17 measures end
#     to end.
#   - BC-19 (delivery document present but unreadable) is unix-only: it is
#     built by chmod 000 as a non-root user, which has no Windows equivalent.
# Every other case in the bash twin, AC-7 included, has a row here.
#
# NOT agent-executable (pwsh is absent on the maintainer host), so this file is
# green-by-symmetry until an operator runs it. Hazard discipline it must obey:
# PS parses the WHOLE file before executing (a syntax error in a never-taken
# branch is fatal); every new variable carries an `at` prefix so none collides
# with a read-only automatic such as $IsWindows; every binary `-join` is
# parenthesised before it meets a `+` (binary -join binds BELOW +); every
# multi-part message is built with -f. Child runs go through Start-Process with
# separate stdout/stderr redirection, never `& pwsh … 2>&1`, so a native
# command writing to stderr cannot throw under $ErrorActionPreference = 'Stop'.

[CmdletBinding()]
param(
    [string]$ArchiveTask = ''
)

$ErrorActionPreference = 'Stop'
# Script lives at .harness/scripts/ — repo root is two levels up.
$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
if (-not $ArchiveTask) { $ArchiveTask = Join-Path $repoRoot '.harness/scripts/archive-task.ps1' }
$atVerifyAll = Join-Path $repoRoot '.harness/scripts/verify_all.ps1'
$atTmplIndex = Join-Path $repoRoot 'skills/harness-init/templates/common/.harness/insight-index.md.tmpl'
if (-not (Test-Path -LiteralPath $ArchiveTask -PathType Leaf)) {
    Write-Host ('test-archive-task: archive-task not found: {0}' -f $ArchiveTask) -ForegroundColor Red
    exit 1
}
Write-Host ('  archive-task under test: {0}' -f $ArchiveTask)
Push-Location $repoRoot
try {

$atPass = 0
$atFail = 0
$atFailures = [System.Collections.Generic.List[string]]::new()
$atSandboxes = [System.Collections.Generic.List[string]]::new()
$atSb = ''
$atOut = ''
$atErr = ''
$atExit = 0
$atEnc = [System.Text.UTF8Encoding]::new($false)

function Add-Ok {
    param([string]$AtLabel)
    Write-Host ('  PASS  {0}' -f $AtLabel) -ForegroundColor Green
    $script:atPass = $script:atPass + 1
}

function Add-No {
    param([string]$AtLabel, [string]$AtDetail)
    Write-Host ('  FAIL  {0}' -f $AtLabel) -ForegroundColor Red
    Write-Host ('        {0}' -f $AtDetail) -ForegroundColor DarkRed
    $script:atFail = $script:atFail + 1
    $script:atFailures.Add($AtLabel)
}

function Assert-Eq {
    param([string]$AtLabel, [string]$AtExpected, [string]$AtActual)
    if ($AtExpected -ceq $AtActual) { Add-Ok $AtLabel }
    else { Add-No $AtLabel ('expected [{0}] got [{1}]' -f $AtExpected, $AtActual) }
}

function Assert-Has {
    param([string]$AtLabel, [string]$AtNeedle, [string]$AtHaystack)
    if (($null -ne $AtHaystack) -and $AtHaystack.Contains($AtNeedle)) { Add-Ok $AtLabel }
    else { Add-No $AtLabel ('missing [{0}]' -f $AtNeedle) }
}

function Assert-HasNot {
    param([string]$AtLabel, [string]$AtNeedle, [string]$AtHaystack)
    if (($null -eq $AtHaystack) -or (-not $AtHaystack.Contains($AtNeedle))) { Add-Ok $AtLabel }
    else { Add-No $AtLabel ('unexpected [{0}] present' -f $AtNeedle) }
}

function Get-FileB64 {
    param([string]$AtPath)
    if (-not (Test-Path -LiteralPath $AtPath -PathType Leaf)) { return '<absent>' }
    return [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($AtPath))
}

function Assert-FilesEq {
    param([string]$AtLabel, [string]$AtA, [string]$AtB)
    if ((Get-FileB64 $AtA) -ceq (Get-FileB64 $AtB)) { Add-Ok $AtLabel }
    else { Add-No $AtLabel ('bytes differ: {0} vs {1}' -f $AtA, $AtB) }
}

function Write-Banner {
    param([string]$AtText)
    Write-Host ''
    Write-Host ('--- {0}' -f $AtText) -ForegroundColor Cyan
}

# --- fixture + sandbox helpers --------------------------------------------
function Write-Fixture {
    param(
        [string]$AtPath,
        [AllowEmptyCollection()][string[]]$AtLines,
        [switch]$AtNoFinalNewline
    )
    $atText = ($AtLines -join "`n")
    if (-not $AtNoFinalNewline) { $atText = $atText + "`n" }
    $atDir = Split-Path $AtPath -Parent
    if (-not (Test-Path $atDir)) { New-Item -ItemType Directory -Path $atDir -Force | Out-Null }
    [System.IO.File]::WriteAllText($AtPath, $atText, [System.Text.UTF8Encoding]::new($false))
}

function New-Sandbox {
    $atRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('test-archive-task-' + [System.Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path (Join-Path $atRoot '.harness/scripts') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $atRoot 'docs/features/_archived') -Force | Out-Null
    Copy-Item -Path $script:ArchiveTask -Destination (Join-Path $atRoot '.harness/scripts/archive-task.ps1') -Force
    $script:atSandboxes.Add($atRoot)
    $script:atSb = $atRoot
    return $atRoot
}

# Start-Process with SEPARATE stdout/stderr files: `& pwsh … 2>&1` is a native
# capture whose stderr can throw under $ErrorActionPreference = 'Stop'.
function Invoke-At {
    param([AllowEmptyCollection()][string[]]$AtArgv)
    $atOutFile = Join-Path $script:atSb 'out.txt'
    $atErrFile = Join-Path $script:atSb 'err.txt'
    $atList = [System.Collections.Generic.List[string]]::new()
    $atList.Add('-NoProfile')
    $atList.Add('-File')
    $atList.Add((Join-Path $script:atSb '.harness/scripts/archive-task.ps1'))
    foreach ($atA in $AtArgv) { $atList.Add($atA) }
    $atProc = Start-Process -FilePath 'pwsh' -ArgumentList $atList.ToArray() -NoNewWindow -Wait -PassThru `
        -RedirectStandardOutput $atOutFile -RedirectStandardError $atErrFile
    $script:atExit = $atProc.ExitCode
    $script:atOut = [System.IO.File]::ReadAllText($atOutFile)
    $script:atErr = [System.IO.File]::ReadAllText($atErrFile)
}

# Run verify_all in a sandbox and return its [I.4] line (every other check is
# ignored on purpose — the sandbox is not a repo and most of them fail).
function Get-I4Line {
    param([string]$AtRoot)
    $atDst = Join-Path $AtRoot '.harness/scripts/verify_all.ps1'
    New-Item -ItemType Directory -Path (Join-Path $AtRoot '.harness/scripts') -Force | Out-Null
    Copy-Item -Path $script:atVerifyAll -Destination $atDst -Force
    $atOutFile = Join-Path $AtRoot 'i4out.txt'
    $atErrFile = Join-Path $AtRoot 'i4err.txt'
    $atProc = Start-Process -FilePath 'pwsh' -ArgumentList @('-NoProfile', '-File', $atDst) -NoNewWindow -Wait -PassThru `
        -RedirectStandardOutput $atOutFile -RedirectStandardError $atErrFile
    $atText = [System.IO.File]::ReadAllText($atOutFile)
    $atHit = @($atText -split "`n" | Where-Object { $_ -match '^\[I\.4\]' })
    if ($atHit.Count -eq 0) { return '' }
    return ($atHit -join ' ')
}

# K-61 raw-marker oracle — the PRE-CHANGE quantity, computed with a .NET regex
# in this driver only, never by a shipped check.
function Get-RawMarkers {
    param([string]$AtPath)
    if (-not (Test-Path -LiteralPath $AtPath -PathType Leaf)) { return 0 }
    return @(@(Get-Content -Path $AtPath) | Where-Object { $_ -match '^\s*-\s+' }).Count
}

# =========================================================================
Write-Banner 'AC-1 / B-2 — a wrapped entry is harvested whole'
$atRoot = New-Sandbox
Write-Fixture (Join-Path $atRoot '.harness/insight-index.md') @(
    '# Insight Index — fixture',
    '',
    '- 2026-01-01 · stored one'
)
Write-Fixture (Join-Path $atRoot 'docs/features/wrapped/07_DELIVERY.md') @(
    '# 07 — Delivery',
    '',
    '## Insight',
    '',
    '- 2026-02-01 · first fact that wraps',
    '  onto a second physical line · evidence: file.sh:12',
    '- 2026-02-01 · second fact',
    '',
    '## Verdict'
)
# This expected file is the POST-CHANGE BASH output for the same input, so this
# comparison is the in-driver half of B-18.
Write-Fixture (Join-Path $atRoot 'expected-index') @(
    '# Insight Index — fixture',
    '',
    '- 2026-01-01 · stored one',
    '- 2026-02-01 · first fact that wraps',
    '  onto a second physical line · evidence: file.sh:12',
    '- 2026-02-01 · second fact'
)
Invoke-At @('-Task', 'wrapped')
Assert-Eq 'AC-1 exit status' '0' ([string]$atExit)
Assert-Has 'AC-1 section tally' 'Insight tally: entries 2, continuation lines 1, ignorable lines 2 (terminal footer 0), unaccounted lines 0' $atOut
Assert-Has 'AC-1 index tally' 'Index tally: entries 1, unaccounted lines 0, entries after run 3' $atOut
Assert-FilesEq 'AC-1 index bytes equal the expected content (B-18 byte-identity with bash)' (Join-Path $atRoot 'expected-index') (Join-Path $atRoot '.harness/insight-index.md')
Assert-Has 'AC-1 evidence pointer survives on the continuation line' '  onto a second physical line · evidence: file.sh:12' ([System.IO.File]::ReadAllText((Join-Path $atRoot '.harness/insight-index.md')))
Assert-Has 'AC-1 echo reprints the continuation line' '  onto a second physical line' $atOut

# =========================================================================
Write-Banner 'AC-2 / B-4 / BC-5 — an unaccounted delivery line refuses before any write'
$atRoot = New-Sandbox
Write-Fixture (Join-Path $atRoot '.harness/insight-index.md') @(
    '# Insight Index — fixture',
    '',
    '- 2026-01-01 · stored one'
)
Write-Fixture (Join-Path $atRoot 'docs/features/_archived/insight-history.md') @(
    '# Insight history (rotated from .harness/insight-index.md)'
)
Write-Fixture (Join-Path $atRoot 'docs/features/unacc/07_DELIVERY.md') @(
    '# 07 — Delivery',
    '',
    '## Insight',
    '',
    '- 2026-02-01 · a fact',
    '',
    'Trailing prose that no rule accounts for.',
    '',
    '## Verdict'
)
Copy-Item (Join-Path $atRoot '.harness/insight-index.md') (Join-Path $atRoot 'index.before') -Force
Copy-Item (Join-Path $atRoot 'docs/features/_archived/insight-history.md') (Join-Path $atRoot 'history.before') -Force
$atIdxMtimeBefore = (Get-Item (Join-Path $atRoot '.harness/insight-index.md')).LastWriteTimeUtc.Ticks
$atHistMtimeBefore = (Get-Item (Join-Path $atRoot 'docs/features/_archived/insight-history.md')).LastWriteTimeUtc.Ticks
Invoke-At @('-Task', 'unacc')
Assert-Eq 'AC-2 exit status is 3' '3' ([string]$atExit)
Assert-Has 'AC-2 diagnostic names document, 1-based line and text' '07_DELIVERY.md:7: unaccounted line: Trailing prose that no rule accounts for.' $atErr
Assert-Has 'AC-2 tally still printed on the refusal path' 'Insight tally: entries 1, continuation lines 0, ignorable lines 3 (terminal footer 0), unaccounted lines 1' $atOut
Assert-FilesEq 'AC-2 index byte-identical' (Join-Path $atRoot 'index.before') (Join-Path $atRoot '.harness/insight-index.md')
Assert-FilesEq 'AC-2 history byte-identical' (Join-Path $atRoot 'history.before') (Join-Path $atRoot 'docs/features/_archived/insight-history.md')
Assert-Eq 'AC-2 index mtime unmoved' ([string]$atIdxMtimeBefore) ([string](Get-Item (Join-Path $atRoot '.harness/insight-index.md')).LastWriteTimeUtc.Ticks)
Assert-Eq 'AC-2 history mtime unmoved' ([string]$atHistMtimeBefore) ([string](Get-Item (Join-Path $atRoot 'docs/features/_archived/insight-history.md')).LastWriteTimeUtc.Ticks)
if ((Test-Path (Join-Path $atRoot 'docs/features/unacc')) -and (-not (Test-Path (Join-Path $atRoot 'docs/features/_archived/unacc')))) {
    Add-Ok 'AC-2 task directory not moved'
} else {
    Add-No 'AC-2 task directory not moved' 'task dir state changed'
}

# =========================================================================
Write-Banner 'BC-6 — a blank line inside an authored bullet terminates the entry'
$atRoot = New-Sandbox
Write-Fixture (Join-Path $atRoot '.harness/insight-index.md') @('# Insight Index — fixture')
Write-Fixture (Join-Path $atRoot 'docs/features/bc6/07_DELIVERY.md') @(
    '# 07 — Delivery',
    '',
    '## Insight',
    '',
    '- 2026-02-01 · a fact',
    '',
    '  indented continuation after a blank',
    '',
    '## Verdict'
)
Invoke-At @('-Task', 'bc6')
Assert-Eq 'BC-6 exit status is 3' '3' ([string]$atExit)
Assert-Has 'BC-6 diagnostic names the orphaned line' ':7: unaccounted line:   indented continuation after a blank' $atErr
Assert-Has 'BC-6 tally' 'Insight tally: entries 1, continuation lines 0, ignorable lines 3 (terminal footer 0), unaccounted lines 1' $atOut

# =========================================================================
Write-Banner 'AC-13 / BC-21 — break then entry, DELIVERY (discriminating fixture)'
$atRoot = New-Sandbox
Write-Fixture (Join-Path $atRoot '.harness/insight-index.md') @('# Insight Index — fixture')
Write-Fixture (Join-Path $atRoot 'docs/features/ac13/07_DELIVERY.md') @(
    '# 07 — Delivery',
    '',
    '## Insight',
    '',
    '- 2026-02-01 · first fact',
    '',
    '---',
    '',
    '- 2026-02-01 · second fact',
    '  its continuation · evidence: x:1',
    '',
    '## Verdict'
)
Copy-Item (Join-Path $atRoot '.harness/insight-index.md') (Join-Path $atRoot 'index.before') -Force
Invoke-At @('-Task', 'ac13')
Assert-Eq 'AC-13 exit status is 3' '3' ([string]$atExit)
Assert-Has 'AC-13 diagnostic names the --- line 1-based number and text' ':7: unaccounted line: ---' $atErr
# The rejected reading (every line after a thematic break is ignorable) exits 0,
# drops both post-break lines and reports entries 1 / continuation 0.
Assert-Has 'AC-13 tally reports the post-break entry-start line and its continuation as CONTENT' 'Insight tally: entries 2, continuation lines 1, ignorable lines 4 (terminal footer 0), unaccounted lines 1' $atOut
Assert-FilesEq 'AC-13 index byte-identical' (Join-Path $atRoot 'index.before') (Join-Path $atRoot '.harness/insight-index.md')
if (-not (Test-Path (Join-Path $atRoot 'docs/features/_archived/insight-history.md'))) {
    Add-Ok 'AC-13 history not created'
} else {
    Add-No 'AC-13 history not created' 'insight-history.md exists'
}
if (Test-Path (Join-Path $atRoot 'docs/features/ac13')) { Add-Ok 'AC-13 task dir not moved' } else { Add-No 'AC-13 task dir not moved' 'moved' }

# =========================================================================
Write-Banner 'AC-14 / BC-21 — break then entry, INDEX (discriminating fixture)'
$atRoot = New-Sandbox
Write-Fixture (Join-Path $atRoot '.harness/insight-index.md') @(
    '# Insight Index — fixture',
    '',
    '- 2026-01-01 · stored one',
    '',
    '---',
    '',
    '- 2026-01-01 · stored two',
    '  its continuation · evidence: y:2'
)
Write-Fixture (Join-Path $atRoot 'docs/features/ac14/07_DELIVERY.md') @(
    '# 07 — Delivery',
    '',
    '## Insight',
    '',
    '- 2026-02-01 · a clean fact',
    '',
    '## Verdict'
)
Copy-Item (Join-Path $atRoot '.harness/insight-index.md') (Join-Path $atRoot 'index.before') -Force
Invoke-At @('-Task', 'ac14')
Assert-Eq 'AC-14 exit status is 3' '3' ([string]$atExit)
Assert-Has 'AC-14 diagnostic names the index path and the --- line' 'insight-index.md:5: unaccounted line: ---' $atErr
Assert-Has 'AC-14 index tally (rejected reading would report entries 1)' 'Index tally: entries 2, unaccounted lines 1, entries after run 2' $atOut
Assert-FilesEq 'AC-14 index byte-identical after the refusal' (Join-Path $atRoot 'index.before') (Join-Path $atRoot '.harness/insight-index.md')
Assert-Has 'AC-14 post-break entry-start line still in the index' '- 2026-01-01 · stored two' ([System.IO.File]::ReadAllText((Join-Path $atRoot '.harness/insight-index.md')))
Assert-Has 'AC-14 post-break continuation still in the index' '  its continuation · evidence: y:2' ([System.IO.File]::ReadAllText((Join-Path $atRoot '.harness/insight-index.md')))
# K-61 oracle: raw markers == classified entries on this fixture (its header
# block holds no entry-start-shaped line). The rejected reading gives raw 2 and
# classified 1, which turns this row red. BOTH halves are parsed out of the run
# (the bash twin does the same with sed at :281). A classified=2 literal on both
# sides would degenerate the row to a raw == 2 test and could not see a
# classified-count drift at all.
$atClassified = ''
if ($atOut -match 'Index tally: entries (\d+),') { $atClassified = $Matches[1] }
Assert-Eq 'AC-14 K-61 equality: raw markers == classified entries' 'raw=2 classified=2' ('raw={0} classified={1}' -f (Get-RawMarkers (Join-Path $atRoot '.harness/insight-index.md')), $atClassified)
$atI4 = Get-I4Line $atRoot
Assert-Has 'AC-14 I.4 reports non-PASS over the fixture' 'WARN' $atI4
Assert-Has 'AC-14 I.4 names 2 entries and 1 unaccounted line at line 5' '2 entries, 1 unaccounted line(s), first at line 5' $atI4

# =========================================================================
Write-Banner 'AC-16 / BC-24 / B-19 — shipped-template header block, harvest AND rotation'
$atRoot = New-Sandbox
$atTmplLines = @(Get-Content -Path $atTmplIndex)
$atFix = [System.Collections.Generic.List[string]]::new()
foreach ($atL in $atTmplLines) { $atFix.Add($atL) }
for ($atI = 1; $atI -le 30; $atI++) {
    $atFix.Add(('- 2026-01-{0:d2} · stored entry {1} · evidence: t:{1}' -f (($atI % 28) + 1), $atI))
}
Write-Fixture (Join-Path $atRoot '.harness/insight-index.md') $atFix.ToArray()
Write-Fixture (Join-Path $atRoot 'docs/features/ac16/07_DELIVERY.md') @(
    '# 07 — Delivery',
    '',
    '## Insight',
    '',
    '- 2026-02-01 · new fact one',
    '- 2026-02-01 · new fact two',
    '',
    '## Verdict'
)
# K-61's ONE designed inequality: the template's commented example bullet is an
# entry-start-shaped line INSIDE the header block, so raw = entries + 1.
Assert-Eq 'AC-16 K-61 designed inequality raw == entries + 1 (31 vs 30)' '31' ([string](Get-RawMarkers (Join-Path $atRoot '.harness/insight-index.md')))
Invoke-At @('-Task', 'ac16')
Assert-Eq 'AC-16 exit status' '0' ([string]$atExit)
Assert-Has 'AC-16 index tally before rotation (0 entries from the header block)' 'Index tally: entries 30, unaccounted lines 0, entries after run 30' $atOut
Assert-Has 'AC-16 rotation fired' 'Rotating 2 old insight entry(ies)' $atOut
$atAfter = @(Get-Content -Path (Join-Path $atRoot '.harness/insight-index.md'))
Write-Fixture (Join-Path $atRoot 'header.after') ($atAfter[0..($atTmplLines.Count - 1)])
$atTmplCopy = Join-Path $atRoot 'header.expected'
Write-Fixture $atTmplCopy $atTmplLines
Assert-FilesEq 'AC-16 header block byte-identical and still first' $atTmplCopy (Join-Path $atRoot 'header.after')
Assert-Has 'AC-16 HTML comment still closed' '-->' ([System.IO.File]::ReadAllText((Join-Path $atRoot 'header.after')))
$atHistText = [System.IO.File]::ReadAllText((Join-Path $atRoot 'docs/features/_archived/insight-history.md'))
Assert-HasNot 'AC-16 history contains no HTML comment terminator' '-->' $atHistText
Assert-HasNot 'AC-16 history contains no header example line' '- YYYY-MM-DD · <one-sentence fact>' $atHistText
Assert-Eq 'AC-16 index holds 30 entries after the run' '30' ([string]((Get-RawMarkers (Join-Path $atRoot '.harness/insight-index.md')) - 1))

# =========================================================================
Write-Banner 'AC-15 / BC-20 — non-wedging floor over the real archived corpus (read-only)'
$atClean = 0
$atDirty = 0
$atFooterSections = 0
$atRoot = New-Sandbox
# Depth-1 enumeration, NOT -Recurse: the bash twin globs
# docs/features/_archived/*/07_DELIVERY.md, so a -Recurse walk here would count
# a nested delivery document the bash twin never sees and the two floors would
# silently diverge the day one appears.
foreach ($atDir in @(Get-ChildItem -Path (Join-Path $repoRoot 'docs/features/_archived') -Directory)) {
    $atF = Join-Path $atDir.FullName '07_DELIVERY.md'
    if (-not (Test-Path -LiteralPath $atF -PathType Leaf)) { continue }
    $atHasHeading = @(@(Get-Content -Path $atF) | Where-Object { $_ -match '^##\s+Insights?\s*$' }).Count
    if ($atHasHeading -eq 0) { continue }
    $atCorpusTask = Join-Path $atRoot 'docs/features/corpus'
    if (Test-Path $atCorpusTask) { Remove-Item -Path $atCorpusTask -Recurse -Force }
    New-Item -ItemType Directory -Path $atCorpusTask -Force | Out-Null
    Copy-Item -Path $atF -Destination (Join-Path $atCorpusTask '07_DELIVERY.md') -Force
    Write-Fixture (Join-Path $atRoot '.harness/insight-index.md') @('# Insight Index — fixture')
    Invoke-At @('-Task', 'corpus', '-DryRun')
    $atTally = @(@($atOut -split "`n") | Where-Object { $_ -match '^Insight tally:' })
    $atLineText = ''
    if ($atTally.Count -gt 0) { $atLineText = $atTally[0] }
    $atU = -1
    $atFt = -1
    if ($atLineText -match 'unaccounted lines (\d+)') { $atU = [int]$Matches[1] }
    if ($atLineText -match 'terminal footer (\d+)\)') { $atFt = [int]$Matches[1] }
    if (($atExit -eq 0) -and ($atU -eq 0)) { $atClean = $atClean + 1 } else { $atDirty = $atDirty + 1 }
    # -gt 0, NOT -ne 0: $atFt stays at its -1 sentinel when the tally line is absent
    # or unparseable (the pre-change script prints no tally at all), and -1 -ne 0 is
    # TRUE, which would count every unmeasured section as footer-bearing and hand the
    # >= 3 floor row a spurious green against the script it is meant to detect.
    if ($atFt -gt 0) { $atFooterSections = $atFooterSections + 1 }
}
# AC-15's property is "no archived section wedges the harvester", so $atDirty
# -eq 0 is the HARD row. The other two are FLOORS, not equalities: the corpus
# grows by one section every time a task archives (this task's own stage-7
# archive takes it to 35), and an exact count would go red on the next commit.
# The floors are the figures measured on the run that set baseline.json's 152:
# 34 clean / 3 footer. They still discriminate — $atClean sits EXACTLY on its
# floor, so any section that stops classifying cleanly moves it to 33 (a dirty
# section increments $atDirty instead), and an unenumerated corpus reads 0.
if ($atClean -ge 34) {
    Add-Ok 'AC-15 archived sections classified with 0 unaccounted lines (floor 34)'
} else {
    Add-No 'AC-15 archived sections classified with 0 unaccounted lines (floor 34)' ('expected >= 34 got {0}' -f $atClean)
}
Assert-Eq 'AC-15 archived sections with an unaccounted line' '0' ([string]$atDirty)
if ($atFooterSections -ge 3) {
    Add-Ok 'AC-15 sections whose terminal-footer figure is non-zero (floor 3)'
} else {
    Add-No 'AC-15 sections whose terminal-footer figure is non-zero (floor 3)' ('expected >= 3 got {0}' -f $atFooterSections)
}

# =========================================================================
Write-Banner 'BC-22 — a thematic break abutting an entry is a continuation'
$atRoot = New-Sandbox
Write-Fixture (Join-Path $atRoot '.harness/insight-index.md') @('# Insight Index — fixture')
Write-Fixture (Join-Path $atRoot 'docs/features/bc22/07_DELIVERY.md') @(
    '# 07 — Delivery',
    '',
    '## Insight',
    '',
    '- 2026-02-01 · a fact',
    '---',
    '',
    '## Verdict'
)
Invoke-At @('-Task', 'bc22')
Assert-Eq 'BC-22 exit status' '0' ([string]$atExit)
Assert-Has 'BC-22 tally: the break is a continuation, not a footer' 'Insight tally: entries 1, continuation lines 1, ignorable lines 2 (terminal footer 0), unaccounted lines 0' $atOut
$atIdxLines = @(Get-Content -Path (Join-Path $atRoot '.harness/insight-index.md'))
Assert-Eq 'BC-22 break preserved verbatim as the entry last index line' '---' ($atIdxLines[$atIdxLines.Count - 1])

# =========================================================================
Write-Banner 'BC-3 / BC-4 — preamble shapes'
$atRoot = New-Sandbox
Write-Fixture (Join-Path $atRoot '.harness/insight-index.md') @('# Insight Index — fixture')
Copy-Item (Join-Path $atRoot '.harness/insight-index.md') (Join-Path $atRoot 'index.before') -Force
Write-Fixture (Join-Path $atRoot 'docs/features/bc3/07_DELIVERY.md') @(
    '# 07 — Delivery',
    '',
    '## Insight',
    '',
    'Some prose but no bullet at all.',
    '',
    '## Verdict'
)
Invoke-At @('-Task', 'bc3')
Assert-Eq 'BC-3 exit status' '0' ([string]$atExit)
Assert-Has 'BC-3 tally: preamble-only yields 0 entries and 0 unaccounted' 'Insight tally: entries 0, continuation lines 0, ignorable lines 3 (terminal footer 0), unaccounted lines 0' $atOut
Assert-FilesEq 'BC-3 index not written' (Join-Path $atRoot 'index.before') (Join-Path $atRoot '.harness/insight-index.md')

$atRoot = New-Sandbox
Write-Fixture (Join-Path $atRoot '.harness/insight-index.md') @('# Insight Index — fixture')
Write-Fixture (Join-Path $atRoot 'docs/features/bc4/07_DELIVERY.md') @(
    '# 07 — Delivery',
    '',
    '## Insight',
    '',
    'Preamble prose describing the section.',
    '',
    '- 2026-02-01 · a fact',
    '',
    '## Verdict'
)
Invoke-At @('-Task', 'bc4')
Assert-Eq 'BC-4 exit status' '0' ([string]$atExit)
Assert-Has 'BC-4 tally: preamble counted ignorable, entry harvested' 'Insight tally: entries 1, continuation lines 0, ignorable lines 4 (terminal footer 0), unaccounted lines 0' $atOut
$atIdxText = [System.IO.File]::ReadAllText((Join-Path $atRoot '.harness/insight-index.md'))
Assert-Has 'BC-4 entry harvested' '- 2026-02-01 · a fact' $atIdxText
Assert-HasNot 'BC-4 preamble not harvested' 'Preamble prose' $atIdxText

# =========================================================================
Write-Banner 'BC-7 — an entry-start marker in continuation position becomes its own entry'
$atRoot = New-Sandbox
Write-Fixture (Join-Path $atRoot '.harness/insight-index.md') @('# Insight Index — fixture')
Write-Fixture (Join-Path $atRoot 'docs/features/bc7/07_DELIVERY.md') @(
    '# 07 — Delivery',
    '',
    '## Insight',
    '',
    '- 2026-02-01 · a fact',
    '- continuation shaped like a marker',
    '',
    '## Verdict'
)
Invoke-At @('-Task', 'bc7')
Assert-Eq 'BC-7 exit status' '0' ([string]$atExit)
Assert-Has 'BC-7 tally reports 2 entries' 'Insight tally: entries 2, continuation lines 0, ignorable lines 2 (terminal footer 0), unaccounted lines 0' $atOut
Assert-Eq 'BC-7 K-61 equality over the post-run index (raw 2 == entries 2)' '2' ([string](Get-RawMarkers (Join-Path $atRoot '.harness/insight-index.md')))
Assert-Has 'BC-7 archive-task reports the same index entry count' 'Index tally: entries 0, unaccounted lines 0, entries after run 2' $atOut

# =========================================================================
Write-Banner 'BC-8 — CRLF delivery document'
$atRoot = New-Sandbox
Write-Fixture (Join-Path $atRoot '.harness/insight-index.md') @('# Insight Index — fixture')
$atCrlf = "# 07`r`n`r`n## Insight`r`n`r`n- 2026-02-01 · crlf fact`r`n  its continuation · evidence: c:1`r`n`r`n## Verdict`r`n"
New-Item -ItemType Directory -Path (Join-Path $atRoot 'docs/features/bc8') -Force | Out-Null
[System.IO.File]::WriteAllText((Join-Path $atRoot 'docs/features/bc8/07_DELIVERY.md'), $atCrlf, $atEnc)
Invoke-At @('-Task', 'bc8')
Assert-Eq 'BC-8 exit status' '0' ([string]$atExit)
$atIdxText = [System.IO.File]::ReadAllText((Join-Path $atRoot '.harness/insight-index.md'))
Assert-HasNot 'BC-8 no CR byte written into the index' "`r" $atIdxText
Assert-Has 'BC-8 continuation harvested' '  its continuation · evidence: c:1' $atIdxText

# =========================================================================
Write-Banner 'BC-9 — trailing whitespace stripped, leading whitespace preserved'
$atRoot = New-Sandbox
Write-Fixture (Join-Path $atRoot '.harness/insight-index.md') @('# Insight Index — fixture')
$atWs = "# 07`n`n## Insight`n`n- 2026-02-01 · ws fact   `n    four-space indent kept`t`n`n## Verdict`n"
New-Item -ItemType Directory -Path (Join-Path $atRoot 'docs/features/bc9') -Force | Out-Null
[System.IO.File]::WriteAllText((Join-Path $atRoot 'docs/features/bc9/07_DELIVERY.md'), $atWs, $atEnc)
Invoke-At @('-Task', 'bc9')
Assert-Eq 'BC-9 exit status' '0' ([string]$atExit)
$atIdxLines = @(Get-Content -Path (Join-Path $atRoot '.harness/insight-index.md'))
$atTrailing = @($atIdxLines | Where-Object { $_ -match '\s$' }).Count
Assert-Eq 'BC-9 no trailing whitespace in the written index' '0' ([string]$atTrailing)
Assert-Eq 'BC-9 leading whitespace byte-preserved' '    four-space indent kept' ($atIdxLines[$atIdxLines.Count - 1])

# =========================================================================
Write-Banner 'BC-12 / BC-13 — cap boundaries'
$atRoot = New-Sandbox
$atFix = [System.Collections.Generic.List[string]]::new()
$atFix.Add('# Insight Index — fixture')
for ($atI = 1; $atI -le 28; $atI++) { $atFix.Add(('- stored {0:d2}' -f $atI)) }
Write-Fixture (Join-Path $atRoot '.harness/insight-index.md') $atFix.ToArray()
Write-Fixture (Join-Path $atRoot 'docs/features/bc12/07_DELIVERY.md') @(
    '# 07', '', '## Insight', '', '- new one', '- new two', '', '## Verdict'
)
Invoke-At @('-Task', 'bc12')
Assert-Eq 'BC-12 exit status' '0' ([string]$atExit)
Assert-Has 'BC-12 total exactly 30 -> no rotation' 'Index tally: entries 28, unaccounted lines 0, entries after run 30' $atOut
Assert-HasNot 'BC-12 no rotation notice' 'Rotating' $atOut
if (-not (Test-Path (Join-Path $atRoot 'docs/features/_archived/insight-history.md'))) {
    Add-Ok 'BC-12 history not created'
} else {
    Add-No 'BC-12 history not created' 'insight-history.md exists'
}

$atRoot = New-Sandbox
$atFix = [System.Collections.Generic.List[string]]::new()
$atFix.Add('# Insight Index — fixture')
for ($atI = 1; $atI -le 29; $atI++) { $atFix.Add(('- stored {0:d2}' -f $atI)) }
Write-Fixture (Join-Path $atRoot '.harness/insight-index.md') $atFix.ToArray()
Write-Fixture (Join-Path $atRoot 'docs/features/bc13/07_DELIVERY.md') @(
    '# 07', '', '## Insight', '', '- new one', '- new two', '', '## Verdict'
)
Invoke-At @('-Task', 'bc13')
Assert-Eq 'BC-13 exit status' '0' ([string]$atExit)
Assert-Has 'BC-13 exactly one entry rotated' 'Rotating 1 old insight entry(ies)' $atOut
Assert-Has 'BC-13 index tally' 'Index tally: entries 29, unaccounted lines 0, entries after run 30' $atOut
Assert-Has 'BC-13 oldest entry rotated first' '- stored 01' ([System.IO.File]::ReadAllText((Join-Path $atRoot 'docs/features/_archived/insight-history.md')))
$atIdxText = [System.IO.File]::ReadAllText((Join-Path $atRoot '.harness/insight-index.md'))
Assert-HasNot 'BC-13 rotated entry gone from the index' '- stored 01' $atIdxText
Assert-Has 'BC-13 second-oldest retained' '- stored 02' $atIdxText

# =========================================================================
Write-Banner 'BC-14 — rotate count clamped to the stored entry count'
$atRoot = New-Sandbox
Write-Fixture (Join-Path $atRoot '.harness/insight-index.md') @(
    '# Insight Index — fixture', '- stored 01', '- stored 02'
)
$atFix = [System.Collections.Generic.List[string]]::new()
$atFix.Add('# 07'); $atFix.Add(''); $atFix.Add('## Insight'); $atFix.Add('')
for ($atI = 1; $atI -le 31; $atI++) { $atFix.Add(('- new {0:d2}' -f $atI)) }
$atFix.Add(''); $atFix.Add('## Verdict')
Write-Fixture (Join-Path $atRoot 'docs/features/bc14/07_DELIVERY.md') $atFix.ToArray()
Invoke-At @('-Task', 'bc14')
Assert-Eq 'BC-14 exit status (completes, no abort)' '0' ([string]$atExit)
Assert-Has 'BC-14 every stored entry rotated (clamped to 2)' 'Rotating 2 old insight entry(ies)' $atOut
Assert-Has 'BC-14 index holds the harvested entries' 'Index tally: entries 2, unaccounted lines 0, entries after run 31' $atOut
Assert-Eq 'BC-14 index entry count after the run' '31' ([string](Get-RawMarkers (Join-Path $atRoot '.harness/insight-index.md')))
Assert-Has 'BC-14 step 4 reached' 'Archived task: bc14' $atOut

# =========================================================================
Write-Banner 'B-7 / B-8 / B-10 — a STORED wrapped entry rotates whole'
$atRoot = New-Sandbox
$atFix = [System.Collections.Generic.List[string]]::new()
$atFix.Add('# Insight Index — fixture')
$atFix.Add('')
$atFix.Add('<!-- Append new insights below, one per line. Format:')
$atFix.Add('-->')
$atFix.Add('- 2026-01-01 · stored wrapped entry')
$atFix.Add('  its continuation line · evidence: s:1')
for ($atI = 2; $atI -le 30; $atI++) { $atFix.Add(('- stored {0:d2}' -f $atI)) }
Write-Fixture (Join-Path $atRoot '.harness/insight-index.md') $atFix.ToArray()
Write-Fixture (Join-Path $atRoot 'header.before') @(
    '# Insight Index — fixture',
    '',
    '<!-- Append new insights below, one per line. Format:',
    '-->'
)
Write-Fixture (Join-Path $atRoot 'docs/features/stored/07_DELIVERY.md') @(
    '# 07', '', '## Insight', '', '- new one', '', '## Verdict'
)
Invoke-At @('-Task', 'stored')
Assert-Eq 'B-10 exit status' '0' ([string]$atExit)
Assert-Has 'B-10 stored wrapped entry counted as ONE entry' 'Index tally: entries 30, unaccounted lines 0, entries after run 30' $atOut
$atHistText = [System.IO.File]::ReadAllText((Join-Path $atRoot 'docs/features/_archived/insight-history.md'))
Assert-Has 'B-7 rotated entry-start line in history' '- 2026-01-01 · stored wrapped entry' $atHistText
Assert-Has 'B-7 rotated CONTINUATION line in history' '  its continuation line · evidence: s:1' $atHistText
$atIdxText = [System.IO.File]::ReadAllText((Join-Path $atRoot '.harness/insight-index.md'))
Assert-HasNot 'B-7 rotated entry-start line gone from the index' 'stored wrapped entry' $atIdxText
Assert-HasNot 'B-7 rotated continuation gone from the index' 'its continuation line' $atIdxText
$atAfter = @(Get-Content -Path (Join-Path $atRoot '.harness/insight-index.md'))
Write-Fixture (Join-Path $atRoot 'header.after') ($atAfter[0..3])
Assert-FilesEq 'B-8 header block byte-identical and still first' (Join-Path $atRoot 'header.before') (Join-Path $atRoot 'header.after')

# =========================================================================
Write-Banner 'K-16 — an unaccounted line in the INDEX refuses before any write'
$atRoot = New-Sandbox
Write-Fixture (Join-Path $atRoot '.harness/insight-index.md') @(
    '# Insight Index — fixture',
    '',
    '- 2026-01-01 · stored one',
    'stray prose that follows an entry without a blank line is a continuation',
    '',
    'not this one though'
)
Write-Fixture (Join-Path $atRoot 'docs/features/k16/07_DELIVERY.md') @(
    '# 07', '', '## Insight', '', '- new one', '', '## Verdict'
)
Copy-Item (Join-Path $atRoot '.harness/insight-index.md') (Join-Path $atRoot 'index.before') -Force
Invoke-At @('-Task', 'k16')
Assert-Eq 'K-16 exit status is 3' '3' ([string]$atExit)
Assert-Has 'K-16 diagnostic names the index path' 'insight-index.md:6: unaccounted line: not this one though' $atErr
Assert-FilesEq 'K-16 index byte-identical' (Join-Path $atRoot 'index.before') (Join-Path $atRoot '.harness/insight-index.md')
if (Test-Path (Join-Path $atRoot 'docs/features/k16')) { Add-Ok 'K-16 task dir not moved' } else { Add-No 'K-16 task dir not moved' 'moved' }

# =========================================================================
Write-Banner 'X-8 — a ## / ### heading line, in BOTH modes, is UNACCOUNTED'
$atRoot = New-Sandbox
Write-Fixture (Join-Path $atRoot '.harness/insight-index.md') @('# Insight Index — fixture')
Write-Fixture (Join-Path $atRoot 'docs/features/x8s/07_DELIVERY.md') @(
    '# 07 — Delivery',
    '',
    '## Insight',
    '',
    '- 2026-02-01 · a fact',
    '### Subheading inside the section',
    '',
    '## Verdict'
)
Copy-Item (Join-Path $atRoot '.harness/insight-index.md') (Join-Path $atRoot 'index.before') -Force
Invoke-At @('-Task', 'x8s')
Assert-Eq 'X-8 section: exit status is 3' '3' ([string]$atExit)
Assert-Has 'X-8 section: diagnostic names the ### line 1-based number and text' ':6: unaccounted line: ### Subheading inside the section' $atErr
Assert-Has 'X-8 section: the heading is UNACCOUNTED, not a continuation' 'Insight tally: entries 1, continuation lines 0, ignorable lines 2 (terminal footer 0), unaccounted lines 1' $atOut
Assert-FilesEq 'X-8 section: index byte-identical' (Join-Path $atRoot 'index.before') (Join-Path $atRoot '.harness/insight-index.md')

$atRoot = New-Sandbox
Write-Fixture (Join-Path $atRoot '.harness/insight-index.md') @(
    '# Insight Index — fixture',
    '',
    '- 2026-01-01 · stored one',
    '## Stray heading in the index'
)
Write-Fixture (Join-Path $atRoot 'docs/features/x8i/07_DELIVERY.md') @(
    '# 07', '', '## Insight', '', '- new one', '', '## Verdict'
)
Copy-Item (Join-Path $atRoot '.harness/insight-index.md') (Join-Path $atRoot 'index.before') -Force
Invoke-At @('-Task', 'x8i')
Assert-Eq 'X-8 index: exit status is 3' '3' ([string]$atExit)
Assert-Has 'X-8 index: diagnostic names the index path and the ## line' 'insight-index.md:4: unaccounted line: ## Stray heading in the index' $atErr
Assert-Has 'X-8 index: the heading is UNACCOUNTED, not a continuation' 'Index tally: entries 1, unaccounted lines 1, entries after run 1' $atOut
Assert-FilesEq 'X-8 index: index byte-identical' (Join-Path $atRoot 'index.before') (Join-Path $atRoot '.harness/insight-index.md')

# =========================================================================
Write-Banner 'X-9 — an unterminated final line that is a CONTINUATION line survives the read'
$atRoot = New-Sandbox
Write-Fixture (Join-Path $atRoot '.harness/insight-index.md') @('# Insight Index — fixture')
Write-Fixture (Join-Path $atRoot 'docs/features/x9/07_DELIVERY.md') @(
    '# 07',
    '',
    '## Insight',
    '',
    '- 2026-02-01 · a fact that wraps',
    '  its continuation · evidence: z:3'
) -AtNoFinalNewline
$atFixBytes = [System.IO.File]::ReadAllBytes((Join-Path $atRoot 'docs/features/x9/07_DELIVERY.md'))
$atNoNl = 'no'
if ($atFixBytes[$atFixBytes.Length - 1] -ne 10) { $atNoNl = 'yes' }
Assert-Eq 'X-9 fixture really has no trailing newline' 'yes' $atNoNl
Invoke-At @('-Task', 'x9')
Assert-Eq 'X-9 exit status' '0' ([string]$atExit)
Assert-Has 'X-9 the unterminated final line is counted as a continuation' 'Insight tally: entries 1, continuation lines 1, ignorable lines 1 (terminal footer 0), unaccounted lines 0' $atOut
$atIdxLines = @(Get-Content -Path (Join-Path $atRoot '.harness/insight-index.md'))
Assert-Eq 'X-9 the unterminated final line reaches the index verbatim' '  its continuation · evidence: z:3' ($atIdxLines[$atIdxLines.Count - 1])

# =========================================================================
Write-Banner 'X-10 — an unbalanced <!-- in the index is MEASURED: refuse, do not corrupt'
$atRoot = New-Sandbox
Write-Fixture (Join-Path $atRoot '.harness/insight-index.md') @(
    '# Insight Index — fixture',
    '',
    '<!-- Append new insights below, one per line. Format:',
    '',
    '- 2026-01-01 · stored one'
)
Write-Fixture (Join-Path $atRoot 'docs/features/x10/07_DELIVERY.md') @(
    '# 07', '', '## Insight', '', '- new one', '', '## Verdict'
)
Copy-Item (Join-Path $atRoot '.harness/insight-index.md') (Join-Path $atRoot 'index.before') -Force
Invoke-At @('-Task', 'x10')
Assert-Eq 'X-10 exit status is 3 (refuses rather than appending inside the open comment)' '3' ([string]$atExit)
Assert-Has 'X-10 diagnostic names the unterminated comment opening line' 'insight-index.md:3: unterminated HTML comment opened here: <!-- Append new insights below, one per line. Format:' $atErr
Assert-Has 'X-10 tally: whole file is header block, 0 entries, 1 unaccounted' 'Index tally: entries 0, unaccounted lines 1, entries after run 0' $atOut
Assert-FilesEq 'X-10 index byte-identical (nothing appended inside the comment)' (Join-Path $atRoot 'index.before') (Join-Path $atRoot '.harness/insight-index.md')
$atI4 = Get-I4Line $atRoot
Assert-Has 'X-10 I.4 reports non-PASS over the same index' 'WARN' $atI4
Assert-Has 'X-10 I.4 names 0 entries and the unterminated line' '0 entries, 1 unaccounted line(s), first at line 3' $atI4

# =========================================================================
Write-Banner 'B-12 / BC-23 — dry run'
$atRoot = New-Sandbox
Write-Fixture (Join-Path $atRoot '.harness/insight-index.md') @(
    '# Insight Index — fixture', '', '- 2026-01-01 · stored one'
)
Write-Fixture (Join-Path $atRoot 'docs/features/dry/07_DELIVERY.md') @(
    '# 07', '', '## Insight', '', '- new one', '  its continuation · evidence: d:1', '', '## Verdict'
)
Copy-Item (Join-Path $atRoot '.harness/insight-index.md') (Join-Path $atRoot 'index.before') -Force
Invoke-At @('-Task', 'dry', '-DryRun')
$atDryExit = $atExit
$atDryOut = $atOut
Assert-Eq 'B-12 dry-run exit status' '0' ([string]$atDryExit)
Assert-FilesEq 'B-12 dry-run wrote nothing' (Join-Path $atRoot 'index.before') (Join-Path $atRoot '.harness/insight-index.md')
if (Test-Path (Join-Path $atRoot 'docs/features/dry')) { Add-Ok 'B-12 dry-run did not move the task dir' } else { Add-No 'B-12 dry-run did not move the task dir' 'moved' }
Invoke-At @('-Task', 'dry')
Assert-Eq 'B-12 real-run exit status equals the dry-run status' ([string]$atDryExit) ([string]$atExit)
Assert-Has 'B-12 real-run section tally equals the dry-run tally' 'Insight tally: entries 1, continuation lines 1, ignorable lines 2 (terminal footer 0), unaccounted lines 0' $atOut
Assert-Has 'B-12 dry-run section tally equals the real-run tally' 'Insight tally: entries 1, continuation lines 1, ignorable lines 2 (terminal footer 0), unaccounted lines 0' $atDryOut

$atRoot = New-Sandbox
Write-Fixture (Join-Path $atRoot 'docs/features/bc23/07_DELIVERY.md') @(
    '# 07', '', '## Insight', '', '- new one', '', '## Verdict'
)
Invoke-At @('-Task', 'bc23', '-DryRun')
Assert-Eq 'BC-23 post-change -DryRun against a missing index exits 0' '0' ([string]$atExit)
Assert-Has 'BC-23 missing-index warning still printed' 'insight-index.md missing' ($atOut + $atErr)
if (-not (Test-Path (Join-Path $atRoot '.harness/insight-index.md'))) {
    Add-Ok 'BC-23 dry-run created nothing'
} else {
    Add-No 'BC-23 dry-run created nothing' 'index was created'
}
Assert-Has 'BC-23 step 4 reached' '[DRY RUN] No files written.' $atOut

# =========================================================================
Write-Banner 'BC-1 / BC-2 — no heading, empty section; and a TAB-separated heading'
$atRoot = New-Sandbox
Write-Fixture (Join-Path $atRoot '.harness/insight-index.md') @('# Insight Index — fixture')
Copy-Item (Join-Path $atRoot '.harness/insight-index.md') (Join-Path $atRoot 'index.before') -Force
Write-Fixture (Join-Path $atRoot 'docs/features/bc1/07_DELIVERY.md') @(
    '# 07', '', '## Insight to surface', '', '- suffixed heading must NOT match'
)
Invoke-At @('-Task', 'bc1')
Assert-Eq 'BC-1 exit status' '0' ([string]$atExit)
Assert-Has 'BC-1 no matching heading -> 0 entries' 'Insight tally: entries 0, continuation lines 0, ignorable lines 0 (terminal footer 0), unaccounted lines 0' $atOut
Assert-FilesEq 'BC-1 index not written' (Join-Path $atRoot 'index.before') (Join-Path $atRoot '.harness/insight-index.md')
Assert-Has 'BC-1 a zero-count harvest reaches step 4' 'Archived task: bc1' $atOut

$atRoot = New-Sandbox
Write-Fixture (Join-Path $atRoot '.harness/insight-index.md') @('# Insight Index — fixture')
Copy-Item (Join-Path $atRoot '.harness/insight-index.md') (Join-Path $atRoot 'index.before') -Force
Write-Fixture (Join-Path $atRoot 'docs/features/bc2/07_DELIVERY.md') @(
    '# 07', '', '## Insight', '## Verdict', '', 'body'
)
Invoke-At @('-Task', 'bc2')
Assert-Eq 'BC-2 exit status' '0' ([string]$atExit)
Assert-Has 'BC-2 empty section -> 0 entries, 0 unaccounted' 'Insight tally: entries 0, continuation lines 0, ignorable lines 0 (terminal footer 0), unaccounted lines 0' $atOut
Assert-FilesEq 'BC-2 index not written' (Join-Path $atRoot 'index.before') (Join-Path $atRoot '.harness/insight-index.md')

$atRoot = New-Sandbox
Write-Fixture (Join-Path $atRoot '.harness/insight-index.md') @('# Insight Index — fixture')
$atTabDoc = "# 07`n`n##`tInsight`n`n- tab-separated heading fact`n`n## Verdict`n"
New-Item -ItemType Directory -Path (Join-Path $atRoot 'docs/features/tabhead') -Force | Out-Null
[System.IO.File]::WriteAllText((Join-Path $atRoot 'docs/features/tabhead/07_DELIVERY.md'), $atTabDoc, $atEnc)
Invoke-At @('-Task', 'tabhead')
Assert-Has 'matcher register: a literal-TAB heading separator still matches under .NET \s' 'Insight tally: entries 1, continuation lines 0, ignorable lines 2 (terminal footer 0), unaccounted lines 0' $atOut

# =========================================================================
Write-Banner 'BC-16 — pre-existing refusals unchanged'
$atRoot = New-Sandbox
Write-Fixture (Join-Path $atRoot '.harness/insight-index.md') @('# Insight Index — fixture')
Invoke-At @('-Task', 'nosuch')
$atNonZero = 'no'
if ($atExit -ne 0) { $atNonZero = 'yes' }
Assert-Eq 'BC-16 missing task directory exits non-zero' 'yes' $atNonZero
Assert-Has 'BC-16 missing task directory message' 'Task directory not found' ($atOut + $atErr)

New-Item -ItemType Directory -Path (Join-Path $atRoot 'docs/features/dup') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $atRoot 'docs/features/_archived/dup') -Force | Out-Null
Invoke-At @('-Task', 'dup')
$atNonZero = 'no'
if ($atExit -ne 0) { $atNonZero = 'yes' }
Assert-Eq 'BC-16 already-archived exits non-zero' 'yes' $atNonZero
Assert-Has 'BC-16 already-archived message' 'Task already archived' ($atOut + $atErr)

# =========================================================================
Write-Banner 'BC-10 — a missing index is created and the harvested entries land in it'
$atRoot = New-Sandbox
Write-Fixture (Join-Path $atRoot 'docs/features/bc10/07_DELIVERY.md') @(
    '# 07', '', '## Insight', '', '- new one', '  its continuation · evidence: m:1', '', '## Verdict'
)
Invoke-At @('-Task', 'bc10')
Assert-Eq 'BC-10 exit status' '0' ([string]$atExit)
Assert-Has 'BC-10 empty header block, 0 stored entries' 'Index tally: entries 0, unaccounted lines 0, entries after run 1' $atOut
if (Test-Path (Join-Path $atRoot '.harness/insight-index.md')) { Add-Ok 'BC-10 index created' } else { Add-No 'BC-10 index created' 'absent' }
$atIdxLines = @(Get-Content -Path (Join-Path $atRoot '.harness/insight-index.md'))
Assert-Eq 'BC-10 harvested entry written whole' '  its continuation · evidence: m:1' ($atIdxLines[$atIdxLines.Count - 1])

# =========================================================================
# QA-1 (round-3 MAJOR). Scanning only the FIRST '## Insight' heading and
# breaking discarded every later section at exit 0 with 'unaccounted lines 0'.
# The AC-4 pre/post leg that pins this against the git-extracted pre-change
# script is bash-only by design (B-11); these four cases are not.
Write-Banner 'QA-1 / B-11 — EVERY ## Insight section is harvested (multi-section)'
$atRoot = New-Sandbox
Write-Fixture (Join-Path $atRoot '.harness/insight-index.md') @(
    '# Insight Index — fixture',
    '- stored 1'
)
Write-Fixture (Join-Path $atRoot 'docs/features/qa1a/07_DELIVERY.md') @(
    '# 07 — Delivery',
    '',
    '## Insight',
    '',
    '- 2026-02-01 · harvested entry A · evidence: a:1',
    '',
    '## Verdict',
    '',
    'shipped',
    '',
    '## Insight',
    '',
    '- 2026-02-01 · harvested entry B · evidence: b:2',
    '  its continuation · evidence: c:3',
    '',
    '## End'
)
Invoke-At @('-Task', 'qa1a')
$atQa1aIdx = [System.IO.File]::ReadAllText((Join-Path $atRoot '.harness/insight-index.md'))
Assert-Eq 'QA-1 multi-section exit status' '0' ([string]$atExit)
Assert-Has 'QA-1 multi-section tally counts BOTH sections' 'Insight tally: entries 2, continuation lines 1, ignorable lines 4 (terminal footer 0), unaccounted lines 0' $atOut
Assert-Has 'QA-1 multi-section index tally' 'Index tally: entries 1, unaccounted lines 0, entries after run 3' $atOut
Assert-Has 'QA-1 first section''s entry reaches the index' '- 2026-02-01 · harvested entry A · evidence: a:1' $atQa1aIdx
Assert-Has 'QA-1 SECOND section''s entry reaches the index (the counterexample line)' '- 2026-02-01 · harvested entry B · evidence: b:2' $atQa1aIdx
Assert-Has 'QA-1 second section''s continuation line reaches the index' '  its continuation · evidence: c:3' $atQa1aIdx
Assert-HasNot 'QA-1 no quoted-heading notice on a document with no fence' 'Quoted headings:' $atOut

# =========================================================================
# The delivery-time variant: a document ABOUT this section quotes the heading
# inside a fenced block. Pre-fix the quote WAS the section, so a documentation
# example plus a bare fence line were written to the index, a real entry was
# rotated out to history, every real insight was lost, and the run exited 0.
Write-Banner 'QA-1 (delivery variant) — a ## Insight heading inside a FENCED block is not a heading'
$atRoot = New-Sandbox
Write-Fixture (Join-Path $atRoot '.harness/insight-index.md') @(
    '# Insight Index — fixture',
    '- stored 1'
)
Write-Fixture (Join-Path $atRoot 'docs/features/qa1b/07_DELIVERY.md') @(
    '# 07 — Delivery',
    '',
    'The developer writes insights under a heading like this:',
    '',
    '```',
    '## Insight',
    '',
    '- an example bullet that is documentation, not an insight',
    '```',
    '',
    '## Insight',
    '',
    '- 2026-02-01 · the REAL insight · evidence: a:1',
    '',
    '## Verdict'
)
Invoke-At @('-Task', 'qa1b')
$atQa1bIdx = [System.IO.File]::ReadAllText((Join-Path $atRoot '.harness/insight-index.md'))
Assert-Eq 'QA-1 fenced-heading exit status' '0' ([string]$atExit)
Assert-Has 'QA-1 fenced-heading tally is the REAL section''s' 'Insight tally: entries 1, continuation lines 0, ignorable lines 2 (terminal footer 0), unaccounted lines 0' $atOut
Assert-Has 'QA-1 the real section''s entry reaches the index' '- 2026-02-01 · the REAL insight · evidence: a:1' $atQa1bIdx
Assert-HasNot 'QA-1 no fence line reaches the index' '```' $atQa1bIdx
Assert-HasNot 'QA-1 the quoted documentation example does not reach the index' 'documentation, not an insight' $atQa1bIdx
Assert-Eq 'QA-1 fenced-heading index holds header + stored + 1 harvested line' '3' ([string](@(Get-Content -Path (Join-Path $atRoot '.harness/insight-index.md'))).Count)
# Skipping a quoted heading is a DECISION and the run SAYS SO. Without this the
# rule would be a second silent channel: a reader could only infer "a heading
# was ignored" from an entry that never arrived — which is the shape of the
# defect this task exists to remove.
Assert-Has 'QA-1 the skipped quoted heading is REPORTED, not silent' "Quoted headings: 1 '## Insight' heading(s) inside a code fence were not harvested" $atOut

# =========================================================================
# Tracking fences opens one new way to LOSE a section: a fence left open hides
# every later heading. That is refused, not absorbed — the same treatment the
# index's unbalanced '<!--' gets (X-10), for the same reason.
Write-Banner 'QA-1 — a code fence left OPEN at EOF refuses, it does not hide the section'
$atRoot = New-Sandbox
Write-Fixture (Join-Path $atRoot '.harness/insight-index.md') @(
    '# Insight Index — fixture',
    '- stored 1'
)
Write-Fixture (Join-Path $atRoot 'expected-index') @(
    '# Insight Index — fixture',
    '- stored 1'
)
Write-Fixture (Join-Path $atRoot 'docs/features/qa1c/07_DELIVERY.md') @(
    '# 07 — Delivery',
    '',
    '```',
    '## Insight',
    '',
    '- documentation example',
    '',
    '## Insight',
    '',
    '- the real one · evidence: a:1'
)
Invoke-At @('-Task', 'qa1c')
Assert-Eq 'QA-1 unterminated fence exit status' '3' ([string]$atExit)
Assert-Has 'QA-1 unterminated fence counts as unaccounted' 'Insight tally: entries 0, continuation lines 0, ignorable lines 0 (terminal footer 0), unaccounted lines 1' $atOut
Assert-Has 'QA-1 unterminated fence names its opening line' '07_DELIVERY.md:3: unterminated code fence opened here: ' $atErr
Assert-FilesEq 'QA-1 unterminated fence: index byte-identical (nothing written)' (Join-Path $atRoot 'expected-index') (Join-Path $atRoot '.harness/insight-index.md')
Assert-Has 'QA-1 unterminated fence: both swallowed headings are counted and reported' 'Quoted headings: 2 ' $atOut

# =========================================================================
# The BOUND of the fenced-heading rule, measured and SIGNALLED rather than
# assumed: a section that lies ENTIRELY inside a fence is quoted, so it is not
# harvested — 0 entries at exit 0. That is only acceptable because the run
# names it; the 'Quoted headings:' line is the whole difference between a
# stated bound and the silent discard QA-1 was.
Write-Banner 'QA-1 bound — a section entirely inside a fence is quoted: 0 entries, and the run SAYS SO'
$atRoot = New-Sandbox
Write-Fixture (Join-Path $atRoot '.harness/insight-index.md') @(
    '# Insight Index — fixture',
    '- stored 1'
)
Write-Fixture (Join-Path $atRoot 'expected-index') @(
    '# Insight Index — fixture',
    '- stored 1'
)
Write-Fixture (Join-Path $atRoot 'docs/features/qa1e/07_DELIVERY.md') @(
    '# 07 — Delivery',
    '',
    'An example of the whole section, quoted:',
    '',
    '```',
    '## Insight',
    '',
    '- 2026-02-01 · quoted, not authored · evidence: a:1',
    '```',
    '',
    '## Verdict'
)
Invoke-At @('-Task', 'qa1e')
Assert-Eq 'QA-1 bound exit status' '0' ([string]$atExit)
Assert-Has 'QA-1 bound harvests nothing' 'Insight tally: entries 0, continuation lines 0, ignorable lines 0 (terminal footer 0), unaccounted lines 0' $atOut
Assert-Has 'QA-1 bound: the ignored heading is reported on stdout' 'Quoted headings: 1 ' $atOut
Assert-FilesEq 'QA-1 bound: index unchanged' (Join-Path $atRoot 'expected-index') (Join-Path $atRoot '.harness/insight-index.md')

# =========================================================================
# MEASURED RESIDUAL, not an endorsement. Fence awareness is scoped to SECTION
# DISCOVERY. A fence INSIDE the section is still classified by pass B, so its
# lines are absorbed as continuation lines of the preceding entry. That channel
# adds content to the index; it never discards any.
Write-Banner 'QA-1 residual — a fence INSIDE the section is absorbed, never dropped'
$atRoot = New-Sandbox
Write-Fixture (Join-Path $atRoot '.harness/insight-index.md') @(
    '# Insight Index — fixture',
    '- stored 1'
)
Write-Fixture (Join-Path $atRoot 'docs/features/qa1d/07_DELIVERY.md') @(
    '# 07 — Delivery',
    '',
    '## Insight',
    '',
    '- 2026-02-01 · one · evidence: a:1',
    '```json',
    '{"a": 1}',
    '```',
    '- 2026-02-01 · two · evidence: b:2',
    '',
    '## Verdict'
)
Invoke-At @('-Task', 'qa1d')
Assert-Eq 'QA-1 residual exit status' '0' ([string]$atExit)
Assert-Has 'QA-1 residual: the 3 fenced lines are counted as CONTINUATION, not dropped' 'Insight tally: entries 2, continuation lines 3, ignorable lines 2 (terminal footer 0), unaccounted lines 0' $atOut
Assert-Has 'QA-1 residual: the fenced body reaches the index verbatim' '{"a": 1}' ([System.IO.File]::ReadAllText((Join-Path $atRoot '.harness/insight-index.md')))

# =========================================================================
# The TILDE half of the fence state machine (CR-13). $atReFence accepts '~{3,}'
# and the tilde branch is NOT a copy of the backtick branch: a tilde opener's
# info string is unrestricted, where a backtick opener's may hold no backtick
# (archive-task.ps1:296). Every other fixture in this driver uses backticks, so
# that branch was code-correct and pinned by nothing. This is the qa1b shape
# rewritten with '~~~', exercising all three tilde-only paths in one fixture:
# the OPENER whose info string CONTAINS a backtick (a backtick fence with that
# info string would not open at all — if it failed to open here, the quoted
# heading would become the section and the tally would read entries 2); the
# mismatched closer (the backtick run inside does NOT close a tilde fence); and
# the CLOSER (if '~~~' failed to close, the fence would be open at EOF and the
# run would refuse at exit 3). NOTE every fixture line below is single-quoted,
# so PowerShell does not process the backticks inside them.
Write-Banner 'QA-1 / CR-13 — the TILDE fence branch: opener with a backtick info string, mismatched backtick fence inside, tilde closer'
$atRoot = New-Sandbox
Write-Fixture (Join-Path $atRoot '.harness/insight-index.md') @(
    '# Insight Index — fixture',
    '- stored 1'
)
Write-Fixture (Join-Path $atRoot 'docs/features/qa1f/07_DELIVERY.md') @(
    '# 07 — Delivery',
    '',
    'The quoted example itself contains a backtick fence, so the outer fence is a tilde one:',
    '',
    '~~~markdown with a `backtick` in the info string',
    '## Insight',
    '',
    '- an example bullet that is documentation, not an insight',
    '',
    '```',
    'inner backtick fence — not a closer for a tilde fence',
    '```',
    '~~~',
    '',
    '## Insight',
    '',
    '- 2026-02-01 · the REAL insight · evidence: a:1',
    '',
    '## Verdict'
)
Invoke-At @('-Task', 'qa1f')
$atQa1fIdx = [System.IO.File]::ReadAllText((Join-Path $atRoot '.harness/insight-index.md'))
Assert-Eq 'CR-13 tilde fence exit status (the ~~~ closer really closed it)' '0' ([string]$atExit)
Assert-Has 'CR-13 tilde fence tally is the REAL section''s' 'Insight tally: entries 1, continuation lines 0, ignorable lines 2 (terminal footer 0), unaccounted lines 0' $atOut
Assert-Has 'CR-13 the real section''s entry reaches the index' '- 2026-02-01 · the REAL insight · evidence: a:1' $atQa1fIdx
Assert-HasNot 'CR-13 the tilde-quoted documentation example does not reach the index' 'documentation, not an insight' $atQa1fIdx
Assert-Has 'CR-13 the heading quoted inside a TILDE fence is reported, not silent' "Quoted headings: 1 '## Insight' heading(s) inside a code fence were not harvested" $atOut

# =========================================================================
# CR-5: this case is NOT bash-only. Its mechanism (K-36 — mutate a copy of the
# live artifact and re-run the gate over it) is shell-agnostic, and the damage
# it guards against lands in GENERATED projects, which run verify_all.ps1 on
# Windows. Get-I4Line returns the [I.4] STATUS line alone, so a PASS/WARN row
# anchored on it cannot accidentally match a neighbouring check's verdict — the
# bash twin needs an explicit i4_head() filter to get the same guarantee,
# because its step() prints a WARN detail on the FOLLOWING line (D-4).
Write-Banner 'AC-7 — I.4 unaccounted condition is non-vacuous (mutation of the ARTIFACT)'
$atRoot = New-Sandbox
Copy-Item -Path (Join-Path $repoRoot '.harness/insight-index.md') `
          -Destination (Join-Path $atRoot '.harness/insight-index.md') -Force
$atCleanI4 = Get-I4Line $atRoot
Assert-Has 'AC-7 unmutated copy of the live index: I.4 PASSes' 'PASS' $atCleanI4
# INSERTION, never a deletion — a deletion would remove another assertion's
# container (insight 2026-08-01). The prose carries no I.6 banned anchor.
[System.IO.File]::AppendAllText(
    (Join-Path $atRoot '.harness/insight-index.md'),
    "`nan ordinary prose line that is neither a bullet nor a continuation`n",
    $atEnc)
$atDirtyI4 = Get-I4Line $atRoot
Assert-Has 'AC-7 mutated copy: I.4 reports non-PASS' 'WARN' $atDirtyI4
Assert-Has 'AC-7 mutated copy: I.4 names the unaccounted count' '1 unaccounted line(s)' $atDirtyI4

# =========================================================================
Write-Banner 'AC-3 — one file never yields two entry counts (rotation result)'
$atRoot = New-Sandbox
$atFix = [System.Collections.Generic.List[string]]::new()
$atFix.Add('# Insight Index — fixture')
$atFix.Add('- 2026-01-01 · stored wrapped')
$atFix.Add('  its continuation · evidence: w:1')
for ($atI = 2; $atI -le 30; $atI++) { $atFix.Add(('- stored {0:d2}' -f $atI)) }
Write-Fixture (Join-Path $atRoot '.harness/insight-index.md') $atFix.ToArray()
Write-Fixture (Join-Path $atRoot 'docs/features/ac3/07_DELIVERY.md') @(
    '# 07', '', '## Insight', '', '- new one', '', '## Verdict'
)
Invoke-At @('-Task', 'ac3')
Assert-Eq 'AC-3 rotation run exit status' '0' ([string]$atExit)
Assert-Has 'AC-3 archive-task reports 30 entries after the run' 'Index tally: entries 30, unaccounted lines 0, entries after run 30' $atOut
$atI4 = Get-I4Line $atRoot
Assert-Has 'AC-3 I.4 agrees the rotation result is within the cap' 'PASS' $atI4
Assert-Eq 'AC-3 K-61 equality over the rotation result (raw 30 == entries 30)' '30' ([string](Get-RawMarkers (Join-Path $atRoot '.harness/insight-index.md')))

# =========================================================================
Write-Host ''
Write-Host '=== test-archive-task summary ===' -ForegroundColor Cyan
Write-Host ('  PASS: {0}' -f $atPass) -ForegroundColor Green
Write-Host ('  FAIL: {0}' -f $atFail) -ForegroundColor Red
foreach ($atD in $atSandboxes) {
    if (Test-Path $atD) { Remove-Item -Path $atD -Recurse -Force -ErrorAction SilentlyContinue }
}
if ($atFail -gt 0) {
    Write-Host ''
    Write-Host 'Failures:' -ForegroundColor Red
    foreach ($atF in $atFailures) { Write-Host ('  - {0}' -f $atF) -ForegroundColor Red }
    exit 1
}
exit 0

} finally { Pop-Location }
