# 03 — Gate Review · T-14 `hook-truth-status`

**Mode**: `full` · **Stage**: 3 (gate-reviewer) · **Date**: 2026-07-31
**Inputs audited**: `01_REQUIREMENT_ANALYSIS.md` (verdict `READY`), `02_SOLUTION_DESIGN.md` (verdict `READY`)
**deferred-human mode**: defer, do not ask — no `AskUserQuestion` was called.
**Method**: every design claim citing existing code was re-read at the cited path. Tool set available was `Read`/`Glob`/`Grep` only — **no run tallies are reported here**; anything settleable only by execution is marked as such.

> Persisted by PM Orchestrator: the gate-reviewer agent contract carries no `Write` tool, so it returned the
> review as text and PM wrote it here verbatim. No PM edits to the content.

## 1. Independent verification of the design's factual claims

| # | Design claim | Verified at | Result |
|---|---|---|---|
| V-1 | Only behavioral edit is `skills/harness-status/SKILL.md` | grep `harness-status` repo-wide (78 files) — every live non-archived hit is a skill-index line, a name array, or a task-board row | **Confirmed** (see F-8 for an adjacent, out-of-FR observation) |
| V-2 | No distributed template copy of this skill exists | `skills/harness-init/templates/**/skills/**` → only `build`/`test`/`verify` `SKILL.md.tmpl` under `backend/` and `fullstack/` | **Confirmed** |
| V-3 | `.claude/skills/` empty — nothing to sync | `.claude/**` → only `settings.json`, `settings.local.json` | **Confirmed** (directory does not exist at all) |
| V-4 | Structural pin is one line, `SKILL.md:34-37` | `test-supervisor.sh:394` `grep -qE '\(7 \+ supervisor\).*plugin-provided'` (per-line); `test-supervisor.ps1:436` `-match` over `-Raw` (`.` does not match `\n` in PS either, so same-line is required) | **Confirmed** — identical one-line constraint in both shells |
| V-5 | Second assertion is an absence assertion | `test-supervisor.sh:397` `grep -qF '{pm,req,sol,gate,dev,review,qa}*'` inverted; `test-supervisor.ps1:438-440` same | **Confirmed** — currently absent; nothing this design writes reintroduces it |
| V-6 | No other driver assertion matches rewritten text | `harness-status` in `*.sh` → `install.sh:150`, `test-supervisor.sh:388-399`, `verify_all.sh:56,339,355`. In `*.ps1` → `install.ps1:152`, `verify_all.ps1:69,315,341`, `test-supervisor.ps1:429-439`. `Safety hook` / `scripts missing` / `DISABLED —` appear in **no** driver | **Confirmed** |
| V-7 | Retired string has exactly one live occurrence | `skills/harness-status/SKILL.md:68,78`; all other hits are `docs/features/**` (I.6-exempt dir) | **Confirmed** |
| V-8 | I.6 banned list has no settings/hooks anchor | `verify_all.sh:531-546` — 14 entries, all CLAUDE.md-composition / adopt / zh-policy | **Confirmed** |
| V-9 | G.3 compares exactly four stamps | `verify_all.sh:373-377` — `plugin.json`, `marketplace.json`, `README.md` badge, `README.zh-CN.md` badge | **Confirmed**, matches §9 Branch B's named set exactly |
| V-10 | G.4 requires a CHANGELOG heading for the manifest version | `verify_all.sh:714,790-792` (`grep -qF "[$g4_version]"`) | **Confirmed** |
| V-11 | OQ-6 tripwire state | `.claude-plugin/plugin.json:4` = `0.45.0`; `CHANGELOG.md:8` = `## [0.45.0] - 2026-07-31`; `.git/packed-refs` newest tag `v0.44.0` → `cb0ed57` (= HEAD); **no `v0.45.0` tag, packed or loose** (`.git/refs/tags/**` empty) | **Branch A is live** |
| V-12 | F.2 precedence shape | `verify_all.sh:303-308` — machine-local wins on substring `"PreToolUse"`, else committed | **Confirmed**; the stated §0-vs-F.2 divergence is real and correctly assigned to T-15 |
| V-13 | Repair-path asymmetry (FR-8) | `upgrade-project.sh:248-357` touches `.claude/settings.json` only — no `settings.local` reference anywhere in the file; `install-hooks.sh:38` documents the removal; `install-hooks.sh:159-162` returns early on presence alone | **Confirmed** (see F-3) |
| V-14 | hook-spec supports the query plan | `hook-spec.sh:18-32` (contract), `:120` (`tools` order: harness-sync, guard-rm, ambient-prompt, ambient-reset), `:83-95` (`matcher guard-rm`→`Bash`, `semantics guard-rm`→`fail-closed`) | **Confirmed**; §3.2's fallback order is order-identical to the spec's `tools`→`event` mapping, so §3c row order does not change between spec and fallback |
| V-15 | Worked trace on this repo | `.claude/settings.local.json:5` has 4 hook keys → `present`; `:16-25` PreToolUse / `"matcher": "Bash"` / `sh -c '… && bash .harness/scripts/guard-rm.sh'` (space-preceded ⇒ left-bounded pattern matches); `.claude/settings.json:21` `"hooks": {}` → `empty` ⇒ `OTHER_DECLARES=false` | **Confirmed** — AC-1/AC-2 reachable; §5.1 line 1 is the expected form |
| V-16 | `test-supervisor` bash expectation 45 | `baseline.json:16` | **Confirmed as the recorded baseline** (a run is Dev/QA's to produce) |
| V-17 | No doc-size gate covers this skill | `verify_all.sh:384-448` — I.1 AI-GUIDE, I.2 `.harness/rules/*`, I.3 `agents/*`, I.4 insight-index, I.5 `docs/tasks.md`; `70-doc-size.md` has no `skill` cap | **Confirmed** — §0 may grow the skill without risking a WARN |
| V-18 | R-10 insight rotation | `.harness/insight-index.md` holds **exactly 30** evidence lines (I.4 WARNs at `>30`); `archive-task.sh:59,74-104` rotates when `total_after > 30` | **Confirmed** — safe only via `archive-task` |
| V-19 | 14 asset rows / denominator 12 | `SKILL.md:19-32` = 14 rows; `:144,149` | **Confirmed** |
| V-20 | CONTEXT.md already carries both new terms | `CONTEXT.md:84-93` | **Confirmed** — the OUT entry is right |

## 2. Audit checklist

| # | Dimension | Verdict | Reason |
|---|---|---|---|
| 1 | Requirement completeness | **PASS** | All 20 FRs are testable statements about printed output; all 20 boundaries name a required behavior; all ten OQs carry binding recommendations, adopted verbatim. No unverifiable criterion exists. |
| 2 | Design completeness | **FAIL** | §3.3's decision table does not define the guard verdict when the command yields **more than one** extracted path, and never requires the tested path to be a `guard-rm.{ps1,sh}` path — **F-1**. Two smaller gaps at **F-2**/**F-3**. |
| 3 | Reuse correctness | **WARN** | Every cited symbol exists at the cited path (V-12…V-14, V-19). But the "verbatim reuse of `settings_hook_state`, can never disagree" claim is false on three input classes (**F-4**), and the "unchanged" extraction pattern is quoted with different bytes (**F-5**). |
| 4 | Risk coverage | **PASS** | R-1, R-3, R-4, R-6, R-9, R-10 are the real risks and each was verified live above. R-2 names the correct hard-reject class; the design simply has a hole in its own mitigation (F-1). |
| 5 | Migration safety | **PASS** | No schema, no persisted artifact, no runtime toggle to flag; rollback is `git checkout` of two files and is genuinely complete. The OQ-6 tripwire is checkable and its Branch A precondition holds today (V-11). |
| 6 | Boundary handling | **WARN** | B-1…B-8, B-10…B-13, B-15…B-20 each have a rule and (except B-17/B-20) a probe. **B-9** and **B-14** have rules but no probe *and* no pinned output string — **F-7**. Null/absent/empty/unreadable/`.claude/`-absent are handled explicitly by Steps 0.1-0.4; concurrency n/a (read-only). |
| 7 | Test feasibility | **WARN** | AC-1/AC-2 reachable against real state (V-15); AC-3…AC-9, AC-12 executable as written; AC-10's bash half executable and its PS half correctly not claimed. AC-11 is executable only with a pre-edit `git status` baseline §10.1 never requests (Q-4). P-19 is discipline-based, not mechanically enforceable, and must be disclosed as such. |
| 8 | Out-of-scope clarity | **PASS** | §12's ten items, §7.3's per-row OUT reasons, and the enumerated frozen-decoy set (incl. the "14 required assets" HEALTH denominator, `baseline.json:11`, archived HTML) make over-building hard; T-15/T-16 boundaries are stated consistently in three places. |

## 3. Findings

### F-1 — **FAIL** · design · §3.3 rows 6-8 admit a false-green and are agent-dependent

§3.3 separates *detection* (substring `guard-rm.ps1`/`guard-rm.sh` anywhere in the command) from *extraction* (the existing left-bounded pattern, which is name-agnostic — `skills/harness-status/SKILL.md:97-99` extracts **every** script path in the command, not the guard's). The table then says row 7 = "Extracted path does not exist", row 8 = "Extracted path exists" — singular, with no rule for multiple paths and no requirement that the tested path be the guard's.

1. **Multiplicity is undefined.** For `sh -c 'cd "$CLAUDE_PROJECT_DIR" && bash .harness/scripts/guard-rm.sh && bash .harness/scripts/harness-sync.sh'` with `guard-rm.sh` deleted, one extracted path is missing and one exists. Rows 7 and 8 are both defensible readings — a direct FR-18 breach — and one of them reports `INSTALLED AND WIRED` **on a guard that does not exist and, being fail-closed, blocks every Bash tool call**. That is precisely the NFR-1 hard-reject direction R-2 claims to close. §3c already solves this ("`ok` — **every** extracted path exists", `SKILL.md:110`); §3b silently drops the quantifier.
2. **The tested path need not be the guard.** A command mentioning `guard-rm.sh` anywhere (comment, echo, wrapper argument) while wiring a different, existing script satisfies detection and yields an existing extracted path ⇒ row 8, healthy. Row 6's own rationale shows the guard-specific reading was intended, but the table's text does not encode it.

**Closes with**: pin that the guard verdict evaluates the *set* of paths the left-bounded pattern extracts from the guard entry's command, and restate rows 6-8 with quantifiers — row 6 when the set contains no `guard-rm\.(ps1|sh)` path; row 7 when **any** path is missing (printing which); row 8 only when **all** extracted paths exist **and** ≥1 is a `guard-rm` path. Add a `P-6b` chained-command probe and the matching §5.2 string.

### F-2 — **WARN** · design · §3.5 leaves the §1 guard row's `Present?` predicate undefined

§3.5 rewrites the *Path* cell but never states what `Present?` shows across the eight rows, nor how it interacts with §6's `All 14 required assets present → +6`. FR-17 supplies the row's condition, which is deliberately **weaker** than the `+1` condition (row 8 only) — so a dangling guard would show the row present (feeding `+6`) while §3b prints `WIRING DANGLING`. Defensible, but it is an unaided judgment call, which FR-18 forbids. **Closes with**: one sentence in §3.5.

### F-3 — **WARN** · design · §5.3's `machine-local` fix line is unconditioned on the other candidate

Verified at `install-hooks.sh:152-155`: the installer exits 0 with "Committed settings already declares lifecycle hooks - no machine-local file created" whenever the committed file is `present`. So in the B-3/FR-4 arrangement with a dangling machine-local guard, `rm .claude/settings.local.json && .harness/scripts/install-hooks` performs the removal and then **no-ops** — the second half of the instruction, and its printed rationale, are wrong in that branch. The removal alone does re-resolve to the committed file, so this is misleading rather than destructive, but FR-8 is absolute. No probe covers it: P-10 flips machine-local *vs* committed, never both-declare. **Closes with**: a fourth §5.3 row for `SOURCE_KIND = machine-local ∧ OTHER_DECLARES = true`, plus a P-10 variant.

### F-4 — **WARN** · design · the "verbatim reuse of `settings_hook_state`" claim is inaccurate in three places

§3.1 Step 0.1 ("the same four-state vocabulary and the same empty/present boundary … so the report and the installer can never disagree") and §7.1 ("Reuse the vocabulary **and** the empty/present boundary verbatim") do not survive a read of `install-hooks.sh:69-94`:

- the installer's third state is spelled **`unparseable`**, not `unreadable`;
- a path that exists but is **not a regular file** returns **`present`** (`install-hooks.sh:74-76`), whereas the design maps it to `unreadable` — as **B-7 requires**;
- the installer never parses; it is a byte probe (`:78-93`), so a byte-broken file that merely starts `{` and ends `}` is `empty`/`present` there, while the design requires it to `parse` ⇒ `unreadable` — again as B-7 requires.

The design's *behavior* is correct and requirement-mandated; the *claim* is wrong, and it is load-bearing — a Developer resolving a conflict in favour of "reuse verbatim" over the Step 0.1 table ships a B-7 violation. **Closes with**: restating it as "same vocabulary and same empty/present boundary for well-formed files; deliberately stricter on non-regular and non-parsing files, per B-7", and dropping "can never disagree".

### F-5 — **WARN** · design · the "unchanged" extraction pattern is quoted with different bytes

§3.3/§7.1 say the pattern is reused **unchanged** and §3.4 says it is byte-preserved, but the design writes `(^|["' =])(\.harness/)?scripts/<name>\.(ps1|sh)` while the live text at `skills/harness-status/SKILL.md:98` has an unescaped `.` before `(ps1|sh)`. Semantically harmless; the Developer must be told which byte-form ships.

### F-6 — **WARN** · requirement wording · NFR-4's literal cap is exceeded (adjudicated acceptable — §4)

The plan is `1 + N + 2` = 7 invocations for four ids; NFR-4's wording allows `1 + N` = 5. A real breach of a binding NFR's text — record it as an accepted deviation with the RA wording corrected at archive time, **not** as "no deviation intended" (§13).

### F-7 — **WARN** · design · B-9 and B-14 have rules but no probe and no pinned output string

§3.3 requires the report to state **how many** guard entries matched (B-9) and to print the interpreter with its fail-closed consequence (B-14, FR-10). Neither string is in §5.2's pinned list and neither has a probe in P-1…P-19. §13's "a probe or an explicit rule" claim is literally true, but QA has nothing to assert, so FR-9's multiplicity note and FR-10 ship unverified. **Closes with**: two §5.2 lines and two probes — or an explicit "rule-only, audited by inspection" note in §10.2, which is legitimate but must be *stated*.

### F-8 — **INFO, not a blocker, not a routing target** · three live docs carry a stale T-12 hook-location claim

`AI-GUIDE.md:110`, `docs/getting-started.md:180-182` and `.harness/rules/60-tool-handoff.md:72-74` each state the Stop hook lives in `.claude/settings.json` — false in this repo since T-12. These are further consumers of the same relocation, but none describes **where the health report reads hook wiring from**, so FR-20 does not reach them and the OUT ledger is correct to exclude them. Recommend PM open a backlog row rather than widen T-14.

## 4. Adjudication of the two interpretation notes

**D-1 (FR-14 as a precondition gate on FR-5's "exactly three states") — FAITHFUL READING. Accept.** The requirement itself already demands more than three outputs in the §3b slot: FR-12 requires a never-installed sentence and forbids reporting it as the guard being switched off, FR-13 requires a *different* opt-out sentence, and FR-14 requires an `unknown` outcome with no point and no healthy claim. None is a member of the FR-5 triple, and FR-5's triple is defined purely in terms of *the effective hook source* — which does not exist in the FR-12/FR-13 branches and is untrustworthy in the FR-14 branch. The 8-row table with rows 1-3 preempting rows 4-8 is the only reading satisfying FR-5, FR-12, FR-13 and FR-14 together. AC-4 stays testable because its probes carry no unreadable candidate. **No rollback to requirement-analyst.**

**D-2 (NFR-4 as O(1)-per-id) — FAITHFUL IN INTENT, BUT A LITERAL BREACH. Accept as a recorded deviation (F-6).** The two extra queries are genuinely required: FR-9 obliges a canonical-matcher comparison the report must not restate, and FR-10 obliges the fail-closed consequence, which `75-safety-hook.md` and `hook-spec semantics` own (insight 2026-06-20 forbids restating it). `hook-spec.sh:18-32` confirms there is no combined query, and changing the spec is out of scope. NFR-4's stated purpose — bounded added work, no repository-wide scan — is fully preserved by a constant `+2`. The choice is right; only the framing is wrong. Developer should state the actual count (`N+3`, 7 today) in `04_IMPLEMENTATION.md` so QA can assert it.

## 5. Direct answers to the seven gate questions

1. **Edit ledger completeness** — the "only behavioral edit" claim **survives** (V-1, V-2, V-3, V-6, V-7). No template copy exists; no live doc states where the health report reads hook wiring from; the retired string has exactly one live occurrence. The only adjacent live falsehoods are F-8's three T-12 stragglers, outside FR-20's scope. **No missed fan-out site found.**
2. **Structural pin** — **correctly identified**, and the one-line constraint is real in *both* shells (V-4): bash matches per line, and PowerShell's `-match` over `-Raw` cannot cross `\n` without `(?s)`. The absence assertion (V-5) is unaffected. Nothing in `test-supervisor`, `test-init`, `test-real-project`, `test-harness-upgrade`, `test-verify-i6` or `verify_all` matches rewritten text (V-6). A guard-row edit is *expected* green — settled by §10.1 step 3's run, not by this reasoning.
3. **D-1 / D-2** — §4: D-1 faithful; D-2 faithful in intent but a literal NFR breach that must be labelled. Neither routes back to the requirement-analyst.
4. **AC feasibility** — the §0 procedure is executable with `Read`/`Glob`/`Bash` against a fixture root outside the repo (§10.2 already parameterises every path on `R`). AC-1/AC-2's pinned strings are reachable against real current state (V-15). **No AC is unverifiable as specified**, with three qualifications: AC-1's outcome is contingent on F-1 closing first; AC-11 needs a pre-edit `git status` baseline §10.1 does not request (Q-4); P-19 rests on QA discipline and must be disclosed rather than reported as a mechanical pass. Probe coverage of B-1…B-20 is complete except B-9 and B-14 (F-7).
5. **Gate-safety claims** — all **hold**. Check count 32, no new check, no I.6 entry (V-8), no new `test-supervisor` assertion; no `.ps1` in the edit set; F.2 untouched and correctly deferred to T-15 (V-12). The OQ-6 tripwire is well-formed and **Branch A is live** (V-11); Branch B's four stamps are exactly what G.3 compares (V-9). One addition the design misses: **AC-9's `WARN 0` depends on the delivery insight landing via `archive-task`** — the index sits at exactly 30 lines and I.4 WARNs above 30 (V-18).
6. **False-green risk** — **a path exists** (F-1). Rows 1-5 and the `SOURCE`-less rows are sound and correctly ordered; the hole is entirely at the row 6/7/8 boundary.
7. **Under-specification for a Developer** — F-1 (quantifier over extracted paths), F-2 (`Present?` predicate), F-3 (fix-line branch), F-5 (which regex bytes ship) and F-7 (two required outputs with no pinned string) are the five places where two competent agents can legitimately diverge. Everything else in §3.1/§3.3/§5 is first-match-wins and pinned.

## 6. High-probability questions during development (pre-answered)

**Q-1 — "Two extracted paths. Which decides the verdict?"** *Unresolved — this is F-1, the blocking finding.* Do not guess.

**Q-2 — "Do I mark the §1 `PreToolUse hook` row present when the wiring is dangling?"** *Pre-answered, pending F-2's pin:* FR-17 defines the row's condition as a guard-referencing `PreToolUse` entry in the effective hook source ⇒ rows 5-8 present, row 4 and rows 1-3 not present. It deliberately differs from the `+1` point, which FR-17 restricts to row 8. Do **not** move the row count (14) or the denominator (12); both frozen (V-19).

**Q-3 — "Can I clean up QA fixtures with `rm -rf` outside the repo?"** *Pre-answered:* No, not silently. The guard resolves `$repoRoot` as the nearest `.git/` ancestor of **cwd** (`.harness/rules/75-safety-hook.md:58-62`), so with cwd inside this repo any destructive verb targeting a scratch path outside it is BLOCKED — fail-closed. Fixture teardown and the P-6 "delete the guard script" mutation need `HARNESS_ALLOW_OUTSIDE_RM=1` on that call (`guard-rm.sh:60-61`), which emits an auditable stderr INFO line. Plan for it; do not "fix" the guard.

**Q-4 — "`git status --porcelain` already shows T-13's changes. How do I satisfy AC-11?"** *Pre-answered:* capture `git status --porcelain` **before the first edit** into `04_IMPLEMENTATION.md`; AC-11 is the *delta*, which must contain only §7.3's IN set. §10.1 step 5 does not ask for this — do it anyway or the criterion is unfalsifiable.

**Q-5 — "Where does the delivery insight go? The index looks full."** *Pre-answered:* into `07_DELIVERY.md`'s `## Insight` section, landing via `.harness/scripts/archive-task`, which rotates at `total_after > 30` (`archive-task.sh:74-104`). The index holds exactly 30 evidence lines, so a **hand-appended** line makes I.4 WARN and breaks AC-9's `WARN 0`. Never hand-edit it.

**Q-6 — "CHANGELOG: new heading or subsection?"** *Pre-answered:* Branch A, verified live (V-11) — no `v0.45.0` tag and the manifest still reads `0.45.0`, so add a `### Fixed — hook-truth-status (T-14): …` subsection under `## [0.45.0] - 2026-07-31` and **move no version stamp**. Re-run §9's tripwire at delivery anyway; if flipped, Branch B's four stamps are `plugin.json`, `marketplace.json` and both README **version** badges (`verify_all.sh:373-377`) — never the test-init badge or `baseline.json:11`.

**Q-7 — "Do I need to touch `test-supervisor.ps1`?"** *Pre-answered:* No, and if you think you do, **stop**. Both shells assert the same two conditions and both are preserved by construction (V-4, V-5). If a delivered edit flips either match state, §10.1 step 6's escalation applies — touching the `.ps1` adds an operator PowerShell obligation (NFR-5) and is a scope change. Concretely: do not re-wrap, re-word or split `skills/harness-status/SKILL.md:34-37`, and do not reintroduce the `{pm,req,sol,gate,dev,review,qa}*` glob anywhere in that file.

## 7. Verdict

**BLOCKED ON DESIGN** → route to `harness-kit:solution-architect`.

One FAIL (**F-1**): §3.3's rows 6-8 admit an `INSTALLED AND WIRED` verdict on a guard that would not run, and are agent-dependent under a multi-path hook command. NFR-1 ranks that direction as a hard reject and FR-18 forbids the ambiguity, so it cannot be waived into development as a condition — it is the exact defect class the task exists to prevent, in the one table the whole design routes through.

The rollback is small and surgical. Nothing else in the design is unsound: the reuse audit checks out against the real files, the structural pin is correctly identified in both shells, the edit ledger survives an independent fan-out sweep, the gate-safety claims are verified live, and both interpretation notes are faithful readings. **No requirement gap was found — do not route to requirement-analyst.**

Close in the same architect pass: **F-1** (blocking), **F-2**, **F-3**, **F-4**, **F-5**, **F-7**, and relabel **F-6** as an accepted, recorded deviation from NFR-4's literal wording. Each is a one-paragraph edit to §3.3, §3.5, §5.2, §5.3, §7.1, §10.2 or §13. On their return this gate expects to issue `APPROVED`.

---

Key files this review turned on: `skills/harness-status/SKILL.md` (lines 32, 68, 78, 97-110, 144-149), `.harness/scripts/install-hooks.sh` (69-94, 152-162), `.harness/scripts/test-supervisor.sh` (394-399), `.harness/scripts/test-supervisor.ps1` (435-441), `.harness/scripts/verify_all.sh` (303-308, 373-377, 384-448, 531-546, 700-800), `.harness/scripts/hook-spec.sh`, `.claude/settings.local.json`, `.git/packed-refs`.

---

# Round 2 — Delta Re-review · T-14 `hook-truth-status`

> Persisted verbatim by PM Orchestrator (gate-reviewer has no `Write` tool). No PM content edits.

**Mode**: `full` · **Stage**: 3 (gate-reviewer), round 2 · **Date**: 2026-07-31
**Input audited**: `02_SOLUTION_DESIGN.md` revised in place (verdict `READY`, `## 14 Round 2 — gate findings closed`), against round 1's F-1…F-8 in this file.
**Scope**: delta only. Round-1 confirmations V-1…V-20 (reuse audit, structural pin in both shells, edit-ledger fan-out sweep, gate-safety claims, OQ-6 Branch A) are carried forward and were **not** re-derived; where a round-2 edit re-cited one of those files, the new citation was re-read.
**deferred-human mode**: defer, do not ask — no `AskUserQuestion` was called.
**Method**: `Read`/`Glob`/`Grep` only. **No run tallies are asserted anywhere in this review** — every count claim below is a document/source-text claim, never an execution result.

---

## R2-1. Per-finding closure verification

| Finding | R1 severity | Closed? | Independent verification this round |
|---|---|---|---|
| **F-1** | **FAIL** | **YES** | See §R2-2 in full. Table is now total, mutually exclusive and quantified; both round-1 defect classes are unreachable. |
| **F-2** | WARN | **YES** (one gloss nit) | §3.5 pins `Present?` = §3.3 rows 5-8, **not** present in rows 1-4 — both halves stated exhaustively over all eight rows, so no row is left to judgment, and the deliberate asymmetry with the row-8-only `+1` is stated in the report's own output. Nit: the parenthetical gloss "(i.e. `SOURCE` exists and `K ≥ 1`)" is *not* equivalent under row 1 — Step 0.2 continues resolution, so `SOURCE` can exist with `K ≥ 1` while row 1 (`UNKNOWN`) fires and the row is **not** present. The explicit row lists govern and are exhaustive, so the gloss cannot be read to override; recorded, not blocking. |
| **F-3** | WARN | **YES** | §5.3 gains the fourth row keyed on `machine-local ∧ OTHER_DECLARES = true`. Evidence re-read at **`.harness/scripts/install-hooks.sh:152-155`** — the range is exact: `152 if [ "$committed_state" = "present" ]; then` / `153 echo "Committed settings already declares lifecycle hooks - no machine-local file created."` / `154 exit 0` / `155 fi`. The quoted message is byte-accurate (ASCII hyphen). The `OTHER_DECLARES = false` branch's rationale is still true, verified at `:159-162` (`settings_hook_state "$local_settings" != absent` ⇒ early exit). §5.3's four rows are pairwise disjoint and total over `SOURCE_KIND × OTHER_DECLARES × MACHINE_STATE`, so no ordering rule is needed. **P-10b** is coherent: the new fix line contains no literal `.harness/scripts/install-hooks`, so its absence assertion is satisfiable. |
| **F-4** | WARN | **YES** | The "verbatim / can never disagree" claim is withdrawn in **both** load-bearing places (§3.1 Step 0.1 and §7.1 row 2). The two divergence rows re-verified against source: non-regular file ⇒ `present` at `install-hooks.sh:74-76` (reads nothing); byte probe at `:78-93` never parses, so a `{…}`-shaped broken file is `empty`/`present` there; the installer's third state is spelled `unparseable` (`:79,81,89`). The tie-rule citation `:63-65` is accurate (step 4 of the header comment is the deciding byte). The conflict rule — **"A Developer must follow the table below, not the installer's source; the table wins any conflict"** — is present and unambiguous, which was the whole point of the finding. Behavior is unchanged from round 1, as claimed. |
| **F-5** | WARN | **YES** | §3.3's byte-form pin quotes, inside a fence, `(^\|["' =])(\.harness/)?scripts/<name>.(ps1\|sh)` — compared character-by-character against the live `skills/harness-status/SKILL.md:98`: identical, including the escaped `\.` in `\.harness/` and the **unescaped** `.` before `(ps1|sh)`. "Copy that line, do not retype it" plus the explicit "do not fix the dot" removes the last degree of freedom. §7.1 row 4 now carries the same pin. |
| **F-6** | WARN (relabel) | **YES** | §3.2 D-2 now reads **ACCEPTED DEVIATION from NFR-4's literal wording** with the arithmetic stated (`1+N+2` = 7 vs `1+N` = 5), the unavoidability argument, the constant-`+2` safety argument, and a disposition that correctly assigns the RA wording correction to an agent permitted to edit `01_…` at archive time. Verified the unavoidability premise at source: `hook-spec.sh:117-124` dispatches `tools` / `event|matcher|semantics` as separate arities with **no combined query**; `hs_semantics guard-rm` ⇒ `fail-closed` (`:90-95`); `hs_matcher guard-rm` ⇒ `Bash` (`:83-88`). §13 carries the same label. |
| **F-7** | WARN | **YES** (one residual, F-11) | Both rules now have pinned strings **and** probes: §5.2 **(b)** `guard entries matched: 1` / `<K> — first in document order evaluated (from <SOURCE>)` with **P-20** (including an order-flip leg that makes the "document order, not content" rule falsifiable); §5.2 **(c)** both interpreter forms with **P-21**, which additionally asserts the §3.3 row is unchanged by interpreter availability (B-14). Nothing is left rule-only. Residual: see **F-11**. |
| **F-8** | INFO | **YES** | Recorded at §12.11 as explicitly out of scope, quoting the gate's own reason, with a `Developer must not edit these three files` instruction and the backlog hand-off to PM. It was **not** folded into the §7.3 ledger — correct. |

---

## R2-2. F-1 in detail — is the table deterministic and false-green-free?

**Totality and mutual exclusion.** Rows 1-8 partition the input space: rows 1-3 are `SOURCE`-less/preempting; row 4 is `K = 0`; rows 5-8 all presuppose `K ≥ 1`; row 5 is the placeholder case; and because `GUARD_PATHS ⊆ PATHS`, `GUARD_PATHS ≠ ∅ ⇒ PATHS ≠ ∅`, so rows 6 / 7 / 8 are exactly `GUARD_PATHS = ∅` / `≠ ∅ ∧ ∃ missing` / `≠ ∅ ∧ ∀ exist`. No input falls through, and no input matches two rows under first-match-wins. **FR-18 is satisfied at the table level: every row selector is a set-membership or existence test with no judgment step.**

**Round-1 defect class 1 (multiplicity) — closed.** The chained-command example now lands on row 7 deterministically because the quantifier ranges over `PATHS`, not over "the extracted path". Verified that this is the *same* quantifier §3c already applies — `skills/harness-status/SKILL.md:110` reads "`ok` — every extracted path exists" — so §3b and §3c can no longer return contradictory answers for one command, which was the sharpest form of the round-1 objection.

**Round-1 defect class 2 (tested path need not be the guard) — closed for the class as stated.** Row 8 now carries `GUARD_PATHS ≠ ∅` as a precondition, so detection-by-substring alone can never buy the health point. **P-6c** pins the direction with a fixture (`echo checking guard-rm.sh; bash …/harness-sync.sh`) whose mention is deliberately non-extractable ⇒ row 6.

**Probes pin what the table claims.** P-6b exercises three mutations of one fixture (delete guard-rm.sh ⇒ row 7; restore it and delete the chained script ⇒ still row 7; restore both ⇒ row 8 with the `all 2 extracted paths exist` form). Each leg is derivable from the table and each is falsifiable. P-6c's expected string matches §5.2 (a)'s row-6 line byte-for-byte, and P-6b's expected strings match the row-7 multi-missing and row-8 multi-path forms. The §5.2 strings and the §3.3 rows agree on wording in every one of the six verdict forms I compared.

**AC-1's expected bytes — verified against real state.** `.claude/settings.local.json:16-25` holds exactly one `PreToolUse` entry, matcher `"Bash"`, command `sh -c 'cd "$CLAUDE_PROJECT_DIR" 2>/dev/null && bash .harness/scripts/guard-rm.sh'`. Applying the pinned left-bounded pattern to that command: the only `scripts/` occurrence is the space-preceded `.harness/scripts/guard-rm.sh`; `cd "$CLAUDE_PROJECT_DIR" 2>/dev/null` contributes nothing. Therefore **`|PATHS| = 1`, `GUARD_PATHS = PATHS`, `K = 1`** — the single-path row-8 form fires and the verdict line's bytes are unchanged from round 1, as the architect claims. Two precise qualifications for QA: (i) the `|PATHS| > 1` row-8 form is unreachable on this repository, so P-1 cannot exercise it — P-6b's third leg is its only coverage; (ii) P-1's *transcript* now additionally carries the two newly pinned adjunct lines (`guard entries matched: 1`, `interpreter: sh (on PATH)`), which were required behavior under FR-9/FR-10 before round 2 but were unpinned. AC-1's own text constrains only the verdict and the named source, so this is not a movement of AC-1.

**Residual, disclosed as F-9 below**: the design's property-2 sentence states an absolute ("never row 8") that a narrow input class defeats. It does **not** reopen F-1 — see F-9's disposition.

---

## R2-3. The `all of PATHS` quantifier against FR-11

FR-11 has two clauses. Both survive:

1. *"tests the existence of the script path extracted from the wired command"* — every member of `PATHS` is, by construction, a path the pattern extracted **from `GUARD_ENTRY.command`**. The quantifier therefore tests only paths FR-11 authorises; it resolves an underdetermination in FR-11's singular phrasing (the RA never confronted a multi-path command — FR-5's table is singular in the same way) rather than contradicting it. Retaining `GUARD_PATHS ≠ ∅` as the precondition for reaching rows 7-8 keeps the *guard-specific* character FR-11 requires.
2. *"Presence of the other shell twin is not a precondition"* — a twin can never enter `PATHS`, because `PATHS` is derived from the command text alone. OQ-4a is preserved and **B-13 stays satisfiable**: a wired `.ps1` with only `.sh` on disk yields `PATHS = {scripts/guard-rm.ps1}` ⇒ row 7, which is exactly what B-13 / P-16 require ("verdict follows the referenced path").

**False-red on a legitimate arrangement — one class exists, and it is bounded.** A hook command using the fail-open idiom the non-guard hooks ship (`[ -f X ] && exec bash X || exit 0`, `hook-spec.sh:111`) references a script whose absence is harmless; under the `all of PATHS` quantifier such a command yields row 7 `WIRING DANGLING` although the guard runs. Assessment: (a) the direction is healthy→dangling only, which NFR-1 ranks as the less severe defect; (b) it introduces **no new class relative to shipped behavior** — `SKILL.md:110` already applies the identical quantifier to those very commands in §3c today; (c) row 7 prints the command verbatim and the missing path, so FR-7's evidence requirement makes the output truthful and self-diagnosing rather than a bare wrong verdict. The design's *justification* for the quantifier (§3.3 property 3: "the shipped guard form carries no `|| exit 0` fallback … so a non-zero from any link makes the fail-closed hook block") is verified true of the shipped form (`hook-spec.sh:108-109`, `.claude/settings.local.json:22`) but is narrower than the rule it justifies. Recorded as part of **F-9**; it does not make the rule wrong, only its stated warrant narrower than universal.

---

## R2-4. The three gate additions

| Addition asked for in round 1 | Landed at | Verified |
|---|---|---|
| Pre-edit `git status --porcelain` baseline | **§10.1 step 0** (new) | Present, correctly framed as the *delta* basis, names `## Pre-edit tree baseline` in `04_IMPLEMENTATION.md`, explains the T-13 uncommitted-tree reason, and instructs QA to report AC-11 as **unverifiable** rather than pass it if step 0 is skipped. Step 5 and §10.2's whole-repo line both re-point at the baseline. Closed. |
| Never hand-edit `.harness/insight-index.md` | **§10.1 step 5b** + §10.2 | Present and binds Developer **and** QA, with the correct diagnosis order ("revert the hand-edit, don't raise the cap"). Re-verified the premise this round: the index carries **exactly 30** evidence lines (counted by pattern over `.harness/insight-index.md`), and the design's `archive-task.sh:59,74-104` rotation citation is carried forward from V-18. Closed. |
| Fixture teardown needs `HARNESS_ALLOW_OUTSIDE_RM=1` | **§10.2** (new paragraph) | Present and correct at source: `.harness/rules/75-safety-hook.md:58-62` confirms `$repoRoot` is the nearest `.git/` ancestor of **cwd**; `guard-rm.sh:60-62` confirms the override is per-call and emits an auditable stderr INFO line. The paragraph correctly scopes the override to *that single call*, names both consumers (teardown and the P-6/P-6b delete mutation), requires the override lines be pasted into `06_TEST_REPORT.md`, and states that working around the guard is a delivery-blocking NFR-1 event. Closed. |
| (fourth, from round-1 audit item 7) P-19 disclosed as discipline-based | §10.2 P-19 | Present, with the tool list actually used required alongside and an explicit "never as a mechanical pass". Closed. |

---

## R2-5. No-regression check on round 2 itself

| Claim | Result |
|---|---|
| §7.3 edit ledger unchanged | **Holds in substance.** IN is still the same four rows (`skills/harness-status/SKILL.md`, `CHANGELOG.md`, `docs/features/hook-truth-status/*`, `docs/tasks.md` at stage 7). Every round-2 artifact lands either inside `02_SOLUTION_DESIGN.md` itself, inside stage docs (already IN), or in scratch fixtures **outside** the repo per §10.2. No round-2 edit adds an IN row, and every OUT row and frozen-decoy row round 1 verified is still present with its reason intact. I cannot byte-diff against round 1 (the document was revised in place and no round-1 copy exists) — the claim is verified by content, not by diff. |
| Check count still 32 | Stated consistently in the header (line 12), §9, §12.4 and §13, with no new check anywhere in the document. **Asserted as a document claim only — no run.** |
| No new I.6 entry | Holds: §5.2's retired-string note, §7.3 OUT row and §12.4 all decline it, consistent with OQ-9a and the four-file-lockstep insight (`insight-index.md:15`). |
| No new `test-supervisor` assertion | Holds: §7.3 OUT row, §12.4, OQ-7a, and §10.1 step 6's escalation rule unchanged. |
| No `.ps1` touched | Holds. Checked the round-2 additions specifically: **P-21's** fixture places a `pwsh …` command **string** inside a fixture settings JSON and asserts a PATH lookup — it executes no PowerShell, so it adds no NFR-5 obligation and no operator-list item. P-16 likewise. §9's PowerShell paragraph is unchanged. |
| F.2 and the four derivation flows untouched | Holds: §7.3 OUT rows + §12.1 / §12.2, unchanged; the stated §0-vs-F.2 divergence is still assigned to T-15. |
| No new dependency / script / gate check | Holds. The only additions are prose, four §5.2 string forms, one §5.3 row, one risk row (R-2b), five probes (P-6b, P-6c, P-10b, P-20, P-21) and three §10 paragraphs. |
| F-8 recorded out-of-scope, not folded in | Holds — §12.11, with the ledger explicitly **not** widened and the AC-11 reason given. |
| OQ-6 Branch A state | §9's tripwire is unchanged and remains the delivery-time check. Branch A's liveness was verified in round 1 (V-11) and is **not** re-asserted here — the Developer re-runs the tripwire at delivery, per §9. |

---

## R2-6. Round-2 findings (all non-blocking)

### F-9 — **WARN** · design · §3.3 property 2 states an absolute the syntactic model cannot deliver

§3.3's second numbered property reads: *"A command that merely mentions `guard-rm.sh` (in a comment, an `echo`, a wrapper argument) while wiring some different, existing script satisfies detection but yields `GUARD_PATHS = ∅` ⇒ row 6, never row 8."* That holds only when the mention is **not** in an extractable, left-bounded, path-shaped form. A command such as `sh -c 'cd "$CLAUDE_PROJECT_DIR" && echo see .harness/scripts/guard-rm.sh && bash .harness/scripts/harness-sync.sh'` yields `GUARD_PATHS ≠ ∅`, all of `PATHS` exists, and lands on **row 8 — `INSTALLED AND WIRED`, `+1`** — on a command that never invokes the guard.

Disposition, stated precisely so it is not misread as a reopening of F-1:

- It is **not** a regression from round 2 and **not** a defect the closure introduced — round 1's table admitted the same input and worse.
- It is **not** closable within this task's authority: distinguishing an executed command position from a quoted/echoed one requires shell-grammar analysis, which FR-11 (existence of *the extracted path*) and FR-18 (no judgment about intent) do not authorise and which §12.3's boundary excludes.
- It is **not** reachable through any wiring the harness generates: `hook-spec.sh:99-114` emits exactly four literal shapes, none of which mentions a path it does not execute.

What is actually wrong is the *sentence*, not the table: an unqualified "never row 8" is a claim QA could be asked to assert and could not. Carried as a **condition** (see §R2-8), not a rollback.

### F-10 — **WARN** · design · the matcher adjunct is undefined on row 4

§3.3 introduces the adjunct block as *"Always-printed adjuncts (in every row except 1-3)"* — i.e. rows 4-8 — but then scopes **(b) multiplicity** and **(c) interpreter** to "rows 5-8" in their own bullets. The **matcher** bullet carries no such qualifier, so on row 4 (`K = 0`, no `GUARD_ENTRY` exists) the header says print it while there is no entry whose matcher could be printed. Two defensible readings — print nothing, or print `matcher: (absent)` — and `(absent)` is defined in §3.3 for *an entry without a matcher key*, not for *no entry*. This is the same FR-18 class as F-2, at much lower stakes (row 4 is already non-healthy, carries no point, and §5.2 (a)'s row-4 line already conveys the absence). Non-blocking; a Developer choice that must be recorded rather than made silently.

### F-11 — **WARN** · design · two derivations for the fail-closed clause in §5.2 (c)

§3.2's query plan spends invocation `N+3` on `hook-spec semantics guard-rm` and D-2's entire NFR-4 deviation argument rests on that query being *necessary* because insight 2026-06-20 forbids the report restating a fact the spec and `75-safety-hook.md` own. But §5.2 (c) pins the sentence *"the guard is fail-closed, so this BLOCKS Bash tool calls…"* as a literal — and §5.2's header states "Slots in `<…>` are substituted; everything else is literal". So the load-bearing word is simultaneously (i) queried from the spec and (ii) hardcoded in the contract string. Verified there is **no output divergence today**: `hook-spec.sh:90-95` returns exactly `fail-closed` for `guard-rm`, so both readings emit identical bytes, and §3.2's fallback already licenses the literal form when the spec is unavailable. The residue is that the `N+3` query becomes decorative under reading (ii), which weakens D-2's own justification for exceeding NFR-4. Low severity; must be settled explicitly rather than left to the Developer.

### F-12 — **INFO** · design · two different line ranges cite one installer fact

The installer's machine-local early return is cited as `:159-162` in §5.3 (the round-2 correction) but as `:156-161` in §3.1 Step 0.4 and §7.1 row 7. Both ranges are truthful — `156-158` is the "keys on PRESENCE alone" comment, `159-161` the `if`/`echo`/`exit 0`, `162` the `fi` — so nothing is false; it is citation inconsistency, not drift. No action required beyond awareness.

### F-13 — **INFO** · design · §5.2's bracketed row keys are annotations, not output

`[row 8, |PATHS| = 1]`, `[row 7, >1 missing]` etc. sit inside the §5.2 (a) fence, whose header declares everything outside `<…>` literal. They are plainly right-hand keys, and the surrounding prose ("keyed to the §3.3 row that fired") supports that, but the header's own rule contradicts it. Trivially resolvable at authoring time; noted so a QA byte-assertion is not written against them.

---

## R2-7. Audit checklist — round 2

| # | Dimension | Verdict | Reason |
|---|---|---|---|
| 1 | Requirement completeness | **PASS** | Unchanged from round 1: 20 testable FRs, 20 boundaries, ten OQs with adopted recommendations. The one literal NFR breach (NFR-4) is now correctly labelled as an accepted deviation with a named correction owner, rather than denied. |
| 2 | Design completeness | **WARN** | The blocking gap is closed: §3.3 is total, mutually exclusive and quantified; §3.5 pins `Present?`; §5.3 covers all four `SOURCE_KIND × OTHER_DECLARES` branches. Two adjunct-level under-specifications remain (**F-10**, **F-11**), neither on a verdict path nor on a safety-relevant row. |
| 3 | Reuse correctness | **PASS** | Every round-2 citation was re-read at source and is accurate: `install-hooks.sh:74-76`, `:78-93`, `:152-155`, `:159-162`, `:63-65`; `hook-spec.sh:90-95`, `:108-109`, `:117-124`; `guard-rm.sh:60-62`; `75-safety-hook.md:58-62`; `SKILL.md:98`, `:110`. The two inaccurate round-1 claims (verbatim reuse, pattern bytes) are withdrawn and replaced by statements that match the code. |
| 4 | Risk coverage | **PASS** | R-2b names the quantifier false-green as its own hard-reject risk with two directional probes, and the round-1 mis-citation of the probe id is corrected. The residual F-9 class is the only reachable false-green left and is inherent to the requirement's syntactic model. |
| 5 | Migration safety | **PASS** | Unchanged: no schema, no artifact, no flag; rollback is a two-file `git checkout`. The OQ-6 tripwire is retained verbatim and remains a delivery-time check the Developer executes. |
| 6 | Boundary handling | **PASS** | B-9 and B-14 now each have a pinned string **and** a probe (P-20, P-21), and P-21 additionally pins the B-14 invariant that the interpreter never selects a row. All twenty boundaries now carry a rule plus a probe except B-17 and B-20, whose rule-only status is stated with reasons. |
| 7 | Test feasibility | **PASS** | AC-11 is now falsifiable (pre-edit baseline, §10.1 step 0); P-19 is disclosed as discipline-based instead of claimed mechanical; fixture teardown's guard interaction is planned rather than discovered mid-run; every new probe (P-6b, P-6c, P-10b, P-20, P-21) is derivable from the table and includes a failing direction. |
| 8 | Out-of-scope clarity | **PASS** | §12 now carries eleven items including the three T-12 stragglers as an explicit do-not-touch, with the AC-11 reason attached — the one place a Developer would plausibly over-build after reading round 1's F-8. |

---

## R2-8. Conditions carried into development

These are conditions on the delivery, not design edits and not a rollback. Each is a one-line statement in `04_IMPLEMENTATION.md`; none changes the shipped report's bytes on this repository.

1. **F-9** — the Developer records the bound of §3.3 property 2: the row-6 guarantee holds for mentions that are not left-bounded extractable paths; an extractable, existing guard path in a non-executing position is a known, out-of-scope residual of the syntactic determination FR-11 mandates. QA asserts **P-6c as written** (non-extractable mention ⇒ row 6) and does **not** generalise it to "any mention".
2. **F-10** — the Developer states whether the matcher adjunct prints on row 4 and, if so, with what value; QA asserts whichever is stated.
3. **F-11** — the Developer states whether §5.2 (c)'s fail-closed clause is substituted from `hook-spec semantics guard-rm` or shipped literal with the spec query retained for the matcher comparison only; the actual invocation count (`N+3`, seven for four ids) is stated in the same place per D-2.
4. Carried from round 1 and now designed-in: §10.1 step 0's pre-edit baseline is a **precondition** for AC-11, and §10.1 step 5b's "never hand-edit `.harness/insight-index.md`" is a precondition for AC-9's `WARN 0`. QA reports either as *unverifiable* rather than passing it if the precondition is missing.

---

## R2-9. Developer questions — round 2 additions

**Q-8 — "Row 6 says `WIRING DANGLING`, but the guard file is fine — is that a bug?"** *Pre-answered:* No. Row 6 is the deliberate landing zone for a wiring whose guard path cannot be verified (absolute path, non-left-bounded form, mention-only). FR-5 admits exactly three states and this is neither *absent* (an entry exists) nor *installed and wired* (nothing verifiable); NFR-1 makes the non-healthy choice mandatory. Print the command verbatim and row 6's own clause so the reader can see why. Do not add a fourth state.

**Q-9 — "The chained hook command references an optional script that this project doesn't ship. Row 7 calls it dangling."** *Pre-answered:* That is the designed behavior and the same answer §3c already gives for the identical command (`SKILL.md:110`). Do **not** narrow the quantifier to `GUARD_PATHS` — that reopens F-1's multiplicity hole. The output is truthful (the path *is* missing) and FR-7's evidence requirement makes it self-diagnosing.

**Q-10 — "Two guard entries, and the first one is a mention-only decoy. The report goes dangling although entry two is healthy."** *Pre-answered:* Correct and intended. `GUARD_ENTRY` is the first in document order (§3.3 detection), the §5.2 (b) adjunct prints `K` and states that the first was evaluated, so the reader is not misled. P-20's order-flip leg is what makes this falsifiable. Do not add "pick the healthiest entry" logic — it is judgment, which FR-18 forbids.

**Q-11 — "`|PATHS| > 1` never happens on this repo. How do I self-check the multi-path row-8 string in step 4?"** *Pre-answered:* You cannot from this repository — `.claude/settings.local.json:22` yields exactly one extracted path. §10.1 step 4's transcript will exercise the single-path forms only; the multi-path forms are QA's, via P-6b's third leg. Do not manufacture a fixture inside the tree to exercise it (AC-11).

**Q-12 — "May I fix the `.` in the extraction pattern while I'm in there?"** *Pre-answered:* No. §3.3's byte-form pin and §7.1 row 4 both require the live `SKILL.md:98` bytes with the unescaped dot. Copy the line; do not retype it.

---

## R2-10. Verdict

All eight round-1 findings are closed. **F-1 is genuinely closed**: the §3.3 table is total, mutually exclusive and quantified over `PATHS` / `GUARD_PATHS`; both round-1 false-green paths are unreachable; the table selects the same row for every input regardless of which agent runs it; the new §5.2 strings and the P-6b / P-6c probes pin exactly what the table claims, in both directions; and the AC-1 byte-stability claim is confirmed against the real `.claude/settings.local.json` (`|PATHS| = 1`, `K = 1`, single-path row-8 form). The broader `all of PATHS` quantifier is faithful to FR-11 — it tests only paths extracted from the wired command, never a shell twin, so OQ-4a and B-13 survive — and its only over-strict class is a disclosed, safe-direction false-red already present in shipped §3c behavior. F-2 through F-7 each landed at the cited section with accurate source evidence, and the three gate additions are present and correct. No round-2 change adds a file, a dependency, a check, an assertion, an I.6 entry or a `.ps1`; the edit ledger, the frozen-decoy set and the out-of-scope boundaries are intact, and F-8 is recorded as out-of-scope rather than folded in.

Three new WARN findings (**F-9**, **F-10**, **F-11**) and two INFO notes remain. None is a verdict-path defect, none is a safety-direction defect, and none is closable by an upstream document better than by a one-line statement during implementation — they are carried as the four conditions in §R2-8. No requirement gap was found in either round; **do not route to requirement-analyst**.

**APPROVED FOR DEVELOPMENT**

---

Files this round-2 review turned on: `docs/features/hook-truth-status/02_SOLUTION_DESIGN.md`, `docs/features/hook-truth-status/01_REQUIREMENT_ANALYSIS.md`, `docs/features/hook-truth-status/03_GATE_REVIEW.md`, `.claude/settings.local.json` (16-25), `skills/harness-status/SKILL.md` (64-124, esp. 97-99 and 110), `.harness/scripts/install-hooks.sh` (38, 54-94, 152-162), `.harness/scripts/hook-spec.sh` (83-95, 99-114, 117-124), `.harness/scripts/guard-rm.sh` (59-63), `.harness/rules/75-safety-hook.md` (50-66), `.harness/insight-index.md` (30 evidence lines).
