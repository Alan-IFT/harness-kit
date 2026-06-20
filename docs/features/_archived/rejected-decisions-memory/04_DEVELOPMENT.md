# Development Record — T-09 rejected-decisions-memory

## Summary
Added a fourth memory kind — a `rejected-decisions.md` deliberately-declined-options memory —
in two non-byte-synced copies (real dogfood + generic template seed), wired the read-at-decide /
append-on-decline habit single-sourced into `25-decision-policy.md` with SOFT pointers from RA/SA,
reconciled the `15-skill-authoring.md` telemetry decline to a one-line pointer, indexed it in
AI-GUIDE + dev-map, added one symmetric test-init assertion, and stamped v0.39.0 → v0.40.0 with
counts unchanged. Implemented EXACTLY per 02_SOLUTION_DESIGN §3.1-§3.7, §5, §6.

## Files changed

**New (2):**
- `.harness/rejected-decisions.md` — dogfood: tight ≤6-substance-line header (what / when-read /
  when-append + one-record-per-concept rule + 3 sibling-memory pointers + soft size note, NO numeric
  gate) + 9 seed records (1 `deferred` = `design-it-twice`; 8 `declined` = `ask-matt-router`,
  `issue-tracker-dedup`, `to-prd`, `triage`, `skill-usage-telemetry`, + 3 grouped non-fit skill
  families). Each record = `## kebab-handle` + Decision + substantive Why + Origin (backward-looking
  evidence, no forward file:line anchors). §3.1.
- `skills/harness-init/templates/common/.harness/rejected-decisions.md` — generic seed: same header
  + one `example-declined-concept` stub + HTML-comment instruction; placeholder-free, no `{{...}}`,
  plain `.md` (no `.tmpl`); body differs from dogfood (AC-3). §3.2.

**Edited — content (5):**
- `.harness/rules/25-decision-policy.md` — canonical read/append bullet added to the "When to read
  this" list (single source); 100 → 106 lines. §3.3.
- `agents/requirement-analyst.md` — one SOFT pointer appended to workflow step 7 (CONTEXT.md
  soft-read line); "per `.harness/rules/25-decision-policy.md`", read-if-present, "Absent is fine —
  never a precondition". §3.4.
- `agents/solution-architect.md` — one SOFT pointer appended to workflow step 5; "per
  `25-decision-policy.md`", "Absent is fine — it never blocks the design". §3.4.
- `.harness/rules/15-skill-authoring.md` — telemetry rationale body replaced with a PURE pointer
  (names the decline, points to `.harness/rejected-decisions.md` for the why); "Deliberately not
  adopted" heading kept; 116 → 113 lines. §3.5.
- `AI-GUIDE.md` — one Memory-layer bullet (4th kind: declined options); stays 111 lines ≤200. §3.6.

**Edited — index/location (1):**
- `docs/dev-map.md` — one "Where features live" row (after the CONTEXT.md row) + one `.harness/`
  tree-comment line (after `decision-rubric.md`). §3.7.

**Edited — test (2):**
- `.harness/scripts/test-init.sh` — one `assert "rejected-decisions.md seed present (generic)"`
  after the CONTEXT.md present-assertion (sh:140). §6.
- `.harness/scripts/test-init.ps1` — symmetric `Assert` after the CONTEXT.md present-assertion
  (ps1:172). F.1 parity. §6.

**Edited — version stamp (5) + baseline (1):**
- `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `README.md` badge,
  `README.zh-CN.md` badge — `0.39.0` → `0.40.0` (version- token only). §5.
- `CHANGELOG.md` — new `## [0.40.0] - 2026-06-20` heading; restates counts UNCHANGED (16 skills /
  8 framework agents / 32 checks), no new check, no new placeholder (D.2 stays 7), not byte-synced. §5.
- `.harness/scripts/baseline.json` — `test_init_bash_no_python3_assertions` 273 → 276 from a REAL
  captured `test-init.sh` run (NOT hand-typed). `test_init_ps_assertions` (308) + both README
  `test--init-308/308` badges LEFT for PM to reconcile from a captured PS run (C2).

## verify_all result
- Baseline (before changes): PASS 32 / WARN 0 / FAIL 0.
- After changes: PASS 32 / WARN 0 / FAIL 0 (`bash .harness/scripts/verify_all.sh`).
- Delta: 0 new failures, 0 new WARN; check count unchanged at 32 (no new check). I.6 PASS with
  BOTH new files in scan scope (`git ls-files` lists both — confirmed before the run). G.3 PASS
  (version stamps consistent), G.4 PASS (count/version claims consistent with plugin.json + live
  count). sync-self --check: "In sync" (template seed NOT in the byte-mirror set; dogfood/seed
  legitimately diverge like CONTEXT.md / decision-rubric.md).

## test-init result
- Baseline `test-init.sh`: PASS 273 / FAIL 0 (matches baseline.json `test_init_bash_no_python3_assertions: 273`).
- After: PASS 276 / FAIL 0 — exactly +3 (= +1 assertion × 3 project types: generic / fullstack /
  backend; the seed also passes in the zh fall-through path, which lives in `common/`). Reconciled
  `test_init_bash_no_python3_assertions` → 276.

## What the PM must reconcile (PowerShell — denied to this agent)
1. Run `pwsh .harness/scripts/test-init.ps1`; expect 308 + 3 = **311** PASS. Set baseline.json
   `test_init_ps_assertions` to the CAPTURED total (do NOT hand-type 311 — capture it).
