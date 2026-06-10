# Delivery — agents-cutover (v0.30.0, redesign Leg 1 complete)

- Date: 2026-06-10
- Status: **DELIVERED**
- Final verify_all result: PASS (32/0/0)

## What shipped

The content-model redesign's **Leg 1 is complete**: the 8 framework agents are now provided by the
harness-kit plugin (top-level `agents/`, dispatched as `harness-kit:<name>`) and are **no longer
copied into each project**. The per-project agent **duplication/drift class is eliminated** — "update
the plugin == every project's framework agents current" (the proven property the 15 skills already had,
now extended to agents). Generic framework agents = plugin; project-specific **partition `dev-*`
agents stay local** (type-parameterized). Default init is plugin-native; `--portable` is the documented
best-effort opt-in for tool-agnostic/offline use.

## Implementation

Operator-spec'd, implemented by `harness-kit:developer` (dogfooding the very plugin agents this ships),
operator-verified. Retired 24 generic agent copies (`.harness/agents/`, `.claude/agents/`,
`templates/common/.harness/agents/`); repointed gates D.1/E.3/E.4/I.3 + removed sync-self's agent legs;
switched pipeline dispatch in the 6 pipeline skills + `agents/pm-orchestrator.md`; updated init +
test-init/test-real-project/test-supervisor + AI-GUIDE/README×2/40-locations/dev-map; 0.29.0 → 0.30.0.

## Verification (operator-run, captured)

- `bash verify_all.sh` → **32 PASS / 0 WARN / 0 FAIL**.
- `bash test-init.sh` **249/0** · `test-real-project.sh` **82/0** · `test-supervisor.sh` **45/0** — all
  match `baseline.json`. (PowerShell side run green by the implementing developer — 32/0/0, test-init
  287 — but NOT operator-run here; confirm on Windows for full belt-and-suspenders.)
- Plugin-agent dispatch confirmed live earlier this session (`harness-kit:supervisor` +
  `harness-kit:requirement-analyst` smoke tests).

## Known follow-ups (deferred, flagged for review)

1. **Generated-project template docs still describe the old model** — `templates/common/AI-GUIDE.md.tmpl`,
   `00-core.md.tmpl`, `generic/50-generic.md.tmpl` still place framework agents under `.harness/agents/`.
   A default (plugin-native) generated project would get slightly-stale docs (functional dispatch is
   correct via the updated skills; only the generated *doc* is inaccurate). Refresh them next — part of
   finishing the user-facing cutover. Accurate under `--portable`.
2. **`--portable` is documented, not separately built/CI-tested** — per the decided positioning
   (Claude-native by default; the operator is Claude-Code-only). A real `--portable` init branch +
   regression is a follow-up if the public non-Claude audience is to be served without regression.
3. **Legs 2 (rules + AI-GUIDE plugin-resident) and 3 (scripts/hooks)** remain — Leg 2 is gated on the
   inline `@${CLAUDE_PLUGIN_ROOT}` spike (see `docs/proposals/plugin-native-redesign.html`).
4. **Existing-project migration** (`/harness-upgrade` "framework-externalize" phase to delete the now-
   redundant local copies) is unbuilt — existing projects keep working (their copies are unused; the
   pipeline dispatches the plugin agents).

## Insight

- 2026-06-10 · The feared "atomic cascade" of retiring per-project framework copies was, in reality, only **3 gate FAILs** (D.1 template-agents, E.3 agent-existence, E.4 `.claude/agents`-dir) — E.1/E.2/I.3 absorbed the missing dirs cleanly because each guards with `if [[ -d ]]` / sync-check-of-absent = no-drift. Mapping the actual gate logic (one diagnostic `verify_all` after the `git rm`) beat reasoning about a cascade in the abstract. The agents cutover (top-level `agents/` → `harness-kit:<name>`, no per-project copy) ELIMINATES the agent copy/drift class by construction, the same way the 15 skills already work — verified end-to-end (live dispatch + 32/0/0 + 4 regressions green). · evidence: agents-cutover v0.30.0, verify_all post-`git rm` showed exactly D.1/E.3/E.4
