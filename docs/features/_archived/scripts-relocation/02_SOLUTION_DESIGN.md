# 02 — Solution Design · scripts-relocation (T-007)

> Mode: **full** (7-stage, Gate-gated). Stage 2 of 7.
> Upstream: `01_REQUIREMENT_ANALYSIS.md` verdict = **RESOLVED — ready for design** (all 6 Qs answered in §10).
> This document is a complete implementation contract. Every path is absolute-from-repo-root; cite line ranges, do not paste (rule 70).

## 1. Architecture summary

Pure directory relocation, zero behavior change. Every harness-owned script leaves `scripts/` for `.harness/scripts/` in both the dogfood repo and the distribution templates under `skills/harness-init/templates/**`. The move is realized by `git mv` (preserves history + line content), followed by edit-in-place of the **path constants** the move forces inside the moved scripts (verify_all self-checks, sync-self mappings, install-hooks invocations) and inside every **live** doc/rule/agent/skill that names a `scripts/<relocated>` path. Two surfaces are special: the dogfood `.claude/settings.json` (LIVE startup config — **propose-only**, user applies) and a brand-new one-shot helper `migrate-scripts-layout.{ps1,sh}` for already-initialized user projects. Self-consistency (Layer-1 byte-identity templates↔repo, Layer-2 `.harness`↔`.claude`) is preserved by retargeting `sync-self`'s 8 mappings and confirming harness-sync scope is untouched. No new dependency, no new placeholder, no new verify_all check is required.

## 2. Affected modules (grouped by R-bucket)

### R1 — Repo `scripts/` → `.harness/scripts/` (git mv, 24 entries)

All 24 files in `scripts/` move, filename preserved (confirmed inventory via Glob, matches §2 R1):

`verify_all.{ps1,sh}`, `harness-sync.{ps1,sh}`, `sync-self.{ps1,sh}`, `install-hooks.{ps1,sh}`, `archive-task.{ps1,sh}`, `guard-rm.{ps1,sh}`, `test-init.{ps1,sh}`, `test-real-project.{ps1,sh}`, `test-supervisor.{ps1,sh}`, `test-verify-i6.{ps1,sh}`, `test-guard-rm.{ps1,sh}`, `baseline.json`, `verification_history.log`.

- `baseline.json` is **tracked** (confirmed absent from `.gitignore`) → `git mv` it.
- `verification_history.log` is gitignored by BOTH `.gitignore:33` (`*.log`) and `:34` (filename) → it is an untracked artifact; `git mv` won't apply. Action: delete the stale `scripts/verification_history.log` (or leave it — it's ignored either way) and let `verify_all` regenerate at the new append path (R5). **No `.gitignore` edit needed** — the filename rule `:34` is path-agnostic and still matches `.harness/scripts/verification_history.log`. Confirm `.gitignore` is left byte-identical.

After the move, the repo `scripts/` directory is **deleted entirely** (Q1=(a) absent — nothing harness-owned stays, Q4=(a) confirms 100% harness-owned).

### R2 — Template `<overlay>/scripts/` → `<overlay>/.harness/scripts/` (git mv, 16 entries)

Confirmed via Glob `skills/harness-init/templates/**/scripts/*` — there is **no `i18n/zh/**/scripts/`** overlay (the zh tree inherits common+stack scripts), so the surface is exactly:

- `skills/harness-init/templates/common/scripts/` (10 files): `harness-sync.{ps1,sh}`, `install-hooks.{ps1,sh}`, `archive-task.{ps1,sh}`, `guard-rm.{ps1,sh}`, `ai-native-mock.json`. (Note: `common/scripts/` has **no** verify_all pair — verify_all is stack-specific.)
- `skills/harness-init/templates/{fullstack,backend,generic}/scripts/verify_all.{ps1,sh}.tmpl` (6 files).

Total template moves: **16**. Each overlay's `scripts/` dir is then empty and deleted.

### R3 — Live `scripts/<name>` reference rewrite (edit-in-place)

Rewrite the literal `scripts/<relocated-name>` → `.harness/scripts/<relocated-name>` in **live** tracked files only. AC-4 exempt set (Q3=(a)): `docs/features/_archived/**`, `CHANGELOG.md`, and the dated-snapshot HTMLs `architecture.html`, `docs/walkthrough.html`, `docs/v0.11-changes.html`, `docs/project-overview.html`, `docs/system-overview.html`. The live targets, from the measured scan (`Grep` over the relocated-name regex, `_archived/**` excluded — 558 raw hits / 107 files; the live, non-historical subset below):

