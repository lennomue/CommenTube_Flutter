# commmit毎の変更内容をメモ
以下の内容はAIが追記していく

## 2026-09-17: フェーズ0 開発環境・雛形構築

- Riverpod、go_router、Drift、WebViewの依存関係を追加
- 廃止済みの直接依存`sqlite3_flutter_libs`を、Drift公式推奨の`drift_flutter`と`path_provider`へ変更
- Flutter 3.44.9との互換性のため`go_router`を17.5系に固定
- home/game/result/libraryのルートと機能別ディレクトリを追加
- HomeとLibraryを往復できる共通ボトムナビゲーションを追加
- Home画面の既存UIを機能別ファイルへ分離
- 静的解析、ウィジェットテスト、iOS向け署名なしデバッグビルドの成功を確認

## 2026-09-17: フェーズ1 JSON固定データによる画面実装

- 仕様の`quizzes`定義に沿った5問分の固定データと、YouTube Data API形式を模した統計モックを追加
- 将来のSupabase・実API移行でも画面側の呼び出しを変えない`QuizRepository`インターフェースを追加
- クイズ本体、動画統計、コメント高評価数を`QuizWithLiveStats`へ結合する処理を実装
- Homeに代表コメント・再生数・公開からの経過期間を表示するスクロールフィードを実装
- Gameに固定統計と全開放状態のコメント・歌詞・楽曲情報ヒントを実装
- Resultに楽曲の全情報、次の問題、Homeへ戻る導線を実装
- クイズIDをパスに含むHome→Game→Result→Homeの画面遷移を実装
- 320×568相当の小型画面でもHomeがオーバーフローしないレスポンシブ表示へ調整
- JSON結合テスト、画面遷移テスト、静的解析、iOS向け署名なしデバッグビルドの成功を確認
