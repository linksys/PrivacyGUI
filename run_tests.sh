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

# test/web/canvaskit_variant_test.dart compares web/assets/canvaskit.* against
# the copy in the SDK's own flutter_web_sdk/, and that directory is an on-demand
# artifact: `flutter test` never fetches it (only `--platform chrome` does), and
# neither does subosito/flutter-action's setup.sh. A fresh `fvm install` has no
# flutter_web_sdk at all — measured, 3.27.4 and 3.38.5 installs on this machine
# have none — so without this line the guard fails on the first run after any pin
# bump, on every machine, for an environment reason and not a real drift.
#
# It belongs here rather than in one CI job because this script is what both a
# developer and CI job 2 invoke, so the prerequisite travels with the command that
# needs it instead of with a runner. A job that runs test/web/ WITHOUT going
# through this script still needs its own precache; the test's failure message
# says so.
#
# The guard fails rather than skips when the SDK copy is missing, on purpose — a
# skipped guard reports green while checking nothing, which is the exact mechanism
# that let a 3.44.0 CanvasKit ship under a 3.47.0 engine. So the environment is
# what has to be fixed, not the assertion.
#
# Silent and ~1s once cached, so it does not read as work being done. It is not
# dead on CI either: flutter-action restores the SDK from a cache keyed on the SDK
# VERSION, so the first run after a pin bump is the cold one — the same run where
# the vendored CanvasKit is what is in question. See the comment in ci.yml's
# unit-test job for the measurement.
$FLUTTER precache --web

# The PR-blocking selection, in exactly one place. What makes `layout-gate`
# PR-blocking is its *absence* from this list, which is the same thing
# dart_test.yaml says from the other side — so moving `layout-gate` into
# BASE_EXCLUDE_TAGS is how the whole gate leaves the PR command in silence.
#
# EDIT THIS AND YOU MUST EDIT `.github/workflows/ci.yml` TOO. The CI gate job does
# not go through this script — it spells the same string out itself — so changing
# only this line leaves a tag excluded here, still excluded there, and running in
# neither job with both green. The comment above that job explains what holds the
# partition together; this is the other end of the same warning, because whoever
# breaks it will be reading this line and not that one.
BASE_EXCLUDE_TAGS="golden||loc||ui"

# Opt-in narrowing, for CI only. `.github/workflows/ci.yml` runs the layout gate
# as its own job — so a PR says which gate failed instead of failing at the first
# step and never reaching the rest — and sets EXTRA_EXCLUDE_TAGS=layout-gate on
# the *unit* job so the two jobs do not both pay for the page sweep. The two
# selectors partition this script's set exactly:
#
#   unit job:  --exclude-tags="golden||loc||ui||layout-gate"
#   gate job:  --tags layout-gate --exclude-tags="golden||loc||ui"
#
# Union is what `./run_tests.sh` runs, intersection is empty, both by
# construction. The gate job carries the base exclusion too, and not for
# symmetry: without it a suite tagged both `layout-gate` and `golden` would run
# there while this script skips it, and the two jobs would stop being a partition
# of anything.
#
# Do not set this locally. The default has to stay complete, because the local
# command is the only one a developer runs before pushing — and it is already
# missing `dart format`, which is what let a format failure reach CI unseen.
EXCLUDE_TAGS="${BASE_EXCLUDE_TAGS}${EXTRA_EXCLUDE_TAGS:+||${EXTRA_EXCLUDE_TAGS}}"
if [ -n "$EXTRA_EXCLUDE_TAGS" ]; then
  echo "Narrowed run: excluding $EXCLUDE_TAGS (EXTRA_EXCLUDE_TAGS=$EXTRA_EXCLUDE_TAGS)"
fi

