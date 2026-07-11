// lib/features/conversation/conversation_orchestrator.dart
// 会話の進行を管理するオーケストレーター
// ユーザーのアクションを受け取り、SessionControllerとFixedPromptProviderを連携させる
// 関連: fixed_prompt_provider.dart, conversation_screen.dart, session_controller.dart

import 'package:flutter/foundation.dart';

import '../../core/ml/classifier.dart';
import '../../core/models/classification_result.dart';
import '../../core/models/evidence_state.dart';
import '../../core/models/rule_engine_output.dart';
import '../../core/session/session_controller.dart';
import '../capture/classification_runner.dart';
import 'models/conversation_turn.dart';
import 'prompts/fixed_prompt_provider.dart';

class ConversationOrchestrator extends ChangeNotifier {
  final SessionController controller;
  final FixedPromptProvider _provider = FixedPromptProvider();

  ConversationOrchestrator({required this.controller});
  final List<ConversationTurn> _turns = [];
  ConversationStep _step = ConversationStep.introduction;
  bool _isProcessing = false;
  String? _intent;

  ConversationRole get lastRole =>
      _turns.isEmpty ? ConversationRole.system : _turns.last.role;

  List<ConversationTurn> get turns => List.unmodifiable(_turns);
  ConversationStep get step => _step;
  bool get isProcessing => _isProcessing;
  String? get intent => _intent;

  /// 会話を開始する
  void start() {
    _turns.clear();
    _step = ConversationStep.introduction;
    _turns.add(_provider.introduction());
    notifyListeners();
  }

  /// ユーザーが始めるを押した
  void begin() {
    _turns.add(_provider.userMessage('始める'));
    _step = ConversationStep.intentSelection;
    _turns.add(_provider.intentSelection());
    notifyListeners();
  }

  /// ユーザーが目的を選択した
  Future<void> selectIntent(String intentValue) async {
    if (_isProcessing) return;
    _isProcessing = true;
    notifyListeners();

    _intent = intentValue;
    final label =
        intentValue == 'find_same' ? '同じ電球を探したい' : '条件だけ確認したい';
    _turns.add(_provider.userMessage(label));

    await controller.startSession('bulb');

    if (intentValue == 'check_spec') {
      await controller.setManualFallback();
    }

    _step = ConversationStep.waitingForPhoto;
    _turns.add(_provider.photoRequest(
      purpose: '電球全体の形状確認',
      message: '電球全体が入るように撮影してください。口金や印字が見えなくても構いません。',
      reason: '口金サイズ（E26/E17）の見分けと、製品種別を判断するためです。',
    ));
    _isProcessing = false;
    notifyListeners();
  }

  /// 写真の分類結果を処理する
  Future<void> processPhoto(
    String imagePath,
    Classifier classifier, {
    String? debugLabel,
  }) async {
    if (_isProcessing) return;
    _isProcessing = true;
    _turns.add(_provider.systemPhotoReceived());
    notifyListeners();

    try {
      final runner = ClassificationRunner(classifier);
      final result = await runner.run(imagePath, debugLabel: debugLabel);

      if (result.topLabel.isPoorQuality ||
          result.topLabel == ImageLabel.unknownOther) {
        _turns.add(_provider.userMessage('（写真の確認に失敗しました）'));
        _turns.add(_retryOrSkipPrompt());
        _isProcessing = false;
        notifyListeners();
        return;
      }

      await controller.processClassification(result);
      await controller.setManualFallback();
      await controller.updateManualCheck();

      await _advanceAfterPhoto();
    } catch (e) {
      debugPrint('Conversation photo error: $e');
      _turns.add(_provider.userMessage('（エラーが発生しました）'));
      _turns.add(_retryOrSkipPrompt());
    }
    _isProcessing = false;
    notifyListeners();
  }

  /// 写真を使わず手動確認へスキップ
  Future<void> skipToManual() async {
    if (_isProcessing) return;
    _isProcessing = true;
    _turns.add(_provider.userMessage('写真を使わず条件確認へ'));
    notifyListeners();

    if (controller.session == null) {
      await controller.startSession('bulb');
    }
    await controller.setManualFallback();

    if (controller.lastOutput?.type != OutputType.purchaseResult) {
      await controller.updateManualCheck();
    }

    await _advanceAfterPhoto();
    _isProcessing = false;
    notifyListeners();
  }

