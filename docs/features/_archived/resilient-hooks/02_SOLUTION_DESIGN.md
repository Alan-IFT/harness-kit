# 02 — Solution Design · T-12 `resilient-hooks`

**Mode:** full · **Architect stage output** · **Verdict:** READY (see §12)
**Upstream:** `01_REQUIREMENT_ANALYSIS.md` verdict = READY · **deferred-human:** proceed on RA Recommended answers (OQ-1a, OQ-2a, OQ-3a, OQ-4a).
**Version:** 0.43.0 → 0.44.0 · no check-count flip (skills 17 / agents 8 / checks 32 unchanged).

---

## 1. Architecture summary

The harness lifecycle hooks are made **resilient at the wiring layer**: the three convenience hooks (Stop→harness-sync, UserPromptSubmit→ambient-prompt, SessionStart→ambient-reset) gain a fail-open, `$CLAUDE_PROJECT_DIR`-anchored command form that exits 0 silently when its script is absent or the cwd is a subdirectory; the safety hook (PreToolUse→guard-rm) gains the same anchor but stays fail-CLOSED (no `|| exit 0`). The single load-bearing constraint is that all four resilient command strings keep exposing a **space-bounded, cwd-relative `.harness/scripts/<name>.<ext>` token** so the existing left-bounded path-extraction ERE in every congruence scan (`verify_all` E.4b/D.4b, `harness-status` §3c, init 10b / adopt 6, the upgrade/migrate terminal scans, test drivers) keeps parsing and existence-checking them **untouched** (OQ-3a). The form is authored in one place per OS and fanned out by lockstep to the template, the five command-derivation sites, and the repair path; the repair path additionally learns to **rewrite a pre-existing brittle command into the resilient form** (A8, a genuinely new transform). Slice B relocates this repo's dogfood hooks out of the committed `.claude/settings.json` into a gitignored `.claude/settings.local.json` carrying the resilient form, so the published plugin distributes no leakable hooks while local dogfooding still fires.

This is a **seam** change: the hook command string is the seam between Claude Code's lifecycle events and the harness scripts. We harden the seam (anchor + fail-open/closed) without touching either side's internals — the scripts (`harness-sync`, `guard-rm`, `ambient-*`) are unchanged (out-of-scope §3.2), and Claude Code's event contract is unchanged. The **locality** win: the resilient idiom is authored at exactly one site per OS per slice; everything else either substitutes a placeholder or re-parses a token that, by design, did not change shape.

---

## 2. Affected modules (file paths from the existing repo)

| # | File | Slice | Nature |
|---|---|---|---|
| 1 | `skills/harness-init/templates/common/.claude/settings.json.tmpl` | A | edit — placeholder values become resilient (placeholders themselves unchanged) |
| 2 | `skills/harness-init/SKILL.md` | A | edit — step-5 `{{...}}_COMMAND` derivation table → resilient strings; step-10b ERE note unchanged |
| 3 | `skills/harness-adopt/SKILL.md` | A | edit — step-6 substitution table → resilient strings; step-6.3 assert note unchanged |
| 4 | `.harness/scripts/upgrade-project.sh` | A | edit — S3.0 `ph_cmd` resilient; NEW S3.2 brittle→resilient rewrite; S6 scan unchanged |
| 5 | `.harness/scripts/upgrade-project.ps1` | A | edit — twin of #4 |
| 6 | `.harness/scripts/migrate-scripts-layout.sh` | A | edit — NEW brittle→resilient rewrite alongside the prefix rewire; terminal scan unchanged |
| 7 | `.harness/scripts/migrate-scripts-layout.ps1` | A | edit — twin of #6 |
| 8 | `skills/harness-status/SKILL.md` | A | edit — §3b/§3c "How to compute" wording confirms the token shape; behavioral, no logic flip |
| 9 | `.harness/scripts/test-init.sh` | A | edit — `*_COMMAND` literals → resilient; ERE existence-check + mutation probe UNCHANGED |
| 10 | `.harness/scripts/test-init.ps1` | A | edit — twin of #9 |
| 11 | `.harness/scripts/test-harness-upgrade.sh` | A | edit — `t20_pick` resilient; fixture OLD-form strings + A/H/I/P/P2/M* assertions adjusted |
| 12 | `.harness/scripts/test-harness-upgrade.ps1` | A | edit — twin of #11 |
| 13 | `.claude/settings.json` (committed dogfood) | B | edit — strip `hooks`, keep empty `hooks: {}` + `_hooks_moved` doc key + permissions |
| 14 | `.claude/settings.local.json` (NEW, gitignored) | A+B | new — the four dogfood hooks in resilient pwsh form |
| 15 | `.gitignore` | B | edit — add `.claude/settings.local.json` |
| 16 | `.harness/scripts/verify_all.sh` | B | edit — F.2 reads the file holding dogfood hooks (settings.local.json fallback); J.1 adds settings.local.json target; E.4b/D.4b are TEMPLATE checks, no dogfood read |
| 17 | `.harness/scripts/verify_all.ps1` | B | edit — twin of #16 |
| 18 | `.claude-plugin/plugin.json` | G.3 | edit — `version` 0.43.0 → 0.44.0 |
| 19 | `.claude-plugin/marketplace.json` | G.3 | edit — `version` 0.43.0 → 0.44.0 |
| 20 | `README.md` | G.3 | edit — version badge → 0.44.0 |
| 21 | `README.zh-CN.md` | G.3 | edit — version badge → 0.44.0 |
| 22 | `CHANGELOG.md` | G.4 | edit — add `## [0.44.0]` heading + entry |

