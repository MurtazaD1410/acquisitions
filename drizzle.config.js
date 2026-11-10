import "dotenv/config";

// Use different drivers based on environment
const isDevelopment = process.env.NODE_ENV === "development";

export default {
  schema: "./src/models/*.js",
  out: "./drizzle",
  dialect: "postgresql",
  driver: isDevelopment ? "pg" : "neon-http",
  dbCredentials: {
    url: process.env.DATABASE_URL,
  },
};
