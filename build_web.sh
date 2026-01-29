function buildWebApp() {
  echo "start building web app #${buildNumber}-${force}-${cloud}"
  echo "base href is ${href}"

  
  if [ "$cloud" == "qa" ]; then
    flutter build web --target=lib/main.dart --base-href="/${href}" --build-number="${buildNumber}" --dart-define=force="${force}" --dart-define=cloud_env="${cloud}" --dart-define=enable_env_picker="${picker}" --dart-define=ca="${ca}" --dart-define=THEME_JSON="${theme}" $enableHTMLRenderer
  else
    flutter build web --target=lib/main.dart --base-href="/${href}" --build-number="${buildNumber}" --dart-define=force="${force}" --dart-define=cloud_env="${cloud}" --dart-define=enable_env_picker="${picker}" --dart-define=ca="${ca}" --dart-define=THEME_JSON="${theme}" $enableHTMLRenderer
  fi
  # rm -rf ./build/web/canvasKit  
}

buildNumber=$1
force=$2
href=$3
cloud=$4
picker=$5
ca=$6
theme=$7

enableHTMLRenderer=""
if [ "$FlutterVersion" == "3.27.1" ]; then
    enableHTMLRenderer="--web-renderer html"
fi

if ! buildWebApp "$buildNumber"; then
    echo Web App "$buildNumber" build failed
    exit 1
fi
