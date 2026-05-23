# 02 — Solution Design · i6-semantic-guard (T-004 · v0.18.0)

Mode: **full**. Upstream verdict: `01_REQUIREMENT_ANALYSIS.md` = **READY**. Repo is
single-developer (`.harness/agents/dev-*.md` does not exist — Glob confirmed) — no
Partition Assignment section required.

> Gate-review rework: see §14 — Rev 2 closed F-1 (line-scoped `exclude`), F-2
> (`docs/features/` exempt-dir extension), F-3 (residual set enumerated); Rev 3
> closes F-4 — entry #2 keeps `gap=20` **plus** the line-scoped `exclude` (the rev-2
> `v0.2` token was on the wrong line and is removed).

---

## 1. Architecture summary

`verify_all` check **I.6** is upgraded in place, in `scripts/verify_all.sh`
(~501-552) and `scripts/verify_all.ps1` (~469-524), from a literal-substring scan to a
**gap-tolerant ordered-anchor scan**: each banned entry becomes an ordered list of
plain-text anchor tokens, and a file hits when all anchors appear in order on one line
within a bounded gap (`{0,40}` chars, per-entry overridable). To keep the repo green
(AC-4), each entry also carries optional **plain-text exclusion tokens** — if any
appears anywhere on the **matched line** (line-scoped, §3.2/F-1), the match is
discarded, so the matcher does not FAIL on accurate negated prose. The I.6 exempt-dir
list is widened from `docs/features/_archived/` to the whole `docs/features/` subtree
(§3.6/F-2) so per-task stage docs — which must quote retired claims — do not fail their
own gate. No new check, no new dependency, count stays 30; a new repo-bespoke pair
`scripts/test-verify-i6.{ps1,sh}` provides cross-shell regression.

---

## 2. Affected modules / files

| File | Change |
|---|---|
| `scripts/verify_all.sh` | Rewrite the I.6 block (~501-552): new data structure + anchor-scan loop + line-scoped exclude + span report. Widen `i6_exempt_dirs`. Update the I.6 comment header (AC-10). |
| `scripts/verify_all.ps1` | Rewrite the I.6 `Step` body (~469-524): symmetric `[regex]` scan + line-scoped exclude. Widen `$exemptDirs`. Update the I.6 comment. |
| `scripts/test-verify-i6.sh` | **NEW** — bash test driver for the matcher (fixtures + parity). |
| `scripts/test-verify-i6.ps1` | **NEW** — PowerShell twin, mirrored assertion set. |
| `CHANGELOG.md` | New v0.18.0 entry (exempt from I.6 scan). |
| `AI-GUIDE.md` | Line 68: I.6 description → gap-tolerant; `30 checks at v0.17.4` → `at v0.18.0`. |
| `docs/dev-map.md` | Lines 74, 129: version bump; line 78 adds `test-verify-i6`; **line 113 R-2 fix** (`Scaffolding-only` → `scaffolding only`). |
| `.harness/insight-index.md` | Follow-up note after line 18 (I.6 gap-tolerant at v0.18.0) and a new line for the `docs/features/` exempt-dir widening. |
| `.harness/rules/40-locations.md` | Line 43: append "gap-tolerant since v0.18". |
| `README.md` / `README.zh-CN.md` | Add a v0.18.0 roadmap/changelog row. |

**Not changed:** `MIGRATION.md` stays scanned (no I.6 hit — verified); exempt-**file**
membership unchanged (exempt-**dir** IS changed, §3.6); `templates/.../verify_all.*.tmpl`
have no I.6 — out of scope.

---

## 3. Module decomposition

### 3.1 Data structure — one banned entry

Authored as **plain text** (NFR-2: no maintainer-written regex). Fields:

| Field | Meaning | Required |
|---|---|---|
| `anchors` | Ordered list of literal anchor tokens. All must appear, in order, within the gap window. | yes |
| `reason` | Human-readable retirement reason (unchanged from today). | yes |
| `exclude` | List of literal tokens; if **any** appears anywhere on the **matched line**, that line's match is rejected (false-positive guard for accurate negated/corrective prose). | optional, default empty |
| `gap` | Per-entry gap-budget override (integer). Falls back to the global default `40`. | optional |

The script — not the maintainer — escapes every anchor for regex; authoring stays a
one-line edit (NFR-2 / item 9). `exclude` tokens are matched as literal
case-insensitive substrings (no regex), so they need no escaping.

- **bash** — a `|`-delimited record `anchors~tokens|reason|exclude~tokens|gap`, anchors
  / exclusions inner-delimited by `~`; `~` never appears in any anchor (verified §5).
- **PowerShell** — an array of hashtables, e.g.
  `@{ anchors = @('regenerates','CLAUDE.md'); reason = '...' }`. Per L19, any anchor
  with a backtick (the `` `CLAUDE.md` `` code-span anchors) MUST be single-quoted;
  double-quoting a backtick-bearing literal is forbidden.

### 3.2 Matching algorithm — shared semantics (NFR-1)

For one file and one entry, both shells compute the identical predicate per line:
`hit(file,entry)` iff some line `L` exists where regex `R(entry)` matches a span within
`L` **and** no `entry.exclude` token appears (literal, case-insensitive) anywhere in the
**full line `L`** (line-scoped — F-1).

The `exclude` test is scoped to the **whole matched line**, not the matched span
(F-1 fix). Rationale: I.6's threat model is accidental copy-paste drift (L18), not a
determined adversary; a negation word frequently sits *before* the first anchor
(`00-core.md.tmpl:7` — see §6) where a span-scoped exclude misses it. The residual
bypass (deliberately writing `not` elsewhere on the line) is far more intentional than
the drift I.6 targets — PM-approved as an acceptable trade.

