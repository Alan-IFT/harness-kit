# 02 — Solution Design · T-018 decision-mode-skill

> Stage 2 (Solution Architect). Mode: **full**. Upstream: `01_REQUIREMENT_ANALYSIS.md` (verdict READY).
> Carries the 4 RA defaults (OQ-1=a minimal, OQ-2=defer zh, OQ-3=leave non-empty custom, OQ-4=halt+point).
> Grounded by reads of: verify_all.sh C.1/G.1/G.2/G.3/G.4 sites, install.{ps1,sh}, README.md,
> AI-GUIDE.md.tmpl, marketplace.json, `.claude/skills/` (empty), `.harness/skills/` (empty).

## 1. Architecture summary

A documentation + skill change, no runtime/binary code. Three asset families change:
(A) the **dogfood policy** (`25-decision-policy.md` gains Mode 3; `decision-rubric.md` splits into Preset/Custom);
(B) a **new plugin skill** `skills/harness-decision-mode/` — an interactive Mode-1/2/3 switcher modeled on
`/harness-language`, doing a single-line surgical rewrite of the "Active mode" line plus an empty-Custom
Mode-3 capture; (C) **generic template copies** of the two policy assets shipped into
`templates/common/.harness/` (Active mode default 1, generic Preset), with the template AI-GUIDE indexing them;
(D) the standard **release fan-out** (version 0.28.0, skill-count 14→15, READMEs/CHANGELOG/install/dev-map +
the C.1/G.1/G.2 verify_all skill-enumeration sites). **No new `verify_all` check** — check count stays 32, so
G.4 (which gates the CHECK count, not the skill count) is unaffected by anything but the version bump.

**OQ-5 resolved (mechanical):** `.claude/skills/` and `.harness/skills/` are both EMPTY in this dogfood repo
(verified by Glob). Plugin skills live ONLY under top-level `skills/`. `harness-sync`/E.2 mirror
`.harness/skills ↔ .claude/skills` (project-level build/test/verify skills), NOT the top-level plugin
`skills/`. Therefore `harness-decision-mode` needs **no `.claude/skills/` copy** and **no sync-self/harness-sync
run** for the skill. (Consistent with how the existing 14 plugin skills are stored.) Confirms RA NFR-4.

## 2. Affected modules / files

### Family A — dogfood policy (THIS repo)
- `.harness/rules/25-decision-policy.md` — edit: add Mode 3; generalize "two modes"→"three modes"; extend
  red-lines/audit-trail "all three modes" wording; extend "How an agent applies it". Active mode line stays 2.
- `.harness/decision-rubric.md` — edit: wrap the existing prime-directive + standing-preferences body under a
  new `## Preset rubric (Mode 2)` heading; append an empty `## Custom rubric (Mode 3)` section.

### Family B — new plugin skill
- `skills/harness-decision-mode/SKILL.md` — NEW.

### Family C — template (shipped to generated projects)
- `skills/harness-init/templates/common/.harness/rules/25-decision-policy.md` — NEW (generic; Active mode 1).
- `skills/harness-init/templates/common/.harness/decision-rubric.md` — NEW (generic Preset; empty Custom).
- `skills/harness-init/templates/common/AI-GUIDE.md.tmpl` — edit: add the `25-decision-policy.md` index line
  (after the `05-insight-index.md` line, before `50-…`) + add a `decision-rubric.md` memory-layer bullet.

### Family D — release fan-out
- `.claude-plugin/plugin.json` — `version` 0.27.0 → 0.28.0.
- `.claude-plugin/marketplace.json` — `version` (line 17) → 0.28.0.
- `README.md` — version badge → 0.28.0; `14 skills`/`fourteen` → `15`/`fifteen`; new skill bullet; test
  badges if they move (see §6 baseline).
- `README.zh-CN.md` — mirror: skill bullet, count claims (`14`/十四 → `15`/十五; the G.4 zh `（N 项检查）`
  claim is a CHECK count = 32 → **do NOT touch**), version badge, moved test badges.
