# 02 — Solution Design · T-014 / harness-language-skill

> Stage 2 of the Harness pipeline. Mode: **full** (7-stage). Author: Solution Architect.
> Inputs (read-only): `01_REQUIREMENT_ANALYSIS.md` (verdict **READY**), `PM_LOG.md` (all 7 OQs
> ACCEPTED — design to the resolved baseline, do not re-open), the live policy templates in both
> `templates/common/` (en) and `templates/i18n/zh/common/` (zh), `skills/harness-upgrade/SKILL.md`
> + `upgrade-project.sh` (the precedent to mirror), `.harness/insight-index.md`, the fan-out sites
> in `verify_all.{ps1,sh}` / README×2 / AI-GUIDE / getting-started / manual-e2e-test / 40-locations /
> CHANGELOG / plugin.json / marketplace.json.
> Single-developer mode (`.harness/agents/dev-*.md` absent → no partition table).

---

## 1. Architecture summary

Ship a 14th skill `skills/harness-language/SKILL.md` plus one deterministic helper pair
`templates/common/.harness/scripts/language-policy.{ps1,sh}` (mirroring the `/harness-upgrade`
skill+helper two-layer split). The skill is the **judgment layer** (cache discovery, current-language
detection, dry-run presentation, AskUserQuestion confirms, precondition gates); the helper is the
**mechanical layer** (locate the policy section by canonical heading anchor, replace it with the target
language's canonical text read from the resolved template cache, swap the one-line policy in
`CLAUDE.md` + `.github/copilot-instructions.md`, `.bak` per edited file, idempotent NOOP on byte-identity,
machine-readable pipe-delimited stdout). It targets a **generated** harness project from its own cwd
(not this dogfood repo — red line). No production code changes ship to the templates' policy CONTENT
(T-013 already shipped both target states); this task only adds a consumer of that text. Shipping a new
skill is releasable: skill count 13→14, version 0.24.0→0.25.0, fan-out across the proven T-012/T-013 sites;
`verify_all` stays **32 checks** (a new skill needs no new lettered `Step` — C.1/C.2/G.1/G.2 already
enumerate skills; F.1 gains the helper pair name-only).

---

## 2. Affected modules

### New (this repo)

| Path | Kind | Responsibility |
|---|---|---|
| `skills/harness-language/SKILL.md` | new skill | judgment layer for `/harness-language [en\|zh]` |
| `templates/common/.harness/scripts/language-policy.ps1` | new helper (template) | mechanical section/line replacement (PowerShell) |
| `templates/common/.harness/scripts/language-policy.sh` | new helper (template) | mechanical section/line replacement (bash mirror) |
| `.harness/scripts/language-policy.ps1` | new helper (dogfood mirror) | sync-self mirror of the template helper |
| `.harness/scripts/language-policy.sh` | new helper (dogfood mirror) | sync-self mirror of the template helper |
| `.harness/scripts/test-language.ps1` | new test (dogfood) | regression driver (PowerShell) |
| `.harness/scripts/test-language.sh` | new test (dogfood) | regression driver (bash mirror) |

### Edited (this repo — fan-out, see §11)

`skills/harness-upgrade/SKILL.md` (one hint line) · `verify_all.{ps1,sh}` (C.1/C.2/G.1/G.2 arrays + F.1
pair list) · `README.md` · `README.zh-CN.md` · `AI-GUIDE.md` · `docs/getting-started.md` ·
`docs/manual-e2e-test.md` · `.harness/rules/40-locations.md` · `CHANGELOG.md` · `.claude-plugin/plugin.json`
· `.claude-plugin/marketplace.json`.

### Read-only inputs (the canonical policy texts the command applies — NOT edited)

- en `00-core.md` section: `templates/common/.harness/rules/00-core.md.tmpl:9-22`.
- zh `00-core.md` section: `templates/i18n/zh/common/.harness/rules/00-core.md.tmpl:9-31`.
- en `CLAUDE.md` line: `templates/common/CLAUDE.md.tmpl:3`; zh: `templates/i18n/zh/common/CLAUDE.md.tmpl:3`.
- en copilot line: `templates/common/.github/copilot-instructions.md.tmpl:6`; zh:
  `templates/i18n/zh/common/.github/copilot-instructions.md.tmpl:6`.

---

## 3. Component decomposition — skill-only vs skill+helper

**Decision: skill + deterministic helper pair** (`language-policy.{ps1,sh}`). Not skill-only.

**Rationale (project principle: mechanical→script, judgment→AI; and the `/harness-upgrade` precedent):**

1. The replacement is **mechanical and byte-exact**: locate a heading, slice to the next `##` or EOF,
   substitute the canonical block, swap a one-line policy in two stubs, write a timestamped `.bak`,
   NOOP on byte-identity. `/harness-upgrade` factored the identical class of work into
   `upgrade-project.{ps1,sh}` and kept the AI out of "no path string-replacement, no settings byte-editing"
   (`skills/harness-upgrade/SKILL.md:22-24`). The same boundary applies here verbatim.
2. **Idempotence + cross-shell parity are correctness NFRs** (`01:NFR-1/NFR-2`). They are only provable when
   the transform is deterministic and runs identically in PS and bash — exactly what a helper pair plus a
   `test-language.{ps1,sh}` regression gives us. An AI inlining Edit calls cannot be regression-tested for
   byte-identity and risks L10 (Edit silently no-ops).
3. **CJK safety** (zh canonical text) demands a single UTF-8 write path with no `grep -F -i` on MSYS (L25).
   A helper encodes that once; AI-inline edits would re-derive it ad hoc each run.

