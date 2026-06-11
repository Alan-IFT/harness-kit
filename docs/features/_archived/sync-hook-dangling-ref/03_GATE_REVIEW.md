# 03 — Gate Review: sync-hook-dangling-ref (T-020)

Mode: full · Reviewer: gate-reviewer · Date: 2026-06-11
Upstream: `01_REQUIREMENT_ANALYSIS.md` (READY) · `02_SOLUTION_DESIGN.md` (READY)

## 1. Audit checklist (8 dimensions)

| # | Dimension | Verdict | Reason |
|---|---|---|---|
| 1 | Requirement completeness | PASS | RC-1..RC-7 each carry verified file:line evidence (I re-checked every citation; all land within ±2 lines); FR-P/D/R are testable; B1–B12 enumerated. |
| 2 | Design completeness | WARN | Every confirmed RC (1,2,3,4) traces to a concrete change (gated rewire + move-verify + exit 4; init 10b; adopt substitution table + 4-event merge + terminal assert; S2 cp-verify + GAP + gated S3 + exit 4) — but B7's repair half is not delivered (Finding F-3) and the exit-4 SKILL row under-specifies co-occurrence with exit 2/3 (F-2). |
| 3 | Reuse correctness | PASS | Reuse table independently confirmed: `upgrade-project.sh` S2 at :136-159, S3 at :161-182; guard-rm tri-state at `harness-status/SKILL.md:61-77`; assembled-brace technique at `upgrade-project.sh:265-279`; sync-self mappings 6–7 at `sync-self.sh:78-84`; dogfood E.4b precedent at `verify_all.sh:232`. No existing hook-congruence checker was missed. |
| 4 | Risk coverage | WARN | R1/R2/R3/R5–R8 are real and correctly mitigated, but R4's "anything unmatchable is ignored" is hand-reasoning and wrong on substring over-matching (F-1); insight 2026-05-23 requires an actual matcher run, not per-family reasoning. |
| 5 | Migration safety | PASS | No data migrations; settings edits stay raw-text with timestamped `.bak`; exit codes are additive (0/1/2/3 semantics unchanged, healthy runs still exit 0); I independently traced the gated-rewire fixed point — B10 holds in both gate states (gate-on → double-prefix → collapse → identity; gate-off → no-op); rollback = git revert / existing `.bak` contract; dogfood `.claude/settings.json` untouched (NFR-6 not triggered). |
| 6 | Boundary handling | PASS | B1–B12 each addressed; line-scoping claim (c) verified against the real `settings.json.tmpl`: `_doc_sync_hook` (:4), `_ambient_hook` (:6), and `permissions.allow` (:29) contain no quoted `"command"` token; `"type": "command"` lines (:42,:53,:63,:73) match the grep but carry no path token. B7 is the one partial (F-3). |
| 7 | Test feasibility | PASS | AC-1..AC-8 map to drivers that all exist (`test-harness-upgrade.{sh,ps1}`, `test-init.{sh,ps1}`, `test-real-project.{sh,ps1}` — globbed); cited driver line refs verified (test-init.sh:41-62, test-init.ps1:112/521/632, test-real-project.sh:41-54); WARN status is supported by both type-template step harnesses (sh `step()` WARN branch :17; ps1 `Step` `$false` → WARN :35-38), so the E.3→WARN reclassification is implementable without framework surgery. |
| 8 | Out-of-scope clarity | PASS | §12 is explicit; every §3 footprint row traces to an FR/RC/OQ; the ambient OS-pick (only candidate for creep) traces to OQ-3 with logged same-class rationale. No untraceable work found. |

## 2. Independent verification results (claims I checked against sources)

All confirmed accurate unless noted:

- **RC-1**: `migrate-scripts-layout.sh:21` (`set -uo`, no `-e`), `:64` (silent source-absent skip), `:76-81` (unchecked `git mv`/`mv`), `:94-97` (unconditional sed) — exact. PS twin `:92-101` matches.
- **RC-4**: `upgrade-project.sh:22`, `:145` (template-absent skip; design cites :144, off by one — harmless), `:157` (unchecked `cp`), `:166-169` (unconditional sed), `:74-77` (adopt routing). `upgrade-project.ps1:151-157` (`$refreshSet`), `:179-202` (S3) — exact.
- **RC-3**: `harness-adopt/SKILL.md:295-303` substitution table has only 5 placeholders, no `{{SYNC_COMMAND}}`; `:242-264` special-case is PreToolUse-only; `:234-240` apply loop has no terminal assertion — the spec gap is real.
- **RC-6**: all six type-template rows confirmed — generic `sh:66-70`/`ps1:104-110`, fullstack `sh:163-166`/`ps1:140-144`, backend `sh:178-181`/`ps1:162-166` FAIL a healthy v0.30 project; `harness-status/SKILL.md:24-25` stale rows confirmed; the 16-row table vs "All 15" at `:97` mismatch is real, so the design's post-deletion count of 14 is arithmetically correct.
- **G.4 gate (insight 2026-06-05)**: read the live G.4 block (`verify_all.sh:686-786`) — count expects are derived from the live count, and the only version-dependent assertion is the CHANGELOG `[<plugin.json version>]` heading. The design's "count stays 32 → only the `[0.31.0]` heading moves" is correct. No dogfood check is added/removed; D.2 whitelist entries (`verify_all.sh:84`, `verify_all.ps1:95` — exact) don't change the count; nothing is added after G.4.
- **I.6 lockstep (insight 2026-06-08)**: read the live banned list (`verify_all.sh:521-536`) — no agents-related anchors; neither the removals nor the new "plugin-provided since v0.30" wording can trip I.6; no four-file lockstep is triggered. Design claim correct.
- **Dual-purpose template check (insight 2026-06-09)**: grepped all readers of `settings.json.tmpl` — F.2 (`verify_all.sh:312-313`) wants `{{GUARD_COMMAND}}`+PreToolUse (untouched), J.1 (`sh:643`) validates structure (commands-only string change is safe), test drivers substitute it (design §10 covers the 2 new substitutions). No hidden consumer breaks.
- **Consumer count claims**: grepped templates for `N checks` claims — none exist, so adding E.4b/D.4b creates no consumer-side G.4-class staleness.
- **GAP record**: `harness-upgrade/SKILL.md:121` already documents the `GAP|` prefix — the design's `GAP|template-missing` reuses existing parser vocabulary as claimed.
- **Repair walk-through (user's scenario)**: traced against real S2/S3 code — settings already say `.harness/scripts/harness-sync.sh`, S2 lands both variants (`is_new` → `n_added`), S3 sed → double-prefix → collapse → identity → NOOP, scan passes, exit 0; re-run all-NOOP. FR-R1/R2 hold. Even an exit-2 co-occurrence doesn't undo the repair (S2/S3 complete before S5 halts).
- **Discrepancy (minor)**: RA RC-5 says harness-sync "unconditionally syncs skills (`:74-96`)" — actually guarded by `[[ -d "$harness_skills" ]]` at `harness-sync.sh:78`. Conclusion unaffected (every generated project ships `.harness/skills/`), no action needed.

## 3. Findings

**F-1 (WARN — design §4.1 + R4; architect points a & c).** The scan ERE `(\.harness/)?scripts/[A-Za-z0-9._-]+\.(ps1|sh)` is unanchored on the left, so it matches **inside longer dirnames**: a healthy user-customized hook `bash build-scripts/deploy.sh` (or any `*scripts/` dirname) yields the extracted token `scripts/deploy.sh`, which doesn't exist → `CONGRUENCE-FAIL`/exit 4 in the helpers and an E.4b FAIL in the consumer gate — a **false positive on exactly the customized-hook state the architect's own property (a) says "must not be flagged"**. R4 analyzed only the unmatchable direction. Per insight 2026-05-23, per-entry false-positive analysis must be backed by an actual matcher run; none was. Owner: 02 §4.1/R4.

**F-2 (WARN — design §6.2.3/§6.6; architect point d).** Exit-4-wins precedence is mechanically sound (the scan is the last `exit_code` writer; all CONFLICT/VERIFY-HALT records remain on stdout), but the SKILL's **exit table is the documented branch point** (`harness-upgrade/SKILL.md:136-143`): when 4 co-occurs with a would-be 2 (unmarked custom B.* → the offer-`--force` flow) or 3 (hook conflict relay), the drafted exit-4 row doesn't instruct the model to also execute those remediations, so the 2/3 *actions* (not the signals) can be masked. The row also doesn't state that exit 4 can occur on the dry-run leg (projected-state violation) and that plan presentation must still happen. Owner: 02 §6.6.

**F-3 (WARN — boundary B7 repair half not delivered).** 01 §5 B7 requires: "diagnosis flags as dangling/malformed; **repair rewires to the OS-picked command**." The design diagnoses MALFORMED (§6.7) and surfaces a congruence CONFLICT with a manual-restore instruction, but S3's prefix sed can never rewire a literal `{{SYNC_COMMAND}}` (no `scripts/harness-sync.` substring), and §6.2 adds no such path. OQ-5's "never rewrite a deliberate user choice" rationale does not apply — an unsubstituted placeholder is never a deliberate choice. Either implement the bounded literal-token rewrite in `upgrade-project` or explicitly amend B7 with logged rationale. Owner: 02 §6.2/§6.6 vs 01 §5 B7. No AC currently exercises B7's repair half, so QA would not catch the gap.

**F-4 (NOTE).** Per-variant gated rewire operates on the whole raw text: when only one variant's target is present, the `_doc_sync_hook` doc string ends half-migrated (one variant's mention at `.harness/scripts/`, the other still at `scripts/`). Cosmetic; the fixed point still holds. Acknowledge in the helper comment so Code Review/QA don't flag it as a defect.

