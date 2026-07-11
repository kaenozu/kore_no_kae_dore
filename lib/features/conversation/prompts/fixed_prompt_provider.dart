// lib/features/conversation/prompts/fixed_prompt_provider.dart
// 会話の状態から次のプロンプトを生成する
// LLMを使わず、EvidenceStateとRuleEngine出力に基づいて定型プロンプトを返す
// 関連: conversation_orchestrator.dart, evidence_state.dart, rule_engine.dart

import 'package:kore_no_kae_dore/core/models/evidence_state.dart';

import '../models/conversation_turn.dart';

enum ConversationStep {
  introduction,
  intentSelection,
  waitingForPhoto,
  waitingForManualCheck,
  readyForResult,
  completed,
}

class FixedPromptProvider {
  int _counter = 0;

  String _nextId() {
    _counter++;
    return 'prompt_$_counter';
  }

  ConversationTurn introduction() {
    return ConversationTurn(
      id: _nextId(),
      role: ConversationRole.agent,
      type: ConversationTurnType.text,
      message:
          '電球の買い替えに特化した確認サポートです。'
          '写真や回答をもとに必要な条件を整理しますが、'
          '商品が完全に同じであることは保証しません。',
      purpose: 'ようこそ',
      createdAt: DateTime.now(),
      actions: [
        PromptAction(
          id: _nextId(),
          type: PromptActionType.continueAction,
          label: '始める',
        ),
      ],
    );
  }

  ConversationTurn intentSelection() {
    return ConversationTurn(
      id: _nextId(),
      role: ConversationRole.agent,
      type: ConversationTurnType.choice,
      message: 'どのような買い替えをしたいですか？',
      purpose: '目的の選択',
      createdAt: DateTime.now(),
      actions: [
        PromptAction(
          id: _nextId(),
          type: PromptActionType.selectChoice,
          label: '同じ電球を探したい',
          value: 'find_same',
        ),
        PromptAction(
          id: _nextId(),
          type: PromptActionType.selectChoice,
          label: '条件だけ確認したい',
          value: 'check_spec',
        ),
      ],
    );
  }

  ConversationTurn photoRequest({
    required String purpose,
    required String message,
    required String reason,
  }) {
    return ConversationTurn(
      id: _nextId(),
      role: ConversationRole.agent,
      type: ConversationTurnType.photoRequest,
      message: message,
      purpose: purpose,
      reason: reason,
      createdAt: DateTime.now(),
      actions: [
        PromptAction(
          id: _nextId(),
          type: PromptActionType.takePhoto,
          label: '写真を撮る',
        ),
        PromptAction(
          id: _nextId(),
          type: PromptActionType.pickImage,
          label: '画像を選ぶ',
        ),
        PromptAction(
          id: _nextId(),
          type: PromptActionType.skip,
          label: '写真を使わず条件確認へ',
        ),
      ],
    );
  }

  ConversationTurn manualCheck(String field, List<String> options) {
    final (purpose, message, reason) = _manualCheckInfo(field);
    return ConversationTurn(
      id: _nextId(),
      role: ConversationRole.agent,
      type: ConversationTurnType.choice,
      message: message,
      purpose: purpose,
      reason: reason,
      createdAt: DateTime.now(),
      actions: [
        ...options.map(
          (opt) => PromptAction(
            id: _nextId(),
            type: PromptActionType.selectChoice,
            label: opt,
            value: opt,
          ),
        ),
        PromptAction(
          id: _nextId(),
          type: PromptActionType.selectChoice,
          label: '分からない',
          value: 'unknown',
        ),
      ],
    );
  }

  ConversationTurn readyForResult() {
    return ConversationTurn(
      id: _nextId(),
      role: ConversationRole.agent,
      type: ConversationTurnType.transition,
      message: '買い替え条件を整理できました。',
      purpose: '完了',
      createdAt: DateTime.now(),
      actions: [
        PromptAction(
          id: _nextId(),
          type: PromptActionType.continueAction,
          label: '購入候補を見る',
          value: 'show_result',
        ),
      ],
    );
  }

