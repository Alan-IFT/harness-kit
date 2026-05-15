import { test } from "node:test";
import assert from "node:assert";
import { addTodo, listTodos } from "../src/server.js";

test("addTodo appends to list", () => {
  const before = listTodos().length;
  addTodo("buy milk");
  assert.equal(listTodos().length, before + 1);
});
