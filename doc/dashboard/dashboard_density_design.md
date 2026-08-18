# Dashboard Card Density — Design Decisions

**Last Updated: 2026-08-18** · Follow-up to #1183 · Status: **agreed; tickets #1225–#1240 published; Track A implemented through #1230 (#1225, #1226, #1233, #1227, #1228, #1229, #1266, #1234, #1236, #1237, #1235, #1247, #1230 — not all merged), #1238 remaining; Track B implemented except #1231 (#1232, #1239, #1240, #1288–#1291, #1299). Allowlist 560 → 27.**

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
added to it.** *Implemented* — the Article XIV conversation went the upstream
route, all five files migrated to the kit's `AppChartLegendEntry`, and both
constraints held: the distinction is now carried by the constructor name and the
WAN/LAN row declined the shared entry on a 6px measurement. See §2.10k.

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

**Re-measured after Track A (#1240 AC 1).** The table below is the post-Track-A
measurement. The pre-Track-A numbers that drove this design are kept underneath it,
because several sections still argue from them.

**Method.** Card width driven directly, screen held at 1920px, one card per pump,
at each card's `minHeightRows` — the same geometry and height the gate pumps.
**832 cases** = 18 cards × their tab counts × 26 locales. Clean means no incident
over the gate's own 2.0px tolerance. Fit width is found by continuous bisection to
4px between a 100px floor and a 1216px ceiling, which is licensed by the same
monotonicity-in-width that licensed the original ladder.

The floor is deliberately **below** the 191px the grid yields. Flooring at 191
censors every card clean there — 13 of 18 — and collapses their headroom to an
unusable "≥0", which makes `ethernet_ports` (≥91px of room) and `network_health`
(+3px) read identically. Widths below 191 are unreachable by a user; they are a
measuring stick, and a fit width at one is not a claim the card is usable there.

`headroom` = narrowest production width − fit width: the room the card has at the
worst width the grid can actually give it. `≥` marks a value censored by the floor.

| Card | Fit width | Narrowest production | Headroom | Binding (tab/locale) |
|---|---:|---:|---:|---|
| `stats_panel` | ≤100 | 288 | ≥188 | all |
| `topology` | 166 | 261 | +95 | t0/fi |
| `ethernet_ports` | ≤100 | 191 | ≥91 | all |
| `port_forwarding` | 170 | 261 | +91 | all |
| `system_status` | 127 | 191 | +64 | t0/vi |
| `device_analytics` | 197 | 261 | +64 | t0/de,el,nb,pt_PT |
| `network_status` | 131 | 191 | +60 | all |
| `time_settings` | 131 | 191 | +60 | all |
| `lan_info` | 140 | 191 | +51 | all |
| `wifi_status` | 217 | 261 | +44 | t0/el |
| `wifi_performance` | 232 | 261 | +29 | t2/fi |
| `device_info` | 170 | 191 | +21 | all |
| `connected_devices` | 173 | 191 | +18 | t0/el |
| `dhcp_reservations` | 245 | 261 | +16 | all |
| `wifi_networks` | 252 | 261 | +9 | all |
| `network_health` | 188 | 191 | **+3** | t0/de |
| `firewall_overview` | 188 | 191 | **+3** | t1/ja |
| `traffic_analysis` | 258 | 261 | **+3** | t1/zh,zh_TW |

**Every card fits at its narrowest production realization**, so per #1240 AC 2
("absent is the correct value, not a number") **no card declares a `normalAbove`
threshold**. Five cards appear here that §1.2 never covered, because they never had
coordinates: `topology`, `device_analytics`, `wifi_status`, `dhcp_reservations`,
`wifi_networks`.

⚠️ **Three cards sit +3px from overflowing** — `network_health` (t0 `de`),
`firewall_overview` (t1 `ja`), `traffic_analysis` (t1 `zh`/`zh_TW`) — against a
2.0px measurement tolerance, i.e. 1px outside the noise floor. A new locale, a font
bump or a padding change in a shared block flips any of them to a gate failure. The
gate reports pass/fail, not margin, so it cannot see this coming.

#### Pre-Track-A measurement (superseded, kept for the sections that cite it)

14-rung ladder (191 → 1216px), floored at 191, 624 cases. Rung-quantized and
censored at the floor, so a `760 → ≤100` move is not a precise −660.

| Card | Declared min → px | Fit width | Now |
|---|---:|---:|---:|
| `stats_panel` | 6 → 288 | 760 | ≤100 |
| `traffic_analysis` | 4 → 260 | 560 | 258 |
| `device_info` | 3 → 191 | 480 | 170 |
| `lan_info` | 3 → 191 | 420 | 140 |
| `wifi_performance` | 3 → 191 | 420 | 232 |
| `ethernet_ports` | 4 → 260 | 420 | ≤100 |
| `network_health` | 4 → 260 | 420 | 188 |
| `firewall_overview` | 3 → 191 | 360 | 188 |
| `system_status` | 4 → 260 | 360 | 127 |
| `connected_devices` | 4 → 260 | 320 | 173 |
| `network_status` | 3 → 191 | 320 | 131 |
| `port_forwarding` | 3 → 191 | 320 | 170 |
| `time_settings` | 3 → 191 | 288 | 131 |

Both caveats this table used to carry are discharged. `system_status`'s 360 was an
underestimate because it read `context.colWidth` while the harness held the screen
wide; #1231/#1251 landed and no card reads a screen-derived width any more (the only
remaining reader is `usp_sliver_dashboard_view.dart`, the grid host). Its measured
fit is 127. `connected_devices`' 320 was flagged stale by 129px; measured, it is 173.

**Track A moved this column and *only* this column.** The width at which each card
is *readable* has not moved at all (§2.10d point 5, §2.10e point 4) — see §2.6,
§2.11a and §2.12 for the three readability limits that survive at full strength.

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

⚠️ **This section's premise no longer holds after Track A, and it was the
load-bearing argument for the whole design.** It was true of the fit widths above
it; it is false of the re-measured ones. Every card now fits at its own narrowest
column count (§1.2), so widening is not the unavailable option — it is unnecessary,
and no card declares a threshold.

What survives is the distinction §1.2 drew before the measurement was taken: Track A
moved the *overflow* column and only that column. The width at which each card is
**readable** has not moved, so the remaining density work (#1232, #1239, #1240) is
readability-driven and can no longer cite overflow as its justification. The three
live limits are `connected_devices`' 23-27px device name (§2.6), `ethernet_ports`'
0px port-state sliver (§2.12) and `firewall_overview`'s unbreakable `fi`/`nb` metric
labels (§2.11a).

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

⚠️ Pre-Track-A, like §1.3. On the re-measured fit widths every card is clean at
every width the grid can produce, so the question this section answers — which
global threshold makes the set safe — no longer has a live case. Kept as the record
of why per-card thresholds beat a global one, should a threshold ever be needed.

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

> **Amended in #1299 (implemented).** The width still selects the form wherever
> nobody has said otherwise, and it is still the only mechanism that *guarantees*
> a card fits. What the clause got wrong is "the width is already the consequence
> of a user action": on the 4-column grid the layout pins `x: 0, w: cols` and
> #1293's left-edge lock forbids horizontal resizing outright, so a phone user has
> no width to act on — and therefore no access to the two forms this design built
> for narrow cards. So a card's form is **also selectable, in edit mode**, and the
> pick then constrains the geometry instead of the geometry selecting the pick.
> The responsibility does not move onto the user: every reachable pairing of form
> and box is still one the framework guarantees, because the pick decides which
> boxes are legal (popup collapses the card and takes its resize handles; compact
> raises its floor). An explicit `normal` pick is the *removal* of a pick, not a
> pin, so this table keeps describing every card nobody has chosen a form for.
> §2.6i records the inversion.

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

### 2.6b What building the mechanism taught us (#1232 — implemented)

Built as specified: `CardDensity` (popup / compact / normal) with
`densityForWidth`, `normalAbove` on `WidgetSpec`, `cardDensityOverrideProvider`,
and `CardDensityScope` / `CardDensityHost` applied inside
`UspWidgetFactory.buildWidget` — the one place production and the gate both
construct cards. No card's rendering changed and `known_overflows.json` is
untouched (gate 1644/1644).

**It has no consumers, and that is the measurement's verdict, not an omission.**
§1.2's re-measurement found all 18 cards clean at their narrowest realization, so
by §2.4 every spec declares absent — which means the selection returns `normal`
at every width for every card in the app today. The mechanism is in place for the
first card that needs it; nothing degrades until one does.

1. **`normalAbove` has to dominate the 200px popup constant, or a threshold below
   200px is undefined.** Two plausible orders disagree: check popup first and a
   card declaring `normalAbove: 180` renders popup at 190px *even though it just
   said it is whole at 180*. The declared threshold wins, so such a card has an
   empty compact band and degrades straight to popup below 200px. Declaring one is
   almost certainly a mistake, but the behaviour is now stated and pinned rather
   than emergent.

2. **The measurement is skipped when no threshold is declared — and the skip is
   not load-bearing.** With `normalAbove` absent the density is a constant, so
   wrapping the card in a `LayoutBuilder` would rebuild its whole subtree once per
   layout pass during a drag-resize to recompute a value that cannot change. To
   check that the skip is an optimization and not a crutch, the gate was also run
   with it removed, so all 18 cards rendered through the `LayoutBuilder`: still
   1644/1644. **Inserting the measurement is layout-neutral**, which matters for
   whichever ticket declares the first threshold — it will not be taking on that
   risk at the same time as a rendering change.

3. **A density test under a bounded ancestor can assert nothing.** The test that
   proves selection reads the *card* and not the *screen* pumps a 600px card on a
   320px screen. Under a normal ancestor `SizedBox(width: 600)` silently resolves
   to `constraints.constrain(600)` = 320, so the card is handed the screen width
   and a screen-reading implementation passes. It only became a real test once the
   ancestor was made width-unbounded. Same family as §1.6's sampling artifact: the
   harness quietly supplied the number the test was trying to vary.

4. **Whether popup is opt-in is now #1239's to settle.** §2.1 states popup applies
   below 200px, but selection is reached only through a declared `normalAbove`, so
   as things stand no card gets a popup form either — the 200px constant currently
   describes a band nothing enters. #1239 has to choose: popup stays opt-in (a card
   wanting it declares a threshold), or it becomes universal below 200px
   independent of `normalAbove`. The second reading conflicts with §2.4's "absent
   asserts this card needs no degraded form", so the first is the consistent one —
   but it should be decided in #1239, not inherited by accident from this ticket's
   precedence rule.

   **Settled in #1239 as opt-in** (§2.6c), which also found that the band is
   unreachable for half the cards regardless — see §2.6c item 1 before reading
   "compact has no consumers" above as a verdict on the middle band.

### 2.6c What building the popup form taught us (#1239 — implemented)

Built as specified: `CardPopupForm` (icon + one value + tap target) selected inside
`DashboardCardTemplate.build`, and `showCardNormalForm` presenting the card's full
form in an `AppDialog` — or an `AppBottomSheet` where a dialog cannot serve. No
card's rendering changed and `known_overflows.json` is untouched (gate 1644/1644).
16 behaviour tests plus a 265-case sweep of the popup form and the dialog it
opens.

**Popup is opt-in — §2.6b item 4 is settled that way.** A card reaches the popup
form only through a declared `normalAbove`, which keeps §2.4's "absent asserts
this card needs no degraded form" true. The 200px constant still describes a band
nothing enters today, and that is now a decision rather than an accident.

1. **Nine of the eighteen widgets can never reach the popup band at all, and it is
   `minColumns` that decides.** Selection compares the *rendered* width against
   200px, so a card the grid cannot make narrow enough has no popup form at any
   width, whatever it declares. The grid's narrowest realizations are **191.4px
   for a 3-column floor, 260.5px for a 4-column floor, and 288px for anything
   wider** (a full-width card clamped to the 4-column mobile grid). Only the first
   is under 200. So the popup form applies to exactly the nine `minColumns: 3`
   cards — `device_info`, `network_status`, `lan_info`, `ethernet_ports`,
   `system_status`, `connected_devices`, `time_settings`, `network_health`,
   `firewall_overview` — and the other nine (`stats_panel`, `topology`,
   `wifi_status`, `wifi_networks`, `dhcp_reservations`, `port_forwarding`,
   `wifi_performance`, `traffic_analysis`, `device_analytics`) are floored above
   it.

   **This is what the compact band is for.** §2.6b recorded that compact had no
   consumers and read that as the measurement's verdict; it is more specific than
   that. Compact is the *only* degraded form those nine cards can ever reach — so
   the middle band is not dead by construction, it is the sole degradation
   available to half the dashboard. #1240 should therefore not treat compact as
   the band to skip: for a `minColumns: 4` card it is the only option there is.

   The widths are not new — #1239's own "Reachability, for expectation-setting"
   paragraph states them, and D3 already said popup never fires on a phone. What
   the sweep added is the per-card inventory and the conclusion drawn from it: the
   ticket framed reachability as *when* popup triggers (manual shrinking on
   tablet/desktop), and the inventory shows it is also *which cards* can trigger
   it at all — half of them cannot, which is what reassigns the compact band from
   "no consumers" to "the only option for these nine".

2. **`stats_panel` is not a card, and the exemption is worth two assertions.** It
   is the full-width summary strip — five `StatTile`s in a `Row`, no title, no
   icon, no single value, and no `DashboardCardTemplate`. It is skipped for the
   geometric reason above *and* for that structural one, and it is the only widget
   of which the second is true: the other eight would gain a popup form the moment
   their `minColumns` allowed a 3-column span. Both halves are pinned, so the skip
   list cannot be read as "these cards may bypass the template".

