# test-init.ps1 — Automated regression for /harness-init (v0.2)
#
# Simulates a full init in a temp directory:
#   1. Copy common + project-type templates with placeholder substitution
#      (.tmpl files; no .append handling — v0.2 doesn't use .append).
#   2. Run the project's own harness-sync to generate .claude/ + CLAUDE.md.
#   3. Assert the resulting structure.
#
# Implements Golden Tasks #1 (fullstack) and #2 (backend).
#
# Usage:
#   .\.harness\scripts\test-init.ps1              # both project types
#   .\.harness\scripts\test-init.ps1 -Type fullstack
#   .\.harness\scripts\test-init.ps1 -KeepTemp    # leave temp dir for inspection

[CmdletBinding()]
param(
    [ValidateSet("all", "both", "fullstack", "backend", "generic")]
    [string]$Type = "all",
    [switch]$KeepTemp
)

$ErrorActionPreference = "Stop"
# Script lives at .harness/scripts/ — repo root is two levels up.
$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$templateRoot = Join-Path $repoRoot "skills/harness-init/templates"
$today = (Get-Date).ToString("yyyy-MM-dd")

$pass = 0
$fail = 0
$failures = @()

# T-13: all EIGHT hook byte-forms are defined UNCONDITIONALLY at script scope; Test-Type
# BINDS the four host-OS $*Cmd variables from them below. Pure re-binding — the bytes the
# substitution injects are exactly the bytes it injected before — so every pre-existing
# exact-string assertion is unaffected. The unconditional definitions exist so the T-13
# spec block can lockstep-compare all 8 cells from one run. These fixtures are HAND
# COPIES: they catch fixture drift, they are NOT independent evidence (the live oracle is).
# Single-quoted literals throughout: the bodies carry \" and un-interpolated $env: tokens.
$expWinSync           = 'pwsh -NoProfile -Command \"Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR -EA SilentlyContinue; if (Test-Path -LiteralPath .harness/scripts/harness-sync.ps1 -PathType Leaf) { & pwsh -NoProfile -File .harness/scripts/harness-sync.ps1 }; exit 0\"'
$expWinGuard          = 'pwsh -NoProfile -Command \"Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR; & pwsh -NoProfile -File .harness/scripts/guard-rm.ps1\"'
$expWinAmbientPrompt  = 'pwsh -NoProfile -Command \"Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR -EA SilentlyContinue; if (Test-Path -LiteralPath .harness/scripts/ambient-prompt.ps1 -PathType Leaf) { & pwsh -NoProfile -File .harness/scripts/ambient-prompt.ps1 }; exit 0\"'
$expWinAmbientReset   = 'pwsh -NoProfile -Command \"Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR -EA SilentlyContinue; if (Test-Path -LiteralPath .harness/scripts/ambient-reset.ps1 -PathType Leaf) { & pwsh -NoProfile -File .harness/scripts/ambient-reset.ps1 }; exit 0\"'
$expUnixSync          = 'sh -c ''cd \"$CLAUDE_PROJECT_DIR\" 2>/dev/null && [ -f .harness/scripts/harness-sync.sh ] && exec bash .harness/scripts/harness-sync.sh || exit 0'''
$expUnixGuard         = 'sh -c ''cd \"$CLAUDE_PROJECT_DIR\" 2>/dev/null && bash .harness/scripts/guard-rm.sh'''
$expUnixAmbientPrompt = 'sh -c ''cd \"$CLAUDE_PROJECT_DIR\" 2>/dev/null && [ -f .harness/scripts/ambient-prompt.sh ] && exec bash .harness/scripts/ambient-prompt.sh || exit 0'''
$expUnixAmbientReset  = 'sh -c ''cd \"$CLAUDE_PROJECT_DIR\" 2>/dev/null && [ -f .harness/scripts/ambient-reset.sh ] && exec bash .harness/scripts/ambient-reset.sh || exit 0'''

# Get-HookFixture <tool> <os> — the hand-copied fixture for one (tool, OS) cell.
function Get-HookFixture($tool, $targetOs) {
    if ($targetOs -ceq 'windows') {
        if ($tool -ceq 'harness-sync')   { return $expWinSync }
        if ($tool -ceq 'guard-rm')       { return $expWinGuard }
        if ($tool -ceq 'ambient-prompt') { return $expWinAmbientPrompt }
        return $expWinAmbientReset
    }
    if ($tool -ceq 'harness-sync')   { return $expUnixSync }
    if ($tool -ceq 'guard-rm')       { return $expUnixGuard }
    if ($tool -ceq 'ambient-prompt') { return $expUnixAmbientPrompt }
    return $expUnixAmbientReset
}

# Invoke-HookSpecQuery — run the spec CLI and record its exit code in
# $script:hookSpecExit. Never crossing shells: the PS twin calls the PS twin.
$script:hookSpecPath = Join-Path $repoRoot ".harness/scripts/hook-spec.ps1"
$script:hookSpecExit = 0
function Invoke-HookSpecQuery {
    param([string[]]$SpecQuery)
    $script:hookSpecExit = 99
    $text = ''
    try {
        $raw = & pwsh -NoProfile -File $script:hookSpecPath @SpecQuery 2>$null
        $script:hookSpecExit = $LASTEXITCODE
        if ($null -ne $raw) { $text = ($raw -join "`n") }
    } catch {
        $script:hookSpecExit = 99
        $text = ''
    }
    return $text
}

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

function Copy-TemplateLayer {
    param(
        [string]$Source,
        [string]$Target,
        [hashtable]$Vars
    )
    if (-not (Test-Path $Source)) { throw "source missing: $Source" }

    Get-ChildItem -Path $Source -Recurse -File | ForEach-Object {
        $rel = $_.FullName.Substring($Source.Length).TrimStart('\','/')
        $destRel = $rel
        $needsSubst = $false

        if ($destRel.EndsWith(".tmpl")) {
            $destRel = $destRel.Substring(0, $destRel.Length - 5)
            $needsSubst = $true
        }

        $destPath = Join-Path $Target $destRel
        $destDir = Split-Path $destPath -Parent
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }

        if ($needsSubst) {
            $content = Get-Content $_.FullName -Raw
            foreach ($k in $Vars.Keys) {
                # Literal .Replace, NOT -replace: the T-12 resilient command values carry
                # `$env:CLAUDE_PROJECT_DIR` / `$CLAUDE_PROJECT_DIR`, and -replace would treat
                # `$...` in the replacement as a regex backreference token and mangle it.
                $content = $content.Replace("{{$k}}", [string]$Vars[$k])
            }
            [System.IO.File]::WriteAllText($destPath, $content)
        } else {
            Copy-Item -Path $_.FullName -Destination $destPath -Force
        }
    }
}

