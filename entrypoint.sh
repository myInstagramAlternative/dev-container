#!/bin/bash
set -e

TARGET_UID=${DOCKER_UID:-1000}
TARGET_GID=${DOCKER_GID:-1000}
CURRENT_UID=$(id -u jesteibice)
CURRENT_GID=$(id -g jesteibice)

# Adjust GID if needed
if [ "$TARGET_GID" != "$CURRENT_GID" ]; then
    groupmod -g "$TARGET_GID" jesteibice 2>/dev/null || true
fi

# Adjust UID if needed
if [ "$TARGET_UID" != "$CURRENT_UID" ]; then
    usermod -u "$TARGET_UID" jesteibice 2>/dev/null || true
fi

# Fix ownership of home directory
chown -R jesteibice:jesteibice /home/jesteibice

# Run the command as jesteibice
exec gosu jesteibice "$@"
