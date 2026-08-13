# Dashboard Card Density — Design Decisions

**Last Updated: 2026-08-13** · Follow-up to #1183 · Status: **agreed; tickets #1225–#1240 published; #1225 + #1226 + #1233 + #1227 + #1228 + #1229 implemented (not yet merged), rest not started. Allowlist 560 → 181.**

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

#### The largest pattern the greedy cover hides — legend rows, 181 coordinates

Ranking sites individually is the wrong lens for one group. **Seven rows across
three files are the same shape** — a centred `Row` of colour dot, gap, and
unconstrained label — and together they are **181 coordinates, 32% of the whole
baseline**, three times the top shared-block site:

| Card | Sites | Coordinates |
|---|---|---:|
| `network_health` | `:143`, `:381`, `:424` | 81 |
| `system_status` | `:314`, `:378`, `:464` | 51 |
| `traffic_analysis` | `:258` | 49 |

The greedy table above scatters these across ranks 1–16, so the pattern is
invisible there. It is one fix replicated seven times, and it is where the
batching leverage actually is.

> Re-measured during #1233 and confirmed: the six #1233 sites clear exactly 132
> coordinates. Note the counting convention — those two cards carry **169**
> allowlisted coordinates between them, but 37 of those also have incidents at
> non-legend sites, so they stay allowlisted until #1234/#1235 land. "Clears" here
> means *fully* cleared, as in the greedy table above.
>
> The sweep also found an **eighth** row of this shape that the table omits:
> `usp_system_status_card.dart:218`, the Monitor tab's legend row, in 28
> coordinates. It is not a #1233 site — it is one of the three #1234 clears
> ("a legend-adjacent row on the first tab"), and #1234's 34 = `:196` (26) +
> `:118` (8) + `:218` where those are the coordinate's only remaining cause. So
> the pattern is really eight rows, and #1234 finishes it.

> Re-measured again during #1229: `wifi_performance`'s two sites (`:190` Signal,
> `:275` Speed) are this same shape, and they are that card's **entire** 45
> coordinates. So the pattern is **ten rows across four files, 181 + 45 = 226
> coordinates — 40% of the whole baseline** (not to be confused with the
> allowlist standing at 226 just before #1229; the two numbers coincide by
> accident), and it is the only structure in this epic that
> accounts for a plurality of it. §1.1's greedy table hides `:275` as well as the
> other nine: it credits `:190` with 33 and never names the Speed tab at all
> (see §2.10b for why a "×2 sites" ticket still needs its own attribution run).

The private colour-dot widget is additionally duplicated **verbatim in five
files** (the three above plus `device_analytics` and, per #1229,
`wifi_performance`). De-duplicating it, or extracting a shared legend entry,
would be a **new shared widget** and therefore needs approval under Article XIV —
so the fix is applied in place, and the extraction raised separately rather than
blocking on that conversation. That raise is **#1245**, filed after #1233; it
carries the constraint #1233 measured, namely that any shared entry must express
the ellipsize-vs-soft-wrap distinction per label kind (§2.10a point 2) and must
not absorb the WAN/LAN row, which deviates for a reason (§2.10a point 3).
**#1245's inventory is written against four files and needs `wifi_performance`
added to it.**

**Blocked on a dependency we do not own — 45 coordinates (8%)**: fl_chart 19
(`firewall_overview`), ui_kit `AppListTile` 26 (`connected_devices`).

**Axis split**: 464 right-only, 63 bottom-only, 33 both.

#### Track A's four remaining card-own tickets reduce to four shapes across six sites (#1234–#1237, measured before implementation)

**Method.** §1.1's `fullLog` attribution, re-run at per-line resolution over the
four cards of #1234 / #1236 / #1237 (`system_status`, `lan_info`, `device_info`,
`time_settings`). 112 incidents → the 84 allowlisted coordinates those three
tickets own; adding #1235's 3 makes 87.

| Shape | Sites | Worst | Tickets |
|---|---|---:|---|
| "View details" footer — `AppDivider` + `Row(mainAxisAlignment: end)` + `Semantics`/`InkWell` | `usp_system_status_card.dart:118`, `usp_device_info_card.dart:140` | +5.2px | **#1234 + #1236** |
| Hero inner row — `Row` inside `Expanded(Column(start, [titleLarge, AppGap.xxs, Row]))` | `usp_lan_info_card.dart:56`, `usp_time_settings_card.dart:108` | +102 / +67px | **#1236 + #1237** |
| Twin gauges — `Expanded(Row(spaceEvenly, [AppGauge(size: 100) ×2]))` | `usp_system_status_card.dart:196` | +43px | #1234 |
| Legend row — `_LegendDot` ×2 + `Spacer` + refresh chrome | `usp_system_status_card.dart:218` | +107px | #1234 |

