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
  — all three closed by #1238; the ui_kit one by the **v2.34.10** upgrade rather
  than by anything in this repo (§2.10e)

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
*Superseded as a planning figure* — later measurement puts the blocked set at
**32** (fl_chart 6, ui_kit 26); see §2.9a. The 19 is retained here as the
baseline record. *Superseded again* — the ui_kit 26 were unblocked upstream by
v2.34.10 and closed by #1238, leaving **6** (fl_chart only); see §2.10e.

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

⚠️ **`connected_devices` is clean at 191px since #1238**, so its 320 is stale by
129px. Track A has moved this column for every card it has closed and *only* this
column — the width at which each is readable has not moved at all (§2.10d point 5,
§2.10e point 4). #1240 re-measures; it must not read this table.

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

### 2.9a The ratchet cannot be cheated, but it can go stale

The gate is asymmetric, and only one direction is guarded:

- **Deleting an entry that still overflows fails the gate.** Progress cannot be
  faked. This is the property §2.9 relies on.
- **An entry that stops being needed fails nothing.** It keeps printing
  `KNOWN OVERFLOW (allowlisted)` for an overflow that no longer happens, and the
  gate is happy either way.

So the allowlist only ever measures *coordinates someone remembered to delete* —
which is not the same number as *coordinates that are broken*. The two drift
apart silently, always in the direction of overstating the remaining work.

Measured on the tip after #1234–#1237: **94 exempted, 48 live — 46 dead.** None of
the four tickets removed them and the gate never asked for them back. #1247
replaced a composed `Expanded(AppText('$portSummary → $internalClient'))` on
`firewall_overview` with the two-`Flexible` `MapsToRow`, which stopped that row
overflowing as a side effect of glyph work; all 26 of
`firewall_overview|preferred|1` and 20 of `firewall_overview|min|1` had been
exempting an overflow that ended there. **Attribution credits #1247, not
#1234–#1237.**

Two consequences worth carrying forward:

1. **A dead exemption is not harmless.** It masks the sites underneath it. A
   coordinate is live if *any* of its sites overflows, so the widest failure hides
   every narrower one at the same coordinate — which is how fl_chart's footprint
   came to be recorded at 19 when it is 6 (§2.10d).
2. **Counting exempted entries is not measuring the ratchet.** The live number
   comes from counting `KNOWN OVERFLOW (allowlisted)` lines in a gate run. Any
   claim about "coordinates remaining" that was not measured that way is an
   estimate, and should say so.

The cheap discipline this argues for: after any layout change lands, re-run the
gate and compare exempted-vs-live per allowlist key. Where they disagree, the
entry is dead and should be deleted in the same sweep.

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

### 2.10d What closing the four card-own tickets taught us (#1234–#1237 — implemented)

87 coordinates → **0**, on one branch, one commit per shape. §1.1's decomposition
held to the coordinate, including its uncomfortable prediction that the two
`system_status` sites sharing `min|0`'s 26 coordinates would each clear **none**
of them alone — the legend row moved only the 2 outside that key, and the 26 fell
in one step when the gauge row followed:

| Commit (shape) | Sites | Coordinates |
|---|---|---:|
| "View details" footer | `system_status:118`, `device_info:140` | 34→28, 2→0 |
| Hero inner row | `lan_info:56`, `time_settings:108` | 27→0, 21→0 |
| Legend row | `system_status:218` | 28→26 |
| Twin gauge row | `system_status:196` | 26→**0** |
| Gauge centre | `network_health:150` | 3→0 |

The ratchet now stands at **48 coordinates**, all owned by #1230 (21,
`firewall_overview`) and #1238 (27, `connected_devices`). *Since superseded* —
#1238 closed its 27 (§2.10e), leaving **21**, all #1230's.

That 48 replaces the 94 these four tickets left behind. The 46 that went were not
removed by any of them — they were dead exemptions, and the credit belongs to
#1247; see §2.9a for the measurement and what the asymmetry costs.

