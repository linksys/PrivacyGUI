# Dashboard Framework — Overflow Mechanics Investigation

**Last Updated: 2026-08-11**

> ## ⚠️ Superseded inferences — read this first
>
> This document's **data-flow mapping (§1, §2, §6) is intact and remains the
> reference** for how a declared constraint becomes a real `BoxConstraints`.
>
> Several of its **inferences** were subsequently tested by direct measurement
> and refuted. The measurements, and the design decisions taken from them, live
> in [dashboard_density_design.md](dashboard_density_design.md). Where the two
> documents disagree, **that one wins**.
>
> | This document infers | Measurement showed |
> |---|---|
> | The gate measuring at `minHeightRows` is a test artifact, so the 560 baseline is unreliable (§4.2, §9) | `minHeightRows` **is** user-reachable — `dashboard_controller_impl.dart:746-747` clamps to `minH`, which `layout_item_factory.dart:59` sets from `minHeightRows`. The baseline is real. |
> | The failing pattern lives **below** the card layer, in shared sub-widgets (§5.2, §5.3) | Attribution of all 998 incidents to their error-causing widget: **68% (379/560 coordinates) is card-own code**; `_shared` accounts for 18% alone, 29% including combinations. |
> | `colWidth`'s screen-vs-card mismatch is a systemic driver (§3.7) | Dashboard cards call `colWidth` **zero** times. The mismatch reaches exactly one card, via `usp_info_row.dart:29`. |
>
> Its verdict that **`HeightStrategy` is a behavioural no-op** (§2.3, §3.1) was
> independently re-verified and **holds**.

## Scope

This document maps the **sizing and overflow mechanics** of the USP Dashboard card
framework: how a declared spec constraint becomes the actual `BoxConstraints` a
card's `build()` sees, what the grid does when content does not fit, and where
responsibility for "content fits its box" currently lives.

**In scope**: the constraint pipeline (`UspWidgetSpecs` → `LayoutItemFactory` →
`SliverDashboard` render object → card widget), the semantics of
`WidgetGridConstraints` / `HeightStrategy` as actually implemented, the
width-axis vs height-axis distinction, per-card layout patterns, and the
edit-mode resize path.

**Out of scope**: any redesign, fix, or recommendation. This document describes
**what exists and why overflow is possible**. It deliberately stops short of
proposing solutions.

**Companion document**: `doc/dashboard/dashboard_custom_layout_comprehensive_report_en.md`
(architecture report, `doc/dashboard/dashboard_custom_layout_comprehensive_report_en.md:5`
declares "Last Updated: 2026-03-23"). That report covers the architecture,
providers, persistence, and preset system. This document does **not** repeat it;
it goes deeper on sizing mechanics and flags where the 2026-03-23 report is now
stale (see §7).

**Primary sources read**:

| Source | Location |
|---|---|
| Repo dashboard framework | `lib/page/dashboard/` |
| sliver_dashboard **0.9.0** (the resolved version, `pubspec.lock:1254-1261`) | `/Users/austin.chang/.pub-cache/hosted/pub.dev/sliver_dashboard-0.9.0/` |
| ui_kit_library (path from `.dart_tool/package_config.json`) | `/Users/austin.chang/.pub-cache/git/privacyGUI-UI-kit-4687b421202b251d44d53e3d0954e0624716a9e0/` |
| Overflow gate machinery | `test/util/dashboard/dashboard_card_probe.dart`, `test/page/dashboard/cards/dashboard_card_overflow_test.dart`, `test/fixtures/known_overflows.json` |

Version note: `sliver_dashboard-0.9.1` also exists in the pub cache. **It was not
read** and no claim here derives from it.

Measured evidence (560 overflowing coordinates, per-card counts, GridExpand /
ScreenLimit / Internal breakdown) was supplied as established and is **not
re-measured** here; it is used as data to test hypotheses against.

---

## 1. Q1 — End-to-end flow: where a declared constraint becomes a real `BoxConstraints`

### 1.1 Flow diagram

```
┌─ DECLARATION (compile-time constants) ───────────────────────────────────────┐
│ UspWidgetSpecs.all              lib/page/dashboard/models/usp_widget_specs   │
│   18 × WidgetSpec               .dart:312 (list), :20-291 (entries)          │
│     └ constraints[DisplayMode.normal] = WidgetGridConstraints(              │
│           minColumns, preferredColumns, maxColumns,                          │
│           minHeightRows, maxHeightRows, heightStrategy )                     │
└──────────────────────────────┬───────────────────────────────────────────────┘
                               │  SEAM 1: spec → integer grid item
                               ▼
┌─ LayoutItemFactory.fromSpec ─────────────────────────────────────────────────┐
│ lib/page/dashboard/providers/layout_item_factory.dart:26-62                   │
│   w = w ?? constraints.preferredColumns                          (:47)       │
│   h = h ?? constraints.getPreferredHeightCells(columns: w)       (:48-49)    │
│   → LayoutItem(w, h, minW, maxW, minH, maxH)                     (:51-61)    │
│ ** This is the ONLY place heightStrategy is ever consumed. **                │
└──────────────────────────────┬───────────────────────────────────────────────┘
                               │  SEAM 2: 12-col layout → breakpoint layout
                               ▼
┌─ UspWidgetSpecs.scaleLayout / controller pre-seed ───────────────────────────┐
│ usp_widget_specs.dart:351-392 ; usp_layout_controller.dart:102-121           │
│   12→8: w,minW,maxW scaled ×8/12 and rounded    (:372, :381-382)            │
│   12→4: ALL items forced w = 4 (full width)     (:366-369)                   │
│   h is NOT touched by scaleLayout — only w/x/minW/maxW                       │
└──────────────────────────────┬───────────────────────────────────────────────┘
                               │  SEAM 3: LayoutItem list → sliver
                               ▼
┌─ UspSliverDashboardView._buildSliverDashboard ───────────────────────────────┐
│ lib/page/dashboard/views/usp_sliver_dashboard_view.dart:307-376              │
│   _slotHeight = 120.0 const                                      (:305)      │
│   slotWidth = (maxWidth − pageMargin·2 − (cols−1)·16) / cols      (:324-325) │
│   ratio = slotWidth / 120.0  → passed as slotAspectRatio          (:326,362) │
│   breakpoints: {0: context.currentMaxColumns}                      (:365)     │
│   crossAxisSpacing = mainAxisSpacing = AppSpacing.lg = 16          (:363-364)│
└──────────────────────────────┬───────────────────────────────────────────────┘
                               │  SEAM 4: integer w/h → PIXELS  ◄── THE seam
                               ▼
┌─ RenderSliverDashboard.performLayout ────────────────────────────────────────┐
│ sliver_dashboard-0.9.0/lib/src/view/sliver_dashboard.dart                    │
│   slotWidth  = (crossAxisExtent − (n−1)·xSpacing) / n            (:401)      │
│   slotHeight = slotWidth / slotAspectRatio                        (:402)      │
│   w = item.w·(slotWidth+xSpacing) − xSpacing                      (:422)      │
│   h = item.h·(slotHeight+ySpacing) − ySpacing                     (:423)      │
│   itemRects[i] = Rect.fromLTWH(x, y, max(w,0), max(h,0))          (:435)      │
│   child.layout(BoxConstraints.tightFor(w: rect.width,                        │
│                                        h: rect.height))     (:510,:538,:556) │
│ ** TIGHT on both axes. No intrinsic query. No assert. No clip. **            │
└──────────────────────────────┬───────────────────────────────────────────────┘
                               │  SEAM 5: cell → widget
                               ▼
┌─ UspSliverDashboardView._buildItemWidget ────────────────────────────────────┐
│ usp_sliver_dashboard_view.dart:522-565                                       │
│   resolvedWidget = UspWidgetFactory().buildWidget(item.id)         (:528)     │
│   SizedBox.expand(child: resolvedWidget)                           (:548)     │
│   ClipRect deliberately REMOVED — see comment                     (:545-547) │
└──────────────────────────────┬───────────────────────────────────────────────┘
                               ▼
┌─ Card widget → DashboardCardTemplate → AppCard → AppSurface ─────────────────┐
│ lib/page/_shared/components/dashboard_card_template.dart:210-231             │
│   AppCard(Column[ header, (tabbar), Expanded(body), footer ])                │
│ ui_kit .../molecules/cards/app_card.dart:137-149 → AppSurface                │
│ ui_kit .../atoms/surfaces/app_surface.dart:222-231 clipBehavior: Clip.antiAlias│
└──────────────────────────────────────────────────────────────────────────────┘
```

