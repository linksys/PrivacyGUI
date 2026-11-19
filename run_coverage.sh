#!/usr/bin/env bash
# The unit tests with coverage, measured the way #1803 describes (#1803 Q1).
#
# usage: ./run_coverage.sh <reportDir>
#
# It runs run_tests.sh with --coverage, so the same tests run, without
# `golden` and `loc` (constitution 3.1). First it writes the import-all
# helper, so that every lib file counts, and on the way out it deletes it,
# Ctrl-C included. It writes:
# - <reportDir>/tests.json, as run_tests.sh does;
# - coverage/lcov.info, where `flutter test --coverage` puts it;
# - <reportDir>/coverage.md, the table #1803 reports, with a line on the
#   floor under it, which it also prints.
#
# `1.x / Unit Tests` runs this script, so the figure a PR shows is the one it
# gives locally. It fails when a test fails, when the table cannot be made, or
# when the total is below the floor in coverage_floor.txt (#1803 Q5).
reportPath=$1
if [ -z "$reportPath" ]; then
  echo 'usage: ./run_coverage.sh <reportDir>'
  exit 2
fi
helper=test/import_all_for_coverage_test.dart
mkdir -p "$reportPath"
rm -f coverage/lcov.info "$reportPath/coverage.md"
trap 'rm -f "$helper"' EXIT
dart test_scripts/coverage_import_all.dart || exit 1
bash run_tests.sh "$reportPath" --coverage
status=$?
if [ -f coverage/lcov.info ]; then
  if dart test_scripts/coverage_summary.dart coverage/lcov.info "$reportPath/tests.json" >"$reportPath/coverage.md"; then
    # A blank line first, so the floor's line is a paragraph of its own.
    if ! { echo; dart test_scripts/coverage_floor.dart coverage/lcov.info; } >>"$reportPath/coverage.md"; then
      status=1
    fi
    cat "$reportPath/coverage.md"
  else
    rm -f "$reportPath/coverage.md"
    echo 'Could not summarise coverage/lcov.info.'
    status=1
  fi
else
  echo 'No coverage/lcov.info was written.'
  status=1
fi
exit $status
