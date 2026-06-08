# Delivery Summary — T-012 harness-upgrade-skill

- **Task:** `/harness-upgrade` — a new (13th) skill that upgrades an already-initialized but
  stale harness project to the current plugin layout + script contents (self-bootstrapping,
  non-destructive, idempotent, dry-run-previewable, ends on a green verify_all).
- **Mode:** full (7-stage).
- **Stages traversed:** 1 Requirement (2026-06-08) → OQ resolution (user-delegated) →
  2 Design → 3 Gate (APPROVED, 0 blocking / 5 advisory) → 4 Developer → 5 Code Review
  (APPROVED, 0 blocking) → 5b CR-minor cleanup → 6 QA (PASS, 1 minor) → 6b DEFECT-1 fix →
  7 Delivery.
- **Rollbacks:** 0 (no stage returned an upstream CHANGES-REQUIRED/FAIL route-back; 5b and 6b
  were forward polish within the Developer stage, each re-gated green).
- **Final verify_all result:** **PASS — 32/32, 0 WARN, 0 FAIL** (PM-run on delivery, PS native;
  independently reproduced 32/32 in BOTH shells by Developer + QA). G.1/G.2 = 13 skills,
  G.3/G.4 = version 0.23.0 consistent across plugin.json / marketplace.json / both READMEs.
- **Baseline changes:** check count **stays 32** (a new skill is version-worthy but not
  check-worthy — no new lettered check); skill count **12 → 13**; version **0.22.0 → 0.23.0**;
  `baseline.json` gained `test_harness_upgrade_ps_assertions: 38` / `_bash_assertions: 37`.
  New regression pair `test-harness-upgrade.{ps1,sh}` (38/37). `test-init` unchanged (251/213).

## What shipped

- `skills/harness-upgrade/SKILL.md` — judgment layer (cache+version discovery with
  `CLAUDE_PLUGIN_ROOT`-optional glob fallback; detect-then-ASK project type; plan→confirm→apply;
  exit-code 0/1/2/3 branching; surfaces verify_all verbatim). Single SOT (`skills/<name>/`,
  no `.harness/skills/` in this repo).
- `upgrade-project.{ps1,sh}` (template `templates/common/.harness/scripts/` + dogfood mirror via
  the `sync-self` set) — deterministic helper: S1 relocate known-set → **S2 unconditional
  content-refresh of the depth-sensitive scripts** (the L31 root-derivation fix) → S3 raw-text
  settings rewire (no JSON re-serialize) → S4 stock-vs-custom hook (re)install → S5 verify_all
  regenerate with the `HARNESS:B-CUSTOM` splice/HALT matrix. Machine-readable pipe-delimited
  stdout, dry-run, idempotent.
- `HARNESS:B-CUSTOM:BEGIN/END` delimiters added to all six `verify_all.*.tmpl` files (literal
  ASCII, no `{{...}}` → D.2 untouched).
- `test-harness-upgrade.{ps1,sh}` — regression suite (isolated temp-dir fixtures).
- Ship fan-out: verify_all C.1/G.1/G.2 + F.1 (both shells), sync-self set, AI-GUIDE, README×2
  (+ badges), getting-started (new skill under **Setup**, not a 7th task-shape), manual-e2e-test,
  dev-map, 40-locations, CHANGELOG `[0.23.0]`, plugin.json, marketplace.json.

## Files changed (git)

22 tracked files modified (138+/38-), 9 new files added (SKILL.md, helper pair ×2 surfaces,
test pair, 7 stage docs). Full list in the delivery commit. (`docs/system-overview.html`, a
pre-existing untracked file unrelated to this task, is intentionally NOT included.)

## Outstanding risks / notes for the user

- The skill's AI layer (`AskUserQuestion` type prompt, plan→confirm gating, dirty-tree refusal
  at SKILL.md, cache-glob discovery) is not headlessly testable; QA marked AC-8/AC-12/BC-10
  **VERIFIED-BY-SPEC** and validated the underlying helper behavior directly. First real
  end-to-end exercise will be the first actual `/harness-upgrade` run on a stale project
  (e.g. NFBY_CMS — the motivating case).
- `CLAUDE_PLUGIN_ROOT` is best-effort-first; the glob fallback chain is load-bearing and
  BC-5 (halt-on-unresolvable) is the floor — so the skill does not depend on an unverified
  env-var contract.
- Pre-existing, out-of-scope: the `test-init-227%2F227` README badge is stale vs the live
  251/213 (predates T-012, not gate-enforced). Flagged for a future trivial cleanup, not fixed
  here to keep scope clean.

## Insight

- 2026-06-08 · A script that SHIPS into generated projects (under `skills/harness-init/templates/`) yet must reference placeholder NAMES for its own runtime substitution cannot contain a literal `{{NAME}}` — `test-init`'s recursive no-unresolved-placeholder scan (`test-init.ps1` globs every generated `.ps1/.sh/.md/.json` for `\{\{[A-Z_]+\}\}`) flags it as a failure. Assemble the token from pieces at runtime (`"{{"+ "NAME" +"}}"`); this keeps the strict scan intact while letting the helper name its own substitution tokens. · evidence: T-012, `upgrade-project.{ps1,sh}` Substitute-Placeholders + 05_CODE_REVIEW adjudication
- 2026-06-08 · PowerShell `[System.IO.File]::WriteAllText($p,$body)` writes NO trailing newline, while a bash heredoc / `printf '%s\n'` includes one — so a "parity" `.ps1`/`.sh` pair that each GENERATE the same file (e.g. a git hook) emit byte-different output, which silently breaks any downstream byte-identity / idempotence check (here: a spurious one-time hook re-install + `.bak` on a ps1→sh switch). Detection: any cross-shell pair that WRITES a file later compared for byte-equality; fix by appending `` "`n" `` on the PS side. Generalizes the cross-shell-parity family (NFR-1). · evidence: T-012 DEFECT-1 (QA), `upgrade-project.ps1` hook-write sites
