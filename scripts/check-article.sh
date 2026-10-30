#!/usr/bin/env bash
# 公開前チェック。
#   usage: check-article.sh <slug>
# 見るもの: frontmatter（published: false・title・topics）、画像の実在、TODO の残り、slug の形。
set -uo pipefail

slug="${1:-}"
if [[ -z "$slug" ]]; then
  echo "usage: check-article.sh <slug>" >&2
  exit 1
fi
# 記事リポジトリ = 実行したディレクトリの git ルート。skill の置き場には依存しない
root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
if [[ ! -d "$root/articles" ]]; then
  echo "articles/ が無い: $root（Zenn の記事リポジトリの中で実行する）" >&2
  exit 1
fi
article="$root/articles/$slug.md"
ng=0
ok() { echo "  ok   $1"; }
bad() { echo "  NG   $1"; ng=$((ng + 1)); }

echo "check: $article"
[[ -f "$article" ]] || { bad "記事が無い"; exit 1; }

# slug
if [[ "$slug" =~ ^[a-z0-9_-]{12,50}$ ]]; then ok "slug の形"; else bad "slug は a-z 0-9 - _ の 12〜50 文字"; fi

# frontmatter
fm="$(awk 'NR==1 && $0!="---"{exit} NR>1 && $0=="---"{exit} NR>1{print}' "$article")"
if grep -qE '^published:[[:space:]]*false' <<<"$fm"; then ok "published: false"; else bad "published: false になっていない（公開は著者が手で変える）"; fi
if grep -qE '^title:[[:space:]]*"[^"]+"' <<<"$fm"; then ok "title"; else bad "title が空"; fi
if grep -qE '^topics:[[:space:]]*\[[^]]+\]' <<<"$fm"; then ok "topics"; else bad "topics が空（最大 5 つ）"; fi
if grep -qE '^type:[[:space:]]*"(tech|idea)"' <<<"$fm"; then ok "type"; else bad "type は tech か idea"; fi

# 画像の実在
missing=0
while IFS= read -r img; do
  [[ -z "$img" ]] && continue
  if [[ ! -f "$root$img" ]]; then echo "       無い画像: $img"; missing=$((missing + 1)); fi
done < <(grep -oE '\]\(/images/[^) ]+' "$article" | sed 's/^](//')
if [[ $missing -eq 0 ]]; then ok "画像が全部ある"; else bad "画像が $missing 枚無い"; fi

# TODO / 要確認 の残り
if grep -nE 'TODO|要確認|<!--' "$article" | grep -vE '^[0-9]+:<!-- この記事の構成は' >/dev/null; then
  bad "TODO・要確認・コメントが残っている:"
  grep -nE 'TODO|要確認|<!--' "$article" | grep -vE '^[0-9]+:<!-- この記事の構成は' | sed 's/^/       /'
else
  ok "TODO が残っていない"
fi

# 節ごとに図・コード・出力があるか（目安）
sections=$(grep -cE '^## ' "$article")
blocks=$(grep -cE '^```|^!\[' "$article")
echo "  info 節 $sections / コードブロック+画像 $blocks（1節に1つ以上が目安）"

echo
if [[ $ng -eq 0 ]]; then
  echo "すべて通った。次は npm run preview で表示を確認する。"
else
  echo "$ng 件直す。"
  exit 1
fi
