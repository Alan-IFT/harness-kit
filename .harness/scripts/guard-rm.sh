#!/usr/bin/env bash
# guard-rm.sh — Destructive-command PreToolUse guard for Claude Code (Unix)
#
# Invoked by .claude/settings.json hooks.PreToolUse before every Bash tool call.
# Reads the tool input as JSON on stdin; exits 0 to allow the command, non-zero
# (exit 2) to BLOCK with a stderr message Claude Code shows in the transcript.
#
# Blocks when ANY destructive verb (rm / rmdir / unlink / Remove-Item / del /
# erase / Clear-RecycleBin / shred / srm / find -delete) targets a path that
# resolves OUTSIDE the nearest .git/ ancestor of cwd.
#
# The rule is evaluated at EVERY command position in the command line — not just
# the first token of each top-level pipe segment. Positions reached through `;`,
# `&&`, `||`, `&`, a newline, a subshell/brace group, a command or process
# substitution, an argv-carrier (`xargs`, `env`, `timeout`, `find -exec`, …) or
# a nested interpreter (`bash -c`, `pwsh -c`, …) are all judged.
#
# Override: prepend `HARNESS_ALLOW_OUTSIDE_RM=1 ` to the command, or set it in
# the hook process environment, for a single call.
#
# See `.harness/rules/75-safety-hook.md` for full contract and disable path.

# NOTE: do NOT use `declare -a` under `set -u` — empty-array reads crash.
# Use bare `name=()` instead (insight 2026-05-16 declare-a-under-set-u).
# NOTE: do NOT use ${var//needle/repl} anywhere in new code — bash 5.2's
# `patsub_replacement` expands an unescaped `&` in the replacement to the
# matched text, and command strings are full of `&` (insight 2026-06-21).
# The two pre-existing ${cmd//…} lines below are exempt: their replacements
# are `"` and `\`, which contain no `&`.
# NOTE: keep this file bash-3.2-safe (macOS /bin/bash): no mapfile, no ${v,,},
# no associative arrays. A bash-4-only construct is a WHOLE-FILE parse error,
# which exits 2 and blocks every Bash tool call.
set -uo pipefail

# str_replace_all <haystack> <needle> <replacement> — literal replace-all that is
# IMMUNE to bash 5.2's `&`-means-matched-text rule in ${var//pat/repl}.
# Copied verbatim from .harness/scripts/upgrade-project.sh.
str_replace_all() {
    local rest="$1" needle="$2" repl="$3" out=""
    while [[ "$rest" == *"$needle"* ]]; do
        out="$out${rest%%"$needle"*}$repl"
        rest="${rest#*"$needle"}"
    done
    printf '%s' "$out$rest"
}

# 1. Read tool input JSON from stdin.
payload=$(cat - 2>/dev/null || true)
if [[ -z "$payload" ]]; then exit 0; fi

# Extract .tool_input.command. Use python only if it actually works (Windows can
# have a Microsoft-Store stub that fakes `command -v` success but exits non-zero
# on real invocation; we test with a tiny script before trusting it).
cmd=""
have_python=0
if command -v python3 >/dev/null 2>&1; then
    if echo '' | python3 -c 'pass' >/dev/null 2>&1; then have_python=1; fi
