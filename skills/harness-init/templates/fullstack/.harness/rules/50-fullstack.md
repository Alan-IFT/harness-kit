---

## Fullstack-specific rules

### Partition Developers (v0.4+)

This project uses **partition Developer agents** when initialized in partitioned mode:

- `dev-frontend` owns UI / pages / components / client state
- `dev-backend` owns API routes / services / server-side logic
- `dev-db` owns schema / migrations / ORM models

The Solution Architect must include a `## Partition assignment` section in every
`02_SOLUTION_DESIGN.md`. The PM Orchestrator dispatches partitions in dependency order
(typically dev-db → dev-backend → dev-frontend). A generic `developer` remains as a
fallback for ambiguous tasks. See `.harness/agents/dev-*.md` for each partition's
owned paths and contract.

If you initialized with single Developer mode, this section is informational only
and the generic `developer` agent handles all code changes.

### API contracts
- Every backend endpoint has a typed schema (OpenAPI / tRPC / GraphQL). No untyped routes.
- Frontend never duplicates types from backend; either generated from OpenAPI or imported via a shared package.
- Breaking API change → write a migration note in `docs/features/<task>/MIGRATION.md`.

### Database
- Never edit production DB directly. All changes via migrations.
- Migrations must be reversible. If irreversible (e.g. DROP COLUMN with data), require explicit user confirmation.
- Migration files are append-only — never edit a merged migration.

### Frontend
- No inline styles for layout; use the project's styling system.
- Components > 200 lines must be split.
- Forms must validate both client-side (UX) and server-side (security).

### Cross-cutting
- Loading states and error states are part of "done", not optional.
- Authenticated routes must verify auth on **both** frontend and backend.
- Environment variables: define in `.env.example`, never commit actual `.env`.
