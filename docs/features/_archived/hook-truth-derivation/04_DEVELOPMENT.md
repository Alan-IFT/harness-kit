# Development Record — T-16 `hook-truth-derivation`

- **Stage**: 4 (developer), single Developer (no `dev-*` partition agents in this repo).
- **Inputs**: `01_REQUIREMENT_ANALYSIS.md` (READY) · `02_SOLUTION_DESIGN.md` (round 2, READY) ·
  `03_GATE_REVIEW.md` (round 2 — **APPROVED FOR DEVELOPMENT**, binding conditions **F-12** and
  **F-13**, plus the eight empirical captures in its `§8`).
- **deferred-human**: defer, do not ask. No `BLOCKED: NEEDS-HUMAN` point arose. No hard stop.
- **Captures**: `/tmp/claude-1000/-home-alan-Programs-harness-kit/18df63fc-…/scratchpad/t16-captures/`
  (session scratch, per design §11 — deliberately **not** under `docs/features/`, which
  `archive-task` would orphan).

---

## Summary

The four derivation flows stopped *carrying* hook command byte-forms and started *asking* for them.
`resilient_cmd` / `Get-ResilientCmd` are retired from `upgrade-project.{sh,ps1}` and
`migrate-scripts-layout.{sh,ps1}`; each flow now has a lazy, memoised **spec adapter** over
`hook-spec.{sh,ps1}` whose only alternative to the spec's bytes is "no answer" — which is what makes
`guard-rm` fail-CLOSED by construction rather than by inspection. The two `SKILL.md` placeholder
tables carry semantics and an instruction to invoke the spec; `verify_all`'s `F.2` gained a
`PreToolUse` **containment window** (no new check — count stays 32); and `test-init`'s T-13 oracle was
re-anchored off the now-delegating flow onto the frozen fixtures, with Group A′ re-purposed into two
standing regression scans.

---

## Files changed

**Flow files** (edited at the `templates/common/` source, propagated by `sync-self`; `sync-self --check` → `In sync.`)

- `skills/harness-init/templates/common/.harness/scripts/upgrade-project.sh` → `.harness/scripts/upgrade-project.sh` — `resilient_cmd` (25 lines) replaced by the `hsa_*` adapter; `ph_o`/`ph_c` **hoisted to S3 scope**; S3.0 takes host OS from `hsa_hostos` and its spec call moved **inside** the token-present ∧ target-present guard; S3.2 `s32_win`→`s32_os`; two `GAP|hook-spec|absent|…` failure branches.
- `…/upgrade-project.ps1` → `.harness/scripts/upgrade-project.ps1` — same set **minus** the `ph_o` hoist (`$phOpen` was already at S3 scope — gate Q5). `$IsWindows` reads at the two S3.0 hook-wiring sites replaced by `$hsOs` / `$hsIsWin`.
- `…/migrate-scripts-layout.sh` → `.harness/scripts/migrate-scripts-layout.sh` — adapter (no template-root candidate); `s32_win`→`s32_os`; `SPEC-GAP` plan branch.
- `…/migrate-scripts-layout.ps1` → `.harness/scripts/migrate-scripts-layout.ps1` — same set.

**Spec headers** (comment-only; ledger rows 9-12 **+ F-13**)

- `…/hook-spec.sh` → `.harness/scripts/hook-spec.sh` — `:8-10` provenance sentence, `:39-52` hand-off list → the corrected §9.1 inventory, `:97-98` second provenance sentence.
- `…/hook-spec.ps1` → `.harness/scripts/hook-spec.ps1` — `:7-9`, `:38-51`, **and `:94`** — the PowerShell twin of the `sh:97-98` sentence that ledger row 11 omitted (**F-13, applied**).

**Gate**

- `.harness/scripts/verify_all.sh` — `F.2` containment window (one `awk` pass, `exit 2`/`exit 3` signalling, `$?` captured explicitly); three new tokens accumulate into the **existing** `f2_problems`. No `step` call added.
- `.harness/scripts/verify_all.ps1` — same rule; three tokens into the existing `$problems`. No `Step` call added. `[ \t]` width class in both shells; `(($lines[$start..$end]) -join "…")` parenthesised and never adjacent to `+`.

**Tests**

- `.harness/scripts/test-init.sh` — SCOPE-NOTE rewrite; oracle re-anchored to the frozen `EXP_*` fixtures; anti-vacuity probe moved onto the fixture; Group A′ re-purposed into 4 idiom-scan + 4 substitution-discipline rows. **17 T-16 rows in, 17 out.**
- `.harness/scripts/test-init.ps1` — same, plus the A′ `Assert` **lifted out of** the per-cell loop (that loop now carries 2 `Assert`s per cell, not 3) into a separate 8-row block; the stale `:700` comment re-pointed at the spec.
- `.harness/scripts/test-real-project.{sh,ps1}` — **comment only**: the literals labelled a deliberate frozen oracle with the citation.

