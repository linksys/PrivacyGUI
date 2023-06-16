
function copyInHouseAssets() {
  iosAssetsPath=./ios/Scripts/InHouse
  targetOutputPath=./artifacts/
  assetFiles=$(ls "$iosAssetsPath"/*)
  for path in $assetFiles
  do
    name=$(basename "$path")
    cp "$path" "$targetOutputPath"/"$name"
    echo "Copied... $path"
  done
}

function updateLinks() {
  echo "Update links"
  version=$1
  htmlFilePath=./artifacts/install.html.template
  sed -i '' "s/{version}/$version/g" "$htmlFilePath"
  mv "$htmlFilePath" "./artifacts/install.html"
  manifestPath=./build/ios/ipa/manifest.plist
  sed -i '' "s/{version}/$version/g" "$manifestPath"
  sed -i '' "s/Runner/Moab App $version/g" "$manifestPath"
  mv "$manifestPath" "./artifacts/manifest.plist"
}
version=$1

copyInHouseAssets
updateLinks "$version"
echo "https://linksys-mobile.s3.us-west-1.amazonaws.com/${version}/install.html"