| Surface | Files (live) | Notes |
|---|---|---|
| Root docs | `AI-GUIDE.md` (incl. :36 gate line), `CLAUDE.md`, `README.md`, `README.zh-CN.md`, `CONTRIBUTING.md` | Q5 lockstep update to `.harness/scripts/verify_all` |
| `.harness/rules/*.md` | `00-core.md`, `05-insight-index.md`, `10-self-consistency.md`, `40-locations.md`, `60-tool-handoff.md`, `65-intervention.md`, `70-doc-size.md`, `75-safety-hook.md`, `80-settings-schema.md` | repo-bespoke rules (L12: NOT synced — see §4) |
| `.harness/agents/*.md` | `pm-orchestrator.md`, `qa-tester.md` (the two that name script paths) | dogfood SOT; mirrored to `.claude/` by harness-sync after E.2 |
| `docs/*.md` | `getting-started.md`, `concepts.md`, `dev-map.md` (incl. tree :75-88 + tables), `manual-e2e-test.md` | dev-map tree must show `.harness/scripts/` |
| `skills/**/SKILL.md` | `harness/`, `harness-goal/`, `harness-adopt/`, `harness-status/`, `harness-verify/`, `harness-supervise/`, `harness-batch/`, `harness-init/SKILL.md` | harness-init also has substitution recipe (R4) + generated-tree block :395-400 |
| `evals/*.md` | `golden-tasks.md`, `guard-rm-cases.md` | |
| `.github/copilot-instructions.md` | yes | static stub but LIVE — in scope per R3 |
| Insight memory | `.harness/insight-index.md` | 6 hits are inside evidence citations naming `scripts/verify_all.ps1:NNN` etc. **JUDGMENT:** these are historical evidence pointers (line cites into the OLD file). Treat as live-but-historical: rewrite the **path** but the line numbers will shift post-move; do NOT chase line numbers. Flag DESIGN-RISK-A below. |
| Template prose (live, NON-tmpl-script) | `templates/common/AI-GUIDE.md.tmpl`, `CLAUDE.md.tmpl`, `.github/copilot-instructions.md.tmpl`, `.harness/rules/*.md.tmpl` (00-core, 05, 60, 70, 75), `.harness/agents/{pm-orchestrator,qa-tester}.md`, `templates/{fullstack,backend}/.harness/{agents,skills}/**.tmpl`, `templates/i18n/zh/**` mirrors, `templates/{generic,...}/.harness/rules/50-*.md.tmpl` | distributed prose that tells the user to run `scripts/...` → must become `.harness/scripts/...` so a fresh init's docs match its layout |
| `tests/fixtures/README.md` | yes | 2 hits |

**Important live-vs-historical nuance — `MIGRATION.md`:** it is NOT in the Q3 exempt set (the I.6 block comment at `scripts/verify_all.ps1:513` explicitly says "MIGRATION.md is NOT exempt"). But its existing body (`MIGRATION.md:45-178`) documents the **v0.1→v0.2** migration where copying `harness-sync` into `scripts/` was historically correct. **DECISION:** do NOT rewrite the v0.1→v0.2 historical steps (that would falsify a past migration); instead **append a new top section** "## Upgrading to the `.harness/scripts/` layout (T-007)" that points users at `migrate-scripts-layout` and states the one-line Q5 note. The old section stays as the v0.2 record. Because MIGRATION.md is I.6-scanned, the new section must phrase around any banned literals (none of the relocation strings are banned today — confirm at gate via verify_all run).

### R4 — Hook wiring (dogfood propose-only + template direct)

