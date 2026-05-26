import postgres from "postgres";

const dbUrl = process.env.DATABASE_URL;

if (!dbUrl) {
  throw new Error("db url not set");
}

export const db = postgres(dbUrl);
