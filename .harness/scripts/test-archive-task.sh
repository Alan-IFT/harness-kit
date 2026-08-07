#!/usr/bin/env bash
# test-archive-task.sh — Drive archive-task.sh's INSIGHT-SCAN harvester (T-20).
#
#   bash .harness/scripts/test-archive-task.sh [archive-task-path]
#
# [archive-task-path] defaults to $repo_root/.harness/scripts/archive-task.sh.
# Pass an alternate path to drive a staged template copy or a git-extracted
# pre-change script. Every case runs against a FRESH sandbox repo root under
# mktemp -d with the script under test copied into its .harness/scripts/ —
# archive-task derives its repo root two levels up from its own location, so a
# copy is mandatory. No case writes anywhere under the real repository; the
# archived corpus (AC-15) is read read-only and classified in a sandbox.
#
# Out-of-scope for verify_all (like every other test-* driver). Use arr=() not
# declare -a per insight 2026-05-16. NOTE this driver runs `set -uo pipefail`
# with NO -e, so `n=$((n+1))` style is a convention here, not a survival rule —
# in archive-task.sh itself (`set -euo pipefail`) it IS a survival rule.
set -uo pipefail

# Script lives at .harness/scripts/ — repo root is two levels up.
repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
archive="${1:-$repo_root/.harness/scripts/archive-task.sh}"
verify_all="$repo_root/.harness/scripts/verify_all.sh"
tmpl_index="$repo_root/skills/harness-init/templates/common/.harness/insight-index.md.tmpl"
cd "$repo_root"

if [[ ! -f "$archive" ]]; then
    echo "test-archive-task: archive-task not found: $archive" >&2
    exit 1
fi
echo "  archive-task under test: $archive"

pass=0
fail=0
failures=()
SANDBOXES=()
SB=""
AT_OUT=""
AT_ERR=""
AT_EXIT=0

cleanup() {
    local d
    for d in "${SANDBOXES[@]}"; do
        [[ -n "$d" && -d "$d" ]] && rm -rf "$d"
    done
}
trap cleanup EXIT

# --- assertion helpers -----------------------------------------------------
ok()  { printf '  PASS  %s\n' "$1"; pass=$((pass+1)); }
no()  { printf '  FAIL  %s\n        %s\n' "$1" "$2" >&2; fail=$((fail+1)); failures+=("$1"); }
eq()  { if [[ "$2" == "$3" ]]; then ok "$1"; else no "$1" "expected [$2] got [$3]"; fi; }
has() { if [[ "$3" == *"$2"* ]]; then ok "$1"; else no "$1" "missing [$2]"; fi; }
hasnot() { if [[ "$3" != *"$2"* ]]; then ok "$1"; else no "$1" "unexpected [$2] present"; fi; }
files_eq() {
    if cmp -s "$2" "$3"; then ok "$1"; else no "$1" "$(diff "$2" "$3" 2>&1 | head -6)"; fi
}

banner() { printf '\n--- %s\n' "$1"; }

# --- sandbox helpers -------------------------------------------------------
new_sandbox() {
    SB=$(mktemp -d "${TMPDIR:-/tmp}/test-archive-task.XXXXXXXX")
    SANDBOXES+=("$SB")
    mkdir -p "$SB/.harness/scripts" "$SB/docs/features/_archived"
    cp "$archive" "$SB/.harness/scripts/archive-task.sh"
}

# use_script <path> — swap the script the sandbox will run (AC-4 pre-change).
use_script() { cp "$1" "$SB/.harness/scripts/archive-task.sh"; }

run_at() {
    bash "$SB/.harness/scripts/archive-task.sh" "$@" >"$SB/.out" 2>"$SB/.err"
    AT_EXIT=$?
    AT_OUT=$(cat "$SB/.out")
    AT_ERR=$(cat "$SB/.err")
}

sec_line() { echo "$AT_OUT" | grep '^Insight tally:' || true; }
idx_line() { echo "$AT_OUT" | grep '^Index tally:' || true; }

# K-61 raw-marker oracle — the PRE-CHANGE quantity, computed by GNU grep (BRE),
# never by a shipped check. Equal to INSIGHT-SCAN's entry count on every index
# whose header block holds no entry-start-shaped line.
raw_markers() { grep -c '^[[:space:]]*-[[:space:]]' "$1" 2>/dev/null || true; }

mtime_of() { stat -c '%y' "$1" 2>/dev/null || echo "no-stat"; }

# Run verify_all in a sandbox and echo its [I.4] line plus the detail line that
# follows it (every other check is ignored on purpose — the sandbox is not a
# repo and most of them fail). NOTE this host's `grep` is ugrep 7.5.0, so every
# pattern in this driver stays inside POSIX bracket expressions (insight L31).
i4_line() {
    local root="$1"
    mkdir -p "$root/.harness/scripts"
    cp "$verify_all" "$root/.harness/scripts/verify_all.sh"
    bash "$root/.harness/scripts/verify_all.sh" 2>/dev/null | grep -A1 '^\[I\.4\]' || true
}

# The [I.4] STATUS line alone, out of an i4_line() capture. A verdict row must
# anchor here and never on the two-line window: on a PASS the -A1 slot holds the
# NEXT check's line, which carries its own PASS token, so `has … PASS <window>`
# would be green whatever [I.4] said. Only the DETAIL rows want the window,
# because bash's step() renders a WARN detail on the following line (D-4).
i4_head() { echo "$1" | grep '^\[I\.4\]' || true; }

# =========================================================================
banner "AC-1 / B-2 — a wrapped entry is harvested whole"
new_sandbox
mkdir -p "$SB/docs/features/wrapped"
cat > "$SB/.harness/insight-index.md" <<'EOF'
# Insight Index — fixture

- 2026-01-01 · stored one
EOF
cat > "$SB/docs/features/wrapped/07_DELIVERY.md" <<'EOF'
# 07 — Delivery

## Insight

- 2026-02-01 · first fact that wraps
  onto a second physical line · evidence: file.sh:12
- 2026-02-01 · second fact

## Verdict
EOF
cat > "$SB/expected-index" <<'EOF'
# Insight Index — fixture

- 2026-01-01 · stored one
- 2026-02-01 · first fact that wraps
  onto a second physical line · evidence: file.sh:12
- 2026-02-01 · second fact
EOF
run_at --task wrapped
eq "AC-1 exit status" "0" "$AT_EXIT"
eq "AC-1 section tally" \
   "Insight tally: entries 2, continuation lines 1, ignorable lines 2 (terminal footer 0), unaccounted lines 0" \
   "$(sec_line)"
eq "AC-1 index tally" "Index tally: entries 1, unaccounted lines 0, entries after run 3" "$(idx_line)"
files_eq "AC-1 index bytes equal the expected content" "$SB/expected-index" "$SB/.harness/insight-index.md"
has "AC-1 evidence pointer survives on the continuation line" \
    "  onto a second physical line · evidence: file.sh:12" "$(cat "$SB/.harness/insight-index.md")"
has "AC-1 echo reprints the continuation line" "  onto a second physical line" "$AT_OUT"

# =========================================================================
banner "AC-2 / B-4 / BC-5 — an unaccounted delivery line refuses before any write"
new_sandbox
mkdir -p "$SB/docs/features/unacc"
cat > "$SB/.harness/insight-index.md" <<'EOF'
# Insight Index — fixture

- 2026-01-01 · stored one
EOF
cat > "$SB/docs/features/_archived/insight-history.md" <<'EOF'
# Insight history (rotated from .harness/insight-index.md)
EOF
cat > "$SB/docs/features/unacc/07_DELIVERY.md" <<'EOF'
# 07 — Delivery

## Insight

- 2026-02-01 · a fact

Trailing prose that no rule accounts for.

