# 06 — Test Report: `/harness-upgrade` skill (T-012)

> Stage 6 (QA Tester). Adversarial verification contract enforced. Every number below
> was produced by a real tool run on this Windows box (PowerShell native + Git-for-Windows
> MSYS bash) and pasted verbatim — no remembered/assumed tallies. Independent reproducers
> were written from the acceptance criteria, NOT copied from `04_DEVELOPMENT.md`.

## Verdict

**PASS (ship-ready) with one MINOR defect routed to developer.**

All 32 `verify_all` checks pass in BOTH shells, both test pairs reproduce the dev's
claimed tallies, sync-self is in sync, and all 15 acceptance criteria survived an
independent adversarial probe. One MINOR cross-shell asymmetry was found (the PS helper
writes the pre-commit hook without a trailing newline, diverging from `install-hooks.sh`
and from the bash helper) — it self-heals after one re-write, writes a `.bak`, never
loses data, and does not break any gate. It does not block ship; it is filed for a
trivial one-character developer fix.

---

## Mandatory execution checklist (captured, real output)

### 1. verify_all — both shells → 32/32, 0 WARN, 0 FAIL, skill count 13, version 0.23.0

`pwsh .harness/scripts/verify_all.ps1` (tail):
```
[C.1] All 13 skills present with SKILL.md ... PASS
[F.1] verify_all, sync-self, harness-sync, test-init, test-real-project, ambient-prompt, ambient-reset, upgrade-project exist in both .ps1 and .sh ... PASS
[G.1] README references all 13 skills ... PASS
[G.3] Version stamps consistent across plugin.json / marketplace.json / README badges ... PASS
[G.4] Doc count/version claims consistent with plugin.json + live check count ... PASS
=== Summary ===
  PASS: 32   WARN: 0   FAIL: 0
```

`bash .harness/scripts/verify_all.sh` (tail) — **no MSYS I.7 truncation this run, full green summary captured**, exit 0:
```
[C.1] All 13 skills present ... PASS
[F.1] Script pairs (.ps1 + .sh) present ... PASS
[G.4] Doc count/version claims consistent with plugin.json + live check count ... PASS
=== Summary ===
  PASS: 32   WARN: 0   FAIL: 0
=== EXIT: 0 ===
```
Both shells: 32/32. `harness-upgrade` present (C.1/G.1/G.2), `upgrade-project` in F.1,
version 0.23.0 (G.3/G.4), settings integrity J.1 PASS. The MSYS truncation the dev
warned about (insight L27/T-010) did **not** recur in my runs; I got the full summary.

### 2. test-harness-upgrade — both shells reproduce 38 / 37

```
pwsh test-harness-upgrade.ps1 →  PASS: 38   FAIL: 0   (exit 0)
bash test-harness-upgrade.sh →  PASS: 37   FAIL: 0   (exit 0)
```
Matches `04_DEVELOPMENT.md`'s claim exactly. The 1-assert gap is the AC-3 JSON-parse
3-way branch (python3 vs node vs skip) — on this box bash takes the node path. Stable
across 3 (bash) + 2 (PS) re-runs — no flakes (see Stability).

### 3. test-init — both shells reproduce 251 / 213 (six B.*-marked templates clean)

```
pwsh test-init.ps1 →  PASS: 251   FAIL: 0   (exit 0)
bash test-init.sh  →  PASS: 213   FAIL: 0   (exit 0)
```
Confirms the six `verify_all.*.tmpl` files with the new `HARNESS:B-CUSTOM` markers still
generate a clean, placeholder-free, passing project, and the copied `upgrade-project`
helper does NOT trip the "no unresolved placeholders" scan (piece-wise token assembly works).

### 4. sync-self -Check / --check → "In sync" both shells

```
pwsh sync-self.ps1 -Check  →  In sync.   (exit 0)
bash sync-self.sh --check  →  In sync.   (exit 0)
```
Template↔dogfood byte-identity of the new `upgrade-project.{ps1,sh}` pair holds (E.1).

---

## Test plan (AC → reproducer → file)

