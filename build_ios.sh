
function buildInHouse() {
  flutter clean
  flutter build ipa --export-options-plist=ios/Scripts/Moab-EE-InHouse.plist
}

buildInHouse
