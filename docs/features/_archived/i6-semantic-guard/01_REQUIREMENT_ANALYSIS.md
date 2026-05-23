# 01 — Requirement Analysis · i6-semantic-guard (T-004 · v0.18)

Mode: **full** (canonical 7-stage). Target version v0.18.0.

## 1. Goal

Upgrade `verify_all`'s I.6 retired-claim guard from literal-substring matching to a
gap-tolerant pattern match, so a retired claim cannot evade the FAIL by inserting
narration between its key words (e.g. `harness-sync regenerates the static stub
CLAUDE.md` slips past the banned literal `regenerates CLAUDE.md`).

## 2. In-scope behaviors

1. I.6 in BOTH `scripts/verify_all.sh` (lines ~501-552) and `scripts/verify_all.ps1`
   (lines ~469-524) is changed so each banned-phrase entry matches its key words
   even when bounded extra text appears between them, not only when they are
   adjacent.
2. Each banned-phrase entry becomes a **multi-token pattern**: an ordered list of
   anchor tokens that must all appear, in order, within one matching window. The
   current literal entries are migrated to this form (e.g. `regenerates CLAUDE.md`
   becomes anchors `regenerates` … `CLAUDE.md`).
3. The matching window has a **bounded gap** between consecutive anchor tokens
   (gap budget defined in §4 + Decision D-1). Anchors separated by more than the
   gap budget do NOT count as a hit.
4. Matching is **case-insensitive on alphabetic anchors** (so `Regenerates` and
   `regenerates` both match) — see Decision D-2 for the exact rule, including how
   `CLAUDE.md` (a fixed-case filename) is treated.
5. I.6 still scans the same input set: every file returned by `git ls-files`,
   minus the exempt files and exempt directories.
6. The exempt-file list (`CHANGELOG.md`, `architecture.html`,
   `docs/walkthrough.html`, `scripts/verify_all.ps1`, `scripts/verify_all.sh`) and
   exempt-dir list (`docs/features/_archived/`, `参考/`) are preserved with
   identical semantics.
7. I.6 still emits exactly one check result: FAIL when ≥1 hit is found, PASS when
   zero hits; the total verify_all check count stays 30 (no new check is added).
8. On FAIL, the message reports, per hit: the file path, which banned pattern
   matched, and the human-readable retirement reason — the same three facts I.6
   reports today. The matched text span (the actual substring including the
   narration) is also reported, so a maintainer can judge a false positive at a
   glance.
9. The banned-pattern list keeps the low-maintenance property: retiring a claim is
   adding one list entry; un-retiring it is deleting that entry. No file-level
   exception is carved per claim (consistent with the I.6 v0.15.1 design intent).
10. The `.sh` and `.ps1` implementations of I.6 produce the **same hit/no-hit
    verdict and the same hit count** for every file in this repo (PS/Bash
    symmetry, rule 30 item 20).
11. After the upgrade, `scripts/verify_all` PASSes on the current repo state
    (v0.17.4 + this change) — the upgrade introduces zero new hits on existing
    accurate prose.

## 3. Out-of-scope (explicit non-goals for v0.18.0)

