# Code Review — T-16 `hook-truth-derivation`

> **Provenance note (PM)**: the code-reviewer agent is read-only by contract (Read/Glob/Grep — no Write tool). It returned this report as its reply; PM persisted it verbatim at this path. Round 1.
>
> **Round 2 is appended at the end of this file** and is the operative verdict. Round 1 stays unchanged for traceability.

- **Stage**: 5 (code-reviewer), mode `full`, dispatched from a `/harness-stream` drain.
- **Inputs**: `01_REQUIREMENT_ANALYSIS.md` (READY) · `02_SOLUTION_DESIGN.md` (round 2, incl. §18) · `03_GATE_REVIEW.md` (**round 2 operative** — APPROVED FOR DEVELOPMENT with binding conditions F-12/F-13) · `04_DEVELOPMENT.md`.
- **Method**: every changed file read in full or at the changed region; both twins of every pair read; the four flows audited **as two sibling pairs** in **both** shells; repo-wide greps run by me rather than inherited. Nothing in `04_DEVELOPMENT.md` was accepted as evidence for a claim I could check by reading.
- **What I cannot do**: execute anything. No bash run, no `pwsh` (absent on this host), no `git`, no `stat`. Every claim below is either read from a file or explicitly marked unverified-by-me (§"Unverified by inspection").
- **deferred-human**: defer, do not ask. Mode 2 (balanced). No `BLOCKED: NEEDS-HUMAN` point arose.

---

## Files reviewed

**Flows (8 files — 4 pairs, repo copy + `templates/common/` source)**
- `.harness/scripts/upgrade-project.sh` · `skills/harness-init/templates/common/.harness/scripts/upgrade-project.sh`
- `.harness/scripts/upgrade-project.ps1` · `skills/harness-init/templates/common/.harness/scripts/upgrade-project.ps1`
- `.harness/scripts/migrate-scripts-layout.sh` · `skills/harness-init/templates/common/.harness/scripts/migrate-scripts-layout.sh`
- `.harness/scripts/migrate-scripts-layout.ps1` · `skills/harness-init/templates/common/.harness/scripts/migrate-scripts-layout.ps1`

**Spec (4 files)**
- `.harness/scripts/hook-spec.sh` · `.harness/scripts/hook-spec.ps1` · both `templates/common/` twins

**Gate** — `.harness/scripts/verify_all.sh` · `.harness/scripts/verify_all.ps1`

**Tests** — `.harness/scripts/test-init.sh` · `.harness/scripts/test-init.ps1` · `.harness/scripts/test-real-project.sh`

**Prose / memory / data** — `skills/harness-init/SKILL.md` · `skills/harness-adopt/SKILL.md` · `AI-GUIDE.md` · `docs/getting-started.md` · `.harness/rules/60-tool-handoff.md` · `.harness/rejected-decisions.md` · `CONTEXT.md` · `.harness/scripts/baseline.json` · `CHANGELOG.md` · `docs/dev-map.md`

**Read to prove *un*changed** — `skills/harness-init/templates/common/.claude/settings.json.tmpl` (M-C reverted) · `.harness/rules/75-safety-hook.md` · `.harness/scripts/sync-self.sh` · `guard-rm.*` / `test-guard-rm.*` / `evals/guard-rm-cases.md` (by repo-wide grep)

---

## The four hardest questions, answered from the shipped code

### 1. Byte-identity — the chain holds end to end, in both shells

**Bash.** `hook-spec.sh:119-134` emits with `printf '%s\n'`. `hsa_query` captures with `v="$(bash "$hsa_bin" "$@" 2>/dev/null)"` (`upgrade-project.sh:155`, `migrate-scripts-layout.sh:172`) — command substitution strips exactly that one trailing newline. The value then moves by **plain assignment only**: `hsa_out="$v"` → `ph_cmd="$hsa_out"` (`:342`) / `s32_cmd="$hsa_out"` (`:404`, `migrate:249`), and is consumed **only** by `str_replace_all` (`upgrade-project.sh:343,405`; `migrate-scripts-layout.sh:250`). I grepped every occurrence of `hsa_out` in the repo (`*.sh`): 14 hits across the 4 files, all assignments, comments, or the three `str_replace_all` arguments. There is **no** `printf "$hsa_out"`, no `echo`, no unquoted expansion, no `sed` on the value. The only `printf` that ever touches it is `str_replace_all`'s own `printf '%s' "$out$rest"` — format-string-safe.

**PowerShell.** `Get-HookSpecCommand` → `.Replace()` (ordinal) at `upgrade-project.ps1:355,415` and `migrate-scripts-layout.ps1:235`. `Invoke-HookSpecCached` uses `@($out) | Select-Object -First 1` then `[string]$first` (`upgrade-project.ps1:164-165`, `migrate:91-92`) — never `[string]$out`. **No `-join` touches the value anywhere in either flow.** I also traced the output-stream purity of `Invoke-HookSpecCached`: `Resolve-HookSpecPath` returns bare and emits nothing; the `+=` and preference assignments emit nothing; `$first`/`$s` are assignments. Only `$val` reaches the caller.

**The two spec twins agree character-for-character.** `hook-spec.sh:123,125,129,131` (double-quoted, `\\\"` → `\"`, `\$env:` → `$env:`) vs `hook-spec.ps1:122,124,128,130` (single-quoted with `-f`, `{{`/`}}` → `{`/`}`) resolve to identical strings for all four shapes. Neither was touched below the header by this task.

**Independent anchor still intact.** `test-init.sh:56-63` `EXP_*` and `test-real-project.sh:54-63` are unchanged frozen literals (comment-only edits), and `test-init.sh:786` Group A now compares the **spec against those literals**, not against a flow. Verified non-circular.

### 2. The `&` hazard — unreachable, and now standing

I ran the design's own widened pattern `\$\{[!#]?[A-Za-z_][A-Za-z0-9_]*(\[[^]]*\])?/` over `.harness/scripts/*.sh` myself. Across the four flow files it returns exactly **2 hits, both comment lines** (`upgrade-project.sh:168`, `migrate-scripts-layout.sh:185`). `-replace` returns **0** in both `.ps1` flows. Every spec-derived substitution routes through `str_replace_all` (bash, `upgrade-project.sh:172-179`) or `.Replace()` (PS, ordinal). The adapter performs **zero** substitution on the value. This is now a *standing* assertion (`test-init.sh:812-824`, `test-init.ps1:959-973`), not a one-time grep.

### 3. Fail-closed asymmetry — no branch can write a permissive guard

There is **no expression in either shell that constructs a command string**. The adapter's only string source is the spec's stdout; its only alternative is "return nothing". Enumerated failure branches, all funnelling into that single return:

| Branch | Bash | PowerShell |
|---|---|---|
| spec file absent (all candidates miss) | `hsa_bin="-"` → `rc=1`, `hsa_out=""` (`sh:151/134`) | `$hsSpecPath='-'` → `$val=$null` (`ps1:140/67`) |
| spec unreadable / not executable | `bash <file>` rc 126/127 → `rc=1` (`sh:156`) | `catch` → `$global:LASTEXITCODE=1` → `$val=$null` (`ps1:162/89`) |
| spec exits 2 (designed) | `(( rc == 0 )) && [[ -n "$v" ]] \|\| { v=""; rc=1; }` | `$LASTEXITCODE -ne 0` → `$val=$null` |
| spec exits 0 with empty stdout | same guard, emptiness re-checked | `[string]::IsNullOrEmpty($s)` → `$val=$null` |
| `pwsh` not on PATH | n/a | `CommandNotFoundException` → `catch` |
| partial answer (one tool succeeds, `guard-rm` fails) | `hsa_query` caches **per key** — the guard's failure is independent; its branch emits `GAP\|`/`SPEC-GAP` and writes nothing | |
| host-OS undeterminable | whole S3.0 loop skipped, all 4 tokens left (`sh:328-329` / `ps1:333-334`) | |