3. **The dialog's max width has to be a width for the *card*, not for the
   dialog.** `AppDialog` constrains its own box, then spends `padding.horizontal`
   inside it, and `AppSurface` draws its border *inside* that too — so asking for
   `normalAbove` yields a card `padding.horizontal + 2·borderWidth` narrower than
   it just said it needs, which reproduces the exact overflow the popup form
   exists to avoid. Chrome is counted from `DialogStyle` and added on, and the
   test asserts the presented form measures **exactly 400.0** for a card declaring
   400 (§1.9's theme override is the injection point, caller-side per Article
   XIV — nothing in ui_kit changes).

4. **The sheet branch is a relationship, not a breakpoint — and no dialog is ever
   squeezed.** The switch fires when what a dialog can offer (`screen − 2·24 −
   chrome`) is narrower than the card's declared fit width, so it is reachable at
   the 320px floor by construction rather than at an invented pixel threshold. The
   consequence only became visible through a test written wrong: "the dialog never
   grows past the screen" was pumped at a 2000px fit width on a 600px screen and
   found *no dialog at all*, because that is precisely the sheet case. A wide card
   on a mid-size screen takes the sheet too. The presentation never narrows a
   dialog below what the card asked for; it changes presentation instead. The test
   now asserts that.

5. **The normal form requires a bounded height, so the presentation must supply
   one — and the popup form already knows it.** `DashboardCardTemplate` puts its
   content in an `Expanded`, so presenting the card in a dialog with unbounded
   height cannot lay out. The height needed is the one the grid gave this card,
   and the popup form occupies that whole grid cell — so it is read from
   `context.size?.height` at tap time (after layout), rather than by looking the
   spec's `minHeightRows` up or introducing a slot-height constant into
   production. `_slotHeight` stays private in `UspSliverDashboardView`.

6. **`normalForm: this` is what keeps the two forms from drifting.** The template
   passes itself as the widget the tap opens, re-rendered under a normal-density
   scope. Nothing is rebuilt or re-specified, so there is no second definition of
   the card to keep in sync — and no duplicate-`GlobalKey` hazard, since the
   normal form's children are not mounted while the popup form is displayed.

7. **The probe needed an `after` hook, and it does not weaken the one-pump
   rule.** Opening the dialog is itself a layout event, occurring after
   `probeCardOverflow` would have returned — so its overflow would be raised with
   no handler installed and lost. The hook runs the tap inside the collection. It
   pumps no second widget tree, so §2.9's one-pump-per-test property (a RenderFlex
   reports its overflow once per render-object lifetime) still holds: the dialog's
   render objects are new and the card's are untouched.

### 2.6d What re-measuring every fit width taught us (#1240 — implemented)

