// Minimal server. Real code would import express, but the fixture has no deps.

export interface Todo {
  id: string;
  text: string;
  done: boolean;
}

const store: Todo[] = [];

export function listTodos(): Todo[] {
  return [...store];
}

export function addTodo(text: string): Todo {
  const todo: Todo = { id: crypto.randomUUID(), text, done: false };
  store.push(todo);
  return todo;
}
