# 01 — Requirement Analysis · T-014 / harness-language-skill

> Stage 1 of the Harness pipeline. Mode: **full** (7-stage). Author: Requirement Analyst.
> Inputs (read-only): the PM dispatch intent (the request of record — no `INPUT.md` is present in the
> task folder), `docs/features/harness-language-skill/PM_LOG.md`, the actual current policy templates in
> both `templates/common/` (en) and `templates/i18n/zh/common/` (zh), `skills/harness-upgrade/SKILL.md`,
> `skills/harness-init/SKILL.md`, `.harness/insight-index.md`, and T-012 / T-013 archived stage docs.
> The PM-set design baseline is treated as binding and is **refined, not overturned**, below.

---

## 1. Goal

Ship a dedicated `/harness-language [en|zh]` skill that lets any harness-initialized project — especially
an already-initialized OLD one — set, switch (en↔zh), or refresh its project-level output-language policy
by surgically rewriting only the three policy-bearing files to the target language's current canonical
policy text, non-destructively and idempotently.

---

## 2. Verified facts (PM context, re-confirmed against the live tree — read before the requirements)

These are confirmations the PM asked for; they pin the requirements below.

- **F-1. The canonical policy text lives in 3 file pairs per language**, fully resolved (no `{{LANG}}`
  inside the prose — `{{LANG}}` only *selects the overlay* at init time, it is not embedded in the policy
  text):
  - `00-core.md` policy SECTION — en: `templates/common/.harness/rules/00-core.md.tmpl`
    (heading `## Output language (project-wide)`); zh: `templates/i18n/zh/common/.harness/rules/00-core.md.tmpl`
    (heading `## 输出语言（按消费者分流）`).
  - `CLAUDE.md` top policy LINE — en: `templates/common/CLAUDE.md.tmpl` line `Output language: **English**.`;
    zh: `templates/i18n/zh/common/CLAUDE.md.tmpl` line `输出语言：面向人的产出…用**中文**…面向 agent/LLM…用**英文**…`.
  - `.github/copilot-instructions.md` top policy LINE — en: `templates/common/.github/copilot-instructions.md.tmpl`;
    zh: `templates/i18n/zh/common/.github/copilot-instructions.md.tmpl`. (Same prose as the `CLAUDE.md` line per language.)
- **F-2. There are NO section delimiters/markers today.** `00-core.md.tmpl` contains no
  `HARNESS:`-style begin/end markers and no HTML comments around the policy section (confirmed: zero
  matches). The section is delimited only by markdown headings: it begins at the `## Output language …`
  / `## 输出语言…` heading and ends at the next `##` heading (`## How this project is developed` /
  `## 这个项目怎么开发`). The en and zh headings DIFFER, so "locate by exact heading string" is
  language-specific.
- **F-3. The en policy is single-language** (everything English); the zh policy is the **T-013 three-way
  split** (chat→ZH, AI-facing artifacts→EN, human-facing artifacts→ZH). These are the two target states.
