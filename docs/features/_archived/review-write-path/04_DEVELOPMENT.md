> Contract portion. Rationale: 04_RATIONALE.md (absent = none written).

# Development Record

## Summary

Stages 3 and 5 now state one arrangement in all three contracts: the review agent **authors** the
document body and returns it; the PM Orchestrator **writes** it verbatim. No tool grant moved, no
check was added, no file was created anywhere. Six files changed — three agent contracts, one
distributed template, and the two hand-maintained `workflow.md` twins.

## Files changed

- `agents/pm-orchestrator.md` — L-1 (P8 markers on stage-table rows 3/5), L-2 (the P1–P7
  transcription block after `:42`), L-3 (C1 fold of the detection fence), L-4 (C2 deletion of the
  duplicated delivery tail, plus a zero-cost specificity carry into step 9 — see Design drift).
- `agents/gate-reviewer.md` — L-5 … L-12 (G1 write-act statement, G2 bracket, G3/G4 anaphors,
  G5 parenthetical deleted, G6 extensional hard rule 1, G7 verdict-artifact rule, G8 in-band header).
- `agents/code-reviewer.md` — L-13 … L-20 (K1 … K8). K7's mandatory re-read found a real conflict;
  see Design drift.
- `skills/harness-init/templates/common/AI-GUIDE.md.tmpl` — A1 (`:51`), A2 (`:53`).
- `docs/workflow.md` — A3 (`:18`).
- `skills/harness-init/templates/common/docs/workflow.md` — A4 (`:18`, the byte-identical twin).

L-25 / L-26 were **not** re-applied (Q-6): `CONTEXT.md` and `.harness/rejected-decisions.md` carry
mtimes of 10:24, from the architect's stage-2 pass, and are untouched by me.

## verify_all result

- Baseline (immediately before any edit): `PASS: 32  WARN: 0  FAIL: 0`, exit 0.
- After changes: `PASS: 32  WARN: 0  FAIL: 0`, exit 0.
- Delta: 0 new failures, 0 new warnings, baseline preserved. No test deleted, none added
  (this change adds no executable surface).
- **AC-11.** Identifiers emitted by the run, in order, 32 of them, unchanged before and after:
  `A.1 A.2 B.1 B.2 C.1 C.2 D.1 D.2 D.3 E.1 E.2 E.3 E.4 E.4b E.5 E.6 E.7 F.1 F.2 G.1 H.1 G.2 G.3 I.1 I.2 I.3 I.4 I.5 I.7 I.6 J.1 G.4`.
  No `.harness/scripts/*` file is in the change set.
- **AC-12.** No `.ps1` path in the change set. The standing operator-obligation list stays at
  **25 (17 numbered plus 8 un-numbered)**, untouched and un-renumbered.

## C-5 — line counts, every one by live `wc -l`

Run before any edit and again after the last one. **No count in `01` or `02` reproduced except
`supervisor`.**

| File | `01` E-15 / `02` claimed | Live `wc -l` BEFORE | Live `wc -l` AFTER | Cap | Headroom |
|---|---|---|---|---|---|
| `agents/pm-orchestrator.md` | 294 | **293** | **296** | 300 | 4 |
| `agents/gate-reviewer.md` | 114 | **113** | **125** | 300 | 175 |
| `agents/code-reviewer.md` | 167 | **166** | **177** | 300 | 123 |
| `agents/supervisor.md` (cited, untouched) | 287 | **287** | **287** | 300 | 13 |

Three of the four inherited figures were high by exactly one. All four files end with a newline
(`tail -c 1` = `0a`), so `wc -l` equals the physical line count and equals what `verify_all` I.3
reads (`n=$(wc -l < "$f")`, `verify_all.sh:451`). G-9's doubt was correct and the true base was
**293**, not 294. The measurement narrative is in `04_RATIONALE.md` §D1.

**Budget reconciliation for the capped file.** 293 − 5 (C1) − 3 (C2) + 11 (block, incl. its
separator blank) + 0 (P8, in-cell) + 0 (step-9 carry, in-line) = **296**. This is ≤ 297, the
design's restated measured ceiling, and ≤ 300, the hard gate. I.3 reports PASS.

