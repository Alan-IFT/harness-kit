# Development Record — Agents Cutover (redesign Leg 1 complete)

## Summary
Switched the harness-kit repo to the **plugin-native agent model**: the 7 framework agents (+ supervisor) are now the single source at the top-level `agents/` (dispatched `harness-kit:<name>`) and are no longer copied into projects. Repointed the verify_all gates, dropped the sync-self agent mirror, switched pipeline dispatch to `harness-kit:<name>`, made `/harness-init` plugin-native by default with a documented `--portable` opt-in, flipped the test assertions, and updated all positioning docs. `verify_all` is 32/0/0 and every regression is green in both shells.

## Files changed

### Gates (verify_all — symmetric)
- `.harness/scripts/verify_all.sh` — D.1 now scans top-level `agents/` + relabeled "Plugin agents present"; E.3 agent-existence points at `agents/pm-orchestrator.md` + `agents/developer.md`; E.4 dropped the `.claude/agents` directory existence requirement; I.3 size-cap scans `agents/`.
- `.harness/scripts/verify_all.ps1` — same four edits, symmetric (D.1 label "Plugin agents present").

### sync-self (symmetric)
- `.harness/scripts/sync-self.sh` — removed both agent-mirror mappings (`.harness/agents`→`.harness/agents` and the v0.29 `.harness/agents`→top-level `agents/`). Script-pair mappings untouched.
- `.harness/scripts/sync-self.ps1` — removed the two `dir-of-md` agent mappings + updated the header doc block.

### Dispatch (plugin skills + plugin pm-orchestrator)
- `skills/harness/SKILL.md` — steps 4-9 now dispatch `harness-kit:{requirement-analyst,solution-architect,gate-reviewer,developer,code-reviewer,qa-tester}`; partition `dev-*` noted as project-local; qa-tester contract ref → "the `harness-kit:qa-tester` agent".
- `skills/harness-plan/SKILL.md` — steps 3-5 → `harness-kit:{requirement-analyst,solution-architect,gate-reviewer}`.
- `skills/harness-goal/SKILL.md` — Developer → `harness-kit:developer`; QA → `harness-kit:qa-tester` (+ contract ref).
- `skills/harness-batch/SKILL.md` — literal dispatch instruction → `harness-kit:pm-orchestrator` (prose mentions left alone).
- `skills/harness-stream/SKILL.md` — literal dispatch instruction → `harness-kit:pm-orchestrator`.
- `agents/pm-orchestrator.md` — Developer-routing section clarifies generics dispatch as `harness-kit:<name>` and partition `dev-*` are project-local; partition-detection glob unchanged.

### Init (default = plugin-native)
- `skills/harness-init/SKILL.md` — two-layer intro rewritten to plugin-native model; added the `--portable` note; frontmatter description softened to "Claude-native by default"; step 3 common/ description (no framework agents); step 4 partitioning prose (generic developer is plugin-provided); step 6 sync scope (partition-only); summary report block.

