// lib/features/home/home_screen.dart
// ホーム画面：カテゴリ選択と履歴リンクを表示
// 進行中セッションの復元ダイアログ表示機能付き
// MVPでは電球のみ本実装、電池/フィルターはβ表記
// 関連: capture_guide_screen.dart, history_screen.dart

import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onStartBulb;
  final VoidCallback onHistory;
  final VoidCallback? onResume;
  final VoidCallback? onStartFresh;

  const HomeScreen({
    super.key,
    required this.onStartBulb,
    required this.onHistory,
    this.onResume,
    this.onStartFresh,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _resumeDialogShown = false;

  @override
  void initState() {
    super.initState();
    // initState時点で既にonResumeがある場合（_checkResumeSessionが高速完了した場合）
    if (widget.onResume != null && !_resumeDialogShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showResumeDialog());
    }
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.onResume == null && widget.onResume != null && !_resumeDialogShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showResumeDialog());
    }
  }

  void _showResumeDialog() {
    _resumeDialogShown = true;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('続きから始めますか？'),
        content: const Text('進行中のセッションがあります。前回の続きから始めますか？'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // 既存進行中セッションを破棄して新規開始
              widget.onStartFresh?.call();
            },
            child: const Text('新しく始める'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onResume?.call();
            },
            child: const Text('続きから'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('これの替えどれ？'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: widget.onHistory,
            tooltip: '履歴',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '何を交換したいですか？',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '写真を撮って、買い間違いを防ぎましょう',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            _CategoryCard(
              icon: Icons.lightbulb_outline,
              title: '電球',
              subtitle: 'LED電球・白熱電球の交換',
              isBeta: false,
              onTap: widget.onStartBulb,
            ),
            const SizedBox(height: 12),
            _CategoryCard(
              icon: Icons.battery_unknown,
              title: '電池',
              subtitle: '単1〜単4、ボタン電池など',
              isBeta: true,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('電池は準備中です')),
                );
              },
            ),
            const SizedBox(height: 12),
            _CategoryCard(
              icon: Icons.air,
              title: 'フィルター',
              subtitle: '空気清浄機・掃除機など',
              isBeta: true,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('フィルターは準備中です')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isBeta;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isBeta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isBeta) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '準備中',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