**Docs / memory**

- `AI-GUIDE.md`, `docs/getting-started.md`, `.harness/rules/60-tool-handoff.md` — the three stale prose sentences (§10.1 L1/L2/L3, transcribed).
- `.harness/rejected-decisions.md` — two records appended: `hook-byteform-test-literal-retirement`, `hook-spec-raw-query`.
- `CONTEXT.md` — **Spec adapter** and **Containment window** coined (D-3).
- `.harness/scripts/baseline.json` — `_qa_note_t16` appended. **Every numeric key byte-frozen — verified mechanically: `numeric keys deviating from the frozen ledger: NONE`.**
- `CHANGELOG.md` — 0.46.0 entry (folded into the unreleased version; no version stamp moved).
- `docs/dev-map.md` — see below.

**Not changed** (asserted by §13's freeze method, not claimed): `guard-rm.{sh,ps1}` + both twins · `evals/guard-rm-cases.md` · `test-guard-rm.{sh,ps1}` · `.harness/rules/75-safety-hook.md` (**still exactly 200 lines**) · `docs/proposals/frontier-gaps-2026-07.md` · `.claude/**` · `CLAUDE.md` · `.github/copilot-instructions.md` · `sync-self.{sh,ps1}` · `test-harness-upgrade.{sh,ps1}` · `settings.json.tmpl` (M-C reverted byte- **and** mtime-exact) · `README.md` (all four badges) · `docs/tasks.md` (stage 7's row).

---

## F-12 — the true pre-change state of the A′ scans (binding condition; the design's sentence is NOT transcribed)

The design's "both scans are green on the pre-change tree — measured, not assumed" is **false for the
idiom scan**. Measured on the pre-change tree, before this task's first write:

| A′ scan | Pre-change | Post-change |
|---|---|---|
| idiom (`Set-Location -LiteralPath` / `CLAUDE_PROJECT_DIR`, non-comment lines) | **16 hits — all four flow files RED** | **0** |
| substitution discipline (`${…/…}` family in `.sh`, `-replace` in `.ps1`, non-comment) | **0 hits — green** | **0** |

Pre-change idiom hits, per file: `upgrade-project.sh:106,108,112,114` · `upgrade-project.ps1:115,117,121,123` ·
`migrate-scripts-layout.sh:121,123,127,129` · `migrate-scripts-layout.ps1:39,41,45,47`. This reproduces
the gate's F-12 measurement exactly. **Green-after-red is the correct state for an AC-3 assertion**: the
scan is a real regression barrier, not a tautology. I did not add an exclusion, narrow the file set, or
otherwise "repair" the scan. Per gate Q2 I edited the flow files first and `test-init` second, so the
transient 13-red-row state never appeared.

A vacuity hole I closed while writing the scans (see **DESIGN DRIFT 1**): a *missing* flow file now
scores `missing`, not `0`, in both shells — otherwise deleting a flow would turn both of its rows
vacuously green.

---

## verify_all result

- **Baseline** (pre-change, captured before the first write): **PASS 32 / WARN 0 / FAIL 0**, exit 0.
- **After changes**: **PASS 32 / WARN 0 / FAIL 0**, exit 0, check count **32** read from the run.
- **Delta**: 0 new failures, 0 new warnings, 0 checks added/removed/renamed. `sync-self --check` → `In sync.`

### Pinned drivers — real runs, both before and after

| Driver | Baseline | After | Pin | Summary line |
|---|---|---|---|---|
| `test-init.sh` (python3 present) | PASS 391 / FAIL 0 | **PASS 391 / FAIL 0** | — | `=== Result ===` |
| `test-init.sh` (**python3 shimmed to fail**) | — | **PASS 355 / FAIL 0** | `test_init_bash_no_python3_assertions` = 355 ✔ | `=== Result ===` |
| `test-real-project.sh` | 90 / 0 | **90 / 0** | 90 ✔ | `=== Result ===` |
| `test-harness-upgrade.sh` | 89 / 0 | **89 / 0** | 89 ✔ | `=== Summary ===` |
| `test-verify-i6.sh` | 58 / 0 | **58 / 0** | 58 ✔ | `=== Result ===` |
| `test-supervisor.sh` (python3 present) | 46 / 0 | **46 / 0** | — | `=== Result ===` |
| `test-supervisor.sh` (**shimmed**) | — | **45 / 0** | `..._bash_no_python3_...` = 45 ✔ | `=== Result ===` |
| `test-language.sh` | 39 / 0 | **39 / 0** | 39 ✔ | `=== Summary ===` |
| `test-guard-rm.sh` | 87 / 0 | **87 / 0** | 87 ✔ | `=== test-guard-rm summary ===` |