`R(entry)` is built from the escaped anchors:
`R = esc(a0)(.{0,GAP})esc(a1)...esc(a[n-1])`, where `esc(t)` escapes every regex
metacharacter so `t` matches literally (`.` in `CLAUDE.md`, `/` in `.harness/rules`;
`→` U+2192 is not a metacharacter — passes through) and `GAP` = `entry.gap` else the
global default `40`.

- `.` in `.{0,GAP}` matches any char **except newline** — enforces D-3 free in both
  engines. A single-anchor entry produces `R = esc(a0)` (plain literal, today's
  behavior). One hit per file per entry — the per-line scan `break`s on first
  non-excluded match. **Backtracking safety (NFR-3):** every gap is bounded `.{0,40}`,
  no nested unbounded quantifier — linear worst case, safe for ERE and .NET.

### 3.3 bash implementation (`scripts/verify_all.sh`)

Line-oriented `grep -E` per entry per file (already used throughout `verify_all.sh`;
satisfies D-3, `-n` gives line numbers, binary files tolerated). The outer
`git ls-files` loop + exempt-array filtering is the existing I.6 skeleton reused
verbatim (§11); only the inner match changes. Key pseudocode:

```bash
i6_gap_default=40
# Each record: anchors~tokens | reason | exclude~tokens | gap   (full 13-row list §5)
# Note entry #2 carries BOTH an exclude list AND gap=20 (F-4):
i6_banned=( "regenerates~CLAUDE.md|harness-sync does not regenerate CLAUDE.md since v0.10||"
            "Composed~into~\`CLAUDE.md\`|rules are not composed into CLAUDE.md since v0.10|not~no longer~referenced|20" ... )

# Build an ERE from a ~-delimited anchor list, escaping each token literally.
i6_build_regex() {                       # $1 = anchors  $2 = gap
    local anchors="$1" gap="$2" out="" first=1 tok esc IFS='~'
    for tok in $anchors; do
        esc=$(printf '%s' "$tok" | sed 's/[.[\](){}*+?|^$\\]/\\&/g')
        if (( first )); then out="$esc"; first=0; else out="${out}.{0,${gap}}${esc}"; fi
    done
    printf '%s' "$out"
}

# inside the existing per-file loop (loop var: scan_file — L24, no report=() collision):
for entry in "${i6_banned[@]}"; do
    IFS='|' read -r e_anchors e_reason e_exclude e_gap <<< "$entry"
    rx=$(i6_build_regex "$e_anchors" "${e_gap:-$i6_gap_default}")
    match=$(grep -E -n -i -m1 -- "$rx" "$scan_file" 2>/dev/null) || continue   # first matching line
    line_no="${match%%:*}"; full_line="${match#*:}"          # the WHOLE matched line (F-1)
    excluded=0                                               # line-scoped exclude
    if [[ -n "$e_exclude" ]]; then
        local IFS='~'
        for xtok in $e_exclude; do
            printf '%s' "$full_line" | grep -F -i -q -- "$xtok" && { excluded=1; break; }
        done
    fi
    (( excluded )) && continue
    span=$(printf '%s' "$full_line" | grep -E -i -o -m1 -- "$rx")     # D-5 report
    i6_hits="${i6_hits}${scan_file}:${line_no} : [${e_anchors}] — ${e_reason} | matched: \"${span:0:120}\""$'\n'
done
```

Notes: the **full `grep -n` line** (not the `-o` span) drives the line-scoped exclude
(F-1); `span` is re-extracted only for the D-5 report. `IFS` reassignments are `local`;
loop var `scan_file` avoids the `report=()` collision (L24).

The bash line-scoped exclude test is implemented with `shopt -s nocasematch` +
`[[ "$full_line" == *"$xtok"* ]]` (a case-insensitive literal substring test in pure
bash), **not** the `grep -F -i -q` shown in the pseudocode above — Git-for-Windows
GNU grep 3.0 SIGABRTs (exit 134) when `-F` and `-i` are combined. The two are
behaviorally identical (literal, case-insensitive, line-scoped) and the bash-native
form improves cross-shell parity: both shells now do the exclude test with in-language
string ops (PowerShell uses `String.IndexOf(...,OrdinalIgnoreCase)`, §3.4). The anchor
scan still uses `grep -E -n -i` (unaffected — only `-F -i` crashes). Recorded so design
and code agree; no rework.

### 3.4 PowerShell implementation (`scripts/verify_all.ps1`)

A behavioral 1:1 twin of §3.3, inside the existing `$tracked`/`$exempt`/`$exemptDirs`
skeleton. Per-entry steps, after `$content = Get-Content -Raw` is read:

1. `$banned` is the array of hashtables (§3.1); `Build-I6Regex` =
   `($anchors | ForEach-Object { [regex]::Escape($_) }) -join "(.{0,$gap})"`.
2. `$rx = [regex]::new((Build-I6Regex $b.anchors $gap), [RegexOptions]::IgnoreCase)` —
   `IgnoreCase` is the explicit D-2 mechanism (**L23**: `-match`/`-cmatch` are NOT used);
   `Singleline` stays `$false` so `.` excludes `\n` (D-3).
3. Split `$content` on `` `r?`n ``; for each line, `$m = $rx.Match($line)`.
4. **Line-scoped exclude (F-1):** on `$m.Success`, reject the line if any `$b.exclude`
   token is found via `$line.IndexOf($x,[StringComparison]::OrdinalIgnoreCase) -ge 0` —
   tested against the **whole `$line`**, not `$m.Value`. On a non-excluded match: record
   `${file}:$n` + anchors + reason + `$m.Value` truncated to 120 chars (D-5), then
   `break` (one hit per file per entry).

