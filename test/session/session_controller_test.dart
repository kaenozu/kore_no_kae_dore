// test/session/session_controller_test.dart
// SessionControllerの単体テスト
// 関連: session_controller.dart, rule_engine.dart, evidence_state.dart

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kore_no_kae_dore/core/models/capture_session.dart';
import 'package:kore_no_kae_dore/core/models/classification_result.dart';
import 'package:kore_no_kae_dore/core/models/evidence_state.dart';
import 'package:kore_no_kae_dore/core/models/rule_engine_output.dart';
import 'package:kore_no_kae_dore/core/session/session_controller.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

ClassificationResult _result(ImageLabel label) {
  return ClassificationResult(
    id: 'test',
    imageId: 'test',
    modelVersion: 'v1',
    predictions: [Prediction(label: label.value, score: 0.95)],
    createdAt: DateTime.now(),
  );
}

class FakePathProvider extends PathProviderPlatform {
  @override
  Future<String> getApplicationDocumentsPath() async {
    return Directory.systemTemp.path;
  }
}

void main() {
  late SessionController controller;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    PathProviderPlatform.instance = FakePathProvider();
    controller = SessionController();
  });

  tearDown(() {
    controller.dispose();
  });

  group('startSession()', () {
    test('新しいセッションを作成し、状態を初期化する', () async {
      await controller.startSession('led_bulb');

      expect(controller.session, isNotNull);
      expect(controller.session!.id, isNotEmpty);
      expect(controller.session!.category, 'led_bulb');
      expect(controller.session!.status, 'in_progress');
      expect(controller.session!.currentStep, StepName.fullView);
      expect(controller.evidence, isNotNull);
      expect(controller.evidence!.sessionId, controller.session!.id);
      expect(controller.lastOutput, isNull);
      expect(controller.lastResult, isNull);
      expect(controller.lastClassification, isNull);
    });
  });

  group('processClassification()', () {
    test('bulb_full_viewラベルでエビデンスとステップが更新される', () async {
      await controller.startSession('led_bulb');

      await controller.processClassification(
        _result(ImageLabel.bulbFullView),
      );

      expect(controller.evidence!.fullViewCaptured, true);
      expect(controller.session!.currentStep, StepName.baseView);
      expect(controller.lastClassification, isNotNull);
      expect(controller.lastOutput, isNotNull);
    });

    test('poor qualityラベルでfailedAttemptsが増加する', () async {
      await controller.startSession('led_bulb');

      await controller.processClassification(
        _result(ImageLabel.unknownTooDark),
      );

      expect(controller.session!.failedAttempts, 1);
      expect(controller.lastOutput!.type, OutputType.nextInstruction);
    });

    test('unknown_otherでfailedAttemptsが増加し、processに委譲される', () async {
      await controller.startSession('led_bulb');

      await controller.processClassification(
        _result(ImageLabel.unknownOther),
      );

      expect(controller.session!.failedAttempts, 1);
      expect(controller.lastOutput, isNotNull);
    });

    test('全エビデンスが揃うとfailedAttemptsがリセットされる', () async {
      await controller.startSession('led_bulb');

      // まず1回品質NG
      await controller.processClassification(
        _result(ImageLabel.unknownTooDark),
      );
      expect(controller.session!.failedAttempts, 1);

      // 次に全ラベルを順にクリア
      await controller.processClassification(
        _result(ImageLabel.bulbFullView),
      );
      expect(controller.session!.failedAttempts, 0);
    });

    test('エビデンスがない場合は何もしない', () async {
      // startSessionしていない状態
      await controller.processClassification(
        _result(ImageLabel.bulbFullView),
      );

      expect(controller.lastClassification, isNull);
    });
  });

  group('updateManualCheck()', () {
    test('手動確認の値を更新し、purchaseResultに到達できる', () async {
      await controller.startSession('led_bulb');

      // 全画像エビデンスを設定
      controller.evidence!.fullViewCaptured = true;
      controller.evidence!.baseViewCaptured = true;
      controller.evidence!.labelViewCaptured = true;
      controller.evidence!.fixtureChecked = true;

      await controller.updateManualCheck(
        baseSize: Mc.e26Candidate,
        colorTone: Mc.bulbColor,
        brightness: '60',
        sealedFixture: Mc.sealedNo,
        dimmer: Mc.dimmerNo,
      );

      expect(controller.lastOutput!.type, OutputType.purchaseResult);
      expect(controller.lastResult, isNotNull);
      expect(controller.session!.status, 'completed');
      expect(controller.session!.currentStep, StepName.result);
      expect(controller.session!.resultId, controller.lastResult!.id);
    });

    test('途中の手動確認ではpurchaseResultにならない', () async {
      await controller.startSession('led_bulb');
      controller.evidence!.fullViewCaptured = true;
      controller.evidence!.baseViewCaptured = true;
      controller.evidence!.labelViewCaptured = true;
      controller.evidence!.fixtureChecked = true;

      await controller.updateManualCheck(baseSize: Mc.e26Candidate);

      expect(controller.lastOutput!.type, isNot(OutputType.purchaseResult));
      expect(controller.lastResult, isNull);
    });

    test('エビデンスがない場合は何もしない', () async {
      await controller.updateManualCheck(baseSize: Mc.e26Candidate);

      expect(controller.lastOutput, isNull);
    });
  });

  group('abandonSession()', () {
    test('セッションを破棄して全状態をクリアする', () async {
      await controller.startSession('led_bulb');
      await controller.processClassification(
        _result(ImageLabel.bulbFullView),
      );
      expect(controller.session, isNotNull);

      await controller.abandonSession();

      expect(controller.session, isNull);
      expect(controller.evidence, isNull);
      expect(controller.lastOutput, isNull);
      expect(controller.lastResult, isNull);
      expect(controller.lastClassification, isNull);
    });
  });

  group('reset()', () {
    test('状態をすべて初期状態に戻す', () async {
      await controller.startSession('led_bulb');
      await controller.processClassification(
        _result(ImageLabel.bulbFullView),
      );

      controller.reset();

      expect(controller.session, isNull);
      expect(controller.evidence, isNull);
      expect(controller.lastOutput, isNull);
      expect(controller.lastResult, isNull);
      expect(controller.lastClassification, isNull);
    });
  });
}