- **Dogfood `.claude/settings.json` — PROPOSE-ONLY (CLAUDE.md red line).** Four hits (`Grep` count = 4): `:24` Stop command `pwsh -NoProfile -File scripts/harness-sync.ps1`, `:27` PreToolUse command `pwsh -NoProfile -File scripts/guard-rm.ps1`, `:9` permission-allow `Bash(bash scripts/harness-sync.sh:*)`, `:4` `_doc_sync_hook` doc string. The Developer surfaces a **proposed diff** changing ONLY the `scripts/` → `.harness/scripts/` path segment in all four; the user applies. Keep `-NoProfile` (L17). Do NOT touch `$schema` (`:2`) or `hooks` key names (L30 / J.1).
- **Template `settings.json.tmpl` — DIRECT edit.** `Grep` shows 2 hits: `:4` `_doc_sync_hook` doc string + `:28` permission-allow `Bash(bash scripts/harness-sync.sh:*)`. The hook `command` values themselves are `{{SYNC_COMMAND}}`/`{{GUARD_COMMAND}}` placeholders (`:42`, `:53`) — **placeholders unchanged** (R4 mandate; the path lives in the substitution recipe, not the template). Edit only the 2 prose/permission `scripts/` strings.
- **SKILL.md substitution recipe — DIRECT edit.** `skills/harness-init/SKILL.md:149-150` define `{{SYNC_COMMAND}}`/`{{GUARD_COMMAND}}` as `... -File scripts/harness-sync.ps1` / `bash scripts/harness-sync.sh` (and guard-rm). Retarget the four paths inside these two recipe lines to `.harness/scripts/`. Keep `-NoProfile`. No new placeholder (L11 avoided).

### R5 — `verify_all` self-checks retarget (both shells)

Enumerated in §5 below (the line-by-line table). Both `.ps1` and `.sh` carry identical edits (L13).

### R6 — `sync-self` + `install-hooks` + `harness-sync` invocation retarget

- `sync-self.{ps1,sh}` — the 8 script `from`/`to` mappings (`sync-self.ps1:40-47`, both sides currently `scripts/...`) retarget both columns to `.harness/scripts/...`. Header comment block (`:9-16`) prose also names `scripts/...` — update for accuracy.
- `install-hooks.{ps1,sh}` — self-reference comment (`install-hooks.ps1:11`) and the pre-commit-hook body it writes, which invokes `scripts/harness-sync.ps1`/`.sh` (`install-hooks.ps1:41-44`, `:54-55`) → retarget to `.harness/scripts/`.
- `archive-task.{ps1,sh}` — 2 hits each (header usage comment) → retarget.

### R7 — User-project verify_all template self-checks retarget

Each `templates/{fullstack,backend,generic}/scripts/verify_all.{ps1,sh}.tmpl` (now under `.harness/scripts/` after R2 move) has (confirmed on `generic`):
- secrets-glob exclude `:!scripts/verify_all*` (`.ps1.tmpl:60` / `.sh.tmpl:34`) — see §5 "secrets glob" decision.
- harness-sync binding-drift check `scripts/harness-sync.ps1` (`.ps1.tmpl:111-113`) / `scripts/harness-sync.sh` (`.sh.tmpl:70-73`) → `.harness/scripts/`.
- archive-task hint `scripts/archive-task` (`.ps1.tmpl:190` / `.sh.tmpl:147`) → `.harness/scripts/`.

Apply the same three edits to all three stacks × both shells = 6 files.

### R9 — Migration helper (NEW — §3 below)

`migrate-scripts-layout.ps1` + `migrate-scripts-layout.sh`, written into `.harness/scripts/` (dogfood) AND `templates/common/scripts/` → `templates/common/.harness/scripts/` (distributed). Regression-covered by extending `test-init` (or a small new fixture block — §3).

## 3. Module decomposition — `migrate-scripts-layout.{ps1,sh}`

**Responsibility:** one-shot, idempotent upgrade of an already-initialized USER project from the old `scripts/<harness>` layout to `.harness/scripts/`. Moves the harness-owned scripts and rewires the two hook command strings in the user's live `.claude/settings.json`. No-op when already migrated.

**Public surface (CLI):**
```
migrate-scripts-layout.ps1 [-DryRun] [-Force]
migrate-scripts-layout.sh   [--dry-run] [--force]
```
- `-DryRun/--dry-run`: print the planned moves + the settings.json diff, change nothing, exit 0.
- `-Force`: proceed even if the target `.harness/scripts/<name>` already exists (overwrite). Default: skip already-present targets (idempotent).
- Exit codes: `0` migrated-or-already-migrated, `1` user error (e.g. not a harness project — no `.claude/settings.json`).

**What it moves** (the known harness-owned set, NOT a blanket `scripts/*` — a user may have authored their own `scripts/foo`):
`verify_all`, `harness-sync`, `guard-rm`, `install-hooks`, `archive-task` (`.ps1`+`.sh` pairs) + `baseline.json`. For each present at `scripts/<name>`: `git mv` if inside a git repo and tracked, else plain move; create `.harness/scripts/` first. `verification_history.log` is NOT moved (regenerates).

