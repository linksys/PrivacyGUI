#!/bin/bash
set -e

# Detect fvm: use fvm flutter if available, otherwise use flutter directly
if command -v fvm > /dev/null 2>&1 && [ -f ".fvmrc" ]; then
  FLUTTER="fvm flutter"
  DART="fvm dart"
else
  FLUTTER="flutter"
  DART="dart"
fi

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

REPORT_DIR="test/golden_test"

echo "*********************Golden Test Verification********************"
echo "Locales: $locales"
echo "Screens: $screens"
echo "Version: $version"
echo "Embed images: ${EMBED_FLAG:-no}"

if [ -z "$file" ]; then
  IFS=',' read -ra LOCS <<< "$locales"
  for locale in "${LOCS[@]}"; do
    echo "Verifying golden tests for locale: $locale, screens: $screens"
    $FLUTTER test test/golden_test/ --file-reporter json:$REPORT_DIR/tests.json \
      --dart-define=locales="$locale" \
      --dart-define=screens="$screens" \
      --dart-define=visualEffects=0 || true
    $DART run test_scripts/test_result_parser.dart $REPORT_DIR/tests.json "$locale" || true
    rm -f $REPORT_DIR/tests.json
  done

  $DART run test_scripts/combine_results.dart $REPORT_DIR "$version" $EMBED_FLAG
  echo ""
  echo "Report generated: $REPORT_DIR/golden_verify_report.html"
else
  echo "Target file: $file"
  $FLUTTER test "$file" --file-reporter json:$REPORT_DIR/tests.json \
    --dart-define=locales="$locales" \
    --dart-define=screens="$screens" \
    --dart-define=visualEffects=0 || true
  $DART run test_scripts/test_result_parser.dart $REPORT_DIR/tests.json "$locales" || true
  rm -f $REPORT_DIR/tests.json
  $DART run test_scripts/combine_results.dart $REPORT_DIR "$version" $EMBED_FLAG
  echo ""
  echo "Report generated: $REPORT_DIR/golden_verify_report.html"
fi

echo "Golden Test Verification Finished!******************************************"
