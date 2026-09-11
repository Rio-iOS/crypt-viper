# CryptViper

VIPERの役割分担と、HTTP通信から一覧表示までの流れを学ぶiOSサンプルです。サンプルJSONの通貨名・価格を表示し、選択すると詳細画面を開きます。価格データはリアルタイムではありません。

## 環境と起動

- Xcode 26.6（ローカルのビルド・テストで確認）
- Deployment Target: iOS 16.1
- 外部パッケージのインストールは不要

`CryptViper.xcodeproj`を開き、`CryptViper` schemeとiPhone Simulatorを選択して実行します。実機では自分のSigning TeamとBundle Identifierを設定してください。

## 構成

- **View**: 一覧、読込中・空・エラー状態を表示し、画面準備完了をPresenterへ通知します。
- **Presenter**: ViewからのイベントをInteractorへ渡し、結果をViewへ返します。
- **Interactor**: 注入されたURLSessionでJSONを取得し、HTTPステータスとJSONを検証します。結果はメインキューで返します。
- **Entity**: 通貨名と価格を表す`Cryptocurrency`です。
- **Router**: 詳細画面への遷移を担当します。Moduleが依存関係を組み立て、ViewがPresenter、PresenterがInteractorとRouterを保持します。PresenterとRouterの画面参照、Interactorの出力先はweakです。

詳細画面への遷移はPresenterからRouterへ指示します。表示にはDynamic Type対応のフォントとAuto Layoutを使います。再試行UIとVoiceOverの操作確認は今後の改善対象です。

## 検証

```sh
swift Scripts/test.swift
```

Simulatorを指定する場合:

```sh
TEST_DESTINATION='platform=iOS Simulator,id=YOUR_SIMULATOR_UDID' swift Scripts/test.swift
```

テストではHTTP通信をURLProtocolで置き換え、正常JSON・空配列・503応答・不正JSON・オフラインを検証します。また、通信開始のタイミングとView・Presenter・Interactor・Routerの解放を確認します。

```sh
swiftformat --version # 0.58.5
swiftformat CryptViper CryptViperTests --lint
```

GitHub Actionsでも同じテストと整形検査を実行します。CIの結果はPRで確認してください。

## データと出典

通貨データは[atilsamancioglu/K21-JSONDataSet](https://github.com/atilsamancioglu/K21-JSONDataSet)の`crypto.json`を参照します。通信先の可用性やデータ形式はこのリポジトリでは管理していません。

このリポジトリは学習用の実装です。元の教材の詳細と、このリポジトリ全体のライセンスは未記載のため、再配布条件は別途確認してください。

## 振る舞いの回帰テスト

一覧に読み込み状態と再試行ボタンを設け、失敗と空結果から再取得できます。画面の非表示時にInteractorの通信をキャンセルし、要求IDが一致しない古い応答を無視します。

HTTP異常系と所有関係に加え、実際のUIViewControllerでエラー→再試行→読み込み→一覧表示・選択・画面離脱を検証します。

```sh
swift Scripts/test.swift
```

## Swiftコード品質

[設計・命名・所有関係の方針と、この教材への適用範囲](SWIFT-QUALITY.md)を参照してください。
