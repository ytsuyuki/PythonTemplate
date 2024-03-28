![stable](https://img.shields.io/badge/stable-v0.1.3-blue)
![python versions](https://img.shields.io/badge/python-3.8%20%7C%203.9-blue)
[![tests](https://github.com/cvpaperchallenge/Ascender/actions/workflows/lint-and-test.yaml/badge.svg)](https://github.com/cvpaperchallenge/Ascender/actions/workflows/lint-and-test.yaml)
[![MIT License](https://img.shields.io/github/license/cvpaperchallenge/Ascender?color=green)](LICENSE)
[![Code style: black](https://img.shields.io/badge/code%20style-black-000000.svg)](https://github.com/psf/black)
[![Code style: flake8](https://img.shields.io/badge/code%20style-flake8-black)](https://github.com/PyCQA/flake8)
[![Imports: isort](https://img.shields.io/badge/%20imports-isort-%231674b1?style=flat&labelColor=ef8336)](https://pycqa.github.io/isort/)
[![Typing: mypy](https://img.shields.io/badge/typing-mypy-blue)](https://github.com/python/mypy)
[![DOI](https://zenodo.org/badge/466620310.svg)](https://zenodo.org/badge/latestdoi/466620310)

# PyDen(Python Docker Environment)
This template is created based on Ascender. \

Basic usage is written in [Ascender](https://github.com/cvpaperchallenge/Ascender) .
This repository adds a feature to Ascender that uses Mutagen to synchronize files between local and remote development environments.

## Prerequisite
- Installed docker in both the local environment and the remote one.
- Constructed connection with docker context from local to remote.
- Installed mutagen.


## Overview of the Deployment Script (./environments/deploy.sh)

The deployment script automates the process of setting up and managing a development environment using Docker and Mutagen sync. It streamlines the workflow by building Docker images, creating and managing Docker volumes and containers, and synchronizing the local project folder with a remote machine.

### Key Features

1. **Environment Type Selection**:
   - The script allows the user to specify the environment type (GPU or CPU) to determine the appropriate base image for the Docker container.

2. **Docker Image Building**:
   - It builds a Docker image based on the specified environment type and the provided Dockerfile.

3. **Docker Volume Management**:
   - The script checks if the required Docker volume exists and creates it if necessary.
   - This volume is used to store the project files on the remote machine.

4. **Docker Container Management**:
   - It checks if the Docker container is running and starts it if needed.
   - The script constructs the `docker run` command based on the environment type and port usage settings.

5. **File Synchronization**:
   - The script uses Mutagen sync to synchronize the contents of the local project folder with the remote machine.
   - It terminates any existing file sync sessions and creates a new one, ensuring that the local and remote project files are in sync.

6. **.gitignore Processing**:
   - It processes the `.gitignore` file to identify the files and folders that should be ignored in the local project folder but still stored on the remote machine.

7. **Summary Display**:
   - Finally, the script displays a summary of the operations performed, providing an overview of the deployment process.

## Technologies Used

- **Docker**:
  - Used for containerization, allowing the development environment to be isolated and easily reproducible.

- **Mutagen sync**:
  - Employed for efficient file synchronization between the local project folder and the remote machine.

- **SSH (Secure Shell)**:
  - Utilized for secure communication between the local Docker context and the remote Docker container.

By using this deployment script, developers can streamline their workflow, ensure consistency between local and remote environments, and efficiently manage the deployment process. The script abstracts away the complexities of setting up and managing Docker containers and file synchronization, allowing developers to focus on writing code and building applications.

```mermaid
graph LR
    %% Local Machine details
    LocalProjectFolder[Local Project Folder] -->|contains| LocalContents
    LocalContents[Project Contents] -->|includes| SrcFolder[src]
    LocalContents -->|includes| ReadmeFile[README.md]
    LocalContents -->|includes| DockerFile[Dockerfile]
    LocalProjectFolder -->|uses| Gitignore[.gitignore]

    %% Sync operation
    LocalProjectFolder -->|synced by| MutagenSync[mutagen sync]
    MutagenSync -.-> |syncs to| RemoteVolumeFolder

    %% Local Docker Context
    LocalDockerContext[Docker Context] -.-> |ssh connection| RemoteDockerContainer[Docker Container]

    %% Ignored Files not shown in local but stored in remote
    Gitignore -.->|ignores on local| HiddenFiles

    %% Mirror relationship between Local and Remote Contents
    LocalContents --> |mirrors| RemoteContents

    subgraph "Local Machine"
        LocalContents
        LocalProjectFolder
        LocalDockerContext
        SrcFolder
        Gitignore
        ReadmeFile
        DockerFile
        MutagenSync
    end

    subgraph "Remote Machine"
        RemoteVolumeFolder[Remote Docker Volume] -->|contains| RemoteContents
        RemoteDockerContainer -.->|mounted on| RemoteVolumeFolder
        RemoteVolumeFolder -->|contains| StoredInRemote

        %% Stored in Remote - Adjusted for clarity
        StoredInRemote[Stored in Remote] --> HiddenFiles[Hidden Files]
        HiddenFiles --> |includes| VenvFolder[.venv/]
        HiddenFiles --> |includes| LogFiles[*.log]
        HiddenFiles --> |includes| EnvFile[.env]
        HiddenFiles --> |includes| PyCache[__pycache__]
        HiddenFiles --> |includes| GitHubFolder[.github]
    end
```

```mermaid
sequenceDiagram
    participant User
    participant Script
    participant Docker

    User->>Script: Run deploy script
    Script->>Script: Check if environment type is specified
    alt Environment type specified
        Script->>Script: Set base image based on environment type
    else Environment type not specified
        Script->>User: Display error message
        Script->>Script: Exit script
    end
    Script->>Docker: Build Docker image
    Script->>Docker: Check if Docker volume exists
    alt Docker volume does not exist
        Script->>Docker: Create Docker volume
    end
    Script->>Docker: Check if Docker container is running
    alt Docker container is not running
        Script->>Docker: Stop Docker container if it exists
        Script->>Script: Construct docker run command
        alt Environment type is GPU
            Script->>Script: Add GPU option to docker run command
        end
        alt Use port is true
            Script->>Script: Add port mapping to docker run command
        end
        Script->>Docker: Execute docker run command
    end
    Script->>Script: Terminate existing file sync session
    Script->>Script: Process .gitignore file
    Script->>Script: Create new file sync session
    Script->>User: Display summary of operations
```

## Knowlege
- run jupyter notebook in docker container
```
poetry run jupyter notebook --port=<port num> --ip=0.0.0.0
```
- run jupyter lab in docker container
```
poetry run jupyter lab --port=<port num> --ip=0.0.0.0
```


