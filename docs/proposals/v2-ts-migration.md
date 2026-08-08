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

> **Correction, measured 2026-08-08 over 60 runs per path** (`evals/measure-hook-latency.sh`,
> which now re-derives this instead of citing it): the real cost is **19 ms median on the allow
> path and 20 ms on the block path**, not 0.01 s. The original figure was taken from a coarse
> single-run `time` and understated it by roughly half. The decision does not change — the
> shell twin measured worse on the same box — but the margin does: the guard now sits **on**
> the brief's 20 ms ceiling rather than comfortably under it. The launcher is not the cause;
> `node guard-rm.js` invoked directly measures 18 ms, so ~18 ms is Node's own start-up and the
> `bash` launcher adds ~1 ms. Getting materially below this needs the single-binary option the
> brief lists, which trades a build toolchain for ~10 ms per call — not taken, and re-openable
> the moment the instrument reports over the ceiling, which it exits non-zero to say.

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
5. **A twin may not be deleted until its port has native tests.** The differential is a
   *migration* instrument: it measures the port against the shell file and dies the day that
   file is removed. A port whose only evidence is the differential has, at cutover, no
   evidence at all. Native tests are the thing that outlives the migration, and they must
   exist first — see stage 4's ordering below.

## Layout

```
src/<name>.ts                     source of truth
.harness/scripts/<name>.js        compiled, committed, ships to projects
.harness/scripts/<name>.sh  two-line launchers; no logic, nothing to diverge
tests/unit/<name>.test.ts         native tests — these outlive the migration
tools/make-shims.sh               generates the launcher pair for a ported name
tsconfig.json                     strict, outDir .harness/scripts, newLine lf
```

Constraints 3 and 4 describe the differential discipline as it was practised through
stages 1–3. All three differentials were deleted once their components were cut over —
see "The cutover" below for why keeping them would have been worse than useless.

## Stages

| # | Target | Size | Status |
|---|---|---:|---|
| 1 | `hook-spec` | 8.2 KB | **done + cut over** — launcher is 699 B; 24 native tests |
| 2 | `guard-rm` | 36.9 KB | **done + cut over** — launcher is 694 B; 93 native tests; live hook runs it |
| 4a | vitest + native tests | — | **done** — 150 tests across the three ports |
| 3 | `install-hooks` | 16.3 KB | **done + cut over** — launcher is 719 B; 33 native tests |
| 6 | `verify_all`, **rewritten slim** | 47.5 KB | pending |
| 4b | remaining 7 shell test drivers | ~228 KB | pending |
| 5 | remaining tooling scripts | 120.9 KB | pending |

Stage 4 was pulled ahead for the reason in constraint 5: a ported component needs native
tests before its twin can go, and the gate is easier and safer to port once a test
framework exists to port it against.

**Stage 3 was then re-aimed from `verify_all` to `install-hooks`.** Of `verify_all`'s 32
checks, roughly 25 verify the scaffolding's own documentary self-consistency — exactly what
§9.2 of the migration brief says to delete when it is slimmed to secret scan, lint, test,
build and guard wiring. Porting those faithfully would be porting code the plan already
intends to remove. `verify_all` therefore moves to stage 6 and will be **rewritten slim
rather than ported**, which is a separate decision from this migration and should not be
mixed into it.

`install-hooks` was the better target: §9.2 keeps it, it is the consumer of `hook-spec`, and
porting it completes a vertical slice — `hook-spec` + `guard-rm` + `install-hooks` is the
entire safety-hook subsystem, now in one language.

The port **imports** the spec instead of shelling out to it. The bash original spawned
`bash hook-spec.sh` seventeen times per run (1 hostos + 1 tools + 4 × 4 per-tool); the port
reads the same single source of truth in-process. The ALL-FOUR-OR-NOTHING and
FOUR-DISTINCT-EVENTS invariants are kept even though the spec is now a typed import — they
guard against a future edit producing a partial wiring that still passes the terminal
confirmation, which is derived from those same answers.

The native suite paid for itself on its first run by finding a **fail-open divergence the
62-case differential could not see**: `extractCommand` ran its heuristic fallback only when
`JSON.parse` threw, whereas the shell twin gates its fallback on the extracted command being
*empty*. A payload that parses as JSON but carries the command outside `tool_input.command`
was therefore returned as `''` and allowed unexamined. Every differential case used a
well-formed payload, so only a test written against the contract rather than against the
twin could reach it.

Stage 1 deliberately does **not** cut consumers over. The port exists and is proven
equivalent; `hook-spec.sh` remain live. Cutover happens when the consumers that call
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

## Why the remaining stages are worth less than the headline

