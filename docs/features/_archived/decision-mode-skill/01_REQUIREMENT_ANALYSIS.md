# 01 — Requirement Analysis · T-018 decision-mode-skill

> Stage 1 (Requirement Analyst). Mode: **full**. Input: `INPUT.md` (read-only).
> Source-of-truth assets read: `.harness/rules/25-decision-policy.md`, `.harness/decision-rubric.md`,
> `skills/harness-language/SKILL.md`, `install.{ps1,sh}`, `README.md`, `.harness/scripts/verify_all.sh`
> (C.1/G.1/G.2/G.3 sites), rule fragments 10/15/20/70.

## 1. Goal

Ship a 15th plugin skill `/harness-decision-mode` (an interactive Mode 1/2/3 switcher) AND extend the
decision-policy mechanism with **Mode 3 (user-custom rubric)**, then distribute the policy mechanism —
with **generic** defaults — to all `/harness-init`-generated projects, as release **v0.28.0**.

## 2. In-scope behaviors (numbered, testable)

### A. Mode 3 in the policy + rubric restructure (dogfood)

1. `.harness/rules/25-decision-policy.md` gains a **Mode 3 — user-custom autonomy** definition: the AI
   decides per the user's OWN custom rubric (the "Custom rubric" section) instead of the preset rubric.
2. The doc states explicitly that the **red lines AND the audit trail apply to all THREE modes** unchanged,
   and the three prime principles remain the floor under Mode 3.
3. The "How an agent applies it" guidance covers Mode 3 (reads Custom rubric where Mode 2 reads Preset).
4. `.harness/decision-rubric.md` is restructured into exactly two delimited sections:
   `## Preset rubric (Mode 2)` and `## Custom rubric (Mode 3)`.
5. The **Preset rubric (Mode 2)** section of the **dogfood** rubric retains the existing seeded operator
   personal preferences verbatim (prime directive + standing preferences currently in the file).
6. The **Custom rubric (Mode 3)** section in the dogfood rubric starts EMPTY — a one-line instruction
   telling the user to author their own decision prompts here, nothing else.
7. The dogfood `25-decision-policy.md` **Active mode** line stays **2** (unchanged).

### B. New skill `skills/harness-decision-mode/SKILL.md`

8. A new top-level plugin skill directory `skills/harness-decision-mode/` with a `SKILL.md`.
9. The skill's runtime flow: read & display the project's CURRENT Active mode from
   `.harness/rules/25-decision-policy.md` → `AskUserQuestion` to pick Mode 1 / 2 / 3 → on confirm,
   surgically rewrite ONLY the single "Active mode" line → confirm the result back to the user.
10. The "Active mode" rewrite is a **single-line surgical edit**: only the line declaring the active mode
    changes; every other byte of `25-decision-policy.md` is preserved.
11. If the chosen mode is **3** AND the target's `## Custom rubric (Mode 3)` section is empty, the skill
    collects the user's custom decision prompts via `AskUserQuestion` (free-text / "Other") and writes
    them into the Custom rubric section of `.harness/decision-rubric.md`.
12. The skill is **idempotent**: choosing the already-active mode is a clean no-op (no write, reported as
    "already Mode N").
13. The skill is **non-destructive and git-clean-gated**: refuses on a dirty working tree (so `git reset`
    is a full rollback), modeled on `/harness-language` step 1.
14. The skill `description:` frontmatter meets rule 15 P1: concrete EN + 中文 triggers including
    "switch decision mode" / "切换决策模式" / "让 AI 自己拿主意" / "改成人工决策", plus a *when-NOT* delta
    vs sibling skills.
15. The SKILL.md contains a **"When NOT to invoke"** surface and an **"Anti-patterns"** section
    (rule 15 P3).
