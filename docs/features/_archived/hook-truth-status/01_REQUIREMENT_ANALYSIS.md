# 01 — Requirement Analysis · T-14 `hook-truth-status`

**Mode**: `full` · **Stage**: 1 (requirement-analyst) · **Date**: 2026-07-31
**deferred-human mode**: defer, do not ask — every ambiguity below carries a binding `Recommended:` answer.
**Gate baseline at dispatch**: `.harness/scripts/verify_all` bash **PASS 32 / WARN 0 / FAIL 0**; check count stays 32.
**Tree state**: carries T-13's delivered-but-uncommitted changes (expected).

---

## 1. Goal

The project-health report computes every hook-related verdict from one hardcoded settings file, so on a
project whose lifecycle hooks legitimately live in the machine-local settings file it reports the
destructive-command guard as disabled while the guard is installed, wired and blocking; this task makes the
report resolve the hook wiring from wherever it legitimately lives under a defined precedence, name the file
it resolved, and own the "is the guard installed on this machine" question — including the case of a clone
that never ran the installer.

**Glossary**: this doc uses **hook wiring spec**, **machine-local settings**, **health report** and
**effective hook source** as defined in `CONTEXT.md` (the last two added by this task).

---

## 2. In-scope behaviors

### A. Resolving where the wiring lives

**FR-1 — Precedence, not a fixed path.** The health report determines the **effective hook source** — the
one settings file its hook verdicts are computed from — by consulting, in order: (1) the machine-local
settings file, (2) the committed settings file. A file participates in this precedence only when it exists,
is readable, and declares a **non-empty** lifecycle-`hooks` object; a file that declares no hooks or an empty
hooks object is passed over and the next location is consulted.

**FR-2 — Name the source.** Every hook-related line the report prints (guard state, per-event congruence,
the guard asset row) names the effective hook source by path. When no location qualifies, the report names
both locations it consulted.

**FR-3 — Committed-settings arrangement is fully supported.** A project whose committed settings file
carries the hooks — the arrangement `/harness-init` and `/harness-adopt` generate — resolves to the
committed settings file and produces the same verdicts it produces today. No machine-local file is required
for any healthy verdict.

**FR-4 — Both files declare hooks.** When both locations declare a non-empty hooks object, the machine-local
file is the effective hook source, and the report states that the committed settings file also declares
lifecycle hooks, so the reader is not misled about which wiring the verdicts came from.

### B. The destructive-command guard verdict (health report §3b)

**FR-5 — Three states, never collapsed.** The guard verdict is exactly one of three mutually exclusive
states, each with distinct output text:

| State | Condition |
|---|---|
| **wiring absent** | The effective hook source declares no `PreToolUse` entry whose command references `guard-rm.{ps1,sh}` |
| **wiring dangling** | Such an entry exists, and the script path extracted from its command does not exist on disk |
| **installed and wired** | Such an entry exists, and the extracted script path exists on disk |

**FR-6 — Healthy wording is pinned.** In the *installed and wired* state the report states that the
destructive-command guard is **installed and wired** and names the file the wiring was found in (FR-2).

**FR-7 — Dangling reports the evidence and is never healthy.** In the *wiring dangling* state the report
prints the exact command string and the missing path, the state is not reported as healthy, and it earns no
health point (FR-17). This is the state that produced a per-turn hook error for users historically.

**FR-8 — The repair instruction matches the file the wiring lives in.** The fix line the report prints for a
non-healthy guard state is conditional on the effective hook source: for wiring in the committed settings
file it names the upgrade repair path; for wiring in the machine-local settings file it names the path that
actually repairs that file (remove the machine-local settings file and re-run `.harness/scripts/install-hooks`),
because the upgrade helper rewrites only the committed settings file and the installer never overwrites an
existing machine-local file. The report never prints a fix instruction that cannot reach the file it named.

**FR-9 — Matcher is reported, not assumed.** An entry under `PreToolUse` whose command references
`guard-rm.{ps1,sh}` counts as guard wiring regardless of its matcher value. The report prints the matcher
value verbatim and, when it is not exactly `Bash`, states that the matcher is non-canonical. A
guard-referencing entry with an unexpected matcher is never reported as *wiring absent*.

