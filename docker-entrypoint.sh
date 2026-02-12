#!/bin/bash
set -e

# Start SSH daemon if not running
if ! pgrep -x sshd > /dev/null; then
    /usr/sbin/sshd
fi

# Execute the CMD
exec "$@"
