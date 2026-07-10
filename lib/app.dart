// lib/app.dart
// アプリケーションのルートウィジェット
// 画面遷移とSessionControllerの管理を担当
// 起動時にGeminiClassifierを試行し、失敗時はMockClassifierにフォールバック
// 関連: 全画面

import 'package:flutter/material.dart';

import 'core/ml/classifier.dart';
import 'core/ml/gemini_classifier.dart';
import 'core/ml/mock_classifier.dart';
import 'core/session/session_controller.dart';
import 'features/capture/capture_guide_screen.dart';
import 'features/history/history_screen.dart';
import 'features/home/home_screen.dart';
import 'features/manual_check/manual_check_screen.dart';
import 'features/result/purchase_result_screen.dart';

class KoreNoKaeDoreApp extends StatelessWidget {
  const KoreNoKaeDoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'これの替えどれ？',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      initialRoute: '/home',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/home':
            return MaterialPageRoute(
              builder: (_) => const _HomeWithHistory(),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                body: Center(child: Text('不明なルート: ${settings.name}')),
              ),
            );
        }
      },
    );
  }
}

/// Home + History 用のラッパー（ルート直下でコントローラにアクセス）
class _HomeWithHistory extends StatefulWidget {
  const _HomeWithHistory();

  @override
  State<_HomeWithHistory> createState() => _HomeWithHistoryState();
}

class _HomeWithHistoryState extends State<_HomeWithHistory> {
  final _controller = SessionController();
  Classifier _classifier = MockClassifier();
  final _debugLabelNotifier = ValueNotifier<String?>(null);
  bool _hasResumeSession = false;

  @override
  void initState() {
    super.initState();
    _tryInitGemini();
    _checkResumeSession();
  }

  Future<void> _tryInitGemini() async {
    final gemini = GeminiClassifier();
    try {
      await gemini.init();
      _classifier = gemini;
    } catch (e) {
      debugPrint('Gemini unavailable, using MockClassifier: $e');
    }
  }

  Future<void> _checkResumeSession() async {
    final session = await _controller.storage.findLatestInProgress();
    if (session != null && mounted) {
      setState(() => _hasResumeSession = true);
    }
  }

  Future<void> _onResume() async {
    final session = await _controller.storage.findLatestInProgress();
    if (session == null) return;
    final evidence = await _controller.storage.loadEvidence(session.id);
    if (evidence == null) return;
    await _controller.loadSession(session, evidence);
    if (!mounted) return;
    setState(() => _hasResumeSession = false);
    Navigator.of(context).pushNamed('/capture');
  }

  Future<void> _onStartNew() async {
    await _controller.abandonSession();
    if (!mounted) return;
    setState(() => _hasResumeSession = false);
  }

  @override
  void dispose() {
    _debugLabelNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      initialRoute: '/home',
      // ignore: deprecated_member_use
      onPopPage: (route, result) {
        if (route.settings.name == '/home') return false;
        return route.didPop(result);
      },
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          settings: settings,
          builder: (context) {
            switch (settings.name) {
              case '/home':
                return HomeScreen(
                  onStartBulb: () async {
                    await _controller.startSession('bulb');
                    if (!context.mounted) return;
                    Navigator.of(context).pushNamed('/capture');
                  },
                  onHistory: () {
                    Navigator.of(context).pushNamed('/history');
                  },
                  onResume: _hasResumeSession ? _onResume : null,
                  onStartNew: _hasResumeSession ? _onStartNew : null,
                );
              case '/capture':
                return CaptureGuideScreen(
                  controller: _controller,
                  classifier: _classifier,
                  debugLabelNotifier: _debugLabelNotifier,
                );
              case '/manual_check':
                return ManualCheckScreen(controller: _controller);
              case '/result':
                return PurchaseResultScreen(controller: _controller);
              case '/history':
                return const HistoryScreen();
              default:
                return Scaffold(
                  body: Center(
                    child: Text('不明なルート: ${settings.name}'),
                  ),
                );
            }
          },
        );
      },
    );
  }
}
