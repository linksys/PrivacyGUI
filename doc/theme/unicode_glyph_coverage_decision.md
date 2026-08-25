# Unicode Symbols in UI Strings — Glyph Coverage Decision

**Last Updated: 2026-08-12** · Resolves #1247 · Follow-up to #1249 (`31d71e0f`) · Status: **decided and implemented**

## Purpose

The app bundles eleven fonts so that every locale renders offline, without
network and without relying on host fonts. A UI string that uses a codepoint
none of those eleven map is therefore a latent defect even when it looks
correct: the browser is resolving a font the app never declared.

This document records which codepoints are safe to put in UI strings, the
measurement behind that, and the decision taken for U+2192.

## The declared font set

Eleven fonts, all eager-loaded and registered before the first frame:

| Font | Role |
|---|---|
| `NeueHaasGrotTextRound-55Roman` / `-75Bold` | Primary (from `ui_kit_library`) |
| `NotoSans-Latin` | Greek, Cyrillic, Vietnamese (`el`/`ru`/`vi`) |
| `NotoSansCJK{sc,tc,hk,jp,kr}.subset` | CJK, per locale |
| `NotoSansThai`, `NotoSansArabic` | `th`, `ar` |
| `Roboto` | Engine's global fallback, declared bare so it resolves locally |

Two things about the chain matter for this decision:

1. **The Noto fallbacks are locale-gated.** `FallbackFontResolver`
   (`lib/localization/fallback_font_resolver.dart`) returns `null` for
   en/fr/de/es/pt and the other Latin locales. For those locales the chain is
   **NeueHaas → Roboto only** — 429 and 896 codepoints respectively. A glyph
   present only in a CJK subset does *not* rescue an English string.
2. **The CJK subsets are generated from ARB text.** `tools/font_subset/`
   subsets against the characters found in the `zh`/`zh_TW`/`ja`/`ko` ARB files
   plus ASCII and the CJK punctuation blocks. Symbols that appear only in
   hardcoded Dart literals are not in that charset even though the full source
   fonts have them.

## Measurement

Measured with fontTools against the pinned `ui_kit_library` (`v2.34.5`,
`bcee4067`) and `assets/fonts/fallback/`. `YES` = the font's `cmap` maps it.

| Codepoint | NeueHaas | Roboto | NotoSans-Latin | Thai/Arabic | CJK subsets | **Union** |
|---|---|---|---|---|---|---|
| U+2192 `→` | no | no | no | no | no | **none** |
| U+2190 `←` | no | no | no | no | no | **none** |
| U+2191 `↑` | no | no | no | no | no | **none** |
| U+2193 `↓` | no | no | no | no | no | **none** |
| U+2013 `–` | YES | YES | YES | YES | YES | **all 11** |
| U+2014 `—` | YES | YES | YES | YES | YES | **all 11** |
| U+00BB `»` | YES | YES | YES | YES | no | 6 of 11 |
| U+203A `›` | YES | YES | YES | YES | no | 6 of 11 |

The arrows resolve in every browser tested, which is why this was never visible
as a bug. That resolution comes from a system font outside the declared set —
precisely the dependency the fallbacks exist to remove.

The full Noto Sans CJK OTFs under `tools/font_subset/full_fonts/` **do** map
U+2192. Only the generated subsets drop it. This is what makes "add arrows to
the CJK subset" look viable when it is not: it would fix nothing for the Latin
locales, which is where all eight sites render.

## Decision

**U+2192 in a rendered UI string is replaced by `AppIcon.font(Icons.arrow_forward)`.**
Icon fonts ship with the app, so coverage is guaranteed offline. This extends
`31d71e0f`, which did the same for U+2191/U+2193/U+23F1/U+26A0, to the
"maps to" separator.

Chosen over two cheaper alternatives:

- **Adding the Arrows block to the CJK subsets** — the ticket's first choice —
  cannot work at all, and this is the more fundamental objection than any cost
  argument. Those subsets are only loaded for CJK locales; for en/fr/de/es/pt
  the chain is NeueHaas → Roboto only, and all eight U+2192 sites are hardcoded
  English strings with no U+2192 in any ARB file. Patching a CJK subset would
  not affect a single one of them.
- **Re-subsetting `Roboto` to add the Arrows block** is the only viable form of
  that idea — Roboto is the one fallback declared for every locale, so it would
  fix all sites with no code change. Rejected on cost, not validity:
  `tools/font_subset/regenerate.sh` regenerates only the five CJK subsets and
  treats the non-CJK fallbacks as fixed committed artifacts; adding Roboto to
  that pipeline makes a vendored binary a maintenance surface for a separator.
  Still the right move if arrow coverage is ever wanted in bulk.
- **An ASCII/en-dash separator** is zero-risk (U+2013 is in all eleven) but
  loses the direction the arrow carries, and leaves the app inconsistent with
  the icon treatment `31d71e0f` established.

### Rules

1. A rendered UI string **must not** depend on a codepoint outside the union
   above. Direction markers are drawn with `AppIcon.font`; U+2013/U+2014 are
   safe as separators.
