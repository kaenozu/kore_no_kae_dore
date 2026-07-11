// test/widgets/conversation_screen_test.dart
// ConversationScreenのウィジェットテスト
// 画面表示と基本的な操作を検証
// 関連: lib/features/conversation/conversation_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kore_no_kae_dore/core/ml/classifier.dart';
import 'package:kore_no_kae_dore/core/ml/mock_classifier.dart';
import 'package:kore_no_kae_dore/core/session/session_controller.dart';
import 'package:kore_no_kae_dore/core/storage/session_storage.dart';
import 'package:kore_no_kae_dore/features/conversation/conversation_orchestrator.dart';
import 'package:kore_no_kae_dore/features/conversation/conversation_screen.dart';
import 'package:kore_no_kae_dore/features/conversation/models/conversation_turn.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class FakePathProvider extends PathProviderPlatform {
  @override
  Future<String> getApplicationDocumentsPath() async {
    return Directory.systemTemp.path;
  }
}

Widget buildTestApp(ConversationOrchestrator orch) {
  return MaterialApp(
    home: ConversationScreen(
      orchestrator: orch,
      classifierNotifier: ValueNotifier<Classifier>(MockClassifier()),
      debugLabelNotifier: ValueNotifier<String?>(null),
    ),
  );
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

  group('ConversationScreen', () {
    testWidgets('renders disclaimer text', (tester) async {
      await tester.pumpWidget(buildTestApp(orch));
      await tester.pump();

      expect(
        find.textContaining('商品が完全に同じであることは保証しません'),
        findsAtLeast(1),
      );
    });

    testWidgets('shows introduction card after start', (tester) async {
      await tester.pumpWidget(buildTestApp(orch));
      await tester.pump();

      expect(find.text('始める'), findsOneWidget);
      expect(find.textContaining('電球の買い替えに特化'), findsOneWidget);
    });

    testWidgets('tapping 始める transitions to intent selection', (tester) async {
      await tester.pumpWidget(buildTestApp(orch));
      await tester.pump();

      await tester.tap(find.text('始める'));
      await tester.pump();

      expect(find.text('同じ電球を探したい'), findsOneWidget);
      expect(find.text('条件だけ確認したい'), findsOneWidget);
    });

    testWidgets('conditions panel toggles visibility', (tester) async {
      await tester.pumpWidget(buildTestApp(orch));
      await tester.pump();

      expect(find.text('現在分かっている条件'), findsNothing);

      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pump();

      expect(find.text('現在分かっている条件'), findsOneWidget);
    });

    testWidgets('selecting intent shows photo request', (tester) async {
      await tester.pumpWidget(buildTestApp(orch));
      await tester.pump();

      await tester.tap(find.text('始める'));
      await tester.pump();

      await tester.runAsync(() async {
        await tester.tap(find.text('同じ電球を探したい'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();

      expect(find.textContaining('電球全体が入るように撮影してください'), findsOneWidget);
    });

    testWidgets('manual check card shows fields after skip', (tester) async {
      // 最初にオーケストレーターを手動確認まで進める
      await tester.runAsync(() async {
        orch.start();
        orch.begin();
        await orch.selectIntent('check_spec');
        await orch.skipToManual();
      });

      // 画面構築後に initState が orch.start() を呼ぶが、
      // 画面構築後にオーケストレーターの状態を上書きして手動確認状態にする
      await tester.pumpWidget(buildTestApp(orch));
      // initState で orch.start() が呼ばれる → ターンがクリアされて初回プロンプトだけになる
      // ここで状態を直接復元するのが難しいので、画面構築後に再度 runAsync で進める
      await tester.runAsync(() async {
        orch.begin();
        await orch.selectIntent('check_spec');
        await orch.skipToManual();
      });
      await tester.pumpAndSettle();

      // 口金サイズの手動確認が表示されている
      expect(find.textContaining('口金サイズの確認'), findsOneWidget);
    });
  });
}
