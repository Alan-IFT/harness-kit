# 06 — Test Report: stream-auto-decompose (T-021)

> Mode: full · QA: qa-tester · Date: 2026-06-12
> Inputs: 01 (READY) · 02 (READY) · 03 (APPROVED, QA condition: isolated-root hook probes + D-1 reading) · 04 (READY FOR REVIEW) · 05 (APPROVED)
> All tallies below are captured from real runs in this sandbox — none inherited from 04/05.

## Test plan (per acceptance criterion)

| AC | Test | Evidence | Result |
|---|---|---|---|
| AC-1 | D-1 single-sourcing + binding pointers (Gate ruling 1) | `grep -c "Triage test" SKILL.md` → **1**; pointers at `:76` ("per "Ingest triage" below") and `:115` ("per "Ingest triage" above"); `grep "see also"` → 0 hits | PASS |
| AC-2 | Amended hard rule + cross-ref truth | `SKILL.md:162` read: union both directions ("no invented scope, no dropped scope") + "Work the user did not ask for is never added" + "never split or rewritten"; `25-decision-policy.md:52-53` unchanged, "never invented autonomously (mirrors the `/harness-stream` rule)" still truthful | PASS |
| AC-3 | 4-carrier runtime parity (isolated root, Gate F-1) | See "Hook runtime probes" below: dogfood ≡ template byte-identical per shell; sh ≡ ps1 textually identical (GBK-decode proof); 17 lines (+2 vs v0.31.0, diffed against `git show HEAD:` outputs); `{{` count 0 in all four | PASS (DEFECT-1 noted, pre-existing) |
| AC-4 | Traceability decidable from BATCH_PLAN.md alone; schema unchanged | `SKILL.md:95` shared `<base>-` prefix + dated `## Notes` provenance line; `_template/BATCH_PLAN.md:9` = `ID | Slug | Goal | Mode | Depends on | Status`, template diff 0 lines | PASS |
| AC-5 | Four semantic probes, text-as-spec | See Adversarial tests §A — all four verdicts forced unambiguously | PASS |
| AC-6 | verify_all 32/32 both shells | bash: **PASS 32 / WARN 0 / FAIL 0**; pwsh: **PASS 32 / WARN 0 / FAIL 0** (incl. G.3 badges, G.4 `[0.32.0]`↔plugin.json, I.6 — real runs) | PASS |
| AC-7 | Stale 1:1-ingest claim sweep (independent grep) | 4 patterns, 0 live hits — see "Stale-claim sweep" | PASS |
| AC-8 | Regression drivers untouched + green | `test-init.sh` **270/0** · `test-init.ps1` **308/0** · `test-real-project.sh` **90/0** · `test-real-project.ps1` **90/0** — all equal baseline.json; `git diff` shows no driver edits | PASS |
| §12.7 | SKILL.md budget | `wc -l` → **175** ≤ 198 | PASS |

## Hook runtime probes (isolated temp root — Gate F-1 honored)

Temp root `/tmp/tmp.BzCtvOtygd` with `.git/` marker + `.harness/`; the four scripts copied in; flag created **only there**. Verified before and after: `.harness/ambient.flag` does NOT exist in the live repo (`test -f` → absent). Temp root deleted afterward.