**No loud-then-quiet residue.** I traced the write gate specifically. In `upgrade-project`, a partial S3.0 leaves `{{GUARD_COMMAND}}` in the text; S3.1/S3.2 may still move `settings_new`, so a **write does happen** — and the terminal congruence scan then **re-reads from disk** (`sh:668`, `ps1:677`), sees `$ph_o` (bound at S3 scope, `sh:305`), emits `CONFLICT|congruence|… unresolved placeholder token` and sets `exit_code=4` (`sh:701`, `ps1:705`). Run 2 with the spec still absent reproduces the same tokens, the same records and the same exit 4 — it does **not** decay to 0. In `migrate-scripts-layout`, the `SPEC-GAP` branch leaves the value byte-untouched, so `$new -cne $raw` / `settings_new != $(cat …)` cannot be moved by it and run 2 is byte-identical — no `.bak`, exit 0, and the residue is a *pre-existing* command, never a newly-written permissive one.

**Ordinal proof of the guard shape itself**: `hook-spec.sh:129` / `.ps1:128` carry no `|| exit 0` and no trailing `exit 0`, and `test-init.sh:833-837` / `.ps1:983-988` assert exactly that on both OS variants.

### 4. D-6 (out-variable) — no call site reintroduces the subshell

Repo-wide grep for `hsa_command|hsa_hostos|hsa_out|hsa_path` across `*.sh`: **zero** occurrences of `x="$(hsa_command …)"` outside the warning comments. All four live call sites use the `if hsa_command …; then x="$hsa_out"` form (`upgrade-project.sh:327,341,403`; `migrate-scripts-layout.sh:248`). `$(hsa_path)` appears at `upgrade-project.sh:346` and `migrate-scripts-layout.sh:252` — the permitted pure-reader use. Correct under `set -uo pipefail` with no `-e`: a function in an `if` condition never aborts; `rc=$?` is captured on the statement immediately following the substitution; `return "${hsa_rcs[$i]}"` reads an index strictly below `hsa_n`; `hsa_resolve` returns 0 on every path so no rc leaks. The cache scan is a C-style counter loop (`sh:146`) and `cands` gets its sibling element unconditionally (`sh:129`, `migrate:146`) — no array is ever `[@]`-expanded when possibly empty (bash 3.2 / `set -u`).

**Spawn ceiling**: `upgrade-project` issues at most 1 `hostos` + 8 distinct `cmd/<tool>/<os>` keys (S3.0's 4 keys are a subset of S3.2's 8) = **≤ 9**. NFR-1 satisfied.

### 5. The two repair helpers as a pair — no divergence

Audited side by side, in both shells, on the four questions the 2026-06-11 insight names:

| Question | `upgrade-project.sh` | `.ps1` | `migrate…layout.sh` | `.ps1` |
|---|---|---|---|---|
| Terminal scan re-reads from **disk** in apply mode | `:668` `$(cat "$settings")` ✅ | `:677` `Get-Content -Raw` ✅ | `:297` ✅ | `:277` ✅ |
| Failure branch leaves the value byte-untouched | `:346`,`:408` ✅ | `:352`,`:412` ✅ | `:252` ✅ | `:232` ✅ |
| Diagnostic carries the resolved path or `not found` | `$(hsa_path)` ✅ | `Get-HookSpecPathForMessage` ✅ | ✅ | ✅ |
| Adapter block position / candidate list | 3 candidates, at the retired helper's slot ✅ | 3 ✅ | 2 (no template root) ✅ | 2 ✅ |

The one deliberate asymmetry — `ph_o`/`ph_c` hoisted to S3 scope in bash (`sh:305`) and **not** touched in PS (`ps1:308-309`, already at S3 scope) — is correct and is exactly gate Q5's instruction. The developer's counterfactual (`ph_o` moved back → `exit 1`, no `SUMMARY|`) is the right way to prove it load-bearing.

---

## Findings

### CRITICAL
*(none)*

### MAJOR
*(none)*

### MINOR

- **[MAINT / LEDGER] `.harness/scripts/hook-spec.sh:162-163` — and its three twins (`.ps1:195-197`, both `templates/common/` copies) — carry a provenance sentence this task falsified, and it is the *fourth* instance of the class ledger rows 9-12 + gate F-13 exist to close.**
  The `hostos` branch is commented:
  > `# The exact discrimination the existing derivation flows already use`
  > `# (upgrade-project.sh) - no third variant is introduced.`

  `upgrade-project.sh` no longer contains that discrimination — my grep for `is_windows|OSTYPE|IsWindows` over the file returns **0 matches**; the flow now *asks* the spec (`:327`). The sentence names a construct that no longer exists in the file it cites, and the direction of the relationship is now inverted. This is precisely what round 2 caught at `hook-spec.sh:8-10`, `:97-98` and what the gate's F-13 caught at `.ps1:94` — all three were fixed; this fourth one was in neither the ledger nor F-13. Comment-only; no gate, no byte. **Fix**: reword to "the discrimination the derivation flows now OBTAIN from here (it was duplicated in `upgrade-project` until T-16); no third variant is introduced", in all four copies, edited at the `templates/common/` source and propagated by `sync-self`. **Route: developer** (mechanical), and record against design §9 ledger rows 9/11 for the architect.

- **[LOGIC / PS] `upgrade-project.ps1:331` — an undisclosed host-OS *selection* delta on Windows PowerShell 5.1, one-sided across the shells.**
  Pre-change the flow read `if ($IsWindows)` (`03_GATE_REVIEW.md §2 F-9` confirms this on the pre-change file). Post-change it delegates to `hook-spec.ps1:198`, which is `if ($IsWindows -or $env:OS -eq "Windows_NT")`. Under Windows PowerShell 5.1 `$IsWindows` is undefined (`$null`), so the pre-change flow selected the **unix** byte-forms on a Windows host and the post-change flow selects **windows**. The bash side has *zero* such delta — `hook-spec.sh:164-167`'s `case "${OSTYPE:-}"` is character-identical to the retired `is_windows` block — so the effect is one-sided, the class this repo keeps shipping.
  This is a **strict improvement** (it fixes a latent 5.1 defect), it cannot make the guard fail-open, and AC-2 is untouched because OS is a *parameter* of the 8-cell comparison. But design §3.6 justifies D-1 by asserting the spec carries "the exact discrimination the existing derivation flows already use" — that premise is **false for the PowerShell twin**, and a behaviour change shipped unrecorded under a "provenance changes, emitted bytes must not" premise deserves a line. **Fix**: no code change; record the delta in `07_DELIVERY.md` and correct §3.6's D-1 justification. **Route: solution-architect** (record).

- **[MAINT / STANDARDS] `verify_all.ps1:335,338` and `test-init.ps1:950-952,968-969` use case-insensitive `-match` / `-notmatch` where the bash twins are case-sensitive and the repo's own convention is `-cmatch`.**
  The convention is stated verbatim two files away — `migrate-scripts-layout.ps1:272-273`: *"Case-sensitive regex, no IgnoreCase (insight 2026-05-19 family)"* — and this very check uses `-cmatch` for the `PreToolUse` key form at `verify_all.ps1:321,329`. The four hits below it do not:
  - `:335` `$window -notmatch [regex]::Escape("{{GUARD_COMMAND}}")` — a lowercase `{{guard_command}}` would satisfy the PS gate and **FAIL** the bash twin (`verify_all.sh:352` `grep -q`, case-sensitive).
  - `:338` `$window -notmatch '"command"[ \t]*:'` — same for `"COMMAND":` vs `verify_all.sh:354` `grep -qE`.

  A cross-shell **verdict divergence** in the one check this task tightened. The `test-init.ps1` A′ hits are harmless (case-insensitivity only widens a "must be zero" scan, so it can only over-report) but are the same deviation. **Fix**: `-cnotmatch` / `-cmatch` at all four sites. **Route: developer.**

- **[MAINT / RECORD] `04_DEVELOPMENT.md` "Open issues" item 3 mis-locates the surviving R-1 divergence.**
  It says the *key-form* matcher is `[[:space:]]` in bash and `[ \t]` in PowerShell. As shipped, the **`PreToolUse` key form is `[ \t]` in both** — `verify_all.sh:333` (`awk … /^[ \t]*"PreToolUse"[ \t]*:/`) and `verify_all.ps1:321`. R-1 is fully closed *there*; that is a quiet win the record under-claims. The divergence that actually survives is on the **`"command"` key** matcher: `verify_all.sh:354` `'"command"[[:space:]]*:'` vs `verify_all.ps1:338` `'"command"[ \t]*:'`. An auditor following the record would read the wrong two lines. **Fix**: correct the record (and, cheaply, make `verify_all.sh:354` `[ \t]` too, closing R-1 outright). **Route: developer.**