fi
if (( have_python == 1 )); then
    cmd=$(python3 -c '
import sys, json
try:
    data = json.loads(sys.stdin.read())
    print(data.get("tool_input", {}).get("command", ""), end="")
except Exception:
    pass
' <<<"$payload" 2>/dev/null || true)
fi
if [[ -z "$cmd" ]]; then
    # Heuristic fallback for the one-level Claude Code shape: greedy-match
    # everything between `"command":"` and the closing `"}` (handles nested
    # \" by being lazy about the right anchor — the closing `"}` is what
    # actually terminates the field in Claude Code's emitted JSON).
    cmd=$(printf '%s' "$payload" \
        | tr -d '\n' \
        | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\(.*\)"[[:space:]]*}.*/\1/p' \
        | head -1)
    # Unescape the whitespace escapes FIRST, with the patsub-safe literal
    # helper: JSON encodes a command newline as the two characters `\` `n`, and
    # without this step the position scanner would never see a real newline
    # separator on a host without python3.
    _lf=$(printf '\nx'); _lf="${_lf%x}"
    _cr=$(printf '\rx'); _cr="${_cr%x}"
    _tab=$(printf '\tx'); _tab="${_tab%x}"
    cmd=$(str_replace_all "$cmd" '\n' "$_lf")
    cmd=$(str_replace_all "$cmd" '\r' "$_cr")
    cmd=$(str_replace_all "$cmd" '\t' "$_tab")
    # Unescape JSON \" -> " and \\ -> \. Order matters: do \" first so a literal
    # \\ stays \\ and then becomes \.
    cmd="${cmd//\\\"/\"}"
    cmd="${cmd//\\\\/\\}"
fi
[[ -z "$cmd" ]] && exit 0

# 2. Override env var: bail out cheaply.
if [[ "${HARNESS_ALLOW_OUTSIDE_RM:-}" == "1" ]]; then
    echo "harness-kit guard-rm: override active (HARNESS_ALLOW_OUTSIDE_RM=1) — allowing destructive command." >&2
    exit 0
fi

# 2b. Command-text override prefix. Evaluated EXACTLY ONCE, on the top-level
# command, before the .git/ walk and before any parsing — never per position.
# Re-applying it per position would make
# `echo x && HARNESS_ALLOW_OUTSIDE_RM=1 rm -rf /etc/x` self-authorizing.
# Only a leading prefix on the whole line counts; case-sensitive; the value must
# be exactly `1` and be followed by a space or a tab.
_ovr_trim="${cmd#"${cmd%%[![:space:]]*}"}"
if [[ "$_ovr_trim" == "HARNESS_ALLOW_OUTSIDE_RM=1 "* || "$_ovr_trim" == "HARNESS_ALLOW_OUTSIDE_RM=1"$'\t'* ]]; then
    echo "harness-kit guard-rm: override active (HARNESS_ALLOW_OUTSIDE_RM=1) — allowing destructive command." >&2
    exit 0
fi

# 3. Walk up to nearest .git/ ancestor of cwd.
dir="$PWD"
repo_root=""
while [[ -n "$dir" ]]; do
    if [[ -d "$dir/.git" ]]; then repo_root="$dir"; break; fi
    parent=$(dirname "$dir")
    if [[ "$parent" == "$dir" ]]; then break; fi
    dir="$parent"
done
if [[ -z "$repo_root" ]]; then
    echo "harness-kit guard-rm: WARN no .git/ ancestor — guard inactive." >&2
    exit 0
fi

# 4. Truncate command (boundary B11).
cmd="${cmd:0:8192}"

# Verb sets (case-sensitive for bash verbs; Remove-Item etc. case-insensitive).
# LEDGER: destructive_verbs_ci is the human-readable declaration of the verb set
# and the diff target for "the verb set is unchanged". _is_destructive_verb()
# below is its mechanical, fork-free twin — both lists have exactly 9 members
# and MUST be edited together.
destructive_verbs_ci="rm rmdir unlink Remove-Item del erase Clear-RecycleBin shred srm"
# Deliberately UNUSED — kept as historical documentation of the D-1/D-2 fix
# (v0.15.1): the find-predicate skip these names once drove is disabled for
# every verb, see the NOTE in _walk_paths. Do not re-wire without a driver row.
find_predicates="-name -type -regex -iname -perm -mtime -size -path -ipath -newer"

# Argv-carrier verbs (IS-1 row 9). These are NOT destructive verbs: they never
# cause a block by themselves, they only expose further command positions.
# Exact, case-sensitive POSIX command names.
_is_carrier_verb() {
    case "$1" in
        xargs|env|nohup|nice|time|timeout|command|exec|find) return 0 ;;
    esac
    return 1
}

# Destructive-verb membership test — fork-free bracket-class globs,
# case-insensitive. Mechanical twin of destructive_verbs_ci (9 members).
_is_destructive_verb() {
    case "$1" in
        [Rr][Mm]) return 0 ;;
        [Rr][Mm][Dd][Ii][Rr]) return 0 ;;
        [Uu][Nn][Ll][Ii][Nn][Kk]) return 0 ;;
        [Rr][Ee][Mm][Oo][Vv][Ee]-[Ii][Tt][Ee][Mm]) return 0 ;;
        [Dd][Ee][Ll]) return 0 ;;
        [Ee][Rr][Aa][Ss][Ee]) return 0 ;;
        [Cc][Ll][Ee][Aa][Rr]-[Rr][Ee][Cc][Yy][Cc][Ll][Ee][Bb][Ii][Nn]) return 0 ;;
        [Ss][Hh][Rr][Ee][Dd]) return 0 ;;
        [Ss][Rr][Mm]) return 0 ;;
    esac
    return 1
}

_is_pwsh_verb() {
    case "$1" in
        [Pp][Ww][Ss][Hh]) return 0 ;;
        [Pp][Oo][Ww][Ee][Rr][Ss][Hh][Ee][Ll][Ll]) return 0 ;;
    esac
    return 1
}

_is_shell_verb() {
    case "$1" in
        [Bb][Aa][Ss][Hh]) return 0 ;;
        [Ss][Hh]) return 0 ;;
        [Dd][Aa][Ss][Hh]) return 0 ;;
        [Zz][Ss][Hh]) return 0 ;;
        [Kk][Ss][Hh]) return 0 ;;
    esac
    return 1
}