**Idempotency strategy:** before each move, test target existence. If `scripts/<name>` is absent AND `.harness/scripts/<name>` present → that entry is already migrated, skip. If neither present → not a harness layout for that entry, skip silently. The whole run is a no-op (exit 0, "already migrated / nothing to do") when no source files remain at `scripts/`.

**Hook rewire (the delicate part — edits the user's LIVE settings.json):**
- Read `.claude/settings.json` raw. Parse JSON (PS: `ConvertFrom-Json`; bash: prefer a tolerant text edit — see below).
- Rewire EXACTLY the two command strings: replace the substring `scripts/harness-sync.` → `.harness/scripts/harness-sync.` and `scripts/guard-rm.` → `.harness/scripts/guard-rm.` inside the `hooks.Stop[].command` and `hooks.PreToolUse[].command` values (and the `permissions.allow` `bash scripts/harness-sync.sh` entry). **Surgical substring replacement, not full re-serialize** — this preserves the user's `$schema`, comments, key order, and any custom permissions byte-for-byte (re-serializing via ConvertTo-Json would reorder keys and strip `_comment` doc keys — a regression we must avoid). PowerShell does a `-creplace` on the raw text (case-sensitive, L19/L20 class); bash does a `sed`-equivalent on the raw text. Keep `-NoProfile` (it's part of the existing command string, untouched by a path-only replace).
- **Safety + reversibility:** write a timestamped backup `.claude/settings.json.bak-<ISO8601>` BEFORE editing. On `-DryRun`, print the unified diff and skip the write. Idempotent: if the command strings already contain `.harness/scripts/`, the replace is a no-op (substring not found → unchanged) and no `.bak` is written.
- **No-op detection ordering:** rewire runs only if at least one source file was moved OR the settings still contains an old `scripts/harness-sync`/`scripts/guard-rm` path; otherwise skip the settings write entirely.

**Regression testing (AC-5):** add a dedicated test block — recommend a NEW small driver `test-migrate.{ps1,sh}` OR (lighter, preferred) extend `test-init.{ps1,sh}` with a "downgrade-then-migrate" fixture: (1) build a fresh init tree, (2) synthetically move its `.harness/scripts/*` back to `scripts/*` + rewrite its settings.json to the OLD paths (simulating a v0.18-initialized project), (3) run `migrate-scripts-layout`, (4) assert: `.harness/scripts/verify_all.*` present, `scripts/` harness files gone, settings.json both hook commands now `.harness/scripts/`, `-NoProfile` retained, `$schema` unchanged, a `.bak` exists, and a SECOND run is a clean no-op (idempotency). **DECISION:** extend `test-init` (reuse its temp-dir harness + Assert helper at `scripts/test-init.ps1`), because a standalone `test-migrate` would need to be added to F.1 symmetry and verify_all wiring (more surface). If the Developer finds `test-init` too crowded, a standalone driver is acceptable but then MUST be added to F.1's pair list — flag at gate.

## 4. Self-consistency plan

### Layer 1 (sync-self: templates/common ↔ repo) — RETARGET REQUIRED

The 8 file mappings in `sync-self.ps1:40-47` (and the `.sh` peer) currently read `scripts/harness-sync.ps1 → scripts/harness-sync.ps1` etc. Retarget BOTH `from` and `to` columns to `.harness/scripts/...` for: `harness-sync.{ps1,sh}`, `install-hooks.{ps1,sh}`, `archive-task.{ps1,sh}`, `guard-rm.{ps1,sh}`. The `.harness/agents` dir mapping (`sync-self.ps1:39`) is unaffected. Post-edit, sync-self compares `templates/common/.harness/scripts/<f>` ↔ repo `.harness/scripts/<f>` — Layer-1 byte-identity holds because BOTH endpoints moved identically (R1+R2 are the same git-mv applied to both trees). **Confirmed:** the 8 moved pairs are byte-identical pre-move (sync-self currently passes E.1); `git mv` preserves bytes; therefore post-move they remain byte-identical. AC-6 satisfied.

### Layer 2 (harness-sync: `.harness/{agents,skills}` ↔ `.claude/{agents,skills}`) — UNAFFECTED (verified)