### NIT

- **[MAINT] `migrate-scripts-layout.sh:182` and `.ps1:105-107` define `hsa_hostos` / `Get-HookSpecHostOs`, which this flow never calls** (it keys on the file extension — design §3.6, `sh:234-240` / `ps1:216-222`). Deliberate per the design's "identical block in both flows", and I am not asking for divergence — but it is dead code in a script that ships into user projects. A half-line (`# unused in this flow — kept so the adapter block stays identical across both flows`) would stop the next reader hunting for the call site.

- **[STYLE] `verify_all.sh:333,336,340` use `[ \t]` inside an awk bracket expression**, which is a GNU/mawk/BWK extension rather than POSIX. Correct on every awk this repo targets, and the cross-shell-parity gain is worth it; noted only because it is a deliberate departure from the `[[:space:]]` form used elsewhere in the same file.

---

## Adjudication of the three self-reported deviations

**DRIFT 1 — A′ scans score `missing`, not `0`, for an absent flow file: SOUND. Endorsed.**
The literal design ("zero hits over the four flow files") would have made deleting a flow turn **both** of its rows vacuously green — the exact false-green class T-15's `E-6/E-8` found. As shipped, `test-init.sh:806,813` initialise `nhit=missing` and only overwrite it when `[[ -f … ]]`; `test-init.ps1:948,966` do the same with `Test-Path -PathType Leaf`. The assertion compares against the **string** `'0'` in both shells (`sh:809,822`; `ps1:956,972`), so `missing` can never satisfy it. Row count unchanged (4 + 4 = 8), no new `verify_all` check, no pin movement. It strengthens the assertion in the only direction that matters and was correctly labelled a drift rather than smuggled in.

**DRIFT 2 — `60-tool-handoff.md` at 131 lines against the design's "≤130": SOUND, immaterial.**
The binding constraint is `I.2` ≤ **200**. I read the file's tail: last content line is 131, i.e. 69 lines of head-room. `verify_all` exits 1 on `warns > 0`, and no `I.2` WARN can fire at 131/200. The "≤130" in design §10.2 was an estimate accompanying a transcription, not a constraint. Correctly disclosed rather than quietly absorbed — which is the behaviour this repo wants.

**DRIFT 3 — `docs/dev-map.md` edited with no ledger row: SOUND.**
The two lines the developer names asserted a state this task falsifies — `:99` said the spec was "to be consumed by the 4 derivation flows in T-16" and `:182` said the flows "still carry their own copies and are re-pointed in T-16". Both are now false statements about the shipped tree, in the map the whole pipeline reads. Two further considerations make the edit correct rather than merely defensible: `verify_all`'s `G.4` reads `docs/dev-map.md` for two count claims (`verify_all.sh:765-766`), so the file is already a gate-load-bearing artifact and a stale line there is not inert; and the Developer contract requires the dev-map to stay true when the described structure changes. No file was added, moved or removed, so this is a **description** correction, exactly as claimed — I read the six edited lines (`:25,26,90,91,99,182`) and they describe the shipped adapter, the spec-absent record types, and the retired duplication accurately. **The omission is the design ledger's, not the developer's**; §9 should have carried the row.

---

## The developer's un-trusted claims, checked

| Claim | My finding |
|---|---|
| `.harness/rules/75-safety-hook.md` still exactly **200** lines | **Verified.** Read the tail: last content line is 200; file is at cap, not over. |
| Guard script + destructive verb set untouched | **Verified as far as reading allows.** Repo-wide grep for `T-16\|hook-spec` over every path matching `*guard*` (`guard-rm.{sh,ps1}` + both twins, `test-guard-rm.{sh,ps1}`, `evals/guard-rm-cases.md`): **0 matches**. `test_guard_rm_bash_assertions` stays 87 and the captured run is 87/0. mtime evidence is not inspectable by me. |
| `docs/proposals/frontier-gaps-2026-07.md` not edited | **Not verifiable by me** (no `git`, no `stat`). The file carries no T-16 marker. Accepted on the S0/mtime record; flagged as an inspection limit, not a doubt. |
| Freeze method's conclusion holds | **Reasoning verified; measurements not.** The developer is right that the tree was dirty at S0 (re-derived: 38 modified + 10 untracked), which contradicts this session's "clean" snapshot and confirms `01 B-11`'s premise — so the dirty-set difference alone proves nothing and **mtime ordering + sha256 must carry it**, which is what §13 specifies and what the record applies (all three conditions, per path). The single named exception, `baseline.json`, is handled with the correct *narrower* assertion (every **numeric** key) — and that I could check directly: I read the file and all 13 numeric keys match design §15's ledger byte-for-byte (32 / 316 / 355 / 90 / 90 / 49 / 45 / 58 / 58 / 89 / 89 / 39 / 39 / 87). |
| No stray `.t16bak` / `verify_all.s0.*` / `.bak-*` at S-final | **Verified.** Glob over the tree returns none. |
| Gate conditions F-12 and F-13 applied | **Verified.** F-12: the false "both scans green pre-change" sentence is **not** transcribed anywhere — `04` §F-12, `test-init.sh:800-802` and `test-init.ps1:939-941` all record the true baseline (16 idiom hits / 0 substitution hits). F-13: `hook-spec.ps1`'s second provenance sentence is rewritten at `:114-118` in both copies. |

---

## Requirement coverage check

