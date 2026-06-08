# 02 — Solution Design: `/harness-upgrade` skill (T-012)

> Stage 2 (Solution Architect). Mode: **full**. Inputs are read-only.
> Designed to the **RESOLVED baseline** (OQ-1..OQ-10 decided by user-delegated PM
> authority); the requirement doc's verdict was `BLOCKED ON USER` only because the
> OQs were open at stage 1 — they are now closed, so this design proceeds. Every
> path is absolute-from-repo-root and grounded in the real code read during design.

---

## 1. Architecture summary

`/harness-upgrade` is a new (13th) plugin skill that brings an **already-initialized
but stale** harness project up to the current plugin layout: scripts under
`.harness/scripts/`, a pre-commit hook pointing at the new path, settings hook-paths
rewired, and a freshly-regenerated per-type `verify_all`. The skill is the **judgment
layer** (gap diagnosis, project-type detection via `AskUserQuestion`, the
verify_all-refresh confirm decision, final reporting). All **mechanical** work is done
by ONE new deterministic helper, `upgrade-project.{ps1,sh}`, that the skill bootstraps
into the target project from the plugin template cache and then drives with explicit
flags. The helper composes three *already-proven* mechanisms: the relocation +
raw-text settings-rewire from `migrate-scripts-layout.{ps1,sh}`, the stock-hook writer
from `install-hooks.{ps1,sh}`, and a new content-refresh + verify_all-regenerate step.
The single non-obvious correctness fix vs. the existing relocation helper: the upgrade
must **refresh the CONTENT** of the depth-sensitive scripts (not merely `git mv` them),
because a relocated-but-not-refreshed script keeps its pre-T-007 one-up root derivation
(insight L31 / DO-1). On THIS repo the change ships as a new `skills/harness-upgrade/`
+ a new `upgrade-project.{ps1,sh}` template (mirrored into dogfood via the existing
`sync-self` set), plus the standard skill-count 12→13 + version 0.22.0→0.23.0 fan-out.
No new `{{...}}` placeholder is introduced (the verify_all template uses only already-
whitelisted `{{PROJECT_NAME}}` / `{{STACK}}` / `{{TODAY}}`), so the D.2 whitelist is
untouched.

---

## 2. Affected modules (real file paths)

### New artifacts

| Path | Kind | Notes |
|---|---|---|
| `skills/harness-upgrade/SKILL.md` | New skill (distributed = source of truth) | The AI/judgment layer. See §3.1. |
| `skills/harness-init/templates/common/.harness/scripts/upgrade-project.ps1` | New helper (template = canonical copy the skill reads from cache) | The deterministic layer. See §3.2. |
| `skills/harness-init/templates/common/.harness/scripts/upgrade-project.sh` | New helper (bash mirror) | Symmetric pair (NFR-1 / B-11). |
| `.harness/scripts/upgrade-project.ps1` | Dogfood mirror (via `sync-self`) | For THIS repo's own F.1/E.1 symmetry. See §4. |
| `.harness/scripts/upgrade-project.sh` | Dogfood mirror (via `sync-self`) | " |
| `.harness/scripts/test-harness-upgrade.ps1` | New regression driver | See §8. |
| `.harness/scripts/test-harness-upgrade.sh` | New regression driver | " |

### Edited artifacts (ship-on-THIS-repo fan-out — full list in §7)

`.harness/scripts/sync-self.{ps1,sh}` (add `upgrade-project` to the mirror set),
`.harness/scripts/verify_all.{ps1,sh}` (skill-count arrays C.1/G.1/G.2 + optional F.1
pair add), the same two files' template equivalents are not needed (verify_all is
dogfood-only; user-project verify_all is regenerated), `AI-GUIDE.md`,
`README.md`, `README.zh-CN.md`, `docs/getting-started.md`, `docs/dev-map.md`,
`docs/manual-e2e-test.md`, `CHANGELOG.md`, `.claude-plugin/plugin.json`,
`.claude-plugin/marketplace.json`, `docs/tasks.md`, and the verify_all B.* delimiter
comments in the six `skills/harness-init/templates/<type>/.harness/scripts/verify_all.{ps1,sh}.tmpl`
files (see §4 + §6 for why and the symmetry obligation that follows).

### Skill source-of-truth correction (important)

The requirement and the dispatch prompt both assumed the skill source lives at
`.harness/skills/harness-upgrade/SKILL.md` and reaches `.claude/skills/` via
`harness-sync`. **That is not how THIS repo works.** Verified by reading:
- `Glob .harness/skills/**` → **no files** (the directory does not exist here);
- `Glob .claude/skills/*/SKILL.md` → **no files**;
- `.claude-plugin/plugin.json:24` → `"skills": "./skills/"` — the plugin declares the
  distributed `skills/` tree directly as its skill source;
- `.harness/scripts/verify_all.ps1:68-72` (C.1), `:300-305` (G.1), `:326-331` (G.2)
  all check `skills/<name>/SKILL.md`, never `.harness/skills/`;
- `.harness/scripts/harness-sync.ps1:80-104` copies `.harness/skills/ → .claude/skills/`
  but that branch is a no-op here because `.harness/skills/` is absent, so E.2 is
  unaffected by a new `skills/<name>/` skill.

**Decision:** the skill has a SINGLE source-of-truth surface in this repo:
`skills/harness-upgrade/SKILL.md`. There is no `.harness/skills/` copy and no
`.claude/skills/` sync step. This matches exactly how `harness-batch` (T-006) and all
12 current skills ship (`Glob skills/*/SKILL.md` → 12 results, none mirrored under
`.harness/skills/`). DO-6's "skill source under `.harness/skills/`" wording is a
template-generalization that does not apply to the dogfood repo; honor the repo's
real model.

---

## 3. Module decomposition (the AI ↔ script contract)

The split follows the project principle (`00-core.md`): **mechanical/deterministic →
script; judgment/semantic → AI** (RESOLVED OQ-1 = skill + one helper).

### 3.1 `skills/harness-upgrade/SKILL.md` — the judgment layer

Frontmatter (mirrors `harness-adopt`'s tool set; `Bash`+`PowerShell` to run the helper,
`AskUserQuestion` for type detection):

