#!/usr/bin/env python3
"""Extract the set of characters actually used by the app's interface strings.

Reads the CJK-relevant ARB files, collects every character that appears in a
translatable *value* (skipping `@`-prefixed metadata keys and ICU placeholder
names), and writes them to a UTF-8 charset file for pyftsubset --text-file.

Scope note: this covers the FIXED interface strings only. User-typed content
(SSIDs, device names) is NOT covered here — that is handled at runtime by the
CDN on-demand fallback (see doc/theme/offline_font_bundle_size_options.md §A+).
"""
import json
import re
import sys
from pathlib import Path

# ARB files whose glyphs need CJK coverage. All 26 locales share the same keys,
# but only these carry CJK/kana/hangul glyphs in their values.
ARB_FILES = ["app_zh.arb", "app_zh_TW.arb", "app_ja.arb", "app_ko.arb"]

# ICU placeholder tokens like {count}, {deviceName} — strip so we don't count
# the ASCII inside braces as "content" (harmless, but keeps intent clear).
PLACEHOLDER_RE = re.compile(r"\{[^{}]*\}")


def extract_values(arb_path: Path) -> list[str]:
    data = json.loads(arb_path.read_text(encoding="utf-8"))
    values = []
    for key, val in data.items():
        if key.startswith("@"):  # metadata object or @@locale
            continue
        if not isinstance(val, str):
            continue
        values.append(PLACEHOLDER_RE.sub("", val))
    return values


def main() -> int:
    l10n_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("lib/l10n")
    out_path = Path(sys.argv[2]) if len(sys.argv) > 2 else Path(
        "tools/font_subset/out/charset.txt"
    )

    chars: set[str] = set()
    per_file: dict[str, int] = {}
    for name in ARB_FILES:
        p = l10n_dir / name
        if not p.exists():
            print(f"WARN: {p} not found, skipping", file=sys.stderr)
            continue
        before = len(chars)
        for v in extract_values(p):
            chars.update(v)
        # count only CJK-ish additions for reporting
        per_file[name] = len(chars) - before

    # (a) Language picker native names (lib/util/languages.dart): the picker
    # lists ALL languages' own names at once (简体中文, 日本語, 한국어, ไทย …),
    # so every locale's subset must contain these regardless of active locale.
    langs = Path("lib/util/languages.dart")
    if langs.exists():
        for m in re.findall(r"'name':\s*'([^']*)'", langs.read_text(encoding="utf-8")):
            chars.update(m)

    # (b) Hardcoded CJK string literals in Dart source (log/debug/labels not in
    # ARB). Scan lib/ excluding the generated l10n (already covered via ARB).
    import glob
    for f in glob.glob("lib/**/*.dart", recursive=True):
        if "/l10n/gen/" in f:
            continue
        txt = Path(f).read_text(encoding="utf-8", errors="ignore")
        for ch in txt:
            o = ord(ch)
            if 0x4E00 <= o <= 0x9FFF or 0x3040 <= o <= 0x30FF or 0xAC00 <= o <= 0xD7AF:
                chars.add(ch)

    # Always include ASCII printable + full CJK punctuation / fullwidth /
    # symbol blocks. The interface strings only reference a handful of these,
    # but the layout engine probes the whole range; anything missing falls
    # through to the CDN (fails offline). These blocks are tiny (~150 glyphs,
    # <1KB in the subset) so include them wholesale to avoid CDN dependency.
    for cp in range(0x20, 0x7F):  # ASCII printable
        chars.add(chr(cp))
    for cp in range(0x3000, 0x3040):  # CJK symbols & punctuation
        chars.add(chr(cp))
    for cp in range(0xFF00, 0xFF61):  # Fullwidth forms (punct, digits, latin)
        chars.add(chr(cp))
    for cp in range(0xFE30, 0xFE50):  # CJK compatibility forms (vertical punct)
        chars.add(chr(cp))
    chars.update("　、。「」『』（）：；？！…—～·・﹅﹆※")  # common extras

    # Report CJK/kana/hangul count specifically (the expensive glyphs).
    def is_cjk(ch: str) -> bool:
        o = ord(ch)
        return (
            0x4E00 <= o <= 0x9FFF  # CJK Unified
            or 0x3400 <= o <= 0x4DBF  # CJK Ext A
            or 0x3040 <= o <= 0x30FF  # Hiragana/Katakana
            or 0xAC00 <= o <= 0xD7AF  # Hangul syllables
        )

    cjk_count = sum(1 for c in chars if is_cjk(c))

    out_path.parent.mkdir(parents=True, exist_ok=True)
    # Sort for deterministic output (stable across runs → reproducible subset).
    out_path.write_text("".join(sorted(chars)), encoding="utf-8")

    print(f"Total unique chars written : {len(chars)}")
    print(f"  of which CJK/kana/hangul : {cjk_count}")
    print(f"Charset written to         : {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
