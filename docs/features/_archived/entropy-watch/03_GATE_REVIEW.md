# 03 — Gate Review · T-11a entropy-watch (RE-REVIEW round 2 — APPROVED)

> Stage 3 (Gate Reviewer). Mode: full. deferred-human: defer. Persisted by PM (gate-reviewer read-only).
> Round 1 = BLOCKED ON DESIGN (F-1 supervisor I.3 cap; F-2 F.1 hardcoded allowlist; coherence Hard-rule #1). SA reworked. This round verifies the 3 deltas + checks regression. Live files re-read, line numbers re-MEASURED.

## Audit (8 dims) — all PASS. Round-1 Risk-coverage WARN cleared (Risk#4 reworded: F.1 checks PRESENCE not drift; parity rests on NFR-3).

## Fix verification
### F-1 (supervisor I.3 ≤300) — RESOLVED ✓
Lens DETAIL relocated to NEW `skills/harness-deflate/references/entropy-scan.md` (EP grammar, deletion test, findings schema, Entropy-verdict spec); supervisor keeps a ~22-line concise stub + pointer. Re-measured LIVE supervisor.md = **257**; +22 stub +6 Hard-rule-exception = **285 ≤ 300** (~15 headroom). I.3 globs `agents/*.md` ONLY (verify_all.ps1 L382) → a `skills/**/references/*.md` is categorically out of agent-cap scope (design correct). harness-deflate/ confirmed not-yet-on-disk (genuinely new).

### F-2 (F.1 hardcoded allowlist) — RESOLVED ✓
Explicit ledger rows 40-42 + line numbers re-verified live: ps1 L270 array `+ "entropy-cadence"`; ps1 L269 label string `+ , entropy-cadence`; sh L284 array `+ entropy-cadence`. SH F.1 label (L288) is generic ("Script pairs present") → correctly NOT edited (asymmetry right). False "F.1 auto-extends" prose retracted in §2 / §Confirmations / §Verdict. Count stays 32 (array/label edit ≠ new check).

### Coherence (Hard-rule #1) — RESOLVED ✓
Hard-rule #1 (live L22, forbids reading prod source) gains an in-place "Exception — entropy mode only" clause: widens READ scope only, re-states no Edit/Bash/PowerShell/Task, one write, never refactor/dispatch, AP-* keeps narrow whitelist. Frontmatter unchanged (`Read, Write, Glob, Grep` L4) — consistent. "## What bad looks like" reading-prod bullet (live L254) qualified to match.

## Regression — none
16→17 fan-out rows 1-39 UNCHANGED + still line-exact; decoys intact; live skill count re-confirmed 16 (correct baseline). Observer boundary held; non-blocking 32 checks / 8 agents; version 0.41.0 ×4 + CHANGELOG [0.41.0]; harness-deflate skill rule-15-compliant. No previously-approved item regressed; no new finding.

## Pre-answered dev Qs
1. SH F.1 label NOT edited (generic); only PS label (L269) + both arrays (ps1 L270 / sh L284). 2. Stub goes between supervisor `## Anti-pattern catalog` and `## Report schema` (live L132↔L133). 3. F.1 array growth trips no new-check gate (count 32). 4. references/entropy-scan.md never in I.3 scope. 5. No code edit without a user pick (skill excludes Edit/Bash; execute = gated /harness-goal dispatch on explicit pick, AC-9).

## Verdict
**APPROVED FOR DEVELOPMENT.** All 3 round-1 blockers resolved + independently re-verified live (supervisor 285≤300, F.1 3 edits line-exact, Hard-rule exception coherent); zero regression. No remaining FAIL/WARN.
