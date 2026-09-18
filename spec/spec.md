# CommenTube基本設計書

YouTubeの動画、特に公式のミュージックビデオを中心としてmeme動画(ネタ動画やMAD動画)をも対象とし、それらにつくコメントなどのヒント(楽曲の動画ならばこれに歌詞やアーティスト、楽曲情報)をプレイヤーに提供し、元動画を回答するゲーム。初めはヒントをかくし、ユーザーはヒントを解放しながら回答をする。スマホ向けアプリとして開発する。
世界中のプレイヤーがログインでなしで、快適に遊べ、ヒント開示演出の体験、さらにお気に入り機能を通じて印象的なコメントを記録し、他の人に共有できる。
この開発の展望として以下のようなものがある。
- ヒント開放の体験について、開放が0-1すぎるので、少しだけ覗く(スライドしながら左から文章をめくっていく)方法で開放する。
- アカウント連携機能
- 問題の自動生成
- ユーザーからの評価・フィードバック、さらにはクイズ投稿
- 出題を完全なランダムではなく、ベクトル表現によって属性などからレコメンドをするシステム + 曖昧キーワード検索対応
- ユーザーがお気に入りのコメントを見つけたら問題を追加できるシステムを作る(例えばコメントを共有するボタンで、アプリを選択した時に、自動で投稿準備ができるなど。既存の動画であればコメントだけが追加され、楽曲も新規であれば新たにクイズに必要な項目もAIを使えば補填可能かと考えられる)
- 表示設定として、プレイヤーの国の言語設定に応じてプロジェクト全体の言語の表示をsetting画面から変更可能に。ゲームの各場所、コメントの翻訳機能などの表示形式について要検討。保存するべき情報は原文のみか、翻訳させるのはどのタイミングなのか。ここは要検討。

---

## 1. 技術選定とその理由

| レイヤー | 採用技術 | 選定理由 |
| :--- | :--- | :--- |
| **フロントエンド** | **Flutter (Dart)** | 1つのコードベースでiOSとAndroidの両アプリを同時開発可能。世界シェアの約7割を占めるAndroid市場への展開や今後のWeb応用を踏まえ、UI柔軟性とアニメーション性能が高い本技術を採用。 状態管理にはライブラリRiverpodを使用 |
| **ローカルDB** | **Drift** | ローカルDBはDrift。読み込んだクイズ情報などを管理 |
| **BaaS / クラウドDB** | **Supabase (PostgreSQL)** | 強固なPostgreSQLをベースにしたサービス。匿名認証やGmail個人認証(Auth)が安全に構築でき、将来的にアーティスト名の配列型検索（GINインデックス）による多角的な楽曲条件抽出が非常に高速なため。現状でも楽曲のジャンルや年代、言語の絞り込みはあるが、これはenumタグを事前に決めておき、ユーザーはタグから選択して指定するようにする。またバックエンドサーバーを立てずに読み書きを実行できる。 |
| **リンタ/フォーマッタ** | **dart format / flutter_lints** | Flutter SDKに標準搭載 |

---

## 2. ゲーム仕様 (ゲームシステム・画面遷移)

### 2.1. コアゲームサイクル
1. ログイン手続きは行わず、ゲストとして即座に遊ぶ（裏側で端末固有でプレイログを保存しておく）。
2. 本場YouTubeアプリを開いた際と同様、ホーム画面にはブロック(サムネイル+簡易情報)が並ぶ(spec/game_images/01_home_draft.JPG)。サムネの基本デザインは全体で共通であり、中心には代表となるコメントが表示されている。サムネの下に視聴回数と動画の投稿時期を表示。
3. 問題のブロックが押されたらその問題の詳細画面へ遷移(spec/game_images/02_quiz_1_main_draft.JPG)。
4. 問題詳細画面以降は次の2.2.回答方法を参照
5. 他にはライブラリからお気に入りのコメント、歌詞、アーティスト、楽曲を確認できる。
6. 設定については未実装で良い。

### 2.2. 回答方法（アプリ内完結型＋専用UIウィンドウ）
(spec/game_images/02_quiz_2_answering_draft_01.JPG、spec/game_images/02_quiz_2_answering_draft_02.JPG)
1. クイズ画面の回答ボタンから、Flutter製の制御外枠（閉じる、戻る・進む、URL検証ロジックを搭載）を持つWebViewウィンドウを展開。
2. WebView内のURLを追跡して、外枠下部に（`watch?v=...`）であれば「**ANSWER**」を、そうでなければ「**PLAY THE VIDEO**」を表示
3. `currentUrl()`を利用して、現在のURLから動画ID（`video_id`）を抽出し、ウィンドウを閉じながら、ローカルデータ内に持っている正解データを元に正誤判定
4. 不正解であればその演出をした上で、game画面に戻る。正解であった時、またはスキップが押された時は楽曲の詳細を表示する(spec/game_images/03_result_draft.JPG)。ユーザーは次の問題にいくか、ホームに戻る。

