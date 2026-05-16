# 02 — Solution Design · ai-safety-guardrails

- Task: `T-001 / ai-safety-guardrails`
- Mode: `full`
- Author: Solution Architect
- Date: 2026-05-16
- Upstream input: `docs/features/ai-safety-guardrails/01_REQUIREMENT_ANALYSIS.md` (verdict `READY`, 19 in-scope items, 12 recorded decisions)
- Target version: **v0.15.0**
- Partition: `developer` (single — `.harness/agents/dev-*.md` glob is empty)

---

## 1. Architecture summary

Three coordinated changes ship under one minor version bump:

- **D1 (documentation)**: a new "AI tool flow modes" section in `AI-GUIDE.md` plus its template, plus a "Copilot continuous mode (opt-in)" subsection in `60-tool-handoff.md` (dogfood + template + zh overlay), plus a tweaked third red line in both Copilot bootstrap stubs.
- **D2 (callout)**: a one-paragraph "Claude Code sub-agent dispatch — already implemented" note added to `AI-GUIDE.md` + its template + zh overlay; `skills/harness-status/SKILL.md` reports a `Sub-agent dispatch:` line.
- **D3 (real feature)**: a cross-platform guard-rm script pair (`scripts/guard-rm.ps1` + `scripts/guard-rm.sh`) invoked by a `PreToolUse` hook in `.claude/settings.json` (dogfood) and `.claude/settings.json.tmpl` (template). The script extracts path-shaped arguments from the about-to-run Bash command, resolves them against the nearest `.git/` ancestor, and exits non-zero (causing Claude Code to abort the tool call) when **any** resolved path falls outside the repo. Override is per-call `HARNESS_ALLOW_OUTSIDE_RM=1`. A new rule fragment `75-safety-hook.md` documents the contract. `sync-self` mirrors the new scripts; `verify_all` gains check `C.5` to assert the four install surfaces exist and reference each other.

System-level invariant after this lands: every project initialized or adopted by harness-kit at v0.15+ has the guard pre-wired; existing projects either re-adopt (merge prompt) or remain unguarded and the README/CHANGELOG flag that.

---

## 2. Affected modules (logical grouping)

### Group A — D1 documentation (English + zh)
- `AI-GUIDE.md` (dogfood, MODIFY)
- `skills/harness-init/templates/common/AI-GUIDE.md.tmpl` (MODIFY)
- `skills/harness-init/templates/i18n/zh/common/AI-GUIDE.md.tmpl` (MODIFY)
- `.harness/rules/60-tool-handoff.md` (dogfood, MODIFY)
- `skills/harness-init/templates/common/.harness/rules/60-tool-handoff.md` (MODIFY)
- `skills/harness-init/templates/i18n/zh/common/.harness/rules/60-tool-handoff.md` (MODIFY)
- `.github/copilot-instructions.md` (dogfood, MODIFY — red-line edit)
- `skills/harness-init/templates/common/.github/copilot-instructions.md.tmpl` (MODIFY — red-line edit)
- `skills/harness-init/templates/i18n/zh/common/.github/copilot-instructions.md.tmpl` (MODIFY — red-line edit)

### Group B — D2 callout
- `AI-GUIDE.md` (already in Group A — same edit batch)
- `AI-GUIDE.md.tmpl` (both English + zh — same edit batch)
- `skills/harness-status/SKILL.md` (MODIFY — add required-assets row + report line)

### Group C — D3 implementation: the guard script pair
- `scripts/guard-rm.ps1` (NEW, dogfood)
- `scripts/guard-rm.sh` (NEW, dogfood)
- `skills/harness-init/templates/common/scripts/guard-rm.ps1` (NEW, template SOT — `sync-self` mirrors back to dogfood)
- `skills/harness-init/templates/common/scripts/guard-rm.sh` (NEW, template SOT)

### Group D — D3 wiring
- `.claude/settings.json` (dogfood, MODIFY — add PreToolUse block)
- `skills/harness-init/templates/common/.claude/settings.json.tmpl` (MODIFY — add PreToolUse with `{{GUARD_COMMAND}}`)
- `.harness/rules/75-safety-hook.md` (NEW, dogfood — rule fragment)
- `skills/harness-init/templates/common/.harness/rules/75-safety-hook.md.tmpl` (NEW, template — content identical to dogfood at v0.15 since there are no placeholders; `.tmpl` suffix kept for consistency with sibling fragments)
- `skills/harness-init/templates/i18n/zh/common/.harness/rules/75-safety-hook.md.tmpl` (NEW — zh overlay translation)

### Group E — D3 install surfaces
- `scripts/sync-self.ps1` (MODIFY — add 2 mappings for guard-rm pair)
- `scripts/sync-self.sh` (MODIFY — add 2 `sync_file` calls)
- `skills/harness-init/SKILL.md` (MODIFY — step 4 lists guard-rm; step 5 adds `{{GUARD_COMMAND}}` placeholder; step 11 summary lists guard-rm)
- `skills/harness-adopt/SKILL.md` (MODIFY — step 5 plan, step 6 apply: PreToolUse merge logic)

### Group F — verify_all + AI-GUIDE indexing
- `scripts/verify_all.ps1` (MODIFY — add check `C.5`; extend D.2 placeholder whitelist with `{{GUARD_COMMAND}}`)
- `scripts/verify_all.sh` (MODIFY — same)
- `AI-GUIDE.md` (MODIFY — add `75-safety-hook.md` to rule index AND update "26/26" → "27/27" counts on lines 34 + 56)
- `AI-GUIDE.md.tmpl` (English + zh — MODIFY — add 75-safety-hook to rule index)
- `.harness/rules/40-locations.md` (MODIFY — bump "26 items at v0.14" → "27 items at v0.15"; add C.5 to enumeration)

### Group G — version drift + changelog (must move together per insight 2026-05-16 "Releases shipped feature code …")
- `.claude-plugin/plugin.json` (MODIFY — `0.14.0` → `0.15.0`)
- `.claude-plugin/marketplace.json` (MODIFY — `0.14.0` → `0.15.0`)
- `README.md` (MODIFY — badge `version-0.14.0` → `0.15.0`; badge `verify_all-26/26` → `27/27`; roadmap row for 0.15.0)
- `README.zh-CN.md` (MODIFY — same)
- `CHANGELOG.md` (MODIFY — new `## [0.15.0] - 2026-05-16` section)
- `docs/getting-started.md` (MODIFY — version mention if any; skill / check counts if cited — search and patch only the spots that are stale)
- `docs/concepts.md` (MODIFY — only if it cites the guard / version; otherwise no-op)

### Group H — task board
- `docs/tasks.md` (MODIFY at the end of pipeline — Developer/PM advances `T-001` row to `done`)

### Group I — insight ledger (optional, only with evidence)
- `.harness/insight-index.md` (MODIFY only if a non-obvious truth surfaces during implementation — Developer or QA records it; not pre-committed here)

---

## 3. Concrete file plan

