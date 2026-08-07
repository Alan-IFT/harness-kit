# 02 — Solution Design · T-13 `hook-truth-spec`

**Mode**: `full` · **Stage**: 2 (solution-architect) · **Date**: 2026-07-31 · **Rework round 1**
**Upstream**: `docs/features/hook-truth-spec/01_REQUIREMENT_ANALYSIS.md` — verdict `READY`.
**Gate**: `.harness/scripts/verify_all` PASS 32 / WARN 0 / FAIL 0. **Check count stays 32.**
**Version**: `0.44.0` → `0.45.0` (OQ-7a — minor; version strings only).
**Decision mode**: 2 (balanced). All nine OQ `Recommended:` answers adopted as binding; architect
additions logged in §12.

## Rework round 1 — gate conditions

`03_GATE_REVIEW.md` returned CHANGES REQUIRED (F-1, F-2 mandatory). Every cited fact below was
re-verified against the live repo first; nothing was accepted on the gate's word alone.

| Condition | Resolution | Where |
|---|---|---|
| **F-1** count-ledger missed a live site | Confirmed `docs/dev-map.md:176`. **Re-grepped the repo myself** (`script pairs`, `script-pair`, `mirror set`, `mirrors only`, `脚本对`, and the 7-name enumeration) — the live set is **five** and now closed; search method recorded so re-review can reproduce it. No frozen claim moved. | §11 count ledger (5-row table + method note), row D3 |
| **F-2** AC-3's transitive chain does not exist | All four sub-claims verified true. Chose **(a)**: Group A's oracle re-pointed at `resilient_cmd` / `Get-ResilientCmd` for all 8 combos; false transitivity sentence deleted; per-comparison evidentiary status stated; no stage-1 rollback needed (AC-3's own parenthetical names this oracle). | §9 (rewritten), §12 D-4 |
| **W-1** `set -e` pre-empts exit 4 | Confirmed `install-hooks.sh:16`. Non-swallowing capture form mandated for **every** spec call incl. the `tools` loop; empty-string checked separately. | §3.2 "Spec capture", §6 step 5 |
| **W-2** template-twin wording | Globbed: 19 files under `templates/common/.harness/scripts/`, no `sync-self.*`/`verify_all.*`; the six `templates/<type>/…/verify_all.{ps1,sh}.tmpl` **do exist** and need no edit (grep for `for pair in`/the affected script names in `generic/…/verify_all.sh.tmpl`: 0 hits). | §2 last paragraph |
| **W-3** decoys / D11 | `CHANGELOG.md:334` named beside `:261`; `docs/tasks.md` added **with the T-13 ID collision** (`:48` = historical `T-13 lang-policy-split`); `docs/dev-map.md:112-114` added to D3 as an append-only refresh. | §11 decoys 1/10, row D3 |
| **W-4** PS write API | `[System.IO.File]::WriteAllText` pinned for **both** generated bodies; `Set-Content`/`Out-File` prohibited. | §3.2, §4, ledger B2 |
| **W-6** R-2 undercount | Added `test-harness-upgrade.sh:296,306` + `.ps1:296` (JSON-escaped) and `.sh:555` + `.ps1:599,603,608` (raw-shell/raw-pwsh guard — a *different* escaping level) to R-2 and to the spec header's T-16 pointer list. | §13 R-2, §3.1 header |
| **Minor 1** non-regular file at the local-settings path | `settings_hook_state` gets an explicit 3-way existence probe; non-regular ⇒ `present` ⇒ no action. | §3.2 |
| **Minor 2** PS gate hard-parses the local settings | Recorded: `verify_all.ps1:290-291` `ConvertFrom-Json` vs `verify_all.sh:304` grep. | §14 item 4, R-5 |

W-5 is requirement-owned (NFR-4 scoping); not addressed here.

## 1. Architecture summary

A new two-shell **hook wiring spec** (`hook-spec.{ps1,sh}`) is added to the distributed
`templates/common/.harness/scripts/` and byte-mirrored into this repo by `sync-self`. It is a pure,
side-effect-free CLI answering six queries about the four lifecycle-hook tools — `tools`, `event`,
`matcher`, `semantics`, `command <tool> <os>`, `hostos` — emitting the command in the
JSON-string-body form (inner `"` already `\"`) that every consumer writes into a settings file. Its
only consumer today is the proof consumer: `install-hooks.{ps1,sh}` gains a second responsibility —
after installing the git pre-commit hook unchanged, it bootstraps a missing **machine-local
settings** file (`.claude/settings.local.json`) from the spec when, and only when, the committed
settings declares no lifecycle hooks and no machine-local file exists. No hook runtime behavior
changes; no derivation flow is re-pointed (T-16); no gate check is added.

## 2. Affected modules

**§11 is the authoritative per-file ledger** (path, change, mirror obligation, AC); this is the map,
not a second list. Four groups: the **new spec pair** (template SOT + repo byte-mirror, A1-A4); the
**proof consumer** `install-hooks.{ps1,sh}` (same shape, B1-B4); **wiring / gate arrays** —
`sync-self` (new Mapping 9), `verify_all` (F.1 array), `test-init`, `baseline.json` (C1-C7); and
**docs + version fan-out** (D1-D11).

**Template twins (W-2, precise).** `sync-self.{ps1,sh}` and `verify_all.{ps1,sh}` have **no** twin
under `skills/harness-init/templates/common/.harness/scripts/` — that directory holds 19 files and
neither name is among them, so those four repo files are edited in place with no mirror obligation.
Six `verify_all.{ps1,sh}.tmpl` files **do** exist under
`skills/harness-init/templates/{backend,fullstack,generic}/.harness/scripts/`; they are the per-type
generated-project gate and require **no edit** — no F.1-style script-pair array, and they name none
of the scripts this task touches (verified by grep on the `generic` twin).

## 3. Module decomposition

### 3.1 `hook-spec.{ps1,sh}` — the hook wiring spec

**Responsibility.** Own the `(tool, OS) → command byte-form` table, the per-tool failure semantics,
event name and matcher, and the host-OS rule — nothing else (no file I/O, parsing, substitution).

**Interface** (the *whole* contract a caller must know):

| Invocation | stdout (exactly one line) | exit |
|---|---|---|
| `hook-spec tools` | 4 lines, fixed order: `harness-sync`, `guard-rm`, `ambient-prompt`, `ambient-reset` | 0 |
| `hook-spec event <tool>` | `Stop` \| `PreToolUse` \| `UserPromptSubmit` \| `SessionStart` | 0 |
| `hook-spec matcher <tool>` | `Bash` for `guard-rm`; the literal `none` for the other three | 0 |
| `hook-spec semantics <tool>` | `fail-open` \| `fail-closed` | 0 |
| `hook-spec command <tool> <os>` | the JSON-string-body command (inner `"` as `\"`) | 0 |
| `hook-spec hostos` | `windows` \| `unix` — the host this shell is running on | 0 |
| any unrecognized query / tool / os / arity | **nothing on stdout**; a diagnostic on stderr naming the unrecognized token | **2** |

- Tool ids are the four **script basenames** — not cosmetic: `command` interpolates the id into
  ` .harness/scripts/<tool>.<ext>` exactly as today's helpers do, so FR-5 / AC-4 (congruence-token
  survival) holds by construction. `os` accepts exactly two case-sensitive spellings, `windows` and
  `unix` — no third value, no alias.
