# 02 — Solution Design: sync-hook-dangling-ref (T-020)

Mode: full · Architect: solution-architect · Date: 2026-06-11
Upstream: `docs/features/sync-hook-dangling-ref/01_REQUIREMENT_ANALYSIS.md` (verdict READY)
Amendment 2026-06-11: gate verdict GO-WITH-CONDITIONS
(`docs/features/sync-hook-dangling-ref/03_GATE_REVIEW.md` §5). Condition **C3 (F-3)
adjudicated in §6.2.5** (literal-placeholder repair — option A); §2/§3/§5/§6.6/§6.7/§10/§12
updated accordingly; conditions C1/C2/C4 are Developer obligations per the gate, indexed in §9.1.

## 1. Architecture summary

The dangling-hook class is eliminated by making every flow's settings rewire **conditional on
the target script's (projected) presence**, and by adding one **terminal hook↔script congruence
assertion** to all four flows — deterministic (exit code + machine record) in the two helpers,
prose-mandatory in the two SKILL-driven flows. Diagnosis extends `/harness-status` (generalizing
its existing guard-rm tri-state to all four hook events plus interpreter availability) and the
shipped type `verify_all` templates (new `E.4b`/`D.4b` row). Repair stays `/harness-upgrade`
(S2 already re-lands scripts; we widen its refresh set to the ambient hook scripts and give it
the same congruence gate). No new command, no new shipped script, no new dogfood gate check:
the dogfood `verify_all` stays at 32. The RC-6 stale surfaces (template `E.3`/`D.3` "All 7
agents", `/harness-status` asset rows) are replaced with v0.30-correct partition-only semantics.
The ambient hooks' hard-coded `pwsh` is fixed by construction with two new OS-picked placeholders
(same proven mechanism as `{{SYNC_COMMAND}}`).

## 2. Open-question adjudications (Mode 2 — decided and logged)

### OQ-1 — `/harness-doctor` vs extending existing surfaces: **EXTEND (option a). No new command.**

Evidence:

- `/harness-status` §3b already computes the exact tri-state this task needs
  (`enabled` / `DISABLED` / `scripts missing`) for guard-rm (`skills/harness-status/SKILL.md:61-77`).
  FR-D1/D2 is a generalization of code-shaped prose that already exists; a doctor would duplicate it.
- `upgrade-project` S2 already re-lands missing `harness-sync.{ps1,sh}` from the current template
  (`templates/common/.harness/scripts/upgrade-project.sh:136-159`) and S3 rewires (`:161-182`).
  The repair mechanics exist; a doctor's "fix" button would shell out to the same helper.
- Insight 2026-06-09 (T-016): "prefer reusing an existing runtime tool as the composition step
  over adding a drift-guard" — same principle applies to a check+repair surface.
- A 16th skill costs README G.1 churn, doc fan-out, and a new name users must discover, for zero
  new capability. The user's question is answered in the deliverable: **diagnose = `/harness-status`,
  repair = `/harness-upgrade`** — and `/harness-status`'s Recommendations section will print exactly
  that routing when it finds a dangling hook.

### OQ-2 — Prevention mechanism: **(c) both**, split by flow determinism

- Deterministic helpers (`migrate-scripts-layout`, `upgrade-project`): presence-gated rewire
  (ordering fix, kills RC-1/RC-4 root cause) **plus** a terminal congruence scan with a dedicated
  exit code (the explicit-error surface FR-P1 requires).
- Prose flows (`/harness-init`, `/harness-adopt`): a mandatory terminal congruence step in the
  SKILL (RC-2/RC-3); ordering cannot be enforced on a model, so the end-state assertion is the contract.

### OQ-3 — Ambient `pwsh` hard-coding: **IN SCOPE, fixed by construction**

Same class as the reported defect (wired hook whose command cannot run, firing every turn /
session start), and A1 says the affected user is likely on a non-Windows shell. Fix is the
already-proven placeholder pattern: `{{AMBIENT_PROMPT_COMMAND}}` / `{{AMBIENT_RESET_COMMAND}}`
replace the two hard-coded commands (`settings.json.tmpl:64,74`), OS-picked at init/adopt with
the same rule as `{{SYNC_COMMAND}}` (`skills/harness-init/SKILL.md:187`). Cost is bounded and
mechanical: 2 whitelist entries in dogfood `verify_all` D.2 (both shells), 2 rows in each SKILL
substitution table, 2 substitutions in each test driver. Deferring would knowingly ship the next
error-storm instance of the exact class this task exists to kill.

### OQ-4 — FR-D3 bounding: **status rows + the six type-template E.3/D.3 rows only**

Plus the new E.4b/D.4b row those same six files gain. The wider v0.30 template-docs refresh
(workflow.md, rule fragments mentioning local framework agents, etc.) is a follow-up task.

### OQ-5 — Cross-OS repair: **diagnose only; never rewrite a runnable-variant choice silently**

`/harness-status` §3c reports "interpreter unavailable" with the exact swap instruction (the
`_doc_sync_hook` / `_ambient_hook` doc keys already document the swap). `/harness-upgrade` keeps
its raw-text path rewire; it does not re-pick variants. Rationale: the wired variant may be a
deliberate user choice (WSL bash on Windows, pwsh on Linux); a silent rewrite violates the
explicit-confirmation contract and B8's byte-safety discipline.

**Boundary (gate C3):** OQ-5 covers only *runnable, user-chosen* command variants. A wired
**unsubstituted literal placeholder** (B7) is never a deliberate choice — it cannot run on any
OS — so it is outside OQ-5 and IS rewritten to the OS-picked command by `/harness-upgrade`
(adjudicated per gate F-3; mechanism in §6.2.5).

### OQ-6 — Consumer verify_all placement: **new `E.4b` (generic/fullstack) / `D.4b` (backend) row**

Not an extension of E.4/D.4: that row's failure means "run harness-sync" (drift), the new row's
failure means "run /harness-upgrade" (dangling hook) — different fix commands must not share one
FAIL line. `E.4b` follows the dogfood repo's own precedent (`.harness/scripts/verify_all.sh:232`
E.4b) and avoids renumbering E.5/E.6. The row lives **outside** the `HARNESS:B-CUSTOM` markers,
so upgrade-time splice/regen logic is untouched.

