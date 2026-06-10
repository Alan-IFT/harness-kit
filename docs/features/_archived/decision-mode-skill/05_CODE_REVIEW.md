# Code Review — decision-mode-skill (T-018)

- Reviewer: operator
- Verdict: **APPROVED**

## Findings

1. **SKILL.md meets `15-skill-authoring.md`.** Model-facing `description:` with EN + 中文 triggers
   and a "NOT for…" disambiguation delta; full When-to / When-NOT / Anti-patterns / Hard-rules /
   Out-of-scope surface; correctly justifies **no helper script** (rule 15 P6 — the edit is a
   one-line replace). The procedure is sound: clean-git precondition, single-`Active mode`-line
   `Edit`, Mode-3 empty-Custom capture, idempotent no-op, hand-mangled-line conflict halt.
2. **AC-4 (the #1 risk) honored.** The shipped `templates/common/.harness/decision-rubric.md`
   Preset is GENERIC — three prime principles + universal defaults (reversible-in-scope→do,
   match-conventions, honest-reporting, verify-before-done, profile-before-optimizing) — with
   **none** of this operator's personal prefs (no lightweight/design-over-guards/Chinese-chat/
   commit-push lines). Shipped policy `Active mode: 1`. Verified by direct read.
3. **Cross-shell symmetry.** `install.ps1`/`install.sh` both add the skill (array + echo);
   `verify_all.ps1`/`verify_all.sh` both move C.1/G.1/G.2 14→15; `test-init.ps1`/`test-init.sh`
   both gain the 2 assertions.
4. **Fan-out complete, incl. the UNGATED surfaces Gate F-1 caught.** `getting-started.md`
   ("fifteen"), `manual-e2e-test.md` (15/fifteen ×4) updated. No stale "fourteen" anywhere;
   `README.zh-CN.md:258` "14 个文件" correctly left untouched (version-history file count, not a
   skill count).
5. **No bloat.** No new `verify_all` check (count stays 32), no I.6 banned/exempt-list change,
   no new `{{placeholder}}`.

APPROVED → QA.
