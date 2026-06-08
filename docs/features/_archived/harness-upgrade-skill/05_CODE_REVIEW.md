# 05 — Code Review: `/harness-upgrade` skill (T-012)

> Stage 5 (Code Reviewer). Independent review against requirement + design.
> Persisted by PM (Code Reviewer is read-only: `tools: Read, Glob, Grep`).

## Verdict: APPROVED

**0 BLOCKING, 0 MAJOR, 4 MINOR, 2 NIT.** All MINOR routed to developer (doc/wording/cosmetic);
none blocks merge. Design-drift item adjudicated ACCEPT (not drift). No route to architect.

## Focus-area verdicts (the 8 places defects hide)

1. **L31 root-derivation crux — VERIFIED SOUND.** S2 (`upgrade-project.ps1:148-174`, `.sh:131-155`) unconditionally byte-overwrites the full refresh set (`harness-sync`, `install-hooks`, `archive-task`, `guard-rm`, `migrate-scripts-layout` — both shells) from the template via `Copy-Item -Force`/`cp`, gated only by a SHA/`cmp` NOOP-on-identical short-circuit — no "relocate-only" branch. Relocated `harness-sync` ends up two-up (`harness-sync.ps1:23`, `.sh:16`). AC-5 fixture **genuinely** invokes the relocated script at runtime (`test-harness-upgrade.ps1:183-188`, `.sh:177-178`) and asserts exit 0 — a one-up derivation would resolve to the temp dir where `.harness/` is absent → exit 1 → fail. NOT a stub.
2. **verify_all refresh matrix — VERIFIED SOUND.** All four branches present in both shells (`upgrade-project.ps1:367-397`, `.sh:348-375`): SPLICE / REGEN / HALT-exit-2 / REGEN. `.bak` on every actual overwrite; NOOP-on-identical for idempotence. **OQ-3 hard constraint holds** — no path silently overwrites a customized B.* (HALT leaves file untouched; `--force` writes `.bak` first).
3. **Piece-wise `{{...}}` assembly — ACCEPT (not drift).** See adjudication below.
4. **Settings rewire — VERIFIED SOUND.** Raw-text `.Replace`/`sed` only incl. `.harness/.harness/` collapse + `.bak`; no JSON re-serialize. DO-3/L30 honored.
5. **Cross-shell parity & byte-identity — VERIFIED SOUND.** Behaviorally equivalent; dogfood = template; `upgrade-project` rows added to `sync-self.ps1:55-56` + `.sh:82-83`. Bash idioms safe (`arr=()`, no `grep -F -i`, `*_file` loop vars). PS `-cne`/`-ceq` where fixed-case matters.
6. **Fan-out completeness — VERIFIED EXHAUSTIVE.** Independent sweep of `12 skills`/`twelve`/`十二`/`12 个`/`0.22.0`: every remaining token is legitimate history (CHANGELOG/Roadmap/labeled snapshots/_archived). All live sites read 13/thirteen/0.23.0. **"six task shapes"/"6 种任务形态" correctly UNCHANGED** (README:15, zh-CN:15). New skill under **Setup**, not Pipeline. CHANGELOG `[0.23.0]` mentions `harness-upgrade`.
7. **Fabricated/stale-tally guard — NO CONTRADICTION.** PS 38 asserts, sh 39 static → 37 runtime (AC-3 JSON-parse is a 3-way mutually-exclusive branch, `test-harness-upgrade.sh:189-197`, one runs → 39−2=37), matching the claimed 38/37. No present/absent contradiction on a shared path; every asserted string exists in the targeted code/template. NOT a T-007-style fabrication.
8. **SKILL.md quality — SOUND (minor nits).** Frontmatter valid; flow matches CLI + 0/1/2/3 contract; honors OQ-8 / OQ-4 / BC-2 / B-8; `CLAUDE_PLUGIN_ROOT` best-effort-with-fallback, not load-bearing (F-3 discharged).

## Findings

