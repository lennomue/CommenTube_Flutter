# CommenTubeのためのSupabase設計書

Flutterアプリが扱う画面仕様と論理データは`../spec/spec.md`を正本とします。この文書は、それをSupabase/PostgreSQLで効率よく探索・取得するための物理設計と読み込み境界を定めます。実行コマンドや環境構築は`README.md`にだけ記載します。

## 1. 結論

- 探索用DBと表示用DBを別サービスとして二重管理しません。1つのSupabase PostgreSQL内に正規化した正本テーブルを置き、探索・カード・詳細を用途別のRPCまたはViewとして公開します。
- `quizzes`は動画1件の安定した基本情報を持つ中心テーブルのまま使います。ただし、コメント・歌詞・YouTube統計・embeddingを大きなJSONや配列として同じ行へ詰め込まず、更新頻度と取得タイミングに応じた子テーブルへ分けます。
- Homeや検索結果は、候補探索とカード情報の結合を**1回のRPC内**で完了させます。Flutterが候補IDを受け取ってからカード取得のためにもう一度通信する構成にはしません。
- Gameを開いた時だけ、その1問に必要なコメント・歌詞・アーティスト・関連動画等を詳細RPCで取得します。Homeの10件すべてについて詳細を先読みしません。
- 推薦時の生の`meta_data`参照は不要です。`meta_data`、タイトル、アーティスト、別名等はembeddingまたは全文検索用データを作る入力として使い、入力が変わった時だけ再生成します。
- ジャンル、言語、動画形式、投稿時期、公開状態等はembeddingへ埋め込むだけでなく、型付きの明示列として保持して絞り込みます。ハード条件をベクトルの意味解釈へ任せません。
- 文字検索とユーザー推薦は目的もベクトル空間も異なります。検索用embeddingと推薦用item embeddingは別データとして管理します。
- 初期段階では通常ViewとRPCで十分です。Materialized View、検索専用DB、Read Replica、外部ベクトルDBは、実測した遅延・件数・負荷から必要性が確認されるまで導入しません。

## 2. 3段階の読み込み

### 2.1. 候補探索

探索結果の1行は基本的に`video_id`と各スコアだけです。

使用する値は次のとおりです。

- 推薦: 同じモデル・同じ次元で作られたユーザー嗜好ベクトルとクイズitem embedding
- 意味検索: 検索語embeddingとクイズの検索用embedding
- 文字検索: タイトル、アーティスト名・別名、検索用キーワードから作った`tsvector`
- ハード条件: `content_genres`、`video_genre`、`languages`、`posted_at`、公開状態
- 補助順位: 未プレイ、重複回避、鮮度、人気度、探索枠、管理上の品質スコア

`meta_data`そのもの、コメント全文、歌詞、全アーティスト行、関連動画は探索中に返しません。

Homeの推薦と検索欄の検索結果は順位目的を分けます。Homeではユーザー嗜好を主に使えますが、検索では入力語への一致を主順位とし、完全一致・アーティスト一致・前方一致をユーザー嗜好より優先します。嗜好ベクトルは同程度の検索結果の並び替えにだけ使い、入力語と異なる人気作品へ置き換えません。

### 2.2. Home・検索結果のカード

探索で上位候補を決めた同じRPC内で、採用した10〜20件だけをカード表示用データへ結合して返します。

カードに必要な値は次のとおりです。

- `video_id`
- `video_atmosphere_color`
- `thumbnail_hint_type`
- 代表ヒント本文1件
- `posted_at`
- 表示用の再生回数
- 未プレイ表示に必要な履歴照合用ID

検索結果でカード外にタイトル、アーティスト、プレイリストを表示する場合は、その検索結果型にだけ表示名と種別を追加します。Homeカードへ不要な値を常に混ぜません。

### 2.3. Game・Resultの詳細

カードが押された時に`get_quiz_detail(video_id)`を1回呼び、次を取得します。

- 基本情報、内容ジャンル、動画ジャンル、言語、リリース時期
- 表示順付きの採用コメント1〜8件
- 表示順付きの歌詞ヒント
- アーティストと別名
- 関連動画と`relation_type`
- Resultで表示するタイトル等の正解情報
- 取得時点のYouTube統計

`meta_data`とembeddingはFlutterへ返しません。連続クイズでは現在問の表示後に次の1問だけを任意で先読みし、全問題の詳細をまとめて取得しません。

