// lib/features/conversation/conversation_screen.dart
// AI交換コンシェルジュの会話画面
// 構造化カードで会話ターンを表示し、現在のアクションのみ操作可能
// 関連: conversation_orchestrator.dart, classification_runner.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/ml/classifier.dart';
import 'conversation_orchestrator.dart';
import 'models/conversation_turn.dart';
import 'prompts/fixed_prompt_provider.dart';

class ConversationScreen extends StatefulWidget {
  final ConversationOrchestrator orchestrator;
  final ValueNotifier<Classifier> classifierNotifier;
  final ValueNotifier<String?> debugLabelNotifier;

  const ConversationScreen({
    super.key,
    required this.orchestrator,
    required this.classifierNotifier,
    required this.debugLabelNotifier,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _picker = ImagePicker();
  final _scrollController = ScrollController();
  bool _showConditions = false;

  ConversationOrchestrator get _orch => widget.orchestrator;

  @override
  void initState() {
    super.initState();
    _orch.addListener(_onOrchChanged);
    _orch.start();
  }

  void _onOrchChanged() {
    if (mounted) setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _orch.removeListener(_onOrchChanged);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onTakePhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (picked == null) return;
    await _orch.processPhoto(
      picked.path,
      widget.classifierNotifier.value,
      debugLabel: widget.debugLabelNotifier.value,
    );
    _navigateIfReady();
  }

  Future<void> _onPickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (picked == null) return;
    await _orch.processPhoto(
      picked.path,
      widget.classifierNotifier.value,
      debugLabel: widget.debugLabelNotifier.value,
    );
    _navigateIfReady();
  }

  void _navigateIfReady() {
    if (mounted && _orch.step == ConversationStep.readyForResult) {
      _navigateToResult();
    }
  }

  void _navigateToResult() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/result',
        (route) => route.settings.name == '/home',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, size: 20),
            SizedBox(width: 8),
            Text('AI交換コンシェルジュ'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showConditions ? Icons.expand_less : Icons.expand_more,
            ),
            tooltip: '現在分かっている条件',
            onPressed: () => setState(() => _showConditions = !_showConditions),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDisclaimer(),
          if (_showConditions) _buildConditionsPanel(),
          Expanded(child: _buildMessageList()),
          if (_orch.isProcessing) _buildLoadingBar(),
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Colors.amber[50],
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 14, color: Colors.amber[800]),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '商品が完全に同じであることは保証しません',
              style: TextStyle(fontSize: 11, color: Colors.amber[900]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingBar() {
    return const Padding(
      padding: EdgeInsets.all(12),
      child: LinearProgressIndicator(),
    );
  }

  Widget _buildConditionsPanel() {
    final evidence = _orch.controller.evidence;
    final checks = evidence?.manualChecks;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '現在分かっている条件',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 4),
          _conditionRow('口金サイズ', _labelFor('baseSize', checks?.baseSize)),
          _conditionRow('光の色', _labelFor('colorTone', checks?.colorTone)),
          _conditionRow('明るさ', _labelFor('brightness', checks?.brightness)),
          _conditionRow('密閉器具', _labelFor('sealedFixture', checks?.sealedFixture)),
          _conditionRow('調光器', _labelFor('dimmer', checks?.dimmer)),
        ],
      ),
    );
  }

  String _labelFor(String field, String? value) {
    if (value == null || value == 'unknown') return '未確認';
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

  Widget _conditionRow(String label, String display) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Text(
        '$label: $display',
        style: TextStyle(
          fontSize: 11,
          color: display == '未確認' ? Colors.grey : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    final turns = _orch.turns;
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: turns.length,
      itemBuilder: (context, index) {
        final turn = turns[index];
        final isLastAgent = index == turns.length - 1 &&
            turn.role == ConversationRole.agent;
        return _buildTurnCard(turn, showActions: isLastAgent);
      },
    );
  }

  Widget _buildTurnCard(ConversationTurn turn, {bool showActions = false}) {
    switch (turn.role) {
      case ConversationRole.agent:
        return _buildAgentCard(turn, showActions: showActions);
      case ConversationRole.user:
        return _buildUserCard(turn);
      case ConversationRole.system:
        return _buildSystemCard(turn);
    }
  }

  Widget _buildAgentCard(ConversationTurn turn, {bool showActions = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (turn.purpose != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.teal[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '目的: ${turn.purpose}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[800],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Text(
                turn.message,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
              if (turn.reason != null && turn.reason!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        turn.reason!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (showActions && turn.actions.isNotEmpty) ...[
                const SizedBox(height: 12),
                ..._buildActions(turn.actions),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(ConversationTurn turn) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'あなた',
                    style: TextStyle(fontSize: 10, color: Colors.blue[400]),
                  ),
                  const SizedBox(height: 2),
                  Text(turn.message, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemCard(ConversationTurn turn) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Center(
        child: Text(
          turn.message,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  List<Widget> _buildActions(List<PromptAction> actions) {
    final widgets = <Widget>[];
    final photoActions = <PromptAction>[];
    final choiceActions = <PromptAction>[];
    final otherActions = <PromptAction>[];

    for (final a in actions) {
      switch (a.type) {
        case PromptActionType.takePhoto:
        case PromptActionType.pickImage:
          photoActions.add(a);
        case PromptActionType.selectChoice:
          choiceActions.add(a);
        default:
          otherActions.add(a);
      }
    }

    if (photoActions.isNotEmpty) {
      widgets.add(
        Row(
          children: photoActions.map((a) {
            final isCamera = a.type == PromptActionType.takePhoto;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: isCamera ? 0 : 4,
                  right: isCamera ? 4 : 0,
                ),
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () => _onActionTap(a),
                    icon: Icon(
                      isCamera ? Icons.camera_alt : Icons.photo_library,
                      size: 20,
                    ),
                    label: Text(a.label, style: const TextStyle(fontSize: 13)),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    }

    if (choiceActions.isNotEmpty) {
      widgets.add(const SizedBox(height: 8));
      widgets.add(
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: choiceActions
              .map((a) => ActionChip(
                    label: Text(a.label, style: const TextStyle(fontSize: 13)),
                    onPressed: () => _onActionTap(a),
                    backgroundColor: Colors.teal[50],
                  ))
              .toList(),
        ),
      );
    }

    if (otherActions.isNotEmpty) {
      widgets.add(const SizedBox(height: 8));
      widgets.addAll(
        otherActions.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => _onActionTap(a),
                  child: Text(a.label, style: const TextStyle(fontSize: 13)),
                ),
              ),
            )),
      );
    }

    return widgets;
  }

  Future<void> _onActionTap(PromptAction action) async {
    if (_orch.isProcessing) return;

    switch (action.type) {
      case PromptActionType.takePhoto:
        await _onTakePhoto();
      case PromptActionType.pickImage:
        await _onPickImage();
      case PromptActionType.selectChoice:
        await _onSelectChoice(action);
      case PromptActionType.skip:
        await _orch.skipToManual();
        _navigateIfReady();
      case PromptActionType.continueAction:
        if (action.value == 'show_result') {
          _navigateToResult();
        } else {
          _orch.begin();
        }
    }
  }

  Future<void> _onSelectChoice(PromptAction action) async {
    if (action.value == null) return;

    if (_orch.step == ConversationStep.waitingForManualCheck) {
      final lastAgentTurn = _orch.turns.reversed.firstWhere(
        (t) => t.role == ConversationRole.agent,
      );
      final field = _guessFieldFromPurpose(lastAgentTurn.purpose ?? '');
      await _orch.answerManualCheck(field, action.label);
      _navigateIfReady();
    } else {
      await _orch.selectIntent(action.value!);
    }
  }

  String _guessFieldFromPurpose(String purpose) {
    if (purpose.contains('口金')) return 'baseSize';
    if (purpose.contains('光')) return 'colorTone';
    if (purpose.contains('明る')) return 'brightness';
    if (purpose.contains('照明') || purpose.contains('密閉')) return 'sealedFixture';
    if (purpose.contains('調光')) return 'dimmer';
    return 'baseSize';
  }
}
