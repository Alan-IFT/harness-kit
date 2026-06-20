# 06 — Test Report · T-05 durable-brief

> Stage 6 (QA Tester). Mode: full. deferred-human: defer, do not ask.
> Upstream: 01 READY · 02 READY · 03 APPROVED (C-1/C-2) · 04 READY FOR REVIEW · 05 APPROVED WITH NOTES.
> Scope: **T-05 additions only**. The shared working tree carries unrelated T-02/T-03/T-04 churn
> (RA rule-1/§8 reword, README/AI-GUIDE 15→16 skill flip, insight-index rotation, solution-architect.md,
> verify_all.{ps1,sh}, docs/*). Per the dev doc + CR these are **NOT T-05** and are excluded from verdict.
> T-05 edit set = 7 files: `agents/requirement-analyst.md`, `agents/pm-orchestrator.md`,
> `.claude-plugin/{plugin,marketplace}.json`, `README.md`, `README.zh-CN.md`, `CHANGELOG.md`.
>
> This task ships **no executable code** — it changes two agent contracts (prose) + version stamps.
> The "test suite" for a contract change is the deterministic gate (`verify_all`) plus independent
> regex/diff probes that encode each acceptance criterion. No unit-test file applies; the encoded
> checks live in `verify_all` (I.3 caps, I.6 retired-claim, G.3 stamps, G.4 claim↔version) and in the
> reproducible probes below.

## Test plan

| Acceptance criterion | Test case / probe | Verification |
|---|---|---|
| AC-1 RA durability rule present | grep Hard rule 6 distinctive phrase in `agents/requirement-analyst.md` | rule 6 at line 33, behavioral-not-procedural + no forward file:line ✅ |
| AC-2 good/bad exemplar present | grep good entry (line 68) + bad entry (line 75) | contrast pair present ✅ |
| AC-3 forward/backward boundary explicit | grep exemption clause names `05-insight-index.md` + stage-doc EVIDENCE | clause present in rule 6, with rationale ✅ |
| AC-4 PM dispatch one-liner present | grep dispatch line in `agents/pm-orchestrator.md` | line 59, "behavioral intent + AC + scope boundary, not procedural file:line" ✅ |
| AC-5 insight-surfacing preserved | grep "include the relevant line(s) in the dispatch prompt" | line 53 byte-present, unweakened ✅ |
| AC-6 no contradiction / protected files untouched | `git diff --name-only` for `05-insight-index.md` (rule) | rule file NOT in diff; coherence holds (see Adversarial) ✅ |
| AC-7 caps + gate green | `wc -l` both agents + `verify_all.sh` | RA 77 / PM 208 ≤300; gate 32/0/0 (I.3 PASS) ✅ |
| AC-8 version + CHANGELOG fan-out | grep 4 stamps + CHANGELOG `[0.36.0]` + G.3/G.4 | 4 stamps @0.36.0, `[0.36.0]` heading, G.3/G.4 PASS ✅ |
| AC-9 additive only | `git diff HEAD` deletion scan on agent files | T-05 surfaces are pure inserts; the `-` lines are T-03 churn (see Adversarial C-2) ✅ |

## Boundary tests added

This is a contract/doc change; boundary coverage is structural, not runtime:
- **Null/absent target heading** — all four target subsections ("Hard rules", "What good looks like",
  "What bad looks like", "Cross-task memory") confirmed present in the live files; no invented heading.
- **Empty-edit (no-op) risk** — durability text is greppable in the live files (rule 6 / good / bad / PM line),
  not merely described in a stage doc.
- **Max size (I.3 cap = 300)** — RA 77, PM 208; both far under cap, verified by `wc -l` and I.3 PASS.
- **Self-trip (I.6)** — every reference to the path/line concept is prose; zero literal `name.ext:NNN`
  tokens in any T-05 addition (Adversarial C-1). I.6 PASS.
- **Contradiction boundary (#1 risk)** — RA forward-only ban vs `05-insight-index.md` evidence mandate:
  both hold simultaneously (Adversarial Boundary-coherence).

## Adversarial tests (REQUIRED — one independent reproducer per probe)

Verdict is based on whether the implementation **survived** these adversarial probes, written
independently from the acceptance-criterion text (not copied from the dev doc's self-review).

| Probe | Hypothesis ("I expect failure when…") | Reproducer (NEW, I wrote this) | Outcome (tool evidence) |
|---|---|---|---|
| **C-1 / I.6 self-trip** | a T-05 addition smuggled a literal `file.ext:NNN` anchor that trips I.6 | `grep -oE '[A-Za-z0-9_.-]+\.(md\|ps1\|sh\|json\|ts\|js\|py):[0-9]+'` over RA rule 6 (L33), RA good (L68), RA bad (L75), PM line (L59), CHANGELOG `[0.36.0]` (L8-16) | **Survived** — NONE matched on all 5 surfaces. The only paths present (`05-insight-index.md`) carry no `:NNN`. `verify_all.sh` I.6 = PASS. |
| **Boundary coherence (#1 risk)** | RA forward-only ban contradicts `05-insight-index.md` (which mandates path/line evidence) | read both: RA rule 6 exemption clause vs `05-insight-index.md` L21/L27 ("evidence: <commit-sha or task-slug>", "Always include evidence") | **Survived** — both true at once. RA bans file:line in the *forward brief*; `05` mandates evidence on *backward* insight lines; rule 6 exempts exactly that surface. No contradiction. |
| **Single-source** | PM restates the forward/backward nuance, creating a 2nd source that can drift | `grep -nE 'forward-looking requirement prose ONLY\|Backward-looking \*\*EVIDENCE\*\* citations are exempt' agents/pm-orchestrator.md` | **Survived** — no match in PM. PM line 59 references "requirement-analyst's Hard rule 6" and does NOT restate the exemption nuance. Single-sourced in RA. |
| **insight-index protected** | T-05 edited `05-insight-index.md` (rule) or `insight-index.md` (data) | `git diff --name-only` filtered for `insight-index` | **Survived (with note)** — `.harness/rules/05-insight-index.md` (the RULE, the protected one per AC-6) is NOT in the diff. `.harness/insight-index.md` (the DATA file) IS modified, but the diff is a T-03 line add (2026-06-19 skill-fan-out insight) + a T-002 archival removal — **sibling churn, not T-05** (matches [0.35.0]/dev-doc). T-05's edit set excludes both. |
| **Additive (C-2)** | a T-05 reword silently deleted an existing RA rule or PM section | `git diff HEAD` deletion scan on both agent files + count of RA Hard rules | **Survived** — PM: zero deletions. RA: the 6 `-` lines are T-03's §8/rule-1 reword (per [0.35.0] CHANGELOG L25), not durability edits. All 6 RA Hard rules present (1-6); T-05 surfaces (rule 6 / good / bad / PM line) are pure inserts. |
| **No count flip** | T-05 flipped a skill/agent/check count token | `git diff HEAD` count-token scan on README ×2 / AI-GUIDE | **Survived** — the only count flips (15→16 skills) are T-03's documented fan-out, NOT T-05. Live counts 16 skills / 8 framework agents / 32 checks all validated by G.1/G.2/G.4 PASS. T-05's only count mention = additive `[0.36.0]` prose stating them UNCHANGED. |
| **Version** | a stamp or CHANGELOG heading lags at 0.35.0 | grep `version` in 4 stamps + CHANGELOG heading | **Survived** — plugin.json L4, marketplace.json L17, README L5, README.zh-CN L5 all `0.36.0`; CHANGELOG `## [0.36.0] - 2026-06-20` heading present. G.3 PASS. |
| **Caps** | an agent exceeds the I.3 300-line cap after additions | `wc -l` both agents | **Survived** — RA 77, PM 208 (both ≤300). I.3 PASS. |

### Tool evidence (pasted)

```
verify_all.sh  →  PASS: 32  WARN: 0  FAIL: 0   (3 consecutive runs, identical)
[I.3] Agent definitions ≤300 lines each ... PASS
[I.6] No retired-claim phrases in current docs/templates ... PASS
[G.3] Version stamps consistent across plugin/marketplace/README ... PASS
[G.4] Doc count/version claims consistent with plugin.json + live check count ... PASS

wc -l: 77 agents/requirement-analyst.md  /  208 agents/pm-orchestrator.md

C-1 regex (name.ext:NNN) over RA L33/L68/L75, PM L59, CHANGELOG L8-16  →  NONE on all 5

git diff --name-only | grep insight-index  →  .harness/insight-index.md  (DATA, T-03 churn)
git diff --name-only -- .harness/rules/05-insight-index.md  →  (empty: RULE untouched)

PM single-source grep  →  PM does NOT restate the nuance clause (PASS)
PM AC-5 grep  →  "include the relevant line(s) in the dispatch prompt"  (L53, byte-present)
```

## verify_all result

- Total checks: **32 → 32** (no check added — content change, not gate change)
- PASS: **32**
- FAIL: **0**
- WARN: **0**
- New tests added: **0** (documentation/contract change; no executable code path to unit-test;
  the encoded checks are the verify_all gate + the reproducible adversarial probes above)
- Baseline updated: **yes** — `last_verify` 2026-06-19 → 2026-06-20 only; `verify_all_checks` stays 32
  (baseline only goes up; no test-count change to record for a doc-only task).

## Defects found

**None.** 0 BLOCKER / 0 CRITICAL / 0 MAJOR / 0 MINOR.

## Stability

- `verify_all.sh` ran **3 consecutive times**: 32/0/0 each, byte-identical summary. No flakes observed. ✅
- C-1 / single-source / additive probes are deterministic (regex + git diff) — re-run idempotent.

## Operator-pending (not faked)

- `.harness/scripts/verify_all.ps1` (PowerShell) — **operator-pending**. PowerShell is denied to this
  agent (standing deny-rule). The bash gate is 32/0/0; the PS parity run is the PM/operator's to execute
  before marking done, per the established cross-shell pattern. **Not run here, not faked.**

## Verdict

**APPROVED FOR DELIVERY** — 0 defects. All 9 acceptance criteria covered and survived independent
adversarial probes; the #1 design tension (forward brief vs backward evidence) is coherent and
single-sourced in RA; T-05 is additive-only with no count flip and no protected-file edit; caps and the
full bash gate (32/0/0, incl. I.3/I.6/G.3/G.4) are green and stable. PowerShell parity run is
operator-pending (not a defect — an environment constraint).
