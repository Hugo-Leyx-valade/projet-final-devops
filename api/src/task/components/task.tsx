type Task = {
  id: number;
  title: string;
  done: boolean;
};

type Props = {
  task: Task;
};

export const Task = (props: Props) => {
  return (
    <li class={props.task.done ? "done" : ""}>
      <button
        hx-post={`/tasks/${props.task.id}/toggle`}
        hx-target="closest ul"
        hx-swap="outerHTML"
      >
        {props.task.done ? "Undo" : "Done"}
      </button>
      <span>{props.task.title}</span>
    </li>
  );
};