**C1 freed 5 net lines, not 6.** The design counted `:140-146` as 7 deletable physical lines, but
`:140` and `:146` are the paragraph's two separator blanks and exactly one of them must survive the
fold. Deletable is 6 (`:140` + the 5 fence lines `:141-145`); the fold spends 1 (a 1-line sentence
becomes 2). The gross figure is therefore 9, not 10, and net 8, not 9. This is why the block was
re-wrapped once, from ~110 to ~130 columns, to land at 296 rather than 297 — condensation inside
the same file, as the design directs, with no P-item dropped and nothing moved elsewhere.

## DEV-1 — which build governs a dispatched stage (established from a shell)

**The observation confirms D-8 and sharpens it.** Commands and output:

| # | command | output |
|---|---|---|
| 1 | `git status --porcelain agents/ .claude-plugin/` | 10 modified: all 8 `agents/*.md`, plus `.claude-plugin/marketplace.json` and `plugin.json` |
| 2 | `git log -1 --oneline` | `cb0ed57 feat(v0.44.0): resilient lifecycle hooks + Windows repair-path fixes (T-12)` |
| 3 | `ls -1 ~/.claude/plugins/cache/harness-kit-marketplace/harness-kit/` | `0.44.0` — one version dir |
| 4 | `diff <cache>/agents/gate-reviewer.md agents/gate-reviewer.md` | **differs**; 67 diff lines; cache `88` lines vs working tree `113` |
| 5 | `sha256sum` cache vs working tree | `e476f619…` vs `2f85ef7d…` |
| 6 | `git show HEAD:agents/gate-reviewer.md \| sha256sum` | **`e476f619…` — byte-identical to the cache copy** |
| 7 | same identity test over all 8 agents | **8/8 `cache == HEAD`** |
| 8 | `grep '"version"' <cache>/.claude-plugin/plugin.json` | `0.44.0`; working tree declares `0.46.0` in both `plugin.json:4` and `marketplace.json:17` |
| 9 | `ls .claude/agents`, `ls .harness/agents` | both **No such file or directory** — no local override can shadow the plugin build |

**Cause of the version gap, which D-8 could only hand over as a question: both, and specifically.**
The cache is *not* lagging a published release — it is byte-identical to this repo's `HEAD` for all
eight agents, and `HEAD` **is** the v0.44.0 release commit. The entire gap is uncommitted
working-tree state: the eight modified `agents/*.md` and the two uncommitted version bumps to
`0.46.0`. No 0.45.0 or 0.46.0 was ever published, so the cache is already at the newest *published*
version. D-8's four-link chain (commit → push → marketplace publish → `/plugin` update → new
session) is therefore exactly right, and link 1 is the one that has not happened.

**No contradiction with D-8.** AC-8 stands as designed — the controlled reproduction with the
0.44.0 cache copy as the differential control. That control artifact exists and I read it: 88 lines,
materially different from the post-change 125.

Note the T-22 lesson applies and was honoured: `git status --porcelain agents/` was run live rather
than read off any context-carried snapshot, and it returns eight modified files.

## DEV-2 — write-act classification (C-10: total over every path-token hit)

Method: `grep -n '03_GATE_REVIEW\.md\|03_RATIONALE\.md\|05_CODE_REVIEW\.md\|05_RATIONALE\.md'` per
file, post-change, every hit classified. **Exactly one write-act statement per file.**

### `agents/pm-orchestrator.md` — 4 hits

| line | text (abbrev.) | class | why |
|---|---|---|---|
| 30 | `\| 3 \| gate-reviewer \| `03_GATE_REVIEW.md` — see the transcription rule below \|` | **constraint** + **pointer** | "Output document" attribution names the stage's output, no write/create/overwrite/replace verb, no acting role addressed. The P8 marker I added is a bare pointer — no verb at all (Q-8). |
| 32 | `\| 5 \| code-reviewer \| `05_CODE_REVIEW.md` — see the transcription rule below \|` | **constraint** + **pointer** | as `:30` |
| 46 | "**You write that body verbatim** to `docs/features/<task-slug>/03_GATE_REVIEW.md` /" | ***the* write-act statement (P3)** | addresses the acting role ("You") **and** applies `write` to the declared paths |
| 47 | "`05_CODE_REVIEW.md`, and a returned rationale portion to `03_RATIONALE.md` / `05_RATIONALE.md`" | same sentence as `:46` | continuation of P3; not a second statement |

