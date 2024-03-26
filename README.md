![stable](https://img.shields.io/badge/stable-v0.1.3-blue)
![python versions](https://img.shields.io/badge/python-3.8%20%7C%203.9-blue)
[![tests](https://github.com/cvpaperchallenge/Ascender/actions/workflows/lint-and-test.yaml/badge.svg)](https://github.com/cvpaperchallenge/Ascender/actions/workflows/lint-and-test.yaml)
[![MIT License](https://img.shields.io/github/license/cvpaperchallenge/Ascender?color=green)](LICENSE)
[![Code style: black](https://img.shields.io/badge/code%20style-black-000000.svg)](https://github.com/psf/black)
[![Code style: flake8](https://img.shields.io/badge/code%20style-flake8-black)](https://github.com/PyCQA/flake8)
[![Imports: isort](https://img.shields.io/badge/%20imports-isort-%231674b1?style=flat&labelColor=ef8336)](https://pycqa.github.io/isort/)
[![Typing: mypy](https://img.shields.io/badge/typing-mypy-blue)](https://github.com/python/mypy)
[![DOI](https://zenodo.org/badge/466620310.svg)](https://zenodo.org/badge/latestdoi/466620310)

# PythonDockerEnvTemplate
This template is created based on Ascender. \

Basic usage is written in [Ascender](https://github.com/cvpaperchallenge/Ascender) .
This repository adds a feature to Ascender that uses Mutagen to synchronize files between local and remote development environments.

## Prerequisite
- Installed docker in both the local environment and the remote one.
- Constructed connection with docker context from local to remote.
- Installed mutagen.


## Overview ./environments/deploy.sh
The graph illustrates a development workflow that involves synchronizing a local project folder with a remote machine using Mutagen sync. The local project folder contains the source code, README, Dockerfile, and a .gitignore file. The .gitignore file specifies files and folders that should be ignored locally but are still stored on the remote machine. The local machine also has a Docker context that establishes an SSH connection with the remote Docker container. On the remote machine, there is a Docker volume that contains the remote contents, which mirror the local project folder, as well as additional files and folders stored exclusively on the remote machine.

Technologies used:
- Mutagen sync: A tool used for synchronizing the contents of the local project folder with the remote machine.
- Docker: A platform for developing, shipping, and running applications using containers. The graph shows the usage of Docker containers and volumes.
- SSH (Secure Shell): A network protocol used for secure communication between the local Docker context and the remote Docker container.


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

