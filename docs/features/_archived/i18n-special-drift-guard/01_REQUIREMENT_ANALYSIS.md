# 01 — Requirement Analysis · T-016 / i18n-special-drift-guard

> Stage 1 of the Harness pipeline. Mode: **full** (7-stage). Author: Requirement Analyst.
> Inputs (read-only): PM dispatch prompt + `PM_LOG.md` (no separate `INPUT.md` exists; PM provided the
> task in the dispatch). Upstream context: T-015 `02_SOLUTION_DESIGN.md` §2.2 + §10 R-2 (the accepted-drift
> risk this task closes), `templates/common/` ↔ `templates/i18n/zh/common/` SPECIAL-file pairs,
> `.harness/scripts/verify_all.{ps1,sh}` (E.1 byte-identity idiom + G.4 count gate), and T-014
> `language-policy.{ps1,sh}` (the heading-anchor section/line locators).
> All file:line citations are against the harness-kit repo at this commit. This document specifies WHAT must
> be true and HOW each requirement is verified; it does **not** choose between GUARD and ELIMINATE — that is
> the Solution Architect's call (§8 Open Questions OQ-1).

---

## 1. Goal

Make the English framework BODY that the 3 i18n/zh SPECIAL template files duplicate from `templates/common/`
incapable of silently drifting out of sync, so a generated `{{LANG}}=zh` project can never ship a stale
framework rule body.

---

## 2. Background (read-only, for traceability — not a requirement)

T-015 (`docs/features/_archived/zh-overlay-anglicize/`) anglicized the AI-facing zh overlay and, by design,
**kept 3 SPECIAL files** in `skills/harness-init/templates/i18n/zh/common/` because T-014 `/harness-language`
reads its canonical zh policy text from them at run time (deleting them breaks `/harness-language zh` —
`language-policy.sh:77-90`). Those 3 files carry an English framework body **duplicated** from
`templates/common/`, with one per-language policy region each:

| # | i18n/zh SPECIAL file | common/ counterpart | Duplicated (body) | Differs (policy region) |
|---|---|---|---|---|
| F-2 | `i18n/zh/common/.harness/rules/00-core.md.tmpl` | `common/.harness/rules/00-core.md.tmpl` | header (lines 1-7) + body after policy (`## How this project is developed` through `## When in doubt`) | the policy **section**: zh `## 输出语言（按消费者分流）` block (zh lines 9-31) vs en `## Output language (project-wide)` block (en lines 9-22) |
| F-7 | `i18n/zh/common/CLAUDE.md.tmpl` | `common/CLAUDE.md.tmpl` | every line except line 3 (title, ruleset-pointer, 4 red lines, static-stub closer) | the policy **line**: zh line 3 `输出语言：…` vs en line 3 `Output language: **English**.` |
| F-8 | `i18n/zh/common/.github/copilot-instructions.md.tmpl` | `common/.github/copilot-instructions.md.tmpl` | every line except line 6 (frontmatter, title, ruleset-pointer, 4 red lines, static-stub closer) | the policy **line**: zh line 6 `输出语言：…` vs en line 6 `Output language: **English**.` |

**Verified this session:** the non-policy bodies of all 3 SPECIAL files are byte-identical to their `common/`
counterparts **today** — the duplication is currently in sync. T-015 §10 R-2 logged the future-drift risk as
"Accepted, bounded" and §10 R-2 explicitly named "full byte-equality of the SPECIAL non-policy body" as
**out of scope for T-015 — a future task**. This is that task.

T-015 §2.1 / §2.2 (read-only) establishes a hard constraint this task inherits: **the 3 SPECIAL files must
remain on disk** in `templates/i18n/zh/common/` because `language-policy.{ps1,sh}` reads them as its canonical
zh-policy source (`language-policy.sh:77-90`, `language-policy.ps1:74-78`). Any solution that removes them is a
T-014 regression.

---

## 3. In-scope behaviors (numbered, testable)

The requirement is stated **mechanism-neutrally** (GUARD or ELIMINATE — OQ-1). Each behavior is something a
tester verifies on the resulting tree.

