# 01 — Requirement Analysis · T-12 `resilient-hooks`

**Mode:** full · **Analyst stage output** · **Verdict:** READY (see §9)
**deferred-human mode:** defer, do not ask — every ambiguity below carries a Recommended answer the pipeline proceeds on.

---

## 1. Goal

Stop the per-turn `Stop hook error: bash: .harness/scripts/harness-sync.sh: No such file or directory` by making the harness convenience lifecycle hooks fail-open and cwd-independent, and stop the published plugin from carrying this repo's dogfood hooks.

---

## 2. In-scope behaviors (numbered, testable)

This task has two independent slices, **A** (resilient hook form) and **B** (stop distributing dogfood hooks). See §10 for the decomposition decision.

### Slice A — resilient hook command form

1. **A1 — Sync hook (Stop) degrades to a silent success when its script is unreachable.** When the Stop hook fires and its target sync script cannot be resolved (missing file, wrong cwd, OS-variant mismatch), the hook command exits 0 and emits nothing on stderr — Claude Code surfaces no per-turn error. When the script IS present at the project root, it runs exactly as today.
2. **A2 — Sync hook anchors its script path to the Claude-Code project root.** The hook resolves its script relative to `$CLAUDE_PROJECT_DIR` (the project-root env var Claude Code injects into hook commands), not relative to the hook's runtime cwd, so launching Claude Code from a subdirectory does not break resolution.
3. **A3 — The resilient form is defined for both OS variants.** An exact Unix (`bash`) command string AND an exact Windows (`pwsh`) command string are specified; both satisfy A1+A2; the two are symmetric in behavior (same fail-open + same anchor semantics).
4. **A4 — The two ambient hooks (UserPromptSubmit→ambient-prompt, SessionStart→ambient-reset) get the same resilient form.** They are convenience hooks (a missing one only disables ambient-stream, never a safety regression), already fail-open by intent (insight 2026-06-08), and fire every turn / every session, so they carry the identical A1+A2+A3 treatment.
5. **A5 — guard-rm (PreToolUse) is treated as a SAFETY hook and is NOT made fail-open.** A missing/unreachable guard-rm script must NOT silently allow a destructive command. guard-rm MAY receive the `$CLAUDE_PROJECT_DIR` anchor for cwd-robustness, but only in a form that fails CLOSED when the script is absent (the destructive Bash call is blocked / the user is told, never silently permitted). The fail-open `... || exit 0` idiom used by A1 is explicitly forbidden for guard-rm. See §9 OQ-1 for the recommended exact form.
6. **A6 — The distributed template carries the resilient form.** `skills/harness-init/templates/common/.claude/settings.json.tmpl` wires its four hook events with the resilient command strings (via the `{{SYNC_COMMAND}}` / `{{GUARD_COMMAND}}` / `{{AMBIENT_PROMPT_COMMAND}}` / `{{AMBIENT_RESET_COMMAND}}` placeholders or their equivalent), so every freshly init'd / adopted project is resilient from day one.
7. **A7 — The `{{...}}_COMMAND` derivation in harness-init and harness-adopt produces the resilient form.** The OS-pick rules documented in `skills/harness-init/SKILL.md` step 5, `skills/harness-adopt/SKILL.md` step 6, and the `upgrade-project` / `migrate-scripts-layout` placeholder-repair path (`ph_cmd` construction) all emit the resilient command for each event, for both OSes. The five command derivations stay consistent with each other (T-020 four-file-lockstep discipline; here it is a multi-file-lockstep over every place a command string is authored).
8. **A8 — The `/harness-upgrade` (and `migrate-scripts-layout`) repair path rewrites an EXISTING project's hooks to the resilient form.** When run against a project whose `.claude/settings.json` carries the OLD brittle command form (bare relative path, no anchor, no guard), the repair rewrites the convenience-hook commands to the resilient form. This is what fixes projects set up before this task (the T-020 fix did not reach them). The rewrite preserves raw-text settings (never re-serialize — DO-3), keeps `$schema` canonical, writes a timestamped `.bak`, and is idempotent (a second run is a NOOP).
9. **A9 — The dogfood `.claude/settings.local.json` carries the resilient form.** This repo's own active hooks (relocated by slice B) use the same resilient pwsh form, so the repo dogfoods what it ships.

### Slice B — stop distributing dogfood hooks

