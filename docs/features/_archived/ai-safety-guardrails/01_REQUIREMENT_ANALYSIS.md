# 01 — Requirement Analysis · ai-safety-guardrails

- Task: `T-001 / ai-safety-guardrails`
- Mode: `full`
- Author: Requirement Analyst
- Date: 2026-05-16
- Upstream inputs (read-only): `docs/features/ai-safety-guardrails/INPUT.md`, `docs/features/ai-safety-guardrails/PM_LOG.md`

> User mandate quoted in `INPUT.md` (verbatim): *"以用户体验好，符合软件工程标准，长期易使用易维护为原则来决策；你来决策就可以了"*.
> Per this mandate, ambiguities are **resolved in this document with a recorded rationale** rather than blocking. The remaining "Open questions" section is empty by design; "Decisions made under mandate" lists every judgment call.

---

## 1. Goal

Ship one cohesive set of AI safety guardrails for harness-kit and every project that installs it, consisting of three deliverables: (D1) clearer documentation of GitHub Copilot's intentional one-role-at-a-time flow plus an opt-in continuous mode, (D2) a documentation callout that Claude Code sub-agent dispatch is already implemented via `Task` tool, and (D3) a cross-platform, auto-installed hook that blocks AI-issued destructive filesystem commands whose target resolves outside the project root.

## 2. In-scope behaviors

### D1 — Copilot flow documentation + opt-in continuous mode

1. `AI-GUIDE.md` (dogfood) and `skills/harness-init/templates/common/AI-GUIDE.md.tmpl` each contain a section titled **"AI tool flow modes"** that states, in ≤8 lines, the three currently-supported flows: (a) Claude Code automatic sub-agent dispatch (default for Claude Code), (b) Copilot manual one-role-at-a-time (default for Copilot/Cursor), (c) Copilot opt-in continuous mode.
2. `.harness/rules/60-tool-handoff.md` (dogfood) and its template counterpart `skills/harness-init/templates/common/.harness/rules/60-tool-handoff.md` each contain a subsection **"Copilot continuous mode (opt-in)"** that specifies:
   - The activation phrase the user types to enter the mode: **`continuous mode`** (English) or **`走全流程`** (Chinese).
   - The activation phrase must appear in a user turn — Copilot does not infer it.
   - While in continuous mode, Copilot self-dispatches through stages 1 → 2 → 3, then **STOPs after Gate Review** and asks the user to confirm before continuing to stages 4-7. This stop is unconditional regardless of the Gate verdict.
   - Continuous mode is reset at every chat-session boundary; Copilot re-prompts the user on the next session.
   - Each stage's output document is still written under `docs/features/<task-slug>/` before advancing.
3. The Copilot bootstrap stub (`.github/copilot-instructions.md` in the dogfood; `skills/harness-init/templates/common/.github/copilot-instructions.md.tmpl` in the template) lists "One role at a time **unless the user has explicitly enabled continuous mode** (see `60-tool-handoff.md`)" as its third red line.

### D2 — Claude Code sub-agent dispatch documentation callout

4. `AI-GUIDE.md` (dogfood) and `AI-GUIDE.md.tmpl` (template) each have a one-paragraph **"Claude Code sub-agent dispatch — already implemented"** callout under the existing "Agents" section, stating that PM Orchestrator uses the `Task` tool and citing the file `.harness/agents/pm-orchestrator.md` lines 4 and ~108-129.
5. `skills/harness-status/SKILL.md` reports a new line item: `Sub-agent dispatch: enabled (Claude Code via Task tool) | n/a (other tools)` in its required-assets table or its summary report. Implementation detail is left to the Architect; the requirement is that running `/harness-status` shows it.

### D3 — Destructive-command guardrail hook (the real feature)

