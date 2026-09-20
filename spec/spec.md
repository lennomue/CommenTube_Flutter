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
| **ローカルDB** | **Drift** | お気に入り、出題履歴、オフライン表示に必要な最小限のスナップショットを端末内に保存 |
| **BaaS / クラウドDB** | **Supabase (PostgreSQL)** | 強固なPostgreSQLをベースにしたサービス。匿名認証やGmail個人認証(Auth)を構築でき、アーティストと動画の関係を中間テーブルで検索できる。内容ジャンル、年代、言語は事前定義したenumタグと配列インデックスを利用して絞り込む。またバックエンドサーバーを別途立てずに読み書きを実行できる。 |
| **リンタ/フォーマッタ** | **dart format / flutter_lints** | Flutter SDKに標準搭載 |

---

## 2. ゲーム仕様 (ゲームシステム・画面遷移)

### 2.1. コアゲームサイクル
1. ログイン手続きは行わず、ゲストとして即座に遊ぶ（裏側で端末固有でプレイログを保存しておく）。
2. 本場YouTubeアプリを開いた際と同様、ホーム画面にはブロック(サムネイル+簡易情報)が並ぶ(spec/game_images/01_home_draft.JPG)。サムネの基本デザインは全体で共通であり、中心にはクイズごとに選んだ代表ヒント（コメントまたは歌詞）が表示される。サムネの下に視聴回数と動画の投稿時期を表示。
3. 問題のブロックが押されたらその問題の詳細画面へ遷移(spec/game_images/02_quiz_1_main_draft.JPG)。
4. 問題詳細画面以降は次の2.2.回答方法を参照。GameとResultは常に最前面の1枚だけとし、縮小すると開始元のHome・Library・Artistへ戻れる。
5. Libraryからお気に入りのコメント、歌詞、アーティスト、楽曲を確認できる。Artist画面からは対象アーティストの全問題を連続して遊べる。
6. 設定については未実装で良い。

### 2.2. 回答方法（アプリ内完結型＋専用UIウィンドウ）
(spec/game_images/02_quiz_2_answering_draft_01.JPG、spec/game_images/02_quiz_2_answering_draft_02.JPG)
1. クイズ画面の回答ボタンから、Flutter製の制御外枠（閉じる、戻る・進む、URL検証ロジックを搭載）を持つWebViewウィンドウを展開。
2. WebView内のURLを追跡して、外枠下部に（`watch?v=...`）であれば「**ANSWER**」を、そうでなければ「**PLAY THE VIDEO**」を表示
3. `currentUrl()`を利用して、現在のURLから動画ID（`video_id`）を抽出し、ウィンドウを閉じながら、ローカルデータ内に持っている正解データを元に正誤判定
4. 不正解であれば全画面の演出をした上でGameへ戻る。正解またはスキップ時はResultを表示する(spec/game_images/03_result_draft.JPG)。通常は次の問題へ進み、Artistの連続クイズでは最後の問題だけ`FINISH`で開始元のArtist画面へ戻る。

### 2.3. 主要画面（機能）
* **ホーム(home)画面**: 問題ブロックが並んでいる。画面下部にはHomeとLibraryを切り替える高さを抑えたアイコンだけのフッターがあり、選択中のアイコンだけを白く塗りつぶす。(spec/game_images/01_home_draft.JPG)
game_imagesで提供したものには残念ながら入っていないが、画面の上部にクイズの対象とする楽曲の制限をタグ選択形式で絞り込むようにしましょう。
タグの種類はクイズデータが持つcontent_genresの他、言語、動画ジャンル、投稿時期です。しかし画面上部に全てのタブを入れはしません。ここは小さめに目立たない形で一部のタグを例示します。なんなら下方向スクロールされたら隠れるようにしましょう。表示するのはジャンルの代表的なJ-Popや、ロック、言語でも英語(洋楽)、日本語(邦楽)、年代として2010'だけとして、詳細設定するためのボタンが虫眼鏡デザインで並んでいるといいでしょう。
詳細設定をする際には以下のようなタグを提示して選択/解除してもらいましょう。
言語やenumデータで、投稿された年代はシンプルにposted_atから絞り込めます。
言語はいくつかしかないので、enum型ですからジャンルと同様に絞り込めますね。
* **クイズプレイ(game)画面**: 段階的に開示可能なコメント等のヒント表示、および専用WebViewを開く回答システム。youtubeのウィンドウを開くときにアプリを立ち上げないように実装する必要がある。(spec/game_images/02_quiz_1_main_draft.JPG、spec/game_images/02_quiz_2_answering_draft_01.JPG、spec/game_images/02_quiz_2_answering_draft_02.JPG)
   ヒントの種類は以下のよう。
  - 上半分に固定で表示する基本情報(再生数、高評価数、投稿時期)、内容ジャンル(代表一つ)
  - コメント(本文、投稿時期、idから導かれるいいね数)、歌詞(歌詞本文からの一部のデータを複数)、動画情報(`video_genre`、`content_genres`、言語、アーティスト名、楽曲リリース時期)
