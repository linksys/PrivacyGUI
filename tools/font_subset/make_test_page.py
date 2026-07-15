#!/usr/bin/env python3
"""Generate a self-contained HTML page that renders real interface strings using
the subset woff2 fonts, so a human can eyeball glyph correctness / missing chars.

Output: out/test_render.html  (open in a browser)
Each language block uses its own subset font (approach ①, glyph-correct).
"""
import base64
import json
import re
from pathlib import Path

PH = re.compile(r"\{[^{}]*\}")
OUT = Path(__file__).parent / "out"

# (label, arb file, subset woff2, how many sample strings)
LANGS = [
    ("简体中文 (zh)", "app_zh.arb", "NotoSansCJKsc.subset.woff2"),
    ("繁體中文 (zh_TW)", "app_zh_TW.arb", "NotoSansCJKtc.subset.woff2"),
    ("日本語 (ja)", "app_ja.arb", "NotoSansCJKjp.subset.woff2"),
    ("한국어 (ko)", "app_ko.arb", "NotoSansCJKkr.subset.woff2"),
]
L10N = Path("lib/l10n")


def sample_strings(arb: Path, n: int = 25) -> list[str]:
    d = json.loads(arb.read_text(encoding="utf-8"))
    out = []
    for k, v in d.items():
        if k.startswith("@") or not isinstance(v, str):
            continue
        s = PH.sub("…", v).strip()
        if s and any(ord(c) >= 0x2E80 for c in s):  # has CJK
            out.append(s)
        if len(out) >= n:
            break
    return out


def b64_font(path: Path) -> str:
    return base64.b64encode(path.read_bytes()).decode("ascii")


def main() -> int:
    blocks = []
    faces = []
    for i, (label, arb_name, woff_name) in enumerate(LANGS):
        woff = OUT / woff_name
        if not woff.exists():
            print(f"WARN: {woff} missing, run subset_fonts.sh first")
            continue
        fam = f"Subset{i}"
        faces.append(
            f"@font-face{{font-family:'{fam}';"
            f"src:url(data:font/woff2;base64,{b64_font(woff)}) format('woff2');}}"
        )
        samples = sample_strings(L10N / arb_name)
        size_kb = woff.stat().st_size / 1024
        rows = "".join(f"<li>{s}</li>" for s in samples)
        blocks.append(
            f"<section style=\"font-family:'{fam}',sans-serif\">"
            f"<h2>{label} <small>— {woff_name} ({size_kb:.0f} KB)</small></h2>"
            f"<ul>{rows}</ul></section>"
        )

    html = (
        "<!doctype html><html><head><meta charset='utf-8'>"
        "<title>CJK Subset Render Test</title><style>"
        + "".join(faces)
        + "body{max-width:820px;margin:2rem auto;padding:0 1rem;line-height:1.7}"
        "h1{font-family:system-ui}section{margin:2rem 0;border-top:1px solid #ccc;padding-top:1rem}"
        "small{color:#888;font-weight:normal}li{margin:.2rem 0}"
        "</style></head><body>"
        "<h1 style='font-family:system-ui'>CJK Subset 渲染驗證</h1>"
        "<p style='font-family:system-ui;color:#555'>每區塊用該語言的 subset 字體渲染真實介面字串。"
        "檢查：① 有無豆腐字 □（缺字）② 字形是否符合該語言標準（日文漢字不應中國化等）。</p>"
        + "".join(blocks)
        + "</body></html>"
    )
    out_path = OUT / "test_render.html"
    out_path.write_text(html, encoding="utf-8")
    print(f"Wrote {out_path} ({out_path.stat().st_size/1024:.0f} KB)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
