# 05 — Code Review: stream-auto-decompose (T-021)

> Mode: full · Reviewer: code-reviewer · Date: 2026-06-12
> Inputs: 01 (READY) · 02 (READY) · 03 (APPROVED, C-1..C-4) · 04 (READY FOR REVIEW) — all claims re-verified against the live tree, not trusted.
> (Materialized verbatim by PM — the code-reviewer thread had no Write tool; content authored by code-reviewer.)

## Files reviewed

- `skills/harness-stream/SKILL.md` (full read, 175 lines)
- `.harness/scripts/ambient-prompt.{ps1,sh}` + `skills/harness-init/templates/common/.harness/scripts/ambient-prompt.{ps1,sh}` (all four, full read)
- `README.md:5,21,275` · `README.zh-CN.md:5,21,277` · `CHANGELOG.md:8-18` · `.claude-plugin/plugin.json:4` · `.claude-plugin/marketplace.json:17` · `docs/batches/README.md:33`
- NO-CHANGE spot-checks: `.harness/rules/25-decision-policy.md:52-53`, `AI-GUIDE.md:88-97`, `skills/harness-batch/SKILL.md:71`, `skills/harness-intervene/SKILL.md:42`, `.harness/rules/65-intervention.md:53`, `docs/harness-stream.html:6` (still v0.22.0-pinned), `test-init.ps1:325-332`, `test-init.sh:288-294`
- Regression greps: `normalize it into a \`pending\` row`, `Mode=full`, `into a/one pending row`, `Ingest triage`, 1:1-shaped phrasing — live tree

## Design fidelity (dimension-by-dimension verification)

1. **§3.1 triage section** (`SKILL.md:84-103`): design text verbatim, re-wrapped one-line-per-paragraph (design-sanctioned "verbatim modulo line-wrap"). Word-level diff against design §3.1: zero dropped or weakened contract terms — applies-to scope (:86), general never-re-triage (:86), both conjunctive criteria (:88-90), three NOT-complex counter-examples (:92), N ≥ 2 same-columns (:94), slug prefix + Notes provenance format (:95), union invariant + ambiguity-ask (:96), real-deps-only (:97), Mode per row (:98), fixed point (:99), per-row de-dup (:100), announce + correction channels (:101), 1:1 fallback + derived-rows-are-ordinary (:103).
2. **Procedure 3a** (`SKILL.md:115`): exact §3.2 text; "per "Ingest triage" above" (binding); de-dup + ambiguity-ask clauses retained. `ADD` bullet clarifier landed at :116 per §3.3/D-4.
3. **Ambient step 1** (`SKILL.md:76`): exact §3.4 text; `Mode=full` retired ("`Mode` per row, default `full`"); ambiguity gate first, unchanged; "no row for question/aside" intact.
4. **Hard rule** (`SKILL.md:162`): exact §3.5 text joined to one line. Union both directions ("no invented scope, no dropped scope"), "Work the user did not ask for is never added", "rows the user authored (`ADD` lines, hand-written pool rows) are never split or rewritten" — all verbatim.
5. **§3.6 trio**: description trigger sentence (`SKILL.md:3`), anti-pattern bullet (:171), Cost sentence (:175) — all verbatim per design.
6. **Hook block** (§4): emitted step 1 in all four carriers matches design §4 word-for-word, including "union ≡ the message".

No silent design drift. The Developer's two declared presentation notes (04 §Design drift) are both inside the design's stated latitude — confirmed.

## Binding conditions C-1..C-4

