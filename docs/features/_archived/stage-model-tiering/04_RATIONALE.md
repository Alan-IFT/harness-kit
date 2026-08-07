# 04 — Development Rationale: stage-model-tiering (T-22)

> Rationale sibling of `04_DEVELOPMENT.md` (the contract). Opened under the named trigger in the
> stage-4 dispatch and under `.harness/rules/70-doc-size.md` row 13 — the S-A/S-B capture
> transcripts are tool runs longer than 5 lines and have no other destination.
> Every verdict in here is stated bindingly in `04_DEVELOPMENT.md`; this file carries the evidence.

---

## R1. Capture S-A — before the first write of stage 4

Captured at 2026-08-01T14:5x UTC, before any file was touched. Working directory
`/home/alan/Programs/harness-kit`. Design reference: `02_SOLUTION_DESIGN.md` §8.1.

**Path substitution.** §8.1 names `/tmp/t22_s0.txt` / `/tmp/t22_s1.txt`. The session's scratchpad
directory was used instead:
`/tmp/claude-1000/-home-alan-Programs-harness-kit/18df63fc-e073-421d-b231-b393671e0e4d/scratchpad/`.
Same semantics, same commands; only the path differs — recorded so it is not read as a deviation.

### A1 — `git rev-parse HEAD` · and C-1 — `git log -1 --format=%cI` (gate round 2 §9)

```
cb0ed57f5c390cbcbdc3c22c9c5e749125136204
2026-06-21T15:00:19+08:00   (epoch 1782025219)
cb0ed57 feat(v0.44.0): resilient lifecycle hooks + Windows repair-path fixes (T-12)
```

### A2 — `git status --porcelain -- agents/`

**Expected empty. It is not.**

```
 M agents/code-reviewer.md
 M agents/developer.md
 M agents/gate-reviewer.md
 M agents/pm-orchestrator.md
 M agents/qa-tester.md
 M agents/requirement-analyst.md
 M agents/solution-architect.md
 M agents/supervisor.md
```

8 entries. `git diff --stat -- agents/` at S-A: `8 files changed, 288 insertions(+), 130 deletions(-)`.

This is the §8.2 contingency-1 branch. Analysis in §R4.

### A3 — whole dirty set

`git status --porcelain | wc -l` → **101** entries, written to `scratchpad/t22_s0.txt`.

### A4 — `stat -c '%n %Y %s'` per agent file

| file | mtime (epoch) | mtime (UTC) | size |
|---|---:|---|---:|
| `agents/code-reviewer.md` | 1785565397 | 2026-08-01T06:23:17Z | 8938 |
| `agents/developer.md` | 1785579706 | 2026-08-01T10:21:46Z | 7218 |
| `agents/gate-reviewer.md` | 1785558918 | 2026-08-01T04:35:18Z | 7189 |
| `agents/pm-orchestrator.md` | 1785579713 | 2026-08-01T10:21:53Z | 19749 |
| `agents/qa-tester.md` | 1785560950 | 2026-08-01T05:09:10Z | 8639 |
| `agents/requirement-analyst.md` | 1785558811 | 2026-08-01T04:33:31Z | 9199 |
| `agents/solution-architect.md` | 1785559564 | 2026-08-01T04:46:04Z | 13446 |
| `agents/supervisor.md` | 1785559103 | 2026-08-01T04:38:23Z | 14049 |

Latest agent mtime: **1785579713** (`pm-orchestrator`, 10:21:53Z).

### A5 — `wc -l agents/*.md`

```
  166 agents/code-reviewer.md
   91 agents/developer.md
  113 agents/gate-reviewer.md
  293 agents/pm-orchestrator.md
  156 agents/qa-tester.md
  101 agents/requirement-analyst.md
  169 agents/solution-architect.md
  287 agents/supervisor.md
 1376 total
```

### A6 — `sha256sum agents/*.md`