ヒントはコメント、歌詞、楽曲情報に分類され、各分類ごとにタブを区切ることで、一度に情報が分散しないようにします。(spec/game_images/02_quiz_1_main_draft.JPG)
Homeのサムネイルに表示した代表ヒント(`thumbnail_hint`)は、Game画面でも最初から開放して表示します。`thumbnail_hint.hint_type`は`comment`または`lyric`であり、前者なら`comments`、後者なら`music_lyrics`の先頭要素を使います。それ以外のヒントの開放状態は1回のプレイ中だけ保持し、Driftやクラウドに開放履歴を保存しません。同じクイズを開き直したときは初期状態に戻します。
Gameの回答ボタンは画面下部中央の丸い浮遊オブジェクトとする。ヒントを下へスクロールすると同じ中央軸上で小さくなって下へ避け、上へスクロールすると大きな表示へ戻る。上部を下へスワイプするか左上の縮小ボタンを押すとGame自体を丸い復帰オブジェクトへ縮小し、開始元の画面を操作できる。
* **リザルト(result)画面**: 正解またはスキップしたらここに到達。(spec/game_images/03_result_draft.JPG)楽曲情報を全て公開し、YouTube・共有・各音楽サービス検索、次の問題への浮遊ボタンを表示する。コメント・歌詞・楽曲・アーティストをDriftのお気に入りへ追加・解除できる。タイトル直下のアーティスト名は横スクロール可能なリンクで、押すとResultを丸い復帰オブジェクトへ縮小してArtist画面を開く。上部の下スワイプまたは左上の縮小ボタンでもResultを開始元の画面上へ縮小できる。
* **プレイ情報(library)画面**: コメント・歌詞・楽曲・アーティストを粒度別タブと検索欄で表示する。一覧ではDriftに保存した文章や名称だけを使い、YouTube API由来の数値は表示しない。コメント・歌詞・楽曲を押すとResultと同じ共通部品を使った楽曲詳細シートを表示する(spec/game_images/04_library_music_draft.JPG)。詳細内のアーティスト名を押すとシートを閉じてArtist画面を開く。
* **アーティスト(artist)画面**: HomeまたはLibraryの上に積み重なる画面で、フッターは常に残す。左上の戻る操作またはiOSの左端スワイプで手前のArtistだけを閉じ、フッターを押すと積み重なったArtistを全て閉じる。アーティストのお気に入り、全問題を順番に遊ぶボタン、代表ヒントのロゴ(コメントまたは歌詞)だけのクイズサムネイル、曲名検索と再生順・新しい順・古い順で並び替えられる楽曲一覧を持つ。
* **画面階層**: 最下層はHomeまたはLibrary、その上に0枚以上のArtist、最前面に最大1枚のGameまたはResultを置く。Game/Resultを縮小した丸い復帰オブジェクトはArtistとフッターより常に手前に表示し、押すと元のGame/Resultへ戻る。GameからResult、Resultから次のGameへ進む際は最前面の1枚を置き換え、重複して積み重ねない。
* **設定(setting)画面**: ここは未実装で良い。アカウント連携や言語、将来的なテーマ変更(デフォルトでダークモードのデザインであり、テーマ変更は今後の展望)

