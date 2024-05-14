while getopts l:s: flag
do
    case "${flag}" in
        l) locales=${OPTARG};;
        s) screens=${OPTARG};;
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

flutter test --tags=loc --update-goldens --dart-define=locales="$locales" --dart-define=screens="$screens" 
echo 'Generating Localization snapshots Finished!******************************************'

echo all screenshots to "screenshots" folder
mkdir ./snapshots/
for dir in $(find ./ -iname 'goldens' -type d); do
  echo $dir
  find "$dir" -type f -exec cp {} ./snapshots/ \;
done