**NOT touched (verified):** `verify_all` E.4b/D.4b template tmpls (the ERE is unchanged — OQ-3a), the six `templates/{fullstack,backend,generic}/.harness/scripts/verify_all.{sh,ps1}.tmpl` E.4b/D.4b rows (untouched per OQ-3a), `harness-sync.*` / `guard-rm.*` / `ambient-*.*` script bodies (out-of-scope §3.2), `install-hooks.*` / pre-commit hook (already guard with `command -v` + `[ -f ]`, out-of-scope §3.6), `40-locations.md`, `80-settings-schema.md` (J.1 contract; updated only if a second target is added — see §5 / J.1).

---

## 3. The resilient command strings (the load-bearing decision — A3, OQ-1, OQ-2, OQ-3)

### 3.1 Design constraints the form MUST satisfy simultaneously

1. **A1/A4 fail-open (convenience):** script absent → exit 0, nothing on stderr.
2. **A5 fail-closed (guard-rm):** script absent → non-zero exit (Claude Code treats PreToolUse non-zero as hook failure → the Bash call is not silently allowed). NO `|| exit 0`.
3. **A2 cwd-anchor:** resolve relative to `$CLAUDE_PROJECT_DIR`, not the hook runtime cwd.
4. **OQ-2 degenerate `$CLAUDE_PROJECT_DIR` unset/empty:** must not point at FS root / crash. Convenience → no-op exit 0; guard-rm → still fail-closed.
5. **Boundary §4-5 spaces in path:** the anchored path must tolerate a space in `$CLAUDE_PROJECT_DIR`.
6. **OQ-3a — the #1 constraint:** the string MUST still contain a `.harness/scripts/<name>.<ext>` token preceded by a boundary char in the existing ERE class `["' =]` (or line start) — i.e. a **space-preceded** bare relative token — so the unchanged left-bounded ERE extracts a **cwd-relative-resolvable** path and the unchanged `[[ -f ]]` / `Test-Path` existence check (which runs from the project root in every scanner) keeps working.
7. **NFR-Perf:** keep `-NoProfile` on every pwsh hook (3-4s → 10ms).
8. **NFR cross-shell byte-parity:** the generated text must be byte-stable across the pwsh/bash writers of the same settings.

### 3.2 Why OQ-3a is achievable ONLY with the `cd`-anchor shape (not the `$CLAUDE_PROJECT_DIR/`-prefix shape)

The dispatch's suggested idiom `bash "$CLAUDE_PROJECT_DIR/.harness/scripts/harness-sync.sh"` places `.harness/scripts/...` immediately after `$CLAUDE_PROJECT_DIR/` — the character before `.harness/` is `/`. The ERE boundary class is `["' =]` (quote / space / `=`), which does **NOT** include `/`. The regex cannot anchor at that position, and the optional `(\.harness/)?` prefix does not help because the char before `scripts/` is also `/`. **Result: a `$CLAUDE_PROJECT_DIR/`-direct-prefix command is INVISIBLE to every congruence scan** — it would silently stop catching dangling sync hooks (defeating T-020) and break Fixture A/P existence checks. This is the precise failure §6-item-2a of the requirement warned about, and it falsifies the naive reading of OQ-3a.

The fix that keeps OQ-3a true: split the anchor from the invocation. Use `cd "$CLAUDE_PROJECT_DIR"` (or `Set-Location`) to establish the anchor, then invoke the script via a **bare, space-preceded relative path** `.harness/scripts/<name>.<ext>`. Now the ERE sees ` .harness/scripts/harness-sync.sh` (leading space = boundary), extracts the bare token, and the existence check resolves it cwd-relative exactly as today. The anchor is satisfied at runtime (the `cd` makes the relative path resolve against the project root regardless of the hook's launch cwd); the scanner is satisfied at scan time (it runs from project root, where the same relative token resolves). **One form, both audiences happy, zero ERE edits.** This is a deletion-test win: we could delete the entire OQ-3b branch (no ERE change, no existence-base change, no test-hardcode change to the regex) and the design still holds.

### 3.3 The exact strings — convenience hooks (Stop / UserPromptSubmit / SessionStart)

**Unix (bash).** Idiom: `&&`-chain after a presence test; trailing `|| exit 0` makes ANY failure (missing file, failed `cd`, unset var) a silent success.

```
sh -c 'cd "$CLAUDE_PROJECT_DIR" 2>/dev/null && [ -f .harness/scripts/harness-sync.sh ] && exec bash .harness/scripts/harness-sync.sh || exit 0'
```

- `cd "$CLAUDE_PROJECT_DIR" 2>/dev/null` — anchor (A2). If the var is unset/empty, `cd ""` fails (empty operand) → short-circuits to `|| exit 0` (OQ-2a: no FS-root, no crash). `2>/dev/null` keeps A1's "no stderr".
- `[ -f .harness/scripts/harness-sync.sh ]` — fail-open guard (A1). Absent script → false → `|| exit 0`.
- `exec bash .harness/scripts/harness-sync.sh` — the **space-preceded bare relative token** the ERE grabs (OQ-3a). `exec` is cosmetic (one fewer subshell); not required.
- `|| exit 0` — fail-open terminator (A1).

The `sh -c '…'` wrapper exists because the Stop/ambient command is a single string Claude Code hands to one interpreter; wrapping in `sh -c` lets the `cd`+test+invoke compose without relying on the outer shell's chaining. Single-quotes inside `sh -c '…'` keep `$CLAUDE_PROJECT_DIR` un-expanded until runtime AND require **no JSON `\"` escaping** of inner double-quotes except the one pair around `$CLAUDE_PROJECT_DIR` — see §3.5 for the JSON-escaped literal.

