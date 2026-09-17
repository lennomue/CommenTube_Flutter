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
