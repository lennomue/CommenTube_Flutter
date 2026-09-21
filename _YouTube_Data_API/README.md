# CommenTube データ作成基盤

YouTube Data APIから元データを保存し、コメント候補を絞り、AIの提案を人がレビューしてからCommenTubeの正本へ移すための開発者用ツールです。AIの出力からSupabaseを直接更新しません。

## 採用する流れ

1. `collect`: `videos.list`で動画情報、`commentThreads.list`でトップレベルコメントを取得し、`data/raw/<video_id>.json`へ不変のスナップショットとして保存する。
2. 決定的な事前除外: URL、過剰な連続文字、短すぎる文、タイトル・アーティスト名の直接的な答え漏れ、重複文を除外する。高評価数は弱い補助値としてだけ使う。
3. `review-rules`: OpenAIなしでルール判定と候補コメントを一行ずつ確認できるJSON/CSVを作る。
4. `draft-openai`: OpenAI Responses APIのStructured Outputsで、候補コメント、表示タイトル、ジャンル、言語、アーティスト候補を型どおりに提案する。
5. `*.review.json`とExcel/Google Sheetsへ取り込みやすいUTF-8 BOM付き`*.review.csv`を人が確認する。事実、コメント言語、答え漏れ、同一アーティスト、既存動画、関連動画を確認する。
6. 承認済みデータだけを将来の投入コマンドでSupabaseへ追加する。現段階では投入コマンドを意図的に用意していない。

取得・選別処理の正本は`src/commentube_data/`です。途中結果は`data/raw/`の取得スナップショットと`data/generated/`のレビュー用JSON/CSVで確認できるため、旧実験Notebookは使用しません。

## セットアップ

```sh
cd /Users/lennomue/Dev/CommenTube/_YouTube_Data_API
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -e .
cp .env.example .env
```

`.env`へ実キーを保存します。`.env`、取得データ、生成データはGit対象外です。キーをDart、JSON、Notebook、`Info.plist`へ直接書かないでください。

```dotenv
YOUTUBE_API_KEY=...
OPENAI_API_KEY=...
OPENAI_MODEL=利用可能なモデルID
```

ChatGPT Plusの契約とOpenAI APIの利用・課金は別です。自動処理にはOpenAI Platformで発行したAPIキーが必要です。OpenAIを使わず、取得JSONとルール判定だけを目視確認する運用もできます。

## 実行

```sh
# 動画と最大200件のトップレベルコメントを保存
commentube-data collect y2bVIBwpCTA --max-comments 200

# OpenAIなしでルール判定のレビューJSON/CSVを作成
commentube-data review-rules data/raw/y2bVIBwpCTA.json \
  --existing-quizzes ../my_test_app/assets/mock_data/quizzes.json

# OpenAIで型付きのレビュー草案を作成
commentube-data draft-openai data/raw/y2bVIBwpCTA.json

# 既存クイズのタイトル・キーワードから重複/関連候補を先に絞る場合
commentube-data draft-openai data/raw/y2bVIBwpCTA.json \
  --existing-quizzes ../my_test_app/assets/mock_data/quizzes.json

# Jev実験用の入力だけを作る（外部送信はしない）
commentube-data prepare-jev data/raw/y2bVIBwpCTA.json

# ネットワーク不要のテスト
python -m unittest discover -s tests
```

## 人が確認する項目

- `status`を`approved`へ変える前に、動画IDが正解動画そのものであることを確認する。
- サムネイル先頭コメントが初見で有効なヒントになり、曲名・動画名・アーティスト名を直接漏らさないことを確認する。
- 日本語動画に日本語候補があるのに、英語コメントだけへ偏っていないか確認する。
- チャンネル名を機械的にアーティスト扱いしない。MAD制作者など、動画へ十分寄与した投稿者だけを登録する。
- `artist_id`の自動生成値は新規候補用である。既存アーティストと同一なら、既存IDへ差し替える。
- `same_music`、`seriese`、`cover`、`part_of`はAIに確定させず、既存動画候補と内容を人が確認して`videos_junction`へ追加する。
- 歌詞はモデルに生成させない。権利と原文を確認した人が別工程で入力する。

## Jevを使う場合

Jevは生成モデルの代替として全項目を作らせるのではなく、コメントごとの「動画固有性」「記憶に残る度合い」「答え漏れ」「ノイズ」を高速に採点する実験枠に限定します。`prepare-jev`が作るJSONは入力と基準を監査でき、Jevが利用できなくてもルール + OpenAIまたは完全な手作業へ戻せます。

Jevは公開直後のearly access段階なので、現在はSDK/APIへ自動送信しません。実アクセス、価格、モデルID、SDKインターフェースを確認してから、`EditorialSelector`とは別の`CommentRanker`実装として接続します。タイトル・アーティスト・関連動画などの事実生成には使いません。

## ディレクトリ

```text
data/raw/        YouTube取得スナップショット（Git対象外）
data/generated/  AI/Jev候補とレビュー用CSV（Git対象外）
prompts/         バージョン管理する選別基準
src/             再現可能な取得・選別・出力コード
tests/           APIキー不要のルールテスト
```

Google Sheetsを使う場合は、まず`review.csv`を手動インポートする運用から始めます。サービスアカウントに編集権限を与える自動連携は秘密鍵管理と誤更新の範囲が増えるため、レビュー列と運用が固まった後に追加します。