## 3. 推奨テーブル構成

### 3.1. `quizzes`

動画1件につき1行の正本です。頻繁に変動しない、画面と絞り込みの基本値だけを持ちます。

| 列 | 用途 |
|---|---|
| `video_id` | YouTube動画ID、Primary Key |
| `title` | 承認済み表示タイトル |
| `video_atmosphere_color` | HSL色 |
| `thumbnail_hint_type` | `comment`または`lyric` |
| `content_genres` | `content_genre[]`、非NULL・空禁止 |
| `video_genre` | `video_genre` enum |
| `languages` | `language[]` |
| `posted_at` | 動画投稿時刻 |
| `music_released_at` | 部分日付。既存仕様どおりprecisionとdateを保持 |
| `meta_data` | embedding・検索派生値を再生成するための承認済み補助情報 |
| `publication_status` | `draft`、`published`、`archived`等。通常探索は`published`だけ |
| `content_updated_at` | embedding再生成判定に使う内容更新時刻 |

`content_genres`の合成MAD・非音楽規則等は`../spec/spec.md`に従い、投入時の検証関数またはCHECK相当の処理でも保証します。

### 3.2. ヒントと統計

次のデータは`quizzes`から分けます。

- `quiz_comments(video_id, comment_id, content, commented_at, display_order, ...)`
- `quiz_lyrics(video_id, lyric_id, content, display_order, ...)`
- `video_stats(video_id, view_count, like_count, fetched_at)`
- 必要なら`comment_stats(comment_id, like_count, fetched_at)`

代表ヒントは`thumbnail_hint_type`に対応する`display_order=1`の行です。同じ本文を`quizzes`へ複製しません。`(video_id, display_order)`へ索引を作り、カードRPCが先頭1件だけを結合します。

統計を分離する理由は、再生回数更新のたびに安定したクイズ行やembedding索引を更新しないためです。統計の取得失敗時は直近値を返します。

### 3.3. アーティストと関連

既存仕様どおり、次の正規化テーブルを使います。

- `artists`
- `artist_videos_junction`
- `artists_junction`
- `videos_junction`

Homeの候補探索でこれらを毎回すべて結合しません。アーティスト文字検索用の派生検索文書を作る時と、カード採用後または詳細取得時にだけ必要な行を結合します。

### 3.4. embedding

検索と推薦は別テーブルにします。

#### `quiz_search_embeddings`

- `video_id`
- `embedding vector(D_search)`
- `model_name`
- `model_version`
- `source_hash`
- `generated_at`

タイトル、アーティスト名・別名、承認済み`meta_data.keywords`等を1つの入力文へ正規化して生成します。ユーザーが入力した検索文との意味類似度に使います。

#### `quiz_recommendation_embeddings`

- `video_id`
- `embedding vector(D_recommendation)`
- `model_name`
- `model_version`
- `source_hash`
- `generated_at`

ユーザー嗜好ベクトルと比較するitem embeddingです。将来、本当のTwo-Towerモデルを学習する場合もこの出力先を使います。

#### `user_recommendation_profiles`（サーバー側プロフィールを導入する時だけ）

- `subject_id`
- `embedding vector(D_recommendation)`
- `model_name`
- `model_version`
- `event_cursor`または`source_updated_at`
- `generated_at`

現在の端末内履歴だけで推薦する段階では必須ではありません。RPCまたはEdge Functionが端末から渡された最近の`video_id`と行動種別を使い、対応するitem embeddingの重み付き平均から一時的なユーザーベクトルを作れます。ログイン・匿名サーバーIDを導入した後は、更新済みプロフィールを保存できます。

#### `user_quiz_events`（サーバー学習を始める時だけ）

- `subject_id`
- `video_id`
- `event_type`
- `occurred_at`
- `session_id`
- `recommendation_request_id`
- `display_position`

Two-Towerを学習するには、正解・お気に入り等の正反応だけでなく、何を表示したかというimpressionが必要です。表示されていない問題を「選ばれなかった負例」と誤認しないため、推薦リクエスト単位と表示位置を記録します。`event_type`は少なくとも`impression`、`opened`、`answered_correct`、`answered_incorrect`、`skipped`、`favorited`、`unfavorited`、`replayed`を区別します。

現状のDrift履歴は端末外へ自動共有されないため、それだけではサーバー学習データになりません。初期は最近の履歴IDをRPC引数で渡す方式とし、行動ログをSupabaseへ保存する段階では匿名IDまたは認証、利用目的、保持期間、削除方法を先に確定します。

