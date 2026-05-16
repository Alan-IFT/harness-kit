# 04 — Development Record

- Task: `T-001 / ai-safety-guardrails`
- Mode: `full`
- Partition: `developer` (single)
- Date: 2026-05-17

## Summary

Shipped the v0.15.0 AI safety guardrails bundle: cross-platform `guard-rm.{ps1,sh}` PreToolUse hook that blocks destructive commands (`rm` / `Remove-Item` / `find -delete` / nested `pwsh -c`) targeting paths outside the project's `.git/` ancestor, with per-call `HARNESS_ALLOW_OUTSIDE_RM=1` override; auto-installed via `.claude/settings.json` (dogfood + template); new `.harness/rules/75-safety-hook.md` rule fragment (en + zh); plus D1 (Copilot opt-in continuous mode docs) and D2 (Claude Code sub-agent dispatch callout) documentation surface. verify_all 26 → 27 (new `F.2`); test-init 162 → 177 (new wiring assertions × 3 project types).

## Files changed

### Stage A — D3 scripts (foundation, template SOT)
- `skills/harness-init/templates/common/scripts/guard-rm.ps1` — NEW. Full algorithm per design §4.2 / §4.7: stdin JSON read, override env check, `.git/` ancestor walk, command truncation (8 KB), pipe split, quote-aware tokenizer, sudo strip, nested-pwsh recursion (depth ≤ 2), `find -delete` special case, find-predicate skip, path leaf-only normalization (`..`/`.` only, no realpath), descendant check, BLOCK message format (verbatim per §4.4 with the design-mandated "See .harness/rules/75-safety-hook.md to fully disable" closing line).
- `skills/harness-init/templates/common/scripts/guard-rm.sh` — NEW. Mirrors the PowerShell algorithm step-by-step. Uses `arr=()` (not `declare -a`) per insight 2026-05-16 declare-a-under-set-u. JSON extraction via python3 if real-Python is available, sed-heuristic fallback otherwise (Windows MS-Store python stub detected and bypassed). Uses global `_TOKENS` / `_SEGS` arrays for sub-function returns (eval-name-ref pattern was too fragile under `set -u`).
- `scripts/guard-rm.ps1`, `scripts/guard-rm.sh` — mirrored from template via `scripts/sync-self.ps1` (Layer 1 sync).
- `scripts/sync-self.ps1` (MODIFY) — added 2 mappings + extended doc-header.
- `scripts/sync-self.sh` (MODIFY) — added "Mapping 5: guard-rm scripts" with two `sync_file` calls.

### Stage B — D3 rule fragment (3 surfaces)
- `.harness/rules/75-safety-hook.md` — NEW (dogfood, 105 lines, under the 200-line rule cap). Contract, override path, disable path, failure modes, boundaries.
- `skills/harness-init/templates/common/.harness/rules/75-safety-hook.md.tmpl` — NEW. Content essentially identical (no placeholders at v0.15; `.tmpl` suffix kept per sibling-fragment convention).
- `skills/harness-init/templates/i18n/zh/common/.harness/rules/75-safety-hook.md.tmpl` — NEW Chinese translation. Code identifiers (`HARNESS_ALLOW_OUTSIDE_RM`, command examples) stay English; prose is Chinese.

