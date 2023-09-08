function buildWebApp() {
  echo "start building storybook #${buildNumber}"
  flutter build web --target=lib/main.dart --base-href=/app/ --build-number="${buildNumber}" --no-tree-shake-icons
  cp -r "./build/web" "./artifacts/webApp/"
}

buildNumber=$1

if ! buildWebApp "$buildNumber"; then
    echo Web App "$buildNumber" build failed
    exit 1
fi
