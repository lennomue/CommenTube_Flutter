# CommenTube基本設計書

YouTubeの動画、特に公式のミュージックビデオを中心としてmeme動画(ネタ動画やMAD動画)をも対象とし、それらにつくコメントなどのヒント(楽曲の動画ならばこれに歌詞やアーティスト、楽曲情報)をプレイヤーに提供し、元動画を回答するゲーム。初めはヒントをかくし、ユーザーはヒントを解放しながら回答をする。スマホ向けアプリとして開発する。
世界中のプレイヤーがログインでなしで、快適に遊べ、ヒント開示演出の体験、さらにお気に入り機能を通じて印象的なコメントを記録し、他の人に共有できる。
この開発の展望として以下のようなものがある。
- 問題の自動生成
- ユーザーからの評価・フィードバックシステム
- アーティスト名で検索すると、そのアーティストの楽曲に絞って問題を見れる。または問題を追加する案内をしてみる
- ユーザーがお気に入りのコメントを見つけたら問題を追加できるシステムを作る(審査や自動判断もAIを使えば可能かと考えられる)
- 表示設定として、プレイヤーの国の言語設定に応じてプロジェクト全体の言語の表示をsetting画面から変更可能に。ゲームの各場所、コメントの翻訳機能などの表示形式について要検討。保存するべき情報は原文のみか、翻訳させるのはどのタイミングなのか、本家YouTubeでの翻訳の仕組みを参考に、また自分の環境で実装可能かどうかを調べてから計画を立てよう。

---

## 1. 技術選定とその理由

| レイヤー | 採用技術 | 選定理由 |
| :--- | :--- | :--- |
| **フロントエンド** | **Flutter (Dart)** | 1つのコードベースでiOSとAndroidの両アプリを同時開発可能。世界シェアの約7割を占めるAndroid市場への展開や今後のWeb応用を踏まえ、UI柔軟性とアニメーション性能が高い本技術を採用。 状態管理にはライブラリRiverpodを使用 |
| **ローカルDB** | **Drift** | ローカルDBはDrift |
| **バックエンド** | **Go (Golang)** | メモリ消費が極めて少なく起動が爆速。世界中からの大規模な同時接続（クイズ条件絞り込み、出題の要求が増えても、格安のサーバー環境で安定して高パフォーマンスを維持するため。 |
| **BaaS / クラウドDB** | **Supabase (PostgreSQL)** | 強固なPostgreSQLをベースにしたサービス。匿名認証やGmail個人認証(Auth)が安全に構築でき、将来的にアーティスト名の配列型検索（GINインデックス）による多角的な楽曲条件抽出が非常に高速なため。現状でも楽曲のジャンルや年代、言語の絞り込みはあるが、これはタグを事前に決めておき、ユーザーはタグから選択して指定するようにする　|
| **リンタ/フォーマッタ** | **dart format / flutter_lints** | Flutter SDKに標準搭載|

---

## 2. ゲーム仕様 (ゲームシステム・画面遷移)

### 2.1. コアゲームサイクル
1. ログイン手続きは行わず、ゲストとして即座に遊ぶ（裏側で端末固有でプレイログを保存しておく）。
2. 本場YouTubeアプリを開いた際と同様、問題(5問程度)への入口のブロック(サムネイル+簡易情報)が並ぶ(spec/game_images/01_home_draft.JPG)。サムネの基本デザインは全体で共通であり、中心に音楽ジャンルのヒントが表示されている。サムネの下に視聴回数と動画の投稿日時(何年前か)という簡単な情報のみここで表示。
3. 問題のブロックが押されたらその問題の詳細画面へ遷移(spec/game_images/02_quiz_1_main_draft.JPG)。ユーザーはみたいヒントをみる。基本構造ができたらヒント開放機能も。
4. 問題の詳細画面には問題に回答するボタンがある。これを押したらアプリ内部でYouTubeを開く。(spec/game_images/02_quiz_2_answering_draft_01.JPG)
5. URLを識別しならがYouTube動画が再生された時には、その動画を回答するボタンが有効になる。(spec/game_images/02_quiz_2_answering_draft_02.JPG)
6. ユーザーが回答するボタンを押したらYouTube画面が閉じ、まずは問題の詳細画面に戻る。不正解であればその演出をした上で、問題の詳細画面(回答直前の状態)に戻る。正解であったならば一瞬その演出をし、直ちに楽曲の詳細を表示する(spec/game_images/03_result_draft.JPG)。ユーザーは次の問題にいくか、ホームに戻る。
7. なお回答の際にアプリ内YouTubeを閉じる際には動画を停止はしたい。

### 2.2. 回答方法（アプリ内完結型＋専用UIウィンドウ）
1. クイズ画面の「解答する」ボタンから、Flutter製の制御外枠（閉じる、戻る・進む、URL検証ロジックを搭載）を持つWebViewウィンドウを展開。
2. ユーザーがWebView内のYouTubeで該当動画の再生ページ（`watch?v=...`）に達した状態で、外枠の「**この動画で回答する！**」をタップ。
3. `currentUrl()`を利用して、現在のURLから動画ID（`video_id`）を抽出し、ウィンドウを閉じながら、ローカルデータ内に持っている正解データを元に正誤判定

