# Harness Kit

Harness Kit is a Claude Code plugin that ships a 7-agent AI-development pipeline plus
project templates. This glossary pins the project's own domain terms so the pipeline
names files, symbols, and stage docs consistently. (Single context; if the repo ever
splits into multiple bounded contexts, a root `CONTEXT-MAP.md` would index them — not
needed today.)

## Language

**Frontier**:
The set of pool tasks that are runnable right now because every task they depend on is
already done. The stream and batch modes drain the frontier, not the whole pool.
_Avoid_: ready set, runnable queue, next-up list

**Pool** (living pool):
The mutable list of tasks a stream drains, which the operator keeps adding to mid-run; a
stream re-reads it each iteration so late additions get picked up.
_Avoid_: backlog, queue, task list

**Ambient mode**:
A session-scoped stream variant where a flag file turns each user message into a
scheduler heartbeat via a prompt hook — no slash-loop, no background process.
_Avoid_: daemon mode, watch mode, background mode

**Partition agent**:
A project-local Developer agent scoped to one slice of a codebase (`dev-frontend`,
`dev-backend`, `dev-db`, …), dispatched when a design splits work across partitions.
_Avoid_: sub-developer, worker agent, dev worker

**Stage doc**:
One of the numbered per-task documents the pipeline produces in order
(`01_REQUIREMENT_ANALYSIS.md` … `07_DELIVERY.md`); each stage reads the prior stages' **contract
portions** and writes exactly its own.
_Avoid_: phase report, work product, deliverable doc

**Stage contract**:
The portion of a stage doc that binds downstream stages — acceptance criteria, interface and
type shapes, constraints, change ledger, verdict — written as the original addressed directly
to its consumers, never as a distilled copy of a fuller body.
_Avoid_: spec section, summary, header block, brief

**Stage rationale**:
The portion of a stage doc carrying reasoning and evidence rather than binding statements —
option arguments, risk analysis, reuse audit, open-question candidates, verbatim runs — read by
the gate by default and by other stages only on a named trigger.
_Avoid_: appendix, notes, background, discussion

**Rationale sibling**:
The optional per-stage file `0N_RATIONALE.md` that carries a stage's rationale portion next to its
contract document, written only when non-empty and read only when a named trigger fires.
_Avoid_: appendix file, notes file, rationale doc, supplement

**Returned body**:
The complete file content a read-only stage agent returns in its final message for another role to
persist — the contract portion beginning with its declared opening line, plus the rationale portion
when non-empty. It is the whole document, never a summary or a fragment of one.
_Avoid_: draft, payload, output text, returned document

**Stage-doc transcription**:
The PM's verbatim write of a returned body to that stage doc's declared path, performed for a stage
whose agent holds no write capability. The author owns every byte; the transcriber adds nothing and
repairs nothing, and routes a body that did not arrive whole back to its author.
_Avoid_: PM write-back, proxy write, persist step, ghostwriting

**Boundary rule**:
The single first-match-wins classification table (`.harness/rules/70-doc-size.md`,
`## Stage-doc boundary rule`) that sends every unit of stage-doc content to exactly one of
`contract`, `rationale`, `routing log`, or `no home`. Total: its last row is a reachable default.
_Avoid_: split rule, content policy, classification guide, doc rules

**Declared shape**:
The row or statement form a contract section declares (`id | criterion | class | verification`;
`**K-n** — <statement>.`). A unit fitting a declared shape is contract by construction — except for
a byte-form, which row 2 now hands to rows 3/4/9 rather than blessing; a contract section never
admits free prose.
_Avoid_: template, format, section type, schema field

**No home**:
The boundary rule's destination for content that belongs in no stage doc at all — a body destined
verbatim for a shipped artifact, or a summary of another unit in the same document. Not "delete
later": there is no location to write it in the first place.
_Avoid_: dropped, forbidden, disallowed content, trash