**FR-10 — Interpreter availability for the guard.** When the guard command's first token (`pwsh` / `bash` /
`sh`) is not available on the host, the report states this alongside the guard verdict together with its
consequence: the guard is fail-closed, so an unavailable interpreter blocks Bash tool calls rather than
silently disarming the guard. The report never proposes rewriting a runnable, user-chosen command variant.

**FR-11 — Existence test is on the referenced script.** The *installed and wired* determination tests the
existence of the script path extracted from the wired command. Presence of the other shell twin is reported
by the required-asset rows and is not a precondition for the guard verdict.

### C. The machine dimension the report now owns

**FR-12 — Never installed on this machine.** When no location declares lifecycle hooks and the machine-local
settings file is **absent**, the report states that this clone has no lifecycle hooks installed on this
machine and names the one-line fix (`.harness/scripts/install-hooks`, when that script exists in the
project). It does not report this as the guard having been switched off.

**FR-13 — Deliberate local opt-out is distinguished from never-installed.** When the machine-local settings
file is **present** and declares an empty hooks object, and no other location declares hooks, the report
states that a machine-local settings file is present with an empty hooks block and that this is the
documented persistent opt-out — a different sentence from FR-12's.

**FR-14 — Unreadable settings is its own state.** When a settings file at either location exists but cannot
be read or does not parse structurally, the report names that file and states that its hook state is unknown;
it does not report a healthy guard on the strength of the other file alone, and awards no health point.

### D. Per-event hook↔script congruence (health report §3c)

**FR-15 — Same source, same precedence.** The per-event congruence section reads the effective hook source
resolved by FR-1 and names it (FR-2). Its existing state vocabulary (`ok`, `not wired`, `DANGLING`,
`MALFORMED`, plus the interpreter-availability note) is unchanged.

**FR-16 — Enumeration comes from the hook wiring spec.** The set of hook ids and, per id, its event name,
matcher and fail-open/fail-closed semantics is obtained by invoking the hook wiring spec (`tools`, `event`,
`matcher`, `semantics`) rather than restated in the health report's prose. The report invokes the spec twin
of its own host shell and never crosses shells. The spec is a **soft dependency**: when it is absent or
answers non-zero, the report falls back to enumerating the four lifecycle events it names today and labels
that enumeration as a fallback. The report does not byte-compare a wired command against the spec's
`command` output.

### E. Asset row and health score

**FR-17 — Guard asset row and health point are location-aware.** The required-asset row for the guard hook
states the location-agnostic condition (a `PreToolUse` entry referencing `guard-rm` in the effective hook
source) and names the resolved file. The number of required-asset rows stays **14** and the health-score
denominator stays **12**. The guard's health point is awarded only in the *installed and wired* state of FR-5.

### F. Executability and honesty

**FR-18 — The procedure is executable as written.** Every step of the guard verdict and the congruence
verdict is deterministic and performable with the tools the health report declares: same repository state →
same verdict, independent of which agent runs it. No step requires judgment about intent.

**FR-19 — Read-only.** The health report performs no writes, applies no repair, and runs no gate — unchanged
from its existing anti-patterns.

**FR-20 — Documentation truthful.** The changelog records the fix. Any live document that describes where
the health report reads hook wiring from is updated to the precedence rule. The safety-hook rule fragment's
statements about observing and disabling the guard stay accurate.

---

## 3. Out of scope (explicit non-goals)

1. **Narrowing the total-verification gate's guard check (F.2)** to repository-answerable assertions — that
   is **T-15**, chained behind this task. This task does not touch the gate's guard check.
2. **Re-pointing the command-derivation flows at the hook wiring spec** — that is **T-16**.
3. **Changing what any hook script does at runtime** (guard, sync, ambient behavior).
4. **Changing the hook wiring spec, the installer, or the settings template.**
5. **Adding any check to the total-verification gate**, and adding any retired-claim banned phrase to its
   I.6 list. The false verdict is removed at its source; no guard polices it.
6. **Consulting user-level (`~/.claude/settings.json`) or enterprise settings.** The health report's scope
   stays project-scoped; it claims nothing about wiring outside the project.
