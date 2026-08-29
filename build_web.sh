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
#   These two are the ONLY variables this script reads from its environment, and
#   the list is exhaustive on purpose: a Jenkins freestyle job exports every
#   build parameter as an environment variable, so a name here is a contract with
#   whoever configures that job, and a name that is read but undocumented is
#   invisible from both sides.
#
#   `FlutterVersion` used to be a third, and it is worth knowing why it is gone
#   rather than rediscovering it. It gated `--web-renderer html` on the literal
#   "3.27.1" — a flag `flutter build web` removed in 3.44 and which does NOT
#   degrade gracefully: it exits with `Could not find an option named
#   "--web-renderer"` (verified on 3.47.0). So any job still passing 3.27.1 was
#   failing its build outright, and no supported SDK could make that branch
#   correct. If a Jenkins job still sets FlutterVersion, it is now inert here.
#
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
#
#   Compress Set to "true" to pre-compress the large static assets with brotli
#            and delete the originals (#1282). Off unless explicitly set, because
#            it is inert — worse, a white screen — until the firmware ships the
#            matching lighttpd rewrite rules. Same Jenkins story as LOCALES: one
#            boolean parameter named Compress, no shell-step change.
#
#   Compress=true ./build_web.sh 100 false "/" prod false true          # Pre-compressed

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
    $themeSourceFlag $themeJsonFlag $themeStudioFlag
}

# Puts back the language packs and fonts the strip deleted, and regenerates the
# localization sources so the working tree is coherent again.
#
# Runs from a trap, so it also covers a build that fails or is interrupted. A
# SIGKILL gets past it, which is harmless on CI because the job re-clones its
# workspace — it matters for the developer running a stripped build locally, who
# gets told to run `restore` by the next build's own gate.
#
# The trap is `EXIT` alone, deliberately. bash runs an EXIT trap on SIGINT and
# SIGTERM too, so naming them adds no coverage — measured: `trap ... EXIT` fires
# on both, and `trap ... EXIT INT TERM` fires the handler *twice* on either
# signal, which would run a second `restore` over an already-restored tree.
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

# Removes build output that is never served, so it cannot reach the router's
# flash. This runs unconditionally: it is a property of what we ship, not an
# option, and keeping it next to the build makes the reasoning visible to
# whoever next wonders why a directory disappears.
#
# build/web/canvaskit/ is the engine's own CanvasKit output (~37 MB, including
# ~8.6 MB of *.symbols). Nothing requests it: flutter_bootstrap.js pins
# canvasKitBaseUrl: "./assets/", so the loader only ever fetches
# assets/canvaskit.*, which are hand-vendored copies committed under web/assets/
# (see #1281 and test/web/canvaskit_variant_test.dart). Shipping the directory
# would silently give back the flash #1281 reclaimed.
#
# Deliberately targeted paths, not a `find -iname canvaskit` sweep from the
# workspace root: such a sweep also matches the FVM SDK's own
# .fvm/flutter_sdk/bin/cache/flutter_web_sdk/canvaskit when flutter_sdk is a real
# directory rather than a symlink, and rm -rf on that breaks the next build with
# an error pointing somewhere unrelated.
#
# Idempotent, so the Jenkins job's own deletion step — which 1.x still needs —
# stays a harmless no-op on 2.x rather than something to keep in sync.
function pruneWebOutput() {
  echo "======== Pruning unserved build output ========"
  local prune=(
    build/web/canvaskit
  )

  local p
  for p in "${prune[@]}"; do
    if [ -e "$p" ]; then
      echo "  removing $p ($(du -sh "$p" 2> /dev/null | cut -f1))"
      if ! rm -rf "$p"; then
        echo "ERROR: could not remove $p"
        return 1
      fi
    else
      echo "  already absent: $p"
    fi
  done
}

