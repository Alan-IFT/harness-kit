# 02 — Solution Design · T-11c entropy-watch-persist

> Mode: **full** (final slice) · Stage 2 (Solution Architect) · deferred-human mode (defer, do not ask) ·
> Upstream verdict: `01_REQUIREMENT_ANALYSIS.md` = **READY** · scope = decline-filter ONLY (the
> standalone findings store was DECLINED as overkill upstream; this design does not build it).

## Overview

The anti-entropy watch already re-derives its findings table from the live tree on every sweep
(`references/entropy-scan.md` Determinism clause: ID+class+Where+strength are a pure function of
current structure). Therefore OPEN and FIXED need **no new storage** — a fixed module stops being
shallow and silently drops; a still-shallow module re-surfaces on its own. The only genuinely-new
wiring is the **DECLINE path**, and that reuses the T-09 memory (`.harness/rejected-decisions.md`)
wholesale: a declined deepening *is* a rejected decision.

Two edits deliver it, both in the single scan-methodology source plus its two pointers:
1. The entropy scan, at the point it produces the findings list, **reads `.harness/rejected-decisions.md`
   and drops any finding whose normalized concept key matches a `declined`/`deferred` record** before
   writing the artifact. The artifact never emits a declined finding, so all three downstream surfaces
   (`/harness-deflate`, `/harness-stream` drain, `/harness` delivery) inherit the filter for free.
2. `/harness-deflate` step 4 gains a third user choice — **decline** — which appends a record to
   `.harness/rejected-decisions.md` in that file's existing record format (concept handle + `Decision:
   declined` + why + origin), reusing T-09's one-record-per-concept de-dup. No new store file.

No new script, skill, state file, `verify_all` check, placeholder, or count flip. Version 0.42.0 →
0.43.0 (distributed behavioral edit). `supervisor.md` stays ≤300; `references/entropy-scan.md` has no
doc-cap but stays tight. I.6 stays clean (the decline records and these docs must not quote banned
anchors — the `rejected-decisions.md` file is I.6-scanned).

## File-level change set

| # | File | New/Edit | What changes |
|---|---|---|---|
| 1 | `skills/harness-deflate/references/entropy-scan.md` | edit | Add a `## Decline filter (T-11c)` section: the read-source, the stable-key normalization, the match rule, fail-open, determinism note. This is the SINGLE source — neither pointer restates it. |
| 2 | `agents/supervisor.md` | edit | In the `## Entropy lens` stub, add ONE clause naming the decline-filter step + pointing at the scan reference's new section (no restatement). Widen the entropy-mode read-set by one already-class-whitelisted file (`.harness/rejected-decisions.md`). |
| 3 | `skills/harness-deflate/SKILL.md` | edit | Promote the step-4 T-11c placeholder ("A declined finding is a T-11c concern…") to the real **decline** action: append a record to `.harness/rejected-decisions.md`; specify the record fields + de-dup + the not-present-ID boundary. Point at the scan reference for the key rule; do not restate it. |
| 4 | `.claude-plugin/plugin.json` | edit | `"version": "0.42.0"` → `"0.43.0"` (G.3 stamp 1). |
| 5 | `.claude-plugin/marketplace.json` | edit | `"version": "0.42.0"` → `"0.43.0"` (G.3 stamp 2). |
| 6 | `README.md` | edit | badge `version-0.42.0-blue` → `version-0.43.0-blue` (G.3 stamp 3). NO ratio flip (verify_all 32/32, skills 17, integration 90/90 unchanged). |
| 7 | `README.zh-CN.md` | edit | badge `version-0.42.0-blue` → `version-0.43.0-blue` (G.3 stamp 4). NO ratio flip. |
| 8 | `CHANGELOG.md` | edit | Prepend a `## [0.43.0] - <ISO-date>` section (G.4 greps for `[0.43.0]`). Note "No count flip — skills 17, agents 8, verify_all 32 unchanged; no new check". |

**Total: 3 behavioral edits + 5 version/changelog stamps. No file created. No file deleted.**

## The exact addition #1 — decline filter in the scan

### Where it lives (single source)

A new `## Decline filter (T-11c)` section appended to
`skills/harness-deflate/references/entropy-scan.md`, immediately AFTER `## Entropy findings artifact`
and BEFORE `## Determinism + caps` (so it sits at the produce-the-findings-list point, and the
Determinism section can reference it). Both readers — the `supervisor.md` `## Entropy lens` stub and
the `SKILL.md` step-1 dispatch prompt — already point at this reference file; neither restates the
rule (NFR-1 DRY: one definition, two readers).

