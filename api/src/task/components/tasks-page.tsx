import type { Task } from "../types";
import { CreateTaskForm } from "./create-task-form";
import { TasksList } from "./tasks-list";

type Props = {
  tasks: Array<Task>;
  errors?: Array<string>;
};

export const TasksPage = (props: Props) => (
  <main>
    <TasksList tasks={props.tasks}  />
    <CreateTaskForm errors={props.errors}/>
  </main>
);
