# Operator obligations — the standing release-gating list

> **What this is.** Every release-gating **operator obligation** this repository owes: a step a human
> operator must perform, on a host this repository's agents cannot reach, before a release is safe.
> **This is the only home.** A standing operator obligation is not written in
> `.harness/scripts/baseline.json`, which pins numeric baselines only, and not in an archived stage
> document. Where each entry's text came from is recorded in that entry's own origin field.
> **Fields.** An entry is one `###` heading followed by exactly seven field lines, one per physical
> line, in this order: id, action, artifacts, pass observable, security, origin, last discharged. The
> heading is navigation only and is not counted. No example entry is rendered anywhere in this file,
> deliberately: a rendered first field line would be counted by the command under `## How to count`.
> **Appending.** A new obligation is appended with the next unused id. No existing entry is
> renumbered, merged, split, reordered or dropped, and an id is never reused, including after the
> obligation is discharged.
> **Discharge.** `Last discharged` reads exactly one of `never`, `<YYYY-MM-DD> against <40-hex-sha>`,
> or `<YYYY-MM-DD> against <40-hex-sha>+dirty`, where the sha is `git rev-parse HEAD` of this
> repository at the moment of the run. `+dirty` is appended when `git status --porcelain` was
> non-empty for any path in that entry's artifacts field, and always reads as **not** discharged.
> **Size and reach.** No `verify_all` size check measures this path, so this file carries no gated
> cap and no rotation; `I.6`, the retired-claim guard, does scan it, at FAIL severity. No agent is
> instructed to read this file at task start and no script reads it, so it is on no always-read path
> and its absence breaks no execution path.

## The set is empty, and why

**28 obligations were retired on 2026-08-08 by the removal of Windows support (v0.49.0), not by
being discharged.** Every one of them named a step that could only be performed under `pwsh` against
an artifact that no longer exists: ids `1`–`17` and the eight `T13-*` entries, plus `V2P1-1` and
`V2P1-2`. All 28 read `Last discharged: never` at the moment they were retired, and had since the
day each was written.

That is the honest description of what happened, and it is worth stating plainly rather than
recording 28 discharges:

- The obligations were never a to-do list. They were the **price of a second implementation** — a
  `.ps1` twin of every script, green by symmetry only, on a host with no `pwsh` to run it. Each
  entry existed because a reviewer could not distinguish "symmetric by construction" from
  "symmetric in fact" without a run nobody here could perform.
- Deleting the twin does not discharge the obligation; it deletes the artifact the obligation was
  about. There is nothing left to verify, so there is nothing left to owe.
- The retired text is not lost. Each entry recorded its enumerating source — an archived
  `04_DEVELOPMENT.md` span, or a `baseline.json` `_qa_note_*` key — and those sources are unchanged.
  The entries themselves are in this file's git history at `v0.48.0`.

**This is the single largest reduction in outstanding human decisions this repository has made.**
By the migration brief's own test — does a change remove a decision point or add one — 28 decision
points that no one on this host could ever reach went away at once. Nothing replaced them.

An obligation may be appended here again the moment a real one appears: a step this repository owes
that its agents genuinely cannot perform. The next unused id is `18`.

## How to count

The size of the set is the number of entries, and no total is stored anywhere in this file. Run this
from the repository root:

```
grep -c '^- Id: ' .harness/operator-obligations.md
```

It counts the first field line of every entry, so "count entries" and "count ids" cannot disagree.
The published line itself begins with `grep`, so it never matches its own pattern. On a file holding
no entries the command prints `0` and exits **1** — grep's documented no-match status, not an error.

## Numbered obligations

_(none)_
