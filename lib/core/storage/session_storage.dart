// lib/core/storage/session_storage.dart
// セッション情報のJSONファイル保存/読込
// Phase 1はJSONファイルベース。将来SQLiteに移行可能
// 関連: capture_session.dart

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/capture_session.dart';

class SessionStorage {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    final sessionsDir = Directory('${directory.path}/sessions');
    if (!await sessionsDir.exists()) {
      await sessionsDir.create(recursive: true);
    }
    return sessionsDir.path;
  }

  Future<void> saveSession(CaptureSession session) async {
    final path = await _localPath;
    final file = File('$path/${session.id}.json');
    await file.writeAsString(jsonEncode(session.toJson()));
  }

  Future<CaptureSession?> loadSession(String id) async {
    try {
      final path = await _localPath;
      final file = File('$path/$id.json');
      if (!await file.exists()) return null;
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return CaptureSession.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<List<CaptureSession>> listSessions() async {
    try {
      final path = await _localPath;
      final dir = Directory(path);
      if (!await dir.exists()) return [];
      final files = await dir.list().where((e) => e.path.endsWith('.json')).toList();
      final sessions = <CaptureSession>[];
      for (final file in files) {
        try {
          final json = jsonDecode(
            await File(file.path).readAsString(),
          ) as Map<String, dynamic>;
          sessions.add(CaptureSession.fromJson(json));
        } catch (_) {}
      }
      sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return sessions;
    } catch (_) {
      return [];
    }
  }

  Future<void> deleteSession(String id) async {
    try {
      final path = await _localPath;
      final file = File('$path/$id.json');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