**Two of the four shapes straddle ticket boundaries.** The footer is
near-identical code in two files (`_buildStatisticsFooter` / `_buildNodeDetailFooter`),
and the hero inner row is the same idiom in two more — and that idiom alone is
**48 of the 84 coordinates**. Split across separate branches, each shape gets its
fix invented twice and #1245's de-duplication inventory grows by two more entries.
This is the #1249 situation again (§2.10a), so the four are best done as one
branch with a commit per shape.

**`system_status`'s 26 widest coordinates have two causes each, so neither site
clears them alone.** The exact decomposition of #1234's 34:

- `min|0` tab 0, all 26 locales — caused by **both** `:196` and `:218`; `el`/`ru`
  additionally by `:118`
- `min|0` tabs 1–3, `el`+`ru` — 6, `:118`
- `preferred|0`, `fr`+`fr_CA` — 2, `:218`

So `:196` alone clears 0 and `:218` alone clears 0; the pair clears 26; adding
`:118` clears all 34. Expect zero allowlist movement until both gauge-row and
legend-row fixes are in — the same trap §2.6a's shared-plus-card-own coordinates
set, one file down.

**`AppGauge`'s centre is fixable at the call site — no ui_kit change, so no
Article XIV question.** `AppGauge` renders
`SizedBox(width: size, height: size, child: Stack(alignment: center, children: [CustomPaint, …, centerBuilder(…)]))`.
The centre is a *non-positioned* `Stack` child, so it receives loose `size × size`
constraints and the overflowing `Column(mainAxisSize: min, …)` is the app's own
closure. This holds for both #1235's `network_health` gauge (`size: 120`) and
`system_status._buildGauge` (`size: 100`), which is why #1235's 3 coordinates are
a cheap add-on to #1234 rather than a separate ui_kit conversation.

> Sequencing note: these four tickets, #1229 and #1266 all edit
> `test/fixtures/known_overflows.json` and this file. Until #1229/#1266's PR
> merges, branch the four-ticket work from *its* head rather than from the epic
> gate branch, or the fixture conflicts.

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

> **Superseded by #1225** (implemented; not yet merged). The probe now enumerates the supported range
> (`narrowestRealizationOf`, 320–2560px) instead of scanning a list. The
> measurements below are what justified that change and are kept as its record;
> the no-op claim they predicted was confirmed on the full sweep — 560
> coordinates across 36 keys, byte-identical before and after.

`dashboard_card_probe.dart` used to scan a **hand-written list of 19 screen
widths** (minimum 320). 191.4px is the narrowest value in that sample, not the
geometric minimum. An exhaustive 1px sweep (240–2560px) gives:

| Span | True narrowest | At screen |
|---:|---:|---:|
| 3 | **152.0px** | 240px |
| ≥ 4 | **208.0px** | 240px (clamped to full grid) |

The list also omits 240–319px entirely and real device widths 375 / 390 / 430px.
The contract floor is therefore a product decision rather than a geometric fact
(§2.3).

**But the sample is not actually lossy above 320px.** Compared against an
exhaustive 320–2560px sweep, the 19-screen list finds the *identical* narrowest
width for **every one of the 12 spans**:

| Span | Sampled min | Exhaustive min | Δ |
|---:|---:|---:|---:|
| 1–4 | 53.1 / 122.2 / 191.4 / 260.5 @ 601px | same | **0.0** |
| 5–12 | 288.0 @ 320px | same | **0.0** |

The omitted widths are nobody's worst case: 375 / 390 / 430px all sit inside the
4-column low-margin band where 320px already dominates. So replacing the sample
(§2.7) bought a **guarantee, not a new baseline** — confirmed as a behavioural
no-op when #1225 was implemented.

**Where the sample *was* lossy: a raised floor.** With `MIN_SCREEN=602` the list
held nothing in 602–904, so it fell through to 1241px and reported a 3-column
card as 198.25px — 6.5px wider than the real 191.75px @ 602px. That path is not
what the PR gate runs (the gate uses no floor), which is why the committed
baseline never saw it, but it is the concrete reason "sampling happens to be
correct here" was not a safe place to leave the invariant.

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

