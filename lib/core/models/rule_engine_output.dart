// lib/core/models/rule_engine_output.dart
// ルールエンジンの出力
// 次の指示、手動確認要求、または購入結果のいずれか
// 関連: rule_engine.dart, analysis_instruction_screen.dart

class RuleEngineOutput {
  final String type; // "next_instruction" | "manual_check" | "purchase_result"
  final String title;
  final String message;
  final String? requiredStep; // 次に撮るべきステップ
  final List<String> warnings;

  RuleEngineOutput({
    required this.type,
    required this.title,
    required this.message,
    this.requiredStep,
    this.warnings = const [],
  });
}