6. A `PreToolUse` hook block is added to `.claude/settings.json` (dogfood) and `skills/harness-init/templates/common/.claude/settings.json.tmpl` that intercepts every Bash tool call before execution.
7. The hook invokes a project-local guard script: `scripts/guard-rm.ps1` (Windows) or `scripts/guard-rm.sh` (Unix), selected by the same OS detection used for `{{SYNC_COMMAND}}` (see `harness-init` step 5).
8. The guard script exits non-zero (causing Claude Code to block the tool call) **if and only if all of the following hold**:
   - The Bash command's first non-pipe token, after `sudo` stripping, matches one of: `rm`, `rmdir`, `unlink`, `Remove-Item`, `del`, `erase`, `Clear-RecycleBin`, `shred`, `srm`.
   - For each path-shaped argument (positional or after `--`) extracted from the command, the **resolved absolute path** (after `..` normalization and after stripping a single layer of symlinks at the leaf only — see §4 boundary B6) lies **outside** the directory `$repoRoot`, where `$repoRoot` is the closest ancestor of the current working directory containing a `.git/` directory. If `$repoRoot` cannot be determined (no `.git/`), the guard exits 0 (no block) and writes a WARN line to stderr.
   - At least one such outside-root path exists. A command that deletes only in-root paths is allowed.
9. When blocking, the guard writes to stderr exactly:
   ```
   harness-kit guard-rm: BLOCKED — destructive command targets path outside project root.
     Command: <the original command, truncated to 300 chars>
     Offending path(s):
       - <absolute path 1> (outside <repoRoot>)
       - <absolute path 2> (outside <repoRoot>)
     Override (only if you really mean this): re-issue the command with the env var
       HARNESS_ALLOW_OUTSIDE_RM=1 set for that single call.
     Or: delete .git/hooks/<n/a — this is a Claude Code PreToolUse hook>, edit .claude/settings.json
     to remove the PreToolUse entry. See .harness/rules/75-safety-hook.md.
   ```
10. Override path: if the environment variable `HARNESS_ALLOW_OUTSIDE_RM=1` is set when the command runs (the user can prepend `HARNESS_ALLOW_OUTSIDE_RM=1` to a single bash invocation, or set it in PowerShell with `$env:HARNESS_ALLOW_OUTSIDE_RM=1` for a session), the guard exits 0 and writes one INFO line to stderr: `harness-kit guard-rm: override active (HARNESS_ALLOW_OUTSIDE_RM=1) — allowing destructive command.`. Claude Code records the stderr in its tool transcript.
11. The guard treats path arguments after these flags as "non-path" and ignores them: `-name`, `-type`, `-regex`, `-iname`, `-perm`, `-mtime`, `-size` (i.e. `find` predicate arguments). This is conservative — see §3.
12. `Remove-Item` invocations through `pwsh -c` / `pwsh -Command "..."` / `powershell -Command "..."` are parsed by re-tokenizing the quoted string and applying the same rules. If parsing fails (unbalanced quotes, no recognizable verb), the guard **defaults to BLOCK** and prints `harness-kit guard-rm: BLOCKED — could not parse nested pwsh command safely; override with HARNESS_ALLOW_OUTSIDE_RM=1 if intended.`
13. The guard script is auto-installed in the following surfaces:
    - **Dogfood** (this repo): `scripts/guard-rm.{ps1,sh}` exist and are referenced from `.claude/settings.json`.
    - **`/harness-init`**: `templates/common/scripts/guard-rm.{ps1,sh}` ship; the rendered `.claude/settings.json` references them; the `harness-init` SKILL.md step 4 lists them under "Scripts".
    - **`/harness-adopt`**: step 5 plan lists `scripts/guard-rm.{ps1,sh}` and the PreToolUse block under "Files I will add (NEW)"; step 6 applies them; conflicts (existing `.claude/settings.json` without PreToolUse) are surfaced under "Conflicts noted" and the user is prompted to **merge in the PreToolUse entry** rather than overwriting the entire file.
