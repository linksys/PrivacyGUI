
function build() {
  targetFlutterApkPath=./build/app/outputs/flutter-apk
  conf=$1
  echo start building "$conf" process...
  flutter build apk --"$conf"
  confFilePath=$(ls ./build/app/outputs/apk/"$conf"/*.apk)
  confFilename=$(basename "$confFilePath" .apk)
  # rename APK file
  targetConfFilePath=$(ls "$targetFlutterApkPath"/*-"$conf".apk)
  mv "$targetConfFilePath" "$targetFlutterApkPath"/"$confFilename".apk
}

build debug
build release