Recorded in code as `kMinSupportedScreenWidth` in
[dashboard_card_probe.dart](../../test/util/dashboard/dashboard_card_probe.dart),
carrying this rationale, so the next person to change it knows it is a decision
(#1225). Lowering it adds overflow coordinates and requires a deliberate
re-baseline.

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

### 2.6a What making the seven shared sites safe taught us (#1227 — implemented)

All 101 coordinates cleared as predicted (379 → 278), and re-attribution before
starting confirmed the four intervening tickets had not moved them: still exactly
101, still exactly the seven named sites, and 0 shared-layer sites afterwards.
Four things the responsibility split did not say:

1. **`Flexible` is a share, not a negotiation — so it is the wrong tool for a
   header trailing.** A `Row` hands each loose flex child `freeSpace / totalFlex`
   and does *not* give one child's unused share to another; the remainder is
   placed by `MainAxisAlignment`. Making the card header's `trailing` `Flexible`
   next to the `Expanded` title therefore does two unwanted things: the title is
   capped at half the row even when the trailing wants 40px, and the trailing's
   leftover share is stranded *after* it under the default `start` alignment, so
   it stops being flush right. The trailing stays inflexible and gets a
   `LayoutBuilder` + `ConstrainedBox` cap of half the row instead — an upper
   bound rather than an allotment. The detail footer *can* use `Flexible`,
   because its row is `MainAxisAlignment.end` and the leftover falls at the
   start, where it is invisible.

2. **Which child receives the `Flexible` is a priority decision, and flexing both
   regresses coordinates that pass today.** In `N items · View all →`, making
   both the count and the link `Flexible` splits the free space evenly and
   ellipsizes the *English* link at 191px — a width where the whole row currently
   fits. Only the link is `Flexible`: as the last child of an end-aligned row it
   absorbs whatever the count leaves, a row that fits is laid out exactly as
   before, and it also covers the cards that pass `detailRoute` without
   `itemCount`, where the link is the only child. Measured at 191px `pl`:
   `6 elementów · Poka… →` — count intact, link shortened, arrow kept.

3. **A leaf block's bottom overflow is a height budget, and only `Flexible` states
   it.** `StatTile` needed `Flexible` around its label, not just `ellipsis`:
   `maxLines` bounds how many lines the *text* takes, but an unconstrained
   `Column` still grows to whatever the wrap produced — 98px past the tile's
   height at the narrowest width, where five tiles across one card leave ~17px of
   content each. `Flexible` is what forbids the `Column` from exceeding what the
   grid gave it; `maxLines: 2` then decides how the remaining space is spent.

4. **Skeletons carry the same bug as the content they stand in for, and they are
   the cheapest possible fix.** `card_skeleton.dart:153` is 212px of fixed widths
   in a 157px content box — the one site in the baseline that overflows by an
   identical 51px in all 26 locales, because a grey rectangle has no localized
   text to vary. Three sibling rows in the same file have the same shape and 0
   coordinates only because those cards are not realized at the narrowest width;
   they were fixed too, since a placeholder loses nothing by shrinking.

### 2.7 The gate enumerates widths instead of sampling them

**Implemented in #1225** (not yet merged). `_scanScreens`'s hand-written 19-width list *asserted* the
gate's stated invariant ("narrowest realization = worst case") rather than
guaranteeing it. It is replaced by `narrowestRealizationOf(span)`, which
enumerates every screen width from `kMinSupportedScreenWidth` (§2.3) to
`kMaxScannedScreenWidth`, keeping the one-case-per-span reduction.

The frozen-geometry warning in `SKILL.md` applies to the **formulas** — which
mirror production and must not change — not to how widths are chosen.

**The guarantee is exact over integer screen widths, and within 0.5px of the
continuum.** Card width is piecewise-linear and increasing in screen width within
each (columns, margin) regime, so each regime's narrowest width is at its left
edge, and enumerating every integer visits every regime. But the breakpoints are
**exclusive** (`screenWidth <= 600` is still 4 columns), so four regimes open
just *above* an integer and their infimum is approached, not attained: a 3-column
card tends to 191.0px as the screen tends down to 600px, versus the 191.375px @
601px the gate pumps. Fractional logical widths are realizable in production
(1080 / 2.75 = 392.7), so the gap is real; it is bounded at **0.5px** (worst case,
span 4), recorded as `kEnumerationSlackPx`, and a quarter of the gate's 2.0px
tolerance — so it cannot flip a verdict. Closing it entirely would mean
enumerating breakpoint+ε as well, which buys nothing measurable.

2560px is a sufficient upper bound because the regime never changes again above
1680px.

**Confirmed a behavioural no-op**, as §1.6 predicted: the full sweep reports the
same 560 coordinates across the same 36 keys, and the allowlist fixture is
unchanged. Because it landed **first** (Part 4), any future shift in that count
is attributable to the ticket that causes it.

Verified by
[dashboard_card_probe_test.dart](../../test/util/dashboard/dashboard_card_probe_test.dart).
Its central test compares the search against an **independently derived
infimum** — computed from the breakpoint list, including the open edges, rather
than by walking integers — so it catches a search whose *domain* is wrong, not
just one whose step is coarse. (Verified by mutation: starting the walk above
601px fails it. An earlier version of the test re-enumerated the same integers
the implementation does and passed that mutation — a property test whose oracle
shares the implementation's blind spot pins the step, not the property.)

### 2.8 The `colWidth` bug is silent truncation, and gates only the threshold

`usp_info_row.dart:29` uses `context.colWidth(labelColumns)`, which is
screen-derived, so the label column does not shrink when the card does. At the
narrowest realization the label claims ~122px of ~159px usable.

**It accounts for zero of the 560 coordinates.** Its `SizedBox` + `Expanded`
structure always technically fits — an `Expanded` compressed to a few pixels is
not a RenderFlex overflow — so the value text is clipped by the card surface's
`Clip.antiAlias` with no error raised. Users see cut-off text; CI sees nothing.
That is **worse** than an overflow, not better, and it is exactly the failure mode
the gate is blind to.

So this fix moves no coordinate. What it gates is `system_status`'s **threshold**:
that card's measured 360px fit width is an underestimate, because the harness held
the screen wide while shrinking the card, so its label column never shrank (§1.2).
Its 85 coordinates are unrelated and are cleared by its own layout fixes.

Fix by reading the real available width (`LayoutBuilder`), **not** by introducing
`PageLayoutScope`: this widget has one label-sizing decision to make, so a scope
wrapper is disproportionate. Verify its non-dashboard consumers (statistics,
internet settings, WiFi status, the ethernet port dialog) still render correctly.

> Generalising: **the gate cannot see clipping, only overflow.** Every fix that
> replaces an overflow with an unconstrained `Expanded` trades a visible failure
> for an invisible one. Prefer `maxLines` + `ellipsis`, which is visible as
> truncation the reader can recognise.

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

**Fixed in #1226** (not yet merged). All 49 coordinates cleared; the card is
clean across 26 locales × 4 tabs, and its two allowlist keys are gone
(560 → 511 coordinates, 36 → 34 keys). Default span unchanged at 6.

Two corrections that measurement forced, recorded because T03 inherits this
shape and because both were stated confidently above:

1. **The default-layout break was one locale, not a general desktop break.** A
   26-locale sweep at the default span-6 widths found **only `fr`** overflowing
   (+92px @ 432, +44 @ 480, +28 @ 496, +12 @ 512) — `Téléversement` /
   `Téléchargement`. §1.7's "40.6% clean" is a *fit-width* figure (worst locale ×
   worst tab, §1.2), so it is consistent with this; but it reads as though every
   desktop user sees the break, and only French users did. The conclusion
   survives — a shipped locale broken at 1024px is still a normal-form bug, and
   the compact-form argument is still unavailable — but the blast radius was
   narrower than the ticket implies. An English-only regression test passed
   *before* the fix existed, which is how this surfaced.
2. **The widths named in #1226 are mis-paired.** At a 1024px screen the
   12-column grid uses a 24px margin and yields **480px**, not 512px; 512px is
   the 1440px screen, and 496px occurs at 1408/1520/1712px. The test covers 432 /
   480 / 496 / 512 so the intent holds as a superset.

**The degradation shape T03 replicates**: a `Wrap` with `spaceBetween` replaces
`Row` + `Spacer` — identical rendering while the content fits, and the totals
drop to a second line instead of overflowing when it does not. Legend labels are
`Flexible` + one-line ellipsis (a legend keys an already colour-coded chart, so a
clipped label still communicates); dot and label stay in one `Row` so a label
never separates from its colour. The byte totals get no `Flexible` and no
ellipsis — they are content, not chrome, and a truncated byte count cannot be
recovered from the chart the way a legend label can.

### 2.10a What replicating the shape six times taught us (#1233 — implemented)

All 132 coordinates cleared as predicted (511 → 379). Three things the shape did
not say, found by measuring each row after it was changed:

1. **`Flexible` is load-bearing, not decoration for the ellipsis.** A `Row` gives
   non-flex children *unbounded* width, so a bare `AppText` takes its full
   intrinsic width on one line and overflows however the enclosing `Wrap`
   arranges the entries. Wrapping a row in `Wrap` alone fixed nothing for the
   single-entry legends (System Status Distribution, Network Health Loss) — the
   `Wrap` can move a whole entry to the next run, but only `Flexible` lets the
   label itself give. #1226's row happened to have two entries and two
   already-`Flexible` labels, so this never surfaced there.
2. **Ellipsis vs. soft-wrap is decided by what the label *is*, not by the row.**
   Bare series names take #1226's one-line ellipsis (the colour identifies the
   series, so a clipped name still keys the chart). Composed statistics —
   `Avg: 42%  Peak: 87%`, and Network Health's `series, average, peak` — get no
   ellipsis and no `maxLines`: an ellipsis lands mid-number, and a half-shown
   statistic misinforms in a way a missing one does not. They soft-wrap onto a
   second line instead. Both cards therefore carry a per-entry flag rather than
   one blanket rule.