- `none` is a reserved non-empty sentinel for "this event takes no matcher" (FR-7 forbids an empty
  successful answer; Claude Code's real matcher value is never `none`). Every 0-exit path prints a
  non-empty line, and every emitted byte is US-ASCII in output *and* diagnostics — sidestepping the
  `pwsh` host-codepage mojibake class (insight 2026-06-12).
- **A consumer invokes the twin of its own shell.** Crossing shells is prohibited: MSYS bash
  capturing `pwsh` output via `$(...)` strips the `\n` but leaves the `\r`, corrupting the command
  string. Stdout line-ending bytes are therefore **not** part of the contract; the captured value
  (both shells strip the trailing newline) is.

**Header comment (load-bearing, W-6).** The file header names the T-16 hand-off surface: the four
call sites to re-point (`upgrade-project.{ps1,sh}`, `migrate-scripts-layout.{ps1,sh}`), the two
SKILL.md prose tables, **and** the known remaining copies T-16 must not overlook —
`test-harness-upgrade.sh:296,306` / `.ps1:296` (JSON-escaped `harness-sync` forms) and `.sh:555` /
`.ps1:599,603,608` (the raw-shell / raw-`pwsh` guard command, a *different escaping level* the spec
deliberately does not emit under OQ-2a — retiring those needs OQ-2's deferred raw form first).
Listing them stops T-16 declaring victory with the duplication still live.

**Implementation shape (both shells).** One dispatch on the query token, then per-tool `case` /
`switch` blocks. The `command` branch has exactly four literal shapes, transcribed **verbatim**
from the canonical helpers — do not retype: windows·guard-rm `upgrade-project.sh:106` / `.ps1:115`;
windows·other three `:108` / `:117`; unix·guard-rm `:112` / `:121`; unix·other three `:114` / `:123`.
The bash twin uses `printf '%s\n'` with the tool name interpolated (as `resilient_cmd` does); the PS
twin uses `-f` over a **single-quoted** literal with `{0}` for the tool and `{{`/`}}` for literal
braces — the idiom proven at `upgrade-project.ps1:115-123`. Never double-quote concatenation
(insight 2026-06-21 (2), failure modes 1 and 3). No parameter or variable in either twin may be
named `$isWindows`, `$IsLinux`, `$IsMacOS`, `$Host` or any other read-only automatic (failure mode
2); use `$forWin` / `$targetOs`, matching `Get-ResilientCmd`'s post-fix name. `hostos` reuses the
existing expressions verbatim — bash `case "${OSTYPE:-}" in msys*|cygwin*|win32) …`
(`upgrade-project.sh:272`), PS `if ($IsWindows -or $env:OS -eq "Windows_NT")`
(`test-real-project.ps1:104` / `test-init.ps1:103`) — so B-11 holds with no third variant.
**Deletion test**: delete `hook-spec` and the installer plus the four future T-16 consumers each
regrow their own 8-cell table with two failure semantics — the defect this task removes.

### 3.2 `install-hooks.{ps1,sh}` — the proof consumer

- `settings_hook_state <path>` → `absent` | `unparseable` | `empty` | `present` — a deliberately
  shallow structural probe — no `jq`, no `python3` (the Git-for-Windows MSYS shell has neither;
  same philosophy as `verify_all.sh:647-651` J.1). **Existence first (gate Minor 1 — `[ -e ]` and
  `[ -f ]` disagree here, so the answer is stated, not inherited):** (0a) nothing at the path
  (neither `-e` nor `-L`; PS `Test-Path -LiteralPath`) → `absent`; (0b) exists but is **not a
  regular file** (directory, dangling symlink, device; PS `-PathType Leaf` false) → **`present`**
  for the machine-local path (report it, read nothing, write nothing) and **`unparseable`** for the
  committed path (row 1 → exit 3). Then, for a regular file: (1) empty after whitespace strip, or
  first non-ws char ≠ `{`, or last ≠ `}` → `unparseable`; (2) no `"hooks"` followed (after optional
  ws) by `:` → `empty`; (3) that `:` not followed by `{` → `unparseable`; (4) first non-ws char
  after that `{` is `}` → `empty`, else `present`. Step 2's anchor is immune to prose mentions:
  `.claude/settings.json:4` names all four events inside a doc string and is correctly `empty`, and
  an escaped `\"hooks\"` never matches (the byte before `hooks` is `\`, not `"`).
- `write_local_settings <path> <sync> <guard> <prompt> <reset>` → builds the body, writes it
  **atomically** (temp sibling then rename), re-reads from disk, verifies, returns 0/non-zero.
  **PS write API is pinned (W-4)**: join the line array with `` "`n" ``, append one trailing
  `` "`n" ``, write via `[System.IO.File]::WriteAllText($tmp, $body)` — BOM-free by contract — then
  rename with `Move-Item -LiteralPath` (destination guaranteed absent by §8 row 5). **Never**
  `Set-Content` / `Out-File` for this body or the pre-commit body: on Windows PowerShell 5.1
  `Set-Content` emits a BOM and `Out-File` defaults to UTF-16LE, either of which breaks AC-10
  byte-identity, J.1's anchored `^[[:space:]]*"\$schema"` grep, and J.1's indent parser.
  bash: `printf '%s\n'` into the temp sibling, `mv -f`.

**Spec capture under `set -euo pipefail` (W-1).** `install-hooks.sh:16` sets `set -euo pipefail`, so
a bare `cmd="$(bash "$sd/hook-spec.sh" command "$tool" "$os")"` aborts the whole script with the
child's status and the designed `exit 4` is unreachable. Every spec call in the bash twin —
`hostos`, `tools`, `event`, `matcher`, `command` — uses the non-swallowing form
`if ! cmd="$(...)"; then <diag>; exit 4; fi`, followed by a **separate** `[ -n "$cmd" ] || { <diag>;
exit 4; }` for the empty case (B-2). The tool list is captured the same way **before** the loop
(`for tool in $(hook-spec …)` inherits the same abort); an explicit `|| rc=$?` is an acceptable
equivalent. The PS twin is already correct via `$LASTEXITCODE -ne 0` + `[string]::IsNullOrEmpty()`.

**Exit codes** (0/1 pre-existing, the rest new and disjoint): **0** success — bootstrapped, or
deliberately took no bootstrap action; **1** not a git repository (**unchanged**, FR-13, B-14);
**3** committed settings present but structurally unparseable (B-5) — nothing written; **4** the
spec did not yield four non-empty commands (B-2) — nothing written; **5** write or terminal
end-state verification failed (B-8) — target left absent.

## 4. Data model changes

No database. One new **generated artifact**: `.claude/settings.local.json`, created only on the
bootstrap path. Its shape is fixed and deterministic (byte-identical across runs and shells):

- `$schema` = `https://json.schemastore.org/claude-code-settings.json` — **with** the `.json` suffix
  (rule `80-settings-schema.md`; insight 2026-05-23). Consult the upstream schema before finalizing
  the key set (`context7` `/websites/code_claude`, or WebFetch
  `https://www.schemastore.org/claude-code-settings.json`); never recall the shape.
- Two underscore doc keys — `_comment`, `_hook_semantics` — at the **root object only**, never inside
  `hooks` (upstream `hooks` is `additionalProperties:false`). `_hook_semantics` states the
  fail-open/fail-closed split and the B-7 opt-out in **ASCII with no escaped quotes** (write "an
  empty hooks object", not `\"hooks\"`, so our own doc text cannot trip the §3.2 anchor).
- `hooks` holds exactly four keys in this order — `Stop`, `PreToolUse` (with `"matcher": "Bash"`),
  `UserPromptSubmit`, `SessionStart` — all in J.1's `j1_valid_hook_events` (`verify_all.sh:652`).
- **Indentation is load-bearing** (J.1's hooks-key extractor is indent-based,
  `verify_all.sh:676-685`): 2 spaces per level, `"hooks": {` at indent 2, event keys at indent 4,
  closing `  }` at indent 2 — today's `.claude/settings.local.json` already passes J.1, so
  **replicate its layout exactly**. One trailing `\n` at EOF, LF endings, **BOM-free**, both shells
  (B-13, AC-10, W-4).

## 5. API contracts

**5.1 Spec CLI** — fully specified in §3.1; the two invariants a consumer may rely on are **purity**
(for fixed arguments the output is a fixed byte string; only `hostos` reads `OSTYPE` / `$IsWindows`
/ `$env:OS`) and **totality** (exit 0 ⟺ non-empty stdout; exit 2 ⟺ empty stdout + non-empty stderr).

**5.2 How T-16's four consumers will call it** (specified, not implemented here). T-16 replaces each
helper's private table with a call to the spec twin of its own shell — fixed now so T-16 needs no
redesign, and inheriting the W-1 capture form since those helpers also run under `set -u`. bash:
`if ! cmd="$(bash "$scripts_dir/hook-spec.sh" command "$tool" "$os")"; then <fail>; fi`; PS:
`$cmd = & pwsh -NoProfile -File (Join-Path $scriptsDir 'hook-spec.ps1') command $tool $os` then
`if ($LASTEXITCODE -ne 0) { <fail> }`. The two SKILL.md prose tables
(`skills/harness-init/SKILL.md:187-190`, `skills/harness-adopt/SKILL.md:311-314`) are T-16's too and
are **not** touched here.

**5.3 Installer terminal report (FR-12).** On the bootstrap path, after the end-state re-read
succeeds, stdout carries the created path, the four wired events with
`PreToolUse -> guard-rm (fail-closed)` called out, the removal command in this shell's own form
(`rm <path>` / `Remove-Item <path>`), and a note that the file is machine-local and should be
gitignored if the project tracks `.claude/`. On every non-bootstrap path, one line stating which
condition held and that nothing was written.

## 6. Sequence / flow

```
operator: bash .harness/scripts/install-hooks.sh
  1. repo_root = two levels up (unchanged)   -- .git/ absent -> exit 1  (FR-13/B-14)
  2. probe committed settings.json -> unparseable: name it, exit 3, NOTHING written (B-5)
  3. write .git/hooks/pre-commit (unchanged behavior; LF + WriteAllText in PS)  (FR-13)
  4. bootstrap decision (section 8): committed hooks present -> report, exit 0  (FR-10)
  |                                  settings.local.json exists -> report, exit 0 (FR-9)
  5. hostos / tools / per tool event|matcher|command -- EVERY capture via the
  |    `if ! v="$(...)"` form (W-1); non-zero OR empty -> exit 4, NOTHING written (B-2)
  6. mkdir -p .claude (B-3); write body -> ...local.json.tmp-<pid>; rename over target;
  |    any failure -> remove the temp, exit 5, target left ABSENT               (B-8)
  7. TERMINAL CONFIRMATION: re-read FROM DISK (never the in-memory buffer); assert
  |    non-empty + "PreToolUse" + "matcher": "Bash" + the 4 commands verbatim;
  |    any miss -> stderr, exit 5, no success line.                            (B-8)
  8. print created path + wired events + removal command -> exit 0             (FR-12)
```

Temp-then-rename is what makes B-8 and B-10 both hold: a failed or concurrent write can never leave
a half-written file wiring a truncated guard command, and two concurrent runs converge on identical
bytes with no lock. The temp is removed on every failure path — nothing named
`settings.local.json.*` survives a run (AC-6).

## 7. Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| The 8 hook command byte-forms (and their test fixtures) | `resilient_cmd` / `Get-ResilientCmd`; the OS-conditional `test-init` literals | `upgrade-project.sh:102-117`, `.ps1:112-126`; `test-init.sh:46-59`, `.ps1:103-114` | **Transcribe verbatim** into the spec **and reuse the helpers as the AC-3 oracle** (§9); not extracted/deleted — re-pointing those four flows is T-16. Restructure the fixtures to expose both OS sets, used as a **lockstep** (not independent) comparison — §9 group A'. |
| Host-OS discrimination; script-pair presence gate | `case "${OSTYPE:-}"` / `$IsWindows -or $env:OS`; F.1 hardcoded array | `upgrade-project.sh:272`, `test-real-project.ps1:104`; `verify_all.sh:284`, `.ps1:269-270` | Reuse the exact OS expressions in `hostos` — no third variant (B-11). Add `hook-spec` to **both** F.1 arrays + the PS Step label; an array element is not a new check (OQ-6a). |
| Extract a live definition from a sibling script for a lockstep assertion | `extract_i6_banned` (awk range) / `extract_ps_banned_records` | `test-verify-i6.sh:332-335`, `:344-359` | **Pattern reused** by §9's oracle loader (awk range + `eval` in bash; AST `FunctionDefinitionAst` in PS). Precedent, not shared code. |
| Literal replace immune to bash 5.2 `&` | `str_replace_all` / `ti_replace_all` | `upgrade-project.sh:124-131`, `test-init.sh:65-72` | **Not needed and not used**: the design does zero substitution over command values (§10 FC-2). B-12 is satisfied by construction, not by discipline. |
| jq-free settings probing; temp-dir-per-fixture harness | J.1 `$schema`/hooks-key scanner; `test_migrate` | `verify_all.sh:641-692`; `test-init.sh:538-623` | Patterns reused (shallow targeted probe, no parser; own temp dir per fixture — insight L22); code not shared, `verify_all` is not a library. |
| Layer-1 byte mirror | `sync_file` mappings | `.harness/scripts/sync-self.sh:63-88`, `.ps1:56-61` | Extend with Mapping 9. Gate coverage is automatic: E.1 delegates to `sync-self --check` (`verify_all.sh:194`). |
| Guard-rm block/allow demonstration | live-guard probe | `test-harness-upgrade.sh:540-560` | QA reuses this pattern by hand for AC-9. **No edit** to `test-harness-upgrade.*` — its baselines stay 89/89. |
| Glossary terms; prior-decline check | `Hook wiring spec`, `Machine-local settings` | `CONTEXT.md:73-82`; `.harness/rejected-decisions.md` | Both terms already present (added by RA) → **no `CONTEXT.md` edit**. No decline record covers hook single-sourcing or installer bootstrap → nothing to surface, nothing new declined. |

## 8. Installer bootstrap decision logic (truth table)

`G` = committed settings state · `L` = `.claude/settings.local.json` presence · first match wins.

| # | G | L | `.claude/` | Action | Exit | AC / B |
|---|---|---|---|---|---|---|
| 1 | `unparseable` | any | any | stderr names the file; **nothing written at all** (evaluated before the pre-commit write) | 3 | B-5 |
| 2 | `present` | any | any | pre-commit installed; report "committed settings already declares hooks — no machine-local file created" | 0 | FR-10, AC-7 |
| 3 | `absent`/`empty` | present | any | pre-commit installed; report "machine-local settings already present at `<path>` — left byte-untouched, no backup written" | 0 | FR-9, B-6, B-7, B-9, AC-6 |
| 4 | `absent`/`empty` | absent | absent | pre-commit installed; `mkdir -p .claude`; then row 5 | — | B-3 |
| 5 | `absent`/`empty` | absent | present | query spec → 4 commands; any empty/non-zero → exit 4, nothing written; else temp-write → rename → **re-read from disk** → report | 0 / 4 / 5 | FR-8, B-2, B-8, AC-5 |

Notes that the developer must not "improve":

- Row 3 keys on **presence alone**, never content. An unparseable local file (B-6), an empty-`hooks`
  local file (B-7, the persistent opt-out) and a non-regular file at that path (§3.2 step 0b) all
  land here and are left byte-untouched; reading its content to "repair" it would break FR-9 and
  silently undo a deliberate disable.
- Row 1 precedes the pre-commit write because B-5 says "changes nothing" — the only behavioral delta
  to FR-13, firing solely on an already-broken committed settings file. Recorded so review does not
  read it as drift.
- **Terminal confirmation discipline (T-020 CR MAJOR B8)**: row 5's end-state assertion re-reads the
  file **from disk**; validating the in-memory body is the exact bug that shipped in
  `migrate-scripts-layout.sh` and exited 0 on a failed write. Direction of risk is restore-only by
  construction (NFR-2).

## 9. AC-3 byte-identity proof mechanism (F-2 — rewritten)

**Where**: `.harness/scripts/test-init.{ps1,sh}` (OQ-9a) — no new driver, script pair, baseline key or gate check.

**The prior rationale was false; it is deleted.** Round 1 called the `EXP_*` fixtures "pinned to the
distributed template". I re-read the driver and confirm all four gate sub-claims: only **two**
full-literal `grep -qF '"command": "<literal>"'` assertions exist (`test-init.sh:324` ambient-prompt,
`:326` ambient-reset) — `$SYNC_COMMAND` / `$GUARD_COMMAND` have none (they occur only at `:48-49`,
`:54-55`, `:90`, `:92-93`; the guard is covered solely by the `:295` matcher and `:301`
`guard-rm\.(ps1|sh)` greps); those two grep the file for the very variable `substitute()` injected
at `:94-95` — **composition-integrity, not a pin** (insight 2026-06-09); the template carries
`{{GUARD_COMMAND}}`-style tokens, not byte-forms (`verify_all.sh:322-325`); and `substitute()` binds one OS set per run (`:46-59`), so the other four literals were only ever compared to themselves.

**Resolution: option (a).** Group A's oracle is re-pointed at the live derivation helpers — the
oracle AC-3's own parenthetical names — so AC-3 is met as written and no stage-1 rollback is owed
(justified in §12 D-4). `resilient_cmd <tool> <win>` (`upgrade-project.sh:102-117`) and
`Get-ResilientCmd <tool> <forWin>` (`.ps1:112-126`) take the OS as a **parameter**, not from the
host, so one Linux bash run evaluates all four Windows *and* all four unix forms; both are live,
independently maintained and still consumed in production by `/harness-upgrade`, so an edit to
either implementation moves one side of the comparison only. Both start their flow at load
(`upgrade-project.sh:133`, `.ps1:128`), so `source` / dot-sourcing is **prohibited** — extract the
one function definition instead:

- bash: `eval "$(awk '/^resilient_cmd\(\) \{$/{f=1} f{print} f&&/^\}$/{exit}' "$repo_root/.harness/scripts/upgrade-project.sh")"` — the extracted body touches only its own locals. Precedent: `test-verify-i6.sh:332-335` range-extracts a live definition out of `verify_all.sh` for a lockstep compare.
- PS: `[System.Management.Automation.Language.Parser]::ParseFile(...)` → the `FunctionDefinitionAst` named `Get-ResilientCmd` → `. ([ScriptBlock]::Create($ast.Extent.Text))`. Never `Invoke-Expression` on the whole file.
- **Anti-vacuity gate (mandatory, one named assertion per shell, before the 8):** `resilient_cmd guard-rm true` returns a non-empty string containing `guard-rm.ps1`. A failed extraction must fail *that* assertion loudly, never silently degrade the comparisons.

**Assertion groups** — new `test_hook_spec` / `Test-HookSpec`, invoked **unconditionally** (like the BUG-2 block at `test-init.sh:727-738`), calling this repo's `.harness/scripts/hook-spec.<ext>`:

| Group | Assertions | Evidentiary status — stated plainly | Serves |
|---|---|---|---|
| A | 8 × `command <tool> <os>` ≡ `resilient_cmd` / `Get-ResilientCmd <tool> <win>`, exit 0 | **Independent** for all 8; **none host-OS-only** (OS is a parameter of both sides) | AC-1, AC-3 |
| A' | 8 × the same outputs ≡ the restructured `EXP_*` fixtures | **Lockstep only** — the fixtures are hand copies; catches fixture drift, is *not* independent evidence | AC-3 support |
| B | 4 × `semantics <tool>`; 2 × the guard command (each OS) contains neither `\|\| exit 0` nor `exit 0` | direct assertion on real output | AC-2, NFR-2 |
| C | 8 × the existing congruence ERE (`test-init.sh:317-320`) extracts `.harness/scripts/<tool>.<ext>` | direct | AC-4, FR-5 |
| D | 4 × `event`/`matcher`; `tools` emits the 4 ids in the fixed order | direct | FR-1, installer contract |
| E | 3 × unknown tool / unknown os / unknown query → non-zero **with empty stdout** | direct | FR-7, B-1 |

**What this does and does not establish** (no overstatement — insight 2026-06-09):

- All 8 Group A comparisons are independent and host-independent; **none is host-OS-only** — the
  concrete gain over round 1, where 4 of 8 were literal-vs-literal.
- Nothing here proves the spec matches the *distributed template after substitution* — the template
  holds placeholders, so no such byte oracle exists in-repo. The pre-existing `:324`/`:326`
  assertions are composition-integrity and must **not** be called drift-catchers in any doc.
- Each shell's chain closes inside its own shell. **Cross-shell** twin identity is not assertable
  in-repo without executing `pwsh` (a source-text compare is invalid: source escaping differs,
  `\\\"` vs `\"`, while emitted bytes agree); it rests on the [M2] hand-lockstep plus NFR-5's
  operator run, recorded green-by-symmetry-only until then.
- **Prohibited**: populating the `EXP_*` fixtures or the four `*_COMMAND` variables from `hook-spec`
  — that would convert the pre-existing C3 assertions into composition-integrity too.
- **QA mutation target**: mutate one literal in `resilient_cmd`'s guard branch (or in `hook-spec.sh`)
  → Group A goes red for exactly the mutated `(tool, OS)` cells. Mutate the **artifact**, never the
  assertion list (insight 2026-06-20).

**Fixture restructure (both twins).** The fixtures live inside an OS `case`/`if`
(`test-init.sh:46-59`, `.ps1:103-114`), so only one OS's four literals exist per run. Define **all
eight** unconditionally as `EXP_WIN_<TOOL>` / `EXP_UNIX_<TOOL>` (PS `$expWin<Tool>` /
`$expUnix<Tool>`), then bind the four existing `*_COMMAND` / `$*Cmd` from the host set — pure
re-binding: emitted bytes unchanged, pre-existing C3 assertions green.

**Installer proof block** — new `test_install_bootstrap` / `Test-InstallBootstrap`, gated like
`test_migrate` (`all`/`both`), own temp tree via `copy_layer` (common + generic) +
`mkdir -p "$tmp/.git"` (no `git` binary needed — the installer only tests for the directory):
(1) installer on the tree as-is (committed settings **has** hooks) → exit 0, no local file (AC-7);
(2) rewrite the generated hooks object to `{}` → installer → exit 0, file created, contains
`"PreToolUse"`, `"matcher": "Bash"`, the canonical `.json` `$schema`, all four host-OS command
strings, no underscore key at indent 4, no BOM, exactly one trailing `\n` (AC-5, FR-11, B-13);
(3) snapshot bytes, run again → byte-identical, no `settings.local.json.*` sibling, no `*.bak*`
under `.claude/` (AC-6, B-9); (4) delete the local file, make `.claude` read-only where the platform
honors it → non-zero exit and the file still absent; restore (skip-with-notice otherwise, as
`test-harness-upgrade` does for its M3 probe).

**Baseline updates** (`.harness/scripts/baseline.json`) — the *only* numeric changes in this task.
`test_init_bash_no_python3_assertions`: `278` → **the number from a captured run**, never
hand-derived from this document (insight 2026-06-04: a hand-derived tally shipped once).
`test_init_ps_assertions` stays `316` in the commit, flagged for **operator reconciliation** exactly
as `_qa_note_t12` did; add a `_qa_note_t13` recording the bash delta, why the PS count is
unreconciled, and the mandatory operator step. `verify_all_checks` stays **32** (G.4 row 11 asserts
it), and every other driver's counts are unchanged — none is edited, and adding a file under
`templates/common/.harness/scripts/` adds no `test-real-project` assertion. Confirm 90/90 and 89/89
in the run log.

## 10. Fail-closed invariant for the destructive-command guard

Four invariants, each mechanically checkable at every code path this design introduces.

- **FC-1 — one origin.** Every guard-rm command string in new code comes from
  `hook-spec … command guard-rm <os>`. *Check*: `grep -n 'guard-rm'` over both installers returns
  only the loop over `hook-spec tools` — no literal guard command.
- **FC-2 — no post-processing.** The spec's return value lands in the JSON body unmodified: no
  `${var//…}`, `sed`, `-replace`, `.Replace()`, `printf` re-quoting. *Check*:
  `grep -nE '\$\{[A-Za-z_]+//|sed |-replace|\.Replace\('` over both installers returns no hit
  touching a `*_cmd` / `$*Cmd` variable — making B-12 (bash 5.2 `patsub_replacement` eating
  `& pwsh`) unreachable rather than merely handled.
- **FC-3 — no exit-0 fallback in the guard branch.** The spec's `guard-rm` branches contain no
  `|| exit 0`, no trailing `; exit 0`, no `-EA SilentlyContinue`. *Check*: static — read the two
  branches; executable — §9 group B asserts it on real output for both OS values.
- **FC-4 — all-four-or-nothing, never a partial file.** The installer writes only when all four
  commands are non-empty and the spec exited 0 for each (B-2, via the W-1 capture form), writes via
  temp-then-rename (B-8), confirms by re-reading from disk, and never emits/reads/persists
  `HARNESS_ALLOW_OUTSIDE_RM` (NFR-4). *Check*: `grep -n 'HARNESS_ALLOW_OUTSIDE_RM'` over both
  installer and both spec files → zero hits; every `exit`/`return` between "decided to bootstrap"
  and "confirmed on disk" is non-zero or preceded by the successful re-read.

## 11. Change ledger

**[M1]** = layer-1 mirror (template ↔ repo, enforced by `sync-self` → E.1); **[M2]** = hand-lockstep (the two shells of one repo file, enforced by review only).

| # | File | Change | Mirror | Serves |
|---|---|---|---|---|
| A1 | `…/templates/common/.harness/scripts/hook-spec.sh` | new — §3.1 | [M1]→A3, [M2]↔A2 | FR-1..7, AC-1..4 |
| A2 | `…/templates/common/.harness/scripts/hook-spec.ps1` | new — §3.1 | [M1]→A4, [M2]↔A1 | FR-1..7, FR-14 |
| A3/A4 | `.harness/scripts/hook-spec.{sh,ps1}` | new — produced by `sync-self`, never hand-written | [M1] | FR-6, AC-11 |
| B1 | `…/templates/common/.harness/scripts/install-hooks.sh` | edit — §3.2/§8; unchanged pre-commit body; W-1 capture form | [M1]→B3, [M2]↔B2 | FR-8..13, AC-5..7 |
| B2 | `…/templates/common/.harness/scripts/install-hooks.ps1` | edit — same, **plus** replace the `@'…'@` here-string body with a line array joined by `` "`n" `` + explicit trailing `` "`n" ``, written via `[System.IO.File]::WriteAllText` (both bodies — W-4) | [M1]→B4, [M2]↔B1 | FR-8..13, AC-10, OQ-5 |
| B3/B4 | `.harness/scripts/install-hooks.{sh,ps1}` | mirror — produced by `sync-self` | [M1] | AC-11 |
| C1/C2 | `.harness/scripts/sync-self.{sh,ps1}` | edit — Mapping 9 (`hook-spec.ps1`, `.sh`) after Mapping 8 (`sh:88`), **plus** the PS header comment list (`ps1:8-21`) | [M2] pair | AC-11 |
| C3/C4 | `.harness/scripts/verify_all.{sh,ps1}` | edit — add `hook-spec` to the F.1 array (`sh:284`, `ps1:270`) **and** to the PS Step label string (`ps1:269`) | [M2] pair | OQ-6a |
| C5/C6 | `.harness/scripts/test-init.{sh,ps1}` | edit — fixture restructure + oracle loader + `test_hook_spec` + `test_install_bootstrap`, both twins | [M2] pair | AC-1..7, NFR-5 |
| C7 | `.harness/scripts/baseline.json` | edit — bash count from a captured run + `_qa_note_t13`; `verify_all_checks` stays 32 | — | AC-8, AC-12 |
| D1/D2 | `.harness/rules/75-safety-hook.md` + `…/templates/common/.harness/rules/75-safety-hook.md.tmpl` | edit — "Fully disable" (repo §82-87, `.tmpl` §74-79) gains: removing hooks from the committed file is not enough once `install-hooks` runs; leave a machine-local file with an empty hooks object (B-7) to keep them off. Dogfood note gains the bootstrap sentence; `.tmpl` says the same in generic wording. | [M2] pair | FR-15, AC-13 |
| D3 | `docs/dev-map.md` | edit — script-tree rows for `hook-spec` (template + repo); the 7 → 8 flips at **L142, L163, L164, L176** (see below); a `hook-spec` row under `## Reusable utilities`; and **append** to the `settings.local.json` row at L112-114 that the file is now installer-regenerable from the spec (W-3) — append only, do not rewrite its `(T-12 v0.44)` attribution | — | FR-16, AC-13 |
| D4 | `AI-GUIDE.md` | edit — L76 sync-self line: 7 → 8 pairs + `hook-spec` in the parenthetical; add one `hook-spec` bullet to the Scripts list | — | FR-16 |
| D5 | `.harness/rules/40-locations.md` | edit — one "what lives where" row for the hook wiring spec | — | FR-16 |
| D6 | `CHANGELOG.md` | edit — new `## [0.45.0]` heading + entry (G.4 requires the heading for the current version) | — | FR-16, AC-12 |
| D7/D8 | `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` | edit — `version` → `0.45.0` (marketplace line 17) | — | OQ-7a, G.3 |
| D9/D10 | `README.md`, `README.zh-CN.md` | edit — version badge only (`version-0.45.0-blue`, line 5 in each). **Do not touch** the `verify__all-32%2F32` or `test--init-316%2F316` badges unless the captured PS run reconciles the latter. | — | G.3, G.4 |
| D11 | `docs/tasks.md` | edit — **only** the Active-table T-13 row at line 9 (see decoy 10) | — | — |

**Count-ledger discipline (F-1 — re-grepped, set now closed).** Exactly one count claim moves — the `sync-self` mirror-set size, **7 → 8** — and it is live at **five** sites, not four:

| # | Site | What must change |
|---|---|---|
| 1 | `AI-GUIDE.md:76` | numeral 7 → 8 **and** `hook-spec` added to the 7-name parenthetical (D4) |
| 2 | `docs/dev-map.md:142` | "repo SOT (7 script pairs)" → 8 (D3) |
| 3 | `docs/dev-map.md:163` | "sync-self touches only the 7 script pairs" → 8 (D3) |
| 4 | `docs/dev-map.md:164` | same sentence in the rejected-decisions row → 8 (D3) |
| 5 | **`docs/dev-map.md:176`** | numeral 7 → 8 **and** `hook-spec` added to the 7-name parenthetical — inside `## Reusable utilities`, the same table D3 adds a row to (D3) |

*Search method (reproducible).* Re-grepped the whole repo for `script pairs`, `script-pair`,
`mirror set`, `mirrors only`, `脚本对`, and the 7-name enumeration
`harness-sync.{0,40}install-hooks.{0,40}archive-task`. Every other live hit is a non-count
enumeration or a frozen decoy; there is **no** such claim in either README, `CONTRIBUTING.md`,
`docs/getting-started.md`, `.harness/rules/`, `evals/`, or any `.html`. The
non-count enumerations of the same set move in lockstep or the ledger is internally inconsistent:
`sync-self.ps1:8-21` header list (C2), `docs/dev-map.md:27` and `:91-98` script trees (D3), the
`AI-GUIDE.md` Scripts bullet list (D4). The claim is **not** in G.4's pinned array
(`verify_all.sh:732-770` pins check-count claims only), so review is its only protection — all five
sites move together. AC-12's "no count claim changes" refers to the gate-pinned release claims
(checks 32, skills 17, agents 8), untouched here; the carve-out is logged as §12 D-3 and was
adjudicated legitimate by the gate.

### DO-NOT-TOUCH decoys

Each contains a number or version string that looks live and is **frozen**:

| # | Site | Why it looks live / why it is frozen |
|---|---|---|
| 1 | `CHANGELOG.md` — every historical `## [x.y.z]` entry | Named because they are the closest lexical twins of the live claim: **:261** ("`sync-self` mirrors only the 7 script pairs", v0.40-era) and **:334** ("The 7 script-pair mappings are untouched", v0.30-era); :115/:398/:476/:480/:485/:1097/:1118 carry older 4- and 6-pair counts. Add a 0.45.0 entry; edit none. |
| 2 | `docs/features/_archived/**` | All of it, incl. `harness-language-skill/*` ("6→7 script pairs"), `resilient-hooks/*`, `context-glossary/*`, `rejected-decisions-memory/*`. |
| 3 | `docs/batches/default/STREAM_LOG.md` + `BATCH_PLAN.md` | Append-only history rows. |
| 4 | `.harness/insight-index.md` | Existing lines describe past states; this task's insight is appended at delivery/archive time, not now. |
| 5 | `.claude/settings.json:3-4` | `v0.44.0 / T-12` provenance prose, not the current release. |
| 6 | `.gitignore:58`, `75-safety-hook.md:10`, the `verify_all.{sh,ps1}` T-12 comments | `(T-12, v0.44.0)` attributions. D1 and D3 **append** to the body without rewriting them. |
| 7 | `skills/harness-status/SKILL.md` | Asset rows structurally pinned by `test-supervisor.{ps1,sh}` (insight 2026-06-11); no status asset row is touched here (T-14's). |
| 8 | `skills/harness-init/SKILL.md:187-190`, `skills/harness-adopt/SKILL.md:311-314` | Prose copies of the byte-forms, T-16's to retire; touching them fails out-of-scope §3.2. |
| 9 | README `verify__all-32%2F32` and `test--init-<n>` badges | See D9/D10 — version badge only. |
| 10 | **`docs/tasks.md` — T-13 ID COLLISION (W-3)** | The Completed row at **:48** is a *different*, historical `T-13 lang-policy-split` (v0.24.0), and a developer grepping `T-13` hits it first. The Completed table is append-only: never touch :48 or any other completed row. The only edit is the Active-table row at **:9** (D11). |
| 11 | `.harness/rules/10-self-consistency.md:7` | "the 7 agents and `harness-sync` scripts" — a numerically identical decoy about the **agent** count, not the mirror set. Frozen (its v0.30 staleness is pre-existing, out of scope). |

## 12. Autonomous decisions logged (Mode 2)

| # | Decision | Justification |
|---|---|---|
| D-1 | The spec also answers `event`, `matcher`, `hostos` (addition) | FR-8 requires the installer to wire four *named events* and B-11 the *existing* OS discrimination — otherwise every consumer restates the mapping. Gate-adjudicated JUSTIFIED; kept as designed, OQ-8 untouched. |
| D-2 | OQ-5 sharpened: the installer divergence is CRLF-throughout, not one trailing newline (gate-verified byte-for-byte) | `.gitattributes:7` pins `*.ps1 text eol=crlf` unconditionally and `install-hooks.ps1` is CRLF throughout (73/73), so its `@'…'@` here-string emits a `/bin/sh` `pre-commit` with CRLF endings. Fix: line array → join with `` "`n" `` → one trailing `` "`n" `` → `[System.IO.File]::WriteAllText`, for the pre-commit **and** settings bodies (W-4, B2). |
| D-3 | The mirror-set count moves 7 → 8 although AC-12 forbids a count change by letter (scope call) | Read as intent, AC-12 pins the gate-enforced release claims; OQ-1a + OQ-4a make the move unavoidable. Resolved by fanning it out at all **five** live sites (§11), not by declining OQ-1a. Gate-accepted. |
| D-4 | F-2 resolved by option **(a)** (oracle = the derivation helpers), not (b) | (a) costs one extraction helper per shell, uses an oracle AC-3's own text names, and upgrades the evidence from "4 of 8 compared to a hand copy of themselves" to "8 of 8 vs a live, independently maintained implementation". (b) would have kept a weaker proof *and* forced a stage-1 rollback to relax an AC that is already satisfiable — worse on both axes. Residual: cross-*shell* twin equality (NFR-5), not cross-OS coverage. **Nothing is appended to `.harness/rejected-decisions.md`** — the rejected OQ options were declined *by the RA* (their doc is the record) and (b) is a within-task alternative resolved by evidence, not a standing decline; `CONTEXT.md` already carries both new terms, so no glossary edit. |

## 13. Risk analysis

| # | Risk | L/I | Mitigation |
|---|---|---|---|
| R-1 | `hook-spec.ps1` ships parse-broken or throws on first call (PS is agent-unexecutable; insight 2026-06-21 (2) — this exact class shipped in T-12) | med / high | Mandated PS idioms in §3.1: single-quoted literals with `-f`, no double-quote concat, no automatic-variable parameter names, no here-strings. NFR-5 operator gate: `[Parser]::ParseFile` every touched `.ps1`, then run `install-hooks.ps1` and `test-init.ps1` on Windows. Recorded in `_qa_note_t13` and in 07_DELIVERY as a mandatory operator item. |
| R-2 | Interim duplication of the byte-forms is wider than "spec + four helpers" (W-6) | high / med | Accepted and bounded, but now **enumerated**: the four un-re-pointed helpers, the two SKILL.md prose tables, the `test-init` fixtures, plus `test-harness-upgrade.sh:296,306` / `.ps1:296` (JSON-escaped) and `.sh:555` / `.ps1:599,603,608` (raw-shell / raw-`pwsh` guard command — a different escaping level the spec does not emit under OQ-2a). All are named in the spec's header comment (§3.1) so T-16 cannot declare victory with them live. Baselines for `test-harness-upgrade` stay 89/89 — it is not edited here. |
| R-3 | The bootstrap silently re-arms hooks an operator deliberately disabled | low / high (trust) | §8 row 3 never overwrites an existing local file (incl. non-regular, unparseable, empty-`hooks`); B-7's empty-`hooks` opt-out is the documented persistent off switch; FR-15 writes it into both `75-safety-hook.md` twins; FR-12's loud report makes any creation visible with its own undo line. Direction of risk is restore-only (NFR-2). |
| R-4 | The shallow settings probe (§3.2) misjudges an exotic but legal JSON layout | med / med | Whitespace-tolerant, anchors on the quoted key; minified `{"hooks":{}}` classifies correctly. Misjudgment fails **safe**: `present` → no bootstrap; `unparseable` → exit 3, nothing written — never a wrong *write*. §9 step 2 asserts classification on real fixtures. |
| R-5 | Generated settings file passes the bash gate but fails on Windows (gate Minor 2) | low / high (gate red) | §4 pins the layout to today's `.claude/settings.local.json` (passes J.1), doc keys at root only, `$schema` with `.json`, BOM-free, upstream schema consulted first. Note the asymmetry: `verify_all.ps1:290-291` hard-parses the local settings with `ConvertFrom-Json` while `verify_all.sh:304` only greps — a file byte-valid to bash but malformed JSON passes on bash and **FAILs on Windows**. One more reason NFR-5's operator run is binding; carry one line into 07_DELIVERY. |
| R-6 | The `test-init` fixture restructure perturbs the pre-existing exact-string assertions | med / med | The restructure is a pure re-binding (§9) — the four `*_COMMAND` variables hold exactly the bytes they hold today, and populating them from `hook-spec` is prohibited. A captured run must show the pre-existing assertions green and only new ones added. |
| R-7 | The §9 oracle loader silently extracts nothing (awk range / AST miss) and the 8 comparisons degrade | med / high | The mandatory anti-vacuity assertion (§9) fails loudly before Group A runs; QA's artifact mutation must turn Group A red for exactly the mutated cells. If `upgrade-project`'s function header is ever reformatted, that assertion — not the 8 — is what goes red, which is the diagnosable failure. |
| R-8 | Concurrent or failed write leaves a half-written file wiring a truncated guard | low / high | Temp-then-rename + terminal re-read from disk (§6 steps 6-7, FC-4). A failed write leaves the target **absent**, not partial. |

## 14. Migration / rollout plan

1. **Backwards compatibility / flags / data migration.** Nothing existing reads `hook-spec`;
   already-initialized projects are unaffected unless their operator runs `install-hooks`, and §8
   rows 2-3 make the common case a no-op report. AC-3 pins the byte-forms, so no hook command
   changes (NFR-1). No flag, no data migration: the bootstrap is condition-gated, one-shot,
   operator-invoked, creates the file only when absent, and never reads, rewrites or backs up an
   existing one.
2. **Order of work.** (a) spec pair in `templates/common/` → `sync-self` → E.1 green;
   (b) `sync-self` mapping + F.1 arrays; (c) installer in `templates/common/` → `sync-self`;
   (d) `test-init` restructure + oracle loader + new blocks → capture run → baseline; (e) docs +
   version fan-out incl. all five count sites; (f) capture `verify_all` 32/0/0 + `test-init` +
   `test-real-project`; (g) delete the dogfood `.claude/settings.local.json`, re-run the installer,
   re-run `verify_all` (AC-5/AC-8), demonstrate AC-9 both directions.
3. **Rollback.** Additive plus one localized installer edit — `git revert` restores the prior state.
   The only untracked side effect is a regenerated, gitignored `.claude/settings.local.json`, reproducible by re-running the installer.
4. **Operator verification (binding, NFR-5).** On Windows: `[Parser]::ParseFile` on every touched
   `.ps1`; `install-hooks.ps1` in a clone with the local settings file deleted; `test-init.ps1`;
   `verify_all.ps1` (which, unlike bash, hard-parses the generated local settings — R-5); then
   reconcile `test_init_ps_assertions`. AC-10 and the cross-shell half of §9 stay
   green-by-symmetry-only until that run.

## 15. Out-of-scope clarifications (design boundaries)

- The design does **not** re-point `upgrade-project.{ps1,sh}`, `migrate-scripts-layout.{ps1,sh}` or
  the two SKILL.md prose tables at the spec, and needs none of them to move for any AC. §9 *reads*
  `upgrade-project`'s helper as a test oracle; it does not modify that file. §5.2 fixes the call
  shape so T-16 needs no redesign.
- No `verify_all` check is added, removed or narrowed. F.2 keeps its current settings-file selection
  (T-15); the health report's fixed-file assumption is untouched (T-14). This repo's hooks stay in
  the machine-local file; the committed `.claude/settings.json` keeps `"hooks": {}` and the published
  plugin keeps shipping none.
- The spec owns no placeholder token names and no substitution map (OQ-8a), and emits only the
  JSON-string-body escaping level (OQ-2a) — the raw-shell form used by `test-harness-upgrade`'s
  Fixture Z is deliberately not designed, which is why that copy survives T-16 (R-2). The installer
  does not edit `.gitignore`, create a backup, install itself into any hook or session-start path,
  or read/write any settings file other than the two named in §8; concurrency uses no lock (B-10),
  atomicity comes from temp-then-rename.

## 16. Verdict

**READY** — both FAIL-severity conditions are resolved on independently re-verified evidence. The
count ledger names five live sites, records the search that closed the set, and moves no frozen
claim (F-1); the AC-3 proof drops the false transitivity claim and compares the spec against a live,
OS-parametric derivation helper for all 8 combinations — independent, none host-OS-only — with the
residual cross-shell gap stated rather than papered over (F-2). W-1…W-4, W-6 and both Minors are
folded in at the cited sections. The guard stays fail-CLOSED everywhere, the check count stays 32, no out-of-scope boundary is approached, and no design decision is left to the Developer.
