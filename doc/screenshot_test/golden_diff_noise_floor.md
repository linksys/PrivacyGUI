# Golden diff noise floor — the measurement #1475's numbers come from

**Status**: instrument shipped, measurement not taken. Nothing in the suite's
thresholds has changed.

## What is wrong

`diffThreshold: 0.025` (`test/golden_test/flutter_test_config.dart`) is a fraction
of the canvas, so the allowance grows with area while a defect confined to a badge,
a chip, a status dot or a link style is laid out at a fixed size.

#1472's regression — an extender that silently stopped reading online — measured
**4.209% at `phone480` (failed), 1.376% at `screen1080` and 0.858% at
`desktop1280` (both passed)**. `usp_topology_view` pins `height: 1000`, so in
pixels:

| width | canvas    |     area | 2.5% allowance | #1472's footprint | of allowance |
|------:|:----------|---------:|---------------:|------------------:|-------------:|
|   480 | 480×1000  |  480,000 |         12,000 |            20,203 |         168% |
|  1080 | 1080×1000 | 1,080,000 |        27,000 |            14,861 |          55% |
|  1280 | 1280×1000 | 1,280,000 |        32,000 |            10,982 |          34% |

The same defect: its footprint *halved* as the layout reflowed wider while the
allowance nearly tripled. Golden-ci sweeps 480, 1080 and 1280, so two of the three
widths could not have caught it.

### The same badge is 1,628 pixels at every width

#1472's figures mix two effects: the canvas grew *and* the layout reflowed, so the
footprint moved too. The instrument can separate them, and the first thing it
measured was the branch it shipped on. #1476 repaints the liveness badge on three
node-detail scenes — the smallest semantic change this suite has: `offline` becomes
`online` on one chip. Reverting its five files and comparing against refreshed
baselines at one height:

| canvas   |      area | diffPercent | differing px | of 2.5% allowance |
|:---------|----------:|------------:|-------------:|------------------:|
| 480×800  |   384,000 |      0.424% |        1,628 |             17.0% |
| 1280×800 | 1,024,000 |      0.159% |        1,628 |              6.4% |

The pixels are identical to the unit — the same chip, laid out at the same size —
and the percentage falls by 2.667×, which is exactly 1280/480. Nothing about the
change is width-dependent; only the denominator is. Both widths passed, and the
suite reported `All tests passed!` while three scenes said the opposite of what
their baselines said.

That is the blindness stated as a number: **a deliberate, reviewed, semantically
loaded repaint spends 6.4% of the allowance at `desktop1280`** — 15× headroom for a
regression of that size to hide in. #1472 was *larger* than this, six or seven
badges' worth (10,982 px at `desktop1280`, 34% of the allowance), and it still
passed at both wide widths. So the badge figure is not the worst case; it is the
floor of what this suite cannot see.

### The height is part of the canvas, and it is per suite

`GoldenTestConfig.height` overrides the 800 default and **19 of the 31 golden suites
set it**, so one width is many canvases. The load-bearing consequence, measured at
width 480 alone: **12 distinct heights, from 140 (`remote_assistance_banner`) to
4200 (`usp_statistics_view`) — a 30× spread of area, and so of what one percent
means.** "The allowance at 480" is not one number, a figure grouped by width alone
averages percentages that do not share a unit, and both the record and the summary
are therefore keyed by **canvas**. The per-width answer is the worst tolerated diff
across that width's canvases.

This is the census, and it lives here only — every other file states the
consequence and points back, because a suite added tomorrow expires the numbers.
Measured 2026-09-04 over 501 local baselines: **35 distinct geometries** across 7
widths (400, 480, 500, 600, 800, 1080, 1280 — component and card suites sweep their
own). Baselines are gitignored, so that is one machine's generated set and a lower
bound on a full sweep. To re-measure:

```sh
find test/golden_test -name '*.png' -path '*/goldens/*' | while read f; do
  python3 -c "import struct,sys; d=open(sys.argv[1],'rb').read(24); \
    print('%dx%d' % struct.unpack('>II', d[16:24]))" "$f"
done | sort | uniq -c | sort -rn
```

Do not read the suite count off this list, and do not cross-check one against the
other: they were 31 and 31 in an earlier draft of this document, which looked like
agreement and was a coincidence — the geometry count was wrong.

## Why the fix is a measurement first

The same threshold absorbs two unrelated things: real regressions, and CI platform
noise (font rasterisation, CanvasKit build, GPU vs software renderer, host OS).
Scaling the wide widths down to `phone480`'s effective sensitivity — the obvious
fix, and mechanically available today, since `AlchemistConfig.current()` is read
synchronously at test registration inside a `runZoned` — risks turning the whole
suite red for reasons that have nothing to do with the app.

Nobody knew the floor, and until #1475 nobody *could*:
`AlchemistFileComparator.compare` computes `diffPercent`, compares it to the
threshold, and on a pass returns `true` and drops the number. **A run where every
cell diffs by 2.4% was byte-for-byte as quiet as a run where every cell is
identical.**

## What shipped

An instrument, and no threshold change.

