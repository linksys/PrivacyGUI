reportPath=$1
echo "*********************Running Tests********************"
flutter test --file-reporter json:$reportPath/tests.json --exclude-tags=golden
if ! dart test_scripts/test_result_parser.dart $reportPath/tests.json $reportPath/app-test-reports.html; then
  echo 'Test failed!******************************************'
  exit 1
else
  echo 'Test passed!******************************************'
fi