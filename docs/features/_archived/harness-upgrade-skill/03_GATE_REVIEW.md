# 03 — Gate Review: `/harness-upgrade` skill (T-012)

> Stage 3 (Gate Reviewer). Independent verification of `01_REQUIREMENT_ANALYSIS.md`
> (READY on the resolved OQ baseline) + `02_SOLUTION_DESIGN.md` (READY). Every
> load-bearing design claim was checked against live code.
> Persisted by PM (Gate Reviewer is read-only: `tools: Read, Glob, Grep`).

## A. Verification of the design's load-bearing claims (verified against real code)

| # | Design claim | Verification | Result |
|---|---|---|---|
| V1 | Skill SOT is `skills/<name>/` only; `.harness/skills/` absent (§2) | `Glob .harness/skills/**` → none; `Glob .claude/skills/*/SKILL.md` → none; `plugin.json:24` = `"skills": "./skills/"`; `Glob skills/*/SKILL.md` → exactly 12 | **CONFIRMED** |
| V2 | C.1/G.1/G.2 scan `skills/<name>/SKILL.md`, hardcoded 12-skill arrays (§2, §7.1) | `verify_all.ps1:68` (C.1), `:300` (G.1), `:326` (G.2); `verify_all.sh:56/59`, `:330/333`, `:346/349` — all hardcoded 12-name arrays + "12 skills" step names | **CONFIRMED** |
| V3 | L31 root-derivation table (§3.3) | `harness-sync.ps1:21-23` two-up; `harness-sync.sh:15-16` two-up; `install-hooks.ps1:19-20` two-up; `migrate-scripts-layout.ps1:28-29` cwd; relocation known-set `migrate-scripts-layout.ps1:42-49` matches design exactly | **CONFIRMED** |
| V4 | B.* delimiter is not byte-stable across types/shells (§6.1) | generic-sh `# --- B. Build / test / lint ...` end `# --- E.`; generic-ps `# --- B. Build / test ...`; fullstack-sh `B. Build / test (require package.json)` end `# --- C.`; backend-ps `B. Build / test (require manifest...)` end `# --- C.` — START text AND END boundary both vary | **CONFIRMED — splice-on-heuristic genuinely unsafe** |
| V5 | `HARNESS:B-CUSTOM` markers are valid in both shells, no `{{...}}` (§6.1, §6.4) | Proposed literals are `#`-prefixed (valid PS + bash comment), contain no `{{...}}` → D.2 (`verify_all.ps1:94-98` scans only `{{...}}`) untouched | **CONFIRMED** |
| V6 | 6 verify_all templates exist (§6.1) | `Glob` → generic/fullstack/backend × {ps1,sh}.tmpl = exactly 6 | **CONFIRMED** |
| V7 | Check count stays 32; G.4 count is dynamic, not hardcoded (§7.3) | `verify_all.ps1:643` `$count = $report.Count + 1`; `Grep "^Step \""` = 32 `Step` calls. Adding to F.1 name-list adds no `Step` → count unchanged | **CONFIRMED — "32 stays" is correct by construction** |
| V8 | G.4 forces CHANGELOG `[version]` heading + version-claim sites (§7.2) | `verify_all.ps1:638-640` reads version dynamically; `:680` requires `[$version]` in CHANGELOG; claim-site table `:653-664` is the authoritative count/version-claim list | **CONFIRMED** |
| V9 | `sync-self` already mirrors `migrate-scripts-layout`; adding `upgrade-project` is consistent (§4.2) | `sync-self.ps1:51-52` + `sync-self.sh:77-79` both mirror migrate-scripts-layout; structurally symmetric | **CONFIRMED** |
| V10 | Settings rewire is raw-text, no re-serialize (§3.2 S3, DO-3) | `migrate-scripts-layout.ps1:87-112` — 3× `.Replace` + `.harness/.harness/` collapse fixed-point + `.bak`, no `ConvertFrom/To-Json` | **CONFIRMED** |
| V11 | install-hooks stock body is a fixed literal usable for S4 detection (§3.2 S4) | `install-hooks.ps1:35-63` here-string referencing `.harness/scripts/harness-sync.{ps1,sh}` | **CONFIRMED (with caveat — see F-4)** |
| V12 | F.1 is a selective (not count-anchored) pair list (§7.3) | `verify_all.ps1:270-274` / `verify_all.sh:285-289` list 7 pairs; guard-rm/archive-task/install-hooks/migrate-scripts-layout are NOT in F.1 → adding `upgrade-project` is name-only | **CONFIRMED** |
| V13 | `CLAUDE_PLUGIN_ROOT` cache-discovery (§5 step 1) | `Grep CLAUDE_PLUGIN_ROOT` → appears in NO repo file except the design doc; `/harness-adopt` (the cited precedent, SKILL.md:171) does NOT use it, uses glob fallback | **UNVERIFIED ASSUMPTION — see F-3** |
| V14 | dogfood verify_all is bespoke (not template-generated), needs no markers (§6.1) | `verify_all.ps1:1` "Verification for the harness-engineering repo itself" | **CONFIRMED** |
| V15 | helper template path + I.6 exempt mechanism (§4.2, §8) | `migrate-scripts-layout.{ps1,sh}` present at `templates/common/.harness/scripts/`; I.6 exempt list `verify_all.ps1:516-525` with `test-verify-i6` precedent + `docs/features/` dir exempt | **CONFIRMED** |

