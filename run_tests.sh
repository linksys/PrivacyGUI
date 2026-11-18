reportPath=$1
# run_coverage.sh passes --coverage as the second argument. Nothing else is
# passed on, so no argument can override the excluded tags (constitution 3.1).
coverage=
if [ "$2" = "--coverage" ]; then coverage=--coverage; fi
echo "*********************Running Tests********************"
flutter test --file-reporter json:$reportPath/tests.json --exclude-tags="golden||loc" $coverage
if ! dart test_scripts/test_result_parser.dart $reportPath/tests.json $reportPath/app-test-reports.html; then
  echo 'Test failed!******************************************'
  exit 1
else
  echo 'Test passed!******************************************'
fi