3. **#1226's shape has an unstated precondition, and one row violates it.** The
   shape pays for its extra run with height, "because the chart above is
   `Expanded`, so it yields the height". Network Health's Health tab has an
   `Expanded` holding a **fixed 120px** gauge, so it yields nothing: a `Wrap`
   there traded that row's 26 right-overflows for **12 new bottom-overflows at
   the gauge centre** (`:128`, 3 → 15) — a fix on paper only, and it would have
   landed as one had the ratchet been edited to the predicted numbers instead of
   the measured ones. That row stays a one-line `Row` of `Flexible` lights and
   gives horizontally; the deviation is commented at the site and pinned by a
   test that fails if someone "restores consistency".

**#1235 is a functional dependency on #1233, not just conflict avoidance** (both
tickets say otherwise). Its 3 gauge-centre coordinates are height-coupled to this
row: they are what is left *because* the row was kept to one line, and they are
the reason it had to be.

The two readability ACs — labels not truncated to uselessness, colours still
associable — are invisible to the gate, which cannot distinguish a row that fits
from a row that truncated its content to nothing. They are covered by
`test/page/dashboard/views/components/dashboard_legend_readability_test.dart`,
tagged `dashboard-card` so it gates; each of its three groups was verified to
fail under a mutation of the code it guards.

