reportPath=$1
echo "*********************Running Tests********************"
flutter test --file-reporter json:$reportPath/tests.json
if ! dart test_scripts/test_result_parser.dart; then
  echo 'Test failed!******************************************'
  exit 1
else
  echo 'Test passed!******************************************'
fi