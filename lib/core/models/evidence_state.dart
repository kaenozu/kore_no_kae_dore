// lib/core/models/evidence_state.dart
// セッション全体の証拠（エビデンス）状態
// どの角度が撮影済みか、手動確認の値は何かを保持する
// 関連: rule_engine.dart, manual_check_screen.dart

class ManualChecks {
  String baseSize; // "unknown" | "e26_candidate" | "e17_candidate" | "user_selected_e26" | "user_selected_e17"
  String colorTone; // "unknown" | "bulb_color" | "neutral_white" | "daylight"
  String brightness; // "unknown" | "40" | "60" | "100"
  String sealedFixture; // "unknown" | "yes" | "no"
  String dimmer; // "unknown" | "yes" | "no"

  ManualChecks({
    this.baseSize = 'unknown',
    this.colorTone = 'unknown',
    this.brightness = 'unknown',
    this.sealedFixture = 'unknown',
    this.dimmer = 'unknown',
  });

  bool get isComplete =>
      baseSize != 'unknown' &&
      colorTone != 'unknown' &&
      brightness != 'unknown' &&
      sealedFixture != 'unknown' &&
      dimmer != 'unknown';

  int get unknownCount =>
      (baseSize == 'unknown' ? 1 : 0) +
      (colorTone == 'unknown' ? 1 : 0) +
      (brightness == 'unknown' ? 1 : 0) +
      (sealedFixture == 'unknown' ? 1 : 0) +
      (dimmer == 'unknown' ? 1 : 0);

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

  EvidenceState({
    required this.sessionId,
    this.itemType = 'bulb',
    this.fullViewCaptured = false,
    this.baseViewCaptured = false,
    this.labelViewCaptured = false,
    this.fixtureChecked = false,
    ManualChecks? manualChecks,
  }) : manualChecks = manualChecks ?? ManualChecks();

  bool get hasPoorQuality =>
      manualChecks.baseSize == 'unknown' &&
      manualChecks.colorTone == 'unknown' &&
      manualChecks.brightness == 'unknown';

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'itemType': itemType,
        'fullViewCaptured': fullViewCaptured,
        'baseViewCaptured': baseViewCaptured,
        'labelViewCaptured': labelViewCaptured,
        'fixtureChecked': fixtureChecked,
        'manualChecks': manualChecks.toJson(),
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
      );
}
