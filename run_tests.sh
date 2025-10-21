#!/bin/bash
# This script runs functional (non-UI) unit tests.

reportPath=$1

if [ -z "$reportPath" ]; then
  # When no report path is given, just run the tests and exit with the status of the test command.
  flutter test --exclude-tags="golden||loc||ui"
else
  # When a report path is given, run tests and generate a report.
  echo "*********************Running Tests********************"
  flutter test --file-reporter json:$reportPath/tests.json --exclude-tags="golden||loc||ui"
  
  if ! dart test_scripts/test_result_parser.dart $reportPath/tests.json $reportPath/app-test-reports.html; then
    echo 'Test failed!******************************************'
    exit 1
  else
    echo 'Test passed!******************************************'
    exit 0
  fi
fi