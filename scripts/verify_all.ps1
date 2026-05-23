# verify_all.ps1 — Verification for the harness-engineering repo itself (tooling/skills project)
#
# Differs from project-template verify_all: checks Markdown / Shell / template integrity / self-consistency
# rather than build & test of a runtime stack.

[CmdletBinding()]
param([switch]$Quick)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path $PSScriptRoot -Parent
Push-Location $repoRoot
try {

$report = @()
$errors = 0
$warns = 0

function Step($id, $name, [scriptblock]$action) {
    Write-Host "[$id] $name ..." -NoNewline
    try {
        $r = & $action
        if ($r -eq $false) {
            Write-Host " WARN" -ForegroundColor Yellow
            $script:warns++
            $script:report += [pscustomobject]@{ id=$id; name=$name; status="WARN" }
        } else {
            Write-Host " PASS" -ForegroundColor Green
            $script:report += [pscustomobject]@{ id=$id; name=$name; status="PASS" }
        }
    } catch {
        Write-Host " FAIL" -ForegroundColor Red
        Write-Host "       $_" -ForegroundColor DarkRed
        $script:errors++
        $script:report += [pscustomobject]@{ id=$id; name=$name; status="FAIL"; error="$_" }
    }
}

Write-Host "=== verify_all (harness-engineering repo) ===" -ForegroundColor Cyan
Write-Host ""

# A. Hygiene
Step "A.1" "No accidentally-committed env or secrets" {
    $envFiles = git ls-files '*.env' '.env*' 2>$null | Where-Object { $_ -notmatch 'example|sample|tmpl' }
    if ($envFiles) { throw ".env committed:`n$envFiles" }
    $secrets = git grep -E "(?i)(api[_-]?key|secret|password|token)\s*[:=]\s*['""][^'""]{12,}['""]" -- ':!*.md' ':!scripts/verify_all*' ':!skills/*' 2>$null
    if ($secrets) { throw "Possible secret:`n$secrets" }
}

Step "A.2" "参考/ not tracked" {
    $tracked = git ls-files -- '参考/' 2>$null
    if ($tracked) { throw "参考/ should be gitignored but is tracked:`n$tracked" }
}

# B. Required top-level files
Step "B.1" "README / LICENSE / CHANGELOG present" {
    foreach ($f in @("README.md", "LICENSE", "CHANGELOG.md")) {
        if (-not (Test-Path $f)) { throw "Missing $f" }
    }
}

Step "B.2" "Install scripts present (both PowerShell + Bash)" {
    if (-not (Test-Path "install.ps1")) { throw "install.ps1 missing" }
    if (-not (Test-Path "install.sh")) { throw "install.sh missing" }
}

# C. Skills structure
Step "C.1" "All 11 skills present with SKILL.md" {
    foreach ($s in @("harness", "harness-init", "harness-adopt", "harness-verify", "harness-status", "harness-plan", "harness-explore", "harness-goal", "harness-intervene", "harness-supervise", "harness-batch")) {
        $p = "skills/$s/SKILL.md"
        if (-not (Test-Path $p)) { throw "Missing $p" }
    }
}

Step "C.2" "Skill frontmatter sanity" {
    $bad = @()
    Get-ChildItem skills -Recurse -Filter "SKILL.md" | ForEach-Object {
        $head = Get-Content $_.FullName -TotalCount 10
        if (-not ($head -match '^---')) { $bad += "$($_.FullName) — missing frontmatter" }
        if (-not ($head -match '^name:')) { $bad += "$($_.FullName) — missing name:" }
        if (-not ($head -match '^description:')) { $bad += "$($_.FullName) — missing description:" }
    }
    if ($bad.Count -gt 0) { throw "Skill frontmatter issues:`n$($bad -join "`n")" }
}

# D. Templates
Step "D.1" "All template agents present in templates/common/.harness/agents" {
    $tplAgents = "skills/harness-init/templates/common/.harness/agents"
    foreach ($a in @("pm-orchestrator","requirement-analyst","solution-architect","gate-reviewer","developer","code-reviewer","qa-tester")) {
        if (-not (Test-Path "$tplAgents/$a.md")) { throw "Missing template agent: $a" }
    }
}

Step "D.2" "Placeholders limited to documented set" {
    $allowed = @("{{PROJECT_NAME}}", "{{PROJECT_TYPE}}", "{{STACK}}", "{{TODAY}}", "{{ENABLE_HOOK}}", "{{SYNC_COMMAND}}", "{{GUARD_COMMAND}}")
    $tmplFiles = Get-ChildItem skills/harness-init/templates -Recurse -File | Where-Object {
        $_.Name -match '\.(tmpl|append)$'
    }
    $bad = @()
    foreach ($f in $tmplFiles) {
        $content = Get-Content $f.FullName -Raw
        # v0.16.0 BUG-2 rollback round 2: broaden regex to catch whitespace-padded
        # ('{{ PROJECT_NAME }}') and lowercase ('{{project_name}}') variants. AI
        # output can drift in either direction; allowlist still polices the form.
        # NOTE: -cnotin (case-sensitive) is intentional — PowerShell's default
        # -notin is case-insensitive, which would silently treat '{{stack}}' as
        # allowed because '{{STACK}}' is in the whitelist. With -cnotin we match
        # the bash twin's case-sensitive 'case' statement at verify_all.sh:78-80.
        $found = [regex]::Matches($content, '\{\{\s*[A-Za-z_][A-Za-z0-9_]*\s*\}\}') | ForEach-Object { $_.Value } | Sort-Object -Unique
        foreach ($p in $found) {
            if ($p -cnotin $allowed) { $bad += "$($f.Name): unknown placeholder $p" }
        }
    }
    if ($bad.Count -gt 0) { throw "Unknown placeholders:`n$($bad -join "`n")" }
}

Step "D.3" "AI-generated 50-*.md sanity (per-section sources, headings, no placeholders)" {
    # Per Gate Finding G: per-section, not file-global. Every `## ` or `### ` section
    # in every `.harness/rules/50-*.md` whose content is non-template must have
    # >=1 `<!-- source: <tag> -->` annotation. Plus: all six required headings
    # present in order; zero `{{...}}` literals.
    if (-not (Test-Path ".harness/rules")) { return }
    $files = Get-ChildItem -Path ".harness/rules" -Filter "50-*.md" -File -ErrorAction SilentlyContinue
    if (-not $files -or $files.Count -eq 0) { return }  # vacuously true; nothing to check

    $requiredHeadings = @(
        "## When to read",
        "## Build / test / verify",
        "## Project structure",
        "## Stack-specific conventions",
        "## Partitioning",
        "## Stack-specific verify_all checks"
    )
    $allowedSourceTags = @(
        "user-q2", "top-level-glob",
        "package.json", "Cargo.toml", "pyproject.toml", "requirements.txt",
        "go.mod", "pom.xml", "README.md"
    )

    $problems = @()
    foreach ($f in $files) {
        $content = Get-Content $f.FullName -Raw
        # (b) zero {{...}} literals
        # v0.16.0 BUG-2 rollback round 2: regex broadened to catch whitespace-padded
        # ('{{ PROJECT_NAME }}') and lowercase ('{{project_name}}') variants too.
        if ($content -match '\{\{\s*[A-Za-z_][A-Za-z0-9_]*\s*\}\}') {
            $problems += "$($f.Name): leaked placeholder {{...}}"
        }
        # (a) six required headings present in order
        $idx = 0
        foreach ($h in $requiredHeadings) {
            $i = $content.IndexOf($h, $idx)
            if ($i -lt 0) { $problems += "$($f.Name): missing required heading '$h' (or out of order)"; break }
            $idx = $i + $h.Length
        }
        # Per-section: split on ## / ###, every non-empty body must contain >=1 source annotation
        # Split the file into sections by '## ' or '### ' lines; skip the leading preamble before the first '##'.
        $lines = $content -split "`r?`n"
        $sections = @()
        $current = $null
        foreach ($line in $lines) {
            if ($line -match '^(##|###)\s+\S') {
                if ($null -ne $current) { $sections += ,$current }
                $current = [pscustomobject]@{ heading = $line; body = [System.Text.StringBuilder]::new() }
            } elseif ($null -ne $current) {
                [void]$current.body.AppendLine($line)
            }
        }
        if ($null -ne $current) { $sections += ,$current }
        foreach ($s in $sections) {
            $body = $s.body.ToString()
            # "template" section = body is empty or contains only the literal '<your ...>' placeholder text
            $trim = ($body -replace '\s', '')
            if ([string]::IsNullOrWhiteSpace($body)) { continue }
            if ($trim -match '^(<your[^>]+>|<command[^>]*>|-)*$') { continue }
            # Non-template section: must have at least one annotation
            $m = [regex]::Matches($body, '<!-- source: ([^\s>]+) -->')
            if ($m.Count -lt 1) {
                $problems += "$($f.Name): section '$($s.heading.Trim())' has non-template content but no <!-- source: ... --> annotation"
            } else {
                foreach ($match in $m) {
                    $tag = $match.Groups[1].Value
                    if ($tag -notin $allowedSourceTags) {
                        $problems += "$($f.Name): section '$($s.heading.Trim())' has unknown source tag '$tag' (must be one of: $($allowedSourceTags -join ', '))"
                    }
                }
            }
        }
    }
    if ($problems.Count -gt 0) { throw ($problems -join "`n") }
}

# E. Self-consistency (dogfood — two layers)
# Layer 1: templates/common/ → repo .harness/ + scripts/harness-sync
Step "E.1" "Layer 1: .harness/ matches templates/common/.harness/" {
    & (Join-Path $PSScriptRoot "sync-self.ps1") -Check
    if ($LASTEXITCODE -ne 0) { throw "Layer 1 drift — run scripts/sync-self.ps1 to fix" }
}

# Layer 2: .harness/ → .claude/ (binding, agents + skills only in v0.10)
Step "E.2" "Layer 2: .claude/agents and .claude/skills synced from .harness/" {
    & (Join-Path $PSScriptRoot "harness-sync.ps1") -Check
    if ($LASTEXITCODE -ne 0) { throw "Layer 2 drift — run scripts/harness-sync.ps1 to fix" }
}

Step "E.3" "Project rule sources present (.harness/rules + 7 agents)" {
    foreach ($f in @(".harness/agents/pm-orchestrator.md", ".harness/agents/developer.md")) {
        if (-not (Test-Path $f)) { throw "Missing $f" }
    }
    $rules = Get-ChildItem -Path ".harness/rules" -Filter "*.md" -File -ErrorAction SilentlyContinue
    if ($rules.Count -lt 1) { throw "No .harness/rules/*.md files found" }
}

Step "E.4" "Bootstrap files present and point to AI-GUIDE.md" {
    foreach ($f in @("AI-GUIDE.md", "CLAUDE.md", ".github/copilot-instructions.md")) {
        if (-not (Test-Path $f)) { throw "Missing $f" }
    }
    foreach ($stub in @("CLAUDE.md", ".github/copilot-instructions.md")) {
        $c = Get-Content $stub -Raw
        if ($c -notmatch 'AI-GUIDE\.md') { throw "$stub does not reference AI-GUIDE.md — stub broken" }
    }
    if (-not (Test-Path ".claude/agents")) { throw "Missing .claude/agents/ (run harness-sync)" }
}

Step "E.4b" "AI-GUIDE.md indexes every .harness/rules/*.md (and vice versa)" {
    if (-not (Test-Path "AI-GUIDE.md")) { throw "AI-GUIDE.md missing (E.4 should have caught this)" }
    if (-not (Test-Path ".harness/rules")) { return "SKIP" }
    $guide = Get-Content "AI-GUIDE.md" -Raw
    $actualRules = Get-ChildItem -Path ".harness/rules" -Filter "*.md" -File | ForEach-Object { $_.Name }

    $missingFromGuide = @()
    foreach ($rule in $actualRules) {
        # Look for ".harness/rules/<filename>" in AI-GUIDE.md
        if ($guide -notmatch [regex]::Escape(".harness/rules/$rule")) {
            $missingFromGuide += $rule
        }
    }

    # Reverse: every .harness/rules/<name>.md mentioned in AI-GUIDE.md must exist
    $referencedRules = [regex]::Matches($guide, '\.harness/rules/([0-9A-Za-z_\-]+\.md)') |
        ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
    $missingFromDisk = @()
    foreach ($ref in $referencedRules) {
        if (-not (Test-Path ".harness/rules/$ref")) {
            $missingFromDisk += $ref
        }
    }

    $problems = @()
    if ($missingFromGuide.Count -gt 0) {
        $problems += "Rules NOT indexed in AI-GUIDE.md:`n  $($missingFromGuide -join "`n  ")"
    }
    if ($missingFromDisk.Count -gt 0) {
        $problems += "AI-GUIDE.md references non-existent rules:`n  $($missingFromDisk -join "`n  ")"
    }
    if ($problems.Count -gt 0) { throw ($problems -join "`n`n") }
}

Step "E.5" "Docs present" {
    foreach ($f in @("docs/workflow.md", "docs/dev-map.md", "docs/tasks.md", "docs/getting-started.md", "docs/concepts.md")) {
        if (-not (Test-Path $f)) { throw "Missing $f" }
    }
}

Step "E.6" "evals/golden-tasks.md present" {
    if (-not (Test-Path "evals/golden-tasks.md")) { throw "Missing evals/golden-tasks.md" }
}

# F. Symmetry (PowerShell <-> Bash pairs)
Step "F.1" "verify_all, sync-self, harness-sync, test-init, test-real-project exist in both .ps1 and .sh" {
    foreach ($pair in @("verify_all", "sync-self", "harness-sync", "test-init", "test-real-project")) {
        if (-not (Test-Path "scripts/$pair.ps1")) { throw "Missing scripts/$pair.ps1" }
        if (-not (Test-Path "scripts/$pair.sh")) { throw "Missing scripts/$pair.sh" }
    }
}

# F.2 — Guard-rm scripts and PreToolUse wiring present (v0.15+)
Step "F.2" "Guard-rm scripts and PreToolUse wiring present" {
    foreach ($f in @("scripts/guard-rm.ps1", "scripts/guard-rm.sh",
                     "skills/harness-init/templates/common/scripts/guard-rm.ps1",
                     "skills/harness-init/templates/common/scripts/guard-rm.sh")) {
        if (-not (Test-Path $f)) { throw "Missing $f" }
    }
    # Dogfood .claude/settings.json must JSON-parse and have a PreToolUse hook calling guard-rm
    $settings = Get-Content ".claude/settings.json" -Raw | ConvertFrom-Json
    $pre = $settings.hooks.PreToolUse
    if (-not $pre -or $pre.Count -lt 1) { throw ".claude/settings.json missing hooks.PreToolUse[]" }
    $first = $pre[0]
    if ($first.matcher -ne "Bash") { throw ".claude/settings.json PreToolUse[0].matcher should be 'Bash', got '$($first.matcher)'" }
    if (-not $first.hooks -or $first.hooks.Count -lt 1) { throw ".claude/settings.json PreToolUse[0].hooks missing" }
    $cmd = $first.hooks[0].command
    if ($cmd -notmatch 'guard-rm\.(ps1|sh)') { throw ".claude/settings.json PreToolUse command does not reference guard-rm: $cmd" }
    # Template settings.json.tmpl must contain {{GUARD_COMMAND}} and PreToolUse
    $tmpl = Get-Content "skills/harness-init/templates/common/.claude/settings.json.tmpl" -Raw
    if ($tmpl -notmatch [regex]::Escape("{{GUARD_COMMAND}}")) { throw "template settings.json.tmpl missing {{GUARD_COMMAND}}" }
    if ($tmpl -notmatch "PreToolUse") { throw "template settings.json.tmpl missing PreToolUse block" }
}

# G. Documentation hygiene
Step "G.1" "README references all 11 skills" {
    $readme = Get-Content "README.md" -Raw
    foreach ($s in @("harness", "harness-init", "harness-adopt", "harness-verify", "harness-status", "harness-plan", "harness-explore", "harness-goal", "harness-intervene", "harness-supervise", "harness-batch")) {
        if ($readme -notmatch [regex]::Escape($s)) { throw "README missing skill mention: $s" }
    }
}

Step "E.7" "No stale .harness/intervention.md tracked (v0.13+)" {
    if (-not (Test-Path ".harness/intervention.md")) { return }
    $tracked = git ls-files -- '.harness/intervention.md' 2>$null
    if ($tracked) {
        Write-Host "" -NoNewline
        Write-Host " (intervention.md is tracked — should be gitignored)" -ForegroundColor Yellow -NoNewline
        return $false
    }
}

Step "H.1" "Test fixtures present (todo-fullstack + todo-backend)" {
    foreach ($f in @("tests/fixtures/todo-fullstack/package.json",
                     "tests/fixtures/todo-fullstack/src/server.ts",
                     "tests/fixtures/todo-backend/pyproject.toml",
                     "tests/fixtures/todo-backend/src/main.py")) {
        if (-not (Test-Path $f)) { throw "Missing fixture file: $f" }
    }
}

Step "G.2" "CHANGELOG mentions all 11 skills" {
    $cl = Get-Content "CHANGELOG.md" -Raw
    foreach ($s in @("harness", "harness-init", "harness-adopt", "harness-verify", "harness-status", "harness-plan", "harness-explore", "harness-goal", "harness-intervene", "harness-supervise", "harness-batch")) {
        if ($cl -notmatch [regex]::Escape($s)) { throw "CHANGELOG missing skill mention: $s" }
    }
}

Step "G.3" "Version stamps consistent across plugin.json / marketplace.json / README badges" {
    $manifest = Get-Content ".claude-plugin/plugin.json" -Raw | ConvertFrom-Json
    $market = Get-Content ".claude-plugin/marketplace.json" -Raw | ConvertFrom-Json
    $pluginV = $manifest.version
    $marketV = $market.plugins[0].version

    $readmeBadge = $null
    if ((Get-Content "README.md" -Raw) -match 'version-(\d+\.\d+\.\d+)-') { $readmeBadge = $Matches[1] }
    $zhBadge = $null
    if ((Get-Content "README.zh-CN.md" -Raw) -match 'version-(\d+\.\d+\.\d+)-') { $zhBadge = $Matches[1] }

    $stamps = [ordered]@{
        "plugin.json"            = $pluginV
        "marketplace.json"       = $marketV
        "README.md badge"        = $readmeBadge
        "README.zh-CN.md badge"  = $zhBadge
    }
    $unique = $stamps.Values | Where-Object { $_ } | Sort-Object -Unique
    if ($null -eq $unique -or $unique.Count -ne 1) {
        $detail = ($stamps.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join '; '
        throw "version mismatch: $detail (bump all four together when cutting a release)"
    }
}

# I. Document size caps (v0.14+, WARN-only; see .harness/rules/70-doc-size.md)
Step "I.1" "AI-GUIDE.md <=200 lines" {
    if (-not (Test-Path "AI-GUIDE.md")) { return }
    $n = (Get-Content "AI-GUIDE.md" | Measure-Object -Line).Lines
    if ($n -gt 200) {
        Write-Host "" -NoNewline
        Write-Host " ($n lines, cap 200 — see .harness/rules/70-doc-size.md)" -ForegroundColor Yellow -NoNewline
        return $false
    }
}

Step "I.2" "Rule fragments <=200 lines each" {
    if (-not (Test-Path ".harness/rules")) { return }
    $over = @()
    Get-ChildItem -Path ".harness/rules" -Filter "*.md" -File | ForEach-Object {
        $n = (Get-Content $_.FullName | Measure-Object -Line).Lines
        if ($n -gt 200) { $over += "$($_.Name):${n}L" }
    }
    if ($over.Count -gt 0) {
        Write-Host "" -NoNewline
        Write-Host " (over cap: $($over -join ', '))" -ForegroundColor Yellow -NoNewline
        return $false
    }
}

Step "I.3" "Agent definitions <=300 lines each" {
    if (-not (Test-Path ".harness/agents")) { return }
    $over = @()
    Get-ChildItem -Path ".harness/agents" -Filter "*.md" -File | ForEach-Object {
        $n = (Get-Content $_.FullName | Measure-Object -Line).Lines
        if ($n -gt 300) { $over += "$($_.Name):${n}L" }
    }
    if ($over.Count -gt 0) {
        Write-Host "" -NoNewline
        Write-Host " (over cap: $($over -join ', '))" -ForegroundColor Yellow -NoNewline
        return $false
    }
}

Step "I.4" "insight-index.md <=30 lines" {
    if (-not (Test-Path ".harness/insight-index.md")) { return }
    $n = (Get-Content ".harness/insight-index.md" | Measure-Object -Line).Lines
    if ($n -gt 30) {
        Write-Host "" -NoNewline
        Write-Host " ($n lines — archive-task auto-rotates; manual overflow)" -ForegroundColor Yellow -NoNewline
        return $false
    }
}

Step "I.5" "docs/tasks.md <=300 lines" {
    if (-not (Test-Path "docs/tasks.md")) { return }
    $n = (Get-Content "docs/tasks.md" | Measure-Object -Line).Lines
    if ($n -gt 300) {
        Write-Host "" -NoNewline
        Write-Host " ($n lines — rotate oldest Completed rows to docs/tasks-archive.md)" -ForegroundColor Yellow -NoNewline
        return $false
    }
}

Step "I.7" "Ignored INTERVENE supervision reports (WARN if >48h old on active task)" {
    # Passive guard for the supervisor agent (v0.17+). Globs every
    # docs/features/<slug>/SUPERVISION_REPORT.md (not _archived/, which is one
    # level deeper and out of scope), reads last 5 lines for the verdict, and
    # WARNs if Verdict: INTERVENE has been ignored on an active task >48h.
    if (-not (Test-Path "docs/features")) { return }
    $reports = Get-ChildItem -Path "docs/features" -Filter "SUPERVISION_REPORT.md" -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '_archived' -and $_.FullName -notmatch '_supervision' }
    if (-not $reports -or $reports.Count -eq 0) { return }
    # docs/tasks.md row format: a row containing <slug> whose status is not Completed/Archived = active.
    $tasksMd = ""
    if (Test-Path "docs/tasks.md") { $tasksMd = Get-Content "docs/tasks.md" -Raw }
    $stale = @()
    foreach ($r in $reports) {
        # Extract slug from path: docs/features/<slug>/SUPERVISION_REPORT.md
        $slug = Split-Path (Split-Path $r.FullName -Parent) -Leaf
        # Last 5 non-blank lines
        $tail = (Get-Content $r.FullName | Where-Object { $_.Trim() -ne "" }) | Select-Object -Last 5
        $verdict = $null
        foreach ($line in $tail) {
            # PS `-match` is case-insensitive by default — use `-cmatch` for case-sensitive
            # regex so a lowercase `verdict: intervene` does NOT trigger I.7 (Q-1 fixed-case
            # schema). Mirrors bash twin's case-sensitive `=~` at verify_all.sh:462.
            # See insight-index L20 (PowerShell case-sensitivity discipline).
            if ($line -cmatch '^Verdict: (HEALTHY|WATCH|INTERVENE)$') { $verdict = $Matches[1]; break }
        }
        if ($verdict -ne "INTERVENE") { continue }
        # Is the task active in tasks.md? Heuristic: row contains the slug and is not marked Completed/Archived.
        $isActive = $false
        if ($tasksMd) {
            # BUG-2 fix (v0.17.1): column-anchored match — the slug must appear as a
            # full pipe-delimited cell in docs/tasks.md, not as a bare substring.
            # Without the `\|...\|` anchor a slug `foo` is falsely matched by an
            # Active row for `foo-extra` (substring collision). Bash twin:
            # verify_all.sh I.7 active-row detection.
            $rows = $tasksMd -split "`r?`n" | Where-Object { $_ -match "\|\s*$([regex]::Escape($slug))\s*\|" }
            foreach ($row in $rows) {
                if ($row -notmatch 'Completed' -and $row -notmatch 'Archived') { $isActive = $true; break }
            }
        }
        if (-not $isActive) { continue }
        # mtime >48h?
        $age = (Get-Date) - $r.LastWriteTime
        if ($age.TotalHours -gt 48) {
            $stale += "$($r.FullName) (INTERVENE, $([math]::Round($age.TotalHours,1))h old, slug=$slug active)"
        }
    }
    if ($stale.Count -gt 0) {
        Write-Host "" -NoNewline
        Write-Host " (stale: $($stale -join '; '))" -ForegroundColor Yellow -NoNewline
        return $false
    }
}

Step "I.6" "No retired-claim phrases in current docs/templates (FAIL on resurgence)" {
    # Retired-claim guard (gap-tolerant since v0.18.0). Phrases that used to be accurate
    # but became wrong after a documented architectural change — resurgence is drift,
    # not history. As of v0.18.0 the matcher is a gap-tolerant ordered-anchor scan: each
    # banned entry is an ordered list of literal anchor tokens, and a file hits when all
    # anchors appear in order on ONE line within a bounded gap (default 40 chars,
    # per-entry overridable). Each entry may also carry literal `exclude` tokens — if any
    # appears anywhere on the matched LINE (line-scoped), the match is rejected, so
    # accurate negated prose ("rules are NOT composed into CLAUDE.md") does not FAIL.
    #
    # Anchors/exclusions are PLAIN TEXT — [regex]::Escape handles every metacharacter.
    # Any anchor containing a literal backtick (the `CLAUDE.md` code-span anchors) MUST
    # be authored in a SINGLE-quoted string: backtick is the PS escape char inside
    # double quotes. When a retired claim becomes accurate again, delete the entry
    # rather than carve a file-level exception. This is the 1:1 twin of verify_all.sh's
    # $i6_banned list — keep both in lockstep (test-verify-i6 asserts it).
    $gapDefault = 40
    $banned = @(
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
    # Build an ERE-equivalent .NET pattern from an anchor list — each anchor escaped to
    # match literally, joined by a bounded gap.
    function Build-I6Regex($anchors, $gap) {
        ($anchors | ForEach-Object { [regex]::Escape($_) }) -join "(.{0,$gap})"
    }
    # Files exempt because they record history honestly: CHANGELOG describes what each
    # release did, architecture.html / walkthrough.html are v0.5/v0.6-era visual
    # snapshots with explicit "v0.5 snapshot" banners, and verify_all itself stores the
    # banned-phrase strings. test-verify-i6.{ps1,sh} are the I.6 regression drivers —
    # they hold a verbatim copy of this banned list plus banned-phrase fixtures, so
    # they are exempt for the same reason verify_all is. The whole docs/features/
    # subtree is exempt because per-task stage docs must quote retired claims to design
    # the guard. (MIGRATION.md is NOT exempt — it is scanned; its old/new comparisons
    # phrase around the banned literals.)
    $exempt = @(
        "CHANGELOG.md",
        "architecture.html",
        "docs/walkthrough.html",
        "scripts/verify_all.ps1",
        "scripts/verify_all.sh",
        "scripts/test-verify-i6.ps1",
        "scripts/test-verify-i6.sh"
    )
    $exemptDirs = @("docs/features/", "参考/")
    $hits = @()
    $tracked = git ls-files 2>$null
    foreach ($file in $tracked) {
        if ($exempt -contains $file) { continue }
        $skipDir = $false
        foreach ($d in $exemptDirs) { if ($file.StartsWith($d)) { $skipDir = $true; break } }
        if ($skipDir) { continue }
        if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { continue }
        $content = Get-Content -LiteralPath $file -Raw -ErrorAction SilentlyContinue
        if (-not $content) { continue }
        $lines = $content -split "`r?`n"
        foreach ($b in $banned) {
            $gap = if ($null -ne $b.gap) { $b.gap } else { $gapDefault }
            # IgnoreCase is the explicit D-2 mechanism — never a PS operator default.
            # Singleline stays $false so `.` excludes newline (single-line scan).
            $rx = [regex]::new((Build-I6Regex $b.anchors $gap), [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            $lineNo = 0
            foreach ($line in $lines) {
                $lineNo++
                $m = $rx.Match($line)
                if (-not $m.Success) { continue }
                # Line-scoped exclude: reject if any exclude token appears anywhere on
                # the WHOLE matched line (not just the matched span).
                $excluded = $false
                foreach ($x in $b.exclude) {
                    if ($line.IndexOf($x, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                        $excluded = $true; break
                    }
                }
                if ($excluded) { continue }
                $span = $m.Value
                if ($span.Length -gt 120) { $span = $span.Substring(0, 120) }
                $hits += "${file}:$lineNo : [$($b.anchors -join '~')] — $($b.reason) | matched: `"$span`""
                break
            }
        }
    }
    if ($hits.Count -gt 0) {
        throw ("Retired-claim phrases found in live files:`n" + ($hits -join "`n"))
    }
}

# J. Claude Code settings.json schema integrity (v0.18.2+)
# See .harness/rules/80-settings-schema.md for the workflow contract.
# Catches the two recurring failure modes hand-edits keep producing:
#   1. Invalid key inside the `hooks` object (additionalProperties:false in schema).
#   2. `$schema` URL missing the `.json` suffix — redirects to a non-JSON MIME so
#      editors silently flag the whole file as invalid.
Step "J.1" "settings.json schema integrity (.claude/ + template)" {
    # Canonical list per https://www.schemastore.org/claude-code-settings.json
    # (fetched 2026-05-23). Update only when the upstream schema adds events.
    $validHookEvents = @(
        'PreToolUse', 'PostToolUse', 'PostToolUseFailure', 'PermissionRequest',
        'PermissionDenied', 'Notification', 'UserPromptSubmit', 'UserPromptExpansion',
        'Stop', 'StopFailure', 'SubagentStart', 'SubagentStop', 'PreCompact',
        'PostCompact', 'PostToolBatch', 'Elicitation', 'ElicitationResult',
        'TeammateIdle', 'TaskCompleted', 'TaskCreated', 'Setup',
        'InstructionsLoaded', 'CwdChanged', 'FileChanged', 'ConfigChange',
        'WorktreeCreate', 'WorktreeRemove', 'SessionStart', 'SessionEnd'
    )
    $canonicalSchema = 'https://json.schemastore.org/claude-code-settings.json'
    $targets = @(
        @{ path = '.claude/settings.json'; isTemplate = $false },
        @{ path = 'skills/harness-init/templates/common/.claude/settings.json.tmpl'; isTemplate = $true }
    )
    $failures = @()
    foreach ($t in $targets) {
        if (-not (Test-Path -LiteralPath $t.path)) { continue }
        $raw = Get-Content -LiteralPath $t.path -Raw -ErrorAction SilentlyContinue
        if (-not $raw) { $failures += "$($t.path): empty or unreadable"; continue }
        try {
            $obj = $raw | ConvertFrom-Json -ErrorAction Stop
        } catch {
            $failures += "$($t.path): not valid JSON ($($_.Exception.Message))"
            continue
        }
        if ($obj.PSObject.Properties.Name -contains '$schema') {
            $s = $obj.'$schema'
            if ($s -ne $canonicalSchema) {
                $failures += "$($t.path): `$schema='$s' (expected '$canonicalSchema' — non-.json URL serves wrong MIME, breaks editor validation)"
            }
        }
        if ($obj.PSObject.Properties.Name -contains 'hooks' -and $obj.hooks) {
            foreach ($k in $obj.hooks.PSObject.Properties.Name) {
                # Underscore-prefixed keys are NOT valid inside hooks — schema is
                # additionalProperties:false. Doc keys belong at root.
                if ($k -notin $validHookEvents) {
                    $failures += "$($t.path): hooks.$k is not a valid Claude Code hook event (schema rejects; move doc keys to root)"
                }
            }
        }
    }
    if ($failures.Count -gt 0) {
        throw ("settings.json schema violations:`n  " + ($failures -join "`n  "))
    }
}

# Summary
Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
$pass = ($report | Where-Object status -eq "PASS").Count
Write-Host "  PASS: $pass" -ForegroundColor Green
Write-Host "  WARN: $warns" -ForegroundColor Yellow
Write-Host "  FAIL: $errors" -ForegroundColor Red

# Append history
$historyEntry = [pscustomobject]@{
    timestamp = (Get-Date).ToString("o")
    pass = $pass; warn = $warns; fail = $errors
    report = $report
}
$historyEntry | ConvertTo-Json -Depth 5 -Compress | Add-Content -Path "scripts/verification_history.log"

if ($errors -gt 0) { exit 2 }
if ($warns -gt 0) { exit 1 }
exit 0

} finally {
    Pop-Location
}
