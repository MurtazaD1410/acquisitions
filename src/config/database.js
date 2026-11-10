import "dotenv/config";

let db, sql;

if (process.env.NODE_ENV === "development") {
  // Use standard PostgreSQL driver for local development
  const { Pool } = await import("pg");
  const { drizzle } = await import("drizzle-orm/node-postgres");
  
  const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
  });
  
  db = drizzle(pool);
  sql = pool; // For compatibility, though we won't use raw queries in development
} else {
  // Use Neon HTTP driver for production
  const { neon } = await import("@neondatabase/serverless");
  const { drizzle } = await import("drizzle-orm/neon-http");
  
  sql = neon(process.env.DATABASE_URL);
  db = drizzle(sql);
}

export { db, sql };
