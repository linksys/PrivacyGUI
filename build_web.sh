function buildWebApp() {
  echo "start building web app #${buildNumber}-${force}"
  echo "base href is ${href}"

  flutter build web --target=lib/main.dart --base-href="/${href}/" --build-number="${buildNumber}" --dart-define=force="${force}" --web-renderer html --no-tree-shake-icons
  cp -r "./build/web" "./artifacts/webApp/"
}

buildNumber=$1
force=$2
href=$3

if ! buildWebApp "$buildNumber"; then
    echo Web App "$buildNumber" build failed
    exit 1
fi
