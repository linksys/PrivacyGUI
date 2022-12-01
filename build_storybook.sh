
function buildStorybook() {
  echo "start building storybook #${buildNumber}"
  flutter build web  --target=lib/storybook.dart --build-number="${buildNumber}"
  mkdir -p "./build/ios/ipa"
  cp "./build/web" "./build/ios/ipa/web"
#  mv "./build/ios/ipa/Moab.ipa" "./build/ios/ipa/moab_app_ee_distribution_${inHouseBuildNumber}.ipa"
}

buildNumber=$1

pod repo update
flutter --version
flutter pub deps
flutter clean
flutter pub cache repair
if ! buildStorybook "$buildNumber"; then
    echo Storybook "$buildNumber" build failed
    exit 1
fi
