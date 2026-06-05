# 03 — Gate Review · scripts-relocation (T-007)

**Mode:** full (7-stage). Stage 3 of 7. Upstream: RA verdict = RESOLVED (6/6 Qs answered), SD verdict = READY.
**Reviewer stance:** independent verifier — every load-bearing design claim was checked against the live repo (file reads + Glob + Grep), not trusted.

> Persisted verbatim by PM: the gate-reviewer agent is read-only (`tools: Read, Glob, Grep`, same enforceable-boundary principle as the supervisor, insight L25), so it returned its review as its final message and the PM persists it here.

## 1. Audit checklist (8 dimensions)

| # | Dimension | Verdict | One-line reason |
|---|---|---|---|
| 1 | Requirement completeness | **PASS** | AC-1..AC-6 each name a concrete command or observable file state; §10 binds all 6 open questions to single choices. |
| 2 | Design completeness | **PASS** | Every R-bucket (R1-R9) maps to enumerated files with verified line ranges; §6 gives a safe edit order through the bootstrapping wrinkle. |
| 3 | Reuse correctness | **PASS** | `git mv`, sync-self mapping loop, harness-sync scope, test-init harness, and verify_all parse-pattern all verified to exist at the cited paths and to be reusable as claimed. |
| 4 | Risk coverage | **PASS** | The 7 design risks plus 4 self-flagged DESIGN-RISKs cover the real hazards (stale hook, partial sweep, PS/Bash asymmetry, fixture flip, data-file disposition, MIGRATION history, settings re-serialize). |
| 5 | Migration safety | **PASS** | Helper is idempotent, writes timestamped `.bak` before editing, has `-DryRun`, surgical substring-replace (no re-serialize), and is reversible by `git revert` (repo) / `.bak` restore (user). |
| 6 | Boundary handling | **PASS** | Empty/absent `scripts/`, already-migrated no-op, collision in `.harness/`, fail-open hook window, PS/Bash symmetry, placeholder whitelist, `-NoProfile` preservation all addressed in RA §4 + SD §3/§8. |
| 7 | Test feasibility | **PASS** | Each AC is mechanically verifiable (run a script / `git grep` / inspect tree); see §3 for the one nuance on AC-2(c). |
| 8 | Out-of-scope clarity | **WARN** | Scope boundaries are explicit (SD §10), but the template move-count arithmetic is wrong (see F-1) — a developer trusting "16" / "10 common" may chase a non-existent file. |

## 2. Adjudication of the 4 self-flagged DESIGN-RISKs

**RISK A (insight-index evidence citations) — ACCEPTED. Design is correct.**
Every `scripts/...` hit in `.harness/insight-index.md` sits *after* the `· evidence:` marker (lines 20, 22, 23, 24, 26, 27, 29 — 7 evidence lines contain a `scripts/` token; design said "6", a trivial undercount, not a hazard). These are historical pointers into post-fix commit states. Path-only rewrite (leave line numbers; they shift post-move) is correct. No over-rewrite hazard: I.6 (verify_all.ps1:515-523) scans for retired-claim *anchors*, not path literals, and does not scan insight-index for paths. Accept.

**RISK B (MIGRATION.md append-not-rewrite) — ACCEPTED. Design is correct.**
MIGRATION.md:45-47 documents the v0.2 `scripts/ harness-sync` step — rewriting it would falsify past history. I.6 block comment (verify_all.ps1:513) literally states "MIGRATION.md is NOT exempt", but appending a relocation section won't trip I.6 (no banned literal). Defer confirmation to the verify_all run (insight L23/L28 — let the matcher decide). Accept.

