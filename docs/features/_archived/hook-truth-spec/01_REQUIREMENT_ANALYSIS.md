# 01 — Requirement Analysis · T-13 `hook-truth-spec`

**Mode**: `full` · **Stage**: 1 (requirement-analyst) · **Date**: 2026-07-31
**Gate baseline at dispatch**: `verify_all` bash PASS 32 / WARN 0 / FAIL 0 — check count must remain 32.

---

## 1. Goal

The byte-form and failure semantics of each harness lifecycle-hook command are hand-duplicated across
many artifacts, so a change to one form silently desynchronizes the others; this task creates one
executable source of truth for `(hook event × target OS) → command string + failure semantics` and
proves it by having the one-shot local-environment installer regenerate this repo's missing
machine-local hook settings file from that source, idempotently.

**Glossary note**: this doc uses the term **hook wiring spec** (added to `CONTEXT.md`) for the single
source, and **machine-local settings** for the gitignored per-machine Claude settings file that carries
this repo's own hooks.

---

## 2. In-scope behaviors

### A. The hook wiring spec (the single source)

**FR-1.** A single artifact — invocable from both the PowerShell and the Bash environment — answers the
query `(hook tool, target OS) → command string`. The four hook tools are the sync tool (`Stop` event),
the destructive-command guard (`PreToolUse`, matcher `Bash`), the ambient prompt heartbeat
(`UserPromptSubmit`), and the ambient session reset (`SessionStart`). The two target OS values are
"Windows" and "non-Windows".

**FR-2.** The same artifact answers, for each hook tool, its failure semantics as one of exactly two
values: **fail-open** (a missing or unreachable script yields exit 0 with no stderr) or **fail-closed**
(a missing or unreachable script yields a non-zero exit, so the tool call is blocked). The sync,
ambient-prompt and ambient-reset tools are fail-open. The destructive-command guard is fail-closed.

**FR-3.** The command string the spec yields for each of the 8 `(tool, OS)` combinations is
byte-identical to the string the currently-distributed settings template yields after placeholder
substitution today. This task changes the origin of the strings, not their content.

**FR-4.** The spec yields the command in the form that lands directly inside a JSON string value
(inner `"` already escaped as `\"`), because every present and planned consumer writes the value into
a JSON settings file.

**FR-5.** Every command string the spec yields keeps the space-preceded bare
`<scripts-dir>/<tool>.<ext>` token intact, so the existing hook↔script congruence scans in the gate
and in the upgrade/migration flows continue to extract and existence-check the script path unchanged.

**FR-6.** The spec is reachable from a generated user project, not only from this repo, so that the
distributed upgrade-repair and layout-migration flows can consume it in the follow-on task without
relocating it.

**FR-7.** Given an unrecognized hook tool or an unrecognized OS value, the spec produces no command
string on stdout and exits non-zero with a diagnostic naming the unrecognized input. It never emits an
empty string as a successful answer.

### B. The installer bootstrap (the proof consumer)

**FR-8.** When the one-shot local-environment installer runs in a repository whose committed Claude
settings file declares no lifecycle hooks **and** whose machine-local settings file is absent, the
installer creates the machine-local settings file wiring all four events, using the host OS's byte-forms
obtained from the hook wiring spec.

**FR-9.** When the machine-local settings file is already present, the installer leaves it
byte-untouched, creates no backup file, and reports that it took no action.

**FR-10.** When the committed Claude settings file already declares one or more lifecycle hooks, the
installer creates no machine-local settings file (a generated user project keeps its hooks in the
committed file; the installer never produces a second, competing wiring).

**FR-11.** The file the installer creates parses as JSON, carries the canonical `$schema` URL including
its `.json` suffix, places any explanatory underscore-prefixed keys at the root object only, and uses
only real Claude Code hook event names as keys of the `hooks` object.

**FR-12.** When the installer creates the machine-local settings file it prints the path it created, the
one-line command to remove it, and a note that the file is machine-local and belongs in `.gitignore` if
the project tracks its Claude settings directory — so the action is visible, reversible, and correctly
classified from the terminal output alone. The installer modifies no `.gitignore` in any code path;
the advisory is printed, never applied. *(Amendment 1 — gate W-5.)*

