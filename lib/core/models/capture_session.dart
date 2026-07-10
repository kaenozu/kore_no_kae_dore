// lib/core/models/capture_session.dart
// 撮影セッションの状態を保持する
// 1セッション = 1回の「これの替えどれ？」フロー全体
// 関連: evidence_state.dart, purchase_result.dart

enum StepName {
  fullView,
  baseView,
  labelView,
  fixtureCheck,
  manualCheck,
  result;

  String get value => switch (this) {
    StepName.fullView => 'full_view',
    StepName.baseView => 'base_view',
    StepName.labelView => 'label_view',
    StepName.fixtureCheck => 'fixture_check',
    StepName.manualCheck => 'manual_check',
    StepName.result => 'result',
  };

  static StepName fromString(String s) => switch (s) {
    'full_view' => StepName.fullView,
    'base_view' => StepName.baseView,
    'label_view' => StepName.labelView,
    'fixture_check' => StepName.fixtureCheck,
    'manual_check' => StepName.manualCheck,
    'result' => StepName.result,
    _ => StepName.fullView,
  };
}

class CaptureSession {
  final String id;
  final String category;
  String status;
  StepName currentStep;
  final DateTime createdAt;
  DateTime updatedAt;
  String? resultId;
  int failedAttempts;

  CaptureSession({
    required this.id,
    required this.category,
    required this.status,
    required this.currentStep,
    required this.createdAt,
    required this.updatedAt,
    this.resultId,
    this.failedAttempts = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'status': status,
        'currentStep': currentStep.value,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'resultId': resultId,
        'failedAttempts': failedAttempts,
      };

  factory CaptureSession.fromJson(Map<String, dynamic> json) => CaptureSession(
        id: json['id'] as String,
        category: json['category'] as String,
        status: json['status'] as String,
        currentStep: StepName.fromString(json['currentStep'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        resultId: json['resultId'] as String?,
        failedAttempts: json['failedAttempts'] as int? ?? 0,
      );
}