### 1.2 Named transformations

| # | Transformation | Where | Note |
|---|---|---|---|
| T1 | `preferredColumns` → `LayoutItem.w` | `layout_item_factory.dart:47` | Bypassed by `createLayoutForCards`, which passes explicit `w: 12` / `w: 6` (`usp_widget_specs.dart:430,439,448`) |
| T2 | `heightStrategy` → `LayoutItem.h` (integer rows) | `layout_item_factory.dart:48-49` → `widget_grid_constraints.dart:66-75` | `h` is never passed explicitly by `createLayoutForCards`, so the strategy **does** decide default height |
| T3 | `minColumns/maxColumns/minHeightRows/maxHeightRows` → `minW/maxW/minH/maxH` | `layout_item_factory.dart:57-60` | These reach the package only as drag-time clamps |
| T4 | 12-col `w` → breakpoint `w` | `usp_widget_specs.dart:363-382` | Height untouched |
| T5 | integer `w` → pixels | `sliver_dashboard.dart:401,422` | Function of `crossAxisExtent`, `slotCount`, `crossAxisSpacing` only |
| T6 | integer `h` → pixels | `sliver_dashboard.dart:402,423` | `slotHeight` derived from `slotWidth / slotAspectRatio`; the view sets ratio so this resolves to a fixed 120 px (`usp_sliver_dashboard_view.dart:326`) |
| T7 | `Rect` → `BoxConstraints` | `sliver_dashboard.dart:510`, `:538`, `:556` | **`BoxConstraints.tightFor` — the answer to "where does a declared constraint become a real BoxConstraints"** |
| T8 | cell → widget, forced to fill | `usp_sliver_dashboard_view.dart:548` | `SizedBox.expand` |

A **null-constraints escape hatch** exists: if a spec has no entry for the
requested `DisplayMode`, `LayoutItemFactory` returns `LayoutItem(w: w ?? 4, h: h ?? 2)`
with **no `minW`/`maxW`/`minH`/`maxH` at all** (`layout_item_factory.dart:35-44`).
All 18 native specs do declare `DisplayMode.normal` (`usp_widget_specs.dart:20-291`),
so this path is currently reachable only by package/A2UI widgets.

---

## 2. Q2 — What the constraints actually DO inside sliver_dashboard 0.9.0

### 2.1 The decisive fact

Every card is laid out under **tight constraints on both axes**, computed purely
from the integer `item.w` / `item.h`:

```dart
// sliver_dashboard-0.9.0/lib/src/view/sliver_dashboard.dart:537-540
child.layout(
  BoxConstraints.tightFor(width: rect.width, height: rect.height),
  parentUsesSize: true,
);
```

The same expression appears at `:510` (leading-fill path) and `:555-556`
(gap-fill path). There is **no other call site that lays out a dashboard child**
in that file.

### 2.2 Answering the concrete questions

| Question | Answer | Evidence |
|---|---|---|
| Content needs more **height** than allotted → clip? | **No clip at the grid level.** `paint()` walks children with `context.paintChild` and no clip layer (`sliver_dashboard.dart:611-644`). The only `ClipRect`/`Clip` in the package's view layer is in `dashboard_feedback_widget.dart:115` (drag feedback) and `dashboard_overlay.dart:262` which is explicitly `Clip.none`. |
| … → overflow? | **Yes — inside the card.** The card is forced to exactly `rect.height`; a `Column` whose children exceed that emits `RenderFlex overflowed by N pixels on the bottom`. |
| … → expand? | **No.** `maxScrollExtent` is computed from `itemRects` (`sliver_dashboard.dart:424-425`), i.e. from `item.h` alone. Nothing reads the child's desired size. |
| … → assert? | **No.** `grep` for `assert(` across `sliver_dashboard-0.9.0/lib/src/view/` returns nothing. |
| Same for **width**? | Identical: tight width from `item.w`; a `Row` that cannot fit emits `overflowed … on the right`. |
| Is there an intrinsic-sizing path? | **No.** `grep` for `computeMinIntrinsic` / `computeMaxIntrinsic` across `sliver_dashboard-0.9.0/lib/src/view/` returns nothing. |

### 2.3 `HeightStrategy` — `strict` and `columnBased` are the same class

```dart
// ui_kit .../lib/src/models/height_strategy.dart:14-21
const factory HeightStrategy.columnBased(double multiplier) =
    ColumnBasedHeightStrategy;

/// Specialized for Bento Grid: Force specify the "Row Span" of the grid
const factory HeightStrategy.strict(double rows) = ColumnBasedHeightStrategy;
```

`strict(n)` is a **redirecting factory to the identical class** as
`columnBased(n)` — same runtime type, same field, same `==`
(`height_strategy.dart:42-54`). `IntrinsicHeightStrategy` carries no data at all
(`height_strategy.dart:31-39`).

Both are consumed at exactly one place:

```dart
// ui_kit .../lib/src/models/widget_grid_constraints.dart:66-75
int getPreferredHeightCells({int? columns}) {
  final cols = columns ?? preferredColumns;
  return switch (heightStrategy) {
    ColumnBasedHeightStrategy(:final multiplier) => multiplier.ceil(),
    AspectRatioHeightStrategy(:final ratio)      => (cols / ratio).ceil().clamp(1, 12),
    IntrinsicHeightStrategy()                    => minHeightRows.clamp(2, 6),
  };
}
```

Note what this means: `intrinsic()` does **not** request intrinsic sizing. It
returns `minHeightRows.clamp(2, 6)` — an integer row count, the same kind of
value `strict(n)` returns. Both feed the same `LayoutItem.h`
(`layout_item_factory.dart:48-49`), which becomes the same
`BoxConstraints.tightFor` height.

