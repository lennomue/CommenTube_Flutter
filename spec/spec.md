# CommenTube基本設計書

> このファイルは2026-09-25時点の実装と確定仕様だけを記す正本です。過去の案、変更理由、実装順、未完了作業は`plan.md`へ記録し、このファイルには廃止済み仕様を残しません。

YouTubeの動画、特に公式のミュージックビデオを中心としてmeme動画(ネタ動画やMAD動画)をも対象とし、それらにつくコメントなどのヒント(楽曲の動画ならばこれに歌詞やアーティスト、楽曲情報)をプレイヤーに提供し、元動画を回答するゲーム。初めはヒントを隠し、ユーザーはヒントを解放しながら回答をする。スマホ向けアプリとして開発する。
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
2. 本場YouTubeアプリを開いた際と同様、ホーム画面にはブロック(サムネイル+簡易情報)が並ぶ(`spec/game_images/01_home_draft.JPG`)。サムネの基本デザインは全体で共通であり、上部は黒を基調としてクイズごとに選んだ代表ヒント（コメントまたは歌詞）の領域だけを白背景にする(`spec/game_images/home_thumbnail.jpg`)。下部は`video_atmosphere_color`に基づく色を使い、視聴回数と動画の投稿時期を表示する。
3. 問題のブロックが押されたらその問題の詳細画面へ遷移(`spec/game_images/02_quiz_1_main_draft.JPG`)。
4. 問題詳細画面以降は次の2.2.回答方法を参照。GameとResultは常に最前面の1枚だけとし、縮小すると開始元のHome・Library・Artistへ戻れる。
5. Libraryにはfavoriteとplaylistのページを持つ。
6. Library-favoriteではお気に入りのコメント、歌詞、アーティスト、作品を確認できる。Artist画面からは対象アーティストの全問題を順番またはシャッフルで連続して遊べる。
7. Library-playlistでは自分で作った再生リストや保存した公開されたプレイリストから遊べる。
8. 設定については未実装で良い。

### 2.2. 回答方法（アプリ内完結型＋専用UIウィンドウ）
(spec/game_images/02_quiz_2_answering_draft_01.JPG、spec/game_images/02_quiz_2_answering_draft_02.JPG)
1. クイズ画面下部の丸い回答オブジェクトを上へスワイプすると、指に追従して白い円が上昇・拡大し、検索入力欄とYouTube記号を段階的に表示してキーボードへフォーカスする（`game_images/game_answer.jpg`、`game_answer_input_01.jpg`、`game_answer_input_02.jpg`）。キーボード表示で画面の高さが縮まり上部情報ブロックと重なった場合も、回答円をGame内の最前面に描画する。空白以外を1文字以上入力するとYouTube記号を赤く有効化し、押すとその文字列を`search_query`にしたYouTube検索結果を、Flutter製の制御外枠（閉じる、戻る・進む、URL検証ロジックを搭載）を持つWebViewウィンドウで展開する。展開中の円外タップまたは円の下スワイプは入力を破棄して通常の回答ボタンへ戻す。
2. WebView内のURLを追跡して、外枠下部に（`watch?v=...`）であれば「**ANSWER**」を、そうでなければ「**PLAY THE VIDEO**」を表示
3. `currentUrl()`を利用して、現在のURLから動画ID（`video_id`）を抽出し、ウィンドウを閉じながら、ローカルデータ内に持っている正解データを元に正誤判定
4. 不正解であれば全画面の演出を約1.5秒表示してGameへ戻る。正解またはスキップ時はResultを右から表示する(spec/game_images/03_result_draft.JPG)。Resultの`NEXT QUIZ`または`FINISH`ブロックは上方向へスワイプして確定する。通常は長方形の中央上部だけを盛り上げ、その中の`^`を「つまみ」とする。ブロックは画面下端へ密着させず少し上へ浮かせ、ラベルは長方形の高さ中央に置く。ドラッグ中は下端を固定したまま上端を引いた距離だけ伸ばし、ラベルも伸長後の長方形の高さ中央へ連動して移動する。`NEXT QUIZ`では次のGameを画面下から表示し、`FINISH`ではResult全体を上へスライドして消す。

