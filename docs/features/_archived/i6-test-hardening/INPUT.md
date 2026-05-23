# INPUT — T-005 i6-test-hardening

> PM-provided task description. Source-of-truth for downstream agents' "what does the user want?".

## User request (verbatim, translated where useful)

After T-004 (i6-semantic-guard, v0.18.0) shipped, two leftover non-blocking observations from
the T-004 CR + QA notes were left for a future task:

1. **`scripts/test-verify-i6.ps1`'s structural lockstep is weaker than the bash side.** The
   bash twin (`test-verify-i6.sh`) extracts `scripts/verify_all.sh`'s `$i6_banned` array
   verbatim and compares every one of its 13 entries against the driver's own copy. The PS
   twin only asserts (a) `scripts/verify_all.ps1`'s `$banned` has 13 entries, and (b) entry
   `#10` carries `exclude=@('.claude/')`. Means a typo in any of `#1` / `#3–9` / `#11–13`'s
   `reason` string (or `exclude` / `gap` clause) would slip past PS structural lockstep — the
   cross-shell parity assertion only catches divergences that change BEHAVIORAL hit sets, not
   a `reason`-string typo (which is metadata, not used by the matcher).

2. **AC-8 (`CHANGELOG.md` / `_archived/` exemption preserved) has no permanent corpus
   fixture.** T-004 QA validated AC-8 via an inline injection probe — banned phrase injected
   at runtime into a tracked file at an exempt path; the temporary mutation was reverted after
   `verify_all` confirmed the file was skipped. Permanent corpus fixtures (i.e. fixtures
   shipped in the test driver's regression set) would catch a future refactor of verify_all's
   exempt-list handling that silently regresses AC-8.

## Constraints from user

- All commits and decisions delegated to PM. User reviews delivered outcome, not interim
  decisions. ("以用户体验好，符合软件工程标准，长期易使用易维护为原则来决策")
- Explicitly out of scope (user said so):
  - `architecture.html:326`'s `v0.17.4` — file has v0.5/v0.6 snapshot caveat and refresh
    deferred to v0.18+ roadmap.
  - Upgrade I.6 matcher to NLP / embedding-grade semantic matching. User: "远超本次"; T-004
    design §3.2 explicitly documents the threat-model trade-off (unintentional copy-paste
    drift, not active adversary).
- One unrelated trivial doc-consistency fix (`docs/manual-e2e-test.md:3` says `v0.17.4`
  for verify_all check count, should say `v0.18.0`) PM has decided to ship as a separate
  trivial commit AFTER this task, NOT as part of the 7-stage pipeline.

## Why this is non-trivial

Per `.harness/rules/00-core.md`, non-trivial for this repo includes "change to verify_all or
its checks". The structural lockstep test directly guards verify_all's I.6 check. AC-8
fixtures expand the test driver corpus. PS/bash symmetry rule (30-engineering #20) applies.