1. **An icon standing in for a character must be given the text's colour
   explicitly.** `AppText` resolves colour from `DefaultTextStyle`; `AppIcon`
   falls back to `IconTheme.of(context).color ?? Colors.black`. Containers set
   one or the other, not both — `AppListTile` wraps its subtitle in a
   `DefaultTextStyle` at 0.7 alpha and no `IconTheme` — so an icon left to its
   own chain diverges from the text beside it. Resolve once
   (`color ?? DefaultTextStyle.of(context).style.color`) and pass it to both.
2. **Logger, console and LLM-prompt strings are out of scope.** They never pass
   through Flutter's font stack. `lib/ai/prompts/` and `[USP]`-prefixed log
   strings keep their arrows deliberately.
3. Anything added to `lib/util/languages.dart` or the CJK ARB files needs
   `tools/font_subset/regenerate.sh` re-run, per that script's header.

## Implementation

`MapsToRow` (`lib/page/_shared/components/layout_blocks/row_blocks.dart`) is the
single definition of the arrow: it takes `source` and `target` as **Strings** and
composes `AppText + AppIcon.font + AppText`.

This keeps `PortForwardingRuleUIModel.portSummary` and
`PortTriggeringRuleUIModel.summary` returning Strings — #1247 AC #3 — rather
than pushing widgets into UI models. Each model gained getters for the two
halves (`portRangeDisplay`/`internalTargetDisplay`,
`triggerSummaryPart`/`forwardSummaryPart`); the composed `…summary` getters
remain for diagnostics and now use ASCII `->`.

`ToggleRow` gained `subtitleContent` (a `Widget?`) alongside its String
`subtitle`, because two of the sites are `ToggleRow` subtitles. The two are
mutually exclusive and asserted as such; existing String callers are unaffected.

**One deliberate visual change.** `usp_firewall_overview_card.dart:255` read
`'${rule.portSummary} → ${rule.internalClient}'`, rendering
`8080 → 192.168.1.100:80 → 192.168.1.100` — the internal client twice, once
bare and once inside `portSummary`. It is now a single
`8080 → 192.168.1.100:80`. Preserving both arrows would have drawn two icons
for duplicate information.

### Sites converted

| File | Note |
|---|---|
| `lib/page/_shared/models/port_forwarding_rule_ui_model.dart` | getter split; `portSummary` → ASCII |
| `lib/page/port_forwarding/models/port_triggering_rule_ui_model.dart` | getter split; `summary` → ASCII |
| `lib/page/statistics/views/sections/stats_port_mapping_section.dart` | `MapsToRow` |
| `lib/page/firewall/cards/usp_firewall_overview_card.dart` | `MapsToRow`; duplicate arrow collapsed |
| `lib/page/port_forwarding/cards/usp_port_forwarding_card.dart` | two `ToggleRow` subtitles |
| `lib/page/port_forwarding/views/components/usp_{single_port,port_range,port_triggering}_tab.dart` | `MapsToRow` |
| `lib/ai/registry/router_component_registry.dart` | three `AppListTile` subtitles |
| `lib/demo/pages/pnp_demo_launcher.dart` | en dash — a three-step sequence, not a mapping |

## Verification

- `test/page/_shared/components/layout_blocks/maps_to_row_test.dart` asserts no
  rendered `Text` contains U+2192, that the arrow is an `Icon`, and that long
  operands ellipsize without overflow. Tagged `layout-gate` (not `ui`) so
  `run_tests.sh` includes it. Mutation-checked: reverting `MapsToRow` to a
  character arrow fails 3 of its 5 tests.
- `test/page/_shared/components/layout_blocks/toggle_row_test.dart` covers the
  two `ToggleRow` subtitle channels, that passing both asserts, and that the
  arrow icon matches the colour of the text beside it. Mutation-checked:
  dropping the `DefaultTextStyle` fallback makes the icon render at alpha 1.0
  against text at 0.7, and the colour test fails.
- `./run_tests.sh` — 5352 passing.
- `dashboard_card_overflow_test.dart` — 1644 passing, allowlist unchanged.
  Both `port_forwarding` and `firewall_overview` are gate-probed, and the icon
  is narrower than the glyph box it replaced, so no coordinate moved.

## Reproducing the measurement

Run from the repo root. `LinksysIcons.otf` is excluded on purpose: it is the
icon font `AppIcon.font` draws from, not part of the *text* fallback chain, so
counting it would mask exactly the gap being measured.

```bash
python3 -m venv /tmp/fc && /tmp/fc/bin/pip install -q fonttools brotli
/tmp/fc/bin/python - <<'PY'
from fontTools.ttLib import TTFont
import glob, os
paths = glob.glob('assets/fonts/fallback/*.woff2') + [
    p for p in glob.glob(os.path.expanduser(
        '~/.pub-cache/git/privacyGUI-UI-kit-bcee4067*/assets/fonts/*.otf'))
    if 'LinksysIcons' not in p]
assert len(paths) == 11, f'expected 11 text fonts, found {len(paths)}'
union = set()
for p in paths:
    f = TTFont(p, fontNumber=0, lazy=True)
    union |= set(f.getBestCmap()); f.close()
for cp in (0x2192, 0x2013):
    print(hex(cp), 'covered' if cp in union else 'MISSING')
PY
```

Expected: `0x2192 MISSING`, `0x2013 covered`. Bump the `bcee4067` glob when
`ui_kit_library` is repinned in `pubspec.lock`.
