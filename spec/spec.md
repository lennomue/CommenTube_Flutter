# CommenTube基本設計書

YouTubeの動画、特に公式のミュージックビデオを中心としてmeme動画(ネタ動画やMAD動画)をも対象とし、それらにつくコメントなどのヒント(楽曲の動画ならばこれに歌詞やアーティスト、楽曲情報)をプレイヤーに提供し、元動画を回答するゲーム。初めはヒントをかくし、ユーザーが選択したヒントを解放する。ヒントの一部の開放にはポイントを消費するゲームシステムにする。スマホ向けアプリとして開発する。
世界中のプレイヤーがログインでなしで、快適に遊べ、Cポイントによるヒント開示システムや評価・フィードバックシステム、お気に入り機能を通じてクイズの質が自動的に洗練されていく、クロスプラットフォーム対応のクイズゲームアプリ。

---

## 1. 技術選定とその理由

| レイヤー | 採用技術 | 選定理由 |
| :--- | :--- | :--- |
| **フロントエンド** | **Flutter (Dart)** | 1つのコードベースでiOSとAndroidの両アプリを同時開発可能。世界シェアの約7割を占めるAndroid市場への展開や今後のWeb応用を踏まえ、UI柔軟性とアニメーション性能が高い本技術を採用。 |
| **ローカルDB** | **Isar** | Flutter専用の高速NoSQLデータベース。一時クイズ、Cポイント、お気に入り、履歴などの構造化データを安全に永続化でき、オブジェクト間のリレーション管理も得意なため。 |
| **バックエンド** | **Go (Golang)** | メモリ消費が極めて少なく起動が爆速。世界中からの大規模な同時接続（クイズ条件絞り込み、ポイント同期など）が増えても、格安のサーバー環境で安定して高パフォーマンスを維持するため。 |
| **BaaS / クラウドDB** | **Supabase (PostgreSQL)** | 強固なPostgreSQLをベースにしたサービス。匿名認証やGmail個人認証(Auth)が安全に構築でき、配列型検索（GINインデックス）による多角的な楽曲条件抽出が非常に高速なため。 |

---

## 2. ゲーム仕様 (ゲームシステム・画面遷移)

### 2.1. コアゲームサイクル
1. ログイン手続きは行わず、ゲストとして即座に遊ぶ（裏側で端末固有でプレイログを保存しておく）。
2. 本場YouTubeアプリを開いた際にサムネがいくつか表示される画面さながら、早速問題(5問程度)への入口のブロック(全て"GUESS ME"と書かれたサムネ共通のもの)が表示されている。視聴回数や動画の投稿日時ほどの簡単な情報のみここで表示。
3. 問題のブロックが押されたらその問題の詳細画面へ遷移。ユーザーはみたいヒントをみる。ヒント開放機能も。
4. 問題の詳細画面には問題に回答するボタンがある。これを押したらアプリ内部でYouTubeを開く。(LINEでYouTubeを開くときのような仕様)
5. URLを識別しならがYouTube動画が再生された時には、その動画を回答するボタンが有効になる(視覚的にも回答できる時とできない時でわかりやすく。)
6. ユーザーが回答するボタンを押したらYouTube画面が閉じ、問題の詳細画面に戻り、正誤判定のポップアップ的な演出をみる。(なお回答の際にアプリ内YouTubeを閉じる際に、アクセスしていいるページを保ち、同じ問題に再度回答する時にはリロードではなく同じ状態のページに戻れると良い。なおこの間には動画を停止はしたい。)

### 2.2. 回答方法（アプリ内完結型＋専用UIウィンドウ）
1. クイズ画面の「解答する」ボタンから、Flutter製の制御外枠（閉じる、戻る・進む、URL検証ロジックを搭載）を持つWebViewウィンドウを展開。
2. ユーザーがWebView内のYouTubeで該当動画の再生ページ（`watch?v=...`）に達した状態で、外枠の「**この動画で回答する！**」をタップ。
3. `currentUrl()`を利用して、現在のURLから動画ID（`video_id`）を抽出し、ウィンドウを閉じながら、ローカルデータ内に持っている正解データを元に正誤判定

