
function buildInHouse() {
  echo "start building in house #${buildNumber}"
  flutter build ipa --export-options-plist=ios/Scripts/Moab-EE-InHouse.plist --flavor=Enterprise --build-number="${inHouseBuildNumber}" --dart-define=cloud_env=qa
  mv "./build/ios/ipa/Moab.ipa" "./build/ios/ipa/moab_app_ee_distribution_${inHouseBuildNumber}.ipa"
}

function buildAppStore() {
  echo "start building app store #${buildNumber}"
  flutter build ipa --export-options-plist=ios/Scripts/Moab-Distribution-app-store.plist --flavor=Moab --build-number="${appStoreBuildNumber}" --dart-define=cloud_env=qa
  mv "./build/ios/ipa/Moab.ipa" "./build/ios/ipa/moab_app_distribution_app_store_${appStoreBuildNumber}.ipa"
}

function buildSimulatorApp() {
    echo "start building simulator app"
    flutter build ios --simulator;
    mv "./build/ios/iphonesimulator/Runner.app" "./build/ios/iphonesimulator/moab_app_simulator.app"
    zip -r "./build/ios/iphonesimulator/moab_app_simulator.app.zip" ./*
    mv "./build/ios/iphonesimulator/moab_app_simulator.app.zip" "./build/ios/ipa/moab_app_simulator.app.zip"
}

buildNumber=$1
inHouseBuild=$2
appStoreBuild=$3
((inHouseBuildNumber=510000+buildNumber))
((appStoreBuildNumber=530000+buildNumber))
pod repo update
flutter --version
flutter pub deps
echo "Flutter clean..."
flutter clean
echo "upgrade major versions..."
flutter pub upgrade --major-versions
if [ "${inHouseBuild}" == "true" ] ; then
  if ! buildInHouse "$buildNumber"; then
    echo InHouse "$buildNumber" build failed
    exit 1
  fi
fi
if [ "${appStoreBuild}" == "true" ] ; then
if ! buildAppStore "$buildNumber"; then
  echo AppStore "$buildNumber" build failed
  exit 1
fi
fi

#if ! buildSimulatorApp "$version"; then
#    echo Simulator app "$version" build failed
#    exit 1
#fi
