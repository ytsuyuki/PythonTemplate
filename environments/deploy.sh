#!/bin/bash

# Variables

IMAGE_NAME="my-img"
CONTAINER_NAME="my-container"
PORT_MAPPING="8000:8000"
BUILD_CONTEXT="../"
DOCKERFILE="Dockerfile"
PROJECT_NAME=ascender
USER_NAME=challenger
GROUP_NAME=challengers
HOST_UID="${HOST_UID-1000}"
HOST_GID="${HOST_GID-1000}"
PYTHON_VERSION="3.8"
APPLICATION_DIRECTORY="/home/${USER_NAME}
RUN_POETRY_INSTALL_AT_BUILD_TIME="false"

# Display help message

display_help() {
    echo "Usage: ./deploy.sh [options]"
    echo
    echo "Options:"
    echo "  --env-type <gpu/cpu>    Specify the base image type (gpu or cpu)"
    echo "  --use-port              Use port mapping"
    echo "  --help                  Display this help message"
    echo
}

# Function to handle errors and exit with a message

handle_error() {
    echo "Error: $1"
    echo "Use --help for more information"
    exit 1
}

# Select the base image type and port usage

# Usage: ./deploy.sh --env-type <gpu/cpu> [--use-port]

use_port=false

while [ "$1" != "" ]; do
    case $1 in
        --env-type )
            shift
            envtype=$1
            ;;
        --use-port )
            use_port=true
            ;;
        --help )
            display_help
            exit 0
            ;;
        * )
            handle_error "Invalid argument: $1"
    esac
    shift
done

# Check if env-type is provided

if [ -z "$envtype" ]; then
    handle_error "Please specify the base image type using --env-type <gpu/cpu>"
fi

# Set the base image based on the env-type

case $envtype in
    gpu)
        BASE_IMAGE="nvidia/cuda:11.6.1-devel-ubuntu20.04"
        ;;
    cpu)
        BASE_IMAGE="ubuntu:20.04"
        ;;
    *)
        handle_error "Invalid base image type. Please provide either 'gpu' or 'cpu'."
        ;;
esac

# Step 1: Build the Docker image with new arguments

docker build -t $IMAGE_NAME \
  --build-arg BASE_IMAGE=$BASE_IMAGE \
  --build-arg PROJECT_NAME=$PROJECT_NAME \
  --build-arg USER_NAME=$USER_NAME \
  --build-arg GROUP_NAME=$GROUP_NAME \
  --build-arg UID=$HOST_UID \
  --build-arg GID=$HOST_GID \
  --build-arg PYTHON_VERSION=$PYTHON_VERSION \
  --build-arg APPLICATION_DIRECTORY=$APPLICATION_DIRECTORY \
  --build-arg RUN_POETRY_INSTALL_AT_BUILD_TIME=$RUN_POETRY_INSTALL_AT_BUILD_TIME \
  -f $DOCKERFILE $BUILD_CONTEXT || handle_error "Failed to build Docker image"

# Step 2: Create a Docker volume for the project if it doesn't exist

if ! docker volume inspect $PROJECT_NAME >/dev/null 2>&1; then
    docker volume create $PROJECT_NAME || handle_error "Failed to create Docker volume"
fi

# Step 3: Run the Docker container with GPU support and port mapping if it doesn't run and exists

if ! docker inspect -f '{{.State.Running}}' $CONTAINER_NAME >/dev/null 2>&1; then
    docker stop $CONTAINER_NAME 2>/dev/null
    docker_run_cmd="docker run -it -d --rm"
    
    if [ $envtype == "gpu" ]; then
        docker_run_cmd+=" --gpus all"
    fi
    
    if $use_port; then
        docker_run_cmd+=" -p $PORT_MAPPING"
    fi
    
    docker_run_cmd+=" -v $PROJECT_NAME:$APPLICATION_DIRECTORY"
    
    # Execute the final docker run command
    eval $docker_run_cmd --name $CONTAINER_NAME $IMAGE_NAME || handle_error "Failed to run Docker container"
fi

# Step 4: Recreate a Mutagen sync session

# Terminates the existing session if it exists
if mutagen sync list | grep -q "$PROJECT_NAME-sync"; then
    mutagen sync terminate $PROJECT_NAME-sync 2>/dev/null
fi

# Step 5: Output created resources to a file
OUTPUT_FILE="created_resources.txt"

echo "IMAGE_NAME=$IMAGE_NAME" > $OUTPUT_FILE
echo "CONTAINER_NAME=$CONTAINER_NAME" >> $OUTPUT_FILE
echo "PROJECT_NAME=$PROJECT_NAME" >> $OUTPUT_FILE

# Create the Mutagen sync command
CMD="mutagen sync create $BUILD_CONTEXT docker://$CONTAINER_NAME$APPLICATION_DIRECTORY --name=$PROJECT_NAME-sync --sync-mode='two-way-resolved'"

GITIGNORE_PATH="$BUILD_CONTEXT/.gitignore"

# Add each line in .gitignore as an --ignore flag if the file exists
if [ -f "$GITIGNORE_PATH" ]; then
    while IFS= read -r line; do
      # Skip empty lines and comments
      if [ -n "$line" ] && [ "${line:0:1}" != "#" ]; then
        escaped_line=$(printf '%q' "$line")
        CMD+=" --ignore='$escaped_line'"
      fi
    done < "$GITIGNORE_PATH"
fi

# Execute the command
eval $CMD || handle_error "Failed to create Mutagen sync session"



RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "===================="
echo -e "Summary:"
echo -e "- Docker image '${BLUE}$IMAGE_NAME${NC}' has been built using base image '${BLUE}$BASE_IMAGE${NC}'."
echo -e "- Docker volume '${BLUE}$PROJECT_NAME${NC}' has been created (if it didn't exist)."
echo -e "- Docker container '${BLUE}$CONTAINER_NAME${NC}' is running with the following configuration:"
echo -e "  - Environment type: ${YELLOW}$envtype${NC}"
if $use_port; then
    echo -e "  - Port mapping: ${YELLOW}$PORT_MAPPING${NC}"
else
    echo -e "  - Port mapping: ${YELLOW}Not used${NC}"
fi
echo -e "  - Volume: '${BLUE}$PROJECT_NAME${NC}' mounted to '${BLUE}$APPLICATION_DIRECTORY${NC}'"
echo -e "- Mutagen sync session '${BLUE}$PROJECT_NAME-sync${NC}' has been created to synchronize '${BLUE}$BUILD_CONTEXT${NC}' with 'docker://${BLUE}$CONTAINER_NAME${NC}${BLUE}$APPLICATION_DIRECTORY${NC}'."

if [ -f "$GITIGNORE_PATH" ]; then
    echo -e "- Entries from '${BLUE}$GITIGNORE_PATH${NC}' are being ignored by the Mutagen sync session."
else
    echo -e "- No '.gitignore' file found. All files in '${BLUE}$BUILD_CONTEXT${NC}' will be synced."
fi
echo "===================="
