# 05 — Code Review · T-11a entropy-watch

> Stage 5 (Code Reviewer). Mode: full. deferred-human: defer. Read-only; persisted by PM.
> Two-axis lens (T-08): Axis A Standards-conformance / Axis B Spec-design-fidelity — per-axis status so neither masks the other.
> Scope: T-11a's ~20 files (excl. docs/batches/default/* + docs/tasks.md = stream bookkeeping). Upstream 01/02(r2)/03(r2 APPROVED)/04.

## Findings
- CRITICAL / MAJOR: none.
- MINOR [MAINT]: harness-deflate SKILL frontmatter `description` when-NOT delta names supervise/goal/harness but NOT /harness-plan (that row is in the body "When NOT to invoke" table); dev record overstated. Non-blocking (three-way delta disambiguates the most-confusable siblings).
- NIT: independent timestamp impls in the cadence pair (informational field, not parsed); README version-history table has no 0.41.0 row (correct — frozen decoy region).

## Requirement coverage (T-11a-owned AC) — all ✅
AC-1 scan grammar+determinism (references/entropy-scan.md); AC-2 observer read-only (tools unchanged, Hard-rule #2 + entropy exception widens READ only); AC-3 shared due-check single-source (N=5 once/shell, both stream + future /harness call by name); AC-4 stream surface (DUE→append, NOT-DUE→no scan); AC-6 non-blocking + fail-open exit 0 + count stays 32; AC-7 cadence semantics (≥N inclusive, delivered +1, swept reset+stamp, bump only on DELIVERED); AC-8 state gitignored + malformed→0; AC-9 authorize→execute (allowed-tools no Edit/Bash, explicit-pick gate, separate /harness-goal dispatch); AC-11 fan-out + F.1 rows applied; AC-12 verify_all.sh 32/0/0 (PS operator-pending). AC-5/AC-10 = T-11b/c (out of scope).

## Design fidelity (vs 02 r2) — all ✅
Supervisor stub+pointer, DETAIL in references/ (single-source); 279 ≤300; frontmatter unchanged; Hard-rule #1 in-place scoped exception; bad-bullet qualified; observer boundary held. entropy-cadence: identical CLI/threshold/fail-open/stdout both shells, .git-walk root, raw-byte UTF-8 write, set -u guards. harness-deflate rule-15 delegator (Read/Glob/Grep/Task, no Edit/Bash). Stream additive (Stop-condition precedence unchanged). F.1 3-edit add (ps1 array+label, sh array; sh label generic untouched). 0.41.0 ×4 + CHANGELOG [0.41.0]. No new check (32), agents 8.

## Standards spot-checks (Axis A) — all ✅
I.3 279≤300 (references file out of agent-cap scope); cross-shell parity; .git-walk root (insight 2026-06-04); raw-byte UTF-8 emit (insight 2026-06-12); set -u hygiene; decoys frozen (harness-status "14 assets", "8 agents", "32 checks", "test--init-314", historical CHANGELOG/README version-history, insight-index); all live 16→17 surfaces flipped both shells; no orphaned "16".

## Per-axis status
- **Axis A — Standards-conformance: CLEAN** (0 CRIT/MAJOR/MINOR).
- **Axis B — Spec-design-fidelity: CLEAN** (1 MINOR description-delta scope, 2 NIT; 0 CRIT/MAJOR).

## Verdict
**APPROVED WITH NOTES** — both axes clean; supervisor 279≤300; 0 CRIT/MAJOR, 1 MINOR (non-blocking), 2 NIT. Proceed to QA. PS twin (verify_all.ps1 + entropy-cadence.ps1) operator-pending (PS deny).
