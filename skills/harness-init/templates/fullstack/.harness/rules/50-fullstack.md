---

## Fullstack-specific rules

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
