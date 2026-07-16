#!/usr/bin/env bash
# Regenerate the bundled CJK subset fonts from the current interface charset and
# deploy them into the app (assets/fonts/fallback/).
#
# WHEN TO RUN: after ANY change to interface text that adds new CJK/kana/hangul
# glyphs — new/edited ARB strings (lib/l10n/app_{zh,zh_TW,ja,ko}.arb), new
# language names in lib/util/languages.dart, or hardcoded CJK literals in Dart
# source. If you skip this, the subset silently misses the new glyphs: online
# they fall back to the CDN, OFFLINE they render as tofu (□).
#
# One command, idempotent. Only the 5 CJK subsets are (re)generated; the
# non-CJK fallbacks (Thai/Arabic/Latin/Roboto) are FULL fonts that never change
# and are already committed under assets/fonts/fallback/.
#
# Prereq: python3. Downloads full Noto Sans CJK OTFs on first run (needs net).
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$DIR/../.." && pwd)"
VENV="$DIR/.venv"
FULL="$DIR/full_fonts"
OUT="$DIR/out"
DEPLOY="$ROOT/assets/fonts/fallback"

# 1. venv + fonttools
if [ ! -x "$VENV/bin/pyftsubset" ]; then
  echo "[1/5] creating venv + installing fonttools/brotli..."
  python3 -m venv "$VENV"
  "$VENV/bin/pip" install --quiet --upgrade pip fonttools brotli
else
  echo "[1/5] venv ready"
fi

# 2. download full Noto Sans CJK OTFs (subset source; production woff2 chunks
#    cannot be re-subsetted, the full fonts are required)
mkdir -p "$FULL"
echo "[2/5] ensuring full Noto Sans CJK OTFs..."
"$VENV/bin/python" - "$FULL" <<'PY'
import os, ssl, sys, urllib.request
outdir = sys.argv[1]
base = "https://github.com/notofonts/noto-cjk/raw/main/Sans/OTF"
targets = {
    "sc": "SimplifiedChinese/NotoSansCJKsc-Regular.otf",
    "tc": "TraditionalChinese/NotoSansCJKtc-Regular.otf",
    "hk": "TraditionalChineseHK/NotoSansCJKhk-Regular.otf",
    "jp": "Japanese/NotoSansCJKjp-Regular.otf",
    "kr": "Korean/NotoSansCJKkr-Regular.otf",
}
ctx = ssl.create_default_context()
for tag, path in targets.items():
    out = f"{outdir}/NotoSansCJK{tag}.otf"
    if os.path.exists(out) and os.path.getsize(out) > 1_000_000:
        print(f"      {tag}: cached"); continue
    req = urllib.request.Request(f"{base}/{path}", headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=180, context=ctx) as r, open(out, "wb") as f:
        f.write(r.read())
    print(f"      {tag}: downloaded {os.path.getsize(out):,} bytes")
PY

# 3. extract the interface charset
echo "[3/5] extracting interface charset..."
( cd "$ROOT" && "$VENV/bin/python" "$DIR/extract_charset.py" )

# 4. subset the 5 CJK fonts to woff2
echo "[4/5] subsetting..."
mkdir -p "$OUT"
for tag in sc tc hk jp kr; do
  "$VENV/bin/pyftsubset" "$FULL/NotoSansCJK${tag}.otf" \
    --text-file="$OUT/charset.txt" \
    --flavor=woff2 --layout-features='*' --no-hinting --desubroutinize \
    --output-file="$OUT/NotoSansCJK${tag}.subset.woff2"
done

# 5. deploy into the app
echo "[5/5] deploying to $DEPLOY..."
cp "$OUT"/NotoSansCJK{sc,tc,hk,jp,kr}.subset.woff2 "$DEPLOY/"
total=0
for tag in sc tc hk jp kr; do
  sz=$(stat -f%z "$DEPLOY/NotoSansCJK${tag}.subset.woff2")
  total=$((total + sz))
done
printf "done. 5 CJK subsets = %.2f MB deployed.\n" "$(python3 -c "print($total/1024/1024)")"
echo "Remember to rebuild the web app and verify (see README)."