- **F-4. There is no persisted `PROJECT_LANG` marker** in a generated project (same class as
  /harness-upgrade's no-persisted-type problem). Current language is only inferrable from the prose/heading
  of the existing policy files.
- **F-5. The C.1/C.2/G.1/G.2 skill list in `verify_all.{ps1,sh}` is a hard-coded enumeration** of 13 skill
  names (`harness … harness-upgrade`); a 14th skill is added there + every "13 skills" claim flips to "14".
- **F-6. The dogfood repo's own `.harness/rules/00-core.md` does NOT have this policy section structure**
  (its headings are `## Project type`, etc.). The command targets the *generated-project* structure, not
  this repo. Running it against the dogfood repo is out of scope (red line).

---

## 3. In-scope behaviors (numbered, testable; no "should/maybe/could")

1. The skill is invoked as `/harness-language en`, `/harness-language zh`, or `/harness-language` (no arg).
2. `/harness-language en` sets the project's policy to the **canonical English single-language policy**:
   it replaces the `00-core.md` policy section, the `CLAUDE.md` top policy line, and the
   `.github/copilot-instructions.md` top policy line with the en canonical text (F-1, en).
3. `/harness-language zh` sets the project's policy to the **canonical Chinese three-way-split policy**:
   it replaces the same three locations with the zh canonical text (F-1, zh).
4. `/harness-language` (no arg) **refreshes** the project's CURRENT language to the latest canonical text:
   it detects the current language (per requirement 9), and rewrites the same three locations to that same
   language's current canonical text (idempotent if already current).
5. The skill rewrites **only** the three policy-bearing locations (F-1). It changes nothing else in the
   project — no other file, no other section of `00-core.md`, no other line of `CLAUDE.md`.
6. The `00-core.md` policy section is replaced **as a whole section** — the span from the policy heading up
   to (but not including) the next `##` heading is the unit replaced (per the locating mechanism resolved
   in OQ-1). On a zh→en switch the zh `## 输出语言…` section (heading included) is replaced by the en
   `## Output language …` section; on en→zh the reverse. After replacement, exactly one policy section and
   one policy heading exist in `00-core.md`.
7. The skill is **self-bootstrapping**: it pulls the current canonical policy text from the plugin template
   cache (the same discovery chain /harness-upgrade uses), and does NOT depend on the canonical text
   pre-existing in the project. It reuses the existing policy templates + the `{{LANG}}` overlay selection
   mechanism — it does NOT introduce a second source of policy text.
8. The skill shows a **dry-run preview** of every planned change (which files, which sections, target
   language) and obtains an explicit user "yes" before applying (mirrors /harness-upgrade's plan→confirm→apply).
9. The skill **detects the project's current language** by a defined inference order and **confirms via
   `AskUserQuestion`** (pre-filled) before acting; it never silently guesses (inference order resolved in OQ-2).
10. Before editing any of the three files, the skill writes a timestamped `.bak` of that file.
11. The operation is **idempotent**: a second invocation with the same target on an already-current project
    makes no content change, writes no `.bak`, and reports "already current / nothing to do".
12. The operation is **non-destructive**: it preserves the rest of each file byte-for-byte; only the policy
    section/line changes.
13. `/harness-upgrade`'s end-of-run summary gains **one hint line** stating that `/harness-language` can
    refresh the language policy (hint only — no automatic cross-command invocation) (confirmed in OQ-4).
14. The new skill is registered: `skills/harness-language/SKILL.md` is created with valid frontmatter, and
    the skill is added to the version/count fan-out (F-5; see §11 obligations).

---

## 4. Out-of-scope (explicitly NOT this iteration)

1. **Whole-project content translation.** The command does not translate any prose other than the three
   policy locations. Translating docs, READMEs, agent files, or task docs is a larger separate follow-up.
2. **The i18n/zh overlay's OTHER files** (`AI-GUIDE.md.tmpl`, `docs/workflow.md`, `05-insight-index.md.tmpl`,
   the rule fragments other than the `00-core.md` policy section, etc.) are not touched. (This is T-013's
   deferred (B) "template-language" reclassification — still deferred.)
3. **harness-kit's own dogfood repo** is not a target (F-6; red line — never hand-edit the dogfood
   `CLAUDE.md` / `00-core.md`).
4. **New language overlays beyond en/zh** (`ja`, `fr`, …). The command accepts only `en` and `zh`.
5. **A new persisted `PROJECT_LANG` marker / new `{{...}}` placeholder** (default NO — see OQ-3; flagged as
   a D.2-churn avoidance per insight L11).
6. **Retroactive policy changes to files the command does not own** (e.g. partition `50-<type>.md` rules,
   per-task docs already written in a project).
7. **Migrating the v0.1.x → v0.2.0 `CLAUDE.md`→rules split**, or adopting harness into a no-harness project
   (that is `/harness-adopt`).

---

## 5. Boundary conditions (null / empty / max / concurrency / error paths)

1. **No-arg + ambiguous current language** — if detection (requirement 9) cannot determine the current
   language with confidence, the skill asks via `AskUserQuestion` (no default applied silently); it never
   guesses.
2. **Invalid argument** — `/harness-language fr` (or any token ∉ {en, zh}) → halt with an actionable
   message ("only en|zh are supported"), change nothing.
