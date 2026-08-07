#!/usr/bin/env bash
# make-shims.sh — replace a ported script's shell twins with launchers.
#
# Once a component is ported to TypeScript, its .sh and .ps1 stop being implementations
# and become two-line launchers. That is the whole win: there is no logic left in them to
# diverge, so the cross-shell divergence class and the PowerShell-only operator
# obligations both go away, WITHOUT touching any of the ~27 files that reference the
# script by name, the deliberately-frozen byte-form literals, or the live hook wiring.
#
# guard-rm is fail-CLOSED and its launcher must stay that way: `exec node …` fails with a
# non-zero status when node is missing, which is a BLOCK. Never add a fallback.
#
# Usage: bash tools/make-shims.sh <name>...

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

TEMPLATE="skills/harness-init/templates/common/.harness/scripts"

for name in "$@"; do
    js=".harness/scripts/$name.js"
    if [ ! -f "$js" ]; then
        echo "make-shims: $js missing — run 'npm run build' first" >&2
        exit 2
    fi

    for dir in ".harness/scripts" "$TEMPLATE"; do
        cat > "$dir/$name.sh" <<SHEOF
#!/usr/bin/env bash
# $name.sh — launcher. The implementation is src/$name.ts, compiled to
# .harness/scripts/$name.js and committed alongside this file.
#
# This file holds no logic on purpose. It exists so the ~27 sites that invoke
# \`bash .harness/scripts/$name.sh\` — including the deliberately-frozen byte-form
# literals in the test drivers and the live hook wiring — keep working unchanged.
#
# \`exec\` replaces this shell, so stdin, stdout, stderr and the exit status all pass
# through untouched. A missing node makes exec fail non-zero, which is the correct
# fail-CLOSED direction for the guard. Do not add a fallback.
exec node "\$(dirname -- "\$0")/$name.js" "\$@"
SHEOF
        chmod +x "$dir/$name.sh"

        cat > "$dir/$name.ps1" <<PSEOF
# $name.ps1 — launcher. The implementation is src/$name.ts, compiled to
# .harness/scripts/$name.js and committed alongside this file.
#
# This file holds no logic on purpose. It exists so every site that invokes
# \`pwsh -File .harness/scripts/$name.ps1\` keeps working unchanged.
#
# One implementation now runs on both host operating systems, so nothing here can
# diverge from the bash launcher. A missing node leaves \$LASTEXITCODE non-zero, which
# is the correct fail-CLOSED direction for the guard. Do not add a fallback.
& node (Join-Path \$PSScriptRoot "$name.js") @args
exit \$LASTEXITCODE
PSEOF
    done
    echo "  shimmed: $name (.sh + .ps1, dogfood + template)"
done
