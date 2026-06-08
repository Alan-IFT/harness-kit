# 02 — Solution Design: ambient-stream

> Stage 2 · solution-architect · mode: full · 2026-06-08
> Upstream: `01_REQUIREMENT_ANALYSIS.md` verdict READY.

## 1. Architecture summary

Add an **ambient chat-driven streaming mode** by (a) extending the existing `/harness-stream` skill — NOT a new skill — so a no-argument invocation resolves a single **default pool** at `docs/batches/default/BATCH_PLAN.md` (auto-created from the `_template`), and adding an **ambient enter/exit** mechanism gated by a transient flag file `.harness/ambient.flag`; and (b) shipping a new **`UserPromptSubmit` hook** (`ambient-prompt.{ps1,sh}` twins) that, **only when `.harness/ambient.flag` exists**, prints an instruction block to stdout (which Claude Code injects as additional context for that turn) telling the agent to fold any requirement into the default pool and drain ready tasks via `pm-orchestrator` until empty. When the flag is absent the hook prints nothing (no-op). The hook is wired into the template `settings.json.tmpl` (with `-NoProfile`), and the dogfood `.claude/settings.json` change is **proposed, not applied**. No new skill, no new `verify_all` lettered check, no version/count bump.

## 2. Affected modules (file paths in the existing repo)

| File | New / Edit | Purpose |
|---|---|---|
| `skills/harness-stream/SKILL.md` | edit | No-arg default-pool resolution + auto-create; ambient enter/exit section; reference the hook as the heartbeat |
| `.harness/scripts/ambient-prompt.ps1` | new | UserPromptSubmit hook (dogfood, Windows) — flag-gated instruction emitter |
| `.harness/scripts/ambient-prompt.sh` | new | UserPromptSubmit hook (dogfood, Unix) — twin |
| `skills/harness-init/templates/common/.harness/scripts/ambient-prompt.ps1` | new | Template twin (distributed) |
| `skills/harness-init/templates/common/.harness/scripts/ambient-prompt.sh` | new | Template twin (distributed) |
| `skills/harness-init/templates/common/.claude/settings.json.tmpl` | edit | Register `UserPromptSubmit` hook with the ambient-prompt command (`-NoProfile` pwsh) |
| `.gitignore` | edit | Ignore `.harness/ambient.flag` (transient runtime state) |
| `.harness/scripts/verify_all.ps1` | edit | Add `ambient-prompt` to the F.1 pair list (NOT a new lettered check) |
| `.harness/scripts/verify_all.sh` | edit | Twin: add `ambient-prompt` to the F.1 pair list |
| `README.md` | edit | EN: mention no-arg/ambient capability under harness-stream |
| `README.zh-CN.md` (or zh section) | edit | zh: same |
| `CHANGELOG.md` | edit | `[Unreleased]` entry |
| `docs/dev-map.md` | edit | List the new `ambient-prompt.{ps1,sh}` pair + `.harness/ambient.flag` |
| `AI-GUIDE.md` | edit (conditional) | Add the new script pair under "Scripts (the moving parts)" |

**NOT edited (red line):** `.claude/settings.json` (dogfood) — propose-only; Developer surfaces the exact JSON block in 04 + 07.

**Note on sync-self mirror set:** `sync-self` mirrors `.harness/agents/` + exactly 4 named script pairs (harness-sync, install-hooks, archive-task, guard-rm) — it does NOT mirror `ambient-prompt`. Therefore the dogfood `.harness/scripts/ambient-prompt.{ps1,sh}` and the template copies must be authored **independently and kept byte-aware in lockstep by hand** (same situation as test-* scripts). This is intentional: adding ambient-prompt to sync-self's mirror set would change sync-self behavior and is out of scope. See Risk R3.

## 3. Module decomposition

### 3.1 `ambient-prompt.{ps1,sh}` — the heartbeat hook

**Responsibility:** a fast, side-effect-free `UserPromptSubmit` hook. It does exactly one decision: is `.harness/ambient.flag` present at the repo root?