**Windows (pwsh).** Idiom: `-NoProfile` preserved (NFR-Perf); `-Command` with a `Set-Location` + `Test-Path -PathType Leaf` + invoke + `exit 0` fallback.

```
pwsh -NoProfile -Command "Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR -EA SilentlyContinue; if (Test-Path -LiteralPath .harness/scripts/harness-sync.ps1 -PathType Leaf) { & pwsh -NoProfile -File .harness/scripts/harness-sync.ps1 }; exit 0"
```

- `Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR -EA SilentlyContinue` — anchor; unset/empty var or bad path → silently stays put, `-EA SilentlyContinue` suppresses stderr (OQ-2a + A1). `-LiteralPath` tolerates spaces/brackets (boundary §4-5).
- `Test-Path -LiteralPath .harness/scripts/harness-sync.ps1 -PathType Leaf` — fail-open guard; the **space-preceded bare relative token** the ERE grabs (OQ-3a). `-PathType Leaf` rejects a dir named like the script.
- `& pwsh -NoProfile -File .harness/scripts/harness-sync.ps1` — runs it with `-NoProfile` (NFR-Perf preserved in the inner call).
- `exit 0` — unconditional fail-open terminator (A1).

Substitute `ambient-prompt` / `ambient-reset` for `harness-sync` to get the UserPromptSubmit / SessionStart strings (A4 — identical treatment).

### 3.4 The exact strings — guard-rm (PreToolUse, SAFETY — A5, OQ-1a)

**Confirm OQ-1a.** guard-rm gets the SAME `$CLAUDE_PROJECT_DIR` anchor (cwd-robustness for the one hook that most needs it — a subdirectory launch must not blind the safety guard) but **NO `|| exit 0` / no `exit 0` fallback**. A missing/unreachable guard yields a non-zero interpreter exit → Claude Code's PreToolUse non-zero contract blocks the Bash call (fail-closed). This is the **direct inverse** of the convenience form (deletion test: remove the fail-open terminator and the form must still be well-defined — it is). Option (c) wrapper-script is rejected as over-engineered for this iteration; (b) un-anchored is rejected because it leaves the cwd bug on the safety hook.

**Unix (bash):**
```
sh -c 'cd "$CLAUDE_PROJECT_DIR" 2>/dev/null && bash .harness/scripts/guard-rm.sh'
```
- `cd` anchor; on unset/empty var the `cd ""` fails → the `&&` short-circuits → `sh -c` exits non-zero (fail-closed; OQ-2a guard branch).
- NO `[ -f ]` pre-test and NO `|| exit 0`: if the script is missing, `bash .harness/scripts/guard-rm.sh` exits non-zero ("No such file or directory") → fail-closed (A5). The missing-file stderr here is **acceptable and desirable** (unlike convenience hooks) — it is the signal that the guard is unreachable.
- The space-preceded bare token `.harness/scripts/guard-rm.sh` is ERE-parseable (OQ-3a).

**Windows (pwsh):**
```
pwsh -NoProfile -Command "Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR; & pwsh -NoProfile -File .harness/scripts/guard-rm.ps1"
```
- `Set-Location` with NO `-EA SilentlyContinue` → a bad/empty path throws → non-zero exit (fail-closed; OQ-2a).
- No `Test-Path` guard, no `exit 0`: a missing `guard-rm.ps1` makes `& pwsh -File …` exit non-zero → fail-closed (A5).
- Space-preceded bare token `.harness/scripts/guard-rm.ps1` is ERE-parseable (OQ-3a).

### 3.5 The JSON-escaped literals (what actually lands in settings.json / .tmpl)

Inside a JSON string value, the inner `"` around `$CLAUDE_PROJECT_DIR` (bash) become `\"`. pwsh `-Command` inner double-quotes also become `\"`. The exact `command` values (Unix examples shown; Windows analogues per §3.3/§3.4):

- **`{{SYNC_COMMAND}}`** (Unix):
  `"sh -c 'cd \"$CLAUDE_PROJECT_DIR\" 2>/dev/null && [ -f .harness/scripts/harness-sync.sh ] && exec bash .harness/scripts/harness-sync.sh || exit 0'"`
- **`{{GUARD_COMMAND}}`** (Unix):
  `"sh -c 'cd \"$CLAUDE_PROJECT_DIR\" 2>/dev/null && bash .harness/scripts/guard-rm.sh'"`
