#!/bin/bash

# Prints the size of the delivered payload — the subset of build/web that is
# packaged into /www/ on the router, and therefore the only part that consumes
# firmware flash.
#
# The SDK's build/web/canvaskit/ directory is excluded because CI prunes it; the
# CanvasKit builds that actually ship live under build/web/assets/. Quoting the
# whole build/web total as a firmware size overstates it by more than 2x.
#
# Usage:
#   ./tools/measure_payload.sh                  # print the payload size
#   ./tools/measure_payload.sh <baselineKB>     # ...and the delta against a baseline

set -uo pipefail

buildDir="build/web"
baseline=${1:-}

if [ ! -d "$buildDir" ]; then
  echo "no $buildDir — run a web build first" >&2
  exit 1
fi

# Arithmetic goes through awk rather than bc, which is absent from minimal CI
# images.
function toMB() {
  awk -v kb="$1" 'BEGIN { printf "%.2f", kb / 1024 }'
}

totalKB=$(du -sk "$buildDir" | cut -f1)
prunedKB=0
if [ -d "$buildDir/canvaskit" ]; then
  prunedKB=$(du -sk "$buildDir/canvaskit" | cut -f1)
fi
payloadKB=$((totalKB - prunedKB))

echo "Delivered payload: ${payloadKB} KB ($(toMB "$payloadKB") MB)"
echo "  build output:    ${totalKB} KB"
echo "  pruned by CI:    ${prunedKB} KB (canvaskit/)"

echo
echo "Largest contributors:"
# `awk NR<=10` rather than `head -10`: head closes the pipe early, which under
# pipefail turns sort's SIGPIPE into a non-zero exit for the whole script.
find "$buildDir" -path "$buildDir/canvaskit" -prune -o -type f -print0 |
  xargs -0 du -k |
  sort -rn |
  awk 'NR <= 10 { printf "  %8d KB  %s\n", $1, $2 }'

if [ -n "$baseline" ]; then
  echo
  deltaKB=$((baseline - payloadKB))
  echo "Reduction vs ${baseline} KB baseline: ${deltaKB} KB ($(toMB "$deltaKB") MB)"
fi
