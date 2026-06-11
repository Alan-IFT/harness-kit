# Development Record — sync-hook-dangling-ref (T-020)

Mode: full · Developer: developer · Date: 2026-06-11
Upstream: `02_SOLUTION_DESIGN.md` (READY, incl. §6.2.5 C3 amendment) · `03_GATE_REVIEW.md` (GO-WITH-CONDITIONS C1–C4)

## Summary

Implemented the full T-020 design: presence-gated settings rewires + move/cp verification +
terminal hook↔script congruence scans (new exit code 4) in both deterministic helpers,
the §6.2.5 literal-placeholder repair in `upgrade-project` S3, OS-picked ambient hook
placeholders, the four SKILL-flow congruence/merge specs (init 10b, adopt 4-event merge +
C4 integrity assert, upgrade exit-4/C2 row, status §3c), the six type-template
`verify_all` row replacements (agents-layout WARN row + E.4b/D.4b congruence row), driver
fixtures for every new behavior, and the v0.31.0 release stamps. All scans use the
C1 left-boundary-guarded matcher; all gates and drivers were run on this machine and are
green (tallies below are pasted from captured runs).

## Files changed

Template helpers (source of truth; dogfood mirrors landed via `sync-self`, byte-verified by `sync-self --check` + gate E.1):

- `skills/harness-init/templates/common/.harness/scripts/migrate-scripts-layout.sh` + `.ps1` — RC-1/FR-P2: header exit-code 4 doc; MOVE-FAILED move verification; `target_present`-gated per-variant rewire (4 combos), unconditional double-prefix collapse last (B10 fixed point); terminal congruence scan (§4.1; CONGRUENCE-FAIL lines + `/harness-upgrade` hint; exit 4 both modes; dry-run projection = disk ∨ planned MOVE). F-4 (half-migrated doc strings) and R4 (fail-open on unparseable commands) acknowledged in comments per gate.
- `skills/harness-init/templates/common/.harness/scripts/upgrade-project.sh` + `.ps1` — RC-4/FR-P3 + C3: S2 refresh set += ambient pair (INVARIANT comments restated per §5.4); template-absent entries → `GAP|template-missing|absent|<path>` or NOOP-retained; cp/copy verified (`CONFLICT|refresh`); S3.0 literal-placeholder repair (§6.2.5: assembled tokens, OS pick per the four-row table, gated on `target_present`, `REWIRE-PLACEHOLDER` record, single REWIRE/.bak semantics untouched); S3.1 per-variant gated prefix rewire; S6 terminal scan emitting `CONFLICT|congruence` records, `n_conflicts++`, exit 4 last-writer-wins. Header exit/verb contract updated.
- `.harness/scripts/migrate-scripts-layout.{ps1,sh}`, `.harness/scripts/upgrade-project.{ps1,sh}` — dogfood mirrors via `bash .harness/scripts/sync-self.sh` (mappings 6–7); `sync-self --check` = "In sync".

Templates / SKILLs:

- `skills/harness-init/templates/common/.claude/settings.json.tmpl` — OQ-3: ambient commands → `{{AMBIENT_PROMPT_COMMAND}}` / `{{AMBIENT_RESET_COMMAND}}`; `_ambient_hook` doc reworded to "OS-picked at init time… swap freely" (§6.3). Rule 80 honored: upstream schema fetched live from `https://www.schemastore.org/claude-code-settings.json` before the edit (`hooks` is `additionalProperties:false`; `UserPromptSubmit`/`SessionStart` confirmed in the event enum; `command` is a free string — value-only change). J.1 green.
- `skills/harness-init/SKILL.md` — placeholder table +2 rows (§5.3); new mandatory step 10b (terminal congruence assertion with the C1 left-bounded pattern, no-verify_all rule untouched); failure-handling bullet pointing at 10b. (FR-P4)
- `skills/harness-adopt/SKILL.md` — RC-3: substitution table += `{{SYNC_COMMAND}}`/`{{GUARD_COMMAND}}`/`{{AMBIENT_PROMPT_COMMAND}}`/`{{AMBIENT_RESET_COMMAND}}` (citing the init OS-pick rule); plan-template settings bullet + "Hooks merge" section + step-6 special case generalized to all four events (per-event add/leave/conflict); step-6 terminal congruence + **C4** merge-mode integrity assertion (JSON parses, canonical `$schema`, valid hook event keys, `_*` keys survive).
- `skills/harness-upgrade/SKILL.md` — **C2** exit-4 row (relay congruence lines verbatim; user-custom missing file → manual restore; co-occurring `VERIFY-HALT`/`CONFLICT|verify_all` (exit-2 remediation) and `CONFLICT|hook` (exit-3 remediation) still processed; dry-run-leg exit 4 = plan presented unchanged); records table documents `GAP|template-missing`, `CONFLICT|refresh`/`congruence` kinds; verb list + `REWIRE-PLACEHOLDER` row with relay instruction; "When to invoke" repair framing; step-7 report += `Repaired:` + `Congruence:` lines. (§6.6)
- `skills/harness-status/SKILL.md` — RC-6/FR-D1/FR-D2: "All 7 agents" + "Supervisor" asset rows deleted, plugin-provided note added (asset count now a consistent **14**; §6 health score updated); new §3c per-event congruence report (`ok`/`not wired`/`DANGLING`/`MALFORMED` + interpreter-availability WARN with the variant-swap instruction, OQ-5: never auto-rewrite a runnable variant); §7 recommendation routing line. (§6.7)
- `skills/harness-init/templates/{generic,fullstack}/.harness/scripts/verify_all.{sh,ps1}.tmpl` and `backend/...` (6 files) — E.3/D.3 replaced with "Agents layout v0.30+ (.harness/agents/ = partition dev-* only)" (PASS absent/dev-only; WARN listing legacy copies with remediation); new E.4b/D.4b "Hook commands resolve to existing scripts" row (SKIP without settings — B1; FAIL names missing path + `fix: run /harness-upgrade`; assembled `{{` token check; C1-bounded ERE), placed after E.4/D.4, **outside** B-CUSTOM markers. (FR-D3/FR-D4, OQ-4/OQ-6, AC-3/AC-4)

Dogfood gate + drivers:

- `.harness/scripts/verify_all.sh` (D.2 case list) + `.harness/scripts/verify_all.ps1` (`$allowed`, `-cnotin` untouched) — whitelist += the 2 ambient placeholders. **No check added/removed — count stays 32** (G.4 only needed the `[0.31.0]` CHANGELOG heading).
- `.harness/scripts/test-harness-upgrade.{sh,ps1}` — new fixtures: **H** = design §10 "Fixture G" (dangling repair AC-2/FR-R1/R2 + the C1 custom `build-scripts/deploy.sh` hook false-positive guard + re-run byte-identity), **I** = design §10 "Fixture H" (incongruent end state via crafted template root: `GAP|template-missing`, `CONFLICT|congruence`, exit 4, legacy path untouched), **P** (placeholder repair: dry-run `PLAN|REWIRE-PLACEHOLDER` + untouched file; apply OS-picked command, no `{{`, target exists, wired command runs, exactly one `.bak`, `_doc_sync_hook`/`$schema` intact; re-run NOOP/no `.bak`/byte-identical — AC-9/B10), **P2** (gated-off token: not substituted, `CONFLICT|congruence` unresolved-token, exit 4), **M1/M2** (migrate RC-1 exit-4 + healthy/idempotent — AC-1/B10). Two existing assertions' needles updated from the retired "agents in .harness/agents" wording to `partition dev-* only`. Driver token strings assembled from pieces (insight 2026-06-08).
- `.harness/scripts/test-init.{sh,ps1}` — ambient substitutions added to the OS-pick block / all three `$vars` tables; new assertions: settings hook-path congruence (step-10b deterministic core, C1-bounded), ambient commands equal the OS-picked variant, generated verify_all carries the new wording + E.4b/D.4b and not the retired check, and the delete-`harness-sync.*` mutation probe (AC-5 both halves).
- `.harness/scripts/test-real-project.{sh,ps1}` — substitutions += ambient pair **and `{{GUARD_COMMAND}}`** (previously unsubstituted — without it the healthy fixture's E.4b would flag the literal token; required by the design's healthy-fixture-PASS assertion); new legs run the generated type `verify_all` (`--quick`) on the healthy single-dev state (E.3/D.3 + E.4b/D.4b PASS) and after deleting `harness-sync.*` (E.4b/D.4b FAIL naming path + fix command). (AC-3/AC-4)
- `.harness/scripts/test-supervisor.{sh,ps1}` — **fan-out fix (not in design §3; see Design drift)**: two structural asserts pinned the harness-status asset rows this task retires; updated to assert the NEW state (plugin-provided note present incl. supervisor; canonical-7 glob row gone). Counts unchanged (45/49).