- **`{{AMBIENT_PROMPT_COMMAND}}`** / **`{{AMBIENT_RESET_COMMAND}}`** (Unix): as `{{SYNC_COMMAND}}` with the script name swapped.
- **Windows `{{SYNC_COMMAND}}`** (lands in this repo's `.claude/settings.local.json`, A9):
  `"pwsh -NoProfile -Command \"Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR -EA SilentlyContinue; if (Test-Path -LiteralPath .harness/scripts/harness-sync.ps1 -PathType Leaf) { & pwsh -NoProfile -File .harness/scripts/harness-sync.ps1 }; exit 0\""`
- **Windows `{{GUARD_COMMAND}}`**:
  `"pwsh -NoProfile -Command \"Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR; & pwsh -NoProfile -File .harness/scripts/guard-rm.ps1\""`

> **Developer note (J.1 / NFR-parity):** the exact byte sequence above is the single source — `settings.json.tmpl`, the dogfood `settings.local.json`, the five derivation sites, and the test `*_COMMAND` literals must all reproduce it character-for-character (T-020 multi-file-lockstep). The grep-based J.1 only reads `$schema` + hooks-block keys, so the inner `\"` does not perturb it; verify J.1 PASS on the new `.tmpl` after substitution-shape check.

### 3.6 Anchor-availability confirmation (NFR-Compat)

`$CLAUDE_PROJECT_DIR` is injected by Claude Code into **all** hook command environments (INPUT cites mattpocock/git-guardrails using `"$CLAUDE_PROJECT_DIR"/…`; the env var is documented for Stop/PreToolUse/UserPromptSubmit/SessionStart alike). The Developer MUST re-verify via context7 `Claude Code` docs (the §3 boundary note demands it) before relying — but no Claude Code version newer than the one already injecting the var is required (the brittle form already runs in those versions). If a future Claude Code dropped the var, the convenience form no-ops (fail-open) and guard-rm fails closed — both safe degradations.

---

## 4. Module decomposition (new + changed behavior)

### 4.1 NEW: `.claude/settings.local.json` (dogfood, gitignored) — B1/B4/A9

- **Responsibility:** hold this repo's four active dev hooks in the resilient **Windows pwsh** form (this dev box is Windows; A9 = dogfood what we ship).
- **Public surface:** Claude Code loads it at the same precedence as `settings.json` for local dev (B4). Never committed (B3).
- **Shape:** `{ "$schema": <canonical>, "hooks": { Stop/PreToolUse/UserPromptSubmit/SessionStart … } }` — the four resilient pwsh strings from §3.5. `$schema` canonical so J.1 (if pointed at it) PASSes.

### 4.2 CHANGED: committed `.claude/settings.json` — B2 (OQ-4a)

- Keep `permissions` (not a leak). Replace the populated `hooks` with **empty `hooks: {}`** + a root `_hooks_moved` doc key: `"_hooks_moved": "Dogfood hooks live in .claude/settings.local.json (gitignored) so the published plugin ships no leakable hooks. See docs/features/_archived/resilient-hooks/."`. Empty `hooks: {}` keeps J.1's parser exercising a real (empty) block (OQ-4a rationale).

### 4.3 NEW behavior in the repair path — A8 (the one genuinely new transform)

The existing upgrade S3.1 / migrate prefix-rewire `sed`/`.Replace` only adds the `.harness/` prefix to a bare `scripts/<name>` — it does NOT convert a brittle command (`pwsh -NoProfile -File .harness/scripts/harness-sync.ps1` or `bash .harness/scripts/harness-sync.sh`) into the resilient form. A8 requires that conversion. **New step S3.2 (after S3.1, before the terminal scan):** for each of the four events, detect a wired command whose extractable token is `.harness/scripts/<tool>.<ext>` but whose surrounding text is NOT already the resilient form (probe: absence of the resilient sentinel `CLAUDE_PROJECT_DIR`), and **replace the whole `command` value** with the OS-picked resilient string for that event (convenience vs guard form per tool). Gated on the target being present (reuse `target_present`), so a brittle command pointing at a missing script is left for the terminal scan to flag as dangling (never rewritten into a resilient-but-dangling form). Idempotent: a command already containing `CLAUDE_PROJECT_DIR` is skipped (second run = NOOP, no `.bak` churn — B10 / boundary §8). Raw-text edit, never re-serialize (DO-3); `$schema` untouched (boundary, AC-8).

> **Deep-module note:** S3.2 is a thin **adapter** over the existing presence-gated rewrite machinery — it reuses `target_present`, the `.bak`/idempotence harness, and the byte-parity write path; it adds only the "is-this-the-resilient-form?" predicate and the whole-value replacement. The terminal congruence scan (S6) is unchanged because S3.2's output still carries the space-bounded token it parses.

---

## 5. Data model / schema changes

No DB. The only "schema" is `.claude/settings.json`'s JSON shape, governed by J.1:

- **J.1 target list (`j1_targets` / `$j1Targets`):** today `.claude/settings.json` + the `.tmpl`. **Add `.claude/settings.local.json`** to both shells so the dogfood hooks' `$schema` + hook-event keys are validated where they now live (B5: "updated to read the local file where it legitimately must verify the dogfood hooks"). The `[[ -f "$jt" ]] || continue` guard already makes a missing target a clean skip, so a user project without settings.local.json is unaffected.
- **`80-settings-schema.md`** — add a one-line note under "Maintenance": `.claude/settings.local.json` (when present) is also a J.1 target; the two move together with `.claude/settings.json`. (Behavioral doc, not a gate.)
- No new hook-event enum entries; no `$schema` URL change. The resilient strings are values, not keys — J.1's key-enum check is unaffected.

---

## 6. Flow — how a Stop turn flows through the resilient hook

```
Claude Code session end (Stop event), cwd = anywhere (maybe a subdir)
  │  injects $CLAUDE_PROJECT_DIR into the hook env
  ▼
runs settings command value (sh -c '…' | pwsh -NoProfile -Command "…")
  │
  ├─ cd / Set-Location "$CLAUDE_PROJECT_DIR"
  │     ├─ var unset/empty/bad → (convenience) short-circuit → exit 0 silent  [A1/OQ-2a]
  │     │                        (guard-rm)    throw/non-zero → Bash call blocked [A5/OQ-2a]
  │     └─ ok → cwd is now project root
  ▼
  ├─ [ -f .harness/scripts/harness-sync.sh ] / Test-Path … (convenience only)
  │     └─ absent → exit 0 silent  [A1]   (guard-rm has NO pre-test → missing = non-zero [A5])
  ▼
  └─ run bash/pwsh .harness/scripts/<tool>.<ext>   ← space-bounded token the ERE parses [OQ-3a]
        └─ present → runs exactly as today
```

Scanner flow (verify_all E.4b / status §3c / init 10b / upgrade S6), run from project root:
```
read "command" line → ERE (^|["' =])(\.harness/)?scripts/<name>.(ps1|sh)
   matches at the SPACE before .harness/scripts/<tool>.<ext>  [unchanged ERE]
→ strip boundary char → token = .harness/scripts/<tool>.<ext>
→ [[ -f "$root/$token" ]] / Test-Path $token   [unchanged existence check, cwd=root]
→ present → PASS ;  deleted/dangling → still FLAGGED (mutation probe stays green)
```

---

## 7. Reuse audit (mandatory)

| Need | Existing code | File path | Decision |
|---|---|---|---|
| Left-bounded path-extraction ERE | `grep -oE "(^\|[\"' =])(\.harness/)?scripts/[A-Za-z0-9._-]+\.(ps1\|sh)"` | E.4b/D.4b template tmpls; `test-init.{sh,ps1}`; upgrade S6; migrate scan; status §3c spec | **Reuse UNCHANGED** — the whole point of OQ-3a |
| Existence check base (project root) | `[[ -f "$root/$ref_path" ]]` / `[[ -f "$tmp/$t20_path" ]]` / `Test-Path $p` | upgrade S6; migrate scan; test-init | **Reuse UNCHANGED** — token stays cwd-relative |
| Presence-gated rewrite + `.bak`/idempotence harness | `target_present` + S3 write path | `upgrade-project.{sh,ps1}` S3; `migrate-scripts-layout.{sh,ps1}` | **Reuse** — S3.2 (A8) is an adapter on top |
| Placeholder repair (token → OS-picked cmd) | S3.0 `ph_cmd` loop | `upgrade-project.{sh,ps1}` | **Extend** — emit resilient `ph_cmd`; reuse the gate + assemble-from-pieces token discipline |
| OS-pick (Windows pwsh / else bash) | `$IsWindows` / `case "$OSTYPE"` | init step 5, adopt step 6, upgrade S3.0 | **Reuse as-is** (out-of-scope §3.5 to change detection) |
| `*_COMMAND` test literals + `{{…}}` substitution | `SYNC_COMMAND`/… + `sed -e "s\|{{…}}\|…"` | `test-init.{sh,ps1}` L43-68 | **Extend** — literals become resilient; substitution mechanism unchanged |
| guard-rm substring recognition | `grep -qE 'guard-rm\.(ps1\|sh)'` (F.2); `references guard-rm.{ps1,sh}` (status §3b) | `verify_all.{sh,ps1}` F.2; status SKILL | **Reuse as-is** — resilient form still contains `guard-rm.ps1`/`.sh` substring |
| settings.local.json as dogfood-hooks home | Claude Code native local-settings precedence | (Claude Code) | **Reuse platform feature** — no new mechanism |
| Version-stamp fan-out gate | G.3 (plugin/marketplace/2 READMEs) + G.4 (CHANGELOG heading + version) | `verify_all.{sh,ps1}` | **Reuse** — G.3/G.4 enforce the 0.44.0 bump |
| Empty-hooks doc-key pattern | `_doc_sync_hook` / `_guard_hook` root doc keys | `.claude/settings.json` | **Reuse pattern** — add `_hooks_moved` root key |
| New verify_all check | (none — deliberately) | — | **NOT added** (feedback_design_over_guards; §3.3 out-of-scope; check count stays 32) |

The audit is non-empty and proves the design rides existing machinery: **no new check, no new ERE, no new existence base, no new placeholder token, no new script.** The only genuinely new code is the A8 brittle→resilient rewrite adapter (S3.2) and the settings.local.json file.

---

## 8. The exact lockstep edit list (the 7 ripple surfaces — behavioral, durable, no file:line)

Each item is a behavioral change description. **Edit-point count: 22 lockstep edit points** (enumerated; see the count rollup at the end of this section). Surfaces that exist in both `.ps1` and `.sh` are counted as two edit points.

**Surface 1 — `verify_all` J.1 (settings schema).** Behavioral change: add `.claude/settings.local.json` to the J.1 target list in BOTH shells so the relocated dogfood hooks' `$schema` + event keys are validated. The resilient command strings keep the JSON valid (values only) — confirm the `.tmpl` after a real substitution still PASSes J.1 (parse + `$schema` canonical + hooks keys all valid events). **[2 edit points: J.1 sh, J.1 ps1]**

**Surface 2 — `verify_all` E.4b / D.4b (generated-project congruence, 6 tmpls).** Behavioral change: **NONE to the ERE or existence check** (OQ-3a). The resilient strings expose a space-bounded cwd-relative token the existing left-bounded ERE parses and `[[ -f ]]`/`Test-Path` resolves from project root. **Re-validate** (not edit) that a freshly-init'd resilient project PASSes E.4b/D.4b and that deleting the wired script still FAILs them. **[0 edit points — verification only, the design's central claim]**

