#!/bin/bash
# This script runs functional (non-UI) unit tests.

# Detect fvm: use fvm flutter if available, otherwise use flutter directly
if command -v fvm > /dev/null 2>&1 && [ -f ".fvmrc" ]; then
  FLUTTER="fvm flutter"
  DART="fvm dart"
  echo "Using fvm flutter"
else
  FLUTTER="flutter"
  DART="dart"
  echo "Using system flutter"
fi

reportPath=$1

if [ -z "$reportPath" ]; then
  # When no report path is given, just run the tests and exit with the status of the test command.
  $FLUTTER test --exclude-tags="golden||loc||ui"
else
  # When a report path is given, run tests and generate a report.
  echo "*********************Running Tests********************"
  $FLUTTER test --file-reporter json:$reportPath/tests.json --exclude-tags="golden||loc||ui"

  if ! $DART test_scripts/test_result_parser.dart $reportPath/tests.json $reportPath/app-test-reports.html; then
    echo 'Test failed!******************************************'
    exit 1
  else
    echo 'Test passed!******************************************'
    exit 0
  fi
fi