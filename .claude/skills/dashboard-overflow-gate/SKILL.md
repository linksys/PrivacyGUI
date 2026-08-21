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
PR-blocking) and the probe in
[test/util/overflow_probe.dart](../../../test/util/overflow_probe.dart). **38
suites carry `layout-gate` today**, and most of them are not overflow sweeps at
all — they are density, readability, form and gesture, layout-block, probe
self-test and render-parity gates. `layout-gate` (#1336) is the name of what
`dart_test.yaml` had been documenting all along: a PR-blocking defensive layout
gate.

**Four of the 38 additionally carry `overflow`**, the pre-commit selector.
`flutter test --tags overflow` runs these and nothing else:

| Sweep | What it pumps |
|---|---|
| `test/page/dashboard/cards/dashboard_card_overflow_test.dart` | every card × narrowest grid width per span × tab × 26 locales (#1183) |
| `test/page/dashboard/cards/dashboard_card_popup_overflow_test.dart` | the same cards pinned into the popup form (#1239) |
| `test/page/dashboard/cards/dashboard_card_forced_form_overflow_test.dart` | the boxes a #1299 user pick produces, which no drag could |
| `test/page/shell/page_chrome_overflow_test.dart` | the top bar and dashboard header at screen width × locale (#1314/#1328) |

It is complete, not quick. `@Tags` is read by loading a suite, so the tag
compiles all 314 test files in order to skip 310 of them: measured 2026-08-21,
those same 2,386 tests take **1m53s under the tag and 32s when the four files are
named**. Identical selection either way, so name the files for a tight inner loop
and use the tag when a fifth sweep must not be silently missed.

`overflow` means "pumps cells and asserts zero overflow" — not "everything a
verdict depends on", which would slide the tag back over the whole family. So
the probe self-tests
([overflow_probe_test.dart](../../../test/util/overflow_probe_test.dart),
[overflow_baseline_test.dart](../../../test/util/overflow_baseline_test.dart))
carry `layout-gate` only, deliberately, even though every sweep's verdict rests
on them.

Two members are worth naming:

- **The #1183 card sweep** — `dashboard_card_overflow_test.dart`. Sweeps **every
  card × its narrowest grid width × every tab × all 26 shipped locales** and
  fails if any RenderFlex overflows beyond a baseline **allowlist** ("ratchet").
  **Data** is a fourth dimension, but an opt-in one: cards listed in
  `kCardDataProfileSweeps` are additionally swept against a second router shape —
  every other card's "clean" verdict is a verdict about the one default fixture.
  Everything below headed *card* describes this member only.
- **The #1314/#1328 page-chrome sweep** — `page_chrome_overflow_test.dart`.
  Sweeps **screen width × 26 locales** over the top bar and the dashboard header.
  It exists because the card sweep is blind to page chrome *by construction*: it
  pumps one card at a computed card width and never renders a page at a screen
  width, so no page-level `Row` is in its view. It shares the probe; it shares
  no geometry, no report, no allowlist.

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

1. Gate test — [test/page/dashboard/cards/dashboard_card_overflow_test.dart](../../../test/page/dashboard/cards/dashboard_card_overflow_test.dart)
2. Allowlist fixture — [test/fixtures/known_overflows.json](../../../test/fixtures/known_overflows.json)
3. Runner — [tool/run_overflow_test.sh](../../../tool/run_overflow_test.sh)
4. Probe + grid math + tab registry — [test/util/dashboard/dashboard_card_probe.dart](../../../test/util/dashboard/dashboard_card_probe.dart)
5. Data profiles + per-card sweep list — [test/util/dashboard/card_data_profiles.dart](../../../test/util/dashboard/card_data_profiles.dart)
6. Report generator (Status SSoT) — [test/util/dashboard/dashboard_overflow_report_generator.dart](../../../test/util/dashboard/dashboard_overflow_report_generator.dart)
7. Width-selection tests — [test/util/dashboard/dashboard_card_probe_test.dart](../../../test/util/dashboard/dashboard_card_probe_test.dart)

## Architecture — Data Flow (the card sweep)

Everything in this diagram except `overflow_probe.dart` belongs to the card
sweep alone. Another member of the gate reuses the box in the middle and nothing
above or below it.

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
                    overflow_probe.dart  (runWithOverflowCollection)
                    hooks FlutterError.onError → collects "overflowed by Npx"
                    as OverflowIncident, forwards real errors so they still fail
                                    │
                                    ▼
    dashboard_card_overflow_test.dart  (one testWidgets PER card×width×tab×locale,
                                        plus one per profile sweep's own cases)
          overflow > 2px tolerance?
            ├─ in allowlist  → print "KNOWN OVERFLOW (allowlisted)", PASS
            └─ not in allowlist → FAIL with fix/allowlist instructions
          clean, but the coordinate IS in the allowlist?
            └─ FAIL "dead exemption" / "over-broad exemption" (both directions)
                                    │
                    (only when DUMP > 0) tearDownAll →
                                    ▼
        dashboard_overflow_report_generator.dart → build/overflow_testing/
          overflow_report.md, overflow_report.html, png/…, png/adjust/…
```

Key invariants (do not "fix" these):

- **One pump per test.** Flutter reports each RenderFlex's overflow only once per
  render-object lifetime; multi-pump sweeps silently drop all but the first. That
  is why every `(card, width, tab, locale)` is its own `testWidgets`.
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

```jsonc
{
  "tracking": {
    "network_health": "legend fix #1145/#1174"   // optional per-card note,
  },                                               // printed on allowlisted hits
  "allowlist": {
    // key = "cardId|widthLabel|tabIndex"  →  set of overflowing locale tags
    "lan_info|min|0": ["*"],                       // "*" = structural: overflows
                                                   //   in EVERY locale (text-length
                                                   //   independent)
    "device_info|preferred|0": ["fi", "id", "pl", "sv"],  // text-length dependent
    "system_status|min|2": ["de", "es", "es_AR", "fr", "..."],
    "wifi_performance|min|2@triband": ["tr"]      // a data-profile sweep's case
  }
}
```

Key grammar — `cardId|widthLabel|tabIndex[@profileKey]`:

- `cardId` — a `UspWidgetSpecs.all` id (`-l` lists them).
- `widthLabel` — one of `min` / `preferred` / `max` (the card's column span whose
  narrowest grid width overflowed).
- `tabIndex` — 0-based; single-view cards are always `0`. Tabbed cards use the
  count in `kTabbedCardTabCounts`.
- `@profileKey` — **absent** for the default data profile, which keeps every
  pre-#1267 key byte-identical. A `kCardDataProfileSweeps` case lands under
  `…@<profile.key>` (e.g. `@triband`) so a second profile's findings can never
  move the default profile's entry count — the number every closed ticket in this
  epic quotes as "N coordinates cleared" (design §2.7).
- Value — a JSON array of **locale tags** (`_localeTag` format: `en`, `de`,
  `es_AR`, `fr_CA`, `pt_PT`, `zh_TW`, …), OR `["*"]` meaning "overflows in all
  locales regardless of text". A hit is tolerated if the set contains the locale
  **or** contains `"*"`.

## The Ratchet — How the Gate Reacts to Edits

The allowlist only *tolerates* the exact baseline. Every direction fails:

- **New overflow** — a card/width/tab not listed, or a listed entry seen in a
  **new locale** → the test FAILS. This is the point: regressions block the PR.
- **Premature removal** — deleting a locale that still overflows fails exactly
  that test (proven both ways in #1183). You cannot shrink the list by editing
  JSON alone; you must fix the layout first.
- **Dead exemption** — a locale listed as overflowing that now renders clean also
  FAILS, with "remove it". Before this, a fixed overflow kept its exemption
  silently, and a stale entry was indistinguishable from tracked debt — which is
  how 46 of them came to be retired by hand. Fixing a card therefore includes
  editing the fixture in the same change.
- **Over-broad `"*"`** — a `"*"` entry with *any* clean locale FAILS too: `"*"`
  claims the overflow is structural, so one clean locale disproves it. Replace it
  with the explicit tags that still overflow.

The gate's own failure message tells the operator exactly what to do:

> Fix the layout (Flexible/Expanded/maxLines/ellipsis), or if this is knowingly
> deferred, add "`<locale>`" to the `'<card>|<width>|<tab>'` entry.

## Playbooks

### A. A `layout-gate` test failed — triage

1. Read the failure: it names `card`, `width` (`min`/`preferred`/`max`), `tab`,
   `locale`, and the overflow (`+Npx right/bottom`).
2. Reproduce + visualize:
   `./tool/run_overflow_test.sh -c <card> -L <locale> -o`
3. Decide, in this order:
   - **Real regression** (a fix or new feature made an existing-clean case
     overflow) → **fix the layout**, don't allowlist. Re-run until green.
   - **Genuinely new card** → see Playbook C.
   - **Known overflow surfacing in a new locale** (an entry exists for
     `card|width|tab` but not this locale) → if the deferral is legitimate and
     tracked, add the locale tag to that entry's array. Prefer fixing.
   - **"Dead exemption" / "Over-broad exemption"** → the opposite failure: the
     coordinate is clean and the fixture still exempts it. Do what the message
     says — drop that locale tag (and the entry plus its `tracking` note once the
     list empties), or narrow a `"*"` to the tags that still overflow. Nothing to
     fix in the layout; this is the ratchet closing.
   - **A `[<profile>]` in the failure name** → the case comes from
     `kCardDataProfileSweeps`, so the *data*, not the width, is what breaks it.
     The message says so explicitly. Its allowlist key carries `@<profileKey>`.
4. Never retag the test or delete it to make CI pass.

### B. Edit the allowlist (defer a known overflow)

1. Confirm it's genuinely deferred (has, or needs, a tracking issue), not a
   regression you should fix now.
2. Add the locale tag to the matching `cardId|widthLabel|tabIndex[@profileKey]`
   array in `known_overflows.json` (create the entry if absent). Use `"*"` only
   when it overflows in **every** locale (structural) — the gate now fails the
   first clean locale it finds under a `"*"`, so guessing costs a red run.
3. Add/update a `tracking` note for the card so the allowlisted hit prints a
   pointer.
4. Re-run the affected slice to confirm green:
   `./tool/run_overflow_test.sh -c <card>`

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
4. Run the card's full sweep: `./tool/run_overflow_test.sh -c <new_card> -o`.
5. Fix any overflow you reasonably can; allowlist the rest per Playbook B with a
   tracking note. Goal is 0 new allowlist entries.

### D. Removing a card / tab

- Removing a card from `UspWidgetSpecs.all` → delete its `known_overflows.json`
  entries (including any `…@profileKey` ones), its `tracking` note, and any
  `kCardDataProfileSweeps` entry naming it.
- Changing a card's tab count → update `kTabbedCardTabCounts`; the meta-test
  enforces it. Re-baseline that card's entries, and check whether a profile sweep
  still names a tab index that exists.

### E. Shrink the allowlist (#1183 follow-up)

For each entry: fix the card's layout so it no longer overflows at that
width/tab/locale, then **remove** those locales (or the whole entry). Re-run
`-c <card>` — the ratchet confirms the removal is real from both sides: a
premature removal fails that exact test, and a fix you forget to record fails as
a dead exemption. This is the intended long-term direction; the baseline is debt,
not a target to grow.

## Adding a New Probe (a surface that is not a card)

You need a new probe when an overflow is found on a surface **no existing suite
renders**. That was the case for #1314/#1328: the card sweep pumps a card at a
card width, so page chrome could overflow at 601–767px in 26 locales with the
whole gate green. Adding a probe means a **new suite**, not a new dimension on an
existing one.

Reference implementation:
[test/page/shell/page_chrome_overflow_test.dart](../../../test/page/shell/page_chrome_overflow_test.dart).

### The seven rules

1. **The only shared asset is the `overflow_probe.dart` import path.**
   `collectOverflow` /
   `OverflowIncident` / `kOverflowTolerancePx` were extracted in #1270 for exactly
   this. Since #1338 the parser half — `OverflowIncident`, `kOverflowTolerancePx`,
   `isOverflowError` — lives in
   [test/layout_gate/incident.dart](../../../test/layout_gate/incident.dart) and
   `overflow_probe.dart` re-exports it, so importing the probe path is still
   correct and no importer changed. Everything else in the card sweep has **one**
   user: the grid geometry in
   `dashboard_card_probe.dart`, the report generator, and `known_overflows.json`
   each serve that one suite. Do not stretch the card-shaped model over a non-card
   surface — `OverflowReportItem` *requires* `cardId`/`columnSpan`/`rowSpan`/
   `recCols`/`recRows`, and its whole `OverflowStatus` vocabulary asks "can this
   card get a wider span?". Page chrome has no span, so the answer is not "false",
   it is "the question does not apply".
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
5. **One pump per cell.** Flutter reports each `RenderFlex`'s overflow once per
   render-object lifetime, so a loop that re-pumps inside one `testWidgets`
   silently drops every incident after the first. Give each pump a unique
   `ValueKey` so the tree is genuinely new.
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
| Using `"*"` after seeing overflow in a few locales | `"*"` means *every* locale — verify with a full-locale sweep of that card first; the gate fails the first clean locale under a `"*"` |
| Fixing a card's layout and leaving its allowlist entry behind | The clean case now fails as a "dead exemption" — remove the tag in the same change |
| Assuming a clean sweep covers every router | Data is a swept dimension only for cards opted into `kCardDataProfileSweeps`; otherwise "clean" means clean *on the default fixture* |
| Wrong locale tag (`zh-TW`, `es-AR`) | Use `_localeTag` form with underscore: `zh_TW`, `es_AR`, `fr_CA`, `pt_PT` |
| New tabbed card, but only tab 0 gets tested | Add it to `kTabbedCardTabCounts`; the `tab registry` meta-test enforces both directions, so an unregistered tabbed card fails instead of quietly under-sweeping |
| Retagging the test golden/loc/ui to "organize" it | It would drop out of the PR gate — keep it `layout-gate` |
| Multi-pumping to sweep widths/tabs in one test | Each case must be its own `testWidgets` (only the first overflow is reported per render object) |
| Editing the grid constants to change results | They mirror production geometry on purpose; changing them changes what "overflow" means |
| Removing an allowlist locale without fixing layout | The ratchet fails that exact test — fix the card first, then remove |
| Replacing the width enumeration with a "faster" sampled list | Sampling makes the worst-case invariant an assertion again, and is lossy under `MIN_SCREEN`; enumeration is pure arithmetic and costs nothing next to the pumps |
| Lowering `kMinSupportedScreenWidth` to "test more" | It is a product commitment (§2.3), and lowering it adds overflow coordinates — re-baseline deliberately, with the shift explained |
| Taking a green sweep as proof a refactor preserved coverage | Green also means "measured less". `./tool/overflow_baseline.sh check` compares the coordinates themselves |
| Capturing a baseline with `--file-reporter json:<file>` | Its sink interleaves writes and leaves 16KB NUL holes; the run still reports success while cells silently vanish. Use `--reporter json > file` — `tool/overflow_baseline.sh` does |
```
