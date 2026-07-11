// test/features/conversation/conversation_orchestrator_test.dart
// ConversationOrchestratorの単体テスト
// 会話フローの各ステップ遷移を検証
// 関連: lib/features/conversation/conversation_orchestrator.dart

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kore_no_kae_dore/core/ml/classifier.dart';
import 'package:kore_no_kae_dore/core/models/classification_result.dart';
import 'package:kore_no_kae_dore/core/models/evidence_state.dart';
import 'package:kore_no_kae_dore/core/session/session_controller.dart';
import 'package:kore_no_kae_dore/core/storage/session_storage.dart';
import 'package:kore_no_kae_dore/features/conversation/conversation_orchestrator.dart';
import 'package:kore_no_kae_dore/features/conversation/models/conversation_turn.dart';
import 'package:kore_no_kae_dore/features/conversation/prompts/fixed_prompt_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class FakePathProvider extends PathProviderPlatform {
  @override
  Future<String> getApplicationDocumentsPath() async {
    return Directory.systemTemp.path;
  }
}

void main() {
  late SessionController controller;
  late ConversationOrchestrator orch;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    PathProviderPlatform.instance = FakePathProvider();
    final cleanupStorage = SessionStorage();
    for (final s in await cleanupStorage.listSessions()) {
      await cleanupStorage.deleteSession(s.id);
    }
    controller = SessionController();
    orch = ConversationOrchestrator(controller: controller);
  });

  tearDown(() async {
    orch.dispose();
    if (controller.session != null) {
      await controller.storage.deleteSession(controller.session!.id);
    }
  });

  group('ConversationOrchestrator', () {
    test('start() clears turns and adds introduction', () {
      expect(orch.turns.length, 0);

      orch.start();

      expect(orch.turns.length, 1);
      expect(orch.turns[0].role, ConversationRole.agent);
      expect(orch.turns[0].actions[0].label, '始める');
      expect(orch.step, ConversationStep.introduction);
    });

    test('start() resets intent, processing state', () async {
      orch.start();
      orch.begin();
      await orch.selectIntent('check_spec');
      await orch.skipToManual();
      final action = PromptAction(
        id: 'test',
        type: PromptActionType.selectChoice,
        label: 'E26',
        value: Mc.userSelectedE26,
        fieldKey: 'baseSize',
      );
      await orch.answerManualCheck(action);

      orch.start();

      expect(orch.intent, isNull);
      expect(orch.isProcessing, false);
      expect(orch.step, ConversationStep.introduction);
      expect(orch.turns.length, 1);
    });

    test('begin() transitions to intentSelection', () {
      orch.start();

      orch.begin();

      expect(orch.turns.length, 3);
      expect(orch.turns[1].role, ConversationRole.user);
      expect(orch.turns[1].message, '始める');
      expect(orch.turns[2].role, ConversationRole.agent);
      expect(orch.step, ConversationStep.intentSelection);
    });

    test(
      'selectIntent("find_same") starts session and shows photo request',
      () async {
        orch.start();
        orch.begin();

        await orch.selectIntent('find_same');

        expect(orch.intent, 'find_same');
        expect(controller.session, isNotNull);
        expect(controller.session!.category, 'bulb');
        expect(orch.step, ConversationStep.waitingForPhoto);
        expect(orch.turns.last.role, ConversationRole.agent);
        final photoActions = orch.turns.last.actions;
        expect(
          photoActions.any((a) => a.type == PromptActionType.takePhoto),
          true,
        );
        expect(
          photoActions.any((a) => a.type == PromptActionType.pickImage),
          true,
        );
        expect(photoActions.any((a) => a.type == PromptActionType.skip), true);
      },
    );

    test(
      'selectIntent("check_spec") starts session with manualFallback',
      () async {
        orch.start();
        orch.begin();

        await orch.selectIntent('check_spec');

        expect(orch.intent, 'check_spec');
        expect(controller.evidence, isNotNull);
        expect(controller.evidence!.manualFallback, true);
      },
    );

    test('skipToManual() falls back to manual checks', () async {
      orch.start();
      orch.begin();
      await orch.selectIntent('find_same');

      await orch.skipToManual();

      expect(orch.step, ConversationStep.waitingForManualCheck);
      expect(orch.turns.last.role, ConversationRole.agent);
      expect(orch.turns.last.purpose, '口金サイズの確認');
      expect(orch.turns.last.actions.any((a) => a.label == 'E26'), true);
      expect(orch.turns.last.actions.any((a) => a.label == '分からない'), true);
    });

    test(
      'answerManualCheck("baseSize", "E26") updates field and shows next check',
      () async {
        orch.start();
        orch.begin();
        await orch.selectIntent('check_spec');
        await orch.skipToManual();

        final action = PromptAction(
          id: 'test',
          type: PromptActionType.selectChoice,
          label: 'E26',
          value: Mc.userSelectedE26,
          fieldKey: 'baseSize',
        );
        await orch.answerManualCheck(action);

        expect(controller.evidence!.manualChecks.baseSize, Mc.userSelectedE26);
        expect(controller.evidence!.manualChecks.colorTone, Mc.unknown);
        expect(orch.turns.last.purpose, '光の色の確認');
      },
    );

    test('分からない skips field and moves to next question', () async {
      orch.start();
      orch.begin();
      await orch.selectIntent('check_spec');
      await orch.skipToManual();

      final action = PromptAction(
        id: 'test',
        type: PromptActionType.selectChoice,
        label: '分からない',
        value: Mc.userSkipped,
        fieldKey: 'baseSize',
      );
      await orch.answerManualCheck(action);

      expect(controller.evidence!.manualChecks.baseSize, Mc.userSkipped);
      expect(orch.turns.last.purpose, '光の色の確認');
    });

    test('all manual checks completed shows readyForResult', () async {
      orch.start();
      orch.begin();
      await orch.selectIntent('check_spec');
      await orch.skipToManual();

      final fields = [
        'baseSize',
        'colorTone',
        'brightness',
        'sealedFixture',
        'dimmer',
      ];
      final values = [
        Mc.userSelectedE26,
        Mc.bulbColor,
        '60',
        Mc.sealedNo,
        Mc.dimmerNo,
      ];
      final labels = ['E26', '電球色', '60', 'いいえ', 'いいえ'];

      for (var i = 0; i < fields.length; i++) {
        final action = PromptAction(
          id: 'test$i',
          type: PromptActionType.selectChoice,
          label: labels[i],
          value: values[i],
          fieldKey: fields[i],
        );
        await orch.answerManualCheck(action);
      }

      expect(orch.step, ConversationStep.readyForResult);
      expect(orch.turns.last.purpose, '完了');
      expect(controller.evidence!.manualChecks.isComplete, true);
    });

    test('error turns show as system messages, not user messages', () async {
      orch.start();
      orch.begin();
      await orch.selectIntent('find_same');

      await orch.processPhoto('/nonexistent.jpg', _FailingClassifier());

      final systemTurns = orch.turns.where(
        (t) => t.role == ConversationRole.system,
      );
      expect(systemTurns.any((t) => t.message.contains('エラー')), true);

      final userTurns = orch.turns.where(
        (t) => t.role == ConversationRole.user,
      );
      expect(userTurns.any((t) => t.message.contains('エラー')), false);
    });
  });
}

class _FailingClassifier extends Classifier {
  @override
  Future<ClassificationResult> classify(String imagePath) async {
    throw Exception('mock error');
  }
}
