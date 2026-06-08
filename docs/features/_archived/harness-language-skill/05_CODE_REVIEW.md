# 05 — Code Review · T-014 / harness-language-skill

> Stage 5. Code Reviewer (read-only). Persisted by PM. Reviewed vs 02 design, 01 ACs, 03 gate (F-1..F-4).

## Verdict: APPROVED — 0 BLOCKING, 0 MAJOR, 2 MINOR, 1 NIT

Faithful to design; all 4 Gate advisories honored; the I.6 self-trip (that bit T-013 3×) is cleared.
All 13 ACs implemented + test-covered. Load-bearing properties (byte-identical round-trip, cross-shell
parity, I.6 safety, fan-out completeness) hold under scrutiny.

## #1 property — byte-identical zh→en→zh round-trip + cross-shell parity: VERIFIED SOUND
- Section slice `[heading, next "## ")` identical both shells (bash awk `extract_section_to` sh:120-134;
  PS `Get-SectionLines` ps1:136-150), trailing blank line included (en 9-23, zh 9-32) — R7 off-by-one handled.
- Final-byte parity: bash awk→cp (sh:203) one trailing `\n`; PS `($lines -join "\n")+"\n"` (ps1:199,217)
  one trailing `\n`. Match regardless of source trailing newline; CRLF normalizes to LF identically.
- NOOP/idempotence compares full new-text byte-for-byte before writing (cmp -s sh:189 / -ceq ps1:202), no .bak on identity.
- Test #9 asserts BYTE-identity (cmp -s / -ceq on raw ReadAllText) both shells, all 3 files. Text read only
  from `--template-root` (single-source invariant) → round-trip stable.

## PS `-split` fix — VERIFIED, no other latent occurrence
`Read-Lines` uses `.NET .Split("\n")` (ps1:112-117) with documented rationale; `-split` appears nowhere else.
Heading/anchor matches use case-sensitive `-ceq`/`-cmatch` (ps1:142,202,227,235) — correct fixed-case calibration.

## I.6 self-trip avoidance — VERIFIED ZERO RISK
Independent grep `全程` across repo: NONE in any T-014 new/edited SCANNED file (SKILL, both helpers, both
tests, AI-GUIDE, READMEs, getting-started, manual-e2e, 40-locations, harness-upgrade hint, dev-map). Only
non-exempt `全程` carriers are test-init.{ps1,sh} pre-existing absence-asserts where `全程` does NOT co-occur
with `中文` on the line → regex can't match. Applied zh canonical text (i18n/zh 00-core.md.tmpl:9-31) has `中文`
but never `全程`. Helper EXTRACTS prose (never embeds). I.6 stays green.

## Fan-out completeness — VERIFIED EXHAUSTIVE
- 0.25.0 at all 4 G.3 sites (plugin.json:4, marketplace.json:17 [F-2 confirmed], README.md:5, README.zh-CN.md:5).
- Skill 14 everywhere live (verify_all C.1/G.1/G.2 arrays+labels both shells, README×2 14/fourteen/14 个,
  AI-GUIDE:7, getting-started:36, manual-e2e all enumerations, 40-locations:30, dev-map tree+prose).
- `harness-language` literal in README.md:27 (G.1) + CHANGELOG:10/14/18 (G.2) — name-match gates satisfied.
- `language-policy` in F.1 both shells; `test-language` correctly NOT in F.1 (F-3). sync-self Mapping 8 both
  shells (6→7); AI-GUIDE:71 "7 script pairs" updated. "six task shapes"/"6 种任务形态" UNCHANGED. "32 checks" untouched. New skill under Setup.

## Test quality — MEANINGFUL (39 asserts each, symmetric)
Own temp dir per fixture (L22). Real end-state checks (exact heading-count, surgical `keep me`/sibling
preservation, conflict exit-2 + file-unchanged, byte-identity round-trip). No T-007 present+absent-same-string
trap. Test #10 PS bad-arg asserts `-ne 0` (ValidateSet bind reject) vs bash exit 1 — correctly accommodated.

## SKILL.md — high quality
Valid frontmatter (incl. AskUserQuestion + Bash + PowerShell). Flow matches helper CLI/exit/stdout. Gates
(git repo, clean tree), detect-then-confirm, absent-section CONFLICT→AskUserQuestion(insert/abort)→--force,
dry-run→confirm→apply. CLAUDE_PLUGIN_ROOT best-effort, glob fallback load-bearing. Dogfood red line stated.

## Design-drift adjudication: ACCEPT (no route to architect)
The "temp-file (bash) / line-array (PS) section injection instead of `$(...)`" drift (04:89-97) is ACCEPTED:
`$(...)` strips trailing newlines and would destroy the section's trailing blank line, breaking §5.4's
byte-stable round-trip (R7). The mechanism is in SERVICE of the contract, not a deviation; test #9 proves it.

## Findings
### MINOR
- **[MAINT] `skills/harness-language/SKILL.md:104-107`** — Step 4 (no-arg refresh) is imprecise about HOW to
  obtain the `DETECT|` record without committing to a language (the helper requires `--lang`). Mechanism works
  (DETECT emitted post-arg-validation, pre-mutation, dry-run writes nothing) but wording should say "invoke
  `--lang <either> --dry-run` purely to read the `DETECT|` record." Dev acknowledged (04:127-130). → developer.
- **[LOGIC] `language-policy.ps1:46-48` vs `.sh:63-66`** — invalid `--lang`: bash emits custom actionable msg
  + exit 1; PS `[ValidateSet]` rejects at bind (generic error, exit non-zero). Equivalent at contract level
  (exit≠0, no change); test #10 accommodates. **PM decision: ACCEPT as-is** — de-idiomatizing PS to match the
  message would be lower quality. Documented known-minor.

### NIT
- **[STYLE] `language-policy.sh:43`** — `LANG_ARG` deliberately avoids clobbering `$LANG` locale env var.
  Correct; called out so a future edit doesn't "simplify" it.

## AC coverage: AC-1..AC-13 all ✅ (see design traceability; round-trip byte-identity proven by test #9).

## Residual risk for QA (verify by RUNNING)
1. **Cross-shell byte parity of the END STATE** — within-shell round-trip is proven by test #9, but
   bash-produced vs PS-produced state being byte-identical to EACH OTHER is claimed, not auto-asserted. On a
   freshly init'd project, run the real en↔zh switch once via bash helper and once via PS helper from clean
   baselines, `cmp` the resulting 00-core.md + CLAUDE.md + copilot-instructions.md across shells (T-012 DEFECT-1 class).
2. verify_all I.6 PASS both shells on the live tree (the T-013 self-trip class).
3. Exercise the no-arg DETECT→confirm path end-to-end through the SKILL (the MINOR step-4 imprecision).
