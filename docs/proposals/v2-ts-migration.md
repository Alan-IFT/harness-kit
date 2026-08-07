# v2 — shell to TypeScript migration

> Approved 2026-08-07. Not part of the original migration brief; adopted after the P2
> measurement showed CodeGraph cannot index bash or PowerShell, and the follow-on
> measurement showed the twin-shell arrangement is this repo's largest recurring cost.

## Why

| Evidence | Figure |
|---|---|
| PowerShell twin, deleted outright by the port | **502.3 KB** |
| Bash side that is hand-rolled test drivers, replaceable by a test framework | **240.1 KB (54%)** |
| Both shells combined | **947.6 KB** |
| Insight-index entries that are pure cross-shell divergence tax | **9 of 30** |
| Operator obligations pending only because PowerShell cannot be run here | **27, all "Last discharged: never"** |
| Hook latency, `bash guard-rm.sh` | 0.03 s |
| Hook latency, Node cold start | **0.01 s** |

The latency figure is the one that could have vetoed this and did not: `guard-rm` runs on
every Bash tool call, and Node starts faster than the 968-line shell scanner it replaces.

Node is already a hard dependency — Claude Code is a Node application — so requiring it
costs nothing, while requiring `bash` *and* `pwsh` costs two implementations of everything.

By the brief's own test ("does it remove a decision point or add one?"): today every change
forces a cross-shell decision, and 27 decisions are queued awaiting a Windows host.

## Constraints

1. **Zero runtime dependencies.** Node standard library only. The plugin ships files, not an
   install step; a project consuming harness-kit must never need `npm install`.
   `package.json` carries devDependencies only, and `dependencies` must stay empty.
2. **Compiled output is committed**, at `.harness/scripts/<name>.js`, so `sync-self`'s
   existing mirror to `templates/common/.harness/scripts/` keeps working unchanged.
3. **Every cutover is gated by a differential**: the new implementation must be byte-identical
   to the committed shell twin across the input space, compared against the twin as
   committed — never against a value the port itself produced.
4. **Each differential must be proved non-vacuous** by mutating the port and observing the
   failure, before it is trusted.

## Layout

```
src/<name>.ts                     source of truth
.harness/scripts/<name>.js        compiled, committed, ships to projects
tools/diff-<name>.sh              differential gate for that port
tsconfig.json                     strict, outDir .harness/scripts, newLine lf
```

## Stages

| # | Target | Size | Status |
|---|---|---:|---|
| 1 | `hook-spec` | 8.2 KB | **done** — 40/40 byte-identical, twin still in place |
| 2 | `guard-rm` | 36.9 KB | **done** — 87/87 corpus + 62/62 raw, twin still wired |
| 3 | `verify_all` | 47.5 KB | pending |
| 4 | 8 test drivers to a test framework | 240.1 KB | pending |
| 5 | remaining tooling scripts | 120.9 KB | pending |

Stage 1 deliberately does **not** cut consumers over. The port exists and is proven
equivalent; `hook-spec.{sh,ps1}` remain live. Cutover happens when the consumers that call
it are themselves migrated, so no stage leaves a half-wired caller.

### Stage 2 note — `guard-rm` is the dangerous one

It is a fail-CLOSED `PreToolUse` hook. A syntax error exits 2, which reads as a BLOCK and
kills every subsequent Bash call including the one that would fix it; a runtime error exits
1, which is treated as non-blocking, so the guard fails **open** silently. Both failure
modes are silent and asymmetric.

The safety net already exists: `evals/guard-rm-cases.md` carries **97 cases** and
`test-guard-rm.sh` drives them. Run both implementations over that corpus and require
identical verdicts per case before touching the wiring — the same differential discipline
T-16 used. Develop the port unwired, and never let an unproven build reach the hook path.

## Found by the stage-2 differential

Two defects that the 87-case corpus could not see, because **every corpus row asserts a
verdict (BLOCK/ALLOW) and none asserts the resolved path or the message text**.

1. **A fail-open bug in the live bash guard, now fixed.** `resolve_leaf`'s tilde branch read
   `${p#~/}`. Bash tilde-expands the *pattern* there, so it expanded to `$HOME`, never matched
   a literal `~/…`, and stripped nothing — yielding `$HOME/~/rest`. That spurious `~` segment
   absorbs a later `..`, so with a repo root at `$HOME` an outside path collapses to an inside
   one and the guard allows it. The pwsh twin was always correct (`$abs.Substring(2)`); only
   the bash line had diverged, silently, for as long as both have existed. Fixed to `${p#\~/}`
   through the staged-template → `bash -n` → `[guard-path]` drive → `sync-self` sequence the
   insight index prescribes for editing a live fail-closed hook.

2. **The corpus does not instantiate the whole verb set.** An anti-vacuity run showed that
   deleting `shred` from the port's destructive-verb list was caught by *neither* arm: of the
   9 verbs, several are pinned by nothing. `tools/diff-guard-rm.sh` now carries one row per
   verb plus case-folding probes, and one row per carrier and interpreter. Extending
   `evals/guard-rm-cases.md` itself was deliberately not done here — its row count is pinned
   in several documents and the drivers are maintained in lockstep with it, so that is its
   own task.

The differential is proved sensitive across six subsystems: verb set, lexer redirection
sentinel (`-2` → `-1`), depth bound, carrier set, tilde expansion, and containment. Turning
`isDescendant` into a constant `true` — a total fail-open — diverges 52 of 62 raw cases.

## Open

- CodeGraph will index both `src/*.ts` and the emitted `.harness/scripts/*.js`, producing
  duplicate symbols. Harmless for now; revisit if the noise matters.
- `vitest` is deliberately not a dependency yet. It arrives at stage 4, where it is
  actually used, rather than sitting unused with an unapproved `esbuild` postinstall.
