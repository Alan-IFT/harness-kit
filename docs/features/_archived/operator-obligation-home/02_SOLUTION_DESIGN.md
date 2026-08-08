> Contract portion. Rationale: `02_RATIONALE.md`.

# 02 — Solution Design: operator-obligation-home (T-24)

Mode: **full** · deferred-human: defer, do not ask · single-Developer (no `.harness/agents/dev-*.md`).
Upstream contract: `docs/features/operator-obligation-home/01_REQUIREMENT_ANALYSIS.md` (`READY`).

## 1. Architecture summary

The 25 release-gating operator obligations move out of the seven spans across four files they are
reconstructed from today — three archived developer stage documents and four `_qa_note_*` string values
inside a machine-read pin file — into **one new tracked Markdown file,
`.harness/operator-obligations.md`**, the memory layer's fifth kind. Each obligation becomes one entry
of seven named fields on seven consecutive lines; the set's size is counted from one field line with a
published `grep`, never read from a stored total. Every entry is derived from the source that
**enumerates** its obligation and carries the **union** of every span that states it (R-4); for the
eight T-13 obligations that source is an archived developer stage document and the note travelling to
the operator is a lossy **mirror** of it (E-28), so the mirror contributes text but never governs
membership or ordinals. The pin file keeps every numeric key byte-identical, keeps the pin-writing
constraints binding its next writer, keeps the historical narrative untouched, and gains one in-band
sentence saying obligations are not written there. No `verify_all` check is added or removed; no script
and no `.ps1` is created.

## 2. Affected modules

`.harness/operator-obligations.md` **(new)** — the ledger (R-1…R-3). Edits:
`.harness/scripts/baseline.json` (excision R-12/R-13 + in-band statement R-9); `agents/qa-tester.md`
(writer duty R-10 — the only agent contract naming the pin file); `AI-GUIDE.md` (memory-layer line,
R-11); `.harness/rules/40-locations.md` (lookup row, R-11); `docs/dev-map.md` (tree line, R-15);
`.harness/rejected-decisions.md` (declined-gate record, R-14); `CHANGELOG.md` (one bullet under the
**existing** `## [0.46.0]` heading, R-15). `CONTEXT.md` is edited at stage 2 (glossary);
`agents/pm-orchestrator.md` is **not touched** (BC-8); every archived stage document named in §4 is
**read-only** (§3.3). Line counts, caps and the PM arithmetic: §13.

## 3. The obligation ledger

**K-1 · Path.** `.harness/operator-obligations.md`, tracked, dogfood-only. Verified, not assumed:
`I.1`–`I.5` measure five fixed paths (`verify_all.sh:422,439,453,472,548`), so no `I.*` check matches
it and it carries **no gated cap**. `E.1` (`:194`) delegates to `sync-self.sh --check`, whose mapping
is **sixteen** top-level `sync_file` calls, one per file, over eight script pairs (`sync-self.sh:63-93`)
and whose `sync_dir_of_md` (`:35-56`) is defined and **never invoked**, so nothing compares
`.harness/*.md` against `templates/common/`. `E.2` walks only `.harness/agents/` and `.harness/skills/`
(`harness-sync.sh:28,74`); `F.1` is a fixed pair list (`:284`); `G.4` a fixed eleven-file array
(`:841-853`); `A.1` excludes `*.md` (`:33`). `I.6` **does** reach it — B-8, K-40.
**K-2 · The precedent is live.** The ledger is the **fourth** Markdown file at `.harness/` root (after
`insight-index.md`, `decision-rubric.md`, `rejected-decisions.md`) and the memory layer's **fifth kind**
(`AI-GUIDE.md:36-40` lists four and calls declined options "the fourth memory kind"). Two siblings
already exist in both this repo and `skills/harness-init/templates/common/.harness/` with **no
`sync-self` mapping and no gate comparing them**; §3.5 forbids a template twin here.

**K-3 · Document skeleton.** In order: `# ` title; a blockquote header; `## How to count`;
`## Numbered obligations`; `## Origin-qualified obligations`. The header states in prose: what an
operator obligation is; that the file has no gated cap and no rotation, and why (K-1); the append rule
(B-3/B-4); the discharge form and staleness rule (K-4a, B-6); that the file is on no always-read path;
the §12.5 disclosure. **K-4 · Entry shape.** One `### ` heading, then exactly seven field lines in this
order, one per physical line, no blank lines between them:

| # | Line prefix | Content | Empty-case value (AC-2) |
|---|---|---|---|
| 1 | `- Id: ` | the id, bare | never empty |
| 2 | `- Action: ` | the transcribed action, union of every contributing span (R-4) | `text not located` (B-2) |
| 3 | `- Artifacts: ` | every path literal in every contributing span, first-appearance order, de-duplicated | `none stated in source` |
| 4 | `- Pass observable: ` | every expected output, exit code and figure named in any contributing span | `not stated in source` |
| 5 | `- Security: ` | `yes` or `no` | never empty |
| 6 | `- Origin: ` | origin task id + slug, then **every** contributing source path and span, enumerating source first | never empty |
| 7 | `- Last discharged: ` | K-4a's form | `never` |

Heading form `### <id> — <title ≤8 words>`; navigation only, not counted. Field 4 reads `not stated in
source` only when **no** contributing span states an observable (R-4 union; this is the G-3 defect).
Fields, never a table row: transcribed text contains `|` and multi-sentence bodies, and R-4 forbids
paraphrase.

**K-4a · The form of `- Last discharged: ` (BC-5).** Exactly one of `never`,
`<YYYY-MM-DD> against <40-hex-commit-sha>`, or `<YYYY-MM-DD> against <40-hex-commit-sha>+dirty`.
R-8's `<artifact state>` **is the full 40-character `git rev-parse HEAD` of this repository at the
moment of the run**, and nothing else: one token for an entry naming five artifacts, no new tooling,
recordable on Windows without running anything from this repo. `+dirty` is appended when
`git status --porcelain` was non-empty for any path in field 3, and always reads as **not** discharged.
B-6 becomes executable: an entry is stale when `git diff --quiet <sha> HEAD -- <field-3 paths>` exits
non-zero. Entries whose artifact is generated rather than tracked (T13-2's settings file, T13-5's
pre-commit hook) pin the **generator** named in field 3; the header says so in one clause.

**K-6 · The count command.** The ledger publishes exactly this line, in a fenced block under
`## How to count`, and the developer runs it verbatim:

