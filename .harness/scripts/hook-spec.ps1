# hook-spec.ps1 - the hook wiring spec (T-13).
#
# THE single source of truth for `(hook tool, target OS) -> command byte-form`
# plus each tool's failure semantics, lifecycle event name and matcher.
# Mirror of hook-spec.sh: same queries, same emitted bytes.
#
# Pure and side-effect-free: no file I/O, no parsing, no substitution. The four
# command shapes originated in T-12's per-flow derivation helpers; since T-16 those
# helpers are retired and this file is their ONLY home — changing a byte here changes
# every consumer, and there is nowhere else to change it.
#
# A consumer invokes the twin of ITS OWN shell. Crossing shells is prohibited:
# an MSYS bash capturing pwsh output via $(...) strips the trailing newline but
# leaves the CR, corrupting the command string. Stdout line-ending bytes are
# therefore NOT part of the contract; the captured value is.
#
# CONTRACT
#   hook-spec.ps1 tools                -> the 4 tool ids, fixed order, one per line
#   hook-spec.ps1 event <tool>         -> Stop | PreToolUse | UserPromptSubmit | SessionStart
#   hook-spec.ps1 matcher <tool>       -> Bash (guard-rm) | none (the other three)
#   hook-spec.ps1 semantics <tool>     -> fail-open | fail-closed
#   hook-spec.ps1 command <tool> <os>  -> the JSON-string-body command (inner " already \")
#   hook-spec.ps1 hostos               -> windows | unix  (the host this shell runs on)
#   anything else / bad arity          -> NOTHING on stdout, diagnostic on stderr, exit 2
#
# <tool> is one of the four script basenames; <os> is exactly `windows` or `unix`
# (case-sensitive, no alias - hence -ceq throughout). `none` is a reserved non-empty
# sentinel for "this event takes no matcher" - every exit-0 path prints a non-empty
# US-ASCII line, so an empty string is never a successful answer. Invariants a
# consumer may rely on: purity (fixed arguments -> fixed bytes; only `hostos` reads
# the environment) and totality (exit 0 <=> non-empty stdout; exit 2 <=> empty
# stdout + non-empty stderr).
#
# guard-rm is fail-CLOSED BY DESIGN: its command carries no exit-0 fallback, so a
# missing or unreachable guard yields a non-zero exit and the Bash tool call is
# BLOCKED. Never add a fallback to that branch.
# See .harness/rules/75-safety-hook.md.
#
# WHO ELSE HOLDS THESE BYTES (settled by T-16; this list supersedes T-16's hand-off)
#
# RETIRED by T-16 - these four derivation flows now QUERY this spec at run time and
# hold no byte-form copy at all. No line citations: the copies no longer exist.
#   .harness/scripts/upgrade-project.{sh,ps1}         (hook-spec adapter)
#   .harness/scripts/migrate-scripts-layout.{sh,ps1}  (hook-spec adapter)
#   skills/harness-init/SKILL.md, skills/harness-adopt/SKILL.md
#       (the placeholder tables now instruct the agent to invoke this spec and paste
#        the captured line verbatim; they carry semantics, not bytes)
#
# DELIBERATELY RETAINED - each is a DECISION recorded in .harness/rejected-decisions.md
# (hook-byteform-test-literal-retirement), not an oversight:
#   .harness/scripts/test-init.{sh,ps1} EXP_* / $exp* fixtures (sh:53-60 literals,
#       sh:62-74 hs_expected) - a test must not derive its expectation from the
#       artifact under test; these are now the ONLY independent anchor for all four
#       flows, and the T-13 oracle compares this spec AGAINST them.
#   .harness/scripts/test-real-project.{sh,ps1} (sh:46-59) - same reason, plus it is a
#       fixture-AUTHORING site: it builds the fixture's final settings, so it must
#       state the expected bytes rather than ask the artifact it is testing.
#       (Omitted from T-13's hand-off list; named here.)
#   .harness/scripts/test-harness-upgrade.{sh,ps1} t20_pick (sh:296,306 / .ps1:296,299)
#       - the live flow-vs-frozen-literal end-to-end anchor (sh:421 asserts what the
#       upgrade flow actually WROTE contains this literal). Same escaping level.
#   .harness/scripts/test-harness-upgrade.sh:555 / .ps1:599,603,608 and
#   .harness/scripts/test-init.ps1:701-702 - DIFFERENT escaping levels (raw shell /
#       raw-pwsh / post-ConvertFrom-Json) that this spec deliberately does not emit.
#
# NOT A WIRING COPY - guard INPUT data, not an emitted command:
#   .harness/scripts/test-guard-rm.{sh,ps1}, evals/guard-rm-cases.md
#
# FOLLOW-UP, NOT A GAP - a `raw` command query is deferred (recorded in
# .harness/rejected-decisions.md as hook-spec-raw-query); retiring the raw-level
# consumers needs that query designed first.
#
# Usage:
#   pwsh -NoProfile -File .harness/scripts/hook-spec.ps1 command guard-rm unix
#
# NOTE - deliberately NO param() block: the CLI takes positional tokens only and
# validates its own arity, so a surplus token yields the designed exit 2 instead of
# a PowerShell parameter-binding error. No identifier here collides with a read-only
# automatic variable ($IsWindows / $Host / $Args are read, never assigned).

$ErrorActionPreference = "Stop"

function Write-HookSpecError($message) {
    [Console]::Error.WriteLine("hook-spec: " + $message)
}

