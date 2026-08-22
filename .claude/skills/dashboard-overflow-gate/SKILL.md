---
name: dashboard-overflow-gate
description: Operate and maintain the `layout-gate`-tagged RenderFlex-overflow PR gate — run the #1183 card sweep, read its HTML/Markdown report, edit the known_overflows.json allowlist under the ratchet rules, onboard newly added/removed dashboard cards, and add a new overflow probe for a surface that is not a card (page chrome, dialogs). Use when a layout-gate test fails, when adding/removing a card or a locale, when reading/generating the overflow report, or when a newly found overflow needs a probe of its own. Trigger keywords (English) - overflow test, overflow gate, layout gate, RenderFlex, dashboard card test, known_overflows, allowlist, whitelist, overflow report, new dashboard card, data profile, dead exemption, new overflow probe, page chrome overflow, top bar overflow, header overflow. Trigger keywords (Chinese) - 跑版測試, 溢出測試, overflow 測試, dashboard card 測試, 白名單, 新增語系, 新增卡片, 刪除卡片, 溢出報告, 生成報告, 掃描 dashboard, 資料情境, 新增探測, 頁面外框溢出.
---

# Dashboard Overflow Gate — Operate & Maintain

## Purpose

The gate is a PR-blocking set of widget tests that catches layout overflows the
golden pipeline structurally misses (default-tab-only, fixed width,
not-every-card — the path the #1145 Network Health legend overflow slipped
through).

