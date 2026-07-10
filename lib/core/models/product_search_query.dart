// lib/core/models/product_search_query.dart
// 商品検索クエリ：キーワード、カテゴリ、マッチレベル、条件を含む
// 関連: product_candidate.dart, product_candidate_provider.dart

import 'match_level.dart';

class ProductSearchQuery {
  final String keyword;
  final String category;
  final MatchLevel matchLevel;
  final Map<String, String> conditions;

  const ProductSearchQuery({
    required this.keyword,
    required this.category,
    required this.matchLevel,
    required this.conditions,
  });
}
