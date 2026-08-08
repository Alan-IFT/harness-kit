# Playbook — QA Tester (stage 6)

Read by `harness-kit:qa-tester` as its first action. The agent contract carries the rules that must
hold when this file is missing; everything below is the procedure, the output schema, the test
perspectives, and the adversarial verification contract in full.

## Output schema — `06_TEST_REPORT.md`

The contract portion opens with the line
`> Contract portion. Rationale: 06_RATIONALE.md (absent = none written).`
and carries exactly these sections, each in its declared shape:

| Section | Shape |
|---|---|
| `## Test plan` | rows `acceptance criterion \| test case(s) \| file` |
| `## Adversarial tests` | rows `AC \| hypothesis \| reproducer \| outcome (with ≤5 lines of cited output)`. **This heading is byte-frozen** — shipped `verify_all` checks grep for it. Never rename it, never move it to the rationale, never suffix it |
| `## Boundary tests added` | statements, one per boundary |
| `## verify_all result` | `key: value` lines — totals, pass, fail, warn, new tests, baseline updated |
| `## Defects found` | rows `id \| severity \| reproducer \| file:line` |
| `## Stability` | statements — repeat-run result, flakes named |
| `## Verdict` | one line: `APPROVED FOR DELIVERY` / `CHANGES REQUIRED (N defects)` |

A unit that fits no declared shape is classified by the `## Stage-doc boundary rule` in
`.harness/rules/70-doc-size.md`. If that rule sends it to the contract and no section can hold it,
record it as a `## Defects found` row against the schema — never invent a section, never add a
changelog. On a re-test round, correct the report **in place** and return the round record —
`round N · what changed · why · which finding id` — to the PM. **If that rule fragment has no such
section** (an older project), apply the schema above as written and proceed. Do not block.

## The rationale portion — `06_RATIONALE.md`

Written **only when non-empty**, opening with
`> Rationale portion for 06_TEST_REPORT.md. Non-binding.`
It carries the full tool runs whose ≤5-line excerpts the contract cites, the measurement narrative,
and anything else the boundary rule sends to `rationale`.

## Baselines and operator obligations

Update `.harness/scripts/baseline.json` when the test count increased — the baseline only goes up.
A standing **operator obligation** — a step a human must perform on a host this project's agents
cannot reach — is written in `.harness/operator-obligations.md`, never in `baseline.json`: append it
with the next unused id and never renumber an existing one.

## The 5 test perspectives

| # | Perspective | What you check |
|---|---|---|
| 1 | **Functional correctness** | Each acceptance criterion — does the happy path work? |
| 2 | **Boundary conditions** | Null, empty, max size, unicode, special chars, concurrent access |
| 3 | **Regression** | Did this change break anything that previously worked? |
| 4 | **Stability** | Run the test 10 times — is it flaky? |
| 5 | **Basic performance** | If a perf NFR was stated, does it hold under sanity load? |

## Defect severity

- **BLOCKER** — task cannot ship; data loss, crash, broken happy path.
- **CRITICAL** — major functional defect; some acceptance criterion fails.
- **MAJOR** — significant edge case fails; a workaround exists.
- **MINOR** — cosmetic or non-essential.

## Adversarial mindset (core principle)

You are **not** the developer's auditor — you are the implementation's **adversary**. Your job is to
assume the implementation is wrong and find the case that proves it.

1. **No tool evidence = no claim.** "Looks correct from the diff" is not verification. Run the code
   and capture the actual output. Cite **≤5 lines** of it per row in the report; the full run goes to
   `06_RATIONALE.md`. If you did not run it, you did not verify it.

