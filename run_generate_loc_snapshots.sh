#!/bin/bash
set -e

while getopts l:s:t:f:cv: flag
do
    case "${flag}" in
        l) locales=${OPTARG};;
        s) screens=${OPTARG};;
        t) themes=${OPTARG};;
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
if [ -z "$themes" ]; then
  themes="glass-light"
fi
if [ -z "$version" ]; then
  version="0.0.1.1"
fi
echo "*********************Generating Localization snapshots********************"
echo "Locales: $locales"
echo "Screens: $screens"
echo "Themes: $themes"
echo "Version: $version"

mkdir -p ./snapshots/
if [ -z "$file" ]; then
  locStr=${locales//,/_}
  screenStr=${screens//,/_}
  themeStr=${themes//,/_}
  IFS=',' read -ra LOCS <<< "$locales"
  IFS=',' read -ra THEMES <<< "$themes"
  g=1
  for((i=0; i < ${#LOCS[@]}; i+=g))
  do
    part=( "${LOCS[@]:i:g}" )
    locale=$(IFS=, ; echo "${part[*]}")
    for theme in "${THEMES[@]}"; do
      echo "Start run screenshot testing with screen: $screens, locales: $locale, theme: $theme"
      flutter test --file-reporter json:snapshots/tests.json --tags=loc --update-goldens --dart-define=locales="$locale" --dart-define=screens="$screens" --dart-define=themes="$theme" --dart-define=visualEffects=15
      dart test_scripts/test_result_parser.dart snapshots/tests.json "$locale" "$screenStr" "$theme"
      rm snapshots/tests.json
    done
  done

  dart test_scripts/combine_results.dart snapshots "$version"
else
  echo "Target file: $file"
  flutter test $file --tags=loc --update-goldens --dart-define=locales="$locales" --dart-define=screens="$screens" --dart-define=themes="$themes" --dart-define=visualEffects=15
  exit $? # Exit with the status of the last command (flutter test)
fi
echo 'Generating Localization snapshots Finished!******************************************'

echo all screenshots to "snapshots" folder
for dir in $(find ./ -iname 'goldens' -type d); do
  echo $dir
  if [ "$copy" = true ]; then
    # Copy with directory structure preserved for theme subdirectories
    find "$dir" -type f -exec cp --parents {} ./snapshots/ \; 2>/dev/null || \
    find "$dir" -type f -exec rsync -R {} ./snapshots/ \; 2>/dev/null || \
    find "$dir" -type f -exec cp {} ./snapshots/ \;
  else
    find "$dir" -type f -exec mv {} ./snapshots/ \;
  fi
done
dart run test_scripts/grep_loc_fils.dart