Every row is a **transcribed real run**, never arithmetic. Each driver **reached its own summary line**
(three of them print `=== Summary ===` / `=== test-guard-rm summary ===` rather than `=== Result ===`;
that is their own idiom, not a truncated run). Notably, the `355` figure comes from a run with a
`python3` shim that exits 127 — the key *names* that host condition, so the python3-present 391 is not
comparable to it (insight 2026-07-31).

---

## Acceptance criteria — how each was discharged (measured, not argued)

**AC-1 (single source, C-5).** Mutated one byte-region (`2>/dev/null` → `2>/dev/nulX`) in the unix
`guard-rm` shape of **both** spec twins, **both copies each**. All three fixtures then carried the
mutated value, with `grep -c nulX` = **0** in every one of the four flow files. Reverted from a
byte-preserving copy: `grep -rn nulX` over `.harness/scripts/` + `templates/` → **0**; spec answer
restored; `sync-self --check` → `In sync.`

**AC-2 (byte-identity, C-1/C-2/C-3/C-4).** Pre-change values came from the **S0 working-tree captures**
(never `git show HEAD:` — HEAD is `cb0ed57` v0.44.0 and `git cat-file -e HEAD:.harness/scripts/hook-spec.sh`
returns *"exists on disk, but not in 'HEAD'"*; `verify_all.sh` alone is 50 lines from HEAD).

- C-1/C-2 — `resilient_cmd` extracted from the S0 copies by the same awk-range+eval technique the
  pre-change `test-init.sh:771` used → `pre-<flow>.tsv`; the post-change flows run on an 8-cell fixture,
  each written `"command"` value re-encoded to the JSON-string body and diffed:
  **`diff pre-upgrade-project.tsv post-upgrade-project.tsv` → 0 differing lines (8/8)**;
  **`diff pre-migrate-scripts-layout.tsv post-migrate-scripts-layout.tsv` → 0 differing lines (8/8)**.
  The two pre-change TSVs are themselves identical (the second copy really was byte-identical).
  The `fx-tokens` S3.0 fixture adds the four host-OS cells: **0 differing**.
- C-3 (PowerShell, unexecutable here — source-literal level) — the four `return (…)` expressions from the
  S0 `upgrade-project.ps1:115,117,121,123` and `migrate-scripts-layout.ps1:39,41,45,47`, whitespace-stripped
  and diffed against the S0 `hook-spec.ps1:102,104,108,110`: **0 differing lines, both pairs.** The
  pre-change flow literal and the spec literal are the same text at S0, so delegation cannot move a byte.
  This is **not** a run — the run is operator items 12(b)/13(b).
- C-4 (prose) — the eight byte-forms extracted from the **S0** `skills/harness-init/SKILL.md` rows, markdown
  `\|` unescaped per B-4, compared against `hook-spec.sh command <tool> <os>`: **8 cells, 0 differing.**

**AC-3 (no literal survives).** Post-change idiom scan over the four flow files: **0** non-comment hits
(from 16). Both `SKILL.md` files: **0** hits of either idiom. Now a **standing** test row.

**AC-4 (fail-closed, C-6) — measured.** Static half over all four flow-emitted `guard-rm` values
(2 flows × 2 OS): no `|| exit 0`, no trailing `exit 0` — **0 violations**. Unix runtime half, executing
the value the flow actually **wrote**:

| Condition | Exit |
|---|---|
| `guard-rm.sh` **absent** | **127** (fail-CLOSED) |
| present, benign payload (`ls -la`) | 0 |
| present, destructive payload outside the repo (`rm -rf /etc/hosts`) | **2** — `BLOCKED — destructive command targets path outside project root.` |
| destructive payload, guard **deleted** again | **127** |

The middle two rows make the probe anti-vacuous: the emitted command genuinely reaches a working guard.
**The Windows runtime half is an operator obligation (items 12(f)/13(e)) and is not claimed here.**

**AC-5 (spec-unreachable degradation)** — a spec-free template root **and** a script directory with no
`hook-spec.sh` sibling, so all three candidates miss:

| Case | Result |
|---|---|
| `upgrade-project`, token fixture | 1 `GAP\|hook-spec\|absent\|… (host OS undeterminable — …)`, all 4 tokens left in place, 4 `CONFLICT\|congruence\|… unresolved placeholder token`, **exit 4**, `SUMMARY\|` present |
| — run 2 | identical output, **exit 4**, **0 `.bak`** |
| `upgrade-project`, 8-cell brittle fixture | 8 `GAP\|hook-spec\|absent\|<tool>.<ext>: … brittle command left as-is`, settings **byte-identical** to the input, **exit 0**, 0 `.bak` |
| `migrate-scripts-layout` | 8 `SPEC-GAP  … at not found — command left unchanged; run /harness-upgrade`, settings **byte-identical**, **exit 0**, 0 `.bak` |
| — run 2 | run 1 and run 2 output **identical**, settings still identical |

