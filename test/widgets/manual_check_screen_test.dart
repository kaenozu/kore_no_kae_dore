import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kore_no_kae_dore/core/models/capture_session.dart';
import 'package:kore_no_kae_dore/core/models/evidence_state.dart';
import 'package:kore_no_kae_dore/core/models/rule_engine_output.dart';
import 'package:kore_no_kae_dore/features/manual_check/manual_check_screen.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../helpers/mock_session_controller.dart';

class FakePathProvider extends PathProviderPlatform {
  @override
  Future<String> getApplicationDocumentsPath() async {
    return Directory.systemTemp.path;
  }
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: child,
    routes: {
      '/result': (_) => const Scaffold(body: Text('result')),
      '/capture': (_) => const Scaffold(body: Text('capture')),
    },
  );
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    PathProviderPlatform.instance = FakePathProvider();
  });

  group('ManualCheckScreen', () {
    testWidgets('セッションなし → セッションがありません を表示', (tester) async {
      final controller = StubSessionController(evidence: null);
      await tester.pumpWidget(_wrap(ManualCheckScreen(controller: controller)));

      expect(find.text('セッションがありません'), findsOneWidget);
    });

    testWidgets('全フィールド unknown → 5項目すべて表示、確認ボタンは無効', (tester) async {
      final session = CaptureSession(
        id: 'test-1',
        category: 'bulb',
        status: 'in_progress',
        currentStep: StepName.manualCheck,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final evidence = EvidenceState(sessionId: 'test-1');
      final controller = StubSessionController(session: session, evidence: evidence);

      await tester.pumpWidget(_wrap(ManualCheckScreen(controller: controller)));

      expect(find.text('口金サイズ'), findsOneWidget);
      expect(find.text('光色'), findsOneWidget);
      expect(find.text('明るさ（ワット数相当）'), findsOneWidget);
      expect(find.text('密閉器具'), findsOneWidget);
      expect(find.text('調光器'), findsOneWidget);

      final confirmButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, '確認して次へ'),
      );
      expect(confirmButton.onPressed, isNull);
    });

    testWidgets('全項目選択すると確認ボタンが有効になる', (tester) async {
      final session = CaptureSession(
        id: 'test-2',
        category: 'bulb',
        status: 'in_progress',
        currentStep: StepName.manualCheck,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final evidence = EvidenceState(sessionId: 'test-2');
      final controller = StubSessionController(session: session, evidence: evidence);

      await tester.pumpWidget(_wrap(ManualCheckScreen(controller: controller)));

      await tester.tap(find.text('E26（直径26mm / 一般的なサイズ）'));
      await tester.pump();
      var confirmButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, '確認して次へ'),
      );
      expect(confirmButton.onPressed, isNull);

      await tester.tap(find.text('電球色（オレンジがかった暖かい色）'));
      await tester.pump();
      await tester.tap(find.text('60形相当（標準）'));
      await tester.pump();
      await tester.tap(find.text('密閉器具ではない'));
      await tester.pump();
      await tester.tap(find.text('調光スイッチは使っていない'));
      await tester.pump();

      confirmButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, '確認して次へ'),
      );
      expect(confirmButton.onPressed, isNotNull);
    });

    testWidgets('一部既知 + 一部 unknown → unknown のみ表示', (tester) async {
      final session = CaptureSession(
        id: 'test-3',
        category: 'bulb',
        status: 'in_progress',
        currentStep: StepName.manualCheck,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final evidence = EvidenceState(
        sessionId: 'test-3',
        manualChecks: ManualChecks(
          baseSize: Mc.e26Candidate,
          colorTone: Mc.bulbColor,
          brightness: Mc.unknown,
          sealedFixture: Mc.unknown,
          dimmer: Mc.dimmerNo,
        ),
      );
      final controller = StubSessionController(session: session, evidence: evidence);

      await tester.pumpWidget(_wrap(ManualCheckScreen(controller: controller)));

      expect(find.text('口金サイズ'), findsNothing);
      expect(find.text('光色'), findsNothing);
      expect(find.text('調光器'), findsNothing);

      expect(find.text('明るさ（ワット数相当）'), findsOneWidget);
      expect(find.text('密閉器具'), findsOneWidget);
    });

    testWidgets('確認して次へ → updateManualCheck が呼ばれる', (tester) async {
      final session = CaptureSession(
        id: 'test-4',
        category: 'bulb',
        status: 'in_progress',
        currentStep: StepName.manualCheck,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final evidence = EvidenceState(sessionId: 'test-4');
      String? capturedBaseSize;
      final controller = StubSessionController(
        session: session,
        evidence: evidence,
        onUpdateManualCheck: ({baseSize, colorTone, brightness, sealedFixture, dimmer}) async {
          capturedBaseSize = baseSize;
        },
      );
      controller.testLastOutput = RuleEngineOutput(
        type: OutputType.manualCheck,
        title: '手動確認',
        message: '確認してください',
      );

      await tester.pumpWidget(_wrap(ManualCheckScreen(controller: controller)));

      await tester.tap(find.text('E26（直径26mm / 一般的なサイズ）'));
      await tester.pump();
      await tester.tap(find.text('電球色（オレンジがかった暖かい色）'));
      await tester.pump();
      await tester.tap(find.text('60形相当（標準）'));
      await tester.pump();
      await tester.tap(find.text('密閉器具ではない'));
      await tester.pump();
      await tester.tap(find.text('調光スイッチは使っていない'));
      await tester.pump();

      await tester.tap(find.text('確認して次へ'));
      await tester.pump();

      expect(capturedBaseSize, equals('e26_candidate'));
    });
  });
}