1. **B-1 Drift is detected, not silent.** After this task, an edit to any `common/` SPECIAL counterpart's
   non-policy body that is NOT mirrored into the corresponding `i18n/zh` SPECIAL file (F-2/F-7/F-8)
   **causes `.harness/scripts/verify_all` to FAIL** (exit ≥ 2) with a message that names the diverged file
   and the divergence. (Mechanism-neutral: GUARD detects via a new check; ELIMINATE makes drift structurally
   impossible by removing the duplicate — in which case "drift detected" is satisfied vacuously because there
   is nothing to drift, and a test must instead prove the body single-sources correctly.)

2. **B-2 The policy region is EXCLUDED from the equality contract.** The intentional en-vs-zh difference in the
   policy region — the F-2 policy **section** (en heading `## Output language (project-wide)` vs zh heading
   `## 输出语言（按消费者分流）`) and the F-7/F-8 policy **line** (en `Output language: **English**.` vs zh
   `输出语言：…`) — does **not** cause a FAIL. The contract is over each file MINUS its policy region only.
   (This is the central correctness requirement: a guard that compares whole files FALSE-FAILs immediately,
   because the policy IS intentionally different.)

3. **B-3 The current tree passes.** On the repo as it stands today (bodies in sync), the resulting
   `verify_all` is GREEN for the new behavior (no FAIL, no new WARN attributable to this task).

4. **B-4 The 3 SPECIAL files remain on disk** in `skills/harness-init/templates/i18n/zh/common/` so
   `/harness-language zh` (`language-policy.{ps1,sh}`) keeps resolving its canonical zh-policy source. A
   `/harness-language zh --dry-run` against a project still extracts the zh policy section/line from these
   files after the change.

5. **B-5 Cross-shell symmetry.** Any new verification logic is implemented in BOTH `verify_all.ps1` and
   `verify_all.sh` (or, for ELIMINATE, in both `test-init.ps1` and `test-init.sh` / the relevant pair), and
   produces the same PASS/FAIL verdict in each shell on the same tree.

6. **B-6 The drift-detection is mutation-proven.** A regression in the test suite (`test-verify-*` /
   `test-init` / a new test pair) demonstrates that the mechanism goes RED when a real body line diverges and
   GREEN when it does not — i.e. the assertion is non-vacuous (T-015 vacuous-fixture lesson; PM_LOG insight).

7. **B-7 The `{{LANG}}=en` init path is byte-unchanged.** No `common/` SPECIAL file is modified in a way that
   changes what an English project generates. (GUARD: read-only, touches no template. ELIMINATE: must prove
   the en render is byte-identical before/after.)

8. **B-8 Version + count fan-out is consistent if (and only if) the check count changes.** If the chosen
   mechanism adds a lettered `verify_all` check, the live check count moves 32 → 33 and every doc claim that
   states the count moves in lockstep (G.4 derives the count from the live tally; the prose/JSON/badge sites
   listed in §6 must agree), and the plugin version bumps 0.26.0 → 0.27.0 (G.3/G.4 green). If the chosen
   mechanism adds NO lettered check (e.g. ELIMINATE verified only via existing `test-init`), the count stays
   32 and only a version bump applies. The shipped tree's `verify_all` is internally consistent either way.