- `CHANGELOG.md` — new `## [0.28.0]` section; must contain literal `harness-decision-mode` (G.2).
- `install.ps1` + `install.sh` — append `harness-decision-mode` to the skills array (symmetric).
- `AI-GUIDE.md` (dogfood) — add a Workflow-entry row for the skill (line 26 `25-decision-policy` index already
  present; verify intact).
- `docs/dev-map.md` — skill tree row + decision-policy asset rows (dogfood + template).
- `.harness/scripts/verify_all.{ps1,sh}` — C.1, G.1, G.2: add `harness-decision-mode` to each enumeration loop
  + bump label `14`→`15`. (Exact ledger §7.)
- `docs/manual-e2e-test.md` + `.harness/rules/40-locations.md` — `14 skills`/`All 14 skills` → `15` (§7 ledger).
- `.harness/scripts/test-init.{ps1,sh}` + `baseline.json` — see §6 (decision: add a presence assertion for the
  2 new template rule/rubric files + reconcile any count the new files move).

## 3. Module decomposition (the new skill)

**`skills/harness-decision-mode/SKILL.md`** — judgment + light mechanical layer.

Unlike `/harness-language` (which delegates ALL string work to a `language-policy.{ps1,sh}` helper), the
edits here are simpler and bounded — a single-line replace plus a section append. **Design decision: NO new
`.{ps1,sh}` helper.** Rationale:
- The Active-mode rewrite is a one-line `Edit` (old "Active mode: N …" line → new). The skill uses the `Edit`
  tool directly with an exact old/new string; this is well within an AI-driven skill's competence and avoids a
  cross-shell helper pair (which would add NFR-1 byte-parity burden for ~10 lines of logic — violates rule 15
  P6 "don't add machinery unless it earns it" + operator anti-bloat preference).
- The Mode-3 capture is an `AskUserQuestion` + an `Edit` that replaces the empty Custom-section body with the
  collected prompts.
- This is consistent with the *other* interactive skills that edit by `Edit` without a helper (e.g.
  `/harness-intervene` writes the signal file directly). `/harness-language` only needed a helper because of
  heading-anchored section slicing + en↔zh byte-identical round-trip — neither applies here.

**Skill responsibilities (the contract, not a rigid script):**
1. **Precondition gate** — cwd is the target project; require `.git/` and a clean `git status --porcelain`
   (so `git reset` is the rollback); require `.harness/rules/25-decision-policy.md` to exist.
2. **Read current mode** — parse the `Active mode:` line from `25-decision-policy.md`. Recognizer:
   the unique line matching `^**Active mode: [123]` (bolded) OR `Active mode: [123]` — the canonical line is
   ``**Active mode: 2 (rubric-guided autonomy, "balanced" calibration).**``. Display "current = Mode N".
3. **Pick target** — `AskUserQuestion` with three options (Mode 1 human-decides / Mode 2 preset-rubric /
   Mode 3 custom-rubric), each option's description stating what that mode does. Pre-select the current mode.
4. **Idempotency** — if target == current → no-op, report "already Mode N", stop (no write, no `.bak`).
5. **Confirm + apply** — show the single-line diff (old Active-mode line → new), `AskUserQuestion` "Apply?
   [yes/no]". On yes: `Edit` the one line. Write a `.bak` of `25-decision-policy.md` first (mirrors
   `/harness-language` non-destructive contract).
6. **Mode-3 empty-Custom capture** — if target == 3 AND `decision-rubric.md`'s `## Custom rubric (Mode 3)`
   body is empty (only the one-line instruction): `AskUserQuestion` (free-text via "Other") collecting the
   user's custom decision prompts; `Edit` them into the Custom section (replacing the instruction line, or
   appending under it — see §5 flow). If Custom is already non-empty (OQ-3 default) → leave it, just switch.
7. **Final report** — "Set decision mode to N (was M). Files: 25-decision-policy.md (Active-mode line);
   [decision-rubric.md Custom section, if captured]. Backups: <.bak>." Suggest nothing else (no verify_all
   needed — edits policy prose, not scripts).

