# Development Record — T-016 / i18n-special-drift-guard

> Stage 4. Developer (single-developer mode). Implements the APPROVED ELIMINATE design
> (`02_SOLUTION_DESIGN.md`) exactly. Direction: eliminate the i18n/zh English-body duplication
> at the root; NO new `verify_all` check (count stays 32).

## Summary

Eliminated the i18n/zh English-body duplication. The canonical Chinese output-language policy is
single-sourced into one new snippet (`i18n/zh/_policy/output-language.zh.md.tmpl`); `/harness-language`'s
zh branch is re-pointed to read from it; the 3 SPECIAL i18n/zh files (00-core/CLAUDE/copilot `.tmpl`) are
DELETED; and zh init/adopt/test-init now COMPOSE — lay the English `common/` files then inject the zh policy
via the existing `language-policy` helper. The composed zh tree is byte-for-byte the old overlaid tree
(proven by a pre-delete `cmp`). No new check — `verify_all` stays 32. Version 0.26.0 → 0.27.0.

## Files changed

- `skills/harness-init/templates/i18n/zh/_policy/output-language.zh.md.tmpl` — **NEW (M-1)**. Single-source
  snippet: region A = the zh policy SECTION (`## 输出语言（按消费者分流）`, copied verbatim from the deleted
  00-core), a non-emitted sentinel heading, region B = the zh policy LINE (`输出语言：…`, copied verbatim from
  the deleted CLAUDE). UTF-8 no-BOM, LF. CJK COPIED (never re-typed).
- `skills/harness-init/templates/common/.harness/scripts/language-policy.sh` — **edit (M-2)**. zh branch
  `tmpl_core`/`tmpl_claude` re-pointed to M-1; en branch reads `common/` inline (unchanged); header doc updated.
- `skills/harness-init/templates/common/.harness/scripts/language-policy.ps1` — **edit (M-3)**. PS mirror of M-2.
- `.harness/scripts/language-policy.sh` / `.ps1` — **edit (M-4/M-5, via `sync-self`)**. Dogfood mirror,
  byte-identical to the template (E.1 green).
- `skills/harness-init/templates/i18n/zh/common/.harness/rules/00-core.md.tmpl` — **DELETED (M-6)** (`git rm`).
- `skills/harness-init/templates/i18n/zh/common/CLAUDE.md.tmpl` — **DELETED (M-7)** (`git rm`).
- `skills/harness-init/templates/i18n/zh/common/.github/copilot-instructions.md.tmpl` — **DELETED (M-8)** (`git rm`).
- `skills/harness-init/SKILL.md` — **edit (M-9)**. Step 4.3 zh-overlay list rewritten (only the 2 human-facing
  files); NEW step 4.4 "Inject the output-language policy (zh only)"; anti-pattern note added.
- `skills/harness-adopt/SKILL.md` — **edit (M-10, F-4)**. "Language handling" prose: dropped `00-core.md.tmpl`
  from the translates list; added the injection instruction in adopt's idiom (mirrors init step 4.4).
- `.harness/scripts/test-init.sh` — **edit (M-11)**. `test_zh_overlay` re-modelled to COMPOSE (lay 2 human-facing
  zh files + run helper injection + drop `.bak-*`); NEW positive body-match assertion `[zh][T-016]`.
- `.harness/scripts/test-init.ps1` — **edit (M-12)**. PS mirror of M-11.
- `.claude-plugin/plugin.json` / `.claude-plugin/marketplace.json` — **edit (M-13/M-14)**. version 0.26.0 → 0.27.0.
- `README.md` / `README.zh-CN.md` — **edit (M-15/M-16)**. version badge only → 0.27.0 (verify_all/test-init/
  integration badges left byte-exact).
- `CHANGELOG.md` — **edit (M-17)**. NEW `## [0.27.0] - 2026-06-09` entry.
- `.harness/scripts/baseline.json` — **edit (M-18)**. `test_init_bash_no_python3_assertions` 236 → 237 (captured);
  `last_verify` → 2026-06-09. `test_init_ps_assertions` left at 274 (see Open issues — PS uncaptured).
- `docs/dev-map.md` — added the i18n/zh overlay subtree (`_policy/` snippet + 2 human-facing files) and updated
  the `language-policy` description (zh source = `_policy` snippet; drives zh-init composition).

## Step-3 pre-delete `cmp` proof (F-1 — the load-bearing backstop)

Built a throwaway English fixture (lay `common/` 00-core/CLAUDE/copilot, substituted), ran the **re-pointed**
`language-policy.sh --template-root <repo> --lang zh` against it, and `cmp`-ed the result against the OLD
i18n/zh SPECIAL files laid the old (overlay) way. Done BEFORE deleting the originals.

