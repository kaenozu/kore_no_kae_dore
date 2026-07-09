// lib/core/models/classification_result.dart
// 画像分類の結果
// 9クラスの分類ラベルとそのスコアを持つ
// 関連: evidence_state.dart, rule_engine.dart

class Prediction {
  final String label;
  final double score;

  const Prediction({required this.label, required this.score});

  Map<String, dynamic> toJson() => {'label': label, 'score': score};

  factory Prediction.fromJson(Map<String, dynamic> json) => Prediction(
        label: json['label'] as String,
        score: (json['score'] as num).toDouble(),
      );
}

class ClassificationResult {
  final String id;
  final String imageId;
  final String modelVersion;
  final List<Prediction> predictions;
  final DateTime createdAt;

  ClassificationResult({
    required this.id,
    required this.imageId,
    required this.modelVersion,
    required this.predictions,
    required this.createdAt,
  });

  String get topLabel =>
      predictions.isNotEmpty ? predictions.first.label : 'unknown_other';

  double get topScore =>
      predictions.isNotEmpty ? predictions.first.score : 0.0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'imageId': imageId,
        'modelVersion': modelVersion,
        'predictions': predictions.map((p) => p.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory ClassificationResult.fromJson(Map<String, dynamic> json) =>
      ClassificationResult(
        id: json['id'] as String,
        imageId: json['imageId'] as String,
        modelVersion: json['modelVersion'] as String,
        predictions: (json['predictions'] as List)
            .map((p) => Prediction.fromJson(p as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
