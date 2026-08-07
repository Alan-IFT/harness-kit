#!/usr/bin/env bash
# hook-spec.sh - the hook wiring spec (T-13).
#
# THE single source of truth for `(hook tool, target OS) -> command byte-form`
# plus each tool's failure semantics, lifecycle event name and matcher.
# Mirror of hook-spec.ps1: same queries, same emitted bytes.
#
# Pure and side-effect-free: no file I/O, no parsing, no substitution. The four
# command shapes originated in T-12's per-flow derivation helpers; since T-16 those
# helpers are retired and this file is their ONLY home — changing a byte here changes
# every consumer, and there is nowhere else to change it.
#
# A consumer invokes the twin of ITS OWN shell. Crossing shells is prohibited:
# an MSYS bash capturing pwsh output via $(...) strips the trailing \n but leaves
# the \r, corrupting the command string. Stdout line-ending bytes are therefore
# NOT part of the contract; the captured value (both shells strip the trailing
# newline) is.
#
# CONTRACT
#   hook-spec.sh tools                -> the 4 tool ids, fixed order, one per line
#   hook-spec.sh event <tool>         -> Stop | PreToolUse | UserPromptSubmit | SessionStart
#   hook-spec.sh matcher <tool>       -> Bash (guard-rm) | none (the other three)
#   hook-spec.sh semantics <tool>     -> fail-open | fail-closed
#   hook-spec.sh command <tool> <os>  -> the JSON-string-body command (inner " already \")
#   hook-spec.sh hostos               -> windows | unix  (the host this shell runs on)
#   anything else / bad arity         -> NOTHING on stdout, diagnostic on stderr, exit 2
#
# <tool> is one of the four script basenames; <os> is exactly `windows` or `unix`
# (case-sensitive, no alias). `none` is a reserved non-empty sentinel for "this
# event takes no matcher" - every exit-0 path prints a non-empty US-ASCII line, so
# an empty string is never a successful answer. Invariants a consumer may rely on:
# purity (fixed arguments -> fixed bytes; only `hostos` reads the environment) and
# totality (exit 0 <=> non-empty stdout; exit 2 <=> empty stdout + non-empty stderr).
#
# guard-rm is fail-CLOSED BY DESIGN: its command carries no `|| exit 0` and no
# trailing `exit 0`, so a missing or unreachable guard yields a non-zero exit and
# the Bash tool call is BLOCKED. Never add a fallback to that branch.
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
#   bash .harness/scripts/hook-spec.sh command guard-rm unix

set -uo pipefail

hs_die() {
    printf '%s\n' "hook-spec: $1" >&2
    exit 2
}

# Every recognized tool id. The ids ARE the script basenames - `command` below
# interpolates the id into ` .harness/scripts/<tool>.<ext>`, so the existing
# space-preceded bare-path congruence extraction keeps working unchanged.
hs_is_tool() {
    case "$1" in
        harness-sync|guard-rm|ambient-prompt|ambient-reset) return 0 ;;
        *) return 1 ;;
    esac
}

hs_event() {
    case "$1" in
        harness-sync)   printf '%s\n' "Stop" ;;
        guard-rm)       printf '%s\n' "PreToolUse" ;;
        ambient-prompt) printf '%s\n' "UserPromptSubmit" ;;
        ambient-reset)  printf '%s\n' "SessionStart" ;;
    esac
}

hs_matcher() {
    case "$1" in
        guard-rm) printf '%s\n' "Bash" ;;
        *)        printf '%s\n' "none" ;;
    esac
}

hs_semantics() {
    case "$1" in
        guard-rm) printf '%s\n' "fail-closed" ;;
        *)        printf '%s\n' "fail-open" ;;
    esac
}

# The four literal shapes. This is their ONLY home since T-16 retired the per-flow
# copies - do not retype them, and do not post-process the result anywhere.
hs_command() {
    local hs_tool="$1" hs_os="$2"
    if [[ "$hs_os" == "windows" ]]; then
        if [[ "$hs_tool" == "guard-rm" ]]; then
            printf '%s\n' "pwsh -NoProfile -Command \\\"Set-Location -LiteralPath \$env:CLAUDE_PROJECT_DIR; & pwsh -NoProfile -File .harness/scripts/$hs_tool.ps1\\\""
        else
            printf '%s\n' "pwsh -NoProfile -Command \\\"Set-Location -LiteralPath \$env:CLAUDE_PROJECT_DIR -EA SilentlyContinue; if (Test-Path -LiteralPath .harness/scripts/$hs_tool.ps1 -PathType Leaf) { & pwsh -NoProfile -File .harness/scripts/$hs_tool.ps1 }; exit 0\\\""
        fi
    else
        if [[ "$hs_tool" == "guard-rm" ]]; then
            printf '%s\n' "sh -c 'cd \\\"\$CLAUDE_PROJECT_DIR\\\" 2>/dev/null && bash .harness/scripts/$hs_tool.sh'"
        else
            printf '%s\n' "sh -c 'cd \\\"\$CLAUDE_PROJECT_DIR\\\" 2>/dev/null && [ -f .harness/scripts/$hs_tool.sh ] && exec bash .harness/scripts/$hs_tool.sh || exit 0'"
        fi
    fi
}

hs_query="${1:-}"
case "$hs_query" in
    tools)
        (( $# == 1 )) || hs_die "unrecognized arity for query 'tools': expected 0 arguments, got $(( $# - 1 ))"
        printf '%s\n' harness-sync guard-rm ambient-prompt ambient-reset
        ;;
    event|matcher|semantics)
        (( $# == 2 )) || hs_die "unrecognized arity for query '$hs_query': expected 1 argument, got $(( $# - 1 ))"
        hs_is_tool "$2" || hs_die "unrecognized tool: $2"
        case "$hs_query" in
            event)     hs_event "$2" ;;
            matcher)   hs_matcher "$2" ;;
            semantics) hs_semantics "$2" ;;
        esac
        ;;
    command)
        (( $# == 3 )) || hs_die "unrecognized arity for query 'command': expected 2 arguments, got $(( $# - 1 ))"
        hs_is_tool "$2" || hs_die "unrecognized tool: $2"
        case "$3" in
            windows|unix) ;;
            *) hs_die "unrecognized os: $3 (expected 'windows' or 'unix')" ;;
        esac
        hs_command "$2" "$3"
        ;;
    hostos)
        (( $# == 1 )) || hs_die "unrecognized arity for query 'hostos': expected 0 arguments, got $(( $# - 1 ))"
        # The discrimination the derivation flows now OBTAIN from here (it was
        # duplicated in upgrade-project.sh until T-16) - no third variant is introduced.
        case "${OSTYPE:-}" in
            msys*|cygwin*|win32) printf '%s\n' "windows" ;;
            *)                   printf '%s\n' "unix" ;;
        esac
        ;;
    "")
        hs_die "unrecognized query: <none> (expected tools|event|matcher|semantics|command|hostos)"
        ;;
    *)
        hs_die "unrecognized query: $hs_query (expected tools|event|matcher|semantics|command|hostos)"
        ;;
esac

exit 0
