import 'dart:convert';
import 'dart:io';

import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

final _sheet = MockSheet.fromJson(
  jsonEncode({
    'note': '配点は仮',
    'sections': [
      {
        'title': '大問1',
        'items': [
          {
            'id': '01',
            'l': '[01]',
            't': 'text',
            'p': 2,
            'a': ['オペレーティングシステム', 'OS'],
          },
          {
            'id': '02',
            't': 'choice',
            'p': 3,
            'o': ['1', '2', '3'],
            'a': ['2'],
          },
          {
            'id': '03',
            't': 'choice',
            'p': 3,
            'o': ['1', '2', '3', '4'],
            'a': ['1', '3'],
            'all': true,
          },
          {
            'id': '04',
            't': 'self',
            'p': 5,
            'a': ['模範解答'],
          },
        ],
      },
    ],
  }),
);

void main() {
  _bundled();
  test('解答用紙を読み、配点の合計を出す', () {
    expect(_sheet.items.length, 4);
    expect(_sheet.total, 13);
    expect(_sheet.item('01')!.label, '[01]');
    expect(_sheet.item('02')!.label, '02');
  });

  test('書き方のちがいをそろえて採点する', () {
    final i = _sheet.item('01')!;
    expect(i.check('ｏｓ'), isTrue);
    expect(i.check(' オペレーティング システム（OS）'), isFalse);
    expect(i.check('オペレーティング システム'), isTrue);
    expect(i.check(''), isFalse);
    expect(i.check(null), isFalse);
    const n = MockItem(
      id: 'n',
      label: 'n',
      type: MockItemType.text,
      points: 1,
      answers: ['-3'],
    );
    expect(n.check('−３'), isTrue);
    expect(n.check('3'), isFalse);
  });

  test('選択と、すべて選ぶ問題（順不同）', () {
    expect(_sheet.item('02')!.check('2'), isTrue);
    expect(_sheet.item('02')!.check('1'), isFalse);
    final all = _sheet.item('03')!;
    expect(all.check(MockItem.joinChoices(['3', '1'])), isTrue);
    expect(all.check('1'), isFalse);
    expect(all.check('1,3,4'), isFalse);
    expect(_sheet.item('04')!.check('なんでも'), isNull);
  });

  test('時間：一時停止した分は数えず、時間切れの提出は60分ちょうどにする', () {
    final t0 = DateTime(2026, 10, 28, 9);
    final a = YosouAttemptFixture.start(t0);
    expect(a.remaining(t0.add(const Duration(minutes: 10)), 60).inMinutes, 50);
    a.pause(t0.add(const Duration(minutes: 10)));
    expect(a.remaining(t0.add(const Duration(minutes: 40)), 60).inMinutes, 50);
    a.resume(t0.add(const Duration(minutes: 40)));
    expect(a.remaining(t0.add(const Duration(minutes: 50)), 60).inMinutes, 40);
    expect(a.remaining(t0.add(const Duration(hours: 3)), 60), Duration.zero);
    a.submit(t0.add(const Duration(hours: 3)), 60);
    expect(a.spent(t0.add(const Duration(hours: 5))).inMinutes, 60);
  });

  test('採点：自動・自分で直す・自分で点をつける', () {
    final a = YosouAttemptFixture.start(DateTime(2026))
      ..answers.addAll({
        '01': 'OS',
        '02': '1',
        '03': '1,3',
        '04': 'メモ',
      });
    expect(a.score(_sheet), 5);
    expect(a.unscored(_sheet).single.id, '04');
    a.selfScores['04'] = 3;
    a.overrides['02'] = true;
    expect(a.score(_sheet), 13 - 2);
    expect(a.correct(_sheet.item('04')!), isFalse);
    expect(a.unscored(_sheet), isEmpty);
  });

  test('保存して読みなおせる', () {
    final t0 = DateTime(2026, 10, 28, 9);
    final a = YosouAttemptFixture.start(t0)
      ..answers['01'] = 'OS'
      ..flags.add('02')
      ..selfScores['04'] = 2
      ..overrides['01'] = false;
    a.pause(t0.add(const Duration(minutes: 5)));
    final b = MockAttempt.fromMap(
      Map<String, dynamic>.from(jsonDecode(jsonEncode(a.toMap())) as Map),
    );
    expect(b.answers, {'01': 'OS'});
    expect(b.flags, {'02'});
    expect(b.paused, isTrue);
    expect(b.selfScores, {'04': 2});
    expect(b.overrides, {'01': false});
    expect(b.spent(t0.add(const Duration(hours: 1))).inMinutes, 5);
  });

  test('予想問題の一覧', () {
    expect(YosouExams.all, isNotEmpty);
    for (final e in YosouExams.all) {
      expect(YosouExams.byId(e.id), same(e));
      expect(e.asset(1), 'assets/mock_exams/${e.id}/01.bin');
      expect(e.pages, e.questionPages + e.answerPages);
    }
  });
}

abstract final class YosouAttemptFixture {
  static MockAttempt start(DateTime t) =>
      MockAttempt(examId: 'x', startedAt: t);
}

final _password = Platform.environment['SCHOOL_PASSWORD'];

void _bundled() {
  test('同梱の予想問題は学校のパスワードで開け、ページがそろい、100点満点', () {
    final key = SchoolMaterials.keyFor(_password!);
    for (final e in YosouExams.all) {
      final dir = '../rpg_game_app/';
      final sheet = MockSheet.fromJson(
        utf8.decode(
          SchoolMaterials.open(
            File(dir + e.sheetAsset).readAsBytesSync(),
            key: key,
          )!,
        ),
      );
      expect(sheet.total, 100, reason: e.id);
      expect(
        {for (final i in sheet.items) i.id}.length,
        sheet.items.length,
        reason: e.id,
      );
      for (final i in sheet.items) {
        if (i.type == MockItemType.choice) {
          for (final a in i.answers) {
            expect(i.options, contains(a), reason: '${e.id} ${i.id}');
          }
        }
        expect(i.answers, isNotEmpty, reason: '${e.id} ${i.id}');
      }
      for (var p = 1; p <= e.pages; p++) {
        final img = SchoolMaterials.open(
          File(dir + e.asset(p)).readAsBytesSync(),
          key: key,
        );
        expect(SchoolMaterials.looksLikeImage(img!), isTrue,
            reason: '${e.id} $p');
      }
      expect(File(dir + e.asset(e.pages + 1)).existsSync(), isFalse,
          reason: e.id);
    }
  }, skip: _password == null ? 'SCHOOL_PASSWORD がないので中身は確かめない' : false);
}