### 2.3. 主要画面（機能）
* **ホーム(home)画面**: 問題ブロックが並んでいる。画面下部にはhomeとlibraryとsettingへの移動をできる/現在の場所を示すものがある。(spec/game_images/01_home_draft.JPG)
game_imagesで提供したものには残念ながら入っていないが、画面の上部にクイズの対象とする楽曲の制限をタグ選択形式で絞り込むようにしましょう。
タグの種類はクイズデータが持つ楽曲ジャンル、言語、動画ジャンルです。しかし画面上部に全てのタブを入れはしません。ここは小さめに目立たない形で一部のタグを例示します。なんなら下方向スクロールされたら隠れるようにしましょう。表示するのはジャンルの代表的なJ-Popや、ロック、言語でも英語(洋楽)、日本語(邦楽)、年代として2010'だけとして、タグと同じような表示方法で詳細設定するためのボタンが虫眼鏡デザインで並んでいるといいでしょう。詳細設定をする際には以下のようなタグを提示して選択/解除してもらいましょう。
ジャンル、投稿された年代の幅、言語などの条件を扱います。
ジャンルは属性であり、一つの楽曲が複数の属性ラベルを持つことができる。
動画のジャンルは次のような候補：楽曲(music_video)、歌詞動画(lyric_video)、ライブ映像(live_performance_video)、合成MAD(fan_made_video)、非音楽(non_music)
楽曲のジャンルについては次のような候補：J-Pop(j_pop)、J-Rock(j_rock)、K-Pop(k_pop)、R&B and ソウル(r_and_b_soul)、アニメ&サントラ(anime_soundtrack)、アフリカ音楽(afro)、アラブ音楽(arabic)、インディー&オルタナティヴ(indie_alternative)、カントリー(country)、クラシック(classical)、ジャズ(jazz)、ダンス&エレクトロニック(dance_electroni)、ヒップホップ(hiphop)、ファミリー(family)、フォーク&アコースティック(folk_acoustic)、ブルース(blues)、ボカロ&歌い手(vocaloid_utaite)、ポップ(pop)、ボリウッド&インド音楽(bollywood_indian)、マンドポップ&香港ポップス(mandopop_cantopop)、メタル(metal)、ラテン(latin)、レゲエ&カリビアン(reggae_caribbean)、ロック(rock)、演歌・歌謡曲(traditional_japanese_pop)、季節の音楽(春夏秋冬)(seasonal_springなど)、年代別(1950s~2010s)(decade_1950sなど)
投稿された年代はシンプルにデータの投稿時期から絞り込めます。
言語はいくつかしかないので、enum型ですからジャンルと同様に絞り込めますね。
* **クイズプレイ(game)画面**: 段階的に開示可能なコメント等のヒント表示、および専用WebViewを開く回答システム。youtubeのウィンドウを開くときにアプリを立ち上げないように実装する必要がある。(spec/game_images/02_quiz_1_main_draft.JPG、spec/game_images/02_quiz_2_answering_draft_01.JPG、spec/game_images/02_quiz_2_answering_draft_02.JPG)
   ヒントの種類は以下のよう。
  - 上半分に固定で表示する基本情報(再生数、高評価数、投稿時期)、楽曲のジャンル(代表一つ)
  - コメント(本文、投稿時期、idから導かれるいいね数)、歌詞(歌詞本文からの一部のデータを複数)、楽曲情報(動画ジャンル(複数可能)、楽曲ジャンル(複数可能)、言語(複数可能)、アーティスト名(複数可能)、楽曲リリース時期)
