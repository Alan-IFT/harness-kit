# Development Record · sa-design-vocab (T-07)

**Mode:** full · **Stage:** 4 (Developer) · **Gate:** APPROVED FOR DEVELOPMENT (0 findings).
**Date:** 2026-06-20 · **Verdict:** see end.

## Summary

Appended one OPTIONAL `## Design vocabulary (optional lens)` section to the plugin-native framework
agent `agents/solution-architect.md` (the verbatim §3 inner content — the 7-term deep-module
glossary + deletion test / interface-is-the-test-surface / one-vs-two-adapter + one combined
deferred-pointer line), framed as a lens the architect MAY reach for, NOT a mandate and NOT a new
required `02_SOLUTION_DESIGN.md` field. Shipped the standard version fan-out 0.37.0 → 0.38.0 across
the four stamp surfaces + a `[0.38.0]` CHANGELOG entry. Counts (16 / 8 / 32) untouched; no new check.

## Files changed (6)

1. `agents/solution-architect.md` — appended the new `## Design vocabulary (optional lens)` section
   after the existing `## What "bad" looks like (avoid)` block (one blank-line separator, then the
   section). Pasted only the INNER content of the design §3 four-backtick `` ````markdown `` display
   fence (heading through the `_Future options …_` line) — NOT the outer fence (gate Q2 honored).
   Lines 1-122 (the 12-section output contract at 14-29, Hard rules, Workflow, Mode note, Reuse-audit
   format, Partition-assignment format) byte-unchanged; additive insertion only.
2. `.claude-plugin/plugin.json` — `version` 0.37.0 → 0.38.0 (line 4).
3. `.claude-plugin/marketplace.json` — `plugins[0].version` 0.37.0 → 0.38.0 (line 17).
4. `README.md` — badge `version-0.37.0-blue` → `version-0.38.0-blue` (line 5, that token ONLY;
   the 32%2F32 / 308 / 90 / MIT badges left intact; NO count token touched).
5. `README.zh-CN.md` — same badge `version-` token bump (line 5, token only).
6. `CHANGELOG.md` — prepended the `## [0.38.0] - 2026-06-20` entry (verbatim from design §9
   §-CHANGELOG) above `## [0.37.0]`; restates 16 skills / 8 framework agents / 32 checks UNCHANGED,
   no new check, no I.6 list change, no sync / no template copy.

## Acceptance-criteria self-review (RA §5)

- **AC-1** — all seven terms present, each one line (module / interface / depth / seam / adapter /
  leverage / locality). PASS.
- **AC-2** — deletion test, "the interface is the test surface", "one adapter = hypothetical seam,
  two = real" each present as a single concise line. PASS.
- **AC-3** — interface = "everything a caller must know … the type signature *and* invariants,
  ordering constraints, error modes, required config, and performance characteristics. Broader than
  the signature alone." PASS.
- **AC-4** — framed optional: heading "(optional lens)" + lead "A lens you **may** reach for …
  leading words to think *with*, not a checklist … and not a required `02_SOLUTION_DESIGN.md` field".
  No mandate; the 12-section output contract (lines 14-29) is byte-unchanged. PASS.
- **AC-5** — design-it-twice + DEEPENING four-category taxonomy appear only inside ONE combined
  deferred-pointer line (name-only, no procedure). PASS.
- **AC-6** — additive diff: my change to the agent file is a pure append after line 122; no existing
  line in the section list / contract / rules was edited by T-07. PASS.
- **AC-7** — `agents/solution-architect.md` = 144 lines ≤ 300. PASS.
- **AC-8** — 0.38.0 on all four stamp surfaces (plugin.json:4, marketplace.json:17, README:5,
  README.zh-CN:5) + a dated `## [0.38.0]` CHANGELOG entry; counts stay 16 / 8 / 32. PASS (G.3 + G.4).
- **AC-9** — `verify_all.sh` PASSes 32/0/0, same total as baseline; no new WARN/FAIL; check total
  stays 32. PASS.

## verify_all result (`bash .harness/scripts/verify_all.sh`)

- Baseline (pre-change): **PASS 32 / WARN 0 / FAIL 0**.
- After changes: **PASS 32 / WARN 0 / FAIL 0**.
- Delta: **0 new failures, 0 new warnings; baseline preserved.**
- Spot-checks: G.3 PASS (0.38.0 ×4), G.4 PASS ([0.38.0] heading + counts 32, claim↔version
  consistent), I.3 PASS (144 ≤ 300), I.6 PASS (clean — no banned anchor, no forward `name.ext:NNN`
  in the new prose).
- `verify_all.ps1` (PowerShell) is operator-to-run (PS denied to this agent); not faked here.

## Final line count

`agents/solution-architect.md` = **144 lines** (projected ~145; ≤300 cap, headroom > 156 lines).

## Design drift

None. The section was pasted verbatim from design §3 (inner content of the four-backtick fence).
The one `02_SOLUTION_DESIGN.md` reference inside the lead sentence is a deliberate NEGATION ("not a
required `02_SOLUTION_DESIGN.md` field") — a doc-name token, NOT a forward-looking `name.ext:NNN`
path:line, so Hard rule 6 is honored (no line number attached). I.6 confirms clean.

## T-07 git diff --name-only (the 6 edited files + stage docs)

```
agents/solution-architect.md
.claude-plugin/plugin.json
.claude-plugin/marketplace.json
README.md
README.zh-CN.md
CHANGELOG.md
docs/features/sa-design-vocab/04_DEVELOPMENT.md   (this doc)
```

> NOTE on the raw working tree: this batch (T-02 … T-06) was run earlier and left UNCOMMITTED, so
> `git status` shows many unrelated modified/untracked files and `git diff HEAD` (HEAD = v0.33.0,
> commit 93fbfbb) is polluted with prior-task drift (e.g. the 15→16 skill-count flip and the
> harness-grill README lines are T-03 work, NOT T-07). The pre-T-07 working-tree state was already
> 0.37.0 / "16 skills"; T-07 bumped 0.37.0 → 0.38.0 and touched NO count token. The list above is
> the T-07-only footprint.

## Open issues for review

None blocking. Reviewer note: when diffing T-07, compare against the pre-T-07 working-tree state
(0.37.0 / 16 skills), not against committed HEAD (0.33.0) — the older HEAD makes `git diff HEAD`
show prior batch tasks' changes interleaved with T-07's. T-07's own footprint is the append in
`agents/solution-architect.md` (second hunk, after line 122), the four `version-`/`"version"` token
bumps, and the prepended `[0.38.0]` CHANGELOG block.

## Dev-map updates

None. No file/module added, moved, or removed — all six edits are content changes to existing files.
`docs/dev-map.md` already describes `agents/*.md` as the plugin-native framework-agent single source.

## Verdict

READY FOR REVIEW
