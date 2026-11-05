import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime(2026, 10, 18, 21);

  test('勉強の記録：日ごと・教科ごとに足し、1回は60分まで、古い日は消す', () {
    var log = StudyLog.empty
        .add('english',
            now: now,
            spent: const Duration(minutes: 12),
            answered: 20,
            correct: 15)
        .add('english',
            now: now,
            spent: const Duration(minutes: 8),
            answered: 10,
            correct: 10)
        .add('math', now: now, spent: const Duration(hours: 5));
    expect(log.on(now)['english']!.minutes, 20);
    expect(log.on(now)['english']!.answered, 30);
    expect(log.on(now)['math']!.minutes, 60);
    log = log.add('math',
        now: now.add(const Duration(days: 61)),
        spent: const Duration(minutes: 1));
    expect(log.on(now), isEmpty);
    final back = StudyLog.fromMap(log.toMap());
    expect(back.on(now.add(const Duration(days: 61)))['math']!.minutes, 1);
    expect(StudyLog.empty.add('x', now: now, spent: Duration.zero),
        same(StudyLog.empty));
  });

  test('つづりへ送る勉強時間：1日・1教科で1件、同じ ID に上書き', () {
    final log = StudyLog.empty
        .add('english', now: now, spent: const Duration(minutes: 10))
        .add('sea', now: now, spent: const Duration(minutes: 5))
        .add('math',
            now: now.subtract(const Duration(days: 1)),
            spent: const Duration(minutes: 30))
        .add('science', now: now, spent: const Duration(seconds: 30))
        .add('social',
            now: now.subtract(const Duration(days: 20)),
            spent: const Duration(minutes: 9));
    final s = TsuzuriLink.sessions(log, now: now);
    expect(s.keys, containsAll(['quest_2026-10-18_英語', 'quest_2026-10-17_数学']));
    expect(s['quest_2026-10-18_英語']!['minutes'], 15, reason: '英語と英文法はまとめる');
    expect(s.keys.any((k) => k.contains('理科')), isFalse, reason: '1分未満は送らない');
    expect(s.keys.any((k) => k.contains('社会')), isFalse, reason: '14日より前は送らない');
    expect(s['quest_2026-10-18_英語']!['memo'], 'つづりクエスト');
    expect(
        TsuzuriLink.staleSessions(
            ['quest_2026-10-18_英語', 'quest_2026-10-16_国語'], s),
        ['quest_2026-10-16_国語']);
  });

  test('成果：今日・1週間の合計と苦手な単元', () {
    final log = StudyLog.empty.add('english',
        now: now, spent: const Duration(minutes: 10), answered: 10, correct: 7);
    final r = TsuzuriLink.results(log, LearningRecord.empty, now: now);
    expect(r['today'], {'minutes': 10, 'answered': 10, 'correct': 7});
    expect((r['days'] as Map)['2026-10-18'], {
      '英語': {'minutes': 10, 'answered': 10, 'correct': 7}
    });
    expect(r['weak'], isEmpty);
  });

  test('つづりのテスト予定を読む：日付順、過ぎたものと壊れたものは除く', () {
    final items = TsuzuriLink.parseUpcoming({
      'items': [
        {
          'date': '2026-10-22',
          'title': '数学Ⅰ 小テスト',
          'kind': '小テスト',
          'isTest': true,
          'subject': '数学Ⅰ'
        },
        {
          'date': '2026-10-19',
          'title': 'ECⅠ LEAP単語テスト',
          'kind': '小テスト',
          'isTest': true,
          'subject': 'ECⅠ',
          'detail': '1201〜1300',
          'period': 2
        },
        {'date': '2026-10-10', 'title': '過ぎた', 'kind': '小テスト'},
        {'title': '日付なし'},
        'こわれた',
      ],
    }, today: now);
    expect(items.map((i) => i.title), ['ECⅠ LEAP単語テスト', '数学Ⅰ 小テスト']);
    expect(items.first.detail, '1201〜1300');
    expect(items.first.worldId, 'english');
    expect(items.first.daysFrom(now), 1);
    expect(items.last.worldId, 'math');
    expect(TsuzuriLink.parseUpcoming(null, today: now), isEmpty);
  });

  test('つづりの科目名から教科を推し量る', () {
    expect(TsuzuriLink.worldFor('論表Ⅰ'), 'english');
    expect(TsuzuriLink.worldFor('言語文化'), 'japanese');
    expect(TsuzuriLink.worldFor('化学基礎'), 'science');
    expect(TsuzuriLink.worldFor('地理総合'), 'social');
    expect(TsuzuriLink.worldFor('情報Ⅰ'), 'information');
    expect(TsuzuriLink.worldFor('体育'), isNull);
  });

  test('成果：教科ごとの1週間（英語と英文法はまとめる）とテストごとの対策時間', () {
    final log = StudyLog.empty
        .add('english',
            now: now,
            spent: const Duration(minutes: 10),
            answered: 10,
            correct: 8)
        .add('sea',
            now: now,
            spent: const Duration(minutes: 5),
            answered: 5,
            correct: 5)
        .add('math',
            now: now.subtract(const Duration(days: 3)),
            spent: const Duration(minutes: 20));
    final r = TsuzuriLink.results(log, LearningRecord.empty,
        now: now, prepMinutes: {'2026-10-19|ECⅠ 小テスト': 12, 'x': 0});
    expect((r['subjects'] as Map)['英語'],
        {'minutes': 15, 'answered': 15, 'correct': 13});
    expect((r['subjects'] as Map)['数学'],
        {'minutes': 20, 'answered': 0, 'correct': 0});
    expect((r['days'] as Map)['2026-10-18']['英語']['minutes'], 15);
    expect(r['tests'], {'2026-10-19|ECⅠ 小テスト': 12});
  });

  test('範囲の番号・時間割・目標を読む', () {
    expect(TsuzuriLink.numberRange('1201〜1300'), (1201, 1300));
    expect(TsuzuriLink.numberRange('No.1300-1201'), (1201, 1300));
    expect(TsuzuriLink.numberRange('p.20'), isNull);
    expect(TsuzuriLink.numberRange(null), isNull);
    final lessons = TsuzuriLink.parseLessons({
      'lessons': {
        '2026-10-19': [
          {'period': 2, 'subject': '数学Ⅰ'},
          {'period': 1, 'subject': 'ECⅠ'},
          {'period': 3},
        ],
      },
    });
    expect(lessons['2026-10-19']!.map((l) => l.subject), ['ECⅠ', '数学Ⅰ']);
    expect(lessons['2026-10-19']!.first.worldId, 'english');
    final goals = TsuzuriLink.parseGoals([
      {'title': '英検', 'type': 'none'},
      {
        'title': '数学の点数',
        'type': 'number',
        'current': 60,
        'target': 80,
        'unit': '点',
        'dueDate': '2026-11-01'
      },
      {'title': '今月30時間', 'type': 'studyTime', 'current': 12.5, 'target': 30},
      {'title': 'おわった', 'type': 'studyTime', 'achieved': true},
    ]);
    expect(goals.map((g) => g.title), ['今月30時間', '数学の点数']);
    expect(goals.first.label, '12.5/30時間');
    expect(goals.last.label, '60/80点');
    expect(goals.last.ratio, 0.75);
    final t = TsuzuriUpcoming(
        date: DateTime(2026, 10, 19),
        title: 'ECⅠ 小テスト',
        kindLabel: '小テスト',
        isTest: true);
    expect(TsuzuriLink.testKey(t), '2026-10-19|ECⅠ 小テスト');
  });
}
