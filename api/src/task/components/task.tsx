import type { Task as TaskType } from "../types";

type Props = {
  task: TaskType;
};

export const Task = (props: Props) => {
  const isDone = props.task.done_at !== null;
  return (
    <li class={isDone ? "done" : ""}>
      <button
        hx-post={`/tasks/${props.task.id}/toggle`}
        hx-target="closest ul"
        hx-swap="outerHTML"
      >
        {isDone ? "Undo" : "Done"}
      </button>
      <span>{props.task.title}</span>
      {isDone && (
        <time dateTime={props.task.done_at!.toISOString()}>
          {props.task.done_at!.toLocaleString()}
        </time>
      )}
    </li>
  );
};