## Verdict
EOF
cp "$SB/.harness/insight-index.md" "$SB/index.before"
cp "$SB/docs/features/_archived/insight-history.md" "$SB/history.before"
idx_mtime_before=$(mtime_of "$SB/.harness/insight-index.md")
hist_mtime_before=$(mtime_of "$SB/docs/features/_archived/insight-history.md")
run_at --task unacc
eq "AC-2 exit status is 3" "3" "$AT_EXIT"
has "AC-2 diagnostic names document, 1-based line and text" \
    "07_DELIVERY.md:7: unaccounted line: Trailing prose that no rule accounts for." "$AT_ERR"
eq "AC-2 tally still printed on the refusal path" \
   "Insight tally: entries 1, continuation lines 0, ignorable lines 3 (terminal footer 0), unaccounted lines 1" \
   "$(sec_line)"
files_eq "AC-2 index byte-identical" "$SB/index.before" "$SB/.harness/insight-index.md"
files_eq "AC-2 history byte-identical" "$SB/history.before" "$SB/docs/features/_archived/insight-history.md"
eq "AC-2 index mtime unmoved" "$idx_mtime_before" "$(mtime_of "$SB/.harness/insight-index.md")"
eq "AC-2 history mtime unmoved" "$hist_mtime_before" "$(mtime_of "$SB/docs/features/_archived/insight-history.md")"
if [[ -d "$SB/docs/features/unacc" && ! -d "$SB/docs/features/_archived/unacc" ]]; then
    ok "AC-2 task directory not moved"
else
    no "AC-2 task directory not moved" "task dir state changed"
fi

# =========================================================================
banner "BC-6 — a blank line inside an authored bullet terminates the entry"
new_sandbox
mkdir -p "$SB/docs/features/bc6"
printf '# Insight Index — fixture\n' > "$SB/.harness/insight-index.md"
cat > "$SB/docs/features/bc6/07_DELIVERY.md" <<'EOF'
# 07 — Delivery

## Insight

- 2026-02-01 · a fact

  indented continuation after a blank

## Verdict
EOF
run_at --task bc6
eq "BC-6 exit status is 3" "3" "$AT_EXIT"
has "BC-6 diagnostic names the orphaned line" \
    ":7: unaccounted line:   indented continuation after a blank" "$AT_ERR"
eq "BC-6 tally" \
   "Insight tally: entries 1, continuation lines 0, ignorable lines 3 (terminal footer 0), unaccounted lines 1" \
   "$(sec_line)"

# =========================================================================
banner "AC-13 / BC-21 / X-5 — break then entry, DELIVERY (discriminating fixture)"
new_sandbox
mkdir -p "$SB/docs/features/ac13"
printf '# Insight Index — fixture\n' > "$SB/.harness/insight-index.md"
cat > "$SB/docs/features/ac13/07_DELIVERY.md" <<'EOF'
# 07 — Delivery

## Insight

- 2026-02-01 · first fact

---

- 2026-02-01 · second fact
  its continuation · evidence: x:1

## Verdict
EOF
cp "$SB/.harness/insight-index.md" "$SB/index.before"
run_at --task ac13
eq "AC-13 exit status is 3" "3" "$AT_EXIT"
has "AC-13 diagnostic names the --- line's 1-based number and text" \
    ":7: unaccounted line: ---" "$AT_ERR"
# The rejected reading (every line after a thematic break is ignorable) exits 0,
# drops both post-break lines and reports entries 1 / continuation 0.
eq "AC-13 tally reports the post-break entry-start line and its continuation as CONTENT" \
   "Insight tally: entries 2, continuation lines 1, ignorable lines 4 (terminal footer 0), unaccounted lines 1" \
   "$(sec_line)"
files_eq "AC-13 index byte-identical" "$SB/index.before" "$SB/.harness/insight-index.md"
if [[ ! -f "$SB/docs/features/_archived/insight-history.md" ]]; then
    ok "AC-13 history not created"
else
    no "AC-13 history not created" "insight-history.md exists"
fi
if [[ -d "$SB/docs/features/ac13" ]]; then ok "AC-13 task dir not moved"; else no "AC-13 task dir not moved" "moved"; fi

# =========================================================================
banner "AC-14 / BC-21 / X-5 — break then entry, INDEX (discriminating fixture)"
new_sandbox
mkdir -p "$SB/docs/features/ac14"
cat > "$SB/.harness/insight-index.md" <<'EOF'
# Insight Index — fixture

- 2026-01-01 · stored one

---

- 2026-01-01 · stored two
  its continuation · evidence: y:2
EOF
cat > "$SB/docs/features/ac14/07_DELIVERY.md" <<'EOF'
# 07 — Delivery

## Insight

- 2026-02-01 · a clean fact

## Verdict
EOF
cp "$SB/.harness/insight-index.md" "$SB/index.before"
run_at --task ac14
eq "AC-14 exit status is 3" "3" "$AT_EXIT"
has "AC-14 diagnostic names the index path and the --- line" \
    "insight-index.md:5: unaccounted line: ---" "$AT_ERR"
eq "AC-14 index tally (rejected reading would report entries 1)" \
   "Index tally: entries 2, unaccounted lines 1, entries after run 2" "$(idx_line)"
files_eq "AC-14 index byte-identical after the refusal" "$SB/index.before" "$SB/.harness/insight-index.md"
has "AC-14 post-break entry-start line still in the index" "- 2026-01-01 · stored two" "$(cat "$SB/.harness/insight-index.md")"
has "AC-14 post-break continuation still in the index" "  its continuation · evidence: y:2" "$(cat "$SB/.harness/insight-index.md")"
# K-61 oracle: raw markers == classified entries on this fixture (its header
# block holds no entry-start-shaped line). A rule that classified post-break
# lines as ignorable gives raw 2 / classified 1 and turns this row red.
ac14_classified=$(idx_line | sed -n 's/^Index tally: entries \([0-9]*\),.*/\1/p')
eq "AC-14 K-61 equality: raw markers == classified entries" \
   "raw=2 classified=2" "raw=$(raw_markers "$SB/.harness/insight-index.md") classified=$ac14_classified"
ac14_i4=$(i4_line "$SB")
has "AC-14 I.4 reports non-PASS over the fixture" "WARN" "$(i4_head "$ac14_i4")"
has "AC-14 I.4 names 2 entries and 1 unaccounted line at line 5" \
    "2 entries, 1 unaccounted line(s), first at line 5" "$ac14_i4"
# AC-3 leg (ii): archive-task's index entry count == I.4's entry count, both
# derived from one INSIGHT-SCAN over one file.
ac14_i4_entries=$(echo "$ac14_i4" | sed -n 's/^[[:space:]]*\([0-9]*\) entries,.*/\1/p')
eq "AC-3 agreement on the AC-14 fixture (archive-task == I.4)" \
   "$ac14_classified" "$ac14_i4_entries"

# =========================================================================
banner "AC-16 / BC-24 / B-19 — shipped-template header block, harvest AND rotation"
new_sandbox
mkdir -p "$SB/docs/features/ac16"
tmpl_lines=$(wc -l < "$tmpl_index")
cp "$tmpl_index" "$SB/.harness/insight-index.md"
for i in $(seq 1 30); do
    printf -- '- 2026-01-%02d · stored entry %d · evidence: t:%d\n' "$(( (i % 28) + 1 ))" "$i" "$i" >> "$SB/.harness/insight-index.md"
done
cat > "$SB/docs/features/ac16/07_DELIVERY.md" <<'EOF'
# 07 — Delivery

## Insight

- 2026-02-01 · new fact one
- 2026-02-01 · new fact two

## Verdict
EOF
# K-61's ONE designed inequality: the template's commented example bullet is an
# entry-start-shaped line inside the header block, so raw = entries + 1.
eq "AC-16 K-61 designed inequality raw == entries + 1 (31 vs 30)" "31" "$(raw_markers "$SB/.harness/insight-index.md")"
run_at --task ac16
eq "AC-16 exit status" "0" "$AT_EXIT"
eq "AC-16 index tally before rotation (0 entries from the header block)" \
   "Index tally: entries 30, unaccounted lines 0, entries after run 30" "$(idx_line)"