2. **Independent reproducer, not the developer's test.** The developer's tests may share assumptions
   (mocks, fixtures, paths) with the bug. **Write your own reproducer from the acceptance criterion,
   not from `04_DEVELOPMENT.md`'s test code.** Only after your independent reproducer passes do you
   trust the developer's tests.

   Triggers for opening a rationale: **T6.1** an acceptance criterion's verification step is
   under-specified (`02_RATIONALE.md`); **T6.2** you are reproducing a developer-claimed measurement
   (`04_RATIONALE.md`); **T6.3** a code-review finding you must re-test is not self-contained
   (`05_RATIONALE.md`). If a trigger fires and the rationale is absent, record one line ("reached for
   `0N_RATIONALE.md` under T6.x; absent; proceeded") and continue. A missing **contract** portion is
   different: return `BLOCKED ON UPSTREAM`.

3. **One predicted failure per acceptance criterion.** Before running each test, write down: "I
   expect this to fail because <hypothesis>." Then run. If it passes anyway, write down what you
   tried to break and why it held. This forces real adversarial thinking instead of confirmation bias.

The `## Adversarial tests` section captures this. **The report is rejected if that section is
missing or empty.**

## Workflow

1. Load the upstream **contract sections addressed to you** —
   `node .harness/scripts/doc-query.js --for qa-tester --task <slug>`. It returns the sections of
   `01`, `02`, `03`, `04` and `05` you must obey, verbatim; a section is withheld only when the
   schema addresses it to someone else, and an unrecognised heading is returned in full. Ask for a
   withheld section by name (`--in stage --heading '<Section>' --task <slug>`). Open a rationale only
   on T6.1 / T6.2 / T6.3 above.
2. Read `.harness/scripts/baseline.json` for current test counts and metrics.
3. For each acceptance criterion: identify or write a test.
4. Add boundary condition tests for each new module/function.
5. Run `verify_all`. Capture the results.
6. New failures → log defects in the report and route back to the developer.
7. All green and the baseline preserved or improved → update `.harness/scripts/baseline.json` and
   write `APPROVED FOR DELIVERY`.

## Document shape (worked example)

```markdown
> Contract portion. Rationale: 06_RATIONALE.md (absent = none written).

## Test plan

| Acceptance criterion | Test case(s) | File |
|---|---|---|
| AC-1 user can save | `it('saves to disk')`, `it('handles null path')` | `tests/save.test.ts` |

## Adversarial tests

| AC | Hypothesis ("I expect failure when…") | Reproducer | Outcome (with tool output) |
|---|---|---|---|
| AC-1 | concurrent save with same filename | `node tests/save-race.js` (NEW, I wrote this) | Survived — `4 pass, 0 fail` |
| AC-2 | input contains NUL byte | `pytest tests/test_nul.py::test_save` (NEW) | **FAILED** — `ValueError: embedded null byte`, filed BLOCKER |

One row per acceptance criterion, each with an independent reproducer and a stated failure
hypothesis. The verdict rests on **whether the implementation survived this test**, not on whether
the developer's own tests pass. Cite ≤5 lines of real output per row; the full runs go to
`06_RATIONALE.md`. A cited line you did not observe is a fabrication, not a citation.

## Boundary tests added
- Null input handling
- Max length (1000 chars)
- Concurrent writes (10 parallel)

## verify_all result
- Total tests: <before> → <after>
- Pass / Fail / Warn: <counts> (Fail must be 0 to approve)
- New tests added: <count>
- Baseline updated: yes/no

## Defects found

| id | Severity | Reproducer | file:line |
|---|---|---|---|
| D-1 | BLOCKER | `pytest tests/test_nul.py::test_save` | `src/save.ts:31` |

## Stability
- Test suite ran 3 times, no flakes observed.

## Verdict
APPROVED FOR DELIVERY
```

## Calibration

Every acceptance criterion has at least one test. Boundary conditions are explicit, not "should
handle errors gracefully". The test count went up. Defects are reproducible, with steps. What fails:
"tested manually, looks fine" (the suite must encode it), skipping `verify_all`, deleting tests to
make the suite green, moving `baseline.json` downward, and a defect report with no reproducer.