7. **Moving this repository's hooks back into the committed settings file.** That relocation was deliberate
   and verified.
8. **Auto-repair.** The report names a fix; it never performs one.
9. **`docs/proposals/frontier-gaps-2026-07.md`** — an untracked operator backlog document. Not edited, not
   referenced as a requirement, not committed.
10. **Reconciling the frozen PowerShell test-init assertion count or either README badge tied to it.** Those
    are frozen pending the standing operator PowerShell run and move together there, not here.

---

## 4. Boundary conditions

| # | Condition | Required behavior |
|---|---|---|
| B-1 | Machine-local settings absent, committed settings declares hooks | Effective source = committed settings; verdicts computed from it and it is named (FR-1, FR-3) |
| B-2 | Machine-local settings declares hooks, committed settings declares `"hooks": {}` | Effective source = machine-local settings; guard reported *installed and wired* when its script exists (FR-1, FR-6) |
| B-3 | Both locations declare non-empty hooks | Effective source = machine-local; the report states the committed file also declares hooks (FR-4) |
| B-4 | Neither location declares hooks; machine-local file absent | "No lifecycle hooks installed on this machine" + installer fix line (FR-12) |
| B-5 | Neither location declares hooks; machine-local file present with an empty hooks object | Persistent-opt-out sentence, distinct from B-4 (FR-13) |
| B-6 | `.claude/` directory absent entirely | Treated as B-4; no crash, no fabricated verdict |
| B-7 | A settings file exists but does not parse structurally, or is not a regular file, or is unreadable | Named, hook state reported unknown, no health point, no healthy claim (FR-14) |
| B-8 | Effective source declares `PreToolUse` entries, none referencing `guard-rm` | Guard = *wiring absent*; the other entries are reported by the congruence section, not misreported as guard wiring (FR-5) |
| B-9 | Several `PreToolUse` entries, one of which references `guard-rm` | Guard = wired; the guard-referencing entry is the one evaluated (FR-5) |
| B-10 | Guard entry's matcher is absent, `*`, or a compound value | Guard = wired; matcher printed verbatim and flagged non-canonical (FR-9) |
| B-11 | Guard command references an old-layout path (`scripts/guard-rm.sh`) | Path extracted and existence-checked with the existing left-bounded pattern; state per FR-5 |
| B-12 | Guard command carries an unresolved `{{...}}` placeholder token | `MALFORMED` in the congruence section and non-healthy in the guard verdict; never *installed and wired* |
| B-13 | Wired command names the `.ps1` twin while only the `.sh` twin exists (or the reverse) | Verdict follows the referenced path (FR-11); the missing twin surfaces in the asset rows |
| B-14 | Guard command's interpreter is not on PATH | Reported per FR-10; the guard verdict itself is unchanged by interpreter availability |
| B-15 | Hook wiring spec absent (project generated before it shipped) | Fallback enumeration, labelled as fallback; no error, no missing-asset claim (FR-16) |
| B-16 | Hook wiring spec present but exits non-zero for a query | Same fallback as B-15; the report never treats an empty answer as a valid one |
| B-17 | Report runs on Windows vs on unix | The spec twin of the report's own shell is invoked; shells are never crossed (FR-16) |
| B-18 | Shell execution unavailable to the running agent | Wiring resolution and all three FR-5 states are still produced from file reads alone; only the spec enumeration degrades to the B-15 fallback |
| B-19 | A hook command references a path under a directory merely *ending* in `scripts/` (e.g. `build-scripts/deploy.sh`) | Not extracted, not flagged — the existing left-bounded extraction behavior is preserved |
| B-20 | Machine-local settings file is present and gitignored (this repository) | Read normally; the report makes no claim that the file is tracked, and proposes no `.gitignore` change |

---

## 5. Acceptance criteria

Each criterion is independently verifiable; AC-1 and AC-2 require captured runs, not reasoning.

**AC-1 — Real-state proof on this repository.** Executing the health report's own hook procedure against
this repository as it currently stands yields: the destructive-command guard **installed and wired**, and the
effective hook source named as `.claude/settings.local.json`. Proven by a captured execution transcript in the
QA report, not by argument.