**Byte-form**:
A unit a document offers as the exact characters to be transcribed into a shipped artifact —
marked by "replace X with", "insert", "exactly", "verbatim", or by quoting/fencing that artifact's
text. Distinct from a **constraint**, which states what the artifact must satisfy; a byte-form
reaches a stage contract only through the boundary rule's acceptance-criterion rows.
_Avoid_: snippet, literal, code block, paste, exact text

**Routing log**:
The PM-owned per-task record of stage transitions, rollbacks and rework rounds (`PM_LOG.md`);
the single home for round history, so a stage doc represents current state only.
_Avoid_: PM notes, task log, history section, changelog

**Verdict**:
The single binding status line a stage agent ends on (e.g. `READY`, `APPROVED FOR
DEVELOPMENT`, `BLOCKED`) that tells the PM how to route the task next.
_Avoid_: status, result, outcome, decision

**Insight**:
An evidence-backed, hard-won project truth recorded as one line in the insight index, so
a later task does not re-learn it; each carries its supporting evidence reference.
_Avoid_: lesson, learning, note, takeaway

**Entry-start line**:
A line matching `^[[:space:]]*-[[:space:]]` — the one predicate shared by
all four readers of the insight index: the harvest, the stored-index read, the index header
derivation and the `I.4` cap check.
_Avoid_: bullet line, marker line, insight line, data line

**Insight entry**:
One entry-start line together with its continuation lines, in order — the unit an insight is
authored as and read back as. A continuation line is never an entry of its own.
_Avoid_: bullet, insight bullet, record, item

**Terminal footer**:
In an `## Insight` section of a delivery document, the lines from the first markdown thematic break
that follows the last line of the section's last insight entry through the end of that section — a
document footer left inside the section because no later heading terminates it. Ignorable, never
harvested; a break with a further entry after it is not one.
_Avoid_: closer block, trailer, tail block, end matter

**Rollback**:
Reverting a task's changes back to the pre-task state when a stage cannot proceed —
relied on for additive work because nothing stateful is created.
_Avoid_: undo, revert-all, back-out, unwind

**Dogfood**:
This repo running its own shipped pipeline and assets on itself, so the dogfood copy of a
file carries this project's real content while the template seed of the same file stays
generic.
_Avoid_: self-host, eat-our-own, internal copy

**Template overlay**:
A layer of files (`common/`, then a project-type layer, then a language layer) that
`/harness-init` stacks to compose a generated project; later layers win.
_Avoid_: scaffold, skeleton, preset, boilerplate

**Soft dependency**:
A resource an agent uses if present and degrades gracefully without — referenced in vague
prose, never a precondition, never given a setup pointer.
_Avoid_: optional dependency, weak dependency, nice-to-have

**Hard dependency**:
A resource an agent genuinely requires to function — the only kind that earns an explicit
setup pointer telling the reader to provision it first.
_Avoid_: required dependency, strong dependency, must-have

**Hook wiring spec**:
The single executable source that answers, for a given lifecycle-hook tool and target OS, the exact
command string to wire plus that hook's fail-open / fail-closed semantics — so no artifact hand-copies
the byte-form.
_Avoid_: hook table, hook registry, command map, hook config

**Derivation flow**:
An artifact that WRITES hook wiring into a project's settings — project creation, adoption,
upgrade-repair, layout-migration. A flow is a consumer of the hook wiring spec; a test driver
that only checks such a write is not a flow.
_Avoid_: writer, generator, installer path, wiring path

**Byte-form**:
The exact character sequence of one `(hook tool, target OS)` command as it lands inside a JSON
`"command"` value — inner quotes already escaped. Two artifacts "agree" only when their byte-forms
are equal after their own source-level quoting is resolved.
_Avoid_: command string, hook string, command literal

**Machine-local settings**:
The gitignored per-machine Claude settings file that carries this repo's own lifecycle hooks, kept out
of the committed settings file so the published plugin distributes none.
_Avoid_: local config, private settings, dev settings, settings override

