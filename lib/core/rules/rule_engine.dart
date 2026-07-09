// lib/core/rules/rule_engine.dart
// ルールエンジン：EvidenceStateから次の指示・手動確認・購入結果を生成する
// このモジュールが「写真1枚で断定しない」の中核ロジックを担う
// 関連: evidence_state.dart, rule_engine_output.dart

import '../models/evidence_state.dart';
import '../models/rule_engine_output.dart';

class RuleEngine {
  /// EvidenceStateからルールエンジン出力を生成する
  RuleEngineOutput process(EvidenceState evidence, {int failedAttempts = 0}) {
    if (failedAttempts >= 3) {
      return RuleEngineOutput(
        type: 'manual_check',
        title: '撮影がうまくいきませんでした',
        message: '写真での確認が難しいようです。手動で項目を確認してください。',
        warnings: ['写真での判定は参考値です'],
      );
    }

    if (!evidence.fullViewCaptured) {
      return RuleEngineOutput(
        type: 'next_instruction',
        title: '電球全体を撮影してください',
        message: '電球全体が写るように、電球から20〜30cm離れて撮影しましょう。',
        requiredStep: 'full_view',
        warnings: ['写真一枚で商品を断定するものではありません'],
      );
    }

    if (!evidence.baseViewCaptured) {
      return RuleEngineOutput(
        type: 'next_instruction',
        title: '口金部分を撮影してください',
        message: '口金（金属部分）が画面いっぱいになるように近づけて撮影しましょう。'
            '口金のサイズ（E26/E17など）を確認するために重要です。',
        requiredStep: 'base_view',
        warnings: ['口金サイズは実際に測って確認することをおすすめします'],
      );
    }

    if (!evidence.labelViewCaptured) {
      return RuleEngineOutput(
        type: 'next_instruction',
        title: '側面の印字を撮影してください',
        message: '電球の側面にある型番や仕様の印字を撮影しましょう。'
            '明るさや光色の手がかりになります。',
        requiredStep: 'label_view',
        warnings: ['印字が読めない場合は手動で確認できます'],
      );
    }

    if (!evidence.fixtureChecked) {
      return RuleEngineOutput(
        type: 'next_instruction',
        title: '照明器具の状態を確認してください',
        message: '密閉器具かどうか、調光スイッチがあるかを確認しましょう。',
        requiredStep: 'fixture_check',
        warnings: ['器具の対応状況は購入前に必ずご確認ください'],
      );
    }

    if (!evidence.manualChecks.isComplete) {
      return RuleEngineOutput(
        type: 'manual_check',
        title: '残りの項目を確認してください',
        message: '以下の情報が不足しています。わかる範囲で答えてください。',
        warnings: ['写真での判定は参考値です'],
      );
    }

    return _generatePurchaseResult(evidence);
  }

  RuleEngineOutput handlePoorQuality(String reason) {
    String title;
    String message;

    switch (reason) {
      case 'too_dark':
        title = '暗すぎます';
        message = '照明をつけるか、明るい場所で撮り直してください。';
        break;
      case 'blurry':
        title = 'ピントが合っていません';
        message = 'カメラを安定させ、ピントを合わせてから撮り直してください。';
        break;
      case 'too_far':
        title = '遠すぎます';
        message = 'もっと電球に近づいて撮り直してください。';
        break;
      default:
        title = '撮り直してください';
        message = 'もう一度、電球をしっかり撮影してください。';
    }

    return RuleEngineOutput(
      type: 'next_instruction',
      title: title,
      message: message,
      warnings: ['写真一枚で商品を断定するものではありません'],
    );
  }

  RuleEngineOutput _generatePurchaseResult(EvidenceState evidence) {
    return RuleEngineOutput(
      type: 'purchase_result',
      title: '購入候補',
      message: '写真と確認内容から、以下の商品が候補です。'
          '購入前に現物やパッケージで必ずご確認ください。',
      warnings: [
        'これは「候補」であり、確定的な商品特定ではありません',
        '購入前に口金サイズを実物で確認してください',
        'この情報は参考用です。メーカーや販売店の情報を優先してください',
      ],
    );
  }
}
