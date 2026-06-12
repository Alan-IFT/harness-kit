# Delivery Summary

- Task: T-021 `stream-auto-decompose` — `/harness-stream` ingest now complexity-triages each chat/ambient requirement and auto-decomposes a complex one into N small staged pool rows (shared slug prefix + `## Notes` provenance, real `Depends on` chains only, union of derived Goals ≡ the original requirement); simple requirements keep the exact 1:1 path; user-authored rows (`ADD` lines, hand-written) are never split.
- Mode: full
- Stages traversed: 1 (RA, READY FOR DESIGN) → 2 (SA, READY FOR GATE) → 3 (Gate, APPROVED FOR DEVELOPMENT, 0 blocking / 4 advisory) → 4 (Dev, READY FOR REVIEW) → 5 (CR, APPROVED, 0 blocking / 0 major) → 6 (QA, PASS — RELEASABLE) → 7 (this doc). All on 2026-06-12.
- Rollbacks: 0 (Gate F-2 line-budget tension dissolved at Dev time by style re-wrap, zero contract terms trimmed)
- Final verify_all result: **PASS** — 32/0/0 BOTH shells (bash + pwsh, QA-captured real runs; PM re-ran post-archive)
- Baseline changes: none of the counts moved (checks 32, skills 15); `baseline.json` `last_verify` → 2026-06-12 (QA). Regression drivers green untouched: test-init.sh 270/0, test-init.ps1 308/0, test-real-project 90/0 both shells.
- Outstanding risks:
  - DEFECT-1 (MINOR, **pre-existing**, not a T-021 regression): `ambient-prompt.ps1` emits non-ASCII punctuation in the host ANSI codepage (GBK on zh-CN Windows) — UTF-8 consumers render mojibake for em-dash/`≡`; operative ASCII content unaffected. Backlog fix: set `[Console]::OutputEncoding` to UTF-8 in the ps1 hook pair (dogfood + template).
  - m-1 (minor, accepted design residual): two different requirements deriving the same `<base>` slug would conflate prefix-grouping; the dated requirement-quoting `## Notes` lines still disambiguate.
- Files changed: 13 (`git diff --stat`): `skills/harness-stream/SKILL.md` (+34/-6 → 175 lines: new single-sourced `## Ingest triage` section, binding pointers from ambient step 1 + Procedure 3a, amended union-invariant hard rule, anti-pattern + Cost + description), 4× `ambient-prompt.{ps1,sh}` (dogfood + template, +2 emitted lines lockstep), `README.md` + `README.zh-CN.md` (bullet + badge + roadmap), `CHANGELOG.md` (`[0.32.0]`), `.claude-plugin/plugin.json` + `marketplace.json` (0.31.0→0.32.0), `docs/batches/README.md`, `docs/tasks.md`, `baseline.json`.
- Next steps for user: optional backlog task for DEFECT-1 (`[Console]::OutputEncoding` in the ps1 hooks); consumer projects pick the new ambient triage step up via `/harness-upgrade` (S2 refresh set already includes the ambient pair).

## Insight (optional — only if the task uncovered non-obvious project truth)

- 2026-06-12 · `pwsh` hook stdout follows the HOST ANSI codepage (GBK on this zh-CN Windows), so an emitted instruction block's non-ASCII punctuation (em-dash, `≡`) reaches UTF-8 consumers as mojibake while bash's emission stays UTF-8-clean — a cross-shell parity gap invisible to CR-stripped text comparison (bytes differ only at non-ASCII code points). Pre-existing in `ambient-prompt.ps1` since v0.22; fix class: `[Console]::OutputEncoding = [Text.Encoding]::UTF8` at the top of any EMITTING ps1 hook (extends the cross-shell-parity family from write-time newlines to console-encoding). · evidence: T-021 QA DEFECT-1, byte-compare vs v0.31.0 `git show HEAD:` run
