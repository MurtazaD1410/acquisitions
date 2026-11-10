# 🐳 Docker Setup for Acquisitions API

This guide explains how to run the Acquisitions API using Docker with different database configurations for development and production environments.

## 📋 Prerequisites

- [Docker](https://docs.docker.com/get-docker/) (v20.10+)
- [Docker Compose](https://docs.docker.com/compose/install/) (v2.0+)
- [Neon Cloud Database](https://neon.com) account (for production)

## 🏗️ Architecture Overview

### Development Environment
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Your App      │───▶│   Neon Local     │───▶│   PostgreSQL    │
│  (Port 3000)    │    │  (Port 5432)     │    │   (In Memory)   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

### Production Environment
```
┌─────────────────┐    ┌──────────────────┐
│   Your App      │───▶│   Neon Cloud     │
│  (Port 3000)    │    │  (neon.tech)     │
└─────────────────┘    └──────────────────┘
```

---

## 🚀 Quick Start

### Development with Neon Local

1. **Start the development environment:**
   ```bash
   npm run docker:dev
   ```

2. **Access your application:**
   - API: http://localhost:3000
   - Health check: http://localhost:3000/health
   - Database UI (Adminer): http://localhost:8080

3. **Stop the development environment:**
   ```bash
   npm run docker:dev:down
   ```

### Production with Neon Cloud

1. **Configure production environment:**
   ```bash
   cp .env.production .env.prod.local
   # Edit .env.prod.local with your actual Neon Cloud URL and secrets
   ```

2. **Start production services:**
   ```bash
   # Load environment variables and start
   export $(cat .env.prod.local | xargs) && npm run docker:prod
   ```

3. **Stop production services:**
   ```bash
   npm run docker:prod:down
   ```

---

## 🔧 Environment Configuration

### Neon Configuration Setup

**Run the configuration helper script:**
```bash
./scripts/setup-neon-config.sh
```

This script will help you:
- Extract current configuration from `.env`
- Show where to find your Neon API keys and IDs
- Create a production environment file
- Validate your configuration

### Required Neon Configuration

You'll need these values from your [Neon Console](https://console.neon.tech/):

| Variable | Where to Find | Example |
|----------|---------------|----------|
| `DATABASE_URL` | Project Dashboard → Connection Details | `postgresql://user:pass@ep-xxx.region.aws.neon.tech/db?sslmode=require` |
| `NEON_API_KEY` | Account Settings → API Keys | `neon_api_key_xxx...` |
| `NEON_PROJECT_ID` | Project URL or Settings | `proj_xxx...` |
| `NEON_BRANCH_ID` | Branches tab | `br_xxx...` |
| `ARCJET_KEY` | [Arcjet Console](https://app.arcjet.com/) | `ajkey_xxx...` |

### Development Environment (`.env.development`)

```bash
NODE_ENV=development
PORT=3000
LOG_LEVEL=debug

# Local PostgreSQL (simulates Neon Local)
DATABASE_URL=postgresql://neondb_owner:localdb@neon-local:5432/neondb

# Development secrets (not used with real APIs)
JWT_SECRET=dev-secret-key-change-in-production-please
NEON_API_KEY=dev-api-key-not-used-in-local
NEON_PROJECT_ID=dev-project-id
NEON_BRANCH_ID=dev-branch-id
ARCJET_KEY=disabled-in-development
```

### Production Environment (`.env.production`)

```bash
NODE_ENV=production
PORT=3000
LOG_LEVEL=info

# Neon Cloud Database - REPLACE WITH YOUR ACTUAL VALUES
DATABASE_URL=postgresql://user:password@ep-xxxxx.us-east-1.aws.neon.tech/dbname?sslmode=require

# Production secrets - MUST BE SET TO REAL VALUES
JWT_SECRET=your-super-secure-random-jwt-secret-here
NEON_API_KEY=neon_api_key_xxxxxxxxxxxxxxxxxxxxx
NEON_PROJECT_ID=proj_xxxxxxxxxxxxxxxxxxxxx
NEON_BRANCH_ID=br_xxxxxxxxxxxxxxxxxxxxx
ARCJET_KEY=ajkey_xxxxxxxxxxxxxxxxxxxxx

# Optional: CORS origins for production
CORS_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
```

---

## 📦 Docker Services

### Development Services (`docker-compose.dev.yml`)

| Service | Description | Port | Purpose |
|---------|-------------|------|---------|
| `neon-local` | Neon Local PostgreSQL proxy | 5432 | Local database for development |
| `app` | Node.js application | 3000 | Your API server |
| `adminer` | Database management UI | 8080 | Database administration |

### Production Services (`docker-compose.prod.yml`)

| Service | Description | Port | Purpose |
|---------|-------------|------|---------|
| `app` | Node.js application | 3000 | Your API server |
| `nginx` | Reverse proxy | 80/443 | Load balancing, SSL, rate limiting |

---

## 🛠️ Database Operations

### Development Database (Neon Local)

**Run migrations:**
```bash
# Inside the running container
docker-compose -f docker-compose.dev.yml exec app npm run db:migrate

# Or from host (if DATABASE_URL points to localhost:5432)
npm run db:migrate
```

**Generate migrations:**
```bash
docker-compose -f docker-compose.dev.yml exec app npm run db:generate
```

**Open Drizzle Studio:**
```bash
docker-compose -f docker-compose.dev.yml exec app npm run db:studio
```

### Production Database (Neon Cloud)

**Run migrations in production:**
```bash
docker-compose -f docker-compose.prod.yml exec app npm run db:migrate
```

---

## 🔍 Monitoring & Debugging

### View Logs

**Development logs:**
```bash
# All services
docker-compose -f docker-compose.dev.yml logs -f

# Specific service
docker-compose -f docker-compose.dev.yml logs -f app
docker-compose -f docker-compose.dev.yml logs -f neon-local
```

**Production logs:**
```bash
docker-compose -f docker-compose.prod.yml logs -f
```

### Health Checks

Both environments include health checks:

```bash
# Check application health
curl http://localhost:3000/health

# Check Docker service health
docker-compose ps
```

### Database Connection Testing

**Test Neon Local (Development):**
```bash
# Connect to database
docker-compose -f docker-compose.dev.yml exec neon-local psql -U neondb_owner -d neondb

# Or from host
psql "postgresql://neondb_owner:localdb@localhost:5432/neondb"
```

---

## 🔐 Security Considerations

### Development
- Uses default credentials (safe for local development)
- Debug logging enabled
- No SSL required
- CORS allows all origins

### Production
- **MUST** set strong JWT_SECRET
- **MUST** use actual Neon Cloud DATABASE_URL
- Structured logging (JSON format)
- Nginx with rate limiting and security headers
- CORS restricted to specific origins

---

## 📊 Performance Optimization

### Development
- Source code mounted as volume for hot reload
- Separate volume for node_modules (faster builds)
- Postgres data persisted in Docker volume

### Production
- Multi-stage builds for smaller images
- Non-root user for security
- Nginx reverse proxy for:
  - Rate limiting (10 req/s general, 5 req/s auth)
  - Gzip compression
  - Security headers
  - SSL termination (when configured)

---

## 🚨 Troubleshooting

### Common Issues

**1. Port conflicts:**
```bash
# Check if ports are in use
lsof -i :3000
lsof -i :5432

# Use different ports
APP_PORT=3001 npm run docker:dev
```

**2. Database connection errors:**
```bash
# Check if Neon Local is healthy
docker-compose -f docker-compose.dev.yml ps

# Restart services
docker-compose -f docker-compose.dev.yml restart
```

**3. Permission issues:**
```bash
# Fix log directory permissions
sudo chown -R $USER:$USER ./logs
```

**4. Build issues:**
```bash
# Clean rebuild
docker-compose -f docker-compose.dev.yml down -v
docker system prune -f
npm run docker:dev
```

### Environment Debugging

**Check environment variables:**
```bash
docker-compose -f docker-compose.dev.yml exec app env | grep DATABASE
docker-compose -f docker-compose.dev.yml exec app node -e "console.log(process.env.DATABASE_URL)"
```

---

## 🚀 Deployment

### Local Testing Production Build

```bash
# Build production image
npm run docker:build

# Test production locally (with Neon Cloud URL)
export DATABASE_URL="your-neon-cloud-url"
export JWT_SECRET="your-production-secret"
npm run docker:prod
```

### Deploy to Production

**Using Docker Swarm:**
```bash
docker stack deploy -c docker-compose.prod.yml acquisitions-api
```

**Using cloud providers:**
- Replace environment variables with actual production values
- Ensure DATABASE_URL points to your Neon Cloud database
- Set up SSL certificates for HTTPS
- Configure monitoring and log aggregation

---

## 📚 Additional Resources

- [Neon Local Documentation](https://neon.com/docs/local/neon-local)
- [Neon Cloud Documentation](https://neon.com/docs)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Node.js in Docker Best Practices](https://github.com/nodejs/docker-node/blob/main/docs/BestPractices.md)

---

## 🤝 Contributing

When working with Docker:

1. **Always test both environments:**
   ```bash
   npm run docker:dev    # Test development setup
   npm run docker:prod   # Test production setup (with proper env vars)
   ```

2. **Update documentation** if you change Docker configuration

3. **Test migrations** in both Neon Local and Neon Cloud environments

4. **Verify environment variables** are properly configured for both dev and prod