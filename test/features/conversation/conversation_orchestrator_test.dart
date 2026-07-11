// test/features/conversation/conversation_orchestrator_test.dart
// ConversationOrchestratorの単体テスト
// 会話フローの各ステップ遷移を検証
// 関連: lib/features/conversation/conversation_orchestrator.dart

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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

    test('begin() transitions to intentSelection', () {
      orch.start();

      orch.begin();

      expect(orch.turns.length, 3);
      expect(orch.turns[1].role, ConversationRole.user);
      expect(orch.turns[1].message, '始める');
      expect(orch.turns[2].role, ConversationRole.agent);
      expect(orch.step, ConversationStep.intentSelection);
    });

    test('selectIntent("find_same") starts session and shows photo request', () async {
      orch.start();
      orch.begin();

      await orch.selectIntent('find_same');

      expect(orch.intent, 'find_same');
      expect(controller.session, isNotNull);
      expect(controller.session!.category, 'bulb');
      expect(orch.step, ConversationStep.waitingForPhoto);
      expect(orch.turns.last.role, ConversationRole.agent);
      final photoActions = orch.turns.last.actions;
      expect(photoActions.any((a) => a.type == PromptActionType.takePhoto), true);
      expect(photoActions.any((a) => a.type == PromptActionType.pickImage), true);
      expect(photoActions.any((a) => a.type == PromptActionType.skip), true);
    });

    test('selectIntent("check_spec") starts session with manualFallback', () async {
      orch.start();
      orch.begin();

      await orch.selectIntent('check_spec');

      expect(orch.intent, 'check_spec');
      expect(controller.evidence, isNotNull);
      expect(controller.evidence!.manualFallback, true);
    });

    test('skipToManual() falls back to manual checks', () async {
      orch.start();
      orch.begin();
      await orch.selectIntent('find_same');

      await orch.skipToManual();

      expect(orch.step, ConversationStep.waitingForManualCheck);
      expect(orch.turns.last.role, ConversationRole.agent);
      expect(orch.turns.last.purpose, '口金サイズの確認');
      expect(
        orch.turns.last.actions.any((a) => a.label == 'E26'),
        true,
      );
      expect(
        orch.turns.last.actions.any((a) => a.label == '分からない'),
        true,
      );
    });

    test('answerManualCheck("baseSize", "E26") updates field and shows next check',
        () async {
      orch.start();
      orch.begin();
      await orch.selectIntent('check_spec');
      // スキップして手動確認へ
      await orch.skipToManual();

      // 最初の手動確認（baseSize）に回答
      await orch.answerManualCheck('baseSize', 'E26');

      expect(controller.evidence!.manualChecks.baseSize, 'user_selected_e26');
      expect(
        controller.evidence!.manualChecks.colorTone,
        'unknown',
      );
      // 次の手動確認（colorTone）が表示されている
      expect(orch.turns.last.purpose, '光の色の確認');
    });
  });
}
