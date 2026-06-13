# 06 — Test Report · T-022 `stream-defer-human`

- Mode: full · QA: qa-tester · Date: 2026-06-13
- Method: independent end-to-end execution (both shells), independent greps/probes, a load-bearing mutation probe, and text-as-spec adversarial reading of the SHIPPED SKILL/agent text. No number below is transcribed from upstream — each is captured here.
- Note: sub-agent threads carry no Write tool in this harness; this report's content is authored by qa-tester and materialized verbatim by PM.

## Test plan (AC → evidence)

| AC | Test | Result |
|---|---|---|
| AC-1 verify_all 32/0/0 both shells, 32/15 unchanged | bash + pwsh verify_all (captured) | PASS — bash 32/0/0, pwsh 32/0/0 |
| AC-2 version lockstep + `[0.33.0]` heading | four-way grep + CHANGELOG grep + mutation probe | PASS — all four = 0.33.0; heading at CHANGELOG:8; G.3 pins it (probe 7) |
| AC-3 no retired-claim trip (I.6) | verify_all I.6 check | PASS (both shells) |
| AC-4 size caps (I.1–I.3) | `wc -l` | PASS — pm-orchestrator 206 ≤300, SKILL 199 |
| AC-5 ASCII-only hook text | `grep -nP '[^\x00-\x7F]'` on the 4 carriers' NEW sentence | PASS — 0 non-ASCII in the new sentence (probe 3) |
| AC-6 taxonomy unambiguous, (c)/(d) bright line | text-as-spec probe 6-iv | PASS — clauses force distinct verdicts |
| AC-7 pm-orchestrator contract binding | read :194-206 + Hard rule 6 (:22) | PASS — stream branch + no-auto-decide + structured return |
| AC-8 every behavior surface synced | `git diff --stat` + fan-out greps | PASS — 14 T-022 files, all fan-out surfaces present |
| AC-9 adversarial: no mid-drain block; report leads; resume free | probes 5, 6-v, 6-vi | PASS |

## verify_all result (CAPTURED, both shells)

```
bash  .harness/scripts/verify_all.sh  → PASS: 32  WARN: 0  FAIL: 0
pwsh  .harness/scripts/verify_all.ps1 → PASS: 32  WARN: 0  FAIL: 0
```
- Total checks: 32 → 32 (no new check; count preserved). Skills 15 (unchanged). Both shells available locally — no run delegated to PM.

## Regression drivers (untouched — CAPTURED, both shells)

| Driver | bash | pwsh | baseline | verdict |
|---|---|---|---|---|
| test-init | 270/0 | 308/0 | 270 / 308 | match |
| test-real-project | 90/0 | 90/0 | 90 / 90 | match |
| test-supervisor | 45/0 | 49/0 | 45 / 49 | match |

Every count equals the baseline exactly — no driver edited, no regression. Stability: verify_all run 3× across this session (initial + 2 mutation passes) — deterministic, no flake.

## Boundary tests (text-as-spec)
- Empty queue → `## Needs your input` reads `None.` (SKILL.md:149, "If there are no deferred items, the section reads `None.`").
- All-tasks-defer → "the stream exits normally per the drained-pool rule — it does not 'halt', it just finishes" (SKILL.md:145).
- Sibling-only dependents → "mark **only** this row's own `Depends on` descendants `blocked`" (SKILL.md:125) — siblings unaffected.
- Re-defer on resume → `needs-human` rejoins the re-runnable set (SKILL.md:118); fresh entry recorded next run (no dedup in v1, per RA §5).
- (c)+(d) same task → hard stop wins (SKILL.md:143 bright line + :137 three-hazard list).

## Adversarial tests (REQUIRED — probes 3, 6, 7, 8)

Each probe states the failure hypothesis, the independent reproducer, and the captured outcome. Verdict is "did the implementation survive", not "did the dev's tests pass".

### Probe 3 — F-1 ASCII / lockstep (independent)
| Hypothesis | Reproducer | Outcome |
|---|---|---|
| The new ambiguity sentence smuggles a non-ASCII char (em-dash/`≡`) | `grep -nP '[^\x00-\x7F]'` on the new-sentence span in all 4 carriers (LC_ALL=C.UTF-8) | **Survived** — 0 non-ASCII in the new sentence (sh:54-56 / ps1:57-59). All flagged non-ASCII is pre-existing surrounding text (header em-dashes, `union ≡ the message`) — out of scope per F-1, allowed. |
| `{{` literal leaked into a carrier | `grep -c '{{'` ×4 | **Survived** — 0 in all 4. |
| dogfood ≠ template per extension | `cmp` ps1, `cmp` sh | **Survived** — IDENTICAL ×2. |
| ps1 emitted block ≠ sh emitted block | extract heredoc/here-string, `tr -d '\r'`, `diff` | **Survived** — IDENTICAL (18 lines each, CR-stripped). |

### Probe 5 — allowed-tools / no surviving blocking ask
| Hypothesis | Reproducer | Outcome |
|---|---|---|
| `AskUserQuestion` survives in frontmatter or a call site of the stream | `grep -nE 'AskUserQuestion' skills/harness-stream/SKILL.md` | **Survived** — 0 hits (removed from frontmatter + both former call sites :76/:115). |
| An orphaned "ask via AskUserQuestion / ask before creating a row" instruction survives in a stream-referenced file | tree-wide grep (excl docs/features) | **Survived** — only hits are harness-adopt:221/242 + harness-upgrade:142 (unrelated interactive skills, file-overwrite/upgrade prompts); none in the stream path. |

