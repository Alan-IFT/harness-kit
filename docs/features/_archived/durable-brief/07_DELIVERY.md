# Delivery Summary — durable-brief (T-05)

- **Task:** T-05 / `durable-brief` — fold the agent-brief durability discipline (behavioral not procedural, no forward-looking file paths/line numbers, complete testable acceptance criteria, explicit out-of-scope, durable across refactors) into the requirement-analyst hard rules + the pm-orchestrator dispatch contract, WITHOUT touching the insight-index evidence citations.
- **Mode:** full (7 stages) · **Depends on:** — (independent)
- **Stages traversed:** 1 RA → 2 SA → 3 Gate → 4 Dev → 5 CR → 6 QA → 7 Delivery (all this run)
- **Rollbacks:** 0
- **Final verify_all result:** **PASS 32/0/0 (Bash, ×3 stable)**, I.3 caps + I.6 + G.3 + G.4 PASS, check count unchanged at 32. verify_all.ps1 operator-pending (PS denied; verify_all unedited this task; G.3/G.4 shell-symmetric → green-by-symmetry).
- **Version:** 0.35.0 → **0.36.0** (minor; shipped-agent content change). NO count flip (16 skills / 8 framework agents / 32 checks all held).
- **Baseline changes:** none (doc-only; `last_verify` stamped 2026-06-20).

## Files changed (7)
- `agents/requirement-analyst.md` (77 lines) — Hard rule 6 (behavioral-not-procedural + no forward-looking file:line in the spec + single-sourced EVIDENCE-exemption clause naming `05-insight-index.md` + stage-doc evidence as exempt) + 1 good + 1 bad exemplar.
- `agents/pm-orchestrator.md` (208 lines) — one dispatch-contract line referencing requirement-analyst Hard rule 6 (no restated boundary).
- `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `README.md`, `README.zh-CN.md` (version → 0.36.0); `CHANGELOG.md` (`[0.36.0]` entry stating counts unchanged).

## Quality trail
- Gate (03): APPROVED FOR DEVELOPMENT — 8/8 dimensions PASS; boundary verified non-contradictory with the evidence convention; I.6 14-entry list inspected clean; conditions C-1/C-2.
- Code Review (05): APPROVED WITH NOTES — 0 CRIT/MAJOR/MINOR, 2 NIT (style); 9 ACs + design verbatim; C-1/C-2 hold; single-sourced boundary.
- QA (06): APPROVED FOR DELIVERY — 0 defects; regex-scan confirmed no literal `name.ext:NNN` token in any new surface; boundary coherence with the insight-index convention proven; additive; no count flip.

## Outstanding risks / Next steps for user
- Operator-pending: `verify_all.ps1` on a Windows shell → confirm 32/32 (PS denied to this runtime; verify_all unedited this task, agents are markdown scanned identically by both shells → green-by-symmetry, unconfirmed on PS). No regression.

## Insight

- 2026-06-20 · A "briefs must be behavioral — no file paths or line numbers" durability rule has to be scoped FORWARD-only (the requirement/spec the pipeline builds FROM) and must explicitly EXEMPT backward-looking EVIDENCE citations — this repo's insight-index and stage-doc evidence sections legitimately cite path-and-line as proof, so a blanket ban would contradict the evidence convention in `05-insight-index.md`. Single-source the forward/backward boundary in ONE agent (requirement-analyst) and have others (pm-orchestrator) reference it, never restate it, so the nuance cannot drift across two places. · evidence: T-05, requirement-analyst Hard rule 6 + pm-orchestrator dispatch line