**RISK C (no standing "script-reappears-under-scripts/" guard) — ACCEPTED, with documented residual gap → CONDITION C-1, not a blocker.**
- F.1 (verify_all.ps1:271 / .sh:285) only asserts scripts EXIST at `.harness/scripts/`; it does NOT fail if a duplicate reappears under `scripts/`.
- E.1 (sync-self) fails only on drift between `.harness/scripts/` and `templates/common`; a stray `scripts/verify_all.ps1` would not make sync-self drift.
- AC-4 git-grep is a one-time QA action, not a standing gate (architect concedes).
- So the design's "F.1 + AC-4 + E.1 suffice" is slightly overstated: only the *init* regression vector is gated (by the flipped test-init AC-1), the *repo-hygiene* vector (a human re-adds `scripts/foo.ps1`) is not — but that residual is cosmetic/inert (nothing invokes it). Adding a new verify_all check is out-of-scope per RA §3. **Do NOT build a new guard here**; a belt-and-suspenders repo-side guard is deferred to a separate follow-up task. The one gate that matters → C-1.

**RISK D (E.1/E.2 PS-vs-Bash path asymmetry) — ACCEPTED. Table edits the right side.**
PS `verify_all.ps1:195/:201` invoke via `Join-Path $PSScriptRoot ...` → `$PSScriptRoot` auto-resolves to the new dir; only FAIL-*message* text at :196/:202 changes. Bash `verify_all.sh:193/:200` use EXPLICIT `$repo_root/scripts/sync-self.sh` / `harness-sync.sh` → real path edits required, plus messages at :196/:203. The L13 trap is handled correctly. Accept.

## 3. Independent checks

- **AC verifiability:** all mechanically testable. Nuance: **AC-2(c)** (Stop-hook session-end sync) is observable but not headlessly scriptable; AC-2(a) F.2-parse + AC-2(b) destructive-call-block are scriptable and together prove wiring. → F-4 (QA execution note).
- **Bootstrapping wrinkle:** §6 order is sound — verify_all moves (step 1), self-checks retargeted (step 3) before the gate first runs (step 8); transiently red between 3-8 but never *un-runnable* (`$PSScriptRoot` self-locates). PASS.
- **Hook fail-OPEN safety:** the live `.claude/settings.json` four targets are `:4` doc string, `:9` permission, `:24` Stop command, `:27` PreToolUse command — each a self-contained string. A case-sensitive raw substring `-creplace`/`sed` on `scripts/harness-sync.` / `scripts/guard-rm.` preserves `$schema`, key order, and `_comment`/`_doc_sync_hook` doc keys byte-for-byte (re-serialize would reorder/strip — correctly avoided). Corruption-resistant (substring is path-internal, matches `./`-prefixed or extra-flag variants); already-migrated → substring-not-found → no-op (idempotent); `.bak-<ISO8601>` gives reversibility. Sharp edge → F-2.
- **Move surface (own Globs):** repo `scripts/*` = **24** (matches inventory file-for-file); template `templates/**/scripts/*` = **15** (`common/scripts/` = 9: harness-sync×2, install-hooks×2, archive-task×2, guard-rm×2, ai-native-mock.json×1; + 3 stacks × 2 verify_all tmpl = 6). Design's "10 common / 16 total" is off by one (F-1); enumeration itself is complete. Nothing outside the buckets.
- **CLAUDE.md red line:** correctly handled — live `.claude/settings.json` = PROPOSE-ONLY (Developer surfaces diff, user applies); `settings.json.tmpl` + `SKILL.md:149-150` recipe = DIRECT edit. PASS.

## 4. Findings (all WARN/NOTE — none blocks, none routes back as a hard fix)