The 947.6 KB figure overstates what is left to gain. Most of the unported shell is
scaffolding §9.1 of the migration brief intends to delete:

- `verify_all` — ~25 of its 32 checks verify documentary self-consistency that §9.2 removes
- `test-harness-upgrade` tests `upgrade-project`, which §9.1 deletes
- `test-language` tests `language-policy`, which §9.1 deletes
- `test-supervisor` tests `/harness-supervise`, which §9.1 deletes
- `test-verify-i6` tests a check the slim rewrite removes

The durable set — the scripts §9.2 explicitly keeps — is `guard-rm`, `hook-spec`,
`install-hooks` and a slim `verify_all`. **Three of those four are done.** Further porting
is largely work on code the plan already intends to remove, so the remaining value is in
the cutover, not in more ports.

## The cutover: launchers, not replacements

The broad cutover described below was scoped and then **not done that way**. Measured
surface: 27 files reference `guard-rm.sh`, and `hook-spec` is called by 16 scripts
including `verify_all` and `sync-self`. Rewriting all of them would also mean patching
`upgrade-project` and `migrate-scripts-layout`, both of which §9.1 deletes — doomed work
again — and touching the 64 KB `test-init.sh`.

**What was done instead: each ported script's `.sh` and `.ps1` became a two-line launcher
over the compiled `.js`.** `exec node "$(dirname -- "$0")/<name>.js" "$@"` replaces the
shell, so stdin, stdout, stderr and the exit status pass through untouched.

That buys the actual goal at a fraction of the risk. The logic is single-sourced in
TypeScript, so there is nothing left in the shell files to diverge — the cross-shell
divergence class and the PowerShell-only maintenance burden are gone. And because the
launcher keeps the same path and the same name, **nothing else had to change**: not the 27
referencing files, not the deliberately-frozen byte-form literals, not the live hook
wiring in `.claude/settings.local.json`.

Sizes after: `guard-rm.sh` 36.9 KB → 694 B, `hook-spec.sh` 8.2 KB → 699 B,
`install-hooks.sh` 16.3 KB → 719 B, and the same for all three `.ps1`.

`guard-rm`'s launcher stays fail-CLOSED by construction: a missing `node` makes `exec`
fail non-zero, which is a BLOCK. Never add a fallback.

### Two consequences, both handled

**The differentials became vacuous and were deleted.** With `.sh` a launcher over `.js`,
`tools/diff-*.sh` compared node against node and could only ever report success. A gate
that cannot fail is worse than no gate — the repo records that failure mode repeatedly —
so all three were removed. Constraint 5 is what made this safe: all three components had
native tests first.

**`test-init`'s two FC-4 rows had their oracle retired without being touched.** They prove
the installer refuses a partial wiring by writing a fake `hook-spec.sh` and expecting exit
4. The installer now *imports* the compiled module, so the fake was never read and the rows
were passing against an unreachable branch. This is exactly the T-16 insight — a refactor
can retire a test's oracle silently — and it was caught only because the rows match their
own diagnostic text rather than the bare exit code. Both were re-anchored to mutate
`hook-spec.js`, in both shells.

`sync-self` gained Mapping 10 so the three committed `.js` files cannot drift between the
dogfood tree and `templates/common`; proved non-vacuous by planting one byte and watching
`--check` name the file.

## Scoping notes from the abandoned broad cutover

Measured surface: **27 files reference `guard-rm.sh`**, and `hook-spec` is called by 16
scripts including `verify_all` and `sync-self`. Changing the guard's emitted command
byte-form ripples into the deliberately-frozen test literals (`hook-byteform-test-literal-retirement`),
`baseline.json`, the template copies, and the derivation flows in `upgrade-project` and
`migrate-scripts-layout` — neither of which is ported and both of which still reference `.sh`.

One useful distinction found while scoping it: **deleting `hook-spec`'s shell twins does
not require changing its output.** Only its callers need to invoke the JS. The emitted bytes
stay identical, so no frozen literal moves. That makes a narrow cutover possible ahead of
the broad one, at the cost of touching `F.1`'s pair list, `sync-self`'s mapping, and
`test-init`'s distribution assertions in both shells.

The live hook wiring lives in `.claude/settings.local.json`, which is the operator's to
apply — CLAUDE.md's red line is that `.claude/` is proposed, not hand-edited.

## Open

- ~~CodeGraph indexes both source and build output, duplicating symbols~~ — fixed by
  `codegraph.json`; see `v2-p2-codegraph.md`.
- `vitest` is deliberately not a dependency yet. It arrives at stage 4, where it is
  actually used, rather than sitting unused with an unapproved `esbuild` postinstall.
