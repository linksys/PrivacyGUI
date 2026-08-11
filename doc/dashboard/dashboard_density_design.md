# Dashboard Card Density — Design Decisions

**Last Updated: 2026-08-11** · Follow-up to #1183 · Status: **agreed, not yet implemented**

## Purpose

The #1183 overflow gate established a measured baseline of **560 overflowing
coordinates** (36 allowlist keys) across 13 of 18 dashboard cards. This document
records how they are to be eliminated: the measurements the plan rests on, the
decisions taken, and — deliberately — the alternatives that measurement ruled
out.

**Companion documents**

| Document | Role |
|---|---|
| [dashboard_framework_overflow_investigation.md](dashboard_framework_overflow_investigation.md) | How the framework turns a spec constraint into a real `BoxConstraints`. Its data-flow mapping is the reference; several of its inferences are superseded here (it carries a pointer). |
| [dashboard_custom_layout_comprehensive_report_en.md](dashboard_custom_layout_comprehensive_report_en.md) | Architecture, providers, persistence, presets. |
| [.claude/skills/dashboard-overflow-gate/SKILL.md](../../.claude/skills/dashboard-overflow-gate/SKILL.md) | How to operate the gate and edit the allowlist. |

---

## Part 1 — Measurements

Everything in Part 2 rests on these. They were produced by temporary harnesses
run against the real card widgets with real fonts, then deleted; each is
reproducible from the method described.

### 1.1 Attribution — 560 coordinates come from 32 source sites

**Method.** The gate's `OverflowIncident.fullLog` retains the full
`FlutterErrorDetails`, which names the error-causing widget **and its creation
location**. A harness re-ran the full sweep (card × narrowest-realization width ×
tab × 26 locales) and parsed that location from every incident.

**Result.** 998 incidents → **560 distinct coordinates**, matching the committed
baseline exactly. All 998 resolved to a source location; none were unattributable.

**By layer that must be modified:**

| Layer | Coordinates | Share |
|---|---:|---:|
| Card's own code only | 379 | 68% |
| `lib/page/_shared/` only | 101 | 18% |
| Card + shared | 35 | 6% |
| Card + shared + ui_kit | 26 | 5% |
| Third-party only (fl_chart) | 19 | 3% |

> This **refutes** the investigation document's inference that the failing
> pattern lives below the card layer. It is predominantly card-own code. The
> batching strategy still holds, but on a different basis: the real leverage is
> that 560 coordinates reduce to **32 sites**.

