# tech-article

Zenn の技術記事を、著者が主体で書き上げるための Claude Code skill。

**AI Slop な記事は書かない。事実を根拠として、自分で確かめながら書く。**

記事の文は「著者が言ったこと」「モデルが実際に実行して得た結果」「原典からの引用」の 3 つからしか来ない。モデルは聞き手・整形役・コマンド実行役・校正役で、著者が言っていない主張を本文に足さない。記事は常に `published: false` で、公開は著者が手でやる（hook で `published: true` の直接的な書き込みを抑止する）。

## 流れ

| # | フェーズ | やること | 要るもの |
|---|---|---|---|
| 1 | 深掘り | 質問バンクを 1 問ずつ聞き、`work/<slug>/brief.md` に事実だけを集める | — |
| 2 | 構成 | 節ごとに「置くもの（図・コード・出力）」と「要る主張」を決める | — |
| 3 | 資料集め（任意） | 要る主張の原典と解説を集める | `/imozuru`（無ければ WebSearch） |
| 4 | SEO 調査（任意） | 検索数と上位ページを引き、タイトル・見出し・topics の案を出す。本文は変えない | ラッコキーワード MCP（無ければサジェストのみ） |
| 5 | 執筆 | 節ごとに 著者が口述 → モデルが整形 → プレビューで確認 | `npm run preview` |
| 6 | 日本語校正 | before / after で見せ、著者が OK した分だけ直す | `/natural-writing-ja`（無ければ style-notes のみ） |
| 7 | 再現性評価（任意） | 初見の読者役のサブエージェントに再現させ、詰まり所を直す | `/tech-article-reproducibility`（無ければ代替） |
| 8 | 公開前チェック | `npm run check`・プレビュー通し見。公開は著者が手で | — |

途中で止めても `work/<slug>/status.md` から再開できる。詳細は [SKILL.md](SKILL.md)。

## 前提

- Claude Code（CLI か Desktop app）
- Node.js と [zenn-cli](https://zenn.dev/zenn/articles/zenn-cli-guide)（記事リポジトリ側）
- Python 3（hook とスクリプトで使う）
- 任意: Google Chrome（`scripts/shot.sh` でローカルの Web 画面を撮るときだけ）

## 導入

### 1. skill を入れる

```bash
git clone https://github.com/Katsu0424/tech-article-skill.git ~/.claude/skills/tech-article
```

### 2. 依存 skill を入れる（任意だが推奨）

```bash
bash ~/.claude/skills/tech-article/scripts/install-deps.sh
```

`~/.claude/skills/` に次の skill を clone して置く。無くても tech-article は動く（該当フェーズを縮めて進む）。

| skill | 使うフェーズ | 出どころ |
|---|---|---|
| grill-me | 1. 深掘り（1 問ずつ聞く流儀。質問バンクはこの skill のもの） | https://github.com/mattpocock/skills |
| imozuru | 3. 資料集め（原文を要約せずに落とす） | https://github.com/MaryCache/imozuru |
| natural-writing-ja | 6. 日本語校正（機械っぽい文の検出） | https://github.com/mizchi/skills |
| tech-article-reproducibility | 7. 再現性評価（10 軸 20 点） | https://github.com/mizchi/skills |
| ai-index | natural-writing-ja の lint | https://github.com/mizchi/skills |

### 3. Zenn の記事リポジトリに前提を入れる

記事リポジトリが無ければ先に作る。

```bash
mkdir my-zenn && cd my-zenn && git init
```

```bash
npm init -y && npm install -D zenn-cli && npx zenn init
```

記事リポジトリの中で実行する。

```bash
bash ~/.claude/skills/tech-article/scripts/setup-repo.sh
```

置くもの（すでにあるものは残す）:

| パス | 何 |
|---|---|
| `.claude/hooks/guard-published.py` | `published: true` の直接的な書き込みを抑止する hook |
| `.claude/settings.json` | 上の hook の登録（`hooks/settings.example.json` と同じ内容を既存の設定に足す） |
| `.claude/launch.json` | Desktop app の内蔵ブラウザでプレビューを開くための `zenn-preview` |
| `package.json` | `npm run preview`（port 8000）と `npm run check -- <slug>` |
| `.gitignore` | `work/*/research/sources/`（資料集めが落とす原文） |
| `work/` | 執筆メモの置き場 |

## 使い方

記事リポジトリで Claude Code を開き、書きたいことを一言添えて `/tech-article` を呼ぶ。

```
/tech-article Rails の API に OpenAPI の契約テストを入れた話
```

続きは同じ呼び方で再開する。`work/<slug>/status.md` の最初の未完のフェーズから続く。

```bash
npm run preview            # http://localhost:8000 で Zenn と同じ見た目を確認
npm run check -- <slug>    # 公開前チェック（frontmatter・画像の実在・TODO の残り）
```

## 公開（人がやる）

1. `npm run check -- <slug>` が通る
2. `npm run preview` で表示を確認する
3. `articles/<slug>.md` の `published: false` を **自分の手で** `true` に変える
4. commit して push する（Zenn と GitHub 連携済みの場合）。連携していなければ本文を Zenn のエディタに貼る

hook は、Claude Code の Write / Edit による記事への書き込みや Bash コマンドに `published: true` が含まれる場合に止める補助策。`false` を `true` に置換する操作などは検出できず、公開変更を完全に防ぐものではない。公開前には著者が差分を確認する。

## 置き場（記事リポジトリ側）

```
articles/<slug>.md         記事本文（Zenn 規約。published: false 固定）
images/<slug>/NN-名前.png   画像。本文からは /images/<slug>/NN-名前.png
work/<slug>/brief.md       深掘りの結果（読者・事実・詰まった点・環境）
work/<slug>/outline.md     構成（節ごとの目的・置くもの・要る主張・参照）
work/<slug>/captures.md    必要なキャプチャの一覧と担当
work/<slug>/status.md      進み具合。再開はここから
work/<slug>/research/      資料集めの原文と地図（sources/ は git 管理外）
work/<slug>/seo/           SEO 調査の結果と判定
```

## この skill の構成

```
SKILL.md                       フロー本体
references/grill-questions.md  深掘りの質問バンク（番号順に 1 問ずつ）
references/style-notes.md      文体と見せ方の決め。指摘が出たら 1 行足して育てる
references/zenn-format.md      Zenn 記法の要点と、この skill での決め
references/seo-rakko.md        ラッコキーワード MCP を使う場合の手順
templates/                     brief / outline / captures / status / article の雛形
scripts/new-article.sh         記事と work/<slug>/ の骨組みを作る
scripts/check-article.sh       公開前チェック（npm run check の実体）
scripts/shot.sh                headless Chrome でローカルの Web 画面を撮る
scripts/install-deps.sh        依存 skill を ~/.claude/skills に入れる
scripts/setup-repo.sh          記事リポジトリに hook・launch.json・npm scripts を入れる
hooks/guard-published.py       published: true の直接的な書き込みを抑止する PreToolUse hook
hooks/settings.example.json    hook の登録例
config/launch.json             zenn-preview の設定
```

文体の決め（`references/style-notes.md`）は一人の著者の指摘から育ったものなので、チームに合わない行は消してよい。
