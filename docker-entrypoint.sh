#!/bin/bash
set -e

# Generate unique SSH host keys on first start (never baked into the image).
if [ ! -f /etc/ssh/ssh_host_ed25519_key ]; then
    sudo ssh-keygen -A
fi

# Normalise ~/.ssh so sshd's StrictModes accepts it and git/ssh behave.
# The home may live on a PVC whose files are group-owned (k8s fsGroup), so
# ownership and modes are fixed on every start. No-op if ~/.ssh is absent.
if [ -d "$HOME/.ssh" ]; then
    sudo chown -R "$(id -u):$(id -g)" "$HOME/.ssh" 2>/dev/null || true
    chmod 700 "$HOME/.ssh" 2>/dev/null || true
    find "$HOME/.ssh" -maxdepth 1 -type f -name 'id_*' ! -name '*.pub' -exec chmod 600 {} + 2>/dev/null || true
    find "$HOME/.ssh" -maxdepth 1 -type f -name '*.pub' -exec chmod 644 {} + 2>/dev/null || true
    chmod 600 "$HOME/.ssh/authorized_keys" "$HOME/.ssh/config" "$HOME/.ssh/known_hosts" 2>/dev/null || true
fi

# Start the SSH daemon if it is not already running. sshd is optional: a
# failure here must not stop the dev shell.
if ! pgrep -x sshd > /dev/null; then
    sudo /usr/sbin/sshd || echo "warning: sshd failed to start" >&2
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