**Settings template**:
The tracked, distributed `.claude/settings.json.tmpl` in the common template overlay, carrying the
`{{…}}` hook-command placeholders `/harness-init` substitutes at generation time — repository
content, never a settings file any tool loads.
_Avoid_: settings tmpl, template settings, settings stub

**Effective hook source**:
The one settings file a consumer resolves this project's lifecycle-hook wiring from, chosen by precedence
(machine-local settings first, committed settings as fallback) so every hook verdict names a single file it
came from.
_Avoid_: active settings, winning config, resolved settings file

**Health report**:
The read-only project snapshot `/harness-status` produces — required assets, baseline, last verify result,
hook state, active tasks, health score — which reports state and never repairs it.
_Avoid_: status output, health check, diagnostics, doctor

**Gate**:
A pass/fail checkpoint between stages — either the human-judgment Gate Review stage or the
mechanical `verify_all` run — that a task must clear before it advances.
_Avoid_: check, guard, barrier, checkpoint

**Command position**:
An offset in a command line at which a shell begins parsing a new simple command; the unit the
destructive-command guard evaluates its out-of-project-root rule at.
_Avoid_: command slot, segment start, statement boundary

**Spec adapter**:
The per-flow module inside a derivation flow that resolves the hook wiring spec twin of its own
shell, invokes it, memoises the answer per `(tool, OS)`, and returns "no answer" — never a
fabricated or default string — when it cannot. Its single failure return is what keeps the
fail-closed guard command fail-closed by construction.
_Avoid_: spec client, spec wrapper, hook resolver, command provider

**Containment window**:
The `PreToolUse` line range a gate check scopes its settings-template assertions to — from the
`"PreToolUse"` key line up to, but excluding, the first following non-blank line at or below that
key's indentation. Evidence outside the window does not count as evidence for `PreToolUse`.
_Avoid_: hook block scope, PreToolUse region, bounded search area

**Operator obligation**:
A release-gating verification step no agent in this repo can perform — it needs a capability the
development host lacks — so it is recorded for a human
operator to execute before a release is safe. It carries a stable id that is never reissued.
_Avoid_: manual check, TODO, pending item, operator task

**Obligation ledger**:
The single location that holds every standing operator obligation, from which the set is read,
counted and executed without opening any other document. Distinct from the numeric-pin baseline
file, which pins counts and metrics only.
_Avoid_: operator checklist, PS list, verification index, standing list

**Discharge**:
Performing an operator obligation and recording, against that obligation, the date and the artifact
state the run was performed against. A discharge recorded against a different artifact state than
the one present today is not a discharge of the current obligation.
_Avoid_: close, complete, tick off, resolve

**Origin-qualified id**:
The id form for an operator obligation that carries only an ordinal local to the document it
originated in (`T13-1` … `T13-8`): the ordinal is preserved as its **enumerating source** assigns it
and the origin's handle is prefixed as a namespace, so the obligation becomes addressable without
any renumbering.
_Avoid_: namespaced id, scoped id, compound id, sub-item number

**Enumerating source**:
The document that first states a set as a numbered list and fixes both its membership and its
ordinals. It governs over any later copy of the set. A copy is a **mirror**, and a mirror is
self-consistent about everything except what it lost — so agreement between a mirror and its own
internal cross-references is not evidence that the mirror is complete. Only comparison against the
enumerating source is.
_Avoid_: original, canonical list, the source, upstream doc

**Pin-writing constraint**:
A unit inside the numeric-pin file that constrains how a key in that same file is next written — a
transcribe-don't-derive instruction, a floor that must not be raised, a key deliberately left absent.
It stays in band with the key it governs and is never an operator obligation.
_Avoid_: baseline rule, pin note, QA note, key policy

> Multi-context note: this repo is a single bounded context, so one root `CONTEXT.md` is
> enough. If it ever grows several bounded contexts, a root `CONTEXT-MAP.md` indexing each
> context's own `CONTEXT.md` is the future option (out of scope today).