### 2.3. 主要画面（機能）
* **ホーム(home)画面**: 30件以上の候補から1回につき10問をランダムに表示し、Driftのクイズ開始履歴にない新規問題を優先する。上端から引いて再読み込みすると抽選し直す。新規問題はカード外周をネオンレッドとブルーのグラデーション線で囲み、白く輝くアクセントを加える。既出は従来の色のない外周とする。画面下部にはHomeとLibraryを切り替える高さを抑えたフッターがあり、アイコン下に小さく`HOME`・`LIBRARY`と表示する。選択中のアイコンと文字は白、未選択は灰色とする。Homeの最上位画面で選択中のHomeボタンをもう一度押した場合は、一覧の先頭へ滑らかに戻す。(spec/game_images/01_home_draft.JPG)
game_imagesで提供したものには残念ながら入っていないが、画面の上部にクイズの対象とする楽曲の制限をタグ選択形式で絞り込むようにしましょう。
タグの種類はクイズデータが持つcontent_genresの他、言語、動画ジャンル、投稿時期です。しかし画面上部に全てのタブを入れはしません。ここは小さめに目立たない形で一部のタグを例示します。なんなら下方向スクロールされたら隠れるようにしましょう。表示するのはジャンルの代表的なJ-Popや、ロック、言語でも英語(洋楽)、日本語(邦楽)、年代として2010'だけとして、詳細設定するためのボタンが虫眼鏡デザインで並んでいるといいでしょう。
詳細設定をする際には以下のようなタグを提示して選択/解除してもらいましょう。詳細シート内の変更は即座にHomeへ反映し、確定ボタンを使わず下スワイプ等で閉じても選択状態を保持する。右上の検索から作品名、アーティスト名・別名、`meta_data`、プレイリスト名を横断検索する。検索対象はHomeへ抽選済みの10〜20件ではなく、開発中は全JSON、Supabase移行後は`quizzes`・`artists`・プレイリストの正本全体とする。検索結果では履歴による除外や未プレイ優先を行わない。結果はアーティスト本体、作品タイトル一致、アーティスト名一致の作品、メタ情報一致の作品、プレイリストの順を基本とし、アーティスト名と一致したときにArtistが作品へ埋もれないようにする。該当Artist行の直下には、Artist画面と同じ順番再生の「▶[アーティスト名]のクイズを始める」と独立したシャッフルボタンを置く。検索画面はHomeブランチの子画面としてフッターを残し、Artistを押した場合も検索の上へ積み重ねてフッターを維持する。Home/Libraryボタンでは検索およびその上のArtistを閉じて選択先へ移動する。上部は黒、検索窓だけは灰色を許容し、縮小中のGame/Result復帰オブジェクトは検索結果より常に手前へ表示する。検索欄にフォーカスがある間は左上ボタンで画面を閉じず、キーボードとフォーカスだけを外す。現在は文字列の部分一致とし、将来は各データの`embedding`を使うベクトル検索へ置き換える。
言語やenumデータで、投稿された年代はシンプルにposted_atから絞り込めます。
言語はいくつかしかないので、enum型ですからジャンルと同様に絞り込めますね。
詳細絞り込みの動画ジャンルには`release`（楽曲）を含め、投稿年スライダーはYouTube開始年に合わせて2005年以降を範囲とする。この共通シートはHome、Libraryのお気に入り作品、Artistの作品で同じ条件を使う。
* **クイズプレイ(game)画面**: 段階的に開示可能なコメント等のヒント表示、および専用WebViewを開く回答システム。youtubeのウィンドウを開くときにアプリを立ち上げないように実装する必要がある。(spec/game_images/02_quiz_1_main_draft.JPG、spec/game_images/02_quiz_2_answering_draft_01.JPG、spec/game_images/02_quiz_2_answering_draft_02.JPG)
   ヒントの種類は以下のよう。
  - 上半分に固定で表示する基本情報(再生数、高評価数、投稿時期)、内容ジャンル(代表一つ)
  - コメント(本文、投稿時期、idから導かれるいいね数)、歌詞(歌詞本文からの一部のデータを複数)、動画情報(`video_genre`、`content_genres`、言語、アーティスト名、楽曲リリース時期)
