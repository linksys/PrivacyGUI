
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
  sed -i '' "s/Runner/Linksys Flutter $version/g" "$manifestPath"
  mv "$manifestPath" "./artifacts/manifest.plist"
}
version=$1
url="https://linksys-mobile.s3.us-west-1.amazonaws.com/${version}/install.html"
dart run ios/Scripts/qr_code_generator.dart $url

copyInHouseAssets
updateLinks "$version"
echo $url
