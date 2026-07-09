// lib/features/capture/capture_guide_screen.dart
// 撮影ガイド画面：現在の撮影ステップを表示し、撮影/画像選択ボタンを提供
// MockClassifierを使ったデバッグ用ラベル選択機能付き
// 関連: analysis_instruction_screen.dart, mock_classifier.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/ml/mock_classifier.dart';
import '../../core/session/session_controller.dart';

class CaptureGuideScreen extends StatefulWidget {
  final SessionController controller;
  final ValueNotifier<String?> debugLabelNotifier;

  const CaptureGuideScreen({
    super.key,
    required this.controller,
    required this.debugLabelNotifier,
  });

  @override
  State<CaptureGuideScreen> createState() => _CaptureGuideScreenState();
}

class _CaptureGuideScreenState extends State<CaptureGuideScreen> {
  final _classifier = MockClassifier();
  final _picker = ImagePicker();
  bool _isAnalyzing = false;

  // 撮影ステップに応じたガイド情報
  static const _stepGuides = {
    'full_view': _GuideInfo(
      stepLabel: 'ステップ 1/3',
      title: '電球全体を撮影',
      description: '電球全体が写るように、電球から20〜30cm離れて撮影しましょう。',
      instruction: '口金のサイズと電球の形状を確認します',
    ),
    'base_view': _GuideInfo(
      stepLabel: 'ステップ 2/3',
      title: '口金部分を撮影',
      description: '口金（金属部分）が画面いっぱいになるように近づけて撮影しましょう。',
      instruction: 'E26/E17など口金サイズを確認します',
    ),
    'label_view': _GuideInfo(
      stepLabel: 'ステップ 3/3',
      title: '側面の印字を撮影',
      description: '電球の側面にある型番や仕様の印字を撮影しましょう。',
      instruction: '明るさや光色の手がかりを得ます',
    ),
    'fixture_check': _GuideInfo(
      stepLabel: '器具確認',
      title: '照明器具を確認',
      description: '照明器具の状態を確認してください。',
      instruction: '密閉器具か調光器の有無を確認します',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final session = widget.controller.session;
    final step = session?.currentStep ?? 'full_view';
    final guide = _stepGuides[step] ?? _stepGuides['full_view']!;

    return Scaffold(
      appBar: AppBar(title: const Text('撮影ガイド')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ステップ表示
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                guide.stepLabel,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ガイド内容
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guide.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      guide.description,
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            guide.instruction,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // カメラプレビュー（モック：アイコン表示）
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt,
                        size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'カメラプレビュー',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 撮影/選択ボタン
            if (_isAnalyzing)
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: null,
                  icon: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  label: const Text('判定中...', style: TextStyle(fontSize: 18)),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () => _onCapture(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt, size: 28),
                        label: const Text('撮影する', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: () => _onCapture(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library, size: 28),
                        label: const Text('画像を選ぶ', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),

            // 手動で進む
            TextButton(
              onPressed: _isAnalyzing
                  ? null
                  : () => _navigateToNext(context, 'manual'),
              child: const Text('写真ではうまく撮れない → 手動で確認'),
            ),
            if (widget.controller.lastOutput?.type == 'next_instruction' &&
                widget.controller.lastOutput?.requiredStep != null &&
                step != widget.controller.lastOutput!.requiredStep) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _navigateToNext(context, 'next'),
                child: const Text('撮影済み → 次に進む'),
              ),
            ],

            // デバッグ：分類ラベル手動選択
            const SizedBox(height: 8),
            Card(
              color: Colors.amber[50],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'デバッグ: 分類ラベル選択',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: widget.debugLabelNotifier.value,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'bulb_full_view', child: Text('電球全体')),
                        DropdownMenuItem(value: 'bulb_base_view', child: Text('口金')),
                        DropdownMenuItem(value: 'bulb_label_side_view', child: Text('側面印字')),
                        DropdownMenuItem(value: 'fixture_socket_view', child: Text('器具')),
                        DropdownMenuItem(value: 'bulb_package_view', child: Text('パッケージ')),
                        DropdownMenuItem(value: 'unknown_too_dark', child: Text('暗い')),
                        DropdownMenuItem(value: 'unknown_blurry', child: Text('ぼやけ')),
                        DropdownMenuItem(value: 'unknown_too_far', child: Text('遠い')),
                        DropdownMenuItem(value: 'unknown_other', child: Text('その他不明')),
                      ],
                      onChanged: (val) {
                        widget.debugLabelNotifier.value = val;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onCapture(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (picked == null) return;
    } catch (_) {
      // pickerが使えない環境でもモックで進める
    }

    setState(() => _isAnalyzing = true);

    final debugLabel = widget.debugLabelNotifier.value;
    if (debugLabel != null) {
      _classifier.fixedLabel = debugLabel;
    } else {
      _classifier.fixedLabel = null;
    }

    final result = await _classifier.classify('mock_path');
    widget.controller.processClassification(result);

    setState(() => _isAnalyzing = false);

    if (!mounted) return;

    final output = widget.controller.lastOutput;
    if (output != null) {
      _navigateToNext(context, output.type);
    }
  }

  void _navigateToNext(BuildContext context, String type) {
    final output = widget.controller.lastOutput;
    if (output == null) return;

    switch (output.type) {
      case 'next_instruction':
        if (output.requiredStep == 'fixture_check') {
          Navigator.pushReplacementNamed(context, '/capture');
        } else {
          Navigator.pushReplacementNamed(context, '/capture');
        }
        break;
      case 'manual_check':
        Navigator.pushNamed(context, '/manual_check');
        break;
      case 'purchase_result':
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/result',
          (route) => route.settings.name == '/home',
        );
        break;
    }
  }
}

class _GuideInfo {
  final String stepLabel;
  final String title;
  final String description;
  final String instruction;

  const _GuideInfo({
    required this.stepLabel,
    required this.title,
    required this.description,
    required this.instruction,
  });
}
