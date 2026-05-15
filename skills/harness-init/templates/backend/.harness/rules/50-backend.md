---

## Backend-specific rules

### Partition Developers (v0.5+)

This project uses **partition Developer agents** when initialized in partitioned mode:

- `dev-api` owns route handlers / controllers / request-response schemas / middleware
- `dev-services` owns business logic / domain models / orchestration / queues
- `dev-db` owns schema / migrations / ORM models / repositories / seeds

The Solution Architect must include a `## Partition assignment` section in every
`02_SOLUTION_DESIGN.md`. The PM Orchestrator dispatches partitions in dependency
order (typically dev-db → dev-services → dev-api). The generic `developer` remains
as a fallback for ambiguous tasks. See `.harness/agents/dev-*.md` for each
partition's owned paths and contract.

If you initialized with single Developer mode, this section is informational only
and the generic `developer` agent handles all code changes.

### API
- Every endpoint has a typed schema (OpenAPI / Pydantic / Zod / Go struct tags).
- Response envelopes are consistent across endpoints (use a shared error format).
- Idempotent operations are marked as such (PUT / DELETE / specific POSTs with idempotency keys).

### Database
- All schema changes via migrations. Never raw SQL in code paths that "happen to alter schema".
- Migrations reversible; irreversible ones need user confirmation.
- N+1 query: any loop that queries the DB → batch or join, no exceptions.

### Errors / Logs
- Errors thrown across module boundaries are typed (custom error classes).
- Logs are structured (JSON for production), with request ID context.
- No `print` / `console.log` left in code; use the logger.

### Security
- Input validation at every API entry point. Use the schema; don't trust client.
- Secrets via env, never in code or config files.
- Auth checks at the route layer **and** at the service layer (defense in depth).

### Performance
- Long operations behind a queue, not blocking HTTP.
- DB indexes on every column used in WHERE / JOIN.
- Sensible default timeouts on every outbound call.