**Frontmatter `description:` (rule 15 P1)** — concrete EN+中文 triggers + when-NOT delta. Draft:
> Switch or set a harness project's decision/escalation MODE — Mode 1 (human decides every judgment call,
> the safe default), Mode 2 (the AI decides per the preset rubric and escalates only red lines), or Mode 3
> (the AI decides per YOUR custom rubric). Surgically rewrites only the "Active mode" line of
> `.harness/rules/25-decision-policy.md`; on a first switch to Mode 3 it collects your custom decision prompts
> and writes them into the rubric's Custom section. Use when you want to change how much the AI decides on its
> own vs. asks you — "switch decision mode", "let the AI decide on its own", "make it ask me first",
> "切换决策模式", "让 AI 自己拿主意", "改成人工决策", "用我自己的决策规则". NOT for changing the rubric's
> CONTENT alone (edit `.harness/decision-rubric.md` directly), NOT for output-language (`/harness-language`),
> NOT for layout upgrades (`/harness-upgrade`).

**`allowed-tools:`** `Read, Write, Edit, Glob, Grep, AskUserQuestion, TodoWrite` (NO Bash/PowerShell needed —
no helper; `git status` precondition can be checked via the user or a Bash call if available, but to keep the
skill tool-light, the clean-tree precondition is asserted by reading `git status --porcelain` IF Bash is
available, else instruct the user to ensure a clean tree — modeled as a soft gate. **Decision:** include `Bash`
in allowed-tools so the clean-tree check is real, matching `/harness-language`'s precondition rigor.)
→ Final `allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, TodoWrite`.

## 4. Policy & rubric content design

### 4.1 `25-decision-policy.md` Mode-3 edits (dogfood + template share structure)
- Rename "## The two modes" → "## The three modes"; add the Mode 3 bullet:
  > **Mode 3 — user-custom autonomy.** Same mechanism as Mode 2, but the AI decides by the user's OWN
  > **Custom rubric** (`.harness/decision-rubric.md` → `## Custom rubric (Mode 3)`) instead of the Preset
  > rubric. The three prime principles remain the floor; the red lines and the audit trail below apply
  > unchanged. Coverage of the Custom rubric is the control knob exactly as in Mode 2.
- Red-lines heading: "ALWAYS escalate (both modes…" → "ALWAYS escalate (all three modes…".
- Audit-trail section: "Every autonomous Mode-2 decision" → "Every autonomous Mode-2 / Mode-3 decision".
- "How an agent applies it (Mode 2)" → add a one-line note: "Mode 3 is identical, reading the Custom rubric
  where Mode 2 reads the Preset rubric."
- "## The three modes" preamble keeps Mode 1 + Mode 2 text intact.
- **Active mode line:** dogfood stays ``**Active mode: 2 …**``; template ships ``**Active mode: 1 …**`` (new
  projects start human-decides) with prose "this is the safe default; opt into Mode 2/3 via
  `/harness-decision-mode`".

### 4.2 `decision-rubric.md` restructure
- **Dogfood:** existing body (Prime directive + Standing preferences + "Escalate anyway") moves UNDER a new
  `## Preset rubric (Mode 2)` heading verbatim. Then append:
  ```
  ## Custom rubric (Mode 3)

  > Author your own decision prompts here — the AI reads ONLY this section under Mode 3
  > (the Preset above is ignored). The red lines in 25-decision-policy.md still apply.
  > Empty by default; /harness-decision-mode fills it on your first switch to Mode 3.
  ```
  (empty body — instruction only)
- **Template (generic):** same two-section skeleton. The Preset contains ONLY:
  - The three prime principles (good UX → sound engineering → long-term maintainability), generically worded
    (no operator-personal framing).
  - Universal defaults: reversible+in-scope → just do it (report after); match existing conventions; honest
    reporting / never fabricate results; verify before declaring done; profile before optimizing.
  - A generic "Escalate anyway" trio (product-direction call; genuine principle conflict; any red line).
  - **EXCLUDES** (AC-4 banned list): "lightweight over heavy", "design out the root cause / don't accrete
    guards", "chat replies in Chinese", operator commit/push authorization, verify_all/dogfood/this-repo refs,
    and the "seeded 2026-06-10 from the operator's prior guidance" provenance line.
  - Custom section: same empty instruction skeleton as dogfood.

### 4.3 Template AI-GUIDE index (item 22 / AC-7)
Add to `AI-GUIDE.md.tmpl` after the `05-insight-index.md` bullet (keeps numeric order 00<05<25<50):
> - **`.harness/rules/25-decision-policy.md`** (**load when you would ask the user / call `AskUserQuestion`**):
>   the decision & escalation policy — Mode 1 (human decides, **the default for new projects**) vs Mode 2
>   (preset-rubric autonomy) vs Mode 3 (your custom rubric) + the always-escalate red lines. Switch modes with
>   `/harness-decision-mode`.

And in the template **Memory layer** block (after the insight-index bullet):
> - **`.harness/decision-rubric.md`** — the principles the AI decides by under Mode 2 (Preset) / Mode 3
>   (Custom); read at every escalate-or-decide point. Edit to widen / narrow autonomy.

## 5. Sequence / flow (the skill, happy + Mode-3 path)

```
/harness-decision-mode
 1. gate: .git? clean tree? 25-decision-policy.md present?   ──no──► halt w/ reason (OQ-4: point at /harness-upgrade if no policy file)
 2. read Active-mode line → current = Mode M ; display
 3. AskUserQuestion: pick 1 | 2 | 3  (preselect M)
 4. target == M ?  ──yes──► "already Mode M", STOP (no write)
 5. show 1-line diff; AskUserQuestion Apply? ──no──► STOP (no write)
 6. write 25-decision-policy.md.bak ; Edit the single Active-mode line → Mode T
 7. target == 3 AND Custom section empty ?
        ──yes──► AskUserQuestion (free-text "Other") collect prompts
                 write decision-rubric.md.bak ; Edit Custom-section body ← prompts
        ──no───► (Mode 3 w/ non-empty Custom: leave it / OQ-3 default)
 8. report: mode M→T ; files touched ; .bak paths
```

## 6. test-init / baseline decision (item 33 / AC-13)

The two new template files (`25-decision-policy.md`, `decision-rubric.md`) are plain `.md` under
`templates/common/.harness/` — they get copied verbatim by `/harness-init` into every generated project's
`.harness/`. **Decision: ADD a presence assertion** to `test-init.{ps1,sh}` for both files in the generated
tree (symmetric), because:
- test-init already asserts the generated `.harness/rules/` set; two new always-shipped files should be
  covered so a future deletion is caught.
- This moves the test-init assertion count up by a fixed delta in BOTH shells → `baseline.json`'s
  test-init counts (`test_init` PS/Bash) must be reconciled to a captured run. **This is operator-run**
  (sub-agents have no Bash) — Dev specifies the exact assertions + the expected delta; the OPERATOR runs
  test-init, reads the real tally, and reconciles baseline.json + the README test-init badge. Dev must NOT
  fabricate the number (insight L23/T-007). The dev doc marks this `[operator-run: capture real tally]`.

The two new files do NOT contain `{{placeholders}}` → no D.2 whitelist change, no test-init
no-unresolved-placeholder regression (NFR-3 satisfied). They are NOT `.tmpl` (no substitution needed).

**G.4 / check-count:** unchanged at 32 (no new check). G.4 gates the CHECK count, so it stays green on the
version bump alone. The skill-count (15) is gated by C.1/G.1/G.2 label+loop only.

## 7. The exact fan-out ledger (Developer's checklist — file:site → change)

> This is the project's #1 recurring failure surface (insight L24/L5). Enumerated exhaustively below; Dev runs
> `verify_all` (the canonical exhaustive scan, L29) — but verify_all only gates SOME of these, so the manual
> ledger is load-bearing. **[operator-run]** the final verify_all/test-init.

| # | File | Site | Change | Gated by |
|---|---|---|---|---|
| 1 | `.claude-plugin/plugin.json` | `"version"` | `0.27.0`→`0.28.0` | G.3 |
| 2 | `.claude-plugin/marketplace.json` | line ~17 `"version"` | →`0.28.0` | G.3 |
| 3 | `README.md` | badge `version-0.27.0` | →`0.28.0` | G.3 |
| 4 | `README.zh-CN.md` | badge `version-0.27.0` | →`0.28.0` | G.3 |
| 5 | `README.md` | `:7` `14 skills`, `:13` `fourteen` | →`15`/`fifteen` | G.1 (name) + prose |
| 6 | `README.md` | new skill bullet under **Operations skills** (`:29-33`) | add `/harness-kit:harness-decision-mode` | G.1 |
| 7 | `README.zh-CN.md` | count claims `14`/十四 + skill bullet | →`15`/十五 + add bullet | G.1 |
| 8 | `CHANGELOG.md` | top | new `## [0.28.0]` section incl. literal `harness-decision-mode` (≥1×) | G.2 |
| 9 | `install.ps1` | `$skills = @(...)` | append `"harness-decision-mode"` | F.1 |
| 10 | `install.sh` | `skills=(...)` | append `harness-decision-mode` | F.1 |
| 11 | `AI-GUIDE.md` (dogfood) | Workflow-entry table (`:97` area) | add a `/harness-decision-mode` row | — (prose) |
| 12 | `AI-GUIDE.md` (dogfood) | `:7` `14 skills` | →`15 skills` | G.4? NO (skill count, not check) → prose only |
| 13 | `docs/dev-map.md` | skills tree + asset rows | add skill + `25-decision-policy`+`decision-rubric` (dogfood+template) | — |
| 14 | `.harness/scripts/verify_all.sh` | C.1 loop+label, G.1 loop+label, G.2 loop+label | add skill to 3 loops + `14`→`15` in 3 labels | self |
| 15 | `.harness/scripts/verify_all.ps1` | C.1/G.1/G.2 (twin) | same as #14 | F.1 (ps/sh parity) |
| 16 | `docs/manual-e2e-test.md` | `:34`,`:49` `14 skills` + enumerations | →`15` + add `harness-decision-mode` | — |
| 17 | `.harness/rules/40-locations.md` | `:30` `All 14 skills` | →`All 15 skills` | — |
| 18 | `.harness/scripts/test-init.{ps1,sh}` | new presence assertions (2 files) | add symmetric | — |
| 19 | `.harness/scripts/baseline.json` | `test_init` counts (+ `verify_all_checks` stays 32) | reconcile to real run **[operator-run]** | G.4 (checks=32 unchanged) |
| 20 | `README.md`/`README.zh-CN.md` | `test-init` badge `275/275` | reconcile if test-init delta moves it **[operator-run]** | — |

> NOTE on #12/#17/#16: these `14 skills` claims are NOT in G.4's ledger (G.4 only tracks the verify_all
> CHECK count, which stays 32) and NOT gated by any check → they are MANUAL. The Code Reviewer + QA must grep
> the live tree for every `14`/`fourteen`/`十四` skill claim and confirm each flipped (insight L26: when
> grepping, beware count tokens that are CHECK counts (32) not SKILL counts — do NOT touch the 32s).

