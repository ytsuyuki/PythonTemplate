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
APPLICATION_DIRECTORY="/home/${USER_NAME}/${PROJECT_NAME}"
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
            echo "Invalid argument: $1"
            echo "Use --help for more information"
            exit 1
    esac
    shift
done

# Check if env-type is provided
if [ -z "$envtype" ]; then
    echo "Please specify the base image type using --env-type <gpu/cpu>"
    echo "Use --help for more information"
    exit 1
fi

# base image type is gpu or cpu or mps
if [ $envtype == "gpu" ]; then
  BASE_IMAGE="nvidia/cuda:11.6.1-devel-ubuntu20.04"
elif [ $envtype == "cpu" ]; then
  BASE_IMAGE="ubuntu:20.04"
else
  echo "Invalid base image type. Please provide either 'gpu' or 'cpu'."
  exit 1
fi


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
  -f $DOCKERFILE $BUILD_CONTEXT

# Step 2: Create a Docker volume for the project if it doesn't exist
docker volume create $PROJECT_NAME 

# Step 3: Run the Docker container with GPU support and port mapping if it doesn't run and exists
docker stop $CONTAINER_NAME

docker_run_cmd="docker run -it -d --rm"
if [ $envtype == "gpu" ]; then
    docker_run_cmd+=" --gpus all"
fi

if $use_port; then
    docker_run_cmd+=" -p $PORT_MAPPING"
fi

docker_run_cmd+=" -v $PROJECT_NAME:$APPLICATION_DIRECTORY --name $CONTAINER_NAME $IMAGE_NAME"

# Execute the final docker run command
eval $docker_run_cmd


# Step 4: Recreate a Mutagen sync session
# Terminates the existing session if it exists
mutagen sync terminate $PROJECT_NAME-sync

# Create the Mutagen sync command
CMD="mutagen sync create $BUILD_CONTEXT docker://$CONTAINER_NAME$APPLICATION_DIRECTORY --name=$PROJECT_NAME-sync --sync-mode='two-way-resolved'"

GITIGNORE_PATH="$BUILD_CONTEXT/.gitignore"
# Add each line in .gitignore as an --ignore flag
while IFS= read -r line; do
  # Skip empty lines and comments
  if [ -n "$line" ] && [ "${line:0:1}" != "#" ]; then
    escaped_line=$(printf '%q' "$line")
    CMD+=" --ignore='$escaped_line'"
  fi
done < "$GITIGNORE_PATH"

# Execute the command
eval $CMD