### 2.3. 個人認証について
1. ゲームの開始時には個人認証はしない。ユーザーが設定から連携に進む時に、そのメールでアカウントがあればログインし、なければその時点での情報を使ってアカウントの新規作成をする。
2. ユーザーが希望したタイミングでGmailによる連携の登録をする(Firebase Authentication)
3. ログインしている時(ログインしているかどうかはIsarに保存できると考えている)、ゲーム起動時にバックサーバーと通信して、クラウド側の最新のCポイント情報や戦績情報を端末内に反映する。
4. 同一ユーザーが複数端末から同時ログインしてデータを更新する場合も、最新のタイムスタンプまたはサーバー側のトランザクション処理によって、Cポイント関連情報の不整合が起きないように同期を構築する。

### 2.4. 主要画面（機能）
* ***ホーム(home)画面**: 問題サムネ(画像はシンプルなもので共通)、お気に入りを開くボタン(ロゴ)、または設定を開くボタン(ロゴ)を設置
* **クイズプレイ(game)画面**: 段階的に開示可能なコメント等のヒント表示、および専用WebViewを開く回答ボタン。
* **プレイ情報(library)画面**: リストとしておく。高評価の機能と、再生リストのように、個人が作ったラベルに分類保存する機能を追加する。タブで切り替え表示。
* **設定(setting)画面**: クイズの対象とする楽曲の制限(ジャンル選択、投稿された年代の幅、再生数の条件など)の変更。
* **問題追加(post)画面**: (将来的な実装であるが)ユーザーがYouTubeの動画からコメントへのURIや歌詞の内容を打ち込んで問題を追加できるようにする。本当に最後に実装する内容なので、そもそもこの画面は作らないし、この画面を開くボタンもどこにも存在しない。

---

## 3. データベース設計 (スキーマ定義)

データベースの実体は**Supabase(クラウド)** と**Isar(ローカル)** の2箇所に存在します。

### 3.1. Supabase (クラウドDB)

#### ① `users` テーブル (ユーザー情報の管理)

