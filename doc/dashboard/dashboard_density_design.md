# Dashboard Card Density — Design Decisions

**Last Updated: 2026-08-12** · Follow-up to #1183 · Status: **agreed; tickets #1225–#1240 published; #1225 + #1226 + #1233 implemented (not yet merged), rest not started**

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

The private colour-dot widget is additionally duplicated **verbatim in four
files** (the three above plus `device_analytics`). De-duplicating it, or
extracting a shared legend entry, would be a **new shared widget** and therefore
needs approval under Article XIV — so the fix is applied in place, and the
extraction raised separately rather than blocking on that conversation. That
raise is **#1245**, filed after #1233; it carries the constraint #1233 measured,
namely that any shared entry must express the ellipsize-vs-soft-wrap distinction
per label kind (§2.10a point 2) and must not absorb the WAN/LAN row, which
deviates for a reason (§2.10a point 3).

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
| #1227 | Shared blocks made overflow-safe (§2.6) | 101 |
| #1228 | `ethernet_ports` ×2 sites | 52 |
| #1229 | `wifi_performance` ×2 sites | 45 |
| #1230 | `firewall_overview` own sites (§2.11) | 48 |
| #1234 | `system_status` remaining ×3 sites | 34 |
| #1236 | `lan_info` + `device_info` card-own | 29 |
| #1237 | `time_settings` card-own | 21 |
| #1235 | `network_health` gauge centre | 3 |
| #1238 | `connected_devices` card-own (§2.6) | 1 |

Ceiling **515 / 560**. The other 45 are the dependency-blocked ones (§1.1).

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
| #1240 | Per-card thresholds and compact forms (§2.4, §2.5) — split after fit widths settle |

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
