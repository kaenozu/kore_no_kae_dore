// lib/core/models/captured_image.dart
// 撮影された1枚の画像のメタデータ
// 画像の品質状態（ぼやけ・暗さ・遠さ）を含む
// 関連: classification_result.dart, capture_session.dart

class CapturedImage {
  final String id;
  final String sessionId;
  final String path;
  final String step;
  final DateTime createdAt;
  final bool blurry;
  final bool tooDark;
  final bool tooFar;

  CapturedImage({
    required this.id,
    required this.sessionId,
    required this.path,
    required this.step,
    required this.createdAt,
    this.blurry = false,
    this.tooDark = false,
    this.tooFar = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'path': path,
        'step': step,
        'createdAt': createdAt.toIso8601String(),
        'blurry': blurry,
        'tooDark': tooDark,
        'tooFar': tooFar,
      };

  factory CapturedImage.fromJson(Map<String, dynamic> json) => CapturedImage(
        id: json['id'] as String,
        sessionId: json['sessionId'] as String,
        path: json['path'] as String,
        step: json['step'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        blurry: json['blurry'] as bool? ?? false,
        tooDark: json['tooDark'] as bool? ?? false,
        tooFar: json['tooFar'] as bool? ?? false,
      );
}