```
grep -c '^- Id: ' .harness/operator-obligations.md
```

It counts field line 1 of every entry, so "count entries" and "count ids" cannot disagree; the line
itself begins with `grep`, so it never matches its own pattern. Under B-1 an empty ledger prints `0`
and exits **1** — grep's documented no-match status, not an error; the header says so in one clause.
**K-7 · Self-match prohibition (binding).** No line anywhere in the ledger other than field line 1 of a
real entry may begin with the seven characters `- Id: `. In particular **the header renders no example
entry**: the seven fields are named as prose, never shown. A rendered example would match K-6's pattern
and inflate the count. AC-4 (`= 25`) is the falsifier.

**K-8/K-9 · Ordering and id forms.** `## Numbered obligations` carries `1` … `17` ascending;
`## Origin-qualified obligations` carries `T13-1` … `T13-8` ascending **in the ordinals the
enumerating source assigns** (R-6) — the only order any enumerating source states. Ids `1`–`17` stay
**bare integers**, because four live archived citations name them ordinally and a prefix would break
those (`02_RATIONALE.md` §R-OQ2 lists them). The eight take `T13-<n>`, `n` = the ordinal **S-F**
assigns (§4). Corrected from round 1: individual ordinals of the eight **are** cited, but only from
inside S-F (`:264`, `:284`, `:289`, `:449-453`), and each resolves under S-F's numbering — which K-46
shows the mirror's falsifies. No document outside S-F and its mirror cites one, so the prefix breaks
nothing and adopting S-F's ordinals repairs rather than moves them.
**K-10 · Disambiguation.** In `_archived/guard-cmd-chain/`, "item 11" means that task's design residual
§10.2 item 11 (`02_SOLUTION_DESIGN.md:181,680,762`), **not** operator obligation 11, which originates
in T-15. Never resolve an obligation id by grepping "item N"; use §4's map.

## 4. Transcription map — the 25 obligations and their sources

Seven spans across four files (E-6). **Enumerating sources**, one per id block: **S-A**
`docs/features/_archived/guard-cmd-chain/04_DEVELOPMENT.md` (ids 1–10); **S-B**
`docs/features/_archived/hook-truth-verify-scope/04_DEVELOPMENT.md` (id 11); **S-F**
`docs/features/_archived/hook-truth-spec/04_DEVELOPMENT.md` `:253-289`, widened at `:444-453` (**the
eight**); **S-D** `baseline.json:_qa_note_t16` (12–16); **S-E** `_qa_note_t20` (17).
**Contributing, never enumerating:** **S-C** `_qa_note_t13` — the **mirror** of S-F
(`_archived/hook-truth-spec/07_DELIVERY.md:72`), lossy per E-28, and the text R-12 excises; and
`_qa_note_t17`, a partial restatement of ids 1/8/9 (K-18). Adjudicating:
`guard-cmd-chain/07_DELIVERY.md:115-120`; `_qa_note_t12` carries no obligation.
**Total: 17 + 8 = 25** (BC-2). Security marks: ids 3, 10, 12, 13 only (K-11).

| Id | Enumerating span |
|---|---|
| 1–7 | S-A, one obligation per span, in order: `:467-469`, `:470-473` (figure amended — K-12), `:474-478`, `:479-482`, `:483-486`, `:487-490`, `:491-492` |
| 8 | S-A `:830-836` amended by `:1230-1233` — K-13 |
| 9 | S-A `:837-838` amended by `:1234-1235` — K-14 |
| 10 | S-A `:1236-1238` |
| 11 | S-B `:662-676` (the blockquote); `hook-truth-verify-scope/07_DELIVERY.md:122` names it only |
| 12 | S-D `(12) upgrade-project.ps1 — SECURITY-RELEVANT:` … `…(fail-CLOSED).` |
| 13 | S-D `(13) migrate-scripts-layout.ps1 — SECURITY-RELEVANT:` … `…on the settings file this flow wrote.` |
| 14 | S-D `(14) verify_all.ps1 F.2 containment:` … `…and 32/0/0 on the reordered template.` |
| 15 | S-D `(15) test-init.ps1:` … `…only if that run moves the number.` |
| 16 | S-D `(16) Parse-only sweep:` … `…-> 90, unchanged.` |
| 17 | S-E `(17) archive-task PowerShell surface:` … `…the driver twins parse them accordingly.` |

### 4.1 The eight, re-issued from the enumerating source (BC-1)

Each row's `Action` / `Artifacts` / `Pass observable` is the **union** of the S-F span and whatever the
mirror adds (R-4). `Mirror` is the per-ordinal verdict AC-3 requires: **matches** = every token of S-F's
statement present in S-C; **differs↓** = present but narrower; **differs↕** = narrower in one place,
wider in another; **silent** = absent from S-C. Transcribe the span, not the abridgement.

