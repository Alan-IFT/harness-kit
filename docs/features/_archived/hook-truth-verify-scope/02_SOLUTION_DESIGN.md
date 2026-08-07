# 02 — Solution Design — T-15 `hook-truth-verify-scope`

- **Mode**: `full` (7-stage). Upstream verdict: `01_REQUIREMENT_ANALYSIS.md` = **READY** (assessment **PROCEED**).
- **deferred-human mode**: defer, do not ask. Every residual ambiguity below carries a binding
  resolution; no `BLOCKED: NEEDS-HUMAN` item arose.
- **Binding inputs adopted as given** (not re-litigated): OQ-1 (b) · OQ-2 (b) · OQ-3 (b) · OQ-4 (a) ·
  OQ-5 (b, and (a) forbidden) · OQ-6 (b) · OQ-7 (b).
- Date: 2026-08-01 · Version target: fold into the unreleased **0.46.0** (no stamp moves).
- **Revision: round 2** (2026-08-01), responding to `03_GATE_REVIEW.md` = **APPROVED WITH
  CONDITIONS (C-1 … C-10)**. All ten conditions are folded in; see **§16 Round 2 changelog** for a
  condition-by-condition map. The architecture, assertion set, edit ledger and flow are unchanged
  from round 1 — the revisions land in the hazard list (§3.2), the symmetry statement (§3.3), one
  frozen-list basis label (§9), R-1/R-3 (§10) and the verification plan (§11).
- **Revision: round 3** (2026-08-01), responding to `05_CODE_REVIEW.md` = **APPROVED (0 CRITICAL,
  0 MAJOR)** with four **doc-only** findings routed here. **The implementation is correct and is
  shipping; nothing in round 3 changes code, and no code file is touched by this revision.** The
  four fixes are: the §3 seven-vs-"six" miscount, a **replacement AC-4 verification recipe**
  (**§3.4** — the old one was unsatisfiable), a **stated coverage residual** (**§3.5** — recorded,
  explicitly *not* fixed), and a **stated evidence budget** resolving the paste-vs-doc-size
  collision (**§11.3**). See **§17 Round 3 changelog**. Everything settled in rounds 1 and 2 stands
  and is not reopened.
- **Revision: round 4** (2026-08-01), responding to `06_TEST_REPORT.md` = **APPROVED FOR DELIVERY**
  (0 BLOCKER / 0 CRITICAL / 0 MAJOR) with two **doc-only** MINORs routed here, both against the
  **§3.3** symmetry statement: the deviation enumeration was incomplete (MINOR-1), and the recorded
  deviations shared one rationale despite unequal coverage (MINOR-2). **Nothing in round 4 changes
  code, blocks delivery, or reopens rounds 1–3** — the implementation ships as tested. Only §3.3 and
  this header change. See **§18 Round 4 changelog**.
- **Safety notice for the implementer** — before executing anything in §11, read **§11.1 Forbidden
  mutation targets**. `.harness/scripts/guard-rm.sh` is the live fail-closed `PreToolUse` hook;
  renaming or deleting it blocks every subsequent Bash tool call, including the ones that would undo
  it.

---

## 1. Architecture summary

`verify_all`'s `F.2` check stops being a two-source check (tracked repository content **plus** a
settings file selected at runtime from machine state) and becomes a **single-source check over
tracked repository content only**. The settings-file evidence-selection block — the
`settings.local.json`-then-`settings.json` fallback and the three wiring greps it drives — is
deleted from both shells; the four guard-script presence tests (A1–A4) and the three
distributed-template assertions (B0 template present, B1 placeholder, B2 hook key) remain —
**seven facts in total**, all at FAIL severity, all emitted through the **one existing `step`/`Step` call
site** so the gate's recorded-step count stays 32 and `G.4`'s eleven count claims stay valid. The
PowerShell twin is additionally restructured from throw-on-first-problem to the accumulate-then-throw
idiom its bash twin already uses, so both shells satisfy B-9. Nothing else in the gate, no guard
script, no settings file, no hook and no `.gitignore` entry is touched. The machine dimension that
`F.2` used to sample is not lost: it is owned by `/harness-status` `§0 Effective hook source`
(T-14). **Behavioural guard coverage is unchanged by this task** — the gate never asserted guard
behaviour; that coverage lives in `.harness/scripts/test-guard-rm.{ps1,sh}` over
`evals/guard-rm-cases.md` (87 rows, pinned).

## 2. Affected modules

| # | Path | Kind | What changes |
|---|---|---|---|
| 1 | `/home/alan/Programs/harness-kit/.harness/scripts/verify_all.sh` | edit | `F.2` block (`:290-334`) — delete settings-file selection + 3 wiring greps; anchor the template PreToolUse grep; relabel; rewrite comment |
| 2 | `/home/alan/Programs/harness-kit/.harness/scripts/verify_all.ps1` | edit | `F.2` block (`:276-310`) — same facts, plus accumulate-then-throw restructure |
| 3 | `/home/alan/Programs/harness-kit/.harness/rules/40-locations.md` | edit | line 42 — the one live doc line that states this check covers `.claude/settings.json` PreToolUse wiring |
| 4 | `/home/alan/Programs/harness-kit/AI-GUIDE.md` | edit | line 74 — `F.2 guard-rm wiring` → names scripts + settings template |
| 5 | `/home/alan/Programs/harness-kit/CHANGELOG.md` | edit (append inside existing `## [0.46.0]`) | one new `###` subsection |
| 6 | `/home/alan/Programs/harness-kit/CONTEXT.md` | edit (append) | one new glossary term, **Settings template** |
| 7 | `/home/alan/Programs/harness-kit/.harness/rejected-decisions.md` | edit (append) | one record: the presence-conditional machine assertion |
| 8 | `/home/alan/Programs/harness-kit/docs/features/hook-truth-verify-scope/04_IMPLEMENTATION.md` | new | stage doc; carries the pasted runs + the **one** new operator PowerShell item |

No new module, no new file under `.harness/scripts/`, no new dependency, no new check.
`verify_all.{sh,ps1}` is **not** in `sync-self`'s mirror set (the 8 mirrored pairs are
`harness-sync`, `install-hooks`, `archive-task`, `guard-rm`, `migrate-scripts-layout`,
`upgrade-project`, `language-policy`, `hook-spec` — `AI-GUIDE.md:76`, `docs/dev-map.md:181`), so
**no `sync-self` run is required and `E.1` is unaffected by the edits L1–L8**. `.harness/rules/` is
never synced (`AI-GUIDE.md:76`), so item 3 needs no sync either.

> **Scoped to the edits only.** `E.1` *is* affected during anti-vacuity mutation **M1**, because the
> mutated path (`templates/common/.harness/scripts/guard-rm.sh`) **is** a mirrored source — Mapping 5
> of `sync-self.sh:74-76`. See §11 S7 M1 (round-2 correction, condition C-2). The two statements are
> not in tension: the *edits* touch no mirrored file; the *mutation* deliberately does.

## 3. Module decomposition — the exact assertion set

The narrowed `F.2` asserts **seven facts** — A1, A2, A3, A4, B0, B1, B2 — in this order, in both
shells. This is the complete list; a developer implements it without re-deriving intent.

> **Round-3 correction (`05_CODE_REVIEW.md`, SPEC/DESIGN MINOR).** Rounds 1 and 2 said "six facts"
> above a table of **seven** rows. The table was always right; the prose word was wrong, and the
> delivery bullet in `CHANGELOG.md` ("All six assertions stay at **FAIL** severity") inherited the
> wrong number from it. Corrected here; the one-word `CHANGELOG.md` fix is the developer's, not this
> document's. **The count is seven everywhere from now on** — an internal miscount in a design is not
> harmless precisely because downstream user-facing prose copies it verbatim, which is the same
> claim-propagation defect class T-15 exists to close.
>
> The arithmetic that produced "six" is worth naming so it cannot recur: §1 described the retained
> set as "four guard-script presence tests **and two** distributed-template assertions", which drops
> **B0** — the template-presence test that gates B1/B2 and that mutation **M4** (§11.2 S7) exists to
> falsify. §1 is corrected in the same round to say **three** template assertions and seven in total.

| # | Fact | Evidence | Problem token on failure |
|---|---|---|---|
| A1 | `.harness/scripts/guard-rm.ps1` exists | file test | `missing:.harness/scripts/guard-rm.ps1` |
| A2 | `.harness/scripts/guard-rm.sh` exists | file test | `missing:.harness/scripts/guard-rm.sh` |
| A3 | `skills/harness-init/templates/common/.harness/scripts/guard-rm.ps1` exists | file test | `missing:<path>` |
| A4 | `skills/harness-init/templates/common/.harness/scripts/guard-rm.sh` exists | file test | `missing:<path>` |
| B0 | `skills/harness-init/templates/common/.claude/settings.json.tmpl` exists | file test | `missing:<tmpl>` |
| B1 | that template contains `{{GUARD_COMMAND}}` | literal substring | `<tmpl>:no_GUARD_COMMAND_placeholder` |
| B2 | that template contains a `"PreToolUse"` **JSON key** (name, optional whitespace, `:`) | anchored pattern | `<tmpl>:no_PreToolUse_block` |

B1/B2 are evaluated only when B0 holds (a missing template yields exactly one token, not three).
A1–A4 are evaluated unconditionally and independently of B*, so **all** problems accumulate into one
message (B-9). Severity is FAIL for every one of them — there is no WARN and no INFO path in this
check.

**Deleted, permanently:** the `f2_hooks_file` / `$hooksFile` selection, the
`.claude/settings.local.json` probe, the `.claude/settings.json` fallback, and the three assertions
driven off whichever file won (`no_PreToolUse`, `no_Bash_matcher`, `no_guard-rm_command`; PS:
`missing hooks.PreToolUse[]`, `PreToolUse[0].matcher`, `PreToolUse command does not reference
guard-rm`). After the change **neither shell contains any read of any settings file inside the `F.2`
block** — that is AC-4, and it is verified by inspection per the recipe in **§3.4**.

> **Round-3 correction.** The recipe rounds 1 and 2 stated here — "zero occurrences of
> `settings.local.json`, `.claude/settings.json`, `ConvertFrom-Json` between the `F.2` header comment
> and the next check" — is **withdrawn as unsatisfiable**, for the reasons in §3.4. The **criterion**
> was and remains satisfied (`05_CODE_REVIEW.md` ruling 3 verified by independent inspection that no
> settings file is opened in either shell); the *recipe* was the defect.

### 3.1 Bash — `.harness/scripts/verify_all.sh`, replacing `:290-334`

```bash
# F.2 — Guard-rm scripts and settings-template guard wiring present (v0.15+; narrowed T-15)
# TRACKED CONTENT ONLY. This check reads NO settings file — not the committed
# .claude/settings.json, not the gitignored .claude/settings.local.json. Its result is a
# function of tracked repository content, so a fresh clone and CI get the same verdict as
# the maintainer's machine. Whether THIS machine has the guard wired is a machine fact with
# no correct expression in a repository gate: the documented durable opt-out is a PRESENT
# machine-local file carrying an empty hooks object (.harness/rules/75-safety-hook.md), so
# even a presence-conditional assertion would fail a legitimate state. That dimension is
# owned and reported by /harness-status §0 "Effective hook source" (T-14). Guard BEHAVIOUR
# was never this check's job and is not affected: it is covered by
# .harness/scripts/test-guard-rm.{ps1,sh} over evals/guard-rm-cases.md.
f2_problems=""
for f in .harness/scripts/guard-rm.ps1 .harness/scripts/guard-rm.sh \
         skills/harness-init/templates/common/.harness/scripts/guard-rm.ps1 \
         skills/harness-init/templates/common/.harness/scripts/guard-rm.sh; do
    [[ -f "$f" ]] || f2_problems="$f2_problems missing:$f"
done
# The distributed settings template must carry the guard command placeholder and a real
# PreToolUse hook KEY. The key form ("PreToolUse" + optional space + colon) is required on
# purpose: the same file's _guard_hook documentation string also contains the bare word
# PreToolUse, so an unanchored match would still PASS with the hook block deleted.
tmpl=skills/harness-init/templates/common/.claude/settings.json.tmpl
if [[ -f "$tmpl" ]]; then
    grep -q '{{GUARD_COMMAND}}' "$tmpl" || f2_problems="$f2_problems $tmpl:no_GUARD_COMMAND_placeholder"
    grep -qE '"PreToolUse"[[:space:]]*:' "$tmpl" || f2_problems="$f2_problems $tmpl:no_PreToolUse_block"
else
    f2_problems="$f2_problems missing:$tmpl"
fi
if [[ -z "$f2_problems" ]]; then
    step "F.2" "Guard-rm scripts and settings-template guard wiring present" "PASS"
else
    step "F.2" "Guard-rm scripts and settings-template guard wiring present" "FAIL" "$f2_problems"
fi
```

Exactly two `step` call sites in mutually exclusive branches ⇒ **one recorded step** (FR-5).

