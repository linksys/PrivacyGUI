reportPath=$1
# run_coverage.sh passes --coverage as the second argument. Nothing else is
# passed on, so no argument can override the excluded tags (constitution 3.1).
coverage=
if [ "$2" = "--coverage" ]; then coverage=--coverage; fi
echo "*********************Running Tests********************"
# layout-gate is the layout gate (#1802 P3), which CI runs in jobs of its own;
# run it with `flutter test --tags layout-gate --exclude-tags="golden||loc"`.
# One --exclude-tags only: a second would replace the first.
flutter test --file-reporter json:$reportPath/tests.json --exclude-tags="golden||loc||layout-gate" $coverage
if ! dart test_scripts/test_result_parser.dart $reportPath/tests.json $reportPath/app-test-reports.html; then
  echo 'Test failed!******************************************'
  exit 1
else
  echo 'Test passed!******************************************'
fi