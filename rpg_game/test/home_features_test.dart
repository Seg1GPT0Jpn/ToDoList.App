import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

RpgProgress _cleared(int n) => RpgProgress.initial.copyWith(
      clearedStageIds: {for (var i = 0; i < n; i++) 'stage$i'},
    );

void main() {
  test('はじめはクラスルームと設定だけ。エリアをクリアするほど増える', () {
    expect(HomeFeature.open(RpgProgress.initial),
        [HomeFeature.classroom, HomeFeature.settings]);
    expect(HomeFeature.next(RpgProgress.initial)!.clears, 1);
    expect(HomeFeature.open(_cleared(1)), contains(HomeFeature.reviewTower));
    expect(HomeFeature.open(_cleared(1)), isNot(contains(HomeFeature.versus)));
    expect(HomeFeature.open(_cleared(5)), HomeFeature.values);
    expect(HomeFeature.next(_cleared(5)), isNull);
  });

  test('「すべての機能を表示」なら最初から全部', () {
    expect(
        HomeFeature.open(RpgProgress.initial, all: true), HomeFeature.values);
  });
}
