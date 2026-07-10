# RemoteProductCandidateProvider 設計メモ

`ProductCandidateProvider` を将来的に実APIへ差し替えるための設計方針。
現時点では Mock のみ実装済み。このドキュメントは設計メモであり、実装ではない。

---

## 1. 目的

Flutterアプリ側の UI/ロジックを変えずに、商品候補の取得元を Mock → 実API へ置き換えられるようにする。

対象:

- 楽天市場
- Amazon
- Yahoo!ショッピング
- 汎用ASP
- 将来的な複数 provider 統合

---

## 2. 基本方針

- Flutterアプリから EC API を直接叩く設計は避ける
- 本番では Proxy / Cloudflare Workers / Firebase Functions 等を経由する
- APIキー、affiliateId、access token はアプリに直書きしない
- アプリには正規化済みの `ProductCandidate` のみ返す
- 商品候補は「購入候補」であり、「同じ商品」と断定しない

---

## 3. 推奨アーキテクチャ

```text
Flutter app
  ↓
ProductCandidateProvider
  ↓
RemoteProductCandidateProvider
  ↓
Backend Proxy
  ↓
Rakuten / Amazon / Yahoo / ASP APIs
```

### 責務分離

**Flutter:**

- `ProductSearchQuery` を作る
- 商品候補を表示する
- アフィリエイト開示を表示する
- 外部リンクを開く

**Backend Proxy:**

- APIキー/affiliateId を保持
- EC API を呼ぶ
- レスポンスを正規化
- 余計なデータを落とす
- rate limit / cache / error handling を担う

---

## 4. Provider 抽象化方針

```dart
abstract class ProductCandidateProvider {
  Future<List<ProductCandidate>> search(ProductSearchQuery query);
}

class MockProductCandidateProvider implements ProductCandidateProvider {}

class RemoteProductCandidateProvider implements ProductCandidateProvider {
  final ProductCandidateApiClient client;

  RemoteProductCandidateProvider(this.client);

  @override
  Future<List<ProductCandidate>> search(ProductSearchQuery query) {
    return client.search(query);
  }
}
```

将来的には内部で複数のソースを統合することも検討する。

```text
RakutenCandidateSource
AmazonCandidateSource
YahooCandidateSource
AspCandidateSource
```

ただし、アプリ側には `ProductCandidateProvider` だけ見せる。

---

## 5. ProductCandidate 正規化ルール

商品候補は必ず以下に正規化する。

- `title` — 必須
- `url` — 必須
- `price` — 取れない場合 `null`
- `imageUrl` — 取れない場合 `null`
- `reviewAverage` — 取れない場合 `null`
- `shopName` — 取れない場合 `null`
- `matchLevel` — 必須
- `cautions` — 空にしない

---

## 6. MatchLevel の扱い

- `exactCode`: JAN/バーコード/型番など明確なコード一致時のみ
- `compatibleSpec`: 検索条件と商品情報の条件が合いそうな場合
- `inferred`: AI推定を含む条件から検索した場合
- `manualCandidate`: 手動入力条件から検索した場合

注意: 現時点では `exactCode` は使わない。将来的に JAN/型番 OCR が入るまで使用しない。

---

## 7. アフィリエイト開示

商品候補に `isAffiliate == true` が1件でも含まれる場合、商品候補セクション上部に明示する。

表示文案:

```text
この商品候補には広告リンクが含まれます。リンクから購入されると、開発者に紹介料が入る場合があります。
```

Mock表示の場合:

```text
商品候補には、将来的に広告リンクを含む場合があります。現在はデモ表示です。
```

アフィリエイトリンクを通常リンクに見せかけたり、ユーザーの意図しないリンク差し替えを行わないこと。

---

## 8. 外部リンクを開く条件

- Mockでは外部リンクを開かない
- 本番 provider ではユーザーが明示的にボタンを押した時だけ外部リンクを開く
- 自動遷移しない
- 商品カード全体タップではなく、明示ボタンで開く
- ボタン文言は `商品ページを見る` または `楽天で見る` など明確にする
- アフィリエイトの場合は開示文を同じ画面内に出す

---

## 9. エラー・空結果の扱い

- APIエラー時は商品候補セクションを壊さず、検索ワードコピー導線を残す
- 空結果なら「条件に合う候補を取得できませんでした」と表示
- APIキー未設定時は Mock または商品候補非表示へ fallback
- ユーザーには raw exception を表示しない
- debugPrint / logging に詳細を出す

---

## 10. キャッシュ・レート制限

- Backend Proxy で短期キャッシュを行う
- 同一 `ProductSearchQuery` は一定時間キャッシュする
- EC API の rate limit を Proxy 側で吸収する
- アプリ側は過度に連打しない
- pull-to-refresh 等を入れる場合は interval 制限する

---

## 11. セキュリティ

- APIキー/affiliateId は Flutterアプリに入れない
- Proxy 側の環境変数で管理する
- 不正利用防止のため、Proxy は入力 query を検証する
- URL は許可ドメインのみ返す
- アプリ側も外部 URL を開く前に scheme/domain を確認する

---

## 12. 実装優先順位

1. Mock UI の安定化
2. RemoteProductCandidateProvider interface 追加
3. Backend Proxy 仕様設計
4. 楽天APIのみ PoC
5. アフィリエイト開示 UI の本番対応
6. 商品画像表示
7. 空結果/エラー UI
8. Yahoo/Amazon 等の追加
9. JAN/型番 OCR 連携
10. exactCode 候補対応

---

## 13. 今回は実装しないこと

- 楽天API連携
- Amazon API連携
- Yahoo API連携
- Cloudflare Workers / Firebase Functions の実装
- 実アフィリエイトリンク生成
- 外部リンク起動
- 商品画像表示
- JAN/型番 OCR