### Probe 6 — Behavioral / text-as-spec (apply the shipped text as the stream agent)
| # | Scenario | Clause that forces the verdict | Outcome |
|---|---|---|---|
| i | T-A runnable + T-B returns `BLOCKED: NEEDS-HUMAN — clarify auth scheme` | SKILL.md:125 "set this row `needs-human`; … record the queue entry … **then keep going** to the next ready task … NEVER halt the stream" + :124 `DELIVERED → done` | **Survived** — text forces T-A→done, T-B→needs-human (queue entry recorded), stream CONTINUES. |
| ii | T-B has dependent T-C (`Depends on T-B`) + independent sibling T-D | SKILL.md:125 "mark **only** this row's own `Depends on` descendants `blocked`" | **Survived** — only T-C blocked; T-D stays runnable. |
| iii | A task returns plain `BLOCKED` (dependency block, no `NEEDS-HUMAN` prefix) | SKILL.md:126 "any other `BLOCKED` … NOT prefixed `NEEDS-HUMAN` → `blocked`" | **Survived** — routes to `blocked`, not `needs-human`; tallies stay distinct (step h :127 has 4 buckets). |
| iv | Task REQUESTS a prod deploy (safety-critical action) vs guard-rm BLOCK of an attempted `rm` | SKILL.md:143 "a *request for* a safety-critical action **defers** (the action is not performed); a `guard-rm` *block of a destructive command already attempted* **halts**" + :141 (guard-rm is a hard stop) | **Survived** — deploy request DEFERS (recorded, not performed, not halted); guard-rm block HALTS. Bright line explicit. |
| v | Drain ends 1 done + 2 needs-human | SKILL.md:149 "leading with a `## Needs your input` section (FIRST …)" + :156 "the message … **leads** with the needs-input digest … BEFORE the … tally"; empty-case :149 "reads `None.`" | **Survived** — report leads with the section listing both asks verbatim; exit message leads with digest; 0-deferral → `None.` |
| vi | Re-invoke after human edits pool / sends `ADD` | SKILL.md:118 "a `needs-human` row re-runs once you supply the input" (joined to the re-runnable set verbatim) | **Survived** — `needs-human` is re-evaluated/runnable, not skipped as done. No new mechanism. |
| vii | Mode 2, a rubric-COVERED judgment call | pm-orchestrator Hard rule 6 (:22) "Never auto-decide a reserved point to avoid blocking" + :206 ties deferral to "a point the active decision mode reserves for the human" (rubric-covered → decide, per 25-decision-policy) | **Survived** — over-deferral guarded: defer is reserved for human-reserved points; rubric-covered calls are DECIDED, not deferred. |

No probe is under-determined by the shipped text. No DEFECT.

### Probe 7 — Mutation (load-bearing, proves G.3 pins the bump)
| Hypothesis | Reproducer | Outcome |
|---|---|---|
| G.3 does NOT actually pin the version bump (gate is decorative) | flip `marketplace.json` → 0.32.0; `bash verify_all.sh`; restore → 0.33.0; re-run; `git diff` | **Gate is real** — mutated: `[G.3] … FAIL`, PASS 31 / FAIL 1. Restored: `[G.3] … PASS`, PASS 32 / FAIL 0. Clean restore: marketplace.json diff is exactly the legit single-line 0.32.0→0.33.0 bump; full tree = same 14 T-022 files, no drift/extras. |

### Probe 8 — Stale-claim sweep (independent)
| Hypothesis | Reproducer | Outcome |
|---|---|---|
| A surviving "halt/stop the stream" sentence now contradicts the defer feature | tree-wide `grep -rniE 'halt the stream\|stop the stream'` (excl docs/features, *.html, CHANGELOG) | **Survived** — all 5 hits legitimate: SKILL.md:3 (the NEW "does not halt the stream"), :117 (`STOP` hard-stop), :125 ("NEVER halt"), :135 (hard-stop header), :137 (best-effort framing). No stale needs-human-halts claim. |
| F-2 batch pulled into scope or a false "batch keeps stopping" claim shipped | grep batch SKILL for needs-human/NEEDS-HUMAN/deferred-human mode; grep README×2+CHANGELOG for "batch keeps stopping" | **Survived** — 0 hits in batch SKILL; 0 false claims. Batch retains its own legit `AskUserQuestion` (out of scope, intact). |

## Defects found
None. (0 BLOCKER, 0 CRITICAL, 0 MAJOR, 0 MINOR.) The two code-review minors (m-1 pre-existing link-target wording, n-1 CHANGELOG style) are pre-existing/cosmetic and not introduced by this task — no new defect.

## Baseline
- `.harness/scripts/baseline.json` NOT updated: nothing increased. verify_all stays 32; all driver assertion counts equal the recorded baseline exactly (test-init 270/308, test-real-project 90/90, test-supervisor 45/49). Baseline only goes up; no movement here.

## Checks delegated to PM
None. Both shells (bash + pwsh) ran locally; every tally above is QA-captured.

## Verdict
**PASS — RELEASABLE.** verify_all 32/0/0 both shells; all 5 regression-driver counts match baseline; F-1 (ASCII + 4-file lockstep), F-2 (batch untouched), allowed-tools removal, and all 7 behavioral probes survived; the mutation probe proves G.3 genuinely pins the version bump and the tree restored cleanly; stale-claim sweep finds only legitimate hard-stop references. AC-1..AC-9 all covered with captured evidence.