No branch writes an empty or partial `"command"`; no branch leaves residue.

**F-4 counterfactual — the `ph_o` hoist is load-bearing, measured not argued.** A scratch copy with
`ph_o`/`ph_c` declared back inside the region the `hostos`-failure branch skips, on the same input:
**exit 1**, **zero `SUMMARY|` lines**, `upgrade-project.sh: line 674: ph_o: unbound variable`. The
shipped (hoisted) build on that same input: **exit 4** with its `SUMMARY|` line. Exactly the failure
gate F-4 predicted, and exactly the repair.

**AC-6 (prose true).** No file under `AI-GUIDE.md` / `docs/getting-started.md` / `.harness/rules/` still
asserts `Stop hook in `.claude/settings.json`` — grep returns none. Caps re-measured **after** the edit:
`AI-GUIDE.md` **113**/200, `60-tool-handoff.md` **131**/200, `75-safety-hook.md` **200**/200 untouched.
(`60-tool-handoff.md` landed at 131, one over the design's "≤130" estimate — 69 lines of head-room, no
`I.2` WARN; noted for accuracy, not a breach.)

**AC-7 (containment) — both directions, both real runs.**
- **Post-change gate on M-C**: `[F.2] … FAIL` with **exactly two** tokens —
  `…settings.json.tmpl:guard_command_not_in_PreToolUse` and `…settings.json.tmpl:PreToolUse_no_command_entry`.
  **Not** `no_GUARD_COMMAND_placeholder` (the placeholder is present in the file) and **not**
  `no_PreToolUse_block` (the key is present). That contrast **is** the presence-vs-containment proof.
  Whole gate: **PASS 31 / WARN 0 / FAIL 1**, exit 2. Design prediction matched exactly.
- **Anti-vacuity (pre-change) direction**: the **S0 working-tree capture** of `verify_all.sh`, run from
  `.harness/scripts/verify_all.s0.sh` (two levels below the root, as its own `repo_root` derivation
  requires), against the *same* M-C mutation → `[F.2] … PASS`. **Admissibility asserted in both
  directions**, not assumed:
  - S0 capture `sha256 = e5ef1fdd…a679c1` **equals** the S0 table entry for the live file; the live
    file's S0 mtime `1785522577` **<** `T0 = 1785532976`;
  - at proof time the **live** `verify_all.sh` hashed **differently** (`2f2decc1…83fe0`), so the
    "pre-change" copy provably was not the post-change file.
  The transient copy was **deleted in the same step**; `find` for `verify_all.s0.*` → none, and it never
  appears in the S-final `git status`.
- **F-3 totality case**: with the whole `"PreToolUse"` block moved to be the **last** key inside `hooks`
  (still valid JSON), the post-change gate reports `[F.2] … PASS`, **32 / 0 / 0**. ~~Round 1's `== IND`
  rule would have FAILed here.~~ Template restored byte- and mtime-exact afterwards.

  > **CORRECTION (PM, stage 6 — QA finding D-1).** The struck sentence is **false, and QA measured it**:
  > on this *block-form* fixture the round-1 `== IND` rule would have **PASSed too**, because the array's
  > own `    ]` line sits at leading width **exactly 4** — so `== IND` finds a terminator there just as
  > `≤ IND` does (`start=68 IND=4 term=78` under **both** rules). The fixture is real and the gate result
  > above is real; what is false is that it *discriminates between the two rules*.
  >
  > The shipped rule **is** strictly more total — that finding stands — but the proof is QA's fixture,
  > not this one: an **inline** `"PreToolUse"` as the last key, where the shipped rule PASSes and `== IND`
  > FAILs. QA additionally confirmed the terminator-**exclusion** tightening with a separate mutant `M-D`
  > (shipped FAILs it; a round-1-style inclusive window would have PASSed it). Both fixtures are pasted in
  > `06_TEST_REPORT.md` §2.3, and `02_SOLUTION_DESIGN.md` §20 carries the same correction on the design
  > side. This is the "cross-check a claim against the artifact that produced it, not against a
  > plausible-sounding derivation" discipline — the derivation was plausible and wrong.
- Unmutated post-change gate: `[F.2] … PASS`, 32/0/0.

**AC-8, AC-9** — see the tables above.

**AC-10 (PowerShell honesty).** `command -v pwsh` fails on this host. **No `.ps1` in this change set has
been executed, parsed or verified by me** — every `.ps1` edit is green-by-symmetry only. Five numbered
operator items (**12-16**) are written verbatim into `baseline.json:_qa_note_t16` with exact commands;
items **12** and **13** are marked SECURITY-RELEVANT. Numbered standing list **11 → 16** (security-marked
**2 → 4**); the 8 un-numbered T-13 obligations are untouched, so total standing obligations **19 → 24**.
PS pins and both README PS badges stay frozen and move only with the operator's run.

