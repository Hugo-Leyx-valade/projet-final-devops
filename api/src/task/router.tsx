import { Hono } from "hono";
import { zValidator } from "@hono/zod-validator";
import { createTaskSchema, taskParamSchema } from "./schemas";
import { Layout } from "../ui/Layout";
import { TasksPage } from "./components/tasks-page";
import { TasksList } from "./components/tasks-list";
import { db } from "../db";
import type { Task } from "./types";

export const taskRouter = new Hono()
  .get("/", async (c) => {
    const tasks = await db<Array<Task>>`SELECT * FROM tasks ORDER BY id`;

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
        return c.html(<p class="error">Invalid task ID.</p>, 400);
      }
    }),
    async (c) => {
      const { id } = c.req.valid("param");

      const [task] = await db<Array<Task>>`SELECT * FROM tasks WHERE id = ${id}`;

      if (!task) {
        return c.html(<p class="error">Task not found.</p>, 404);
      }

      const newDoneAt = task.done_at ? null : new Date();
      await db`UPDATE tasks SET done_at = ${newDoneAt} WHERE id = ${id}`;

      const tasks = await db<Array<Task>>`SELECT * FROM tasks ORDER BY id`;
      
      return c.html(<TasksList tasks={tasks} />);
    }
  )
  .post(
    "/",
    zValidator("form", createTaskSchema, (result, c) => {
      if (!result.success) {
        const errors = result.error.issues.map((i) => i.message);
        return c.html(<TasksPage tasks={[]} errors={errors} />, 422);
      }
    }),
    async (c) => {
      const { title } = c.req.valid("form");

      await db`INSERT INTO tasks (title) VALUES (${title})`;

      const tasks = await db<Array<Task>>`SELECT * FROM tasks ORDER BY id`;

      return c.html(<TasksList tasks={tasks} />);
    }
  );