## 3. Affected modules (existing files)

| File | Change class |
|---|---|
| `skills/harness-init/templates/common/.harness/scripts/migrate-scripts-layout.sh` + `.ps1` | RC-1 fix: gated rewire, move verification, terminal scan, exit 4 |
| `skills/harness-init/templates/common/.harness/scripts/upgrade-project.sh` + `.ps1` | RC-4 fix: S2 set widened + cp verified, S3 gated rewire **+ literal-placeholder repair (§6.2.5, gate C3)**, terminal scan, exit 4 |
| `.harness/scripts/migrate-scripts-layout.{ps1,sh}`, `.harness/scripts/upgrade-project.{ps1,sh}` | dogfood mirrors — land via `.harness/scripts/sync-self` (mappings 6 & 7, `sync-self.sh:78-84`) |
| `skills/harness-init/templates/common/.claude/settings.json.tmpl` | OQ-3: ambient placeholders + `_ambient_hook` doc text |
| `skills/harness-init/SKILL.md` | placeholder table +2 rows; new mandatory step 10b (terminal congruence) |
| `skills/harness-adopt/SKILL.md` | RC-3 fix: substitution table += `SYNC/GUARD/AMBIENT_*` commands; hooks-merge spec for all 4 events; terminal congruence step |
| `skills/harness-upgrade/SKILL.md` | exit-4 row (final text per gate C2); `REWIRE-PLACEHOLDER` record row (§6.2.5); repair framing; report line |
| `skills/harness-status/SKILL.md` | RC-6 asset rows; new §3c congruence report; health-score recount |
| `skills/harness-init/templates/{generic,fullstack}/.harness/scripts/verify_all.{sh,ps1}.tmpl` | E.3 replacement + new E.4b |
| `skills/harness-init/templates/backend/.harness/scripts/verify_all.{sh,ps1}.tmpl` | D.3 replacement + new D.4b |
| `.harness/scripts/verify_all.sh:84` + `.harness/scripts/verify_all.ps1:95` | D.2 placeholder whitelist += 2 names (bespoke dogfood files, not in sync-self set) |
| `.harness/scripts/test-init.{sh,ps1}`, `test-harness-upgrade.{sh,ps1}`, `test-real-project.{sh,ps1}` | new substitutions + assertions (see §10) |
| `CHANGELOG.md`, `.claude-plugin/plugin.json`, `marketplace.json`, README version badges | v0.31.0 release stamps (G.3); check count stays 32 → no G.4 count edits, only the `[0.31.0]` CHANGELOG heading |

Sync-self mirror set vs hand-maintained, stated explicitly (NFR-3): `migrate-scripts-layout` and
`upgrade-project` are in the mirror set — **edit the template copy, run sync-self**. The dogfood
`verify_all.{ps1,sh}`, the test drivers, and the dogfood `.claude/settings.json` are bespoke
(not mirrored). The dogfood `.claude/settings.json` needs **no change** (Windows-correct pwsh
commands; NFR-6 propose-only red line is not triggered).

## 4. Module decomposition

**No new shipped scripts, no new skills.** One new logical block, inlined per consumer:

### 4.1 Congruence scan (the invariant enforcer)

Logic (identical semantics in all consumers):

1. Take the **final** settings text (apply mode) or the **projected** text (dry-run).
2. For each line containing `"command"`: extract every match of the case-sensitive ERE
   `(\.harness/)?scripts/[A-Za-z0-9._-]+\.(ps1|sh)`; also flag the line if it contains an
   unresolved double-brace token (brace pair **assembled at runtime** from pieces —
   `o="{{"`-style, per insight 2026-06-08 / `upgrade-project.sh:274` technique — so neither the
   helper nor a generated verify_all ever contains a literal placeholder token).
3. For each unique extracted relative path: test file existence against (projected) presence.
4. Each miss is a violation carrying `<command text> -> missing <path>`.

Line-scoping to `"command"` lines is deliberate: `permissions.allow` entries and the `_doc_sync_hook`
/ `_ambient_hook` doc strings mention both shell variants and must NOT force both variants to exist
(B4: only the wired variant is load-bearing). `"type": "command"` lines match the grep but contain
no path token — harmless.

**Projected presence** (B9 dry-run support): `target_present(name)` = file exists at
`.harness/scripts/<name>` **or** (migrate dry-run) a `MOVE` of `<name>` is in the plan **or**
(upgrade dry-run) the template carries `<name>` so S2 would land it. In apply mode the disk is
ground truth because the scan runs last.

**Why inline, not a shared `hook-congruence.{ps1,sh}` script:** a shared shipped script is itself
a file that can be absent — a congruence checker that dangles is self-defeating; it would also add
an F.1 pair, a sync-self mapping, and a bootstrap step. The core is ~15 lines; the four helper
copies stay aligned by the existing within-pair parity discipline, and the template rows / SKILL
prose are different output shapes anyway. Decision logged.

### 4.2 Consumers of the scan

