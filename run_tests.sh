reportPath=$1
echo "*********************Running Tests********************"
# EXTRA_EXCLUDE_TAGS adds tags to leave out, such as CI's `layout-gate`, which
# runs in jobs of its own (#1802 P3). It joins the one --exclude-tags: a second
# --exclude-tags would replace the first, and golden and loc would run again.
flutter test --file-reporter json:$reportPath/tests.json --exclude-tags="golden||loc${EXTRA_EXCLUDE_TAGS:+||$EXTRA_EXCLUDE_TAGS}"
if ! dart test_scripts/test_result_parser.dart $reportPath/tests.json $reportPath/app-test-reports.html; then
  echo 'Test failed!******************************************'
  exit 1
else
  echo 'Test passed!******************************************'
fi