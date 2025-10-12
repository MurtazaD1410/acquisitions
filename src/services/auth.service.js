import logger from "#config/logger.js";
import bcrypt from "bcrypt";
import { db } from "#config/database.js";
import { eq } from "drizzle-orm";
import { users } from "#models/user.model.js";

export const hashPassword = async password => {
  try {
    return await bcrypt.hash(password, 10);
  } catch (error) {
    logger.error("Error hasing the password", error);
    throw new Error("Error hashing");
  }
};

export const comparePassword = async (password, hashedPassword) => {
  try {
    return await bcrypt.compare(password, hashedPassword);
  } catch (error) {
    logger.error("Error comparing password", error);
    throw new Error("Error comparing password");
  }
};

export const createUser = async ({ name, email, role = "user", password }) => {
  try {
    const existingUser = await db
      .select()
      .from(users)
      .where(eq(users.email, email))
      .limit(1);

    if (existingUser.length > 0) {
      throw new Error("User with this email already exists");
    }

    const password_hash = await hashPassword(password);
    const [newUser] = await db
      .insert(users)
      .values({ name, email, password: password_hash, role })
      .returning({
        id: users.id,
        name: users.name,
        email: users.email,
        role: users.role,
        created_at: users.created_at,
      });

    logger.info(`User ${newUser.email} created successfully`);
    return newUser;
  } catch (error) {
    logger.error("Failed to create User", error);
    throw error;
  }
};

export const authenticateUser = async ({ email, password }) => {
  try {
    const [existingUser] = await db
      .select()
      .from(users)
      .where(eq(users.email, email))
      .limit(1);

    if (!existingUser) {
      throw new Error("Invalid email or password");
    }

    const isPasswordValid = await comparePassword(password, existingUser.password);

    if (!isPasswordValid) {
      throw new Error("Invalid email or password");
    }

    logger.info(`User ${existingUser.email} authenticated successfully`);
    
    // Return user without password
    return {
      id: existingUser.id,
      name: existingUser.name,
      email: existingUser.email,
      role: existingUser.role,
      created_at: existingUser.created_at,
    };
  } catch (error) {
    logger.error("Failed to authenticate user", error);
    throw error;
  }
};