---

## 3. データベース設計 (スキーマ定義)

### 3.1. 必要な情報(変数)の概要

永続データベースの実体は**Supabase(クラウド)** と**Drift(ローカル/SQLite)** の2箇所に存在します。1回のプレイ中だけ必要なヒント開放状態、縮小中のGame・Result、アーティスト連続クイズの進行等は永続DBへ保存せず、画面StateまたはRiverpodのメモリで管理します。
クイズの正解単位は常にYouTube動画そのものです。同じ楽曲のMV、歌詞動画、ライブ、カバー、投稿時期の異なる動画はそれぞれ別の`quizzes`行・別の正解として扱い、お気に入り動画も共有しません。ただし、ユーザーへ関連を示すために動画同士を`videos_junction`中間テーブルで結びます。楽曲そのものを表す`works`等の共通実体は作りません。

`quizzes`は動画固有の出題情報を持つ中心テーブルです。従来`quizzes.music_artists`に入れていた情報は`artists`と`artist_videos_junction`へ、従来`quizzes.music_related_videos`に入れていた情報は`videos_junction`へ移します。項目を削除するのではなく、重複や表記揺れを避けながら同じ情報を関係として保持するための移動です。Repositoryはこれらを結合し、Flutter側へアーティスト一覧・関連動画一覧を含むクイズデータとして返します。

YouTube側で変動する動画の再生回数・高評価数、コメントの高評価数は、`video_id`または`comment_id`でYouTube Data APIから取得します。Supabaseには直近値と最終更新日をキャッシュし、月1回程度の管理処理、または最終更新から一定期間が経過した取得時に更新できる設計とします。API取得に失敗した場合は直近のキャッシュ値を表示できます。

`video_genre`は動画の形式を表し、候補は楽曲(`music_video`)、歌詞動画(`lyric_video`)、ライブ映像(`live_performance_video`)、合成MAD(`fan_made_video`)、非音楽(`non_music`)です。

`languages`は楽曲か非音楽かとは独立して、動画内で使われる言語を複数保持します。たとえば英語の会話が中心の非音楽動画も`[english]`とし、言語フィルタの対象にします。会話・歌詞・画面内テキスト等の言語表現がない動画だけは空配列とし、存在しない`none`言語を作りません。

`content_genres`は内容の分類・検索タグを複数持つ非NULL・空配列禁止の項目です。候補はJ-Pop(`j_pop`)、J-Rock(`j_rock`)、K-Pop(`k_pop`)、R&B and ソウル(`r_and_b_soul`)、アニメ&サントラ(`anime_soundtrack`)、アフリカ音楽(`afro`)、アラブ音楽(`arabic`)、インディー&オルタナティヴ(`indie_alternative`)、カントリー(`country`)、クラシック(`classical`)、ジャズ(`jazz`)、ダンス&エレクトロニック(`dance_electronic`)、ヒップホップ(`hiphop`)、ファミリー(`family`)、フォーク&アコースティック(`folk_acoustic`)、ブルース(`blues`)、ボカロ&歌い手(`vocaloid_utaite`)、ポップ(`pop`)、ボリウッド&インド音楽(`bollywood_indian`)、マンドポップ&香港ポップス(`mandopop_cantopop`)、メタル(`metal`)、ラテン(`latin`)、レゲエ&カリビアン(`reggae_caribbean`)、ロック(`rock`)、演歌・歌謡曲(`traditional_japanese_pop`)、季節の音楽(`seasonal_spring`等)、年代別(`decade_1950s`〜`decade_2010s`)、非音楽(`non_music`)です。先頭要素をGame画面上部の代表ジャンルとして表示します。合成MADでは元楽曲に対応するジャンルを持たせ、非音楽では`[non_music]`とし、日本語UIでは「その他」と表示します。

`title`も非NULLです。音楽以外では動画タイトルの主要部分を使用します。`artists`には、その動画への実質的な寄与者を登録します。音楽動画では主なバンド・作曲者・名義等を優先し、単にアップロードしただけのチャンネルは登録しません。MADではMAD制作者、非音楽では十分に寄与した演者・制作者・チャンネルを登録できます。

