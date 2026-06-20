# 05 — Code Review · T-09 rejected-decisions-memory

> Stage 5 (Code Reviewer). Mode: full. deferred-human: defer. Read-only; persisted by PM.
> Reviewed under TWO separate lenses (Standards-conformance / Spec-fidelity — the lens installed in T-08) so neither masks the other.
> Scope: T-09's attributable edits only (co-mingled T-02…T-08 churn excluded). Upstream 01/02/03 READY/APPROVED (C1-C3).

## Findings
- CRITICAL / MAJOR / MINOR: none.
- NIT [STYLE]: dogfood header is 8 soft-wrapped lines but 6 substance items (design §3.1 licenses this). NIT [MAINT]: 3 grouped skill-family records vs 9 one-liners (design §3.1 token-economy choice). Both pre-licensed; not defects.

## Requirement coverage (AC-1…AC-11) — all ✅
Dogfood exists w/ ≤6-substance header (no gate) + 9 records (1 deferred + 8 declined, 4 fields each); generic placeholder-free seed ≠ dogfood, not in sync-self; AI-GUIDE 4th memory line (111≤200); dev-map row; read/append single-sourced in 25-decision-policy (107 lines) + RA/SA pointer-only; no new check (32); telemetry not duplicated (15-skill-authoring = pure pointer, AC-8); verify_all.sh 32/0/0; I.6 both new files in scope + clean; version 0.39.0→0.40.0, no count claim changed.

## Design fidelity (§3.1-§3.7/§5/§6) — PASS, zero drift
All items matched verbatim (whitespace only): dogfood structure, generic seed, canonical rule-25 bullet, RA/SA pure pointers, rule-15 telemetry→pointer, AI-GUIDE bullet, dev-map row + tree line (32-checks strings untouched), 4 version stamps + CHANGELOG [0.40.0], symmetric test-init assertion (sh:141/ps1:173), baseline test_init_bash 273→276 from captured run (ps 308 + READMEs left for PM).

## Gate conditions (C1-C3, F-1/F-2/F-3) — all ✅
C1/F-1: NO count edit; the three "15 skills" in CHANGELOG are immutable OLD-version history (lines 186+), not T-09; [0.40.0] restates 16/8/32. C2/F-2: only test_init_bash_no_python3_assertions→276 (captured); ps field 308 + both README test--init badges left for PM; no "311" hand-typed. C3: verify_all.sh 32/0/0 both new files in I.6 scope; test-init.sh 276; PS twins deferred. F-3: rule-15 line is a pure pointer (one reason, in the file).

## Per-axis status
- **Standards-conformance:** PASS (AI-GUIDE 111 / rule25 107 / rule15 113 ≤200; agents ≤300; I.6 clean vs 14 anchors; no new check/placeholder; seed plain .md no {{}}; not in sync-self; G.3 4-stamp consistent 0.40.0; G.4 [0.40.0]; F.1 symmetric assertion; baseline captured not hand-typed; no count token mutated).
- **Spec-fidelity:** PASS (11/11 ACs; §3.1-§3.7/§5/§6 verbatim; C1-C3 + F-1/F-2/F-3 honored; zero drift; only 2 design-licensed NITs).

## Verdict
**APPROVED WITH NOTES** — both axes clean (neither masks the other); 0 CRIT/MAJOR/MINOR, 2 NIT (design-licensed). Outstanding (PM, not defects): PS twins (test-init.ps1→reconcile ps field + README badges; verify_all.ps1→32/0/0) + reconcile co-mingled non-T-09 churn at commit. No route-back.
