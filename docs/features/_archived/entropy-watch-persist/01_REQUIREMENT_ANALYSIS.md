# 01 — Requirement Analysis · T-11c entropy-watch-persist

> Mode: **full** · Stage 1 (Requirement Analyst) · deferred-human mode (defer, do not ask) ·
> Standing rule: recommend an answer per Open Question · behavioral, no forward file:line.

## Goal

Stop the anti-entropy watch from re-litigating a finding the user has already declined: a
declined finding is recorded once in `.harness/rejected-decisions.md` and is excluded from every
future entropy sweep, while still-open findings keep surfacing and fixed ones keep dropping.

## Scope decision (the load-bearing call)

**The re-derive assumption HOLDS.** The entropy scan re-derives the structured finding list from
the live tree on every sweep — the scan reference states the finding list (ID + class + Where +
strength) is identical across runs over an *unchanged* tree, i.e. it is a pure function of current
structure, not a remembered list. Two consequences follow with no new storage:

- **FIXED needs no store.** A module that was deepened is no longer shallow, so the deletion test
  no longer flags it and it simply stops appearing in the next sweep's table. "Fixed" = "no longer
  surfaced", derived for free.
- **OPEN needs no store.** A still-shallow module is re-derived every sweep and re-surfaces on its
  own. No "remember this is still open" record is required.

**Therefore the only genuinely-new wiring is the DECLINE path**, and this analysis scopes the task
DOWN to exactly that. A separate open/fixed findings store (`entropy-findings.md` or a
read+write findings log) is **DECLINED as overkill** for this repo: it would store information the
scan already re-derives, adding a file + a read/write cycle + a drift surface to duplicate a
property the design already has by construction. This is the design-over-guards / lightweight line
(do not accrete state that re-encodes a re-derived fact). The decline-as-rejected-decision reuse
is recorded as the chosen approach; the standalone findings store is recorded as DECLINED in this
doc's rationale (an append to `.harness/rejected-decisions.md` for the store concept is left to the
architect/delivery as the standard decline-record habit).

## In-scope behaviors

1. The entropy scan, when producing its findings table, EXCLUDES any finding whose stable key
   matches an existing `.harness/rejected-decisions.md` record. The excluded finding does not
   appear in the findings table and does not contribute to the `Entropy-verdict` line's
   FINDINGS-PRESENT/CLEAN determination.
2. The match is by the **stable finding key** = the finding's `Where (file/module)` handle,
   normalized to a concept handle (the module/file path the finding is about), compared against the
   rejected-decisions record's concept handle. This mirrors T-09's one-record-per-concept de-dup
   (the EP-NNN sequential ID is per-run and is NOT the stable key).
3. The decline-filter is applied AT THE POINT THE FINDINGS LIST IS PRODUCED (the scan reads
   `.harness/rejected-decisions.md` and drops matching findings before writing the artifact),
   reusing the T-09 "read the decline memory at the decide-point" pattern. No new always-on
   process and no separate filter pass downstream of the artifact.