`thumbnail_hint`はHomeのサムネイルとGameの初期開放ヒントに使う非NULLの値です。`hint_type`は`comment`または`lyric`のenumだけを持ちます。`comment`なら`comments`の先頭要素、`lyric`なら`music_lyrics`の先頭要素を表示するため、本文を重複保存しません。選択された配列が空でないことをデータ投入時に検証します。

`meta_data`は将来のembedding生成、検索、作品をまたぐ関連候補の発見に使う補助情報です。`keywords`と`related_works`等を持つjsonbとし、クイズの正解判定や現在の画面表示には使用しません。コメントや歌詞だけでは表れにくいアニメ、映画、アルバム、シリーズ、文化的文脈等を保存できます。

### 3.2. Supabase (クラウドDB)

#### ① `users` テーブル (ユーザー情報の管理)
必要な個人情報の管理についてはより一般的な実装方法があればそれを参考にすること。

```jsonc
{
   "user_id": "f353ca91-4fc5-49f2-9b9e-304f83d11914",      // uuid型 (Primary Key / Supabase Auth連動)
   "email": "test@gmail.com",                         // text型 (匿名ログイン時はnull、Gmail連携時に格納)
   "created_at": "2026-06-08T14:00:33Z",              // timestamptz型
   "favorite_videos": ["Il-an3K9pjg", "y2bVIBwpCTA"],  // text[]型 (お気に入り楽曲(動画)のID配列)
   "favorite_comments": [                             // jsonb型 (本文は持たず、参照のみ。表示時にquizzes.commentsから引く)
      {"video_id": "MrTz5xjmso4", "comment_id": "UgzYLJd1ADkFg4QPuOh4AaABAg"}
   ],
   "favorite_artists": ["d5b25b8a-9a36-4f13-92f2-6dca44c66b51"], // uuid[]型 (artists.artist_idの配列。表示名はartistsから取得)
   "quiz_history": ["_G9JjpnwCVQ", "mUg5aEy-8CQ", "rSYoIuyks8g"]  // text[]型 (出題被り防止用。最新50までを保存)
}
```

#### ② `quizzes` テーブル (出題情報の管理)
```jsonc
{
   "video_id": "y2bVIBwpCTA",                          // text型 (Primary Key / YouTube動画ID / API最新値取得キーも兼ねる)
   "video_atmosphere_color": {"h": 140.0, "s": 0.85, "l": 0.06}, // jsonb型 (HSL。サムネイル背景等に使用)
   "content_genres": ["r_and_b_soul"],                 // content_genre[]型 (非NULL・空配列禁止。先頭が代表表示)
   "video_genre": "live_performance_video",            // video_genre型 (非NULL / 条件絞り込み用・出題用)
   "title": "I Want You Back",                         // text型 (非NULL)
   "languages": ["english"],                           // language[]型 (非NULL / 条件絞り込み用・出題用)
   "posted_at": "2020-06-14T19:00:08Z",                // timestamptz型 (非NULL / 条件絞り込み・新着順用。YouTubeの公開日時を失わない)
   "video_favorite_count": 450000,                      // bigint型 (YouTube APIによる直近の動画高評価数キャッシュ)
   "video_view_count": 130000000,                       // bigint型 (YouTube APIによる直近の再生数キャッシュ)
   "video_favorite_count_last_updated_at": "2026-09-14", // date型
   "video_view_count_last_updated_at": "2026-09-14",     // date型
   "music_released_at": {                               // 論理表現。物理DBではdate列とprecision列に分ける。非音楽等ではnull
      "precision": "day",                              // date_precision型: year / month / day
      "date": "1969-10-07"                             // date型
   },
   "thumbnail_hint": {                                  // jsonb型 (非NULL / Home表示・Game初期開放)
      "hint_type": "comment"                           // thumbnail_hint_type型: comment / lyric。対応配列の先頭要素を使う
   },
   "music_lyrics": [                                   // text[]型 (最大3個の歌詞 / 非音楽ではnull)
      "Oh, baby, give me one more chance",
      "Won't you please let me (Back in your heart)",
      "But now since I see you in his arms (I want you back)"
   ],
   "comments": [                                       // jsonb型 (固定コメントヒント。本文・ID・投稿時期・評価数キャッシュを保持)
      {
         "comment_id": "UgzYLJd1ADkFg4QPuOh4AaABAg",
         "commented_at": "2020-07-14T10:00:08Z",
         "content": "Imagine a 10 year old sounding better than most artist today",
         "comment_favorite_count": 12000,
         "comment_favorite_count_last_updated_at": "2026-09-14"
      },
      {
         "comment_id": "Ugy-lmxYekKinoSMZ0l4AaABAg",
         "commented_at": "2025-03-10T13:00:08Z",
         "content": "We want you back, Michael 💔\nThis world is so evil.",
         "comment_favorite_count": 12000,
         "comment_favorite_count_last_updated_at": "2026-09-14"
      }
   ],
   "meta_data": {                                      // jsonb型 (検索・関連候補・将来のembedding生成用。画面には直接表示しない)
      "keywords": ["Motown", "Jackson family", "live performance"],
      "related_works": []
   },
   "embedding": null                                   // vector(384)型 (将来のレコメンド機能用。当面NULL)
}

```

