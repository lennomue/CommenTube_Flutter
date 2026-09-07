Bundle Identifier：com.lennomue.commentubedemo
# 実行の仕方
cd /Users/lennomue/Dev/CommenTube
<!-- flutter コマンドを使用可能に -->
export PATH="/Users/lennomue/develop/flutter/bin:$PATH"
<!-- 実行可能かの検査をする。iOS関連でチェックが出ればOK -->
flutter doctor
<!-- いざ実行、usbを繋いで実機でテスト -->
flutter run
軽微な修正はコードを編集してからターミナルで`r` -> リロード、`R`で再起動
なお、`d`で切り離し、スマホ本体にアプリが残る


<!-- 以下初めのテストの時のやり方 -->
<!-- Xcodeを入れる前のMacは、参照先が「Command Line Tools（単体版）」という機能が制限された場所にセットされていたので、次ので参照先を変更 -->
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
<!-- 初回ライセンスの同意とツール初期化 -->
sudo xcodebuild -runFirstLaunch
<!-- CocoaPods（iOSライブラリ管理ツール、FlutterでiOSアプリをビルドする際に必要なツール）の導入 -->
sudo gem install cocoapods
<!-- 上のコマンドを実行すると次のように返ってくる(アップデートコマンドの案内など) -->
A new release of RubyGems is available: 3.5.9 → 4.0.17!
Run `gem update --system 4.0.17` to update your installation.

Xcodeを開いて(ターミナルで`open ios/Runner.xcworkspace`)プロジェクトの設定としてAppleアカウントの初期設定をする。
iPhoneの「設定」-> 「プライバシーとセキュリティ」→「デベロッパモード」を有効にする
iPhoneの「一般」-> 「VPNとデバイス管理」で信頼

iPhoneに繋いでアプリが立ち上がりテストができた！
-> ターミナル