| Consumer | Output shape | On violation |
|---|---|---|
| `migrate-scripts-layout.{ps1,sh}` | human plan lines: `CONGRUENCE-FAIL  <command> -> missing <path>` + hint `run /harness-upgrade to re-land current scripts` | exit **4** (both modes) |
| `upgrade-project.{ps1,sh}` | record `CONFLICT\|congruence\|<command> -> missing <path>` (existing record family) | `n_conflicts++`, exit **4** (overrides 2/3; scan runs last) |
| type `verify_all` E.4b/D.4b row | `FAIL "hook command references missing script: <path> — fix: run /harness-upgrade"`; SKIP if no `.claude/settings.json` | consumer gate FAIL |
| `/harness-init` step 10b, `/harness-adopt` step 6-final | prose assertion via Read/Glob; flow reports **failure**, success summary withheld | flow failure (FR-P4) |
| `/harness-status` §3c | per-event status lines | report only (read-only skill) |

## 5. Data model / contract changes (no DB; file-level contracts)

1. **New exit code `4`** for both helpers: "end-state assertion failure — a wired hook command
   does (or would) reference a missing script, or a move/refresh did not land." Documented in both
   helper headers and the `/harness-upgrade` SKILL exit table. Existing codes 0/1/2/3 unchanged;
   healthy-project runs keep exiting 0 (B10 fixed-point preserved).
2. **New record kind** `CONFLICT|congruence|<detail>` from `upgrade-project` (reuses the existing
   `CONFLICT|<kind>|<detail>` shape — the SKILL's parser table needs no new prefix, only a row
   documenting the new kind). Additional S2 gap record: `GAP|template-missing|absent|<name>` when
   the template lacks a refresh-set script that the project also lacks (replaces the silent
   `[[ -f "$tmpl_file" ]] || continue` for that case). New S3 record verb
   `REWIRE-PLACEHOLDER|.claude/settings.json (<NAME> -> <os-picked command>)` — one line per
   repaired literal token, token name printed **without** braces so neither helper source nor
   stdout ever carries a literal `{{...}}` token (§6.2.5; gate C3).
3. **Two new placeholders** (rule 10 §9-10 discipline):

   | Placeholder | Windows | macOS/Linux |
   |---|---|---|
   | `{{AMBIENT_PROMPT_COMMAND}}` | `pwsh -NoProfile -File .harness/scripts/ambient-prompt.ps1` | `bash .harness/scripts/ambient-prompt.sh` |
   | `{{AMBIENT_RESET_COMMAND}}` | `pwsh -NoProfile -File .harness/scripts/ambient-reset.ps1` | `bash .harness/scripts/ambient-reset.sh` |

   OS detection: same rule as `{{SYNC_COMMAND}}` (`harness-init/SKILL.md:187`). Whitelisted in
   dogfood D.2 (`verify_all.sh:84`, `verify_all.ps1:95`). Used only in `.claude/settings.json`.
4. **S2 refresh set widened**: `ambient-prompt.{ps1,sh}` + `ambient-reset.{ps1,sh}` join
   `refresh_set` (`upgrade-project.sh:136-142`, `.ps1:151-157`). They are hook targets — repair
   (FR-R1) must be able to re-land them or FR-D2 would flag states `/harness-upgrade` can't fix.
   The S1 `known` array is **unchanged** (ambient scripts never lived at top-level `scripts/`;
   they shipped post-relocation in T-011). The hand-maintained INVARIANT comments in both files
   (`upgrade-project.sh:92,134`) are restated: "refresh_set == (known minus verify_all.*,
   baseline.json) plus the ambient hook pair".
5. **settings.json schema (rule 80 / NFR-2)**: all edits remain raw-text command-string changes
   inside existing `hooks` entries — no new keys, no event-name changes, `$schema` untouched.
   Developer must still consult the upstream schema via context7/WebFetch before editing the
   `.tmpl` and run J.1 (the rule is procedural, not waivable).

## 6. File-by-file change plan

### 6.1 `migrate-scripts-layout.{sh,ps1}` (template source; mirror via sync-self)

1. **Move verification** (RC-1 unchecked `git mv`/`mv`, `sh:76-81`, `ps1:75-80`): after each
   apply-mode move, assert the destination file exists; on failure emit
   `MOVE-FAILED scripts/<name> (move did not land — see git output above)` and mark the run
   incongruent (exit 4 at end). Note: a failed move leaves the source in place, so the settings
   rewire gate (below) simply stays off for that variant — the hook keeps pointing at the
   still-existing legacy file (no new dangle is ever created by a failed move).
2. **Per-variant presence-gated rewire** (replaces the two unconditional prefix seds,
   `sh:94-97` / `ps1:92-98`): for each of the 4 combinations `{harness-sync,guard-rm} ×
   {ps1,sh}`, apply `s|scripts/<tool>.<ext>|.harness/scripts/<tool>.<ext>|g` **only if**
   `target_present("<tool>.<ext>")`; keep the unconditional double-prefix collapse
   `s|\.harness/\.harness/scripts/|.harness/scripts/|g` last. Fixed-point property is preserved
   exactly as today (already-migrated text → double prefix → collapse → identity), so B10
   (second run = no `.bak`, no write) holds.
3. **Terminal congruence scan** (§4.1) after the settings write (or against `settings_new` +
   projected presence in dry-run). Violations print the explicit lines (naming command + missing
   path + the `/harness-upgrade` remediation) and set exit 4. Header comment documents exit 4.
4. PS side mirrors 1:1; use `-creplace`-free literal `.Replace(...)` per variant (case-sensitive
   by construction) and `[regex]` with **no** IgnoreCase for the scan (insight 2026-05-19 family).

### 6.2 `upgrade-project.{sh,ps1}` (template source; mirror via sync-self)

1. **S2**: add the ambient pair to `refresh_set` (§5.4). Replace the silent template-absent skip
   (`sh:144`, `ps1` analog) with: if template lacks it AND project lacks it → emit
   `GAP|template-missing|absent|.harness/scripts/<name>`; if project has it → `NOOP` (existing
   copy retained). Verify the `cp` landed: `cp ... && cmp -s ...` else emit
   `CONFLICT|refresh|.harness/scripts/<name> copy failed` (covers RC-4's undetected-cp window
   under `set -uo` without `-e`).
