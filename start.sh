#!/bin/bash

# Start Script for geminicli2api Local Development
# Usage: ./start.sh [command]

set -e

# Configuration
COMPOSE_FILE="docker-compose.local.yml"
SERVICE_NAME="geminicli2api"
PROJECT_NAME="geminicli2api-local"
DEFAULT_PORT="8888"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
    echo -e "${CYAN}=====================================${NC}"
    echo -e "${CYAN} $1${NC}"
    echo -e "${CYAN}=====================================${NC}"
}

# Check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        log_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
}

# Check if .env file exists
check_env() {
    if [ ! -f .env ]; then
        log_warning ".env file not found. Creating from .env.example..."
        if [ -f .env.example ]; then
            cp .env.example .env
            log_info "Please edit .env file with your configuration:"
            log_info "  - GEMINI_AUTH_PASSWORD: Your API password"
            log_info "  - GOOGLE_APPLICATION_CREDENTIALS: Path to your Google credentials"
            echo ""
            read -p "Press Enter to continue after editing .env file..."
        else
            log_error ".env.example file not found. Please create .env file manually."
            exit 1
        fi
    fi
}

# Check if the image exists
check_image() {
    if ! docker image inspect drnit29/geminicli2api:latest > /dev/null 2>&1; then
        log_warning "Image drnit29/geminicli2api:latest not found locally."
        read -p "Do you want to pull it from Docker Hub? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "Pulling image from Docker Hub..."
            docker pull drnit29/geminicli2api:latest
        else
            log_info "You can build the image locally with: ./build-and-push.sh"
            exit 1
        fi
    fi
}

# Start services
start_services() {
    log_header "Starting geminicli2api Local Development"
    
    check_docker
    check_env
    check_image
    
    log_info "Starting services..."
    docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME up -d
    
    # Wait for service to be healthy
    log_info "Waiting for service to be healthy..."
    timeout=60
    counter=0
    
    while [ $counter -lt $timeout ]; do
        if docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME ps | grep -q "healthy"; then
            log_success "Service is healthy!"
            break
        elif docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME ps | grep -q "unhealthy"; then
            log_error "Service is unhealthy. Check logs with: ./start.sh logs"
            exit 1
        fi
        
        echo -n "."
        sleep 2
        counter=$((counter + 2))
    done
    
    if [ $counter -ge $timeout ]; then
        log_warning "Service health check timeout. Service may still be starting..."
    fi
    
    # Get the actual port
    PORT=$(docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME port $SERVICE_NAME 8888 2>/dev/null | cut -d: -f2)
    if [ -z "$PORT" ]; then
        PORT=$DEFAULT_PORT
    fi
    
    echo ""
    log_success "geminicli2api is running!"
    echo ""
    echo -e "${CYAN}Service Information:${NC}"
    echo "  🌐 API URL: http://localhost:$PORT"
    echo "  🔍 Health Check: http://localhost:$PORT/health"
    echo "  📋 OpenAI API: http://localhost:$PORT/v1/chat/completions"
    echo "  📋 Gemini API: http://localhost:$PORT/v1beta/models"
    echo ""
    echo -e "${CYAN}Useful Commands:${NC}"
    echo "  ./start.sh logs     - View logs"
    echo "  ./start.sh status   - Check status"
    echo "  ./start.sh stop     - Stop services"
    echo "  ./start.sh restart  - Restart services"
    echo "  ./start.sh test     - Test API"
    echo ""
}

# Stop services
stop_services() {
    log_header "Stopping geminicli2api Local Development"
    
    check_docker
    
    log_info "Stopping services..."
    docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME down
    
    log_success "Services stopped successfully!"
}

# Restart services
restart_services() {
    log_header "Restarting geminicli2api Local Development"
    
    stop_services
    sleep 2
    start_services
}

# Show logs
show_logs() {
    check_docker
    
    log_info "Showing logs (press Ctrl+C to exit)..."
    docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME logs -f
}

# Show status
show_status() {
    check_docker
    
    log_header "Service Status"
    
    docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME ps
    
    echo ""
    log_info "Container details:"
    docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME exec $SERVICE_NAME curl -s http://localhost:8888/health 2>/dev/null || echo "Health check failed"
}

# Test API
test_api() {
    check_docker
    
    log_header "Testing API"
    
    # Get the actual port
    PORT=$(docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME port $SERVICE_NAME 8888 2>/dev/null | cut -d: -f2)
    if [ -z "$PORT" ]; then
        PORT=$DEFAULT_PORT
    fi
    
    # Test health endpoint
    log_info "Testing health endpoint..."
    if curl -s -f "http://localhost:$PORT/health" > /dev/null; then
        log_success "Health check passed!"
    else
        log_error "Health check failed!"
        exit 1
    fi
    
    # Test API with dummy request (requires auth)
    log_info "Testing API endpoint..."
    echo "Note: This will fail without proper authentication configured in .env"
    
    # Read password from .env if exists
    if [ -f .env ]; then
        PASSWORD=$(grep GEMINI_AUTH_PASSWORD .env | cut -d'=' -f2)
        if [ ! -z "$PASSWORD" ]; then
            log_info "Testing with configured password..."
            response=$(curl -s -w "HTTP_STATUS:%{http_code}" \
                -X POST "http://localhost:$PORT/v1/models" \
                -H "Authorization: Bearer $PASSWORD" \
                -H "Content-Type: application/json")
            
            http_status=$(echo "$response" | grep -o "HTTP_STATUS:[0-9]*" | cut -d: -f2)
            if [ "$http_status" -eq 200 ]; then
                log_success "API test passed!"
            else
                log_warning "API test returned status: $http_status"
            fi
        fi
    fi
}

# Pull latest image
pull_image() {
    check_docker
    
    log_header "Pulling Latest Image"
    
    log_info "Pulling drnit29/geminicli2api:latest..."
    docker pull drnit29/geminicli2api:latest
    
    log_success "Image pulled successfully!"
    log_info "Restart services to use the new image: ./start.sh restart"
}

# Show help
show_help() {
    echo -e "${CYAN}geminicli2api Local Development Script${NC}"
    echo ""
    echo "Usage: ./start.sh [command]"
    echo ""
    echo "Commands:"
    echo "  start     - Start services (default)"
    echo "  stop      - Stop services"
    echo "  restart   - Restart services"
    echo "  logs      - Show logs"
    echo "  status    - Show service status"
    echo "  test      - Test API endpoints"
    echo "  pull      - Pull latest image"
    echo "  help      - Show this help"
    echo ""
    echo "Examples:"
    echo "  ./start.sh           # Start services"
    echo "  ./start.sh logs      # View logs"
    echo "  ./start.sh test      # Test API"
    echo ""
}

# Main logic
case "${1:-start}" in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    logs)
        show_logs
        ;;
    status)
        show_status
        ;;
    test)
        test_api
        ;;
    pull)
        pull_image
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        log_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac