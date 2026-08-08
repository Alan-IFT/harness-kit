## What lives where

| Need | Look at |
|---|---|
| Distributed skills | `skills/<name>/SKILL.md` |
| Project templates (distribution source of truth) | `skills/harness-init/templates/` |
| Framework agent definitions (7 + supervisor) | plugin-native — top-level `agents/`, dispatched as `harness-kit:<name>`. Each is ≤3 KB and carries identity, tool grants, 4–6 degradation-proof hard rules and its verdict vocabulary — nothing else (verify_all I.3) |
| Stage playbooks — the procedure, output schema and worked examples each agent reads on dispatch | `.harness/playbooks/<role>.md` (distributed from `templates/common/`, mirrored by `sync-self`). A subagent's system prompt IS its agent file, so anything needed once per dispatch lives here instead of being resident in every one |
| Partition agent definitions (`dev-*`, project-specific) | `.harness/agents/` (empty in this repo; templates under `skills/harness-init/templates/<type>/.harness/agents/`) |
| Rule source files (this repo's source of truth) | `.harness/rules/` |
| Stub CLAUDE.md (do not edit; ~15 lines, references AI-GUIDE.md) | `CLAUDE.md` |
| Generated .claude/ (do not edit; synced from `.harness/agents/` + `.harness/skills/`) | `.claude/` |
| The 7-agent pipeline definition | `docs/workflow.md` |
| Supervisor agent (auxiliary, v0.17+; not part of 7-stage routing) | plugin-native — `agents/supervisor.md` (`harness-kit:supervisor`) |
| Supervisor skill (manual invocation, v0.17+) | `skills/harness-supervise/SKILL.md` |
| Anti-entropy sweep skill (v0.41+) + its scan reference | `skills/harness-deflate/SKILL.md` + `skills/harness-deflate/references/entropy-scan.md` |
| Entropy-watch cadence pair (shared remind-if-due, F.1 member) | `.harness/scripts/entropy-cadence.sh` (state: gitignored `.harness/entropy-watch.state`) |
| Release-gating operator obligations (the standing list of steps a human must run on a host the agents cannot reach; append here, never into the pin file) | `.harness/operator-obligations.md` |
| Project repo navigation | `docs/dev-map.md` |
| Total verification | `.harness/scripts/verify_all.sh` |
| Binding sync (`.harness/agents/` partition `dev-*` + `.harness/skills/` → `.claude/`) | `.harness/scripts/harness-sync.sh` |
| Repo-self sync (`templates/` script pairs → `.harness/scripts/`; no agent mirror since v0.30) | `.harness/scripts/sync-self.sh` |
| Hook wiring spec — `(hook tool × target OS) → command byte-form` + fail-open/fail-closed semantics + event + matcher (v0.45+, F.1 member) | `.harness/scripts/hook-spec.sh` (distributed from `templates/common/`; consumed by `install-hooks`) |
| Init regression | `.harness/scripts/test-init.sh` |
| Supervisor regression (v0.17+) | `.harness/scripts/test-supervisor.sh` |
| Architecture overview (HTML) | `architecture.html` |
| Project history | `CHANGELOG.md` |
| Why each piece exists / contributor onboarding / user-flow demo | `docs/concepts.md`, `docs/getting-started.md`, `docs/walkthrough.html` |
| Destructive-command `PreToolUse` guard (**fail-CLOSED**) | `.harness/scripts/guard-rm.sh` — see `.harness/rules/75-safety-hook.md` |
| Git pre-commit installer + `settings.local.json` bootstrap from `hook-spec` | `.harness/scripts/install-hooks.sh` — never overwrites an existing file |
| Task archive + insight harvest / rotation | `.harness/scripts/archive-task.sh` |
| Return the UNITS of a document that answer a question, never the document | `.harness/scripts/doc-query.js` — `--in memory\|stage\|rules [--doc <path>] <term>` for a term, `--for <role> --task <slug>` for the stage-contract sections addressed to a role. A term search spends ≤32 KB and reports what it did not print; a finished task is searchable by its `07_DELIVERY.md` until `--task` / `--archived` opens the rest |
| Which role reads which section of which stage contract | `.harness/scripts/stage-schema.js` — `--map`, `--lint --task <slug>` (PM runs it at every stage boundary), `--check` (verify_all D.6) reads the `\| Section \| Shape \|` table back out of `.harness/playbooks/<role>.md` |
| Per-task ledger: stage, rollback counts, verdicts | `.harness/scripts/task-state.js` → `.harness/state/<slug>.json`. PM writes; everyone else reads |
| Contract instructions vs granted tools | `.harness/scripts/capability-audit.js` (verify_all D.4) |
| What this project has DECIDED, declined, learned, and named | `.harness/scripts/memory.js` — `search <question>`, `recent --kind <k>`, `stats`, `roles`. SQLite + FTS5 at `$HARNESS_MEMORY_DB` → `$CLAUDE_PLUGIN_DATA/memory.db` → `.harness/state/memory.db`, **never** under `$CLAUDE_PLUGIN_ROOT` (version-scoped; a plugin update discards it) |
| Rebuild that index from the project's own memory files and task archive | `.harness/scripts/memory.js seed [--dry-run]` — deterministic parse, idempotent by `contentHash`, prunes what the sources no longer say. Freshness is `max(seq)` **in code**; no model is ever asked which record is newer |
| The P0 control set, parsed; and whether its expected ANSWERS are still true | `.harness/scripts/eval-set.js` — `--list`, `--check` (verify_all D.7). `eval-anchors` checks the citation resolves; this checks the answer behind it |
| Score a retrieval configuration against the control set, no model in the loop | `.harness/scripts/retrieval-eval.js` — `--compare` runs whole / grep / query / memory and prints score against mean bytes |
| Skill mechanical layers (`entropy-cadence`, `ambient-prompt`, `ambient-reset`, `language-policy`, `upgrade-project`, `migrate-scripts-layout`) | `.harness/scripts/<name>.sh`, one per like-named skill |
| Regression drivers, one per subject (out of scope for verify_all) | `.harness/scripts/test-<name>.sh` |

Every script's header states its own contract. The table is the index, not a restatement.

**Code questions go to the graph, not to grep.** Where a symbol is, who calls it, what changes
if it changes, and its verbatim source all come from one `mcp__plugin_harness-kit_codegraph__*`
call — the index is pre-computed and its answer carries the blast radius, which a grep does not.
Five roles hold it (architect, gate reviewer, developer, code reviewer, QA); the analyst and the
orchestrator deliberately do not — one is barred from `file:line` anchoring and the other routes
rather than reads code. It is a **dependency, not a precondition**: the server is a rented
component and an unresolvable tool name is dropped silently, so every contract that holds it also
holds `Read` / `Glob` / `Grep` and degrades to them. `verify_all` D.4 rejects a granted MCP tool
name that no configured server provides — see `capability-audit.js`.

**TypeScript.** Every `.harness/scripts/*.js` is implemented in `src/*.ts`, compiled to
`.harness/scripts/` and committed; where a `.sh` stands beside one it is a two-line
launcher holding no logic. After editing `src/`: `npm run build`, then `npm test`, then copy any
changed `.js` into `skills/harness-init/templates/common/.harness/scripts/` for the ones that
ship. **The copy is that direction and `sync-self` runs the other**, so a `sync-self` before the
copy overwrites your fresh build with the stale template one — build, copy, then sync. Rationale and the latency measurement that chose Node: `docs/proposals/v2-ts-migration.md`.

## Verify before declaring done

`.harness/scripts/verify_all` checks (37 checks, all must PASS — count grows with releases):

- No secrets / committed env files
- `参考/` not tracked
- Required scaffolding present (README, LICENSE, CHANGELOG, CONTRIBUTING, installers)
- All 17 skills present with valid frontmatter
- All 7 template agents present
- Placeholder whitelist enforced (7 allowed)
- `.harness/agents/` matches `templates/common/.harness/agents/` (Layer 1)
- `.claude/agents/` + `.claude/skills/` match `.harness/` (Layer 2 binding)
- AI-GUIDE.md ↔ `.harness/rules/*.md` indexed both directions (no drift)
- Project rules / docs / evals present
- The harness-owned scripts are present and no `.ps1` twin has reappeared (F.1)
- Guard-rm script pair (repo + distributed template) + the settings template's guard wiring (F.2, v0.15+; FAIL if missing; reads no settings file — machine hook state is reported by `/harness-status`)
- README and CHANGELOG reference all skills
- Version stamps consistent across `plugin.json` / `marketplace.json` / both README badges (G.3, v0.14.x+; FAIL on drift)
- `.harness/intervention.md` not tracked (ephemeral file; v0.13+)
- Document size soft caps (I.1-I.5, v0.14+; WARN-level)
- Retired-claim phrase guard (I.6, v0.15.1+; gap-tolerant ordered-anchor scan since v0.18; FAIL if any banned phrase from past architectural retirements resurfaces in a live file)
- AI-generated `50-*.md` sanity (D.3, v0.16.0+; FAIL if a `50-*.md` rule fragment is missing any of the six required headings, leaks a `{{...}}` placeholder, or has a non-template `##`/`###` section without a `<!-- source: ... -->` annotation)
- Ignored INTERVENE supervision reports (I.7, v0.17.0+; WARN if a `docs/features/<slug>/SUPERVISION_REPORT.md` has `Verdict: INTERVENE` AND the slug is an active row in `docs/tasks.md` AND the file mtime is >48h old)

Run after every change; do not skip.
