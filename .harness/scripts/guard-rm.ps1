# guard-rm.ps1 — launcher. The implementation is src/guard-rm.ts, compiled to
# .harness/scripts/guard-rm.js and committed alongside this file.
#
# This file holds no logic on purpose. It exists so every site that invokes
# `pwsh -File .harness/scripts/guard-rm.ps1` keeps working unchanged.
#
# One implementation now runs on both host operating systems, so nothing here can
# diverge from the bash launcher. A missing node leaves $LASTEXITCODE non-zero, which
# is the correct fail-CLOSED direction for the guard. Do not add a fallback.
& node (Join-Path $PSScriptRoot "guard-rm.js") @args
exit $LASTEXITCODE