### 2.10b What the eighth and ninth replications taught us (#1229 — implemented)

All 45 coordinates cleared as predicted (226 → 181). By this point the shape is
routine — the interesting findings are about *method*, not about legends.

1. **A "×N sites" scope still needs its own attribution run.** §1.1's greedy
   cover is greedy: it credits each coordinate to one site, so it named
   `:190` (33) and never mentioned the Speed tab's legend at all. The remaining
   12 were only located by re-running §1.1's method scoped to this card, which
   returned an unambiguous split — `:190` → 33, `:275` → 12, no coordinate
   needing both, total exactly 45. Inferring the second site from the ticket
   title would have been a guess with a 12-coordinate blast radius.
2. **Same shape, same fix, different cause — and the locale footprint says
   which.** `:190` (four entries, 261px) overflows in `en` too: it is
   *geometry*-bound, and `ru` missed by 149px. `:275` (two entries) overflows
   only in the long-translation locales (`es`, `fr`, `pt_PT`, `ru`, `tr`): it is
   *translation-length*-bound. The distinction is free to read off the allowlist
   — an `["*"]` entry means the card is too narrow for the content in any
   language, a locale list means the layout is fine and one translation is long
   — and it predicts which sites will regress when a string changes versus when
   spacing changes.
3. **§2.10a point 3's precondition was checked here, not assumed.** The
   `Expanded` above both rows holds a `ListView`/`AppBarChart`, so it yields the
   height a second run costs. Confirmed by re-running attribution after the fix:
   **0 incidents at any site, any tab, any locale** — no bottom-overflow was
   traded in, which is the exact failure Network Health's fixed 120px gauge
   produced. Measured, because the shape's cost is paid in a currency the gate
   only sometimes charges for.
4. **The mutation that validates a readability test must itself be run against
   the gate.** #1233 and #1228 recorded "verified to fail under a mutation"; that
   is necessary but not sufficient. Here the *obvious* mutation — revert `Wrap` to
   a bare `Row` — turns out to be **invisible to the readability test and caught
   by the gate** (33 failures): a `Row` hands non-flex children unbounded width,
   so the inner `Flexible` never binds, every label paints full-width, and the
   *outer* row overflows. The genuinely gate-invisible regression is the one that
   *succeeds* at fitting: keep the single `Row` and wrap each entry in
   `Flexible`. Every tier name then ellipsizes to a stub — in `en`, not just the
   long translations — and all **157** `wifi_performance` gate cases stay green.
   That is the shape a well-meaning "just make it fit" edit lands on. **Rule for
   the remaining Track A tickets: run each candidate mutation against the gate as
   well: if the gate already fails it, the mutation proves nothing about the
   readability test and a different one is needed.**

The gate-invisible ACs are covered by
`test/page/dashboard/views/components/wifi_performance_readability_test.dart`,
tagged `dashboard-card` so it gates; its three groups were verified to fail under
the mutations tabulated in the file, each with its gate result beside it.

**AC4 was already true before this ticket, and is now pinned rather than earned.**
"Per-band metrics stay distinguishable at the narrowest clean width" is about the
Channels tab, which contributed none of the 45 and which #1229 does not modify. At
the 261px narrowest realization both bands show band, channel, bandwidth, client
count and SNR with nothing clipped. It is asserted anyway, because "already clean"
is not "checked" and nothing else in the suite would notice a later fix collapsing
those rows.

Two observations were left deliberately unfixed here, and **both were wrong** —
#1266 (§2.10c) measured them and inverted the conclusion. They are quoted rather
than deleted because the way they were wrong is the finding:

- `_ChannelsTab`'s two per-radio rows use the same unconstrained shape this epic
  keeps fixing (`Row` + `Spacer`, non-flex `AppText`), and measure clean only by
  about **48px** of headroom. That is the #1258 situation exactly — hardening a
  site that is not currently failing — so it belongs there, not in a ratchet
  ticket whose contract is a coordinate count.