**Surface 3 — `test-init.{sh,ps1}` path-exists + OS-variant + `*_COMMAND` literals + delete-dangling.**
- The `SYNC_COMMAND`/`GUARD_COMMAND`/`AMBIENT_PROMPT_COMMAND`/`AMBIENT_RESET_COMMAND` literals at the driver top → the resilient strings (exact bytes, both OS branches), because the OS-picked-variant assertions compare via `grep -qF '"command": "<literal>"'` and the literal MUST equal what the substituted `.tmpl` writes.
- The `{{…}}` substitution mechanism (`sed`) is UNCHANGED.
- The "[T-020] every settings hook command path exists on disk" extraction + `[[ -f "$tmp/$t20_path" ]]` is UNCHANGED (token shape preserved — OQ-3a).
- The mutation probe "deleted harness-sync.* IS reported as dangling" is UNCHANGED (the scan is not blinded by the anchor — re-validate it still triggers). **[2 edit points: test-init.sh literals, test-init.ps1 literals]**

**Surface 4 — `test-harness-upgrade.{ps1,sh}` fixtures + `t20_*` literals + OLD-form strings.**
- `t20_pick` → the resilient OS-picked string (it is the expected post-repair command). Because the resilient string contains spaces and `||`/`;`, the test's `p_target="${t20_pick##* }"` (last-token = script path) and `eval "$t20_pick"` break: **change `p_target` derivation** to extract the `.harness/scripts/<name>.<ext>` token via the same left-bounded ERE (not "last space-token"), and keep `eval "$t20_pick"` (the resilient string runs fine under `eval`; from the fixture root the script exists → exits 0; PS twin uses `Invoke-Expression`). **[encoded OLD-form fixture → resilient]**
- **Fixture A** (OLD-form pre-wired `pwsh -NoProfile -File scripts/harness-sync.ps1`): the post-upgrade assertion "settings rewired to .harness/scripts/" stays true (token still present); ADD an assertion that the rewritten command is the **resilient form** (contains `CLAUDE_PROJECT_DIR`) — this is the A8 proof. The negative "no bare `-File scripts/harness-sync`" stays valid.
- **Fixture H** (dangling repair, pre-wired bare `bash .harness/scripts/harness-sync.sh`): after repair the wired command must become resilient — ADD/adjust the assertion to expect the resilient form; the direct `bash .harness/scripts/harness-sync.sh` invocation (runtime check) stays as-is (the file exists post-repair).
- **Fixture I** (incongruent end state, exit 4): unchanged behavior — the legacy `scripts/harness-sync.ps1` (no `.harness/` prefix, missing script) is still flagged; assertions stay.
- **Fixtures P / P2** (literal-placeholder repair): P asserts the repaired command equals `t20_pick` — now the resilient string; P's `p_target`/`eval` fix above applies; P2 (gated-off) still asserts the token is NOT substituted (no new dangle). `$schema` canonical + `.bak` + idempotent-NOOP assertions unchanged.
- **Fixtures M1/M2/M3** (migrate per-variant gating / byte-identity / read-only write-failure): M2 (healthy) asserts the rewired command — update to expect the resilient form (the migrate brittle→resilient rewrite now applies); M1/M3 still assert the missing/legacy path is flagged (CONGRUENCE-FAIL), unchanged. **[2 edit points: test-harness-upgrade.sh, .ps1]**