2. **S3**: same per-variant presence-gated rewire as §6.1.2 (`sh:166-169`, `ps1:179-196`). In the
   normal flow S2 has just landed both variants, so the gate is transparently true — behavior on
   healthy projects is byte-identical to today (idempotence assertions in test-harness-upgrade
   stay green).
3. **Terminal congruence scan** after S5, immediately before `SUMMARY|...`: emits
   `CONFLICT|congruence|...` per violation, increments `n_conflicts`, sets exit 4 (the scan is
   the last writer of `exit_code`, so 4 wins over 2/3 — an incongruent end state is the most
   actionable failure). Dry-run: scan runs against projected state and is included in the plan.
4. Header comment + exit-code roster updated in both shells.

#### 6.2.5 C3 adjudication: literal-placeholder repair (gate F-3) — **DECIDED: option A**

**Decision.** `upgrade-project.{sh,ps1}` S3 gains a bounded literal-token repair pass: a wired,
unsubstituted placeholder token in `.claude/settings.json` is rewritten to the OS-picked command
(same pick rule as init). This delivers B7's repair half (`01_REQUIREMENT_ANALYSIS.md` §5 B7);
the B7 contract is NOT amended.

**Rationale** (Mode 2, decided and logged):

- B7 is an explicit contract in a READY requirement: "repair rewires to the OS-picked command".
  Without this pass, S3's prefix replaces can never touch a literal token (no
  `scripts/harness-sync.` substring exists in it) — diagnosis without repair, gate F-3.
- OQ-5 is untriggered (gate ruling concurred): an unsubstituted placeholder is never a deliberate
  user choice — it is RC-3's improvisation failure and cannot run on any OS. Rewriting it cannot
  destroy intent; *not* rewriting it leaves a state whose only fix is hand-editing settings.json.
- Cost is bounded and root-causal: ~15 lines per shell inside a file already in the footprint,
  reusing two proven mechanisms (assembled-brace tokens, `upgrade-project.sh:265-279`; OS-pick
  rule, `skills/harness-init/SKILL.md:187-188`). No new file, no new exit code, no new `.bak`
  semantics.