**Verified single consumer**: `grep -rn heightStrategy lib/` returns only
`usp_widget_specs.dart` (the 18 declarations),
`layout_item_factory.dart:49`, and `lib/page/dashboard/models/package_widget_template.dart:55`.
A parallel grep across ui_kit_library outside `lib/src/models/` returns **no
matches**. No render object anywhere receives the strategy.

### 2.4 What min/max actually do

| Field | Reaches the package? | Effect |
|---|---|---|
| `preferredColumns` | Only via `LayoutItem.w` at `layout_item_factory.dart:47` | See §6.4 — largely bypassed in practice |
| `minColumns` → `minW` | Yes, `layout_item_factory.dart:57` | Live clamp during resize drag (`dashboard_controller_impl.dart:746`); **bypassable**, see §6.2 |
| `maxColumns` → `maxW` | Yes, `:58` | Live clamp during drag (`:744,:746`) |
| `minHeightRows` → `minH` | Yes, `:59` | Live clamp during drag (`:747`) |
| `maxHeightRows` → `maxH` | Yes, `:60` | Live clamp during drag (`:745,:747`) |
| `heightStrategy` | **No** | Only picks the initial integer `h` |

### 2.5 A framework hazard: the skipped frame

When the breakpoint changes, `SliverDashboard.build` schedules
`setSlotCount` in a post-frame callback and returns
`SliverToBoxAdapter(child: SizedBox.shrink())` for that frame
(`sliver_dashboard.dart:110-124`). During that frame no card is laid out at all.
This is a correctness/flicker property, not itself an overflow source, but it
means card geometry is not stable within a single breakpoint transition.

---

## 3. Q3 — Testing the `strict()` hypothesis adversarially

**Hypothesis under test**: "strict height pinning is the root cause of the 560
overflowing coordinates."

### 3.1 Verdict

**Largely refuted as a mechanism. Partially explained as a correlation.**

`strict()` cannot be the mechanism, because the mechanism is
`BoxConstraints.tightFor` (`sliver_dashboard.dart:510/538/556`) applied to
**every** card regardless of strategy. `strict` vs `intrinsic` changes only which
integer row count is chosen (`widget_grid_constraints.dart:69` vs `:72-73`); both
then produce equally tight constraints. `strict(n)` and `columnBased(n)` are
literally the same class (`height_strategy.dart:14-21`), so "strict" is not even
a distinct code path.

### 3.2 Evidence FOR the hypothesis

1. **The raw aggregate looks damning**: 526 coordinates across 11 strict cards vs
   34 across 2 intrinsic cards.
2. **`strict` cards are the only ones that can declare a `h` below their own
   `minHeightRows` floor**… except they can't declare it *lower*; see §3.3 point 3
   for why this cuts the other way.
3. **Height overflow is real**: 110 of 560 coordinates are classified `Internal`
   (still overflow when widened), and the report generator's bottom-overflow
   branch (`dashboard_card_overflow_test.dart:299-305`) exists precisely because
   bottom overflow occurs.

### 3.3 Evidence AGAINST the hypothesis

**1. `intrinsic()` does not request intrinsic sizing.**
`widget_grid_constraints.dart:72-73` returns `minHeightRows.clamp(2, 6)`. It is a
constant-row strategy with a different formula, not a content-driven one. So
switching a card to `intrinsic()` changes its height by at most a rounding of
`minHeightRows` — it cannot relieve height overflow structurally.

**2. `intrinsic()` has no bearing on width at all.** `getPreferredHeightCells` is
a height function; `LayoutItem.w` comes from `preferredColumns`
(`layout_item_factory.dart:47`), untouched by strategy. Since roughly 450 of 560
coordinates are `GridExpand` (315) + `ScreenLimit` (135) — both driven by the
**right**-overflow branch (`dashboard_card_overflow_test.dart:287-295`,
classifier at `dashboard_overflow_report_generator.dart:66-73`) — the dominant
axis is **width**, which no `HeightStrategy` value can influence.

**3. The gate does not pump at the strategy's height — it pumps at `minHeightRows`.**

```dart
// test/page/dashboard/cards/dashboard_card_overflow_test.dart:248
final rows = spec.getConstraints(DisplayMode.normal).minHeightRows;
```

Production height comes from `getPreferredHeightCells` (`layout_item_factory.dart:48-49`).
For strict cards these differ; for intrinsic cards they are identical by
construction (`minHeightRows.clamp(2, 6)` = `minHeightRows` for all four
intrinsic cards, whose `minHeightRows` is 3). Computed from
`usp_widget_specs.dart` declarations and `dashboard_card_probe.dart:105-106`:

| Card | Strategy | Production rows | Gate rows | Production px | Gate px | Height budget the gate removes | Coords |
|---|---|---:|---:|---:|---:|---:|---:|
| system_status | strict(5) | 5 | 4 | 664 | 528 | **−136** | 85 |
| network_health | strict(4) | 4 | 3 | 528 | 392 | **−136** | 84 |
| firewall_overview | strict(4) | 4 | 3 | 528 | 392 | **−136** | 67 |
| ethernet_ports | strict(3) | 3 | 2 | 392 | 256 | **−136** | 52 |
| traffic_analysis | strict(5) | 5 | 4 | 664 | 528 | **−136** | 49 |
| wifi_performance | strict(5) | 5 | 4 | 664 | 528 | **−136** | 45 |
| lan_info | strict(3) | 3 | 2 | 392 | 256 | **−136** | 44 |
| device_info | strict(3) | 3 | 2 | 392 | 256 | **−136** | 29 |
| network_status | strict(3) | 3 | 2 | 392 | 256 | **−136** | 24 |
| topology | strict(5) | 5 | 3 | 664 | 392 | **−272** | **0** |
| device_analytics | strict(5) | 5 | 4 | 664 | 528 | **−136** | **0** |
| stats_panel | strict(1) | 1 | 1 | 120 | 120 | 0 | 26 |
| time_settings | strict(3) | 3 | 3 | 392 | 392 | 0 | 21 |
| wifi_status | strict(4) | 4 | 4 | 528 | 528 | 0 | **0** |
| connected_devices | intrinsic | 3 | 3 | 392 | 392 | 0 | 27 |
| port_forwarding | intrinsic | 3 | 3 | 392 | 392 | 0 | 7 |
| dhcp_reservations | intrinsic | 3 | 3 | 392 | 392 | 0 | **0** |
| wifi_networks | intrinsic | 3 | 3 | 392 | 392 | 0 | **0** |

This table is the crux. **Nine of the eleven overflowing strict cards are pumped
136 px shorter than production ships them**, whereas **all four intrinsic cards
are pumped at exactly their production height**. The strict/intrinsic split in
the raw counts is therefore confounded with a systematic ~136 px height handicap
applied only to strict cards. The 526-vs-34 ratio is not a clean comparison.

(The probe does mitigate this for the *height* axis specifically: the harness
wraps the card in `SingleChildScrollView` + `Align(topLeft)`
(`dashboard_card_probe.dart:296-308`) and the docstring at `:293-295` states
height is deliberately generous because the gate hunts horizontal overflow. But
the card itself is still hard-sized by `SizedBox(width: cardWidth, height: cardHeight)`
at `:301-304`, so a `Column` inside the card still sees the shorter box and still
reports bottom overflow.)

