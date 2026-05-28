#!/bin/bash

# Usage:
#   ./build_web.sh <buildNumber> <force> <href> <cloud> <picker> <ca> [themeSource] [themeJson] [themeStudio]
#
# Examples:
#   ./build_web.sh 100 false "/" prod false true                        # Default theme
#   ./build_web.sh 100 false "/" prod false true cicd '{"style":"neo"}' # Override theme
#   ./build_web.sh 100 false "/" qa false true "" "" true               # Enable theme studio

# Detect fvm: use fvm flutter if available, otherwise use flutter directly
if command -v fvm > /dev/null 2>&1 && [ -f ".fvmrc" ]; then
  FLUTTER="fvm flutter"
  echo "Using fvm flutter"
else
  FLUTTER="flutter"
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

if ! buildWebApp "$buildNumber"; then
    echo Web App "$buildNumber" build failed
    exit 1
fi
