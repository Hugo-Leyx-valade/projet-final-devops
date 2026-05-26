import type { FC } from "hono/jsx";
import { CreateTaskForm } from "./create-task-form";
import { TasksList } from "./tasks-list";

type Task = {
  id: number;
  title: string;
  done: boolean;
};

type Props = {
  tasks: Array<Task>;
  errors?: Array<string>;
};

export const TasksPage: FC<Props> = (props: Props) => (
  <main>
    <TasksList tasks={props.tasks}  />
    <CreateTaskForm errors={props.errors}/>
  </main>
);
