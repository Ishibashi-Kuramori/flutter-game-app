# flutter-game-app

Flutterのブロック崩しアプリ
[https://flutter-game-app-55ec2.web.app/](https://flutter-game-app-55ec2.web.app/)

元となったチュートリアル
[Flutter で Flame を使ってみる](https://codelabs.developers.google.com/codelabs/flutter-flame-brick-breaker?hl=ja#0)

### 追加及び修正した機能
* ゲーム終盤に球が亜空間の彼方に消えるバグを改修
* flame_audioを利用した効果音再生機能を実装
* cloudFireStoreと連携してハイスコア機能を実装
* ハイスコア実装に伴い、ゲーム難易度を上方修正(人間業では無理なレベルに)
* 名前入力欄を使った隠しコマンド機能(long/short/big/small/power/double/reset)を実装
* セキュリティルールを導入しスコア不正対策実施(FirebaseAppCheckは実装を断念)

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
