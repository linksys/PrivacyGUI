#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
FLUTTER_BIN="${FLUTTER_BIN:-flutter}"
"$FLUTTER_BIN" test --no-pub \
  test/page/instant_verify/views
if [[ "${1:-}" == "--build" ]]; then
  "$FLUTTER_BIN" build web --no-pub --target=lib/main.dart --base-href=/ \
    --dart-define=force=local --dart-define=enable_env_picker=false \
    --dart-define=cloud_env=prod --no-tree-shake-icons --output=build/instant_test
fi