### 2.3. 個人認証について
1. ゲームの開始時には個人認証はしない。ユーザーが設定から連携に進む時に、そのメールでアカウントがあればログインし、なければその時点での情報を使ってアカウントの新規作成をする。
2. ユーザーが希望したタイミングでGmailなどによる連携の登録をする(Firebase Authenticationなどがあると聞いているが、手段にこだわりはなく実装コストの低いもので良い。)
3. ログインしているならばゲーム起動時にバックサーバーと通信して、クラウド側に保存しているユーザーの設定やライブラリ情報を端末内に反映する。
4. 同一ユーザーが複数端末から同時ログインしてデータを更新する場合も、標準的な手法を用いて、データベースに管理している情報に不具合が起きないように安全な設計にする。

### 2.4. 主要画面（機能）
* ***ホーム(home)画面**: 問題ブロックが並んでいる。画面下部にはhomeとlibraryとsettingへの移動をできる/現在の場所を示すものがある。
* **クイズプレイ(game)画面**: 段階的に開示可能なコメント等のヒント表示、および専用WebViewを開く回答ボタン。
* **プレイ情報(library)画面**: コメントや歌詞、動画という各粒度でお気に入り登録/確認が可能。タブで粒度を切り替えて表示。
* **設定(setting)画面**: クイズの対象とする楽曲の制限(ジャンル選択、投稿された年代の幅、再生数の条件など)の変更。ジャンルは属性であり、一つの楽曲が複数の属性ラベルを持つことができる。
動画のジャンル次のような候補：楽曲(music_video)、歌詞動画(lyric_video)、ライブ映像(live_performance_video)、合成MAD(fan_made_video)、非音楽(non_music)
楽曲のジャンルについては次のような候補：J-Pop(j_pop)、J-Rock(j_rock)、K-Pop(k_pop)、R&B and ソウル(r_and_b_soul)、アニメ&サントラ(anime_soundtrack)、アフリカ音楽(afro)、アラブ音楽(arabic)、インディー&オルタナティヴ(indie_alternative)、カントリー(country)、クラシック(classical)、ジャズ(jazz)、ダンス&エレクトロニック(dance_electroni)、ヒップホップ(hiphop)、ファミリー(family)、フォーク&アコースティック(folk_acoustic)、ブルース(blues)、ボカロ&歌い手(vocaloid_utaite)、ポップ(pop)、ボリウッド&インド音楽(bollywood_indian)、マンドポップ&香港ポップス(mandopop_cantopop)、メタル(metal)、ラテン(latin)、レゲエ&カリビアン(reggae_caribbean)、ロック(rock)、演歌・歌謡曲(traditional_japanese_pop)、季節の音楽(春夏秋冬)(seasonal_springなど)、年代別(1950s~2010s)(decade_1950sなど)

---

## 3. データベース設計 (スキーマ定義)

データベースの実体は**Supabase(クラウド)** と**Isar(ローカル)** の2箇所に存在します。

### 3.1. Supabase (クラウドDB)

#### ① `users` テーブル (ユーザー情報の管理)
必要な個人情報の管理についてはより一般的な実装方法があればそれを参考にすること。

```jsonc
{
   "user_id": "f353ca91-4fc5-49f2-9b9e-304f83d11914",      // uuid型 (Primary Key / Supabase Auth連動)
   "email": "test@gmail.com",                         // text型 (匿名ログイン時はnull、Gmail連携時に格納)
   "created_at": "2026-06-08T14:00:33Z",              // timestamptz型 (ISO 8601形式の日時文字列)
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
   "video_mood_color": {"h": 0,"s": 35,"l": 80},       // HSL / HSBのデータ型
   "music_genre": ["r_and_b_soul"],                              // 
   "video_genre": "musicLivePerformane",               // text型 ("musicVideo"、"musicLivePerformane"、"musicMAD"、"musicAI"、"nonMusic"のどれか / 条件検索用 / 出題用)
   "music_title": "I Want You Back",                   // text型 (楽曲タイトル / resultやlibraryにて楽曲の紹介に使用)
   "music_artists": ["The Jackson 5"],                 // text[]型 (配列型: アーティスト名。複数名に対応 / 出題用 / 検索用(追加機能としてアーティスト名検索は可能にしたい。そうなるとアーティストの表記揺れやIDの設定も必要か？検索機能は今回の仕様書には含まない))
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

### 3.2. Isar (スマホ内・一時キャッシュ・状態管理用)
```jsonc
{
   "user_information": {
      "user_id": "f353ca91-4fc5-49f2-9b9e-304f83d11914",    // クラウドと同期した一意の識別子
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
            "show_music_artists": false,                    // 各種要素が開示されているかのフラグ
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