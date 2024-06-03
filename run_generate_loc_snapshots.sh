while getopts l:s:f:c: flag
do
    case "${flag}" in
        l) locales=${OPTARG};;
        s) screens=${OPTARG};;
        f) file=${OPTARG};;
        c) copy=true;;
    esac
done
if [ -z "$locales" ]; then
  locales="all"
fi
if [ -z "$screens" ]; then
  screens="all"
fi
echo "*********************Generating Localization snapshots********************"
echo "Locales: $locales"
echo "Screens: $screens"

if [ -z "$file" ]; then
  echo "Target file: $file"
  flutter test --tags=loc --update-goldens --dart-define=locales="$locales" --dart-define=screens="$screens" 
else
  flutter test $file --tags=loc --update-goldens --dart-define=locales="$locales" --dart-define=screens="$screens" 
fi
echo 'Generating Localization snapshots Finished!******************************************'

echo all screenshots to "snapshots" folder
mkdir ./snapshots/
for dir in $(find ./ -iname 'goldens' -type d); do
  echo $dir
  if [ "$copy" = true ]; then
    find "$dir" -type f -exec cp {} ./snapshots/ \;
  else
    find "$dir" -type f -exec mv {} ./snapshots/ \;
  fi
done
dart run test_scripts/grep_loc_fils.dart