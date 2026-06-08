# upgrade-project.ps1 — Deterministic mechanical layer for /harness-upgrade (T-012).
#
# Brings an already-initialized but STALE harness project up to the current plugin
# layout: relocate scripts to .harness/scripts/, content-refresh the depth-sensitive
# scripts from the current template (so their two-up repo-root derivation is correct —
# relocation alone is NOT enough; see insight L31 / DO-1), re-install the pre-commit
# hook, rewire .claude/settings.json hook paths (raw-text, never re-serialized), and
# regenerate verify_all from the current type template while preserving the user's
# B.* customizations.
#
# This is the deterministic transform. The /harness-upgrade SKILL owns all judgment
# (cache + version discovery, project-type detection via AskUserQuestion, plan/confirm,
# the verify_all-HALT confirm, final reporting). The helper does ZERO cache discovery —
# the SKILL passes the resolved template root via -TemplateRoot.
#
# Run from the PROJECT ROOT (the directory that contains .git/, .claude/, scripts/ or
# .harness/scripts/). cwd-derived, so it works whether bootstrapped under scripts/
# (pre-relocation) or .harness/scripts/ (post-relocation).
#
# Usage:
#   pwsh -File upgrade-project.ps1 -TemplateRoot <abs> -Type generic -Stack "Rust CLI"
#   pwsh -File upgrade-project.ps1 -TemplateRoot <abs> -Type fullstack -DryRun
#
# Machine-readable stdout (one record per line, pipe-delimited, stable verb prefix so
# the AI layer can grep without locale/format issues):
#   PLAN|<verb>|<detail>          (dry-run plan lines)
#   RESULT|<verb>|<detail>        (applied actions)
#   GAP|<id>|<present|absent>|<detail>
#   TYPE|<type>
#   BAK|<path>
#   CONFLICT|<kind>|<detail>
#   SUMMARY|added=<n> moved=<n> rewritten=<n> rewired=<n> conflicts=<n>
# <verb> in: MOVE REFRESH REWIRE HOOK-INSTALL HOOK-SKIP VERIFY-REGEN VERIFY-SPLICE
#            VERIFY-HALT SKIP NOOP
#
# Exit codes:
#   0  success (applied / nothing-to-do / dry-run printed)
#   1  user/precondition error (not a harness project; missing -TemplateRoot; bad -Type)
#   2  refresh-blocked: verify_all B.* could not be cleanly delimited AND not --force
#   3  hook conflict surfaced (non-stock pre-commit); other steps still completed

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Force,
    [ValidateSet("fullstack", "backend", "generic")]
    [string]$Type,
    [string]$Stack,
    [string]$ProjectName,
    [string]$TemplateRoot,
    [string]$Today
)

$ErrorActionPreference = "Stop"

$root = (Get-Location).Path

# --- preconditions ---------------------------------------------------------------
if (-not $TemplateRoot) {
    [Console]::Error.WriteLine("upgrade-project: -TemplateRoot is required (the resolved plugin template cache root).")
    exit 1
}
$templateCommonScripts = Join-Path $TemplateRoot "skills/harness-init/templates/common/.harness/scripts"
$templateTypeScripts   = Join-Path $TemplateRoot ("skills/harness-init/templates/{0}/.harness/scripts" -f $Type)
if (-not (Test-Path $templateCommonScripts)) {
    [Console]::Error.WriteLine("upgrade-project: template common scripts not found at $templateCommonScripts.")
    exit 1
}
if (-not $Type) {
    [Console]::Error.WriteLine("upgrade-project: -Type is required (fullstack|backend|generic).")
    exit 1
}
if (-not (Test-Path $templateTypeScripts)) {
    [Console]::Error.WriteLine("upgrade-project: template type scripts not found at $templateTypeScripts.")
    exit 1
}

# Must look like SOME harness project: .claude/settings.json OR .harness/ OR scripts/harness-sync.*
$hasSettings   = Test-Path (Join-Path $root ".claude/settings.json")
$hasHarnessDir = Test-Path (Join-Path $root ".harness")
$hasOldSync    = (Test-Path (Join-Path $root "scripts/harness-sync.ps1")) -or (Test-Path (Join-Path $root "scripts/harness-sync.sh"))
if (-not ($hasSettings -or $hasHarnessDir -or $hasOldSync)) {
    [Console]::Error.WriteLine("upgrade-project: this does not look like a harness project (no .claude/settings.json, no .harness/, no scripts/harness-sync.*). Use /harness-adopt for a no-harness project.")
    exit 1
}

