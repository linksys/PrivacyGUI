function buildWebApp() {
  echo "start building web app #${buildNumber}-${force}-${cloud}"
  echo "base href is ${href}"
  echo "source revision is ${SOURCE_REVISION}, remote assistance is ${ENABLE_REMOTE_ASSISTANCE}"

  if [ "$cloud" == "qa" ]; then
    flutter build web --target=lib/main.dart --base-href="/${href}" --build-number="${buildNumber}" --dart-define=force="${force}" --dart-define=cloud_env="${cloud}" --dart-define=enable_env_picker="${picker}" --dart-define=ca="${ca}" $enableHTMLRenderer --dart-define=year="${YEAR}" --dart-define=source_revision="${SOURCE_REVISION}" --dart-define=enable_remote_assistance="${ENABLE_REMOTE_ASSISTANCE}"
  else
    flutter build web --target=lib/main.dart --base-href="/${href}" --build-number="${buildNumber}" --dart-define=force="${force}" --dart-define=cloud_env="${cloud}" --dart-define=enable_env_picker="${picker}" --dart-define=ca="${ca}" $enableHTMLRenderer --dart-define=year="${YEAR}" --dart-define=source_revision="${SOURCE_REVISION}" --dart-define=enable_remote_assistance="${ENABLE_REMOTE_ASSISTANCE}"
  fi
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
SOURCE_REVISION="${SOURCE_REVISION:-$(git rev-parse --short HEAD 2>/dev/null || echo unknown)}"

# Off unless the build environment asks for it. Must be the literal string
# "true": bool.fromEnvironment accepts only "true"/"false" and silently falls
# back to the default for anything else.
ENABLE_REMOTE_ASSISTANCE="${ENABLE_REMOTE_ASSISTANCE:-false}"

enableHTMLRenderer=""
if [ "$FlutterVersion" == "3.27.1" ]; then
    enableHTMLRenderer="--web-renderer html"
fi

if ! buildWebApp "$buildNumber"; then
    echo Web App "$buildNumber" build failed
    exit 1
fi
