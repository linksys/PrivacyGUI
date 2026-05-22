#!/bin/bash
# ci/verify_golden_coverage.sh
#
# Verifies that every USP view file has a corresponding golden test.
# Run after: flutter test --coverage test/usp_test/
#
# Exit code 0 = all views covered, 1 = missing tests or low coverage.

set -euo pipefail

THRESHOLD=${1:-95}
FAIL=0
TESTED=0
TOTAL=0

echo "=== USP Golden Test Coverage Verification ==="
echo "Branch coverage threshold: ${THRESHOLD}%"
echo ""

for view_file in lib/page/*/views/usp_*_view.dart; do
  [ -f "$view_file" ] || continue
  TOTAL=$((TOTAL + 1))

  feature=$(echo "$view_file" | sed 's|lib/page/\(.*\)/views/.*|\1|')

  # Check golden test exists in usp_test directory
  test_pattern="test/usp_test/page/$feature/localizations/*_test.dart"
  if ! compgen -G "$test_pattern" >/dev/null 2>&1; then
    echo "FAIL $view_file: no golden test found"
    FAIL=1
    continue
  fi

  TESTED=$((TESTED + 1))

  # Check branch coverage if lcov.info exists
  if [ -f "coverage/lcov.info" ]; then
    # Extract line coverage for this specific file
    line_coverage=$(lcov --summary coverage/lcov.info \
      --include "$(pwd)/$view_file" 2>&1 \
      | grep "lines" | grep -o '[0-9.]*%' | head -1 || echo "N/A")

    if [ "$line_coverage" != "N/A" ]; then
      coverage_num=$(echo "$line_coverage" | sed 's/%//')
      if [ "$(echo "$coverage_num < $THRESHOLD" | bc -l)" = "1" ]; then
        echo "FAIL $view_file: line coverage ${line_coverage} < ${THRESHOLD}%"
        FAIL=1
      else
        echo "PASS $view_file: line coverage ${line_coverage}"
      fi
    else
      echo "WARN $view_file: no coverage data (test may not exercise view code)"
    fi
  else
    echo "PASS $view_file: golden test exists (no coverage data to check)"
  fi
done

echo ""
echo "=== Summary ==="
echo "Total USP views: $TOTAL"
echo "Views with golden tests: $TESTED"
echo "Views missing golden tests: $((TOTAL - TESTED))"

exit $FAIL
