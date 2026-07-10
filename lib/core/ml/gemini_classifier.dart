// lib/core/ml/gemini_classifier.dart
// Google AI Studio（Gemini API）を使った画像分類
// 注意: 現在の google_generative_ai SDK は暫定。将来は公式推奨SDK/Proxy構成へ移行
// APIキーは --dart-define で注入。APK/IPAにキーが埋め込まれるため本番公開時はProxy必須
// フォールバックチェーンで複数モデルを試行する
// 関連: classifier.dart, app.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:uuid/uuid.dart';
import 'package:mime/mime.dart' as mime_pkg;

import '../models/classification_result.dart';
import 'classifier.dart';

/// Gemini API利用可能モデル名の定数リスト
/// 安定モデルを優先し、previewモデルは最後に試行
class GeminiModelNames {
  static const List<String> candidates = [
    'gemini-2.5-flash-preview', // 安定版を優先
    'gemini-3-flash-preview',   // 高速
    'gemini-3.1-pro-preview',   // 最新
  ];
  static const String unknown = 'unknown';
}

/// Google AI Gemini APIを使った画像分類器
///
/// APIキーは `--dart-define=GEMINI_API_KEY=xxx` でビルド時に注入する。
/// 注意: キーはAPK/IPAに埋め込まれる（本番はApp Check/Proxy必須）。
/// 未設定の場合は [ClassifierInitException] を throw し、
/// 呼び出し元で MockClassifier にフォールバックする。
///
/// フォールバックチェーン（init時に順に試行）:
/// {@macro GeminiModelNames.candidates}
class GeminiClassifier extends Classifier with FixedLabelMixin {
  static List<String> get _candidates {
    // --dart-define=GEMINI_MODEL=xxx で優先モデル指定可能
    final overridden = const String.fromEnvironment('GEMINI_MODEL');
    if (overridden.isNotEmpty) {
      return [overridden, ...GeminiModelNames.candidates];
    }
    return GeminiModelNames.candidates;
  }

  GenerativeModel? _model;
  String? _activeModel;

  bool get isReady => _model != null;
  String get activeModel => _activeModel ?? GeminiModelNames.unknown;

  /// 疎通確認を兼ねて利用可能なモデルを探す。
  /// 全て失敗した場合は [ClassifierInitException] を throw。
  Future<void> init() async {
    final apiKey = const String.fromEnvironment('GEMINI_API_KEY');
    if (apiKey.isEmpty) {
      throw ClassifierInitException(
        'GEMINI_API_KEY not set. '
        'Pass --dart-define=GEMINI_API_KEY=xxx to flutter run.',
      );
    }

    for (final name in _candidates) {
      try {
        final m = GenerativeModel(
          model: name,
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
          ),
        );
        // 軽いリクエストで疎通確認
        await m.generateContent([Content.text('respond with: ok')]);
        _model = m;
        _activeModel = name;
        debugPrint('GeminiClassifier: using model $name');
        return;
      } catch (e) {
        debugPrint('GeminiClassifier: model $name unavailable ($e)');
        continue;
      }
    }
    throw ClassifierInitException('All Gemini models unavailable');
  }

  @override
  Future<ClassificationResult> classify(String imagePath) async {
    if (_model == null) {
      throw StateError('GeminiClassifier not initialized. Call init() first.');
    }

    // FixedLabelMixin: デバッグ用に固定ラベルを指定可能
    if (fixedLabel != null) {
      return _buildResult(fixedLabel!, fixedScore);
    }

    final file = File(imagePath);
    if (!await file.exists()) {
      return _buildResult(ImageLabel.unknownOther.value, 0.0);
    }
    final imageBytes = await file.readAsBytes();
    final mimeType = _detectMime(imagePath);

    final prompt = '''
あなたは電球の写真を分析するアシスタントです。
以下の9クラスから、この写真がどれに該当するか判定してください。

- bulb_full_view: 電球全体が写っている
- bulb_base_view: 口金部分が写っている
- bulb_label_side_view: 電球のラベル/型番部分が写っている
- fixture_socket_view: 照明器具のソケット部分が写っている
- bulb_package_view: 電球のパッケージが写っている
- unknown_too_dark: 暗すぎて判別できない
- unknown_blurry: ぼやけていて判別できない
- unknown_too_far: 遠すぎて判別できない
- unknown_other: その他（電球と関係ない）

JSON形式で回答してください:
{
  "label": "クラス名",
  "score": 0.0〜1.0の信頼度,
  "reasoning": "判定理由（日本語）"
}
''';

    final resp = await _model!.generateContent([
      Content.multi([
        TextPart(prompt),
        DataPart(mimeType, imageBytes),
      ]),
    ]).timeout(const Duration(seconds: 30));

    final text = resp.text;
    if (text == null || text.isEmpty) {
      return _buildResult(ImageLabel.unknownOther.value, 0.0);
    }

    return _parseResponse(text);
  }

  /// ファイルパスからMIMEタイプを推定する
  String _detectMime(String imagePath) {
    final guessed = mime_pkg.lookupMimeType(imagePath);
    return guessed ?? 'image/jpeg';
  }

  /// Gemini応答からJSONを安全にパースする
  ClassificationResult _parseResponse(String raw) {
    try {
      final json = _extractJson(raw);
      final rawLabel = json['label'] as String? ?? ImageLabel.unknownOther.value;
      // ImageLabel.fromStringで正規化（未知ラベルはunknownOtherに落ちる）
      final label = ImageLabel.fromString(rawLabel);
      final rawScore = (json['score'] as num?)?.toDouble() ?? 0.0;
      final score = rawScore.clamp(0.0, 1.0);
      return _buildResult(label.value, score);
    } catch (e) {
      debugPrint('GeminiClassifier: failed to parse response ($e)');
      // raw responseはdebugのみ、本番では出さない
      return _buildResult(ImageLabel.unknownOther.value, 0.0);
    }
  }

  /// ```json ... ``` コードブロックや余分なテキストを除去してJSONを抽出。
  /// コードブロックがあればその中身を、なければ最初の { から最後の } までを抽出する。
  Map<String, dynamic> _extractJson(String text) {
    final stripped = text.trim();
    // まずコードブロックを探す
    final codeBlockMatch =
        RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(stripped);
    if (codeBlockMatch != null) {
      return jsonDecode(codeBlockMatch.group(1)!.trim()) as Map<String, dynamic>;
    }
    // コードブロックがなければ最初の { から最後の } までを抽出
    final firstBrace = stripped.indexOf('{');
    final lastBrace = stripped.lastIndexOf('}');
    if (firstBrace != -1 && lastBrace > firstBrace) {
      return jsonDecode(stripped.substring(firstBrace, lastBrace + 1)) as Map<String, dynamic>;
    }
    // どちらも失敗 → そのままデコード（最後の手段、エラー時はcatchで処理）
    return jsonDecode(stripped) as Map<String, dynamic>;
  }

  ClassificationResult _buildResult(String label, double score) {
    final predictions = [
      Prediction(label: label, score: score),
      Prediction(label: ImageLabel.unknownOther.value, score: 1.0 - score),
    ];
    return ClassificationResult(
      id: const Uuid().v4(),
      imageId: const Uuid().v4(),
      modelVersion: _activeModel ?? GeminiModelNames.unknown,
      predictions: predictions,
      createdAt: DateTime.now(),
    );
  }
}

/// Geminiモデル初期化の失敗を表す例外
class ClassifierInitException implements Exception {
  final String message;
  ClassifierInitException(this.message);
  @override
  String toString() => 'ClassifierInitException: $message';
}
