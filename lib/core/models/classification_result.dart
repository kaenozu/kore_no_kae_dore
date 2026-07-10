// lib/core/models/classification_result.dart
// 画像分類の結果
// 9クラスの分類ラベルとそのスコアを持つ
// 関連: evidence_state.dart, rule_engine.dart

enum ImageLabel {
  bulbFullView,
  bulbBaseView,
  bulbLabelSideView,
  fixtureSocketView,
  bulbPackageView,
  unknownTooDark,
  unknownBlurry,
  unknownTooFar,
  unknownOther;

  String get value => switch (this) {
    ImageLabel.bulbFullView => 'bulb_full_view',
    ImageLabel.bulbBaseView => 'bulb_base_view',
    ImageLabel.bulbLabelSideView => 'bulb_label_side_view',
    ImageLabel.fixtureSocketView => 'fixture_socket_view',
    ImageLabel.bulbPackageView => 'bulb_package_view',
    ImageLabel.unknownTooDark => 'unknown_too_dark',
    ImageLabel.unknownBlurry => 'unknown_blurry',
    ImageLabel.unknownTooFar => 'unknown_too_far',
    ImageLabel.unknownOther => 'unknown_other',
  };

  static ImageLabel fromString(String s) => switch (s) {
    'bulb_full_view' => ImageLabel.bulbFullView,
    'bulb_base_view' => ImageLabel.bulbBaseView,
    'bulb_label_side_view' => ImageLabel.bulbLabelSideView,
    'fixture_socket_view' => ImageLabel.fixtureSocketView,
    'bulb_package_view' => ImageLabel.bulbPackageView,
    'unknown_too_dark' => ImageLabel.unknownTooDark,
    'unknown_blurry' => ImageLabel.unknownBlurry,
    'unknown_too_far' => ImageLabel.unknownTooFar,
    _ => ImageLabel.unknownOther,
  };

  bool get isPoorQuality => switch (this) {
    ImageLabel.unknownTooDark || ImageLabel.unknownBlurry || ImageLabel.unknownTooFar => true,
    _ => false,
  };
}

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

  ImageLabel get topLabel =>
      predictions.isNotEmpty
          ? ImageLabel.fromString(predictions.first.label)
          : ImageLabel.unknownOther;

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
