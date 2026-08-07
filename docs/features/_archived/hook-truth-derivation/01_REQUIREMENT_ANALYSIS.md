# 01 — Requirement Analysis · T-16 `hook-truth-derivation`

- **Mode**: `full` (stages 1-7) · dispatched from a `/harness-stream` drain
- **Decision mode**: Mode 2 (balanced) · **deferred-human: defer, do not ask** — every ambiguity below
  carries a labelled `Recommended:` answer that the Architect adopts unless the operator overrides it.
- **Stage-1 verdict**: see §10.

---

## 1. Goal

Every artifact that writes a lifecycle-hook command into a project's settings obtains that command's
byte-form from the hook wiring spec instead of carrying its own hand-maintained copy, so that changing
a hook command is a one-place edit rather than a multi-artifact lockstep.

---

## 2. Derived call-site inventory (EVIDENCE — enumerated, not inherited)

The T-13 hand-off header claims to name "every remaining call site". It does not: a repository-wide
search for the two distinctive command idioms returns **two live script files it omits**. The inventory
below is the derived one and supersedes the header's list.

| # | Artifact | What it carries | Class | Named in T-13 header? |
|---|---|---|---|---|
| 1 | `upgrade-project.{sh,ps1}` — upgrade-repair flow | `resilient_cmd` / `Get-ResilientCmd`, all 4 shapes | flow | yes |
| 2 | `migrate-scripts-layout.{sh,ps1}` — layout-migration flow | a **second, independent** copy of the same helper | flow | yes |
| 3 | `skills/harness-init/SKILL.md` step-5 placeholder table | all 8 `(tool, OS)` byte-forms in prose | flow | yes |
| 4 | `skills/harness-adopt/SKILL.md` substitution table | semantics restated; bytes deferred to #3 | flow | yes |
| 5 | `test-init.{sh,ps1}` `EXP_*` / `$exp*` | all 8 cells, as test expectations | test | yes |
| 6 | `test-real-project.{sh,ps1}` | all 8 cells, as test expectations | test | **NO — omitted** |
| 7 | `test-harness-upgrade.{sh,ps1}` | 2 JSON-escaped sync forms + raw-shell probes | test | yes |
| 8 | `test-guard-rm.{sh,ps1}`, `evals/guard-rm-cases.md` | the raw unix guard command as guard **input data** | test data | no (not a wiring copy) |
| 9 | `skills/harness-status/SKILL.md` | names the `$CLAUDE_PROJECT_DIR` anchor idiom only — **not** a byte-form copy | prose | n/a |

Items 1 and 2 exist twice each on disk (repo copy + `templates/common/` source, kept byte-identical by
`sync-self` Mappings 6/7), so a byte edit today touches **8 script files, 2 skill documents and 8 test
files** in lockstep. That is the defect.

Evidence: `.harness/scripts/hook-spec.sh:39-52` (the hand-off list); `.harness/scripts/upgrade-project.sh:102-117`;
`.harness/scripts/migrate-scripts-layout.sh:117-132`; `skills/harness-init/SKILL.md:187-190`;
`skills/harness-adopt/SKILL.md:311-314`; `.harness/scripts/test-init.sh:53-60`;
`.harness/scripts/test-real-project.sh:48-57`; `.harness/scripts/test-harness-upgrade.sh:296,306`;
`.harness/scripts/sync-self.sh:78,82,90`.

### 2b. The three stale prose consumers (verified against current files)

| Artifact | Current claim | Why it is false |
|---|---|---|
| `AI-GUIDE.md:110` | "The Stop hook in `.claude/settings.json` does this automatically at session end." | this repo's committed settings carries `"hooks": {}` |
| `docs/getting-started.md:180-182` | "The Stop hook in `.claude/settings.json` runs `harness-sync` automatically at session end" | same |
| `.harness/rules/60-tool-handoff.md:72-75` | "The Stop hook in `.claude/settings.json` auto-runs `.harness/scripts/harness-sync` at session end" | same |

