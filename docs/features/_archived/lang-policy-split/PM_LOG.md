# PM Log — T-013 lang-policy-split

> Task: refine harness-kit's existing v0.7.0 project-level output-language feature. When a user
> picks Chinese at init ({{LANG}}=zh), replace the blunt "everything in Chinese" policy with a
> THREE-WAY split: conversational replies → Chinese; AI-facing artifacts → English; human-facing
> artifacts → Chinese. ("原中文要求需要更新" = the existing v0.7.0 zh policy text.)
>
> Mode: full (7-stage). Started 2026-06-08.

## Intervention check
- Before stage 1: `.harness/intervention.md` absent → no pending signal.

## Developer mode
- `.harness/agents/dev-*.md`: none (confirmed in T-012) → single Developer mode.

## PM pre-scan (handed to RA so it need not rediscover)
- init Q5 selects language → `{{LANG}}` placeholder (en default / zh).
- zh overlay: `skills/harness-init/templates/i18n/zh/common/` (CLAUDE.md.tmpl, AI-GUIDE.md.tmpl,
  00-core.md.tmpl, copilot-instructions.md.tmpl, 60-tool-handoff.md, docs/spec/README.md). EN
  default layer: `templates/common/`.
- Policy landing site: generated CLAUDE.md top "Output language/输出语言" section + 00-core.
  agents/*.md already English (CHANGELOG: agent defs stay English by design).
- Scope = generated USER projects (zh overlay + SKILL.md Q5 + generated policy text). NOT the
  harness-kit dogfood repo itself (its CLAUDE.md stays English).

## Insights surfaced to downstream (from .harness/insight-index.md)
- **L11/L20**: any NEW `{{...}}` placeholder → BOTH verify_all D.2 whitelists (`-cnotin`).
  Prefer reusing existing `{{LANG}}` over adding placeholders.
- **T-012 insight (2026-06-08)**: test-init recursively scans EVERY generated file for
  `{{...}}` — a template that must reference a token literally trips it; assemble from pieces.
  Relevant if any template needs to mention a placeholder name.
- **L12**: sync-self mirrors a SPECIFIC set, NOT rules; i18n overlay ↔ common symmetry is its
  own concern — changing the zh overlay must keep test-init's i18n assertions green.
- **L33/L34/L36 + G.3/G.4**: a policy change that bumps the version must move version claims in
  lockstep; same-file claim `expect` literals must be file-unique. (Likely a version bump, not a
  skill/check-count change — confirm.)
- **L10**: Edit may silently no-op — re-Read after each edit.
- **One-sided assertion insight (2026-05-16)**: when asserting set membership in templates,
  write the inverse check too (relevant if RA/Architect add a classification assertion).

## Stage transitions

### Stage 1 — Requirement Analyst — dispatched 2026-06-08
- Output: `01_REQUIREMENT_ANALYSIS.md`. Verdict: **BLOCKED ON USER** (6 OQs, 2 load-bearing).
- Centerpiece: a 16-row artifact→EN/ZH classification table (§4) + the critical §3 distinction
  (A) runtime-output-language vs (B) static-template-language.

### OQ resolution — user delegated decision authority to PM (2026-06-08)
User principle (standing): decide by **good UX + software-engineering standards + long-term
ease-of-use & maintainability**; user reviews results only; "你来决策就可以了，我只看结果";
PM owns commits/pushes. The user explicitly said NOT to ask — so PM resolves all 6, no AskUserQuestion.
**All six RA defaults ACCEPTED** (this is the agreed design baseline):
- **OQ-1 → EN** for the 7-stage docs (01…07). They are AI-to-AI handoff work products (the next
  agent is the stricter consumer); the human reviews via the PM's ZH chat summaries, not the raw
  docs. Matches how THIS dogfood session itself operates (EN stage docs + ZH chat).
- **OQ-2 → keep agent defs English** (status quo).
- **OQ-3 → No / defer the (B) template re-translation.** Considered expanding to also move
  AI-facing zh-overlay template files (AI-GUIDE.md.tmpl, rules, etc.) back to English for full
  coherence, but §3's (A)/(B) distinction means a Chinese AI-GUIDE *template* does not violate a
  runtime-*output* policy — no hard contradiction. Including (B) would balloon blast radius
  (overlay↔common symmetry, test-init, doc-size) against surgical-change discipline. **Logged as a
  separate FUTURE task** (T-014 candidate: "prune AI-facing files from the zh overlay so shipped
  scaffolding matches the AI-facing→English policy").
- **OQ-4 → code comments EN**; **OQ-5 → commit messages EN**; **OQ-6 → en path byte-unchanged.**

Net baseline: **ZH** = chat replies / error messages / status & progress reports / human-facing
delivery messages / human-facing README & docs. **EN** = all AI-facing output (7-stage docs,
PM_LOG, tasks.md / dev-map / insight-index ledgers, agent / rule / AI-GUIDE / CLAUDE edits, code
comments, commit messages). zh overlay template files unchanged this iteration; en path untouched.

Carry to Architect: D-obligation 1 (add I.6 banned-line for the retired "全程中文/every AI output
in Chinese" phrasing); D-obligation 3 (fix the stale SKILL step-4.3 overlay file list opportunistically);
D-obligation 4 (first-ever test-init language assertions — symmetric, no-python3-tolerant);
D-obligation 6 (version bump + CHANGELOG; G.3/G.4 stay green). No new placeholder (no D.2 change).

Requirement flipped to **READY** on the above baseline. Advancing to stage 2 (design).

### Stage 2 — Solution Architect — dispatched 2026-06-08
- Output: `02_SOLUTION_DESIGN.md`. Verdict: **READY**. 14 files (F1-F14). Primary edit F1 = zh
  `00-core.md.tmpl` policy rewrite to two explicit Chinese-prose lists (ZH/EN), ~77→86 lines (< I.2 cap).
- **CJK-I.6 cross-shell risk RESOLVED (read the real matcher):** I.6 uses `grep -E -i` (NOT
  `grep -F -i` → no MSYS SIGABRT) + nocasematch/regex; 3 CJK anchors already ship green
  (生成/合成/重新生成的). Adds one `全程~中文` ordered-anchor per shell; verified the new split text
  has no "全程" so it doesn't self-trip; test-init absence-assert uses bare `全程` alone (never
  全程+中文 together) so test-init isn't tripped → no new exempt entry.
- Version 0.23.0→0.24.0 (plugin.json, marketplace.json, 2 README badges, CHANGELOG [0.24.0]).
  Skill count stays 13; verify_all check count stays 32 (test-init block adds no Step; I.6 change
  is a new ENTRY inside the existing I.6 Step → G.4 derived count untouched).
- Architect flagged for Gate/Dev: (a) reconcile any existing CHANGELOG `[Unreleased]` ambient-stream
  content vs the new [0.24.0] (default: keep separate); (b) mirror the I.6 entry into test-verify-i6
  copies or lockstep fails; (c) read real test-init totals before stamping any informational badge.

### Stage 3 — Gate Reviewer — dispatched 2026-06-08
- Output: `03_GATE_REVIEW.md` (persisted by PM). Verdict: **CHANGES REQUIRED** — 1 BLOCKING, 3 ADVISORY.
- CJK-I.6 cross-shell analysis VERIFIED correct against both live matchers (the #1 risk holds).
- **F-1 BLOCKING (→ solution-architect)**: design's I.6 sweep missed live tracked non-exempt
  `docs/project-overview.html:314` ("中文项目全程中文") → the new `全程~中文` banned-line would FAIL
  verify_all. PM confirmed the file is an archived v0.17.0 snapshot (`:765` "生成于 2026-05-19 ·
  Harness Kit v0.17.0 · 本页面归档于...") = same class as exempt architecture.html/walkthrough.html
  → correct fix is EXEMPT it, not rewrite a frozen snapshot.
- F-2/F-3/F-4 ADVISORY (already in design carries): empirical test-init badge totals; mirror I.6
  entry into test-verify-i6 copies; CHANGELOG → fold ambient [Unreleased] into [0.24.0].

### Stage 3b — Architect amendment (F-1) — dispatched 2026-06-08
- `02_SOLUTION_DESIGN.md` appended `## Amendment 1`. F-1 resolved: **exempt** `docs/project-overview.html`
  (archived v0.17.0 snapshot) — NOT rewrite. Re-grep confirmed NO second missed `全程` site (sweep exhaustive).
- Architect surfaced an EXTRA lockstep the Gate under-specified: the exempt list + banned list are
  BOTH mirrored in `test-verify-i6.{ps1,sh}`, AND those drivers hold a hard `I6ExpectedEntryCount`
  that must bump 13→14 with the new banned entry. Full I.6 lockstep = 4 exempt-site edits + 4
  banned-line edits + 2 count bumps.
- CHANGELOG: rename `[Unreleased]` → `[0.24.0]`, append T-013, no orphan. Verdict remains READY.
- PM decision: Gate pre-blessed the exempt fix shape + verified all else; amendment is scoped +
  exhaustive → advance to Dev WITHOUT full re-Gate (ceremony avoided).

### Stage 4 — Developer — dispatched 2026-06-08
- Output: `04_DEVELOPMENT.md`. 16 files per F1-F15. Captured (both shells, 0 FAIL): test-verify-i6
  **58/0 · 58/0**; test-init **255/0 (ps) · 217/0 (sh, no python3)**; verify_all **32/32 BOTH shells**
  (I.6 PASS, G.3=0.24.0, G.4 ok, skill 13, checks 32).
- I.6 4-file lockstep done (banned + exempt element-wise identical across verify_all + test-verify-i6
  both shells; I6ExpectedEntryCount 13→14). F-15 exempt project-overview.html (never rewritten).
  First test-init zh assertion added (present/absent on different strings). CHANGELOG [Unreleased]→
  [0.24.0] with ambient bullets kept. EN path byte-unchanged (git diff --stat empty).
- Dev corrected pre-existing badge drift (227→ empirical 255); left dev-map:140 v0.16.0-pinned
  historical note as-is (G.4-clean). 1 insight surfaced (MSYS bash re-reads script mid-run).
- Stage-4→5 gate satisfied.

### Stage 5 — Code Reviewer — dispatched 2026-06-08
- Output: `05_CODE_REVIEW.md` (persisted by PM). Verdict: **APPROVED**. 0 BLOCKING, 0 MAJOR, 2 MINOR, 1 NIT.
  All ACs met, F-1 exemption + F-2/F-3/F-4 discharged, CJK + 4-file I.6 lockstep byte-correct, no
  fabricated tally (counted 14 entries = I6ExpectedEntryCount 14).
- 2 MINOR: stale "13-entry banned list" comments in test-verify-i6.{ps1,sh} (now 14). NIT: pre-existing
  badge convention (PS total both sides).
- PM decision: fix the 2 MINOR comments BEFORE QA (user principle prioritizes maintainability; comment
  claiming 13 beside 14-entry array is a small lie; re-run re-validates CJK-sensitive files survived
  another edit; keeps QA on final artifact). Skip NIT (pre-existing badge convention, separate concern).

### Stage 5b — Developer polish (CR MINOR comments) — dispatched 2026-06-08
- Fixed both "13-entry"→"14-entry" banned-list header comments (test-verify-i6.{ps1,sh}); code/CJK
  untouched. Re-gate: test-verify-i6 58/58 both shells; verify_all 32/32 both shells (I.6 PASS, v0.24.0).
  test-init not re-run (templates untouched). 04 appended `## CR-minor comment fix (stage 5b)`.

### Stage 6 — QA Tester — dispatched 2026-06-08
(awaiting output)
