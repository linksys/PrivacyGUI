#!/usr/bin/env bash
# ==============================================================================
# Dashboard Layout Overflow Test Runner
# ==============================================================================
# Runs the dashboard card RenderFlex overflow test suite with customizable
# dump modes, screen width filtering, card targeting, and automatic report cleanup.
# ==============================================================================

set -e

# Default settings
DUMP_MODE=2
MIN_SCREEN=0
CARD_ID=""
LOCALE_FILTER=""
AUTO_OPEN=false
LIST_ONLY=false
TARGET_TEST="test/page/dashboard/cards/dashboard_card_overflow_test.dart"
OUTPUT_DIR="build/overflow_testing"

show_help() {
  cat << EOF
Dashboard Layout Overflow Test Runner

Usage:
  ./tool/run_overflow_test.sh [options]

Options:
  -l, --list            List all registered Dashboard Card IDs dynamically from UspWidgetSpecs.all.
  -d, --dump MODE       Dump mode for reports & PNG screenshots:
                          0 = No output (clean PR gate mode)
                          1 = Markdown bulleted list (build/overflow_testing/overflow_report.md)
                          2 = HTML visual report + PNG screenshots (default)
                          3 = Markdown + HTML + PNG screenshots
  -m, --min-screen PX   Filter test cases to screen widths >= PX (e.g. 400). Default: 0 (scan all).
  -c, --card CARD_ID    Target a specific card spec ID (e.g. stats_panel, network_health).
  -L, --locale LOCALE   Target specific locale(s) (e.g. ru or ru,zh_TW). Default: all 26 locales.
  -o, --open            Automatically open HTML report in default browser after test completes.
  -h, --help            Show this help message.

Examples:
  # List all registered cards
  ./tool/run_overflow_test.sh -l

  # Default run: Dump HTML report & PNG screenshots for all cards
  ./tool/run_overflow_test.sh

  # Ultra-fast debug run: Test only device_info card on Russian locale
  ./tool/run_overflow_test.sh -c device_info -L ru -o

  # Quick Markdown summary mode
  ./tool/run_overflow_test.sh -d 1
EOF
  exit 0
}

# Parse CLI flags
while [[ $# -gt 0 ]]; do
  case $1 in
    -l|--list)
      LIST_ONLY=true
      shift
      ;;
    -d|--dump)
      DUMP_MODE="$2"
      shift 2
      ;;
    -m|--min-screen)
      MIN_SCREEN="$2"
      shift 2
      ;;
    -c|--card)
      CARD_ID="$2"
      shift 2
      ;;
    -L|--locale)
      LOCALE_FILTER="$2"
      shift 2
      ;;
    -o|--open)
      AUTO_OPEN=true
      shift
      ;;
    -h|--help)
      show_help
      ;;
    *)
      echo "Error: Unknown argument '$1'"
      echo "Use -h or --help for usage details."
      exit 1
      ;;
  esac
done

if [ "$LIST_ONLY" = true ]; then
  fvm flutter test $TARGET_TEST --dart-define=LIST_CARDS=true
  exit 0
fi

echo "======================================================="
echo " 🚀 Dashboard Card Overflow Test Runner"
echo "======================================================="
echo "  Dump Mode:   $DUMP_MODE"
echo "  Min Screen:  ${MIN_SCREEN}px"
if [ -n "$CARD_ID" ]; then
  echo "  Target Card: $CARD_ID"
fi
if [ -n "$LOCALE_FILTER" ]; then
  echo "  Target Locale: $LOCALE_FILTER"
fi
echo "======================================================="

# Clean previous test outputs
if [ -d "$OUTPUT_DIR" ]; then
  echo "🧹 Cleaning previous output directory: $OUTPUT_DIR"
  rm -rf "$OUTPUT_DIR"
fi

# Build test execution command
CMD="fvm flutter test $TARGET_TEST"
if [ -n "$CARD_ID" ]; then
  CMD="$CMD --name \"$CARD_ID\""
fi
CMD="$CMD --dart-define=DUMP=$DUMP_MODE --dart-define=MIN_SCREEN=$MIN_SCREEN"
if [ -n "$LOCALE_FILTER" ]; then
  CMD="$CMD --dart-define=LOCALE=$LOCALE_FILTER"
fi

echo "▶ Executing: $CMD"
echo ""

# Run tests (allow non-zero exit code so reports are still surfaced if tests fail)
set +e
eval $CMD
TEST_EXIT_CODE=$?
set -e

echo ""
echo "======================================================="
echo " 📊 Execution Finished (Exit Code: $TEST_EXIT_CODE)"
echo "======================================================="

# Display generated report locations
if [ -f "$OUTPUT_DIR/overflow_report.md" ]; then
  echo "  📝 Markdown Report: $OUTPUT_DIR/overflow_report.md"
fi
if [ -f "$OUTPUT_DIR/overflow_report.html" ]; then
  echo "  🌐 HTML Visual Report: $OUTPUT_DIR/overflow_report.html"
fi
if [ -d "$OUTPUT_DIR/png" ]; then
  PNG_COUNT=$(find "$OUTPUT_DIR/png" -type f -name "*.png" | wc -l | tr -d ' ')
  echo "  🖼️ Saved PNG Screenshots: $PNG_COUNT files in $OUTPUT_DIR/png/"
fi

# Auto-open HTML report if requested
if [ "$AUTO_OPEN" = true ] && [ -f "$OUTPUT_DIR/overflow_report.html" ]; then
  echo "🌐 Opening HTML report in browser..."
  if command -v open &> /dev/null; then
    open "$OUTPUT_DIR/overflow_report.html"
  elif command -v xdg-open &> /dev/null; then
    xdg-open "$OUTPUT_DIR/overflow_report.html"
  fi
fi

exit $TEST_EXIT_CODE
