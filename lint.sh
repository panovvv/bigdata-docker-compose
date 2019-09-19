#!/bin/bash

echo "Checking base Dockerfile..."
docker run --rm -i hadolint/hadolint < Dockerfile
echo "Checking Zeppelin Dockerfile..."
docker run --rm -i hadolint/hadolint < docker_zeppelin/Dockerfile
echo "Checking Livy Dockerfile..."
docker run --rm -i hadolint/hadolint < docker_livy/Dockerfile