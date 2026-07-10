// lib/core/models/product_candidate.dart
// 商品候補1件分の情報
// 信頼度レベル・一致条件・警告を含み、断定表現を使ってはいけない
// 関連: product_search_query.dart, product_candidate_provider.dart, purchase_result.dart

import 'match_level.dart';

class ProductCandidate {
  final String title;
  final int? price;
  final String? imageUrl;
  final String? shopName;
  final double? reviewAverage;
  final String url;
  final bool isAffiliate;
  final MatchLevel matchLevel;
  final List<String> matchedConditions;
  final List<String> cautions;

  const ProductCandidate({
    required this.title,
    this.price,
    this.imageUrl,
    this.shopName,
    this.reviewAverage,
    required this.url,
    required this.isAffiliate,
    required this.matchLevel,
    required this.matchedConditions,
    required this.cautions,
  });
}