**Highest-leverage sites** (greedy cover — coordinates *fully* cleared, i.e. all
of that coordinate's incidents resolved):

| # | Site | Clears | Cumulative |
|---:|---|---:|---:|
| 1 | `lib/page/_shared/components/layout_blocks/metric_blocks.dart:31` | 58 | 10% |
| 2 | `lib/page/dashboard/views/components/usp_traffic_analysis_card.dart:258` | 49 | 19% |
| 3 | `lib/page/wifi_settings/cards/usp_wifi_performance_card.dart:190` | 33 | 25% |
| 4 | `lib/page/firewall/cards/usp_firewall_overview_card.dart:237` | 31 | 31% |
| 5 | `lib/page/dashboard/views/components/usp_system_status_card.dart:314` | 28 | 36% |
| 6–8 | `usp_network_health_card.dart:143`, `:424`, `:381` | 81 | 50% |
| … | 22 sites total | 474 | 85% |
| … | 27 sites total | 508 | 91% |

The remaining 52 coordinates need **multiple sites fixed together** (a coordinate
only goes green when every one of its incidents is resolved):

- **`stats_panel` — 26**: `stat_blocks.dart:34` **and** `:40`
- **`connected_devices` — 26**: `card_skeleton.dart:153` **and**
  `usp_connected_devices_card.dart:61` **and** ui_kit `app_list_tile.dart:109`

**Blocked on a dependency we do not own — 45 coordinates (8%)**: fl_chart 19
(`firewall_overview`), ui_kit `AppListTile` 26 (`connected_devices`).

**Axis split**: 464 right-only, 63 bottom-only, 33 both.

### 1.2 Fit width — the narrowest width at which each card is clean

**Method.** Card width was driven directly through a 14-rung ladder
(191 → 1216px) for every (card, tab, locale), holding the screen at 1920px.
Overflow is monotonic in width, so the narrowest clean rung is that case's fit
width. 624 cases; **every one is clean at some width** — no card is broken
independent of width.

`fit width` below is the **worst locale × worst tab** for that card.

| Card | Declared min → px | Fit width | Gap |
|---|---:|---:|---:|
| `stats_panel` | 6 → 288 | **760** | +472 |
| `traffic_analysis` | 4 → 260 | **560** | +300 |
| `device_info` | 3 → 191 | **480** | +289 |
| `lan_info` | 3 → 191 | **420** | +229 |
| `wifi_performance` | 3 → 191 | **420** | +229 |
| `ethernet_ports` | 4 → 260 | **420** | +160 |
| `network_health` | 4 → 260 | **420** | +160 |
| `firewall_overview` | 3 → 191 | **360** | +169 |
| `system_status` | 4 → 260 | **360** | +100 |
| `connected_devices` | 4 → 260 | **320** | +60 |
| `network_status` | 3 → 191 | **320** | +129 |
| `port_forwarding` | 3 → 191 | **320** | +129 |
| `time_settings` | 3 → 191 | **288** | +97 |

⚠️ **`system_status`'s 360px is an underestimate.** It reads
`context.colWidth` (screen-derived), and the harness held the screen at 1920px,
so its label column did not shrink with the card. Its threshold must be set only
after that is fixed — see §2.8.

### 1.3 Raising `minColumns` is arithmetically impossible for 12 of 13 cards

At a 320px screen the grid is 4 columns with 16px margins, so **the entire
12-column grid is only 288px wide**. Therefore "widen the card until the content
fits" has no solution for any card whose fit width exceeds 288px:

| Card | Needed `minColumns` |
|---|---|
| `time_settings` (fit 288) | 3 → **5** — possible |
| All other 12 cards | **> 12 — impossible** |

> This is the quantified form of the constraint that drove this design: for 12 of
> 13 cards, no column count exists that fits the content. Graceful degradation is
> not the preferred option; it is the **only** option.

### 1.4 A single global threshold cannot make the set safe

| Threshold | Cases still overflowing | Cards |
|---:|---:|---:|
| 320px | 78 / 624 | 9 |
| 360px | 48 / 624 | 7 |
| 420px | 15 / 624 | 3 |
| 480px | 6 / 624 | 2 |
| **760px** | **0** | 0 |

Zero overflow via one global number requires T = 760px (`stats_panel`'s fit
width), which would put nearly every card into the degraded form at nearly every
width — abolishing the normal form in practice. Hence per-card thresholds (§2.4).

### 1.5 Column count is a lossy proxy for card width — 2.2× distortion

Card width is a function of **both** span and screen width. Measured over the
grid's own formula:

| Span | Narrowest | Widest | Ratio |
|---:|---:|---:|---:|
| 3 | 191.4px | 422.0px | **2.20×** |
| 12 | 288.0px | 1216.0px | 4.22× |

The breakpoint edge is the sharpest case: a 3-column card is **422px at a 600px
screen and 191.4px at a 601px screen** — a 1px screen change costs the card 55%
of its width, while its column count is unchanged.

Worse, ordering does not even hold: there are **433 (span, screen) inversions**
where a *wider* span yields a *narrower* card, e.g. span 4 @ 360px = 328px is
wider than span 12 @ 320px = 288px.

> Column count is therefore unusable as a density threshold. This refutes the
> initial recommendation to use it, which had argued that px thresholds would
> produce meaningless differences at breakpoint edges — the opposite is true.

### 1.6 The 191px "floor" was a sampling artifact

`dashboard_card_probe.dart:154` scans a **hand-written list of 19 screen widths**
(minimum 320). 191.4px is the narrowest value in that sample, not the geometric
minimum. An exhaustive 1px sweep (240–2560px) gives:

| Span | True narrowest | At screen |
|---:|---:|---:|
| 3 | **152.0px** | 240px |
| ≥ 4 | **208.0px** | 240px (clamped to full grid) |

The list also omits 240–319px entirely and real device widths 375 / 390 / 430px.
Consequences: the gate under-measures (§2.7), and the contract floor is a product
decision rather than a geometric fact (§2.3).

Counter-intuitively, **mobile is not the narrowest case**: a 3-column card is
212px at a 320px phone but 191.4px at a 601px tablet.

### 1.7 The default layout is clean at most widths — normal survives as primary

Presets use `w: 6` (`w: 12` for `stats_panel`). Share of screen widths
320–2560px at which the **default** layout is clean:

| Card | Clean |
|---|---:|
| `time_settings` | 100% |
| `network_status`, `connected_devices`, `port_forwarding` | 98.6% |
| `system_status`, `firewall_overview` | 96.8% |
| `lan_info`, `ethernet_ports`, `network_health`, `wifi_performance` | 92.1% |
| `stats_panel` | 77.5% |
| `device_info` | 73.2% |
| **`traffic_analysis`** | **40.6%** |

The 560 coordinates are overwhelmingly **not** on the default layout — the gate
measures each span's *narrowest realization*, which is reached by manual resize
or a narrow screen. This is what makes "normal is the primary form" viable.

Two genuine breaks in that claim:

1. **`traffic_analysis` at 40.6%** — it needs 560px, but `w: 6` yields only
   512px at a 1024px screen and 496px at 1440px. Mainstream desktop widths
   overflow on the default layout. (Cause: desktop page margins of 200/256/352px
   — see Deferred D1.)
2. **A 320px phone overflows on 12 of 13 cards** on the default layout, because
   `w: 6` clamps to the 4-column grid = 288px. (See Deferred D2.)

### 1.8 Bottom-axis overflow is a secondary effect of width

96 coordinates involve the bottom axis (63 pure, 33 both), in 3 cards:
`firewall_overview` 67, `stats_panel` 26, `network_health` 3.

At the widest rung (1216px), **0 of 624 cases still overflow on the bottom**.
Bottom overflow is text rewrapping taller because it was squeezed, not an
independent height problem. In 40 cases the bottom axis is the *last* to clear,
so a threshold derived from right-overflow alone would be set too low.

### 1.9 `AppDialog` width is theme-overridable

`app_dialog.dart:167` — `maxWidth: effectiveDialogStyle?.maxWidth ?? 400.0`.
The 400px default is a default, not a ceiling: it is overridable via
`DialogStyle` and per-call `style`. **No ui_kit change is needed** to widen a
popup. (An earlier claim that 400px was a hard cap, and therefore that popups
could not reuse the normal form, was wrong.)

---

## Part 2 — Decisions

### 2.1 Three density forms, automatically selected

| Form | When | Content |
|---|---|---|
| **popup** | card width < **200px** | Icon + a single value (or the minimum meaningful cell). Tapping opens the **normal** form in a dialog. |
| **compact** | 200px ≤ width < card's `normalAbove` | Simplified / reduced information. |
| **normal** | width ≥ card's `normalAbove` | Full content. **The primary form.** |

Selection is **automatic from the card's real pixel width**. It is not a user
preference: the width is already the consequence of a user action (resizing the
card, or the screen they are on), so requiring a second, separate choice to avoid
broken layout would push the framework's responsibility onto the user.

`UspLayoutPreferences.setMode()` / `getMode()` become unused for this purpose.

**Why three and not two.** popup has a natural lower bound that is independent of
width (an icon and one value always fit). That terminates the otherwise infinite
regress of "and what guarantees the compact form fits?".

**popup reachability.** Only `span=3` ever falls below 200px (191.4px, at screens
601–1247px — 30 widths). `span≥4` is never narrower than 260.5px. So popup is a
safety net for *manual shrinking on tablet/desktop*, and **never triggers on a
phone** (a 320px phone's 3-column card is 212px). Reaching phones would require a
threshold ≥ 212px. **200px stands, and is open to revision.**

**popup content is the normal form** (§1.9): dialog `maxWidth` is set to
`min(screenWidth − inset, card's fitWidth)`. For screens ≥ 600px this reuses
normal for every card except `stats_panel`. Where a phone cannot fit it, use a
fullscreen sheet — the correct mobile interaction anyway. Horizontal scrolling
inside the popup is rejected: it converts overflow from an error into a feature
and blinds the gate.

### 2.2 The threshold is measured in pixels, never columns

Per §1.5: 2.2× distortion within one span, 433 ordering inversions, and a 55%
cliff at the breakpoint edge. Cards read their real width (via `LayoutBuilder` or
the injected value of §2.6). Screen-derived helpers — `context.colWidth`,
`currentMaxColumns` — are explicitly **not** valid inputs; that mismatch is a
known bug (§2.8).

### 2.3 The absolute contract floor is a product decision: 320px minimum screen

Geometry alone permits a 152px card (§1.6), but no shipping device is 240px wide.
Rather than design every popup form to survive a width no user has, the framework
**declares a minimum supported screen width of 320px**, from which the floor
follows. This is an explicit product commitment, not a side effect of a test's
scan list.

> Revisit if narrower targets appear (automotive head units, embedded panels).

### 2.4 `normalAbove` is per-card, declared on `WidgetSpec`, defaulting to absent

One number per card. It lives on **`WidgetSpec`** (this repo,
`lib/page/dashboard/models/widget_spec.dart`) — **not** on
`WidgetGridConstraints`, which is in `ui_kit_library` and cannot be changed
unilaterally (constitution Article XIV).

**Default is absent, not a number.** A spec that declares no threshold asserts
"this card does not need a degraded form", and the gate then requires it to be
clean at its own narrowest realization. That is entirely reasonable for a simple
card. Once it does not fit, the author is forced into an explicit decision. A
numeric default would make "considered and not needed" indistinguishable from
"never considered".

**Thresholds are set to the worst-locale fit width** (§1.2), not per-locale. A
1.9× spread between English and Finnish for the same card is a symptom — usually
a label missing `ellipsis` — and encoding it as 13×26 = 338 constants would
freeze the bug and require re-measurement on every new locale. Instead the
threshold is one maintainable number, and the way to lower it is to fix the
layout. `fitWidth` dropping from 480 to 320 is then measurable progress.

**Thresholds are a design decision, validated by the gate — not derived from
it.** Deriving them from measured fit width would let a test dictate runtime
behaviour: adding a locale could shift a threshold and silently change what users
see. The declared number states intent; the gate enforces
`normalAbove >= fitWidth`.

**The threshold covers both axes.** Bottom overflow disappears entirely at
sufficient width (§1.8), so it is a width symptom. Compensating with
`minHeightRows` would treat the symptom — the card gets taller while the text
stays crushed — and height is user-resizable anyway.

### 2.5 Each card chooses its own degradation technique

The compact contract is exactly one clause: **does not overflow at its
threshold width**. How information is shed is the card's own design choice.

`stats_panel` demonstrates why: it is five `Expanded` `StatTile`s in a `Row`
(`usp_stats_panel.dart:41`), so a 760px fit width means 145px per tile. Its
natural degradation is **wrapping to multiple rows**, which keeps all five
values — strictly better than hiding two of them for the sake of a uniform rule.

### 2.6 Density is injected via Provider, not threaded as a parameter

`UspWidgetFactory.buildWidget(String id)` takes no mode parameter, so it cannot
carry density today. Density will be provided by the card container and read
through context.

Rationale is **testability plus reach**: over half of the 32 sites are nested 3–4
levels below the card root (`MetricTile`, `_LegendEntry`, list rows). Threading a
parameter would push density into every leaf's signature — `MetricTile(mode:)` is
a change that cannot be walked back, and the same block is shared by 12 cards
that want different things from it. Injection also lets the gate override density
to test a specific form, exactly as it already pins tabs via
`cardTabIndexProvider` rather than tapping.

Leaf blocks (`MetricTile`, `StatTile`, …) **do not receive density**. They are
made unconditionally overflow-safe (`Flexible` / `maxLines` / `ellipsis`);
choosing *which elements to show* stays with the card. Two clean
responsibilities: blocks guarantee "I never overflow", cards decide "what is
worth showing at this width".

Per Article XIV, adding `Flexible`/`maxLines` to an existing block is a bug fix.
Should a genuinely new shared widget emerge (e.g. `OverflowSafeRow`), it must go
through the UI Kit proposal path.

### 2.7 The gate enumerates widths instead of sampling them

`_scanScreens`'s hand-written 19-width list violates the gate's own stated
invariant that "narrowest realization = worst case" (§1.6). It will be replaced
by an exhaustive search for each span's true narrowest realization, keeping the
current one-case-per-span reduction.

The frozen-geometry warning in `SKILL.md` applies to the **formulas** — which
mirror production and must not change — not to the sample list.

This will shift the 560 baseline. That shift is itself the information: it
quantifies how much the current baseline under-measures — which is why it goes
**first**, before anything that eliminates coordinates (see Part 4).

### 2.8 `system_status`'s `colWidth` bug is fixed before its threshold is set

`usp_info_row.dart:29` uses `context.colWidth(labelColumns)`, which is
screen-derived, so the label column does not shrink when the card does. Its
measured 360px fit width is therefore an underestimate (§1.2), and it is the
largest single card in the baseline at 85 coordinates.

Fix by reading the real available width (`LayoutBuilder`), **not** by introducing
`PageLayoutScope`: `usp_info_row.dart` has exactly one consumer, so a scope
wrapper is disproportionate. Then re-measure, then set the threshold.

### 2.9 The existing gate is the validation mechanism

No new test harness. The #1183 gate already asserts precisely the required
property — "every card, at its declared narrowest realization, across every tab
and locale, does not overflow" — and the 560 coordinates are its list of
failures. Once density is wired, removing a coordinate from the allowlist and
having it pass **is** the evidence.

This closes the gap the investigation identified: nothing validated a declared
size against real content. A second harness would duplicate the pump matrix and
drift on the geometry constants; a constructor assert can only check number
consistency, which is exactly what is already checked and exactly what is not
enough.

Raising `minColumns` is therefore not allowlisting in disguise: with §2.9 in
place it becomes a testable assertion that the card fits at N columns, recorded
in the spec with its rationale (both the number and the note are required).

### 2.10 `traffic_analysis` is a normal-form bug, not a compact case

It overflows on the **default** layout at 1024px and 1440px — mainstream desktop
widths (§1.7). Sending mainstream desktop users to a degraded form would mean
normal is not the primary form. All 49 of its coordinates are at a **single
site** (`usp_traffic_analysis_card.dart:258`), the second-highest-leverage fix in
the whole set. Fix the layout; do not raise its default span, which would squeeze
neighbouring cards and still leave manual shrinking broken.

### 2.11 fl_chart's 19 coordinates get a primary plan and a documented fallback

`firewall_overview`'s 19 coordinates originate inside fl_chart
(`side_titles_widget.dart:245` — axis labels overflow at narrow widths).

- **Primary**: constrain at the call site — suppress axis labels below the
  threshold, as part of that card's compact design. Reducing information density
  at narrow width is a legitimate design choice, not a workaround.
- **Fallback**: if it still overflows once labels are off (fl_chart may contain
  other unconstrained `Row`s), it is reclassified as a deferred dependency item
  and stays allowlisted with a tracking note.

The fallback is written down deliberately: this is the one fix whose *method can
fail*, and without a stated exit someone will reach for the allowlist mid-fix.
Forking or patching the dependency is rejected — a vendored patch dies silently
on the next upgrade.

---

## Part 3 — Deferred

Agreed as real, explicitly out of scope here.

### D1 — Desktop page margins make bigger screens yield narrower cards

`AppLayoutConfig.margin` returns 200 / 256 / 352px above 1240 / 1440 / 1680px.
Consequently a card at a 1240px screen is **narrower** than the same card at
905px (margin jumps 24 → 200), and `w: 6` yields only 512px at 1024px and 496px
at 1440px — the direct cause of §1.7's `traffic_analysis` break.

Large margins exist to bound **text line length**. A dashboard's unit of content
is the card, whose line length is already bounded by the card, so the rationale
does not transfer — it just discards 400–704px of usable width. A dashboard-local
margin (`usp_sliver_dashboard_view.dart:322` currently uses
`context.pageMargin`) would not require a ui_kit change.

Likely the cheapest remaining lever on the baseline; needs quantifying before
claiming a figure.

### D2 — No mobile preset

All three presets are 12-column layouts, applied unchanged on phones, so `w: 6`
clamps to 288px and 12 of 13 cards overflow on the default layout at 320px
(§1.7). A single-column mobile preset (`w: 4`, full 288px) would fix
`time_settings` outright and bring `network_status` / `connected_devices` /
`port_forwarding` (320px) close.

### D3 — The 200px popup threshold

Agreed as a starting value. It makes popup a tablet/desktop safety net that never
triggers on phones (§2.1); a phone-reaching threshold would need ≥ 212px.

---

## Part 4 — Order of work

**Instruments before measurements.** Two changes *raise* the baseline (the gate
enumerating widths; fixing `colWidth`, after which `system_status`'s label column
finally shrinks with the card) and every subsequent change *lowers* it. Interleave
them and the deltas cancel, leaving no way to attribute a shift to the change that
caused it. So both re-baselining steps land first, each committed on its own.

1. **Gate enumerates widths** (§2.7) — test-only, so the entire baseline shift is
   attributable to the instrument.
2. **`system_status` `colWidth` fix** (§2.8) — expected to raise its count;
   unblocks its threshold. 85 coordinates, the largest single card.
3. **`traffic_analysis:258`** (§2.10) — 49 coordinates at one site; the first
   *elimination*, and the only card broken at mainstream desktop widths.
4. **Blocks made overflow-safe** (§2.6) — `metric_blocks.dart:31` alone clears
   58; `stat_blocks.dart:34`+`:40` clears 26 more.
5. **Density plumbing** (§2.1, §2.6) — Provider injection, `normalAbove` on
   `WidgetSpec`, form selection.
6. **Per-card thresholds and compact forms**, batched by site (§1.1).

Steps 1–3 are independent of the threshold values: fit width is a property of card
content, measured by driving card width directly, so it does not depend on grid
margins or the scan list. Only *which screen widths reach a threshold* depends on
those.

### How each step is verified

The steps do not share a single verification method, and treating them as if they
did is the likeliest way to get this wrong.

| Steps | Method | Why |
|---|---|---|
| 3, 4, 6 | **Ratchet, not TDD** | The failing assertions are *already committed* — the 560 entries in `known_overflows.json`. The red→green move is: fix the layout, delete the allowlist entry, gate passes. Deleting an entry that still overflows fails that test, so it cannot be faked. |
| 5 | **TDD** | The gate asserts only "no overflow"; it cannot detect *wrong density*. Threshold selection, popup cut-off, and absent-`normalAbove` behaviour can all be broken while the gate stays green. These need tests written red first. |
| 1, 2 | **Neither** | Re-measurement, not assertion. There is no "should pass" to write — the output is a new baseline, reviewed as a number. |

The gate does **not** need to know a card's measured fit width to enforce
§2.4's `normalAbove >= fitWidth`: it applies the density rule at the card's
narrowest realization and pumps. A threshold set too low leaves the card in the
normal form at a width where it overflows, and the gate fails on that. No
fit-width measurement harness needs to exist at runtime or in CI.
