#!/bin/bash

# Script used to start and update inference service
# Set it up as a cron job which will execute daily at midnight

# Function to check exit code and handle errors
check_exit_code() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed."
        exit 1
    fi
}

# Function to check if the container is running
is_container_running() {
    docker ps --filter "name=incident-inference-service" --filter "status=running" | grep -q "incident-inference-service"
    return $?
}

# Function to check if the container exists
does_container_exist() {
    docker ps -a --filter "name=incident-inference-service" | grep -q "incident-inference-service"
    return $?
}

# Pull image
docker pull boskodev8/incident-inference-service:latest
check_exit_code "docker pull boskodev8/incident-inference-service:latest"

# Check if the container exists before stopping or removing
if does_container_exist; then
    if is_container_running; then
        # Stop current
        docker stop incident-inference-service
        check_exit_code "docker stop incident-inference-service"
    else
        echo "Container incident-inference-service is not running."
    fi

    # Remove stopped container
    # Force remove in case container is restarting
    docker rm -f incident-inference-service
    check_exit_code "docker rm -f incident-inference-service"
else
    echo "Container incident-inference-service does not exist."
fi

# Prune untagged images
# -f needed for automatic YES response
docker image prune -f
check_exit_code "docker image prune -f"

# Start new updated container
docker run -d \
  --name incident-inference-service \
  --restart unless-stopped \
  --gpus all,capabilities=video \
  -e IIS_STORAGE_PATH=/root/.incident-inference-service-data \
  -v $(echo ~/.incident-inference-service-data):/root/.incident-inference-service-data \
  boskodev8/incident-inference-service:latest
