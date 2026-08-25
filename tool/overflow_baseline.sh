#!/usr/bin/env bash
# ==============================================================================
# Overflow Sweep Baselines (#1337)
# ==============================================================================
# Captures a byte-stable dataset of every coordinate the five overflow sweeps
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
#   All five sweeps pass today and the allowlist is empty, so what these baselines
#   freeze is coverage: 4,032 coordinates that are measured and clean — card 1,943,
#   popup 347, forced_form 78, chrome 1,248, re-checked at the `dev-2.7.0` merge on
#   2026-08-24, where +29 cells arrived from a production spec change (#1325's
#   `normalAbove` on `dhcp_reservations`) with no sweep edited, plus page 416 from
#   #1349's pilot the same day (the fifth sweep, and the first one registered here
#   after the framework existed: two lines, see `suite_for`). The test run
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

SWEEPS=(card popup forced_form chrome page)
BASELINE_DIR="test/fixtures/overflow_baselines"
RUN_DIR="build/overflow_baseline"
REPORT_DIR="$RUN_DIR/report"
SHOT_ROOT="$RUN_DIR/shots"
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
  ./tool/overflow_baseline.sh capture [sweep...]      Re-capture and overwrite the committed baselines
  ./tool/overflow_baseline.sh check   [sweep...]      Compare a fresh run against the committed baselines
  ./tool/overflow_baseline.sh diff    [sweep...]      Alias for check
  ./tool/overflow_baseline.sh render  [sweep...]      Render the committed baselines as MD + HTML
  ./tool/overflow_baseline.sh shoot   <sweep> <pat>   Photograph <pat>'s cells and report on that run

Sweeps: ${SWEEPS[*]} (default: all five, except 'shoot' which takes exactly one)

Options:
  -h, --help    Show this message

Examples:
  # Before starting a port: freeze today's measured coverage
  ./tool/overflow_baseline.sh capture

  # After porting the chrome sweep: prove it measures the same cells identically
  ./tool/overflow_baseline.sh check chrome

  # Read what a sweep covers, without running it (seconds, no flutter)
  ./tool/overflow_baseline.sh render page && open $REPORT_DIR/page.html

  # A sweep went red: photograph exactly the cells that failed
  ./tool/overflow_baseline.sh shoot page failed

  # Look at what a green cell actually renders as: every Arabic page cell
  ./tool/overflow_baseline.sh shoot page locale=ar

  # One coordinate, exactly as the report prints its id
  ./tool/overflow_baseline.sh shoot page 'page.dhcp|screen_px=601|locale=ru'

Exit codes: 0 = every sweep matched, 1 = a sweep differs, 2 = bad input or an
unusable run.

'render' runs no tests at all: it reads the committed .tsv files, so each report
describes the commit stamped in its own header and not this working tree. That is
said again at the top of every report, because it is the one way a report here
can mislead.

'shoot' is the opposite: it runs the sweep against the working tree, writes one PNG
per matching cell into $SHOT_ROOT/<sweep>/, and reports on that
same run — the records and the images come out of one execution, so the rows and
the pictures always describe one tree and an image can never be orphaned by rows
taken elsewhere. Nothing it writes goes near $BASELINE_DIR/,
and nothing about a shoot changes a verdict.

<pat> is required, because the only defensible default is 'all' and that is 1,943
images on the card sweep. It is one of:

  failed             the cells this run judged as failures — an overflow past the
                     2px tolerance, or a pump that threw. What you want when a
                     sweep goes red, and it writes nothing at all on a green one.
  all                every measured cell.
  <substring>        any cell id containing it: 'locale=ar', 'px=191',
                     'card=lan_info', or a whole id copied from a report.

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
    # One entry per *baseline id*, not per family: the extractor splits a record's
    # `page.dhcp` on the first dot, so both pilot pages land in one dataset the way
    # the card sweep's three families do (#1349).
    page)        echo "test/page/_shared/page_surface_overflow_test.dart" ;;
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
  render)    MODE="render"; shift ;;
  shoot)     MODE="shoot"; shift ;;
  *)         die "unknown command '$1'" ;;
esac

