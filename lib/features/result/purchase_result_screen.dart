// lib/features/result/purchase_result_screen.dart
// 購入結果画面：候補名、検索ワード、買う前チェック、店員用要約、商品候補を表示
// 断定表現を使わないことに注意
// 関連: purchase_result.dart, home_screen.dart, product_candidate_provider.dart

import 'package:flutter/material.dart';
import '../../core/session/session_controller.dart';
import '../../core/models/match_level.dart';
import '../../core/models/product_candidate.dart';
import '../../core/models/product_search_query.dart';
import '../../core/services/product_candidate_provider.dart';
import '../../shared/widgets/copyable_text.dart';

class PurchaseResultScreen extends StatelessWidget {
  final SessionController controller;

  const PurchaseResultScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final result = controller.lastResult;

    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('結果')),
        body: const Center(child: Text('結果データがありません')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('購入候補'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 商品候補の信頼度レベル
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.verified_user_outlined, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.matchLevel.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            result.matchLevel.caution,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 注意文（常時表示）
            Card(
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'これは「候補」です。「これでOK」ではありません。'
                        '購入前に必ず現物やパッケージで各項目を確認してください。',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 候補名
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '買い替え候補',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      result.candidateTitle,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '信頼度: ${result.confidenceLabel}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 検索ワード
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '検索ワード',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...result.searchKeywords.map(
                      (keyword) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: CopyableText(text: keyword),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'このキーワードで通販サイトを検索してください。',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 買う前チェック
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '買う前に確認すること',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...result.checkBeforeBuy.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${entry.key + 1}. ',
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.warning_amber,
                              size: 14, color: Colors.red[700]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                               'この条件を目安に探してください。',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.red[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
             const SizedBox(height: 16),

             // 商品候補（デモ）
             Column(
               crossAxisAlignment: CrossAxisAlignment.stretch,
               children: [
                 const Text(
                   '商品候補',
                   style: TextStyle(
                     fontSize: 16,
                     fontWeight: FontWeight.bold,
                   ),
                 ),
                 const SizedBox(height: 4),
                 Text(
                   '商品候補には、将来的に広告リンクを含む場合があります。現在はデモ表示です。',
                   style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                 ),
                 const SizedBox(height: 12),
                 FutureBuilder<List<ProductCandidate>>(
                   future: MockProductCandidateProvider().search(
                     ProductSearchQuery(
                       keyword: result.candidateTitle,
                       category: 'bulb',
                       matchLevel: result.matchLevel,
                       conditions: const {},
                     ),
                   ),
                   builder: (context, snapshot) {
                     if (!snapshot.hasData) {
                       return const Center(
                         child: Padding(
                           padding: EdgeInsets.all(16),
                           child: CircularProgressIndicator(strokeWidth: 2),
                         ),
                       );
                     }

                     final candidates = snapshot.data!;

                     return Column(
                       children: [
                         ...candidates.map(
                           (c) => Card(
                             child: Padding(
                               padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Row(
                                     children: [
                                       Expanded(
                                         child: Text(
                                           c.title,
                                           style: const TextStyle(
                                             fontSize: 16,
                                             fontWeight: FontWeight.bold,
                                           ),
                                         ),
                                       ),
                                       if (c.price != null)
                                         Text(
                                           '¥${c.price!}',
                                           style: TextStyle(
                                             fontSize: 16,
                                             fontWeight: FontWeight.bold,
                                             color: Theme.of(context).colorScheme.primary,
                                           ),
                                         ),
                                     ],
                                   ),
                                   const SizedBox(height: 6),
                                   Container(
                                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                     decoration: BoxDecoration(
                                       color: Colors.blue[50],
                                       borderRadius: BorderRadius.circular(4),
                                     ),
                                     child: Text(
                                       c.matchLevel.label,
                                       style: TextStyle(
                                         fontSize: 12,
                                         color: Colors.blue[800],
                                         fontWeight: FontWeight.bold,
                                       ),
                                     ),
                                   ),
                                   const SizedBox(height: 4),
                                   Text(
                                     c.matchLevel.caution,
                                     style: TextStyle(
                                       fontSize: 12,
                                       color: Colors.blue[700],
                                     ),
                                   ),
                                   const SizedBox(height: 8),
                                   SizedBox(
                                     width: double.infinity,
                                     child: OutlinedButton.icon(
                                       onPressed: () {
                                         ScaffoldMessenger.of(context).showSnackBar(
                                           const SnackBar(
                                             content: Text('商品リンク連携は今後対応予定です'),
                                           ),
                                         );
                                       },
                                       icon: const Icon(Icons.open_in_new, size: 16),
                                       label: const Text('商品ページを見る（デモ）'),
                                     ),
                                   ),
                                 ],
                               ),
                             ),
                           ),
                         ),
                         const SizedBox(height: 12),
                       ],
                     );
                   },
                 ),
               ],
             ),
              const SizedBox(height: 24),

             // 店員に見せる要約
             Card(
               color: Colors.green[50],
               child: Padding(
                 padding: const EdgeInsets.all(16),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Row(
                       children: [
                         const Icon(Icons.store, color: Colors.green),
                         const SizedBox(width: 8),
                         const Text(
                           '店員さんに見せる',
                           style: TextStyle(
                             fontSize: 14,
                             fontWeight: FontWeight.bold,
                             color: Colors.green,
                           ),
                         ),
                       ],
                     ),
                     const SizedBox(height: 8),
                     Text(
                       result.shopStaffSummary,
                       style: const TextStyle(fontSize: 15),
                     ),
                     const SizedBox(height: 8),
                     CopyableText(
                       text: result.shopStaffSummary,
                       iconSize: 16,
                     ),
                     const SizedBox(height: 4),
                     Text(
                       'この文面をコピーして店員さんに見せてください。',
                       style: TextStyle(
                         fontSize: 12,
                         color: Colors.grey[500],
                       ),
                     ),
                   ],
                 ),
               ),
             ),
             const SizedBox(height: 24),

             // ホームに戻る
             SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  controller.reset();
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/home', (route) => false);
                },
                icon: const Icon(Icons.home),
                label: const Text('ホームに戻る', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