`music_released_at`はFlutter・JSONでの論理表現です。PostgreSQLではJSONBに日付文字列を埋めず、比較・並べ替えを容易にするため、`music_released_date date`と`music_released_precision date_precision`の2列で保存します。年だけ判明している場合は、たとえば`1969-01-01`と`year`を保存し、UIでは1969年だけを表示します。年月までなら日を1として`month`を保存します。完全に不明な場合は両方をNULLにします。ライブなら演奏日、カバーならそのカバー版の初出日、それ以外なら原曲のリリース時期を使います。

#### ③ `artists` テーブル (アーティスト・制作者情報)

```jsonc
{
   "artist_id": "d5b25b8a-9a36-4f13-92f2-6dca44c66b51", // uuid型 (Primary Key)
   "name": "The Jackson 5",                              // text型 (非NULL / UIに表示する現在の代表名)
   "sub_names": ["Jackson 5", "ジャクソン5"]             // text[]型 (非NULL、既定値[] / 検索専用でUIには表示しない)
}
```

`sub_names`には旧名、愛称、別言語表記、一般的な別表記を入れます。`pg_trgm`は同じ文字列内の曖昧一致には利用できますが、日本語名と英語名のような翻訳関係そのものは判断できないため、検索対象にしたい別言語表記は`sub_names`へ明示的に登録します。将来、別名ごとの言語や種類を管理する必要が生じた場合のみ別名テーブルへ分離します。

音楽動画では、主なバンド、作曲者、演者、名義等、その動画内容に関係するものを登録します。投稿チャンネルが単にアップロードしただけなら登録しません。MAD制作者や、非音楽動画で十分に寄与している演者・制作者・チャンネルは登録対象です。

#### ④ `artist_videos_junction` テーブル (アーティストと動画の中間テーブル)

```jsonc
{
   "artist_id": "d5b25b8a-9a36-4f13-92f2-6dca44c66b51", // uuid型 (Foreign Key -> artists.artist_id)
   "video_id": "y2bVIBwpCTA"                            // text型 (Foreign Key -> quizzes.video_id)
}
```

1組の`artist_id`と`video_id`につき1行だけ登録し、複合主キーは`(artist_id, video_id)`とします。中間テーブルには関係だけを保存し、表示順を固定する`display_order`は持ちません。

アーティストIDを指定すると、そのIDを持つ全行の`video_id`を一覧として取得できます。逆に動画IDを指定すると、その動画に関係する全アーティストを取得できます。主キーは重複登録の防止と外部キー参照のために使われ、検索は列条件で行います。両方向を効率よく検索できるよう、複合主キーとは別に`video_id`にもインデックスを作成します。