TARGETS=()
PATTERN=""
if [ "$MODE" = "shoot" ]; then
  # Parsed apart from the loop below, which reads every positional as a sweep
  # name. A shoot takes one sweep and one pattern, both required: the pattern is
  # what selects the cells — either by id, or, as 'failed', by this run's own
  # verdicts — so a default would be a second rule, and the only defensible
  # default, 'all', is 1,943 images on the card sweep.
  #
  # Not validated against a list of legal patterns: 'failed' and 'all' are reserved
  # words in a space where everything else is a substring of a cell id, and a
  # pattern that matches nothing is reported after the run with the count.
  for arg in "$@"; do
    case "$arg" in -h|--help) show_help ;; esac
  done
  [ $# -ge 1 ] || die "shoot needs a sweep: ${SWEEPS[*]}"
  suite_for "$1" > /dev/null
  TARGETS=("$1")
  shift
  [ $# -ge 1 ] || die "shoot needs a pattern: 'failed', 'all', or a substring of a cell id"
  PATTERN="$1"
  shift
  [ $# -eq 0 ] || die "shoot takes one sweep and one pattern, and got '$1' as well"
else
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
if [ "$MODE" = "render" ] || [ "$MODE" = "shoot" ]; then
  mkdir -p "$REPORT_DIR"
fi

echo "======================================================="
echo " 📐 Overflow sweep baselines — $MODE"
echo "======================================================="
if [ "$MODE" = "render" ]; then
  # Deliberately not the stamp above: nothing is measured here, so this tree's
  # sha would name a commit these rows were not taken at. Every report states the
  # commit out of its own header instead.
  echo "  Source: $BASELINE_DIR (committed rows — no test run)"
else
  echo "  Commit: $COMMIT$DIRTY"
fi
echo "  Sweeps: ${TARGETS[*]}"
if [ "$MODE" = "shoot" ]; then
  echo "  Cells:  $PATTERN"
fi
echo "======================================================="

# Renders one dataset as MD + HTML. Returns 1 when the file disagrees with its own
# header, which is what FAILED means in these two modes.
#
# Shared by 'render' and 'shoot' because a shoot's whole output is a rendered
# report with its images linked — two copies of this loop would be two places for
# the gallery to be forgotten. The dataset and the output prefix are arguments
# rather than derived from $sweep, because that is the whole difference between the
# two callers: 'render' reads the committed .tsv, and 'shoot' reads the one its own
# run just produced.
render_sweep() {
  local sweep="$1"
  local baseline="$2"
  local out_prefix="$3"
  local shots="$SHOT_ROOT/$sweep"
  local shot_args=()
  local rc=0
  local format code

  [ -f "$baseline" ] || die "no dataset at $baseline — run 'capture' first"
  # Linked whenever a shoot has left a directory there, so a plain 'render' after a
  # 'shoot' needs no extra flag. Passing the directory rather than testing for the
  # manifest keeps its name in one program: the renderer says so if it is missing,
  # and lists any image the rows do not account for.
  if [ -d "$shots" ]; then
    shot_args=(--shots "$shots")
  fi

  for format in md html; do
    # The format name doubles as the extension, so the two reports land beside
    # each other as <prefix>.md and <prefix>.html.
    set +e
    $DART run "$EXTRACTOR" render \
      --baseline "$baseline" --format "$format" \
      --out "$out_prefix.$format" "${shot_args[@]+"${shot_args[@]}"}"
    code=$?
    set -e
    case $code in
      0) ;;
      # The document is still written on a 1 — it is what says what the
      # disagreement was — so both formats are always attempted.
      1) rc=1 ;;
      *) die "could not render $sweep as $format (exit $code)" ;;
    esac
  done
  return $rc
}