Evidence: `.claude/settings.json:21` is `"hooks": {}`; `:4` records that the dogfood hooks moved to the
machine-local settings file. Note the nuance each of the three sentences erases: in a **generated user
project** the hooks genuinely do live in the committed settings file — the claim is false for this repo
and true for a generated project, and none of the three says which it is describing.

---

## 3. In-scope behaviors

**Provenance**

1. Each of the four derivation flows obtains every hook command byte-form it writes by querying the hook
   wiring spec at run time, and holds no literal copy of any of the eight `(tool, OS)` byte-forms.
2. Changing one byte inside the hook wiring spec's command answer changes what all four flows emit, with
   no edit to any flow.
3. Each flow queries the spec twin of its own shell; no flow captures the output of the other shell's twin.
4. Each flow's emitted commands are byte-identical to what that flow emits today, for both OS variants
   and all four tools.
5. The `guard-rm` command every flow emits carries no `|| exit 0` and no trailing `exit 0`; the other
   three carry their existing fail-open construction. No flow gains a code path that can emit a
   fail-open guard command.
6. Where a flow needs a hook's event name, matcher, or fail-open/fail-closed classification, it takes
   that from the spec as well, rather than restating it.

**Prose**

7. The three stale prose consumers no longer assert that this repository's lifecycle hooks live in a
   fixed settings file. Each states the durable fact (a Stop hook runs `harness-sync` at session end)
   without naming a location that machine state can falsify, or points at the authority that resolves
   the location.
8. The two skill placeholder tables state each placeholder's meaning, its event, its matcher and its
   fail-open/fail-closed classification, and instruct the executing agent to obtain the byte-form from
   the spec and paste the captured value verbatim. Neither table contains a command byte-form.
9. The spec's own T-16 hand-off header is corrected to match the derived inventory in §2: sites that are
   retired are removed from it, sites deliberately retained (see OQ-1) are re-labelled as deliberate, and
   the two omitted test files are named.

**Gate**

