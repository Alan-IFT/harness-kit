# Retrieval Eval — v2 migration control set

> **Purpose.** The v2 migration deletes ~70% of harness-kit's bytes and replaces the
> "read the whole document" access pattern with "query it". This file is the only
> instrument that says whether that made retrieval **better or worse**.
>
> Built for P0. Every acceptance bar in P1–P4 scores against it.
> Distinct from [`golden-tasks.md`](golden-tasks.md), which is a manual regression
> checklist for the scaffolding generators — that file is not a retrieval instrument
> and is not superseded by this one.

## Why not a public benchmark

LoCoMo is not usable as a regression signal: a third-party audit found 99 of 1540 items
(6.4%) carry a wrong reference answer, and judge models accept 62.81% of deliberately-wrong
but topically-related responses. A control set drawn from **this repo's own decided history**
has verifiable answers and no judge-model in the loop.

## Scoring protocol

Run each question against the retrieval configuration under test. Record three things:

| Field | Meaning |
|---|---|
| **HIT** | The answer contains the expected fact *and* cites the anchor (or an equivalent). |
| **PARTIAL** | Fact correct, anchor missing/wrong — or anchor right, fact incomplete. |
| **MISS** | Fact absent, or contradicted. |
| **TOKENS** | Input tokens consumed to produce the answer. |

Score = `HIT + 0.5·PARTIAL` over the category's item count. **Report tokens alongside
accuracy — a config that wins accuracy at 4× the tokens has not won.** That trade is the
entire point of the migration.

A configuration is **A** = today (full-document reads), **B** = grep-only baseline,
**C** = CodeGraph (P2), **D** = CodeGraph + memory layer (P3).

Per §5.3 of the brief: **B must be run before C or D is adopted.** Letta measured plain
grep + file reads at 74.0% on LoCoMo against mem0's self-reported 68.5%; a memory backend
that does not beat grep here does not get merged.

## Categories and what they gate

| Cat | Items | Answerable from | Gates |
|---|---|---|---|
| `CODE` | C1–C10 | source structure | **P2** — CodeGraph must beat grep here |
| `MEM` | M1–M12 | decided history (insight-index, rejected-decisions, PM_LOGs) | **P3** — memory layer must beat grep here |
| `RULE` | R1–R8 | methodology + guardrails | **P1** — these must NOT regress after the §9 deletion |
| `STATE` | S1–S6 | per-task progress ledgers | **P4** — the state JSON must reconstruct these |

`RULE` is the safety net for P1: it is the set of facts that must still be retrievable
*after* `.harness/rules/`, `AI-GUIDE.md`, and `CONTEXT.md` are deleted. Any `RULE` regression
means content was destroyed rather than relocated.

**Baseline captured 2026-08-07** (pre-migration, plugin v0.46.0, last commit `cb0ed57`
v0.44.0): `verify_all` = 32 PASS / 0 WARN / 0 FAIL, exit 0.

### The P1 acceptance bar, restated against a measured floor

The brief sets P1's bar at "Developer stage opening drops from 60,804 tokens to under
10,000". **That absolute number is unreachable, and the reason is measurable.**

Measured with `claude -p "Reply with exactly: ok" --output-format json`, resident prompt
taken as `cache_creation_input_tokens + cache_read_input_tokens`:

| Configuration | cache_creation | cache_read | **resident total** |
|---|---:|---:|---:|
| Empty directory (platform floor) | 10,376 | 15,636 | **26,012** |
| Inside `harness-kit/` | 11,934 | 15,636 | **27,570** |
| **harness-kit's static delta** | | | **1,558** |

The floor is Claude Code's own system prompt, tool schemas, and the globally-installed
plugin skill listing. **No deletion in §9 can take a session below ~26,012 tokens**, so a
`<10,000` absolute total is arithmetically impossible.

The floor is only *marginally* addressable: harness-kit's 17 skill descriptions contribute
~2,680 tok of it, and §9's deletion of 7 skills removes ~740 tok (17 → 10 skills,
9,651 B → 6,986 B of description text).

**Two facts this measurement separates, which the brief conflates.** harness-kit's *static*
contribution to a cold session is only ~1,558 tokens. The 60,804 figure comes from a real
working session and is dominated not by resident config but by **what the agent chose to
read into the conversation** — `AI-GUIDE.md`, rule fragments, `insight-index.md`, and the
01/02/03 contracts. That is genuinely ~60k of addressable content; it is simply not
"resident prompt", and it shrinks by changing *reading behaviour*, not only by deleting files.