**Repair table** (token → OS-picked command; gate target = the picked variant's script):

| Token name (braces assembled at runtime) | Windows (`$IsWindows` / `$OSTYPE` = `msys*\|cygwin*\|win32`) | macOS / Linux | Gate target |
|---|---|---|---|
| `SYNC_COMMAND` | `pwsh -NoProfile -File .harness/scripts/harness-sync.ps1` | `bash .harness/scripts/harness-sync.sh` | `harness-sync.<picked ext>` |
| `GUARD_COMMAND` | `pwsh -NoProfile -File .harness/scripts/guard-rm.ps1` | `bash .harness/scripts/guard-rm.sh` | `guard-rm.<picked ext>` |
| `AMBIENT_PROMPT_COMMAND` | `pwsh -NoProfile -File .harness/scripts/ambient-prompt.ps1` | `bash .harness/scripts/ambient-prompt.sh` | `ambient-prompt.<picked ext>` |
| `AMBIENT_RESET_COMMAND` | `pwsh -NoProfile -File .harness/scripts/ambient-reset.ps1` | `bash .harness/scripts/ambient-reset.sh` | `ambient-reset.<picked ext>` |

Commands are verbatim the init step-5 values (`harness-init/SKILL.md:187-188` + §5.3 of this
design); all four gate targets are in the widened S2 `refresh_set` (§5.4), so in the normal flow
the gate is transparently true.

**Mechanism.**

- **Placement & ordering**: a new *first* pass inside S3, on the raw settings text, **before**
  the per-variant prefix rewires of §6.2.2 and the double-prefix collapse; the §6.2.3 terminal
  congruence scan still runs last. S2 has already run, so apply-mode gating uses disk truth;
  dry-run gating uses §4.1 projected presence (template carries the script → S2 would land it).
- **Per token**: assemble `tok = "{{" + NAME + "}}"` from pieces (`o="{{"`/`c="}}"` locals, per
  insight 2026-06-08 — neither helper may contain a literal token); pick the command by OS; if
  the text contains `tok` **and** `target_present(<gate target>)`: globally replace `tok` →
  command and emit `$(verb_prefix)|REWIRE-PLACEHOLDER|.claude/settings.json (<NAME> -> <command>)`.
  If the gate is false, the token is left untouched (a MALFORMED token must not become a DANGLING
  path — no new dangle class) and the terminal scan's unresolved-token check flags it → exit 4.
- **sh**: fixed-string detection via `grep -qF -- "$tok"`; replacement via bash parameter
  expansion `txt="${txt//"$tok"/$cmd}"` (quoted pattern = literal; avoids sed-escaping the
  replacement command). OS pick per the init rule's bash test (`$OSTYPE` table above).
- **ps1**: `$new.Contains($tok)` + `$new.Replace($tok, $cmd)` — ordinal, case-sensitive (R1
  discipline); OS pick via `$IsWindows`. On a Windows machine Git-Bash reports `OSTYPE=msys` →
  both shells pick the same (pwsh) command → AC-7 cross-shell byte-compare of the resulting
  settings.json holds.
- **Write path unchanged**: the pass only mutates the in-memory `settings_new` text; the existing
  single change-detection → one `REWIRE` record, one timestamped `.bak` iff content changed,
  one raw-text write (FR-R3, B8) — `.bak` semantics untouched, `n_rewired` semantics untouched
  (per-file, not per-token).
- **Idempotence / fixed point (B10)**: replacement values contain no `{{`, so a second run finds
  no token → pass is a no-op. Interplay with §6.2.2 is the existing fixed point: the substituted
  command's `scripts/<tool>.` substring is prefix-matched → double prefix → collapse → identity.
  Net: healthy and once-repaired projects keep exiting 0 with zero writes.

**Scope notes**: `migrate-scripts-layout` does NOT substitute placeholders — its terminal scan
(§6.1.3) flags the unresolved token with the `/harness-upgrade` hint (one repair surface, per
FR-R1). `/harness-status` §3c's MALFORMED fix line ("run /harness-upgrade") is now backed by an
actual repair (§6.7). `/harness-adopt` prevention (§6.5) remains the construction-side fix for
RC-3; this pass is the repair-side complement for already-shipped damage.

### 6.3 `settings.json.tmpl` (template; J.1-guarded)

- `:64` → `"command": "{{AMBIENT_PROMPT_COMMAND}}"`; `:74` → `"command": "{{AMBIENT_RESET_COMMAND}}"`.
- `_ambient_hook` (`:6`): replace the "Commands below are the Windows default; on macOS/Linux …
  change them to …" sentence with "Commands were OS-picked at init time (Windows → pwsh
  -NoProfile, elsewhere → bash). Swap freely if your environment differs." (mirrors
  `_doc_sync_hook`'s wording). No structural JSON change → J.1 stays green.

### 6.4 `harness-init/SKILL.md`

- Placeholder table (after `:188`): two new rows per §5.3.
- New **step 10b — Hook congruence assertion (mandatory)** between steps 10 and 11: read the
  written `.claude/settings.json`; for every `"command"` line extract script paths with the §4.1
  ERE; assert each file exists (Glob/Read) and that the file contains no unresolved `{{…}}`
  token; on any violation report **flow failure** naming hook event, command, and missing path,
  instruct re-copying the named file(s) from `<skill-root>/templates/common/.harness/scripts/`,
  and **do not print the step-11 success summary** until the assertion passes. Failure-handling
  section (`:467-472`) gains a pointer to 10b. (The "no verify_all at init" rule `:463` is
  untouched — 10b is a file-existence assertion, not a gate run.)

### 6.5 `harness-adopt/SKILL.md`

- Substitution table (`:295-303`) += `{{SYNC_COMMAND}}`, `{{GUARD_COMMAND}}`,
  `{{AMBIENT_PROMPT_COMMAND}}`, `{{AMBIENT_RESET_COMMAND}}` — each citing the init OS-pick rule
  (`harness-init/SKILL.md` step 5 table) rather than duplicating it. This closes RC-3's
  improvised-Stop-command gap.
- The settings special-case (`:242-264`) is generalized from "PreToolUse merge" to **"hooks merge
  (all four events)"**: target absent → copy template with all four commands substituted; target
  exists → per event: no entry → add the OS-picked entry; entry pointing at the harness script →
  leave; entry pointing elsewhere → log to `.harness-adopt/CONFLICTS.md`, do not modify (existing
  conflict discipline). This makes merge mode finally reconcile the Stop hook (RC-3's second gap).
- End of step 6 (after `:312`): the same mandatory terminal congruence assertion as init 10b,
  also covering merge mode. **Gate condition C4 extends this step — implement per
  `03_GATE_REVIEW.md` §5**: after any merge-mode settings write, additionally assert JSON parses,
  `$schema` is canonical, hook keys are valid event names, and `_*` doc keys survived.

### 6.6 `harness-upgrade/SKILL.md`

- Step 6 exit table += `4 | post-run hook↔script congruence failure — a wired hook still
  references a missing script | relay each CONFLICT|congruence line; if the missing file is not
  a template-shipped script (user-custom hook command), tell the user to restore it manually`.
  **Gate condition C2 governs this row's final text — implement per `03_GATE_REVIEW.md` §5**:
  the row must also instruct processing of co-occurring `VERIFY-HALT` / `CONFLICT|verify_all` /
  `CONFLICT|hook` records (their exit-2/3 remediations still apply when 4 wins), and state that
  exit 4 can fire on the dry-run leg (projected-state violation) with plan presentation unchanged.
- Records table (`SKILL.md:115-131`) += a row for the `REWIRE-PLACEHOLDER` verb (§6.2.5): relay
  each line in the report as a repaired-item ("unsubstituted placeholder rewired to the OS-picked
  command").
- "When to invoke" += the repair framing: "also the repair path when `/harness-status` (or a
  per-turn `Stop hook error: … No such file or directory`) reports a dangling hook."
- Step 7 report += `Congruence:  OK — every wired hook command resolves to an existing script`
  (or the conflict lines verbatim), plus any `REWIRE-PLACEHOLDER` lines under "Repaired".

### 6.7 `harness-status/SKILL.md`

- §1 asset table: delete the "All 7 agents" (`:24`) and "Supervisor" (`:25`) rows; add a note
  line under the table: "Framework agents (7 + supervisor) are plugin-provided
  (`harness-kit:<name>`) since v0.30 — not project files, not checked here. Partitioned projects
  only: `.harness/agents/dev-*.md` synced to `.claude/agents/` (report if present, absence is
  healthy)." Resulting required-asset count = **14**; §6 health score updated to "All 14 required
  assets present → +6" (fixes the pre-existing 15-vs-16 mismatch as a side effect).
- New **§3c Hook ↔ script congruence (all events)**: for every
  `hooks.{Stop,PreToolUse,UserPromptSubmit,SessionStart}[].hooks[].command`, report per event:
  `ok` / `not wired` / `DANGLING — <command> -> missing <path>` / `MALFORMED — unsubstituted
  placeholder` — each non-ok line carries the fix (`run /harness-upgrade`; B7 included — for
  MALFORMED that fix is now an actual repair, §6.2.5, not just a re-land). Plus the
  WARN-level interpreter check (FR-D2/OQ-5): first token (`pwsh`/`bash`) not on PATH →
  "wired to <tok> but <tok> is unavailable on this OS — swap the command variant (see the
  `_doc_sync_hook` / `_ambient_hook` notes in settings.json)". §3b (guard-rm deep check) stays
  as-is; the Stop/sync hook gets the same tri-state vocabulary (FR-D1). §7 Recommendations gains
  the routing line when §3c is non-ok.

### 6.8 Type `verify_all` templates (6 files; both shells per type, byte-parity within each pair)

- **E.3 / D.3 replacement** (generic `sh:66-70`/`ps1:104-110`; fullstack `sh:162-166`/`ps1:141+`;
  backend `sh:177-181`/`ps1:163+`): new semantics "Agents layout v0.30+ (.harness/agents/ =
  partition dev-* only)": PASS if `.harness/agents/` is absent or every `*.md` in it matches
  `dev-*.md`; **WARN** (not FAIL) listing the non-partition filenames with "framework agents are
  plugin-provided since v0.30 — remove local copies". WARN keeps an upgraded-but-unmigrated
  project's gate non-red (upgrade v1 does not delete agent files) while still surfacing the skew;
  a healthy v0.30 fixture reports 0 FAIL for this row (AC-3/AC-4).
