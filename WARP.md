# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

Node.js/Express REST API for user authentication and acquisitions management. Uses PostgreSQL via Neon (serverless) with Drizzle ORM for database operations.

**Tech Stack:**
- Runtime: Node.js (ES modules)
- Framework: Express 5
- Database: PostgreSQL (Neon serverless)
- ORM: Drizzle ORM
- Validation: Zod
- Auth: JWT + bcrypt
- Logging: Winston
- Security: Helmet, CORS

## Development Commands

### Running the Application
```bash
npm run dev           # Start server with --watch (auto-reload on file changes)
```
The server runs on port 3000 by default (configurable via `PORT` env var).

### Code Quality
```bash
npm run lint          # Run ESLint
npm run lint:fix      # Auto-fix ESLint issues
npm run format        # Format code with Prettier
npm run format:check  # Check formatting without changes
```

### Database Operations
```bash
npm run db:generate   # Generate migration files from schema changes
npm run db:migrate    # Apply pending migrations to database
npm run db:studio     # Open Drizzle Studio (visual database browser)
```

**Important:** After modifying any file in `src/models/*.js`, run `npm run db:generate` to create migration files, then `npm run db:migrate` to apply them.

## Architecture & Code Structure

### Import Aliases (Subpath Imports)
The project uses Node.js subpath imports defined in `package.json` for cleaner imports:
- `#config/*` → `./src/config/*`
- `#models/*` → `./src/models/*`
- `#routes/*` → `./src/routes/*`
- `#services/*` → `./src/services/*`
- `#utils/*` → `./src/utils/*`
- `#middleware/*` → `./src/middleware/*`
- `#controllers/*` → `./src/controllers/*`
- `#validations/*` → `./src/validations/*`

**Always use these aliases** when importing from these directories.

### Application Entry Flow
1. **src/index.js** - Entry point, loads environment variables and imports server
2. **src/server.js** - Creates HTTP server and listens on configured port
3. **src/app.js** - Express application setup with middleware and route registration

### Request Flow Pattern
The codebase follows a layered architecture:

**Route → Controller → Service → Model**

1. **Routes** (`src/routes/*.js`): Define API endpoints and HTTP methods
2. **Controllers** (`src/controllers/*.js`): Handle HTTP request/response, validation, and error formatting
3. **Services** (`src/services/*.js`): Business logic, database operations via Drizzle
4. **Models** (`src/models/*.js`): Drizzle ORM schema definitions

**Validation Layer:** Zod schemas in `src/validations/*.js` validate request data before it reaches business logic.

### Database Layer
- **Connection**: `src/config/database.js` exports `db` (Drizzle instance) and `sql` (Neon client)
- **Models**: Drizzle schema definitions use `pgTable` from `drizzle-orm/pg-core`
- **Queries**: Use Drizzle ORM query builder (not raw SQL) - see `src/services/auth.service.js` for examples
- **Migrations**: Stored in `drizzle/` directory, managed by Drizzle Kit

### Logging Strategy
Winston logger configured in `src/config/logger.js`:
- **Production**: Writes to `logs/error.log` and `logs/combined.log` (JSON format)
- **Development**: Also outputs to console with colors
- **HTTP Requests**: Morgan middleware pipes to Winston logger

Use `logger.info()`, `logger.error()`, `logger.warn()` for application logging.

### Utility Modules
- **src/utils/jwt.js**: JWT token signing and verification (uses `JWT_SECRET` env var)
- **src/utils/cookies.js**: Cookie management with secure defaults (httpOnly, sameSite)
- **src/utils/format.js**: Format Zod validation errors for API responses

### Authentication Flow
Currently implements signup endpoint (`POST /api/auth/sign-up`):
1. Request validated against Zod schema
2. Check if user exists (by email)
3. Hash password with bcrypt
4. Insert user into database
5. Generate JWT token
6. Set httpOnly cookie
7. Return user data (excluding password)

**Note:** Sign-in and sign-out endpoints are stubbed but not yet implemented.

## Environment Configuration

Required environment variables (see `.env.example`):
```
PORT=3000                    # Server port
NODE_ENV=development         # Environment (development/production)
LOG_LEVEL=info              # Winston log level
DATABASE_URL=               # Neon PostgreSQL connection string
JWT_SECRET=                 # Secret for JWT signing (MUST be set in production)
```

## Code Style Guidelines

### ESLint Rules
- Use ES6+ features (no `var`, prefer `const`, arrow functions)
- Double quotes for strings
- 2-space indentation
- Unix line endings
- Semicolons required
- Unused vars prefixed with `_` are allowed

### Prettier Configuration
- 80 character line width
- Semicolons: true
- Single quotes: false (use double quotes)
- Arrow function parens: avoid when possible

## API Endpoints

**Base URL:** `http://localhost:3000`

- `GET /` - Hello message
- `GET /health` - Health check with uptime
- `GET /api` - API status
- `POST /api/auth/sign-up` - User registration
- `POST /api/auth/sign-in` - Login (not implemented)
- `POST /api/auth/sign-out` - Logout (not implemented)

## Database Schema

**Users Table:**
- `id` (serial, primary key)
- `name` (varchar 256, required)
- `email` (varchar 256, unique, required)
- `password` (varchar 256, required, hashed)
- `role` (varchar 50, default 'user', enum: 'user'|'admin')
- `created_at` (timestamp, default now)
- `updated_at` (timestamp, default now)

## Key Development Patterns

### Adding New Features
1. Define Drizzle model schema in `src/models/`
2. Run `npm run db:generate` and `npm run db:migrate`
3. Create Zod validation schema in `src/validations/`
4. Implement business logic in `src/services/`
5. Create controller in `src/controllers/`
6. Register routes in `src/routes/`
7. Import and mount router in `src/app.js`

### Error Handling
- Controllers use try-catch blocks
- Pass errors to Express error handler via `next(error)`
- Log errors with Winston logger
- Return appropriate HTTP status codes (400, 409, 500, etc.)
- Use Zod validation and format errors with `formatValidationError()`

### Security Considerations
- Passwords always hashed with bcrypt (salt rounds: 10)
- JWT tokens stored in httpOnly cookies (not localStorage)
- Helmet middleware enabled for security headers
- CORS enabled (configure origins for production)
- Environment variables for sensitive data (never commit `.env`)