Artist画面の楽曲順は中間テーブルへ保存せず、取得した動画IDを`quizzes`へ結合した後、再生回数順なら`video_view_count`、新しい順・古い順なら`posted_at`で並べ替えます。複数アーティストをResult内で表示する順序には意味を持たせず、必要なら`artists.name`等で安定した順序へ並べます。

#### ⑤ `videos_junction` テーブル (動画同士の無方向な関連)

```jsonc
{
   "video_id_a": "UvynvnxZJ3Q",                         // text型 (Foreign Key -> quizzes.video_id)
   "video_id_b": "y2bVIBwpCTA",                         // text型 (Foreign Key -> quizzes.video_id)
   "relation_type": "same_music"                        // video_relation_type型: same_music / seriese / cover / part_of
}
```

各行は動画を頂点、行そのものを辺とする単純な無向グラフの1辺です。`video_id_a`と`video_id_b`の順番に意味はなく、動画の投稿時期やDBへの追加時期とも無関係です。登録時に動画IDを一定の比較順へ正規化し、`video_id_a < video_id_b`、`video_id_a <> video_id_b`、複合主キー`(video_id_a, video_id_b)`を制約として、A-BとB-Aの二重登録や自己参照を防ぎます。動画IDを片方に指定すれば、反対側にあるすべての関連動画IDを取得できる読み取り用ビューも用意します。

`relation_type`の意味は次のとおりです。どちらも方向を持ちません。

- `same_music`: 歌詞動画とMV、ライブ、投稿時期違い等、同じ楽曲に関連する別動画。同じ人が歌唱に関わるものはこれに該当するが、完全に別の人だけで歌っているものは`cover`に該当する。
- `seriese`: 同一作品(アニメや映画)によって紐づく楽曲。または歌詞が少しだけ違うバージョン違いなど
- `cover`: 同じ曲であるが、別の方の歌唱/演奏であるもの
- `part_of`: 合成MADや複数楽曲演奏を構成する元楽曲の代表動画との関係。

MADや複数楽曲演奏を追加するときは、元楽曲ごとに最も代表的な動画を1つ選びます。その動画が`quizzes`に存在しなければ、先に独立したクイズデータとして追加してから`part_of`で結びます。この方法では、後から同じ楽曲の動画が追加されても、既存MADとの辺をすべて張り直す必要はありません。

`seriese`は、同じアニメ・映画・企画に属する別楽曲や、「東京サマーセッション」と「東京ウインターセッション」のように物語・登場人物・企画が連続する動画を結ぶために使います。単なる同一アーティストという理由だけでは結びません。

### 3.3. Drift (スマホ内・一時キャッシュ・状態管理用)

Driftはお気に入り、出題被りを避けるための履歴、および画面を再表示するための必要最小限のスナップショットを保持します。ヒントの開放履歴は保存しません。Supabaseの全データを恒久的に複製する場所ではなく、Supabaseまたは開発中のJSONが正本です。

お気に入りは動画・コメント・アーティストごとの行として保持します。アーティストは`artist_id`を識別子にし、オフライン表示用に取得時点の`name`もスナップショットとして保存します。コメントも`video_id + comment_id`を識別子にし、LibraryでAPIなしに表示できるよう本文を保存します。`quiz_history`は動画IDと回答時刻を最大50件まで持つ出題制御用であり、ヒント開放履歴とは別物です。

Repositoryが画面へ返す論理的なクイズデータは次の形です。Supabaseで別テーブルへ移したアーティストと関連動画は、取得時に結合して一覧へ戻すため、従来画面が必要としていた情報は失われません。