Notes: **L19** — backtick anchors single-quoted in the hashtable; `[regex]::Escape`
leaves a literal backtick intact. `→` (U+2192) passes through `Escape` literally;
`verify_all.ps1:486` already contains `→`, so source encoding is correct — no regression.

### 3.5 Cross-shell parity argument (NFR-1 / AC-5)

§3.3 and §3.4 are behaviorally identical: same anchor list / gap / overrides; same
regex shape (ERE ≡ .NET on bounded repetition, literal escaping, `.` excluding
newline); same line orientation; same case rule (`grep -i` ≡ `IgnoreCase`); same
line-scoped exclude (F-1); same one-hit-per-file-per-entry. Test driver asserts it
empirically (7.3 #2).

### 3.6 Exempt-dir extension (F-2)

I.6 scans `git ls-files`. Once this task's stage docs are committed under
`docs/features/i6-semantic-guard/`, they get scanned — and they **must** quote literal
banned phrases to design the guard, so the shipping commit would fail its own I.6 gate
under the old exempt-dir list (`docs/features/_archived/` only).

**Resolution (PM-authorized scope extension):** the I.6 exempt-dir list is widened from
`docs/features/_archived/` to the whole **`docs/features/`** subtree in **both**
scripts — the `_archived/` entry is *replaced*:

```
i6_exempt_dirs=( "docs/features/" "参考/" )      # verify_all.sh
$exemptDirs    = @("docs/features/", "参考/")     # verify_all.ps1
```

The existing prefix test (`== "$ed"*` / `StartsWith`) makes `docs/features/` subsume
`_archived/`. Rationale: per-task stage docs legitimately quote retired claims; the
`_archived/` exemption already concedes this, and widening to the parent removes a
fragile commit-ordering dependency. A deliberate scope change vs. requirement §3 "no
change to exempt-dir membership" (recorded §12/§14); QA-tested per §7.2.

---

## 4. Decision resolutions (D-1 … D-6)

| D | Decision taken | Reason |
|---|---|---|
| **D-1** | (a) — fixed default `.{0,40}` chars, per-entry override allowed. | Identical in ERE and .NET (NFR-1); 40 chars covers real narration. Entry #2 overrides to `gap=20` — its `concepts.md:104` sub-gap is 23 chars, so `gap=20` clears that line while line-scoped `exclude` clears the negation files (§6). |
| **D-2** | (a) — all alphabetic anchors AND `CLAUDE.md` case-insensitive. | Stronger guard; via `grep -i` / `RegexOptions::IgnoreCase` — explicit, never a PS operator default (L23). |
| **D-3** | (a) — single-line only. | A retired claim is one sentence; `.` excludes `\n` in both engines. |
| **D-4** | (a) — human-reviewed whitespace split, minimal anchors, PLUS a per-entry line-scoped `exclude` field (§3.2/F-1). | A mechanical split breaks AC-4 (`composed`…`CLAUDE.md` hits accurate negated prose); line-scoped `exclude` keeps the repo green without per-file exceptions. List §5. |
| **D-5** | (a) — report the matched span truncated to 120 chars, with line number. | Lets a maintainer judge a false positive at a glance (item 8). |
| **D-6** | New dedicated pair `scripts/test-verify-i6.{ps1,sh}`. | Matcher logic deserves its own driver. `sync-self` mirrors only `harness-sync`/`install-hooks`/`archive-task`/`guard-rm` — a repo-bespoke pair is not a distributed template, so no `sync-self` change. |

### 4.1 Why D-4 needs the `exclude` field — the AC-4 blocker analysis

AC-4 asserts the current repo is clean under the upgraded matcher. A naive anchor split
breaks this — a gap-tolerant `composed`…`CLAUDE.md` hits accurate prose. Grep of the
live (non-exempt) tree found six `composed…CLAUDE.md` candidate lines (all entry #2;
exhaustive per-file char-count proof in §6). Three further negation lines correctly do
**not** hit by ordered-anchor structure alone: `AI-GUIDE.md.tmpl:95` (`No automatic
regeneration … re-composition` — anchor order differs), `10-self-consistency.md:17`
and `tests/fixtures/README.md:23` (both put `CLAUDE.md` before `regenerated` —
verb-first ordering fails the match).

The `regenerated`/`regenerates` family (#5–#8) is protected purely by **ordered
anchors** (verb before filename) — accurate prose puts `CLAUDE.md` first. **Only the
`composed`/`composition` family (#2/#4)** needs extra guarding, because there the
false claim and the accurate negation share anchor order. Entry #2 therefore uses
**two complementary, per-*entry* mechanisms** — a line-scoped `exclude`
(`not`/`no longer`/`referenced`) clearing the four narrow-gap negation files, and a
per-entry `gap=20` clearing the historical-narration `concepts.md:104` — neither alone
clears all five (full file-by-file char-count proof: §6). Neither is a per-*file*
exception (in-scope item 9 preserved). The rev-2 `v0.2` exclude token is **removed**:
`v0.2` sits on `concepts.md:103`, off the match line 104, so it never fired.

---

## 5. Migrated banned-pattern list (the load-bearing deliverable, D-4)

Every current literal re-expressed as anchors + reason + (exclude) + (gap), order
preserved (the `.ps1` hashtable is the 1:1 twin of these bash records):

| # | Current literal | `anchors` (`~`-joined) | `exclude` | `gap` | `reason` |
|---|---|---|---|---|---|
| 1 | `scaffolding-only` | `scaffolding-only` | — | — | harness-adopt has been fully automated since v0.3 |
| 2 | `` Composed into `CLAUDE.md` `` | `` Composed~into~`CLAUDE.md` `` | `not`~`no longer`~`referenced` | `20` | rules are not composed into CLAUDE.md since v0.10 |
| 3 | `composed by filename order` | `composed~by~filename~order` | — | — | rules not composed since v0.10 |
| 4 | `composition order in CLAUDE.md` | `composition~order~in~CLAUDE.md` | `not`~`no longer` | — | no composition in CLAUDE.md since v0.10 |
| 5 | `regenerates CLAUDE.md` | `regenerates~CLAUDE.md` | — | — | harness-sync does not regenerate CLAUDE.md since v0.10 |
| 6 | `` regenerates `CLAUDE.md` `` | `` regenerates~`CLAUDE.md` `` | — | — | harness-sync does not regenerate CLAUDE.md since v0.10 |
| 7 | `regenerated CLAUDE.md` | `regenerated~CLAUDE.md` | — | — | CLAUDE.md is a static stub since v0.10 |
| 8 | `` regenerated `CLAUDE.md` `` | `` regenerated~`CLAUDE.md` `` | — | — | CLAUDE.md is a static stub since v0.10 |
| 9 | `Generated from .harness/rules` | `Generated~from~.harness/rules` | — | — | CLAUDE.md not generated from rules since v0.10 |
| 10 | `.harness/ → CLAUDE.md` | `.harness/~→~CLAUDE.md` | `.claude/` | — | harness-sync target is .claude/, not CLAUDE.md, since v0.10 |
| 11 | `harness-sync 生成 CLAUDE.md` | `harness-sync~生成~CLAUDE.md` | `不` | — | v0.10 起 harness-sync 不再生成 CLAUDE.md |
| 12 | `harness-sync 合成 CLAUDE.md` | `harness-sync~合成~CLAUDE.md` | `不` | — | v0.10 起规则不再合成进 CLAUDE.md |
| 13 | `重新生成的 CLAUDE.md` | `重新生成的~CLAUDE.md` | — | — | v0.10 起 CLAUDE.md 是 stub，不再被重新生成 |

**Per-entry notes:** #2 — needs **both** complementary mechanisms (full §6 proof):
per-entry `gap=20` clears `concepts.md:104` (`composed`→`into` sub-gap 23 > 20,
historical narration with no negation word); line-scoped `exclude`
(`not`/`no longer`/`referenced`) clears the four ~1-char-gap negation files
(`00-core.md.tmpl:7`, `getting-started.md:132`, `CONTRIBUTING.md:111`,
`harness-sync.ps1:8`). **No** `v0.2` exclude token — the rev-2 `v0.2` token rested on
a false premise (`v0.2` is on `concepts.md:103`, not the matched line 104) and is
removed. #3 — four distinct anchors; appears only as the false claim, no `exclude`. #4 —
`exclude=not`/`no longer` for symmetry with #2; live occurrences are exempt-file only.
#5–#8 — verb-first ordered anchors exclude the accurate `CLAUDE.md … not regenerated`
prose, no `exclude` needed. #9 — `/` escaped literally; `AI-GUIDE.md.tmpl:95` uses the
noun "regeneration", no hit; the developer's exhaustive `verify_all` scan (§6) found
**zero** live #9 hits, so #9 carries **no `exclude`**. #10 — three anchors (`.harness/`,
U+2192 arrow, `CLAUDE.md`); the AC-7 metachar/Unicode case. It carries
`exclude=.claude/`: the gap-tolerant scan otherwise hits two **accurate-prose** lines
(`README.md:196`, `README.zh-CN.md:198`) that describe harness-sync's real flow
`.harness/agents + .harness/skills → .claude/` and parenthetically note CLAUDE.md is a
static stub — the `→`→`CLAUDE.md` sub-gap there is ~11 chars (` .claude/ (`), inside
`gap=40`. The accurate lines' distinguishing marker is `.claude/` — harness-sync's
*real* sync target; a genuine retired false claim (`.harness/ → CLAUDE.md`, asserting
the flow target IS CLAUDE.md) would not carry `.claude/`. So `exclude=.claude/` clears
the two README lines while still catching the false claim — mechanically identical in
shape to #2/#4 carrying `not`/`no longer` and #11/#12 carrying `不`. The exclude token
`.claude/` contains no `~` or `|`, so the bash record format is safe; it is matched as
a literal case-insensitive substring (line-scoped), never as a regex anchor, so the `.`
needs no escaping. #11–#13 — Chinese, CJK is caseless so D-2 is a no-op; `exclude=不`
on #11/#12 is the Chinese twin of #2's negation guard.

**Delimiter safety:** no anchor, reason, or exclude token in the 13 rows contains the
inner delimiter `~` or the field delimiter `|`. Confirmed by inspection.

---

## 6. AC-4 verification reasoning (current repo stays green)

Per-family argument that the migrated list produces **zero non-exempt hits** on the
current tree, other than the single PM-approved R-2 line:

- **`composed`/`composition` family (#2, #3, #4):** entry #2 carries **both** a
  per-entry `gap=20` override **and** a line-scoped `exclude` (`not`/`no longer`/
  `referenced`) — complementary, each clearing files the other cannot. Every live
  (non-exempt) `composed…CLAUDE.md` candidate, with its binding sub-gap *counted* (not
  estimated) against the live text — sub-gaps are `composed`→`into` (c→i) and
  `into`→`` `CLAUDE.md` `` (i→`` ` ``):

  | File:line | Live line content | sub-gaps (c→i, i→`` ` ``) | Cleared by |
  |---|---|---|---|
  | `skills/.../00-core.md.tmpl:7` | `…since v0.10 rules are referenced, not composed into `CLAUDE.md`)` | 1, 1 | `exclude` — `not`, `referenced` on line |
  | `docs/concepts.md:104` | `composed `.harness/rules/*.md` into a single `CLAUDE.md` so the AI…` | **23**, 10 | **`gap=20`** — c→i 23 > 20 breaks the chain |
  | `docs/getting-started.md:132` | `Since v0.10, rules are **not** composed into CLAUDE.md.` | 1, 1 | `exclude` — `not` on line |
  | `CONTRIBUTING.md:111` | `…fragments are not composed into CLAUDE.md; `AI-GUIDE.md`…` | 1, 1 | `exclude` — `not` on line |
  | `scripts/harness-sync.ps1:8` | `# Rules are NO LONGER composed into CLAUDE.md or…` | 1, 1 | `exclude` — `no longer` on line |
  | `skills/.../scripts/harness-sync.ps1:8` | (byte-identical twin of the above) | 1, 1 | `exclude` — `no longer` on line |

  The `concepts.md:104` `composed`→`into` sub-gap of 23 chars = ` ` +
  `` `.harness/rules/*.md` `` (21 chars incl. both backticks) + ` `. The four negation
  files have ~1-char sub-gaps — inside `gap=20`, so the gap override alone cannot clear
  them; only the `exclude` token fires. `concepts.md:104` carries no negation token, so
  only `gap=20` clears it. **Neither mechanism alone clears all five — both required.**
  `00-core.md.tmpl:7` additionally has its token *before* the anchors, which the rev-1
  span-scoped exclude missed and line-scoping (F-1) catches. **All cleared.** The rev-2
  `v0.2` token is removed: `v0.2` lives on `concepts.md:103`, a different line from the
  match on 104, so it never tested true. #3/#4 never appear as accurate prose in
  non-exempt files; zero hits.
- **`regenerates`/`regenerated` family (#5–#8):** verb-first ordered anchors — accurate
  prose puts `CLAUDE.md` first (wrong order, no match); CHANGELOG occurrences are
  exempt; `AI-GUIDE.md` uses the noun `regeneration` (no anchor match). Zero non-exempt
  hits.
- **#9 (`Generated from .harness/rules`):** the developer's exhaustive gap-tolerant
  `verify_all` scan of all 13 entries over the entire `git ls-files` tree found **zero**
  live #9 hits — #9 is **not** in the 3-line hit set below — so #9 needs **no
  `exclude`**. (`AI-GUIDE.md.tmpl:95` uses the noun "regeneration", which contains no #9
  anchor.)
- **#10 (`.harness/ → CLAUDE.md`):** the gap-tolerant scan **does** hit two accurate-
  prose, tracked, non-exempt files — `README.md:196` and `README.zh-CN.md:198` — each a
  repo-layout line stating `.harness/agents + .harness/skills → .claude/ (CLAUDE.md is
  a static stub …)`; the `→`→`CLAUDE.md` sub-gap is ~11 chars, inside `gap=40`. The
  earlier revision wrongly claimed "#9/#10 … zero non-exempt hits" — that sentence was
  not backed by an automated scan. **Fix:** entry #10 carries `exclude=.claude/` (§5);
  `.claude/` appears on both README lines (harness-sync's real target) so the
  line-scoped exclude rejects both, while a genuine false claim asserting the target IS
  `CLAUDE.md` carries no `.claude/` and still hits. After the exclude, #10 has zero
  non-exempt hits.

**Exhaustive hit set.** The developer ran the upgraded matcher (`verify_all.{sh,ps1}`,
byte-identical I.6 output cross-shell) gap-tolerantly over **all 13 entries** against
the **entire `git ls-files` tree** — a complete automated check, not per-family hand
reasoning. The full I.6 non-exempt hit set under the §5 list is exactly **three lines**:
`docs/dev-map.md:113` (the PM-approved R-2 line, fixed in-commit), plus `README.md:196`
and `README.zh-CN.md:198` (both cleared by entry #10's `.claude/` exclude). There is no
4th false positive — the scan proves it. With #10's `exclude` applied, the complete
non-exempt hit set narrows to the **single** line `dev-map.md:113`, fixed by R-2.
- **`scaffolding-only` (#1) — residual set, F-3:** D-2 case-insensitivity newly catches
  the capital-S variant. The GR's repo-wide `[Ss]caffolding-only` grep confirms the
  **only** non-exempt capital-variant occurrence is **`docs/dev-map.md:113`**
  (`architecture.html`/`CHANGELOG.md` occurrences are exempt; the stage docs are now
  exempt under `docs/features/`, §3.6) — the complete, closed set of expected live hits
  is exactly that one file, fixed in-commit per R-2 (`Scaffolding-only in 0.1` →
  `scaffolding only in 0.1`). F-3 closed.

**Net:** with F-1 (line-scoped `exclude`), the F-4 fix (entry #2 also keeps a per-entry
`gap=20`), F-2 (`docs/features/` exempt-dir extension), and the Rev-4 fix (entry #10's
`exclude=.claude/`), the only live hit is `dev-map.md:113`, fixed in-commit per R-2 —
**after this task's commit, `verify_all` reports I.6 = PASS, 30/30.**

**`gap=20` does not regress real-bypass detection.** AC-1/AC-2 hit **entry #5**
(`regenerates`~`CLAUDE.md`, global `gap=40`) — entry #2 is not involved, so narrowing
#2's gap cannot weaken them (GR re-review predicted-question #3 confirms). A genuine
bypass phrased against entry #2 itself — e.g. `composed into the static stub
`CLAUDE.md`` — still hits #2 under `gap=20`: `into`→`` `CLAUDE.md` `` there is
` the static stub ` = 17 chars < 20 and `composed`→`into` is 1 char, both inside the
window. `gap=20` only suppresses 21–40-char inter-anchor distances, which in the live
tree occur exclusively in historical narration with a parenthetical between anchors
(`concepts.md:104`), not in drift-style false claims.

---

## 7. Test-driver design — `scripts/test-verify-i6.{ps1,sh}` (AC-11, D-6)

### 7.1 Structure

Follows the `test-supervisor.{ps1,sh}` pattern (`Assert` helper, pass/fail counter,
`failures` array, non-zero exit). The driver does **not** source `verify_all` (that
would run all 30 checks); it re-declares the matcher predicate (`i6_build_regex` +
scan/line-scoped-exclude logic) as a self-contained function, kept in lockstep by a
structural assertion (7.3 #3) — as `test-supervisor` re-declares its detector ladders.

### 7.2 Fixture corpus

Fixtures in an isolated temp dir per L12 (cleaned unless `-KeepTemp`); one file per case:

| Fixture | Content (representative) | Expected | AC |
|---|---|---|---|
| `fx-bypass.md` | `harness-sync regenerates the static stub CLAUDE.md` | HIT #5 | AC-1 |
| `fx-adjacent.md` | `regenerates CLAUDE.md` | HIT #5 | AC-2 |
| `fx-accurate.md` | `.claude/agents/ is regenerated by harness-sync from .harness/agents/` | NO hit | AC-3 |
| `fx-case.md` | `Harness-sync Regenerates the CLAUDE.md stub` | HIT #5 | AC-6 |
| `fx-meta-backtick.md` | `` harness-sync regenerates `CLAUDE.md` `` | HIT #6, no error | AC-7 |
| `fx-meta-arrow.md` | `.harness/ → CLAUDE.md` | HIT #10, no error | AC-7 |
| `fx-arrow-accurate.md` | `.harness/agents + .harness/skills → .claude/ (CLAUDE.md is a static stub since v0.10)` (the README repo-layout line) | NO hit — line-scoped `.claude/` exclude fires | §6 / Rev-4 |
| `fx-gap-exact.md` | `regenerates` + 40 filler chars + `CLAUDE.md` | HIT #5 | AC-9 |
| `fx-gap-over.md` | `regenerates` + 41 filler chars + `CLAUDE.md` | NO hit | AC-9 |
| `fx-negation-pre.md` | `rules are referenced, not composed into ` + "`CLAUDE.md`" (negation BEFORE anchors) | NO hit (line-scoped `exclude`) | AC-3 / F-1 |
| `fx-historical.md` | Near-verbatim two-line copy of `concepts.md:103-104` — line 1 `…The original v0.2 design`, line 2 `` composed `.harness/rules/*.md` into a single `CLAUDE.md` so… `` | NO hit — #2's anchors all land on line 2; `composed`→`into` sub-gap 23 > `gap=20` | §6 / F-4 |
| `fx-empty.md` | (zero bytes) | NO hit | boundary |
| `fx-multiline.md` | `regenerates` on line 1, `CLAUDE.md` on line 2 | NO hit (D-3) | boundary |
| one fixture per remaining entry (#1,#3,#4,#9,#11,#12,#13) | the literal phrase | HIT that entry | AC-5 coverage |

`fx-negation-pre.md` is the **direct F-1 regression test** (a span-scoped exclude
would fail it). `fx-historical.md` is the **direct F-4 regression test**: it
reproduces `concepts.md`'s real two-line layout (`v0.2` on line 1, all anchors on
line 2; binding sub-gap `composed`→`into` = 23 chars) so any future removal of #2's
`gap=20` — or a regression to a single-line layout — re-trips the case.
`fx-arrow-accurate.md` is the **direct Rev-4 regression test**: it reproduces the
README repo-layout line that entry #10 gap-tolerantly hits, expecting NO hit because
the line-scoped `.claude/` exclude fires — mirroring how `fx-historical.md` protects
F-4. Any future removal of #10's `exclude=.claude/` re-trips it. **F-2
exempt-dir test:** the driver runs the real I.6 exempt-dir predicate against a
synthetic `docs/features/some-task/03_GATE_REVIEW.md` and asserts it is skipped in
both shells.

### 7.3 Assertions

1. **Behavioral** — for each fixture, run the bash and PS matcher; assert hit/no-hit
   matches Expected.
2. **Cross-shell parity (AC-5)** — collect each shell's full `(file,entry)` hit set
   over the corpus; assert the two are identical.
3. **Structural lockstep** — `test-verify-i6.*`'s banned-list has the same 13 entries
   as the live `verify_all.*` array, each record verbatim; the exempt-dir list contains
   `docs/features/` in both scripts.
4. **No-error** — capture stderr on the metachar fixtures (AC-7); assert empty.
5. **Gap boundary (AC-9)** — `fx-gap-exact` HIT, `fx-gap-over` NO-hit.
6. **F-1 / F-2 / F-4 / Rev-4 regression** — `fx-negation-pre` NO-hit; `fx-historical`
   NO-hit under `gap=20`; `fx-arrow-accurate` NO-hit (entry #10 `.claude/` exclude);
   the `docs/features/` exempt-dir skip asserted.

### 7.4 sync-self

`scripts/test-verify-i6.{ps1,sh}` is **repo-bespoke** — `sync-self` mirrors only
`harness-sync`/`install-hooks`/`archive-task`/`guard-rm`, so **no `sync-self` change**.

---

## 8. Risk analysis

| ID | Risk | Severity | Mitigation |
|---|---|---|---|
| **R-1** | The `composed`/`composition` entries (#2/#4) gap-tolerantly match accurate negated/historical prose, breaking AC-4. | High | Entry #2 carries **two complementary guards** — line-scoped `exclude` (clears the four narrow-gap negation files) and per-entry `gap=20` (clears `concepts.md:104`, sub-gap 23 > 20); neither alone clears all five. No `v0.2` token (off the matched line). Verified file-by-file with exact char counts in §6; `fx-negation-pre`/`fx-historical` fixtures regression-protect it. |
| **R-2** | D-2 case-insensitivity newly catches `Scaffolding-only` (capital S) in `docs/dev-map.md:113`. | High | **PM-approved (option a):** a one-line `dev-map.md:113` edit ships in this commit (`Scaffolding-only` → `scaffolding only`). §6/F-3 confirm this is the *only* non-exempt capital-variant residual — closed set. |
| **R-3** | Task's own committed stage docs become live I.6 hits (F-2). | High | **Resolved:** I.6 exempt-dir list widened from `docs/features/_archived/` to `docs/features/` in both scripts (§3.6). PM-authorized scope extension; QA-tested (§7.2). |
| **R-4** | `grep -E` ERE vs .NET regex diverge on an edge token. | Medium | `/` and `→` are not metacharacters in either; `[regex]::Escape` / the `sed` class leave them literal. Cross-shell parity assertion (7.3 #2) catches divergence pre-merge. |
| **R-5** | bash loop var collides with the global `report=()` array (L24); PS backtick anchors error if double-quoted (L19). | Medium | Loop var is `scan_file`, others scalar (§3.3); PS entries #2/#6/#8 single-quoted (the `.ps1` won't parse if violated — self-catching) + no-error assertion (7.3 #4). |
| **R-6** | Catastrophic backtracking on a pathological line. | Low | Every gap is bounded `.{0,40}`; no nested unbounded quantifier — linear worst case (NFR-3). |
| **R-7** | A future maintainer adds an anchor containing `~`/`\|`, corrupting the bash record split. | Low | Documented in the I.6 comment header; the structural-lockstep assertion (7.3 #3) fails on a corrupted verbatim record. |

---

## 9. Migration / rollout plan

Verify-time check — no data migration, no feature flag.
1. Implement the symmetric matcher in `verify_all.{sh,ps1}`: anchor scan, line-scoped
   exclude, widened `docs/features/` exempt-dir.
2. Apply the **R-2 fix**: edit `docs/dev-map.md:113` (`Scaffolding-only` →
   `scaffolding only`) in the same commit.
3. Add `scripts/test-verify-i6.{ps1,sh}`; run both — all fixtures + cross-shell parity +
   F-1/F-2/F-4 regression fixtures pass.
4. Run `verify_all.{sh,ps1}` on the full repo — confirm I.6 = PASS, 30/30 (AC-4). The
   F-2 exempt-dir widening makes this pass **even with the stage docs already
   committed** — no commit-ordering dependency.
5. Doc fan-out (AC-10) — §10.
6. `git pre-commit` (`verify_all`) gates the commit. No rollback path: a real live hit
   is a PM finding, not a silent revert.

**Backwards compatibility:** I.6 stays one check, FAIL severity, same exempt-file list,
input set, and 30-count. Observable changes: stronger matching, a richer FAIL message
(line number + span), the wider exempt-dir (§3.6/§12). No consumer depends on the FAIL
message format.

---

## 10. Version-surface fan-out (v0.18.0 — insight L14 / L21 discipline)

The §2 table is the file list; this section gives the exact surface edits (AC-10):

- `CHANGELOG.md` — new `## v0.18.0` section: I.6 gap-tolerant upgrade + `docs/features/`
  exempt-dir widening (L21).
- `AI-GUIDE.md:68` — `30 checks at v0.17.4 … I.6 retired-claim phrase guard` →
  `30 checks at v0.18.0 … I.6 gap-tolerant retired-claim guard`.
- `docs/dev-map.md` — lines 74/129 `v0.17.4`→`v0.18.0`; line 78 add
  `test-verify-i6.{ps1,sh}`; **line 113 R-2 fix**.
- `.harness/rules/40-locations.md:43` — append `(gap-tolerant since v0.18)`.
- `.harness/insight-index.md` — note after line 18: I.6 gap-tolerant + line-scoped
  exclusion-token at v0.18.0, exempt-dir widened to `docs/features/`.
- `README.md` / `README.zh-CN.md` — add a v0.18.0 roadmap/version row.
- `scripts/verify_all.{ps1,sh}` — rewrite the I.6 comment header.

L14 caveat: G.3 catches version-badge drift but check-count claims are NOT
machine-checked — the developer hand-verifies each row.

---

## 11. Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| Per-file scan with exempt filtering | I.6's scan loop | `verify_all.sh:531-546`, `verify_all.ps1:505-520` | Reuse loop skeleton + exempt-file array verbatim; **widen** the exempt-dir array (§3.6); replace the inner literal-match with the anchor scan. |
| Check-result emitter | `step()` / `Step` | `verify_all.sh:16-24`, `verify_all.ps1` | Reuse as-is — I.6 still emits one result. |
| Test-driver harness (Assert, counters, temp-dir, `-KeepTemp`) | `test-supervisor.{ps1,sh}` | `scripts/test-supervisor.{sh,ps1}` | Copy the harness skeleton into the new `test-verify-i6` pair. |
| Isolated temp dir per fixture group | `mktemp -d` + L12 | `test-init.{ps1,sh}` | Reuse the separate-temp-dir discipline (L12). |
| Regex escaping of a literal | `[regex]::Escape` | `verify_all.ps1:450` | Reuse for PS; bash uses a `sed` metachar-class escape (§3.3). |
| Banned-phrase list + reasons | `i6_banned_phrases` / `$banned` | `verify_all.sh:505-519`, `verify_all.ps1:476-490` | Migrate (not discard) — the 13 reasons preserved verbatim; only the matching shape changes. |

No new dependency, runtime, or tool (NFR-5) — `grep`, `sed`, `.NET regex`, `git` are
already used by `verify_all`.

---

## 12. Out-of-scope clarifications

- No new/removed banned phrase — the 13-entry list is migrated 1:1 (§5). No new
  `verify_all` check (count stays 30). No NLP/embedding/LLM matching. The phrase list
  stays inline in both scripts. `templates/.../verify_all.*.tmpl` are out of scope.
- **Exempt-file membership unchanged; exempt-DIR membership IS changed** — widened to
  `docs/features/` (§3.6/F-2), a PM-authorized scope extension that is the *only*
  deviation from requirement §3's "no change to exempt-dir membership".
- The R-2 `dev-map.md:113` one-line edit ships in this commit (PM-approved) — the sole
  doc-cleanup action, a confirmed-correct guard finding, not open-ended cleanup.

---

## 13. Verdict

**READY** — implementable without further design decisions. All Gate-Review findings
closed (F-1/F-2/F-3 + re-review F-4, §14); D-1..D-6 resolved (§4); no item routes to PM.

---

## 14. Gate-review rework

Revision 2 — addressed `03_GATE_REVIEW.md` verdict `CHANGES REQUIRED`; all three
findings GR-confirmed closed in the re-review (kept here terse for traceability):
**F-1** — `exclude` made line-scoped (whole matched line, not the anchor span; §3.2);
**F-2** — I.6 exempt-dir widened from `docs/features/_archived/` to `docs/features/`
in both scripts (§3.6); **F-3** — residual set enumerated as the single file
`docs/dev-map.md:113` (§6). The matcher, the 13-entry migration, the parity argument,
boundary handling, and the test-driver design were GR-confirmed sound and unchanged.

**Revision 3** — closes re-review finding **F-4**; F-1/F-2/F-3 untouched.

- **F-4 (`concepts.md:104` uncaught; rev-2 `v0.2` claim false).** Rev-2 had removed
  #2's `gap=20` and substituted a `v0.2` exclude token, falsely claiming `v0.2` was on
  the matched line. PM verification: `v0.2` sits on `concepts.md:103` (`…The original
  v0.2 design`), while all three of #2's anchors land on `concepts.md:104`
  (`composed `.harness/rules/*.md` into a single `CLAUDE.md` so…`), which carries no
  `v0.2`/`not`/`no longer`/`referenced` — so line-scoped exclude never fired. **Fix:**
  #2 now carries **both** complementary mechanisms — (1) restored per-entry `gap=20`
  (line-104 `composed`→`into` sub-gap 23 > 20 breaks the chain → clears
  `concepts.md:104`); (2) line-scoped `exclude=('not','no longer','referenced')`
  (clears the four ~1-char-gap negation files, which `gap=20` alone cannot). The `v0.2`
  token is dropped entirely (§4.1/§5/§6/§8 R-1). This is rev-1's `gap=20` PLUS rev-2's
  line-scoped exclude together — the GR re-review noted "the prior `gap=20` override
  did clear this file." §6 gives per-file char counts; `fx-historical.md` (§7.2) is
  replaced with a two-line copy of `concepts.md:103-104` to regression-protect it.
  `gap=20` does not regress real-bypass detection (§6).

**Revision 4** — closes the developer's implementation-time blocker (rework #3);
F-1/F-2/F-3/F-4 untouched.

- **Entry #10 false-positive (`02_SOLUTION_DESIGN.md` §6 factually wrong).** The
  developer implemented the §5 matcher exactly and ran the upgraded `verify_all`
  gap-tolerantly over the whole `git ls-files` tree — entry #10 (`.harness/ ~ → ~
  CLAUDE.md`, `gap=40`, **no `exclude`**) hit two accurate-prose tracked, non-exempt
  files: `README.md:196` and `README.zh-CN.md:198` (both repo-layout lines stating
  `.harness/agents + .harness/skills → .claude/ (CLAUDE.md is a static stub …)`; the
  `→`→`CLAUDE.md` sub-gap ≈ 11 chars, inside `gap=40`). §6's prior claim that "#9/#10
  … zero non-exempt hits" was not backed by an automated scan and is false. **Fix:**
  entry #10 carries `exclude=.claude/` (§5) — the README lines all carry `.claude/`
  (harness-sync's real sync target), so the line-scoped exclude rejects them, while a
  genuine retired false claim asserting the target IS `CLAUDE.md` carries no `.claude/`
  and still hits. Mechanically identical to #2/#4's `not`/`no longer` and #11/#12's
  `不`; the low-maintenance NFR-2 property is preserved. §6 now records the developer's
  `verify_all` run as the exhaustive automated check: the complete non-exempt hit set
  is exactly `dev-map.md:113` (R-2) once #10's exclude is applied; #9 has zero hits and
  needs no `exclude` (verify_all evidence). §7.2 adds `fx-arrow-accurate.md` (NO-hit
  regression). §3.3 records that the bash exclude test uses `shopt -s nocasematch` +
  `[[ == *glob* ]]` (Git-for-Windows GNU grep 3.0 SIGABRTs on `-F -i`) — behaviorally
  identical, no rework.
