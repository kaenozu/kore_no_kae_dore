// lib/core/rules/search_keyword_generator.dart
// 検索ワード生成ロジック
// EvidenceStateの内容からECサイトで使える検索ワードを生成する
// 関連: rule_engine.dart

class SearchKeywordGenerator {
  static List<String> generate({
    required String baseSize,
    required String brightness,
    required String colorTone,
    required String sealedFixture,
    required String dimmer,
  }) {
    final parts = <String>[];

    // 口金
    if (baseSize.startsWith('e26')) {
      parts.add('E26');
    } else if (baseSize.startsWith('e17')) {
      parts.add('E17');
    } else {
      parts.add('口金');
    }

    parts.add('LED電球');

    // 明るさ
    if (brightness != 'unknown') {
      parts.add('$brightness形相当');
    }

    // 光色
    switch (colorTone) {
      case 'bulb_color':
        parts.add('電球色');
        break;
      case 'neutral_white':
        parts.add('昼白色');
        break;
      case 'daylight':
        parts.add('昼光色');
        break;
    }

    // 密閉器具対応
    if (sealedFixture == 'yes') {
      parts.add('密閉器具対応');
    }

    // 調光器対応
    if (dimmer == 'yes') {
      parts.add('調光器対応');
    }

    return [parts.join(' ')];
  }
}