ヒントはコメント、歌詞、作品情報に分類され、各分類ごとにタブを区切ることで、一度に情報が分散しないようにします。(spec/game_images/02_quiz_1_main_draft.JPG)
Homeのサムネイルに表示した代表ヒントは、Game画面でも最初から開放して表示します。`thumbnail_hint_type`は`comment`または`lyric`であり、前者なら`comments`、後者なら`music_lyrics`の先頭要素を使います。`lyric`のクイズではGame開始時に歌詞タブを開きます。それ以外のヒントの開放状態は1回のプレイ中だけ保持し、Driftやクラウドに開放履歴を保存しません。同じクイズを開き直したときは初期状態に戻します。
Gameの回答ボタンは画面下部中央の丸い浮遊オブジェクトとする。閉じた通常状態では`ANSWER`を円の中央に置き、`^`をその上へ置く。ヒントの下スクロールで小さくなった円は`^`だけを中央に表示し、通常円と下端を揃える。スキップ円も回答円と下端を揃え、右余白は下余白と同程度にする。上スワイプで開く円は通常時の約2.5倍の直径（以前の試作比で半径約1.5倍）まで拡大し、中心位置を大きく動かさず入力領域を広げる。回答円は本文ではなくGame全体の重なり順で最前面とし、キーボード表示時にも上部ブロックの背面へ隠さない。回答検索の透明な内部UIは閉じた円でレイアウトせず、展開中は円の大きさに収まるよう段階的に拡大してoverflowを防ぐ。ヒントを下へスクロールすると同じ中央軸上で小さくなって下へ避け、上へスクロールすると大きな表示へ戻る。一方、コメント・歌詞・作品情報のタブは通常の本文スクロールでは隠さず上部に固定する。上部を下へスワイプするか左上の縮小ボタンを押すと同じ縮小演出を開始し、開始元の画面を操作できる。縮小中は背景の開始元画面を暗いマスク越しに表示し、進行に応じてマスクを透明化する。ヘッダーとヒントタブは右端を画面右端に揃えて縮小しながら下へ移動し、ヒント本文と浮遊ボタンは下へ移動しつつ先にフェードアウトする。新規問題では選択タブの下端全幅をHomeと同じネオンレッド・白・ブルーのグラデーション線にし、既出問題では白線とする。iOSの左端スワイプではGameを閉じない。
* **リザルト(result)画面**: 正解またはスキップしたらここに到達。(spec/game_images/03_result_draft.JPG)作品情報を全て公開し、YouTube・共有・各音楽サービス検索、次の問題へのスワイプブロックを表示する。コメント・歌詞・作品・アーティストをDriftのお気に入りへ追加・解除でき、作品のお気に入りボタン右には再生リスト追加ボタンを置く。コメント等のタブ下線をタブ領域の実際の最下端に置き、直下の内容との間に意図しない空白を作らない。関連動画はGameのヒントには使わず、ResultとLibraryの作品詳細にある関連タブだけで表示する。表示順は同じ曲(`same_music`)、シリーズ(`seriese`)、カバー(`cover`)、MAD・構成元(`part_of`)とし、該当動画のない種類は見出しごと表示しない。未出題の関連作品は行の下を薄い青線にする。タイトル直下のアーティスト名は横スクロール可能なリンクで、押すとResultを丸い復帰オブジェクトへ縮小してArtist画面を開く。上部の下スワイプまたは左上の縮小ボタンでもResultを開始元の画面上へ縮小でき、左端スワイプでは閉じない。
* **プレイ情報(library)画面**: タイトル右のハートとブックマークで、お気に入り画面と再生リスト画面を切り替える。お気に入りではコメント・歌詞・作品・アーティスト・履歴を粒度別タブと検索欄で表示し、検索欄の上に左の「お気に入りでクイズ」と右の独立したシャッフル記号を置く。作品タブはHomeと同じ詳細絞り込み、再生順・新しい順・古い順、三点メニューを同じ高さに配置する。三点メニューの「まとめて再生リストに追加する」は、現在の絞り込み結果を現在の並び順のまま追加先選択シートへ渡す。履歴は最近50件のタイトル、再生数、高評価数、プレイからの経過時間を表示し、押すとその動画のGameを開始する。コメント・歌詞・作品を押すとResultと同じ共通部品を使った作品詳細シートを表示する(spec/game_images/04_library_music_draft.JPG)。再生リスト側は初期状態を絞り込みなしとしてマイプレイリストと保存したプレイリストを同じ一覧に表示し、`マイプレイリスト`、`保存したプレイリスト`、`関連`タグで切り替える。並び順は操作時刻が新しい順とする。選択中の`マイプレイリスト`または`保存したプレイリスト`タグはもう一度押して解除でき、その場合も両方を同じ一覧に表示する。お気に入り作品はFavoriteデータと上記シャッフル出題で扱い、重複する「お気に入り」プレイリストは作らない。マイプレイリスト末尾には新規作成、その下には関連する公開プレイリスト候補を最大3件表示する。関連する公開プレイリストを端末へ複製する操作名は「プレイリストを保存」とする。関連する公開プレイリストを押すと所有者のプレイリストと同じ詳細画面を読み取り専用で開き、編集操作だけを出さない。モック段階の関連順は、最近操作した端末内プレイリストと公開リストのアーティスト・内容ジャンルの重複数で決め、同点なら公開リストの更新時刻順とする。将来は`embedding`類似度へ置き換える。
* **アーティスト(artist)画面**: HomeまたはLibraryの上に積み重なる画面で、フッターは常に残す。左上の戻る操作またはiOSの左端スワイプで手前のArtistだけを閉じ、フッターを押すと積み重なったArtistを全て閉じる。アーティストのお気に入り、全問題の順番・シャッフル再生、代表ヒントと`video_atmosphere_color`で表現するクイズ一覧を持つ。タブは`クイズ`、`作品`、`関連`で、作品行はPlaylistと同じ共通部品・余白を使い、行間の白い区切り線は表示しない。作品タブの絞り込み・並び順・一括プレイリスト追加はLibraryのお気に入り作品タブと同じ共通UI・挙動にする。関連には`artists_junction`で結んだ同一人物・グループ等を表示する。
* **再生リスト(playlist)画面**: Artistと同様にHomeまたはLibraryの上に積み重なる。名前、説明、連続・シャッフルクイズ、クイズ・作品タブ、メタデータ編集、削除、共有を持つ。所有者は作品タブの編集モードで、赤い削除、複数選択、まとめてドラッグ移動、選択順に並べる、別のプレイリストへ移動、すべて選択、選択解除、完了前の取り消しを使える。編集開始時は画面上部の通常情報、共通フッター、縮小中Game/Resultの丸い復帰オブジェクトを隠し、作品一覧を全画面化して選択管理ブロックを一覧上端へ固定する。選択管理ブロックは1段目に小さい選択数・目立たない全選択・選択解除、2段目にまとめて移動・別プレイリストへ移動、3段目に選択順に並べる・実行を置く。未選択時は全作品にグリップを表示する。最初の選択時に「まとめて移動」を既定モードとし、最初に選んだ作品だけにグリップを残し、2件目以降の選択作品は薄く表示する。「選択順に並べる」では全グリップを隠し、2件目以降を同様に薄くする。「別のプレイリストへ移動」の実行時は追加先選択シートを表示し、選択順を保って追加後に元リストから削除する。まとめて移動時だけ実行を無効とし、有効な実行は太枠で示す。編集モード中に作品行を押してもGameへ遷移しない。他ユーザーの公開リストは同じ画面を読み取り専用で再利用し、JSONモックから表示して保存すると`source_playlist_id`を持つ端末内コピーを作る。
* **画面階層**: 最下層はHomeまたはLibrary、その上に0枚以上のArtistまたはPlaylist、最前面に最大1枚のGameまたはResultを置く。Game/Resultを縮小した丸い復帰オブジェクトはArtist・Playlistとフッターより常に手前に表示し、押すと縮小時の逆アニメーションで復元する。GameからResultは右から、Resultから次のGameは下から表示し、最前面の1枚を置き換えて重複して積み重ねない。
* **設定(setting)画面**: ここは未実装で良い。アカウント連携や言語、将来的なテーマ変更(デフォルトでダークモードのデザインであり、テーマ変更は今後の展望)

