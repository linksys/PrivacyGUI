---
name: dashboard-overflow-gate
description: Operate and maintain the #1183 dashboard-card RenderFlex-overflow PR gate — run the sweep, read its HTML/Markdown report, edit the known_overflows.json allowlist under the ratchet rules, and onboard newly added/removed dashboard cards. Use when a dashboard-card gate test fails, when adding/removing a card or a locale, or when reading/generating the overflow report. Trigger keywords (English) - overflow test, overflow gate, RenderFlex, dashboard card test, known_overflows, allowlist, whitelist, overflow report, new dashboard card. Trigger keywords (Chinese) - 跑版測試, 溢出測試, overflow 測試, dashboard card 測試, 白名單, 新增語系, 新增卡片, 刪除卡片, 溢出報告, 生成報告, 掃描 dashboard.
---

# Dashboard Card Overflow Gate — Operate & Maintain

## Purpose

The #1183 gate is a PR-blocking widget test that catches dashboard-card layout
overflows the golden pipeline structurally misses (default-tab-only, fixed
width, not-every-card — the path the #1145 Network Health legend overflow
slipped through). It sweeps **every card × its narrowest grid width × every tab
× all 26 shipped locales** and fails if any RenderFlex overflows beyond a
baseline **allowlist** ("ratchet").

This skill is for **operating and maintaining** that gate — NOT for writing new
overflow-detection machinery. Use it to run the sweep, read its report, edit the
allowlist correctly, and keep the gate exhaustive when cards change.

## When to Use

- A `dashboard-card`-tagged test fails (locally or in CI / PR gate) and you must
  decide: real regression, new card, or a known overflow in a new locale.
- Adding or removing a card from the dashboard (`UspWidgetSpecs.all`).
- Adding/removing a tab on a tabbed card.
- Editing [test/fixtures/known_overflows.json](../../../test/fixtures/known_overflows.json)
  (allowlist / tracking notes).
- Generating or interpreting the HTML/Markdown overflow report.
- Shrinking the allowlist as part of #1183 follow-up (fixing the overflowing
  cards).

## When NOT to Use

- Writing golden/screenshot tests → use `golden-test-review`.
- Generic pre-PR checks → use `review-pr-readiness`.
- Rewriting the probe/grid-geometry engine — that is intentionally frozen to
  mirror production; changing it silently changes what the gate measures.

## Step 0: Read the Implementation (BLOCKING PREREQUISITE)

Before editing anything, read these — they are the source of truth, and detail
below may drift:

1. Gate test — [test/page/dashboard/cards/dashboard_card_overflow_test.dart](../../../test/page/dashboard/cards/dashboard_card_overflow_test.dart)
2. Allowlist fixture — [test/fixtures/known_overflows.json](../../../test/fixtures/known_overflows.json)
3. Runner — [tool/run_overflow_test.sh](../../../tool/run_overflow_test.sh)
4. Probe + grid math + tab registry — [test/util/dashboard/dashboard_card_probe.dart](../../../test/util/dashboard/dashboard_card_probe.dart)
5. Report generator (Status SSoT) — [test/util/dashboard/dashboard_overflow_report_generator.dart](../../../test/util/dashboard/dashboard_overflow_report_generator.dart)

## Architecture — Data Flow

```
UspWidgetSpecs.all ──┐  (card registry: id + min/pref/max column span)
UspWidgetFactory   ──┤→ dashboard_card_probe.dart
cardTabIndexProvider ┘     • widthCasesFor(spec): narrowest real grid px per span
                           • buildDashboardCardApp(): pumps ONE card at real
                             screen/card width, pinned tab, locale, real fonts
                           • kTabbedCardTabCounts: tabs to sweep per card
                                    │
                                    ▼
                    overflow_probe.dart  (runWithOverflowCollection)
                    hooks FlutterError.onError → collects "overflowed by Npx"
                    as OverflowIncident, forwards real errors so they still fail
                                    │
                                    ▼
        dashboard_card_overflow_test.dart  (one testWidgets PER card×width×tab×locale)
          overflow > 2px tolerance?
            ├─ in allowlist  → print "KNOWN OVERFLOW (allowlisted)", PASS
            └─ not in allowlist → FAIL with fix/allowlist instructions
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
- **Tag must stay `dashboard-card`.** `run_tests.sh` excludes `golden||loc||ui`;
  `dashboard-card` is NOT excluded, so it runs in the PR gate. Retagging it
  golden/loc/ui silently drops it from the gate.
- **`2.0px` tolerance** absorbs mac↔CI sub-pixel shaping; real clipping is many px.

## Quick Execution — `tool/run_overflow_test.sh`

Always run via `fvm flutter` (the script does). Output dir: `build/overflow_testing/`.

| Flag | Meaning | Default |
|------|---------|---------|
| `-l`, `--list` | List every registered card ID + column spans + tab count (from `UspWidgetSpecs.all`); runs nothing else | off |
| `-d`, `--dump MODE` | `0`=no output (clean PR-gate mode) · `1`=Markdown · `2`=HTML + PNG · `3`=MD+HTML+PNG | `2` |
| `-m`, `--min-screen PX` | Only test screen widths ≥ PX (fewer cases, faster) | `0` (all) |
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
# or the whole gate set:  ./run_tests.sh   (dashboard-card is NOT excluded)
```

