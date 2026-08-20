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
  -m, --min-screen PX   Raise the floor of the enumerated screen-width range to PX (e.g. 400),
                        so each span's narrowest width is the narrowest at or above PX.
                        Default: 0 = no filter; the 320px supported floor still applies.
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

die() {
  echo "Error: $1"
  echo "Use -h or --help for usage details."
  exit 1
}

# Option values are validated here rather than left to the Dart side, because a
# missing value silently swallows the *next* flag as its argument: `-c -o` would
# run with card id "-o" and no auto-open, and a `--dart-define` is happy to carry
# any string, so the run just quietly tests nothing.
require_value() {
  # A leading dash means the next flag landed here, i.e. this option's own value
  # was omitted. No card id or locale tag legitimately starts with one.
  if [ -z "$2" ] || [[ "$2" == -* ]]; then
    die "$1 requires a value."
  fi
}

require_number() {
  if ! [[ "$2" =~ ^[0-9]+$ ]]; then
    die "$1 expects a non-negative integer, got '$2'."
  fi
}

# Parse CLI flags
while [[ $# -gt 0 ]]; do
  case $1 in
    -l|--list)
      LIST_ONLY=true
      shift
      ;;
    -d|--dump)
      require_number "$1" "$2"
      # Out-of-range modes are rejected rather than clamped: `-d 4` most likely
      # means a mode the caller believes exists, and a silent fallback to the
      # default would hand them a report they did not ask for.
      case "$2" in
        0|1|2|3) ;;
        *) die "$1 must be 0, 1, 2, or 3, got '$2'." ;;
      esac
      DUMP_MODE="$2"
      shift 2
      ;;
    -m|--min-screen)
      require_number "$1" "$2"
      MIN_SCREEN="$2"
      shift 2
      ;;
    -c|--card)
      require_value "$1" "$2"
      CARD_ID="$2"
      shift 2
      ;;
    -L|--locale)
      require_value "$1" "$2"
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
  fvm flutter test "$TARGET_TEST" --dart-define=LIST_CARDS=true
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

# Build test execution command as an array, not a string: -c and -L carry
# arbitrary user text, and a string command would have to be re-expanded with
# `eval` to run — a second round of word splitting and glob expansion over that
# text. As an array each element stays one argument no matter what is in it.
CMD=(fvm flutter test "$TARGET_TEST")
if [ -n "$CARD_ID" ]; then
  CMD+=(--name "$CARD_ID")
fi
CMD+=(--dart-define=DUMP="$DUMP_MODE" --dart-define=MIN_SCREEN="$MIN_SCREEN")
if [ -n "$LOCALE_FILTER" ]; then
  CMD+=(--dart-define=LOCALE="$LOCALE_FILTER")
fi

# `${CMD[*]}` here is display only — the run below uses `"${CMD[@]}"`.
echo "▶ Executing: ${CMD[*]}"
echo ""

# Run tests (allow non-zero exit code so reports are still surfaced if tests fail)
set +e
"${CMD[@]}"
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