## 8. Reuse audit

| Need | Existing | File path | Decision |
|---|---|---|---|
| Interactive surgical-edit + git-clean gate + confirm flow | `/harness-language` SKILL | `skills/harness-language/SKILL.md` | **Reuse the pattern** (precondition gate, AskUserQuestion, `.bak`, idempotent no-op, anti-patterns/when-NOT sections). Do NOT reuse its helper — no section-slicing needed here. |
| Single-line policy edit | `Edit` tool | — | Direct `Edit`, no helper (§3 rationale). |
| Free-text capture | `AskUserQuestion` "Other" | — | Standard. |
| Release fan-out ledger shape | T-014 §11 | `docs/features/_archived/harness-language-skill/02_SOLUTION_DESIGN.md:485-500` | Mirror its shape (§7 here). |
| Policy/rubric content (dogfood) | existing files | `.harness/rules/25-decision-policy.md`, `.harness/decision-rubric.md` | Extend in place. |
| Skill-count enumeration sites | verify_all C.1/G.1/G.2 | `.harness/scripts/verify_all.{ps1,sh}` | Edit loops+labels (§7 #14-15). |

## 9. Risk analysis

- **R1 — Shipped Preset leaks operator-personal prefs (AC-4, the #1 correctness risk).** A copy-paste of the
  dogfood rubric into the template would ship the banned phrases. *Mitigation:* the template rubric is
  AUTHORED FRESH (not copied) from the generic skeleton in §4.2; the Code Reviewer greps the template file for
  every banned phrase (item 19 list) as an explicit review item; QA re-greps. Verdict-blocking if any hit.
- **R2 — Skill-count fan-out drift (recurring, insight L24/L5).** A `14` left somewhere → C.1/G.1/G.2 FAIL or
  a silent prose lie. *Mitigation:* §7 exhaustive ledger; Dev runs verify_all (operator); CR+QA grep every
  `14`/`fourteen`/`十四` SKILL token and confirm flip, while NOT touching the CHECK-count `32`/`（32 项检查）`
  tokens (insight L26 same-file-token discrimination).
- **R3 — verify_all C.1/G.1/G.2 ps/sh drift (F.1).** Editing only one shell. *Mitigation:* §7 #14-15 pairs the
  edit; F.1 catches asymmetry; CR audits both shells line-for-line.
- **R4 — test-init baseline fabrication (insight L23/T-007).** Dev guessing the new assertion tally.
  *Mitigation:* §6 marks the count `[operator-run: capture real tally]`; Dev writes the assertions but leaves
  the baseline number to the operator's real run; QA confirms the run was real.
- **R5 — I.6 self-trip / banned-anchor (insight L30/L31).** None of T-018 RETIRES a claim, so the I.6
  four-file lockstep is untouched. *Mitigation:* Dev confirms no retired claim is introduced; any new doc text
  (CHANGELOG, policy) avoids existing I.6 banned anchors. CR/QA confirm I.6 PASS.
- **R6 — Mode-3 capture clobbers a non-empty Custom rubric.** *Mitigation:* §3 step 6 + OQ-3 default = capture
  ONLY when empty; the empty-check is on the Custom section body, and a `.bak` precedes any rubric edit.
- **R7 — Doc-size cap breach (rule 70).** Adding Mode 3 grows `25-decision-policy.md` (currently 87 lines, cap
  200 — ample); AI-GUIDE.md (currently 108, cap 200 — adding 1 Workflow row is fine). *Mitigation:* keep Mode 3
  additions terse; CR checks I.1/I.2 stay PASS.

## 10. Migration / rollout plan

- Backwards compatible: existing dogfood `25-decision-policy.md` consumers see a superset (Mode 1/2 unchanged;
  Mode 3 added). The dogfood Active mode stays 2 → no behavior change for this repo's agents.
- Generated projects: NEW files only (additive); existing generated projects don't retroactively get them
  (that's `/harness-upgrade` territory, out of scope — OQ-4).
- Rollback: green-tree hand-off; operator `git reset` reverts everything (HARD CONSTRAINT #1).
- No data, no API, no schema.

## 11. Out-of-scope clarifications (design boundaries)

- No `decision-mode.{ps1,sh}` helper (§3 rationale) — the skill edits via `Edit` directly.
- No new `verify_all` check (O-6); check count stays 32.
- No zh-overlay policy copy (OQ-2 default defer); English `common/` only.
- No fix to the install-array's pre-existing missing `harness-language`/`harness-upgrade` (OQ-1 default
  minimal) — append only `harness-decision-mode`. Flag to operator at delivery.
- No bootstrap of a missing policy file in the skill (OQ-4 default = halt + point at `/harness-upgrade`).
- No deep per-agent rubric integration (O-3).

## 12. Partition assignment

N/A — single Developer mode (no `.harness/agents/dev-*.md`). The generic `developer` implements all families.

## 13. Verdict

**READY for Gate Review.**

The design is complete enough to implement without further design decisions: every file/site is enumerated in
§2 + §7, the generic-vs-personal split is specified as a fresh-authored skeleton (§4.2) with an explicit banned
list, the skill contract is bounded (§3, no helper), OQ-5 is resolved mechanically, and the operator-run gates
(verify_all, test-init/baseline) are marked so no agent fabricates a tally. Carries the 4 RA defaults; CR/QA
have explicit grep duties for R1/R2.

---

## Amendment 1 (round 2, post-Gate F-1/F-2) — 2026-06-10

Gate Review (03_GATE_REVIEW.md) returned **BLOCKED ON DESIGN**: F-1 (blocking) — the §7 ledger omitted
`docs/getting-started.md`, a live ungated "fourteen skills" surface with its own skill enumeration; F-2
(advisory) — §7 row 16 under-specified `manual-e2e-test.md`'s `fourteen` sites. Both accepted. I re-ran a
fresh live-tree `14 skills|fourteen|十四|All 14` grep to make the ledger exhaustive this time.

### A1.1 — New ledger row (fixes F-1): `docs/getting-started.md`

| # | File | Site | Change | Gated by |
|---|---|---|---|---|
| 21 | `docs/getting-started.md` | `:36` `fourteen skills` | →`fifteen skills` | — (ungated, MANUAL) |
| 22 | `docs/getting-started.md` | **Operations** group (`:53+`) | add a `harness-decision-mode` bullet (mirror the Pipeline/Setup/Operations grouping; place after `harness-language` / alongside the other ops skills) | — |

`getting-started.md` is also added to **§2 Family D** (it was missing). Its grouping (lines 38-54) is
Pipeline / Setup / Operations — the new skill is an Operations-class control (switches a policy), so its bullet
goes in the **Operations** group, consistent with the README placement (§7 row 6).

### A1.2 — Clarify ledger row 16 (fixes F-2): `manual-e2e-test.md` exhaustive sites

Row 16 is replaced by this explicit enumeration (live-grep confirmed):
- `docs/manual-e2e-test.md:7` — "load the **fourteen** skills?" → `fifteen`
- `docs/manual-e2e-test.md:34` — "all **14 skills** (harness, harness-init, …)" → `15 skills` + add
  `harness-decision-mode` to the parenthetical enumeration
- `docs/manual-e2e-test.md:49` — "all **14 skills**. After completion, list them:" → `15 skills` + add to the
  post-completion listing
- `docs/manual-e2e-test.md:60` — "the **fourteen** `/harness-*` commands appear (`/harness`, …)" → `fifteen`
  + add `/harness-decision-mode` to the command enumeration

### A1.3 — Re-confirmation grep (exhaustive ungated skill-count surfaces)

The complete set of LIVE skill-count claim surfaces (excluding `docs/features/**` archived task docs and this
task's own docs, which are not shipped/gated) is now:

| Surface | Token(s) | In ledger |
|---|---|---|
| `README.md:7,:13` | `14 skills`, `fourteen` | §7 row 5 ✓ |
| `README.zh-CN.md:7,:13` | `14 个 skills`, `14 个 AI skill` | §7 row 7 ✓ |
| `AI-GUIDE.md:7` | `14 skills` | §7 row 12 ✓ |
| `docs/getting-started.md:36` | `fourteen` | **row 21 (NEW)** ✓ |
| `docs/manual-e2e-test.md:7,:34,:49,:60` | `fourteen`/`14 skills` | **row 16 (clarified A1.2)** ✓ |
| `.harness/rules/40-locations.md:30` | `All 14 skills` | §7 row 17 ✓ |
| `.harness/scripts/verify_all.{sh,ps1}` C.1/G.1/G.2 labels | `All 14 skills` / `references all 14 skills` / `mentions all 14 skills` | §7 rows 14-15 ✓ |

(The `README.zh-CN.md:257` `14 个文件` token is a v0.15.1 CHANGELOG-prose "14 FILES" reference, NOT a skill
count — do NOT touch. Insight L26 token-discrimination: confirm the noun before flipping.) No other live
ungated surface remains. The ledger (§7 rows 1-20 + amendment rows 16-clarified, 21, 22) is now exhaustive.

### A1.4 — Verdict (round 2)

**READY for Gate Review (re-review).** Scope of change: 2 new ledger rows + 1 row clarification + add
`getting-started.md` to Family D. No change to the skill contract, the generic-split design, OQ resolutions,
or any other section. The Gate's F-3 (don't touch the `32`/`（32 项检查）` CHECK-count tokens) is reaffirmed.
