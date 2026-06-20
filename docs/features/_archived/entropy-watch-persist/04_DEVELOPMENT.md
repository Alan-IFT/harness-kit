# Development Record — T-11c entropy-watch-persist

> Stage 4 (Developer). Mode: full (final slice; decline-filter only). Gate APPROVED.
> Implemented EXACTLY per `02_SOLUTION_DESIGN.md` + `03_GATE_REVIEW.md`. No design decisions made.

## Summary

The anti-entropy watch now respects declined findings: the scan reads `.harness/rejected-decisions.md`
before writing its artifact and excludes any finding whose normalized `Where` handle exactly matches a
`declined`/`deferred` record's concept handle, and `/harness-deflate` step 4 gains a third user choice
(`decline EP-NNN`) that records a T-09-format decline (memory-write only). No standalone findings store
is built — OPEN/FIXED are re-derived by the scan each sweep. Version bumped 0.42.0 → 0.43.0.

## Files changed (3 behavioral + 5 stamps; no file created, none deleted)

- `skills/harness-deflate/references/entropy-scan.md` — added the `## Decline filter` section (the
  SINGLE source) AFTER `## Entropy findings artifact` and BEFORE `## Determinism + caps`: read source,
  stable-key + normalization (trim, `\`→`/`, strip leading `./` + trailing `/`, no case-fold, no dir
  coarsening), EXACT-equality match rule (not substring/prefix), per-run EP-NNN explicitly NOT the key,
  drop semantics (no Findings/Detail row, no FINDINGS-PRESENT contribution, all-dropped → CLEAN),
  internal `decline-filter: N finding(s) suppressed` methodology note, and fail-open on
  absent/unreadable/empty file. Updated the `## Determinism + caps` opening sentence to note
  determinism holds over an unchanged tree AND an unchanged `.harness/rejected-decisions.md`.
- `agents/supervisor.md` — ONE decline-filter clause in `## Entropy lens` pointing at the scan ref's
  `## Decline filter` rule (does NOT restate the key rule); widened the entropy-mode read-set by the
  one whitelisted `.harness/rejected-decisions.md` file (consistent with the existing entropy read-only
  exception). 280 → 285 lines (≤300 cap).
- `skills/harness-deflate/SKILL.md` — promoted the step-4 T-11c placeholder to the real three-way pick
  (deflate / decline / none). `decline EP-NNN` is memory-write only (no `/harness-goal` dispatch, no
  production edit): resolve in the just-presented artifact (not present → report, no write), stable key
  per the scan ref (pointed at, not restated), and the T-09 record-shape CONTRACT
  (`## <stable-key>` + `Decision: declined` + Why + `Origin: entropy sweep <ISO-date> · EP-<class>`)
  with de-dup by handle and create-from-seed-if-absent. Per NOTE-3 the text states the append is the
  MAIN agent's decide-point habit (`25-decision-policy.md`) — the skill does not edit the file and no
  tool was added to `allowed-tools` (stays `Read, Glob, Grep, Task`).
- `.harness/rejected-decisions.md` — appended the `## entropy-findings-store` decline record
  (de-dup-checked first — none existed; reason: re-encodes a re-derived fact, the scan re-derives
  OPEN/FIXED each run). I.6-clean (file IS scanned).
- `.claude-plugin/plugin.json` — `version` 0.42.0 → 0.43.0 (G.3 stamp 1).
- `.claude-plugin/marketplace.json` — `version` 0.42.0 → 0.43.0 (G.3 stamp 2).
- `README.md` — version badge 0.42.0 → 0.43.0 (line 5, version token only; no ratio flip).
- `README.zh-CN.md` — version badge 0.42.0 → 0.43.0 (line 5, version token only; no ratio flip).
- `CHANGELOG.md` — prepended `## [0.43.0] - 2026-06-20` (G.4), noting no count flip and no new
  check/file/skill/agent.

## verify_all result

- Baseline (before edits): PASS 32 / WARN 0 / FAIL 0; test-supervisor.sh 45 PASS / 0 FAIL.
- After changes: PASS 32 / WARN 0 / FAIL 0; test-supervisor.sh 45 PASS / 0 FAIL.
- Delta: 0 new failures, 0 new warnings. Check count unchanged (32 — no new check). G.3 (version stamps
  consistent at 0.43.0), G.4 ([0.43.0] CHANGELOG + claim↔plugin.json consistency), I.6 (clean including
  the new rejected-decisions record + scan section + SKILL prose) all PASS.

## Acceptance-criteria self-review (01 §Acceptance)

1. Declined module's EP row omitted from the artifact — implemented: scan drops on exact-key match
   before writing Findings/Detail.
2. Remove the record → finding reappears — implemented: filter is a deterministic set subtraction keyed
   only on the record; nothing else suppresses the finding.
3. `decline EP-NNN` writes a `## <Where>` record (declined + why + entropy-sweep origin) — implemented
   as the step-4 record-shape contract.
4. Second decline of an existing handle appends an origin, no 2nd record — implemented (T-09 de-dup
   clause in step 4).
5. Decline triggers no refactor / edits no production file; verify_all stays green — implemented
   (memory-write only, no dispatch) and verified (32/0/0 after change).
6. Non-declined still-shallow finding re-surfaces next sweep — preserved: only declined-key matches are
   subtracted; the re-derive behavior is otherwise untouched.
7. verify_all green, check count unchanged, version 0.43.0 — verified.

## 3 non-blocking notes (03 §Findings) — self-review

1. DRY is review-enforced, not gated. Honored: the key rule lives ONLY in `references/entropy-scan.md`;
   `supervisor.md` and `SKILL.md` POINT at it ("read it for the key + match + fail-open contract",
   "normalized per the `## Decline filter` rule … do not restate it here") and do not restate it.
2. Filter matches `declined` AND `deferred`. Honored: match rule explicitly covers both Decision
   values. The existing `## design-it-twice` (deferred) matches no module path → inert, as expected.
3. The append is the MAIN agent's action (skill has no Edit/Write). Honored: SKILL.md states the
   record-shape CONTRACT and attributes the append to the main agent's `25-decision-policy` decide-point
   habit; no Edit tool / writing sub-agent added; `allowed-tools` unchanged.

## Design drift

None. Implementation matches the design and the gate's pre-answered Qs exactly. (Minor note, not drift:
`02 §Standard decline-record habit` sketched a longer `entropy-findings-store` reason; the brief's item-4
canonical reason — "re-encodes a re-derived fact; the scan re-derives OPEN/FIXED each run" — was used as
the record's spine, kept substantive and I.6-clean. Same decision, same record, no behavioral delta.)

## Constraint compliance

- NO new file (no findings-store): confirmed — only existing files edited; `git status` shows no new
  tracked file from T-11c (the `?? skills/harness-deflate/` and feature folders are pre-existing
  uncommitted T-11a/T-11b work, not created by this slice).
- NO new script / skill / state / verify_all check: confirmed — check count stays 32.
- NO count flip: confirmed — 17 skills / 8 agents / 32 verify_all / 90 integration / 314 test-init all
  untouched; G.1/G.2/G.4 PASS; no decoy claim edited.
- supervisor ≤300: confirmed — 285 lines.
- I.6 clean: confirmed — I.6 PASS; the new rejected-decisions record + scan section + SKILL prose quote
  no banned anchor (rejected-decisions.md IS I.6-scanned).
- Both decline records written: `## entropy-findings-store` appended to `.harness/rejected-decisions.md`
  (the standalone-store decline); the per-finding decline record is the step-4 CONTRACT in SKILL.md
  (written by the main agent at decline time, not at dev time — correct per design).

## Open issues for review

None. The per-finding decline record is produced at runtime by the main agent (per the design's
no-Edit-tool contract), not at dev time — the reviewer should confirm the SKILL.md prose states the
contract without implying the skill itself edits the file (NOTE-3).

## Dev-map updates

None. T-11c adds/moves/removes no file or module; `harness-deflate` (SKILL.md + references/entropy-scan.md)
and `.harness/rejected-decisions.md` are already in `docs/dev-map.md` from T-11a / T-09.

## T-11c git diff --name-only (this slice's files only)

```
agents/supervisor.md
.harness/rejected-decisions.md
.claude-plugin/plugin.json
.claude-plugin/marketplace.json
README.md
README.zh-CN.md
CHANGELOG.md
skills/harness-deflate/SKILL.md
skills/harness-deflate/references/entropy-scan.md
```

> Note: the working tree contains other modified/untracked files from prior uncommitted T-11a/T-11b and
> earlier work (verify_all, pm-orchestrator, AI-GUIDE, dev-map, tasks.md, the `skills/harness-deflate/`
> tree, archived feature folders, etc.). Those are NOT T-11c edits — the list above is exactly the files
> this slice touched, verified by diffing each for T-11c content.

## Verdict

READY FOR REVIEW