**1. One shape, two techniques — and sometimes the technique is deletion.** The
hero inner row is the same idiom in two files and **48 of the 84 coordinates**,
the largest single shape in the baseline, with the same measured cause in both: a
fixed 56px avatar plus `AppGap.lg` leaves the `Expanded` column **61.4px**, and a
`Row` hands its non-flex children *unbounded* width. `lan_info` overflowed in all
26 locales including `en` (+47.7px), so this was never a translation-length
defect. But the two fixes diverge, per §2.10a point 2: a composed status
soft-wraps (`DHCP Enabled` ellipsized to `DHCP…` drops the only word the row
exists to show), while `time_settings`' child is an `AppBadge` and **a capsule
cannot take a second line**. That badge already ellipsized correctly and only ever
failed because a single-child `Row` handed it infinity — so the `Row` was
*deleted*, not flexed. Removing a `RenderFlex` beats constraining one when it had
no other effect; the enclosing `Column` was already `start`-aligned.

**2. A `Wrap` under an `Expanded` is clipped in silence.** #1234's design
alternative (stack the two gauges instead of shrinking them) was expected to fail
loudly: two 100px runs need ~208px against the 201px (`en`) / 181px (`de`) the
`Expanded` offers. It fails *silently* — `RenderWrap` has no overflow indicator of
its own and the `Expanded` pins its height, so the second circle is simply cut
(108px between gauge centres in a 181px box, all 209 gate cases green). §2.10a
point 3 says a `Wrap` must have height to spend; the sharper form is: **the gate
cannot tell you when it doesn't**, so the precondition is measured *before* the
conversion or not at all. #1233's and #1266's conversions were safe for a reason
that has to be checked, not inherited.

**3. Every fix is one of three things to the gate — and a green gate is not a
green criterion.**

| Fix class | Example | The gate afterwards |
|---|---|---|
| Constrain (`Flexible`, `maxLines`, bound a size) | all of #1236, #1237 | still sees a revert |
| Convert to a `Wrap`/`Column` inside a pinned box | rejected stacking | blind to the *new* failure |
| Scale (`FittedBox`) | #1235's centre | blind to it **for good** |

`FittedBox(fit: BoxFit.scaleDown)` is the right fix for #1235's centre and it
permanently removes the signal: once a subtree may shrink, no future squeeze can
ever produce a coordinate. The mutation ledger makes that concrete — shrinking the
score's font unconditionally clears **all 209** gate cases. So a self-relaxing fix
has to ship its own floor: `usp_gauge_center_readability_test.dart` asserts a 12px
painted minimum, which is the replacement for what `scaleDown` took away.

