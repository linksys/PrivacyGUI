# Overflow Sweep Baselines

**Last Updated: 2026-08-24** · #1337, inside epic #1335 · Status: **captured at `4fb1ac5e-dirty`, before any port starts** (`chrome` re-captured at `785c6f67-dirty` for #1356's id fixes; all four re-captured at `25d1b8ed-dirty` for the `dev-2.7.0` merge — see §5). **All four ports were signed off against it**: #1342 (`check chrome`, 1,248 cells identical), #1343 (`check card`, 1,917 identical), #1345 (`check popup`, 347 byte-identical) and #1344 (`check forced_form`, 75 cells with six renamed ids). **A fifth baseline arrived at `69079cb0-dirty`** — `page`, 416 cells from #1349's two-page pilot — which is the first one captured *after* the framework existed rather than to protect a port through it, and registering it took two lines of `tool/overflow_baseline.sh`. A third subcommand, **`render`**, was added the same day so the committed rows can be read as a report without running anything (§1), and a fourth, **`shoot`**, photographs cells — either the ones a cell-id pattern names, which is the first thing in the whole family that can show what a *passing* cell renders as (#1240 AC1, #1349's wrap), or, as `shoot <sweep> failed`, exactly the cells that run judged as failures. It reports on its own run, so the rows and the images are always one tree (§1).

Every port in epic #1335 is signed off by one claim: *the ported sweep measures
the same cells and reaches the same verdicts as before*. The main card sweep
measures 1,917 coordinates. Nobody can check that by reading output, so this
mechanism turns the claim into a plain diff.

| | |
|---|---|
| Capture / compare / render / shoot | [`tool/overflow_baseline.sh`](../../tool/overflow_baseline.sh) |
| Committed baselines | [`test/fixtures/overflow_baselines/`](../../test/fixtures/overflow_baselines/) |
| Emitter (runs inside the sweeps) | [`test/util/overflow_baseline.dart`](../../test/util/overflow_baseline.dart) |
| Screenshot dump (runs inside the sweeps) | [`test/layout_gate/screenshot.dart`](../../test/layout_gate/screenshot.dart) |
| Extractor / differ / reporter | [`test_scripts/overflow_baseline.dart`](../../test_scripts/overflow_baseline.dart) |
| Rendered reports (gitignored) | `build/overflow_baseline/report/<sweep>.baseline.{md,html}` from `render`, `<sweep>.shoot.{md,html}` from `shoot` — named after whose rows they hold |
| Screenshots (gitignored) | `build/overflow_baseline/shots/<sweep>/` |
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

### Reading one without running it — `render`

A baseline is 4,032 sorted rows across five files. `check` answers "did it move";
it does not answer "what does this sweep cover", which is the question anyone
inheriting the gate asks first. `render` turns a committed `.tsv` into a report:

```bash
# Every sweep, Markdown + HTML, seconds — no flutter, no test run
./tool/overflow_baseline.sh render

# One sweep, then read it
./tool/overflow_baseline.sh render page && open build/overflow_baseline/report/page.baseline.html
```

Reports land in `build/overflow_baseline/report/<sweep>.baseline.{md,html}`
(gitignored).
Each one recounts the dataset and states, in this order: where the rows came from,
the summary counts, coverage per group, coverage per axis with its denominator, and
the findings keyed the way `known_overflows.json` is keyed — so a real failure set
can be read as an allowlist worklist rather than transcribed from scrollback.

Three things about it are deliberate:

- **It reads the file, not a run.** So it describes the commit stamped in that
  file's header and *not* the working tree it was invoked from, which the document
  says at the top of itself. This is also why it generalises: the per-cell table is
  already sweep-agnostic, while the card sweep's own HTML report
  (`dashboard_overflow_report_generator.dart`, `DUMP=2`) is card-shaped — column
  span, a grid recommendation, before/after PNGs. Use that one for a card; use this
  one for any of the five, and `shoot` (below) when it needs pictures.
- **Every number is recounted from the rows**, then compared against the header the
  capture wrote. A disagreement is not silently preferred either way: it becomes a
  warning inside the document, a line on stderr, and **exit 1**. A hand-edited
  header therefore cannot launder itself into a plausible-looking report.
