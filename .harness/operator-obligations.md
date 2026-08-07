# Operator obligations — the standing release-gating list

> **What this is.** Every release-gating **operator obligation** this repository owes: a step a human
> operator must perform, on a host this repository's agents cannot reach, before a release is safe.
> Almost all of them are PowerShell work — `pwsh` is not installed on the development host, so every
> `.ps1` in this repository ships green-by-symmetry only and no agent here can discharge any of these.
> **This is the only home.** A standing operator obligation is not written in
> `.harness/scripts/baseline.json`, which pins numeric baselines only, and not in an archived stage
> document. Where each entry's text came from is recorded in that entry's own origin field.
> **Fields.** An entry is one `###` heading followed by exactly seven field lines, one per physical
> line, in this order: id, action, artifacts, pass observable, security, origin, last discharged. The
> heading is navigation only and is not counted. No example entry is rendered anywhere in this file,
> deliberately: a rendered first field line would be counted by the command under `## How to count`.
> **Appending.** A new obligation is appended with the next unused id. No existing entry is
> renumbered, merged, split, reordered or dropped, and an id is never reused, including after the
> obligation is discharged. Ids `1`–`17` are bare integers, because archived documents cite them by
> that integer. An obligation that carries no global integer takes its origin task's handle as a
> namespace (`T13-<n>`) and keeps the ordinal its **enumerating** source assigns it.
> **Discharge.** `Last discharged` reads exactly one of `never`, `<YYYY-MM-DD> against <40-hex-sha>`,
> or `<YYYY-MM-DD> against <40-hex-sha>+dirty`, where the sha is `git rev-parse HEAD` of this
> repository at the moment of the run. `+dirty` is appended when `git status --porcelain` was
> non-empty for any path in that entry's artifacts field, and always reads as **not** discharged. An
> entry is stale when `git diff --quiet <sha> HEAD -- <that entry's artifact paths>` exits non-zero,
> and a discharge recorded against a different artifact state is read as **not** discharged. An entry
> whose artifact is generated rather than tracked pins the generator named in its artifacts field
> instead; where the source span names no generator, the sha pins the repository alone and the record
> is weaker by exactly that much.
> **Size and reach.** No `verify_all` size check measures this path, so this file carries no gated
> cap and no rotation; `I.6`, the retired-claim guard, does scan it, at FAIL severity. No agent is
> instructed to read this file at task start and no script reads it, so it is on no always-read path
> and its absence breaks no execution path.
> **Disclosure.** Four entries quote a release-gate check count inside transcribed obligation text
> (ids 7, 11, 14 and 17). No check reads those figures. Each sits inside quoted obligation text whose
> origin field names the task that stated it, so a later change to the gate's check count makes that
> *obligation* stale rather than this file wrong. The general problem — one number restated in many
> ungated places — is entropy finding EP-003, which owns it.

## How to count

The size of the set is the number of entries, and no total is stored anywhere in this file. Run this
from the repository root:

```
grep -c '^- Id: ' .harness/operator-obligations.md
```

It counts the first field line of every entry, so "count entries" and "count ids" cannot disagree.
The published line itself begins with `grep`, so it never matches its own pattern. On a file holding
no entries the command prints `0` and exits **1** — grep's documented no-match status, not an error.

## Numbered obligations

### 1 — ParseFile sweep over the guard pair

- Id: 1
- Action: `[Parser]::ParseFile` over **`.harness/scripts/guard-rm.ps1`**, its template twin, and **`.harness/scripts/test-guard-rm.ps1`**. PowerShell parses the whole file before executing, so a syntax error in a never-taken branch is fatal to the entire guard.
- Artifacts: `.harness/scripts/guard-rm.ps1`, its template twin, `.harness/scripts/test-guard-rm.ps1`
- Pass observable: not stated in source
- Security: no
- Origin: T-17 `guard-cmd-chain`. Enumerating source `docs/features/_archived/guard-cmd-chain/04_DEVELOPMENT.md:467-469`. Also restated, more narrowly (it omits the template twin), at `.harness/scripts/baseline.json:_qa_note_t17` in the span this task excised into this file.
- Last discharged: never

### 2 — test-guard-rm.ps1 run and key pin