The **judgment** stays in the skill: cache discovery + version fallback chain (judgment — "which version",
fallbacks), current-language detection inference + AskUserQuestion confirm, the hand-mangled/absent-section
conflict branch, dry-run presentation, and the git-repo + clean-tree gates. This mirrors
`skills/harness-upgrade/SKILL.md:74-77` ("The helper itself does ZERO cache discovery — discovery is
judgment … The helper is a pure deterministic transform driven by `--template-root`").

### 3.1 Helper CLI contract (`language-policy.{ps1,sh}`)

Mirrors `upgrade-project`'s flag + exit-code + pipe-stdout contract (`upgrade-project.sh:32-43, 86-89`).
**cwd-derived** (runs from the TARGET project root, like `upgrade-project`) — so L31 two-up root-derivation
does NOT apply to its own logic; it resolves the project from `pwd` and the templates from `--template-root`.

```
pwsh -File .harness/scripts/language-policy.ps1 -TemplateRoot <abs> -Lang <en|zh> [-DryRun] [-Force]
bash  .harness/scripts/language-policy.sh   --template-root <abs> --lang <en|zh> [--dry-run] [--force]
```

| Flag | Meaning |
|---|---|
| `--template-root` / `-TemplateRoot` | resolved plugin cache root (the dir that contains `skills/`) — **required**; the helper does ZERO discovery |
| `--lang` / `-Lang` | target language `en` or `zh` — **required**; any other token → exit 1 |
| `--dry-run` / `-DryRun` | print the `PLAN\|…` records, write nothing |
| `--force` / `-Force` | proceed past the absent-section conflict (insert the canonical section); without it the helper emits the conflict and exits 2 (the skill mediates the AskUserQuestion) |

**Template source paths the helper reads** (no second policy-text source — `01:in-scope 7`):

- en section/lines: `<template-root>/skills/harness-init/templates/common/.harness/rules/00-core.md.tmpl`,
  `…/common/CLAUDE.md.tmpl`, `…/common/.github/copilot-instructions.md.tmpl`.
- zh section/lines: `<template-root>/skills/harness-init/templates/i18n/zh/common/.harness/rules/00-core.md.tmpl`,
  `…/i18n/zh/common/CLAUDE.md.tmpl`, `…/i18n/zh/common/.github/copilot-instructions.md.tmpl`.

The helper extracts the policy section/line from these `.tmpl` files using the **same heading/line anchors**
it uses on the target (§5) — it does not hard-code policy prose. The `00-core.md.tmpl` files contain
`{{PROJECT_NAME}}` etc. ONLY in the header (`00-core.md.tmpl:1-3`), never inside the policy section
(`01:F-1`), so the extracted section has no unresolved placeholder. (Cross-check: the en section
`00-core.md.tmpl:9-22` and zh section `:9-31` contain zero `{{…}}`.)

**Exit codes** (mirror `upgrade-project.sh:19-20`):

| Exit | Meaning | Skill action |
|---|---|---|
| `0` | success / nothing-to-do / dry-run printed | continue to final gate |
| `1` | precondition / arg error (bad `--lang`, missing `--template-root`, no policy surface) | surface stderr, halt |
| `2` | **section-conflict** — `00-core.md` exists but neither canonical heading is present (hand-mangled / absent) and `--force` not given | relay `CONFLICT\|section\|…`; the skill runs AskUserQuestion (OQ-5) → re-invoke with `--force` to insert, or abort |

**Pipe-delimited stdout** (one record per line; mirror `upgrade-project.sh:117-126`):

| Prefix | Meaning |
|---|---|
| `LANG\|<en\|zh>` | resolved target language |
| `DETECT\|<en\|zh\|ambiguous>\|<source>` | current-language inference result (source ∈ `00-core`/`CLAUDE`/`copilot`/`none`) |
| `PLAN\|<verb>\|<file>\|<detail>` | planned action (dry-run) |
| `RESULT\|<verb>\|<file>\|<detail>` | applied action |
| `BAK\|<path>` | backup written |
| `SKIP\|<file>\|<reason>` | absent policy surface tolerated (e.g. copilot file missing) |
| `CONFLICT\|section\|<file>\|<detail>` | hand-mangled / absent policy section |
| `SUMMARY\|rewritten=.. noop=.. skipped=.. baks=.. conflicts=..` | totals |

`<verb>` ∈ `REWRITE-SECTION REWRITE-LINE INSERT-SECTION NOOP SKIP`.

### 3.2 Helper location + sync-self membership

- Template copy: `templates/common/.harness/scripts/language-policy.{ps1,sh}` — ships into every generated
  project (so a project can refresh without the plugin cache present on PATH — though the skill always
  passes `--template-root` from the live cache, matching `/harness-upgrade`).
- Dogfood mirror: `.harness/scripts/language-policy.{ps1,sh}`.
- **Joins the sync-self mirror set.** sync-self today mirrors `.harness/agents/` + 6 script pairs
  (`AI-GUIDE.md:71`: harness-sync, install-hooks, archive-task, guard-rm, migrate-scripts-layout,
  upgrade-project). Add `language-policy` → **7 script pairs**. This requires editing `sync-self.{ps1,sh}`'s
  mirror array AND the `AI-GUIDE.md:71` "6 script pairs" prose. (Insight line 10 still says "4 specific
  scripts"; that is a stale insight, not a live array — the live mirror list is in `sync-self.{ps1,sh}` and
  the `AI-GUIDE.md:71` prose, both of which the Developer edits.)

> **Developer action:** read the live `sync-self.{ps1,sh}` mirror array before editing — add `language-policy`
> to it in BOTH shells, then bump `AI-GUIDE.md:71` "6 script pairs" → "7 script pairs" and extend its
> parenthetical list. `test-language` is a **test** driver, NOT in the sync-self mirror set (test drivers
> are dogfood-only, like `test-harness-upgrade.{ps1,sh}`).

---

## 4. Self-bootstrap + template-cache discovery (skill layer)

Reuse the `/harness-upgrade` discovery chain verbatim (`skills/harness-upgrade/SKILL.md:51-72`), first hit
wins:

1. `$CLAUDE_PLUGIN_ROOT/skills/harness-init/templates` if `$CLAUDE_PLUGIN_ROOT` set (**best-effort only**;
   fall through if unset — do NOT depend on it).
2. **Load-bearing glob:**
   `~/.claude/plugins/cache/harness-kit-marketplace/harness-kit/*/skills/harness-init/templates` — on
   multiple matches pick the **highest semver** directory.
3. Dev/marketplace-less fallbacks:
   `~/.claude/plugins/cache/*/harness-kit/*/skills/harness-init/templates`, then
   `~/.claude/skills/harness-init/templates`.
4. **None resolve → halt** ("could not locate the harness-kit plugin template cache; reinstall the plugin")
   — the helper is never invoked (`01:boundary 7`, AC-10's negative path).

The helper's `--template-root` is the directory **above** `skills/harness-init/templates` (the resolved
`<cache>/harness-kit/<version>/` that contains `skills/`), identical to
`skills/harness-upgrade/SKILL.md:66-68`. The skill reads `<that>/.claude-plugin/plugin.json` `version` and
surfaces it in the plan as human prose. **No second source of policy text** (`01:in-scope 7`): the canonical
en/zh sections come only from the resolved templates; AC-10 (self-bootstrap on a stale project that does not
contain the canonical text) holds because the text is pulled from the cache, never from the target project.

---

## 5. The section-locator + replacement mechanism (OQ-1 — the crux)

This is the load-bearing algorithm. It runs in the helper, identically in PS and bash.

### 5.1 The two real headings (quote, verbatim)

The en and zh `00-core.md` policy headings **differ** (`01:F-2`). Exact literals:

- en heading (`templates/common/.harness/rules/00-core.md.tmpl:9`):
  `## Output language (project-wide)`
- zh heading (`templates/i18n/zh/common/.harness/rules/00-core.md.tmpl:9`):
  `## 输出语言（按消费者分流）`

The section ends at the next `## ` heading: en `## How this project is developed` (`:24`) /
zh `## 这个项目怎么开发` (`:33`), or EOF if none follows.

### 5.2 Locate algorithm (idempotent, language-agnostic match)

```
INPUT: target file 00-core.md (lines), TARGET lang's canonical section block (from template)
1. Scan lines for the FIRST line that, after trimming trailing whitespace, equals EITHER
   "## Output language (project-wide)"  OR  "## 输出语言（按消费者分流）".
   (Match either heading: the project may currently be en OR zh; we do not know which yet.)
2. If no such line:
     -> the policy section is absent or its heading was hand-mangled.
     -> emit CONFLICT|section|00-core.md; exit 2 UNLESS --force.
        With --force: INSERT-SECTION — append the canonical section after the file's H1/intro
        block (documented insertion point: immediately before the first "## " heading, or at EOF
        if none), then continue. (OQ-5: never silently mutate without the skill's AskUserQuestion.)
3. Else let START = that heading line index.
4. Find END = the index of the NEXT line beginning with "## " strictly after START; if none, END = EOF.
5. Replace lines [START, END) with the TARGET lang's canonical section block (heading included),
   verbatim from the template. Everything before START and from END onward is preserved byte-for-byte.
6. After replacement there is exactly ONE policy heading and ONE policy section (AC-6) — because the old
   heading+body span (whichever language) was the unit removed and the single new block installed.
```

The canonical section block the helper installs is **exactly** the template lines:

- **en target** = `templates/common/.harness/rules/00-core.md.tmpl:9-22` — i.e. from
  `## Output language (project-wide)` through the line
  `To change the project language, edit this "Output language" section in
  \`.harness/rules/00-core.md\` — it takes effect by reference, no sync step needed.` and its trailing
  blank line, up to (not including) `## How this project is developed`.
- **zh target** = `templates/i18n/zh/common/.harness/rules/00-core.md.tmpl:9-31` — from
  `## 输出语言（按消费者分流）` through the line
  `要修改语言策略，编辑 \`.harness/rules/00-core.md\` 的"输出语言"章节 …` and its trailing blank line,
  up to (not including) `## 这个项目怎么开发`.

> **Dev note:** the helper EXTRACTS this block from the resolved template at runtime using the same
> step-1/step-4 anchor logic against the `.tmpl` file (locate the heading, slice to the next `## `). It
> does NOT embed the prose as a string literal — that keeps a single source of truth (the template) and
> means a future T-013-style policy refinement flows through automatically with no helper edit. **Also: not
> embedding the zh prose as a literal keeps the zh canonical text (which is the T-013 three-way split and
> contains no retired anchor) out of the helper file entirely — see §8.**

### 5.3 The one-line policy swap (CLAUDE.md + copilot)

`CLAUDE.md` and `.github/copilot-instructions.md` carry a single policy LINE, not a section. Exact literals:

- en `CLAUDE.md.tmpl:3`: `Output language: **English**.`
- zh `CLAUDE.md.tmpl:3`:
  `输出语言：面向人的产出（对话、报告、README/人读文档）用**中文**，面向 agent/LLM 的产出（阶段文档、台账、规则、注释、commit）用**英文**。完整分流见 \`.harness/rules/00-core.md\`。`
- en copilot (`copilot-instructions.md.tmpl:6`) = same prose as the en CLAUDE.md line.
- zh copilot (`copilot-instructions.md.tmpl:6`) = same prose as the zh CLAUDE.md line.

**Locate algorithm for the line:** scan for the FIRST line whose trimmed start matches the regex
`^(Output language:|输出语言：)` and replace that **entire line** with the target language's canonical line
(read from the template). Preserve all other lines byte-for-byte. If no such line is found in a file that
otherwise exists → emit `SKIP|<file>|policy line not found` (do not corrupt; the skill surfaces it). The
copilot template additionally has YAML frontmatter (`copilot-instructions.md.tmpl:1-3` `applyTo: "**"`); the
line scan starts after the frontmatter and the policy line is the first body line — the regex anchor handles
this without special-casing.

### 5.4 Idempotence + the zh→en→zh round-trip (the critical correctness property)

- **Idempotence (AC-2/AC-3 second run):** before writing each file, compare the would-be new content to the
  current content byte-for-byte. If identical → emit `NOOP`, write nothing, write NO `.bak`
  (`01:requirement 11`, mirrors `upgrade-project.sh:147-150, 382-386`). Running the same target twice is a
  clean no-op.
- **Round-trip zh→en→zh restores the exact zh text (byte-identical):** because the installed text comes
  **only** from the plugin templates (self-bootstrap, §4), an `en` run installs exactly the en template
  block and a subsequent `zh` run installs exactly the zh template block. There is no lossy transform and no
  second source. The user's other `00-core.md` sections are never touched, so the rest of the file is also
  bit-stable. State explicitly: **zh→en→zh is byte-identical to the original zh template state** for the
  policy section/lines, and unchanged elsewhere. This is the contract that makes "switch" safe and
  reversible.

### 5.5 Hand-mangled / absent-section fallback (boundary 5, OQ-5)

If step 2 finds no recognizable heading: the helper emits `CONFLICT|section|00-core.md|no recognizable
policy heading` and exits 2 (without `--force`). The **skill** then runs `AskUserQuestion`:
"00-core.md has no recognizable Output-language policy section. Insert the canonical `<lang>` section?
[insert / abort]". On "insert" → re-invoke the helper with `--force` (INSERT-SECTION at the documented
point). On "abort" → halt, change nothing. The skill NEVER auto-inserts without the explicit answer
(AC-7). This is the exact analogue of `/harness-upgrade`'s exit-2 verify_all-conflict mediation
(`skills/harness-upgrade/SKILL.md:142`).

