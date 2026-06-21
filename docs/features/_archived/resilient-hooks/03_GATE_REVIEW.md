# 03 — Gate Review · T-12 `resilient-hooks`

**Mode:** full · **Reviewer stage output** · **Upstream:** 01 verdict = READY, 02 verdict = READY
**Method:** two-axis (standards-conformance AND spec/design-fidelity), every code claim verified against LIVE files (not trusted from the design).

> Persisted by PM from the read-only gate-reviewer's return (gate-reviewer has no Write tool).

---

## 1. Audit checklist (8 dimensions)

| # | Dimension | Status | One-line reason |
|---|---|---|---|
| 1 | Requirement completeness | **PASS** | All 14 in-scope behaviors (A1-A9, B1-B5) and 14 ACs are concrete and testable; the fail-open/fail-closed split (A1 vs A5) is unambiguous and the SMTP-style "what if down" gap is closed by OQ-2a. |
| 2 | Design completeness | **WARN** | The four resilient strings + A8 transform + slice B are fully specified, BUT the 22-edit list **omits two real lockstep surfaces** (template-common copies of upgrade/migrate; test-init's `test_migrate` block) — see Findings F1, F2. |
| 3 | Reuse correctness | **PASS** | §7 reuse audit is accurate: the left-bounded ERE, the existence base, the presence-gate/`.bak` harness, the guard-rm substring recognition, and `settings.local.json` native precedence all exist and are reused unchanged; verified against the live ERE in both `verify_all.{sh,ps1}.tmpl`, `test-init.sh`, `upgrade-project.sh`, `migrate-scripts-layout.sh`. |
| 4 | Risk coverage | **PASS** | R1-R6 name the real risks; R1 (prefix-form blinds the scan) and R3 (JSON-escape byte-drift) are exactly the two failure classes the live ERE + the cross-shell-parity insights predict. One additional risk (F1) was missed by the design but is itself a coverage gap, not a wrong risk. |
| 5 | Migration safety | **PASS** | A8 is idempotent (sentinel-gated on `CLAUDE_PROJECT_DIR`), writes a timestamped `.bak`, never re-serializes (DO-3), and is gated on `target_present` so it never creates a resilient-but-dangling command; slice B is git-revertible with permissions retained throughout. No DB migration. |
| 6 | Boundary handling | **PASS** | Null/empty `$CLAUDE_PROJECT_DIR` (OQ-2a), spaces in path (`-LiteralPath` / quoted `cd`), missing script (fail-open vs fail-closed), absent settings.json (A8 skip preserved), idempotence, cross-shell byte parity — all designed. The degenerate-var path was hand-traced and is sound. |
| 7 | Test feasibility | **PASS** | Every AC maps to an existing or adjustable assertion; AC-1/AC-2/AC-5 are runnable mutations; the OQ-3a central claim is verifiable by the existing E.4b mutation probe. One semantic-weakening caveat on the P-fixture `eval` (Finding F4, non-blocking). |
| 8 | Out-of-scope clarity | **PASS** | §3 + §11 draw crisp boundaries (no plugin-hooks conversion, no script-body change, no new check/placeholder, no OS-detect change); the developer cannot accidentally over-build. |

---

## 2. Findings (each tied to an upstream section + responsible doc)

### F1 — BLOCKING — Design omits the `templates/common/` copies of `upgrade-project` and `migrate-scripts-layout` (responsible: 02 §2 affected-modules table + §8 Surface 5)

`sync-self.sh` mappings 6 and 7 (lines 78-84) enforce that `.harness/scripts/upgrade-project.{ps1,sh}` and `.harness/scripts/migrate-scripts-layout.{ps1,sh}` are **byte-identical** (`cmp -s`) to `skills/harness-init/templates/common/.harness/scripts/<same>`. `verify_all.sh` **E.1** (line 194) runs `sync-self.sh --check` and FAILs on any drift.

The design's affected-modules table lists only the repo copies (rows 4-7). If the Developer edits only those four files with the S3.0 resilient `ph_cmd` + new S3.2 transform, `sync-self --check` reports drift → **E.1 FAILs → verify_all never reaches 32/32 → AC-13 gate fails.** The real lockstep is **8 files** (4 repo + 4 template-common), OR the Dev must run `sync-self` (non-check) to propagate after editing the template-common source. This is the canonical "edit `templates/common/` then run `sync-self`" rule (AI-GUIDE.md line 110) and is exactly the four-file-lockstep discipline recorded in insight `2026-06-08` (line 21) and the audit-siblings-as-a-pair insight `2026-06-11` (line 31). The 22-edit count undercounts by 4 here (or hides them behind an unstated `sync-self` run).

### F2 — BLOCKING — Design omits the `test_migrate` block in `test-init.sh`/`.ps1`, which hardcodes the OLD (brittle) migrate output (responsible: 02 §8 Surface 3 + Surface 5)

`test-init.sh` `test_migrate()` (lines 558-561) asserts the migrate output is the **bare brittle** form:
- `grep -qF 'pwsh -NoProfile -File .harness/scripts/harness-sync.ps1'` (Stop)
- `grep -qF 'pwsh -NoProfile -File .harness/scripts/guard-rm.ps1'` (PreToolUse)

The design adds the A8 brittle→resilient rewrite to **migrate** (§4.3: "in BOTH upgrade and migrate"). Once migrate rewrites to the resilient form, the Stop command becomes `pwsh -NoProfile -Command "Set-Location ... if (Test-Path ... ) { & pwsh -NoProfile -File .harness/scripts/harness-sync.ps1 }; exit 0"`. The PreToolUse `grep -qF 'pwsh -NoProfile -File .harness/scripts/guard-rm.ps1'` still matches as a substring (guard resilient form contains `& pwsh -NoProfile -File .harness/scripts/guard-rm.ps1`), so that one survives. But the **Stop assertion (line 558-559)** will still match too, because the resilient form embeds `-File .harness/scripts/harness-sync.ps1` as a substring — so these particular `grep -qF` assertions happen to survive by substring luck. HOWEVER, line 562-563 (`_doc_sync_hook` doc-string rewire, with the `sed 's|...harness-sync\.|XX|g'` negative) and the migrate `-NoProfile` count assertion (line 564-565, `>= 2`) interact with the new form in ways the design did not analyze, and the design's Surface 3 only mentions test-init's top-of-driver `*_COMMAND` literals — it does NOT mention the `test_migrate` block at all. **The Developer must be told `test-init.sh`/`.ps1` `test_migrate` is a third edit/verify surface inside test-init**, not only the `*_COMMAND` literals. Risk: silent under-test or a real failure if A8 changes the doc-string handling. Verify-and-adjust required; flag because it is an unenumerated surface.

### F3 — CONDITION — `t20_pick` must hold the JSON-ESCAPED resilient bytes for the Fixture P exact-match (responsible: 02 §8 Surface 4 + §3.5)

`test-harness-upgrade.sh` Fixture P line 384 asserts `contains "\"command\": \"$t20_pick\""` against the on-disk settings. The resilient bash string contains `\"` around `$CLAUDE_PROJECT_DIR`; the pwsh string contains `\"` around the `-Command` body. For this exact-match to hold, `t20_pick` (line 282-283) must be set to the **JSON-escaped** literal (with `\"`), AND `upgrade-project` must emit those exact bytes. The design's R3 covers byte-parity generally and §3.5 names the escaped literal as the single source, but §8 Surface 4 says only "`t20_pick` → the resilient OS-picked string" without explicitly stating it must be the JSON-escaped form. Make this explicit so the Dev does not store the un-escaped shell form (which would fail the exact `grep -qF`). Same applies to test-init's `AMBIENT_*_COMMAND` literals (lines 45-46, 51-52) used by the `grep -qF '"command": "<literal>"'` assertions (lines 293-296).

### F4 — WARN (non-blocking, note for Dev/QA) — Fixture P's `eval "$t20_pick"` exits 0 for the WRONG reason under the resilient form (responsible: 02 §8 Surface 4)

Line 388: `( cd "$p_fix" && eval "$t20_pick" )` then asserts exit 0. With the resilient bash form `sh -c 'cd "$CLAUDE_PROJECT_DIR" 2>/dev/null && ...'`, under the test harness `$CLAUDE_PROJECT_DIR` is **unset**, so `cd ""` fails → `|| exit 0` → exits 0 via the **fail-open** path, NOT because it ran the script. The assertion still passes, but it no longer proves "the wired command runs the script" (AC-9's intent). The design correctly flags that `p_target="${t20_pick##* }"` (line 386) breaks and must switch to ERE extraction, but it does NOT note this `eval` semantic degradation. QA should either set `CLAUDE_PROJECT_DIR="$p_fix"` before the `eval` to exercise the real run path, or downgrade the assertion's claimed meaning. Same caveat for Fixture H line 330.

### F5 — WARN (non-blocking) — `75-safety-hook.md` "What this is" / "Fully disable" become repo-inaccurate after slice B (responsible: 02 §2 NOT-touched list)

Line 5 states the guard "is a `PreToolUse` hook in `.claude/settings.json`"; lines 76-79 give the disable path as editing `.claude/settings.json`. After slice B, THIS repo's dogfood guard lives in `.claude/settings.local.json`. The rule is still correct for distributed user projects (A6 keeps user hooks in committed settings.json), so this is doc-staleness for the dogfood case only. Not in the affected-modules list. Non-blocking; flag for optional one-line note.

### F6 — INFO — minor edit-count omissions in the rollup (responsible: 02 §8 rollup)

The §5 `80-settings-schema.md` one-line note and the `75-safety-hook.md` staleness (F5) are real touch-points not in the "22" rollup. The true lockstep, after F1+F2, is materially higher than 22 (at minimum +4 template-common, +2 test_migrate awareness). The "22" figure should be treated as a floor, not the complete enumeration.

---

## 3. Load-bearing OQ-3a verification (hand-traced against live ERE, BOTH shells)

**CONFIRMED — the bare token is scanner-visible AND cwd-resolvable in both shells.**

- **bash** E.4b ERE (`verify_all.sh.tmpl` L207-210, identical in `test-init.sh` L287-290 and the upgrade/migrate scans): `grep -oE "(^|[\"' =])(\.harness/)?scripts/[A-Za-z0-9._-]+\.(ps1|sh)"` → `sed 's|^[\"' =]||'` → `[[ -f "$path" ]]`. The SA's Stop string `sh -c 'cd "$CLAUDE_PROJECT_DIR" 2>/dev/null && [ -f .harness/scripts/harness-sync.sh ] && exec bash .harness/scripts/harness-sync.sh || exit 0'` contains TWO space-preceded `.harness/scripts/harness-sync.sh` tokens (after `[ -f ` and after `exec bash `). Both are extracted, deduped by `sort -u`, and resolve cwd-relative from project root. The `||`/`&&` punctuation does NOT ride along — the char class `[A-Za-z0-9._-]` terminates at `.sh` before the trailing space. The `cd` anchor does NOT introduce a `$CLAUDE_PROJECT_DIR/`-prefixed token. **The SA's §3.2 rejection of the `$CLAUDE_PROJECT_DIR/`-prefix shape in favor of the `cd`/`Set-Location` shape is correct and is the right call.**

- **pwsh** E.4b regex (`verify_all.ps1.tmpl` L172): `[regex]::new('(^|["'' =])((\.harness/)?scripts/[A-Za-z0-9._-]+\.(ps1|sh))')`, extracting `Groups[2]` then `Test-Path $p`. The SA's pwsh Stop string has `.harness/scripts/harness-sync.ps1` after `-LiteralPath ` and after `-File ` — both space-preceded, both matched, both cwd-resolvable via `Test-Path`. Confirmed.

- **guard-rm** (both shells): `sh -c 'cd "$CLAUDE_PROJECT_DIR" 2>/dev/null && bash .harness/scripts/guard-rm.sh'` and the pwsh analogue both expose a space-preceded `.harness/scripts/guard-rm.<ext>` token; `harness-status` §3b's `references guard-rm.{ps1,sh}` substring check (SKILL §3b L76) and F.2's `grep -qE 'guard-rm\.(ps1|sh)'` (verify_all.sh L306) both still match. Confirmed.

- **Mutation probe** (`test-init.sh` L489-498): deleting the wired script still leaves the extractable token in the command, so the scan still reports it dangling — the anchor does NOT blind the scan. Confirmed.

**OQ-3a is true; the 6 E.4b/D.4b tmpls are genuinely 0-edit verify-only as the design claims** (the central design payoff holds).

---

## 4. High-probability developer questions (pre-answered)

1. **"Do I edit the repo `upgrade-project.sh` or the `templates/common/` one?"** → BOTH must end byte-identical (sync-self mappings 6/7 + E.1). Edit `templates/common/.harness/scripts/{upgrade-project,migrate-scripts-layout}.{ps1,sh}` as the source, then run `.harness/scripts/sync-self` to propagate to the repo copies. This is Finding F1; do not skip it or E.1 FAILs.
2. **"Will the existing S3.1 prefix `sed` corrupt the resilient form's `.harness/scripts/...` token?"** → No. `sed 's|scripts/<tool>.<ext>|.harness/scripts/<tool>.<ext>|g'` matches the embedded substring → produces `.harness/.harness/scripts/...` → the unconditional collapse `sed 's|.harness/.harness/scripts/|.harness/scripts/|g'` (upgrade L260, migrate L134) restores it. The resilient form is a fixed point. Verified.
3. **"What exact bytes go in `t20_pick` / the `*_COMMAND` test literals?"** → The JSON-escaped resilient string (inner `"` as `\"`), character-for-character equal to what lands in settings after substitution (Finding F3 / design §3.5). The `grep -qF '"command": "<literal>"'` assertions are exact.
4. **"Does moving dogfood hooks to settings.local.json break F.2?"** → Yes unless F.2 is updated. F.2 (verify_all.sh L299-308) reads `.claude/settings.json` for PreToolUse + Bash matcher + guard-rm. After B2 the committed file has empty hooks. Add the settings.local.json fallback (design R5/§8-[5]) in BOTH shells. The template `{{GUARD_COMMAND}}` + PreToolUse checks (L312-319) stay intact.
5. **"Is `.claude/settings.local.json` already gitignored by `*.local`?"** → No. `.gitignore` L37 `*.local` matches files literally ending `.local`, not `settings.local.json`. B3's explicit add is required and correct.

---

## 5. Two-axis summary

- **Standards-conformance:** PASS on the red lines — no hand-edit of `.claude/` runtime config beyond the legitimate dogfood settings move (which is the task), no new check (feedback_design_over_guards honored), no count flip (skills 17 / agents 8 / checks 32 all correctly unchanged — verified: 8 agent files incl. supervisor, D.1 checks 7 framework + supervisor is the documented 8th, no agent added), version 0.44.0 G.3 fan-out (plugin.json + marketplace.json + 2 README badges) + G.4 (`## [0.44.0]` heading) correctly enumerated and matches the live G.3/G.4 logic. Cross-shell parity discipline (T-012/T-021 insights) acknowledged.
- **Spec/design-fidelity:** The resilient strings satisfy every stated constraint (A1-A5, OQ-1a/2a/3a/4a) and OQ-3a holds on both shells as hand-verified. The two FIDELITY gaps are the **incomplete lockstep enumeration** (F1, F2): the design under-counts the synchronized surfaces, which would surface as a guaranteed E.1 gate failure (F1) and an unenumerated test surface (F2) at Dev time.

---

## 6. Verdict

**APPROVED WITH CONDITIONS.**

The design is architecturally sound, the load-bearing OQ-3a claim is verified true on both shells, and the fail-open/fail-closed safety split is correct. Development may proceed **provided the following conditions are met during implementation** (all are completeness gaps, not design errors):

- **C1 (blocking, from F1):** Treat `upgrade-project.{ps1,sh}` and `migrate-scripts-layout.{ps1,sh}` as an **8-file** lockstep — edit the `templates/common/.harness/scripts/` source copies and run `.harness/scripts/sync-self` so the repo copies stay byte-identical; confirm `verify_all` **E.1** PASSes. (Required or the gate cannot reach 32/32.)
- **C2 (blocking, from F2):** Update/verify the `test_migrate` block in `test-init.{sh,ps1}` (Stop/PreToolUse/`_doc_sync_hook`/`-NoProfile`-count assertions, lines ~558-565 in `.sh`) against the new A8-resilient migrate output — not only the top-of-driver `*_COMMAND` literals.
- **C3 (from F3):** Store the **JSON-escaped** resilient bytes in `t20_pick` and all `*_COMMAND` test literals so the exact `grep -qF '"command": "<literal>"'` assertions match.
- **C4 (from R5/design §8-[5]):** Add the `settings.local.json` fallback to F.2 in BOTH shells; confirm F.2 + J.1 PASS post-slice-B.
- **C5 (non-blocking, from F4/F5):** QA should exercise the real-run path in Fixtures P/H (set `CLAUDE_PROJECT_DIR` before `eval`) rather than rely on the fail-open exit 0; optionally refresh the `75-safety-hook.md` "What this is"/"Fully disable" wording for the dogfood relocation.
