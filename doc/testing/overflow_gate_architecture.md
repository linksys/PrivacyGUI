# Overflow Gate — Framework Architecture

**Last Updated: 2026-08-21** · Refactor proposal for the #1183 gate family · Status: **agreed and ticketed as epic #1335 (13 tickets: #1336–#1346, #1348, #1349). §6's cell↔test mapping decided 2026-08-20; §10 Q2 and Q4 closed 2026-08-21; R4's direction corrected against the code (§1.3, §9.2); R5 added and §1.2's cost table re-measured 2026-08-21 (§9.3); the local-versus-CI scout matrix and its consequence for R2/R4 verification recorded 2026-08-21 (§8, §9.2). Implementation started 2026-08-21: #1337 (baselines), #1336 (R1, tags), #1338 (R2's parser), **#1351 (the gate's last call into the golden parser), #1340 (surface + collector) and #1341 (the ratchet re-key)** have all landed on `fix/1314-1328-chrome-overflow`. **R2 is therefore complete on the gate side**, and #1339's golden half was split out of R2 into R4 on 2026-08-21 (§3.5), because it is the only part of R2 a developer machine cannot verify. Stacked on `fix/1314-1328-chrome-overflow`, carrying one accepted conflict with PR #1325 (§9.1).**

**Ticket map.** R1 → #1336 ✅ · R2 → #1338 (parser) ✅, #1351 (retire the gate's dependency on the golden parser) ✅, #1340 (surface/collector) ✅ · R3 → #1342 (runner, proved on chrome), #1341 (ratchet) ✅, #1343 (main card sweep), #1344 (forced-form), #1345 (popup) · R4 → #1346 + #1339 (retire the golden framework's own parser — resequenced here 2026-08-21, see §3.5) · **R5 → #1348 (acceptance)** · **pilot → #1349**. Plus #1337, which has its own document rather than a section here: a byte-stable baseline capture, because R3's "compared cell-by-cell against a pre-port run" names a comparison without naming a mechanism, and 1,898 cells cannot be diffed by eye. **#1337 is implemented and its four baselines are captured at `4fb1ac5e-dirty`** (that sha plus #1337 itself — a baseline cannot name the commit containing it; `chrome` was re-captured at `785c6f67-dirty` when #1356 took the action count out of its cell ids and unified the locale spelling, a pure rename proved row-for-row) — see [overflow_baselines.md](overflow_baselines.md); R3 and R5 both consume `./tool/overflow_baseline.sh check`.

