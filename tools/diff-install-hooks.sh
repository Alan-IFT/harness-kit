#!/usr/bin/env bash
# diff-install-hooks.sh — differential gate for the install-hooks TypeScript port.
#
# install-hooks WRITES, so comparing stdout is not enough. Each scenario is run twice in
# two freshly-built, byte-identical sandboxes — once per implementation — and all four
# observables are compared: exit code, stdout, stderr, and the bytes of every file the
# installer may create or refuse to touch.
#
# Sandboxes are built from scratch rather than copied from the repo, so the comparison
# can never be contaminated by a leftover from a previous scenario.
#
# Usage: bash tools/diff-install-hooks.sh

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

SH_REL=".harness/scripts/install-hooks.sh"
JS_REL=".harness/scripts/install-hooks.js"

if [ ! -f "$ROOT/$JS_REL" ]; then
    echo "diff-install-hooks: $JS_REL missing — run 'npm run build' first" >&2
    exit 2
fi

WORK="$(mktemp -d -t install-hooks-diff-XXXXXX)"
trap 'rm -rf "$WORK"' EXIT

pass=0
fail=0

# build_sandbox <dir> <scenario> — create a self-contained fake project.
build_sandbox() {
    local dir="$1" scenario="$2"
    mkdir -p "$dir/.harness/scripts"
    # The installer only ever READS these two from the scripts dir.
    cp "$ROOT/.harness/scripts/hook-spec.sh" "$dir/.harness/scripts/"
    cp "$ROOT/.harness/scripts/install-hooks.sh" "$dir/.harness/scripts/"
    cp "$ROOT/.harness/scripts/hook-spec.js" "$dir/.harness/scripts/"
    cp "$ROOT/.harness/scripts/install-hooks.js" "$dir/.harness/scripts/"

    case "$scenario" in
        fresh-repo)
            mkdir -p "$dir/.git"
            ;;
        no-git)
            : # deliberately no .git
            ;;
        committed-hooks-present)
            mkdir -p "$dir/.git" "$dir/.claude"
            printf '{ "hooks": { "Stop": [] } }\n' > "$dir/.claude/settings.json"
            ;;
        committed-hooks-empty)
            mkdir -p "$dir/.git" "$dir/.claude"
            printf '{ "hooks": {} }\n' > "$dir/.claude/settings.json"
            ;;
        committed-no-hooks-key)
            mkdir -p "$dir/.git" "$dir/.claude"
            printf '{ "model": "opus" }\n' > "$dir/.claude/settings.json"
            ;;
        committed-unparseable)
            mkdir -p "$dir/.git" "$dir/.claude"
            printf 'not json at all\n' > "$dir/.claude/settings.json"
            ;;
        committed-empty-file)
            mkdir -p "$dir/.git" "$dir/.claude"
            : > "$dir/.claude/settings.json"
            ;;
        committed-is-dir)
            mkdir -p "$dir/.git" "$dir/.claude/settings.json"
            ;;
        local-already-present)
            mkdir -p "$dir/.git" "$dir/.claude"
            printf '{ "hooks": {} }\n' > "$dir/.claude/settings.local.json"
            ;;
        local-unparseable)
            mkdir -p "$dir/.git" "$dir/.claude"
            printf 'garbage\n' > "$dir/.claude/settings.local.json"
            ;;
        doc-string-mentions-hooks)
            # The `"hooks"` probe must anchor on the QUOTED key, not a prose mention.
            mkdir -p "$dir/.git" "$dir/.claude"
            printf '{ "_comment": "this project wires hooks elsewhere" }\n' > "$dir/.claude/settings.json"
            ;;
        pre-existing-pre-commit)
            mkdir -p "$dir/.git/hooks"
            printf '#!/bin/sh\necho stale\n' > "$dir/.git/hooks/pre-commit"
            ;;
        *)
            echo "unknown scenario: $scenario" >&2
            exit 2
            ;;
    esac
}

# snapshot <dir> — every observable the installer may touch, as one comparable blob.
snapshot() {
    local dir="$1" f
    for f in ".git/hooks/pre-commit" ".claude/settings.json" ".claude/settings.local.json"; do
        if [ -f "$dir/$f" ]; then
            printf '=== %s (regular file) ===\n' "$f"
            cat "$dir/$f"
        elif [ -d "$dir/$f" ]; then
            printf '=== %s (directory) ===\n' "$f"
        else
            printf '=== %s (absent) ===\n' "$f"
        fi
    done
    # Any temp file left behind is itself a divergence.
    find "$dir/.claude" -name '*.tmp-*' 2>/dev/null | sed "s|$dir||" | sort
}

run_scenario() {
    local scenario="$1"
    local shdir="$WORK/$scenario.sh" jsdir="$WORK/$scenario.js"

    build_sandbox "$shdir" "$scenario"
    build_sandbox "$jsdir" "$scenario"

    local sh_out sh_rc js_out js_rc
    sh_out=$(cd "$shdir" && bash "$shdir/$SH_REL" 2>&1); sh_rc=$?
    js_out=$(cd "$jsdir" && node "$jsdir/$JS_REL" 2>&1); js_rc=$?

    # Paths differ by sandbox root; normalise before comparing.
    sh_out=${sh_out//$shdir/ROOT}
    js_out=${js_out//$jsdir/ROOT}

    local sh_snap js_snap
    sh_snap=$(snapshot "$shdir")
    js_snap=$(snapshot "$jsdir")

    local why=""
    [ "$sh_rc" != "$js_rc" ] && why="exit"
    [ "$sh_out" != "$js_out" ] && why="${why:+$why,}output"
    [ "$sh_snap" != "$js_snap" ] && why="${why:+$why,}files"

    if [ -z "$why" ]; then
        pass=$((pass + 1))
        printf '  ok    %-28s (exit %s)\n' "$scenario" "$sh_rc"
    else
        fail=$((fail + 1))
        printf '  FAIL  %-28s (%s)\n' "$scenario" "$why"
        printf '        sh rc=%s   js rc=%s\n' "$sh_rc" "$js_rc"
        if [ "$sh_out" != "$js_out" ]; then
            diff <(printf '%s\n' "$sh_out") <(printf '%s\n' "$js_out") | head -12 | sed 's/^/        /'
        fi
        if [ "$sh_snap" != "$js_snap" ]; then
            diff <(printf '%s\n' "$sh_snap") <(printf '%s\n' "$js_snap") | head -20 | sed 's/^/        /'
        fi
    fi
}

echo "=== install-hooks differential: shell twin vs TypeScript port ==="
echo

for s in \
    fresh-repo \
    no-git \
    committed-hooks-present \
    committed-hooks-empty \
    committed-no-hooks-key \
    committed-unparseable \
    committed-empty-file \
    committed-is-dir \
    local-already-present \
    local-unparseable \
    doc-string-mentions-hooks \
    pre-existing-pre-commit
do
    run_scenario "$s"
done

echo
echo "=== $((pass + fail)) scenarios: $pass identical, $fail divergent ==="
[ "$fail" -eq 0 ] || exit 1
echo "Exit code, output and written bytes all match."
