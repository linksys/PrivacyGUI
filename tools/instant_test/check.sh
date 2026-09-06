#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
FLUTTER_BIN="${FLUTTER_BIN:-flutter}"
"$FLUTTER_BIN" test --no-pub \
  test/page/instant_verify/views/single_page_test.dart \
  test/page/instant_verify/views/help_me_fix_it_tab_test.dart
if [[ "${1:-}" == "--build" ]]; then
  "$FLUTTER_BIN" build web --no-pub --target=lib/main.dart --base-href=/ \
    --dart-define=force=local --dart-define=enable_env_picker=false \
    --dart-define=cloud_env=prod --no-tree-shake-icons --output=build/instant_test
fi
