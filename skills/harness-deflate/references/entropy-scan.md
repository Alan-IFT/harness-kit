# Entropy scan reference (supervisor entropy lens + /harness-deflate)

> The SINGLE source of the entropy-scan methodology + artifact schema. Pointed at by BOTH
> `agents/supervisor.md` (the concise `## Entropy lens` stub) and `skills/harness-deflate/SKILL.md`
> (the Task-dispatch prompt). One definition, two readers — never restate it in either place.
> Follow it exactly when the supervisor is dispatched in **entropy mode**.

## Classification grammar (T-07 vocabulary — use these terms exactly)

| Finding class | Signal |
|---|---|
| EP-1 shallow module | interface ≈ implementation (a thin pass-through; the interface is nearly as complex as what it hides) |
| EP-2 cross-seam leakage | a module's internals leak across its seam; callers depend on implementation detail |
| EP-3 coupling cluster | a knot of modules that must change together; no clean seam between them |
| EP-4 deepening candidate | a place where pulling complexity behind one deeper interface would raise leverage / locality |

## Deletion test (applied to every EP finding)

For each candidate: would deleting/inlining it CONCENTRATE complexity (signal — keep & deepen)
or merely MOVE it (no finding)? Record the verdict in one line per finding.

## Strength badge (fixed set — exactly one per finding)

`Strong` | `Worth exploring` | `Speculative`. (Distinct from AP severity INFO/WARN/ALERT
and from verify_all PASS/WARN/FAIL.)

## Entropy findings artifact (the one write)

Single-task-style path: `docs/features/_supervision/entropy-<ISO-date>.md` (create the folder
if absent — the same folder the cross-task report uses). Schema:

    # Entropy Watch — <ISO-timestamp>
    > by /harness-deflate (or /harness-stream drain) · supervisor.md entropy lens vX.Y.Z

    ## Findings
    | ID | Class | Where (file/module) | Strength | Deletion test |
    |---|---|---|---|---|
    | EP-001 | shallow module | path/to/file | Worth exploring | inlining moves complexity → minor |

    ## Detail
    ### EP-001 — <one paragraph: the friction, in T-07 terms>
    ...

    ## Methodology notes
    <what was/wasn't read; doc-cap note if hit>

    Entropy-verdict: FINDINGS-PRESENT | CLEAN

## Decline filter

> The SINGLE source of the decline-suppression rule. The `supervisor.md` `## Entropy lens` stub and
> the `SKILL.md` step-4 decline path both point HERE — neither restates the key rule.

Some findings have been **declined** by the user ("not worth deepening"); those must not re-litigate
every sweep. The declined-finding memory reuses the existing T-09 file `.harness/rejected-decisions.md`
(one record per concept handle — a `## <handle>` block with `- **Decision:**`, `- **Why:**`,
`- **Origin:**` bullets); a declined deepening IS a rejected decision.

**BEFORE writing the artifact** (after deriving the full findings list — ID + class + Where + strength
+ deletion test), READ `.harness/rejected-decisions.md` and EXCLUDE every finding whose normalized
`Where (file/module)` handle EXACTLY matches a declined/deferred record's normalized concept handle:

1. **Read** `.harness/rejected-decisions.md` (read-only). This is the single already-class-whitelisted
   `.harness/` file the entropy-mode read exception covers.
2. For each derived finding compute its **stable key** = the finding's `Where (file/module)` cell,
   normalized. Compare it against each record's **concept handle** = the `## <handle>` heading text,
   normalized the SAME way. The per-run `EP-NNN` id is **NOT** the key (it is sequential per sweep and
   unstable across sweeps); the concept handle is.
3. **Normalization** (deterministic; applied to BOTH sides before comparison):
   1. **Trim** surrounding whitespace.
   2. **Normalize separators** to forward slash (`\` → `/`).
   3. **Strip** a leading `./` and any trailing `/`.
   4. **No case folding, no directory coarsening** — compare the full path/handle string
      case-sensitively (it must match exactly what the user saw and declined in the `Where` cell).
4. **Match rule:** drop a finding **iff** `normalize(finding.Where) == normalize(record.concept_handle)`
   for at least one record whose `- **Decision:**` line reads `declined` or `deferred`. EXACT string
   equality after normalization — **NOT** substring, **NOT** prefix (substring/prefix would silently
   over-suppress sibling modules the user never declined).
5. **A dropped finding** does NOT appear in the `## Findings` table, does NOT appear in `## Detail`, and
   does NOT contribute to the `Entropy-verdict:` FINDINGS-PRESENT/CLEAN determination — if EVERY derived
   finding is dropped, the verdict is `CLEAN`. Two findings in one sweep that normalize to the same
   declined key are BOTH dropped (declining a module declines its co-located findings). A declined
   record whose handle matches no current finding suppresses nothing (a stale record sits harmlessly).
6. **Methodology note (internal honesty, not a user-facing hidden count):** record the suppressed count
   in `## Methodology notes`, e.g. `decline-filter: N finding(s) suppressed`. This states what the scan
   did and did not emit; it is NOT a report-facing "N findings hidden because declined" count.
7. **Fail-open:** if `.harness/rejected-decisions.md` is **absent or unreadable**, the filter is a
   no-op and ALL derived findings surface (never suppress on a read failure — consistent with the
   cadence engine's fail-open posture). Absent / header-only / empty file = "no declines".

The filter is a deterministic set subtraction (declined-key set − derived-finding set), applied once,
before the write.

## Determinism + caps

The structured finding list (ID + class + Where + strength) is identical across runs over an
unchanged tree (NFR-6) AND an unchanged `.harness/rejected-decisions.md`; the decline filter is a
deterministic set subtraction applied before the write, so determinism holds over both inputs.
Narrative prose may vary. The artifact obeys the ≤200-line
SUPERVISION_REPORT-class cap; on overflow emit `(entropy report truncated: 200-line cap hit)`
in Methodology notes — never silently drop findings.

## Entropy verdict line (machine-readable)

Last non-blank line, exact regex `^Entropy-verdict: (FINDINGS-PRESENT|CLEAN)$`. This lets an
automated reader (the stream surface) detect "findings present" without parsing the body.
(It is DISTINCT from the AP-* `Verdict: HEALTHY|WATCH|INTERVENE` line; an entropy-mode run
emits the Entropy-verdict line, not the AP verdict line.)