- **C-1 SATISFIED.** Criteria exist exactly once (`SKILL.md:84-103`; "Triage test" grep: single hit). All three consumers bind with "per": Procedure 3a :115 ("per "Ingest triage" above"), ambient step 1 :76 ("per "Ingest triage" below" — direction correct, section is below :76 and above :115), hook block ("N rows per skills/harness-stream/SKILL.md "Ingest triage""). No "see also" phrasing anywhere.
- **C-2 SATISFIED.** Protected trio verbatim at :162 (union both directions / never-add-unrequested / never-split-user-authored). The GENERAL never-re-triage clause ships in the F-4-confirmed wording at :86; generality is additionally secured by the fixed-point bullet (:99) and ":103 derived rows are ordinary pool rows" — pool rows are never triage inputs (triage's only input is the message). Termination stays triple-layered as the Gate found.
- **C-3 SATISFIED.** File is exactly 175 lines (read-verified) ≤ 198. Met by re-wrapping, zero contract-term trimming (word-level diff above). QA's §12.7 assert holds without re-baseline.
- **C-4 SATISFIED.** Four carriers carry identical emitted blocks: ps1 :47-63 / sh :44-60 = 17 lines each (15 → 17, +2 per NFR-1); ps1 ↔ sh textually identical; dogfood ↔ template identical per extension (line-for-line read compare, comments included). `\{\{` grep: 0 hits in all four. `\r` grep: 0 hits in all four — all LF, no here-string/heredoc CR asymmetry (the known defect class is absent). Single-quoted here-string `@'…'@` / quoted heredoc `<<'EOF'` — no interpolation surface.

## Requirement coverage check

| Criterion | Implementation evidence | Status |
|---|---|---|
| AC-1 | Criteria once at `SKILL.md:84-103`; binding pointers :76 + :115 (D-1 reading, Gate-confirmed) | ✅ |
| AC-2 | Amended rule `SKILL.md:162`; `25-decision-policy.md:52-53` untouched, still truthful ("never invented autonomously" mirrors "never added") | ✅ |
| AC-3 | 4 carriers identical blocks (above); dogfood ≡ template per extension; 04 reports cmp/diff-verified, consistent with reads | ✅ |
| AC-4 | `SKILL.md:95` shared `<base>-` prefix + `## Notes` provenance line, decidable from `BATCH_PLAN.md` alone; schema columns unchanged (:94 "same columns, no schema change") | ✅ |
| AC-5 | Text dictates all four probe outcomes: (i)/(iv) via :92 counter-examples + conjunctive test, (ii) via :97 "`—`", (iii) via :89 phased signal + :97 real chain; fixed-point via :99. QA executes the probes | ✅ (text-level) |
| AC-6 | 32/0/0 both shells claimed from real runs (04); G.3 badges 0.32.0 ×2, G.4 `[0.32.0]` heading ↔ plugin.json 0.32.0 verified by read; no banned-anchor-shaped sentence introduced. PM holds tallies | ✅ (claims internally consistent) |
| AC-7 | Stale-claim greps: `normalize it into a \`pending\` row` and `Mode=full` → 0 live hits (only exempt `docs/features/` + archived docs + historical CHANGELOG :139); no 1:1-shaped live phrasing found; `docs/batches/README.md:19` is batch-authoring, correctly untouched | ✅ |
| AC-8 | `test-init.ps1:325-332` / `test-init.sh:288-294` read: command-wiring asserts only, no SKILL/block-content pin; drivers untouched; 04 claims both green unmodified | ✅ |

## Cross-file truthfulness

- **README.md:21 / zh:21** — en bullet verbatim per design §5; zh bullet is a faithful mirror ("复杂的多部分需求会在入池时自动分诊拆解…简单需求仍是一行；你自己写的行 —— `ADD` / 手写 —— 原样执行"). Roadmap rows :275 (en, design-verbatim) / :277 (zh, faithful) after the 0.31.0 rows. Badges 0.32.0 both (:5).
- **CHANGELOG.md:8-18** — heading format matches predecessors (`## [0.31.0] - 2026-06-11` style); date = today; content accurately describes what shipped (single-sourced section, pointer binding, union invariant, 4-file lockstep +2 lines, doc fan-out, counts stay 15/32); closing version line matches design.
- **docs/batches/README.md:33** — sentence consistent with the SKILL contract (triage scope, prefix + Notes, user-authored honored as-is).
- Versions consistent everywhere: plugin.json:4, marketplace.json:17, both badges = 0.32.0.
- **04 truthfulness:** every claimed line anchor re-verified exact (SKILL 3/76/84-103/115/116/162/171/175 = 175 lines; hooks 52-57/49-54; README 5/21/275; zh 5/21/277; CHANGELOG 8-18; batches 33). No internally contradictory claim found.

## Internal consistency & adversarial reading

- No contradiction with K-empty-passes exit (:127/:169), resume semantics (:118 — Status/07_DELIVERY only, derived rows indistinguishable), mirror-to-pool rule (:47/:161 — true for N rows), or the ambiguity-ask rule (:76/:96/:115 — gate stays first; un-placeable outcome is *defined* as ambiguity).
- Over-decomposition guarded by the conjunctive test + three counter-examples + anti-pattern :171; "independently verifiable deliverable" is pinned to the pipeline's own QA/DELIVERED semantics — tight enough to be decidable.
- ID/slug collisions on a second decomposition: per-row de-dup (:100, :115) handles them by the existing rule.

## Findings

### BLOCKING
None.

### MAJOR
None.

### minor / nit
- **m-1 [DESIGN, residual] `SKILL.md:95`** — If two different requirements ever derive the same `<base>` slug, prefix-grouping conflates the groups; the dated, requirement-quoting Notes lines still disambiguate per decomposition, and per-row de-dup forces distinct slugs, so FR-5 decidability degrades only in this pathological case. Accepted residual of design D-2. Action: none required; PM may optionally log as an insight candidate.
- **n-1 [MAINT] `SKILL.md:86`** — The general never-re-triage clause grammatically rides the user-authored-rows sentence. Gate F-4 explicitly ruled this exact wording binding-general, and :99 + :103 reinforce it. Action: none (Gate-sanctioned wording, shipped verbatim).

## Verdict

**APPROVED**