The umbrella ticket, whose output is a decision and a split rather than a card
fix. Its full fit-width table lives on the issue (#1240, AC 1 comment); five
things came out of the measurement that belong in the design.

1. **All 18 cards fit, so no card declares a threshold — and the ticket's own
   headline deliverable evaporates.** #1240 was written as *"each card that needs
   one declares a `normalAbove` threshold and gains a compact form"*, from a table
   whose worst entry was `stats_panel` at 760px. Re-measured after Track A, the
   widest fit width in the registry is `wifi_networks` at 252px against a 261px
   floor, and `stats_panel` is the *best* card in the set (clean below 100px,
   ≥188px of room). AC 2 — *"cards that fit at their narrowest realization declare
   **no** threshold"* — therefore decides every card in the registry, and §1.3's
   load-bearing claim (*"graceful degradation is not the preferred option; it is
   the only option"*) is false of the code as it now stands. `densityForWidth`
   records this in its dartdoc so the next reader does not have to re-derive it.

2. **Overflow and readability moved apart, and only one of them moved.** §1.2 said
   this would happen — *"Track A has moved this column for every card it has
   closed and only this column"* — and the zero-coordinate ratchet is what makes
   it visible: six cards render content that cannot be read at a width where
   nothing overflows. Re-shot at this branch head, not inherited from the earlier
   measurement:

   | card | locale | at 191px | at 288px |
   |---|---|---|---|
   | `device_info` | `ru` | `MR7500` one glyph per line, clipped after `M R 7 5` | reads |
   | `lan_info` | `ru` | IP split `192.1`/`68.1.1`; `Включено` cut mid-word | reads |
   | `time_settings` | `ru` | timestamp over 5 lines; `America/…` clipped mid-glyph | reads |
   | `network_health` | `de` | ring shrunk to ~40px, `Mittelmäßig` painted over it, labels `Ver/wor/fen/e/Pak/ete` | tier still overlaps the ring; legend ellipsized |
   | `connected_devices` | `el` | device names are `D…` and `i…` — one glyph and an ellipsis | reads |
   | `ethernet_ports` | `en` | port grid entirely below the viewport — 0px of glyph | still 0px |

   The first three are one shape hand-rolled three times (a `LayoutBlock` holding
   a 56-72px icon, an `AppGap.lg` and an `Expanded` hero value, which leaves the
   value 61.4px), which is why they are batched together below. `ethernet_ports`
   is the only card unreadable at **both** narrow realizations, and the only one
   whose fix cannot be a threshold alone.

3. **The remaining work needs a compact form, not just a threshold — because the
   band that needs one is reachable and the popup form does not cover it.** Below
   200px the popup form (#1239) is a complete answer: it replaces an unreadable
   card with an icon, one value and a tap. But five of the six cards above read at
   288px and not at 191px, so an honest threshold sits between them, and §1.5's
   range (a 3-column card spans 191.4-422.0px) says every width in that interval
   is reachable. So each card owes a compact form for `[200, normalAbove)` —
   exactly #1240's original deliverable, arriving with a readability justification
   instead of an overflow one.

4. **AC 4 is only exercisable on a synthetic card now, which is itself the
   finding.** *"The gate fails when a threshold is set too low — verified by
   deliberately lowering one"* assumed a too-low threshold leaves a card in a form
   that overflows. With every card clean at every reachable width, no threshold any
   of them could declare produces an overflow: the failure mode a wrong threshold
   causes today is *illegibility*, which the gate cannot see, and its mirror image
   — a threshold set too **high**, which blanks a card into a popup form and turns
   the gate green — is the one §2.11a point 4 warned about. So the AC is honoured
   in `card_popup_form_test.dart` on a card built to overflow (a 400px child in a
   `Row`), as a pair: threshold 150 at a 191px width keeps the normal form and the
   overflow is reported; threshold 400 selects popup and is clean. The control
   matters — without it the test passes on a card that overflows in every form.

5. **One claim this epic carried was wrong, and measuring it retired it.** #1183's
   body and #1240's AC 1 comment both said `firewall_overview`'s Finnish and
   Norwegian metric labels *"are single words that can only break mid-word"*, and
   treated that as a readability defect on par with the six above. Measured across
   all 26 locales at both label-column widths the stacked arrangement produces
   (111.4px and 127.6px, §2.11a point 1): `didExceedMaxLines` is **false in all 78
   cases**. `PALOMUURISÄÄNNÖT` is 131.0px and does break mid-word, onto two lines
   that both render in full; `BRANNMURREGLER` (118.6px) takes two lines at 111.4px
   and one at 127.6px; the widest label in the registry is `ru`'s 143.2px, also
   over two lines. `maxLines: 2` is what makes the difference, and #1230 chose it
   deliberately. So the break is real and the loss is not — a hyphenation nicety,
   not a legibility defect, and not batched below. The general form: *"wraps
   mid-word"* names how text broke, not whether it can be read; the question is
   whether anything was **cut**, and only the ellipsis flag answers that.

The split AC 8 asks for, batched by shared site per §1.1, with the measurement each
batch inherits recorded on it:

| batch | ticket | what it owes beyond a threshold |
|---|---|---|
| hero row — `device_info`, `lan_info`, `time_settings` | #1288 | a compact hero for one shape hand-rolled three times, without reaching for the ellipsis `usp_hero_row_readability_test.dart` forbids |
| `connected_devices` device row | #1289 | a compact row; carries #1238's AC 7 |
| `ethernet_ports` port list | #1290 | the **first real compact form**, and a threshold above 288px; carries #1240 AC 9 = #1228 AC 5 |
| `network_health` gauge centre + metric chips | #1291 | a compact metric row that gives the gauge its height back, so #1235's `scaleDown` relaxes toward 1.0 |

What each batch actually cost is recorded as it lands: §2.6e (#1288), §2.6f (#1289),
§2.6g (#1291), §2.6h (#1290).

### 2.6e What declaring the first thresholds taught us (#1288 — implemented)

Three specs — `device_info` 262, `lan_info` 250, `time_settings` 256 — became the
first in the registry to declare a `normalAbove`, which makes them the first
evidence about the mechanism §2.4 designed. Four things came out of it.

1. **The first thresholds in the dashboard exist for readability, and §2.6d point 1
   stands unrevised.** #1240 measured every card as *fitting* at its narrowest
   realization and correctly left every threshold absent; #1288 asked whether the
   same cards can be *read* there and found three that cannot. Both are true of the
   same code, which is the whole reason §1.2 splits the two columns. The practical
   consequence is that a threshold is now derived from a **token measurement**, so
   each spec carries its arithmetic decomposition — card chrome + hero fixed cost +
   widest token — rather than the number alone. `lan_info` is why: its binding
   string is the *subtitle*'s longest token in `el` (107.2px), beating the IP
   address by 1.4px. Nobody would have guessed that, and nobody has to, because the
   decomposition says which term moved when a hero is next edited.

2. **A mid-word break is a defect in a datum and a nicety in a word — the same
   fact §2.6d point 5 read the other way.** #1240 retired the claim that
   `firewall_overview`'s `PALOMUURISÄÄNNÖT` is a readability defect: it breaks
   mid-word onto two lines that both render in full, and nothing is cut. #1288's
   hero criterion is stricter — a card reads when no line break falls inside a
   token — and both are right, because a metric *label* is a word the reader
   reconstructs while a hero value is a *datum* whose reading changes when it
   breaks. `192.1` / `68.1.1` is not a hyphenated address; it is two numbers. So the
   criterion attaches to what the string **is**, not to how it broke, and #1289
   sharpened the same distinction into bounded vs unbounded (§2.6f point 2).

3. **Both directions of this are invisible to the #1183 gate, and one of them
   inverts it.** `widestTokenWidth` and `hasSplitToken` had to be added to the
   readability probe because a mid-word break makes text *narrower* — the more
   badly a hero degrades, the greener the gate gets. This is the same asymmetry
   §2.11a point 4 warned about from the popup side, now measured from the wrapping
   side, and it is why every batch in this table owes a readability suite rather
   than a gate exemption.

4. **Declaring a threshold retro-invalidates the readability suite that motivated
   it.** `usp_hero_row_readability_test.dart` was written when production rendered
   the normal form at 191.4px; the moment the spec declared 262, production
   rendered the *popup* form there and every assertion failed on a missing widget
   rather than on unreadable content. The fix is a one-line pin (`CardDensity.normal`)
   and the assertions keep their meaning — 191.4px is still the narrowest width the
   normal form can be asked for — but the sequencing lesson generalizes: **every**
   remaining batch should expect its own readability file to break on the commit
   that fixes the card, and should pin rather than re-measure. #1289 hit exactly
   this (§2.6f point 5) and cost nothing to fix because #1288 had already named it.

### 2.6f What a threshold above the realization taught us (#1289 — implemented)

`connected_devices` declares `normalAbove: 336` — the first threshold in the
registry **above** the 288px realization the grid most often hands out, where all
three of #1288's cards sit below it. That inversion is the section.

1. **A threshold is not "the floor at which a card stops being broken"; it is the
   width at which the *normal* form earns being selected.** #1288's hero cards read
   at 288px and only need help at the 191px floor, so their thresholds land below
   288 and the compact band is a narrow strip nothing realizes. This card ellipsizes
   four of its five fixture device names at 288px, so 288px is precisely where the
   compact form has to be chosen for it to be worth having. `usp_connected_devices_density_test.dart`
   therefore asserts `normalAbove >= widestRealization`, the deliberate inversion of
   the `<= 288` bound its hero-row counterpart asserts — and the two bounds
   disagreeing is the correct outcome, not a rule that needs unifying.

2. **The criterion that decides what a threshold protects: a bounded token must
   never ellipsize, an unbounded one may.** This card's "nothing ellipsizes" width
   is 330px in all 26 locales, bound by a fixture device *name*. Shipping 330 would
   have encoded the fixture, because a device name is unbounded router data — no
   width fits an arbitrary one, and `MacBook-A…` still identifies a device.
   `192.168.1.…` identifies no host, so the address is what the number protects, and
   a full 15-character quad (93.1px) is what it was measured against. Locale
   invariance follows from the same fact rather than from luck: the widest thing on
   this card is data, not a translated string.

3. **A per-row rule cannot decline a demand that is inside its own budget — which
   is how you tell a card fix from a threshold.** The parent-node badge is sized
   `min(nodeName + 16, 100)`, and it has a per-row drop rule: it goes when the
   trailing slot cannot seat the name **whole**. But a name at the 100px cap *is*
   whole at 100px by definition, so from 311px up the rule is satisfied, the badge
   stays, and a capped name leaves the address 69.0px of the 93.1px it needs. The
   mutation ledger confirms it from the other side: re-admitting the badge clips the
   address at 200px but not at 288px, because at 288px the slot is too narrow to
   seat a capped name and the rule fires on its own. **The rule protects the bottom
   of the band and goes quiet exactly where the problem is.** A bounded demand that
   some width can retire belongs in the threshold; the alternative — a second rule
   that declines a demand it already approved — is a rule arguing with itself.

4. **A compact form must be clean across its whole band, not at the widths the grid
   realizes.** The band `[200, 336)` was swept at 1px in all 26 locales, and so was
   `[336, 520]` for the normal form. This is more than the two realizations need,
   and §1.5 is why it is the right amount: a 3-column span is 228.5px on a 700px
   screen, so the interval is reachable even though no default layout produces it. A
   band no test enters is a band whose contents were never seen.

5. **The sweep found a half-pixel the gate cannot, and the derivation error behind
   it is repeatable.** At a 330px card — content exactly 296px — `el`'s status
   counts overflowed their half by 0.264px, live in the normal form since #1238 and
   nothing to do with density. #1238 derived 289.4px for that threshold and read the
   6.6px up to 296 as slack; the true demand is 296.264px, so 296 was a knife edge
   landed on exactly. Two lessons, both general: derive a threshold as **widest
   failing + 1**, never as *demand + eyeballed slack*; and when arguing that no
   width lands near a constant, measure **widths**, not realizations — #1238's
   justification ("nothing lands within 200px of it") compared the realized content
   widths either side and a user drags cards to any span the grid offers. The gate
   was blind twice over: 0.264px is inside its 2.0px tolerance, and it never pumps
   330px. The test that guards it asserts on *layout* — which line the second count
   sits on — because a pixel assertion at that scale cannot survive two rasterizers.

### 2.6g What the first tabbed threshold taught us (#1291 — implemented)

`network_health` declares `normalAbove: 366` and drops its metric row whole in
compact, which returns 165px to a gauge that was scaling itself down to fit
(#1235's `BoxFit.scaleDown`). At 288px in production the gauge is back to 120×120
at scale **1.000** in 25 locales (`ru` 0.973, width-bound), with no change to the
centre. Three things came out of it that no earlier batch could have found.

1. **`cardContentViewport` does not answer "visible" on a tabbed card, and it
   fails by returning the wrong box rather than by throwing.** The helper takes the
   shorter of exactly two `SingleChildScrollView`s — the pump harness and the
   template's content — but `DashboardCardTemplate` hands tab content back directly
   because "charts need fixed space" (`dashboard_card_template.dart:340`). Measured,
   it returned `53.0–97.0`: `AppTabs`' own horizontal scroller, while the gauge
   occupied `141.5–261.5`. The frame that is correct here is the card's own box
   (`CardDensityHost`), and it is correct *because* nothing in this card scrolls —
   tab content sits in a fixed `Expanded`. So the choice of frame is a per-card
   measurement, not a house style: use the scrolling viewport where the card
   scrolls, the card box where it does not, and state which in the test.

2. **Declaring a threshold on a *tabbed* card breaks a gate meta-test that is not
   about overflow.** The tab-registry guard counted visible tabs at
   `widthCasesFor(spec).first` = 191.375px; that pump now returns the tab-less popup
   form, and the guard read 0 tabs as "the card lost its tabs". It counts at
   `desktopCaseFor(spec)` instead: *how many tabs a card has* is a property of its
   whole form, while *which form a width selects* is a density claim that belongs to
   the density suite. Case count unchanged — this is a frame correction, not a
   suppression.

3. **Coverage does not move when a threshold lands; it leaves.**
   `usp_gauge_center_readability_test.dart`'s own ledger recorded two mutations
   (removing the gauge's `FittedBox`; ellipsizing score and tier instead of scaling)
   as failing the 1644-case gate 3× and 2×. After `normalAbove: 366` both are
   **green** there — not because the mutations became safe, but because production
   no longer renders the gauge at 191.375px at all. The density suite and that file
   are now the only guard on those rows. Generalized: **every mutation ledger that
   claims a gate column is dated by the thresholds in force when it was measured**,
   so a batch that declares one owes a re-measurement of the older ledgers on the
   same card, and the correction belongs in the file rather than in a commit
   message.

### 2.6h What the first real compact form taught us (#1290 — implemented)

`ethernet_ports` is the card §2.12 point 3 recorded as *losing* 41px of port glyph
to #1228's tile stacking, and the only one of the six unreadable at **both** narrow
realizations. It declares `normalAbove: 386`, `popupValue: '3/5'` (ports up over
ports present), and a compact port list of five 32px chips. Five lessons, the first
of which invalidates the shape of the acceptance criterion itself.

1. **A card can have no readability *width*, because its binding constraint is
   vertical — and then the threshold cannot be "the width at which it reads".** AC 1
   asked for "the width at which the port grid seats inside the content viewport".
   Measured in the pinned normal form over a 4px sweep of `[200, 700]` in `de`, `ru`
   and `en`: **0 of 5 port items seat at every one of the 126 widths**, and every
   glyph measures 0.0px at both narrow realizations in all 26 locales. One 82px item
   starting below a 96–136px block of summary tiles cannot land inside a 121px
   viewport at any width; widening the card only reflows the `Wrap`. What the sweep
   *did* find are two real coordinates, neither of them a floor: **386**, where the
   content column first reaches 352px and the tiles stop stacking (1px sweep:
   stacked at 385, side by side at 386) — which is the 41px → 0px regression in a
   single number — and **570**, where all five items fit one run. 570 is rejected
   for being above `desktopCaseFor` (512): declaring it would put the mainstream
   desktop realization in compact and contradict the same ticket's "the full grid is
   intact at desktop". So the threshold shipped is *the width above which the normal
   form stops costing the ports their glyphs*, and the compact form — not the
   threshold — is what makes the card readable. **Where the constraint is height,
   ask a threshold to stop a loss, not to fix one.**

2. **Two thresholds on one card coexist when they read different boxes — and the
   one the grid can no longer reach is still reachable from the presentation.**
   `normalAbove` is read against the width the *grid* gives the card and selects a
   form; `_kSideBySideMinWidth: 352` is read against the *content column* and
   arranges the tiles inside whichever box the normal form landed in. From the grid
   they can no longer disagree (386 is exactly the card width at which content
   reaches 352), which reads as "the stacked branch is dead code" — and it is not.
   `showCardNormalForm` renders that same normal form in a dialog, or a full-bleed
   sheet on a screen too narrow to host one, at up to `normalAbove`: a 320px phone
   tapping the popup form gets ~284px of content, squarely inside the stacked band.
   Deleting the constant would put that phone back on the arrangement #1228 measured
   as overflowing by 1.3px while rendering no label at all. **A branch unreachable
   from the grid is not unreachable; the popup form's tap target is a second frame
   in which every card's normal form gets narrow widths on purpose** (§2.6c).

3. **Compact may shed a fact, never a signal.** The chips keep the glyph (whose
   tint *is* the up/down state) and the speed, because `speedLabel` reads `—` for a
   port that is down and is therefore the *textual* half of that state — dropping it
   would leave a colour-blind reader with less than the wide form gave them. What
   goes is the connected-device line, unbounded router data that the tap shows in
   full. The two summary tiles go with it, and that is the same test: their content
   is a count derivable from the chips now visible, where the ports they displaced
   were not derivable from anything.

4. **A mutation ledger has to name *which* test failed, because an assertion that
   cannot fail counts as coverage until you check.** The chip's text column is capped
   at 72px so that a port label from unknown future hardware cannot overflow the
   `Wrap` — and the mutation that removes the cap killed **nothing**: the fixture's
   labels are `LAN 1`, so the in-band assertion `chipWidth <= 96` can never fail
   however the cap is set. It became a real assertion only once the suite grew a pump
   that injects a pathological label (via `cardOverride` plus a hand-built
   `CardDensityHost`, since the host is applied inside `UspWidgetFactory`), after
   which it kills exactly one test. The always-passing loop was deleted with the
   reason written in its place. The first draft of the ledger read counts off "…and N
   more" output and got two rows wrong; a ledger is a measurement, so it is read off
   the `+N -M` summary and the per-test failure names.

5. **§2.6e point 4's retro-invalidation is not confined to the card's own
   readability file.** This batch's pin was expected on
   `ethernet_ports_summary_readability_test.dart` and applied there. What was not
   expected: running the whole `dashboard-card` tag surfaced **12 failures in
   `dashboard_legend_readability_test.dart`**, all `network_health` — collateral from
   #1291's threshold, in a file that belongs to #1233 and names neither card in its
   title. The remedy is the same one-line pin, threaded only through the
   `network_health` pumps (`system_status` declares no threshold and stays unpinned,
   so it keeps failing the day someone gives it one). The process lesson: **a batch
   verifies against the whole tag, not against its own files** — a threshold is a
   registry-wide change, and the suites it invalidates are indexed by card, not by
   ticket. And the pin's justification has shifted with point 2: it is no longer
   "191.4px is still the narrowest width the normal form can be asked for" but "this
   is the form the presentation shows at that width".

### 2.6i What inverting the mechanism taught us (#1299 — implemented)

Every section above runs #1232's arrow: the grid gives a card a width, and the
width picks the form. This one runs it backwards. A card's form is **selectable in
edit mode**, and the pick decides which sizes are legal — popup pins the box and
takes the resize handles, compact raises the floor, normal restores the spec's own
bounds. §2.1's "not a user preference" clause is amended in place with the reason;
the short version is that the clause assumed a user who can change a card's width,
and on a phone there is no such user (§2.1's own "never triggers on a phone" is the
same fact seen from the other side).

Built as `CardFormChoice` / `CardForms` (`cardFormsProvider`),
`UspWidgetSpecs.selectableForms` + `applyCardForms`, a per-breakpoint `forms` map in
`UspLayoutEnvelope`, and a `CardFormBar` row under the edit-mode toolbar that acts on
the card selected in the grid. `DisplayMode` is **not** revived: it is the abandoned
three-value enum §2.6 replaced, and a second spelling of the same idea would be two
things to keep in agreement. Seven lessons.

1. **Four decisions were recorded on the issue before the code; the fifth only
   appears once you write the reader.** The recorded four: popup collapses to 2×1 on
   the 8/12-column grids remembering the previous box; on the 4-column grid popup
   owns the height only and the card stays full width; widening does not re-promote a
   card the user set to compact; and compact's left edge becomes a move. What none of
   them says is what an explicit **`normal`** pick means. Read as a pin it is a hole
   in §1's whole argument — a user could park `lan_info` at its 191.4px realization
   in its full form, which is the overflow this epic exists to remove. So normal is
   the *removal* of a pick and the width rule takes over, and the asymmetry is
   deliberate: **a pick may only ever narrow the set of boxes the framework
   considers legal, never widen it.** Pinned in `card_form_control_test.dart` as "an
   explicit normal pick does not pin".

2. **The placement was gated on a mitigation that does not exist, and only the spike
   could tell.** The ticket's fallback condition was "if `cancelInteraction()` cannot
   undo an accidental drag, put the control in the dialog". It cannot:
   `DashboardOverlay._onPointerUp` commits the drag *after* the restore, so the card
   moves anyway. Two more findings came with it — a control inside the edit-mode
   `AbsorbPointer` receives no pointers at all (on-card placement is not "add a
   button", it is "hoist a button out of the widget that exists to make the card
   inert"), and the overlay's raw `Listener` is behind `_isMobile`, i.e. **the
   platform, not the pointer kind**, so on a phone a drag needs a long press and a tap
   is safe while on desktop pointer-down arms a drag with no slop threshold. The spike
   is kept as `density_control_gesture_spike_test.dart` rather than written up and
   deleted: **a placement justified by package behaviour needs the behaviour asserted,
   or the next package bump silently removes the justification.**

   **The spike ruled out one placement; it did not choose the next, and the first
   answer it was read as choosing was wrong.** "Not on the card" was taken to mean the
   layout settings dialog, and that shipped: one labelled row per card, every card in
   a list. Rejected on sight in review as counter-intuitive, and correctly — it asks
   the user to find the card they are looking at in a list of names, inside a dialog
   covering the grid they were looking at it in. What the spike's own findings already
   contained is the answer: on desktop a pointer-down on a card *selects* it (the
   package's `toggleSelection`), on mobile a tap does, the selection survives
   pointer-up, and edit mode already draws a border around it. So the gesture the
   feature needs was there — select the card, then shape it, the same pair as select
   then drag and select then trash — and only the control was missing. It became a row
   under the toolbar, naming the selected card with a picker beside it, prompting when
   nothing is selected. Two constraints fell out of measuring rather than sketching:
   a **fifth** header icon button was not available, because that header `Row` already
   overflows below 480px with the four it has (pre-existing, #1183's own budget, not
   this ticket's), and the row keeps its height when empty, because one that appeared
   on selection would shove the grid down on every card tap. Generalized: **a spike
   that rules a placement out has not chosen one; the affordances it measured on the
   way past are worth more than its verdict.**

   One mechanical consequence: the selection lives on a `state_beacon` beacon owned by
   the package, and `state_beacon` is a transitive dependency the package does not
   re-export, so nothing in `lib/` watches a beacon from a widget. It is mirrored into
   `selectedCardIdProvider` by the controller notifier — the same shape as
   `cardFormsProvider` — which keeps the widgets on one reactive mechanism. Beacons
   flush subscriptions on a microtask, which is what makes subscribing from the
   provider's constructor safe; two guards written against a build-time write were
   deleted after no mutation could kill either.

3. **Store the choice, derive the geometry — but store what the derivation cannot
   recover.** `isResizable`, `minW` and `minH` are re-derived by `applyCardForms` on
   every import, so a rule change reaches layouts users already saved and no flag can
   drift from the pick that implies it. The exception is the box popup collapsed: with
   the handles gone there is no gesture that could recover it, so `restoreW`/`restoreH`
   travel *with* the choice, per breakpoint. Compact deliberately records nothing — it
   only ever grows a card, and to a width the card genuinely needs.

4. **A floor on both axes, with the numeric raise on one of them, is the honest
   shape.** Compact's floor is **4 columns / 260.5px**, not the 3 columns every
   compact consumer declares as `minColumns`: 3 columns realizes at 191.4px, below
   `kPopupBelow`, so a compact card shrunk to its declared minimum would sit in the
   band §2.1 says a label and a value no longer share. On the height axis
   `compactMinHeightRows: 2` is the mechanism *without* a raise — all six consumers
   already declare 2 or 3 rows, and §2.4 forbids freezing a constant nobody measured,
   so inventing a taller floor to make the two axes look symmetric would be exactly
   that. It applies the day a card declares less. **A mechanism that does not bite
   today is not the same as a mechanism that is missing, and the difference belongs in
   the code's own words rather than in a ticket comment.**

5. **The loading state is a card state, and it degrades with the card.** Found by the
   forced-form sweep, not reasoned out: `connected_devices` overflowed its picked 2×1
   tile by **94.0px** and `wifi_performance` by 6.0px, in all three locales — and
   neither was the popup form, which passed. It was `CardSkeleton`, a stack of
   fixed-height blocks sized for the footprint the card *used to have*, rendered in
   the frames before the domain data lands. A picked box is not a width the grid
   chose, so on a cold boot the skeleton is drawn into a box 69px narrower than the
   3-column floor and two rows shorter than the three-row box its blocks are sized
   for — `CardSkeleton.list(rows: 3)` alone is 86px of content. Fixed once, in
   `CardSkeleton`
   itself, reading `CardDensityScope` for the same reason `DashboardCardTemplate`
   does — all 15 cards that show a skeleton go through that one widget, so none of
   them can miss the behaviour or spell it differently.

6. **Only 2 of those 15 cards had a loading frame to catch, so the finding was
   luck — and the fix is a pump, not a wider sweep.** The shared fixture resolves
   most cards' data immediately; 13 of the 15 were "covered" by fixture timing rather
   than by an assertion. Widening the card sweep would not have helped, because
   whether a card renders its skeleton at all is a property of the fixture. So the six
   skeleton variants are pumped directly under a hand-built popup scope, one test each
   — the claim is about six widgets and has nothing to do with locale or card data,
   and the two card-level cases are what prove production puts the skeleton under that
   scope at all. Generalized: **`runWithOverflowCollection` spans every frame of the
   pump, which is the only reason a pre-data frame ever surfaces; a suite that only
   asserts on the settled frame is measuring the form, not the card.**

7. **A forced geometry is a new worst case only where it is not dominated, and the
   domination is a test, not a paragraph.** Two boxes exist now that no drag could
   produce: the popup collapse (**122.3px × 1 row**, against the 191.4px 3-column
   floor that was the narrowest width any card had ever been pumped at) and compact's
   4-column floor (**260.5px**, a span the #1183 gate never pumps, since it pumps each
   spec's min / preferred / max — 3, 6 and 8 for all six consumers). The two other
   pairings are skipped: the mobile popup tile is 288px at the same one row, and
   compact above `normalAbove` is wider at the same height, so both are dominated
   because overflow is monotonic in width. That premise is load-bearing for every
   "one case per span" claim in this suite, so
   `dashboard_card_forced_form_overflow_test.dart` **asserts each skip** against the
   live geometry instead of asserting it in prose. Two more facts it pins rather than
   states: the popup inventory is all 18 ids minus `cardsWithoutPopupForm`, and the
   two cards whose thresholds sit *below* 260.5px — `lan_info` (250) and
   `time_settings` (256) — are named, because those are the cards for which the
   4-column sweep is a width the automatic rule would genuinely not select, and a spec
   edit that moves a threshold across that line changes what the sweep means.

   This retires a coverage statement two sections rely on. §2.6c item 1 and §D3 both
   note that nine of the eighteen cards are floored above `kPopupBelow` by their own
   `minColumns`, so no width selects popup for them — true of widths, and now
   incomplete: **a pick is not a width**, so eight of those nine (all but
   `stats_panel`) render a popup form for the first time in this ticket's sweep.
   `known_overflows.json` is unchanged and the #1183 gate is green (1698/1698): none of
   these boxes existed before, so there is nothing to grandfather and a failure here is
   this ticket's regression.

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

**Extended in #1267: width and locale were not the only dimensions, only the
swept ones.** Enumerating widths guarantees the worst *width* per span; it says
nothing about data, and `kitchenSinkOverrides()` hardcoded one router shape, so
all 1644 cases were verdicts about two radios with 2-digit channels. #1267 adds a
**data** dimension — `extraOverrides` on `probeCardOverflow()` /
`buildDashboardCardApp()`, a tri-band fixture, and `kCardDataProfileSweeps`, an
opt-in list of (card, tabs, profile) triples. Sweeping the second profile
everywhere would have doubled the case count and *added* allowlist entries, so the
list is opt-in and the new cases key as `card|width|tab@profile`: the default
profile's 1644 cases and every existing key are byte-identical, and the "N
coordinates cleared" figure every closed ticket in this epic quotes cannot be
moved by a second profile's findings. The sweep is now **1698** — 1644 default
plus 54 (`wifi_performance` tab 2 on the tri-band profile: 26 locales × 2 widths,
plus a marker guard and a tab-exists guard). Full reasoning, and the cost of
opt-in stated plainly, in §2.10g point 1.

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

**Two amendments the epic measured into this claim.** The property is "does not
overflow", and the gate reads it off `RenderFlex` incidents, so it holds only
where the render objects can report:

- *Data is now part of the domain, for the cards that opt in* (#1267, §2.7). It
  was not before, and a green verdict on one router shape reads as broader than it
  is.
- *Nothing inside a scrolling region can report an overflow.* #1267 gave the
  `wifi_performance` Channels tab a scrolling content region, and the tri-band
  fixture that had reported `+9.0px bottom` now reports clean — as it would if the
  content were 300px too tall. Where a tab converts, the gate stops being the
  validation mechanism for its *height* and `cardContentScrollShortfall` takes
  over (§2.10g point 6). This is the same class of blindness as §2.6d's: the gate
  cannot see a card that is legible-but-scrolled any more than one that is
  clean-but-illegible.

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
   one blanket rule. *Superseded by #1245*: the flag is gone, and the rule is
   carried by which constructor the call site names —
   `AppChartLegendEntry.seriesName` shortens, `.statistic` wraps, and neither
   takes the behaviour as a parameter there is a default for (§2.10k point 2).
3. **#1226's shape has an unstated precondition, and one row violates it.** The
   shape pays for its extra run with height, "because the chart above is
   `Expanded`, so it yields the height". Network Health's Health tab has an
   `Expanded` holding a **fixed 120px** gauge, so it yields nothing: a `Wrap`
   there traded that row's 26 right-overflows for **12 new bottom-overflows at
   the gauge centre** (`:128`, 3 → 15) — a fix on paper only, and it would have
   landed as one had the ratchet been edited to the predicted numbers instead of
   the measured ones. That row stays a one-line `Row` of `Flexible` lights and
   gives horizontally; the deviation is commented at the site and pinned by a
   test that fails if someone "restores consistency". #1245 is where that pin
   earned itself: the shared entry was declined for this row alone, because the
   kit's 16px mark box would have cost 6px per light here (§2.10k point 3).

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

> **Re-measured for #1298 — the table above is #1266's record, and both of its
> inputs have since changed.** #1267 moved the client count *inside* the row's
> first `Wrap` child, so child 1 is wider than the bare band `tr`/`th` were
> measured against; and #1298 removed `tr`'s `Channel (Kanal)` gloss (the English
> term with the Turkish in parentheses — see §2.10h), so `tr`'s `channel` is now
> `Kanal` and it is no longer the loudest locale. Restoring `Row` + `Spacer` on
> today's tree measures **25 of 26 locales overflowing the 261px card** (`th`
> +44.0px, `ja` +28.0, `en` +26.0, `fi` +21.0 … `zh` +3.8; only `ko` clean) and
> `th` +17.0 alone at the preferred 288px width. On the `[triband]` profile #1267
> added — the fixture #1266 could reach only by hand-editing — **all 26** break at
> 261px (`th` +55.0, mildest `ko` +12.0) and four still break at 288px (`th`
> +27.0, `ja` +11.0, `en` +8.8, `fi` +3.6). The conclusion is unchanged and
> stronger: the row had a geometry problem in nearly every locale, not two.
> #1266's coordinate arithmetic is untouched, because the `Wrap` shipped in the
> same change and no coordinate was ever booked.

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
scrollable like the Signal tab's `ListView`) is a density decision, and it was not
verifiable at all until the gate could express a second data profile.

**Filed as #1267, and closed — measured, not estimated (§2.10g).** It paired the
density decision with the gate change that makes it measurable: an `extraOverrides`
parameter threaded through `probeCardOverflow()` / `buildDashboardCardApp()`, a
tri-band fixture derived from `testRadios`, and an opt-in sweep list. The gate
reproduced this exact incident red — `wifi_performance|min|2@triband`, `tr`,
`+9.0px bottom`, and only there — and the answer turned out to be *both* of the
options above plus a third: the donut is gone (its slices restated the per-radio
counts, its centre total the header badge), the tab scrolls, and the client count
moved onto the band row as an icon and a numeral. The tri-band profile is clean at
26 locales × both widths with ~120px to spare, and the gate stands at **1698**
(1644 default + 54 tri-band) with an empty allowlist.

It was deliberately *not* folded into #1235 — same family (fixed-size gauge in an
`Expanded` that cannot pay), but different axis (vertical vs horizontal), different
trigger (data vs translation length) and different visibility (invisible until
#1267's Part 1 landed vs 3 live coordinates), and #1235's acceptance criteria are
executable ratchet claims that an unverifiable AC would make unclosable. Recorded
here because the #1266 fix does trade a right-overflow for a bottom-overflow on
that unshipped profile, which is exactly the trade §2.10a point 3 warns about.

Note also what #1267's Part 1 would have cost done the obvious way: adding a
second profile to the sweep across all 18 cards doubles 1644 cases and surfaces
coordinates nobody has looked at — an allowlist *addition*, against the ratchet's
direction. That is why the sweep shape (opt-in per card / second allowlist keyed by
profile / one allowlist) was an explicit decision in that ticket rather than an
implementation detail; it chose the first, and namespaced the second profile's keys
so the default profile's arithmetic could not move (§2.10g point 1).

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
`firewall_overview`) and #1238 (27, `connected_devices`). *Both have since
cleared* — #1230 its 21 (§2.11a) and #1238 its 27 (§2.10e) — leaving **0**:
`known_overflows.json` now carries an empty allowlist.

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

### 2.10f What the Statistics twin of the same abbreviation taught us (#1270 — implemented)

§2.10c localized `'Ch '` on the Wi-Fi Performance tab, where the gate could see it
(3 coordinates in, 3 out). #1270 is the same one-line change on the Statistics
page's WiFi Channels section, and everything the gate did for #1266 had to be done
by hand here, because that page is not in `UspWidgetSpecs.all` (§2.9). Measured on
the shipped section, all 26 locales × 288 / 256 / 224 / 192px sections, wide-6GHz
fixture:

| shape | 288px (production floor) | 256 / 224 / 192px |
|-------|--------------------------|-------------------|
| `Wrap` (shipped, #1264) | 26 clean | 26 clean at each |
| pre-#1264 `Row` + `Spacer` | `tr` +27.0/+13.0, `th` +3.0 | **all 26** overflow (`tr` worst +123.0/+109.0) |

Four findings, all method:

1. **A `Wrap` fix converts an overflow into an *arrangement change*, and geometry
   assertions have to be re-taken when it does.** The prefix spent the 47px of
   headroom #1258 measured, so at the 288px floor the channel string no longer
   fits one run: it drops below the band. Nothing overflows — that is the fix
   working — but "the channel string is flush right", the property the old
   `Row` + `Spacer` had and the geometry guard asserted, is now false at exactly
   the width that matters most. Skipping the assertion there would leave the floor
   unguarded, so each width now *states* which arrangement it expects (one run
   above the floor, stacked at it) and the test asserts that. A change that buys
   the string back onto one run fails the test, which is correct: the expectation
   is a measurement and has to be re-taken.
2. **Two ways to write a geometry probe that is blind by construction**, both
   found in the #1258 group while re-taking its ledger, both now guarded in the
   probe itself:
   - *Measuring a span against the immediate parent.* `CrossAxisAlignment.start`
     shrink-wraps the per-radio `Column` **together with** the `Wrap` inside it, so
     "child width == parent width" holds in both the fixed and the broken tree. The
     reference has to be a box whose size the harness controls (the section box),
     with the intervening insets summed off the tree rather than hardcoded.
   - *Pumping a section wider than the screen.* The box that sizes a section lives
     inside the viewport, so Flutter clamps it: 288 / 537 / 841px sections on a
     320px screen render 238 / 270 / 270px of content — three cases, two layouts,
     and every width in the report wrong. `probeSectionOverflow` now fails loudly
     when asked for this. The general rule for this epic's instruments: **a width
     is only measured if it is realizable on the screen it is pumped on.**
3. **A mutation ledger is a per-revision fact and has to be re-taken, not
   appended to.** This file's suite grew 43 → 158 tests, so every count in its
   ledger was stale; re-running all ten mutations is what surfaced finding 2 (one
   row had quietly dropped from 3 failures to 1). It has since been re-taken twice
   more — 168 tests at #1298 and 172 at #1297, where the same unchanged mutation
   went from 85 failures to 117 because the row it reverts had gained the client
   count (§2.10i finding 3) — so the rule reads: **a ledger row is only current for
   the revision it was taken on**, and the tell is that the numbers stop
   reproducing (§2.10h finding 3). Two corollaries: group
   attribution is not evidence of isolation — one shared probe returns every
   `RenderFlex` incident in the tree, so mutating one row fails whichever group
   pumps a width where it overflows — and a `Flexible` inside a `Wrap` fails all
   158 tests with a framework error, which is loud but proves nothing about the
   guard that was meant to catch it.
4. **Five suites, five copies of `2.0`.** The gate and its four satellites each
   filtered overflow on a bare 2.0px tolerance. A satellite that drifted looser
   would report a coordinate the gate still fails on; tighter, and it fails on CI
   only. It is now one `kOverflowTolerancePx`, and the Statistics-section pump is
   one `probeSectionOverflow` beside the dashboard's `probeCardOverflow` — the
   *mechanism* (collector, parsing, settling) stays separate from a page's
   *geometry*, so a dashboard test cannot inherit Statistics layout facts.

### 2.10g What giving the gate a second data profile taught us (#1267 — implemented)

§2.10c recorded a `+9.0px bottom` on a tri-band router that the gate had no way to
express — found by hand-editing `testRadios` and reverting. #1267 gave the gate the
profile, reproduced the incident red, and then had to decide what the Channels tab
drops at that density. Both halves shipped:

| `wifi_performance` tab 2, tri-band, `tr` @261px card | verdict |
|---|---|
| the gate before #1267 (one hardcoded profile) | unmeasurable — 1644 cases, all green |
| the tri-band sweep, donut still in place (**red first**) | `+9.0px bottom` at `:575`, `tr` only — 51 of 52 cases green |
| shipped: donut removed, tab scrolls, client count compressed | clean, 26 locales × both widths, **0.0px** scroll shortfall |

Gate **1644 → 1698** (54 = 26 locales × 2 widths + 2 meta guards), and
`known_overflows.json` stayed empty in both directions. Eight findings.

1. **Namespacing the keys is what made a second dimension affordable.** The ticket
   offered three sweep shapes; option 1 (opt-in per card,
   `kCardDataProfileSweeps`) was chosen for what the other two do to the ratchet.
   Sweeping a second profile across all 18 cards doubles 1644 cases and surfaces
   coordinates in cards nobody has examined — an allowlist *addition*, against
   §2.9's contract, reading as a mass regression the moment the mechanism lands.
   The mechanical half of the fix is one line: a non-default profile's cases key as
   `card|width|tab@profile`, so **every pre-#1267 key is byte-identical** and the
   default profile's arithmetic — the number every closed ticket in this epic
   quotes — cannot be moved by a second profile's findings. Option 2 (all cards,
   per-profile allowlist) is the honest full-coverage answer and is what this
   should grow into; the growth belongs to the ticket that measures each card, not
   to the one that builds the mechanism. The cost of option 1 is stated in
   `card_data_profiles.dart` rather than left implicit: **a card is covered on the
   second profile only once someone adds it**, and one entry is not a claim about
   the other 17 cards.

   The same argument bounds what gets swept *within* the opted-in card. The
   tri-band profile varies the radio list, so it cannot change the Signal or Speed
   tabs, which render clients — sweeping them would buy 104 byte-identical cases
   (two tabs × 26 locales × two widths) and read as coverage.

2. **A data profile's failure mode is silence, so the profile has to prove it
   reached the tree.** There are two `testWifiData` fixtures in this repo (the
   dashboard's and `statistics_test_data.dart`'s), and #1266 already lost a full
   measurement round to editing the wrong one. Override the wrong provider and
   every case in the sweep pumps the default fixture, reports green, and reads as
   52 extra cases of coverage that were never measured. So each profile carries
   `markers` — locale-independent substrings only it can produce (`233 (Auto)`,
   `320MHz`) — asserted by one `en` pump at the desktop width before the sweep
   runs. The general rule for this epic's instruments, alongside §2.10f finding 2:
   **a harness parameter whose absence is green needs a positive assertion that it
   arrived.**

3. **The density decision was subtraction, and what justified it was that both
   halves of the donut were duplicates.** The ticket's preferred option was a
   height threshold that drops the donut below the height its centre label needs;
   what shipped drops it unconditionally, because measuring what it *says* is
   cheaper than measuring how tall it needs to be:

   - its slices are per-band client counts, which the tab already prints once per
     radio block;
   - its centre total is the client total, which the card's header badge already
     carries.

   Re-slicing it by channel was considered and rejected on the same ground — a
   radio has exactly one channel, so channel-keyed slices are band-keyed slices
   with a different legend. What *would* earn the space is the one thing this tab
   cannot currently say: airtime utilization, or how many neighbouring networks
   share the channel. TR-181 has `Device.WiFi.DataElements.Network.Device.{i}.`
   `Radio.{i}.Utilization`, no provider fetches it and `WifiRadioUIModel` has no
   field for it, so that is a follow-up ticket and not a layout fix — filed as
   #1295 and then **deferred** (no new feature work for now), which makes the
   blank space the intended interim state rather than an unfinished one: the case
   for removing the chart never depended on something replacing it. The tab's
   linear `AppLoader` went with the donut, for the narrower version of the same
   reason: an unlabelled bar drawn at `snr / 50` restates the number printed
   beside it, and removing it removed an `Expanded`/`Spacer` pair and the
   zero-bar branch #1271 had to guard.

   This satisfies the AC forbidding a box-adaptive donut by being strictly
   stronger than it: shrinking the chart to its slot silences the gate while
   leaving a useless chart on screen, whereas deleting it withdraws the claim.
   The Statistics twin had both the bar and its own band-distribution donut, and
   the same two questions were asked of that surface separately, in #1297 — same
   two answers, weaker overflow evidence and a heavier vertical bill (§2.10i).

4. **An overflow number is a lower bound on the visual damage.** The gate reported
   `+9.0px bottom` and the screenshot was far worse: the donut, fixed at 120px
   inside an `Expanded` with ~40px to give, was `Center`ed — and `Center` spills an
   oversized child in **both** directions, so it painted over the 6GHz radio block
   above it and only the 9px that fell past the card's bottom edge was ever
   reported. §2.10a point 3's shape (fixed-size gauge inside an `Expanded` that
   cannot pay) hides most of itself when the gauge is centred. Read the render, not
   just the incident list — which is why this branch dumps PNGs (`saveCardScreenshot`).

5. **A tab can scroll or it can hold a vertical `Expanded`; there is no third
   option, and that is why the flag is per tab.** Tabbed cards shipped with
   `scrollable: false` because their charts and lists sit in `Expanded`, which
   asserts under the unbounded height a `SingleChildScrollView` hands its child —
   so content taller than the grid-fixed card had nowhere to go but outside the
   box. `CardScrollRegion` (private to the card template until #1297 needed the
   same net on a Statistics section, then extracted unchanged to
   `lib/page/_shared/components/`) gives that content the viewport height as a
   **floor** (`ConstrainedBox(minHeight: constraints.maxHeight)`, no ceiling), so a
   shrink-wrapping `Column` still fills the card exactly as before while being free
   to grow. What that cannot do is keep flex working, and the apparent third option
   was measured rather than assumed: `SliverFillRemaining(hasScrollBody: false)`
   promises a tight `max(viewport, intrinsic)` height, queries
   `getMaxIntrinsicHeight`, and throws through the `LayoutBuilder`s that
   `LayoutBlock`, the charts and `CardDensityHost` are built from — **784 gate
   cases failed** on that assertion before it was reverted. So a tab opts in only
   after its content has been given real heights, which is a per-tab property:
   within this one card the Channels tab converts while Signal and Speed still hand
   a `ListView` and a bar chart the whole box. A card-level flag would have forced
   all three together, or none.

   That per-tab decision was taken for the remaining 19 tabs in #1296, and the
   membership table lives in **§2.10j** — three more tabs in, four declines with the
   measurement each rests on. Read the table there rather than assuming this
   paragraph's "everything else is opted out" still holds.

   The affordance is `Scrollbar(thumbVisibility: true)`, and it is free on cards
   that fit: `thumbVisibility` pins the fade-out animation open, but
   `ScrollbarPainter.paint` still returns early unless
   `maxScrollExtent - minScrollExtent > precisionErrorTolerance`, so nothing is
   painted while the content fits. Article XIV was searched first: `ui_kit_library`
   exports no scroll-affordance component (`AppTooltip` is the nearest neighbour,
   and ui_kit uses the raw `Scrollbar` internally too), so a gradient fade edge is a
   component to propose upstream, not to invent here.

6. **Converting an overflow into a scroll makes the gate go quiet, so the
   conversion owes a measurement the gate cannot make.** A scrolling region has
   unbounded height by construction: nothing inside it can report a `RenderFlex`
   overflow, ever. The same tri-band fixture that reported `+9.0px` now reports
   clean at all 26 locales, and it would report clean if the content were 300px
   too tall. Measured from the other side, `CardTab.scrollable: false` on this tab
   leaves **all 211** of the card's gate cases green — the ratchet is blind to the
   mechanism it depends on. This is §2.6d's "the gate cannot see illegibility" in a
   new place, and it is answered the same way, with an instrument that measures the
   thing directly: `cardContentScrollShortfall` returns how far the content exceeds
   the viewport, asserted in the readability suite. Default and tri-band profiles
   report **0.0px** at every width and locale (tri-band fits with ~120px to spare
   once the donut is gone), so a six-radio profile — 177–275px short across the
   four width × locale combinations — supplies the load the net is verified under.
   It is deliberately **not** in `kCardDataProfileSweeps`: coordinates recorded
   against hardware nobody sells become allowlist entries no ticket can clear.

7. **Compressing the client count moved the wrap, so the geometry expectations had
   to be re-taken — the same lesson as §2.10f finding 1, one ticket later.** The
   count is now an icon plus a numeral beside the band (`AppIcon.font`
   `AppFontIcons.devices` at 14px, `AppGap.xxs`, `bodySmall`) instead of a
   `clientsCount` sentence on the row below, which is what lets the SNR line be a
   plain `AppText` with no sibling — no `Expanded`, no `Spacer`, and none of
   #1258's spaceBetween cliff. Two measured consequences: the sentence was costing
   ~50px of a 235px content width to name the tab's own subject, and the ~29px the
   icon pair adds to the band row pushes the 5GHz block from one run to two at
   288px `en` (at 261px both bands already took two). Nothing overflows — that is
   the `Wrap` working — but the run structure a #1266 assertion depended on is now
   different, and the test states the new one rather than being relaxed.
   Accessibility is not the thing compressed: the row is wrapped in
   `Semantics(label: clientsCount(n), excludeSemantics: true)`, so a screen reader
   still hears "3 clients", and the parity test pins both halves — the visible
   numeral **and** the label — because an icon with a naked number and no
   accessible name is exactly the regression that would otherwise pass. That
   assertion was `countIsCompact`-gated for as long as only this surface was
   compressed; #1297 compressed the twin and the gate went away (§2.10i finding 4).

8. **Two ways a mutation ledger lies, both hit on this branch.**
   - *The oracle stops discriminating without failing.* #1266's `stretch` invariant
     compared the band row's `Wrap` width against its enclosing `Column`. Removing
     the SNR bar removed the second row's `Expanded`, and under
     `CrossAxisAlignment.start` both boxes then shrink-wrap to the same width —
     measured 204.888px either way, so the assertion passed on the broken tree as
     well. It now compares the block's **two rows** to each other (Wrap width
     against the SNR text's width), mutation-verified at 65.207 vs 204.888. §2.10f
     finding 2 named two ways to write a probe that is blind by construction; this
     is a third, and the one that does not require writing the probe badly — an
     unrelated change to the subtree took the independence away. **Re-run the
     ledger after changing the tree, not only after changing the test.**
   - *The mutation does not land.* A scripted replace of `scrollable: true` matched
     nothing (the real indent differed), the suite was re-run, and 15 green was
     recorded as evidence that the flag was not load-bearing — which is the
     opposite of the truth. A ledger row is only a measurement if the mutation is
     shown to have applied; the confirming `grep` is now part of taking one. The
     screenshot equivalent bit at the same time: `saveCardScreenshot` returns early
     when the file exists, so the "after" images were the "before" ones until
     `build/shots_1267` was removed.

### 2.10h The widest string in the sweep was not a translation (#1298 — implemented)

§2.10c's table has `tr`'s `channel` as `Channel (Kanal)` (15 chars) and treats it
as the worst case a locale sweep can throw at the row. It is not a translation. It
is a glossary entry — the English term with the Turkish beside it in parentheses —
and it is why `tr` measured as the widest `channel` value in the product at
**212.5px** where the actual Turkish word renders at **155.1px**. Three `tr` keys
had the shape; sweeping the other 25 locales for it found six more:

| locale | key | shipped | fixed |
|---|---|---|---|
| `tr` | `channel` | `Channel (Kanal)` | `Kanal` |
| `tr` | `connectionType` | `Connection Type (Bağlantı Tipi)` | `Bağlantı Tipi` |
| `tr` | `defaultGateway` | `Default Gateway (Varsayılan Ağ Geçidi)` | `Varsayılan Ağ Geçidi` |
| `ar` | `macAddress` | `MAC Address (عنوان MAC)` | `عنوان MAC` |
| `pt` | `macAddress` | `MAC Address (Endereço MAC)` | `Endereço MAC` |
| `da` | `broadcastSSID` | `Broadcast SSID (Udsend SSID)` | `Udsend SSID` |
| `pl` | `automatic` | `Automatic (Automatyczny)` | `Automatyczny` |
| `vi` | `automatic` | `Automatic (Tự động)` | `Tự động` |
| `pt_PT` | `wired` | `Wired (Com fios)` | `Com fios` |

Nine keys across seven files; gate **1698/1698**, `known_overflows.json` empty in
both directions. Five findings.

1. **The shape is mechanically findable, and two hits are not defects.** The regex
   is `^<the en value>\s*\(.+\)$` per key against `app_en.arb`, which is what makes
   it separable from ordinary parentheses in a translation. It leaves two hits
   standing, and the distinction is the parenthetical's *job*: `ar`
   `connectionTypePppoe` is `PPPoE (بروتوكول نقطة إلى نقطة عبر Ethernet)` and `it`
   `dmz` is `DMZ (Demilitarized Zone)`. There the English side is an acronym, so
   the parenthetical is not a gloss of a term the reader already has — it is the
   only translated content in the string, and removing it leaves an untranslated
   acronym. **A gloss is redundant with the English term beside it; an expansion is
   not.**
2. **Nothing can regress; documentation can.** All nine replacements are strictly
   shorter than what shipped, so no layout can newly overflow — which is exactly
   why the change is dangerous to land quietly. What it invalidates is every
   *measurement* that quoted a glossed string: §2.10c's table above, the twin
   card's `Row` + `Spacer` comment, and in
   `stats_wifi_channels_section_test.dart` the per-locale width ranking, the AC-1
   ladder and three rows of the mutation ledger. All were re-taken by re-running
   rather than edited to fit, and re-running caught a pre-existing over-claim:
   the ladder's `Row` + `Spacer` row had reported "all 26 at 256px" where the
   measurement is **16 of 26** before this change and **15 of 26** after it.
   A documented number that nobody re-derives decays into a documented guess.
3. **Two of the ledger's stale rows had nothing to do with this change.** Rows 2,
   3 and 4 (`Row` + `Expanded` on the signal bar, `Row(min)` for the stats pair,
   `Expanded` on the bar alone) reproduce 5 / 5 / 34 failures against 9 / 7 / 158
   recorded. Re-running them under the *old* sample list with the `tr` gloss
   restored still gives 5 and 5, so #1298 is not the cause: **#1271** made the bar
   conditional on `averageSnr != null`, and groups 1 and 3 pump the client-less
   fixture, so those mutations can no longer reach them. The ledger is a
   measurement of the tree, not a property of the test — §2.10g finding 8's "re-run
   the ledger after changing the tree" applies to *other people's* tickets too, and
   the way you find out is that the numbers stop reproducing.
4. **A locale sweep cannot see a string that never varies — the same blindness
   §2.10c named for abbreviations, one layer up.** 205 keys are byte-identical to
   English in at least one locale. Most are acronyms that legitimately do not
   translate (`MTU`, `TCP`, `UDP`, `DHCP`, `SSID`), so that is not a defect count.
   Two that are not: `channelAutoRecommended` (`Auto (recommended)`) is an English
   sentence in **25 of 26** locales, and `da` `automatic` is the English word
   `Automatic`. Both render inside this epic's cards, and the gate reports them
   green in every locale because there is nothing for a locale sweep to vary.
5. **`(Auto)` is still hardcoded English in `lib/`, and localizing it has a
   measured gate cost.** `wifi_radio_ui_model.dart:62` and
   `wifi_network_ui_model.dart:110` append `' (Auto)'` unlocalized — the same
   defect class as #1266's `'Ch '`, in the same channel string. Substituting the
   existing `automatic` key measures the worst-case row at `ru` **222.1px** against
   `en`'s 159.1 (+63.0), then `fi` 220.1, `pl` 208.4, `nl` 205.7, while
   `ja`/`zh`/`zh_TW`/`ko` get *narrower*. That is 34px past the widest string
   either surface has ever been measured with, so it is a ticket with a coordinate
   cost and hardening attached, not a one-line substitution — the coupling §2.10c
   established (localizing alone runs the ratchet backwards). Recorded here rather
   than done here.

### 2.10i What the same two questions cost on the Statistics twin (#1297 — implemented)

§2.10g finding 3 removed the Wi-Fi Performance card's donut and signal bar and left
the Statistics twin holding both, on the grounds that "the same two questions on
that surface are separate work". #1297 is that work. It asked them of
`stats_wifi_channels_section.dart` and got the same two answers with different
evidence, plus a third decision the dashboard's version of the ticket did not have
to make:

| Statistics WiFi Channels, 288px section = 238px content | verdict |
|---|---|
| the 96px linear `AppLoader` beside each SNR | **removed** — 1.92px/dB, no tick, no unit, saturating: 50/55/60/70 dB paint the same full bar |
| the band-distribution donut | **removed** — 40–60px slice titles on a **15px** ring at every width; painted over the rows from 4 radios up with the probe silent |
| the client count | **compressed** to icon + numeral beside the band, as on the dashboard — 23.2px against a 36.3–90.5px sentence |
| the fixed 320px chart box | **`scrollable: true`** — 5 radios need 360px there, 6 need 432px |

Gate **1698/1698**, unchanged, and that is the point: this section has no gate
coordinate, so every figure here was measured by hand (§2.10f is the precedent for
what that costs). Six findings.

1. **The removal arguments do not transfer between twins — one is stronger here and
   one is much weaker.** Stronger: on the dashboard the donut was a second
   rendering of the tab's own rows; here it was the **third**, because
   `StatsDeviceDistributionSection` — the first card of this same Devices tab —
   already draws the band distribution as labelled horizontal bars with band names
   and counts. Weaker: the *evidence*. §2.10g finding 4 said an overflow number is a
   lower bound on the visual damage; here the bound was **zero**. The donut sat in
   an `Expanded` inside a fixed 320px box and `AppPieChart` derives its geometry
   from the `size` it is handed rather than from its slot — measured slot heights in
   `en` are 188px at 2 radios, 136px at 3, **84px at 4**, 32px at 5, 0px at 6 — so
   from 4 radios up the 120px drawing was larger than its slot and painted across
   the last radio's SNR while `probeSectionOverflow` reported nothing at all, at any
   width. **A surface with no ratchet coordinate is not a surface with no defect**,
   and the twin that has a gate is the one that got the cheaper argument.

2. **Legibility, not space, is what disqualified the chart — which is why scrolling
   was the answer to a different question.** "If we really want a chart, can we give
   it scroll?" was measured rather than argued. `AppPieChart` prints each slice
   title *on* the slice, and at `size: 120` the themed `pieCenterRadius` (60) is
   capped to a 45px hole, leaving a 15px ring under titles 40px (`5GHz`, `6GHz`) to
   60px (`2.4GHz`) wide — up to 18.5px outside the 120px box on a skewed split.
   Scroll buys height; it cannot widen a ring, and there is no width at which a 60px
   word fits a 15px one, at 841px as much as at 288px. So the donut is not a
   space problem and "the same chart, bigger" is not a smaller version of the fix.
   Where scroll *was* right is the per-radio row list, whose height is set by data
   and locale rather than by the box — the opposite defect, given the opposite fix,
   in the same change.

3. **The count's compression is where the two surfaces converged, and the honest
   reading reversed mid-ticket.** #1297 first kept the sentence on a headroom
   argument: count + SNR measured 112.0–166.2px of a 238px content box, so it fitted.
   Fitting is not the same as being worth the width — the word names what the whole
   Devices tab is about and it repeats on every radio — so the count is now an icon
   plus a numeral (23.2px: 14px glyph + `xxs` + numeral) against a sentence costing
   36.3px (`id`) to 90.5px (`fi`). What the dashboard's version of this decision hid
   is the second-order cost, and it is bigger here: moving the count *up* beside the
   band adds 27.2px to the band row, which takes that row from one run to two in
   **all 26** locales at the 288px floor (it was 3 of 26 — `th` 257.3, `ja` 240.8,
   `en` 239.0 against 238px), so a per-radio block costs 72px instead of 52px. The
   dashboard paid ~29px on one band at one width (§2.10g finding 7); this is every
   locale on every radio. **The saving is horizontal, the cost is vertical, and only
   the second one needed a new mechanism** — the scroll region, not a narrower row.

4. **Both flags in the shared oracle are now retired, and each retirement is
   strictly stronger than the flag was.** `wifi_snr_render_parity_test.dart` carried
   `hasSignalBar` and `countIsCompact` so that one oracle could describe two
   surfaces that had *diverged*. #1267 took the dashboard's bar, #1297 took this
   one, so `hasSignalBar` went; #1297 compressed this count, so `countIsCompact`
   went. Neither assertion was dropped — both became unconditional, so both surfaces
   are now located by the same two things (the visible numeral **and**
   `Semantics(label: clientsCount(n))`) and a re-added bar fails the parity suite on
   either. **A flag in a parity test is a record of divergence; the fix for one is
   for the surfaces to agree, not for the flag to be deleted.** Measured payoff: of
   13 mutations, the parity column now fails on exactly the four that touch
   something both surfaces claim — the count as a numeral (either surface), its
   accessible name, the bar's absence, the donut's absence — and stays green on the
   nine that are this section's own geometry.

5. **A guard that a lone text cannot overflow does not get deleted; it becomes a
   guard about the shape.** With the count moved up, the SNR is the only child on
   its line, and the widest reading of 26 locales (`zh`/`zh_TW` `snrValue`, 69.8px;
   `snrUnavailable` 41.4px everywhere) clears the 238px content box with 168px to
   spare — where the pair that used to sit there overflowed a **216.2px** section in
   `fi` even under `Row(min)`. So the group's width ladder stops being evidence
   about width and becomes evidence about the shape, and it is joined by a
   structural assertion: the first `Flex`/`Wrap` ancestor of each SNR text must be
   the per-radio `Column`. That assertion is not redundant — re-adding the 96px bar
   fails it, and fails **nothing** on width or height, because in `en` the pair is
   111.3px so the bar's 104px still fits the row, and its real cost was
   locale-dependent (7 of 26 at the floor) in groups that pump `en`.

6. **Deleting a chart from a box that now scrolls changed the *class* of the
   failure, which is what a revert-mutation is for.** Re-adding the donut used to
   cost 4 test failures and hide the actual defect; on the shipped tree the same
   code fails **48 of 172** with `RenderFlex children have non-zero flex but
   incoming height constraints are unbounded` — its `Expanded` is now inside a
   `SingleChildScrollView`, and §2.10g finding 5's rule ("a tab can scroll or it can
   hold a vertical `Expanded`") is doing enforcement work rather than describing a
   tradeoff. The chart cannot come back *at all* while the box scrolls. The net
   itself is measured from the other side too, which is §2.10g finding 6's blindness
   answered with a number instead of a mechanism: `scrollable: true → false` fails
   11 tests — four because nothing scrolls at all (`Expected: not null`, the
   assertion refusing a card that cannot scroll) and seven on the exact overflow the
   scroll absorbs (`+256.0px bottom` at 8 radios).

### 2.10j Three tabs joined the scroll net and four declined, all on the same measurement (#1296 — implemented)

§2.10g point 5 built `CardTab.scrollable` and converted exactly one tab
(`wifi_performance` Channels), leaving the sentence "everything else is still
opted out" true but undecided. #1296 decided the other 19 tabs. The table below
replaces that sentence and is **executable**: `netTabs` in
`test/page/dashboard/views/components/card_scroll_net_test.dart` is the same
table, and a meta-test fails if a tabbed card is missing from it.

| card | tab | verdict | the measurement that decided it |
|---|---|---|---|
| `wifi_performance` | t2 Channels | **in** | #1267 (§2.10g point 5) |
| `device_analytics` | t0 Overview | **in** | donut 180px at 4 rows and at 8, while its slot grew 245 → 789px |
| `traffic_analysis` | t2 Distribution | **in** | donut 180px, ~67px of slack at the shipped height |
| `system_status` | t0 Monitor | **in** | gauges width-bound: 72.7px at the narrowest card, 100.0px at desktop |
| `network_health` | t0 Health | **out** | gauge is 87–103px inside its flex and 120px without it |
| `firewall_overview` | t0, t1 | **out** | 15–39px of leftover slot — nothing to give |
| the other 13 (charts, `ListView`s) | — | **out** | the chart's height *is* the card's: 285 → 829px between 4 and 8 rows |

1. **The conversion is only free when the flex was centring air, and that is a
   property of the widget, not of the layout.** `AppPieChart` derives its geometry
   from `size:` and ignores the box it is given, so both donuts measured **180px at
   4 rows and at 8** while their slots grew by ~545px — the `Flexible` above them
   was distributing leftover height, never sizing the chart, and deleting it
   changes no pixel. `AppGauge` does the opposite: it **respects incoming
   constraints**. `network_health`'s single gauge renders 87px in `de` at the
   narrowest normal-form width and 99–103px at the desktop realization, all below
   its declared `size: 120` — the flex is load-bearing, so the same instrument that
   licensed two conversions refused a third. Two widgets, one slot shape, opposite
   answers; there is no shortcut past measuring the widget.

2. **A decline can cost more than a squeeze.** Dropping `network_health`'s
   `Expanded` does not overflow — the content that no longer fits simply scrolls,
   and **all 157** of that card's gate coordinates stay green. What it does is let
   the gauge grow to its natural 120px and push 17px (desktop) to 33px (narrowest
   normal form) of the metric row below the fold **on arrival**, at the height the
   card actually ships. A card that scrolls before the user has touched it has
   converted a hidden overflow into a visible one; the only fix is a taller card
   (`minHeightRows`), which #1296 excludes. Measured, and left alone.

3. **`system_status` converted without any flex to delete, which is the cleanest
   possible form of the claim.** Its Monitor tab sizes gauges from a bare
   `LayoutBuilder` — `min(72, (maxWidth - AppSpacing.md) / 2, maxHeight)` — so the
   height term survives the conversion untouched: a non-flex child of a `Column`
   receives an unbounded height whether or not the region scrolls, and the
   diameters are identical either way (72.7 / 100.0). This is why its mutation row
   is **45 fail, not 47**: the two geometry tests are *supposed* to pass under
   `scrollable: false`. A mutation that moved those numbers would mean the
   conversion had a cost after all.

4. **The gate is blind to all four flips, in both directions.** Per card, its own
   gate coordinates (209 / 209 / 209 / 157) stayed green under every mutation:
   removing a shipped conversion, and adding the declined one. The suite that is
   not blind fails 47 / 47 / 45 / 41. The decisive assertions are not the shortfall
   being non-null (which only proves a region exists) but the pair around it — the
   content arriving with **shortfall == 0.0** at every pumped width and locale, and
   the same tab carrying real load (**shortfall > 0**, every text still reachable)
   one row below the card's shipped height. §2.10g point 6 said a conversion owes a
   measurement the gate cannot make; this is the shape of it.

5. **A net-membership sweep has to run above `normalAbove`, or it measures the
   wrong card.** 26 of the network_health mutation's 41 failures were an artifact:
   at its narrowest realization (191px) that card is below its `normalAbove: 366`
   threshold and renders the degraded score form with **no tabs at all**, so
   "no scroll region" is correct there rather than a regression. The registry sweep
   therefore pumps `desktopCaseFor(spec)`, and any future conversion on a card with
   a degraded form owes its arrival assertions above that threshold. This is the
   §2.10f finding 2 family again — a probe that is blind by construction — reached
   from a new direction: the probe was fine, the *coordinate* was outside the
   subject.

6. **`cardContentScrollShortfall` could not tell "does not scroll" from "has no
   card".** It returned `null` for both, because `null` meant "found no
   `SingleChildScrollView`", and the horizontal tab strip is a scroll view — so on
   a tabbed card the function silently reported the *tab strip's* extent instead of
   the content's. It now tracks whether a **vertical** region was seen and returns
   `null` only in that case, which is what makes `isNotNull` a real assertion about
   net membership. The instrument built in §2.10g to answer the gate's blindness had
   its own blind spot for one ticket.

### 2.10k What the Article XIV route cost, and what it returned (#1245 — implemented)

§1.1 recorded the legend dot as duplicated verbatim in five files and raised the
extraction rather than blocking #1233 on it. That raise is #1245, and it took the
Article XIV route in full: **propose upstream, then consume the release**. The
proposal is linksys/privacyGUI-UI-kit#26; it shipped `AppChartLegendEntry` (plus
an `AppChartLegend` container) in **v2.37.0**, this repo's pin moved **v2.35.1 →
v2.38.0**, and the seven private classes — four `_LegendDot`, two `_LegendEntry`,
one `_StatLegendEntry` — plus one inline entry row were deleted across **five
files / 13 legend rows** (−128 lines net).

Two baselines, deliberately separated, because the bump carried unrelated a11y
work (`app_ipv4_text_field`, `app_text_field`, `app_breath_dot`) and a charts
refactor:

| state | gate | allowlist | notes |
|---|---|---|---|
| v2.35.1, before the bump | 1698/1698 | empty | §2.10j's closing figure |
| **v2.38.0, no migration** | **1698/1698** | empty | isolates the bump from the migration |
| v2.38.0, migrated | 1698/1698 | empty | plus 14/14 readability *unmodified*, 161/161 scroll net, 39/39 new |

1. **The unit worth sharing was the entry, not the legend.** The kit ships both,
   and the container is the wrong altitude for all 13 rows. `AppChartLegend`
   derives its rows from the same series list the chart got and emits
   `AppChartLegendEntry.seriesName` for every one of them — ellipsis always —
   which would re-break §2.10a point 2 on the **five rows whose labels compose a
   statistic**. It also owns its own `Wrap` (`WrapAlignment.start`,
   `runSpacing: AppSpacing.sm`), which would discard three shapes this epic
   measured: centring (§2.10c finding 3), `traffic_analysis` t0's `spaceBetween`
   split between legend and byte totals (§2.10 rule 3), and `system_status`
   Monitor's legend sharing one `Wrap` with the refresh chip (§2.10d). What #1245
   was asked to de-duplicate was the dot + gap + `Flexible` triple, and that is
   exactly the entry. A shared component being *available* at a higher altitude
   is not a reason to adopt it there.

2. **The distinction that lived in seven comments now lives in a constructor
   name, which is a stronger guarantee than either a comment or a bool.**
   `_StatLegendEntry` expressed it as `ellipsize = false`, so the safe reading was
   the default and a call site could pick wrong by forgetting the flag —
   `Correlation`'s two entries were the only ones that had to remember. The kit
   takes no such parameter: `.seriesName` shortens, `.statistic` wraps, and the
   choice is made by which entrance you reach for. What the kit still cannot check
   is whether a call site reached for the entrance matching the label it passes,
   so that half is now
   `test/page/dashboard/views/components/legend_entry_label_kind_test.dart` (39
   cases, 13 rows × 3 locales): a rendered label containing a digit must be
   `wrap`, one containing none must be `shorten`. Derived from the string rather
   than from a list of call sites, so it also covers a legend added to a sixth
   card, and it fails the day a bare name grows a value.

3. **The shared mark is wider than every dot it replaced, and that is the real
   price of the extraction.** An 8px disc becomes a **16×10 mark box** (the disc
   itself is 10px, centred in it), so every entry gained **+8px** of width — and
   the marks stopped being generic: a block for a bar series, a disc for a pie
   section, a dashed line with a centre dot for a dashed one. All 13 rows absorbed
   it with the gate unmoved, and the reason is §2.10a point 3's precondition:
   every one of them sits under an `Expanded` chart or inside a scroll region, so
   an extra `Wrap` run is paid for out of height that was already there. **The one
   row without that slack declined.** `_TrafficLight` keeps its hand-rolled 10px
   dot, because the kit's box would cost **+6px per light** on the WAN/LAN row —
   the row whose fixed 120px gauge yields nothing (§2.10a point 3), where a `Wrap`
   once traded 26 right-overflows for 15 bottom ones, and which `#1245`'s own "not
   in scope" forbids moving. The decline is now recorded in the widget's doc
   comment rather than only in this file.

4. **Three call sites needed a `Flexible` they never needed before, from the
   RenderFlex rule this epic keeps re-deriving.** A `Row` hands non-flex children
   **unbounded** width; `AppChartLegendEntry` contains a `Flexible`; a flex child
   under an unbounded main axis throws. Ten of the 13 rows needed nothing, because
   `RenderWrap` passes `maxWidth: constraints.maxWidth` to its children and a
   `Wrap` child is therefore already bounded. The three plain centred `Row`s
   (`traffic_analysis` t1 / t2 / t3) each got `Flexible(child: entry)` — the
   minimal bound, **not** a conversion to `Wrap`: none of those rows was ever an
   overflow coordinate, and #1245 is a de-duplication, so the fix supplies the
   constraint the component documents and changes nothing else.

5. **"Renders identically at every width" was not literally achievable, and the
   honest form of AC 2 is its executable half.** Any migration to a shared key
   changes pixels by design — reproducing the ink the chart painted is the whole
   purpose of a mark, and 13 rows previously drew the same disc for a bar, a pie
   slice and a dashed line. What held exactly is the half that can be asserted:
   the gate count and the allowlist are byte-identical (1698/1698, `{}`), and
   `dashboard_legend_readability_test.dart` — the file written for #1233 precisely
   because the gate cannot see a row that survives by truncating itself to nothing
   — passes **unmodified**, including its WAN/LAN one-line assertions. An AC that
   cannot be true literally is worth restating before implementation rather than
   quietly satisfying in spirit.

**What #1245 did not close.** Its ACs scope it to the legend dot and entry, so the
*other* two entries in the de-duplication inventory are untouched: the four
hand-rolled "View details" footers and their cause, `detailRoute`'s inability to
carry query parameters (§2.10d finding 7). Those are a template-signature problem
in this repo, not a missing UI Kit component, so they do not travel the Article
XIV route this section describes.

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

Measured since, and both guessed levers were wrong: the declared height stayed at
3 rows and the caption goes only because the whole donut does. The cause is a
width one. See **§2.11a**.

### 2.11a What the two height sites taught us (#1230 — implemented)

All **21** cleared, not the 15 §2.11 scoped: fl_chart's 6 went with them, from the
call site, with the package untouched. `minHeightRows` stays 3. Six things only
showed up in the measurement.

1. **Both bottom overflows had a *width* cause, and neither of §2.11's guessed
   levers was one of them.** The card's height was never short. What overflowed is
   the three-across metric grid: at the narrowest realization the tab body is
   **157.4px wide and 205px tall** (203px where the tab bar wraps), and three
   `InfoGrid` tiles leave each label `(157.4 − 16) / 3 − 24` = **23.1px** of text —
   one character per line, `ru` wanting **8 lines** (129px) for one label. Those
   three tiles measured **108px** in `en` and up to **173px** in `ru`, inside a
   205px viewport that already owed 20px to gaps and 36px to the legend, so 15 of
   the 26 locales overflowed and the outer `Column` (`:136`) reported up to +26px.
   Stacking the metrics into full-width rows — a *width* decision — is what closes
   a *height* overflow: each label gets 111.4-127.6px and the whole stack
   112-130px, which the donut's `Expanded` absorbs. §1.8's "a
   bottom overflow is often a width symptom" holds here in its strongest form, and
   the ticket's AC 4 (do not raise the declared height) was never a constraint to
   work around — it was the diagnosis.
2. **Nested sites are mutually exclusive, which is why the two counts summed to 15
   over 15 locales rather than 26.** `RenderFlex` reports where it is asked to
   paint: where the grid grew tall enough to starve the donut's `Expanded` to 0,
   the inner `centerWidget` (`:157`) had no box to overflow and only `:136`
   reported (7 locales, grids of 156-173px); where the grid left the `Expanded`
   20-25px, `:157` overflowed by exactly `40 − slot` — +15px to +21px, the caption
   needing 40px — and the outer `Column` fit (8 locales). One site per locale,
   never both. So
   §2.11's "they must be measured together" was not caution, it was necessary:
   fixing either alone moves the report to the other instead of clearing it.
3. **fl_chart's 6 were not dependency-blocked; they were unmeasured.** §1.1
   counted them as third-party and §2.11 reserved a fallback allowlist entry with
   a tracking note for them. Measured, fl_chart's bottom `SideTitles` asks a
   constant `reservedSize: 22` whatever the chart's height is, and `AppBarChart`'s
   vertical path does not override it, so the strip's own `Flex` overflows by
   `22 − slot`: +5px at 17px slots, +10px in `ru`'s 12px. Two call-site levers
   close that, and the cheaper-looking one is the worse one. `AppBarChart.xLabels`
   is nullable and its vertical path passes `showTitles: xLabels != null`, so
   `xLabels: null` deletes the 22px strip outright — measured, that alone takes all
   105 of this card's gate cases green with no height guard at all. It is not what
   shipped: the value axis keeps drawing, so in `ru`'s 12px slot its "2" and "0"
   overlap above two 8px pills, and the only threshold that would admit the
   labelless chart where it reads (`en`, 37px) and reject it where it does not
   (`da`, 17px) sits between 37 and 40px — a knife edge between two shipped
   locales. So the card declines to draw a chart with no room to be one: below
   **70px** (22px axis + 24px always-on value labels + 24px
   `AppBarChart.minBarArea`, leaving every locale 33px clear) it is not built,
   which is §2.11's Primary path applied one level up. Either way the fallback note
   was never needed and `known_overflows.json` now holds nothing for this card.
   Generalisation: a "third-party site" names where the exception is *thrown*, not
   where the fix has to live.
4. **Suppression is a fix the gate actively rewards, and the ratchet has no
   vocabulary to constrain it.** Every earlier Track A ticket made a row give or
   rearranged one; #1230 is the first to *remove* content below a threshold, and
   absent content never overflows. A threshold accidentally set above the height
   the dashboard actually gives the card leaves all 105 of its gate cases green
   (2 widths × 2 tabs × 26 locales, plus the tab-registry check) and the card blank — verified, not feared: `_kProtocolChartMinHeight` 70 → 200 and
   `_kDonutMinRingThickness` 10 → 60 each delete a chart at the shipped height
   with the gate still green. So the guard test asserts *presence* at the 4 rows
   `HeightStrategy.strict(4)` gives (chart slot 148-173px) as well as absence at
   the 3 rows the gate pumps (12-37px). Any later ticket that clears a coordinate
   by not drawing something owes the same pair.
5. **Where a card overflows, look for what it also clips.** ui_kit ≤ v2.34.10's
   `AppPieChart` took the ring radius from the call site but the centre-hole radius
   from the theme (`ChartStyle.pieCenterRadius`, 60px here), so the drawn diameter
   was `2 × (centre + ring)` and did not follow `size`. The card's `size: 160` with
   the default 40px ring drew a **200px donut into a 160px box** — 20px clipped off
   every side at *every* width including desktop, invisible to the gate because a
   clip is not an overflow. Measured by pixel extent, the painted diameter was 200px
   at every `size` from 120 to 300, so `size` bounded the drawing in neither
   direction; filed upstream as linksys/privacyGUI-UI-kit#22 and **fixed in
   v2.34.11**, which derives both radii from the box. This branch bumps to it and
   deletes the `sectionRadius: size / 2 - pieCenterRadius` workaround the fix makes
   redundant — ui_kit's own dartdoc says the two now draw identically. Measured
   after removal: 191px card → 153px box, **57.4px hole + 19.1px ring**; 288px and
   512px → 160px box, 60px hole + 20px ring; the caption's half-diagonal is 32.0px
   at all three, so it clears even the shrunk hole by 25.4px. The one thing the
   upstream fix changes for a *tight* box is which radius gives: it shrinks the
   **hole**, not the ring, so a `centerWidget` sized against the themed value can
   overhang — which is the second reason `_kDonutMinRingThickness` suppresses rather
   than shrinks. The card's cap is now written as a ring thickness measured outward
   from the same themed hole as that floor, so no theme's `pieCenterRadius` can
   invert the two and close the window (a flat 160px would leave `neumorphic`'s 65px
   hole only 150-160px, and any hole past 70px nothing at all). The app's other four
   `AppPieChart` call sites (`size: 180` ×2, `size: 120`, one caller-supplied) are
   fixed by the bump without touching them. Second instance of the pattern §2.10d
   found in `network_health`'s gauge centre.
6. **AC 5 is a claim about the card, and a tab with no coordinates on it can still
   fail it.** Both #1230 sites are on the Rules tab, so the Ports tab was outside
   the coordinate list entirely — and its port-forwarding rows fit at 191px, which
   the gate reads as fine. Swept across all 26 locales, its localized text is clean
   (6 locales wrap the heading to 2 lines, `pt_PT` wanting 230.1px of a 157.4px
   row; nothing clips). Its **mapping target does not read**: 36.9-38.5px of room
   for 82.3-103.7px of "host:port", so every rule shows about two characters of its
   destination in every locale. The cause is not this card. `MapsToRow` gives its
   source and target a `Flexible` each, and `RenderFlex` splits the room **evenly**
   between equal flexes without handing back what the shorter half declines —
   measured, the source takes its 30.7px and the target still gets exactly half,
   38.5px of the pair's 77px. So the target's ceiling is half the mapping row
   whatever else that row spends, and no width this card can give it is enough:
   103.7px of target needs 227.4px of mapping, more than a 191px card is wide. Both
   card-side fixes were measured and neither suffices alone — putting the mapping on
   a full-width line of its own still leaves the target 68.7px, and it costs 20px a
   rule, which overflows the 3-row minimum AC 4 forbids raising by +11px to +36px
   unless the DMZ list goes with it. What clears it is the combination: that line,
   the DMZ list dropped at narrow width, **and** `MapsToRow` giving its bounded half
   its intrinsic width instead of half the row — measured green on this card's whole
   readability suite. That last part contradicts the widget's own docstring
   ("[target] is the part that ellipsizes, since the source is short and bounded
   while the target is not") and is shared with seven other call sites, so it is a
   `row_blocks.dart` change and not #1230's; the readability suite records the
   limitation as a failing-when-fixed expectation rather than a comment. **A shared
   layout block's flex distribution is a density decision** — the even split is
   invisible until a card is narrow enough for the two halves to want different
   amounts, and then it is the whole difference between "19…" and the address.

The claims the gate cannot make — both arrangements legible, both tabs legible in
all 26 locales, both charts present at the shipped height, the donut never wider
than its box, no slice label painted into the ring — are covered by
`test/page/dashboard/views/components/firewall_overview_readability_test.dart`,
tagged `dashboard-card` so it gates; each of its eight groups was verified to fail
under a mutation of the code it guards (eleven mutations, tabulated in the file,
seven of which leave the #1183 gate green). It also re-asserts plain overflow at
every realization it pumps, which is not redundant with the gate: the gate pumps
`minHeightRows` only, and the shipped 4 rows is the one height at which the donut's
caption and fl_chart's axis strip are built at all — the two sites #1230 fixed were
otherwise measured by nothing at the height they actually render.

Three follow-ups left open rather than folded into #1230: the narrow arrangement's
tile is `_InfoGridTile` in a `Row`, which `layout_blocks` has no variant for and
`ethernet_ports` hand-rolls too (**#1275**); the helpers these readability
tests share are now cloned across up to seven files (noted on **#1238**, the next
card to need them); and `MapsToRow`'s even flex split (item 6), which no card can
work around and which needs the shared block changed.

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

   **Closed by #1290** (§2.6h), and the closure sharpens what was recorded here.
   The compact form shows all five ports in 72px of the 121px viewport at the 288px
   realization and the popup form answers 191px with `3/5` plus a tap, so the
   inherited AC is met at both narrow realizations. But the 41px was never
   recoverable *as a width*: a 4px sweep of `[200, 700]` in the pinned normal form
   seats 0 of 5 items at all 126 widths, so "the narrowest clean width at which the
   port state is readable" does not exist for the normal form and the fix had to be
   a different rendering. The desktop half of this point stands unchanged and
   unfixed — at 512px no item seats whole either — and it retires by *height*, not
   width: at this card's shipped `rows: 3` (257px of viewport) four of the five seat.

The AC that *is* gate-invisible and satisfiable — the two tiles being a matched
pair — plus the label-legibility floor are covered by
`test/page/dashboard/views/components/ethernet_ports_summary_readability_test.dart`,
tagged `dashboard-card` so it gates; each of its four groups was verified to fail
under a mutation of the code it guards (the mutations are tabulated in the file).
Since #1290 every pump in it pins `CardDensity.normal`: the narrow widths it names
are no longer widths at which the grid selects this arrangement, but they are the
widths at which the *presentation* shows it (§2.6h point 2), so the pin keeps the
four groups pointed at the form they were written for.

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

#1239 measured how narrow that band actually is: 200px is reached only by a
`minColumns: 3` card, and only near a 601px screen, where its realization is
191.4px. A 4-column floor is 260.5px and a full-width card 288px, so nine of the
eighteen widgets sit above the threshold at every width (§2.6c item 1). Raising
the constant past 260.5px would pull those nine in — which is a different decision
from this one, since for them popup would replace compact rather than backstop it.

Since #1299 that sentence is about **widths only**: a user can pick popup for eight
of those nine, so the form is reachable on them without touching the constant
(§2.6i item 7). What raising it would change is whether they get popup *without
being asked* — which is why it is still deferred.

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
| #1267 | Second data profile for the gate + what the Channels tab drops at that density (§2.7, §2.10g) — **implemented** | 0 (+54 cases) |
| #1234 | `system_status` remaining ×3 sites (§2.10d) — **implemented** | 34 |
| #1236 | `lan_info` + `device_info` card-own (§2.10d) — **implemented** | 29 |
| #1237 | `time_settings` card-own (§2.10d) — **implemented** | 21 |
| #1235 | `network_health` gauge centre (§2.10d) — **implemented** | 3 |
| #1247 | `firewall_overview` `MapsToRow` — side effect, not its brief (§2.9a) — **implemented** | 46 |
| #1230 | `firewall_overview` remaining ×2 sites (§2.11, §2.11a) — **implemented** | 21 |
| #1238 | `connected_devices` ×2 card-own sites + the ui_kit v2.34.10 upgrade (§2.10e) — **implemented** | 27 |

Ceiling **528 / 560** as planned, on the assumption that ui_kit's 26 and
fl_chart's 6 both stay blocked. Neither did: #1238 cleared all 27 after the
v2.34.10 upgrade (§2.10e), and #1230 closed fl_chart's 6 from the call site by
declining to draw into a slot shorter than the axis strip (§2.11a). The ceiling
is **560 / 560**, and no coordinate is dependency-blocked.

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

That split held for exactly as long as the two dependencies did, and neither
held. ui_kit **v2.34.10** shipped the `AppListTile` change
(linksys/privacyGUI-UI-kit#20), so the 26 became call-site-fixable and #1238
cleared all 27 together — the necessary-but-not-sufficient reading is what made
that cheap, since the two card-own sites had to be fixed regardless and were the
whole of the work once the slot stopped being unbounded (§2.10e). #1230 then
cleared all **21**, fl_chart's 6 included, by declining to draw a chart into a
slot shorter than its own axis strip (§2.11a). So 22 of the 48 were clearable
here rather than 16, the other 26 needed one upstream tag and no call-site
compromise, and the allowlist now holds **0**.

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

So the dependency-blocked share of the baseline ended at **0 of 560, not 45** —
32 as planned, 26 once #1230 measured fl_chart's 6 and closed them at the call
site (§2.11a), and none once ui_kit v2.34.10 released #1238's 26 (§2.10e). And
`firewall_overview` was a *height* problem, all 21 of its coordinates bottom
overflows, a different class from the four width shapes these tickets settled.

Neither card kept the epic's `baseline #1183` default in the end, and the rule
that a ticket touches only the notes of the cards it closes is why. #1230 closed
`firewall_overview` outright, so both its keys and its note are gone from
`known_overflows.json` — including the fl_chart fallback entry §2.11 had reserved,
which measurement made unnecessary (§2.11a). #1238 deleted `connected_devices`'
note along with its two keys, which is the same rule applied in the other
direction: the note exists to name a live blocker, so it goes when the block does.
Between them the file is left with an **empty `tracking` and an empty
`allowlist`** — the ratchet's floor, and the state the gate has to hold from here:
every future overflow is a new entry, and there is no longer any exempt
coordinate to hide behind.

#1266 is in this track despite clearing nothing: it is the only entry that *adds*
coordinates (3, by localizing a hardcoded string) and removes them again in the
same change. It belongs here rather than in Track B because the ratchet is what
constrains it — see §2.10c for why the two halves cannot ship separately.

#1267 clears nothing either, and is here for the same reason from the other
direction: it grows the gate's *domain* (1644 → 1698 cases, a data dimension
alongside width and locale) and the ratchet is what constrains how — hence opt-in
per card and `@profile`-namespaced keys, so no closed ticket's arithmetic moves
(§2.7, §2.10g). Its own coordinate is one the default profile could never have
produced. Three later tickets sit in this track without a row of their own because
they are the Statistics twins of entries that have one: #1270 (§2.10f), #1297
(§2.10i — #1267's two density questions asked of the WiFi Channels section, which
the gate cannot see at all) and #1271, which is not a layout ticket at all — it is
the shared SNR aggregation the two surfaces had drifted apart on, found while
measuring #1267's tab.

#1298 is the smallest entry in the track and sits here on the same footing: nine
ARB strings, no change under `lib/`, no coordinate moved, gate 1698/1698 before and
after. It belongs to the ratchet because it changed the *inputs* the earlier
measurements were taken with. `tr` is the failing locale in #1258, #1266, #1270 and
#1267's original `+9.0px`, and it was failing partly on a string that was never
Turkish (§2.10h). A ticket that touches no assertion can still invalidate the
evidence for a dozen of them, so the cost of landing it is re-running every
measurement that quoted the old string — which is where the epic's one documented
over-claim turned up (§2.10h finding 2).

#1296 has no row either, and its reason is the inverse of #1266's: it clears
nothing and adds nothing, because everything it changes is **invisible to the
ratchet by construction** — three tabs gained a scroll region and one was measured
and refused, with each card's own coordinates (209 / 209 / 209 / 157) green under
every mutation in both directions (§2.10j point 4). It belongs to the ratchet as
the ticket that decided how far #1267's mechanism goes, and it is verified entirely
outside the gate: `card_scroll_net_test.dart`'s 161 cases, which fail 47 / 47 / 45
/ 41 on the same four mutations. The gate's role here was only to confirm the
conversions cost nothing it *can* see — 1698/1698, allowlist empty, before and
after.

#1245 has no row for a third reason: it is the only ticket in the track whose
subject is the *duplication* the ratchet work created rather than the coordinates
it cleared. #1226 and #1233 fixed the same legend shape nine times across five
files, and #1229 added the fifth copy of the dot knowingly (§1.1) — so the debt was
booked at the time and paid here, upstream, under Article XIV. It clears nothing
and is allowed to move nothing: 1698/1698 with an empty allowlist before the
dependency bump, after the bump alone, and after the migration (§2.10k). Its
verification lives in the two suites the gate cannot substitute for —
`dashboard_legend_readability_test.dart` passing **unmodified**, and a new
`legend_entry_label_kind_test.dart` that asserts the ellipsize-vs-soft-wrap rule
per label kind instead of trusting seven comments to stay in agreement.

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
| #1239 | Popup form + dialog reuse (§2.1) — **implemented**, lessons in §2.6c |
| #1240 | Per-card thresholds and compact forms (§2.4, §2.5) — **implemented as a decision and a split**, lessons in §2.6d. Measured: all 18 cards fit, so no card declares a threshold; the six that are unreadable at 191px are split into four batch tickets (#1288, #1289, #1290, #1291), `ethernet_ports`' inherited port-list AC (§2.12) among them |
| #1288 | Hero row — `device_info` 262, `lan_info` 250, `time_settings` 256, the registry's first declared thresholds — **implemented**, lessons in §2.6e |
| #1289 | `connected_devices` device row — `normalAbove: 336`, the first threshold *above* the 288px realization — **implemented**, lessons in §2.6f |
| #1290 | `ethernet_ports` port list — `normalAbove: 386`, the registry's first compact form with a *rendering* of its own, and the first card with no readable width at all — **implemented**, lessons in §2.6h |
| #1291 | `network_health` gauge centre + metric chips — `normalAbove: 366`, the first *tabbed* card to declare a threshold; the gauge is back to scale 1.000 — **implemented**, lessons in §2.6g |
| #1299 | Density selectable in edit mode, the form constraining resize (§2.1 as amended, §2.6i) — the arrow inverted: popup on 17 cards, compact on the 6 with a threshold, persisted per breakpoint — **implemented**, lessons in §2.6i |

#1240 waited on all of Track A: thresholds are meaningless while fit widths are
still moving, and the point of the layout fixes is to lower them. Re-measured
after they landed, every card fits at its narrowest realization, so **absent is
the correct value for all 18** — see §2.6d. What remains of the track is
readability, tracked per batch rather than per threshold (#1288, #1289, #1290,
#1291, tabulated at the end of §2.6d), and each batch owes a
compact form for `[200, normalAbove)` as well as the threshold itself: the popup
form covers below 200px, and §1.5's 191.4-422.0px span for a 3-column card means
the interval between is reachable.

**Six** cards now declare a threshold — `device_info` 262, `lan_info` 250,
`time_settings` 256 (§2.6e), `connected_devices` 336 (§2.6f), `network_health` 366
(§2.6g), `ethernet_ports` 386 (§2.6h) — so "absent for all 18" is the statement
#1240 measured, not the state of the registry. All four batches held the gate at
1644/1644 with `known_overflows.json` byte-identical: a threshold changes which
form is *selected*, and every form was already clean — which is exactly why each
batch owes a readability suite the gate cannot substitute for, and why the
suites the thresholds invalidate have to be re-pointed rather than re-measured
(§2.6h point 5).

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

**Superseded in one direction by §2.6d point 4.** That reasoning holds for a card
that overflows in its normal form, and after Track A **no registered card does** —
so a too-low threshold now produces illegibility, which the gate cannot see, and
the claim survives only on a synthetic card (`card_popup_form_test.dart`). The
mirror case, a threshold set too **high**, was never covered by it: it blanks a
readable card into a popup form and the gate goes *greener*. That is why every
batch ticket above owes the two-sided assertion of §2.11a point 4.