**F-5 (NOTE).** Superstring **rewire** clobber (`our-scripts/harness-sync.sh` → `our-.harness/scripts/...`) is pre-existing in the current seds and is *narrowed*, not widened, by the gating. Recorded so it isn't mistaken for a regression. (Distinct from F-1, which is a *new* scan-side false positive.)

**F-6 (NOTE — adopt merge re-serializes).** `harness-adopt/SKILL.md:252-264` writes settings back via JSON parse + re-serialize in merge mode; design §6.5 extends that path to all four hook events, widening its use on user files. FR-R3's raw-text contract binds upgrade, not adopt, so no violation — but AC-6's integrity assertions only cover the helper writes (AC-1/AC-2). The adopt terminal assertion should also check JSON validity, canonical `$schema`, and `_*`-key survival after a merge-mode write (J.1-class, insight 2026-05-23 settings-schema family).

## 4. High-probability developer questions

1. **"How do I left-boundary the ERE without breaking the leading-dot `.harness/` match?"** — In settings command strings the path token is always preceded by a quote, space, or `=`; require that (or start-of-string) before `(\.harness/)?scripts/`. Then satisfy insight 2026-05-23: run the actual matcher over fixture settings that include a `build-scripts/deploy.sh`-style custom command and assert zero violations (this run is condition C1's evidence).
2. **"Does adding E.4b change consumer doc claims or exit semantics?"** — Pre-answered: no `N checks` claims exist anywhere in templates (grep-verified); E.4b FAIL exits via the existing template exit logic; row sits outside `HARNESS:B-CUSTOM`, so the S5 splice is untouched.
3. **"PS side of the scan — which string ops?"** — Pre-answered by design §6.1.4 + insights: `.Split("`n")` not `-split` (T-014), `[regex]` without IgnoreCase, `-cnotin`/`-ccontains` for the D.2 whitelist adds, and append `` "`n" `` on any PS-generated file compared for byte identity (T-012 DEFECT-1).
4. **"Does the D.2 whitelist add trigger the I.6 four-file lockstep or a test-verify-i6 count bump?"** — Pre-answered: no. D.2's whitelist is not the I.6 banned list; `test-verify-i6`'s `I6ExpectedEntryCount` is untouched. test-init's placeholder scan is blanket (`{{...}}`), not whitelist-mirrored — substituting the two new tokens in the drivers is sufficient.
5. **"Should upgrade rewrite a wired literal `{{SYNC_COMMAND}}`?"** — Unresolved (F-3): needs architect adjudication via condition C3; do not improvise either way.

## 5. Verdict

**GO-WITH-CONDITIONS.** The design is grounded — every load-bearing file:line claim survived independent verification, all four confirmed RCs are made unreachable by concrete mechanisms, the repair path provably fixes the user's reported state idempotently, and the G.4/I.6/parity/version-policy obligations are correctly accounted (v0.31.0 minor bump, count stays 32, `[0.31.0]` heading, plugin.json/marketplace.json/README badges). Conditions, to be verified by Code Review and QA:

- [ ] **C1 (F-1):** Left-boundary the §4.1 scan ERE in all five consumers (both helpers × 2 shells + E.4b/D.4b rows) so dirnames merely *ending* in `scripts/` cannot match; back the false-positive claim with an **actual matcher run** over fixture settings including a custom `*scripts/`-dirname command (paste the run output into 04/06 docs, per insight 2026-05-23).
- [ ] **C2 (F-2):** The `harness-upgrade/SKILL.md` exit-4 row must instruct processing of co-occurring `VERIFY-HALT` / `CONFLICT|verify_all` / `CONFLICT|hook` records (their exit-2/3 remediations still apply) and state that exit 4 can fire on the dry-run leg with plan presentation unchanged.
- [ ] **C3 (F-3):** Adjudicate B7's repair half explicitly: either `upgrade-project` rewrites a wired literal `{{SYNC_COMMAND}}`/`{{GUARD_COMMAND}}`/ambient token to the OS-picked command (bounded, not a user choice — OQ-5 untriggered), or 02 records the deviation and the B7 contract is amended; add the corresponding fixture either way.
- [ ] **C4 (F-6):** The adopt terminal congruence step also asserts, after any merge-mode settings write: JSON parses, `$schema` canonical, hook keys valid, `_*` doc keys preserved.

Findings F-4/F-5 (and the RA's harmless `:74-96`/`:78` mischaracterization) are notes, no action gates development.
