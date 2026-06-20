# 05 — Code Review · T-03 harness-grill

> Stage 5 (Code Reviewer). Mode: **full**. deferred-human: defer. Read-only audit; persisted by PM.
> Upstream: 01 READY · 02 READY · 03 APPROVED (C1-C4) · 04 READY FOR REVIEW. Every claim verified against the LIVE repo.

## Findings
- **BLOCKER / MAJOR / MINOR:** none.
- **NIT [MAINT]:** `install.sh:139` / `install.ps1:141` — soft "Use in Claude Code:" help-text grill line added (parity restored), but the block stays a manually-maintained per-skill enumeration that will drift on the next skill. SA-flagged §11 optional surface, ungated. Not actionable for this task.

## Requirement coverage (AC-1…AC-12) — all ✅ (AC-6/AC-8/AC-11 carry [operator-run] PS confirmation)
- AC-1 SKILL.md frontmatter `name:`+bilingual model-facing `description:` w/ when-NOT delta vs /harness,/harness-plan,/harness-explore (`:1-18`).
- AC-2 interview engine: one-at-a-time wait, recommended answer/question, explore-to-self-answer, CONTEXT.md SOFT (graceful absent), emit brief → `docs/features/<slug>/INPUT.md` (`:55-107`).
- AC-3 When-NOT + Anti-patterns naming multi-question + ask-what-codebase-answers (`:36-46`, `:116-126`).
- AC-4 user-invoked, pre-pipeline, no stage/pm-orchestrator change; `allowed-tools` excludes Task (cannot dispatch).
- AC-5 standing recommended-answer rule (`:23`) + Hard-rule-1 strip-ban scoped to PROSE w/ explicit Exception (`:28`) — coherent, no contradiction.
- AC-6 version 0.35.0 ×4 stamps. AC-7 both READMEs list /harness-grill + 16; CHANGELOG `[0.35.0]` w/ literal harness-grill.
- AC-8 verify_all C.1/G.1/G.2 arrays carry harness-grill + labels read 16, both shells. AC-9 every ungated count surface → 16 + grill entry; decoys untouched.
- AC-10 AI-GUIDE 111 lines (≤200); Workflow triggers match SKILL description. AC-11 bash 32/0/0 + test-init 273 + integration 90; PS operator-to-run (not faked). AC-12 green tree, no commit.

## Design fidelity — all ✅
SKILL §1-8 body map, interview invariants (not a rigid script — no railroading), §4 strip-list reconcile both edits, §6.1-6.3 fan-out (arrays NOT directory-derived → arrays+labels both edited, the RA item-26 correction honored), no new check (count 32, G.4 dynamic), no helper script, no test-init/baseline change, template AI-GUIDE.md.tmpl untouched (Q1), README "six task shapes"→"plus a pre-pipeline aligner" (C2). Dev "no drift" independently confirmed.

## Strip-list self-contradiction check (explicit)
`:28` bans lowercase hedge "suggest"/"recommend" in requirement STATEMENTS, with explicit Exception for the labelled `Recommended:` field; `:23` requires the labelled `Recommended:` answer. Not both required+forbidden — ban scoped to hedging prose, labelled field exempt. No contradiction. §8 edit matched verbatim live string (C3). File 75 lines (≤300). ✅

## Decoy / DO-NOT-TOUCH confirmation (reverse check) — all untouched
insight-index.md:35 (C1) · proposals/plugin-native-redesign.html:65/136 (C1) · CHANGELOG:74/85/95/109/127 (history, I.6-exempt) · tasks.md:15/16/28/30 (append-only delivery rows) · README.zh-CN.md:276-279 (historical table) · harness-status:135 ("14 required assets" health denominator) · all 32/(32 checks)/32%2F32 tokens · 308/90 test badges · baseline.json · templates/common/AI-GUIDE.md.tmpl. No decoy wrongly flipped; no live surface missed.

## verify_all symmetry (F.1)
3 array sites + 3 labels per shell, both edited: C.1 sh:56/59 ps:69/68 · G.1 sh:329/332 ps:301/299 · G.2 sh:345/348 ps:327/325. install help-text sh:139 / ps:141 symmetric. No one-shell-only edit.

## Verdict
**APPROVED** — 0 BLOCKER/MAJOR/MINOR, 1 NIT. Faithful to requirement + design, clears C1-C4; the #1-risk 15→16 fan-out is complete and correct in both directions; both shells symmetric; version 0.35.0 w/ matching CHANGELOG heading; check count 32; AI-GUIDE 111; RA coherent at 75 lines; no I.6 anchor introduced. Remaining: [operator-run] PowerShell verify_all twin (PS-denied to sub-agents; dev did not fabricate). Code is structurally correct for a 32/0/0 PS PASS. Proceed to Stage 6 (QA).
