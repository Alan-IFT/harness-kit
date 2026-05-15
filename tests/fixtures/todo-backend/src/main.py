"""Minimal todo backend. No external deps; pretends to be a FastAPI service."""

from __future__ import annotations

from dataclasses import dataclass, field
from uuid import uuid4


class TodoError(Exception):
    """Raised when a todo operation fails."""


@dataclass
class Todo:
    id: str
    text: str
    done: bool = False


@dataclass
class TodoStore:
    items: list[Todo] = field(default_factory=list)

    def add(self, text: str) -> Todo:
        if not text.strip():
            raise TodoError("text must not be empty")
        todo = Todo(id=str(uuid4()), text=text)
        self.items.append(todo)
        return todo

    def list(self) -> list[Todo]:
        return list(self.items)
