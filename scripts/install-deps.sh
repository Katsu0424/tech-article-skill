#!/usr/bin/env bash
# tech-article が呼ぶ skill を ~/.claude/skills に入れる。
#   usage: install-deps.sh [--force]
# 入れるもの（出どころは README.md）:
#   grill-me                      mattpocock/skills
#   imozuru                       MaryCache/imozuru
#   yomiyasu                      nanaism/yomiyasu
#   tech-article-reproducibility  mizchi/skills
# どれも無くても tech-article は動く（該当フェーズを縮めて進む）。
set -euo pipefail

dest="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
force=0
[[ "${1:-}" == "--force" ]] && force=1

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$dest"

# clone 1 回につき 1 リポジトリ。同じリポジトリから複数の skill を取るので、clone はキャッシュする
clone() { # <owner/repo>
  local dir="$tmp/${1//\//__}"
  if [[ ! -d "$dir" ]]; then
    echo "clone: https://github.com/$1" >&2
    git clone -q --depth 1 "https://github.com/$1.git" "$dir" >&2
  fi
  echo "$dir"
}

install_skill() { # <owner/repo> <skill名>
  local repo="$1" name="$2" src target="$dest/$2"
  if [[ -e "$target" && $force -eq 0 ]]; then
    echo "  skip  $name（すでにある: $target。入れ直すなら --force）"
    return
  fi
  src="$(find "$(clone "$repo")" -type d -name "$name" -not -path '*/.git/*' | head -1)"
  if [[ -z "$src" || ! -f "$src/SKILL.md" ]]; then
    echo "  NG    $name: $repo に SKILL.md 付きの $name が見つからない" >&2
    return 1
  fi
  rm -rf "$target"
  cp -R "$src" "$target"
  echo "  ok    $name  <- $repo"
}

echo "install to: $dest"
install_skill mattpocock/skills grill-me
install_skill MaryCache/imozuru imozuru
install_skill nanaism/yomiyasu yomiyasu
install_skill mizchi/skills tech-article-reproducibility
echo
echo "入った。Claude Code を立ち上げ直すと /grill-me /imozuru /yomiyasu /tech-article-reproducibility が使える。"
