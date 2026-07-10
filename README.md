# これの替えどれ？

電球などの買い替え時に、写真を撮って同じ規格の商品を調べるためのアプリ。

> **現状: MVP（Mock判定/Gemini判定）**
> 画像分類は `MockClassifier`（擬似）または `GeminiClassifier`（Gemini API）を使用します。
> APIキー未設定時は自動的に Mock判定にフォールバックします。
> 画面遷移と手動確認のフローを検証する段階です。

## 対応品目

- **電球**（E26 / E17 口金）
  - 全体写真 → 口金写真 → 印字写真 → 器具確認 の3段階撮影
- その他の品目は今後追加予定

## 主な画面導線

```
ホーム → 撮影ガイド（全画面/口金/印字/器具）
        → 手動確認（不足項目のみ表示）
        → 購入結果（候補タイトル・検索ワード・注意事項）
        → 履歴一覧（過去の結果を閲覧）
```

## 必要なもの

- Flutter SDK（stable channel）
- Android Studio / Xcode（実機ビルド用）

## Gemini APIを使う場合

```bash
# APIキーを指定して実行（APKにキーが埋め込まれるため開発用）
flutter run --dart-define=GEMINI_API_KEY=your_key_here

# 本番ビルドも同様
flutter build apk --release --dart-define=GEMINI_API_KEY=your_key_here
```

> **APIキーに関する注意**
> `--dart-define` で渡したAPIキーは **APK/IPAに埋め込まれます**。
> 本番公開（ストア配布）時は **Proxy構成が必須** です。
> 現状は開発確認用であり、キー漏洩リスクを理解した上で使用してください。

## ローカル実行

```bash
flutter pub get
flutter run            # 実機またはエミュレーターで起動
flutter test           # テスト実行
flutter analyze        # 静的解析
```

## APKビルド

```bash
# デバッグAPK（開発確認用）
flutter build apk --debug

# リリースAPK（開発確認用 / ストア公開用ではない）
flutter build apk --release
```

> **リリース署名について**
> 現在のGitHub Release APKは **debug署名（開発確認用）** であり、**ストア公開用ではありません**。
> 本番配布（ストア公開）には至っていないため、当面はこの状態で運用します。
> 将来ストア公開する場合は `android/key.properties` + GitHub Secrets でrelease署名に切り替えます。
> 詳細は [Flutter 署名ガイド](https://docs.flutter.dev/deployment/android#signing-the-app) を参照。

## CI

| トリガー | 実行内容 |
|----------|----------|
| PR作成・更新 | `flutter analyze` + `flutter test` |
| master push | `flutter analyze` + `flutter test` |
| `v*` タグ push | APKビルド + GitHub Release作成（開発確認用APK） |

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
