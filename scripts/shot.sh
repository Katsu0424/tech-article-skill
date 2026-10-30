#!/usr/bin/env bash
# ローカルの Web 画面を headless Chrome で撮る。
#   usage: shot.sh <url> <out.png> [width] [height]
# 例:   shot.sh http://localhost:3000/ images/my-slug/02-top.png 1280 800
set -euo pipefail

url="${1:-}"; out="${2:-}"; w="${3:-1280}"; h="${4:-800}"
if [[ -z "$url" || -z "$out" ]]; then
  echo "usage: shot.sh <url> <out.png> [width] [height]" >&2
  exit 1
fi

chrome="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
if [[ ! -x "$chrome" ]]; then
  echo "Google Chrome が見つからない。ブラウザツールでスクリーンショットを撮るか、著者に撮ってもらう" >&2
  exit 1
fi

mkdir -p "$(dirname "$out")"
# 普段使いの Chrome と衝突しないよう、プロファイルとクラッシュ記録は一時ディレクトリに置く
tmp="${TMPDIR:-/tmp}/tech-article-shot"
mkdir -p "$tmp/profile" "$tmp/crash"
"$chrome" --headless=new --disable-gpu --hide-scrollbars --no-first-run \
  --user-data-dir="$tmp/profile" --crash-dumps-dir="$tmp/crash" --disable-crashpad \
  --window-size="${w},${h}" --screenshot="$out" "$url" 2>"$tmp/chrome.log" || true
if [[ -s "$out" ]]; then
  echo "saved: $out"
else
  echo "撮れなかった。$tmp/chrome.log を見る。サンドボックス内なら、ブラウザツールで撮るか著者に頼む" >&2
  exit 1
fi