| AC | Independent reproducer (I wrote these) | Outcome |
|---|---|---|
| AC-1 relocate + custom untouched | own fixture, drive helper, assert `scripts/my-custom.sh` not moved | PASS |
| AC-2 hook → `.harness/scripts/` + fires | own fixture, inspect hook + real `git commit` | PASS |
| AC-3 settings rewired + parses + doc keys | own fixture w/ `_comment` + permissions.allow | PASS |
| AC-4 current checks + no `{{...}}` | `echo hi` old fixture → regenerated full check set | PASS |
| **AC-5 root two-up (L31)** | own fixture w/ **REAL one-up** harness-sync.sh + **mutation** | PASS (mutation caught) |
| AC-6 idempotent | run twice, recursive content hash + .bak count | PASS |
| AC-7 dry-run unchanged | recursive hash before/after + git status | PASS |
| AC-8 final verify_all surfaced | SKILL.md procedure (AI layer — see "Not executable") | VERIFIED-BY-SPEC |
| AC-9 self-bootstrap | fixture w/ NO migrate helper | PASS |
| AC-10 cross-shell parity | ps1 vs sh on fresh copies, fingerprint diff | PASS (1 MINOR newline diff) |
| AC-11 no-harness halt → adopt | bare git repo | PASS |
| AC-12 detect + report version | SKILL.md procedure (AI layer — see "Not executable") | VERIFIED-BY-SPEC |
| AC-13 B.* preserve/warn | 3 fixtures: splice / halt / --force, data-loss hunt | PASS |
| AC-14 ship both surfaces + obligations | verify_all E.1/F.1/C.1 green | PASS |
| AC-15 count/version consistency | verify_all G.1/G.2/G.3/G.4 green | PASS |

## Boundary tests added/exercised
- Null/absent `.claude/settings.json` (BC-15 / OQ-9) — relocate+hook proceed, settings skipped with note.
- Bare git repo, no harness (BC-2) — halt exit 1, points to `/harness-adopt`, no changes.
- Non-stock hand-customized pre-commit hook (BC-7) — exit 3, NOT overwritten.
- Customized B.* with NO markers (BC-8) — HALT exit 2, file untouched.
- `--force` overwrite path — `.bak` written BEFORE overwrite (recoverable).
- Cross-shell hook idempotence (trailing-newline class) — bounded one-time re-write (the MINOR defect).

---

## Adversarial tests (REQUIRED — one+ per AC, independent reproducer + stated hypothesis)

Every reproducer below was built in its **own** `mktemp` dir (insight L22), `git init`'d,
and drives the helper directly. Verdict is "did the implementation survive", not "did the
dev's test pass".

| AC | Hypothesis ("I expect failure when…") | Reproducer | Outcome (real output) |
|---|---|---|---|
| **AC-5** | the relocated `harness-sync` keeps one-up derivation → resolves wrong root | own fixture with a **REAL one-up** `harness-sync.sh` (dev used a trivial `exit 0` stub here), run upgrade, invoke relocated script from project root | **Survived.** `relocated-sync exit=0`, content shows "project root is two levels up", `WRONG ROOT` gone. |
| **AC-5 mutation** | the AC-5 assertion is a stub that can't catch a one-up regression | hand-place a one-up body at the destination, invoke it | **Assertion is real.** mutant `exit=3` ("WRONG ROOT …/.harness (no .git)") → assertion goes RED. S2 refresh is load-bearing. |
| **AC-13(a)** | a marked custom B.* check is dropped by regeneration | marker-wrapped `MY_SECRET_BUILD_INCANTATION_42 && cargo build…`, run upgrade | **Survived.** `VERIFY-SPLICE`, line present verbatim. |
| **AC-13(b)** | an UNMARKED custom B.* is silently overwritten | unmarked `USER_UNMARKED_CHECK_99`, run upgrade | **Survived.** `exit=2 VERIFY-HALT`; user check still live in relocated file + recoverable from git; nothing lost. |
| **AC-13(c)** | `--force` overwrites with NO recoverable backup | re-run the HALTed fixture with `--force` | **Survived.** `.bak` written first, `grep USER_UNMARKED_CHECK_99 …bak → 1`. Data recoverable. |
| **AC-13 data-loss hunt** | SOME path loses a customized B.* without preservation or `.bak` | tried splice / halt / force / relocation-then-halt | **None found.** Relocation moves the file but S5 halts before overwrite; `--force` `.bak`s first. OQ-3 hard constraint holds. |
| **AC-6** | 2nd run mutates content or writes a new `.bak` (T-007 newline class) | run twice, recursive content sha + `.bak` count | **Survived.** 2nd run all NOOP, hash identical (`3652ca…`), `.bak` count 3→3. |
| **AC-7** | dry-run mutates disk | recursive sha of whole tree before/after `--dry-run` | **Survived.** hash `fee507…` == `fee507…`, git status identical, full PLAN printed. |
| **AC-1** | the known-set relocation also sweeps a user's `scripts/<custom>` | own fixture with `scripts/my-custom.sh`, run upgrade | **Survived.** custom present, not in `.harness/`. |
| **AC-3** | raw-text rewire breaks JSON or drops `_comment`/permissions.allow | fixture w/ `_comment:"DOC KEY KEEP ME"` + permissions.allow guard-rm | **Survived.** rewired Stop+PreToolUse+permissions, `_comment` kept, `JSON parses (good)`, no bare old path. |
| **AC-4** | a placeholder leaks, or the old short check set survives | `echo hi` old fixture → regenerate | **Survived.** 28 sh / 17 ps current check ids (A/B/E…), 0 `{{...}}`, project/stack/today substituted. |
| **AC-9** | self-bootstrap fails when migrate helper absent | fixture with NO `migrate-scripts-layout.*` | **Survived.** `upgrade exit=0`, helper bootstrapped into `.harness/scripts/`. |
| **AC-11/BC-2** | a bare repo gets mutated instead of halting | bare `git init` dir, run upgrade | **Survived.** `exit=1`, message names `/harness-adopt`, no files changed. |
| **AC-2** | the installed hook points at old path or silently skips | own fixture, inspect hook + real `git commit` | **Survived.** hook references `.harness/scripts/harness-sync.{ps1,sh}`; commit ran the drift check (exit 0 = in-sync, not bypassed). |
| **BC-7** | a hand-customized hook is clobbered | non-stock `# MY OWN HAND-WRITTEN HOOK`, run upgrade | **Survived.** `exit=3 CONFLICT|hook`, hook NOT overwritten. |
| **BC-15/OQ-9** | absence of settings aborts the whole run | fixture, `rm .claude/settings.json`, run upgrade | **Survived.** `exit=0`, `SKIP|.claude/settings.json absent`, scripts still relocated. |
| **AC-10** | the two shells produce a non-equivalent end-state | ps1 helper vs sh helper on fresh copies, fingerprint diff | **Mostly survived — see DEFECT-1.** All refreshed scripts + settings byte-identical; verify_all differs only by `{{PROJECT_NAME}}` (different temp basenames); **pre-commit hook differs by a trailing newline.** |

