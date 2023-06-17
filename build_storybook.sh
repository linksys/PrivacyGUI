
function buildStorybook() {
  echo "start building storybook #${buildNumber}"
  flutter build web --target=lib/storybook/storybook.dart --base-href=/storybook/ --build-number="${buildNumber}" --no-tree-shake-icons
  mkdir -p "./build/ios/ipa"
  cp -r "./build/web" "./build/ios/ipa/web"
}

buildNumber=$1

#pod repo update
#flutter --version
#flutter pub deps
#flutter clean
#flutter pub cache repair
if ! buildStorybook "$buildNumber"; then
    echo Storybook "$buildNumber" build failed
    exit 1
fi
