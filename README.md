# これの替えどれ？

電球などの買い替え時に、写真を撮って同じ規格の商品を調べるためのアプリ。

> **現状: MVP（Mock判定）**
> 画像分類は `MockClassifier` による擬似的なもので、実際の画像認識は行いません。
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

## ローカル実行

```bash
flutter pub get
flutter run            # 実機またはエミュレーターで起動
flutter test           # テスト実行
flutter analyze        # 静的解析
```

## APKビルド

```bash
# デバッグAPK（開発用）
flutter build apk --debug

# リリースAPK（配布用）
flutter build apk --release
```

> **リリース署名について**
> デフォルトでは debug 署名でビルドされます。
> 実配布用の署名を行う場合は `android/key.properties` を作成してください。
> 詳細は [Flutter 署名ガイド](https://docs.flutter.dev/deployment/android#signing-the-app) を参照。

## CI

| トリガー | 実行内容 |
|----------|----------|
| PR作成・更新 | `flutter analyze` + `flutter test` |
| master push | `flutter analyze` + `flutter test` |
| `v*` タグ push | APKビルド + GitHub Release作成 |

## 技術スタック

- **Flutter** / Dart
- **Jetpack Compose**（UI）
- **Room**（データ保存 - Phase 3以降）
- **画像分類**: Phase 2で TFLite + MediaPipe を予定

## 注意事項

- このアプリが提示する情報は「購入候補」であり、確定的な商品特定ではありません
- 口金サイズは購入前に必ず実物で確認してください
- 写真一枚で商品を断定するものではありません
