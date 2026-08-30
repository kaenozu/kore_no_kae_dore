import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kore_no_kae_dore/core/models/evidence_state.dart';
import 'package:kore_no_kae_dore/core/session/session_controller.dart';
import 'package:kore_no_kae_dore/core/storage/session_storage.dart';
import 'package:kore_no_kae_dore/features/conversation/conversation_orchestrator.dart';
import 'package:kore_no_kae_dore/features/conversation/models/conversation_turn.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _FakePathProvider extends PathProviderPlatform {
  @override
  Future<String> getApplicationDocumentsPath() async => Directory.systemTemp.path;
}

PromptAction _answer(String field, String value, String label) => PromptAction(
      id: 'answer-$field',
      type: PromptActionType.selectChoice,
      label: label,
      value: value,
      fieldKey: field,
    );

void main() {
  late SessionController controller;
  late ConversationOrchestrator orchestrator;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    PathProviderPlatform.instance = _FakePathProvider();
    final storage = SessionStorage();
    for (final session in await storage.listSessions()) {
      await storage.deleteSession(session.id);
    }
    controller = SessionController();
    orchestrator = ConversationOrchestrator(controller: controller);
    orchestrator.start();
    orchestrator.begin();
    await orchestrator.selectIntent('check_spec');
    await orchestrator.skipToManual();
  });

  tearDown(() async {
    orchestrator.dispose();
    if (controller.session != null) {
      await controller.storage.deleteSession(controller.session!.id);
    }
  });

  test('skipped manual check remains unresolved and blocks result', () async {
    await orchestrator.answerManualCheck(
      _answer('baseSize', Mc.userSkipped, '分からない'),
    );
    await orchestrator.answerManualCheck(
      _answer('colorTone', Mc.bulbColor, '電球色'),
    );
    await orchestrator.answerManualCheck(_answer('brightness', '60', '60'));
    await orchestrator.answerManualCheck(
      _answer('sealedFixture', Mc.sealedNo, 'いいえ'),
    );
    await orchestrator.answerManualCheck(
      _answer('dimmer', Mc.dimmerNo, 'いいえ'),
    );

    expect(controller.evidence!.manualChecks.isComplete, false);
    expect(controller.evidence!.manualChecks.unknownCount, 1);
    expect(orchestrator.step, ConversationStep.waitingForManualCheck);
    expect(orchestrator.turns.last.purpose, '口金サイズの確認');
    expect(
      orchestrator.turns.any((turn) => turn.message.contains('未確認項目')),
      true,
    );
  });
}