- The channel readout is **data**-dependent, not translation-dependent:
  `Ch 197 (Auto) · 320MHz` on a tri-band router is materially wider than the
  mock's two-radio output. No amount of locale sweeping reaches it, so that
  headroom is unmeasured rather than measured-safe — a limit of the gate's fixed
  mock, worth stating where the 48px figure is quoted.

The 48px was real and the reasoning from it was not: it was measured with `'Ch '`,
a hardcoded English abbreviation, in the row. The abbreviation *was* the bug, and
it was concealing the geometry problem rather than the row not having one. "Clean
by 48px" and "hardening a site that is not currently failing" both describe a
string that was never going to ship.

### 2.10c An English abbreviation was hiding a geometry problem (#1266 — implemented)

#1229 left the Channels tab alone on the strength of the two bullets above.
Localizing `'Ch '` to the existing `channel` ARB key — which was already
translated in all 26 locales, so this was a one-line change with no ARB work —
turns the tab's band/channel row into **3 gate coordinates on the fixture the gate
actually ships**:

| locale | `channel` | 261px (min) | 288px (preferred) |
|--------|-----------|-------------|-------------------|
| `tr`   | `Channel (Kanal)` (15 chars) | +4.1px, +41.0px | +14.0px |
| `th`   | `ช่องสัญญาณ`   | +17.0px         | clean   |
| other 24 | — | clean | clean |

So the two halves cannot be separated, and the *ordering* is the point:

- **Localizing alone runs the ratchet backwards.** It adds 3 coordinates to a
  mechanism whose entire purpose (§2.9) is that the count only falls. It would
  have to be booked as an allowlist *addition*, which nothing in Part 4 permits.
- **Hardening alone is gate-invisible.** With `'Ch '` in place the row is clean
  everywhere, so the `Wrap` changes no coordinate and the gate cannot tell whether
  it worked. That is the #1258 shape, and it is why #1229's bullet reached for
  #1258.
- **Together they are self-verifying**: the localization supplies the failure the
  hardening has to clear, on the shipped fixture, at both widths. Net coordinate
  change **0**, and the honest string ships. This is the #1249 bundling precedent
  (ratchet work travels together), not the #1258 one.

Four further findings, all about method:

1. **An abbreviation in `lib/` is a measurement hazard, not just an i18n bug.**
   Any hardcoded English string makes every width measurement at that site
   optimistic by however much the translation is longer, and the gate reports the
   optimistic number in all 26 locales — a locale sweep cannot find a string that
   never varies. Worth a grep pass over the remaining Track A sites: an
   abbreviation is the one defect this epic's instrument is structurally blind to.
2. **Two `testWifiData` fixtures exist and only one reaches the gate.** The
   dashboard gate reads `test/golden_test/page/dashboard/cards/fixtures/`
   `cards_test_data.dart` (via `kitchenSinkOverrides()`); the Statistics page reads
   `test/golden_test/page/statistics/fixtures/statistics_test_data.dart`. Editing
   the latter and re-running the gate produces a confident, meaningless "clean".
   Caught only by dumping the rendered `Text` list and noticing the added radio was
   absent. **Rule: when a measurement depends on fixture data, verify the render
   contains the data, not just that the verdict is green.**
3. **`WrapAlignment.spaceBetween` is a silent no-op under loose width
   constraints.** `RenderWrap` sizes itself to its widest run, so
   `freeMainAxisSpace` is 0 and there is nothing to distribute; the second child
   lands one `spacing` gap after the first instead of at the right edge. The
   enclosing `Column` must hand it a tight width
   (`CrossAxisAlignment.stretch`) for `spaceBetween` to reproduce what a `Spacer`
   did. This is a **pure visual regression that overflows nothing**, so the gate
   passes all 157 cases either way — it is pinned in the readability test instead.
   **This applies retroactively: #1226's and #1233's `spaceBetween` legends should
   be checked for the same precondition, since a shrink-wrapped legend is
   indistinguishable from a correct one in a green gate.**
4. **Attribution scoped the fix to one of the two rows.** Regexing
   `usp_wifi_performance_card.dart:(\d+)` over `OverflowIncident.fullLog`
   attributed every single incident — both fixtures, all locales, both widths — to
   the band/channel row, and none to the clients/SNR/loader row below it (whose
   `Expanded` loader already binds). §1.1's method at per-line resolution, and it
   halved the change: #1229's bullet had assumed "two per-radio rows" needed the
   same treatment.

**Tri-band data: what the fix costs on a profile the gate cannot produce.** The
gate's data domain is one hardcoded profile — `testRadios` is 2 radios, 2-digit
channels, `160MHz` widest — and `buildDashboardCardApp()` takes no overrides, so no
card can be measured against different data without editing the fixture. Measured
by temporarily adding a third tri-band radio (`Channel 233 (Auto) · 320MHz`) and
reverting:

| | before #1266 (`'Ch '`) | localized, old `Row` | localized + `Wrap` (shipped) |
|---|---|---|---|
| 2 radios (the gate's fixture) | clean | 3 coordinates | **clean, 26 locales × both widths** |
| 3 radios, tri-band | clean | `en` +8.3px, plus `fi`, `ja` and the two above | one **+9.0px bottom** (`tr` @261 only) |

The remaining tri-band incident is not the band/channel row: it is the donut's
centre label at `:575`, squeezed once three two-run blocks have taken enough of the
column that its `Expanded` no longer fits the label's two lines. That is §2.10a
point 3's failure mode — the same
fixed-size-gauge-in-an-`Expanded` shape as #1235's `network_health` gauge — and at
that height the donut is visually useless whether or not it reports an overflow, so
"shrink the donut to fit" would silence the gate without fixing anything. Deciding
what the tab drops at that density (the donut, or the whole tab becoming
scrollable like the Signal tab's `ListView`) is a density decision, and it is not
verifiable at all until the gate can express a second data profile.

**Filed as #1267**, which pairs the density decision with the gate change that
makes it measurable: an `overrides` parameter on `buildDashboardCardApp()` /
`kitchenSinkOverrides()` plus a tri-band fixture. It is deliberately *not* folded
into #1235 — same family (fixed-size gauge in an `Expanded` that cannot pay), but
different axis (vertical vs horizontal), different trigger (data vs translation
length) and different visibility (invisible until #1267's Part 1 lands vs 3 live
coordinates), and #1235's acceptance criteria are executable ratchet claims that an
unverifiable AC would make unclosable. Recorded here because the #1266 fix does
trade a right-overflow for a bottom-overflow on that unshipped profile, which is
exactly the trade §2.10a point 3 warns about.

Note also what #1267's Part 1 costs: adding a second profile to the sweep across
all 18 cards doubles 1644 cases and will surface coordinates nobody has looked at
— an allowlist *addition*, against the ratchet's direction. Which is why the sweep
shape (opt-in per card / second allowlist keyed by profile / one allowlist) is an
explicit decision in that ticket rather than an implementation detail.

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

### 2.12 What the first *rearrangement* taught us (#1228 — implemented)

All 52 coordinates cleared as predicted (278 → 226). #1226/#1233/#1227 all made
existing rows *give*; this is the first ticket where the row had to be taken
apart, and three things only showed up in the measurements.

1. **A residual under the gate's tolerance is a silent pass, and the narrowest
   card produces one.** The gate ignores overflows below 2.0px. At the narrowest
   realization `ethernet_ports` ever gets — a 191px card, 157px of content — each
   summary tile's row has **50.69px** for chrome that costs **52px** (a 40px
   status disc plus a 12px gap). Constraining the text is therefore not a fix
   *and not a failure either*: the text column goes to zero, the row still
   overflows by **1.31px**, and the gate goes green on a tile that renders no
   label at all. The reflex from the three preceding tickets — wrap the label in
   `Flexible`/`Expanded` and move on — would have produced exactly that. **Check
   the row's fixed cost against the available width before choosing "make the
   text give"**; where fixed cost alone exceeds it, the arrangement has to change.
2. **Rearranging spends vertical budget the gate cannot see.** `ethernet_ports`
   gives its content a **121px** viewport (measured at both narrow
   realizations). Stacking the two tiles at the standard 12px padding needs 136px
   — it clears every coordinate and slices the second tile by 15px, because
   `DashboardCardTemplate` scrolls rather than clips, so nothing overflows and
   the gate cannot tell. Stacking therefore tightens the tile padding to 8px
   (2 × 56 + 8 = 120px). Generalisation for the remaining Track A tickets: a fix
   that changes a card's *arrangement* must be measured against the content
   viewport, not only against the gate.
3. **The port list's initially-visible sliver is a measured, accepted loss —
   and #1228's AC5 is not met by this ticket.** The port `Wrap` needs 514px (min)
   / 318px (preferred) against that 121px viewport, so it required scrolling
   before this change and after it; the port *labels and speeds* sat below the
   viewport bottom already (wrap top 137 + a 38px glyph = 175, labels from ~183,
   viewport ends at 178). What changed is the glyph row: stacking moves the wrap
   from y=137 to y=193, so the 41px of port glyphs that were visible without
   scrolling become 0px — at the two narrow realizations only, desktop untouched.
   The loss is forced, not chosen: preserving 41px needs 64px back, which even a
   disc-less stacked pair (2 × 52px) cannot return. So AC5 ("port state remains
   readable at the narrowest clean width") is unreachable by *any* arrangement of
   the summary tiles; it needs a compact port list, which is #1240's job. Track B
   inherits it rather than #1228 claiming it.

The AC that *is* gate-invisible and satisfiable — the two tiles being a matched
pair — plus the label-legibility floor are covered by
`test/page/dashboard/views/components/ethernet_ports_summary_readability_test.dart`,
tagged `dashboard-card` so it gates; each of its four groups was verified to fail
under a mutation of the code it guards (the mutations are tabulated in the file).

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

Published as issues #1225–#1240 under #1183, with native blocking dependencies.

**Two tracks that do not block each other.** Track A makes the gate green; Track B
makes narrow cards readable. The gate cannot measure readability, so B does not
wait for A. `normalAbove` defaulting to absent (§2.4) means B's mechanism is pure
addition — it changes no card's rendering until a threshold is declared.

### Track A — eliminate coordinates (ratchet)

| # | Work | Clears |
|---|---|---:|
| #1225 | Gate enumerates widths (§2.7) — **implemented** | 0 |
| #1226 | `traffic_analysis` legend row (§2.10) — **implemented** | 49 |
| #1233 | The other six legend rows (§1.1, §2.10a) — **implemented** | 132 |
| #1227 | Shared blocks made overflow-safe (§2.6, §2.6a) — **implemented** | 101 |
| #1228 | `ethernet_ports` ×2 sites (§2.12) — **implemented** | 52 |
| #1229 | `wifi_performance` ×2 sites (§2.10b) — **implemented** | 45 |
| #1266 | `wifi_performance` Channels tab: localize `'Ch '` + harden (§2.10c) — **implemented** | 0 (net) |
| #1230 | `firewall_overview` own sites (§2.11) | 48 |
| #1234 | `system_status` remaining ×3 sites | 34 |
| #1236 | `lan_info` + `device_info` card-own | 29 |
| #1237 | `time_settings` card-own | 21 |
| #1235 | `network_health` gauge centre | 3 |
| #1238 | `connected_devices` card-own (§2.6) | 1 |

Ceiling **515 / 560**. The other 45 are the dependency-blocked ones (§1.1).

#1266 is in this track despite clearing nothing: it is the only entry that *adds*
coordinates (3, by localizing a hardcoded string) and removes them again in the
same change. It belongs here rather than in Track B because the ratchet is what
constrains it — see §2.10c for why the two halves cannot ship separately.

#1225 lands first — not because it re-baselines (it does not, §1.6) but so that
the invariant holds by construction and any future shift is attributable. #1226
precedes #1233 because it settles the legend shape the six others replicate.
#1236/#1237/#1238 genuinely depend on #1227: those coordinates need both a shared
and a card-own fix, so card-own work done first shows zero allowlist progress.
#1234 follows #1233 only to avoid editing the same file concurrently. **#1235 is
a real functional dependency** — measured during #1233, see §2.10a point 3: its 3
coordinates are height-coupled to the WAN/LAN row, which is why that row is the
one deviation from the legend shape.

### Track B — make narrow cards readable

| # | Work |
|---|---|
| #1231 | `usp_info_row` reads real width (§2.8) — fixes silent truncation, clears 0 |
| #1232 | Density plumbing (§2.1, §2.4, §2.6) — the one ticket needing red-first tests |
| #1239 | Popup form + dialog reuse (§2.1) |
| #1240 | Per-card thresholds and compact forms (§2.4, §2.5) — split after fit widths settle; inherits #1228's port-list readability AC (§2.12) |

#1240 waits on all of Track A: thresholds are meaningless while fit widths are
still moving, and the point of the layout fixes is to lower them. **Re-measure
before declaring any threshold** — a card whose fit width drops to its narrowest
realization needs no threshold at all, and absent is the correct value.

### How each step is verified

The steps do not share a verification method, and treating them as if they did is
the likeliest way to get this wrong.

| Work | Method | Why |
|---|---|---|
| All of Track A except #1225 | **Ratchet, not TDD** | The failing assertions are *already committed* — the 560 entries in `known_overflows.json`. The red→green move is: fix the layout, delete the allowlist entry, gate passes. Deleting an entry that still overflows fails that test, so it cannot be faked. |
| #1232 | **TDD** | The gate asserts only "no overflow"; it cannot detect *wrong density*. Threshold selection, popup cut-off, and absent-`normalAbove` behaviour can all break while the gate stays green. Tests go red first. |
| #1231 | **Neither** | Not an assertion — it fixes a failure the gate is structurally blind to (§2.8), so it is verified by eye or golden. |
| #1225 | **Property tests + no-op diff** | Planned as "neither", since converting a sampled invariant into a guaranteed one changes no assertion. In the event it had a testable seam after all: the search is pinned by a property (no supported width is narrower than the one pumped, which fails on a coarser step) and the no-op claim by diffing the full sweep's 560 allowlisted hits before and after — they matched exactly. |

The gate does **not** need to know a card's measured fit width to enforce
§2.4's `normalAbove >= fitWidth`: it applies the density rule at the card's
narrowest realization and pumps. A threshold set too low leaves the card in the
normal form at a width where it overflows, and the gate fails on that. No
fit-width measurement harness needs to exist at runtime or in CI.
