#!/bin/bash
# This script runs functional (non-UI) unit tests.
#
# Usage:
#   ./run_tests.sh              # Run tests only
#   ./run_tests.sh --report     # Run tests and generate markdown report
#   ./run_tests.sh <reportPath> # Run tests and generate HTML report (legacy)

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

# Generate categorized test report from JSON output
generate_report() {
  local json_file="$1"
  cat "$json_file" | jq -rs '
  # Build suite path lookup
  (map(select(.type == "suite")) | map({(.suite.id | tostring): .suite.path}) | add) as $suites |

  # Get test results with suite path
  [.[] | select(.type == "testDone" and .hidden == false) | {
    testID: .testID,
    result: .result,
    skipped: .skipped
  }] as $results |

  # Get test to suite mapping
  [.[] | select(.type == "testStart" and .test.line != null) | {
    testID: (.test.id | tostring),
    suiteID: (.test.suiteID | tostring)
  }] | map({(.testID): .suiteID}) | add as $testSuites |

  # Count by category
  [$results[] | {
    path: ($suites[$testSuites[.testID | tostring]] // "unknown"),
    result: .result,
    skipped: .skipped
  }] |

  # Extract category from path
  map(.category = (
    .path |
    gsub(".*/test/"; "") |
    gsub("_test\\.dart$"; "") |
    split("/")[0:2] | join("/")
  )) |

  # Group and count
  group_by(.category) |
  map({
    category: .[0].category,
    pass: [.[] | select(.result == "success")] | length,
    fail: [.[] | select(.result == "failure" or .result == "error")] | length,
    skip: [.[] | select(.skipped == true)] | length,
    total: length
  }) |
  sort_by(-.total) |

  # Format as markdown
  "## Test Report\n\n| Category | Pass | Fail | Skip | Total |\n|----------|------|------|------|-------|\n" +
  (map("| \(.category) | \(.pass) | \(.fail) | \(.skip) | \(.total) |") | join("\n")) +
  "\n|----------|------|------|------|-------|\n" +
  "| **TOTAL** | **\(map(.pass) | add)** | **\(map(.fail) | add)** | **\(map(.skip) | add)** | **\(map(.total) | add)** |"
  '
}

reportPath=$1

if [ "$reportPath" == "--report" ]; then
  # Generate markdown report
  echo "*********************Running Tests********************"
  JSON_FILE="/tmp/test_results_$$.json"
  $FLUTTER test --file-reporter json:$JSON_FILE --exclude-tags="golden||loc||ui"
  TEST_EXIT=$?

  echo ""
  echo "*********************Test Report**********************"
  generate_report "$JSON_FILE"
  echo ""

  rm -f "$JSON_FILE"
  exit $TEST_EXIT
elif [ -z "$reportPath" ]; then
  # When no report path is given, just run the tests and exit with the status of the test command.
  $FLUTTER test --exclude-tags="golden||loc||ui"
else
  # When a report path is given, run tests and generate a report (legacy HTML mode).
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