### 2.4. 検索候補の今後の実装計画

検索候補は外部の一般検索プラグインへ依存せず、CommenTubeの正本DBに合わせた`SearchSuggestionRepository`を用意します。入力フォーカス中かつ2文字程度入力された後、250〜300msのdebounceを挟み、正規化した前方一致を優先して最大8件程度を返します。候補辞書は`quizzes.title`、`artists.name`、`artists.sub_names`、公開・保存プレイリスト名、`meta_data.keywords`から構成し、候補には種別と遷移先IDを持たせます。

Supabase移行後の検索と候補取得はHomeフィード用の取得結果を再利用せず、検索語を引数にしたRPCまたは専用Repositoryから`quizzes`・`artists`・プレイリストへ問い合わせます。初期順位は完全一致、前方一致、部分一致の順とし、同順位では人気度や更新時刻を補助値にします。将来は端末内の検索履歴をDriftへ保存して本人の過去検索を上位へ混ぜますが、履歴をクラウド共有しません。候補選択と検索確定は同じ正規化・順位規則を利用し、将来embedding検索を追加しても画面は`SearchSuggestionRepository`と`SearchRepository`のインターフェースを保ちます。

---

## 3. データベース設計 (スキーマ定義)

### 3.1. 必要な情報(変数)の概要

永続データベースの実体は**Supabase(クラウド)** と**Drift(ローカル/SQLite)** の2箇所に存在します。1回のプレイ中だけ必要なヒント開放状態、縮小中のGame・Result、アーティスト連続クイズの進行等は永続DBへ保存せず、画面StateまたはRiverpodのメモリで管理します。
クイズの正解単位は常にYouTube動画そのものです。同じ楽曲のMV、歌詞動画、ライブ、カバー、投稿時期の異なる動画はそれぞれ別の`quizzes`行・別の正解として扱い、お気に入り動画も共有しません。ただし、ユーザーへ関連を示すために動画同士を`videos_junction`中間テーブルで結びます。楽曲そのものを表す`works`等の共通実体は作りません。

