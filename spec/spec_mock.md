# CommenTube基本設計書(mock版)

YouTubeの動画(主に公式のミュージックビデオ)につくコメントや楽曲情報をヒントとしてプレイヤーに提供し、元動画を回答するゲーム。スマホ向けアプリとして開発する。
モック版では、複雑な認証やポイント決済機能を排し、コアゲームサイクル（出題、回答、リザルト）の実現可能性を検証することを目的とする。
なおゲームの問題情報のために、プロジェクト内のjsonデータファイルに仮のゲームデータ(固定)を用意する。必要ならば個人の変化するデータを保存するjsonファイルを使うのも良いが、フロントエンドの画面自体が保存しきれていたら良い。

---

## 1. 技術選定とその理由

| レイヤー | 採用技術 | 選定理由 |
| :--- | :--- | :--- |
| **フロントエンド** | **Flutter (Dart)** | 1つのコードベースでiOSとAndroidの両アプリを同時開発可能。UIの柔軟性が高く、カスタムWebViewの構築やクイズの快適なアニメーションも実装しやすいため。 |
| **ローカルDB** | **Drift** | FlutterのローカルDB選定に関してもっとも推奨されている選択肢 (2026年時点) |

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
1. クイズ画面に固定で設置される解答するためのボタン(CommenTubeロゴのような丸いもの)から、Flutter製の制御外枠（閉じる、戻る・進む、回答ボタン）を持つWebViewウィンドウを展開。
2. ユーザーがWebView内のYouTubeで該当動画の再生ページ（`watch?v=...`）に達した状態で、外枠の「**この動画で回答する！**」をタップ。
3. `currentUrl()`を利用して、現在のURLから動画ID（`video_id`）を抽出し、ウィンドウを閉じながら、ローカルデータ内に持っている正解データを元に正誤判定

### 2.3. 主要画面（機能）
* **ホーム(home)画面**: 問題ブロックが並んでいる。画面下部にはhomeとlibraryとsettingへの移動をできる/現在の場所を示すものがある。(spec/game_images/01_home_draft.JPG)
* **クイズプレイ(game)画面**: 段階的に開示可能なコメント等のヒント表示、および専用WebViewを開く回答ボタン。(spec/game_images/02_quiz_1_main_draft.JPG、spec/game_images/02_quiz_2_answering_draft_01.JPG、spec/game_images/02_quiz_2_answering_draft_02.JPG)
* **プレイ情報(library)画面**: コメントや歌詞、動画という各粒度でお気に入り登録/確認が可能。タブで粒度を切り替えて表示。
* **設定(setting)画面**: データベースを最低限の実装のため、ダミーの検索となるが、出題問題の条件をここで設定する。言語、ジャンルや年代の条件絞り込み機能。

---

## 3. データベース設計 (スキーマ定義)

データベースの実体はプロジェクト内のjsonファイルにあるが、将来的には**Supabase(クラウド)** と**Isar(ローカル)** を用いる。
つまりjsonファイルにアクセスする回数を増やすと将来的にクラウドのデータベースに検索などをかけてアクセスする回数が増えてしまうので、それに注意してデータのアクセスの仕方と保持の仕方を設計すること。
なお今回は最低限で固定のjsonデータであり、データベースとして検索はしない。

### 3.1. Supabase (クラウドDB)

#### ① `users` テーブル (ユーザー情報の管理)

```jsonc
{
   "user_id": "f353ca91-4fc5-49f2-9b9e-304f83d11914",      // uuid型データ(Primary Key)
   "created_at": "2026-06-08T14:00:33Z",              // UTCのdatetime型データ
   "quiz_history": ["_G9JjpnwCVQ", "mUg5aEy-8CQ", "rSYoIuyks8g"]  // text[] (配列型: 出題された問題を記録。被り防止に最大100まで巡回保存)
}
```

#### ② `quizzes` テーブル (出題情報の管理)
```jsonc
{
   "video_id": "y2bVIBwpCTA",                          // text型 (Primary Key / YouTubeの動画ID)
   "music_title": "I Want You Back",                   // text型 (通常は答えに直結するためヒントにしない)
   "music_artists": ["The Jackson 5"],                 // text[]型 (配列型: コラボ曲等の複数名に対応)
   "music_languages": ["english"],                     // text[]型 (配列型: 条件検索用の言語タグ)
   "music_released_at": "1969-10-07T00:00:00Z",        // timestamptz型 (ISO 8601形式の日時文字列) (条件検索用: リリース年)
   "video_view_count": 117264772,                      // int型 (動画の視聴回数。条件検索用)
   "video_like_count": 944180,                         // int型 (動画の高評価数)
   "video_channel_id": "UCDUNe-NZaknJOGyulc4Ohvg",     // text型 (チャンネルID)
   "video_published_at": "2020-06-14T19:00:08Z",       // timestamptz型 (動画の公開日)
   "video_lyrics": [                                   // text[]型 (3個ほどの歌詞を持つ文字列配列ヒント)
      "Oh, baby, give me one more chance",
      "Won't you please let me (Back in your heart)",
      "But now since I see you in his arms (I want you back)" 
   ],
   "video_comments": [                                 // jsonb型 (画面表示専用データ。検索対象にしないためネストを維持)
      {
         "content": "Imagine a 10 year old sounding better than most artist today",
         "like_count": 77307,
         "updated_at": "2021-01-22T14:00:33Z"
      },
      {
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
      "user_id": "f353ca91-4fc5-49f2-9b9e-304f83d11914",    // UUID
      "c_point": 50,                                        // int型
      "quiz_history": ["_G9JjpnwCVQ", "mUg5aEy-8CQ", "rSYoIuyks8g"]  // 過去の出題(回答済み)履歴保存、同期用
   },
   "quizzes_showing_check": [
      {
         "video_id": "y2bVIBwpCTA",                       // 楽曲のID
         "show_music_released_year": true,                // bool型: 表示済か未表示かのフラグ管理
         "show_video_view_count": true,
         "show_video_like_count": true,
         "show_video_channel_id": false,
         "show_video_lyrics": [false, false, false],
         "show_video_comments": [true, false]
      },
      {},{},{},{}                                        // 残り4問分は省略
   ],
   "quizzes_on_going": [
      // バックエンドから取得した、現在進行中ステージのクイズ5問分のフルオブジェクトデータを一時キャッシュ
   ]
}
```