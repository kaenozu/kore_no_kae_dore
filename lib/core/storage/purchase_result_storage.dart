// lib/core/storage/purchase_result_storage.dart
// 購入結果のJSONファイル保存/読込
// 履歴一覧表示に使う
// 関連: purchase_result.dart, history_screen.dart

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/purchase_result.dart';

class PurchaseResultStorage {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    final resultsDir = Directory('${directory.path}/results');
    if (!await resultsDir.exists()) {
      await resultsDir.create(recursive: true);
    }
    return resultsDir.path;
  }

  Future<void> saveResult(PurchaseResult result) async {
    final path = await _localPath;
    final file = File('$path/${result.id}.json');
    await file.writeAsString(jsonEncode(result.toJson()));
  }

  Future<PurchaseResult?> loadResult(String id) async {
    try {
      final path = await _localPath;
      final file = File('$path/$id.json');
      if (!await file.exists()) return null;
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return PurchaseResult.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<List<PurchaseResult>> listResults() async {
    try {
      final path = await _localPath;
      final dir = Directory(path);
      if (!await dir.exists()) return [];
      final files = await dir.list().where((e) => e.path.endsWith('.json')).toList();
      final results = <PurchaseResult>[];
      for (final file in files) {
        try {
          final json = jsonDecode(
            await File(file.path).readAsString(),
          ) as Map<String, dynamic>;
          results.add(PurchaseResult.fromJson(json));
        } catch (_) {}
      }
      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return results;
    } catch (_) {
      return [];
    }
  }
}
