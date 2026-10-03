import 'dart:convert';
import 'dart:io';

import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

import 'helpers.dart';

/// 小中学生版の問題データの検査（tool/junior/gen.py で作ったもの）
void main() {
  group('5教科のワールド', () {
    test('5教科がそろい、英語の国だけ無料', () {
      expect(RpgCatalog.worlds.map((w) => w.id),
          ['english', 'math', 'japanese', 'science', 'social']);
      for (final w in RpgCatalog.worlds) {
        expect(w.isComingSoon, isFalse, reason: w.id);
        expect(w.isFree, w.id == RpgCatalog.englishWorldId, reason: w.id);
        expect(w.hubName, isNotEmpty);
        expect(w.hubSign, isNotEmpty);
      }
    });

    test('広場の1辺の門は3つまで、学年の道は小さい学年から並ぶ', () {
      for (final w in RpgCatalog.worlds) {
        for (final dir in const ['up', 'left', 'right', 'down']) {
          expect(w.routes.where((r) => r.direction == dir).length,
              lessThanOrEqualTo(3),
              reason: '${w.id} $dir');
        }
      }
      expect(
        RpgCatalog.world('math').routes.map((r) => r.name),
        ['小1', '小2', '小3', '小4', '小5', '小6', '中1', '中2', '中3'],
      );
    });
  });

  group('エリアの問題', () {
    final ids = <String>{};
    for (final w in RpgCatalog.worlds) {
      for (final s in w.stages) {
        test('${s.id} ${s.grammarTheme}: 自作の4択で、解説つき', () {
          final own = loadSet(s.questionSetIds.last);
          expect(own.setId,
              '${w.id}_${s.branch}_${s.areaNo.toString().padLeft(2, '0')}');
          expect(own.origin, QuestionOrigin.original);
          expect(own.questions.length, greaterThanOrEqualTo(s.isBoss ? 8 : 10));
          for (final q in own.questions) {
            expect(ids.add(q.id), isTrue, reason: '問題 ID が重複: ${q.id}');
            expect(q.choices.toSet(), hasLength(4), reason: q.id);
            expect(q.explanation, isNotNull, reason: q.id);
            expect(q.explanation!.trim(), isNotEmpty, reason: q.id);
            expect(q.prompt.trim(), isNotEmpty, reason: q.id);
            expect(q.targetGrade, isNotNull, reason: q.id);
          }
          // ボスは、前のボスの次のエリアからの問題をまとめて出す
          if (s.isBoss) expect(s.questionSetIds.length, greaterThan(1));
        });
      }
    }

    test('同じ学年の道で、同じ問いを2度出していない', () {
      for (final w in RpgCatalog.worlds) {
        for (final r in w.routes) {
          final keys = <String>[
            for (final s in w.stages.where((s) => s.branch == r.id))
              for (final q in loadSet(s.questionSetIds.last).questions)
                '${q.prompt}|${q.sentence}|${q.choices[q.answerIndex]}',
          ];
          expect(keys.toSet().length, keys.length, reason: '${w.id}/${r.id}');
        }
      }
    });

    test('ボスの装甲を割る種類の問題が、ボスの出題範囲にある', () {
      for (final w in RpgCatalog.worlds) {
        for (final s in w.stages.where((s) => s.isBoss)) {
          final pool = loadStagePool(s).questions;
          expect(pool.any((q) => q.category == s.enemy.armorCategory), isTrue,
              reason: s.id);
        }
      }
    });
  });

  group('定期テストの海と単語帳', () {
    test('中1〜中3の文法単元に問題がある', () {
      for (final u in SeaCatalog.units) {
        final set = JsonQuestionSource.parse(
            File('assets/questions/sea/${u.id}.json').readAsStringSync());
        expect(set.questions.length, greaterThanOrEqualTo(10), reason: u.id);
        expect(set.origin, QuestionOrigin.original);
      }
    });

    test('単語帳は自作で、語が重ならない', () {
      for (final b in SeaCatalog.wordBooks) {
        final list = WordList.fromJson(
            jsonDecode(File('assets/words/${b.id}.json').readAsStringSync())
                as Map<String, dynamic>);
        expect(list.origin, QuestionOrigin.original);
        expect(list.words.length, greaterThanOrEqualTo(40), reason: b.id);
        final terms = [for (final w in list.words) w.term];
        expect(terms.toSet().length, terms.length, reason: b.id);
      }
    });
  });

  test('アセットに市販教材の名前が入っていない', () {
    for (final f
        in Directory('assets').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.json')) continue;
      final text = f.readAsStringSync();
      expect(text, isNot(matches(RegExp(r'\b(LEAP|STEP|EEVI)\b'))),
          reason: f.path);
    }
  });
}