```
400a38421611dc5167e2a17f3c8e9f33e4e8f1c13522f95414622e0747e190d9  agents/code-reviewer.md
a7fabb1c74bf5568bfcb9b0d5ff036232884c7e507376b6e20d2feba822b9152  agents/developer.md
2f85ef7def7aff70468326d63de83a473c6de5b4a71e79c52c0d2aaedb0d67b9  agents/gate-reviewer.md
ca1ea827cd044840b7ba5afe148784cfd2f5153673f33525e5a9aeea78f2ca9d  agents/pm-orchestrator.md
a3a1eca3939eb8985ca8a9ce5700678fd1dc8b2f10b27957ea004352ef9ed6ae  agents/qa-tester.md
520450d7298ccf632a41956f65502cc5e9d8661eff28547f5a42a916f75d1075  agents/requirement-analyst.md
32257a209e293856a7e5a1470fdd6afed0392ffeef2d93c630de5a29f13558fb  agents/solution-architect.md
f96b1359059fce54ae0bf912206fc0ac6700a48001c9ffcdec1cd93ddd49b3bf  agents/supervisor.md
```

Roll-up (`sha256sum agents/*.md | sha256sum`):
`31ff7e778c3ba95870f7846d3c59c738d10229465a11505f883eb5ca31828a5f`

### A7 — `T0`

`stat -c '%Y %n'` → `1785591621 docs/features/stage-model-tiering/01_REQUIREMENT_ANALYSIS.md`
(2026-08-01T13:40:21Z).

### A7b — every task-folder document's mtime

At S-A, ascending, all 2026-08-01: `01_REQUIREMENT_ANALYSIS.md` 1785591621 (13:40:21Z) ·
`01_RATIONALE.md` 1785591718 (13:41:58Z) · `02_SOLUTION_DESIGN.md` 1785594982 (14:36:22Z) ·
`02_RATIONALE.md` 1785594989 (14:36:29Z) · `03_GATE_REVIEW.md` 1785595837 (14:50:37Z) ·
`PM_LOG.md` 1785595856 (14:50:56Z).

`min(mtime)` over the folder = **1785591621** — the same file A7 names, because every other
artifact has been rewritten since. `PM_LOG.md` is the task's *earliest-created* artifact but
carries the *latest* mtime; this is exactly the reason D-15 exists.

An independent, tighter anchor is available and is not an mtime at all:
`docs/batches/default/STREAM_LOG.md:88` records the dispatch boundary verbatim —

```
2026-08-01T13:30:45Z · T-22 · dispatching pm-orchestrator · slug=stage-model-tiering · mode=full · ASSESS-FIRST …
```

= epoch **1785591045**. It is a written record of when T-22 began, not a filesystem attribute, so
it cannot be perturbed by a later touch. Used in §R5 as `T_dispatch`.

### A8 — baseline `verify_all`

Summary block `PASS: 32 / WARN: 0 / FAIL: 0`, `exit=0` — check-for-check identical to the post-edit
run listed in full at §R3.1.

---

## R2. The edit