- No new banned phrases are added and no existing banned phrase is removed; this
  task changes the *matching engine*, not the *phrase list contents*. (Adding the
  v0.10 set was T's prior work; phrase-list curation is a separate concern.)
- No new verify_all check; no change to any other check (I.1-I.5, I.7, D.3, etc.).
- No semantic/NLP/embedding/LLM-based matching. "Semantic" here means
  "tolerant of intervening narration", implemented with regex or token-window
  scanning — not meaning-based inference.
- No change to the exempt-file / exempt-dir lists' membership.
- No change to I.6's severity (stays FAIL) or to where it sits in verify_all.
- No new external dependency, language runtime, or tool; the change stays within
  the existing Bash + PowerShell capabilities of the two scripts.
- No retroactive doc cleanup: this task does not hunt for and fix retired claims
  that the stronger matcher newly catches. If the upgrade surfaces a real hit on a
  live file, that is a finding routed back to PM, not silently fixed here
  (in-scope item 11 asserts the current repo is already clean — if it is not, that
  is a blocker surfaced to PM).
- No configuration file for the phrase list; it stays inline in both scripts as
  today.

## 4. Boundary conditions

- **Empty file** (tracked, zero bytes): no hit. Current code already skips empty
  content; preserved.
- **Binary / non-UTF-8 tracked file**: must not crash either script and must not
  produce a spurious hit; treated as no-hit (matches current `grep -F` /
  `Get-Content` tolerance).
- **Anchor token spanning a line break**: a banned pattern's anchors may fall on
  different lines with narration (including newlines) between them — see Decision
  D-3 for whether the gap budget counts newlines.
- **Banned pattern whose anchors are a single token** (degenerate case, e.g.
  `scaffolding-only`): behaves as a plain substring match — no gap to bound.
- **Same banned pattern matching twice in one file**: reported as one hit per file
  per pattern (matches current behavior — no per-occurrence multiplicity).
- **Anchor token containing regex metacharacters** (`.` in `CLAUDE.md`,
  `/` in `.harness/rules`, `→` in `.harness/ → CLAUDE.md`, backtick in
  `` `CLAUDE.md` ``): metacharacters must be matched literally, not as regex
  operators. The PS backtick-escaping hazard (insight 2026-05-19, line 19) and
  the `→` Unicode arrow are explicit hazards here.
- **`git ls-files` returns nothing** (not a git repo / detached state): I.6 scans
  zero files, emits PASS — matches current behavior.
- **Maximum gap budget**: the gap budget is a fixed small integer (Decision D-1
  proposes a default). It is NOT unbounded — an unbounded gap would match the two
  anchors anywhere in a large file and flood false positives.
- **Overlapping anchors / anchor that is a prefix of the next**: defined by
  Decision D-1's window semantics; the spec requires the behavior be deterministic
  and identical across both shells.

## 5. Acceptance criteria

- **AC-1 (bypass caught)**: A test fixture file containing
  `harness-sync regenerates the static stub CLAUDE.md` causes I.6 to FAIL with a
  hit naming the `regenerates`…`CLAUDE.md` pattern. The current literal matcher
  does NOT catch this string; the upgraded matcher does.
- **AC-2 (adjacent still caught)**: A fixture containing the literal
  `regenerates CLAUDE.md` (zero gap) still FAILs — no regression on the
  zero-narration case.
- **AC-3 (false positive NOT raised)**: A fixture containing the *accurate* prose
  `.claude/agents/ is regenerated by harness-sync from .harness/agents/`
  (which mentions `regenerated` and is a true statement, but is NOT about
  `CLAUDE.md`) does NOT produce a hit. This is the load-bearing false-positive
  guard: the gap budget must be tight enough that `regenerated` and a later
  unrelated `CLAUDE.md` do not co-match.
- **AC-4 (repo stays green)**: `scripts/verify_all.sh` and `scripts/verify_all.ps1`
  both run on the current repo and report I.6 = PASS, total 30/30 PASS. (The repo
  today contains many accurate uses of `regenerated`, `composed`, `CLAUDE.md` —
  verified: ~170 `CLAUDE.md` mentions across 26 files; the upgrade must not turn
  any of them into a hit.)
- **AC-5 (cross-shell parity)**: For a fixture corpus containing at least the
  AC-1, AC-2, AC-3 cases plus one case per existing banned pattern, the `.sh` and
  `.ps1` I.6 implementations produce an identical list of hits (same files, same
  patterns, same count).
- **AC-6 (case-insensitivity)**: A fixture with `Harness-sync Regenerates the
  CLAUDE.md stub` is caught (alphabetic anchors case-insensitive per D-2).
- **AC-7 (metacharacter safety)**: A fixture exercising the `` `CLAUDE.md` ``
  backtick pattern and the `.harness/ → CLAUDE.md` arrow pattern is caught, and
  neither script throws a parser/regex error. PS single-quote rule (insight L19)
  is honored.
- **AC-8 (exemption preserved)**: A banned pattern present in `CHANGELOG.md` and in
  a `docs/features/_archived/` file produces no hit (exemptions still apply under
  the new matcher).
- **AC-9 (gap boundary)**: A fixture where the two anchors are separated by
  *exactly the gap budget* matches, and one where they are separated by
  *gap budget + 1* does NOT match — the boundary is tested on both sides.
- **AC-10 (docs synced)**: `CHANGELOG.md` records the v0.18.0 I.6 upgrade; the I.6
  description string in both scripts and any reference in `AI-GUIDE.md` /
  `docs/dev-map.md` that describes I.6 as "literal-substring" is updated. The
  insight-index line about I.6 (2026-05-19, line 18) gains a follow-up note that
  I.6 became gap-tolerant at v0.18. (Insight-index L14/L21 fan-out discipline.)
- **AC-11 (test driver)**: The fixture-based checks (AC-1..AC-9) run from a
  repeatable test driver — either an extension of an existing `scripts/test-*`
  pair or a new pair — so the matcher's behavior is regression-protected. The
  architect chooses the host; the requirement is that it is automated and
  cross-shell, not manual.

## 6. Non-functional requirements

- **NFR-1 PS/Bash symmetry**: The two implementations are behaviorally identical
  (AC-5). Any divergence is a defect. Rule 30 item 20.
- **NFR-2 maintainability of the phrase list**: Retiring a claim remains a
  one-line edit in each script; the multi-token entry format is human-readable
  and self-documenting (a reviewer can read an entry and know what it bans). The
  format must not require a maintainer to hand-write raw regex with escaping — the
  anchor tokens are written as plain text and the script does any escaping. (This
  protects against the PS-backtick and Unicode-arrow hazards becoming a
  per-edit burden.)
- **NFR-3 performance**: I.6 runtime over the full `git ls-files` set stays in the
  same order of magnitude as today (today: ~50 lines/shell, one pass per file per
  pattern). The upgraded matcher must not introduce pathological backtracking
  (catastrophic-regex risk) or a per-file cost that makes verify_all noticeably
  slower. Target: I.6 contributes < 1s to total verify_all wall-clock on this repo.
- **NFR-4 false-positive budget**: Zero false positives on the current repo
  (AC-4). The gap budget (D-1) is the primary tuning knob; it is chosen to favor
  catching real bypasses while keeping the current repo green. If the two goals
  conflict on a specific phrase, that phrase's entry may use a tighter
  per-entry gap (D-1 covers this).
- **NFR-5 no new dependency / determinism**: No tool, runtime, or library is added.
  Given the same file set, I.6's verdict is deterministic and reproducible.
- **NFR-6 doc-size compliance**: This stage doc and downstream stage docs respect
  rule 70 caps (per-task stage doc ≤ 500 lines).

## 7. Related tasks

- **T-001 / ai-safety-guardrails** (v0.15.0) — precedent for adding/altering a
  `verify_all` check; insight L7 (PS `-contains` case-insensitivity) and the
  general "PS string operators need their `c`-prefixed case-sensitive variant"
  family (L17 line 16, L20, L23) apply directly to the matcher's PS side.
- **T-002 / ai-native-init** (v0.16.0) — insight L11 (CHANGELOG must be in the
  fan-out of any version sweep) applies to AC-10; L12 (separate temp dirs for
  bidirectional fixtures) applies to AC-11's fixture corpus.
- **T-003 / supervisor-agent** (v0.17.0) — insight L24 (bash loop-variable name
  collision with a global array) applies to any new loop in I.6; `i6_hits` /
  per-file loop variables must not collide with the global `report=()` array.
- I.6 itself was introduced at **v0.15.1** (doc-resync delivery); see
  insight-index line 18 for its design intent (negligible ongoing cost,
  history-exemption list) and line 19 for the PS-backtick hazard already hit once.
- No prior `docs/features/_archived/` task is a direct extension of this one; I.6's
  introduction predates the per-task stage-doc pipeline for that delivery.

## 8. Open questions

All items below are framed as **Decisions** with an analyst-recommended default,
per the user's "you decide; user reviews the result" mandate. They are
**PM-resolvable** (the PM or the Solution Architect confirms or overrides in
stage 2) — none is a hard user blocker. The user reviews the final result.

- **D-1 — Gap budget (size and granularity).**
  How much intervening text is tolerated between two consecutive anchors?
  - (a) **[RECOMMENDED]** A fixed default of **≤ 40 characters** between
    consecutive anchors, applied uniformly, with the option for an individual
    phrase entry to override with a tighter budget. Rationale: 40 chars comfortably
    covers `the static stub ` (16 chars) and `harness-sync does not ` style
    narration, while being far short of the ~hundreds of chars that separate an
    unrelated `regenerated` from a later `CLAUDE.md` in real prose (AC-3 corpus).
  - (b) A word-count budget instead of char-count: ≤ N words (e.g. ≤ 5) between
    anchors.
  - (c) Unbounded within a single line (gap = "anywhere on the same line").
  Analyst note: (c) risks false positives on long lines; (a) and (b) are both
  defensible — (a) chosen for being trivially identical to express in both a
  bash regex (`.{0,40}`) and a PS regex, satisfying NFR-1/NFR-2.

- **D-2 — Case sensitivity of anchors.**
  - (a) **[RECOMMENDED]** Alphabetic anchors match case-insensitively; the
    filename token `CLAUDE.md` also matches case-insensitively (so `claude.md`
    is caught). Rationale: a bypass author lower-casing a word should not escape;
    `CLAUDE.md` is conventionally fixed-case so case-folding it adds catch power at
    near-zero false-positive cost.
  - (b) Alphabetic anchors case-insensitive, but `CLAUDE.md` matched case-exactly
    (treat the filename as a fixed-case contract token).
  Analyst note: (a) is the stronger guard. PS implementers must remember
  `-match` / `-cmatch` semantics (insight L23) — whichever is chosen, it must be
  explicit, not the operator default.

- **D-3 — Does the gap budget span newlines?**
  - (a) **[RECOMMENDED]** Match **within a single line only** — anchors on
    different lines are NOT a hit. Rationale: a retired *claim* is almost always
    one sentence on one line; allowing cross-line matching widens the
    false-positive surface (anchors on lines 10 and 400 of a doc) for marginal
    extra catch. Keeps the regex simple (`grep` line-oriented; PS `-split` on
    newlines).
  - (b) Match across newlines, counting newline characters toward the D-1 budget.
  Analyst note: (a) chosen. If a future bypass splits a claim across two lines,
  that is a rarer and more obviously deliberate evasion; can be revisited.

- **D-4 — Anchor decomposition of existing entries.**
  Each current literal must be re-expressed as anchor tokens. The mechanical split
  is "split on whitespace" (e.g. `regenerates CLAUDE.md` → [`regenerates`,
  `CLAUDE.md`]). Question: are multi-word *phrases that must stay adjacent* kept as
  a single anchor?
  - (a) **[RECOMMENDED]** Split each existing literal on whitespace into anchors;
    where two words must stay adjacent for the claim to be wrong, keep them as one
    anchor (the entry author decides per entry). The migrated list is reviewed in
    stage 2/4 so each entry's anchors are the *minimal distinctive* set.
  - (b) Fully mechanical whitespace split with no per-entry judgment.
  Analyst note: (a) — a human-reviewed migration is a one-time cost and produces a
  more precise list. The reviewer checks each entry against AC-3-style prose.

- **D-5 — Reporting the matched span.**
  In-scope item 8 requires the FAIL message to include the actual matched text.
  - (a) **[RECOMMENDED]** Report the matched span truncated to a sane length
    (e.g. ≤ 120 chars) so a multi-line / long match does not flood the terminal.
  - (b) Report only the line number + the pattern name, no span text.
  Analyst note: (a) — the span is what lets a maintainer instantly judge a false
  positive; truncation keeps output readable.

- **D-6 — Test-driver host.**
  AC-11 requires automated cross-shell fixture tests.
  - (a) **[RECOMMENDED]** Architect's call in stage 2: either extend an existing
    `scripts/test-*` pair or add a focused `scripts/test-verify-i6.{ps1,sh}` pair.
    This is a pure design decision with no requirement-level consequence.
  - (b) Pre-decide a new dedicated pair now.
  Analyst note: (a) — defer to the Solution Architect; flagged here only so the
  PM knows AC-11 needs a home.

## 9. Verdict

**READY** — all open items are framed as PM-resolvable Decisions (D-1..D-6) with
analyst-recommended defaults, per the user's explicit "you decide; user reviews
the result only" mandate. No item requires a user answer before the Solution
Architect can proceed; the Architect may confirm or override any D-line in
stage 2. If the Architect rejects a default and the alternative materially
changes scope, that routes back through PM — but no such conflict is anticipated.