---

## 6. Current-language detection (OQ-2)

Inference order, **first confident hit wins**, then **always confirm via AskUserQuestion pre-filled**
(`01:requirement 9`, AC-7):

1. `00-core.md` policy heading — `## 输出语言（按消费者分流）` ⇒ **zh**; `## Output language (project-wide)`
   ⇒ **en** (authoritative; it is the full policy section).
2. else `CLAUDE.md` top policy line — a line starting `输出语言：` ⇒ **zh**; `Output language:` ⇒ **en**.
3. else `.github/copilot-instructions.md` top policy line — same discriminants.

**The distinguishing string is the heading/line prefix literal**, not a language-detection heuristic:
`输出语言` (the CJK characters) vs `Output language` (the ASCII phrase). Matching `输出语言` as a substring of
either the H2 heading or the `输出语言：` line is sufficient and unambiguous; `Output language` likewise.

- **First confident hit wins** (source emitted as `DETECT|<lang>|<source>`).
- **Conflict between sources OR no hit → `ambiguous`** (`DETECT|ambiguous|…`) → the skill ASKS with no
  pre-fill default (boundary 1, AC-7). Never guess.
- For the **no-arg refresh** path, detection sets the pre-filled value; the skill confirms via
  AskUserQuestion ("Detected `<lang>`. Refresh to the current canonical `<lang>` policy? [yes / change to
  other / cancel]"), then drives the helper with the confirmed `--lang`. (OQ-2 keeps the confirm but
  pre-fills it — option (a), not "always ask blindly".)

