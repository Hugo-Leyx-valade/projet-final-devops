import { Hono } from "hono";
import { zValidator } from "@hono/zod-validator";
import { createTaskSchema, taskParamSchema } from "./schemas";
import { Layout } from "../ui/Layout";
import { TasksPage } from "./components/tasks-page";
import { TasksList } from "./components/tasks-list";

const tasks = [
  { id: 1, title: "Provision Terraform infra", done: false },
  { id: 2, title: "Configure Ansible roles", done: false },
  { id: 3, title: "Run Molecule tests", done: false },
];

export const taskRouter = new Hono()
.get("/", (c) => {
  return c.html(
    <Layout title="DevOps Project">
      <TasksPage tasks={tasks} />
    </Layout>
  );
})
.post(
  "/:id/toggle",
  zValidator("param", taskParamSchema, (result, c) => {
    if (!result.success) {
      return c.html(<p class="error">Invalid task ID.</p>, 400)
    };
  }),
  (c) => {
    const params = c.req.valid("param");

    const task = tasks.find((t) => t.id === params.id);

    if (!task)  {
       return c.html(<p class="error">Task not found.</p>, 404)
    };

    task.done = !task.done;
    
    return c.html(<TasksList tasks={tasks} />);
  }
).post(
  "/",
  zValidator("form", createTaskSchema, (result, c) => {
    if (!result.success) {
      const errors = result.error.issues.map((i) => i.message);
      return c.html(<TasksPage tasks={tasks} errors={errors} />, 422);
    }
  }),
  (c) => {
    const form = c.req.valid("form");

    tasks.push({ id: Date.now(), title:form.title, done: false });

    return c.html(<TasksList tasks={tasks} />);
  }
);