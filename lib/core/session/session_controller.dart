// lib/core/session/session_controller.dart
// 撮影セッション全体を管理する
// 画面間の状態共有とルールエンジン呼び出しを担当
// 関連: 全画面, rule_engine.dart, mock_classifier.dart

import 'package:uuid/uuid.dart';

import '../models/capture_session.dart';
import '../models/classification_result.dart';
import '../models/evidence_state.dart';
import '../models/purchase_result.dart';
import '../models/rule_engine_output.dart';
import '../rules/rule_engine.dart';
import '../storage/purchase_result_storage.dart';
import '../storage/session_storage.dart';

class SessionController {
  final _uuid = const Uuid();
  final _ruleEngine = RuleEngine();
  final storage = SessionStorage();
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

  /// 保存済みのセッションとエビデンスを読み込む
  Future<void> loadSession(CaptureSession session, EvidenceState evidence) async {
    _session = session;
    _evidence = evidence;
    _lastOutput = _ruleEngine.process(evidence, failedAttempts: session.failedAttempts);
    if (_lastOutput!.type == OutputType.purchaseResult) {
      _lastResult = await _resultStorage.loadResult(session.resultId ?? '');
    }
  }

  /// 新しいセッションを開始する
  Future<void> startSession(String category) async {
    final now = DateTime.now();
    _session = CaptureSession(
      id: _uuid.v4(),
      category: category,
      status: 'in_progress',
      currentStep: StepName.fullView,
      createdAt: now,
      updatedAt: now,
    );
    _evidence = EvidenceState(sessionId: _session!.id, itemType: category);
    _lastOutput = null;
    _lastResult = null;
    _lastClassification = null;
    await storage.saveSession(_session!);
    await storage.saveEvidence(_evidence!);
  }

  /// 分類結果を処理してエビデンスを更新する
  Future<void> processClassification(ClassificationResult result) async {
    if (_evidence == null || _session == null) return;

    _lastClassification = result;
    final label = result.topLabel;

    if (label.isPoorQuality) {
      _session!.failedAttempts++;
      _lastOutput = _ruleEngine.handlePoorQuality(label);
      _session!.updatedAt = DateTime.now();
      await storage.saveSession(_session!);
      await storage.saveEvidence(_evidence!);
      return;
    }

    if (label == ImageLabel.unknownOther) {
      _session!.failedAttempts++;
      _lastOutput = _ruleEngine.process(_evidence!, failedAttempts: _session!.failedAttempts);
      _session!.updatedAt = DateTime.now();
      await storage.saveSession(_session!);
      await storage.saveEvidence(_evidence!);
      return;
    }

    _session!.failedAttempts = 0;

    switch (label) {
      case ImageLabel.bulbFullView:
        _evidence!.fullViewCaptured = true;
        _session!.currentStep = StepName.baseView;
        break;
      case ImageLabel.bulbBaseView:
        _evidence!.baseViewCaptured = true;
        _session!.currentStep = StepName.labelView;
        break;
      case ImageLabel.bulbLabelSideView:
        _evidence!.labelViewCaptured = true;
        _session!.currentStep = StepName.fixtureCheck;
        break;
      case ImageLabel.fixtureSocketView:
        _evidence!.fixtureChecked = true;
        _session!.currentStep = StepName.fixtureCheck;
        break;
      case ImageLabel.bulbPackageView:
        _evidence!.fullViewCaptured = true;
        _evidence!.baseViewCaptured = true;
        _evidence!.labelViewCaptured = true;
        _session!.currentStep = StepName.fixtureCheck;
        break;
      default:
        break;
    }

    _lastOutput = _ruleEngine.process(_evidence!, failedAttempts: _session!.failedAttempts);
    _session!.updatedAt = DateTime.now();
    await storage.saveSession(_session!);
    await storage.saveEvidence(_evidence!);
  }

  /// 手動フォールバックを有効にする（写真エビデンス不足でもpurchaseResultへ進める）
  Future<void> setManualFallback() async {
    if (_evidence == null) return;
    _evidence!.manualFallback = true;
    await storage.saveEvidence(_evidence!);
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

    // 手動確認が完了したらfailedAttemptsをリセットしてpurchaseResultに進める
    if (_evidence!.manualChecks.isComplete) {
      _session!.failedAttempts = 0;
    }
    _lastOutput = _ruleEngine.process(_evidence!, failedAttempts: _session?.failedAttempts ?? 0);
    _session!.updatedAt = DateTime.now();
    await storage.saveSession(_session!);
    await storage.saveEvidence(_evidence!);

    if (_lastOutput!.type == OutputType.purchaseResult) {
      await _finalizeResult();
    }
  }

  Future<void> _finalizeResult() async {
    if (_evidence == null || _session == null) return;

    final checks = _evidence!.manualChecks;
    final baseStr = switch (checks.baseSize) {
      Mc.e26Candidate || Mc.userSelectedE26 => 'E26',
      Mc.e17Candidate || Mc.userSelectedE17 => 'E17',
      _ => 'E26', // unknownは安全側でE26候補
    };
    final brightnessStr =
        checks.brightness != Mc.unknown ? ' ${checks.brightness}形相当' : '';
    String colorStr;
    switch (checks.colorTone) {
      case Mc.bulbColor:
        colorStr = '電球色';
        break;
      case Mc.neutralWhite:
        colorStr = '昼白色';
        break;
      case Mc.daylight:
        colorStr = '昼光色';
        break;
      default:
        colorStr = '';
    }

    final candidateTitle = '$baseStr LED電球$brightnessStr $colorStr'.trim();

    final checkBeforeBuy = <String>[
      '口金が$baseStrであることを現物またはパッケージで確認してください',
    ];
    if (checks.sealedFixture == Mc.sealedYes) {
      checkBeforeBuy.add('密閉器具対応の商品を選んでください');
    }
    if (checks.dimmer == Mc.dimmerYes) {
      checkBeforeBuy.add('調光器対応の商品を選んでください');
    }
    if (checks.brightness == Mc.unknown) {
      checkBeforeBuy.add('明るさ（ワット数相当）をパッケージで確認してください');
    }

    final summary =
        '$baseStr口金のLED電球を探しています。$brightnessStr $colorStr候補です。'

        '${checks.sealedFixture == Mc.sealedYes ? '密閉器具対応が必要です。' : ''}'
        '${checks.dimmer == Mc.dimmerYes ? '調光器対応が必要です。' : ''}';

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
    _session!.currentStep = StepName.result;
    _session!.resultId = _lastResult!.id;
    _session!.updatedAt = now;

    await storage.saveSession(_session!);
    await _resultStorage.saveResult(_lastResult!);
  }

  /// セッションを破棄する
  Future<void> abandonSession() async {
    if (_session != null) {
      _session!.status = 'abandoned';
      _session!.updatedAt = DateTime.now();
      await storage.saveSession(_session!);
    }
    _session = null;
    _evidence = null;
    _lastOutput = null;
    _lastResult = null;
    _lastClassification = null;
  }

  /// リセット
  void reset() {
    _session = null;
    _evidence = null;
    _lastOutput = null;
    _lastResult = null;
    _lastClassification = null;
  }
}
