import { Task } from "./task";

type Task = {
  id: number;
  title: string;
  done: boolean;
};

type Props = {
  tasks: Array<Task>;
};

export const TasksList = (props:Props) => (
  <ul>
    {props.tasks.map((task) => (
      <Task task={task} />
    ))}
  </ul>
);