harness-sync's scope is `.harness/agents/` + `.harness/skills/` → `.claude/`. The relocated scripts land in `.harness/scripts/`, which is **outside** harness-sync's copy scope. Confirmed by reading `dev-map.md:104` (Layer 2 = agents+skills only) and the E.2 invocation (`verify_all.ps1:200-202`). **However:** R3 rewrites two `.harness/agents/*.md` (`pm-orchestrator.md`, `qa-tester.md`) for their `scripts/` prose. After editing those, the Developer MUST run `harness-sync` so `.claude/agents/{pm-orchestrator,qa-tester}.md` re-mirror — otherwise E.2 FAILs (Layer-2 drift). This is the only harness-sync touch-point. (L12 reminder: rule edits do NOT need sync; agent edits DO.)

### sync-self header-prose

`sync-self.ps1:7-16` comment lists the synced paths as `scripts/...`; update prose to `.harness/scripts/...` for accuracy (not enforced, but avoids lying docs).

## 5. verify_all self-check retarget — exhaustive path-constant table

Both shells. `.ps1` line numbers from current `scripts/verify_all.ps1`; `.sh` numbers differ — listed separately because the requirement's ranges were `.ps1`-only.

| Check | `.ps1` location | `.sh` location | Old → New |
|---|---|---|---|
| A.1 secrets-glob exclude | `:45` `':!scripts/verify_all*'` | `:32` same | → `':!.harness/scripts/verify_all*'` — see decision below |
| E.1 sync-self invocation | `:195-196` (`PSScriptRoot/sync-self.ps1`; msg "run scripts/sync-self.ps1") | `:193,196` (`$repo_root/scripts/sync-self.sh`; msg) | invocation path + message → `.harness/scripts/` |
| E.2 harness-sync invocation | `:201-202` (msg "run scripts/harness-sync.ps1") | `:200,203` (`$repo_root/scripts/harness-sync.sh`) | invocation path + message → `.harness/scripts/` |
| F.1 pair existence | `:271-272` `scripts/$pair.{ps1,sh}` | `:285-286` same | → `.harness/scripts/$pair.{ps1,sh}` |
| F.2 guard-rm presence | `:278` `scripts/guard-rm.{ps1,sh}` + `:279-280` template paths | `:292-294` same | repo paths → `.harness/scripts/`; template paths → `templates/common/.harness/scripts/guard-rm.*` |
| I.6 exempt-FILE list | `:519-522` (`scripts/verify_all.{ps1,sh}`, `scripts/test-verify-i6.{ps1,sh}`) | `:550-553` same | → `.harness/scripts/...` (L26 — MANDATORY, else I.6 fires on the relocated self-check files) |
| J.1 settings targets | `:587-588` (`.claude/settings.json` + template tmpl) | (matching block) | **no path change** — these are settings.json paths, not script paths. Leave byte-identical (L30). |
| history append | `:636` `Add-Content -Path "scripts/verification_history.log"` | `:664` `>> scripts/verification_history.log` | → `.harness/scripts/verification_history.log` |

**E.1/E.2 PowerShell note:** `:195`/`:201` invoke via `Join-Path $PSScriptRoot "sync-self.ps1"` — `$PSScriptRoot` is the script's OWN dir, so after the move it resolves to `.harness/scripts/` automatically; only the human-readable FAIL **message** strings (`:196`, `:202`) need the `scripts/`→`.harness/scripts/` text edit. The `.sh` peer uses `$repo_root/scripts/sync-self.sh` (`:193`, `:200`) which is an EXPLICIT path → must be edited to `$repo_root/.harness/scripts/...`. (This PS-vs-Bash asymmetry is exactly the L13 trap — call it out to the Developer.)

**Secrets-glob decision (A.1):** when `verify_all` moves under `.harness/`, its body (containing the literal token-regex) could self-match A.1. Two options: (a) change the exclude to `':!.harness/scripts/verify_all*'`; (b) rely on the fact that the existing exclude `':!skills/*'` does NOT cover `.harness/`, so an explicit exclude is still needed. **RECOMMEND (a)** — retarget the exclude path to `.harness/scripts/verify_all*` in both shells. This is a path-constant retarget (in-scope R5), not a new check. The stack `verify_all.*.tmpl` files exclude `':!.harness/*'` already (confirmed `generic/...ps1.tmpl:60`) — once their verify_all sits under `.harness/`, the broad `.harness/*` exclude already covers it, so the explicit `scripts/verify_all*` exclude in the tmpl becomes redundant; retarget it to `.harness/scripts/verify_all*` for consistency (harmless overlap with `.harness/*`).

