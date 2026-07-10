import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kore_no_kae_dore/features/history/history_screen.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: child);
}

void main() {
  group('HistoryScreen', () {
    testWidgets('ローディング中 → CircularProgressIndicator を表示', (tester) async {
      await tester.pumpWidget(_wrap(const HistoryScreen()));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
