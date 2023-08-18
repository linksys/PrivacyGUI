
function build() {
  conf=$1
  type=$2
  env=$3
  hasPicker=true
  if [ "type" = "appbundle" ]; then
    hasPicker=false
  fi
  echo start building "$conf" "$type" "$env" process...
  if ! flutter build "$type" --"$conf" --obfuscate --split-debug-info=./build/app/outputs/temp/ --build-number="${AppBuildNumber}" --dart-define=cloud_env="${env}" --dart-define=enable_env_picker="${hasPicker}" --no-tree-shake-icons; then
      echo build "$conf" failed
      exit 1
  fi
  ext="apk"
  if [ "$type" = "appbundle" ]; then
    ext="aab"
  fi
  copyFiles "$ext" "$conf" "$env"
  echo finish build "$conf" "$type" "$env".
}

function copyFiles() {
  targetFlutterApkPath=./artifacts
  mkdir -p "$targetFlutterApkPath"

  type=$1
  conf=$2
  env=$3
  if [ "$env" = "prod" ]; then
    env=""
  else
    env="-$env"
  fi
  path=apk
  if [ "$type" = "aab" ]; then
    echo "process app bundle..."
    path="bundle"
    confFilePath=$(ls ./build/app/outputs/"$path"/"$conf"/*."$type")
    confFilename=$(basename "$confFilePath" ."$type")
    cp "$confFilePath" "$targetFlutterApkPath"/"$confFilename-$BranchName$env-$AppBuildNumber"."$type"
  else
    echo "process apk..."
    confFilePath=$(ls ./build/app/outputs/"$path"/"$conf"/*."$type")
    confFilename=$(basename "$confFilePath" ."$type")
    cp "$confFilePath" "$targetFlutterApkPath"/"$confFilename-$BranchName$env-$AppBuildNumber"."$type"
  fi
}
BranchName=$1
AppBuildNumber=$2

flutter --version
flutter pub get
flutter pub deps
flutter clean
flutter pub cache repairbuild debug apk
build debug apk qa
build release apk qa
build debug apk prod
build release apk prod
build release appbundle prod