**New verify_all check — RECOMMENDATION: do NOT add one.** §3 out-of-scope explicitly forbids introducing a new check, and the existing checks already prevent regression: F.1 FAILs if `.harness/scripts/verify_all.{ps1,sh}` (etc.) go missing; AC-4's `git grep` (a tester action, not a gate check) catches stale live refs; if a harness script *reappeared* under `scripts/`, sync-self mappings point at `.harness/scripts/` so E.1 would FAIL on the orphan/missing. A "FAIL if any harness script reappears under `scripts/`" guard is *tempting* but (i) violates the out-of-scope rule, (ii) would need its own exempt logic for user projects that legitimately keep a `scripts/` dir, and (iii) adds a placeholder-whitelist-class maintenance burden. **Verdict: existing F.1 + AC-4 git-grep + E.1 suffice.** If the Gate Reviewer wants belt-and-suspenders, propose it as a SEPARATE follow-up task, not this delivery.

## 6. Sequence / migration ordering (the safe edit order)

The bootstrapping wrinkle: `verify_all` is itself one of the moved files, so the gate cannot self-validate mid-flight. Safe order:

1. **`git mv` the repo scripts** (R1) — `scripts/* → .harness/scripts/*` (skip `verification_history.log`; delete it). Repo `scripts/` now empty → remove dir.
2. **`git mv` the template scripts** (R2) — common (10) + 3 stacks (6). Overlay `scripts/` dirs now empty → remove.
3. **Retarget the moved scripts' internal path constants** (R5 verify_all, R6 sync-self/install-hooks/archive-task, R7 tmpl self-checks) — edit-in-place at their NEW `.harness/scripts/` locations. At this point the scripts are present but self-checks are half-retargeted; do this as one atomic batch per file (PS+SH together, L13).
4. **Write the migration helper** (R9) into `.harness/scripts/` + `templates/common/.harness/scripts/`.
5. **Rewrite live docs/rules/skills/evals/agents prose** (R3) + SKILL.md recipe + template prose/permission (R4 direct parts). Run `harness-sync` after the two `.harness/agents/*.md` edits (Layer-2).
6. **Run `.harness/scripts/sync-self.ps1 -Check`** (Layer-1) and `.harness/scripts/harness-sync.ps1 -Check` (Layer-2) → both green.
7. **Update the regression fixtures** (`test-init.{ps1,sh}` assertions at `scripts/test-init.ps1:224-225,253-254,270` etc.) to expect `.harness/scripts/`; extend with the migrate fixture (§3).
8. **Run `.harness/scripts/verify_all.ps1`** (and `.sh` where env supports) → all PASS (R8/AC-3). This is the first point the moved gate validates itself.
9. **Propose the `.claude/settings.json` diff** to the user (R4 propose-only); user applies; re-run F.2 to confirm AC-2.
10. **Append the MIGRATION.md relocation section** (R3 nuance) + bump any doc count claims (manual, per L14 fan-out — AI-GUIDE :36, dev-map count, README badges if any reference check count).

Rationale: moves first (steps 1-2) so paths exist; self-checks retargeted (step 3) before the gate runs; the gate (`verify_all`) is the LAST thing validated because it is itself moved and edited. Steps 1-8 keep the repo in a state where, at worst, the gate is temporarily red on a path the very next step fixes — never a state that blocks the Developer from reaching green.

## 7. Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| Move files preserving history | `git mv` | (git) | Reuse — no script needed for the repo/template move |
| Layer-1 sync engine | `sync-self` mapping loop | `scripts/sync-self.ps1:38-112` | Reuse as-is; only the 8 mapping path strings change |
| Layer-2 sync | `harness-sync` | `scripts/harness-sync.{ps1,sh}` | Reuse unchanged; scope excludes `.harness/scripts/` (verified §4) |
| Settings.json safe read/parse | `verify_all` F.2/J.1 parse pattern | `scripts/verify_all.ps1:284-296`, `:585-616` | Reference for the helper's parse approach; helper uses **surgical text replace**, not re-serialize (avoids key-reorder regression) |
| Idempotent file-presence guard | sync-self `Sync-File` hash-compare | `scripts/sync-self.ps1:52-60` | Pattern reuse for the helper's "already migrated?" skip logic |
| Regression harness (temp dir + Assert) | `test-init` driver | `scripts/test-init.ps1` (temp-dir + `Assert`) | Extend with downgrade-then-migrate fixture (§3) |
| Backup-before-edit pattern | (none found in repo) | — | New (timestamped `.bak`) — justified: helper mutates the user's live config, must be reversible |
| Migration doc precedent | `MIGRATION.md` v0.1→v0.2 structure | `MIGRATION.md:1-229` | Extend (append new section), don't rewrite history |

