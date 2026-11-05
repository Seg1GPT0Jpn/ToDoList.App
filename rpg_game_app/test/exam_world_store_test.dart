import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/study/exam_world_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('試験対策ワールドを保存・更新・削除できる', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ExamWorldStore(await SharedPreferences.getInstance());
    final plan = ExamWorldPlan(
      id: 'a',
      title: '中間',
      worldId: 'english',
      stageIds: const ['english_stage_01'],
      createdAt: DateTime(2026),
    );
    await store.add(plan);
    expect(store.load().single.title, '中間');
    await store.update(plan.copyWith(clearedCount: 1));
    expect(store.byId('a')!.clearedCount, 1);
    await store.remove('a');
    expect(store.load(), isEmpty);
  });
}