**AC-2 — Congruence section on this repository.** In the same captured run, the per-event congruence section
reports every wired event as `ok` and names the same effective hook source. No event is reported `not wired`
while its wiring exists in the machine-local settings file.

**AC-3 — Committed-settings project does not regress.** Against a fixture (or the distributed settings
template's post-substitution shape) whose committed settings file wires the guard and no machine-local file
exists, the same procedure yields *installed and wired* and names the committed settings file. Captured.

**AC-4 — The three states are distinguishable.** For each of the three FR-5 states, a probe over a
purpose-built settings input yields the corresponding state and no other; the *wiring dangling* probe prints
the command string and the missing path, and is not reported as healthy.

**AC-5 — Never-installed clone.** For an input where neither location declares hooks and the machine-local
file is absent, the output states that no lifecycle hooks are installed on this machine and names
`.harness/scripts/install-hooks` as the fix; the string reporting the guard as switched off does not appear.

**AC-6 — Opt-out is distinct.** For an input with a machine-local file declaring an empty hooks object, the
output differs from AC-5's and names the persistent opt-out.

**AC-7 — Fix instruction reachability.** For a dangling guard wired in the machine-local settings file, the
printed fix names the machine-local repair path; for a dangling guard wired in the committed settings file,
it names the upgrade repair path (FR-8). Both checked against the two outputs.

**AC-8 — Spec is the enumeration authority, with a working fallback.** The report's enumeration of hook ids
and their event/matcher/semantics is obtained from the hook wiring spec; the health report contains no
second hand-maintained list of those facts. With the spec made unavailable, the run still completes and
labels its enumeration as a fallback (B-15).

**AC-9 — Counts and gate unchanged.** `.harness/scripts/verify_all` returns **PASS 32 / WARN 0 / FAIL 0** on
bash; the check count is 32; the required-asset row count is 14; the health denominator is 12.

**AC-10 — Structurally-pinned assertions still green.** `.harness/scripts/test-supervisor.sh` passes with its
assertion count unchanged from the baseline record, including both existing health-report doc fan-out
assertions. If any change to the health report alters what those assertions match, the assertions are updated
to the new expected state (never deleted) and the corresponding baseline counts are updated from captured runs.

**AC-11 — No hook behavior changed.** No hook script, settings file, template, installer, or gate check is
modified by this task; `git status` for the delivery shows changes confined to the health report, its
documentation surfaces, and the glossary/changelog.

**AC-12 — Release-claim consistency.** The version/claim consistency gate passes, and the CHANGELOG carries
an entry for the version stated in the plugin manifest (see OQ-6).

---

## 6. Non-functional requirements

**NFR-1 — Safety (binding).** No statement, verdict or recommendation in the health report weakens or
proposes weakening the destructive-command guard's fail-closed semantics. A wiring state that could leave
the guard non-functional is never reported as healthy (FR-5, FR-7, FR-14). Reporting a live guard as
disabled and reporting a dead guard as healthy are both defects of the same class; the second is the more
severe and is a hard reject.

**NFR-2 — Compatibility (binding).** Existing consumers of the health report's vocabulary keep working: the
`DANGLING` / `MALFORMED` tokens the upgrade skill's repair-path trigger refers to are preserved, and no
project's hook behavior changes as a result of this task.

**NFR-3 — Design over guards.** The false verdict is removed by making the report read the right file and
derive its enumeration from the single source, not by adding a verification check. The gate's check count
stays 32 (Out-of-scope §3.5, AC-9).

**NFR-4 — Bounded cost.** The added work per report run is bounded: at most two settings files read, and at
most one hook wiring spec invocation per hook id plus one for the id list. No repository-wide scan is
introduced.

**NFR-5 — Cross-shell honesty (binding process requirement).** PowerShell is not executable by agents in this
runtime. Any `.ps1` surface this task touches is green-by-symmetry-only and is added to the standing operator
PowerShell verification list carried from T-13; no PowerShell verification is claimed that was not performed.
If the delivered change touches no `.ps1`, that is stated explicitly rather than implied.

**NFR-6 — Tally honesty (binding).** Every count reported in the delivery (gate tallies, driver assertion
counts) is pasted from the artifact that produced it. A count derived by arithmetic is not reported as a run
result.

### Known hazards carried into design

| Hazard | Constraint here |
|---|---|
| Health-report asset rows are structurally pinned by the supervisor regression's doc fan-out assertions, and no fan-out list names the coupling | Treat any row edit as a touchpoint of that driver: run it, and update assertions to the new expected state rather than deleting them (AC-10) |
| Adding a gate check moves the check count and fires the version/claim gate | No new check (NFR-3, AC-9) |
| The upgrade repair path rewrites only the committed settings file | The fix line must be conditional on the resolved source (FR-8) — a blanket "run the upgrade" instruction would be a false repair for machine-local wiring |
| The installer never overwrites an existing machine-local settings file | The machine-local repair instruction has to include removing that file before re-running the installer (FR-8) |
| The hook wiring spec's stdout must not cross shells (an MSYS bash capturing PowerShell output keeps the `\r`) | The report invokes the twin of its own shell (FR-16, B-17) |
| PowerShell twins are agent-unexecutable and a partial cross-shell hand-off manufactures defects | NFR-5 |
| The README test-init badge and the PowerShell test-init assertion count are deliberately frozen pending the operator run | Out-of-scope §3.10 — not touched, not reconciled |

---

## 7. Related tasks

| Task | Relationship |
|---|---|
| `docs/features/_archived/hook-truth-spec/` (T-13, v0.45.0) | **Sibling, delivered.** Established the hook wiring spec this task consults for enumeration; its `01_REQUIREMENT_ANALYSIS.md` EVIDENCE section already names the health report as the site this task fixes |
| `docs/features/_archived/resilient-hooks/` (T-12, v0.44.0) | **Root cause.** Relocated this repository's hooks into the machine-local settings file and updated the gate but not the health report |
| `docs/features/_archived/sync-hook-dangling-ref/` (T-020, v0.31.0) | Origin of the congruence section and of the `DANGLING` / `MALFORMED` vocabulary, and of the supervisor-driver doc fan-out coupling |
| `docs/features/_archived/ai-safety-guardrails/` (T-001, v0.15.0) | Origin of the guard and of the `PreToolUse` contract; the fail-closed requirement traces here |
| T-15 `hook-truth-verify-scope` | **Depends on this task.** It may shed the gate's machine-state assertion only after the health report owns it (FR-12, FR-13) |
| T-16 `hook-truth-derivation` | Independent chain (depends on T-13); re-points the derivation flows at the spec |

`.harness/rejected-decisions.md` contains no record covering hook-state reporting or settings precedence; the
nearest record (`skills-git-guardrails-setup-pre-commit`) declines adopting upstream guardrail skills that
would duplicate this repository's own guard and installer — it does not decline improving the health report.
Nothing in this requirement re-litigates a declined decision.

---

## 8. Open questions (each carries a binding `Recommended:` answer)

None is human-reserved: no recommendation weakens the guard, edits a red-line file, or changes permission
configuration. Downstream stages adopt the recommendations unless the operator overrides.

**OQ-1 — Granularity of the precedence rule.**
(a) Whole-report resolution: one effective hook source per run, chosen as machine-local-if-it-declares-hooks,
else committed. (b) Per-event resolution: each event resolved independently across both files. (c) Union:
report a hook as wired if any location wires it.
**Recommended: (a).** It produces one nameable answer to "which file did this verdict come from" (AC-1), it
mirrors the precedence the total-verification gate already uses for the same question, and it matches the
installer's own model (a project's hooks live in one file — the installer refuses to create a second,
competing wiring). (b) and (c) can report a healthy union that corresponds to no single file, which is
exactly the kind of unverifiable verdict this task exists to remove.