P8's marker was **worded** as a pointer from the start, so no reclassification was needed (C-10's
conditional did not fire). Out of scope by construction: the `## Round records` block (pre-change
`:84-88`, now `:95-99`) names a different path and a different act, and is unedited.

### `agents/gate-reviewer.md` — 6 hits

| line | text (abbrev.) | class | why |
|---|---|---|---|
| 15 | "and **the PM Orchestrator writes them** to `…/03_GATE_REVIEW.md` and" | ***the* write-act statement (G1)** | names the acting role **and** applies `writes` to the declared paths |
| 16 | "`03_RATIONALE.md`, verbatim, authoring no part." | same sentence as `:15` | continuation of G1 |
| 18 | "**The contract portion** — `…/03_GATE_REVIEW.md`. It opens with the line" | **constraint** | a schema property of the document; no write verb, no actor |
| 19 | the quoted declared opening line, which contains `03_RATIONALE.md` | **quoted literal** | G-13's third case. It is a *quotation of bytes*, not a statement; it names no actor and applies no verb. Character identity preserved exactly (G2 / AC-8(a)) |
| 38 | "**The rationale portion** — `…/03_RATIONALE.md`, written **only when" | **constraint** | passive write verb, **no actor** — fails conjunct (i). The design orders this wording kept |
| 39 | the quoted rationale opening line, containing `03_GATE_REVIEW.md` | **quoted literal** | as `:19` |

G3 (`:34-35`), G4 (`:42-43`), G6 (`:86`) and G8 (`:65-69`) hit **zero** path tokens — they are anaphoric
("the same path", "that path", "each declared target path") exactly as Q-7 requires. The `PM_LOG.md`
sentence at `:36` is verbatim-unchanged and out of scope.

### `agents/code-reviewer.md` — 7 hits

| line | text (abbrev.) | class | why |
|---|---|---|---|
| 15 | "and **the PM Orchestrator writes them** to `…/05_CODE_REVIEW.md` and" | ***the* write-act statement (K1)** | names the acting role **and** applies `writes` to the declared paths |
| 16 | "`05_RATIONALE.md`, verbatim, authoring no part." | same sentence as `:15` | continuation of K1 |
| 18 | "**The contract portion** — `…/05_CODE_REVIEW.md`. It opens with the line" | **constraint** | as gate `:18` |
| 19 | quoted declared opening line, containing `05_RATIONALE.md` | **quoted literal** | as gate `:19` |
| 42 | "**The rationale portion** — `…/05_RATIONALE.md`, written **only when" | **constraint** | passive, no actor |
| 43 | quoted rationale opening line, containing `05_CODE_REVIEW.md` | **quoted literal** | as gate `:39` |
| 122 | `> Contract portion. Rationale: 05_RATIONALE.md (absent = none written).` | **quoted literal, inside the fenced example** | the schema example's own first line (K7) |

K3 (`:36-37`), K4 (`:45-46`), K5 (`:101`) and K8 (`:48-52`) hit zero path tokens. K5 points at
`## What you produce` rather than re-naming an actor, so Hard rule 2 does not become a second
write-act statement while still answering AC-4 with the same answer as the schema section: **no —
it authors the body, the PM writes it**.

**AC-10 is therefore mechanical.** Delete `:46-47` / `:15-16` / `:15-16` respectively and each file
retains only constraints, quoted literals and anaphors with no antecedent.

## DEV-3 — the C1 fold, before and after

**Before** (`agents/pm-orchestrator.md:139-146`, 8 lines shown; `:147` unchanged):

```
by their bare local name. Detect at start of stage 4:

```
List files matching .harness/agents/dev-*.md
  - If none: single Developer mode. Dispatch the plugin `harness-kit:developer` agent.
  - If found: partitioned mode. Continue below (dispatch the project-local dev-* agents).
```

```

**After** (`agents/pm-orchestrator.md:150-151`):

```
by their bare local name. At stage 4, list `.harness/agents/dev-*.md`: none ⇒ single-Developer mode,
dispatch the plugin `harness-kit:developer` agent; found ⇒ partitioned mode, dispatch the project-local `dev-*` agents.
```

Both branch outcomes survive, as the C1 clause obliges:

| branch | required outcome | present in the fold |
|---|---|---|
| none | single Developer mode; the literal dispatch target **`harness-kit:developer`** | yes — "none ⇒ single-Developer mode, dispatch the plugin `harness-kit:developer` agent" |
| found | partitioned mode; **dispatch the project-local `dev-*` agents** | yes — "found ⇒ partitioned mode, dispatch the project-local `dev-*` agents" |

The only text not carried is the navigational "Continue below", which is not a branch outcome and
is supplied by the next paragraph, "In partitioned mode, for each stage-4 dispatch:". G-12's
correction is confirmed against the live file: `harness-kit:developer` does also appear at `:147`
as the naming-convention example, so the fold preserves the branch *instruction*, which is what the
clause requires.

## C-4 / AC-5 — audit-set derivation, re-run and reconciled (total)

I re-ran S1 … S5 myself at implementation time. **Reconciliation against the ledger produced one
methodological finding and eleven sites the design's table does not name individually**; every one
is dispositioned below.

### The search instrument had to be corrected before it was total

`rg` skips dot-directories by default. **S1 as written in `02` returns nothing under any
`.harness/` path** — which silently drops every ⊕ template-twin row the design added to close C-4,
including all six `dev-*.md.tmpl` files and both `60-tool-handoff.md` copies. Re-running with
`--hidden` recovered 25 further lines. A C-4 publication built on S1 as literally specified would
have been non-total in exactly the class C-4 exists to prevent. All results below are `--hidden`.

### Sites CHANGED (reconciles 1:1 with ledger rows L-1 … L-24)

| site | found by | disposition |
|---|---|---|
| `agents/pm-orchestrator.md:30,:32`, after `:42`, `:139-146`, `:235-237` | S1, S2 | changed — L-1 … L-4 |
| `agents/gate-reviewer.md` `:14`(head), `:14-16`, `:29-30`, `:32-33`, `:36-37`, `:57`, `:74` | S1, S2 | changed — L-5 … L-12 |
| `agents/code-reviewer.md` `:14`(head), `:14-16`, `:31-32`, `:36-39`, `:88`, `:95`, `:108-152` | S1, S2 | changed — L-13 … L-20 |
| `skills/harness-init/templates/common/AI-GUIDE.md.tmpl:51,:53` | **S3** | changed — L-21/22. S3 is the only search that binds a write verb to the filenames, and post-change it returns these two lines in their corrected form |
| `docs/workflow.md:18` | **S4 only** | changed — L-23. Confirmed: S1 returns `:10`,`:12` and S2 returns `:10`; neither returns `:18`. The design's line-granularity headline is exactly true |
| `skills/harness-init/templates/common/docs/workflow.md:18` | **S4 only** | changed — L-24. `cmp` confirms the twins are byte-identical after the change |

### Sites NOT changed — the design's table, each row re-derived live

