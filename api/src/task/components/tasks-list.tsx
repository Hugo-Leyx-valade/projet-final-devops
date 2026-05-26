import type { Task as TaskType } from "../types";
import { Task } from "./task";

type Props = {
  tasks: Array<TaskType>;
};

export const TasksList = (props:Props) => (
  <ul>
    {props.tasks.map((task) => (
      <Task task={task} />
    ))}
  </ul>
);
