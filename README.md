# これの替えどれ？

電球などの買い替え時に、写真を撮って同じ規格の商品を調べるためのアプリ。

> **現状: MVP（Mock判定/Gemini判定）**
> 画像分類は `MockClassifier`（擬似）または `GeminiClassifier`（Gemini API）を使用します。
> APIキー未設定時は自動的に Mock判定にフォールバックします。
>
> 対象品目は現在 **電球（E26 / E17）のみ** です。

## 現状の対応範囲

| 品目 | 対応 | 備考 |
|------|------|------|
| 電球（E26 / E17） | ✅ 完了 | 3段階撮影 + 手動確認 |
| 電池 | ⏸ 未着手 | Beta表示のみ |
| フィルター | ⏸ 未着手 | Beta表示のみ |

## Mock判定とGemini判定の違い

| 項目 | Mock判定 | Gemini判定 |
|------|---------|-----------|
| 画像の外部送信 | なし（端末内のみ） | あり（Gemini APIへ送信） |
| APIキー | 不要 | 必要 |
| 分類精度 | 擬似（デバッグ用） | AIによる実際の画像分類 |
| フォールバック | — | 初期化失敗時に自動でMockへ |

## 必要なもの

- Flutter SDK（stable channel）
- Android Studio / Xcode（実機ビルド用）
- Java 17（APKビルド用）

## Gemini APIキーの指定方法

```bash
# 開発実行
flutter run --dart-define=GEMINI_API_KEY=your_key_here

# デバッグAPKビルド
flutter build apk --debug --dart-define=GEMINI_API_KEY=your_key_here

# モデルを明示指定する場合（未指定時は候補リストから自動選択）
flutter run --dart-define=GEMINI_API_KEY=xxx --dart-define=GEMINI_MODEL=gemini-2.5-flash-preview
```

> **注意: `--dart-define` で渡したAPIキーは APK/IPAに埋め込まれます。**
> 本番公開（ストア配布）時は **Proxy / Firebase Functions / Cloudflare Workers 等の中継構成が必須** です。
> 現状は開発確認用であり、キー漏洩リスクを理解した上で使用してください。

## 画像送信とプライバシー注意

- Gemini判定を使う場合、選択した画像はAI判定のため外部API（Gemini API）へ送信されます
- APIキー未設定時はMock判定のみで、画像は外部送信されません
- 送信された画像はGoogleのプライバシーポリシーに従って処理されます
- 現在のGemini SDK構成は暫定です。将来は公式推奨SDKまたはProxy構成へ移行予定

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

Gemini APIキー不要でビルド可能（Mock判定で動作します）。

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
- **画像分類**: Gemini API（暫定） / Mock判定（フォールバック）
  - 現在の `google_generative_ai` SDK は暫定利用です
  - 将来は公式推奨SDKまたはProxy構成へ移行予定
  - Phase 2で TFLite + MediaPipe オンデバイス判定を追加予定

## 注意事項

- このアプリが提示する情報は「購入候補」であり、確定的な商品特定ではありません
- 口金サイズは購入前に必ず実物で確認してください
- 写真一枚で商品を断定するものではありません
- AI判定は参考情報です。必ず現物・パッケージで確認してください
