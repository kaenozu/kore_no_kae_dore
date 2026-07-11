// ignore_for_file: prefer_initializing_formals, prefer_final_fields

import 'package:kore_no_kae_dore/core/models/capture_session.dart';
import 'package:kore_no_kae_dore/core/models/classification_result.dart';
import 'package:kore_no_kae_dore/core/models/evidence_state.dart';
import 'package:kore_no_kae_dore/core/models/match_level.dart';
import 'package:kore_no_kae_dore/core/models/purchase_result.dart';
import 'package:kore_no_kae_dore/core/models/rule_engine_output.dart';
import 'package:kore_no_kae_dore/core/session/session_controller.dart';

class StubSessionController extends SessionController {
  StubSessionController({
    CaptureSession? session,
    EvidenceState? evidence,
    RuleEngineOutput? lastOutput,
    PurchaseResult? lastResult,
    this.onUpdateManualCheck,
  }) : _session = session,
       _evidence = evidence,
       _lastOutput = lastOutput,
       _lastResult = lastResult;

  CaptureSession? _session;
  EvidenceState? _evidence;
  RuleEngineOutput? _lastOutput;
  PurchaseResult? _lastResult;
  final Future<void> Function({
    String? baseSize,
    String? colorTone,
    String? brightness,
    String? sealedFixture,
    String? dimmer,
  })?
  onUpdateManualCheck;

  @override
  CaptureSession? get session => _session;
  @override
  EvidenceState? get evidence => _evidence;
  @override
  RuleEngineOutput? get lastOutput => _lastOutput;
  @override
  PurchaseResult? get lastResult => _lastResult;

  set testLastOutput(RuleEngineOutput? v) => _lastOutput = v;
  set testLastResult(PurchaseResult? v) => _lastResult = v;

  @override
  Future<void> processClassification(ClassificationResult result) async {}

  @override
  Future<void> updateManualCheck({
    String? baseSize,
    String? colorTone,
    String? brightness,
    String? sealedFixture,
    String? dimmer,
  }) async {
    await onUpdateManualCheck?.call(
      baseSize: baseSize,
      colorTone: colorTone,
      brightness: brightness,
      sealedFixture: sealedFixture,
      dimmer: dimmer,
    );
    if (_evidence != null) {
      if (baseSize != null) _evidence!.manualChecks.baseSize = baseSize;
      if (colorTone != null) _evidence!.manualChecks.colorTone = colorTone;
      if (brightness != null) _evidence!.manualChecks.brightness = brightness;
      if (sealedFixture != null) _evidence!.manualChecks.sealedFixture = sealedFixture;
      if (dimmer != null) _evidence!.manualChecks.dimmer = dimmer;
    }
    if (_evidence != null && _evidence!.manualChecks.isComplete) {
      _lastOutput = RuleEngineOutput(
        type: OutputType.purchaseResult,
        title: '購入候補',
        message: '完了',
      );
      _lastResult = PurchaseResult(
        id: 'mock-result',
        sessionId: _session?.id ?? '',
        candidateTitle: 'E26 LED電球 60形相当 昼光色',
        confidenceLabel: '候補',
        searchKeywords: ['E26 LED電球'],
        checkBeforeBuy: ['口金を確認'],
        shopStaffSummary: 'E26口金のLED電球',
        createdAt: DateTime.now(),
        matchLevel: MatchLevel.compatibleSpec,
      );
    }
  }

  @override
  void reset() => _lastResult = null;
}
