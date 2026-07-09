// lib/core/models/purchase_result.dart
// 購入結果：最終的にユーザーに表示する情報
// 候補名、検索ワード、買う前チェック、店員用要約を含む
// 関連: result_screen.dart, rule_engine.dart

class PurchaseResult {
  final String id;
  final String sessionId;
  final String candidateTitle;
  final String confidenceLabel; // "高め" | "候補" | "要確認"
  final List<String> searchKeywords;
  final List<String> checkBeforeBuy;
  final String shopStaffSummary;
  final DateTime createdAt;

  PurchaseResult({
    required this.id,
    required this.sessionId,
    required this.candidateTitle,
    required this.confidenceLabel,
    required this.searchKeywords,
    required this.checkBeforeBuy,
    required this.shopStaffSummary,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'candidateTitle': candidateTitle,
        'confidenceLabel': confidenceLabel,
        'searchKeywords': searchKeywords,
        'checkBeforeBuy': checkBeforeBuy,
        'shopStaffSummary': shopStaffSummary,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PurchaseResult.fromJson(Map<String, dynamic> json) => PurchaseResult(
        id: json['id'] as String,
        sessionId: json['sessionId'] as String,
        candidateTitle: json['candidateTitle'] as String,
        confidenceLabel: json['confidenceLabel'] as String,
        searchKeywords:
            (json['searchKeywords'] as List).cast<String>(),
        checkBeforeBuy:
            (json['checkBeforeBuy'] as List).cast<String>(),
        shopStaffSummary: json['shopStaffSummary'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
