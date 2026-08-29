// lib/core/ml/gemini_classifier.dart
// Remote Gemini classification is intentionally disabled in the mobile client.
// A client-side API key would be extractable from every distributed APK/IPA.

import '../models/classification_result.dart';
import 'classifier.dart';

/// Gemini model names retained as metadata for compatibility with existing tests/UI.
class GeminiModelNames {
  static const List<String> candidates = [
    'gemini-2.5-flash-preview',
    'gemini-3-flash-preview',
    'gemini-3.1-pro-preview',
  ];
  static const String unknown = 'unknown';
}

/// Placeholder for a future authenticated backend classifier.
///
/// This class deliberately contains no API-key lookup, SDK dependency, or
/// network client. Enabling Gemini requires a backend with authentication,
/// rate limiting, and server-side secret storage.
class GeminiClassifier extends Classifier with FixedLabelMixin {
  bool get isReady => false;
  String get activeModel => GeminiModelNames.unknown;

  Future<void> init() async {
    throw ClassifierInitException(
      'Remote Gemini classification is disabled in the client. '
      'Configure an authenticated backend before enabling it.',
    );
  }

  @override
  Future<ClassificationResult> classify(String imagePath) async {
    throw StateError('GeminiClassifier is disabled until a secure backend is configured.');
  }
}

class ClassifierInitException implements Exception {
  final String message;
  ClassifierInitException(this.message);

  @override
  String toString() => 'ClassifierInitException: $message';
}
