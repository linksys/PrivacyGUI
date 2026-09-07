#!/bin/bash
set -e

# Detect fvm: use fvm flutter if available, otherwise use flutter directly
if command -v fvm > /dev/null 2>&1 && [ -f ".fvmrc" ]; then
  FLUTTER="fvm flutter"
  DART="fvm dart"
else
  FLUTTER="flutter"
  DART="dart"
fi

while getopts l:s:f:v: flag
do
    case "${flag}" in
        l) locales=${OPTARG};;
        s) screens=${OPTARG};;
        f) file=${OPTARG};;
        v) version=${OPTARG};;
    esac
done
if [ -z "$locales" ]; then
  locales="en"
fi
if [ -z "$screens" ]; then
  screens="480,1280"
fi
if [ -z "$version" ]; then
  version="0.0.1.1"
fi
echo "*********************Generating Localization snapshots********************"
echo "Locales: $locales"
echo "Screens: $screens"
echo "Version: $version"

# Start every run with an empty overflow report. golden_runner.dart appends to
# this file instead of overwriting it, and skips writing entirely when a run has
# no overflows, so a leftover copy keeps reporting overflows that are already
# fixed. Only this file is removed: the golden PNGs must survive, because -f/-l/-s
# regenerate a subset and clear_goldens.sh is the opt-in way to wipe them all.
rm -f goldens/overflow_warnings.json
# And the diff record (#1475), for a reason specific to a generation run: it
# compares nothing, so it writes no report and would leave the *verify* run's file
# in place. Read afterwards by `golden_diff_summary.dart`, that file describes
# baselines this run has just replaced, and nothing in its output is dated.
rm -f goldens/golden_diff_percent.jsonl

FAILED=0
FAILED_LOCALES=()

if [ -z "$file" ]; then
  IFS=',' read -ra LOCS <<< "$locales"
  for((i=0; i < ${#LOCS[@]}; i++))
  do
    locale="${LOCS[$i]}"
    echo "Start run screenshot testing with screen: $screens, locales: $locale"
    # Each locale is independent work, so one failing locale must not cost the
    # rest of the list (#1477). `set -e` above would abort the loop on the first
    # non-zero exit, and a single crashing page is enough to produce one — which
    # turned a 26-locale generation into one locale of output, with no report
    # and nothing saying so. `if !` puts the command in a condition, where `set
    # -e` does not apply; the failure is remembered instead of being fatal.
    # `run_golden_verify.sh` has always accumulated this way.
    if ! $FLUTTER test test/golden_test/ --update-goldens --dart-define=locales="$locale" --dart-define=screens="$screens" --dart-define=visualEffects=0; then
      FAILED=1
      FAILED_LOCALES+=("$locale")
    fi
  done
else
  echo "Target file: $file"
  # One file, one exit code: there is no list here to be resilient about, and the
  # caller asked for this file's verdict.
  $FLUTTER test $file --update-goldens --dart-define=locales="$locales" --dart-define=screens="$screens" --dart-define=visualEffects=0
  exit $?
fi
echo 'Generating Localization snapshots Finished!******************************************'

# Generated even after a failure, as the verify script does with its own report:
# a partial refresh still has to be reviewable, and the gallery is how it is read.
$DART run test_scripts/generate_gallery_report.dart "$version" || FAILED=1

if [ "$FAILED" -ne 0 ]; then
  # Last, so it survives the report's output. The exit code says a locale failed;
  # only this says which ones have to be re-run — and that the PNGs on disk are a
  # partial refresh rather than a complete one.
  echo ""
  echo "WARNING: failed locales: ${FAILED_LOCALES[*]}"
  echo "Their goldens are incomplete. Re-run those locales before treating"
  echo "goldens/ as refreshed."
fi

exit $FAILED