ヒントはコメント、歌詞、楽曲情報に分類され、各分類ごとにタブを区切ることで、一度に情報が分散しないようにします。(spec/game_images/02_quiz_1_main_draft.JPG)
Homeのサムネイルに表示した代表コメント(`thumbnail_comment_id`、未指定なら先頭コメント)は、Game画面でも最初から開放して表示します。それ以外のヒントの開放状態は1回のプレイ中だけ保持し、Driftやクラウドに開放履歴を保存しません。同じクイズを開き直したときは初期状態に戻します。
game画面上の回答ボタンについて、はじめはシンプルで良いのですが、imagesにあげたような独自の回答UXを作りたいです。特にヒント情報が見たい時には邪魔になるので、下スクロールされたら画面下部に文字で集約されるのでいいですが、画面を上にスクロールした時にはimagesにあるように大きな回答ボタンを表示しましょう。
* **リザルト(result)画面**: 正解またはスキップしたらここに到達。(spec/game_images/03_result_draft.JPG)ここでは楽曲の情報を全て公開する。さらに動画や楽曲へのリンクも表示。次の問題をサジェストする。押されたらクイズプレイ画面へ。なおこの画面で、コメントや歌詞、動画、アーティストをお気に入り追加/解除できるようにする。お気に入りデータはDriftに保存し、データはDriftに保存しましょう。
* **プレイ情報(library)画面**: コメントや歌詞、動画、アーティストという各粒度でお気に入りを見れる。ここに表示するのはYouTube APIを叩く必要のないものに抑えましょう。つまりDriftに保存されている文章やIDのうち文章だけを表示し、高評価数は出しません。game画面にてコメントや歌詞、楽曲情報をタブによって仕分けたのと同様に、粒度(コメント/歌詞/楽曲名/アーティスト)を切り替えてその一覧(名前のみ)を表示し、アーティスト以外の項目はタップされると、紐づく動画の詳細情報としてresult画面に似たものを表示(spec/game_images/04_library_music_draft.JPG)。ここで必要な情報は初めてAPIを叩きましょう。
* **設定(setting)画面**: ここは未実装で良い。アカウント連携や言語、将来的なテーマ変更(デフォルトでダークモードのデザインであり、テーマ変更は今後の展望)

---

## 3. データベース設計 (スキーマ定義)

データベースの実体は**Supabase(クラウド)** と**Drift(ローカル/SQLite)** の2箇所に存在します。
YouTube側で常に変動する数値(動画の再生回数・高評価数、コメントの高評価数)は基本自前DBに一切保存せず、クイズ表示時にvideo_id/comment_idを使ってYouTube Data APIから都度取得して用意する必要があります。
データベースに問い合わせをするのは以下の時です。
- home画面に問題を表示する際: 動画IDと投稿時期と代表コメント、加えてAPIからわかる再生回数
- game画面を表示する時: quizzesのもつヒント情報と、APIからわかる再生回数や高評価数、コメントにつく高評価数
- library画面ではDriftが保持しているデータを用います。元楽曲の詳細を開く時には必要な情報をAPIで取得します。resultと同じ項目が必要になるはず
これらの関数はdartファイルのクラスで記述しましょう。なお開発初期においてSupabaseの代わりにjsonを用いる場合はAPIによって得られる情報をjsonデータベースで管理しましょう。またjsonデータを用いる初期段階でもDriftはjsonを使わずにいけると思います。
歌詞・コメント本文はいずれも「このクイズ用に選ばれた固定ヒント」として、quizzesテーブルに埋め込み(jsonb/配列)で保持します。

### 3.1. Supabase (クラウドDB)

#### ① `users` テーブル (ユーザー情報の管理)
必要な個人情報の管理についてはより一般的な実装方法があればそれを参考にすること。

```jsonc
{
   "user_id": "f353ca91-4fc5-49f2-9b9e-304f83d11914",      // uuid型 (Primary Key / Supabase Auth連動)
   "email": "test@gmail.com",                         // text型 (匿名ログイン時はnull、Gmail連携時に格納)
   "created_at": "2026-06-08T14:00:33Z",              // timestamptz型
   "favorite_videos": ["Il-an3K9pjg", "y2bVIBwpCTA"],  // text[]型 (お気に入り楽曲(動画)のID配列)
   "favorite_comments": [                             // jsonb型 (本文は持たず、参照のみ。表示時にquizzes.video_commentsから引く)
      {"video_id": "MrTz5xjmso4", "comment_id": "UgzYLJd1ADkFg4QPuOh4AaABAg"}
   ],
   "favorite_artists": ["The Jackson 5"],             // text[]型 (お気に入りのアーティスト名)
   "quiz_history": ["_G9JjpnwCVQ", "mUg5aEy-8CQ", "rSYoIuyks8g"]  // text[]型 (出題被り防止用。最新100までを保存)
}
```

