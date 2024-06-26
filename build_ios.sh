
function buildInHouse() {
  echo "start building in house #${inHouseBuildNumber}"
  flutter build ipa --export-options-plist=ios/Scripts/Linksys-EE-InHouse.plist --flavor=Enterprise --build-number="${inHouseBuildNumber}" --dart-define=cloud_env=qa --no-tree-shake-icons
  mkdir -p "./artifacts"
  mv "./build/ios/ipa/Linksys.ipa" "./artifacts/linksys_app_ee_distribution_${inHouseBuildNumber}.ipa"
}

function buildAppStore() {
  echo "start building app store #${appStoreBuildNumber}"
  flutter build ipa --export-options-plist=ios/Scripts/Linksys-Distribution-app-store.plist --flavor=Linksys --build-number="${appStoreBuildNumber}" --dart-define=cloud_env=qa --no-tree-shake-icons
  mkdir -p "./artifacts"
  mv "./build/ios/ipa/Linksys.ipa" "./artifacts/linksys_app_distribution_app_store_${appStoreBuildNumber}.ipa"
}

function buildSimulatorApp() {
    echo "start building simulator app"
    flutter build ios --simulator;
    mv "./build/ios/iphonesimulator/Runner.app" "./artifacts/linksys_app_simulator.app"
    zip -r "./build/ios/iphonesimulator/linksys_app_simulator.app.zip" ./*
    mv "./build/ios/iphonesimulator/linksys_app_simulator.app.zip" "./artifacts/linksys_app_simulator.app.zip"
}

inHouseBuildNumber=$1
appStoreBuildNumber=$2
inHouseBuild=$3
appStoreBuild=$4
flutter pub get
cd ios
pod install --repo-update
cd ..
flutter --version
flutter pub get
flutter pub deps
flutter clean
flutter pub cache repair
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