| site | live line numbers | found by | disposition |
|---|---|---|---|
| `agents/supervisor.md:97,:99` | confirmed `:97`,`:99` | S1 | unchanged — stage-doc validity table (required headings + minimum lines); no authorship attributed. `:4`,`:9`,`:283` = RES-5 (OQ-4), not repaired here |
| `AI-GUIDE.md` (dogfood) `:51` | confirmed `:51` | S2 | unchanged — arrow chain only, no per-agent "writes" list |
| `skills/harness/SKILL.md:36,:38`; `skills/harness-plan/SKILL.md:3,:32,:56`; `skills/harness-explore/SKILL.md:82` | confirmed; design's `:52-58` range resolves to `:56` | S1, S2 | unchanged — "Output: `03_GATE_REVIEW.md`" names the **stage's** output, true under D-1; no write verb attributed to a role |
| `.harness/rules/60-tool-handoff.md:32-33,:125` | design said `:122-127`; live is `:125` | S1 | unchanged — read list + resume rule. `:122` forbids **editing** an upstream-authored document, which a verbatim transcription authoring no part does not do |
| `.harness/rules/70-doc-size.md:39` | confirmed `:39` | S4 | unchanged — passive definition, attributes no role |
| ⊕ `…/templates/common/.harness/rules/70-doc-size.md.tmpl:38` | confirmed `:38` | S4 (**needs `--hidden`**) | unchanged — distributed twin of the passive definition. The highest-risk omission of the set; recorded as checked |
| ⊕ `…/templates/common/.harness/rules/00-core.md.tmpl:15` | confirmed `:15` | S1 (**`--hidden`**) | unchanged — a filename set |
| ⊕ `…/templates/common/.harness/rules/_ai-native-prompt.md:22-23` | confirmed `:22-23` | S2 (**`--hidden`**) | unchanged — `RESERVED_NAMES` list |
| ⊕ `…/templates/common/.harness/rules/60-tool-handoff.md:32-33,:122` | confirmed `:32-33` and `:122` — the design's correction of the gate's `:34` is right | S1 (**`--hidden`**) | unchanged — distributed twin; read list + resume rule |
| ⊕ 6 × `dev-*.md.tmpl` | confirmed exactly: `backend/dev-api:48`, `backend/dev-db:48`, `backend/dev-services:49`, `fullstack/dev-backend:44`, `fullstack/dev-db:46`, `fullstack/dev-frontend:49` | S1 (**`--hidden`**) | unchanged — stage-4 **read lists**; no writing or authoring verb, and the arrangement does not change what stage 4 reads |
| ⊕ `skills/harness-supervise/fixtures/sample-task/PM_LOG.md:29,:43`; `…-three-rollbacks/PM_LOG.md:29` | confirmed | S1 | unchanged — fixtures recording a stage's output; editing one changes what the supervisor tests without changing what it tests *for* |
| ⊕ `docs/tasks.md:15,:29` (and `:17`, found by S4) | confirmed | S1, S2, S4 | unchanged — historical ledger rows. `:15` is the T-22 row recording this very defect; it is the evidence trail, not an attribution to repair |
| ⊕ `CHANGELOG.md` — S2 returns `:43`; S1 returns `:943`,`:1194`; S2 also `:436,:438,:447,:592,:608,:1203,:1230,:1503-1579,:2323`; S4 returns `:42` | confirmed `:43` (the design's correction of the gate's `:42` is right — `:42` is a *separate* S4 hit) | S1, S2, S4 | unchanged, **class-level**: a released record is never rewritten, and **no entry is added** (Q-9). No `CHANGELOG.md` line is edited by this task |
| `docs/dev-map.md:132`; `.harness/insight-index.md:19,:30,:54-61` | confirmed | S1, S2, S4 | unchanged — passive / historical; the T-22 insight entry stays true under D-1 and entries are not rewritten |
| `agents/{requirement-analyst,solution-architect,developer,qa-tester}.md` | live: `requirement-analyst:34`, `solution-architect:44`,`:66`, `developer:16`,`:38`, `qa-tester:27`,`:74`,`:82` | S1, S4 | unchanged — rationale-portion lines are passive and all four roles hold `Write` (S5); the rest are read lists attributing no authorship |
| `docs/*.html`, `README.md:40`, `README.zh-CN.md:40`, `docs/concepts.md:73,:75` | live: `project-overview.html:401-402,:411-412`, `v0.11-changes.html:65,:67,:135,:409`, `walkthrough.html:393,:398,:539,:543,:629`, `architecture.html:899`, `parallel-stream-design.html:236` | S1, S2 | unchanged — pipeline diagrams and role tables; **none attributes a writing or authoring verb** to either document (re-verified this round) |
| `docs/features/_archived/**`; `.harness/scripts/*` | — | excluded / S5 | out of scope §3.4; no script reads a `tools:` line or an authorship attribution — check count stays 32 |

### Sites the design's table does not name individually — dispositioned here for totality

