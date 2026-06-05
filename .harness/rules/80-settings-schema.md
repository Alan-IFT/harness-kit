# 80-settings-schema.md — `.claude/settings.json` editing contract

**When to read**: before editing `.claude/settings.json`, `skills/harness-init/templates/common/.claude/settings.json.tmpl`, or any other `.claude/settings.json` instance this repo ships or maintains.

## Why this file exists

`.claude/settings.json` has broken schema validation twice in two consecutive minor releases:

- **v0.17.2** — doc keys (`_doc_sync_hook`, `_guard_hook`) lived inside the `hooks` object, but the upstream schema declares `hooks` as `additionalProperties: false`. Only real Claude Code hook event names are valid keys there. Fix moved both keys to the root object (`additionalProperties: true`).
- **v0.18.2** — `$schema` URL omitted the `.json` suffix (`https://json.schemastore.org/claude-code-settings`). The non-suffix form 301-redirects to a URL serving `application/octet-stream`, which many JSON-schema-aware editors (VS Code, JetBrains) silently refuse to load. The whole file is then flagged as invalid even though the JSON parses. Fix used the canonical `.json` form.

Both bugs share the same shape: a small textual change passes JSON-parse but breaks schema validation, and no `verify_all` check existed to catch it. The class of bug is **invisible to the writer** because the editor warning is subtle (a single squiggle), the file loads at runtime fine for the writer's session, and the next contributor inherits a broken file with no signal.

## The rule

**Before any edit** to `.claude/settings.json` or its template:

1. **Consult the canonical schema** — fetch the live definition, never recall it from memory or training data:
   - Preferred: `context7` MCP tool, library `Claude Code` → query the current settings.json schema.
   - Fallback: `WebFetch` against `https://www.schemastore.org/claude-code-settings.json` (the URL the file's own `$schema` points to).
   - Check at minimum: (a) is the field name a real top-level key, (b) for keys under `hooks`, is the event name in the schema's allowed enum, (c) does the proposed value match the field's type.
2. **Make the edit.**
3. **Run `.harness/scripts/verify_all`** — the `J.1` check parses the file, validates the `$schema` URL is the canonical `.json` form, and rejects any key inside `hooks` that is not a real event name. Both failure modes above would have been caught at the gate, not in production.

## What `J.1` enforces (machine-readable contract)

`J.1` fails when **any** of these are true for `.claude/settings.json` OR `skills/harness-init/templates/common/.claude/settings.json.tmpl`:

- File exists but does not parse as JSON.
- `$schema` is present but is not exactly `https://json.schemastore.org/claude-code-settings.json`.
- A key inside the top-level `hooks` object is not in the upstream schema's hook event enum (see the `$validHookEvents` list in `.harness/scripts/verify_all.ps1` J.1 — kept in lockstep with the bash twin).

The check is pure shell + grep — no `jq`/`python3` dependency, since the Git-for-Windows MSYS shell lacks both.

## Maintenance

- When Anthropic adds a new hook event upstream, update **both** the PS list (`$validHookEvents` in `.harness/scripts/verify_all.ps1`) and the bash list (`j1_valid_hook_events` in `.harness/scripts/verify_all.sh`) in the same commit. Lockstep is enforced visually (no test asserts it); a drift will FAIL J.1 in whichever twin is stale on a project that uses the new event.
- When the upstream `$schema` URL changes, update the `$canonicalSchema` / `j1_canonical` constants in both twins **and** the `$schema` field in `.claude/settings.json` + the `.tmpl` in the same commit.
- Underscore-prefixed doc keys (`_comment`, `_doc_sync_hook`, `_guard_hook`) are allowed at root (root is `additionalProperties: true`) but **never** inside `hooks` (which is `additionalProperties: false`). If you want to annotate a hook entry, put the comment at the root object — not nested in the hook config.

## Cross-references

- Insight that records the recurrence: see `.harness/insight-index.md` (entry dated 2026-05-23 about settings.json schema validation).
- Template that ships to user projects: `skills/harness-init/templates/common/.claude/settings.json.tmpl` — both files move together.