- Source-level extraction proof (M-1 vs originals, via the helper's own awk anchors):
  - Region A (section): M-1 = 1492 bytes / 24 lines == OLD 00-core = 1492 bytes / 24 lines → **BYTE-IDENTICAL ✓**
  - Region B (line):    M-1 = 235 bytes == OLD CLAUDE = 235 bytes → **BYTE-IDENTICAL ✓**
- Composed-output proof (re-pointed helper output vs old overlay, WHOLE FILE `cmp`):
  - `00-core.md`  → **BYTE-IDENTICAL ✓**
  - `CLAUDE.md`   → **BYTE-IDENTICAL ✓**
  - `copilot-instructions.md` → **BYTE-IDENTICAL ✓**
- M-1 encoding: no BOM (first bytes `3c 21 2d`), LF-only, `file` reports UTF-8. CJK re-Read after Write — no mojibake.

A drifted glyph would have failed the region-A/B `cmp` and the whole-file `cmp`. None did. M-1 is byte-correct;
deletion proceeded only after this proof.

## verify_all result

- Baseline (bash): **PASS 32 / WARN 0 / FAIL 0** (check count 32, version 0.26.0).
- After changes (bash): **PASS 32 / WARN 0 / FAIL 0** (check count **UNCHANGED at 32**, version 0.27.0,
  G.3 + G.4 + I.6 all PASS).
- Delta: **0 new failures, 0 new checks** (the anti-bloat outcome). +1 test-init assertion (the body-match proof).

### Captured test results (bash — see Open issues for the PS-execution gap)

- `sync-self --check` (bash) → **In sync** (E.1 byte-identity of the language-policy dogfood mirror).
- `test-language.sh` → **39 PASS / 0 FAIL** (re-point preserved `/harness-language` zh+en byte-output).
- `test-init.sh` (full) → **237 PASS / 0 FAIL** (236 baseline + 1 new body-match). All retained T-015 inverse
  assertions + the 4 T-013 zh assertions PASS on the COMPOSED fixture; the new `[zh][T-016]` body-match PASSES.
- `verify_all.sh` → **32 PASS / 0 WARN / 0 FAIL**.
- `/harness-language` live re-confirm (bash, fresh fixture): `--lang zh` resolves M-1 (zh section + line injected);
  `--lang en` round-trips back to English. Both work.

### Mutation proof of the new assertion (B-6)

Probed the `[zh][T-016]` body-match: unmutated composed body == `common/` body (PASS); mutating one body line
(`## Hard rules (red lines)` → `## Hard rules (MUTATED)`) → bodies DIFFER → assertion RED. **Non-vacuous /
mutation-provable.** The proof lives in the test suite, not as a `verify_all` check (no bloat).

### `全程` self-trip check (I.6)

`git diff` of every edited SCANNED file (SKILL.md ×2, test-init ×2, dev-map, helper templates, M-1) shows **no
`全程` in any added line**. The only `全程` occurrences are the pre-existing `"[zh] retired blunt 全程 phrasing is
absent"` assertion names (baseline-green; bare `全程` does not match the I.6 ordered-anchor pair). verify_all I.6
PASS confirms no self-trip. CHANGELOG is I.6-exempt and was also kept anchor-clean.

## Design drift (if any)

None. Implementation follows the design exactly. Two clarifications worth the reviewer's eye (not drift):

- **`<template-root>` is the REPO root**, i.e. the directory that CONTAINS `skills/harness-init/templates`
  (the helper itself appends `skills/harness-init/templates/...`). The design's step-4.4 prose said "the
  directory above `skills/harness-init/templates`" — I made this explicit in the SKILL.md/adopt wording and used
  `$repo_root` (not `$template_root`) in the test-init invocation. This matches `/harness-language`'s own usage.
- The PS body-match assertion uses the helper's own `Read-Lines` line model (CR-strip + drop one trailing empty
  record) on BOTH sides, so it is byte-symmetric with the bash `awk` extraction and immune to the
  trailing-empty-element subtlety of PS `-split`. Same contract, hardened implementation.

## Open issues for review

- **BLOCKED ON CAPABILITY (partial) — PowerShell execution is unavailable in this environment.** Both the
  dedicated `PowerShell` tool and `pwsh` via Bash are denied by the harness sandbox. I therefore could NOT
  capture the PS-side numbers (`test-init.ps1`, `test-language.ps1`, `verify_all.ps1`). The PS code was edited as
  the byte-symmetric mirror of the proven bash side and statically reviewed, but it has NOT been executed here.
  **CR/QA must run the three PS scripts on Windows** to confirm: `test-language.ps1` = 39/39; `test-init.ps1`
  composes green incl. the new `[zh][T-016]` assertion (SA expected total 274 → 275); `verify_all.ps1` = 32/0/0.
