// lib/features/capture/classification_runner.dart
// 撮影画像の分類を実行するpure Dartクラス
// _onCapture から分類ロジックを分離することでテストしやすくする
// 関連: classifier.dart, capture_guide_screen.dart

import 'package:flutter/foundation.dart';

import '../../core/models/classification_result.dart';
import '../../core/ml/classifier.dart';

class ClassificationRunner {
  final Classifier classifier;

  ClassificationRunner(this.classifier);

  Future<ClassificationResult> run(String imagePath, {String? debugLabel}) async {
    if (debugLabel != null && classifier is FixedLabelMixin) {
      (classifier as FixedLabelMixin).fixedLabel = debugLabel;
    }
    debugPrint('classify using: ${classifier.runtimeType}');
    return await classifier.classify(imagePath);
  }
}