if (-not $ProjectName) { $ProjectName = Split-Path $root -Leaf }
if (-not $Today)       { $Today = (Get-Date).ToString("yyyy-MM-dd") }

$stamp = (Get-Date).ToString("yyyyMMddTHHmmss")

# counters
$nMoved = 0; $nRewritten = 0; $nRewired = 0; $nAdded = 0; $nConflicts = 0
$exitCode = 0

function Emit($line) { Write-Output $line }

Emit ("TYPE|{0}" -f $Type)

# --- S1 relocation (verbatim known-set + git-mv-preserving + SKIP-unless-Force) ---
# Inlined from migrate-scripts-layout.ps1 so the upgrade is a single self-contained
# helper. The known set is filename-preserved (NOT a blanket scripts/*).
# INVARIANT: $refreshSet (S2 below) == $known minus verify_all.{ps1,sh} and baseline.json.
# These two literal arrays are hand-maintained — if you edit one, update the other.
$known = @(
    "verify_all.ps1", "verify_all.sh",
    "harness-sync.ps1", "harness-sync.sh",
    "guard-rm.ps1", "guard-rm.sh",
    "install-hooks.ps1", "install-hooks.sh",
    "archive-task.ps1", "archive-task.sh",
    "migrate-scripts-layout.ps1", "migrate-scripts-layout.sh",
    "baseline.json"
)
$srcDir = Join-Path $root "scripts"
$dstDir = Join-Path $root ".harness/scripts"
$inGit  = Test-Path (Join-Path $root ".git")

foreach ($name in $known) {
    $src = Join-Path $srcDir $name
    $dst = Join-Path $dstDir $name
    if (-not (Test-Path $src)) { continue }
    if ((Test-Path $dst) -and -not $Force) {
        Emit ("{0}|SKIP|scripts/{1} (already at .harness/scripts/{1}; -Force to overwrite)" -f ($(if ($DryRun) { "PLAN" } else { "RESULT" })), $name)
        continue
    }
    Emit ("{0}|MOVE|scripts/{1} -> .harness/scripts/{1}" -f ($(if ($DryRun) { "PLAN" } else { "RESULT" })), $name)
    $nMoved++
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
    }
}

# --- S2 content-refresh of depth-sensitive scripts (the L31 / DO-1 fix) -----------
# UNCONDITIONALLY byte-overwrite the refresh set from the current template (which is
# already two-up). Relocation alone preserves OLD one-up root derivation — this is
# what actually fixes the root-resolution hazard. verify_all is NOT in this set (it
# is regenerated from the type .tmpl in S5); baseline.json is data (relocate-only).
# INVARIANT: $refreshSet == $known (S1 above) minus verify_all.{ps1,sh} and baseline.json.
# Hand-maintained literal arrays — keep in sync; edit one, update the other.
$refreshSet = @(
    "harness-sync.ps1", "harness-sync.sh",
    "install-hooks.ps1", "install-hooks.sh",
    "archive-task.ps1", "archive-task.sh",
    "guard-rm.ps1", "guard-rm.sh",
    "migrate-scripts-layout.ps1", "migrate-scripts-layout.sh"
)
foreach ($name in $refreshSet) {
    $tmpl = Join-Path $templateCommonScripts $name
    if (-not (Test-Path $tmpl)) { continue }
    $dst = Join-Path $dstDir $name
    $identical = $false
    if (Test-Path $dst) {
        $identical = ((Get-FileHash $tmpl -Algorithm SHA256).Hash -eq (Get-FileHash $dst -Algorithm SHA256).Hash)
    }
    if ($identical) {
        Emit ("{0}|NOOP|.harness/scripts/{1} (already current)" -f ($(if ($DryRun) { "PLAN" } else { "RESULT" })), $name)
        continue
    }
    $isNew = -not (Test-Path $dst)
    Emit ("{0}|REFRESH|.harness/scripts/{1} (from current template)" -f ($(if ($DryRun) { "PLAN" } else { "RESULT" })), $name)
    if ($isNew) { $nAdded++ } else { $nRewritten++ }
    if (-not $DryRun) {
        if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
        Copy-Item -Path $tmpl -Destination $dst -Force
    }
}

