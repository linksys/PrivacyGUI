#!/bin/bash
# Deploy Flutter web build to the local router at 192.168.1.1
#
# REQUIRED: --dart-define=force=local tells the app to use window.location.host
# as the JNAP target instead of the WiFi connectivity plugin (which doesn't work
# on web). Omitting this flag causes JNAP calls to go to a malformed URL and
# the app fails to authenticate.
#
# Usage: ./scripts/deploy_local.sh

set -e
cd "$(dirname "$0")/.."

echo "▶ Building Flutter web (force=local)..."
~/.pub-cache/bin/fvm flutter build web \
  --dart-define=force=local \
  --no-tree-shake-icons

echo "▶ Deploying to router at 192.168.1.1..."
sshpass -f ~/.secrets/router-pass scp -O \
  -o StrictHostKeyChecking=no \
  -o KexAlgorithms=+diffie-hellman-group1-sha1 \
  -o HostKeyAlgorithms=+ssh-rsa \
  -r build/web/* root@192.168.1.1:/www/

echo "✓ Done — open http://192.168.1.1 to verify"
