import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

void main() {
  test('熟語の穴埋め：最初の語の活用と one\'s などの部分を許す', () {
    expect(VocabCard.clozeWord('She looks up to her sister.', 'look up to'),
        'looks up to');
    expect(
        VocabCard.clozeWord(
            'He made up his mind to study abroad.', 'make up one\'s mind'),
        'made up his mind'); // 不規則な活用も見つける
    expect(
        VocabCard.clozeWord(
            'She makes up her mind quickly.', 'make up one\'s mind'),
        'makes up her mind');
    expect(
        VocabCard.clozeWord(
            'Don\'t take it for granted.', 'take A for granted'),
        'take it for granted');
  });

  test('豆知識は保存して読み戻せる', () {
    const c = VocabCard(id: '1', term: 'agree', meaning: '賛成する', note: '語源');
    expect(VocabCard.fromJson(c.toJson()).note, '語源');
    expect(
        VocabCard.fromJson(
                const VocabCard(id: '1', term: 'a', meaning: 'b').toJson())
            .note,
        '');
  });

  test('穴埋め：不規則動詞と、目的語をはさむ熟語', () {
    expect(VocabCard.clozeWord('A bee stung me.', 'sting'), 'stung');
    expect(VocabCard.clozeWord('The thugs roughed him up.', 'rough up'),
        'roughed him up');
    expect(VocabCard.clozeWord('She is akin to her aunt.', 'be akin to'),
        'is akin to');
  });
}
