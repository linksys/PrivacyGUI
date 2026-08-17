#!/bin/bash

# Prints the size of the delivered payload — the subset of build/web that is
# packaged into /www/ on the router, and therefore the only part that consumes
# firmware flash.
#
# The SDK's build/web/canvaskit/ directory is excluded because it is never served;
# the CanvasKit builds that actually ship live under build/web/assets/. Quoting the
# whole build/web total as a firmware size overstates it by more than 2x.
#
# build_web.sh deletes that directory before calling this script, so the pruned
# line reads 0 KB there. The subtraction stays for the standalone case — a plain
# `flutter build web` followed by running this by hand — where it is the whole
# difference between a real payload figure and a doubled one.
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
#
# `du` is allowed to fail quietly: xargs splits past ARG_MAX, so on a large tree
# du runs in several batches and one unreadable file would otherwise take the
# whole pipeline down under pipefail — discarding the nine contributors it did
# measure. The Top-10 is diagnostic output, not a gate.
find "$buildDir" -path "$buildDir/canvaskit" -prune -o -type f -print0 |
  xargs -0 du -k 2> /dev/null |
  sort -rn |
  awk 'NR <= 10 { printf "  %8d KB  %s\n", $1, $2 }'

if [ -n "$baseline" ]; then
  # Validated before the arithmetic: `$(( ))` on a non-numeric baseline aborts
  # with "unbound variable" under `set -u`, which reads as a broken script rather
  # than the mistyped argument it is.
  if ! [[ "$baseline" =~ ^[0-9]+$ ]]; then
    echo "baseline must be a whole number of KB, got: ${baseline}" >&2
    exit 2
  fi
  echo
  deltaKB=$((baseline - payloadKB))
  echo "Reduction vs ${baseline} KB baseline: ${deltaKB} KB ($(toMB "$deltaKB") MB)"
fi
