#!/usr/bin/env bash
# Zenn の記事リポジトリに tech-article の前提を入れる。記事リポジトリの中で実行する。
#   usage: setup-repo.sh
# やること:
#   .claude/hooks/guard-published.py   AI が published: true を書くのを止める hook（README 参照）
#   .claude/settings.json              上の hook の登録（既存の設定は残す）
#   .claude/launch.json                内蔵ブラウザ用の zenn-preview（無いときだけ）
#   package.json                       scripts.preview と scripts.check（無いときだけ）
#   .gitignore                         work/*/research/sources/（資料集めが落とす原文。大きい）
#   work/                              執筆メモの置き場
set -euo pipefail

self="$(python3 -I -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$0")"
skill="$(cd "$(dirname "$self")/.." && pwd)"
root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

if [[ ! -f "$root/package.json" ]] || ! grep -q '"zenn-cli"' "$root/package.json"; then
  echo "zenn-cli が package.json に無い: $root" >&2
  echo "先に Zenn のリポジトリを作る:  npm init -y && npm install -D zenn-cli && npx zenn init" >&2
  exit 1
fi

put() { # <src> <dst>  無いときだけ置く
  if [[ -e "$2" ]]; then echo "  keep  ${2#$root/}（すでにある）"; else mkdir -p "$(dirname "$2")"; cp "$1" "$2"; echo "  add   ${2#$root/}"; fi
}

echo "setup: $root"
mkdir -p "$root/.claude/hooks" "$root/work" "$root/articles" "$root/images"
cp "$skill/hooks/guard-published.py" "$root/.claude/hooks/guard-published.py"
echo "  add   .claude/hooks/guard-published.py"
put "$skill/config/launch.json" "$root/.claude/launch.json"
[[ -e "$root/work/.gitkeep" ]] || touch "$root/work/.gitkeep"

# settings.json: hooks.PreToolUse に guard-published を足す（既存の設定は残す）
python3 -I - "$root/.claude/settings.json" <<'PY'
import json, pathlib, sys
p = pathlib.Path(sys.argv[1])
s = json.loads(p.read_text()) if p.exists() else {}
cmd = 'python3 -I "$CLAUDE_PROJECT_DIR/.claude/hooks/guard-published.py"'
entry = {"matcher": "Write|Edit|MultiEdit|Bash", "hooks": [{"type": "command", "command": cmd}]}
pre = s.setdefault("hooks", {}).setdefault("PreToolUse", [])
if any(cmd in h.get("command", "") for e in pre for h in e.get("hooks", [])):
    print("  keep  .claude/settings.json（hook は登録済み）")
else:
    pre.append(entry)
    p.write_text(json.dumps(s, ensure_ascii=False, indent=2) + "\n")
    print("  edit  .claude/settings.json（hooks.PreToolUse に guard-published を追加）")
PY

# package.json: scripts.preview / scripts.check（無いときだけ）
python3 -I - "$root/package.json" "$skill/scripts/check-article.sh" <<'PY'
import json, pathlib, sys
p = pathlib.Path(sys.argv[1]); check = sys.argv[2].replace(str(pathlib.Path.home()), "$HOME", 1)
s = json.loads(p.read_text()); sc = s.setdefault("scripts", {}); changed = []
for k, v in (("preview", "zenn preview --port 8000"), ("check", f'bash "{check}"')):
    if k not in sc:
        sc[k] = v; changed.append(k)
if changed:
    p.write_text(json.dumps(s, ensure_ascii=False, indent=2) + "\n")
    print(f"  edit  package.json（scripts: {', '.join(changed)}）")
else:
    print("  keep  package.json（scripts.preview / scripts.check はある）")
PY

# .gitignore
gi="$root/.gitignore"
if [[ ! -f "$gi" ]] || ! grep -qx 'work/\*/research/sources/' "$gi"; then
  printf '\n# 資料集めが落とす原文（大きいので追跡しない）\nwork/*/research/sources/\n' >> "$gi"
  echo "  edit  .gitignore（work/*/research/sources/）"
else
  echo "  keep  .gitignore"
fi

echo
echo "できた。Claude Code をこのリポジトリで開き直し、/tech-article で始める。"
