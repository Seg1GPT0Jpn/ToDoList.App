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

  test('穴埋めは、例文の中の形（過去形など）をそのまま書く', () {
    const c = VocabCard(
      id: '1',
      term: 'rise',
      meaning: '[動] 上がる',
      example: 'The price of gasoline rose again this month.',
    );
    expect(c.clozeAnswer, 'rose');
    expect(c.clozeHint, 'r＿＿＿（4文字）');
    expect(c.clozeMatches('rose'), isTrue);
    expect(c.clozeMatches(' Rose '), isTrue);
    // 元の形では正解にしない
    expect(c.clozeMatches('rise'), isFalse);
    const p = VocabCard(
      id: '2',
      term: 'look up to',
      meaning: '尊敬する',
      example: 'She looks up to her sister.',
    );
    expect(p.clozeMatches('looks  up to'), isTrue);
    expect(p.clozeMatches('look up to'), isFalse);
  });

  test("be の熟語は I'm などの短縮形でも穴埋めにでき、もとの形で書いてもよい", () {
    const c = VocabCard(
      id: '1',
      term: 'be used to ～ing',
      meaning: '～することに慣れている',
      example: "I'm used to getting up early.",
    );
    expect(c.hasExample, isTrue);
    expect(c.clozeAnswer, "'m used to getting");
    expect(c.clozeMatches("'m used to getting"), isTrue);
    expect(c.clozeMatches('am used to getting'), isTrue);
    expect(c.clozeMatches('be used to getting'), isFalse);
  });

  test('熟語の穴埋め：［ ］の言いかえ・( ) の省略・間に入る1語・A\'s', () {
    expect(
        VocabCard.clozeWord('Will you keep an eye on this baggage?',
            "keep an [one's] eye on ～"),
        'keep an eye on');
    expect(
        VocabCard.clozeWord('He is entirely dependent on his father.',
            'be dependent on [upon] ～'),
        'is entirely dependent on');
    expect(
        VocabCard.clozeWord(
            'It is never easy to make ends meet.', 'make (both) ends meet'),
        'make ends meet');
    expect(
        VocabCard.clozeWord(
            'She gets on my nerves with her complaints.', "get on A's nerves"),
        'gets on my nerves');
    expect(
        VocabCard.clozeWord(
            'Some facts were brought to light.', 'bring A to light'),
        'brought to light');
    expect(
        VocabCard.clozeWord(
            'Make sure your phone is switched off.', 'make sure that 節'),
        'Make sure');
    // 最後の to do は動詞1語だけ
    expect(
        VocabCard.clozeWord(
            "I don't want you to go out of your way to bring it.",
            "go out of one's way to do"),
        'go out of your way to bring');
    // 書いてあるとおりに見つかるときは、間に語を入れた形を探さない
    expect(VocabCard.clozeWord('Life is a journey.', 'look up to'), isNull);
  });
}
