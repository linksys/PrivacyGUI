#!/usr/bin/env bash
# ==============================================================================
# Overflow Sweep Baselines (#1337)
# ==============================================================================
# Captures a byte-stable dataset of every coordinate the four overflow sweeps
# measure, and diffs a fresh run against the committed one.
#
# WHY
#   Epic #1335 ports all four sweeps onto one framework, and each port is signed
#   off by the same claim: the failure set is identical, cell by cell. The card
#   sweep alone measures ~1,900 cells, so that claim needs a diff, not a reader.
#
# HOW
#   Each sweep prints one `#LAYOUT-CELL#` record per measured coordinate when
#   OVERFLOW_BASELINE=1 (see test/util/overflow_baseline.dart). This script runs
#   the sweep with `--reporter json`, and test_scripts/overflow_baseline.dart turns
#   those records into sorted TSV under test/fixtures/overflow_baselines/.
#
#   All four sweeps pass today and the allowlist is empty, so what these baselines
#   freeze is coverage: 3,587 coordinates that are measured and clean. The test run
#   is nonetheless allowed to exit non-zero — a sweep can go red at any time, and
#   its records are still the right input for a diff. What must never be tolerated
#   is a *truncated* run, which the extractor rejects on its own.
#
# WHY NOT --file-reporter
#   Its file sink interleaves writes and leaves 16KB runs of NUL bytes mid-stream,
#   and the records inside a hole are simply gone. Redirecting `--reporter json`
#   keeps one writer on the stream. Do not "simplify" this back — the extractor's
#   NUL check documents what it cost.
# ==============================================================================

set -euo pipefail

SWEEPS=(card popup forced_form chrome)
BASELINE_DIR="test/fixtures/overflow_baselines"
RUN_DIR="build/overflow_baseline"
EXTRACTOR="test_scripts/overflow_baseline.dart"

FLUTTER="flutter"
DART="dart"
if command -v fvm &> /dev/null && [ -f ".fvmrc" ]; then
  FLUTTER="fvm flutter"
  DART="fvm dart"
fi

show_help() {
  cat << EOF
Overflow sweep baselines (#1337)

Usage:
  ./tool/overflow_baseline.sh capture [sweep...]   Re-capture and overwrite the committed baselines
  ./tool/overflow_baseline.sh check   [sweep...]   Compare a fresh run against the committed baselines
  ./tool/overflow_baseline.sh diff    [sweep...]   Alias for check

Sweeps: ${SWEEPS[*]} (default: all four)

Options:
  -h, --help    Show this message

Examples:
  # Before starting a port: freeze today's measured coverage
  ./tool/overflow_baseline.sh capture

  # After porting the chrome sweep: prove it measures the same cells identically
  ./tool/overflow_baseline.sh check chrome

Exit codes: 0 = every sweep matched, 1 = a sweep differs, 2 = bad input or an
unusable run.

A 'check' failure is not automatically a regression — read the diff. Cells
reported as "no longer measured" are the dangerous ones: a port that drops a
coordinate produces fewer failures, which reads like progress. Only re-capture
once the difference is understood and intended, and say so in the commit.
EOF
  exit 0
}

die() {
  echo "Error: $1" >&2
  echo "Use -h or --help for usage details." >&2
  exit 2
}

# The sweep registry. A `case` rather than an associative array because macOS
# still ships bash 3.2, where `declare -A` does not exist.
suite_for() {
  case "$1" in
    card)        echo "test/page/dashboard/cards/dashboard_card_overflow_test.dart" ;;
    popup)       echo "test/page/dashboard/cards/dashboard_card_popup_overflow_test.dart" ;;
    forced_form) echo "test/page/dashboard/cards/dashboard_card_forced_form_overflow_test.dart" ;;
    chrome)      echo "test/page/shell/page_chrome_overflow_test.dart" ;;
    *)           die "unknown sweep '$1'. Known: ${SWEEPS[*]}" ;;
  esac
}

MODE=""
if [ $# -eq 0 ]; then
  show_help
fi
case "$1" in
  -h|--help) show_help ;;
  capture)   MODE="capture"; shift ;;
  check)     MODE="check"; shift ;;
  diff)      MODE="check"; shift ;;
  *)         die "unknown command '$1'" ;;
esac

TARGETS=()
for arg in "$@"; do
  case "$arg" in
    -h|--help) show_help ;;
    -*)        die "unknown option '$arg'" ;;
    *)         suite_for "$arg" > /dev/null; TARGETS+=("$arg") ;;
  esac
