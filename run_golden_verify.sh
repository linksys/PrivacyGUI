#!/bin/bash
set -e

EMBED_FLAG=""

while getopts l:s:f:v:-: flag
do
    case "${flag}" in
        l) locales=${OPTARG};;
        s) screens=${OPTARG};;
        f) file=${OPTARG};;
        v) version=${OPTARG};;
        -)
            case "${OPTARG}" in
                embed) EMBED_FLAG="--embed";;
            esac
            ;;
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

echo "*********************Golden Test Verification********************"
echo "Locales: $locales"
echo "Screens: $screens"
echo "Version: $version"
echo "Embed images: ${EMBED_FLAG:-no}"

mkdir -p ./snapshots/

if [ -z "$file" ]; then
  IFS=',' read -ra LOCS <<< "$locales"
  for locale in "${LOCS[@]}"; do
    echo "Verifying golden tests for locale: $locale, screens: $screens"
    flutter test --file-reporter json:snapshots/tests.json --tags=loc \
      --dart-define=locales="$locale" \
      --dart-define=screens="$screens" \
      --dart-define=visualEffects=0 || true
    dart test_scripts/test_result_parser.dart snapshots/tests.json "$locale"
    rm -f snapshots/tests.json
  done

  dart test_scripts/combine_results.dart snapshots "$version" $EMBED_FLAG
  echo ""
  echo "Report generated: snapshots/golden_verify_report.html"
else
  echo "Target file: $file"
  flutter test "$file" --file-reporter json:snapshots/tests.json --tags=loc \
    --dart-define=locales="$locales" \
    --dart-define=screens="$screens" \
    --dart-define=visualEffects=0 || true
  dart test_scripts/test_result_parser.dart snapshots/tests.json "$locales"
  rm -f snapshots/tests.json
  dart test_scripts/combine_results.dart snapshots "$version" $EMBED_FLAG
  echo ""
  echo "Report generated: snapshots/golden_verify_report.html"
fi

echo "Golden Test Verification Finished!******************************************"
