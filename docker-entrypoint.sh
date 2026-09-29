#!/bin/bash
set -e

# Start SSH daemon if not already running.
# The container runs as the unprivileged dev user, which has passwordless sudo.
if ! pgrep -x sshd > /dev/null; then
    sudo /usr/sbin/sshd
fi

# Optionally set the dev user's password at runtime, from a secret.
# The password is never baked into the image; it comes from USER_PASSWORD
# (e.g. a Kubernetes Secret / docker --env-file) or, preferably, from a file
# via USER_PASSWORD_FILE (a mounted secret, keeps it out of `docker inspect`).
DEV_USER="${DEV_USER:-jesteibice}"
RUNTIME_PASSWORD=""
if [ -n "${USER_PASSWORD_FILE:-}" ] && [ -r "${USER_PASSWORD_FILE}" ]; then
    RUNTIME_PASSWORD="$(cat "${USER_PASSWORD_FILE}")"
elif [ -n "${USER_PASSWORD:-}" ]; then
    RUNTIME_PASSWORD="${USER_PASSWORD}"
fi
if [ -n "${RUNTIME_PASSWORD}" ]; then
    printf '%s:%s\n' "${DEV_USER}" "${RUNTIME_PASSWORD}" | sudo chpasswd
    unset RUNTIME_PASSWORD USER_PASSWORD
fi

# Execute the CMD
exec "$@"
