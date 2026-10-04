import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

void main() {
  group('試験対策ワールド', () {
    final math = RpgCatalog.world('math');

    test('試験範囲の文章から、合うエリアを探す（全角・漢数字のゆれも許す）', () {
      final got = ExamWorlds.match(math, '一次方程式、三平方の定理');
      expect(got, isNotEmpty);
      for (final s in got) {
        final t = ExamWorlds.searchText(math, s);
        // 漢数字は算用数字にそろえて探す（一次 → 1次）
        expect(
            t.contains(ExamWorlds.normalize('一次方程式')) || t.contains('三平方の定理'),
            isTrue,
            reason: s.id);
      }
      expect(got.any((s) => s.grammarTheme.startsWith('三平方')), isTrue);
      expect(got.any((s) => s.grammarTheme.contains('一次方程式')), isTrue);
      expect(ExamWorlds.match(math, '３けた').length,
          ExamWorlds.match(math, '3けた').length);
    });

    test('1文字のキーワードや空の入力では何も選ばない', () {
      expect(ExamWorlds.match(math, ''), isEmpty);
      expect(ExamWorlds.match(math, 'の、は'), isEmpty);
    });

    test('ほかの教科でも探せる', () {
      expect(ExamWorlds.match(RpgCatalog.world('japanese'), '敬語'), isNotEmpty);
      expect(ExamWorlds.match(RpgCatalog.world('social'), '江戸'), isNotEmpty);
      expect(ExamWorlds.match(RpgCatalog.world('science'), '電流'), isNotEmpty);
      expect(
          ExamWorlds.match(
              RpgCatalog.world(RpgCatalog.englishWorldId), '関係代名詞'),
          isNotEmpty);
    });

    test('選んだエリア＋試験本番のボスで1本道になり、ボスは範囲全部から出題する', () {
      final picked = ExamWorlds.match(math, '三平方の定理');
      final plan = ExamWorldPlan(
        id: 't1',
        title: '中間テスト',
        worldId: 'math',
        stageIds: [for (final s in picked) s.id],
        createdAt: DateTime(2026),
        rangeText: '三平方の定理',
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

    test('5教科のエリアを1つのワールドにまとめられる', () {
      final picked = ExamWorlds.matchAll({
        'math': '一次方程式',
        RpgCatalog.englishWorldId: '関係代名詞',
        'japanese': '敬語',
        'science': '電流',
        'social': '明治維新',
      });
      final worlds = {for (final s in picked) s.worldId};
      expect(worlds.length, 5);
      final plan = ExamWorldPlan(
        id: 'mix',
        title: '期末テスト',
        worldId: 'math',
        stageIds: [for (final s in picked.take(ExamWorlds.maxAreas)) s.id],
        createdAt: DateTime(2026),
        examDate: DateTime(2026, 10, 15),
      );
      expect(plan.worldIds.length, greaterThanOrEqualTo(5));
      expect(plan.subjectsLabel, contains('算数・数学'));
      final stages = ExamWorlds.build(plan, level: 10);
      expect(stages.length, plan.stageIds.length + 1);
      // 各エリアはもとの教科のワールドのまま（バトルの見た目・宿の授業に使う）
      for (var i = 0; i < plan.stageIds.length; i++) {
        expect(
            stages[i].worldId, ExamWorlds.stageById(plan.stageIds[i])!.worldId);
      }
      // 試験本番は、すべての教科の範囲から出題する
      expect(
        stages.last.questionSetIds.toSet(),
        {
          for (final id in plan.stageIds)
            ...ExamWorlds.stageById(id)!.questionSetIds,
        },
      );
      expect(plan.daysLeft(DateTime(2026, 10, 8)), 7);
      expect(plan.daysLeft(DateTime(2026, 10, 15, 23)), 0);
    });

    test('テスト対策ゲージは 0〜100 の間でたまり、保存しても元にもどる', () {
      final plan = ExamWorldPlan(
        id: 'g',
        title: 't',
        worldId: 'math',
        stageIds: const ['math_j1_01'],
        createdAt: DateTime(2026),
      );
      expect(plan.addGauge(30).addGauge(90).gauge, ExamWorlds.gaugeMax);
      final saved =
          plan.addGauge(12).copyWith(openedChests: {'exam_g_chest_1'});
      final back = ExamWorldPlan.fromMap(saved.toMap());
      expect(back.gauge, 12);
      expect(back.openedChests, {'exam_g_chest_1'});
    });

    test('5教科から60エリアまで集められ、後半の敵も強くなりすぎない', () {
      expect(ExamWorlds.maxAreas, 60);
      final all = [
        for (final w in RpgCatalog.worlds)
          ...w.stages.where((s) => !s.isBoss).take(12),
      ];
      final plan = ExamWorldPlan(
        id: 'big',
        title: '学年末',
        worldId: 'math',
        stageIds: [for (final s in all.take(60)) s.id],
        createdAt: DateTime(2026),
      );
      expect(plan.stageIds.length, 60);
      final stages = ExamWorlds.build(plan, level: 20);
      expect(stages.length, 61);
      final first = stages.first.enemy.maxHp;
      final last60 = stages[59].enemy.maxHp;
      expect(last60, lessThanOrEqualTo(first * 2));
      expect(plan.worldIds.length, 5);
    });
  });
}
