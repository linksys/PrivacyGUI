# Overflow Sweep Baselines

**Last Updated: 2026-08-22** · #1337, inside epic #1335 · Status: **captured at `4fb1ac5e-dirty`, before any port starts** (`chrome` re-captured at `785c6f67-dirty` for #1356's id fixes — see §5). **Two ports have now been signed off against it**: #1342 (`check chrome`, 1,248 cells identical) and #1343 (`check card`, 1,917 identical).

Every port in epic #1335 is signed off by one claim: *the ported sweep measures
the same cells and reaches the same verdicts as before*. The main card sweep
measures 1,917 coordinates. Nobody can check that by reading output, so this
mechanism turns the claim into a plain diff.

| | |
|---|---|
| Capture / compare | [`tool/overflow_baseline.sh`](../../tool/overflow_baseline.sh) |
| Committed baselines | [`test/fixtures/overflow_baselines/`](../../test/fixtures/overflow_baselines/) |
| Emitter (runs inside the sweeps) | [`test/util/overflow_baseline.dart`](../../test/util/overflow_baseline.dart) |
| Extractor / differ | [`test_scripts/overflow_baseline.dart`](../../test_scripts/overflow_baseline.dart) |
| Architecture it serves | [overflow_gate_architecture.md](overflow_gate_architecture.md) §9.2 R3, R5 |

---

## 1. Using it

```bash
# Freeze today's measured coverage, before touching a sweep
./tool/overflow_baseline.sh capture

# After a port: prove the sweep still measures the same cells identically
./tool/overflow_baseline.sh check chrome     # exit 0 = identical, 1 = differs

# One sweep at a time; `diff` is an alias for `check`
./tool/overflow_baseline.sh capture card
```

`check` runs the sweep and diffs it against the committed file. Exit **0** means
byte-identical, **1** means a difference to read, **2** means the run itself was
unusable (see §4).

**A `check` failure is not automatically a regression.** Read the diff. Three
kinds of difference appear, and they are not equally alarming:

```
1 cell no longer measured (coverage lost — this would otherwise read as a pass):
  - forced_form.skeleton|variant=list|px=122|rows=1          ← the dangerous one
2 new cells:
  + chrome.header|screen_px=800|mode=viewing_local|locale=fr ← added coverage
1 cell changed:
  - card.width|card=lan_info|px=191|tab=0|locale=de  clean     -   -  -              -
  + card.width|card=lan_info|px=191|tab=0|locale=de  overflow  41.0 right lib/a.dart:120 Row
```

Only re-capture once a difference is understood and intended, and say which
difference and why in the commit message. A re-capture is how a lost cell becomes
permanent.

## 2. What is in a baseline

One row per measured coordinate, six tab-separated columns, whole-line sorted:

```
# overflow-baseline 1
# sweep forced_form
# groups forced_form.compact_floor forced_form.popup_tile forced_form.skeleton
# suite test/page/dashboard/cards/dashboard_card_forced_form_overflow_test.dart
# commit 4fb1ac5e-dirty
# cells 75
# incidents 0
# overflows 0
# unmeasured 0
# columns cell	verdict	px	side	site	widget
forced_form.compact_floor|card=connected_devices|px=261|rows=3|locale=de	clean	-	-	-	-
```

| Column | Meaning |
|---|---|
| `cell` | `<sweep>.<group>` then every axis as `name=value`, in declaration order |
| `verdict` | `clean` · `noise` (an incident under the 2.0px tolerance) · `overflow` · `error` (the pump did not finish, so nothing was measured) |
| `px`, `side` | the measurement, `-` when clean. `Infinity` when the overflow string could not be parsed |
| `site`, `widget` | `file:line` and the render object, read off the incident's own `file` / `line` / `widget` fields |

Axis names are the sweep's own. Two conventions worth knowing: `px` is the **card**
width in `card` / `popup` / `forced_form` and `screen_px` is the **screen** width in
`chrome`, because those are the things each sweep actually varies — a single `px`
would read the same in both and mean different things.

