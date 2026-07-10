// lib/core/models/rule_engine_output.dart
// ルールエンジンの出力
// 次の指示、手動確認要求、または購入結果のいずれか
// 関連: rule_engine.dart

enum OutputType {
  nextInstruction,
  manualCheck,
  purchaseResult;

  String get value => switch (this) {
    OutputType.nextInstruction => 'next_instruction',
    OutputType.manualCheck => 'manual_check',
    OutputType.purchaseResult => 'purchase_result',
  };

  static OutputType fromString(String s) => switch (s) {
    'next_instruction' => OutputType.nextInstruction,
    'manual_check' => OutputType.manualCheck,
    'purchase_result' => OutputType.purchaseResult,
    _ => OutputType.nextInstruction,
  };
}

class RuleEngineOutput {
  final OutputType type;
  final String title;
  final String message;
  final String? requiredStep;
  final List<String> warnings;

  RuleEngineOutput({
    required this.type,
    required this.title,
    required this.message,
    this.requiredStep,
    this.warnings = const [],
  });
}