- **Nothing volatile is in the output** — no timestamp, no duration, no run id — so
  two renders of one file are byte-identical and two reports diff as cleanly as the
  datasets do. Pinned by a byte-identity test. The one input-dependent string is the
  `--baseline` path itself, quoted back as the first line of provenance: render a
  copy from `/tmp` and the report says `/tmp`, which is the report naming what it
  read rather than volatility.

Exit codes match the rest of the tool: **0** clean, **1** the file disagrees with
its own header, **2** bad input (an unknown `--format`, a missing baseline).

### Photographing cells — `shoot`

`shoot` runs one sweep against the working tree, writes a PNG per selected cell, and
reports on **that same run** — so the rows and the images always describe one tree.
It answers two different questions depending on how the cells are selected.

#### `shoot <sweep> failed` — a picture of what went red

The first thing to reach for when a sweep fails, because the ids of the failures are
exactly what you do not want to retype:

```bash
./tool/overflow_baseline.sh shoot page failed && open build/overflow_baseline/report/page.shoot.html
```

`failed` means what the sweep means by it: an overflow past the 2.0px tolerance, or
a pump that threw — not "any incident was collected", since a sub-tolerance `noise`
row is a cell that passed. On a green sweep it writes **nothing at all**, not even a
manifest, and says so.

It costs one thing the pattern modes below do not. A boundary has to be in place
*before* the pump, when no verdict exists yet, so `failed` wraps **every** cell and
discards the wrappers of the ones that passed. A `RepaintBoundary` adds a layer and
not a constraint, so this moves no geometry: measured over all five sweeps at
`83e90159-dirty`, a `failed` shoot reproduces all **4,032** committed rows exactly,
and `sweep_test.dart` asserts the same thing per cell.

#### `shoot <sweep> <pattern>` — a picture of what the gate calls clean

Every row in all five datasets says `clean`, and that word means one thing only:
no `RenderFlex` reported an overflow. It does not mean the coordinate is legible.
Two findings already live in that gap:

- Four dashboard cards pass at 191px rendering unreadably (#1240 AC1). Nothing
  overflowed, so the gate is blind to it by construction.
- #1349's fix traded an overflow for a **wrap**, which no cell can see either;
  `PageSurfaceFamily` declined the per-cell readability assertion in writing and
  guards the one changed site with a hand-written test instead.

Neither is reachable from a verdict, and the card sweep's own PNG pair cannot help:
it is written downstream of `if (significant.isEmpty) return null`, so a green tree
produces **zero** images. A pattern selects cells by id, whatever their verdict:

```bash
# Every Arabic page cell — 16 images, then the report that links them
./tool/overflow_baseline.sh shoot page locale=ar && open build/overflow_baseline/report/page.shoot.html

# One coordinate, the id copied out of the report
./tool/overflow_baseline.sh shoot page 'page.dhcp|screen_px=601|locale=ru'

# The #1240 AC1 width, English only, across every card that realises at 191px
./tool/overflow_baseline.sh shoot card 'px=191|tab=0|locale=en'
```

A pattern is a plain substring of a cell id, or the word `all`. There is no default,
because the only defensible one is `all` and that is 1,943 images on the card sweep.

The third command answers #1240 AC1 in nine images: at 191px the Network Health card
renders as the number `70` and its title, gauge and legend gone, and the dataset
calls that cell `clean` — correctly, because nothing overflowed.

#### What both modes write

Images land in `build/overflow_baseline/shots/<sweep>/` (gitignored), named after
the coordinate — `page.dhcp|screen_px=320|locale=ar` becomes
`page.dhcp__screen_px-320__locale-ar.png` — and the run's own report,
`build/overflow_baseline/report/<sweep>.shoot.{md,html}`, grows a **Screenshots**
gallery linking each one. The gallery's prose is recounted from the rows, so it says
which of the two shoots produced it rather than trusting the pattern it was given.
The frame is the whole surface the sweep pumped rather than a crop of the widget
under test, so a card cell shows the card in its grid slot and the empty page beside
it is real. A shoot **opens** its report when it finishes rather than printing the
path; `NO_OPEN=1` (or no TTY, or no `open`) falls back to printing it.

Both suffixes are load-bearing. `render` writes `<sweep>.baseline.{md,html}` and
`shoot` writes `<sweep>.shoot.{md,html}`, named after **whose rows they hold** — and
neither name is bare, because a bare `<sweep>.html` was the shorter thing to type
*and* the one that is green whatever the working tree does, so opening it after a red
shoot reads as "nothing failed". `render` deletes a pre-rename `<sweep>.html` if it
finds one, for the same reason.

Four properties are worth knowing before trusting one:

- **Both halves come from one run.** `shoot` sets `OVERFLOW_BASELINE=1` as well as
  the dump, extracts the records to `build/overflow_baseline/<sweep>.shoot.tsv`, and
  renders *that* — never `test/fixtures/`. So an image cannot be orphaned by rows
  taken at another commit, and `failed` can be believed. The cost is the one
  `capture` pays: the records go to stdout, so the run is silent.

  **This property is `shoot`'s alone.** A later `render <sweep>` reads the committed
  dataset and still links the same shots folder with no extra flag, so its two halves
  are two trees — and the orphan warning does *not* reliably catch that, because it
  fires on an image whose cell id the dataset lacks. The ordinary case has the id
  present as a `clean` row, so nothing warns and the gallery prose calls it a cell
  that passed while the picture shows the overflow stripes. Measured: after
  `shoot page failed` on a tree with #1349's fix removed, `render page` linked all
  three broken images under "a verdict above says no `RenderFlex` overflowed", in
  silence. Read a `.baseline` report's gallery as "images from some run", and a
  `.shoot` report's as "images from this one".
- **Selection is by cell id, or by this run's own verdicts.** `failed`, `all`, or a
  substring. Reserved words rather than a flag beside a pattern, so there is one
  input to explain and one rule per run.
- **A shoot changes nothing.** No verdict, no baseline, no row. The capture happens
  after the measurement and before the family judges — so a popup cell photographs
  the dialog rather than the tile behind it, and an allowlisted overflow is still
  shot, because looking at it is the point. The boundary goes *outside* the per-cell
  `KeyedSubtree`, so a shot run and an unshot run pump the same subtree: `check`
  after a `shoot` is byte-identical, which is why the order is that way round.
- **It cannot fail a sweep.** The dump swallows and prints its own errors
  (`[PNG DUMP …]`), because a capture runs inside `measureOverflowCell`'s `try`
  where invariant 3 would attribute a raised exception to the *cell* — one mistyped
  directory would turn a green sweep into thousands of cells that "threw". It also
  runs in the `catch`, where a cell that threw is photographed as Flutter's red error
  box, so the guard is around the whole capture and not merely its body: a dump that
  raised there would replace the error it exists to document. A row reaches the
  manifest only after its bytes land, so the gallery can never link a 404.
  `test/layout_gate/sweep_test.dart` pins all of it.

The mechanism is two programs that cannot import each other — `test_scripts/` runs
under a bare `dart run` — so the folder carries a manifest, `index.tsv`, headed
`# overflow-screenshots 1` with one `cell id<TAB>file name` row per image, appended
as each shot lands so a killed run still leaves a readable index. Both sides keep
their own copy of that version string on purpose; the pair is pinned by tests on
both sides.

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

- **`locale` has one spelling across all five sweeps: `zh_TW`, not `zh-TW`.** The
  three card sweeps each defined the underscore form privately and `chrome` called
  `Locale.toLanguageTag()`, so the datasets disagreed about how to name one locale.
  It is now `localeTag()` in `test/layout_gate/locale_tag.dart`, imported by all
  five — the fifth reaching it through `runOverflowSweep` rather than by hand,
  which is the shape #1342 built it in — the same spelling the ratchet's locale
  lists and `--dart-define=LOCALE=`
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
the fonts these sweeps load live there: all five call `loadAppFonts()`, which
reads the ui_kit faces from the pub-cache checkout `pubspec.yaml` pins and the
Noto fallbacks from `test/fonts/`, both already covered. The Flutter SDK version
is the one input no stamp here can see.) The five baselines here all carry the
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
        'tab': tab, 'locale': tag,                     five sweeps name a cell, so
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

## 5. The five baselines, as captured

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