### 3.2 PowerShell — `.harness/scripts/verify_all.ps1`, replacing `:276-310`

```powershell
# F.2 — Guard-rm scripts and settings-template guard wiring present (v0.15+; narrowed T-15)
# (same comment body as the bash twin — keep the two comments in lockstep)
Step "F.2" "Guard-rm scripts and settings-template guard wiring present" {
    $problems = @()
    foreach ($f in @(".harness/scripts/guard-rm.ps1", ".harness/scripts/guard-rm.sh",
                     "skills/harness-init/templates/common/.harness/scripts/guard-rm.ps1",
                     "skills/harness-init/templates/common/.harness/scripts/guard-rm.sh")) {
        if (-not (Test-Path $f)) { $problems += "missing:$f" }
    }
    $tmpl = "skills/harness-init/templates/common/.claude/settings.json.tmpl"
    if (Test-Path $tmpl) {
        $tmplText = Get-Content $tmpl -Raw
        if ($tmplText -notmatch [regex]::Escape("{{GUARD_COMMAND}}")) {
            $problems += "${tmpl}:no_GUARD_COMMAND_placeholder"
        }
        if ($tmplText -notmatch '"PreToolUse"\s*:') {
            $problems += "${tmpl}:no_PreToolUse_block"
        }
    } else {
        $problems += "missing:$tmpl"
    }
    if ($problems.Count -gt 0) { throw ($problems -join ' ') }
}
```

**Five PowerShell hazards this shape deliberately avoids** (PS is agent-unexecutable here; per
insight 2026-06-21 / 2026-07-31 it has shipped broken three distinct ways):

1. **`${tmpl}` braces are mandatory** in `"${tmpl}:no_GUARD_COMMAND_placeholder"`. `"$tmpl:no_X"`
   parses as a *drive-qualified variable reference* (`$tmpl:no_X`), not `$tmpl` followed by a colon,
   and silently yields the wrong string with no error. This is the same silent-wrong-string family as
   the `-join` precedence trap.
2. **`throw ($problems -join ' ')` must be parenthesized and must not be concatenated with `+`.**
   Binary `-join` binds *below* `+` (insight 2026-07-31), so `throw "F.2: " + $problems -join ' '`
   re-associates and produces a wrong message with no error.
3. **`Get-Content -Raw` must keep `-Raw`.** Without it `Get-Content` returns a string *array* and
   `-notmatch` becomes a filtering operator returning an array — truthy when any line fails to match,
   which inverts the assertion.
4. **No variable name may collide with a read-only automatic.** `$problems`, `$tmpl`, `$tmplText`,
   `$f` are all safe; do not rename any of them to `$input`, `$args`, `$host`, `$error`, `$matches`
   or `$isWindows`.
5. **No statement inside the scriptblock may emit to the pipeline — a stray emission becomes a WARN,
   which fails the gate.** (Round-2 addition, condition C-4 / gate F-4.) `Step`
   (`verify_all.ps1:19-37`) decides severity from the scriptblock's **pipeline output**:

   ```powershell
   $r = & $action
   if ($r -eq $false) { … WARN … } else { … PASS … }
   ```

   With the block as written `$r` is `$null` and `$null -eq $false` is `False` ⇒ PASS. But **any**
   statement whose value falls to the pipeline makes `$r` an *array*, at which point `-eq` stops
   being a comparison and becomes a **filtering** operator: `@("missing:x") -eq $false` returns a
   non-empty array, which `if` reads as **truthy** ⇒ **WARN** ⇒ `exit 1` (`verify_all.sh:823-825`,
   PS twin identical) ⇒ **FR-4 / AC-6 violated** — the check would report a non-FAIL severity for a
   real defect. This is the same "operator silently changes meaning when its left side is an array"
   family as hazards 2 and 3.

   Concrete rule for the developer: inside `Step "F.2" { … }` every statement must be an
   **assignment** (`$x = …`, `$problems += …`), an `if`/`foreach` whose body obeys the same rule, or
   a `throw`. Specifically forbidden: a bare `Test-Path $f` on its own line; `$problems + "…"` where
   `+=` was meant (the `+` result is discarded to the pipeline and the accumulator never grows —
   *double* bug); `Write-Output`; an unassigned `Get-Content $tmpl`. If a diagnostic call ever needs
   to run for effect, terminate it with `| Out-Null`. The shape in §3.2 already satisfies this —
   verify it still does after any edit, because the checklist, not the sample, is what gets reused.

**Reused pattern**: the accumulate-then-throw shape is copied from `E.4b` in the same file
(`verify_all.ps1:248-255`), which already does `$problems = @()` … `throw ($problems -join "…")`.

**Hand-off completeness is itself a required property.** §3.1 and §3.2 give **full bodies** in both
shells with an identical token vocabulary and identical evaluation order. The historical `-join`
defect was manufactured by handing the PS twin over as a described delta rather than as a body; do
not degrade this section to a diff when implementing.

### 3.3 Symmetry statement (FR-7)

Both shells assert facts A1–A4, B0, B1, B2 — the same set, in the same order, with the **same problem
token strings**, joined by a single space in both. The only permitted differences are language idiom
(`[[ -f ]]` vs `Test-Path`, `grep -qE` vs `-notmatch`, string accumulation vs array + `-join`) and
the framework's own rendering of a FAIL detail (`      $detail` in bash, `       $_` in PS).

**The symmetry claim, stated precisely** (round-2 narrowing, condition C-7 / gate F-5; **round-4
correction** per `06_TEST_REPORT.md` MINOR-1 / MINOR-2). For every input **the two shells agree on
verdict and on token list**, except for one characterised **class** of deviation — confined to the
regex-matched assertion B2, and reachable only by a *pathological* template that no real edit
produces.

**The class is stated by root cause, not as an exhaustive list of members** (round-4, MINOR-1).
Round 2 said "exactly **two** recorded deviations". That count was wrong: QA's 13-case differential
corpus (`06_TEST_REPORT.md` E-9) found a third member. The acceptance argument was unaffected, but a
future auditor would have trusted the count — so the closed list is replaced by the two axes that
generate it. B2's PowerShell arm is matched by the **.NET regex engine** (`'"PreToolUse"\s*:'` under
`-notmatch`); its bash arm by a **POSIX extended bracket expression** under `grep -qE`. .NET is wider
along two independent axes, and every known member is an instance of one:

- **axis (i) — case folding.** `-notmatch` is case-insensitive by default; `grep -qE` is case-sensitive.
- **axis (ii) — whitespace breadth.** .NET `\s` is `[\f\n\r\t\v\x85\p{Z}]`, which covers the line
  terminator (bash's `grep` is line-scoped) *and* Unicode separators such as `U+00A0` and `U+0085`
  that this host's `[[:space:]]` does not match under `LANG=en_US.UTF-8`.

| # | Member (axis) | Effect | Independent coverage elsewhere in the gate | Why accepted |
|---|---|---|---|---|
| S-1 | PS `-notmatch` is **case-insensitive** by default; `grep -qE` is case-sensitive — axis (i) | a template written `"pretooluse":` PASSes PS, FAILs bash | **Cross-shell only — none inside the PS gate.** Measured: a lowercase key makes **bash** `J.1` co-fire (`06` E-8 P1) — but bash `F.2` already fails there, so the co-fire is redundant exactly where it was observed. In the shell where the deviation exists, `J.1`'s membership test is `$k -notin $validHookEvents` (`verify_all.ps1:633`) and PowerShell's `-notin` is **itself case-insensitive**, so PS `J.1` accepts `pretooluse` as a valid event. The backstop is "someone also runs the bash gate", not a second check on Windows | JSON hook-event keys are case-sensitive to Claude Code itself, so such a template is **already broken upstream** — this leg carries the acceptance on its own. Forcing symmetry would mean `-cnotmatch`, which is *not* the idiom used by the file's other `-notmatch` sites — a local inconsistency traded for a case no one can reach by editing JSON normally |
| S-2 | .NET `\s` matches `\n`; `grep` is line-scoped — axis (ii) | a template with `"PreToolUse"` and its `:` on **different lines** PASSes PS, FAILs bash | **None, in either shell** (round-4, MINOR-2). Measured: the split key is still valid JSON, and bash `J.1`'s key regex (`verify_all.sh:666`) is line-scoped, so it extracts no key and passes **cleanly green** (`06` E-8 P2); PS `J.1` parses with `ConvertFrom-Json` and sees a well-formed `PreToolUse`. Only bash `F.2` catches it — **argued unreachable, with no independent backstop anywhere in the gate** | the file is machine-generated JSON with a stable formatter; splitting a key from its colon is not a reachable edit. Forcing symmetry would need `[^\S\r\n]*` in PS — a construct with its own escaping hazard in a shell that is agent-unexecutable here (R-4), i.e. more risk than it removes |
| S-3 | .NET `\s` matches Unicode separators (`U+00A0`, `U+0085`) that this host's POSIX `[[:space:]]` does not — axis (ii) | a template with a no-break space or NEL between key and colon PASSes PS, FAILs bash | **None** — same mechanism as S-2: the template stays valid JSON and the key parses, so neither shell's `J.1` has anything to report. Only bash `F.2` catches it | same as S-2, and strictly less reachable: no editor or formatter emits a no-break space inside JSON punctuation. Forcing symmetry would mean hand-enumerating a Unicode class in PS, which is more escaping risk than the case removes |

**Each member's coverage is stated on its own row on purpose** (round-4, MINOR-2). Round 2 gave S-1
and S-2 the same rationale, which let S-2 borrow a backstop it does not have. Corrected: **none of
the three has a backstop inside the PowerShell gate** — the only gate that runs where these
deviations exist — and S-2/S-3 have none in either shell. Round 2's phrase "`J.1`'s event-name list
owns key spelling" is true of the **bash** gate and false of the PowerShell one; it must not be
carried to S-2 or S-3, and for S-1 the acceptance now rests on the upstream-already-broken leg alone.
**All three verdicts are unchanged: accept, argued unreachable.** No code change follows from this
correction — it is a statement-of-coverage fix, not a coverage fix.

**What is pre-existing and what T-15 introduced** (round-4 correction). Axis (i) **is** pre-existing:
the retained B1 assertion (`{{GUARD_COMMAND}}`, matched via `[regex]::Escape` in PS and a literal
`grep -q` in bash) carries it, and so did the pre-change *unanchored* B2 (`-notmatch "PreToolUse"`).
Axis (ii) is **not** pre-existing — no pre-T-15 pattern in `F.2` contained a whitespace class at all,
so S-2 and S-3 exist *because* T-15 anchored B2. Round 2's "T-15 neither introduces nor widens them"
is corrected to that extent. This is an **accepted cost of the anchor, not a reason to revisit it**:
the anchored form is binding (R-1 / C-9), its benefit is measured — the pre-change gate did not
notice a deleted hook block and the anchored gate does (`06` E-6 M-B2, E-8 P3) — and the cost is a
class of inputs no formatter emits. bash, the **stricter** side, is not weakened by any member.

**Evidence status of this section.** The bash column is executed; the PowerShell column is
**modelled** — `pwsh` is absent from the QA host (`06:145`), and the PS `J.1` case-insensitivity
above is read from `verify_all.ps1:633` plus PowerShell operator semantics, not run. The direction
"PS accepts a superset of bash" is **observed over E-9's 13 cases, not proved over all inputs**: a
character inside this host's `[[:space:]]` but outside .NET `\s` (the C1 separators `U+001C`–`U+001F`
are the candidates) would deviate in the *opposite* direction and is not excluded by measurement. It
would be equally pathological; it is recorded so the direction is not mistaken for a proof.

**For every non-pathological input — including all four mutations of §11 S7 — the shells agree on
verdict and on byte-comparable token list.**

### 3.4 AC-4 verification recipe (round-3 replacement)

**The criterion is about *reads*, not about string occurrences.** `01_REQUIREMENT_ANALYSIS.md:164`
is binding and unchanged: *"Neither implementation contains any read of a settings file inside the
guard check — verifiable by inspection of the check's body in both shells."* Everything below is an
**operationalization** of that sentence. The sentence governs.

**Why the round-1/round-2 recipe is withdrawn.** It demanded zero occurrences of
`settings.local.json`, `.claude/settings.json` and `ConvertFrom-Json` anywhere between the `F.2`
header comment and the next check. That is unsatisfiable **against this design's own prescribed
code**, for two independent reasons:

1. **FR-6 mandates the collision.** §3.1's header comment deliberately *names both settings paths*,
   because the comment's entire value is stating which files the check no longer reads. A recipe
   counting those strings to zero forbids exactly the text another requirement compels. Trimming the
   comment to make a number look right would trade a real requirement for a cosmetic one — the
   developer's refusal to do so was correct, and this recipe is rewritten around that refusal rather
   than against it.
2. **The template path contains a needle as a prefix.**
   `skills/harness-init/templates/common/.claude/settings.json.tmpl` contains the literal
   `.claude/settings.json`, and assertions B0/B1/B2 cannot exist without naming that path. The count
   could never reach zero while the check still does its job.

