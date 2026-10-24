import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

TermDeck _load(String id) => TermDeck.fromJson(
      jsonDecode(File('assets/cards/$id.json').readAsStringSync())
          as Map<String, dynamic>,
    );

void main() {
  const deck = TermDeck(
    id: 'test',
    worldId: 'information',
    title: 'テスト',
    cards: [
      TermCard(
          term: 'TCP/IP',
          meaning: 'インターネットのプロトコル群',
          related: ['TCP'],
          trivia: 'a',
          section: '通信'),
      TermCard(
          term: 'TCP',
          meaning: '確認しながら送るプロトコル',
          related: ['UDP'],
          trivia: 'b',
          section: '通信'),
      TermCard(
          term: 'UDP',
          meaning: '確認を省くプロトコル',
          related: ['TCP'],
          trivia: 'c',
          section: '通信'),
      TermCard(
          term: 'キロバイト（KB）',
          meaning: '約1000バイト',
          related: ['バイト'],
          trivia: 'd',
          section: '単位'),
      TermCard(
          term: '艮',
          reading: 'うしとら',
          meaning: '北東',
          related: ['巽'],
          trivia: 'e',
          section: '単位'),
      TermCard(
          term: '猫に小判',
          meaning: '価値がわからない',
          related: ['豚に真珠'],
          trivia: 'f',
          section: '単位'),
      TermCard(
          term: '豚に真珠',
          meaning: '価値がわからない',
          related: ['猫に小判'],
          trivia: 'g',
          section: '単位'),
    ],
  );

  test('暗記カードを単語帳の形にする（ID は用語・章・読み・豆知識）', () {
    final b = deck.toBook();
    expect(b.id, 'cards_test');
    expect(b.isTerms, isTrue);
    expect(b.worldId, 'information');
    expect(b.unit, '枚');
    expect(b.cards.first.id, 'TCP/IP');
    expect(b.cards.first.group, '通信');
    expect(b.card('艮')!.pron, 'うしとら');
    expect(b.card('TCP')!.note, contains('関連：UDP'));
  });

  test('用語を書く：全角半角・カタカナ・読み・かっこの中でもよい。ほかのカードの用語はだめ', () {
    final b = deck.toBook();
    final tcpip = b.card('TCP/IP')!;
    expect(b.writingMatches(tcpip, 'ＴＣＰ／ＩＰ'), isTrue);
    expect(b.writingMatches(tcpip, 'tcp/ip'), isTrue);
    expect(b.writingMatches(tcpip, 'TCP'), isFalse, reason: '別のカード');
    final kb = b.card('キロバイト（KB）')!;
    expect(b.writingMatches(kb, 'KB'), isTrue);
    expect(b.writingMatches(kb, 'きろばいと'), isTrue);
    expect(b.writingMatches(kb, 'キロバイト'), isTrue);
    final ushi = b.card('艮')!;
    expect(b.writingMatches(ushi, 'ウシトラ'), isTrue);
    expect(b.writingMatches(ushi, '巽'), isFalse);
    // 説明が同じカードの用語も正解
    expect(b.writingMatches(b.card('猫に小判')!, '豚に真珠'), isTrue);
    expect(b.writingMatches(tcpip, ''), isFalse);
    expect(tcpip.writingHint, '「T」で始まる6文字');
    expect(kb.writingHint, '「キ」で始まる5文字');
  });

  test('暗記カードでは発音・例文の形式を出さず、今日の最適学習にも入れない', () {
    final b = deck.toBook();
    expect(VocabMode.of(b), isNot(contains(VocabMode.listening)));
    expect(VocabMode.of(b), isNot(contains(VocabMode.cloze)));
    expect(VocabSkill.of(b),
        [VocabSkill.meaning, VocabSkill.recall, VocabSkill.spelling]);
    expect(VocabMode.spelling.labelOf(true), '用語を書く');
    expect(MistakeReason.of(b, b.cards.first),
        isNot(contains(MistakeReason.pronunciation)));

    final p = BookProgress();
    final now = DateTime(2026, 10, 1);
    for (final c in b.cards) {
      for (var i = 0; i < 3; i++) {
        p.record(
            cardId: c.id,
            skill: VocabSkill.meaning,
            rating: Rating.good,
            now: now.add(Duration(days: i * 3)));
      }
    }
    final later = now.add(const Duration(days: 60));
    final tasks = VocabPlanner.today(b, p, later);
    expect(tasks, isNotEmpty);
    expect(
        tasks.any(
            (t) => t.mode == VocabMode.listening || t.mode == VocabMode.cloze),
        isFalse);
  });

  test('4択：説明が同じカードは、まちがいの選択肢にしない。同じ章を先に出す', () {
    final b = deck.toBook();
    final neko = b.card('猫に小判')!;
    for (var i = 0; i < 30; i++) {
      final ch =
          VocabChoices.build(b, neko, VocabMode.choiceTerm, random: Random(i));
      expect(ch, contains('猫に小判'));
      expect(ch, isNot(contains('豚に真珠')));
      expect(ch.toSet(), hasLength(ch.length));
    }
    final udp = b.card('UDP')!;
    final ch =
        VocabChoices.build(b, udp, VocabMode.choiceMeaning, random: Random(1));
    expect(ch, contains('確認を省くプロトコル'));
    expect(ch, contains('確認しながら送るプロトコル'), reason: '同じ章');
  });

  test('日本語の似た用語（1字ちがい）', () {
    expect(Confusables.similar('荘園', '荘官'), isTrue);
    expect(Confusables.similar('酸化', '還元'), isFalse);
    expect(Confusables.similar('艮', '巽'), isFalse);
  });

  test('アプリに入っている暗記カードは、すべて単語帳の形で4択・書く問題が作れる', () {
    for (final info in TermDecks.all) {
      final b = _load(info.id).toBook();
      expect(b.cards.map((c) => c.id).toSet(), hasLength(b.cards.length),
          reason: info.id);
      final r = Random(3);
      for (final c in b.cards.take(40)) {
        for (final m in [VocabMode.choiceMeaning, VocabMode.choiceTerm]) {
          final ch = VocabChoices.build(b, c, m, random: r);
          expect(ch, hasLength(4), reason: '${info.id} ${c.term}');
          expect(ch.toSet(), hasLength(4), reason: '${info.id} ${c.term}');
        }
        expect(b.writingMatches(c, c.term), isTrue, reason: c.term);
      }
    }
  });

  test('国語・情報の暗記カードもワールドといっしょに使える', () {
    expect(
        TermDecks.of('japanese').map((d) => d.id),
        containsAll(
            ['kobun_words', 'classics', 'hyoron', 'kotowaza', 'bungakushi']));
    expect(TermDecks.of('information').map((d) => d.id), contains('info1'));
  });

  test('暗記カードの1戦：用語の問い方で作る', () {
    final b = _load('info1').toBook();
    final list = WordList(
      listId: 'vocab_${b.id}_quick',
      title: b.title,
      origin: QuestionOrigin.original,
      words: [
        for (final c in b.cards)
          WordEntry(term: c.term, meaning: c.meaning, number: c.number)
      ],
    );
    final qs = WordBattle.questionsFor(list, list.words[5],
        formats: const {WordFormat.meaning, WordFormat.recall},
        terms: true,
        random: Random(1));
    expect(qs, hasLength(2));
    expect(qs.map((q) => q.prompt), contains('次の説明にあてはまる用語は？'));
    final stage = WordBattle.stage(list, list.words.take(5).toList(), 10,
        worldId: 'information', name: '暗記カード：情報Ⅰ', noun: '用語');
    expect(stage.worldId, 'information');
    expect(stage.enemy.description, startsWith('用語「'));
  });
}
