import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kore_no_kae_dore/core/models/capture_session.dart';
import 'package:kore_no_kae_dore/core/models/evidence_state.dart';
import 'package:kore_no_kae_dore/core/models/match_level.dart';
import 'package:kore_no_kae_dore/core/models/purchase_result.dart';
import 'package:kore_no_kae_dore/core/session/session_controller.dart';
import 'package:kore_no_kae_dore/core/storage/purchase_result_storage.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.path);
  final String path;

  @override
  Future<String> getApplicationDocumentsPath() async => path;
}

void main() {
  late Directory tempDir;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('kore-result-recovery-');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('loadSession repairs a durable result whose session commit was lost', () async {
    final now = DateTime(2026, 8, 30);
    final session = CaptureSession(
      id: 'session-recovery',
      category: 'bulb',
      status: 'in_progress',
      currentStep: StepName.manualCheck,
      createdAt: now,
      updatedAt: now,
    );
    final evidence = EvidenceState(
      sessionId: session.id,
      manualFallback: true,
      manualChecks: ManualChecks(
        baseSize: Mc.userSelectedE26,
        colorTone: Mc.bulbColor,
        brightness: '60',
        sealedFixture: Mc.sealedNo,
        dimmer: Mc.dimmerNo,
      ),
    );
    final result = PurchaseResult(
      id: 'result-recovery',
      sessionId: session.id,
      candidateTitle: 'E26 LED電球',
      confidenceLabel: '候補',
      searchKeywords: const ['E26 LED電球'],
      checkBeforeBuy: const ['口金を確認'],
      shopStaffSummary: 'E26候補',
      createdAt: now,
      matchLevel: MatchLevel.manualCandidate,
    );

    await PurchaseResultStorage().saveResult(result);

    final controller = SessionController();
    await controller.loadSession(session, evidence);

    expect(controller.lastResult?.id, result.id);
    expect(controller.session?.status, 'completed');
    expect(controller.session?.currentStep, StepName.result);
    expect(controller.session?.resultId, result.id);

    final repaired = await controller.storage.loadSession(session.id);
    expect(repaired?.status, 'completed');
    expect(repaired?.resultId, result.id);
  });
}
