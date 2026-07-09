// lib/core/session/session_controller.dart
// 撮影セッション全体を管理する
// 画面間の状態共有とルールエンジン呼び出しを担当
// 関連: 全画面, rule_engine.dart, mock_classifier.dart

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/capture_session.dart';
import '../models/classification_result.dart';
import '../models/evidence_state.dart';
import '../models/purchase_result.dart';
import '../models/rule_engine_output.dart';
import '../rules/rule_engine.dart';
import '../storage/purchase_result_storage.dart';
import '../storage/session_storage.dart';

class SessionController extends ChangeNotifier {
  final _uuid = const Uuid();
  final _ruleEngine = RuleEngine();
  final _sessionStorage = SessionStorage();
  final _resultStorage = PurchaseResultStorage();

  CaptureSession? _session;
  EvidenceState? _evidence;
  RuleEngineOutput? _lastOutput;
  PurchaseResult? _lastResult;
  ClassificationResult? _lastClassification;

  CaptureSession? get session => _session;
  EvidenceState? get evidence => _evidence;
  RuleEngineOutput? get lastOutput => _lastOutput;
  PurchaseResult? get lastResult => _lastResult;
  ClassificationResult? get lastClassification => _lastClassification;

  /// 新しいセッションを開始する
  Future<void> startSession(String category) async {
    final now = DateTime.now();
    _session = CaptureSession(
      id: _uuid.v4(),
      category: category,
      status: 'in_progress',
      currentStep: 'full_view',
      createdAt: now,
      updatedAt: now,
    );
    _evidence = EvidenceState(sessionId: _session!.id, itemType: category);
    _lastOutput = null;
    _lastResult = null;
    _lastClassification = null;
    await _sessionStorage.saveSession(_session!);
    notifyListeners();
  }

  /// 分類結果を処理してエビデンスを更新する
  Future<void> processClassification(ClassificationResult result) async {
    if (_evidence == null || _session == null) return;

    _lastClassification = result;
    final label = result.topLabel;

    if (label == 'unknown_too_dark' ||
        label == 'unknown_blurry' ||
        label == 'unknown_too_far') {
      _session!.failedAttempts++;
      _lastOutput = _ruleEngine.handlePoorQuality(label);
      _session!.updatedAt = DateTime.now();
      await _sessionStorage.saveSession(_session!);
      notifyListeners();
      return;
    }

    if (label == 'unknown_other') {
      _session!.failedAttempts++;
      _lastOutput = _ruleEngine.process(_evidence!, failedAttempts: _session!.failedAttempts);
      _session!.updatedAt = DateTime.now();
      await _sessionStorage.saveSession(_session!);
      notifyListeners();
      return;
    }

    _session!.failedAttempts = 0;

    switch (label) {
      case 'bulb_full_view':
        _evidence!.fullViewCaptured = true;
        _session!.currentStep = 'base_view';
        break;
      case 'bulb_base_view':
        _evidence!.baseViewCaptured = true;
        _session!.currentStep = 'label_view';
        break;
      case 'bulb_label_side_view':
        _evidence!.labelViewCaptured = true;
        _session!.currentStep = 'fixture_check';
        break;
      case 'fixture_socket_view':
        _evidence!.fixtureChecked = true;
        _session!.currentStep = 'fixture_check';
        break;
      case 'bulb_package_view':
        _evidence!.fullViewCaptured = true;
        _evidence!.baseViewCaptured = true;
        _evidence!.labelViewCaptured = true;
        _session!.currentStep = 'fixture_check';
        break;
    }

    _lastOutput = _ruleEngine.process(_evidence!, failedAttempts: _session!.failedAttempts);
    _session!.updatedAt = DateTime.now();
    await _sessionStorage.saveSession(_session!);
    notifyListeners();
  }