**The gate is not one test.** It is a family of independent suites that share
two things and nothing else: the tag `layout-gate` (which is what makes them
PR-blocking) and the measurement spine in
[test/layout_gate/](../../../test/layout_gate/), still imported through
[test/util/overflow_probe.dart](../../../test/util/overflow_probe.dart), which is
a re-export of it since #1340. **41 suites carry `layout-gate` today**, and most
of them are not overflow sweeps at all — they are density, readability, form and
gesture, layout-block, probe self-test, ratchet-oracle and render-parity gates. `layout-gate` (#1336) is the name of what
`dart_test.yaml` had been documenting all along: a PR-blocking defensive layout
gate.

**Four of the 41 additionally carry `overflow`**, the pre-commit selector.
`flutter test --tags overflow` runs these and nothing else:

| Sweep | What it pumps |
|---|---|
| `test/page/dashboard/cards/dashboard_card_overflow_test.dart` | every card × narrowest grid width per span × tab × 26 locales (#1183), declared through `runOverflowSweep` since #1343 |
| `test/page/dashboard/cards/dashboard_card_popup_overflow_test.dart` | the same cards pinned into the popup form (#1239), declared through `runOverflowSweep` since #1345 |
| `test/page/dashboard/cards/dashboard_card_forced_form_overflow_test.dart` | the boxes a #1299 user pick produces, which no drag could, declared through `runOverflowSweep` since #1344 |
| `test/page/shell/page_chrome_overflow_test.dart` | the top bar and dashboard header at screen width × locale (#1314/#1328), declared through `runOverflowSweep` since #1342 |

It is complete, not quick. `@Tags` is read by loading a suite, so the tag
compiles every test file in the repo (317 at #1345) to skip all but four:
measured 2026-08-22,
those same **273** tests take **1m53s under the tag and 19s when the four files are
named** (`flutter test`'s own clock; the shell sees 2m09s and 27s, the difference
being package resolution and build). Identical selection either way, so name the files for a tight inner loop
and use the tag when a fifth sweep must not be silently missed. **273 — 590 after
#1343, 2,412 before it**: all four sweeps now aggregate their locales inside one
test per coordinate, so 273 tests declare the same 3,587 cells (card 99, popup 80,
chrome 57, forced-form 37). The cells are what the gate measures; the test count is
only how they are named.

`overflow` means "pumps cells and asserts zero overflow" — not "everything a
verdict depends on", which would slide the tag back over the whole family. So
the probe self-tests
([overflow_probe_test.dart](../../../test/util/overflow_probe_test.dart),
[overflow_baseline_test.dart](../../../test/util/overflow_baseline_test.dart))
and the three framework oracles
([ratchet_test.dart](../../../test/layout_gate/ratchet_test.dart), #1341;
[sweep_test.dart](../../../test/layout_gate/sweep_test.dart), #1342;
[families/dashboard_card_gate_test.dart](../../../test/layout_gate/families/dashboard_card_gate_test.dart), #1343)
carry `layout-gate` only, deliberately, even though every sweep's verdict rests
on them. The split is checkable by arithmetic: `--tags overflow` measures exactly
what naming the four sweep files measures (273), so nothing has quietly joined
the pre-commit selector.

Two members are worth naming:

- **The #1183 card sweep** — `dashboard_card_overflow_test.dart`. Sweeps **every
  card × its narrowest grid width × every tab × all 26 shipped locales** and
  fails if any RenderFlex overflows beyond a baseline **allowlist** ("ratchet").
  **Data** is a fourth dimension, but an opt-in one: cards listed in
  `kCardDataProfileSweeps` are additionally swept against a second router shape —
  every other card's "clean" verdict is a verdict about the one default fixture.
  Everything below headed *card* describes this member only.
- **The #1314/#1328 page-chrome sweep** — `page_chrome_overflow_test.dart`.
  Sweeps **screen width × 26 locales** over the top bar and the dashboard header
  (× 3 action modes for the header). It exists because the card sweep is blind to
  page chrome *by construction*: it pumps one card at a computed card width and
  never renders a page at a screen width, so no page-level `Row` is in its view.
  **Since #1342 it is declared, not written**: two `runOverflowSweep(...)` calls
  against `ChromeTopBarFamily` / `ChromeHeaderFamily`
  ([test/layout_gate/families/page_chrome_family.dart](../../../test/layout_gate/families/page_chrome_family.dart)),
  so it now shares the whole measurement spine rather than just the probe — while
  still sharing no geometry, no report and no allowlist. What is left in the suite
  file is the seven readability tests, whose oracle is not "did a `RenderFlex`
  overflow".

This skill is for **operating and maintaining** that family: running a sweep,
reading its report, editing the allowlist correctly, keeping the card sweep
exhaustive when cards change — and adding a new probe for a surface that is not
a card (see [Adding a New Probe](#adding-a-new-probe-a-surface-that-is-not-a-card)).
What it is *not* for is rewriting the shared probe or the frozen grid formulas.

## When to Use

- A `layout-gate`-tagged test fails (locally or in CI / PR gate) and you must
  decide: real regression, new card, or a known overflow in a new locale.
- Adding or removing a card from the dashboard (`UspWidgetSpecs.all`).
- Adding/removing a tab on a tabbed card.
- Adding a new probe because an overflow was found on a surface no existing
  suite renders (page chrome, a dialog, a bottom sheet).
- Editing [test/fixtures/known_overflows.json](../../../test/fixtures/known_overflows.json)
  (allowlist / tracking notes).
- Generating or interpreting the HTML/Markdown overflow report.
- Shrinking the allowlist as part of #1183 follow-up (fixing the overflowing
  cards).

## When NOT to Use

- Writing golden/screenshot tests → use `golden-test-review`.
- Generic pre-PR checks → use `review-pr-readiness`.
- Rewriting the probe's grid-geometry **formulas** (column count, margin, slot
  width, card width) — those are intentionally frozen to mirror production;
  changing them silently changes what the gate measures. The *width-selection*
  step (`narrowestRealizationOf`) is separate and is not frozen, but it is
  covered by tests — see the enumeration invariant below.

## Step 0: Read the Implementation (BLOCKING PREREQUISITE)

Before editing anything, read these — they are the source of truth, and detail
below may drift:

1. Gate test — [test/page/dashboard/cards/dashboard_card_overflow_test.dart](../../../test/page/dashboard/cards/dashboard_card_overflow_test.dart).
   **Since #1343 it is a declaration, not a sweep**: three `runOverflowSweep`
   calls, the hand-written guards, and the two hooks. What each sweep *is* stays
   documented there; *which cells* and *what a verdict means* moved to
   [test/layout_gate/families/dashboard_card_family.dart](../../../test/layout_gate/families/dashboard_card_family.dart)
   (enumeration: `CardWidthFamily` 1,638 · `CardNormalBandFamily` 208 ·
   `CardProfileFamily` 52) and
   [test/layout_gate/families/dashboard_card_gate.dart](../../../test/layout_gate/families/dashboard_card_gate.dart)
   (the ratchet consult, the failure prose, the report row, the PNG pair, the
   coverage counters — read this one before editing a failure message). Its oracle
   is [test/layout_gate/families/dashboard_card_gate_test.dart](../../../test/layout_gate/families/dashboard_card_gate_test.dart),
   which is where a fixture edit's *effect* is cheapest to see — the sweep is green
   on real data, so none of the interesting branches run there.
2. Allowlist fixture — [test/fixtures/known_overflows.json](../../../test/fixtures/known_overflows.json)
   and the module that reads it —
   [test/layout_gate/ratchet.dart](../../../test/layout_gate/ratchet.dart)
   (`OverflowRatchet`: key shape, dead-entry rules, why a null site is never
   exempt). Its oracle is
   [test/layout_gate/ratchet_test.dart](../../../test/layout_gate/ratchet_test.dart)
   — the fastest way to see what a fixture edit does is to add a case there.
3. Runner — [tool/run_overflow_test.sh](../../../tool/run_overflow_test.sh)
4. Probe + grid math + tab registry — [test/util/dashboard/dashboard_card_probe.dart](../../../test/util/dashboard/dashboard_card_probe.dart)
5. Data profiles + per-card sweep list — [test/util/dashboard/card_data_profiles.dart](../../../test/util/dashboard/card_data_profiles.dart)
6. Report generator (Status SSoT) — [test/util/dashboard/dashboard_overflow_report_generator.dart](../../../test/util/dashboard/dashboard_overflow_report_generator.dart)
7. Width-selection tests — [test/util/dashboard/dashboard_card_probe_test.dart](../../../test/util/dashboard/dashboard_card_probe_test.dart)

## Architecture — Data Flow (the card sweep)

Everything in this diagram except the `test/layout_gate/` boxes belongs to the
card sweep alone. Another member of the gate reuses the box in the middle and
nothing above or below it.

```
UspWidgetSpecs.all ──┐  (card registry: id + min/pref/max column span)
UspWidgetFactory   ──┤→ dashboard_card_probe.dart
cardTabIndexProvider ┘     • widthCasesFor(spec): narrowest real grid px per span
                           •   (enumerated over 320px..2560px, not sampled)
                           • buildDashboardCardApp(): pumps ONE card at real
                             screen/card width, pinned tab, locale, real fonts
                           • kTabbedCardTabCounts: tabs to sweep per card
                                    │
card_data_profiles.dart ────────────┤  (#1267: the router shape the card is fed)
  • the default profile is kitchenSinkOverrides() — one fixed router
  • kCardDataProfileSweeps: per-card OPT-IN list of extra (card, tabs, profile)
    triples, each pumped through the same width × locale sweep
                                    │
                                    ▼
                    layout_gate/collector.dart  (runWithOverflowCollection,
                                                 via overflow_probe.dart)
                    hooks FlutterError.onError → collects "overflowed by Npx"
                    as OverflowIncident, forwards real errors so they still fail
                    · layout_gate/surface.dart sets the viewport and restores it
                                    │
                                    ▼
    layout_gate/sweep.dart  runOverflowSweep(CardWidthFamily(gate)) × 3
      • since #1343: ONE testWidgets per card×width×tab, looping all 26 locales
        inside it, plus one `cell count` test per family pinning 1638/208/52
      • families/dashboard_card_family.dart enumerates the cells
      • families/dashboard_card_gate.dart judges them — everything below is its
        judgeCell/close, shared by all three card families
          overflow > 2px tolerance?  →  layout_gate/ratchet.dart consultCell()
            ├─ EVERY incident's file:line allowlisted for this locale
            │    → print "KNOWN OVERFLOW (allowlisted)" + its tracking note, PASS
            └─ any incident not allowlisted → FAIL, naming that file:line as the
                                              key to add
                                    │
                      tearDownAll → CardSweepGate.close()
                                     → ratchet.deadEntryFailure()
            └─ an entry, or one of its locale tags, that nothing overflowed at all
               run  → FAIL "dead exemption" / "over-broad exemption". Taken ONCE
               for the whole run, and skipped entirely when the run was filtered
               (-c / -L / -m), because a subset cannot tell "fixed" from
               "not measured"
                                    │
                    (only when DUMP > 0) tearDownAll →
                                    ▼
        dashboard_overflow_report_generator.dart → build/overflow_testing/
          overflow_report.md, overflow_report.html, png/…, png/adjust/…
```

Key invariants (do not "fix" these):

- **One fresh tree per measurement.** Flutter reports each RenderFlex's overflow
  only once per render-object lifetime; multi-pump sweeps silently drop all but the
  first. Until #1343 that was enforced by giving every `(card, width, tab, locale)`
  its own `testWidgets`. It is now enforced by `runOverflowSweep`, which wraps each
  cell host in `KeyedSubtree(key: ValueKey(cellId))` — a new subtree, so new render
  objects, so a fresh report — which is what lets one test loop 26 locales. The
  invariant did not relax; only the mechanism changed. **A tree pumped outside the
  runner still needs its own test or its own key.**
- **Narrowest realization = worst case.** Overflow is monotonic in width and
  height is measured, so testing each span's narrowest grid width is exhaustive
  (~5× fewer tests, identical coverage). Grid geometry is mirrored from
  `UspSliverDashboardView` + ui_kit `AppLayoutConfig`.
- **Narrowest is enumerated, not sampled** (#1225). `narrowestRealizationOf()`
  walks every screen width from `kMinSupportedScreenWidth` (320px — a *product*
  commitment, see density design §2.3) to `kMaxScannedScreenWidth`, so the
  worst-case claim above holds by construction. Do not reintroduce a scan list:
  the retired 19-width sample was lossy under `MIN_SCREEN` (a floor of 602px
  reported a 3-column card 6.5px wider than reality). Lowering the 320px floor
  **moves the baseline** and requires a deliberate re-baseline.
  Covered by [dashboard_card_probe_test.dart](../../../test/util/dashboard/dashboard_card_probe_test.dart).
- **Tag must stay `layout-gate` (plus `overflow` on this file).** `run_tests.sh`
  excludes `golden||loc||ui`; neither of those two is excluded, so both run in
  the PR gate. Retagging golden/loc/ui silently drops the suite from the gate,
  and dropping `overflow` silently removes it from the pre-commit selector.
- **`2.0px` tolerance** absorbs mac↔CI sub-pixel shaping; real clipping is many px.

## Quick Execution — `tool/run_overflow_test.sh`

Always run via `fvm flutter` (the script does). Output dir: `build/overflow_testing/`.

| Flag | Meaning | Default |
|------|---------|---------|
| `-l`, `--list` | List every registered card ID + column spans + tab count (from `UspWidgetSpecs.all`); runs nothing else | off |
| `-d`, `--dump MODE` | `0`=no output (clean PR-gate mode) · `1`=Markdown · `2`=HTML + PNG · `3`=MD+HTML+PNG | `2` |
| `-m`, `--min-screen PX` | Raise the enumerated range's floor to PX, so each span's narrowest width is the narrowest at or above PX (narrower screens are skipped, not the widths themselves) | `0` = no filter (the 320px product floor still applies) |
| `-c`, `--card CARD_ID` | Target one card (passed as `--name`, matches the card's test group) | all |
| `-L`, `--locale LOCALES` | Comma-separated locale tags, e.g. `ru` or `ru,zh_TW` | all 26 |
| `-o`, `--open` | Open the HTML report in the browser when done | off |
| `-h`, `--help` | Usage | — |

```bash
# See what cards exist (and their tab counts)
./tool/run_overflow_test.sh -l

# Fast, targeted debug: one card, one locale, auto-open the visual report
./tool/run_overflow_test.sh -c network_health -L ru -o

# Full sweep with HTML report + before/after PNGs
./tool/run_overflow_test.sh

# What the PR gate actually runs (no dump, just pass/fail):
fvm flutter test test/page/dashboard/cards/dashboard_card_overflow_test.dart
# all four sweeps, the pre-commit run:  fvm flutter test --tags overflow
# or the whole gate set:  ./run_tests.sh   (layout-gate is NOT excluded)
```

Raw `flutter test` knobs (the script wraps these as `--dart-define`):
`DUMP=<0..3>`, `MIN_SCREEN=<px>`, `LOCALE=<tags>`, `LIST_CARDS=true`.

### Before and after a refactor — `tool/overflow_baseline.sh`

`run_overflow_test.sh` answers "is the gate green". It cannot answer "does the
gate still measure the same 3,587 coordinates", and a refactor that stops
enumerating a coordinate is green for exactly that reason. So when you are about
to restructure a sweep rather than fix a card:

```bash
./tool/overflow_baseline.sh capture          # freeze today's coverage, all four sweeps
# … refactor …
./tool/overflow_baseline.sh check chrome     # exit 0 = identical, 1 = read the diff
```

The dataset records a **clean cell as a row**, so a dropped coordinate appears as
`no longer measured` instead of as a card that got fixed — and a cell whose pump
died reads as `error`, not as one that fits. Read the diff before re-capturing — a
re-capture is how lost coverage becomes permanent. Full mechanism, and the four
committed baselines, in
[doc/testing/overflow_baselines.md](../../../doc/testing/overflow_baselines.md).

## Fixture Format — `known_overflows.json`

**Keys are the overflowing widget's source location, `file:line` — not a
coordinate.** #1341 re-keyed it: a `card|width|tab` key invalidated wholesale the
moment a layout was rearranged, while a source location survives the
rearrangement and is the join column between this gate's verdicts and golden CI's
advisory findings (architecture doc §3.5, §8).

```jsonc
{
  "tracking": {
    // same file:line keys as below — one note per SITE, not per card
    "lib/page/dashboard/views/components/usp_network_health_card.dart:424":
        "legend fix #1145/#1174",
  },
  "allowlist": {
    // key = "<repo-relative file>:<line>"  →  set of overflowing locale tags
    "lib/page/dashboard/views/components/usp_network_health_card.dart:424":
        ["de", "fi", "pl"],                        // text-length dependent
    "ui_kit_library/lib/src/widgets/app_chip.dart:63": ["*"]
                                                   // "*" = structural: overflows
                                                   //   in EVERY locale (text-length
                                                   //   independent)
  }
}
```

Key grammar — `<file>:<line>`:

- The exact string the failure message already prints. Every incident renders as
  `+41.0px right at lib/page/…/x.dart:424` (`OverflowIncident.toString`), so the
  key is the part after `at` — copy it, do not reconstruct it.
- `file` is repo-relative and forward-slashed. A widget built inside a git
  dependency collapses to `<package>/<path>` (e.g.
  `ui_kit_library/lib/src/…`), so pub-cache paths and commit SHAs never reach the
  fixture. `line` is 1-based and must be > 0.
- **A pre-#1341 coordinate key is rejected, loudly.** `OverflowRatchet` throws on
  any key containing `|` or `@` (and on a bare card id in `tracking`), because a
  key that matches no site would otherwise read as "not allowlisted" everywhere
  and the stale entry would be invisible in both directions. Re-derive keys from a
  full sweep's failure messages; there is no mechanical translation from the old
  shape, since one coordinate can hold several sites and one site appears at many
  coordinates.
- **The key has no width, tab or profile axis.** An exemption therefore covers
  that source location *wherever* it overflows — every width, every tab, the
  data-profile sweeps and the normal-band sweep included. That is coarser than the
  old key on purpose; if a profile-only exemption is ever needed, narrow the key
  shape in `ratchet.dart` rather than adding a second fixture.
- **An incident whose location did not resolve can never be exempted** — a null
  site is not a key, and `"*"` on every entry still will not cover it. Deliberate,
  and the safe direction.
- Value — a JSON array of **locale tags** (`_localeTag` format: `en`, `de`,
  `es_AR`, `fr_CA`, `pt_PT`, `zh_TW`, …), OR `["*"]` meaning "overflows in all
  locales regardless of text". A hit is tolerated if the set contains the locale
  **or** contains `"*"`. An empty array, a non-string tag, `"*"` mixed with
  explicit tags, and an unknown top-level key are all parse errors — the loader
  fails the run once as `(setUpAll)` instead of printing a warning nobody reads
  inside a 1,900-test run (99 tests since #1343, and the argument is unchanged: a
  warning is not a verdict).

## The Ratchet — How the Gate Reacts to Edits

The allowlist only *tolerates* the exact baseline. Every direction fails:

- **New overflow** — a `file:line` not listed, or a listed site seen in a **new
  locale** → the test FAILS. This is the point: regressions block the PR. A cell is
  tolerated only when **every** incident in it is exempt; one known site plus one
  new site still fails, and the message quotes the new one.
- **Premature removal** — deleting a locale that still overflows fails exactly
  that test (proven both ways in #1183). You cannot shrink the list by editing
  JSON alone; you must fix the layout first.
- **Dead exemption** — an entry (or one of its locale tags) that nothing overflowed
  at during the run FAILS, with "remove it". Before this, a fixed overflow kept its
  exemption silently, and a stale entry was indistinguishable from tracked debt —
  which is how 46 of them came to be retired by hand. Fixing a card therefore
  includes editing the fixture in the same change.
- **Over-broad `"*"`** — a `"*"` entry seen in fewer locales than the run covered
  FAILS too: `"*"` claims the overflow is structural, so a locale it never appeared
  in disproves it. Replace it with the explicit tags the message lists.

Two things about that closing direction, both consequences of the key:

- **It is judged once, in `tearDownAll`, over the whole run** — not per cell. One
  source location can be rendered by many cards, so a single clean cell proves
  nothing about the site. The cost: the failure names the site and the locales, and
  no longer names the exact coordinate that came clean. Get that from
  `./tool/run_overflow_test.sh -c <card> -d 2`.
- **A filtered run does not judge it at all.** `-c` / `-L` / `-m` (and
  `--dart-define=LOCALE` / `MIN_SCREEN`) each mean the run measured a subset, and a
  subset cannot distinguish "fixed" from "not measured". The suite prints
  `⚠️ … dead-entry detection skipped` and leaves the verdict to the full gate. So
  **a green `-c <card>` run is not evidence that an entry is still needed.**

The gate's own failure message tells the operator exactly what to do:

> Fix the layout (Flexible/Expanded/maxLines/ellipsis), or if this is knowingly
> deferred, add "`<locale>`" to the `'lib/page/…/x.dart:424'` entry of the
> "allowlist" map in `test/fixtures/known_overflows.json`, along with a "tracking"
> note under the same key.

## Playbooks

### A. A `layout-gate` test failed — triage

1. Read the failure: it names `card`, `width` (`min`/`preferred`/`max`), `tab`,
   `locale`, the overflow (`+Npx right/bottom`) **and the source location the
   overflow happened at** (`at lib/page/…/x.dart:424`). That last part is the
   allowlist key and usually the fastest route to the culprit widget — go read that
   line before anything else.
   **Since #1343 the locale is inside the message, not in the test name.** The test
   reads `card.width card=<id> width=<label> px=<n> tab=<n> lays out cleanly in
   every locale`, and its failure opens with
   `card.width overflowed at <coordinate> in 3 locale(s):` followed by one
   `<tag>: …` line each.
   Read that count first — one locale is a translation-length problem, twenty is
   structural, and the old shape (one red test per locale) made the difference
   something you had to assemble by hand from the report.
2. Reproduce + visualize:
   `./tool/run_overflow_test.sh -c <card> -L <locale> -o`
3. Decide, in this order:
   - **Real regression** (a fix or new feature made an existing-clean case
     overflow) → **fix the layout**, don't allowlist. Re-run until green.
   - **Genuinely new card** → see Playbook C.
   - **Known overflow surfacing in a new locale** (an entry exists for that
     `file:line` but not this locale) → if the deferral is legitimate and
     tracked, add the locale tag to that entry's array. Prefer fixing.
   - **"Dead exemption" / "Over-broad exemption"** → the opposite failure, and it
     arrives from `(tearDownAll)` rather than from a named test: nothing in the run
     overflowed at a site the fixture still exempts. Do what the message says —
     drop that locale tag (and the entry plus its `tracking` note once the list
     empties), or narrow a `"*"` to the tags it lists. Nothing to fix in the
     layout; this is the ratchet closing. Only a **full** sweep raises it (see
     above), so do not go looking for it in a `-c` run.
   - **A `[<profile>]` in the failure name** → the case comes from
     `kCardDataProfileSweeps`, so the *data*, not the width, is what breaks it.
     The message says so explicitly. Note that allowlisting it exempts that same
     `file:line` on the default data too — the key carries no profile.
4. Never retag the test or delete it to make CI pass.

### B. Edit the allowlist (defer a known overflow)

1. Confirm it's genuinely deferred (has, or needs, a tracking issue), not a
   regression you should fix now.
2. Copy the `file:line` out of the failure message (the part after `at`) and add
   the locale tag to that key's array in `known_overflows.json` (create the entry
   if absent). Use `"*"` only when it overflows in **every** locale (structural) —
   a full run fails a `"*"` that appeared in fewer locales than it covered, so
   guessing costs a red run.
3. Add/update a `tracking` note **under the same `file:line` key** so the
   allowlisted hit prints a pointer. A note keyed on a card id is a parse error.
4. Re-run the affected slice to confirm green:
   `./tool/run_overflow_test.sh -c <card>`. That proves the exemption works; it
   does **not** exercise dead-entry detection, which only a full sweep does.

### C. Onboard a NEW dashboard card

New cards in `UspWidgetSpecs.all` are picked up automatically — but:

1. Every `UspWidgetSpecs.all` id must map to a widget in `UspWidgetFactory`
   (the probe throws `StateError` otherwise).
2. If the card is **tabbed**, add it to `kTabbedCardTabCounts` in
   [dashboard_card_probe.dart](../../../test/util/dashboard/dashboard_card_probe.dart)
   with its tab count. The `tab registry` meta-test enforces this from both
   sides — `<card> still has N tabs` for a registered card, and `<card> is
   single-view, so tab 0 is full coverage` for an unregistered one — so a tabbed
   card left out of the registry fails rather than being swept at tab 0 only.
3. Decide whether the card's tree depends on the **router shape** (radio count,
   band count, port count, client count). If it does, the default profile is one
   router and the sweep says nothing about the others: add a
   `CardDataProfileSweep` to `kCardDataProfileSweeps` in
   [card_data_profiles.dart](../../../test/util/dashboard/card_data_profiles.dart),
   naming only the tabs that actually render the varying data. That file's doc
   states the opt-in cost plainly — a card is uncovered on the second profile
   until someone adds it — so record the decision either way.
4. **Update the pinned cell counts** — `expectedCellCount:` on each affected
   `runOverflowSweep` call. Since #1344/#1345 that is **three files, not one**, and
   a new card can touch all eight sweeps:
   - [dashboard_card_overflow_test.dart](../../../test/page/dashboard/cards/dashboard_card_overflow_test.dart)
     — `spans × tabs × 26` to `CardWidthFamily`, another `tabs × 26` to
     `CardNormalBandFamily` if it declares a `normalAbove`, and `tabs × widths × 26`
     to `CardProfileFamily` if you added it to `kCardDataProfileSweeps` in step 3.
   - [dashboard_card_popup_overflow_test.dart](../../../test/page/dashboard/cards/dashboard_card_popup_overflow_test.dart)
     — `+26` to `popup.form` and `+3` to `popup.dialog` if the grid can put the card
     under `kPopupBelow` (a `minColumns` of 3), and `+3` to `popup.picked_dialog`
     unless the card is in `cardsWithoutPopupForm`. That file's
     `what this file sweeps` group pins both inventories, so it fails first and
     names which of the two the card joined.
   - [dashboard_card_forced_form_overflow_test.dart](../../../test/page/dashboard/cards/dashboard_card_forced_form_overflow_test.dart)
     — `+3` to `forced_form.popup_tile` and `+3` to `forced_form.compact_floor`, per
     form the card offers in `selectableForms`. `forced_form.skeleton` is fixed at 6:
     it sweeps skeleton *variants*, not cards.

   This is not optional bookkeeping and it is not derived on purpose: since #1343
   the count is the *only* thing standing between "regrouped 1,898 cells into 73
   tests" and "quietly stopped enumerating 800 of them", so a computed pin would be
   the enumeration restating itself. The failure names both numbers, so the run
   tells you what to write.
5. Run the card's full sweep: `./tool/run_overflow_test.sh -c <new_card> -o`.
   **Then run the file unfiltered once** — `-c` narrows the run, so the count tests
   skip rather than pass (they say so, with both numbers), and a wrong pin from step
   4 stays invisible until CI.
6. Fix any overflow you reasonably can; allowlist the rest per Playbook B with a
   tracking note. Goal is 0 new allowlist entries.

### D. Removing a card / tab

- Removing a card from `UspWidgetSpecs.all` → delete any `known_overflows.json`
  entry whose `file:line` lives in **that card's own files**, plus its `tracking`
  note, and any `kCardDataProfileSweeps` entry naming it. Keys no longer carry the
  card id, so this is a judgement call, not a grep for the name: a site in
  `ui_kit_library` or in a shared row widget may still be reached by another card.
  Delete the card, run the **full** sweep, and let the dead-entry check name what
  actually died.
- Changing a card's tab count → update `kTabbedCardTabCounts`; the meta-test
  enforces it. Run the full sweep afterwards: a tab that stopped being swept can
  leave an entry dead, and only that run will say so.
- **Either change moves the pinned `expectedCellCount`s** (Playbook C step 4), in
  the other direction. Removing a card or a tab shrinks the enumeration, and the
  count test fails with both numbers in it — that failure is the feature, not an
  obstacle: it is what makes lost coverage impossible to confuse with an intended
  deletion.

### E. Shrink the allowlist (#1183 follow-up)

For each entry: fix the layout at that `file:line` so it no longer overflows, then
**remove** the locales it was listed for (or the whole entry, plus its `tracking`
note). The ratchet confirms the removal is real from both sides: a premature
removal fails the exact test that still overflows — `-c <card>` shows that — and a
fix you forget to record fails as a dead exemption, which needs the **full** sweep
(`fvm flutter test test/page/dashboard/cards/dashboard_card_overflow_test.dart`).
Run both before claiming an entry is retired. This is the intended long-term
direction; the baseline is debt, not a target to grow.

## Adding a New Probe (a surface that is not a card)

You need a new probe when an overflow is found on a surface **no existing suite
renders**. That was the case for #1314/#1328: the card sweep pumps a card at a
card width, so page chrome could overflow at 601–767px in 26 locales with the
whole gate green. Adding a probe means a **new suite**, not a new dimension on an
existing one.

Reference implementation:
[test/page/shell/page_chrome_overflow_test.dart](../../../test/page/shell/page_chrome_overflow_test.dart).

### The seven rules

1. **The shared assets are the `overflow_probe.dart` import path and
   `test/layout_gate/`.** `collectOverflow` / `OverflowIncident` /
   `kOverflowTolerancePx` were extracted in #1270 for exactly this. Since #1338 the
   parser half — `OverflowIncident`, `kOverflowTolerancePx`, `isOverflowError` —
   lives in
   [test/layout_gate/incident.dart](../../../test/layout_gate/incident.dart), and
   since #1340 the collector half (`runWithOverflowCollection`, `collectOverflow`,
   `settleIgnoringAnimations`) lives in
   [test/layout_gate/collector.dart](../../../test/layout_gate/collector.dart)
   beside the new surface primitive `setLayoutSurface`
   ([surface.dart](../../../test/layout_gate/surface.dart)), which is now the only
   place any suite in the family may set the test viewport — it registers the
   restore itself, so hand-writing `setSurfaceSize` + `physicalSize` +
   `devicePixelRatio` in a new sweep is a review comment. `overflow_probe.dart`
   re-exports all three files, so importing the probe path is still correct and
   no importer changed. Since #1341 the allowlist is a module too —
   [test/layout_gate/ratchet.dart](../../../test/layout_gate/ratchet.dart) — keyed
   on `file:line` and therefore usable by any suite, card-shaped or not: a new
   probe that ever needs grandfathering constructs an `OverflowRatchet` instead of
   copying ~80 lines of allowlist logic (see rule 3 — it should not need one).
   And since #1342 the sweep itself is shared —
   [sweep.dart](../../../test/layout_gate/sweep.dart) declares the tests and
   [families/](../../../test/layout_gate/families/) is where a new surface's axes
   and hosts go, next to the existing ones (see rule 5).
   Everything else in the card sweep has **one** user: the grid geometry in
   `dashboard_card_probe.dart` and the report generator each serve that one suite.
   Do not stretch the card-shaped model over a non-card surface —
   `OverflowReportItem` *requires* `cardId`/`columnSpan`/`rowSpan`/`recCols`/
   `recRows`, and its whole `OverflowStatus` vocabulary asks "can this card get a
   wider span?". Page chrome has no span, so the answer is not "false", it is "the
   question does not apply".
2. **Each suite chooses its own assertion axes.** The card sweep's axis is span
   (× tab × locale × data profile); page chrome's is screen width × locale; a
   dialog's would likely be content length × locale. Pick the axes the bug
   actually lives on. #1328's failure band was 601–767px — sweeping `en` alone
   would have reported a 167px-wide defect as a 39px corner case, because `pl`
   needs 128px more than `en` does. **Locale is a first-class axis, not a
   variation.**
3. **Fix first, then gate. Do not open a second ratchet.** Every satellite suite
   added since #1183 starts from zero tolerance; `known_overflows.json` is #1183's
   historical debt, not a pattern to copy. Land the layout fix and the suite in
   one PR so the suite is green the moment it arrives — the intermediate state of
   a fix-then-gate split is a deliberately red test.
4. **Every overflow assertion needs a readability assertion beside it, and there
   are two verdicts, not one.** A suite that only checks overflow can be fully
   green while the text is unreadable (project memory *"Overflow Gate: Green but
   Unreadable"*: 4 cards pass at 191px rendering nonsense). Both of these live in
   [test/util/dashboard/text_readability_probe.dart](../../../test/util/dashboard/text_readability_probe.dart):
   - `isTextClipped` — did the paragraph exceed `maxLines` (i.e. ellipsize)?
   - `hasSplitToken` — is the widest single word wider than the box?

   **Neither subsumes the other.** `isTextClipped` is blind to a mid-word break,
   because when Flutter breaks an unbreakable word across a line nothing is
   dropped and `didExceedMaxLines` stays `false`. `hasSplitToken` is blind to an
   ellipsis, because the tokens that survive all fit. #1314 proved it twice on the
   same string: `sv` "Instrumentpanel" overran its 188px box by 3.6px, rendered as
   "Instrumentpane / l", and the suite went **31/31 green** — `hasSplitToken` is
   what turned it red again. Assert both, in that order.
5. **Declare the sweep through the runner; do not hand-write the loop.** Since
   #1342, `runOverflowSweep(family: …, expectedCellCount: …)`
   ([test/layout_gate/sweep.dart](../../../test/layout_gate/sweep.dart)) owns the
   surface, the fresh subtree, the settle, the tolerance filter, the per-cell
   exception isolation and the aggregated failure. A new probe writes an
   `OverflowSurfaceFamily` — which coordinates exist, and how one becomes a host
   widget — and nothing else.

   The rule this replaces was **"one pump per cell: give each pump a unique
   `ValueKey`"**, and the reason it existed still holds: Flutter reports each
   `RenderFlex`'s overflow once per render-object lifetime, so a loop that
   re-pumps inside one `testWidgets` silently drops every incident after the
   first. The runner now keys every cell host on the cell's own id, so that trap
   is disarmed for you — but a suite that pumps trees *outside* the runner (a
   readability test of its own, like the chrome suite's seven) still has to key
   them by hand.

   One place in the gate pumps unkeyed on purpose: `captureAdjustedCardScreenshot`,
   called from the card gate's judge, re-pumps the same card at its recommended size
   to photograph it. It is safe because it is measuring a *different* tree — a
   different root widget, so different render objects — and it only ever runs on a
   `DUMP=2` run for a cell that already overflowed. If you copy it, keep both of
   those properties or key it.

   Two consequences of the runner worth knowing before you write a family:
   `expectedCellCount` is **required** — pin it as a literal from the ticket, not
   as `widths.length * locales.length`, which is the enumeration restating itself
   — and locale is a **field on the cell, not an axis**, because the runner groups
   by every axis except locale and loops locale inside one test. Declaring
   `locale` in `axisNames` is reported as a malformed family.

   **Two hooks are defaulted, and a new probe should leave both alone until it
   can't** (#1343 added them, and only because the card sweep needed them):

   - `judgeCell(tester, cell, verdict)` — the verdict for one measured cell, called
     for **every** cell including clean ones. The default is zero tolerance: any
     incident above the filter is that cell's failure. Override it only if your
     surface has something the runner cannot know about — the card gate's override
     is the allowlist, the report row and the PNG pair, all in
     `families/dashboard_card_gate.dart`. **One hook, not three**, on purpose: the
     consult, the report row and the dump all happen at one moment over the same
     inputs, so splitting them would be three hooks that must agree.
   - `enumerationGaps()` — why this run enumerated fewer cells than the sweep pins,
     empty by default. Non-empty makes the count test *skip with the reason in it*
     rather than fail — **unless the narrowing enumerated nothing at all**, which
     fails: a gap explains measuring less than the pin, never measuring nothing, and
     `LOCALE=zz` would otherwise leave every pin skipped and the sweep green over
     zero cells. You need this only if your family reads a `--dart-define` that
     narrows the enumeration; a family whose cells are fixed does not.

   The three card families share a private `_CardFamily` base
   ([families/dashboard_card_family.dart](../../../test/layout_gate/families/dashboard_card_family.dart))
   that holds the gate, the cached enumeration and that `enumerationGaps` delegate,
   and narrows both hooks to `CardSweepCell` so the cast is paid once. Copy that
   shape if you write a second family for one surface; it is what stops a later
   family from forgetting the delegate and pinning a subset as the whole sweep.
6. **`@Tags(['layout-gate'])` — never `loc` / `ui` / `golden`.** `run_tests.sh`
   only does `--exclude-tags="golden||loc||ui"`; nothing in `.github/` names
   `layout-gate`. So "is it in the PR gate?" means "is it un-excluded?", and the
   honest-looking retag to `loc` is how a suite leaves the gate in silence. Add
   `overflow` as a second tag — `@Tags(['layout-gate', 'overflow'])` — only if
   the new suite pumps cells and asserts zero overflow, since that tag is the
   pre-commit selector and has to stay fast; a readability or density probe takes
   `layout-gate` alone.
7. **`loadAppFonts()` in `setUpAll`, from
   [test/util/app_test_fonts.dart](../../../test/util/app_test_fonts.dart)** (not
   from `golden_toolkit`). Under Ahem every glyph is an identical box and every
   width you measure is fiction.

### Report the numbers, not the verdict

A failure message that says "title clipped" sends the reader back to the
debugger. One that says

> `sv [viewing, local]: title broken mid-word — granted 188.0px, widest token 191.6px, whole string 191.6px — "Instrumentpanel"`

is already the decision: 3.6px, so it is a type-size or a wording call. Print the
box width, the widest token and the whole-string intrinsic width.

### Host scaffolding traps (all three cost real debugging time)

- **A `ModalBarrier` in your host erases your semantics.** `MaterialPageRoute`
  ships one, and a modal barrier is a `BlockSemantics` — it drops the semantics of
  everything painted before it in the same parent. In the #1328 host that was the
  entire top bar, so every `nav-*` identifier read as absent at *every* width.
  `find.bySemanticsIdentifier` resolves through `renderObject.debugSemantics`, so
  a blocked node is indistinguishable from a missing widget: zero matches, no
  explanation. Wrap a placeholder `Navigator` in `ExcludeSemantics`. Confirm the
  production tree does not have the same blocker before "fixing" anything in
  `lib/`.
- **`ProviderScope`'s override list length must not change between pumps**
  (`_debugOverridesLength == overrides.length`). Never build overrides with
  `if (loggedIn) …`; always emit the override and swap the *value*. Violating it
  made a logged-in assertion read `false` at 1024px and invalidated a whole batch.
- **Some widgets need a real `GoRouter` ancestor**, not just `MaterialApp` —
  `MenuHolder.didChangeDependencies` calls `GoRouter.of(context)`.

## Report Interpretation (`-d 2`/`3`)

`build/overflow_testing/overflow_report.html` groups rows by card and, per row,
shows current size, locale, overflow px, and a **Status** with before/after PNGs
(`png/<card>/…` original vs `png/adjust/<card>/…` re-pumped at the recommended
grid size). Status is the SSoT `OverflowStatus` enum:

| Status | Meaning | Implication |
|--------|---------|-------------|
| 🟢 **Grid Expand** | Clean once the card spans more columns/rows | Layout is fine; the card just needs a bigger grid footprint |
| ⚠️ **Screen Limit** | Already at the max columns the screen allows; can't widen | Needs an internal layout refactor (wrap/ellipsis/Flexible), not more grid |
| ⚠️ **Internal Overflow** | Still overflows even at the recommended larger size | Real internal layout bug — fix content, not the container |
| **Grid Size OK** | No meaningful overflow after adjustment | Informational |

Markdown report (`-d 1`) is the same data as a flat bulleted list —
`card (screen px | card px | span | tab | locale): +Npx side ⇒ <Status>`.

## Common Mistakes

| Mistake | Correct approach |
|---------|------------------|
| Allowlisting a real regression to get CI green | Fix the layout; the allowlist is for tracked, deferred debt only |
| Using `"*"` after seeing overflow in a few locales | `"*"` means *every* locale — verify with a full-locale sweep first; a full run fails a `"*"` that showed up in fewer locales than it covered, and lists the ones it saw |
| Fixing a card's layout and leaving its allowlist entry behind | The next **full** sweep fails in `(tearDownAll)` as a "dead exemption" — remove the tag in the same change. A green `-c <card>` run will not tell you |
| Writing an allowlist key as `card\|width\|tab` (the pre-#1341 shape) | Keys are the overflow's `file:line`. The loader rejects anything that is not `<path>.dart:<line>`, so the run fails at `(setUpAll)` — copy the location out of the failure message instead. A `\|` in the key also gets named as the old coordinate shape; `@` does not, since it is legal in a path |
| Expecting an exemption to apply to one width, tab or data profile only | A `file:line` key has none of those axes: it exempts that source location everywhere it overflows. Fix the layout if the exemption would be too broad |
| Assuming a clean sweep covers every router | Data is a swept dimension only for cards opted into `kCardDataProfileSweeps`; otherwise "clean" means clean *on the default fixture* |
| Wrong locale tag (`zh-TW`, `es-AR`) | Use `_localeTag` form with underscore: `zh_TW`, `es_AR`, `fr_CA`, `pt_PT` |
| New tabbed card, but only tab 0 gets tested | Add it to `kTabbedCardTabCounts`; the `tab registry` meta-test enforces both directions, so an unregistered tabbed card fails instead of quietly under-sweeping |
| Retagging the test golden/loc/ui to "organize" it | It would drop out of the PR gate — keep it `layout-gate` |
| Multi-pumping to sweep widths/tabs in one test | Either declare it through `runOverflowSweep` (which keys each cell host for you) or give each pump its own `testWidgets` — only the first overflow is reported per render object |
| Editing the grid constants to change results | They mirror production geometry on purpose; changing them changes what "overflow" means |
| Removing an allowlist locale without fixing layout | The ratchet fails that exact test — fix the card first, then remove |
| Replacing the width enumeration with a "faster" sampled list | Sampling makes the worst-case invariant an assertion again, and is lossy under `MIN_SCREEN`; enumeration is pure arithmetic and costs nothing next to the pumps |
| Lowering `kMinSupportedScreenWidth` to "test more" | It is a product commitment (§2.3), and lowering it adds overflow coordinates — re-baseline deliberately, with the shift explained |
| Taking a green sweep as proof a refactor preserved coverage | Green also means "measured less". `./tool/overflow_baseline.sh check` compares the coordinates themselves |
| Capturing a baseline with `--file-reporter json:<file>` | Its sink interleaves writes and leaves 16KB NUL holes; the run still reports success while cells silently vanish. Use `--reporter json > file` — `tool/overflow_baseline.sh` does |
```
