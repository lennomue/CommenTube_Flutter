# CommenTube データ作成基盤

YouTube Data APIから元データを保存し、コメント候補を絞り、AIの提案を人がレビューしてからCommenTubeの正本へ移すためのローカル開発者ツールです。AIの出力からSupabaseを直接更新しません。

## 現在APIを使う場所

コマンドごとに使う外部サービスは分離されています。`.env`にキーが書かれていても、対応するコマンドを実行しない限りAPIへ送信されません。

| コマンド | YouTube API | OpenAI API | Jev API | Google Sheets API |
|---|---:|---:|---:|---:|
| `collect` | 使用 | 不使用 | 不使用 | 不使用 |
| `review-rules` | 不使用 | 不使用 | 不使用 | 不使用 |
| `prepare-jev` | 不使用 | 不使用 | **不使用**。入力JSONを作るだけ | 不使用 |
| `draft-openai` | 不使用 | 使用 | 不使用 | 不使用 |
| Sheetsへの自動出力 | 不使用 | 不使用 | 不使用 | **未実装** |

したがって、現在すでに動作確認した`collect`と`review-rules`ではOpenAI APIキーもJev APIキーも使っていません。OpenAIが呼ばれるのは`draft-openai`だけです。JevへのHTTP送信コードはまだ存在しません。

## 採用する流れと件数

JSONは機械処理・再実行・監査のための正本形式です。CSVはAIへ渡すために必須なのではなく、Google Sheetsへの取り込みと人の行単位レビューを容易にする交換形式です。

1. `collect`: `videos.list`で動画情報、`commentThreads.list`で最大200件程度のトップレベルコメントを取得し、`data/raw/<video_id>.json`へ取得時点の不変スナップショットとして保存する。
2. 決定的な事前除外: URL、過剰な連続文字、短すぎる文、タイトル・アーティスト名の直接的な答え漏れ、重複文を除外し、最大40件程度の候補にする。高評価数は弱い補助値としてだけ使う。
3. `review-rules`: OpenAIなしでルール判定と候補コメントを一行ずつ確認できるJSON/CSVを作る。
4. OpenAIまたはJev: ルール通過候補を動画固有性、有用性、答え漏れ、ノイズ、言語の偏りで評価し、人が確認する短いリストを15件程度の目安まで絞る。
5. Google Sheets: 候補を1コメント1行で出力し、人が採否、順序、メモを編集する。
6. 最終採用: 人が1〜8件程度を目安に選ぶ。有効なヒントが多ければ8件を超えてもよい。`thumbnail_hint_type=comment`なら、並び順の先頭をHomeとGameで最初から見える代表コメントにする。残りはGameで開放するヒントになる。
7. 表示タイトル、ジャンル、言語、アーティスト候補等も人が確認し、承認済みデータだけを将来の投入コマンドでSupabaseへ追加する。

現在の`draft-openai`は最大5件を仮採用する実装で、Sheetsレビュー候補と最終採用の確定を分離する処理は未実装です。Sheets同期と一緒に、候補・最終採用を別フィールドとして実装します。それまでは生成JSONをSupabase投入可能な確定データとは扱いません。

Jevは事前ルール直後の全件に必須で掛けるのではなく、まず安価で再現可能な決定的ルールを通し、その後の意味的な採点へ使います。Jevは定義済みの選択・スコア・真偽判定を返す用途に向きますが、自由文の表示タイトルやアーティスト情報は生成できません。そのため次のいずれかを選べる構成にします。

- ルール → Jevでコメント採点 → 人が最終確認。タイトル等は人が入力
- ルール → OpenAIでコメントとメタ情報を提案 → 人が最終確認
- ルール → Jevで15件へ絞る → OpenAIでメタ情報を提案 → 人が最終確認

取得・選別処理の正本は`src/commentube_data/`です。途中結果は`data/raw/`の取得スナップショットと`data/generated/`のレビュー用JSON/CSVで確認できるため、旧実験Notebookは使用しません。

## セットアップ

```sh
cd /Users/lennomue/Dev/CommenTube/_YouTube_Data_API
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -e .
```

