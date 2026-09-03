#!/bin/bash
set -e

DOCKER_SOCKET="/var/run/docker.sock"

if [ -S "$DOCKER_SOCKET" ]; then
    SOCKET_GID=$(stat -c '%g' "$DOCKER_SOCKET")
    if ! getent group "$SOCKET_GID" >/dev/null 2>&1; then
        groupadd -for -g "$SOCKET_GID" docker_host
    fi
    usermod -aG "$SOCKET_GID" jenkins
fi

exec gosu jenkins /usr/bin/tini -- /usr/local/bin/jenkins.sh "$@"
