import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kore_no_kae_dore/features/home/home_screen.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: child);
}

void main() {
  group('HomeScreen', () {
    testWidgets('カテゴリカードが3つ表示される', (tester) async {
      await tester.pumpWidget(_wrap(HomeScreen(
        onStartBulb: () {},
        onHistory: () {},
      )));

      expect(find.text('電球'), findsOneWidget);
      expect(find.text('電池'), findsOneWidget);
      expect(find.text('フィルター'), findsOneWidget);
    });

    testWidgets('電池とフィルターに「準備中」バッジが表示される', (tester) async {
      await tester.pumpWidget(_wrap(HomeScreen(
        onStartBulb: () {},
        onHistory: () {},
      )));

      expect(find.text('準備中'), findsNWidgets(2));
    });

    testWidgets('電球をタップ → onStartBulb が呼ばれる', (tester) async {
      bool called = false;
      await tester.pumpWidget(_wrap(HomeScreen(
        onStartBulb: () => called = true,
        onHistory: () {},
      )));

      await tester.tap(find.text('電球'));
      await tester.pump();

      expect(called, isTrue);
    });

    testWidgets('電池をタップ → SnackBar が表示される', (tester) async {
      await tester.pumpWidget(_wrap(HomeScreen(
        onStartBulb: () {},
        onHistory: () {},
      )));

      await tester.tap(find.text('電池'));
      await tester.pump();

      expect(find.text('電池は準備中です'), findsOneWidget);
    });

    testWidgets('フィルターをタップ → SnackBar が表示される', (tester) async {
      await tester.pumpWidget(_wrap(HomeScreen(
        onStartBulb: () {},
        onHistory: () {},
      )));

      await tester.tap(find.text('フィルター'));
      await tester.pump();

      expect(find.text('フィルターは準備中です'), findsOneWidget);
    });

    testWidgets('履歴ボタンをタップ → onHistory が呼ばれる', (tester) async {
      bool called = false;
      await tester.pumpWidget(_wrap(HomeScreen(
        onStartBulb: () {},
        onHistory: () => called = true,
      )));

      await tester.tap(find.byIcon(Icons.history));
      await tester.pump();

      expect(called, isTrue);
    });

    testWidgets('onResume あり → 復元ダイアログが表示される', (tester) async {
      await tester.pumpWidget(_wrap(HomeScreen(
        onStartBulb: () {},
        onHistory: () {},
        onResume: () {},
      )));
      await tester.pump();

      expect(find.text('続きから始めますか？'), findsOneWidget);
      expect(find.text('新しく始める'), findsOneWidget);
      expect(find.text('続きから'), findsOneWidget);
    });

    testWidgets('「新しく始める」をタップ → ダイアログが閉じる', (tester) async {
      await tester.pumpWidget(_wrap(HomeScreen(
        onStartBulb: () {},
        onHistory: () {},
        onResume: () {},
      )));
      await tester.pump();

      await tester.tap(find.text('新しく始める'));
      await tester.pump();

      expect(find.text('続きから始めますか？'), findsNothing);
    });

    testWidgets('「続きから」をタップ → onResume が呼ばれる', (tester) async {
      bool called = false;
      await tester.pumpWidget(_wrap(HomeScreen(
        onStartBulb: () {},
        onHistory: () {},
        onResume: () => called = true,
      )));
      await tester.pump();

      await tester.tap(find.text('続きから'));
      await tester.pump();

      expect(called, isTrue);
    });

    testWidgets('onResume なし → 復元ダイアログは表示されない', (tester) async {
      await tester.pumpWidget(_wrap(HomeScreen(
        onStartBulb: () {},
        onHistory: () {},
      )));
      await tester.pump();

      expect(find.text('続きから始めますか？'), findsNothing);
    });

    testWidgets('後からonResumeが設定された場合に復元ダイアログが表示される', (tester) async {
      // 初期表示は onResume == null
      await tester.pumpWidget(_wrap(HomeScreen(
        onStartBulb: () {},
        onHistory: () {},
      )));
      await tester.pump();
      expect(find.text('続きから始めますか？'), findsNothing);

      // 後から onResume が設定される（_checkResumeSession完了を模擬）
      await tester.pumpWidget(_wrap(HomeScreen(
        onStartBulb: () {},
        onHistory: () {},
        onResume: () {},
        onStartFresh: () {},
      )));
      await tester.pump();

      expect(find.text('続きから始めますか？'), findsOneWidget);
    });

    testWidgets('復元ダイアログが二重表示されない', (tester) async {
      // 一度表示されたら
      await tester.pumpWidget(_wrap(HomeScreen(
        onStartBulb: () {},
        onHistory: () {},
        onResume: () {},
        onStartFresh: () {},
      )));
      await tester.pump();

      expect(find.text('続きから始めますか？'), findsOneWidget);

      // 再度同じonResumeで再buildしてもダイアログは1回だけ
      await tester.pumpWidget(_wrap(HomeScreen(
        onStartBulb: () {},
        onHistory: () {},
        onResume: () {},
        onStartFresh: () {},
      )));
      await tester.pump();

      expect(find.text('続きから始めますか？'), findsOneWidget);
    });
  });
}
