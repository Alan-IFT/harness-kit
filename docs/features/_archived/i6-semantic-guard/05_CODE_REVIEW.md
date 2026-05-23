# 05 — Code Review · i6-semantic-guard (T-004 · v0.18.0)

Independent stage-5 audit. Walked the 11 ACs, the design §3/§5/§7/§10, and read every changed file.

## Findings

### CRITICAL
None.

### MAJOR

- **[FANOUT] `.harness/rules/40-locations.md:25`** — still reads `30 items at v0.17.4`.
  This file IS in design §10 fan-out — line 43 was correctly updated to `v0.18.0`, but
  the section-header freshness stamp on line 25 was missed. Same file, two stamps; only
  one bumped. This is precisely the failure mode insight L14 warns about. Check count
  unchanged at 30; needs `v0.18.0`. Trivial one-line edit. Single blocker.

### MINOR

- **[FANOUT] `docs/manual-e2e-test.md:3`** — `scripts/verify_all at 30 checks at v0.17.4`.
  Not in design §10's explicit list, so by the contract this is not strictly a defect.
  Live developer-facing freshness reference; future-task consideration whether to widen
  §10's surface list.

- **[TEST] `scripts/test-verify-i6.ps1:289-310`** — PS structural lockstep is weaker
  than design §7.3 #3 prescribes. The bash side does a verbatim line-by-line compare of
  `verify_all.sh i6_banned`. The PS twin only asserts entry count = 13 plus entry #10's
  `exclude=@('.claude/')`. A silent typo in entries #1, #3-9, #11-13 of
  `verify_all.ps1` (e.g. a wrong `reason` string) would not trip the PS lockstep — only
  the cross-shell parity assertion (which compares hit sets on the 20-file corpus)
  would catch behavioral divergence. Not blocking — bash covers it + parity backstops —
  but worth tightening.

- **[TEST] `scripts/test-verify-i6.{sh,ps1}`** — AC-8 (exemption preserved: a banned
  phrase in `CHANGELOG.md` and in a `docs/features/_archived/` file produces no hit) is
  not directly fixtured. The F-2 assertion tests `docs/features/some-task/...` (good for
  the F-2 widening) but no corpus fixture writes a banned phrase into a synthetic
  CHANGELOG-named file or into a `_archived/` path. AC-8 currently covered only
  indirectly by the live `verify_all` PASS = 30/30.

- **[MAINT] `scripts/verify_all.sh:576`** — uses
  `old_ifs="$IFS"; IFS='~'; read -r -a xtoks <<< "$e_exclude"; IFS="$old_ifs"` while
  line 568 uses the cleaner `IFS='|' read ...` prefix idiom. Stylistic inconsistency
  inside the same function.

- **[LOGIC] `scripts/verify_all.sh:589`** — span re-extracted via
  `printf '%s' "$full_line" | grep -E -i -o -m1` after the line is proven to FAIL.
  Safe (double-quoted variable, no `eval`); intended per D-5 (matched-span reporting).
  Defensive-comment-worthy note only.

- **[STYLE] `scripts/test-verify-i6.ps1:309`** — Rev-4 lockstep regex is correct but
  fragile to whitespace/punctuation reshuffles in `verify_all.ps1:496`. A defensive
  improvement: two separate `-match` checks (anchors + `exclude = @('.claude/')`).

### NIT

- **[FANOUT] `architecture.html:326`** — says `当前实际版本是 v0.17.4`. Per design §10
  intentionally not in v0.18 fan-out (file carries a "v0.5/v0.6 snapshot" caveat).
  Following the design's contract.
- **[STYLE] `scripts/verify_all.sh:514-515`** — comment header previews the exempt-file
  extension before the array literal. Reads cleanly.
- **[STYLE] `scripts/test-verify-i6.sh:130`** — `fx_expect=( ... \ ... \ ... )`
  multi-line array with backslash continuation. Pure preference.

## Drift-(b) decision: ACCEPT as in-scope drift

The developer added `scripts/test-verify-i6.{ps1,sh}` to `i6_exempt_files` (bash) and
`$exempt` (PS), and flagged this as a divergence from design §3/§12's
"exempt-FILE membership unchanged" statement.

**Decision: ACCEPT.** Rationale:

1. **Design §7.3 #3 mandates the test driver hold a verbatim copy of the 13-entry
   banned list.** A driver that re-declares the list (which the design *requires*) is
   structurally identical to `verify_all.{ps1,sh}` themselves — both files store
   banned-phrase strings as source code. Both must be exempt for the same reason.
2. **Class identity with the pre-existing `verify_all.*` self-exemption.** Extends an
   established exemption rule along its own logic, not a new exemption class.
3. **§3/§12 wording is superseded by §7.3 #3 on this specific implementation point.**
   §7.3 (specific) governs over §3/§12 (generic).
4. **Behavior is correct** in both shells (verify_all PASS 30/30, test-verify-i6
   34/35 green).
5. **Routing to architect for a one-sentence amendment is disproportionate.** The
   principle is captured in the new `.harness/insight-index.md:26` line.

**No design amendment required.**

## Requirement coverage check

| Criterion | Status |
|---|---|
| AC-1 bypass caught | ✅ `fx-bypass.md` → HIT #5 |
| AC-2 adjacent still caught | ✅ `fx-adjacent.md` → HIT #5 |
| AC-3 false positive not raised | ✅ `fx-accurate.md` → NO hit; entry #10 `exclude=.claude/` clears READMEs |
| AC-4 repo stays green | ✅ verify_all PASS 30/30 both shells |
| AC-5 cross-shell parity | ✅ Assertion 2 both shells |
| AC-6 case-insensitivity | ✅ `fx-case.md` → HIT #5 |
| AC-7 metachar safety | ✅ `fx-meta-backtick.md` + `fx-meta-arrow.md` |
| AC-8 exemption preserved | ⚠️ Indirect only (no direct fixture); live PASS proves it |
| AC-9 gap boundary | ✅ Assertion 5 |
| AC-10 docs synced | ⚠️ One missed stamp at `40-locations.md:25` (MAJOR) |
| AC-11 test driver | ✅ Both drivers green |

## Verdict

**CHANGES REQUIRED** — 1 MAJOR (single one-line `40-locations.md:25` stamp). After that
fix lands, the work is **APPROVED FOR QA**. The MINORs are non-blocking observations.
Drift-(b) is ACCEPTED.

---

## Conditional approval realized — 2026-05-23

Developer Rev-2 applied the one-line fix (`40-locations.md:25`: `v0.17.4` → `v0.18.0`)
and re-ran both shells: `verify_all.ps1` and `verify_all.sh` both PASS 30/0/0;
`test-verify-i6.ps1` PASS 35/0 and `test-verify-i6.sh` PASS 34/0. Repo-wide
`v0.17.4` grep sweep documented in `04_DEVELOPMENT.md` Rev-2 — no remaining
in-scope freshness-stamp drift. The single CR-MAJOR is closed.

**Final verdict: APPROVED FOR QA.**

The dev-map.md:78 `57 PS / 53 Bash at v0.17.4` test-supervisor assertion-count stamp
that the developer surfaced is a different metric (test-supervisor stats, not
verify_all check-count) and out of T-004's §10 contract — correctly left alone.