# --- S3 settings rewire (verbatim raw-text replace; NEVER re-serialize — DO-3) -----
$settings = Join-Path $root ".claude/settings.json"
if (-not (Test-Path $settings)) {
    Emit "RESULT|SKIP|.claude/settings.json absent — settings rewire skipped (non-Claude-Code project)"
} else {
    $raw = Get-Content $settings -Raw
    $new = $raw.Replace("scripts/harness-sync.", ".harness/scripts/harness-sync.")
    $new = $new.Replace("scripts/guard-rm.", ".harness/scripts/guard-rm.")
    # Collapse the double prefix produced when an already-migrated `.harness/scripts/...`
    # substring matched the `scripts/...` target -> true fixed point (idempotent).
    $new = $new.Replace(".harness/.harness/scripts/", ".harness/scripts/")
    if ($new -cne $raw) {
        Emit ("{0}|REWIRE|.claude/settings.json (harness-sync + guard-rm hook paths)" -f ($(if ($DryRun) { "PLAN" } else { "RESULT" })))
        $nRewired++
        if (-not $DryRun) {
            $bak = "$settings.bak-$stamp"
            Copy-Item -Path $settings -Destination $bak -Force
            Emit ("BAK|{0}" -f $bak)
            [System.IO.File]::WriteAllText($settings, $new)
        }
    } else {
        Emit "RESULT|NOOP|.claude/settings.json already rewired"
    }
}

# --- S4 hook (re)install --------------------------------------------------------
# Stock-hook detection: compare the existing pre-commit body against the CURRENT
# stock body. The pre-T-007 stock hook differs only in the script path prefix
# (scripts/harness-sync. vs .harness/scripts/harness-sync.), so NORMALIZE that prefix
# in both bodies before comparing (F-4) — one normalized comparison covers both
# stock variants without keeping two full literal copies.
$currentHookBody = @'
#!/bin/sh
# harness-kit pre-commit hook.
# Blocks the commit if .harness/ has drifted from CLAUDE.md or .github/copilot-instructions.md.
# Tool-agnostic: catches edits from Claude Code, Copilot, Cursor, or hand-typed.
set -e
_drift=0
if command -v pwsh >/dev/null 2>&1 && [ -f .harness/scripts/harness-sync.ps1 ]; then
    pwsh -File .harness/scripts/harness-sync.ps1 -Check >/dev/null 2>&1 || _drift=1
elif command -v bash >/dev/null 2>&1 && [ -f .harness/scripts/harness-sync.sh ]; then
    bash .harness/scripts/harness-sync.sh --check >/dev/null 2>&1 || _drift=1
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

function Normalize-HookBody($s) {
    if ($null -eq $s) { return "" }
    # Collapse the old one-up path prefix to the new two-up prefix, then normalize
    # line endings, so the stock-vs-custom test ignores both path-depth and CRLF/LF.
    $n = $s.Replace("scripts/harness-sync.", ".harness/scripts/harness-sync.")
    $n = $n.Replace(".harness/.harness/scripts/harness-sync.", ".harness/scripts/harness-sync.")
    $n = $n.Replace("`r`n", "`n").Trim()
    return $n
}

