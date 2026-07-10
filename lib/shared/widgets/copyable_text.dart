// lib/shared/widgets/copyable_text.dart
// コピー可能なテキスト行（コピーボタン付き）
// 購入結果画面と履歴画面で重複していたロジックを抽出
// 関連: purchase_result_screen.dart, history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CopyableText extends StatelessWidget {
  final String text;
  final double iconSize;

  const CopyableText({
    super.key,
    required this.text,
    this.iconSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(text, style: const TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(Icons.copy, size: iconSize),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: text));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('コピーしました')),
            );
          },
        ),
      ],
    );
  }
}
