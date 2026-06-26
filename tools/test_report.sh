#!/bin/bash
# Generate categorized test report from Flutter test JSON output
# Usage: ./tools/test_report.sh [json_file]
#
# If no json_file is provided, runs tests and generates report.
# Output: Markdown table grouped by test category.

set -e

# Detect fvm
if command -v fvm > /dev/null 2>&1 && [ -f ".fvmrc" ]; then
  FLUTTER="fvm flutter"
else
  FLUTTER="flutter"
fi

JSON_FILE="${1:-/tmp/test_results.json}"

# Run tests if no JSON file provided
if [ -z "$1" ]; then
  echo "Running tests..."
  $FLUTTER test --file-reporter json:$JSON_FILE --exclude-tags="golden||loc||ui" 2>/dev/null || true
fi

if [ ! -f "$JSON_FILE" ]; then
  echo "Error: JSON file not found: $JSON_FILE"
  exit 1
fi

# Parse JSON and generate report using jq
cat "$JSON_FILE" | jq -rs '
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

# Extract category from path (test/X/Y -> X/Y or test/page/X -> page/X)
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

echo ""
echo "Report generated from: $JSON_FILE"
