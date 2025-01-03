#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Load environment variables from .envrc
if [ -f .envrc ]; then
  echo "Loading environment variables from .envrc..."
  export $(grep -v '^#' .envrc | xargs)
else
  echo "Error: .envrc file not found. Please create one with the required variables."
  exit 1
fi

# Build Docker images
echo "Building Exporter docker image..."
docker build -f docker/exporter/Dockerfile -t exporter .

# Remove all dangling images
echo "Cleaning up unused Docker images..."
docker image prune --force

echo "Docker images built successfully."
