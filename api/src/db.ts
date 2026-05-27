import postgres from "postgres";
import fs from 'fs'
import path from "path";

const requiredEnv = ["DB_HOST", "DB_PORT", "DB_USER", "DB_PASSWORD", "DB_NAME"] as const;

for (const envVar of requiredEnv) {
  if (!process.env[envVar]) {
    throw new Error(`Database configuration error: ${envVar} is not set in .env`);
  }
}

export const db = postgres({
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT),
  username: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  ssl:{
    rejectUnauthorized: true, 
    ca: fs.readFileSync(path.resolve(__dirname, './key.pem')),
  }
});