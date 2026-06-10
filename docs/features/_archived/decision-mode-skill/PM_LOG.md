# PM_LOG — T-018 decision-mode-skill

> Task: ship a 15th skill `/harness-decision-mode` + add Mode 3 (user-custom rubric) to the decision policy, and ship the policy mechanism (generic) to generated projects. Real shipped feature + version release v0.27.0 → v0.28.0.
> Mode: full (7-stage). PM = orchestrator (router only).

## Task-start checks (2026-06-10)

- `.harness/intervention.md` — ABSENT at task start (no pending intervention).
- `.harness/insight-index.md` — read. Applicable entries surfaced to downstream:
  - L24 (2026-06-05) · adding a verify_all check / count claim is version-worthy; G.4 enforces claim↔plugin.json consistency. → SA/Dev: count/version surfaces.
  - L26 (2026-06-06) · whole-file substring claim checks need file-UNIQUE expect literals. → relevant if test-init/verify_all assertions added.
  - L30 (2026-06-08, T-013) · I.6 banned/exempt list is a FOUR-file lockstep + I6ExpectedEntryCount. → only if a retired claim is added (likely N/A here — net-new feature, no claim retired).
  - L31 (2026-06-08) · CJK I.6 anchors are cross-shell-safe but a scanned doc must not write the literal banned sequence (self-trip). → archive-stage caution.
  - Skill-add precedent: T-014 `/harness-language` (v0.25.0) is the canonical "how a skill was added" — full release fan-out (plugin.json, marketplace.json, README + README.zh-CN badges/lists, CHANGELOG, install.{ps1,sh}, AI-GUIDE workflow table, dev-map, test-init/baseline). T-006 harness-batch caught skill-count drift (M-1).
- `docs/tasks.md` — read. Related historical: T-013 (lang-policy-split), T-014 (harness-language-skill, BEST skill-add precedent), T-016 (design-out-root-cause). New entry T-018 added with `mode: full`.
- `docs/dev-map.md` — read (skill layout, two consistency layers, release surfaces).

## Routing plan

Full pipeline 1→2→3→4→5→6→7. Stage 4 dispatch: detect partition agents first (`.harness/agents/dev-*.md`).