**4. Two strict cards with the *largest* height handicap are perfectly clean.**
`topology` is pumped 272 px short (the worst handicap of any card) and
`device_analytics` 136 px short, and both have **zero** overflowing coordinates,
with no entries in `test/fixtures/known_overflows.json:5-73`. If strict height
pinning were the driver, these two should be the worst affected.

**5. Two intrinsic cards overflow anyway.** `connected_devices` (27) and
`port_forwarding` (7) are allowlisted at
`known_overflows.json:6-7` and `:39-40`. Their overflow is width-axis:
`connected_devices` right-overflows and `port_forwarding` only in the five
long-word Romance locales (`es`, `fr`, `fr_CA`, `pt`, `pt_PT`).

**6. `stats_panel` and `time_settings` overflow with zero height handicap.**
Both are pumped at exactly their production height (0 deficit) and still produce
26 and 21 coordinates. Their overflow cannot be a height-budget artifact at all.

### 3.4 What the 3 clean strict cards actually do differently

| Card | Distinguishing pattern | Evidence |
|---|---|---|
| `topology` | `DashboardCardTemplate(scrollable: false, content: ClipRect(child: AppTopology(...)))`. A **self-sizing canvas wrapped in an explicit ClipRect** — no text `Row`s in the body at all. | `lib/page/topology/cards/usp_network_topology_card.dart:49,55,56,59` |
| `wifi_status` | The **only** card in the repo that pairs fixed-width `SizedBox(width: context.colWidth(n))` labels with `Expanded` middles — 5 `colWidth` call sites. | `lib/page/wifi_settings/cards/usp_wifi_status_card.dart:86,127,138,175,182`; the repo-wide `colWidth` grep shows no other card file with more than 1 |
| `device_analytics` | Every horizontal child is `Expanded`, and each `Expanded` contains a nested `Row` whose **text child is itself `Expanded`** while only the numeral is intrinsic. | `lib/page/dashboard/views/components/usp_device_analytics_card.dart:148-181` (`Expanded(LayoutBlock(Row[Icon, Gap, Expanded(text), titleSmall(number)]))`), repeated at `:185-235` |

The common thread is **not** the height strategy — all three are `strict`. It is
that **no unbounded text sits as a non-flexible child of a `Row`**.

### 3.5 Does `intrinsic()` solve WIDTH overflow?

**No.** `getPreferredHeightCells` (`widget_grid_constraints.dart:66-75`) returns a
height. `LayoutItem.w` is set from `preferredColumns` at
`layout_item_factory.dart:47` with no reference to `heightStrategy`. The
`BoxConstraints.tightFor` width at `sliver_dashboard.dart:538` derives from
`item.w` only (`:422`). There is no path by which any `HeightStrategy` value can
change a card's width.

Given that the majority of coordinates classify as `GridExpand` (315) or
`ScreenLimit` (135) — both reachable only through
`hasRightOverflow` (`dashboard_card_overflow_test.dart:279-295`) — the strategy
knob addresses the minority axis.

### 3.6 Height-axis vs width-axis causes, separated

| Axis | Mechanism | Where |
|---|---|---|
| **Width** | Card box width is a pure function of `(crossAxisExtent, slotCount, item.w)`; a `Row` with a non-flexible unbounded-text child cannot shrink below its intrinsic width → `overflowed … right`. | `sliver_dashboard.dart:401,422,538` + per-card `Row`s (§5) |
| **Width (second, independent cause)** | `context.colWidth(n)` computes from **screen width**, not from the card's own box. It has no knowledge of the card's width. A card 191 px wide reserving `colWidth(2) = 122 px` for a label leaves ~37 px for the value. | ui_kit `lib/src/layout/layout_extensions.dart:76-107`, esp. `:99` `screenWidth - marginTotal - gutterTotal` |
| **Width (third cause: gutter mismatch)** | The grid hardcodes `AppSpacing.lg = 16` as gutter (`usp_sliver_dashboard_view.dart:363-364`; `AppSpacing.lg = 16` at ui_kit `lib/src/foundation/theme/tokens/app_spacing.dart:9`), while `colWidth` uses the **responsive** gutter (20 or 24 above 905 px) (`layout_extensions.dart:85` → `app_layout_provider.dart:312-316` → `app_layout_config.dart:90-100`). So the grid's slot and `colWidth(1)` disagree by design above 905 px. |
| **Height** | Card box height = `item.h × 120 + (item.h−1) × 16`; a `Column` exceeding it → `overflowed … bottom`. Tabbed cards get **no scroll relief** (`dashboard_card_template.dart:277-279`). | `sliver_dashboard.dart:402,423,538`; `usp_sliver_dashboard_view.dart:305,326` |

### 3.7 Quantified: the `colWidth` mismatch

Computed from the formulas at `dashboard_card_probe.dart:71-102` (grid side) and
`layout_extensions.dart:76-107` (`colWidth` side), for a `minColumns: 3` card at
its narrowest realization:

| Screen | Card px (span 3) | AppCard inner (−2×16 padding) | `colWidth(2)` label reserve | Left for value |
|---:|---:|---:|---:|---:|
| 601 | 191.4 | 159.4 | 122.2 | **37.1** |
| 906 | 202.5 | 170.5 | 123.0 | **47.5** |
| 1241 | 198.2 | 166.2 | 123.5 | **42.8** |
| 320 | 212.0 | 180.0 | 136.0 | **44.0** |

`AppCard`'s default padding is `EdgeInsets.all(AppSpacing.lg)` = 16 per side
(ui_kit `lib/src/molecules/cards/app_card.dart:144-145`). A `UspInfoRow`
(`lib/page/_shared/components/usp_info_row.dart:28-32`) at these widths reserves
~70% of the card's usable width for its label and leaves ~37-48 px for the
`Expanded` value. This is a **width-axis, screen-vs-box mismatch** with no
relationship to `HeightStrategy`.

### 3.8 Restated verdict

- The **mechanism** of overflow is `BoxConstraints.tightFor` from an integer grid
  span, applied to all 18 cards identically (`sliver_dashboard.dart:510/538/556`).
- `HeightStrategy` selects only an initial integer row count
  (`widget_grid_constraints.dart:66-75`) and never reaches a render object
  (single-consumer grep, §2.3). `strict` is not even a distinct class from
  `columnBased` (`height_strategy.dart:14-21`).
- The strict/intrinsic correlation in the raw counts is **confounded** by the gate
  pumping 9 of 11 strict cards 136 px shorter than production while pumping all 4
  intrinsic cards at exactly production height (§3.3 table).
- The dominant axis is **width** (315 GridExpand + 135 ScreenLimit ≈ 450/560),
  which no `HeightStrategy` value can affect.
- The counter-examples are decisive in both directions: the two most
  height-handicapped strict cards (`topology`, `device_analytics`) are clean,
  while two zero-handicap cards (`stats_panel`, `time_settings`) and two
  intrinsic cards (`connected_devices`, `port_forwarding`) overflow.

---

## 4. Q4 — Where does "content fits its box" responsibility live?

### 4.1 It lives with the **card author**, by default and without support