### The exact behavior the scan performs

After deriving the full findings list (ID + class + Where + strength + deletion test) and BEFORE
writing the artifact:

1. **Read** `.harness/rejected-decisions.md` (read-only; the supervisor already has Read, and entropy
   mode whitelists `.harness/` reads — this is one already-class-whitelisted file).
2. For each derived finding, compute its **stable key** (below) and check it against every record
   whose `- **Decision:** declined` or `- **Decision:** deferred` line is present.
3. **Drop** every finding whose stable key matches a declined/deferred record's concept handle. A
   dropped finding does NOT appear in the `## Findings` table, does NOT appear in `## Detail`, and does
   NOT contribute to the `Entropy-verdict:` FINDINGS-PRESENT/CLEAN determination (if every derived
   finding is dropped, the verdict is `CLEAN`).
4. Note the count of suppressed findings in `## Methodology notes` (informational, e.g.
   `decline-filter: 2 finding(s) suppressed by .harness/rejected-decisions.md`). This is NOT the
   declined "hidden count" surfaced in the report (out-of-scope OOS-6) — it is a methodology-notes
   honesty line about what the scan did and did not emit.

### The exact key-normalization + match rule (OQ-2 → recommended (a), per-path verbatim)

> **Stable finding key** = the finding's `Where (file/module)` cell, normalized to a concept handle,
> matched against a `.harness/rejected-decisions.md` record's **concept handle** (the `## <handle>`
> heading of the record). This mirrors T-09's one-record-per-concept de-dup. The per-run `EP-NNN` id
> is **NOT** the key (it is sequential per sweep and unstable across sweeps).

Normalization (deterministic, applied to BOTH sides before comparison):

