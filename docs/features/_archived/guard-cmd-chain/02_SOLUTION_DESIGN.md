# 02 — Solution Design · T-17 `guard-cmd-chain`

> **POST-DELIVERY CORRECTION (PM Orchestrator, 2026-08-01).** Three statements in this document are
> **known false** against the shipped implementation. They are recorded here rather than rewritten in
> place, so the design remains the record of what was decided while no reader is misled by it. All
> three divergences were adjudicated at stage 5 as **correct fixes-forward**; none required an
> architect round. Details and evidence: `05_CODE_REVIEW.md` §5.1, §5.2 and round-3 §1/§9.
>
> 1. **§3.1, "End of input (total)" — the unconditional `HDBODY` → parse-failure rule is wrong.** A
>    here-document whose terminator is the final line is **accepted**. The design's reading would
>    block essentially every `cat > f <<'EOF' … EOF` an agent writes, because command substitution
>    strips the trailing newline from every command string the guard ever sees — it would have failed
>    acceptance criterion AC-3 L9, the row the requirement calls load-bearing. A genuinely
>    unterminated here-document still blocks (pinned by driver row `F3`).
> 2. **§10.3's F-9 evidence row is unachievable as written.** `echo $'it\'s fine'` contains *three*
>    apostrophes, so the retained pre-change `tokenize()` blocks it **pre-change too**; the
>    `sq_ansi` flag is implemented as designed but is unobservable at top level. ANSI-C strings are
>    therefore recorded as an accepted over-block rather than claimed fixed.
> 3. **§3.1 rows 12/15 — "`prev` is the raw previous byte" is a false-negative generator** and was
>    replaced. An escaped `\>` or `\<` before `&` suppressed the separator, so
>    `echo a\>& rm -rf <outside>` passed. The shipped code records the index at which a redirection
>    operator was actually appended. That index's sentinel **must be outside the domain of `i - 1`**
>    (`-2`, not `-1`) — the first attempt used `-1` and reopened a bypass at `i == 0`.

- Mode: **full** · Stage 2 (solution-architect) · Security task · **Round 2 (amended after gate review)**
- Input: `docs/features/guard-cmd-chain/01_REQUIREMENT_ANALYSIS.md` (verdict **READY**),
  `docs/features/guard-cmd-chain/03_GATE_REVIEW.md` (verdict **BLOCKED ON DESIGN**, findings F-1…F-9, F-12)
- deferred-human: **defer, do not ask.** All six OQs are PM-RESOLVED (OQ-1a … OQ-6a) and binding; none re-opened.
- Partition mode: **single-developer** (no `.harness/agents/dev-*.md`) — no partition section.
- Paths are repo-relative to `/home/alan/Programs/harness-kit`.

## 0. Round-2 changelog (what the gate findings changed)

| Finding | Change | Section |
|---|---|---|
| F-1 | Nesting frames now save **and restore** the quote state; inner buffer starts `NORMAL`; the `)`×DQ exception is gone and the table is total | §3.1 |
| F-2 | Invariant restated: **`P` contains `s` itself at every depth**; "provable by inspection" withdrawn; AC-4 differential is IS-2's proof | §1, §3.2, §3.5, §8 R5, §12 |
| F-3 | `find`: carrier scan **first, no `return`**, then the byte-unchanged `-delete` branch — §3.4 and §6 now say the same thing | §3.4, §6 |
| F-4 | §10.2 gains the general union-residue statement; L10 demoted to one instance of that class; R1's "structurally incapable" claim withdrawn | §3.1, §8 R1, §10.2, §10.3 |
| F-5 | Driver-row quoting mandated (both shells) + echo-back check; R7's failure mode corrected to *loud FAIL* | §6.2, §8 R7 |
| F-6 | PS: length-guarded lookahead + `try/catch`; the two failure signals reconciled into one channel; new risk row | §8 R11, §9.2 |
| F-7 | Exact assignment test specified (name-then-`=` split, no malformed glob) | §3.3 |
| F-8 | Explicit longest-prefix dispatch order; fast-path list re-derived from the final table (`:` dropped, `\` added) | §3.1, §3.2 |
| F-9 | ANSI-C quoting **fixed** (one `sq_ansi` flag) rather than recorded, with a driver row as evidence | §3.1, §10.3 |
| F-12 | Override's whole-line authorization named in the residual list | §10.2 |
| C-4 / C-6 / C-8 | Override evaluated once on the top-level `cmd` only; `sync-self --check` before promoting; `CONTEXT.md` **not** touched | §5.1, §9.1, §11 |
| — | New over-block class created by C-1 at depth 0, pre-declared | §10.3 |

**Size note (`70-doc-size.md`, 500-line soft WARN cap).** Round 1 was 579 lines; round 2 adds four
specifications the gate required (frame quote save/restore + total table, the C-1 invariant and its
consequence, the pinned `find` ordering, the union-residue coverage statement) and one fix (F-9). A
compression pass on §2, §3.1-§3.4, §5.1, §9.2, §9.3, §10.2 and §12 recovered part of that; the doc
still lands over cap. The over-cap content is the §3.1 state table (30 lines — the deliverable
itself), the §6 flow and §3.4 ordering block (deliberately duplicated, because their disagreement
*was* F-3), and the §10.2 residual list (the task's coverage-honesty deliverable). Nothing here is
narrative; cutting further would remove a specification the Developer needs.

---

## 1. Architecture summary

The guard keeps its verb set, its path resolver and its verdict machinery exactly as they are;
what changes is **how a command line is decomposed before the classifier sees it**. Today the
only decomposition is `split_pipes()` (`|` at top level). This design adds a second, richer
decomposition — a total, single-pass, quote/here-doc/comment-aware **position scanner** — and
feeds the classifier the **union** of the two decompositions *plus the input string itself*. The
union is the load-bearing structural choice: no string the pre-change guard classified is ever
dropped, at any depth. IS-2 (monotonicity) is therefore *structurally intended* but **not
inspection-provable** — the nested-interpreter call sites re-decompose a string that used to be
classified whole, so the proof obligation is the **AC-4 differential run** (§3.2, gate C-1). Two
smaller changes complete the reachability fix inside the classifier: a widened **prefix-strip**
(assignments, shell reserved words, argv-carrier verbs join the existing `sudo` strip) and a new
**nested-interpreter branch** for `bash`/`sh`/`dash`/`zsh`/`ksh` next to the existing `pwsh` one.
A command-text `HARNESS_ALLOW_OUTSIDE_RM=1` prefix becomes a recognized, *audited* override
(OQ-1a) evaluated once, before any parsing. No new dependency, no new gate check, no config that
can weaken the guard.

---

## 2. Affected modules

Code: `guard-rm.sh` / `guard-rm.ps1` — **edited in
`skills/harness-init/templates/common/.harness/scripts/`** (sync-self Mapping 5 source), never in
`.harness/scripts/` (byte-mirror). Tests: `.harness/scripts/test-guard-rm.{sh,ps1}` +
`evals/guard-rm-cases.md` (hand-maintained, no template twin). Docs/ledger:
`.harness/rules/75-safety-hook.md` + its `.md.tmpl` twin, `.harness/scripts/baseline.json`.
`CONTEXT.md` needs **no** edit — it already carries **Command position** at `CONTEXT.md:100-102`
(gate C-8). §11 is the full ledger, per-file, including what is verified *not* to change.

---

## 3. Module decomposition

### 3.1 `split_positions()` — the scanner (new, bash) / `Split-CommandPositions` (PS)

**Responsibility.** Given one command string, return the list of substrings at which a shell
would begin parsing a simple command, and a parse-failure flag. It never resolves paths, never
looks at verbs, never forks.

**Public API (bash).** `split_positions <string>` → fills global `_POSITIONS=()`; returns `0` on
success, `1` on unresolvable structure. Callers snapshot `_POSITIONS` into a local array
immediately (recursion clobbers globals — same discipline as `guard-rm.sh:304-305`; use the
`("${_POSITIONS[@]+"${_POSITIONS[@]}"}")` idiom, never `declare -a`).

**Public API (PS).** `Split-CommandPositions([string]$s)` → returns `,$list.ToArray()`, or
`$null` on unresolvable structure (mirrors the existing `Get-Tokens` `$null` contract,
`guard-rm.ps1:94`). The `$null` is converted to the **single** existing failure channel
`'__PARSE_FAIL__'` by the caller — see §9.2.

**Chosen strategy: a single-pass character lexer with an explicit nesting stack, emitting
*segment strings* — not a syntax tree.** Rejected: recursive-descent shell grammar (an order of
magnitude more code in both shells, in the one script whose failure blocks every Bash tool call —
NFR-3 — for structure the classifier never consumes); `sed`/`awk`/regex pre-split (not quote- or
here-doc-aware, forks, cannot be made total); asking a real shell (cannot enumerate positions, new
dependency); tree + per-node classify (same coverage, higher risk). The lexer wins because its
**output type is already the classifier's input type**, so `classify_segment()`'s verb dispatch,
`find` branch, path walk, `resolve_leaf()` and `is_descendant()` stay byte-unchanged (AC-2/AC-5/IS-5).

**Nesting stack (F-1).** Frames: `CMDSUB` (`$(`), `BQ` (backtick), `PROCSUB` (`<(` / `>(`),
`GROUP_PAREN` (`(`), `GROUP_BRACE` (`{` at word start), `PARAM` (`${`), `ARITH` (`$((`).

- `CMDSUB` / `BQ` / `PROCSUB` push a frame that **saves the outer buffer *and* the outer quote
  state**, then start a fresh inner buffer **at state `NORMAL`**. On close: the inner buffer is
  emitted as a position, the frame pops, and **both** the outer buffer and the outer quote state
  are restored. This is what makes `echo "$(true && rm -rf /etc/x)"` yield the positions `true`
  and `rm -rf /etc/x` (BLOCK) instead of one `true && rm -rf /etc/x` (ALLOW).
- `GROUP_PAREN` / `GROUP_BRACE` flush and start fresh; nothing to restore.
- `PARAM` / `ARITH` carry no command positions: their characters are appended verbatim, the quote
  state is untouched, and they **do not count toward depth** — they exist only so their closer
  (`}` / `))`) is matched instead of being read as a separator.
- Depth counter increments for `CMDSUB`/`BQ`/`PROCSUB`/`GROUP_PAREN`/`GROUP_BRACE` only; a push
  past depth **2** → parse failure (B-5). Non-empty stack at end of input → parse failure
  (IS-1 row 18).

**Dispatch order is longest-prefix and is the row order below (F-8).** Exactly one row fires per
step: `$((` is tested before `$(` before `${` before `$`; `<<<` before `<<` before `<(` before
`<`; `&&` before `&>` before `&`; `))` is handled inside the `)` row. `prev` = the raw input
character immediately before the current index (empty at index 0). `flush` = emit the current
buffer as a position and clear it; empty/whitespace-only buffers are dropped (B-3). `sq_ansi` is a
one-bit flag, set when `SQ` is entered, that marks an ANSI-C `$'…'` string (F-9).

| # | Input (dispatch order) | NORMAL | SQ | DQ |
|---|---|---|---|---|
| 1 | `\` + next char | append both, `i+=2`; a lone trailing `\` is appended | `sq_ansi=1` → append both, `i+=2`; else append `\` as a literal | append both, `i+=2` (B-9) |
| 2 | `'` | append, →SQ, `sq_ansi = (prev == '$')` | append, →NORMAL | append |
| 3 | `"` | append, →DQ | append | append, →NORMAL |
| 4 | `` ` `` | top=BQ → emit inner, pop, restore | append | push BQ (save buffer+DQ) |
| 5 | `$((` | append, push ARITH, `i+=3` | append | append, push ARITH, `i+=3` |
| 6 | `$(` | push CMDSUB (save buffer+state), `i+=2` | append | push CMDSUB (save buffer+DQ), `i+=2` |
| 7 | `${` | append, push PARAM, `i+=2` | append | append, push PARAM, `i+=2` |
| 8 | `$` (other) | append | append | append |
| 9 | `<<<` | append, `i+=3` | append | append |
| 10 | `<<` | append, then read + enqueue the here-doc delimiter (below) | append | append |
| 11 | `<(` / `>(` | push PROCSUB (save buffer+state), `i+=2` | append | append |
| 12 | `<` / `>` | append | append | append |
| 13 | `&&` | flush, `i+=2` | append | append |
| 14 | `&>` | append both, `i+=2` | append | append |
| 15 | `&` | `prev` ∈ {`>`,`<`} → append; else flush | append | append |
| 16 | `\|` | **flush, unconditionally** (identical to `split_pipes`) | append | append |
| 17 | `;` | flush | append | append |
| 18 | `(` | flush, push GROUP_PAREN | append | append |
| 19 | `)` | top=CMDSUB/PROCSUB → emit inner, pop, **restore buffer + quote state**; top=ARITH ∧ next=`)` → append `))`, pop, `i+=2`; top=GROUP_PAREN → flush, pop; else flush, **no pop** (`case` patterns) | append | top=ARITH ∧ next=`)` → append `))`, pop, `i+=2`; else append |
| 20 | `{` | buffer empty/blank → flush, push GROUP_BRACE; else append (brace expansion, `-I{}`) | append | append |
| 21 | `}` | top=PARAM → append, pop; top=GROUP_BRACE → flush, pop; else append | append | top=PARAM → append, pop; else append |
| 22 | LF / CR | here-doc queue non-empty → flush, →HDBODY; else flush | append | append |
| 23 | `#` | buffer empty or ends with space/tab → →COMMENT; else append | append | append |
| 24 | **any other byte** (incl. space, tab) | append | append | append |

The table is **total for `NORMAL`/`SQ`/`DQ`**: row 24 is the catch-all, and no cell carries an
exception clause. The two remaining states are constant and are stated as prose rather than as two
near-constant columns:

- **`COMMENT`** — every byte is discarded. On LF/CR: flush, then →HDBODY if the here-doc queue is
  non-empty, else →NORMAL. (`#` cannot start a comment inside a quote: rows 23/2/3 make that
  unreachable.)
- **`HDBODY`** — every byte accumulates into a *terminator-compare line buffer*, never into the
  position buffer, and produces **no scanner position**. On LF/CR: compare the line against the
  queue front (strip leading tabs first if the delimiter was written `<<-`); on match, dequeue and
  →NORMAL if the queue is now empty, else stay in `HDBODY`; on mismatch, clear the line buffer and
  stay in `HDBODY`. *(This is a statement about the **scanner** only — the retained pre-change pass
  is not here-doc-aware and does derive positions from body text; see §10.2 item 11.)*

**Here-doc delimiter read** (a sub-step of row 10, not a state): consume an optional `-` (sets
tab-stripping for the terminator compare), skip spaces/tabs, read the word — `'W'`, `"W"`, `\W`,
or bare-until-whitespace-or-separator — strip its quotes, **enqueue** it. Several here-docs on one
line are consumed in declaration order.

**End of input (total).** `SQ`/`DQ` → parse failure (B-4). `HDBODY` → parse failure. `NORMAL`/
`COMMENT` with a non-empty here-doc queue → parse failure (a `<<WORD` whose body never started).
Non-empty nesting stack → parse failure. Otherwise flush, success. **Every parse failure sets
`parse_failed=1` and the walker exits 2 with the existing message (`guard-rm.sh:316-319`) — never
a skip (IS-3, IS-1 rows 18-19).**

### 3.2 `classify_command_string()` (new, thin) / `Get-OffendingFromCommandString`

**Responsibility.** The union step and the single entry point for "judge this command string".

```
classify_command_string(s, depth):
    if depth > 2: parse_failed=1; return
    P = [ s ]                                          # C-1: the input string itself, at EVERY depth
    split_pipes(s); for seg in snapshot(_SEGS): P += seg if not already in P
    if s contains any of  ; & ( ) { } ` < > \ LF CR    # fork-free glob test, one pass
        if ! split_positions(s): parse_failed=1; return
        for q in snapshot(_POSITIONS): P += q if not already in P
    for seg in P: if seg non-empty: classify_segment(seg, depth)
```

**The invariant (F-2 / C-1): `P` contains the input string `s` itself, at every depth.** The
round-1 formulation ("`P ⊇ split_pipes(s)` at depth 0") was false one level down: §3.5 changes the
`pwsh` call site from classifying the inner string **whole** to classifying it **decomposed**, and
decomposition strictly narrows each verb's token walk — `pwsh -c "Remove-Item -Recurse ./tmp |
Tee-Object C:\log"` flips BLOCK→ALLOW, because the whole-string walk is exactly what reaches
`C:\log`. Keeping `s` in `P` unconditionally restores it, with no context parameter a developer can
get wrong (a wrong flag here would fail **open**).

**Consequence: IS-2 is no longer provable by inspection.** Adding `s` at depth 0 also *adds* a
position the pre-change guard never judged whenever the line contains a top-level `|`
(pre-declared over-block, §10.3). IS-2's proof obligation is the **AC-4 differential run** — pre-
vs post-change verdicts over the readable in-repo corpus, identical except the AC-1 rows — not a
reading of this section.

Dedup is an exact-string linear scan over an indexed array (no associative arrays — §9.3 bash-3.2
constraint); it bounds cost only, duplicates being harmless (B-11). `split_pipes` trims its
segments, so a trimmed segment and the untrimmed `s` can both survive — harmless.

**Fast-path glob, re-derived from the final table (F-8).** The scanner can emit a boundary
`split_pipes` does not only via a flush/frame-emit row (13, 15, 17, 18, 19, 20, 21, 22), a frame
push (4, 6, 11), or a quote-state divergence from `split_pipes`'s naive toggling (row 1 — e.g.
`echo \'a|b`, where `split_pipes` believes it is inside a quote and the scanner does not). The
trigger set is therefore exactly `;` `&` `(` `)` `{` `}` `` ` `` `<` `>` `\` LF CR: `:` is dropped
(no cell reacts to it), `$` and `|` are redundant (`$(`/`${`/`$((` need `(` or `{`; `|` is handled
identically by both passes), `#` is excluded (a comment can only *remove* positions). Suggested
spelling (verify with `bash -n` plus a driver probe row):

```bash
if [[ "$s" == *[\;\&\(\)\{\}\`\<\>\\]* ]] || [[ "$s" == *$'\n'* ]] || [[ "$s" == *$'\r'* ]]; then
```

Twelve separate `[[ ]]` tests are an acceptable, semantically identical fallback if the bracket
expression proves finicky in bash 3.2. A command with none of these characters runs **exactly**
today's code path plus one `[[ ]]` test.

### 3.3 `_skip_prefix()` (new) — the widened prefix strip / `Get-PrefixIndex`

Replaces the inline `sudo` block at `guard-rm.sh:212-221` (that block's body moves in
**verbatim**). Loops, advancing `idx` while `tokens[idx]` is:

1. an **assignment**. Exact test (F-7 — the round-1 glob `[A-Za-z_][A-Za-z0-9_]*=*` was malformed:
   it required *two* name characters and accepted `AB;rm=x`). Split at the first `=`, then
   validate the name, fork-free and bash-3.2-safe:

   ```bash
   if [[ "$t" == *=* ]]; then
       name="${t%%=*}"
       if [[ -n "$name" && "$name" != *[!A-Za-z0-9_]* && "$name" != [0-9]* ]]; then  # assignment → skip
   ```

   `A=1` matches (one-letter names close that bypass); `AB;rm=x` does not (`;` is outside the
   class); `=x` does not (empty name); `1A=x` does not (leading digit). PS twin:
   `$t -match '^[A-Za-z_][A-Za-z0-9_]*='` (anchored; PS regex needs no bash-3.2 concession).
2. `sudo` → existing `-E` / `-H` / `-u USER` logic, byte-for-byte;
3. a **reserved word** — `if then elif else fi while until do done for select case esac in
   function coproc !` and stray `{` / `}` → skip. Closes `do rm -rf OUT; done`, `then rm -rf OUT`
   and the `} rm …` residue of a brace split. Safe by construction: the destructive-verb test
   still gates every path walk, so stripping a reserved word in front of a harmless verb changes
   nothing.

Termination: `idx` strictly increases. Returns `idx`; everything downstream of
`local verb="${tokens[$idx]}"` (`guard-rm.sh:223`) is unchanged.

### 3.4 Argv carriers (IS-1 row 9) — reachability paths, not verbs

`CARRIERS = xargs env nohup nice time timeout command exec find` (exact, case-sensitive; POSIX
command names). **These are not added to the destructive verb set** (AC-6): they never cause a
block by themselves, they only expose positions.

**Rule (one linear scan, no option tables).** When the post-prefix verb is a carrier, scan
`tokens[idx+1 … n-1]` once; for each token that is **either** a destructive verb (same
`_is_destructive_verb` test) **or** a nested-interpreter verb (`bash sh dash zsh ksh pwsh
powershell`), run the same dispatch `classify_segment` would run with `idx` set to that token's
index (interpreter → `classify_command_string` on its first non-option argument at `depth+1`;
destructive verb → the existing token walk from that index + 1). The scan **runs to the end and
never returns early**; repeated dispatches are harmless (B-11). Nothing else in the scan acts.

No per-carrier option table: an incomplete table produces **false negatives** (`xargs -d , rm -rf
OUT` would take `,` as the command) — the forbidden direction. "Every remaining token is a
candidate" is exactly IS-1 row 9's wording, is total, and cannot mis-skip; false-positive cost is
near zero because only *exact* destructive/interpreter verb tokens dispatch.

**Branch ordering for `find` — pinned (F-3 / C-3).** The carrier scan and the `-delete` branch are
**sequential, not exclusive**. In `classify_segment`, after `_skip_prefix`:

```
if verb is pwsh/powershell        → interpreter branch, return
if verb is bash/sh/dash/zsh/ksh   → interpreter branch, return
if verb is a CARRIER              → carrier scan            ← runs first, NO return
if verb == find                   → existing -delete branch (byte-unchanged, may return early)
if _is_destructive_verb(verb)     → existing token walk
```

`find` is in `CARRIERS`, so both run for it, in that order. Neither exclusive ordering works:
carrier-first-with-`return` would silently flip fixture rows 9 (`find /etc -delete`) and 17 to
ALLOW, breaking AC-2 *and* IS-2; find-first lets `guard-rm.sh:250`'s `(( has_delete == 0 )) &&
return` fire and AC-1 row o (`find . -name '*.log' -exec rm -rf OUT ;`) pass. With the pinned
order: row o's carrier scan dispatches at `rm` → BLOCK, then the `-delete` branch returns early;
rows 9/17 find nothing in the carrier scan and then take the untouched `-delete` path → BLOCK;
fixture row 10 (`find . -name '*.log' -delete`) stays ALLOW.

Hand-verified against the bypass matrix: `xargs -I {} rm -rf OUT` (k), `timeout 5 rm -rf OUT` (n),
`env FOO=1 rm -rf OUT` (l), `nohup rm -rf OUT` (m), row o — all BLOCK; `xargs grep rm` ALLOW
(dispatch on `rm` finds no path token). Carriers do **not** consume recursion depth (they advance
an index inside one already-parsed token list), so `timeout 5 env FOO=1 nice -n 10 make` cannot
hit the depth bound.

### 3.5 Nested interpreters (IS-1 row 10, OQ-5a)

- **`pwsh` / `powershell` branch (`guard-rm.sh:226-241`): one call-site change** —
  `classify_segment "${tokens[$((j+1))]}" $((depth+1))` becomes
  `classify_command_string "${tokens[$((j+1))]}" $((depth+1))`, so an inner *chain* is judged too.
  Because `P` contains the input string itself (§3.2), the inner string is **also** still
  classified whole, exactly as today — that is what keeps
  `pwsh -c "Remove-Item -Recurse ./tmp | Tee-Object C:\log"` a BLOCK (F-2). The `verb_lc`
  computation on `:227` becomes a fork-free glob test (§9.3); the flag list, the `parse_failed` on
  a missing argument and the `return` are untouched. Fixture row 8 keeps its verdict.
- **New parallel branch** for `bash sh dash zsh ksh`: for every subsequent token that is **not**
  option-shaped (`-*`), call `classify_command_string <token> depth+1`. Deliberately broader than
  "find `-c`": `bash --rcfile foo -c "rm -rf OUT"` is judged, and `bash script.sh` degrades to
  judging the literal string `script.sh` (verb `script.sh`, not destructive → ALLOW), preserving
  IS-1 row 15 without a false positive. `bash -c "rm -rf OUT"` → BLOCK (AC-1 row r). Depth bound 2
  applies (B-5).

### 3.6 `_is_destructive_verb()` (new) / `Test-DestructiveVerb`

A fork-free, bash-3.2-safe, case-insensitive membership test over the **unchanged** verb set,
implemented as a constant list of bracket-class globs (`[Rr][Mm]`, `[Rr][Mm][Dd][Ii][Rr]`,
`[Uu][Nn][Ll][Ii][Nn][Kk]`, `[Rr][Ee][Mm][Oo][Vv][Ee]-[Ii][Tt][Ee][Mm]`, `[Dd][Ee][Ll]`,
`[Ee][Rr][Aa][Ss][Ee]`, `[Cc][Ll][Ee][Aa][Rr]-[Rr][Ee][Cc][Yy][Cc][Ll][Ee][Bb][Ii][Nn]`,
`[Ss][Hh][Rr][Ee][Dd]`, `[Ss][Rr][Mm]`). It replaces the loop at `guard-rm.sh:265-272`, which
forks `printf | tr` once per verb per segment (18 forks/segment) — see §9.3. `destructive_verbs_ci`
(`:83`) stays in the file as the human-readable declaration and as AC-6's diff target; the glob
list is its mechanical twin and the two are asserted equal-membership in a code comment ledger
(9 members, both lists).

---

## 4. Data model changes

None. The guard is stateless (B-12): no temp file, no lock, no shared write. The only persisted
artifact is one new ledger key in `.harness/scripts/baseline.json`:

```
"test_guard_rm_bash_assertions": <captured>
```

**The value is transcribed from the `PASS:` line of a real `test-guard-rm.sh` run, never derived
arithmetically** (insight 2026-07-31). The key needs no host qualifier: python3 affects only
payload *encoding* in `test-guard-rm.sh:44-57`, not the case count. The PowerShell key stays
**out** of `baseline.json` until an operator run produces a real tally (OQ-4a) — record that
absence in the `_qa_note` prose so the next reader does not "reconcile" a phantom.

---

## 5. API contracts

The guard's contract is its **exit code and stderr**; both are preserved.

| Surface | Contract | Change |
|---|---|---|
| stdin | Claude Code `{"tool_input":{"command":"…"}}` | unchanged |
| exit 0 / exit 2 | ALLOW / BLOCK with stderr message | unchanged, both classes |
| stderr override line | `harness-kit guard-rm: override active (HARNESS_ALLOW_OUTSIDE_RM=1) — allowing destructive command.` | **now also emitted for the command-text prefix**, byte-identical (OQ-1a) |
| BLOCK message | `guard-rm.sh:324-335` | unchanged — names every offending path across all positions (IS-6, B-11) |
| `test-guard-rm.sh` | `bash .harness/scripts/test-guard-rm.sh [guard-path]` | **new optional arg**, default `$repo_root/.harness/scripts/guard-rm.sh` |
| `test-guard-rm.ps1` | `-Guard <path>` | same, PS-idiomatic |

### 5.1 The command-text override (OQ-1a) — placement and fail-closed shape

Placed as a new **step 2b**, immediately after the env-var block (`guard-rm.sh:60-63`) and before
the `.git/` walk, so it short-circuits before any parsing — exactly like the env path. **It is
evaluated exactly once, on the top-level `cmd`, and never inside `classify_command_string` or
`classify_segment` (gate C-4).** Re-applying it per position would make
`echo x && HARNESS_ALLOW_OUTSIDE_RM=1 rm -rf OUT` self-authorizing, which is precisely the bypass
this shape prevents.

Recognition (single O(1) prefix test, no tokenizing, no regex):

- left-trim spaces/tabs from `cmd` using the existing trim idiom (`guard-rm.sh:134-135`);
- the remainder must **start with** the literal `HARNESS_ALLOW_OUTSIDE_RM=1` followed by a space
  or a tab; case-sensitive (bash `[[ == ]]`; PS `StartsWith(…, [StringComparison]::Ordinal)` —
  **not** `-eq`/`-match`, which are case-insensitive and would accept
  `harness_allow_outside_rm=1`, a widening);
- nothing else qualifies: not `=0`, not `=10`, not quoted, not after another assignment, not after
  any separator.

**Only a leading prefix on the whole line counts**, because: it is the byte-form the rule document
already documents (`75-safety-hook.md:71`); an override's audit value is that it is visible at the
head of the transcript line, where a mid-chain one would hide the authorization far from the
deletion; `echo x && HARNESS_ALLOW_OUTSIDE_RM=1 rm -rf OUT` must not self-authorize, and here it
does not (prefix not at offset 0 → line parsed → assignment transparent per §3.3 → `rm` judged →
**BLOCK**); and an O(1) prefix test cannot be confused by quoting, so it adds no parser surface.

Net direction: today this text reaches exit 0 *silently* through the unknown-verb path (E-1); after
the change it reaches exit 0 **with an audit line** — the existing escape hatch, instrumented, never
more permissive. Its whole-line scope is a named residual (§10.2 item 9).

---

## 6. Flow

```
stdin JSON
  └─ extract .tool_input.command        (python3 path, or heuristic fallback + unescape §6.1)
      └─ [2]  env HARNESS_ALLOW_OUTSIDE_RM=1 ? ──► audit line, exit 0
          └─ [2b] top-level cmd starts with "HARNESS_ALLOW_OUTSIDE_RM=1 " ? ──► same audit line, exit 0
              └─ [3]  walk to nearest .git/ ancestor  (none ──► WARN, exit 0)
                  └─ [4]  truncate to 8192
                      └─ classify_command_string(cmd, 0)
                          ├─ P := [ cmd ]                       ← C-1, at every depth
                          ├─ split_pipes(cmd)  → P += segments  [byte-unchanged]
                          ├─ fast-path glob hit? → split_positions(cmd) → P += positions  [new scanner]
                          │      └─ parse failure ─────────────────────────────► exit 2
                          └─ for each seg in P:
                                classify_segment(seg, depth)
                                  ├─ tokenize(seg)   [unchanged] → parse failure ► exit 2
                                  ├─ _skip_prefix()  [assignments · sudo · reserved words]
                                  ├─ verb pwsh/powershell?      → classify_command_string(inner, d+1); return
                                  ├─ verb bash/sh/dash/zsh/ksh? → classify_command_string(tok,   d+1); return
                                  ├─ verb in CARRIERS?          → linear scan, dispatch at each hit   (NO return)
                                  ├─ verb == find?              → existing -delete branch [unchanged] (may return)
                                  └─ _is_destructive_verb(verb)? → walk tokens
                                          resolve_leaf() + is_descendant()   [both unchanged]
                                            └─ outside root → segment_offending += path
                      └─ any offending path ──► exit 2 with the existing BLOCK message
                      └─ none                ──► exit 0
```

The carrier and `find` lines are **sequential**, not alternatives — see §3.4 (F-3).

### 6.1 JSON decode: the newline dependency (must be fixed here)

IS-1 row 2 claims newline-separated coverage unconditionally, but the guard's **no-python3**
fallback (`guard-rm.sh:43-56`) unescapes only `\"` and `\\`. A JSON payload encodes a command
newline as the two characters `\` `n`, so on a host without python3 `echo hi\nrm -rf OUT` never
contains a real newline and the scanner sees no separator — AC-1 row f would silently pass.

**Required change:** in the fallback only, unescape `\n`, `\r`, `\t` **before** the existing `\\`
step, using a literal-replacement helper (B-14 — copy `str_replace_all` verbatim from
`.harness/scripts/upgrade-project.sh:124-131`). **No `${var//needle/repl}` may appear in any new
code**: bash 5.2 `patsub_replacement` expands an unescaped `&` in the replacement to the matched
text, and command strings here are full of `&` (insight 2026-06-21). The two existing `${cmd//…}`
lines at `:54-55` stay byte-unchanged (their replacements are `"` and `\` — no `&`).

Symmetrically, `test-guard-rm.sh`'s fallback encoder (`:52-56`) must escape a real newline to `\n`
via the same helper, or the multi-line row cannot be expressed on a no-python3 host.

### 6.2 Driver row encoding: delimiter **and** quoting (both are blockers)

`test-guard-rm.sh:16-35` encodes rows as `id|cmd|override|expected` and splits on `|`
(`:60-62`). AC-1 rows **d** (`false || rm -rf OUT`), **q** and AC-3 **L5**, **L11** contain `|`, so
`cmd` truncates at the first `|` and the residue lands in `expected` — which can then never equal
`ALLOW`/`BLOCK`, so those rows **FAIL loudly** (they do not fabricate green; F-5 corrects the
round-1 claim). The hazard is subtler: the *command actually fed to the guard* is a truncated,
different command, and a developer chasing the red row can "fix" it without noticing.

**Replacement encoding:** a flat 4-tuple array iterated in strides of 4
(`cases=( "id" "cmd" "override" "expected" … )`) — no delimiter, no escaping. The PS twin already
uses hashtables and needs only new rows plus `-Guard`.

**Quoting constraint — mandatory, both shells (F-5 / C-5).** Array elements and hashtable values
obey the quoting of their literal:

- **Single-quote (bash `'…'`, PS `'…'`) every row whose text contains `$`, `` ` `` or `$(`.** A
  double-quoted element containing `$(` is command-substituted **when the array is defined** —
  AC-1 row i (`echo $(rm -rf /etc/harness-guard-probe)`) would really run the deletion on the
  developer's machine, in bash *and* in PowerShell (`@{ cmd = "echo $(rm …)" }` invokes the
  subexpression).
- **Newline / CRLF rows:** bash `$'echo hi\nrm -rf OUT'` and `$'echo hi\r\nrm -rf OUT'` — `$'…'`
  performs no substitution. PS equivalent: a double-quoted string with `` `n `` / `` `r`n ``,
  permitted only because those rows contain no `$` or `` ` `` payload of their own.
- Rows containing `'` but no `$` (e.g. L11) may use a double-quoted element with `\"`, or
  `$'…\'…'`. Existing row 8 (`test-guard-rm.sh:24`) is already single-quoted for this reason.
- **Echo-back check:** `test-guard-rm.sh:80` prints `$cmd` in the PASS line. QA must confirm each
  new row echoes back **intact** — that is the detector for a truncated or pre-expanded row.

---

## 7. Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| Pre-change segmentation (monotonicity anchor) | `split_pipes()` | `.harness/scripts/guard-rm.sh:119-146` | **Reuse byte-unchanged** as one member of the union |
| Word splitting + quote balance | `tokenize()` | `guard-rm.sh:86-117` | Reuse as-is |
| Path resolution | `resolve_leaf()` | `guard-rm.sh:148-186` | Reuse **byte-unchanged** (AC-2/AC-5/IS-5, leaf-only contract from T-001) |
| Root containment | `is_descendant()` | `guard-rm.sh:188-196` | Reuse byte-unchanged |
| `sudo` prefix strip | `classify_segment` `:212-221` | `guard-rm.sh` | Move **verbatim** into `_skip_prefix()` |
| `find … -delete` path logic | `classify_segment` `:243-262` | `guard-rm.sh` | Reuse byte-unchanged; carrier scan runs **before** it, without returning |
| Nested-interpreter recursion + depth bound | pwsh branch `:226-241` | `guard-rm.sh` | Reuse; **one** call-site change + a fork-free verb test |
| Fail-closed plumbing | `parse_failed` / `__PARSE_FAIL__` | `guard-rm.sh:200`, `guard-rm.ps1:174,178` | Reuse both idioms; invent no new failure channel |
| Empty-array-under-`set -u` idiom | `("${arr[@]+"${arr[@]}"}")` | `guard-rm.sh:208`, `:305` | Reuse for `_POSITIONS` |
| Literal string replacement (patsub-safe) | `str_replace_all()` | `.harness/scripts/upgrade-project.sh:124-131` | Copy verbatim into the guard's fallback |
| Byte-mirroring to the template | sync-self Mapping 5 | `.harness/scripts/sync-self.sh:74-76` | Reuse; no new mapping |
| Guard presence/wiring gate | verify_all F.2 | `.harness/scripts/verify_all.sh:290-334` | Reuse unchanged — presence + wiring, not behaviour (AC-8) |
| PS array-coercion safety | `,$list.ToArray()` | `guard-rm.ps1:97,117` | Reuse for the new PS functions |
| Test payload encoding | `encode_payload()` | `test-guard-rm.sh:44-57` | Extend (newline escaping) |
| Position-scanner algorithm | *(none found — grepped `split_`, `tokenize`, `Split-` across `.harness/scripts/` and `skills/`)* | — | **New module justified**: nothing in the repo decomposes a shell line beyond `\|` |

---

## 8. Risk analysis

| # | Risk | Mitigation |
|---|---|---|
| R1 | **Here-doc mis-detection** → every `cat > f <<'EOF' … rm … EOF` blocks; agents write files this way, so the whole toolchain seizes (AC-3 L9 is load-bearing). | L9/L10 are first-class driver rows; the guard is exercised **against the template copy** before promotion (§9.1), so a mistake never reaches the live hook. The scanner emits no position from body text (§3.1 `HDBODY`). **Not a totality claim:** the retained pre-change pass still splits body text on `\|` — §10.2 item 11. |
| R2 | **Bricking the live guard.** A bash syntax error exits 2 and blocks *every* Bash tool call for every downstream agent (E-2; the hook has no `\|\| exit 0`). | Never hand-edit `.harness/scripts/guard-rm.sh`; edit the template, `bash -n` it, drive it, then promote with one `sync-self`. Repair path: the **Write/Edit tools**, which the `matcher: Bash` hook does not govern. `git checkout` is **not** a repair path — it is a Bash call and would itself be blocked. |
| R3 | **Latency blow-up.** The existing verb loop forks `printf \| tr` 9×2 times *per segment* (`:265-271`) plus 2 more at `:227`; multiplying segment count by 5-15× multiplies those forks. | `_is_destructive_verb` glob matcher + glob pwsh test remove **all** per-segment forks (§9.3). Measure per NFR-1 before and after. |
| R4 | **PowerShell twin ships broken** — PS is agent-unexecutable, so symmetry is the only check (insight 2026-06-21). | The construct-avoidance list in §9.2 is binding; the operator PS run is appended to the standing T-13 list (AC-12); no PS baseline key is invented (OQ-4a). |
| R5 | **Monotonicity regression** — a decomposition that is *smarter* than the old one can turn a pre-change BLOCK into an ALLOW, and it already did once (the pwsh call site, F-2). | `P` contains `s` at every depth (§3.2), so no pre-change judgement is dropped. This is **not** self-evident: the proof obligation is the AC-4 differential run over the readable in-repo corpus, and any flip other than the AC-1 rows is fixed or recorded (OQ-6a). |
| R6 | **Self-block of the test harness** (AC-3 L11/L12): if `printf '…' \| bash guard-rm.sh` blocks, the suite cannot run. | The JSON payload is single-quoted → one `SQ` word, no positions inside (IS-4); the whole line's own verb is `printf` → ALLOW. Verified against the template copy first; the `[guard-path]` argument means the suite never depends on the live copy being correct. |
| R7 | **Driver rows that do not carry the command they claim.** The `\|` delimiter truncates `cmd` and pushes the residue into `expected` (loud FAIL, not silent green); a double-quoted row containing `$(` **executes** at array-definition time. | §6.2: stride-4 encoding + the single-quote mandate in both shells; QA confirms each new row's `cmd` echoes back intact in its PASS line. |
| R8 | **Fabricated tally** in `baseline.json` (2nd occurrence of this class, insight 2026-07-31). | The value is transcribed from the run that produced it; the delivery quotes the run, not the arithmetic. |
| R9 | **Doc-size cap.** `.harness/rules/75-safety-hook.md` is 137 lines against a 200-line WARN cap (`70-doc-size.md:25`). Coverage claim + residuals + accepted over-blocks can overrun it. | Budget ≤ 55 added lines (lands at ≤ 192); **replace** the "first token after optional `sudo`" header and the out-of-scope bullet rather than appending beside them (AC-9 requires the old sentence to be gone anyway). |
| R10 | **New over-blocks** on forms nobody enumerated. | OQ-6a governs: fix if realistic, else record in the rule doc's failure-mode table with rationale. §10.3 pre-declares the four known ones so QA is not surprised. |
| R11 | **PS scanner throws and the Windows guard silently disarms (fail-OPEN).** .NET string indexing / `Substring` **throw** on out-of-range where bash `${s:$i:1}` at `i == len` yields `""`, and the scanner is lookahead-heavy (`$((`, `$(`, `${`, `&&`, `<<`, `<<<`, `))`, `&>`). With `guard-rm.ps1:19` `$ErrorActionPreference = 'Stop'` an escaping terminating error exits **1**, which Claude Code treats as non-blocking. Symmetry review cannot detect it. | §9.2: every lookahead length-guarded, whole scanner wrapped in `try/catch` mapping any exception to the parse-fail path (exit 2). Listed as an explicit item for the operator PS run (AC-12). |

---

## 9. Migration / rollout plan

No data migration, no feature flag (a flag that disables the widened coverage would be a config
that weakens the guard — forbidden by NFR-5). Rollback = `git checkout` of the files in §11, or
re-running `sync-self` from a reverted template. Distribution: user projects receive the new guard
through the template copy on their next `/harness-adopt` / `/harness-upgrade`; existing installs
keep the old guard until then. The guard reads and writes no state, so no compatibility shim.

### 9.1 Edit sequence (NFR-3: the guard is LIVE this session)

The template copy is **not** wired to any hook, so it is a free staging area; the repo copy is only
ever written by one `cp` inside `sync-self`. Every numbered step leaves the repo copy valid.

| # | Action | Tool | Re-run after |
|---|---|---|---|
| 0 | Capture the pre-change tally: `bash .harness/scripts/test-guard-rm.sh` | Bash | — (this **is** the capture) |
| 1 | `test-guard-rm.sh`: stride-4 rows + quoting rule + `[guard-path]` arg + newline escaping (§6.2, §6.1). No guard touched. | Edit | run it → tally must still equal step 0 |
| 2 | Same for `test-guard-rm.ps1` (`-Guard` param). | Edit | — (PS unexecutable) |
| 3 | Full change to `skills/harness-init/templates/common/.harness/scripts/guard-rm.sh`. | Write/Edit | `bash -n <template>` **must pass before anything else** |
| 4 | Add the AC-1 / AC-3 / AC-5 rows to `evals/guard-rm-cases.md` + both drivers. | Edit | `bash .harness/scripts/test-guard-rm.sh <template-path>` → all rows green; the same command against the **repo** copy is expected red on the new rows (anti-revert evidence, AC-10) |
| 5 | **Promote:** `bash .harness/scripts/sync-self.sh --check` **first** → confirm the drift list names **only** `.harness/scripts/guard-rm.sh` / `.ps1`; then `bash .harness/scripts/sync-self.sh` | Bash | `bash .harness/scripts/test-guard-rm.sh` (default path) → **quote** the captured tally, never derive it |
| 6 | AC-10 mutation: copy the promoted guard to a scratch path, delete the scanner call, run the driver against the scratch copy → AC-1 rows red. | Bash | — |
| 7 | AC-4 differential: run the driver's `[guard-path]` against a scratch copy of the **pre-change** guard and against the live one over the corpus; diff verdicts. | Bash | — |
| 8 | PS twin in the template + `sync-self` again. | Write/Edit, Bash | `sync-self.sh --check` → "In sync." |
| 9 | Docs: `75-safety-hook.md` + `.tmpl`, `baseline.json`, `CHANGELOG.md`, `docs/dev-map.md:102` if its wording narrows. | Edit | `bash .harness/scripts/verify_all.sh` → **32 checks**, PASS |

Two sequencing facts the developer must hold (gate §5, Q4):

- **`sync-self.sh` promotes all nine mappings** (`sync-self.sh:62-93`), not just guard-rm — hence
  the `--check`-first condition in step 5 (C-6). Any other drifted pair must be resolved or
  understood *before* the promote.
- **`bash -n` catches syntax errors only.** A *runtime* error under `set -uo pipefail`
  (`guard-rm.sh:19`) exits **1**, and Claude Code treats non-2 as non-blocking — a runtime bug
  therefore fails **open** and is invisible to the syntax check. The post-promotion driver run
  (step 5) is the only thing that catches it. A row whose actual verdict prints as
  `UNKNOWN(exit=1)` (`test-guard-rm.sh:76`) is that symptom.

If step 5 ever leaves the repo copy unrunnable, **every** Bash call returns exit 2. Recovery is
exclusively: `Read` the template copy → `Write` `.harness/scripts/guard-rm.sh` with that content.
Do not attempt any Bash-based recovery.

### 9.2 Cross-shell symmetry — binding constraints for `guard-rm.ps1`

PowerShell parses the **whole file** before executing, so a syntax error in a never-taken branch is
fatal (insight 2026-06-21). The PS twin is green-by-symmetry only. The developer must:

- **Length-guard every lookahead and wrap the scanner in `try/catch` (R11, C-7).** `$s[$i+1]` and
  `$s.Substring($i, 2)` throw when the index runs past the end; bash's `${s:$i:1}` returns `""`.
  Every multi-character test (`$((`, `$(`, `${`, `&&`, `&>`, `<<`, `<<<`, `))`) must be written
  `if ($i + k -lt $s.Length -and …)`. The whole function body is additionally wrapped in
  `try { … } catch { return $null }` — an escaping terminating error exits 1 and **disarms the
  guard**, so this is a security requirement, not hygiene.
- **One failure channel.** `Split-CommandPositions` returns `$null` on parse failure (mirroring
  `Get-Tokens`, `guard-rm.ps1:94`); its caller `Get-OffendingFromCommandString` converts that
  `$null` into the existing `,@('__PARSE_FAIL__')` return (`guard-rm.ps1:174,178`). No new
  mechanism, and the two signals named in round 1 are now one internal convention plus one
  external channel (F-6).
- **Never** name a variable/parameter `$isWindows`, `$input`, `$args`, `$error`, `$matches`,
  `$host`, `$home`, `$pwd`, `$this`, `$profile`, `$switch`, `$foreach`, `$sender` — automatic
  variables collide case-insensitively and throw on first call. Suggested: `$posList`, `$nestKind`,
  `$hdQueue`, `$stIn`, `$prevCh`, `$sqAnsi`.
- **Never**: build a literal containing `\"` by double-quote concatenation (use `'…'` with doubled
  inner `'`, or `'…{0}…' -f $x`); put `-join` next to `+` (binds below `+`, insight 2026-07-31);
  use `-split "…", -1` (insight 2026-06-08 — use `.Split()`); use `Out-String` for diagnostics or
  `Sort-Object -Unique` (case-insensitive, diverges from `sort -u`).
- Use `-ceq` / `StartsWith(…, [StringComparison]::Ordinal)` for the override prefix (PS `-eq` is
  case-insensitive → would widen the override); keep `-ieq` for destructive- and interpreter-verb
  matching. Return arrays as `,$list.ToArray()`. Prefer explicit `if/elseif` character comparisons
  over `switch`/regex in the scanner: fewer escaping hazards, and every branch parses.

### 9.3 Latency (NFR-1)

**Algorithmic shape, mandatory:** one pass over the string per decomposition, character-indexed,
**zero forks inside any per-character or per-token loop**. The new code must contain no `$( … )`,
no pipe and no external command anywhere inside `split_positions`, `_skip_prefix`,
`_is_destructive_verb` or the carrier scan.

**The real bottleneck is pre-existing and this change multiplies it** (profile the mechanism, not
the named suspect — insight 2026-06-09). `guard-rm.sh:265-271` forks `printf | tr` once per verb
per segment (9 verbs × 2 = 18) and `:227` forks twice more — ~20 forks/segment today; raising the
segment count from 1-2 to 5-15 would mean 100-300 forks per Bash tool call. `_is_destructive_verb`'s
glob list and the glob pwsh test remove all of them. `resolve_leaf` keeps its `$( )` call site
(byte-unchanged, AC-2) — reached only for path tokens of an actually-destructive verb.

**Constraint:** `guard-rm.sh` today uses **no bash-4-only construct** (no `mapfile`, no `${v,,}`,
no associative array). The hook runs `bash`, which on macOS is 3.2 — a bash-4 construct would be a
whole-file parse error, i.e. R2. Hence the glob verb matcher and the linear-scan dedup.

**Measure and record:** (a) a typical ~120-char command; (b) an 8192-char worst case (~400
`echo a && ` repetitions + a trailing in-project `rm -rf ./build`); (c) an 8192-char here-doc
payload. 20 timed `printf … | bash <guard>` invocations each, against the **pre-change guard
extracted to a scratch path** and the post-change guard on the same host, in per-invocation ms. If
the figures contradict the 50 ms claim in `.harness/rules/75-safety-hook.md:58-62`, correct the
rule document to the measured truth (NFR-1), not the reverse.

---

## 10. Out-of-scope clarifications and residual surface

### 10.1 Design boundaries (not covered by this design)

Verb-set widening (`mv`, `cp`, `>`, `truncate`, `dd`, `git clean`); verb-spelling normalization;
cwd simulation; indirection resolution; a new `verify_all` check; the other two pool rows;
`docs/proposals/frontier-gaps-2026-07.md`; reconciliation of the frozen PowerShell items.

### 10.2 Residual bypass surface — the honest list

Publish this list in `.harness/rules/75-safety-hook.md` (IS-8 / AC-9, ≤ 55 added lines per R9). A
guard that overstates its coverage is worse than one that names its edges.

1. **Path-qualified / escape-spelled verbs** — `/bin/rm`, `\rm`, `command rm` via `$(which rm)`.
   Not covered (IS-1 row 16, OQ-3a). `'rm'` / `"rm"` **are** covered (`tokenize()` strips quotes).
2. **Indirection** — `eval "$X"`, `$CMD -rf OUT`, aliases, shell functions, `./script.sh`,
   `bash script.sh`, a Makefile target. Structurally out of reach for a text-only guard (row 15).
3. **`cd` is not modelled** — `cd /tmp && rm -rf ./x` is now *evaluated*, and `./x` resolves against
   the guard's own cwd, so it judges in-project (row 17, OQ-2a).
4. **Variable expansion in paths** — `rm -rf $HOME/x` resolves the literal token relative to cwd and
   judges in-project. Pre-existing (`resolve_leaf` expands `~` only, `:154-156`); **newly documented.**
5. **Command substitution as a path argument** — `rm -rf $(cat list)`: the inner command is judged
   as its own position, the *target* is not resolvable. Class 2.
6. **Beyond 8192 characters** — content past truncation is unjudged (B-2); if truncation severs a
   here-doc terminator the verdict is BLOCK, not skip.
7. **Non-Claude-Code writers** — `PreToolUse` governs only Claude Code's Bash tool; Write/Edit,
   other agents and other IDEs are unaffected (also the deliberate repair path, §9.1).
8. **The deliberate fail-open**: no `.git/` ancestor → WARN + exit 0 (B-6), unchanged.
9. **The override authorizes the whole line, not one position (F-12).** A leading
   `HARNESS_ALLOW_OUTSIDE_RM=1` exits 0 before any parsing, so *every* chained position after it is
   allowed too — `HARNESS_ALLOW_OUTSIDE_RM=1 rm -rf A && rm -rf B` allows both. Identical to today
   and to the env-var form, therefore monotonic; but now that the guard is chain-aware everywhere
   else, the override is the one place that is not, and the list must say so. It remains the single
   visible escape hatch (NFR-5), now audited instead of silent (E-1).
10. **The PowerShell twin is unverified by agents** — green-by-symmetry only until an operator run
    (AC-12); R11 is its highest-probability failure.
11. **The union retains the pre-change pass in full, so the scanner narrows nothing (F-4).** Every
    pre-change parse failure and every pre-change `|`-split survives unchanged, however well the new
    scanner understands the line: `split_pipes` and `tokenize` are byte-unchanged and have no
    backslash, comment or here-doc awareness. Consequences — all pre-existing, all over-blocking
    rather than under-blocking:
    - a here-doc **body** is not position-free under the union: the pre-change pass splits the
      *whole command string* on `|`, so a body line containing `|` (any markdown table written via
      `cat > f <<'EOF'`, routine in this repo) yields body-derived positions. They ALLOW unless the
      body text itself parses as a destructive command with an outside path — a body line
      `| rm -rf /etc/x |` BLOCKs;
    - an odd `'` or `"` anywhere — including inside a here-doc body or a comment — still fails
      `tokenize()` and BLOCKs (`guard-rm.sh:114`); AC-3 L10 is **one instance of this class**, not a
      special case (§10.3);
    - therefore the post-change over-block surface is a **superset** of today's. Correct posture for
      a fail-closed guard, but it must be stated rather than implied — stopping the coverage claim
      from overstating is what this task exists for.

### 10.3 Pre-declared over-blocks (OQ-6a: captured, then recorded in the rule doc)

- **Pre-change parse failures (the class in item 11), of which AC-3 L10 is the named instance.**
  L10 **already** BLOCKs today: the body's lone `'` leaves `tokenize()` unbalanced → `parse_failed`.
  The union retains that pass, so the verdict stays BLOCK. AC-3's table header ("exit 0 for every
  row") contradicts IS-2 for this row; the requirement-analyst is correcting the header, and this
  design's position is unchanged: **L10 is expected to BLOCK, identically to pre-change**, recorded
  in the rule doc's failure-mode table with the override as the workaround. A follow-up pool row may
  relax the pre-change pass's parse failures once here-doc awareness has field evidence.
- **A whole line containing a top-level `|` whose leading verb is destructive or a carrier, and
  whose later pipe stage names an absolute outside path** — e.g. `rm -rf ./build | tee /tmp/x.log`
  now BLOCKs (pre-change: ALLOW). This is the price of the C-1 invariant: `P` contains `s` itself
  at depth 0 too, so `rm`'s token walk crosses the `|` and reaches `/tmp/x.log`. Accepted rather
  than special-cased, because a depth-conditional rule would be one more thing to get wrong and its
  failure direction is **open**; the same whole-string walk is what today's guard already does
  inside `pwsh -c` strings. Narrow in practice: relative tokens after the `|` resolve in-project and
  are harmless, so only an *absolute* outside path triggers it.
- **Nesting deeper than 2** — `echo "$(basename "$(dirname "$(pwd)")")"` BLOCKs. Mandated by B-5 /
  IS-1 row 4; realistic but rare. Workaround: split the line or use the override. Candidate
  follow-up: raise the bound for the *iterative* scanner (its stack has no recursion cost) while
  keeping depth 2 for interpreter re-parses.
- **Unbalanced or unterminated structure** — `echo :-(` (unclosed frame at end of input),
  `cat <<EOF` with no body in the string. Mandated by IS-1 row 18 / IS-3.

**ANSI-C quoting is fixed, not recorded (F-9).** `$'it\'s'` would BLOCK under the round-1 table
(`\` × SQ = literal → the escaped quote closes SQ → string ends in SQ → parse failure): a new
ALLOW→BLOCK flip. Resolved per OQ-6a's "fix it if it is a form a developer would realistically
type" — the `sq_ansi` flag (§3.1 rows 1-2) makes `\` inside `$'…'` consume the next character, as
bash does. Cost: one bit and one branch per shell. Recording it instead would have cost a rule-doc
line *and* left a live over-block on `git commit -m $'don\'t …'`. Evidence: a driver row
`echo $'it\'s fine'` → ALLOW, in both drivers and in `evals/guard-rm-cases.md` (§6.2's single-quote
rule applies to the row itself). If the flag is ever wrong the failure direction is a parse failure
→ BLOCK, i.e. fail-closed.

---

## 11. Lockstep ledger — every fan-out surface

| # | Surface | Mirroring | What changes |
|---|---|---|---|
| 1 | `skills/harness-init/templates/common/.harness/scripts/guard-rm.sh` | **source** of sync-self Mapping 5 (`sync-self.sh:76`) | the whole change — **edit here** |
| 2 | `.harness/scripts/guard-rm.sh` | byte-mirrored **dest** | written by `sync-self` only; never hand-edited |
| 3 | `skills/harness-init/templates/common/.harness/scripts/guard-rm.ps1` | **source**, Mapping 5 (`:75`) | symmetric change |
| 4 | `.harness/scripts/guard-rm.ps1` | byte-mirrored **dest** | written by `sync-self` only |
| 5 | `.harness/scripts/test-guard-rm.sh` | hand-maintained, not in sync-self | stride-4 rows + quoting rule, `[guard-path]` arg, newline escaping, new rows |
| 6 | `.harness/scripts/test-guard-rm.ps1` | hand-maintained twin | `-Guard` param, new rows (same ids), same quoting rule |
| 7 | `evals/guard-rm-cases.md` | hand-maintained fixture, dogfood-only | one row per driver case, both directions (IS-7) |
| 8 | `.harness/rules/75-safety-hook.md` | hand-maintained (`.harness/rules/` is **not** in sync-self's mirror set — `AI-GUIDE.md:76`) | coverage claim replaces "first token after optional `sudo`"; chaining removed from out-of-scope; residuals §10.2 **including items 9 and 11**; over-blocks §10.3; failure-mode rows; ≤ 55 added lines (R9, C-9) |
| 9 | `skills/harness-init/templates/common/.harness/rules/75-safety-hook.md.tmpl` | hand-maintained twin | same edits, minus the two dogfood-note blocks the repo copy carries at `:10-22`, `:96-110` |
| 10 | `.harness/scripts/baseline.json` | ledger | `test_guard_rm_bash_assertions` (captured); PS key deliberately absent, noted in prose |
| 11 | `CONTEXT.md` | glossary | **Already done — do NOT re-add (C-8).** `Command position` is at `CONTEXT.md:100-102`, added during round 1 of this stage |
| 12 | `CHANGELOG.md` + `plugin.json` version | release convention | one entry; verify_all's release checks stay green |
| 13 | `docs/dev-map.md:102,106` | prose | only if the one-line guard description becomes narrower than the truth |
| 14 | `docs/tasks.md`, `docs/batches/default/BATCH_PLAN.md` | PM-owned | status rows |

**Verified NOT to change** (grepped, independently re-confirmed by the gate reviewer — do not
touch): `.harness/scripts/verify_all.{sh,ps1}` (F.2 is presence + wiring only,
`verify_all.sh:290-334`); `.harness/scripts/test-init.{sh,ps1}` (guard presence/wiring only,
`:279-280`, `:287-336` — assertion counts frozen); `.harness/scripts/hook-spec.{sh,ps1}`;
`.claude/settings.local.json`; `skills/harness-{init,adopt,batch,stream,status}/SKILL.md`;
`README.md` / `README.zh-CN.md`; `AI-GUIDE.md:33`; `.harness/scripts/migrate-scripts-layout.*`,
`upgrade-project.*`, `entropy-cadence.*`, `install-hooks.*`, `test-real-project.*`,
`test-harness-upgrade.*`, `MIGRATION.md`, `.harness/rules/40-locations.md`,
`.harness/rules/15-skill-authoring.md`; `docs/proposals/frontier-gaps-2026-07.md` (**forbidden**).

`.harness/rejected-decisions.md` was read: no record touches the guard's parsing scope
(`skills-git-guardrails-setup-pre-commit` declines *adopting upstream guard skills*, which does not
bear on fixing this guard). Round 2 declines one approach — a depth-conditional whole-string rule
(§10.3, bullet 2) — but it is a design-internal alternative rejected inline with its reason, not a
proposal-level decision, so no record is appended.

---

## 12. Verdict

**READY.**

The design covers IS-1 rows 1-19 as a total contract; the scanner's state table is total in all
five states with no exception clauses (F-1, F-8); the verb set and the path resolver stay
byte-unchanged (AC-2/AC-5/AC-6); no dependency and no gate check are added (NFR-2, AC-8 — 32 held);
and the edit sequence keeps the live guard valid after every individual step (NFR-3).

Two round-1 claims are **withdrawn**: IS-2 is *not* provable by inspection (the anchor is now "`P`
contains `s` at every depth", proved by the AC-4 differential run — §3.2, R5), and a here-doc body
is *not* structurally position-free under the union (§10.2 item 11). Four over-block classes are
pre-declared for QA (§10.3), one previously unenumerated over-block is fixed outright (ANSI-C
quoting), and the branch ordering that broke either AC-1 row o or fixture rows 9/17 is pinned
(§3.4, §6).

No `BLOCKED: NEEDS-HUMAN` marker: every open point is either PM-resolved upstream or a reversible,
fail-closed implementation trade-off inside Mode 2's rubric coverage.