| # | File (absolute) | Action | Reason |
|---|---|---|---|
| 1 | `C:\Programs\HarnessEngineering\AI-GUIDE.md` | MODIFY | Add "AI tool flow modes" + Claude Code sub-agent callout + 75-safety-hook index line; update 26→27 counts |
| 2 | `C:\Programs\HarnessEngineering\skills\harness-init\templates\common\AI-GUIDE.md.tmpl` | MODIFY | Same edits, template surface |
| 3 | `C:\Programs\HarnessEngineering\skills\harness-init\templates\i18n\zh\common\AI-GUIDE.md.tmpl` | MODIFY | zh translation of those edits |
| 4 | `C:\Programs\HarnessEngineering\.harness\rules\60-tool-handoff.md` | MODIFY | Append "Copilot continuous mode (opt-in)" subsection |
| 5 | `C:\Programs\HarnessEngineering\skills\harness-init\templates\common\.harness\rules\60-tool-handoff.md` | MODIFY | Same |
| 6 | `C:\Programs\HarnessEngineering\skills\harness-init\templates\i18n\zh\common\.harness\rules\60-tool-handoff.md` | MODIFY | zh — uses `走全流程` |
| 7 | `C:\Programs\HarnessEngineering\.github\copilot-instructions.md` | MODIFY | Third red line: append "unless the user has explicitly enabled continuous mode (see `60-tool-handoff.md`)" |
| 8 | `C:\Programs\HarnessEngineering\skills\harness-init\templates\common\.github\copilot-instructions.md.tmpl` | MODIFY | Same |
| 9 | `C:\Programs\HarnessEngineering\skills\harness-init\templates\i18n\zh\common\.github\copilot-instructions.md.tmpl` | MODIFY | zh |
| 10 | `C:\Programs\HarnessEngineering\skills\harness-status\SKILL.md` | MODIFY | New row in §1 + new report block in §2 or §3 |
| 11 | `C:\Programs\HarnessEngineering\scripts\guard-rm.ps1` | NEW | Windows guard script; will be replaced by `sync-self` mirror after template SOT lands |
| 12 | `C:\Programs\HarnessEngineering\scripts\guard-rm.sh` | NEW | Unix guard script |
| 13 | `C:\Programs\HarnessEngineering\skills\harness-init\templates\common\scripts\guard-rm.ps1` | NEW | Template SOT |
| 14 | `C:\Programs\HarnessEngineering\skills\harness-init\templates\common\scripts\guard-rm.sh` | NEW | Template SOT |
| 15 | `C:\Programs\HarnessEngineering\.claude\settings.json` | MODIFY | Add `hooks.PreToolUse` array |
| 16 | `C:\Programs\HarnessEngineering\skills\harness-init\templates\common\.claude\settings.json.tmpl` | MODIFY | Same, command is `{{GUARD_COMMAND}}` |
| 17 | `C:\Programs\HarnessEngineering\.harness\rules\75-safety-hook.md` | NEW | Rule fragment documenting guard contract + disable path |
| 18 | `C:\Programs\HarnessEngineering\skills\harness-init\templates\common\.harness\rules\75-safety-hook.md.tmpl` | NEW | Template (no placeholders at v0.15) |
| 19 | `C:\Programs\HarnessEngineering\skills\harness-init\templates\i18n\zh\common\.harness\rules\75-safety-hook.md.tmpl` | NEW | zh translation |
| 20 | `C:\Programs\HarnessEngineering\scripts\sync-self.ps1` | MODIFY | Add 2 mappings to `$mappings` array |
| 21 | `C:\Programs\HarnessEngineering\scripts\sync-self.sh` | MODIFY | Add 2 `sync_file` calls (use `()` not `declare -a` — already does) |
| 22 | `C:\Programs\HarnessEngineering\skills\harness-init\SKILL.md` | MODIFY | Step 4 scripts list; step 5 placeholder table (`{{GUARD_COMMAND}}`); step 8 mention; step 11 output |
| 23 | `C:\Programs\HarnessEngineering\skills\harness-adopt\SKILL.md` | MODIFY | Step 5 plan listing; step 6 PreToolUse merge clause |
| 24 | `C:\Programs\HarnessEngineering\scripts\verify_all.ps1` | MODIFY | New `C.5` (renaming: see §6 below); extend D.2 `$allowed` with `{{GUARD_COMMAND}}` |
| 25 | `C:\Programs\HarnessEngineering\scripts\verify_all.sh` | MODIFY | Same |
| 26 | `C:\Programs\HarnessEngineering\.harness\rules\40-locations.md` | MODIFY | "26 items at v0.14" → "27 items at v0.15"; add C.5 line + safety-hook reference |
| 27 | `C:\Programs\HarnessEngineering\.claude-plugin\plugin.json` | MODIFY | version 0.15.0 |
| 28 | `C:\Programs\HarnessEngineering\.claude-plugin\marketplace.json` | MODIFY | version 0.15.0 |
| 29 | `C:\Programs\HarnessEngineering\README.md` | MODIFY | Badges + roadmap row |
| 30 | `C:\Programs\HarnessEngineering\README.zh-CN.md` | MODIFY | Badges + roadmap row |
| 31 | `C:\Programs\HarnessEngineering\CHANGELOG.md` | MODIFY | New 0.15.0 section |
| 32 | `C:\Programs\HarnessEngineering\docs\getting-started.md` | MODIFY (conditional) | If/where version or check-count is cited — `Grep` first; touch only stale lines |
| 33 | `C:\Programs\HarnessEngineering\docs\tasks.md` | MODIFY | Move T-001 to done at delivery |
| 34 | `C:\Programs\HarnessEngineering\evals\guard-rm-cases.md` | NEW | Driver+fixture table for acceptance B2 (Developer creates) |

No DELETEs. No new third-party dependencies.

---

## 4. Script designs

### 4.1 Tokenization choice

Two valid choices were considered.

| Option | Pros | Cons |
|---|---|---|
| (a) PowerShell `[Management.Automation.Language.Parser]::ParseInput` for `.ps1`; native bash `read -ra` for `.sh` | Robust for nested quoting; same parser the shell uses | Adds runtime cost; harder to mirror cross-shell |
| **(b) Regex split with whitespace tokenization, then quote-aware re-merge** | Tiny, identical algorithm in both shells, ≤ 100 LOC each, performance well under the 50 ms budget | Misses exotic quoting (e.g. ANSI-C `$'...'`); acceptable because we **default to BLOCK** on parse failure |

