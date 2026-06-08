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
                $content = $content -replace [regex]::Escape("{{$k}}"), $Vars[$k]
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
        $syncCmd = if ($IsWindows -or $env:OS -eq "Windows_NT") {
            "pwsh -NoProfile -File .harness/scripts/harness-sync.ps1"
        } else {
            "bash .harness/scripts/harness-sync.sh"
        }
        $guardCmd = if ($IsWindows -or $env:OS -eq "Windows_NT") {
            "pwsh -NoProfile -File .harness/scripts/guard-rm.ps1"
        } else {
            "bash .harness/scripts/guard-rm.sh"
        }
        $vars = @{
            "PROJECT_NAME"  = "test-project"
            "PROJECT_TYPE"  = $ProjectType
            "STACK"         = $Stack
            "TODAY"         = $today
            "ENABLE_HOOK"   = "false"
            "SYNC_COMMAND"  = $syncCmd
            "GUARD_COMMAND" = $guardCmd
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
        $agents = @("pm-orchestrator","requirement-analyst","solution-architect",
                    "gate-reviewer","developer","code-reviewer","qa-tester")
        foreach ($a in $agents) {
            Assert ".harness/agents/$a.md (SOT)" { Test-Path (Join-Path $tmp ".harness/agents/$a.md") }
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
        Assert ".harness/rules/50-$ProjectType.md (overlay)" { Test-Path (Join-Path $tmp ".harness/rules/50-$ProjectType.md") }

        # .harness/skills/ is fullstack/backend-only; generic ships without them (user fills in)
        if ($ProjectType -ne "generic") {
            foreach ($s in @("build","test","verify")) {
                Assert ".harness/skills/$s/SKILL.md (SOT)" { Test-Path (Join-Path $tmp ".harness/skills/$s/SKILL.md") }
            }
        }

        # === Generated artifacts (.claude/ + CLAUDE.md) ===
        foreach ($a in $agents) {
            Assert ".claude/agents/$a.md (generated)" { Test-Path (Join-Path $tmp ".claude/agents/$a.md") }
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
                    $tmplContent = $tmplContent -replace [regex]::Escape("{{$k}}"), $vars[$k]
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
            # Simulate accept: write the file (per SKILL.md step 5b.9 Accept branch)
            if ($partA) {
                [System.IO.File]::WriteAllText((Join-Path $tmp ".harness/agents/dev-payments.md"), $partA.body)
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
        $vars = @{
            "PROJECT_NAME"  = "migrate-test"; "PROJECT_TYPE" = "generic"
            "STACK"         = "Rust CLI tool"; "TODAY" = $today; "ENABLE_HOOK" = "false"
            "SYNC_COMMAND"  = "pwsh -NoProfile -File .harness/scripts/harness-sync.ps1"
            "GUARD_COMMAND" = "pwsh -NoProfile -File .harness/scripts/guard-rm.ps1"
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
            Assert "[migrate] settings Stop command -> .harness/scripts/harness-sync.ps1" {
                $j = $s | ConvertFrom-Json
                $j.hooks.Stop[0].hooks[0].command -eq "pwsh -NoProfile -File .harness/scripts/harness-sync.ps1"
            }
            Assert "[migrate] settings PreToolUse command -> .harness/scripts/guard-rm.ps1" {
                $j = $s | ConvertFrom-Json
                $j.hooks.PreToolUse[0].hooks[0].command -eq "pwsh -NoProfile -File .harness/scripts/guard-rm.ps1"
            }
            Assert "[migrate] settings _doc_sync_hook doc string rewired (no stale bare scripts/harness-sync.)" {
                $j = $s | ConvertFrom-Json
                # Must contain the migrated form, and contain NO bare `scripts/harness-sync.`
                # that isn't part of `.harness/scripts/harness-sync.` (negative lookbehind on
                # a literal `scripts/...`, NOT on a `.`-any-char that the prior regex used and
                # which falsely matched the space before `.harness/...`).
                ($j._doc_sync_hook -match '\.harness/scripts/harness-sync\.sh') -and
                ($j._doc_sync_hook -notmatch '(?<!\.harness/)scripts/harness-sync\.')
            }
            Assert "[migrate] permissions.allow rewired to .harness/scripts/harness-sync.sh" {
                $j = $s | ConvertFrom-Json
                ($j.permissions.allow -join ' ') -match '\.harness/scripts/harness-sync\.sh'
            }
            Assert "[migrate] -NoProfile retained in both hook commands" {
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
        $vars = @{ "PROJECT_NAME"="zh-test"; "PROJECT_TYPE"="fullstack"; "STACK"="Next.js + NestJS";
                   "TODAY"=$today; "ENABLE_HOOK"="false";
                   "SYNC_COMMAND"="pwsh -NoProfile -File .harness/scripts/harness-sync.ps1";
                   "GUARD_COMMAND"="pwsh -NoProfile -File .harness/scripts/guard-rm.ps1" }
        Copy-TemplateLayer -Source (Join-Path $templateRoot "common")        -Target $tmp -Vars $vars
        Copy-TemplateLayer -Source (Join-Path $templateRoot "fullstack")      -Target $tmp -Vars $vars
        Copy-TemplateLayer -Source (Join-Path $templateRoot "i18n/zh/common") -Target $tmp -Vars $vars

        $core = Join-Path $tmp ".harness/rules/00-core.md"
        Assert "[zh] 00-core.md overlaid" { Test-Path $core }
        Assert "[zh] policy lists a Chinese-artifact (consumer=human) marker" { (Get-Content $core -Raw) -match '给用户的交付总结' }
        Assert "[zh] policy lists an English-artifact (consumer=agent) marker" { (Get-Content $core -Raw) -match 'commit message' }
        Assert "[zh] retired blunt 全程 phrasing is absent" { -not ((Get-Content $core -Raw) -match '全程') }
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