**Surface 5 — `upgrade-project.{ps1,sh}` S3 + S6 + `migrate-scripts-layout.{ps1,sh}` rewire + scan.**
- S3.0 `ph_cmd` / `$cmd`: emit the **resilient** OS-picked string per event (convenience vs guard form per tool) instead of the brittle `bash .harness/scripts/<tool>.sh` / `pwsh -NoProfile -File …`. Tokens still assembled from pieces (no literal `{{…}}` in the shipped helper — insight 2026-06-08).
- NEW S3.2 brittle→resilient rewrite (A8, §4.3) in BOTH upgrade and migrate, gated on `target_present`, idempotent on the `CLAUDE_PROJECT_DIR` sentinel, raw-text, `.bak`, `$schema` preserved.
- S3.1 prefix rewire `sed`/`.Replace` + double-prefix collapse: UNCHANGED and confirmed idempotent on a resilient string (the substring `scripts/<tool>.<ext>` → `.harness/scripts/<tool>.<ext>` then collapse `.harness/.harness/` → `.harness/`; the resilient form's existing `.harness/scripts/…` token round-trips to itself).
- S6 terminal scan (upgrade) / terminal scan (migrate): UNCHANGED ERE + `[[ -f "$root/$ref_path" ]]` — re-validate it PASSes on a resilient end state and still exits 4 on a genuine dangle. **[4 edit points: upgrade.sh, upgrade.ps1, migrate.sh, migrate.ps1]**

**Surface 6 — `harness-status` SKILL §3b + §3c.** Behavioral change: §3b guard-rm recognition (`command references guard-rm.{ps1,sh}`) stays valid (substring present). §3c "How to compute" wording — the left-bounded ERE + existence check is unchanged; ADD a one-line clarification that the resilient form's anchor (`cd`/`Set-Location $CLAUDE_PROJECT_DIR`) is expected and that the extractable token remains the space-preceded `.harness/scripts/<name>.<ext>` (so a reader hand-computing congruence parses the same token). Interpreter-availability WARN unchanged. **[1 edit point: status SKILL]**

**Surface 7 — `harness-init` step 10b + `harness-adopt` step 6.3 + step-5/6 derivation tables.**
- init step-5 `{{…}}_COMMAND` table + adopt step-6 substitution table: the documented OS-picked value per event → the resilient strings (both OS). These are the human-readable derivations the model follows when it writes a real settings.json; they must match the `.tmpl`'s post-substitution bytes.
- init step 10b + adopt step 6.3 terminal congruence assert: the documented extract-and-check pattern is UNCHANGED (token shape preserved); confirm the prose still describes the same left-bounded ERE. **[2 edit points: init SKILL table, adopt SKILL table]** (the 10b/6.3 assert prose: no change needed beyond confirming.)

Plus the template + dogfood + slice-B + version surfaces:
**[1] `settings.json.tmpl`** placeholder values become resilient (the four `{{…}}` stay; their substituted output is resilient — actually no edit to the `.tmpl` body since it holds tokens; the resilient form is produced by substitution. **0 edit points to the .tmpl body**; F.2 still finds `{{GUARD_COMMAND}}` + PreToolUse.)
**[2] `.claude/settings.json`** (dogfood) hooks → empty `{}` + `_hooks_moved`. **[1]**
**[3] `.claude/settings.local.json`** new, resilient pwsh hooks. **[1]**
**[4] `.gitignore`** add `.claude/settings.local.json`. **[1]**
**[5] verify_all F.2** read dogfood hooks from settings.local.json (fallback) in both shells. **[2]** (folded conceptually with J.1's surface-1 but distinct check — see §9 risk.)
**[6] G.3/G.4 version fan-out:** plugin.json, marketplace.json, README.md badge, README.zh-CN.md badge, CHANGELOG `## [0.44.0]`. **[5]**

**Edit-point rollup (lockstep total = 22):** J.1 ×2 · test-init ×2 · test-harness-upgrade ×2 · upgrade/migrate ×4 · status ×1 · init+adopt tables ×2 · F.2 ×2 · settings.json ×1 · settings.local.json ×1 · .gitignore ×1 · version fan-out ×4 (plugin/marketplace/2 READMEs) + CHANGELOG ×1 = **22**. (E.4b/D.4b ×6 tmpls = **0 edit, verify-only** — OQ-3a's payoff. The `.tmpl` body = 0 edit.)

---

## 9. Risk analysis (each with mitigation)

1. **R1 — `$CLAUDE_PROJECT_DIR/`-prefix accidentally used instead of the `cd`-anchor (blinds every scan).** If a Developer "simplifies" the form to `bash "$CLAUDE_PROJECT_DIR/.harness/scripts/…"`, the `/` before `.harness/` breaks the ERE boundary → E.4b/D.4b/status/init-10b silently stop catching dangling sync hooks (T-020 regression) AND Fixture A/P existence checks break. **Mitigation:** the design mandates the `cd`/`Set-Location` shape (§3.2); the test-init "every command path exists" + the test-harness-upgrade Fixture A/P/H assertions exercise the extracted token, so a prefix-form regresses them loudly; QA must add a mutation that deletes the wired script in a resilient project and confirms E.4b still FAILs (AC-12).

2. **R2 — guard-rm accidentally fail-open.** A copy-paste of the convenience idiom onto guard-rm (adding `[ -f ]`+`|| exit 0`) silently permits destructive Bash when the guard is missing (NFR-Safety, the single non-negotiable). **Mitigation:** §3.4 specifies guard-rm with NO pre-test and NO `exit 0`; AC-5 mutation (delete guard-rm, attempt destructive command, assert NOT silently permitted) is the gate; the design explicitly forbids the convenience terminator for guard-rm.

3. **R3 — JSON-escaping / cross-shell byte-drift of the command string.** The inner `\"` around `$CLAUDE_PROJECT_DIR`/`$env:CLAUDE_PROJECT_DIR`, plus PS `[System.IO.File]::WriteAllText` dropping the trailing newline vs bash heredoc adding one (insight 2026-06-08), can make the upgrade `.ps1` and `.sh` emit byte-different settings, breaking the byte-identity/idempotence assertions (Fixture M2/H2/P2nd) and the exact-string test-init grep. **Mitigation:** single-source the exact JSON-escaped literal (§3.5); reuse the existing write-time-newline discipline already in upgrade/migrate; QA cross-shell `cmp` of the rewritten settings (T-014/T-021 family); the `*_COMMAND` test literals are the canonical bytes both shells must reproduce.

4. **R4 — A8 rewrite is over-eager and rewrites a user's intentional custom hook.** The brittle→resilient rewrite (S3.2) must only touch commands whose extractable token is a harness script (`.harness/scripts/{harness-sync,guard-rm,ambient-*}.<ext>`), never a user's `build-scripts/deploy.sh`. **Mitigation:** S3.2 reuses the left-bounded ERE (the C1 false-positive guard — Fixture H's `build-scripts/deploy.sh` must stay un-flagged AND un-rewritten); gate on `target_present` + the harness-tool name set; Fixture H's "[C1] custom hook NOT flagged" assertion extended to "NOT rewritten".

5. **R5 — Slice B breaks F.2 (guard-rm wiring) because the committed settings.json lost its hooks.** F.2 today requires `.claude/settings.json` to contain PreToolUse + Bash matcher + guard-rm; after B2 the committed file has empty hooks. **Mitigation:** F.2 in both shells reads the dogfood PreToolUse evidence from `.claude/settings.local.json` when present (fallback chain: prefer settings.local.json for the dogfood-hook assertions), leaving the template-`.tmpl` `{{GUARD_COMMAND}}` + PreToolUse checks intact. B5 explicitly requires this; AC-11 verifies F.2 + J.1 PASS post-B. (This is the one place slice B forces a real check edit — flagged for the Gate.)

6. **R6 — anchor unavailable / interpreter mismatch confused with script-missing.** OQ-2 degenerate `$CLAUDE_PROJECT_DIR` and the no-pwsh-box case are distinct from script-missing. **Mitigation:** §3.3/§3.4 handle unset/empty var (convenience no-op, guard fail-closed); interpreter-unavailable stays a status §3c WARN (out-of-scope to auto-rewrite, boundary §4-4); the design does not try to swallow interpreter-not-found.

---

## 10. Migration / rollout plan

1. **Sequence A-before-B (per RA §10).** Land A first: define the resilient strings (§3), wire the `.tmpl` substitution output + the five derivation sites + the A8 repair + the test literals. Then B: relocate the dogfood hooks into `.claude/settings.local.json` **in the resilient pwsh form A defined** (A9 writes the form B's file carries), strip the committed settings.json hooks, add the .gitignore line, retarget F.2/J.1.
2. **Backwards compatibility.** Existing user projects on the brittle form are fixed by plugin update + `/harness-upgrade` (or `migrate-scripts-layout`) — the A8 rewrite. Already-cached plugin versions 0.19.0–0.31.0 are immutable (out-of-scope §3.7); users get the fix on update.
3. **Feature flags.** None — this is a wiring + hygiene change, not a runtime-toggled feature.
4. **Idempotence / rollback.** A8 is idempotent (sentinel-gated; second run NOOP, no `.bak` churn). Each settings rewrite writes a timestamped `.bak` (rollback = restore the `.bak`). Slice B: `.claude/settings.local.json` is git-ignored; reverting B = move the four hooks back and drop the gitignore line (no data loss — permissions stayed in the committed file throughout).
5. **Gate sequence.** `verify_all` 32/32 both shells (PS run may be operator-pending per repo convention); test-init + test-harness-upgrade green; G.3/G.4 enforce the 0.44.0 fan-out.
6. **Version stamp (§7 RA / G.3-G.4).** plugin.json + marketplace.json + README.md badge + README.zh-CN.md badge → 0.44.0; CHANGELOG `## [0.44.0]` entry. No count claims change (skills 17 / agents 8 / checks 32) — verified against the count-ledger decoy discipline (insight 2026-06-19): do NOT touch historical `## [x.y.z]` CHANGELOG rows, append-only tasks.md rows, archived proposals, or insight lines describing past states.

---

## 11. Out-of-scope clarifications (design boundaries)

- Does NOT change what `harness-sync` / `guard-rm` / `ambient-*` DO — only the command-string wiring + the dogfood-distribution (§3.2 RA).
- Does NOT convert the harness Stop hook into a plugin `hooks/hooks.json` hook — it is a per-project dev-sync, not a global plugin hook (§3.1 RA).
- Does NOT add a new `verify_all` check, a new placeholder token, or change OS-detection (§3.3-3.5 RA; feedback_design_over_guards).
- Does NOT touch the pre-commit git hook / install-hooks path (already guarded; §3.6 RA).
- Does NOT change user projects' settings.json layout in slice B (slice B is repo-dogfood-only; users keep their resilient hooks in the committed settings.json they own — A6; boundary §4-7 = no interaction).
- Does NOT auto-rewrite an interpreter-mismatch (pwsh-on-no-pwsh) — that stays a status §3c WARN (boundary §4-4).

---

## 12. Partition assignment

No `.harness/agents/dev-*.md` files exist in this repo (single-Developer mode — confirmed: `.harness/agents/` holds only partition agents and is empty here). Partition section omitted per the contract's single-Developer allowance.

---

## 13. Verdict

**READY.** The resilient command strings are specified exactly for both OSes (convenience + guard-rm, §3.3-3.5); OQ-1a/OQ-2a/OQ-3a/OQ-4a are resolved on RA's recommended answers; the load-bearing OQ-3 tension is resolved by the `cd`/`Set-Location` anchor shape that keeps the existing ERE + existence check untouched (OQ-3a achieved — §3.2); the 22 lockstep edit points are enumerated (with the 6 E.4b/D.4b tmpls confirmed as **0-edit verify-only**); the one genuinely new behavior (A8 brittle→resilient rewrite) is decomposed as an adapter on the existing presence-gated machinery; slice B's F.2/J.1 retarget is identified as the single check edit and flagged for the Gate; version 0.44.0 fan-out + no count flip is specified. A junior Developer can implement from §3-§8 without further design decisions. The one residual that needs a Developer-time confirmation (not a blocker): re-verify via context7 that `$CLAUDE_PROJECT_DIR` is injected into all four hook events (§3.6) before relying — the design degrades safely if it is ever absent.
