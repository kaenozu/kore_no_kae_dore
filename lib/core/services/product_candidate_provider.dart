// lib/core/services/product_candidate_provider.dart
// 商品候補の取得を抽象化したインターフェース
// Provider差し替えでMock検索→実API検索へ移行できるようにする
// related: product_candidate.dart, product_search_query.dart

import '../models/match_level.dart';
import '../models/product_candidate.dart';
import '../models/product_search_query.dart';

abstract class ProductCandidateProvider {
  Future<List<ProductCandidate>> search(ProductSearchQuery query);
}

class MockProductCandidateProvider implements ProductCandidateProvider {
  const MockProductCandidateProvider();

  @override
  Future<List<ProductCandidate>> search(ProductSearchQuery query) async {
    final caution = switch (query.matchLevel) {
      MatchLevel.exactCode =>
        '型番やコードが一致する候補です。購入前に販売ページの対応条件を確認してください。',
      MatchLevel.compatibleSpec =>
        '入力された条件に合いそうな候補です。購入前に規格を確認してください。',
      MatchLevel.inferred =>
        '写真からの推定を含みます。購入前に必ず現物・パッケージで確認してください。',
      MatchLevel.manualCandidate =>
        '手動入力に基づく候補です。入力内容と商品ページを照合してください。',
    };

    return [
      ProductCandidate(
        title: '${query.keyword} 互換 LED電球',
        price: 2980,
        imageUrl: null,
        shopName: 'デモストア',
        reviewAverage: 4.2,
        url: 'https://example.com/demo/1',
        isAffiliate: false,
        matchLevel: query.matchLevel,
        matchedConditions: query.conditions.keys.toList(),
        cautions: [caution],
      ),
      ProductCandidate(
        title: '${query.keyword} 高演色 LED',
        price: 3580,
        imageUrl: null,
        shopName: 'デモストア',
        reviewAverage: 4.5,
        url: 'https://example.com/demo/2',
        isAffiliate: false,
        matchLevel: query.matchLevel,
        matchedConditions: query.conditions.keys.toList(),
        cautions: [caution],
      ),
    ];
  }
}