| Id | S-F span | Statement (abridged) | Mirror | Only the mirror carries |
|---|---|---|---|---|
| T13-1 | `:255-256` | `[…Language.Parser]::ParseFile` on every touched `.ps1`: `hook-spec.ps1` (**template + repo**), `install-hooks.ps1` (**template + repo**), `test-init.ps1`, `sync-self.ps1`, `verify_all.ps1`; `:283-284` adds `install-hooks.ps1` (template + repo) to this sweep | **differs↓** — drops both `(template + repo)` scopes and the full type name | `on Windows run` |
| T13-2 | `:257-258` | `pwsh -File .harness/scripts/install-hooks.ps1` in a clone with `.claude/settings.local.json` deleted — **exit 0, file created with the Windows byte-forms, FR-12 report, idempotent re-run**; `:284` requires re-running it after the rework-2 patch | **differs↓** — keeps the run, drops the invocation form and **every** pass observable | — |
| T13-3 | `:259-261` + `:449-450` | `test-init.ps1`: confirm `Test-HookSpec` and `Test-InstallBootstrap` green, **then** reconcile `test_init_ps_assertions` (pinned **316**, deliberately unreconciled) and only then move the README `test--init-316%2F316` badge; **both READMEs move together**; widened: one more driver row, `Test-InstallBootstrap` = **32** `Assert`s per twin, the number to reconcile against | **differs↓ (split)** — the run sits at mirror ordinal 3 fused with T13-4, the reconcile tail is promoted into mirror ordinal 5; drops both `Test-*` names, `316`, the badge token, "Both READMEs move together" | the second FC-4 row's detail: `test-init.ps1:1223-1252`, stub answers `tools` with the guard id four times, asserts exit 4 + target ABSENT + the `expected 4 DISTINCT hook events, got 1` diagnostic, bash twin proven load-bearing by deletion mutation, PS twin NOT |
| T13-4 | `:262-263` | `verify_all.ps1` hard-parses the generated `settings.local.json` with `ConvertFrom-Json` (**advisory A-8**) where the bash twin only greps — the only place a malformed generated file surfaces | **differs↕** — drops the `A-8` handle | the gloss `so a file byte-valid to bash can still FAIL there` |
| T13-5 | `:264-266` | **AC-10 cross-shell byte-identity** of the generated `settings.local.json` **and of the generated pre-commit hook** is unproven until T13-2's step runs and the bytes are **`cmp`-compared against the bash twin's output on the same host** | **silent** — absent since T-13 (E-28); still binding per S-F `:452-453`; carried **in force** (PM ruling on G-11); the delivery names it (R-2, AC-4) | — |
| T13-6 | `:267-275` + `:450` | (m-3) `test-init.ps1:1073,1120,1161,1180,1215,1246,1256` — **seven** `& pwsh … 2>&1` native-command captures under script-scope `$ErrorActionPreference = "Stop"`; `$PSNativeCommandUseErrorActionPreference` governs exit-code→error, **not** stderr→`NativeCommandError`; rows `:1161` (exit 3), `:1215` (exit 4, arity), `:1246` (exit 4, distinct events), `:1256` (exit 1) drive the installer's stderr paths; **confirm the driver reaches its own `=== Result ===` line — if it does not, wrap those captures so stderr cannot raise**; widened: site list 6 → **7** | **differs↕** — drops the four per-row exit-code annotations, the remedy clause, and the `(m-3, rework 1 … CR r-7 / QA n-8)` provenance | `SEVEN sites, re-enumerated from the current file in QA rework 3 - the round-2 and round-3 insertions shifted the tail twice and added one` |
| T13-7 | `:276-279` | (m-4) `test-init.ps1:1140` `Get-ChildItem -Filter "settings.local.json.*"` uses the Win32 wildcard engine, whose legacy `name.*` semantics differ from the bash twin's `find -name` (**`test-init.sh:938`**); the target is now excluded by exact name (**DEV-7**), **making the twins equivalent by construction** — confirm the AC-6 **sibling** row is green on Windows | **differs↓** — drops the bash-twin citation, the `DEV-7` handle, the equivalence clause, `sibling` | — |
| T13-8 | `:280-289` + `:450-451` | the four-distinct-events gate **`install-hooks.ps1:245-259`** and **both** FC-4 rows — **`test-init.ps1:1190-1221`** (arity) and **`:1223-1252`** (distinct events) — are new PS code only the bash twins were executed for; include `install-hooks.ps1` (**template + repo**) in T13-1's sweep and **re-run T13-2 after this patch**; confirm `Sort-Object -Unique` is case-insensitive (stricter, never looser — **bound n-11**), that the diagnostic uses `-f` because `-join` binds **looser** than `+` so **`"a" + $n + ($x -join ' ')`** would re-associate, and that `Test-InstallBootstrap` is **32** `Assert` calls; widened: the gate's PS-side coverage is now two rows | **differs↕** — drops all three line spans, the `n-11` handle, the worked `-join` example, the `(template + repo)` scope, and `Eighth and last — no ninth` | the `$nDistinct` byte-form `@($wired \| ForEach-Object { $_.event } \| Sort-Object -Unique).Count`; `never Out-String, which re-wraps at the host buffer width`; the array-joined capture; and the whole **KNOWN BOUNDS (i)/(ii)** paragraph (K-16) |

**K-46 · The mirror's ordinals are wrong, provably without counting.** S-F `:452-453` partitions its
own set — "Items 1, 2, 4, 5, 7 are unchanged and still binding" against the widened 3, 6, 8 — total and
consistent under S-F, self-contradictory under the mirror's ordinals, because item 3's widening is
expressly the reconcile target (S-F `:288-289`, `:449-450`) that the mirror holds at its ordinal **5**,
which the same sentence calls unchanged. Derived in `02_RATIONALE.md` §R-mirror. R-6 restores S-F's
ordinals; that restoration is explicitly not a renumbering.

**K-11 · The security set is closed at four, corroborated not derived.** Ids 3 and 10 from
`guard-cmd-chain/07_DELIVERY.md:116`; ids 12 and 13 from S-D, which marks each `SECURITY-RELEVANT` and
records "its security-marked count from 2 to 4". 2 + 2 = 4 = E-12. Every other entry, **including all
eight `T13-*`**, carries `Security: no`. Losing one is a B-13 defect.
**K-12 · Id 2's figure.** `81` is **superseded by 87** and restated nowhere (R-5). Authority:
`guard-cmd-chain/07_DELIVERY.md:118-120` ("**The correct figure is 87.**"), corroborated by
`_qa_note_t17`. Entry 2 keeps every other token — both invocations (plain, and
`-Guard <template-path>`), the pin instruction, and "The key is deliberately absent today — do not
invent one", which is **not** a fingerprint token (K-44).

**K-13 · Id 8's amendment.** Transcribe the round-3 amendment verbatim (`$redirIdx` initialised to
**`-2`**, not `-1`; confirm the literal is an `[int]` and `if ($redirIdx -eq ($i - 1))` an integer
comparison) and carry forward from round 2 the initialised-before-the-scan-loop requirement, the
fail-open / over-block directionality sentence, and all three round-2 probes (`echo a\>& rm -rf C:\x`
→ 2, `echo a\<& rm -rf C:\x` → 2, `echo a>& rm -rf C:\x` → 0), plus the two round-3 probes
(`& rm -rf C:\x` → 2, `pwsh -c "& Remove-Item -Recurse C:\Windows"` → 2). Five probes total.
**K-14 · Id 9's figure.** `85` is superseded by **87** and is not restated. Entry 9 reads the round-3
amendment: re-run at 87 rows (`R4`/`R5` new), pin `test_guard_rm_ps_assertions` from that run, the key
is still deliberately absent.

