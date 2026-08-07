# 02 — Solution Design · T-16 `hook-truth-derivation`

- **Mode**: `full` (stages 1-7) · dispatched from a `/harness-stream` drain.
- **Revision**: **round 3 (record-only)**. Round 2 revised the design in place after
  `03_GATE_REVIEW.md` returned **CHANGES REQUIRED** with eleven findings, all routed to this document
  — **§18 answers F-1 … F-11 individually**. **Round 3 changes no design decision, mechanism or
  acceptance criterion**: after the implementation shipped, was **APPROVED** by code review round 2
  and **PASSed** QA, three statements in this document were found false or dangling and are corrected
  in place. **§20 records all three**, and every corrected passage points at it.
  `01_REQUIREMENT_ANALYSIS.md` stands as written and is not edited by this agent.
- **Upstream verdict**: `01_REQUIREMENT_ANALYSIS.md` = **READY**. Its §9 `Recommended:` answers
  **OQ-1 … OQ-8 are adopted verbatim**; §14 records the places where a recommendation had an
  unstated consequence and how it is resolved. No recommendation is overturned.
- **deferred-human mode**: defer, do not ask. Decision Mode 2 (balanced). Every judgement call is
  logged in §14 (D-1 … D-7). No `BLOCKED: NEEDS-HUMAN` item arose.
- **Version target**: fold into the unreleased **0.46.0**. No version stamp moves.
- **Partition assignment**: **single Developer** — `.harness/agents/` contains no `dev-*` partition
  agents in this repo (`AI-GUIDE.md:15`). No partition table, no dispatch order.

**Safety notice for the implementer — read before writing anything.** `.harness/scripts/guard-rm.sh`
is this machine's live fail-closed `PreToolUse` hook. It is **frozen** (§13). So are
`.harness/rules/75-safety-hook.md` (200/200 lines) and `docs/proposals/frontier-gaps-2026-07.md`.
This design touches none of them and no edit is authorised "while in there".

---

## 1. Architecture summary

The four derivation flows stop *carrying* hook command byte-forms and start *asking* for them. Each
of the two script flows (`upgrade-project`, `migrate-scripts-layout`) grows a small **spec adapter**
— resolve the `hook-spec` twin of the caller's own shell (lazily, at first query), invoke it, memoise
the answer per `(tool, os)`, and return **"no answer"** rather than a fabricated string when it
cannot. The `resilient_cmd` / `Get-ResilientCmd` helper is **retired**: after the change it would be
a pass-through mapping a boolean to `windows`/`unix`, and each of its two call sites per flow has to
grow a failure branch anyway, so the call sites invoke the adapter directly (§3.1, §14 D-5). Each of
the two prose flows (`harness-init`, `harness-adopt`) drops its byte-form columns and instructs the
executing agent to invoke the spec and paste the captured line verbatim. Alongside, `verify_all`'s
`F.2` stops asking whether the guard placeholder exists *somewhere* in the settings template and
starts asking whether it exists *inside the `PreToolUse` block* — still one check, still 32 total.
Nothing about the emitted bytes changes; the only thing that changes is where they come from.

Deletion test: delete the adapter and the duplication reappears in four flows × two shells. It earns
its keep. Its interface is two functions and one failure convention; everything else — path
resolution order, caching, cross-shell prohibition, empty-answer handling — sits behind it.

---

## 2. Affected modules

| Path | Role |
|---|---|
| `/home/alan/Programs/harness-kit/skills/harness-init/templates/common/.harness/scripts/upgrade-project.{sh,ps1}` | upgrade-repair flow — **template source of truth** |
| `/home/alan/Programs/harness-kit/.harness/scripts/upgrade-project.{sh,ps1}` | dogfood twin (sync-self Mapping 7) |
| `/home/alan/Programs/harness-kit/skills/harness-init/templates/common/.harness/scripts/migrate-scripts-layout.{sh,ps1}` | layout-migration flow — **template source of truth** |
| `/home/alan/Programs/harness-kit/.harness/scripts/migrate-scripts-layout.{sh,ps1}` | dogfood twin (sync-self Mapping 6) |
| `/home/alan/Programs/harness-kit/skills/harness-init/templates/common/.harness/scripts/hook-spec.{sh,ps1}` | the spec — **header comment only** (Mapping 9) |
| `/home/alan/Programs/harness-kit/.harness/scripts/hook-spec.{sh,ps1}` | dogfood twin |
| `/home/alan/Programs/harness-kit/skills/harness-init/SKILL.md` | project-creation flow (step-5 placeholder table, `:187-190`) |
| `/home/alan/Programs/harness-kit/skills/harness-adopt/SKILL.md` | adoption flow (substitution table, `:311-314`) |
| `/home/alan/Programs/harness-kit/.harness/scripts/verify_all.{sh,ps1}` | gate check `F.2` (`sh:301-322`, `ps1:287-311`) |
| `/home/alan/Programs/harness-kit/.harness/scripts/test-init.{sh,ps1}` | T-13 oracle block (`sh:750-856`, `ps1:872-…`) |
| `/home/alan/Programs/harness-kit/.harness/scripts/test-real-project.{sh,ps1}` | frozen fixture literals (`sh:40-59`) |
| `/home/alan/Programs/harness-kit/AI-GUIDE.md`, `docs/getting-started.md`, `.harness/rules/60-tool-handoff.md` | the three stale prose consumers |

---

## 3. The spec adapter (per-flow derivation mechanism)

### 3.1 Interface (identical in both shells, both flows)

Everything a caller must know:

- `hsa_command <tool> <os>` / `Invoke-HookSpecCached` — obtain one byte-form. Success: exit 0 and
  the value in the out-variable `hsa_out` (bash) / the function's return value (PowerShell).
  Failure: non-zero and `hsa_out=""` (bash) / `$null` (PowerShell). There is **no third return
  path**: no default, no fallback, no embedded copy. This single property is what discharges B-3
  and AC-4 structurally rather than by inspection.
- `hsa_hostos` / `Get-HookSpecHostOs` — `windows` | `unix`, same success/failure convention
  (`Get-HookSpecHostOs` is **defined** in §3.4; round 1 named it in this interface without ever
  defining it — F-9).
- `hsa_path` / `$script:hsSpecPath` — the resolved spec path, or the literal `not found`, for the
  diagnostic records in §5. Read-only for callers.
- **`resilient_cmd` / `Get-ResilientCmd` are RETIRED, not retained** (round-2 change; §14 D-5).
  After the change they would be pass-throughs mapping a boolean to `windows`/`unix` with no
  behaviour of their own, and every call site has to change anyway (each now needs a failure
  branch, §5). Both call sites in each flow call the adapter directly and compute the OS token
  where they already compute the file extension. Deleting a pass-through is not a scope increase:
  it is what makes AC-3's "no literal survives in a flow" trivially true and it removes F-9's
  `Get-ResilientCmd $ph.Tool $IsWindows` positional-automatic problem at the root instead of
  patching it.
- **Ordering constraint (restated — F-1).** The adapter block **defines functions only**. It
  executes nothing at definition time and **reads no flow variable at definition time**. Candidate
  resolution is **lazy**: it happens inside `hsa_resolve` / `Resolve-HookSpecPath` on the *first*
  query and is memoised. The block therefore sits **exactly where the retired helper sits today**
  in all four files (`upgrade-project.sh:93-117`, `.ps1:102-126`,
  `migrate-scripts-layout.sh:112-132`, `.ps1:31-50`) and **no binding order changes**. Round 1's
  constraint ("after argument parsing so `$TEMPLATE_ROOT` is bound") was both insufficient and
  unnecessary — see §3.2 for the measured binding order it missed.
- **Never call the bash adapter inside `$( … )`.** Command substitution forks a subshell, so the
  cache write is discarded and the next call re-spawns the spec — 13 spawns per run instead of ≤9,
  breaking NFR-1's "values are obtained once per run and reused". This is the whole reason for the
  out-variable convention, and it is the one place the two shells use different idioms: a
  PowerShell function call is in-process, so `$script:`-scoped cache writes persist and the PS
  adapter can return its value normally. The asymmetry is idiom-level, not behaviour-level.
- **Naming.** The bash adapter uses the `hsa_` (hook-spec **a**dapter) prefix because
  `hook-spec.sh:99` already defines an *internal* function named `hs_command`; two different
  `hs_command`s in one repo would make the AC-3 / A′ greps and any future reader ambiguous.
- **Performance**: at most one spec invocation per distinct `(tool, os)` key per run, plus at most
  one `hostos` invocation — **≤ 9 process spawns per run** (8 command keys + 1 hostos), memoised
  across both consuming steps *in the caller's own shell*.

### 3.2 Spec resolution (which file, in which order) — resolved lazily, at first query

`upgrade-project` — first existing candidate wins:

1. `$template_common_scripts/hook-spec.<ext>` — the **current plugin template**, already a validated
   precondition (`upgrade-project.sh:56-61`). This flow's job is to bring a stale project to the
   *current* layout, so the current template's spec is the correct authority; using the project's own
   possibly-stale copy would emit stale bytes into a "repaired" settings file.
