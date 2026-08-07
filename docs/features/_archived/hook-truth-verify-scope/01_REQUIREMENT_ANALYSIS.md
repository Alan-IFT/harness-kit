# 01 — Requirement Analysis — T-15 `hook-truth-verify-scope`

- **Mode**: `full` (7-stage), dispatched from a `/harness-stream` drain
- **deferred-human mode**: defer, do not ask. Every ambiguity below carries a labelled
  `Recommended:` answer that the PM/Architect adopts unless the operator overrides it.
- **Decision mode**: Mode 2 (balanced) — `.harness/rules/25-decision-policy.md` + `.harness/decision-rubric.md`
- Date: 2026-08-01

---

## 0. ASSESS-FIRST — is this row still worth building?

### Verdict: **PROCEED**

The row's motivation was weakened by T-13 and T-14, but not removed. A clean checkout of this
repository fails `verify_all` today, in both shells, for a condition the repository cannot
express — and the two candidate "do nothing" arguments both fail on evidence.

### Evidence (read from the live tree, not from the goal sentence)

**E-1 — the clean-checkout failure is real, deterministic, and in both shells.**
The bash guard check (`verify_all.sh:290-334`, id `F.2`) selects its hooks evidence file as:
machine-local settings if it exists *and* contains `"PreToolUse"`, else the committed settings
file. On a clean checkout the machine-local file is absent — `.gitignore:60` ignores
`.claude/settings.local.json` explicitly — so the check falls back to the committed
`.claude/settings.json`, which since T-12 carries `"hooks": {}` (`.claude/settings.json:21`,
with `_hooks_moved` at line 4 stating the relocation was deliberate so "the published plugin
distributes NO leakable hooks"). All three of the check's wiring greps then fail, producing
`no_PreToolUse no_Bash_matcher no_guard-rm_command` at **FAIL** severity. The PowerShell twin
(`verify_all.ps1:276-310`) takes the identical fallback and throws
`missing hooks.PreToolUse[]`. `verify_all` exits non-zero on any FAIL, so **a fresh clone and
every CI run fail the release gate on machine state**, not on a repository defect.

**E-2 — the assertion is machine-answerable only, and its own in-code justification does not
hold for this script.** The check's comment (`verify_all.sh:301-302`) justifies the fallback as
"a user project that keeps hooks in the committed file is still validated". That is false for
this file: this 32-check `verify_all` is **dogfood-only**. Generated projects receive a
different, stack-specific gate from the type overlays
(`skills/harness-init/templates/{generic,backend,fullstack}/.harness/scripts/verify_all.{sh,ps1}.tmpl`),
and a search of the generic overlay for `guard-rm` / `PreToolUse` returns **0 occurrences**;
`templates/common/.harness/scripts/` ships no `verify_all` at all. So the machine-read assertion
protects exactly one machine — the maintainer's — and dropping it removes **zero** user-facing
coverage.

**E-3 — there is no conditional formulation that is both correct and safe, so "narrow" is the
only sound resolution.** The obvious middle path is J.1's own pattern in the same script
(`verify_all.sh:660`, `[[ -f ]] || continue`): assert the wiring only when the machine-local
file is present. That formulation is **wrong**, because the documented durable opt-out for the
safety hook is precisely *a present machine-local file carrying an empty hooks object*
(`.harness/rules/75-safety-hook.md:160-170`, and `.claude/settings.local.json:4`'s own
`_hook_semantics` note: "To keep every hook off permanently, leave this file in place with an
empty hooks object"). A present-implies-wired assertion at FAIL severity would turn the
documented disable path into a gate failure. The machine dimension has no correct expression
inside a repository gate at all.

**E-4 — the stated precondition is satisfied; responsibility has a new owner.** T-14 delivered
`§0 Effective hook source` into `skills/harness-status/SKILL.md`: the health report resolves
machine-local → committed by precedence, names the file the wiring was found in, and
distinguishes never-installed / documented opt-out / dangling / installed-and-wired
(`docs/features/_archived/hook-truth-status/07_DELIVERY.md:86-100`, and its "T-15 is now
unblocked" note at line 145).

### Why the two decline arguments fail

- *"T-13 made it bootstrappable, so it is an acceptable first-run step."* T-13's installer
  bootstrap (`docs/features/_archived/hook-truth-spec/07_DELIVERY.md:3`, AI-GUIDE script index)
  makes the failure **repairable**, not **absent**. A gate that requires a machine-mutating
  installer run — one that also writes `.git/hooks/pre-commit` — as a precondition of asserting
  facts about a repository is asserting the wrong thing. CI cannot be fixed by documentation.
- *"T-10 set a decline precedent."* T-10 declined because every concept mapped 1:1 onto existing
  machinery, i.e. there was **no defect left**. Here a reproducible FAIL remains, and the
  narrowing is a *removal* of surface, which is the direction the rubric's "lightweight over
  heavy / design out the root cause" line favours.

### What PROCEED must not be mistaken for

The gate has never checked what the guard *does* — only that its scripts exist and something is
wired. That blindness is how the chained-command bypass survived until T-17. Narrowing the gate
therefore **reduces no behavioural guard coverage**; the behavioural coverage lives in
`test-guard-rm` (87 rows, pinned in `baseline.json:23`) and in the guard itself. Any delivery
prose describing this change as "reducing guard coverage" is inaccurate and must be corrected.

---

## 1. Goal

`verify_all`'s guard-wiring check asserts a fact about the maintainer's machine, so a clean
checkout fails the release gate for an environment condition; narrow it to the facts the
repository itself can answer, at unchanged severity and unchanged check count.

## 2. In-scope behaviors

**FR-1.** The guard-wiring check asserts that the guard script pair exists at both the repository
path and the distributed-template path — four files, unchanged from today.

**FR-2.** The check asserts that the distributed settings template carries the guard command
placeholder and a pre-tool hook block.

**FR-3.** The check reads no machine-local settings file and no committed settings file. Its
result is a function of tracked repository content only.

**FR-4.** Every assertion the check retains reports at **FAIL** severity. No assertion is
downgraded to WARN or INFO.

**FR-5.** The check emits a single recorded step under its existing identifier, so the gate's
total check count is unchanged.

**FR-6.** The check's human-readable label and its in-file comment describe what it asserts after
the narrowing; neither claims settings-file or machine wiring coverage.

**FR-7.** The bash and PowerShell implementations assert the same set of facts and fail on the
same inputs, differing only in language idiom.

**FR-8.** Any live project document that states what this check covers is corrected to match the
narrowed assertion set. Historical roadmap/CHANGELOG rows and archived stage documents that
record the check's *past* behavior are frozen and untouched.

**FR-9.** The machine dimension is confirmed **by execution** to still be reported by the
project-health report — the never-installed state and the installed-and-wired state are both
exercised and their output pasted into the stage document that ran them.

## 3. Out-of-scope

1. Re-pointing the four command-derivation flows at the hook wiring spec — that is **T-16**.
2. Any change to guard behavior, to the destructive verb set, or to either guard script.
3. The residual bypass surface T-17 published and deliberately left open.
4. Adding any new `verify_all` check, including one that would "compensate" for the narrowed
   assertions. The defect class closes with the check count flat.
5. Changing the health report, the installer, the hook wiring spec, or any settings file.
6. Reconciling the frozen PowerShell operator items from T-13/T-17.
7. `docs/proposals/frontier-gaps-2026-07.md` — an untracked operator backlog document. Not read,
   not edited, not cited, not committed.
8. Committing anything. The tree is left green; the operator commits.

## 4. Boundary conditions

| # | Condition | Required behavior |
|---|---|---|
| B-1 | Machine-local settings file absent (clean checkout / CI) | Check PASSes |
| B-2 | Machine-local settings file present and fully wired | Check PASSes, identical result to B-1 |
| B-3 | Machine-local settings file present with an empty hooks object (the documented opt-out) | Check PASSes — the opt-out is legitimate and the gate does not judge it |
| B-4 | Committed settings file absent, empty, or unparseable | Check PASSes — it is no longer an input |
| B-5 | Any one of the four guard scripts missing | Check FAILs, naming the missing path |
| B-6 | Distributed settings template missing | Check FAILs, naming the missing path |
| B-7 | Template present but the guard placeholder removed | Check FAILs |
| B-8 | Template present but the pre-tool hook block removed | Check FAILs |
| B-9 | Multiple problems simultaneously | All are reported in one message; the check does not stop at the first |
| B-10 | Verification of B-1 | Performed against a tree state carrying no machine-local settings file, produced **without renaming, moving, emptying or deleting the live `.claude/settings.local.json`** — mutating it would disarm the live fail-closed guard for the remainder of the session |
| B-11 | Any scratch tree created for B-10 | Cleaning it up outside the project root triggers the destructive-command guard; either keep the scratch tree inside the project root or use the documented per-call override, and never disable the guard to do it |
| B-12 | The gate's own summary | `PASS 32 / WARN 0 / FAIL 0`; a WARN is a hard failure (`verify_all` exits 1 on `warns > 0`) |

## 5. Acceptance criteria

**AC-1.** Running the bash gate on the working tree yields **PASS 32 / WARN 0 / FAIL 0**, pasted
from the run that produced it (never re-derived arithmetically).

**AC-2.** Running the bash gate against a tree state with **no machine-local settings file**
yields a green result with the guard check PASSing — the pasted evidence that a clean checkout no
longer fails. Constructed per B-10/B-11.

**AC-3.** The pre-change gate is shown to FAIL on that same clean state, so AC-2 measures a real
change rather than asserting one. Both exit codes and the guard check's message are pasted.

**AC-4.** Neither implementation contains any read of a settings file inside the guard check —
verifiable by inspection of the check's body in both shells.

**AC-5.** The check's remaining assertions are **anti-vacuity tested by mutating the ARTIFACT**,
not by editing a name list: deleting one template guard script, and separately removing the guard
placeholder from the settings template, each turn the check red on its own, and the tree is
restored afterward with the gate green again.

**AC-6.** Every retained assertion reports at FAIL severity — confirmed by AC-5's runs showing
`FAIL`, not `WARN`.

**AC-7.** `verify_all_checks` in `baseline.json` remains `32` and no version stamp moves, or —
if the count genuinely moves — every count/version claim surface is reconciled in the same change
and the gate's doc-consistency check passes.

**AC-8.** `test-guard-rm` reports **87 / 0** unchanged, and no other pinned baseline count moves.

**AC-9.** Both shells are updated symmetrically; the PowerShell change is declared
**green-by-symmetry only** and appended as a new enumerated item to the standing operator
PowerShell verification list, without touching the frozen T-13/T-17 items.

**AC-10.** The health-report machine dimension is confirmed by execution (FR-9): the report names
the machine-local file in the wired state, and reports the never-installed state distinctly, with
both outputs pasted.

**AC-11.** Every live document naming what this check covers agrees with the shipped behavior;
no frozen historical row is edited.

**AC-12.** The delivery document states plainly that behavioural guard coverage is unchanged and
that the machine dimension moved to the health report rather than disappearing.

## 6. Non-functional requirements

**NFR-1 (safety).** No change to any guard script, hook command, settings file, or `.gitignore`
entry. The live `PreToolUse` guard stays armed for the whole task.

**NFR-2 (documentation size).** `.harness/rules/75-safety-hook.md` sits at exactly **200 of 200**
permitted lines. If it must be touched, room is made by condensing first; the line count is
confirmed before and after, and never exceeds 200. A WARN is a gate failure.

**NFR-3 (honest reporting).** Every tally is pasted from the artifact that produced it.

**NFR-4 (compatibility).** Generated user projects are unaffected — they run a different gate.

## 7. Related tasks

| Task | Relevance |
|---|---|
| T-12 `resilient-hooks` (`docs/features/_archived/resilient-hooks/`) | Moved the dogfood hooks into the gitignored machine-local file and added the fallback that creates this defect |
| T-13 `hook-truth-spec` (`docs/features/_archived/hook-truth-spec/`) | Installer bootstrap — makes the failure repairable, not absent |
| T-14 `hook-truth-status` (`docs/features/_archived/hook-truth-status/`) | The health report now owns the machine dimension; this row's stated precondition |
| T-17 `guard-cmd-chain` (`docs/features/_archived/guard-cmd-chain/`) | Rewrote both guard scripts; driver 17 → 87 rows, now pinned; rule doc at 200/200 |
| T-10 `planning-decision-map` (`docs/features/_archived/planning-decision-map/`) | The decline precedent, assessed and rejected here on evidence |
| T-11a (insight 2026-06-20) | Presence checks are load-bearing only against a missing artifact — shapes AC-5 |

## 8. Open questions for the operator (each resolved by the `Recommended:` answer)

**OQ-1 — Is narrowing a safety-adjacent gate check a red-line-5 escalation?**
(a) Escalate and block; (b) proceed, recording it for after-the-fact review.
**Recommended: (b).** No runtime safety behavior changes; the assertion being dropped protects one
machine and has no correct formulation (E-3). Flagged in the delivery for operator spot-check.

**OQ-2 — Keep a presence-conditional machine assertion instead of dropping it?**
(a) Keep it conditional at FAIL; (b) drop it entirely.
**Recommended: (b).** (a) fails the documented opt-out state (E-3).

**OQ-3 — Relabel the check?**
(a) Keep the current label; (b) relabel so the output stops claiming settings wiring.
**Recommended: (b).** No driver or baseline pins the label string; only archived stage docs quote
it, and those are frozen.

**OQ-4 — Which version does this land in?**
(a) Fold into the unreleased `0.46.0`; (b) bump.
**Recommended: (a).** No tag exists; the count is unchanged, so no stamp needs to move.

**OQ-5 — How is "a clean checkout passes" demonstrated (AC-2)?**
(a) Mutate the live `.claude/`; (b) build a separate tree state and run the gate there.
**Recommended: (b), and (a) is forbidden** — (a) disarms the live fail-closed guard.

**OQ-6 — Does the template-side assertion need widening while we are here?**
(a) Also assert the template's guard command byte-form against the hook wiring spec; (b) no.
**Recommended: (b).** That is T-16's territory and would grow the check.

**OQ-7 — Does the health-report confirmation (FR-9/AC-10) need a new automated test?**
(a) Add a regression driver; (b) confirm by execution once and record the output.
**Recommended: (b).** Adding coverage for another task's product is scope expansion.

## 9. Verdict

**READY** — assessment complete (**PROCEED**), scope bounded, every open question carries a
binding recommended answer. No `BLOCKED: NEEDS-HUMAN` item arose.