**Two steps this document did not have (added 2026-08-21).** R1–R4 as written verify that each port matches its own baseline, which is necessary and not sufficient: a refactor that makes 3,800 cells run faster and quieter while measuring less satisfies all of it. So **R5 (#1348)** re-runs the card suite's existing mutation table against the ported code and adds one *executed* mutation per framework invariant — the precedent being that table's own row 1, where a real defect was killed by 26 of 26 `network_health` tab-0 cases while the main width sweep, the largest thing in the file, saw nothing (§9.3, which also records which of that table's counts no longer reconcile). And the **pilot (#1349)** is now ticketed inside the epic rather than deferred past it, gated on R5, with §10 Q5 as its deliverable.

## Purpose

The #1183 overflow gate grew into two independent frameworks that measure the
same thing. `test/page/dashboard/cards/dashboard_card_overflow_test.dart` (the
card sweep) and `test/page/shell/page_chrome_overflow_test.dart` (the chrome
sweep, #1314/#1328) share exactly one file — `test/util/overflow_probe.dart` —
and re-invent twelve other things between them. (Written of the pre-refactor
tree. Since #1338/#1340 the shared spine is three files under `test/layout_gate/`,
still reached through that path, which is now a re-export; the parser, the
collector and the surface have left the re-invented list.) A third path,
`test/golden_test/golden_framework/golden_runner.dart`, parses the same overflow
string a third way and then discards its own verdict.

This document records the alignment that established which differences are
essential and which are accidental, the architecture that absorbs the accidental
set, and the migration order that gets there without a red intermediate state.

**It is a refactor, not a feature.** Nothing here adds a surface to the gate. The
pages pilot depends on it and is deliberately sequenced after it (§9), because
adding a third family to two frameworks would produce three.

**Companion documents**

| Document | Role |
|---|---|
| [overflow_baselines.md](overflow_baselines.md) | **#1337, landed.** The mechanism R3 and R5 compare against: `./tool/overflow_baseline.sh check <sweep>`. Baselines for all four sweeps are captured at `4fb1ac5e-dirty`, before any port — `chrome` re-captured at `785c6f67-dirty` for #1356's cell-id fixes. |
| [../dashboard/dashboard_density_design.md](../dashboard/dashboard_density_design.md) | How the card family's 560 → 27 → 0 allowlist was eliminated; the measurements the card axes rest on. |
| [../dashboard/dashboard_framework_overflow_investigation.md](../dashboard/dashboard_framework_overflow_investigation.md) | How a declared spec constraint becomes a real `BoxConstraints`. |
| [../../.claude/skills/dashboard-overflow-gate/SKILL.md](../../.claude/skills/dashboard-overflow-gate/SKILL.md) | How to operate the gate today. Its "adding a new probe" section is superseded by §3 here once R3 lands. |

---

## 1. What exists today

### 1.1 The two frameworks, aligned

| Aspect | Card sweep (#1183) | Chrome sweep (#1314/#1328) | Verdict |
|---|---|---|---|
| cell↔test mapping | 1 cell = 1 `testWidgets` | 1 test = N cells (inner loop over locale × mode) | accidental |
| Axis source | derived from grid geometry (`narrowestRealizationOf`) | hand-written width list | **essential** |
| Monotonicity in width | yes — narrowest realization is the worst case | no — the failure band is 601–767px | **essential** |
| Host construction | shared `buildDashboardCardApp` in a probe util | private `_topBarHost` / `_headerHost` in the suite | **essential** |
| Fresh render tree | one test per cell | `ValueKey(cellKey)` on the host root | accidental |
| Overflow collection | `probeCardOverflow` → `runWithOverflowCollection` | `collectOverflow` directly | accidental |
| Surface set (`setSurfaceSize` + `view.physicalSize` + `devicePixelRatio`) | inside the probe, 2 sites | hand-copied **7** times in the suite | accidental — **closed at #1340**: one `setLayoutSurface` |
| Surface reset | none | `_resetSurfaceAfter` teardown | accidental (the second was right) — **closed at #1340**: the primitive registers the teardown itself, so the card path resets too |
| Tolerance | `const _tolerancePx = kOverflowTolerancePx` | inline `> kOverflowTolerancePx` | accidental |
| Locale filter | `_targetLocales` + `--dart-define=LOCALE` | always all 26 | accidental |
| Ratchet | `known_overflows.json` + dead-exemption detection | none | accidental — **re-keyed on `file:line` at #1341** (`test/layout_gate/ratchet.dart`); dead-entry detection is now one `tearDownAll` verdict over the whole run, suppressed when the run was filtered (§5 contract 4) |
| Report | `OverflowReportItem` → MD/HTML/PNG dumps | none | accidental |
| Failure surface | `fail()` per cell with a remediation paragraph | aggregated `failures` list + `expect(isEmpty, reason:)` | accidental (the second reads better for locale-driven defects) |
| Localizations access | not needed (`find.textContaining` on markers) | `localizationsByTag` preloaded in `setUpAll` | accidental |
| Readability assertions | 7 separate suites | inline in the same file | accidental |
| Tag | `layout-gate` + `overflow` | `layout-gate` + `overflow` | same |

Fifteen differences; three are essential.

**Four of the accidental rows are closed as of 2026-08-21** — the parser (#1338),
the surface set and the surface reset (#1340) and the ratchet key (#1341). The
table is kept as the diagnosis the epic was scoped from rather than rewritten to
the current tree; each row now says where it landed.

**A sixteenth difference surfaced at review and is closed too (#1356): the two
families spelled one locale two ways.** The three card sweeps each defined
`zh_TW` privately; the chrome sweep called `Locale.toLanguageTag()` and got
`zh-TW`. It is not on the table above because it is not visible from either suite
— each was self-consistent — and it took the committed datasets sitting next to
each other to show. It matters twice: the four baselines are grepped by hand
(`overflow_baselines.md` §2), and the ratchet matches the tag a sweep hands it
against locale lists a human wrote, so once #1342 puts the chrome sweep on the
runner a `zh-TW` would silently match no entry and read as "not deferred". Now
`localeTag()` in `test/layout_gate/locale_tag.dart`, imported by all four.

```
  dashboard_card_overflow_test.dart      page_chrome_overflow_test.dart      golden_runner.dart
  844 lines · 1898 sweep cells           707 lines · ~1468 pumps             31 golden configs
  ═══════════════════════════════        ═══════════════════════════         ══════════════════
  locale   --dart-define filter          locale   all 26, always             locale   CI-injected
  tolerance  const _tolerancePx          tolerance  inline                   tolerance  NONE
  ratchet    known_overflows.json        ratchet    –                        ratchet    –
  report     OverflowReportItem→MD/HTML  report     –                        report     overflow_warnings.json
  fresh tree 1 cell = 1 test             fresh tree ValueKey(cellKey)        fresh tree n/a
  surface    inside probeCardOverflow    surface    3 lines × 7 copies       surface    golden device
  host       buildDashboardCardApp       host       _topBarHost/_headerHost  host       ShellType
  axes       card × span × tab × locale  axes       width × locale × mode    axes       device × locale
        │                                        │                                    │
        └────────────┬───────────────────────────┘                                    │
                     ▼                                                                ▼
        ┌────────────────────────────┐                          ┌──────────────────────────────┐
        │ test/util/overflow_probe   │                          │ golden_framework/            │
        │ worst side                 │  ◄── the only sharing    │ overflow_diagnostics         │
        │ tolerance 2.0px            │                          │ first side · no tolerance    │
        │ unparseable → ∞ (loud)     │                          │ + file:line  ◄── UNIQUE      │
        └────────────────────────────┘                          └──────────────────────────────┘
                                                                               │
                                                       pass/fail discarded (:373–391 `return;`) — correct
                                                       file:line discarded downstream, in THIS repo, at
                                                       test_scripts/combine_results.dart:178  ◄── the real loss
```

### 1.2 The measured cost model

Measured on this branch 2026-08-20, and every row re-measured 2026-08-21:

| Suite | `flutter test` tests | Pumped cells | Wall clock | Per cell |
|---|---|---|---|---|
| Card sweep (one file) | 1,921 | 1,898 | ~20–22s | **10.5–11.6ms** |
| Chrome sweep (one file) | 31 | ~1,468 | ~8s | **5.4ms** |
| The four overflow sweeps (4 files, named) | 2,386 | > 3,000 | ~30s | — |
| The same four via `--tags overflow` | 2,386 | > 3,000 | 1m53s | — |
| Whole `layout-gate` family (39 files) | 3,340 | > 3,800 | 2m24s | — |
| Whole PR gate (`./run_tests.sh`) | 7,260 | — | 2m44s–4m56s | — |
| Full-page golden (for contrast) | 6 | 6 | ~1s | ~170ms |

**Re-measured 2026-08-21.** Test counts are deterministic and are what the
tickets assert on; wall clock is not, because `flutter test` parallelises suites
across cores — read that column as an order of magnitude.

- The card sweep is **1,921** tests, not 1,922, so the file's non-sweep remainder
  is 23, not 24 (§6).
- **The 2,386 row was mislabelled, not wrong.** It is the four *sweeps*
  (1,921 + 80 + 354 + 31 = 2,386, the `--tags overflow` pre-commit selector of
  §4), not the 39-file family, which measures **3,340**. Both rows now appear,
  because R1's two tags select exactly these two sets and the tickets assert on
  each separately.
- **Selecting by tag costs 1m53s where naming the four files costs 32s**, for the
  identical 2,386 tests (measured 2026-08-21, #1336). `@Tags` is read by loading a
  suite, so the tag compiles all 315 test files in order to skip 311 of them. The
  selection is exactly right either way, so the tag is correct for a pre-commit
  run and for `tool/run_overflow_test.sh` — both of which must not miss a fifth
  sweep — and naming the file is correct for an inner loop. **#1336's ticket text
  claimed "about half a minute" for the tag; that figure belongs to the filename
  path.**
- The gate total **7,260 is exact** as of #1341 plus its review, and moves with the
  tickets: 7,144 when the epic was written, 7,200 after #1337's baseline
  instrumentation, 7,217 after #1338's 17 parser tests (14, plus 3 pinning
  `toString()` after review found its output change untested), 7,221 after #1351
  (+4: one emitter test and three pinning the record's keys and types), 7,229 after
  #1340 (+8, the surface primitive's own group), 7,258 after #1341 (+29,
  `ratchet_test.dart`) and 7,260 after that ticket's review (+2, pinning that `@` in
  a path is a site and that a whitespace key is rejected for the reason it really
  was — see Invariant 2's second count correction).
  §6's projection therefore reads `7,260 − 1,898 + 73 = 5,435`, **not the 5,319
  the epic's acceptance criterion and #1348 still name** — whoever runs #1348 must
  re-derive it from the total standing at that moment rather than assert on 5,319.
  Every ticket in this epic has moved this number, which is the whole reason it is
  a subtraction rather than a literal.

The per-file sweep counts behind that row — main **1,921**, popup **354**,
forced-form **80**, chrome **31** — are each a port's baseline, so R3's four
tickets (#1342–#1345) each own one of them.

Two things follow, and both were previously mis-stated:

1. **Per-cell cost is the same order in both frameworks** (5–10ms). An earlier
   reading of "31 tests / 8s = 260ms" mistook a per-*test* figure for a
   per-*cell* one and produced a phantom 26× gap. The chrome sweep is in fact the
   cheaper of the two per measurement, because its hosts are provider-free while
   the card hosts stand up `kitchenSinkOverrides` and a
   `FallbackFontResolver`-wrapped theme.
2. **The 170ms figure belongs to the golden runner, not to overflow.** It is the
   right proxy for a *full page with its orchestrator*, and the wrong proxy for a
   chrome-style probe. The pages budget therefore stays open, and the pilot's job
   is to measure which of the two a real page resembles.

The card sweep's 1,898 cells decompose perfectly: **73 non-locale coordinates ×
exactly 26 locales each**, with no ragged group — re-verified 2026-08-21 by
grouping the JSON reporter's test names, which put all 73 coordinates at exactly
26 locales and none at any other count. This is what makes §6's regrouping a
clean cut, and it is the one figure in this section that survived
re-measurement untouched.

### 1.3 The third path: a source location measured and then flattened

`golden_runner.dart:373–391` hooks `FlutterError.onError`, recognises the
overflow, builds a record via `buildOverflowRecord(...)`, and returns — justified
in-place by "overflow in golden tests is cosmetic (visible in the golden image
itself)". `tearDownAll` at `:72` writes `goldens/overflow_warnings.json` (`:420`).

**Corrected 2026-08-21, against the code.** An earlier revision of this section
read that as a verdict "thrown away". Two things are wrong with that:

1. The `return` discards only the **pass/fail verdict**, and §8 argues it should
   keep doing exactly that — advisory is the right setting for a scout. The
   *record*, `file:line` included, is captured faithfully and written out.
2. The record is then parsed by `test_scripts/overflow_details.dart` into
   `OverflowDetail{widget, file, line, pixels, side, message, occurrences}` — a
   **richer** row than the gate's own card-shaped `OverflowReportItem`, which
   carries no source location at all. The direction of R4 in §9.2 was therefore
   backwards: it is the gate that needs to learn the golden side's join column,
   not the reverse, and #1338/#1343 already deliver it.

The real loss is one step further down, in this repo, at
`test_scripts/combine_results.dart:178`:

```dart
final sites = overflowDetails[goldenName] ?? const [];
test['hasOverflow'] = sites.isNotEmpty;   // ← file:line dies here
```

Every consumer downstream is screen-keyed as a direct consequence. Golden CI's
day-over-day collector (`PrivacyGUI-golden-ci`, `triage-agent/collector.py`) keys
its overflow diff on `{tsName}|{locale}|{deviceType}`, which is why one source
location multiplies into hundreds of rows, and why that collector's new-overflow
issue creation is **held in code** against a ~361-issue blast.

That pipeline is not idle. It runs in the golden CI repo across 26 locales and
four devices (`desktop1280`, `desktop1241`, `phone480`, `phone320` — more devices
than the local defaults, which declare no `locales:` at all and fall back to
`[Locale('en')]` at `golden_test_config.dart:85`), and it has already produced
roughly 135 ticketed coordinates:

- **#1302** (open): 15 coordinates collapsing to **5 source locations** across
  devices / shared / statistics / topology, every one locale-driven (`fr`,
  `fr_CA`, `fi`).
- **120 further coordinates** in admin, all at `firmware_update_card.dart:77`
  across 10 locales.
- One site is in ui_kit (`app_dialog.dart:95`) and therefore not fixable from
  this repo (constitution Article XIV).
- One site (`usp_node_detail_view.dart:467`) was found by a human, not the
  pipeline, because no fixture sets `lastContactTime`.

So the question the refactor has to answer is not "how do we detect page-level
overflow" — that already happens daily — and not "why is a measured signal
advisory" either, since §8 concludes advisory is correct for the scout. It is
**"why can the two datasets not be compared"**, and the answer is one line that
collapses a list of sites to a boolean. §8 is the shape of the comparison.

---

## 2. Essential versus accidental

The three essential differences are all about *what is being measured*, and none
of them should be abstracted away:

1. **Where the axes come from.** The card family derives width from production
   grid geometry, so a card added to `UspWidgetSpecs.all` is swept automatically.
   The chrome family enumerates a literal width list, because there is no
   geometry to derive it from — the widths that matter are breakpoints.
2. **Whether overflow is monotone in width.** The card sweep pumps one width per
   span and calls it exhaustive, and that argument is only sound because wider is
   never worse *within a form* (`narrowestRealizationOf`'s doc carries the proof,
   bounded by `kEnumerationSlackPx` = 0.5px, a quarter of the tolerance). Chrome
   has no such property: `menu_holder.dart:79` renders the top nav as
   `SizedBox.shrink()` at ≤600px, so #1328's failure band is 601–767px with clean
   water on both sides. A framework that assumed either property would be wrong
   for one of its families.
3. **How one cell's host is built.** A card needs the factory, tab pinning,
   density scope and the kitchen-sink fixture. The top bar needs a `GoRouter`
   ancestor, a mounted `Navigator` under `uspShellNavigatorKey`, and an
   `ExcludeSemantics` around it. These have nothing in common and never will.

Everything else on the list is the same problem solved twice.

---

## 3. Target architecture

### 3.1 Layers

Files **do not move**. `app_test_fonts.dart` has 28 importers,
`dashboard_card_probe.dart` has 24, `overflow_probe.dart` has 21; relocating them
means touching ~70 files for no behavioural gain. The new layer is additive and
the old paths re-export from it.

**Counts re-measured 2026-08-21** (files carrying an `import` of the path, which
is what a relocation would have to edit; an earlier revision wrote 20 in this
paragraph and 22 in the §3.2 diagram, counting different things). `overflow_probe.dart`
had **22** importers at #1338 and has **21** since #1351: `test/util/overflow_baseline.dart`
now imports `test/layout_gate/incident.dart` directly, because reaching the parser
through the shim would put it in a cycle with `collector.dart` — the one importer
the whole R2 sequence moved, and it moved for a reason the re-export cannot serve.

```
   SUITES ─ stay next to the code under test
   test/page/dashboard/cards/          test/page/shell/              test/page/<future>/
   dashboard_card_overflow_test        page_chrome_overflow_test     page_surface_overflow_test
          │ runOverflowSweep(                  │                              │
          │   DashboardCardFamily())           │                              │
          ▼                                    ▼                              ▼
  ┌──────────────────────────────────────────────────────────────────────────────────┐
  │ FAMILIES ─ own the three essential differences, and only those                    │
  │                                                                                  │
  │   DashboardCardFamily          PageChromeFamily          PageSurfaceFamily        │
  │   axes  card × span × tab      axes  width               axes  route             │
  │   monotone in width ✓          monotone ✗ (601–767)      monotone ? (pilot)      │
  │   host  buildDashboardCardApp  host  _topBarHost/_header host  shell + route     │
  │   geometry  grid math          geometry  literal list    geometry  –             │
  └──────────────────────────────────────────────────────────────────────────────────┘
                                    │ implements OverflowSurfaceFamily
                                    │   name / axisNames / enumerateCells / onCellSettled
                                    ▼
  ┌──────────────────────────────────────────────────────────────────────────────────┐
  │ test/layout_gate/  FRAMEWORK ─ absorbs the twelve accidental differences          │
  │                                                                                  │
  │   sweep.dart       runOverflowSweep   declares tests; never awaited              │
  │   cell.dart        OverflowCell       key = ordered axis values                  │
  │   surface.dart     set + reset        once                                       │
  │   ratchet.dart     allowlist keyed on file:line + dead-entry detection           │
  │   locale_tag.dart  localeTag()          one spelling of a locale: zh_TW           │
  │   report.dart      base row + family extension columns                           │
  │   collector.dart   runWithOverflowCollection / collectOverflow / settle           │
  │   incident.dart    ONE parser: worst side + tolerance 2.0 + ∞ + file:line         │
  └──────────────────────────────────────────────────────────────────────────────────┘
            ▲                              ▲                          ▲
            │ re-export                    │ re-export                │ R2: shares the parser
   test/util/overflow_probe.dart   dashboard_card_probe.dart    golden_framework/
   (22 importers unchanged)         (26 importers unchanged)     (golden_runner unchanged;
                                                                  R4 is one line down, in
                                                                  test_scripts/combine_results)
```

<details>
<summary>Same diagram as mermaid (for GitHub rendering)</summary>

```mermaid
graph TD
  subgraph S[Suites — next to the code under test]
    S1[dashboard_card_overflow_test]
    S2[page_chrome_overflow_test]
    S3[page_surface_overflow_test<br/>future]
  end
  subgraph F[Families — the 3 essential differences]
    F1["DashboardCardFamily<br/>axes: card × span × tab<br/>monotone ✓<br/>host: buildDashboardCardApp"]
    F2["PageChromeFamily<br/>axes: width<br/>monotone ✗ 601–767<br/>host: _topBarHost/_headerHost"]
    F3["PageSurfaceFamily<br/>axes: route<br/>monotone ?<br/>host: shell + route"]
  end
  subgraph K["test/layout_gate — the framework"]
    K1[sweep.dart · runOverflowSweep]
    K2[cell.dart · OverflowCell]
    K3[surface.dart]
    K4[ratchet.dart · keyed on file:line]
    K5[report.dart]
    K6[collector.dart]
    K7[incident.dart · one parser]
    K8[locale_tag.dart · one locale spelling]
  end
  S1 --> F1 --> K1
  S2 --> F2 --> K1
  S3 --> F3 --> K1
  K1 --> K2 & K3 & K4 & K5 & K6 --> K7
  K4 --> K8
  U1["test/util/overflow_probe.dart<br/>21 importers"] -.re-export.-> K7
  U2["dashboard_card_probe.dart<br/>24 importers"] -.re-export.-> K6
  U3["golden_framework<br/>golden_runner unchanged"] -.R2 shares parser.-> K7
  U4["test_scripts/combine_results.dart<br/>:178 stops flattening"] -.R4.-> K5
```

</details>

### 3.2 The two core types

```dart
/// One measurable coordinate: enough to pump exactly one tree, plus a stable
/// identity for the ratchet, the report and the test name.
class OverflowCell {
  /// Ordered, so the key is stable and the report columns line up.
  /// e.g. [('card','device_info'), ('width','191'), ('tab','2')]
  final List<(String axis, String value)> coords;
  final Locale locale;
  final Size surfaceSize;
  final Widget Function() build;

  String get key => coords.map((c) => '${c.$1}=${c.$2}').join('|');
}

abstract class OverflowSurfaceFamily {
  /// 'dashboard_card' / 'page_chrome' — namespaces the ratchet and the report.
  String get name;

  /// Ratchet key order and report column order. The first axis becomes the
  /// enclosing `group` name — see §5 for why that is a contract.
  List<String> get axisNames;

  Iterable<OverflowCell> enumerateCells();

  /// Runs once the cell has settled, still inside the overflow collector.
  /// This is the readability slot; see §7 on why it has no default.
  Future<void> onCellSettled(WidgetTester tester, OverflowCell cell);
}
```

A family answers two questions and no others: **which coordinates exist**, and
**how one coordinate becomes a host widget**. Geometry, the monotonicity
argument, and host scaffolding all stay inside the family, which is why the three
essential differences need no abstraction at all.

### 3.3 The runner

```dart
runOverflowSweep(OverflowSweepConfig(
  family: DashboardCardFamily(),
  tolerancePx: kOverflowTolerancePx,
  ratchet: OverflowRatchet.fromFixture(),   // #1341; path defaults to
                                            // kKnownOverflowsFixturePath
  report: cardReportRowBuilder,   // optional
));
```

It must be a **top-level declarative function**, shaped like
`runViewGoldenTests(GoldenTestConfig)` — it *declares* tests. A helper you
`await` inside one `testWidgets` cannot work here: Flutter reports each
`RenderFlex`'s overflow once per render-object lifetime, so a loop inside a
single test silently drops every measurement after the first unless something
forces a fresh subtree. Making the runner a declaration keeps that decision in
the framework's hands (§3.4, invariant 1).

### 3.4 The three invariants the framework owns

```
╔═ DECLARATION TIME ═ main() runs once; there is no tester yet ═════════════════╗
║  runOverflowSweep(config)                                                     ║
║    │                                                                          ║
║    ├─ family.enumerateCells()             ◄── the family is the only axis      ║
║    │     └─ 1,898 OverflowCell                 authority                       ║
║    │                                                                          ║
║    ├─ test('cell count')                 ◄── pins enumerateCells().length      ║
║    │     └─ the only defence against silent coverage loss (§6)                 ║
║    │                                                                          ║
║    ├─ group by every axis except locale   ◄── framework policy, fixed          ║
║    │     └─ 73 groups × 26 locales                                             ║
║    │                                                                          ║
║    └─ per group: group(axis0) { testWidgets(remaining axes) { … } }            ║
║                      └─ card id stays a group prefix                           ║
║                         contract: run_overflow_test.sh:162 --name "$CARD_ID"    ║
╚═══════════════════════════════════════════════════════════════════════════════╝

╔═ RUN TIME ═ one testWidgets = 26 cells ═══════════════════════════════════════╗
║  for locale in 26:                                                            ║
║    ┌────────────────────────────────────────────── owned by the framework ──┐ ║
║    │ 1  surface.set(cell.surfaceSize)                                       │ ║
║    │ 2  pumpWidget( KeyedSubtree(key: ValueKey(cell.key),   ◄── INVARIANT 1 │ ║
║    │                             child: cell.build()) )                     │ ║
║    │ 3  settleIgnoringAnimations(tester)                                    │ ║
║    │ 4  try  family.onCellSettled(tester, cell)   ◄── readability slot      │ ║
║    │    catch → record as this cell's failure     ◄── INVARIANT 3           │ ║
║    │ 5  incidents.where((i) => i.pixels > tolerance)                        │ ║
║    │ 6  ratchet.consult(cell.key, incident.sourceLocation)                  │ ║
║    │ 7  report.add(baseRow + familyColumns)                                 │ ║
║    └────────────────────────────────────────────────────────────────────────┘ ║
║  expect(failures, isEmpty, reason: '… in N locale(s): …')                     ║
║  teardown: surface.reset()                                    ◄── INVARIANT 2 ║
╚═══════════════════════════════════════════════════════════════════════════════╝
```

<details>
<summary>Same lifecycle as mermaid</summary>

```mermaid
flowchart TD
  A[main loads] --> B[family.enumerateCells]
  B --> C["test('cell count') pins length"]
  B --> D[group by all axes except locale]
  D --> E["group(axis0) → testWidgets(rest)"]
  E --> F{{run time: loop 26 locales}}
  F --> G[1 surface.set]
  G --> H[2 pumpWidget KeyedSubtree ValueKey cell.key]
  H --> I[3 settleIgnoringAnimations]
  I --> J[4 family.onCellSettled — try/catch]
  J --> K[5 filter by tolerance]
  K --> L[6 ratchet.consult on file:line]
  L --> M[7 report.add]
  M --> F
  F --> N["expect(failures, isEmpty)"]
  N --> O[teardown surface.reset]
```

</details>

**Invariant 1 — every cell host is wrapped in `KeyedSubtree(key: ValueKey(cell.key))`.**
Both existing frameworks dodge the once-per-render-object reporting rule, by
different means (a fresh test / a hand-written `cellKey`). Handing the dodge to
the framework makes it impossible to forget, and it upgrades "multiple pumps in
one test" from a trap to a safe operation — which the card family needs, because
its adjusted-screenshot capture re-pumps inside the same test.

**Invariant 2 — the surface is set and reset in one place.** The three-line
surface dance appeared **thirteen** times across the gate's measuring paths:
seven in the chrome suite, twice in the card probe, once inside the shared
`collectOverflow`, once in the stats-section probe, once in the popup-form gate
and once in the SNR render-parity gate — and only two of those paths reset it
afterwards. A width leaking into the next test silently measures the wrong
viewport.

**Landed 2026-08-21 (#1340).** All thirteen are `setLayoutSurface(tester, size)`
in `test/layout_gate/surface.dart`, which registers the restore itself, so the
paths that never had a teardown gain one and no caller of the spine can opt out.
There is deliberately no standalone reset primitive: every site that reset also
set, so a second entry point would be the "one place" this invariant forbids. The
chrome suite's private `_resetSurfaceAfter` is gone and its baseline is unchanged
(`./tool/overflow_baseline.sh check chrome`, 1,248 cells identical).

Two count corrections, both worth keeping because each was a different mistake.
An earlier revision wrote "eight times in the chrome suite": the total of ten was
right, the split was not — the eighth copy was in `collectOverflow`, which is a
materially different fact, because that one was already shared and simply was not
reset for the card half. Then ten itself proved short: the review of #1340 found
three more, in `stats_section_probe.dart`, `card_popup_form_test.dart` and
`wifi_snr_render_parity_test.dart`. Two of the three reset nothing at all, so
they were leaks of exactly the kind this invariant is about, and the first sat
twenty lines under a header that already credited the shared layer with owning
the restore.

**Where the invariant stops.** It binds the paths that reach the gate's spine —
anything that pumps through `runWithOverflowCollection` / `collectOverflow`, or
imports `overflow_probe.dart` to size a card. Five `layout-gate` carriers still
write the triple by hand (`card_density_scope_test.dart`,
`usp_info_row_test.dart`, `card_form_toolbar_test.dart`,
`usp_wifi_status_card_legibility_test.dart`, `dhcp_card_test_harness.dart`) and
are deliberately left: they collect no overflows and do not otherwise depend on
`test/layout_gate/`, so porting them would add a dependency on the spine to buy
consistency alone. `overflow_probe_test.dart` keeps one copy on purpose — it is
the dirty-all-three fixture the primitive is measured against.

**Invariant 3 — a per-cell exception is recorded as that cell's failure.** This
is the precondition that makes the locale inner loop safe: one locale throwing a
non-overflow exception must not take the other 25 down with it. Roughly ten lines,
and without them §6's regrouping trades reporting quality for isolation.

### 3.5 One parser

Two independent parsers of the same string exist today, and each has what the
other lacks:

| | `test/util/overflow_probe.dart` | `golden_framework/overflow_diagnostics.dart` (#1197) |
|---|---|---|
| Side chosen | worst | first |
| Tolerance | `kOverflowTolerancePx` = 2.0 | none |
| Unparseable | `double.infinity` — fails loud | failure-tolerant |
| Source location | — | **`file:line`, with path normalisation** |

The merged parser keeps the loud-failure behaviour, the worst side and the
tolerance, and absorbs `file:line`.

**Landed 2026-08-21 (#1338), and "exactly one" is not true yet.** The merge lives
at `test/layout_gate/incident.dart` and `overflow_probe.dart` re-exports it, so
its 22 importers are untouched. Call sites still reach the second parser, and they
split into two groups that do **not** belong in one ticket:

| | Call site | Verifiable locally? |
|---|---|---|
| **gate side** (#1351) ✅ | `test/util/overflow_baseline.dart:185` spread `parseOverflowSource` into every baseline record — the *only* parser coupling between the gate family and the golden framework, and the reason that file imported it at all | **yes** — `./tool/overflow_baseline.sh check` |
| **golden side** (#1339) | `golden_runner.dart` uses its own copy; #1339 deletes it and points the runner here | **no** — needs golden-ci artifacts |

The gate side is a byte-for-byte no-op today, and provably so: all 3,587 rows
across the four frozen baselines are `clean`, with `-` in every incident column,
so nothing exercises the source fields. What changes is only the shape of a row a
*future* overflow would write — `parseOverflowSource` returns
`Map<String, String>`, so `line` serializes quoted, while `OverflowIncident.line`
is an `int`. (An earlier revision of this section called that "rewrites rows in a
dataset #1337 froze byte-for-byte". It does not; the dataset has no such row.)

**Consequence for sequencing.** Nothing in R2 or R3 depends on the golden side —
the only ticket that does is #1346, which needs the two sides measuring the same
way before it can join them on `file:line`. Verified 2026-08-21: of the 39
`layout-gate` files, four import `golden_framework`, and all four import only
`mocks/`. So #1339 is a prerequisite of **R4**, not of R2, and doing the gate side
separately — split out as **#1351** on 2026-08-21 — takes golden-ci off R2's
and R3's critical path entirely.

**The gate side landed 2026-08-21 (#1351).** `overflow_baseline.dart` reads
`OverflowIncident.file` / `.line` / `.widget` instead of calling the golden
parser, and `grep -rn parseOverflowSource test/` now finds callers only in
`overflow_diagnostics.dart` and its own test. Verified exactly as predicted:
`./tool/overflow_baseline.sh check` exits 0 on all four sweeps, 3,587 cells
identical. The `runDirectory` parameter of `overflowBaselineRecordLine` was
**removed** rather than left unused — an ignored parameter still reads as "this is
what the recorded paths are relative to", and nothing would have caught it
becoming false.

So the epic's "exactly one parser of Flutter's overflow string exists in the repo"
is now met **inside the gate family** — one parser is canonical and one runs — and
partially met repo-wide: `golden_runner.dart` still uses the copy, which is #1339
in R4.

`file:line` is not decoration. It is the correct ratchet key: a coordinate-keyed
allowlist invalidates wholesale whenever a layout is rearranged, whereas a
source-location key survives it. And it is the join column that makes golden CI's
advisory findings and the local gate's verdicts one comparable dataset (§8) —
which is what turns the graduation rule from something a person has to watch into
something a diff computes.

---

## 4. Tags

`layout-gate` is carried by **39 test files** (a 40th mention, at
`test/golden_test/flutter_test_config.dart:9`, is a comment) — 38 until #1341
added `test/layout_gate/ratchet_test.dart`, which carries `layout-gate` **only**:
it pumps no cell, so the `overflow` pre-commit selector has nothing to gain from
it. Only **6** of the 39 have "overflow" in the filename; the rest are density,
readability, form and gesture, layout blocks, probe self-tests, the ratchet oracle
and render-parity gates. Renaming the tag to `overflow` would therefore mislabel
33 files.

`dart_test.yaml` documents the tag's real meaning — since #1336 landed, in the
name as well as the comment:

```yaml
  # Defensive widget gates that must run in the PR test command (#1183), said in
  # the name since #1336: a PR-blocking defensive layout gate. All 39 carriers
  # are one — density, readability, form and gesture, layout-block, probe
  # self-test, render-parity and overflow.
  # NOT excluded by run_tests.sh's --exclude-tags="golden||loc||ui", so a
  # failure here blocks the PR — and tagging one of these `golden`, `loc` or
  # `ui` instead is how a gate leaves the PR command in silence.
  layout-gate:
```

Dart test tags are a set, not a hierarchy, so the answer is two tags:

| Tag | Applied to | Purpose |
|---|---|---|
| `layout-gate` | all 39 files | "PR-blocking defensive layout gate" — the semantics the comment already describes |
| `overflow` | the sweep files only, as `@Tags(['layout-gate', 'overflow'])` | the fast pre-commit selector |

Both must be declared in `dart_test.yaml`. Neither appears in `run_tests.sh`'s
`--exclude-tags="golden||loc||ui"` (lines 80 / 92 / 96), so both stay
PR-blocking — gating comes from *not being excluded*, which is also why tagging a
sweep `ui` or `loc` would remove it from the gate silently.

`flutter test --tags overflow` becomes the local pre-commit run. `tool/run_overflow_test.sh:18`
drops its hardwired `TARGET_TEST` in favour of the tag.

---

## 5. Contracts that must survive the refactor

1. **`run_overflow_test.sh:162` filters by test name** — `--name "$CARD_ID"`,
   which resolves today through the `group('${spec.id} overflow')` wrapper. The
   card id must remain a group-name prefix. Generating the enclosing group from
   `axisNames.first` satisfies this by construction.
2. **`--dart-define=LIST_CARDS`** (`:133`) prints the registry and returns early.
   Keep it as a family capability, not a framework one.
3. **`--dart-define=LOCALE` / `MIN_SCREEN` / `DUMP`** stay honoured; they are the
   dump tooling's only interface.
4. **`test/fixtures/known_overflows.json`** currently holds
   `{"tracking": {}, "allowlist": {}}` — zero tolerance is already fact, not
   aspiration. Nine `.dart` files name it, but it has exactly **one real reader**:
   `dashboard_card_overflow_test.dart:98`. The five further mentions in that same
   file are remediation text inside failure messages, and the ten mentions spread
   across the other eight files are comments. Re-keying it on `file:line` is
   therefore a one-file change plus a documentation pass.

   **Landed 2026-08-21 (#1341), and the prediction held.** The one real reader is
   now `test/layout_gate/ratchet.dart`, which took the card sweep's place in that
   set of nine; the sweep names the path through `kKnownOverflowsFixturePath` and
   no longer contains the literal at all. The **fixture bytes did not change** —
   both maps are empty under either key shape, so there was nothing to migrate, and
   an empty allowlist still means zero tolerance. Two behaviours changed and are
   worth carrying forward into #1342–#1345:

   * **A key the ratchet cannot parse now throws** (`OverflowRatchetFormatException`,
     from `setUpAll`, once) instead of being read as "not allowlisted". A leftover
     `card|width|tab[@profile]` key gets its own message naming the old shape. The
     pre-#1341 loader wrapped the load in `catch (e) { print(...) }`, and a printed
     warning inside a 1,898-test run is not a signal.
   * **Dead-entry detection moved from the cell to the run.** One source location
     can be rendered by many cells, so a clean cell no longer proves an entry is
     dead; the verdict is taken once in `tearDownAll` over the union of observed
     sites, and it is **suppressed entirely** when the run measured less than the
     full sweep (`LOCALE`, `MIN_SCREEN`, or a `--name` / `-c` filter, which the
     suite detects by counting declared against measured cells). What that gives up
     is granularity and timing, both stated on `OverflowRatchet.deadEntryFailure`:
     `FlutterError.onError` only ever observes overflows, so "this site rendered
     here and fitted" is unobservable, and a false "dead" verdict on a partial run
     would be strictly worse than a later true one.
5. **`test/util/app_test_fonts.dart` is shared with `test/golden_test/flutter_test_config.dart`
   deliberately**, so that both font loaders answer "how wide is this text"
   identically. Do not fork it.

---

## 6. The cell↔test mapping decision

**Decided 2026-08-20: the framework always groups by every axis except locale, and
loops locale inside one test.** The visible test count is not the figure of merit —
the usefulness of the signal is.

Rationale: locale is universally the highest-cardinality and most aggregatable
axis, and an aggregated failure (`top bar overflowed at 640px in 7 locale(s)`)
is materially easier to act on than seven separate red tests that each have to be
opened. Invariant 3 removes the isolation cost that would otherwise make this a
trade.

Measured consequences for the card sweep:

| | Today | After |
|---|---|---|
| Pumped cells in the main sweep | 1,898 | **1,898 (unchanged)** |
| Per-cell assertions (tolerance, ratchet, report row) | 1,898 | **1,898 (unchanged)** |
| `flutter test` tests, main sweep | 1,898 | 73 |
| Other tests in the same file (tab registry 18, normal-band meta 3, triband existence 2) | 23 | 23 (untouched) |
| Tests in the file | 1,921 | 96 |
| `./run_tests.sh` total | 7,260 | **5,435** |

Every figure in that table was re-measured 2026-08-21. The decomposition is exact
— 73 non-locale coordinates × exactly 26 locales, no ragged group — so this is a
clean regrouping and not a merge of unlike things, and the totals close without a
remainder: `1,898 + 23 = 1,921` today, `73 + 23 = 96` after, and
`7,260 − 1,898 + 73 = 5,435`.

**Only the last row moves with unrelated work**, and it has moved five times
already: 7,144 when this table was written, 7,200 after #1337, 7,217 after #1338,
7,221 after #1351, 7,229 after #1340, 7,260 after #1341 (§1.2). The four
rows above it are properties of the card sweep and are the ones a port is signed
off against; the gate total is a subtraction from whatever the suite measures on
the day, so #1348 must re-derive it rather than assert on the literal 5,319 the
epic's acceptance criterion still names.

The non-sweep remainder is worth naming exactly, because it is what the port must
leave alone: **18** tab-registry meta-tests (six cards asserting their tab count,
twelve asserting they are single-view), the **3** `normal band coverage`
meta-tests, and **2** triband existence checks. The mutation table is a comment,
not a test, and no data-profile test lives in this file — an earlier revision of
this table listed both and put the remainder at 24.

**The risk this creates, and the mitigation.** Visible test count falls by 96%.
After that, "deliberately regrouped" and "accidentally stopped enumerating 800
cells" look identical in the report. That is the failure mode #1321 already
demonstrated in another form: a DHCP fixture whose lease expired in 2024 turned a
red gate green and nothing said so. Hence the `test('cell count')` in §3.4 —
`family.enumerateCells().length` pinned as a literal, in the same spirit as
`dashboard_card_probe_geometry_test.dart` pinning the column mapping. **Without
that test this section's change is not safe to make.**

Cost: the card sweep loses 1,898 per-locale test names in favour of 73 group
names plus aggregated reasons. Reversible, but reverting means touching every
family again.

---

## 7. What the framework deliberately does not absorb

- **Grid geometry** (`dashboard_card_probe.dart`'s math and its monotonicity
  proof) — card-family private. Forcing a card-shaped model onto non-card
  surfaces is exactly how `OverflowReportItem` came to demand `cardId`,
  `columnSpan` and `recCols` from things that have no span.
- **The normal-band groups and the tab-registry meta-tests** (23 tests: 18 + 3 +
  2, itemised in §6) — hand-written `group`s in the card suite, not part of any
  sweep. The mutation table is a *comment* in the same file rather than a test,
  and R5 (#1348) is what keeps it honest.
- **The readability probes** (7 suites) — they keep `layout-gate` and do **not**
  get `overflow`. Their oracle is a different question ("is it still legible")
  and merging the two would blur both.

  But `onCellSettled` is a **required** parameter with no default, because a
  sweep that only checks overflow can be fully green while text is truncated to
  nothing — measured: four cards pass at 191px rendering unreadably, and the
  gate is blind to it by construction. Writing `(t, c) async {}` is allowed; not
  noticing that you did is not.

---

## 8. Scout and guard, and the `file:line` join

```
        DISCOVER (scout)                                HOLD (guard)
   golden CI · separate repo                       local · pre-commit
   26 locales × 4 devices                          tag: overflow · 30s
   advisory · has baselines                        zero tolerance · no baseline
   oracle: "same as last time"                     oracle: "always 0"
   launderable via --update-goldens                not launderable; guards new pages
            │                                                ▲
            │ overflow_warnings.json → OverflowDetail          │ graduation rule:
            │ (already carries file:line; R4 stops             │ a surface earns a probe
            │  combine_results.dart:178 flattening it)         │ only after it is at 0
            ▼                                                 │
   ┌──────────────────────────────────────────────────────────────────────────┐
   │  join key = file:line                                                    │
   │  ──────────────────────────────────────────────────────────────────       │
   │  in CI, not in the gate  → candidate for a new probe (~135 today)         │
   │  in both                 → the gate is doing its job                     │
   │  in the gate, not in CI  → the gate reaches where CI cannot (#1328's band)│
   └──────────────────────────────────────────────────────────────────────────┘
```

The two oracles are not redundant, and the difference is why both exist:

- **Overflow's correct answer is 0, always.** No reference image is needed, so it
  can guard a brand-new page, and nobody can launder it.
- **Golden's correct answer is "the same as last time."** It needs a baseline,
  which is what lets it discover territory nobody thought to probe — and also
  what lets whoever last ran `--update-goldens` bless a regression.

**The scout's two matrices are not the same, and only one of them finds anything.**
`golden_test_config.dart` defaults to `[phone480, desktop1280]` and `[Locale('en')]`,
so a golden run on a developer machine sweeps **one locale by two devices**; CI
sweeps **26 by four**. Measured 2026-08-21, the local run costs 2m13s and reports
**zero** overflow — `goldens/overflow_warnings.json` is not even created — because
every one of the ~135 coordinates that pipeline has found is locale-driven (`fr`,
`fr_CA`, `fi`). The consequence is structural, not incidental: **anything that
verifies scout output has to be verified against a CI artifact**, and the golden
side has no local baseline to capture. That is why #1337's baseline mechanism is
scoped to the four local sweeps only, and why the golden side's baseline is
#1346's problem.

Advisory is the *right* setting for the scout and the *wrong* one for the guard.
The graduation rule follows: a surface gets a local probe only after it has been
fixed to zero. Adding a probe to a surface that still carries debt would force a
second allowlist into existence, which is precisely what the empty
`known_overflows.json` exists to avoid.

---

## 9. Migration

### 9.1 Branch position, and the one conflict that is accepted

The refactor is built **on top of `fix/1314-1328-chrome-overflow`**, not on
`dev-2.7.0`. That branch already carries #1314/#1328 and the chrome sweep — R3's
second input — so stacking removes any need to merge it first, and its PR is
deliberately deferred (decided 2026-08-20).

One dependency does not dissolve. **PR #1325 is open** (`fix(dashboard): stack the
DHCP Active Leases row and declare its threshold (#1321)`, base `dev-2.7.0`) and
modifies `dashboard_card_probe.dart`, `card_data_profiles.dart` and all three card
sweeps — which is every file R3's card port rewrites. The conflict is **accepted
and deferred**: R3 lands here first, and the merge is resolved once, when #1325
goes in. Whoever resolves it should treat #1325's side as authoritative for card
data and thresholds, and this branch's side as authoritative for structure.

### 9.2 The five steps

Each is individually green. R1–R4 are the original plan; **R5 was added
2026-08-21** because R1–R4 verify only that each port matches its own baseline,
which is necessary and not sufficient (§9.3).

| Step | Content | Verification |
|---|---|---|
| **R1** | Tag swap: the old card-shaped gate tag becomes `layout-gate` on 38 files (37 when this row was written; #1337 added the 38th); add `overflow` to the sweeps; `dart_test.yaml`; `run_overflow_test.sh` consumes the tag; prose (`SKILL.md` ×10, `dashboard_density_design.md` ×5, `dashboard_framework_overflow_investigation.md` ×1, `doc/theme/unicode_glyph_coverage_decision.md` ×1, `test/golden_test/flutter_test_config.dart:9` comment). No behavioural change. | `./run_tests.sh` reports the same total as before the swap; `flutter test --tags overflow` selects the four sweeps only |
| **R2** | `test/layout_gate/` spine: merged parser (with `file:line`), `surface.dart`, `collector.dart`; old paths re-export. Then **#1351** drops the gate's own last call into the golden parser (`overflow_baseline.dart:185`). Deleting the duplicate in `overflow_diagnostics.dart` and pointing `golden_runner.dart` at the shared one — with the advisory caller opting out of the loud-failure default **explicitly**, so a future gate caller cannot inherit tolerance by omission — **moved to R4 on 2026-08-21 as #1339** (§3.5): it is verifiable only against golden-ci artifacts, and holding R2 for it would put a CI round-trip in front of R3. Revised 2026-08-21: the chrome suite *does* change here, collapsing its seven hand-copied surface blocks, because otherwise this step has no verification signal of its own. The card suites still do not. **Landed 2026-08-21** (#1338 → #1351 → #1340). | family still green; count **7,229** after all three (7,217 at #1338 — its own 17 parser tests being the whole delta from #1337's 7,200 — then +4 at #1351 and +8 at #1340), and no existing test moved; `overflow_probe_test.dart` extended for the new fields, including a real Flutter overflow whose `file:line` is asserted against the line the `Row` is written on, 3 tests pinning `toString()`, and #1340's 8-test surface group whose six mutations all have recorded killers; chrome's failure set unchanged; #1351's and #1340's swaps both verified by `./tool/overflow_baseline.sh check` exiting 0 on all four sweeps, 3,587 cells identical — **entirely local**, since the CI-artifact obligation left with #1339 |
| **R3** | `runOverflowSweep` + `OverflowSurfaceFamily`. Port **chrome first** (31 tests, no ratchet, no report — the proof, #1342), then the ratchet re-key (**#1341, landed 2026-08-21 ahead of the runner** — it is a module extraction plus a key change, and neither needs `runOverflowSweep` to exist), then the card family last because it carries ratchet, report and PNG dumps: main sweep (1,921 tests, #1343), forced-form (80, #1344), popup (354, #1345). **Four tickets, not one** — see the note below the table. | `./tool/overflow_baseline.sh check <sweep>` exits 0 against #1337's pre-port baseline — cell counts and verdicts compared by diff, not by eye; `./run_tests.sh` legitimately drops by **1,825** (`1,898 − 73`) from whatever it measures at the time — **5,435** from today's 7,260, not the epic's literal 5,319 — with `test('cell count')` pinning 1,898. #1341's own share is verified without any of that: `ratchet_test.dart` proves the allowlisted-passes / not-allowlisted-fails / dead-entry-reported triple against a string, and the card sweep's 1,921 tests and its `card` baseline are both unchanged |
| **R4** | `test_scripts/combine_results.dart:178` stops flattening the overflow sites to a boolean: report rows carry file / line / side / pixels / occurrences. `golden_runner`'s early `return` is **not** touched — the scout stays advisory. Plus **#1339**, moved here from R2: delete `overflow_diagnostics.dart`'s parser and point `golden_runner.dart` at the shared one, which is what makes both sides of the join measure the same way. Follow-up in `PrivacyGUI-golden-ci`: re-key the collector's diff on `file:line`, which lifts its ~361-issue hold. | golden report rows and gate rows join on `file:line`; grouped by the new key, #1302's 15 coordinates collapse to 5 source locations and admin's 120 to 1 — verified against a **CI artifact**, since a local run has no rows to group (see the note below); and every difference #1339 makes to `overflow_warnings.json` attributed incident-by-incident to first-side → worst-side, byte-identical being unachievable there |
| **R5** | Acceptance (#1348). Part A: `./tool/overflow_baseline.sh check` exits 0 for all four sweeps against the committed baselines (`4fb1ac5e-dirty`; `chrome` `785c6f67-dirty`). Part B: every row of the card suite's existing mutation table re-run, plus one executed mutation per framework invariant — keyed subtree removed, surface teardown dropped, per-cell exception allowed to propagate, a coordinate dropped from `enumerateCells()`, tolerance at 1.9/2.1px, a dead allowlist entry, `onCellSettled` omitted, #1328's fix reverted. Part C: §1.2's cost table re-measured. | every mutation has a recorded killer; a mutation killed by *nothing* becomes its own issue rather than vanishing from the table |

The pages pilot is sequenced after R5 — not merely after R4 — so that the third
family arrives to one framework that has been proved both invariant *and* still
capable of failing. Two pages only, one cheap form page and one provider-heavy
page, both at zero beforehand per §8's graduation rule.

**R3 is four tickets** (#1341–#1345), not the one step the table's single row
suggests. The two secondary card files are not one sweep each: the forced-form
file holds three sweep shapes and the popup file another three, each with its own
axes and host, across ~1,050 lines. One ticket would not fit a single context
window.

**R4's golden-side halves cannot be verified on a developer machine** (added
2026-08-21; this said "R2's and R4's" until #1339 moved into R4 — the constraint
is what moved it). A full local golden run takes 2m13s and writes **no
`goldens/overflow_warnings.json` at all**, because the local default matrix is one
locale by two devices while CI runs 26 by four (§8), and every coordinate that
pipeline has found is locale-driven. So the artifact #1339 and #1346 compare has
to come from CI, and the comparison is not a plain diff for two reasons: the
merged parser reports the **worst** side where the golden copy reported the
**first**, so any multi-side incident legitimately changes; and the file is
written read-merge-append-write, so it is never truncated, its record order is
suite-completion order, and its `logIndex` is an insertion-order integer. R4 must
therefore normalise its input rather than trust it, which is a stated
precondition on #1346.

### 9.3 Why R5 exists, and one thing it must not trust

R1–R4 each verify that a port reproduces its own baseline. That is necessary and
it is not sufficient, because **the cheapest way to pass all of it is to measure
less**: a framework that quietly stops enumerating a coordinate, stops resetting
the surface, or swallows a per-cell exception will match a baseline that was
captured from the same defect. Large, green and blind are not mutually exclusive.

#1337 closes the first of those three, and part of the third. Its dataset records a
clean cell as a *row*, so a coordinate that stops being enumerated is a missing row
the diff calls out as lost coverage; and each row states whether its pump finished,
so a cell that raised before laying anything out reads as `error` rather than as a
coordinate that fits — which is the same lie one level in, and the one an
exception-swallowing port would otherwise tell for free. What it cannot see is a
surface that leaks between cells, or an exception swallowed *below* the pump while
the tree still builds: both produce a full row set with the same verdicts. Those
need an executed mutation, which is Part B.

The precedent is in this repo already. The card suite's mutation table (a comment
block in `dashboard_card_overflow_test.dart`, five rows) exists because of exactly
this. Its row 1 mutates `usp_network_health_card` so a metric row takes a fixed
`width: 140` instead of `Expanded` — a real defect — and records that the main
width sweep saw **nothing**, while 26 of 26 `network_health` tab-0 normal-band
cases caught it. The biggest sweep in the file was the blind one.

**R5 must re-derive that table's case counts rather than trust them**, because
three of them no longer reconcile with the code:

| Row | Claim | Re-measured 2026-08-21 |
|---|---|---|
| 2 | normal-band sweep goes `208 → 130` | **exact** — 208 = network_health 78 + five single-coordinate cards × 26; dropping `normalAbove` removes the 78 |
| 3 | "208 of 208 sweep cases" | **exact** |
| 5 | threshold coordinates `8 → 6` | **exact** — 3 network_health tabs + 5 single-view cards; collapsing network_health to single-view gives 6 |
| 1 | "the 1,698-case main sweep", "3,213 other cases carrying the tag" | **does not reconcile.** The main sweep is 1,898 cells (1,690 outside the normal-band groups, 1,638 also outside triband), and the whole tagged family is 3,340 tests (3,270 when this row was written, before #1337; 3,300 after #1338; measured again 2026-08-21 after #1351, #1340 and #1341) |

Rows 2, 3 and 5 are arithmetic against structures that still exist, and they are
exact. Row 1's two figures are cross-suite totals from an earlier state of the
tree, and re-running that mutation after the port will produce different numbers.
The row's *conclusion* — that the main sweep was blind to a defect a smaller group
caught — is what matters and is unaffected; the counts are not evidence any more.

---

## 10. Open questions

**Settled** — §6's cell↔test mapping (2026-08-20); the branch position with its
accepted #1325 conflict (§9.1); and, on 2026-08-21, Q2 (below), Q4 (families live
centrally under `test/layout_gate/families/`), plus one deviation agreed while
ticketing: R2 *does* touch the chrome suite, collapsing its eight hand-copied
surface blocks, because otherwise that step has no verification signal of its own.

**Still open**, each annotated with what it actually blocks:

1. **#1302's ~135 coordinates** — fixed one by one, or does an ownership table come
   first? Five source locations plus 120 admin coordinates at a single site is a
   small number of fixes and a large number of tickets. *Blocks nothing in R1–R4;
   blocks the pilot's scope.*
2. ~~**Which repo holds the golden CI pipeline**~~ — **closed 2026-08-21.** The
   consumers of `overflow_warnings.json` are all in this repo:
   `test_scripts/overflow_details.dart`, `combine_results.dart` and
   `generate_gallery_report.dart`, each already covered by
   `test/test_scripts/overflow_details_test.dart`. `linksys/PrivacyGUI-golden-ci`
   only *runs* the golden suite and reads the finished report, so R4 needs nothing
   new from it; the collector re-key is a follow-up ticket in that repo, blocked by
   R4 rather than blocking it. *Blocks nothing.*
3. **Does the skill get renamed?** `.claude/skills/dashboard-overflow-gate/` is
   card-shaped in its name and in most of its text, and its name is also the slash
   command people type. R1 rewrites its prose either way. *Blocks nothing; R1 can
   land with the directory name unchanged.*
4. ~~**Where do family implementations live**~~ — **decided 2026-08-21:**
   centrally, under `test/layout_gate/families/`, so the three families sit side by
   side and "only three differences are essential" stays checkable by reading them
   together. *Blocks nothing.*
5. **Whether `page_surface` (full pages with orchestrators) is affordable** — a
   pilot measurement, not an assumption: §1.2 shows chrome-style probes at 5ms and
   golden's full-page pumps at 170ms, and a real page could resemble either.
   *Now ticketed as #1349, gated on R5.* It is the pilot's **deliverable**, so a
   pilot concluding "too expensive — pages stay scout-only in golden CI" closes this
   question successfully; the failure mode is leaving it open, not answering it no.

### 10.1 Decisions taken unilaterally in this document

Recorded so they can be reversed cheaply now rather than discovered later.

| Decision | Where | Reversal cost |
|---|---|---|
| Tag names `layout-gate` and `overflow` | §4 | one sweep over 37 files plus prose |
| `overflow` tags the **4 sweeps only**, not the probe self-tests — the tag means "pumps cells and asserts zero overflow", not "everything a verdict depends on", which would slide back to the whole family | §4 | one line per file |
| New directory `test/layout_gate/`, parallel to `test/golden_test/` | §3.1 | a move plus a re-export update |
| `OverflowCell.coords` is `List<(String axis, String value)>` — a stringly-typed identity, chosen because the ratchet key, the test name and the report columns all need the same ordered projection | §3.2 | touches every family |