- **F-1 (WARN, dim 8) — owner solution-architect (SD §2 R2).** Template count wrong: `common/scripts/` = **9** not "10", total template moves = **15** not "16". File *list* is correct; only arithmetic is off. Fix the count. Non-blocking.
- **F-2 (WARN, dim 5) — owner solution-architect (SD §3).** Helper's settings.json replace scope ambiguous: §3 names 3 sites (2 commands + permissions.allow), but a whole-file substring replace also hits the `:4` `_doc_sync_hook` doc string (4th site). Both safe; spec should state which so the AC-5 regression asserts the right end-state. Non-blocking.
- **F-3 (WARN, dim 3) — owner solution-architect (SD §2 R6).** R6 doesn't explicitly list `harness-sync.ps1`'s own internal self-reference message (`harness-sync.ps1:111`). Caught by AC-4's exhaustive git-grep backstop, so it won't be missed; R6 prose should name it. Non-blocking.
- **F-4 (NOTE, dim 7) — owner qa-tester (execution).** AC-2(c) not headlessly scriptable; rely on AC-2(a)/(b) for mechanical proof, treat (c) as manual smoke.

## 5. High-probability developer questions (pre-answered)

1. **PS verify_all E.1/E.2 invocation path edit?** No — `$PSScriptRoot` self-locates (`:195/:201`); only FAIL-message text at `:196/:202` changes. The BASH peer (`verify_all.sh:193/:200`) DOES need explicit `$repo_root/scripts/...` → `.../.harness/scripts/...` edits. (RISK D — do not flatten the two shells.)
2. **Edit `.claude/settings.json` directly?** No — propose-only. Surface a diff changing ONLY the `scripts/`→`.harness/scripts/` path segment in the four hits (`:4,:9,:24,:27`); user applies. Keep `-NoProfile`; do not touch `$schema` (`:2`) or `hooks` keys. `settings.json.tmpl` + `SKILL.md:149-150` recipe ARE direct-edit.
3. **How many template files move?** 15 (F-1): `common/scripts/` = 9 + 6 stack `verify_all.{ps1,sh}.tmpl`. Move all; delete each emptied `scripts/` dir.
4. **Will MIGRATION.md append / insight-index path rewrite trip I.6?** No — I.6 scans retired-claim anchors, not path literals. Confirm by running verify_all at step 8 (don't hand-reason — L23/L28).
5. **harness-sync after the move?** Only because R3 edits two `.harness/agents/*.md` (pm-orchestrator, qa-tester) — run `harness-sync` after so `.claude/agents/*` re-mirror (else E.2 FAILs). Moved scripts are OUTSIDE harness-sync scope (`harness-sync.ps1:5-6,34-79`) — `.harness/scripts/` is not copied to `.claude/`; Layer-2 otherwise untouched.

## 6. Conditions (must hold during development)

- **C-1 (from RISK C):** the flipped `test-init` AC-1 assertion ("generated tree contains no harness file under `scripts/`, and `scripts/` is absent") MUST be present and MUST FAIL if init writes any `scripts/` file. This is the one standing gate that closes the init-regression vector; a broader repo-side reappearance guard is deferred to a separate task.
- **C-2 (from F-2):** resolve the settings.json replace scope (3 sites vs whole-file incl. doc string) and assert the chosen end-state in the AC-5 regression.
- **C-3 (general):** run BOTH `verify_all.ps1` AND `verify_all.sh` at §6 step 8 (Git-bash via `git.exe` root per L27, not the WindowsApps stub) — a PS-only run hides bash path bugs (L13/L24).

## 7. Verdict

The requirement is complete and unambiguous; the design is a faithful, line-verified implementation contract. All four self-flagged DESIGN-RISKs are correctly reasoned (A/B/D fully correct; C's "existing checks suffice" is slightly overstated but the residual gap is low and correctly deferred). The four findings are all WARN/NOTE — cosmetic count errors and a spec ambiguity, none of which blocks coding or routes back as a hard requirement/design defect. Conditions C-1..C-3 are development-time obligations, not gate blockers.

**GATE VERDICT: APPROVED FOR DEVELOPMENT**
Reason: Requirement and design are complete and line-verified; all 4 DESIGN-RISKs adjudicated (A/B/D correct, C's residual gap is low and correctly deferred), only WARN/NOTE findings, gated by 3 development-time conditions C-1..C-3.