検索用と推薦用のembeddingは次元が同じでも意味が同じとは限りません。同じ列や索引へ混在させず、それぞれにHNSW索引を持たせます。モデル変更中は`model_version`を照合し、異なるバージョンのベクトル同士を比較しません。

## 4. `meta_data`を使うタイミング

`meta_data`は次の場合に使います。

- 検索用embeddingの生成・再生成
- 推薦用item embeddingの特徴生成
- 全文検索用`search_document`の生成
- 管理画面での関連候補発見と人による確認

通常のベクトル探索では生の`meta_data`を読みません。`source_hash`は、タイトル、アーティスト、別名、検索対象の`meta_data`等を正規化した入力から作ります。ハッシュ、モデル名、モデルバージョンが変わった行だけembeddingを再生成します。

YouTube再生回数やコメント高評価数の更新だけではembeddingを再生成しません。ジャンル、タイトル、アーティスト、キーワード等の意味内容が変わった時だけ再生成します。

文字列検索では、生のJSONB全体を毎回走査せず、検索対象だけをまとめた`search_document tsvector`を別の派生列または検索用テーブルに持たせ、GIN索引を使います。ベクトル検索と全文検索の順位はRRF等で合成でき、完全一致・前方一致は意味類似度より優先します。

## 5. Two-Towerについて

ユーザー履歴からitem embeddingの加重平均を作って類似動画を探す方式は、初期実装として有効な**コンテンツベース推薦**です。ただし、別々に作ったユーザーベクトルとテキストembeddingを比較するだけでは、学習済みTwo-Towerモデルとは呼びません。

本当のTwo-Towerでは、ユーザー塔とアイテム塔を同じ目的関数で学習し、両方を同じベクトル空間へ出力する必要があります。十分な行動ログが集まるまでは、次の方式を採用します。

1. クイズ内容から推薦用item embeddingを生成する。
2. 完了、正解、お気に入り、再プレイ等を正、即スキップ等を負の重みとして扱う。
3. 時間減衰をかけた重み付き平均からユーザー嗜好ベクトルを作る。
4. 類似候補を多めに取得し、未プレイ、多様性、鮮度、人気度、探索枠を加えて再順位付けする。
5. 履歴がないユーザーには、品質確認済みの人気問題とジャンルが偏らない探索枠を返す。

データが蓄積した後、同じRPC契約を維持したまま学習済みTwo-Towerの出力へ置き換えます。

## 6. RPC境界

### `discover_quiz_cards(...)`

1回のSQL/RPC内で次を行います。

1. `published`だけを対象に、ジャンル・言語・動画形式・投稿時期のハード条件を適用する。
2. 推薦embeddingから必要数より多めの候補IDを取得する。
3. 渡された直近履歴IDを除外または減点する。
4. 多様性、鮮度、品質、探索枠を加えて10件程度へ絞る。
5. その10件だけを`quizzes`、`video_stats`、代表ヒントへ結合してカード型で返す。

Flutterから見れば1通信です。DB内部のPrimary Key結合は、候補ID受信後にFlutterが再通信するより小さな負担です。

### `search(...)`

タイトル・アーティストの完全一致、前方一致、全文検索、意味検索を統合し、クイズ・アーティスト・プレイリストを型付きの結果として返します。完全一致とアーティスト本体を最優先し、ユーザー嗜好は同程度の候補の補助順位に限定します。検索用embeddingの生成に外部APIが必要な場合は、APIキーをFlutterへ置かずEdge Function等のサーバー側で生成します。初期は低遅延・低コストな全文検索だけでも成立させ、意味検索は検索品質の不足を計測してから追加できます。

### `get_quiz_detail(video_id)`

指定した1問だけを、コメント・歌詞・アーティスト・関連動画・統計を含む詳細型へ結合して返します。公開前行を一般ユーザーへ返さないことをRLSまたは`security invoker`の関数で保証します。

## 7. 索引

初期候補は次のとおりです。実際のクエリ計画を測定してから追加・削除します。