  Future<void> _advanceAfterPhoto() async {
    if (controller.lastOutput?.type == OutputType.purchaseResult) {
      _step = ConversationStep.readyForResult;
      _turns.add(_provider.readyForResult());
      return;
    }

    _step = ConversationStep.waitingForManualCheck;
    await _askNextManualCheck();
  }

  ConversationTurn _retryOrSkipPrompt() {
    return ConversationTurn(
      id: 'error_retry',
      role: ConversationRole.agent,
      type: ConversationTurnType.warning,
      message: '写真の確認ができませんでした。もう一度撮影するか、手動で条件を確認してください。',
      purpose: '確認エラー',
      createdAt: DateTime.now(),
      actions: [
        const PromptAction(
          id: 'retry_photo',
          type: PromptActionType.takePhoto,
          label: 'もう一度撮影する',
        ),
        const PromptAction(
          id: 'skip_to_manual',
          type: PromptActionType.skip,
          label: '写真を使わず条件確認へ',
        ),
      ],
    );
  }

  Future<void> _askNextManualCheck() async {
    final evidence = controller.evidence;
    if (evidence == null) return;

    final unknownField = FixedPromptProvider.manualCheckOrder.firstWhere(
      (f) => _getFieldValue(evidence, f) == 'unknown',
      orElse: () => '',
    );

    if (unknownField.isEmpty) {
      if (controller.lastOutput?.type == OutputType.purchaseResult) {
        _step = ConversationStep.readyForResult;
        _turns.add(_provider.readyForResult());
      }
      return;
    }

    final options = FixedPromptProvider.optionsFor(unknownField);
    _turns.add(_provider.manualCheck(unknownField, options));
  }

  /// 手動確認の回答を受け取る
  Future<void> answerManualCheck(String field, String displayValue) async {
    if (_isProcessing) return;
    _isProcessing = true;
    notifyListeners();

    final mcValue = _toMcValue(field, displayValue);
    _turns.add(_provider.userMessage(displayValue));

    switch (field) {
      case 'baseSize':
        await controller.updateManualCheck(baseSize: mcValue);
      case 'colorTone':
        await controller.updateManualCheck(colorTone: mcValue);
      case 'brightness':
        await controller.updateManualCheck(brightness: mcValue);
      case 'sealedFixture':
        await controller.updateManualCheck(sealedFixture: mcValue);
      case 'dimmer':
        await controller.updateManualCheck(dimmer: mcValue);
    }

    final evidence = controller.evidence;
    if (evidence != null &&
        evidence.manualChecks.isComplete &&
        controller.lastOutput?.type == OutputType.purchaseResult) {
      _step = ConversationStep.readyForResult;
      _turns.add(_provider.readyForResult());
    } else {
      await _askNextManualCheck();
    }

    _isProcessing = false;
    notifyListeners();
  }

  /// 結果画面へ進む
  void goToResult() {
    if (_step != ConversationStep.readyForResult) return;
    _step = ConversationStep.completed;
    notifyListeners();
  }

  String _getFieldValue(EvidenceState evidence, String field) {
    return switch (field) {
      'baseSize' => evidence.manualChecks.baseSize,
      'colorTone' => evidence.manualChecks.colorTone,
      'brightness' => evidence.manualChecks.brightness,
      'sealedFixture' => evidence.manualChecks.sealedFixture,
      'dimmer' => evidence.manualChecks.dimmer,
      _ => 'unknown',
    };
  }

  String _toMcValue(String field, String displayValue) {
    return switch (field) {
      'baseSize' => switch (displayValue) {
        'E26' => 'user_selected_e26',
        'E17' => 'user_selected_e17',
        _ => 'unknown',
      },
      'colorTone' => switch (displayValue) {
        '電球色' => 'bulb_color',
        '昼白色' => 'neutral_white',
        '昼光色' => 'daylight',
        _ => 'unknown',
      },
      'brightness' => displayValue,
      'sealedFixture' => switch (displayValue) {
        'はい' => 'yes',
        'いいえ' => 'no',
        _ => 'unknown',
      },
      'dimmer' => switch (displayValue) {
        'はい' => 'yes',
        'いいえ' => 'no',
        _ => 'unknown',
      },
      _ => 'unknown',
    };
  }


}
