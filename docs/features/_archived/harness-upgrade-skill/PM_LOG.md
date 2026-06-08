# PM Log — T-012 harness-upgrade-skill

> Task: new `/harness-upgrade` skill — upgrade an existing project that was
> initialized with an older harness-kit version to the current plugin's layout +
> script contents. Self-bootstrapping (does not depend on the migration helper
> already being present in the old project).
>
> Mode: full (7-stage). Started 2026-06-08.

## Intervention check
- Before stage 1 dispatch: `.harness/intervention.md` absent → no pending signal.

## Developer mode
- `.harness/agents/dev-*.md`: none found → single Developer mode.

## Insights surfaced to downstream (from .harness/insight-index.md)
- **L31 (T-007)**: dogfood scripts derive repo-root as a FIXED level-up from their own
  location; relocation across directory depth silently breaks root resolution. This task's
  core domain is exactly relocation/upgrade — Architect+Dev must treat root-derivation as a
  first-class concern, not a path-string sweep.
- **L11**: any new `{{...}}` placeholder in a `.tmpl` MUST be whitelisted in BOTH
  verify_all.ps1 AND .sh D.2 (case-sensitive `-ccontains`/`-cnotin`).
- **L30**: never edit `.claude/settings.json` shape from memory — consult upstream schema
  (context7 `/websites/code_claude` or schemastore) first; J.1 gates it.
- **L33 (T-008) + L35 (T-010)**: adding a verify_all check is version-worthy (G.4); same-file
  verify_all claim `expect` literals must be file-unique.
- **L12**: `sync-self` mirrors only agents + 4 script pairs, NOT rules; template ↔ dogfood
  symmetry for any new script must be maintained (F.1/E.2).
- **L10**: Edit tool may report success without applying — re-Read/Grep to verify.

## Stage transitions

### Stage 1 — Requirement Analyst — dispatched 2026-06-08
- Output: `01_REQUIREMENT_ANALYSIS.md`. Verdict: **BLOCKED ON USER** (10 OQs with defaults).
- 15 ACs, 13 behaviors, 8 downstream obligations (DO-1..DO-8) flagged from insights.

### OQ resolution — user delegated decision authority to PM (2026-06-08)
User instruction (verbatim intent): decide by the principle **"good UX + conforms to
software-engineering standards + long-term ease-of-use & maintainability"**; user reviews
results only; PM owns all commits/pushes. Resolutions (this is the agreed design baseline):

- **OQ-3 → (a) full-regenerate verify_all from the type `.tmpl`**, with a **HARD,
  non-negotiable constraint: NEVER silently lose a user's B.* customizations.** Mechanism
  (Architect to design the cleanest deterministic form): always write a `.bak`; detect
  non-stub B.* checks; if present, EITHER preserve the B.* block verbatim into the
  regenerated file (when the block is cleanly delimited) OR halt and require explicit user
  confirmation before overwrite. Rationale: full-regen is the only deterministic / idempotent
  / parity-testable path (maintainability); the constraint protects UX (no silent data loss).
  Merge-in (b) rejected as the general mechanism — fragile splice, hard to keep idempotent.
- **OQ-5 → (a) scripts-layer only for v1** (scripts + hooks + settings + verify_all).
  agent/skill/rule CONTENT refresh deferred (different, higher-risk problem; users edit
  agents/rules). Future `--include-agents` flag. Rationale: narrow, well-tested v1 = SWE
  discipline + maintainability; matches the user's stated pain.
- **OQ-1 → (b)** skill + one deterministic helper (`upgrade-project.{ps1,sh}`); AI does only
  judgment (gap report, type detect, verify_all-refresh decision).
- **OQ-2 → (c)** require clean git tree AND write `.bak` for the two untracked surfaces
  (pre-commit hook, settings.json).
- **OQ-4 → (d)** ask user via AskUserQuestion pre-filled from `50-<type>.md` then the
  `=== verify_all (<type>) ===` header; never silently guess; `{{STACK}}` for generic comes
  from the user.
- **OQ-6 → (a)** post-v0.2 only; v0.1.x keeps the manual MIGRATION.md path.
- **OQ-7 → (a)** detect non-stock pre-commit hook; do not overwrite; surface as conflict.
- **OQ-8 → (a)** refuse on dirty working tree; ask user to commit/stash first.
- **OQ-9 → (a)** non-Claude-Code projects (no `.claude/settings.json`): still refresh
  scripts + hooks + verify_all; skip settings rewire with a logged note.
- **OQ-10 → (a)** name `/harness-upgrade`; ship as next minor (v0.23.0).

Requirement flipped to **READY** on the above baseline. Advancing to stage 2 (design).

### Stage 2 — Solution Architect — dispatched 2026-06-08
- Output: `02_SOLUTION_DESIGN.md`. Verdict: **READY**.
- Two code-verified corrections to the PM brief: (1) skill SOT is `skills/<name>/` ONLY
  (no `.harness/skills/` in this repo — plugin.json `"skills":"./skills/"`); (2) no new
  `{{...}}` placeholder, no new lettered verify_all check → check count stays **32**, only
  skill count 12→13 + version 0.23.0 move.
- Crux (L31) resolved: relocate the whole known-set, then UNCONDITIONALLY byte-refresh the
  depth-sensitive scripts' CONTENT from the current template (already two-up). New logic is
  only S2 (content-refresh) + S5 (verify_all splice/regenerate w/ `HARNESS:B-CUSTOM` delimiter).
- Architect flagged 2 items for Gate sanity-check: (a) adding B.* delimiters to the 6
  verify_all templates; (b) keeping check count at 32.