- **New E.4b / D.4b row** directly after E.4/D.4, outside the B-CUSTOM markers: the §4.1 scan in
  check-row form (SKIP when `.claude/settings.json` absent — B1; FAIL names command + missing
  path + "fix: run /harness-upgrade"). This catches B3 (hook → legacy `scripts/` path whose file
  was deleted), B7 (`{{` literal), and the user's exact reported state. Brace detection uses the
  assembled-token technique so test-init's unresolved-placeholder scan stays clean.

### 6.9 Dogfood gate + drivers

- `verify_all.sh:84` / `verify_all.ps1:95`: D.2 whitelist += the two ambient placeholders.
  **No new dogfood check** → count stays 32, G.4 needs no count edits (only the `[0.31.0]`
  CHANGELOG heading); **no I.6 banned-list change** → the four-file lockstep (insight 2026-06-08)
  is not triggered. The stale-claim removal is done at the sources; we deliberately do not add an
  "All 7 agents" banned anchor (design-over-guards; the phrase survives legitimately in
  CHANGELOG history, which is I.6-exempt anyway).
- Test drivers: see §10.

## 7. Sequence / flow (repair path, the user's scenario)

```
broken project (Stop hook -> bash .harness/scripts/harness-sync.sh, file absent)
  │
  ├─ /harness-status                      ← diagnosis
  │    §3c: Stop: DANGLING — "bash .harness/scripts/harness-sync.sh"
  │         -> missing .harness/scripts/harness-sync.sh
  │    §7:  "Run /harness-upgrade to re-land current scripts and rewire hook paths."
  │
  └─ /harness-upgrade                     ← repair
       step 4: bootstrap upgrade-project.{ps1,sh} from plugin cache
       step 5: dry-run → plan shows REFRESH .harness/scripts/harness-sync.{ps1,sh} (S2)
               + projected congruence: OK  → user confirms
       apply:  S1 (no-op) → S2 re-lands harness-sync + guard-rm + ambient pair
               → S3 gated rewire (targets present → rewire/no-op)
               → S4/S5 → terminal congruence scan: 0 violations → SUMMARY, exit 0
       step 7: verify_all green (E.4b PASS) → report "Congruence: OK"
       re-run: NOOP end-to-end, no .bak (FR-R2)
```

Prevention path (RC-1 fixture): `migrate-scripts-layout` on a project missing
`scripts/harness-sync.sh` → move loop skips (source absent) → `target_present(harness-sync.sh)`
false → that variant's rewire **not applied** → terminal scan: the wired legacy command
`scripts/harness-sync.sh` is missing on disk → `CONGRUENCE-FAIL` line + exit 4 (was: silent
rewire to a dangling `.harness/...` path, exit 0).

## 8. Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| Re-land missing scripts (repair) | `upgrade-project` S2 content-refresh | `templates/common/.harness/scripts/upgrade-project.sh:136-159` | Reuse; widen refresh set by ambient pair |
| Raw-text settings rewire, `.bak`, fixed-point idempotence | S3 / migrate sed-replace blocks | `upgrade-project.sh:161-182`, `migrate-scripts-layout.sh:94-113` | Extend with per-variant presence gates; never re-serialize (rule 80) |
| Hook congruence tri-state reporting | guard-rm safety-hook status | `skills/harness-status/SKILL.md:61-77` | Generalize pattern to §3c (all events) |
| OS-picked hook command substitution | `{{SYNC_COMMAND}}` / `{{GUARD_COMMAND}}` | `skills/harness-init/SKILL.md:187-188` | Same mechanism for the 2 ambient placeholders |
| Placeholder-token-without-literal technique | `substitute_placeholders` assembled braces | `upgrade-project.sh:265-279` (insight 2026-06-08) | Reuse in scan + E.4b rows |
| Conflict surfacing records | `CONFLICT\|<kind>\|<detail>` protocol | `upgrade-project.sh` / `harness-upgrade/SKILL.md:115-131` | Reuse kind `congruence`; no new prefix |
| Template↔dogfood mirroring | sync-self mappings 6-7 | `.harness/scripts/sync-self.sh:78-84` | Reuse as the propagation step; no new mapping needed |
| E.4b-style supplementary row ID | dogfood E.4b precedent | `.harness/scripts/verify_all.sh:232` | Reuse naming convention in templates |
| Old-layout fixtures + settings asserts | test-harness-upgrade fixture builder | `.harness/scripts/test-harness-upgrade.sh:38-110` | Extend with dangling/migrate fixtures |
| Hook↔script congruence checker as a shipped standalone script | (none found) | — | Deliberately NOT built — inlined per consumer (§4.1 rationale) |