- **No flag:** all 4 scripts → `exit=0 output_bytes=0` (dog.sh, tpl.sh, dog.ps1, tpl.ps1). ✅
- **Flag present:** all 4 → exit 0, **17 lines** each (`wc -l`: 17/17/17/17). Old block (from `git show HEAD:`) = 15 lines → **+2 confirmed**; `diff old new` shows exactly the step-1 swap (3 lines → 5 lines) and nothing else. ✅
- **Content:** emitted block contains `N rows per skills/harness-stream/SKILL.md "Ingest triage"` (line 8), `union ≡ the message; Mode per row` (line 9), requirement/question gate (line 6). (Dispatch's paraphrase "Triage the message" is not literal text; the shipped wording matches design §4 verbatim.) ✅
- **dogfood ≡ template:** runtime outputs byte-identical per shell (`cmp`: sh pair IDENTICAL, ps1 pair IDENTICAL). ✅
- **sh ≡ ps1:** CR-stripped byte compare DIFFERS by 7 chars — investigated, root-caused, and bounded: see DEFECT-1. Decoding the pwsh output as GBK (cp936) and re-comparing → **TEXTUALLY IDENTICAL** to the bash output. The authored text is identical; the byte gap is runtime console encoding on this zh-CN-locale Windows host. ✅ (text level)

## verify_all result

- bash `verify_all.sh`: `PASS: 32 / WARN: 0 / FAIL: 0`
- pwsh `verify_all.ps1`: `PASS: 32 / WARN: 0 / FAIL: 0`
- Total checks: 32 → 32 (no new check by design, AD-5). New automated tests added: 0 — text-only skill change; behavior is encoded in this report's reproducible probes (drivers must stay unmodified per AC-8, and no driver pins SKILL text by design).
- Baseline updated: yes — `baseline.json` `last_verify` → 2026-06-12; all assertion counts unchanged and re-confirmed by capture (270/308/90/90). Baseline never went down.

## Adversarial tests (one predicted failure per AC family)

### A. AC-5 semantic probes — applied `SKILL.md:84-103` exactly as written

| Probe | Hypothesis ("I expect failure when…") | Forced verdict + clause | Outcome |
|---|---|---|---|
| (i) Verbose simple: "Login page should remember the user's email — pre-fill the field, survive restart, clear on explicit logout. Users have complained for months." | the "enumeration of distinct outcomes" signal (:89) misfires on the 3 acceptance bullets and forces a split | **1 row.** Criterion 1 requires outcomes that are "*independently verifiable deliverables* — each could pass its own QA and reach DELIVERED on its own" (:89); "pre-fill" alone cannot. :92 names it: "long prose describing one outcome; **a list of acceptance details for one outcome**" → NOT complex. Signals are parenthetical to the deliverable test, not freestanding triggers | Survived |
| (ii) 3 independent: "Add a /healthz endpoint, fix the README install typo, and bump the Docker base image to bookworm." | `Depends on` guidance is advisory enough to let the agent fabricate an execution-order chain | **3 rows, all `Depends on` = `—`.** :88-90 both criteria hold ("and"-chain, distinct subsystems, no single one-sentence Goal); :97 "chain only REAL consumption (row B uses an artifact or behavior row A produces). Independent siblings stay unchained (`—`) so a failed sibling never blocks them" — no consumption exists among the three | Survived |
| (iii) Phased: "First build a CSV export endpoint in the backend, then add a download button in the UI that calls it." | the text under-determines whether the UI row "consumes" the endpoint vs being independent | **2 chained rows** (button depends on endpoint). :89 phased signal ("X, then Y" / "先…再…"); :97 defines REAL as "uses an artifact or behavior row A produces" — the button *calls* the endpoint = behavior consumption; :95's own example slugs (`csv-export-endpoint`, `csv-export-button`) pin this exact shape | Survived |
| (iv) Fan-out: "Rename config key `max_retries` to `retry_limit` everywhere — code, tests, docs, sample configs." | the "outcomes touching distinct subsystems or artifact classes" signal (:89) reads code/tests/docs as distinct classes and forces a wrong split | **1 row.** Only ONE outcome exists, so criterion 1's operative test fails before signals apply; :92 counter-example names the case verbatim: "a single deliverable with wide fan-out (**one change echoed across many files**)"; criterion 2 also fails (one sentence states it); anti-pattern :171 reinforces | Survived |

No probe was under-determined — each verdict is forced by a quotable clause. AC-5: PASS.

### B. Fixed-point probe (termination)

Re-applied triage to probe (iii)'s row-B Goal ("Add a download button in the UI that calls the CSV export endpoint") as if it were a new message: one outcome → fails test 1 (:88-89) → simple path, 1 row, no marker. Pool rows are additionally non-inputs to triage by three quoted layers: `:86` "an existing row is never re-triaged" (general clause, Gate F-4); `:99` "every produced row must FAIL test 1 on its own … re-running triage on any produced row returns it unchanged"; `:103` "Once written, derived rows are ordinary pool rows". Ambient step 1 triages "your message" (:76) and Procedure 3a triages "message(s) delivered with *this tick's turn*" (:115) — the per-iteration pool re-read feeds drain, never triage. Survived.

### C. Mutation probe (gates are load-bearing)

Hypothesis: G.3/G.4 might not actually pin the marketplace.json stamp. Flipped `.claude-plugin/marketplace.json:17` to `0.31.0` → `bash verify_all.sh`:
```
[G.3] Version stamps consistent across plugin/marketplace/README ... FAIL
PASS: 31 / WARN: 0 / FAIL: 1
```
Restored (backup copy, `grep` confirms `0.32.0`) → re-run: `[G.3] ... PASS`, `PASS: 32 / WARN: 0 / FAIL: 0`. `git diff --stat` afterward shows only the 11 intended T-021 files + `docs/tasks.md` (PM ledger, declared in 04). Gate goes RED on the exact failure class this release depends on. Survived.

### D. Cross-shell runtime parity (independent reproducer — found DEFECT-1)

Hypothesis: the ps1 here-string emits differently than the sh heredoc at runtime (known 2026-06-08 defect class). The byte compare DID fail; root cause is host console encoding, not the change (see DEFECT-1) — the pre-change v0.31.0 ps1 emits the **same** GBK bytes (`a1 aa` for em-dash, hex-captured), proving the class is pre-existing, and GBK-decode restores textual identity. Implementation survived at the contract level the design fixed (authored-text identity, design §4: "do not chase byte-identity across shells").

## Stale-claim sweep (AC-7, independent)

Live tree (`*.md`, `*.ps1`, `*.sh`; excluding `docs/features/`, `CHANGELOG.md` history, `docs/*.html` version-pinned snapshots): `into a \`pending\` row` → 0 · `Mode=full` → 0 · `one row per requirement|exactly one row per|single pending row` (regex, case-insensitive) → 0 · `normalize it into a ` → 0. ✅

## Defects found

- **[MINOR] DEFECT-1 — pre-existing, NOT a T-021 regression: pwsh hook emits non-ASCII punctuation in the host ANSI codepage (GBK here), not UTF-8.** Repro: in an isolated root with the flag set, `echo '{}' | pwsh -NoProfile -File ambient-prompt.ps1 > out.txt` on a zh-CN Windows host → em-dash = bytes `a1 aa`, `≡` likewise GBK; a UTF-8 consumer (Claude Code reading hook stdout) renders these 7 chars as replacement chars, so the injected line reads "union �� the message". Evidence it is pre-existing: `git show HEAD:.harness/scripts/ambient-prompt.ps1` (v0.31.0) emits the identical `a1 aa` bytes for its em-dashes. Functional impact: none on the binding contract — the operative pointer `N rows per skills/harness-stream/SKILL.md "Ingest triage"` is pure ASCII and SKILL.md is the single source (D-1); loss is cosmetic punctuation. File: `.harness/scripts/ambient-prompt.ps1:65` (`[Console]::Out.WriteLine` without setting `[Console]::OutputEncoding`); also note `powershell.exe` 5.1 mangles differently (UTF-8-no-BOM source read as ANSI), but the live wiring is `pwsh -NoProfile` (`.claude/settings.json:30`). Suggested follow-up (PM backlog / insight candidate, not this task): set `[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)` before emitting, or keep hook blocks ASCII-only.

No BLOCKER / CRITICAL / MAJOR defects.

## Stability

`verify_all.sh` ran 3× (baseline, mutated, restored) + `verify_all.ps1` 1× — tallies deterministic (32/0/0 except the intended mutation run 31/0/1). Hook probes ran across 2 temp roots with identical results. No flakes observed.

## Not run / delegated

Nothing — both shells were available; all dispatch items 1-7 executed and captured here.

## Verdict

**PASS — RELEASABLE** (APPROVED FOR DELIVERY). One MINOR pre-existing defect (DEFECT-1) recorded for PM's backlog; it neither blocks nor is introduced by T-021.
