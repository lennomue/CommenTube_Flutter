# CommenTube

YouTube動画を、コメント・歌詞・作品情報などのヒントから当てるFlutterアプリです。

- 現在仕様: `spec/spec.md`
- 開発過程・残作業: `spec/plan.md`
- コミット単位の変更記録: `spec/_commit.md`
- データ作成ツール: `_YouTube_Data_API/README.md`

Bundle Identifier：`com.lennomue.commentubedemo`

## 実機での実行

```sh
cd /Users/lennomue/Dev/CommenTube/my_test_app
export PATH="/Users/lennomue/develop/flutter/bin:$PATH"
flutter doctor
flutter run
```

軽微な修正はコードを編集してからターミナルで`r` -> リロード、`R`で再起動
なお、`d`で切り離し、スマホ本体にアプリが残る


## iOS初回セットアップの記録

Xcode導入前のMacで参照先がCommand Line Tools単体版になっている場合だけ実行します。

```sh
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
# 初回ライセンスの同意とツール初期化
sudo xcodebuild -runFirstLaunch
# CocoaPodsの導入
sudo gem install cocoapods
```

Xcodeを開いて(ターミナルで`open ios/Runner.xcworkspace`)プロジェクトの設定としてAppleアカウントの初期設定をする。
iPhoneの「設定」-> 「プライバシーとセキュリティ」→「デベロッパモード」を有効にする
iPhoneの「一般」-> 「VPNとデバイス管理」で信頼

iPhoneに接続後、VS Codeまたは`flutter run`から実機テストします。