## 9. Risk analysis

| # | Risk | Mitigation |
|---|---|---|
| R1 | Cross-shell divergence in the scan (PS case-insensitive operators, line-split traps, trailing-newline writes) | Case-sensitive ops only (`-cmatch`/`[regex]` without IgnoreCase — insight 2026-05-19 family); `.Split("`n")` not `-split` (insight 2026-06-08); QA runs both shells on the same fixture and `cmp`s the resulting settings.json bytes (AC-7). Known pre-existing nuance: migrate `sh` writes via `printf '%s\n'` vs `ps1` `WriteAllText` — behavior-identical on newline-terminated JSON (our shape); not widened by this change, not fixed here. |
| R2 | New exit 4 breaks an existing caller's `exit 0` assumption | Exit 4 only fires on states that previously ended **silently broken**; healthy/idempotent paths still exit 0 (B10). Both SKILL exit tables and helper headers document it; test drivers assert it explicitly. |
| R3 | E.3→WARN reclassification masks a real problem (legacy framework agents shadowing plugin agents via harness-sync) | WARN text names the exact remediation; `/harness-status` §1 note repeats it; full agent-copy cleanup is the bounded follow-up (OQ-4). FAIL was rejected because `/harness-upgrade` v1 cannot remove agent files, and "upgrade ends red with no in-flow fix" violates its own success contract. |
| R4 | Scan false-positives on user-customized commands (wrapped interpreters, spaces in paths) | The strict ERE only matches plain `(.harness/)?scripts/<name>.<ext>` tokens and only flags **missing** files — anything unmatchable is ignored (fail-open diagnosis; prevention never blocks on what it cannot parse). Documented in helper comments. |
| R5 | test-init unresolved-placeholder scan trips on the new check/scan code | All brace tokens assembled from pieces at runtime (proven technique, insight 2026-06-08); test-init's recursive scan is itself the regression for this. |
| R6 | Mirror drift (template edited, dogfood copy stale) | Existing gate already enforces: E.1 runs `sync-self --check` (`verify_all.sh:193-198`); F.1 pair-presence unchanged. |
| R7 | Prose steps (init 10b / adopt terminal assert) skipped by a future model run | The deterministic backstops still hold the invariant: generated E.4b FAILs on first verify_all, `/harness-status` §3c reports it, `/harness-upgrade` repairs it. Prevention-prose is the first line, not the only line. |
| R8 | J.1 / schema regression from the `.tmpl` edit | Commands-only string change; rule 80 procedure (consult upstream schema first) is restated as a developer hard step; J.1 validates both the dogfood settings and the `.tmpl` at the gate. |

### 9.1 Gate conditions — one coherent source for the Developer

The gate (`docs/features/sync-hook-dangling-ref/03_GATE_REVIEW.md` §5) attached four conditions.
C3 is adjudicated in this amendment; **C1/C2/C4 are fully specified by the gate — implement per
`03_GATE_REVIEW.md` §5**, no further design needed:

- **C1 (F-1)**: left-boundary the §4.1 scan ERE in all five consumers (quote/space/`=`/
  start-of-string before `(\.harness/)?scripts/`) so dirnames merely *ending* in `scripts/`
  (e.g. `build-scripts/deploy.sh`) cannot match; evidence = an **actual matcher run** over
  fixture settings including such a custom command, output pasted into 04/06 docs (insight
  2026-05-23). This supersedes R4's "anything unmatchable is ignored" reasoning, which the gate
  showed wrong in the substring-over-matching direction.
- **C2 (F-2)**: the exit-4 SKILL row's co-occurrence and dry-run-leg semantics — wired into
  §6.6 above.
- **C3 (F-3)**: adjudicated — **§6.2.5 is the binding spec** (option A: bounded
  literal-placeholder repair in `upgrade-project` S3); AC-9 / Fixtures P+P2 in §10 exercise it.
- **C4 (F-6)**: the adopt terminal assertion's merge-mode integrity checks — wired into §6.5
  above.

## 10. Test plan sketch (QA stage 6, mechanically verifiable)

**`test-harness-upgrade.{sh,ps1}`** (extends existing fixture builder `sh:38-110`):

- Fixture G — *dangling repair (AC-2, FR-R1/R2)*: settings wired to
  `.harness/scripts/harness-sync.sh`, no harness-sync anywhere → apply → assert wired command's
  target exists; invoking the wired command from project root exits 0; exit code 0; re-run →
  no new `.bak`, byte-identical settings.
- Fixture H — *incongruent end state (FR-P3)*: crafted `--template-root` whose common/scripts
  lacks `harness-sync.*` + project lacks it → assert `GAP|template-missing`,
  `CONFLICT|congruence` naming the path, exit 4, and settings still references the **legacy**
  path (no dangling rewire).
- Fixture P — *B7 literal-placeholder repair (gate C3 / AC-9)*: settings Stop-hook command is
  the literal `SYNC_COMMAND` token — the fixture builder assembles `{{` + name + `}}` from
  pieces so driver sources stay literal-free (insight 2026-06-08) — and no `harness-sync.*`
  exists in the project (combined RC-3 state). Dry-run leg first: plan contains
  `PLAN|REWIRE-PLACEHOLDER` and the file is untouched. Apply: assert the wired command equals
  the machine's OS-picked variant (per the §6.2.5 table), no assembled `{{` remains anywhere in
  settings, the command's target file exists, invoking the wired command from project root exits
  0, helper exit 0, exactly one new `.bak`. Re-run → NOOP, no new `.bak`, byte-identical
  settings (B10). Both shells; AC-7 `cmp` of the two shells' resulting settings.json.