Byte-form source: `02_SOLUTION_DESIGN.md` lines 108–129 (the fence at 107 is ```` ```markdown ````,
the closing fence is at 130). Extracted with `sed -n '108,129p'` rather than retyped, so character
identity (D-1 / C-2) is a property of the method, not of my transcription accuracy. The §6 text
contains `—`, `–`, `≥` and `…`; retyping is where those get silently normalised.

```
extracted lines: 22
sha256(record.txt) = 072fe7404e85121aa72b6942455740079ea770395970043cf05b5ba23f4c5117
trailing whitespace: none
max line width: 100 (line 7)
field distribution: 1 heading + 2 Decision + 16 Why + 3 Origin = 22   ← D-6 exactly
```

Append performed as `{ printf '\n'; cat record.txt; } >> .harness/rejected-decisions.md`.

### Post-edit verification

```
file line count      : 255 → 278
trailing byte        : 0a  (newline preserved)
records (^## )       : 23 → 24
sha256(head -n 255)  : fbdf6db11ef80da023a31b2a53ede36ed41d509e0e20b4507987e177c30af898
sha256(pre-edit file): fbdf6db11ef80da023a31b2a53ede36ed41d509e0e20b4507987e177c30af898   ← identical, D-10 proven
sha256(tail -n 22)   : 072fe7404e85121aa72b6942455740079ea770395970043cf05b5ba23f4c5117   ← identical to §6, C-2 proven
line 256             : blank (exactly one separator)
```

`sed -n '255,257p' | cat -A`:

```
- **Origin:** T-20 `harvest-wrapped-insight` (design §M.1 / `K-48c`, gate `K-67`).<EOL>
<EOL>
## stage-model-tiering<EOL>
```

### D-9 — the two diff baselines

```
$ git diff --numstat -- .harness/rejected-decisions.md          # vs H0
179     0       .harness/rejected-decisions.md

$ git diff --no-index --numstat <pre-edit copy> .harness/rejected-decisions.md
23      0       … => .harness/rejected-decisions.md
```

`diff` line tally against the pre-edit copy: **added 23, removed 0**. No
`\ No newline at end of file` marker anywhere in the diff (grep count 0), so D-9's tolerance clause
is not needed. Bound at `04_DEVELOPMENT.md` `## Design drift` row **DR-2**.

### AC-5 exactness

```
$ grep -c '^## stage-model-tiering$'  → 1
$ grep -in 'stage-model-tiering'
257:## stage-model-tiering
276:- **Origin:** T-22 `stage-model-tiering`. It overrides `docs/batches/default/BATCH_PLAN.md:37`
278:  quoted and answered at `docs/features/_archived/stage-model-tiering/02_SOLUTION_DESIGN.md` §16.1.
```

One heading; the two other hits are the handle and the archived path inside `Origin`, neither a
heading at any level, casing or indentation.

---

## R3. Capture S-B — after the edit and after the final `verify_all`

A1 `cb0ed57f5c390cbcbdc3c22c9c5e749125136204` (unchanged).
A2 — the same eight ` M agents/*.md` entries, byte-identical to S-A. **Eight lines, all ` M`; no
`??` line at either capture** — the mode degraded FZ-1 still covers (§R6, M5 leg).
A3 — 101 entries (unchanged).
A4 — all eight mtimes and sizes **identical to S-A**, to the second and to the byte.
A5 — `166 / 91 / 113 / 293 / 156 / 101 / 169 / 287`, total `1376` (unchanged).
A6 — all eight digests identical; roll-up
`31ff7e778c3ba95870f7846d3c59c738d10229465a11505f883eb5ca31828a5f` (unchanged).

`git diff --numstat -- agents/` at S-B — per file, in glob order:
`40/13 · 27/39 · 41/16 · 47/4 · 33/9 · 45/21 · 51/26 · 4/2`, summing to **288 insertions / 130
deletions**, identical to the S-A `--stat` total and per-file identical to §R6's independently
rebuilt control.

### R3.1 — A8 (final): `bash .harness/scripts/verify_all.sh; echo "exit=$?"`

Full listing, pasted unmodified. Bound in `04_DEVELOPMENT.md` `## verify_all result` (AC-7, C-5).

```
=== verify_all (harness-engineering repo) ===

[A.1] No accidentally-committed env or secrets ... PASS
[A.2] 参考/ not tracked ... PASS
[B.1] README / LICENSE / CHANGELOG present ... PASS
[B.2] Install scripts present ... PASS
[C.1] All 17 skills present ... PASS
[C.2] Skill frontmatter sanity ... PASS
[D.1] Plugin agents present ... PASS
[D.2] Placeholders documented ... PASS
[D.3] AI-generated 50-*.md sanity (per-section sources, headings, no placeholders) ... PASS
[E.1] Layer 1: .harness/ matches templates/common/.harness/ ... PASS
[E.2] Layer 2: .claude/agents and .claude/skills synced from .harness/ ... PASS
[E.3] Rule sources present ... PASS
[E.4] Bootstrap files present and stubs reference AI-GUIDE.md ... PASS
[E.4b] AI-GUIDE.md indexes every .harness/rules/*.md (and vice versa) ... PASS
[E.5] Docs present ... PASS
[E.6] evals/golden-tasks.md present ... PASS
[E.7] No stale .harness/intervention.md tracked ... PASS
[F.1] Script pairs (.ps1 + .sh) present ... PASS
[F.2] Guard-rm scripts and settings-template guard wiring present ... PASS
[G.1] README references all 17 skills ... PASS
[H.1] Test fixtures present ... PASS
[G.2] CHANGELOG references all 17 skills ... PASS
[G.3] Version stamps consistent across plugin/marketplace/README ... PASS
[I.1] AI-GUIDE.md ≤200 lines ... PASS
[I.2] Rule fragments ≤200 lines each ... PASS
[I.3] Agent definitions ≤300 lines each ... PASS
[I.4] insight-index.md ≤30 insight entries ... PASS
[I.5] docs/tasks.md ≤300 lines ... PASS
[I.7] Ignored INTERVENE supervision reports (WARN if >48h old on active task) ... PASS
[I.6] No retired-claim phrases in current docs/templates ... PASS
[J.1] settings.json schema integrity (.claude/ + template) ... PASS
[G.4] Doc count/version claims consistent with plugin.json + live check count ... PASS

=== Summary ===
  PASS: 32
  WARN: 0
  FAIL: 0
exit=0
```

Identical check-for-check to the A8 baseline captured before the edit (§R1 A8): same 32 ids, same
order, same verdicts.

---

## R4. Why A2 came back non-empty, and what it costs

`agents/` **is** in the dirty set. All eight files carry uncommitted changes against `H0`
(288+/130−). Their mtimes cluster at 04:33–10:21 UTC on 2026-08-01 — i.e. during the T-13…T-21
wave, hours before T-22 was dispatched at 13:30:45Z. The agent contracts were revised by sibling
tasks in this wave and never committed. Nothing anomalous happened; the premise was simply wrong.

**How the wrong premise got in, twice.** `03_GATE_REVIEW.md` §3.1 states: *"Verified from the
session-start `git status` snapshot: the modified-file stream runs `… README.zh-CN.md` →
`docs/batches/default/BATCH_PLAN.md`, and `agents/` sorts strictly between those two paths. No
`agents/` entry appears."* Round 2 §3 repeats it. The sort reasoning is correct — `agents/` does
sort strictly between `README.zh-CN.md` and `docs/`. What is wrong is the premise that the snapshot
is complete. The session-context `git status` block is **elided**, and it elides exactly there:

```
 M README.zh-CN.md
 M docs/batches/default/BATCH_PLAN.md      ← the eight agents/ lines are missing here
```

Run live, the same region reads:

```
35   M README.zh-CN.md
36   M agents/code-reviewer.md
…    (six more)
43   M agents/supervisor.md
44   M docs/batches/default/BATCH_PLAN.md
```

The gate did the sort arithmetic correctly and then read a negative off a lossy artifact. It also
labelled the check honestly — *"Not a live check; A2 at S-A remains authoritative"* — which is why
this cost nothing: the design routed the real check to S-A and pre-wrote the contingency.

**What it costs.** FZ-1's strength was that path-scoped emptiness against an unmoved `H0` is a
*content-identity* statement over the whole interval since `cb0ed57`, which strictly contains the
task. That is gone. `git status --porcelain -- agents/` printing ` M` at S-A and ` M` at S-B is
compatible with any content change in between — the T-15 blindness exactly. FZ-1 degrades to the
difference argument §8.2 anticipated.

**What replaces it, and what does not.** Two things step in, and **neither is stronger** than what
FZ-1 would have given for stages 0–3 — that interval is genuinely weaker now, and saying otherwise
would be the same over-claim the gate rolled stage 2 back for:

1. **FZ-3, with a real margin** (§R5). All eight mtimes precede `T0` by ≥11,908 s and precede the
   *dispatch* by ≥11,332 s (3 h 08 m). This is the only leg that reaches stages 0–3 at all, and it
   is **weaker than content identity**: an mtime survives no edit, but it can be backdated, so FZ-3
   excludes an edit that advanced an mtime, not an edit as such.
2. **An added leg to FZ-1**: `git diff --numstat -- agents/` compared S-A→S-B. Unlike `git status`
   it is content-sensitive inside an already-dirty file; 288/130 at both captures. But it spans
   `[S-A, S-B]` only and therefore supplies **zero** coverage of stages 0–3, the exact interval
   FZ-1's failure vacated — and inside that span it is subsumed by FZ-2, since equal digests imply
   equal numstat. It is corroboration, not a leg.

The residual this leaves is stated narrowly at `04_DEVELOPMENT.md` `## Open issues for review`
item 1, and narrowed further by three in-record anchors (`01` §4.3, `02` §8.3, `03` round 2 §2)
that all reproduce at S-A/S-B.

**`01` avoided the exposure; `02` took it on, and the premise — not the inference — is what failed.**
`01_REQUIREMENT_ANALYSIS.md` §4.5 says: *"The working tree carries eight siblings'
delivered-but-uncommitted changes, so 'absent from the dirty set' proves nothing about the agent
files. The agent files being untouched is established by their content and modification time being
unchanged relative to this task's first write, not by cleanliness in git."* That is precisely what
happened and precisely what carries AC-6. §8's FZ-1 introduced a premise `01` had declined to rely
on. Its *inference* is logically valid — path-scoped emptiness against an unmoved `H0` really does
imply content identity. What failed is the **empirical premise**, certified twice off an elided
artifact rather than a command. The transferable lesson is therefore not "do not reason about the
dirty set" but the one the `## Insight to surface` bullet states: never take a negative off a
context-carried `git status` snapshot.

---

## R5. Predicate-by-predicate evaluation

`T0 = 1785591621`, `T_dispatch = 1785591045`, `H0 = cb0ed57`, `H0_date = 1782025219`.

### FZ-1 — DEGRADED, evaluated in its degraded form

| leg | S-A | S-B | verdict |
|---|---|---|---|
| `git rev-parse HEAD` | `cb0ed57…` | `cb0ed57…` | unchanged ✔ |
| `git status --porcelain -- agents/` | 8 × ` M` | 8 × ` M` | **non-empty at both** — premise failed |
| …same output, `??` entries only | none | none | **holds ✔** — no new untracked `agents/*.md` |
| `git diff --numstat -- agents/` *(added)* | 288 / 130 | 288 / 130 | unchanged ✔ |

Path-scoped *emptiness* is unavailable, so the content-identity reading is gone. The `??` reading
survives intact and is mutation-tested at §R6; the added numstat leg carries the rest of the row,
subject to the subsumption noted in §R4.

### FZ-2 — PASS, 8/8

`diff` of the S-A and S-B digest lists is empty. This predicate is git-independent and survives a
HEAD move; with FZ-1 degraded it is the load-bearing predicate for the stage-4 interval.

### FZ-3 — PASS, 8/8, against two anchors

| file | mtime | `< T0`? | margin to `T0` | `< T_dispatch`? |
|---|---:|:---:|---:|:---:|
| `code-reviewer.md` | 1785565397 | yes | 26 224 s | yes |
| `developer.md` | 1785579706 | yes | 11 915 s | yes |
| `gate-reviewer.md` | 1785558918 | yes | 32 703 s | yes |
| `pm-orchestrator.md` | 1785579713 | yes | **11 908 s** | yes |
| `qa-tester.md` | 1785560950 | yes | 30 671 s | yes |
| `requirement-analyst.md` | 1785558811 | yes | 32 810 s | yes |
| `solution-architect.md` | 1785559564 | yes | 32 057 s | yes |
| `supervisor.md` | 1785559103 | yes | 32 518 s | yes |

Tightest margin 11 908 s ≈ 3 h 18 m to `T0`; 11 332 s ≈ 3 h 08 m to `T_dispatch`. The second
column is the one that matters after §R4: **no agent file has been written since before T-22 was
dispatched**, so no stage of this task wrote one. Neither contingency-2 case arises — no mtime is
`≥ T0`, so there is no touched-without-edit NOTE to file.

### FZ-4 — NULL, and the null is informative

`diff scratchpad/t22_s0.txt scratchpad/t22_s1.txt` → no output. Expected per §8.2 and pre-ruled by
gate round 2 §10.5. `.harness/rejected-decisions.md` was already ` M` and stayed ` M`.

Beyond being expected, this null is the **live demonstration of FZ-1's degraded blindness**: a real
+23-line content change to an already-dirty file moved nothing in the porcelain output. FZ-4 is
therefore not merely the weakest predicate — on this tree it is a worked counterexample to using
`git status` as a freeze proof. See §R6.

### FZ-5 — PASS, 8/8 exact

Every `wc -l` equals §8.3's reference value with **zero** deltas; D-13's ±1 tolerance is not
invoked. Total 1376 = §8.3's total. Max value 293 (`pm-orchestrator`), 7 under the I.3 cap; next
287 (`supervisor`), 13 under. D-12's confirmation of `01` §4.3 reproduces exactly.

### C-1 — SATISFIED, and moot

`H0_date` 1782025219 (2026-06-21T07:00:19Z) precedes `min(A7b)` 1785591621 by **3 566 402 s
≈ 41.3 days**, and precedes `T_dispatch` by 3 565 826 s. `H0` predates the task by a wide margin,
so the condition the gate set is met. But C-1 existed to underwrite D-15's transfer of stages 0–2
coverage onto FZ-1, and FZ-1's *other* premise failed, so satisfying C-1 no longer buys that
transfer. Recorded as satisfied and as insufficient on its own.

---

## R6. Mutation test — showing the proof discriminates

§10.2 item 1 / R-2 assign this to stage 6. Run here as well because stage 5's substantive check is
whether this document *supports* AC-6 or merely asserts it, and a predicate never observed to fail
cannot support anything. **This does not discharge stage 6's obligation** — QA must reproduce it
independently, per §11.

**Method M-a — the three filesystem predicates (FZ-2, FZ-3, FZ-5).** `agents/developer.md` copied to
a scratch directory; mtime pinned back to the original 1785579706 so the control differs from the
original in nothing; then `model: haiku` appended — the exact change this task declines.

**Method M-b — the two git predicates (FZ-1, FZ-1′).** A path-scoped git command cannot see a
scratch copy outside the work tree, and measuring it on the real tree would require writing under
`agents/`, which AC-6 forbids. So a **scratch git repository** was built instead: `git init` in the
scratchpad, the eight `git show cb0ed57:agents/*.md` blobs committed as its HEAD, then the eight
live files copied into its work tree. Its control reproduces the real tree's FZ-1′ output
**per file exactly** — `40/13, 27/39, 41/16, 47/4, 33/9, 45/21, 51/26, 4/2`, total **288/130**,
identical to §R3 — which is what makes it a faithful stand-in. The mutation is then applied inside
that repo.

**No file under `agents/` was written by either method** — checked after the run:
`sha256sum agents/developer.md` = `a7fabb1c…9152`, unchanged, and `git status --porcelain --
agents/` still returns exactly the eight ` M` lines. Both scratch trees removed after.

| predicate | method | control | mutated | fires? |
|---|---|---|---|---|
| FZ-2 digest | M-a | `a7fabb1c…9152` | `3ada48b2…dc79` | **FIRES** ✔ |
| FZ-3 mtime vs `T0` | M-a | 1785579706 (`< T0`) | 1785596217 (`> T0` by 4 596 s) | **FIRES** ✔ |
| FZ-5 line count vs 91 | M-a | 91 | 92 | **FIRES** ✔ |
| FZ-1 `git status`, ` M` form | M-b | 8 × ` M` | 8 × ` M` | **does NOT fire** ✘ |
| FZ-1 `git status`, `??` form (M5) | M-b | no `??` | `?? agents/sneaky.md` | **FIRES** ✔ |
| FZ-1′ `git diff --numstat -- agents/` | M-b | 288 / 130 | **289 / 130** | **FIRES** ✔ (by +1) |

The FZ-1′ mutated cell is `28 39 agents/developer.md` in place of `27 39`, every other file
unchanged. **Provenance note, because it matters for reproduction:** the numbers `156/0 → 179/0`
that a reader may have seen against this row elsewhere are **not** FZ-1′. They are the pre- and
post-append numstat of `.harness/rejected-decisions.md` against `H0` (§R2, `:190`) — this task's own
edit used as a real-data demonstrator of the FZ-1/FZ-1′ contrast. That is a different experiment and
is reported as one; the FZ-1′ row above is measured under the method its own row declares.

Four results worth stating plainly:

- **The FZ-1′ signal is real but minimal: +1 insertion.** A one-line append moves the numstat by one
  line and nothing else. It is a genuine discriminator and the weakest one in the table.
- **D-13's ±1 tolerance would have swallowed FZ-5's signal.** A `model:` key adds exactly one line,
  which is exactly the trailing-newline artefact D-13 tells the developer to forgive. The
  discriminator D-13 names — FZ-2's digest — is what separates them, and it changed. D-13 is
  correctly specified; the point is that FZ-5 **alone** cannot carry a one-line mutation, so it must
  never be quoted as an independent leg for a `model:`-key edit specifically.
- **FZ-1's ` M` form does not discriminate content on this tree**, demonstrated on real data rather
  than argued (the FZ-4 null, §R5). Rows 4 and 6 are the same predicate at two resolutions, and only
  the finer one is evidence.
- **FZ-1's `??` form does discriminate, and FZ-1′ does not.** Adding `agents/sneaky.md` produces a
  `??` line while `git diff --numstat -- agents/` stays at 288/130 — an untracked file contributes
  no diff. This is the one mode where degraded FZ-1 is the *only* git-side leg, which is why it is
  claimed above rather than written off. FZ-2/FZ-5's eight-file glob would also see it (9 files).

**Why M-b exists at all — a gap in §10.2 item 1's instruction, reported not corrected.** The design
tells the tester to *"copy `agents/developer.md` into a scratch directory, append a `model: <tier>`
line, and run FZ-1, FZ-2, FZ-3 and FZ-5 against the mutated copy"* (`02:314-316`). FZ-1 is
`git status --porcelain -- agents/`; a copy in a scratch directory is outside the work tree and
untracked, so that command cannot see the mutated copy and returns the unmutated tree's output no
matter what the copy contains. Run literally, FZ-1's row is guaranteed not to fire for reasons that
have nothing to do with the predicate's power. M-b is the smallest faithful executable reading —
same mutation, same commands, a tree where the command can actually observe it — and it is what
makes the ✘ in row 4 an honest measurement rather than an artefact of the fixture. Carried to stage
6 as an open issue; `02` is not this stage's to edit.

---

## R7. Verification detail

| id | Result | Evidence |
|---|---|---|
| V-1 | PASS 32 / WARN 0 / FAIL 0, `exit=0` | Full output at §R3.1 |
| V-2 | 32, unchanged | `[G.4] Doc count/version claims consistent with plugin.json + live check count … PASS`; `verify_all.sh:826` derives `g4_count=$(( ${#report[@]} + 1 ))` |
| V-3 | `[E.1] … PASS` | `sync-self` not run (C-4); `docs/dev-map.md:172` — "NOT byte-synced (sync-self touches only the 8 script pairs)" |
| V-4 | `[I.6] … PASS` | Scope confirmed non-vacuous: `git ls-files .harness/rejected-decisions.md` returns the path (I.6's scan source), and the path is in neither `i6_exempt_files` (8 entries, read at `verify_all.sh:666-675`) nor `i6_exempt_dirs` (`docs/features/`, `参考/`). The check ran **over** the appended text and passed. |
| V-5 | `[I.3] … PASS` | FZ-5; max 293 ≤ 300 |
| V-6 | No `.ps1` executed | Only `bash .harness/scripts/verify_all.sh` was run; no `.ps1` file was read or written |

**Exit semantics, read in place.** `02` §10.1's citation `verify_all.sh:932-934` is **exact**:
`932` is `(( errors > 0 )) && exit 2`, `933` is `(( warns > 0 )) && exit 1`, `934` is `exit 0`.
Semantics are as the design and gate state: a WARN exits 1, so `WARN: 0` plus `exit=0` is the
conjunction C-5 asks for. Downstream stages must not renumber this citation.

---

## R8. Things deliberately not done

- **`sync-self` not run** (C-4, RK-7). No mapping exists for this file; E.1 PASSed without it.
- **No `agents/*.md` touched** — the declined change itself (AC-6, §15).
- **§6 not corrected.** C-2 / D-1. Nothing in §6 looked wrong on inspection; the two pre-ruled
  rounding pairs (44 % vs 43.9 %, 0.02/0.83 vs 0.017/0.834) were checked and left alone.
- **The archived `Origin` path not "fixed"** (D-4, RK-3, gate round 2 §10.4); **no difference
  manufactured for FZ-4** (gate round 2 §10.5).
- **`docs/dev-map.md` not edited** — no file added, moved or removed; `:85` and `:172` already
  describe this file and its role, both still accurate.
- **`BATCH_PLAN.md:37` left `in-progress`** (§15 — the disposition is the operator's act).
- **No version bump, no CHANGELOG entry, no `docs/tasks.md` edit, no new pool row.**
- **No `verify_all` check added, removed or renamed** — count stays 32.