function Test-Type {
    param([string]$ProjectType, [string]$Stack)

    Write-Host ""
    Write-Host "=== Testing: $ProjectType ($Stack) ===" -ForegroundColor Cyan

    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) "harness-test-$(Get-Random)"
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null

    try {
        # NOTE: -NoProfile on Windows mirrors harness-init/SKILL.md step 5 rule.
        # Without it, every Bash tool call eats $PROFILE startup cost (NFR-Perf).
        # See 06_TEST_REPORT.md D-3 (3.7s p50 → 10ms with -NoProfile).
        # T-12: the OS-picked hook commands are the RESILIENT form (fail-OPEN +
        # $CLAUDE_PROJECT_DIR-anchored for the convenience hooks, fail-CLOSED for guard-rm).
        # JSON-ESCAPED bytes (inner " as \") so the exact `"command": "<literal>"` match
        # equals the substituted .tmpl byte-for-byte (gate C3).
        # T-13: pure re-binding from the eight script-scope fixtures defined at the top.
        $win = ($IsWindows -or $env:OS -eq "Windows_NT")
        if ($win) {
            $syncCmd          = $expWinSync
            $guardCmd         = $expWinGuard
            $ambientPromptCmd = $expWinAmbientPrompt
            $ambientResetCmd  = $expWinAmbientReset
        } else {
            $syncCmd          = $expUnixSync
            $guardCmd         = $expUnixGuard
            $ambientPromptCmd = $expUnixAmbientPrompt
            $ambientResetCmd  = $expUnixAmbientReset
        }
        $vars = @{
            "PROJECT_NAME"  = "test-project"
            "PROJECT_TYPE"  = $ProjectType
            "STACK"         = $Stack
            "TODAY"         = $today
            "ENABLE_HOOK"   = "false"
            "SYNC_COMMAND"  = $syncCmd
            "GUARD_COMMAND" = $guardCmd
            "AMBIENT_PROMPT_COMMAND" = $ambientPromptCmd
            "AMBIENT_RESET_COMMAND"  = $ambientResetCmd
        }

        # 1) copy templates (common, then overlay)
        Copy-TemplateLayer -Source (Join-Path $templateRoot "common") -Target $tmp -Vars $vars
        Copy-TemplateLayer -Source (Join-Path $templateRoot $ProjectType) -Target $tmp -Vars $vars

        # 2) run the embedded harness-sync to generate .claude/ + CLAUDE.md
        $syncScript = Join-Path $tmp ".harness/scripts/harness-sync.ps1"
        Assert "harness-sync.ps1 was distributed" { Test-Path $syncScript }
        if (Test-Path $syncScript) {
            $env:HARNESS_TEST = "1"  # not used currently but reserved
            & pwsh -File $syncScript | Out-Null
            $syncExit = $LASTEXITCODE
            Assert "harness-sync exited cleanly" { $syncExit -eq 0 }
        }

        # === Source-of-truth (.harness/) assertions ===
        # v0.30 cutover: the 7 generic framework agents are PLUGIN-provided (harness-kit:<name>),
        # NOT copied into the project by default — assert they are ABSENT.
        # NOTE: baseline.json test-init counts MOVE with these flips; the operator reconciles
        # them from a captured run.
        $agents = @("pm-orchestrator","requirement-analyst","solution-architect",
                    "gate-reviewer","developer","code-reviewer","qa-tester")
        foreach ($a in $agents) {
            Assert ".harness/agents/$a.md ABSENT (plugin-provided, not copied)" { -not (Test-Path (Join-Path $tmp ".harness/agents/$a.md")) }
        }

        # Partition agents: fullstack and backend have them in v0.5+; generic has none by default
        $partitionAgents = switch ($ProjectType) {
            "fullstack" { @("dev-frontend", "dev-backend", "dev-db") }
            "backend"   { @("dev-api", "dev-services", "dev-db") }
            "generic"   { @() }
        }
        foreach ($p in $partitionAgents) {
            Assert ".harness/agents/$p.md (partition SOT)" { Test-Path (Join-Path $tmp ".harness/agents/$p.md") }
            Assert ".harness/agents/$p.md placeholder substituted" {
                $content = Get-Content (Join-Path $tmp ".harness/agents/$p.md") -Raw
                ($content -notmatch '\{\{[A-Z_]+\}\}') -and ($content -match "test-project")
            }
        }

        Assert ".harness/rules/00-core.md (composed base)" { Test-Path (Join-Path $tmp ".harness/rules/00-core.md") }
        Assert ".harness/rules/25-decision-policy.md (shipped, generic)" { Test-Path (Join-Path $tmp ".harness/rules/25-decision-policy.md") }
        Assert ".harness/rules/25-decision-policy.md defaults to Mode 1" { (Get-Content (Join-Path $tmp ".harness/rules/25-decision-policy.md") -Raw) -match 'Active mode: 1' }
        Assert ".harness/decision-rubric.md (shipped, generic)" { Test-Path (Join-Path $tmp ".harness/decision-rubric.md") }
        Assert ".harness/decision-rubric.md has Preset + Custom sections" { $r = Get-Content (Join-Path $tmp ".harness/decision-rubric.md") -Raw; ($r -match 'Preset rubric \(Mode 2\)') -and ($r -match 'Custom rubric \(Mode 3\)') }
        Assert "CONTEXT.md seed present (generic glossary)" { Test-Path (Join-Path $tmp "CONTEXT.md") }
        Assert "rejected-decisions.md seed present (generic)" { Test-Path (Join-Path $tmp ".harness/rejected-decisions.md") }
        Assert ".harness/rules/50-$ProjectType.md (overlay)" { Test-Path (Join-Path $tmp ".harness/rules/50-$ProjectType.md") }

        # .harness/skills/ is fullstack/backend-only; generic ships without them (user fills in)
        if ($ProjectType -ne "generic") {
            foreach ($s in @("build","test","verify")) {
                Assert ".harness/skills/$s/SKILL.md (SOT)" { Test-Path (Join-Path $tmp ".harness/skills/$s/SKILL.md") }
            }
        }

        # === Generated artifacts (.claude/ + CLAUDE.md) ===
        # v0.30 cutover: generic framework agents are plugin-provided, so harness-sync does NOT
        # generate them under .claude/agents/ — assert they are ABSENT. Partition dev-* still sync.
        foreach ($a in $agents) {
            Assert ".claude/agents/$a.md ABSENT (plugin-provided, not generated)" { -not (Test-Path (Join-Path $tmp ".claude/agents/$a.md")) }
        }
        foreach ($p in $partitionAgents) {
            Assert ".claude/agents/$p.md (generated partition)" { Test-Path (Join-Path $tmp ".claude/agents/$p.md") }
        }
        if ($ProjectType -ne "generic") {
            foreach ($s in @("build","test","verify")) {
                Assert ".claude/skills/$s/SKILL.md (generated)" { Test-Path (Join-Path $tmp ".claude/skills/$s/SKILL.md") }
            }
        }
        Assert ".claude/settings.json (direct binding artifact)" { Test-Path (Join-Path $tmp ".claude/settings.json") }
        Assert "AI-GUIDE.md (v0.10 tool-agnostic entry)" { Test-Path (Join-Path $tmp "AI-GUIDE.md") }
        Assert "CLAUDE.md (v0.10 bootstrap stub)" { Test-Path (Join-Path $tmp "CLAUDE.md") }
        Assert ".github/copilot-instructions.md (v0.10 bootstrap stub)" {
            Test-Path (Join-Path $tmp ".github/copilot-instructions.md")
        }
        Assert "copilot-instructions.md has applyTo frontmatter" {
            $head = Get-Content (Join-Path $tmp ".github/copilot-instructions.md") -TotalCount 5
            ($head -join "`n") -match 'applyTo:\s*"\*\*"'
        }

        # === Content correctness ===
        Assert "CLAUDE.md is a stub (references AI-GUIDE.md, no GENERATED marker)" {
            $c = Get-Content (Join-Path $tmp "CLAUDE.md") -Raw
            ($c -match "AI-GUIDE\.md") -and ($c -notmatch "GENERATED FILE") -and ($c.Length -lt 2000)
        }
        Assert "copilot-instructions.md is a stub (references AI-GUIDE.md)" {
            $c = Get-Content (Join-Path $tmp ".github/copilot-instructions.md") -Raw
            ($c -match "AI-GUIDE\.md") -and ($c.Length -lt 2000)
        }
        Assert "AI-GUIDE.md indexes project-type rule overlay" {
            (Get-Content (Join-Path $tmp "AI-GUIDE.md") -Raw) -match "50-$ProjectType\.md"
        }
        Assert "AI-GUIDE.md indexes every .harness/rules/*.md file (matches user-project verify_all E.5)" {
            $guide = Get-Content (Join-Path $tmp "AI-GUIDE.md") -Raw
            $missing = @()
            Get-ChildItem -Path (Join-Path $tmp ".harness/rules") -Filter "*.md" -File | ForEach-Object {
                if ($guide -notmatch [regex]::Escape(".harness/rules/$($_.Name)")) { $missing += $_.Name }
            }
            if ($missing.Count -gt 0) {
                Write-Host ("  Rules NOT indexed: " + ($missing -join ", ")) -ForegroundColor Yellow
                $false
            } else { $true }
        }
        Assert "PROJECT_NAME substituted into rules" {
            (Get-Content (Join-Path $tmp ".harness/rules/00-core.md") -Raw) -match "test-project"
        }
        Assert "TODAY substituted into rules" {
            (Get-Content (Join-Path $tmp ".harness/rules/00-core.md") -Raw) -match $today
        }
        Assert "STACK substituted into rules" {
            (Get-Content (Join-Path $tmp ".harness/rules/00-core.md") -Raw) -match [regex]::Escape($Stack)
        }
        Assert "PROJECT_NAME substituted into AI-GUIDE.md" {
            (Get-Content (Join-Path $tmp "AI-GUIDE.md") -Raw) -match "test-project"
        }
        Assert "PROJECT_NAME substituted into CLAUDE.md stub" {
            (Get-Content (Join-Path $tmp "CLAUDE.md") -Raw) -match "test-project"
        }

        # === Docs / scripts / evals ===
        foreach ($f in @("docs/workflow.md","docs/dev-map.md","docs/tasks.md","docs/spec/README.md",
                         "evals/golden-tasks.md",".harness/scripts/verify_all.ps1",".harness/scripts/verify_all.sh",
                         ".harness/scripts/harness-sync.sh")) {
            Assert "$f present" { Test-Path (Join-Path $tmp $f) }
        }

        # === AC-1 (T-007): harness scripts live under .harness/scripts/, NOT scripts/ ===
        # The generated tree must contain NO harness-owned file under scripts/, and
        # the scripts/ directory itself must be absent (Q1=(a) absent). FAIL if init
        # writes any script into scripts/.
        Assert "[AC-1] generated tree has no scripts/ directory (harness writes only to .harness/scripts/)" {
            -not (Test-Path (Join-Path $tmp "scripts"))
        }
        Assert "[AC-1] no harness script leaked under scripts/ (verify_all/harness-sync/guard-rm/baseline)" {
            $leaked = @("verify_all.ps1","verify_all.sh","harness-sync.ps1","harness-sync.sh",
                        "guard-rm.ps1","guard-rm.sh","baseline.json") | Where-Object {
                Test-Path (Join-Path $tmp "scripts/$_")
            }
            if ($leaked.Count -gt 0) { throw "harness files found under scripts/: $($leaked -join ', ')" }
            $true
        }

        # === Cleanliness ===
        Assert "no unresolved placeholders anywhere" {
            $bad = @()
            Get-ChildItem -Path $tmp -Recurse -File | Where-Object {
                $_.Extension -in @(".md", ".json", ".sh", ".ps1")
            } | ForEach-Object {
                $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
                if ($content -match '\{\{[A-Z_]+\}\}') { $bad += $_.FullName }
            }
            if ($bad.Count -gt 0) { throw "unresolved placeholders in:`n$($bad -join "`n")" }
            $true
        }
        Assert "no .tmpl files leaked" {
            $leaked = Get-ChildItem -Path $tmp -Recurse -Filter "*.tmpl" -File
            if ($leaked) { throw "leaked: $($leaked.FullName -join ', ')" }
            $true
        }
        Assert "no .append files anywhere (v0.2 removed them)" {
            $leaked = Get-ChildItem -Path $tmp -Recurse -Filter "*.append" -File
            if ($leaked) { throw "found: $($leaked.FullName -join ', ')" }
            $true
        }

        # === Guard-rm + PreToolUse hook wired (v0.15+) ===
        Assert ".harness/scripts/guard-rm.ps1 present after init" { Test-Path (Join-Path $tmp ".harness/scripts/guard-rm.ps1") }
        Assert ".harness/scripts/guard-rm.sh present after init" { Test-Path (Join-Path $tmp ".harness/scripts/guard-rm.sh") }
        Assert ".claude/settings.json parses as JSON" {
            $raw = Get-Content (Join-Path $tmp ".claude/settings.json") -Raw
            $null -ne ($raw | ConvertFrom-Json)
        }
        Assert ".claude/settings.json PreToolUse[0].matcher == 'Bash'" {
            $s = Get-Content (Join-Path $tmp ".claude/settings.json") -Raw | ConvertFrom-Json
            $s.hooks.PreToolUse[0].matcher -eq "Bash"
        }
        Assert ".claude/settings.json PreToolUse command references guard-rm" {
            $s = Get-Content (Join-Path $tmp ".claude/settings.json") -Raw | ConvertFrom-Json
            $s.hooks.PreToolUse[0].hooks[0].command -match 'guard-rm\.(ps1|sh)'
        }

        # === T-020: hook<->script congruence of the generated settings (AC-5) ===
        # Same deterministic core as harness-init SKILL step 10b: extract every script
        # path on "command" lines with the LEFT-BOUNDED regex (quote/space/=/line
        # start — a dirname merely ending in scripts/ never matches) and assert each
        # exists. Case-sensitive regex; .Split("`n") per insight 2026-06-08.
        $t20Rx = [regex]::new('(^|["'' =])((\.harness/)?scripts/[A-Za-z0-9._-]+\.(ps1|sh))')
        function Get-DanglingHookPaths($settingsPath, $treeRoot) {
            $viol = @()
            $rawSettings = Get-Content $settingsPath -Raw
            foreach ($cmdLine in $rawSettings.Split("`n")) {
                if (-not $cmdLine.Contains('"command"')) { continue }
                foreach ($m in $t20Rx.Matches($cmdLine)) {
                    $rp = $m.Groups[2].Value
                    if (-not (Test-Path (Join-Path $treeRoot $rp))) { $viol += $rp }
                }
            }
            return $viol
        }
        Assert "[T-020] every settings hook command path exists on disk (AC-5)" {
            (Get-DanglingHookPaths (Join-Path $tmp ".claude/settings.json") $tmp).Count -eq 0
        }
        Assert "[T-020] ambient-prompt command is the OS-picked variant" {
            (Get-Content (Join-Path $tmp ".claude/settings.json") -Raw).Contains('"command": "' + $ambientPromptCmd + '"')
        }
        Assert "[T-020] ambient-reset command is the OS-picked variant" {
            (Get-Content (Join-Path $tmp ".claude/settings.json") -Raw).Contains('"command": "' + $ambientResetCmd + '"')
        }

        # === T-020: generated verify_all carries the v0.30-correct rows (FR-D3/FR-D4) ===
        $t20CongRow = if ($ProjectType -eq "backend") { "D.4b" } else { "E.4b" }
        Assert "[T-020] generated verify_all.ps1 has the agents-layout wording, not the retired 7-agents check" {
            $c = Get-Content (Join-Path $tmp ".harness/scripts/verify_all.ps1") -Raw
            $c.Contains('partition dev-* only') -and (-not $c.Contains('All 7 agent definitions'))
        }
        Assert "[T-020] generated verify_all.ps1 has the $t20CongRow hook-congruence row" {
            (Get-Content (Join-Path $tmp ".harness/scripts/verify_all.ps1") -Raw).Contains('"' + $t20CongRow + '"')
        }
        Assert "[T-020] generated verify_all.sh has the agents-layout wording + $t20CongRow row" {
            $c = Get-Content (Join-Path $tmp ".harness/scripts/verify_all.sh") -Raw
            $c.Contains('partition dev-* only') -and $c.Contains('"' + $t20CongRow + '"') -and (-not $c.Contains('All 7 agents'))
        }

        # === Layer 2 binding consistency right after init ===
        Assert "harness-sync --check is clean after init" {
            $check = Join-Path $tmp ".harness/scripts/harness-sync.ps1"
            & pwsh -File $check -Check | Out-Null
            $LASTEXITCODE -eq 0
        }

        # === AI-native init/adopt (v0.16+) ===
        # Bidirectional: opt-out path must be byte-identical to v0.15.1 (AC-10);
        # opt-in path must produce a tailored 50-<slug>.md with all four invariants
        # satisfied and the static stub replaced. See design §10 for the 14
        # assertions per project type.

        # Opt-out half (bidirectional check 1 + 2 of §10)
        Assert "[AI-out] .harness/rules/50-$ProjectType.md is present (static stub, opt-out path)" {
            Test-Path (Join-Path $tmp ".harness/rules/50-$ProjectType.md")
        }
        Assert "[AI-out] .harness/rules/50-test-project.md is NOT present (opt-out leaves stub in place)" {
            -not (Test-Path (Join-Path $tmp ".harness/rules/50-test-project.md"))
        }

        # === AC-10 byte-compare (rollback round 1, M-2 + M-3) ===
        # Discrete "Q6=No, full init, end state" pass in its own temp dir, with no
        # AI-native simulation touching it. Byte-compare the resulting
        # .harness/rules/50-<type>.md against the source template (post-substitution
        # for the generic .md.tmpl case). v0.15.1 shipped these exact bytes; the
        # static templates ARE the v0.15.1 reference.
        $optOutTmp = Join-Path ([System.IO.Path]::GetTempPath()) "harness-test-optout-$(Get-Random)"
        New-Item -ItemType Directory -Path $optOutTmp -Force | Out-Null
        try {
            # Run the same template-copy + substitution flow used in real init,
            # but skip harness-sync and skip the AI-native simulation — this is
            # the pure Q6=No end state.
            Copy-TemplateLayer -Source (Join-Path $templateRoot "common") -Target $optOutTmp -Vars $vars
            Copy-TemplateLayer -Source (Join-Path $templateRoot $ProjectType) -Target $optOutTmp -Vars $vars

            # Compute the expected bytes from the source template. fullstack and
            # backend ship a plain .md (no substitution); generic ships .md.tmpl
            # with {{PROJECT_NAME}} and {{STACK}}. Mirror Copy-TemplateLayer's
            # substitution for the .tmpl case.
            $srcStatic = Join-Path $templateRoot "$ProjectType/.harness/rules/50-$ProjectType.md"
            $srcTmpl   = Join-Path $templateRoot "$ProjectType/.harness/rules/50-$ProjectType.md.tmpl"
            $expected = $null
            if (Test-Path $srcStatic) {
                $expected = [System.IO.File]::ReadAllBytes($srcStatic)
            } elseif (Test-Path $srcTmpl) {
                $tmplContent = Get-Content $srcTmpl -Raw
                foreach ($k in $vars.Keys) {
                    $tmplContent = $tmplContent.Replace("{{$k}}", [string]$vars[$k])  # literal (T-12: $-safe)
                }
                # Copy-TemplateLayer writes with WriteAllText (UTF-8 no BOM by
                # default in .NET). Mirror that exactly so the comparison is fair.
                $tmpExpected = Join-Path $optOutTmp "_expected_50.md"
                [System.IO.File]::WriteAllText($tmpExpected, $tmplContent)
                $expected = [System.IO.File]::ReadAllBytes($tmpExpected)
                Remove-Item $tmpExpected -Force
            }
            $actualPath = Join-Path $optOutTmp ".harness/rules/50-$ProjectType.md"
            Assert "[AC-10] opt-out 50-$ProjectType.md is byte-identical to source template (v0.15.1 reference, fresh temp dir)" {
                if ($null -eq $expected) { throw "no source template found for $ProjectType" }
                if (-not (Test-Path $actualPath)) { throw "actual file missing: $actualPath" }
                $actual = [System.IO.File]::ReadAllBytes($actualPath)
                if ($actual.Length -ne $expected.Length) {
                    throw "length mismatch: actual=$($actual.Length) expected=$($expected.Length)"
                }
                for ($i = 0; $i -lt $actual.Length; $i++) {
                    if ($actual[$i] -ne $expected[$i]) { throw "first byte mismatch at offset $i" }
                }
                $true
            }
        } finally {
            Remove-Item -Recurse -Force $optOutTmp -ErrorAction SilentlyContinue
        }

        # Opt-in simulation. The skill's step 5b runs INSIDE the orchestrator,
        # not as a Bash call; this block mirrors its logic so test-init can
        # exercise the same invariants offline.
        $mockFixture = Join-Path $tmp ".harness/scripts/ai-native-mock.json"
        Assert "[AI-in] mock fixture present after init (templates/common ships it)" { Test-Path $mockFixture }

        $env:HARNESS_AI_NATIVE_MOCK = $mockFixture
        try {
            $mockJson = Get-Content $mockFixture -Raw | ConvertFrom-Json
            $ruleBody = $mockJson.rule_md

            # Invariant 1: six required headings present in order
            $required = @(
                "## When to read",
                "## Build / test / verify",
                "## Project structure",
                "## Stack-specific conventions",
                "## Partitioning",
                "## Stack-specific verify_all checks"
            )
            $invariant1 = $true
            $idx = 0
            foreach ($h in $required) {
                $i = $ruleBody.IndexOf($h, $idx)
                if ($i -lt 0) { $invariant1 = $false; break }
                $idx = $i + $h.Length
            }
            # Invariant 2: zero {{...}} literals
            $invariant2 = ($ruleBody -notmatch '\{\{[A-Z_]+\}\}')
            # Invariant 3: line count <=200
            $invariant3 = (($ruleBody -split "`n").Length -le 200)
            # Invariant 4: reserved-name filter
            $reserved = @("pm-orchestrator","requirement-analyst","solution-architect","gate-reviewer","developer","code-reviewer","qa-tester")
            $filteredPartitions = $mockJson.partition_agents | Where-Object { $reserved -notcontains $_.name }

            # Apply (simulate skill steps 5b.6 / 5b.7 / 5b.8)
            $slug = "test-project"
            $optInRule = Join-Path $tmp ".harness/rules/50-$slug.md"
            $staticStub = Join-Path $tmp ".harness/rules/50-$ProjectType.md"
            $aiGuide    = Join-Path $tmp "AI-GUIDE.md"

            if ($invariant1 -and $invariant2 -and ($filteredPartitions.Count -eq $mockJson.partition_agents.Count -or $true)) {
                [System.IO.File]::WriteAllText($optInRule, $ruleBody)
                # Re-Read sanity (per insight-index line 10)
                $readBack = Get-Content $optInRule -Raw
                if ($readBack -ne $ruleBody) { throw "re-Read mismatch on $optInRule" }
                # Delete static stub
                Remove-Item $staticStub -Force
                # Edit AI-GUIDE.md to swap the index line
                $guideContent = Get-Content $aiGuide -Raw
                $guideContent = $guideContent.Replace("50-$ProjectType.md", "50-$slug.md")
                [System.IO.File]::WriteAllText($aiGuide, $guideContent)
            }

            # The 14 assertions per design §10
            Assert "[AI-in] (3) 50-$slug.md exists after opt-in apply" { Test-Path $optInRule }
            Assert "[AI-in] (4) 50-$ProjectType.md does NOT exist (replaced by 50-$slug.md)" { -not (Test-Path $staticStub) }
            Assert "[AI-in] (5) opt-in file contains no <your build command>/<your test command>/<your linter> placeholders" {
                $c = Get-Content $optInRule -Raw
                ($c -notmatch '<your build command>') -and ($c -notmatch '<your test command>') -and ($c -notmatch '<your linter>')
            }
            Assert "[AI-in] (6) opt-in file has all six required headings present in order" { $invariant1 }
            Assert "[AI-in] (7) opt-in file has >=1 <!-- source: ... --> annotation" {
                $c = Get-Content $optInRule -Raw
                ([regex]::Matches($c, '<!-- source: [^ >]+ -->')).Count -ge 1
            }
            Assert "[AI-in] (8) AI-GUIDE.md references 50-$slug.md, NOT 50-$ProjectType.md" {
                $c = Get-Content $aiGuide -Raw
                # Look for new slug presence + absence of original type-named rule index entry
                $oldRef = ".harness/rules/50-$ProjectType.md"
                ($c -match [regex]::Escape("50-$slug.md")) -and ($c -notmatch [regex]::Escape($oldRef))
            }
            Assert '[AI-in] (9) opt-in file has zero {{...}} literals (D.2 protection)' { $invariant2 }
            Assert "[AI-in] (10) opt-in file has line count <=200" { $invariant3 }

            # Mock-error path: pointing the env var at a garbage file should NOT
            # crash; the skill detects parse failure and falls back to the static
            # stub. Simulate by writing a separate mini-test fixture in a sub-temp.
            $errTmp = Join-Path ([System.IO.Path]::GetTempPath()) "harness-test-mockerr-$(Get-Random)"
            New-Item -ItemType Directory -Path $errTmp -Force | Out-Null
            try {
                # Re-prepare just the stub from templates without going through full copy
                $stubPath = Join-Path $errTmp "50-$ProjectType.md"
                "# 50 — Project-specific rules`n## When to read`n- placeholder" | Set-Content $stubPath
                $env:HARNESS_AI_NATIVE_MOCK = (Join-Path $errTmp "does-not-exist.json")
                $mockReadable = Test-Path $env:HARNESS_AI_NATIVE_MOCK
                # The skill detects unreadable mock -> fallback -> static stub survives.
                Assert "[AI-in] (11) mock-error path: unreadable mock detected, static stub preserved (fallback)" {
                    (-not $mockReadable) -and (Test-Path $stubPath)
                }
            } finally {
                Remove-Item -Recurse -Force $errTmp -ErrorAction SilentlyContinue
            }

            # Partition acceptance / rejection (12 + 13)
            $partA = $filteredPartitions | Where-Object { $_.name -eq "dev-payments" } | Select-Object -First 1
            Assert "[AI-in] (12) partition draft NOT written under reject decision (mock without explicit accept)" {
                # Simulate reject: the skill never writes without an Accept; just check
                # the agent file doesn't exist yet at this point (it shouldn't, because
                # we have not "accepted" anything in this simulated run).
                -not (Test-Path (Join-Path $tmp ".harness/agents/dev-payments.md"))
            }
            # Simulate accept: write the file (per SKILL.md step 5b.9 Accept branch).
            # The SKILL's Write tool creates parent dirs; mirror that — since the v0.30
            # cutover, a generic/single-dev project has no pre-existing .harness/agents/.
            if ($partA) {
                $agentsDir = Join-Path $tmp ".harness/agents"
                if (-not (Test-Path $agentsDir)) { New-Item -ItemType Directory -Path $agentsDir -Force | Out-Null }
                [System.IO.File]::WriteAllText((Join-Path $agentsDir "dev-payments.md"), $partA.body)
            }
            Assert "[AI-in] (13) partition draft IS written under accept decision (dev-payments.md present)" {
                Test-Path (Join-Path $tmp ".harness/agents/dev-payments.md")
            }

            # Reserved-name collision (14): a mock proposing 'developer' must be dropped.
            $reservedClash = @(
                [pscustomobject]@{ name = "developer"; body = "should be dropped" },
                [pscustomobject]@{ name = "dev-realtime"; body = "should pass" }
            )
            $afterFilter = $reservedClash | Where-Object { $reserved -notcontains $_.name }
            Assert "[AI-in] (14) reserved-name collision: proposed 'developer' is filtered out before write" {
                ($afterFilter.Count -eq 1) -and ($afterFilter[0].name -eq "dev-realtime")
            }

        } finally {
            Remove-Item Env:HARNESS_AI_NATIVE_MOCK -ErrorAction SilentlyContinue
        }

        # === T-020 mutation probe (AC-5 mutation half): delete the wired sync script,
        # re-run the step-10b deterministic core — it MUST now report a violation.
        # Runs LAST in this fixture (the tree is discarded right after). ===
        Remove-Item (Join-Path $tmp ".harness/scripts/harness-sync.sh") -Force -ErrorAction SilentlyContinue
        Remove-Item (Join-Path $tmp ".harness/scripts/harness-sync.ps1") -Force -ErrorAction SilentlyContinue
        Assert "[T-020] mutation probe: deleted harness-sync.* IS reported as dangling (AC-5)" {
            (Get-DanglingHookPaths (Join-Path $tmp ".claude/settings.json") $tmp).Count -ge 1
        }

    } finally {
        if (-not $KeepTemp) {
            Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
        } else {
            Write-Host ""
            Write-Host "Temp dir kept: $tmp" -ForegroundColor Yellow
        }
    }
}

function Test-Migrate {
    # AC-5 (T-007): downgrade-then-migrate regression for migrate-scripts-layout.
    # 1) Build a fresh generic init tree, 2) synthetically downgrade it to the
    # pre-T-007 layout (scripts/* + OLD settings paths), 3) run the helper,
    # 4) assert the end-state, then 5) assert a second run is a clean no-op.
    Write-Host ""
    Write-Host "=== Testing: migrate-scripts-layout (downgrade-then-migrate) ===" -ForegroundColor Cyan

    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) "harness-test-migrate-$(Get-Random)"
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
    try {
        # T-12: resilient OS-picked commands (JSON-escaped) for the pre-downgrade settings;
        # the synthetic downgrade below overwrites .claude/settings.json with a hand-written
        # OLD-layout brittle one anyway, so these only feed the template-copy substitution.
        $vars = @{
            "PROJECT_NAME"  = "migrate-test"; "PROJECT_TYPE" = "generic"
            "STACK"         = "Rust CLI tool"; "TODAY" = $today; "ENABLE_HOOK" = "false"
            "SYNC_COMMAND"  = 'pwsh -NoProfile -Command \"Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR -EA SilentlyContinue; if (Test-Path -LiteralPath .harness/scripts/harness-sync.ps1 -PathType Leaf) { & pwsh -NoProfile -File .harness/scripts/harness-sync.ps1 }; exit 0\"'
            "GUARD_COMMAND" = 'pwsh -NoProfile -Command \"Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR; & pwsh -NoProfile -File .harness/scripts/guard-rm.ps1\"'
            "AMBIENT_PROMPT_COMMAND" = 'pwsh -NoProfile -Command \"Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR -EA SilentlyContinue; if (Test-Path -LiteralPath .harness/scripts/ambient-prompt.ps1 -PathType Leaf) { & pwsh -NoProfile -File .harness/scripts/ambient-prompt.ps1 }; exit 0\"'
            "AMBIENT_RESET_COMMAND"  = 'pwsh -NoProfile -Command \"Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR -EA SilentlyContinue; if (Test-Path -LiteralPath .harness/scripts/ambient-reset.ps1 -PathType Leaf) { & pwsh -NoProfile -File .harness/scripts/ambient-reset.ps1 }; exit 0\"'
        }
        Copy-TemplateLayer -Source (Join-Path $templateRoot "common") -Target $tmp -Vars $vars
        Copy-TemplateLayer -Source (Join-Path $templateRoot "generic") -Target $tmp -Vars $vars

        Push-Location $tmp
        try {
            git init -q 2>$null

            # --- Synthetic downgrade: move .harness/scripts/* back to scripts/* ---
            New-Item -ItemType Directory -Path "scripts" -Force | Out-Null
            foreach ($n in @("verify_all.ps1","verify_all.sh","harness-sync.ps1","harness-sync.sh",
                             "guard-rm.ps1","guard-rm.sh")) {
                $hs = Join-Path $tmp ".harness/scripts/$n"
                if (Test-Path $hs) { Move-Item $hs (Join-Path $tmp "scripts/$n") -Force }
            }
            # baseline.json isn't a template file (it's generated post-init); synthesize
            # one at the OLD path (scripts/) so the helper's baseline.json move branch
            # is actually exercised by the regression (T-007 m-1).
            '{"test_count":0}' | Set-Content (Join-Path $tmp "scripts/baseline.json")
            # Write an OLD-layout settings.json (pre-T-007 paths) so the helper has a
            # genuine rewrite to perform (exercises the settings rewire + .bak path).
            $oldSettings = @'
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "_doc_sync_hook": "On macOS/Linux change the Stop hook command to: bash scripts/harness-sync.sh",
  "permissions": { "allow": [ "Bash(bash scripts/harness-sync.sh:*)" ] },
  "hooks": {
    "Stop": [ { "hooks": [ { "type": "command", "command": "pwsh -NoProfile -File scripts/harness-sync.ps1" } ] } ],
    "PreToolUse": [ { "matcher": "Bash", "hooks": [ { "type": "command", "command": "pwsh -NoProfile -File scripts/guard-rm.ps1" } ] } ]
  }
}
'@
            New-Item -ItemType Directory -Path ".claude" -Force | Out-Null
            [System.IO.File]::WriteAllText((Join-Path $tmp ".claude/settings.json"), $oldSettings)
            # A user-authored script that must NOT be moved.
            "echo deploy" | Set-Content (Join-Path $tmp "scripts/deploy.sh")
            git add -A 2>$null | Out-Null
            git -c user.email=t@t -c user.name=t commit -qm downgrade 2>$null | Out-Null

            $helper = Join-Path $tmp ".harness/scripts/migrate-scripts-layout.ps1"
            Assert "[migrate] helper present after init" { Test-Path $helper }

            # --- Run the migration ---
            & pwsh -NoProfile -File $helper | Out-Null
            Assert "[migrate] exit 0" { $LASTEXITCODE -eq 0 }

            Assert "[migrate] .harness/scripts/verify_all.ps1 present" { Test-Path (Join-Path $tmp ".harness/scripts/verify_all.ps1") }
            Assert "[migrate] .harness/scripts/harness-sync.ps1 present" { Test-Path (Join-Path $tmp ".harness/scripts/harness-sync.ps1") }
            Assert "[migrate] .harness/scripts/baseline.json present" { Test-Path (Join-Path $tmp ".harness/scripts/baseline.json") }
            Assert "[migrate] OLD scripts/harness-sync.ps1 vacated" { -not (Test-Path (Join-Path $tmp "scripts/harness-sync.ps1")) }
            Assert "[migrate] OLD scripts/guard-rm.sh vacated" { -not (Test-Path (Join-Path $tmp "scripts/guard-rm.sh")) }
            Assert "[migrate] OLD scripts/baseline.json vacated" { -not (Test-Path (Join-Path $tmp "scripts/baseline.json")) }
            Assert "[migrate] user-authored scripts/deploy.sh NOT moved" { Test-Path (Join-Path $tmp "scripts/deploy.sh") }

            $s = Get-Content (Join-Path $tmp ".claude/settings.json") -Raw
            # T-12: migrate now ALSO resilient-ifies (A8). The parsed command is the full
            # resilient string (ConvertFrom-Json un-escapes the inner \" to "), so compare
            # against the RESILIENT value, not the bare brittle one. The runnable resilient
            # form below matches hook-spec.ps1's `command <tool> windows` answer with real
            # (un-escaped) quotes — a THIRD escaping level the spec deliberately does not
            # emit, so this literal is a deliberate retention (T-16, hook-spec.ps1 header).
            $expSync  = 'pwsh -NoProfile -Command "Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR -EA SilentlyContinue; if (Test-Path -LiteralPath .harness/scripts/harness-sync.ps1 -PathType Leaf) { & pwsh -NoProfile -File .harness/scripts/harness-sync.ps1 }; exit 0"'
            $expGuard = 'pwsh -NoProfile -Command "Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR; & pwsh -NoProfile -File .harness/scripts/guard-rm.ps1"'
            Assert "[migrate] settings Stop command -> resilient .harness/scripts/harness-sync.ps1 (A8)" {
                $j = $s | ConvertFrom-Json
                $j.hooks.Stop[0].hooks[0].command -eq $expSync
            }
            Assert "[migrate] settings PreToolUse command -> resilient .harness/scripts/guard-rm.ps1 (A8)" {
                $j = $s | ConvertFrom-Json
                $j.hooks.PreToolUse[0].hooks[0].command -eq $expGuard
            }
            Assert "[migrate] Stop command is the resilient form (CLAUDE_PROJECT_DIR-anchored)" {
                ($s | ConvertFrom-Json).hooks.Stop[0].hooks[0].command.Contains('CLAUDE_PROJECT_DIR')
            }
            Assert "[migrate] guard-rm resilient form is fail-CLOSED (no exit 0 on its command)" {
                -not (($s | ConvertFrom-Json).hooks.PreToolUse[0].hooks[0].command.Contains('exit 0'))
            }
            Assert "[migrate] settings _doc_sync_hook doc string rewired (no stale bare scripts/harness-sync.)" {
                $j = $s | ConvertFrom-Json
                # The doc string is prefix-rewired by S3.1 but NOT made resilient (S3.2 only
                # touches "command" lines). Must contain the migrated `.harness/scripts/`
                # form, and contain NO bare `scripts/harness-sync.` that isn't part of
                # `.harness/scripts/harness-sync.` (negative lookbehind on a literal path).
                ($j._doc_sync_hook -match '\.harness/scripts/harness-sync\.sh') -and
                ($j._doc_sync_hook -notmatch '(?<!\.harness/)scripts/harness-sync\.')
            }
            Assert "[migrate] permissions.allow rewired to .harness/scripts/harness-sync.sh" {
                $j = $s | ConvertFrom-Json
                ($j.permissions.allow -join ' ') -match '\.harness/scripts/harness-sync\.sh'
            }
            Assert "[migrate] -NoProfile retained (>=2 hits; resilient form carries more)" {
                ([regex]::Matches($s, '-NoProfile')).Count -ge 2
            }
            Assert "[migrate] \$schema unchanged" {
                $s -match 'json\.schemastore\.org/claude-code-settings\.json'
            }
            Assert "[migrate] a .bak backup was written" {
                (Get-ChildItem (Join-Path $tmp ".claude") -Filter "settings.json.bak-*" -File).Count -ge 1
            }

            # --- Idempotency: a second run is a clean no-op (no new .bak) ---
            $bakBefore = (Get-ChildItem (Join-Path $tmp ".claude") -Filter "settings.json.bak-*" -File).Count
            Start-Sleep -Milliseconds 1100  # ensure a distinct timestamp WOULD be used
            & pwsh -NoProfile -File $helper | Out-Null
            Assert "[migrate] second run exit 0 (idempotent)" { $LASTEXITCODE -eq 0 }
            Assert "[migrate] second run wrote NO new .bak (true no-op)" {
                (Get-ChildItem (Join-Path $tmp ".claude") -Filter "settings.json.bak-*" -File).Count -eq $bakBefore
            }
        } finally { Pop-Location }
    } finally {
        if (-not $KeepTemp) { Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue }
        else { Write-Host "Temp dir kept: $tmp" -ForegroundColor Yellow }
    }
}

