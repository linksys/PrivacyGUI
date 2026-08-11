#!/bin/bash

# Usage:
#   ./build_web.sh <buildNumber> <force> <href> <cloud> <picker> <ca> [themeSource] [themeJson] [themeStudio]
#
# Examples:
#   ./build_web.sh 100 false "/" prod false true                        # Default theme
#   ./build_web.sh 100 false "/" prod false true cicd '{"style":"neo"}' # Override theme
#   ./build_web.sh 100 false "/" qa false true "" "" true               # Enable theme studio
#
# Environment:
#   LOCALES  Which language packs to ship. Unset or "all" builds exactly what it
#            has always built. Anything else strips the other language packs and
#            the fallback fonts they need before building, and restores them
#            afterwards — see docs/adr/0001-english-only-build-by-build-time-stripping.md
#
#   LOCALES=en ./build_web.sh 100 false "/" prod false true             # English-only

# Detect fvm: use fvm flutter if available, otherwise use flutter directly
if command -v fvm > /dev/null 2>&1 && [ -f ".fvmrc" ]; then
  FLUTTER="fvm flutter"
  DART="fvm dart"
  echo "Using fvm flutter"
else
  FLUTTER="flutter"
  DART="dart"
  echo "Using system flutter"
fi

function buildWebApp() {
  echo "start building web app #${buildNumber}-${force}-${cloud}"
  echo "base href is ${href}"

  $FLUTTER build web --target=lib/main.dart --base-href="/${href}" \
    --build-number="${buildNumber}" \
    --dart-define=force="${force}" \
    --dart-define=cloud_env="${cloud}" \
    --dart-define=enable_env_picker="${picker}" \
    --dart-define=ca="${ca}" \
    $themeSourceFlag $themeJsonFlag $themeStudioFlag $enableHTMLRenderer
}

# Puts back the language packs and fonts the strip deleted, and regenerates the
# localization sources so the working tree is coherent again.
#
# Runs from a trap, so it also covers a build that fails or is interrupted. Only
# an unstoppable kill can get past it, and the next stripped build's own gate
# catches that, because the leftovers show up as local changes.
#
# Takes over the exit code on failure: a build that leaves a stripped tree behind
# has to fail loudly, even if the build itself succeeded.
function restoreLocales() {
  local buildStatus=$?
  echo "restoring all language packs"
  if ! $DART run tools/locale_strip.dart restore; then
    echo "FAILED to restore language packs — the working tree is still stripped"
    exit 1
  fi
  # lib/l10n/gen is gitignored, so `verify` cannot see a stale English-only
  # generation. Failing here is the only thing that stops it going unnoticed.
  if ! $FLUTTER gen-l10n; then
    echo "FAILED to regenerate localizations — run 'flutter gen-l10n' before"
    echo "building again, or the app will only see English"
    exit 1
  fi
  exit $buildStatus
}

buildNumber=${1}
force=${2}
href=${3}
cloud=${4}
picker=${5}
ca=${6}
themeSource=${7}
themeJson=${8}
themeStudio=${9}

themeSourceFlag=""
if [ "$themeSource" != "" ]; then
    themeSourceFlag="--dart-define=THEME_SOURCE=${themeSource}"
fi

themeJsonFlag=""
if [ "$themeJson" != "" ]; then
    themeJsonFlag="--dart-define=THEME_JSON=${themeJson}"
fi

themeStudioFlag=""
if [ "$themeStudio" == "true" ]; then
    themeStudioFlag="--dart-define=theme_studio=true"
fi

enableHTMLRenderer=""
if [ "$FlutterVersion" == "3.27.1" ]; then
    enableHTMLRenderer="--web-renderer html"
fi

locales=${LOCALES:-all}
if [ "$locales" != "all" ]; then
    echo "stripping language packs down to: ${locales}"
    if ! $DART run tools/locale_strip.dart keep "$locales"; then
        echo "language pack strip failed — nothing was built"
        exit 1
    fi
    # From here on the working tree is modified, so every exit path restores it.
    trap restoreLocales EXIT
    if ! $FLUTTER gen-l10n; then
        echo "gen-l10n failed after stripping to ${locales}"
        exit 1
    fi
fi

if ! buildWebApp "$buildNumber"; then
    echo Web App "$buildNumber" build failed
    exit 1
fi

# Reporting, not gating: a measurement that cannot run must not fail a build that
# already succeeded.
./tools/measure_payload.sh || echo "could not measure the delivered payload"
