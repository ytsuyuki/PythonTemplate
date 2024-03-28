#!/bin/bash

# ... (previous code remains the same)

# Function to stop and clean up resources
cleanup() {
    echo "Stopping and cleaning up resources..."

    # Stop and remove the Docker container
    docker stop $CONTAINER_NAME 2>/dev/null
    docker rm $CONTAINER_NAME 2>/dev/null

    # Terminate the Mutagen sync session
    mutagen sync terminate $PROJECT_NAME-sync 2>/dev/null

    # Delete the Docker volume if --volume argument is provided
    if [ "$volume_option" = true ]; then
        docker volume rm $PROJECT_NAME 2>/dev/null
        echo "Docker volume deleted."
    fi

    echo "Cleanup completed."
}

# ... (previous code remains the same)

# Parse command line arguments
volume_option=false
while [ "$1" != "" ]; do
    case $1 in
        # ... (previous code remains the same)
        --volume )
            volume_option=true
            ;;
    esac
    shift
done

# ... (previous code remains the same)

# Step 3: Run the Docker container with GPU support, port mapping, and volume (if specified)
docker stop $CONTAINER_NAME 2>/dev/null

docker_run_cmd="docker run -it -d --rm"
if [ $envtype == "gpu" ]; then
    docker_run_cmd+=" --gpus all"
fi

if $use_port; then
    docker_run_cmd+=" -p $PORT_MAPPING"
fi

if $volume_option; then
    # Create a Docker volume for the project if it doesn't exist
    docker volume create $PROJECT_NAME || handle_error "Failed to create Docker volume"
    docker_run_cmd+=" -v $PROJECT_NAME:$APPLICATION_DIRECTORY"
fi

# Execute the final docker run command
eval $docker_run_cmd --name $CONTAINER_NAME $IMAGE_NAME || handle_error "Failed to run Docker container"

# ... (previous code remains the same)

# Trap the cleanup function to be executed on script exit
trap cleanup EXIT

# ... (previous code remains the same)