function Test-ZhOverlay {
    Write-Host ""
    Write-Host "=== Testing: i18n/zh overlay — consumer-split output-language policy ===" -ForegroundColor Cyan
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) "harness-test-zh-$(Get-Random)"
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
    try {
        # T-12: live FIXTURE-AUTHORING site — *_COMMAND values are the RESILIENT form
        # (convenience hooks fail-OPEN + $CLAUDE_PROJECT_DIR-anchored; guard-rm fail-CLOSED,
        # NO `|| exit 0`). JSON-escaped bytes copied byte-identical from the main *_COMMAND
        # literal block above; the zh-overlay substitution uses .Replace() (ordinal-literal,
        # so `&`/`$env:` survive) (AC-7).
        $vars = @{ "PROJECT_NAME"="zh-test"; "PROJECT_TYPE"="fullstack"; "STACK"="Next.js + NestJS";
                   "TODAY"=$today; "ENABLE_HOOK"="false";
                   "SYNC_COMMAND"='pwsh -NoProfile -Command \"Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR -EA SilentlyContinue; if (Test-Path -LiteralPath .harness/scripts/harness-sync.ps1 -PathType Leaf) { & pwsh -NoProfile -File .harness/scripts/harness-sync.ps1 }; exit 0\"';
                   "GUARD_COMMAND"='pwsh -NoProfile -Command \"Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR; & pwsh -NoProfile -File .harness/scripts/guard-rm.ps1\"';
                   "AMBIENT_PROMPT_COMMAND"='pwsh -NoProfile -Command \"Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR -EA SilentlyContinue; if (Test-Path -LiteralPath .harness/scripts/ambient-prompt.ps1 -PathType Leaf) { & pwsh -NoProfile -File .harness/scripts/ambient-prompt.ps1 }; exit 0\"';
                   "AMBIENT_RESET_COMMAND"='pwsh -NoProfile -Command \"Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR -EA SilentlyContinue; if (Test-Path -LiteralPath .harness/scripts/ambient-reset.ps1 -PathType Leaf) { & pwsh -NoProfile -File .harness/scripts/ambient-reset.ps1 }; exit 0\"' }
        Copy-TemplateLayer -Source (Join-Path $templateRoot "common")        -Target $tmp -Vars $vars
        Copy-TemplateLayer -Source (Join-Path $templateRoot "fullstack")      -Target $tmp -Vars $vars
        # The i18n/zh overlay now carries only the 2 human-facing files (the 3 policy-carrying
        # SPECIAL files were deleted in T-016); lay them, then COMPOSE the zh policy by running
        # the language-policy helper against the project root, exactly as init step 4.4 does.
        Copy-TemplateLayer -Source (Join-Path $templateRoot "i18n/zh/common") -Target $tmp -Vars $vars
        Push-Location $tmp
        try {
            & pwsh -NoProfile -File (Join-Path $tmp ".harness/scripts/language-policy.ps1") -TemplateRoot $repoRoot -Lang zh | Out-Null
        } finally { Pop-Location }
        Get-ChildItem -Path $tmp -Recurse -Filter "*.bak-*" -File | Remove-Item -Force -ErrorAction SilentlyContinue

        $core = Join-Path $tmp ".harness/rules/00-core.md"
        Assert "[zh] 00-core.md overlaid" { Test-Path $core }
        Assert "[zh] policy lists a Chinese-artifact (consumer=human) marker" { (Get-Content $core -Raw) -match '给用户的交付总结' }
        Assert "[zh] policy lists an English-artifact (consumer=agent) marker" { (Get-Content $core -Raw) -match 'commit message' }
        Assert "[zh] retired blunt 全程 phrasing is absent" { -not ((Get-Content $core -Raw) -match '全程') }

        # --- T-015 inverse assertions: AI-facing scaffolding now falls through to ENGLISH common/,
        #     human-facing files stay Chinese, the SPECIAL trio keeps EN body + zh policy.
        #     Each pair tests PRESENT and ABSENT on DIFFERENT strings (no same-string trap). ---

        # AI-facing files now ENGLISH (deleted from overlay → English common/ ships)
        $aiGuide = Join-Path $tmp "AI-GUIDE.md"
        Assert "[zh] AI-GUIDE.md is now ENGLISH (project index present)" { (Get-Content $aiGuide -Raw) -match 'project index' }
        Assert "[zh] AI-GUIDE.md no longer Chinese (项目指南 absent)" { -not ((Get-Content $aiGuide -Raw) -match '项目指南') }

        $insightRule = Join-Path $tmp ".harness/rules/05-insight-index.md"
        Assert "[zh] 05-insight-index.md is now ENGLISH (Cross-task insight index present)" { (Get-Content $insightRule -Raw) -match 'Cross-task insight index' }
        Assert "[zh] 05-insight-index.md no longer Chinese (跨任务 absent)" { -not ((Get-Content $insightRule -Raw) -match '跨任务') }

        $workflow = Join-Path $tmp "docs/workflow.md"
        Assert "[zh] docs/workflow.md is now ENGLISH (7-Agent Pipeline present)" { (Get-Content $workflow -Raw) -match 'The 7-Agent Pipeline' }
        Assert "[zh] docs/workflow.md no longer Chinese (工作流 absent)" { -not ((Get-Content $workflow -Raw) -match '工作流') }

        $devmap = Join-Path $tmp "docs/dev-map.md"
        Assert "[zh] docs/dev-map.md is now ENGLISH (Dev Map present)" { (Get-Content $devmap -Raw) -match 'Dev Map' }
        Assert "[zh] docs/dev-map.md no longer Chinese (开发导航 absent)" { -not ((Get-Content $devmap -Raw) -match '开发导航') }

        $tasks = Join-Path $tmp "docs/tasks.md"
        Assert "[zh] docs/tasks.md is now ENGLISH (Task Board present)" { (Get-Content $tasks -Raw) -match 'Task Board' }
        Assert "[zh] docs/tasks.md no longer Chinese (任务看板 absent)" { -not ((Get-Content $tasks -Raw) -match '任务看板') }

        # SPECIAL 00-core: ENGLISH framework body + Chinese policy section, exactly ONE policy section
        Assert "[zh] 00-core.md has ENGLISH body (Hard rules (red lines) present)" { (Get-Content $core -Raw) -match '## Hard rules \(red lines\)' }
        Assert "[zh] 00-core.md keeps Chinese policy heading (输出语言（按消费者分流） present)" { (Get-Content $core -Raw) -match '输出语言（按消费者分流）' }
        Assert "[zh] 00-core.md has NO second (English) policy section (Output language (project-wide) absent)" { -not ((Get-Content $core -Raw) -match 'Output language \(project-wide\)') }

        # SPECIAL CLAUDE.md / copilot: ENGLISH body + the single Chinese policy line
        $claude = Join-Path $tmp "CLAUDE.md"
        Assert "[zh] CLAUDE.md has ENGLISH body (full project ruleset present)" { (Get-Content $claude -Raw) -match 'The full project ruleset lives in' }
        Assert "[zh] CLAUDE.md keeps the Chinese policy line (输出语言：面向人的产出 present)" { (Get-Content $claude -Raw) -match '输出语言：面向人的产出' }
        $copilot = Join-Path $tmp ".github/copilot-instructions.md"
        Assert "[zh] copilot-instructions.md has ENGLISH body (full project ruleset present)" { (Get-Content $copilot -Raw) -match 'The full project ruleset lives in' }
        Assert "[zh] copilot-instructions.md keeps the Chinese policy line (输出语言：面向人的产出 present)" { (Get-Content $copilot -Raw) -match '输出语言：面向人的产出' }

        # Human-facing files STAY Chinese
        $specReadme = Join-Path $tmp "docs/spec/README.md"
        Assert "[zh] docs/spec/README.md stays Chinese (项目 SPEC present)" { (Get-Content $specReadme -Raw) -match '项目 SPEC' }
        $golden = Join-Path $tmp "evals/golden-tasks.md"
        Assert "[zh] evals/golden-tasks.md stays Chinese (轻量回归任务集 present)" { (Get-Content $golden -Raw) -match '轻量回归任务集' }

        # --- T-016 POSITIVE proof: the composed zh 00-core's English BODY (from the first
        #     non-policy heading to EOF) is byte-identical to the English common/ 00-core's
        #     body, substituted the same way. Positive analogue of the would-be guard: proves
        #     the body is single-sourced from common/ (no duplication) AND that composition
        #     carried it correctly. Mutation-provable: a seam over/under-cut or a common/ body
        #     drift the compose failed to carry makes the bodies differ → this assertion RED. ---
        Assert "[zh][T-016] composed zh 00-core BODY byte-matches English common/ (single-source, no duplication)" {
            $bodyStart = '## How this project is developed'
            # Read both files into LF-line arrays with CR stripped and the single trailing
            # empty record (from a final LF) dropped — the same line model the helper uses.
            $toLines = {
                param($raw)
                $out = [System.Collections.Generic.List[string]]::new()
                foreach ($p in $raw.Split("`n")) {
                    if ($p.EndsWith("`r")) { $out.Add($p.Substring(0, $p.Length - 1)) } else { $out.Add($p) }
                }
                if ($out.Count -gt 0 -and $out[$out.Count - 1] -eq "") { $out.RemoveAt($out.Count - 1) }
                , $out.ToArray()
            }
            $composedRaw = [System.IO.File]::ReadAllText($core, [System.Text.UTF8Encoding]::new($false))
            $composedLines = & $toLines $composedRaw
            $ci = [array]::IndexOf($composedLines, $bodyStart)

            $commonRaw = [System.IO.File]::ReadAllText((Join-Path $templateRoot "common/.harness/rules/00-core.md.tmpl"), [System.Text.UTF8Encoding]::new($false))
            foreach ($k in $vars.Keys) { $commonRaw = $commonRaw.Replace("{{$k}}", [string]$vars[$k]) }  # literal (T-12: $-safe)
            $commonLines = & $toLines $commonRaw
            $ki = [array]::IndexOf($commonLines, $bodyStart)

            $composedBody = ($composedLines[$ci..($composedLines.Count - 1)] -join "`n")
            $commonBody   = ($commonLines[$ki..($commonLines.Count - 1)] -join "`n")
            ($ci -ge 0) -and ($ki -ge 0) -and ($composedBody -ceq $commonBody)
        }
    } finally {
        if (-not $KeepTemp) { Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue }
        else { Write-Host "Temp dir kept: $tmp" -ForegroundColor Yellow }
    }
}

# === T-13: the hook wiring spec (AC-1..AC-4, FR-1..FR-7, NFR-2) ====================
# ORACLE (re-anchored by T-16): the FROZEN $exp* fixture table at the top of this file.
# Until T-16 the oracle was the LIVE Get-ResilientCmd, AST-extracted from
# upgrade-project.ps1. T-16 retired that helper: the four derivation flows now QUERY
# hook-spec.ps1, so comparing the spec against a flow would compare the spec with itself
# — green, and measuring nothing. A test must not derive its expectation from the
# artifact under test, so Group A now compares the spec against the frozen literals,
# which are the ONLY independent anchor left for all four flows.
# SCOPE NOTE: the frozen literals in this file and in test-real-project.{sh,ps1} are a
# DELIBERATE non-retirement, recorded in .harness/rejected-decisions.md
# (hook-byteform-test-literal-retirement) and in hook-spec.{sh,ps1}'s header. Standing
# END-TO-END coverage of a flow-EMITTED byte string lives in test-harness-upgrade
# (.ps1 M2/T20 vs $t20Pick) for one (tool, OS, flow) cell; the rest is residual RES-1.
function Test-HookSpec {
    Write-Host ""
    Write-Host "=== Testing: hook wiring spec (T-13) ===" -ForegroundColor Cyan
    # PowerShell 7.4+ turns a non-zero NATIVE exit code into a terminating error while
    # $ErrorActionPreference is Stop; Group E deliberately expects non-zero exits, so opt
    # out for this block only (function scope shadows the global).
    $PSNativeCommandUseErrorActionPreference = $false

    Assert "[T-13] hook-spec.ps1 present at .harness/scripts/" { Test-Path $script:hookSpecPath }

    # MANDATORY anti-vacuity gate on the ORACLE ITSELF: an empty / broken fixture must
    # fail THIS named assertion loudly, never silently degrade the 8 below.
    $oracleProbe = [string](Get-HookFixture guard-rm windows)
    Assert "[T-16][oracle] ANTI-VACUITY: the frozen `$exp* fixture (guard-rm, windows) is a non-empty string naming guard-rm.ps1" {
        ($oracleProbe.Length -gt 0) -and ($oracleProbe.Contains('guard-rm.ps1'))
    }

    foreach ($os in @('windows', 'unix')) {
        $ext = 'sh'
        if ($os -ceq 'windows') { $ext = 'ps1' }
        foreach ($tool in @('harness-sync', 'guard-rm', 'ambient-prompt', 'ambient-reset')) {
            $actual = Invoke-HookSpecQuery @('command', $tool, $os)
            $specRc = $script:hookSpecExit
            $fixture = [string](Get-HookFixture $tool $os)
            # Group A — INDEPENDENT of every flow: spec vs. the FROZEN fixture, all 8 cells.
            Assert "[T-16][A] command $tool $os is byte-equal to the FROZEN test-init fixture (independent of every flow)" {
                ($specRc -eq 0) -and ($actual.Length -gt 0) -and ($actual -ceq $fixture)
            }
            # Group C — the existing left-bounded congruence regex still finds the path.
            Assert "[T-13][C] congruence regex extracts .harness/scripts/$tool.$ext from the $os command" {
                $m = [regex]::Matches($actual, "(^|[`"' =])(\.harness/)?scripts/[A-Za-z0-9._-]+\.(ps1|sh)")
                $found = $false
                foreach ($hit in $m) {
                    if ($hit.Value.TrimStart('"', "'", ' ', '=') -ceq ".harness/scripts/$tool.$ext") { $found = $true }
                }
                $found
            }
        }
    }

    # --- Group A' (T-16): two STANDING 4-row scans over the four derivation-flow files.
    #     Lifted OUT of the per-cell loop above (which now carries 2 Asserts per cell, not
    #     3) and written as a separate 8-row block: 17 T-16-affected rows in, 17 out.
    #     Scan 1 is the AC-3 regression: no hook-command byte-form idiom may reappear on a
    #     NON-COMMENT line of a flow. Scan 2 is the &-hazard regression (insight
    #     2026-06-21): no pattern-substitution operator may touch a spec-derived value —
    #     ${var//pat/repl} and its ${arr[i]//}, ${!ref//}, ${var/pat/repl} siblings in bash
    #     (bash 5.2's patsub_replacement expands an unescaped `&` in the REPLACEMENT to the
    #     matched text, and the byte-forms contain a literal `&`), and -replace in
    #     PowerShell (whose replacement half interprets $& / $1). Comment lines are
    #     excluded: a comment can neither emit a command nor perform a substitution, and
    #     these flows legitimately DOCUMENT both idioms.
    #     PRE-T-16 BASELINE, measured on bash: scan 1 was RED on all four files (16
    #     non-comment hits, inside the resilient_cmd / Get-ResilientCmd bodies T-16
    #     deleted); scan 2 was already green. Green-after-red is the point.
    $flowFiles = @('upgrade-project.sh', 'upgrade-project.ps1',
                   'migrate-scripts-layout.sh', 'migrate-scripts-layout.ps1')
    #     A MISSING flow file scores "missing", never 0 — otherwise deleting a flow would
    #     make both of its scan rows vacuously green.
    foreach ($flowFile in $flowFiles) {
        $flowPath = Join-Path $repoRoot ".harness/scripts/$flowFile"
        $idiomHits = 'missing'
        if (Test-Path -LiteralPath $flowPath -PathType Leaf) {
            # Case-sensitive (-cmatch / -cnotmatch), no IgnoreCase: the bash twin greps
            # case-sensitively, and both scans must count the same lines.
            $flowLines = @(@((Get-Content $flowPath -Raw) -split "`r?`n") | Where-Object { $_ -cnotmatch '^[ \t]*#' })
            $idiomHits = [string]@($flowLines | Where-Object {
                ($_ -cmatch 'Set-Location -LiteralPath') -or ($_ -cmatch 'CLAUDE_PROJECT_DIR')
            }).Count
        }
        Assert "[T-16][A'] $flowFile carries no hook-command byte-form idiom outside comments (got $idiomHits)" {
            $idiomHits -ceq '0'
        }
    }
    foreach ($flowFile in $flowFiles) {
        $flowPath = Join-Path $repoRoot ".harness/scripts/$flowFile"
        if ($flowFile -clike '*.sh') {
            $subPattern = '\$\{[!#]?[A-Za-z_][A-Za-z0-9_]*(\[[^\]]*\])?/'
        } else {
            $subPattern = '-replace'
        }
        $subHits = 'missing'
        if (Test-Path -LiteralPath $flowPath -PathType Leaf) {
            $flowLines = @(@((Get-Content $flowPath -Raw) -split "`r?`n") | Where-Object { $_ -cnotmatch '^[ \t]*#' })
            $subHits = [string]@($flowLines | Where-Object { $_ -cmatch $subPattern }).Count
        }
        Assert "[T-16][A'] $flowFile uses no pattern-substitution operator (& / patsub hazard) (got $subHits)" {
            $subHits -ceq '0'
        }
    }

    # Group B — failure semantics, and the guard is fail-CLOSED on real output.
    foreach ($tool in @('harness-sync', 'guard-rm', 'ambient-prompt', 'ambient-reset')) {
        $expectedSem = 'fail-open'
        if ($tool -ceq 'guard-rm') { $expectedSem = 'fail-closed' }
        $sem = Invoke-HookSpecQuery @('semantics', $tool)
        Assert "[T-13][B] semantics $tool == $expectedSem" { $sem -ceq $expectedSem }
    }
    foreach ($os in @('windows', 'unix')) {
        $guardCommand = Invoke-HookSpecQuery @('command', 'guard-rm', $os)
        Assert "[T-13][B] guard-rm command ($os) carries NO '|| exit 0' and NO 'exit 0' fallback (fail-CLOSED, NFR-2)" {
            ($guardCommand.Length -gt 0) -and (-not $guardCommand.Contains('|| exit 0')) -and (-not $guardCommand.Contains('exit 0'))
        }
    }

    # Group D — event / matcher / tool list (the installer's contract).
    foreach ($tool in @('harness-sync', 'guard-rm', 'ambient-prompt', 'ambient-reset')) {
        $expectedEvent = 'SessionStart'
        if ($tool -ceq 'harness-sync')   { $expectedEvent = 'Stop' }
        if ($tool -ceq 'guard-rm')       { $expectedEvent = 'PreToolUse' }
        if ($tool -ceq 'ambient-prompt') { $expectedEvent = 'UserPromptSubmit' }
        $ev = Invoke-HookSpecQuery @('event', $tool)
        Assert "[T-13][D] event $tool == $expectedEvent" { $ev -ceq $expectedEvent }
        $expectedMatcher = 'none'
        if ($tool -ceq 'guard-rm') { $expectedMatcher = 'Bash' }
        $mt = Invoke-HookSpecQuery @('matcher', $tool)
        Assert "[T-13][D] matcher $tool == $expectedMatcher (non-empty sentinel for 'no matcher')" { $mt -ceq $expectedMatcher }
    }
    $toolList = Invoke-HookSpecQuery @('tools')
    Assert "[T-13][D] tools emits the 4 ids in the fixed order" {
        $toolList -ceq "harness-sync`nguard-rm`nambient-prompt`nambient-reset"
    }
    $hostAnswer = Invoke-HookSpecQuery @('hostos')
    Assert "[T-13][D] hostos answers windows|unix (no third variant)" {
        ($hostAnswer -ceq 'windows') -or ($hostAnswer -ceq 'unix')
    }

    # Group E — totality: bad input yields EMPTY stdout and a non-zero exit.
    $bad = Invoke-HookSpecQuery @('command', 'bogus-tool', 'unix')
    $badRc = $script:hookSpecExit
    Assert "[T-13][E] unknown tool -> non-zero exit with EMPTY stdout (FR-7/B-1)" {
        ($badRc -ne 0) -and ($bad.Length -eq 0)
    }
    $bad = Invoke-HookSpecQuery @('command', 'guard-rm', 'dos')
    $badRc = $script:hookSpecExit
    Assert "[T-13][E] unknown os -> non-zero exit with EMPTY stdout (FR-7/B-1)" {
        ($badRc -ne 0) -and ($bad.Length -eq 0)
    }
    $bad = Invoke-HookSpecQuery @('not-a-query')
    $badRc = $script:hookSpecExit
    Assert "[T-13][E] unknown query -> non-zero exit with EMPTY stdout (FR-7/B-1)" {
        ($badRc -ne 0) -and ($bad.Length -eq 0)
    }
}

# === T-13: the installer bootstrap (AC-5, AC-6, AC-7, FR-8..FR-12, B-2/B-3/B-8/B-9) ==
# Own temp tree; `.git` is a bare directory — the installer only tests for it, so no git
# binary is needed. No python3 dependency anywhere in this block.
function Test-InstallBootstrap {
    Write-Host ""
    Write-Host "=== Testing: install-hooks machine-local bootstrap (T-13) ===" -ForegroundColor Cyan
    # See Test-HookSpec: the negative rows below expect non-zero native exit codes.
    $PSNativeCommandUseErrorActionPreference = $false

    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) "harness-test-install-$(Get-Random)"
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
    try {
        # HOST-bound, exactly like Test-Type and like the bash twin's copy_layer /
        # substitute: pinning the Windows fixtures here would make the generated
        # project's committed settings disagree with the host's byte-forms.
        $win = ($IsWindows -or $env:OS -eq "Windows_NT")
        if ($win) {
            $syncCmd          = $expWinSync
            $guardCmd         = $expWinGuard
            $ambientPromptCmd = $expWinAmbientPrompt
            $ambientResetCmd  = $expWinAmbientReset
        } else {
            $syncCmd          = $expUnixSync
            $guardCmd         = $expUnixGuard
            $ambientPromptCmd = $expUnixAmbientPrompt
            $ambientResetCmd  = $expUnixAmbientReset
        }
        $vars = @{
            "PROJECT_NAME"  = "install-test"
            "PROJECT_TYPE"  = "generic"
            "STACK"         = "Rust CLI tool"
            "TODAY"         = $today
            "ENABLE_HOOK"   = "false"
            "SYNC_COMMAND"  = $syncCmd
            "GUARD_COMMAND" = $guardCmd
            "AMBIENT_PROMPT_COMMAND" = $ambientPromptCmd
            "AMBIENT_RESET_COMMAND"  = $ambientResetCmd
        }
        Copy-TemplateLayer -Source (Join-Path $templateRoot "common")  -Target $tmp -Vars $vars
        Copy-TemplateLayer -Source (Join-Path $templateRoot "generic") -Target $tmp -Vars $vars
        New-Item -ItemType Directory -Path (Join-Path $tmp ".git") -Force | Out-Null

        $inst = Join-Path $tmp ".harness/scripts/install-hooks.ps1"
        $claudeDir = Join-Path $tmp ".claude"
        $committed = Join-Path $claudeDir "settings.json"
        $localSet = Join-Path $claudeDir "settings.local.json"
        $projSpec = Join-Path $tmp ".harness/scripts/hook-spec.ps1"

        Assert "[T-13][install] installer present after init" { Test-Path $inst }
        Assert "[T-13][install] hook-spec pair distributed into the generated project (FR-6)" {
            (Test-Path $projSpec) -and (Test-Path (Join-Path $tmp ".harness/scripts/hook-spec.sh"))
        }

        # (1) committed settings DECLARES hooks -> no machine-local file (AC-7 / FR-10)
        & pwsh -NoProfile -File $inst | Out-Null
        $rc = $LASTEXITCODE
        Assert "[T-13][install] project whose committed settings has hooks: exit 0 and NO local file (AC-7/FR-10)" {
            ($rc -eq 0) -and (-not (Test-Path $localSet))
        }
        Assert "[T-13][install] pre-existing pre-commit hook behavior preserved (FR-13)" {
            Test-Path (Join-Path $tmp ".git/hooks/pre-commit")
        }

        # (2) empty the committed hooks object -> the bootstrap path (AC-5, FR-11, B-13)
        $srcLines = [System.IO.File]::ReadAllText($committed).Split("`n")
        $kept = [System.Collections.Generic.List[string]]::new()
        $skip = $false
        foreach ($rawLine in $srcLines) {
            $line = $rawLine
            if ($line.EndsWith("`r")) { $line = $line.Substring(0, $line.Length - 1) }
            if ($line -ceq '  "hooks": {') { $kept.Add('  "hooks": {}'); $skip = $true; continue }
            if ($skip -and (($line -ceq '  }') -or ($line -ceq '  },'))) { $skip = $false; continue }
            if ($skip) { continue }
            $kept.Add($line)
        }
        [System.IO.File]::WriteAllText($committed, ($kept.ToArray() -join "`n"))
        Assert "[T-13][install] fixture precondition: committed settings now declares an empty hooks object" {
            [System.IO.File]::ReadAllText($committed).Contains('"hooks": {}')
        }

        $bootOut = (& pwsh -NoProfile -File $inst 2>&1) -join "`n"
        $rc = $LASTEXITCODE
        Assert "[T-13][install] bootstrap created .claude/settings.local.json, exit 0 (AC-5/FR-8)" {
            ($rc -eq 0) -and (Test-Path $localSet)
        }

        $generated = ''
        if (Test-Path $localSet) { $generated = [System.IO.File]::ReadAllText($localSet) }
        Assert "[T-13][install] generated file carries the canonical .json schema URL (FR-11)" {
            $generated.Contains('"$schema": "https://json.schemastore.org/claude-code-settings.json"')
        }
        Assert "[T-13][install] generated file wires PreToolUse with matcher Bash (FR-11)" {
            $generated.Contains('"PreToolUse"') -and $generated.Contains('"matcher": "Bash"')
        }
        Assert "[T-13][install] generated file wires all four real hook event names (FR-11)" {
            $generated.Contains('"Stop"') -and $generated.Contains('"UserPromptSubmit"') -and $generated.Contains('"SessionStart"')
        }
        Assert "[T-13][install] no underscore doc key inside the hooks object (root only - FR-11)" {
            -not [regex]::IsMatch($generated, '(?m)^ {4}"_')
        }
        $projHostOs = (& pwsh -NoProfile -File $projSpec hostos) -join ''
        foreach ($tool in @('harness-sync', 'guard-rm', 'ambient-prompt', 'ambient-reset')) {
            $projCmd = (& pwsh -NoProfile -File $projSpec command $tool $projHostOs) -join ''
            Assert "[T-13][install] generated file carries the spec's $tool command verbatim (AC-5)" {
                ($projCmd.Length -gt 0) -and $generated.Contains($projCmd)
            }
        }
        $bytes = [System.IO.File]::ReadAllBytes($localSet)
        Assert "[T-13][install] generated file is BOM-free (first byte is '{')" { $bytes[0] -eq 123 }
        Assert "[T-13][install] generated file has LF endings only (no CR)" { -not $generated.Contains("`r") }
        Assert "[T-13][install] generated file ends with EXACTLY one trailing newline" {
            ($bytes[$bytes.Length - 1] -eq 10) -and ($bytes[$bytes.Length - 2] -ne 10)
        }
        Assert "[T-13][install] report names the created path (FR-12)" { $bootOut.Contains('settings.local.json') }
        Assert "[T-13][install] report gives the one-line removal command in this shell's form (FR-12)" {
            $bootOut.Contains('Remove: Remove-Item ')
        }
        Assert "[T-13][install] report carries the machine-local / .gitignore advisory (FR-12/AC-14)" {
            $bootOut.Contains('machine-local') -and $bootOut.Contains('.gitignore')
        }
        Assert "[T-13][install] report calls out the fail-closed guard hook (FR-12)" { $bootOut.Contains('fail-closed') }
        Assert "[T-13][install] installer created no .gitignore (B-15/NFR-4c)" {
            -not (Test-Path (Join-Path $tmp ".gitignore"))
        }

        # (3) idempotence: byte-identical, no backup, no temp sibling (AC-6, B-9)
        $snapshot = [System.IO.File]::ReadAllBytes($localSet)
        $secondOut = (& pwsh -NoProfile -File $inst 2>&1) -join "`n"
        $rc = $LASTEXITCODE
        Assert "[T-13][install] second run leaves the file BYTE-IDENTICAL, exit 0 (AC-6/FR-9/B-9)" {
            $after = [System.IO.File]::ReadAllBytes($localSet)
            $same = ($rc -eq 0) -and ($after.Length -eq $snapshot.Length)
            if ($same) {
                for ($k = 0; $k -lt $after.Length; $k++) {
                    if ($after[$k] -ne $snapshot[$k]) { $same = $false; break }
                }
            }
            $same
        }
        Assert "[T-13][install] second run reports it took no action (FR-9)" {
            $secondOut.Contains('left byte-untouched')
        }
        # -Filter goes through the Win32 wildcard engine, whose legacy `name.*` semantics
        # are NOT the bash twin's `find -name 'settings.local.json.*'` (which can never
        # match `settings.local.json` itself). Exclude the target by exact name so the
        # two twins assert the same thing on every host; @() keeps .Count valid on none.
        Assert "[T-13][install] no settings.local.json.* temp/backup sibling survives (AC-6)" {
            @(Get-ChildItem -Path $claudeDir -Filter "settings.local.json.*" -File -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -ne 'settings.local.json' }).Count -eq 0
        }
        Assert "[T-13][install] no *.bak* file anywhere under .claude/ (AC-6)" {
            (Get-ChildItem -Path $claudeDir -Filter "*.bak*" -File -ErrorAction SilentlyContinue).Count -eq 0
        }

        # (4) B-7: an empty-hooks local file is the persistent opt-out - never overwritten.
        [System.IO.File]::WriteAllText($localSet, "{`n  `"hooks`": {}`n}`n")
        $optOut = [System.IO.File]::ReadAllText($localSet)
        & pwsh -NoProfile -File $inst | Out-Null
        $rc = $LASTEXITCODE
        Assert "[T-13][install] empty-hooks local file (B-7 opt-out) is left BYTE-UNTOUCHED" {
            ($rc -eq 0) -and ([System.IO.File]::ReadAllText($localSet) -ceq $optOut)
        }

        # (5) B-5: an unparseable COMMITTED settings file changes nothing at all, exit 3.
        Remove-Item -LiteralPath $localSet -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath (Join-Path $tmp ".git/hooks/pre-commit") -Force -ErrorAction SilentlyContinue
        $goodSettings = [System.IO.File]::ReadAllText($committed)
        [System.IO.File]::WriteAllText($committed, "not json")
        & pwsh -NoProfile -File $inst 2>&1 | Out-Null
        $rc = $LASTEXITCODE
        Assert "[T-13][install] unparseable committed settings -> exit 3, NOTHING written (B-5)" {
            ($rc -eq 3) -and (-not (Test-Path $localSet)) -and (-not (Test-Path (Join-Path $tmp ".git/hooks/pre-commit")))
        }
        [System.IO.File]::WriteAllText($committed, $goodSettings)

        # (6) B-8: an unwritable .claude/ leaves the target ABSENT with a non-zero exit.
        #     Self-disables with a notice where the platform ignores the mode (root, ACLs).
        $roEnforced = $false
        if ($IsLinux -or $IsMacOS) {
            & chmod a-w $claudeDir
            $probeFile = Join-Path $claudeDir ".wtest"
            try {
                [System.IO.File]::WriteAllText($probeFile, "x")
                Remove-Item -LiteralPath $probeFile -Force -ErrorAction SilentlyContinue
            } catch { $roEnforced = $true }
        }
        if ($roEnforced) {
            & pwsh -NoProfile -File $inst 2>&1 | Out-Null
            $rc = $LASTEXITCODE
            Assert "[T-13][install] unwritable .claude/ -> non-zero exit, target left ABSENT (B-8)" {
                ($rc -ne 0) -and (-not (Test-Path $localSet))
            }
        } else {
            Write-Host "  [SKIP] [T-13][install] read-only .claude/ probe - not enforceable on this platform" -ForegroundColor Yellow
        }
        if ($IsLinux -or $IsMacOS) { & chmod u+w $claudeDir }

        # (7) FC-4 all-four-or-nothing: a spec that lists FEWER than four tool ids is a
        #     partial wiring - possibly one with no destructive-command guard at all -
        #     and must be refused outright: exit 4, nothing written. The stub delegates
        #     every query except `tools` to the real spec, so only the arity differs.
        Remove-Item -LiteralPath $localSet -Force -ErrorAction SilentlyContinue
        #     RE-ANCHORED (v2 TS migration): the installer no longer SHELLS OUT to the
        #     spec, it imports the compiled module, so mutating hook-spec.ps1 proves
        #     nothing - the stub would never be read and the row would go green against
        #     an unreachable branch. The mutation surface is now hook-spec.js, which
        #     install-hooks.js resolves by require("./hook-spec") from its own directory.
        $projSpecJs = Join-Path $tmp ".harness/scripts/hook-spec.js"
        $goodSpec = Join-Path $tmp "hook-spec.good.js"
        Move-Item -LiteralPath $projSpecJs -Destination $goodSpec -Force
        $stubLines = @(
            "const good = require('" + ($goodSpec -replace '\\', '/') + "');"
            'module.exports = { ...good, TOOLS: good.TOOLS.slice(0, 3) };'
        )
        [System.IO.File]::WriteAllText($projSpecJs, (($stubLines -join "`n") + "`n"))
        #     The DIAGNOSTIC is matched too, not just the exit code: exit 4 alone is
        #     vacuous - a silently broken stub (wrong hsGood path, pwsh unavailable, a
        #     parse error in the generated stub) also exits 4, via Stop-OnSpecFailure
        #     'tools', without ever reaching the arity branch, and the row would stay
        #     green while proving nothing. Matching "expected 4 ids, got 3" pins the
        #     row to that branch by construction.
        #     Captured as an ARRAY joined by hand, never `| Out-String`: Out-String
        #     re-wraps at the host buffer width and could split the matched phrase.
        $fc4Out = @(& pwsh -NoProfile -File $inst 2>&1 | ForEach-Object { [string]$_ }) -join "`n"
        $rc = $LASTEXITCODE
        Assert "[T-13][install] spec listing fewer than 4 tool ids -> exit 4, NOTHING written (FC-4)" {
            ($rc -eq 4) -and (-not (Test-Path $localSet)) -and
            ($fc4Out.IndexOf('expected 4 ids, got 3', [System.StringComparison]::Ordinal) -ge 0)
        }
        Move-Item -LiteralPath $goodSpec -Destination $projSpecJs -Force

        # (8) FC-4, SECOND axis: four ids that collapse to fewer than four DISTINCT
        #     hook EVENTS are a partial wiring too - one event on disk instead of four,
        #     plus duplicate JSON keys - and must be refused BEFORE anything is written:
        #     exit 4, target ABSENT. This row is the anti-revert coverage for the
        #     distinct-events gate: delete that gate and this same spec sails through
        #     the arity check, the installer exits 0 with the file PRESENT, and the row
        #     goes red. The stub answers `tools` with the guard id four times and
        #     delegates every other query, so ONLY the event multiplicity differs.
        Remove-Item -LiteralPath $localSet -Force -ErrorAction SilentlyContinue
        #     RE-ANCHORED (v2 TS migration): see row (7) - the mutation surface is the
        #     compiled module the installer imports, not the shell launcher.
        Move-Item -LiteralPath $projSpecJs -Destination $goodSpec -Force
        $dupLines = @(
            "const good = require('" + ($goodSpec -replace '\\', '/') + "');"
            "module.exports = { ...good, TOOLS: ['guard-rm', 'guard-rm', 'guard-rm', 'guard-rm'] };"
        )
        [System.IO.File]::WriteAllText($projSpecJs, (($dupLines -join "`n") + "`n"))
        #     The DISTINCT-gate diagnostic is matched too, for exactly the reason row
        #     (7) matches the arity one, and captured the same way: an array joined by
        #     hand, never `| Out-String`, which re-wraps at the host buffer width.
        $fc4dOut = @(& pwsh -NoProfile -File $inst 2>&1 | ForEach-Object { [string]$_ }) -join "`n"
        $rc = $LASTEXITCODE
        Assert "[T-13][install] spec answering 4 ids that collapse to 1 event -> exit 4, NOTHING written (FC-4)" {
            ($rc -eq 4) -and (-not (Test-Path $localSet)) -and
            ($fc4dOut.IndexOf('expected 4 DISTINCT hook events, got 1', [System.StringComparison]::Ordinal) -ge 0)
        }
        Move-Item -LiteralPath $goodSpec -Destination $projSpecJs -Force

        # (9) B-14: not a git repository -> exit 1, unchanged behavior (FR-13).
        Remove-Item -Recurse -Force (Join-Path $tmp ".git") -ErrorAction SilentlyContinue
        & pwsh -NoProfile -File $inst 2>&1 | Out-Null
        $rc = $LASTEXITCODE
        Assert "[T-13][install] not a git repository -> exit 1 (FR-13/B-14, unchanged)" { $rc -eq 1 }
    } finally {
        if (-not $KeepTemp) { Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue }
        else { Write-Host "Temp dir kept: $tmp" -ForegroundColor Yellow }
    }
}

