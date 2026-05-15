// Minimal client component. Pretends to be React without the dependency.

export interface TodoItemProps {
  text: string;
  done: boolean;
  onToggle: () => void;
}

export function TodoItem(_props: TodoItemProps) {
  // placeholder render
  return null;
}