| site | found by | disposition |
|---|---|---|
| `skills/harness/SKILL.md:47` | S1 | unchanged — "The `03_GATE_REVIEW.md`'s `APPROVED FOR DEVELOPMENT` verdict is the prerequisite"; names a verdict, no writer |
| `skills/harness-plan/SKILL.md:26` | S2 | unchanged — names which stages run; no write verb |
| `.harness/scripts/test-verify-i6.sh:586,:587,:626,:627`; `.ps1:635,:665,:666` | S1 (**`--hidden`**) | unchanged — the string `docs/features/some-task/03_GATE_REVIEW.md` used as a **synthetic path fixture** for the I.6 exemption predicate. A path literal in a test, attributing nothing. Editing it would change a regression's input |
| `.harness/scripts/{test-init,test-real-project,verify_all}.{sh,ps1}` (role-name lists: `verify_all.sh:74`, `.ps1:89`, `test-init.sh:184,:215,:546`, `.ps1:197,:506`, `test-real-project.sh:193`, `.ps1:152`) | S2 (**`--hidden`**) | unchanged — D.1 presence checks and reserved-name guards keyed on the role **identifier**. S5's companion proof: no script carries a `tools:` matcher |
| `.harness/rejected-decisions.md:69,:187` | S2 (**`--hidden`**) | unchanged — `:69` is an unrelated decline; `:187` cites an archived `05_CODE_REVIEW.md:458` as evidence. Historical citations are not rewritten |
| `.harness/rejected-decisions.md:282-308` (`reviewer-write-grant`, incl. `:284`,`:287`) | S2, S3 (**`--hidden`**) | unchanged — **L-26, already applied at stage 2** (Q-6). `:287`'s "the grant that lets the gate reviewer write `03_GATE_REVIEW.md`" is S3's only remaining non-corrected hit and is *correct as written*: it describes the **declined** option |
| `CONTEXT.md:50,:56` | S4 | unchanged — **L-25, already applied at stage 2** (Q-6) |
| `.harness/rules/60-tool-handoff.md:34` and its twin `:34` | S4 (**`--hidden`** for the twin) | unchanged — "Open a `0N_RATIONALE.md` sibling only when one …": a **read** rule for a downstream consumer, no authorship attributed |
| `…/templates/i18n/zh/_policy/output-language.zh.md.tmpl:18` | S4 (**`--hidden`**) | unchanged — a zh-language filename enumeration; no verb bound to a role |
| `agents/supervisor.md:111` | S4 | unchanged — the AP-2 exclusion for `0N_RATIONALE.md`; passive, attributes no role |
| `docs/batches/default/{BATCH_PLAN.md:18,:52, STREAM_LOG.md:39, STREAM_REPORT.md:61}`; `docs/proposals/frontier-gaps-2026-07.md:36`; `docs/features/_supervision/entropy-2026-08-02.md` | S2 | unchanged — historical batch/stream records, an operator-authored proposal, and the sweep artifact that is this task's read-only **input** (§3.3) |

### S5 — proof that no tool grant moved (AC-11 companion)

Identical before and after; `gate-reviewer:4` and `code-reviewer:4` both remain `Read, Glob, Grep`,
`pm-orchestrator:4` remains `Read, Write, Edit, Glob, Grep, TodoWrite, Task`. All eight lines are
listed in `04_RATIONALE.md` §D2.

## Design drift

**DESIGN DRIFT 1 (MINOR, K7 / L-19) — the fenced example at `code-reviewer.md:108-152` did not
match the schema, and I changed it.** The design predicted "no content change is expected" and made
the check mandatory anyway. The check bit.

- What K2 mandates (from G2, verbatim): the returned body "**is the complete file content, begins
  with that line and ends with the `## Verdict` line**". `02_RATIONALE.md:158-159` and `:181-182`
  confirm this is meant literally — the opening line is "part of what the author returns … rather
  than something the writer is trusted to prepend", and the bracket is "begins with the declared
  opening line and ends with the `## Verdict` line". P6(a) and AC-8(a) both key on it.
- What the fence showed: `# Code Review` on fence-line 1, a blank, then the declared opening line
  on fence-line 3 (file `:111`).
- So after K2, the file's own worked example contradicted the file's own schema — the exact
  internal-inconsistency class R-8 / AC-4 exist to prevent, and the class T-18 QA-12 named
  (an instruction rendered only inside a schema example).
- **Repair:** deleted the `# Code Review` heading and its blank from inside the fence (2 lines).
  K7's three literal requirements all still hold — the fence still shows the opening line (now
  `:122`), still ends with `## Verdict`, and gained no round or changelog section.
- **Why this direction and not the other:** the produced artifacts already converged on it.
  `03_GATE_REVIEW.md:1` in this very task folder is the marker line with no H1, and E-10 records
  `06:1` likewise. `agents/gate-reviewer.md` carries no fenced example, so stage 3 had no conflict
  to expose. `agents/supervisor.md:97,:99` requires only `## Findings` / `## Verdict` and a minimum
  line count — no mechanism anywhere requires an H1. Full argument: `04_RATIONALE.md` §D3.
