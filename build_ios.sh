
function buildInHouse() {
  version=$1
  flutter clean
  flutter build ipa --export-options-plist=ios/Scripts/Moab-EE-InHouse.plist;
  mv "./build/ios/ipa/Moab.ipa" "./build/ios/ipa/moab_app_ee_distribution.ipa"
  copyInHouseAssets
  updateLinks "$version"
}

function copyInHouseAssets() {
  iosAssetsPath=./ios/Scripts/InHouse
  targetOutputPath=./build/ios/ipa/
  assetFiles=$(ls "$iosAssetsPath"/*)
  for path in $assetFiles
  do
    name=$(basename "$path")
    cp "$path" "$targetOutputPath"/"$name"
    echo "Copied... $path"
  done
}

function updateLinks() {
  exho "Update links"
  version=$1
  htmlFilePath=./build/ios/ipa/install.html.template
  sed -i '' "s/{version}/$version/g" "$htmlFilePath"
  mv "$htmlFilePath" "./build/ios/ipa/install.html"
  manifestPath=./build/ios/ipa/manifest.plist
  sed -i '' "s/{version}/$version/g" "$manifestPath"
  sed -i '' "s/Runner/Moab App $version/g" "$manifestPath"
}
version=$1
if buildInHouse "$version"; then
  echo InHouse "$version" build failed
  exit 1
fi