### Stage C — D3 wiring + AI-GUIDE updates (multi-surface)
- `.claude/settings.json` (MODIFY) — added `hooks.PreToolUse[]` block with `matcher: "Bash"` calling `pwsh -File scripts/guard-rm.ps1`. Stop / permissions blocks untouched (additive).
- `skills/harness-init/templates/common/.claude/settings.json.tmpl` (MODIFY) — same shape with `{{GUARD_COMMAND}}` placeholder.
- `AI-GUIDE.md` (MODIFY) — added: (a) `75-safety-hook.md` index line; (b) "Claude Code sub-agent dispatch — already implemented" callout; (c) "AI tool flow modes" section (3 flows); (d) `26/26` → `27/27` on lines 35 + 67; (e) **per gate condition C-2**: "+ 4 script pairs (harness-sync, install-hooks, archive-task)" → "+ 4 script pairs (… + guard-rm)" — count now matches the 4 names listed (was pre-v0.15 drift: count said 4, list had 3; this commit fixes both).
- `skills/harness-init/templates/common/AI-GUIDE.md.tmpl` (MODIFY) — (a) `75-safety-hook.md` index line; (b) sub-agent callout; (c) AI tool flow modes section.
- `skills/harness-init/templates/i18n/zh/common/AI-GUIDE.md.tmpl` (MODIFY) — Chinese versions of (a)+(b)+(c). F-5 NOT applied: the template's `F.*` reference is correct in user-project context (user-project verify_all uses `F.*` for size checks, dogfood uses `I.*`). Treated as a misread by the gate reviewer; not a real drift to fix.
- `.harness/rules/60-tool-handoff.md` (MODIFY) — appended "Copilot continuous mode (opt-in)" subsection: activation phrase `continuous mode` / `走全流程`, HARD STOP after Gate Review, session-boundary reset.
- `skills/harness-init/templates/common/.harness/rules/60-tool-handoff.md` (MODIFY) — same.
- `skills/harness-init/templates/i18n/zh/common/.harness/rules/60-tool-handoff.md` (MODIFY) — Chinese version (`走全流程`).
- `.github/copilot-instructions.md` (MODIFY) — third red line: "One role at a time **unless the user has explicitly enabled continuous mode** (see `60-tool-handoff.md`)".
- `skills/harness-init/templates/common/.github/copilot-instructions.md.tmpl` (MODIFY) — same.
- `skills/harness-init/templates/i18n/zh/common/.github/copilot-instructions.md.tmpl` (MODIFY) — Chinese version with **连续模式** phrasing.

