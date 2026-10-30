# SEO 調査: ラッコキーワード MCP の手順

フェーズ 4 でラッコキーワード MCP（`mcp__…__search-volume-history` など）が使えるときの手順。
連携の手順は https://rakkokeyword.com/knowledge/10753/ 。MCP 経由はスタンダードプランで 1.5 倍のクレジットを消費する。
反映先はタイトル・見出し・topics の 3 か所だけ。本文の文は変えない。

1. `account-info` で残クレジットを見る
2. 元語を 10〜15 語（brief の読者・テーマ・固有名詞・困りごとの語「来ない／反応しない」・説明の語「とは／仕組み」）。サジェストは Google サジェスト API（無料）か `suggest-keywords`（1.5）で集める
3. **月間検索数**: `search-volume-history` に集めた語を**全部 1 リクエスト**で渡す（最低 15 クレジット。`seoDifficulty` はオフ）。`search-volume-history-status` で完了を待ち、`search-volume-history-results` を `noiseReduction: false` で取る。null は「10 未満か未収録」で、ゼロと断定しない
4. 検索数の立つ上位 3〜4 語に `headline`（3）と `co-occurrence`（3）。主語 1 つに `other-keywords`（22.5）と `question-search`（1.5）。`ranking-keywords` はデータが無いことがある（0 件なら諦める）
5. 読み取りを `work/<slug>/seo/rakko-serp-<日付>.md` に書く:
   - 上位 20 に無い切り口（この記事の差になる）
   - 上位に共通する見出し
   - 本文に出にくい共起語
   - 検索意図が記事とずれる語（使わない）
   - 困りごとの語の検索数（null ならタイトルに入れない）
   - 「とは」需要（見出しか用語表で受ける）
6. タイトル 3 案（主語 2 つを先頭 32 字に。Zenn の上限 70 字）・見出しの語の案（構成は変えない）・topics 案（`https://zenn.dev/topics/<topic>` が 200 のものだけ）を出し、著者が選ぶ

## フェーズ 8 の SEO 判定で見るもの

フェーズ 4 の数字を根拠に、記事の形は変えない。

- タイトルの先頭 32 字に主語 2 つ・70 字以内
- H2・H3 に検索数のある語
- 冒頭 2 文に主語の語（Zenn の meta description は定型なので、Google は本文から抜く）
- topics の topic ページが 200
- 本文に無い主要な共起語

結果と「形を変えずにできる案」を `seo/seo-review-<日付>.md` に書き、著者が選んだ分だけ反映する。