- `test/golden_test/golden_framework/golden_diff_record.dart` —
  `GoldenDiffRecordingComparator`, a subclass of `AlchemistFileComparator` that
  keeps the `diffPercent` its parent discards. Verdicts are the parent's, asserted
  as parity in `test/test_scripts/golden_diff_record_test.dart`; one comparison per
  cell, so the run costs the same.
- `goldens/golden_diff_percent.jsonl` — appended per suite beside
  `overflow_warnings.json`, gitignored. Non-zero diffs are listed individually;
  identical cells are counted per canvas, because a mover count without a
  denominator says nothing. JSON Lines and append-only because every suite writes
  and `flutter test` runs them concurrently: a read-modify-write could drop another
  suite's *denominator*, which is the deliverable. A cell whose baseline is missing
  is counted as `uncomparable` rather than skipped — it is a cell absent from a
  denominator the summary divides by, and until #1475 handled it the node-detail
  suite silently reported 6 cells at `480×800` against 7 at `1280×800`.
- `test_scripts/golden_diff_summary.dart` — prints the per-canvas table, the worst
  tolerated movement per width, and a warning for anything that makes the report
  incomplete. `run_golden_verify.sh` clears the report before a run and prints the
  summary after it; `clear_goldens.sh` and `run_generate_loc_snapshots.sh` clear it
  too, so a stale report can never be read as current.

## The procedure

The numbers have to come from CI, not from a laptop. Measured locally across four
suites — 41 compared cells over 10 canvas geometries — every movement was traceable
to a baseline older than the code, and **every one reproduced its `diffPercent`
byte-for-byte on a repeat run** (measured twice on `test/golden_test/page/shared/`:
`0.00053125` and `0.00019921875` both times, 204 px each). Rendering on one machine
is deterministic, so this machine's own contribution to the floor is zero and a
local mover is a stale baseline rather than a sample of anything.

That determinism is also the cheapest test in the procedure below: **a diff that
repeats exactly is not noise.** A floor is made of cells that move by a *different*
amount each run, which is why two or three CI runs are needed rather than one.

1. **Run golden-ci with no app change.** Baselines already refreshed, no
   application commit in between — the only thing that can move pixels is the
   environment. Two or three runs, ideally not back-to-back, so a one-off is
   distinguishable from a floor.
2. **Collect `goldens/golden_diff_percent.jsonl` from each run** as a CI artifact,
   and read each with `dart run test_scripts/golden_diff_summary.dart <path>`.
   **This step has no owner yet.** The golden jobs run in the private
   `PrivacyGUI-golden-ci` repo and `/goldens/` is gitignored, so the file exists on
   the runner and nowhere else: uploading it is a change over there, not here, and
   no cross-repo issue is filed for it. Nothing downstream of this step can happen
   until it is.
3. **Check the summary printed no WARNING.** Each one says the reading is not a
   floor, and none of them is recoverable by squinting at the table:
   - *cells exceeded the threshold* — the run is not a no-change run. A stale
     baseline or a real regression; explain it and re-run. Those cells are held out
     of the columns, so a failure cannot inflate the floor either.
   - *cells compared with no recorder installed* — the report's silence is not
     evidence; see `GoldenDiffLog.unmeasured`.
   - *cells had no baseline to compare against* — the sweep is not against a
     complete set of baselines, and each such cell is missing from the denominator
     the table divides by. Refresh, then re-run.
   - *lines could not be read* / *canvases recorded more cells than they reported* —
     the report is missing part of the sweep, so every percentile is over an unknown
     denominator.
4. **Read the table per canvas.** `max diff` is the floor: the largest movement the
   environment produced with nothing to blame. `max px` is that in pixels, which is
   the unit the floor is actually produced in and the only one comparable across
   canvases — a floor of "a few pixels of antialiasing" and one of "a 120×120 block"
   are the same percentage at different heights. `p95`/`p99` say whether the max is a
   population or one flaky cell. `of allow` says how much of the current 2.5% the
   noise already uses.
5. **Take the per-width figure from the "worst tolerated movement" block**, not from
   an average across canvases: a threshold is compared against `diffPercent`, so a
   per-width threshold has to clear the largest `diffPercent` any canvas at that
   width produced. The block names the canvas and the golden, which is what you
   investigate if the number is surprising.
6. **Only then pick per-width thresholds**, above the observed max by a margin the
   run's own spread justifies, and land them as a separate change so a red suite
   is attributable. Candidate mechanism: `AlchemistConfig.runWithConfig` per width,
   which works because alchemist reads the config synchronously when the test
   registers.

## What this does not fix

Nothing about *large*-area regressions, which the current threshold already
catches, and nothing about the fact that a golden compares pixels rather than
meaning. A defect small enough to hide under any tolerance a real CI floor
permits still needs a semantic assertion — that is #1475's option B and what
#1472/#1473 shipped for topology (`test/page/topology/
topology_scene_reachability_test.dart`, `usp_node_detail_header_liveness_test.dart`).
Prefer it whenever the fact you care about can be named: those assertions cost no
pixels and hold at every width.

Baseline-refresh policy is explicitly out of scope (#1475).
