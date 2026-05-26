import { Hono } from "hono";
import { taskRouter } from "./task/router";

const app = new Hono().route("/tasks", taskRouter).get("/", (c) => {
  return c.redirect("/tasks");
});

export default {
  port: 3000,
  fetch: app.fetch,
};