| Layer | Does it validate content fit? | Evidence |
|---|---|---|
| `WidgetGridConstraints` constructor | **No.** Its four asserts check only internal consistency of the numbers (`1 ≤ minColumns ≤ 12`, `maxColumns ≥ minColumns`, `preferredColumns` within range, `maxHeightRows ≥ minHeightRows`). None can see a widget. | ui_kit `lib/src/models/widget_grid_constraints.dart:34-38` |
| `LayoutItemFactory` | **No.** Pure arithmetic; no widget reference is available to it. | `lib/page/dashboard/providers/layout_item_factory.dart:26-62` |
| `UspWidgetSpecs` | **No.** `const` data only. | `lib/page/dashboard/models/usp_widget_specs.dart:312` |
| `RenderSliverDashboard` | **No.** `grep assert(` across `sliver_dashboard-0.9.0/lib/src/view/` returns nothing. |
| `UspSliverDashboardView` | **No** for content fit. It validates only that a **user-resized** span respects declared min/max, post-hoc (§6.3). | `lib/page/dashboard/views/usp_sliver_dashboard_view.dart:448-497` |
| Repo-wide asserts | **None.** `grep -rn "assert(" lib/page/dashboard/` returns nothing. |
| Lint | **None.** `analysis_options.yaml:27` has an empty `rules:` block; no custom_lint package, no overflow rule. |

There is **no framework mechanism** — no assert, no debug-mode check, no
`debugAssertDoesMeetConstraints`-style hook, no lint — that a card's declared
`minColumns` can actually hold its content.

### 4.2 The overflow gate is a test, not a framework mechanism

This distinction matters:

- `test/page/dashboard/cards/dashboard_card_overflow_test.dart` detects overflow by
  intercepting `FlutterError.onError` and string-matching `'overflowed'`
  (`test/util/overflow_probe.dart:73-82`). That is a **debug-build diagnostic**,
  not a layout contract.
- It runs only under `flutter test`. It is tagged `dashboard-card`
  (`dashboard_card_overflow_test.dart:1`), which is not in `run_tests.sh`'s
  `--exclude-tags="golden||loc||ui"` (`run_tests.sh:80,92,96`), so it gates PRs —
  but it does not affect the shipped app at all.
- It has a **tolerance**: `_tolerancePx = 2.0`
  (`dashboard_card_overflow_test.dart:87,273`), so sub-2px overflow is invisible
  to it.
- It has a **documented allowlist** of 560 known-failing coordinates
  (`test/fixtures/known_overflows.json:5-73`), so those coordinates ship
  overflowing by policy.
- Flutter reports each `RenderFlex`'s overflow **once per render-object
  lifetime**, which is why the gate uses one pump per test
  (`dashboard_card_probe.dart:318-326`). In production, the same property means a
  card that overflows on a later frame may report nothing.

### 4.3 In production, what happens to the overflow?

The grid does not clip (§2.2), and `_buildItemWidget` deliberately removed
`ClipRect`:

```dart
// lib/page/dashboard/views/usp_sliver_dashboard_view.dart:545-548
// SizedBox.expand ensures cards fill their grid cell.
// Note: ClipRect was removed because it clips shadows/borders causing
// visual truncation. Cards handle their own overflow via internal clipping.
final displayedWidget = SizedBox.expand(child: resolvedWidget);
```

