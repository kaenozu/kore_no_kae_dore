// lib/features/history/history_screen.dart
// 履歴画面：過去の購入結果を一覧表示
// 結果をタップすると詳細を再表示できる
// 関連: purchase_result_storage.dart, home_screen.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _results = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final resultsDir = Directory('${directory.path}/results');
      if (!await resultsDir.exists()) {
        setState(() {
          _results = [];
          _loading = false;
        });
        return;
      }

      final files = await resultsDir.list().where((e) => e.path.endsWith('.json')).toList();
      final results = <Map<String, dynamic>>[];
      for (final file in files) {
        try {
          final json = jsonDecode(
            await File(file.path).readAsString(),
          ) as Map<String, dynamic>;
          results.add(json);
        } catch (_) {}
      }
      results.sort((a, b) => (b['createdAt'] as String).compareTo(a['createdAt'] as String));

      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.year}/${dt.month.toString().padLeft(2, '0')}'
          '/${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('履歴')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
              ? const Center(
                  child: Text('履歴がありません', style: TextStyle(color: Colors.grey)))
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final result = _results[index];
                      final title = result['candidateTitle'] as String? ?? '';
                      final date =
                          _formatDate(result['createdAt'] as String? ?? '');
                      final confidence =
                          result['confidenceLabel'] as String? ?? '';
                      final keywords = (result['searchKeywords'] as List?)
                              ?.cast<String>() ??
                          [];
                      final checks = (result['checkBeforeBuy'] as List?)
                              ?.cast<String>() ??
                          [];
                      final summary =
                          result['shopStaffSummary'] as String? ?? '';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ExpansionTile(
                          title: Text(
                            title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text(
                            date,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              confidence,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.blue[700]),
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (keywords.isNotEmpty) ...[
                                    const Text('検索ワード',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: Colors.grey)),
                                    const SizedBox(height: 4),
                                    ...keywords.map(
                                      (kw) => Padding(
                                        padding: const EdgeInsets.only(
                                            bottom: 4),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(kw,
                                                  style:
                                                      const TextStyle(fontSize: 14)),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.copy,
                                                  size: 18),
                                              onPressed: () {
                                                Clipboard.setData(
                                                    ClipboardData(text: kw));
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content:
                                                          Text('コピーしました')),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const Divider(),
                                  ],
                                  if (checks.isNotEmpty) ...[
                                    const Text('買う前チェック',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: Colors.grey)),
                                    const SizedBox(height: 4),
                                    ...checks.map(
                                      (c) => Padding(
                                        padding: const EdgeInsets.only(
                                            bottom: 4),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text('・'),
                                            Expanded(child: Text(c)),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const Divider(),
                                  ],
                                  const Text('店員用要約',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Colors.grey)),
                                  const SizedBox(height: 4),
                                  Text(summary, style: const TextStyle(fontSize: 14)),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