- Id: 2
- Action: Run `pwsh -File .harness/scripts/test-guard-rm.ps1` (**87** rows) and, separately, with `-Guard <template-path>`. Expect `PASS: 87 / FAIL: 0`; then pin `test_guard_rm_ps_assertions` in `baseline.json` **from that run**. The key is deliberately absent today — do not invent one. Figure amended per R-5: the enumerating span says "(81 rows) … Expect `PASS: 81`", and `guard-cmd-chain/07_DELIVERY.md:118-120` records that as a known inconsistency against item 9 and rules "**The correct figure is 87.**" The superseded `81` is not restated.
- Artifacts: `.harness/scripts/test-guard-rm.ps1`, its template twin passed as `-Guard <template-path>`, `baseline.json` (this repository's `.harness/scripts/baseline.json`)
- Pass observable: `PASS: 87 / FAIL: 0` from both invocations, and `test_guard_rm_ps_assertions` pinned in `baseline.json` transcribed from that run
- Security: no
- Origin: T-17 `guard-cmd-chain`. Enumerating source `docs/features/_archived/guard-cmd-chain/04_DEVELOPMENT.md:470-473`; amending source `docs/features/_archived/guard-cmd-chain/07_DELIVERY.md:118-120`; corroborated by `.harness/scripts/baseline.json:_qa_note_t17` (87 rows), in the span this task excised into this file.
- Last discharged: never

### 3 — no exception escapes the scanner

- Id: 3
- Action: **Highest-probability defect (R11), and it fails OPEN:** the scanner is lookahead-heavy. Every lookahead goes through `Get-Slice`, which is length-guarded, and `Split-CommandPositions` is wrapped in `try/catch → return $null`. Confirm no exception escapes: an escaping terminating error under `$ErrorActionPreference = 'Stop'` exits **1**, which Claude Code treats as non-blocking, silently disarming the Windows guard. A green symmetry review cannot detect this.
- Artifacts: none stated in source
- Pass observable: no exception escapes the scanner; the failure signature is exit **1** under `$ErrorActionPreference = 'Stop'`, which Claude Code treats as non-blocking
- Security: yes
- Origin: T-17 `guard-cmd-chain`. Enumerating source `docs/features/_archived/guard-cmd-chain/04_DEVELOPMENT.md:474-478`; marked a security item at `docs/features/_archived/guard-cmd-chain/07_DELIVERY.md:115-117`.
- Last discharged: never

### 4 — override prefix is case-sensitive

- Id: 4
- Action: Confirm the **override prefix is case-SENSITIVE**: `StartsWith(…, [StringComparison]::Ordinal)` is deliberate; PS `-eq`/`-match` are case-insensitive and would accept `harness_allow_outside_rm=1`, a widening. Probe `HARNESS_ALLOW_OUTSIDE_RM=1 rm -rf C:\x` (exit 0 + audit line) and `harness_allow_outside_rm=1 rm -rf C:\x` (expect exit 2).
- Artifacts: none stated in source
- Pass observable: `HARNESS_ALLOW_OUTSIDE_RM=1 rm -rf C:\x` → exit 0 plus an audit line; `harness_allow_outside_rm=1 rm -rf C:\x` → exit 2
- Security: no
- Origin: T-17 `guard-cmd-chain`. Enumerating source `docs/features/_archived/guard-cmd-chain/04_DEVELOPMENT.md:479-482`.
- Last discharged: never

### 5 — driver row quoting did not pre-expand

- Id: 5
- Action: Confirm the new driver's row quoting did not pre-expand: PS hashtable values are single-quoted for every row containing `$`, a backtick or `$(` — a double-quoted `@{ cmd = "echo $(rm …)" }` would invoke the subexpression at array-definition time and really delete the path. Check that row `i`, `C10a`, `C11a`, `C11b` and `W4` echo back **literally** in their PASS lines.
- Artifacts: none stated in source
- Pass observable: rows `i`, `C10a`, `C11a`, `C11b` and `W4` echo back literally in their PASS lines
- Security: no
- Origin: T-17 `guard-cmd-chain`. Enumerating source `docs/features/_archived/guard-cmd-chain/04_DEVELOPMENT.md:483-486`.
- Last discharged: never

### 6 — backtick literal and no automatic-variable collision

- Id: 6
- Action: Confirm `$BackTick = [string][char]0x60` and the `$specialScanChars` array parse and behave (they replace backtick-quoted literals precisely to avoid a whole-file parse hazard), and that no new variable collides with an automatic (`$stIn`, `$sqAnsi`, `$nestKind`, `$nestTop`, `$hdQueue`, `$prevCh`, `$posList` were chosen for this reason).
- Artifacts: none stated in source
- Pass observable: `$BackTick` and the `$specialScanChars` array parse and behave; no new variable collides with a PowerShell automatic variable
- Security: no
- Origin: T-17 `guard-cmd-chain`. Enumerating source `docs/features/_archived/guard-cmd-chain/04_DEVELOPMENT.md:487-490`.
- Last discharged: never

### 7 — verify_all.ps1 and sync-self.ps1 re-run

- Id: 7
- Action: Re-run `pwsh -File .harness/scripts/verify_all.ps1` (expect **32/0/0**) and `pwsh -File .harness/scripts/sync-self.ps1 --check` (expect "In sync.").
- Artifacts: `.harness/scripts/verify_all.ps1`, `.harness/scripts/sync-self.ps1`
- Pass observable: `32/0/0` from `verify_all.ps1`; `In sync.` from `sync-self.ps1 --check`
- Security: no
- Origin: T-17 `guard-cmd-chain`. Enumerating source `docs/features/_archived/guard-cmd-chain/04_DEVELOPMENT.md:491-492`. This entry quotes a release-gate check count — see the disclosure in this file's header.
- Last discharged: never

### 8 — $redirIdx initialisation and the redirect probes

- Id: 8
- Action: **Row 12 / `$redirIdx` in `Split-CommandPositions`.** Confirm `$redirIdx` (no collision with a PS automatic variable) is initialised **before** the scan loop and that `if ($redirIdx -eq ($i - 1))` is an integer comparison, not a string one — PS `-eq` on a string left operand would compare `'-1'` to an int and could mis-branch. A wrong result in the "append" direction is the only fail-**open** direction here; a wrong result in the "flush" direction merely over-blocks. **Amended in round 3:** `$redirIdx` is now initialised to **`-2`**, not `-1`; confirm the literal is an `[int]` and that `if ($redirIdx -eq ($i - 1))` is still an integer comparison. Five probes: `echo a\>& rm -rf C:\x` (expect exit 2), `echo a\<& rm -rf C:\x` (expect 2), `echo a>& rm -rf C:\x` (expect 0), `& rm -rf C:\x` (expect **2**) and `pwsh -c "& Remove-Item -Recurse C:\Windows"` (expect **2**). The last two were exit 0 on the bash twin before round 3's fix.
- Artifacts: none stated in source
- Pass observable: `echo a\>& rm -rf C:\x` → 2; `echo a\<& rm -rf C:\x` → 2; `echo a>& rm -rf C:\x` → 0; `& rm -rf C:\x` → 2; `pwsh -c "& Remove-Item -Recurse C:\Windows"` → 2
- Security: no
- Origin: T-17 `guard-cmd-chain`. Enumerating source `docs/features/_archived/guard-cmd-chain/04_DEVELOPMENT.md:830-836`, amended at `:1230-1233`. The two round-3 probes are also stated at `.harness/scripts/baseline.json:_qa_note_t17` in the span this task excised into this file.
- Last discharged: never

### 9 — test-guard-rm.ps1 at 87 rows, key still absent

- Id: 9
- Action: Re-run `test-guard-rm.ps1` at **87** rows (`R4`/`R5` are new) and pin `test_guard_rm_ps_assertions` from that run — the key is still deliberately absent. Figure amended per R-5: round 2 said 85 rows with `R1 R2 R3 H1` new; `guard-cmd-chain/04_DEVELOPMENT.md:1234-1235` supersedes it with 87. The superseded `85` is not restated.
- Artifacts: `.harness/scripts/test-guard-rm.ps1`, `baseline.json` (this repository's `.harness/scripts/baseline.json`)
- Pass observable: a `test-guard-rm.ps1` run of 87 rows, from which `test_guard_rm_ps_assertions` is transcribed
- Security: no
- Origin: T-17 `guard-cmd-chain`. Enumerating source `docs/features/_archived/guard-cmd-chain/04_DEVELOPMENT.md:837-838`, amended at `:1234-1235`. Also restated at `.harness/scripts/baseline.json:_qa_note_t17` ("a test-guard-rm.ps1 run at 87 rows, then pin the key from THAT run") in the span this task excised into this file.
- Last discharged: never

### 10 — only a PS run distinguishes symmetric-in-fact

- Id: 10
- Action: The PS twin's defect and its fix were both symmetric to bash, so a PS run is the *only* thing that can distinguish "symmetric by construction" from "symmetric in fact" here. This is a **security** item, not polish: the vector `pwsh -c "& …"` is a PowerShell one.
- Artifacts: none stated in source
- Pass observable: not stated in source
- Security: yes
- Origin: T-17 `guard-cmd-chain`. Enumerating source `docs/features/_archived/guard-cmd-chain/04_DEVELOPMENT.md:1236-1238`; marked a security item at `docs/features/_archived/guard-cmd-chain/07_DELIVERY.md:115-117`.
- Last discharged: never

### 11 — verify_all.ps1 F.2, five legs

- Id: 11
- Action: `verify_all.ps1` `F.2` (T-15). (a) `[Parser]::ParseFile` over `.harness/scripts/verify_all.ps1` — PowerShell parses the whole file before executing, so a syntax error in the rewritten `F.2` block kills the entire gate on Windows. (b) Run `pwsh -File .harness/scripts/verify_all.ps1`; expect `PASS 32 / WARN 0 / FAIL 0` and confirm the `[F.2]` line prints the **new** label. (c) Confirm `F.2` PASSes with no `.claude/settings.local.json` present — **in a fresh clone or the scratch tree, never by moving or emptying the live file**. (d) Multi-problem rendering: with the template's `{{GUARD_COMMAND}}` removed **and** one **template** guard script renamed at the same time (never `.harness/scripts/guard-rm.*` — that is the live fail-closed hook), confirm the FAIL detail names **both** problems in one message (this is the `-join`-precedence / accumulator check) and that the status is `FAIL`, not `WARN`. Expect `[E.1]` to be red as well while the template script is renamed — that is the mirrored-pair co-fire, not a defect; do **not** run `sync-self` in write mode to clear it. Restore both by renaming/editing back. (e) Confirm the `[F.2]` line never prints `WARN`: a WARN here would mean a statement in the block leaked to the pipeline (§3.2 hazard 5), and WARN exits 1.
- Artifacts: `.harness/scripts/verify_all.ps1`, `.claude/settings.local.json`, `.harness/scripts/guard-rm.*`, the template guard script, the settings template's `{{GUARD_COMMAND}}` placeholder
- Pass observable: `PASS 32 / WARN 0 / FAIL 0`; the `[F.2]` line prints the new label; `F.2` PASSes with no `.claude/settings.local.json` present; under (d) the FAIL detail names both problems in one message with status `FAIL`, not `WARN`, and `[E.1]` is red at the same time; `[F.2]` never prints `WARN`
- Security: no
- Origin: T-15 `hook-truth-verify-scope`. Enumerating source `docs/features/_archived/hook-truth-verify-scope/04_DEVELOPMENT.md:662-676` (the blockquote); `docs/features/_archived/hook-truth-verify-scope/07_DELIVERY.md:122` names the item but does not carry its text. This entry quotes a release-gate check count — see the disclosure in this file's header.
- Last discharged: never

### 12 — upgrade-project.ps1 security-relevant surface

- Id: 12
- Action: `upgrade-project.ps1` — SECURITY-RELEVANT: (a) `[System.Management.Automation.Language.Parser]::ParseFile` over BOTH copies (`.harness/scripts/` and `skills/harness-init/templates/common/.harness/scripts/`); (b) on an 8-cell brittle fixture, `pwsh -File .harness/scripts/upgrade-project.ps1 -TemplateRoot <abs> -Type generic`, confirm all eight written `"command"` values are byte-equal to the pre-change capture and the guard-rm values carry no exit 0; (c) repeat on a 4-token placeholder fixture and confirm the four `RESULT|REWIRE-PLACEHOLDER` lines; (d) delete `hook-spec.ps1` from the template root, the script's sibling directory and the project, re-run: expect NO settings write, four `GAP|hook-spec|absent|` records naming 'not found', and exit 4 from the terminal congruence scan on the token fixture; then with the spec present but its hostos branch edited to exit 2, expect the single 'host OS undeterminable' `GAP|` record, all four tokens still present, and exit 4 (NOT exit 1 — this is the `$phOpen`-binding branch; the bash twin was the one that could have exited 1 and its fix is measured); re-run each: identical output, no `.bak` churn; (e) confirm the host-OS boolean is `$hsIsWin` (never `$isWindows` — read-only automatic), that `$IsWindows` no longer appears in the S3.0 hook-wiring path, and that `Get-ResilientCmd` is GONE; (f) AC-4 Windows runtime half: from the settings file the FLOW WROTE, extract the `PreToolUse` `"command"` value, pipe `{"tool_input":{"command":"rm -rf C:\\Windows"}}` into it with `guard-rm.ps1` PRESENT (expect non-zero), then DELETE `guard-rm.ps1` and repeat (expect non-zero again — fail-CLOSED).
- Artifacts: `.harness/scripts/upgrade-project.ps1` and its `skills/harness-init/templates/common/.harness/scripts/` copy, `hook-spec.ps1`, `guard-rm.ps1`, the settings file the flow wrote
- Pass observable: all eight written `"command"` values byte-equal to the pre-change capture with no exit 0 on the guard-rm values; four `RESULT|REWIRE-PLACEHOLDER` lines; with the spec deleted, no settings write, four `GAP|hook-spec|absent|` records naming 'not found' and exit 4; with the hostos branch exiting 2, one 'host OS undeterminable' `GAP|` record, four tokens still present and exit 4 (not exit 1); identical output and no `.bak` churn on re-run; `$hsIsWin` present, `$IsWindows` and `Get-ResilientCmd` absent; the piped payload exits non-zero both with `guard-rm.ps1` present and with it deleted (fail-CLOSED)
- Security: yes
- Origin: T-16 `hook-truth-derivation`. Enumerating source `.harness/scripts/baseline.json:_qa_note_t16` item (12), in the span this task excised into this file; marked SECURITY-RELEVANT there, and the same note records the security-marked count moving from 2 to 4. A longer round-1 variant survives at `docs/features/_archived/hook-truth-derivation/02_SOLUTION_DESIGN.md:1072-1084` and is corroborating only — the note amended it, so no detail is imported from it.
- Last discharged: never

### 13 — migrate-scripts-layout.ps1 security-relevant surface

- Id: 13
- Action: `migrate-scripts-layout.ps1` — SECURITY-RELEVANT: (a) `ParseFile` over both copies; (b) run on the 8-cell fixture, same eight-value byte comparison; (c) spec removed: confirm the `SPEC-GAP` plan lines naming 'not found', exit 0, no `.bak`, and an identical second run; (d) confirm `Get-ResilientCmd` is gone and that the adapter block still sits where the helper sat WITHOUT reading `$dstDir` at load time (the script must run to completion when invoked from a directory with no `.harness/scripts/`); (e) AC-4 Windows runtime half as 12(f), on the settings file THIS flow wrote.
- Artifacts: `.harness/scripts/migrate-scripts-layout.ps1` and its `skills/harness-init/templates/common/.harness/scripts/` copy, the settings file this flow wrote
- Pass observable: the eight-value byte comparison holds on the 8-cell fixture; with the spec removed, `SPEC-GAP` plan lines naming 'not found', exit 0, no `.bak`, and an identical second run; `Get-ResilientCmd` absent and the script running to completion from a directory with no `.harness/scripts/`; the 12(f) payload exiting non-zero both with `guard-rm.ps1` present and with it deleted (fail-CLOSED)
- Security: yes
- Origin: T-16 `hook-truth-derivation`. Enumerating source `.harness/scripts/baseline.json:_qa_note_t16` item (13), in the span this task excised into this file; marked SECURITY-RELEVANT there. A longer round-1 variant survives at `docs/features/_archived/hook-truth-derivation/02_SOLUTION_DESIGN.md:1072-1084` and is corroborating only.
- Last discharged: never

### 14 — verify_all.ps1 F.2 containment window

- Id: 14
- Action: `verify_all.ps1` F.2 containment: (a) `ParseFile`; (b) `pwsh -File .harness/scripts/verify_all.ps1` -> `PASS 32 / WARN 0 / FAIL 0` with the check count read from the run; (c) apply mutation M-C (`settings.json.tmpl`: move `{{GUARD_COMMAND}}` into the Stop block and replace the whole PreToolUse block with the single line `    "PreToolUse": [],`) and confirm F.2 FAILs with EXACTLY `guard_command_not_in_PreToolUse` and `PreToolUse_no_command_entry` in one accumulated message (this is also the `-join`-precedence check); revert; (d) confirm `[F.2]` never prints WARN (a WARN means a statement leaked to the pipeline, and `verify_all` exits 1 on warns > 0); (e) totality case: in a scratch copy of `settings.json.tmpl` move the whole `"PreToolUse"` block so it is the LAST key inside `hooks` and confirm `[F.2]` still PASSes — the PS half is the one whose `..` range operator would silently reverse if `$end < $start` (it cannot: the smallest terminator is `$start+1`). The bash twin of (b), (c) and (e) was measured on this host: 32/0/0 unmutated, 31/0/1 with exactly those two tokens under M-C, and 32/0/0 on the reordered template.
- Artifacts: `.harness/scripts/verify_all.ps1`, `settings.json.tmpl`
- Pass observable: `PASS 32 / WARN 0 / FAIL 0` with the check count read from the run; under M-C, F.2 FAILs with exactly `guard_command_not_in_PreToolUse` and `PreToolUse_no_command_entry` in one accumulated message; `[F.2]` never prints WARN; `[F.2]` still PASSes on the reordered template. Bash-twin reference figures, measured: 32/0/0 unmutated, 31/0/1 under M-C, 32/0/0 reordered.
- Security: no
- Origin: T-16 `hook-truth-derivation`. Enumerating source `.harness/scripts/baseline.json:_qa_note_t16` item (14), in the span this task excised into this file. This entry quotes a release-gate check count — see the disclosure in this file's header.
- Last discharged: never

### 15 — test-init.ps1 run and badge reconciliation

- Id: 15
- Action: `test-init.ps1`: (a) `ParseFile`; (b) `pwsh -File .harness/scripts/test-init.ps1` — confirm the driver REACHES its `=== Result ===` line (a run that terminates without it is a FAILURE, not a pass — insight 2026-07-31) and reports 316, unchanged; (c) confirm the `[T-16][oracle]`, `[T-16][A]` (x8) and `[T-16][A']` (x8: 4 idiom rows + 4 substitution-discipline rows) rows are green, that no row still names `Get-ResilientCmd`, and that the per-cell loop now carries 2 Asserts per cell (not 3) with the A' block OUTSIDE it, so the total is unchanged; (d) reconcile `test_init_ps_assertions` and the README test-init badge TOGETHER, and only if that run moves the number.
- Artifacts: `.harness/scripts/test-init.ps1`, `baseline.json` key `test_init_ps_assertions`, the README test-init badge
- Pass observable: the driver reaches its `=== Result ===` line and reports 316, unchanged; the `[T-16][oracle]`, `[T-16][A]` (x8) and `[T-16][A']` (x8) rows green; no row naming `Get-ResilientCmd`; 2 Asserts per cell in the per-cell loop with the A' block outside it
- Security: no
- Origin: T-16 `hook-truth-derivation`. Enumerating source `.harness/scripts/baseline.json:_qa_note_t16` item (15), in the span this task excised into this file. The pin-writing constraint governing (d) — that the PS assertion pins and both README PS badges stay frozen and move only together with the operator's run, never separately — stays in band with the keys it constrains, at `_qa_note_t16`.
- Last discharged: never

### 16 — parse-only sweep and test-real-project.ps1

- Id: 16
- Action: Parse-only sweep: `ParseFile` over `.harness/scripts/hook-spec.ps1`, `.harness/scripts/test-real-project.ps1` and the `templates/common/` copies of `hook-spec.ps1`, `migrate-scripts-layout.ps1` and `upgrade-project.ps1`, then `pwsh -File .harness/scripts/test-real-project.ps1` -> 90, unchanged.
- Artifacts: `.harness/scripts/hook-spec.ps1`, `.harness/scripts/test-real-project.ps1`, and the `templates/common/` copies of `hook-spec.ps1`, `migrate-scripts-layout.ps1` and `upgrade-project.ps1`
- Pass observable: `test-real-project.ps1` reports 90, unchanged
- Security: no
- Origin: T-16 `hook-truth-derivation`. Enumerating source `.harness/scripts/baseline.json:_qa_note_t16` item (16), in the span this task excised into this file.
- Last discharged: never

### 17 — archive-task PowerShell surface

- Id: 17
- Action: archive-task PowerShell surface: (a) `[System.Management.Automation.Language.Parser]::ParseFile` over BOTH `archive-task.ps1` copies (`.harness/scripts/` and `skills/harness-init/templates/common/.harness/scripts/`), over `.harness/scripts/test-archive-task.ps1` and over `.harness/scripts/verify_all.ps1` - PS parses the WHOLE file before executing, so a syntax error in a never-taken branch is fatal to the file (insight 2026-06-21); (b) `pwsh -File .harness/scripts/test-archive-task.ps1` must REACH its `=== test-archive-task summary ===` block (a run that terminates without it is a FAILURE, not a pass - insight 2026-07-31) and must reproduce AC-1 (wrapped harvest), AC-2 (refusal before any write, mtime unmoved), AC-3 (one file never yields two entry counts), AC-13 (break-then-entry in the DELIVERY section), AC-14 (break-then-entry in the INDEX - the fixture that closes round-1's G-1), AC-7 (I.4's unaccounted condition proven non-vacuous by mutating a COPY of the live index - added to the PS twin in code-review round 2, so the only remaining bash-only cases are AC-4, bash-only by design B-11, and BC-19, unix-only by nature) and AC-16 (the shipped `insight-index.md.tmpl` header block driven through harvest AND rotation - the fixture that closes round-1's G-3, whose damage lands in GENERATED projects, which run archive-task under PowerShell on Windows more often than under bash) and QA-1 (all SIX cases present in the PS twin - five from round 3, one from round 4 - enumerated here so the count and the list cannot disagree: (1) EVERY `## Insight` section harvested; (2) a heading inside a fenced code block is not a heading; (3) an unterminated fence refuses at exit 3; (4) the measured residual that a fence INSIDE the section is absorbed as continuation lines; (5) the bound case where a wholly fenced section harvests 0 entries but prints `Quoted headings: 1 ...`; (6) the round-4 tilde case (CR-13) - a `~~~` fence whose info string holds a backtick, containing a backtick run that must NOT close it - 31 rows, present case for case in the PS twin, and the ONLY new fenced-block logic in `archive-task.ps1`, so a PS parse failure or a .NET-vs-ERE fence-regex divergence lands exactly here); (c) B-18 byte-identity: on the AC-1 fixture, compare the PowerShell-written `.harness/insight-index.md` and `docs/features/_archived/insight-history.md` against the POST-CHANGE BASH output for the same input - LF-only, no BOM, no CR anywhere; the driver's 'AC-1 index bytes equal the expected content' row pins the index half in-driver, the history half needs the AC-16 rotation fixture; (d) confirm `archive-task.ps1` and `test-archive-task.ps1` assign NO `$Is*` automatic (every introduced variable carries an `at` prefix - the `$isWindows` read-only-automatic collision of insight 2026-06-21), that no binary `-join` sits unparenthesised beside a `+` (binary `-join` binds BELOW `+`, insight 2026-07-31), and that `Set-Content` / `Add-Content` appear NOWHERE in the index or history write path (they emit `[Environment]::NewLine` = CRLF on Windows, which breaks B-13/N-2); (e) `pwsh -File .harness/scripts/verify_all.ps1` -> `PASS 32 / WARN 0 / FAIL 0` with the check count read from the run, and `[I.4]` must read 'insight-index.md <=30 insight entries'. NOTE for (b)/(e): the two shells differ in WHERE the I.4 WARN detail is printed - PS writes it inline on the `[I.4]` line via `Write-Host -NoNewline`, while bash's `step()` prints a detail line only for FAIL, so the bash I.4 block echoes its own detail on the following line. Both name the same two counts and the same 1-based line number; the driver twins parse them accordingly.
- Artifacts: `.harness/scripts/archive-task.ps1` and its `skills/harness-init/templates/common/.harness/scripts/` copy, `.harness/scripts/test-archive-task.ps1`, `.harness/scripts/verify_all.ps1`, `.harness/insight-index.md`, `docs/features/_archived/insight-history.md`, the shipped `insight-index.md.tmpl`
- Pass observable: the driver reaches its `=== test-archive-task summary ===` block and reproduces AC-1, AC-2, AC-3, AC-13, AC-14, AC-7, AC-16 and all six QA-1 cases (31 rows); byte-identity against the post-change bash output, LF-only, no BOM, no CR; no `$Is*` automatic assigned, no unparenthesised binary `-join` beside a `+`, no `Set-Content` / `Add-Content` in the index or history write path; `verify_all.ps1` -> `PASS 32 / WARN 0 / FAIL 0` with the check count read from the run and `[I.4]` reading 'insight-index.md <=30 insight entries'
- Security: no
- Origin: T-20 `harvest-wrapped-insight`. Enumerating source `.harness/scripts/baseline.json:_qa_note_t20` item (17), in the span this task excised into this file. The pin-writing constraint governing its outcome — that only after (a)-(e) may a PowerShell tally be recorded, transcribed from that run — stays in band with the key it constrains, at `_qa_note_t20`. This entry quotes a release-gate check count — see the disclosure in this file's header.
- Last discharged: never

## Origin-qualified obligations

These eight carry no global integer. They are transcribed from the source that **enumerates** them,
`docs/features/_archived/hook-truth-spec/04_DEVELOPMENT.md:253-289` (widened at `:444-453`), and they
keep that source's ordinals. `.harness/scripts/baseline.json:_qa_note_t13` carried a **mirror** of
that enumeration which narrowed seven of the eight, was silent on one, and numbered them differently;
where the mirror states something the enumeration does not, this file carries it too, and each entry's
origin field records how the two diverged.

### T13-1 — ParseFile over every touched .ps1

- Id: T13-1
- Action: On Windows run `[…Language.Parser]::ParseFile` on every touched `.ps1`: `hook-spec.ps1` (**template + repo**), `install-hooks.ps1` (**template + repo**), `test-init.ps1`, `sync-self.ps1`, `verify_all.ps1`. The rework-3 widening of T13-8 requires `install-hooks.ps1` (template + repo) to be in this sweep.
- Artifacts: `hook-spec.ps1` (template + repo), `install-hooks.ps1` (template + repo), `test-init.ps1`, `sync-self.ps1`, `verify_all.ps1`
- Pass observable: not stated in source
- Security: no
- Origin: T-13 `hook-truth-spec`. Enumerating source `docs/features/_archived/hook-truth-spec/04_DEVELOPMENT.md:255-256`, extended at `:283-284`. The mirror at `.harness/scripts/baseline.json:_qa_note_t13`, in the span this task excised into this file, differed: it dropped both `(template + repo)` scopes and the full type name, and added `on Windows run`, which is carried above.
- Last discharged: never

### T13-2 — install-hooks.ps1 bootstrap run in a clean clone

- Id: T13-2
- Action: `pwsh -File .harness/scripts/install-hooks.ps1` in a clone with `.claude/settings.local.json` deleted: exit 0, file created with the **Windows** byte-forms, FR-12 report, idempotent re-run. T13-8's span additionally requires this step to be **re-run after that patch** (the four-distinct-events gate, added in rework 2 and widened in rework 3).
- Artifacts: `.harness/scripts/install-hooks.ps1`, `.claude/settings.local.json` (generated; the generator named here is `install-hooks.ps1`)
- Pass observable: exit 0; the file created with the Windows byte-forms; the FR-12 report; an idempotent re-run
- Security: no
- Origin: T-13 `hook-truth-spec`. Enumerating source `docs/features/_archived/hook-truth-spec/04_DEVELOPMENT.md:257-258`, with the re-run requirement at `:283-284`. The mirror at `.harness/scripts/baseline.json:_qa_note_t13`, in the span this task excised into this file, differed: it kept the run but dropped the invocation form and every pass observable.
- Last discharged: never

### T13-3 — test-init.ps1 green, then reconcile, then the badge

- Id: T13-3
- Action: `test-init.ps1` — confirm `Test-HookSpec` and `Test-InstallBootstrap` are green, then **reconcile `test_init_ps_assertions`** (still pinned at **316**, deliberately unreconciled) and only then move the README `test--init-316%2F316` badge. Both READMEs move together. Widened in rework 3: the driver has one more row, and `Test-InstallBootstrap` is **32** `Assert`s per twin — the number to reconcile `test_init_ps_assertions` against. That figure carries its own amendment: `hook-truth-spec/07_DELIVERY.md:76` records "n-9 — wording only: the operator note calls `Test-InstallBootstrap` '32 `Assert` calls'; the source has **29**, one inside a four-tool loop, yielding **32 runtime rows**. 32 is the number the operator needs, so the guidance is operationally right" (corroborated at `hook-truth-spec/06_TEST_REPORT.md:462` and `:485-486`) — so an operator counting `Assert` calls in the source should find 29, and 32 is the runtime row count to reconcile against. The added row is `test-init.ps1:1223-1252`, a SECOND FC-4 row: the stub answers `tools` with the guard id four times and it asserts exit 4 + target ABSENT + the `expected 4 DISTINCT hook events, got 1` diagnostic; its bash twin was executed and proven load-bearing by deletion mutation, the PS twin was NOT.
- Artifacts: `test-init.ps1`, `test-init.ps1:1223-1252`, `test_init_ps_assertions` in `baseline.json`, the README `test--init-316%2F316` badge in both READMEs
- Pass observable: `Test-HookSpec` and `Test-InstallBootstrap` green; `test_init_ps_assertions` reconciled from that run against `Test-InstallBootstrap`'s **32** runtime rows (29 source `Assert` calls, one inside a four-tool loop — `07_DELIVERY.md:76`); the badge moved only afterwards and in both READMEs together; on the second FC-4 row, exit 4 + target ABSENT + the `expected 4 DISTINCT hook events, got 1` diagnostic
- Security: no
- Origin: T-13 `hook-truth-spec`. Enumerating source `docs/features/_archived/hook-truth-spec/04_DEVELOPMENT.md:259-261`, widened at `:448-450`; the `32 Assert calls` figure is amended at `docs/features/_archived/hook-truth-spec/07_DELIVERY.md:76` and corroborated at `06_TEST_REPORT.md:462,485-486`. The mirror at `.harness/scripts/baseline.json:_qa_note_t13`, in the span this task excised into this file, differed and did so by splitting: it fused the run with the `ConvertFrom-Json` item at its own ordinal 3 and promoted the reconcile tail to its own ordinal 5, and it dropped both `Test-*` names, `316`, the badge token and "Both READMEs move together"; it alone carried the second FC-4 row's detail, which is carried above.
- Last discharged: never

### T13-4 — verify_all.ps1 hard-parses the generated settings file

- Id: T13-4
- Action: `verify_all.ps1` — it hard-parses the generated `settings.local.json` with `ConvertFrom-Json` (advisory A-8) where the bash twin only greps: the only place a malformed generated file surfaces, so a file byte-valid to bash can still FAIL there.
- Artifacts: `verify_all.ps1`, `settings.local.json` (generated; the generator is `install-hooks.ps1`, named in T13-2)
- Pass observable: not stated in source
- Security: no
- Origin: T-13 `hook-truth-spec`. Enumerating source `docs/features/_archived/hook-truth-spec/04_DEVELOPMENT.md:262-263`; the same document pins the mirror's own ordinal for this item at `:241` ("A-8 Carried — operator item 4"). The mirror at `.harness/scripts/baseline.json:_qa_note_t13`, in the span this task excised into this file, differed: it dropped the `A-8` handle and added the gloss "so a file byte-valid to bash can still FAIL there", which is carried above.
- Last discharged: never

### T13-5 — cross-shell byte-identity of the generated files

- Id: T13-5
- Action: **AC-10 cross-shell byte-identity** of the generated `settings.local.json` (and of the generated pre-commit hook) is unproven until step 2 (T13-2) runs and the bytes are `cmp`-compared against the bash twin's output on the same host.
- Artifacts: the generated `settings.local.json`, the generated pre-commit hook (the enumerating span names no generator for the hook; a discharge record therefore pins the repository sha alone, and is weaker by that much)
- Pass observable: the generated bytes `cmp`-equal to the bash twin's output on the same host
- Security: no
- Origin: T-13 `hook-truth-spec`. Enumerating source `docs/features/_archived/hook-truth-spec/04_DEVELOPMENT.md:264-266`; still binding per `:452-453` ("Items 1, 2, 4, 5, 7 are unchanged and still binding"). The mirror at `.harness/scripts/baseline.json:_qa_note_t13` was **silent** on this obligation: it has not travelled to the operator since T-13, and nothing ever adjudicated the omission. Carried in force; T-24 retires nothing.
- Last discharged: never

### T13-6 — seven native-command captures reach the Result line

- Id: T13-6
- Action: **(m-3, rework 1; site list re-enumerated in rework 3 — CR r-7 / QA n-8)** `test-init.ps1:1073,1120,1161,1180,1215,1246,1256` — **seven** `& pwsh … 2>&1` **native-command** captures under script-scope `$ErrorActionPreference = "Stop"`. `2>&1` on a native command is new here, and `$PSNativeCommandUseErrorActionPreference` governs exit-code→error conversion, **not** stderr→`NativeCommandError`. Rows `:1161` (exit 3), `:1215` (exit 4, arity), `:1246` (exit 4, distinct events) and `:1256` (exit 1) deliberately drive the installer's stderr paths. If PS raises there the throw escapes `Test-InstallBootstrap`'s `try`/`finally`, is caught by no `Assert`, and kills the driver mid-run. **Confirm the driver reaches its own `=== Result ===` line**; if it does not, wrap those captures so stderr cannot raise. Widened in rework 3: the site list goes 6 → **7**, re-enumerated from the current file because the round-2 and round-3 insertions shifted the tail twice and added one.
- Artifacts: `test-init.ps1` at `:1073`, `:1120`, `:1161`, `:1180`, `:1215`, `:1246`, `:1256`
- Pass observable: the driver reaches its own `=== Result ===` line; `:1161` exit 3, `:1215` exit 4 (arity), `:1246` exit 4 (distinct events), `:1256` exit 1
- Security: no
- Origin: T-13 `hook-truth-spec`. Enumerating source `docs/features/_archived/hook-truth-spec/04_DEVELOPMENT.md:267-275`, widened at `:450`. The mirror at `.harness/scripts/baseline.json:_qa_note_t13`, in the span this task excised into this file, differed: it dropped the four per-row exit-code annotations, the remedy clause and the `(m-3, rework 1 … CR r-7 / QA n-8)` provenance, and it alone carried the re-enumeration parenthetical, which is carried above.
- Last discharged: never

### T13-7 — Get-ChildItem wildcard semantics versus find -name

- Id: T13-7
- Action: **(m-4, added in rework 1)** `test-init.ps1:1140` `Get-ChildItem -Filter "settings.local.json.*"` uses the Win32 wildcard engine, whose legacy `name.*` semantics differ from the bash twin's `find -name` (`test-init.sh:938`). The target is now excluded by exact name (DEV-7), making the twins equivalent by construction — **confirm the AC-6 sibling row is green on Windows**.
- Artifacts: `test-init.ps1:1140`, `test-init.sh:938`
- Pass observable: the AC-6 sibling row green on Windows
- Security: no
- Origin: T-13 `hook-truth-spec`. Enumerating source `docs/features/_archived/hook-truth-spec/04_DEVELOPMENT.md:276-279`. The mirror at `.harness/scripts/baseline.json:_qa_note_t13`, in the span this task excised into this file, differed: it dropped the bash-twin citation, the `DEV-7` handle, the equivalence clause and the word `sibling`.
- Last discharged: never

### T13-8 — the four-distinct-events gate and both FC-4 rows

- Id: T13-8
- Action: **(added in rework 2 — the QA-flagged conditional 8th, now unconditional; widened in rework 3)** the four-distinct-events gate `install-hooks.ps1:245-259` and **both** FC-4 rows — `test-init.ps1:1190-1221` (arity) and `:1223-1252` (distinct events, added in rework 3) — are new PS code that **only the bash twins were executed for**. Include `install-hooks.ps1` (template + repo) in T13-1's `ParseFile` sweep and **re-run T13-2 after this patch**. Three PS-specific points to confirm: `Sort-Object -Unique` is case-insensitive (stricter, never looser — bound n-11), so on a *mutated* spec answering e.g. `Stop`/`stop` the PS twin refuses where bash proceeds, disclosed and record-only; the diagnostic uses `-f` because `-join` binds **looser** than `+`, so `"a" + $n + ($x -join ' ')` would silently re-associate into `("a" + $n + $x) -join " …"`, and the operator must confirm the message it builds renders correctly; and `Test-InstallBootstrap` is now **32** `Assert` calls, matching the bash twin — the number to reconcile `test_init_ps_assertions` against in T13-3. That figure carries its own amendment: `hook-truth-spec/07_DELIVERY.md:76` records "n-9 — wording only: … the source has **29**, one inside a four-tool loop, yielding **32 runtime rows**. 32 is the number the operator needs, so the guidance is operationally right" (corroborated at `06_TEST_REPORT.md:462,485-486`). Widened in rework 3: the gate's PS-side coverage is now two rows, both unexecuted. The gate is the `$nDistinct` block `@($wired | ForEach-Object { $_.event } | Sort-Object -Unique).Count`, and the FC-4 row matches the `expected 4 ids, got 3` diagnostic via an array-joined capture — never `Out-String`, which re-wraps at the host buffer width. **KNOWN BOUNDS, record-only, both narrower than what the gate closes:** (i) the gate's closure assumes `hook-spec` has exactly **four** tools — a future **fifth** tool with a fifth distinct event would reopen a narrow guardless-residue path (exit 5 leaving a guardless file that the next run blesses at exit 0); that needs an **addition** to the spec, not a degradation of it; (ii) the bash gate counts **lines** (`printf … | sort -u | wc -l`), so an `event` answer containing an **embedded newline** would pass 4-unique-of-5-lines and wire one event twice; that needs `hook-spec` rewritten to violate its own single-token totality contract, and the fix belongs in that contract, not in the installer.
- Artifacts: `install-hooks.ps1:245-259`, `test-init.ps1:1190-1221`, `test-init.ps1:1223-1252`
- Pass observable: `Sort-Object -Unique` case-insensitive (stricter, never looser); the `-f`-built diagnostic rendering correctly, with the `expected 4 ids, got 3` message matched via an array-joined capture; `Test-InstallBootstrap` at **32** `Assert` calls (29 source calls, one inside a four-tool loop, yielding 32 runtime rows — `07_DELIVERY.md:76`); the gate's two PS-side rows executed rather than assumed
- Security: no
- Origin: T-13 `hook-truth-spec`. Enumerating source `docs/features/_archived/hook-truth-spec/04_DEVELOPMENT.md:280-289`, widened at `:450-451`; the `32 Assert calls` figure is amended at `07_DELIVERY.md:76`, corroborated at `06_TEST_REPORT.md:462,485-486`; bound (i) is also stated at `04_DEVELOPMENT.md:429-432` and `07_DELIVERY.md:73`, bound (ii) at `04_DEVELOPMENT.md:418-419` and `07_DELIVERY.md:74`. The mirror at `.harness/scripts/baseline.json:_qa_note_t13`, in the span this task excised into this file, differed: it dropped all three line spans, the `n-11` handle, the worked `-join` example, the `(template + repo)` scope and "Eighth and last — no ninth", and it alone carried the `$nDistinct` byte-form, the `Out-String` warning, the array-joined capture and the KNOWN BOUNDS paragraph — all of which are carried above.
- Last discharged: never