Axis **values** carry two rules, both of them consequences of the ids being a join
key that humans also grep (#1356):

- **`locale` has one spelling across all four sweeps: `zh_TW`, not `zh-TW`.** The
  three card sweeps each defined the underscore form privately and `chrome` called
  `Locale.toLanguageTag()`, so the datasets disagreed about how to name one locale.
  It is now `localeTag()` in `test/layout_gate/locale_tag.dart`, imported by all
  four — the same spelling the ratchet's locale lists and `--dart-define=LOCALE=`
  already used.
- **An axis value is an identity, so prose stays out of it.** `chrome.header`'s
  mode axis read `mode=viewing, local (3 actions)`; the count is useful in a
  failure message and fatal in a key, because adding a header action renamed every
  cell of the sweep and the diff would then report the whole coverage lost plus an
  equal number of new cells — the one difference §1 says to treat as dangerous. The
  modes now carry an `id` (`viewing_local`) for the key and a `label` for the
  message.

`# commit` and the other `#` lines are **excluded from the diff**, so re-capturing
at a new commit does not by itself register as a change.

**`-dirty` in `# commit` means what it says.** The suffix is appended when any of
`lib/`, `test/` or `pubspec.yaml` carried uncommitted work at capture time — that
last one because most of the widgets these rows measure are not in this repo:
`ui_kit_library` and `generative_ui` are git dependencies pinned by ref there, so
bumping the ref moves rows exactly as directly as editing `lib/` does. (Not
`pubspec.lock`: it is gitignored here, so no stamp can see a resolved-version
drift. `assets/fonts/` is not on the list either — not because fonts are
irrelevant, they decide every measurement in this dataset, but because none of
the fonts these sweeps load live there: all four call `loadAppFonts()`, which
reads the ui_kit faces from the pub-cache checkout `pubspec.yaml` pins and the
Noto fallbacks from `test/fonts/`, both already covered. The Flutter SDK version
is the one input no stamp here can see.) The four baselines here all carry the
suffix: they were taken with this ticket's own instrumentation still
uncommitted, which is unavoidable for a mechanism that measures the code that
introduces it. So `4fb1ac5e-dirty` reads "the tree at `4fb1ac5e` plus #1337", not
"check out `4fb1ac5e` and re-capture". A baseline can never name the commit that
contains it; the flag is there so nobody reads a plain sha as a promise it cannot
keep.

### Why these fields and not others

- **A clean cell is a row, not an absence.** This is the whole of AC 5. A
  coordinate a port stopped enumerating shows up as a *missing* row, and the diff
  labels it "coverage lost" rather than letting it read as a layout that got
  fixed. Verified against a real reporter stream, not only in unit tests: dropping
  one `#LAYOUT-CELL#` event from a captured `forced_form` run produces exactly
  that line and exit 1.
- **A cell that never finished is `error`, not `clean`.** The same confusion
  returns one level in: a tree that fails to build lays nothing out, so it reports
  no overflow, so its row would be indistinguishable from a coordinate that fits —
  and because the cell *is* in the dataset, the diff would not call it lost either.
  So the emitter states outright whether the pump completed, and a record that omits
  that flag is refused rather than assumed fine.
- **`noise` rows are kept.** The sweeps discard sub-tolerance incidents before
  asserting, so this file is the only place they are visible. Without them, a port
  that loosened the filter would be indistinguishable from a port that fixed a
  card.
- **No test names.** #1335 §6 has already decided a regrouping that collapses
  1,898 test names into 73 group names *by design*. A dataset keyed on test names
  would report that intended change as total loss and total gain, and the real
  question — did the same 1,898 coordinates get measured — would be unanswerable.
  So cells are keyed on their intrinsic axes. **#1343 executed that regrouping**
  (1,921 → 99 tests in the file) and `check card` reported 1,917 cells identical,
  which is the design decision earning its keep: the largest port in the epic is
  signed off by a diff that never saw a test name.
- **Nothing volatile.** No timestamps, no run ids, no durations, no failure prose,
  and no map iteration order: axes are ordered as written and rows are sorted
  whole-line.

## 3. How a coordinate becomes a row

```
  SWEEP (test file)                                  the only opt-in point
  ─────────────────                                  ─────────────────────
  probeCardOverflow(tester, …,
      cell: OverflowCell('card.width', {             ← a null cell emits nothing.
        'card': spec.id, 'px': wc.widthKey,            All 17 probe calls in the
        'tab': tab, 'locale': tag,                     four sweeps name a cell, so
      }))                                              nothing they measure is
        │                                              missing from the dataset
        ▼
  test/util/overflow_probe.dart · runWithOverflowCollection
        │  emits in `finally` — a cell whose pump threw is still recorded, flagged
        ▼
  test/util/overflow_baseline.dart                   OVERFLOW_BASELINE=1 only
        │  print('#LAYOUT-CELL# {"cell":…,"incidents":[…]}')
        ▼
  flutter test --reporter json > build/overflow_baseline/<sweep>.json
        │  the records ride out as `print` events
        ▼
  test_scripts/overflow_baseline.dart · extract → sorted TSV
                                     · diff   → exit 0 / 1
```

Three decisions inside that path are worth knowing:

1. **`OVERFLOW_BASELINE=1` is an environment variable, not a `--dart-define`.** A
   `--dart-define` is compiled in, so toggling it invalidates the kernel and every
   capture pays a full recompile.
2. **The `significant` verdict is computed by the emitter**, where
   `kOverflowTolerancePx` is in scope. #1270 made that constant shared precisely so
   the number is stated once; the extractor never restates it.
3. **The source location is read off the incident, not parsed again.** #1337
   shipped this by calling the golden framework's `parseOverflowSource` on
   `OverflowIncident.fullLog` — borrowing the only parser that resolved a location
   at the time, rather than adding a third. #1338 then gave the incident its own
   `file` / `line` / `widget`, and **#1351 switched these columns to those fields
   and dropped the import**, so the location is resolved once, at collection time,
   by the parser the whole gate family shares. One consequence is visible in the
   JSON: `line` is an `int` now, so it serializes unquoted. The TSVs do not move —
   the extractor renders every column through `'$value'`, and all 3,587 committed
   rows are `clean` anyway.

## 4. What the extractor refuses

Silence is the only failure mode a baseline cannot survive: a short dataset looks
like a smaller, cleaner run. So the extractor exits **2** rather than write a file
when the stream is not demonstrably whole.

| Refused | Message contains |
|---|---|
| A NUL byte anywhere in the stream | `NUL` — see below |
| A `{`-prefixed line that will not parse | `truncated` |
| No `done` event | `did not finish` |
| An error attributed to a `loading` / `compiling` test | `failed to load` |
| A record whose cell id has a foreign sweep prefix | names the sweep |
| The same cell id twice | `twice` |
| A record missing `significant` | names the field |
| A record missing `threw` | names the field |

### The `--file-reporter` trap

**Do not capture with `flutter test --file-reporter json:<file>`.** Its file sink
interleaves writes and leaves runs of NUL bytes at 16KB boundaries. This ticket's
first `forced_form` capture reported **53 cells**; the same code captured through
stdout reports **75**. The 22 missing cells were not flagged anywhere — the hole
swallowed their `print` events, the run still ended `success: true` with zero
errors, and the result read as a smaller sweep that was entirely clean.

`--reporter json` redirected to a file keeps one writer on the stream. The NUL
check exists because the failure was invisible from the outside, and a baseline
that is silently short poisons every later comparison.

### The environment is cleared, not trusted

The card sweeps read `LOCALE`, `MIN_SCREEN`, `DUMP` and `LIST_CARDS` from the
environment to narrow a debugging run. Any of them left exported would change
*which cells exist*, and the resulting subset would then pass every diff taken
against it. `tool/overflow_baseline.sh` unsets all four (both spellings) before
each run.

## 5. The four baselines, as captured

Taken at `4fb1ac5e-dirty` on `fix/1314-1328-chrome-overflow` — that is, at
`4fb1ac5e` plus this ticket's instrumentation — before any port. `chrome` was
**re-captured at `785c6f67-dirty`** for the id changes described in §2, and that
re-capture is the one case where a rewritten dataset is not a measurement change:
each of its 984 affected rows maps to exactly one row of the old file under
`mode=viewing, local (3 actions)` → `mode=viewing_local` and `locale=zh-TW` →
`locale=zh_TW`, with the same cell count and the same six columns per row. The
other three files are untouched, and that is the evidence the shared `localeTag()`
changed nothing for them: `check card popup forced_form` compares 1,917 + 347 + 75
cells against the pre-#1356 bytes and reports all three identical.

| Sweep | Suite | Cells | Overflows | Groups |
|---|---|---|---|---|
| `card` | `dashboard_card_overflow_test.dart` | 1,917 | 0 | `width` 1638 · `normal_band` 208 · `profile` 52 · `single_view` 12 · `tab_registry` 6 · `profile_data` 1 |
| `chrome` | `page_chrome_overflow_test.dart` | 1,248 | 0 | `header` 936 · `top_bar` 312 |
| `popup` | `dashboard_card_popup_overflow_test.dart` | 347 | 0 | `form` 234 · `picked_dialog` 51 · `dialog` 27 · `picked_value` 17 · `picked_height` 17 · `exempt` 1 |
| `forced_form` | `dashboard_card_forced_form_overflow_test.dart` | 75 | 0 | `popup_tile` 51 · `compact_floor` 18 · `skeleton` 6 |

**`card`'s density cells come to 1,638 + 208 + 52 = 1,898**, the figure
[overflow_gate_architecture.md](overflow_gate_architecture.md) §1.2 measured
independently and §6 pins as what the port must preserve. The remaining 19 are the
structural guards in the same file — the tab registry, the single-view inverse, and
the check that a data profile reaches the render. They are measured coordinates
(each pumps a real card and collects real incidents), and they are also what keeps
the density cells honest: without `profile_data` the 52 `profile` cells can pump the
default fixture and pass. A port that dropped a guard would otherwise diff clean, so
they are in the dataset too, under group names of their own.

**Every cell is clean, and that is the point.** `known_overflows.json` is
`{"tracking": {}, "allowlist": {}}` — zero tolerance is already fact — so there is
no red failure set to freeze. The entry *shape* changed at #1356's review (an
exemption now carries a `maxOverflowPx` ceiling beside its locale list, and the
two sections must name the same sites — see
[overflow_gate_architecture.md](overflow_gate_architecture.md) §3), but an empty
map is an empty map under either shape, and all four baselines still `check`
identical. What is being frozen is the *coverage*: 3,587
coordinates that are measured and clean today. Against an all-clean baseline the
only difference a port can produce is a lost cell, a new overflow, or a cell that
stopped finishing — which is exactly what R3 and R5 need to detect, and what a
pass/fail run cannot distinguish from success.