**FR-13.** The installer's pre-existing behavior — installing the git pre-commit drift hook, and exiting
non-zero when the target directory is not a git repository — is unchanged.

### C. Symmetry and documentation

**FR-14.** Both shell variants of every touched script are updated symmetrically: same inputs produce
the same observable behavior and the same generated bytes.

**FR-15.** The documented "fully disable the destructive-command guard" path stays accurate after this
change: the safety-hook rule fragment states what the installer will and will not recreate, so a
deliberate disable is not silently undone without the operator noticing.

**FR-16.** The where-things-live map and the changelog record the new spec artifact and the installer's
new bootstrap behavior.

---

## 3. Out of scope

1. **Changing what any hook script does at runtime** (sync, guard, ambient behavior). Only the origin
   of the wiring string changes.
2. **Re-pointing the four command-derivation flows** (project creation, adoption, upgrade-repair,
   layout migration) at the new spec. That is **T-16**. This task builds the spec so T-16 can consume
   it; it performs none of those edits and requires none of them to pass.
3. **Narrowing the total-verification gate's guard check** — that is **T-15**.
4. **Fixing the project-health report's fixed-settings-file assumption** — that is **T-14**.
5. **Moving this repo's hooks back into the committed settings file.** That relocation was deliberate
   and verified (the published artifact does carry the committed settings file), so the hygiene motive
   stands and is not revisited.
6. **Adding any new check to the total-verification gate.** The duplication is removed at its source;
   no guard check polices it.
7. **Changing the four placeholder token names** or the settings template's structure.
8. **Automatic invocation** of the installer (from a hook, a session start, or the pipeline). It stays
   one-shot and operator-invoked.

---

## 4. Boundary conditions

| # | Condition | Required behavior |
|---|---|---|
| B-1 | Spec asked for an unknown tool or unknown OS | No stdout command, non-zero exit, diagnostic naming the input (FR-7) |
| B-2 | Any of the four command strings resolves empty at install time | Installer writes nothing and exits non-zero; an empty hook command is never persisted |
| B-3 | `.claude/` directory absent | Installer creates it before writing the machine-local settings file |
| B-4 | Committed settings file absent entirely | Treated as "declares no lifecycle hooks" (FR-8 applies) |
| B-5 | Committed settings file present but does not parse as JSON | Installer changes nothing, exits non-zero, reports the unparseable file |
| B-6 | Machine-local settings file present but does not parse as JSON | Left byte-untouched (FR-9); installer reports the condition and does not overwrite |
| B-7 | Machine-local settings file present with an empty `hooks` object | Left byte-untouched — this is the operator's persistent local opt-out |
| B-8 | Write to the machine-local settings file fails (read-only FS, full disk, permissions) | Installer exits non-zero with a diagnostic; it never reports success on an unwritten file, and confirms the end state by re-reading from disk rather than from the in-memory buffer |
| B-9 | Installer run twice in a row | Second run makes no filesystem change to the machine-local settings file and emits the no-action report (FR-9) |
| B-10 | Two installer runs concurrently | Both may write identical deterministic bytes; no lock is required, and the end state is the same file content either way |
| B-11 | Host OS detection: Windows-family shell vs everything else | Exactly the same OS discrimination the existing derivation flows already use; no third variant is introduced |
| B-12 | Bash-side string handling of a command containing a literal `&` | Uses the repo's literal replace helper (or an escaped `&`); a bare `${var//needle/repl}` substitution is prohibited for these values |
| B-13 | Generated file compared across shells | Byte-identical from the PowerShell and Bash variants, trailing newline included |
| B-14 | Repository is not a git repository | Unchanged pre-existing behavior: non-zero exit, no files written |
| B-15 | Target project has no `.gitignore`, or has one that does not list the machine-local settings path | Installer creates and edits no `.gitignore`; it emits the FR-12 advisory and completes normally. A missing ignore entry is never an error condition and never blocks the write *(Amendment 1 — gate W-5)* |

---

## 5. Acceptance criteria

Each criterion is independently verifiable.

**AC-1 — spec exists and answers both axes.** Invoking the hook wiring spec from a Bash environment for
each of the 4 tools × 2 OS values returns a non-empty command string and the tool's failure-semantics
value, with exit 0. Verified by a captured run.