### Test assertions (symmetric)
- `.harness/scripts/test-init.sh` / `.harness/scripts/test-init.ps1` — 7 generic-agent SOT + generated assertions flipped to ABSENT; AI-native partition-accept simulation now creates `.harness/agents/` before writing (mirrors the SKILL's Write tool, which creates parents); operator-reconciliation note added.
- `.harness/scripts/test-real-project.sh` / `.ps1` — 7 generic-agent SOT + generated assertions flipped to ABSENT (same count, flipped polarity → integration stays 82). **[scope extension — see Design drift]**
- `.harness/scripts/test-supervisor.sh` / `.ps1` — AC-1.* repointed to `agents/supervisor.md`; AC-2 reworked from template byte-identity to the single-plugin-source invariant (no template/`.harness` copy). **[scope extension — see Design drift]**
- `skills/harness-adopt/SKILL.md` — PLAN prose + partition-handling prose updated (generic agents not copied; plugin-provided). **[scope extension — see Design drift]**

### Docs
- `AI-GUIDE.md` — agents section, source-of-truth list, skill-authoring index line, Copilot role-play line, harness-sync/sync-self script lines, editing-rules line; positioning softened to "Claude-native by default; `--portable` for tool-agnostic/offline".
- `README.md` / `README.zh-CN.md` — tagline/positioning, quickstart artifact list, key-features section, repo layout box, dogfood line, design principle 3, test-count line; added a v0.30.0 roadmap row; version badge 0.29.0 → 0.30.0.
- `.harness/rules/40-locations.md` — agent-location rows split (framework → plugin `agents/`; partition `dev-*` → `.harness/agents/`); supervisor + sync rows updated.
- `docs/dev-map.md` — top-level `agents/` added; `.harness/agents/` = partition-only; two-layers section, where-features-live + reusable-utilities tables, patterns-to-avoid, test-init count line.

### Version
- `.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json` — version 0.29.0 → 0.30.0; descriptions softened to plugin-native / Claude-native.
- `CHANGELOG.md` — new `## [0.30.0] - 2026-06-10` "Agents cutover" entry.

## verify_all result
- Baseline (pre-change, per spec): 3 FAILs — D.1, E.3, E.4.
- After changes: **verify_all 32 PASS / 0 WARN / 0 FAIL** in BOTH shells (bash + pwsh).
- Delta: 3 FAILs resolved; no new failures; check count unchanged (32); skill count unchanged (15).

### Regression suite (captured runs, this environment)
| Test | bash | pwsh |
|---|---|---|
| verify_all | 32/0/0 | 32/0/0 |
| test-init | 249/0 (no python3) | 287/0 |
| test-real-project | 82/0 | 82/0 |
| test-supervisor | 45/0 | 49/0 |
| test-verify-i6 | 58/0 | 58/0 |

These match the values already recorded in `.harness/scripts/baseline.json` (test_init_ps=287, test_init_bash=249, test_supervisor_ps=49, test_supervisor_bash=45, test_verify_i6=58/58) — the polarity flip preserved assertion totals, so no count reconciliation appears necessary. Operator should still confirm from their own captured run per the task instruction.

## Design drift (if any)

`DESIGN DRIFT` (all are scope extensions of the spec's stated intent, flagged for reviewer):

1. **`test-real-project.{sh,ps1}` flipped** — the spec's section 5 named only `test-init`, but `test-real-project` carries the identical "7 generic agents present" assertions that the cutover invalidates; leaving them would fail the integration regression (and violate "baseline only goes up"). Applied the same 1:1 polarity flip (present → absent), preserving the 82 count. Symmetric in both shells.
2. **`test-supervisor.{sh,ps1}` repointed** — not in the spec. The supervisor agent moved to `agents/supervisor.md` and its `templates/common` copy was removed, so AC-1.* (path) and AC-2 (template byte-identity) both failed. Repointed AC-1.* to `agents/supervisor.md` (mechanical); **reworked AC-2 from a byte-identity check to a "single plugin source" check** (the byte-identity invariant genuinely retired with the cutover — this is the one structural, not purely mechanical, change). Reviewer should confirm AC-2's new shape is the intended model for the supervisor under plugin-native.
3. **`skills/harness-adopt/SKILL.md` prose** — not named in the spec (only `harness-init`), but its adopt-PLAN template and partition-handling prose still said the 7 generic agents are copied / "only `developer.md` is shipped". Updated to the plugin-native model for consistency with the init SKILL.
4. **Manifest descriptions softened** — the spec asked only for the version bump in `plugin.json`/`marketplace.json`; I also softened their "tool-agnostic .harness/ SOT" description strings to match the new positioning (consistent with the README/AI-GUIDE doc task). Pure prose.

## Open issues for review
- **`baseline.json` metadata field `template_agent_count_baseline: 7`** — this informational field's name predates the cutover (framework agents are no longer "template" agents). It is NOT consumed by any verify_all check (D.1 reads the live `agents/` dir, which has 8 files incl supervisor). Left as-is; operator may want to rename/repurpose it.
- **Distributed templates** (`templates/common/.harness/rules/00-core.md.tmpl`, `templates/generic/.harness/rules/50-generic.md.tmpl`, `templates/common/AI-GUIDE.md.tmpl`) still contain prose referencing framework agents under `.harness/agents/` (e.g. "edits `.harness/agents/solution-architect.md`"). These are the content a *generated user project* gets and were NOT in scope; under `--portable` they remain accurate. Flagging in case the operator wants the distributed templates updated in a follow-up (Leg 2).
- **Frontmatter on the moved agents**: the operator verified (per task context) that the top-level `agents/*.md` carry no plugin-disallowed frontmatter; I did not re-verify that.

## Dev-map updates
Lines added/changed in `docs/dev-map.md`:
- New top-level `agents/` entry (plugin-native framework agents; single source; `harness-kit:<name>`).
- `.harness/agents/` redescribed as partition `dev-*` only (empty in this repo).
- Partition `dev-*.md.tmpl` rows added under the fullstack/backend overlay tree.
- Two-layers-of-consistency section: framework agents no longer mirrored by sync-self.
- where-features-live + reusable-utilities tables, patterns-to-avoid, and the test-init count line updated.

## Insight to surface
A content-cutover that flips "asset present" assertions to "asset absent" has a wider blast radius than the named test: the same present-the-agents invariant lived in FOUR regression scripts (`test-init`, `test-real-project`, `test-supervisor`) and a polarity flip preserves assertion counts (so `baseline.json` need not move) — but `test-supervisor` additionally encoded a template↔dogfood byte-identity invariant that the cutover genuinely retires, which a polarity flip can't express and must be restructured. · evidence: agents-cutover, test-real-project.{sh,ps1} + test-supervisor.{sh,ps1} AC-2 rework, baseline.json counts unchanged

## Verdict
READY FOR REVIEW
