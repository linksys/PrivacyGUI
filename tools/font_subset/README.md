# Fallback font subsetting (offline CJK)

Build-time tool that generates the bundled **CJK subset fonts** used for
offline rendering. The app must work with **no network** (router firmware), so
every glyph the interface can show must ship in the product. Full Noto Sans CJK
is ~12.7 MB; subsetting to just the glyphs the interface uses brings the 5 CJK
fonts down to **~2.1 MB (84% smaller)** while keeping every language's glyph
shapes correct.

Architecture overview and rationale:
[raw/offline_font_bundle_size_options.md](../../../Documents/docs/raw/offline_font_bundle_size_options.md)
(Obsidian vault) — or ask; it documents the full A+ design.

## ⚠️ When you MUST re-run this

Re-run **`regenerate.sh`** after ANY change that can introduce a new CJK / kana /
hangul glyph into interface text:

- new or edited strings in `lib/l10n/app_{zh,zh_TW,ja,ko}.arb`
- a new language name in `lib/util/languages.dart`
- a hardcoded CJK literal in Dart source under `lib/`

**If you skip it, the subset silently misses the new glyph** → online it falls
back to the CDN (a network request), **offline it renders as tofu (□)**. This is
hard to spot because most text still looks fine.

> Only the **5 CJK subsets** are regenerated. The non-CJK fallbacks
> (`NotoSansThai`, `NotoSansArabic`, `NotoSans-Latin`, `Roboto` in
> `assets/fonts/fallback/`) are FULL fonts that never change — leave them.

## Usage

```bash
bash tools/font_subset/regenerate.sh
```

One idempotent command: sets up a venv, downloads the full Noto Sans CJK OTFs
(first run only, needs net), extracts the interface charset, subsets the 5 CJK
fonts, and deploys them to `assets/fonts/fallback/`.

Then rebuild and verify no CDN requests appear for CJK text:

```bash
flutter build web --debug
# serve build/web, open a CJK locale, DevTools → Network → Font:
# should load only assets/fonts/fallback/*.woff2, zero fonts.gstatic.com
```

Optional visual check of glyph correctness:

```bash
.venv/bin/python tools/font_subset/make_test_page.py   # -> out/test_render.html
```

## Charset sources (extract_charset.py)

The interface charset is the union of:
1. translatable values in the CJK ARB files (skips `@` metadata + ICU placeholders)
2. full CJK punctuation / fullwidth / compat blocks (U+3000–303F, U+FF00–FF60, U+FE30–FE4F)
3. language picker native names in `lib/util/languages.dart`
4. hardcoded CJK literals in Dart source under `lib/` (excludes generated l10n)

Missing any of these classes was a real cause of stray CDN requests — keep all four.

## Files

- `regenerate.sh` — the one command to run (download → extract → subset → deploy).
- `extract_charset.py` — builds `out/charset.txt` from the sources above.
- `make_test_page.py` — renders sample strings per language to `out/test_render.html`.
- `.venv/`, `full_fonts/`, `out/` — reproducible intermediates, gitignored.

## Where the fonts are consumed

- Declared eager under `pubspec.yaml` `fonts:` as `packages/ui_kit_library/NotoSans*`
  (registered before first frame — this is what keeps CJK off the CDN).
- Locale→family mapping: `lib/localization/fallback_font_resolver.dart` (single
  source of truth), injected into ui_kit's `LocaleFallbackFont` at startup.
