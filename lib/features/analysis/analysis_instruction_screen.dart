// lib/features/analysis/analysis_instruction_screen.dart
// 判定中/追加撮影指示画面
// 現在わかったこと、足りないこと、次に撮る角度を表示
// 関連: capture_guide_screen.dart, rule_engine.dart

import 'package:flutter/material.dart';
import '../../core/session/session_controller.dart';

class AnalysisInstructionScreen extends StatelessWidget {
  final SessionController controller;

  const AnalysisInstructionScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final output = controller.lastOutput;

    if (output == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('判定')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('判定結果')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // タイトル
            Text(
              output.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // メッセージ
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '指示',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      output.message,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 警告
            if (output.warnings.isNotEmpty)
              Card(
                color: Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final warning in output.warnings)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.warning_amber,
                                  size: 16, color: Colors.orange),
                              const SizedBox(width: 8),
                              Expanded(child: Text(warning, style: const TextStyle(fontSize: 13))),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            const Spacer(),

            // アクションボタン
            if (output.type == 'next_instruction')
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/capture'),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('撮影に進む', style: TextStyle(fontSize: 16)),
                ),
              ),

            if (output.type == 'manual_check')
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/manual_check'),
                  icon: const Icon(Icons.checklist),
                  label: const Text('手動確認に進む', style: TextStyle(fontSize: 16)),
                ),
              ),

            if (output.type == 'purchase_result')
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/result',
                    (route) => route.settings.name == '/home',
                  ),
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text('結果を見る', style: TextStyle(fontSize: 16)),
                ),
              ),

            const SizedBox(height: 12),

            // ホームに戻る
            TextButton(
              onPressed: () {
                controller.abandonSession();
                Navigator.pushNamedAndRemoveUntil(
                    context, '/home', (route) => false);
              },
              child: const Text('最初からやり直す'),
            ),
          ],
        ),
      ),
    );
  }
}