# 5. Whitespace-aware quote tokenizer.
# Writes tokens into the global array _TOKENS.
# Returns 0 on success, 1 on parse failure (unbalanced quotes).
_TOKENS=()
tokenize() {
    local s="$1"
    _TOKENS=()
    local cur=""
    local in_single=0 in_double=0 has_content=0
    local i=0 ch=""
    local len=${#s}
    while (( i < len )); do
        ch="${s:$i:1}"
        if (( in_single == 0 && in_double == 0 )) && [[ "$ch" == " " || "$ch" == $'\t' ]]; then
            if (( has_content == 1 )); then
                _TOKENS+=("$cur"); cur=""; has_content=0
            fi
            ((i++)); continue
        fi
        if (( in_double == 0 )) && [[ "$ch" == "'" ]]; then
            in_single=$(( 1 - in_single )); has_content=1; ((i++)); continue
        fi
        if (( in_single == 0 )) && [[ "$ch" == '"' ]]; then
            in_double=$(( 1 - in_double )); has_content=1; ((i++)); continue
        fi
        cur="${cur}${ch}"; has_content=1
        ((i++))
    done
    if (( in_single == 1 || in_double == 1 )); then return 1; fi
    if (( has_content == 1 )); then _TOKENS+=("$cur"); fi
    return 0
}

# 6. Split top-level pipes into segments (not inside quotes).
# Writes into the global array _SEGS.
_SEGS=()
split_pipes() {
    local s="$1"
    _SEGS=()
    local cur=""
    local in_single=0 in_double=0
    local i=0 ch=""
    local len=${#s}
    while (( i < len )); do
        ch="${s:$i:1}"
        if (( in_double == 0 )) && [[ "$ch" == "'" ]]; then in_single=$(( 1 - in_single )); fi
        if (( in_single == 0 )) && [[ "$ch" == '"' ]]; then in_double=$(( 1 - in_double )); fi
        if [[ "$ch" == "|" ]] && (( in_single == 0 && in_double == 0 )); then
            local trimmed="${cur#"${cur%%[![:space:]]*}"}"
            trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"
            _SEGS+=("$trimmed")
            cur=""
            ((i++)); continue
        fi
        cur="${cur}${ch}"
        ((i++))
    done
    local trimmed="${cur#"${cur%%[![:space:]]*}"}"
    trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"
    _SEGS+=("$trimmed")
}

# 6b. Position scanner — a single-pass character lexer with an explicit nesting
# stack that emits the substrings at which a shell would begin parsing a simple
# command. It never resolves paths, never looks at verbs and never forks.
#
# States: N (normal) · SQ (single-quoted) · DQ (double-quoted) · C (comment)
#         H (here-document body)
# Frames: CMDSUB `$(` · BQ backtick · PROCSUB `<(`/`>(` · GROUP_PAREN `(` ·
#         GROUP_BRACE `{` · PARAM `${` · ARITH `$((` · VPAREN/VBRACE (balance
#         frames inside PARAM/ARITH).
# CMDSUB/BQ/PROCSUB/GROUP_PAREN/GROUP_BRACE count toward the depth bound (2);
# PARAM/ARITH/VPAREN/VBRACE do not — they exist only so their closer is matched
# instead of being read as a separator.
_POSITIONS=()
_SP_BUF=""
_SP_KINDS=()
_SP_SBUFS=()
_SP_SQST=()
_SP_TOP=""
_SP_DEPTH=0
_SP_POP_BUF=""
_SP_POP_ST=""

_sp_flush() {
    local t="${_SP_BUF#"${_SP_BUF%%[![:space:]]*}"}"
    t="${t%"${t##*[![:space:]]}"}"
    if [[ -n "$t" ]]; then _POSITIONS+=("$t"); fi
    _SP_BUF=""
}

_sp_settop() {
    local n=${#_SP_KINDS[@]}
    if (( n > 0 )); then _SP_TOP="${_SP_KINDS[$(( n - 1 ))]}"; else _SP_TOP=""; fi
}

# Push a verbatim (non-command-bearing) frame: PARAM / ARITH / VPAREN / VBRACE.
_sp_push_v() {
    _SP_KINDS+=("$1"); _SP_SBUFS+=(""); _SP_SQST+=("")
    _SP_TOP="$1"
}

_sp_pop_v() {
    local n=${#_SP_KINDS[@]}
    if (( n > 0 )); then
        unset "_SP_KINDS[$(( n - 1 ))]" "_SP_SBUFS[$(( n - 1 ))]" "_SP_SQST[$(( n - 1 ))]"
    fi
    _sp_settop
}

# Push a command-bearing frame, saving the outer buffer AND the outer quote
# state. Returns 1 when the depth bound (2) would be exceeded → parse failure.
_sp_push_cmd() {
    _SP_DEPTH=$(( _SP_DEPTH + 1 ))
    if (( _SP_DEPTH > 2 )); then return 1; fi
    _SP_KINDS+=("$1"); _SP_SBUFS+=("$2"); _SP_SQST+=("$3")
    _SP_TOP="$1"
    return 0
}

# Pop a command-bearing frame; the saved buffer / quote state land in
# _SP_POP_BUF / _SP_POP_ST for the caller to restore.
_sp_pop_cmd() {
    local n=${#_SP_KINDS[@]}
    _SP_POP_BUF=""; _SP_POP_ST=""
    if (( n > 0 )); then
        _SP_POP_BUF="${_SP_SBUFS[$(( n - 1 ))]}"
        _SP_POP_ST="${_SP_SQST[$(( n - 1 ))]}"
    fi
    _SP_DEPTH=$(( _SP_DEPTH - 1 ))
    _sp_pop_v
}

# split_positions <string> — fills _POSITIONS; returns 0 on success, 1 on
# unresolvable structure (the caller then blocks, fail-closed).
split_positions() {
    local s="$1"
    _POSITIONS=()
    _SP_BUF=""
    _SP_KINDS=(); _SP_SBUFS=(); _SP_SQST=(); _SP_TOP=""; _SP_DEPTH=0
    local st="N"
    # sq_ansi is meaningful ONLY while st == SQ; it is re-set on every SQ entry
    # (SQ is enterable only from the NORMAL `'` cell) and never read otherwise.
    local sq_ansi=0
    local len=${#s}
    local i=0
    local ch="" two="" three="" prev="" btrim="" qch="" c2="" w="" strip=0
    # Index at which row 12 last appended a redirection operator (`>` / `<`) at
    # NORMAL. Row 15 uses it instead of the raw byte at i-1 — see row 12.
    # The "none recorded yet" sentinel MUST stay -2, NOT -1: row 15 compares it
    # against `i - 1`, whose domain over this loop is {-1, 0, … len-2}, so -1
    # COLLIDES at i == 0 and appends a leading `&` instead of flushing it —
    # fail-OPEN, and `&` is PowerShell's call operator, which the guard reaches
    # by recursing into `pwsh -c` strings. Pinned by driver rows R4 / R5.
    local redir_i=-2
    local hdq=() hdstrip=() hdhead=0 hdline="" cmpline=""

    while (( i < len )); do
        ch="${s:$i:1}"

        # ---- verbatim frames: copy bytes until the matching closer ----
        case "$_SP_TOP" in
            PARAM|ARITH|VPAREN|VBRACE)
                if [[ "$ch" == "\\" ]]; then
                    _SP_BUF="${_SP_BUF}${s:$i:2}"; i=$(( i + 2 )); continue
                fi
                if [[ "$ch" == '$' ]]; then
                    three="${s:$i:3}"
                    if [[ "$three" == '$((' ]]; then
                        _SP_BUF="${_SP_BUF}${three}"; i=$(( i + 3 )); _sp_push_v ARITH; continue
                    fi
                    two="${s:$i:2}"
                    if [[ "$two" == '${' ]]; then
                        _SP_BUF="${_SP_BUF}${two}"; i=$(( i + 2 )); _sp_push_v PARAM; continue
                    fi
                fi
                if [[ "$ch" == ")" && "$_SP_TOP" == "ARITH" && "${s:$i:2}" == "))" ]]; then
                    _SP_BUF="${_SP_BUF}))"; i=$(( i + 2 )); _sp_pop_v; continue
                fi
                if [[ "$ch" == "(" ]]; then
                    _SP_BUF="${_SP_BUF}("; i=$(( i + 1 )); _sp_push_v VPAREN; continue
                fi
                if [[ "$ch" == "{" ]]; then
                    _SP_BUF="${_SP_BUF}{"; i=$(( i + 1 )); _sp_push_v VBRACE; continue
                fi
                if [[ "$ch" == ")" && "$_SP_TOP" == "VPAREN" ]]; then
                    _SP_BUF="${_SP_BUF})"; i=$(( i + 1 )); _sp_pop_v; continue
                fi
                if [[ "$ch" == "}" ]] && [[ "$_SP_TOP" == "PARAM" || "$_SP_TOP" == "VBRACE" ]]; then
                    _SP_BUF="${_SP_BUF}}"; i=$(( i + 1 )); _sp_pop_v; continue
                fi
                _SP_BUF="${_SP_BUF}${ch}"; i=$(( i + 1 )); continue
                ;;
        esac

        # ---- comment: discard bytes to end of line ----
        if [[ "$st" == "C" ]]; then
            if [[ "$ch" == $'\n' || "$ch" == $'\r' ]]; then
                _sp_flush
                if (( hdhead < ${#hdq[@]} )); then st="H"; hdline=""; else st="N"; fi
            fi
            i=$(( i + 1 )); continue
        fi

        # ---- here-document body: data, never a command position ----
        if [[ "$st" == "H" ]]; then
            if [[ "$ch" == $'\n' || "$ch" == $'\r' ]]; then
                cmpline="$hdline"
                if [[ "${hdstrip[$hdhead]}" == "1" ]]; then
                    while [[ "$cmpline" == $'\t'* ]]; do cmpline="${cmpline:1}"; done
                fi
                if [[ "$cmpline" == "${hdq[$hdhead]}" ]]; then
                    hdhead=$(( hdhead + 1 ))
                    if (( hdhead >= ${#hdq[@]} )); then st="N"; fi
                fi
                hdline=""
            else
                hdline="${hdline}${ch}"
            fi
            i=$(( i + 1 )); continue
        fi

        # ---- hoisted row 24 ----
        # Every byte that NO dispatch row keys on behaves identically in N, SQ
        # and DQ: append. Hoisting it costs one `case` for the common byte and
        # saves ~20 sequential tests. The pattern list below is EXACTLY the set
        # of characters rows 1-23 react to; nothing in the scanner's state
        # depends on an ordinary byte beyond appending it (`prev` and `sq_ansi`
        # are read from $s directly, not accumulated).
        case "$ch" in
            '\'|"'"|'"'|'`'|'$'|'<'|'>'|'&'|'|'|';'|'('|')'|'{'|'}'|'#'|$'\n'|$'\r') ;;
            *) _SP_BUF="${_SP_BUF}${ch}"; i=$(( i + 1 )); continue ;;
        esac

        # ---- row 1: backslash ----
        if [[ "$ch" == "\\" ]]; then
            if [[ "$st" == "SQ" ]] && (( sq_ansi == 0 )); then
                _SP_BUF="${_SP_BUF}\\"; i=$(( i + 1 ))
            else
                _SP_BUF="${_SP_BUF}${s:$i:2}"; i=$(( i + 2 ))
            fi
            continue
        fi

        # ---- row 2: single quote ----
        if [[ "$ch" == "'" ]]; then
            if [[ "$st" == "N" ]]; then
                prev=""
                (( i > 0 )) && prev="${s:$(( i - 1 )):1}"
                _SP_BUF="${_SP_BUF}'"
                st="SQ"
                if [[ "$prev" == '$' ]]; then sq_ansi=1; else sq_ansi=0; fi
            elif [[ "$st" == "SQ" ]]; then
                _SP_BUF="${_SP_BUF}'"; st="N"
            else
                _SP_BUF="${_SP_BUF}'"
            fi
            i=$(( i + 1 )); continue
        fi

        # ---- row 3: double quote ----
        if [[ "$ch" == '"' ]]; then
            if [[ "$st" == "N" ]]; then
                _SP_BUF="${_SP_BUF}\""; st="DQ"
            elif [[ "$st" == "DQ" ]]; then
                _SP_BUF="${_SP_BUF}\""; st="N"
            else
                _SP_BUF="${_SP_BUF}\""
            fi
            i=$(( i + 1 )); continue
        fi

        # ---- SQ: every remaining row is "append" ----
        if [[ "$st" == "SQ" ]]; then
            _SP_BUF="${_SP_BUF}${ch}"; i=$(( i + 1 )); continue
        fi

        # ---- row 4: backtick (self-toggling frame; pushes at N and at DQ) ----
        if [[ "$ch" == '`' ]]; then
            if [[ "$_SP_TOP" == "BQ" ]]; then
                _sp_flush
                _sp_pop_cmd
                _SP_BUF="$_SP_POP_BUF"; st="$_SP_POP_ST"
            else
                if ! _sp_push_cmd BQ "$_SP_BUF" "$st"; then return 1; fi
                _SP_BUF=""; st="N"
            fi
            i=$(( i + 1 )); continue
        fi

        # Multi-character lookahead is only needed for these lead bytes.
        two=""; three=""
        case "$ch" in
            '$'|'<'|'>'|'&') two="${s:$i:2}"; three="${s:$i:3}" ;;
        esac

        # ---- row 5: $((  (append + verbatim ARITH frame, N and DQ alike) ----
        if [[ "$three" == '$((' ]]; then
            _SP_BUF="${_SP_BUF}${three}"; i=$(( i + 3 )); _sp_push_v ARITH; continue
        fi
        # ---- row 6: $(  ----
        if [[ "$two" == '$(' ]]; then
            if ! _sp_push_cmd CMDSUB "$_SP_BUF" "$st"; then return 1; fi
            _SP_BUF=""; st="N"; i=$(( i + 2 )); continue
        fi
        # ---- row 7: ${  ----
        if [[ "$two" == '${' ]]; then
            _SP_BUF="${_SP_BUF}${two}"; i=$(( i + 2 )); _sp_push_v PARAM; continue
        fi
        # ---- row 9: <<<  ----
        if [[ "$three" == "<<<" ]]; then
            _SP_BUF="${_SP_BUF}<<<"; i=$(( i + 3 )); continue
        fi
        # ---- row 10: <<  (here-document; NORMAL only) ----
        if [[ "$two" == "<<" && "$st" == "N" ]]; then
            _SP_BUF="${_SP_BUF}<<"; i=$(( i + 2 ))
            strip=0
            if [[ "${s:$i:1}" == "-" ]]; then
                strip=1; _SP_BUF="${_SP_BUF}-"; i=$(( i + 1 ))
            fi
            while (( i < len )); do
                c2="${s:$i:1}"
                if [[ "$c2" == " " || "$c2" == $'\t' ]]; then
                    _SP_BUF="${_SP_BUF}${c2}"; i=$(( i + 1 ))
                else
                    break
                fi
            done
            w=""
            c2="${s:$i:1}"
            if [[ "$c2" == "'" || "$c2" == '"' ]]; then
                qch="$c2"
                _SP_BUF="${_SP_BUF}${qch}"; i=$(( i + 1 ))
                while (( i < len )) && [[ "${s:$i:1}" != "$qch" ]]; do
                    w="${w}${s:$i:1}"; _SP_BUF="${_SP_BUF}${s:$i:1}"; i=$(( i + 1 ))
                done
                if (( i >= len )); then return 1; fi
                _SP_BUF="${_SP_BUF}${qch}"; i=$(( i + 1 ))
            else
                while (( i < len )); do
                    c2="${s:$i:1}"
                    if [[ "$c2" == " " || "$c2" == $'\t' || "$c2" == $'\n' || "$c2" == $'\r' ]]; then break; fi
                    if [[ "$c2" == ";" || "$c2" == "&" || "$c2" == "|" ]]; then break; fi
                    if [[ "$c2" == "(" || "$c2" == ")" || "$c2" == "<" || "$c2" == ">" ]]; then break; fi
                    if [[ "$c2" == "\\" ]]; then
                        _SP_BUF="${_SP_BUF}\\"; i=$(( i + 1 ))
                        if (( i >= len )); then break; fi
                        c2="${s:$i:1}"
                    fi
                    w="${w}${c2}"; _SP_BUF="${_SP_BUF}${c2}"; i=$(( i + 1 ))
                done
            fi
            if [[ -n "$w" ]]; then hdq+=("$w"); hdstrip+=("$strip"); fi
            continue
        fi
        # ---- row 11: <( / >(  (process substitution; NORMAL only) ----
        if [[ "$st" == "N" ]] && [[ "$two" == "<(" || "$two" == ">(" ]]; then
            if ! _sp_push_cmd PROCSUB "$_SP_BUF" "$st"; then return 1; fi
            _SP_BUF=""; st="N"; i=$(( i + 2 )); continue
        fi

        # ---- rows 12-23: NORMAL-only redirections, separators and frames ----
        if [[ "$st" == "N" ]]; then
            # ---- row 12: plain redirection operator ----
            # Recording WHERE it was appended is what lets row 15 tell an
            # OPERATOR `>` from a literal one. Reading the raw byte at i-1
            # instead (design §3.1 row 15) is a false negative: in
            # `echo a\>& rm -rf /etc/x` bash treats the escaped `>` as text, so
            # the `&` IS a separator, but the raw byte says "redirect" and the
            # position is never flushed. Because the "none yet" sentinel (-2) is
            # OUTSIDE the domain of `i - 1`, a stale or never-set index can only
            # ever compare unequal, i.e. cause a flush, i.e. MORE positions —
            # fail-closed. That property is what makes a single scanner-wide
            # index sound without per-frame save/restore, and it holds only
            # while the sentinel stays unreachable (see its declaration).
            if [[ "$ch" == ">" || "$ch" == "<" ]]; then
                _SP_BUF="${_SP_BUF}${ch}"; redir_i=$i; i=$(( i + 1 )); continue
            fi
            if [[ "$two" == "&&" ]]; then _sp_flush; i=$(( i + 2 )); continue; fi
            if [[ "$two" == "&>" ]]; then _SP_BUF="${_SP_BUF}&>"; i=$(( i + 2 )); continue; fi
            if [[ "$ch" == "&" ]]; then
                if (( redir_i == i - 1 )); then
                    _SP_BUF="${_SP_BUF}&"
                else
                    _sp_flush
                fi
                i=$(( i + 1 )); continue
            fi
            if [[ "$ch" == "|" ]]; then _sp_flush; i=$(( i + 1 )); continue; fi
            if [[ "$ch" == ";" ]]; then _sp_flush; i=$(( i + 1 )); continue; fi
            if [[ "$ch" == "(" ]]; then
                _sp_flush
                if ! _sp_push_cmd GROUP_PAREN "" ""; then return 1; fi
                i=$(( i + 1 )); continue
            fi
            if [[ "$ch" == ")" ]]; then
                case "$_SP_TOP" in
                    CMDSUB|PROCSUB)
                        _sp_flush; _sp_pop_cmd
                        _SP_BUF="$_SP_POP_BUF"; st="$_SP_POP_ST" ;;
                    GROUP_PAREN)
                        _sp_flush; _sp_pop_cmd ;;
                    *)
                        # `case` arm terminator and friends: flush, no pop.
                        _sp_flush ;;
                esac
                i=$(( i + 1 )); continue
            fi
            if [[ "$ch" == "{" ]]; then
                btrim="${_SP_BUF#"${_SP_BUF%%[![:space:]]*}"}"
                btrim="${btrim%"${btrim##*[![:space:]]}"}"
                if [[ -z "$btrim" ]]; then
                    _sp_flush
                    if ! _sp_push_cmd GROUP_BRACE "" ""; then return 1; fi
                else
                    _SP_BUF="${_SP_BUF}{"
                fi
                i=$(( i + 1 )); continue
            fi
            if [[ "$ch" == "}" ]]; then
                if [[ "$_SP_TOP" == "GROUP_BRACE" ]]; then
                    _sp_flush; _sp_pop_cmd
                else
                    _SP_BUF="${_SP_BUF}}"
                fi
                i=$(( i + 1 )); continue
            fi
            if [[ "$ch" == $'\n' || "$ch" == $'\r' ]]; then
                _sp_flush
                if (( hdhead < ${#hdq[@]} )); then st="H"; hdline=""; fi
                i=$(( i + 1 )); continue
            fi
            if [[ "$ch" == "#" ]]; then
                if [[ -z "$_SP_BUF" || "$_SP_BUF" == *" " || "$_SP_BUF" == *$'\t' ]]; then
                    st="C"
                else
                    _SP_BUF="${_SP_BUF}#"
                fi
                i=$(( i + 1 )); continue
            fi
        fi

        # ---- row 24: any other byte ----
        _SP_BUF="${_SP_BUF}${ch}"; i=$(( i + 1 ))
    done

    # ---- end of input (total) ----
    if [[ "$st" == "SQ" || "$st" == "DQ" ]]; then return 1; fi
    if [[ "$st" == "H" ]]; then
        # A terminator on the final line with no trailing newline still ends the
        # body (bash accepts it); anything else is genuinely unterminated.
        cmpline="$hdline"
        if [[ "${hdstrip[$hdhead]}" == "1" ]]; then
            while [[ "$cmpline" == $'\t'* ]]; do cmpline="${cmpline:1}"; done
        fi
        if [[ "$cmpline" == "${hdq[$hdhead]}" ]]; then hdhead=$(( hdhead + 1 )); fi
    fi
    if (( hdhead < ${#hdq[@]} )); then return 1; fi
    if (( ${#_SP_KINDS[@]} > 0 )); then return 1; fi
    _sp_flush
    return 0
}

# 6c. Fast-path trigger test. The scanner can only emit a boundary split_pipes
# does not when one of these bytes is present. Written as twelve separate tests
# (never one bracket expression) because `bash -n` validates syntax, not pattern
# semantics, and a mis-parsed class member would be a SILENT false negative.
_has_scanner_trigger() {
    local s="$1"
    [[ "$s" == *";"* ]] && return 0
    [[ "$s" == *"&"* ]] && return 0
    [[ "$s" == *"("* ]] && return 0
    [[ "$s" == *")"* ]] && return 0
    [[ "$s" == *"{"* ]] && return 0
    [[ "$s" == *"}"* ]] && return 0
    [[ "$s" == *'`'* ]] && return 0
    [[ "$s" == *"<"* ]] && return 0
    [[ "$s" == *">"* ]] && return 0
    [[ "$s" == *"\\"* ]] && return 0
    [[ "$s" == *$'\n'* ]] && return 0
    [[ "$s" == *$'\r'* ]] && return 0
    return 1
}

# 7. Path normalize (leaf-only; no realpath / symlink chase).
resolve_leaf() {
    local p="$1" cwd="$2"
    # Strip surrounding quotes if any.
    if [[ "$p" == \"*\" ]]; then p="${p:1:${#p}-2}"; fi
    if [[ "$p" == \'*\' ]]; then p="${p:1:${#p}-2}"; fi
    # Expand ~.
    if [[ "$p" == "~" ]]; then p="${HOME:-/}"
    elif [[ "$p" == "~/"* ]]; then p="${HOME:-/}/${p#~/}"; fi
    local abs="$p"
    # Determine absolute: unix /…, Windows-style /…, or drive-letter X:…
    case "$abs" in
        /*|\\*) ;;
        [A-Za-z]:*) ;;
        *) abs="$cwd/$abs" ;;
    esac
    # Collapse .. and . segments.
    local IFS='/'
    # shellcheck disable=SC2206
    local parts=($abs)
    local stack=()
    local first=1
    local part
    for part in "${parts[@]+"${parts[@]}"}"; do
        if (( first == 1 )); then
            stack+=("$part"); first=0; continue
        fi
        if [[ -z "$part" || "$part" == "." ]]; then continue; fi
        if [[ "$part" == ".." ]]; then
            if (( ${#stack[@]} > 1 )); then unset 'stack[${#stack[@]}-1]'; fi
            continue
        fi
        stack+=("$part")
    done
    local result
    result=$(IFS='/'; printf '%s' "${stack[*]+"${stack[*]}"}")
    [[ -z "$result" ]] && result="/"
    printf '%s' "$result"
}

is_descendant() {
    local child="$1" parent="$2"
    # Strip trailing slashes.
    child="${child%/}"; child="${child%\\}"
    parent="${parent%/}"; parent="${parent%\\}"
    [[ "$child" == "$parent" ]] && return 0
    [[ "$child" == "$parent/"* ]] && return 0
    return 1
}

# 8. Classify a segment. Writes offending paths to $segment_offending (global) and
#    sets parse_failed=1 on tokenizer / nested-interpreter parse failure.
parse_failed=0
segment_offending=()

# _skip_prefix <token>… — advances past assignment prefixes, `sudo` (with its
# -E / -H / -u USER logic, byte-for-byte the pre-change block) and shell
# reserved words. Result lands in the global _PREFIX_IDX. Tokens are passed by
# value, so there is no dynamic-scope coupling to the caller.
_PREFIX_IDX=0
_skip_prefix() {
    local toks=("$@")
    local n=${#toks[@]}
    local idx=0
    local t="" name=""
    while (( idx < n )); do
        t="${toks[$idx]}"
        # 1. Assignment prefix: NAME=value or NAME+=value.
        if [[ "$t" == *=* ]]; then
            name="${t%%=*}"
            name="${name%+}"
            if [[ -n "$name" && "$name" != *[!A-Za-z0-9_]* && "$name" != [0-9]* ]]; then
                idx=$(( idx + 1 )); continue
            fi
        fi
        # 2. sudo [-E|-H|-u USER]
        if [[ "$t" == "sudo" ]]; then
            idx=$(( idx + 1 ))
            while (( idx < n )); do
                t="${toks[$idx]}"
                if [[ "$t" == "-E" || "$t" == "-H" ]]; then idx=$(( idx + 1 )); continue; fi
                if [[ "$t" == "-u" ]] && (( idx + 1 < n )); then idx=$(( idx + 2 )); continue; fi
                break
            done
            continue
        fi
        # 3. Shell reserved words and stray group braces. Safe by construction:
        # the destructive-verb test still gates every path walk.
        case "$t" in
            if|then|elif|else|fi|while|until|do|done|for|select|case|esac|in|function|coproc|'!'|'{'|'}')
                idx=$(( idx + 1 )); continue ;;
        esac
        break
    done
    _PREFIX_IDX=$idx
}

# _walk_paths <start-index> <token>… — the pre-change path walk, behaviourally
# unchanged: skip flags, honour `--`, resolve every remaining token as a path.
_walk_paths() {
    local start="$1"; shift
    local toks=("$@")
    local n=${#toks[@]}
    local after_dd=0
    local j="$start" t="" abs=""
    while (( j < n )); do
        t="${toks[$j]}"
        if (( after_dd == 0 )); then
            if [[ "$t" == "--" ]]; then after_dd=1; ((j++)); continue; fi
            if [[ "$t" == -* && "${#t}" -gt 1 ]]; then
                # NOTE: find-predicate skip intentionally disabled here.
                # No destructive verb other than `find` takes -name/-path/etc.,
                # so any such flag is either user error or adversarial — treat
                # subsequent tokens as paths.
                ((j++)); continue
            fi
        fi
        abs=$(resolve_leaf "$t" "$PWD")
        if ! is_descendant "$abs" "$repo_root"; then
            segment_offending+=("$abs")
        fi
        ((j++))
    done
}

classify_segment() {
    local segment="$1" depth="$2"
    if (( depth > 2 )); then parse_failed=1; return; fi
    if ! tokenize "$segment"; then parse_failed=1; return; fi
    # Snapshot tokens to a local array immediately — recursive calls re-fill _TOKENS.
    local tokens=("${_TOKENS[@]+"${_TOKENS[@]}"}")
    local ntok=${#tokens[@]}
    if (( ntok == 0 )); then return; fi

    _skip_prefix "${tokens[@]}"
    local idx=$_PREFIX_IDX
    (( idx >= ntok )) && return
    local verb="${tokens[$idx]}"
    local after_verb=$((idx + 1))
    local j=0 k=0 t=""

    # Nested pwsh / powershell.
    if _is_pwsh_verb "$verb"; then
        j=$after_verb
        while (( j < ntok )); do
            t="${tokens[$j]}"
            case "$t" in
                -[Cc]|-[Cc][Oo][Mm][Mm][Aa][Nn][Dd]|-[Cc][Oo][Mm][Mm][Aa][Nn][Dd][Ww][Ii][Tt][Hh][Aa][Rr][Gg][Ss]|/c)
                    if (( j + 1 >= ntok )); then parse_failed=1; return; fi
                    classify_command_string "${tokens[$((j+1))]}" $((depth + 1))
                    return ;;
            esac
            ((j++))
        done
        return
    fi

    # Nested POSIX-shell interpreters. Deliberately broader than "find -c":
    # every non-option token is judged as a command string, so
    # `bash --rcfile foo -c "rm -rf /etc/x"` is covered and `bash script.sh`
    # degrades to judging the literal string `script.sh` (not destructive).
    if _is_shell_verb "$verb"; then
        j=$after_verb
        while (( j < ntok )); do
            t="${tokens[$j]}"
            if [[ "$t" != -* ]]; then
                classify_command_string "$t" $((depth + 1))
            fi
            ((j++))
        done
        return
    fi

    # Argv carriers (IS-1 row 9). The scan runs to the end and NEVER returns —
    # `find` is a carrier AND has its own -delete branch below, and both must
    # run, in this order. No per-carrier option table: an incomplete table
    # produces false negatives, which is the forbidden direction.
    if _is_carrier_verb "$verb"; then
        j=$after_verb
        while (( j < ntok )); do
            t="${tokens[$j]}"
            if _is_destructive_verb "$t"; then
                _walk_paths $((j + 1)) "${tokens[@]}"
            elif _is_pwsh_verb "$t" || _is_shell_verb "$t"; then
                k=$((j + 1))
                while (( k < ntok )); do
                    if [[ "${tokens[$k]}" != -* ]]; then
                        classify_command_string "${tokens[$k]}" $((depth + 1))
                        break
                    fi
                    ((k++))
                done
            fi
            ((j++))
        done
    fi

    # find with -delete.
    if [[ "$verb" == "find" ]]; then
        local has_delete=0
        for t in "${tokens[@]+"${tokens[@]}"}"; do
            if [[ "$t" == "-delete" ]]; then has_delete=1; break; fi
        done
        (( has_delete == 0 )) && return
        j=$after_verb
        while (( j < ntok )); do
            t="${tokens[$j]}"
            if [[ "$t" == -* ]]; then break; fi
            local abs; abs=$(resolve_leaf "$t" "$PWD")
            if ! is_descendant "$abs" "$repo_root"; then
                segment_offending+=("$abs")
            fi
            ((j++))
        done
        return
    fi

    # Other destructive verbs (case-insensitive match).
    _is_destructive_verb "$verb" || return

    # Walk remaining tokens; skip flags. Find-predicate-style next-arg skip
    # applies ONLY when verb is 'find' (handled in its own branch above).
    # Applying it generically allowed `rm -path /etc`, `rm -name /etc/passwd`
    # to bypass. See 06_TEST_REPORT.md D-1 / D-2.
    _walk_paths "$after_verb" "${tokens[@]}"
}

# 8b. The union step and the single entry point for "judge this command string".
# INVARIANT: P contains the input string `s` ITSELF at EVERY depth, including
# depth 0. Do NOT make this depth-conditional — decomposition strictly narrows
# each verb's token walk, so dropping `s` would flip pre-change BLOCKs to ALLOW
# (a silent, fail-OPEN regression).
classify_command_string() {
    local s="$1" depth="$2"
    if (( depth > 2 )); then parse_failed=1; return; fi

    local plist=()
    plist+=("$s")
    local seg="" q="" dup=0

    split_pipes "$s"
    local segs=("${_SEGS[@]+"${_SEGS[@]}"}")
    for seg in "${segs[@]+"${segs[@]}"}"; do
        dup=0
        for q in "${plist[@]+"${plist[@]}"}"; do
            if [[ "$q" == "$seg" ]]; then dup=1; break; fi
        done
        (( dup == 0 )) && plist+=("$seg")
    done

    if _has_scanner_trigger "$s"; then
        if ! split_positions "$s"; then parse_failed=1; return; fi
        local poss=("${_POSITIONS[@]+"${_POSITIONS[@]}"}")
        for seg in "${poss[@]+"${poss[@]}"}"; do
            dup=0
            for q in "${plist[@]+"${plist[@]}"}"; do
                if [[ "$q" == "$seg" ]]; then dup=1; break; fi
            done
            (( dup == 0 )) && plist+=("$seg")
        done
    fi

    for seg in "${plist[@]+"${plist[@]}"}"; do
        (( parse_failed == 1 )) && return
        [[ -z "$seg" ]] && continue
        classify_segment "$seg" "$depth"
    done
}

# 9. Judge every command position in the command line.
all_offending=()
segment_offending=()
classify_command_string "$cmd" 0
for off in "${segment_offending[@]+"${segment_offending[@]}"}"; do
    all_offending+=("$off")
done

if (( parse_failed == 1 )); then
    echo "harness-kit guard-rm: BLOCKED — could not parse the command safely (unbalanced quotes, nesting past depth 2, or an unterminated here-document); override with HARNESS_ALLOW_OUTSIDE_RM=1 if intended." >&2
    exit 2
fi

(( ${#all_offending[@]} == 0 )) && exit 0

# 10. Emit BLOCK message.
trunc_cmd="${cmd:0:300}"
{
    printf 'harness-kit guard-rm: BLOCKED — destructive command targets path outside project root.\n'
    printf '  Command: %s\n' "$trunc_cmd"
    printf '  Offending path(s):\n'
    for p in "${all_offending[@]}"; do
        printf '    - %s (outside %s)\n' "$p" "$repo_root"
    done
    printf '  Override (only if you really mean this): re-issue the command with the env var\n'
    printf '    HARNESS_ALLOW_OUTSIDE_RM=1 set for that single call.\n'
    printf '  See .harness/rules/75-safety-hook.md to fully disable.\n'
} >&2
exit 2