$hookPath = Join-Path $root ".git/hooks/pre-commit"
$normCurrent = Normalize-HookBody $currentHookBody
if (-not (Test-Path (Join-Path $root ".git"))) {
    Emit "RESULT|SKIP|.git absent — pre-commit hook not installed"
} elseif (-not (Test-Path $hookPath)) {
    Emit ("{0}|HOOK-INSTALL|.git/hooks/pre-commit (was absent)" -f ($(if ($DryRun) { "PLAN" } else { "RESULT" })))
    if (-not $DryRun) {
        $hooksDir = Join-Path $root ".git/hooks"
        if (-not (Test-Path $hooksDir)) { New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null }
        # Trailing "`n": match the byte-for-byte output of install-hooks.sh / upgrade-project.sh
        # (both write the hook WITH a single trailing newline). Without it the two shells would
        # produce 1-byte-different hooks → a spurious cross-shell re-install + .bak (NFR-1 parity).
        [System.IO.File]::WriteAllText($hookPath, $currentHookBody + "`n")
        if ($IsLinux -or $IsMacOS) { & chmod +x $hookPath }
    }
} else {
    $existing = Get-Content $hookPath -Raw
    if ((Normalize-HookBody $existing) -eq $normCurrent) {
        $alreadyCurrent = (($existing.Replace("`r`n", "`n").Trim()) -eq ($currentHookBody.Replace("`r`n", "`n").Trim()))
        if ($alreadyCurrent) {
            Emit "RESULT|NOOP|.git/hooks/pre-commit already current"
        } else {
            Emit ("{0}|HOOK-INSTALL|.git/hooks/pre-commit (was stock pre-T-007; refreshed to new path)" -f ($(if ($DryRun) { "PLAN" } else { "RESULT" })))
            if (-not $DryRun) {
                $bak = "$hookPath.bak-$stamp"
                Copy-Item -Path $hookPath -Destination $bak -Force
                Emit ("BAK|{0}" -f $bak)
                # Trailing "`n": match install-hooks.sh / upgrade-project.sh byte-for-byte (NFR-1).
                [System.IO.File]::WriteAllText($hookPath, $currentHookBody + "`n")
                if ($IsLinux -or $IsMacOS) { & chmod +x $hookPath }
            }
        }
    } else {
        Emit "CONFLICT|hook|.git/hooks/pre-commit is non-stock (hand-customized) — NOT overwritten; merge the drift check in manually"
        $nConflicts++
        $exitCode = 3
    }
}

# --- S5 verify_all regenerate (splice / regen / halt) ---------------------------
$beginMarker = "# >>> HARNESS:B-CUSTOM:BEGIN"
$endMarker   = "# >>> HARNESS:B-CUSTOM:END"

function Get-MarkerBlock($lines) {
    # Returns @{ ok=$bool; startIdx; endIdx; block } where ok = exactly one BEGIN, one
    # END, BEGIN strictly before END. block = the lines BETWEEN the markers (exclusive).
    $begins = @(); $ends = @()
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].StartsWith($beginMarker)) { $begins += $i }
        elseif ($lines[$i].StartsWith($endMarker)) { $ends += $i }
    }
    if ($begins.Count -ne 1 -or $ends.Count -ne 1 -or $begins[0] -ge $ends[0]) {
        return @{ ok = $false }
    }
    $inner = @()
    for ($i = $begins[0] + 1; $i -lt $ends[0]; $i++) { $inner += $lines[$i] }
    return @{ ok = $true; startIdx = $begins[0]; endIdx = $ends[0]; block = $inner }
}

function Test-IsStubBlock($blockLines) {
    # Stub = every B.* check body is a bare SKIP/TODO (no real build/test/lint command).
    # Heuristic: no non-comment line that is NOT a SKIP step and NOT structural.
    foreach ($line in $blockLines) {
        $t = $line.Trim()
        if ($t -eq "") { continue }
        if ($t.StartsWith("#")) { continue }
        # bash stub:   step "B.1" "Build" "SKIP"
        # ps stub:     Step "B.x" "..." {  /  return "SKIP"  /  }  /  # TODO comments
        if ($t -match 'SKIP') { continue }
        if ($t -match '^Step\b' -or $t -match '^step\b') { continue }
        if ($t -eq '{' -or $t -eq '}') { continue }
        if ($t.StartsWith('return ')) { continue }
        # Any other live content => customized.
        return $false
    }
    return $true
}

function Test-OldBCustomized($lines) {
    # For an OLD verify_all that predates the HARNESS:B-CUSTOM markers: decide whether
    # the B.* region carries custom checks. Heuristic — any line that declares a B.*
    # step (bash `step "B.x" ... "PASS|FAIL|WARN"` with a non-SKIP status, or a real
    # build/test command token) is treated as customized. A region of only SKIP stubs
    # is NOT customized (safe to regenerate).
    foreach ($line in $lines) {
        $t = $line.Trim()
        # bash step with a non-SKIP terminal status on a B.* id
        if ($t -match '^step\s+"B\.' -and $t -notmatch '"SKIP"') { return $true }
        # explicit real commands commonly written into a customized B.* block
        if ($t -match '\b(cargo|pytest|npm|pnpm|yarn|go build|go test|dotnet|gradle|mvn|ruff|mypy|eslint|tsc)\b' -and $t -notmatch '^#') { return $true }
    }
    return $false
}