#### ② `quizzes` テーブル (出題情報の管理)
```jsonc
{
   "video_id": "y2bVIBwpCTA",                          // text型 (Primary Key / YouTube動画ID / API最新値取得キーも兼ねる)
   "music_genre": ["r_and_b_soul"],                    // enum[]型 (配列: 条件絞り込み用 / クイズ詳細画面で代表的なものを常時表示 / いくつかの種類しか想定しない(2.4. 主要画面（機能）の設定画面にて記述した内容)ので、絞り込む際に楽なenum型で保存。)
   "video_genre": "musicLivePerformane",               // enum型 (条件絞り込み用 / 出題用)
   "music_title": "I Want You Back",                   // text型
   "music_artists": ["The Jackson 5"],                 // text[]型 (表記ゆれ検索はpg_trgmで対応していきたい / 出題用)
   "music_languages": ["english"],                     // enum[]型 (条件絞り込み用 / 出題用)
   "music_released_at": "1969-10-07T00:00:00Z",        // timestamptz型 (条件絞り込み用 / 出題用)
   "video_published_at": "2020-06-14T19:00:08Z",       // timestamptz型 (条件絞り込み用 / 出題用)
   "video_lyrics": [                                   // text[]型 (最大3個の歌詞。楽曲でなければnull/出題用の固定ヒント)
      "Oh, baby, give me one more chance",
      "Won't you please let me (Back in your heart)",
      "But now since I see you in his arms (I want you back)"
   ],
   "video_comments": [                                 // jsonb型 (固定ヒント。いいね数は持たず、表示時にcomment_idからAPI取得)
      {
         "comment_id": "UgzYLJd1ADkFg4QPuOh4AaABAg",
         "commented_at": "2020-07-14T10:00:08Z",
         "content": "Imagine a 10 year old sounding better than most artist today"
      },
      {
         "comment_id": "Ugy-lmxYekKinoSMZ0l4AaABAg",
         "commented_at": "2025-03-10T13:00:08Z",
         "content": "We want you back, Michael 💔\nThis world is so evil."
      }
   ],
   "embedding": null                                   // vector(384)型 (pgvector。将来のレコメンド機能用。当面NULLのまま列だけ用意)
}

```

### 3.2. Drift (スマホ内・一時キャッシュ・状態管理用)
```jsonc
{
   "user_information": {
      "user_id": "f353ca91-4fc5-49f2-9b9e-304f83d11914",    // クラウドと同期した一意の識別子
      "favorite_videos": ["Il-an3K9pjg", "y2bVIBwpCTA"],    // お気に入り楽曲配列
      "favorite_comments": [                                // お気に入りコメント配列
         {
            "video_id": "MrTz5xjmso4",
            "comment_id": "UgzYLJd1ADkFg4QPuOh4AaABAg"
         }
      ],
      "favorite_artists": ["The Jackson 5"],             // text[]型 (お気に入りのアーティスト名)
      "quiz_history": ["_G9JjpnwCVQ", "mUg5aEy-8CQ", "rSYoIuyks8g"]  // 出題履歴キャッシュ
   },
   "quiz_information": {
      "video_id": "y2bVIBwpCTA",                          // text型 (Primary Key / YouTube動画ID / API最新値取得キーも兼ねる)
      "music_genre": ["r_and_b_soul"],                    // enum[]型 (配列: 条件絞り込み用 / クイズ詳細画面で代表的なものを常時表示 / いくつかの種類しか想定しない(2.4. 主要画面（機能）の設定画面にて記述した内容)ので、絞り込む際に楽なenum型で保存。)
      "video_genre": "musicLivePerformane",               // enum型 (条件絞り込み用 / 出題用)
      "music_title": "I Want You Back",                   // text型
      "music_artists": ["The Jackson 5"],                 // text[]型 (表記ゆれ検索はpg_trgmで対応していきたい / 出題用)
      "music_languages": ["english"],                     // enum[]型 (条件絞り込み用 / 出題用)
      "music_released_at": "1969-10-07T00:00:00Z",        // timestamptz型 (条件絞り込み用 / 出題用)
      "video_published_at": "2020-06-14T19:00:08Z",       // timestamptz型 (条件絞り込み用 / 出題用)
      "video_lyrics": [                                   // text[]型 (最大3個の歌詞。楽曲でなければnull/出題用の固定ヒント)
         "Oh, baby, give me one more chance",
         "Won't you please let me (Back in your heart)",
         "But now since I see you in his arms (I want you back)"
      ],
      "video_comments": [                                 // jsonb型 (固定ヒント。いいね数は持たず、表示時にcomment_idからAPI取得)
         {
            "comment_id": "UgzYLJd1ADkFg4QPuOh4AaABAg",
            "commented_at": "2020-07-14T10:00:08Z",
            "content": "Imagine a 10 year old sounding better than most artist today",
            "favorite_count": 12000                      // YouTube APIにより得られたデータ
         },
         {
            "comment_id": "Ugy-lmxYekKinoSMZ0l4AaABAg",
            "commented_at": "2025-03-10T13:00:08Z",
            "content": "We want you back, Michael 💔\nThis world is so evil.",
            "favorite_count": 12000                      // YouTube APIにより得られたデータ
         }
      ]
   }
}
```