**K-15 · The widening is allocated sentence by sentence, never duplicated.** It is stated twice — S-F
`:444-453` and the mirror's `WIDENED in QA rework 3` span — and R-4 makes each entry carry the union. A
sentence naming more than one of 3/6/8 is transcribed **once**, into the lowest-numbered entry it
names; the others end their `Action` with `see T13-<n>`, a pointer inside the same document (R-3
holds). Second FC-4 row `test-init.ps1:1223-1252` → **T13-3**; seventh `& pwsh … 2>&1` capture (`:1246`)
and `Test-InstallBootstrap` = 32 `Assert`s → **T13-6** (that count also feeds T13-3's reconcile
target); `Sort-Object -Unique` case-insensitivity, record-only → **T13-8**.

**K-45 · Disposition of the widening's lead-in clause (BC-3).** The clause
`WIDENED in QA rework 3 (this adds NO ninth item - it widens items 3, 6 and 8):` is R-12 **kind 3** —
historical narrative that "already has a permanent home in that task's archived stage documents",
namely S-F `:444-453`, which states it verbatim. Disposition: **left byte-unchanged**, so §5 splits
`_qa_note_t13`'s excision into **two spans** and it survives between them. No unit inside any excised
span takes a fourth disposition. Neither assertion is lost — argued in `02_RATIONALE.md` §R-K45.

**K-16 · `KNOWN BOUNDS` moves with T13-8.** Bounds (i) and (ii) qualify T13-8's pass observable, so they
are transcribed into T13-8's `Action` and leave the note with the rest of the span (disposition:
**moves**). Both are independently stated in the archive — (i) at S-F `:429-432` and
`hook-truth-spec/07_DELIVERY.md:73`, (ii) at S-F `:418-419` and `07_DELIVERY.md:74` — so T13-8's
`Origin` cites all four spans. Alternatives: `02_RATIONALE.md` §R-K16.

**K-17 · For ids 12–17 the note value is the enumerating source.** `_qa_note_t16` / `_qa_note_t20`
enumerate `(12)`–`(16)` and `(17)` explicitly and are the text R-12 excises, so they are what R-4
measures losslessness against. `hook-truth-derivation/02_SOLUTION_DESIGN.md:1072-1084` carries a longer
round-1 variant of 12–14, corroborating only — **do not import a detail from it**, that risks
reinstating a statement the note already amended.
**K-18 · For ids 1–11 and for the eight, the archive is the enumerating source.** No note carries the
text of 1–11 (E-4); `_qa_note_t17`'s restatement of 1/8/9 is a strict **subset** of the archive spans
(it omits the template twin at S-A `:467`), adding no token and creating no id. R-4 extends the rule to
its harder case: **where the note is itself a mirror of an enumeration, the enumeration governs even
though the note carries text**. Item 11's full five-leg text is at S-B `:662-676` (verbatim per
`05_CODE_REVIEW.md:170`), so **zero** entries take B-2's `text not located`; the delivery states `0`.

**K-20 · JSON-escape level.** Text taken from a note lives inside JSON strings, so `\"command\"`,
`C:\\Windows` and `{\"tool_input\":…}` are **escaped forms**; the ledger is Markdown, so transcribe the
**unescaped** value. Text from an archived Markdown document is already unescaped. AC-5 compares
unescaped forms both sides. Wrap every path and command literal in backticks.

## 5. Excision plan for `.harness/scripts/baseline.json`

**K-21 · Method.** Every edit is an exact-string replacement inside an existing string value. Never
regenerate, re-serialise, reflow, re-indent or reorder keys. The file stays **31 lines** (V-14); all
changes are intra-line. No key is added or removed.
**K-22 · Step 0, before any edit.** `cp .harness/scripts/baseline.json /tmp/t24_baseline_pre.json`. The
working tree already carries this file as modified, so `git show HEAD:` is **not** the pre-task state
and must not be used as AC-8's reference.

| Note | Excised span (start anchor → end anchor) | What stays around it |
|---|---|---|
| `_qa_note_t13` **span A** | `MANDATORY operator steps (NFR-5):` → `…renders correctly.` | before: `…green-by-symmetry-only.` · after: the K-45 clause, byte-unchanged |
| `_qa_note_t13` **span B** | `test-init.ps1:1223-1252 is a SECOND FC-4 row,` → end of value (through `…not in the installer.`) | before: the K-45 clause, byte-unchanged |
| `_qa_note_t16` | `(12) upgrade-project.ps1 — SECURITY-RELEVANT:` → `…-> 90, unchanged.` | before: `…green-by-symmetry ONLY.` · after: `The PS assertion pins and both README PS badges stay FROZEN…` |
| `_qa_note_t17` | `The PS surface is on the standing operator list:` → end of value | everything before, ending `…phantom-key trap of insight 2026-07-31.` |
| `_qa_note_t20` | `(17) archive-task PowerShell surface:` → `…the driver twins parse them accordingly.` | before: `…are NOT renumbered, reconciled, re-read or edited.` · after: `Only after (a)-(e) may a PowerShell tally be recorded…` |
| `_qa_note_t12` | — | byte-unchanged (E-7) |

**K-23 · What deliberately stays (R-12 kinds 2 and 3).** Pin-writing constraints stay in band with the
keys they constrain: `TRANSCRIBED … never derived arithmetically` (t20, t17); `CORPUS FLOOR (do NOT
re-baseline it upward)` (t20); `There is deliberately NO test_archive_task_ps_assertions key … Do not
invent one` (t20); the same for `test_guard_rm_ps_assertions` (t17); `test_init_ps_assertions stays 316
and is UNRECONCILED` (t13); `The PS assertion pins and both README PS badges stay FROZEN and move only
together … never separately` (t16); `Only after (a)-(e) may a PowerShell tally be recorded, transcribed
from THAT run.` (t20). Historical narrative — round histories, label-set corroboration, the t13
`ARCHIVE CORRECTION`, the two `NEW NUMBERED …` sentences, **the K-45 clause** — is left byte-unchanged.