- **This is a reviewer decision point.** It changes the shape of every future `05_CODE_REVIEW.md`.
  The alternative — keep the H1 and weaken K2/P6(a)/AC-8(a) to "carries" instead of "begins with" —
  is a design change I do not own; if stage 5 prefers it, it is a route-back to the architect.

**DESIGN DRIFT 2 (trivial, L-4) — one clause carried instead of deleted.** C2 deletes `:236-237`.
G-12 observed that `:236` carries "append a one-line entry referencing this folder", a specificity
`:181` does not restate. Rather than lose it, I folded it into `:181` in place, at **zero line
cost**: step 9 (pre-change `:181`, now `:187`) reads "update `docs/tasks.md` with the delivery
result — a one-line entry referencing this task's folder." Both deleted sentences are gone as C2
requires and the surviving mode-independent carrier is still steps 9–10 (now `:187-188`). Flagged
because it edits a line no ledger row names.

**No other deviation.** P6 is stated in the positive ("check that the body begins with … / ends
with … / every header-named path has a portion present with no author-reported partial return; on
any failure nothing is written at all") rather than the design's negative "three conditions make a
return non-intact". All three conditions and the consequence are present; the positive form is
shorter, which the line budget needed. Recorded as a wording choice, not a content change.

## Open issues for review

1. **RES-3 is untouched, as designed.** Nothing in this change set makes the edited contracts govern
   a dispatched stage. DEV-1 measures link 1 of the chain as unstarted: `HEAD` is v0.44.0 and every
   edit sits uncommitted. QA's AC-8 must run as the controlled reproduction; a "live dispatch" would
   silently exercise the 0.44.0 build.
2. **`agents/pm-orchestrator.md` has 4 lines of headroom** (296/300). The next task that adds prose
   there will have to condense first. The two condensation sites this task used are spent.
3. **`agents/supervisor.md:283`** still carries the same mis-attribution (RES-5 / OQ-4). The
   formulation to apply is now live at `gate-reviewer.md:86` (G6) and `code-reviewer.md:101` (K5).
4. **The `docs/workflow.md` twins are byte-identical right now** (`cmp` clean) and nothing keeps
   them so. R5's class is live.
5. **`02`'s S1 as literally specified is not total** (see C-4 above). If a future task inherits that
   search string, it will miss every `.harness/` path again.
6. **The same schema/example mismatch as DRIFT 1 exists in `agents/developer.md`** — `:15` says
   `04_DEVELOPMENT.md` "opens with the line `> Contract portion. …`", while its fenced template in
   "What `04_DEVELOPMENT.md` must contain" opens with `# Development Record`. It is **out of scope**
   here (no ledger row, and D-6 disposes of `agents/developer.md` as unchanged), so I did not touch
   it; this document itself follows the schema statement, marker first. `requirement-analyst.md`,
   `solution-architect.md` and `qa-tester.md` are likely to carry the same mismatch. If stage 5
   upholds DRIFT 1, this wants its own queued row rather than a silent fix here.

## Dev-map updates

**None.** No file was created, moved or removed; no module boundary changed. `docs/dev-map.md`
already describes `agents/` and the two `workflow.md` copies correctly, and its only path-token hit
(`:132`) is a passive statement that stays true under D-1.

## Insight to surface

- 2026-08-02 · `rg` skips dot-directories unless `--hidden` is passed, so a repository-wide audit
  search written without it silently returns **nothing** under `.harness/` — here it dropped all six
  `dev-*.md.tmpl` files, both `60-tool-handoff.md` copies, `00-core.md.tmpl`, `_ai-native-prompt.md`
  and `70-doc-size.md.tmpl` from a totality audit whose whole purpose was to catch that class, while
  still returning enough hits to look complete · evidence: T-23, `02_SOLUTION_DESIGN.md:282` S1 run
  with and without `--hidden` (25-line delta)
- 2026-08-02 · A `Read` of a file with no `limit` reports one line more than `wc -l` for three of
  four agent contracts here, so line counts transcribed from a full read (E-15's 294 / 167 / 114)
  were each high by one while `supervisor`'s 287 happened to match — a 300-line hard gate planned
  off read-derived counts is planned off a figure that is wrong in the *unsafe* direction only by
  luck · evidence: T-23, live `wc -l` 293 / 166 / 113 / 287 vs `01` E-15

## Verdict

READY FOR REVIEW
