function buildWebApp() {
  echo "start building web app #${buildNumber}-${force}"
  baseHref="/app/"
  if [ "$force" = "local" ]; then
    baseHref="/ui/local/dynamic/"
  fi
  echo "base href is ${baseHref}"
  flutter build web --target=lib/main.dart --base-href="${baseHref}" --build-number="${buildNumber}" --dart-define=force="${force}" --web-renderer html --no-tree-shake-icons
  cp -r "./build/web" "./artifacts/webApp/"
}

buildNumber=$1
force=$2

if ! buildWebApp "$buildNumber"; then
    echo Web App "$buildNumber" build failed
    exit 1
fi