| Criterion | Implementation | Status |
|---|---|---|
| In-scope 1 — flows query the spec, hold no byte-form | adapters at `upgrade-project.sh:116-165` / `.ps1:126-180`, `migrate…sh:134-182` / `.ps1:54-107`; idiom grep over all 8 flow files → comment lines only | ✅ |
| In-scope 2 — one spec edit changes all four flows | single source `hook-spec.{sh,ps1}`; C-5 mutation captured (`grep -c nulX` = 0 in every flow) | ✅ |
| In-scope 3 — each flow queries its own shell's twin | bash forms only `…/hook-spec.sh` + `bash` (`sh:128-130,155`); PS forms only `…/hook-spec.ps1` + `& pwsh` (`ps1:134-136,161`) — unreachable by construction, not merely handled | ✅ |
| In-scope 4 — bytes byte-identical, both OS, all 4 tools | chain audited above; C-1/C-2 `diff` → 0 differing, 8/8, both flows; C-3 source-literal diff 0/0 | ✅ |
| In-scope 5 — no flow can emit a fail-open guard | no command-constructing expression exists; `hook-spec.sh:129`/`.ps1:128` carry no `exit 0`; asserted at `test-init.sh:833-837` | ✅ |
| In-scope 6 — event/matcher/semantics/host-OS from the spec | `hsa_hostos` (`sh:327`) / `Get-HookSpecHostOs` (`ps1:331`); event/matcher/semantics referenced by the SKILL instruction (`SKILL.md:206-208`) | ✅ |
| In-scope 7 — three stale prose sentences corrected | `AI-GUIDE.md:110`, `docs/getting-started.md:180-185`, `60-tool-handoff.md:72-78` — all three transcribed verbatim from design §10.1 | ✅ |
| In-scope 8 — skill tables: semantics, no bytes | `harness-init/SKILL.md:187-190` + instruction `:192-219`; `harness-adopt/SKILL.md:311-320` (points at #19, restates nothing) | ✅ |
| In-scope 9 — spec hand-off header corrected | `hook-spec.sh:40-72` / `.ps1:39-71`: RETIRED / DELIBERATELY RETAINED (incl. `test-real-project`, named) / NOT A WIRING COPY / FOLLOW-UP | ✅ |
| In-scope 10 — F.2 containment (T-15 residual) | `verify_all.sh:328-356`, `.ps1:318-341` — 3 new tokens into the **existing** `f2_problems` / `$problems` | ✅ |
| In-scope 11 — check count stays 32 | `verify_all.ps1` has exactly 32 `Step "` calls; `G.4` is last in both shells and derives the count from the live tally; `baseline.json:10` = 32 untouched; captured run 32/0/0 | ✅ |
| **AC-1** single source, by construction | C-5: byte mutated in **both** twins, **both copies each**; all three fixtures carried it; 0 edits to any flow; reverted, `sync-self --check` → In sync. | ✅ |
| **AC-2** byte-identity, by capture | pre-change from **S0 working-tree captures** (never `git show HEAD:`); `diff` 0 differing ×2 flows ×8 cells + `fx-tokens` host-OS cells; C-3 PS at source-literal level; C-4 prose 8/0 | ✅ |
| **AC-3** no literal survives in a flow | my own greps: 0 non-comment hits in all **8** flow files (repo + template twins) and 0 in both `SKILL.md`; now a standing test row | ✅ |
| **AC-4** fail-closed preserved | static 0 violations ×4 emitted values; unix runtime on the **flow-written** file: absent → 127, benign → 0, destructive → 2, deleted again → 127 (middle rows make it anti-vacuous). Windows runtime correctly deferred to operator 12(f)/13(e) | ✅ (Windows half operator-owned by design) |
| **AC-5** spec-unreachable degradation | 5 captured cases incl. both re-run directions; tokens left, values byte-identical, exits 4 / 0 / 0, 0 `.bak` | ✅ |
| **AC-6** prose consumers true | all three re-read by me; none names a fixed file as *this repo's* hook location; each defers to `/harness-status` §0 | ✅ |
| **AC-7** containment, both directions | post-change M-C → exactly 2 tokens, 31/0/1; pre-change **S0 capture** → `[F.2] PASS` with admissibility asserted **both** ways (hash == S0 table, S0 mtime < T0, **and** live file hashes differently); F-3 totality case → PASS | ✅ |
| **AC-8** regressions green, counts captured | 9 captured runs, each reaching its own summary line; every pin matched, none moved; `355` correctly captured under a python3-**absent** shim so it matches the pin's *name*, and `391` (python3-present) is not compared against it | ✅ |
| **AC-9** gate 32/0/0, count from the run | captured; `G.4` (last check, derives count) green, which is itself the anti-fabrication mechanism | ✅ |
| **AC-10** PowerShell honesty | 9 touched `.ps1` all covered by numbered items 12-16 with exact commands (12/13 SECURITY-RELEVANT); `_qa_note_t16` and `04` both state **nothing** was executed in PS; 11 → 16 numbered, 2 → 4 security, 19 → 24 total; PS pins + README PS badges frozen | ✅ |
| **AC-11** no scope leakage | freeze method re-derived at task start; frozen set intact (see table above); `baseline.json` the single disclosed exception with the correct narrower numeric-key assertion | ✅ (mtime half unverifiable by me) |

---

## Design fidelity check

| Design item | Implementation | Status |
|---|---|---|
| §3.1 adapter interface, single failure return | `hsa_command`/`hsa_out` + rc; `Get-HookSpecCommand` → `$null` | ✅ |
| §3.1 / §3.2 **lazy** resolution, block reads no flow variable at definition time | `hsa_resolve` (`sh:124`) / `Resolve-HookSpecPath` (`ps1:131`, `migrate:59`); first call at `sh:327` / `ps1:331` / `migrate sh:248` / `ps1:230`, all after every binding | ✅ |
| §3.2 candidate order (3 for upgrade, 2 for migrate) | `sh:128-130` / `ps1:134-136`; `migrate sh:146-147` / `ps1:62-63` | ✅ |
| §3.3 C-style cache loop, unconditional sibling candidate | `sh:146`, `sh:129` | ✅ |
| §3.4 `$script:`-scoped cache, `@($out)\|Select -First 1`, `$PSNativeCommandUseErrorActionPreference=$false`, `catch` forces `$LASTEXITCODE` | `ps1:157,161-171` / `migrate:84,88-98` | ✅ |
| §3.5 all call sites rewired; S3.0 spec call moved inside the token∧target guard | `sh:340-347` / `ps1:349-357` | ✅ |
| §3.6 host OS from the spec; `$hsIsWin`, never `$isWindows`; `$IsLinux\|$IsMacOS` chmod untouched | `ps1:331-332,344`; `:494,510` untouched; `$IsWindows` gone from the wiring path (grep) | ✅ (see MINOR #2 on the §3.6 *justification*) |
| §3.6 F-4 `ph_o`/`ph_c` hoisted to S3 scope in bash; **not** in PS | `sh:305` (after `settings_new=""`, before the `-f` branch); `ps1:308-309` untouched | ✅ |
| §4 `str_replace_all` at every bash site; no pattern substitution on the path | `sh:343,405`, `migrate:250`; grep 2 comment-line hits | ✅ |
| §5 degradation records, exact shapes, no new record type | `GAP\|hook-spec\|absent\|…` ×3 shapes + `SPEC-GAP` plan line; `GAP` is a pre-existing shape | ✅ |
| §6 prose tables carry semantics only; instruction written once | `harness-init/SKILL.md:192-219`; `harness-adopt` points at it by name | ✅ |
| §7.1 window rule: `≤ IND`, terminator **excluded**, `term = N` when none, `[ \t]` width in both shells | `verify_all.sh:328-346` (awk, `exit 2`/`exit 3`, `$?` captured at `:347`) / `.ps1:318-341`; both agree; traced against the real template → window `[48,57]`, evidence at `:53`/`:54` → PASS | ✅ |
| §7.1 no new `step`/`Step`; `G.4` remains last | tokens accumulate into existing lists; 32 `Step` calls; `G.4` last in both | ✅ |
| §8 oracle re-anchored; A′ re-purposed; A′ block **outside** the PS per-cell loop | `test-init.sh:776-824`; `.ps1:899-974`, loop at `:904-925` carries 2 `Assert`s/cell, A′ a separate 8-row block | ✅ |
| §9 ledger rows 1-27 | all located; **`docs/dev-map.md` has no row** (drift 3, adjudicated sound); `hook-spec.ps1:94` twin added per F-13 | ⚠️ ledger gap (design-side), not a code defect |
| §9 twin propagation at the source | all 8 flow/spec twins byte-consistent at identical line numbers on spot-check; `verify_all.sh:194` `E.1` runs `sync-self.sh --check` and is green — the gate that makes the A′ scan's `.harness/scripts/`-only file set sound | ✅ |
| §12 five numbered operator items in `baseline.json:_qa_note_t16` | present, verbatim, with exact commands | ✅ |
| §13 frozen set | `settings.json.tmpl` restored exactly; `sync-self.*`, `guard-rm.*`, `test-guard-rm.*`, `test-harness-upgrade.*` carry no T-16 marker | ✅ |
| §16.1 RES-1 named and travelling | `04` open issue 2; must reach `07_DELIVERY.md` | ✅ (stage-7 obligation) |

---

## Unverified by inspection — must not be reported as reviewed-green

I have Read/Glob/Grep and no execution. Everything below is *consistent with* the artifacts I read and **not measured by me**:

1. Every captured tally (`test-init` 391 / 355, `verify_all` 32/0/0, `test-real-project` 90, `test-harness-upgrade` 89, `test-verify-i6` 58, `test-supervisor` 46/45, `test-language` 39, `test-guard-rm` 87) — transcribed from the record. What I *can* confirm: they are mutually consistent, consistent with `baseline.json`, and consistent with `_qa_note_t13`'s independent corroboration that `391 − 355 = 36 = 3 × 12` (the python3-gated block), which is a real cross-check rather than arithmetic on itself.
2. The M-C two-token / 31-0-1 result and the **pre-change** `[F.2] PASS` with both admissibility assertions.
3. All mtime/sha256 freeze evidence (no `stat`, no `git` here).
4. **The entire PowerShell surface**, without exception — 9 edited `.ps1` files, none parsed or run by anyone. I read every changed `.ps1` line as a parser would and found no syntax defect, no assignment to a read-only automatic, no `-join` adjacent to `+`, no `[string]$array`, no bare `+=` on a cache, and no double-quote-concat literal idiom. That is *review*, not *execution*: operator items 12-16 remain the only evidence path, and MINOR #3 above is a real PS-only divergence that only a Windows run will surface as a behavioural difference.

---

## Axis status

- **Standards-conformance**: **4 findings, worst = MINOR** — stale `hook-spec` `hostos` provenance comment ×4 copies; case-insensitive `-match` in `verify_all.ps1` + `test-init.ps1`; `04` record mis-locating R-1; plus 2 NITs (dead `hsa_hostos`, awk `[ \t]` portability). Every AI-GUIDE / `.harness/rules/*` constraint I could check holds: no hand-edit of `.claude/`, `CLAUDE.md` or `.github/copilot-instructions.md`; doc-size caps measured (`AI-GUIDE.md` 113/200, `60-tool-handoff.md` 131/200, `75-safety-hook.md` 200/200 untouched); twins edited at the `templates/common/` source and propagated; `.harness/rejected-decisions.md` and `CONTEXT.md` updated as the decision-policy requires; no invented rule applied — the four MINORs each cite either a repo convention stated verbatim in the repo or a false statement in a shipped file.
- **Spec/design-fidelity**: **1 finding, worst = MINOR** — the PowerShell host-OS selection delta and the false §3.6/D-1 justification behind it. Every acceptance criterion has a located implementation; every design mechanism (lazy resolution, out-variable, C-style loop, `str_replace_all` mandate, containment window with `≤ IND` + terminator exclusion, oracle re-anchor, A′ lift-out, degradation contract, operator list) is present as specified. The one design-side gap — `docs/dev-map.md` missing from the §9 ledger — is the architect's omission, correctly surfaced by the developer as DRIFT 3 rather than absorbed, and is not a code defect.

Neither axis carries an open CRITICAL or MAJOR, so the aggregate is the more severe of the two: **MINOR**.

---

## Verdict

> **APPROVED** — 0 CRITICAL, 0 MAJOR, 4 MINOR, 2 NIT.

The task's central premise survives adversarial reading: provenance changed, bytes did not. I traced the emission chain end to end in both shells and found no post-processing of the captured value anywhere — no `printf "$v"`, no bare `echo`, no unquoted expansion, no `-join`, no pattern substitution — and the two spec twins' four literals are character-identical, so the two shells cannot diverge. The `&`/`patsub_replacement` hazard is unreachable rather than handled, and my own widened grep confirms it (2 hits, both comments). `guard-rm` is fail-CLOSED **structurally**: there is no expression in either flow that constructs a command string, and I enumerated all seven failure branches — including the new lazy-resolution ones and the partial-answer case — into the single "return nothing" path, then followed each to its terminal exit code to confirm no branch leaves a residue that the `$new -cne $raw` write gate or a second run blesses at 0. The out-variable convention is intact at every call site. The two repair helpers were audited as a pair, in four files, and diverge in exactly one place — the `ph_o` hoist — which is the place they are *supposed* to diverge, and which the developer proved load-bearing by counterfactual rather than by argument. The containment fix adds three tokens to the existing accumulators, no `step`/`Step` call, `G.4` still last, count still 32.

None of the four MINORs blocks merge: two are comment/record corrections, one is a case-sensitivity tightening in a PowerShell branch, and one is a record-only behaviour disclosure. All four are dischargeable by a developer with bash alone.

**Routing**
- **Developer** (mechanical, no design decision): MINOR #1 (reword the `hostos` provenance comment in all four `hook-spec` copies, at the `templates/common/` source, then `sync-self`); MINOR #3 (`-cnotmatch`/`-cmatch` at `verify_all.ps1:335,338` and `test-init.ps1:950-952,968-969` — and note this makes `verify_all.ps1` a **re-touch**, so operator item 14(a) `ParseFile` must be re-run and item 15(a) likewise for `test-init.ps1`); MINOR #4 (correct the `04` record, and optionally close R-1 outright by making `verify_all.sh:354` use `[ \t]`); the two NITs at discretion.
- **Solution-architect** (record only, no rework): MINOR #2 (the PS host-OS delta and §3.6's D-1 justification) and the `docs/dev-map.md` ledger omission — both belong in `07_DELIVERY.md`.
- **Stage 6 (QA)**: RES-1 stands and must travel. The eight empirical captures the gate could not verify, plus everything in my "Unverified by inspection" list, remain QA's to re-measure — in particular the PowerShell surface, which no agent on this host can touch and which now has one more reason (MINOR #3) for the operator to look at `verify_all.ps1`'s `F.2` closely.

---
---

# Code Review — T-16 `hook-truth-derivation` — Round 2

> **Provenance note (PM)**: returned as agent reply; the code-reviewer is read-only by contract (Read/Glob/Grep, no Write). Round 1 stays on disk above this section unchanged. **This round-2 section is the operative verdict.**

- **Stage**: 5 (code-reviewer), round 2, **narrow delta scope**. Everything cleared in round 1 stands: the emission chain, the `&`/`patsub_replacement` unreachability, the fail-closed branch enumeration, the D-6 out-variable convention, the sibling-pair audit, the containment window, the `resilient_cmd` retirement, and both coverage tables were **not** re-reviewed except where the delta touched them.
- **Input**: `04_DEVELOPMENT.md:321-469` (round-2 section) + the 7 changed files, each read at the changed region, both twins of every pair.
- **What I cannot do**: unchanged from round 1 — no execution, no `git`, no `stat`, no `pwsh`. Every claim below is read from a file or explicitly marked as transcribed.
- **deferred-human**: defer, do not ask. No `BLOCKED: NEEDS-HUMAN` point arose.

---

## Files reviewed (round-2 delta only)

- `.harness/scripts/hook-spec.sh` · `skills/harness-init/templates/common/.harness/scripts/hook-spec.sh`
- `.harness/scripts/hook-spec.ps1` · `skills/harness-init/templates/common/.harness/scripts/hook-spec.ps1`
- `.harness/scripts/verify_all.ps1` · `.harness/scripts/verify_all.sh` · `.harness/scripts/test-init.ps1`

**Read to prove *un*changed / to re-confirm invariants**: `.harness/scripts/test-init.sh` · `.harness/scripts/baseline.json` · `.harness/rules/75-safety-hook.md` · `.harness/scripts/guard-rm.sh` (+ every `*guard*` path by grep) · `docs/proposals/frontier-gaps-2026-07.md` · `02_SOLUTION_DESIGN.md:363-376`.

---

## 1. The three fixes — all landed, verified by reading

### MINOR #1 — stale `hostos` provenance sentence: **CLOSED**

All four copies carry the reworded text, and the two pairs are byte-consistent **at identical line numbers**, which is the signature of a source-side edit propagated by `sync-self` rather than a repo-side edit back-copied:

- `hook-spec.sh:162-163` and `templates/common/…/hook-spec.sh:162-163` — identical, 2 comment lines (was 2).
- `hook-spec.ps1:195-197` and `templates/common/…/hook-spec.ps1:195-197` — identical, 3 comment lines (was 3).

The F-13 sentence is preserved verbatim as the PS twin's third line (`ps1:196-197`, `$IsWindows` undefined on 5.1 / `$env:OS` carries the answer), so the in-code disclosure surface that MINOR #2 depends on is intact.

Two things better than my round-1 prescription, worth recording: each twin names **its own shell's** flow (`upgrade-project.sh` at `sh:163`, `upgrade-project.ps1` at `ps1:196`) rather than the shell-agnostic "upgrade-project" I wrote; and the accuracy claim holds — round 1's grep for `is_windows|OSTYPE|IsWindows` over `upgrade-project.sh` returned 0, so "it was duplicated … until T-16" is true of the shipped tree.

I re-ran the repo-wide grep for the old sentence myself. **Zero hits in any `.sh` or `.ps1`.** The four surviving hits are all citations, not assertions: `docs/features/_archived/hook-truth-spec/01_REQUIREMENT_ANALYSIS.md:132` (immutable archived record, correctly untouched), this task's `04:336` and `05:101,108` (quoting it to fix it), and `02_SOLUTION_DESIGN.md:370` — see the MINOR #2 addendum below, which is the one place this matters.

*(The clause "no third variant is introduced" survives from my own round-1 prescribed wording and is now mildly stale — it references a two-variant world the retirement collapsed. Trivially still true, and I am not going to charge the developer for transcribing my sentence. Noted so a future reader doesn't think it slipped past.)*

### MINOR #3 — case-sensitive operators: **CLOSED**, exactly at the sites I named

Seven operators across five lines, and the line numbers match the task brief precisely:

- `verify_all.ps1:338` `-cnotmatch [regex]::Escape("{{GUARD_COMMAND}}")` · `:341` `-cnotmatch '"command"[ \t]*:'`, with the reason comment at `:335-337`.
- `test-init.ps1:952` and `:970` `-cnotmatch '^[ \t]*#'` · `:954` two `-cmatch` (`Set-Location -LiteralPath` / `CLAUDE_PROJECT_DIR`) · `:971` `-cmatch $subPattern`, with the reason comment at `:950-951`.

The shift from round-1's citations is exactly the inserted comment height (+3 in `verify_all.ps1`: `335,338` → `338,341`; +2 in `test-init.ps1`: `950-952`/`968-969` → `952-955`/`970-971`). Nothing else moved.

**No unintended site flipped.** I enumerated every `-match`/`-notmatch`/`-cmatch`/`-cnotmatch` in both files. `verify_all.ps1` has 21 such sites; only `:338` and `:341` changed — `:321`/`:329` were already `-cmatch` (round 1 said so), `:315` is the deliberate exclusion, and the other 17 (`:44,79,80,81,97,146,162,175,220,233,355,381,392,394,450,475,503,505,730`) are untouched and outside T-16's blast radius. `test-init.ps1` has ~45 sites; only the five lines above changed, all inside the `[T-16][A′]` block.

**Semantics unchanged apart from casing**, operator by operator:

| Site | Pattern | Effect of the flip |
|---|---|---|
| `test-init.ps1:952,970` | `^[ \t]*#` | **no-op** — no letters in the pattern. Consistency only. |
| `test-init.ps1:971` (`.sh` branch) | `\$\{[!#]?[A-Za-z_]…` | **no-op** — classes spell both cases explicitly. |
| `test-init.ps1:954` ×2 | `Set-Location -LiteralPath`, `CLAUDE_PROJECT_DIR` | tightened; now equal to `test-init.sh:807`'s `grep -nE`. |
| `test-init.ps1:971` (`.ps1` branch) | literal `-replace` | tightened; now equal to `test-init.sh:818`'s `grep -n -- '-replace'`. See NIT R2-4. |
| `verify_all.ps1:338` | escaped `{{GUARD_COMMAND}}` | tightened; now equal to `verify_all.sh:352`'s `grep -q`. **Load-bearing.** |
| `verify_all.ps1:341` | `"command"[ \t]*:` | tightened; now case-equal to `verify_all.sh:359`'s `grep -qE`. |

The `[ \t]`-vs-`[[:space:]]` width divergence at `:341`/`:359` is untouched and is the documented R-1 residual, not a casing artifact.

### MINOR #4 — record corrected: **CLOSED**

`04:269-278` now cites `verify_all.sh:333` / `verify_all.ps1:321` for the key form (I verified both are `[ \t]`, so R-1 really is closed there) and `verify_all.sh:359` / `verify_all.ps1:341` for the surviving `"command"` divergence (verified: `grep -qE '"command"[[:space:]]*:'` vs `-cnotmatch '"command"[ \t]*:'`). The correction is accurate on both halves and correctly flags that the original line under-claimed a win.

---

## 2. Adjudication — the declined `[ \t]` harmonization

**The decline is CORRECT, and it is the right kind of correct: measured, not argued.** I am withdrawing my round-1 suggestion without reservation.

I could not re-run the developer's experiment (no execution), but I do not need to — the claim is checkable against POSIX and GNU grep's documented behaviour, and the transcript at `04:385-403` is internally coherent in a way a fabricated one would not be. Inside a **bracket expression**, POSIX ERE gives `\` no special meaning: `[ \t]` is the set `{space, backslash, t}`. GNU grep 3.11 implements exactly that. So `grep -E '"command"[ \t]*:'` **misses** `"command"<TAB>:` and **matches** `"command"t:` and `"command"\:` — which is precisely the three-line result their `cat -A` fixture prints. `awk`, by contrast, processes ERE literals through its **string-escape** layer first, so `\t` becomes a real tab before the regex engine ever sees it — hence gawk/mawk/BWK read `[ \t]` as `{space, tab}`.

My round-1 NIT #2 called the awk form "a GNU/mawk/BWK extension rather than POSIX" and then, one finding later, my MINOR #4 invited harmonizing the grep to match it. Those two statements are in tension and the developer caught the tension by measuring rather than by reading my two bullets as consistent. Had they taken the "cheap closure", the gate would have gained a **false FAIL on a valid tab-indented template** and a **false PASS on `"command"t:`** — strictly worse than what it replaced, in exchange for closing a divergence that needs a form-feed, vertical tab or CR to observe inside a JSON file the gate itself owns.

**The surviving bash/PS asymmetry is sound and documented, not sloppy.** Three tests, all passed:

1. **It is intentional, not residual** — the comment at `verify_all.sh:354-358` states the reason at the exact line a future harmonizer would edit.
2. **It is per-tool-correct** — `[[:space:]]` in GNU grep and `[ \t]` in .NET both mean what the author intends in their own engine. The asymmetry is in the *notation*, not in the *semantics*, apart from the four extra whitespace characters `[[:space:]]` admits (`\n\r\f\v`), which is the documented R-1 residual at `04:274-278`.
3. **It is recorded where the auditor looks** — `04` open-issues item 3, corrected in the same round, with an explicit "see round 2 for the measurement".

That is the difference between a divergence and a defect, and this one is on the right side of it.

---

## 3. Adjudication — the ugrep/GNU-grep split and the in-gate comment

**The comment is in the right place.** The hazard vector is one-directional: a reader "tidying up" `verify_all.sh:359` to match the awk block 20 lines above. The comment sits immediately above that line, so it is unmissable to exactly that reader. The reverse move (harmonizing awk *down* to `[[:space:]]`) is harmless — POSIX classes work in awk too — so it needs no guard.

**The wording is right on substance, with one imprecision.** `verify_all.sh:357-358` says "awk turns `\t` inside an ERE into a TAB; grep does not". True of gawk, mawk and BWK awk; **not** guaranteed of a strict POSIX awk, where the escape handling is unspecified inside a bracket expression. The developer's own newly-surfaced insight (`04:311-317`) says "must be measured per tool, never assumed from a sibling line" — and the comment then makes an unqualified tool-general claim about `awk`. Naming the measured awk would make the comment obey its own rule. NIT R2-3.

**The ugrep caveat is the more valuable half of the finding, and it is *not* in the gate comment.** `04:410-412` records it; `verify_all.sh:354-358` does not. I think that split is defensible — the gate comment answers "why are these two lines different", which is what a code reader needs; the "your login shell will lie to you" trap is a *verification-method* insight and belongs in the insight channel, which is where they put it. Flagging it here only so PM does not mistake the omission for an oversight.

**No other changed grep pattern is exposed to the same split.** I checked this rather than assumed it. Two greps over all of `.harness/scripts/*.sh`:

- `grep` invocations containing `\t`, `\s`, `\d`, `\w` (or their negations), or `grep -P`: **zero matches, repo-wide.**
- `[ \t]` anywhere in a `.sh` file: **8 hits, all in `verify_all.sh`** — `:333,336,339,340` inside the awk program (correct there) and `:316,354,356,358` in comments. **Not one is inside a grep pattern.**

Every other pattern this task touched uses POSIX classes or plain literals, on which GNU grep and ugrep agree: `verify_all.sh:324,352` (fixed strings), `:359` (`[[:space:]]`), `test-init.sh:807-808,816-819` (`[[:space:]]`, explicit `[A-Za-z_]` classes, `[^]]` with the leading-`]` POSIX literal form, `\{`). The split is contained to exactly the one line that now carries the comment.

---

## 4. Adjudication — `verify_all.ps1:315` left as pre-existing

**The scope call is CORRECT, and it is safer than the developer argues.**

*On scope*: my round-1 finding enumerated "the four hits **below** it", anchored on `:321,329` already using `-cmatch`. `:315` sits **above** `:321` and was genuinely outside my named set. A round whose entire purpose is discharging three named MINORs is the wrong place to widen into an unnamed line of a live gate — that is the scope discipline this task's own freeze method exists to enforce, and reversing it here would set the precedent that a fix round may edit any line it happens to notice.

*On the pre-existence claim*: I cannot run `git show`, so `cb0ed57:verify_all.ps1:308` is transcribed, not measured by me. It is structurally corroborated: the comment block at `verify_all.ps1:294-297` describes the presence check as the older requirement and marks the containment window separately at `:298` with an explicit "T-16 (T-15's containment residual)" boundary. Consistent with the claim; not proof of it.

*On risk — the part the record misses*: **the MINOR #3 fix at `:338` already subsumes `:315`'s verdict risk.** Trace a template carrying a lowercase `{{guard_command}}` inside the PreToolUse block:

- bash: `:324` `grep -q` misses → token `no_GUARD_COMMAND_placeholder`; `:352` misses → token `guard_command_not_in_PreToolUse`. **2 tokens, FAIL.**
- PowerShell: `:315` `-notmatch` (still case-insensitive) matches → no token; `:338` `-cnotmatch` (now case-sensitive) → token `guard_command_not_in_PreToolUse`. **1 token, FAIL.**

Both shells FAIL. What survives at `:315` is a **diagnostic-token-set divergence**, not the verdict divergence round 1 flagged. There is no input on which `:315` alone produces a false PASS, because the window check now backstops it case-sensitively. That downgrades the residual from "same class, live gate" to "cosmetic asymmetry in the failure message" — which makes leaving it not merely disciplined but correct.

**Where it must be recorded.** Right now it lives only in narrative prose at `04:366-372`, inside the MINOR #3 fix write-up. The list that stage 6/7 harvests is `04`'s **"Open issues for review"** (`:256-279`), which ends at item 4 and does not mention it. A residual recorded only in a fix section's body will not survive the harvest. It must be added as **Open-issues item 5** in `04_DEVELOPMENT.md` and carried into `07_DELIVERY.md` alongside R-1 and RES-1 — the same channel, since it is the same kind of object (a gate record-only residual). It does **not** need a `baseline.json` operator item: it is a bash-verifiable one-character change, not a PowerShell obligation. Raised as MINOR R2-1 below so the requirement is binding rather than advisory. This review is a backstop, not a substitute — 05 is read at stage 7, but the harvested list is 04's.

---

## 5. The two NITs

**NIT #2 (awk `[ \t]` portability) — TAKEN, and correctly executed.** Comment-only, at `verify_all.sh:354-358`, in a bash-only file, with **no PowerShell re-touch** — verified: the `verify_all.ps1` delta is confined to `:335-337` (comment) and `:338,341` (operators), all of which are MINOR #3's, none of which is NIT #2's. Repurposing the NIT from "document the portability caveat" to "document why the two forms must stay different" is a strict improvement: it guards the live hazard rather than annotating a theoretical one. The one wording imprecision is NIT R2-3.

**NIT #1 (half-line on the unused `hsa_hostos`) — DECLINE ACCEPTED; the stated reason is not.** A NIT is declinable by definition, it was recorded with a reason rather than silently dropped, and the design already answers the dead-code question at §3.6. That is the correct disposition and I am not reopening it.

But the cost argument at `04:420-424` is wrong on its facts, and it is wrong in a way the *same document* gets right three paragraphs later. It claims re-touching `migrate-scripts-layout.ps1` "would create a **third** operator re-parse obligation (item 13)". Item 13(a) in `baseline.json:_qa_note_t16` already reads *"ParseFile over both copies"* **unconditionally** — that obligation exists today, created by round 1's edits, and no comment can create it a second time. A comment would change the parse's *object*, not add an obligation — which is precisely the reasoning `04:454-456` applies correctly to items 14/15 ("the obligation stands unchanged in kind — only its *object* changed"). The decline stands on its real grounds (it is a NIT, prose-only, in an unexecutable file); the phantom-cost rationale should not become precedent, because it would let any `.ps1` comment anywhere be blocked by an obligation that already exists. NIT R2-5.

---

## 6. Invariant re-confirmation

| Invariant | Result |
|---|---|
| Check count still **32**, no `step`/`Step` added | ✅ Re-enumerated `Step "` in `verify_all.ps1` from scratch: 32 exactly (`:43` A.1 → `:696` G.4). The bash delta added only comment lines inside the existing F.2 block. |
| `G.4` still **last** | ✅ `verify_all.ps1:696` is the final `Step`; `verify_all.sh` G.4 records at `:829/:833` with the self-reference tripwire at `:841-843` intact. |
| No pinned count moved | ✅ Read `baseline.json` in full. All 18 numeric keys identical to round 1's ledger: 1 / 4 / 7 / 2 / **32** / 316 / 355 / 90 / 90 / 49 / 45 / 58 / 58 / 89 / 89 / 39 / 39 / 87. The file is not in the 7-file edit set. |
| Twins byte-consistent after the `hook-spec` edit | ✅ Both pairs read: identical text at identical line numbers (`sh:160-168`, `ps1:190-200`). Comment-line counts held at 2 / 3. |
| `sync-self --check` in sync | ⚠️ **Transcribed, not measured** (no execution). Inspection is consistent with it, and I confirmed the structural precondition myself: `verify_all.ps1` and `test-init.ps1` have **no** `templates/common/` twin (globbed the whole directory — 21 files, neither present), so the two gate/test edits create **zero** propagation obligation. Only the four `hook-spec` copies did, and they agree. |
| `75-safety-hook.md` exactly **200** lines | ✅ Read the tail: last content line is 200, nothing follows. At cap, not over. Untouched by the delta. |
| Guard script + destructive verb set untouched | ✅ Repo-wide grep for `T-16\|hook-spec` over every path matching `*guard*` (`guard-rm.{sh,ps1}` ×2 copies, `test-guard-rm.{sh,ps1}`, `evals/guard-rm-cases.md`): **0 matches**. |
| Untracked operator backlog untouched | ✅ `docs/proposals/frontier-gaps-2026-07.md`: 0 matches for `T-16\|hook-truth-derivation\|round 2`. (mtime evidence remains outside my reach.) |
| PS re-touch consequence recorded where the operator sees it | ✅ **and no `_qa_note_t16` edit is required** — I checked each item against the four round-2-touched `.ps1` files: `hook-spec.ps1` ×2 → item **16**; `verify_all.ps1` → item **14(a)**; `test-init.ps1` → item **15(a)**. All three are unconditional and **record no parse results**, so nothing in the note went stale — the operator running it today parses the round-2 bytes by construction. `04:444-456` states the re-run requirement imperatively for PM's carry into `07_DELIVERY.md`. |
| No `.ps1` described as verified | ✅ `04:446` — "nothing in `.ps1` was executed or parsed this round either … green-by-symmetry only"; `04:258` unchanged. Round 1's "9 edited `.ps1`, none parsed or run" does **not** move: all four round-2 files were already inside that 9. |
| MINOR #2 (PS host-OS delta) left for the architect | ✅ `hook-spec.ps1:198` is byte-for-byte as round 1 shipped it (`if ($IsWindows -or $env:OS -eq "Windows_NT")`). Only the comment above it changed, and the 5.1 disclosure line survives verbatim. See the addendum below. |

---

## 7. Findings (round 2 only)

### CRITICAL
*(none)*

### MAJOR
*(none)*

### MINOR

- **R2-1 · [RECORD] `04_DEVELOPMENT.md:256-279` — the `verify_all.ps1:315` residual is not in the harvested list.**
  It is recorded only in narrative prose at `04:366-372`, inside the MINOR #3 fix section. The "Open issues for review" list — the artifact stage 6/7 reads to build `07_DELIVERY.md` — ends at item 4 and does not name it. A residual that lives only in a fix write-up does not survive the harvest. **Fix**: add it as **Open-issues item 5** ("`verify_all.ps1:315` presence check is case-insensitive against a case-sensitive bash twin at `verify_all.sh:324`; pre-existing at `cb0ed57`, deliberately out of T-16's scope; post-MINOR-#3 the exposure is a diagnostic-token divergence only, not a verdict divergence, because `:338` backstops it"), then carry to `07_DELIVERY.md`. No `baseline.json` operator item needed — it is bash-verifiable. **Route: developer or PM** (one line, no code).

- **MINOR #2 (carried, architect) — addendum created by this round's delta.**
  `02_SOLUTION_DESIGN.md:369-370` justifies D-1 by **quoting** the sentence MINOR #1 just deleted: *"`hook-spec.sh:142-147` documents itself as carrying 'the exact discrimination the existing derivation flows already use', so this is the same duplication class."* That quotation now names a string present in **no shipped file**, and its line citation is wrong twice over (the comment is at `:162-163`, not `:142-147`). This does not change the design's conclusion — the duplication class is real and D-1 is right — but the architect's §3.6 correction under round-1 MINOR #2 must now also refresh this quotation and its citation, or §3.6 will cite evidence that cannot be found. **Route: solution-architect**, folded into the existing MINOR #2 record item. No developer action.

### NIT

- **R2-2 · [RECORD] the in-gate comment is cited off by one, twice, inconsistently.** The comment occupies `verify_all.sh:354-358` and the grep it guards is `:359`. `04:410` cites it as `verify_all.sh:355-358` (misses line 354, the line that carries the actual instruction "NOT harmonized"); `04:316` cites the same artifact as `verify_all.sh:355-359`. Two citations, one artifact, neither exact. Given that round-1 MINOR #4 was itself a mis-located-record finding, precision here is worth the ten seconds.

- **R2-3 · [STYLE] `verify_all.sh:357-358` makes a tool-general claim about `awk`.** "awk turns `\t` inside an ERE into a TAB" is true of gawk/mawk/BWK and unspecified for strict POSIX awk. The comment's own governing insight is "measured per tool, never assumed". Name the measured awk and the comment obeys the rule it exists to teach. Also worth half a line: the awk block at `:333-340` has no pointer down to this note, so a reader who copies `[ \t]` *out of* the awk into a new grep elsewhere in the file is not covered by it.

- **R2-4 · [MAINT] `test-init.ps1:971` — `-cmatch '-replace'` makes both shells equally blind to `-Replace`.** PowerShell operators are case-insensitive at the *language* level, so `$v -Replace 'a','b'` is a legal `-replace` and now evades **both** A′ substitution scans. Pre-fix, bash missed it (`test-init.sh:818` `grep -n -- '-replace'` was always case-sensitive) and PS caught it. Post-fix the pair is uniformly blind. I am rating this a NIT, not a MINOR, deliberately: the substantive gap is on the **bash** side, it is T-16's own but was cleared in round 1, and symmetric-and-documented is strictly better for the cross-shell-parity property than asymmetric-and-lucky. On the development host (Linux, bash-only) detection is **unchanged**. Recorded so a future task widens **both** sides together — e.g. `-[Rr]eplace` in each — rather than re-splitting them.

- **R2-5 · [RECORD] the NIT #1 decline's stated cost is phantom.** `04:420-424` says a comment in `migrate-scripts-layout.ps1` "would create a **third** operator re-parse obligation (item 13)". Item 13(a) already mandates `ParseFile` over both copies unconditionally; a comment changes the parse's *object*, not the obligation — exactly as `04:454-456` correctly reasons for items 14/15. The **decline stands**; the **rationale should not be cited as precedent**, or it becomes a general veto on touching any `.ps1`.

---

## 8. Unverified by inspection (round-2 delta)

Unchanged in kind from round 1, narrowed to this round's claims:

1. **The measurement transcript at `04:385-403`** — the `/usr/bin/grep --version`, `cat -A` and contrast runs. I cannot execute. I verified the *claim* against POSIX bracket-expression semantics and GNU grep's documented behaviour and it is correct; I have not seen the run.
2. **The eight re-verification runs at `04:428-437`** (`verify_all` 32/0/0, `test-init` 391 / 355, `test-verify-i6` 58, `test-real-project` 90, `test-harness-upgrade` 89, `test-guard-rm` 87, `sync-self --check` `In sync.`). Transcribed. They are mutually consistent and consistent with `baseline.json`, which is all reading can establish.
3. **`git show HEAD:.harness/scripts/verify_all.ps1`** at `cb0ed57` — the pre-existence proof for `:315`. Structurally corroborated by the comment demarcation at `verify_all.ps1:294-298`, not measured.
4. **The entire PowerShell surface, again.** Four `.ps1` files were re-touched this round and **none** was parsed. I read every changed `.ps1` line as a parser would: `-cnotmatch`/`-cmatch` are valid operators in all supported PS versions, the comment insertions introduce no unbalanced quote, backtick or here-string, and no line exceeds the file's existing conventions. That is review, not execution. Operator items **14(a), 15(a) and 16** remain the only evidence path, and all three must be run against the **round-2** bytes.
5. **mtime / dirty-set evidence** for the "7 files, nothing else moved" claim. No `stat`, no `git`. What I could check independently — `baseline.json` numerics, `75-safety-hook.md` at 200, zero `T-16|hook-spec` in any `*guard*` path, zero markers in `frontier-gaps-2026-07.md`, both `hook-spec` twin pairs identical — is all consistent with it.

---

## Axis status (round 2)

- **Standards-conformance**: **4 findings, worst = MINOR** — R2-1 (residual absent from the harvested list), plus NITs R2-2 (citation drift), R2-3 (unqualified `awk` claim), R2-4 (`-Replace` symmetric blind spot), R2-5 (phantom-cost rationale). Every repo convention the delta could touch holds and was measured, not assumed: cross-shell parity is now **improved** at the two load-bearing `verify_all` sites and unchanged elsewhere; the case-sensitivity convention cited verbatim at `migrate-scripts-layout.ps1:272-273` is now honoured at all seven flipped operators; twins were edited at the `templates/common/` source and propagated (proved by identical content at identical line numbers, not by testimony); doc caps unmoved (`75-safety-hook.md` 200/200); `.claude/`, `CLAUDE.md` and `.github/copilot-instructions.md` untouched; no `step`/`Step` added and `G.4` still last; no invented rule applied.
- **Spec/design-fidelity**: **1 finding, worst = MINOR** — the carried MINOR #2, now enlarged by the delta: `02_SOLUTION_DESIGN.md:369-370` quotes a sentence that no longer exists anywhere and cites the wrong lines for it. Not clean, and I am saying so explicitly rather than letting the Standards axis carry the round. Otherwise: **no design decision was made or altered this round**. All three fixes are mechanical; the one judgement call — declining the `verify_all.sh:359` harmonization — is a *refusal to deviate* backed by measurement, which is fidelity, not drift.

Neither axis carries an open CRITICAL or MAJOR, so the aggregate is the more severe of the two: **MINOR**.

---

## Verdict (round 2 — operative)

> **APPROVED** — round 2: 0 CRITICAL, 0 MAJOR, **2 MINOR** (R2-1 new; MINOR #2 carried, architect-owned, with a delta-created addendum), **4 NIT**. Round-1 MINOR #1, #3 and #4 are **CLOSED**; round-1 NIT #2 is **TAKEN**; round-1 NIT #1 is **CLOSED as declined-with-reason**.

The delta does what a fix round should do and nothing else. Three MINORs discharged at exactly the sites named, seven operators flipped and not one unintended site touched, semantics preserved to the character apart from casing, four `hook-spec` copies edited at the source and propagated with the twin pairs still identical line-for-line. Every invariant the delta could have disturbed was re-measured by me rather than inherited: 32 checks with `G.4` last, 18 baseline keys frozen, `75-safety-hook.md` at 200, zero guard-path contamination, and — the check that mattered most for a round that edited two gate/test `.ps1` files — confirmation that neither has a `templates/common/` twin, so the propagation surface is exactly the four `hook-spec` copies and no more.

The strongest thing in this round is the refusal. My round-1 MINOR #4 offered a "cheap closure" that would have shipped a strictly worse matcher into a live gate; the developer measured it, found it introduces both a false FAIL and a false PASS, declined, documented the reason at the line a future harmonizer will edit, and surfaced the compounding trap that this host's interactive `grep` would have endorsed the bad fix. That is the correct handling of a reviewer suggestion, and it is worth more to this repo than the divergence it left open. The `:315` scope call is likewise right, and safer than the record claims — the `:338` fix removes the verdict risk entirely, leaving only a token-set asymmetry.

**Routing**

- **Developer or PM** (one line, no code): **R2-1** — add the `verify_all.ps1:315` residual to `04`'s "Open issues for review" as item 5. This is the only thing that must happen before delivery, and it is a record edit.
- **Solution-architect** (record only, no rework): **MINOR #2** as routed in round 1, now also refreshing `02_SOLUTION_DESIGN.md:369-370`'s dangling quotation and its `hook-spec.sh:142-147` → `:162-163` citation. Both belong in `07_DELIVERY.md`.
- **Stage 6 (QA)**: the four NITs are QA's at discretion, none blocking. The obligations that must travel: **RES-1** (unchanged), **R-1** (now correctly located and deliberately open), the new **`:315`** residual, and — binding — **operator items 14(a), 15(a) and 16 must be re-run against the round-2 bytes**. No `.ps1` in this change set has been parsed or executed by any agent, in either round.
