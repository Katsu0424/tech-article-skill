#!/usr/bin/env python3
"""PreToolUse hook: AI が記事を published: true にするのを禁止する。

Claude Code は Write / Edit / MultiEdit / Bash の実行前に、この script へ
tool_name と tool_input を JSON で stdin に渡す。exit 2 で呼び出しを止め、
stderr の文面がモデルに返る。

守りたいこと:
  - articles/*.md の frontmatter に published: true を書かない
  - Bash 経由（sed / echo / heredoc）でも同じ文字列を流し込まない
公開は人が frontmatter を手で変えてから push する。
"""
import json
import re
import sys

PUBLISHED_TRUE = re.compile(r"""published\s*:\s*["']?true\b""", re.IGNORECASE)
ARTICLE_PATH = re.compile(r"(^|/)articles/[^/]+\.md$")


def block(reason: str) -> None:
    sys.stderr.write(
        "guard-published: blocked. "
        + reason
        + " 記事は published: false のままにする。公開は著者が手で行う。\n"
    )
    sys.exit(2)


def main() -> None:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return  # 解析できない入力は素通し（hook の不具合で作業を止めない）

    tool = payload.get("tool_name", "")
    inp = payload.get("tool_input", {}) or {}

    if tool == "Bash":
        cmd = inp.get("command", "") or ""
        if PUBLISHED_TRUE.search(cmd):
            block("コマンドに published: true が含まれる。")
        return

    if tool in ("Write", "Edit", "MultiEdit"):
        path = inp.get("file_path", "") or ""
        if not ARTICLE_PATH.search(path):
            return
        texts = []
        if tool == "Write":
            texts.append(inp.get("content", "") or "")
        elif tool == "Edit":
            texts.append(inp.get("new_string", "") or "")
        else:
            for e in inp.get("edits", []) or []:
                texts.append(e.get("new_string", "") or "")
        for t in texts:
            if PUBLISHED_TRUE.search(t):
                block(f"{path} に published: true を書こうとした。")


if __name__ == "__main__":
    main()
