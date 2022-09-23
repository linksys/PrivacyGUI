
function build() {
  conf=$1
  type=$2
  echo start building "$conf" "$type" process...
  if ! flutter build "$type" --"$conf" --obfuscate --split-debug-info=moab/build/app/outputs/temp/ --dart-define=cloud_env=qa; then
      echo build "$conf" failed
      exit 1
  fi
  ext="apk"
  if [ "$type" = "appbundle" ]; then
    ext="aab"
  fi
  copyFiles "$ext" "$conf"
  echo finish build "$conf" "$type".
}

function copyFiles() {
  targetFlutterApkPath=./build/app/outputs/flutter-apk
  mkdir -p "$targetFlutterApkPath"

  type=$1
  conf=$2
  path=apk
  if [ "$type" = "aab" ]; then
    echo "process app bundle..."
    path="bundle"
    confFilePath=$(ls ./build/app/outputs/"$path"/"$conf"/*."$type")
    confFilename=$(basename "$confFilePath" ."$type")
    cp "$confFilePath" "$targetFlutterApkPath"/"$confFilename"."$type"
  else
    echo "process apk..."
    confFilePath=$(ls ./build/app/outputs/"$path"/"$conf"/*."$type")
    confFilename=$(basename "$confFilePath" ."$type")
    # rename file
    targetConfFilePath=$(ls "$targetFlutterApkPath"/*-"$conf"."$type")
    mv "$targetConfFilePath" "$targetFlutterApkPath"/"$confFilename"."$type"
  fi
}

echo cleaning...
flutter clean
build debug apk
build release apk
build release appbundle
