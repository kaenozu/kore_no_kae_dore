// lib/core/ml/mock_classifier.dart
// ダミーの分類結果を返すMockClassifier
// 画面遷移のテスト用。将来的にTFLiteClassifierと差し替える
// 関連: classifier.dart, analysis_instruction_screen.dart

import 'dart:math';

import 'package:uuid/uuid.dart';

import '../models/classification_result.dart';
import 'classifier.dart';

class MockClassifier extends Classifier {
  final _random = Random();
  final _uuid = Uuid();

  // デバッグ用に固定ラベルを指定できる（null = ランダム）
  String? fixedLabel;
  double fixedScore = 0.85;

  MockClassifier({this.fixedLabel});

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
    const labels = [
      'bulb_full_view',
      'bulb_base_view',
      'bulb_label_side_view',
      'fixture_socket_view',
      'bulb_package_view',
      'unknown_too_dark',
      'unknown_blurry',
      'unknown_too_far',
      'unknown_other',
    ];
    return labels[_random.nextInt(labels.length)];
  }

  String _fallbackLabel(String label) {
    const allLabels = [
      'bulb_full_view',
      'bulb_base_view',
      'bulb_label_side_view',
      'fixture_socket_view',
      'bulb_package_view',
      'unknown_too_dark',
      'unknown_blurry',
      'unknown_too_far',
      'unknown_other',
    ];
    for (final l in allLabels) {
      if (l != label) return l;
    }
    return 'unknown_other';
  }
}
