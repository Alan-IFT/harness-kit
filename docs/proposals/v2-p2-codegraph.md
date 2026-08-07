# v2 P2 — CodeGraph wired, but it cannot see this repo

> Measured 2026-08-07 on branch `v2-migration`, CodeGraph v1.5.0 installed from npm.
> The wiring is done and correct. The acceptance criteria are not reachable on harness-kit,
> for a reason the brief could not have known.

## What was verified

Every §4.1 fact in the brief that mattered checked out:

| Claim | Result |
|---|---|
| v1.5.0, zero LLM / embedding / external service | confirmed |
| local directories only, no repo fetching | confirmed — `codegraph init [path]` is the only entry |
| SQLite + WAL under `<project>/.codegraph/` | confirmed |
| 283 MB install | **exactly 283 MB** (npm package itself is only 664 KB; the rest is native kernel + WASM grammars) |
| telemetry on by default | confirmed — the CLI printed the notice on first run |
| MCP exposes only `explore` unless `CODEGRAPH_MCP_TOOLS` is set | confirmed — default list is `codegraph_explore` alone; setting the env var opened all 7 |
| `.mcp.json` belongs at the plugin root | done; **not** in `.claude-plugin/` |

`codegraph install` was **not** run, per §4.3 — it rewrites `~/.claude.json`,
`~/.claude/settings.json` and `~/.claude/CLAUDE.md`, which a plugin has no business doing.

MCP tool names for a subagent's `tools:` field are `mcp__codegraph__codegraph_<name>`,
confirmed against a live `tools/list` response.

## What fails: the language map

**CodeGraph v1.5.0 indexes neither bash nor PowerShell.**

Tested rather than inferred. A directory holding three files:

| file | indexed |
|---|---|
| `ctl.py` | yes — 4 nodes, 5 edges |
| `lib.sh` | **no** |
| `lib2.ps1` | **no** |

`tree-sitter-bash.wasm` *does* ship inside the package, arriving through the generic
`tree-sitter-wasms` dependency, and PowerShell has no grammar at all. Grammar presence is
not language support — which is precisely why this was measured. Had it been inferred from
the shipped `.wasm` list, bash would have looked supported.

## What that means for harness-kit

Indexing the repo produces **6 files, 26 nodes, 39 edges from 612 tracked files** in 1.3 s,
DB 192 KB. All six are `tests/fixtures/` sample apps (Python, TypeScript, TSX) plus one
JSON mock. The repo's actual moving parts — 33 `.sh` and 32 `.ps1`, 1.28 MB — are invisible.

harness-kit is 487 markdown files (7.8 MB) plus 65 shell scripts. It is close to a
worst-case shape for a code-graph tool: the prose is not code, and the code is in the two
languages this tool does not read.

**So P2's acceptance criterion — "`codegraph_explore` replaces whole-repo grep" — cannot be
evaluated here, and the P0 control set's 10 CODE items cannot gate it.** They were all
anchored in `guard-rm.sh`, `verify_all.sh` and `hook-spec.sh`.

## The wiring is still worth keeping

harness-kit is a plugin applied to *other* codebases. Its own fixtures are TypeScript, TSX
and Python — all confirmed indexable — which is a reasonable guess at the shape of the
projects it gets pointed at. `.mcp.json` therefore ships the capability to those projects
at a cost of one stdio subprocess and no behaviour change here.

What it does **not** do is help the agents that develop harness-kit itself, which is what
the migration brief assumed when it put CodeGraph in the "code structure" slot.

## Decisions needed

1. **Name a target project in an indexed language** to serve as P2's acceptance bed, or
   accept that P2 ships as unvalidated capability wiring. Until one is named, P2 has no
   instrument, and the `≥6×` bar's CodeGraph component has no evidence behind it.
2. **Do not spend P2 effort on harness-kit's own grep paths.** The remaining lever for
   this repo's own agents is the memory layer (P3) and section addressing, not a code graph.
3. `.codegraph/` is gitignored. The local index of this repo is harmless but near-useless;
   `codegraph uninit .` removes it if the 192 KB and the file watcher are unwanted.