14. A new rule fragment **`.harness/rules/75-safety-hook.md`** (dogfood) and **`skills/harness-init/templates/common/.harness/rules/75-safety-hook.md.tmpl`** (template, no placeholders required at v0.15) describes the guard's contract, override path, and how to disable it. `AI-GUIDE.md` and `AI-GUIDE.md.tmpl` index this fragment with trigger **"when running, observing, or disabling the destructive-command guardrail"**.
15. `scripts/sync-self.{ps1,sh}` is extended so that `scripts/guard-rm.{ps1,sh}` are part of its scripts-to-mirror list (joining the existing 4: `harness-sync`, `install-hooks`, `archive-task`, plus the new `guard-rm`).
16. `scripts/verify_all.{ps1,sh}` gains one new PASS check (proposed ID **C.5** — exact ID is the Architect's call) that asserts:
    - `scripts/guard-rm.ps1` and `scripts/guard-rm.sh` both exist in this repo,
    - `templates/common/scripts/guard-rm.ps1` and `templates/common/scripts/guard-rm.sh` both exist,
    - `.claude/settings.json` contains a `PreToolUse` hook entry pointing at `scripts/guard-rm.*`,
    - `templates/common/.claude/settings.json.tmpl` contains the same entry.

### Cross-cutting (applies to D1+D2+D3)

17. `docs/tasks.md` row `T-001` advances to stage `done` upon delivery.
18. `.harness/insight-index.md` MUST receive at most one new line if a non-obvious truth surfaced during implementation (the Architect/Developer decides; required only if evidence exists, per `05-insight-index.md`).
19. `CHANGELOG.md` gains a new minor-version entry (proposed `v0.15.0` — Architect confirms the exact bump per existing version-drift rules).

## 3. Out-of-scope

- **Blocking destructive commands inside the project root.** Build artifacts, temp files, and `node_modules/` deletions inside `$repoRoot` are explicitly allowed. Scope is "rm OUTSIDE the project" per user wording.
- **Intercepting destructive commands issued through tools other than the Bash tool** (e.g. the Write/Edit tools, or commands issued by Cursor/Copilot). PreToolUse only governs Claude Code's tool calls; for other tools the guard is documented best-practice only. See §6.
- **`mv` / `cp` / redirection (`> file`) protection.** Moves and overwrites are common-legit and out of scope for v1. Re-evaluated only if an incident occurs.
- **Network-level safety** (`curl | sh`, `wget -O- | bash`). Out of scope.
- **Production deployment / signing / credential safety.** Out of scope; covered by the existing "stop and ask the user" hard rule in `pm-orchestrator.md`.
- **A GUI / TUI override prompt.** Override is environment-variable based for v1; UX iteration deferred.
- **Retroactive enforcement on already-running tool calls.** PreToolUse blocks before execution; commands that already ran are not unwound.
- **Symlink-following beyond one leaf level.** The guard does NOT chase nested symlinks. See §4 B6.
- **Implementing programmatic sub-agent dispatch for Copilot.** Copilot has no such API; only the opt-in continuous-mode prompt pattern is added (D1).
- **Auto-detecting whether the user wants continuous mode.** Activation requires an explicit phrase (in-scope behavior #2).

## 4. Boundary conditions

| ID | Boundary | Behavior |
|---|---|---|
| B1 | Empty command string | Guard exits 0 (nothing to block). |
| B2 | Command does not match any destructive verb | Guard exits 0 immediately, no path parsing. |
| B3 | `rm` with no path arguments (e.g. `rm --help`) | Guard exits 0. |
| B4 | Path argument is a relative path | Resolve against `cwd` first, then check vs `$repoRoot`. |
| B5 | Path contains `..` that escapes `$repoRoot` (`rm ../../etc/passwd`) | After normalization, this resolves outside root → BLOCK. |
| B6 | Path is a symlink whose target is outside `$repoRoot` | The **leaf** (the path as written) is resolved; the **target** is NOT followed. Rationale: if the user wrote a path inside the repo, deleting the link itself is in-scope-legit. Deleting through `realpath`-resolved targets is out of scope to avoid breaking legitimate symlink-grooming. |
| B7 | `$repoRoot` cannot be determined (no `.git/` ancestor) | Guard exits 0 with a stderr WARN. Rationale: not-a-repo means not-a-harness-kit-project; refusing to block avoids false positives in CI shells. |
| B8 | Glob pattern (`rm /tmp/*.log`) | The guard does NOT expand globs; it inspects the literal argument. `/tmp/*.log` starts with `/tmp/` which resolves outside root → BLOCK. |
| B9 | Command pipes (`find /etc -delete \| xargs rm`) | The guard inspects every pipe segment. `find /etc -delete` blocks because `/etc` is outside root (treated as destructive due to `-delete` flag — see §3 amendment below). |
| B10 | `find` with `-delete` | Treated as a destructive verb (added to the list in in-scope #8). Path arguments to `find` are checked. |
| B11 | Maximum command length 8 KB | Anything longer is truncated to 8 KB before parsing. If a path argument falls past the truncation, the guard defaults to BLOCK. |
| B12 | Concurrency: two parallel tool calls | The guard is stateless and per-invocation; no shared file lock. Each call decides independently. |
| B13 | Override env var set but command is in-root | No effect (the command would be allowed anyway). Override is purely additive. |
| B14 | `.claude/settings.json` has hand-edited PreToolUse entries from a different project | `/harness-adopt` step 5 surfaces this as a conflict and asks the user to merge. |
| B15 | Continuous-mode activation phrase appears in a code block or quoted context | The phrase must appear in the user's plain prose. Copilot follows the existing convention of treating quoted text literally. |
| B16 | Continuous mode + Gate Review verdict = APPROVED | Still STOPs and asks the user. The HARD STOP is unconditional. |
| B17 | User runs harness-kit on a directory that is a subdirectory of another git repo | `$repoRoot` is the **nearest** `.git/` ancestor (current `cwd` walk up). Document this in `75-safety-hook.md`. |

## 5. Acceptance criteria

Each criterion is verifiable by either reading a file, running a script, or observing a tool-call transcript.

### A. Documentation (D1+D2)

- **A1**: `Grep` for `continuous mode` in `AI-GUIDE.md`, `.harness/rules/60-tool-handoff.md`, and their template counterparts returns at least one match per file.
- **A2**: `Grep` for `走全流程` in the `i18n/zh` overlay (`templates/i18n/zh/common/.harness/rules/60-tool-handoff.md` and the zh `AI-GUIDE.md.tmpl`) returns at least one match per file.
- **A3**: `Grep` for `Task tool` (or "sub-agent dispatch") in `AI-GUIDE.md` and `AI-GUIDE.md.tmpl` returns at least one match per file.
- **A4**: Running `/harness-status` (manual exercise, recorded in `06_TEST_REPORT.md`) prints a "Sub-agent dispatch:" line.
- **A5**: `.github/copilot-instructions.md` and its template both contain the phrase "One role at a time **unless**" (or the rendered equivalent).

### B. Guardrail script (D3 — core)

- **B1**: `scripts/guard-rm.ps1` and `scripts/guard-rm.sh` exist in this repo and in `templates/common/scripts/`.
- **B2**: Unit fixtures `evals/guard-rm-cases.md` (created by Developer) document at least the following input → expected-verdict pairs, and a small driver script exercises them:
  - `rm -rf /` → BLOCK
  - `rm -rf /etc` → BLOCK
  - `rm -rf ~/Desktop/foo` → BLOCK
  - `rm -rf ../../../tmp` from inside repo → BLOCK
  - `rm -rf build/` from inside repo → ALLOW
  - `rm -rf node_modules` → ALLOW
  - `Remove-Item -Recurse C:\Windows` → BLOCK
  - `pwsh -c "Remove-Item -Recurse C:\Windows"` → BLOCK
  - `find /etc -delete` → BLOCK
  - `find . -name '*.log' -delete` (cwd inside repo) → ALLOW
  - `HARNESS_ALLOW_OUTSIDE_RM=1 rm -rf /etc/foo` → ALLOW (override)
- **B3**: A live Claude Code session where the assistant attempts `rm -rf /tmp/foo` from this repo's `cwd` produces a tool-call transcript showing the BLOCK and the stderr message from in-scope #9. Recorded in `06_TEST_REPORT.md`.
- **B4**: A live Claude Code session where the assistant attempts `rm -rf <repo>/build` succeeds (no block). Recorded.

### C. Integration (D3 — install surfaces)

- **C1**: `.claude/settings.json` in this repo has a `PreToolUse` array whose first hook command invokes `scripts/guard-rm.ps1` (Windows) or `scripts/guard-rm.sh` (Unix).
- **C2**: `templates/common/.claude/settings.json.tmpl` has the same shape with `{{GUARD_COMMAND}}` (or equivalent placeholder — Architect names it). The placeholder is added to BOTH `scripts/verify_all.ps1` and `.sh` D.2 whitelist (per insight `2026-05-16 · Any new {{...}} placeholder…`).
- **C3**: `skills/harness-adopt/SKILL.md` step 5 plan explicitly lists `scripts/guard-rm.{ps1,sh}` and the PreToolUse merge.
- **C4**: `skills/harness-init/SKILL.md` step 4 / step 8 / "Files added" output references `guard-rm`.
- **C5**: `scripts/sync-self.{ps1,sh}` lists `guard-rm` in its mirror set; `scripts/verify_all` confirms byte-identity between dogfood and template versions.
- **C6**: A new verify_all check ID (Architect names it) PASSes, covering in-scope #16's four sub-assertions.
- **C7**: `scripts/test-init.{ps1,sh}` regression run on an empty fixture directory ends with a `.claude/settings.json` containing the PreToolUse entry and `scripts/guard-rm.{ps1,sh}` present.
- **C8**: `.harness/rules/75-safety-hook.md` exists in this repo; `AI-GUIDE.md` lists it in the "Rule fragments" section with a "when to read" trigger.

### D. Cross-cutting

- **D1**: `scripts/verify_all.{ps1,sh}` PASS in this repo at the end of the task (the standard declare-done gate).
- **D2**: `docs/tasks.md` row `T-001` marked `done` with delivery date.
- **D3**: `CHANGELOG.md` has an entry for the new version describing the three deliverables.
- **D4**: README badge / claimed-check-count / skill list updated to match (per insight `Releases shipped feature code … left README badges … at the pre-release values`).
- **D5**: `.harness/agents/qa-tester` exercises the adversarial case "what if the override env var is set unintentionally" (recorded in `06_TEST_REPORT.md`'s `## Adversarial tests` section).

## 6. Non-functional requirements

| NFR | Requirement | Verification |
|---|---|---|
| Performance | The guard script's wall-clock overhead per Bash tool call MUST be ≤ 50 ms on a developer laptop. | QA times 100 invocations; reports median + p95. |
| Compatibility | The guard MUST run unmodified on: Windows 10/11 with pwsh 7.x, macOS 13+, Ubuntu 22.04+ (bash 5.x). | QA runs the fixture set on each platform or notes "platform unavailable in this run". |
| Failure mode | If the guard script itself errors (syntax error, missing interpreter), Claude Code's PreToolUse failure semantics MUST result in a BLOCK with a clear message, not a silent pass. | Architect designs; QA verifies by intentionally breaking the script. |
| Maintainability | The guard is a single file per OS (no library dependencies beyond stock pwsh/bash). | Read the script. |
| Security | The override env var MUST NOT be persistable in `.claude/settings.json` or any committed file; it is a per-call escape hatch only. | `Grep` confirms no committed file sets `HARNESS_ALLOW_OUTSIDE_RM=1`. |
| Observability | Every BLOCK emits a stderr line that includes the absolute offending path(s) and the resolved `$repoRoot`. | Inspect transcript. |
| Backward compat | Projects initialized before this version that re-run `harness-sync` MUST NOT have their existing `.claude/settings.json` overwritten. `harness-sync` does not touch `.claude/settings.json`; only `/harness-adopt` migrates it (with merge prompt). | Verified by reading current sync script and the C3 plan. |

## 7. Related tasks

From `docs/tasks.md`:

- **T-000 / initial-bootstrap** (delivered 2026-05-15) — established the `.harness/` + `.claude/` + `templates/` layout this task extends. No per-stage docs.

From `.harness/insight-index.md`, applicable entries (PM_LOG already enumerated):

- `2026-05-16 · Any new {{...}} placeholder in a .tmpl file MUST be added to BOTH verify_all.ps1 AND verify_all.sh D.2 whitelist OR the test fails.` — applies to acceptance C2.
- `2026-05-16 · sync-self only syncs .harness/agents/ + 4 specific scripts … — NOT .harness/rules/.` — applies to in-scope #15: adding `guard-rm` to sync-self requires touching both `.ps1` and `.sh` versions.
- `2026-05-16 · Releases shipped feature code + CHANGELOG but left README badges / getting-started skill list / AI-GUIDE.md / manual-e2e-test counts at the pre-release values.` — applies to D3 / D4.
- `2026-05-16 · One-sided assertions hide bidirectional drift.` — applies to C6: the new check must assert both directions (rule indexed in AI-GUIDE AND AI-GUIDE indexes only rules that exist).
- `2026-05-16 · Edit tool occasionally reports SUCCESS without applying the change.` — Developer must re-Read after every edit.

No prior task has touched `PreToolUse` hooks, `.claude/settings.json` permissions beyond the existing `Bash(rm -rf /:*)` deny, or Copilot continuous mode. This is greenfield in those areas.

## 8. Decisions made under user mandate (replaces "Open questions")

The user's directive *"你来决策就可以了"* (you decide) means ambiguities are resolved here, not bounced back. Each row records the question, the decision, the rationale (good UX / SE standards / long-term maintainability), and the alternative that was rejected.

| # | Question | Decision | Rationale | Rejected alternative |
|---|---|---|---|---|
| 1 | Which Bash verbs count as "destructive"? | `rm`, `rmdir`, `unlink`, `Remove-Item`, `del`, `erase`, `Clear-RecycleBin`, `shred`, `srm`, plus `find … -delete`. | Covers the universe of "actually removes a file" verbs across bash + pwsh + cmd shims. `mv` and redirection deferred per §3. | (a) Just `rm` — too narrow, misses `Remove-Item` on Windows. (b) Anything that touches the filesystem — too broad, breaks build tools. |
| 2 | How is "outside project root" determined? | Resolve to absolute path, normalize `..`, compare against the nearest `.git/` ancestor of `cwd`. Do NOT follow symlinks past the leaf. | `git`-based root is the same heuristic `harness-sync` already uses. Symlink leaf-only matches user mental model ("the file I wrote"). | (a) Use `pwd` — fails when cwd is a subdir. (b) Follow full symlink chain via `realpath` — surprises users grooming legitimate links. |
| 3 | Enforcement mechanism for Claude Code? | `PreToolUse` hook in `.claude/settings.json` invoking `scripts/guard-rm.{ps1,sh}`. | Officially supported in Claude Code's settings schema (the same schema we already use for `Stop`). Lives next to existing hooks → low cognitive load. | (a) A custom wrapper around the Bash tool — not available. (b) Rely only on the existing `deny` list — only blocks exact-string `rm -rf /`, misses every variant. |
| 4 | Enforcement for Copilot/Cursor? | Documented best-practice in `75-safety-hook.md` + the existing `.claude/settings.json` `deny` block (kept and expanded). Programmatic block is technically infeasible for those tools today; the project pre-commit hook gives a partial backstop for any committed deletion of tracked files. | Honest about the tooling gap; the user's mandate is to be SE-standard, which means not pretending to enforce what we can't. | (a) Ship a shell wrapper that overrides `rm` globally — too invasive on the user's machine. (b) Do nothing for Copilot — leaves a known gap unsignalled. |
| 5 | Override mechanism? | Per-call env var `HARNESS_ALLOW_OUTSIDE_RM=1`. | Forces the user to make the override explicit and ephemeral — good UX (visible) + good security (no persistent toggle in a committed file). Pattern is familiar (`SUDO=1`, `FORCE=1`). | (a) A persistent setting in `.claude/settings.json` — too easy to leave on. (b) An interactive prompt — Claude Code tool hooks don't support stdin prompts cleanly. |
| 6 | Continuous-mode activation phrase? | English `continuous mode`; Chinese `走全流程`. Both are explicit, not inferred. | Two-word English phrase is distinctive enough to avoid false triggers; 走全流程 mirrors existing 中文 triggers used in AI-GUIDE.md workflow table. | (a) A magic comment in the user's prompt — too discoverable, increases accidental activation. (b) Different phrases per stage — too much surface area. |
| 7 | Continuous-mode HARD STOP point? | Unconditional STOP after Gate Review (stage 3), regardless of verdict. The user must say "continue" to proceed to stages 4-7. | Gate Review is the design-approval gate; if a human will ever sanity-check, this is the cheapest moment. Honors the user's "good UX" principle while keeping autonomy gains. | (a) Stop only on FAIL — defeats the purpose of opt-in autonomy + sanity-check. (b) No stop, full 1-7 autonomy — too risky given the user's stated safety concern. |
| 8 | Where does the new rule fragment live? | `.harness/rules/75-safety-hook.md` (between `70-doc-size.md` and `80-existing-conventions.md` per harness-adopt). | The numbering convention uses 60s for tool handoff, 70s for doc hygiene, so 75 is the natural slot for a guardrail-discipline rule. | (a) Cram into `60-tool-handoff.md` — overloads that file. (b) `90-safety.md` — leaves an awkward gap. |
| 9 | Auto-install on existing projects via `/harness-adopt`? | Yes, as a NEW file entry in step 5's plan AND a merge into `.claude/settings.json` (not overwrite). | The user explicitly asked for auto-install on every project. Merge-not-overwrite is the existing `harness-adopt` discipline. | (a) Skip existing projects — violates user requirement. (b) Overwrite settings.json — destructive. |
| 10 | Version bump? | `v0.15.0` (minor). | New feature + new rule fragment + new script pair = minor bump per existing version convention. | (a) Patch — understates surface change. (b) Major — premature; nothing breaks for existing users who re-run sync. |
| 11 | What if a project doesn't use `.git`? | Guard exits 0 with stderr WARN. | Refuse-to-protect-loudly beats false-block-silently. Documented in `75-safety-hook.md`. | (a) Always block — breaks CI scratch shells. (b) Silently no-op — hides the failure to find root. |
| 12 | Should the guard be opt-out at init? | No. Always on. Documented disable path = remove the PreToolUse entry from `.claude/settings.json`. Each project's `init` writes it unconditionally. | User mandate: "auto-install on every project". Making it opt-in defeats the purpose. Disable path is one-line removal — discoverable, reversible. | (a) Ask Q6 in `harness-init` — adds a question whose right answer is "yes" 99% of the time. |

## 9. Verdict

**READY** — proceed to Solution Architecture.

All decisions are recorded in section 8 under the user's explicit mandate to decide. The Architect inherits a fixed scope, fixed verb list, fixed enforcement mechanism, fixed override path, and a checklist of install surfaces. The Architect's remaining freedom is in: (a) exact rule-fragment file shape, (b) exact placeholder names in templates, (c) the verify_all check ID, (d) the precise tokenizer in `guard-rm` (whether to use pwsh's `[Management.Automation.Language.Parser]` or a regex; bash's `read -ra` or a small AWK). Those are implementation, not requirements.