# Every recognized tool id. The ids ARE the script basenames - Get-HookSpecCommand
# interpolates the id into ` .harness/scripts/<tool>.<ext>`, so the existing
# space-preceded bare-path congruence extraction keeps working unchanged.
function Test-HookSpecTool($tool) {
    foreach ($known in @('harness-sync', 'guard-rm', 'ambient-prompt', 'ambient-reset')) {
        if ($tool -ceq $known) { return $true }
    }
    return $false
}

function Get-HookSpecEvent($tool) {
    if ($tool -ceq 'harness-sync')   { return 'Stop' }
    if ($tool -ceq 'guard-rm')       { return 'PreToolUse' }
    if ($tool -ceq 'ambient-prompt') { return 'UserPromptSubmit' }
    return 'SessionStart'
}

function Get-HookSpecMatcher($tool) {
    if ($tool -ceq 'guard-rm') { return 'Bash' }
    return 'none'
}

function Get-HookSpecSemantics($tool) {
    if ($tool -ceq 'guard-rm') { return 'fail-closed' }
    return 'fail-open'
}

# The four literal shapes. This is their ONLY home since T-16 retired the per-flow
# copies - do not retype them, and do not post-process the result anywhere. Single-quoted
# literals with -f (never double-quote concatenation): the bodies carry `\"` and
# un-interpolated `$env:` / `$CLAUDE_PROJECT_DIR`, which double quotes would eat.
# `{{` / `}}` are the -f escapes for a literal brace.
function Get-HookSpecCommand($tool, $targetOs) {
    if ($targetOs -ceq 'windows') {
        if ($tool -ceq 'guard-rm') {
            return ('pwsh -NoProfile -Command \"Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR; & pwsh -NoProfile -File .harness/scripts/{0}.ps1\"' -f $tool)
        } else {
            return ('pwsh -NoProfile -Command \"Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR -EA SilentlyContinue; if (Test-Path -LiteralPath .harness/scripts/{0}.ps1 -PathType Leaf) {{ & pwsh -NoProfile -File .harness/scripts/{0}.ps1 }}; exit 0\"' -f $tool)
        }
    } else {
        if ($tool -ceq 'guard-rm') {
            return ('sh -c ''cd \"$CLAUDE_PROJECT_DIR\" 2>/dev/null && bash .harness/scripts/{0}.sh''' -f $tool)
        } else {
            return ('sh -c ''cd \"$CLAUDE_PROJECT_DIR\" 2>/dev/null && [ -f .harness/scripts/{0}.sh ] && exec bash .harness/scripts/{0}.sh || exit 0''' -f $tool)
        }
    }
}

$hsArgc = $args.Count
$hsQuery = ''
if ($hsArgc -ge 1) { $hsQuery = [string]$args[0] }

if ($hsQuery -ceq 'tools') {
    if ($hsArgc -ne 1) {
        Write-HookSpecError ("unrecognized arity for query 'tools': expected 0 arguments, got " + ($hsArgc - 1))
        exit 2
    }
    Write-Output 'harness-sync'
    Write-Output 'guard-rm'
    Write-Output 'ambient-prompt'
    Write-Output 'ambient-reset'
    exit 0
}

if (($hsQuery -ceq 'event') -or ($hsQuery -ceq 'matcher') -or ($hsQuery -ceq 'semantics')) {
    if ($hsArgc -ne 2) {
        Write-HookSpecError ("unrecognized arity for query '" + $hsQuery + "': expected 1 argument, got " + ($hsArgc - 1))
        exit 2
    }
    $hsTool = [string]$args[1]
    if (-not (Test-HookSpecTool $hsTool)) {
        Write-HookSpecError ("unrecognized tool: " + $hsTool)
        exit 2
    }
    if ($hsQuery -ceq 'event') {
        Write-Output (Get-HookSpecEvent $hsTool)
    } elseif ($hsQuery -ceq 'matcher') {
        Write-Output (Get-HookSpecMatcher $hsTool)
    } else {
        Write-Output (Get-HookSpecSemantics $hsTool)
    }
    exit 0
}

if ($hsQuery -ceq 'command') {
    if ($hsArgc -ne 3) {
        Write-HookSpecError ("unrecognized arity for query 'command': expected 2 arguments, got " + ($hsArgc - 1))
        exit 2
    }
    $hsTool = [string]$args[1]
    $hsOs = [string]$args[2]
    if (-not (Test-HookSpecTool $hsTool)) {
        Write-HookSpecError ("unrecognized tool: " + $hsTool)
        exit 2
    }
    if (-not (($hsOs -ceq 'windows') -or ($hsOs -ceq 'unix'))) {
        Write-HookSpecError ("unrecognized os: " + $hsOs + " (expected 'windows' or 'unix')")
        exit 2
    }
    Write-Output (Get-HookSpecCommand $hsTool $hsOs)
    exit 0
}

if ($hsQuery -ceq 'hostos') {
    if ($hsArgc -ne 1) {
        Write-HookSpecError ("unrecognized arity for query 'hostos': expected 0 arguments, got " + ($hsArgc - 1))
        exit 2
    }
    # The discrimination the derivation flows now OBTAIN from here (it was duplicated
    # in upgrade-project.ps1 until T-16) - no third variant is introduced. $IsWindows
    # is undefined on Windows PowerShell 5.1, where $env:OS carries the answer.
    if ($IsWindows -or $env:OS -eq "Windows_NT") { Write-Output 'windows' } else { Write-Output 'unix' }
    exit 0
}

if ($hsQuery -ceq '') {
    Write-HookSpecError "unrecognized query: <none> (expected tools|event|matcher|semantics|command|hostos)"
} else {
    Write-HookSpecError ("unrecognized query: " + $hsQuery + " (expected tools|event|matcher|semantics|command|hostos)")
}
exit 2
