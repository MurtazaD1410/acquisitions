#!/bin/bash

# Development setup script for Acquisitions API with Neon Local
# This script helps developers quickly set up the development environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE} Acquisitions API - Development Setup${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
}

print_step() {
    echo -e "${GREEN}➤ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_step "Checking prerequisites..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Setup environment files
setup_env() {
    print_step "Setting up environment files..."
    
    if [ ! -f .env.development ]; then
        print_warning ".env.development not found, it should have been created already"
        exit 1
    fi
    
    print_success "Environment files ready"
}

# Start services
start_services() {
    print_step "Starting Neon Local and application services..."
    
    # Stop any existing services
    docker-compose -f docker-compose.dev.yml down -v 2>/dev/null || true
    
    # Start services
    docker-compose -f docker-compose.dev.yml up --build -d
    
    print_step "Waiting for services to be ready..."
    sleep 10
    
    # Check if services are running
    if ! docker-compose -f docker-compose.dev.yml ps | grep -q "Up"; then
        print_error "Failed to start services. Check logs with: docker-compose -f docker-compose.dev.yml logs"
        exit 1
    fi
    
    print_success "Services started successfully"
}

# Run database migrations
run_migrations() {
    print_step "Running database migrations..."
    
    # Wait for database to be ready
    sleep 5
    
    # Run migrations
    if docker-compose -f docker-compose.dev.yml exec -T app npm run db:migrate; then
        print_success "Database migrations completed"
    else
        print_warning "Migration failed, but this might be expected on first run"
        print_warning "You can run migrations manually: docker-compose -f docker-compose.dev.yml exec app npm run db:migrate"
    fi
}

# Show status
show_status() {
    print_step "Development environment status:"
    echo
    echo "🌐 Services:"
    echo "   • API Server: http://localhost:3000"
    echo "   • Health Check: http://localhost:3000/health"
    echo "   • Database Admin: http://localhost:8080"
    echo "     - Server: neon-local"
    echo "     - Username: neondb_owner"
    echo "     - Password: localdb"
    echo "     - Database: neondb"
    echo
    echo "🔧 Useful commands:"
    echo "   • View logs: npm run docker:logs"
    echo "   • Stop services: npm run docker:dev:down"
    echo "   • Run migrations: docker-compose -f docker-compose.dev.yml exec app npm run db:migrate"
    echo "   • Generate migrations: docker-compose -f docker-compose.dev.yml exec app npm run db:generate"
    echo "   • Open DB Studio: docker-compose -f docker-compose.dev.yml exec app npm run db:studio"
    echo
}

# Test the setup
test_setup() {
    print_step "Testing the setup..."
    
    # Test API health endpoint
    sleep 3
    if curl -f http://localhost:3000/health > /dev/null 2>&1; then
        print_success "API server is responding"
    else
        print_warning "API server health check failed. Check logs: docker-compose -f docker-compose.dev.yml logs app"
    fi
    
    # Test database connection
    if docker-compose -f docker-compose.dev.yml exec -T neon-local pg_isready -U neondb_owner -d neondb > /dev/null 2>&1; then
        print_success "Database is ready"
    else
        print_warning "Database connection test failed"
    fi
}

# Cleanup function
cleanup() {
    if [ "$1" = "clean" ]; then
        print_step "Cleaning up development environment..."
        docker-compose -f docker-compose.dev.yml down -v
        docker system prune -f
        print_success "Cleanup completed"
    fi
}

# Main function
main() {
    print_header
    
    # Handle cleanup flag
    if [ "$1" = "clean" ]; then
        cleanup clean
        exit 0
    fi
    
    # Setup development environment
    check_prerequisites
    setup_env
    start_services
    run_migrations
    test_setup
    show_status
    
    echo
    print_success "Development environment is ready! 🚀"
    echo
    echo -e "${BLUE}To stop the environment, run: ${YELLOW}npm run docker:dev:down${NC}"
    echo -e "${BLUE}To clean everything, run: ${YELLOW}./scripts/dev-setup.sh clean${NC}"
}

# Run main function with all arguments
main "$@"