Release stamps / records:

- `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` — 0.30.1 → **0.31.0**.
- `CHANGELOG.md` — `[0.31.0]` entry (G.4 heading requirement).
- `README.md`, `README.zh-CN.md` — version badge 0.31.0; test badges refreshed from captured runs (test-init 287→308, integration 82→90); `test-real-project` text claim 82→90; roadmap += 0.31.0 row.
- `.harness/scripts/baseline.json` — captured-run counts: test-init ps 287→308, bash(no-python3) 249→270; test-harness-upgrade ps 38→77, bash 37→76; new test-real-project fields 90/90; `last_verify` 2026-06-11. `verify_all_checks` stays 32.
- `docs/dev-map.md` — descriptions of `migrate-scripts-layout` / `upgrade-project` / `test-harness-upgrade` extended with the v0.31 congruence/exit-4 capability (no files added/moved/removed — no structural rows changed).

## Gate conditions C1–C4

**C1 (F-1, left-boundary the scan ERE — satisfied with a real matcher run).** All five consumers use
`(^|["' =])(\.harness/)?scripts/[A-Za-z0-9._-]+\.(ps1|sh)` (bash `grep -oE` + boundary-strip `sed`; PS `[regex]` without IgnoreCase, group 2 capture). Actual matcher run over a fixture settings containing the gate's exact false-positive candidate, pasted verbatim:

```
=== C1 matcher run: extracted path tokens (left-bounded ERE) ===
.harness/scripts/guard-rm.sh
.harness/scripts/harness-sync.sh
scripts/run-me.sh
=== existence verdicts ===
ok       .harness/scripts/guard-rm.sh
MISSING  .harness/scripts/harness-sync.sh
MISSING  scripts/run-me.sh
=== negative control: extracted tokens containing build-scripts (must be 0) ===
count=0
```

(`bash build-scripts/deploy.sh` is never extracted; the `=`-bounded `RUNNER=scripts/run-me.sh` IS still caught; `my-scripts/tool.sh` not extracted; doc-string mentions on non-command lines not scanned.) End-to-end, Fixture H wires a real `bash build-scripts/deploy.sh` hook through a full `upgrade-project` apply — captured run:

```
  [PASS] H: no CONFLICT|congruence in output (end state congruent)
  [PASS] H: [C1] custom build-scripts/deploy.sh hook NOT flagged (left-bounded ERE)
```

**C2 (F-2).** The `harness-upgrade/SKILL.md` exit-4 row instructs: relay `CONFLICT|congruence` lines verbatim; manual-restore for non-template files; explicitly process co-occurring `VERIFY-HALT`/`CONFLICT|verify_all` (exit-2 remediation: confirm → `--force`) and `CONFLICT|hook` (exit-3 remediation) records per their own rows; exit 4 can fire on the dry-run leg (projected violation) with plan presentation unchanged. Mechanically, the scan is the last `exit_code` writer in both helper shells.

**C3 (F-3, §6.2.5 binding spec).** Implemented exactly: S3 first pass, assembled tokens (`grep -qF` + `${txt//...}` in sh; `.Contains`/`.Replace` ordinal in PS), OS pick per the §6.2.5 four-row table, gate = `target_present(<picked ext>)` (disk in apply; planned-MOVE/template-carries projection in dry-run), `REWIRE-PLACEHOLDER|.claude/settings.json (<NAME> -> <command>)` with the name printed braces-free, write path/`.bak`/`n_rewired` semantics untouched, B10 fixed point (re-run NOOP). Fixtures P (repair, dry-run + apply + re-run) and P2 (gated-off → token untouched, exit 4) pass in both shells; AC-7 cross-shell spot check: bash-helper vs PS-helper repaired settings.json are **byte-identical** (`cmp` clean) on this Windows machine (both shells pick the pwsh command, per §6.2.5).