- **`baseline.json` `test_init_ps_assertions` and the README `test--init-274%2F274` badge were NOT updated** —
  per AC-10/L27 I will not ship an uncaptured estimate. The bash count (237, captured) IS updated. If a PS run
  confirms 275, QA should bump `test_init_ps_assertions` 274 → 275 and the README badge 274 → 275 (the README
  test-init badge is NOT gated by any verify_all check, so the gate stays green either way; this is a
  freshness-only correction). No verify_all FAIL results from the current values.
- `docs/tasks.md` shows as modified in `git status` — that is the PM's T-016 registration row, not my edit; left
  untouched (PM owns it).

## Dev-map updates

Added to `docs/dev-map.md` under `skills/harness-init/templates/`:
```
│   │       └── i18n/zh/                 ← Chinese language overlay
│   │           ├── common/docs/spec/README.md          ← human-facing (KEEP-ZH)
│   │           ├── common/evals/golden-tasks.md.tmpl   ← human-facing (KEEP-ZH)
│   │           └── _policy/output-language.zh.md.tmpl  ← single-source zh policy (T-016); NOT overlaid — read by language-policy.{ps1,sh}; zh init COMPOSES (lay English common/ + inject this policy)
```
and updated the `language-policy.{ps1,sh}` line to note the zh source is the `_policy` snippet and it drives
zh-init composition (step 4.4).

## Insight to surface (optional)

The `language-policy` helper's `--template-root` is the REPO root (the dir containing `skills/`), not the
`templates` dir — the helper internally appends `skills/harness-init/templates/...`; passing the templates dir
makes it silently `exit 1` (template not found), leaving the fixture un-injected. · evidence:
`skills/harness-init/templates/common/.harness/scripts/language-policy.sh:73-90` + Step-3 first run

## CR-minor prose fix (stage 5b)

Code Review APPROVED the work and raised one MINOR: the "Note" block in `skills/harness-init/SKILL.md`
(lines ~160-163) described `CLAUDE.md.tmpl` / `copilot-instructions.md.tmpl` as **never regenerated /
static stubs**, which now reads as contradicting the newly-added **step 4.4** — for a `{{LANG}}=zh`
project, step 4.4 injects the Chinese policy LINE into those two files via the `language-policy` helper.
Tightened the Note prose ONLY (zero behavior change; step 4.4, the helper, and all other files untouched).

**Before:**

```
`CLAUDE.md.tmpl` and `.github/copilot-instructions.md.tmpl` are copied to their
final paths during init and are **never regenerated** — they're static stubs.
```

**After:**

```
`CLAUDE.md.tmpl` and `.github/copilot-instructions.md.tmpl` are copied to their
final paths during init; their **body is static** and never regenerated —
they're stubs. (The one exception: for a `zh` project, step 4.4 rewrites *only*
the top `Output language` policy line in each, leaving the body untouched.)
```

Rationale: the stub BODY remains static (never regenerated); the only mutation is step 4.4's
REWRITE-LINE on the single top "Output language" policy line for a zh project — now stated accurately.

**`全程` self-trip guard (I.6):** grep of `skills/harness-init/SKILL.md` for `全程` → **0 occurrences**
(edit is English prose, so the `全程`+`中文` adjacency cannot arise). Re-Read of the edited lines
confirmed the Edit applied (Insight L10).

**Scope:** only `skills/harness-init/SKILL.md` changed in this stage (`git diff` of SKILL.md shows the
single Note-block hunk as the only stage-5b change; all other working-tree edits predate this stage from
the upstream T-016 work). The 2 NITs (test-init `.bak` cleanup style; M-1 sentinel comment) were NOT
touched. No test-init/test-language rerun needed — SKILL.md prose is not exercised by them.

**verify_all result (post-edit):**

- `verify_all.sh` (bash): **PASS: 32  WARN: 0  FAIL: 0** — version 0.27.0. Both checks that scan
  SKILL.md passed: `[C.2] Skill frontmatter sanity ... PASS` and
  `[I.6] No retired-claim phrases in current docs/templates ... PASS`. This is the substantive check
  for a prose-only edit to a scanned doc.
- `verify_all.ps1` (PowerShell twin): **BLOCKED in sandbox** — running pwsh was denied by the auto-mode
  classifier (PowerShell deny rule). Per task instructions, the bash I.6/C.2 PASS is the substantive
  check; PM to run the PS twin (expected identical 32/32/0/0).

## Verdict

READY FOR REVIEW
