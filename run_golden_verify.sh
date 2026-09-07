#!/bin/bash

# Detect fvm: use fvm flutter if available, otherwise use flutter directly
if command -v fvm > /dev/null 2>&1 && [ -f ".fvmrc" ]; then
  FLUTTER="fvm flutter"
  DART="fvm dart"
else
  FLUTTER="flutter"
  DART="dart"
fi

while getopts l:s:f:v: flag
do
    case "${flag}" in
        l) locales=${OPTARG};;
        s) screens=${OPTARG};;
        f) file=${OPTARG};;
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

REPORT_DIR="test/golden_test"
FAILED=0

echo "*********************Golden Test Verification********************"
echo "Locales: $locales"
echo "Screens: $screens"
echo "Version: $version"

# The golden runner appends to this file, so a previous run's records would be
# attributed to this one — reporting overflows at line numbers that have since
# moved, or on goldens this run never touched. Cleared before, not after, so the
# file is still readable for debugging once the run ends. Placed ahead of the
# branch below because both paths generate a report.
rm -f goldens/overflow_warnings.json
# Same reasoning for the diff record (#1475), and more so: it is append-only, so
# every locale in the loop below adds to it on purpose — a run's floor is measured
# over every cell it swept — and that only holds if the previous run's cells are
# gone first.
rm -f goldens/golden_diff_percent.jsonl

if [ -z "$file" ]; then
  IFS=',' read -ra LOCS <<< "$locales"
  for locale in "${LOCS[@]}"; do
    echo "Verifying golden tests for locale: $locale, screens: $screens"
    $FLUTTER test test/golden_test/ --file-reporter json:$REPORT_DIR/tests.json \
      --dart-define=locales="$locale" \
      --dart-define=screens="$screens" \
      --dart-define=visualEffects=0 || FAILED=1
    $DART run test_scripts/test_result_parser.dart $REPORT_DIR/tests.json "$locale" || FAILED=1
    rm -f $REPORT_DIR/tests.json
  done

  $DART run test_scripts/combine_results.dart $REPORT_DIR "$version" || FAILED=1
  echo ""
  echo "Report generated: $REPORT_DIR/golden_verify_report.html"
else
  echo "Target file: $file"
  $FLUTTER test "$file" --file-reporter json:$REPORT_DIR/tests.json \
    --dart-define=locales="$locales" \
    --dart-define=screens="$screens" \
    --dart-define=visualEffects=0 || FAILED=1
  $DART run test_scripts/test_result_parser.dart $REPORT_DIR/tests.json "$locales" || FAILED=1
  rm -f $REPORT_DIR/tests.json
  $DART run test_scripts/combine_results.dart $REPORT_DIR "$version" || FAILED=1
  echo ""
  echo "Report generated: $REPORT_DIR/golden_verify_report.html"
fi

# How far every golden moved from its baseline, including the cells that passed
# (#1475). Printed for both branches above, and deliberately not allowed to
# change the exit code: the thresholds are what decide pass or fail, and a
# diagnostic that can fail a run is a second, undocumented gate.
echo ""
$DART run test_scripts/golden_diff_summary.dart || true

echo "Golden Test Verification Finished!******************************************"
exit $FAILED