```jsonc
{
   "user_information": {
      "user_id": "f353ca91-4fc5-49f2-9b9e-304f83d11914",
      "favorite_videos": ["Il-an3K9pjg", "y2bVIBwpCTA"],
      "favorite_comments": [
         {
            "video_id": "MrTz5xjmso4",
            "comment_id": "UgzYLJd1ADkFg4QPuOh4AaABAg",
            "content": "Libraryで表示するコメント本文のスナップショット"
         }
      ],
      "favorite_artists": [
         {
            "artist_id": "d5b25b8a-9a36-4f13-92f2-6dca44c66b51",
            "name": "The Jackson 5"
         }
      ],
      "quiz_history": ["_G9JjpnwCVQ", "mUg5aEy-8CQ", "rSYoIuyks8g"]
   },
   "quiz_information": {
      "video_id": "y2bVIBwpCTA",
      "video_atmosphere_color": {"h": 140.0, "s": 0.85, "l": 0.06},
      "content_genres": ["r_and_b_soul"],
      "video_genre": "live_performance_video",
      "title": "I Want You Back",
      "languages": ["english"],
      "posted_at": "2020-06-14T19:00:08Z",
      "video_favorite_count": 450000,
      "video_view_count": 130000000,
      "video_favorite_count_last_updated_at": "2026-09-14",
      "video_view_count_last_updated_at": "2026-09-14",
      "music_released_at": {
         "precision": "day",
         "date": "1969-10-07"
      },
      "thumbnail_hint": {
         "hint_type": "comment"
      },
      "artists": [
         {
            "artist_id": "d5b25b8a-9a36-4f13-92f2-6dca44c66b51",
            "name": "The Jackson 5",
            "sub_names": ["Jackson 5", "ジャクソン5"]
         }
      ],
      "related_videos": [
         {
            "video_id": "UvynvnxZJ3Q",
            "relation_type": "same_music"
         }
      ],
      "music_lyrics": [
         "Oh, baby, give me one more chance",
         "Won't you please let me (Back in your heart)",
         "But now since I see you in his arms (I want you back)"
      ],
      "comments": [
         {
            "comment_id": "UgzYLJd1ADkFg4QPuOh4AaABAg",
            "commented_at": "2020-07-14T10:00:08Z",
            "content": "Imagine a 10 year old sounding better than most artist today",
            "comment_favorite_count": 12000,
            "comment_favorite_count_last_updated_at": "2026-09-14"
         }
      ],
      "meta_data": {
         "keywords": ["Motown", "Jackson family", "live performance"],
         "related_works": []
      }
   }
}
```

開発中のモックJSONでも同じ関係を再現するため、`quizzes.json`、`artists.json`、`artist_videos_junction.json`、`videos_junction.json`を別ファイルとして持ち、Repositoryで結合します。YouTube API由来の可変値は`youtube_api_mock.json`に分離します。Supabase移行後もRepositoryが返す論理モデルを維持し、画面側のデータ取得方法を変更しないことを原則とします。

### 3.4. 永続DB・Riverpod・画面Stateの役割分担

データの寿命に応じて管理場所を次のように分けます。

| 管理対象 | 管理場所 | アプリ再起動後 | 主な役割 |
|---|---|---|---|
| クイズ・アーティスト・関連動画・統計キャッシュ | Supabase（開発中はJSON） | 残る | 全ユーザー共通の正本 |
| お気に入り、最大50件の出題履歴 | Drift | 残る | 端末固有のユーザーデータ |
| Repositoryが結合済みのクイズ一覧 | Riverpod/FutureとRepositoryのメモリキャッシュ | 消える | 同一起動中の重複JSON・DBアクセスを避ける |
| 縮小中のGame・Result | Riverpod | 消える | Home・Library・Artistを操作中に前面体験を復元する |
| アーティスト連続クイズの対象動画と現在位置 | Riverpod | 消える | 複数画面から参照する1回限りのセッション |
| Homeのフィルタ、検索文字、タブ、スクロール位置 | 各画面のState | 消える | その画面だけで必要なUI状態 |
| Gameのヒント開放状態、回答演出、回答ボタン縮退状態 | Game画面のState | 消える | 1回のプレイだけで有効な状態 |

Riverpodに置くのは複数画面・共通ナビゲーションから参照する起動中だけの状態です。画面内部だけで完結する状態は各WidgetのStateに置きます。アプリ終了後にも必要なものだけをDriftへ保存し、ヒント開放状態は保存しません。Hot Reloadでは通常メモリ状態も維持されますが、Hot Restartまたはアプリプロセスの終了ではRiverpodと画面Stateが初期化され、Driftは維持されます。
