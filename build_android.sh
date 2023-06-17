
function build() {
  conf=$1
  type=$2
  echo start building "$conf" "$type" process...
  if ! flutter build "$type" --"$conf" --obfuscate --split-debug-info=moab/build/app/outputs/temp/ --build-number="${AppBuildNumber}" --dart-define=cloud_env=qa --no-tree-shake-icons; then
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
  targetFlutterApkPath=./artifacts
  mkdir -p "$targetFlutterApkPath"

  type=$1
  conf=$2
  path=apk
  if [ "$type" = "aab" ]; then
    echo "process app bundle..."
    path="bundle"
    confFilePath=$(ls ./build/app/outputs/"$path"/"$conf"/*."$type")
    confFilename=$(basename "$confFilePath" ."$type")
    cp "$confFilePath" "$targetFlutterApkPath"/"$confFilename-$BranchName-$AppBuildNumber"."$type"
  else
    echo "process apk..."
    confFilePath=$(ls ./build/app/outputs/"$path"/"$conf"/*."$type")
    confFilename=$(basename "$confFilePath" ."$type")
    cp "$confFilePath" "$targetFlutterApkPath"/"$confFilename-$BranchName-$AppBuildNumber"."$type"
  fi
}
BranchName=$1
AppBuildNumber=$2
flutter --version
flutter pub get
flutter pub deps
flutter clean
flutter pub cache repairbuild debug apk
build release apk
build debug apk
build release appbundle