FAILED=()
for sweep in "${TARGETS[@]}"; do
  baseline="$BASELINE_DIR/$sweep.tsv"

  if [ "$MODE" = "render" ]; then
    echo ""
    echo "▶ $sweep — $baseline"
    if ! render_sweep "$sweep" "$baseline" "$REPORT_DIR/$sweep"; then
      FAILED+=("$sweep")
    fi
    continue
  fi

  if [ "$MODE" = "shoot" ]; then
    suite="$(suite_for "$sweep")"
    shots="$SHOT_ROOT/$sweep"
    report="$RUN_DIR/$sweep.shoot.json"
    dataset="$RUN_DIR/$sweep.shoot.tsv"

    echo ""
    echo "▶ $sweep — $suite"

    # Replaced, not added to. The manifest is rewritten from scratch by each run,
    # so an image left by an earlier pattern would sit in the folder unlisted and
    # read as part of this shoot to anyone who opened it. $sweep is one of the five
    # registered names by now — suite_for rejected anything else.
    rm -rf "$shots"
    mkdir -p "$shots"

    # OVERFLOW_BASELINE=1 as well as the dump, so this one run produces both halves
    # of the report: the rows and the images then describe the same tree by
    # construction, an image can never be orphaned by rows taken at another commit,
    # and `failed` can be believed — the cells it photographed are the cells the
    # rows beside them call failures. The cost is the same one 'capture' pays: the
    # records go to stdout, so stdout is the dataset and the run is silent.
    #
    # The same scrub 'capture' does, for a related reason: LOCALE or MIN_SCREEN
    # left exported would narrow which cells are enumerated, and the shoot would
    # then be a subset of the pattern without saying so. DUMP is cleared too, so the
    # card sweep's own report PNGs are not written beside these.
    echo "  (silent — this run's records are the dataset: $report)"
    set +e
    env -u LOCALE -u locale -u MIN_SCREEN -u min_screen -u DUMP -u DUMP_MODE \
        -u dump -u dump_mode -u LIST_CARDS -u list_cards \
        OVERFLOW_BASELINE=1 \
        OVERFLOW_PNG="$PATTERN" OVERFLOW_PNG_DIR="$shots" \
        $FLUTTER test "$suite" --reporter json > "$report"
    test_exit=$?
    set -e
    if [ $test_exit -ne 0 ]; then
      # Not fatal, and not unexpected: a red sweep is exactly when a picture is
      # worth having. The images are written per cell as it settles, so a failing
      # coordinate still has one.
      echo "  (the sweep exited $test_exit — its images and records were still written)"
    fi

    $DART run "$EXTRACTOR" extract \
      --reporter "$report" --sweep "$sweep" --commit "$COMMIT" --out "$dataset"

    shot_count=$(find "$shots" -name '*.png' -type f | wc -l | tr -d ' ')
    if [ "$shot_count" -eq 0 ] && [ "$PATTERN" = "failed" ]; then
      # The good outcome, and worth saying out loud rather than leaving as an empty
      # folder: 'failed' shooting nothing means the sweep had nothing to shoot.
      echo "  ✅ nothing failed, so there was nothing to photograph."
      echo "     The report below is the same all-clean dataset a 'check' would diff."
    elif [ "$shot_count" -eq 0 ]; then
      echo "  ⚠ no cell id matched '$PATTERN', so nothing was photographed."
      echo "    A pattern is a plain substring of a cell id — try 'all' or 'failed',"
      echo "    or copy an id out of $REPORT_DIR/$sweep.shoot.md."
    else
      echo "  📸 $shot_count image(s) in $shots"
    fi

    if ! render_sweep "$sweep" "$dataset" "$REPORT_DIR/$sweep.shoot"; then
      FAILED+=("$sweep")
    fi
    continue
  fi

  suite="$(suite_for "$sweep")"
  report="$RUN_DIR/$sweep.json"

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
if [ "$MODE" = "render" ]; then
  if [ ${#FAILED[@]} -eq 0 ]; then
    echo " ✅ Reports in $REPORT_DIR/: ${TARGETS[*]}"
    echo "    Each one describes the commit stamped in its own header, not this"
    echo "    tree — re-capture before reading one as a statement about today."
    exit 0
  fi
  echo " ❌ Rendered, but these disagree with their own headers: ${FAILED[*]}"
  echo "    The counts in a header are written at capture time and the rows were"
  echo "    recounted, so the file has been edited by hand or by another version."
  echo "    Re-capture it rather than quoting the report."
  exit 1
fi
if [ "$MODE" = "shoot" ]; then
  sweep="${TARGETS[0]}"
  echo " 📸 Shot '$PATTERN' → $SHOT_ROOT/$sweep/"
  echo "    open $REPORT_DIR/$sweep.shoot.html"
  echo ""
  echo "    Both halves are of this working tree at $COMMIT: the rows come from the"
  echo "    same run that took the images, not from $BASELINE_DIR/."
  echo "    So they cannot disagree — and nothing here touched a committed baseline"
  echo "    or changed a verdict. To compare the two trees, run 'check $sweep'."
  if [ ${#FAILED[@]} -ne 0 ]; then
    echo ""
    echo " ❌ …but $RUN_DIR/$sweep.shoot.tsv disagrees with its own header — see above."
    echo "    That is this script's own arithmetic failing, not the sweep's: report it."
    exit 1
  fi
  exit 0
fi
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
