
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
  echo "Update links"
  version=$1
  htmlFilePath=./build/ios/ipa/install.html.template
  sed -i '' "s/{version}/$version/g" "$htmlFilePath"
  mv "$htmlFilePath" "./build/ios/ipa/install.html"
  manifestPath=./build/ios/ipa/manifest.plist
  sed -i '' "s/{version}/$version/g" "$manifestPath"
  sed -i '' "s/Runner/Moab App $version/g" "$manifestPath"
}
tmp=$1
((version=510000+tmp))

copyInHouseAssets
updateLinks "$version"
print "https://linksys-moab.s3.us-west-1.amazonaws.com/${version}/install.html"
