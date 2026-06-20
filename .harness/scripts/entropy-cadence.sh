#!/usr/bin/env bash
# entropy-cadence.sh — Shared remind-if-due cadence unit for the entropy watch (Unix half).
#
# ONE definition of the entropy-sweep due-logic and threshold literal, called by BOTH
# /harness-stream (T-11a) and (later) /harness (T-11b) so neither restates the threshold.
# Reads/writes the tiny key=value state file `.harness/entropy-watch.state`.
#
# CLI:
#   entropy-cadence.sh check [--first-of-session]   -> stdout: DUE | NOT-DUE   (no write)
#   entropy-cadence.sh delivered                    -> stdout: count=<n>       (increment + write)
#   entropy-cadence.sh swept                         -> stdout: reset           (reset + stamp + write)
#
# Due logic (the ONLY place the threshold lives):
#   N = 5
#   due = (count >= N) OR (first_of_session AND count >= 1)
#
# FAIL-OPEN CONTRACT: any state-file problem (absent / malformed / unreadable / unwritable)
# resolves `check` to NOT-DUE and NEVER exits non-zero — a drain or delivery must never be
# blocked by cadence I/O. Mirrors the ambient-hook fail-open (always exit 0).
#
# Byte-symmetric with entropy-cadence.ps1 (NFR-3): UTF-8 / LF, the N=5 literal once per half.
# See skills/harness-stream/SKILL.md "On stream completion" and the design §2.

set -uo pipefail

# The one threshold literal (deliveries-since-sweep that makes the watch due).
N=5

# Walk up to nearest .git/ ancestor of cwd (same robust pattern as ambient-reset /
# guard-rm; NOT a fixed depth from $0 — insight 2026-06-04). Fail-open on no root.
dir="$PWD"
repo_root=""
while [[ -n "$dir" ]]; do
    if [[ -d "$dir/.git" ]]; then repo_root="$dir"; break; fi
    parent=$(dirname "$dir")
    if [[ "$parent" == "$dir" ]]; then break; fi
    dir="$parent"
done

# Resolve the state file path. With no repo root we still fail open below.
state_file=""
[[ -n "$repo_root" ]] && state_file="$repo_root/.harness/entropy-watch.state"

# Read delivered_since_sweep from the state file; fail-open to 0 on any problem.
read_count() {
    local n="" line
    [[ -n "$state_file" && -f "$state_file" ]] || { printf '0'; return 0; }
    while IFS= read -r line || [[ -n "$line" ]]; do
        case "$line" in
            delivered_since_sweep=*) n="${line#delivered_since_sweep=}" ;;
        esac
    done < "$state_file" 2>/dev/null || { printf '0'; return 0; }
    # Validate: a non-negative integer, else fail-open to 0.
    case "$n" in
        ''|*[!0-9]*) printf '0' ;;
        *) printf '%s' "$n" ;;
    esac
    return 0
}

# Write the state file (two key=value lines, UTF-8 / LF, no BOM). Fail-open: never
# exit non-zero on a write failure — emit a stderr note and carry on (exit 0).
write_state() {
    local count="$1" last_sweep="$2"
    [[ -n "$state_file" ]] || { echo "entropy-cadence: no repo root; state not written" >&2; return 0; }
    local d; d="$(dirname "$state_file")"
    mkdir -p "$d" 2>/dev/null || { echo "entropy-cadence: cannot create $d; state not written" >&2; return 0; }
    {
        printf 'delivered_since_sweep=%s\n' "$count"
        printf 'last_sweep=%s\n' "$last_sweep"
    } > "$state_file" 2>/dev/null || { echo "entropy-cadence: cannot write $state_file; ignored" >&2; return 0; }
    return 0
}

# Read last_sweep (may be empty/absent before the first sweep — never an error).
read_last_sweep() {
    local v="" line
    [[ -n "$state_file" && -f "$state_file" ]] || { printf ''; return 0; }
    while IFS= read -r line || [[ -n "$line" ]]; do
        case "$line" in
            last_sweep=*) v="${line#last_sweep=}" ;;
        esac
    done < "$state_file" 2>/dev/null || { printf ''; return 0; }
    printf '%s' "$v"
    return 0
}

cmd="${1:-}"
case "$cmd" in
    check)
        first_of_session=0
        [[ "${2:-}" == "--first-of-session" ]] && first_of_session=1
        count="$(read_count)"
        # due = (count >= N) OR (first_of_session AND count >= 1)
        if (( count >= N )) || { (( first_of_session == 1 )) && (( count >= 1 )); }; then
            echo "DUE"
        else
            echo "NOT-DUE"
        fi
        exit 0
        ;;
    delivered)
        count="$(read_count)"
        count=$(( count + 1 ))
        write_state "$count" "$(read_last_sweep)"
        echo "count=$count"
        exit 0
        ;;
    swept)
        now="$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || printf '')"
        write_state "0" "$now"
        echo "reset"
        exit 0
        ;;
    *)
        # Unknown / missing sub-command: fail-open (never block a caller), exit 0.
        echo "entropy-cadence: usage: check [--first-of-session] | delivered | swept" >&2
        exit 0
        ;;
esac
