// test/rules/rule_engine_test.dart
// ルールエンジンの単体テスト
// 関連: rule_engine.dart, evidence_state.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:kore_no_kae_dore/core/models/evidence_state.dart';
import 'package:kore_no_kae_dore/core/rules/rule_engine.dart';

void main() {
  late RuleEngine engine;
  late String sessionId;

  setUp(() {
    engine = RuleEngine();
    sessionId = 'test-session-001';
  });

  group('RuleEngine.process()', () {
    test(
        'bulb_full_view未撮影の場合、口金撮影指示（full_view）を返す', () {
      final evidence = EvidenceState(sessionId: sessionId);

      final output = engine.process(evidence);

      expect(output.type, 'next_instruction');
      expect(output.requiredStep, 'full_view');
      expect(output.title, contains('電球全体'));
    });

    test('3回失敗時に手動確認へ誘導する', () {
      final evidence = EvidenceState(sessionId: sessionId);

      final output = engine.process(evidence, failedAttempts: 3);

      expect(output.type, 'manual_check');
      expect(output.title, contains('うまくいきません'));
    });

    test('全エビデンスが揃うとpurchase_resultを返す', () {
      final evidence = EvidenceState(sessionId: sessionId);
      evidence.fullViewCaptured = true;
      evidence.baseViewCaptured = true;
      evidence.labelViewCaptured = true;
      evidence.fixtureChecked = true;
      evidence.manualChecks.baseSize = 'e26_candidate';
      evidence.manualChecks.colorTone = 'bulb_color';
      evidence.manualChecks.brightness = '60';
      evidence.manualChecks.sealedFixture = 'no';
      evidence.manualChecks.dimmer = 'no';

      final output = engine.process(evidence);

      expect(output.type, 'purchase_result');
      expect(output.warnings.any((w) => w.contains('候補')), true);
    });

    test('PurchaseResultに禁止された断定表現が含まれない', () {
      final evidence = EvidenceState(sessionId: sessionId);
      evidence.fullViewCaptured = true;
      evidence.baseViewCaptured = true;
      evidence.labelViewCaptured = true;
      evidence.fixtureChecked = true;
      evidence.manualChecks.baseSize = 'e26_candidate';
      evidence.manualChecks.colorTone = 'bulb_color';
      evidence.manualChecks.brightness = '60';
      evidence.manualChecks.sealedFixture = 'no';
      evidence.manualChecks.dimmer = 'no';

      final output = engine.process(evidence);

      expect(output.type, 'purchase_result');

      final allText = [
        output.title,
        output.message,
        ...output.warnings,
      ].join(' ');
      expect(allText, isNot(contains('これで確定です')));
      expect(allText, isNot(contains('必ず使えます')));
      expect(allText, isNot(contains('100%判定')));
    });

    test('手動確認が未完了の場合、manual_checkを返す', () {
      final evidence = EvidenceState(sessionId: sessionId);
      evidence.fullViewCaptured = true;
      evidence.baseViewCaptured = true;
      evidence.labelViewCaptured = true;
      evidence.fixtureChecked = true;

      final output = engine.process(evidence);

      expect(output.type, 'manual_check');
    });
  });

  group('RuleEngine.handlePoorQuality()', () {
    test('too_darkの場合、明るい場所での再撮影指示を返す', () {
      final output = engine.handlePoorQuality('too_dark');

      expect(output.type, 'next_instruction');
      expect(output.title, contains('暗すぎます'));
      expect(output.message, contains('明るい'));
    });

    test('unknown_too_darkの場合、「暗すぎます」を返す', () {
      final output = engine.handlePoorQuality('unknown_too_dark');

      expect(output.type, 'next_instruction');
      expect(output.title, contains('暗すぎます'));
      expect(output.message, contains('明るい'));
    });

    test('blurryの場合、ピント再調整指示を返す', () {
      final output = engine.handlePoorQuality('blurry');

      expect(output.type, 'next_instruction');
      expect(output.title, contains('ピント'));
    });

    test('unknown_blurryの場合、「ピントが合っていません」を返す', () {
      final output = engine.handlePoorQuality('unknown_blurry');

      expect(output.type, 'next_instruction');
      expect(output.title, contains('ピント'));
    });

    test('too_farの場合、近づく指示を返す', () {
      final output = engine.handlePoorQuality('too_far');

      expect(output.type, 'next_instruction');
      expect(output.title, contains('遠すぎます'));
    });

    test('unknown_too_farの場合、「遠すぎます」を返す', () {
      final output = engine.handlePoorQuality('unknown_too_far');

      expect(output.type, 'next_instruction');
      expect(output.title, contains('遠すぎます'));
    });

    test('未知のラベルはデフォルトメッセージにフォールバックする', () {
      final output = engine.handlePoorQuality('unknown_other');

      expect(output.type, 'next_instruction');
      expect(output.title, contains('撮り直してください'));
    });
  });

  group('ManualChecks.isComplete', () {
    test('全てunknownの場合はfalse', () {
      final checks = ManualChecks();

      expect(checks.isComplete, false);
    });

    test('全て入力済みの場合はtrue', () {
      final checks = ManualChecks(
        baseSize: 'e26_candidate',
        colorTone: 'bulb_color',
        brightness: '60',
        sealedFixture: 'no',
        dimmer: 'no',
      );

      expect(checks.isComplete, true);
    });

    test('一部のみ入力の場合はfalse', () {
      final checks = ManualChecks(
        baseSize: 'e26_candidate',
        colorTone: 'bulb_color',
      );

      expect(checks.isComplete, false);
    });
  });
}
