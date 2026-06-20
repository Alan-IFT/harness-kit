# entropy-cadence.ps1 — Shared remind-if-due cadence unit for the entropy watch (Windows half).
#
# ONE definition of the entropy-sweep due-logic and threshold literal, called by BOTH
# /harness-stream (T-11a) and (later) /harness (T-11b) so neither restates the threshold.
# Reads/writes the tiny key=value state file `.harness/entropy-watch.state`.
#
# CLI:
#   entropy-cadence.ps1 check [--first-of-session]   -> stdout: DUE | NOT-DUE   (no write)
#   entropy-cadence.ps1 delivered                    -> stdout: count=<n>       (increment + write)
#   entropy-cadence.ps1 swept                         -> stdout: reset           (reset + stamp + write)
#
# Due logic (the ONLY place the threshold lives):
#   N = 5
#   due = (count >= N) OR (first_of_session AND count >= 1)
#
# FAIL-OPEN CONTRACT: any state-file problem (absent / malformed / unreadable / unwritable)
# resolves `check` to NOT-DUE and NEVER exits non-zero — a drain or delivery must never be
# blocked by cadence I/O. Mirrors the ambient-hook fail-open (always exit 0).
#
# Byte-symmetric with entropy-cadence.sh (NFR-3): UTF-8 / LF, the N=5 literal once per half.
# See skills/harness-stream/SKILL.md "On stream completion" and the design §2.

[CmdletBinding()]
param(
    [Parameter(Position = 0)] [string]$Command,
    [Parameter(Position = 1)] [string]$Flag
)

$ErrorActionPreference = 'SilentlyContinue'

# The one threshold literal (deliveries-since-sweep that makes the watch due).
$N = 5

# Walk up to nearest .git/ ancestor of cwd (same robust pattern as ambient-reset /
# guard-rm; NOT $PSScriptRoot arithmetic — insight 2026-06-04). Fail-open on no root.
$dir = (Get-Location).Path
$repoRoot = $null
while ($dir) {
    if (Test-Path (Join-Path $dir '.git')) { $repoRoot = $dir; break }
    $parent = Split-Path $dir -Parent
    if (-not $parent -or $parent -eq $dir) { break }
    $dir = $parent
}

# Resolve the state file path. With no repo root we still fail open below.
$stateFile = $null
if ($repoRoot) { $stateFile = Join-Path $repoRoot '.harness/entropy-watch.state' }

# Read delivered_since_sweep from the state file; fail-open to 0 on any problem.
function Read-Count {
    if (-not $stateFile -or -not (Test-Path -LiteralPath $stateFile)) { return 0 }
    try {
        $n = $null
        foreach ($line in (Get-Content -LiteralPath $stateFile -ErrorAction Stop)) {
            if ($line -like 'delivered_since_sweep=*') { $n = $line.Substring('delivered_since_sweep='.Length) }
        }
        if ($n -match '^[0-9]+$') { return [int]$n }
        return 0
    } catch { return 0 }
}

# Read last_sweep (may be empty/absent before the first sweep — never an error).
function Read-LastSweep {
    if (-not $stateFile -or -not (Test-Path -LiteralPath $stateFile)) { return '' }
    try {
        $v = ''
        foreach ($line in (Get-Content -LiteralPath $stateFile -ErrorAction Stop)) {
            if ($line -like 'last_sweep=*') { $v = $line.Substring('last_sweep='.Length) }
        }
        return $v
    } catch { return '' }
}

# Write the state file (two key=value lines, UTF-8 / LF, no BOM via raw-byte write —
# insight 2026-06-12 / T-021). Fail-open: never throw on a write failure — emit a
# stderr note and carry on.
function Write-State {
    param([int]$Count, [string]$LastSweep)
    if (-not $stateFile) { [Console]::Error.WriteLine('entropy-cadence: no repo root; state not written'); return }
    try {
        $d = Split-Path $stateFile -Parent
        if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force -ErrorAction Stop | Out-Null }
        $body = "delivered_since_sweep=$Count`nlast_sweep=$LastSweep`n"
        $bytes = [System.Text.UTF8Encoding]::new($false).GetBytes($body)
        [System.IO.File]::WriteAllBytes($stateFile, $bytes)
    } catch {
        [Console]::Error.WriteLine("entropy-cadence: cannot write $stateFile; ignored")
    }
}

switch ($Command) {
    'check' {
        $firstOfSession = ($Flag -eq '--first-of-session')
        $count = Read-Count
        # due = (count >= N) OR (first_of_session AND count >= 1)
        if (($count -ge $N) -or ($firstOfSession -and $count -ge 1)) {
            Write-Output 'DUE'
        } else {
            Write-Output 'NOT-DUE'
        }
        exit 0
    }
    'delivered' {
        $count = (Read-Count) + 1
        Write-State -Count $count -LastSweep (Read-LastSweep)
        Write-Output "count=$count"
        exit 0
    }
    'swept' {
        $now = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        Write-State -Count 0 -LastSweep $now
        Write-Output 'reset'
        exit 0
    }
    default {
        # Unknown / missing sub-command: fail-open (never block a caller), exit 0.
        [Console]::Error.WriteLine('entropy-cadence: usage: check [--first-of-session] | delivered | swept')
        exit 0
    }
}