## B. 8-dimension audit

| # | Dimension | Result | Reason |
|---|---|---|---|
| 1 | Requirement completeness | **PASS** | All 13 behaviors + 15 BCs are testable; the 10 OQs are resolved in PM_LOG with concrete defaults; AC-13 correctly branches on the OQ-3 resolution. |
| 2 | Design completeness | **PASS** | §13 traceability maps every AC-1..15 to a concrete mechanism; §3 gives an exit-code + stdout contract precise enough to implement; §6.2 fully specifies the verify_all refresh algorithm. |
| 3 | Reuse correctness | **PASS** | Reuse audit (§10) verified row-by-row against live code: relocation (`migrate-scripts-layout:42-85`), settings rewire (`:87-112`), stock hook (`install-hooks:35-63`), sync-self extension (`:51-52`), all confirmed present and reusable as described. |
| 4 | Risk coverage | **PASS** | R1 (the #1 L31 root-derivation risk) is correctly identified and mitigated by S2; R5 (fan-out drift) is named High — and is exactly where my findings land; R2/R3/R4/R6/R7/R8 each map to a real, verified mechanism. |
| 5 | Migration safety | **PASS** | OQ-2(c) clean-tree precondition + `.bak` for the two untracked surfaces; every tracked edit is `git revert`-able; idempotent fixed-point rewire verified at `migrate-scripts-layout.ps1:95-101`. |
| 6 | Boundary handling | **PASS** | BC-1..15 each have a handler in §3.1/§3.2; §8 fixtures exercise dirty-tree, custom-hook, custom-verify, non-cc, no-harness, idempotent-rerun, dry-run, cross-shell. |
| 7 | Test feasibility | **PASS** | Every AC has a §8 fixture; AC-5 (the L31 fix) is directly exercised by "invoke relocated harness-sync, must find root"; exit codes 0/1/2/3 make AI branching deterministically testable. |
| 8 | Out-of-scope clarity | **WARN** | OOS-1..7 + §12 are explicit and strong. WARN only because the README placement nuance (harness-upgrade is NOT a 7th "task shape") is implicit, not stated — a developer could wrongly bump "six task shapes" (see F-2). |

## C. Findings

Severity legend: **BLOCKING** = must fix before Dev; **ADVISORY** = Dev must know, not gate-blocking.

### F-1 — `02_SOLUTION_DESIGN.md` §7.1 skill-count fan-out list is INCOMPLETE (ADVISORY, but high-recurrence)

Concerns: `02_SOLUTION_DESIGN.md` §7.1 (lines 450-462). The §7.1 table is the project's #1 recurring failure surface (insight-index L14). Grepped every `12 skills` / `twelve` / `12 个` token in the live tree and cross-checked against §7.1. Sites carrying a stale skill-count phrase that §7.1 does NOT explicitly list:

| Missed site | Live content | In §7.1? |
|---|---|---|
| `docs/getting-started.md:36` | "Either path makes **twelve** skills available" | No — §7.1 cites only getting-started `:38-57` (the bullet list), not the `:36` count word |
| `docs/manual-e2e-test.md:7` | "load the **twelve** skills" | No — §7.1 cites only `:34`, `:49` |
| `docs/manual-e2e-test.md:60-62` | "the **twelve** `/harness-*` commands appear" + an explicit 12-command enumeration | Partially — §7.1 says "add to the enumerations" but does not flag the "twelve" count word at `:60` |
| `.harness/rules/40-locations.md:30` | "All **12** skills present with valid frontmatter" | No — not listed at all |
| `AI-GUIDE.md:71` and `docs/dev-map.md:134` | sync-self prose "4 mirrored script pairs" (already stale: omits migrate-scripts-layout; will also omit `upgrade-project`) | No |

**Gate-impact assessment (important nuance):** NONE of these missed sites is enforced by `verify_all`. C.1/G.1/G.2 check skill *names* (not count phrases) and read only `skills/`, README, CHANGELOG; G.4 reads getting-started/manual-e2e-test/40-locations only for the `(N checks)` count (which stays 32). **So this finding is ADVISORY, not BLOCKING** — `verify_all` will PASS even if these are left stale. But it is exactly the human-visible "count drift left in one file" class that requirement **AC-15** and **DO-4** mandate, and that L5/L14 record as the recurrence vector. Routing: design-doc completeness gap → **solution-architect** if the PM wants §7.1 amended; otherwise the Developer must treat §7.1 as a floor and run a literal `12|twelve|十二|12 个` sweep at the end.

### F-2 — README "six task shapes" must NOT become "seven"; harness-upgrade is a Setup skill (ADVISORY)

Concerns: `02_SOLUTION_DESIGN.md` §7.1 line 457. `README.md:15` reads "**Pipeline skills (six task shapes...)**". `/harness-upgrade` is a maintenance/Setup skill (sibling of init/adopt), NOT a pipeline task-shape. The "12 skills → 13" / "twelve AI skills → thirteen" count must move; the "**six task shapes**" phrase must stay six. Same categorization for `getting-started.md:38-57` (group it under "Setup", not "Pipeline"). Developer must place the bullet in the Setup group and leave task-shape counts untouched. No upstream re-route.

### F-3 — `CLAUDE_PLUGIN_ROOT` is an unverified runtime assumption (ADVISORY)

Concerns: `02_SOLUTION_DESIGN.md` §5 step 1 (lines 308-309). The claim "Claude Code exposes the active plugin root to skills" via `CLAUDE_PLUGIN_ROOT` has zero corroboration in this codebase, and the cited precedent `/harness-adopt` does not use it. Risk to flag, not a blocker — the design correctly puts it first-with-fallback and the glob fallbacks (§5 steps 2-3) reproduce the proven adopt-era discovery (`harness-adopt/SKILL.md:171`), which suffices alone. Developer constraint: do NOT make the skill depend on `CLAUDE_PLUGIN_ROOT`; the glob chain must be load-bearing, BC-5 (halt-on-unresolvable) is the floor. Optionally confirm the SDK env-var contract via context7 (`/websites/code_claude`); absence must be harmless.

### F-4 — Old (pre-T-007) stock hook body for S4 detection is not preserved in-repo (ADVISORY)

Concerns: `02_SOLUTION_DESIGN.md` §3.2 S4 (lines 183-191). S4 detects a "stock hook" by byte-matching TWO known bodies: the current `.harness/scripts/harness-sync.*` body AND "the old `scripts/harness-sync.*` variant". The current body is at `install-hooks.ps1:35-63`; the **old** body is not present anywhere in the live tree. The Developer must reconstruct it (same here-string with `scripts/harness-sync.` instead of `.harness/scripts/harness-sync.`) and prefer normalizing the path prefix before comparing over maintaining two full literal copies. No re-route.

### F-5 — Minor line-citation imprecision in §7.1 (ADVISORY)

Concerns: `02_SOLUTION_DESIGN.md` §7.1. The `verify_all.sh` step-name strings that read "All 12 skills" are at `:59` (C.1), `:333` (G.1), `:349` (G.2); the design cites the *loop* lines `:56/:330/:346`. Intent is captured; cosmetic — but the Developer must edit BOTH the loop array AND the adjacent step-name string in each shell, in both files. Re-Read after each Edit (insight L10 / design R8).

## D. Adjudication of the two items the Architect flagged (§15)

**(a) Adding `HARNESS:B-CUSTOM` delimiters to the six templates vs. heuristic-boundary splicing — CORRECT CALL, ENDORSED.** Verified the B.* region boundaries across templates: the START comment text varies AND the END boundary varies (`# --- E.` for generic but `# --- C.` for fullstack/backend). Heuristic splicing is a guess against a moving target — the R2 partial-splice failure the baseline rejected. Stable literal delimiters are the right, deterministic, cross-shell-byte-identical choice. The triggered obligation (six templates change shape → `test-init` output changes) is identified by the design (§11) and is in the rollout sequence (§11 step 7). Dogfood verify_all correctly gets no markers (bespoke, `verify_all.ps1:1`). **No concern.**

**(b) Keeping the recorded check count at 32 (no new lettered check) — CORRECT CALL, ENDORSED.** Verified G.4 derives `$count` dynamically as `$report.Count + 1` (`verify_all.ps1:643`); live `Step` count is exactly 32. A new skill is version-worthy (L33) but a new check requires a new `Step`; the two new artifacts are adequately covered without one: the skill by C.1/G.1/G.2/C.2; the helper pair's byte-identity by **E.1** (once in `sync-self`), its existence optionally by **F.1** (name-only, zero count impact). Keeping 32 means the `(32 checks)`/`32/32`/`verify__all-32%2F32` sites all stay — no G.4 movement, no L36 hazard. **No concern.**

## E. Feasibility & completeness spot-checks

- **AC↔mechanism coverage:** Spot-checked AC-5 (root two-up → §3.3 + S2 unconditional byte-overwrite — the only mechanism that actually fixes L31; a path-string sweep would NOT), AC-13 (B.* preserve → §6.2 SPLICE / HALT-`--force`, both fixtures in §8), AC-3 (settings rewire → verbatim `migrate-scripts-layout:87-112`, DO-3-safe). Genuinely covered.
- **OQ-3 hard constraint:** §6.2's matrix satisfies it exactly — clean-delimiter+customized → verbatim SPLICE; no-clean-delimiter+customized → HALT (exit 2) for explicit `--force`; always `.bak`. Pure-merge never used. **Satisfied.**
- **Idempotence:** §6.2 step 4 NOOP-on-identical + verified fixed-point rewire (`migrate-scripts-layout.ps1:95-101`) + relocation SKIP-unless-Force (`:63-66`) converge. **Satisfied (AC-6).**
- **Cross-shell parity:** Every new artifact is a symmetric pair; parity testable via §8 parity fixture; E.1 + F.1 enforce the helper pair. **Satisfied (AC-10 / NFR-1).**
- **Insights → Dev constraints:** L13/L27 → R7 + DO-7/DO-8; L10 → R8. Adequately converted. Note: insight-index L12 ("sync-self mirrors 4 pairs") and AI-GUIDE:71/dev-map:134 prose are themselves stale (live sync-self mirrors 5 pairs incl. migrate-scripts-layout) — design correctly trusted live code; prose refresh folded into F-1.

## F. High-probability developer questions (pre-answered)

1. **"Do I create `.harness/skills/harness-upgrade/`?"** No. Skills ship from `skills/<name>/` only (`plugin.json:24`); no `.harness/skills/`, no `.claude/skills/` sync. SOT = `skills/harness-upgrade/SKILL.md`. (V1.)
2. **"Does adding the skill add a verify_all check / move the 32 count?"** No. Check count = live `Step` count (`verify_all.ps1:643`); only adding a `Step` moves it. Add `upgrade-project` to F.1 as name-only (optional, recommended). 32 stays; only skill count 12→13 + version 0.23.0 move. (V7/V12.)
3. **"Which files carry the skill count?"** Design §7.1 PLUS the F-1 additions: `verify_all.{ps1,sh}` C.1/G.1/G.2, `AI-GUIDE.md:7`, `README.md:7,13`+bullet, `README.zh-CN.md:7,13`, `getting-started.md:36`(+bullet under Setup), `manual-e2e-test.md:7,34,49,60`+enumeration, `dev-map.md` skills tree, `.harness/rules/40-locations.md:30`, `CHANGELOG.md` `[0.23.0]`. Then run `verify_all` (G.1/G.2/G.4) as backstop. Leave "six task shapes" (README:15) untouched (F-2).
4. **"Where do I get the old stock hook body?"** Current `install-hooks.ps1:35-63` here-string with prefix `scripts/harness-sync.` instead of `.harness/scripts/harness-sync.`. Prefer normalizing the prefix before comparison. (F-4.)
5. **"What if `CLAUDE_PLUGIN_ROOT` isn't set?"** Best-effort only; the glob fallback chain (§5 steps 2-3, mirroring `harness-adopt/SKILL.md:171`) is load-bearing; BC-5 (halt-with-message) is the floor. (F-3.)

## G. Verdict

**APPROVED FOR DEVELOPMENT.**

The design is sound, code-grounded, and implementable from §3/§6/§7/§8. Every load-bearing claim was verified against live code. Both Architect-flagged decisions (B.* delimiters; check count stays 32) are correct and endorsed. The two design corrections vs. the PM brief (single-surface skill model; no D.2/no-new-check) are accurate and important.

**0 BLOCKING**, **5 ADVISORY** (F-1..F-5). None causes `verify_all` to FAIL as designed — but F-1 is the historically #1 recurrence vector (L5/L14): Developer must treat design §7.1 as a *floor*, execute a final literal `12|twelve|十二|12 个` + `0.22.0` repo-wide sweep before declaring done (covering the five extra sites), and run `verify_all` G.1/G.2/G.4 twice (after the count sweep, and after the version bump).

**Top 3 things Dev must not lose sight of:**
1. **L31 / R1 — content-refresh (S2), not just relocation.** A relocated-but-not-refreshed depth-sensitive script silently resolves the wrong root. S2 must unconditionally byte-overwrite the refresh set; AC-5 must actually invoke a relocated `harness-sync` and prove it finds root.
2. **The fan-out sweep is wider than §7.1 (F-1) and "six task shapes" must stay six (F-2).** Run the literal sweep; place the new skill in the Setup group.
3. **B.* delimiters change the six templates' shape → rerun `test-init` (§11 step 7)** alongside the new `test-harness-upgrade` and `verify_all` until all green (32/32, skill count 13).
