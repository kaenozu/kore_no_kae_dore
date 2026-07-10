// test/core/models/match_level_test.dart
// MatchLevel のラベル・注意文・JSON整合性のテスト
// 関連: lib/core/models/match_level.dart, lib/core/models/purchase_result.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:kore_no_kae_dore/core/models/match_level.dart';
import 'package:kore_no_kae_dore/core/models/purchase_result.dart';

void main() {
  group('MatchLevelLabel', () {
    test('各レベルにlabelとcautionが設定されている', () {
      for (final level in MatchLevel.values) {
        expect(level.label, isNotEmpty);
        expect(level.caution, isNotEmpty);
      }
    });

    test('exactCode の文言が正しい', () {
      expect(MatchLevel.exactCode.label, '型番・コード一致候補');
      expect(MatchLevel.exactCode.caution,
          '型番やコードが一致する候補です。購入前に販売ページの対応条件を確認してください。');
    });

    test('compatibleSpec の文言が正しい', () {
      expect(MatchLevel.compatibleSpec.label, '条件一致候補');
      expect(MatchLevel.compatibleSpec.caution,
          '入力された条件に合いそうな候補です。購入前に規格を確認してください。');
    });

    test('inferred の文言が正しい', () {
      expect(MatchLevel.inferred.label, 'AI推定候補');
      expect(MatchLevel.inferred.caution,
          '写真からの推定を含みます。購入前に必ず現物・パッケージで確認してください。');
    });

    test('manualCandidate の文言が正しい', () {
      expect(MatchLevel.manualCandidate.label, '手動入力候補');
      expect(MatchLevel.manualCandidate.caution,
          '手動入力に基づく候補です。入力内容と商品ページを照合してください。');
    });
  });

  group('PurchaseResult matchLevel JSON ラウンドトリップ', () {
    test('matchLevel がJSON保存/復元できる', () {
      final result = PurchaseResult(
        id: 'r1',
        sessionId: 's1',
        candidateTitle: 'E26 LED電球',
        confidenceLabel: '候補',
        searchKeywords: ['E26 LED電球'],
        checkBeforeBuy: ['口金を確認'],
        shopStaffSummary: 'E26口金のLED電球',
        createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
        matchLevel: MatchLevel.manualCandidate,
      );

      final json = result.toJson();
      final restored = PurchaseResult.fromJson(json);

      expect(restored.matchLevel, MatchLevel.manualCandidate);
      expect(restored.candidateTitle, result.candidateTitle);
    });

    test('古いJSONに matchLevel が無くても読み込める（compatibleSpec fallback）', () {
      final json = <String, dynamic>{
        'id': 'r-old',
        'sessionId': 's-old',
        'candidateTitle': 'E26 LED電球',
        'confidenceLabel': '候補',
        'searchKeywords': <String>[],
        'checkBeforeBuy': <String>[],
        'shopStaffSummary': '',
        'createdAt': '2024-01-01T00:00:00Z',
      };

      final result = PurchaseResult.fromJson(json);

      expect(result.matchLevel, MatchLevel.compatibleSpec);
    });

    test('不明な matchLevel 値でも安全に fallback する（compatibleSpec）', () {
      final json = <String, dynamic>{
        'id': 'r-unknown',
        'sessionId': 's-unknown',
        'candidateTitle': 'E26 LED電球',
        'confidenceLabel': '候補',
        'searchKeywords': <String>[],
        'checkBeforeBuy': <String>[],
        'shopStaffSummary': '',
        'createdAt': '2024-01-01T00:00:00Z',
        'matchLevel': 'does_not_exist',
      };

      final result = PurchaseResult.fromJson(json);

      expect(result.matchLevel, MatchLevel.compatibleSpec);
    });
  });
}
