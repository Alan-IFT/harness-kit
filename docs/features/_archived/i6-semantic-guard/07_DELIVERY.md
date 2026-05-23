# 07 — Delivery Summary · i6-semantic-guard (T-004 · v0.18.0)

- **Task**: Upgrade `verify_all` check I.6 from literal-substring matching to a
  gap-tolerant ordered-anchor scan, so retired claims cannot evade FAIL by
  inserting narration between key words.
- **Mode**: full (7-stage pipeline).
- **Stages traversed**:
  1. Requirement Analyst — 2026-05-22 — READY
  2. Solution Architect — 2026-05-22 / 23 — 4 revisions (rev 1 → rev 4 final)
  3. Gate Reviewer — 2026-05-22 / 23 — 4 passes (3 CHANGES REQUIRED → APPROVED FOR DEVELOPMENT)
  4. Developer — 2026-05-23 — BLOCKED ON DESIGN once (entry #10) → resumed → CR rollback once (40-locations.md:25)
  5. Code Reviewer — 2026-05-23 — CHANGES REQUIRED → APPROVED FOR QA (conditional realized)
  6. QA Tester — 2026-05-23 — APPROVED FOR DELIVERY (adversarial AC walk-through)
  7. Delivery (this doc) — 2026-05-23

- **Rollbacks**: 4 total
  - Stage 2 (Solution Architect): 3 — F-1/F-2 from gate pass 1; F-4 (false `v0.2`
    claim) from gate pass 2; entry #10 README false-positive from Developer
  - Stage 4 (Developer): 1 — `.harness/rules/40-locations.md:25` missed stamp from
    Code Review
- **Final `verify_all` result**: **PASS 30 / WARN 0 / FAIL 0** in BOTH shells. I.6 = PASS.
  Cross-shell parity confirmed. Test pair: `test-verify-i6.sh` 34/0, `test-verify-i6.ps1` 35/0.

## Baseline changes

| Metric | Before | After |
|---|---|---|
| verify_all checks | 30 | 30 (unchanged — no new check, matcher upgraded in place) |
| test_init_ps_assertions | 227 | 227 |
| test_supervisor_ps_assertions | 57 | 57 |
| test_verify_i6_ps_assertions | — | 35 (new) |
| test_verify_i6_bash_assertions | — | 34 (new) |
| `last_verify` | 2026-05-19 | 2026-05-23 |
| Plugin version | 0.17.4 | 0.18.0 |

## Outstanding risks

None functional. Non-blocking observations from Code Review / QA (acceptable per
design + threat model):

- **PS structural-lockstep is field-by-field weaker than bash** (test-verify-i6.ps1
  asserts entry count + entry #10 only; bash side does verbatim line-compare). Bash
  side covers it correctly; cross-shell parity backstops behavioral divergence. Worth
  tightening in a future minor task.
- **AC-8 has no permanent corpus fixture** (CHANGELOG / `_archived/` exemption); QA
  closed the gap with an inline injection probe (banned phrase written into both,
  verify_all stayed PASS, then reverted). Worth adding a permanent fixture next time
  test-verify-i6 is touched.
- **Entry #10 `.claude/` exclude has a designed-in bypass**: a sentence claiming
  `.harness/ → CLAUDE.md` that ALSO mentions `.claude/` elsewhere would be suppressed.
  Same shape as #2/#4 with negation words. Threat model is *accidental drift* (insight
  L18), not a determined adversary; trade explicit in design §3.2.
- **Process: 3 design rollbacks** — root cause: architect's "§6 verified" claims were
  per-family hand-reasoning, not actual matcher runs. The developer's `verify_all`
  pass over the whole tree is the canonical exhaustive scan; rely on it from the
  design stage onward. Captured as an insight below.

## Files changed (git diff --stat)

```
 .claude-plugin/marketplace.json |   2 +-
 .claude-plugin/plugin.json      |   2 +-
 .harness/insight-index.md       |   2 +
 .harness/rules/40-locations.md  |   4 +-
 AI-GUIDE.md                     |   5 +-
 CHANGELOG.md                    |  25 +++++
 README.md                       |   5 +-
 README.zh-CN.md                 |   5 +-
 docs/dev-map.md                 |   7 +-
 docs/tasks.md                   |   2 +-
 scripts/baseline.json           |   6 +-
 scripts/verify_all.ps1          |  95 +++++++++++++++++--------
 scripts/verify_all.sh           | 102 +++++++++++++++++++++++-----
 13 files changed, 191 insertions(+), 71 deletions(-)
```

Plus two NEW files: `scripts/test-verify-i6.sh`, `scripts/test-verify-i6.ps1`.
Plus seven stage-doc files under `docs/features/i6-semantic-guard/` (will be moved
to `_archived/` by `scripts/archive-task` after this delivery).

## Next steps for user

None required. The v0.18.0 is committed; `verify_all` PASSes 30/30 in both shells;
the new regression pair protects the matcher's behavior. The `40-locations.md`
double-stamp pattern (line 25 + line 43, both needing a version bump) suggests a
future task could add a check-count freshness-stamp guard to verify_all itself, but
that is well outside this task's scope.

## Insight

(Harvested into `.harness/insight-index.md` — final one-line forms at index lines 28-29.)

- 2026-05-23 · A pattern-matching guard's per-entry false-positive analysis must be backed by an actual matcher run over the live tree, not per-family hand-reasoning — in T-004 three "§6 zero hits" design claims were falsified by `verify_all` runs (00-core.md.tmpl:7; concepts.md:104 v0.2-on-wrong-line; READMEs entry-#10). Rely on `verify_all` as the canonical exhaustive scan from the design stage onward. · evidence: T-004 design rollbacks 1-3
- 2026-05-23 · When an L13-style insight is captured, sweep ALL sibling scripts for the same pattern at the time of recording. L13 fixed `sync-self.sh` + `harness-sync.sh` but missed `archive-task.sh` — the identical `declare -a` under `set -u` bug bit T-004 delivery 3 years later. · evidence: T-004 delivery flow, archive-task.sh:45/64/72

---

## Delivery-stage addendum (2026-05-23)

During `scripts/archive-task.sh --task i6-semantic-guard`, the script exited 1 on
an unbound `rotated` variable. The move + harvest had already completed before the
crash, so the archive itself is intact — but the crash surfaced a **pre-existing
latent bug** in `archive-task.{sh,ps1}` (a direct recurrence of insight L13's
`declare -a foo` under `set -u` pattern). Affected lines in the bash side:
`harvested`/`current`/`rotated`/`remaining`. The PowerShell twin already used
`@()` correctly and was unaffected.

**PM-authorized in-flight scope addition**: fixed the bug in both
`skills/harness-init/templates/common/scripts/archive-task.sh` and the
`sync-self`-mirrored `scripts/archive-task.sh` (all four arrays now `=()` with a
referencing comment back to L13). Verified: `sync-self` reports parity, and
`verify_all.{ps1,sh}` still PASS 30/0/0 in both shells. The first harvested
insight was truncated by my multi-line authoring; both insights are now
correctly one-line at `.harness/insight-index.md:28-29`.

This addendum is the final delivery state.