done
if [ ${#TARGETS[@]} -eq 0 ]; then
  TARGETS=("${SWEEPS[@]}")
fi

# The commit stamped into each baseline's header.
#
# A `-dirty` suffix when the measured paths carry uncommitted work, and it is not
# cosmetic: `# commit <sha>` is the only thing telling a later reader which tree
# produced these rows, and a plain sha claims that checking out that sha and
# re-capturing reproduces them. It does not when the tree was dirty — the first
# capture of these four was itself taken with this ticket's own instrumentation
# still uncommitted, which is unavoidable for a mechanism that measures the code
# introducing it. Better to say so in the file than to imply otherwise.
#
# MEASURED_PATHS mirrors kBaselineMeasuredPaths in $EXTRACTOR, which stamps the
# same way for a direct `dart run … extract`; the extractor's test asserts the two
# lists match, so read the doc comment there before editing either. `pubspec.yaml`
# earns its place by pinning the ui_kit_library / generative_ui refs — most of the
# widgets these rows measure are not in this repo at all.
MEASURED_PATHS=(lib test pubspec.yaml)
COMMIT="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
if [ -n "$(git status --porcelain -- "${MEASURED_PATHS[@]}" 2>/dev/null)" ]; then
  COMMIT="$COMMIT-dirty"
  DIRTY=" — uncommitted work in ${MEASURED_PATHS[*]}, so a re-capture at that sha
          alone will not reproduce these rows"
else
  DIRTY=""
fi

mkdir -p "$RUN_DIR" "$BASELINE_DIR"

echo "======================================================="
echo " 📐 Overflow sweep baselines — $MODE"
echo "======================================================="
echo "  Commit: $COMMIT$DIRTY"
echo "  Sweeps: ${TARGETS[*]}"
echo "======================================================="

FAILED=()
for sweep in "${TARGETS[@]}"; do
  suite="$(suite_for "$sweep")"
  report="$RUN_DIR/$sweep.json"
  baseline="$BASELINE_DIR/$sweep.tsv"

  echo ""
  echo "▶ $sweep — $suite"

  # The sweeps read LOCALE / MIN_SCREEN / DUMP / LIST_CARDS from the environment
  # to narrow a debugging run. Any of them left set would change *which cells
  # exist*, and the dataset would then be a subset that passes every diff taken
  # against it. Cleared here rather than trusted, because an exported LOCALE from
  # an earlier debugging session is invisible at the call site.
  #
  # `--reporter json` to stdout rather than `--file-reporter json:<file>`: see
  # WHY NOT --file-reporter above. The redirect makes this run silent, so the
  # cell count the extractor prints afterwards is the only progress report.
  set +e
  env -u LOCALE -u locale -u MIN_SCREEN -u min_screen -u DUMP -u DUMP_MODE \
      -u dump -u dump_mode -u LIST_CARDS -u list_cards \
      OVERFLOW_BASELINE=1 \
      $FLUTTER test "$suite" --reporter json > "$report"
  test_exit=$?
  set -e
  if [ $test_exit -ne 0 ]; then
    # Not fatal on its own. A failing assertion still produced records, and those
    # records are what the diff needs; the extractor is what decides whether the
    # run is whole enough to trust.
    echo "  (the sweep exited $test_exit — reading its records anyway)"
  fi

  if [ "$MODE" = "capture" ]; then
    $DART run "$EXTRACTOR" extract \
      --reporter "$report" --sweep "$sweep" --commit "$COMMIT" --out "$baseline"
  else
    [ -f "$baseline" ] || die "no committed baseline at $baseline — run 'capture' first"
    set +e
    $DART run "$EXTRACTOR" diff --baseline "$baseline" --reporter "$report"
    diff_exit=$?
    set -e
    case $diff_exit in
      0) ;;
      1) FAILED+=("$sweep") ;;
      *) die "could not compare $sweep (exit $diff_exit)" ;;
    esac
  fi
done

echo ""
echo "======================================================="
if [ "$MODE" = "capture" ]; then
  echo " ✅ Captured at $COMMIT: ${TARGETS[*]}"
  echo "    Commit $BASELINE_DIR/ so every later run has something to diff against."
  exit 0
fi
if [ ${#FAILED[@]} -eq 0 ]; then
  echo " ✅ Every sweep matches its baseline: ${TARGETS[*]}"
  exit 0
fi
echo " ❌ Differs from the committed baseline: ${FAILED[*]}"
echo "    Read the diff above before re-capturing — 'no longer measured' means"
echo "    lost coverage, which a plain pass/fail run would have reported as green."
exit 1
