// test/features/conversation/prompts/fixed_prompt_provider_test.dart
// FixedPromptProviderの単体テスト
// 各プロンプトが期待通りの構造と内容を返すことを確認
// 関連: lib/features/conversation/prompts/fixed_prompt_provider.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:kore_no_kae_dore/core/models/evidence_state.dart';
import 'package:kore_no_kae_dore/features/conversation/models/conversation_turn.dart';
import 'package:kore_no_kae_dore/features/conversation/prompts/fixed_prompt_provider.dart';

void main() {
  late FixedPromptProvider provider;

  setUp(() {
    provider = FixedPromptProvider();
  });

  group('FixedPromptProvider', () {
    test('introduction() has correct message and start action', () {
      final turn = provider.introduction();

      expect(turn.role, ConversationRole.agent);
      expect(turn.message, contains('電球の買い替え'));
      expect(turn.message, contains('保証しません'));
      expect(turn.actions.length, 1);
      expect(turn.actions[0].type, PromptActionType.continueAction);
      expect(turn.actions[0].label, '始める');
    });

    test('intentSelection() has two choices with correct labels', () {
      final turn = provider.intentSelection();

      expect(turn.role, ConversationRole.agent);
      expect(turn.type, ConversationTurnType.choice);
      expect(turn.purpose, '目的の選択');
      expect(turn.actions.length, 2);
      expect(turn.actions[0].type, PromptActionType.selectChoice);
      expect(turn.actions[0].label, '同じ電球を探したい');
      expect(turn.actions[0].value, 'find_same');
      expect(turn.actions[1].label, '条件だけ確認したい');
      expect(turn.actions[1].value, 'check_spec');
    });

    test(
      'manualCheck() for baseSize includes E26/E17 options plus "分からない"',
      () {
        final turn = provider.manualCheck('baseSize');

        expect(turn.role, ConversationRole.agent);
        expect(turn.type, ConversationTurnType.choice);
        expect(turn.purpose, '口金サイズの確認');
        expect(turn.actions.length, 3);
        expect(turn.actions[0].label, 'E26');
        expect(turn.actions[0].value, Mc.userSelectedE26);
        expect(turn.actions[0].fieldKey, 'baseSize');
        expect(turn.actions[1].label, 'E17');
        expect(turn.actions[1].value, Mc.userSelectedE17);
        expect(turn.actions[1].fieldKey, 'baseSize');
        expect(turn.actions[2].label, '分からない');
        expect(turn.actions[2].value, Mc.userSkipped);
        expect(turn.actions[2].fieldKey, 'baseSize');
      },
    );
  });
}
