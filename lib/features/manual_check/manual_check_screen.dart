// lib/features/manual_check/manual_check_screen.dart
// 手動確認画面：不足項目だけを質問する
// 全項目を一気に聞かず、不足項目のみ表示
// 関連: evidence_state.dart, session_controller.dart

import 'package:flutter/material.dart';
import '../../core/models/evidence_state.dart';
import '../../core/models/rule_engine_output.dart';
import '../../core/session/session_controller.dart';

class ManualCheckScreen extends StatefulWidget {
  final SessionController controller;

  const ManualCheckScreen({super.key, required this.controller});

  @override
  State<ManualCheckScreen> createState() => _ManualCheckScreenState();
}

class _ManualCheckScreenState extends State<ManualCheckScreen> {
  String? _baseSize;
  String? _colorTone;
  String? _brightness;
  String? _sealedFixture;
  String? _dimmer;

  @override
  void initState() {
    super.initState();
    final checks = widget.controller.evidence?.manualChecks;
    if (checks != null) {
      _baseSize = checks.baseSize != Mc.unknown ? checks.baseSize : null;
      _colorTone = checks.colorTone != Mc.unknown ? checks.colorTone : null;
      _brightness = checks.brightness != Mc.unknown ? checks.brightness : null;
      _sealedFixture = checks.sealedFixture != Mc.unknown ? checks.sealedFixture : null;
      _dimmer = checks.dimmer != Mc.unknown ? checks.dimmer : null;
    }
  }

  bool get _canConfirm {
    final checks = widget.controller.evidence?.manualChecks;
    if (checks == null) return false;

    // 表示されている全項目が選択済みか確認
    if (checks.baseSize == Mc.unknown && _baseSize == null) return false;
    if (checks.colorTone == Mc.unknown && _colorTone == null) return false;
    if (checks.brightness == Mc.unknown && _brightness == null) return false;
    if (checks.sealedFixture == Mc.unknown && _sealedFixture == null) return false;
    if (checks.dimmer == Mc.unknown && _dimmer == null) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final checks = widget.controller.evidence?.manualChecks;
    if (checks == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('手動確認')),
        body: const Center(child: Text('セッションがありません')),
      );
    }

    final unknownItems = <String>[
      if (_baseSize == null && checks.baseSize == Mc.unknown) '口金サイズ',
      if (_colorTone == null && checks.colorTone == Mc.unknown) '光色',
      if (_brightness == null && checks.brightness == Mc.unknown) '明るさ',
      if (_sealedFixture == null && checks.sealedFixture == Mc.unknown) '密閉器具',
      if (_dimmer == null && checks.dimmer == Mc.unknown) '調光器',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('手動確認')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '写真から読み取れなかった項目があります。\nわかる範囲で選んでください。',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 24),

            if (unknownItems.isEmpty)
              const Text('すべての項目が確認済みです。')
            else ...[
              for (final item in unknownItems) ...[
                if (item == '口金サイズ') _buildBaseSizeSelector(),
                if (item == '光色') _buildColorToneSelector(),
                if (item == '明るさ') _buildBrightnessSelector(),
                if (item == '密閉器具') _buildSealedFixtureSelector(),
                if (item == '調光器') _buildDimmerSelector(),
                const SizedBox(height: 16),
              ],
            ],

            const SizedBox(height: 24),

            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _canConfirm ? _onConfirm : null,
                icon: const Icon(Icons.check),
                label: const Text('確認して次へ', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBaseSizeSelector() {
    return _buildSelectorGroup(
      label: '口金サイズ',
      options: const [
        (Mc.e26Candidate, 'E26（直径26mm / 一般的なサイズ）'),
        (Mc.e17Candidate, 'E17（直径17mm / 小口径）'),
      ],
      selected: _baseSize,
      onSelect: (v) => setState(() => _baseSize = v),
    );
  }

  Widget _buildColorToneSelector() {
    return _buildSelectorGroup(
      label: '光色',
      options: const [
        (Mc.bulbColor, '電球色（オレンジがかった暖かい色）'),
        (Mc.neutralWhite, '昼白色（自然な白色）'),
        (Mc.daylight, '昼光色（青みがかった白色）'),
      ],
      selected: _colorTone,
      onSelect: (v) => setState(() => _colorTone = v),
    );
  }

  Widget _buildBrightnessSelector() {
    return _buildSelectorGroup(
      label: '明るさ（ワット数相当）',
      options: const [
        ('40', '40形相当（やや暗め）'),
        ('60', '60形相当（標準）'),
        ('100', '100形相当（明るめ）'),
      ],
      selected: _brightness,
      onSelect: (v) => setState(() => _brightness = v),
    );
  }

  Widget _buildSealedFixtureSelector() {
    return _buildSelectorGroup(
      label: '密閉器具',
      options: const [
        (Mc.sealedYes, '密閉器具で使う（密閉対応が必要）'),
        (Mc.sealedNo, '密閉器具ではない'),
      ],
      selected: _sealedFixture,
      onSelect: (v) => setState(() => _sealedFixture = v),
    );
  }

  Widget _buildDimmerSelector() {
    return _buildSelectorGroup(
      label: '調光器',
      options: const [
        (Mc.dimmerYes, '調光スイッチを使っている（調光対応が必要）'),
        (Mc.dimmerNo, '調光スイッチは使っていない'),
      ],
      selected: _dimmer,
      onSelect: (v) => setState(() => _dimmer = v),
    );
  }

  Widget _buildSelectorGroup({
    required String label,
    required List<(String, String)> options,
    required String? selected,
    required ValueChanged<String> onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...options.map(
          (opt) {
            final isSelected = opt.$1 == selected;
            return InkWell(
              onTap: () => onSelect(opt.$1),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        opt.$2,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _onConfirm() async {
    await widget.controller.updateManualCheck(
      baseSize: _baseSize ?? widget.controller.evidence?.manualChecks.baseSize,
      colorTone: _colorTone ?? widget.controller.evidence?.manualChecks.colorTone,
      brightness: _brightness ?? widget.controller.evidence?.manualChecks.brightness,
      sealedFixture: _sealedFixture ?? widget.controller.evidence?.manualChecks.sealedFixture,
      dimmer: _dimmer ?? widget.controller.evidence?.manualChecks.dimmer,
    );
    if (!mounted) return;
    final output = widget.controller.lastOutput;

    if (output?.type == OutputType.purchaseResult) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/result',
        (route) => route.settings.name == '/home',
      );
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/capture',
        (route) => route.settings.name == '/home',
      );
    }
  }
}
