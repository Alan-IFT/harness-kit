# test-guard-rm.ps1 — Drive evals/guard-rm-cases.md against scripts/guard-rm.ps1
#
# Out-of-scope for verify_all (v0.15): runs only on demand. Acceptance B2 of
# T-001 / ai-safety-guardrails — at least 11 input/expected pairs.

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
$guard = Join-Path $repoRoot 'scripts/guard-rm.ps1'
Push-Location $repoRoot
try {

# Each case: @{ cmd; env (override yes/no); expected (ALLOW|BLOCK) }
$cases = @(
    @{ id = 1;  cmd = 'rm -rf /';                                         override = $false; expected = 'BLOCK' }
    @{ id = 2;  cmd = 'rm -rf /etc';                                      override = $false; expected = 'BLOCK' }
    @{ id = 3;  cmd = 'rm -rf ~/Desktop/foo';                             override = $false; expected = 'BLOCK' }
    @{ id = 4;  cmd = 'rm -rf ../../../tmp';                              override = $false; expected = 'BLOCK' }
    @{ id = 5;  cmd = 'rm -rf build/';                                    override = $false; expected = 'ALLOW' }
    @{ id = 6;  cmd = 'rm -rf node_modules';                              override = $false; expected = 'ALLOW' }
    @{ id = 7;  cmd = 'Remove-Item -Recurse C:\Windows';                  override = $false; expected = 'BLOCK' }
    @{ id = 8;  cmd = 'pwsh -c "Remove-Item -Recurse C:\Windows"';        override = $false; expected = 'BLOCK' }
    @{ id = 9;  cmd = 'find /etc -delete';                                override = $false; expected = 'BLOCK' }
    @{ id = 10; cmd = "find . -name '*.log' -delete";                     override = $false; expected = 'ALLOW' }
    @{ id = 11; cmd = 'rm -rf /etc/foo';                                  override = $true;  expected = 'ALLOW' }
    # v0.15.1 rollback hardening — regressions for D-1 / D-2 (find-predicate-skip applied to every verb).
    @{ id = 12; cmd = 'Remove-Item -Path C:\Windows -Recurse';            override = $false; expected = 'BLOCK' }
    @{ id = 13; cmd = 'rm -name /etc/passwd';                             override = $false; expected = 'BLOCK' }
    @{ id = 14; cmd = 'rm -path /etc -delete';                            override = $false; expected = 'BLOCK' }
    @{ id = 15; cmd = 'rm -type f /etc/x';                                override = $false; expected = 'BLOCK' }
    @{ id = 16; cmd = 'rm -mtime +0 /etc/x';                              override = $false; expected = 'BLOCK' }
    @{ id = 17; cmd = "find /tmp -name '*.log' -delete";                  override = $false; expected = 'BLOCK' }
)

$pass = 0
$fail = 0
$failures = @()

foreach ($c in $cases) {
    $payload = @{ tool_input = @{ command = $c.cmd } } | ConvertTo-Json -Compress -Depth 10
    Remove-Item Env:HARNESS_ALLOW_OUTSIDE_RM -ErrorAction SilentlyContinue
    if ($c.override) { $env:HARNESS_ALLOW_OUTSIDE_RM = '1' }
    try {
        $payload | & pwsh -File $guard *>$null
        $exitCode = $LASTEXITCODE
    } catch {
        $exitCode = 99
    }
    if ($c.override) { Remove-Item Env:HARNESS_ALLOW_OUTSIDE_RM -ErrorAction SilentlyContinue }
    $actual = if ($exitCode -eq 0) { 'ALLOW' } elseif ($exitCode -eq 2) { 'BLOCK' } else { "UNKNOWN(exit=$exitCode)" }
    if ($actual -eq $c.expected) {
        Write-Host ("  PASS  case {0,2}: {1} -> {2}" -f $c.id, $c.cmd, $actual) -ForegroundColor Green
        $pass++
    } else {
        Write-Host ("  FAIL  case {0,2}: {1} -> got {2}, expected {3}" -f $c.id, $c.cmd, $actual, $c.expected) -ForegroundColor Red
        $fail++
        $failures += "case $($c.id): expected $($c.expected), got $actual"
    }
}

Write-Host ""
Write-Host "=== test-guard-rm summary ===" -ForegroundColor Cyan
Write-Host "  PASS: $pass" -ForegroundColor Green
Write-Host "  FAIL: $fail" -ForegroundColor Red
if ($fail -gt 0) {
    Write-Host ""
    Write-Host "Failures:" -ForegroundColor Red
    foreach ($f in $failures) { Write-Host "  - $f" -ForegroundColor Red }
    exit 1
}
exit 0

} finally { Pop-Location }