function Substitute-Placeholders($text) {
    # The placeholder tokens are assembled from pieces (o + NAME + c) rather than written
    # as double-brace literals, so this helper file does NOT itself contain an
    # unsubstituted placeholder token — keeps test-init's "no unresolved placeholders"
    # cleanliness check happy when the helper is copied into a generated project. These
    # are still the only 3 substituted names (the D.2-whitelisted set); no new placeholder.
    $o = "{{"; $c = "}}"
    $out = $text.Replace($o + "PROJECT_NAME" + $c, $ProjectName)
    $out = $out.Replace($o + "STACK" + $c, $(if ($Stack) { $Stack } else { $Type }))
    $out = $out.Replace($o + "TODAY" + $c, $Today)
    return $out
}

foreach ($shell in @("ps1", "sh")) {
    $proj = Join-Path $dstDir ("verify_all.{0}" -f $shell)
    $tmpl = Join-Path $templateTypeScripts ("verify_all.{0}.tmpl" -f $shell)
    if (-not (Test-Path $tmpl)) {
        Emit ("RESULT|SKIP|verify_all.{0} (no type template)" -f $shell)
        continue
    }
    $fresh = Substitute-Placeholders (Get-Content $tmpl -Raw)
    $freshLines = $fresh -split "`r?`n"

    # Determine the splice/regen/halt decision from the OLD project file.
    $verb = "VERIFY-REGEN"
    $finalText = $fresh
    if (Test-Path $proj) {
        $oldRaw = Get-Content $proj -Raw
        $oldLines = $oldRaw -split "`r?`n"
        $oldMarkers = Get-MarkerBlock $oldLines
        if ($oldMarkers.ok) {
            $customized = -not (Test-IsStubBlock $oldMarkers.block)
            if ($customized) {
                # SPLICE: replace the fresh file's BEGIN..END region with the OLD block verbatim.
                $freshMarkers = Get-MarkerBlock $freshLines
                if ($freshMarkers.ok) {
                    $spliced = @()
                    $spliced += $freshLines[0..$freshMarkers.startIdx]      # up to & incl. fresh BEGIN
                    $spliced += $oldMarkers.block                            # old inner block verbatim
                    $spliced += $freshLines[$freshMarkers.endIdx..($freshLines.Count - 1)]  # fresh END onward
                    $finalText = ($spliced -join "`n")
                    $verb = "VERIFY-SPLICE"
                } else {
                    # Fresh template lost its markers (should not happen) — regen.
                    $verb = "VERIFY-REGEN"
                }
            } else {
                $verb = "VERIFY-REGEN"   # clean delimiter + stub-only -> take fresh
            }
        } else {
            # No clean delimiter in the OLD file (predates markers).
            $oldCustomized = Test-OldBCustomized $oldLines
            if ($oldCustomized -and -not $Force) {
                Emit ("VERIFY-HALT|{0}" -f $shell)
                Emit ("CONFLICT|verify_all|verify_all.{0} has no HARNESS:B-CUSTOM markers but appears to carry custom B.* checks — left untouched (nothing lost). Re-run with -Force to overwrite; a timestamped .bak will be written first, preserving your old checks." -f $shell)
                $nConflicts++
                $exitCode = 2
                continue
            }
            $verb = "VERIFY-REGEN"
        }
    }

    # Idempotence: byte-identical to existing -> NOOP, no .bak, no write.
    if ((Test-Path $proj) -and ((Get-Content $proj -Raw) -ceq $finalText)) {
        Emit ("RESULT|NOOP|verify_all.{0} already current" -f $shell)
        continue
    }

    $isNew = -not (Test-Path $proj)
    Emit ("{0}|{1}|verify_all.{2}" -f ($(if ($DryRun) { "PLAN" } else { "RESULT" })), $verb, $shell)
    if ($isNew) { $nAdded++ } else { $nRewritten++ }
    if (-not $DryRun) {
        if (Test-Path $proj) {
            $bak = "$proj.bak-$stamp"
            Copy-Item -Path $proj -Destination $bak -Force
            Emit ("BAK|{0}" -f $bak)
        }
        [System.IO.File]::WriteAllText($proj, $finalText)
    }
}

Emit ("SUMMARY|added={0} moved={1} rewritten={2} rewired={3} conflicts={4}" -f $nAdded, $nMoved, $nRewritten, $nRewired, $nConflicts)
exit $exitCode