# Run the PR-blocking suite and leave one JSON reporter event per line in $1.
# Returns the test command's own exit code.
#
# `--reporter json` redirected, not `--file-reporter json:$1`: the file sink
# interleaves writes and leaves 16KB runs of NUL bytes mid-stream, and every event
# inside a hole is simply gone — a truncated report that reads as a smaller, clean
# run. See "WHY NOT --file-reporter" in tool/overflow_baseline.sh, whose extractor
# rejects NUL for the same reason. One writer on the stream is the whole fix.
run_tests_to_json() {
  local dest="$1"
  local raw="${dest}.raw"
  $FLUTTER test --reporter json --exclude-tags="$EXCLUDE_TAGS" > "$raw"
  local exit_code=$?
  # The flutter tool's own notices ("The following plugins do not support…") share
  # stdout with the events, and one of them in front of `jq -s` — or of the legacy
  # parser's unguarded jsonDecode — fails the whole parse. `-a` so a NUL, if one
  # ever reappears, does not turn this into "binary file matches".
  grep -a '^{' "$raw" > "$dest"
  if [ $exit_code -ne 0 ]; then
    # The redirect silenced the live run, and a compile failure never becomes an
    # event: it is one of the lines just filtered out. Say it here or lose it.
    grep -av '^{' "$raw" >&2
  fi
  rm -f "$raw"
  return $exit_code
}

# Name the failures the redirect silenced. generate_report counts them; this is
# the only place the run says which test and why. `.error` only — the stack trace
# stays in the JSON, and this is a summary.
print_failures() {
  local json_file="$1"
  cat "$json_file" | jq -rs '
  (map(select(.type == "suite")) | map({(.suite.id | tostring): .suite.path}) | add // {}) as $suites |
  (map(select(.type == "testStart")) | map({(.test.id | tostring): {
    name: .test.name,
    suite: ($suites[(.test.suiteID | tostring)] // "unknown")
  }}) | add // {}) as $tests |
  (map(select(.type == "error"))) as $errors |
  [.[] | select(.type == "testDone" and .hidden == false and (.result == "failure" or .result == "error")) | (.testID | tostring)] |
  if length == 0 then empty else
    map(. as $id |
      "✗ \($tests[$id].suite // "unknown") › \($tests[$id].name // $id)" +
      ([$errors[] | select((.testID | tostring) == $id) | "\n  \(.error)"] | join(""))
    ) | join("\n\n")
  end
  '
}

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

# `=` and not `==`: this script declares `#!/bin/bash`, but it was invoked as
# `sh run_tests.sh` from CI until 2026-08-27, and Ubuntu's `sh` is dash, whose `[`
# has no `==`. That printed `[: unexpected operator` into every unit-test job log,
# and — worse — sent `--report` down the *else* branch, because a failed `[` is just
# a false `if`. The caller was fixed to `bash run_tests.sh`; this is belt as well as
# braces, and since `==` was the only bash-only construct in the file (`local` is
# fine in dash) the script now behaves identically under either shell.
if [ "$reportPath" = "--report" ]; then
  # Generate markdown report
  echo "*********************Running Tests********************"
  JSON_FILE="/tmp/test_results_$$.json"
  run_tests_to_json "$JSON_FILE"
  TEST_EXIT=$?

  echo ""
  echo "*********************Test Report**********************"
  generate_report "$JSON_FILE"
  echo ""

  if [ $TEST_EXIT -ne 0 ]; then
    echo "*********************Failures*************************"
    print_failures "$JSON_FILE"
    echo ""
  fi

  rm -f "$JSON_FILE"
  exit $TEST_EXIT
elif [ -z "$reportPath" ]; then
  # When no report path is given, just run the tests and exit with the status of the test command.
  $FLUTTER test --exclude-tags="$EXCLUDE_TAGS"
else
  # When a report path is given, run tests and generate a report (legacy HTML mode).
  echo "*********************Running Tests********************"
  mkdir -p "$reportPath"
  run_tests_to_json "$reportPath/tests.json"

  if ! $DART test_scripts/test_result_parser.dart $reportPath/tests.json $reportPath/app-test-reports.html; then
    echo 'Test failed!******************************************'
    exit 1
  else
    echo 'Test passed!******************************************'
    exit 0
  fi
fi