For an **explicit** `/harness-language en|zh`, detection is still run (to report "switching from `<X>` to
`<Y>`" or "already `<Y>`") but the target is the argument; the confirm is the dry-run apply gate (§7),
not a language-choice question.

---

## 7. Sequence / flow (skill → helper)

```
/harness-language [en|zh|<none>]
        │
        ▼
[skill] Stage 1 — Precondition gate (OQ-6, OQ-7; mirror upgrade SKILL §1)
        • cwd is the target.
        • .git/ exists?            no → HALT "not a git repository" (AC-9)
        • dirty tree?              yes → HALT "commit or stash first" (clean = git reset rollback)
        • at least one of .harness/rules/00-core.md OR CLAUDE.md exists?
                                   no → HALT, point at /harness-init or /harness-adopt (AC-9)
        │
        ▼
[skill] Stage 2 — Validate arg
        • arg ∉ {en, zh, ∅} → HALT "only en|zh are supported" (boundary 2)
        │
        ▼
[skill] Stage 3 — Resolve template cache (§4 chain) → --template-root, read target version
        • none resolve → HALT (boundary 7)
        │
        ▼
[skill] Stage 4 — Determine target lang
        • explicit en|zh → that.
        • no-arg → run helper detection (DETECT record) → AskUserQuestion pre-filled (§6).
          ambiguous → AskUserQuestion no default (AC-7).
        │
        ▼
[skill] Stage 5 — DRY-RUN: invoke helper --dry-run --lang <L> --template-root <abs>
        • parse PLAN|… records → present: which files, which section/line, en→zh / zh→en / refresh,
          .bak locations, target version.
        • CONFLICT|section → AskUserQuestion insert/abort (§5.5).
        • AskUserQuestion "Apply this plan? [yes / no]" (mirror upgrade SKILL §5; AC-7 no silent write)
        │
        ▼ yes
[helper] APPLY: --lang <L> --template-root <abs> [--force if insert approved]
        • for 00-core.md: REWRITE-SECTION (or INSERT-SECTION), .bak first, NOOP on byte-identity.
        • for CLAUDE.md + copilot (each that EXISTS): REWRITE-LINE, .bak first, NOOP on byte-identity.
        • missing copilot file → SKIP|… (AC-8, not an error).
        • emit RESULT|… BAK|… SUMMARY|…
        │
        ▼
[skill] Stage 6 — Branch on exit (0 ok / 1 halt+stderr / 2 section-conflict mediation)
        │
        ▼
[skill] Stage 7 — Report: rewritten/noop/skipped files, .bak paths, "switched <X>→<Y>" or
        "already current / nothing to do" (idempotent no-op messaging, AC-2). No verify_all run on the
        TARGET project is required by AC (the command edits policy prose, not scripts), but the skill MAY
        suggest the user re-run their own verify_all if present.
```

---

## 8. I.6 self-trip avoidance (the #1 doc hazard — carry from PM_LOG)

**The hazard (insight line 38 / I.6, T-013 hit this 3×):** any **scanned** file that DESCRIBES the
retired blunt all-Chinese policy must NOT write the literal retired anchor (the I.6 zh banned-line:
the word meaning "throughout/all-the-way" immediately followed by the word for "Chinese"). Writing it
self-trips `verify_all` I.6.

**Exempt vs scanned boundary (verified against `verify_all.sh:517-559`):**

- **EXEMPT (may quote freely):** `CHANGELOG.md`, the whole `docs/features/` subtree (so this
  `02_SOLUTION_DESIGN.md` itself, the future `04_DEVELOPMENT.md`, etc.), `verify_all.{ps1,sh}` itself,
  `test-verify-i6.{ps1,sh}`, `architecture.html`, `docs/walkthrough.html`.
- **SCANNED (must paraphrase / use English):** `skills/harness-language/SKILL.md`,
  `language-policy.{ps1,sh}`, `test-language.{ps1,sh}`, `AI-GUIDE.md`, `README.md`, `README.zh-CN.md`,
  `docs/getting-started.md`, `docs/manual-e2e-test.md`, `.harness/rules/40-locations.md`,
  `skills/harness-upgrade/SKILL.md` (the hint line).

**Design rules for the Developer (explicit):**

1. In `SKILL.md`, `language-policy.{ps1,sh}`, `test-language.{ps1,sh}`, and every scanned doc: when you must
   refer to the old policy, **paraphrase in English** — e.g. "the pre-T-013 single-language Chinese policy"
   or "the retired blunt all-Chinese rule". **Never** write the two retired CJK words adjacently.
2. **The helper does NOT embed the zh policy prose as a string literal** (§5.2) — it extracts from the
   template. This removes the only place a helper file might otherwise contain CJK policy text, and the
   T-013 three-way zh canonical text it applies contains **no** retired anchor anyway (it is the new split
   text), so even the applied content is safe. The risk is **purely META descriptions**, and those are all
   in scanned files → paraphrase.
3. The **CHANGELOG `[0.25.0]` entry** is in an exempt file, but to be safe and consistent the entry should
   still describe the feature by what it does ("set/switch/refresh the project output-language policy"),
   referencing the retired phrasing only if necessary and only because CHANGELOG is exempt. The existing
   `[0.24.0]` entry (`CHANGELOG.md:10-18`) is the model: it paraphrases ("the blunt 'everything in
   Chinese'") and confines the literal anchor to a backticked I.6-rule reference.
4. **Does the new `SKILL.md`/CHANGELOG entry risk the anchor?** SKILL.md: only if it narrates "this switches
   away from the old X policy" — design the wording to say "switch between English and the consumer-split
   Chinese policy" (no anchor). CHANGELOG: exempt, but follow rule 3.

> **No I.6 LIST changes.** This task does NOT add or remove an I.6 banned/exempt entry, so the 4-file
> lockstep (`verify_all.{ps1,sh}` + `test-verify-i6.{ps1,sh}` + `I6ExpectedEntryCount`, insight line 37) is
> **untouched**. `test-language.{ps1,sh}` does NOT need to be added to the I.6 exempt-FILE list **provided it
> embeds only the SAFE three-way zh text** (or, better, asserts on the en/zh markers without embedding the
> retired anchor). If a fixture or assertion needs the retired anchor literal, that would force a 4-file I.6
> exempt-list edit — **avoid it**: assert on the NEW markers (`输出语言（按消费者分流）` heading, the EN-list /
> ZH-list markers) and on the ABSENCE of the retired phrasing, the way T-013's own `test_zh_overlay` did
> (`CHANGELOG.md:16`).

---

## 9. Regression-test plan stub (`test-language.{ps1,sh}`)

**Decision: a NEW dedicated `test-language.{ps1,sh}` pair**, paralleling `test-harness-upgrade.{ps1,sh}`
(the sibling skill's driver). Not an extension of `test-init` (test-init asserts the init scaffold; the
language command operates on an already-generated project — a different fixture lifecycle). PS+Bash
symmetric (NFR-1), byte-identical assertions, UTF-8-saved (CJK), no `grep -F -i` on MSYS (L25),
bash `arr=()` not `declare -a` (L13).

**Fixtures + cases (map to ACs):**

| # | Fixture / setup | Action | Assert | AC |
|---|---|---|---|---|
| 1 | en-generated project (00-core en heading, CLAUDE/copilot en line) | `--lang zh` | zh heading + ZH-list + EN-list markers present in 00-core; zh line in CLAUDE + copilot; `.bak` per edited file; exactly one policy heading | AC-3, AC-6 |
| 2 | result of #1 | `--lang zh` again | NOOP, no new `.bak`, "already current" | AC-3 (idempotence) |
| 3 | zh-generated project | `--lang en` | en heading + single-language en section; en line in CLAUDE + copilot; `.bak` each; one heading | AC-1, AC-6 |
| 4 | result of #3 | `--lang en` again | NOOP, no `.bak` | AC-2 |
| 5 | zh project | `--dry-run --lang en` | PLAN records printed; **no file changed** (git/byte diff clean) | NFR-2, AC-5 |
| 6 | zh project, STALE policy text (rewritten to a pre-T-013 form, paraphrased — NOT the literal anchor) | no-arg (detect) → `--lang zh` | DETECT\|zh; rewrites to current three-way zh; markers present | AC-4 |
| 7 | en project lacking `.github/copilot-instructions.md` | `--lang zh` | 00-core + CLAUDE rewritten; copilot `SKIP`; exit 0 | AC-8 |
| 8 | project with 00-core.md whose policy heading is hand-mangled | `--lang en` (no `--force`) | `CONFLICT\|section`; exit 2; **file unchanged** | AC-7, boundary 5 |
| 9 | round-trip: zh project → `--lang en` → `--lang zh` | compare final 00-core/CLAUDE/copilot policy region to original | **byte-identical** to original zh | §5.4 |
| 10 | non-git dir | any | helper/skill gate HALT, no change | AC-9 |

> Fixture-building note: use isolated `mktemp -d` per case (insight line 20 — shared temp dirs degrade
> bidirectional assertions into a sequence). Separate allocations for #1/#3 etc.

**Baseline impact:** `test-language` is a NEW driver with its own tally; it does NOT change `test-init`'s
count (test-init unchanged — `01:O-6`). Add its counts to `baseline.json` if the project tracks them there
(check the live `baseline.json` shape; `test-harness-upgrade` precedent reported 38/37).

---

## 10. AC → component traceability

| AC | Component(s) | Where |
|---|---|---|
| AC-1 zh→en switch | helper REWRITE-SECTION + REWRITE-LINE; en template | §5.2, §5.3 |
| AC-2 idempotence of switch | helper NOOP on byte-identity | §5.4 |
| AC-3 en→zh switch | helper, zh template | §5.2, §5.3 |
| AC-4 no-arg refresh | skill detection + confirm; helper apply | §6, §7 |
| AC-5 surgical scope | helper replaces only [START,END) + the one line; rest byte-preserved | §5.2, §5.3 |
| AC-6 single-section invariant | helper removes old heading+body span, installs one block | §5.2 step 6 |
| AC-7 detect-then-confirm, no silent guess | skill AskUserQuestion (ambiguous / apply / insert) | §5.5, §6, §7 |
| AC-8 missing surface tolerated | helper `SKIP\|<file>` | §5.3, §3.1 |
| AC-9 precondition gates | skill Stage 1 (git/clean/min-surface) | §7 |
| AC-10 self-bootstrap | template-cache discovery; no project-resident text dependency | §4 |
| AC-11 /harness-upgrade hint | one hint line in upgrade SKILL.md | §11 O-4 |
| AC-12 gate green + fan-out | C.1/C.2/G.1/G.2 arrays, version bump, CHANGELOG, helper parity, test-init green | §11 |
| AC-13 no new placeholder | no `{{…}}` added; D.2 whitelist untouched | §12, §13 |

---

## 11. Ship-on-THIS-repo fan-out (version + count obligation)

New skill ⇒ skill count **13→14**, version **0.24.0→0.25.0** (releasable; insight line 31 / G.4). The
fan-out floor is the T-012/T-013 proven list (verified line-by-line against the live tree). **`verify_all`
stays 32 checks** — a new skill needs NO new lettered `Step`: C.1 (present), C.2 (frontmatter), G.1
(README mentions), G.2 (CHANGELOG mentions) already loop over the skill array; F.1 gains the helper pair
**name-only** (zero check-count impact). Confirmed against `verify_all.sh:54-69, 333-349` and
`verify_all.ps1:300-331`.

| Site | File:line | Edit |
|---|---|---|
| C.1 skill loop (bash) | `verify_all.sh:56`; label `:59` | add `harness-language` to the `for s in …` list; label `All 13`→`All 14` |
| C.1 skill loop (PS) | `verify_all.ps1:302` (under Step `:68`); label `:68` | add `"harness-language"` to the array; label `All 13`→`All 14` |
| C.2 frontmatter loop | `verify_all.{sh:63-69, ps1}` | globs `skills/**/SKILL.md` — **auto-covers** the new skill, no array edit, but it WILL now require `harness-language/SKILL.md` to have valid frontmatter |
| G.1 README skill loop (bash) | `verify_all.sh:346`; label `:333` | add `harness-language`; label `all 13`→`all 14` |
| G.1 README skill loop (PS) | `verify_all.ps1:302`; label `:300` | add `"harness-language"`; label `all 13`→`all 14` |
| G.2 CHANGELOG skill loop (bash) | `verify_all.sh:346`; label `:349` | add `harness-language`; label `all 13`→`all 14` |
| G.2 CHANGELOG skill loop (PS) | `verify_all.ps1:328`; label `:326` | add `"harness-language"`; label `all 13`→`all 14` |
| F.1 script-pair list | `verify_all.{ps1,sh}` F.1 pair list | add `language-policy` (name-only, like `upgrade-project`); zero count impact |
| `plugin.json` version | `.claude-plugin/plugin.json:3` | `0.24.0`→`0.25.0` |
| `marketplace.json` version | `.claude-plugin/marketplace.json:19` | `0.24.0`→`0.25.0` |
| README badge (en) | `README.md:5` | `version-0.24.0`→`version-0.25.0` (verify_all badge stays `32/32`; test-init/integration badges only if their counts move — `test-language` is a separate driver, likely no badge) |
| README skill count (en) | `README.md:7` "13 skills"; `:13` "thirteen" | →"14 skills" / "fourteen"; add a `/harness-kit:harness-language` bullet under **Setup skills** (`:23-26`) |
| README badge + count (zh) | `README.zh-CN.md:5, :7, :13` | `0.24.0`→`0.25.0`; "13 个 skills"→"14 个"; add bullet under **安装类** (`:23-26`) |
| AI-GUIDE skill count | `AI-GUIDE.md:7` "distributes 13 skills" | →"14 skills" |
| AI-GUIDE sync-self prose | `AI-GUIDE.md:71` "6 script pairs" + list | →"7 script pairs"; add `language-policy` to the parenthetical |
| getting-started | `docs/getting-started.md:36` "thirteen"; Setup group `:47-51` | →"fourteen"; add `harness-language` bullet |
| manual-e2e-test | `docs/manual-e2e-test.md:7, :34-36, :49, :53-54, :60-62` | "thirteen"/"13 skills"→"fourteen"/"14 skills"; add `harness-language` to all enumerations |
| 40-locations | `.harness/rules/40-locations.md:30` "All 13 skills" | →"All 14 skills" (note `:25` says "32 checks" — **stays 32**, do NOT touch) |
| CHANGELOG | `CHANGELOG.md` top | new `[0.25.0]` section (Added — `/harness-language` skill); MUST mention `harness-language` (so G.2 passes) and reference the helper |
| sync-self mirror | `sync-self.{ps1,sh}` array | add `language-policy` (see §3.2) |

**Same-file claim uniqueness (insight line 33 / L36):** when bumping "13"→"14" labels in the C.1/G.1/G.2
step strings, each step's label string is already file-unique by its letter ("All 14 skills present" vs
"README references all 14 skills" vs "CHANGELOG references all 14 skills") — no collision introduced. The
README/zh-CN "fourteen"/"14 个" tokens are prose, not gate-`expect` literals, so L36 (gate same-file
expect-uniqueness) does not bind them; just keep them internally consistent.

**Grouping (insight line 36 / O-7):** `/harness-language` registers under **Setup** (sibling of init / adopt
/ upgrade) in README (`:23-26`), getting-started (`:47-51`), manual-e2e-test — **NOT** a pipeline task-shape.
The **"six task shapes" / "6 种任务形态"** framing (`README.md:15`, `README.zh-CN.md:15`) is for pipeline
modes and stays **SIX — do NOT touch** (this is a setup utility). This matches the T-012 ruling
(`_archived/harness-upgrade-skill/05_CODE_REVIEW.md:18`).

### O-4 — the /harness-upgrade one-line hint (OQ-4)

The **only** edit to an existing skill. Add ONE line to `/harness-upgrade`'s end-of-run summary
(`skills/harness-upgrade/SKILL.md` step 7 report block, after the summary lines `:150-163`). Exact line
(English, no I.6 anchor):

```
Tip: to set or refresh this project's output-language policy (English ↔ Chinese), run /harness-language.
```

Hint only — **no auto cross-command invocation** (AC-11). No other change to `harness-upgrade`.

---

## 12. Migration / rollout plan

- **Backwards compatibility:** purely additive — a new skill + a new helper pair + a new test pair + doc
  count bumps + one hint line. No existing template policy CONTENT changes (T-013 shipped both target
  states), so **`test-init` stays green** (`01:O-6`) and already-generated projects are not auto-migrated.
- **Rollout to existing projects:** existing projects pick up the new skill on their next plugin
  marketplace pull (standard plugin distribution). The skill self-bootstraps the helper from the cache, so
  a stale project does not need the helper pre-installed (mirrors `/harness-upgrade`).
- **No new placeholder (OQ-3 / AC-13):** D.2 whitelist untouched (insight line 9). The canonical policy text
  is already fully resolved in the templates (no per-policy `{{…}}`), so no D.2 churn.
- **Rollback path on a TARGET project:** clean-git-tree precondition (OQ-7) ⇒ `git reset --hard` restores
  tracked policy files; the `.bak` per file covers any untracked surface. On THIS repo, the change is
  revertable by a single commit revert (no data migration).
- **Version gate:** `plugin.json` + `marketplace.json` + both README badges to 0.25.0 in lockstep or G.3/G.4
  FAIL (insight line 12 / line 31).

---

## 13. Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| Skill+helper two-layer structure | `/harness-upgrade` skill + `upgrade-project.{ps1,sh}` | `skills/harness-upgrade/SKILL.md`, `templates/common/.harness/scripts/upgrade-project.{ps1,sh}` | **Reuse the pattern** — copy the structure, flag/exit/stdout contract, dry-run→confirm→apply, `.bak`, gates |
| Plugin-template-cache discovery chain | `/harness-upgrade` §2 | `skills/harness-upgrade/SKILL.md:51-72` | **Reuse verbatim** (same 4-step fallback, `$CLAUDE_PLUGIN_ROOT`-optional, highest-semver glob) |
| Detect-then-ASK current state | `/harness-upgrade` §3 (project-type detect+confirm) | `skills/harness-upgrade/SKILL.md:78-91` | **Reuse the pattern** for current-language detect+confirm |
| Precondition gates (git repo + clean tree) | `upgrade-project.sh` preconditions | `upgrade-project.sh:71-77`, `skills/harness-upgrade/SKILL.md:36-47` | **Reuse** the gate logic + messages |
| `.bak` + NOOP-on-byte-identity + pipe stdout | `upgrade-project.sh` S2/S5 | `upgrade-project.sh:147-159, 382-402` | **Reuse** the idempotence + `.bak` + `SUMMARY` discipline |
| Piece-wise placeholder token (avoid test-init `{{…}}` scan) | `substitute_placeholders` `o="{{"; c="}}"` | `upgrade-project.sh:265-279` (insight line 35) | **Reuse IF** the helper ever names a placeholder — but the policy sections contain none, so likely N/A here |
| Canonical en/zh policy text | T-013 template sections | `templates/common/.../00-core.md.tmpl:9-22`, `templates/i18n/zh/common/.../00-core.md.tmpl:9-31` + the two `CLAUDE.md`/copilot lines | **Reuse as the ONLY source** — read at runtime, do not fork |
| sync-self mirror mechanism | `sync-self.{ps1,sh}` + `AI-GUIDE.md:71` | `.harness/scripts/sync-self.{ps1,sh}` | **Extend** — add `language-policy` to the mirror array (6→7 pairs) |
| Regression driver convention | `test-harness-upgrade.{ps1,sh}` | `.harness/scripts/test-harness-upgrade.{ps1,sh}` | **Reuse the convention** — new `test-language.{ps1,sh}` paralleling it |
| Skill-count + version fan-out checklist | T-012/T-013 deliveries | `_archived/harness-upgrade-skill/02_SOLUTION_DESIGN.md:454-510`, `CHANGELOG.md:75-97`, `:10-18` | **Reuse the proven site list** (§11) |
| Heading-anchor section replace | (none — `/harness-upgrade` works on scripts/settings/hooks, not markdown sections) | — | **New mechanism justified** (§5); no existing markdown-section locator in the repo |

---

## 14. Risk analysis

| # | Risk | Likelihood | Mitigation |
|---|---|---|---|
| R1 | **I.6 self-trip** — a scanned file (SKILL.md / helper / test / doc) writes the retired CJK anchor while describing the feature → `verify_all` I.6 FAIL (hit T-013 3×). | High (proven recurrence) | §8: paraphrase in English in all SCANNED files; helper extracts (never embeds) policy prose; tests assert on NEW markers + absence of the retired phrasing; CHANGELOG (exempt) follows the `[0.24.0]` model. Verify with a live `verify_all` run before declaring done (insight line 26). |
| R2 | **Cross-shell parity break** — PS `WriteAllText` writes no trailing newline, bash heredoc/`printf '%s\n'` does (insight line 36 / L36) → byte-different policy-section writes → idempotence/round-trip assertions break. | Medium | Append `` "`n" `` on the PS write side; `test-language.{ps1,sh}` #9 asserts byte-identical round-trip in BOTH shells; the helper compares byte-for-byte before writing. |
| R3 | **Hand-mangled heading defeats the anchor** → silent corruption or wrong-place insert. | Medium | §5.5: locator emits `CONFLICT\|section` + exit 2; the skill mediates via AskUserQuestion (insert/abort), never auto-inserts (AC-7); test #8 asserts no change without `--force`. |
| R4 | **CJK mojibake** — zh three-way text written as non-UTF-8 → corrupted policy. | Medium | NFR-3: every helper write is UTF-8; no `grep -F -i` on MSYS (L25); test asserts the zh markers round-trip without mojibake. |
| R5 | **Fan-out miss** — a "13/thirteen/13 个" site left stale → G.1/G.2 still PASS (they match skill NAMES, not the count) but the doc lies; or version badge left at 0.24.0 → G.3/G.4 FAIL. | Medium | §11 enumerates every site with file:line; G.3/G.4 catch the version vector; a manual sweep of `13`/`thirteen`/`13 个`/`0.24.0` against the live tree before delivery (insight line 19 — include CHANGELOG; line 12 — counts need manual sync). |
| R6 | **Wrong sync-self/AI-GUIDE prose** — add `language-policy` to the template+dogfood but forget the sync-self array or the `AI-GUIDE.md:71` "6 pairs" prose → drift / E.* mismatch at the gate. | Low-Medium | §3.2 Dev note: edit the sync-self array in BOTH shells AND the AI-GUIDE prose; run `sync-self` then `verify_all`. |
| R7 | **Section block extracted with wrong boundary** — off-by-one on the trailing blank line before the next `##` → policy section gains/loses a blank line, breaking byte round-trip. | Low-Medium | §5.2 step 5 defines [START, END) precisely (END = next `## ` line, exclusive); test #9 round-trip catches any boundary drift byte-for-byte. |

---

## 15. Out-of-scope clarifications (design boundaries)

- **No whole-project content translation** — only the three policy locations (`01:out-of-scope 1`).
- **No other i18n/zh overlay files** (`AI-GUIDE.md.tmpl`, `docs/workflow.md`, other rule fragments) —
  T-013's deferred (B) stays deferred (`01:out-of-scope 2`).
- **The dogfood repo is NOT a target** — never hand-edit this repo's `CLAUDE.md` / `00-core.md` policy via
  the command (red line; `01:F-6`, `01:out-of-scope 3`).
- **Only `en` and `zh`** — no `ja`/`fr`/… overlays (`01:out-of-scope 4`).
- **No new persisted `PROJECT_LANG` marker / no new `{{…}}`** (OQ-3; `01:out-of-scope 5`, AC-13).
- **No retroactive edits to files the command does not own** (`50-<type>.md`, per-task docs)
  (`01:out-of-scope 6`).
- **No v0.1.x→v0.2.0 CLAUDE.md→rules split migration** (that is `MIGRATION.md`) (`01:out-of-scope 7`).
- **No new lettered `verify_all` check** — the existing skill loops cover the new skill; check count stays
  **32** (§11).
- **No I.6 banned/exempt list change** — the 4-file lockstep is untouched (§8).

---

## 16. Downstream-obligations discharge list

| Obligation (from `01:§11`) | Discharged in design | Where |
|---|---|---|
| O-1 skill-count fan-out (13→14) | enumerated with file:line | §11 |
| O-2 version bump (0.24.0→0.25.0) | plugin/marketplace/README badges | §11, §12 |
| O-3 I.6 self-trip trap | paraphrase rules + exempt/scanned boundary + helper-extract | §8 |
| O-4 no new `{{…}}` placeholder | D.2 untouched | §12, §15 |
| O-5 helper two-layer + cross-shell parity + sync-self | helper pair, NFR-1, sync-self 6→7 | §3, §3.2, R2 |
| O-6 test-init impact (none) | no template policy CONTENT change; new `test-language` driver | §9, §12 |
| O-7 skill grouping under Setup; six task shapes unchanged | Setup group; six stays six | §11 |

---

## 17. Verdict

**READY.**

All 7 OQs are resolved (PM_LOG baseline) and the design grounds every decision in real file:line. The
load-bearing forks are settled: **skill + deterministic `language-policy.{ps1,sh}` helper** (mirroring
`/harness-upgrade`); the **heading-anchor locator** (§5: match either canonical heading, replace
[START, next-`##`), idempotent, byte-stable round-trip, AskUserQuestion conflict fallback); **detection**
`00-core → CLAUDE → copilot`, first confident hit, always confirm pre-filled, ambiguous → ask; **self-
bootstrap** from the resolved template cache (single source of policy text). The fan-out is **18 sites**
(§11) with `verify_all` holding at **32 checks** and version moving **0.24.0→0.25.0**. The **I.6 self-trip
plan** (§8) is the #1 risk and is mitigated by the scanned-vs-exempt boundary + paraphrase rule +
template-extraction (no embedded policy prose). No new placeholder, no I.6 list change, six task shapes
unchanged.

**Hand-off to Gate Reviewer.** Residual items the Gate should confirm: (a) the exact insertion point for the
absent-section `--force` branch (§5.2 step 2 — "before the first `## ` heading"); (b) that `test-language`
embeds only the SAFE three-way zh text so no I.6 exempt-list edit is forced (§8/§9); (c) the live
`sync-self.{ps1,sh}` array shape before the Developer adds `language-policy` (§3.2).