2. sibling of the running script (`dirname "$0"` / `$PSScriptRoot`).
3. `$dst_dir/hook-spec.<ext>` (the project's own `.harness/scripts/`).

`migrate-scripts-layout` — no template root exists in this flow's contract:

1. sibling of the running script.
2. `$dst_dir/hook-spec.<ext>`.

**Why lazy, measured rather than assumed (F-1).** The candidate list reads variables that are bound
*after* the point where the retired helper sits. Measured on the current files:

| File | Retired helper at | `$template_common_scripts` bound | `dst_dir` / `$dstDir` bound | Adapter's first *call* |
|---|---|---|---|---|
| `.harness/scripts/upgrade-project.sh` | `:102` | `:56` | **`:150`** | `:282` (S3.0) |
| `.harness/scripts/upgrade-project.ps1` | `:112` | `:67` | **`:147`** | `:286` (S3.0) |
| `.harness/scripts/migrate-scripts-layout.sh` | `:117` | n/a | `:40` | `:193` |
| `.harness/scripts/migrate-scripts-layout.ps1` | **`:36`** | n/a | **`:56`** | `:168` |

A *top-level* candidate loop at the helper's position — round 1's shape — expands `dst_dir` before
`:150` in three of the four files. Under `set -uo pipefail` (`upgrade-project.sh:26`) bash aborts the
whole run; under `$ErrorActionPreference = "Stop"` (`upgrade-project.ps1:58`,
`migrate-scripts-layout.ps1:29`) `Join-Path` rejects a `$null` `-Path` with a terminating error and
kills the repair helper. Only `migrate-scripts-layout.sh` was safe — a three-of-four cross-shell
asymmetry, `01 NFR-3`'s named failure class.

Making resolution lazy removes the constraint entirely rather than satisfying it: the first call in
every file (rightmost column) is after every binding in the row. Defensive expansion is used anyway
(`${dst_dir:-}` in bash; `if ($dstDir)` in PowerShell, where an undefined variable is `$null` — this
repo sets `Set-StrictMode` nowhere, verified by repo-wide search), so a future re-ordering of either
file degrades to "candidate skipped", never to an abort.

**Totality.** The candidate list is a first-match-wins scan over a finite list; if no candidate
exists the resolver records "not found" and every subsequent query takes the single failure return
of §3.1. There is no input for which resolution is undefined.

**Cross-shell prohibition (B-7) is enforced by construction**: the bash adapter only ever forms
`…/hook-spec.sh` candidates and invokes them with `bash`; the PowerShell adapter only ever forms
`…/hook-spec.ps1` and invokes them with `& pwsh -NoProfile -File`. Neither shell has a code path that
can name the other's twin, so the MSYS `$( … )` CR-corruption the spec header warns about is
unreachable rather than merely handled.

### 3.3 Bash mechanism (pseudo-code — both flows, identical block)

```
# --- hook-spec adapter (T-16). FUNCTIONS + inert scalars ONLY: nothing below runs
#     at definition time and no flow variable is READ at definition time, so this
#     block sits exactly where resilient_cmd sat (§3.1 ordering constraint).
hsa_bin=""            # ""  = not resolved yet
                      # "-" = resolved, NOT FOUND (a path can never be "-")
hsa_out=""            # the last successful answer; "" after any failure
hsa_n=0               # cache length; the three arrays below are index-addressed
hsa_keys=(); hsa_vals=(); hsa_rcs=()   # parallel indexed arrays, ≤9 entries, linear scan
                                       # (deliberately NOT `declare -A`: bash 3.2 compatible,
                                       #  matching the rest of these two files)

hsa_resolve() {                         # lazy; the body runs at most once per run
    [[ -n "$hsa_bin" ]] && return 0
    local c
    local cands=()
    # NEXT LINE IS THE ONLY PER-FILE DIFFERENCE: present in upgrade-project.sh,
    # ABSENT in migrate-scripts-layout.sh (that flow has no template root).
    [[ -n "${template_common_scripts:-}" ]] && cands+=("$template_common_scripts/hook-spec.sh")
    cands+=("$(dirname -- "$0")/hook-spec.sh")        # always ≥1 element, so the
    [[ -n "${dst_dir:-}" ]] && cands+=("$dst_dir/hook-spec.sh")   # expansion below is
    for c in "${cands[@]}"; do                        # never an empty-array expansion
        [[ -f "$c" ]] && { hsa_bin="$c"; return 0; }
    done
    hsa_bin="-"
    return 0
}

hsa_path() { if [[ "$hsa_bin" == "-" || -z "$hsa_bin" ]]; then printf '%s' "not found"; \
             else printf '%s' "$hsa_bin"; fi; }

hsa_query() {                           # $1 = cache key, $2.. = spec argv
    local k="$1"; shift
    local i v rc
    for (( i = 0; i < hsa_n; i++ )); do          # C-STYLE loop over an explicit counter.
        if [[ "${hsa_keys[$i]}" == "$k" ]]; then # NEVER `for i in "${!hsa_keys[@]}"`: an
            hsa_out="${hsa_vals[$i]}"            # empty-array expansion is an UNBOUND
            return "${hsa_rcs[$i]}"              # VARIABLE error under `set -u` on bash
        fi                                       # < 4.4 — including the macOS 3.2 this
    done                                         # array choice exists for (F-5).
    hsa_resolve
    v=""; rc=1
    if [[ "$hsa_bin" != "-" ]]; then
        v="$(bash "$hsa_bin" "$@" 2>/dev/null)"; rc=$?     # `set -uo`, no -e: capture rc explicitly
        (( rc == 0 )) && [[ -n "$v" ]] || { v=""; rc=1; }  # exit 2 AND empty stdout both land here
    fi
    hsa_keys[$hsa_n]="$k"; hsa_vals[$hsa_n]="$v"; hsa_rcs[$hsa_n]="$rc"
    hsa_n=$(( hsa_n + 1 ))
    hsa_out="$v"
    return "$rc"
}

hsa_command() { hsa_query "cmd/$1/$2" command "$1" "$2"; }
hsa_hostos()  { hsa_query "hostos"    hostos; }
```

Call shape at every site (this replaces `x="$(resilient_cmd …)"`):

```
if hsa_command "$tool" "$os"; then
    cmd="$hsa_out"
    …existing substitution, unchanged…
else
    emit "GAP|hook-spec|absent|.claude/settings.json (… at $(hsa_path) …)"    # §5
fi
```

Four nuances the developer must not "simplify":

- **Never `x="$(hsa_command …)"`.** The cache lives in shell variables; a command substitution
  forks a subshell and every cache write is thrown away, so each of the 12 call-site invocations
  re-spawns the spec (NFR-1 caps it at 9). `$(hsa_path)` *is* fine — it is a pure reader.
- `install-hooks.sh:176` uses `if ! v="$(…)"` because it runs under `set -e`. These two flows run
  under `set -uo pipefail` (`upgrade-project.sh:26`, `migrate-scripts-layout.sh:24`), so the plain
  capture-then-check-`$?` form above is correct. Do not import `set -e`.
- The value is only ever moved by plain assignment and consumed by `str_replace_all` (§4). If it is
  ever printed, it is printed with `printf '%s' "$hsa_out"` — **never** `printf "$hsa_out"`,
  `echo "$hsa_out"`, or an unquoted expansion. The byte-forms are `%`-free but carry `\` and a
  literal `&`.
- `local cands=()` then `cands+=(…)` unconditionally for the sibling candidate keeps `"${cands[@]}"`
  non-empty by construction — the same `set -u`/bash-3.2 hazard as the cache loop, closed the same
  way. The surrounding code already guards this shape (`migrate-scripts-layout.sh:266,277`).

**Byte-identity chain (why this emits the same bytes).** `hook-spec.sh:103-111` prints the shape with
`printf '%s\n'`; `$( … )` inside `hsa_query` strips exactly that one trailing newline; the value then
reaches the substitution by assignment only. What `resilient_cmd`'s `printf '%s'`
(`upgrade-project.sh:106-114`) produced today is the same byte string: the two source literals are
already proven equal by `test-init.sh:776-785` Group A on every green run to date, and §11 C-1/C-2
re-prove it mechanically against an S0 capture.

### 3.4 PowerShell mechanism (pseudo-code — both flows, identical block)

Modelled on the shipped consumer `install-hooks.ps1:190-199`, which is the reuse target:

```
# --- hook-spec adapter (T-16). Definitions + inert scalars only.
$script:hsSpecPath  = ''      # ''  = not resolved yet
                              # '-' = resolved, NOT FOUND (a path can never be '-')
$script:hsCacheKey  = @()
$script:hsCacheVal  = @()     # parallel arrays; a cached FAILURE is stored as $null

function Resolve-HookSpecPath {                  # lazy; the body runs at most once per run
    if ($script:hsSpecPath -cne '') { return }
    $cands = @()
    # NEXT LINE IS THE ONLY PER-FILE DIFFERENCE: present in upgrade-project.ps1,
    # ABSENT in migrate-scripts-layout.ps1 (that flow has no template root).
    if ($templateCommonScripts) { $cands += (Join-Path $templateCommonScripts "hook-spec.ps1") }
    if ($PSScriptRoot)          { $cands += (Join-Path $PSScriptRoot "hook-spec.ps1") }
    if ($dstDir)                { $cands += (Join-Path $dstDir "hook-spec.ps1") }
    foreach ($c in $cands) {
        if (Test-Path -LiteralPath $c -PathType Leaf) { $script:hsSpecPath = $c; return }
    }
    $script:hsSpecPath = '-'
}

function Get-HookSpecPathForMessage {            # the §5 diagnostic's <path-or-"not found">
    if (($script:hsSpecPath -ceq '-') -or ($script:hsSpecPath -ceq '')) { return 'not found' }
    return $script:hsSpecPath
}

function Invoke-HookSpecCached([string]$CacheKey, [string[]]$SpecArgs) {
    for ($i = 0; $i -lt $script:hsCacheKey.Count; $i++) {
        if ($script:hsCacheKey[$i] -ceq $CacheKey) { return $script:hsCacheVal[$i] }
    }
    # A non-zero NATIVE exit under $ErrorActionPreference='Stop' becomes a terminating
    # error on PS 7.4+; the spec answers exit 2 by design. Opt out for THIS function
    # scope only (precedent: test-init.ps1:885-888) AND keep the try/catch.
    $PSNativeCommandUseErrorActionPreference = $false
    Resolve-HookSpecPath
    $val = $null
    if ($script:hsSpecPath -cne '-') {
        try   { $out = & pwsh -NoProfile -File $script:hsSpecPath @SpecArgs }
        catch { $out = $null; $global:LASTEXITCODE = 1 }
        if (($LASTEXITCODE -eq 0) -and ($null -ne $out)) {
            $first = @($out) | Select-Object -First 1        # NEVER [string]$out on an array:
            $s = [string]$first                              # PS joins array elements with a SPACE
            if (-not [string]::IsNullOrEmpty($s)) { $val = $s }
        }
    }
    $script:hsCacheKey += $CacheKey
    $script:hsCacheVal += $val
    return $val
}

function Get-HookSpecCommand([string]$tool, [string]$targetOs) {
    return (Invoke-HookSpecCached ("cmd/{0}/{1}" -f $tool, $targetOs) @('command', $tool, $targetOs))
}

function Get-HookSpecHostOs {                    # F-9: named in §3.1 round 1, never defined
    return (Invoke-HookSpecCached 'hostos' @('hostos'))
}
```

Call shape at every site (this replaces `$x = Get-ResilientCmd …`):

```
$cmd = Get-HookSpecCommand $tool $os
if ($null -eq $cmd) {
    Emit ("GAP|hook-spec|absent|.claude/settings.json (… at {0} …)" -f (Get-HookSpecPathForMessage))
    continue
}
…existing .Replace(), unchanged…
```

Mandatory PowerShell hazards, each a named member of the agent-unexecutable family:

1. **No identifier may collide with a read-only automatic variable.** `$isWindows`, `$IsWindows`,
   `$Host`, `$Args`, `$Input`, `$PSScriptRoot` are all forbidden as *assignment* targets — note the
   adapter only ever **reads** `$PSScriptRoot`. `$hsIsWin` (§3.6) is the new host-OS boolean and is
   deliberately not `$isWindows` (T-12 shipped that exact defect once).
2. **No `-join` adjacent to `+`.** Binary `-join` binds below `+`. Build every message with `-f`.
3. **The whole file parses before anything runs.** A syntax error in a never-taken adapter branch
   kills the entire repair helper on Windows. Operator `[Parser]::ParseFile` is mandatory (§12).
4. **`@($out) | Select-Object -First 1`, never `[string]$out`** — a multi-line answer cast to
   `[string]` is space-joined, silently producing a wrong command.
5. **`$ErrorActionPreference = "Stop"` is script-scope in both flows.** A native command raising
   `NativeCommandError` would escape; the `try/catch` above is not optional, and the `catch` must
   force `$LASTEXITCODE` to non-zero — otherwise a *stale* zero from an earlier native call would
   make the next `if` accept a `$null` answer.
6. **Cache writes must be `$script:`-scoped.** A bare `$hsCacheKey += …` inside a function creates a
   function-local copy and the cache silently never fills (PowerShell's copy-on-write scoping).
   There is no subshell problem in PowerShell — that is bash-only (§3.1) — but this scoping trap is
   the PS-side equivalent and is just as silent.
7. **`$cands = @()` then `foreach`** — an empty array `foreach` is a legal no-op in PowerShell, so
   the bash empty-array hazard has no PS twin here. Do not "fix" it symmetrically.

### 3.5 How the value reaches the emitted settings text

Unchanged substitution machinery; the call sites change shape exactly as much as the failure branch
requires and no more. This table is **total** over the call sites: a repo-wide search for
`resilient_cmd` / `Get-ResilientCmd` returns exactly these three per shell (plus the definitions and
comments the change deletes, and the frozen historical mentions in `docs/tasks.md:18`,
`CHANGELOG.md:127`, `.harness/insight-index.md:20`, `baseline.json:26` — decoys, never edited).

| Flow · step | Call site today | After |
|---|---|---|
| `upgrade-project` S3.0 placeholder repair | `sh:282` / `ps1:286` | `hsa_command` / `Get-HookSpecCommand` with the OS token from §3.6, moved **inside** the `token-present ∧ target-present` guard so no spec call is made for a placeholder the flow would not write; failure branch per §5 |
| `upgrade-project` S3.2 brittle→resilient | `sh:340` / `ps1:338` | unchanged position; `s32_win=true/false` (`sh:333,336` / `ps1:331,334`) becomes `s32_os=windows/unix`; failure branch per §5 |
| `migrate-scripts-layout` brittle→resilient | `sh:193` / `ps1:168` | same, at `sh:186,189` / `ps1:161,164` |
| `upgrade-project` S3.0 host-OS read (PS only) | `ps1:278` `if ($IsWindows)` | `if ($hsIsWin)` — §3.6, F-9 |
| `upgrade-project` S3.0 host-OS read (PS only) | `ps1:286` `Get-ResilientCmd $ph.Tool $IsWindows` | subsumed by row 1: the OS token is `$hsOs`, so the automatic `$IsWindows` is no longer passed positionally |

Nothing else moves. In particular the emitted-text writers (`str_replace_all` in bash,
`.Replace()` in PowerShell), the `.bak` policy, the idempotence needles and the terminal congruence
scans are byte-untouched.

### 3.6 Host-OS discrimination also comes from the spec

`upgrade-project.sh:271-272`'s `is_windows=false; case "${OSTYPE:-}" …` and
`upgrade-project.ps1:278`'s `if ($IsWindows)` are replaced by `hsa_hostos` / `Get-HookSpecHostOs`
(memoised once). The duplication class is real in **both** shells — that is what justifies D-1 — but
it is **not symmetric**, and rounds 1-2 of this document asserted a symmetry that does not exist.
Corrected here; the full record is §20 corrections 1 and 2.

- **bash — no behavioural delta.** `hook-spec.sh:164-167`'s `case "${OSTYPE:-}"` is
  character-identical to the retired `is_windows` block, so the bash flow now *asks* for exactly the
  answer it used to *compute*. Provenance moves, behaviour does not.
- **PowerShell — a one-sided host-OS *selection* delta on Windows PowerShell 5.1.** The spec's branch
  is `hook-spec.ps1:198`'s `if ($IsWindows -or $env:OS -eq "Windows_NT")`, which is strictly **wider**
  than the retired `if ($IsWindows)`. On Windows PowerShell 5.1 `$IsWindows` is undefined (`$null`),
  so the **pre**-change flow selected the **unix** byte-forms on a Windows host and the **post**-change
  flow selects **windows**. Three properties make this safe, and each is a separate argument:
  1. **It is a strict improvement, not a regression** — it repairs a latent 5.1 defect in which a
     Windows host was wired with `sh -c …` commands. There is no host on which the delta selects a
     *worse* answer: the added disjunct can only fire where `$IsWindows` is `$null`, i.e. exactly
     where the old expression was wrong.
  2. **It cannot make the guard fail-open.** §5's B-3 argument is about the *only string source* being
     the spec's stdout; which OS is selected picks *which* of two spec-authored strings is emitted, and
     `hook-spec` authors no fail-open variant of either (`hook-spec.sh:129` / `.ps1:128` carry no
     `exit 0`). Selecting `windows` instead of `unix` moves between two fail-closed forms.
  3. **AC-2 is untouched**, because OS is a **parameter** of the 8-cell byte comparison, not a result
     of it: AC-2 asks "for each `(tool, os)`, are the bytes identical", and all 8 cells were measured
     identical (`06_TEST_REPORT.md` §3.1-3.2). A change in *which cell a given host selects* is
     outside that quantification and therefore needs its own record — which is this one.

  It is nonetheless a behaviour change shipped under a "provenance changes, emitted bytes must not"
  premise, so it is recorded rather than absorbed, and it travels to `07_DELIVERY.md`. **The code is
  not changed**: `hook-spec.ps1:198` is exactly as shipped and reviewed.

Bound once, at the top of S3.0:

```
if hsa_hostos; then hsa_os="$hsa_out"; else hsa_os=""; fi        # bash
$hsOs = Get-HookSpecHostOs; $hsIsWin = ($hsOs -ceq 'windows')    # PowerShell
```

`upgrade-project.ps1:418` / `:434`'s `$IsLinux -or $IsMacOS` (the `chmod` decision in S4) is **not**
hook wiring and is left alone. `migrate-scripts-layout` has no host-OS branch at all in either shell
(its `s32_win` comes from the file extension, `sh:184-190` / `ps1:159-165`) and gains none. See
§14 D-1.

#### The `hostos`-failure skip boundary — respecified (F-4)

Round 1 said "S3.0 is skipped **in its entirety**". That is wrong in bash and would have shipped a
worse failure than the one it degrades from. `ph_o="{{"` is declared at `upgrade-project.sh:270`,
textually inside S3.0, and is **consumed by the terminal congruence scan at `:607`**
(`[[ "$cmd_line" == *"$ph_o"* ]]`). Skipping the whole step leaves `ph_o` unbound at `:607`; under
`set -uo pipefail` bash exits **1** right there — no `SUMMARY|` line, no exit 4, and the terminal
assertion loses the exit-code ownership `01 B-1` requires it to keep, while §5 row 2 predicts exit 4.

**The fix has two parts:**

1. **Hoist the token opener/closer out of S3.0**, to S3 scope — immediately after
   `settings_new=""` (`upgrade-project.sh:249`) and **before** the `if [[ ! -f "$settings" ]]`
   branch. This is not an invention: it is exactly where the PowerShell twin already puts it
   (`upgrade-project.ps1:252-255`, `$phOpen`/`$phClose` at S3 scope, outside S3.0), so the edit
   *removes* a cross-shell asymmetry rather than adding one. `ph_c` is used only inside S3.0 and
   moves with `ph_o` so the pair stays together. The literal text (`ph_o="{{"`) is copied verbatim;
   B-6 is unaffected (a bare `{{` is not a `{{NAME}}` token, and this is the pre-existing
   run-time-assembly idiom, §6.3).
2. **"Skip S3.0" means: skip the four-iteration placeholder loop** (`sh:275-287` /
   `ps1:276-291`) — not the step's variable declarations. `ph_names` / `ph_tools` / `$phPairs` may
   be declared or skipped freely; nothing outside S3.0 reads them (verified: repo-wide search for
   `ph_names`, `ph_tools`, `phPairs` returns hits only inside `:273-287` / `:270-291`).

With both parts, the `hostos`-failure branch emits its one `GAP|` record, leaves all four tokens in
place, reaches `:607` with `ph_o` bound, matches every unresolved token, and exits **4** — which is
what §5 row 2 has always predicted.

**PowerShell is unaffected by part 1 and must not be "fixed" symmetrically.** `$phOpen` at `.ps1:254`
is already at S3 scope; the round-1 review's note that "the PS twin has the same shape" is the one
place I disagree with the gate, and the disagreement is in the gate's favour (it makes the finding
narrower, not wider) — see §18 F-4.

---

## 4. The `&` / `patsub_replacement` handling

The unix convenience byte-form contains `||`; the **Windows guard byte-form contains a literal `&`**
(`& pwsh -NoProfile -File …`, `hook-spec.sh:103`). Under bash 5.2's default `patsub_replacement`, an
unescaped `&` in the *replacement* half of `${var//needle/repl}` expands to the matched text — this
repo shipped exactly that corruption once, in this exact hook JSON (insight 2026-06-21).

**Mandate (bash).** Every substitution of a spec-derived value goes through the existing
literal-replacement helper **`str_replace_all`** — `upgrade-project.sh:124-131` and
`migrate-scripts-layout.sh:138-145`. It is already the mechanism at all three affected call sites
(`upgrade-project.sh:284`, `:341`; `migrate-scripts-layout.sh:194`), so this is a *preservation*
requirement, not a new one:

- **No pattern-substitution expansion of any form** may be introduced anywhere on the path from
  `hsa_out` to the settings text. That means `${var//…/…}` **and** its index/indirect siblings
  `${arr[i]//…}`, `${arr[@]//…}`, `${!ref//…}`, and the single-replace `${var/…/…}` — all four carry
  the same `&` rule. No `sed` either (the value also carries `|`, `;`, `{`, `}`).
  §11 C-7's grep is widened to match all of them (F-10) and is promoted to a standing assertion
  (§8 Group A′).
- The adapter itself performs **zero** substitution on the value — capture, cache, emit. The spec's
  purity contract (`hook-spec.sh:8-10`, "no substitution … do not post-process the result anywhere")
  is preserved end-to-end, which is what makes the hazard *unreachable* here rather than *handled*.
- The cache key is built from tool/OS ids, which contain no `&`.

**PowerShell is ordinal and therefore unaffected.** `String.Replace(string,string)` performs a
literal, culture-invariant substitution; `&` has no replacement-pattern meaning. Both flows already
use `.Replace` (`upgrade-project.ps1:288`, `:339`; `migrate-scripts-layout.ps1:169`) and keep it.

**Why the asymmetry makes the corruption invisible to a PS-only check.** The two shells reach the
same logical step through engines with different escape semantics: PowerShell's has no `&` rule at
all, so a PowerShell run — including a full green `test-init.ps1` — exercises a code path on which the
defect cannot exist. A green PS run is therefore **zero evidence** about the bash path, and the
corruption would only surface on a bash host, at upgrade time, in a user's settings file. This is why
§11 C-7 requires a *bash-side mechanical* check over the flow files' non-comment lines rather than an
argument, and why §8's Group A′ makes that same check **standing** rather than one-time. The PS twin
of the mandate is "no `-replace`" (PowerShell's regex replacement half interprets `$1`/`$&`, exactly
the analogous hazard); measured today, `-replace` has **zero** occurrences in either `.ps1` flow file
and `${var//` occurs in the two `.sh` flow files only on comment lines
(`upgrade-project.sh:120`, `migrate-scripts-layout.sh:135`), so both assertions are green on the
pre-change tree and only a regression can redden them.

---

## 5. The degradation contract (B-1 / B-2 / B-3 · OQ-3(b))

**Trigger classes, all collapsed to one.** Spec file absent · spec file unreadable · spec exits 2 ·
spec exits 0 with empty stdout — all four produce the adapter's single failure return (§3.1). The
spec's own totality invariant (`hook-spec.sh:30-32`: exit 0 ⟺ non-empty stdout) makes the collapse
sound; the adapter re-checks emptiness anyway rather than trusting it.

**The spec is consulted lazily — only when the flow is about to write.** This is what makes AC-5
satisfiable in the re-run direction: an already-repaired project matches no needle, queries nothing,
and emits nothing.

| Flow · step | Tool | Spec unreachable ⇒ |
|---|---|---|
| `upgrade-project` S3.0 | any of the four | the placeholder token is **left in place** (not replaced, not emptied). One record per tool: `GAP\|hook-spec\|absent\|.claude/settings.json (<PLACEHOLDER_NAME>: hook wiring spec unavailable at <path-or-"not found"> — placeholder left unresolved)`. No `REWIRE-PLACEHOLDER` line is emitted. |
| `upgrade-project` S3.0 (`hostos` failure) | all four at once | the S3.0 **placeholder loop** is skipped (not the step's declarations — §3.6 F-4), one `GAP\|hook-spec\|absent\|.claude/settings.json (host OS undeterminable — SYNC_COMMAND, GUARD_COMMAND, AMBIENT_PROMPT_COMMAND, AMBIENT_RESET_COMMAND left unresolved)` |
| `upgrade-project` S3.2 | any of the four × `{ps1,sh}` | the **existing brittle command value is left byte-untouched**. One record per `(tool, ext)`: `GAP\|hook-spec\|absent\|.claude/settings.json (<tool>.<ext>: hook wiring spec unavailable — brittle command left as-is)`. No `REWIRE-RESILIENT` line. |
| `migrate-scripts-layout` | any of the four × `{ps1,sh}` | existing value left byte-untouched; one `plan` entry `SPEC-GAP  .claude/settings.json (<tool>.<ext>: hook wiring spec unavailable at <path-or-"not found"> — command left unchanged; run /harness-upgrade)` |

**Totality of this table (re-audited in round 2 per F-3's instruction).** The rows quantify over
`(flow, step, tool, ext)`. `upgrade-project` has exactly two spec-consuming steps (S3.0, S3.2) and
`migrate-scripts-layout` exactly one; S3.0 is host-OS-keyed (one cell per tool) and S3.2/migrate are
extension-keyed (two cells per tool), so the four rows cover 4 + 1 + 8 + 8 = every reachable cell.
The `hostos` failure is the only whole-step failure and has its own row. There is no fifth trigger:
resolution is total (§3.2) and the four trigger classes above are exhaustive over "the adapter did
not return a value".

**Exit-code contract is preserved (OQ-3(b)).**

- `GAP|…` is an existing upgrade-project record type (`upgrade-project.sh:206`) that increments no
  counter and sets no exit code; the `<verb>` list in `upgrade-project.ps1:33-34` needs no change
  because `GAP` is its own record shape (`:29`), not a verb. **No new stdout record type is added.**
- S3.0's unresolved token is caught by the *existing* terminal congruence scan
  (`upgrade-project.sh:607-611`) → `CONFLICT|congruence|… -> unresolved placeholder token` → **exit 4**.
  The terminal assertion continues to own the exit code for a dangling wiring, exactly as B-1 requires.
- S3.2 / migrate leaving a brittle-but-present command is **not** a congruence failure: the value is
  the pre-existing one and its target was proven present by the `target_present` gate that already
  guards the step. Exit stays 0. A partially repairable project stays repairable.
- `SPEC-GAP` entering `migrate`'s `plan` array changes the report path from "Already migrated /
  nothing to do." to the header + the record line, still exit 0, still no `.bak` (the write is gated
  on `$new -cne $raw`, which the failure branch cannot move).

**Idempotence / re-run direction (AC-5).** Run 2 with the spec still absent reaches the same needles,
takes the same failure branch, emits the same records, writes nothing, and produces the same exit
code. Run 2 with the spec restored performs the repair normally — the failure branch leaves **no
residue** (no sentinel, no partial value, no marker) for a later run to trip over.

**B-3, the fail-closed asymmetry, is structural.** `guard-rm` has no distinguished branch anywhere in
the adapter. The adapter's only string source is the spec's stdout, and the only alternative is
"return nothing". There is no expression in the design that can produce a `guard-rm` command
containing `|| exit 0` or a trailing `exit 0`, because there is no expression that constructs a
command at all. AC-4 is therefore discharged by construction and re-measured by §11.

---

## 6. The prose flows (OQ-4(b))

### 6.1 What the tables keep, what they drop

**Keep** (the spec does not answer these): which placeholder token; which file it lands in
(`.claude/settings.json`, and only that file); its lifecycle event; its matcher; its
fail-open / fail-closed classification and the one-line reason; why `-NoProfile` matters on Windows
(measured 3.7 s → 10 ms, QA `06_TEST_REPORT.md` D-3); that the value lands inside a JSON string so the
inner `"` are already `\"`-escaped; that the space-preceded bare `.harness/scripts/<tool>.<ext>` token
must survive so step 10b / `E.4b` congruence still parses it.

**Drop** (the spec answers these): both OS byte-form strings, and the OS-detection idiom
(`$IsWindows` / the `$OSTYPE` case) — `hook-spec … hostos` replaces it.

Placeholder → tool id map for the instruction: `{{SYNC_COMMAND}}`→`harness-sync`,
`{{GUARD_COMMAND}}`→`guard-rm`, `{{AMBIENT_PROMPT_COMMAND}}`→`ambient-prompt`,
`{{AMBIENT_RESET_COMMAND}}`→`ambient-reset`.

### 6.2 The instruction the executing agent follows (transcribe verbatim)

Written **once** in `skills/harness-init/SKILL.md` step 5, immediately under the table; the
`harness-adopt` table's four rows point at it by name and restate nothing.

> **Obtaining a hook command value — invoke the spec, paste the answer.** For each of the four
> `*_COMMAND` placeholders, run the hook wiring spec twin **for the shell you are running in**, from
> the target project root (the template copy landed at `.harness/scripts/hook-spec.{sh,ps1}` in the
> earlier copy step; if you are substituting before that copy, use
> `<template-root>/skills/harness-init/templates/common/.harness/scripts/hook-spec.{sh,ps1}`):
>
> - macOS / Linux / MSYS bash — `bash .harness/scripts/hook-spec.sh command <tool> "$(bash .harness/scripts/hook-spec.sh hostos)"`
> - Windows PowerShell — `pwsh -NoProfile -File .harness/scripts/hook-spec.ps1 command <tool> (pwsh -NoProfile -File .harness/scripts/hook-spec.ps1 hostos)`
>
> where `<tool>` is the tool id named in the placeholder's row. **Never call the other shell's twin**:
> an MSYS bash capturing pwsh output through `$( … )` strips the trailing newline but leaves the `\r`,
> which corrupts the value. Paste the captured line **verbatim** into the placeholder's position — do
> not re-escape it, re-wrap it, reformat it, or add or remove a single character; it is already at the
> JSON-string escaping level the settings file needs. The same spec answers this hook's event
> (`hook-spec … event <tool>`), matcher (`matcher <tool>`) and fail-open/fail-closed classification
> (`semantics <tool>`) if you need to confirm the row.
>
> **If the spec is missing, or exits non-zero, or answers with an empty line: stop.** Leave the
> placeholder unresolved, report the failure naming the tool and the path you tried, and do **not**
> improvise a command, copy one from another project, or reconstruct one from documentation. The
> step-10b congruence assertion will flag the unresolved token, which is the correct, visible outcome.

### 6.3 The `{{NAME}}`-token constraint (B-6) — checked, not assumed

B-6 bans a literal `{{NAME}}`-form token in a **shipped script** (one copied into a generated
project), because `test-init`'s blanket placeholder scan runs over generated output. This design puts
**no such token anywhere new**:

- The two `SKILL.md` files already carry the four tokens in their tables' first column and are **not**
  copied into a generated project (top-level `skills/` is plugin-native; there is no `.harness/skills/`
  in this repo).
- `verify_all.ps1` already carries `{{GUARD_COMMAND}}` at `:301` and the D.2 allow-list at `:95`; §7's
  edit reuses the same literal and adds no new token. `verify_all.{sh,ps1}` is dogfood, not distributed.
- The two flow scripts **are** shipped, and this change strictly *reduces* their token surface: the
  run-time-assembled openers `ph_o="{{"` (`upgrade-project.sh:270` — **moved** to S3 scope by §3.6,
  text byte-identical), `$phOpen = "{" + "{"` (`upgrade-project.ps1:254`, untouched) and
  `ph_open="{{"` (`migrate-scripts-layout.sh:234`, untouched) are all retained. A bare `{{` is not a
  `{{NAME}}`-form token, which is what `test-init`'s scan looks for. The adapter introduces no token.

---

## 7. The containment fix (OQ-2(a), in scope, no new check)

### 7.1 Mechanism — a containment window, no JSON parser

`F.2` today makes two independent whole-file assertions (`verify_all.sh:313-314`,
`.ps1:301-306`). Neither says the placeholder lives *inside* the hook block. The fix scopes both to a
**containment window** over the settings template.

**Window rule (identical in both shells) — total by construction.** Let `L[0…N-1]` be the template's
lines.

1. **`start`** = the index of the first line matching the key form
   `^[[:space:]]*"PreToolUse"[[:space:]]*:` / `^[ \t]*"PreToolUse"[ \t]*:`.
   If there is none → token `no_PreToolUse_block`, and **no window is computed** (rows 4-5 are not
   evaluated; the token set for that input is exactly this one token plus whatever row 1 says).
2. **`IND`** = the leading-whitespace width of `L[start]`, counted over the character class
   `[ \t]` with each character worth 1.
3. **`term`** = the index of the first `j > start` such that `L[j]` is non-blank **and** its
   leading-whitespace width is **≤ `IND`**; if no such `j` exists, `term = N`.
4. **Window** = the inclusive range `[start, term - 1]` — the terminator line itself is **excluded**.
5. If step 3 found no `j` (`term = N`) → additional token `PreToolUse_block_unterminated`; the
   window is still `[start, N-1]` and rows 4-5 **are** evaluated over it, so the emitted token set is
   deterministic for every input.

Round 1's rule said "width **exactly** `IND`". Round 2 justified replacing it with `≤ IND` by
citing a **block-form** `"PreToolUse"` moved to be the last key inside `hooks`, asserting that
"every following line dedents to 2 (`  }`) then 0 (`}`), never back to 4". **QA measured that fixture
and falsified the assertion** (`06_TEST_REPORT.md` D-1 and §2.3): the `PreToolUse` array closes with
its **own** `    ]` line at leading width **exactly 4**, which `== IND` finds as a terminator just as
`≤ IND` does — `start=68 IND=4 term=78` under *both* rules, PASS under *both*. That fixture does not
discriminate between the two rules, so it is withdrawn as evidence here. §20 correction 3 records the
falsification; the round-2 derivation overlooked the array's own closing bracket.

**The conclusion is unchanged and now rests on evidence that measures it.** QA built the
discriminating fixture: an **inline** `"PreToolUse"` as the last key inside `hooks`, where the whole
array sits on one line at width 4 and the next non-blank line is the two-space `}`:

```
    "PreToolUse": [ { "matcher": "Bash", "hooks": [ { "type": "command", "command": "{{GUARD_COMMAND}}" } ] } ]
  }
}
=== SHIPPED rule (<= IND) ===   start=68 IND=4 term=69 unterminated=no    -> window [68,68] -> PASS
=== ROUND-1 rule (== IND) ===   start=68 IND=4 term=71 unterminated=YES   -> FAIL
=== real gate on inline-last fixture ===  EXIT=0 · [F.2] PASS · PASS: 32  WARN: 0  FAIL: 0
```

On this input `== IND` runs to EOF without ever seeing width 4 again and classifies a valid, merely
reformatted template as `PreToolUse_block_unterminated` → FAIL, turning the release gate red on
semantically correct input; `≤ IND` PASSes it. So `≤ IND` **is** strictly more total, which is the
finding round 2 made — it was right for a reason it had not measured. Totality in general still
follows from the rule's shape: for any text file, exactly one of step 1's two branches applies, and
within the second, step 3 either finds a `j` or does not.

Excluding the terminator line (step 4) is a second, independent tightening, and it too is now
measured rather than argued. QA's mutant **`M-D`** puts an empty `"PreToolUse": [],` immediately above
an inline `"PostToolUse": [ … "command": "{{GUARD_COMMAND}}" … ],` at width `IND`. The shipped
terminator-**excluded** window FAILs it with **both** `guard_command_not_in_PreToolUse` **and**
`PreToolUse_no_command_entry` (real gate 31/0/1, both tokens firing independently); a round-1-style
**inclusive** window would have pulled the sibling in and PASSed (`06_TEST_REPORT.md` §2.4). The
sibling-donation hazard is real, as claimed — but that is now a run, not an inspection.

Traced against the real template and measured against QA's fixtures (`06_TEST_REPORT.md` §2.3-2.4):

| Input | `start` | `IND` | `term` | Window | Result |
|---|---|---|---|---|---|
| today's `settings.json.tmpl` | `:48` | 4 | `:58` (`    ],`, width 4) | `[48,57]` | `"command"` at `:53`, `{{GUARD_COMMAND}}` at `:54` → **PASS** |
| M-C mutant (§7.2) | the `    "PreToolUse": [],` line | 4 | the `    "UserPromptSubmit": [` line | that one line | no `"command"`, no placeholder → **exactly 2 tokens** |
| **block-form** `PreToolUse` moved to last key inside `hooks` | `:68` | 4 | `:78` (the array's own `    ]`, width 4) | `[68,77]` | **PASS — and round 1's `== IND` also PASSes.** Non-discriminating; round 2 wrongly reported it as a round-1 FAIL (§20 correction 3) |
| **inline** `PreToolUse` as last key inside `hooks` (QA-authored) | `:68` | 4 | `:69` (the two-space `}`, width 2) | `[68,68]` | **PASS**; round 1's `== IND` → `term = N` → `PreToolUse_block_unterminated` → **FAIL**. This is the discriminating case |
| `M-D` sibling-donation mutant (QA-authored) | the `    "PreToolUse": [],` line | 4 | the inline `    "PostToolUse": …` line (excluded) | that one line | **FAIL, exactly 2 tokens**, 31/0/1; a round-1 *inclusive* window would have PASSed |

Assertions inside `F.2` (all accumulate into the existing `f2_problems` / `$problems` list; no
`step`/`Step` call is added):

| Condition | Problem token |
|---|---|
| file carries no `{{GUARD_COMMAND}}` anywhere | `no_GUARD_COMMAND_placeholder` *(retained — distinguishes "absent" from "misplaced")* |
| no `"PreToolUse"` key form (rule step 1) | `no_PreToolUse_block` *(retained; rows 4-5 not evaluated)* |
| key found but no dedent-or-equal line before EOF (rule step 5) | `PreToolUse_block_unterminated` *(new)* |
| window carries no `{{GUARD_COMMAND}}` | `guard_command_not_in_PreToolUse` *(new)* |
| window carries no `"command"` key form | `PreToolUse_no_command_entry` *(new)* |

An undelimitable window is a **FAIL, not a skip**: after the repair, "unterminated" can only mean the
file has no line at or below the key's indent after it — i.e. a truncated or non-JSON file, which
must be re-examined by a human, never waved through.

**Bash**: one `awk` pass emitting the window, `exit 2` from `END` when no key form was found and
`exit 3` when no terminator was found (both after printing whatever the window is); capture `$?`
explicitly (`verify_all.sh:3` is `set -uo pipefail`, no `-e`, so a non-zero command substitution does
not abort) and test the window text with `grep -q`. Width is `match($0, /^[ \t]*/); w = RLENGTH`.
**PowerShell**: split on `` "`r?`n" ``, find `start` with `-cmatch '^[ \t]*"PreToolUse"[ \t]*:'`,
take widths with `[regex]::Match($line, '^[ \t]*').Length`, then
`(($lines[$start..$end]) -join "`n")` — **parenthesised, and not adjacent to any `+`** (the `-join`
precedence trap). `$end ≥ $start` always holds (step 3's smallest `j` is `start+1`, so the smallest
`end` is `start`), which matters because PowerShell's `..` **reverses** when the right bound is the
smaller — a silent wrong-window bug rather than an error.

Measure indentation with an explicit `[ \t]` class in **both** shells, never PowerShell's `\s`, whose
Unicode-whitespace breadth would make the two shells measure different widths (T-15 already records
this deviation class; this design adds no new instance of it).

**Recorded measurement edge (F-3 secondary, record-only).** With `[ \t]`, a tab counts as width 1 in
both shells — consistent cross-shell, but a template that mixes tabs and spaces at the same nesting
depth would mis-measure the dedent and could pick the wrong terminator. Not designed for: the file is
this repo's own tracked template, is space-indented throughout, and any reformatting of it is a
deliberate edit whose gate result must be re-read anyway. Recorded here so a future reformatter knows
the assumption exists; it is **not** a residual that needs closing.

**Check count: 32, unchanged.** `F.2` remains exactly one `step "F.2" …` call in bash and exactly one
`Step "F.2" …` in PowerShell, on mutually exclusive branches. `baseline.json:verify_all_checks` stays
`32` and every documented "32" literal is frozen (§10).

### 7.2 The mutation QA will use (AC-7), and the anti-vacuity direction

**Mutation M-C**, applied to `skills/harness-init/templates/common/.claude/settings.json.tmpl` after
copying it to `settings.json.tmpl.t16bak` (a suffix ending in neither `.tmpl` nor `.append`, so D.2
does not scan the backup):

1. `:43` — `"command": "{{SYNC_COMMAND}}"` → `"command": "{{GUARD_COMMAND}}"` (the guard placeholder
   now sits inside the **`Stop`** block).
2. `:48-58` — the whole `PreToolUse` block → the single line `    "PreToolUse": [],` (the array is
   empty; the **key and the `hooks` container both survive**).

**Containment audit before predicting a token count** (the T-15 lesson: a mutation that deletes a
container falsifies every assertion whose evidence lives inside it). The deleted range `:48-58`
contains exactly one piece of `F.2` evidence — the `{{GUARD_COMMAND}}` at `:54` — and step 1
deliberately **relocates it rather than losing it**. The four guard-script assertions read the
filesystem, not this file. So:

- **Post-change gate on M-C**: `F.2` **FAIL** with **exactly two** tokens —
  `…settings.json.tmpl:guard_command_not_in_PreToolUse` and
  `…settings.json.tmpl:PreToolUse_no_command_entry`. Not `no_GUARD_COMMAND_placeholder` (the
  placeholder is present in the file) and not `no_PreToolUse_block` (the key is present) — that
  contrast *is* the presence-vs-containment proof. Whole-gate prediction: **PASS 31 / WARN 0 / FAIL 1**.
- **Anti-vacuity direction**: the **pre-change** `verify_all.sh` run against the *same* mutated
  template must report `F.2` **PASS**. **The pre-change artifact is an S0 capture of the working
  tree, never `git show HEAD:` (F-2).** On this tree HEAD is `cb0ed57` = **v0.44.0**:
  `hook-spec.sh` does not exist at HEAD (T-13 created it at v0.45.0), and `verify_all.sh:290`'s
  `F.2` carries T-15's `(v0.15+; narrowed T-15)` key-form anchoring which HEAD predates. Running
  `HEAD:verify_all.sh` would measure a check two tasks older than the one T-16 modifies — a green
  claim about the wrong artifact. Method:

  | Step | Command / act | Recorded in `04_DEVELOPMENT.md` |
  |---|---|---|
  | S0, **before the first write of this task** | `cp .harness/scripts/verify_all.sh $W/verify_all.s0.sh` | `sha256sum` of both, and `stat -c '%Y %n'` of the live file |
  | S0 | note `T0` = wall-clock of this task's first write | the S0 mtime must be `< T0` |
  | at proof time | `cp $W/verify_all.s0.sh .harness/scripts/verify_all.s0.sh` — it must live **two levels below the repo root**, because it derives `repo_root` from `dirname "$0"/../..` and `cd`s there (`verify_all.sh:5-7`) | — |
  | at proof time | apply M-C, run `bash .harness/scripts/verify_all.s0.sh`, grep the `[F.2]` line, expect **PASS** | the one `[F.2]` line |
  | immediately after | `rm .harness/scripts/verify_all.s0.sh` | the deletion, so the file never enters `git status` at S-final or any commit |

  Two properties make the capture *provably* the pre-change state: (a) its `sha256sum` equals the
  S0 table's hash for the live file and its S0 mtime is `< T0` (§13's own method, reused rather than
  restated); and (b) at proof time the **live** `verify_all.sh` hashes **differently** — if it did
  not, the "pre-change" copy would be the post-change file and the direction would be vacuous. Both
  are asserted, not assumed. Only the `[F.2]` line of that run is load-bearing; the rest of the
  pre-change gate may legitimately be red on a mid-change tree.

  For the record, the direction is real: the gate reviewer hand-traced the *current*
  `verify_all.sh:313-314` over M-C — `grep -q '{{GUARD_COMMAND}}'` hits the relocated placeholder at
  `:43` and `grep -qE '"PreToolUse"[[:space:]]*:'` hits the mutated `    "PreToolUse": [],` line, so
  `F.2` PASSes pre-change. The S0 run turns that trace into a measurement.
- **Unmutated post-change gate**: `F.2` **PASS**, 32/0/0. Revert M-C from the `.t16bak` copy and
  delete the backup before any other driver runs.
- **Collateral checks under M-C** (predicted PASS, verified not asserted): `D.2` — both tokens are in
  its allow-list and it never *requires* a token; `J.1` — the file is still valid JSON and
  `PreToolUse` is still a valid event name.

---

## 8. The circularity repair (OQ-1(b))

**The problem.** `test-init.sh:771` extracts the live `resilient_cmd` from `upgrade-project.sh` by
`awk` range + `eval` and Group A (`:776-785`) compares the spec against it. The AST-based PowerShell
twin (`test-init.ps1:892-907`) has the identical shape.

**The pre-repair symptom, corrected (F-8).** Round 1 wrote both "tautological, and **still green**"
and "the probe would go red" two sentences apart. Only the second is true, and the gate traced why:
`test-init.sh:771`'s `awk` range is `/^resilient_cmd\(\) \{$/` … first `^}$`, so what gets `eval`ed
after the change is the *delegating* body, which calls `hsa_command` — undefined in the driver's
scope. `$probe` comes back empty, the probe at `:773-774` goes **red**, and Group A's `$b` is empty
so all **8 Group A rows go red too**. The failure is **loud (9 red rows), not silent-green**. In
PowerShell the shape is the same with a different mechanism: `Get-ResilientCmd` is *retired*
(§3.1 D-5), so `$fnAst` is `$null`, the function is never dot-sourced, `Get-ResilientCmd` throws,
`catch` sets `$oracleProbe = ''`, and the same 9 rows go red. QA must predict **9 loud red rows**
before the repair, not a green tautology. The tautology risk is real but only in the *counterfactual*
where the extraction still succeeded — which is exactly why the repair re-anchors the oracle rather
than patching the extraction. (`R-3` in §16 is corrected to match.)

**The repair (count-neutral: 17 T-16-affected rows in, 17 out, in both shells).** The block also
owns `[T-13] hook-spec.sh present` (`sh:767` / `ps1:890`), which is untouched and not counted here.

| Block | Today | After |
|---|---|---|
| Anti-vacuity probe (1 row) | extract `resilient_cmd` / `Get-ResilientCmd`, call it, assert non-empty and names `guard-rm.ps1` | delete the extraction (`sh:771`, `ps1:892-898`); probe the **frozen fixture** instead — `hs_expected guard-rm windows` / `Get-HookFixture guard-rm windows` must be non-empty and contain `guard-rm.ps1`. Label: `[T-16][oracle] ANTI-VACUITY: the frozen EXP_* fixture (guard-rm, windows) is a non-empty string naming guard-rm.ps1` |
| Group A (8 rows) | spec vs. **live helper** | spec vs. **frozen `EXP_*` / `$exp*` literal** — exactly OQ-1's prescription. Label: `[T-16][A] command <tool> <os> is byte-equal to the FROZEN test-init fixture (independent of every flow)` |
| Group A′ (8 rows) | spec vs. frozen literal (byte-identical to Group A after the repair — zero marginal power) | **re-purposed into two standing 4-row scans over the four `.harness/scripts/` flow files** (§14 D-2, and the F-6 answer): 4 rows of *idiom* scan + 4 rows of *substitution-discipline* scan. See below. |

**Group A′ after the repair — 4 + 4 rows.**

| Rows | Assertion | Label |
|---|---|---|
| 4 (one per flow file) | zero hits, on **non-comment** lines, of either byte-form idiom `Set-Location -LiteralPath` (the Windows shape's marker) or `CLAUDE_PROJECT_DIR` (the unix shape's marker) — the standing AC-3 regression | `[T-16][A'] <flow-file> carries no hook-command byte-form idiom outside comments` |
| 4 (one per flow file) | zero hits, on **non-comment** lines, of the shell's non-literal substitution operator: for `*.sh`, any `${…//…}` / `${…/…/…}` form including the `${arr[i]//}` and `${!ref//}` variants; for `*.ps1`, `-replace` — the standing §4 `&`-hazard regression, which was a one-time developer grep in round 1 | `[T-16][A'] <flow-file> uses no pattern-substitution operator (& / patsub hazard)` |

Both scans are green on the **pre-change** tree, so they are regressions rather than fixes:
`Set-Location -LiteralPath` / `CLAUDE_PROJECT_DIR` appear on non-comment lines today only inside the
`resilient_cmd` / `Get-ResilientCmd` bodies this change deletes (`upgrade-project.sh:106,108,112,114`
/ `.ps1:115,117,121,123`, `migrate-scripts-layout.sh:121,123,127,129` / `.ps1:39,41,45,47`);
`${var//` occurs only on `upgrade-project.sh:120` and `migrate-scripts-layout.sh:135`, both comment
lines; `-replace` occurs in neither `.ps1`. The legacy brittle needles the flows still build
(`pwsh -NoProfile -File .harness/scripts/…`, `bash .harness/scripts/…`, `upgrade-project.sh:332,335`)
match no scan and are explicitly out of scope (`01 §4.3`). Comment lines are excluded because a
comment can neither emit a command nor perform a substitution, and because the flows' *documentation*
legitimately names `$CLAUDE_PROJECT_DIR` and `${var//pat/repl}` when explaining the anchor and the
hazard.

**Structural note for the PowerShell twin.** In `test-init.ps1` Groups A, A′ and C are interleaved in
one per-cell loop (`:909-936`). The A′ `Assert` is **removed from that loop** and the 8 new rows are
added as a separate block after it. The loop then carries 2 Asserts × 8 cells; the block carries 8.
Total unchanged. In bash A′ is already its own loop (`sh:788-795`) and is replaced in place.

Groups B / C / D / E (`test-init.sh:797-855`) are **untouched**: they exercise the spec's own
semantics, congruence-ERE compatibility, event/matcher contract and totality, none of which this task
changes.

**Artifacts that deliberately retain literals, and why.**

| Artifact | Why retained |
|---|---|
| `test-init.{sh,ps1}` `EXP_*` / `$exp*` (8 cells) | A test must not derive its expectation from the artifact under test. These are now the **only** independent anchor for all four flows. |
| `test-real-project.{sh,ps1}` (8 cells, `sh:46-59`) | Same reason, plus this is a **fixture-authoring** site: it *builds* the fixture's final settings, so it must state the expected bytes, not ask the artifact it is testing. Omitted from the T-13 header; named now (OQ-6(b)). |
| `test-harness-upgrade.{sh,ps1}` `t20_pick` (`sh:296,306`) | The **live flow-vs-frozen-literal** anchor — `sh:421` asserts the settings the upgrade flow actually wrote contains this literal. It is what keeps end-to-end byte-identity falsifiable after Group A stops testing the flow — for **one** `(tool, OS, flow)` cell only; the other seven and the `migrate` flow are residual **RES-1** (§16.1, F-6). |
| `test-harness-upgrade.{sh,ps1}` raw-shell probes (`sh:555`), `test-guard-rm.*`, `evals/guard-rm-cases.md` | A **different escaping level** the spec deliberately does not emit (OQ-7(b)); and the guard cases are guard *input data*, not a wiring copy. |
| `test-init.ps1:701-702` un-escaped resilient forms | A **third** escaping level (post-`ConvertFrom-Json`), also not emitted by the spec. |

All of the above are recorded as deliberate in the corrected spec header (§9) and appended to
`.harness/rejected-decisions.md` as `hook-byteform-test-literal-retirement`, together with
`hook-spec-raw-query` (OQ-7(b), deferred with its reason).

---

## 9. Change ledger

Twin pairs: **edit the `templates/common/` source, then propagate with
`bash .harness/scripts/sync-self.sh`** (B-8). `sync-self` Mappings **6** (migrate), **7** (upgrade)
and **9** (hook-spec) already cover every twin in this task — **no mapping is added, changed, or
removed**; `sync-self.{sh,ps1}` is itself **frozen**.

| # | File | Change | Pair / mirror |
|---|---|---|---|
| 1 | `skills/harness-init/templates/common/.harness/scripts/upgrade-project.sh` | adapter §3.3 in place of `resilient_cmd` (**retired**, §3.1 D-5); S3.0 gate reorder + `hostos`; **`ph_o`/`ph_c` hoisted to S3 scope (§3.6 F-4)**; S3.0/S3.2 failure branches §5; comment rewrite | source → #2 (Mapping 7) |
| 2 | `.harness/scripts/upgrade-project.sh` | mirror | ← #1 |
| 3 | `…/templates/common/.harness/scripts/upgrade-project.ps1` | adapter §3.4, same set, **minus** the `ph_o` hoist (`$phOpen` is already at S3 scope, `.ps1:254`); `$IsWindows` reads at `:278,286` → `$hsIsWin`/`$hsOs` (§3.5 F-9) | source → #4 (Mapping 7) |
| 4 | `.harness/scripts/upgrade-project.ps1` | mirror | ← #3 |
| 5 | `…/templates/common/.harness/scripts/migrate-scripts-layout.sh` | adapter §3.3 in place of `resilient_cmd` (retired); `s32_win` → `s32_os`; `SPEC-GAP` branch §5 | source → #6 (Mapping 6) |
| 6 | `.harness/scripts/migrate-scripts-layout.sh` | mirror | ← #5 |
| 7 | `…/templates/common/.harness/scripts/migrate-scripts-layout.ps1` | adapter §3.4, same set | source → #8 (Mapping 6) |
| 8 | `.harness/scripts/migrate-scripts-layout.ps1` | mirror | ← #7 |
| 9 | `…/templates/common/.harness/scripts/hook-spec.sh` | **header/comments only**: (a) T-16 hand-off list `:39-52` → corrected inventory §9.1; (b) the **provenance sentences** at `:8-10` and `:97-98` — "transcribed VERBATIM from the canonical derivation helper (upgrade-project.sh `resilient_cmd`)" / "Transcribed verbatim from upgrade-project.sh:104-116" — re-worded, because that helper no longer exists after this task (found in round 2; round 1's ledger row said "T-16 hand-off list" only) | source → #10 (Mapping 9) |
| 10 | `.harness/scripts/hook-spec.sh` | mirror | ← #9 |
| 11 | `…/templates/common/.harness/scripts/hook-spec.ps1` | same two edits, `:38-51` and `:7-9` | source → #12 (Mapping 9) |
| 12 | `.harness/scripts/hook-spec.ps1` | mirror | ← #11 |
| 13 | `.harness/scripts/verify_all.sh` | `F.2` containment window §7.1 | **not twinned** (dogfood gate; the type-template `verify_all.*.tmpl` has no `F.2` equivalent — its `E.4b` checks a *generated project's* settings and is untouched) |
| 14 | `.harness/scripts/verify_all.ps1` | `F.2` containment window §7.1 | not twinned |
| 15 | `.harness/scripts/test-init.sh` | oracle re-anchor + A′ re-purpose + SCOPE-NOTE rewrite (`:750-760`) §8 | mirror-of-record #16 |
| 16 | `.harness/scripts/test-init.ps1` | same (`:872-881`), plus the A′ `Assert` lifted out of the per-cell loop §8; **plus** the stale comment at `:700` ("matches `Get-ResilientCmd`'s output") re-pointed at the spec — comment only, no assertion moves | ← #15 |
| 17 | `.harness/scripts/test-real-project.sh` | **comment only** (`:40-45`): label the literals a deliberate frozen oracle, cite the corrected spec header | mirror-of-record #18 |
| 18 | `.harness/scripts/test-real-project.ps1` | same | ← #17 |
| 19 | `skills/harness-init/SKILL.md` | step-5 table rows `:187-190` §6.1 + the instruction §6.2 | no sync (plugin-native `skills/`) |
| 20 | `skills/harness-adopt/SKILL.md` | table rows `:311-314` → semantics + pointer to #19's instruction | no sync |
| 21 | `AI-GUIDE.md` | `:110` last sentence → §10.1 L1 | — |
| 22 | `docs/getting-started.md` | `:180-182` → §10.1 L2 | — |
| 23 | `.harness/rules/60-tool-handoff.md` | `:72-75` location clause → §10.1 L3 | — |
| 24 | `.harness/rejected-decisions.md` | append two records (§8) | — |
| 25 | `.harness/scripts/baseline.json` | append `_qa_note_t16` **only** — the operator PS items §12. **Every numeric key byte-frozen.** | — |
| 26 | `CONTEXT.md` | append **Spec adapter** and **Containment window** (§14 D-3) | — |
| 27 | `CHANGELOG.md` | 0.46.0 entry | — |
| 28 | `docs/tasks.md` | delivery row (stage 7) | — |

**Explicitly not changed** (and asserted so by §13): `sync-self.{sh,ps1}`;
`test-harness-upgrade.{sh,ps1}`; `test-guard-rm.{sh,ps1}`; `evals/guard-rm-cases.md`;
`guard-rm.{sh,ps1}` + both template twins; `.harness/rules/75-safety-hook.md` (200/200 — **not
touched, so no condensing and no before/after count is required**; if a later round finds it must be
touched, condense first and record the count before and after); `settings.json.tmpl` (M-C is reverted);
`.claude/**`; `CLAUDE.md`; `.github/copilot-instructions.md`;
`docs/proposals/frontier-gaps-2026-07.md`.

### 9.1 The corrected spec header (both twins, identical text)

Replaces `hook-spec.sh:39-52` / `.ps1:38-51`. Structure:

1. **Retired by T-16** — `upgrade-project.{sh,ps1}` and `migrate-scripts-layout.{sh,ps1}` now query
   this spec; the two `SKILL.md` tables now instruct the agent to query it. No byte-form copy remains
   in any derivation flow.
2. **Deliberately retained, with the reason** — the five rows of §8's retention table, each with its
   one-line rationale, and each labelled a *decision*, not an oversight. `test-real-project.{sh,ps1}`
   is named explicitly (it was omitted from the T-13 list).
3. **Not a wiring copy** — `test-guard-rm.{sh,ps1}` and `evals/guard-rm-cases.md` carry the raw unix
   guard command as guard *input data*.
4. **Follow-up, not a gap** — a `raw` command query (OQ-7(b)) is deferred and recorded in
   `.harness/rejected-decisions.md`; retiring the raw-level consumers needs it designed first.

No line/column citations for the retired sites (they no longer exist); citations retained only for the
frozen-literal sites, where they are still true.

---

## 10. Prose consumers (OQ-5: (b) plus one clause of (c))

### 10.1 The three replacement sentences — transcribe, do not compose

**L1 — `AI-GUIDE.md:110`.** Replace the final sentence "The Stop hook in `.claude/settings.json` does
this automatically at session end." with:

> A Stop hook runs `harness-sync` automatically at session end; a project generated by `/harness-init`
> ships that hook in its committed `.claude/settings.json`, while this repo keeps its own wiring
> machine-local — `/harness-status` §0 "Effective hook source" reports which file a given project
> actually loads it from.

**L2 — `docs/getting-started.md:180-182`.** Replace "The Stop hook in `.claude/settings.json` runs
`harness-sync` automatically at session end, so this rarely bites you in Claude Code." with:

> A Stop hook runs `harness-sync` automatically at session end, so this rarely bites you in Claude
> Code. A project generated by `/harness-init` ships that hook in its committed
> `.claude/settings.json`; harness-kit's own checkout keeps its wiring machine-local — run
> `/harness-status` §0 "Effective hook source" if you need to know which file a given project loads
> it from.

**L3 — `.harness/rules/60-tool-handoff.md:72-75`.** Replace "The Stop hook in
`.claude/settings.json` auto-runs …" with (keeping the trailing clause verbatim — it is pre-existing
and **not** in this task's scope to "improve"):

> A Stop hook auto-runs `.harness/scripts/harness-sync` at session end, so `.harness/` edits flow to
> `CLAUDE.md` + `.github/copilot-instructions.md` without user intervention. A generated project ships
> that hook in its committed `.claude/settings.json`; this repo keeps its own machine-local, and
> `/harness-status` §0 "Effective hook source" reports which file a given project loads it from.

`60-tool-handoff.md:87`'s "The Stop hook above is **Claude-Code-specific**" stays — it makes no
location claim.

### 10.2 Size caps — checked per file before the edit, not after

| File | `verify_all` cap | Current | After | Head-room |
|---|---|---|---|---|
| `AI-GUIDE.md` | `I.1`, 200 lines | **113** | 113 (in-line sentence swap) | 87 |
| `.harness/rules/60-tool-handoff.md` | `I.2`, 200 lines each | **128** (round 1 said 129 — corrected, gate measurement confirmed by re-reading the file's tail) | ≤130 | ≥70 |
| `docs/getting-started.md` | **none** (`I.*` does not cover `docs/*.md`) | 200+ | +1…2 | n/a |
| `.harness/rules/75-safety-hook.md` | `I.2`, 200 lines | **200/200** | **untouched** | 0 — do not edit |

`verify_all` exits 1 on `warns > 0`, so an `I.*` WARN is a hard release-gate failure, not advisory.

### 10.3 Two gate interactions on the edited lines — verified, not assumed

- **`I.6` retired-claim guard.** The banned entry `.harness/~→~CLAUDE.md` (`verify_all.sh:529`) is
  line-scoped and excluded by `.claude/`. L3 contains no `→` character; L1/L2 contain no banned anchor
  sequence. No new `I.6` hit is created.
- **`G.4` pinned literals.** None of the three edited lines carries a `(32 checks` / `32/32` literal.
  `AI-GUIDE.md:42` and `:74` are untouched.

---

## 11. Byte-identity proof plan (AC-2) — pre-change captures, mechanical comparison

**Rule 1: a post-change flow compared against the spec is circular and is not accepted.** Every
comparison below has a *pre-change artifact* on one side.

**Rule 2 (round 2, F-2): "pre-change" always means an S0 capture of the working tree, never
`git show HEAD:`.** HEAD on this tree is `cb0ed57` = v0.44.0 and is several tasks stale — it predates
`hook-spec.{sh,ps1}` entirely. Round 1 used `git show HEAD:` in C-1, C-3, C-4 and §7.2 on an
assumption ("those files have not moved since T-12") that it never stated or tested, and that §13
explicitly forbids inheriting. **Every** pre-change capture in this task is therefore taken at S0,
before the first write, into the scratch directory, with `sha256sum` + `stat -c '%Y %n'` recorded
alongside; a capture is admissible as "pre-change" only if its hash matches the S0 table and its S0
mtime is `< T0`. As a cheap corroboration (not a proof), the developer also records
`git diff --stat HEAD -- <each captured path>` at S0: it documents *how far* HEAD is from the
pre-change state instead of assuming the distance is zero.

**Where the captures live.** In the session scratch directory
(`/tmp/claude-*/…/scratchpad/t16-captures/`), not in `docs/features/`, because `archive-task` moves
only `0[1-7]_*.md` + `PM_LOG.md` and any other file under the task directory would be orphaned.
`04_DEVELOPMENT.md` records the exact commands, the comparison results, and — under an explicit
evidence budget of **≤20 pasted lines total** (`70-doc-size.md` rule 1) — the 8-row TSV for **one**
flow verbatim, with the remaining comparisons recorded as `diff … → 0 differing lines`.

**C-1 · bash flows, pre-change values (8 cells each).** At S0, `cp` the working-tree
`upgrade-project.sh` and `migrate-scripts-layout.sh` to `$W/<name>.s0.sh` (hash + mtime recorded per
Rule 2); extract `resilient_cmd` from the S0 copies with the same `awk`-range + `eval` technique the
pre-change `test-init.sh:771` uses; print `<tool>\t<os>\t<value>` for all 8 cells →
`pre-<flow>.tsv`.

**C-2 · bash flows, post-change emitted values.** Build fixture `fx-8cell`: a project root with the
eight empty files `.harness/scripts/{harness-sync,guard-rm,ambient-prompt,ambient-reset}.{sh,ps1}` and
a `.claude/settings.json` whose single `Stop` hooks array carries **eight** `"command"` entries, one
per `(tool, ext)`, each holding the *brittle* form the flows match on. Run the post-change flow on it
(apply mode), then extract each `"command"` value from the written file and compare against `pre-<flow>.tsv`
with `diff`. Expect **0 differing lines**, 8/8, for each flow. A second fixture `fx-tokens` carries the
four `{{…}}` tokens and exercises `upgrade-project` S3.0 against the host-OS rows of the TSV.

**C-3 · PowerShell flows (unexecutable here — proved at the source-literal level).** For
`upgrade-project.ps1:115-123` and `migrate-scripts-layout.ps1:39-47`, extract the four `return (…)`
expressions from the **S0 captures** of those files, and the four from the S0 capture of
`hook-spec.ps1:102-110`; strip leading whitespace and `diff` them pairwise. Expect **0 differing
lines** — the pre-change flow literal and the spec literal are the same text at S0, so post-change
delegation cannot move a byte. Store as `pre-ps-literal-diff.txt`. This is a mechanical,
non-circular comparison (the spec is a *pre-existing* artifact this task does not rewrite below its
header). It is **not** a run; the run is operator items 12(b)/13(b) (§12).

**C-4 · prose flows.** From the **S0 capture** of `skills/harness-init/SKILL.md` extract the eight
byte-forms in rows `:187-190`; resolve the presentation escaping per B-4 (strip the enclosing
backticks; `\|` → `|`) and `diff` against `hook-spec.sh command <tool> <os>` for all 8 cells. Expect
**0 differing lines**. `harness-adopt` defers its bytes to `harness-init` (`:311`), so it has no
independent capture. (Round 1 sourced this from `git show HEAD:` — at HEAD the spec side of the
comparison does not even exist, so the command as written could not have run.)

**C-5 · AC-1, single source by construction.** Mutate one byte in **both** spec twins (e.g.
`guard-rm.sh` → `guard-rm.sh ` inside the unix guard shape), re-run all four flows against the
fixtures, confirm all four emit the mutated value with **zero** edits to any flow, then revert both
twins and re-run `sync-self --check` (expect "In sync.") before the final gate.

**C-6 · AC-4, measured not argued.** For each flow × each OS variant, extract the emitted `guard-rm`
command and assert it contains neither `|| exit 0` nor a trailing `exit 0`; then, on a fixture with
`.harness/scripts/guard-rm.sh` **deleted**, execute the emitted **unix** command and assert a
non-zero exit. **The Windows runtime half of AC-4 is not executable here and is therefore an operator
obligation, not a stage-4 one** — §12 items 12(f) and 13(e) (F-11).

**C-7 · the `&` / substitution mechanical check (§4), widened (F-10).** Over the **non-comment**
lines of the four flow files:

- `*.sh`: `grep -nE '\$\{[!#]?[A-Za-z_][A-Za-z0-9_]*(\[[^]]*\])?/'` → expect **0** hits. Round 1's
  pattern `'${[A-Za-z_][A-Za-z0-9_]*//'` missed `${arr[i]//…}`, `${!ref//…}` and the single-replace
  `${var/…/…}`, all of which carry the same `&` rule — i.e. the check was narrower than the §4
  mandate it enforces.
- `*.ps1`: `grep -n -- '-replace'` → expect **0** hits (PowerShell's regex-replacement half
  interprets `$&`/`$1`; `.Replace()` is the mandated ordinal form).

C-7 is a one-time developer capture **and** is promoted to a standing regression by §8's Group A′
second scan, so a later reintroduction reddens a named test row rather than escaping notice.

---

## 12. Operator PowerShell list

No `.ps1` in this change set is executable by any agent here, so **no `.ps1` may be described as
verified**.

**The arithmetic, restated correctly (F-7).** Round 1 said "eleven items … the eight T-13, ten T-17
and one T-15 items are untouched", which reads as 19 members of an 11-item list. Two different
things were conflated:

| Register | Members | Where it lives |
|---|---|---|
| The **numbered** standing operator PowerShell list | **11** items: **10** from T-17 `guard-cmd-chain` (items 1-10, with **3** and **10** marked *security*) + **1** from T-15 `hook-truth-verify-scope` (item 11) | `_archived/guard-cmd-chain/07_DELIVERY.md:115-116`; `_archived/hook-truth-verify-scope/07_DELIVERY.md:122` |
| **Un-numbered** operator obligations from T-13 | **8** items, written as prose | `baseline.json:_qa_note_t13` |

So: 11 numbered + 8 un-numbered = **19 standing operator obligations**, of which the *numbered list*
holds 11 and carries 2 security marks. This task appends **five numbered items (12-16)**, taking the
numbered list to **16** and the total to **24**; items **12** and **13** are **security-relevant**
(they are the code paths that emit the fail-closed guard command), taking the security-marked count
in the numbered list to **four**. Nothing in the 19 is retired, reconciled or renumbered. `01 AC-10`
keys on the numbered-list figure: **11 → 16**. The list is mirrored into
`baseline.json:_qa_note_t16` (the artifact that travels).

> **12. `upgrade-project.ps1` (T-16) — SECURITY-RELEVANT.**
> (a) `pwsh -NoProfile -c "[System.Management.Automation.Language.Parser]::ParseFile('.harness/scripts/upgrade-project.ps1',[ref]$null,[ref]$null)"` and the same for
> `skills/harness-init/templates/common/.harness/scripts/upgrade-project.ps1`.
> (b) In a scratch clone, on the `fx-8cell` fixture: `pwsh -File .harness/scripts/upgrade-project.ps1 -TemplateRoot <abs> -Type generic`; confirm all eight `"command"` values in the written `.claude/settings.json` equal the `pre-upgrade-project.tsv` rows byte-for-byte, and that the `guard-rm` values carry no `exit 0`.
> (c) Repeat on `fx-tokens` (placeholder repair) and confirm the four `RESULT|REWIRE-PLACEHOLDER` lines.
> (d) Delete `hook-spec.ps1` from the template root, the script's sibling directory and the project, re-run (b): confirm **no** settings write, the four `GAP|hook-spec|absent|…` records naming `not found` as the path, and exit **4** from the terminal congruence scan on the token fixture. Then repeat with the spec present but its `hostos` query broken (edit the scratch copy's `hostos` branch to `exit 2`): confirm the single "host OS undeterminable" `GAP|` record, all four tokens still present, and **exit 4** — *not* exit 1 (this is the `$phOpen`-binding branch of §3.6 F-4; the bash twin is the one that could have exited 1, but the branch must be exercised in both shells). Re-run each: identical output, no `.bak` churn.
> (e) Confirm no new identifier collides with a read-only automatic variable — specifically that the host-OS boolean is `$hsIsWin` and that `$IsWindows` no longer appears at `:278`/`:286`; and that `Get-ResilientCmd` is **gone** from the file.
> (f) **AC-4, Windows runtime half (F-11).** In the `fx-8cell` scratch clone after (b), extract the `PreToolUse` `"command"` value from the settings file the **flow wrote**, then: with `.harness/scripts/guard-rm.ps1` present, pipe `{"tool_input":{"command":"rm -rf C:\\Windows"}}` into it and confirm a **non-zero** exit; delete `guard-rm.ps1` and repeat, confirming a **non-zero** exit again (fail-CLOSED). Corroborating precedent, not a substitute: the frozen `test-harness-upgrade.ps1:599-608` Fixture Z already runs exactly this present/benign/absent triple on a **transcribed** literal — (f) is the same probe on the **flow-emitted** value, which is what `01 AC-4` asks for.

> **13. `migrate-scripts-layout.ps1` (T-16) — SECURITY-RELEVANT.**
> (a) `[Parser]::ParseFile` over both copies. (b) `pwsh -File … migrate-scripts-layout.ps1` on `fx-8cell`; same eight-value byte comparison. (c) Spec removed: confirm the `SPEC-GAP` plan lines naming `not found`, **exit 0**, no `.bak`, and that a second run is identical. (d) Confirm `Get-ResilientCmd` is gone and that the adapter block sits where it sat (`:31-50`) without reading `$dstDir` at load time — i.e. the script still runs to completion when invoked from a directory with no `.harness/scripts/`. (e) **AC-4, Windows runtime half** — as item 12(f), on the settings file this flow wrote.

> **14. `verify_all.ps1` `F.2` containment (T-16).**
> (a) `[Parser]::ParseFile`. (b) `pwsh -File .harness/scripts/verify_all.ps1` → **PASS 32 / WARN 0 / FAIL 0**; confirm the `[F.2]` line and that check count is 32. (c) Apply mutation **M-C** (§7.2) and confirm `F.2` FAILs with **exactly** `guard_command_not_in_PreToolUse` and `PreToolUse_no_command_entry` in one accumulated message (this is also the `-join`-precedence check); revert from `.t16bak`. (d) Confirm `[F.2]` never prints `WARN` — a WARN here means a statement leaked to the pipeline, and WARN exits 1. (e) **The F-3 totality case**: in a scratch copy of `settings.json.tmpl`, move the whole `"PreToolUse"` block so it is the **last** key inside `hooks`, and confirm `[F.2]` still reports **PASS**. The PS half is the one whose `..` range operator silently reverses if `$end < $start` (it cannot: the smallest terminator is `$start+1`) — that, not rule discrimination, is what this probe is for. *(Round-3 record correction, §20 correction 3: round 2 annotated this item "the round-1 rule would have FAILed here". QA measured it and the round-1 `== IND` rule PASSes this fixture too — the array's own `    ]` sits at width 4. The obligation is unchanged in kind and in count; only the false rationale clause is struck. `baseline.json:_qa_note_t16` — the artifact the operator actually reads — never carried the struck clause, so no divergence is created.)*

> **15. `test-init.ps1` (T-16).**
> (a) `[Parser]::ParseFile`. (b) `pwsh -File .harness/scripts/test-init.ps1`; confirm the driver reaches its `=== Result ===` line and reports **316**, unchanged. (c) Confirm the `[T-16][oracle]`, `[T-16][A]` (×8) and `[T-16][A']` (×8 — now 4 idiom rows + 4 substitution-discipline rows) are green and that no row still names `Get-ResilientCmd`; confirm the A′ block sits **outside** the per-cell loop (that loop must carry 2 `Assert`s per cell, not 3) so the total is unchanged. (d) Reconcile `test_init_ps_assertions` and the README `test-init` badge **together**, and only if this run moves the number.

> **16. Parse-only sweep (T-16).** `[Parser]::ParseFile` over `.harness/scripts/hook-spec.ps1`,
> `.harness/scripts/test-real-project.ps1` and both `templates/common/` `hook-spec.ps1` /
> `migrate-scripts-layout.ps1` / `upgrade-project.ps1` copies, then
> `pwsh -File .harness/scripts/test-real-project.ps1` → **90**, unchanged.

---

## 13. Freeze method (B-11 / AC-11)

Absence from `git diff --name-only` is **not** a freeze proof on this tree — sibling work may leave
files already dirty, and a dirty-set difference is blind to a content edit inside an
already-dirty file. The claim is carried by the **difference plus per-file mtime ordering**:

- **S0, before the first write of this task**: capture `git status --porcelain`, `git diff --name-only`,
  and `stat -c '%Y %n'` for every path in the frozen set below. Record the wall-clock timestamp of the
  task's **first write** (`T0`).
- **S-final**: re-capture all three. A frozen path passes iff (a) it is **not** in
  `post-dirty ∖ pre-dirty`, **and** (b) its mtime is **unchanged** from the S0 table, **and** (c) its
  mtime is **< T0**. Any path failing (b) or (c) is a violation regardless of (a).

**Frozen set**: `.harness/scripts/guard-rm.{sh,ps1}` + both `templates/common/` twins ·
`evals/guard-rm-cases.md` · `.harness/scripts/test-guard-rm.{sh,ps1}` ·
`.harness/rules/75-safety-hook.md` · `docs/proposals/frontier-gaps-2026-07.md` · `.claude/**` ·
`CLAUDE.md` · `.github/copilot-instructions.md` · `.harness/scripts/sync-self.{sh,ps1}` ·
`.harness/scripts/test-harness-upgrade.{sh,ps1}` · every **numeric** key in `baseline.json` (content
check, since `_qa_note_t16` is appended to that file) · the four README badges.

The git-status snapshot taken at this session's start reported a **clean** tree, which contradicts the
requirement's B-11 premise. The developer **re-derives S0 at task start** rather than adopting either
claim.

---

## 14. Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| Query the hook wiring spec from bash, with rc + emptiness discipline | Step-5 block, `if ! v="$(bash "$spec" …)"` + empty check | `.harness/scripts/install-hooks.sh:164-199` | **Reuse the pattern**, adapted from `set -e` to `set -uo` (§3.3) |
| Query the spec from PowerShell, try/catch + `$LASTEXITCODE` | `Invoke-HookSpec` | `.harness/scripts/install-hooks.ps1:190-199` | **Reuse the shape** verbatim; add memoisation and the `@($out)\|Select -First 1` guard |
| Literal replace-all immune to `patsub_replacement` | `str_replace_all` | `upgrade-project.sh:124-131`, `migrate-scripts-layout.sh:138-145` | **Reuse as-is; mandated for every spec-derived substitution** |
| Ordinal literal replace (PowerShell) | `String.Replace` | `upgrade-project.ps1:288,339`, `migrate-scripts-layout.ps1:169` | Reuse as-is (already ordinal) |
| Diagnostic record type for "cannot do this step" | `GAP\|<id>\|absent\|<detail>` | `upgrade-project.sh:206`, `.ps1:207,29` | **Reuse; no new record type** |
| Terminal end-state ownership of the exit code | congruence scan, re-reads from **disk** in apply mode | `upgrade-project.sh:597-635`, `migrate-scripts-layout.sh:215-263` | Reuse untouched. Both siblings already carry the correct disk re-read (the 2026-06-11 divergence is fixed); audited as a **pair**, as that insight requires |
| Twin propagation | Mappings 6 / 7 / 9 | `.harness/scripts/sync-self.sh:78-93` | Reuse; **no mapping added** |
| Frozen 8-cell expectation table | `EXP_*` / `hs_expected`, `$exp*` / `Get-HookFixture` | `test-init.sh:53-74`, `test-init.ps1:40-60` | Reuse as the re-anchored oracle (§8) |
| Live flow-vs-frozen-literal end-to-end anchor | `t20_pick` + `sh:421` | `test-harness-upgrade.sh:288-309,421` | Reuse untouched — this is why retiring Group A's live-oracle role is safe |
| Anti-vacuity by running the **pre-change** script against the mutated artifact | T-15's technique | `_archived/hook-truth-verify-scope/06_TEST_REPORT.md` | Reuse the **technique**; **reject its `git show HEAD:` sourcing** — on this tree HEAD is v0.44.0 and predates both T-13 and T-15 (F-2). The artifact is an S0 working-tree capture (§7.2, §11 Rule 2) |
| Freeze evidence (hash + mtime vs `T0`) as the proof that a capture is pre-change | §13's own S0 method | this document, §13 | Reuse for §7.2 / §11 rather than inventing a second provenance rule |
| Native-exit-code opt-out around a spec call in PowerShell | `$PSNativeCommandUseErrorActionPreference = $false` in function scope | `test-init.ps1:885-888` | Reuse verbatim in `Invoke-HookSpecCached` (§3.4 hazard 5) |
| Empty-array-safe iteration under `set -u` on bash 3.2 | `(( ${#plan[@]} == 0 ))` / `${#cong_lines[@]}` guards | `migrate-scripts-layout.sh:266,273,277` | Reuse the discipline; the adapter goes one step further and uses an explicit counter with a C-style loop, so no array is ever `[@]`-expanded (§3.3, F-5) |
| Accumulating problem list in `F.2` (both shells) | `f2_problems` / `$problems` | `verify_all.sh:301-322`, `.ps1:287-311` | Extend with three tokens; **no new `step`/`Step` call** |
| Containment window over JSON without a parser | (none found) | — | New, justified: the repo has no JSON parser in either gate shell (`install-hooks.sh:54-94` deliberately hand-rolls a structural probe for the same reason — no `jq`, no `python3` on MSYS) |
| A new dependency (library / service) | — | — | **None added.** Pure local shell, offline (NFR-4) |

**Autonomous decisions logged (Mode 2).**

- **D-1 — `hostos` is taken from the spec (§3.6).** Not literally required by `01 §3` (which binds
  byte-forms, event, matcher and semantics), but it is the same duplication class: both flows computed
  a host-OS discriminator the spec also owns. Cost: one extra invocation and one extra failure path,
  both fail-closed. **Revert is 3 lines per shell and moves no byte-form** if the Gate objects.
  **Justification corrected in round 3 (§20 corrections 1-2).** Rounds 1-2 supported D-1 by quoting
  `hook-spec`'s own provenance comment — "the exact discrimination the existing derivation flows
  already use". That support was wrong twice: (a) it was **false for the PowerShell twin**, whose
  discrimination is *wider* than the retired `if ($IsWindows)` and changes host-OS selection on
  Windows PowerShell 5.1 (§3.6); and (b) after code-review round 2 the quoted sentence exists in
  **no shipped file** — all four `hook-spec` copies were reworded, and quoting a comment that this
  task itself edited was circular support in any case. D-1 **stands**: it is justified by the measured
  duplication in the pre-change flows, not by the spec's self-description.
- **D-2 — Group A′ is re-purposed rather than left a duplicate (§8).** OQ-1(b) is adopted verbatim for
  Group A; its unstated consequence is that A′ (already spec-vs-literal) becomes byte-identical to A —
  8 rows carrying zero marginal power. Re-purposing A′ to two 4-row standing scans (idiom + pattern
  substitution) keeps the T-16-affected row count **exactly 17 in both shells** (so the frozen PS pin
  316 and the bash pin 355 both hold — round 1 said "16", an arithmetic slip: 1 probe + 8 + 8 = 17)
  and converts two one-time developer greps into standing regressions. This adds no `verify_all`
  check.
- **D-3 — two `CONTEXT.md` terms are coined**: **Spec adapter** (the per-flow module that resolves,
  invokes, memoises and refuses) and **Containment window** (the `PreToolUse` byte range `F.2` scopes
  its assertions to). Both are used throughout this design; recording them keeps naming canonical.
- **D-4 — `baseline.json` gains `_qa_note_t16`** (operator items only, no numeric key touched),
  following T-13's precedent that the operator list must travel on the artifact the operator reads.
- **D-5 (round 2) — `resilient_cmd` / `Get-ResilientCmd` are retired, not retained (§3.1).** Round 1
  kept them as three-line wrappers "so both call sites are untouched". That premise did not survive
  the round-1 review: every call site has to grow a failure branch (§5), the bash sites have to stop
  using `$( … )` (§3.3), and the PS site at `.ps1:286` passes the read-only automatic `$IsWindows`
  positionally (F-9). A wrapper whose only remaining job is `true → "windows"` fails the deletion
  test. Retiring it makes AC-3 trivially true, removes F-9 at the root, and removes the last
  hand-maintained name in the byte-form path. **Cost**: two extra edited lines per loop (`s32_win` →
  `s32_os`) and two stale comment sentences in `hook-spec.{sh,ps1}` that now need rewording (ledger
  rows 9-12). **Revert cost if the Gate objects**: re-add a 3-line wrapper per shell; no byte-form
  moves either way.
- **D-6 (round 2) — the bash adapter uses an out-variable, not stdout (§3.1, §3.3).** Forced, not
  preferred: a `$( … )` capture forks a subshell and discards the cache, which would make each run
  spawn the spec 13 times against NFR-1's ceiling of 9. PowerShell keeps a normal return value
  because its function calls are in-process. Logged because it is the one deliberate cross-shell
  idiom asymmetry in this design.
- **D-7 (round 2) — F-6's coverage gap is answered by raising standing coverage *and* naming a
  residual, not by unfreezing `test-harness-upgrade`.** See §16 R-11.
- **Checked against `.harness/rejected-decisions.md`**: `verify-gate-machine-hook-assertion` declines a
  *machine-state* hook assertion in the gate. §7 stays entirely inside **tracked content** (the settings
  template) and reads **no** settings file, so it does not re-open that decision.

---

## 15. Count ledger

| Number | Where | Current | Moves? |
|---|---|---|---|
| `verify_all` check count | `baseline.json:10`; README badge `verify__all-32/32`; `AI-GUIDE.md:42,74`; `.harness/rules/40-locations.md:29`; `CONTRIBUTING.md:22`; `README.zh-CN.md`; `docs/manual-e2e-test.md`; `docs/dev-map.md` | **32** | **No** — hard constraint; `F.2` stays one check |
| `test_init_bash_no_python3_assertions` | `baseline.json:12` | **355** | **No** — §8 is 17-rows-in / 17-rows-out (1 probe + 8 Group A + 8 Group A′; round 1 wrote "16") |
| `test_init_ps_assertions` | `baseline.json:11` | **316** | **No** — frozen; moves only with operator item 15 |
| README `test-init` badge | `README.md:5` | **316/316** | **No** — moves only together with the row above |
| `test_real_project_{ps,bash}_assertions` | `baseline.json:13-14` | **90 / 90** | **No** — comment-only edit (#17/#18) |
| README `integration` badge | `README.md:5` | **90/90** | **No** |
| `test_harness_upgrade_{ps,bash}_assertions` | `baseline.json:19-20` | **89 / 89** | **No** — file untouched; emitted bytes unchanged, so its assertions stay green |
| `test_guard_rm_bash_assertions` | `baseline.json:23` | **87** | **No** — guard frozen |
| `test_supervisor_*`, `test_verify_i6_*`, `test_language_*` | `baseline.json:15-18,21-22` | 49/45, 58/58, 39/39 | **No** |
| `AI-GUIDE.md` length (`I.1` ≤200) | — | **113** | 113 |
| `60-tool-handoff.md` length (`I.2` ≤200) | — | **128** | ≤130 |
| `75-safety-hook.md` length (`I.2` ≤200) | — | **200/200** | **untouched** |
| `insight-index.md` evidence lines (`I.4` ≤30) | `.harness/insight-index.md:9-38` | **30 — at the cap** | stage-7 `archive-task` rotates; **each new insight must be ONE physical line** (the harvester truncates wrapped bullets and that defect is out of scope) |
| Operator PowerShell **numbered** list | §12 + `baseline.json:_qa_note_t16` | **11** (2 security) = 10 T-17 + 1 T-15 | **→ 16** (4 security) |
| Operator PowerShell **un-numbered** obligations (T-13 prose) | `baseline.json:_qa_note_t13` | **8** | **No** — untouched, unreconciled |
| Total standing operator obligations | both rows above | **19** | **→ 24** |
| Version stamp | `README.md:5`, `CHANGELOG.md` | 0.46.0 | **No** — fold into the unreleased 0.46.0 |

**Reconciliation rule (OQ-8(b)).** If any bash count moves, it is transcribed from a **pasted real
run**, never derived arithmetically, and a driver that terminates without its summary line is a
failure, not a pass. PowerShell pins and both README PS badges stay **frozen** and move only together,
with the operator's run.

---

## 16. Risk analysis

| # | Risk | Mitigation |
|---|---|---|
| R-1 | **`&` corruption re-introduced in bash.** A developer adds `${settings_new//$needle/$cmd}` "for clarity"; the Windows guard's `& pwsh` expands to the matched text and ships invalid hook JSON. Invisible to every PowerShell check. | §4 mandates `str_replace_all` at every site; §11 C-7 is a mechanical `grep` over non-comment lines expecting 0 hits; the adapter performs no substitution at all, making the hazard unreachable rather than handled. |
| R-2 | **PowerShell ships broken three ways an agent cannot see** — whole-file parse failure from a never-taken adapter branch; an identifier colliding with a read-only automatic; `[string]$array` space-joining a multi-line answer. | §3.4 names all five hazards as implementation mandates; §12 items 12-16 make `[Parser]::ParseFile` + a real run a release gate; nothing is described as verified. |
| R-3 | **The oracle stops measuring anything.** Corrected in round 2 (F-8): with the *current* extraction mechanism the symptom is **loud** — the extracted delegation calls `hsa_command`, which is undefined in the driver, so the probe **and** all 8 Group A rows go red (9 rows). The insidious variant — a tautological spec-vs-spec comparison that stays **green** — is what the design would have shipped had the extraction been made to keep working, and it is the reason the repair re-anchors rather than patches. | §8 re-anchors Group A to the frozen literals and re-purposes A′; the anti-vacuity probe moves onto the fixture so a broken fixture reddens a *named* row instead of silently degrading eight. QA's pre-repair prediction is **9 loud red rows**, not a green tautology (§8). |
| R-4 | **Incomplete ledger — a missed lockstep surface** (this repo's #1 gate failure; the T-13 header itself missed two files). | §9 enumerates 28 rows including both `test-real-project` twins, all six twin pairs and their sync-self mappings, and an explicit not-changed list; §13's freeze method proves the not-changed list rather than asserting it. |
| R-5 | **The containment mutation's token count is mis-predicted** because a deleted container also deletes the evidence inside it (T-15 shipped that mis-prediction twice through the gate). | §7.2 performs the containment audit **before** predicting, and the mutation deliberately **relocates** `{{GUARD_COMMAND}}` instead of deleting it — which is exactly what makes the two-token prediction sound and the presence-vs-containment contrast visible. |
| R-6 | **A guard command is written after a partial spec answer.** | The adapter has no third return path (§3.1); B-3 resolves to "do not write" in every branch; §11 C-6 measures it on both OS variants and with the guard script absent. |
| R-7 | **A cap breach turns into a hard gate failure** — `verify_all` exits 1 on `warns > 0`. | §10.2 checks each file's cap **before** the edit; `75-safety-hook.md` (200/200) is out of the edit set entirely. |
| R-8 | **The layout-migration flow runs where the spec never existed** (its most likely deployment). | §5's per-tool skip leaves the existing value, records `SPEC-GAP`, exits 0 and stays idempotent — a partially repairable project does not become unrepairable (OQ-3(b) over (a)). |
| R-9 | **`sync-self` twin drift** — a fix landed in the dogfood copy only. | Every edit is made at the `templates/common/` source and propagated by `sync-self`; the final gate run includes `sync-self --check` → "In sync." |
| R-10 | **Freeze claim unprovable on a dirty tree.** | §13's difference **plus** mtime ordering against `T0`; S0 is re-derived at task start rather than inherited from either the requirement's premise or the session snapshot, which disagree. |
| R-11 | **Standing end-to-end byte coverage of the flows drops from 8 cells to 1** (F-6). After the change the only standing assertion comparing a *flow-emitted* byte string with an *independent* literal is `test-harness-upgrade.sh:421` vs `t20_pick` — one tool, one OS, one flow; `migrate-scripts-layout` keeps none at all (its strongest standing check is `contains 'CLAUDE_PROJECT_DIR'`, `sh:510`). The uncovered failure is an adapter that *post-processes* the captured value: a stray `printf "$v"`, a re-added trailing newline, a `-join`. | Partly closed, partly named. **Closed**: §8's re-purposed Group A′ adds 8 standing rows that pin the two ends of the chain (no byte-form literal survives; no pattern substitution touches the value) in both shells at zero row cost; §11 C-2/C-3 cover all 8 cells for both flows one-time on bash and at the literal level for PS; §12 items 12(b)/13(b) require the operator to compare all 8 cells on Windows. **Named**: the remaining gap is a *standing* 8-cell end-to-end comparison, recorded as residual **RES-1** below. |

### 16.1 Named residuals — these must reach `07_DELIVERY.md`

**RES-1 — no standing 8-cell flow-emitted byte assertion.** Scope: `test-harness-upgrade.{sh,ps1}`
asserts one `(tool, OS, flow)` cell (`sh:421` vs `t20_pick`); `migrate-scripts-layout` asserts none.
Why it is not closed in this task (**D-7**): closing it means adding assertions to
`test-harness-upgrade.{sh,ps1}`, which (a) leaves this task's frozen set — the design and the gate
both rely on that file being untouched as the *independent* anchor that makes retiring Group A's
live-oracle role safe; (b) moves `test_harness_upgrade_bash_assertions` (89, reconcilable from a
captured run) **and** `test_harness_upgrade_ps_assertions` (89, **not** reconcilable here — pwsh is
agent-unexecutable, so the PS pin would ship stale by construction, the phantom-count trap
`baseline.json:_qa_note_t17` names); and (c) writing new PS assertions no agent can run into a
currently-green driver is the exact hazard `insight-index.md:20` records. The residual risk is
narrow because the composition argument holds — post-change flow bytes ≡ spec bytes by construction,
and Group A pins the spec against frozen literals — and both ends of that composition are now
standing (Group A′). **Follow-up shape**: extend `test-harness-upgrade`'s T20/M2 fixtures to assert
all four host-OS cells per flow, in one task that can also schedule the operator PS run that
reconciles the PS pin.

---

## 17. Out-of-scope clarifications

This design does **not** cover, and the developer must not opportunistically do:

1. Any change to guard behaviour, the destructive-verb set, or `guard-rm.{sh,ps1}`.
2. Retiring the raw-escaping-level forms or adding a `raw` spec query (OQ-7(b) — recorded as a
   follow-up in `.harness/rejected-decisions.md`).
3. Retiring the legacy brittle needles the repair flows search for — legacy *input*, not emitted output.
4. The `archive-task` wrapped-bullet truncation defect (worked **around** in §15, not fixed).
5. T-17's residual bypass surface and its chunked-indexing follow-up.
6. `docs/proposals/frontier-gaps-2026-07.md` — not read as a requirement source, not edited, not committed.
7. Adding a fifth hook tool, or changing any tool's event or matcher. (T-13 residual 2 stands: the
   installer's distinct-events gate assumes exactly four tools. Unchanged here.)
8. Reconciling the PowerShell assertion baseline or the README PS badges from a claimed run.
9. Adding a `verify_all` check, a script, or a state file (NFR-2). The check count is 32, flat.
10. "Improving while in there": `.harness/rules/75-safety-hook.md:150-151`,
    `.harness/rules/40-locations.md:41`, and `60-tool-handoff.md`'s pre-existing
    `.harness/`→`CLAUDE.md` clause are all knowingly left as they are.
11. Closing **RES-1** (§16.1) — the standing 8-cell flow-emitted byte assertion. Named as a residual
    that travels to `07_DELIVERY.md`; `test-harness-upgrade.{sh,ps1}` stays frozen in this task.

---

## 18. Round 2 — gate findings resolution

`03_GATE_REVIEW.md` round 1 returned **CHANGES REQUIRED** with eleven findings, all routed here.
Each is answered below: what changed, where, and why the fix is correct. Nothing is folded in
silently. The gate's positive verifications (ledger completeness, `&`-hazard unreachability,
fail-closed preservation, M-C's prediction, the cap measurements, the freeze adjudication, scope
discipline) are preserved unchanged and are **not** re-litigated.

### F-1 · MAJOR · adapter placement vs. the variables its resolution order reads — **fixed**

**What was wrong.** §3.1's only ordering constraint ("after argument parsing so `$TEMPLATE_ROOT` is
bound") did not cover `dst_dir` / `$dstDir`, which the candidate list also reads, and §3.3/§3.4 put
the candidate loop at **top level**. I re-measured the binding order myself rather than inheriting
the gate's table, and it is right in every cell: `upgrade-project.sh` helper `:102` vs `dst_dir`
`:150`; `upgrade-project.ps1` helper `:112` vs `$dstDir` `:147`; `migrate-scripts-layout.ps1` helper
`:36` vs `$dstDir` `:56` (with `$root` at `:53`); only `migrate-scripts-layout.sh` (`:117` vs `:40`)
was safe.

**What changed.** §3.1 (new ordering clause), §3.2 (new measured table + the lazy rule), §3.3
(`hsa_resolve`), §3.4 (`Resolve-HookSpecPath`). Candidate resolution is now **lazy** — it happens
inside the resolver on the first *query*, which in all four files occurs after every binding
(`sh:282` / `ps1:286` / `sh:193` / `ps1:168`). The adapter block therefore sits exactly where the
retired helper sits and **no binding order changes in any file**.

**Why it is correct.** It removes the constraint instead of satisfying it, so a future re-ordering
of either flow cannot resurrect the defect. Defensive expansion is used anyway: `${dst_dir:-}` in
bash, `if ($dstDir)` in PowerShell — the latter is safe because this repo sets `Set-StrictMode`
nowhere (verified by repo-wide search), so an undefined variable is `$null` and the candidate is
skipped rather than fed to `Join-Path`, which is what would have raised the terminating error. The
PS side is specified completely: `Resolve-HookSpecPath`, `Get-HookSpecPathForMessage`,
`Invoke-HookSpecCached`, `Get-HookSpecCommand`, `Get-HookSpecHostOs`, plus the `$script:` scoping
mandate and the `$PSNativeCommandUseErrorActionPreference` opt-out modelled on
`test-init.ps1:885-888`.

**Two things I found while fixing it, which the gate did not flag** (both now in the design):
(a) the bash cache would have been **silently discarded** because every call site captures through
`$( … )`, which forks a subshell — 13 spawns per run against NFR-1's ceiling of 9; hence the
out-variable convention (D-6); (b) with a failure branch required at every call site anyway, the
`resilient_cmd` / `Get-ResilientCmd` wrapper became a pass-through, so it is **retired** (D-5) —
which also dissolves F-9 at the root.

### F-2 · MAJOR (FAIL) · AC-7's anti-vacuity direction measures the wrong artifact — **fixed**

**Agreed without reservation.** HEAD is `cb0ed57` = v0.44.0; `hook-spec.sh` does not exist there and
`verify_all.sh:290`'s `F.2` carries T-15's `narrowed T-15` key-form anchoring, which HEAD predates.
`git show HEAD:verify_all.sh` measures a check two tasks older than the one T-16 modifies.

**What changed.** §7.2's anti-vacuity method is respecified on an **S0 capture of the working tree**:
copy taken before the first write, `sha256sum` + `stat -c '%Y %n'` recorded in the S0 table,
admissible only if the hash matches the S0 table and the S0 mtime is `< T0`; plus the converse check
that the **live** file hashes *differently* at proof time, so the "pre-change" copy cannot silently
be the post-change file. The copy is placed at `.harness/scripts/verify_all.s0.sh` (two levels below
the repo root — `verify_all.sh:5-7` derives `repo_root` from `dirname "$0"/../..` and `cd`s there),
run against M-C, its `[F.2]` line captured, then deleted so it never appears in `git status` at
S-final or in a commit.

**The two other `git show HEAD:` sites, re-examined as instructed.** The gate guessed C-1 and C-4
were "probably safe". I did not keep the guess. C-4 is in fact **impossible as written**: it diffs
the SKILL.md byte-forms against `hook-spec.sh command …`, and at HEAD `hook-spec.sh` does not exist,
so one side of that comparison is empty. C-1 and C-3 are *plausible* but rest on exactly the untested
tree-state assumption §13 forbids inheriting. All of them are therefore moved onto the same S0
footing by a single rule at the head of §11 (**Rule 2**), which is stronger than patching them
individually: *no* pre-change claim in this task is derived from `git show HEAD:`. As a cheap
corroboration the developer records `git diff --stat HEAD -- <path>` at S0 — documenting the distance
from HEAD instead of assuming it is zero.

### F-3 · MAJOR · the containment-window terminator rule is non-total — **fixed**

**Agreed.** With "width **exactly** `IND`", a template whose `"PreToolUse"` key is the *last* key
inside `hooks` has no following line at width 4 (they dedent 4 → 2 → 0), so the rule matched zero
lines and the design classified a valid template as `PreToolUse_block_unterminated` → FAIL.

> **[Round-3 record correction — §20 correction 3.]** The two sentences above and the "reordered
> template (PASS, where round 1 gave FAIL)" clause below are **false as written for the block form**.
> QA measured it: a *block-form* `"PreToolUse"` moved to last position still dedents 4 → **4** (its
> own `    ]`) → 2 → 0, so `== IND` finds a terminator and PASSes. The finding itself survives — QA
> built the *inline*-last-key fixture, on which `== IND` really does reach EOF and FAIL — so F-3's
> conclusion and the shipped `≤ IND` rule are unaffected. Only the cited case was wrong. The corrected
> evidence is in §7.1.

**What changed.** §7.1's rule is restated as five numbered steps over `L[0…N-1]`: the terminator is
the first non-blank line with leading width **≤ `IND`**, `term = N` when there is none, and the
window is `[start, term-1]` — the terminator line **excluded**. Totality is now explicit: step 1
branches two ways, step 3 either finds a `j` or does not, and on the `term = N` branch the window is
`[start, N-1]` and the two window assertions **are** still evaluated, so the emitted token set is
deterministic for every possible input. A three-row verification table records the outcome on
today's template (`[48,57]`, PASS), on the M-C mutant (exactly 2 tokens — unchanged from round 1) and
on the reordered template (PASS, where round 1 gave FAIL). Excluding the terminator line is a second,
independent tightening the gate did not ask for: it prevents an inline *sibling* event at width `IND`
from satisfying `PreToolUse_no_command_entry` with evidence that is not `PreToolUse`'s. The
tab/space measurement edge is recorded verbatim as record-only, with the reason it is not designed
for. Operator item 14(e) adds the reordered-template probe on the PS side, where `..` would silently
reverse if `$end < $start` (it cannot: the smallest `end` is `start`, stated in §7.1).

**Re-audit of every other table in this document, as `insight-index.md:26` requires.** I confirm the
gate's readings of §5 (total; I additionally wrote the quantification out — 4+1+8+8 cells — and
state that resolution itself is total), §3.5 (total; I re-derived the call-site set myself and
**extended** the table by the two PS `$IsWindows` reads the gate found under F-9, so round 1's table
was total over `resilient_cmd` call sites but **not** over host-OS reads), §7.1 (was non-total only
via the window rule; now fixed), and §15/§14/§8 (enumerations, complete — though §15's
`test_init_bash` row and §12's operator arithmetic both carried wrong *numbers*, fixed under F-7).
Two tables the gate did not name: §9's ledger (enumeration; the gate re-derived it independently and
found it complete — I added the `hook-spec.{sh,ps1}` provenance-sentence edit it does not cover,
which is a *completeness* gain, not a totality failure) and §10.2's cap table (enumeration; the
`60-tool-handoff.md` figure was wrong, fixed under the gate's cap measurement).

### F-4 · MEDIUM · the `hostos` skip leaves `ph_o` unbound — **fixed, with one narrowing disagreement**

**Agreed on the bash half, and it is worse than "a wrong exit code":** `ph_o="{{"` is declared at
`upgrade-project.sh:270` inside S3.0 and read at `:607` by the terminal congruence scan, so
"skip S3.0 in its entirety" leaves it unbound under `set -uo pipefail` → **exit 1, no `SUMMARY|`
line**, and the terminal assertion loses the exit-code ownership `01 B-1` gives it, while §5 row 2
predicts exit 4.

**What changed.** §3.6 gains an explicit skip-boundary subsection: (1) hoist `ph_o`/`ph_c` out of
S3.0 to S3 scope, immediately after `settings_new=""` (`:249`) and before the
`if [[ ! -f "$settings" ]]` branch; (2) "skip S3.0" is redefined to mean *skip the four-iteration
placeholder loop* (`sh:275-287`), not the step's declarations. §5 row 2 and ledger row 1 are updated
to match. Operator item 12(d) now exercises the branch on the PS side too.

**Where I disagree with the gate, narrowly.** The finding says "the PS twin has the same shape
(`$phOpen` at `.ps1:254`)". It does not: `.ps1:254-255` sits at **S3 scope**, outside S3.0 and
outside the `if (-not (Test-Path $settings))` branch, so the PS twin is already correct and would
not have been broken by round 1's wording. This makes the finding *narrower*, not wrong — the bash
defect is exactly as described — and it improves the fix: the hoist is not an invention but an
alignment of bash onto the PS twin's existing placement, so the edit **removes** a cross-shell
asymmetry. Recorded because a developer told "fix both shells" would otherwise move a correct line.

### F-5 · MEDIUM · the cache loop breaks the bash-3.2 compatibility it was justified by — **fixed**

**Agreed.** `for i in "${!hs_keys[@]}"` over an empty array is an unbound-variable error under
`set -u` on bash < 4.4, including the macOS 3.2 the parallel-array choice exists for; the dev host is
5.2, so it would have shipped green and failed only on a user's Mac running `/harness-upgrade`.

**What changed.** §3.3's cache loop is a **C-style loop over an explicit counter** (`hsa_n`), so no
array is ever `[@]`- or `${!…[@]}`-expanded at all — strictly stronger than adding a count guard, and
it removes the failure mode rather than gating it. The same hazard in the resolver is closed the same
way: `cands` gets its sibling-candidate element **unconditionally**, so `"${cands[@]}"` is never an
empty-array expansion. The surrounding precedent (`migrate-scripts-layout.sh:266,273,277`) is now
cited in the reuse audit.

### F-6 · MEDIUM · standing flow-byte coverage drops 8 cells → 1, unrecorded — **both, and stated**

**Agreed on the measurement.** After the change the only standing flow-emitted-vs-independent-literal
assertion is `test-harness-upgrade.sh:421` vs `t20_pick` (one tool, one OS, one flow), and
`migrate-scripts-layout` keeps none. §11 C-2 covers all 8 cells for both flows but is a one-time
capture.

**Choice made: raise standing coverage *and* name a residual.** (i) **Raised** — §8's Group A′ is
re-shaped from 8 zero-value rows into two standing 4-row scans, one per flow file: no byte-form idiom
survives on a non-comment line (the AC-3 regression), and no pattern-substitution operator appears on
a non-comment line (the §4 `&`-hazard regression, `${…//…}` and friends in `.sh`, `-replace` in
`.ps1`). Both are green on the pre-change tree — measured, not assumed:
`Set-Location -LiteralPath` / `CLAUDE_PROJECT_DIR` occur on non-comment lines today only inside the
bodies this change deletes, `${var//` occurs only at `upgrade-project.sh:120` and
`migrate-scripts-layout.sh:135` (both comments), `-replace` occurs in neither `.ps1`. Cost: **zero**
new `verify_all` checks (count stays 32), **zero** pin movement (17 rows in, 17 out, both shells),
and it converts C-7 from a one-time grep into a regression. This pins both ends of the composition
argument the gate itself accepted. (ii) **Named** — the part not closed (a standing *8-cell
end-to-end* comparison) is residual **RES-1** in the new §16.1, with R-11 in the risk table and
§17.11 in the out-of-scope list, so it reaches `07_DELIVERY.md` by three routes.

**Why not close it fully.** Closing it means adding assertions to `test-harness-upgrade.{sh,ps1}`,
which leaves the frozen set the whole design leans on, and moves `test_harness_upgrade_ps_assertions`
— a pin no agent here can reconcile, which would ship stale by construction (the phantom-count trap
`baseline.json:_qa_note_t17` names) while injecting unrunnable PS into a green driver
(`insight-index.md:20`). Logged as D-7 with the follow-up's shape.

### F-7 · MINOR · operator-list arithmetic is internally inconsistent — **fixed**

The 11 vs 19 confusion came from conflating two registers. §12 now states them separately in a table:
the **numbered** standing list is 11 items (10 from T-17, items 3 and 10 security-marked; 1 from
T-15), and T-13's **8** obligations live as prose in `baseline.json:_qa_note_t13` and were never
members of the numbered list. Totals: 11 numbered + 8 un-numbered = **19** today → this task appends
items 12-16, giving **16** numbered (4 security) and **24** total. `01 AC-10` keys on the numbered
figure: **11 → 16**. §15 gains three ledger rows so the two registers can never be re-merged by a
later reader. In the same count-hygiene sweep: §8/§14 D-2/§15's "16 rows" corrected to **17**
(1 probe + 8 + 8, verified against `test-init.sh:774,776-785,788-795`), and §10.2/§15's
`60-tool-handoff.md` length corrected **129 → 128** (the gate's measurement, confirmed by reading the
file's tail).

### F-8 · MINOR · §8 self-contradicts on the pre-repair symptom — **fixed**

Agreed, and the gate's trace is right: `test-init.sh:771`'s awk range ends at the first `^}$`, so the
extracted body is the delegation, which calls an undefined `hsa_command`; `$probe` is empty, the
probe at `:773-774` goes red, and Group A's `$b` is empty so all 8 rows go red. §8 now states the
symptom once — **9 loud red rows, not a green tautology** — and explains the PS twin's equivalent
(with `Get-ResilientCmd` retired, `$fnAst` is `$null`, the call throws, `catch` empties the probe,
same 9 rows). `R-3` is rewritten to match, keeping the tautology as the *counterfactual* that
motivates re-anchoring rather than patching the extraction.

### F-9 · MINOR · "both call sites keep their present shape" is false for the PS twin — **fixed at the root**

Agreed: `upgrade-project.ps1:286` passes the read-only automatic `$IsWindows` positionally, and
`:278` reads it too, so §3.6 changes both. Rather than patch the wrapper's argument, the wrapper is
**retired** (D-5): the OS token is computed once (`$hsOs` / `$hsIsWin`, never `$isWindows` — T-12
shipped that collision) and passed to `Get-HookSpecCommand` directly. §3.5's table is extended with
both PS `$IsWindows` rows, and §3.1's over-claim is replaced by a precise statement of what changes.
`Get-HookSpecHostOs` — named in round 1's interface and never defined — is now defined in §3.4, and
the unused `$hsCacheOk` array the gate also spotted is deleted rather than left dangling.

### F-10 · MINOR · C-7's grep is narrower than the §4 mandate — **fixed**

Agreed. §4's mandate is widened explicitly to `${var//…}`, `${arr[i]//…}`, `${arr[@]//…}`,
`${!ref//…}` **and** the single-replace `${var/…/…}`, all of which carry the same `&` rule; §11 C-7's
pattern becomes `\$\{[!#]?[A-Za-z_][A-Za-z0-9_]*(\[[^]]*\])?/`, which matches all five shapes. A PS
half is added (`-replace`, whose replacement string interprets `$&`/`$1` — the analogous hazard),
measured at zero occurrences today. And the check is promoted from a one-time capture to a standing
Group A′ row (F-6), so the mandate and its enforcement now have the same width *and* the same
lifetime.

### F-11 · MINOR · AC-4's Windows runtime half is unowned — **fixed**

Agreed: §11 C-6 executes only the unix variant and §12 asked only for a string inspection on Windows.
The Windows runtime half is now operator items **12(f)** and **13(e)**, with the exact probe:
extract the `PreToolUse` `"command"` value from the settings file **the flow wrote**, pipe a
destructive payload into it with `guard-rm.ps1` present (expect non-zero), then delete `guard-rm.ps1`
and repeat (expect non-zero — fail-CLOSED). §11 C-6 now says explicitly that the Windows half is an
operator obligation, not a stage-4 one. The gate's pointer to `test-harness-upgrade.ps1:599-608`
(Fixture Z) is cited as **corroborating precedent, not a substitute**: Fixture Z runs the same
present/benign/absent triple on a *transcribed* literal, whereas `01 AC-4` asks for a *flow-written*
settings file.

---

## 19. Verdict

**READY** — implementable as specified by a single Developer, with no further design decisions
required. All eleven round-1 findings are resolved in place (§18), one of them with a narrowing
disagreement argued from the file (F-4's PS half). Eight `Recommended:` answers from
`01_REQUIREMENT_ANALYSIS.md` remain adopted verbatim; that document is unedited. Seven autonomous
calls are logged in §14 (D-1 … D-7), each with its revert cost. One residual (**RES-1**, §16.1) is
named and routed to `07_DELIVERY.md`. Check count stays **32**; no `verify_all` check, script or
state file is added; `guard-rm`'s fail-closed semantics are untouched on every branch. No
human-reserved point arose.

**This verdict is unchanged by round 3.** §20 corrects three statements in this document after a
shipped, code-review-APPROVED and QA-PASSed implementation. No design decision, mechanism or
acceptance criterion moved.

---

## 20. Round 3 — post-implementation record corrections

**Status of this section.** Stages 4-6 are complete: `05_CODE_REVIEW.md` round 2 (the operative
section) returned **APPROVED** — 0 CRITICAL, 0 MAJOR — and `06_TEST_REPORT.md` returned **PASS WITH
DEFECTS**, 0 blocking. Both routed three items to this agent explicitly as **record only, no rework**.

**What this section is not.** No design decision, mechanism, interface, degradation branch, window
rule, ledger row or acceptance criterion is changed. No code is touched and none is proposed. The
`verify_all` check count is and stays **32**; no pinned count moves; the frozen set (`guard-rm.*`,
`test-guard-rm.*`, `test-harness-upgrade.*`, `.harness/rules/75-safety-hook.md` at 200/200,
`docs/proposals/frontier-gaps-2026-07.md`) is untouched, uncited as a source, and uncommitted. The
only edited artifact is this document.

**PowerShell honesty is unchanged.** Nothing in this section describes any `.ps1` as verified. pwsh is
agent-unexecutable on this host; the PowerShell claims below are read from shipped source and from
the code reviewer's reading, never from a run. **Operator items 14(a), 15(a) and 16 must still be
re-run against the round-2 bytes** — round 3 edits no `.ps1` and therefore neither discharges nor adds
to that obligation.

| # | Correction | Routed by | Where it was false | Where it is now true |
|---|---|---|---|---|
| 1 | D-1's justification asserted a host-OS discrimination identical in both shells; it is one-sided | code review round 1, MINOR #2 | §3.6 ¶1, §14 D-1 | §3.6 (bash/PS split), §14 D-1 |
| 2 | D-1's supporting **quotation** and its citation both dangle after the round-2 fix | code review round 2, MINOR #2 addendum | `02:369-370` (pre-edit) | quotation withdrawn (§3.6, §14 D-1) |
| 3 | The `≤ IND` totality evidence does not discriminate between the two rules | QA, D-1 | §7.1 ¶ "Round 1's rule said…", §7.1 table row 3, §12 item 14(e), §18 F-3 | §7.1 (QA's inline-last-key fixture + `M-D`), §12 14(e), §18 F-3 note |

### Correction 1 — the D-1 justification was false for the PowerShell twin

**What was claimed.** §3.6 justified D-1 (take `hostos` from the spec) by asserting that the spec
carries "the exact discrimination the existing derivation flows already use", i.e. that asking the
spec returns exactly what each flow used to compute.

**What is true.** That holds in bash and **fails in PowerShell**:

- **bash**: `hook-spec.sh:164-167`'s `case "${OSTYPE:-}"` is character-identical to the retired
  `is_windows` block in `upgrade-project.sh`. Zero behavioural delta.
- **PowerShell**: the retired read was `if ($IsWindows)`; the spec's branch is `hook-spec.ps1:198`'s
  `if ($IsWindows -or $env:OS -eq "Windows_NT")`. Under **Windows PowerShell 5.1** `$IsWindows` is
  undefined (`$null`), so the pre-change flow selected the **unix** byte-forms on a Windows host and
  the post-change flow selects **windows**. This is a host-OS **selection** delta, one-sided across
  the shells — the class this repo has shipped before.

**Why nothing changes.** The reviewer ruled it a **strict improvement** (it repairs a latent 5.1
defect: a Windows host was being wired with `sh -c …` commands), it cannot make the guard fail-open
(the spec is the only string source and authors no fail-open variant on either branch), and **AC-2 is
untouched** because OS is a *parameter* of the 8-cell byte comparison, not a result of it — all 8
cells measured byte-identical (`06_TEST_REPORT.md` §3.1-3.2). `hook-spec.ps1:198` is byte-for-byte as
shipped and reviewed (`05` round 2, §6 invariant table).

**What changed here.** §3.6 no longer claims the discrimination is identical to what both flows used.
It states the bash/PowerShell split, names the 5.1 delta as a one-sided *selection* change, and gives
the three separate safety arguments. §14's D-1 entry carries the same correction. The delta must also
appear in `07_DELIVERY.md` as an unrecorded-behaviour-change disclosure — that is PM's carry, not an
edit I make.

### Correction 2 — the quotation the justification rested on no longer exists

**What was false.** Pre-edit `02:369-370` justified D-1 by quoting `hook-spec.sh` as documenting
itself to carry "the exact discrimination the existing derivation flows already use", cited to
`hook-spec.sh:142-147`. Both halves are now wrong:

- **The string is gone.** Under code-review round 1 MINOR #1 the developer reworded all **four**
  `hook-spec` copies; the reviewer re-ran the repo-wide grep in round 2 and found **zero hits in any
  `.sh` or `.ps1`**. The surviving hits are all citations, not assertions — one archived requirement
  document, `04`, `05`, and this document's own now-deleted line.
- **The citation was wrong.** The comment lives at `hook-spec.sh:162-163` (3 lines at
  `hook-spec.ps1:195-197`), not `:142-147`.

**What the shipped comment says now** (`hook-spec.sh:162-163`; the `.ps1` twin at `:195-197` names its
own shell's flow and keeps the 5.1 disclosure line):

> `# The discrimination the derivation flows now OBTAIN from here (it was`
> `# duplicated in upgrade-project.sh until T-16) - no third variant is introduced.`

**What changed here.** The quotation is **withdrawn, not re-pointed**. Re-quoting the new sentence
would be circular: it is a comment this task itself wrote, so it cannot be evidence for this task's
own decision. D-1 now rests on the measured duplication in the **pre-change** flows
(`upgrade-project.sh:271-272` and `.ps1:278`, both retired by this change), which is a fact about the
tree the design was written against. The design's conclusion is unaffected: the duplication class was
real and D-1 is right.

### Correction 3 — the totality evidence was falsified by measurement

**Say it plainly: this claim was measured and found false.** Round 2 of this document (§7.1, its table
row 3, §12 item 14(e) and §18 F-3) asserted that round 1's `== IND` terminator rule "would have
FAILed" on a **block-form** `"PreToolUse"` moved to be the last key inside `hooks`, deriving that from
"every following line dedents to 2 (`  }`) then 0 (`}`), never back to 4". QA ran both rules over the
developer's own fixture:

```
=== SHIPPED rule (<= IND) ===   start=68 IND=4 term=78 (window 68..77)   -> PASS
=== ROUND-1 rule (== IND) ===   start=68 IND=4 term=78  unterminated=no  -> ALSO PASS
```

The derivation overlooked the `PreToolUse` **array's own closing `    ]`**, which sits at leading
width exactly 4. `== IND` finds a terminator there just as `≤ IND` does. **The cited evidence does not
discriminate between the two rules**, so it proved nothing about the repair it was offered as proof
of.

**The conclusion survives, on evidence that measures it.** QA built the discriminating fixture — an
**inline** `"PreToolUse"` as the last key, where the array sits on one line at width 4 and the next
non-blank line is the two-space `}`: the shipped `≤ IND` rule PASSes (`term=69`, window `[68,68]`;
real gate `[F.2] PASS`, 32/0/0) and `== IND` reaches EOF, emits `PreToolUse_block_unterminated` and
**FAILs** a valid template. QA separately confirmed the terminator-**exclusion** tightening with
mutant **`M-D`** (empty `"PreToolUse": [],` above an inline sibling at width `IND`): the shipped
exclusive window FAILs with both containment tokens (31/0/1) where a round-1 inclusive window would
have PASSed. Both fixtures are transcribed into §7.1 and its table, replacing the non-discriminating
row.

**Scope of the edit.** §7.1's paragraph and table, §12 item 14(e)'s rationale clause (the *obligation*
is unchanged in kind and in count — item 14 still asks the operator to confirm `[F.2]` PASSes on the
reordered template, and `baseline.json:_qa_note_t16`, the artifact the operator actually reads, never
carried the struck clause, so no doc/artifact divergence is created), and a correction note under
§18 F-3. The shipped window rule in `verify_all.{sh,ps1}` is **not** touched.

**Why this correction matters beyond this task.** The repo's own standing rule is *cross-check a
claim against the artifact that produced it, not against a plausible-sounding derivation*
(`insight-index.md:26` family). Round 2 wrote a rule-comparison result it had reasoned to rather than
run — and got the right conclusion from the wrong case. That is the second time in this pipeline the
discipline has paid (the first being the developer's measured refusal of the `[ \t]` "cheap closure",
`05` round 2 §2), and the failure mode here is the more dangerous one, because a wrong claim that
reaches the *right* conclusion survives review by being unfalsifiable-looking.

### Items explicitly **not** carried by this section

- **R2-1** (`verify_all.ps1:315` residual missing from `04`'s harvested Open-issues list) — routed to
  developer/PM. Not this document's.
- **QA D-2 / D-3 / D-4** and code-review NITs R2-2 … R2-5 — routed to developer, insight-harvester or
  backlog. Not this document's.
- **RES-1** (§16.1) and **R-1** (the `"command"`-key `[[:space:]]` vs `[ \t]` divergence) — unchanged,
  still open by design, still travelling to `07_DELIVERY.md`.
- `01_REQUIREMENT_ANALYSIS.md`, `04_DEVELOPMENT.md`, `05_CODE_REVIEW.md`, `06_TEST_REPORT.md` — not
  edited by this agent, by contract.

**Round-3 verdict: READY (record corrected).** Three false or dangling statements in this document are
corrected against the artifacts that falsified them. The design as implemented stands unchanged.
