# 03 — Gate Review · T-05 durable-brief

> Stage 3 (Gate Reviewer). Mode: full. deferred-human: defer. Persisted by PM (gate-reviewer read-only).
> Upstream: 01 READY (8 behaviors/9 AC/4 OQ) · 02 READY. Every claim verified against live source.

## Audit checklist (8 dimensions) — all PASS
Requirement completeness · Design completeness · Reuse correctness · Risk coverage · Migration safety · Boundary handling · Test feasibility · Out-of-scope clarity — PASS. No WARN, no FAIL.

## Six dispatch checks — all CONFIRMED
1. **Forward/backward boundary coherent + single-sourced.** RA Hard rule 6 bans path/line ONLY in forward-looking requirement prose; explicit exemption keeps backward-looking EVIDENCE citing path-and-line "exactly as 05-insight-index.md requires." Does NOT contradict 05-insight-index.md (read in full; it requires `evidence:` file:line, e.g. existing `verify_all.ps1:439` in insight-index). Nuance lives ONLY in RA; PM line points at "Hard rule 6", no restated clause → no two-place drift.
2. **insight-index protected.** `.harness/rules/05-insight-index.md` + `.harness/insight-index.md` NOT in edit set (AC-6 makes byte-unchanged verifiable).
3. **I.6 self-trip clean.** Read live banned list (verify_all.ps1:486-501, 14 entries) + matcher; agents/*.md ARE scanned. None of the 14 CLAUDE.md-composition / scaffolding-only / CJK anchors overlaps the designed tokens. Design writes path/line as PROSE CONCEPT, never a literal `name.ext:NNN` token (bad-exemplar uses plain prose). 07 insight carries the same obligation → condition C-1.
3b. **No I.6 list change.** No banned/exempt entry added; 4-file lockstep + I6ExpectedEntryCount intact (stays 14).
4. **Caps.** RA 75→~79, pm-orchestrator 207→~209; both ≤300 (I.3).
5. **Version + no count flip.** All 4 G.3 stamps currently 0.35.0 (plugin.json:4, marketplace.json:17, README.md:5, README.zh-CN.md:5) → bump to 0.36.0 together; CHANGELOG prepend `## [0.36.0]` (G.4). README count claims are on line 7 (NOT the line-5 badge) → no collision. G.4 count-claim files not edited; live check count stays 32 (no new check). G.2 stays green (existing [0.35.0] entry names all 16, not removed). CHANGELOG body stating 32/16/8 is additive prose in an I.6-exempt file — harmless, just match live values.
6. **Agents edited directly** (plugin-native top-level `agents/`, no sync/template copy; AI-GUIDE:13, v0.30 cutover). No dev-* partition agents (single-Developer mode).

## Pre-answered developer questions
1. RA Hard rule 6 after rule 5 (line 32); good entry after line 66; bad entry after line 72 (all headings exist).
2. PM one-liner in "Cross-task memory" after the insight-surfacing paragraph (after line 57, before "Mid-task intervention" line 59); APPEND, keep lines 51-57 byte-present (AC-5).
3. Write path/line as PROSE; never a literal `name.ext:NNN` token in any scanned file (both agents + the 07 insight).
4. Touch NO count claim; bump only the 4 version stamps + CHANGELOG [0.36.0]. Content edit, not count flip (insight 2026-06-19 decoy set).
5. CHANGELOG body's "32 checks"/"16 skills" is additive prose stating UNCHANGED counts (CHANGELOG is G.4-non-target + I.6-exempt) — just match live 32/16/8.

## Verdict
**APPROVED FOR DEVELOPMENT** — carry-forward conditions:
- **C-1 (I.6 hygiene at delivery):** the 07 insight, if written, MUST phrase path/line as prose and MUST NOT quote a literal `name.ext:NNN` banned-anchor sequence (T-013 self-trip class). Both agent edits already satisfy this; the obligation extends to delivery.
- **C-2 (additive-only + gate):** final `git diff` shows additions only in both agent files (AC-9); `verify_all` reports 32/32 with all four G.3 stamps + CHANGELOG `[0.36.0]` at/naming 0.36.0 before done (AC-7/AC-8; PS run operator-pending per deny rule).

No finding routes back to RA or SA.
