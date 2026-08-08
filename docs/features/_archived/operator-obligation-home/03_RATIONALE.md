> Rationale portion for 03_GATE_REVIEW.md. Non-binding.

## §A — §4.1 re-derived independently, and the derivation the contract omits

The brief asked me to re-derive the eight-row map myself rather than check it. I read S-F
`:253-289` and `:444-453` and the `_qa_note_t13` value in full, and decomposed both without
consulting §4.1.

**S-F's eight** are explicitly numbered and closed: 1 `ParseFile` over five `.ps1` with `hook-spec.ps1`
and `install-hooks.ps1` scoped **template + repo** (`:255-256`); 2 the `install-hooks.ps1` bootstrap run
with four pass observables (`:257-258`); 3 `test-init.ps1` green **then** reconcile `test_init_ps_assertions`
(316, deliberately unreconciled) then the badge, both READMEs together (`:259-261`); 4 `verify_all.ps1`'s
`ConvertFrom-Json` asymmetry (`:262-263`); 5 AC-10 cross-shell byte-identity of the generated settings
file **and** the generated pre-commit hook, `cmp`-compared against the bash twin on the same host
(`:264-266`); 6 (m-3) seven native captures (`:267-275`); 7 (m-4) the `Get-ChildItem -Filter` wildcard
semantics (`:276-279`); 8 the four-distinct-events gate and both FC-4 rows (`:280-289`), closing
"**Eighth and last — no ninth.**"

**The mirror's eight** are fixed by its own labels, working backwards. `EIGHTH BINDING OPERATOR CHECK`
fixes 8; `TWO ADDITIONAL BINDING OPERATOR CHECKS from code review: (a) … (b) …` fixes 6 and 7; so the
`MANDATORY operator steps (NFR-5):` chain must occupy 1–5. That chain has four semicolon-separated legs —
ParseFile; the bootstrap run; "test-init.ps1 **and** verify_all.ps1 (gloss)"; the reconcile — so the third
leg must be two items, and the reconcile is **5**.

That is the premise K-46 rests on, and neither `01` nor `02` derives it (H-6). It also has an independent
external confirmation that no document in this row cites: S-F `:241` reads "**A-8 Carried** — operator
item **4** / `_qa_note_t13`: `verify_all.ps1:290-291` hard-parses the generated file where
`verify_all.sh:304` only greps." That sentence pins the *mirror's* ordinal 4 to the `ConvertFrom-Json`
item from inside S-F, which forces the fused third leg to split and the reconcile to land at 5 —
exactly as required. I record it here so stage 6 has a route to the premise rather than the assertion.

Laid side by side, my derivation and §4.1 agree on every ordinal, every span and every mirror-only body,
and disagree on two subscripts:

| ordinal | S-F | mirror | my verdict | §4.1 |
|---|---|---|---|---|
| 1 | `:255-256` | narrower (no `template + repo`, no full type name) **but adds `on Windows run`** | differs↕ | differs↓ ✗ |
| 2 | `:257-258` | narrower; drops the invocation form and all four observables | differs↓ | differs↓ ✓ |
| 3 | `:259-261` + `:448-450` | split across mirror 3 and 5; drops `Test-*` names, `316`, the badge token, "Both READMEs move together" **but adds the second FC-4 row's detail** | differs↕ | differs↓ ✗ |
| 4 | `:262-263` | drops `A-8`; adds the "byte-valid to bash can still FAIL" gloss | differs↕ | differs↕ ✓ |
| 5 | `:264-266` | **absent** | silent | silent ✓ |
| 6 | `:267-275` + `:450` | drops four exit annotations, the remedy clause, the provenance handle; adds the re-enumeration parenthetical | differs↕ | differs↕ ✓ |
| 7 | `:276-279` | drops `test-init.sh:938`, `DEV-7`, the equivalence clause, `sibling` | differs↓ | differs↓ ✓ |
| 8 | `:280-289` + `:450-451` | drops three line spans, `n-11`, the worked `-join` example, `template + repo`, "Eighth and last"; adds the `$nDistinct` byte-form, the `Out-String` warning, the array-joined capture, the `KNOWN BOUNDS` paragraph | differs↕ | differs↕ ✓ |

The reverse-loss check the brief asked for: I walked the mirror sentence by sentence and every
obligation-bearing body in it lands somewhere in §4.1's union. Nothing that exists only in the mirror is
dropped. Two mirror details are absent from the fifth column — "immediately after the arity check" and
"the 7-row degradation matrix re-measured" — and neither is a loss, because S-F states the first at
`:295` and the second at `:324`, `:392` and `:480`. R-4's widening did its job.