Two notes on these numbers:

- **Cells are not pumps.** §1.2 estimates "~1,468 pumps" in the chrome file against
  1,248 cells here. The difference is not uninstrumented coverage: every call that
  installs the overflow collector in all four sweeps names a cell (17 of 17). The
  rest of that file's pumps are behaviour tests — menu selection, action
  reachability, the title staying whole — which never collect overflow and so have
  no measurement to record.
- **Only the four local sweeps are covered.** The golden side has no local
  baseline to capture at all: the default local matrix is one locale by two
  devices, it writes no `overflow_warnings.json`, and every coordinate that
  pipeline has found is locale-driven. That is #1346's problem, recorded in
  §8 of the architecture document.

## 6. Tests

| File | Covers |
|---|---|
| `test/util/overflow_baseline_test.dart` | cell id construction and sanitising, record shape, the tolerance verdict, a `testWidgets` that induces a real `Row` overflow and asserts the row it produces end to end, and a pump that throws — proving it is recorded and flagged rather than dropped or read as clean |
| `test/test_scripts/overflow_baseline_test.dart` | extraction, every refusal in §4, rendering, parsing, and the diff's difference kinds, including a cell that became `error`. Two contract tests span the `flutter_test` / bare-`dart` boundary, where nothing can be imported: `overflowBaselineMarker == emitter.kOverflowBaselineMarker`, and a cell id built by the real emitter routed back to its group by the real extractor. Both would otherwise drift silently — as an empty dataset reading "no overflows anywhere", or as records filed under a baseline they do not belong to |
