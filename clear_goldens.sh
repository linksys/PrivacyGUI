#!/bin/bash

# Clear all golden test PNG files and intermediate artifacts.
# Run this before regenerating screenshots with run_generate_loc_snapshots.sh.

set -e

echo "(1/2) Deleting golden PNG files under test/golden_test/..."

count=$(find ./test/golden_test -path '*/goldens/*.png' | wc -l | tr -d ' ')
find ./test/golden_test -path '*/goldens/*.png' -delete
echo "Deleted $count golden images."

echo "---------------------------------"

echo "(2/2) Clearing intermediate artifacts..."

rm -f goldens/overflow_warnings.json
rm -f goldens/golden_diff_percent.jsonl
rm -f test/golden_test/golden_gallery_report.html

echo "Done. Ready for a clean regeneration."