`forced_form` was then **re-captured at `d6fa9e27-dirty`** for #1344, and it is the
second case of a rewritten dataset that is not a measurement change: its six
`skeleton` rows gain the `|locale=en` they were always measured in, because
`runOverflowSweep` appends the locale to every cell id by construction and locale is
a field on the cell rather than an axis a family may respell. Same 75 cells, same
groups, same six columns; the other 69 rows are byte-identical, so the whole diff is
six renamed keys and the commit stamp. `popup` came through #1345 untouched — all
three of its sweeps already carried `locale` last — which is what says the port
measured the same 347 coordinates.

All four were then **re-captured at `25d1b8ed-dirty`** for the `dev-2.7.0` merge, which
is the third rewritten-dataset-that-is-not-a-port: `card` gains 26 `normal_band` cells
and `forced_form` 3 `compact_floor` cells, all of them #1325's production spec change
(`normalAbove` on `dhcp_reservations`) arriving through an unedited sweep. And `page`
was **captured at `69079cb0-dirty`** for #1349's pilot — a new sweep rather than a
re-capture, so it has nothing to diff against yet and its 416 rows are the claim
future ports check.

| Sweep | Suite | Cells | Overflows | Groups |
|---|---|---|---|---|
| `card` | `dashboard_card_overflow_test.dart` | 1,943 | 0 | `width` 1638 · `normal_band` 234 · `profile` 52 · `single_view` 12 · `tab_registry` 6 · `profile_data` 1 |
| `chrome` | `page_chrome_overflow_test.dart` | 1,248 | 0 | `header` 936 · `top_bar` 312 |
| `popup` | `dashboard_card_popup_overflow_test.dart` | 347 | 0 | `form` 234 · `picked_dialog` 51 · `dialog` 27 · `picked_value` 17 · `picked_height` 17 · `exempt` 1 |
| `forced_form` | `dashboard_card_forced_form_overflow_test.dart` | 78 | 0 | `popup_tile` 51 · `compact_floor` 21 · `skeleton` 6 |
| `page` | `page_surface_overflow_test.dart` | 416 | 0 | `dhcp` 208 · `wifi_settings` 208 |

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
map is an empty map under either shape, and all five baselines still `check`
identical. What is being frozen is the *coverage*: **4,032**
coordinates that are measured and clean today (3,587 at capture, 3,616 after the
merge, plus #1349's 416). Against an all-clean baseline the
only difference a port can produce is a lost cell, a new overflow, or a cell that
stopped finishing — which is exactly what R3 and R5 need to detect, and what a
pass/fail run cannot distinguish from success.

Two notes on these numbers:

- **Cells are not pumps.** §1.2 estimates "~1,468 pumps" in the chrome file against
  1,248 cells here. The difference is not uninstrumented coverage: every call that
  installs the overflow collector in all five sweeps names a cell (17 of 17, and
  the page sweep adds none — the runner installs it for every declared cell). The
  rest of that file's pumps are behaviour tests — menu selection, action
  reachability, the title staying whole — which never collect overflow and so have
  no measurement to record.
- **Only the five local sweeps are covered.** The golden side has no local
  baseline to capture at all: the default local matrix is one locale by two
  devices, it writes no `overflow_warnings.json`, and every coordinate that
  pipeline has found is locale-driven. That is #1346's problem, recorded in
  §8 of the architecture document.

## 6. Tests

| File | Covers |
|---|---|
| `test/util/overflow_baseline_test.dart` | cell id construction and sanitising, record shape, the tolerance verdict, a `testWidgets` that induces a real `Row` overflow and asserts the row it produces end to end, and a pump that throws — proving it is recorded and flagged rather than dropped or read as clean |
| `test/test_scripts/overflow_baseline_test.dart` | extraction, every refusal in §4, TSV rendering, parsing, and the diff's difference kinds, including a cell that became `error`. Also the §1 report: that its counts are recounted rather than quoted (a `# cells 9` header over one row is reported, not believed), that a rendered report is byte-identical on a re-render, that a group with no `locale` axis is disclosed as a denominator instead of averaged away, and that findings come out keyed like `known_overflows.json`. Two contract tests span the `flutter_test` / bare-`dart` boundary, where nothing can be imported: `overflowBaselineMarker == emitter.kOverflowBaselineMarker`, and a cell id built by the real emitter routed back to its group by the real extractor. Both would otherwise drift silently — as an empty dataset reading "no overflows anywhere", or as records filed under a baseline they do not belong to |
