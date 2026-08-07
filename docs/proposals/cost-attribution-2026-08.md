# Cost attribution — where a pipeline run's spend actually goes

> Produced 2026-08-01 by the `/harness-stream` operator, not by a pipeline run.
> This is the deliverable for pool row **T-21 `stage-cost-attribution`**, which was
> scoped as measurement-only. It took minutes rather than a seven-stage task, which
> is itself the finding that motivated the efficiency wave.

## Method

Per-token rates were read from the current model reference, not recalled. Usage totals
came from an external 30-day usage report over three projects. The two were multiplied
out and checked against the reported bill.

Rates used (first-party, per 1M tokens): input $5.00, output $25.00, cache write
1.25× input, cache read 0.10× input.

## Result

| Component | Tokens | Cost | Share |
|---|---:|---:|---:|
| Cache **read** | 1338.3M | $669.15 | **43.3%** |
| Cache **write** | 86.7M | $541.88 | **35.1%** |
| Output | 13.3M | $332.50 | 21.5% |
| Uncached input | 0.4M | $1.80 | 0.1% |
| **Model total** | | **$1545.32** | |
| **Reported bill** | | **$1570.15** | deviation 1.6% |

A 1.6% deviation across four independently-priced components is close enough to treat
the breakdown as real. The residual is consistent with a small amount of 1-hour-TTL
cache writes (priced at 2× rather than 1.25×) and a negligible cheap-tier tail.

## The finding

**78% of spend is cache traffic, not model intelligence.**

Derived per-call averages over 10,456 calls:

- **127,993 tokens of cached context read per call**
- 1,272 tokens of output produced per call
- A read-to-write ratio of roughly **100:1**

Cost is therefore governed by how much context each call drags in, not by which model
answers. This is the opposite of the intuition that motivated the cost wave.

## Resolving the contradiction that T-21 existed to settle

The external report attributed roughly $36 to the six framework roles while the stream
had directly observed sub-agent token counts of 200k / 248k / 350k / 267k / 297k across
five preceding rows — about 1.5M tokens.

Both numbers are correct; they measure different things. 1.5M tokens at the output rate
is about **$37.5** — the report's per-agent figure tracks sub-agent **output** and excludes
the cached context each sub-agent reads on every call. That excluded context is the
majority of the bill.

## What this changes

**Reducing context per call is the primary lever, and it is risk-free.** It attacks the
43.3% cache-read share directly, and secondarily the 35.1% write share, with no capability
trade-off. The contract/rationale split delivered by T-18 measured a 37.7% reduction in
what a stage-4 run must read (52.9% and 51.7% for stages 5 and 6). Applied against the
cache-read share alone, that is roughly a **16% reduction in total spend** for zero loss
of rigour.

**Model tiering still works, but it is a proportional discount with a capability risk
attached, not a structural fix.** Because cache reads and writes are both priced off the
model's input rate, moving a role to a cheaper tier scales its entire cost line down
together. That is real money — but it buys a percentage off a bill whose size is set by
context volume, and it is the only one of the two levers that can make the pipeline worse
at its job.

Order of operations follows directly: shrink context first, then consider tiering for
roles whose defect-catching record shows they can afford it. The three verification roles
raised essentially every one of the 11+ rollbacks across the preceding wave, and the
debugging category alone cost more over 30 days than the entire model delta being chased
— so they are the last place to economise, not the first.

## Recommended disposition

- **T-21** — complete. No pipeline run needed; this document is the deliverable.
- **T-22 `stage-model-tiering`** — still worth doing, with its priority corrected from
  "primary cost lever" to "secondary, after context reduction". Its existing constraint
  that the verification roles stay at full depth unless positive evidence says otherwise
  is reinforced by this data, not weakened.
- **A new candidate, not scheduled**: nothing currently measures per-call context volume.
  The 128K figure came from dividing an external report by a call count. A cheap in-repo
  measurement would let context reduction be verified rather than projected.
