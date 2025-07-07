#!/bin/bash

# Build and Push Script for geminicli2api
# Usage: ./build-and-push.sh [tag]

set -e

# Configuration
DOCKER_USERNAME="drnit29"
DOCKER_REPOSITORY="geminicli2api"
DEFAULT_TAG="latest"
PLATFORMS="linux/amd64,linux/arm64"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Parse arguments
TAG=${1:-$DEFAULT_TAG}
FULL_IMAGE_NAME="${DOCKER_USERNAME}/${DOCKER_REPOSITORY}:${TAG}"

log_info "Starting build and push process for ${FULL_IMAGE_NAME}"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    log_error "Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if logged in to Docker Hub
if ! docker info | grep -q "Username"; then
    log_warning "You may not be logged in to Docker Hub."
    log_info "Please run: docker login"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Create buildx builder if not exists
if ! docker buildx ls | grep -q "multi-platform"; then
    log_info "Creating multi-platform builder..."
    docker buildx create --name multi-platform --use --platform $PLATFORMS
fi

# Build multi-platform image
log_info "Building multi-platform Docker image..."
docker buildx build \
    --platform $PLATFORMS \
    --tag $FULL_IMAGE_NAME \
    --push \
    --progress=plain \
    .

# Verify the push
log_info "Verifying the pushed image..."
if docker manifest inspect $FULL_IMAGE_NAME > /dev/null 2>&1; then
    log_success "Image successfully pushed to Docker Hub!"
    log_info "Image: ${FULL_IMAGE_NAME}"
    log_info "Platforms: ${PLATFORMS}"
else
    log_error "Failed to verify the pushed image."
    exit 1
fi

# Also tag and push as 'latest' if not already latest
if [ "$TAG" != "latest" ]; then
    log_info "Also tagging as 'latest'..."
    LATEST_IMAGE_NAME="${DOCKER_USERNAME}/${DOCKER_REPOSITORY}:latest"
    
    docker buildx build \
        --platform $PLATFORMS \
        --tag $LATEST_IMAGE_NAME \
        --push \
        --progress=plain \
        .
    
    log_success "Also pushed as: ${LATEST_IMAGE_NAME}"
fi

# Show usage instructions
echo ""
log_success "Build and push completed successfully!"
echo ""
log_info "Usage instructions:"
echo "  Pull the image: docker pull ${FULL_IMAGE_NAME}"
echo "  Run locally: docker run -p 8888:8888 -e GEMINI_AUTH_PASSWORD=yourpassword ${FULL_IMAGE_NAME}"
echo "  Use in docker-compose:"
echo "    services:"
echo "      geminicli2api:"
echo "        image: ${FULL_IMAGE_NAME}"
echo "        ports:"
echo "          - \"8888:8888\""
echo "        environment:"
echo "          - GEMINI_AUTH_PASSWORD=yourpassword"
echo ""
log_info "Docker Hub: https://hub.docker.com/r/${DOCKER_USERNAME}/${DOCKER_REPOSITORY}"