9. **B-9 No I.6 retired-claim self-trip.** No file scanned by `verify_all` I.6 (everything `git ls-files`
   except the I.6 exempt set) gains a line that trips a banned-anchor entry. In particular the preserved zh
   policy text (already-green T-013 text using `按消费者分流` / `对话回复仍用中文`) is carried verbatim, and
   no new file (SKILL.md, READMEs, AI-GUIDE, test code, the new check's message strings) introduces a banned
   anchor sequence. Any UTF-8 zh text the mechanism compares is read/written as UTF-8 (no BOM).

10. **B-10 `verify_all` ends 32/32 (or 33/33 if a check was added) PASS in both shells** after the change,
    with no new FAIL and no new WARN attributable to this task. (This is the standing declare-done gate.)

---

## 4. Out-of-scope (explicitly NOT done this iteration)

- **O-1 Anglicizing the policy PROSE.** The Chinese T-013 policy section/line stays verbatim. This task does
  not touch the *content* of the policy region — only the equality contract over the *non-policy body*.
- **O-2 Adding new language overlays** (beyond zh) or a per-init language toggle.
- **O-3 Migrating already-generated zh projects.** Projects initialized before this change are not rewritten;
  `/harness-upgrade` / `/harness-language` are the existing surfaces for that.
- **O-4 Touching the harness-kit dogfood repo's own English `AI-GUIDE.md` / `00-core.md` / `CLAUDE.md` /
  `.github/copilot-instructions.md`.** Those are red-line files (hand-edit prohibited).
- **O-5 Restructuring the 11 already-anglicized (deleted) overlay files** from T-015. This task concerns only
  the 3 SPECIAL files.
- **O-6 Extending the equality contract to files other than the 3 SPECIAL pairs.** The drift surface is
  exactly F-2/F-7/F-8 ↔ their `common/` counterparts.
- **O-7 Backend/generic `test-init` fixtures** or any new fixture topology beyond what the chosen mechanism
  minimally requires to be mutation-proven (B-6).
- **O-8 Changing E.1** (the existing template↔dogfood byte-identity check) or any other existing check's
  scope. A GUARD mechanism ADDS a check; it does not repurpose E.1.

---

## 5. Boundary conditions

- **C-1 Policy region absent / malformed.** If a SPECIAL file (or its `common/` counterpart) is missing the
  expected policy heading/line anchor, the mechanism must FAIL with a clear message (not silently pass, not
  crash). The locator is the heading anchor (`## Output language (project-wide)` / `## 输出语言（按消费者分流）`)
  for F-2 and the line anchor (`^Output language:` / `^输出语言：`) for F-7/F-8, identical to the T-014
  locators — see OQ-2.
- **C-2 A SPECIAL file is missing.** If F-2/F-7/F-8 or its `common/` counterpart does not exist on disk, the
  mechanism FAILs with the missing path named (a missing file is itself drift / a regression of B-4).
- **C-3 Trailing-whitespace / CRLF / trailing-newline noise.** The body-equality comparison must be robust to
  the cross-shell line-ending and trailing-newline hazards documented in insights (T-012 DEFECT-1, T-014):
  the bash and PowerShell implementations must reach the SAME verdict on the SAME tree (B-5). Specify whether
  comparison is byte-exact-after-CR-strip or line-list equality (OQ-3).
- **C-4 Empty body after policy removal.** F-7/F-8's only difference is one line; after excluding the policy
  line, the remaining body is non-empty (13/16 lines). F-2's body after excluding the policy section is
  non-empty (header + dev/hard-rules/style/locations/when-in-doubt). An empty-after-exclusion result indicates
  a locator error and must FAIL (C-1).
- **C-5 Placeholder tokens in the body.** Both bodies contain `{{PROJECT_NAME}}` / `{{PROJECT_TYPE}}` /
  `{{STACK}}` / `{{TODAY}}` in the header (kept English in both files), so a body-equality comparison over the
  raw `.tmpl` text includes those tokens identically on both sides — no placeholder substitution is required
  before comparing, and no new placeholder is introduced (D.2 unchanged).
- **C-6 Concurrency.** None — `verify_all` is a single-process read-only scan; no concurrency surface.
- **C-7 The policy region's own boundary (the seam).** For F-2 the policy section is delimited
  `[policy heading, next "## ")`; the body after it begins at `## How this project is developed`. The
  exclusion must cut exactly at that seam so the body comparison neither includes any policy line nor drops a
  body line (off-by-one at the seam = false PASS or false FAIL). The trailing blank line before
  `## How this project is developed` belongs to the policy section per the T-014 inclusive-span convention.

---

## 6. Acceptance criteria (each verifiable)

> ACs are written for the **default GUARD** mechanism (PM lean) because they must be concrete. If the SA
> selects ELIMINATE (OQ-1), AC-1/AC-3/AC-6 re-map per §9; AC-2/AC-4/AC-5/AC-7 hold for either mechanism.

- **AC-1 (drift goes RED — mutation-provable).** With the mechanism in place, change ONE non-policy body line
  in `common/.harness/rules/00-core.md.tmpl` (e.g. a word in `## Hard rules (red lines)`) WITHOUT mirroring it
  into `i18n/zh/.../00-core.md.tmpl`; run `verify_all` → the new check FAILs (exit ≥ 2) and the FAIL message
  names `00-core.md.tmpl` as the diverged file. Revert → PASS. (Repeat for F-7 and F-8: change a non-policy
  body line in `common/CLAUDE.md.tmpl` / `common/.github/copilot-instructions.md.tmpl` → FAIL.)
- **AC-2 (current tree PASSes).** On the unmodified repo (bodies in sync today), `verify_all` reports the new
  behavior PASS in BOTH shells.
- **AC-3 (policy region is correctly EXCLUDED — no false FAIL).** The mechanism does NOT FAIL on the current
  tree even though the F-2 policy section (`## Output language (project-wide)` vs `## 输出语言（按消费者分流）`)
  and the F-7/F-8 policy line (`Output language: **English**.` vs `输出语言：…`) differ en-vs-zh.
  Mutation-provable: change ONLY a word INSIDE the zh policy region (not the body) → the check still PASSes
  (the policy region is excluded), distinguishing it from a whole-file comparison.
- **AC-4 (cross-shell symmetry).** `verify_all.ps1` and `verify_all.sh` produce the identical PASS/FAIL
  verdict for the new behavior on the current tree AND on the AC-1 mutated tree.
- **AC-5 (mutation-tested in a regression).** A regression (a `test-verify-*` pair, or an extension to an
  existing test pair) automatically exercises AC-1 + AC-3: it mutates a real body line, asserts the mechanism
  goes RED, restores, and asserts GREEN — so the guard's effectiveness is itself under test (not just a
  one-time manual check). The regression is symmetric (PS + bash).
- **AC-6 (`/harness-language zh` still works).** After the change, `language-policy.{ps1,sh}` still resolves
  its canonical zh-policy source from the 3 SPECIAL files: a `/harness-language zh --dry-run` (or the
  `test-language` regression) extracts the zh policy section/line without error (exit 0). (B-4.)
- **AC-7 (`{{LANG}}=en` render byte-unchanged).** The English init path produces byte-identical output before
  and after this task (no `common/` SPECIAL file content change; `test-init` en/default fixture assertions
  unchanged in meaning).
- **AC-8 (count + version fan-out consistent).** If a lettered check was added: `verify_all` live count is
  33, plugin.json/marketplace.json = 0.27.0, both README version badges = 0.27.0, and EVERY count-claim site
  in §6.1 reads 33; G.3 and G.4 are GREEN. If no lettered check was added: count stays 32, version bumps
  0.26.0 → 0.27.0, G.3/G.4 GREEN. (B-8.)
- **AC-9 (no I.6 self-trip; gate fully green).** `verify_all` is 33/33 (or 32/32) PASS in BOTH shells with no
  new WARN/FAIL attributable to this task; I.6 PASSes (no banned-anchor line introduced). (B-9, B-10.)
- **AC-10 (baseline reconciled from a captured run).** If the regression (AC-5) adds assertions to a test
  whose count is recorded in `.harness/scripts/baseline.json` (e.g. `test_init_*` or a new
  `test_verify_*` key), the new totals are pasted from an ACTUAL captured run in both shells — never
  hand-estimated (insight 2026-06-04 / T-007 / L27). README test-init badge tracks the captured PS total if it
  changes.

### 6.1 Count-claim fan-out sites (the G.4-gated set + neighbours) — for AC-8 if the count changes

A NEW lettered check moves the live count 32 → 33. G.4 derives the count from the live `report[]` tally and
gates these claim sites; each must read 33 (and version 0.27.0 where a version token is co-located). **L36
same-file uniqueness** applies (two rows can target the same file — each row's expected substring must be
unique in that file, per insight 2026-06-06 / T-010 D-1):

| Site (file) | Current claim | New (if +1 check) | Gated by |
|---|---|---|---|
| `AI-GUIDE.md:36` | `green (32/32; …)` | `33/33` | G.4 row `[0-9]+/[0-9]+` |
| `AI-GUIDE.md:69` | `total verification (32 checks, …)` | `33 checks` | G.4 row `[0-9]+ checks` |
| `docs/dev-map.md:65` | `Total verification (32 checks)` | `(33 checks)` | G.4 row `\([0-9]+ checks\)` |
| `docs/dev-map.md:145` | `runs all 32 checks` | `runs all 33 checks` | G.4 row `runs all [0-9]+ checks` |
| `.harness/rules/40-locations.md:25` | `verify_all checks (32 checks, …)` | `(33 checks` | G.4 row `\([0-9]+ checks` |
| `README.md:5` (badge) | `verify__all-32%2F32` | `verify__all-33%2F33` | G.4 README badge row |
| `README.zh-CN.md:5` (badge) | `verify__all-32%2F32` | `verify__all-33%2F33` | G.4 README badge row |
| `README.md:5` (text) | `(32 checks)` | `(33 checks)` | G.4 `\([0-9]+ checks\)` |
| `README.zh-CN.md:5` (text) | `（32 项检查）` | `（33 项检查）` | G.4 `（[0-9]+ 项检查）` |
| `docs/manual-e2e-test.md` | `32 checks` | `33 checks` | G.4 `[0-9]+ checks` |
| `.harness/scripts/baseline.json:10` | `"verify_all_checks": 32` | `33` | G.4 `"verify_all_checks": [0-9]+` |
| `CHANGELOG.md` | (n/a) | new `[0.27.0]` heading | G.4 CHANGELOG-heading check |
| `.claude-plugin/plugin.json:4` + `marketplace.json:17` | `0.26.0` | `0.27.0` | G.3 |
| `README.md:5` + `README.zh-CN.md:5` (version badge) | `version-0.26.0` | `version-0.27.0` | G.3 |