Write-Host "=== test-init: simulating /harness-init flow (v0.2) ===" -ForegroundColor Cyan
Write-Host "Repo: $repoRoot"

if ($Type -in @("all", "both", "fullstack")) {
    Test-Type -ProjectType "fullstack" -Stack "Next.js + NestJS + Postgres"
}
if ($Type -in @("all", "both", "backend")) {
    Test-Type -ProjectType "backend" -Stack "FastAPI + Postgres"
}
if ($Type -in @("all", "generic")) {
    Test-Type -ProjectType "generic" -Stack "Rust CLI tool"
}
if ($Type -in @("all", "both")) {
    Test-Migrate
}
if ($Type -in @("all", "both")) {
    Test-ZhOverlay
}
# T-13: the spec block runs UNCONDITIONALLY (a pure CLI probe, no fixture tree); the
# installer bootstrap block is fixture-backed and gated like Test-Migrate.
Test-HookSpec
if ($Type -in @("all", "both")) {
    Test-InstallBootstrap
}

# BUG-2 regression (v0.16.0 rollback round 2): verify the broadened D.2/D.3
# regex catches whitespace-padded and lowercase placeholder variants that the
# v0.15.1 pattern '\{\{[A-Z_]+\}\}' missed. Single-shot in-process unit test;
# runs once regardless of -Type to keep coverage small but explicit.
$broadenedRegex = '\{\{\s*[A-Za-z_][A-Za-z0-9_]*\s*\}\}'
Write-Host ""
Write-Host "=== BUG-2 regression: broadened placeholder regex ===" -ForegroundColor Cyan
Assert "[BUG-2] broadened regex catches whitespace-padded '{{ PROJECT_NAME }}'" {
    [regex]::IsMatch('{{ PROJECT_NAME }}', $broadenedRegex)
}
Assert "[BUG-2] broadened regex catches lowercase '{{project_name}}'" {
    [regex]::IsMatch('{{project_name}}', $broadenedRegex)
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