### Stage D — verify_all + locations
- `scripts/verify_all.ps1` (MODIFY) — D.2 `$allowed` array adds `{{GUARD_COMMAND}}`; new `F.2` check replaces the v0.14.x vacated-comment slot. Asserts: both dogfood + template guard scripts exist; dogfood `.claude/settings.json` JSON-parses with `hooks.PreToolUse[0].matcher == "Bash"` and command matches `guard-rm\.(ps1|sh)`; template `.claude/settings.json.tmpl` contains `{{GUARD_COMMAND}}` + `PreToolUse`. PASS-level (FAIL on miss).
- `scripts/verify_all.sh` (MODIFY) — same D.2 + F.2 (bash grep-heuristic equivalent for the JSON checks, mirroring G.3's pattern).
- `.harness/rules/40-locations.md` (MODIFY) — `26 items at v0.14` → `27 items at v0.15`; **per gate condition C-3**: `Placeholder whitelist enforced (5 allowed)` → `(7 allowed)` (was already 1 off; +`{{GUARD_COMMAND}}` makes 7); new F.2 line.

### Stage E — harness skills
- `skills/harness-init/SKILL.md` (MODIFY) — step 5 placeholder table adds `{{GUARD_COMMAND}}` with OS-detection rule mirroring `{{SYNC_COMMAND}}`; step 8 mentions the always-on guard; step 11 output lists `guard-rm.{ps1,sh}`.
- `skills/harness-adopt/SKILL.md` (MODIFY) — step 5 plan adds `scripts/guard-rm.{ps1,sh}` + `.harness/rules/75-safety-hook.md` + new "PreToolUse hook merge" subsection; step 6 specifies the JSON-merge logic for `.claude/settings.json` (preserve existing keys; append PreToolUse if absent; flag conflict if matcher==Bash entry points elsewhere).
- `skills/harness-status/SKILL.md` (MODIFY) — three new required-asset rows (guard-rm × 2 + PreToolUse hook); new `### 3b. Sub-agent dispatch / safety hook` block; health score denominator 11 → 12 with `+1` for "PreToolUse guard hook installed and points at existing guard-rm scripts"; "All 12 required assets" → "All 15 required assets" to reflect the 3 new rows.

### Stage F — test-init regression (gate condition C-1)
- `scripts/test-init.ps1` (MODIFY) — `$vars` adds `GUARD_COMMAND`; five new `Assert` calls per project type (guard-rm.ps1 / guard-rm.sh present; settings.json parses; matcher == "Bash"; command references guard-rm). Total 162 → 177.
- `scripts/test-init.sh` (MODIFY) — `SYNC_COMMAND` case statement extended with `GUARD_COMMAND`; `substitute` adds `{{GUARD_COMMAND}}` sed; same five assertions per project type with python3 (real-probed, not just `command -v`) and a 3-assertion grep fallback for Windows. Total 162 → 177 (matched to PS).

### Stage G — evals fixture + driver (acceptance B2)
- `evals/guard-rm-cases.md` — NEW. 11 input/expected pairs covering BLOCK / ALLOW / override / nested-pwsh / find-delete / glob / tilde-expansion / in-repo cases.
- `scripts/test-guard-rm.ps1` — NEW. Drives the 11 cases through `scripts/guard-rm.ps1` via stdin JSON; asserts exit codes (0 = ALLOW, 2 = BLOCK).
- `scripts/test-guard-rm.sh` — NEW. Mirror, with python3-real-probe for JSON encoding and a string-escape fallback otherwise. NOT added to verify_all (out of scope v0.15 per design §15).

### Stage H — version drift
- `.claude-plugin/plugin.json` — `0.14.0` → `0.15.0`.
- `.claude-plugin/marketplace.json` — `0.14.0` → `0.15.0`.
- `README.md` — version badge `0.14.0` → `0.15.0`; `verify_all-26%2F26` → `27%2F27`; `test-init-162%2F162` → `177%2F177`; "regression-testing" section counts updated to 27/177/82; roadmap row for `0.15.0` added; `0.15+ planned` → `0.16+ planned`.
- `README.zh-CN.md` — same.
- `CHANGELOG.md` — new `## [0.15.0] - 2026-05-16` section describing D1+D2+D3 with file lists and migration notes.
- `docs/walkthrough.html` — `26 checks: 26 PASS` → `27 checks: 27 PASS`; `Health: 11/11` → `12/12`.

### Cross-cutting
- `docs/dev-map.md` — `.harness/rules/` enumeration brought up to date (was missing 05/60/65/70 from before this task; added 75 with the same pass); `scripts/` listing updated for all current scripts including guard-rm + test-guard-rm; placeholder count 5 → 7 with the new dev-map rule "any new placeholder must land in BOTH verify_all D.2 whitelists".

## verify_all result

- Baseline (before any changes, captured 2026-05-16 23:50): PASS 26, WARN 0, FAIL 0.
- After all changes: PASS 27, WARN 0, FAIL 0 (both `.ps1` and `.sh` agree).
- Delta: +1 PASS (new F.2). No new failures, no warnings introduced. All five document-size WARN guards (I.1-I.5) still green — `AI-GUIDE.md` at 94/200, new `75-safety-hook.md` at 105/200, `60-tool-handoff.md` at 142/200.

## Additional regression runs

| Run | Before | After | Notes |
|---|---|---|---|
| `verify_all.ps1` | 26/26 PASS | 27/27 PASS | New `F.2` |
| `verify_all.sh` | 26/26 PASS | 27/27 PASS | New `F.2` (bash grep-heuristic equivalent) |
| `test-init.ps1` | 162/162 | 177/177 | +5 wiring assertions × 3 project types |
| `test-init.sh` | 162/162 | 177/177 | Same 5 assertions, matched granularity |
| `test-real-project.ps1` | 82/82 | 82/82 | Unchanged |
| `test-guard-rm.ps1` | n/a (new) | 11/11 | Acceptance B2 |
| `test-guard-rm.sh` | n/a (new) | 11/11 | Acceptance B2 |

## Design drift (DESIGN DRIFT flags for reviewer)

1. **F-5 (template `AI-GUIDE.md.tmpl:26` says `F.*` not `I.*`)** — NOT FIXED. Dispatch said "opportunistically fix … if you see it". On inspection, the `F.*` reference is correct in user-project context: user-project verify_all uses `F.*` for the doc-size WARN group (confirmed by `Grep` of `templates/generic/scripts/verify_all.ps1.tmpl:151-204` showing F.1-F.6). The gate reviewer appears to have misread it as drift; in dogfood the size-WARN group is `I.*`, in user-projects it's `F.*`, both correct. Flagged here for the Code Reviewer to confirm.

2. **PowerShell `guard-rm.ps1` algorithm bugs caught during the `test-guard-rm.ps1` run** — fixed and re-verified, but worth flagging:
   - Initial `Resolve-AbsoluteLeaf` used `[System.Collections.ArrayList]` + `[string]::Join` which yielded `System.Collections.ArrayList` as the rendered path (cases 5, 6, 10 reported BLOCK on in-repo paths). Switched to `[List[string]]` + `.ToArray()` join.
   - `$home` was used as a local variable name — collides with the auto-variable; expansion broke for `~`-prefixed paths (case 3 crashed with exit 1). Renamed to `$homePath`.
   These are now correct in `templates/common/scripts/guard-rm.ps1` and mirrored to `scripts/guard-rm.ps1`.

3. **bash `guard-rm.sh` algorithm bugs caught during the `test-guard-rm.sh` run** — fixed:
   - Original `tokenize` / `split_pipes` used `eval "$arr_name=()"` to write back into a caller-named array. Under `set -u` the eval also clobbered the local `tokens` variable in the enclosing scope on the second pass. Switched to global `_TOKENS` / `_SEGS` arrays with explicit caller-side snapshots before recursive calls.
   - JSON `command` extraction sed regex `s/.*"command":"\(\([^"\\]\|\\.\)*\)".*/\1/p` did not handle escaped quotes (`\"`) from Claude Code; case 8 (nested `pwsh -c "Remove-Item …"`) returned empty. Switched to greedy `s/.*"command":"\(.*\)"[[:space:]]*}.*/\1/p` with shell-side unescape of `\"` and `\\` after capture.
   - Windows Microsoft Store python3 stub satisfies `command -v python3` but exits non-zero on invocation. Added a real `echo '' | python3 -c 'pass'` probe before trusting python; sed-heuristic + bash parameter-expansion unescape covers the fallback.
   - `test-guard-rm.sh` had `set +e` / `set -e` around the inner `bash "$guard"` call which left `-e` enabled for the post-call `((pass++))`. The arithmetic returned 0 (first increment) which the shell treats as false, causing exit. Removed the `-e` toggle entirely (`-uo pipefail` is sufficient and the post-call exit-code capture is the only thing we needed).

4. **Design §10.3 says "5 script pairs (… + guard-rm)"** — I wrote "4 script pairs" per gate condition C-2's explicit instruction. The pre-v0.15 line said "4 script pairs" but listed 3 (harness-sync, install-hooks, archive-task) — drift the gate reviewer caught. Adding guard-rm brings the listed count to 4, matching the "4 script pairs" wording. The design's "5 pairs" was based on a different count basis (it included agents/ dir as one of the "5"). C-2's "fix-don't-propagate" instruction is what landed.

## Open issues for review

- None blocking. The Code Reviewer should sanity-check:
  - Whether F-5 should be touched (I argue no, see drift #1).
  - The bash `guard-rm.sh` parser is the most complex new piece; the 11 acceptance cases all pass, but the parser may have edge cases not in the fixture (`-name` patterns with embedded quotes, deeply-nested heredocs, command substitution `$(rm …)`). Out of scope per design §1 / §15; documented contract is "parse failure → BLOCK".
  - JSON-merge logic in `harness-adopt` is described in prose (skill markdown) but not executed by any code path yet — the merge happens when a user runs `/harness-adopt` against a project with a pre-existing `.claude/settings.json`. Manual testing on a real adopt-merge case is a QA item.

## Dev-map updates

Lines added/updated in `docs/dev-map.md`:
- `.harness/rules/` enumeration now lists 05/60/65/70/75 (was only 00/10/20/30/40 pre-task — drift from the v0.10+ era, fixed in this pass).
- `scripts/` section gained `install-hooks`, `archive-task`, `guard-rm`, `test-guard-rm`; assertion counts updated (test-init 86→177, test-real-project 64→82).
- Template-placeholder convention: 5 → 7 with `{{SYNC_COMMAND}}` (already added in v0.9.x) and `{{GUARD_COMMAND}}` (this task); explicit reminder added to update D.2 in BOTH `verify_all.ps1` and `.sh`.

## Insight to surface (optional)

`pwsh function returning System.Collections.ArrayList via [string]::Join coerces the joined output to the ArrayList's toString instead of the concatenated string; [List[string]]::new().ToArray() + [string]::Join works as expected · evidence: scripts/guard-rm.ps1 first integration with test-guard-rm.ps1 cases 5/6/10 showing 'System.Collections.ArrayList' as offending path.`

This is non-obvious and beat the reasonable prior. It does not appear in any existing AI-GUIDE.md / rule / agent file, and `Grep`ing the repo before this task surfaced no precedent for path-normalization helpers — so a future agent writing similar tokenization / list-join logic in pwsh has no current insight to consult. The PM may choose to consolidate this into 07_DELIVERY.md's `## Insight` section for archive-task harvest into `.harness/insight-index.md` (if it deems the cost-benefit favorable for a 30-slot ledger).

## Verdict

READY FOR REVIEW

---

## Rollback #1 — fixes (2026-05-17)

QA's `06_TEST_REPORT.md` BLOCKED ON DEV with 2 CRITICAL + 1 MAJOR + 2 MINOR
findings under adversarial testing. The 11-case fixture passed, but it didn't
exercise the failing patterns. This rollback applies targeted fixes for D-1,
D-2, D-3 and extends the fixture suite 11 → 17 to lock the bypasses out of
future regressions. D-4 / D-5 stay as documented known limitations.

### Fix 1 — D-1 + D-2 (shared root cause): find-predicate skip applied to every verb

**Root cause**: the destructive-verb argument walker (`guard-rm.{ps1,sh}` after
the early returns for `pwsh` and `find`) maintained its own copy of the
find-predicate list (`-name -type -regex -iname -perm -mtime -size -path -ipath
-newer`) and used `-contains` / a `for-fp-in-list` loop to decide whether to
skip the next token as "the value of a predicate flag". Three issues compounded:

1. **The predicate list is `find`-specific**, but the skip ran for every
   destructive verb — letting `rm -name /etc/passwd`, `rm -path /etc/foo`,
   `rm -type f /etc/x`, `rm -mtime +0 /etc/x` all bypass with a 5-byte
   `-rf` → `-name` substitution.
2. **PowerShell's `-contains` is case-insensitive by default** on strings, so
   `Remove-Item -Path C:\Windows\System32` was caught by the same skip: `-Path`
   matched the list entry `-path` case-insensitively, the next token
   (`C:\Windows\System32`) was then consumed as if it were a predicate value,
   and the verb produced zero offending paths → ALLOW.
3. The `find` branch above (already correctly verb-gated) handles legitimate
   `find -delete` cases on its own. The duplicated skip below it served no
   purpose and was pure attack surface.

**Fix**: remove the find-predicate skip entirely from the non-`find`
destructive-verb walker in both shells. Flags (`-rf`, `-Force`, `-Path`,
`-Recurse`, etc.) are still skipped as flags (they all start with `-`), but the
next token is NOT auto-consumed — it's treated as a candidate path token, so
the descendant check runs. Comments added at the bug site reference the QA
report.

- `skills/harness-init/templates/common/scripts/guard-rm.ps1` lines 237-258 —
  removed the `$findPredicates -contains $t` skip; added "intentionally
  disabled here" comment block.
- `skills/harness-init/templates/common/scripts/guard-rm.sh` lines 273-290 —
  same fix, removed the `for fp in $find_predicates` inner loop.
- `scripts/guard-rm.ps1` and `scripts/guard-rm.sh` — mirrored from template via
  `pwsh -File scripts/sync-self.ps1` (Layer 1 sync). E.1 byte-identity check
  still PASS.

### Fix 2 — D-3 (MAJOR perf NFR): add `-NoProfile` to the pwsh hook commands

**Root cause**: `.claude/settings.json` hook commands ran `pwsh -File <script>`
with NO `-NoProfile`. On any developer machine with a non-trivial `$PROFILE`
(this user's profile runs a ~3s IP-status banner), every Bash tool call ate the
full startup cost. QA measured p50 = 3,769 ms vs the 50 ms NFR.

**Fix**: add `-NoProfile` to **both** the PreToolUse (guard) and Stop (sync)
hook commands. Done in three places (dogfood + template substitution rule +
test-init harness):

- `.claude/settings.json` — Stop hook `command` → `pwsh -NoProfile -File
  scripts/harness-sync.ps1`; PreToolUse hook `command` → `pwsh -NoProfile -File
  scripts/guard-rm.ps1`. (The Stop hook is unchanged territory but gets the
  free perf win.)
- `skills/harness-init/SKILL.md` step 5 — `{{SYNC_COMMAND}}` and
  `{{GUARD_COMMAND}}` Windows resolutions both updated to include `-NoProfile`,
  with inline comment pointing at 06_TEST_REPORT.md D-3.
- `scripts/test-init.ps1` and `scripts/test-init.sh` — the `$syncCmd` /
  `$guardCmd` substitution values bumped to match SKILL.md. This keeps
  test-init's simulation of what `/harness-init` produces in lockstep with the
  real placeholder resolution rule.

No new placeholder added → `verify_all` D.2 whitelist needs no change. F.2's
regex `guard-rm\.(ps1|sh)` still matches `pwsh -NoProfile -File
scripts/guard-rm.ps1`. Template `.claude/settings.json.tmpl` still uses
`{{GUARD_COMMAND}}` placeholder unchanged.

### Fix 3 — fixture suite extension 11 → 17

Six new cases per QA's required-before-routing list, plus one `find`-branch
boundary case to lock the verb-gating:

- Case 12: `Remove-Item -Path C:\Windows -Recurse` → BLOCK (regression for D-1).
- Case 13: `rm -name /etc/passwd` → BLOCK (regression for D-2).
- Case 14: `rm -path /etc -delete` → BLOCK (combined predicate+flag confusion).
- Case 15: `rm -type f /etc/x` → BLOCK.
- Case 16: `rm -mtime +0 /etc/x` → BLOCK.
- Case 17: `find /tmp -name '*.log' -delete` → BLOCK (confirms the `find`
  branch still BLOCKs outside-repo paths under its own predicate handling).

Added to:
- `evals/guard-rm-cases.md` — 6 new table rows under v0.15.1 rollback heading.
- `scripts/test-guard-rm.ps1` — 6 new `@{...}` entries in `$cases`.
- `scripts/test-guard-rm.sh` — 6 new `id|cmd|override|expected` rows.

Both `test-guard-rm.ps1` and `test-guard-rm.sh` now report PASS 17 / FAIL 0.

### Manual verification (per dispatch §Verification step 5)

```text
$ printf '%s' '{"tool_input":{"command":"Remove-Item -Path C:\\\\Windows\\\\System32 -Recurse"}}' \
    | pwsh -NoProfile -File scripts/guard-rm.ps1; echo "exit=$?"
harness-kit guard-rm: BLOCKED — destructive command targets path outside project root.
  Command: Remove-Item -Path C:\Windows\System32 -Recurse
  Offending path(s):
    - C:\Windows\System32 (outside C:\Programs\HarnessEngineering)
  Override (only if you really mean this): re-issue the command with the env var
    HARNESS_ALLOW_OUTSIDE_RM=1 set for that single call.
  See .harness/rules/75-safety-hook.md to fully disable.
exit=2

$ echo '{"tool_input":{"command":"rm -name /etc/passwd"}}' \
    | bash scripts/guard-rm.sh; echo "exit=$?"
harness-kit guard-rm: BLOCKED — destructive command targets path outside project root.
  Command: rm -name /etc/passwd
  Offending path(s):
    - /etc/passwd (outside /c/Programs/HarnessEngineering)
  Override (only if you really mean this): re-issue the command with the env var
    HARNESS_ALLOW_OUTSIDE_RM=1 set for that single call.
  See .harness/rules/75-safety-hook.md to fully disable.
exit=2
```

Both reproducers from QA's D-1 / D-2 sections now produce exit 2 (BLOCK). In-
repo cases (`rm -rf build/`) still produce exit 0 (ALLOW) via case 5 and a
spot-check.

### Regression sweep after rollback fixes

| Run | Result | Delta vs first-pass baseline |
|---|---|---|
| `pwsh -NoProfile -File scripts/verify_all.ps1` | 27 PASS / 0 WARN / 0 FAIL | unchanged |
| `bash scripts/verify_all.sh` | 27 PASS / 0 WARN / 0 FAIL | unchanged |
| `pwsh -NoProfile -File scripts/test-init.ps1` | 177 / 177 PASS | unchanged |
| `bash scripts/test-init.sh` | 177 / 177 PASS | unchanged |
| `pwsh -NoProfile -File scripts/test-real-project.ps1` | 82 / 82 PASS | unchanged |
| `pwsh -NoProfile -File scripts/test-guard-rm.ps1` | **17 / 17 PASS** | +6 (was 11) |
| `bash scripts/test-guard-rm.sh` | **17 / 17 PASS** | +6 (was 11) |

### Files touched in this rollback

- `skills/harness-init/templates/common/scripts/guard-rm.ps1` — find-predicate
  skip removed from non-`find` destructive-verb walker.
- `skills/harness-init/templates/common/scripts/guard-rm.sh` — same.
- `scripts/guard-rm.ps1` / `scripts/guard-rm.sh` — synced from template (Layer 1
  byte-identity preserved).
- `.claude/settings.json` — Stop and PreToolUse hook `command` strings now
  include `-NoProfile`.
- `skills/harness-init/SKILL.md` step 5 — `{{SYNC_COMMAND}}` and
  `{{GUARD_COMMAND}}` Windows resolutions include `-NoProfile` + perf
  rationale comment.
- `scripts/test-init.ps1` / `scripts/test-init.sh` — `$syncCmd` / `$guardCmd`
  substitution values match the new SKILL.md rule.
- `evals/guard-rm-cases.md` — 6 new rows (cases 12-17).
- `scripts/test-guard-rm.ps1` / `scripts/test-guard-rm.sh` — 6 new cases each.
- `docs/features/ai-safety-guardrails/04_DEVELOPMENT.md` — this `## Rollback #1`
  section appended.

### Design drift in this rollback (DESIGN DRIFT flags)

None. All three fixes are within the design's existing contract:
- D-1 / D-2 fix is the design-intended behavior (the design §4.7 says only
  `find` accepts predicates; the prior implementation duplicated the skip out
  of caution and that caution was the attack surface).
- D-3 perf fix is a wiring change; the design's NFR-Perf already required
  ≤ 50 ms median; `-NoProfile` is the only realistic mechanism on Windows.

### Open issues NOT addressed by this rollback

- **D-4 MINOR** (override env var set in user profile gives silent permanent
  disable): kept as documented known limitation in 06_TEST_REPORT.md. Mitigation
  is `/harness-status` warning when `HARNESS_ALLOW_OUTSIDE_RM=1` is set; not
  implemented this pass. Per dispatch §Optional, left as known limitation.
- **D-5 MINOR** (depth-3+ nested pwsh silently allows after quote-strip
  collapses): adversarial only; design's "parse-failure → BLOCK" philosophy
  catches the simpler nesting cases. Left as known limitation per dispatch.
- N-A / N-B / N-C: unchanged from QA's report.

### Insight to surface (rollback addendum)

`PowerShell -contains is case-insensitive for strings by default, so a list
intended for case-sensitive matching (e.g. find predicate flags like '-path')
will silently match named-parameter shorthands of cmdlets with different
casing (e.g. Remove-Item -Path). Use -ccontains for case-sensitive matching,
or scope the lookup so the casing collision can't fire. · evidence:
06_TEST_REPORT.md D-1 + this rollback fix in guard-rm.ps1 lines 237-258.`

This is a non-obvious pwsh language quirk that bit the v0.15.0 guard hard
under adversarial QA. Worth recording for future agents writing PowerShell
token-classification logic. The PM may include in 07_DELIVERY.md's `## Insight`
section.

## Verdict (after rollback)

READY FOR REVIEW (post-rollback)
