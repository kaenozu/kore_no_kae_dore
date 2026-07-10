// lib/core/storage/session_storage.dart
// セッション情報のJSONファイル保存/読込
// Phase 1はJSONファイルベース。将来SQLiteに移行可能
// 関連: capture_session.dart, evidence_state.dart

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/capture_session.dart';
import '../models/evidence_state.dart';

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

  Future<void> saveEvidence(EvidenceState evidence) async {
    final path = await _localPath;
    final file = File('$path/${evidence.sessionId}_evidence.json');
    await file.writeAsString(jsonEncode(evidence.toJson()));
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

  Future<EvidenceState?> loadEvidence(String sessionId) async {
    try {
      final path = await _localPath;
      final file = File('$path/${sessionId}_evidence.json');
      if (!await file.exists()) return null;
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return EvidenceState.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<List<CaptureSession>> listSessions() async {
    try {
      final path = await _localPath;
      final dir = Directory(path);
      if (!await dir.exists()) return [];
      final files = await dir.list().where((e) => e.path.endsWith('.json') && !e.path.endsWith('_evidence.json')).toList();
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

  /// 最新の進行中セッションを取得する（なければnull）
  Future<CaptureSession?> findLatestInProgress() async {
    final sessions = await listSessions();
    try {
      return sessions.firstWhere((s) => s.status == 'in_progress');
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteSession(String id) async {
    try {
      final path = await _localPath;
      final sessionFile = File('$path/$id.json');
      if (await sessionFile.exists()) {
        await sessionFile.delete();
      }
      final evidenceFile = File('$path/${id}_evidence.json');
      if (await evidenceFile.exists()) {
        await evidenceFile.delete();
      }
    } catch (_) {}
  }
}
