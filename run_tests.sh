echo "*********************Running Tests********************"
flutter test --file-reporter json:reports/tests.json
if ! dart test_scripts/test_result_parser.dart; then
  echo 'Test failed!******************************************'
  exit(1)
else
  echo 'Test passed!******************************************'
fi