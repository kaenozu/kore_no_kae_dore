// lib/features/conversation/models/conversation_turn.dart
// 会話の1ターンを表現するモデル
// コンシェルジュの確認プロンプトとユーザーの応答を保持
// 関連: fixed_prompt_provider.dart, conversation_orchestrator.dart

enum ConversationRole { user, agent, system }

enum ConversationTurnType {
  text,
  photoRequest,
  choice,
  confirmation,
  warning,
  transition,
}

enum PromptActionType {
  takePhoto,
  pickImage,
  selectChoice,
  skip,
  continueAction,
}

class PromptAction {
  final String id;
  final PromptActionType type;
  final String label;
  final String? value;
  final String? fieldKey;

  const PromptAction({
    required this.id,
    required this.type,
    required this.label,
    this.value,
    this.fieldKey,
  });
}

class ConversationTurn {
  final String id;
  final ConversationRole role;
  final ConversationTurnType type;
  final String message;
  final String? purpose;
  final String? reason;
  final List<PromptAction> actions;
  final DateTime createdAt;

  const ConversationTurn({
    required this.id,
    required this.role,
    required this.type,
    required this.message,
    this.purpose,
    this.reason,
    this.actions = const [],
    required this.createdAt,
  });
}