### Stage 3 — Gate Reviewer — dispatched 2026-06-08
- Output: `03_GATE_REVIEW.md` (persisted by PM; GR is read-only). Verdict: **APPROVED FOR
  DEVELOPMENT**. 0 BLOCKING, 5 ADVISORY (F-1..F-5). 15 load-bearing claims verified vs live
  code; both Architect-flagged decisions (B.* delimiters; check count stays 32) endorsed.
- PM routing decision: F-1 (fan-out list incomplete) is advisory + not gate-enforced, and GR
  already enumerated the 5 extra stale sites — NOT routing back to Architect (would add 5 lines
  for no gate benefit). All 5 advisories folded into the Developer brief instead.

### Stage 4 — Developer — dispatched 2026-06-08
- Output: `04_DEVELOPMENT.md`. Captured gates: verify_all.ps1 **32/32 PASS 0W 0F** (skill 13,
  v0.23.0); verify_all.sh exit-0 (MSYS I.6 capture-truncation noted, L27/T-010); sync-self in
  sync (E.1 incl. upgrade-project); test-init 251/251 (ps1) · 213/213 (sh); test-harness-upgrade
  38/38 (ps1) · 37/37 (sh). All 5 GR advisories actioned. Check count stays 32.
- Dev self-flagged 1 minor DESIGN DRIFT: helper assembles `{{...}}` substitution tokens from
  pieces (`"{{"+NAME+"}}"`) so the copied helper doesn't trip test-init's no-placeholder scan —
  substitution behavior unchanged, only source form differs. Routed to CR for adjudication.
- Stage-4→5 gate (verify_all PASS shown in 04) satisfied.

### Stage 5 — Code Reviewer — dispatched 2026-06-08
- Output: `05_CODE_REVIEW.md` (persisted by PM; CR is read-only). Verdict: **APPROVED**.
  0 BLOCKING, 0 MAJOR, 4 MINOR, 2 NIT. Design-drift item (`{{...}}` piece-wise assembly)
  adjudicated ACCEPT (not drift, no route to architect). All 15 ACs ✅, all 5 GR advisories
  discharged, no fabricated tally (38/37 explained by AC-3 3-way branch).
- PM routing decision on the 4 MINOR + 2 NIT (none gate-blocking; CR says none blocks merge):
  Fix BEFORE QA the 3 low-risk clarity items (so QA tests the final artifact, no re-QA):
  (1) MINOR MAINT misleading VERIFY-HALT message (UX); (2) MINOR DOC TARGET-VERSION contract
  comment + SKILL.md colon/pipe alignment + NIT meaningless inline note; (3) MINOR MAINT
  known/refreshSet cross-ref comment. DEFER (surgical-change discipline — touching working code
  for zero behavioral gain): MINOR LOGIC precondition-ordering. OUT OF SCOPE: NIT stale
  `test-init-227` README badge (pre-existing drift, not T-012, surface to user).

### Stage 5b — Developer cleanup (CR MINOR) — dispatched 2026-06-08
- 3 surgical fixes applied (comment/message/prose only, behavior unchanged): (1) VERIFY-HALT
  message accuracy; (2) TARGET-VERSION contract comment trim + SKILL.md made human-prose
  (`Target version: x.y.z`) resolving colon/pipe mismatch; (3) known/refreshSet invariant
  cross-ref comments. Deferred items confirmed untouched; 6 `.tmpl` not touched (no test-init rerun).
- Re-gate after cleanup: sync-self In sync (both shells); verify_all **32/32 0W 0F BOTH shells**
  (bash full summary now captured, prior MSYS truncation gone); test-harness-upgrade 38/37 unchanged;
  AC-5 runtime assertion still passes. 04_DEVELOPMENT.md appended `## CR-minor cleanup (stage 5b)`.
- Stage-5 APPROVED + cleanup green → advancing to QA.

### Stage 6 — QA Tester — dispatched 2026-06-08
- Output: `06_TEST_REPORT.md`. Verdict: **PASS** (ship-ready, 1 MINOR routed). Independently
  reproduced: verify_all **32/32 0W 0F BOTH shells** (no MSYS truncation this run); test-harness-upgrade
  **38/0 (ps) · 37/0 (sh)**; test-init 251/0 · 213/0; sync-self In sync. 16 adversarial probes:
  15 fully passed. AC-5 mutation test confirmed the root-derivation assertion goes RED on a one-up
  regression (genuinely load-bearing). OQ-3 data-loss hunt found NO silent-loss path. AC-8/AC-12/BC-10
  VERIFIED-BY-SPEC (skill AI layer not headlessly drivable — honest disclosure). Stability: bash 3×, PS 2×, 0 flakes.
  QA bumped baseline.json (test_harness_upgrade_ps=38 / bash=37), re-ran verify_all still 32/32.
- **DEFECT-1 [MINOR → developer]**: `upgrade-project.ps1` writes pre-commit hook WITHOUT trailing
  newline (`:259`,`:274`); bash helper + canonical install-hooks.sh write one → cross-shell byte
  asymmetry → one-time spurious hook re-install + `.bak` on ps1→sh switch. Self-heals, writes `.bak`,
  no data loss, fails no gate. PM decision: **FIX before delivery** — it violates NFR-1 cross-shell
  parity (a hard rule); trivial one-char fix; keeps shipped artifact correct (fixing post-delivery
  would force re-QA). Routed to developer.

### Stage 6b — Developer fix (DEFECT-1) — dispatched 2026-06-08
(awaiting output)