2. Update BOTH README `test--init-308%2F308` badges (EN + zh) to the captured PS total/total.
   (Per design §5/§6 the test-init badge tracks the PS total; left at 308 by the developer per C2.)
3. Run `pwsh .harness/scripts/verify_all.ps1`; expect 32/0/0 (PS twin of the bash run; G.3/G.4/I.6
   confirmed green on bash).
4. Optionally re-run `test-real-project` both shells; design §6 expects 90/90 unchanged (the seed
   rides the overlay, not enumerated by name) — reconcile only if the captured run shows movement.

## Design drift
None. Implemented exactly per §3.1-§3.7, §5, §6. Header phrasing, the 9 records, the canonical
bullet, both SOFT pointers, the rule-15 pointer, the AI-GUIDE line, the dev-map row + tree line,
the test assertions, and the version stamp set match the design contract verbatim (whitespace only
adjusted where the contract permits).

## Conditions C1-C3 self-review
- **C1 (live skill count is 16; make NO count edits):** HONORED. I made ZERO count edits. I did NOT
  touch any `16`/`32` token, and did NOT "correct" anything toward 15. The CHANGELOG [0.40.0] entry
  RESTATES "16 skills / 8 framework agents / 32 checks" (a restatement of the unchanged count, not a
  flip). G.1/G.2 (README/CHANGELOG reference all 16 skills) PASS; G.4 PASS.
- **C2 (reconcile from captured runs, never hand-type):** HONORED. Updated ONLY
  `test_init_bash_no_python3_assertions` → 276 from a REAL captured `test-init.sh` run. Left
  `test_init_ps_assertions` (308) and both README `test--init-308/308` badges for the PM to
  reconcile from a captured PS run. Did NOT hand-type "311" anywhere.
- **C3 (verify_all.sh 32/0/0 with both new files in I.6 scope; test-init.sh green):** HONORED.
  `verify_all.sh` = 32/0/0; both new files are `git ls-files`-tracked (staged) so I.6 scanned them
  and PASSed. `test-init.sh` = 276/0 green (+3 over the 273 baseline). PowerShell twins deferred to
  PM per the deny rule (not faked).

## AC self-review (01_REQUIREMENT_ANALYSIS §6)
- AC-1: dogfood file exists with ≤6-substance-line header (what/when-read/when-append + sibling
  pointers + soft size note). PASS.
- AC-2: all named seed records present, four fields each, deferral/declined correctly marked
  (`design-it-twice` = deferred, rest declined). PASS.
- AC-3: template seed exists, placeholder-free (test-init `{{...}}` scan PASS), generic body
  (differs from dogfood — 1 stub vs 9 records), NOT in sync-self mirror (sync-self "In sync"). PASS.
- AC-4: one new AI-GUIDE Memory-layer line; AI-GUIDE 111 ≤200 (I.1 PASS). PASS.
- AC-5: one dev-map row resolving to the real path(s). PASS.
- AC-6: read/append habit single-sourced in rule 25; RA/SA carry pointer-only lines referencing it;
  rule 25 106 ≤200. PASS.
- AC-7: no new verify_all check (count stays 32); no new hook. PASS.
- AC-8: telemetry decline not duplicated as two divergent rationales — migrated to the new file,
  rule 15 holds a pointer (same reason, not a second one). PASS.
- AC-9: verify_all.sh PASSes 32/32, no new WARN. PASS (PS twin → PM).
- AC-10: no I.6 self-trip — I.6 PASS with both new files in scope. PASS.
- AC-11: version bumped one minor (0.39.0 → 0.40.0), G.4 PASS, no count claim changed. PASS.

## Open issues for review
- **WORKING-TREE DRIFT (PM attention — NOT a T-09 defect):** the working tree was NOT clean when
  this stage began (the session-start git snapshot reported "clean", but `git diff HEAD` shows
  substantial uncommitted work from PRIOR tasks co-mingled into many files I did not touch — e.g.
  `verify_all.ps1`, `agents/code-reviewer.md`, `agents/pm-orchestrator.md`, `docs/batches/*`,
  `install.{ps1,sh}`, `skills/harness-{batch,plan,stream}/SKILL.md`, the README/CHANGELOG `15→16`
  skill flip + `version-0.33.0` base, and many untracked `docs/features/_archived/*` task dirs +
  `skills/harness-grill/`, `CONTEXT.md`, `templates/common/CONTEXT.md`). My verify_all.sh (32/0/0)
  and test-init.sh (276/0) runs were over this combined tree, so they reflect the aggregate state.
  My T-09 edits are surgical (see "Files changed"); the drift is the PM's to reconcile/commit per
  task before or alongside the T-09 commit. The `16 skills` value was ALREADY correct in the tree
  (set by the prior harness-grill task) — I did not touch it, satisfying C1.

## Dev-map updates
- `docs/dev-map.md` "Where features live" table: + row
  `Rejected-decisions memory (.harness/rejected-decisions.md) | repo dogfood + templates/common seed | Fourth memory kind … No gate.`
- `docs/dev-map.md` `.harness/` tree comment: + line
  `│   ├── rejected-decisions.md  ← Memory layer (4th kind): deliberately-declined options + why; read/append at decide-points (v0.40+; dual-purpose dogfood + template seed)`

## Verdict
READY FOR REVIEW
