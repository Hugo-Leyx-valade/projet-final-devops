import type { FC } from "hono/jsx";
import { CreateTaskForm } from "./create-task-form";
import { Task } from "./task";

type Task = {
  id: number;
  title: string;
  done: boolean;
};

type Props = {
  tasks: Array<Task>;
};

export const TasksList: FC<Props> = (props) => (
  <ul>
    {props.tasks.map((task) => (
      <Task task={task} />
    ))}
  </ul>
);
