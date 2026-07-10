// lib/core/models/match_level.dart
// 商品候補の信頼度レベル：型番一致、条件一致、AI推定、手動入力の4段階
// 購入前の注意度を明示することで「断定表現」を避ける
// 関連: purchase_result.dart, rule_engine.dart, purchase_result_screen.dart

enum MatchLevel {
  exactCode,        // JAN/バーコード/型番などコード一致
  compatibleSpec,  // 入力条件に合う候補
  inferred,         // AI推定を含む候補
  manualCandidate, // 手動入力から作った候補
}

extension MatchLevelLabel on MatchLevel {
  String get label {
    switch (this) {
      case MatchLevel.exactCode:
        return '型番・コード一致候補';
      case MatchLevel.compatibleSpec:
        return '条件一致候補';
      case MatchLevel.inferred:
        return 'AI推定候補';
      case MatchLevel.manualCandidate:
        return '手動入力候補';
    }
  }

  String get caution {
    switch (this) {
      case MatchLevel.exactCode:
        return '型番やコードが一致する候補です。購入前に販売ページの対応条件を確認してください。';
      case MatchLevel.compatibleSpec:
        return '入力された条件に合いそうな候補です。購入前に規格を確認してください。';
      case MatchLevel.inferred:
        return '写真からの推定を含みます。購入前に必ず現物・パッケージで確認してください。';
      case MatchLevel.manualCandidate:
        return '手動入力に基づく候補です。入力内容と商品ページを照合してください。';
    }
  }
}
