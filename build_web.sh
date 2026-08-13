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
#            afterwards. English-only saves 3,904 KB (3.81 MB) of delivered
#            payload; see tools/locale_strip.dart for how and why.
#
#            On a Jenkins freestyle job this needs ONE string parameter named
#            LOCALES (default "all") and no change to any shell step, because
#            Jenkins exports build parameters as environment variables.
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
# Runs from a trap, so it also covers a build that fails or is interrupted. A
# SIGKILL gets past it, which is harmless on CI because the job re-clones its
# workspace — it matters for the developer running a stripped build locally, who
# gets told to run `restore` by the next build's own gate.
#
# Takes over the exit code on failure: a build that leaves a stripped tree behind
# has to fail loudly, even if the build itself succeeded.
function restoreLocales() {
  local buildStatus=$?
  echo "===== restoring all language packs (build exited ${buildStatus}) ====="
  if ! $DART run tools/locale_strip.dart restore; then
    echo "FAILED to restore language packs — the working tree is still stripped"
    echo "git status of the strippable paths:"
    git status --porcelain -- lib/l10n assets/fonts/fallback pubspec.yaml
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
echo "===== language packs: LOCALES=${LOCALES:-<unset>} -> ${locales} ====="
if [ "$locales" != "all" ]; then
    # Logged before the strip because the strip's own gate reads git status, and
    # a dirty workspace is the failure that is impossible to diagnose without it.
    echo "workspace state before stripping:"
    echo "  HEAD:   $(git rev-parse --short HEAD 2> /dev/null || echo unknown)"
    echo "  branch: $(git rev-parse --abbrev-ref HEAD 2> /dev/null || echo unknown)"
    echo "  git status --porcelain:"
    git status --porcelain | sed 's/^/    /'
    echo "  language packs present: $(ls lib/l10n/app_*.arb 2> /dev/null | wc -l | tr -d ' ')"
    echo "  fallback fonts present: $(ls assets/fonts/fallback 2> /dev/null | wc -l | tr -d ' ')"

    # Installed BEFORE the strip, not after: `keep` deletes files as it goes, so a
    # failure partway through leaves a stripped tree that only this trap puts
    # back. `restore` is idempotent and prints "nothing was stripped" on an intact
    # tree, so arming it early costs nothing when the strip never starts.
    trap restoreLocales EXIT
    if ! $DART run tools/locale_strip.dart keep "$locales"; then
        echo "language pack strip failed — nothing was built; the working tree"
        echo "may be partially stripped, which the restore below puts back"
        exit 1
    fi
    echo "  language packs kept:    $(ls lib/l10n/app_*.arb 2> /dev/null | wc -l | tr -d ' ')"
    echo "  fallback fonts kept:    $(ls assets/fonts/fallback 2> /dev/null | wc -l | tr -d ' ')"
    if ! $FLUTTER gen-l10n; then
        echo "gen-l10n failed after stripping to ${locales}"
        exit 1
    fi
    # The single line that says which flavour was actually compiled, so a console
    # log is enough to tell an English-only build from a retail one.
    echo "  locales compiled in:    $(grep -c 'Locale(' lib/l10n/gen/app_localizations.dart)"
fi

if ! buildWebApp "$buildNumber"; then
    echo Web App "$buildNumber" build failed
    exit 1
fi

# Reporting, not gating: a measurement that cannot run must not fail a build that
# already succeeded.
./tools/measure_payload.sh || echo "could not measure the delivered payload"
