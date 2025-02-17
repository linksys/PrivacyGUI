function buildWebApp() {
  echo "start building web app #${buildNumber}-${force}-${cloud}"
  echo "base href is ${href}"

  if [ "$cloud" == "qa" ]; then
    flutter build web --target=lib/main.dart --base-href="/${href}" --build-number="${buildNumber}" --dart-define=force="${force}" --dart-define=cloud_env="${cloud}" --dart-define=enable_env_picker="${picker}" --dart-define=ca="${ca}" --no-tree-shake-icons
  else
    flutter build web --target=lib/main.dart --base-href="/${href}" --build-number="${buildNumber}" --dart-define=force="${force}" --dart-define=cloud_env="${cloud}" --dart-define=enable_env_picker="${picker}" --dart-define=ca="${ca}" --web-renderer html --no-tree-shake-icons
  fi
  # rm -rf ./build/web/canvasKit  
}

buildNumber=$1
force=$2
href=$3
cloud=$4
picker=$5
ca=$6

if ! buildWebApp "$buildNumber"; then
    echo Web App "$buildNumber" build failed
    exit 1
fi