## §B — the four corrections attacked

**K-46 holds, and its verb is the right one.** The falsifier needs "**unchanged**", not "still binding":
a widened item is still binding, so only "unchanged" produces the clash. S-F `:452-453` reads exactly
"Items 1, 2, 4, 5, 7 are unchanged and still binding", and `:447-451` names 3, 6 and 8 — a total,
disjoint partition of 1–8 under S-F. Under the mirror's ordinals the widening reaches the reconcile leg,
which the partition sentence calls unchanged. §R-mirror identifies the verb correctly ("A thing cannot be
both widened and unchanged"). The claim that it is **count-free** is true in the sense that matters: it
never compares totals, and it survives even if the mirror had seven legs or nine. It is not premise-free
— it needs the mirror's ordinal 5 — which is H-6, not a refutation.

**K-45's classification is right and its ground is overstated.** R-12 gives three dispositions and applies
them in order: *moves* requires the unit to state an action a human must perform, which the lead-in does
not; *stays* requires it to constrain how a key in that file is next written, which it does not; kind 3
then requires a permanent home in the archive, which S-F `:444-451` supplies. Positive match, correct
disposition. But S-F does not state the clause "verbatim" or "word for word" (H-8) — it states the same
content in its own words, which is all R-12 asks. Against `70-doc-size.md`: the clause is one sentence,
so it is one unit under classification step 6, and K-45 is a `**K-n**` statement line, so it is contract
by row 2 with the argument correctly at §R-K45 under row 12. The disposition also does not delete the
in-tree corroboration G-4 was raised about — §5's two spans keep it, and V-6 anchors on it, which is the
part that actually binds a developer who has read the round-1 plan.

**K-44 makes AC-1 and V-6 jointly satisfiable in fact, and the definition is not circular.** I checked
each of V-5's ten tokens against the post-excision note text: `ParseFile` (t13 span A, t16 (12)–(16),
t17 trailing span, t20 (17) — all excised; `ParserError` in t12 is not a substring match), `MANDATORY
operator steps`, `TWO ADDITIONAL BINDING`, `EIGHTH BINDING` (t13 span A), `KNOWN BOUNDS` (t13 span B),
`SECURITY-RELEVANT` (t16, excised; "security-marked" is a different string), `archive-task PowerShell
surface` (t20 excision start), `standing operator list` (t17 excision start; "standing list" elsewhere is
a different string), `Remove-Item -Recurse` (t17 excised span), `expected 4 DISTINCT hook events` (t13
span B) — all reach `0`. And each of V-6's nine anchors survives: `CORPUS FLOOR`, `do NOT re-baseline`,
`Do not invent one` (twice, t17 and t20 — both immediately before their excision starts), `TRANSCRIBED`,
`UNRECONCILED`, `ARCHIVE CORRECTION`, `stay FROZEN and move only together` (t16, immediately after the
excised span), `Only after (a)-(e)` (t20's last sentence), and the K-45 clause. Disjoint in fact.
The definition is not vacuous because clause 3 quantifies over a **pre-declared** keep set, not over
whatever happens to survive the edit — under-excise and the surviving sentence is on neither list, so its
tokens stay fingerprints and AC-1 fires. That property depends on K-23's kind-3 list being read as
closed, which is BC-17.

**K-4a is acceptable and is not a latent G-7.** G-7 was the absence of a stated form for `<artifact
state>`; a form now exists, is one token, is recordable on Windows without running anything from this
repo, and reduces B-6 to `git diff --quiet`. That every entry ships `never` is the correct delivery
state, not an evasion — §3.1 reserves discharging to the operator, so an exercised instance at delivery
would itself be a scope breach. §R-K4a weighs four forms and picks the one that errs toward "re-run it",
which is the safe direction. The one place it does not reach is T13-5 (H-10), whose span names no
generator to pin.

**§9/OQ-8 did not transcribe my argument — it re-derived it and improved the record.** Round 1 supplied
the `I.6` counterexample from `rejected-decisions.md#insight-prose-i6-banned-phrase`; §9 mechanism 4
instead cites `verify_all.sh:636-638` and `:673-674` (the in-script statement that the drivers hold a
verbatim copy) and `baseline.json:17-18` (both pins at `58`), which is the primary evidence rather than
the memory record — and I re-read all of it. I also re-verified the count-neutrality claim myself:
`i6_banned` is an array of `|`-delimited records at `:640-655`, the per-entry regexes are prebuilt at
`:685-690`, the scan loop runs to `:742` over `git ls-files`, and `step "I.6"` is called exactly once at
`:744`/`:747` — so an added record genuinely costs no check id and grounds 1–3 genuinely do not reach it.
K-32 now says four and §9 lists four (G-9 closed). The decline survives on ground (a), which is
independent of the count argument; that independence is what makes it survive, and §R-OQ8 says so.

## §C — the two corrections made against the gate: both confirmed

**G-10 was short by one.** `_archived/guard-cmd-chain/04_DEVELOPMENT.md:491-492` reads "Re-run
`pwsh -File .harness/scripts/verify_all.ps1` (expect **32/0/0**) and `pwsh -File
.harness/scripts/sync-self.ps1 --check` (expect "In sync.")". Id 7 carries a check count. With id 11 at
`hook-truth-verify-scope/04_DEVELOPMENT.md:665` ("expect `PASS 32 / WARN 0 / FAIL 0`"), id 14 (`32/0/0`,
`31/0/1`, `PASS 32 / WARN 0 / FAIL 0`) and id 17 (`PASS 32 / WARN 0 / FAIL 0`), §12.5's **four** is
correct and round 1's three was wrong.

**K-9/RES-D4 needed correcting and the correction is right.** Round 1 asserted that the only ordinal
citation of the eight anywhere is the note's own widening clause. That is false: S-F cites its own
ordinals at `:264-265` ("until **step 2** runs"), `:283-284` ("item **1**'s `ParseFile` sweep", "re-run
item **2**"), `:288-289` ("in item **3**") and `:449-453`, and — the one the architect also missed —
`:241` ("operator item **4**"). Every one resolves under S-F's numbering and none resolves under the
mirror's, which strengthens R-6 exactly as claimed: adopting S-F's ordinals repairs internal references
rather than moving them. My round-1 §B row on K-9 was wrong and is withdrawn.

## §D — the 25-count and the PM ruling, re-checked not inherited

Not re-litigated, only checked for implementation. The total is 25 under S-F's decomposition because the
reconcile leg folds back into ordinal 3, so 17 + 8 = 25 whichever numbering is used — which is why no
count moves and why AC-4 cannot be the instrument. Four independent arithmetics still agree:
`_qa_note_t16`'s "19 -> 24", `_qa_note_t20`'s "16 to 17", `hook-truth-derivation/02_SOLUTION_DESIGN.md:1061-1064`'s
11 + 8 = 19, and `hook-truth-verify-scope/04_DEVELOPMENT.md:659`. The ruling is implemented in all four
places it needs to be: `01` R-2 and AC-4 (the delivery names which of the eight has not travelled since
T-13, cites the enumerating source, and states that nothing is retired), `02` §4.1's T13-5 row (carried
in force, `silent`, PM ruling cited), §12.4 and §16.

## §E — what this stage still could not establish

Every search here was the `Grep` tool (ripgrep-backed) or `Glob`, and results did include paths under
`.harness/` and `docs/features/_archived/`, so these invocations were not dot-blind — but I cannot pass
`--hidden`, and I claim no totality anywhere.

- **GR-1** — every V-row of §11 is unexecuted here; V-7, V-3, V-9, V-10 and V-14 are inspected for
  correctness of *expectation* only.
- **GR-2** — `I.6` cleanliness of the transcribed text (B-8, K-40). I re-read all fourteen banned entries
  at `verify_all.sh:640-655`; none of their anchors appears in any source span I read, and all fourteen
  key on retired `CLAUDE.md` claims, `harness-adopt` scaffolding or `全程 中文`. Only a run proves it.
- **GR-3** — the authoritative `wc -l` for `agents/pm-orchestrator.md`. My instrument shows a line 297;
  whether that is a trailing blank line or an artifact I cannot determine without a shell, and AC-10 and
  V-12 both hard-code 296. This is H-5 and BC-15, and it supersedes my round-1 "read to end of file, 296".
- **GR-4** — that no live document outside `docs/proposals/` and the archive restates an obligation's
  content. One instrument, no totality claim; this is the factual half of H-4/BC-14.
- **GR-5** — whether `07_DELIVERY.md:76`'s n-9 has any further restatement I did not find. I searched
  `docs/features/_archived/hook-truth-spec/` for `29 …Assert`, `Assert…29`, `four-tool loop` and
  `runtime rows`; the hits are `07_DELIVERY.md:76` and `06_TEST_REPORT.md:462,485-486`, and **no hit in
  `04_DEVELOPMENT.md`** — which is why S-F carries the unqualified figure and H-1 exists.
- **GR-6** — G-11's factual half is unchanged: nothing in the tree records whether the byte-identity
  obligation was ever discharged, and nothing can, which is the defect R-8 exists to close.
