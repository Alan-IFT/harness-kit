# 03 — Gate Review · T-11c entropy-watch-persist

> Stage 3 (Gate Reviewer). Mode: full (final slice). deferred-human: defer. Persisted by PM (gate-reviewer read-only).
> Upstream: 01 READY · 02 READY. Verify-don't-trust; live files read.

## Audit (8 dims) — all PASS. No FAIL, no blocking WARN.

## Six PM-directed checks — all CONFIRMED
1. **Scope-down correct.** references/entropy-scan.md L51 Determinism/NFR-6: finding list identical across runs over unchanged tree = pure fn of current structure → OPEN re-surfaces, FIXED stops surfacing, NO store needed. Design adds NO findings-store file (only decline-filter); declined-store concept recorded as its own `## entropy-findings-store` rejected-decisions entry.
2. **Key rule safe.** Key = normalized `Where (file/module)` handle (NOT per-run EP-NNN); EXACT string equality after normalize (trim, \→/, strip ./ + trailing /, no case-fold, no dir-coarsen) — explicitly NOT substring/prefix (no sibling over-suppression). Defined ONCE in scan ref; supervisor + SKILL only point at it (DRY).
3. **Decline path correct.** /harness-deflate step-4 appends a T-09-format `## <handle>` record (Decision: declined + Why + Origin "entropy sweep <ISO-date> · EP-<class>"); de-dups by handle (existing → append origin, not 2nd record); creates-from-seed if absent; NO /harness-goal dispatch (memory-write only); NO new Edit/Bash tool (allowed-tools stays Read/Glob/Grep/Task — the append is the main-agent decide-point habit per 25-decision-policy).
4. **Fail-open.** Missing/unreadable rejected-decisions.md → filter no-op, all findings surface, never wedges. Mirrors live entropy-cadence.sh fail-open.
5. **I.6 (R-5).** rejected-decisions.md is NOT exempt (verify_all.sh L547-560) → IS scanned. All 14 banned anchors (L521-536, CLAUDE.md-composition + 全程中文) checked vs the new decline records + scan section + SKILL prose → none introduced.
6. **No regression.** All live at 0.42.0 → bump 0.43.0 ×4 stamps + CHANGELOG [0.43.0]. No count flip (17/8/32/90/314). No new check. supervisor 281→~283 ≤300. No new file (3 behavioral edits + 5 stamps).

## Findings — no FAIL; 3 non-blocking NOTES (design already handles)
1. DRY is review-enforced, not gated (no check fails if SKILL/supervisor restate the rule) — design says "point, don't restate" in 3 places; honor it.
2. The filter matches both `declined` AND `deferred` records — intended T-09 reuse; the existing `## design-it-twice` (deferred) matches no module path so it's inert; known property, not a surprise.
3. The append is performed by the MAIN agent (skill has no Edit/Write); SKILL.md states the record-shape CONTRACT, must not imply the skill itself edits — do NOT add an Edit tool / writing sub-agent.

## Pre-answered dev Qs
1. `## Decline filter` section goes after `## Entropy findings artifact`, before `## Determinism + caps` (scan ref). 2. A dropped finding doesn't count toward FINDINGS-PRESENT / doesn't appear in Findings or Detail; all dropped → CLEAN. 3. Origin = `entropy sweep <ISO-date> · EP-<class>` (class word, not EP-NNN). 4. Also write the `## entropy-findings-store` decline record (de-dup-checked; none exists today). 5. Internal `decline-filter: N suppressed` methodology-note line is IN scope; a user-facing "N hidden" count is OOS.

## Verdict
**APPROVED FOR DEVELOPMENT.** Scope-down correct (no store), exact-match key single-sourced, T-09-format dispatch-free decline path, fail-open, I.6-clean, 0.43.0 no-count-flip/no-new-check/no-new-file/≤300. 3 non-blocking notes the design already addresses.
