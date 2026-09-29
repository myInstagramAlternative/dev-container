#!/bin/bash
set -e

# Start SSH daemon if not already running.
# The container runs as the unprivileged dev user, which has passwordless sudo.
if ! pgrep -x sshd > /dev/null; then
    sudo /usr/sbin/sshd
fi

# Optionally set the dev user's password at runtime, from a secret file only.
# The password is never baked into the image and never passed as an env var.
# Mount a secret and point USER_PASSWORD_FILE at it, e.g.
#   docker:  -v ./user_password:/run/secrets/user_password:ro \
#            -e USER_PASSWORD_FILE=/run/secrets/user_password
#   k8s:     mount a Secret as a volume and set USER_PASSWORD_FILE to the file.
DEV_USER="${DEV_USER:-jesteibice}"
if [ -n "${USER_PASSWORD_FILE:-}" ] && [ -r "${USER_PASSWORD_FILE}" ]; then
    printf '%s:%s\n' "${DEV_USER}" "$(cat "${USER_PASSWORD_FILE}")" | sudo chpasswd
fi

# Optionally start the rathole client reverse tunnel, but only if a config is
# mounted. No config -> nothing happens. This lets the same image be used with
# or without a rathole endpoint (e.g. mount ./client.toml at /etc/rathole/).
RATHOLE_CONFIG="${RATHOLE_CONFIG:-/etc/rathole/client.toml}"
if command -v rathole > /dev/null 2>&1 && [ -f "${RATHOLE_CONFIG}" ]; then
    echo "starting rathole client with ${RATHOLE_CONFIG}"
    rathole --client "${RATHOLE_CONFIG}" &
fi

# Execute the CMD
exec "$@"
