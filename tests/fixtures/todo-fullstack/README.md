# todo-fullstack (fixture)

This is a fixture, not a real project. It exists to give `test-real-project` a
project shape to adopt Harness into.

## Structure

- `src/server.ts` — minimal Express-ish backend
- `src/client.tsx` — minimal React-ish frontend page
- `tests/server.test.ts` — example test (uses node:test)

## Convention (for harness-adopt to extract)

- Components use named exports, no default exports.
- Backend routes return JSON envelopes `{ ok: true, data: ... }`.
- Tests live next to source under `tests/`.