> NOTE: G.4 also self-checks that it remains the LAST recorded check (`verify_all.sh:769-773` tripwire;
> `report[]` count derivation). Any new lettered check MUST be inserted ABOVE the G.4 block, never below.

---

## 7. Non-functional requirements (only where material)

- **NFR-1 Cross-shell parity (load-bearing).** The mechanism is symmetric PS + bash and reaches the identical
  verdict on the same tree. Cross-shell byte-comparison hazards (CRLF, trailing newline, UTF-8 CJK) are
  the recurring defect class here (T-012 DEFECT-1, T-014, T-004 MSYS `grep -F -i` SIGABRT) — the
  implementation must avoid `grep -F -i` on bash, use `arr=()` not `declare -a` under `set -u` (L13), and use
  case/UTF-8-safe matching for any zh anchor (I.6-style `grep -E -i` + PS `[regex]` IgnoreCase over UTF-16).
- **NFR-2 No new runtime dependency.** `verify_all` must keep running on the Git-for-Windows MSYS shell with
  no `python3` / `jq` dependency (the existing constraint). The mechanism uses only bash builtins + awk/sed +
  PowerShell builtins, matching the T-014 locator implementation it reuses.
- **NFR-3 Read-only at the gate.** A GUARD mechanism must not mutate any tracked file when run (it is a
  verification, like E.1). (ELIMINATE's init change is exempt — it changes generation, not verification.)
- **NFR-4 Doc-size budget.** Any new check + message stays within the existing verify_all size; no rule
  fragment or doc crosses an I.* WARN cap as a side effect.

---

## 8. Related tasks (linked, not re-described)

- **T-015 / zh-overlay-anglicize** — `docs/features/_archived/zh-overlay-anglicize/02_SOLUTION_DESIGN.md`
  §2.1/§2.2 (the 3 SPECIAL files are dual-purpose; the duplicated body is "small and partially test-guarded")
  and §10 R-2 (the **accepted-drift risk this task closes**; "full byte-equality of the SPECIAL non-policy
  body" named out-of-scope-for-now). `docs/tasks.md` row T-015.
- **T-014 / harness-language-skill** — `language-policy.{ps1,sh}` provides the heading-anchor section locator
  (`extract_section_to`, `language-policy.sh:120-134`) and the policy-line locator (`extract_line_to`,
  `language-policy.sh:137-143`) the GUARD can reuse to exclude the policy region. `docs/tasks.md` row T-014.
  The constraint "the SPECIAL files are this helper's canonical source — do not delete" originates here
  (insight 2026-06-09, `.harness/insight-index.md:39`).
- **T-008 / test-supervisor-stamps** — added verify_all **G.4** (count↔version gate) and the insight that a
  new check is version-worthy (`.harness/insight-index.md:29`). Governs B-8 / AC-8.
- **T-010 / g4-version-decouple** — same-file claim-uniqueness trap (L36, `.harness/insight-index.md:31`).
  Governs the §6.1 fan-out uniqueness requirement.
- **E.1 (existing check)** — `verify_all.sh:193-198` (template↔dogfood byte-identity via
  `sync-self --check`) is the **idiomatic precedent** the GUARD mirrors: "make the bad (drift) state FAIL the
  gate." The new check is to F-2/F-7/F-8 what E.1 is to the whole template↔dogfood mirror.
- **T-004 / i6-semantic-guard** + **T-013 / lang-policy-split** — the I.6 retired-claim guard + self-trip
  lesson (`.harness/insight-index.md:22,23,36`). Governs B-9 / AC-9.

---

## 9. Open questions for user/PM (numbered, with defaults)

> Per the agent contract, genuine forks are escalated with a default. **OQ-1 is the one true fork** (it
> selects the mechanism the SA will design). OQ-2/OQ-3 are scoping refinements with low-risk defaults. None
> blocks the SA from starting — each has a default that lets stage 2 proceed; they are surfaced so the SA
> records the choice explicitly rather than guessing silently.

1. **OQ-1 — GUARD vs ELIMINATE (the mechanism fork).** How is "the body can never silently drift" achieved?
   - **(a) GUARD (PM lean — DEFAULT).** Add a new read-only lettered `verify_all` check (sibling of E.1) that,
     for each of F-2/F-7/F-8, compares the `i18n/zh` SPECIAL file MINUS its policy region against the
     `common/` counterpart MINUS its policy region, and FAILs on any divergence. Read-only; does not touch
     init; count 32 → 33; version 0.26.0 → 0.27.0. Reuses the T-014 heading/line locators.
   - **(b) ELIMINATE.** Restructure so the English body is single-sourced — e.g. init COMPOSES F-2's body from
     `common/00-core.md.tmpl` + an injected zh-policy snippet — removing the body duplication from the SPECIAL
     files. Larger change to init + `/harness-language` + `test-init`; must NOT delete the SPECIAL files
     (T-014 reads them — §2). The SA evaluates feasibility/risk and may recommend (a) or (b).
   - **Default: (a) GUARD.** Rationale (per PM lean): idiomatic to E.1, read-only (no init-flow risk), low
     cost vs the marginal benefit of removing ~50 already-in-sync lines. The SA confirms or refutes.

2. **OQ-2 — Policy-region exclusion: reuse T-014's anchors, or hard-code the line spans?**
   - **(a) Reuse the T-014 heading/line anchors (DEFAULT)** — locate the F-2 policy section as
     `[policy heading, next "## ")` and the F-7/F-8 policy line as the first `^Output language:` / `^输出语言：`
     line, identical to `language-policy`'s `extract_section_to` / `extract_line_to`. Robust to the policy
     text growing/shrinking; one anchor convention shared with T-014.
   - **(b) Hard-code the current line spans** (e.g. "exclude lines 9-22 in common, 9-31 in zh"). Simpler but
     brittle: any future policy-text edit silently shifts the spans and the guard either false-PASSes or
     false-FAILs.
   - **Default: (a) anchors.** Matches the central-correctness requirement (B-2) and reuses proven, cross-shell
     locators (NFR-1/NFR-2). The SA finalizes the exact anchor handling.

3. **OQ-3 — Body-comparison granularity for cross-shell parity (C-3).**
   - **(a) Line-list equality after per-line CR-strip (DEFAULT)** — read both bodies, strip trailing `\r` per
     line, compare the resulting line sequences; verdict identical in PS and bash (mirrors T-014's read-time
     CR-strip).
   - **(b) Byte-exact comparison of the reconstructed body** — stricter, but exposes the trailing-newline
     cross-shell hazard (T-012 DEFECT-1) and would need its own parity proof.
   - **Default: (a) line-list after CR-strip.** Lowest cross-shell risk for a comparison that only needs to
     catch real body-content drift. The SA specifies the exact comparison in stage 2.

---

## 10. Verdict

**READY.**

The requirement is fully specified and code-grounded: the drift surface is exactly the 3 SPECIAL ↔ `common/`
pairs (F-2/F-7/F-8), the policy-region boundaries are confirmed verbatim (the central exclude-the-policy-region
correctness point, B-2/AC-3), the bodies are verified in-sync today (so AC-2 is satisfiable), and the
count/version fan-out is pinned to the G.4-gated site list (§6.1). The three Open Questions are scoping forks,
not blockers — each carries a default (OQ-1 = GUARD per PM lean; OQ-2 = reuse T-014 anchors; OQ-3 = line-list
after CR-strip) that lets the Solution Architect begin stage 2 immediately and record the chosen mechanism
explicitly. The constraint that the SPECIAL files must NOT be deleted (T-014 reads them) is carried as a hard
boundary (B-4/AC-6). No upstream block.