`_YouTube_Data_API/.env`をエディタで作成し、以下の必要項目だけを保存します。共有用テンプレートは置かず、必要な変数名はこのREADMEを正本とします。`.env`、取得データ、生成データはGit対象外です。キーをDart、JSON、Notebook、`Info.plist`へ直接書かないでください。

```dotenv
YOUTUBE_API_KEY=...
OPENAI_API_KEY=...
OPENAI_MODEL=利用可能なモデルID
GOOGLE_SPREADSHEET_ID=...
```

`GOOGLE_SPREADSHEET_ID`はSheets自動同期を実装した後に使います。共有URLが`https://docs.google.com/spreadsheets/d/<ID>/edit`なら`<ID>`の部分です。

OpenAI、Jev、Google Sheetsを使わない間は`YOUTUBE_API_KEY`以外の行を省略できます。作成後は`chmod 600 .env`で自分だけが読み書きできる状態にします。

ChatGPT Plusの契約とOpenAI APIの利用・課金は別です。自動処理にはOpenAI Platformで発行したAPIキーが必要です。OpenAIを使わず、取得JSONとルール判定だけを目視確認する運用もできます。

## 実行

### `commentube-data`というコマンドが使える理由

セットアップ時の`python -m pip install -e .`が、このフォルダの`pyproject.toml`を読みます。`[project.scripts]`に次の対応があるため、現在有効な仮想環境の`bin/`へ`commentube-data`というコンソールコマンドが作られます。

```toml
commentube-data = "commentube_data.cli:main"
```

コマンド本体は`src/commentube_data/cli.py`の`main()`です。`collect`、`review-rules`、`draft-openai`、`prepare-jev`は別のプログラム名ではなく、`argparse`で定義した`commentube-data`のサブコマンドです。`-e`はeditable installなので、通常はPythonソースを直すたびに再インストールする必要はありません。依存関係や`pyproject.toml`を変更した時だけ再度`python -m pip install -e .`を実行します。

仮想環境を有効化していない場合はコマンドが見つかりません。次のどちらでも同じ`main()`を実行できます。

```sh
source .venv/bin/activate
commentube-data --help

# コンソールコマンドを使わない同等の実行方法
python -m commentube_data.cli --help
```

### 各サブコマンド

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

`collect`の第1引数はYouTube動画IDです。`collect`がraw JSONを作り、残りのコマンドはそのファイルパスを第1引数として読みます。すべての出力先はカレントディレクトリではなく、このPythonプロジェクト内の`data/raw/`または`data/generated/`です。

## `commentube_data`パッケージ内のファイル

| ファイル | 役割 |
|---|---|
| `__init__.py` | `commentube_data`をPythonパッケージとして扱うための入口 |
| `cli.py` | コマンドとサブコマンドの引数を定義し、各処理を呼び分ける入口 |
| `config.py` | `.env`を読み、必要なコマンドでだけAPIキーの存在を検証する |
| `youtube_client.py` | YouTube Data APIの`videos.list`と`commentThreads.list`を呼び、`VideoSnapshot`を作る |
| `rules.py` | URL、重複、長さ、答え漏れ等の決定的な事前判定と簡易言語判定を行う |
| `selectors.py` | OpenAI Structured Outputsによる提案と、Jevへ渡すプロバイダー非依存の入力を組み立てる |
| `models.py` | raw、候補評価、AI提案、レビュー状態をPydantic型で検証する |
| `pipeline.py` | ファイル読書き、既存クイズ候補検索、レビューJSON/CSV生成をつなぐ |

依存方向はおおむね`cli.py` → `pipeline.py` / APIクライアント → `rules.py` / `selectors.py` → `models.py`です。画面アプリ側のFlutterコードからこのPythonパッケージを呼ぶことはありません。

## 人が確認する項目

