import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

void main() {
  group('暗記カード', () {
    for (final info in TermDecks.all) {
      final file = File('assets/cards/${info.id}.json');
      test('${info.title}：すべてのカードに意味・関連語・豆知識がある', () {
        if (!file.existsSync()) return; // まだ用意していない束
        final deck = TermDeck.fromJson(
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
        );
        expect(deck.id, info.id);
        expect(deck.worldId, info.worldId);
        expect(deck.cards.length, greaterThan(100));
        final terms = <String>{};
        for (final c in deck.cards) {
          expect(terms.add(c.term), isTrue, reason: '重複: ${c.term}');
          expect(c.meaning, isNotEmpty, reason: c.term);
          expect(c.related, isNotEmpty, reason: c.term);
          expect(c.trivia, isNotEmpty, reason: c.term);
        }
        final qs = TermQuizBuilder(random: Random(1)).build(deck, count: 30);
        expect(qs, hasLength(30));
        for (final q in qs) {
          expect(q.choices.toSet(), hasLength(4));
          expect(q.answerIndex, inInclusiveRange(0, 3));
        }
      });
    }

    test('理科・社会のワールドといっしょに解放される', () {
      expect(TermDecks.of('science').map((d) => d.id), contains('physics'));
      expect(TermDecks.of('social').map((d) => d.id), contains('politics'));
      expect(TermDecks.of('english'), isEmpty);
    });
  });

  test('単語帳から4択問題を作る（英→日・日→英）', () {
    final book = VocabBook(
      id: 'test',
      title: 'テスト',
      kind: VocabBookKind.custom,
      cards: [
        for (var i = 0; i < 10; i++)
          VocabCard(id: '$i', term: 'word$i', meaning: '[名] 意味$i'),
      ],
    );
    final b = VocabQuizBuilder(random: Random(2));
    final en = b.build(book, enToJa: true, count: 5);
    expect(en, hasLength(5));
    expect(en.first.prompt, contains('word'));
    expect(en.first.choices[en.first.answerIndex], startsWith('意味'));
    final ja = b.build(book, enToJa: false, count: 20);
    expect(ja, hasLength(10));
    expect(ja.first.choices.every((c) => c.startsWith('word')), isTrue);
  });
}
