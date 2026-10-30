#!/usr/bin/env bash
# 新しい記事の骨組みを作る。
#   usage: new-article.sh <slug> ["タイトル"]
# slug は a-z 0-9 - _ の 12〜50 文字（Zenn の規約）。
set -euo pipefail

slug="${1:-}"
title="${2:-}"
if [[ -z "$slug" ]]; then
  echo "usage: new-article.sh <slug> [title]" >&2
  exit 1
fi
if ! [[ "$slug" =~ ^[a-z0-9_-]{12,50}$ ]]; then
  echo "slug は a-z 0-9 - _ の 12〜50 文字: $slug" >&2
  exit 1
fi

# 記事リポジトリ = 実行したディレクトリの git ルート。skill の置き場には依存しない
self="$(python3 -I -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$0")"
root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
if [[ ! -d "$root/articles" ]]; then
  echo "articles/ が無い: $root（Zenn の記事リポジトリの中で実行する）" >&2
  exit 1
fi
tpl="$(dirname "$self")/../templates"
article="$root/articles/$slug.md"
work="$root/work/$slug"

if [[ -e "$article" ]]; then
  echo "すでにある: $article" >&2
  exit 1
fi

mkdir -p "$root/articles" "$root/images/$slug" "$work"
sed "s|<slug>|$slug|g" "$tpl/article.md" > "$article"
if [[ -n "$title" ]]; then
  # title: "" の行だけ差し替える
  python3 -I - "$article" "$title" <<'PY'
import sys, pathlib
p = pathlib.Path(sys.argv[1]); t = sys.argv[2].replace('"', '\\"')
p.write_text(p.read_text().replace('title: ""', f'title: "{t}"', 1))
PY
fi
for f in brief outline captures status; do
  sed "s|<slug>|$slug|g" "$tpl/$f.md" > "$work/$f.md"
done
touch "$root/images/$slug/.gitkeep"

echo "作成した:"
echo "  $article"
echo "  $work/{brief,outline,captures,status}.md"
echo "  $root/images/$slug/"