- `status`を`approved`へ変える前に、動画IDが正解動画そのものであることを確認する。
- サムネイル先頭コメントが初見で有効なヒントになり、曲名・動画名・アーティスト名を直接漏らさないことを確認する。
- 日本語動画に日本語候補があるのに、英語コメントだけへ偏っていないか確認する。
- チャンネル名を機械的にアーティスト扱いしない。MAD制作者など、動画へ十分寄与した投稿者だけを登録する。
- `artist_id`の自動生成値は新規候補用である。既存アーティストと同一なら、既存IDへ差し替える。
- `same_music`、`seriese`、`cover`、`part_of`はAIに確定させず、既存動画候補と内容を人が確認して`videos_junction`へ追加する。
- 歌詞はモデルに生成させない。権利と原文を確認した人が別工程で入力する。

## Jevを使う場合

Jevは生成モデルの代替として全項目を作らせるのではなく、コメントごとの「動画固有性」「記憶に残る度合い」「答え漏れ」「ノイズ」を高速に採点する実験枠に限定します。`prepare-jev`が作るJSONは入力と基準を監査でき、Jevが利用できなくてもルール + OpenAIまたは完全な手作業へ戻せます。TypeSafe公式はJevを、自由文ではなく型付きの判断と確率を返すSystem One Modelとして説明しています。

Jevは公開直後のearly access段階なので、現在はSDK/APIへ自動送信しません。TypeSafeから実アクセスと現行API仕様を取得した後に、`EditorialSelector`とは別の`CommentRanker`実装として接続します。タイトル・アーティスト・関連動画などの事実生成には使いません。未確認のエンドポイントやSDK名をコードへ先に固定しません。

- [TypeSafe AI公式サイト](https://typesafe.ai/)
- [Jevの公式発表](https://typesafe.ai/blog/introducing-system-one-models-and-jev)

## ディレクトリ

```text
data/raw/        YouTube取得スナップショット（Git対象外）
data/generated/  AI/Jev候補とレビュー用CSV（Git対象外）
prompts/         バージョン管理する選別基準
src/commentube_data/  再現可能な取得・選別・出力コード
tests/           APIキー不要のルールテスト
```

## Google Sheetsへの共有

### 現在できること

現在は`*.review.csv`をGoogle Sheetsで手動インポートできます。Sheetsへ送信するPythonコードとコマンドはまだありません。

### 自動同期の準備

シート構成、承認状態、差分同期、Supabase物理テーブルとの対応は`spec.md`を参照してください。READMEでは実行に必要なGoogle側の準備だけを扱います。既存の1枚のスプレッドシートへローカルMacから書く初期実装は、対象シートだけを編集者として共有したサービスアカウントを使います。既知のSpreadsheet IDへ値を書くだけならGoogle Sheets APIで足り、ファイル作成や検索をしない限りGoogle Drive APIは不要です。

実装後に必要になるGoogle側の準備は次のとおりです。

1. Google Cloud Consoleでプロジェクトを選ぶ。YouTube用と同じプロジェクトでも、分離したプロジェクトでもよい。
2. **Google Sheets API**を有効化する。
3. 認証情報作成時は`Application data`を選び、サービスアカウントを作成する。Google CloudプロジェクトのIAMロールは付けない。
4. サービスアカウントのJSON鍵を1つ作り、ダウンロードしたファイルを`_YouTube_Data_API/credentials.json`へ改名して置く。`chmod 600 credentials.json`で所有者だけが読み書きできるようにする。
5. 対象スプレッドシートの共有画面で、サービスアカウントのメールアドレスを編集者として追加する。サービスアカウントには受信箱がないため通知は不要。
6. `.env`へ対象シートの`GOOGLE_SPREADSHEET_ID`を保存する。

`credentials.json`と`.env`はGit対象外です。Google Cloudの既定ダウンロード名`commentube-*.json`も、改名前に誤って追跡しないようGit対象外にしています。鍵ファイルの内容をチャットへ貼りません。鍵をGitへ追加した疑いがある場合は、ignore追加だけではなくGoogle Cloudでその鍵を無効化・削除して新しい鍵を発行します。

- [Google Sheets API Pythonクイックスタート](https://developers.google.com/workspace/sheets/api/quickstart/python)
- [Google Sheets APIの値の読み書き](https://developers.google.com/workspace/sheets/api/guides/values)
- [Google Workspace用認証情報の選択](https://developers.google.com/workspace/guides/create-credentials)
