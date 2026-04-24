#!/bin/bash
# Serve the pre-built Flutter web app for Playwright tests.
#
# Usage:
#   bash scripts/serve.sh          # serve existing build
#   BUILD=1 bash scripts/serve.sh  # rebuild then serve
#
# Prerequisites:
#   - Flutter web build at ../build/web/
#   - npx serve (installed via package.json)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build/web"

# Optionally rebuild
if [ "${BUILD:-0}" = "1" ]; then
  echo "Building Flutter web..."
  cd "$PROJECT_ROOT"
  flutter build web --target=lib/main.dart --base-href="/" --build-number=100 \
    --dart-define=force="local" \
    --dart-define=cloud_env="prod" \
    --dart-define=enable_env_picker="false" \
    --dart-define=ca="true" \
    --dart-define=sse_disabled="true"
  echo "Build complete."
fi

# Check build exists
if [ ! -d "$BUILD_DIR" ]; then
  echo "ERROR: Flutter web build not found at $BUILD_DIR"
  echo "Run 'flutter build web' first, or use BUILD=1 bash scripts/serve.sh"
  exit 1
fi

PORT="${PORT:-4200}"
echo "Serving Flutter web from $BUILD_DIR on port $PORT..."
exec npx serve "$BUILD_DIR" -l "$PORT" --no-clipboard --single