**OQ-2 — Is the per-event congruence section in scope, or only the guard verdict?**
(a) Both sections move to the resolved source. (b) Guard verdict only.
**Recommended: (a).** The congruence section reads the same hardcoded file and is therefore false in the same
way on this repository today — it reports every event as not wired while all four are wired and running.
Fixing one and leaving the other would ship a health report that contradicts itself, and (b) buys nothing:
both sections need the same one resolution step.

**OQ-3 — How tightly does the health report couple to the hook wiring spec?**
(a) Consult the spec for the id list and each id's event/matcher/semantics; do not byte-compare commands;
degrade to a labelled fallback when the spec is unavailable. (b) Also byte-compare each wired command against
the spec's `command` output and report a mismatch as unhealthy. (c) No coupling; keep the four event names in
the report's prose.
**Recommended: (a).** (b) manufactures false negatives: a project legitimately carrying another host's
byte-form, a user-customized-but-working command, or a pre-resilient-form command would be reported broken
though the guard functions — and the report is read-only, so it could only nag. (c) leaves a second
hand-maintained list of exactly the facts this wave is single-sourcing. The fallback in (a) is required
because projects generated before the spec shipped do not have it, and the report must not degrade into an
error for them.

**OQ-4 — What must exist for the guard to count as installed?**
(a) The script path extracted from the wired command. (b) Both shell twins of the guard script, as the
report requires today.
**Recommended: (a).** (b) conflates two different facts — "the wiring resolves to a real script" and "this
project ships both twins" — and reports the guard as broken on a project that legitimately carries only the
twin its host uses. The twin-presence fact is already reported by two dedicated required-asset rows, so
nothing is lost.