```jsonc
{
   "user_id": "f353ca91-4fc5-49f2-9b9e-304f83d11914",      // uuid型 (Primary Key / Supabase Auth連動)
   "email": "test@gmail.com",                         // text型 (匿名ログイン時はnull、Gmail連携時に格納)
   "created_at": "2026-06-08T14:00:33Z",              // timestamptz型 (ISO 8601形式の日時文字列)
   "c_point": 50,                                     // int型 (ユーザーの現在所有しているCポイント。サーバー側を正とする)
   "favorite_videos": ["Il-an3K9pjg", "y2bVIBwpCTA"],  // text[]型 (お気に入り楽曲(動画)のID配列)
   "favorite_comments": [                             // jsonb型 (お気に入りコメント構造体の配列。表示専用のためネスト保持)
      {
         "video_id": "MrTz5xjmso4",                    // 楽曲のID
         "content": "I remember my mom wouldn't let me listen to this song bc it said suicidal",
         "comment_id": "UgzYLJd1ADkFg4QPuOh4AaABAg"   // コメントの一意なID
      }
   ],
   "quiz_history": ["_G9JjpnwCVQ", "mUg5aEy-8CQ", "rSYoIuyks8g"]  // text[]型 (出題被り防止用。最新100〜200件を巡回保存)
}
```
#### ② `quizzes` テーブル (出題情報の管理)
```jsonc
{
   "video_id": "y2bVIBwpCTA",                          // text型 (Primary Key / YouTube動画ID / 答え合わせ用)
   "video_genre": "musicLivePerformane",               // text型 ("musicOriginal"、"musicLivePerformane"、"musicMAD"、"musicAI"、"nonMusic"のどれか / 条件検索用 / 出題用)
   "music_title": "I Want You Back",                   // text型 (楽曲タイトル / resultやlibraryにて楽曲の紹介に使用)
   "music_artists": ["The Jackson 5"],                 // text[]型 (配列型: アーティスト名。複数名に対応 / 出題用)
   "music_languages": ["english"],                     // text[]型 (配列型: 歌詞の言語。複数言語に対応 / 条件検索用)
   "music_released_at": "1969-10-07T00:00:00Z",        // timestamptz型 (ISO 8601形式の日時文字列) (リリース年 / 条件検索用)
   "video_view_count": 117264772,                      // int型 (動画の視聴回数 / 出題用)
   "video_like_count": 944180,                         // int型 (動画の高評価数)
   "video_channel_id": "UCDUNe-NZaknJOGyulc4Ohvg",     // text型 (チャンネルID / 出題用)
   "video_published_at": "2020-06-14T19:00:08Z",       // (YoutubeのAPIではISO 8601形式だが、このデータの目的は年月日の情報があれば良い。データベースとの相性も考えて型は変更しても良い)timestamptz型 (ISO 8601形式の日時文字列) (動画公開日時 / 出題用)
   "video_lyrics": [                                   // text[]型 (最大3個の歌詞を持つ文字列配列、楽曲でなければnullとする / 出題用)
      "Oh, baby, give me one more chance",
      "Won't you please let me (Back in your heart)",
      "But now since I see you in his arms (I want you back)" 
   ],
   "video_comments": [                                 // jsonb型 (画面表示専用データ。検索条件に使わないためオブジェクト構造を維持)
      {
         "comment_id": "UgzYLJd1ADkFg4QPuOh4AaABAg",
         "content": "Imagine a 10 year old sounding better than most artist today",
         "like_count": 77307,
         "updated_at": "2021-01-22T14:00:33Z"
      },
      {
         "comment_id": "Ugy-lmxYekKinoSMZ0l4AaABAg",
         "content": "We want you back, Michael 💔\nThis world is so evil.",
         "like_count": 1705,
         "updated_at": "2026-05-09T19:48:20Z"
      }
   ]
}
```
#### ③ `quiz_feedbacks` テーブル (フィードバック(報告)の記録)
```jsonc
{
   "report_id": 128,                                   // int型 (Identityによる自動連番。管理の簡素化)
   "video_id": "aatr_2MstrI",                           // text型 (対象の動画ID)
   "hint_type": "comment",                             // text型 (comment / lyric / video_type)
   "comment_id": "Ugy-lmxYekKinoSMZ0l4AaABAg",         // text型 (特定のコメントを特定する場合に格納)
   "report_counts": 3                                  // int型 (同一問題への累積報告回数。開発者のデータブラッシュアップ用)
}
```

### 3.2. Isar (スマホ内・一時キャッシュ・状態管理用)
```jsonc
{
   "user_information": {
      "user_id": "f353ca91-4fc5-49f2-9b9e-304f83d11914",    // クラウドと同期した一意の識別子
      "c_point": 50,                                        // 同期された現在の所持Cポイント
      "favorite_videos": ["Il-an3K9pjg", "y2bVIBwpCTA"],    // お気に入り楽曲配列
      "favorite_comments": [                                // お気に入りコメント配列
         {
            "video_id": "MrTz5xjmso4",
            "content": "I remember my mom wouldn't let me listen...",
            "comment_id": "UgzYLJd1ADkFg4QPuOh4AaABAg"
         }
      ],
      "quiz_history": ["_G9JjpnwCVQ", "mUg5aEy-8CQ", "rSYoIuyks8g"]  // 出題履歴キャッシュ
   },
   "quizzes_showing_check": {
      "quiz_state": 1,                                      // int型 (表示している問題のindex(0~4)、またはクイズが終了しているなら-1を入れる。途中でアプリを閉じていた時に、クイズの続きをするか、新規クイズを開始するかの判定に使用。)
      "flags": [
         {
            "video_id": "y2bVIBwpCTA",                      // 対象の楽曲ID
            "show_music_artists": false,                    // 各種要素がCポイント消費によって開示されているかのフラグ
            "show_music_released_year": true,
            "show_video_view_count": true,
            "show_video_like_count": true,
            "show_video_channel_id": false,
            "show_video_lyrics": [false, false, false],
            "show_video_comments": [true, false]
         },
         {},{},{},{}                                        // 省略
      ]
   },
   "quizzes_on_going": [
      // バックエンドから条件抽出された、現在プレイ中ステージ（5問分）のフルオブジェクトキャッシュ
   ]
}
```