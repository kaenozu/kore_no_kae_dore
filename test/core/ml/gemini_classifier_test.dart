// test/core/ml/gemini_classifier_test.dart
// GeminiClassifierのユニットテスト（モデル名定数とMIME検出）
// 関連: gemini_classifier.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:kore_no_kae_dore/core/ml/gemini_classifier.dart';

void main() {
  group('GeminiModelNames', () {
    test('candidates に3つのモデル名が含まれる', () {
      expect(GeminiModelNames.candidates.length, 3);
    });

    test('安定モデルが最初に設定されている', () {
      expect(GeminiModelNames.candidates[0], contains('gemini-2.5'));
    });

    test('unknown は空文字ではない', () {
      expect(GeminiModelNames.unknown, isNotEmpty);
    });
  });

  group('GeminiClassifier', () {
    test('init前はactiveModelがunknownを返す', () {
      final c = GeminiClassifier();
      expect(c.activeModel, 'unknown');
    });

    test('init前はisReadyがfalseを返す', () {
      final c = GeminiClassifier();
      expect(c.isReady, false);
    });
  });
}