16. SKILL.md stays within doc-size discipline (rule 70 — no numeric cap on SKILL.md specifically, but
    progressive-disclosure / no-bloat applies; keep it comparable to `/harness-language`'s ~215 lines).

### C. Ship the policy mechanism to generated projects (generic)

17. `skills/harness-init/templates/common/.harness/rules/25-decision-policy.md` is added — same structure
    as dogfood, but its **Active mode defaults to 1**.
18. `skills/harness-init/templates/common/.harness/decision-rubric.md` is added with the same two-section
    structure (`## Preset rubric (Mode 2)` + `## Custom rubric (Mode 3)`).
19. **CRITICAL correctness boundary:** the SHIPPED Preset rubric contains ONLY generic, universal defaults:
    the three prime principles + universally-safe defaults (reversible+in-scope → just do it; match
    existing conventions; honest reporting / no fabricated results; verify before declaring done;
    profile before optimizing). It MUST NOT contain any operator-personal line — specifically NOT:
    "lightweight over heavy", "design out the root cause / don't accrete guards", "chat replies in
    Chinese", "operator has standing commit+push authorization", or any harness-kit-repo-specific
    reference (verify_all, dogfood, this repo's English policy).
20. The shipped Custom rubric (Mode 3) section starts EMPTY (one-line author instruction only).
21. The shipped templates contain NO `{{placeholder}}` tokens that `harness-init` does not substitute
    (rule 10 #10; test-init's no-unresolved-placeholder scan must stay green). The two new files are plain
    `.md` (not `.tmpl`) unless a placeholder is genuinely required — decision deferred to SA, but the
    default expectation is plain `.md` with no placeholders.
22. The **template AI-GUIDE** (`skills/harness-init/templates/common/AI-GUIDE.md.tmpl` or its equivalent)
    indexes the new `25-decision-policy.md` rule and surfaces `decision-rubric.md` in the template's
    memory layer, so a generated project's AI-GUIDE↔rules bidirectional index (E.4b analogue) is complete.
23. The skill does NOT go into `templates/` — it is a plugin skill consumed via the installed plugin.

### D. Full release fan-out (each is an AC for Gate/CR/QA to verify)

24. `.claude-plugin/plugin.json` `version`: `0.27.0` → `0.28.0`.
25. `marketplace.json` version field → `0.28.0` (matching G.3).
26. `README.md`: version badge `0.27.0` → `0.28.0`; the `14 skills` / `fourteen` claims → `15` /
    `fifteen`; a new skill bullet for `/harness-kit:harness-decision-mode` under the appropriate group
    (Setup or Operations — SA decides placement); any test badges that move (verify_all / test-init
    counts) updated to the post-change values.
27. `README.zh-CN.md`: the same skill-list addition, `14`/十四 → `15`/十五 count claims, version badge,
    and any moved test badges — mirrored from `README.md`.
28. `CHANGELOG.md`: a new `## [0.28.0]` section (above the prior top entry) describing the feature; it must
    contain the literal token `harness-decision-mode` (G.2 requires every skill name to appear in
    CHANGELOG) and note the skill-count 14 → 15 and version bump.
29. `install.ps1` AND `install.sh`: `harness-decision-mode` added to the `$skills` / `skills=(...)` array,
    symmetrically (rule 30 #20). *(Note: the array currently lists 12 skills and is missing
    `harness-language` + `harness-upgrade` — see OQ-1; minimally, append `harness-decision-mode`.)*
30. `AI-GUIDE.md` (dogfood): a "Workflow entry" / skill row for the new skill (the `25-decision-policy`
    rule line is already present at AI-GUIDE.md:26 from the prior session — verify and leave intact).
31. `docs/dev-map.md`: the new skill listed in the skills tree + the decision-policy assets
    (`25-decision-policy.md`, `decision-rubric.md`, and their template copies) listed.
32. `.harness/scripts/verify_all.{ps1,sh}`: the C.1, G.1, G.2 skill-enumeration loops gain
    `harness-decision-mode`, and their label strings `"All 14 skills present"` /
    `"references all 14 skills"` become `15` (6 loop edits + 6 label edits across 2 shells — SA produces
    the exact ledger). This is a **count claim, hence version-worthy** (insight L24) — already covered by
    the 0.28.0 bump.
33. `test-init.{ps1,sh}` + `baseline.json`: extended ONLY if test-init asserts the shipped `.harness/rules/`
    set or a skill count, or if the new template files move a counted asset (SA determines; if a presence
    assertion for the two new template files is warranted, add it symmetrically and reconcile baseline).
34. Any other surface enumerating skills or counts that `verify_all` does not gate but that drifts
    (e.g. `docs/manual-e2e-test.md` "14 skills", `.harness/rules/40-locations.md:30` "All 14 skills") is
    updated to 15 — SA produces the exhaustive count-claim ledger (this is the project's #1 recurring
    failure surface, insight L24/L5; T-014's §11 ledger is the template).

## 3. Out-of-scope

- O-1. **Git commit / push / release tag** — explicitly the operator's (HARD CONSTRAINT #1; red line #2 of
  the very policy shipped). Sub-agents leave a green tree.
- O-2. **Fixing the pre-existing missing `harness-language` + `harness-upgrade` entries in the install
  scripts' skill array** beyond what's needed — this is a latent bug unrelated to T-018; scope-expansion
  red line says don't invent it. (Surfaced as OQ-1 for a user ruling; default = add only
  `harness-decision-mode`.)
- O-3. **Deep per-agent rubric integration** (teaching every pipeline agent's contract to be rubric-aware)
  — explicitly deferred by `25-decision-policy.md` "Scope of this version"; not part of T-018.
- O-4. **Mode-3 custom-rubric content authoring beyond capture** — the skill writes whatever prompts the
  user supplies; it does not validate, curate, or interpret them.
- O-5. **Translating the shipped policy/rubric to other languages** — the zh overlay's policy handling is
  `/harness-language`'s domain; T-018 ships the English canonical policy/rubric to `common/` only.
  (See OQ-2.)
- O-6. **A new `verify_all` CHECK** dedicated to the policy assets — not requested; rule 15 P6 + operator
  preference say don't add a guard unless it prevents a concrete hazard. (C.1/G.x label/count edits are
  modifications of existing checks, not a new check; check count stays 32.)

## 4. Boundary conditions

- BC-1. **Empty / missing Custom rubric** on a Mode-3 switch → collect prompts and write them (AC-11).
- BC-2. **Non-empty Custom rubric** on a Mode-3 switch → do NOT clobber it; SA decides whether to offer
  append/replace or just leave it (see OQ-3). Default expectation: leave existing content, switch the mode.
- BC-3. **Already-active mode chosen** → no-op, report "already Mode N" (AC-12).
- BC-4. **Dirty git tree** → refuse with a "commit or stash first" message; change nothing (AC-13).
- BC-5. **Hand-mangled / missing "Active mode" line** in `25-decision-policy.md` → the skill must not
  silently corrupt the file; surface a conflict and ask (modeled on `/harness-language` exit-2
  section-conflict). SA specifies the recognizer.
- BC-6. **Missing `25-decision-policy.md` entirely** (old project that predates this policy) → SA decides:
  either self-bootstrap from the plugin template (like `/harness-language`) or halt with a pointer to
  `/harness-upgrade`. (See OQ-4.)
- BC-7. **Mode value out of {1,2,3}** never written — the AskUserQuestion choices are the only inputs.

## 5. Acceptance criteria

Each maps to in-scope items; all are operator-verifiable (sub-agents have no Bash → the run gate is
operator-run, marked **[operator-run]**).

- AC-1. `25-decision-policy.md` (dogfood + template) defines Mode 3 and states red-lines + audit-trail
  apply to all three modes. (Items 1-3, 17.)
- AC-2. `decision-rubric.md` (dogfood + template) has exactly the two sections `## Preset rubric (Mode 2)`
  and `## Custom rubric (Mode 3)`. (Items 4, 18.)
- AC-3. Dogfood Preset = existing personal prefs verbatim; dogfood Custom empty; dogfood Active mode = 2.
  (Items 5-7.)
- AC-4. **Shipped Preset is generic** — a reviewer grep of the template `decision-rubric.md` finds NONE of
  the banned operator-personal phrases (item 19's list); shipped Active mode = 1; shipped Custom empty.
  (Items 17, 19, 20.) **This is the highest-risk correctness boundary.**
- AC-5. `skills/harness-decision-mode/SKILL.md` exists, has a rule-15-compliant `description:` (EN+中文
  triggers, when-NOT delta), a "When NOT to invoke" section, an "Anti-patterns" section, and documents the
  single-line surgical Active-mode rewrite + Mode-3 capture flow. (Items 8-16.)
- AC-6. Skill flow is idempotent (no-op on same mode), git-clean-gated, non-destructive, and never edits
  any byte other than the Active-mode line (+ the Custom rubric section on a Mode-3 capture). (Items 9-13.)
- AC-7. Template AI-GUIDE indexes `25-decision-policy.md` + surfaces `decision-rubric.md`; a generated
  project's AI-GUIDE↔rules index check passes. **[operator-run via test-init]** (Item 22.)
- AC-8. `plugin.json` + `marketplace.json` + both READMEs' version badges all read `0.28.0`
  (verify_all **G.3** PASS). **[operator-run]** (Items 24-27.)
- AC-9. Both READMEs list `/harness-decision-mode` and claim `15` / `fifteen` (+十五) skills; CHANGELOG has
  a `[0.28.0]` section containing `harness-decision-mode`. (Items 26-28.)
- AC-10. `verify_all` **C.1 / G.1 / G.2** reference all **15** skills (loop + label) and PASS; **G.4**
  (claim↔version consistency) PASSes. **[operator-run]** (Items 32, 34.)
- AC-11. `install.ps1` and `install.sh` both include `harness-decision-mode` in the skill array (symmetric).
  verify_all **F.1** (ps/sh symmetry) PASS. **[operator-run]** (Item 29.)
- AC-12. `docs/dev-map.md` lists the new skill + decision-policy assets. (Item 31.)
- AC-13. **[operator-run] gate:** `bash .harness/scripts/verify_all.sh` = 32 PASS / 0 WARN / 0 FAIL;
  if templates changed, `bash .harness/scripts/test-init.sh` green; PowerShell twins equivalent.
- AC-14. **Green git tree** at hand-off — no commit, no tag (HARD CONSTRAINT #1).

## 6. Non-functional requirements

- NFR-1. **PS/SH symmetry** — any `.ps1` edited (install, verify_all, test-init) has its `.sh` twin edited
  to equivalent behavior (rule 30 #20; verify_all F.1). If SA introduces a `decision-mode.{ps1,sh}` helper
  pair, byte-identical cross-shell output is required where it writes files (insight L29/T-014).
- NFR-2. **Doc-size caps (rule 70):** new rule `25-decision-policy.md` ≤ 200 lines (both copies);
  `AI-GUIDE.md` ≤ 200 lines after edit; `dev-map`, README within their existing budgets. `decision-rubric.md`
  has no explicit cap but stays lean.
- NFR-3. **No new placeholder** introduced without registering it in `harness-init/SKILL.md` + the D.2
  whitelist in both verify_all shells (rule 10 #10). Default: introduce none.
- NFR-4. **Self-consistency (rule 10):** the new template RULE + rubric are bespoke (NOT in sync-self's
  mirror set) → no `sync-self` needed for them. The new SKILL is a plugin skill under top-level `skills/`;
  it reaches `.claude/skills/` via `harness-sync` (E.2) — SA confirms whether dogfood `.claude/skills/`
  must contain it for E.2 to pass, OR whether plugin skills live only in `skills/`. **[SA must resolve —
  see OQ-5.]**
- NFR-5. **No I.6 self-trip:** no new banned-claim is retired by T-018, so the I.6 four-file lockstep is
  NOT touched (insight L30 — confirm net-new, no retired claim). Any doc text written must avoid existing
  I.6 banned anchors (insight L31). SA/Dev confirm.

## 7. Related tasks

- **T-014 `/harness-language`** (`docs/features/_archived/harness-language-skill/`) — THE precedent for
  adding a skill: the surgical single-line/section rewrite + git-clean gate + dry-run + `.bak` flow
  (`skills/harness-language/SKILL.md`), and the complete release fan-out ledger
  (`02_SOLUTION_DESIGN.md` §11, lines ~485-500: README/AI-GUIDE/manual-e2e/40-locations count fan-out;
  install scripts; G.3/G.4). SA should mirror that ledger's shape.
- **T-013 `lang-policy-split`** — the prior structural split of a policy doc; precedent for two-section
  delimitation.
- **T-006 `harness-batch-skill`** — first "add a skill" task; the skill-count-drift rollback (M-1) that
  established the count fan-out as the #1 recurring failure.
- **T-016 `i18n-special-drift-guard`** — operator preference "design out the root cause; don't accrete
  guards" (feedback_design_over_guards) — relevant to O-6 (no new check).

## 8. Open questions for user

> The INPUT brief is highly prescriptive; these are the genuine residual ambiguities. Defaults are proposed
> so the pipeline can proceed under Mode-2 dogfood autonomy if the user does not object — but each carries a
> material-enough choice to record.

1. **OQ-1 (install-script array):** the install scripts' skill array currently lists only 12 skills,
   missing `harness-language` and `harness-upgrade`. Do we (a) append ONLY `harness-decision-mode` (minimal,
   in-scope, leaves the pre-existing gap), or (b) also add the two missing ones (fixes a latent bug, but is
   scope expansion)? **Default: (a)** — stay in scope; note the gap for a future task.
2. **OQ-2 (zh template policy):** the brief ships the policy/rubric to `common/` (English). Should a
   Chinese version also ship in the `i18n/zh/` overlay now, or is zh handling deferred to a follow-up like
   the existing language model? **Default: defer** — ship English `common/` only; the policy prose is
   AI-facing scaffolding (English by the v0.26 model), so no zh overlay copy is needed.
3. **OQ-3 (Mode-3 on a NON-empty Custom rubric):** when switching to Mode 3 and the Custom section already
   has content, should the skill (a) leave it and just switch the mode, (b) offer append, or (c) offer
   replace? **Default: (a)** leave + switch; only auto-capture when empty (per the brief's "if … empty").
4. **OQ-4 (skill on a project with NO `25-decision-policy.md`):** old projects predating this policy won't
   have the file. Should the skill (a) self-bootstrap the policy from the plugin template (like
   `/harness-language`), or (b) halt and point at `/harness-upgrade`? **Default: (b)** halt + point at
   `/harness-upgrade` — keeps the skill's scope to "switch an existing policy's mode"; bootstrapping a whole
   policy file is upgrade territory. (SA may refine.)
5. **OQ-5 (plugin-skill binding):** does the dogfood `.claude/skills/` need a copy of
   `harness-decision-mode` for verify_all E.2 to pass, or do plugin skills live only under top-level
   `skills/`? This is a mechanical self-consistency question SA must answer from the E.2 check + how the
   other 14 skills are bound. **No user input needed — SA resolves from the check.**

## 9. Verdict

**READY (with proposed defaults).**

Rationale: the brief is prescriptive enough that none of OQ-1…OQ-4 *blocks* design — each has a safe,
in-scope default that respects the HARD CONSTRAINTS (especially scope-expansion red line #3 and
generic-rubric constraint #2). OQ-5 is a mechanical question the Architect answers from the E.2 check, not a
user question. The Architect should adopt the proposed defaults unless the user (or a `/harness-intervene`
NOTE) overrides; any override on OQ-1/OQ-2 changes only the breadth of the fan-out, not the core design.

Recommend the PM advance to Stage 2 (Solution Architect) carrying these defaults; flag OQ-1 and OQ-2 to the
user at delivery as decisions taken, so they can reverse them into the live decision-rubric if desired.