That table is the *revert* axis, and it is not the only one. A constraining fix
keeps the signal, so the gate does own its revert — but it never owned the
**choice**: `maxLines: 1` and a soft-wrap clear the same coordinates, and at three
of these sites one of them destroys the string. Measured on this branch:
ellipsizing `lan_info`'s router IP, its DHCP status, or the shared InfoGrid value
renderer leaves **all 1644** gate cases green. #1236 AC 4 and #1237 AC 5 name those
readings ("truncating an IP in the middle makes it useless"; "timezone names stay
identifiable"), so `usp_hero_row_readability_test.dart` asserts them across four
locales each — and each mutation kills exactly its own group, so a failure says
which criterion broke. The rule that falls out is narrower than "constraining
fixes need tests", which would be licence to test every `Flexible` on the branch:
**a fix owes a test when the gate stays green through both the right and the wrong
version of it** — whether because the fix removed the signal (#1234, #1235) or
because the signal never told the two apart (#1236, #1237). Where the gate does
discriminate, the allowlist entry it deletes *is* the assertion.

The same test covers the one place this branch made a reading *worse*: #1237's
badge now ellipsizes (`de` paints 45.4px of an 85.1px label), which §2.10a point 2
requires of a capsule but which no coordinate can report, since a narrower badge
overflows *less*. That gets a floor too, not a fidelity claim — enough glyphs to
key the state, with the colour carrying the rest.

**4. A ticket's diagnosis is a report, not a measurement.** #1235 states the tier
label is wider than the space inside the circle. The three coordinates are
**bottom** overflows (+21.0 `de`, +11.0 `ru`, +9.0 `th`): `AppGauge` respects its
incoming constraints, so the gauge lays out 120×67 (`en`) and 120×**23** (`de`)
against a 44px centre column. Worse, the cause is two levels up — `_MetricChip`'s
three ~23.1px label columns soft-wrap (`Discards` over 3 lines, `Verworfene
Pakete` over **6**), so the height left for the gauge is a function of translation
length. Acting on the ticket's text would have produced a fix that is both lossy
and incomplete: ellipsizing the tier truncates it *and* leaves 2 of 3 coordinates
standing (ledger row 2). §1.1's per-line attribution is what turned this up, and
it belongs on the *cause*, not on the symptom's line number.

**5. A cleared allowlist is not a readability claim — and #1240 must not read it
as one.** Track A's target is "nothing is clipped or overflowing". Both cards
closed here are green at 191px and unusable there:

- `time_settings`: the hero clock is a 222.5px string in a 61.4px column, so it
  paints **5 lines / 140px** — in every locale, `en` included — while the sync
  badge shows ~6 glyphs plus an ellipsis. Nothing overflows; everything that could
  give, gave. §1.2 puts this card's fit width at 288px.
- `network_health`: the centre scales to **0.52** in `de` (14.6px score, 8.4px
  tier) because the metric labels below take 48px (`en`) to 96px (`de`) of the
  height. §1.2 puts its fit width at 420px; it is being asked to render at 191px.

Those two numbers are direct #1240 input, not defects to paper over. Related
caveat on §1.2 itself: that table measures the narrowest width at which a card is
*clean*, and Track A has now moved that number for five cards while leaving the
width at which they are *readable* exactly where it was. #1240 must re-measure,
not read §1.2's column.

**6. §2.10c finding 1's grep pass, executed over these five cards.** Six
hardcoded English strings; five are protocol acronyms that do not vary by locale
(`CPU`, `DNS`, `IPv6`, `MAC`, and `DST`, which is arguable and left alone). One is
a real bug: `usp_lan_info_card.dart:144` renders `value: 'Enabled'` while line 85
of the same file uses `loc(context).enabled`, a key that exists in all 26 locales
(`Ενεργοποιήθηκε`, `Ingeschakeld`, …). It is **not** the one-line fix #1266 was,
because it is gate-invisible twice over: a hardcoded string cannot vary in a
locale sweep, *and* the branch never renders at all — it is the `else` of
`if (info.ipv6Addresses.isNotEmpty)`, and the gate's fixture supplies
`ipv6Addresses: ['fd00::1']`. Verifying a localization there needs #1267's
`overrides` parameter first, so it is recorded here rather than folded into these
four tickets. This is §2.10c finding 2 in its purest form: the data decides what
the instrument can see.

**7. Two entries for #1245's de-duplication inventory.** There are **three**
hand-rolled "View details" footers, not two — `usp_system_status_card.dart:118`,
`usp_device_info_card.dart:134` and `usp_traffic_analysis_card.dart:141` — plus
the template's own at `dashboard_card_template.dart:393`, so four copies of one
shape. They exist for one reason: `detailRoute` cannot carry query parameters
(`?tab=`, `?deviceId=`), so none of the three can use
`DashboardCardTemplate._buildDetailFooter`. #1227 fixed the template's copy and
could not fix theirs. The fix here was replicated *verbatim* rather than
extracted, because extracting it would make a fifth copy of the widget while
leaving the cause in place. The cause — `detailRoute`'s signature — is the
inventory entry. The second entry is the footer shape itself.

These four tickets hardened two of the three. `traffic_analysis`'s is left
unflexed on purpose: its `minColumns` is **4**, not 3, so the width enumeration
never realizes it at the 157.4px where this shape bites, and it carries no
allowlist entry in any of its 26 locales. That is the ratchet doing its job in
the other direction — it says which copies actually need the change, and this one
does not yet. It is also why the copy is worth recording rather than patched
prophylactically: if the floor ever drops to 3, the gate raises coordinates for
it and the fix is the same three-line `Flexible` used twice above. Hardening it
blind today would spend the signal that tells us it is needed.

**8. Widening was genuinely available once, and was declined.** `time_settings`
is the only card in the baseline where §1.3's arithmetic permits the other fix
(fit width 288px, so `minColumns` 3 → 5 would have worked). It stays 3, with the
reasoning recorded at the declaration site: the floor is the user's, it costs 5 of
12 columns in every layout to buy headroom in a handful of locales, and the
card-own fix cleared all 21 coordinates by deleting a single-child `Row` that
had no other effect — the cheapest fix on the branch.

### 2.10e What the ui_kit dependency actually blocked (#1238 — implemented)

27 coordinates → **0**, and 26 of them were the epic's largest
"dependency-blocked" block. They were not unblocked by a workaround: ui_kit
**v2.34.10** replaced `AppListTile`'s `Row` with `ListTileContentLayout`, a
slotted render object that guarantees the content column 25% of the row and caps
each slot.

Neither AC 3 nor AC 4 describes the path taken, and it is worth being exact about
which. AC 3's precondition ("if avoidable at the call site") was false on the
version this ticket was written against — the `trailing` slot was laid out at
`maxWidth: Infinity`, so no call-site fix existed — which is why the escalation
was filed as linksys/privacyGUI-UI-kit#20. AC 4's remedy (leave the 26
allowlisted, with a tracking note naming the request) then became moot, because the
upstream layer had already changed: consuming v2.34.10 made the call-site fix
possible and the coordinates went green. So the ticket's **outcome** is AC 3's —
the 26 removed, the gate passing — reached by the upstream route AC 4 anticipated.
#20 itself is still open upstream; this branch comments the v2.34.10 resolution on
it rather than assuming it was answered. Both card-own sites went with the upgrade,
in the two shapes below.

**1. The two status counts stack; the threshold comes from one Greek word.** Side
by side, each count gets `(content − 8) / 2` minus 24px of padding, and it has to
hold a 10px dot, an 8px gap, the number, a 4px gap and the state word. The binding
locale is `el`: «Χωρίς σύνδεση» needs **116.7px** all in, against `en`'s 66.8px
and `zh`'s 52.2px — so side by side needs `2 × (116.7 + 24) + 8` = **289.4px** of
content, and the threshold is 296. Neither narrow realization has it (157.4px at a
191px card, 254.0px at 288px), and stacked, each block gets the full inner width
and every locale fits with ≥16.7px to spare. The realized widths either side of
the threshold are 254px and ~600px, so nothing lands within 200px of it.

This is now the second card using the shape (`ethernet_ports` is the first,
§2.12), and it is deliberately **not** extracted into
`lib/page/_shared/components/layout_blocks/` yet. What the two share is ~15 lines
of `LayoutBuilder`/`Row`/`Column`; what they do not share is everything that
matters — each threshold is measured from its own card's labels, and
`ethernet_ports` additionally tightens tile padding when stacked to buy vertical
budget. #1240 replaces both arrangements with a declared compact form, so the
abstraction would be born to be deleted. A third card needing the shape is the
trigger to extract it; recorded here so the next reader does not have to re-derive
the decision.

A stacked pair occupies 96px of a 261px content viewport (52px more than the 44px
it takes side by side), which the gate cannot see at all
— the template *scrolls*, so a stacked pair that pushed the device list below the
fold would overflow nothing. Measured: the two 44px blocks occupy y=57–153 and the
first 68px device row ends at 233, against a viewport bottom of 318.

**2. A demand-derived slot cap is not a budget.** This is the finding worth
carrying forward. v2.34.10 makes a `LayoutBuilder` legal in the `trailing` slot
(before it, the slot was laid out at `maxWidth: Infinity` and a call-site fix was
impossible — which is what "blocked" meant), and the finite number it now sees
looks like the row's spare room. It is not. The allocator reserves 25% of the row
for the content column, splits the rest in two, and then **lends each side whatever
the other did not want**:

```
available   = tile width − 2 × 16px gap        // tile width = content − 32px padding
share       = 0.375 × available
trailingCap = share + max(0, share − leadingDemand)
```

Two consequences, and they pull in opposite directions. The cap is bounded by what
*this row* demanded in the first pass, so it cannot be read as spare room — and it
is *raised* by the leading slot under-asking, so it is not a fixed fraction of the
card either. Measured on the gate's fixture at a **512px** card, all three rows
carrying a badge and an indicator:

| row | trailing cap | outcome under a slot-derived rule |
|---|---:|---|
| `iPhone-15` | 75.0px | keeps `-45 dBm` |
| `MacBook-Air` | 64.8px | loses it |
| `Smart-Speaker` | 22.0px | loses it |

The cap tracks the *device name's* length, so the first cut of this fix deleted
the signal reading on a 1440px screen for the rows with the longest names and kept
it one row above — for a reason no user can see. Nothing overflowed, so the gate
called it fixed, and the readability test called it fixed too, because it asserted
`labels.isNotEmpty` and one surviving label satisfies that. A desktop screenshot is
what caught it: two bare bar groups under a labelled one. The rule that falls out:
*a demand-derived cap answers "may this child have what it asked for", never "how
much room is there"* — so a decision every row must agree on is taken once from the
card's content width, and only a decision whose own width **is** the demand may
read the slot. Here that splits cleanly:

- the `-NN dBm` label cannot yield (4 fixed bars, 3 gaps, a 4px gap, an unwrapped
  `AppText`: **80.8px** at `-100 dBm`, 75.0px at a 2-digit reading, 22.0px with the
  label off), so it is decided from the card. Substituting into the allocator with
  the fixed 44px leading icon: `0.75 × (content − 64) − 44 ≥ 80.8` ⇒ **content ≥
  230.4px**, hence a threshold of 231. The realizations are 157.4px and 254.0px, so
  the label goes at the min realization only.
- the parent-node badge ellipsizes, so its own label width *is* what it demands.
  It is measured with a `TextPainter` — through ui_kit's own `AppTextVariant.resolve`,
  because `AppText` re-applies the design theme's body font bare and prepends the
  locale fallback, and measuring in the raw theme style measures a different font —
  and dropped exactly where it could only ellipsize, which is genuinely per-row:
  `N1` is 30.1px and its row is handed 32.6px at 191px, 288px **and** 512px, while
  `Extender-1` is 78.3px against 22.0px at 191px and 78.3px above it. Any fixed
  floor that rejects the second also rejects the first on a 1440px screen. A
  truncated node name is dropped rather than shown as `Ex…`, which names nothing and
  costs the device name beside it.

**2b. The gate is blind between the realizations, and that is where 175 shipped.**
The first threshold here was 174.7px, derived from the 25% content floor alone —
i.e. from the allocator's `floor`, ignoring the lend-back and the tile's own 32px of
padding. It is green on the gate at both realizations and overflows everywhere
between them, because the gate pumps only the *narrowest* realization of each span
(157.4px and 254.0px of content) and never the continuum a user reaches by dragging
a card:

| content | trailing cap | label kept at 175 | result |
|---:|---:|---|---|
| 175 | 39.3px | yes | **+33.0px right** |
| 200 | 58.0px | yes | **+17.0px right** |
| 216 | 70.0px | yes | **+5.0px right** |
| 229 | 79.8px | yes | **+1.0px right** |
| 230 | 80.5px | yes | **+0.287px right** |
| 231 | 81.3px | yes | clean |

Two lessons for the remaining tickets. First, **a threshold derived from a layout
rule must be derived from the whole rule** — the 25% floor is one of three terms,
and the two omitted ones (the lend-back, the tile padding) moved the answer by 56px.
Second, **a card-width threshold needs a test at widths the gate skips**: the
`connected_devices` readability file pumps 209/234/250/264/265px card widths and
asserts zero overflow, which is the only check on the branch that would have caught
this. `_tolerancePx` is 2.0, so the 230px case (+0.287px) would have passed the gate
even if it had pumped it.

Also worth carrying: the worst case is the *reading*, not just the width. A fixture
showing only `-45 dBm` (75.0px) clears at content 223 and would have justified 223;
`-100 dBm` is 80.8px and does not clear until 231. The readability fixture pins the
3-digit reading for that reason.

**3. The corollary for the readability tests: assert the count, not the
existence.** §2.10d point 3 said a fix owes a test when the gate stays green
through both the right and the wrong version. This branch adds the sharper form —
**a presence assertion is green through a partial deletion**. `isNotEmpty` over
five rows passes on one. The assertion that catches it is `labels.length ==
indicators.length`, and it is the only one of the file's 29 that mutation N (label
decided from the slot) kills. Fourteen mutations were run and every assertion in the
file is killed by at least one. Only three of the fourteen would also fail the gate;
mutation Q — the shipped-then-corrected 231 → 175 threshold — leaves overflow the
gate is *structurally* unable to see (point 2b), and the other ten take content away
without overflowing anything.

**4. Direct #1240 input: this card is green at 191px and unreadable there.** The
tile gives the device name **23.3px** (27.4px for the one row without a badge) —
one glyph and an ellipsis — and the IP the same, because the 44px leading icon and
the 22.0–32.6px trailing take 66px of a 141px row before the name is measured.
Both narrow realizations were screenshotted for the record. This is the third card
in a row to close its coordinates while staying unusable at its narrowest width
(§2.10d point 5), and it is the strongest case yet for #1240's compact form: the
degradation here is not the label or the badge, both of which were affordable —
it is the name.

So **#1238's AC 7 ("device names and connection details stay readable at the
narrowest clean width") is not met, and is not reachable from this call site** —
recorded here and on the issue rather than left unticked. What the fix owed AC 7 it
paid: nothing this branch does costs the name a pixel, and both things that could
have (the dBm label, the badge) are dropped at 191px precisely so they don't. The
23.3px that remains is the tile's own division of a 141px row between a fixed 44px
leading icon, a trailing slot, and the content column — the row's *shape*, not its
overflow — and changing it means a different row for narrow cards. That is #1240's
AC 1, the same conclusion #1228 reached about its own AC 5 (§2.12 point 3): a
readability AC that needs a compact form is inherited by Track B, not claimed by the
overflow ticket.

### 2.11 fl_chart's coordinates get a primary plan and a documented fallback

Six of `firewall_overview`'s remaining coordinates originate inside fl_chart
(`side_titles_widget.dart:245` — axis labels overflow at narrow widths), all at
`min` tab 1 in `da pl pt pt_PT ru sv`, by 5–10px on the **bottom**. This section
was written against an estimate of 19; 6 is the measured figure and the
discrepancy is discussed in §2.10d.

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

**#1230's other 15 coordinates are a height problem, so none of the four shapes
apply.** After #1247, what remains card-own is two sites, both overflowing on the
**bottom**, both at `min` tab 0:

| Site | Coordinates | Overflow |
|---|---:|---|
| `usp_firewall_overview_card.dart:157` — the donut's `centerWidget` `Column` | 8 | bottom, 15–31px |
| `usp_firewall_overview_card.dart:136` — the card's outer `Column` | 7 | bottom, 7–26px |

§2.10d's four shapes were all *width* fixes — make a `Row`'s non-flex child give.
A vertical overflow is a different failure: the card's declared height is too
small for the content it stacks, and no amount of `Flexible` on a horizontal axis
touches it. The two sites are also nested — `:136` is the outer `Column` that
holds the donut whose centre label is `:157` — so they must be measured together;
fixing the inner one changes what the outer one is asked to fit. The likely
levers are the declared `minHeightRows` for this card (an assertion to make, per
§2.9's last paragraph, not an allowlist in disguise) and dropping the donut's
centre caption at narrow width, which is the same information-density argument as
the axis labels above. **Not yet measured** — unlike the four shapes, this one has
no double-factor decomposition behind it, and that measurement is #1230's first
step.

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
| #1234 | `system_status` remaining ×3 sites (§2.10d) — **implemented** | 34 |
| #1236 | `lan_info` + `device_info` card-own (§2.10d) — **implemented** | 29 |
| #1237 | `time_settings` card-own (§2.10d) — **implemented** | 21 |
| #1235 | `network_health` gauge centre (§2.10d) — **implemented** | 3 |
| #1247 | `firewall_overview` `MapsToRow` — side effect, not its brief (§2.9a) — **implemented** | 46 |
| #1230 | `firewall_overview` remaining ×2 sites (§2.11) | 15 |
| #1238 | `connected_devices` ×2 card-own sites + the ui_kit v2.34.10 upgrade (§2.10e) — **implemented** | 27 |

Ceiling **528 / 560**, on the assumption that ui_kit's 26 stay blocked. They did
not: #1238 cleared all 27 after the v2.34.10 upgrade, so the ceiling is **554 /
560** and the only dependency-blocked coordinates left are fl_chart's 6.

After #1234–#1237, and after #1247's side effect was collected (§2.9a), the
allowlist holds **48** coordinates: 21 `firewall_overview` (#1230) and 27
`connected_devices` (#1238). Attributed per line rather than estimated:

| owner | coordinates | site | side |
|---|---:|---|---|
| #1230 | 8 | `usp_firewall_overview_card.dart:157` — the donut's `centerWidget` `Column` | bottom, 15–31px |
| #1230 | 7 | `usp_firewall_overview_card.dart:136` — the card's outer `Column` | bottom, 7–26px |
| #1230 | 6 | fl_chart `side_titles_widget.dart:245` | bottom, 5–10px |
| #1238 | 26 | three sites at once, one of them ui_kit `app_list_tile.dart:115` | right, 25–26px |
| #1238 | 1 | `usp_connected_devices_card.dart:79` only | right |

**16 are card-own and clearable in this repo** — #1230's 15 and #1238's 1. The
other **32** are dependency-blocked: fl_chart's 6 and the 26 that cannot go green
without a ui_kit change (they need the card's own two rows fixed as well, so
"blocked" means necessary-but-not-sufficient, not untouched).

That split held for exactly as long as the dependency did. ui_kit **v2.34.10**
shipped the `AppListTile` change (linksys/privacyGUI-UI-kit#20), and with it the 26
became call-site-fixable; #1238 cleared all 27 together, so the allowlist now holds
**21** — #1230's — and the blocked set is fl_chart's **6**. The
necessary-but-not-sufficient reading is what made this cheap: the two card-own
sites had to be fixed regardless, and they were the whole of the work once the
slot stopped being unbounded (§2.10e).

Two figures earlier in this document are contradicted by that attribution, both
downward:

- #1230 was scoped at 67 coordinates over "three own sites". Two sites remain;
  the third was the composed `portSummary → internalClient` row #1247 replaced.
- §1.1 classifies **19** coordinates as third-party-only (fl_chart). Measured,
  fl_chart names **6**, all at `min` tab 1, in `da pl pt pt_PT ru sv` — exactly
  the set `min|1` now narrows to. The two cannot both be right: a coordinate that
  *only* fl_chart breaks cannot be cleared by a card-own change, yet #1247's
  `MapsToRow` cleared 13 of the tab-1 coordinates the 19 was drawn from. So
  either those 13 were misclassified, or they had a card-own site §1.1's census
  did not record. Which one is no longer decidable — the baseline was measured
  against a tree that is 14 commits of layout work behind us, and re-deriving it
  would mean reverting all of them. **6 is the number to plan against**; §1.1's
  19 is left as written because its table is a record of what was believed at
  baseline and its rows sum to 560.

So the dependency-blocked share of the baseline is **32 of 560, not 45**, and
`firewall_overview` is a *height* problem now — all 21 of its coordinates are
bottom overflows, a different class from the four width shapes these tickets
settled. #1230 is still the largest single block of clearable coordinates left,
at 15 rather than 48. (And **6 of 560** after #1238, which is the whole of
fl_chart's; `firewall_overview` is the only card left in the allowlist.)

Their `tracking` notes are left as the epic requires: a ticket touches only the
notes of cards it closes, so both cards keep the `baseline #1183` default until
their own ticket names an owner. #1238 has since deleted `connected_devices`'
note along with its two keys, which is the same rule applied in the other
direction: the note exists to name a live blocker, so it goes when the block does.

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
| …plus two readability tests, added by #1234–#1237 | **Ratchet + a floor test** | The ratchet verifies that the overflow is gone. It cannot verify what the fix *chose*, in two situations, and both occurred on that branch (§2.10d point 3). (a) The fix makes a subtree self-relaxing, so the signal is gone for good: measured, shrinking the health score's font unconditionally clears all 209 of its gate cases. (b) Two fixes clear the same coordinates and only one preserves the reading: measured, `maxLines: 1` on the router IP, the DHCP status, or the InfoGrid value renderer leaves all 1644 cases green while cutting a string #1236 AC 4 / #1237 AC 5 require whole. The test is owed when **the gate stays green through both the right and the wrong fix** — not whenever a fix constrains. A plain `Flexible` is fully verified by the entry it deletes. |
| #1232 | **TDD** | The gate asserts only "no overflow"; it cannot detect *wrong density*. Threshold selection, popup cut-off, and absent-`normalAbove` behaviour can all break while the gate stays green. Tests go red first. |
| #1231 | **Neither** | Not an assertion — it fixes a failure the gate is structurally blind to (§2.8), so it is verified by eye or golden. |
| #1225 | **Property tests + no-op diff** | Planned as "neither", since converting a sampled invariant into a guaranteed one changes no assertion. In the event it had a testable seam after all: the search is pinned by a property (no supported width is narrower than the one pumped, which fails on a coarser step) and the no-op claim by diffing the full sweep's 560 allowlisted hits before and after — they matched exactly. |

The gate does **not** need to know a card's measured fit width to enforce
§2.4's `normalAbove >= fitWidth`: it applies the density rule at the card's
narrowest realization and pumps. A threshold set too low leaves the card in the
normal form at a width where it overflows, and the gate fails on that. No
fit-width measurement harness needs to exist at runtime or in CI.
