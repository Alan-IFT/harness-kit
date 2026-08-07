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

Re-measure the floor with the same command after P1 — the 7 deleted skills should move it
to ~25,270.

---

## CODE — structural questions (P2 gate)

| ID | Question | Expected answer | Anchor |
|---|---|---|---|
| C1 | Which function decides whether a target path lies inside the protected `.git/` ancestor? | `is_descendant()` | `.harness/scripts/guard-rm.sh:711` |
| C2 | Where does guard-rm split a command string into tokens? | `tokenize()` | `.harness/scripts/guard-rm.sh:191` |
| C3 | What is the top-level entry point that classifies a whole command string? | `classify_command_string()`, which delegates to `classify_segment()` (`:796`) | `.harness/scripts/guard-rm.sh:903` |
| C4 | What is `hook-spec.sh`'s complete public surface? | 6 functions: `hs_die`, `hs_is_tool`, `hs_event`, `hs_matcher`, `hs_semantics`, `hs_command` | `.harness/scripts/hook-spec.sh:79–119` |
| C5 | How many checks does `verify_all` run, and how is the count derived? | 32. 31 ids of form `X.N` plus `E.4b`, whose letter suffix defeats a naive `[A-J]\.[0-9]+` scan | `verify_all.sh`; pin at `baseline.json:10` |
| C6 | Which `verify_all` check must be recorded last, and what breaks otherwise? | `G.4` — its count derivation under-counts if any check is added after it; a tripwire FAILs when `G.4` is not last | `.harness/scripts/verify_all.sh:922` |
| C7 | Which check validates `settings.json` schema integrity? | `J.1` | `.harness/scripts/verify_all.sh` |
| C8 | Which checks are the doc-size guards? | `I.1`–`I.5` (AI-GUIDE ≤200 lines, rules ≤200 each, agents ≤300 each, insight-index ≤30 entries, tasks.md ≤300 lines); `I.6`/`I.7` are separate guards | `.harness/scripts/verify_all.sh` |
| C9 | If `is_descendant()` changes, what is the blast radius? | Reached via `_walk_paths()` (`:770`) and `classify_segment()` (`:796`) — every destructive-verb path decision | `guard-rm.sh:711,770,796` |
| C10 | Which script pairs does `sync-self` hold byte-identical with `templates/common/`? | 8 pairs: `harness-sync`, `install-hooks`, `archive-task`, `guard-rm`, `migrate-scripts-layout`, `upgrade-project`, `language-policy`, `hook-spec`. It does **not** sync `.harness/rules/` or agents. | `.harness/scripts/sync-self.sh`; `AI-GUIDE.md:77` |

**C-category note.** These are the questions a Solution Architect or Code Reviewer asks.
Today they are answered by full-file reads of a 968-line and a 934-line script. `codegraph_node`
/ `codegraph_callers` / `codegraph_impact` should answer C1–C4 and C9 at a fraction of the tokens.
C5–C8 and C10 are *semi-structural* — the answer lives in data tables and comments, not the call
graph, so CodeGraph may legitimately lose these to grep. **Score the two sub-groups separately;
a CodeGraph win on C1–C4/C9 with a loss on C5–C8/C10 is the expected and acceptable result.**

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
| R3 | Is guard-rm fail-open or fail-closed? | **fail-CLOSED** — and it is the one hook declared so in `hook-spec`. | `.harness/scripts/hook-spec.sh`; `AI-GUIDE.md:78` |
| R4 | What is the declare-done gate for all non-trivial modes? | `verify_all` PASS **plus**, for 7-stage or goal mode, an `## Adversarial tests` section in `06_TEST_REPORT.md`. | `AI-GUIDE.md:106` |
| R5 | What happens after three rollbacks at the same stage? | Stop and ask the human. It is a hard rule, not a heuristic. | `agents/pm-orchestrator.md` |
| R6 | What are the doc-size caps? | AI-GUIDE ≤200 lines; each rule fragment ≤200 lines; each agent ≤300 lines; insight-index ≤30 entries; `tasks.md` ≤300 lines. All are gated at WARN, which exits 1 (see M3). | `.harness/rules/70-doc-size.md`; `verify_all` `I.1`–`I.5` |
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
