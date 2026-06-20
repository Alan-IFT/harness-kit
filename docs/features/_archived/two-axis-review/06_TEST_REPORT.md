# 06 — Test Report · T-08 two-axis-review

> Stage 6 (QA Tester). Mode: full. deferred-human: defer, do not ask.
> Scope: T-08's 6 files only (sibling/in-flight churn excluded). Upstream CR = APPROVED (both axes clean).
> Tooling: Bash available; PowerShell DENIED for sub-agent — `verify_all.ps1` twin marked operator-pending (never faked). Precedent T-05/T-07.
> Nature of change: agent-prose + version fan-out. No code/script/gate moves; the test surface is the
> agent contract itself (grep/structure assertions) + `verify_all` — there is no unit-test suite delta.

## Test plan

| Acceptance criterion (01 §6) | Test case(s) | Evidence |
|---|---|---|
| AC-1 names both axes + masking rule | grep axis names + "Masking rule" + the binding clause | code-reviewer.md L27-51 (section), L45/47-48 (masking) — present |
| AC-2 `tools:` still exactly `Read, Glob, Grep` | word-boundary regex for any write/exec tool on L4 | L4 = `tools: Read, Glob, Grep`; no Edit/Write/Bash/PowerShell/Task — PASS |
| AC-3 verdict per-axis; APPROVED impossible w/ open axis CRIT/MAJOR | read masking clause + verdict gate + `## Axis status` order | L47-48 + L78 + `## Axis status`(L119) above `## Verdict`(L123) — PASS |
| AC-4 6 dims + coverage + design check retained | grep the 6 table rows + both check headings | L20-25 (6 rows), Requirement coverage check + Design fidelity check both present |
| AC-5 severity model + rollback byte-equivalent | inspect `## Severity levels` + Hard rule 1 + verdict bullets | L53-58 intact; L62 + L78-79 routing intact; only verdict step renumbered 6→7 |
| AC-6 ≤300 lines | `wc -l` | 139 ≤ 300 — PASS |
| AC-7 0.39.0 ×4 + CHANGELOG [0.39.0] | grep 4 stamps + CHANGELOG heading | plugin.json L4, marketplace.json L17, both README L5 = 0.39.0; CHANGELOG `## [0.39.0]` L8 |
| AC-8 counts 16/8/32 unchanged | grep README badges + descriptions + CHANGELOG restatement | `32%2F32`/`308%2F308`/`90%2F90` + "16 skills/8 framework agents/32 checks" unchanged |
| AC-9 verify_all 32/0/0 | run `verify_all.sh` | 32/0/0 (run twice) — PASS |
| AC-10 no new I.6 banned/exempt; no self-trip | I.6 PASS + new-section path:line scan | I.6 PASS; new section L27-51 has 0 path:line tokens |

## Boundary tests added (verified against the contract prose, 01 §5)

- **BC-1 no `02_SOLUTION_DESIGN.md` (requirement-only):** contract L49-50 routes the Spec/design axis
  to `01` alone and emits "Spec/design: no design doc — requirement-only" — does not fabricate/block. ✅
- **BC-2 empty axis must speak (no silent omission):** contract L46 forces "Standards: no findings"
  explicitly; silence is named as the masking failure mode this lens exists to prevent. ✅
- **BC-3 finding spans both axes:** contract L42-43 "Attribute, don't double-count; cross-reference". ✅
- **BC-4 cap headroom:** 139 lines, 161-line headroom under the I.3 300 cap. ✅
- **BC-5 cross-shell:** Markdown-only change, no script surface introduced. ✅ (PS verify twin still operator-pending.)

## Adversarial tests (REQUIRED, one per acceptance criterion)