**AC-11 (no scope leakage) — §13 freeze method, re-derived at task start.**
- S0 was **re-derived**, not inherited: the tree was **dirty** — 38 modified + 10 untracked paths. The
  session snapshot's "clean tree" claim is **false**; the requirement's B-11 premise is correct.
- Every frozen path passes all three conditions (not in `post-dirty ∖ pre-dirty`; mtime unchanged from
  the S0 table; mtime `< T0`) **except** `baseline.json`, which is ledger row 25's deliberate
  `_qa_note_t16` append. Its correct frozen assertion — every **numeric** key — was checked mechanically:
  **NONE deviating**.
- `sha256sum -c` over the frozen table: all frozen files byte-identical to S0 except that one.
- The complete `mtime ≥ T0` edit set is exactly the ledger's rows 1-27 (plus the gitignored
  `verification_history.log`, a verify_all run artifact) and contains nothing unledgered.
- No `.t16bak`, no `verify_all.s0.*`, no stray `.bak-*` anywhere at S-final.

---

## Design drift

**DESIGN DRIFT 1 — A′ scans treat a missing flow file as `missing`, not `0`** (both shells).
The design specifies "zero hits over the four flow files". Implemented literally, deleting a flow file
would make **both** of its scan rows vacuously green — the same false-green class T-15's `E-6/E-8`
found. Each scan now scores `missing` for an absent file and the row fails. Additive, no row-count
change (still 4 + 4), no new check.

**DESIGN DRIFT 2 — `60-tool-handoff.md` is 131 lines, not the design's "≤130".**
The transcribed L3 replacement is three lines longer than the estimate. 69 lines of head-room remain;
`I.2` PASSes. Recorded because §10.2 stated a number.