4. `/harness-deflate` gains an explicit user action to mark a presented finding **declined**.
   When the user declines finding EP-NNN, the skill appends a record to
   `.harness/rejected-decisions.md`: concept handle = the finding's stable key (its module/file
   `Where`), decision = `declined`, a substantive why (the user's stated reason, or "not worth the
   deepening" if none given), and an origin naming the entropy sweep (date + EP class).
5. A declined finding's record follows T-09's de-dup contract: if a record for that concept handle
   already exists, the decline appends its origin to the existing record (a re-occurrence) rather
   than creating a second record.
6. Declining a finding does NOT execute any refactor and does NOT edit production code — it is a
   memory-write only. The existing authorize-gate (no refactor without an explicit pick) is
   unchanged; "decline" is a third user choice alongside "deflate this one" and "none".
7. A finding that is neither declined nor fixed re-surfaces on the next sweep unchanged (the
   existing re-derive behavior, asserted here as a guarded property the decline-filter must not
   break for non-matching findings).
8. The version bumps 0.42.0 → 0.43.0 (a distributed behavioral edit). The skill count does NOT
   flip (no new skill) and the verify_all check count does NOT change (no new check).

## Out-of-scope

1. A standalone open/fixed findings store / database (DECLINED above — the scan re-derives).
2. Auto-classifying a finding as fixed by diffing the codebase (the scan's re-derive already makes
   "fixed" == "no longer surfaced").
3. Any change to the cadence engine, the scan methodology/grammar, or the surfacing in
   `/harness-stream` / `/harness` from T-11a/T-11b.
4. Any new `verify_all` check, any new placeholder, any skill-count change.
5. An "un-decline" / revive flow (re-opening a declined finding). If the user wants a declined
   finding back, they edit/remove its `.harness/rejected-decisions.md` record by hand, consistent
   with how that file is maintained today.
6. Surfacing a "N findings hidden because declined" count in the report (informational extra,
   not required for "declined ones don't re-litigate").

## Boundary conditions

1. **`.harness/rejected-decisions.md` absent** — the file is a SOFT convenience (per the decision
   policy; absent is fine, never a `BLOCKED`). The scan treats "no file" as "no declines" and
   surfaces all derived findings. The decline action CREATES the file from the standard seed shape
   if it does not exist.
2. **Empty rejected-decisions file (header only, zero records)** — no findings excluded; identical
   to the absent case for filtering.
3. **No findings derived this sweep** — filter is a no-op; `Entropy-verdict: CLEAN` as today.
4. **A declined record whose concept handle no longer matches any current finding** — harmless: the
   filter excludes nothing for it; the stale record simply sits in the memory file (the same way an
   obsolete rejected-decision sits there today; soft-compaction is a manual habit, not a gate).
5. **Two findings in one sweep that normalize to the SAME stable key** — both are excluded if that
   key is declined (the key is the module/file handle, so co-located findings share the decline).
   This is acceptable: a user declining "this module isn't worth deepening" declines the module.
6. **Decline requested for a finding ID not present in the just-presented artifact** — the skill
   does not invent a record; it reports the ID is not among the current findings and takes no
   memory-write (no silent guessing of which module was meant).
7. **Concurrency** — single-operator repo, sweeps run serially (manual `/harness-deflate` or a
   cadenced drain); no concurrent-writer requirement on the memory file beyond the file's existing
   append-one-record discipline.
8. **Max size** — the decline-filter reads the whole (one-screen) rejected-decisions file; no max
   beyond the file's existing soft "compact past one screen" self-discipline. No per-finding size
   limit applies (the key is a path/handle string).

## Acceptance criteria

1. With a `.harness/rejected-decisions.md` record whose concept handle equals a module the scan
   would otherwise flag, a sweep over that unchanged tree omits that finding from the artifact's
   findings table (observable: the EP row for that module is absent).
2. With the same tree and that record removed, the same sweep re-includes the finding (observable:
   the EP row reappears) — proving the exclusion is caused by the record, not by the scan losing
   the finding.
3. Declining finding EP-NNN via `/harness-deflate` results in a `.harness/rejected-decisions.md`
   record with the finding's module/file as the concept handle, `declined`, a why, and an
   entropy-sweep origin (observable: the new record in the file).
4. A second decline of a finding for an already-recorded concept handle appends an origin to the
   existing record and does NOT create a second record (observable: still one record for that
   concept).
5. Declining a finding triggers no refactor and edits no production file (observable: only
   `.harness/rejected-decisions.md` changes; verify_all stays green).
6. A non-declined, still-shallow finding re-surfaces on a subsequent sweep (observable: its EP row
   present in the next artifact).
7. `verify_all` is green after the change; the check count is unchanged and the plugin version is
   0.43.0 (observable: the gate passes and the version/count claims are consistent).

## Non-functional requirements

1. **DRY / single-source** — the decline-filter rule and the stable-key definition live in the
   single scan-methodology source that both the supervisor stub and the skill point at; they are
   not restated in two places (mirrors the existing "one definition, two readers" discipline).
2. **Determinism preserved** — after filtering, the findings list remains identical across runs
   over an unchanged tree and an unchanged rejected-decisions file (the filter is a deterministic
   set subtraction, so the NFR-6 determinism property still holds).
3. **Fail-open** — if reading the rejected-decisions file errors, the scan surfaces all derived
   findings (does not suppress findings on a read failure) and does not wedge, consistent with the
   cadence engine's fail-open posture.

## Related tasks

- **T-11a** (`entropy-watch`, `docs/features/_archived/entropy-watch/`) — created the scan
  reference (the re-derive/determinism contract this scope rests on), the supervisor entropy lens
  stub, the cadence pair, and the `/harness-stream` surface.
- **T-11b** (`entropy-watch-harness`, `docs/features/_archived/entropy-watch-harness/`) — wired the
  watch into the `/harness` delivery boundary. This task adds no new dispatcher.
- **T-09** (`rejected-decisions-memory`, `docs/features/_archived/rejected-decisions-memory/`) —
  created `.harness/rejected-decisions.md`, its one-record-per-concept de-dup, and the
  read-at-decide-point habit single-sourced in the decision policy. This task REUSES that file and
  contract for the DECLINE case; a declined deepening IS a rejected decision.
- **T-10** (`planning-decision-map`) — the first real use of the rejected-decisions memory (an
  assess-then-decline), precedent for recording a decline rather than re-litigating.

## Open questions for user

(deferred-human mode — recorded with a recommended answer; none of these blocks the pipeline.)

1. **Where does the decline-filter physically read+drop?** Recommended: **(a)** the supervisor
   entropy lens reads `.harness/rejected-decisions.md` and drops matching findings before writing
   the artifact (the scan never emits a declined finding). Alternative: **(b)** the
   `/harness-deflate` skill post-filters the artifact after reading it. Recommend (a): it keeps the
   artifact itself clean for ALL readers (the `/harness-stream` and `/harness` surfaces consume the
   same artifact), so the decline applies uniformly without each surface re-implementing the
   filter; the cost is widening the supervisor's read-set by one already-whitelisted-class file.

2. **What exactly is the stable key normalization?** Recommended: **(a)** the finding's `Where`
   module/file path used verbatim as the concept handle (e.g. the path string), matched
   case-sensitively against the rejected-decisions concept handle. Alternative: **(b)** a coarser
   module-name handle (directory/component) so a decline covers a whole component. Recommend (a):
   it is the most precise and matches what the user actually saw and declined (the specific
   `Where`); component-level grouping risks silently hiding findings the user never declined.

3. **What origin string does a decline record carry?** Recommended: **(a)** `entropy sweep
   <ISO-date> · EP-<class>` (date + finding class), matching the existing origin style in the file.
   Alternative: **(b)** also embed the per-run EP-NNN id. Recommend (a): the per-run id is not
   stable across sweeps, so embedding it adds noise without identifying value; date + class is the
   durable, reproducible provenance.

## Verdict

**READY.** The re-derive assumption is confirmed against the scan reference, so the scope is the
decline-filter plus the `/harness-deflate` decline-record path only; the standalone open/fixed
store is declined as overkill. All three open questions carry a recommended answer and are
reversible design choices that do not block downstream stages under deferred-human mode.