```yaml
---
name: harness-upgrade
description: Upgrade an already-initialized but stale harness project to the current
  plugin layout — relocate scripts to .harness/scripts/, re-install the pre-commit
  hook, rewire settings hook paths, regenerate verify_all from the current type
  template — non-destructively, idempotently, with a dry-run preview, then prove it
  with a green verify_all. Use when a project HAS harness but is OLD; for projects
  with no harness at all use /harness-adopt.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, PowerShell, AskUserQuestion, TodoWrite
---
```

**Responsibilities (judgment only):**

1. **Target & precondition gate (B-1, BC-1/BC-2, OQ-8/BC-10).**
   - Confirm cwd has `.git/` (else halt → BC-1).
   - Confirm SOME harness setup exists: `.claude/settings.json` OR `.harness/` OR
     top-level `scripts/harness-sync.*`. If none → halt, point at `/harness-adopt`
     (BC-2 / OOS-1 / AC-11).
   - Refuse on a dirty working tree (`git status --porcelain` non-empty) with
     "commit or stash first" (OQ-8 / BC-10 / NFR-2). This preserves the `git reset`
     rollback path for all tracked edits.
2. **Template-cache + version discovery (B-13 / AC-12, BC-5).** See §5.
3. **Project-type detection (OQ-4 / BC-9 / AC-4).** Detect-then-**ASK** via
   `AskUserQuestion`, pre-filled. Never silently guess. See §6 "type source".
4. **Self-bootstrap the helper (B-3 / BC-4 / AC-9).** Copy `upgrade-project.{ps1,sh}`
   (and `migrate-scripts-layout.{ps1,sh}` if the helper internally shells to it — see
   §3.2 decision) from the resolved template cache into the project's
   `.harness/scripts/`. Must not assume they pre-exist.
5. **Plan (dry-run) → confirm → apply.** Invoke the helper with `--dry-run` first,
   parse its machine-readable plan (§3.2 stdout contract), present the gap report +
   plan to the user, then on confirmation invoke the helper for real.
6. **verify_all-refresh confirm decision (OQ-3 / AC-13).** The helper reports whether
   the project's `verify_all` B.* region can be cleanly spliced or must halt for
   confirmation. The skill owns the user-facing confirm in the HALT branch (the
   helper exits with a dedicated code; see §3.2 + §6).
7. **Final gate + report (B-8 / AC-8).** Run `verify_all`, surface PASS/WARN/FAIL
   verbatim (never swallow a non-zero result), and print the summary (starting state,
   target version, every file added/moved/rewritten/rewired, `.bak` locations).

The skill does **no** path string-replacement, no `git mv`, no settings byte-editing,
no template substitution itself — all of that is the helper's job (testable as a unit,
cross-shell-parity-checkable).

### 3.2 `upgrade-project.{ps1,sh}` — the deterministic layer

**CLI surface** (PS switch / bash long-flag, symmetric with the existing helpers'
convention — cf. `migrate-scripts-layout.ps1:20-24` `-DryRun`/`-Force`):

