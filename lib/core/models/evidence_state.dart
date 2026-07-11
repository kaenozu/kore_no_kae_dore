// lib/core/models/evidence_state.dart
// セッション全体の証拠（エビデンス）状態
// どの角度が撮影済みか、手動確認の値は何かを保持する
// 関連: rule_engine.dart, manual_check_screen.dart

class Mc {
  static const unknown = 'unknown';
  static const userSkipped = 'skipped';
  static const e26Candidate = 'e26_candidate';
  static const e17Candidate = 'e17_candidate';
  static const userSelectedE26 = 'user_selected_e26';
  static const userSelectedE17 = 'user_selected_e17';
  static const bulbColor = 'bulb_color';
  static const neutralWhite = 'neutral_white';
  static const daylight = 'daylight';
  static const sealedYes = 'yes';
  static const sealedNo = 'no';
  static const dimmerYes = 'yes';
  static const dimmerNo = 'no';
}

class ManualChecks {
  String baseSize; // Mc.unknown | Mc.e26Candidate | Mc.e17Candidate | ...
  String colorTone; // Mc.unknown | Mc.bulbColor | Mc.neutralWhite | Mc.daylight
  String brightness; // Mc.unknown | "40" | "60" | "100"
  String sealedFixture; // Mc.unknown | Mc.sealedYes | Mc.sealedNo
  String dimmer; // Mc.unknown | Mc.dimmerYes | Mc.dimmerNo

  ManualChecks({
    this.baseSize = Mc.unknown,
    this.colorTone = Mc.unknown,
    this.brightness = Mc.unknown,
    this.sealedFixture = Mc.unknown,
    this.dimmer = Mc.unknown,
  });

  bool get isComplete =>
      baseSize != Mc.unknown &&
      colorTone != Mc.unknown &&
      brightness != Mc.unknown &&
      sealedFixture != Mc.unknown &&
      dimmer != Mc.unknown;

  int get unknownCount =>
      (baseSize == Mc.unknown ? 1 : 0) +
      (colorTone == Mc.unknown ? 1 : 0) +
      (brightness == Mc.unknown ? 1 : 0) +
      (sealedFixture == Mc.unknown ? 1 : 0) +
      (dimmer == Mc.unknown ? 1 : 0);

  Map<String, dynamic> toJson() => {
        'baseSize': baseSize,
        'colorTone': colorTone,
        'brightness': brightness,
        'sealedFixture': sealedFixture,
        'dimmer': dimmer,
      };

  factory ManualChecks.fromJson(Map<String, dynamic> json) => ManualChecks(
        baseSize: json['baseSize'] as String? ?? 'unknown',
        colorTone: json['colorTone'] as String? ?? 'unknown',
        brightness: json['brightness'] as String? ?? 'unknown',
        sealedFixture: json['sealedFixture'] as String? ?? 'unknown',
        dimmer: json['dimmer'] as String? ?? 'unknown',
      );
}

class EvidenceState {
  final String sessionId;
  final String itemType; // "bulb"
  bool fullViewCaptured;
  bool baseViewCaptured;
  bool labelViewCaptured;
  bool fixtureChecked;
  ManualChecks manualChecks;
  bool manualFallback; // 手動フォールバック有効時、写真エビデンス不足でもpurchaseResultへ

  EvidenceState({
    required this.sessionId,
    this.itemType = 'bulb',
    this.fullViewCaptured = false,
    this.baseViewCaptured = false,
    this.labelViewCaptured = false,
    this.fixtureChecked = false,
    ManualChecks? manualChecks,
    this.manualFallback = false,
  }) : manualChecks = manualChecks ?? ManualChecks();

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'itemType': itemType,
        'fullViewCaptured': fullViewCaptured,
        'baseViewCaptured': baseViewCaptured,
        'labelViewCaptured': labelViewCaptured,
        'fixtureChecked': fixtureChecked,
        'manualChecks': manualChecks.toJson(),
        'manualFallback': manualFallback,
      };

  factory EvidenceState.fromJson(Map<String, dynamic> json) => EvidenceState(
        sessionId: json['sessionId'] as String,
        itemType: json['itemType'] as String? ?? 'bulb',
        fullViewCaptured: json['fullViewCaptured'] as bool? ?? false,
        baseViewCaptured: json['baseViewCaptured'] as bool? ?? false,
        labelViewCaptured: json['labelViewCaptured'] as bool? ?? false,
        fixtureChecked: json['fixtureChecked'] as bool? ?? false,
        manualChecks: json['manualChecks'] != null
            ? ManualChecks.fromJson(json['manualChecks'] as Map<String, dynamic>)
            : ManualChecks(),
        manualFallback: json['manualFallback'] as bool? ?? false,
      );
}
