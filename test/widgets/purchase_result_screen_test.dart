import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kore_no_kae_dore/core/models/purchase_result.dart';
import 'package:kore_no_kae_dore/features/result/purchase_result_screen.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../helpers/mock_session_controller.dart';

class FakePathProvider extends PathProviderPlatform {
  @override
  Future<String> getApplicationDocumentsPath() async {
    return Directory.systemTemp.path;
  }
}

Widget _wrap(Widget child) {
  return MaterialApp(home: child);
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    PathProviderPlatform.instance = FakePathProvider();
  });

  group('PurchaseResultScreen', () {
    testWidgets('結果がない →「結果データがありません」を表示', (tester) async {
      final controller = StubSessionController(lastResult: null);
      await tester.pumpWidget(_wrap(PurchaseResultScreen(controller: controller)));

      expect(find.text('結果データがありません'), findsOneWidget);
    });

    testWidgets('結果がある → 候補名・検索ワード・要約が表示される', (tester) async {
      final result = PurchaseResult(
        id: 'r1',
        sessionId: 's1',
        candidateTitle: 'E26 LED電球 60形相当 昼光色',
        confidenceLabel: '候補',
        searchKeywords: ['E26 LED電球', '60W相当', '昼光色'],
        checkBeforeBuy: ['口金を確認', '明るさを確認'],
        shopStaffSummary: 'E26口金のLED電球を探しています。',
        createdAt: DateTime.now(),
      );
      final controller = StubSessionController(lastResult: result);

      await tester.pumpWidget(_wrap(PurchaseResultScreen(controller: controller)));

      expect(find.text('E26 LED電球 60形相当 昼光色'), findsOneWidget);
      expect(find.text('信頼度: 候補'), findsOneWidget);
      expect(find.text('E26 LED電球'), findsOneWidget);
      expect(find.text('口金を確認'), findsOneWidget);
      expect(find.text('E26口金のLED電球を探しています。'), findsAtLeast(1));
    });

    testWidgets('ホームに戻るボタンが表示される', (tester) async {
      final result = PurchaseResult(
        id: 'r2',
        sessionId: 's2',
        candidateTitle: 'E26 LED電球',
        confidenceLabel: '候補',
        searchKeywords: [],
        checkBeforeBuy: [],
        shopStaffSummary: '',
        createdAt: DateTime.now(),
      );
      final controller = StubSessionController(lastResult: result);

      await tester.pumpWidget(_wrap(PurchaseResultScreen(controller: controller)));

      expect(find.text('ホームに戻る'), findsOneWidget);
    });
  });
}
