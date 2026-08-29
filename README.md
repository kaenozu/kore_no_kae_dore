# これの替えどれ？

電球などの買い替え時に、写真を撮って同じ規格の商品を調べるためのアプリ。

> **現状: MVP（Mock判定）**
> 画像分類は端末内の `MockClassifier`（擬似）を使用します。
> Gemini APIのクライアント直接呼び出しは無効化しています。安全なバックエンド経由でのみ再導入します。
>
> 対象品目は現在 **電球（E26 / E17）のみ** です。

## 現状の対応範囲

| 品目 | 対応 | 備考 |
|------|------|------|
| 電球（E26 / E17） | ✅ 完了 | 3段階撮影 + 手動確認 |
| 電池 | ⏸ 未着手 | Beta表示のみ |
| フィルター | ⏸ 未着手 | Beta表示のみ |

## 必要なもの

- Flutter SDK（stable channel）
- Android Studio / Xcode（実機ビルド用）
- Java 17（APKビルド用）

## 画像送信とプライバシー注意

- 現在はMock判定のみで、画像は外部送信されません
- Geminiを再導入する場合は、認証・レート制限・サーバー側秘密管理を備えたバックエンド経由に限定します

## ローカル実行

```bash
flutter pub get
flutter run            # 実機またはエミュレーターで起動
flutter test           # テスト実行
flutter analyze        # 静的解析
```

## テスト

```bash
flutter test                       # 全テスト実行
flutter test test/rules/           # ルールエンジンのテストのみ
flutter test test/session/         # セッションコントローラのテストのみ
flutter test test/widgets/         # Widgetテストのみ
```

## Debug APKビルド

```bash
# デバッグAPK（開発確認用、署名なし）
flutter build apk --debug
```

APIキー不要でビルド可能（Mock判定で動作します）。

## GitHub Actions artifact の取り方

1. リポジトリの **Actions** タブを開く
2. 最新の **CI** workflow run をクリック
3. Artifacts セクションの `kore-no-kae-dore-debug-preview-apk` をダウンロード
4. ダウンロードしたAPKを実機にインストール（開発者オプション + USBデバッグ / `adb install`）

> 注意: これはdebug署名のAPKです。**ストア公開用ではありません。**

## CI

| トリガー | 実行内容 |
|----------|----------|
| PR作成・更新 / master push | `flutter analyze` + `flutter test` + `flutter build apk --debug` |
| `v*` タグ push | APKビルド + GitHub Release作成（開発確認用APK） |
| 手動（workflow_dispatch） | 同上 |

## 本番公開に必要な残作業

- [ ] **Proxy化**: Gemini APIキーをAPKに含めないためのProxy/Firebase Functions/Cloudflare Workers
- [ ] **release署名**: `android/key.properties` + GitHub Secrets による署名設定
- [ ] **ストア用プライバシーポリシー**: 画像送信に関する説明
- [ ] **実機検証**: 各種Android端末での動作確認
- [ ] **対応品目拡張**: 電池 / フィルターなど

## 技術スタック

- **Flutter** / Dart
- **image_picker**（カメラ・ギャラリー）
- **path_provider** / JSONファイル保存
- **画像分類**: Mock判定（端末内）
  - Gemini APIのクライアント直接呼び出しは無効化しています
  - 再導入は安全なバックエンド経由に限定します
  - Phase 2で TFLite + MediaPipe オンデバイス判定を追加予定
- **商品候補モデル**: `MatchLevel`, `ProductCandidate`, `ProductCandidateProvider`

## 商品特定レベルについて

このアプリは、写真から完全に同じ商品を断定するものではありません。
商品候補は以下のレベルで表示します。

- 型番・コード一致候補: JAN/バーコード/型番などが一致する候補
- 条件一致候補: 口金、明るさ、光色などの条件に合いそうな候補
- AI推定候補: 写真からのAI推定を含む候補
- 手動入力候補: ユーザーの手動入力に基づく候補

購入前には、必ず商品ページ・パッケージ・販売店情報を確認してください。

## 本番公開に必要な残作業

- [ ] **Proxy化**: Gemini APIキーをAPKに含めないためのProxy/Firebase Functions/Cloudflare Workers
- [ ] **release署名**: `android/key.properties` + GitHub Secrets による署名設定
- [ ] **ストア用プライバシーポリシー**: 画像送信に関する説明
- [ ] **実機検証**: 各種Android端末での動作確認
- [ ] **対応品目拡張**: 電池 / フィルターなど
- [ ] **商品検索連携**: 楽天/Amazon/Yahoo等の商品検索API接続
- [ ] **アフィリエイトリンク開示**: 将来的に広告リンクを含む場合は明記
- [ ] **型番/JAN対応**: バーコード読み取り、型番OCR、パッケージ撮影
- [ ] **購入履歴入力**: 過去の購入品から候補を絞り込み
- [ ] **ストレージ固化対策**: 暗号化 / JSON破損ファイル退避（P2）

## 注意事項

- このアプリが提案する情報は「購入候補」であり、確定的な商品特定ではありません
- 口金サイズは購入前に必ず実物で確認してください
- 写真一枚で商品を断定するものではありません
- AI判定は参考情報です。必ず現物・パッケージで確認してください
- 検索結果にはアフィリエイトリンクが含まれる場合があります
