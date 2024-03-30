#!/bin/bash

#Read the output file
OUTPUT_FILE="created_resources.txt"

if [ ! -f "$OUTPUT_FILE" ]; then
echo "Error: Output file '$OUTPUT_FILE' not found."
exit 1
fi

source $OUTPUT_FILE

#Terminate the Mutagen sync session
if mutagen sync list | grep -q "$PROJECT_NAME-sync"; then
mutagen sync terminate $PROJECT_NAME-sync
echo "Terminated Mutagen sync session: $PROJECT_NAME-sync"
else
echo "Mutagen sync session '$PROJECT_NAME-sync' not found."
fi

#Stop and remove the Docker container
if docker ps -a | grep -q "$CONTAINER_NAME"; then
docker stop $CONTAINER_NAME
docker rm $CONTAINER_NAME
echo "Stopped and removed Docker container: $CONTAINER_NAME"
else
echo "Docker container '$CONTAINER_NAME' not found."
fi

#Remove the Docker image
if docker images | grep -q "$IMAGE_NAME"; then
docker rmi $IMAGE_NAME
echo "Removed Docker image: $IMAGE_NAME"
else
echo "Docker image '$IMAGE_NAME' not found."
fi

#Remove the Docker volume
if docker volume inspect $PROJECT_NAME >/dev/null 2>&1; then
docker volume rm $PROJECT_NAME
echo "Removed Docker volume: $PROJECT_NAME"
else
echo "Docker volume '$PROJECT_NAME' not found."
fi

echo "Termination completed."

#Remove the output file
rm $OUTPUT_FILE
