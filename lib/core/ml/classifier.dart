// lib/core/ml/classifier.dart
// 画像分類器のインターフェース定義
// MockClassifierと将来のTFLiteClassifierで共通のインターフェース
// 関連: mock_classifier.dart, analysis_instruction_screen.dart

import '../models/classification_result.dart';

abstract class Classifier {
  /// 画像を分類し、ClassificationResultを返す
  /// [imagePath] はローカルファイルのパス
  Future<ClassificationResult> classify(String imagePath);
}

/// デバッグ用：MockClassifier が固定ラベルを受け付けるためのmixin
mixin FixedLabelMixin on Classifier {
  String? fixedLabel;
  double fixedScore = 0.85;
}
