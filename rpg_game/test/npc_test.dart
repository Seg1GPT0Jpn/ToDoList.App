import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

void main() {
  final stage = RpgCatalog.world(RpgCatalog.englishWorldId).stages[1];

  test('すべての地形に住人がいる', () {
    for (final t in Terrain.values) {
      expect(Npcs.of(t).name, isNotEmpty);
    }
  });

  test('この先の魔物の能力・弱点と、熟練度に合わせたアドバイスを話す', () {
    final low = Npcs.talk(stage, Terrain.hill, score: 40);
    expect(low.lines.join(), contains(stage.enemy.name));
    expect(low.lines.join(), contains('熟練度40'));
    expect(low.lines.join(), contains('暗い'));
    final high = Npcs.talk(stage, Terrain.hill, score: 90);
    expect(high.lines.join(), contains('ばっちり'));
    final none = Npcs.talk(stage, Terrain.hill);
    expect(none.lines.join(), contains('宿の授業'));
  });

  test('頼みごと：奥の宝箱を開けるとごほうび、受け取ったらおしまい', () {
    final ask = Npcs.talk(stage, Terrain.hill, nookIsSecret: true);
    expect(ask.lines.last, contains('頼みごと'));
    expect(ask.questReady, isFalse);
    final ready = Npcs.talk(stage, Terrain.hill,
        nookIsSecret: false, nookChestOpened: true);
    expect(ready.questReady, isTrue);
    final done = Npcs.talk(stage, Terrain.hill,
        nookIsSecret: false, nookChestOpened: true, questRewarded: true);
    expect(done.questReady, isFalse);
    expect(done.questDone, isTrue);
  });

  test('語り部は、集めた欠片の数で話が変わる', () {
    expect(Npcs.storytellerTalk({}).lines.join(), contains('ひとつも'));
    expect(Npcs.storytellerTalk({'english'}).lines.join(), contains('通訳の羅針盤'));
    expect(
      Npcs.storytellerTalk({for (final w in Story.worlds) w.worldId})
          .lines
          .join(),
      contains('天空の図書院'),
    );
  });
}