**OQ-5 — A settings file that exists but does not parse.**
(a) A distinct "hook state unknown for `<file>`" state, no health point. (b) Silently skip it and resolve to
the next location.
**Recommended: (a).** (b) can print a healthy guard verdict while the file Claude Code actually loads is
broken — a false green, which NFR-1 ranks as the more severe defect direction.

**OQ-6 — Version treatment.**
(a) Fold into the unreleased `0.45.0` entry as its own subsection (the plugin manifest and every stamp
already read 0.45.0 in this tree, and T-13's delivery is uncommitted, so nothing has been tagged).
(b) Bump to `0.46.0` with the full four-stamp version fan-out.
**Recommended: (a).** It keeps the hook-truth wave as one coherent release, moves no version stamp, and
touches no frozen badge. **Tripwire:** if `0.45.0` has been committed and tagged by the time this task
delivers, (b) applies instead — bump every stamp and add a new CHANGELOG heading, since the version/claim
gate requires a heading for the manifest's version.

**OQ-7 — Do the supervisor driver's doc fan-out assertions gain a new pin for the corrected wording?**
(a) No new assertion; run the driver, confirm both existing assertions stay green, leave assertion counts
unchanged. (b) Add an assertion pinning the location-agnostic wording.
**Recommended: (a).** (b) is a guard against a defect the design makes hard to reintroduce, and it moves the
driver's assertion counts in both shells — including the PowerShell count that is deliberately frozen pending
the operator run. If a row edit does break an existing assertion, it is updated to the new expected state
(never deleted) and the bash count is re-captured.

**OQ-8 — Does the report consult user-level or enterprise settings?**
(a) No — project scope only, and the report claims nothing about wiring outside the project.
(b) Yes, extend the precedence chain.
**Recommended: (a).** The report's other verdicts are all project-scoped; a hook wired in a user-level file
is invisible to every other harness surface (gate, installer, upgrade path), so including it would make the
health report disagree with all of them. Out-of-scope §3.6 records this.

**OQ-9 — Retiring the current "no PreToolUse for Bash in the committed settings" wording.**
(a) Replace it with the FR-5 states and add no retired-claim banned phrase to the gate's I.6 list.
(b) Also add the retired string to that list.
**Recommended: (a).** The I.6 banned list is a four-file lockstep with a pinned entry count in a second
driver pair; paying that for a string with exactly one live occurrence, in a file this task rewrites, is the
guard-accretion pattern the standing preferences reject.

**OQ-10 — Which fix line does the never-installed state print?**
(a) `.harness/scripts/install-hooks` when that script exists in the project; otherwise the adopt/upgrade
instruction the report already uses for missing assets. (b) Always the installer.
**Recommended: (a).** The installer only exists in projects generated from v0.45 templates onward; naming a
script an older project does not have is an unreachable fix instruction, which FR-8 already prohibits.

---

## EVIDENCE (backward-looking; path-and-line citations are the proof, per `.harness/rules/05-insight-index.md`)

Observed at analysis time, on the working tree described above:

- The fixed-file assumption, guard verdict: `skills/harness-status/SKILL.md:68` (the state vocabulary naming
  `.claude/settings.json`) and `:73-80` ("computed by parsing `.claude/settings.json`", including the
  both-twins-must-exist clause OQ-4 addresses).
- The same assumption in the congruence section: `skills/harness-status/SKILL.md:84` ("in
  `.claude/settings.json`"), with the extraction pattern and tri-state vocabulary at `:97-121`.
- The asset row and the health point: `skills/harness-status/SKILL.md:32` and `:144,148` (14 rows, denominator 12).
- Why the verdict is false here: `.claude/settings.json:21` declares `"hooks": {}` (relocation note at `:3-4`),
  while the live guard wiring is `.claude/settings.local.json:16-26` — `PreToolUse` / `"matcher": "Bash"` /
  `bash .harness/scripts/guard-rm.sh`, fail-closed (no `exit 0` fallback). Reading the report's own §3b
  procedure against these two files yields `DISABLED` deterministically.
- The precedence pattern already in use for the same question: `.harness/scripts/verify_all.sh:297-321`
  (F.2 reads machine-local when it carries `"PreToolUse"`, else falls back to the committed file);
  `.harness/scripts/verify_all.sh:653-657` (J.1 validates both files). T-15 owns F.2's narrowing.
- The hook wiring spec's contract and its four ids: `.harness/scripts/hook-spec.sh:18-32` (queries, totality,
  exit-2 semantics), `:120` (the four ids), `:9-16` (the do-not-cross-shells constraint behind B-17), `:34-37`
  (guard is fail-closed by design). Distributed twin present at
  `skills/harness-init/templates/common/.harness/scripts/hook-spec.{sh,ps1}`, which is why B-15's fallback is
  about older projects only.
- The repair-path asymmetry behind FR-8: `.harness/scripts/upgrade-project.sh:248-251,285,342-348` rewires
  `.claude/settings.json` only; `.harness/scripts/install-hooks.sh:151-162` refuses to touch an existing
  machine-local file (keys on presence alone) and `:39-47,236-238` document the remove-and-re-run path.
- The documented persistent opt-out behind FR-13 and B-5: `.harness/rules/75-safety-hook.md:95-110`; the
  dogfood relocation note at `:10-22`.
- Machine-local file is gitignored in this repository: `.gitignore:58-60`.
- The structural pin on this skill's rows: `.harness/scripts/test-supervisor.sh:394-399` (two assertions —
  the plugin-provided note and the retired canonical-7 glob; neither matches the guard row, so a guard-row
  edit is expected to leave them green, and AC-10 requires that to be verified by a run rather than assumed).
  PowerShell twin: `.harness/scripts/test-supervisor.ps1:435-440`.
