#!/bin/bash

# Detect fvm: use fvm flutter if available, otherwise use flutter directly
if command -v fvm &> /dev/null && [ -f ".fvmrc" ]; then
  FLUTTER="fvm flutter"
  echo "Using fvm flutter"
else
  FLUTTER="flutter"
  echo "Using system flutter"
fi

function buildWebApp() {
  echo "start building web app #${buildNumber}-${force}-${cloud}"
  echo "base href is ${href}"

  if [ "$cloud" == "qa" ]; then
    $FLUTTER build web --target=lib/main.dart --base-href="/${href}" --build-number="${buildNumber}" --dart-define=force="${force}" --dart-define=cloud_env="${cloud}" --dart-define=enable_env_picker="${picker}" --dart-define=ca="${ca}" --dart-define=THEME_SOURCE="${themeSource}" --dart-define=THEME_JSON="${themeJson}" $enableHTMLRenderer
  else
    $FLUTTER build web --target=lib/main.dart --base-href="/${href}" --build-number="${buildNumber}" --dart-define=force="${force}" --dart-define=cloud_env="${cloud}" --dart-define=enable_env_picker="${picker}" --dart-define=ca="${ca}" --dart-define=THEME_SOURCE="${themeSource}" --dart-define=THEME_JSON="${themeJson}" $enableHTMLRenderer
  fi
  # rm -rf ./build/web/canvasKit
}

buildNumber=$1
force=$2
href=$3
cloud=$4
picker=$5
ca=$6
themeSource=$7
themeJson=$8

enableHTMLRenderer=""
if [ "$FlutterVersion" == "3.27.1" ]; then
    enableHTMLRenderer="--web-renderer html"
fi

if ! buildWebApp "$buildNumber"; then
    echo Web App "$buildNumber" build failed
    exit 1
fi