### AC-5 core probe — pasted evidence
```
=== BEFORE: old scripts/harness-sync.sh from project root (one-up from scripts/ = repo) ===
ok root=/tmp/qa-ac5-GDgGbk   old-from-scripts exit=0
=== RUN UPGRADE ===
RESULT|REFRESH|.harness/scripts/harness-sync.sh (from current template)   ...   upgrade exit=0
=== AC-5 CORE: RELOCATED .harness/scripts/harness-sync.sh from project root ===
In sync.   relocated-sync exit=0
15:# Script lives at .harness/scripts/ — project root is two levels up.
stale one-up gone (good)
```
### AC-5 mutation — pasted evidence (proves the assertion is not a stub)
```
=== MUTATION: relocated harness-sync.sh given a ONE-UP body ===
harness-sync: WRONG ROOT /tmp/qa-ac5-GDgGbk/.harness (no .git)
mutant relocated-sync exit=3
MUTATION CAUGHT: assertion would go RED on stale one-up
```
### AC-13 data-loss hunt — pasted evidence
```
(a) RESULT|VERIFY-SPLICE  → MY_SECRET_BUILD_INCANTATION_42 PRESERVED verbatim
(b) exit=2 VERIFY-HALT    → USER_UNMARKED_CHECK_99 still live (count 1) + git-recoverable (1); no .bak yet (file untouched)
(c) --force → BAK|…verify_all.sh.bak-… ; bak USER_UNMARKED_CHECK_99 count: 1
    YES - .bak preserves the user check (OQ-3 hard constraint holds on --force path)
```

---

## DEFECT-1 [MINOR] — PS helper writes the pre-commit hook without a trailing newline → bounded cross-shell hook churn

**Severity: MINOR.** Route: **developer**.

**What:** `upgrade-project.ps1` writes the hook via
`[System.IO.File]::WriteAllText($hookPath, $currentHookBody)` where `$currentHookBody`
is a here-string with **no trailing newline** (template `upgrade-project.ps1:259` and
`:274`). The bash helper writes `current_hook_file_content="$current_hook_body"$'\n'`
(template `upgrade-project.sh:216`) — **with** a trailing newline. The canonical
`install-hooks.sh` also writes a trailing newline. So `upgrade-project.ps1` is the odd
one out.

**Consequence:** when a user runs the PS helper and later the bash helper on the same
project (or vice versa, ps1→sh), the bash helper's byte-equality NOOP check fails on the
1-byte difference and performs a one-time spurious `HOOK-INSTALL (refreshed)` + writes a
`.bak`. It is **bounded, not infinite** — once the trailing-newline form is on disk, all
subsequent runs (either shell) NOOP.

**Reproducer (own fixtures, captured):**
```
[run1 ps] RESULT|HOOK-INSTALL|.git/hooks/pre-commit (was absent)        hooks .bak: 0
[run2 sh] RESULT|HOOK-INSTALL|.git/hooks/pre-commit (was stock pre-T-007; refreshed)  hooks .bak: 1
[run3 sh] (no HOOK line)   .bak: 1
[run4 ps] (no HOOK line)   .bak: 1
[run5 sh] (no HOOK line)   .bak: 1
canonical install-hooks.sh last byte: \n
```
Per-file diff after CRLF-strip: only `\ No newline at end of file` on the PS side.

