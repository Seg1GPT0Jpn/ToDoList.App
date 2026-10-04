import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

const _leap = '''No\t単語\t意味
1\tagree\t[自] ①賛成する ②（主語の中で）意見が一致する
2\toppose\t[他] ～に反対する
3\tadvise\t[他] ～に忠告する
4\ttip\t[名] ①助言，ヒント ②チップ
5\tdiscuss\t[他] ①～について話し合う，議論する
1399\tafterward(s)\t[副] ①（文頭で）その後
1400\ton behalf of ～\t[熟] ①～を代表して''';

const _step = '''大学受験STEP
単語一覧
1
rise
■動詞：上がる；起きる；生じる　■名詞：上昇
›

2
raise
■動詞：～を上げる；～を育てる；(お金を)集める
›

3
lie
■動詞：横たわる、(無生物が)ある；嘘をつく　■名詞：嘘
›
''';

void main() {
  group('単語帳の読み取り', () {
    test('LEAP の形（番号・単語・意味のタブ区切り、見出し行つき）', () {
      final cards = VocabParser.parse(_leap);
      expect(cards.length, 7);
      expect(cards.first.term, 'agree');
      expect(cards.first.number, 1);
      expect(cards.first.id, '1');
      expect(cards.first.shortMeaning, '賛成する');
      expect(
          cards[5].acceptedSpellings, containsAll(['afterward', 'afterwards']));
      expect(cards[6].spellingMatches('on behalf of'), isTrue);
    });

    test('STEP の形（番号・単語・■意味が縦に並ぶ）', () {
      final cards = VocabParser.parse(_step);
      expect([for (final c in cards) c.term], ['rise', 'raise', 'lie']);
      expect(cards.first.number, 1);
      expect(cards.first.meaning, '[動] 上がる；起きる；生じる [名] 上昇');
      expect(cards.first.partOfSpeech, '動');
      expect(cards.first.shortMeaning, '上がる；起きる；生じる');
    });

    test('CSV（見出しつき・例文と発音つき）', () {
      final cards = VocabParser.parse(
        'term,meaning,pron,example,translation\n'
        'abandon,～を捨てる,/əˈbændən/,"The soldiers abandoned the town.",兵士たちは町を捨てた。\n',
      );
      expect(cards.single.pron, '/əˈbændən/');
      expect(cards.single.hasExample, isTrue);
      expect(VocabCard.clozeOf(cards.single.example, 'abandon'),
          'The soldiers ＿＿＿＿ the town.');
    });

    test('取り込み直すと、同じ単語は空いている項目だけ埋まる', () {
      final book = VocabBook(
        id: 'b',
        title: 'b',
        kind: VocabBookKind.custom,
        cards: VocabParser.parse(_leap),
      );
      final r = book.merge([
        const VocabCard(
            id: 'x', term: 'agree', meaning: '別', example: 'I agree.'),
        const VocabCard(id: '1', term: 'brand', meaning: '新しい'),
      ]);
      expect(r.added, 1);
      expect(r.updated, 1);
      expect(book.card('1')!.meaning, startsWith('[自]'));
      expect(book.card('1')!.example, 'I agree.');
      expect(book.cards.last.id, '1_', reason: 'ID がかぶらない');
    });
  });

  group('FSRS', () {
    const f = Fsrs();
    final t0 = DateTime(2026, 4, 1, 9);

    test('評価が良いほど次の間隔は長く、「忘れた」は10分後にもう一度', () {
      final p = f.preview(null, t0);
      expect(p[Rating.again], Fsrs.relearnDelay);
      expect(p[Rating.hard]! < p[Rating.good]!, isTrue);
      expect(p[Rating.good]! < p[Rating.easy]!, isTrue);
    });

    test('思い出すたびに安定度が伸び、忘れると縮む', () {
      var s = f.first(Rating.good, t0);
      final intervals = <int>[];
      var t = t0;
      for (var i = 0; i < 3; i++) {
        t = s.due;
        s = f.review(s, Rating.good, t);
        intervals.add(s.due.difference(t).inDays);
      }
      for (var i = 1; i < intervals.length; i++) {
        expect(intervals[i], greaterThan(intervals[i - 1]));
      }
      final lapse = f.review(s, Rating.again, s.due);
      expect(lapse.stability, lessThan(s.stability));
      expect(lapse.lapses, 1);
      expect(lapse.streak, 0);
      // 保存して読み直しても同じ
      final back = MemoryState.fromJson(lapse.toJson());
      expect(back.due, lapse.due);
      expect(back.lapses, 1);
    });

    test('時間がたつほど思い出せる確率は下がる（安定度の日数で90%）', () {
      expect(Fsrs.retrievability(0, 10), closeTo(1, 1e-9));
      expect(Fsrs.retrievability(10, 10), closeTo(0.9, 1e-3));
      expect(Fsrs.retrievability(30, 10), lessThan(0.9));
    });
  });

  group('熟練度と今日の学習', () {
    final t0 = DateTime(2026, 4, 1, 9);
    VocabBook book() => VocabBook(
          id: 'b',
          title: 'b',
          kind: VocabBookKind.custom,
          cards: [
            ...VocabParser.parse(_leap),
            const VocabCard(id: 'a1', term: 'acquire', meaning: '[他] 身につける'),
            const VocabCard(id: 'a2', term: 'require', meaning: '[他] 必要とする'),
            const VocabCard(id: 'e1', term: 'affect', meaning: '[他] 影響する'),
            const VocabCard(id: 'e2', term: 'effect', meaning: '[名] 効果'),
          ],
        );

    test('1回正解しただけでは習得にならない。力ごとに別々に測る', () {
      final p = BookProgress();
      for (var i = 0; i < 3; i++) {
        p.record(
            cardId: '1',
            skill: VocabSkill.meaning,
            rating: Rating.good,
            now: t0.add(Duration(days: i * 10)));
      }
      final c = p.cards['1']!;
      expect(c.mastered(VocabSkill.meaning), isTrue);
      expect(c.mastered(VocabSkill.spelling), isFalse);
      final now = t0.add(const Duration(days: 20));
      expect(c.mastery(VocabSkill.meaning, now), greaterThan(60));
      expect(c.mastery(VocabSkill.spelling, now), 0);
      expect(c.status(now), isNot(CardStatus.stable), reason: '日→英がまだ');
    });

    test('間違えた理由に合わせて、その力をすぐまた出す', () {
      final p = BookProgress();
      p.record(
          cardId: '1', skill: VocabSkill.meaning, rating: Rating.good, now: t0);
      p.record(
          cardId: '1',
          skill: VocabSkill.spelling,
          rating: Rating.good,
          now: t0);
      final later = t0.add(const Duration(days: 1));
      p.record(
        cardId: '1',
        skill: VocabSkill.meaning,
        rating: Rating.again,
        now: later,
        reason: MistakeReason.spelling,
      );
      final c = p.cards['1']!;
      expect(c.mistakes[MistakeReason.spelling], 1);
      expect(
          c.skills[VocabSkill.spelling]!.due
              .isAfter(later.add(const Duration(hours: 1))),
          isFalse);
      expect(c.status(later), CardStatus.weak);
    });

    test('今日の学習：忘れかけた順に復習、混同は比較問題、最後に新しい単語', () {
      final b = book();
      final p = BookProgress(newPerDay: 3);
      p.record(
          cardId: '1', skill: VocabSkill.meaning, rating: Rating.good, now: t0);
      p.record(
          cardId: 'a1',
          skill: VocabSkill.meaning,
          rating: Rating.good,
          now: t0);
      p.record(
        cardId: 'a1',
        skill: VocabSkill.meaning,
        rating: Rating.again,
        now: t0,
        reason: MistakeReason.confused,
        confusedWith: 'require',
      );
      final now = t0.add(const Duration(days: 30));
      final tasks = VocabPlanner.today(b, p, now, listening: false);
      expect(tasks.first.mode, VocabMode.choiceMeaning);
      expect(tasks.any((t) => t.cardId == 'a1' && t.mode == VocabMode.compare),
          isTrue);
      final news = tasks.where((t) => t.isNew).toList();
      expect(news.length, 3);
      expect(tasks.last.isNew, isTrue);
      // 意味を覚えた単語は、日→英も練習に入る
      expect(
          tasks.any((t) => t.cardId == '1' && t.mode == VocabMode.choiceTerm),
          isTrue);
    });

    test('似た単語を見つける', () {
      final b = book();
      expect(Confusables.similar('affect', 'effect'), isTrue);
      expect(Confusables.similar('acquire', 'require'), isTrue);
      expect(Confusables.similar('agree', 'oppose'), isFalse);
      expect(Confusables.of(b, b.card('a1')!).map((c) => c.term),
          contains('require'));
      final choices = VocabChoices.build(b, b.card('e1')!, VocabMode.compare);
      expect(choices, containsAll(['affect', 'effect']));
      expect(choices.length, 4);
    });

    test('学習記録は保存して読み直せる。連続日数も数える', () {
      final p = BookProgress(newPerDay: 7);
      for (var d = 0; d < 3; d++) {
        p.record(
          cardId: '1',
          skill: VocabSkill.meaning,
          rating: Rating.good,
          now: t0.add(Duration(days: d)),
          spent: const Duration(seconds: 5),
        );
      }
      final back = BookProgress.fromJson(p.toJson());
      expect(back.newPerDay, 7);
      expect(back.cards['1']!.answers[VocabSkill.meaning], (3, 3));
      expect(back.streak(t0.add(const Duration(days: 2))), 3);
      expect(back.today(t0).seconds, 5);
    });

    test('形式を選んだ練習は、問題数を選べて全部一気にもできる', () {
      final cards = [
        for (var i = 1; i <= 120; i++)
          VocabCard(id: '$i', number: i, term: 'w$i', meaning: 'm$i'),
      ];
      expect(VocabPlanner.drill(cards, VocabMode.spelling).length, 20);
      expect(
          VocabPlanner.drill(cards, VocabMode.spelling, count: 50).length, 50);
      final all = VocabPlanner.drill(
        cards,
        VocabMode.flashcard,
        count: null,
        shuffle: false,
      );
      expect(all.length, 120);
      expect(all.first.cardId, '1');
      expect(all.last.cardId, '120');
    });

    test('週ごとのコース', () {
      final b = VocabBook(
        id: 'b',
        title: 'b',
        kind: VocabBookKind.custom,
        cards: [
          for (var i = 1; i <= 250; i++)
            VocabCard(id: '$i', number: i, term: 'w$i', meaning: 'm$i')
        ],
      );
      final w = VocabCourse.weeks(b);
      expect(w.length, 3);
      expect(w.first.$1, 'Week 1（1〜100）');
      expect(w.last.$2.length, 50);
    });
  });
}
