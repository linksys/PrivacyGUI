function buildWebApp() {
  echo "start building web app #${buildNumber}-${force}-${cloud}"
  echo "base href is ${href}"

  if [ "$cloud" == "qa" ]; then
    flutter build web --target=lib/main.dart --base-href="/${href}" --build-number="${buildNumber}" --dart-define=force="${force}" --dart-define=cloud_env="${cloud}" --dart-define=enable_env_picker="${picker}" --web-renderer html --no-tree-shake-icons --source-maps
  else
    flutter build web --target=lib/main.dart --base-href="/${href}" --build-number="${buildNumber}" --dart-define=force="${force}" --dart-define=cloud_env="${cloud}" --dart-define=enable_env_picker="${picker}" --web-renderer html --no-tree-shake-icons
  fi  
  cp -r "./build/web" "./artifacts/webApp/"
}

buildNumber=$1
force=$2
href=$3
cloud=$4
picker=$5

if ! buildWebApp "$buildNumber"; then
    echo Web App "$buildNumber" build failed
    exit 1
fi
