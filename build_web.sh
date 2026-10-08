function buildWebApp() {
  echo "start building web app #${buildNumber}-${force}-${cloud}"
  echo "base href is ${href}"
  echo "source revision is ${SOURCE_REVISION}, remote assistance is ${ENABLE_REMOTE_ASSISTANCE}"

  # The qa and non-qa branches this replaces were byte-identical, which is how
  # both of the flags below came to be appended twice.
  flutter build web --target=lib/main.dart --base-href="/${href}" --build-number="${buildNumber}" --dart-define=force="${force}" --dart-define=cloud_env="${cloud}" --dart-define=enable_env_picker="${picker}" --dart-define=ca="${ca}" $enableHTMLRenderer --dart-define=year="${YEAR}" --dart-define=source_revision="${SOURCE_REVISION}" --dart-define=enable_remote_assistance="${ENABLE_REMOTE_ASSISTANCE}"
  # rm -rf ./build/web/canvasKit
}

buildNumber=$1
force=$2
href=$3
cloud=$4
picker=$5
ca=$6
YEAR=$(date +%Y)

# Derived here rather than passed in, so the script keeps its six-argument
# signature and every existing caller works unchanged. An externally supplied
# SOURCE_REVISION wins, for build environments where the working directory is
# not the checkout.
#
# Resolved against the script's own directory, not the caller's: invoked from
# elsewhere, or from a workspace nested inside another repository, a bare
# `git rev-parse` reports that other repository's HEAD - a plausible-looking but
# wrong revision, with no error to notice.
SOURCE_REVISION="${SOURCE_REVISION:-$(git -C "$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)" rev-parse --short HEAD 2>/dev/null || echo unknown)}"

# Off unless the build environment asks for it. bool.fromEnvironment accepts only
# the literal "true" or "false" and silently falls back to its default for
# anything else, so TRUE / 1 / yes would ship the feature off while the build log
# echoed the value back as if it had been understood. Rejected here instead.
ENABLE_REMOTE_ASSISTANCE="${ENABLE_REMOTE_ASSISTANCE:-false}"
if [ "$ENABLE_REMOTE_ASSISTANCE" != "true" ] && [ "$ENABLE_REMOTE_ASSISTANCE" != "false" ]; then
    echo "ENABLE_REMOTE_ASSISTANCE must be exactly 'true' or 'false', got '${ENABLE_REMOTE_ASSISTANCE}'" >&2
    exit 1
fi

enableHTMLRenderer=""
if [ "$FlutterVersion" == "3.27.1" ]; then
    enableHTMLRenderer="--web-renderer html"
fi

if ! buildWebApp "$buildNumber"; then
    echo Web App "$buildNumber" build failed
    exit 1
fi
