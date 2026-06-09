# 05 — Code Review · T-016 / i18n-special-drift-guard

> Stage 5. Code Reviewer (read-only). Persisted by PM. Reviewed vs 02 design, 01 ACs, 03 gate (F-1..F-4).
> Both shells already GREEN (Dev bash; PM PS): verify_all 32/32, test-language 39/39, test-init 275(ps)/237(sh)
> incl. the new `[zh][T-016]` body-match assertion, sync-self in sync, Dev pre-delete cmp proof.

## Verdict: APPROVED — 0 BLOCKING · 0 MAJOR · 1 MINOR · 2 NIT

The ELIMINATE design is faithfully + completely implemented. No routing required.

## The two most important confirmations
**1. Duplication ACTUALLY eliminated (not relocated).** The 3 SPECIAL i18n/zh files are physically gone (Glob
"No files found" for all three). The English framework BODY now lives in exactly ONE place: `templates/common/`.
M-1 contains ONLY the zh policy (section + line) — no English body anywhere. The new `[zh][T-016]` assertion
structurally enforces "composed zh body == common/ body," so a future common/ edit propagates automatically +
is test-guarded. The R-2 root cause is REMOVED, not guarded. Task met its stated goal.
**2. M-1 byte-correct.** CJK clean (no mojibake/U+FFFD; full-width `（）——：、` render cleanly); T-013 anchor-free
(`按消费者分流`, no `全程`); heading + line match the helper anchors; sentinel (line 29) terminates the section
span without matching `^## 输出语言` or `^输出语言：`. Corroborated by the Dev cmp proof (region A 1492B / B 235B
byte-identical to deleted originals; composed files whole-file byte-identical to old overlay) + green tests.

## AC + design-fidelity: all OK
3 deletions clean (overlay 5→2 + non-overlaid `_policy/`); re-point ONLY the zh source path (`language-policy.sh:83-85`
/ `.ps1:80-82`), extractor + en source unchanged, dogfood mirror in sync (E.1); init step 4.4 zh-only/after-common/
rm-.bak/idempotent (`SKILL.md:110-138`); adopt F-4 fixed (`harness-adopt/SKILL.md:275-292`); test-init COMPOSE
re-model + exactly ONE new mutation-provable body-match assertion/shell (T-015 inverse + 4 T-013 retained); EN path
byte-unchanged; check count STAYS 32 (no new Step — the anti-bloat win); version 0.27.0 at 4 G.3 sites; "32"/badge
claims byte-exact except the version badge; baseline ps=275 (PM-captured)/bash=237, test-init badge 275; no I.6 self-trip;
+1/shell reconciles with the one new assertion (no fabricated tally).

## Findings (advisory)
- **MINOR [MAINT] `skills/harness-init/SKILL.md:153-164`** — the "templates/common contains... CLAUDE.md.tmpl ...
  never regenerated — static stubs" prose now sits AFTER the new step 4.4, which DOES rewrite CLAUDE.md/copilot's
  policy LINE for zh. Still true for the BODY, but a reader landing here right after 4.4 could read it as
  contradicting the injection / as a doc inaccuracy about init behavior. Advisory clarity — tighten to note the
  body is static but the policy line is injected for zh. → developer (prose).
- **NIT [STYLE] test-init.sh:525** — `.bak` cleanup uses 3 explicit globs vs the PS mirror's single recursive
  `*.bak-*`; both green. Preference.
- **NIT [STYLE] output-language.zh.md.tmpl:29** — the sentinel heading is load-bearing-by-convention; a one-line
  comment is fine.

## Residual risk for QA (verify by RUNNING)
#1: a real `/harness-init` Q5=中文 on Windows (PS path) composes a zh project = English body + injected Chinese
policy, with NO leftover `*.bak-*` (step 4.4 is a NEW live orchestration step only test-init has exercised; PS
numbers were PM-captured). Plus: `/harness-language zh`→`en` round-trip on a freshly-composed zh project (byte-identity
back to English on a real non-fixture tree); and a mutation-sensitivity spot-check of `[zh][T-016]` in BOTH shells
(mutate one `common/00-core.md.tmpl` body line → test-init RED both shells; the PS `[array]::IndexOf`+`-ceq`
body-comparison is the hand-rolled mirror most likely to harbor a latent line-model mismatch).