The referenced "internal clipping" does exist, one layer down:
`DashboardCardTemplate` → `AppCard` → `AppSurface`, whose `AnimatedContainer` sets
`clipBehavior: Clip.antiAlias` (ui_kit `lib/src/atoms/surfaces/app_surface.dart:222-231`,
comment at `:221` "clipBehavior ensures child content respects the border
radius"). So overflowing content is **visually clipped at the card border** in
release builds — no yellow-and-black stripe, no exception, just silently missing
or cut-off content. In debug builds the same overflow additionally produces the
`RenderFlex overflowed` error the gate keys on.

---

## 5. Q5 — What a card author must do today, and whether any primitive helps

### 5.1 The shared scaffold: what it does and does not protect

`lib/page/_shared/components/dashboard_card_template.dart` (429 lines) is used by
all cards examined. Its structure (`:210-231`):

```dart
AppCard(child: Column(crossAxisAlignment: stretch, children: [
  _buildHeader(context),                      // :216
  if (_isTabbed) [AppGap.md(), _buildTabBar(context)],  // :217-220
  AppGap.lg(),                                // :221
  Expanded(child: _buildScrollableContent(context)),    // :223-225
  _buildFooter(context),                      // :227
]))
```

| Region | Overflow-safe? | Evidence |
|---|---|---|
| Header **title** | **Yes** — `Flexible` + `maxLines: 1` + `TextOverflow.ellipsis` | `:243-249` |
| Header `titleBadge` | **No** — appended as a raw non-flexible child of the inner `Row` | `:250-253` |
| Header `trailing` | **No** — raw non-flexible child of the outer `Row` | `:257` |
| Body, **non-tabbed** | Vertical relief only — `SingleChildScrollView` | `:293-296` |
| Body, **tabbed** | **No relief at all** — returns tab content directly, before the scroll wrapper is reached | `:277-279` (comment: "Tab content - don't wrap in scroll (charts need fixed space)") |
| Body, `scrollable: false` | No relief (opt-out) | `:289-291` |
| Section header (multiSection) | Title is **not** flexible — `AppText.titleSmall(section.title)` is a raw `Row` child | `:326-334` |
| Footer | Fixed-height; `_buildPlaceholderFooter` always reserves ~20 px + divider + gap even when there is no link | `:413-428`, esp. `:422-424` |

Two structural consequences: (a) the template offers **zero horizontal
protection** anywhere except the title; (b) tabbed cards get **zero vertical
protection**, and 6 of 18 cards are tabbed
(`test/util/dashboard/dashboard_card_probe.dart:221-228`:
`firewall_overview`, `network_health`, `wifi_performance`, `device_analytics`,
`system_status`, `traffic_analysis`) — accounting for 4 of the top 6
overflow counts.

### 5.2 Is there a shared width-safe primitive? Mostly no.

| Candidate | Status |
|---|---|
| `UspInfoRow` (`lib/page/_shared/components/usp_info_row.dart:22-36`) | Structurally safe (`SizedBox` label + `Expanded` value) **but** sizes its label from `context.colWidth(labelColumns)` = screen width, not card width (`:29`). Used by only 2 of the 18 card files (`usp_system_status_card.dart`, `usp_wifi_status_card.dart`); the other 7 usages are detail views/dialogs/sections. Not a card-level standard. |
| `ToggleRow` (`lib/page/_shared/components/layout_blocks/row_blocks.dart:139-198`) | **Genuinely safe**: fixed 44 px leading, and both title and subtitle carry `maxLines: 1` + `ellipsis` (`:181-193`). Used by `port_forwarding`. |
| `StatTile` (`lib/page/_shared/components/layout_blocks/stat_blocks.dart:13-68`) | **Not safe**: inner `Row(mainAxisSize: min)` at `:40-50` and a bare `AppText.bodySmall(label)` at `:52-55` with no `maxLines`/`ellipsis`/`Flexible`. |
| `LayoutBlock` | A padded container; carries no flex or ellipsis policy. |
| `context.colWidth(n)` | Available and used, but computes from screen width (§3.7), so it is not a card-relative primitive. |
| Responsive card scaffold / constrained-text helper / overflow-safe row | **Does not exist.** No such abstraction was found in `lib/page/_shared/components/` or ui_kit. |

**Conclusion**: each card hand-rolls its own horizontal fit. The only reusable
horizontally-safe primitive found is `ToggleRow`.

### 5.3 Clean vs badly-overflowing: concrete pattern comparison

**Clean cards (0 coordinates)**

| Card | Pattern | Citation |
|---|---|---|
| `topology` | `scrollable: false` + body is `ClipRect(AppTopology(...))`. Self-sizing canvas; body contains **no text `Row`s**. | `lib/page/topology/cards/usp_network_topology_card.dart:49,55-59` |
| `wifi_status` | Fixed `SizedBox(width: colWidth(1..2))` + `Expanded` middle, consistently, 5 times. | `lib/page/wifi_settings/cards/usp_wifi_status_card.dart:83-92,124-140,166-186` |
| `device_analytics` | **Doubly** flexible: outer `Expanded`, and the text inside the nested `Row` is *also* `Expanded`; only the numeral is intrinsic. | `lib/page/dashboard/views/components/usp_device_analytics_card.dart:146-183,185-235` |

**Badly-overflowing cards**

| Card | Coords | Failing pattern | Citation |
|---|---:|---|---|
| `system_status` | 85 | 4 legend `Row`s whose children are `_LegendDot` + `AppText.labelSmall(...)` + `Spacer` — **the text is a non-flexible `Row` child** with a localized interpolated string. Repeated 4× (one per tab). Also two `AppGauge(size: 100)` side by side in a `Row`, and `UspInfoRow` (screen-derived label width). | `lib/page/dashboard/views/components/usp_system_status_card.dart:218-237` (and the parallel blocks at `:314-325`, `:378-385`, `:464-475`); `UspInfoRow` at `:190` |
| `network_health` | 84 | `_LegendEntry` = `Row(mainAxisSize: min, [dot, gap, AppText.labelSmall(label)])` with **no flex and no ellipsis** (`:424-431`); placed inside a centered `Row` (`:381-390`) whose label is the composed string `seriesAvgValuePeakValue(...)`. Only one of the three legend sites uses `Wrap` (`:305`). Tracked as "legend fix #1145/#1174" (`test/fixtures/known_overflows.json:3`). | `lib/page/dashboard/views/components/usp_network_health_card.dart:305,381-390,417-431` |
| `ethernet_ports` | 52 | `Expanded(LayoutBlock(Row[Container 40×40, AppGap.md, Column[titleSmall, bodySmall]]))` — the inner `Column` is a **non-flexible** `Row` child, so its widest unbounded text (`loc(context).connected` / `lanConnected`) sets the minimum width. Plus a `Wrap` of `_PortItem`s. | `lib/page/local_network/cards/usp_ethernet_ports_card.dart:58-107` (`Column` at `:94-103`), `Wrap` at `:112-116` |
| `stats_panel` | 26 | Every child **is** `Expanded` (`:44,52,60,68,76`) — yet it overflows, because the failure is one level down inside `StatTile`: `Row(mainAxisSize: min)` (`stat_blocks.dart:40-50`) and unconstrained `AppText.bodySmall(label)` (`:52-55`). 5 tiles in a 12-column card. | `lib/page/dashboard/views/components/usp_stats_panel.dart:42-84` + `lib/page/_shared/components/layout_blocks/stat_blocks.dart:33-58` |
| `time_settings` | 21 | `Row[Container 56×56, AppGap.lg, Expanded(Column[titleLarge(timeDisplay), Row[AppBadge(...)]])]` — the `Expanded` is present, but the inner `AppBadge` label is a localized status string in a bare `Row` with no shrink policy. Zero height handicap, so this is purely width. | `lib/page/admin/cards/usp_time_settings_card.dart:84-125` |

**The characterizing difference is a single pattern**: clean cards never place
unbounded localized text as a **non-flexible child of a `Row`**; overflowing cards
do, usually in legend/metric rows, and usually in a widget one level below the
card file (`_LegendEntry`, `StatTile`, `_TrafficLight`). `stats_panel` is the
clearest proof that "add `Expanded`" applied at the card level is not sufficient —
it already has `Expanded` everywhere and still overflows.

### 5.4 What a card author must therefore do today

Derived from the above (a description of the current de-facto burden, not a
recommendation):

1. Know that their card will be laid out under **tight** constraints on both axes
   from an integer span (`sliver_dashboard.dart:538`) with no negotiation.
2. Compute, by hand, the narrowest pixel width their declared `minColumns` yields
   across all 6 margin/column regimes — the grid formula lives in the view
   (`usp_sliver_dashboard_view.dart:324-325`), mirrored in
   `dashboard_card_probe.dart:89-102`. For `minColumns: 3` that is **191.4 px**
   (at screen 601), minus 32 px of `AppCard` padding = **159.4 px** of usable width.
3. Verify their content at that width in **all 26 locales**
   (`dashboard_card_overflow_test.dart:71-72` uses `AppLocalizations.supportedLocales`).
4. Add flex/ellipsis policy themselves at **every** `Row` level, including inside
   shared sub-widgets they did not author (`StatTile`, `_LegendEntry`).
5. If the card is tabbed, know that they get **no vertical scroll relief**
   (`dashboard_card_template.dart:277-279`) and must fit every tab within
   `h × 120 + (h−1) × 16` px.
6. Avoid, or hand-correct for, `context.colWidth(n)` inside a card, because it
   measures the screen and not the card (`layout_extensions.dart:99`).

Nothing in the framework tells them any of this, and nothing checks it.

---

## 6. Q6 — Edit-mode resize path

### 6.1 Entering and leaving edit mode

`dashboardEditModeProvider` (`lib/page/dashboard/providers/dashboard_edit_mode_provider.dart:10-13`)
snapshots the layout on entry (`:62-70`) and either commits (`:77`) or reverts by
re-importing the snapshot (`:93-99`). It carries **no size validation** — it is a
snapshot/revert mechanism only.

### 6.2 Live clamping during the drag — and a bypass

```dart
// sliver_dashboard-0.9.0/lib/src/controller/dashboard_controller_impl.dart:744-747
final maxW = originalItem.maxW.isFinite ? originalItem.maxW.toInt() : 10000;
final maxH = originalItem.maxH.isFinite ? originalItem.maxH.toInt() : 10000;
newW = newW.clamp(originalItem.minW, maxW);
newH = newH.clamp(originalItem.minH, maxH);
```

So **`minColumns` IS enforced as a hard floor at drag time** — but only until nine
lines later:

```dart
// dashboard_controller_impl.dart:754-756
if (newX + newW > slotCount.value) {
  newW = slotCount.value - newX;
}
```

This edge clamp runs **after** the `minW` clamp and is not itself re-clamped to
`minW`. Dragging an item's right edge while its `x` is near the grid edge can
therefore produce `w < minW`. Independently, `LayoutEngine.correctBounds`
(`sliver_dashboard-0.9.0/lib/src/engine/layout_engine.dart:743-766`) repositions
items (`x = cols - w`) and can force `w = cols`, but never shrinks `w` back up to
respect `minW`.

### 6.3 Post-hoc repair in the repo, with a user-visible error

The repo compensates after the gesture ends:

```dart
// lib/page/dashboard/views/usp_sliver_dashboard_view.dart:464-479
if (item.w < constraints.minColumns) { newW = constraints.minColumns; violated = true; }
if (item.w > constraints.maxColumns) { newW = constraints.maxColumns; violated = true; }
if (item.h < constraints.minHeightRows) { newH = constraints.minHeightRows; violated = true; }
if (item.h > constraints.maxHeightRows) { newH = constraints.maxHeightRows; violated = true; }
```

On violation it shows an **error-coloured SnackBar** (`:481-489`) and calls
`updateItemSize` (`:491-495`), which rebuilds the controller from a patched
layout (`usp_layout_controller.dart:139-162`).

**Can a user reach a size the card was never designed for? Yes, in three ways:**

1. **Transiently, during the drag** — `_handleResizeEnd` fires on
   `onItemResizeEnd` (`usp_sliver_dashboard_view.dart:339-341`), so every
   intermediate frame of an out-of-range drag is laid out and painted at the
   out-of-range size. `RenderFlex` reports overflow only once per render-object
   lifetime (`dashboard_card_probe.dart:318-322`), so a transient out-of-range
   frame can consume the one report and mask it later.
2. **Persistently via `scaleLayout` rounding** — the 12→8 path scales `minW` by
   `(minW * 8 / 12).round().clamp(1, 8)` (`usp_widget_specs.dart:381`). A
   `minColumns: 3` card becomes `minW = 2` on tablet, i.e. its floor is
   **relaxed** at the breakpoint where slots are narrowest (191.4 px at 601 px
   screen, §3.7). `_handleResizeEnd` then validates against the **unscaled**
   `constraints.minColumns` from the spec (`usp_sliver_dashboard_view.dart:457,464`),
   not against the scaled `minW` the controller is using — the two disagree.
3. **Persistently via the mobile path** — at ≤ 4 columns `scaleLayout` forces
   `newW = toCols` for every item (`usp_widget_specs.dart:366-369`), overriding
   `maxColumns` entirely. A `maxColumns: 8` card is shipped at `w = 4` of 4.

### 6.4 Is `preferredColumns` ever actually used?

Barely.

| Path | Uses `preferredColumns`? |
|---|---|
| Default layout (`createDefaultLayout` → `createLayoutForCards`) | **No.** Passes explicit `w: 12` for `stats_panel` (`usp_widget_specs.dart:430`) and `w: 6` for every other card (`:439`, `:448`), which short-circuits the `w ?? preferredColumns` fallback at `layout_item_factory.dart:47`. |
| `addWidget` (user adds a card) | **Yes** — calls `LayoutItemFactory.fromSpec` with no `w` (`usp_layout_controller.dart:185-190`), so `preferredColumns` decides. |
| `usp_dashboard_preset.dart:128` | Calls `fromSpec`; UNVERIFIED whether it passes an explicit `w` — would need to read `lib/page/dashboard/models/usp_dashboard_preset.dart` around `:120-140`. |
| Resize clamping | **No.** Only `minW`/`maxW` participate (`dashboard_controller_impl.dart:746`; `usp_sliver_dashboard_view.dart:464-471`). |

Note the consequence for the overflow data: since 12 of 18 cards declare
`preferredColumns: 6` and the default layout hardcodes `w: 6` anyway, the two
happen to agree for most cards — but `preferredColumns` is not the mechanism
producing that width. Meanwhile `h` **is** taken from `heightStrategy` on the
default path, since `createLayoutForCards` never passes `h`.

### 6.5 Declared constraint blocks (the shared-block observation, verified)

From `lib/page/dashboard/models/usp_widget_specs.dart`:

| Block | Cards | Line ranges |
|---|---|---|
| `min 3 / pref 6 / max 8` | `device_info`, `network_status`, `lan_info`, `ethernet_ports`, `system_status`, `connected_devices`, `time_settings`, `network_health`, `firewall_overview` — **9 cards** | `:41-43`, `:57-59`, `:87-89`, `:102-104`, `:117-119`, `:132-134`, `:177-179`, `:237-239`, `:252-254` |
| `min 4 / pref 6 / max 8` | `wifi_status`, `wifi_networks`, `dhcp_reservations`, `port_forwarding`, `wifi_performance` — **5 cards** | `:147-149`, `:162-164`, `:192-194`, `:207-209`, `:267-269` |
| `min 4 / pref 6 / max 12` | `topology`, `device_analytics`, `traffic_analysis` — **3 cards** | `:72-74`, `:222-224`, `:282-284` |
| `min 6 / pref 12 / max 12` | `stats_panel` — 1 card | `:25-27` |

**Correction to the supplied figures**: the counts are 9 + 5 + 3 + 1 = 18, not
"12 share min3/pref6/max8 and 4 more share min4/pref6/max8". The **9 cards** at
`min 3` include 6 of the 7 worst-overflowing cards; and note that `min 3 / max 8`
alongside `min 4 / max 8` differ only in the floor, yet the `min 3` group carries
the overwhelming majority of coordinates — consistent with the width-axis reading
in §3.6-3.7 (191.4 px vs 260.5 px narrowest realization).

---

## 7. Staleness flags against the 2026-03-23 architecture report

Every item below is a place where `doc/dashboard/dashboard_custom_layout_comprehensive_report_en.md`
(dated `:5`) is now contradicted by the code.

| # | Report claim | Report line | Current reality | Evidence |
|---|---|---|---|---|
| 1 | `HeightStrategy` lives at `lib/page/dashboard/models/height_strategy.dart` | `:103` | That file does not exist in the repo; the class lives in **ui_kit_library** | ui_kit `lib/src/models/height_strategy.dart:5-28`; imported via `package:ui_kit_library/ui_kit.dart` at `lib/page/dashboard/models/widget_spec.dart:1` |
| 2 | `WidgetGridConstraints` lives at `lib/page/dashboard/models/widget_grid_constraints.dart` | `:139` | Same — now in ui_kit_library | ui_kit `lib/src/models/widget_grid_constraints.dart:8` |
| 3 | "all **17** USP Dashboard card specs" + a 17-row table | `:194` | There are **18**; `wifi_networks` is the addition | `usp_widget_specs.dart:158-171`; `grep -c "^    id: '"` = 18; list at `:312` |
| 4 | "fixed slot height of **100px** per row" | `:194` | **120 px** | `usp_sliver_dashboard_view.dart:305`; the report contradicts itself at its own `:976` which says 120 |
| 5 | Intrinsic "falls back to `minHeightRows.clamp(2, 6)` **in Grid**" | `:991` | The clamp is in the **spec model**, evaluated before any grid exists; the grid never sees `heightStrategy` at all | `widget_grid_constraints.dart:72-73`; single-consumer grep §2.3 |
| 6 | `strict` described as a distinct strategy from `columnBased` ("Height remains constant in row units" vs "Height = Width × Multiplier") | `:988-989` | They are **the same class via redirecting factories**; `strict(n)` and `columnBased(n)` are indistinguishable at runtime | `height_strategy.dart:14-21,42-54` |
| 7 | `minColumns` is a "**Shrink Limit**. The widget width will never go below this value during user resize or responsive scaling" | `:970` | Both halves are violated: the drag-edge clamp can drive `w < minW` (`dashboard_controller_impl.dart:754-756`), and responsive scaling **reduces** `minW` itself (`usp_widget_specs.dart:381`) and forces full width at ≤4 cols (`:366-369`) | §6.2, §6.3 |
| 8 | `preferredColumns` is the "**Initial Width** … Base calculation width for layout generation" | `:972` | The default layout hardcodes `w: 12` / `w: 6` and never consults `preferredColumns`; it is used only by `addWidget` | `usp_widget_specs.dart:430,439,448`; `usp_layout_controller.dart:185-190`; §6.4 |
| 9 | `maxColumns` is a "**Grow Limit**" | `:971` | Overridden on mobile, where every item is forced to `w = toCols` regardless of `maxColumns` | `usp_widget_specs.dart:366-369` |

The report is **not** stale on: the provider/controller architecture, preset
system, persistence via SharedPreferences, or the general min/max-as-resize-bounds
intent. It is stale on file locations, card count, slot height, and on describing
declared constraints as guarantees.

---

## 8. Summary of mechanisms by which overflow is possible

| # | Mechanism | Axis | Citation |
|---|---|---|---|
| M1 | Cards receive `BoxConstraints.tightFor` from an integer span; no intrinsic negotiation, no assert | both | `sliver_dashboard.dart:510,538,556` |
| M2 | Grid neither clips nor expands; `SizedBox.expand` with `ClipRect` deliberately removed | both | `sliver_dashboard.dart:611-644`; `usp_sliver_dashboard_view.dart:545-548` |
| M3 | Unbounded localized text as a **non-flexible `Row` child**, often inside a shared sub-widget | width | `usp_system_status_card.dart:218-237`; `usp_network_health_card.dart:424-431`; `stat_blocks.dart:40-55`; `usp_ethernet_ports_card.dart:94-103` |
| M4 | `context.colWidth(n)` measures **screen** width, not card width | width | ui_kit `layout_extensions.dart:76-107` esp. `:99` |
| M5 | Grid gutter is hardcoded 16 px while `colWidth` uses the responsive gutter (20/24 above 905 px) | width | `usp_sliver_dashboard_view.dart:363-364`; `app_spacing.dart:9`; `app_layout_config.dart:90-100` |
| M6 | Tabbed cards get **no** scroll relief; 6 of 18 cards are tabbed | height | `dashboard_card_template.dart:277-279`; `dashboard_card_probe.dart:221-228` |
| M7 | Template protects only the header title; `titleBadge`, `trailing`, section titles are unprotected | width | `dashboard_card_template.dart:243-257,326-334` |
| M8 | Fixed-height footer always reserved even when empty | height | `dashboard_card_template.dart:413-428` |
| M9 | `heightStrategy` never reaches a render object; `intrinsic()` is a constant-rows formula, not intrinsic sizing | height | `widget_grid_constraints.dart:66-75`; single-consumer grep §2.3 |
| M10 | No assert / debug check / lint validates that a declared size can hold real content | both | `widget_grid_constraints.dart:34-38`; empty `analysis_options.yaml:27`; no `assert(` in `lib/page/dashboard/` |
| M11 | Drag-edge clamp can drive `w` below `minW`, bypassing the min clamp | width | `dashboard_controller_impl.dart:746` then `:754-756` |
| M12 | Responsive `scaleLayout` **lowers** `minW` at the tablet breakpoint where slots are narrowest, and ignores `maxColumns` on mobile | width | `usp_widget_specs.dart:366-382` |
| M13 | Overflow is silently clipped by `AppSurface`'s `Clip.antiAlias` in release builds — no user-visible error, just missing content | both | ui_kit `app_surface.dart:222-231` |
| M14 | 560 coordinates ship overflowing by allowlist policy | both | `test/fixtures/known_overflows.json:5-73` |

---

## 9. Open questions / what this document does not answer

1. **Per-coordinate axis attribution.** The 315/135/110 breakdown was supplied
   pre-aggregated. Attributing each of the 560 coordinates to `right` vs `bottom`
   individually would require the report generator's collected
   `OverflowIncident.side` values (`test/util/overflow_probe.dart:15`), obtainable
   only by running the gate with `DUMP=1`
   (`dashboard_card_overflow_test.dart:131-158`) — explicitly out of bounds here.
   The width-dominance conclusion (§3.5) rests on the classifier's structure
   (`dashboard_overflow_report_generator.dart:66-73`), which is sound but coarser
   than per-incident data.

2. **How much of the strict-card overflow survives at production height.** §3.3
   shows 9 of 11 strict cards are pumped 136 px short. Re-pumping them at
   `getPreferredHeightCells` rows instead of `minHeightRows` would separate
   "genuine height overflow" from "gate handicap". Not done (would require running
   the suite).

3. **Whether the "clean" cards actually render populated content.**
   `kitchenSinkOverrides()` (`test/util/dashboard/kitchen_sink_overrides.dart:19-37`)
   feeds 14 fixture providers, and its own docstring at `:14-15` concedes cards
   reading unlisted providers "still build fine … when its own provider is left at
   default". If `topology`, `wifi_status`, `dhcp_reservations`, or `wifi_networks`
   render empty/placeholder bodies under this harness, their zero counts would be
   partly artifactual. Determining this requires cross-referencing each card's
   watched providers against `cardOverrides`' parameter list — UNVERIFIED.

4. **`usp_dashboard_preset.dart:128`** — whether it passes an explicit `w` to
   `LayoutItemFactory.fromSpec`, which determines whether `preferredColumns` has a
   second live consumer (§6.4). Would need `lib/page/dashboard/models/usp_dashboard_preset.dart:120-140`.

5. **Whether `DashboardOverlay`'s resize feedback path applies different
   constraints** than `RenderSliverDashboard`. `dashboard_overlay.dart:262` sets
   `Clip.none` and `dashboard_feedback_widget.dart:115` adds a `ClipRect`, but the
   full overlay layout path was not traced. UNVERIFIED whether a card can be laid
   out at a *different* size during an active drag than the grid would give it.

6. **Real-device behaviour of M13.** That `AppSurface` sets
   `clipBehavior: Clip.antiAlias` is verified from source; that this results in
   silently truncated content in a release web build is a reasonable inference but
   was not visually confirmed.

7. **The skipped breakpoint frame (§2.5).** Whether returning
   `SizedBox.shrink()` for one frame (`sliver_dashboard.dart:122-123`) causes cards
   to be disposed and re-created — and therefore to get a **fresh** overflow
   report on the next frame — was not traced through `collectGarbage`
   (`sliver_dashboard.dart:484`).

8. **sliver_dashboard 0.9.1.** Present in the pub cache, deliberately not read.
   Whether it changes `performLayout`'s constraint construction is unknown.
