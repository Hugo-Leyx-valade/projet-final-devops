import { z } from "zod";

export const taskSchema = z.object({
  id: z.number().nonnegative(),
  title: z
    .string()
    .min(1, "Title is required")
    .max(100, "Title must be 100 characters or fewer")
    .trim(),
});

export const taskParamSchema = z.object({
  id: z.coerce.number(),
});

export const createTaskSchema = taskSchema.pick({ title: true });