  ConversationTurn userMessage(String text) {
    return ConversationTurn(
      id: _nextId(),
      role: ConversationRole.user,
      type: ConversationTurnType.text,
      message: text,
      createdAt: DateTime.now(),
    );
  }

  ConversationTurn systemPhotoReceived() {
    return ConversationTurn(
      id: _nextId(),
      role: ConversationRole.system,
      type: ConversationTurnType.text,
      message: '写真を受信しました。確認中です...',
      createdAt: DateTime.now(),
    );
  }

  (String, String, String) _manualCheckInfo(String field) {
    return switch (field) {
      'baseSize' => (
        '口金サイズの確認',
        '電球の口金（金属部分）のサイズを教えてください。',
        'E26（一般的なサイズ）とE17（小型）では商品が異なります。'
      ),
      'colorTone' => (
        '光の色の確認',
        '普段使っていた光の色を選んでください。',
        '色が違うと部屋の印象が変わります。'
      ),
      'brightness' => (
        '明るさの確認',
        '希望する明るさを選んでください。',
        '明るさはワット数相当（40形/60形/100形）で選びます。'
      ),
      'sealedFixture' => (
        '照明器具の確認',
        'この電球を使う器具は密閉型ですか？',
        '密閉器具に対応していない電球を使うと故障の原因になります。'
      ),
      'dimmer' => (
        '調光器の確認',
        'この電球には調光スイッチが付いていますか？',
        '調光器対応の電球が必要かどうかを確認するためです。'
      ),
      _ => (
        '確認',
        '以下の項目を教えてください。',
        ''
      ),
    };
  }

  ConversationTurn knownConditions(EvidenceState? evidence) {
    if (evidence == null) {
      return ConversationTurn(
        id: _nextId(),
        role: ConversationRole.system,
        type: ConversationTurnType.text,
        message: 'まだ情報がありません。',
        createdAt: DateTime.now(),
      );
    }
    final checks = evidence.manualChecks;
    final lines = <String>[
      '口金サイズ: ${_fieldLabel('baseSize', checks.baseSize)}',
      '光の色: ${_fieldLabel('colorTone', checks.colorTone)}',
      '明るさ: ${_fieldLabel('brightness', checks.brightness)}',
      '密閉器具: ${_fieldLabel('sealedFixture', checks.sealedFixture)}',
      '調光器: ${_fieldLabel('dimmer', checks.dimmer)}',
    ];
    return ConversationTurn(
      id: _nextId(),
      role: ConversationRole.system,
      type: ConversationTurnType.text,
      message: lines.join('\n'),
      createdAt: DateTime.now(),
    );
  }

  String _fieldLabel(String field, String value) {
    if (value == 'unknown') return '未確認';
    return switch (field) {
      'baseSize' => switch (value) {
        'e26_candidate' || 'user_selected_e26' => 'E26候補',
        'e17_candidate' || 'user_selected_e17' => 'E17候補',
        _ => value,
      },
      'colorTone' => switch (value) {
        'bulb_color' => '電球色',
        'neutral_white' => '昼白色',
        'daylight' => '昼光色',
        _ => value,
      },
      'brightness' => '$value形相当',
      'sealedFixture' => switch (value) {
        'yes' => '密閉対応必要',
        'no' => '密閉不要',
        _ => value,
      },
      'dimmer' => switch (value) {
        'yes' => '調光対応必要',
        'no' => '調光不要',
        _ => value,
      },
      _ => value,
    };
  }

  /// 手動確認が必要なフィールドを順に返す
  static List<String> get manualCheckOrder => [
    'baseSize',
    'colorTone',
    'brightness',
    'sealedFixture',
    'dimmer',
  ];

  /// 指定フィールドの選択肢を返す
  static List<String> optionsFor(String field) {
    return switch (field) {
      'baseSize' => ['E26', 'E17'],
      'colorTone' => ['電球色', '昼白色', '昼光色'],
      'brightness' => ['40', '60', '100'],
      'sealedFixture' => ['はい', 'いいえ'],
      'dimmer' => ['はい', 'いいえ'],
      _ => [],
    };
  }
}
