// test/features/capture/classification_runner_test.dart
// ClassificationRunner の単体テスト
// 分類実行処理が pure Dart でテスト可能であることを確認
// 関連: lib/features/capture/classification_runner.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:kore_no_kae_dore/core/ml/classifier.dart';
import 'package:kore_no_kae_dore/core/models/classification_result.dart';
import 'package:kore_no_kae_dore/features/capture/classification_runner.dart';

class TrackingClassifier extends Classifier {
  int classifyCallCount = 0;
  String? lastImagePath;

  @override
  Future<ClassificationResult> classify(String imagePath) async {
    classifyCallCount++;
    lastImagePath = imagePath;
    return ClassificationResult(
      id: 'tracking',
      imageId: 'tracking',
      modelVersion: 'tracking',
      predictions: [Prediction(label: 'bulb_full_view', score: 0.95)],
      createdAt: DateTime.now(),
    );
  }
}

class FixedLabelTrackingClassifier extends Classifier with FixedLabelMixin {
  int classifyCallCount = 0;
  String? lastImagePath;

  @override
  Future<ClassificationResult> classify(String imagePath) async {
    classifyCallCount++;
    lastImagePath = imagePath;
    return ClassificationResult(
      id: 'fixed',
      imageId: 'fixed',
      modelVersion: 'v1',
      predictions: [Prediction(label: fixedLabel ?? 'bulb_full_view', score: 0.95)],
      createdAt: DateTime.now(),
    );
  }
}

void main() {
  group('ClassificationRunner', () {
    test('classifier.classify が呼ばれ結果が返る', () async {
      final classifier = TrackingClassifier();
      final runner = ClassificationRunner(classifier);

      final result = await runner.run('/fake/path.jpg');

      expect(classifier.classifyCallCount, 1);
      expect(classifier.lastImagePath, '/fake/path.jpg');
      expect(result, isNotNull);
      expect(result.topLabel, ImageLabel.bulbFullView);
    });

    test('debugLabel 指定時に FixedLabelMixin.fixedLabel が設定される', () async {
      final classifier = FixedLabelTrackingClassifier();
      final runner = ClassificationRunner(classifier);

      await runner.run('/fake/path.jpg', debugLabel: 'bulb_base_view');

      expect(classifier.classifyCallCount, 1);
      expect(classifier.fixedLabel, 'bulb_base_view');
    });
  });
}