10. **B1 — This repo's active dev hooks move out of the committed `.claude/settings.json`.** The four hook entries currently in the repo's committed `.claude/settings.json` move to `.claude/settings.local.json` (Claude Code's local-only, same-precedence settings file).
11. **B2 — The committed `.claude/settings.json` carries NO leakable hooks.** After the move, the committed/distributed `.claude/settings.json` has either no `hooks` block or an empty one. (Permissions MAY remain in the committed file; only the `hooks` are the leak.)
12. **B3 — `.claude/settings.local.json` is gitignored.** `.gitignore` excludes `.claude/settings.local.json` (add the entry — it is absent today). The local dogfood file is never committed and never distributed.
13. **B4 — Local dogfood behavior still works.** After the move, this repo's Stop/PreToolUse/UserPromptSubmit/SessionStart hooks still fire locally for the developer (settings.local.json has the same load precedence for local dev).
14. **B5 — Nothing in `verify_all` requires the committed `.claude/settings.json` to carry the hooks.** Every check that today reads `.claude/settings.json` for a hook (F.2 guard-rm wiring; J.1 schema; E.4b/D.4b in generated projects) is confirmed to still PASS with the hooks living in `.claude/settings.local.json` (and is updated to read the local file where it legitimately must verify the dogfood hooks). No check is left asserting against an empty committed `hooks` block.

---

## 3. Out-of-scope (explicitly NOT this iteration)

1. Converting the plugin to ship hooks via `hooks/hooks.json` or the `plugin.json` `hooks` field. The harness Stop hook is a per-project dev-sync, not a global plugin hook; it should not be a plugin hook at all.
2. Changing what `harness-sync` / `guard-rm` / `ambient-prompt` / `ambient-reset` DO. Only the WIRING (command string) and the dogfood-distribution change.
3. Adding a new `verify_all` check. Per `feedback_design_over_guards`, the resilient design is the fix; no new gate. (Existing checks are UPDATED for the new command form per §2 A-ripple, but no new check is introduced.)
4. A new placeholder token. The four existing `{{...}}_COMMAND` placeholders carry the resilient form.
5. Changing the OS-detection logic itself (`$IsWindows` / `$OSTYPE` branch). The same detection picks between the resilient pwsh and resilient bash forms.
6. Migrating the pre-commit git hook or the install-hooks path (those already guard with `command -v` + `[ -f ... ]` and are not the per-turn error source).
7. Backporting to already-cached plugin versions 0.19.0–0.31.0 (immutable; users get the fix on plugin update + `/harness-upgrade`).

---

## 4. Boundary conditions

1. **Missing script (the reported bug).** Sync/ambient hook → exit 0, no stderr (A1). guard-rm → fail CLOSED (A5).
2. **Wrong cwd (Claude Code launched from a subdirectory).** `$CLAUDE_PROJECT_DIR` anchor resolves the script regardless of cwd (A2/A4).
3. **`$CLAUDE_PROJECT_DIR` unset or empty.** The resilient form must not blow up or accidentally point at a filesystem root. Recommended: treat unset/empty as "script unreachable" → the convenience hooks no-op exit 0; guard-rm falls back to a still-fail-closed behavior. (OQ-2.)
4. **OS-variant mismatch (pwsh form on a no-pwsh box, or the `_doc_sync_hook` hand-switch to bash).** The interpreter's own "not found" is a separate failure mode from the script-missing one; the in-scope fix targets script-missing. Interpreter-unavailable stays a `harness-status` §3c WARN (already implemented) — not silently swallowed, not in-scope to auto-rewrite.
5. **Path with spaces / non-ASCII in the project root.** The anchored path must be quoted in both shells so a space in `$CLAUDE_PROJECT_DIR` does not split the command.
6. **Settings.json absent (non-Claude-Code project).** Repair path skips settings rewire with a note (existing behavior, must be preserved — A8 does not regress it).
7. **Existing `.claude/settings.local.json` in a user project (slice B is repo-only).** Slice B touches only THIS repo's dogfood; it does not change what init/adopt write to a user's settings.json (their resilient hooks live in the committed settings.json they own — A6). No interaction.
8. **Idempotence.** Running `/harness-upgrade` twice on an already-resilient project is a NOOP, no `.bak` churn (A8) — mirrors the T-020 fixed-point discipline (insight B10).
9. **Cross-shell byte parity of any GENERATED settings text.** If a script writes the settings (upgrade/migrate raw-text rewrite), the pwsh and bash forms must produce byte-identical command strings and obey the write-time newline + console-encoding discipline (insights 2026-06-08, T-021).
10. **The congruence-scan path extractor (the #1 ripple).** The new command string still contains an extractable `scripts/<name>.(ps1|sh)` token that the existing left-bounded ERE can parse, AND the existence check the scan performs must remain correct when the path is `$CLAUDE_PROJECT_DIR`-anchored. See §6 and OQ-3.

---

## 5. Acceptance criteria (each verifiable)

1. **AC-1 (A1 reproduce-the-bug).** In a project tree with `.harness/scripts/harness-sync.{sh,ps1}` ABSENT, invoking the wired Stop command from the project root exits 0 and prints nothing to stderr. (Reproduces the consumer's `rc=127` scenario → resilient `rc=0`, mirroring T-020's verbatim-replay discipline.)
2. **AC-2 (A2 anchor).** Invoking the wired Stop command from a SUBDIRECTORY of a project whose script IS present resolves and runs the script (exit 0, sync performed). The pre-anchor brittle form would have failed here.
3. **AC-3 (A3 both OSes).** The exact Unix and Windows command strings are recorded in the spec and both pass AC-1 + AC-2 (the unavailable-script OS gets the no-op; the available-script OS runs it).
4. **AC-4 (A4 ambient parity).** AC-1 + AC-2 hold for the UserPromptSubmit and SessionStart hook commands.
5. **AC-5 (A5 guard-rm fail-closed — the safety invariant).** With `.harness/scripts/guard-rm.{ps1,sh}` ABSENT, the PreToolUse hook does NOT silently allow a Bash call that the present guard would have blocked: it either blocks (non-zero / deny) or surfaces an explicit error. A mutation test deleting guard-rm and attempting a destructive command MUST NOT result in silent permission. (Direct inverse of AC-1 — convenience fails open, safety fails closed.)
6. **AC-6 (A6 template).** `settings.json.tmpl` (after placeholder substitution by a real init for each OS) yields the resilient form for all four events; `verify_all` J.1 still PASSes (schema valid, `$schema` canonical, every `hooks` key a valid event).
7. **AC-7 (A7 derivation lockstep).** init step-5 table, adopt step-6 table, and the `upgrade`/`migrate` `ph_cmd` construction all emit the same resilient command per event/OS. A grep over the authoring sites shows no surviving brittle (un-anchored, un-guarded) form for the convenience hooks.
8. **AC-8 (A8 repair).** Running `/harness-upgrade` (and `migrate-scripts-layout`) against a fixture whose settings carries the OLD brittle convenience-hook form rewrites it to the resilient form; `$schema` stays canonical; a `.bak` is written; a second run is a settings NOOP (byte-identical, no new `.bak`).
9. **AC-9 (B1/B2 move).** This repo's committed `.claude/settings.json` has no (or an empty) `hooks` block; the four hook entries are present in `.claude/settings.local.json` in the resilient form.
10. **AC-10 (B3 gitignore).** `.gitignore` contains `.claude/settings.local.json`; `git status` shows the local file untracked/ignored.
11. **AC-11 (B5 verify_all unaffected).** `.harness/scripts/verify_all.{ps1,sh}` PASSes after slice B — specifically F.2 (guard-rm wiring) still finds its PreToolUse+Bash+guard-rm evidence (read from the file that now holds the dogfood hooks) and J.1 still validates both targets. No check FAILs because the committed settings lost its hooks.
12. **AC-12 (ripple — the #1 risk).** Every assertion in §6 that parses a hook command string still classifies a healthy resilient project as congruent/PASS and still flags a genuinely dangling script. Verified by: `verify_all` E.4b/D.4b PASS on a resilient generated project; `test-init` AC-5 "every settings hook command path exists" + "OS-picked variant" PASS; `test-harness-upgrade` dangling-repair + congruence-exit-4 + placeholder-repair fixtures PASS; a mutation deleting the wired script is STILL reported as dangling (the scan is not blinded by the anchor).
13. **AC-13 (gate).** `.harness/scripts/verify_all` PASSes (32/32) on both shells after the change. (PS run may be operator-pending per repo convention.)
14. **AC-14 (count/version).** `plugin.json` version bumps (§7); no check-count flip; G.4 stays consistent (count claims unchanged).

---

## 6. The assertion-ripple list (every surface that parses the hook command string)

A changed command form WILL ripple into these. This is the #1 regression risk (T-020 four-file-lockstep, generalized). The shared mechanism across all of them is the left-bounded path-extraction ERE `(^|["' =])(\.harness/)?scripts/<name>.(ps1|sh)` followed by an existence check **relative to cwd / project root**, plus a `{{` unresolved-placeholder probe. The architect MUST enumerate and re-validate each:

1. **`verify_all` J.1 — settings.json schema integrity** (`.claude/settings.json` + `settings.json.tmpl`). Parses the `$schema` literal and every key inside the `hooks` block against the valid-event enum. Risk: the new command strings must keep the JSON valid and the schema URL/hook-key structure intact. (Both shells: `.sh` ~L631-684; `.ps1` twin.)
2. **`verify_all` E.4b (fullstack/generic) / D.4b (backend) — hook↔script congruence in GENERATED projects.** Template files `skills/harness-init/templates/{fullstack,backend,generic-or-common}/.harness/scripts/verify_all.{sh,ps1}.tmpl`. Extracts every command path and asserts `[[ -f "$e4b_path" ]]` **relative to project cwd**, plus a `{{` token probe. **Critical tension:** with a `$CLAUDE_PROJECT_DIR`-anchored path, (a) the extractor's left-boundary class `["' =]` does not include `/`, so a literal `$CLAUDE_PROJECT_DIR/.harness/scripts/...` may not anchor the ERE; and (b) even if extracted, the path string would carry the `$CLAUDE_PROJECT_DIR/` prefix and `[[ -f ]]` against cwd would mis-resolve. The architect must choose a command form whose extractable token is still cwd-relative-resolvable by these scans (or update the scans' boundary class + existence base). Both shells, both templates per type.
3. **`test-init.{ps1,sh}` — generated-settings congruence assertions.** `[T-020] every settings hook command path exists on disk (AC-5)` (same ERE, `[[ -f "$tmp/$t20_path" ]]`), `[T-020] ambient-prompt command is the OS-picked variant` + `ambient-reset ... OS-picked variant` (exact-string `grep -qF "\"command\": \"$AMBIENT_PROMPT_COMMAND\""`), and the `SYNC_COMMAND`/`GUARD_COMMAND`/`AMBIENT_*_COMMAND` literals defined at the top of the driver (`.sh` ~L43-52). The OS-picked-variant assertions compare against the literal the driver builds — that literal MUST be updated to the resilient form or the exact-match fails. Plus the deletion mutation probe `deleted harness-sync.* IS reported as dangling` must still trigger.
4. **`test-harness-upgrade.{ps1,sh}` — repair-path probes.** Fixtures that craft OLD-form settings and assert the rewrite: `A: settings rewired to .harness/scripts/`, `A: settings no longer references bare scripts/harness-sync`, Fixture H (dangling repair → wired command runs, no `CONFLICT|congruence`), Fixture I (incongruent end state → exit 4), Fixture P / P2 (literal-placeholder repair → wired command equals OS-picked variant, target exists, exits 0), M1/M2/M3 (per-variant gating, byte-identity, read-only write-failure). The `t20_pick` / `t20_tok` literals (`.sh` ~L282-283) and the OLD-form fixture command strings define what "rewired to" means — these must be updated to expect the resilient form, and the fixtures' assertions about the rewritten command string must match the new form.
5. **`upgrade-project.{ps1,sh}` S3 + S6 + `migrate-scripts-layout.{ps1,sh}` rewire + terminal scan.** The `ph_cmd` construction (`upgrade` `.sh` ~L233-237) is itself a command-AUTHORING site (must emit the resilient form — A7), AND the terminal congruence scan (`upgrade` S6 ~L494-550; `migrate` ~L152-200) re-parses the final settings with the same ERE + existence test. Both the author and the scanner inside these helpers must agree on the resilient form. The per-variant prefix-rewire `sed` (`s|scripts/$tool_base...|.harness/scripts/...|`) operates on the path substring — confirm the anchored form does not defeat it.
6. **`harness-status` SKILL §3b + §3c — hook↔script congruence diagnostic.** `skills/harness-status/SKILL.md` §3b (guard-rm "Safety hook" deep check: parses `hooks.PreToolUse[*].command` references `guard-rm.{ps1,sh}`) and §3c (per-event DANGLING/MALFORMED tri-state using the SAME left-bounded ERE + existence check + `{{` probe). The resilient form must keep §3b recognizing guard-rm and §3c classifying a healthy project as `ok`. (Behavioral skill spec, not a script — update the "How to compute" wording if the extractable token shape changes.)
7. **`harness-init` SKILL step 10b + `harness-adopt` step 6 terminal congruence assert.** Both SKILLs document the same extract-and-check-existence assertion run at end of init/adopt (init step 10b; adopt step 6.3). Behavioral spec — the documented pattern must match whatever the architect chooses.

**Net:** 7 surfaces (5 of which exist in BOTH `.ps1` and `.sh`, i.e. ~12 files), plus 2 SKILL behavioral specs. The architect must pick a resilient command form that the existing left-bounded ERE can still parse to a cwd-resolvable token, OR update the ERE + existence-base consistently across ALL of them in lockstep. The cwd-vs-`$CLAUDE_PROJECT_DIR` resolution mismatch (item 2a/2b) is the load-bearing decision.

---

## 7. Version / count / decomposition

- **Version bump:** `plugin.json` `0.43.0` → `0.44.0` (a shipped behavior change to distributed hooks + repair path). This is the minor-bump convention used by every prior shipped task in §tasks.md.
- **No count flip:** no new skill (skills stay 17), no new agent (8), no new `verify_all` check (32). It is a bug fix + hygiene change. G.4 count claims are unchanged; only the version token moves.
- **CHANGELOG:** a `## [0.44.0]` heading is required (G.4 gate).

---

## 8. Non-functional requirements (only the material ones)

1. **NFR-Safety (load-bearing).** guard-rm MUST remain fail-closed (A5/AC-5). This is the single non-negotiable: convenience hooks may swallow errors, the safety hook may not.
2. **NFR-Perf.** The Windows `-NoProfile` flag stays on every pwsh hook (measured 3-4s→10ms; init step-5 note, QA D-3). The resilient wrapper must not reintroduce per-turn `$PROFILE` load or a measurable per-turn cost.
3. **NFR-Cross-shell-parity.** Any script that GENERATES the settings text must emit byte-identical command strings across pwsh/bash and obey write-time-newline + UTF-8 console-encoding discipline (insights 2026-06-08, T-021). guard against the recurring parity-gap family.
4. **NFR-Compat.** The fix must not require a Claude Code version newer than what already injects `$CLAUDE_PROJECT_DIR` into hook commands (confirm availability across all four hook events — INPUT cites mattpocock/git-guardrails using it; verify before relying).

---

## 9. Open questions (Recommended answer per — deferred-human: proceed on Recommended)

**OQ-1 — guard-rm's exact resilient form (the safety/cwd-robustness balance).**
(a) Add the `$CLAUDE_PROJECT_DIR` anchor AND fail-closed-if-absent: `pwsh -NoProfile -File "$CLAUDE_PROJECT_DIR/.harness/scripts/guard-rm.ps1"` / `bash "$CLAUDE_PROJECT_DIR/.harness/scripts/guard-rm.sh"` with NO `|| exit 0` — a missing script makes the interpreter exit non-zero, which Claude Code treats as a hook failure (the destructive call is not silently allowed).
(b) Leave guard-rm exactly as today (bare relative path, no anchor) — minimal blast radius, but a subdirectory launch can still mis-resolve it.
(c) Anchor + an explicit "guard missing → deny" wrapper script.
**Recommended: (a).** It gives guard-rm the same cwd-robustness as the convenience hooks (fixing the same subdirectory class) while keeping it fail-closed by construction — a missing/unreachable guard yields a hook failure, never a silent allow. Option (c) is over-engineered for this iteration; (b) leaves the cwd bug for the one hook that most needs robustness. The architect confirms (a)'s exact failure semantics against Claude Code's PreToolUse non-zero-exit contract.

**OQ-2 — behavior when `$CLAUDE_PROJECT_DIR` is unset/empty.**
(a) Convenience hooks: treat as unreachable → no-op exit 0. guard-rm: fall back to a still-fail-closed path (e.g. resolve relative to cwd; if still unresolved, deny/fail).
(b) Fall back to the bare relative path for all hooks (today's behavior) when the var is unset.
**Recommended: (a).** Unset `$CLAUDE_PROJECT_DIR` is not the reported failure mode (Claude Code injects it), but the resilient form must not crash or point at FS root if it is empty; (a) preserves the fail-open/fail-closed split even in the degenerate case.

**OQ-3 — keep the cwd-relative congruence scans, or teach them the anchor?**
(a) Choose a resilient command form whose extractable token stays the cwd-relative `.harness/scripts/<name>.(ps1|sh)` substring (e.g. the anchor is a shell variable expansion that still leaves `.harness/scripts/...` as a parseable substring, and the scan's existence check is interpreted as "this script must exist in the project") — minimal ripple, the existing ERE + `[[ -f ]]` keep working unchanged.
(b) Update every scan's ERE boundary class to also accept the `$CLAUDE_PROJECT_DIR/` prefix AND change the existence base from cwd to the project root, across all 7 surfaces / ~12 files in lockstep.
**Recommended: (a) where achievable, falling back to (b) only for surfaces where (a) cannot hold.** (a) honors the four-file-lockstep lesson (fewer synchronized edits = fewer drift bugs) and `feedback_design_over_guards` (pick the form that doesn't force a guard rewrite). The architect verifies that a `$CLAUDE_PROJECT_DIR`-anchored command still contains the bare `.harness/scripts/<name>.sh` substring the ERE can grab (it does — the substring survives the prefix), and that the scan's `[[ -f "$path" ]]` resolves correctly when run from the project root (verify_all/test fixtures run from root). This is the load-bearing design call and is flagged as the #1 risk in §6.

**OQ-4 — committed `.claude/settings.json`: empty `hooks: {}` or drop the key entirely?**
(a) Keep an empty `hooks: {}` block (+ the `_*` doc keys explaining hooks live in settings.local.json).
(b) Remove the `hooks` key entirely.
**Recommended: (a).** An empty `hooks: {}` plus a `_hooks_moved` doc key keeps J.1's parser exercising a real (empty) hooks block, documents WHERE the dogfood hooks went, and is a clearer signal to a reader than silent absence. Permissions stay in the committed file.

None of these block progress under deferred-human mode — each has a Recommended answer the SA/Dev proceed on; an operator may override any at review.

---

## 10. Decomposition (per T-06 smart-zone)

**Decision: do NOT split into separate pipeline tasks; keep A and B as two slices of one task.** Rationale: B (move 4 hook entries to settings.local.json + 1 gitignore line + confirm verify_all) is a few-file, low-cognitive-load change that shares the SAME files and the SAME verify_all surfaces as A's dogfood leg (A9 writes the resilient form into the very settings.local.json that B creates). Splitting would force two passes over `.claude/settings*.json` and the F.2/J.1 surfaces with a serial dependency (B must land the file A9 writes into), inflating coordination for no isolation benefit — the opposite of the T-06 "thin independently-verifiable slice" goal. The total surface fits one ~120k-token smart zone. The architect MAY sequence A-before-B internally (A defines the resilient form; B relocates the dogfood copy already in that form), but as ONE task with one delivery and one version bump.

---

## 11. Related historical tasks (linked, not re-described)

- **T-020 `sync-hook-dangling-ref` (v0.31.0)** — same user-reported `harness-sync.sh: No such file or directory`; fixed the "ensure the script lands" side (presence-gated rewires + terminal congruence scan exit 4 + init 10b / adopt terminal asserts + template E.4b/D.4b rows). Did NOT make the hook itself resilient → this task is its direct successor. `docs/features/_archived/sync-hook-dangling-ref/`.
- **T-007 `scripts-relocation` (v0.20.0)** — moved `scripts/` → `.harness/scripts/`; origin of the `migrate-scripts-layout` helper and the root-depth-derivation hazard (insight 2026-06-04).
- **T-012 `harness-upgrade-skill` (v0.23.0)** — origin of `/harness-upgrade` + `upgrade-project.{ps1,sh}`; the repair path A8 extends. Also the write-time-newline parity insight (DEFECT-1).
- **T-011 `ambient-stream`** — origin of the two ambient hooks (A4); fail-open-by-design insight (2026-06-08).
- **T-021 `stream-auto-decompose` (v0.32.0)** — pwsh console-encoding parity gap (NFR-3); the raw-byte UTF-8 emission fix in ambient-prompt.ps1.
- **Insight 2026-06-08 (schema)** — J.1's two failure classes ($schema URL `.json` suffix; doc-key placement inside `hooks`); both must stay green under the new command form.

---

## 12. Verdict

**READY.** The two slices, in-scope behaviors, boundary conditions, and acceptance criteria are testable; the assertion-ripple list (the #1 risk) is enumerated; all open questions carry a Recommended answer the pipeline proceeds on under deferred-human mode. The single load-bearing design call (OQ-3: anchor vs. the cwd-relative congruence scans) is handed to the Solution Architect with the recommended path and the exact constraint it must satisfy.