**The replacement recipe — three parts, both shells, all three must hold.** Block extents: bash
`/home/alan/Programs/harness-kit/.harness/scripts/verify_all.sh:290-322` (header comment through the
closing `fi` of the `step` branch); PowerShell
`/home/alan/Programs/harness-kit/.harness/scripts/verify_all.ps1:276-311` (header comment through
the scriptblock's closing brace).

**(a) Positive — enumerate every file-touching operation and name its target.** This is the part
that actually discharges AC-4; (b) and (c) are tripwires around it. Ignore comment lines, then list
every operation in the block that can open, read or stat a file, and state its target:

| Shell | Operations to enumerate | Permitted targets — nothing else may appear |
|---|---|---|
| bash | `[[ -f ]]` / `[[ -e ]]` / `[[ -r ]]`, `grep`, `cat`, `<` redirect, `source` / `.`, any `$( … )` | `$f` (the A1–A4 loop variable, i.e. the four guard-script paths) and `$tmpl` |
| PowerShell | `Test-Path`, `Get-Content`, `ConvertFrom-Json`, `Import-*`, `[IO.File]::*`, `Select-String` | `$f` and `$tmpl` / `${tmpl}` |

Expected result as shipped — bash: four `[[ -f "$f" ]]`, one `[[ -f "$tmpl" ]]`, two `grep` whose
sole target is `"$tmpl"`. PowerShell: five `Test-Path`, one `Get-Content $tmpl -Raw`. **Zero
operations with any other target, and zero JSON-parser calls of any kind** — the block now has no
JSON-parser dependency at all. Paste both enumerations.

**(b) Negative — a string count that is actually reachable.** Count on **code lines only** (comment
lines removed) and with the template path **masked first**, so the prefix collision cannot inflate
it:

```
sed -n '290,322p' .harness/scripts/verify_all.sh \
  | grep -vE '^[[:space:]]*#' \
  | sed 's#skills/harness-init/templates/common/\.claude/settings\.json\.tmpl#<TMPL>#g' \
  | grep -cE 'settings\.local\.json|\.claude/settings\.json|ConvertFrom-Json|f2_hooks_file|hooksFile'
```

Expect **0** matching lines. Same for PowerShell with `sed -n '276,311p'
.harness/scripts/verify_all.ps1` through the identical two filters and the same pattern. Paste both
counts. (`f2_hooks_file` / `hooksFile` are added as needles because they are the *deleted machinery's*
own names — a stronger signal than the path strings, since nothing but the retired code ever used
them.)

Comment lines are excluded because **a comment cannot open a file**, and because FR-6 requires those
exact strings to be present in the comment. The template path is masked because the settings
**template** is repository content, not a settings file any tool loads (`CONTEXT.md` → **Settings
template**) — counting it as a settings read is a category error.

**(c) Inverse — assert the comment *does* name both files.** The mirror image of (b), and the reason
(b) has to be scoped to code lines. On the **comment lines** of each block, `.claude/settings.json`
and `.claude/settings.local.json` must each appear **at least once**. A future edit that "tidies" the
comment to make (b) look neater would silently break FR-6; (c) is the tripwire that catches it. As
shipped, both names sit on one line in each shell — `verify_all.sh:292` and `verify_all.ps1:278`.

**Standing rule this recipe encodes.** A recipe is a *proxy* for a criterion. **If a proxy and its
criterion ever disagree, the criterion governs, the proxy is the defect, and the implementer reports
it rather than editing code, comments or the criterion to satisfy the proxy.** This is §11.0 rule 5
("never edit the expectation to match the run") applied to inspection steps rather than to runs, and
it is exactly what happened here in round 2.

### 3.5 Stated residual — B1 and B2 assert presence, not containment (recorded, NOT fixed here)

B1 and B2 are two **independent whole-file** assertions. Neither says the placeholder lives *inside*
the hook block. A template carrying `{{GUARD_COMMAND}}` inside, say, the `Stop` hook while
`"PreToolUse": []` sat empty would satisfy both and **PASS**, under a label that reads
"settings-template guard **wiring** present". The label is therefore slightly wider than the
assertions beneath it, and must not be over-read.

This is the same entanglement mutation M3 exposed from the opposite direction: on today's artifact
the only `{{GUARD_COMMAND}}` (`settings.json.tmpl:54`) sits **inside** the `"PreToolUse": [ … ]`
array (`:48-58`), so deleting the array necessarily deleted the placeholder too — which is why M3
emitted **two** tokens where §11 predicted one. The two assertions are not independent on the real
file, and neither of them asserts that relationship.

**Not fixed in T-15, deliberately.** A containment assertion means either parsing the template's JSON
structure or matching the placeholder *within* the `PreToolUse` array's byte range — i.e. asserting
the template's guard command against the hook wiring spec. That is precisely **OQ-6(a)**, which
`01_REQUIREMENT_ANALYSIS.md:243-245` declined in favour of (b) as **T-16 `hook-truth-derivation`**
territory (`docs/batches/default/BATCH_PLAN.md:31`). Closing it here would grow the check, and T-15's
whole thesis is that this check should shrink to what the repository can answer. **No code change, no
new check (§12), no widening of B1 or B2.**

Consequences, all doc-only:

- **Delivery states it.** `07_DELIVERY.md` records this residual verbatim in substance, so the new
  label is not read as more than it asserts: `F.2` asserts the template carries the placeholder
  **and** carries a real `PreToolUse` key — **not** that the one sits inside the other.
- **T-16 inherits it.** When T-16 re-points the derivation flows at
  `.harness/scripts/hook-spec.{ps1,sh}`, the byte-form comparison it must make anyway is the natural
  place to close this. The T-16 row should carry "close the `F.2` B1/B2 containment residual" as an
  explicit sub-item rather than rediscovering it from scratch.
- **Nobody should "fix it while they are in there"** during T-15 — the same discipline R-3 applies to
  `.harness/rules/75-safety-hook.md:150-151`.

## 4. Data model changes

None. No schema, no table, no `baseline.json` key. `baseline.json` is **read-only for this task**:
`verify_all_checks` stays `32`, `test_guard_rm_bash_assertions` stays `87`, and no `_qa_note_*` is
edited.

## 5. API contracts

`F.2`'s contract is its console line and its recorded tuple `id|name|status`:

- **PASS** — `[F.2] Guard-rm scripts and settings-template guard wiring present ... PASS`
- **FAIL** — same line ending `... FAIL`, followed by an indented, space-separated token list drawn
  from the vocabulary in §3, e.g.
  `missing:skills/harness-init/templates/common/.harness/scripts/guard-rm.sh skills/harness-init/templates/common/.claude/settings.json.tmpl:no_GUARD_COMMAND_placeholder`
- **Exit-code contract of the gate is unchanged**: any FAIL ⇒ `exit 2`; any WARN ⇒ `exit 1`
  (`verify_all.sh:823-825`) — a WARN is a hard gate failure, not advisory.
- **Recorded-step contract**: exactly one record with id `F.2`. `G.4` derives the shipped check count
  as `${#report[@]} + 1` from inside its own branch and a Summary tripwire asserts `G.4` is last
  (`verify_all.sh:700-717, 806-815`). A second `step "F.2"` call, or a new check id, would make the
  live count 33 and turn **all eleven** `G.4` claim rows red at once.

## 6. Flow

```
verify_all.{sh,ps1}
  └─ F.2
       ├─ [A1..A4] four -f / Test-Path tests over tracked guard-script paths      ─┐
       ├─ [B0]     -f / Test-Path over the distributed settings template           ├─ accumulate
       │            ├─ present → [B1] literal {{GUARD_COMMAND}}                    │  problems
       │            │            [B2] anchored "PreToolUse" JSON key               │
       │            └─ absent  → single missing:<tmpl> token                      ─┘
       └─ problems empty ? step PASS : step FAIL "<space-joined tokens>"   ← ONE record

  (no branch of this flow opens .claude/settings.json or .claude/settings.local.json)

machine dimension (NOT here):
  /harness-status §0 Effective hook source → resolves C1=.claude/settings.local.json,
  C2=.claude/settings.json by precedence and reports one of
  never-installed | opt-out | installed | unknown, naming the file it read.
```

## 7. Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| Recorded step + severity + count semantics | `step()` / `Step` | `.harness/scripts/verify_all.sh:17-25`, `.harness/scripts/verify_all.ps1:19-37` | **Reuse as-is** — one call site, unchanged id |
| Four guard-script presence tests | existing `F.2` loop | `verify_all.sh:292-296`, `verify_all.ps1:278-282` | **Reuse byte-unchanged** (bash); PS loop body re-expressed as accumulator |
| Template placeholder assertion | existing `F.2` template block | `verify_all.sh:322-329`, `verify_all.ps1:306-309` | **Reuse**, with B2 anchored (§9 R-1) |
| Accumulate-then-throw in PS | `E.4b` | `verify_all.ps1:248-255` | **Reuse the idiom** — do not invent a new one |
| Multi-problem accumulation in bash | existing `f2_problems` string | `verify_all.sh:291` | **Reuse as-is** |
| Machine / effective-hook-source reporting | `§0 Effective hook source` + `§3b` guard verdict | `skills/harness-status/SKILL.md:15-73` | **Reuse — it is the new owner.** No change to it (out-of-scope 5) |
| Guard **behaviour** coverage | `test-guard-rm` driver + case file | `.harness/scripts/test-guard-rm.{ps1,sh}`, `evals/guard-rm-cases.md` | **Reuse untouched** — 87 rows, pinned; this task neither adds nor removes a row |
| Count/version claim enforcement | `G.4` eleven-row fan-out | `verify_all.sh:700-800` | **Reuse** — it is the mechanism that keeps the count honest; nothing to change because the count does not move |
| Clean-tree construction for a differential run | `git show HEAD:<path>` → scratch path + drive by argument | `baseline.json:_qa_note_t17` (T-17's pre-change measurement) | **Reuse the technique**, adapted to a `git worktree` (§11) |
| Rule-fragment doc index | `.harness/rules/40-locations.md` check list | `.harness/rules/40-locations.md:29-49` | **Reuse** — correct one line in place |

Nothing here is new machinery. No new dependency of any kind is introduced (no library, no service,
no script, no check).

## 8. Change ledger — every surface that MUST change

Verified by search on 2026-08-01, not inherited: `Grep "F\.2|PreToolUse wiring|guard-rm wiring|Guard-rm scripts"`
tree-wide (120 hits, all reviewed); `Grep "PreToolUse"` tree-wide (109 files, every non-archived hit
opened); `Grep "Guard-rm scripts and PreToolUse wiring present"` (6 files: the 2 scripts + 4 archived
stage docs); `Grep "verify_all"` over `.harness/rules/` and over `skills/**/SKILL.md`;
`Grep "verify_all_checks|32 checks|32/32|G\.4"` tree-wide; `Grep "CONTEXT.md"` over `.harness/scripts/`.

| # | File | Change | Why it is live-false / needed |
|---|---|---|---|
| L1 | `.harness/scripts/verify_all.sh` | replace `:290-334` per §3.1 | the defect itself |
| L2 | `.harness/scripts/verify_all.ps1` | replace `:276-310` per §3.2 | symmetry (FR-7) + B-9 |
| L3 | `.harness/rules/40-locations.md:42` | `- Guard-rm scripts + `.claude/settings.json` PreToolUse wiring (F.2, v0.15+; FAIL if missing)` → `- Guard-rm script pair (repo + distributed template) + the settings template's guard wiring (F.2, v0.15+; FAIL if missing; reads no settings file — machine hook state is reported by `/harness-status`)` | the **one** live doc line naming a settings file as this check's subject. Line 29's `(32 checks` claim (a `G.4` row) is on a different line and must stay byte-identical |
| L4 | `AI-GUIDE.md:74` | replace the substring `F.2 guard-rm wiring` with `F.2 guard-rm scripts + settings-template wiring` | "guard-rm wiring" reads as "the hook is wired". The `(32 checks,` literal earlier on the same line is a `G.4` row — **re-read the line after the edit** and confirm `32 checks` survives |
| L5 | `CHANGELOG.md` | append one `### Changed — hook-truth-verify-scope (T-15): …` block at the **end of the existing `## [0.46.0]` section**, immediately before the `## [0.45.0]` heading | OQ-4(a). Do **not** add a `## [0.46.1]` heading, do not edit the `- 2026-07-31` date on the 0.46.0 heading, do not touch T-17's bullets |
| L6 | `CONTEXT.md` | append one term (§8.1) | the new label coins "settings template" as distinct from "settings file"; glossary maintenance is the architect/dev's standing job (`AI-GUIDE.md:39`) |
| L7 | `.harness/rejected-decisions.md` | append one record (§8.2) | the presence-conditional machine assertion is the obvious "middle path" a future reader of the narrowed check will re-propose; recording the decline is exactly what this memory exists for (insight 2026-06-20) |
| L8 | `docs/features/hook-truth-verify-scope/04_IMPLEMENTATION.md` | new stage doc | carries every pasted run (AC-1/2/3/5/8/10) **and** the one new operator PowerShell item (§10) |
| L9 | `docs/tasks.md` / `docs/batches/default/BATCH_PLAN.md` T-15 status | PM bookkeeping at delivery only | not the developer's edit; listed so nobody else touches them |

### 8.1 CONTEXT.md append (exact)

Insert after the **Machine-local settings** entry, before **Effective hook source**:

```markdown
**Settings template**:
The tracked, distributed `.claude/settings.json.tmpl` in the common template overlay, carrying the
`{{…}}` hook-command placeholders `/harness-init` substitutes at generation time — repository
content, never a settings file any tool loads.
_Avoid_: settings tmpl, template settings, settings stub
```

### 8.2 `.harness/rejected-decisions.md` append (exact)

```markdown
## verify-gate-machine-hook-assertion
- **Decision:** declined.
- **Why:** asserting in `verify_all` that THIS machine has the guard hook wired — including the
  "assert only when `.claude/settings.local.json` is present" conditional form — has no correct
  formulation: the documented durable opt-out is a present machine-local file with an empty hooks
  object (`.harness/rules/75-safety-hook.md`), so a presence-conditional FAIL turns a legitimate
  state into a gate failure, and an unconditional one fails every clean checkout and every CI run.
  A repository gate answers repository questions; the machine dimension is owned by
  `/harness-status` §0 "Effective hook source". A "compensating" extra check was declined with it.
- **Origin:** T-15 `hook-truth-verify-scope` (OQ-2, OQ-6), narrowing `F.2`.
```

## 9. Frozen / decoy list — surfaces that must NOT change

A wrongly-flipped frozen claim is an equal-severity bug to a missed live flip (insight 2026-06-19).
Each row below was opened and read; none is edited by this task.

| Surface | Location | Why frozen |
|---|---|---|
| README 0.15.0 roadmap row | `README.md:262` | historical delivery row ("verify_all 26 → 27 (new F.2)") — a record of what v0.15.0 shipped |
| README.zh-CN 0.15.0 roadmap row | `README.zh-CN.md:264` | same, Chinese mirror |
| All historical `## [x.y.z]` CHANGELOG entries | `CHANGELOG.md:190, 714, 730, 1221, 1255-1256, 1276` | history, not claims about today |
| `MIGRATION.md:231` | v0.1→v0.2 "what changed" table | deliberately historical; its "29 checks" is already frozen-stale by design and is **not** a `G.4` row. Editing it would be the decoy bug |
| `docs/project-overview.html:733` | v0.17.0 snapshot | archival HTML |
| `docs/batches/default/BATCH_PLAN.md:36-40` | pool notes | append-only rationale recorded at queue time; note (d) "check count must stay 32" remains true |
| Every `docs/features/_archived/**` stage doc quoting the old label or the settings fallback | 20+ files incl. `_archived/resilient-hooks/*`, `_archived/ai-safety-guardrails/*`, `_archived/guard-cmd-chain/*`, `_archived/hook-truth-spec/02_SOLUTION_DESIGN.md:481` | archived stage docs record past state; also `docs/features/` is an I.6-exempt subtree precisely so it may quote retired claims |
| `.harness/insight-index.md` | all lines | describe past states / truths; T-15 appends only at archive time via the `## Insight` harvest, never edits an existing line. **PM-carried note (condition C-8, gate F-8): the file sits at exactly 30 of the 30 bullets `I.4` permits (`verify_all.sh:426-436`), and a WARN exits 1** — so the stage-7 harvest must **rotate**, not merely append. This is on the PM's stage-7 checklist; the Developer designs nothing for it and must not pre-emptively trim the file |
| **All three type-overlay `F.2`s** — `templates/{generic,backend,fullstack}/.harness/scripts/verify_all.{sh,ps1}.tmpl` | e.g. `generic/.harness/scripts/verify_all.sh.tmpl:172-179` | **decoy with a name collision**: the overlays' `F.2` is *"Rule fragments <=200 lines each"*, a completely different check. Grepping `F.2` and editing "the F.2 in the templates" would corrupt three generated-project gates. Confirmed: `guard-rm`/`PreToolUse` appear **0 times** in the generic overlay, and `templates/common/.harness/scripts/` ships no `verify_all` at all |
| `docs/dev-map.md:87, 184` | `(32 checks)`, `runs all 32 checks` | `G.4` rows; the count does not move |
| `.harness/rules/40-locations.md:29` | `(32 checks, all must PASS…` | `G.4` row on a *different line* from L3 |
| `README.md` / `README.zh-CN.md` verify_all badges, `docs/manual-e2e-test.md`, `AI-GUIDE.md:42`, `baseline.json:10` | **`G.4` count rows** (gate-protected) | count unchanged ⇒ untouched. `g4_files` (`verify_all.sh:732-744`) has exactly **eleven** entries: `AI-GUIDE.md`×2, `docs/dev-map.md`×2, `.harness/rules/40-locations.md`, `README.md`×2, `README.zh-CN.md`×2, `docs/manual-e2e-test.md`, `.harness/scripts/baseline.json` |
| `CONTRIBUTING.md:22` ("the gate currently runs 32 checks") | **review-protected, NOT gate-protected** | *Round-2 correction (condition C-6 / gate F-6): this row was previously mis-filed as a `G.4` count row. It is not — `CONTRIBUTING.md` is absent from the eleven `g4_files` entries above.* The freeze verdict is unchanged (the count does not move, so the line stays true and untouched), but the **reason** is that nothing in `verify_all` reads it: if it drifted, only human review would catch it. This distinction is exactly what §11's QA addition (i) publishes as "the honest claim", so it must be stated correctly here |
| `.claude/settings.json`, `.claude/settings.local.json`, `.gitignore` | — | NFR-1. **Mutating, renaming, emptying or deleting `.claude/settings.local.json` is FORBIDDEN** for the whole task — including temporarily, including "just to demonstrate the clean state" |
| `.harness/rules/75-safety-hook.md` | 200/200 lines — one added line is a WARN ⇒ `exit 1` | not touched at all (§10 R-3). **Also do not "fix" anything inside it** — see R-3 |
| `.harness/scripts/guard-rm.{ps1,sh}` **(live)** + template twins, `evals/guard-rm-cases.md`, `test-guard-rm.{ps1,sh}` | — | out-of-scope 2; the 87-row driver must not move. **`.harness/scripts/guard-rm.sh` and `.harness/scripts/guard-rm.ps1` additionally carry the S7 absolute prohibition** (§11 "Forbidden mutation targets", condition C-1): they are the live fail-closed `PreToolUse` hook and must not be renamed/moved/emptied/deleted **at any point**, including temporarily during anti-vacuity testing |
| `skills/harness-status/SKILL.md`, `install-hooks.*`, `hook-spec.*` | — | out-of-scope 5 |
| The 8 T-13 + 10 T-17 operator PowerShell items | `_archived/hook-truth-spec/*`, `_archived/guard-cmd-chain/04_DEVELOPMENT.md:459+` | out-of-scope 6; T-15 **appends item 11 in its own stage doc**, exactly as T-17 appended to T-13's list |
| `docs/proposals/frontier-gaps-2026-07.md` | untracked | out-of-scope 7: not read, not edited, not cited |

## 10. Risk analysis

**R-1 — the retained `PreToolUse` template assertion is vacuous as written, so B-8 would ship
unsatisfied.** `settings.json.tmpl:5` (`"_guard_hook": "PreToolUse hook auto-runs guard-rm …"`)
contains the bare word `PreToolUse`, and today's test is an unanchored whole-file match in both
shells (`grep -q 'PreToolUse'`, `-notmatch "PreToolUse"`). Delete the entire `"PreToolUse": [ … ]`
array from `hooks` and the check still PASSes — B-8 ("pre-tool hook block removed ⇒ FAIL") is false
today. *Mitigation*: assertion B2 is anchored to the JSON **key** form (`"PreToolUse"` + optional
whitespace + `:`), which the doc string cannot satisfy (its text is `"PreToolUse hook…`, quote then
space), and mutation M3 in §11 proves it load-bearing. *Scope note for the gate reviewer*: this is
**not** the OQ-6(a) widening — it does not compare the template's guard command byte-form against
the hook wiring spec (that is T-16). It makes an already-required assertion mean what its own
boundary condition says.

**Settled in round 2 (condition C-9): the anchored form IS the design; there is no fallback.** The
gate independently re-derived the claim above (reading `settings.json.tmpl:5` and `:48`,
`verify_all.sh:326`, `verify_all.ps1:309`), confirmed B-8 is false today in both shells, verified the
proposed anchor matches `:48` and not `:5`, and ruled the anchoring in scope. The unanchored variant
this document previously floated as a fallback ("ship B2 unanchored, record B-8 as knowingly
vacuous") is **withdrawn and is not an available option** — it trades one false coverage claim for
another: after the narrowing B2 is the check's *only* remaining wiring assertion, so leaving it
unanchored makes the check's new label ("settings-template guard **wiring** present") live-false at
birth, which is a direct FR-6 violation and precisely the defect class T-15 exists to close. It would
also make mutation M3 un-runnable, so AC-5 could not be discharged for B2 at all.

**R-2 — check-count drift turns eleven doc claims red at once.** Any second `step "F.2"`, any new
id, or a check inserted below `G.4` breaks the `${#report[@]} + 1` derivation and the Summary
tripwire. *Mitigation*: one call site per branch (§3.1/§3.2); the developer greps
`grep -c 'step "F.2"' .harness/scripts/verify_all.sh` (expect 2, both in the same if/else) and
confirms the summary prints `PASS: 32`.

**R-3 — `.harness/rules/75-safety-hook.md` is at exactly 200 of 200 lines and a WARN exits 1.**
One appended line fails the release gate (insight 2026-08-01). *Mitigation*: **this design touches
that file zero times** — it was read and contains no claim about `F.2`'s coverage; its "fully
disable" section (`:153-170`) describes the runtime opt-out, which stays true. The developer records
`wc -l` before and after (expect **200** both times) and confirms it is absent from
`git diff --name-only`. Both measurements are mandatory steps (§11 S0 and S11), not assertions.

**Round-2 addition (condition C-10 / gate F-9) — do not repair anything inside that file.** The gate
found a pre-existing unbacked claim at `.harness/rules/75-safety-hook.md:150-151` (it says
`verify_all` would catch a tracked file hard-coding `HARNESS_ALLOW_OUTSIDE_RM=1`; no check does —
`A.1` greps secret-shaped assignments, `F.2` never did, and `I.6`'s banned list lacks it). It is
**out of scope for T-15 and must be left exactly as it is.** The file is at 200 of 200 permitted
lines, so any repair that adds a line trips `I.1` → WARN → `exit 1` → the gate fails; and even a
line-neutral rewrite would put a frozen file in `git diff --name-only`, breaking the §11 S11
close-out and NFR-2. It is backlog for a separate task, recorded here **so that nobody fixes it while
they are in there** — which is the exact failure mode the note exists to prevent.

**R-4 — the PowerShell twin is green-by-symmetry only and has shipped broken three distinct ways.**
A parse error anywhere in `verify_all.ps1` makes the **whole gate** unloadable on Windows.
*Mitigation*: §3.2's **five** named hazards (the fifth — a pipeline emission silently becoming a
WARN — added in round 2 per C-4); the accumulator idiom is copied from an existing block in
the same file rather than invented; one new enumerated operator item (§10.1). Residual risk is
accepted and declared, not hidden.

**R-5 — the AC-2/AC-3 clean-state demonstration is the single most dangerous step in the task**,
because the shortest path to it is mutating the live `.claude/settings.local.json`, which disarms
the live fail-closed guard for the rest of the session, and because cleaning a scratch tree outside
the project root is itself blocked by the guard. *Mitigation*: §11's worktree procedure never names
the live settings file in a mutating command, keeps the scratch tree **inside** the project root
(so its removal is guard-legal without any override), and forbids `HARNESS_ALLOW_OUTSIDE_RM=1`
entirely for this task.

**R-6 — a scratch tree inside the repo root could pollute the live gate.** *Mitigation*: `I.6`
enumerates via `git ls-files` (`verify_all.sh:633`) and a linked worktree's contents are not in the
parent index, so it is invisible; every other check is path-scoped. Belt-and-braces: §11 forbids
running the live gate while the scratch tree exists, and requires `git status --porcelain` to show
no `.t15-clean` before the AC-1 run.

**R-7 — the tree carries three siblings' uncommitted work (T-13/T-14/T-17).** A scratch tree built
from `HEAD` alone would measure the wrong artifact (T-17 rewrote both guard scripts; T-13 added
`hook-spec` to `F.1`'s pair list). *Mitigation*: §11 overlays the live working tree onto the
worktree, and runs the pre-change and post-change measurements through the **identical**
construction so the only variable is the `F.2` edit.

**R-8 — describing this change as reducing guard coverage.** It does not, and prose saying so is a
defect (RA §0). *Mitigation*: the CHANGELOG block (L5) and `07_DELIVERY.md` must both state that
behavioural guard coverage is unchanged (87 rows, unmoved) and that the machine dimension moved to
the health report rather than disappearing — AC-12.

### 10.1 The one new operator PowerShell item (AC-9)

Written into `04_IMPLEMENTATION.md` under a heading `## PowerShell surface added to the standing
operator list`, following T-17's own precedent (`_archived/guard-cmd-chain/04_DEVELOPMENT.md:459-465`).
It states that the **eight T-13 items and the ten T-17 items are untouched and unreconciled**, and
adds exactly:

> **11.** `verify_all.ps1` `F.2` (T-15). (a) `[Parser]::ParseFile` over
> `.harness/scripts/verify_all.ps1` — PowerShell parses the whole file before executing, so a
> syntax error in the rewritten `F.2` block kills the entire gate on Windows. (b) Run
> `pwsh -File .harness/scripts/verify_all.ps1`; expect `PASS 32 / WARN 0 / FAIL 0` and confirm the
> `[F.2]` line prints the **new** label. (c) Confirm `F.2` PASSes with no
> `.claude/settings.local.json` present — **in a fresh clone or the scratch tree, never by moving or
> emptying the live file**. (d) Multi-problem rendering: with the template's `{{GUARD_COMMAND}}`
> removed **and** one **template** guard script renamed at the same time (never
> `.harness/scripts/guard-rm.*` — that is the live fail-closed hook), confirm the FAIL detail names
> **both** problems in one message (this is the `-join`-precedence / accumulator check) and that the
> status is `FAIL`, not `WARN`. Expect `[E.1]` to be red as well while the template script is
> renamed — that is the mirrored-pair co-fire, not a defect; do **not** run `sync-self` in write mode
> to clear it. Restore both by renaming/editing back. (e) Confirm the `[F.2]` line never prints
> `WARN`: a WARN here would mean a statement in the block leaked to the pipeline (§3.2 hazard 5), and
> WARN exits 1.

## 11. Verification plan (developer + QA)

### 11.0 Hard rules — read before executing any step

These bind **every** step below, including the anti-vacuity mutations. Two of them are prohibitions
of equal, safety-critical rank; both were strengthened in round 2 (conditions C-1, C-5).

1. **NEVER touch `.claude/settings.local.json`** — no rename, move, edit, empty or delete, not even
   temporarily, not "just to show the clean state". It is the live hook wiring (NFR-1).
2. **NEVER touch `.harness/scripts/guard-rm.sh` or `.harness/scripts/guard-rm.ps1`** — no rename,
   move, empty or delete, at **any** point, including as an anti-vacuity mutation. See §11.1.
3. **NEVER set `HARNESS_ALLOW_OUTSIDE_RM=1`** for any command in this task.
4. **NEVER run `sync-self.sh` in write mode (i.e. without `--check`) while any mirrored source is
   renamed away** — it would copy the *absence* onto the live path. See S7 M1 (condition C-2).
5. **Every tally, verdict and summary block is pasted from the run that produced it — never derived,
   never predicted, never reconstructed arithmetically** (insight 2026-07-31). Where this document
   states an expectation, it is a *prediction to be compared against the paste*, not a substitute for
   it. **If a run disagrees with a stated expectation, record the run and report the discrepancy —
   never edit the expectation to match, and never edit the run.**

### 11.1 Forbidden mutation targets (condition C-1 / gate F-2) — safety-critical

Assertions **A1** and **A2** of §3 are **forbidden mutation targets**. Do not rename, move, empty or
delete `.harness/scripts/guard-rm.ps1` or `.harness/scripts/guard-rm.sh` for any reason, at any point
in this task.

**Why this is not merely a style rule.** `.claude/settings.local.json:22` wires `PreToolUse` →
`sh -c '… bash .harness/scripts/guard-rm.sh'`, and `:4` records that the wiring is **fail-CLOSED** —
there is no exit-0 fallback, so a **missing guard script blocks the Bash tool call itself**
(`.harness/rules/75-safety-hook.md:176` states the same). Renaming or deleting that script therefore
**seizes the entire Bash toolchain for the rest of the session**: no `mv`, no `git checkout`, no
`bash verify_all.sh` — because each of those *is* a Bash tool call and each is blocked by the very
hook whose script you removed. Recovery is **Read + Write only** (insight 2026-08-01), i.e. hand
re-creating a 900-line script from memory. This is the single most expensive recoverable mistake
available in this repository.

**Why one mutation is sufficient — do not generalise.** A1–A4 are not four independent
implementations; they are four iterations of **one loop body** (`verify_all.sh:292-296` /
`verify_all.ps1:278-282`, preserved verbatim in §3.1/§3.2). Falsifying any one path proves the loop
detects a missing path; falsifying a second proves nothing new about the mechanism and only adds
exposure. The "audit every sibling" discipline in force elsewhere in this task applies to *documents
and claims*, where each sibling is an independent proposition — **it does not transfer to mutating
runtime-load-bearing files.** S7 therefore mutates exactly one guard-script path, and it is a
**template** copy (A4-adjacent, see M1), never a live one.

**Safe vs forbidden, explicitly:**

| Assertion | Path | Mutation status |
|---|---|---|
| A1 | `.harness/scripts/guard-rm.ps1` | **FORBIDDEN** — mirrored source *and* the Windows twin of the live guard |
| A2 | `.harness/scripts/guard-rm.sh` | **FORBIDDEN — live fail-closed `PreToolUse` target; mutating it seizes Bash** |
| A3 | `templates/common/.harness/scripts/guard-rm.ps1` | permitted, not used (M1 covers the loop) |
| A4 | `templates/common/.harness/scripts/guard-rm.sh` | **permitted — this is M1's target** |

### 11.2 Steps

**S0 — pre-state (measure, do not assume).** Capture and paste, in this order:

- `git rev-parse HEAD` and `git status --porcelain` (the **full** output, not a summary) —
- `grep -n '"version"' .claude-plugin/plugin.json` and `head -12 CHANGELOG.md`,
- `wc -l .harness/rules/75-safety-hook.md` (expect 200),
- `grep -n '"verify_all_checks"' .harness/scripts/baseline.json` (expect 32).

**Round-2 requirement (condition C-5 / gate F-7b).** The environment snapshot reports
`HEAD = cb0ed57 (v0.44.0)` with a *clean* status, while `.claude-plugin/plugin.json:4` says `0.46.0`
and `CHANGELOG.md:8` carries `## [0.46.0]`. **Those cannot both be true**, so S0 exists to *measure*
the real state rather than inherit either claim. R-7 already anticipates that the working tree
carries siblings' uncommitted work; S0 turns that anticipation into a recorded fact. Whatever the
measurement shows, **do not reconcile it** — it is context for reading later runs (in particular, it
tells you which files the scratch-tree overlay is actually carrying), not a defect to fix in T-15.
If `git status --porcelain` is genuinely empty while the version files read `0.46.0`, record that
too: it means the sibling work is already committed and R-7's overlay is belt-and-braces rather than
load-bearing. Either way the S1 construction is unchanged.

**S1 — build the scratch clean tree (inside the project root).**
```
git worktree add --detach .t15-clean HEAD
rsync -a --delete --exclude '.git' --exclude '.t15-clean' \
      --exclude '.claude/settings.local.json' ./ .t15-clean/
```
`rsync` absent ⇒ `tar --exclude=./.git --exclude=./.t15-clean --exclude=./.claude/settings.local.json -cf - . | tar -xf - -C .t15-clean`
(note: without `--delete`, a file deleted in the working tree relative to HEAD would linger — prefer
rsync).

**What this scratch tree actually is** (round-2 correction, condition C-5 / gate F-7a). It is **the
current working tree, minus `.claude/settings.local.json`, laid over HEAD's index** — *not* a clean
checkout, and the earlier phrase "the exact clean-checkout condition" is withdrawn as overstated.
Precisely:

- `git worktree add --detach .t15-clean HEAD` gives the scratch tree **HEAD's index**; the `rsync`
  overlay changes files **on disk without touching that index**. So every git-driven check inside the
  scratch tree (`A.1`, `A.2`, `E.7`, and `I.6` via `git ls-files` at `verify_all.sh:633`) enumerates
  **HEAD's** file list, not the overlaid one.
- The property that AC-2/AC-3 actually need is narrower and *is* satisfied: **no machine-local
  settings file present**, committed `.claude/settings.json` present carrying `"hooks": {}`, and the
  `F.2`-relevant content (guard scripts, settings template, `verify_all` itself) identical to the
  live tree. `F.2` reads none of its inputs through git, so the stale index cannot affect its verdict.
- Consequence for reporting: the **load-bearing observation in S2 and S8 is `F.2`'s own verdict line
  and detail**, which is a genuine measurement. The whole-run tallies in the scratch tree are
  **recorded as observed, not predicted** — see the discrepancy rule below.

**S2 — AC-3, the pre-change measurement (before writing any code).**
`bash .t15-clean/.harness/scripts/verify_all.sh; echo "exit=$?"` — the script derives its root from
its own path (`verify_all.sh:5-7`), so it evaluates the scratch tree. **Paste the entire run
verbatim** (every `[id] … STATUS` line, the whole `=== Summary ===` block, and the `exit=` echo).

The assertion under test is exactly this: `[F.2] … FAIL` whose detail is
`.claude/settings.json:no_PreToolUse .claude/settings.json:no_Bash_matcher .claude/settings.json:no_guard-rm_command`,
and `exit=2`. That is the pre-change defect, demonstrated rather than described.

**Discrepancy rule for scratch-tree runs (condition C-5).** Any *other* red line in a scratch-tree
run — a check that is not `F.2` reporting FAIL or WARN — is to be treated as a **procedure artifact
of the scratch construction** (most plausibly the stale index described above), and handled as:
record it, name it in `04_IMPLEMENTATION.md`, and continue. Do **not** edit the recorded expectation
to match, do **not** "fix" the scratch tree to make it green, and do **not** conclude the T-15 edit
caused it — S2 runs *before any code is written*, so by construction it cannot have. The one thing
that would genuinely block progress is `F.2` itself not behaving as stated; that would mean the
scratch construction failed to remove the machine-local file, and the correct response is to
re-verify the `--exclude` and rebuild — **never** to touch the live file.

**S3 — AC-10, never-installed half (while the scratch tree exists).** Apply
`skills/harness-status/SKILL.md` §0 to `.t15-clean/.claude/`: C1 absent, C2 `empty` ⇒ `SOURCE = none`,
`MACHINE_STATE = never-installed`. Paste the §0.5 `Hook source:` line and the §3b guard verdict.

**S4 — dismantle before touching the live gate.** `git worktree remove --force .t15-clean` then
`git worktree prune`; confirm `git status --porcelain | grep t15-clean` is empty. (Removal is inside
the project root ⇒ guard-legal; `git worktree remove` carries no destructive verb from the guard's
nine-verb set.)

**S5 — implement** L1–L7 of §8. Re-Read every edited file after every Edit (the Edit-false-success
insight), and specifically re-read `AI-GUIDE.md:74` to confirm `32 checks` survived.

**S6 — AC-1.** `bash .harness/scripts/verify_all.sh` on the live tree. Paste the whole
`=== Summary ===` block; expect `PASS: 32 / WARN: 0 / FAIL: 0`, exit 0.

**S7 — AC-5/AC-6 anti-vacuity, mutating the ARTIFACT** (insight 2026-06-20 — never a name array).
**Four** mutations (round 2 added M4 per condition C-3). One mutation at a time; restore and re-run
green (`PASS: 32 / WARN: 0 / FAIL: 0`, exit 0) between each; run no other driver while mutated
(`test-init`'s own `PreToolUse` assertions run against a rendered fixture and would break while M2/M3
are active).

**Before starting, re-read §11.1.** A1/A2 — the live guard scripts — are forbidden targets. Every
mutation below is a rename or edit **inside the repo**, destroying nothing, with an exact restore.

- **M1 — falsifies the A1–A4 loop.** Rename
  `skills/harness-init/templates/common/.harness/scripts/guard-rm.sh` to `guard-rm.sh.t15bak`.
  **Expected output (round-2 correction, condition C-2 / gate F-1): TWO FAILs, not one.**
  - `[F.2] … FAIL` with detail
    `missing:skills/harness-init/templates/common/.harness/scripts/guard-rm.sh` — the assertion
    under test, and the only one AC-5 depends on;
  - `[E.1] … FAIL` with `Run .harness/scripts/sync-self.sh` — **expected and correct**;
  - summary `PASS: 30 / WARN: 0 / FAIL: 2`, `exit=2`.

  *Why `E.1` co-fires, so nobody "repairs" it:* the mutated path is **Mapping 5** of
  `sync-self.sh:74-76` — the template guard scripts are a mirrored **source**. `sync_file`
  (`:22-33`) records drift whenever `[[ -f "$dst" ]] && cmp -s "$src" "$dst"` fails, which includes
  the source being renamed away; `--check` then exits 1 (`:95-103`), which `verify_all.sh:194-198`
  renders as `[E.1] … FAIL`. **No mutation of A1–A4 can avoid this** — all four paths are mirrored
  (and two of them are forbidden outright), so the two-FAIL shape is inherent, not a mistake.
  AC-5's validity is untouched: `F.2` turns red on its **own** token, independently.

  > **DANGER (hard rule 4).** Do **not** run `sync-self.sh` without `--check` to "fix" `E.1` while
  > the source is renamed. In write mode `sync_file` would `cp` from a **missing source** onto the
  > live `.harness/scripts/guard-rm.sh` — i.e. it would attack the live fail-closed guard path by a
  > side door, producing exactly the Bash-seizure outcome §11.1 exists to prevent. `E.1` is restored
  > by restoring the rename, and by nothing else.

- **M2 — falsifies B1.** Replace `{{GUARD_COMMAND}}` with `XGUARD_COMMANDX` in
  `skills/harness-init/templates/common/.claude/settings.json.tmpl`. Expect exactly one FAIL:
  `[F.2] … FAIL` with `…settings.json.tmpl:no_GUARD_COMMAND_placeholder`, `FAIL: 1`, `exit=2`.
  Co-failure-free: `D.2` (`verify_all.sh:79-89`) rejects only **unknown** `{{…}}` placeholders and
  never requires presence, so a *renamed* placeholder is not an unknown one. Restore → 32/0/0.

- **M3 — falsifies B2 and proves R-1 closed.** Delete the `"PreToolUse": [ … ]` array from that
  template's `hooks` object, **leaving the `_guard_hook` doc string at `:5` in place** — that
  juxtaposition is the whole point: it is what the old unanchored grep could not detect. Expect
  exactly one FAIL: `…settings.json.tmpl:no_PreToolUse_block`, `FAIL: 1`, `exit=2`. Co-failure-free:
  `J.1`'s valid-event list (`verify_all.sh:652`) is a *spelling* check over whichever hook keys are
  present, and `Stop` / `UserPromptSubmit` / `SessionStart` remain, so removing one key trips
  nothing. Restore → 32/0/0.

- **M4 — falsifies B0** (round-2 addition, condition C-3 / gate F-3). Before this addition the
  `else` arm emitting `missing:$tmpl` was the **only branch of the new block that no step exercised**
  — closing the single finding rather than the class. Temporarily rename
  `skills/harness-init/templates/common/.claude/settings.json.tmpl` to
  `settings.json.tmpl.t15bak`. **The `.t15bak` suffix is required**: the new name must not end in
  `.tmpl`, or `D.2`'s `find … -name '*.tmpl'` (`verify_all.sh:88`) would still scan it.
  Expect **exactly one FAIL**: `[F.2] … FAIL` with detail
  `missing:skills/harness-init/templates/common/.claude/settings.json.tmpl` — **one token only**,
  which is itself the evidence that B1/B2 are correctly gated behind B0 (§3: a missing template
  yields one token, not three). Summary `PASS: 31 / WARN: 0 / FAIL: 1`, `exit=2`. Restore →
  32/0/0.

  *Verified co-failure-free* (the whole reason this mutation is cheap): the template is **not** one
  of `sync-self`'s eight mirrored pairs — Mapping 5 covers the guard *scripts*, and the only
  `templates/common/.claude/` file in the mirror set is none at all — so **`E.1` stays green, unlike
  M1**; `J.1` skips a missing target cleanly via `[[ -f "$jt" ]] || continue` (`verify_all.sh:660`);
  `D.2` enumerates by `find` so the renamed file simply drops out of the scan set; and
  `verify_all.sh` references this path in exactly two places — `F.2` (`:323`) and `J.1` (`:657`) —
  confirmed by search, so there is no third consumer to surprise.

- **Every run's status word must read `FAIL`, never `WARN`** (AC-6, FR-4). A WARN would mean the
  block emitted to the pipeline in the PS twin (§3.2 hazard 5) or lost its `step … "FAIL"` argument
  in bash — either is a defect, not a passing variant.
- Restoration is by rename-back / edit-back only. After the final restore, re-run and paste a green
  32/0/0 before proceeding to S8.

**S8 — AC-2.** Rebuild the scratch tree exactly as in S1 (same commands, from the now-changed live
tree) and run `bash .t15-clean/.harness/scripts/verify_all.sh; echo "exit=$?"`. **Paste the run
verbatim**, whole summary block and `exit=` echo included. The assertion under test is
`[F.2] … PASS` — the same construction that produced a FAIL in S2 now produces a PASS, and the only
variable between the two is the `F.2` edit. That differential *is* AC-2.

The S2 discrepancy rule applies unchanged: a non-`F.2` red here is a **procedure artifact** of the
scratch construction (stale index per S1), to be recorded and reported, never silently absorbed into
the expectation and never repaired by editing the scratch tree. Note also that the S8 tree is built
from the **changed** live tree, so its overlay carries the T-15 edits while its index still reflects
HEAD — one more reason the git-driven checks inside it are not the measurement. Then S4 again
(remove + prune + confirm).

**S9 — AC-10, installed-and-wired half.** Apply §0 to the live tree: C1 `present` ⇒
`SOURCE_KIND = machine-local`, `MACHINE_STATE = installed`. Paste the `Hook source:` line naming
`.claude/settings.local.json` and the §3b guard verdict. Read-only; no file is modified.

**S10 — AC-8.** `bash .harness/scripts/test-guard-rm.sh`; paste `PASS: 87 / FAIL: 0`. Confirm
`baseline.json` is absent from `git diff --name-only`.

**S11 — AC-7 / NFR-2 close-out.** `verify_all_checks` still 32; no version stamp moved (`G.3`/`G.4`
PASS in S6); **`wc -l .harness/rules/75-safety-hook.md` = 200 — the identical value recorded at S0 —
and the file is absent from `git diff --name-only`** (condition C-10; both measurements pasted, both
mandatory). Confirm too that the file was **not** "improved while you were in there": the stale claim
at its `:150-151` is a known, deliberately-unrepaired backlog item per R-3, and repairing it here
would add a 201st line ⇒ `I.1` WARN ⇒ `exit 1`.

**S12 — AC-4 / AC-11 by inspection.** Paste the two `F.2` blocks and run **§3.4's three-part recipe**
over each: (a) the enumeration of every file-touching operation with its target, (b) the masked
code-line count (expect **0**), (c) the inverse assertion that the comment *does* name both settings
files. *(Round-3 correction: the earlier wording here — "show zero occurrences of
`settings.local.json`, `.claude/settings.json` and `ConvertFrom-Json` inside them" — is **withdrawn
as unsatisfiable**; see §3.4. The criterion it was proxying is unchanged and was met.)* Re-run the §8
searches and show that the only live doc lines naming this check's coverage are L3 and L4, both now
consistent with the shipped behaviour, and that no frozen row in §9 appears in `git diff --name-only`.

**QA additions (adversarial, beyond the ACs).** Mutate the ledger in **both** directions
(insight 2026-06-19):

(i) Revert **L3** alone (`.harness/rules/40-locations.md:42`) and confirm **no gate catches it** —
proving that line is **review-protected, not gate-protected**, which is the honest claim to publish.
Restore immediately. The same classification applies to `CONTRIBUTING.md:22`, which §9 now files
correctly (condition C-6): `g4_files` (`verify_all.sh:732-744`) contains exactly eleven entries —
`AI-GUIDE.md`×2, `docs/dev-map.md`×2, `.harness/rules/40-locations.md`, `README.md`×2,
`README.zh-CN.md`×2, `docs/manual-e2e-test.md`, `.harness/scripts/baseline.json` — and
`CONTRIBUTING.md` is **not** among them. Publish the distinction with that evidence, not from
memory: the delivery claim is "the count claims are gate-protected in eleven places and
review-protected elsewhere", and naming a wrong file in either bucket is itself the defect class
T-15 is closing. Note the subtlety `G.4` itself documents (`:728-731`): `.harness/rules/40-locations.md`
**is** in `g4_files`, but as a whole-file test whose expect is the `(32 checks` literal on `:29` —
which is why L3 (`:42`) can be reverted without `G.4` noticing.

(ii) Confirm no frozen surface in §9 appears in `git diff --name-only`.

(iii) Probe **B-3** explicitly — a tree whose `.claude/settings.local.json` carries `{"hooks": {}}`
must still yield `F.2 PASS` (the durable opt-out is a *present* file, which is why the
presence-conditional form is unsound). Constructible **in the scratch tree** by *writing* that file
there; the live file is never involved (§11.0 rule 1).

### 11.3 Evidence budget — the paste-vs-doc-size collision, resolved here (round-3 allowance)

**The collision.** §11.0 rule 5 mandates that every tally, verdict and summary block be **pasted from
the run that produced it**, and S2/S8 each require a whole 32-line gate run verbatim. Meanwhile
`.harness/rules/70-doc-size.md:30` caps a per-task stage doc at **500 lines**, and its Rule 1
(`:34-44`, "reference, don't paste") caps raw evidence at **≤5 lines** per block. Both rules are in
force; both are right in their own domain; and rounds 1–2 of this design granted **no allowance**,
so the developer had to arbitrate mid-task and `04_DEVELOPMENT.md` landed at ~755 lines
(`05_CODE_REVIEW.md`, STANDARDS/DOC-SIZE MINOR). Leaving that arbitration to the implementer was an
architectural omission, not a developer error.

**The tie-break, binding for this task and stated for future ones: the paste mandate wins.** Never
shorten, summarise, re-derive, re-column or otherwise transform a run to fit a size cap. Rationale,
so it is reusable rather than a one-off ruling: a truncated tally is **unrecoverable** evidence — the
run is gone and nothing in the repository can reconstruct it — while an over-long stage doc is a
WARN-level context cost on a document that gets archived within days (`70-doc-size.md` Rule 4).
Further, Rule 1 governs **discretionary** pasting — code the reader could go read for themselves,
which is why "cite `path:42-58` instead" is its remedy. It does not govern **mandated** evidence,
which by construction has no citable source. The developer's tie-break in round 2 was the correct
one and is now the written rule.

**The budget, stated rather than discovered.** T-15's mandated pastes, at ~32 `[id]` lines per full
run plus summary block and `exit=` echo:

| Step | Mandated paste | ≈ lines |
|---|---|---|
| S0 | full `git status --porcelain` (explicitly "the **full** output, not a summary") | ~46 |
| S2 | full pre-change run + summary + `exit=` | ~40 |
| S6 | summary block | ~8 |
| S7 M1–M4 | per-mutation `F.2` line + detail + summary + `exit=`, ×4 | ~32 |
| S8 | full post-change run + summary + `exit=` | ~40 |
| S3 / S9 / S10 | health-report lines, driver tally | ~10 |
| **Total mandated evidence** | | **≈ 175** |

500 − 175 leaves ~325 lines for twelve steps, four mutations, three QA additions, an operator item
and every discrepancy narrative. **A compliant-and-complete stage-4 doc was arithmetically impossible
for this task, and that was knowable at design time.** The overage is therefore **granted here
retroactively**; `04_DEVELOPMENT.md` is **not** to be restructured, appendix-ised or trimmed after the
fact — doing so now would re-open a shipped record to satisfy a cap it was already excused from.

**The pattern future designs must use instead of arbitrating late — an appendix, not a diet:**

1. **Body** (prose, tables, findings, discrepancies) stays under the 500-line cap and **cites**
   evidence by step id: "S2 → Appendix E-S2".
2. **Appendix** — one trailing `## Appendix E — Verbatim runs`, each paste under an `### E-S<n>`
   heading naming the exact command that produced it. The appendix is mandated evidence and is
   **exempt** from Rule 1's ≤5-line guidance.
3. **The doc header declares the split**: "Body N lines / Appendix M lines; the appendix is mandated
   evidence under the design's verification plan and is exempt per design §11.3." A disclosed,
   budgeted overage is a different object from an undisclosed one.
4. **Design-time obligation**: any design whose verification plan mandates verbatim runs **must**
   carry a table like the one above. Counting the evidence is the architect's job; the developer
   should never have to choose between two rules the design left colliding.

**Scope of this allowance.** It is doc-process only and changes **no rule file** —
`.harness/rules/70-doc-size.md` is not edited by T-15 and stays exactly as written. If the collision
recurs on a third task, the durable fix is one sentence in that fragment exempting mandated verbatim
evidence from Rule 1; that is a rule-fragment edit and therefore its own task, not T-15's.

**This document is also over the cap, and for a *different* reason — stated, not quietly excused.**
`02_SOLUTION_DESIGN.md` passed 500 lines during round 2 and grows again in round 3. The cause is not
pasted evidence (this document pastes no run) but **revision accretion**: each review round appends a
condition-by-condition changelog (§16, §17) that the PM requires to stay diffable, on top of a body
that must remain a complete standalone hand-off. The allowance above does **not** cover it, because
the remedies differ — mandated evidence belongs in an appendix, whereas revision trail is a
candidate for the PM-owned **compaction** pattern (`70-doc-size.md:46-57`, today written for
`PM_LOG.md` only). The honest statement for a future architect: **a design that survives three review
rounds will exceed the per-stage cap on changelog weight alone**, and the fix is to compact
superseded round changelogs to one-line summaries at task close — an archive-time action, not a
mid-flight trim of a document downstream stages are still reading. Recorded here as the observation;
extending compaction from `PM_LOG.md` to multi-round stage docs is a rule-fragment change and thus
its own task, alongside the Rule 1 exemption above.

## 12. Out-of-scope clarifications

This design does **not** cover: re-pointing the four command-derivation flows at the hook wiring spec
(T-16); any change to guard behaviour, the destructive verb set, or either guard script; the residual
bypass surface T-17 published; **any new `verify_all` check, including a compensating one** — the
defect class closes with the check count flat at 32; any change to the health report, the installer,
the hook wiring spec, or any settings file; reconciliation of the frozen T-13/T-17 operator
PowerShell items or of `test_init_ps_assertions`; `docs/proposals/frontier-gaps-2026-07.md`;
committing anything (the tree is left green and the operator commits).

**Added in round 3 — the B1/B2 containment residual (§3.5).** `F.2` asserts that the settings
template carries the `{{GUARD_COMMAND}}` placeholder **and** that it carries a real `"PreToolUse"`
JSON key; it does **not** assert that the placeholder sits *inside* that hook block. This is
**stated, not closed** — closing it is OQ-6(a), declined at `01_REQUIREMENT_ANALYSIS.md:243-245` and
owned by **T-16 `hook-truth-derivation`**. `07_DELIVERY.md` states the residual so the new label is
not over-read; the T-16 row carries it as a sub-item. No T-15 code change follows from it.

## 13. Partition assignment

Not applicable — `.harness/agents/` contains no `dev-*.md` partition agents in this repo
(`AI-GUIDE.md:15`, `.harness/rules/40-locations.md:8`). Single-Developer mode; dispatch order is the
S0→S12 sequence in §11, which is strictly sequential by construction (S2 must precede S5).

## 14. Decided autonomously (deferred-human mode — recorded, not asked)

| # | Ambiguity | Resolution | Basis |
|---|---|---|---|
| D-1 | B-8 is unsatisfiable with today's unanchored `PreToolUse` grep | anchor B2 to the JSON key form (§3.1/§3.2, R-1). **Upheld by the gate in round 1 and now binding (C-9); the unanchored fallback is withdrawn** | a stated boundary condition must hold; explicitly **not** the OQ-6(a) byte-form widening |
| D-2 | PS `F.2` throws on the first problem, violating B-9 and FR-7 | restructure to the `E.4b` accumulate-then-throw idiom | B-9 + FR-7 are binding; the idiom already exists in the same file |
| D-3 | Exact new label string | `Guard-rm scripts and settings-template guard wiring present` (identical in both shells) | OQ-3(b); verified no driver/baseline pins the old string — only the two scripts and four archived stage docs contain it |
| D-4 | Is `AI-GUIDE.md:74` live-false? | yes, minimally — `F.2 guard-rm wiring` reads as a live-wiring claim; edit the phrase only, preserving the `G.4`-load-bearing `32 checks` literal | FR-8 |
| D-5 | `MIGRATION.md:231` ("29 checks … F.2 guard-rm") | frozen, deliberately untouched | historical table, not a `G.4` row; editing it is the decoy bug |
| D-6 | Where the new operator PS item lives, given the list is materialized in archived stage docs | in T-15's own `04_IMPLEMENTATION.md`, exactly as T-17 appended to T-13's list | AC-9 + "archived docs are frozen" are only jointly satisfiable this way |
| D-7 | Two memory-layer appends (CONTEXT.md, rejected-decisions.md) on a surface-*removing* task | keep both; each is one small block, neither is read by any gate, and the declined-approach record is precisely what prevents this narrowing from being reverted by a future reader | `AI-GUIDE.md:39-40`, `.harness/rules/25-decision-policy.md`, insight 2026-06-20 |

## 15. Verdict

**READY (round 4)** — round 4 corrected **two doc-only claims in §3.3** (the deviation enumeration
and the per-deviation coverage statement) and touched nothing else in this document, no code, no
requirement and no settled decision. QA returned **APPROVED FOR DELIVERY** with 0 BLOCKER / 0
CRITICAL / 0 MAJOR; neither finding blocks delivery and neither implies a code change. The round-3
and round-2 verdicts below stand unchanged.

**READY (round 3)** — the round-2 verdict below stands unchanged; round 3 corrected four **doc-only**
defects in this document (§3 count, §3.4 recipe, §3.5 residual, §11.3 evidence budget) and touched
no code, no requirement and no settled decision. The shipped implementation was reviewed **APPROVED
(0 CRITICAL, 0 MAJOR)** and is unaffected by this revision.

**READY (round 2)** — every FR (1–9), boundary condition (B-1…B-12) and acceptance criterion (AC-1…AC-12) in
`01_REQUIREMENT_ANALYSIS.md` maps to a concrete edit in §8 or a concrete step in §11; the change
ledger and the frozen list were verified by search rather than inherited; no new dependency, no new
check, no new file under `.harness/scripts/`; the 200/200 rule fragment is untouched; and the one
genuinely risky operation (the clean-state demonstration) has a procedure that never disarms the
live guard. Nothing is undecidable, so no `BLOCKED: NEEDS-HUMAN` item is raised.

**R-1 / D-1 — adjudicated in round 1 and now closed.** The question raised for the gate (whether
anchoring the template `PreToolUse` assertion is inside T-15's mandate or is OQ-6(a) creep) was
answered: the gate independently verified the factual claim, ruled the anchoring **correct and in
scope**, and **rejected the unanchored fallback**. Per condition C-9 the anchored form is the design;
the fallback has been struck from R-1 rather than left as a live option, because after the narrowing
B2 is the check's only remaining wiring assertion and shipping it unanchored would make the new label
live-false at birth. **Nothing in this document is now offered as an alternative for the developer to
choose between** — every open question of round 1 is decided.

## 16. Round 2 changelog

Responses to `03_GATE_REVIEW.md` (**APPROVED WITH CONDITIONS**, C-1 … C-10). Nothing was
re-architected; the assertion set (§3), the edit ledger (§8) and the flow (§6) are byte-unchanged
from round 1. All ten conditions land in the hazard list, the frozen list, one basis label, one
symmetry sentence, and the verification plan.

| Condition | Where | What changed |
|---|---|---|
| **C-1** (F-2, safety-critical) | new **§11.1 "Forbidden mutation targets"**; §11.0 rule 2; §9 guard-script row | A1/A2 (`.harness/scripts/guard-rm.{sh,ps1}`) declared **forbidden mutation targets at any point**, at the same prominence as the `.claude/settings.local.json` prohibition, with the mechanism spelled out (fail-closed `PreToolUse` ⇒ renaming it seizes the whole Bash toolchain; recovery is Read+Write only). Added the safe/forbidden table and the explicit reason **one mutation suffices**: A1–A4 are four iterations of one loop body, so the "audit every sibling" discipline applies to claims, not to mutating runtime-load-bearing files |
| **C-2** (F-1) | §11.2 S7 **M1**; §2 scope note | M1's expected output corrected to **two** FAILs — `F.2` + `E.1`, `PASS: 30 / FAIL: 2`, `exit=2` — with the derivation (Mapping 5 of `sync-self.sh:74-76`; `sync_file:22-33` records drift when the **source** is renamed away; `--check` exit 1 → `verify_all.sh:194-198`) and the statement that **no** A1–A4 mutation can avoid it. Added the DANGER block: never run `sync-self.sh` in write mode while a mirrored source is renamed (it would `cp` an absence onto the live guard path). §2's "E.1 is unaffected" narrowed to "unaffected **by the edits**" |
| **C-3** (F-3) | §11.2 S7 **M4** (new) | Fourth mutation falsifying **B0**, the previously untested `else` arm: rename `settings.json.tmpl` → `settings.json.tmpl.t15bak` (suffix constraint stated, so `D.2`'s `find -name '*.tmpl'` drops it). Expect **exactly one** FAIL `missing:<tmpl>`, `PASS: 31 / FAIL: 1`, `exit=2` — the single token doubling as proof that B1/B2 are gated behind B0. Co-failure-freedom re-verified here, not inherited: not in the mirror set (so `E.1` stays green, unlike M1), `J.1` skips missing targets at `:660`, `D.2` enumerates by `find` at `:88`, and the path has exactly two consumers in `verify_all.sh` (`:323`, `:657`) |
| **C-4** (F-4) | §3.2 **hazard 5** (list now "Five") | New named hazard: `Step` (`verify_all.ps1:19-37`) derives severity from the scriptblock's **pipeline output** (`$r = & $action`; `if ($r -eq $false)`), so any emitting statement makes `$r` an array, `-eq` a filter, the result truthy ⇒ **WARN ⇒ exit 1 ⇒ FR-4/AC-6 violated**. Added the concrete rule (assignments / `if` / `foreach` / `throw` only; forbidden: bare `Test-Path`, `$problems + …` for `+=`, `Write-Output`, unassigned `Get-Content`; `| Out-Null` if ever needed) and a note that the code as written is clean. Also recorded that the **two-shell hand-off must stay a full body, not a diff** — the property whose absence manufactured the `-join` defect |
| **C-5** (F-7) | §11.2 **S0**, S1, S2, S8 | S0 now **measures**: `git rev-parse HEAD` + full `git status --porcelain` + `plugin.json` version + `CHANGELOG` head, with the HEAD-vs-version-file contradiction named and explicitly *not* to be reconciled. S1's "the exact clean-checkout condition" **withdrawn**; replaced with what the tree actually is — the current working tree minus `.claude/settings.local.json` over **HEAD's stale index**, with the consequence that git-driven checks inside it (`A.1`, `A.2`, `E.7`, `I.6`) enumerate HEAD's file list. Stated why AC-2/AC-3 survive anyway (`F.2` reads nothing through git). S2/S8 now require verbatim pastes and carry the **discrepancy rule**: a non-`F.2` red is a procedure artifact — record and report, never edit the expectation, never repair the scratch tree |
| **C-6** (F-6) | §9 (two rows); §11 QA addition (i) | `CONTRIBUTING.md:22` **removed** from the "`G.4` count rows" row and given its own row as **review-protected, not gate-protected**, with the eleven actual `g4_files` entries enumerated from `verify_all.sh:732-744`. Freeze verdict unchanged. QA (i) now publishes the distinction with that evidence and adds the `40-locations.md` subtlety (`:29` is the `G.4` literal, `:42` is L3) |
| **C-7** (F-5) | §3.3 | The absolute symmetry sentence replaced by a narrowed claim plus a table of the **two accepted deviations**: PS `-notmatch` is case-insensitive (S-1) and .NET `\s*` matches `\n` while `grep` is line-scoped (S-2). Each carries why it is accepted rather than forced, and the note that S-1 is pre-existing on the `{{GUARD_COMMAND}}` assertion. Claim now reads: for every non-pathological input, including all four S7 mutations, the shells agree on verdict and token list |
| **C-8** (F-8) | §9 insight-index row | Recorded as **PM-carried**: the file is at exactly 30/30 `I.4` bullets and a WARN exits 1, so the stage-7 harvest must **rotate**, not append. Explicitly marked as not the Developer's design surface and not to be pre-emptively trimmed |
| **C-9** | §10 R-1; §15 | The unanchored fallback **struck**, not merely deprecated — R-1 now records the gate's independent verification and the stronger argument (B2 is the only remaining wiring assertion; unanchored, the new label is live-false at birth ⇒ FR-6 violation ⇒ M3 un-runnable ⇒ AC-5 undischargeable for B2). §15's "if the reviewer disagrees…" paragraph replaced with a closure note: no alternative is offered for the developer to choose between |
| **C-10** | §10 R-3; §11.2 S11; §9 | Restated that `.harness/rules/75-safety-hook.md` is untouched — `wc -l` = **200** at S0 **and** S11, absent from `git diff --name-only`, both pasted. Added the explicit prohibition on repairing the gate's F-9 stale claim at its `:150-151`: the file is at 200/200, one added line is a WARN ⇒ exit 1, and even a line-neutral rewrite would put a frozen file in the diff. Recorded as backlog, "so nobody fixes it while they are in there" |

**Disputed: nothing.** Every finding was re-checked against the code before folding it in — `sync-self.sh:22-33`/`:74-76` and `verify_all.sh:194-198` (F-1), `.claude/settings.local.json:4,22` and `.harness/rules/75-safety-hook.md:176` (F-2), `verify_all.sh:88`/`:657`/`:660` (F-3), `verify_all.ps1:19-37` (F-4), `settings.json.tmpl:5,48` (F-5), `verify_all.sh:732-744` and `CONTRIBUTING.md:22` (F-6), `.claude-plugin/plugin.json:4` vs the environment's HEAD snapshot (F-7b). All seven confirmed as reported. One incidental confirmation worth recording for the developer: `.harness/scripts/verification_history.log` is appended by **every** `verify_all` run but is gitignored (`.gitignore:34`), so the repeated S6/S7/S8 runs cannot pollute the `git diff --name-only` evidence that S11/S12 depend on.

## 17. Round 3 changelog

Responses to `05_CODE_REVIEW.md` = **APPROVED (0 CRITICAL, 0 MAJOR, 7 MINOR, 6 NIT)**. Four MINORs
were routed to the architect; all four are **doc-only** and land in this document. **No code file was
opened for edit in round 3**, the implementation ships as reviewed, and nothing settled in rounds 1
or 2 is reopened — the anchored B2 form stays binding and the unanchored variant stays struck (C-9),
the machine read stays dropped rather than conditionalized, no new gate check, exactly one recorded
step, total 32, every assertion at FAIL, the 200-line rule fragment untouched, the guard regression
driver pinned at 87 rows, guard behaviour and the destructive verb set unchanged, and no surface
describes this change as reducing guard coverage.

| Finding | Where it landed | What changed |
|---|---|---|
| **1 — internal miscount** (SPEC/DESIGN MINOR, `05:36`) | §3 opening sentence + a new note under it; **§1** architecture summary | "asserts **six facts**" → "**seven facts** — A1, A2, A3, A4, B0, B1, B2", matching the seven-row table that was always correct. **Root cause traced and closed too**: §1 read "the four guard-script presence tests and the **two** distributed-template assertions", silently dropping **B0** (the template-presence test that gates B1/B2 and that mutation **M4** exists to falsify) — 4+2 is where "six" came from. §1 now reads "four … (A1–A4) and the **three** distributed-template assertions (B0 present, B1 placeholder, B2 hook key) — **seven facts in total**", so the two sections can no longer disagree. Recorded rather than fixed silently: the delivery bullet in `CHANGELOG.md` copied the wrong number out of this document, which is the same claim-propagation defect class T-15 exists to close. The one-word `CHANGELOG.md` fix is the developer's, in parallel; **this revision touches no code file**. |
| **2 — unsatisfiable AC-4 recipe** (SPEC/DESIGN MINOR, `05:35`, ruling 3) | §3 parenthetical **withdrawn**; new **§3.4**; **S12** rewritten | The "zero occurrences of `settings.local.json` / `.claude/settings.json` / `ConvertFrom-Json` between the header comment and the next check" recipe is struck, with both reasons for its impossibility stated: (i) FR-6 *requires* the header comment to name both settings paths, so a zero-count over the whole block forbids the exact text another requirement compels; (ii) the template path contains `.claude/settings.json` as a **prefix**, so B0/B1/B2 make the count unreachable by construction. Replaced with a three-part recipe that is satisfiable and strictly stronger: **(a)** a positive enumeration of every file-touching operation in each block with its target (permitted targets: `$f`, `$tmpl` — nothing else, and zero JSON-parser calls) — this is the part that actually discharges AC-4; **(b)** the string count re-scoped to **code lines only** with the template path **masked**, plus two new needles (`f2_hooks_file`, `hooksFile`) that name the deleted machinery itself; **(c)** the **inverse** assertion that the comment *does* name both files, so a future "tidy-up" of the comment cannot pass. Also written down as a standing rule: **when a proxy and its criterion disagree, the criterion governs and the proxy is the defect** — the implementer reports it, never trims code or comments to satisfy a number. The criterion itself was met (`05` ruling 3, verified independently); only the recipe was wrong. |
| **3 — B1/B2 containment residual** (SPEC/COVERAGE MINOR, `05:37`) | new **§3.5**; §12 addendum | Recorded as a **stated residual, explicitly not fixed**: B1 and B2 each assert **presence** over the whole file and never **containment**, so a template with `{{GUARD_COMMAND}}` in a different hook and an empty `PreToolUse` array would PASS under a label reading "wiring present". Documented the M3 link — the placeholder (`settings.json.tmpl:54`) physically lives inside the hook array (`:48-58`), which is why M3 emitted two tokens against a one-token prediction; the two assertions are entangled on the real artifact and neither asserts that relationship. Closing it means matching the placeholder within the array's byte range or against the hook wiring spec, i.e. **OQ-6(a)**, declined at `01:243-245` and owned by **T-16 `hook-truth-derivation`** (`BATCH_PLAN.md:31`); flagged there as an explicit sub-item. `07_DELIVERY.md` states the residual so the new label is not over-read. **No code change, no widening of B1/B2, no new check.** |
| **4 — evidence-budget / doc-size collision** (STANDARDS/DOC-SIZE MINOR, `05:41`) | new **§11.3** | The design mandated verbatim full-run pastes (§11.0 rule 5) while `.harness/rules/70-doc-size.md:30` caps a stage doc at 500 lines and `:34-44` caps raw evidence at ≤5 lines per block — and granted no allowance, leaving the developer to arbitrate mid-task (result: ~755 lines). Now resolved up front: **the paste mandate wins**, with a reusable rationale (a truncated tally is unrecoverable; an over-long stage doc is a WARN-level cost on a doc archived within days; Rule 1 governs *discretionary* pasting, where "cite `path:42-58`" is the remedy, and mandated evidence has no citable source). Added a **line-by-line budget table** (≈175 lines of mandated evidence, so 500-and-complete was arithmetically impossible and knowable at design time), granted the overage **retroactively** with an instruction **not** to restructure `04_DEVELOPMENT.md` after the fact, and specified the **appendix pattern** future designs must use (cited body under the cap + one `## Appendix E — Verbatim runs` section + a declared body/appendix split in the header), plus the standing design-time obligation to publish an evidence budget whenever a verification plan mandates verbatim runs. Changes **no** rule file; if the collision recurs, the durable one-sentence exemption in `70-doc-size.md` is its own task. |

**Disputed: nothing.** All four findings were re-verified against the live tree before folding in:
the seven-row table at §3 against `verify_all.sh:301-317` and `.ps1:288-309`; the recipe's two
impossibility causes against the shipped header comments (`verify_all.sh:292`, `.ps1:278`) and
against the literal template path in `verify_all.sh:311` / `.ps1:298`; the containment gap
against `settings.json.tmpl:48-58` vs `:54` and the assertions at `verify_all.sh:313-314`; the
size collision against `.harness/rules/70-doc-size.md:30,34-44`. Two notes on **what round 3 did
not do**, both deliberate:

- **The three MINORs and NITs routed to the *developer*** (`04`'s S11 freeze wording, the AC-11
  enumeration naming `docs/tasks.md:18`, the "byte-equal to §3.2" rewording, the reformatted S0
  porcelain) are **not** addressed here and `04_DEVELOPMENT.md` was not opened. The one forward-looking
  rule they imply — never transform a mandated paste, *including* by re-columning it — is recorded in
  §11.3 as design guidance, not as a re-litigation of that record.
- **The `CHANGELOG.md:83` "six assertions" fix is the developer's**, running in parallel this round.
  Editing a code file from here would collide with a concurrent round; §3's note records the
  dependency instead.

## 18. Round 4 changelog

Responses to `06_TEST_REPORT.md` = **APPROVED FOR DELIVERY** (0 BLOCKER, 0 CRITICAL, 0 MAJOR, 2
MINOR, 2 NIT). Both MINORs are **doc-only**, both land in **§3.3**, and both are *statement-of-fact*
corrections rather than coverage changes. **No code file was opened for edit. The verdict on every
recorded deviation is unchanged: accept, argued unreachable.** Nothing settled in rounds 1–3 is
reopened — the anchored B2 form stays binding and the unanchored variant stays struck (C-9), the
machine read stays dropped, no new gate check, exactly one recorded step, total 32, every assertion
at FAIL, the 200-line rule fragment untouched, the guard driver pinned at 87, guard behaviour and the
destructive verb set unchanged, the §3.5 containment residual recorded and still **not** fixed (it is
T-16's row), and no surface describes this change as reducing guard coverage.

| Finding | Where it landed | What changed |
|---|---|---|
| **MINOR-1 — "exactly two accepted deviations" is incomplete** (`06:155`) | §3.3, opening claim + a new axis list + a third table row | QA's 13-case corpus (`06` E-9) found a **third** member — .NET `\s` matches `U+00A0` / `U+0085`, which this host's POSIX `[[:space:]]` does not. Rather than bump a count that would go stale again, the closed list is replaced with the **two root-cause axes** that generate the class: **(i) case folding** and **(ii) whitespace breadth**, with the deviation defined as "the .NET engine is wider than the POSIX bracket expression along these axes, in ways this artifact cannot reach". The three known members (S-1, S-2, **S-3** new) are now presented as *instances*, so a fourth member does not falsify the section. **Also corrected while in there, because the new axis made the adjacent sentence false**: round 2's "T-15 neither introduces nor widens them" holds for axis (i) (pre-existing on B1 and on the pre-change unanchored B2) but **not** for axis (ii) — no pre-T-15 `F.2` pattern contained a whitespace class, so S-2/S-3 exist *because* T-15 anchored B2. Recorded as an **accepted cost of the anchor, explicitly not a reason to revisit it**: the anchor is binding, its benefit is measured (`06` E-6 M-B2, E-8 P3), and bash — the stricter side — is not weakened by any member. |
| **MINOR-2 — one rationale shared across unequally covered deviations** (`06:156`) | §3.3 table gains an **"Independent coverage elsewhere in the gate"** column; new paragraph after the table | Each member's coverage is now stated **separately and by measurement**. **S-2**: `J.1` passes cleanly on a key/colon line split (`06` E-8 P2) — bash `J.1`'s key regex is line-scoped (`verify_all.sh:666`) and PS `J.1` sees well-formed JSON — so S-2 is **argued unreachable with no independent backstop anywhere in the gate**, stated in those words. **S-3**: same mechanism, same absence. **S-1**: the co-fire QA measured (`06` E-8 P1) is real but **bash-side**, where `F.2` already fails; in the shell where the deviation actually occurs, PS `J.1` tests `$k -notin $validHookEvents` (`verify_all.ps1:633`) and PowerShell's `-notin` is itself **case-insensitive**, so PS `J.1` accepts `pretooluse`. Round 2's "`J.1` owns key spelling" is therefore true of the bash gate and **false of the PowerShell one**; it no longer carries S-1 as far as round 2 implied, and S-1's acceptance is re-based on its independent leg (a case-wrong key is already broken upstream — Claude Code's hook-event keys are case-sensitive). Net: **none of the three has a backstop inside the PowerShell gate**, and that is now written down instead of implied. |

**Disputed: nothing.** Both findings were re-verified against the live tree before folding in, not
taken on report: bash `J.1`'s line-scoped key extraction at `.harness/scripts/verify_all.sh:666` and
its 4-space indent discriminator at `:671-673`; PS `J.1`'s `ConvertFrom-Json` parse and `-notin`
membership test at `.harness/scripts/verify_all.ps1:618,633`; and B2's two shipped patterns —
`grep -qE '"PreToolUse"[[:space:]]*:'` at `.harness/scripts/verify_all.sh:314` versus
`-notmatch '"PreToolUse"\s*:'` at `.harness/scripts/verify_all.ps1:304`, which is the exact pair the
axis analysis is about. Three notes on **what round 4 did not do**:

- **One addition beyond QA's two findings, and it is inside §3.3.** QA measured S-1's backstop on the
  **bash** side; the PS-side `-notin` case-insensitivity that removes it on Windows is my own read of
  `verify_all.ps1:633`, not QA's. It **strengthens** MINOR-2 (S-1 is less covered than QA credited)
  and does not change S-1's verdict, which never depended on that leg. It is **modelled, not
  executed** — `pwsh` is absent (`06:145`) — and §3.3's evidence-status paragraph says so.
- **The direction claim is marked as observed, not proved.** "PS accepts a superset of bash" holds
  across E-9's 13 cases; a character inside this host's `[[:space:]]` but outside .NET `\s` (the C1
  separators `U+001C`–`U+001F`) would deviate the *other* way and is not excluded by measurement.
  Recorded in §3.3 so a future auditor does not read the axis list as a proof. **Not investigated
  further** — it would need `pwsh`, and it is the same pathological-reachability class already
  accepted.
- **§16 (round-2 changelog) is deliberately left saying "the two accepted deviations".** It is a
  historical record of what round 2 did, and it was accurate then; the same discipline that freezes
  the historical `CHANGELOG.md` rows (§9) applies to a changelog section inside this document. §3.3
  is the live statement and is the one that had to be corrected. **NIT-1** (`CHANGELOG.md:80-83`
  enumeration) and **NIT-2** (`grep` portability) are **not** this document's — they route to the PM
  and to backlog respectively, and `CHANGELOG.md` was not opened (a developer round is editing it in
  parallel).
