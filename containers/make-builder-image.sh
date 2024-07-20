#!/bin/bash
DOCKER_COMMAND="${DOCKER_COMMAND:-docker}"
$DOCKER_COMMAND build -f ValidiTEE-build.containerFile --platform linux/amd64 \
    --target setup-build-dir-stage -t validitee-builder .

