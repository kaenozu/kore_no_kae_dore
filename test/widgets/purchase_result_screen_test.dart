import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kore_no_kae_dore/core/models/match_level.dart';
import 'package:kore_no_kae_dore/core/models/product_candidate.dart';
import 'package:kore_no_kae_dore/core/models/product_search_query.dart';
import 'package:kore_no_kae_dore/core/models/purchase_result.dart';
import 'package:kore_no_kae_dore/core/services/product_candidate_provider.dart';
import 'package:kore_no_kae_dore/features/result/purchase_result_screen.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../helpers/mock_session_controller.dart';

class FakePathProvider extends PathProviderPlatform {
  @override
  Future<String> getApplicationDocumentsPath() async {
    return Directory.systemTemp.path;
  }
}

class FakeProductCandidateProvider implements ProductCandidateProvider {
  const FakeProductCandidateProvider();

  @override
  Future<List<ProductCandidate>> search(ProductSearchQuery query) async {
    return [
      ProductCandidate(
        title: 'Fake LED電球',
        price: 1000,
        imageUrl: null,
        shopName: 'FakeShop',
        reviewAverage: 4.0,
        url: 'https://example.com/fake',
        isAffiliate: false,
        matchLevel: MatchLevel.compatibleSpec,
        matchedConditions: const ['baseSize'],
        cautions: [MatchLevel.compatibleSpec.caution],
      ),
    ];
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
        matchLevel: MatchLevel.compatibleSpec,
      );
      final controller = StubSessionController(lastResult: result);

      await tester.pumpWidget(_wrap(PurchaseResultScreen(controller: controller)));

      expect(find.text('E26 LED電球 60形相当 昼光色'), findsOneWidget);
      expect(find.text('信頼度: 候補'), findsOneWidget);
      expect(find.text('E26 LED電球'), findsOneWidget);
      expect(find.text('口金を確認'), findsOneWidget);
      expect(find.text('E26口金のLED電球を探しています。'), findsAtLeast(1));
      expect(find.text('条件一致候補'), findsOneWidget);
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
        matchLevel: MatchLevel.compatibleSpec,
      );
      final controller = StubSessionController(lastResult: result);

      await tester.pumpWidget(_wrap(PurchaseResultScreen(controller: controller)));

      expect(find.text('ホームに戻る'), findsOneWidget);
    });

    group('product candidates', () {
      testWidgets('開示文が表示される', (tester) async {
        final result = PurchaseResult(
          id: 'r3',
          sessionId: 's3',
          candidateTitle: 'E26 LED電球',
          confidenceLabel: '候補',
          searchKeywords: const [],
          checkBeforeBuy: const [],
          shopStaffSummary: '',
          createdAt: DateTime.now(),
          matchLevel: MatchLevel.compatibleSpec,
        );
        final controller = StubSessionController(lastResult: result);

        await tester.pumpWidget(_wrap(
          PurchaseResultScreen(
            controller: controller,
            productProvider: const FakeProductCandidateProvider(),
          ),
        ));
        await tester.pumpAndSettle();

        expect(
          find.text('商品候補には、将来的に広告リンクを含む場合があります。現在はデモ表示です。'),
          findsOneWidget,
        );
      });

      testWidgets('matchLevel.label / caution が表示される', (tester) async {
        final result = PurchaseResult(
          id: 'r4',
          sessionId: 's4',
          candidateTitle: 'E26 LED電球',
          confidenceLabel: '候補',
          searchKeywords: const [],
          checkBeforeBuy: const [],
          shopStaffSummary: '',
          createdAt: DateTime.now(),
          matchLevel: MatchLevel.manualCandidate,
        );
        final controller = StubSessionController(lastResult: result);

        await tester.pumpWidget(_wrap(
          PurchaseResultScreen(
            controller: controller,
            productProvider: const FakeProductCandidateProvider(),
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('手動入力候補'), findsOneWidget);
        expect(
          find.text('手動入力に基づく候補です。入力内容と商品ページを照合してください。'),
          findsOneWidget,
        );
      });

      testWidgets('「商品ページを見る（デモ）」で SnackBar が出る', (tester) async {
        final result = PurchaseResult(
          id: 'r5',
          sessionId: 's5',
          candidateTitle: 'E26 LED電球',
          confidenceLabel: '候補',
          searchKeywords: const [],
          checkBeforeBuy: const [],
          shopStaffSummary: '',
          createdAt: DateTime.now(),
          matchLevel: MatchLevel.compatibleSpec,
        );
        final controller = StubSessionController(lastResult: result);

        await tester.binding.setSurfaceSize(const Size(800, 1200));
        await tester.pumpWidget(_wrap(
          PurchaseResultScreen(
            controller: controller,
            productProvider: const FakeProductCandidateProvider(),
          ),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('商品ページを見る（デモ）'), warnIfMissed: false);
        await tester.pump();

        expect(find.text('商品リンク連携は今後対応予定です'), findsOneWidget);
        addTearDown(() async {
          await tester.binding.setSurfaceSize(null);
        });
      });
    });
  });
}
