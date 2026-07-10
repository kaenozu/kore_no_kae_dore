// lib/core/services/product_candidate_provider.dart
// 商品候補の取得を抽象化したインターフェース
// Provider差し替えでMock検索→実API検索へ移行できるようにする
// related: product_candidate.dart, product_search_query.dart

import '../models/product_candidate.dart';
import '../models/product_search_query.dart';

abstract class ProductCandidateProvider {
  Future<List<ProductCandidate>> search(ProductSearchQuery query);
}