`quizzes`は動画固有の出題情報を持つ中心テーブルです。従来`quizzes.music_artists`に入れていた情報は`artists`と`artist_videos_junction`へ、従来`quizzes.music_related_videos`に入れていた情報は`videos_junction`へ移します。項目を削除するのではなく、重複や表記揺れを避けながら同じ情報を関係として保持するための移動です。Repositoryはこれらを結合し、Flutter側へアーティスト一覧・関連動画一覧を含むクイズデータとして返します。

YouTube側で変動する動画の再生回数・高評価数、コメントの高評価数は、`video_id`または`comment_id`でYouTube Data APIから取得します。Supabaseには直近値と最終更新日をキャッシュし、月1回程度の管理処理、または最終更新から一定期間が経過した取得時に更新できる設計とします。API取得に失敗した場合は直近のキャッシュ値を表示できます。

`video_genre`は動画の形式を表し、候補は楽曲(`release`)、ミュージックビデオ(`music_video`)、カバー動画(`cover_video`)、歌詞動画(`lyric_video`)、ライブ映像(`live_performance_video`)、合成MAD(`fan_made_video`)、その他(`non_music`)です。

`languages`は楽曲か非音楽かとは独立して、動画内で使われる言語を複数保持します。たとえば英語の会話が中心の非音楽動画も`[english]`とし、言語フィルタの対象にします。会話・歌詞・画面内テキスト等の言語表現がない動画だけは空配列とし、存在しない`none`言語を作りません。

`content_genres`は内容の分類・検索タグを複数持つ非NULL・空配列禁止の項目です。候補はJ-Pop(`j_pop`)、J-Rock(`j_rock`)、K-Pop(`k_pop`)、R&B and ソウル(`r_and_b_soul`)、アニメ&サントラ(`anime_soundtrack`)、アフリカ音楽(`afro`)、アラブ音楽(`arabic`)、インディー&オルタナティヴ(`indie_alternative`)、カントリー(`country`)、クラシック(`classical`)、ジャズ(`jazz`)、ダンス&エレクトロニック(`dance_electronic`)、ヒップホップ(`hiphop`)、ファミリー(`family`)、フォーク&アコースティック(`folk_acoustic`)、ブルース(`blues`)、ボカロ&歌い手(`vocaloid_utaite`)、ポップ(`pop`)、ボリウッド&インド音楽(`bollywood_indian`)、マンドポップ&香港ポップス(`mandopop_cantopop`)、メタル(`metal`)、ラテン(`latin`)、レゲエ&カリビアン(`reggae_caribbean`)、ロック(`rock`)、演歌・歌謡曲(`traditional_japanese_pop`)、季節の音楽(`seasonal_spring`等)、年代別(`decade_1950s`〜`decade_2010s`)、合成MAD(`fan_made_video`)、非音楽(`non_music`)です。先頭要素をGame画面上部の代表ジャンルとして表示します。`video_genre`が`fan_made_video`の場合は元楽曲に対応するジャンルをそのまま保持し、追加で`fan_made_video`を必ず含めます。`video_genre`が`non_music`の場合は`non_music`を必ず含め、日本語UIでは「その他」と表示します。

`title`も非NULLです。音楽以外では動画タイトルの主要部分を使用します。`artists`には、その動画への実質的な寄与者を登録します。音楽動画では主なバンド・作曲者・名義等を優先し、単にアップロードしただけのチャンネルは登録しません。MADではMAD制作者、非音楽では十分に寄与した演者・制作者・チャンネルを登録できます。

`thumbnail_hint_type`はHomeのサムネイルとGameの初期開放ヒントに使う非NULLのenum列で、`comment`または`lyric`を持ちます。`comment`なら`comments`の先頭要素、`lyric`なら`music_lyrics`の先頭要素を表示するため、本文を重複保存しません。`comments`は人が最終採用した1〜8件を表示順に保持します。選択された配列が空でないことと、コメントが8件を超えないことをデータ投入時に検証します。