- `quiz_search_embeddings.embedding`: cosine距離用HNSW
- `quiz_recommendation_embeddings.embedding`: 推薦空間に合わせたHNSW
- `quizzes.content_genres`: GIN
- `quizzes.languages`: GIN
- `quizzes.posted_at`: B-tree
- `quizzes(video_genre, posted_at)`: 実際の複合絞り込み頻度が高い場合だけ複合索引
- `quizzes`の公開行: 頻繁に`publication_status='published'`を使う場合は部分索引
- `quiz_comments(video_id, display_order)`
- `quiz_lyrics(video_id, display_order)`
- 全文検索用`search_document`: GIN
- すべての中間テーブルの外部キー列

HNSWとハード条件を同時に使うと、近傍候補を走査した後の絞り込みで件数が不足する場合があります。候補を多めに取得し、pgvectorのiterative scan、一般列の索引、条件が固定的なら部分HNSW索引を検討します。ジャンルごとに無条件でHNSW索引を量産しません。

## 8. 同一テーブルか分割か

同じテーブルに列が存在すること自体より、次の要素の方が性能へ強く影響します。

- 返却する列を明示し、`select *`で不要な本文を送らないこと
- `WHERE`、`JOIN`、`ORDER BY`に合った索引
- 1回の通信でサーバー側結合を終えること
- コメント等の1対多データを行として正規化すること
- 頻繁に更新する統計と、ほぼ不変のクイズ情報を分離すること
- HNSW索引がメモリに収まるか、必要な再現率を満たすか

PostgreSQLは大きな可変長値をTOASTで行外保存できます。また、必要列だけを選択すれば不要な列をネットワークへ返しません。そのため「広い`quizzes`テーブルだから必ず探索が遅い」とは言えません。一方、コメント配列や歌詞を同じJSONBへ詰めると、更新、検証、部分取得、索引、キャッシュ効率が悪くなるため子テーブル化します。

正本を二重化した探索専用テーブルは同期漏れを生みます。embeddingと全文検索文書のように再生成可能な派生データだけを分離し、`source_hash`で正本との整合性を確認します。

## 9. キャッシュと整合性

- Flutter/Riverpodはカード一覧と開いた詳細を同一起動中だけキャッシュできます。
- RPCレスポンスには必要なら`content_updated_at`またはデータバージョンを含め、古い詳細を判定します。
- embedding更新は、先に新ベクトルを生成・検証してからトランザクションで有効版を切り替えます。
- `video_stats`更新はクイズ本文やembeddingを無効化しません。
- Viewは正本から毎回計算するため初期の整合性を保ちやすいです。Materialized Viewは更新遅延を許容でき、通常View/RPCが実測で遅い場合だけ採用します。

## 10. セキュリティとゲーム性

- Flutterから直接参照できるテーブルにはRLSを必須とし、原則として公開済み行だけを返します。
- 管理用`meta_data`、embedding、ドラフト、レビュー情報は一般クライアントへ公開しません。
- 現在のように端末内で正誤判定する限り、技術的なユーザーが通信やアプリデータから正解IDを調べることを完全には防げません。厳密な不正防止が必要になった時は、回答動画IDをサーバーRPCへ送り、正誤だけを返す方式へ変更します。
- サービスロールキーとembedding生成APIキーはFlutterへ入れません。

## 11. 計測して決める項目

推測だけでテーブルを複製せず、代表的な件数のデータで次を測ります。

- `EXPLAIN (ANALYZE, BUFFERS)`による探索RPC、カード結合、詳細RPCの実行計画
- p50/p95のDB実行時間とAPI全体時間
- RPCレスポンス容量
- HNSWの近似結果とexact searchを比較したrecall
- 絞り込み後に10件を満たせない割合
- index hit rate、cache hit rate、未使用索引、テーブル・索引サイズ

最初の目標は、Homeカード10件を1通信、Game詳細1件を1通信で取得し、不要なコメント・歌詞・embeddingをHomeレスポンスへ含めないことです。データ件数が少ない間はSequential Scanの方が速い場合もあるため、索引が使われないことだけを失敗とは判断しません。

## 12. 参考資料

- [Supabase: Query Optimization](https://supabase.com/docs/guides/database/query-optimization)
- [Supabase: Debugging performance issues](https://supabase.com/docs/guides/database/debugging-performance)
- [Supabase: Automatic embeddings](https://supabase.com/docs/guides/ai/automatic-embeddings)
- [pgvector公式: Indexing、Filtering、Hybrid Search](https://github.com/pgvector/pgvector)
- [PostgreSQL: TOAST](https://www.postgresql.org/docs/current/storage-toast.html)
