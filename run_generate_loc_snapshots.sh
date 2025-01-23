while getopts l:s:f:c:o: flag
do
    case "${flag}" in
        l) locales=${OPTARG};;
        s) screens=${OPTARG};;
        f) file=${OPTARG};;
        c) copy=true;;
        v) version=${OPTARG};;
    esac
done
if [ -z "$locales" ]; then
  locales="en"
fi
if [ -z "$screens" ]; then
  screens="480,1280"
fi
if [ -z "$version" ]; then
  version="0.0.1.1"
fi
echo "*********************Generating Localization snapshots********************"
echo "Locales: $locales"
echo "Screens: $screens"
echo "Version: $version"

mkdir ./snapshots/
if [ -z "$file" ]; then
  locStr=${locales//,/_}
  screenStr=${screens//,/_}
  IFS=',' read -ra LOCS <<< "$locales"
  # IFS=',' read -ra SCREENS <<< "$screens"
  g=1
  # for screen in "${SCREENS[@]}"; do
    for((i=0; i < ${#LOCS[@]}; i+=g))
    do
      part=( "${LOCS[@]:i:g}" )
      locale=$(IFS=, ; echo "${part[*]}")
      echo "Start run screenshot testing with screen: $screens, locales: $locale"
      flutter test --file-reporter json:snapshots/tests.json --tags=loc --update-goldens --dart-define=locales="$locale" --dart-define=screens="$screens"
      dart test_scripts/test_result_parser.dart snapshots/tests.json "$locale" "$screenStr"
      rm snapshots/tests.json
    done
  # done
  
  dart test_scripts/combine_results.dart snapshots "$version"
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