`meta_data`は将来のembedding生成、文字検索、作品をまたぐ関連候補の発見に使う補助情報です。`keywords`と`related_works`等を持つjsonbとし、クイズの正解判定や画面への直接表示には使用しません。現在の検索ではJSON内の文字列を平坦化して部分一致の対象にします。コメントや歌詞だけでは表れにくいアニメ、映画、アルバム、シリーズ、文化的文脈等を保存できます。

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
   "thumbnail_hint_type": "comment",                   // thumbnail_hint_type型: (非NULL / comment / lyric)、対応配列の先頭要素を使う
   "music_lyrics": [                                   // text[]型 (最大3個の歌詞 / 非音楽ではnull)
      "Oh, baby, give me one more chance",
      "Won't you please let me (Back in your heart)",
      "But now since I see you in his arms (I want you back)"
   ],
   "comments": [                                       // jsonb型 (1〜8件の固定コメントヒント。本文・ID・投稿時期・評価数キャッシュを表示順に保持)
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
   "meta_data": {                                      // jsonb型 (文字検索・関連候補・将来のembedding生成用。画面には直接表示しない)
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
   "sub_names": ["Jackson 5", "ジャクソン5"],            // text[]型 (非NULL、既定値[] / 検索専用でUIには表示しない)
   "embedding": null                                      // vector(384)型 (将来の検索・関連候補用。当面NULL)
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

Artist画面の作品順は中間テーブルへ保存せず、取得した動画IDを`quizzes`へ結合した後に、画面で選択された再生順・新しい順・古い順で並べます。複数アーティストをResult内で表示する順序にも意味を持たせず、必要なら`artists.name`等で安定した順序へ並べます。

#### ⑤ `artists_junction` テーブル (アーティスト同士の無方向な関連)

```jsonc
{
   "artist_id_a": "00000000-0000-4000-8000-000000000001", // uuid型 (Foreign Key -> artists.artist_id)
   "artist_id_b": "00000000-0000-4000-8000-000000000002", // uuid型 (Foreign Key -> artists.artist_id)
   "relation_type": "same_person"                          // artist_relation_type型: same_person
}
```

`same_person`は、マイケル・ジャクソンとThe Jackson 5、個人と所属グループ、同一人物の別名義のように、Artist画面で互いを関連先として案内すべき関係を表します。単に曲調が似ていることや共演したことだけでは結びません。

関係は無方向です。登録時にIDを一定順へ正規化し、`artist_id_a < artist_id_b`、`artist_id_a <> artist_id_b`、複合主キー`(artist_id_a, artist_id_b)`で二重登録と自己参照を防ぎます。Repositoryは指定したIDがA/Bのどちらにあっても反対側を返します。

#### ⑥ `videos_junction` テーブル (動画同士の無方向な関連)

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

#### ⑦ `user_playlists` / `user_playlist_items` テーブル（公開再生リスト）

```jsonc
// user_playlists
{
   "playlist_id": "public-motown-starters",            // uuidまたは一意なtext型 (Primary Key)
   "owner_user_id": "10000000-0000-4000-8000-000000000001", // uuid型 (Foreign Key -> users.user_id)
   "name": "Motownから始める10分",                 // text型 (非NULL)
   "description": "同じ曲のライブ版と音源版を聴き比べる公開プレイリストです。",
   "is_public": true,
   "allows_collaboration": false,
   "created_at": "2026-09-18T10:00:00Z",              // timestamptz型
   "updated_at": "2026-09-20T12:00:00Z",              // timestamptz型
   "embedding": null                                    // vector(384)型 (将来の検索・関連候補用)
}

// user_playlist_items
{
   "playlist_id": "public-motown-starters",            // Foreign Key -> user_playlists.playlist_id
   "video_id": "y2bVIBwpCTA",                          // Foreign Key -> quizzes.video_id
   "position": 0,                                       // integer型 (一覧内の並び順)
   "added_by_user_id": "10000000-0000-4000-8000-000000000001", // Foreign Key -> users.user_id
   "added_at": "2026-09-18T10:01:00Z"                 // timestamptz型
}
```

`user_playlist_items`は`(playlist_id, video_id)`を複合主キーとし、`(playlist_id, position)`に一意制約を付けます。再生リスト本体に動画ID配列を持たせず、項目テーブルを並べ替えることで、削除・順序変更・共同編集の更新単位を明確にします。公開閲覧、所有者編集、共同編集者の操作権限はRLSで分けます。

現在の`public_playlists.json`は画面検証用なので、この2テーブルを結合した読み取りモデルとして`owner_name`と`video_ids`を含めます。これらは物理DBではそれぞれ`users`と`user_playlist_items`から取得し、重複保存しません。認証はフェーズ7でもスコープ外のため、現在はJSONをクラウド公開リストの正本に見立て、保存時にDriftへ端末内コピーを作ります。実際の公開共有と共同編集は認証導入フェーズで最終確定します。

### 3.3. Drift (スマホ内・一時キャッシュ・状態管理用)

Driftはお気に入り、出題被りを避けるための履歴、端末所有の再生リスト、および画面を再表示するための必要最小限のスナップショットを保持します。ヒントの開放履歴は保存しません。Supabaseの全データを恒久的に複製する場所ではなく、Supabaseまたは開発中のJSONが正本です。

お気に入りは動画・コメント・アーティストごとの行として保持します。アーティストは`artist_id`を識別子にし、オフライン表示用に取得時点の`name`もスナップショットとして保存します。コメントも`video_id + comment_id`を識別子にし、LibraryでAPIなしに表示できるよう本文を保存します。`quiz_history_entries`は`video_id`を主キー、`played_at`をクイズ開始時刻として最新50件まで保持します。同じ動画を再度開始した場合は行を重複させず`played_at`を更新し、最新の履歴として扱います。これはヒント開放履歴とは別物です。

Libraryの履歴は上限が50件で、クイズ一覧もRepositoryのメモリキャッシュで共有されるため、履歴の動画IDとプレイ時刻はDriftから一括でRiverpodへ読み込みます。表示中はメモリ上で動画IDをクイズ情報と結合し、各50行ごとにDBへ取りに行くN+1アクセスは行いません。

再生リストは`playlist_records`と`playlist_item_entries`の2テーブルに分けます。`playlist_records`は`id`、`name`、`is_public`、`description`、`allows_collaboration`、`is_owned`、`source_playlist_id`、`created_at`、`updated_at`を持ちます。`source_playlist_id`がNULLなら端末で作成したマイプレイリスト、値があればその公開プレイリストから保存したコピーです。公開元を後から更新しても端末コピーへ自動同期せず、ユーザーが保存した時点の内容を保持します。`playlist_item_entries`は`playlist_id`、`video_id`、`position`、`added_at`を持ち、`(playlist_id, video_id)`の複合主キーで同じ動画の二重追加を防ぎます。並び順は配列をレコード本体へ埋め込まず`position`で表し、ドラッグ並べ替え後にトランザクションで更新します。一括追加は渡された動画IDの順を保って未登録作品だけを末尾へ追加し、別プレイリストへの移動は追加と元リストからの削除・位置正規化を同一トランザクションで行います。お気に入り作品は`favorite_entries`だけで管理し、「お気に入り」プレイリストは作りません。以前のモック版で作成済みの予約ID `system-favorites` はDBバージョン7への移行時に項目と本体を削除します。現在のモック版では公開・共同編集は将来のクラウド移行用メタデータであり、実際の他ユーザー共有は行いません。

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
      "quiz_history": [
         {"video_id": "_G9JjpnwCVQ", "played_at": "2026-09-20T10:00:00Z"},
         {"video_id": "mUg5aEy-8CQ", "played_at": "2026-09-20T09:30:00Z"}
      ]
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
      "thumbnail_hint_type": "comment",
      "artists": [
         {
            "artist_id": "d5b25b8a-9a36-4f13-92f2-6dca44c66b51",
            "name": "The Jackson 5",
            "sub_names": ["Jackson 5", "ジャクソン5"],
            "embedding": null
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

開発中のモックJSONでも同じ関係を再現するため、`quizzes.json`、`artists.json`、`artist_videos_junction.json`、`artists_junction.json`、`videos_junction.json`を別ファイルとして持ち、`QuizRepository`で結合します。YouTube API由来の可変値は`youtube_api_mock.json`に分離します。`QuizRepository`は画面へ結合済みのクイズ、全アーティスト、指定アーティストの無方向な関連先を返し、JSONの参照切れ・自己参照・重複辺・未定義enumを読み込み時に検証します。

再生リストは用途ごとに正本を分けます。`PlaylistRepository`はDrift上の端末作成リストと保存コピーを監視し、作成・作品追加・削除・並べ替え・コピーを担当します。`PublicPlaylistRepository`は現在`public_playlists.json`を読み、将来はSupabaseの公開リスト問い合わせへ差し替えます。Riverpod ProviderはこれらのRepositoryを画面へ注入し、画面はJSON・Drift・Supabaseの違いを直接意識しません。Supabase移行後も各Repositoryのインターフェースと画面へ返す論理モデルを維持し、画面側の取得方法を変更しないことを原則とします。

### 3.4. 永続DB・Riverpod・画面Stateの役割分担

データの寿命に応じて管理場所を次のように分けます。

| 管理対象 | 管理場所 | アプリ再起動後 | 主な役割 |
|---|---|---|---|
| クイズ・アーティスト・関連・公開再生リスト・統計キャッシュ | Supabase（開発中はJSON） | 残る | 全ユーザー共通の正本 |
| お気に入り、最大50件のクイズ開始履歴、端末内再生リスト | Drift | 残る | 端末固有のユーザーデータ |
| Repositoryが結合済みのクイズ一覧 | Riverpod/FutureとRepositoryのメモリキャッシュ | 消える | 同一起動中の重複JSON・DBアクセスを避ける |
| 縮小中のGame・Result | Riverpod | 消える | Home・Library・Artistを操作中に前面体験を復元する |
| アーティスト・再生リスト連続クイズの対象動画と現在位置 | Riverpod | 消える | 複数画面から参照する1回限りのセッション |
| Homeのフィルタ・抽選seed、検索文字、タブ、Playlistの編集中並び順 | 各画面のState | 消える | その画面だけで必要なUI状態 |
| Gameのヒント開放状態、回答演出、回答ボタン縮退状態 | Game画面のState | 消える | 1回のプレイだけで有効な状態 |

Riverpodに置くのは複数画面・共通ナビゲーションから参照する起動中だけの状態です。画面内部だけで完結する状態は各WidgetのStateに置きます。アプリ終了後にも必要なものだけをDriftへ保存し、ヒント開放状態は保存しません。Hot Reloadでは通常メモリ状態も維持されますが、Hot Restartまたはアプリプロセスの終了ではRiverpodと画面Stateが初期化され、Driftは維持されます。

### 3.5. クイズデータ作成・レビュー工程

クイズデータは`_YouTube_Data_API`のローカル開発者ツールで作成し、アプリ本体やSupabaseから分離します。自動処理の出力を正本DBへ直接書かず、次の段階を必須とします。

1. YouTube Data APIの`videos.list`と`commentThreads.list`から動画情報・統計・最大200件程度のトップレベルコメントを取得し、取得時刻付きのraw JSONへ保存する。
2. URL、繰り返し、短すぎる文、重複、タイトルやアーティストの直接的な答え漏れを決定的なルールで除外し、最大40件程度の意味評価候補にする。高評価数だけで選ばず、言語も記録する。OpenAIを使わない場合は`review-rules`で候補ごとの判定、検出言語、答え漏れ、ノイズ、スコア、人の承認欄をJSON/CSVへ出す。決定的ルールは事前選別であり、別言語の人物名や文脈上の答え漏れを完全に決めないため、最終承認を人または次段の型付き提案へ渡す。
3. OpenAIまたはJevで意味評価する場合は、人が確認するコメント候補を最大15件程度へ絞る。OpenAI APIのStructured OutputsはPydanticで固定した型へコメント評価、表示タイトル、ジャンル、言語、アーティスト候補、検索キーワードを出力できる。ChatGPT Plus契約はAPIキーやAPI利用枠を含まないため、利用時は開発者用のAPIキーを別途`.env`へ設定する。
4. Jevは任意の実験的な`CommentRanker`とし、作品固有性・有用性・答え漏れ・ノイズの型付き採点だけを担当させる。自由文のタイトル、アーティスト、関連動画などの事実生成やDB確定には使わない。early access中は外部送信を実装せず、同じ基準の入力JSONを生成して比較可能にする。
5. AI提案を`needs_review`状態のJSONと、1コメント1行のUTF-8 CSVへ出力する。Google Sheetsには最大15件程度の候補を同期し、人がコメント言語、答え漏れ、有用性、事実、既存アーティストとの同一性、既存動画・関連動画を確認して、表示順を含む1〜8件を最終採用する。歌詞はAIに生成させず、権利と原文を確認して別工程で入力する。
6. Google Sheets自動同期はローカルPythonツールからGoogle Sheets APIを使用する。対象シートだけをIAMロールなしのサービスアカウントへ編集者として直接共有し、JSON鍵`credentials.json`をGit対象外にする。既知のSpreadsheet IDへ値を書くだけなのでGoogle Drive APIやドメイン全体の委任へ権限を広げない。再同期時は安定IDで行を更新し、人が入力した採否・メモ・最終順序を上書きしない。
7. 人が`approved`にしたデータだけをSupabase投入候補とする。`artist_id`候補は既存Artistと照合し、`videos_junction`の関係は必ず人が確定する。投入処理はフェーズ7で、承認済みデータだけを受け付ける別コマンドとして実装する。

APIキーは`_YouTube_Data_API/.env`だけに置きます。共有用の`.env.example`は置かず、必要な変数名と作成方法は`_YouTube_Data_API/README.md`を正本とします。`.env`、rawデータ、AI生成物、認証キャッシュはGit管理外とし、Flutter asset、Python/Dartソース、`Info.plist`、コミット履歴へ実キーやトークンを入れません。API例外はキー付きURLやレスポンス本文をそのまま出力せず、リソース名とHTTPステータスだけに秘匿化します。漏えいが疑われるキーは提供元で無効化・再発行します。