  /// 手動確認の値を更新する
  Future<void> updateManualCheck({
    String? baseSize,
    String? colorTone,
    String? brightness,
    String? sealedFixture,
    String? dimmer,
  }) async {
    if (_evidence == null) return;

    if (baseSize != null) _evidence!.manualChecks.baseSize = baseSize;
    if (colorTone != null) _evidence!.manualChecks.colorTone = colorTone;
    if (brightness != null) _evidence!.manualChecks.brightness = brightness;
    if (sealedFixture != null) _evidence!.manualChecks.sealedFixture = sealedFixture;
    if (dimmer != null) _evidence!.manualChecks.dimmer = dimmer;

    _lastOutput = _ruleEngine.process(_evidence!, failedAttempts: _session?.failedAttempts ?? 0);
    _session!.updatedAt = DateTime.now();
    await _sessionStorage.saveSession(_session!);

    if (_lastOutput!.type == 'purchase_result') {
      await _finalizeResult();
    }

    notifyListeners();
  }

  /// さらに撮影が必要かどうか（false = 結果表示へ進める）
  bool get needsCapture =>
      _evidence != null &&
      (!_evidence!.fullViewCaptured ||
          !_evidence!.baseViewCaptured ||
          !_evidence!.labelViewCaptured ||
          !_evidence!.fixtureChecked);

  Future<void> _finalizeResult() async {
    if (_evidence == null || _session == null) return;

    final checks = _evidence!.manualChecks;
    final baseStr = checks.baseSize.contains('e26') ? 'E26' : 'E17';
    final brightnessStr =
        checks.brightness != 'unknown' ? ' ${checks.brightness}形相当' : '';
    String colorStr;
    switch (checks.colorTone) {
      case 'bulb_color':
        colorStr = '電球色';
        break;
      case 'neutral_white':
        colorStr = '昼白色';
        break;
      case 'daylight':
        colorStr = '昼光色';
        break;
      default:
        colorStr = '';
    }

    final candidateTitle = '$baseStr LED電球$brightnessStr $colorStr'.trim();

    final checkBeforeBuy = <String>[
      '口金が$baseStrであることを現物またはパッケージで確認してください',
    ];
    if (checks.sealedFixture == 'yes') {
      checkBeforeBuy.add('密閉器具対応の商品を選んでください');
    }
    if (checks.dimmer == 'yes') {
      checkBeforeBuy.add('調光器対応の商品を選んでください');
    }
    if (checks.brightness == 'unknown') {
      checkBeforeBuy.add('明るさ（ワット数相当）をパッケージで確認してください');
    }

    final summary =
        '$baseStr口金のLED電球を探しています。$brightnessStr $colorStr候補です。'

        '${checks.sealedFixture == 'yes' ? '密閉器具対応が必要です。' : ''}'
        '${checks.dimmer == 'yes' ? '調光器対応が必要です。' : ''}';

    final now = DateTime.now();
    _lastResult = PurchaseResult(
      id: _uuid.v4(),
      sessionId: _session!.id,
      candidateTitle: candidateTitle,
      confidenceLabel: '候補',
      searchKeywords: ['$baseStr LED電球$brightnessStr $colorStr'.trim()],
      checkBeforeBuy: checkBeforeBuy,
      shopStaffSummary: summary,
      createdAt: now,
    );

    _session!.status = 'completed';
    _session!.currentStep = 'result';
    _session!.resultId = _lastResult!.id;
    _session!.updatedAt = now;

    await _sessionStorage.saveSession(_session!);
    await _resultStorage.saveResult(_lastResult!);
  }

  /// セッションを破棄する
  Future<void> abandonSession() async {
    if (_session != null) {
      _session!.status = 'abandoned';
      _session!.updatedAt = DateTime.now();
      await _sessionStorage.saveSession(_session!);
    }
    _session = null;
    _evidence = null;
    _lastOutput = null;
    _lastResult = null;
    _lastClassification = null;
    notifyListeners();
  }

  /// リセット
  void reset() {
    _session = null;
    _evidence = null;
    _lastOutput = null;
    _lastResult = null;
    _lastClassification = null;
    notifyListeners();
  }
}
