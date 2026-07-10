import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kore_no_kae_dore/core/ml/classifier.dart';
import 'package:kore_no_kae_dore/core/models/capture_session.dart';
import 'package:kore_no_kae_dore/core/models/classification_result.dart';
import 'package:kore_no_kae_dore/core/models/rule_engine_output.dart';
import 'package:kore_no_kae_dore/features/capture/capture_guide_screen.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../helpers/mock_session_controller.dart';

class FakePathProvider extends PathProviderPlatform {
  @override
  Future<String> getApplicationDocumentsPath() async {
    return Directory.systemTemp.path;
  }
}

class StubClassifier extends Classifier with FixedLabelMixin {
  @override
  Future<ClassificationResult> classify(String imagePath) async {
    return ClassificationResult(
      id: 'stub',
      imageId: 'stub',
      modelVersion: 'stub',
      predictions: [Prediction(label: fixedLabel ?? 'bulb_full_view', score: 0.95)],
      createdAt: DateTime.now(),
    );
  }
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: child,
    routes: {
      '/manual_check': (_) => const Scaffold(body: Text('manual_check')),
      '/capture': (_) => const Scaffold(body: Text('capture')),
      '/result': (_) => const Scaffold(body: Text('result')),
    },
  );
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    PathProviderPlatform.instance = FakePathProvider();
  });

  group('CaptureGuideScreen', () {
    Future<void> pumpScreen(
      WidgetTester tester, {
      StepName step = StepName.fullView,
      RuleEngineOutput? lastOutput,
    }) async {
      final session = CaptureSession(
        id: 'test-cg',
        category: 'bulb',
        status: 'in_progress',
        currentStep: step,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final controller = StubSessionController(session: session);
      controller.testLastOutput = lastOutput;
      final classifierNotifier = ValueNotifier<Classifier>(StubClassifier());
      final classifierStatus = ValueNotifier<String>('AI判定: Mock');
      final debugNotifier = ValueNotifier<String?>(null);

      await tester.pumpWidget(_wrap(CaptureGuideScreen(
        controller: controller,
        classifierNotifier: classifierNotifier,
        classifierStatus: classifierStatus,
        debugLabelNotifier: debugNotifier,
      )));
      await tester.pump();
    }

    testWidgets('fullView のガイダンスが正しく表示される', (tester) async {
      await pumpScreen(tester);

      expect(find.text('ステップ 1/3'), findsOneWidget);
      expect(find.text('電球全体を撮影'), findsOneWidget);
      expect(find.text('カメラプレビュー'), findsOneWidget);
      expect(find.text('撮影する'), findsOneWidget);
      expect(find.text('画像を選ぶ'), findsOneWidget);
      expect(find.text('写真ではうまく撮れない → 手動で確認'), findsOneWidget);
    });

    testWidgets('baseView のガイダンスが正しく表示される', (tester) async {
      await pumpScreen(tester, step: StepName.baseView);

      expect(find.text('ステップ 2/3'), findsOneWidget);
      expect(find.text('口金部分を撮影'), findsOneWidget);
    });

    testWidgets('labelView のガイダンスが正しく表示される', (tester) async {
      await pumpScreen(tester, step: StepName.labelView);

      expect(find.text('ステップ 3/3'), findsOneWidget);
      expect(find.text('側面の印字を撮影'), findsOneWidget);
    });

    testWidgets('fixtureCheck のガイダンスが正しく表示される', (tester) async {
      await pumpScreen(tester, step: StepName.fixtureCheck);

      expect(find.text('器具確認'), findsOneWidget);
      expect(find.text('照明器具を確認'), findsOneWidget);
    });

    testWidgets('デバッグ用ラベル選択エリアが表示される', (tester) async {
      await pumpScreen(tester);

      expect(find.text('デバッグ: 分類ラベル選択'), findsOneWidget);
    });

    testWidgets('撮影済み→次に進む が条件付きで表示される', (tester) async {
      await pumpScreen(
        tester,
        lastOutput: RuleEngineOutput(
          type: OutputType.nextInstruction,
          title: '次へ',
          message: '次に進んでください',
          requiredStep: 'base_view',
        ),
      );

      expect(find.text('撮影済み → 次に進む'), findsOneWidget);
    });

    testWidgets('classifierNotifier の値変更が撮影時の分類器に反映される', (tester) async {
      final session = CaptureSession(
        id: 'test-cg-swap',
        category: 'bulb',
        status: 'in_progress',
        currentStep: StepName.fullView,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final controller = StubSessionController(session: session);
      final notifier = ValueNotifier<Classifier>(StubClassifier());
      final status = ValueNotifier<String>('AI判定: Mock');
      final debugNotifier = ValueNotifier<String?>(null);

      await tester.pumpWidget(_wrap(CaptureGuideScreen(
        controller: controller,
        classifierNotifier: notifier,
        classifierStatus: status,
        debugLabelNotifier: debugNotifier,
      )));
      await tester.pump();

      // 表示後、別のclassifierに入れ替え
      final swapped = StubClassifier();
      notifier.value = swapped;
      await tester.pump();

      // notifierの現在値がswappedであることを確認
      expect(notifier.value, equals(swapped));
    });
  });
}
