# Task Input — context-glossary (T-02)

**Mode:** full
**Dispatched by:** /harness-stream (default pool), PM shell in main thread (runtime: sub-agents have no Task/Bash/PowerShell — PM runs verify_all & tests).
**deferred-human mode:** defer, do not ask. If a point genuinely belongs to the human under the active decision mode (Mode 2, see `.harness/rules/25-decision-policy.md` + `.harness/decision-rubric.md`), return `BLOCKED: NEEDS-HUMAN — <q> — <unblock>` rather than asking interactively.

## Goal (one sentence)

Add a `CONTEXT.md` domain-glossary memory layer (tight definition + `_Avoid_` format) as a dogfood file and a harness-init template asset, wired as a SOFT dependency that the requirement-analyst and solution-architect reference and lazily maintain, indexed in AI-GUIDE.md — killing verbose / inconsistent domain naming at the root with no new verify_all guard.

## Origin & rationale

This is T-02 of a 6-task batch adopting ideas distilled from a deep read of github.com/mattpocock/skills (★136k). The standout idea: a **shared language** file (`CONTEXT.md`) — a project glossary of domain terms, each a one/two-sentence definition plus an `_Avoid_` list of synonyms not to use. Benefits the author cites: fewer tokens (one term replaces a long phrase — e.g. "the materialization cascade"), consistent naming of variables/functions/files, codebase easier for the agent to navigate.

Reference material (shallow clone on disk, read-only):
- `c:\Programs\_research\mattpocock-skills\skills\engineering\domain-modeling\CONTEXT-FORMAT.md` — the exact format (definition + `_Avoid_`; "be opinionated", "tight definitions", "only domain-specific terms, not general programming concepts", group under subheadings; single- vs multi-context via `CONTEXT-MAP.md`).
- `c:\Programs\_research\mattpocock-skills\skills\engineering\domain-modeling\SKILL.md` — the maintenance discipline (challenge against glossary, sharpen fuzzy terms, update inline, lazy-create).
- `c:\Programs\_research\mattpocock-skills\CONTEXT.md` — a real example (this repo's own analogue would name terms like *frontier*, *pool*, *ambient*, *partition agent*, *stage doc*, *verdict*, *insight*, *rollback*).
- `c:\Programs\_research\mattpocock-skills\docs\adr\0001-...md` — the **soft vs hard dependency** principle: only HARD dependencies get an explicit setup pointer; SOFT dependencies reference docs in vague prose and degrade gracefully when absent. CONTEXT.md must be wired as a SOFT dependency.

## Scope guidance (for the analyst to make testable, not to pre-design)

In scope: a dogfood `CONTEXT.md` at this repo root (seeded with this repo's genuine domain terms); a template asset so generated projects get a `CONTEXT.md` seed/skeleton; SOFT-dependency wiring into `requirement-analyst` and `solution-architect` (reference + lazy-maintain, degrade gracefully); one index line in AI-GUIDE.md memory layer; dev-map.md location entry.

Out of scope (unless the analyst argues otherwise with evidence): any new `verify_all` guard/check (explicit user preference: design out root causes, do not accrete guards — see [[feedback_design_over_guards]]); the multi-context `CONTEXT-MAP.md` machinery (single-context is fine for this repo — mention as future); ADR machinery (we already produce 02_SOLUTION_DESIGN per task); a dedicated domain-modeling *skill* (the maintenance habit folds into RA/SA prose this round).

## Insights to honor (from .harness/insight-index.md — verify before relying)

- Doc-size caps: AI-GUIDE.md ≤200 lines (I.1), rule fragments ≤200 lines (I.2). Adding the index line + any RA/SA prose must stay under cap.
- I.6 retired-claim guard scans current docs/templates for banned phrases; do not introduce banned anchors. A new doc that quotes a banned phrase self-trips.
- Template fan-out: `test-init` globs every generated `.ps1/.sh/.md/.json` for unresolved `{{PLACEHOLDER}}`. A `CONTEXT.md` template must contain no unresolved placeholder (or assemble the token at runtime). Only the 7 documented placeholders are whitelisted (D.2).
- A template asset that is also dogfooded is NOT necessarily byte-synced: like `decision-rubric.md`, the template seed is GENERIC while the repo's own `CONTEXT.md` carries real content. sync-self mirrors only the 7 script pairs — CONTEXT.md is not a script pair.
- New template files are exercised by `test-init` / `test-real-project`; a new always-present template asset may shift their asset counts (baseline.json reconcile from a captured run).