- Fixture P2 — *gated-off placeholder creates no new dangle (§6.2.5 gate)*: same settings +
  crafted `--template-root` whose common/scripts lacks `harness-sync.*` → assert the token is
  NOT substituted (still present verbatim), terminal scan emits a `CONFLICT|congruence`
  unresolved-token violation, exit 4.
- Fixture M1 — *RC-1 (AC-1)*: pre-relocation fixture, settings → `scripts/harness-sync.ps1`,
  source file deleted → run `migrate-scripts-layout` (both shells) → assert settings does NOT
  contain `.harness/scripts/harness-sync.ps1`, output contains `CONGRUENCE-FAIL` + the path,
  exit 4. M2 — healthy pre-relocation → unchanged behavior, exit 0, second run no-op (B10).
- AC-6 asserts after every fixture that writes settings: JSON parses, `$schema` canonical, hook
  keys valid, `_*` keys + order preserved, `.bak` written iff content changed.

**`test-init.{sh,ps1}`**: add the 2 ambient substitutions (`sh:43-62`, `ps1:112-113,521-522,632-633`);
new assertions: (a) every `"command"`-line script path in generated settings exists on disk
(AC-5); (b) ambient commands equal the OS-matching variant; (c) generated `verify_all` contains
the new E.3 wording + an E.4b/D.4b row and does NOT contain the retired 7-agents check; (d)
mutation probe: delete `harness-sync.sh` from the generated tree → the 10b assertion procedure's
deterministic core (the same grep/exists check, run by the driver) reports the violation (AC-5
mutation half).

**`test-real-project.{sh,ps1}`**: substitutions += ambient pair (`sh:41-54`, `ps1:110`); run the
generated type `verify_all` on (a) a healthy v0.30 single-dev fixture (no `.harness/agents/`) →
E.3 PASS + E.4b PASS, 0 FAIL on the touched rows (AC-3/AC-4 healthy half); (b) after deleting
`.harness/scripts/harness-sync.*` → E.4b FAIL naming the path + fix command (AC-4).

**QA cross-shell + gate (AC-7/AC-8)**: `cmp` bash-vs-PS settings outputs per fixture;
`sync-self --check` clean; dogfood `verify_all` 32/32 both shells; tallies pasted from captured
runs (insight 2026-06-04 — no hand-written numbers).

**AC-9 (added by this amendment, gate C3 — B7 repair half).** Fixture P/P2 assertions above:
a wired literal placeholder is repaired to the OS-picked command idempotently when the target
can land, and is flagged (exit 4) without substitution when it cannot. Complements AC-3, which
covers B7's diagnosis half only. (`01_REQUIREMENT_ANALYSIS.md`'s AC list is unedited per
pipeline rules; gate review §5 C3 plus this section carry the addition for QA.)

## 11. Migration / rollout plan

1. **Version**: v0.31.0 (minor — new exit code, new placeholders, template behavior). Stamps:
   `plugin.json` + `marketplace.json` + README badges (G.3), CHANGELOG `[0.31.0]` heading (G.4).
   Check count stays 32 → no count claims move (insight 2026-06-05 satisfied trivially).
2. **Order of landing** (single PR, but reviewable in this order): template helpers → sync-self →
   `settings.json.tmpl` + SKILL tables → type verify_all templates → status/upgrade/init/adopt
   SKILL prose → dogfood D.2 whitelist → test drivers → release stamps.
3. **Consumer adoption**: fresh `/harness-init`/`/harness-adopt` projects get everything by
   construction. Existing projects: `/harness-upgrade` re-lands current helpers + scripts (S2,
   now incl. ambient pair) and regenerates `verify_all` with the new rows (S5 splice preserves
   their B.*). Existing projects' ambient `pwsh` commands are **not** auto-rewritten (OQ-5) —
   §3c diagnoses and prints the swap.
4. **Backwards compatibility**: exit 0/1/2/3 semantics unchanged; settings shape untouched
   (raw-text, `_*` keys preserved, FR-R3); old verify_all files keep working until regenerated.
   Rollback = git revert (no data, no migrations); per-project rollback of an upgrade run =
   existing `.bak` + `git reset` contract.

## 12. Out-of-scope clarifications

- No redesign of the sync mechanism (plugin-hosted hooks, removing harness-sync) and no hook
  removal for single-dev projects (RC-5 settled: the Stop hook stays for all shapes — FR-P5).
- No auto-repair at hook-fire time; repair runs only under `/harness-upgrade` confirmation (A3).
- No removal/migration of legacy framework-agent copies in old projects (E.3 WARNs; cleanup is a
  follow-up task), and no template-docs refresh beyond the six E.3/D.3 rows + status rows (OQ-4).
- No re-picking of OS variants by repair for runnable, user-chosen commands (OQ-5) — distinct
  from §6.2.5, which rewrites only never-runnable unsubstituted placeholder literals (gate C3).
  Also: no Copilot/Cursor surfaces, no CI edits, no downgrade path, no new dogfood verify_all
  check, no I.6 banned-list changes.
- The pre-existing migrate `sh`-vs-`ps1` trailing-newline nuance on non-newline-terminated
  settings files (R1) is recorded, not fixed here.

## 13. Partition assignment

`.harness/agents/` contains no `dev-*.md` in this repo (single-Developer mode) — per the contract
this section is omitted; the whole change set goes to the single `harness-kit:developer`.

## 14. Verdict

**READY** — design is implementable without further design decisions: every change is specified
at file/line granularity, all six open questions are adjudicated with recorded rationale, the
invariant (FR-P1) has one definition (§4.1) and five enumerated consumers, and the test plan maps
1:1 onto AC-1..AC-9 with named drivers and fixtures. Gate condition C3 is adjudicated in §6.2.5
(option A); C1/C2/C4 are indexed in §9.1 and implemented per `03_GATE_REVIEW.md` §5.