10. The settings-template assertions fail when the guard placeholder is present in the template but is
    **not** inside the `PreToolUse` hook block, and when the `PreToolUse` block carries no command entry
    (T-15's inherited containment residual — see OQ-2).
11. The `verify_all` check count stays 32. No check is added, removed, or renamed.

---

## 4. Out of scope (explicit non-goals)

1. Any change to guard behaviour, to the destructive-verb set, or to what the guard blocks.
2. Retiring the **raw-escaping-level** command forms (the shell-level probes in `test-harness-upgrade`,
   `test-guard-rm`, `evals/guard-rm-cases.md`). The spec deliberately emits one escaping level; a raw
   form would be a new spec query, i.e. a change to the source, not to a consumer.
3. Retiring the **legacy brittle needles** the repair flows search for (the pre-v0.44 `pwsh -NoProfile
   -File …` / `bash …` values). Those describe legacy input to be replaced, not output to be emitted.
4. The `archive-task` insight-harvester wrapped-bullet truncation defect.
5. The residual bypass surface published by T-17 and its chunked-indexing performance follow-up.
6. `docs/proposals/frontier-gaps-2026-07.md` — untracked operator backlog. Not edited, not cited as a
   requirement, not included in any commit.
7. Adding a fifth hook tool, or changing any tool's event or matcher.
8. Reconciling the PowerShell assertion baseline or the README PS badges from a claimed run.

---

## 5. Boundary conditions

**B-1 — spec unreachable.** The layout-migration flow runs from a project root with no template-root
argument and may execute in a project predating the spec's existence, so the spec can be absent. A flow
that cannot obtain a byte-form does not write that tool's command at all: it leaves the existing settings
value untouched, emits an explicit diagnostic record naming the tool, and never fabricates, degrades, or
falls back to an embedded copy. The existing terminal congruence assertion continues to run and continues
to own the exit code for a dangling wiring.

**B-2 — spec answers empty or non-zero.** An exit-2 answer (empty stdout) is treated exactly as B-1. No
flow writes an empty string into a `"command"` value.

**B-3 — fail-closed asymmetry.** For `guard-rm`, B-1 and B-2 resolve to "do not write", never to "write
something permissive". An emitted guard command that would exit 0 when the guard script is missing is a
defect of this task regardless of any other criterion being met.

**B-4 — quoting level.** Byte-identity is compared on **runtime values**, not on source text. The bash
sources spell the same value with `\\\"` inside double quotes and `\"` inside single quotes, and the
markdown tables escape `|` as `\|` for table syntax. Comparison resolves each artifact's own quoting
first; markdown pipe escaping is presentation and is excluded from the compared value.

**B-5 — the `&` hazard.** The unix convenience byte-form and the Windows guard byte-form both contain a
literal `&`. Under bash 5.2's default `patsub_replacement`, an unescaped `&` in the replacement half of
`${var//needle/repl}` expands to the matched text. Any substitution of a spec-derived value in bash uses
the repo's existing literal-replacement helper. PowerShell `.Replace()` is ordinal, so a PowerShell-only
check cannot observe this corruption.

**B-6 — placeholder tokens in shipped scripts.** Any script that ships into a generated project carries
no literal `{{NAME}}`-form token; the init regression driver scans generated output for unresolved
placeholders. A token that is genuinely needed is assembled from pieces at run time.

**B-7 — cross-shell capture.** Bash capturing PowerShell output through `$( … )` strips the trailing
newline but leaves the `\r`, corrupting the value. The spec's stdout line-ending bytes are not part of
its contract; the captured value is.

**B-8 — twin drift.** The repo copies and the `templates/common/` sources of the two repair scripts are
byte-identical by gate. Every change is made at the template source and propagated by `sync-self`.

**B-9 — the 200/200 rule fragment.** `.harness/rules/75-safety-hook.md` is at exactly 200 of 200 permitted
lines. `verify_all` exits 1 when warns > 0, so a 201st line fails the release gate. If that file must be
touched, room is made by condensing first, and the line count is confirmed before and after.

**B-10 — live fail-closed hook.** The guard script itself is not modified by this task. If any change
would touch it, it is staged in the unwired template copy, syntax-checked, and promoted once — editing the
live `PreToolUse` hook in place can seize the Bash toolchain.

**B-11 — dirty working tree.** Four siblings' delivered-but-uncommitted changes are present. Absence from
`git diff --name-only` is therefore not a freeze proof; a freeze claim is carried by the dirty-set
difference **plus** per-file mtime ordering against this task's first write.

---

## 6. Acceptance criteria (each falsifiable)

**AC-1 — single source, by construction.** Mutating one command answer in the hook wiring spec (both
twins) and re-running each of the four flows against a fixture makes all four emit the mutated value,
with zero edits to the flows. Falsified by any flow emitting the pre-mutation value. The mutation is
reverted before the final gate run.

**AC-2 — byte-identity, by capture.** For all 8 `(tool, OS)` cells and each of the four flows, the
emitted value after the change equals the value captured from the **committed pre-change artifact**
before the change. The pre-change capture is produced by executing the pre-change artifact (or, for the
two prose flows, by extracting the pre-change table literal), stored in the development record, and
compared mechanically. Inspection is not accepted as proof; neither is a comparison against the spec
alone, which is circular after the change.

**AC-3 — no literal survives in a flow.** A repository search of the four flows' sources for the two
distinctive command idioms returns zero hits outside the spec itself and outside the artifacts OQ-1 deliberately retains.

**AC-4 — fail-closed preserved.** For every flow and both OS variants, the emitted `guard-rm` command
contains no `|| exit 0` and no trailing `exit 0`, and a settings file written by each flow with the guard
script absent yields a non-zero exit from the guard command when executed. Measured, not argued.

**AC-5 — spec-unreachable degradation.** With the spec removed from a fixture, each flow leaves the
existing hook values untouched, emits its diagnostic record, and writes no empty or partial `"command"`
value. Verified per flow, in both the write and the re-run (idempotence) direction.

**AC-6 — prose consumers true.** Each of the three prose sentences is re-read after the change and
carries no assertion that this repository's hooks live in a named settings file, or defers to the
authority. Falsified by any of the three still naming a fixed file as the location of this repo's hooks.

**AC-7 — containment.** With the settings template mutated so the guard placeholder sits inside a
different hook block and the `PreToolUse` array is empty, the gate FAILs; the unmutated template PASSes.
Proven by mutating the artifact and running the post-change gate, and by running the **pre-change** gate
against the same mutation to show it passed before (the anti-vacuity direction).

**AC-8 — regressions green with captured counts.** `test-init`, `test-real-project`,
`test-harness-upgrade`, `test-verify-i6`, `test-supervisor`, `test-language`, `test-guard-rm` all pass on
bash. Any pinned count that moves is reconciled from a pasted real run; no count is hand-derived. A
driver that terminates without its summary line is treated as a failure, not as a pass.

**AC-9 — gate.** `.harness/scripts/verify_all` (bash) reports **PASS 32 / WARN 0 / FAIL 0**, check count
**32, unchanged**, captured from a real run.

**AC-10 — PowerShell honesty.** Every `.ps1` touched is added to the standing operator PowerShell list
(currently **eleven** items, two marked security) with the exact command the operator must run. No `.ps1`
is described as verified. The PS assertion baseline and the README PS badges stay frozen together.

**AC-11 — no scope leakage.** The guard script, the verb set, and the untracked operator backlog document
are unmodified; verified by the freeze method in B-11.

---

## 7. Non-functional requirements

**NFR-1 — flow latency.** Each flow gains at most one spec invocation per `(tool, OS)` value it needs
(bounded above by 8 per run). A per-item re-invocation inside a loop over settings lines is not
acceptable; values are obtained once per run and reused.

**NFR-2 — no new resident surface.** No new script, no new gate check, no new state file. The
duplication is eliminated by composition over the existing spec.

**NFR-3 — cross-shell parity.** Every behavior above holds in both shells. A change landed in one shell
and only described for the other is an incomplete hand-off (this repo has manufactured that class twice).

**NFR-4 — offline / no-network.** The flows stay pure local shell; the spec is pure and side-effect-free.

---

## 8. Related tasks

- **T-13 `hook-truth-spec`** (`docs/features/_archived/hook-truth-spec/`) — created the spec; its
  `07_DELIVERY.md` residual 7 hands this duplication to T-16 and its residual 2 warns that the
  distinct-events gate assumes exactly four tools.
- **T-12 `resilient-hooks`** (`docs/features/_archived/resilient-hooks/`) — origin of the byte-forms and
  of the "must be reproduced character-for-character" design note this task retires.
- **T-14 `hook-truth-status`** (`docs/features/_archived/hook-truth-status/`) — the health report's
  effective-hook-source resolution; the authority the prose consumers can defer to.
- **T-15 `hook-truth-verify-scope`** (`docs/features/_archived/hook-truth-verify-scope/`) — narrowed the
  gate to tracked content and handed the containment residual here (its `02_SOLUTION_DESIGN.md` §3.5
  states T-16 should carry it "as an explicit sub-item rather than rediscovering it from scratch").
- **`.harness/rejected-decisions.md` → `verify-gate-machine-hook-assertion`** — a machine-state hook
  assertion in the gate is a **declined** approach. In-scope item 10 stays inside tracked content
  (the settings template) and does not re-open it.

---

## 9. Open questions (deferred-human mode — each carries a binding recommendation)

**OQ-1 — Do the test drivers' expected-value literals get retired too?**
(a) Retire them; tests query the spec. (b) Keep them as independent frozen expectations.
**Recommended: (b), and additionally re-anchor the T-13 oracle assertions.** A test must not derive its
expectation from the artifact under test. Today `test-init`'s byte-identity block extracts the live
`resilient_cmd` from the upgrade-repair flow and compares it to the spec; once that helper delegates to
the spec, those assertions compare the spec with itself and become tautological while still reporting
green. So: keep `test-init` / `test-real-project` literals as the frozen oracle, and change the oracle
assertions to compare the spec against those literals rather than against the (now derived) helper. This
is a deliberate, recorded non-retirement, not an oversight — it is named as such in the corrected spec
header (in-scope item 9) and appended to `.harness/rejected-decisions.md`.

**OQ-2 — Is T-15's containment residual in scope for this row?**
(a) In scope, as a strengthening of the existing settings-template assertions. (b) Recorded as a follow-up.
**Recommended: (a), in scope.** Rationale, stated as required by the dispatch: T-15's design nominates
T-16 explicitly; the weakness is a proven false-green in the check that names the guard; the fix adds no
check (count holds at 32) and its blast radius is one check in each shell, which is self-detecting
because a broken assertion reddens the gate this task must pass anyway. The cost is one added operator
PowerShell item (AC-10). Cheapest sound form is a containment window over the template's hook block — it
needs no JSON parser and stays symmetric across shells; the mechanism choice is the Architect's.

**OQ-3 — What does a flow do when the spec is unreachable?**
(a) Abort the whole run. (b) Skip only the hook-wiring step, record a gap, continue. (c) Fall back to an
embedded copy.
**Recommended: (b).** (c) reinstates the duplication this task removes. (a) turns a partially-repairable
stale project into an unrepairable one, and the layout-migration flow is exactly the flow most likely to
run where the spec is absent. (b) preserves the existing exit-code contract, and the terminal congruence
assertion still fails a genuinely dangling wiring. Under no branch is a permissive guard command written.

**OQ-4 — How do the two prose flows "derive"?**
(a) Table rows keep the strings but add a pointer. (b) Table rows carry semantics plus an instruction to
invoke the spec and paste the captured value; no byte-forms.
**Recommended: (b).** (a) is the status quo with extra words — the copies would still drift. The tables
keep what the spec does not answer (which placeholder, which file it lands in, why `-NoProfile` matters)
and drop what it does answer. If the executing agent cannot invoke the spec, it refuses and reports;
it never improvises a command, and the existing step-10b congruence assertion still catches an
unresolved placeholder in the written settings.

**OQ-5 — What replaces the three false prose sentences?**
(a) Name the machine-local settings file instead. (b) State the behavior without a location and point at
the authority. (c) Distinguish "generated project" from "this repo".
**Recommended: (b) with one clause of (c).** (a) trades one machine-dependent claim for another — a
generated project's hooks are in the committed file. The durable statement is "a Stop hook runs
`harness-sync` at session end; where this project's wiring is resolved from is reported by the health
report's effective-hook-source section", plus a half-sentence noting a generated project ships it in the
committed settings file while this repo keeps it machine-local.

**OQ-6 — Do the two unnamed test files (`test-real-project.{sh,ps1}`) come along?**
(a) Ignore them — not in the hand-off list. (b) Fold them into the inventory and the freeze/verification.
**Recommended: (b).** The hand-off list is demonstrably incomplete (§2); acting on a list this task has
just falsified would repeat the defect class the task exists to remove. Their literals are retained per
OQ-1, and they are named in the corrected header per in-scope item 9.

**OQ-7 — Does the spec grow a `raw` command query for the shell-level probes?**
(a) Yes, this row. (b) No — record as a follow-up.
**Recommended: (b).** T-13 deliberately emits exactly one escaping level, and the raw consumers are test
probes and guard input data, not wiring writers. Adding a query changes the source of truth's contract
(and its arity/anti-vacuity gates) inside a task whose whole point is that consumers change and the
source does not. Recorded as a follow-up row, not silently dropped.

**OQ-8 — Reconciling counts if assertions move.**
(a) Adjust pins to the new numbers. (b) Adjust only from pasted captures, bash only; freeze PS.
**Recommended: (b).** This repo has shipped a fabricated-but-correct tally once and a
mis-derived-baseline claim once. Bash counts come from a pasted run; the PS assertion pin and both
README PS badges stay frozen and move together with the operator's PS run, never separately.

**Human-reserved escalations**: none. No red line in `.harness/rules/25-decision-policy.md` is engaged —
the retirements are the operator's own request (not autonomous scope expansion), the guard's
security-relevant semantics are preserved by constraint rather than chosen, and nothing here publishes,
force-pushes, or commits.

---

## 10. Verdict

**READY** — with the eight `Recommended:` answers in §9 binding on the Architect unless the operator
overrides them. No question is human-reserved; deferred-human mode is satisfied by recording them.