3. **No harness setup present** — if the project has NEITHER `.harness/rules/00-core.md` NOR `CLAUDE.md`
   (the minimum that makes this command applicable), halt with an actionable message and change nothing
   (resolved in OQ-6).
4. **Partial policy surface** — exactly which of the three files exist varies (e.g. a Copilot-less project
   may lack `.github/copilot-instructions.md`). The skill rewrites every policy file that EXISTS and
   reports each missing one as a skipped/absent surface; a missing file is not an error.
5. **Policy section absent in `00-core.md`** — if `00-core.md` exists but has no recognizable policy
   section (neither heading), the skill surfaces this as a conflict and asks the user whether to insert the
   canonical section (default: do not auto-insert without confirmation; resolved in OQ-5).
6. **Already-target idempotence** — running `en` on an en project (or `zh` on a zh project) is a clean
   no-op (requirement 11): no write, no `.bak`.
7. **Template cache not locatable** — if the plugin template cache cannot be resolved (the /harness-upgrade
   discovery chain all misses), halt with an actionable message ("could not locate the harness-kit plugin
   template cache; reinstall the plugin") and change nothing — the skill is self-bootstrapping but never
   fabricates policy text.
8. **Dirty / non-git working tree** — precondition gate resolved in OQ-7 (default: mirror /harness-upgrade
   — git repo required + clean tree, so `git reset` is the rollback path; `.bak` covers untracked surfaces).
9. **CJK / encoding** — the zh policy text contains CJK; every file the skill writes is UTF-8. Any new
   helper or test that scans/writes policy text follows the cross-shell CJK rules (insight L25/L38: no
   `grep -F -i` on MSYS; UTF-8 save).
10. **Concurrency** — single-shot interactive command; no concurrency contract beyond "do not run two
    instances against the same tree simultaneously" (out of practical scope — not enforced).
11. **Max size / doc cap** — the replacement keeps `00-core.md` within the I.* doc-size WARN cap (the
    canonical section is concise; the Architect sizes it).
12. **Self-trip avoidance (insight L38 / I.6)** — any SKILL.md / doc text that DESCRIBES the retired blunt
    all-Chinese phrasing must not write the literal banned anchor sequence (the T-013 verify_all I.6 zh
    banned-line), or the gate self-trips. Describe it in English / paraphrase.

---

## 6. Acceptance criteria (verifiable on a real generated project)

Each AC is observable on a fixture project produced by `/harness-init` (en or zh), or via a test driver.

- **AC-1 — zh→en switch.** On a project initialized with `{{LANG}}=zh`, running `/harness-language en`
  replaces the `## 输出语言…` three-way-split section in `00-core.md` with the en `## Output language
  (project-wide)` single-language section, replaces the `CLAUDE.md` top line `输出语言：…` with
  `Output language: **English**.`, replaces the `.github/copilot-instructions.md` top line symmetrically,
  and writes a `.bak` for each edited file.
- **AC-2 — idempotence of the switch.** Running `/harness-language en` a SECOND time on the now-en project
  makes no content change and writes no new `.bak` ("already current").
- **AC-3 — en→zh switch.** On a project initialized with `{{LANG}}=en`, running `/harness-language zh`
  installs the zh three-way-split section / lines into all three present files and writes `.bak`s; a second
  run is a clean no-op.
- **AC-4 — no-arg refresh.** On a zh project whose policy text is STALE (e.g. the pre-T-013 blunt
  all-Chinese policy), running `/harness-language` (no arg) detects zh, confirms via `AskUserQuestion`, and
  rewrites the three locations to the CURRENT canonical zh three-way-split text; on an already-current
  project it is a no-op.
- **AC-5 — surgical scope.** After any of AC-1/AC-3/AC-4, a diff of the project shows changes ONLY within
  the policy section of `00-core.md` and the single policy line of `CLAUDE.md` /
  `copilot-instructions.md` — every other byte of every file is unchanged.
- **AC-6 — single section invariant.** After a switch, `00-core.md` contains exactly one policy heading and
  one policy section (no duplicate/orphaned old-language section left behind).
- **AC-7 — detect-then-confirm, no silent guess.** With detection ambiguous (boundary 1) or with `00-core.md`
  policy section absent (boundary 5), the skill asks via `AskUserQuestion` and does not write without an
  explicit answer.
- **AC-8 — missing surface tolerated.** On a project lacking `.github/copilot-instructions.md`, the skill
  rewrites `00-core.md` + `CLAUDE.md`, reports the copilot file as absent/skipped, and exits success.
- **AC-9 — precondition gates.** On a non-git tree (and, per OQ-7 default, a dirty tree), the skill halts
  with the gate message and changes nothing; on a project with no `00-core.md` AND no `CLAUDE.md` it halts
  pointing the user at init/adopt.
- **AC-10 — self-bootstrap.** On a stale project that does NOT contain the canonical policy text anywhere,
  the skill still produces the correct target text (sourced from the plugin template cache), proving it
  does not depend on the text pre-existing in the project.
- **AC-11 — /harness-upgrade hint.** `/harness-upgrade`'s end-of-run summary contains exactly one line
  mentioning `/harness-language` as the way to refresh the language policy (no auto-invocation).
- **AC-12 — gate green + fan-out.** `verify_all` PASSes on the harness-kit repo with the skill count
  advanced 13→14 across all claim surfaces (F-5, §11), CHANGELOG updated, version bumped per G.3/G.4; if a
  helper script is introduced it is PS+Bash symmetric and passes both shells; `test-init` stays green.
- **AC-13 — no new placeholder (default).** `verify_all` D.2 placeholder whitelist is unchanged (no new
  `{{...}}`), unless OQ-3 resolves to add a persisted marker.

---

## 7. Non-functional requirements (only the material ones)

- **NFR-1 — cross-platform symmetry.** If a deterministic helper script is introduced (mirroring
  /harness-upgrade's `upgrade-project.{ps1,sh}` two-layer pattern), it ships as a PS+Bash pair with
  byte-identical behavior and passes both shells; any added test assertion is symmetric (insight L36:
  cross-shell file-writing pairs must match on trailing newline).
- **NFR-2 — idempotence & non-destructiveness** are correctness NFRs (mirrors /harness-upgrade): a second
  run is a clean no-op; a `.bak` precedes every edit; the rest of each file is preserved byte-for-byte.
- **NFR-3 — UTF-8 / CJK safety.** All written files are UTF-8; the zh policy text round-trips without
  mojibake; no `grep -F -i` on MSYS (insight L25).
- **NFR-4 — doc-size.** The rewritten `00-core.md` stays under the I.* WARN cap.

---

## 8. Related tasks (linked, not re-described)

- **T-012 / harness-upgrade-skill** — `docs/features/_archived/harness-upgrade-skill/`. The closest
  precedent: skill+helper two-layer structure, plugin-template-cache self-bootstrap/discovery chain,
  dry-run→confirm→apply, `.bak`, precondition gates (git repo + clean tree), exit-code/stdout contract,
  "surface verify_all verbatim". **Mirror this structure.** Read `skills/harness-upgrade/SKILL.md`.
- **T-013 / lang-policy-split** — `docs/features/_archived/lang-policy-split/`. Defined the current zh
  three-way-split canonical policy text (the `zh` target state) and the en single-language policy (the `en`
  target state); added the verify_all I.6 banned-line for the retired blunt-Chinese phrasing (self-trip
  hazard, insight L38). This task consumes T-013's output as its canonical source and explicitly carries
  T-013's deferred "old projects can't pull the new policy" gap.
- **T-006 / harness-batch-skill** + **T-011 / ambient-stream** — prior new-skill ships; precedent for the
  skill-count fan-out (12→13, 13→14) and the G.3/G.4 version/claim consistency obligations.
- **T-008 / test-supervisor-stamps** + **T-010 / g4-version-decouple** — the G.3/G.4 gates AC-12 keeps green.

---

## 9. Open questions for the user (each with ≥2 candidates + a recommended default)

> Verdict is gated on these. Defaults are attached so the PM can approve-by-default and advance fast. OQ-1
> (section-locating mechanism) and OQ-2 (detection order) are the load-bearing design forks the SA needs
> settled.

**OQ-1 — How is the `00-core.md` policy section located + replaced idempotently?** (F-2: no markers exist
today; the en/zh headings differ.)
- (a) **Heading-anchor matching (recommended default).** Locate the section as "from the line matching
  either canonical policy heading (`## Output language (project-wide)` OR `## 输出语言…`) up to the next
  `## ` heading", and replace that whole span. No template/format change ships; works on already-generated
  OLD projects immediately (their files have the heading, not markers). Risk: a hand-edited heading defeats
  the match → falls through to the AskUserQuestion conflict path (boundary 5).
- (b) Introduce stable `HARNESS:LANG-POLICY:BEGIN/END` markers (T-013 `HARNESS:B-CUSTOM` style) into the
  `00-core.md.tmpl` policy section. Cleaner long-term anchor, but markers are ABSENT from every
  already-generated old project (the exact projects this skill targets), so the skill would still need a
  heading-anchor fallback for old projects — net more complexity for this iteration. Recommend deferring
  markers.
- (c) Replace by whole-file regeneration of `00-core.md` from the template — rejected (would clobber the
  user's bespoke edits to other sections of `00-core.md`; violates "surgical").

**OQ-2 — Current-language detection inference order (for no-arg refresh + the pre-filled confirm).**
- (a) **Recommended order:** (1) `00-core.md` policy heading/prose language → (2) `CLAUDE.md` top
  `Output language:` / `输出语言：` line → (3) `.github/copilot-instructions.md` top line. First confident
  hit wins; on conflict between sources or no hit, ASK (never guess). Always confirm via AskUserQuestion
  pre-filled with the inferred value.
- (b) Reverse priority (CLAUDE.md first) — less reliable because `CLAUDE.md` is a one-line stub while
  `00-core.md` is the authoritative policy section.
- (c) Always ASK regardless of inference — safe but adds friction to the common refresh case; (a) keeps the
  confirm but pre-fills it.

**OQ-3 — Persist a `PROJECT_LANG` marker / new `{{...}}` placeholder?**
- (a) **No new marker / no new placeholder (recommended default).** Rely on inference+confirm (OQ-2); keeps
  D.2 whitelist untouched (insight L11) and avoids the 4-place fan-out a new placeholder forces. Detection
  is reliable from the existing policy prose.
- (b) Persist a marker (e.g. a comment line or a `.harness/` metadata file) so future runs skip inference.
  Adds a new surface to keep consistent + (if a `{{...}}`) a D.2 + verify_all edit in both shells. Flag
  only if the user wants deterministic re-detection without ever asking.

**OQ-4 — /harness-upgrade end-of-run hint line: add it?**
- (a) **Yes — add ONE hint line, no auto-invocation (recommended default).** Surfaces the new capability to
  exactly the audience (people upgrading old projects) without coupling the two commands.
- (b) No hint — keep /harness-upgrade unchanged; users discover `/harness-language` independently.

**OQ-5 — `00-core.md` exists but has NO recognizable policy section (boundary 5): auto-insert or ask?**
- (a) **Ask via AskUserQuestion before inserting (recommended default).** Never silently mutate an
  unexpected structure; offer to insert the canonical section at the documented location on "yes".
- (b) Auto-insert at the top — rejected as a default (silent structural mutation of a file the skill did
  not author).
- (c) Halt with a message and change nothing — safe but less helpful than (a)'s confirm-then-insert.

**OQ-6 — Minimum "this project has harness setup" precondition for the command to apply.**
- (a) **Require at least one of `.harness/rules/00-core.md` OR `CLAUDE.md` to exist (recommended default).**
  These are the policy-bearing surfaces; if neither exists the command has nothing to operate on → halt and
  point at `/harness-init` (empty project) or `/harness-adopt` (no-harness project).
- (b) Require the FULL /harness-upgrade precondition set (`.claude/settings.json` OR `.harness/` OR a
  scripts dir) — broader than needed; the language command only needs the policy files.

**OQ-7 — Precondition/safety gates: mirror /harness-upgrade exactly?**
- (a) **Yes — git repo required + clean working tree required + `.bak` before each edit (recommended
  default).** Clean tree gives a `git reset` rollback path; `.bak` covers untracked surfaces; consistent
  with the sibling command.
- (b) Looser — git repo required but allow a dirty tree (rely on `.bak` alone). Smaller friction for a
  quick refresh, but loses the `git reset` rollback guarantee on tracked files; recommend (a) for parity
  and safety.

---

## 10. Verdict

**BLOCKED ON USER** — seven open questions (OQ-1 … OQ-7) remain, of which **OQ-1 (section-locating
mechanism)** and **OQ-2 (detection inference order)** are the load-bearing forks the Solution Architect
needs settled before design. Every question carries a recommended default; if the PM approves all seven
defaults the requirement collapses to: *a `/harness-language [en|zh]` skill that locates the policy section
by canonical-heading anchor, detects current language from `00-core.md`→`CLAUDE.md`→copilot (confirm,
never guess), self-bootstraps the canonical text from the plugin template cache, dry-run→confirm→apply with
a `.bak` per file, idempotent, non-destructive, no new placeholder, git-repo+clean-tree gated; plus a
one-line /harness-upgrade hint.* The PM may approve-by-default and advance to the Solution Architect, or
route the forks to the user.

---

## 11. Downstream obligations the Architect / Developer must carry (flagged, not designed here)

- **O-1 — skill-count fan-out (F-5).** A new 14th skill flips every "13 skills / thirteen / 13 个" claim to
  "14": the hard-coded skill loop in `verify_all.{ps1,sh}` C.1 (+ the C.2 frontmatter loop, G.1 README, G.2
  CHANGELOG enumerations), `README.md` / `README.zh-CN.md` (badge stays version-gated; count + "thirteen"),
  `AI-GUIDE.md` ("distributes 13 skills"), `.harness/rules/40-locations.md` ("All 13 skills"),
  `docs/getting-started.md`, `docs/manual-e2e-test.md` (three "13 skills"/"thirteen" enumerations + the
  command list), and the marketplace/plugin registration. This is a G.3/G.4-gated, version-worthy change.
- **O-2 — version bump (insight L33 / G.4).** Shipping a new skill is releasable: bump `plugin.json` +
  CHANGELOG + every count/version claim, or G.3/G.4 FAIL at the gate.
- **O-3 — I.6 self-trip trap (insight L38 / I.6).** Any SKILL.md/doc/insight text that references the
  retired blunt all-Chinese phrasing must NOT write the literal banned anchor (the T-013 zh I.6 banned-line)
  — paraphrase or use English, or `verify_all` I.6 self-trips (this exact failure hit T-013's own delivery).
- **O-4 — no new `{{...}}` placeholder (default; insight L11).** Keep D.2 untouched unless OQ-3 → (b); if a
  placeholder is added it goes in BOTH `verify_all.ps1` and `.sh` D.2 whitelists (case-sensitive `-ccontains`).
- **O-5 — helper two-layer + cross-shell parity (NFR-1, insight L36).** If a deterministic helper is
  introduced, it mirrors `upgrade-project.{ps1,sh}` (skill = judgment, helper = mechanical), goes into the
  `sync-self` mirror set if it ships into templates, and matches byte-for-byte across shells (trailing-newline
  parity). A helper that ships into generated projects and must name `{{LANG}}` for its own substitution
  cannot contain the literal `{{LANG}}` (test-init scan) — assemble the token from pieces (insight L35).
- **O-6 — test-init impact (likely none).** This skill does not change `templates/` policy CONTENT (T-013
  already shipped it); it adds a NEW skill that consumes the existing templates. `test-init` stays green
  unless a template file is modified. A new regression for the language command itself is a Developer/QA
  scoping call (recommend a `test-language` driver paralleling `test-init`, decided at design).
- **O-7 — skill grouping in docs.** Register `/harness-language` under the same "Setup / project lifecycle"
  grouping as `/harness-init` / `/harness-adopt` / `/harness-upgrade` in README + getting-started + AI-GUIDE
  (where the workflow-mode table lives); the "six task shapes" framing for the *pipeline modes* is
  unaffected (this is a setup utility, not a pipeline mode).
