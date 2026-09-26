import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

void main() {
  group('試験対策ワールド', () {
    final math = RpgCatalog.world('math');

    test('試験範囲の文章から、合うエリアを探す（全角・漢数字のゆれも許す）', () {
      final got = ExamWorlds.match(math, '二次関数、三角比');
      expect(got, isNotEmpty);
      for (final s in got) {
        final t = ExamWorlds.searchText(math, s);
        expect(t.contains('2次関数') || t.contains('三角比'), isTrue, reason: s.id);
      }
      expect(got.any((s) => s.grammarTheme.startsWith('三角比')), isTrue);
      expect(got.any((s) => s.grammarTheme.contains('2次関数')), isTrue);
      expect(ExamWorlds.match(math, '２次関数').length,
          ExamWorlds.match(math, '2次関数').length);
    });

    test('1文字のキーワードや空の入力では何も選ばない', () {
      expect(ExamWorlds.match(math, ''), isEmpty);
      expect(ExamWorlds.match(math, 'の、は'), isEmpty);
    });

    test('ほかの教科でも探せる', () {
      expect(ExamWorlds.match(RpgCatalog.world('japanese'), '助動詞'), isNotEmpty);
      expect(ExamWorlds.match(RpgCatalog.world('social'), '日本史'), isNotEmpty);
      expect(ExamWorlds.match(RpgCatalog.world('science'), '化学'), isNotEmpty);
      expect(
          ExamWorlds.match(RpgCatalog.world(RpgCatalog.englishWorldId), '関係詞'),
          isNotEmpty);
    });

    test('選んだエリア＋試験本番のボスで1本道になり、ボスは範囲全部から出題する', () {
      final picked = ExamWorlds.match(math, '三角比');
      final plan = ExamWorldPlan(
        id: 't1',
        title: '中間テスト',
        worldId: 'math',
        stageIds: [for (final s in picked) s.id],
        createdAt: DateTime(2026),
        rangeText: '三角比',
      );
      final stages = ExamWorlds.build(plan);
      expect(stages.length, picked.length + 1);
      expect(stages.last.isBoss, isTrue);
      expect(stages.last.questionSetIds.toSet(),
          {for (final s in picked) ...s.questionSetIds});
      for (var i = 1; i < stages.length; i++) {
        expect(stages[i].enemy.maxHp,
            greaterThanOrEqualTo(stages[i - 1].enemy.maxHp));
        expect(stages[i].order, i + 1);
      }
      // 元のエリアと ID がかぶらない（RPG の進行を変えない）
      final rpgIds = {for (final s in math.stages) s.id};
      expect(stages.every((s) => !rpgIds.contains(s.id)), isTrue);
    });

    test('保存用の形に変換しても元にもどる', () {
      final plan = ExamWorldPlan(
        id: 'x',
        title: '期末',
        worldId: 'social',
        stageIds: const ['social_geo_01', 'social_geo_02'],
        createdAt: DateTime(2026, 9, 1),
        rangeText: '地理',
        clearedCount: 2,
      );
      final back = ExamWorldPlan.fromMap(plan.toMap());
      expect(back.toMap(), plan.toMap());
      expect(back.length, 3);
      expect(back.completed, isFalse);
    });
  });
}
