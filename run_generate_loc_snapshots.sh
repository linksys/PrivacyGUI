while getopts l:s:f:c:o: flag
do
    case "${flag}" in
        l) locales=${OPTARG};;
        s) screens=${OPTARG};;
        f) file=${OPTARG};;
        c) copy=true;;
        o) overlay=true;;
    esac
done
if [ -z "$locales" ]; then
  locales="en"
fi
if [ -z "$screens" ]; then
  screens="480,1280"
fi
if [ -z "$overlay" ]; then
  overlay="false"
fi
echo "*********************Generating Localization snapshots********************"
echo "Locales: $locales"
echo "Screens: $screens"
echo "Show overlay: $overlay"

mkdir ./snapshots/
if [ -z "$file" ]; then
  locStr=${locales//,/_}
  screenStr=${screens//,/_}
  flutter test --file-reporter json:snapshots/tests.json --tags=loc --update-goldens --dart-define=locales="$locales" --dart-define=screens="$screens" --dart-define=overlay="$overlay"
  dart test_scripts/test_result_parser.dart snapshots/tests.json "snapshots/localizations-test-reports-$locStr-$screenStr.html"
  rm snapshots/tests.json
else
  echo "Target file: $file"
  flutter test $file --tags=loc --update-goldens --dart-define=locales="$locales" --dart-define=screens="$screens" --dart-define=overlay="$overlay"
fi
echo 'Generating Localization snapshots Finished!******************************************'

echo all screenshots to "snapshots" folder
for dir in $(find ./ -iname 'goldens' -type d); do
  echo $dir
  if [ "$copy" = true ]; then
    find "$dir" -type f -exec cp {} ./snapshots/ \;
  else
    find "$dir" -type f -exec mv {} ./snapshots/ \;
  fi
done
dart run test_scripts/grep_loc_fils.dart