1. **Trim** surrounding whitespace.
2. **Normalize path separators** to forward slash (`\` → `/`) so a Windows-authored handle and a
   POSIX-authored finding match.
3. **Strip** a leading `./` and any trailing `/`.
4. **No case folding, no directory coarsening** — compare the full path/handle string
   case-sensitively (matches exactly what the user saw and declined in the `Where` cell;
   component-level coarsening was the rejected OQ-2 alternative because it risks hiding findings the
   user never declined).

Match rule:

- A finding is dropped **iff** `normalize(finding.Where) == normalize(record.concept_handle)` for at
  least one `declined`/`deferred` record. Exact string equality after normalization — NOT substring,
  NOT prefix (substring/prefix would silently over-suppress sibling modules).
- The record's concept handle is the `## ` heading text of the record block in
  `.harness/rejected-decisions.md` (T-09 format: each record is a `## <handle>` block with
  `- **Decision:**`, `- **Why:**`, `- **Origin:**` bullets).
- **Two findings in one sweep that normalize to the same key** are BOTH dropped if that key is
  declined (boundary B-5: declining a module declines all co-located findings — acceptable).
- A declined record whose handle matches no current finding suppresses nothing (boundary B-4: stale
  record sits harmlessly, like any obsolete rejected-decision).

### Fail-open + determinism (NFR-2, NFR-3)

- **Fail-open**: if `.harness/rejected-decisions.md` is **absent** or unreadable, the filter is a
  no-op and ALL derived findings surface (never suppress on read failure — consistent with the
  cadence engine's fail-open posture). Absent file = "no declines" (boundary B-1). Header-only/empty
  file = "no declines" (boundary B-2).
- **Determinism preserved**: the filter is a deterministic set subtraction (declined-key set −
  derived-finding set). Over an unchanged tree AND an unchanged `rejected-decisions.md`, the post-
  filter list is identical across runs — NFR-6 determinism still holds. The `## Determinism + caps`
  section gains one sentence: "the structured list is identical across runs over an unchanged tree
  *and* an unchanged `.harness/rejected-decisions.md`; the decline filter is a deterministic set
  subtraction applied before the write."

## The exact addition #2 — `/harness-deflate` step-4 decline-record path

### Current state (the placeholder being promoted)

`skills/harness-deflate/SKILL.md` step 4 ("Authorize gate") currently parenthesizes the future work:
"(A declined finding is a T-11c concern: note the decline and do not execute; T-11c wires it to
`.harness/rejected-decisions.md`.)" This slice replaces that parenthetical with the real action.

### The exact step-4 behavior

Step 4 becomes a **three-way** user choice (the authorize gate stays intact — no refactor without an
explicit pick):

- **deflate this one** (existing) → go to step 5 (`/harness-goal` execute).
- **none** (existing) → every finding stays open, zero edits, stop.
- **decline EP-NNN** (NEW) → **memory-write only**, no refactor, no production-file edit:

  1. Resolve `EP-NNN` to the finding row in the just-presented artifact. **If the ID is not among the
     current findings** (boundary B-6) → report "EP-NNN is not among the current findings" and take
     NO memory-write (no silent guessing which module was meant).
  2. Compute the finding's **stable key** = `normalize(finding.Where)` (the SAME rule as the scan
     filter — defined ONCE in `references/entropy-scan.md`; SKILL.md points at it, does not restate
     it).
  3. **Append** a record to `.harness/rejected-decisions.md` in that file's existing record format:

         ## <stable-key>
         - **Decision:** declined.
         - **Why:** <user's stated reason, or "not worth the deepening" if none given>.
         - **Origin:** entropy sweep <ISO-date> · EP-<class>.

     where `<class>` is the finding's class word (`shallow module` / `cross-seam leakage` /
     `coupling cluster` / `deepening candidate`) — OQ-3 recommended (a): date + class, NOT the
     unstable per-run EP-NNN id.
  4. **De-dup (T-09 contract)**: if a record for `<stable-key>` already exists, append this origin to
     that record's `- **Origin:**` line (a re-occurrence) rather than creating a second record
     (boundary B-3 / acceptance #4). One record per concept.
  5. **Create the file** from the standard seed shape if it does not exist (boundary B-1: the decline
     action creates `.harness/rejected-decisions.md` if absent, matching how that file is seeded today).

### Tool capability check (no new capability granted)

`/harness-deflate`'s `allowed-tools` is `Read, Glob, Grep, Task` — it has **no `Edit`/`Write`**. The
memory-write must therefore happen the same way the skill already reaches an effect: it cannot edit a
file itself. **Decision (Mode-2 autonomous, reversible):** the append is performed by the **main agent
driving the skill** (the same agent that presents findings and reads the artifact), not by a sub-agent
— consistent with how decline-records are appended elsewhere in this repo (the decision policy's
"append a record there" habit is a main-agent action at a decide-point, not a dispatched Edit). The
SKILL.md text states the record-shape contract; the act of appending is the operator/main-agent
decision-recording habit governed by `.harness/rules/25-decision-policy.md`. This keeps the skill's
observer/dispatch boundary intact (the skill still owns no scan engine and no refactor loop) and adds
NO Edit capability to the skill's tool list. **No production code is edited; only the memory file
changes** (acceptance #5 — verify_all stays green).

> Note: this matches the requirement's framing — "decline is a memory-write only … the existing
> authorize-gate is unchanged; 'decline' is a third user choice." It is NOT a dispatch to a writing
> sub-agent (no new agent, no widened skill tool-set).

## OPEN / FIXED need NO store — explicit confirmation (no store is built)

Confirmed against `references/entropy-scan.md` Determinism clause ("the structured finding list is
identical across runs over an unchanged tree (NFR-6)"):

- **FIXED needs no store.** A deepened module is no longer shallow → the deletion test no longer flags
  it → it simply stops appearing in the next sweep's table. "Fixed" == "no longer surfaced", derived
  for free. No "remember this was fixed" record exists or is created.
- **OPEN needs no store.** A still-shallow module is re-derived every sweep and re-surfaces on its own
  (acceptance #6). No "remember this is still open" record exists or is created.
- **Therefore NO `entropy-findings.md`, NO read+write findings log, NO new state file is built.** The
  upstream RA DECLINED the standalone open/fixed store as overkill; this design honors that — building
  it would store a fact the scan already re-derives, adding a file + a read/write cycle + a drift
  surface (the design-over-guards / lightweight line). The only persistent artifact touched is the
  pre-existing T-09 `.harness/rejected-decisions.md` (declines only).

### Standard decline-record habit for the declined store concept

Per the RA's note (and this repo's standard "append a record when something is deliberately declined"
habit), the architect records the declined **standalone findings store** concept itself in
`.harness/rejected-decisions.md` so a future re-proposal finds the prior decision. Proposed record
(to be appended as part of this slice's delivery, de-dup-checked first):

    ## entropy-findings-store
    - **Decision:** declined.
    - **Why:** a standalone open/fixed findings log would persist what the entropy scan already
      re-derives every sweep (fixed == no-longer-surfaced; open == re-derived), adding a file plus a
      read/write cycle plus a drift surface to duplicate a property the design already has by
      construction. Declines are the only state that needs memory, and they reuse T-09
      rejected-decisions. Lightweight / design-over-guards line.
    - **Origin:** T-11c entropy-watch-persist scope-down (RA + architect).

This record must NOT quote any I.6 banned anchor (see I.6 note below); the wording above is plain
English describing a decline and contains none.

## Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| Decline memory (the store for "user said not worth it") | `.harness/rejected-decisions.md` + one-record-per-concept de-dup + read-at-decide-point habit | `.harness/rejected-decisions.md`, `.harness/rules/25-decision-policy.md` | Reuse as-is (T-09); a declined deepening IS a rejected decision |
| Stable-key / concept de-dup rule | T-09 one-record-per-concept (record = `## <handle>` block) | `.harness/rejected-decisions.md` header + `25-decision-policy.md` | Reuse the concept-handle as the finding key; define normalization once in scan ref |
| Findings re-derivation (open/fixed for free) | scan Determinism clause (pure function of tree) | `skills/harness-deflate/references/entropy-scan.md` §Determinism | Reuse — confirms no store needed |
| Scan methodology single-source | the scan reference, pointed at by both readers | `skills/harness-deflate/references/entropy-scan.md` | Extend with `## Decline filter` (one new section); both pointers reference it |
| Entropy-mode read widening posture | Hard-rule #1 exception (entropy mode widens READ scope, no write/exec) | `agents/supervisor.md` Hard rules + `## Entropy lens` | Reuse — adds one whitelisted read (`rejected-decisions.md`), no new capability |
| Authorize gate (no refactor without pick) | step-4 gate; `allowed-tools` excludes Edit/Bash | `skills/harness-deflate/SKILL.md` step 4, frontmatter | Reuse — add a third choice (decline) that is memory-write-only, no new tool |
| Fail-open posture | cadence engine fail-open | (T-11a cadence) | Reuse the pattern for the filter's read-failure path |
| Version stamp gate | G.3 (4 stamps) + G.4 (`[ver]` CHANGELOG heading) | `.harness/scripts/verify_all.{ps1,sh}` | Reuse — bump the 4 stamps + add CHANGELOG heading; no new check |
| Standalone findings store | (none — declined) | — | NOT built (RA + this design decline it as overkill) |

## Sequence / flow

### Sweep (decline filter)

```
/harness-deflate (or /harness-stream drain / /harness delivery)
  → dispatch supervisor in entropy mode (Task)
      → Glob/Grep/Read production source, derive findings list  [unchanged]
      → READ .harness/rejected-decisions.md                     [NEW: fail-open if absent/error]
      → for each finding: drop iff normalize(Where) == normalize(declined record handle)  [NEW]
      → write docs/features/_supervision/entropy-<ISO-date>.md   (declined findings never appear)
      → last line: Entropy-verdict: FINDINGS-PRESENT | CLEAN     (declined findings don't count)
  → present remaining findings table to user
```

### Decline (step 4, memory-write only)

```
user: "decline EP-007"
  → resolve EP-007 in the just-presented artifact
      → not present? report "EP-007 not among current findings", no write, stop  [B-6]
      → present: key = normalize(finding.Where)
  → .harness/rejected-decisions.md:
      → record for <key> exists?  → append this origin to its Origin line   [T-09 de-dup, B-3]
      → else                      → append new "## <key>" record             [acceptance #3]
      → file absent?              → create from seed, then append            [B-1]
  → NO /harness-goal dispatch, NO production edit, verify_all stays green     [acceptance #5]
  → next sweep over unchanged tree: EP-007's module omitted from the table   [acceptance #1]
```

## Risk analysis

| # | Risk | Mitigation |
|---|---|---|
| R-1 | Path-separator / leading-`./` mismatch makes a declined record fail to filter (Windows `\` vs POSIX `/`). | Normalization step (sep→`/`, strip leading `./` + trailing `/`) defined once and applied to BOTH sides before equality; stated explicitly in the scan ref. |
| R-2 | Over-suppression: a substring/prefix match silently hides a sibling module the user never declined. | Match rule is **exact string equality after normalization**, NOT substring/prefix; documented + an acceptance-#2 round-trip (remove record → finding reappears) proves the exclusion is caused by the record. |
| R-3 | Read failure on `rejected-decisions.md` could suppress ALL findings (fail-closed) and hide real rot. | Fail-OPEN: absent/unreadable → no-op, all findings surface (NFR-3). |
| R-4 | DRY drift: the key rule restated in both the scan ref and SKILL.md diverges over time. | Rule defined ONLY in `references/entropy-scan.md`; supervisor stub + SKILL.md POINT at it, never restate (NFR-1; mirrors existing "one definition, two readers"). Same discipline that keeps the artifact schema single-sourced. |
| R-5 | I.6 self-trip: a decline record or a doc here quotes a banned retired-claim anchor (the `rejected-decisions.md` file is I.6-scanned, per insight 2026-06-08 / T-013 self-trip). | All new prose (the scan section, the SKILL.md text, the two decline records, this design) is plain forward-looking English describing the filter; it quotes no banned anchor sequence. Verified at delivery by `verify_all` I.6 PASS. |
| R-6 | Count/version drift: bumping behavior without the version, or flipping a count that didn't change. | Version 0.42.0→0.43.0 across the 4 G.3 stamps + CHANGELOG `[0.43.0]` (G.4). NO count flip — skills 17, agents 8, verify_all 32, integration 90/90, test-init 314/314 all UNCHANGED (no new skill/agent/check). G.4 enforces claim↔plugin.json consistency at the gate. |
| R-7 | supervisor.md exceeds its 300-line cap from the new clause. | The clause is ONE sentence pointing at the scan ref (no restatement); supervisor.md is 281 lines today → ~282-284 after, well under 300. |

## Migration / rollout plan

- **Backwards compatible.** No schema, no API, no state-file format changes. `.harness/rejected-decisions.md`
  keeps its existing T-09 record format (this slice only ADDS records of the existing shape). An older
  project with no `rejected-decisions.md` is unaffected (fail-open: no file = no declines).
- **No data migration.** No store is created; nothing to migrate. The decline action lazily creates
  `.harness/rejected-decisions.md` from seed only if a user actually declines and the file is absent.
- **No feature flag needed.** The filter is inert until a `declined`/`deferred` record exists whose
  handle matches a current finding; pre-existing T-09 declines that happen to match a module's path
  would begin filtering, which is the intended T-09 reuse (a declined deepening is a declined finding).
- **Rollback.** Revert the 3 behavioral edits + 5 stamps; no data to unwind (any decline records added
  remain valid T-09 records and are harmless if the filter is reverted — they just stop being read by
  the scan). The `entropy-findings-store` decline record likewise remains a valid plain record.
- **Distribution.** All edited files are repo source-of-truth that also ship in the plugin
  (`agents/`, `skills/`). No `templates/` change (no new file ships into generated projects;
  `rejected-decisions.md` is the existing T-09 dual-purpose file, already handled). No `harness-sync`
  / `sync-self` impact (framework agents are plugin-native; skills edited in place).

## Out-of-scope clarifications (this design does NOT cover)

1. A standalone open/fixed findings store / DB — DECLINED (and recorded as a decline record).
2. Auto-classifying fixed-vs-open by diffing the codebase — the scan's re-derive makes "fixed" ==
   "no longer surfaced".
3. Any change to the cadence engine, the scan methodology/grammar, or the `/harness-stream` //harness`
   surfaces from T-11a/T-11b — this task adds no dispatcher and no new section format.
4. Any new `verify_all` check, placeholder, skill, agent, or count flip.
5. An un-decline / revive flow — the user hand-edits/removes the `rejected-decisions.md` record,
   consistent with how that file is maintained today.
6. A "N findings hidden because declined" count surfaced IN the report (the methodology-notes
   suppressed-count line is an internal honesty note, not the report-facing count, which is OOS).

## Partition assignment

No `.harness/agents/dev-*.md` partition agents exist in this repo (single-Developer mode — AI-GUIDE
"`.harness/agents/*.md` … empty in this repo"). Section omitted per contract; all edits go to the
single Developer.

## Verdict

**READY.** The re-derive assumption is confirmed against `references/entropy-scan.md`, so the scope is
the decline-filter + the `/harness-deflate` decline-record path only; OPEN/FIXED need no store and none
is built. The key-normalization + match rule, the fail-open + determinism posture, the step-4
memory-write-only contract, and the version/stamp/count plan are all specified to the file level. No
new dependency, script, skill, state file, or `verify_all` check; supervisor.md stays ≤300; I.6 stays
clean. A developer can implement this without further design decisions.