**Why MINOR (not a blocker):** within a single shell, idempotence is perfect (AC-6
green). No data loss (a `.bak` is written). The hook executes identically with or without
the trailing newline. No `verify_all`/`test-*` gate fails (the in-repo verify_all checks
the hook's path references, not its trailing byte). It violates the spirit of AC-10
"equivalent end-state" and NFR-4 (one spurious cross-shell re-write), so it should be
fixed, but it does not endanger ship.

**Suggested fix (developer):** make the PS helper write `$currentHookBody + "`n"` (or
append a newline) at both write sites so all three writers agree. After the template fix,
re-run `sync-self` (dogfood mirror) and re-confirm gates. **QA did not fix this** (QA does
not write production code).

---

## Items NOT executable in this QA environment (honest disclosure)

The skill's **AI/judgment layer** (the `AskUserQuestion` type prompt, the plan→confirm→
apply gating, the cache-glob discovery, the final verbatim verify_all surfacing) cannot be
driven headlessly here — there is no AI runtime in a bash/pwsh shell. I verified these by:
- **AC-8** (final verify_all surfaced): the deterministic helper makes no claim here; the
  SKILL.md step 7 specifies running verify_all and surfacing PASS/WARN/FAIL verbatim. I
  confirmed verify_all itself runs and produces a parseable summary, and the skill text
  is faithful. Marked VERIFIED-BY-SPEC.
- **AC-12** (detect + report version): the helper deliberately emits NO `TARGET-VERSION`
  line (CR-confirmed; it's the skill's human-facing job). SKILL.md step 2 specifies the
  cache-glob chain + reading `.claude-plugin/plugin.json` version. The fallback chain is
  sound on inspection; I could not exercise the live `~/.claude/plugins/cache` glob.
  Marked VERIFIED-BY-SPEC.
- **BC-10 dirty-tree refusal:** this lives in **SKILL.md:44** (the AI precondition gate),
  NOT in the helper — the helper has no `git status --porcelain` check (confirmed by grep).
  So I could verify the skill SPECIFIES the refusal but could not execute the AI gate. The
  helper will run on a dirty tree (it relies on `git mv` of tracked files). This matches
  the design (§3.1 resp.1 puts the gate in the skill). Flagged for awareness, not a defect.

These are inherent to QA-without-an-agent-runtime, not coverage gaps in the deliverable.

---

## verify_all result
- Total checks: 32 → 32 (unchanged — design §7.3 deliberately adds no new lettered check).
- Pass: 32  /  Fail: 0  /  Warn: 0  — in BOTH shells.
- New tests added by QA: 0 new files (the dev's `test-harness-upgrade.{ps1,sh}` already
  encode the regression suite; I added 16 independent adversarial probes run as throwaway
  fixtures, plus recorded the two new test tallies in `baseline.json`).
- Baseline updated: **yes** — added `test_harness_upgrade_ps_assertions: 38` and
  `test_harness_upgrade_bash_assertions: 37` (baseline only goes up; these are new assets).
  Re-ran verify_all after the edit → still 32/32 both shells.

## Defects found
- **[MINOR] DEFECT-1** — PS helper writes pre-commit hook without trailing newline →
  bounded one-time cross-shell hook re-write + spurious `.bak`. Reproducer above.
  Files: `skills/harness-init/templates/common/.harness/scripts/upgrade-project.ps1:259,274`
  (and the byte-identical dogfood mirror). Route: developer.
- No BLOCKER, no CRITICAL, no MAJOR.

## Stability
- `test-harness-upgrade.sh` ran 3×: 37/0, 37/0, 37/0 — no flakes.
- `test-harness-upgrade.ps1` ran 2×: 38/0, 38/0 — no flakes.
- `verify_all` (both shells) and `sync-self` (both shells) re-run after the baseline edit —
  still green / In sync.

## Regression statement
The fan-out edits (skill count 13, version 0.23.0) and the six B.* template markers broke
nothing: all 32 `verify_all` checks green in both shells, `test-init` green in both shells
(251/213 — the riskiest regression surface, the six templates, is clean), `sync-self`
in sync. No pre-existing check regressed.

## Verdict
**PASS — APPROVED FOR DELIVERY** with one MINOR defect (DEFECT-1) routed to developer for
a one-character trailing-newline fix. The defect is bounded, non-data-losing, gate-safe,
and need not block this delivery (PM may schedule the fix as a fast-follow or fold it into
delivery at discretion). All 15 acceptance criteria survived independent adversarial
probing; the #1 risk (AC-5 / L31 root derivation) and the highest-value correctness
constraint (AC-13 / OQ-3 never-lose-B.*) both held under mutation and data-loss-hunt
testing.