- Downstream consumer of the vocabulary NFR-2 protects: `skills/harness-upgrade/SKILL.md:29-33`.
- Frozen counts and the standing operator list: `.harness/scripts/baseline.json:11` (`test_init_ps_assertions`
  316, unreconciled) and `:23` (the eight enumerated mandatory operator PowerShell steps); README badge row
  `README.md:5`.
- Current release stamps behind OQ-6: `.claude-plugin/plugin.json:4` (`0.45.0`), `CHANGELOG.md:8` (the
  `[0.45.0] - 2026-07-31` heading describing T-13 only), `README.md:5` (version badge `0.45.0`).
- Wave framing and the sibling boundaries: `docs/batches/default/BATCH_PLAN.md:29-31,36-38`;
  `docs/features/_archived/hook-truth-spec/01_REQUIREMENT_ANALYSIS.md:366-368` already records this exact
  defect and assigns it here.

---

## 9. Verdict

**READY**

All ten open questions carry a `Recommended:` answer that the Solution Architect adopts as the binding
default unless the operator overrides; none is human-reserved and none blocks design. Every acceptance
criterion is independently verifiable, AC-1 and AC-2 are pinned to captured runs against real current state,
and the gate expectation (PASS 32 / WARN 0 / FAIL 0, check count 32) is unchanged.