HARD CONSTRAINTS carried into every dispatch:
1. NO git commit/push/tag — leave green tree (operator commits; red-line #2 of the shipped policy).
2. Shipped rubric = GENERIC defaults, never operator personal prefs (those stay in dogfood Preset).
3. Symmetry: every .ps1 edit needs its .sh twin.
4. Self-consistency rule 10: template RULE is bespoke (not in sync-self mirror set) → no sync-self; SKILL must reach `.claude/` via harness-sync if applicable. Skill is a top-level PLUGIN skill, not a template skill.
5. Doc-size caps (rule 70) on every new doc.
6. Sub-agents have NO Bash → verify gate is operator-run. Agents surface BLOCKED-ON-CAPABILITY rather than fabricate run results.

## Dispatch mechanism note (2026-06-10)

The `Task` sub-agent tool is unavailable in this run (PM is itself executing inside a sub-agent context; `Task is not available inside subagents`). Per AI-GUIDE.md line 50 + line 57, fall back to **manual one-role-at-a-time** role-play: PM produces each stage doc in pipeline order, strictly honoring the separation of concerns (a stage may not edit an upstream doc; a defect routes back to the upstream author as a rollback recorded here). Same rigor, single context.

## Stage transitions

### Stage 1 — Requirement Analyst → 01_REQUIREMENT_ANALYSIS.md (2026-06-10)
Verdict: **READY** (with 4 safe in-scope defaults). 14 in-scope ACs, full A/B/C/D coverage, exhaustive
release fan-out enumerated. Key correctness boundary flagged: AC-4 (shipped Preset must be GENERIC — banned
operator-personal phrase list). OQ-1 (install array gap), OQ-2 (zh defer), OQ-3 (non-empty custom),
OQ-4 (no-policy old project) — all with defaults; OQ-5 routed to SA (mechanical).

PM routing decision: **ADVANCE to Stage 2.** No open question blocks design; each default is reversible +
in-scope + respects the HARD CONSTRAINTS (esp. scope red-line #3 + generic-rubric #2). This is a legitimate
Mode-2 autonomous call (the policy this very task ships) — recorded here for review-after; OQ-1/OQ-2 to be
surfaced at delivery so the operator can reverse if desired.
- Intervention check before Stage 2: `.harness/intervention.md` ABSENT.

### Stage 2 — Solution Architect → 02_SOLUTION_DESIGN.md (2026-06-10)
Verdict: **READY for Gate Review.** Key design calls:
- OQ-5 RESOLVED mechanically: `.claude/skills/` + `.harness/skills/` both EMPTY in dogfood → plugin skills
  live only under top-level `skills/`; new skill needs NO `.claude/` copy, NO sync. (E.2 unaffected.)
- NO helper script (skill edits via `Edit` directly — single-line + section append; rule 15 P6 anti-bloat).
- NO new verify_all check → count stays 32 → G.4 unaffected by anything but the version bump. Skill count
  (14→15) gated by C.1/G.1/G.2 label+loop only (NOT G.4, which tracks the CHECK count 32).
- §4.2 generic template Preset authored FRESH with an explicit AC-4 banned-phrase list (R1 = #1 risk).
- §7 exhaustive 20-row fan-out ledger; §6 test-init adds 2 presence assertions, baseline reconcile is
  [operator-run] (no fabrication, insight L23).
PM routing decision: **ADVANCE to Stage 3 (Gate Review).** Design is implementable without further decisions.
- Intervention check before Stage 3: `.harness/intervention.md` ABSENT.

### Stage 3 — Gate Reviewer → 03_GATE_REVIEW.md (2026-06-10) [round 1]
Verdict: **BLOCKED ON DESIGN.** Gate's independent live-tree grep caught:
- **F-1 (BLOCKING):** §7 fan-out ledger OMITS `docs/getting-started.md:36` ("fourteen skills" + a 3-group
  skill enumeration). This is the exact recurring fan-out-incompleteness class (L5/L24; T-008 F-1/F-2/F-5;
  T-006 M-1). T-014 — the SA's own cited template — DID fan it out; T-018's ledger dropped it. Ungated by
  verify_all → un-catchable downstream → guaranteed stale `fourteen` ships. Routes to SA.
- F-2 (advisory): §7 row 16 under-specifies manual-e2e-test.md's `fourteen` sites (`:7`,`:60` missing).
- F-3 (INFO, no action): G.4=CHECK count (32, untouched) correctly excluded; don't flip the 32 tokens.
7/8 dimensions PASS; only design-completeness (dim 2) FAILs. Fast fix expected.

PM routing decision: **ROLLBACK #1 (design stage) → solution-architect.** Per rollback rule "Gate finds
design gap → solution-architect" (only the design author may edit the design). This is the 1st consecutive
rollback at the design stage (limit: 3 → then stop+ask).
- Intervention check before rollback: `.harness/intervention.md` ABSENT.

### Stage 2 (round 2) — Solution Architect amends 02_SOLUTION_DESIGN.md (2026-06-10)
Amendment 1 added: rows 21/22 (`getting-started.md` count flip + new Operations bullet), row 16 clarified
(manual-e2e-test `:7`/`:34`/`:49`/`:60`), getting-started added to Family D, A1.3 exhaustive re-grep table
(confirms no other ungated surface; flags README.zh-CN:257 `14 个文件` as a NON-skill token to leave alone).
Verdict round 2: READY for re-review. No change to skill contract / generic split / OQ resolutions.
- Intervention check before re-review: `.harness/intervention.md` ABSENT.

### Stage 3 (round 2) — Gate Reviewer re-reviews → 03_GATE_REVIEW.md (2026-06-10)
Verdict: **APPROVED.** Gate re-ran its OWN independent live-tree grep (not trusting the SA's A1.3 claim, per
L19) — confirmed all 8 skill-count surfaces now covered by the amended ledger (getting-started rows 21-22,
manual-e2e row 16 clarified), zero premature `fifteen`, README.zh-CN:257 `14 个文件` correctly excluded, 32
CHECK tokens untouched. All 8 dimensions PASS. **Stage gate satisfied (explicit APPROVED before Dev).**
Design-stage rollback count: 1 (under the limit of 3).

PM routing decision: **ADVANCE to Stage 4 (Developer).** Partition detection: `.harness/agents/dev-*.md` →
NONE → **single Developer mode** → dispatch generic `developer`.
- Intervention check before Stage 4: `.harness/intervention.md` ABSENT.

### Stage 4 — Developer → 04_DEVELOPMENT.md (2026-06-10)
Dispatched (role-play, single developer). Implements families A/B/C/D strictly from the amended §2/§7/§4
ledger. verify_all/test-init/baseline are operator-run (sub-agent has no Bash) → Dev surfaces
BLOCKED-ON-CAPABILITY for the run gate, does NOT fabricate tallies (L23). See doc.