**K-24 · Replacement clause per edited note (OQ-5).** **One** sentence per edited note. It **must**
contain the literal `.harness/operator-obligations.md`; **must** say the obligation is written there
and not here; **must not** contain any digit, obligation id, count, `"` or `\`. For `_qa_note_t20` it
**must additionally** name `(a)-(e)`, the antecedent the next kept sentence opens with. For
`_qa_note_t13` the single clause replaces **span B**, sitting immediately after the K-45 clause's colon
which supplies its lead-in; **span A** is replaced by nothing, since a second clause would restate the
same pointer twice in one value. Wordings: `02_RATIONALE.md` §W.

**K-25 · The in-band statement (R-9).** Append **one sentence** to the existing `"notes"` value at `:5`,
changing no other key: the file pins numeric baselines only, and a standing operator obligation is
written in `.harness/operator-obligations.md`. No new key — nothing for a consumer to trip on — and `:5`
sits above every numeric pin, so an editor meets it first. The four K-24 clauses are the same statement
at the point of temptation; together they satisfy AC-9's first conjunct.

**K-44 · The fingerprint-token set AC-1 searches (BC-4).** A **fingerprint token** of an obligation is
a literal string satisfying all three of: (1) it appears in that entry's `- Action: ` or
`- Pass observable: ` field; (2) it is at least three words long, or a path / command / identifier
literal unique to that obligation; (3) it appears **nowhere** in K-23's keep-list and in no unit K-23
or K-45 leaves byte-unchanged. Clause 3 is the definition BC-4 requires: a unit R-12 classifies as
kind 2 or kind 3 is by construction **not** a statement of an obligation, so it cannot be an
obligation's fingerprint even when an entry transcribes it inside a longer span (K-12); argued in
`02_RATIONALE.md` §R-K44. Binding exclusions, non-exhaustive: `Do not invent one` / `do not invent
one`, `deliberately absent today`, `deliberately NO`, `CORPUS FLOOR`, `do NOT re-baseline`,
`TRANSCRIBED`, `UNRECONCILED`, `stay FROZEN and move only together`, `Only after (a)-(e)`,
`ARCHIVE CORRECTION`, and the K-45 clause. AC-1 and V-6 are jointly satisfiable in one run because the
two sets are disjoint by this definition. **K-26 · Over-excision is checked, not assumed:**
§11 runs both the absence probe (AC-1, V-5, over K-44 tokens only) and the **presence** probe over
K-23's anchors plus the K-45 clause (V-6).

## 6. Writer duty, lookup, memory (R-10, R-11, R-14, R-15)

**K-27 · One contract carries R-10: `agents/qa-tester.md`.** Grep over `agents/` for `baseline\.json`
returns exactly two files: `qa-tester.md:28,83,88,155` and `developer.md:42`, and the latter names
`scripts/verify_baseline.json`, a different artifact. Add the duty at `:28`, where the pin file is
already named as a stage output, extending item 4 with a second sentence: a standing operator
obligation is written in `.harness/operator-obligations.md`, never in `baseline.json`, appended with
the next unused id, never renumbering an existing one. Budget ≤3 lines.
**K-28 · The edit governs no dispatched run until publish.** A dispatched sub-agent loads the
version-scoped plugin cache, not the working-tree `agents/*.md`. AC-9's second conjunct is verified by
**reading every `agents/*.md`**, never by observing a QA run. K-25's in-band statement is the lever
that works immediately, because `baseline.json` is read from the tree.

**K-29 · The three lookup lines.** One line each, naming the ledger and what it holds: `AI-GUIDE.md` —
the `**Memory layer**:` list `:36-40` (`G.4` rows 1–2; **B-9 binds here**);
`.harness/rules/40-locations.md` — `## What lives where`, after `:16` (`G.4` row 5; its `(32 checks` at
`:29` is untouched); `docs/dev-map.md` — the `.harness/` tree block beside `rejected-decisions.md`
`:85` (`G.4` rows 3–4). `E.4b`'s reverse arm reads **only** `AI-GUIDE.md` (`verify_all.sh:248-252`; PS
twin `:239`), so B-9 binds the `AI-GUIDE.md` line alone: no `.harness/rules/…md` path on it; the same
prohibition extends to the other two as a cheap uniform rule, not because a check reads them. No line
may carry a check-count-shaped token (B-10); no gated cap measures `docs/dev-map.md`. *(K-30/K-31 were
folded here during drafting, K-5 into K-4 and K-19 into K-18 in round 2; all retired, none reused.)*

**K-32 · `.harness/rejected-decisions.md` (R-14).** One new record, handle `obligation-prose-gate`,
marked **declined**, stating **the four candidate mechanisms that were tested** and why each fails or is
declined — including mechanism 4, which adds **no check id** — the design lever replacing them, and the
**re-surface condition**: an obligation landing in the pin file again after this change, observed by the
anti-entropy sweep (`skills/harness-deflate/`, cadence `.harness/scripts/entropy-cadence.{ps1,sh}`) that
produced EP-002. Its stated count is **four**, matching §9 (AC-12, BC-6; round 1's "two" was G-9).

**K-33/K-34/K-35 · Three bounded edits.** Nothing is appended to `## entropy-findings-store`: that
file's rule is "one record per concept", and R-8 is a field on an entry in its only home, not a
standalone findings store. `CHANGELOG.md` gets one bullet under the **existing** `## [0.46.0]` heading
— no new version heading, no version stamp moved, no README badge touched (AC-11, `G.3`).
`.harness/rules/70-doc-size.md` gains no caps row: its `templates/common/` twin is hand-aligned with no
gate catching divergence and the ledger is dogfood-only, so the ledger's own header carries the
statement instead (K-3).

## 7. Flow

```
WRITE  writer editing baseline.json ──→ meets K-25 at :5 / a K-24 clause at the note ─┐
       QA stage (post-publish) ──────→ agents/qa-tester.md:28 names the ledger ───────┤
                                   .harness/operator-obligations.md (append, next id) ◀┘
FIND   AI-GUIDE.md memory line · 40-locations.md row · dev-map.md tree line ──────────▶│
RUN    execute entries in order · record `- Last discharged:` per K-4a · count with K-6
```

## 8. Binding design keys — risk mitigations

**K-36 · Silent obligation loss (the defect this row exists to close, and the one that fired).** The
developer transcribes from §4's map only. QA re-derives the id set **independently, from the seven
source spans of E-6 across four files — S-F included** — never from the developer's list (AC-3, AC-5).
The decisive instrument is **not** arithmetic: the mirror's drop was compensated by a split, so the
count was right while the membership was wrong, and **no count-based check can detect this class of
loss**. AC-3's per-ordinal verdict bears the weight (§4.1 expected, V-15 the re-derivation); AC-4's
`= 25` and K-11's `4` are backstops for a *different* failure, an entry simply omitted.

**K-37 · The count command counts itself or an example.** K-7 plus AC-4 run on the real file.
**K-38 · JSON breakage (B-7).** K-21 (exact-string replacement only), K-24 (no `"` and no `\` in
replacement text), and V-3's parse proof, run before `verify_all`.

**K-39 · Over-excision — a kept unit leaves with an obligation.** K-23's keep-list, K-45's retained
clause, and V-6's **presence** probe over both. A dangling antecedent is the instance K-24's
`_qa_note_t20` clause repairs; the K-45 clause's colon is the second.

**K-40 · `I.6` FAILs on transcribed text (B-8).** The ledger is scanned at FAIL severity
(`verify_all.sh:742` iterates `git ls-files`; exemptions at `:666-679` do not cover it). All 14 banned
entries key on retired `CLAUDE.md` composition/regeneration claims, `harness-adopt` scaffolding, or
`全程 中文`; no source span mentions any. Only a run proves it (RES-5); if it fires the fix is at the
ledger, never at the banned list — §9's mechanism 4 gives both reasons.
**K-41 · A WARN is a hard failure.** `verify_all` exits **1** on `warns > 0` (`:933`). Every capped
file touched has ≥85 lines of headroom (§13); `agents/pm-orchestrator.md` is not touched.

**K-42 · A stale-looking reference survives the move, deliberately.** `_qa_note_t16` / `_qa_note_t20`
still say "items 1-16 … are NOT renumbered" and "taking the numbered standing list from 11 to 16", and
`_qa_note_t13` keeps the K-45 clause: historical narrative about what those tasks did, **left
byte-unchanged** (R-12), not pointers a reader must resolve. Correcting them would be pruning, which
§3.6 forbids — the same disposition K-45 applies, uniformly across all three notes.
**K-43 · The consumer audit is not certified total.** V-11 re-derives it with two differently-blind
instruments and states the form. BC-9: the hidden-inclusive form must be **executed** and stated before
AC-7 is claimed.

## 9. Open-question rulings

| OQ | Ruling | Ground |
|---|---|---|
| OQ-1 | **adopt** `.harness/operator-obligations.md` | verified against `I.1`–`I.5`, `E.1`, `E.2`, `E.4b`, `F.1`, `G.4`, `A.1`, `I.6` line by line (K-1); two un-mapped `.harness/`-root Markdown siblings are the precedent (K-2) |
| OQ-2 | **adopt** origin-qualified ids, **with K-9**: 1–17 bare, the eight take **S-F's** ordinals | every individual-ordinal citation of the eight lives inside S-F and resolves under S-F's numbering; K-46 shows the mirror's numbering contradicts S-F's own partition sentence. A prefix on 1–17 *would* break four live citations |
| OQ-3 | **adopt** one re-armable `- Last discharged: ` field, in K-4a's form | the `entropy-findings-store` decline rests entirely on re-derivability; at most 4 of 25 leave any artifact, and even those cannot distinguish "run against current bytes" from "run once, then the artifact changed" (E-11). The decline's shape constraint — no separate file, no lifecycle, no read/write cycle — is obeyed (K-33) |
| OQ-4 | **adopt** R-12's three-way rule, **totally** | K-23 enumerates the keep-list; K-45 disposes of the one unit round 1 left unclassified; the ~11 KB narrative residual is stated, not hidden |
| OQ-5 | **adopt**, constrained by K-24 | plus the `_qa_note_t20` antecedent repair and the two-span `_qa_note_t13` excision K-45 forces |
| OQ-6 / OQ-7 | **adopt** `agents/qa-tester.md` only; the convenience index stays untouched | grep-verified sole hit (K-27), K-28 adding the publish-lag consequence; §3.2, with the delivery stating the index's removal as an operator action (AC-13) |
| OQ-8 | **adopt** — no check added — **four mechanisms weighed, one adding no check id** | below |

**OQ-8, argued through (BC-6).** Four mechanisms were tested; 1–3 add a check id, 4 does not.

1. *Length*, pin-file side ("no `_qa_note_*` value exceeds N characters") — implementable, and it fires
   on the kind-3 narrative R-12 deliberately keeps (all four notes stay multi-KB post-change), so
   passing it forces a deletion §3.6 forbids. Fails on measurement, not taste.
2. *Imperative verbs*, pin-file side (ban `must` / `confirm` / `expect` / `run` inside `_qa_note_*`) —
   fails decisively: the text K-23 **keeps** is itself imperative ("Do not invent one", "do NOT
   re-baseline it upward"). Kind 1 and kind 2 are lexically indistinguishable and R-12 is a semantic
   split, so no lexical matcher implements it — the disjointness K-44 relies on, from the other side.
3. *Ledger-side* ("ids are unique") — this one **does** have a mechanical form, so a blanket "no
   predicate exists" claim would be too strong. Declined on three grounds: R-16 binds the count at 32;
   it guards a different failure (duplicate id, not homeless obligation); and 32 → 33 cascades through
   `G.4`'s eleven sites plus `CONTRIBUTING.md:22`, the ungated twelfth site EP-003 names.
4. **An `I.6` banned-list entry — adds no check id.** `i6_banned` is a data-driven array
   (`verify_all.sh:640-655`), the scan walks every tracked file via `git ls-files` (`:742`), and
   `baseline.json` is tracked and unexempted (`:666-679`), so an added record costs no `step` call and
   the count stays 32 — grounds 1–3 all quantify over adding a check id and none of them reaches it.
   Declined on two of its own. **(a)** `verify_all.sh:636-638` and `:673-674` record that
   `test-verify-i6.{sh,ps1}` hold a **verbatim copy** of this list, so one added record moves
   `test_verify_i6_bash_assertions` **and** `test_verify_i6_ps_assertions` (both pinned `58`,
   `baseline.json:17-18`) and the PowerShell half cannot be re-measured on this host (E-25) — it would
   manufacture a new PowerShell operator obligation inside the row whose subject is that such
   obligations cannot be discharged, and reopen `insight-prose-i6-banned-phrase`. **(b)** `I.6` has
   file *exemptions* and no *inclusions*, so any anchor sharp enough to match obligation prose in
   `baseline.json` matches the ledger too, whose entire content is that prose.

The replacement lever is two-part, both verifiable at AC-9 (K-25, K-27), and its falsifier is
**observable**: the anti-entropy sweep that produced EP-002 runs on a cadence. K-32 records all four.

## 10. Migration / rollout

Additive and fully reversible: one new file, seven edited files, no schema, no data migration, no flag,
no version stamp. Rollback is `git checkout --` on the seven edited paths plus
`rm .harness/operator-obligations.md`. No script reads the ledger (B-12) and the pin file's numeric span
is byte-preserved (AC-8), so every consumer in §0.3 of the requirement sees an unchanged shape. **Order
of work:** ledger first (so nothing is excised before its destination exists), then the excision, the
in-band statement, the five documentation edits, the declined-gate record.

## 11. Verification handed to stages 4 and 6

Run from the repo root, bash; every shell command is executable verbatim here. **V-15 carries this
row's decisive risk**: G-1's loss is count-invariant, so only the per-ordinal comparison detects it.

| # | Purpose | Command | Expected |
|---|---|---|---|
| V-1 | AC-4 count | `grep -c '^- Id: ' .harness/operator-obligations.md` | `25` |
| V-2 | AC-4 no stored total | `grep -nE '\b25\b' .harness/operator-obligations.md` | no line **claiming** a total (transcribed figures are fine) |
| V-3 | B-7 parse | `python3 -c 'import json;json.load(open(".harness/scripts/baseline.json"));print("JSON OK")'` | `JSON OK` |
| V-4 | AC-8 numeric span | `sed -n '1,24p' /tmp/t24_baseline_pre.json \| sed '5d' > /tmp/a; sed -n '1,24p' .harness/scripts/baseline.json \| sed '5d' > /tmp/b; diff -u /tmp/a /tmp/b && echo AC8-OK` | `AC8-OK` (line 5 is the K-25 edit, excluded by design) |
| V-5 | AC-1 absence, **K-44 tokens only** | `for t in 'ParseFile' 'MANDATORY operator steps' 'TWO ADDITIONAL BINDING' 'EIGHTH BINDING' 'KNOWN BOUNDS' 'SECURITY-RELEVANT' 'archive-task PowerShell surface' 'standing operator list' 'Remove-Item -Recurse' 'expected 4 DISTINCT hook events'; do echo "$(grep -c -F -- "$t" .harness/scripts/baseline.json) $t"; done` | every count `0` |
| V-6 | K-26/K-45 over-excision | `for t in 'CORPUS FLOOR' 'do NOT re-baseline' 'Do not invent one' 'TRANSCRIBED' 'UNRECONCILED' 'ARCHIVE CORRECTION' 'stay FROZEN and move only together' 'Only after (a)-(e)' 'WIDENED in QA rework 3 (this adds NO ninth item'; do echo "$(grep -c -F -- "$t" .harness/scripts/baseline.json) $t"; done` | every count `≥1` |
| V-7 | AC-6 gate | `bash .harness/scripts/verify_all.sh; echo "exit=$?"` | `PASS: 32 / WARN: 0 / FAIL: 0`, `exit=0` |
| V-8 | AC-6 check count from the run | `bash .harness/scripts/verify_all.sh \| grep -cE '^\[[A-Z]\.[0-9]+[a-z]?\]'` | `32` |
| V-9 | AC-7 mirror | `bash .harness/scripts/sync-self.sh --check; echo "exit=$?"` | `In sync.`, `exit=0` |
| V-10 | AC-7 drivers | run each of `test-init.sh`, `test-real-project.sh`, `test-supervisor.sh`, `test-verify-i6.sh`, `test-harness-upgrade.sh`, `test-language.sh`, `test-guard-rm.sh`, `test-archive-task.sh` | pinned tallies below |
| V-11 | RES-1 consumer set (BC-9) | `git grep -n -E 'baseline\.json\|_qa_note' -- .` **and** `rg --hidden --no-ignore --glob '!.git/' -n 'baseline\.json\|_qa_note'` | both forms **executed**, both stated in the report; union taken |
| V-12 | AC-10 line counts | `wc -l AI-GUIDE.md .harness/rules/40-locations.md agents/qa-tester.md agents/pm-orchestrator.md` | each under its cap; pm-orchestrator `296` |
| V-13 | AC-9 second conjunct | `grep -ln 'baseline\.json' agents/*.md` then read each hit for the ledger path | `qa-tester.md` names both |
| V-14 | K-21 intra-line proof | `wc -l .harness/scripts/baseline.json` | `31` |
| V-15 | **AC-3 per-ordinal verdict (BC-1)** | a **read**, not a command: for `n` = 1…8, read S-F `:253-289` item `n` and the mirror leg §4.1 pairs with it, then record `matches` / `differs` / `silent` **without consulting the developer's ledger** | eight verdicts reproducing §4.1 — `differs↓, differs↓, differs↓, differs↕, silent, differs↕, differs↓, differs↕`; ordinal 5 **silent**; then confirm `T13-5` exists and carries the byte-identity text |
| — | **V-10 expected tallies**, transcribed from `baseline.json` + `_qa_note_t16`, never derived | — | test-init `391`/`355` (python3-present / no-python3); test-real-project `90`; test-supervisor `46`/`45`; test-verify-i6 `58`; test-harness-upgrade `89`; test-language `39`; test-guard-rm `87`; test-archive-task `186` |

## 12. Out-of-scope clarifications

1. No `.ps1`, no script, no script pair — R-17 never fires and the ledger stays at 25 entries. No
   `sync-self` mapping, no `templates/common/` twin, no `test-init` assertion, no generated-project
   surface (§3.5; K-2 records why no gate notices).
2. `docs/concepts.md`, `README.md` and `.harness/rules/70-doc-size.md` are **not** edited (K-35;
   `rejected-decisions.md` shipped in v0.40 without an entry in either of the first two).
3. `docs/proposals/*`, `docs/features/_supervision/*` and every archived stage document are read-only
   here (S-A, S-B and S-F are cited, never edited — including S-F `:452-453`, whose partition sentence
   K-46 relies on); the ~11 KB of narrative R-12 leaves in the pin file is not pruned.
4. No obligation is discharged; every entry ships `- Last discharged: never`. No obligation is retired:
   T13-5 is carried **in force** per the PM ruling on G-11, and the delivery states that the note
   travelling to the operator has not carried it since T-13 (R-2, AC-4).
5. **Disclosed, not designed away (BC-10): the ledger becomes a new ungated restatement site for the
   check count.** Lossless transcription puts `32/0/0` into entry 7 (S-A `:491`),
   `PASS 32 / WARN 0 / FAIL 0` into entries 11 (S-B `:665`), 14 and 17, and `31/0/1` into entry 14 —
   **four** entries, not the three the gate counted. B-10 is not breached (`G.4`'s fixed eleven-file
   array, `verify_all.sh:841-853`, does not read the ledger), but the multiplication EP-003 names grows
   by four sites and R-4/NFR-4 forbid dropping the figures. Mitigation is containment plus disclosure:
   each figure sits inside quoted obligation text whose `Origin` pins the task that stated it, so a
   later check-count change makes the *obligation* stale, not the ledger wrong. RES-D8 hands the sites
   to EP-003; the ledger header and the delivery both say so.

## 13. Change ledger and cap arithmetic

| File | Lines now | Cap | Check that measures it | Post-change |
|---|---|---|---|---|
| `.harness/operator-obligations.md` | 0 (new) | **none** | no `I.*` check matches the path — K-1 names the five checked | ~340–430, ungated |
| `.harness/scripts/baseline.json` | 31 | none | — | **31** (all edits intra-line; V-14) |
| `agents/qa-tester.md` | 157 | 300 | `I.3` (`verify_all.sh:447-459`) | ≤160 |
| `AI-GUIDE.md` | **114** | 200 | `I.1` (`:421-431`) | **115** |
| `.harness/rules/40-locations.md` | **52** | 200 | `I.2` (`:433-445`) | **53** |
| `docs/dev-map.md` · `.harness/rejected-decisions.md` | 209 · 309 | none (the latter self-discipline only, per its own header) | — | 210 · ~327 |
| `CHANGELOG.md` · `CONTEXT.md` | — · 234 | none; CHANGELOG is `I.6`-exempt (`:667`) | — | +≈6 · **250** (done at stage 2, no developer action) |
| `agents/pm-orchestrator.md` | **296** | **300** | `I.3` | **296, byte-unchanged** |

**`agents/pm-orchestrator.md` arithmetic (BC-8).** 296 of 300 = **4 lines of headroom**, and this design
needs **no line there**: R-10's duty lands in `agents/qa-tester.md` alone (K-27), R-11's lookup lines in
`AI-GUIDE.md` and `40-locations.md` (K-29), nothing in the ledger's lifecycle changes PM routing, and
round 2's own new material (K-44, K-45, V-15) is stage-2/4/6 work creating no PM routing duty. Had a
line been needed the arithmetic would be 296 + 1 = 297 ≤ 300, but AC-10 requires the file
byte-unchanged; a case for a PM line is a rollback to stage 2, never a developer call.
**Line-count provenance:** `AI-GUIDE.md` and `40-locations.md` now read **114** and **52**, agreeing
with E-21; round 1's 113/51 were off by one (G-14). Immaterial to every cap; V-12 is authoritative.

## 14. Partition assignment

**No `.harness/agents/dev-*.md` exists** (directory empty; recorded at `AI-GUIDE.md:15` and in
`docs/dev-map.md`), so stage 4 runs in **single Developer mode**: no partitions are invented, no
dispatch order applies, and the work order is §10's five steps.

## 15. Residuals handed forward

| Id | Residual | Owner |
|---|---|---|
| RES-1 / RES-D2 | consumer set re-derived hidden-inclusively, form stated and **executed** (V-11, BC-9); the two search forms are differently blind, the union is what the report states, and totality is still not claimed | stage 4/6 |
| RES-2 / RES-3 | every consumer proven unbroken **by execution** (V-3, V-7 … V-10, V-14); the 24,874-character figure is upstream-measured, not re-measured here, and no post-change character count is predicted | stage 4/6 |
| RES-4 / RES-5 | ids 2, 8, 9 and T13-3/6/8 resolve an amendment and K-12 … K-16 state each resolution, but those remain readings of prose (stage 6 re-derives independently, AC-5); and `I.6` cleanliness of the transcribed text is proven only by V-7 (B-8) | stage 4/6 |
| RES-D1 | authoritative `wc -l` for the four capped/near-capped files; §13 adopts E-21's figures but they are Read-tool counts | stage 4 (V-12) |
| RES-D3 | `python3` is present per `_qa_note_t16`; if V-3 finds it absent, substitute `node -e 'JSON.parse(require("fs").readFileSync(".harness/scripts/baseline.json","utf8"))'` | stage 4 |
| RES-D4 | K-9's ordinal-citation claim was re-derived by Grep over `docs/features/_archived/` and now asserts only that no document **outside S-F and its mirror** cites an individual ordinal of the eight; hidden-inclusive re-derivation needs a shell | stage 6 |
| RES-D5 | the `agents/qa-tester.md` edit governs no dispatched run until commit → plugin publish; AC-9 is verified by **reading** files (K-28) | stage 6 + delivery |
| RES-D6 | **superseded.** The eight are no longer derived from the mirror; §4.1 reads them off S-F's explicit 1–8 enumeration with a per-ordinal verdict. What remains is V-15's independent re-read of S-F `:253-289` and `:444-453` | stage 6 (AC-3) |
| RES-D7 | E-4 understates item 11's source; its full text is at S-B `:662-676` (K-18), so no entry needs B-2 and the delivery states `0` | stage 7 |
| RES-D8 | §12.5's four check-count-bearing entries are new sites for EP-003; this row discloses them and does not resolve them | stage 7 → EP-003 |
| RES-D9 / RES-D10 | K-4a's commit-sha form is unexercised at delivery (every entry ships `never`, so the first instance is written by an operator, and no run here proves the form or the staleness command); and K-44's exclusion list is non-exhaustive, V-5's token list being its executable instance, with QA re-deriving its own per AC-5 | operator / stage 6 |

## 16. Verdict

**READY.** §4 names an **enumerating source** per id block and §4.1 re-issues the eight from S-F with a
per-ordinal mirror verdict; K-46 falsifies the mirror's numbering without counting; R-4's union rule
keeps the mirror's contributions instead of trading one loss for its reverse; K-45 gives every unit in
an excised span one of R-12's three dispositions; K-44 makes AC-1 and V-6 jointly satisfiable; K-4a
gives `- Last discharged: ` a stated form with an executable staleness predicate; §9 weighs four
mechanisms, one adding no check id, matching K-32's count; §12.5 discloses the four check-count-bearing
transcriptions. The check count stays 32, no `.ps1` is created, `agents/pm-orchestrator.md` is
untouched at 296 of 300, no obligation is retired, and every unproven claim is a named residual.