# Pre-compresses the large static assets with brotli and deletes the originals,
# so the router serves compressed bytes without needing a server-side brotli
# library (its lighttpd has none). See #1282 for the measurements.
#
# gzip is deliberately not used here. Its output is near-incompressible, which
# defeats the rootfs squashfs XZ layer and makes flash LARGER (9.45 -> 10.76 MB
# measured), while also transferring ~1.3 MB more per cold load than brotli.
#
# The target list is explicit rather than a glob: a rewrite rule that matches
# every .js/.wasm would also rewrite files that have no .br sibling
# (canvaskit.js, flutter.js, usp_client.js, usp_client_bg.wasm), and each of
# those is a 404 and a white screen. The list and the disk must agree, so a
# missing target is a hard failure, never a silent skip.
#
# Inert without the server half: pre-compressed files with no lighttpd rewrite
# rule are just 404s. Keep this off until the firmware team ships the config.
#
# Two compressors are accepted because the CI agent may not have the brotli CLI
# (the current one does not; it does have node). Node's zlib is built on the same
# libbrotli and at q11/lgwin=24 produces output of identical size — byte-identical
# for main.dart.js, while canvaskit.wasm differs only in the one-byte window-size
# header, since the CLI auto-sizes lgwin down to 23 for a 7.2 MB input. Both
# decode back to the exact original.
#
# lgwin must be set explicitly: Node defaults to 22 while the CLI auto-sizes to
# the input, which costs ~7.5 KB on main.dart.js. 24 is BROTLI_MAX_WINDOW_BITS,
# the largest window needing no client negotiation, so browsers still decode it.
function compressWebAssets() {
  echo "======== Pre-compressing web assets (brotli -q11) ========"
  local targets=(
    build/web/main.dart.js
    build/web/assets/canvaskit.wasm
  )

  local compressor=""
  if command -v brotli > /dev/null 2>&1; then
    compressor="cli"
  elif command -v node > /dev/null 2>&1; then
    compressor="node"
  else
    echo "ERROR: no brotli compressor available (need the brotli CLI or node)"
    return 1
  fi
  echo "  compressor: $compressor"

  # Checks the whole list before touching anything, so a target name that goes
  # stale cannot leave the tree half-compressed — which serves as a mix of
  # rewritten and unrewritten files, i.e. a white screen rather than a failure.
  local f
  local missing=0
  for f in "${targets[@]}"; do
    if [ ! -f "$f" ]; then
      echo "ERROR: expected compression target missing: $f"
      missing=1
    fi
  done
  if [ "$missing" -ne 0 ]; then
    echo "ERROR: target list and build output disagree; nothing was compressed"
    return 1
  fi

  for f in "${targets[@]}"; do
    # -c > "$f.br" rather than brotli's in-place mode: no dependency on -k
    # semantics, and the original is removed explicitly below.
    if [ "$compressor" = "cli" ]; then
      if ! brotli -q 11 -c "$f" > "$f.br"; then
        echo "ERROR: brotli failed on $f"
        rm -f "$f.br"
        return 1
      fi
    else
      if ! node -e '
const fs = require("fs"), zlib = require("zlib");
const buf = fs.readFileSync(process.argv[1]);
fs.writeFileSync(process.argv[2], zlib.brotliCompressSync(buf, {
  params: {
    [zlib.constants.BROTLI_PARAM_QUALITY]: 11,
    [zlib.constants.BROTLI_PARAM_LGWIN]: zlib.constants.BROTLI_MAX_WINDOW_BITS,
    [zlib.constants.BROTLI_PARAM_SIZE_HINT]: buf.length,
  },
}));' "$f" "$f.br"; then
        echo "ERROR: node brotli failed on $f"
        rm -f "$f.br"
        return 1
      fi
    fi
    if ! rm "$f"; then
      echo "ERROR: could not remove original: $f"
      return 1
    fi
    echo "  $(basename "$f") -> $(basename "$f").br"
  done

  # Consistency gate. A surviving original means lighttpd would serve it
  # unrewritten; a missing .br means a 404 and a white screen.
  for f in "${targets[@]}"; do
    if [ ! -f "$f.br" ]; then
      echo "ERROR: missing $f.br after compression"
      return 1
    fi
    if [ -f "$f" ]; then
      echo "ERROR: original survived: $f"
      return 1
    fi
  done

  echo "Pre-compression OK: ${#targets[@]} files"
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
    #
    # Anchored to the indented Locale entries of the supportedLocales list. A bare
    # 'Locale(' also matches intl.Intl.canonicalizedLocale( elsewhere in the
    # generated file, which reported 27 for the retail build's 26 packs — and 2
    # for an English-only one, reading as if a language pack had leaked in.
    compiledLocales=$(grep -cE "^ +Locale" lib/l10n/gen/app_localizations.dart)
    echo "  locales compiled in:    ${compiledLocales}"
fi

if ! buildWebApp "$buildNumber"; then
    echo Web App "$buildNumber" build failed
    exit 1
fi

if ! pruneWebOutput; then
    echo Web App "$buildNumber" prune failed
    exit 1
fi

echo "Compress files? ${Compress:-false}"
if [ "$Compress" == "true" ]; then
    if ! compressWebAssets; then
        echo Web App "$buildNumber" pre-compression failed
        exit 1
    fi
fi

# Last, so that what it measures is exactly what gets packaged: the prune has
# already removed the unserved directory and any pre-compression has already
# replaced the originals.
#
# Reporting, not gating: a measurement that cannot run must not fail a build that
# already succeeded.
./tools/measure_payload.sh || echo "could not measure the delivered payload"