No new third-party dependency. No new tool surface (helper is PS/Bash, same as every other script). No new `{{...}}` placeholder (L11 avoided — confirmed).

## 8. Risk analysis

| # | Risk | Likelihood | Blast radius | Mitigation |
|---|---|---|---|---|
| R-1 | **Stale hook in dogfood settings.json** — if the propose-only edit isn't applied, the Stop-sync / PreToolUse guard silently no-ops (guard **fails OPEN** per §4 boundary; destructive commands pass). | Med (propose-only = a human step that can be skipped) | High (safety) | §6 step 9 makes settings.json a gated step; AC-2 verifies F.2 PASS + a live destructive-call block. Developer surfaces the diff prominently. NFR-Safety: the helper's substring-replace is atomic per user. |
| R-2 | **Partial sweep leaves a live `scripts/` ref** → AC-4 fail. 558 raw hits across 107 files; easy to miss a prose mention (esp. i18n/zh mirrors, template `.harness/agents/*.tmpl`). | High | Med (cosmetic + a future-init project ships wrong docs) | AC-4 `git grep` for each relocated name under `scripts/` (excluding Q3 set) is the exhaustive backstop — run it as the definitive check (L28: rely on the matcher, not hand-reasoning). Sweep i18n/zh in the SAME pass as `common` (L06 inverse-check discipline). |
| R-3 | **PS/Bash asymmetry** — a path edited in `.ps1` but missed in `.sh` (or the E.1/E.2 `$PSScriptRoot`-auto-resolves-but-`$repo_root`-is-explicit asymmetry, §5). PS-run verify_all hides the bash bug (L13/L24). | High | Med (Unix users hit it later) | Edit each `.ps1`/`.sh` pair in one batch; run BOTH `verify_all.ps1` AND `verify_all.sh` at step 8 where the env supports bash (Git-bash via `git.exe` root per L27, not WindowsApps stub). §5 table is the per-line checklist. |
| R-4 | **Regression fixtures assert the OLD layout** — `test-init.{ps1,sh}` (`:224-225,253-254,270`) and `test-real-project.{ps1,sh}` assert `scripts/verify_all.ps1` etc. exist. After the move these FAIL unless flipped. | High (certain if forgotten) | Med (red gate) | §6 step 7 flips them BEFORE step 8's gate run. Also flip the AC-1 absent-`scripts/` assertion (Q1=(a): assert `scripts/` is absent in the generated tree). |
| R-5 | **`.gitignore` / data-file disposition** — assuming wrong about `verification_history.log` (gitignored) vs `baseline.json` (tracked). | Low (verified) | Low | Verified: `.gitignore:33-34` matches the log by filename (path-agnostic) → no edit; `baseline.json` not ignored → `git mv` it. SKILL.md step 10 (`:350`) must write `baseline.json` to `.harness/scripts/` on fresh init. |
| R-6 | **MIGRATION.md history falsification** — a blanket `scripts/`→`.harness/scripts/` rewrite would corrupt the v0.1→v0.2 historical steps AND trip the I.6 scan (MIGRATION.md is NOT exempt). | Med | Low | §2 R3 decision: append a NEW relocation section, leave the v0.2 body intact; phrase the new section around any I.6 banned literals; confirm at gate via verify_all run (L23 — let the matcher decide, not hand-reasoning). |
| R-7 | **Helper re-serializes settings.json** and strips `_comment`/`_doc_sync_hook` doc keys or reorders `hooks` keys (J.1 class). | Med | Med (breaks user's editor validation / J.1) | §3: surgical raw-text substring replace, never `ConvertTo-Json` round-trip; `.bak` for reversibility; idempotent no-op when already `.harness/scripts/`. Regression asserts `$schema` + doc keys survive. |

## 9. Migration / rollout plan

- **Backward compat:** Q2=(a) one-shot helper (no shim, no forwarding stub). Fresh inits are clean (no `scripts/` dir). Existing users run `migrate-scripts-layout` once.
- **Data migration:** `baseline.json` `git mv`'d; `verification_history.log` regenerates at new path (no carry-over needed — it's an append log). The helper moves `baseline.json` for users; does NOT carry the old log.
- **Rollback:** repo-side — `git revert` of the relocation commit restores `scripts/`. User-side — the helper's `.bak-<ISO>` restores their settings.json; the moved files can be moved back manually (or `git checkout` if they tracked them). The helper is reversible by design.
- **Feature flag:** none — this is a structural move, not a runtime toggle. The "flag" is simply whether a user runs the helper.
- **Version bump:** this is a breaking layout change for already-initialized projects → a MINOR bump (per the project's pre-1.0 convention where layout changes are minors); CHANGELOG entry required (CHANGELOG itself is Q3-exempt from the path rewrite but MUST gain a new release entry describing T-007). Bump README/AI-GUIDE/dev-map/manual-e2e-test version + check-count claims in lockstep (L14 fan-out; verify_all G.3 catches version drift at FAIL).

## 10. Out-of-scope clarifications

- No script renamed, no logic changed beyond forced path constants (per §3 RA).
- `docs/features/_archived/**`, `CHANGELOG.md` body refs, and the 5 dated-snapshot HTMLs are NOT path-rewritten (Q3=(a)); they keep historical `scripts/` strings. CHANGELOG still gains a NEW release entry.
- No new verify_all check (§5 recommendation); no new placeholder; no new dependency.
- The helper handles only the **known harness-owned** script set — it does not touch a user's own `scripts/<custom>` files.
- `$schema` URL and `hooks` key names in any settings.json are NOT touched (L30 / J.1) — only the `command` path segment.
- This design does NOT cover a `/harness-upgrade` skill (out of scope; the bare helper is the deliverable).

## 11. Partition assignment

**Single-Developer mode.** Glob `.harness/agents/dev-*.md` → no files (only the 7 canonical + supervisor exist; `dev-*.md.tmpl` live only under `templates/{fullstack,backend}/` as distribution artifacts, not as THIS repo's partition agents). No partition table required; one Developer owns the whole change. Within the single dev, follow the §6 ordering strictly (moves → self-check retarget → docs → fixtures → gate → settings propose).

## 12. Verdict

**READY.** The brief is complete and unambiguous (RA §10 resolves all 6 Qs). The surface is fully enumerated from reading the actual files: 24 repo files + 16 template files to `git mv`; the verify_all/sync-self/install-hooks/tmpl path constants are line-located in BOTH shells (§5); the migration helper is specified with idempotency, safety, reversibility, and a regression-test plan (§3); self-consistency is preserved (Layer-1 retarget verified, Layer-2 verified untouched, §4). No upstream gap. No new dependency. No design contradiction with the requirement.

**Hand-off notes for the Gate Reviewer (DESIGN-RISK flags):**
- **DESIGN-RISK-A (insight-index line cites):** `.harness/insight-index.md` has 6 hits that are `scripts/<file>:NNN` EVIDENCE pointers into the old file; this design rewrites the PATH but NOT the line numbers (they shift post-move and chasing them is out of scope). Confirm GR accepts path-only rewrite of evidence citations.
- **DESIGN-RISK-B (MIGRATION.md append-not-rewrite):** §2 R3 decides to APPEND a relocation section rather than rewrite the v0.2 history; confirm GR agrees this is the right read of Q3+Q5 (MIGRATION.md is I.6-scanned but not Q3-exempt).
- **DESIGN-RISK-C (no new regression-guard check):** §5 recommends NOT adding a "harness-script-reappears-under-scripts/" verify_all guard (out-of-scope per §3 RA); confirm GR is comfortable that F.1 + AC-4 git-grep + E.1 suffice, or routes a separate follow-up task.
- **DESIGN-RISK-D (E.1/E.2 PS-vs-Bash path asymmetry):** PS auto-resolves via `$PSScriptRoot` (only FAIL-message text changes) but bash uses explicit `$repo_root/scripts/...` (real path change) — a classic L13 trap the Developer must not flatten.