**Decision: (b)** — same regex algorithm in both files. Pseudocode below. The "if parse fails, default to BLOCK" semantics (in-scope #12) makes ambiguous quoting safe by construction.

### 4.2 Path resolution algorithm (both shells, identical)

```
Input: $original_command (string from $env:CLAUDE_TOOL_INPUT or stdin JSON)
       $cwd                (current directory)
       $env:HARNESS_ALLOW_OUTSIDE_RM (optional override)

1. If $env:HARNESS_ALLOW_OUTSIDE_RM == "1":
       emit "harness-kit guard-rm: override active …" to stderr
       exit 0

2. Find $repoRoot: walk up from $cwd looking for a directory containing ".git/"
   If not found:
       emit "harness-kit guard-rm: WARN no .git/ ancestor — guard inactive." to stderr
       exit 0   (per boundary B7; in-scope #8 third sub-clause)

3. Truncate $original_command to 8192 chars (boundary B11)

4. Split $original_command on top-level pipes "|" (NOT inside quotes).
   For each pipe segment:
        4a. Tokenize segment by whitespace, respecting single + double quotes.
            If tokenizer raises an exception → default BLOCK with message "could not parse …".
        4b. Strip a leading "sudo" if present (and the optional "-E/-H/-u <user>" flags after it).
        4c. Take the first token = $verb.
        4d. If $verb not in {rm, rmdir, unlink, Remove-Item, del, erase,
                              Clear-RecycleBin, shred, srm}:
               # Special case: 'find' counts as destructive iff "-delete" appears as a later token
               if $verb == "find" AND segment contains a "-delete" token: treat as destructive
               else: continue to next pipe segment
        4e. For pwsh -c / pwsh -Command / powershell -Command / powershell -c:
               Re-extract the quoted command string (the next single quoted argument),
               recursively call step 4 on it. If re-extraction fails → default BLOCK.
        4f. Walk remaining tokens after $verb.
               Skip tokens that:
                  - start with "-" or "/" -> "-" prefix only for short flags;
                    treat "/" prefix as a path on Windows pwsh contexts (use heuristic: 
                    if token contains ":" before "\" -> path; else short flag style).
                    NOTE: bash side treats "/" as a path; pwsh side preserves cmd-style "/X" flags
                    only when verb is del/erase. Documented in inline comment.
                  - immediately follow a find-predicate flag (-name, -type, -regex,
                    -iname, -perm, -mtime, -size) — in-scope #11
               Keep tokens that look like paths (everything else; explicit "--" 
               terminates flag parsing, the rest are paths).
        4g. For each path token $p:
               - If $p is relative: $abs = Join-Path $cwd $p
               - Else: $abs = $p
               - Normalize: collapse "..", "." (do NOT call realpath/symlink resolve;
                 leaf-only per boundary B6)
               - If $abs is NOT a descendant of $repoRoot: 
                     append to $offending (with annotation "outside <repoRoot>")

5. If $offending is non-empty:
       Emit the BLOCK message (§4.4 below) to stderr
       exit 2

6. exit 0   (allowed)
```

The algorithm is deterministic, stateless, and free of external commands beyond the shell's built-in path arithmetic and the `git rev-parse --show-toplevel` we DO NOT use (we walk `.git/` ourselves to avoid spawning git for every Bash call — perf budget per NFR is 50 ms).

### 4.3 Nested pwsh parsing

When the outer verb is `pwsh`/`powershell` and the next token is `-c`/`-Command` (case-insensitive), the immediately-following quoted argument is re-tokenized as a fresh segment. **Maximum recursion depth = 2** (defense-in-depth; deeper nesting defaults to BLOCK with the "could not parse" message). Acceptance B2 row `pwsh -c "Remove-Item -Recurse C:\Windows"` exercises this exact path.

### 4.4 BLOCK message format (verbatim per in-scope #9)

```
harness-kit guard-rm: BLOCKED — destructive command targets path outside project root.
  Command: <truncated to 300 chars>
  Offending path(s):
    - <abs-path> (outside <repoRoot>)
  Override (only if you really mean this): re-issue the command with the env var
    HARNESS_ALLOW_OUTSIDE_RM=1 set for that single call.
  See .harness/rules/75-safety-hook.md to fully disable.
```

The reference to `delete .git/hooks/...` in the requirement's literal block is **removed** — that referred to git hooks, not the PreToolUse mechanism we're implementing; keeping it would mislead. The corrected sentence is `See .harness/rules/75-safety-hook.md to fully disable.` (the rule fragment then explains the one-line edit to `.claude/settings.json`).

### 4.5 Symlink policy

**Leaf-only** (per boundary B6). No `realpath` / `Resolve-Path -Resolve` / `readlink` call. The path-as-written is normalized for `..` and `.` only. Rationale: matches user mental model and avoids surprising blocks when grooming legitimate in-repo symlinks.

### 4.6 Override env var

`HARNESS_ALLOW_OUTSIDE_RM=1` checked **at the very top** of the script. When set, the script emits a single stderr INFO line (per in-scope #10) and exits 0 without parsing — by design, the override is intentionally cheap so a knowledgeable user can `HARNESS_ALLOW_OUTSIDE_RM=1 rm -rf /tmp/something` in a single bash invocation without overhead.

### 4.7 Pseudo-code skeletons

`scripts/guard-rm.ps1` (PowerShell):

```powershell
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# Claude Code passes tool input via stdin as JSON; we read it.
$raw = [Console]::In.ReadToEnd()
try   { $payload = $raw | ConvertFrom-Json } catch { exit 0 }  # no payload, nothing to guard
$cmd  = $payload.tool_input.command
if (-not $cmd) { exit 0 }

if ($env:HARNESS_ALLOW_OUTSIDE_RM -eq '1') {
    [Console]::Error.WriteLine('harness-kit guard-rm: override active (HARNESS_ALLOW_OUTSIDE_RM=1) — allowing destructive command.')
    exit 0
}

# walk-up to nearest .git/
$dir = (Get-Location).Path
$repoRoot = $null
while ($dir) {
    if (Test-Path (Join-Path $dir '.git')) { $repoRoot = $dir; break }
    $parent = Split-Path $dir -Parent
    if ($parent -eq $dir) { break }
    $dir = $parent
}
if (-not $repoRoot) {
    [Console]::Error.WriteLine('harness-kit guard-rm: WARN no .git/ ancestor — guard inactive.')
    exit 0
}

$cmd = $cmd.Substring(0, [Math]::Min($cmd.Length, 8192))

# ... tokenize + classify + collect offending paths (see §4.2) ...

if ($offending.Count -gt 0) {
    [Console]::Error.WriteLine("harness-kit guard-rm: BLOCKED — destructive command targets path outside project root.")
    [Console]::Error.WriteLine("  Command: $($cmd.Substring(0, [Math]::Min($cmd.Length, 300)))")
    [Console]::Error.WriteLine("  Offending path(s):")
    foreach ($p in $offending) { [Console]::Error.WriteLine("    - $p (outside $repoRoot)") }
    [Console]::Error.WriteLine("  Override (only if you really mean this): re-issue the command with the env var")
    [Console]::Error.WriteLine("    HARNESS_ALLOW_OUTSIDE_RM=1 set for that single call.")
    [Console]::Error.WriteLine("  See .harness/rules/75-safety-hook.md to fully disable.")
    exit 2
}

exit 0
```

`scripts/guard-rm.sh` (bash 5.x):

```bash
#!/usr/bin/env bash
# Use arr=() not declare -a (insight 2026-05-16 declare-a-under-set-u).
set -uo pipefail

payload=$(cat || true)
cmd=$(printf '%s' "$payload" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\(.*\)".*/\1/p' | head -1)
# A robust extractor uses python -c if available; fallback above works for the
# minimal JSON shape Claude Code emits (one-level object).
[[ -z "$cmd" ]] && exit 0

if [[ "${HARNESS_ALLOW_OUTSIDE_RM:-}" == "1" ]]; then
    echo "harness-kit guard-rm: override active (HARNESS_ALLOW_OUTSIDE_RM=1) — allowing destructive command." >&2
    exit 0
fi

dir="$PWD"; repo_root=""
while [[ -n "$dir" && "$dir" != "/" ]]; do
    [[ -d "$dir/.git" ]] && { repo_root="$dir"; break; }
    parent="$(dirname "$dir")"
    [[ "$parent" == "$dir" ]] && break
    dir="$parent"
done
if [[ -z "$repo_root" ]]; then
    echo "harness-kit guard-rm: WARN no .git/ ancestor — guard inactive." >&2
    exit 0
fi

cmd="${cmd:0:8192}"
offending=()
# ... tokenize $cmd (read -ra on whitespace, then re-merge quotes); classify; collect ...

if (( ${#offending[@]} > 0 )); then
    printf 'harness-kit guard-rm: BLOCKED — destructive command targets path outside project root.\n' >&2
    printf '  Command: %s\n' "${cmd:0:300}" >&2
    printf '  Offending path(s):\n' >&2
    for p in "${offending[@]}"; do printf '    - %s (outside %s)\n' "$p" "$repo_root" >&2; done
    printf '  Override (only if you really mean this): re-issue the command with the env var\n' >&2
    printf '    HARNESS_ALLOW_OUTSIDE_RM=1 set for that single call.\n' >&2
    printf '  See .harness/rules/75-safety-hook.md to fully disable.\n' >&2
    exit 2
fi
exit 0
```

The Developer implements the body of the `# ... tokenize ... # ... classify ...` blocks following §4.2 step-by-step. Pseudo-code in this design is the contract.

---

## 5. Settings.json shape

### 5.1 New PreToolUse block (dogfood — `.claude/settings.json`)

```jsonc
{
  "permissions": { /* unchanged */ },
  "hooks": {
    "_doc_sync_hook": "…",
    "Stop": [ /* unchanged */ ],
    "_guard_hook": "Auto-runs guard-rm before every Bash tool call. Blocks destructive commands targeting paths outside this repo. Override per-call with HARNESS_ALLOW_OUTSIDE_RM=1. See .harness/rules/75-safety-hook.md to disable.",
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "pwsh -File scripts/guard-rm.ps1"
          }
        ]
      }
    ]
  }
}
```

### 5.2 Template — `.claude/settings.json.tmpl`

Replace the hard-coded command with the new placeholder `{{GUARD_COMMAND}}`:

```jsonc
"PreToolUse": [
  {
    "matcher": "Bash",
    "hooks": [
      {
        "type": "command",
        "command": "{{GUARD_COMMAND}}"
      }
    ]
  }
]
```

### 5.3 New placeholder

| Placeholder | Replacement at init time | Detection |
|---|---|---|
| `{{GUARD_COMMAND}}` | Windows → `pwsh -File scripts/guard-rm.ps1`. macOS/Linux → `bash scripts/guard-rm.sh` | Mirror `{{SYNC_COMMAND}}` OS detection logic in `harness-init/SKILL.md` step 5 |

**Whitelist update (both files, per insight 2026-05-16 placeholders):**

- `scripts/verify_all.ps1` line 94: add `"{{GUARD_COMMAND}}"` to the `$allowed` array
- `scripts/verify_all.sh` line 79: add `"{{GUARD_COMMAND}}")` to the `case` pattern

Both must change together.

### 5.4 Matcher value

Claude Code's PreToolUse matcher accepts a tool name. For Bash tool calls the canonical matcher is `"Bash"` (capitalized, exact). The hook command receives the tool input as JSON on stdin; the script reads it (per §4.7).

### 5.5 Failure semantics

If `guard-rm.{ps1,sh}` is missing or has a syntax error, the hook command itself fails. Claude Code's PreToolUse failure semantics treat hook exit ≠ 0 as a block. We document this in `75-safety-hook.md` and rely on `verify_all C.5` to keep the scripts present.

---

## 6. verify_all check

### 6.1 ID assignment

Reading existing IDs in `scripts/verify_all.ps1`: A.1, A.2, B.1, B.2, C.1, C.2, D.1, D.2, E.1, E.2, E.3, E.4, E.4b, E.5, E.6, E.7, F.1, G.1, G.2, G.3, H.1, I.1, I.2, I.3, I.4, I.5. That's **26 checks** total (matches the current README claim).

The requirement proposed `C.5`, but C is reserved for "Skills structure" (C.1 = 9 skills present, C.2 = frontmatter). Inserting a guard-script check into C would change C's meaning. The natural slot is **after F.1** (script symmetry) and before G.1 (documentation hygiene): **`F.2`** (the previous F.2 was already removed in v0.14.x per comment line 193). Reviving F.2 with a fresh semantic is acceptable since its previous content is gone and no other check references the old ID.

**Decision: new check ID is `F.2`** — "Guard-rm scripts and PreToolUse wiring present".

This brings the total to **27 checks at v0.15** (badge becomes `27/27`).

### 6.2 Assertions (PASS-level, mandatory)

```
F.2 — Guard-rm scripts and PreToolUse wiring present
   1. scripts/guard-rm.ps1 exists
   2. scripts/guard-rm.sh exists
   3. skills/harness-init/templates/common/scripts/guard-rm.ps1 exists
   4. skills/harness-init/templates/common/scripts/guard-rm.sh exists
   5. .claude/settings.json — JSON parse; hooks.PreToolUse[0].hooks[0].command matches "guard-rm\.(ps1|sh)"
   6. skills/harness-init/templates/common/.claude/settings.json.tmpl — string-contains "{{GUARD_COMMAND}}" 
      AND contains the literal "PreToolUse"
```

Any single sub-assertion failing throws. PASS level (not WARN) because the requirement is mandatory presence on every repo.

### 6.3 Bidirectional rule indexing (no new check needed)

`E.4b` (existing) already enforces "every `.harness/rules/*.md` is indexed in `AI-GUIDE.md` AND every reference in `AI-GUIDE.md` points to an existing file". Adding `75-safety-hook.md` is automatically covered — no change to E.4b needed. The Developer's job is to add the index line to AI-GUIDE.md AND its template AND the zh overlay; if any is missed, E.4b fails for that surface.

### 6.4 Updates to existing checks

- `D.2` placeholder whitelist: add `{{GUARD_COMMAND}}` to BOTH `.ps1` (`$allowed` array) and `.sh` (`case` pattern). This is the precise scenario flagged by the insight `2026-05-16 · Any new {{...}} placeholder…`.
- No other existing check is touched.

### 6.5 Implementation pattern (mirror G.3 for cross-shell symmetry)

The `.ps1` version uses `ConvertFrom-Json` on `.claude/settings.json`. The `.sh` version can use a simple `grep` since the file is small (mirror G.3's `grep -oE` approach to avoid a `jq` dependency).

---

## 7. Rule fragment design

### 7.1 `.harness/rules/75-safety-hook.md` (dogfood — NEW)

Structure (mirrors `70-doc-size.md` style):

```markdown
# 75 — Destructive-command safety hook (harness-kit dogfood)

## What this is
A `PreToolUse` hook in `.claude/settings.json` that runs `scripts/guard-rm.{ps1,sh}` 
before every Claude Code Bash tool call. The guard blocks the call when any 
destructive verb (rm / rmdir / unlink / Remove-Item / del / erase / 
Clear-RecycleBin / shred / srm / find -delete) targets a path that resolves 
outside the nearest `.git/` ancestor of cwd.

## When to read this
- When running, observing, or disabling the destructive-command guardrail.
- When a tool call was unexpectedly BLOCKED.
- Before editing the `PreToolUse` block in `.claude/settings.json`.

## Trigger verbs
[ table ]

## Path resolution rules
- Absolute paths: used as-is.
- Relative paths: joined to cwd, then `..` / `.` normalized.
- Symlinks: leaf-only — the link itself is checked; the link target is NOT followed.
- Globs: literal — `/tmp/*.log` resolves under `/tmp/` → outside root.
- $repoRoot = nearest `.git/` ancestor of cwd. If none exists, guard exits 0 with a WARN.

## Override
`HARNESS_ALLOW_OUTSIDE_RM=1` set for one bash invocation, e.g.
   HARNESS_ALLOW_OUTSIDE_RM=1 rm -rf /tmp/some-thing
or PowerShell:
   $env:HARNESS_ALLOW_OUTSIDE_RM=1; Remove-Item -Recurse C:\some\external

Override is intentionally per-call and visible; it cannot be persisted in any 
committed file.

## Fully disable
Edit `.claude/settings.json` and delete the `PreToolUse` block. Re-add by 
re-running `/harness-adopt` or copying from the template.

## Failure modes
- Guard script missing → hook fails → tool call blocked. Reinstall via `/harness-adopt` or `scripts/sync-self`.
- Parse failure on nested pwsh → BLOCK with explicit message; override if intended.

## Boundaries
- Inside-project deletions are allowed (build artifacts, node_modules, .next/, etc.).
- `mv` / `cp` / redirect `> file` are NOT guarded (out of scope v1).
- The guard only fires for Claude Code Bash tool calls. Other tools (Write/Edit, Copilot, Cursor) are NOT intercepted.
- For "outside" determination, the leaf path is what we look at — no realpath chase.
```

Cap: keep under 200 lines per `70-doc-size.md`'s rule for rule fragments. Target ~80–100 lines.

### 7.2 Template version

`skills/harness-init/templates/common/.harness/rules/75-safety-hook.md.tmpl` — content identical at v0.15 (no placeholders today). `.tmpl` suffix preserved for consistency with sibling `65-intervention.md.tmpl` / `70-doc-size.md.tmpl` and so future placeholders fit without renaming.

### 7.3 zh overlay

`skills/harness-init/templates/i18n/zh/common/.harness/rules/75-safety-hook.md.tmpl` — Chinese translation. Mirrors the existing zh overlay pattern (`60-tool-handoff.md` and `00-core.md.tmpl` are already translated). Override env var name stays English (`HARNESS_ALLOW_OUTSIDE_RM`); commands stay English; surrounding prose is Chinese.

### 7.4 AI-GUIDE.md index lines

In `AI-GUIDE.md` (dogfood) Rule-fragments section, append between `70-doc-size.md` and the memory layer:

```
- **`.harness/rules/75-safety-hook.md`** (**when running, observing, or disabling the destructive-command guardrail**): `PreToolUse` hook on Bash tool calls; blocks destructive commands targeting paths outside `.git/` ancestor of cwd; override `HARNESS_ALLOW_OUTSIDE_RM=1`.
```

Same line added (English) to `AI-GUIDE.md.tmpl`. zh-translated line added to the zh `AI-GUIDE.md.tmpl`. Without all three, `E.4b` (or the per-project F.* check after init) fails.

---

## 8. harness-adopt impact

### 8.1 Step 5 (plan)

In the "Files I will add (NEW)" block, append:

```
- scripts/guard-rm.{ps1,sh} (cross-platform destructive-command guard; see .harness/rules/75-safety-hook.md)
```

In a new "PreToolUse hook merge" subsection under "Conflicts noted":

```
If .claude/settings.json already exists:
  - If it has NO `hooks.PreToolUse` array → ADD the guard-rm PreToolUse entry. No conflict.
  - If it HAS a `hooks.PreToolUse` array → APPEND a new matcher block for "Bash" 
    pointing at scripts/guard-rm.* . If a matcher==="Bash" entry already exists, 
    surface as a conflict and ask user: merge into the existing array (default) / 
    overwrite / skip.
```

### 8.2 Step 6 (apply) — JSON merge logic

The adopt skill currently overwrites `.claude/settings.json` from the template when missing, but skips when present (merge mode) or prompts (overwrite mode) — see step 6 first three bullets. **The skill does NOT have a JSON-merge primitive today.** This task adds one in prose-form (Developer implements during step 6 of the rendered output, not as a separate utility):

```
For .claude/settings.json:
  - If absent: copy template (with placeholder substitution); done.
  - If present and byte-identical to template: skip; done.
  - If present and differs:
      - Read existing as JSON.
      - If no hooks.PreToolUse: insert a fresh PreToolUse array with the Bash matcher block.
      - Else: scan existing PreToolUse entries; if no entry has matcher=="Bash" 
        pointing at guard-rm.*, prepend the new block. If one already exists, 
        log to .harness-adopt/CONFLICTS.md and DO NOT modify.
      - Write back with stable JSON formatting (2-space indent; preserve key order).
```

The "stable JSON formatting" is best-effort; PowerShell `ConvertTo-Json -Depth 10` and bash `jq` (if available) both produce reasonable output. Where `jq` is absent, fall back to template-replace heuristic (since the file we wrote at init has known shape, this works in the common case).

### 8.3 Step 4 / draft-rules collection

No change. The guard isn't a "rule extracted from the user's existing project".

---

## 9. harness-status impact

### 9.1 Required-assets table (§1)

Add three rows:

| Asset | Path | Present? |
|---|---|---|
| Guard-rm script (ps1) | `scripts/guard-rm.ps1` | ? |
| Guard-rm script (sh) | `scripts/guard-rm.sh` | ? |
| PreToolUse hook | `.claude/settings.json` (has `hooks.PreToolUse` array referencing guard-rm) | ? |

### 9.2 New report block (after §3, before §4)

```
### 3b. Sub-agent dispatch / safety hook
Sub-agent dispatch:  enabled (Claude Code via Task tool) | n/a (other tools)
Safety hook:         enabled (guard-rm wired in PreToolUse) | DISABLED — .claude/settings.json has no PreToolUse for Bash | scripts missing
```

The "Sub-agent dispatch" line is constant — Claude Code is the only tool with programmatic dispatch, so the value is always `enabled (Claude Code via Task tool) | n/a (other tools)`. The safety-hook line is computed by parsing `.claude/settings.json` and checking the PreToolUse path.

### 9.3 Health score (§6)

Bump the denominator from 11 to **12**: add `+1` for "PreToolUse guard hook installed and points at existing guard-rm scripts".

---

## 10. sync-self impact

### 10.1 PowerShell (`scripts/sync-self.ps1`)

Add two entries to the `$mappings` array (currently ends at `archive-task.sh`):

```powershell
$mappings = @(
    @{ from = ".harness/agents"; to = ".harness/agents"; type = "dir-of-md" }
    @{ from = "scripts/harness-sync.ps1"; to = "scripts/harness-sync.ps1"; type = "file" }
    @{ from = "scripts/harness-sync.sh"; to = "scripts/harness-sync.sh"; type = "file" }
    @{ from = "scripts/install-hooks.ps1"; to = "scripts/install-hooks.ps1"; type = "file" }
    @{ from = "scripts/install-hooks.sh"; to = "scripts/install-hooks.sh"; type = "file" }
    @{ from = "scripts/archive-task.ps1"; to = "scripts/archive-task.ps1"; type = "file" }
    @{ from = "scripts/archive-task.sh"; to = "scripts/archive-task.sh"; type = "file" }
    @{ from = "scripts/guard-rm.ps1"; to = "scripts/guard-rm.ps1"; type = "file" }   # NEW
    @{ from = "scripts/guard-rm.sh"; to = "scripts/guard-rm.sh"; type = "file" }     # NEW
)
```

Update the doc-comment block at top:

```
# Synchronizes (templates/common/ → repo root):
#   .harness/agents/*.md             → .harness/agents/*.md
#   scripts/harness-sync.{ps1,sh}    → scripts/harness-sync.{ps1,sh}
#   scripts/install-hooks.{ps1,sh}   → scripts/install-hooks.{ps1,sh}
#   scripts/archive-task.{ps1,sh}    → scripts/archive-task.{ps1,sh}
#   scripts/guard-rm.{ps1,sh}        → scripts/guard-rm.{ps1,sh}    # NEW
```

### 10.2 Bash (`scripts/sync-self.sh`)

Add two `sync_file` calls in mapping section (mappings already use `()` array — no `declare -a` fix needed). Insert after "Mapping 4: archive-task scripts":

```bash
# Mapping 5: guard-rm scripts
sync_file "$template_common/scripts/guard-rm.ps1" "$repo_root/scripts/guard-rm.ps1" "scripts/guard-rm.ps1"
sync_file "$template_common/scripts/guard-rm.sh"  "$repo_root/scripts/guard-rm.sh"  "scripts/guard-rm.sh"
```

The existing `drift=()` array is already idiomatic; no change.

### 10.3 AI-GUIDE.md / insight-index callout

Existing insight 2026-05-16 says `sync-self only syncs .harness/agents/ + 4 specific scripts (harness-sync, install-hooks, archive-task)`. After this task lands, the count is **+1 = guard-rm**. The insight is still accurate "scripts/rules don't sync; only the explicit list does" — no insight rewrite needed. But the AI-GUIDE line that names them should reflect the new total:

`AI-GUIDE.md` line 58: change `+ 4 script pairs (harness-sync, install-hooks, archive-task)` → `+ 5 script pairs (harness-sync, install-hooks, archive-task, guard-rm)`.

---

## 11. Sequence / flow (request → guard → tool call)

```
1. User in Claude Code asks the assistant to run a Bash command.
2. Assistant emits a Bash tool call: { tool_name: "Bash", tool_input: { command: "rm -rf /tmp/foo" } }
3. Claude Code's PreToolUse hook fires:
       a. Matcher "Bash" matches.
       b. Spawns: pwsh -File scripts/guard-rm.ps1  (or bash scripts/guard-rm.sh)
       c. Passes the tool_input as JSON on stdin.
       d. Inherits cwd + env.
4. guard-rm:
       a. Read JSON; extract .tool_input.command → "rm -rf /tmp/foo"
       b. Check $env:HARNESS_ALLOW_OUTSIDE_RM. Not set.
       c. Walk up to nearest .git/ → $repoRoot = C:\Programs\HarnessEngineering
       d. Tokenize: ["rm", "-rf", "/tmp/foo"]; verb=rm matches.
       e. Path arg = "/tmp/foo" → absolute → NOT a descendant of repoRoot → offending.
       f. Emit BLOCK message to stderr; exit 2.
5. Claude Code observes hook exit 2; aborts the Bash tool call.
6. Tool transcript shows the stderr message (so the assistant + the user see why).
7. Assistant can either ask the user, or re-issue with override:
       Bash { command: "HARNESS_ALLOW_OUTSIDE_RM=1 rm -rf /tmp/foo" }
       PreToolUse fires again; guard sees env var; exits 0 with INFO line; command runs.
```

ASCII diagram:

```
                   ┌─────────────────────────────┐
   user prompt ──▶ │  Claude Code (assistant)    │
                   └──────────┬──────────────────┘
                              │ Bash tool call
                              ▼
                   ┌─────────────────────────────┐
                   │  Claude Code runtime        │
                   │  - matches PreToolUse hook  │
                   │  - spawns guard-rm.{ps1,sh} │
                   │  - stdin = tool_input JSON  │
                   └──────────┬──────────────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
         exit 0          exit 0+stderr   exit 2 + stderr
        (allowed)         (override)       (blocked)
              │               │               │
              ▼               ▼               ▼
       Bash runs       Bash runs       Tool call aborts;
                                       stderr surfaces in
                                       transcript
```

---

## 12. Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| Cross-shell script pair pattern (`.ps1` + `.sh`) | `install-hooks.ps1` / `.sh`, `archive-task.ps1` / `.sh`, `harness-sync.ps1` / `.sh` | `C:\Programs\HarnessEngineering\scripts\` | **Reuse pattern** — exact same skeleton: param block, `$repoRoot = Split-Path $PSScriptRoot -Parent`, `set -uo pipefail`. |
| `.git/` ancestor walk | (none reused directly; `harness-sync` assumes cwd) | — | **New code justified** — small (≤ 15 lines per shell). Could shell out to `git rev-parse --show-toplevel` but that would spawn a process per Bash tool call → blows the 50 ms NFR. Hand-rolled walk is faster and dep-free. |
| OS-detection for `{{SYNC_COMMAND}}` | `harness-init/SKILL.md` step 5 | `skills\harness-init\SKILL.md:139` | **Reuse exactly** — `{{GUARD_COMMAND}}` follows the same `$IsWindows` / `$OSTYPE` branching at init time. No new detection logic. |
| Placeholder whitelist machinery | `verify_all.{ps1,sh}` D.2 | `scripts\verify_all.ps1:93`, `scripts\verify_all.sh:79` | **Extend** — add one entry to each list. |
| Bidirectional rule index check | `verify_all.{ps1,sh}` E.4b | `scripts\verify_all.ps1:141`, `scripts\verify_all.sh:126` | **Reuse as-is** — automatically covers the new `75-safety-hook.md`. No change needed. |
| Settings.json JSON shape | `.claude/settings.json` (dogfood) and `.tmpl` | `C:\Programs\HarnessEngineering\.claude\settings.json` | **Extend** — add a `PreToolUse` array next to the existing `Stop` array. Don't rewrite `Stop` or `permissions`. |
| `sync-self` mapping table | `scripts/sync-self.{ps1,sh}` `$mappings` / inline calls | `scripts\sync-self.ps1:34-42`, `scripts\sync-self.sh:57-70` | **Extend** — add two rows / two `sync_file` calls. The orphan-removal logic already handles dir-of-md mappings; the new mappings are `type=file`, no orphan concern. |
| Rule fragment file pattern | `70-doc-size.md` / `65-intervention.md.tmpl` | `.harness\rules\70-doc-size.md`, `skills\harness-init\templates\common\.harness\rules\65-intervention.md.tmpl` | **Reuse structure** — section headings ("What this is" / "When to read" / "Boundaries"). |
| Path-outside-root check | **(none found)** — `Grep` for `..` normalization, `realpath`, `outside`, `is descendant` returned no existing utility. | — | **New module justified** — green-field, no duplicate. |

The path-outside-root check is the one genuinely new bit of logic. Everything else extends existing patterns.

---

## 13. Risk analysis

| # | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| R1 | Tokenizer regex misclassifies a legitimate `rm` (false BLOCK) | M | H (user friction) | Default to BLOCK only on **parse failure**; for parse success the algorithm is conservative-but-determinable. Acceptance B2 enumerates 11 input/output pairs and Developer adds a driver that runs them. QA validates on real workloads. |
| R2 | Tokenizer misses a destructive command (false ALLOW) | L | C (data loss outside repo) | Verb list covers rm + Remove-Item + del + erase + rmdir + unlink + shred + srm + Clear-RecycleBin + `find -delete`. Decision §1 says future verbs are added when an incident occurs — accepted trade-off in the requirement's §3 out-of-scope. |
| R3 | Guard script slow → degrades Claude Code UX | L | M | Hand-rolled `.git` walk avoids spawning git (the dominant cost). Pseudo-code is straight-line; PowerShell startup is the main cost (~50–80 ms on cold start). NFR says ≤ 50 ms median; QA measures p50 + p95. Mitigation if exceeded: precompile/AOT not available for `.ps1` — fallback is to drop overall behavior down to "fast-path: if first token not in verb list, exit 0 with zero allocation" (already part of algorithm step 4d/B2). |
| R4 | Bash script breaks under `set -u` empty-array (the insight) | L | H (CI fails silently) | `arr=()` syntax used explicitly. Bash code reviewed by Code Reviewer with this insight cited. `scripts/test-init.sh` runs on Linux fixture so it'd actually fail rather than hide. |
| R5 | JSON-parse on `.claude/settings.json` fails in adopt-merge | L | M | Two-tier fallback: `jq` if present; otherwise template-replace heuristic (since the file was written by us with known shape in the common case). Conflict → log to `CONFLICTS.md` and ask user. |
| R6 | Override env var leaks into committed file | L | C | Documented in NFR-Security; `Grep` check in CHANGELOG QA review confirms no committed file sets `HARNESS_ALLOW_OUTSIDE_RM=1`. No automated check (would be over-engineering for a one-off review item). |
| R7 | New `{{GUARD_COMMAND}}` placeholder not added to verify_all D.2 whitelist | M | M | The insight 2026-05-16 calls this out explicitly. Solution Architecture lists D.2 update in §5.3 and §6.4. Developer must touch BOTH `.ps1` and `.sh`. Code Reviewer's checklist includes "verify D.2 whitelist updated for every new placeholder". |
| R8 | E.4b only checks dogfood AI-GUIDE.md; template + zh AI-GUIDE.md.tmpl can silently drift | M | M | This was the v0.13/v0.14 root cause. F.2 (the new check) asserts the template settings.json has the wiring; the existing `test-init` regression should catch the missing rule index because `test-init` runs the init template and then runs verify_all in the fixture, which would F.* (project-level) the bidirectional check. Developer manually verifies the zh path; QA inspects on real-init. |
| R9 | `scripts/guard-rm.*` mirror drift between template and dogfood (Layer 1) | L | M | `verify_all.E.1` calls `sync-self --check`; once §10 lands, `guard-rm.{ps1,sh}` are in the mapping → any drift is caught. |
| R10 | User in a non-git directory hits no-op WARN unexpectedly | L | L | Documented in `75-safety-hook.md` boundary B7. Stderr WARN is loud enough that the user sees it in the tool transcript. |
| R11 | Edit-tool false success on multi-line `AI-GUIDE.md` edits (insight) | M | M | Developer instruction: after every Edit on AI-GUIDE.md / `.tmpl` files / verify_all.{ps1,sh}, re-Read or Grep to confirm the change. Code Reviewer explicitly verifies the same. |
| R12 | The hook spawns pwsh on Linux/macOS where it may not exist | L | H (every Bash call blocked) | Template OS-detect picks `bash scripts/guard-rm.sh` on macOS/Linux, `pwsh -File scripts/guard-rm.ps1` on Windows — same logic as `{{SYNC_COMMAND}}`. The dogfood (this repo) is Windows + has pwsh, so the dogfood value is the pwsh form. |

---

## 14. Migration / rollout plan

### 14.1 Backwards compatibility

- **Dogfood (this repo)**: `.claude/settings.json` gains the `PreToolUse` block. Existing `Stop` and `permissions` blocks are untouched. JSON shape is additive.
- **Existing `/harness-init` users (pre-v0.15 projects)**: not auto-migrated. They re-run `/harness-adopt` to get the guard (see §8).
- **New `/harness-init` users (v0.15+)**: get the guard automatically; no opt-in question (per decision #12).
- **`harness-sync`**: unchanged scope — it does NOT sync `.claude/settings.json` and never has. Re-running `harness-sync` on an existing project does NOT install the guard. This is correct: `harness-sync` is per-session, settings.json is per-project, the lifecycle differs.

### 14.2 Rollout steps (developer task list, in dependency order)

1. **D3 scripts first** — write `scripts/guard-rm.ps1` + `.sh` in `templates/common/scripts/`.
2. Run `scripts/sync-self.ps1` to mirror them into `scripts/guard-rm.{ps1,sh}` (after adding the mappings).
3. Write `.harness/rules/75-safety-hook.md` (dogfood) + `.tmpl` (template) + zh overlay.
4. Update `AI-GUIDE.md` (dogfood + tmpl + zh) — rule-fragment index + "AI tool flow modes" + sub-agent callout + check counts.
5. Update `60-tool-handoff.md` (dogfood + tmpl + zh) — append continuous mode subsection.
6. Update `copilot-instructions.md` (dogfood + tmpl + zh) — third red line.
7. Update `.claude/settings.json` (dogfood) + `.tmpl` (with `{{GUARD_COMMAND}}`).
8. Update `verify_all.ps1` + `.sh` — add F.2 + extend D.2 whitelist.
9. Update `harness-init/SKILL.md` (step 4/5/8/11) + `harness-adopt/SKILL.md` (step 5/6) + `harness-status/SKILL.md` (§1/§3b/§6).
10. Update `40-locations.md` — 26→27, +F.2 line.
11. Update `plugin.json` / `marketplace.json` / `README*.md` badges → 0.15.0, 27/27.
12. Write `CHANGELOG.md [0.15.0]` entry.
13. Update `docs/getting-started.md` (Grep for stale numbers; patch only the spots).
14. Run `scripts/verify_all` → must PASS 27/27.
15. Write `evals/guard-rm-cases.md` + a driver script under `scripts/test-guard-rm.{ps1,sh}` (Developer's call whether to ship the driver in v0.15 or run it ad-hoc during QA).

### 14.3 Rollback

- **Per-user**: delete the `PreToolUse` block from their `.claude/settings.json`; the script stays on disk but is never invoked.
- **Per-release**: revert v0.15.0 commit; `sync-self --check` will note `guard-rm.*` is now orphan in dogfood (the template no longer has them) and remove them.

### 14.4 Feature flag

None. The guard is on by default per decision #12. The override env var IS the per-call flag; deletion of the PreToolUse entry IS the per-project flag.

---

## 15. Out-of-scope clarifications (this design)

This design does NOT cover:

- **A `jq` dependency**. The bash JSON extraction uses a sed/grep heuristic that works on Claude Code's known tool-input shape. If users have `jq`, great; if not, fine. No install step.
- **A PowerShell module / cmdlet** packaging. The script is a single `.ps1` file with no helper modules.
- **Telemetry of block events**. We do not phone home or write block events to a log file. The stderr message IS the audit trail (Claude Code records it).
- **Cross-tool enforcement**. Copilot/Cursor have no hook mechanism; the rule fragment documents the gap (per requirement decision #4).
- **A `--dry-run` mode**. The Developer can prepend `HARNESS_ALLOW_OUTSIDE_RM=1` to test; that's the documented rehearsal path.
- **Cleaning up the existing `Bash(rm -rf /:*)` deny-line** in `.claude/settings.json`. It stays as a belt-and-suspenders measure even though `guard-rm` is strictly stronger; removing it would be a separate change.
- **Modifying `harness-sync`'s scope** to also sync `.claude/settings.json`. That's a long-standing intentional carve-out (settings.json is user-customizable; only init/adopt write to it).
- **Implementing the QA test cases**. The Architect specifies the fixture table (acceptance B2); Developer writes the driver; QA runs the adversarial pass.

---

## 16. Partition assignment

This repo uses **single-developer mode** — no `.harness/agents/dev-*.md` files exist (verified by `Glob` returning empty for `.harness/agents/dev-*.md`).

| File | Partition | New / Edit | Dependency |
|---|---|---|---|
| All files in §3 | `developer` | as noted | sequential within the order in §14.2 |

### Dispatch order

1. `developer` — single agent does all 34 files.

### Parallelism

None — single agent. Within the agent's work, §14.2 step-order matters because step 2 (`sync-self`) only works after step 1 (template SOT scripts exist).

---

## 17. Cross-cutting checklist (the gotchas spelled out)

- **Edit tool false success** (insight 2026-05-16): Developer MUST re-Read every file after every Edit. Especially load-bearing for `verify_all.{ps1,sh}` (D.2 whitelist + new F.2), `AI-GUIDE.md` (×3 surfaces), and the three `60-tool-handoff.md` surfaces.
- **bash `declare -a` + `set -u`** (insight 2026-05-16): the new bash guard script MUST use `arr=()`. Code Reviewer checks. `sync-self.sh` and `harness-sync.sh` already pass — no regression here.
- **New `{{...}}` placeholders** (insight 2026-05-16): only one new placeholder this task → `{{GUARD_COMMAND}}`. Add to BOTH `verify_all.ps1:94` (`$allowed`) and `verify_all.sh:79` (case pattern). D.2 will FAIL until both are updated.
- **Bidirectional rule indexing** (insight 2026-05-16): `75-safety-hook.md` MUST appear in: `AI-GUIDE.md` (dogfood), `templates/common/AI-GUIDE.md.tmpl`, `templates/i18n/zh/common/AI-GUIDE.md.tmpl`. E.4b enforces the dogfood half automatically. Template halves are caught by `test-init` regression IF the regression includes verify_all of the rendered fixture (it does, per `test-init.{ps1,sh}`).
- **Cross-platform JSON command quoting**: the `command` field in `PreToolUse` is a plain string that Claude Code runs via the shell on the host OS. We mirror `{{SYNC_COMMAND}}`'s detection at init time, hard-coding one of two literal commands (`pwsh -File scripts/guard-rm.ps1` on Windows, `bash scripts/guard-rm.sh` elsewhere). No runtime OS-detection in the JSON; rendered once at init.
- **Version drift** (insight 2026-05-16 about v0.13/v0.14 release drift): the §3 file plan includes plugin.json + marketplace.json + both README badges + CHANGELOG + getting-started (conditional) + AI-GUIDE.md check count + 40-locations check count. Developer MUST touch every one; Code Reviewer's checklist includes a `Grep "26/26"` to confirm no stale match remains.

---

## 18. Verdict

**READY FOR GATE REVIEW**

Every file is enumerated with an absolute path and a stated action. The two new scripts have a designed-in-detail algorithm (§4) with explicit pseudo-code skeletons; the settings.json shape is exact (§5); the new verify_all check has an ID (F.2 — reviving the v0.14.x-vacated slot), assertions, and PASS-level (§6); the rule fragment has a structure (§7) and is auto-covered by E.4b for dogfood indexing; harness-adopt's JSON-merge approach is specified (§8); harness-status's new lines and health bump are specified (§9); sync-self's exact diff is in §10; all 5 known gotchas are addressed in §17; partition assignment is `developer` (single mode) with the dependency-ordered task list in §14.2.

A junior developer could implement this without further design decisions. The remaining freedom is purely tactical (exact regex in the tokenizer, exact JSON pretty-print style in the adopt merge) — both explicitly punted to implementation in §4.1 and §8.2.