| PS flag | bash flag | Meaning |
|---|---|---|
| `-DryRun` | `--dry-run` | Print the full plan as machine-readable lines; change nothing (B-9 / AC-7). |
| `-Force` | `--force` | Overwrite existing relocation targets (passthrough to relocation's `-Force`, BC-12). |
| `-Type <t>` | `--type <t>` | Project type: `fullstack`\|`backend`\|`generic`. Supplied by the AI after OQ-4 detection. Drives which `verify_all.<type>.tmpl` to regenerate from. |
| `-Stack <s>` | `--stack <s>` | Free-text stack string for `{{STACK}}` substitution (required when `--type generic`; the AI collects it from the user — BC-9). |
| `-ProjectName <n>` | `--project-name <n>` | `{{PROJECT_NAME}}` substitution; defaults to cwd basename if omitted. |
| `-TemplateRoot <p>` | `--template-root <p>` | Absolute path to the resolved plugin template cache root (the dir that contains `skills/harness-init/templates/`). The AI passes the path it resolved in §5 so the helper does no cache discovery of its own (keeps the helper a pure deterministic transform). |
| `-Today <d>` | `--today <d>` | `{{TODAY}}` value (`YYYY-MM-DD`); defaults to system date. Passing it makes dry-run output reproducible for tests. |

**Run-from:** project root (cwd-based, like `migrate-scripts-layout` —
`migrate-scripts-layout.ps1:29` `$root = (Get-Location).Path`). The helper itself is
cwd-derived (depth-independent), so it works whether invoked from `scripts/` (during
bootstrap, before relocation) or `.harness/scripts/` (after).

**Internal steps (each idempotent — §6):**

- **S1 Relocation.** Reuse the EXACT known-set + git-mv-preserving + SKIP-unless-Force
  logic of `migrate-scripts-layout` (read at `.harness/scripts/migrate-scripts-layout.ps1:42-85`).
  Decision: **inline this logic into `upgrade-project`** rather than shelling out, so
  the upgrade is a single self-contained helper and the skill bootstraps ONE pair (not
  two). The known set is copied verbatim from the relocation helper (`verify_all.*`,
  `harness-sync.*`, `guard-rm.*`, `install-hooks.*`, `archive-task.*`, `baseline.json`).
  *(`migrate-scripts-layout.{ps1,sh}` is still bootstrapped by the skill for B-2(b)/B-3
  parity reporting and because the project should END with the current helper present,
  but `upgrade-project` does not call it.)*
- **S2 Content-refresh of depth-sensitive scripts (the L31/DO-1 fix — §3.3).** For each
  script in the **refresh set** (see §3.3), overwrite the project copy at
  `.harness/scripts/<name>` with the current template copy from `--template-root`,
  byte-for-byte. This is what guarantees correct two-up root derivation; relocation
  alone does not.
- **S3 Settings rewire.** Reuse the surgical raw-text replace from
  `migrate-scripts-layout.ps1:92-112` verbatim (the three `.Replace(...)` /
  `sed -e` transforms + the `.harness/.harness/` collapse fixed-point + `.bak`).
  **Never re-serialize JSON** (DO-3 / L30). Skip entirely with a logged note if
  `.claude/settings.json` is absent (OQ-9 / BC-15 / AC-3 N/A branch).
- **S4 Hook (re)install.** Detect the current `.git/hooks/pre-commit`:
  - absent → install stock hook (BC-6).
  - present AND byte-matches the stock hook body (current OR the old `scripts/`-path
    variant) → re-install current stock hook (idempotent; `.bak` first).
  - present AND non-stock → **do NOT overwrite**; emit a `CONFLICT` plan line; the
    skill surfaces it (OQ-7 / BC-7). Detection compares against the two known stock
    bodies (current `.harness/scripts/harness-sync.*` body from
    `install-hooks.ps1:35-63`, and the old `scripts/harness-sync.*` body — a single
    path substring distinguishes them).
- **S5 verify_all regenerate.** See §6 in full (delimiter splice or halt-for-confirm,
  placeholder substitution, `.bak`).

**Exit codes** (so the AI can branch deterministically):

| Code | Meaning |
|---|---|
| `0` | Success (changes applied) OR already-current / nothing-to-do OR dry-run printed. |
| `1` | User/precondition error (not a harness project; missing `--template-root`; bad `--type`). |
| `2` | **Refresh-blocked**: verify_all B.* region could not be cleanly delimited AND `--force` was not given → the AI must show the user the diff and re-invoke with `--force` (or abort). (OQ-3 halt branch.) |
| `3` | Hook conflict surfaced (non-stock pre-commit). Non-fatal to the rest of the run; the helper finishes other steps and reports the conflict; the AI relays it. *(Implementation note: codes 2 and 3 are distinct so the AI can tell "I stopped before verify_all" from "I finished but a hook needs your attention".)* |

**stdout contract (machine-readable plan/result the AI parses).** One record per line,
pipe-delimited, prefixed by a stable verb so the AI can grep without locale/格式 issues:

```
PLAN|<verb>|<detail>
RESULT|<verb>|<detail>
GAP|<id>|<present|absent>|<detail>
TYPE|<detected-or-given>
TARGET-VERSION|<x.y.z>
BAK|<path>
CONFLICT|<kind>|<detail>
SUMMARY|added=<n> moved=<n> rewritten=<n> rewired=<n> conflicts=<n>
```

`<verb>` ∈ `MOVE | REFRESH | REWIRE | HOOK-INSTALL | HOOK-SKIP | VERIFY-REGEN |
VERIFY-SPLICE | VERIFY-HALT | SKIP | NOOP`. `<id>` for `GAP` ∈ B-2's a..e. This is the
same human-readable-but-parseable shape the existing helpers already print
(`migrate-scripts-layout` prints `MOVE  scripts/x -> .harness/scripts/x` /
`SKIP  ...` / `EDIT  ...`); we formalize the prefix so the AI layer never has to
fuzzy-parse prose.

### 3.3 The refresh set vs. relocate-only set (root-derivation map)

Grounded in the actual root-derivation idioms read from each script:

| Script | Root derivation (verified) | Depth-sensitive? | Upgrade action |
|---|---|---|---|
| `harness-sync.{ps1,sh}` | `Split-Path (Split-Path $PSScriptRoot -Parent) -Parent` (two-up) — `harness-sync.ps1:23` | **YES** | **relocate + content-refresh (S2)** |
| `install-hooks.{ps1,sh}` | two-up — `install-hooks.ps1:20`, `install-hooks.sh:19` | **YES** | **relocate + content-refresh (S2)** |
| `archive-task.{ps1,sh}` | two-up — template `archive-task.ps1:25` | **YES** | **relocate + content-refresh (S2)** |
| `guard-rm.{ps1,sh}` | `(Get-Location).Path` / cwd — template `guard-rm.ps1:40` | no (cwd-relative by design) | relocate + content-refresh (S2) for currency anyway |
| `migrate-scripts-layout.{ps1,sh}` | `(Get-Location).Path` / cwd — `migrate-scripts-layout.ps1:29` | no | relocate + content-refresh (S2) |
| `verify_all.{ps1,sh}` | `$root = (Get-Location).Path` / cwd — template `verify_all.ps1.tmpl:21` | no | **regenerate from `.tmpl` (S5)**, not a flat copy (has placeholders) |
| `baseline.json` | data file | n/a | relocate-only |
| `ai-native-mock.json` | data file (template only) | n/a | not in known-set; ignore |

**Refresh set (S2 byte-copies from template):** `harness-sync`, `install-hooks`,
`archive-task`, `guard-rm`, `migrate-scripts-layout` (both shells each). **Regenerate
set (S5):** `verify_all` (both shells). **Relocate-only:** `baseline.json`.

This is the **crux resolution**: B-4 (relocate) + B-6 (refresh) + B-12 (root
correctness) reconcile as — *relocate everything in the known set, then content-refresh
every depth-sensitive script from the current template (which already carries correct
two-up derivation), and regenerate verify_all from the type `.tmpl`.* A relocated
script never keeps stale one-up derivation because the depth-sensitive ones are
unconditionally overwritten with the current two-up template content. (See §9 Risk R1.)

---

## 4. Where every artifact lives + the full ship path

### 4.1 The skill

- **Source of truth = `skills/harness-upgrade/SKILL.md`** (the distributed tree; see
  §2 correction). No `.harness/skills/` copy, no `.claude/skills/` sync. `plugin.json`
  `"skills": "./skills/"` picks it up automatically.

### 4.2 The helper `upgrade-project.{ps1,sh}`

- **Canonical copy (what the skill reads from the plugin cache) =**
  `skills/harness-init/templates/common/.harness/scripts/upgrade-project.{ps1,sh}`.
  This is the copy that ends up at
  `~/.claude/plugins/cache/.../skills/harness-init/templates/common/.harness/scripts/`
  in a user install, exactly alongside the existing `migrate-scripts-layout.{ps1,sh}`
  (verified present at that template path via `Glob`).
- **Dogfood copy =** `.harness/scripts/upgrade-project.{ps1,sh}`, maintained
  **byte-identical** to the template via the existing `sync-self` mirror set.

**Mirroring decision: ADD `upgrade-project` to the `sync-self` set** (not hand-lockstep).
Rationale, grounded in code:
- `sync-self.ps1:41-53` already mirrors `migrate-scripts-layout.{ps1,sh}` (its closest
  sibling — same "relocation helper" family, same template-common location). Adding
  `upgrade-project` to the same set is consistent and gives a `verify_all`-enforced
  byte-identity guarantee (E.1 drift check) for free.
- This differs from the `ambient-*` precedent (AI-GUIDE.md:78-79 — ambient scripts are
  NOT in `sync-self`'s set, hand-lockstep). Ambient scripts were excluded because they
  are Claude-Code-hook-specific and were added late; `upgrade-project` is a
  general-purpose maintenance helper in the same family as the already-mirrored
  `migrate-scripts-layout`, so the consistent choice is to mirror it.
- **Consequence (insight L12):** edit `sync-self.ps1` AND `sync-self.sh` mapping arrays
  to add two rows each (`upgrade-project.ps1`, `upgrade-project.sh`). `verify_all` E.1
  will then enforce template↔dogfood byte-identity; if the two ever drift, E.1 FAILs.
  This is the intended forcing function.

### 4.3 Does the helper need to ship to USER projects?

Yes, transitively, and that is already handled: the helper lives under
`templates/common/.harness/scripts/`, so **`/harness-init` and `/harness-adopt` already
copy the whole `templates/common/.harness/scripts/` tree into new projects** (cf.
`harness-adopt` SKILL plan, "Files I will add" → `.harness/scripts/...`). So future
init'd projects get `upgrade-project` for free. For OLD projects being upgraded, the
skill **bootstraps it from the cache** (B-3 / S-step 4). The dogfood `.harness/scripts/`
copy exists purely for THIS repo's own F.1/E.1 symmetry (the repo dogfoods its own
helper presence), not because the dogfood repo ever runs the upgrade on itself (OOS-7).

---

## 5. Template-cache + version discovery at runtime (B-13 / AC-12 / BC-5)

The skill must find the plugin cache from inside an arbitrary user project, then read
the target version. Resolution strategy, in order (first hit wins), mirroring how
`/harness-adopt` locates templates ("typically at `~/.claude/skills/harness-init/templates/`",
SKILL.md:171) but hardened for the plugin-cache layout the real incident showed:

1. **Env var** `CLAUDE_PLUGIN_ROOT` if set (Claude Code exposes the active plugin root
   to skills); template root = `$CLAUDE_PLUGIN_ROOT/skills/harness-init/templates`.
2. **Versioned plugin cache glob:**
   `~/.claude/plugins/cache/harness-kit-marketplace/harness-kit/*/skills/harness-init/templates`
   — if multiple versions match, pick the **highest semver** directory (that is the
   currently-installed target; the skill reports it).
3. **Marketplace-less / dev install:**
   `~/.claude/plugins/cache/*/harness-kit/*/skills/harness-init/templates` then
   `~/.claude/skills/harness-init/templates` (the adopt-era fallback).
4. **Fail (BC-5):** if none resolve, **halt with an actionable message** ("could not
   locate the harness-kit plugin template cache; reinstall the plugin or pass the path
   manually") and change nothing. The helper is never invoked.

**Target version** = read `version` from the **resolved** template root's sibling
`.claude-plugin/plugin.json` — i.e. discover the cache root (`<...>/harness-kit/<ver>/`)
and read `<that>/.claude-plugin/plugin.json` `version` (and cross-check the directory's
`<ver>` segment). The skill prints `TARGET-VERSION|<x.y.z>` and the project's detected
starting state in the plan (AC-12). The resolved template root is passed to the helper
as `--template-root` (§3.2) so the helper does zero discovery — discovery is judgment
(fallbacks, "which version") and stays in the AI layer; the transform is deterministic
and stays in the helper.

The DO part of B-13/AC-12 (the cache path shape) is thus captured explicitly:
`<cache>/harness-kit-marketplace/harness-kit/<version>/skills/harness-init/templates/common/.harness/scripts/upgrade-project.*`
is the canonical bootstrap source.

---

## 6. verify_all refresh mechanism (OQ-3 baseline, in concrete detail)

**Goal (RESOLVED OQ-3):** FULL-REGENERATE `verify_all.{ps1,sh}` from the type `.tmpl`,
but **NEVER silently lose the user's B.\* customizations**. Always `.bak` the old file.

### 6.1 The B.* delimiter (read from the real template)

I read the current generic template. The B.* region is bounded by stable section
comments:

- **Start (bash, `verify_all.sh.tmpl:48`):**
  `# --- B. Build / test / lint (CUSTOMIZE FOR {{STACK}}) ---`
- **End (bash, `verify_all.sh.tmpl:55`):** the next section header
  `# --- E. Project structure (Harness required) ---`
- **Start (PS, `verify_all.ps1.tmpl:70`):**
  `# --- B. Build / test (CUSTOMIZE FOR {{STACK}}) ---`
- **End (PS):** the next `# --- ` section header.

**Problem found:** the START comment is *not byte-stable across versions/types*
(generic PS says "Build / test", generic sh says "Build / test / lint"; fullstack/backend
overlays may differ), and the END is "the next `# --- X.` header" which is heuristic.
Splicing on a heuristic boundary risks a partial splice (the rejected failure mode).

**Decision (allowed by the baseline):** ADD a pair of **stable, version-independent
delimiter comments** around the B.* region in ALL SIX type templates' verify_all
`.tmpl` files (generic/fullstack/backend × ps1/sh). Exact literals (no placeholders, so
no D.2 impact — see §6.4):

```
# >>> HARNESS:B-CUSTOM:BEGIN (your build/test/lint checks live here; preserved across /harness-upgrade) <<<
...existing B.1/B.2/B.3 stub or user checks...
# >>> HARNESS:B-CUSTOM:END <<<
```

These markers are literal ASCII, identical in both shells (a `#` comment is valid in
both PowerShell and bash), so the splice/detect logic is byte-identical cross-shell.
Because we MODIFY the six templates, this triggers the **template↔dogfood symmetry +
test-init** obligations (F.1-family: the generated verify_all changes shape), NOT a
D.2/placeholder change. (DO note: the dogfood `.harness/scripts/verify_all.{ps1,sh}` is
the REPO's own bespoke verify_all — different file, NOT generated from the template —
so it does NOT need these markers; only the user-project templates do. Confirmed: the
dogfood verify_all is "Verification for the harness-engineering repo itself",
`verify_all.ps1:1`, and is not produced by substitution.)

### 6.2 The refresh algorithm (S5)

```
1. .bak the old project verify_all.{ps1,sh}  →  verify_all.ps1.bak-<ts> / .sh.bak-<ts>   (always)
2. Render the fresh file from <template-root>/skills/harness-init/templates/<type>/
   .harness/scripts/verify_all.<shell>.tmpl with placeholder substitution:
     {{PROJECT_NAME}} ← --project-name (default cwd basename)
     {{STACK}}        ← --stack        (required when type=generic)
     {{TODAY}}        ← --today        (default today)
   (These are the ONLY placeholders the template contains — verified by reading the
    template; all three are already in the D.2 whitelist, verify_all.ps1:95.)
3. B.* preservation:
   a. In the OLD file, locate the region between HARNESS:B-CUSTOM:BEGIN and :END.
      - If BOTH markers are present AND uniquely matched (exactly one BEGIN, one END,
        BEGIN before END):  this is a "clean delimiter".
      - Determine whether the user customized B.*: the captured block differs from the
        template's stub block (i.e. it is NOT just the three "SKIP"/TODO stubs).
   b. Decision matrix:
      - Clean delimiter + user-customized  → SPLICE: replace the fresh file's
        BEGIN..END region with the OLD captured block verbatim. Emit
        VERIFY-SPLICE|<shell>. (Preferred path; OQ-3 preferred mechanism.)
      - Clean delimiter + stub-only (no customization) → take the fresh template region
        as-is (nothing to preserve). Emit VERIFY-REGEN|<shell>.
      - NO clean delimiter (old file predates the markers — the common old-fixture
        case) AND the old B.* region appears customized (heuristic: any B.* Step/step
        line whose body is not a bare SKIP/TODO) → **HALT** unless --force:
        emit VERIFY-HALT|<shell>, exit 2. The AI shows the user the old B.* block +
        the .bak path and asks to confirm overwrite (re-invoke with --force) or abort.
      - NO clean delimiter AND old B.* is stub-only → safe to full-regenerate
        (nothing of value to lose). Emit VERIFY-REGEN|<shell>.
   c. With --force on the HALT branch: full-regenerate (B.* reset to template stub);
      the .bak already preserves the user's old checks for manual re-apply.
4. Write the fresh (possibly spliced) file. Idempotence: if the freshly-rendered file
   is byte-identical to the existing one, skip the write and the .bak (NOOP|verify_all).
```

This satisfies OQ-3's hard constraint exactly: **preferred** = verbatim splice of the
single well-delimited B.* block; **fallback** (region not cleanly identifiable) = HALT
for explicit confirmation. Pure-merge-of-all-checks is never used. AC-13's
"full-regenerate" branch is the `--force`/stub-only path with the loud `.bak` + warning;
AC-13's "merge-in" branch is the SPLICE path. Both branches are testable (§8).

### 6.3 Project-type source for substitution (OQ-4 / BC-9)

The AI determines `--type` BEFORE invoking the helper, by **detect-then-ASK**:
1. Pre-fill from `.harness/rules/50-<type>.md` filename (the only stored type signal;
   e.g. `50-fullstack.md` → fullstack). If absent, pre-fill from the old verify_all's
   `=== verify_all (<type>) ===` header line (template emits this at
   `verify_all.sh.tmpl:24` / `verify_all.ps1.tmpl:51`).
2. **Always** confirm via `AskUserQuestion` (pre-filled). Never silently guess (BC-9).
3. For `generic`, `{{STACK}}` cannot be recovered reliably → the AI collects it as
   free text from the user and passes `--stack`. (Non-generic templates hardcode their
   stack text, but `--stack` is still accepted/forwarded for the substitution the
   template expects.)

### 6.4 D.2 / placeholder impact: NONE

The new delimiter comments contain **no `{{...}}`** — they are literal ASCII. The
substitution set stays `{{PROJECT_NAME}}`, `{{STACK}}`, `{{TODAY}}`, all already
whitelisted (`verify_all.ps1:95`). **No D.2 whitelist edit is needed** (DO-2 satisfied
by reuse, the preferred outcome). The skill introduces zero new placeholders anywhere.

---

## 7. Ship-this-on-THIS-repo checklist (AC-14 / AC-15 / DO-4 / DO-5)

This is the part most likely to break `verify_all` here. Grounded in the T-006
(`harness-batch`) precedent (`07_DELIVERY.md` lists the exact 15-file fan-out) and the
live check sites I read.

### 7.1 Skill-count 12 → 13 (DO-4)

| File | Site | Change |
|---|---|---|
| `.harness/scripts/verify_all.ps1` | C.1 `:68-72`, G.1 `:300-305`, G.2 `:326-331` | Add `"harness-upgrade"` to all 3 arrays; rename `"All 12 skills..."` → `"All 13 skills..."`, `"...all 12 skills"` → `"...all 13 skills"`. |
| `.harness/scripts/verify_all.sh` | C.1 `:56`, G.1 `:330`, G.2 `:346` (the `for s in ...` lists) | Add `harness-upgrade` to all 3 loops; update the 3 step names to 13. |
| `AI-GUIDE.md` | `:7` ("distributes 12 skills") | → 13; add `/harness-upgrade` to the workflow-entry table (§ "Workflow entry"). |
| `README.md` | `:7` ("12 skills"), `:13` ("twelve AI skills"), the skills section, Roadmap | → 13 / "thirteen"; add a `/harness-upgrade` bullet + Roadmap row. |
| `README.zh-CN.md` | `:7` ("12 个 skills"), `:13` ("12 个 AI skill") | → 13; add bullet. |
| `docs/getting-started.md` | skill list `:38-57` (Setup or Operations group) | Add `- \`harness-upgrade\` — upgrade an old harness project to the current layout`. |
| `docs/dev-map.md` | skills tree `:43-44` area | Add a `harness-upgrade/SKILL.md` line. |
| `docs/manual-e2e-test.md` | `:34`, `:49` ("all 12 skills") + skill enumerations | → 13 + add `harness-upgrade` to the enumerations (T-006 touched "5 count phrases + 3 enumerations"). |
| `CHANGELOG.md` | top | New `[0.23.0]` section describing the skill + helper + version bump. Must mention `harness-upgrade` (G.2 also scans CHANGELOG). |

### 7.2 Version 0.22.0 → 0.23.0 (DO-4, G.3-gated)

| File | Site | Change |
|---|---|---|
| `.claude-plugin/plugin.json` | `:4` `"version"` | `0.22.0` → `0.23.0`. |
| `.claude-plugin/marketplace.json` | `:21` `plugins[0].version` | `0.22.0` → `0.23.0`. |
| `README.md` | badge `:5` `version-0.22.0-blue` | `version-0.23.0-blue`. |
| `README.zh-CN.md` | version badge | `0.23.0`. |

G.3 (`verify_all.ps1:333-355`) FAILs unless plugin.json / marketplace.json / both
README badges all read `0.23.0`. (G.3 already passed me the exact regex
`version-(\d+\.\d+\.\d+)-`.)

### 7.3 New verify_all check? — **NO new lettered check for v1**

Analysis (per the dispatch's "consider whether a new check is even needed"):
- **F.1** already guarantees the .ps1/.sh pair existence model. Adding `upgrade-project`
  to F.1's name+list (`verify_all.ps1:270-271`) is **optional symmetry coverage**;
  recommended, because the helper is a parity-critical pair. **But note:** F.1 is a
  *named selective list*, NOT count-anchored — adding to it changes the step NAME, not
  the recorded check COUNT. So it does **not** move G.4's count and is **not**
  version-count-worthy. (It IS worth doing so the helper pair is regression-guarded.)
- **E.1** (template↔dogfood byte-identity) will automatically cover
  `upgrade-project.{ps1,sh}` once they are added to the `sync-self` mirror set (§4.2) —
  no new check needed; the existing E.1 enforces it.
- **E.2 / harness-sync** is unaffected (no `.harness/skills/`).
- **G.3/G.4** already cover the version + count claims.

**Therefore: do NOT add a new lettered `verify_all` check.** This keeps the recorded
check count stable at **32**, so **G.4's count claims (`32/32`, `32 checks`, etc.) do
NOT move** and the README `verify__all-32%2F32` badge stays. The ONLY version-worthy
claim that moves is the **skill count** (12→13) and the **version** (0.23.0). This is
the lighter, correct path: a new skill is version-worthy (L33) but does not by itself
add a check (T-006 confirmed: "`verify_all_checks` stays at 31, no new checks").

> If the Gate insists on adding `upgrade-project` to F.1: do it; it changes only the
> F.1 step *name* string in both shells and adds 2 `Test-Path`/`-f` lines — zero count
> impact, so no G.4 ripple. Treat as optional polish, not a count change.

### 7.4 Same-file expect-uniqueness (DO-5 / L36)

For every claim touched: the changed literals are version/count tokens already audited
for uniqueness by G.4's table (`verify_all.ps1:654-664`). Since we are NOT changing the
check count (32 stays), G.4's `(32 checks)` / `32/32` rows are untouched — no
uniqueness risk introduced there. The skill-count claims (C.1/G.1/G.2 names "13
skills") are step-NAME strings, not whole-file `.Contains` claims, so the L36 trap does
not apply to them. The README/AI-GUIDE prose "13 skills" / "thirteen" are human prose,
not gate-`expect` literals. **No new same-file-uniqueness hazard is created.** (We
explicitly do NOT collapse any two count phrases into a subset relationship — the
T-010 trap.)

---

## 8. Regression-test plan stub (for QA / Dev)

New pair **`.harness/scripts/test-harness-upgrade.{ps1,sh}`** (matches the existing
`test-*.{ps1,sh}` convention — `test-init`, `test-supervisor`, `test-guard-rm`,
`test-verify-i6`). Drives the helper against synthetic fixtures built in a `mktemp`/
`New-Item -ItemType Directory` temp dir with `git init`, then asserts end-state.

**Fixtures (each its OWN temp dir — insight L22, no shared `$tmp`):**

| Fixture | Setup | Asserts (AC) |
|---|---|---|
| `old-baseline` | scripts under top-level `scripts/` (incl. OLD one-up `harness-sync.*`), NO `migrate-scripts-layout.*`, stock pre-commit at old `scripts/harness-sync.*` path, old short `verify_all`, `.claude/settings.json` with old paths | AC-1 (relocated + custom untouched), AC-2 (hook → `.harness/scripts/`), AC-3 (settings rewired + parses), AC-4 (current check ids + no `{{...}}`), **AC-5 (relocated harness-sync runs and finds root — directly exercises the L31 two-up fix)**, AC-9 (self-bootstrap completed) |
| `old-baseline` re-run | run upgrade twice | AC-6 (idempotent: 2nd run NOOP, clean `git status`) |
| `old-baseline` dry-run | `--dry-run` | AC-7 (full plan printed, byte-for-byte unchanged) |
| `custom-hook` (BC-7) | non-stock pre-commit | hook NOT overwritten; CONFLICT surfaced (exit 3) |
| `custom-verify` (BC-8) | verify_all with a real `B.1` build check inside the markers | SPLICE preserves it (AC-13 merge branch); and a no-marker customized variant → HALT exit 2 (AC-13 regenerate-warn branch) |
| `dirty-tree` (BC-10) | uncommitted change | refuse, no changes |
| `non-cc` (BC-15) | `.harness/scripts/` present, NO `.claude/settings.json` | scripts+hooks+verify_all refreshed, settings rewire SKIPPED with note (OQ-9) |
| `no-harness` (BC-2) | bare git repo | halt, point to `/harness-adopt` (AC-11) |
| cross-shell parity | run `old-baseline` from ps1 AND from sh on fresh copies | AC-10 (equivalent end-state) |

**Exempt-list note (insight L26 / DO):** `test-harness-upgrade.{ps1,sh}` will embed
fixture verify_all snippets that contain `{{STACK}}` etc. (to build old-fixtures) and
may embed `HARNESS:B-CUSTOM` markers. If it embeds any `{{...}}` literal under
`skills/harness-init/templates/` scanning OR any I.6-banned phrase, it must be added to
the relevant exempt list — but since the test files live at `.harness/scripts/` (NOT
under `skills/harness-init/templates/`), **D.2 does not scan them** (D.2 only globs
`skills/harness-init/templates/**/*.{tmpl,append}`, `verify_all.ps1:96-98`). They are
also outside `docs/features/`. So: if a fixture string trips I.6, add the two test
files to the I.6 `$exempt` list (`verify_all.ps1:516-524`), exactly as
`test-verify-i6.{ps1,sh}` were added. Flag for Dev to check after writing.

Do NOT add `test-harness-upgrade` to F.1 (F.1 lists only `test-init`/`test-real-project`
among tests, not every test pair — keeping it out matches the existing selective
convention; the pair's existence is implicitly covered by the test itself running).

---

## 9. Risk analysis

| # | Risk | Likelihood | Mitigation |
|---|---|---|---|
| **R1** | **Stale one-up root derivation survives relocation** (L31/DO-1, the #1 risk). If S2 content-refresh is skipped for any depth-sensitive script, a relocated `harness-sync`/`install-hooks`/`archive-task` keeps one-up derivation and silently resolves the wrong root. | Medium | S2 UNCONDITIONALLY byte-overwrites the entire refresh set from the current template (which is two-up). AC-5 directly tests it (invoke relocated `harness-sync` from project root → must find root). §3.3 enumerates exactly which scripts and why. |
| **R2** | **B.* splice partial-match** corrupts the regenerated verify_all (rejected failure mode). | Medium | Splice ONLY on clean dual-marker delimiter (exactly one BEGIN, one END, ordered). No clean delimiter + customized → HALT (exit 2) for explicit `--force`, never a guessy splice. Always `.bak`. (§6.2) |
| **R3** | **Settings JSON re-serialization** reorders keys / drops `_comment` doc keys (L30/DO-3). | Low | Reuse the EXACT raw-text `.Replace`/`sed` rewire from `migrate-scripts-layout` verbatim; never `ConvertFrom-Json|ConvertTo-Json`. J.1 gates settings integrity at the end. (§3.2 S3) |
| **R4** | **Cache resolution fails / wrong version** picked. | Medium | Ordered fallback chain (§5) with `CLAUDE_PLUGIN_ROOT` first, highest-semver cache dir, adopt-era fallback, then HALT (BC-5) — never proceed with an unresolved root. Report `TARGET-VERSION` for user confirmation. |
| **R5** | **Ship fan-out drift** — skill-count claim left at 12 in one file → C.1/G.1/G.2/G.3 FAIL (L5/L33 recurrence). | High (this is the historically-recurring class) | §7 is an explicit, file-by-file checklist derived from the T-006 delivery's proven 15-file list. Dev runs `verify_all` (the canonical exhaustive scan, L29) after the sweep, and again after the version bump. |
| **R6** | **Template↔dogfood drift** of `upgrade-project` after adding to `sync-self`. | Low | E.1 enforces byte-identity once both rows are added to `sync-self.{ps1,sh}`; drift FAILs the gate. Edit template first, run `sync-self`, then commit. |
| **R7** | **bash portability** in the new `upgrade-project.sh` / `test-harness-upgrade.sh` (L13/L27/DO-7/DO-8). | Medium | New arrays use `arr=()` not `declare -a`; case-insensitive matches use `shopt -s nocasematch` (never `grep -F -i`); loop file vars named `<thing>_file`; Git-bash derived from `git.exe` root in any cross-shell test harness. |
| **R8** | **Edit silent no-op** during the multi-file sweep (L10). | Low | Dev obligation (not architecture): re-Read/Grep after each Edit to the count/version sites; `verify_all` is the backstop. |

---

## 10. Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| Relocation (known-set, git-mv-preserving, SKIP-unless-Force, dry-run, idempotent fixed-point) | `migrate-scripts-layout.{ps1,sh}` | `.harness/scripts/migrate-scripts-layout.ps1:42-130` | **Reuse logic verbatim, inlined** into `upgrade-project` (S1) |
| Settings hook-path rewire (raw-text, `.bak`, `.harness/.harness/` collapse fixed-point) | same helper's settings block | `migrate-scripts-layout.ps1:87-112` / `.sh:85-113` | **Reuse verbatim** (S3); satisfies DO-3 by construction |
| Stock pre-commit hook body + writer | `install-hooks.{ps1,sh}` | `.harness/scripts/install-hooks.ps1:35-65` | **Reuse** for S4 install + as the byte-template for stock-vs-custom detection |
| Plan/confirm/apply + template-cache discovery + non-destructive stance + AskUserQuestion type-detect | `harness-adopt` SKILL | `skills/harness-adopt/SKILL.md` (steps 1,2,3,5,6) | **Mirror the structure** in the new SKILL; harness-upgrade is its old-harness complement |
| Skill packaging (where source lives, how it ships) | the 12 existing skills + `plugin.json` | `skills/*/SKILL.md`, `.claude-plugin/plugin.json:24` | **Reuse the single-surface model** (`skills/<name>/`); no `.harness/skills/` |
| Skill-count + version fan-out checklist | T-006 delivery | `docs/features/_archived/harness-batch-skill/07_DELIVERY.md:19-21` | **Reuse the proven 15-file fan-out** as §7 |
| Template↔dogfood mirroring of a relocation-family helper | `sync-self` mirror set | `.harness/scripts/sync-self.ps1:51-52` (already mirrors `migrate-scripts-layout`) | **Extend** the set with `upgrade-project` |
| verify_all type templates + placeholder set | per-type `.tmpl` | `skills/harness-init/templates/<type>/.harness/scripts/verify_all.{ps1,sh}.tmpl` | **Reuse as regenerate source** (S5); add B.* delimiters only |
| D.2 placeholder whitelist | verify_all D.2 | `.harness/scripts/verify_all.ps1:95` | **Reuse as-is** (no new placeholder → no edit) |
| Hook-installer (current `.harness/scripts/harness-sync.*` path) | the hook already points new | `install-hooks.ps1:42-45` | **Reuse** — current stock hook already references the new path (B-5 satisfied by re-install) |

Reuse audit is non-empty and proves the design extends proven mechanisms rather than
reinventing them. The ONLY genuinely new logic is S2 (content-refresh) + S5 (verify_all
splice/regenerate) + the cache fallback chain — everything else is composition.

---

## 11. Migration / rollout plan

- **Backwards compatibility:** purely additive to the plugin (a new skill + a new
  template helper). Existing skills, scripts, and the init/adopt flows are unchanged
  except the six verify_all templates gain inert B.* delimiter comments (a regenerated
  verify_all still runs identically; the comments are no-ops). `test-init` re-run
  proves the templated output still passes.
- **Feature flags:** none needed; the skill is opt-in (user invokes `/harness-upgrade`).
- **Rollout sequence (Dev order):**
  1. Add B.* delimiter comments to the 6 `verify_all.*.tmpl` files (template edit).
  2. Write `upgrade-project.{ps1,sh}` under `templates/common/.harness/scripts/`.
  3. Add `upgrade-project` rows to `sync-self.{ps1,sh}`; run `sync-self` → dogfood copy.
  4. Write `skills/harness-upgrade/SKILL.md`.
  5. Skill-count fan-out (§7.1) + version bump (§7.2).
  6. Write `test-harness-upgrade.{ps1,sh}`; add to I.6 exempt list only if needed (§8).
  7. Run `test-init` (template change), `test-harness-upgrade` (new), and `verify_all`
     until green (32/32, skill count 13).
- **Rollback:** all changes are git-tracked; `git revert` of the delivery commit fully
  removes the skill + helper + fan-out. The skill's OWN runtime rollback (on a user
  project) is git-clean-tree precondition (OQ-8) + `.bak` for the two untracked
  surfaces (OQ-2 = both).

---

## 12. Out-of-scope clarifications

- **Agent / skill / rule CONTENT refresh** (OQ-5 = scripts-layer ONLY for v1). A future
  `--include-agents` is explicitly deferred (OOS-4).
- **v0.1.x → v0.2.0 `CLAUDE.md` → `.harness/rules/` split** (OQ-6 = post-v0.2 only;
  v0.1 stays manual via `MIGRATION.md`) (OOS-3).
- **Adopting harness into a no-harness project** → `/harness-adopt` (OOS-1).
- **Downgrade** (newer project → older plugin) (OOS-6).
- **Running the upgrade on THIS dogfood repo** (OOS-7); the dogfood `.harness/scripts/`
  copy exists for symmetry only.
- **Package installs / CI edits / network calls** (NFR-3 / OOS-5).
- **Re-serializing `.claude/settings.json`** — never; raw-text only (DO-3).
- **Adding a new lettered `verify_all` check** — deliberately NOT done (§7.3); 32 stays.

---

## 13. Acceptance-criteria traceability

| AC | Satisfied by |
|---|---|
| AC-1 relocate + custom untouched | §3.2 S1 (known-set relocation reused from `migrate-scripts-layout`) |
| AC-2 hook → `.harness/scripts/` | §3.2 S4 + reuse of `install-hooks` stock body |
| AC-3 settings rewired + parses + doc keys kept | §3.2 S3 (verbatim raw-text rewire; DO-3) |
| AC-4 current checks + no `{{...}}` | §6.2 S5 (regenerate from `.tmpl` + full substitution) |
| **AC-5 root two-up correctness** | **§3.3 refresh set + S2 content-refresh (the L31 fix)** |
| AC-6 idempotent | §6.2 step 4 NOOP-on-identical + reuse of fixed-point rewire (§3.2 S3); per-artifact §3.2 |
| AC-7 dry-run unchanged | §3.2 `-DryRun/--dry-run` (reused from relocation helper's dry-run) |
| AC-8 final verify_all surfaced | §3.1 resp. 7 (run + verbatim PASS/WARN/FAIL) |
| AC-9 self-bootstrap | §3.1 resp. 4 + §3.2 (skill copies helper from cache; no pre-existence assumed) |
| AC-10 cross-shell parity | §3.2 symmetric pair + §8 parity fixture (NFR-1) |
| AC-11 no-harness halt → adopt | §3.1 resp. 1 (BC-2) |
| AC-12 detect + report version | §5 (cache + version discovery, `TARGET-VERSION` line) |
| AC-13 B.* preserve/warn | §6.2 SPLICE branch (merge) + HALT/`--force` branch (regenerate-warn) |
| AC-14 ship both surfaces + obligations | §4 (single skill surface; helper template+dogfood) + §7 |
| AC-15 count/version claim consistency | §7 (12→13 + 0.23.0 fan-out; G.3/G.4 PASS) |

---

## 14. Downstream-obligations discharge

| DO | Obligation | Discharged by |
|---|---|---|
| **DO-1** (L31) | Relocated/refreshed scripts derive root two-up | §3.3 refresh set + S2 unconditional content-refresh of depth-sensitive scripts; AC-5 test (§8). Path find/replace is explicitly NOT relied upon. |
| **DO-2** (L11/L20) | New `{{...}}` → both D.2 whitelists | **No new placeholder** introduced (delimiters are literal ASCII; verify_all uses only the 3 already-whitelisted placeholders — `verify_all.ps1:95`). No D.2 edit. (§6.4) |
| **DO-3** (L30) | settings shape change → schema-validate first | **No shape change**: verbatim raw-text rewire reused from `migrate-scripts-layout` (§3.2 S3). J.1 still gates. |
| **DO-4** (L33/L34) | New skill = version + count worthy | §7.1 (skill count 12→13 across all sites) + §7.2 (0.23.0 bump). No new check → check-count claim stays 32 (§7.3). |
| **DO-5** (L36) | Same-file claim uniqueness | §7.4: no new whole-file `.Contains` claim added; G.4's `(32 checks)` rows untouched; no subset-collapse. |
| **DO-6** | Source edits in `.harness/` + `templates/`; no hand-edit of `.claude/`/`CLAUDE.md`/copilot | Skill at `skills/harness-upgrade/` (the repo's real skill SOT), helper at `templates/common/.harness/scripts/` then `sync-self`; no `.claude/` hand-edit proposed. (§4) |
| **DO-7** (L27) | bash: no `grep -F -i`; `shopt -s nocasematch` | §9 R7 + design constraint on `upgrade-project.sh` / `test-harness-upgrade.sh`. |
| **DO-8** (L13) | bash arrays `arr=()`; loop file vars `<thing>_file` | §9 R7 + design constraint. |

---

## 15. Verdict

**READY.**

The design composes three proven mechanisms (relocation + raw-text settings rewire from
`migrate-scripts-layout`, stock-hook install from `install-hooks`, plan/confirm/apply
from `harness-adopt`) plus exactly two pieces of genuinely new logic (S2 content-refresh
that resolves the L31 root-derivation crux, and S5 verify_all splice/regenerate with the
B.* delimiter), introduces **zero** new placeholders (no D.2 change), makes **no**
settings-shape change (no DO-3 re-trigger), and adds **no** new `verify_all` check (check
count stays 32; only the skill count 12→13 and version 0.23.0 move). The skill
source-of-truth model was corrected to match how this repo actually ships skills
(`skills/<name>/` only — no `.harness/skills/`). A junior developer can implement from
§3 (contract), §6 (verify_all mechanism), §7 (ship checklist), and §8 (tests) without
further design decisions.

No `BLOCKED` conditions. The only items the Gate should sanity-check: (a) the decision
to ADD B.* delimiters to the six templates (template↔dogfood + test-init symmetry, §6.1)
rather than splice on heuristic boundaries; (b) the decision to keep check count at 32
(no new lettered check, §7.3). Both are argued from the read code and the resolved
baseline.