**DESIGN DRIFT 3 — `docs/dev-map.md` was edited** (the design's ledger has no row for it).
Six lines described a state this task falsifies — `:99` said the spec was "to be consumed by the 4
derivation flows in T-16" and `:182` said the flows "still carry their own copies and are re-pointed in
T-16". Leaving them would ship a stale claim in the map the whole pipeline reads. The Developer contract
requires a dev-map update when project structure changes; no file was added, moved or removed, so this is
a **description** correction only.

**Not drift, recorded for the reviewer**: the `hostos`-failure branch skips the S3.0 **placeholder loop**
only (design §3.6 part 2), so `ph_names`/`ph_tools` are also skipped — nothing outside S3.0 reads them.
`ph_o`/`ph_c` are at S3 scope (part 1). The counterfactual above proves both parts are needed and that the
shipped shape is correct.

---

## Open issues for review

1. **The entire PowerShell surface is unverified by me.** Nine `.ps1` files were edited or touched and
   none was parsed or run. Operator items 12-16 are the only evidence path. The three named PS traps were
   handled by construction — whole-file parse (a syntax error in a never-taken branch is fatal), no
   assignment to a read-only automatic (`$hsIsWin`, never `$isWindows`), `-f` everywhere instead of a
   `-join` adjacent to `+`, `@($out) | Select-Object -First 1` never `[string]$out`, `$script:`-scoped
   cache writes, and `$PSNativeCommandUseErrorActionPreference = $false` scoped to the one function that
   must tolerate the spec's designed exit 2 — but *handled by construction* is not *measured*.
2. **RES-1 stands** (design §16.1): standing end-to-end coverage of a *flow-emitted* byte string is one
   `(tool, OS, flow)` cell (`test-harness-upgrade.sh:421` vs `t20_pick`); `migrate-scripts-layout` has
   none. Group A′ now pins both ends of the composition argument, and C-2 covered all 8 cells for both
   flows once, but the standing 8-cell assertion is still open. Must reach `07_DELIVERY.md`.
3. **`R-1` (gate record-only) survives as shipped — but NOT where this line originally said.**
   *(Corrected in round 2, code-review MINOR #4. The original text claimed the divergence was on the
   **key-form** matcher; that is false and it under-claimed a win.)* The `PreToolUse` **key form is
   `[ \t]` in BOTH shells** — `verify_all.sh:333` (inside `awk`) and `verify_all.ps1:321` — as is the
   indent-width measurement and the blank-line skip, so R-1 is **closed** across the whole window rule.
   The one matcher where it survives is the **`"command"` key**: `verify_all.sh:359`
   (`'"command"[[:space:]]*:'`, `grep -qE`) vs `verify_all.ps1:341` (`'"command"[ \t]*:'`).
   Divergence needs a form-feed, vertical tab or carriage return between `"command"` and its colon —
   unreachable in a JSON template the gate itself owns. **Deliberately left open**; see round 2 for the
   measurement showing that "harmonizing" it the cheap way would introduce a real defect.
4. **`docs/tasks.md` delivery row is stage 7's** and was deliberately not written here.
5. **`verify_all.ps1:315` — the `{{GUARD_COMMAND}}` *presence* check is case-insensitive against a
   case-sensitive bash twin (`verify_all.sh:324`, `grep -q`).** **Pre-existing, not T-16's** — verified
   against `cb0ed57`, which carries the identical form at `:308` — and therefore deliberately left
   outside this task's scope (see round 2, MINOR #3). **Post-MINOR-#3 the exposure is a
   diagnostic-token-set divergence only, not a verdict divergence**: a lowercase `{{guard_command}}`
   now FAILs in both shells, because `:338`'s `-cnotmatch` backstops it case-sensitively; the shells
   differ only in how many tokens they print. Bash-verifiable one-character fix; **no operator
   PowerShell item needed**. Carry to `07_DELIVERY.md` alongside R-1 and RES-1.
   *(Added by PM at stage 5 round 2, discharging code-review finding R2-1 — a record edit only. The
   reviewer's point was that a residual recorded solely in a fix section's narrative does not survive
   the stage-6/7 harvest, which reads this list.)*

---

## Dev-map updates

`docs/dev-map.md`, six lines (no structural change — description corrections; see DESIGN DRIFT 3):

- `:25`, `:26`, `:90`, `:91` — the four flow entries now state that hook commands (and, for
  `upgrade-project`, the host OS) are derived from `hook-spec` via the spec adapter, and name each
  flow's spec-absent record (`GAP|` / `SPEC-GAP`).
- `:99` — `hook-spec` is now consumed by `install-hooks` **and all four derivation flows**; the
  "to be consumed … in T-16" forward reference is retired.
- `:182` — the reference-table row now describes the spec adapter (lazy resolution, memoised per
  `(tool, OS)`, single failure return that writes nothing) and points at the spec header for the
  deliberately-retained test-side literals; the "still carry their own copies" claim is retired.

---

## Insight to surface

- A test's *oracle* can be retired by a refactor that never touches the test: once the four flows
  delegated to `hook-spec`, `test-init`'s spec-vs-live-`resilient_cmd` comparison would have compared the
  spec with itself — and the failure mode is loud only because the extraction is *name*-anchored (`awk`
  range / `FunctionDefinitionAst`), which broke; had the extraction kept working, 9 rows would have gone
  green-and-vacuous. Audit every name-anchored extractor before retiring a symbol. · evidence: T-16,
  `test-init.sh:771` pre-change vs `.harness/scripts/test-init.sh` `[T-16][A]` rows post-change
- A "leave the value alone" degradation branch is only idempotent if it also leaves **no plan/report
  residue that a later gate blesses** — `migrate-scripts-layout`'s `SPEC-GAP` line enters `plan`, which
  flips the report from "Already migrated / nothing to do." to the header form, yet the write stays gated
  on `$new -cne $raw` so run 2 is byte-identical output and still 0 `.bak`. Measured both runs, not
  argued. · evidence: T-16 AC-5, `migrate-scripts-layout.sh` SPEC-GAP branch, two captured runs
- `[ \t]` inside a **bracket expression** means a tab to `awk` but the class `{space, backslash, t}` to
  GNU grep 3.11 — so `grep -E '"x"[ \t]*:'` *misses* a real tab and *matches* `"x"t:`. Cross-shell
  "harmonization" of a matcher must be measured per tool, never assumed from a sibling line in the same
  file. Compounding trap: this host's interactive `grep` is **ugrep 7.5.0**, which reads `[ \t]` as a
  tab, so a by-hand check in a login shell endorses the broken form while the scripts (non-interactive
  bash, no profile → `/usr/bin/grep`) get GNU grep. · evidence: T-16 round 2, `verify_all.sh:355-359`
  comment + the captured `/usr/bin/grep --version` / `awk` contrast run

---

## Round 2 — code-review fixes

- **Input**: `05_CODE_REVIEW.md` (round 1, **APPROVED** — 0 CRITICAL, 0 MAJOR, 4 MINOR, 2 NIT).
- **Scope**: the three developer-routed MINORs (#1, #3, #4) and a ruling on the two NITs. **MINOR #2 is
  the architect's** (record-only, PS host-OS delta) and was **not** touched — the host-OS resolution is
  byte-for-byte as round 1 shipped it.
- **Edit set, complete** (7 files, mtime-verified 06:11-06:13; nothing else in the tree moved):
  `hook-spec.{sh,ps1}` ×2 copies each · `verify_all.ps1` · `verify_all.sh` · `test-init.ps1`.
- **No pin moved.** Every `baseline.json` numeric key re-read after the fixes and compared to the frozen
  ledger — 18 keys: `version` 1, then **4 / 7 / 2 / 32 / 316 / 355 / 90 / 90 / 49 / 45 / 58 / 58 / 89 /
  89 / 39 / 39 / 87** — all identical, and the file's mtime (05:44) is round 1's, i.e. it was not
  re-touched this round. `verify_all` check count stays **32**; no check added, renamed or removed.

### MINOR #1 — the fourth stale provenance sentence (fixed, all four copies)

The `hostos` branch claimed the discrimination was one "the existing derivation flows already use
(upgrade-project.sh)". Since T-16 the flows hold no such block and *ask* the spec instead, so the
sentence named a construct that no longer exists in the file it cited **and** stated the relationship
backwards. Reworded to name the true direction:

- `hook-spec.sh:162-163` — *"The discrimination the derivation flows now OBTAIN from here (it was
  duplicated in upgrade-project.sh until T-16) - no third variant is introduced."*
- `hook-spec.ps1:195-197` — same, naming `upgrade-project.ps1`, with the existing 5.1 `$env:OS` note
  preserved verbatim as its third line.

Edited at the **`templates/common/` source** and propagated: `sync-self.sh` reported
`Synced .harness/scripts/hook-spec.ps1` / `…hook-spec.sh`, then `--check` → `In sync.` (exit 0), and
`verify_all`'s `E.1` (which *is* `sync-self --check`) is green. Comment lines held at 2 (bash) / 3 (PS)
so the file shape is unchanged. Repo-wide grep for the old sentence over `*.sh` / `*.ps1` / `*.md`:
**0 hits outside `05_CODE_REVIEW.md`'s own quotation of it.**

### MINOR #3 — case-sensitivity, the real cross-shell verdict divergence (fixed, 4 sites / 7 operators)

- `verify_all.ps1:338` `-notmatch` → **`-cnotmatch`** (the `{{GUARD_COMMAND}}` containment test)
- `verify_all.ps1:341` `-notmatch` → **`-cnotmatch`** (the `"command"` key containment test)
- `test-init.ps1:952,970` `-notmatch` → **`-cnotmatch`** (the comment-line exclusion, both A′ scans)
- `test-init.ps1:954` `-match` ×2 → **`-cmatch`** (`Set-Location -LiteralPath` / `CLAUDE_PROJECT_DIR`)
- `test-init.ps1:971` `-match` → **`-cmatch`** (the substitution-operator pattern)

Each now matches its bash twin's case-sensitive `grep`, and each carries a one-line reason citing the
twin (the repo's stated convention, `migrate-scripts-layout.ps1:272-273`). The `verify_all.ps1` pair is
the load-bearing one: a lowercase `{{guard_command}}` or a `"COMMAND":` key would previously have PASSed
the PS gate and FAILed the bash gate. The `test-init.ps1` five are the same deviation with a harmless
sign (case-insensitivity only widens a must-be-zero scan) and were fixed so the precedent does not stand.

**Not fixed, and deliberately so: `verify_all.ps1:315`** — the *presence* check
(`$tmplText -notmatch [regex]::Escape("{{GUARD_COMMAND}}")`) is also case-insensitive against a
case-sensitive bash twin (`verify_all.sh:324` `grep -q`). It is **pre-existing, not T-16's**: verified
against `git show HEAD:.harness/scripts/verify_all.ps1:308`, which carries the identical form at
`cb0ed57`. The reviewer named four sites and this was not among them, so fixing it would have been
scope expansion into a live gate. **Flagged for the next task / QA** — same class, same block, one
character to fix.

### MINOR #4 — record corrected, and the optional R-1 closure DECLINED with a measurement

"Open issues" item 3 above is rewritten. The reviewer is right on both halves: the key-form matcher is
`[ \t]` in **both** shells (`verify_all.sh:333` / `.ps1:321`), so R-1 is closed there and the record was
under-claiming; the surviving divergence is on the `"command"` key (`verify_all.sh:359` vs `.ps1:341`).

**I did not take the offered cheap closure (make `verify_all.sh` use `[ \t]` too), because measuring it
showed it would be a defect, not a tidy-up.** `awk` and `grep` do not agree on `\t` inside a bracket
expression. Measured on this host against `/usr/bin/grep` — **the grep the gate actually gets**, since
`bash script.sh` starts a non-interactive shell that never loads the profile function shadowing it:

```
$ /usr/bin/grep --version | head -1
grep (GNU grep) 3.11
$ cat -A t2.txt
"command"^I: X$          <- a REAL tab
"command"t: X$
"command"\: X$
"command": X$
$ /usr/bin/grep -nE '"command"[ \t]*:' t2.txt      # the "cheap fix"
2:"command"t: X$
3:"command"\: X$
4:"command": X$                                    # <- MISSES the real tab (line 1),
                                                   #    MATCHES garbage (lines 2,3)
$ /usr/bin/grep -nE '"command"[[:space:]]*:' t2.txt   # as shipped
1:"command"^I: X$
4:"command": X$
$ awk '/^"command"[ \t]*:/ {print NR": "$0}' t2.txt   # awk, for contrast
1: "command"^I: X$                                    # <- awk DOES read \t as a tab
```

GNU grep 3.11 reads `[ \t]` as the class `{space, backslash, t}`. So the "cheap" harmonization would
have made the gate **miss** a tab-indented `"command"\t:` (false FAIL on a valid template) and **accept**
`"command"t:` (false PASS on garbage) — a strictly worse matcher than the `[[:space:]]` it replaced, in
exchange for closing a divergence that needs a form-feed to observe. `verify_all.sh:359` therefore keeps
`[[:space:]]`, R-1 stays open as a record-only item, and the asymmetry is now **documented in the gate
itself** (`verify_all.sh:355-358`) so the next reader does not "fix" it. Caveat worth knowing: this host's
interactive `grep` is **ugrep 7.5.0**, which *does* read `[ \t]` as a tab — so the same experiment run by
hand in a login shell prints the opposite result and would have endorsed the bad fix.

### The two NITs

- **NIT #2 (awk `[ \t]` portability) — TAKEN**, and repurposed. `awk`'s ERE genuinely turns `\t` into a
  tab (measured above), so `verify_all.sh:333,336,340` are correct as they stand and no code changed.
  What I added is the four-line comment at `verify_all.sh:355-358` recording *why* the awk form and the
  grep form must stay different. Comment-only, bash-only file, no PS re-touch.
- **NIT #1 (a half-line on the unused `hsa_hostos` in the migrate flow) — DECLINED.** The comment would
  have to land in `migrate-scripts-layout.ps1` as well as `.sh` to keep the "identical adapter block in
  both flows" property the design mandates, and re-touching that `.ps1` would create a **third** operator
  re-parse obligation (item 13) for a half-line of prose. Cost exceeds the benefit; the dead-code
  question is already answered in the design (§3.6) and in the reviewer's own NIT. Recorded, not done.

### Re-verification — real runs, after the fixes

| Driver | Result | Pin | Summary line reached |
|---|---|---|---|
| `verify_all.sh` | **PASS 32 / WARN 0 / FAIL 0** (count read from the run) | `verify_all_checks` = 32 ✔ | `=== Summary ===` |
| `test-init.sh` (python3 present) | **PASS 391 / FAIL 0** | — | `=== Result ===` |
| `test-init.sh` (**python3 shimmed to exit 127**) | **PASS 355 / FAIL 0** | `test_init_bash_no_python3_assertions` = 355 ✔ | `=== Result ===` |
| `test-verify-i6.sh` | **58 / 0** | 58 ✔ | `=== Result ===` |
| `test-real-project.sh` | **90 / 0** | 90 ✔ | `=== Result ===` |
| `test-harness-upgrade.sh` | **89 / 0** | 89 ✔ | `=== Summary ===` |
| `test-guard-rm.sh` | **87 / 0** | 87 ✔ | `=== test-guard-rm summary ===` |
| `sync-self.sh --check` | **`In sync.`**, exit 0 | — | — |

Every row terminated at its own summary line. The `355` run is the **python3-absent** condition the pin
is named for (the shim exits 127); the python3-present `391` is not compared against it. `test-verify-i6`
and `test-harness-upgrade` were run because they exercise `verify_all.sh` and the `hook-spec`-querying
upgrade flow respectively; `test-guard-rm` because `hook-spec` is the guard command's only home.

### PowerShell — the obligation this round ADDS

`command -v pwsh` still fails on this host: **nothing in `.ps1` was executed or parsed this round
either**, and both round-2 `.ps1` edits are green-by-symmetry only. Because `verify_all.ps1` and
`test-init.ps1` were **re-touched after** the operator list was written:

> **Operator items 14(a) and 15(a) MUST be re-run.** A round-1 `ParseFile` result for either file is now
> stale — it was taken against a different byte sequence. Item 14(a) additionally now covers the
> `-cnotmatch` pair that is the whole point of MINOR #3, and item 15(a) the five in the A′ scans.

The numbered list in `baseline.json:_qa_note_t16` was **not** edited: items 14 and 15 already specify
exactly these parses, so the obligation stands unchanged in kind — only its *object* changed. Flagged
here so PM can carry the re-touch into `07_DELIVERY.md`.

### Round 2 — design drift

**None.** No design decision was made or altered; all three fixes are mechanical, and the one judgement
call (declining the optional `verify_all.sh:354` change) is a *refusal* to deviate, evidenced above.

---

## Verdict

**READY FOR REVIEW** *(round 2 — three code-review MINORs discharged, one NIT taken, one NIT declined
with reason; 0 pins moved, `verify_all` 32/0/0)*
