#!/bin/bash
set -e # TLDR: exit on failed command

upload_build()
{
  echo "Will look for file to upload using path '$filePath' and filter '$fileFilter'"

  # find the package file to upload, make sure there's only 1 file
  searchFor="$filePath/*$fileFilter*.ipa"
  numFiles=$(ls $searchFor | wc -l)
  if [ $numFiles != 1 ]; then
    echo "Too many or not enough files found for upload. Please check your filePath and fileFilter string"
    return
  fi

  ipa=$(ls $searchFor)
  echo "Will upload file: $ipa"

  #validate and upload package
  echo "Validating $ipa"
  xcrun altool --validate-app --type ios --file="$ipa" --username="$username" --password="$password"
  echo "Uploading $ipa"
  xcrun altool --upload-app --type ios --file="$ipa" --username="$username" --password="$password"
}

# Must have 4 input parameters
if [ $# -lt 4 ];
then
  echo ""
  echo "Please include parameters. Usage:"
  echo "  upload-build.sh [filePath] [fileFilter] [username] [password]"
  echo "Ex. upload-build.sh /pathToArtifactsFolder Distribution AppStoreConnectUsername AppStoreConnectPassword"
  echo ""
else
  filePath=$1
  fileFilter=$2
  username=$3
  password=$4

  upload_build
fi
