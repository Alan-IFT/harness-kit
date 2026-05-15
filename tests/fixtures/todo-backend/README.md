# todo-backend (fixture)

Minimal Python backend todo list. Fixture for `test-real-project`.

## Structure

- `src/main.py` — todo service (no FastAPI dep; pretends)
- `tests/test_main.py` — pytest example

## Convention (for harness-adopt to extract)

- All public functions have type hints.
- Errors are raised as `TodoError`, never bare `Exception`.
- Service functions are pure where possible.
