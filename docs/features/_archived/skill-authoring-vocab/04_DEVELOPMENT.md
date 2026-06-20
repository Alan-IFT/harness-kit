# 04 — Development Record · T-04 `skill-authoring-vocab`

**Mode:** full · **Stage:** 4 (Developer) · **deferred-human:** defer
**Upstream:** 01 READY · 02 READY · 03 APPROVED FOR DEVELOPMENT. Implemented exactly per `02_SOLUTION_DESIGN.md` §7.

## Summary

Two additive edits to the dogfood rule `.harness/rules/15-skill-authoring.md`: (1) one sibling
provenance sentence crediting mattpocock/skills `writing-great-skills` / its `GLOSSARY.md`,
joined into the existing intro paragraph (Anthropic line + URL left byte-stable); (2) a new
`## Named vocabulary (mattpocock/skills)` section inserted between the end of P8 and
`## Deliberately not adopted`, carrying seven terse named handles. No code, schema, or runtime
surface; P1–P8 are byte-stable; no version/README/CHANGELOG/skill-count/plugin.json fan-out;
no new verify_all check; no harness-sync (rules are referenced, not synced — AI-GUIDE.md:75,106).

## Files changed

- `.harness/rules/15-skill-authoring.md` — (7a) appended one provenance sentence to the intro
  paragraph (the new sentence re-wrapped two adjacent lines of that same paragraph; no
  information lost, Anthropic attribution + URL unchanged); (7b) inserted the new
  `## Named vocabulary (mattpocock/skills)` section (heading + 2-line intro + 7 bullets) between
  P8 (live line 62) and `## Deliberately not adopted`.

No other source file touched by this task.

## AC self-review (against 01 §5 / design §7)

| AC | Status | Evidence |
|---|---|---|
| AC-1 all seven concepts named (leading word, completion criterion [checkable+exhaustive], premature completion, no-op test, sediment+sprawl, single source of truth, user-invoked vs model-invoked w/ context load vs cognitive load) | PASS | All seven present in the new section; completion-criterion axes "checkable"/"exhaustive" and load pair "context load"/"cognitive load" named inline. |
| AC-2 no-op test → P2, leading word → P1 (generalizes) | PASS | "The named handle for **P2**"; "Generalizes **P1**". |
| AC-3 sediment/sprawl → P5 + `70-doc-size.md`; single source of truth → anti-bloat / "Deliberately not adopted" stance | PASS | "Cure both via the **P5** … ladder and the `70-doc-size.md` cap"; "the repo's existing anti-bloat stance … see 'Deliberately not adopted'". |
| AC-4 the 3 genuinely-new (completion criterion, premature completion, load lens) NOT falsely mapped to a P-number | PASS | Marked `*(new — no prior handle)*` / `*(new lens)*`; none carry a `→ Px` mapping. |
| AC-5 P1–P8 present, numbered 1–8, original meaning intact (additive only) | PASS | `git diff` second hunk is pure-add (0 deletions in the principles block); P1–P8 byte-stable. |
| AC-6 mattpocock/skills `writing-great-skills` credited (one line) | PASS | Provenance sibling sentence names mattpocock/skills `writing-great-skills` / `GLOSSARY.md`; Anthropic line preserved. |
| AC-7 final file ≤200 lines | PASS | 115 lines (cap 200; design projected ~108). |
| AC-8 verify_all green, no new FAIL/WARN (esp. I.2, I.6) | PASS | 32/0/0, identical to baseline; I.2 and I.6 both PASS. |
| AC-9 no fan-out (plugin.json/README/CHANGELOG/skill-count/templates byte-untouched by this task) | PASS | This task modified only `.harness/rules/15-skill-authoring.md`. |

### I.6 banned-literal check (R-1)

The new prose contains none of the live I.6 anchor sequences (verify_all.ps1:486-501):
no `CLAUDE.md`, `composed`/`composition`, `regenerate(s/d)`, `scaffolding-only`,
`Generated from`, `生成`/`合成`/`重新生成的`, or `全程中文`. Confirmed by a clean I.6 PASS.

## verify_all result

- **Baseline (pre-edit):** PASS 32 / WARN 0 / FAIL 0 (`bash .harness/scripts/verify_all.sh`).
- **After changes:** PASS 32 / WARN 0 / FAIL 0.
- **Delta:** 0 new FAIL, 0 new WARN; check tally unchanged (no gate added). I.2 (≤200 rule
  fragment) and I.6 (retired-claim guard) both PASS.
- PowerShell (`verify_all.ps1`) is PM-to-run (denied to sub-agents); not faked here. The `.sh`
  twin is authoritative for this stage; the I.6 banned list is the 1:1 twin of the `.ps1` list
  (test-verify-i6 asserts lockstep), so the I.6 result transfers.

## Final line count

`.harness/rules/15-skill-authoring.md` = **115 lines** (was 80; +35 net). Cap 200 — 85 lines of
headroom. (Design projected ~108; actual 115 due to bullet wrapping at the design's exact
wording — within the "exact wrap is free as long as ≤200" contract of §7c.)

## git diff --name-only (T-04 scope)

Attributable to this task: only
- `.harness/rules/15-skill-authoring.md`
- `docs/features/skill-authoring-vocab/` stage docs (this `04_DEVELOPMENT.md` + the 01/02/03/INPUT docs)

The repo working tree also shows unrelated modifications from sibling stream-pool tasks
(T-02 `context-glossary`, T-03 `harness-grill`, and their fan-out to plugin.json / README /
CHANGELOG / docs / agents / scripts). Those are **not** T-04's: this task touched no file
outside the two paths above. The dev-map already lists `15-skill-authoring.md` (line 70) and
no file was added/moved/removed, so no dev-map update is required.

## Design drift (if any)

None. Implemented verbatim per §7a/§7b wording. Line count is 115 vs the ~108 projection, which
§7c explicitly licenses ("Developer may reflow bullets … exact wrap is free as long as ≤200").
Not flagged as drift — it is within the stated contract.

## Open issues for review

None blocking. One note for the reviewer: the `git diff --name-only` over the whole repo lists
many files because this runs in a shared stream working tree; verify the T-04 hunk in isolation
via `git diff -- .harness/rules/15-skill-authoring.md` (two hunks: the provenance paragraph and
the new section; P1–P8 block unmodified).

## Dev-map updates

None. No file added/moved/removed; `docs/dev-map.md:70` already indexes the edited rule.

## Verdict

READY FOR REVIEW