Independent reproducers written from the acceptance criteria (not from 04's self-review). Each carries
a stated failure hypothesis; verdict is "did the implementation SURVIVE", not "did the dev's tests pass".

| AC | Hypothesis ("I expect failure when…") | Reproducer (NEW, I wrote) | Outcome (tool output) |
|---|---|---|---|
| AC-1 | the new section smuggled a stray four-backtick fence or a ` ```markdown ` into agent prose | `grep -n '````' agents/code-reviewer.md` + `grep -n '```markdown'` | SURVIVED — four-backtick: none (exit 1). ` ```markdown ` = 1 hit @L83, the PRE-EXISTING format-template fence (`## Review document format`@L81), not in the new section. |
| AC-1 | new content reintroduced the foreign `BLOCKER` vocab | `grep -n 'BLOCKER' agents/code-reviewer.md` | SURVIVED — none (exit 1). New content uses CRITICAL. |
| AC-2 | frontmatter quietly gained a write/exec tool | `sed -n '4p' \| grep -E '\b(Edit\|Write\|Bash\|PowerShell\|Task\|MultiEdit\|NotebookEdit)\b'` | SURVIVED — "PASS: only Read/Glob/Grep; no write/exec tool". L4 byte-exact `tools: Read, Glob, Grep`. |
| AC-3 | an aggregate APPROVED can coexist with an open axis CRITICAL (the masking bug this feature exists to kill) | constructed the masking case (Standards clean, Spec/design 1 open CRITICAL) and read it against BOTH gating clauses | SURVIVED — L78 "APPROVED — no CRITICAL or MAJOR" (any CRITICAL on EITHER axis blocks) AND L47-48 "cannot read APPROVED while either axis carries an unaddressed CRITICAL or MAJOR". Two independent clauses forbid it. |
| AC-3 | `## Axis status` sits BELOW `## Verdict` (so the per-axis status doesn't precede/bind the verdict) | grep heading offsets in the format template | SURVIVED — `## Axis status`@L119 is ABOVE `## Verdict`@L123. |
| AC-3 | no Workflow step records per-axis worst severity (so the rule isn't operationalized) | `grep -nE 'record each' agents/code-reviewer.md` | SURVIVED — Workflow step 6 @L75-76 "Group every finding under its axis … record each axis's worst severity — including an explicit clean result". Verdict step renumbered to 7@L77. |
| AC-4 | a dimension row or a check table was dropped when the section was inserted | grep the 6 numbered rows + both check headings | SURVIVED — 6 rows @L20-25; "Requirement coverage check" + "Design fidelity check" both present. |
| AC-5 | the verdict edit silently rewrote the severity model or the rollback routing | inspect `## Severity levels` block + Hard rule 1 + verdict CHANGES REQUIRED bullet | SURVIVED — severity block L53-58 intact (CRITICAL/MAJOR/MINOR/NIT); routing intact (L62 "route back to developer via PM"; L79 "routes back to developer"). |
| AC-6 | the section pushed the file over the 300-line I.3 cap | `wc -l < agents/code-reviewer.md` | SURVIVED — 139 lines. |
| AC-7 | a version surface was missed (stamp drift) | grep 0.39.0 across plugin.json/marketplace.json/both READMEs + CHANGELOG heading | SURVIVED — plugin.json L4, marketplace.json L17, README L5, README.zh-CN L5 all 0.39.0; CHANGELOG `## [0.39.0]`@L8. |
| AC-8 | the version bump flipped a 16/8/32 count token (decoy-flip class) | grep `32%2F32`/`308%2F308`/`90%2F90` badges + counts descriptions in both READMEs + CHANGELOG | SURVIVED — all count badges + "16 skills / 8 framework agents / 32 checks" unchanged; CHANGELOG [0.39.0] restates them unchanged (L29). |
| AC-9 | a hidden WARN/FAIL or check-count change | `bash .harness/scripts/verify_all.sh` ×2 | SURVIVED — 32/0/0 both runs (full output below). |
| AC-10 | the new prose self-trips I.6 or introduces a NEW `name.ext:NNN` | I.6 result + path:line scan of the NEW section L27-51 | SURVIVED — I.6 PASS; new section has 0 path:line tokens. The only `*.ts:NN` (`x.ts:42`@L108, `y.ts:18`@L110) are PRE-EXISTING example placeholders in the coverage-check template, byte-unchanged. |

### Pasted evidence (verify_all.sh, run 1)

```
[G.3] Version stamps consistent across plugin/marketplace/README ... PASS
[I.3] Agent definitions ≤300 lines each ... PASS
[I.6] No retired-claim phrases in current docs/templates ... PASS
[G.4] Doc count/version claims consistent with plugin.json + live check count ... PASS
=== Summary ===
  PASS: 32
  WARN: 0
  FAIL: 0
```

(Run 2 identical: PASS 32 / WARN 0 / FAIL 0.)

## verify_all result

- Total checks: 32 → 32 (no check added/removed; matches expected 32/0/0).
- Pass: 32
- Fail: 0 (required for approval)
- Warn: 0
- Sub-results matched to brief: **G.3** 0.39.0 ×4 stamps consistent — PASS; **G.4** `[0.39.0]` heading,
  counts consistent — PASS; **I.3** code-reviewer.md 139 ≤ 300 — PASS; **I.6** clean — PASS.
- New automated tests added: 0 (agent-prose change; no unit-test suite surface — verify_all is the
  source of truth and is unchanged at 32 checks).
- Baseline updated: **no** (test/check counts unchanged; baseline only goes up — nothing to raise).

## Defects found

None.

- CRITICAL: 0
- MAJOR: 0
- MINOR: 0
- NIT: 0

(The CR's single NIT — "aggregate = the more severe of the two axes" doesn't spell the total order —
was re-examined; the severity list at L53-58 is already ordered and the phrasing is unambiguous to a
human reviewer. Pure preference, non-binding, not re-filed.)

## Stability

- `verify_all.sh` ran 2× back-to-back — 32/0/0 both times, no flake. ✅
- The change is static Markdown + JSON; no timing, concurrency, or I/O surface — no flake vector. ✅

## Operator-pending (PowerShell twin)

- `verify_all.ps1` NOT run (PowerShell denied for sub-agent). The Bash twin is 32/0/0; the PS twin is
  expected to match (precedent T-05/T-07). Marked operator-pending — NOT faked.

## Verdict

**APPROVED FOR DELIVERY** — 0 defects. All 10 acceptance criteria survived independent adversarial
reproducers; both review axes (Standards-conformance / Spec-design-fidelity) verified clean; the
masking invariant binds the verdict and is operationalized by Workflow step 6 + the `## Axis status`
block above `## Verdict`. Existing structure (6-dim table, severity block, rollback routing) byte-intact;
no count flip; version 0.39.0 across 4 stamps + CHANGELOG `[0.39.0]`. verify_all.sh 32/0/0 (×2, no flake).
PS twin operator-pending.