**AC-2 — semantics preserved and guard not weakened.** The spec reports fail-open for the sync,
ambient-prompt and ambient-reset tools, and fail-closed for the destructive-command guard. The guard's
command string for both OS values contains no `|| exit 0` and no trailing `exit 0` fallback. Verified by
direct string assertion on the spec's output for both OS values.

**AC-3 — byte-identity with today's forms, proven not asserted.** For each of the 8 `(tool, OS)`
combinations, the spec's output is byte-equal to the string the currently-distributed template produces
after substitution today (equivalently: to the existing derivation helpers' output). The proof is an
executable assertion over all 8 combinations in a regression driver, run and its output captured — not a
prose claim.

**AC-4 — congruence token survives.** For each of the 8 combinations, the existing hook↔script
congruence extraction pattern still extracts the bare `<scripts-dir>/<tool>.<ext>` path from the spec's
output. Verified by applying the existing extraction to each of the 8 strings.

**AC-5 — installer bootstraps a missing machine-local settings file.** Starting from a clone of this
repository with the machine-local settings file deleted, running the installer creates that file with
all four events wired to the host-OS byte-forms, and the file parses as JSON with a canonical
`$schema`, root-only underscore doc keys, and only valid hook event names under `hooks`.

**AC-6 — installer is idempotent.** Running the installer a second time leaves the machine-local
settings file byte-identical (verified by comparing a pre-run and post-run copy) and creates no backup
file anywhere under `.claude/`.

**AC-7 — installer does not double-wire a project that already has hooks.** In a fixture whose committed
settings file declares lifecycle hooks, the installer creates no machine-local settings file.

**AC-8 — gate green from a bootstrapped clone.** After AC-5's installer run, `.harness/scripts/verify_all`
returns PASS 32 / WARN 0 / FAIL 0 on bash. The check count is 32 — unchanged.

**AC-9 — the guard actually guards after bootstrap.** With the file produced by AC-5 in place, a
destructive command targeting a path outside the project root is BLOCKED (non-zero, block message), and
a destructive command targeting an in-project path is ALLOWED. Both directions demonstrated with real
captured runs.

**AC-10 — cross-shell parity of generated output.** The machine-local settings file generated by the
PowerShell variant and by the Bash variant are byte-identical, trailing newline included. Where PowerShell
execution is unavailable to the agent, this is recorded as green-by-symmetry-only and carried as a
mandatory operator verification item (see NFR-5).

**AC-11 — both shells updated symmetrically.** Every script touched by this task has both its `.ps1` and
`.sh` variant updated; the script-pair symmetry check and the template↔repo byte-identity check both pass.

**AC-12 — release-claim consistency.** No count claim anywhere in the repository changes as a result of
this task (checks stay 32, skills and agents unchanged), and the version/claim consistency gate passes.

**AC-13 — documentation truthful.** The safety-hook rule fragment, the where-things-live map and the
changelog describe the installer's new bootstrap behavior and the spec artifact; the doc-size WARN group
stays clean.

**AC-14 — the bootstrap report is complete and no `.gitignore` moves.** *(Amendment 1 — gate W-5.)* The
captured stdout of AC-5's bootstrap run contains all three FR-12 elements: the created path, the removal
command in that shell's own form, and the machine-local/gitignore advisory. In the same run, `git status
--porcelain` shows no modification to any `.gitignore`, and the created file appears as untracked or
ignored — never as a staged or modified tracked file.

---

## 6. Non-functional requirements

**NFR-1 — compatibility (binding).** No existing project's hook behavior changes. Because AC-3 pins
byte-identity, an already-initialized project that never runs this task's installer path is unaffected.

**NFR-2 — safety (binding).** The destructive-command guard's fail-closed semantics are not weakened in
any code path, in any OS variant, under any boundary condition in §4. Any change that would let a missing
guard produce exit 0 is a hard reject.

**NFR-3 — performance.** Hook command strings are unchanged, so per-hook latency is unchanged. The spec
is consulted at install/derivation time, never per hook invocation; the Windows `-NoProfile` flags on both
the outer and inner invocations are preserved (their removal reintroduces a multi-second per-hook cost).

**NFR-4 — security / hygiene.** *(Scoped by Amendment 1 — gate W-5.)* Three clauses, each with its own
scope:

- **(a) Distribution — universal.** The machine-local settings file is never distributed: it is not a
  template asset, not a mirror-set member, and not part of the published plugin, which continues to ship
  no hooks. This clause is unconditional and holds for every consumer.
- **(b) Gitignored — this repository.** The guarantee that the file *is* ignored applies to harness-kit
  itself, where `.gitignore` carries the entry. It is a property of this repository, not of the
  installer, and this task neither adds nor needs a mechanism to extend it elsewhere.
- **(c) Generated user projects — advisory, by design.** In a project the installer did not author the
  `.gitignore` of, the requirement is exactly FR-12's printed advisory plus B-15's no-edit guarantee:
  the operator is told the file is machine-local and belongs in `.gitignore`, and the installer changes
  no ignore rules. Editing a project's `.gitignore` is not a behavior this task grants the installer.

**Residual risk of (c), accepted and bounded.** An operator who ignores the advisory can commit a
machine-local settings file into a shared project. The exposure is not secret leakage — the generated
content carries no secrets, no absolute machine paths and no persisted guard-override environment
variable (unchanged from the original NFR-4 text) — it is OS-mismatch: the file holds one host OS's
byte-forms, so a teammate on the other OS inherits commands their shell cannot run, and because the
guard is fail-closed by NFR-2 that surfaces as blocked Bash tool calls rather than as a silent
weakening. The risk is accepted on three grounds: (1) the bootstrap path is unreachable in a freshly
generated project at all, since such a project's committed settings declares all four hooks and FR-10
therefore suppresses creation — it is reachable only after an operator has deliberately removed or
emptied that hooks block; (2) the failure direction is safe and loud (blocked calls, never a disabled
guard); (3) it is reversible by the one-line removal command FR-12 prints. Automatically ignoring or
un-tracking files in someone else's repository is a larger and less reversible intrusion than the risk
it prevents.

**NFR-5 — PowerShell verification (binding process requirement).** PowerShell is not executable by agents
in this runtime. The `.ps1` twin is marked green-by-symmetry-only, and the delivery doc carries a mandatory
operator verification item: parse-check every touched `.ps1`, then run the installer and the affected
regression drivers on a Windows shell.

### Known hazards carried into design (each already cost this project a defect)

| Hazard | Constraint it imposes here |
|---|---|
| bash 5.2 `patsub_replacement` expands an unescaped `&` in a `${var//needle/repl}` replacement to the matched text; the hook strings contain a literal `& pwsh` | Bash-side substitution over these values uses the repo's literal replace helper or escapes `&`. PowerShell's replace is ordinal-literal, so this corruption is bash-only and invisible to a PowerShell-only check. |
| PowerShell parses a whole file before executing, so a syntax error in a never-taken branch is fatal; a parameter named like a read-only automatic variable throws on first call; the bash literal idiom for `\"` plus an un-interpolated `$VAR` does not port | The `.ps1` twin cannot be validated by symmetry alone (NFR-5). Embedded bash literals go in single-quoted PowerShell strings or a format string; no parameter name collides with an automatic variable. |
| PowerShell's whole-file write emits no trailing newline while a bash heredoc does | Any file this task generates gets an explicit trailing newline on the PowerShell side (B-13, AC-10). |
| Adding a gate check would trip the version/claim consistency gate and re-pay for the duplication instead of removing it | No new gate check (out-of-scope §3.6). The duplication is removed at its source. |
| Settings-schema traps: underscore doc keys inside the `hooks` object are rejected; the `$schema` URL must keep `.json` | FR-11. Consult the upstream schema before shaping the generated file; do not recall its shape. |
| A regression driver's assertion counts are pinned in the baseline file, and the PowerShell-side counts are operator-reconciled | Adding the AC-3 assertions requires a captured bash count update and a flagged operator reconciliation for the PowerShell count. |

---

## 7. Related tasks

| Task | Relationship |
|---|---|
| `docs/features/_archived/resilient-hooks/` (T-12, v0.44.0) | **Direct upstream.** Created the resilient byte-forms, the fail-open/fail-closed split, the `$CLAUDE_PROJECT_DIR` anchor, and moved this repo's hooks into the machine-local settings file. This task single-sources what T-12 duplicated. |
| T-14 `hook-truth-status` | Sibling; owns the health report's fixed-settings-file assumption. Independent chain — no dependency either way. |
| T-15 `hook-truth-verify-scope` | Depends on T-14, not on this task; narrows the gate's guard check. |
| T-16 `hook-truth-derivation` | **Depends on this task.** Re-points the four derivation flows at the spec. FR-6 exists so T-16 does not have to relocate the artifact. |
| `docs/features/_archived/scripts-relocation/` (T-007) | Established the two-levels-up repo-root derivation convention every harness script follows. |
| `docs/features/_archived/ai-safety-guardrails/` (T-001, v0.15.0) | Original guard-rm + PreToolUse contract; the fail-closed requirement traces here. |
| `docs/features/_archived/ambient-stream/` | Origin of the `UserPromptSubmit` / `SessionStart` hook pair. |

No entry in `.harness/rejected-decisions.md` covers hook single-sourcing or installer bootstrap; the
closest record (`skills-git-guardrails-setup-pre-commit`) declines *adopting upstream skills* that would
duplicate this repo's own installer — it does not decline extending the installer.

---

## 8. Open questions (each carries a `Recommended:` answer, adopted as the binding default)

**OQ-1 — Where does the hook wiring spec live, and is it distributed?**
(a) A new script pair in the distributed template's scripts directory, byte-mirrored into this repo by
the layer-1 sync — reachable by the distributed upgrade/migration flows that T-16 must re-point.
(b) A dogfood-only pair in this repo's scripts directory — simpler now, but T-16 could not consume it
from the distributed flows without a later relocation.
(c) A static data file plus one tiny reader per shell.
**Recommended: (a).** It is the only option that satisfies FR-6 without a follow-up move, and it keeps
the artifact under the existing mirror discipline. (c) adds a parse surface in two shells for eight
short strings and buys nothing.

**OQ-2 — Which escaping level does the spec emit?**
(a) The JSON-string-body form (inner `"` already escaped). (b) The raw shell command. (c) Both, selected
by a flag.
**Recommended: (a) only.** Every current and planned consumer writes into a JSON settings value, which is
also exactly what today's derivation helpers emit — so (a) preserves byte-identity by construction. Add
(b) only when a consumer needs it.

**OQ-3 — What exactly gates the installer's creation of the machine-local settings file?**
(a) Committed settings declares no lifecycle hooks AND the machine-local file is absent.
(b) Detect that the repository is harness-kit itself.
(c) Require an explicit opt-in flag on the installer.
**Recommended: (a), plus the loud report of FR-12 and the B-7 empty-`hooks` local opt-out.** (a) is
generic, so the installer stays byte-mirrorable with its distributed twin (see OQ-4); (b) ships dead code
to every user project; (c) makes the bootstrap another thing to remember, which is the failure this task
exists to remove. The interaction with the documented full-disable path is handled by FR-15 + B-7: an
operator who wants hooks permanently off writes an explicit empty local hooks object, which the installer
never overwrites. Note the direction of risk is safe — this path can only *restore* the guard, never
weaken it.

**OQ-4 — Does the installer stay in the layer-1 mirror set (byte-identical template ↔ repo)?**
(a) Yes — the new behavior is written generically so both copies stay byte-identical.
(b) No — fork a dogfood-only installer variant.
**Recommended: (a).** (b) creates exactly the hand-synchronized duplication this task exists to delete,
and would need the drift gate's mirror mapping changed.

**OQ-5 — The installer's generated pre-commit hook currently differs by one trailing newline between the
two shells (PowerShell's whole-file write omits it; the bash heredoc emits it). Fix now or defer?**
(a) Fix inside this task. (b) Leave it; file a separate pool row.
**Recommended: (a).** It is the exact defect class the insight index already records, it lives in a file
this task edits anyway, and it is user-invisible (the pre-commit hook is overwritten unconditionally, so
there is no re-install or backup churn). Leaving a known cross-shell parity bug in a file being edited
contradicts AC-10's own rationale.

**OQ-6 — Does a new script pair join the script-pair symmetry check's name array?**
(a) Yes — add the pair name to the array in both shells. (b) No.
**Recommended: (a).** Adding an array element is not adding a check; the total stays 32 (AC-8/AC-12). Note
the array is hardcoded in both shells and is not directory-derived, so both must be edited in the same
change.

**OQ-7 — Version treatment.**
(a) Minor bump with the full version fan-out. (b) No bump (internal refactor only).
**Recommended: (a), a minor bump.** The installer gains user-observable behavior. No count claim changes,
so the fan-out is version strings only.

**OQ-8 — Does the spec also own the four placeholder token names?**
(a) Byte-forms and semantics only. (b) Also the placeholder names and the template's substitution map.
**Recommended: (a).** Placeholder-name ownership belongs with the creation flow until T-16 re-points the
derivations; pulling it in now widens this task into T-16's scope.

**OQ-9 — Where does the AC-3 byte-identity proof live?**
(a) Assertions added to the existing initialization regression driver, which already carries the resilient
byte-forms as fixtures. (b) A new dedicated test driver pair. (c) A gate check.
**Recommended: (a).** (b) adds a script pair, a symmetry-array entry and a baseline entry for eight string
comparisons; (c) is explicitly out of scope (§3.6). Adding assertions to (a) requires a captured bash
assertion-count update in the baseline file plus a flagged operator reconciliation for the PowerShell count.

---

## EVIDENCE (backward-looking; path-and-line citations are the proof, per `.harness/rules/05-insight-index.md`)

- Duplication of the byte-forms, observed at analysis time:
  `skills/harness-init/SKILL.md:187-190` (four placeholder rows carrying the full strings in prose);
  `skills/harness-adopt/SKILL.md:311-314`;
  `.harness/scripts/upgrade-project.sh:102-117` and `.harness/scripts/upgrade-project.ps1:112`;
  `.harness/scripts/migrate-scripts-layout.sh:117` and `.harness/scripts/migrate-scripts-layout.ps1:36`;
  the byte-identical template twins of all four under
  `skills/harness-init/templates/common/.harness/scripts/`;
  `.claude/settings.local.json:11,22,32,42` (the live dogfood strings);
  `.harness/scripts/verify_all.sh:290-334` (F.2 guard + template-placeholder checks);
  `skills/harness-status/SKILL.md:32,68,73-79`;
  and the fixtures in `.harness/scripts/test-init.{ps1,sh}` / `test-harness-upgrade.{ps1,sh}`.
- The missed site from T-12: `skills/harness-status/SKILL.md:73-79` computes the safety-hook verdict by
  parsing `.claude/settings.json` only, which is why it reports `DISABLED` on a machine where the guard is
  wired in `.claude/settings.local.json:22` and demonstrably blocking. (Fix owned by T-14, not here.)
- Fresh-clone gate failure: `.harness/scripts/verify_all.sh:304-320` selects the machine-local settings
  file only when it exists and contains `"PreToolUse"`, otherwise falls back to
  `.claude/settings.json`, which ships `"hooks": {}` (`.claude/settings.json:21`) — so a clone without the
  untracked local file fails F.2 on an environment condition.
- Machine-local file is gitignored: `.gitignore:58-60`.
- Installer is in the layer-1 mirror set: `.harness/scripts/sync-self.sh:66-68` (mapping 3), which is why
  OQ-4 matters.
- Trailing-newline asymmetry in the installer (OQ-5): `.harness/scripts/install-hooks.ps1:65` writes the
  hook body with a whole-file write and no trailing newline, while `.harness/scripts/install-hooks.sh:31-59`
  emits it via a heredoc that terminates the last line.
- Script-pair symmetry array is hardcoded per shell: `.harness/scripts/verify_all.sh:284`.
- Congruence-token constraint and the fail-closed rationale:
  `docs/features/_archived/resilient-hooks/07_DELIVERY.md:14-17,31`.
- Settings-schema contract: `.harness/rules/80-settings-schema.md:27-39`.
- Guard contract and documented disable path: `.harness/rules/75-safety-hook.md:10-16,82-87`.

**Added by Amendment 1 (gate W-5), verified at amendment time:**

- The init templates lay down **no** `.gitignore` at all: a glob of
  `skills/harness-init/templates/**` returns zero gitignore assets, and no init or adopt flow writes or
  appends one. `.harness/scripts/test-real-project.sh:231-235` asserts the *pre-existing* user
  `.gitignore` is **preserved**, confirming the flow only ever leaves it alone. So a generated project's
  ignore rules are entirely the user's, and no mechanism exists today to extend `.gitignore:58-60` to it.
- Advise-don't-edit is the established precedent for this repo's installers:
  `skills/harness-adopt/SKILL.md:377-379` recommends a `.gitignore` snippet in its summary rather than
  editing the file.
- The bootstrap path is unreachable in a freshly generated project: the distributed
  `skills/harness-init/templates/common/.claude/settings.json.tmpl:37-79` declares all four hook events
  in the **committed** settings file, so FR-10 suppresses creation until an operator removes or empties
  that block.
- OS-mismatch is the actual exposure, not secret leakage: the Windows byte-forms invoke `pwsh`
  (`.harness/scripts/upgrade-project.sh:106,108`), and the guard branch at `:106` carries no fail-open
  fallback — so a cross-OS committed copy blocks Bash tool calls rather than disabling the guard.

---

## Amendment 1 (gate W-5) — 2026-07-31

**Finding adjudicated**: gate `03_GATE_REVIEW.md` W-5 (WARN, non-blocking) — NFR-4's "stays gitignored
and is never distributed" was guaranteed only for harness-kit itself, so the requirement over-claimed for
a generated user project whose installer reaches the create path.

**Resolution: both of the gate's offered options, split by clause** — scope the *gitignored* guarantee to
this repository, and adopt the printed advisory as the sufficient and *complete* requirement for a
generated user project, with the residual risk recorded. The *never distributed* clause is left
unconditional, because it is true universally and by a different mechanism (the file is not a template
asset, not a mirror-set member, and not in the published plugin) — collapsing both clauses to one scope
would have under-claimed as badly as the original over-claimed.

**Why not the alternative reading.** The gate offered "accept the printed note as sufficient" as a
standalone resolution. Accepting it without scoping NFR-4 would have left the over-claiming sentence
intact, which is the defect W-5 actually names. Conversely, scoping alone would have left the user-project
case unstated. Both edits together are what removes the gap.

**What changed** (four narrow edits; nothing renumbered, nothing else re-opened):

| Item | Change |
|---|---|
| FR-12 | Extended in place: the printed report now also carries the machine-local/gitignore advisory, and the no-`.gitignore`-edit guarantee is stated as binding behavior. |
| B-15 | **New row appended.** Target project has no `.gitignore`, or one lacking the entry → no ignore file is created or edited; the advisory prints; the write proceeds. A missing entry is never an error. |
| AC-14 | **New criterion appended.** AC-5's captured stdout carries all three FR-12 elements, and the same run shows no `.gitignore` modification and the created file untracked/ignored. |
| NFR-4 | Rewritten in place into three scoped clauses (a) distribution — universal, (b) gitignored — this repository, (c) generated user projects — advisory by design, plus an explicit accepted-residual-risk paragraph. |

**No new work for the architect.** FR-12's added clause ratifies behavior `02_SOLUTION_DESIGN.md`
already specifies (§5's stdout contract) and B-15 restates its §15 out-of-scope boundary, which the gate
verified as correct. AC-14 asserts against that same already-designed output. The hard boundary the gate
protected is untouched: the installer must not edit `.gitignore`, and no requirement here forces it to.

**Not touched**: NFR-2's fail-closed requirement (unchanged, and clause (c) now cites it as the reason the
residual failure mode is loud rather than silent); every other FR, AC, boundary row, NFR, out-of-scope
item and open question; `02_SOLUTION_DESIGN.md`; `03_GATE_REVIEW.md`.

---

## 9. Verdict

**READY** (unchanged by Amendment 1)

All nine open questions carry a `Recommended:` answer, which the Solution Architect adopts as the binding
default unless the operator overrides. None is human-reserved: no recommendation weakens the
destructive-command guard, changes a red-line file, or alters permission configuration. The task is
well-posed, every acceptance criterion is independently verifiable, and the gate expectation
(PASS 32 / WARN 0 / FAIL 0, check count 32) is unchanged.

Amendment 1 opens no new question: it was resolvable from repository evidence alone, touches no red-line
file, no permission configuration and no guard semantics, and adds no work to the in-flight design.