### MINOR (all → developer)
- **[DOC] `upgrade-project.ps1:30`** — stdout-contract comment lists `TARGET-VERSION|<x.y.z>` but the helper never emits it (it's the SKILL's job per design §5 — correct); and `SKILL.md:70` prints colon form `TARGET-VERSION:` vs the documented pipe form. Trim the helper comment + align the skill format.
- **[MAINT] `upgrade-project.ps1:391` / `.sh:369`** — the VERIFY-HALT `CONFLICT` message says "the .bak preserves your old checks", but on the HALT (exit 2, pre-`--force`) path no `.bak` is written (file untouched; nothing lost). Message is forward-looking and could send a user hunting for a non-existent `.bak`. Reword to "...re-run with --force to overwrite (a .bak will be written first, preserving your old checks)".
- **[LOGIC] `upgrade-project.ps1:64-77` / `.sh:52-69`** — `$templateTypeScripts` interpolates `$Type` before the empty-Type check (malformed path caught one check later). Functionally safe (empty rejected at `:70`/`:58`; bad Type rejected by `[ValidateSet]`/`case`). Cosmetic ordering.
- **[MAINT] `upgrade-project.ps1:104-112` vs `:148-153`** — `known` set and `refreshSet` are two hand-maintained arrays that must stay in sync (refreshSet = known minus `verify_all`/`baseline.json`). Both correct today; a cross-ref comment or derived subset would be more robust. Advisory — do not block.

### NIT
- **[STYLE] `README.md:5` / `README.zh-CN.md:5`** — `test-init-227%2F227` badge is stale vs the reported 251/213. **Predates T-012**, not in the changed-files set, not G.4-gated → out of scope for this task; flagged for awareness only.
- **[STYLE] `upgrade-project.ps1:30`** — inline note "(echoed from -Today/-TemplateRoot context if available)" on the TARGET-VERSION line is meaningless. Cosmetic.

## Adjudication of the self-flagged DESIGN DRIFT (#3): ACCEPT — not drift
The helper assembles substitution tokens from pieces (`$o+"PROJECT_NAME"+$c`, `upgrade-project.ps1:343-347`, `.sh:268-274`) instead of literal `{{PROJECT_NAME}}`. Verified against `test-init.ps1:247-256`, which recursively scans every generated `.ps1`/`.sh`/`.md`/`.json` for `\{\{[A-Z_]+\}\}`. Since the helper ships under `templates/common/.harness/scripts/` and is copied verbatim into generated projects, a literal token would be a false-positive failure of that cleanliness scan even though the helper legitimately must name the token to substitute it. The technique: introduces no new placeholder (3 names unchanged, D.2 untouched), does not weaken the scan (stays strict + path-based), masks no real problem (runtime substitution identical). **No route to solution-architect.**

## Requirement coverage (AC-1..AC-15): all ✅ (see PM_LOG / 04 traceability)
AC-5 (root two-up) genuinely proven by a runtime assertion, not a stub. AC-13 both branches (SPLICE + HALT/`--force`) tested. AC-15 fan-out verified exhaustive.

## Design fidelity: all ✅
Single-surface skill; S1–S5 match §3.2; refresh set = §3.3; exit codes 0/1/2/3; 4-branch matrix; B.* markers in all 6 templates + none in bespoke dogfood verify_all; no D.2 change; check count stays 32; GR F-1..F-5 all discharged.

## Residual risk profile for QA (verify by EXECUTION)
1. **#1 — run `test-harness-upgrade.{ps1,sh}`; confirm the AC-5 runtime assertion passes** (relocated `harness-sync` runs from project root, exit 0 = two-up proven). Confirm 38/37 tallies.
2. Run `verify_all.{ps1,sh}` → **32/32, 0 WARN, 0 FAIL** in BOTH shells (dev captured bash via exit-code probe only — MSYS truncation; get the full green summary on a non-Windows shell).
3. `sync-self -Check` / `--check` → "In sync" (E.1 byte-identity of the new pair).
4. `test-init.{ps1,sh}` → six templates' B.* markers still produce a clean placeholder-free passing project (and the copied helper does NOT trip the no-placeholder scan).
5. SPLICE idempotence: run Fixture D upgrade twice; confirm 2nd run NOOPs verify_all (T-007 trailing-newline failure class).
