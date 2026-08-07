#!/usr/bin/env bash
# install-hooks.sh — launcher. The implementation is src/install-hooks.ts, compiled to
# .harness/scripts/install-hooks.js and committed alongside this file.
#
# This file holds no logic on purpose. It exists so the ~27 sites that invoke
# `bash .harness/scripts/install-hooks.sh` — including the deliberately-frozen byte-form
# literals in the test drivers and the live hook wiring — keep working unchanged.
#
# `exec` replaces this shell, so stdin, stdout, stderr and the exit status all pass
# through untouched. A missing node makes exec fail non-zero, which is the correct
# fail-CLOSED direction for the guard. Do not add a fallback.
exec node "$(dirname -- "$0")/install-hooks.js" "$@"