**C4 (F-6).** `harness-adopt/SKILL.md` step-6 terminal assertion now additionally requires, after any merge-mode settings write: JSON parses; `$schema` is exactly the canonical `.json` URL; every `hooks` key is a valid event name; pre-existing root `_*` doc keys survived. Flow failure (no success summary) until it passes.

## verify_all result

- Baseline: clean tree at released v0.30.1 (recorded 32 PASS / 0 WARN / 0 FAIL — `baseline.json` + README badge; no fresh pre-change run was captured since the tree was at an already-gated release commit).
- After changes (captured runs, this machine, 2026-06-11):
  - `verify_all`: bash **32 PASS / 0 WARN / 0 FAIL**; pwsh **32 PASS / 0 WARN / 0 FAIL** (count stays 32 — NFR-4).
  - `sync-self --check`: "In sync." (NFR-3 mirrors byte-identical).
  - `test-harness-upgrade`: bash **76/0**, ps **77/0** (was 37/38 — +39 new assertions each).
  - `test-init`: bash **270/0** (no-python3 path; was 249), ps **308/0** (was 287; +21 = 7 new × 3 types).
  - `test-real-project`: bash **90/0**, ps **90/0** (was 82; +8 = 4 new × 2 fixtures).
  - `test-supervisor`: bash **45/0**, ps **49/0** (counts unchanged after the fan-out fix).
  - `test-verify-i6`: bash **58/0**, ps **58/0**; `test-language`: bash **39/0**, ps **39/0** (untouched surfaces, regression-confirmed).
- Delta: 0 new failures; baseline raised (+68 driver assertions net across suites).

## Design drift (if any)

No behavioral deviation from the design. Four implementation notes the reviewer should see (flagged for completeness, none changes a designed contract):

1. `DESIGN DRIFT` (naming only) — design §10 fixture letters "G"/"H" collide with the driver's pre-existing Fixture G (no-harness halt); they landed as **H** (dangling repair) and **I** (incongruent end state). Assertions match the design 1:1.
2. `DESIGN DRIFT` (projection superset) — §4.1 lists "template carries `<name>`" as the upgrade dry-run projection source; the implementation additionally counts a planned S1 `MOVE` (the generic first clause of §4.1), so the dry-run plan can never disagree with what apply would do when the script is moving from legacy `scripts/`. Strictly more faithful projection; apply-mode behavior identical.
3. Fan-out not in design §3: `test-supervisor.{sh,ps1}` carried two structural asserts pinning the harness-status rows this task retires; they were updated to assert the new state (tests fixed, not deleted; counts unchanged). Without this, test-supervisor fails 2 assertions against the designed §6.7 change.
4. Fan-out not in design §3: `test-real-project.{sh,ps1}` never substituted `{{GUARD_COMMAND}}`; the design's healthy-fixture E.4b-PASS assertion is unsatisfiable with a literal token in settings, so the substitution was added alongside the designed ambient pair.

## Open issues for review

- The pre-existing migrate `sh` (`printf '%s\n'`) vs `ps1` (`WriteAllText`) trailing-newline nuance on non-newline-terminated settings files is unchanged, per design R1/§12 (recorded, not fixed).
- The two new `GAP|template-missing` / `CONFLICT|refresh` records reuse existing record families; the `/harness-upgrade` SKILL documents them, but older third-party parsers of the stdout contract (none known) would treat them as unknown kinds.
- README test-count badges now track ps-side captured counts (308 / 90); QA should re-confirm tallies on its own runs (insight 2026-06-04 — numbers here are from my captured runs, command list below).

## Verification commands + observed results

All run on this machine (Windows 11, Git-Bash + pwsh), 2026-06-11 — every tally above is from these runs:

```
bash .harness/scripts/sync-self.sh --check          # In sync.
bash .harness/scripts/verify_all.sh                 # 32/0/0
pwsh -NoProfile -File .harness/scripts/verify_all.ps1   # 32/0/0
bash .harness/scripts/test-harness-upgrade.sh       # 76/0
pwsh -NoProfile -File .harness/scripts/test-harness-upgrade.ps1  # 77/0
bash .harness/scripts/test-init.sh                  # 270/0
pwsh -NoProfile -File .harness/scripts/test-init.ps1    # 308/0
bash .harness/scripts/test-real-project.sh          # 90/0
pwsh -NoProfile -File .harness/scripts/test-real-project.ps1  # 90/0
bash .harness/scripts/test-supervisor.sh            # 45/0
pwsh -NoProfile -File .harness/scripts/test-supervisor.ps1    # 49/0
bash .harness/scripts/test-verify-i6.sh             # 58/0
pwsh -NoProfile -File .harness/scripts/test-verify-i6.ps1     # 58/0
bash .harness/scripts/test-language.sh              # 39/0
pwsh -NoProfile -File .harness/scripts/test-language.ps1      # 39/0
```

## Dev-map updates

No files/modules added, moved, or removed — only capability descriptions refreshed:
`docs/dev-map.md` lines for `migrate-scripts-layout.{ps1,sh}` (×2 occurrences), `upgrade-project.{ps1,sh}` (×2), and `test-harness-upgrade.{ps1,sh}` now mention the v0.31 gated rewire / placeholder repair / terminal congruence scan (exit 4) / new fixtures.

## Insight to surface (optional)

- `skills/harness-status/SKILL.md`'s §1 asset rows are structurally pinned by `test-supervisor.{ps1,sh}` "doc fan-out" asserts — retiring/editing a status asset row silently breaks test-supervisor even though no design/fan-out list names that coupling · evidence: `.harness/scripts/test-supervisor.sh:390-395` (pre-fix 2-assert failure on the T-020 §6.7 row removal)

## Verdict

READY FOR REVIEW

## Rework round 1 (after 05_CODE_REVIEW.md verdict REWORK)

> Note on provenance: the rework developer agent landed all code below but was killed by a
> stream-idle API error before writing this section; the PM inspected the tree, attributed
> the changes, and ran the verification itself. All tallies below are PM-observed runs.

### MAJOR [LOGIC/B8] — fixed

`migrate-scripts-layout.{sh,ps1}` (template source + dogfood mirror, 4 files): the terminal
congruence scan now reads its text per mode — apply mode re-reads the WRITTEN file from disk
(`scan_text="$(cat "$settings")"` sh / `Get-Content $settings -Raw` ps1, the
`upgrade-project` S6 pattern); dry-run keeps the in-memory projection. A settings write that
never lands (read-only file, disk full, AV lock) is now caught by the scan → explicit
`CONGRUENCE-FAIL` + exit 4 — the FR-P1 silent-dangle window is closed and the
"disk is ground truth" comment is true in both shells. The B9 additive-only dry-run
projection asymmetry is documented in the same comment block (reviewer MINOR 2).

### New driver probe — Fixture M3 (B8 write-failure half)

`test-harness-upgrade.{sh,ps1}`: read-only `settings.json` fixture — moves succeed, the
settings write fails, the run must NOT print success / exit 0; asserts CONGRUENCE-FAIL names
the still-legacy on-disk path and that the failed write left settings untouched on disk.
Gracefully SKIPs where read-only cannot be enforced (e.g. running as root).

### Optional review notes taken

- MINOR 3: `upgrade-project.{sh,ps1}` REWIRE record detail string → `(hook command paths)`.
- NIT 1: dead `$movedAny` removed from `migrate-scripts-layout.ps1`.
- MINOR 2: B9 asymmetry documented in the helper comment (see above).

Not taken (out of rework scope, routed per review): `docs/tasks.md` row (PM-owned, at
delivery); pre-existing template usage-header paths (OQ-4 follow-up); sh/ps E.4b output
cosmetics.

### Rework verification (PM-observed, 2026-06-11)

```
sync-self --check            In sync.
test-harness-upgrade.sh      PASS: 79   FAIL: 0   (was 76; +2 M3 probes, +1 M-fixture assert)
test-harness-upgrade.ps1     PASS: 80   FAIL: 0   (was 77)
verify_all.sh                PASS: 32   WARN: 0   FAIL: 0
verify_all.ps1               PASS: 32   WARN: 0   FAIL: 0
```

## Verdict (rework round 1)

READY FOR RE-REVIEW