has "AC-16 rotation fired" "Rotating 2 old insight entry(ies)" "$AT_OUT"
head -n "$tmpl_lines" "$SB/.harness/insight-index.md" > "$SB/header.after"
files_eq "AC-16 header block byte-identical and still first" "$tmpl_index" "$SB/header.after"
has "AC-16 HTML comment still closed" "-->" "$(cat "$SB/header.after")"
eq "AC-16 history contains no '-->' line" "0" "$(grep -c -- '-->' "$SB/docs/features/_archived/insight-history.md" || true)"
eq "AC-16 history contains no header example line" "0" \
   "$(grep -cF -- '- YYYY-MM-DD · <one-sentence fact>' "$SB/docs/features/_archived/insight-history.md" || true)"
eq "AC-16 index holds 30 entries after the run" "30" \
   "$(( $(raw_markers "$SB/.harness/insight-index.md") - 1 ))"

# =========================================================================
banner "AC-15 / BC-20 — non-wedging floor over the real archived corpus (read-only)"
corpus_clean=0
corpus_dirty=0
corpus_footer=0
new_sandbox
corpus_sb="$SB"
for f in "$repo_root"/docs/features/_archived/*/07_DELIVERY.md; do
    [[ -f "$f" ]] || continue
    grep -qE '^##[[:space:]]+Insights?[[:space:]]*$' "$f" || continue
    rm -rf "$corpus_sb/docs/features/corpus"
    mkdir -p "$corpus_sb/docs/features/corpus"
    cp "$f" "$corpus_sb/docs/features/corpus/07_DELIVERY.md"
    printf '# Insight Index — fixture\n' > "$corpus_sb/.harness/insight-index.md"
    SB="$corpus_sb"
    run_at --task corpus --dry-run
    line=$(sec_line)
    # STRICT parse: an absent or garbled tally line is NOT a measurement. `${line##*x}`
    # on a string that does not contain x returns the string UNCHANGED, so an empty
    # tally line (which is exactly what the pre-change script produces — it prints no
    # tally at all) would otherwise read as a non-zero terminal footer and hand the
    # >= 3 floor row a spurious green against the very script it is meant to detect.
    u="none"
    ft="none"
    if [[ "$line" == *"unaccounted lines "* ]]; then u=${line##*unaccounted lines }; fi
    if [[ "$line" == *"terminal footer "* ]]; then
        ft=${line##*terminal footer }
        ft=${ft%%)*}
    fi
    if [[ "$AT_EXIT" == "0" && "$u" == "0" ]]; then
        corpus_clean=$((corpus_clean+1))
    else
        corpus_dirty=$((corpus_dirty+1))
        echo "        corpus non-zero: $f -> exit $AT_EXIT / $line" >&2
    fi
    if [[ "$ft" =~ ^[0-9]+$ ]]; then
        if (( ft > 0 )); then corpus_footer=$((corpus_footer+1)); fi
    fi
done
# AC-15's property is "no archived section wedges the harvester", so corpus_dirty
# == 0 is the HARD row. The other two are FLOORS, not equalities: the corpus grows
# by one section every time a task archives (this task's own stage-7 archive takes
# it to 35), and an exact count would go red on the next commit. The floors are the
# figures measured on the run that set baseline.json's 152: 34 clean / 3 footer.
# They still discriminate — corpus_clean sits EXACTLY on its floor, so any section
# that stops classifying cleanly moves it to 33 (a dirty section increments
# corpus_dirty instead), and a corpus that stops being enumerated at all reads 0.
if (( corpus_clean >= 34 )); then
    ok "AC-15 archived sections classified with 0 unaccounted lines (floor 34)"
else
    no "AC-15 archived sections classified with 0 unaccounted lines (floor 34)" "expected >= 34 got $corpus_clean"
fi
eq "AC-15 archived sections with an unaccounted line" "0" "$corpus_dirty"
if (( corpus_footer >= 3 )); then
    ok "AC-15 sections whose terminal-footer figure is non-zero (floor 3)"
else
    no "AC-15 sections whose terminal-footer figure is non-zero (floor 3)" "expected >= 3 got $corpus_footer"
fi

# =========================================================================
banner "BC-22 — a thematic break abutting an entry is a continuation"
new_sandbox
mkdir -p "$SB/docs/features/bc22"
printf '# Insight Index — fixture\n' > "$SB/.harness/insight-index.md"
cat > "$SB/docs/features/bc22/07_DELIVERY.md" <<'EOF'
# 07 — Delivery

## Insight

- 2026-02-01 · a fact
---

## Verdict
EOF
run_at --task bc22
eq "BC-22 exit status" "0" "$AT_EXIT"
eq "BC-22 tally: the break is a continuation, not a footer" \
   "Insight tally: entries 1, continuation lines 1, ignorable lines 2 (terminal footer 0), unaccounted lines 0" \
   "$(sec_line)"
eq "BC-22 break preserved verbatim as the entry's last index line" "---" "$(tail -n 1 "$SB/.harness/insight-index.md")"

# =========================================================================
banner "BC-3 / BC-4 — preamble shapes"
new_sandbox
mkdir -p "$SB/docs/features/bc3"
printf '# Insight Index — fixture\n' > "$SB/.harness/insight-index.md"
cp "$SB/.harness/insight-index.md" "$SB/index.before"
cat > "$SB/docs/features/bc3/07_DELIVERY.md" <<'EOF'
# 07 — Delivery

## Insight

Some prose but no bullet at all.

## Verdict
EOF
run_at --task bc3
eq "BC-3 exit status" "0" "$AT_EXIT"
eq "BC-3 tally: preamble-only yields 0 entries and 0 unaccounted" \
   "Insight tally: entries 0, continuation lines 0, ignorable lines 3 (terminal footer 0), unaccounted lines 0" \
   "$(sec_line)"
files_eq "BC-3 index not written" "$SB/index.before" "$SB/.harness/insight-index.md"

new_sandbox
mkdir -p "$SB/docs/features/bc4"
printf '# Insight Index — fixture\n' > "$SB/.harness/insight-index.md"
cat > "$SB/docs/features/bc4/07_DELIVERY.md" <<'EOF'
# 07 — Delivery

## Insight

Preamble prose describing the section.

- 2026-02-01 · a fact

## Verdict
EOF
run_at --task bc4
eq "BC-4 exit status" "0" "$AT_EXIT"
eq "BC-4 tally: preamble counted ignorable, entry harvested" \
   "Insight tally: entries 1, continuation lines 0, ignorable lines 4 (terminal footer 0), unaccounted lines 0" \
   "$(sec_line)"
has "BC-4 entry harvested" "- 2026-02-01 · a fact" "$(cat "$SB/.harness/insight-index.md")"
hasnot "BC-4 preamble not harvested" "Preamble prose" "$(cat "$SB/.harness/insight-index.md")"

# =========================================================================
banner "BC-7 — an entry-start marker in continuation position becomes its own entry"
new_sandbox
mkdir -p "$SB/docs/features/bc7"
printf '# Insight Index — fixture\n' > "$SB/.harness/insight-index.md"
cat > "$SB/docs/features/bc7/07_DELIVERY.md" <<'EOF'
# 07 — Delivery

## Insight

- 2026-02-01 · a fact
- continuation shaped like a marker

## Verdict
EOF
run_at --task bc7
eq "BC-7 exit status" "0" "$AT_EXIT"
eq "BC-7 tally reports 2 entries" \
   "Insight tally: entries 2, continuation lines 0, ignorable lines 2 (terminal footer 0), unaccounted lines 0" \
   "$(sec_line)"
eq "BC-7 K-61 equality over the post-run index (raw 2 == entries 2)" "2" "$(raw_markers "$SB/.harness/insight-index.md")"
eq "BC-7 archive-task reports the same index entry count" \
   "Index tally: entries 0, unaccounted lines 0, entries after run 2" "$(idx_line)"

# =========================================================================
banner "BC-8 — CRLF delivery document"
new_sandbox
mkdir -p "$SB/docs/features/bc8"
printf '# Insight Index — fixture\n' > "$SB/.harness/insight-index.md"
printf '# 07\r\n\r\n## Insight\r\n\r\n- 2026-02-01 · crlf fact\r\n  its continuation · evidence: c:1\r\n\r\n## Verdict\r\n' \
    > "$SB/docs/features/bc8/07_DELIVERY.md"
run_at --task bc8
eq "BC-8 exit status" "0" "$AT_EXIT"
eq "BC-8 no CR byte written into the index" "0" "$(grep -c $'\r' "$SB/.harness/insight-index.md" || true)"
has "BC-8 continuation harvested" "  its continuation · evidence: c:1" "$(cat "$SB/.harness/insight-index.md")"

# =========================================================================
banner "BC-9 — trailing whitespace stripped, leading whitespace preserved"
new_sandbox
mkdir -p "$SB/docs/features/bc9"
printf '# Insight Index — fixture\n' > "$SB/.harness/insight-index.md"
printf '# 07\n\n## Insight\n\n- 2026-02-01 · ws fact   \n    four-space indent kept\t\n\n## Verdict\n' \
    > "$SB/docs/features/bc9/07_DELIVERY.md"
run_at --task bc9
eq "BC-9 exit status" "0" "$AT_EXIT"
# POSIX bracket expression only: `[ \t]` is a tab to awk but {space, backslash,
# t} to GNU grep, and this host's grep is ugrep — insight L31, measured here.
eq "BC-9 no trailing whitespace in the written index" "0" \
   "$(grep -c '[[:space:]]$' "$SB/.harness/insight-index.md" || true)"
eq "BC-9 leading whitespace byte-preserved" "    four-space indent kept" "$(tail -n 1 "$SB/.harness/insight-index.md")"

# =========================================================================
banner "BC-12 / BC-13 — cap boundaries"
new_sandbox
mkdir -p "$SB/docs/features/bc12"
printf '# Insight Index — fixture\n' > "$SB/.harness/insight-index.md"
for i in $(seq 1 28); do printf -- '- stored %02d\n' "$i" >> "$SB/.harness/insight-index.md"; done
printf '# 07\n\n## Insight\n\n- new one\n- new two\n\n## Verdict\n' > "$SB/docs/features/bc12/07_DELIVERY.md"
run_at --task bc12
eq "BC-12 exit status" "0" "$AT_EXIT"
eq "BC-12 total exactly 30 -> no rotation" "Index tally: entries 28, unaccounted lines 0, entries after run 30" "$(idx_line)"
hasnot "BC-12 no rotation notice" "Rotating" "$AT_OUT"
if [[ ! -f "$SB/docs/features/_archived/insight-history.md" ]]; then
    ok "BC-12 history not created"
else
    no "BC-12 history not created" "insight-history.md exists"
fi

new_sandbox
mkdir -p "$SB/docs/features/bc13"
printf '# Insight Index — fixture\n' > "$SB/.harness/insight-index.md"
for i in $(seq 1 29); do printf -- '- stored %02d\n' "$i" >> "$SB/.harness/insight-index.md"; done
printf '# 07\n\n## Insight\n\n- new one\n- new two\n\n## Verdict\n' > "$SB/docs/features/bc13/07_DELIVERY.md"
run_at --task bc13
eq "BC-13 exit status" "0" "$AT_EXIT"
has "BC-13 exactly one entry rotated" "Rotating 1 old insight entry(ies)" "$AT_OUT"
eq "BC-13 index tally" "Index tally: entries 29, unaccounted lines 0, entries after run 30" "$(idx_line)"
has "BC-13 oldest entry rotated first" "- stored 01" "$(cat "$SB/docs/features/_archived/insight-history.md")"
hasnot "BC-13 rotated entry gone from the index" "- stored 01" "$(cat "$SB/.harness/insight-index.md")"
has "BC-13 second-oldest retained" "- stored 02" "$(cat "$SB/.harness/insight-index.md")"

# =========================================================================
banner "BC-14 — rotate count clamped to the stored entry count (no unbound-variable abort)"
new_sandbox
mkdir -p "$SB/docs/features/bc14"
printf '# Insight Index — fixture\n' > "$SB/.harness/insight-index.md"
printf -- '- stored 01\n- stored 02\n' >> "$SB/.harness/insight-index.md"
{
    printf '# 07\n\n## Insight\n\n'
    for i in $(seq 1 31); do printf -- '- new %02d\n' "$i"; done
    printf '\n## Verdict\n'
} > "$SB/docs/features/bc14/07_DELIVERY.md"
run_at --task bc14
eq "BC-14 exit status (completes, no abort)" "0" "$AT_EXIT"
hasnot "BC-14 no unbound-variable abort" "unbound variable" "$AT_ERR"
has "BC-14 every stored entry rotated (clamped to 2)" "Rotating 2 old insight entry(ies)" "$AT_OUT"
eq "BC-14 index holds the harvested entries" "Index tally: entries 2, unaccounted lines 0, entries after run 31" "$(idx_line)"
eq "BC-14 index entry count after the run" "31" "$(raw_markers "$SB/.harness/insight-index.md")"
has "BC-14 step 4 reached" "Archived task: bc14" "$AT_OUT"

# =========================================================================
banner "B-7 / B-8 / B-10 — a STORED wrapped entry rotates whole"
new_sandbox
mkdir -p "$SB/docs/features/stored"
cat > "$SB/.harness/insight-index.md" <<'EOF'
# Insight Index — fixture

<!-- Append new insights below, one per line. Format:
-->
- 2026-01-01 · stored wrapped entry
  its continuation line · evidence: s:1
EOF
for i in $(seq 2 30); do printf -- '- stored %02d\n' "$i" >> "$SB/.harness/insight-index.md"; done
head -n 4 "$SB/.harness/insight-index.md" > "$SB/header.before"
printf '# 07\n\n## Insight\n\n- new one\n\n## Verdict\n' > "$SB/docs/features/stored/07_DELIVERY.md"
run_at --task stored
eq "B-10 exit status" "0" "$AT_EXIT"
eq "B-10 stored wrapped entry counted as ONE entry" \
   "Index tally: entries 30, unaccounted lines 0, entries after run 30" "$(idx_line)"
has "B-7 rotated entry-start line in history" "- 2026-01-01 · stored wrapped entry" "$(cat "$SB/docs/features/_archived/insight-history.md")"
has "B-7 rotated CONTINUATION line in history" "  its continuation line · evidence: s:1" "$(cat "$SB/docs/features/_archived/insight-history.md")"
hasnot "B-7 rotated entry-start line gone from the index" "stored wrapped entry" "$(cat "$SB/.harness/insight-index.md")"
hasnot "B-7 rotated continuation gone from the index" "its continuation line" "$(cat "$SB/.harness/insight-index.md")"
head -n 4 "$SB/.harness/insight-index.md" > "$SB/header.after"
files_eq "B-8 header block byte-identical and still first" "$SB/header.before" "$SB/header.after"

# =========================================================================
banner "K-16 — an unaccounted line in the INDEX refuses before any write"
new_sandbox
mkdir -p "$SB/docs/features/k16"
cat > "$SB/.harness/insight-index.md" <<'EOF'
# Insight Index — fixture

- 2026-01-01 · stored one
stray prose that follows an entry without a blank line is a continuation

not this one though
EOF
printf '# 07\n\n## Insight\n\n- new one\n\n## Verdict\n' > "$SB/docs/features/k16/07_DELIVERY.md"
cp "$SB/.harness/insight-index.md" "$SB/index.before"
run_at --task k16
eq "K-16 exit status is 3" "3" "$AT_EXIT"
has "K-16 diagnostic names the index path" "insight-index.md:6: unaccounted line: not this one though" "$AT_ERR"
files_eq "K-16 index byte-identical" "$SB/index.before" "$SB/.harness/insight-index.md"
if [[ -d "$SB/docs/features/k16" ]]; then ok "K-16 task dir not moved"; else no "K-16 task dir not moved" "moved"; fi

# =========================================================================
banner "X-8 — a ## / ### heading line, in BOTH modes, is UNACCOUNTED (never a continuation)"
new_sandbox
mkdir -p "$SB/docs/features/x8s"
printf '# Insight Index — fixture\n' > "$SB/.harness/insight-index.md"
cat > "$SB/docs/features/x8s/07_DELIVERY.md" <<'EOF'
# 07 — Delivery

## Insight

- 2026-02-01 · a fact
### Subheading inside the section

## Verdict
EOF
cp "$SB/.harness/insight-index.md" "$SB/index.before"
run_at --task x8s
eq "X-8 section: exit status is 3" "3" "$AT_EXIT"
has "X-8 section: diagnostic names the ### line's 1-based number and text" \
    ":6: unaccounted line: ### Subheading inside the section" "$AT_ERR"
eq "X-8 section: the heading is UNACCOUNTED, not a continuation" \
   "Insight tally: entries 1, continuation lines 0, ignorable lines 2 (terminal footer 0), unaccounted lines 1" \
   "$(sec_line)"
files_eq "X-8 section: index byte-identical" "$SB/index.before" "$SB/.harness/insight-index.md"

new_sandbox
mkdir -p "$SB/docs/features/x8i"
cat > "$SB/.harness/insight-index.md" <<'EOF'
# Insight Index — fixture

- 2026-01-01 · stored one
## Stray heading in the index
EOF
printf '# 07\n\n## Insight\n\n- new one\n\n## Verdict\n' > "$SB/docs/features/x8i/07_DELIVERY.md"
cp "$SB/.harness/insight-index.md" "$SB/index.before"
run_at --task x8i
eq "X-8 index: exit status is 3" "3" "$AT_EXIT"
has "X-8 index: diagnostic names the index path and the ## line" \
    "insight-index.md:4: unaccounted line: ## Stray heading in the index" "$AT_ERR"
eq "X-8 index: the heading is UNACCOUNTED, not a continuation" \
   "Index tally: entries 1, unaccounted lines 1, entries after run 1" "$(idx_line)"
files_eq "X-8 index: index byte-identical" "$SB/index.before" "$SB/.harness/insight-index.md"

# =========================================================================
banner "X-9 — an unterminated final line that is a CONTINUATION line survives the read"
new_sandbox
mkdir -p "$SB/docs/features/x9"
printf '# Insight Index — fixture\n' > "$SB/.harness/insight-index.md"
# NOTE the absent trailing newline: the `while IFS= read -r line` idiom this
# replaced drops this line entirely, at exit 0, reporting it as absent.
printf '# 07\n\n## Insight\n\n- 2026-02-01 · a fact that wraps\n  its continuation · evidence: z:3' \
    > "$SB/docs/features/x9/07_DELIVERY.md"
# The absent final newline IS the fixture's defining property, so this guard has
# to be able to see it come back. `tail -c 1 | wc -l` counts the last byte as a
# newline or not — range {1, 0}, same range as the PS twin's last-byte test at
# :675-678. (A `tr -d` + `tr -dc` pipeline cannot: the first filter deletes the
# only byte the second could keep, so its range is the one-element set {""}.)
x9_final_nl=$(tail -c 1 "$SB/docs/features/x9/07_DELIVERY.md" | wc -l)
eq "X-9 fixture really has no trailing newline" "0" "$(( x9_final_nl ))"
run_at --task x9
eq "X-9 exit status" "0" "$AT_EXIT"
eq "X-9 the unterminated final line is counted as a continuation" \
   "Insight tally: entries 1, continuation lines 1, ignorable lines 1 (terminal footer 0), unaccounted lines 0" \
   "$(sec_line)"
eq "X-9 the unterminated final line reaches the index verbatim" \
   "  its continuation · evidence: z:3" "$(tail -n 1 "$SB/.harness/insight-index.md")"

# =========================================================================
banner "X-10 — an unbalanced <!-- in the index is MEASURED: refuse, do not corrupt"
new_sandbox
mkdir -p "$SB/docs/features/x10"
cat > "$SB/.harness/insight-index.md" <<'EOF'
# Insight Index — fixture

<!-- Append new insights below, one per line. Format:

- 2026-01-01 · stored one
EOF
printf '# 07\n\n## Insight\n\n- new one\n\n## Verdict\n' > "$SB/docs/features/x10/07_DELIVERY.md"
cp "$SB/.harness/insight-index.md" "$SB/index.before"
run_at --task x10
eq "X-10 exit status is 3 (refuses rather than appending inside the open comment)" "3" "$AT_EXIT"
has "X-10 diagnostic names the unterminated comment's opening line" \
    "insight-index.md:3: unterminated HTML comment opened here: <!-- Append new insights below, one per line. Format:" "$AT_ERR"
eq "X-10 tally: whole file is header block, 0 entries, 1 unaccounted" \
   "Index tally: entries 0, unaccounted lines 1, entries after run 0" "$(idx_line)"
files_eq "X-10 index byte-identical (nothing appended inside the comment)" "$SB/index.before" "$SB/.harness/insight-index.md"
x10_i4=$(i4_line "$SB")
has "X-10 I.4 reports non-PASS over the same index" "WARN" "$(i4_head "$x10_i4")"
has "X-10 I.4 names 0 entries and the unterminated line" "0 entries, 1 unaccounted line(s), first at line 3" "$x10_i4"

# =========================================================================
banner "B-12 / BC-23 — dry run"
new_sandbox
mkdir -p "$SB/docs/features/dry"
cat > "$SB/.harness/insight-index.md" <<'EOF'
# Insight Index — fixture

- 2026-01-01 · stored one
EOF
printf '# 07\n\n## Insight\n\n- new one\n  its continuation · evidence: d:1\n\n## Verdict\n' \
    > "$SB/docs/features/dry/07_DELIVERY.md"
cp "$SB/.harness/insight-index.md" "$SB/index.before"
run_at --task dry --dry-run
dry_exit=$AT_EXIT
dry_sec=$(sec_line)
dry_idx=$(idx_line)
eq "B-12 dry-run exit status" "0" "$dry_exit"
files_eq "B-12 dry-run wrote nothing" "$SB/index.before" "$SB/.harness/insight-index.md"
if [[ -d "$SB/docs/features/dry" ]]; then ok "B-12 dry-run did not move the task dir"; else no "B-12 dry-run did not move the task dir" "moved"; fi
run_at --task dry
eq "B-12 real-run exit status equals the dry-run status" "$dry_exit" "$AT_EXIT"
eq "B-12 real-run section tally equals the dry-run tally" "$dry_sec" "$(sec_line)"
eq "B-12 real-run index tally equals the dry-run tally" "$dry_idx" "$(idx_line)"

new_sandbox
mkdir -p "$SB/docs/features/bc23"
rm -f "$SB/.harness/insight-index.md"
printf '# 07\n\n## Insight\n\n- new one\n\n## Verdict\n' > "$SB/docs/features/bc23/07_DELIVERY.md"
# The PRE-change status on this path is CAPTURED from the extracted script, not
# predicted (insight 2026-07-31 / K-63).
git show HEAD:.harness/scripts/archive-task.sh > "$SB/pre-archive-task.sh" 2>/dev/null
use_script "$SB/pre-archive-task.sh"
run_at --task bc23 --dry-run
echo "        NOTE captured pre-change --dry-run/missing-index exit status: $AT_EXIT"
rm -rf "$SB/docs/features/_archived/bc23"
mkdir -p "$SB/docs/features/bc23"
printf '# 07\n\n## Insight\n\n- new one\n\n## Verdict\n' > "$SB/docs/features/bc23/07_DELIVERY.md"
rm -f "$SB/.harness/insight-index.md"
use_script "$archive"
run_at --task bc23 --dry-run
eq "BC-23 post-change --dry-run against a missing index exits 0" "0" "$AT_EXIT"
has "BC-23 missing-index warning still printed" "insight-index.md missing" "$AT_OUT"
if [[ ! -f "$SB/.harness/insight-index.md" ]]; then
    ok "BC-23 dry-run created nothing"
else
    no "BC-23 dry-run created nothing" "index was created"
fi
has "BC-23 step 4 reached (X-12 anti-regression: no set -e abort)" "[DRY RUN] No files written." "$AT_OUT"

# =========================================================================
banner "BC-1 / BC-2 — no heading, empty section; and a TAB-separated heading (§G register)"
new_sandbox
mkdir -p "$SB/docs/features/bc1"
printf '# Insight Index — fixture\n' > "$SB/.harness/insight-index.md"
cp "$SB/.harness/insight-index.md" "$SB/index.before"
printf '# 07\n\n## Insight to surface\n\n- suffixed heading must NOT match\n' > "$SB/docs/features/bc1/07_DELIVERY.md"
run_at --task bc1
eq "BC-1 exit status" "0" "$AT_EXIT"
eq "BC-1 no matching heading -> 0 entries" \
   "Insight tally: entries 0, continuation lines 0, ignorable lines 0 (terminal footer 0), unaccounted lines 0" \
   "$(sec_line)"
files_eq "BC-1 index not written" "$SB/index.before" "$SB/.harness/insight-index.md"
has "BC-1 X-12 anti-regression: a zero-count harvest reaches step 4" "Archived task: bc1" "$AT_OUT"

new_sandbox
mkdir -p "$SB/docs/features/bc2"
printf '# Insight Index — fixture\n' > "$SB/.harness/insight-index.md"
cp "$SB/.harness/insight-index.md" "$SB/index.before"
printf '# 07\n\n## Insight\n## Verdict\n\nbody\n' > "$SB/docs/features/bc2/07_DELIVERY.md"
run_at --task bc2
eq "BC-2 exit status" "0" "$AT_EXIT"
eq "BC-2 empty section -> 0 entries, 0 unaccounted" \
   "Insight tally: entries 0, continuation lines 0, ignorable lines 0 (terminal footer 0), unaccounted lines 0" \
   "$(sec_line)"
files_eq "BC-2 index not written" "$SB/index.before" "$SB/.harness/insight-index.md"

new_sandbox
mkdir -p "$SB/docs/features/tabhead"
printf '# Insight Index — fixture\n' > "$SB/.harness/insight-index.md"
printf '# 07\n\n##\tInsight\n\n- tab-separated heading fact\n\n## Verdict\n' > "$SB/docs/features/tabhead/07_DELIVERY.md"
run_at --task tabhead
eq "§G register: a literal-TAB heading separator still matches under bash [[ =~ ]]" \
   "Insight tally: entries 1, continuation lines 0, ignorable lines 2 (terminal footer 0), unaccounted lines 0" \
   "$(sec_line)"

# =========================================================================
banner "BC-16 / BC-19 — pre-existing refusals unchanged"
new_sandbox
printf '# Insight Index — fixture\n' > "$SB/.harness/insight-index.md"
run_at --task nosuch
eq "BC-16 missing task directory exits 1" "1" "$AT_EXIT"
has "BC-16 missing task directory message" "Task directory not found" "$AT_ERR"

mkdir -p "$SB/docs/features/dup" "$SB/docs/features/_archived/dup"
run_at --task dup
eq "BC-16 already-archived exits 1" "1" "$AT_EXIT"
has "BC-16 already-archived message" "Task already archived" "$AT_ERR"

if [[ "$(id -u)" != "0" ]]; then
    new_sandbox
    mkdir -p "$SB/docs/features/unread"
    printf '# Insight Index — fixture\n' > "$SB/.harness/insight-index.md"
    printf '# 07\n\n## Insight\n\n- a fact\n' > "$SB/docs/features/unread/07_DELIVERY.md"
    chmod 000 "$SB/docs/features/unread/07_DELIVERY.md"
    run_at --task unread
    eq "BC-19 unreadable delivery document exits 1" "1" "$AT_EXIT"
    has "BC-19 unreadable delivery message" "not readable" "$AT_ERR"
    chmod 644 "$SB/docs/features/unread/07_DELIVERY.md"
else
    echo "        NOTE running as root — BC-19 unreadable-file case skipped"
fi

# =========================================================================
banner "BC-10 — a missing index is created and the harvested entries land in it"
new_sandbox
mkdir -p "$SB/docs/features/bc10"
rm -f "$SB/.harness/insight-index.md"
printf '# 07\n\n## Insight\n\n- new one\n  its continuation · evidence: m:1\n\n## Verdict\n' \
    > "$SB/docs/features/bc10/07_DELIVERY.md"
run_at --task bc10
eq "BC-10 exit status" "0" "$AT_EXIT"
eq "BC-10 empty header block, 0 stored entries" \
   "Index tally: entries 0, unaccounted lines 0, entries after run 1" "$(idx_line)"
if [[ -f "$SB/.harness/insight-index.md" ]]; then ok "BC-10 index created"; else no "BC-10 index created" "absent"; fi
eq "BC-10 harvested entry written whole" "  its continuation · evidence: m:1" "$(tail -n 1 "$SB/.harness/insight-index.md")"

# =========================================================================
# QA-1 (round-3 MAJOR). Scanning only the FIRST `## Insight` heading and
# `break`ing discarded every later section at exit 0 with `unaccounted lines 0`
# — a silent-content-loss path inside K-65's own admissible class, i.e. the
# exact defect class this task exists to remove. The pre-change awk re-armed its
# flag on every matching heading, so this is also the B-11 floor: the AC-4
# `multi-section` leg below drives THIS fixture through the pre-change script.
banner "QA-1 / B-11 — EVERY ## Insight section is harvested (multi-section)"
new_sandbox
mkdir -p "$SB/docs/features/qa1a"
printf '# Insight Index — fixture\n- stored 1\n' > "$SB/.harness/insight-index.md"
cat > "$SB/docs/features/qa1a/07_DELIVERY.md" <<'EOF'
# 07 — Delivery

## Insight

- 2026-02-01 · harvested entry A · evidence: a:1

## Verdict

shipped

## Insight

- 2026-02-01 · harvested entry B · evidence: b:2
  its continuation · evidence: c:3

## End
EOF
run_at --task qa1a
qa1a_idx=$(cat "$SB/.harness/insight-index.md")
eq "QA-1 multi-section exit status" "0" "$AT_EXIT"
eq "QA-1 multi-section tally counts BOTH sections" \
   "Insight tally: entries 2, continuation lines 1, ignorable lines 4 (terminal footer 0), unaccounted lines 0" \
   "$(sec_line)"
eq "QA-1 multi-section index tally" \
   "Index tally: entries 1, unaccounted lines 0, entries after run 3" "$(idx_line)"
has "QA-1 first section's entry reaches the index" "- 2026-02-01 · harvested entry A · evidence: a:1" "$qa1a_idx"
has "QA-1 SECOND section's entry reaches the index (the counterexample line)" \
    "- 2026-02-01 · harvested entry B · evidence: b:2" "$qa1a_idx"
has "QA-1 second section's continuation line reaches the index" \
    "  its continuation · evidence: c:3" "$qa1a_idx"
hasnot "QA-1 no quoted-heading notice on a document with no fence" "Quoted headings:" "$AT_OUT"

# =========================================================================
# The delivery-time variant of QA-1: a document ABOUT this section quotes the
# heading inside a fenced block. Pre-fix the quote WAS the section, so the
# documentation example plus a bare ``` fence were written to the index, a real
# entry was rotated out to history, every real insight was lost, and the run
# exited 0. Fence state is tracked over the whole document for the opener AND
# the terminator.
banner "QA-1 (delivery variant) — a ## Insight heading inside a FENCED block is not a heading"
new_sandbox
mkdir -p "$SB/docs/features/qa1b"
printf '# Insight Index — fixture\n- stored 1\n' > "$SB/.harness/insight-index.md"
cat > "$SB/docs/features/qa1b/07_DELIVERY.md" <<'EOF'
# 07 — Delivery

The developer writes insights under a heading like this:

```
## Insight

- an example bullet that is documentation, not an insight
```

## Insight

- 2026-02-01 · the REAL insight · evidence: a:1

## Verdict
EOF
run_at --task qa1b
qa1b_idx=$(cat "$SB/.harness/insight-index.md")
eq "QA-1 fenced-heading exit status" "0" "$AT_EXIT"
eq "QA-1 fenced-heading tally is the REAL section's" \
   "Insight tally: entries 1, continuation lines 0, ignorable lines 2 (terminal footer 0), unaccounted lines 0" \
   "$(sec_line)"
has "QA-1 the real section's entry reaches the index" \
    "- 2026-02-01 · the REAL insight · evidence: a:1" "$qa1b_idx"
hasnot "QA-1 no fence line reaches the index" '```' "$qa1b_idx"
hasnot "QA-1 the quoted documentation example does not reach the index" \
       "documentation, not an insight" "$qa1b_idx"
eq "QA-1 fenced-heading index holds header + stored + 1 harvested line" "3" \
   "$(wc -l < "$SB/.harness/insight-index.md")"
# Skipping a quoted heading is a DECISION and the run SAYS SO. Without this the
# rule would be a second silent channel: a reader could only infer "a heading
# was ignored" from an entry that never arrived — which is the shape of the
# defect this task exists to remove (user requirement 2).
has "QA-1 the skipped quoted heading is REPORTED, not silent" \
    "Quoted headings: 1 '## Insight' heading(s) inside a code fence were not harvested" "$AT_OUT"

# =========================================================================
# Tracking fences opens one new way to LOSE a section: a fence left open hides
# every later heading. That is refused, not absorbed — the same treatment the
# index's unbalanced `<!--` gets (D-2/X-10), for the same reason.
banner "QA-1 — a code fence left OPEN at EOF refuses, it does not hide the section"
new_sandbox
mkdir -p "$SB/docs/features/qa1c"
printf '# Insight Index — fixture\n- stored 1\n' > "$SB/.harness/insight-index.md"
cp "$SB/.harness/insight-index.md" "$SB/expected-index"
cat > "$SB/docs/features/qa1c/07_DELIVERY.md" <<'EOF'
# 07 — Delivery

```
## Insight

- documentation example

## Insight

- the real one · evidence: a:1
EOF
run_at --task qa1c
eq "QA-1 unterminated fence exit status" "3" "$AT_EXIT"
eq "QA-1 unterminated fence counts as unaccounted" \
   "Insight tally: entries 0, continuation lines 0, ignorable lines 0 (terminal footer 0), unaccounted lines 1" \
   "$(sec_line)"
has "QA-1 unterminated fence names its opening line" \
    "07_DELIVERY.md:3: unterminated code fence opened here: " "$AT_ERR"
files_eq "QA-1 unterminated fence: index byte-identical (nothing written)" \
         "$SB/expected-index" "$SB/.harness/insight-index.md"
has "QA-1 unterminated fence: both swallowed headings are counted and reported" \
    "Quoted headings: 2 " "$AT_OUT"

# =========================================================================
# The BOUND of the fenced-heading rule, measured and SIGNALLED rather than
# assumed: a section that lies ENTIRELY inside a fence is quoted, so it is not
# harvested — 0 entries at exit 0. That is only acceptable because the run
# names it; the `Quoted headings:` line is the whole difference between a
# stated bound and the silent discard QA-1 was.
banner "QA-1 bound — a section entirely inside a fence is quoted: 0 entries, and the run SAYS SO"
new_sandbox
mkdir -p "$SB/docs/features/qa1e"
printf '# Insight Index — fixture\n- stored 1\n' > "$SB/.harness/insight-index.md"
cp "$SB/.harness/insight-index.md" "$SB/expected-index"
cat > "$SB/docs/features/qa1e/07_DELIVERY.md" <<'EOF'
# 07 — Delivery

An example of the whole section, quoted:

```
## Insight

- 2026-02-01 · quoted, not authored · evidence: a:1
```

## Verdict
EOF
run_at --task qa1e
eq "QA-1 bound exit status" "0" "$AT_EXIT"
eq "QA-1 bound harvests nothing" \
   "Insight tally: entries 0, continuation lines 0, ignorable lines 0 (terminal footer 0), unaccounted lines 0" \
   "$(sec_line)"
has "QA-1 bound: the ignored heading is reported on stdout" \
    "Quoted headings: 1 " "$AT_OUT"
files_eq "QA-1 bound: index unchanged" "$SB/expected-index" "$SB/.harness/insight-index.md"

# =========================================================================
# MEASURED RESIDUAL, not an endorsement. Fence awareness is scoped to SECTION
# DISCOVERY. A fence INSIDE the section is still classified by pass B, so its
# lines are absorbed as continuation lines of the preceding entry (or refused if
# no entry is open). That channel adds content to the index; it never discards
# any, so it cannot produce the exit-0-with-lost-content shape this task exists
# to remove. Pinned so the bound is measured rather than assumed.
banner "QA-1 residual — a fence INSIDE the section is absorbed, never dropped"
new_sandbox
mkdir -p "$SB/docs/features/qa1d"
printf '# Insight Index — fixture\n- stored 1\n' > "$SB/.harness/insight-index.md"
cat > "$SB/docs/features/qa1d/07_DELIVERY.md" <<'EOF'
# 07 — Delivery

## Insight

- 2026-02-01 · one · evidence: a:1
```json
{"a": 1}
```
- 2026-02-01 · two · evidence: b:2

## Verdict
EOF
run_at --task qa1d
eq "QA-1 residual exit status" "0" "$AT_EXIT"
eq "QA-1 residual: the 3 fenced lines are counted as CONTINUATION, not dropped" \
   "Insight tally: entries 2, continuation lines 3, ignorable lines 2 (terminal footer 0), unaccounted lines 0" \
   "$(sec_line)"
has "QA-1 residual: the fenced body reaches the index verbatim" \
    '{"a": 1}' "$(cat "$SB/.harness/insight-index.md")"

# =========================================================================
# The TILDE half of the fence state machine (CR-13). RE_FENCE accepts `~{3,}`
# and the tilde branch is NOT a copy of the backtick branch: a tilde opener's
# info string is unrestricted, where a backtick opener's may hold no backtick.
# Every other fixture in this driver uses backticks, so that branch was
# code-correct and pinned by nothing. This is the qa1b shape rewritten with
# `~~~`, and it exercises all three tilde-only paths in one fixture:
#   * the OPENER, whose info string here CONTAINS a backtick — a backtick fence
#     with that info string would not open at all. If it failed to open, the
#     quoted heading would become the section and the tally would read entries 2.
#   * the mismatched closer — the ``` run inside does NOT close a tilde fence
#     (bound 5 in the other direction). If it did, `## Insight` at line 15 would
#     open a second section and the quoted bullet would reach the index.
#   * the CLOSER. If `~~~` failed to close, the fence would still be open at EOF
#     and the run would refuse at exit 3 with nothing written.
banner "QA-1 / CR-13 — the TILDE fence branch: opener with a backtick info string, mismatched \`\`\` inside, tilde closer"
new_sandbox
mkdir -p "$SB/docs/features/qa1f"
printf '# Insight Index — fixture\n- stored 1\n' > "$SB/.harness/insight-index.md"
cat > "$SB/docs/features/qa1f/07_DELIVERY.md" <<'EOF'
# 07 — Delivery

The quoted example itself contains a backtick fence, so the outer fence is a tilde one:

~~~markdown with a `backtick` in the info string
## Insight

- an example bullet that is documentation, not an insight

```
inner backtick fence — not a closer for a tilde fence
```
~~~

## Insight

- 2026-02-01 · the REAL insight · evidence: a:1

## Verdict
EOF
run_at --task qa1f
qa1f_idx=$(cat "$SB/.harness/insight-index.md")
eq "CR-13 tilde fence exit status (the ~~~ closer really closed it)" "0" "$AT_EXIT"
eq "CR-13 tilde fence tally is the REAL section's" \
   "Insight tally: entries 1, continuation lines 0, ignorable lines 2 (terminal footer 0), unaccounted lines 0" \
   "$(sec_line)"
has "CR-13 the real section's entry reaches the index" \
    "- 2026-02-01 · the REAL insight · evidence: a:1" "$qa1f_idx"
hasnot "CR-13 the tilde-quoted documentation example does not reach the index" \
       "documentation, not an insight" "$qa1f_idx"
has "CR-13 the heading quoted inside a TILDE fence is reported, not silent" \
    "Quoted headings: 1 '## Insight' heading(s) inside a code fence were not harvested" "$AT_OUT"

# =========================================================================
banner "AC-4 (bash) — regression floor against the git-extracted PRE-CHANGE script"
pre_script=$(mktemp "${TMPDIR:-/tmp}/archive-task-pre.XXXXXX.sh")
git show HEAD:.harness/scripts/archive-task.sh > "$pre_script" 2>/dev/null
if [[ ! -s "$pre_script" ]]; then
    no "AC-4 pre-change script extracted from git" "git show HEAD:.harness/scripts/archive-task.sh produced nothing"
else
    ok "AC-4 pre-change script extracted from git"
    # K-65's pinned admissible fixture class: index line 1 is a non-entry line,
    # no blank between it and the first entry, every entry one physical line
    # ending in a non-space character, file ends in exactly one newline, section
    # carries no unaccounted line, index exists.
    build_ac4() {   # <sandbox> <stored-count>
        local root="$1" stored="$2" i
        mkdir -p "$root/docs/features/ac4" "$root/docs/features/_archived"
        printf '# Insight Index — fixture\n' > "$root/.harness/insight-index.md"
        for (( i = 1; i <= stored; i++ )); do
            printf -- '- 2026-01-01 · stored entry %02d · evidence: t:%d\n' "$i" "$i" >> "$root/.harness/insight-index.md"
        done
        printf '# 07 — Delivery\n\n## Insight\n\n- 2026-02-01 · new fact one · evidence: a:1\n- 2026-02-01 · new fact two · evidence: b:2\n' \
            > "$root/docs/features/ac4/07_DELIVERY.md"
    }
    for legname in append rotation; do
        if [[ "$legname" == "append" ]]; then stored=5; else stored=30; fi
        new_sandbox; pre_sb="$SB"
        use_script "$pre_script"
        build_ac4 "$pre_sb" "$stored"
        run_at --task ac4
        pre_exit=$AT_EXIT
        new_sandbox; post_sb="$SB"
        build_ac4 "$post_sb" "$stored"
        run_at --task ac4
        eq "AC-4 $legname: post-change exit status matches pre-change" "$pre_exit" "$AT_EXIT"
        files_eq "AC-4 $legname: index byte-identical to pre-change output" \
                 "$pre_sb/.harness/insight-index.md" "$post_sb/.harness/insight-index.md"
        if [[ -f "$pre_sb/docs/features/_archived/insight-history.md" || -f "$post_sb/docs/features/_archived/insight-history.md" ]]; then
            files_eq "AC-4 $legname: history byte-identical to pre-change output" \
                     "$pre_sb/docs/features/_archived/insight-history.md" "$post_sb/docs/features/_archived/insight-history.md"
        else
            ok "AC-4 $legname: neither run created a history file"
        fi
    done
    # QA-1's row 3: the multi-section fixture driven through the PRE-CHANGE
    # script as well, so the QA-1 rows above are anti-revert coverage and not a
    # self-consistent assertion. The pre-change awk re-armed `flag` on every
    # matching heading, so pre-change is the CORRECT reference here — a fix that
    # only silenced the symptom would show up as a byte difference.
    build_ac4_multi() {   # <sandbox>
        local root="$1" i
        mkdir -p "$root/docs/features/ac4m" "$root/docs/features/_archived"
        printf '# Insight Index — fixture\n' > "$root/.harness/insight-index.md"
        for (( i = 1; i <= 5; i++ )); do
            printf -- '- 2026-01-01 · stored entry %02d · evidence: t:%d\n' "$i" "$i" >> "$root/.harness/insight-index.md"
        done
        printf '# 07 — Delivery\n\n## Insight\n\n- harvested entry A\n\n## Verdict\n\nshipped\n\n## Insight\n\n- harvested entry B\n\n## End\n' \
            > "$root/docs/features/ac4m/07_DELIVERY.md"
    }
    new_sandbox; pre_sb="$SB"
    use_script "$pre_script"
    build_ac4_multi "$pre_sb"
    run_at --task ac4m
    pre_exit=$AT_EXIT
    new_sandbox; post_sb="$SB"
    build_ac4_multi "$post_sb"
    run_at --task ac4m
    eq "AC-4 multi-section: post-change exit status matches pre-change" "$pre_exit" "$AT_EXIT"
    files_eq "AC-4 multi-section: index byte-identical to pre-change output (B-11)" \
             "$pre_sb/.harness/insight-index.md" "$post_sb/.harness/insight-index.md"
    has "AC-4 multi-section: the pre-change reference really harvested BOTH entries" \
        "- harvested entry B" "$(cat "$pre_sb/.harness/insight-index.md")"
    rm -f "$pre_script"
fi

# =========================================================================
banner "AC-7 — I.4's unaccounted condition is non-vacuous (mutation of the ARTIFACT)"
new_sandbox
cp "$repo_root/.harness/insight-index.md" "$SB/.harness/insight-index.md"
clean_i4=$(i4_line "$SB")
has "AC-7 unmutated copy of the live index: I.4 PASSes" "PASS" "$(i4_head "$clean_i4")"
# INSERTION, never a deletion — a deletion would remove another assertion's
# container (insight 2026-08-01). The prose carries no I.6 banned anchor.
printf '\nan ordinary prose line that is neither a bullet nor a continuation\n' >> "$SB/.harness/insight-index.md"
dirty_i4=$(i4_line "$SB")
has "AC-7 mutated copy: I.4 reports non-PASS" "WARN" "$(i4_head "$dirty_i4")"
has "AC-7 mutated copy: I.4 names the unaccounted count" "1 unaccounted line(s)" "$dirty_i4"

# =========================================================================
banner "AC-3 — one file never yields two entry counts (rotation result)"
new_sandbox
mkdir -p "$SB/docs/features/ac3"
printf '# Insight Index — fixture\n' > "$SB/.harness/insight-index.md"
printf -- '- 2026-01-01 · stored wrapped\n  its continuation · evidence: w:1\n' >> "$SB/.harness/insight-index.md"
for i in $(seq 2 30); do printf -- '- stored %02d\n' "$i" >> "$SB/.harness/insight-index.md"; done
printf '# 07\n\n## Insight\n\n- new one\n\n## Verdict\n' > "$SB/docs/features/ac3/07_DELIVERY.md"
run_at --task ac3
eq "AC-3 rotation run exit status" "0" "$AT_EXIT"
eq "AC-3 archive-task reports 30 entries after the run" \
   "Index tally: entries 30, unaccounted lines 0, entries after run 30" "$(idx_line)"
ac3_i4=$(i4_line "$SB")
has "AC-3 I.4 agrees the rotation result is within the cap" "PASS" "$(i4_head "$ac3_i4")"
eq "AC-3 K-61 equality over the rotation result (raw 30 == entries 30)" "30" "$(raw_markers "$SB/.harness/insight-index.md")"

# =========================================================================
echo ""
echo "=== test-archive-task summary ==="
echo "  PASS: $pass"
echo "  FAIL: $fail"
if (( fail > 0 )); then
    echo ""
    echo "Failures:" >&2
    for f in "${failures[@]}"; do echo "  - $f" >&2; done
    exit 1
fi
exit 0