Raw `flutter test` knobs (the script wraps these as `--dart-define`):
`DUMP=<0..3>`, `MIN_SCREEN=<px>`, `LOCALE=<tags>`, `LIST_CARDS=true`.

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
    "system_status|min|2": ["de", "es", "es_AR", "fr", "..."]
  }
}
```

Key grammar — `cardId|widthLabel|tabIndex`:

- `cardId` — a `UspWidgetSpecs.all` id (`-l` lists them).
- `widthLabel` — one of `min` / `preferred` / `max` (the card's column span whose
  narrowest grid width overflowed).
- `tabIndex` — 0-based; single-view cards are always `0`. Tabbed cards use the
  count in `kTabbedCardTabCounts`.
- Value — a JSON array of **locale tags** (`_localeTag` format: `en`, `de`,
  `es_AR`, `fr_CA`, `pt_PT`, `zh_TW`, …), OR `["*"]` meaning "overflows in all
  locales regardless of text". A hit is tolerated if the set contains the locale
  **or** contains `"*"`.

## The Ratchet — How the Gate Reacts to Edits

The allowlist only *tolerates* the exact baseline. Both directions fail:

- **New overflow** — a card/width/tab not listed, or a listed entry seen in a
  **new locale** → the test FAILS. This is the point: regressions block the PR.
- **Over-broad allowlist** — a locale listed as overflowing that no longer
  overflows does NOT auto-fail, but removing a still-overflowing locale from an
  entry fails exactly that test (proven both ways in #1183). So you cannot shrink
  the list by editing JSON alone — you must fix the layout first.

The gate's own failure message tells the operator exactly what to do:

> Fix the layout (Flexible/Expanded/maxLines/ellipsis), or if this is knowingly
> deferred, add "`<locale>`" to the `'<card>|<width>|<tab>'` entry.

## Playbooks

### A. A `dashboard-card` test failed — triage

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
4. Never retag the test or delete it to make CI pass.

### B. Edit the allowlist (defer a known overflow)

1. Confirm it's genuinely deferred (has, or needs, a tracking issue), not a
   regression you should fix now.
2. Add the locale tag to the matching `cardId|widthLabel|tabIndex` array in
   `known_overflows.json` (create the entry if absent). Use `"*"` only when it
   overflows in **every** locale (structural), verified via a full sweep of that
   card.
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
   with its tab count. The `tab registry` meta-test (`<card> still has N tabs`)
   fails if this is missing/wrong, so the sweep covers every tab.
3. Run the card's full sweep: `./tool/run_overflow_test.sh -c <new_card> -o`.
4. Fix any overflow you reasonably can; allowlist the rest per Playbook B with a
   tracking note. Goal is 0 new allowlist entries.

### D. Removing a card / tab

- Removing a card from `UspWidgetSpecs.all` → delete its `known_overflows.json`
  entries and any `tracking` note (stale keys are silently ignored, but keep the
  fixture clean).
- Changing a card's tab count → update `kTabbedCardTabCounts`; the meta-test
  enforces it. Re-baseline that card's entries.

### E. Shrink the allowlist (#1183 follow-up)

For each entry: fix the card's layout so it no longer overflows at that
width/tab/locale, then **remove** those locales (or the whole entry). Re-run
`-c <card>` — the ratchet confirms the removal is real (a premature removal fails
that exact test). This is the intended long-term direction; the baseline is debt,
not a target to grow.

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
| Using `"*"` after seeing overflow in a few locales | `"*"` means *every* locale — verify with a full-locale sweep of that card first |
| Wrong locale tag (`zh-TW`, `es-AR`) | Use `_localeTag` form with underscore: `zh_TW`, `es_AR`, `fr_CA`, `pt_PT` |
| New tabbed card, but only tab 0 gets tested | Add it to `kTabbedCardTabCounts`; the `tab registry` meta-test enforces coverage |
| Retagging the test golden/loc/ui to "organize" it | It would drop out of the PR gate — keep it `dashboard-card` |
| Multi-pumping to sweep widths/tabs in one test | Each case must be its own `testWidgets` (only the first overflow is reported per render object) |
| Editing the grid constants to change results | They mirror production geometry on purpose; changing them changes what "overflow" means |
| Removing an allowlist locale without fixing layout | The ratchet fails that exact test — fix the card first, then remove |
```