> **Adopted bar (replaces the brief's §1 figure):**
> The **harness-kit-authored content a stage-4 Developer ingests before starting work**
> drops below **10,000 tokens**, measured excluding the ~26,012-token platform floor.
> Baseline for that quantity is ~32,250 tok (see `evals/measure-context.sh`).
> Secondary, exactly reproducible: the byte total of that ingest set falls ≥6×.

### That bar is not reachable by routing either. Measured 2026-08-08.

Two releases named stage-doc **conformance** as the remaining lever, at 12,778 tok of a ~14,000
tok gap. That number was extrapolated, and the extrapolation crossed document types.

`measure-stage-query.sh` derives its **3.67×** from the stage documents in the whole archive
that conform. There are **nine**, and **not one of them is a `01` or a `02`** — they are two
`03`s, two `04`s, two `05`s and three `06`s, drawn from four tasks, three of which are the
tasks that built this machinery. The Developer's opening read is `01+02+03`, of which `02`
alone is over half. A factor measured on `04/05/06` was being applied to documents that have
never once conformed.

What conformance actually changes is the **addressed fraction**, and that is knowable exactly
from the schema with no sample at all:

| Document | Sections | Addressed to the Developer |
|---|---:|---:|
| `01_REQUIREMENT_ANALYSIS` | 8 | **7** |
| `02_SOLUTION_DESIGN` | 12 | **10** |
| `03_GATE_REVIEW` | 5 | **2** |

**The requirement and the design are written FOR the Developer**, so the routing addresses
almost all of them to it however perfectly they conform. Measured: perfect conformance
withholds **3,697 tok**, not 12,778, leaving a floor of **20,294 tok — still 2× the bar.**

So the remaining term is not routing, it is **document size**. Median `02_SOLUTION_DESIGN` is
35.4 KB and the largest is 125.3 KB. Its cap was *500 lines with no byte arm* and no checker at
all until v0.52.0 — the same wrong-unit hole the caps table already names three times for other
documents, sitting on the one class the stage-4 opening actually pays for.

Re-measure the floor with the same command after P1 — the 7 deleted skills should move it
to ~25,270.

---

## Measured baseline — `retrieval-eval.js --compare`, 2026-08-08, v0.51.0

The brief's P0 asks for a repeatable batch runner and a recorded baseline. This is it. No model
is in the loop: a case is a HIT when every backticked token of its Expected answer appears in
the retrieved text, so two runs of the same tree agree exactly.

| Config | scored | score | mean bytes | ~mean tok |
|---|---:|---:|---:|---:|
| `whole` — read every anchor file | 18 | **1.000** | 60.7 KB | 17,255 |
| `grep` — grep the repo for the derived terms | 18 | **1.000** | 544.7 KB | 154,933 |
| `query` — `doc-query` over the case's store | 18 | **0.750** | 27.8 KB | 7,916 |

**Three findings, none of them the one the brief expects.**

**1. grep is dominated, not cheap.** §5.3 requires the grep baseline before any memory backend
is adopted, on the strength of Letta's LoCoMo result. On *this* corpus grep matches whole-file
accuracy at **9× the bytes** — it is the most expensive configuration measured, not the frugal
one. A memory backend does not have to beat a cheap baseline here; it has to beat `query`.

**2. `query` holds 75% of the ceiling at 46% of its bytes**, and 5% of grep's. Its four losses
are the honest cost of "query, don't read", and three of them are one cause:

**3. Half the control set cannot be scored mechanically.** 18 of 36 Expected answers are prose,
so no runner can check them and they are reported as `n/a` rather than folded into MISS —
scoring them as misses pinned every configuration near 0.5 and made the ceiling read as the
floor. Where a future case's answer matters, write the load-bearing part backticked so both
`--check` and the runner can see it.

**CODE under `query` is measuring an absence.** `doc-query` has memory, stage and rules
classes; none indexes source. A CODE question scores only what happens to be restated in
`.harness/rules/`. That gap is what P5 exists to close — and per the boxed note below, P5
cannot be gated on this repo either.

---

## CODE — structural questions (P2 gate)

| ID | Question | Expected answer | Anchor |
|---|---|---|---|
| C1 | Which function decides whether a target path lies inside the protected `.git/` ancestor? | `isDescendant` | `src/guard-rm.ts` |
| C2 | Where does guard-rm split a command string into tokens? | `tokenize` | `src/guard-rm.ts` |
| C3 | What is the top-level entry point that classifies a whole command string? | `classifyCommandString`, which delegates to `classifySegment` | `src/guard-rm.ts` |
| C4 | What is hook-spec's complete public surface? | `TOOLS`, `EVENTS`, `isTool`, `matcherOf`, `semanticsOf`, `commandOf`, `run`. Seven, not eight: hostOs went with Windows support at v0.49.0 (written bare — a name the file no longer contains is not a live reference), and `commandOf` lost its second parameter with it | `src/hook-spec.ts` |
| C5 | How many checks does `verify_all` run, and how is the count derived? | 35. 34 ids of form `X.N` plus `E.4b`, whose letter suffix defeats a naive `[A-J]\.[0-9]+` scan | `verify_all.sh`; pin at `verify_all_checks` in `baseline.json` |
| C6 | Which `verify_all` check must be recorded last, and what breaks otherwise? | `G.4` — its count derivation under-counts if any check is added after it; a tripwire FAILs when `G.4` is not last | `.harness/scripts/verify_all.sh:922` |
| C7 | Which check validates `settings.json` schema integrity? | `J.1` | `.harness/scripts/verify_all.sh` |
| C8 | Which checks are the doc-size guards? | `I.1`–`I.5` (AI-GUIDE ≤200 lines + 20 KB, rules ≤200 each, agent contracts ≤3 KB each **and** each naming a playbook that exists, insight-index ≤30 entries + 24 KB, tasks.md ≤300 lines + 24 KB); `I.6`/`I.7` are separate guards. `I.3` is the only one that FAILs rather than WARNs | `.harness/scripts/verify_all.sh` |
| C9 | If `isDescendant` changes, what is the blast radius? | Reached via `walkPaths` and `classifySegment` — every destructive-verb path decision — plus the unit suite | `src/guard-rm.ts` |
| C10 | Which script pairs does `sync-self` hold byte-identical with `templates/common/`? | 8 shell pairs — `harness-sync`, `install-hooks`, `archive-task`, `guard-rm`, `migrate-scripts-layout`, `upgrade-project`, `language-policy`, `hook-spec` — plus Mapping 10's nine compiled `.js` files and Mapping 11's `.harness/playbooks/` directory (the only mapping with an orphan arm). It does **not** sync `.harness/rules/` or agents. | `.harness/scripts/sync-self.sh` |

**C-category note.** These are the questions a Solution Architect or Code Reviewer asks.

**Anchors here cite a file and a SYMBOL, never a line.** Five of them once cited lines in
`guard-rm.sh`, and when the TypeScript migration turned that file into a twelve-line
launcher the citations kept pointing at lines 191, 711 and 903 of a file ending at 12.
Nothing noticed for a whole working session. A symbol survives a refactor; a line number is
a claim about a file's current shape, and `evals/` is the last place that should carry one.
`tests/unit/eval-anchors.test.ts` now fails the build if any citation stops resolving.

> ### ⚠️ CODE cannot gate P2. Measured 2026-08-07.
>
> Every C item is anchored in a `.sh` file, and **CodeGraph v1.5.0 indexes neither bash nor
> PowerShell.** Proved by experiment, not by reading the docs: a directory holding `ctl.py`,
> `lib.sh` and `lib2.ps1` indexes to 1 file / 4 nodes — the Python one. Indexing harness-kit
> itself yields **6 files, 26 nodes, 39 edges out of 612 tracked files**, and all six are
> throwaway `tests/fixtures/` sample apps plus one JSON mock. Not one of the repo's 33 `.sh`
> files — its entire moving-parts surface at the time, 1.28 MB — was visible. The shell half of
> that gap closed by being ported to TypeScript; the PowerShell half closed by being deleted in
> v0.49.0, so what remains unindexed is bash only.
>
> `tree-sitter-bash.wasm` does ship inside the package, but it arrives via the generic
> `tree-sitter-wasms` dependency and is not wired into the language map. Grammar presence is
> not support; that is exactly why this was tested rather than inferred.
>
> **Consequence.** C1–C10 stay in this file as a *grep-vs-full-read* comparison, which is
> still worth scoring, but they cannot serve as the P2 acceptance gate. P2 must be validated
> on a target project in an indexed language (TypeScript, TSX and Python are confirmed
> working from the fixtures), not on harness-kit. Until such a project is named, **P2 has no
> acceptance instrument.**

---

## MEM — decided-history questions (P3 gate)

These are the questions that today force an agent to read `insight-index.md` (21 KB),
`rejected-decisions.md` (26 KB), or an archived `PM_LOG.md`.

| ID | Question | Expected answer | Anchor |
|---|---|---|---|
| M1 | Why was granting `Write` to `gate-reviewer` / `code-reviewer` declined? | No tool grant in this runtime is **path-scoped** — the grant that lets the gate write `03_GATE_REVIEW.md` also lets it overwrite `02_SOLUTION_DESIGN.md`. It trades structural enforcement of the **independence invariant** (whose failure leaves no artifact) for enforcement of a duty whose failure is visible on the artifact. Re-surface only with path-scoped write, or a check that reads an agent's `tools:` line. | `.harness/rejected-decisions.md` `## reviewer-write-grant` (:282) |
| M2 | Which contract does a dispatched sub-agent actually load? | **Not** the working tree. The version-scoped plugin cache `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/agents/`. Editing `agents/*.md` governs no run until commit → push → marketplace publish → `/plugin` update → new session; **commit is usually the unstarted link**. | `.harness/insight-index.md` (T-23 entry) |
| M3 | Is a `verify_all` WARN status-neutral? | No — it exits **1** on `warns > 0`. Every WARN cap is a hard release gate, not advisory. An architect explicitly assumed the opposite. | `.harness/insight-index.md`; `verify_all.sh:823–825` |
| M4 | What does a plain `rg` pattern silently miss in this repo? | Dot-directories are skipped by default, so any audit search returns **zero** hits under `.harness/` while still looking complete. `--hidden` is not optional in a repo whose source of truth lives under a dot-directory. | `.harness/insight-index.md` (T-23 entry) |
| M5 | Why was per-agent model tiering declined? | Model-swap **declined**, reasoning-effort **deferred**. Nothing measures a per-stage rollback rate, so the before/after comparison is unavailable; the saving is a proportional discount on a bill that is 78% cache traffic; plugin-native agents make a tier neither trialable nor withdrawable per consumer. Re-surface only with F-1 + F-2 + F-3. | `.harness/rejected-decisions.md` `## stage-model-tiering` (:257) |
| M6 | What is the safe sequence for editing a live fail-closed `PreToolUse` hook? | Stage the change in the **unwired template copy**, syntax-check it, drive it through a `[guard-path]` argument, then promote once via `sync-self`. Recovery must be Read+Write only — `git checkout` is itself a Bash call and would be blocked. Failure modes are asymmetric and both silent: syntax error exits 2 (looks like a BLOCK, kills every later Bash call); runtime error under `set -uo pipefail` exits 1, which Claude Code treats as non-blocking, so the guard **fails open** and `bash -n` cannot see it. | `.harness/insight-index.md` (guard-cmd-chain) |
| M7 | Can a `git status` snapshot carried in agent context prove a path is absent from the dirty set? | No. It is **elided mid-list** — eight `agents/*.md` entries vanish between `README.zh-CN.md` and `docs/`. Three independent stages certified that directory clean off it while the live `git status --porcelain -- agents/` returned eight modified files. Only a stage with a shell can establish a negative. | `.harness/insight-index.md` (T-22) |
| M8 | Which edit class is simultaneously invisible to `git status --porcelain`, `git diff --numstat`, and `wc -l`? | An **in-hunk, line-count-preserving in-place** edit. Only a content digest moves. The blindness is bounded, not uniform — the same edit on a *context* line does move numstat. | `.harness/insight-index.md` (T-22, QA M2a/M2b) |
| M9 | Is "one physical line per insight" a hard input contract for `archive-task`? | **No — superseded.** A wrapped entry survives harvest and rotation whole, and the cap counts entries rather than physical lines. What survives from the retracted entry is only the hazard shape: a transport defect that reports success while discarding content is invisible to a gate that counts markers instead of content. | `.harness/insight-index.md` (T-20 SUPERSEDES entry) |
| M10 | Why was restating the stage-3/stage-5 transcription duty inside each mode skill declined? | Four hand-synced copies of one sentence, each adding dispatch-time ingest cost. Adopted instead: the author's own contract makes it end its final message with the target paths, so the instruction travels **in-band with the body**. | `.harness/rejected-decisions.md` `## persist-duty-in-mode-skills` (:298) |
| M11 | Why can `gate-reviewer` and `code-reviewer` not produce the stage documents their own contracts name? | They are declared `Read, Glob, Grep` — **no `Write`**. The orchestrator must transcribe their returned bodies verbatim; a run that assumes those files appear by themselves silently loses the stage record. Latent for as long as both contracts have named an output they cannot produce. | `.harness/insight-index.md` (T-22) |
| M12 | What does `[ \t]` inside a bracket expression match, per tool? | A tab to `awk`; the class `{space, backslash, t}` to GNU grep 3.11 — so `grep -E '"x"[ \t]*:'` **misses** a real tab and **matches** `"x"t:`. Compounding trap: this host's interactive shell has ugrep 7.5.0, which reads it as a tab, so a by-hand check endorses the broken form while the script run gets GNU grep. Measure a matcher per tool. | `.harness/insight-index.md`; `verify_all.sh:354–359` |

---

## RULE — methodology that must survive P1 (P1 regression gate)

**If any of these regresses after the §9 deletion, content was destroyed, not relocated.**

| ID | Question | Expected answer | Anchor (today) |
|---|---|---|---|
| R1 | What decision mode does this repo run, and what does it imply? | **Mode 2 (balanced)** — decide per `.harness/decision-rubric.md` Preset section, escalate the red lines, log each autonomous call. | `AI-GUIDE.md:27` |
| R2 | How is the destructive-command guard overridden? | `HARNESS_ALLOW_OUTSIDE_RM=1` | `.harness/rules/75-safety-hook.md` |
| R3 | Is guard-rm fail-open or fail-closed? | **fail-CLOSED** — and it is the one hook declared so in `hook-spec`. | `.harness/scripts/hook-spec.sh`; `.harness/rules/40-locations.md:28` |
| R4 | What is the declare-done gate for all non-trivial modes? | `verify_all` PASS **plus**, for 7-stage or goal mode, an `## Adversarial tests` section in `06_TEST_REPORT.md`. | `AI-GUIDE.md:59` |
| R5 | What happens after three rollbacks at the same stage? | Stop and ask the human. It is a hard rule, not a heuristic. | `agents/pm-orchestrator.md` |
| R6 | What are the doc-size caps? | AI-GUIDE ≤200 lines **and** 20 KB; each rule fragment ≤200 lines; each agent ≤300 lines **and** 24 KB; insight-index ≤30 entries **and** 24 KB; `tasks.md` ≤300 lines **and** 24 KB. Four of the five carry a byte arm because the unit that is paid is bytes. All are gated at WARN, which exits 1 (see M3). | `.harness/rules/70-doc-size.md`; `verify_all` `I.1`–`I.5` |
| R7 | Which agent is permitted to write production code? | `developer`, and only it. Reviewers hold no `Write`; the architect holds `Write` for design docs only. | `agents/developer.md` |
| R8 | What are the five attribution classes behind "don't retry, fix the rail"? | Wrong style/pattern → **Rule** (`.harness/rules/`) + **Script** (`verify_all`). Forgot a step → **Skill** (`.harness/skills/`). Roles confused → **Agent definition**. Couldn't reach an external capability → **MCP server**. Whole stage missing → **new agent + workflow update**. The principle: every mistake is a hint about a missing guardrail, so `verify_all` grows fatter and manual correction shrinks — the *system* gets smarter, not the model. | `docs/concepts.md:228–243` |

> **R8 conflicts with §9.1 and must be remapped before P1, not after.**
> Two of the five fix levels name destinations the deletion removes — `.harness/rules/`
> (deleted outright) and `.harness/skills/` (7 of 17 skills deleted). A third names
> `.harness/agents/`, which has been **stale since v0.30**: framework agents live in
> top-level `agents/`. The taxonomy is the routing table for every future guardrail repair;
> if P1 lands without rewriting its right-hand column, the most valuable rule in the system
> points at four paths, three of which are wrong.
>
> The fourth row — "couldn't reach an external capability → MCP server" — is the one the
> migration *improves*: P2/P3 finally make that destination real.
>
> **Owner action: rewrite the fix-level column as part of P1, in the same commit as the deletion.**

---

## STATE — per-task ledger questions (P4 gate)

43 archived tasks carry a `PM_LOG.md` with a **Final rollback ledger** table. The
`.harness/state/<slug>.json` file must reconstruct these answers in <1 KB.

| ID | Question | Expected answer | Anchor |
|---|---|---|---|
| S1 | How many rollbacks did `review-write-path` take, and at which stage? | One, at stage 2 (solution-architect), triggered by gate round 1 `BLOCKED ON DESIGN` (G-1 unsatisfiable AC-10 uniqueness constraint; G-2 dispatched stages load the plugin-cache build). Hard rule 3 never approached. | `docs/features/_archived/review-write-path/PM_LOG.md` |
| S2 | Did `review-write-path` ever return `BLOCKED: NEEDS-HUMAN`? | No. The one candidate escalation (the AC-8 acceptance bar) was resolved on structural facts by the architect and independently adjudicated by the gate. | same |
| S3 | Which stage caused the rollback in task `<slug>`? | Per-task; extract from each ledger. | `docs/features/_archived/*/PM_LOG.md` |
| S4 | What was the final verdict of task `<slug>`? | Per-task; `## Verdict` section. | `docs/features/_archived/*/07_DELIVERY.md` |
| S5 | Across all archived tasks, is a per-stage rollback **rate** derivable? | **No.** Individual rollbacks are attributed to a causing stage (19 of 19 checked), but nothing aggregates them into a rate — which is precisely why `stage-model-tiering` was declined (M5). | `.harness/rejected-decisions.md:257`; `.harness/insight-index.md` (T-22) |
| S6 | Which tasks ran the entropy-watch cadence and which deliberately skipped it? | Per-task; `review-write-path` deliberately did **not** run it — the dispatching `/harness-stream` drain owned that boundary. | `docs/features/_archived/*/PM_LOG.md` |

> **S3/S4/S6 are templates, not items.** Instantiate each against 8–10 named tasks before
> P4 scoring so the category has ~25 scoreable rows. Left as templates here because the
> extraction is mechanical and should be scripted, not hand-copied.

---

## Item count

| Cat | Scoreable now | After owner actions |
|---|---|---|
| CODE | 10 | 10 |
| MEM | 12 | 12 |
| RULE | 7 (R8 pending) | 8 |
| STATE | 3 (S1, S2, S5) | ~25 |
| **Total** | **32** | **~55** |

32 scoreable items meets the brief's 30–50 target today. The STATE expansion is scripted
work that should land with P4, not before.

## Outstanding owner actions

1. **Pin R8's expected answer** from `docs/workflow.md` / `docs/concepts.md` before P1 deletes anything.
2. **Script the STATE extraction** over the 43 `PM_LOG.md` ledgers (deferred to P4).
3. **Run configuration A** (today's full-document reads) to capture the accuracy *and* token
   baseline. Without it P1's "accuracy did not regress" claim is unfalsifiable.

---

## P3 baseline result — measured 2026-08-07

`evals/run-mem-baseline.sh` runs the 12 MEM items through four retrieval configurations.
Scoring is mechanical (does the expected evidence string appear in the arm's output?), so
no judge model is involved.

| arm | what it is | accuracy | tokens | vs A |
|---|---|---:|---:|---:|
| **A** | read the whole document — today | 12/12 | 81,899 | — |
| **B1** | repo-wide search that skips dot-directories | **0/12** | 0 | — |
| **B2** | the same search, dot-directories included | 12/12 | 50,332 | 1.6× |
| **B3** | scoped to the memory docs, 2 lines of context | 8/12 | 4,550 | 18.0× |
| **B4** | scoped, entry-sized context window | 10/12 | 16,614 | 4.9× |
| **B5** | `memory-search` — named stores, whole entries | **11/12** | **4,560** | **18.0×** |

B5 was built after the first four arms measured *why* search failed. Its one remaining miss
is M3, whose answer lives in `verify_all.sh` rather than in any store — unreachable by
construction, and the eval set's own mis-categorisation. **On the eleven correctly-homed
items it is perfect, at 18× fewer tokens than reading the documents.**

Two scoring artifacts were fixed before this table was trusted, both in the measure rather
than the arms: the evidence check was case-sensitive, so an entry writing `BRACKET` in caps
scored MISS against evidence `bracket`; and two terms were written as grep *regexes*, which
measured the term format rather than the arm once a substring-matching arm existed.

### Three findings

**1. The dot-directory hazard is not theoretical — it is total.** B1 scores **0 of 12** and
returns **zero bytes**, so it reads as "no results" rather than "wrong search". Every MEM
answer lives under `.harness/`, and Claude Code's Grep tool is ripgrep-backed, which skips
dot-directories by default. This is the live case for every agent in this repo, and it is
the single largest retrieval risk measured anywhere in this migration.

**2. Unscoped search is barely worth doing.** B2 buys full accuracy for only 1.6× fewer
tokens than reading the documents outright, because a repo-wide match sprays across
`CHANGELOG.md` and 7.4 MB of archived tasks. "Grep instead of read" is not the win the
brief assumed; **scoping** is where the 18× lives.

**3. B4's three misses have three different causes, and only one argues for a backend.**

- **M3** — its answer is in `verify_all.sh`, not a memory store, so the scoped arms cannot
  reach it by construction. This is the eval set's own mis-categorisation, not a retrieval
  failure. Marked in the runner rather than deleted.
- **M12** — the keyword hits but the evidence sits outside a ±10-line window, because one
  fact is stored as one long wrapped paragraph. The fix is the storage **unit**, not the
  storage **engine**: one fact per retrievable chunk makes a hit return the whole fact.
- **M6** — the literal search term never appears, because the source writes ``` `PreToolUse` ```
  with backticks. This is genuine literal-vs-semantic brittleness, and it is the only one of
  the twelve that a semantic backend would fix.

### Recommendation: do not adopt agentmemory on this evidence

§5.3 sets the bar — a backend that does not beat search does not get merged. Scoped search
reaches 9–12 of 12 at 5–18× cheaper than today, and exactly **1 of 12** failures is the kind
semantic retrieval addresses. Against that, `agentmemory` brings a hard-pinned `iii-engine`
dependency whose provenance the brief itself records as unverified, a cross-agent memory leak
fixed only in v0.9.28, and a 0.9.x version line.

By the brief's own test — *does it remove a decision point or add one?* — it adds several to
remove roughly 8% of one category's misses.

**Adopted instead — `memory-search`, and no new component.** Both fixes landed in one
30-line tool rather than a service: the stores are named *in the tool* so none can be
silently missed, and the unit returned is the whole entry so a hit is never a window into a
fact. It summarises and indexes nothing — the text it prints is the original at its original
location, because `stage-doc-summary-header` applies to memory as much as to stage documents.

Wired into `.harness/rules/05-insight-index.md`, which already fires before every
non-trivial task, so the discipline is reachable rather than merely stated, and into the
seven agent-contract sites that used to say *read the file*.

### A capability split the fix had to respect

**Only 2 of the 8 agents hold `Bash`** — developer and qa-tester. The six that most need
memory (requirement-analyst, solution-architect, gate-reviewer, code-reviewer,
pm-orchestrator, supervisor) cannot run any script at all, which is why the whole-file read
became habit in the first place. Granting them `Bash` was not an option: it would surrender
the reviewers' physical read-only isolation that `reviewer-write-grant` exists to protect.

So the rule states two forms. Script-capable agents call `memory-search`. The rest use the
`Grep` tool with an **explicit `path`** — which is the property that matters, since without
it the tool is ripgrep-backed and returns nothing from any store under `.harness/`.

### What the rewrite costs and returns

| | per full 7-stage task |
|---|---:|
| Before — six agents each read the 20.6 KB index whole | **~35,100 tok** |
| After — six scoped queries at the measured B5 average of ~380 tok | ~2,280 tok |
| **Net saving** | **~32,800 tok** |
| Cost — the eight contracts grew by longer instructions | **+300 tok** on-invoke |

Measured with `claude --plugin-dir . plugin details harness-kit`: the agent contracts moved
from ~35.4k to ~35.7k on-invoke in total. That is a roughly hundredfold return on the added
contract bytes, and it is the largest single reduction found anywhere in this migration.

Still outstanding: **re-home M3** into `RULE`, where it belongs.

Re-run this baseline before revisiting the question. The bar a backend must clear is now
**B5 — 11/12 at 4,560 tokens** — not A, not B2, and no longer B3.
