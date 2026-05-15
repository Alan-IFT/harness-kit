"""Tests for the todo store."""

import pytest

from src.main import TodoError, TodoStore


def test_add_appends_to_list() -> None:
    store = TodoStore()
    todo = store.add("buy milk")
    assert todo.text == "buy milk"
    assert not todo.done
    assert len(store.list()) == 1


def test_add_rejects_empty_text() -> None:
    store = TodoStore()
    with pytest.raises(TodoError):
        store.add("   ")
