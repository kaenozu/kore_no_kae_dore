// lib/core/ml/mock_classifier.dart
// ダミーの分類結果を返すMockClassifier
// 画面遷移のテスト用。将来的にTFLiteClassifierと差し替える
// 関連: classifier.dart, analysis_instruction_screen.dart

import 'dart:math';

import 'package:uuid/uuid.dart';

import '../models/classification_result.dart';
import 'classifier.dart';

class MockClassifier extends Classifier with FixedLabelMixin {
  final _random = Random();
  final _uuid = Uuid();

  MockClassifier({String? fixedLabel}) {
    this.fixedLabel = fixedLabel;
  }

  @override
  Future<ClassificationResult> classify(String imagePath) async {
    // 実際の推論時間を模擬
    await Future.delayed(const Duration(milliseconds: 500));

    final label = fixedLabel ?? _randomLabel();
    final predictions = [
      Prediction(label: label, score: fixedScore),
      Prediction(label: _fallbackLabel(label), score: 1.0 - fixedScore),
    ];

    return ClassificationResult(
      id: _uuid.v4(),
      imageId: _uuid.v4(),
      modelVersion: 'bulb-nav-v0.1.0-mock',
      predictions: predictions,
      createdAt: DateTime.now(),
    );
  }

  String _randomLabel() {
    const labels = ImageLabel.values;
    return labels[_random.nextInt(labels.length)].value;
  }

  String _fallbackLabel(String label) {
    for (final l in ImageLabel.values) {
      if (l.value != label) return l.value;
    }
    return ImageLabel.unknownOther.value;
  }
}