**Contract:**
- Reads the `UserPromptSubmit` payload JSON from stdin (may ignore it; the user's prompt is already in the turn — the hook does not need to parse it).
- Resolves the repo root the SAME way as guard-rm: walk up from cwd to the nearest `.git/` ancestor. (The hook is invoked with cwd = project root by Claude Code, but the walk is the robust, proven pattern. The hook does NOT derive root from `$PSScriptRoot` two-up, because at runtime Claude Code invokes it via the settings command relative to cwd — using the `.git` walk avoids the depth-sensitivity hazard, insight L31, entirely.)
- If `.harness/ambient.flag` does NOT exist under repo root → **print nothing, exit 0** (no-op; normal chat).
- If `.harness/ambient.flag` EXISTS → **print the ambient instruction block to stdout, exit 0.** Claude Code injects a `UserPromptSubmit` hook's stdout into the turn as additional context (this is the documented mechanism — the hook augments the prompt; it does not block it). The instruction block tells the agent to:
  1. If this user message reads as a requirement (not a question/aside), normalize it into a `pending` row in `docs/batches/default/BATCH_PLAN.md` (create the file from `docs/batches/_template/BATCH_PLAN.md` if absent; assign `ID`/`Slug`/`Goal`/`Mode=full`/`Depends on`), de-duplicating against existing slugs/goals; if ambiguous, ask before creating a row.
  2. Then drain ready tasks in topological order via `pm-orchestrator` (serial, one at a time) until the pool is empty, exactly per `skills/harness-stream/SKILL.md` "Procedure" (best-effort; existing hard-safety stops apply).
  3. Then stop and wait for the next user message.
  4. Reminder: ambient mode is ON because `.harness/ambient.flag` is present; to exit, the user removes it (or says the exit keyword).

**Exit codes:** always `0`. The hook NEVER blocks a turn (it is not a gate; UserPromptSubmit non-zero/`block` semantics are NOT used — a buggy ambient hook must never wedge the user's chat). Errors (e.g. unreadable cwd) → print nothing, exit 0 ("fail open" for a context-injection hook; the worst case is ambient simply not firing that turn, which the user notices and re-triggers).

**Performance:** straight-line code, no subprocess spawn, no `git` invocation (manual `.git` walk). The pwsh command in settings MUST pass `-NoProfile` (insight L17: 3.7s p50 without it).

**PS case-sensitivity (insight L16/L20/L23):** the hook has no fixed-case string contract (it only tests file existence), so no `-cmatch`/`-ccontains` needed. The flag filename `ambient.flag` is matched by `Test-Path`/`-f`, which are filesystem-case-rules, not string operators — no operator-case hazard. (If any fixed-case literal is added later, use the `-c*` variant.)

### 3.2 Ambient flag — `.harness/ambient.flag`

**Responsibility:** the single bit of state that gates the hook. Presence = ambient ON; absence = ambient OFF.

- **Path:** `.harness/ambient.flag` (repo root). Chosen to sit beside `.harness/intervention.md` (the established transient-runtime-state convention).
- **Content:** freeform / may be empty; a short human-readable line (e.g. `ambient mode ON since <ISO> — pool: docs/batches/default/`) is allowed for transparency but not required by the contract. The hook only checks existence.
- **gitignored:** YES — add `.harness/ambient.flag` to `.gitignore` directly under the existing `# Harness — ephemeral intervention signal` group. It is runtime state, never committed (same as `.harness/intervention.md`). (AC-4)
- **Lifecycle:** created on ambient enter; deleted on ambient exit. Persists across sessions (file-based) — the documented trade-off (RA boundary "Stale flag across sessions"); explicit exit is the mitigation.

### 3.3 Ambient enter / exit (resolves Open Question 2)

**Decision: chat keywords recognized by the `/harness-stream` skill (Open Question 2 option a), NOT a new script and NOT a new placeholder.** Rationale: a new helper script or skill-invocation argument would expand the surface (more files, possible new placeholder, more docs); the converged design's only requirement is "a clear way in and a clear way out". The skill prose defines the keywords; the agent creates/removes the flag file using its normal Write/Edit tools (no new executable needed).

- **Enter:** the user invokes `/harness-stream` with **no pool-id** AND signals ambient intent — surface phrase: **"ambient on"** (English) / **"开启环境模式"** (Chinese), OR the skill, when invoked no-arg, offers to enter ambient mode. On enter: the skill (the agent) writes `.harness/ambient.flag`, ensures `docs/batches/default/BATCH_PLAN.md` exists (auto-create from `_template`), and tells the user: "Ambient mode ON. Type requirements; I will fold each into the default pool and drain it. Say 'ambient off' to stop."
- **Exit:** surface phrase **"ambient off"** (English) / **"关闭环境模式"** (Chinese). On exit: the skill removes `.harness/ambient.flag` and confirms "Ambient mode OFF. Normal chat resumed." Idempotent both ways (enter when flag present = refresh; exit when absent = no-op).

Both keywords are documented in `skills/harness-stream/SKILL.md`. The hook's injected instruction also reminds the user of the exit keyword every ambient turn, so discoverability is guaranteed.

### 3.4 Default pool (resolves Open Question 1)

**Decision: auto-create `docs/batches/default/BATCH_PLAN.md` from `_template` with an EMPTY task table (header row only, example `T-01..T-03` rows removed) — Open Question 1 option (b).** Rationale: ambient use starts from zero; leaving example placeholder rows would make the stream try to plan fictional tasks. The skill, on auto-create, copies `_template/BATCH_PLAN.md`, replaces `<batch-id>` with `default`, and strips the three example rows, leaving the table header + column reference intact.

- **No-arg resolution:** `/harness-stream` with no argument → pool = `docs/batches/default/BATCH_PLAN.md`. (AC-1)
- **Auto-create:** if absent → create from `docs/batches/_template/BATCH_PLAN.md` per above. (AC-2) (Note: existing skill behavior for a *named* missing pool is "point at template + stop"; the **no-arg default** path is the new, friendlier auto-create branch — explicitly distinct so a typo'd named pool still errors loudly.)

## 4. Data model changes

None (no DB). The only persistent artifacts are markdown/flag files already covered.

## 5. API contracts

No network API. The "contract" surfaces are:

- **Hook stdin:** Claude Code passes `UserPromptSubmit` JSON (`{ "prompt": "...", ... }`) on stdin. The hook may ignore it.
- **Hook stdout:** when flag present → the instruction block (becomes turn context). When absent → empty.
- **Hook exit:** always 0.
- **settings.json hook entry (template):**

```json
"UserPromptSubmit": [
  { "hooks": [ { "type": "command", "command": "<AMBIENT_COMMAND>" } ] }
]
```

where `<AMBIENT_COMMAND>` is OS-picked at init time (mirroring how `{{SYNC_COMMAND}}`/`{{GUARD_COMMAND}}` are chosen): Windows → `pwsh -NoProfile -File .harness/scripts/ambient-prompt.ps1`; elsewhere → `bash .harness/scripts/ambient-prompt.sh`.

**Placeholder decision (avoids insight L11 fan-out):** Do NOT introduce a new `{{AMBIENT_COMMAND}}` placeholder. Instead, write the `UserPromptSubmit` entry into `settings.json.tmpl` using the **same literal command shape the dogfood uses**, i.e. hard-code `pwsh -NoProfile -File .harness/scripts/ambient-prompt.ps1` as the template default (the existing `{{SYNC_COMMAND}}`/`{{GUARD_COMMAND}}` placeholders are substituted by harness-init's OS logic; ambient is new and lower-stakes, so shipping the Windows-default literal — consistent with the dogfood which is Windows — plus a `_ambient_hook` root doc-key note instructing non-Windows users to swap to `bash .harness/scripts/ambient-prompt.sh` keeps parity with how the repo documents the Stop/guard OS-swap today). **This adds NO new placeholder → no D.2 whitelist change, no SKILL.md placeholder-table change.** (Confirms AC-13 is N/A and AC-8 holds.)

> SA note: harness-init's substitution step currently fills `{{SYNC_COMMAND}}`/`{{GUARD_COMMAND}}` per OS. The minimal-surface choice is a literal default + documented swap. If the Gate prefers full OS-symmetry via a placeholder, that is the explicit trade (one new placeholder → both D.2 whitelists + SKILL.md table). Default recommendation: literal + doc-key, matching the `_doc_sync_hook`/`_guard_hook` precedent that already documents OS swaps for the other two hooks.

## 6. Sequence / flow

```
User types a message (turn begins)
        │
        ▼
Claude Code fires UserPromptSubmit hook → ambient-prompt.{ps1,sh}
        │
        ├─ walk up to .git root
        ├─ Test-Path .harness/ambient.flag ?
        │        │
        │   NO ──┴─► print nothing, exit 0  ──► normal turn (no injection)
        │
        YES ─► print ambient instruction block to stdout, exit 0
                          │
                          ▼
        Claude Code injects block as added context for THIS turn
                          │
                          ▼
        Agent (per injected instruction + harness-stream SKILL.md):
          1. message is a requirement? → upsert pending row in default pool (de-dupe)
          2. drain ready tasks topologically via pm-orchestrator (serial)
             until pool empty (best-effort; hard-safety stops apply)
          3. stop, wait for next message
```

Ambient enter/exit flow:
```
"ambient on"  → agent writes .harness/ambient.flag + ensures default pool exists
"ambient off" → agent removes .harness/ambient.flag
```

## 7. Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| Living-pool draining (re-read pool, topo frontier, pm-orchestrator dispatch, resume) | `/harness-stream` Procedure | `skills/harness-stream/SKILL.md` §"Procedure" | **Reuse as-is** — ambient is a new entry path + heartbeat into the SAME loop; do not duplicate the loop |
| Pool format + resume semantics | BATCH_PLAN format | `docs/batches/_template/BATCH_PLAN.md` | Reuse; default pool is a `_template` copy |
| Transient runtime-state file convention | `.harness/intervention.md` (gitignored, consumed-and-deleted) | `.gitignore:46-47`, `.harness/rules/65-intervention.md` | Reuse the convention for `.harness/ambient.flag` |
| Hook script shape (stdin JSON, `.git` root walk, exit codes, `set -uo pipefail`, `arr=()`) | `guard-rm.{ps1,sh}` | `.harness/scripts/guard-rm.{ps1,sh}` | Reuse the shape; ambient is far simpler (existence check only) |
| pwsh hook command shape (`-NoProfile -File ...`) | dogfood Stop/PreToolUse hooks | `.claude/settings.json:24,27` | Mirror exactly |
| settings.json schema constraints | J.1 + rule 80 | `verify_all.ps1:574`, `.harness/rules/80-settings-schema.md` | `UserPromptSubmit` already in J.1 enum (verify_all.ps1:579) — no enum change needed |
| Symmetry pair registration | F.1 pair list | `verify_all.ps1:271`, `verify_all.sh` twin | Add `ambient-prompt` to the existing list (no new lettered check) |
| No-version-bump governance | G.3 + G.4 | `verify_all.ps1:300,637` | Stay within: no count claim, no version token changes |

## 8. Risk analysis

- **R1 — Hook injects when it shouldn't (captures casual chat).** Mitigation: strict flag gate; the hook prints nothing unless `.harness/ambient.flag` exists. Explicit "ambient off" exit. QA adversarial test: flag OFF → no-op (AC-6).
- **R2 — pwsh `$PROFILE` runs per turn (slow).** Mitigation: `-NoProfile` mandatory in the settings command (insight L17). QA test: assert `-NoProfile` present in the template command (AC-8) and in the proposed dogfood block.
- **R3 — Dogfood/template ambient-prompt twins drift** (sync-self does NOT mirror this pair). Mitigation: author both copies in the same edit; F.1 only checks *existence* of `.ps1`+`.sh` (not cross-copy byte-identity for non-mirrored scripts), so the lockstep is by discipline + a QA byte-compare of dogfood vs template ambient-prompt. Add a QA adversarial check comparing the two copies. (E.1 sync-self check is unaffected because ambient-prompt is not in sync-self's set.)
- **R4 — settings.json schema break (the two recurring modes).** Mitigation: `UserPromptSubmit` is already a valid J.1 enum key; keep `$schema` canonical `.json`; put any doc note as a ROOT `_ambient_hook` key, NEVER inside `hooks`. Run J.1. (insight L30; AC-8)
- **R5 — Accidental version/count bump.** Mitigation: no new lettered check (F.1 list extension is not lettered); no skill added; no count claim touched. G.3/G.4 stay green without a bump (AC-12). CHANGELOG gets an `[Unreleased]` entry only.
- **R6 — `UserPromptSubmit` non-zero exit wedges the user's chat.** Mitigation: hook always exits 0, fail-open; it is a context augmenter, not a gate.
- **R7 — Repo-root depth hazard (insight L31).** Mitigation: the hook uses the `.git`-ancestor WALK (like guard-rm), NOT `$PSScriptRoot` two-up arithmetic, so relocating the script can't break root resolution.
- **R8 — Doc sweep forgets CHANGELOG (insight L21).** Mitigation: CHANGELOG explicitly in the affected-modules table and the Developer/Reviewer checklist.

## 9. Migration / rollout plan

- **Backwards compatible.** Existing `/harness-stream <pool-id>` invocations are unchanged (named pool still required-or-error). The no-arg default-pool branch and ambient keywords are purely additive.
- **No data migration.** Flag file and default pool are created on demand.
- **Rollout:** template change ships to new projects via `/harness-init`; existing projects get it on `/harness-adopt` re-run (settings merge) or by copying the new script pair + settings block.
- **Dogfood:** PROPOSE the `.claude/settings.json` `UserPromptSubmit` block in 04 + 07; the human applies it. Until applied, the dogfood repo simply doesn't fire the ambient hook (no regression).
- **Rollback:** remove `.harness/ambient.flag` (instant OFF); to fully remove, delete the script pair + the settings `UserPromptSubmit` block.

## 10. Out-of-scope clarifications

- No `/loop`, no idle/unattended progress (heartbeat is user messages only).
- No parallel execution.
- No new `verify_all` lettered check, no new skill, no new template placeholder, no version/count bump.
- The hook does NOT parse the user's prompt to decide "is this a requirement" — that judgment is the AGENT's, per the injected instruction. The hook only gates on the flag. (Keeps the hook trivial and fast.)
- No automatic ambient-exit timeout — exit is explicit only (documented trade-off).

## 11. Partition assignment

N/A — single Developer mode (no `.harness/agents/dev-*.md`). All files go to the generic `developer`.

## 12. Verdict

**READY** — design is complete, grounded in cited files, reuses the existing stream loop, resolves both RA open questions within the converged design, and respects every red line (propose-only dogfood settings, PS/Bash symmetry, `-NoProfile`, canonical `$schema`, no new placeholder/check/version bump). Advancing to Stage 3 (gate-reviewer).
