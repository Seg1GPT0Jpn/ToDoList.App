import 'dart:math';

import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

VocabBook _book({String title = 'LEAP', int n = 300}) => VocabBook(
      id: title.toLowerCase(),
      title: title,
      kind: VocabBookKind.protectedImport,
      cards: [
        for (var i = 1; i <= n; i++)
          VocabCard(id: 'w$i', number: i, term: 'word$i', meaning: '意味$i'),
      ],
    );

ClassTask _task({
  int from = 101,
  int to = 200,
  DateTime? date,
  ClassTaskKind kind = ClassTaskKind.quiz,
}) =>
    ClassTask(
      id: 't1',
      kind: kind,
      title: '第7回',
      bookKey: ClassBooks.normalize('LEAP'),
      bookTitle: 'LEAP',
      from: from,
      to: to,
      date: date ?? DateTime(2026, 10, 23),
    );

void main() {
  group('範囲', () {
    test('番号の範囲の単語だけを選ぶ（両端を含む）', () {
      final cards = _task().cardsIn(_book());
      expect(cards, hasLength(100));
      expect(cards.first.number, 101);
      expect(cards.last.number, 200);
    });

    test('試験日までの日数と準備期間（小テストは1週間前、定期テストは2週間前から）', () {
      final t = _task(date: DateTime(2026, 10, 23));
      expect(t.daysLeft(DateTime(2026, 10, 16, 21)), 7);
      expect(t.active(DateTime(2026, 10, 16)), isTrue);
      expect(t.active(DateTime(2026, 10, 15)), isFalse);
      expect(t.active(DateTime(2026, 10, 23, 23)), isTrue);
      expect(t.over(DateTime(2026, 10, 24)), isTrue);
      final e = _task(date: DateTime(2026, 11, 24), kind: ClassTaskKind.exam);
      expect(e.prepStart, DateTime(2026, 11, 10));
    });

    test('保存して読み直せる。壊れたデータは読み飛ばす', () {
      final t = _task();
      final again = ClassTask.fromMap(t.toMap())!;
      expect(again.from, 101);
      expect(again.date, DateTime(2026, 10, 23));
      expect(again.kind, ClassTaskKind.quiz);
      expect(ClassTask.fromMap({'id': 'x'}), isNull);
      expect(ClassTask.fromMap({...t.toMap(), 'from': 300, 'to': 1}), isNull);
      expect(ClassTask.fromMap({...t.toMap(), 'date': '2026-02-30'}), isNull);
      expect(ClassTask.fromMap('こわれた'), isNull);
    });

    test('単語帳は名前で照合する（空白・大文字小文字・中点を無視）', () {
      final t = _task();
      expect(ClassBooks.match(t, [_book(title: 'leap')])?.title, 'leap');
      expect(ClassBooks.match(t, [_book(title: 'L E A P')]), isNotNull);
      expect(ClassBooks.match(t, [_book(title: 'ターゲット1900')]), isNull);
    });
  });

  group('クラスルーム', () {
    test('6ケタのコード。0で始まらない', () {
      final r = Random(1);
      for (var i = 0; i < 200; i++) {
        final c = Classroom.newCode(r);
        expect(Classroom.validCode(c), isTrue, reason: c);
      }
      expect(Classroom.validCode('12345'), isFalse);
      expect(Classroom.validCode('012345'), isFalse);
      expect(Classroom.validCode('12a456'), isFalse);
    });

    test('保存して読み直せる。壊れた範囲は除く', () {
      final room = Classroom(
        code: '123456',
        name: '1年英語',
        ownerId: 'a',
        ownerName: 'あ',
        members: const {'a': 'あ', 'b': 'い'},
        tasks: [_task()],
      );
      final again = Classroom.fromMap('123456', {
        ...room.toMap(),
        'tasks': [...room.toMap()['tasks']! as List, 'こわれた'],
      });
      expect(again.members, {'a': 'あ', 'b': 'い'});
      expect(again.tasks.single.id, 't1');
      expect(again.isOwner('a'), isTrue);
      expect(again.isMember('b'), isTrue);
      expect(again.isMember('c'), isFalse);
    });

    test('名前は前後の空白を取り、長すぎれば切る', () {
      expect(Classroom.cleanName('  1年  英語 '), '1年 英語');
      expect(Classroom.cleanName(''), 'クラス');
      expect(Classroom.cleanName('あ' * 50).length, Classroom.maxName);
    });
  });

  group('今日の分', () {
    final book = _book();
    final task = _task(date: DateTime(2026, 10, 23));
    final cards = task.cardsIn(book);

    test('まだの単語を、前日までの日数で割って出す', () {
      final p = BookProgress();
      // 7日前：前日は最終チェックなので、6日で100語 → 1日17語
      final today = ClassPlanner.today(task, cards, p, DateTime(2026, 10, 16));
      expect(today.where((t) => t.isNew), hasLength(17));
    });

    test('今日すでに覚えた分は差し引く', () {
      final p = BookProgress();
      final now = DateTime(2026, 10, 16, 9);
      for (final c in cards.take(10)) {
        p.record(
          cardId: c.id,
          skill: VocabSkill.meaning,
          rating: Rating.good,
          now: now,
          isNew: true,
        );
      }
      final today = ClassPlanner.today(task, cards, p, now);
      expect(today.where((t) => t.isNew), hasLength(7));
    });

    test('前日と当日は、範囲の全部を苦手なものから（最終チェック）', () {
      final p = BookProgress();
      final check = ClassPlanner.today(task, cards, p, DateTime(2026, 10, 22));
      expect(check, hasLength(100));
      expect(check.every((t) => t.mode == VocabMode.choiceMeaning), isTrue);
    });

    test('覚えた単語の数', () {
      final p = BookProgress();
      final now = DateTime(2026, 10, 16);
      for (final c in cards.take(30)) {
        p.record(
          cardId: c.id,
          skill: VocabSkill.meaning,
          rating: Rating.good,
          now: now,
        );
      }
      expect(ClassPlanner.learnedCount(cards, p, now), 30);
    });
  });

  group('共闘ボス', () {
    test('体力は 範囲の単語数×人数。少人数でも倒せる', () {
      final t = _task();
      expect(ClassBoss.maxHp(t, 3), 300);
      expect(ClassBoss.maxHp(t, 0), 100);
      expect(ClassBoss.hpLeft(t, 3, 120), 180);
      expect(ClassBoss.hpLeft(t, 3, 999), 0);
    });
  });
}
