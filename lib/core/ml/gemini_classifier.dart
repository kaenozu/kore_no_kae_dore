// lib/core/ml/gemini_classifier.dart
// Google AI Studio（Gemini API）を使った画像分類
// 無料枠（レート制限あり）で動作。APIキーは --dart-define で注入
// フォールバックチェーンで複数モデルを試行する
// 関連: classifier.dart, app.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:uuid/uuid.dart';

import '../models/classification_result.dart';
import 'classifier.dart';

/// Google AI Gemini APIを使った画像分類器
///
/// APIキーは `--dart-define=GEMINI_API_KEY=xxx` で渡す。
/// 未設定の場合は [ClassifierInitException] を throw し、
/// 呼び出し元で MockClassifier にフォールバックする。
///
/// フォールバックチェーン（init時に順に試行）:
/// 1. gemini-3.1-pro-preview (最新)
/// 2. gemini-3-flash-preview (高速)
/// 3. gemini-2.5-flash-preview (安定版)
class GeminiClassifier extends Classifier with FixedLabelMixin {
  static const _candidates = [
    'gemini-3.1-pro-preview',
    'gemini-3-flash-preview',
    'gemini-2.5-flash-preview',
  ];

  GenerativeModel? _model;
  String? _activeModel;

  bool get isReady => _model != null;

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

    final imageBytes = await File(imagePath).readAsBytes();

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
        DataPart('image/jpeg', imageBytes),
      ]),
    ]);

    final text = resp.text;
    if (text == null || text.isEmpty) {
      return _buildResult(ImageLabel.unknownOther.value, 0.0);
    }

    return _parseResponse(text);
  }

  ClassificationResult _parseResponse(String raw) {
    try {
      final json = _extractJson(raw);
      final label = json['label'] as String? ?? ImageLabel.unknownOther.value;
      final score = (json['score'] as num?)?.toDouble() ?? 0.0;
      return _buildResult(label, score);
    } catch (e) {
      debugPrint('GeminiClassifier: failed to parse response ($e)');
      debugPrint('GeminiClassifier: raw response: $raw');
      return _buildResult(ImageLabel.unknownOther.value, 0.0);
    }
  }

  /// ```json ... ``` コードブロックや余分なテキストを除去してJSONを抽出
  Map<String, dynamic> _extractJson(String text) {
    final stripped = text.trim();
    final codeBlockMatch =
        RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(stripped);
    final jsonStr = codeBlockMatch?.group(1) ?? stripped;
    return jsonDecode(jsonStr) as Map<String, dynamic>;
  }

  ClassificationResult _buildResult(String label, double score) {
    final predictions = [
      Prediction(label: label, score: score),
      Prediction(label: ImageLabel.unknownOther.value, score: 1.0 - score),
    ];
    return ClassificationResult(
      id: const Uuid().v4(),
      imageId: const Uuid().v4(),
      modelVersion: 'gemini-${_activeModel ?? "unknown"}',
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
