#!/bin/bash
# Mutation check for the service-worker guard in
# test/web/canvaskit_variant_test.dart (#1623).
#
# Each mutant writes one way of bringing the reload loop back into
# web/service_worker.js or web/flutter_bootstrap.js, runs the guard, and expects
# it to go red. The controls put the same text inside a comment and expect it to
# stay green, because the reason a line was removed belongs in the file it was
# removed from. Every mutant restores both files before the next one runs, and
# the script refuses to start on a dirty copy of either.
#
# Run it when you change the guard or its comment-stripping helper. It is not
# part of CI: it runs the test file once per mutant, about 25 s each.
#
#   ./tools/sw_guard_mutations.sh
#
# Exit 0 = every mutant red and every control green.

set -u
cd "$(dirname "$0")/.."

SW=web/service_worker.js
BS=web/flutter_bootstrap.js
TEST=test/web/canvaskit_variant_test.dart

if ! git diff --quiet -- "$SW" "$BS"; then
  echo "ERROR: $SW or $BS has uncommitted changes; commit or discard them first."
  exit 2
fi

if command -v fvm > /dev/null 2>&1 && [ -f .fvmrc ]; then FLUTTER="fvm flutter"; else FLUTTER=flutter; fi

tmp=$(mktemp -d)
trap 'cp "$tmp/sw" "$SW"; cp "$tmp/bs" "$BS"; rm -rf "$tmp"' EXIT
cp "$SW" "$tmp/sw"
cp "$BS" "$tmp/bs"

fails=0
total=0
run() {
  local name="$1" want="$2" got
  total=$((total + 1))
  if $FLUTTER test "$TEST" > "$tmp/log" 2>&1; then got=green; else got=red; fi
  if [ "$got" = "$want" ]; then
    printf 'ok     %-52s %s\n' "$name" "$got"
  else
    printf 'WRONG  %-52s %s (want %s)\n' "$name" "$got" "$want"
    fails=$((fails + 1))
  fi
  cp "$tmp/sw" "$SW"
  cp "$tmp/bs" "$BS"
}
# Append one line to the worker.
sw() { printf '%s\n' "$1" >> "$SW"; }
# Replace text in a file (literal, first occurrence).
sub() { python3 - "$1" "$2" "$3" << 'EOF'
import sys
path, old, new = sys.argv[1:4]
s = open(path).read()
if old not in s:
    sys.exit(f"mutant target not found in {path}: {old!r}")
open(path, 'w').write(s.replace(old, new, 1))
EOF
}

# Bringing the cleanup worker back.
sw "importScripts('flutter_service_worker.js');";                            run "importScripts" red
sw "self.importScripts('flutter_service_worker.js');";                       run "self.importScripts" red
# Its two effects, written directly.
sw "self.registration.unregister();";                                        run "unregister()" red
sw "self.registration.unregister?.();";                                      run "unregister?.()" red
sw "self.registration.unregister ();";                                       run "unregister ()" red
sw "clients.matchAll().then((cs) => cs.forEach((c) => c.navigate(c.url)));"; run "navigate()" red
sw "clients.matchAll().then((cs) => cs.forEach((c) => c.navigate?.(c.url)));"; run "navigate?.()" red
sw "clients.matchAll().then((cs) => cs.forEach((c) => c['navigate'](c.url)));"; run "['navigate']()" red
# A fetch handler or a cache.
sw "self.addEventListener('fetch', () => {});";                              run "fetch, single quotes" red
sw 'self.addEventListener("fetch", () => {});';                              run "fetch, double quotes" red
sw 'self.addEventListener(`fetch`, () => {});';                              run "fetch, backticks" red
sw "self.onfetch = () => {};";                                               run "onfetch" red
sw "caches.open('x');";                                                      run "caches" red
sw "self.caches.open('x');";                                                 run "self.caches" red
# Required lines that only survive as comments.
sub "$SW" "  self.skipWaiting();" "  void 0; // self.skipWaiting();";         run "skipWaiting only in a trailing comment" red
sub "$SW" "  self.skipWaiting();" "  /* self.skipWaiting(); */";              run "skipWaiting only in a block comment" red
sub "$SW" "  event.waitUntil(clients.claim());" "  void 0;";                 run "clients.claim dropped" red
sub "$BS" '    serviceWorkerUrl: "service_worker.js"' '    // serviceWorkerUrl: "service_worker.js"'; run "serviceWorkerUrl commented out" red
sub "$BS" '    serviceWorkerUrl: "service_worker.js"' '    /* serviceWorkerUrl: "service_worker.js" */'; run "serviceWorkerUrl in a block comment" red
sub "$BS" '    canvasKitVariant: "full"' '    // canvasKitVariant: "full"';  run "canvasKitVariant commented out" red
# A /* inside a // comment must not open a block that hides real code (review of #1623).
sw "// TODO: /* fix later"; sw "importScripts('flutter_service_worker.js');"; sw "/* unrelated */"; run "'// /*' hiding an import" red
# Controls: the same text, only in comments.
sw "// importScripts('flutter_service_worker.js');";                         run "CONTROL import in a line comment" green
sw "/* importScripts('flutter_service_worker.js'); */";                      run "CONTROL import in a block comment" green

echo
echo "$((total - fails)) of $total as expected"
[ "$fails" -eq 0 ]
