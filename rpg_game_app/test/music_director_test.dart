import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game_app/app/settings.dart';
import 'package:rpg_game_app/audio/music_director.dart';

class Log implements AudioBackend {
  final loops = <String, String>{};
  final volumes = <String, double>{};
  final played = <String>[];

  @override
  Future<void> loop(String channel, String asset, double volume) async {
    loops[channel] = asset;
    volumes[channel] = volume;
  }

  @override
  Future<void> once(String asset, double volume) async => played.add(asset);

  @override
  Future<void> setVolume(String channel, double volume) async =>
      volumes[channel] = volume;

  @override
  Future<void> stop(String channel) async {
    loops.remove(channel);
    volumes.remove(channel);
  }
}

int audible(Log log) =>
    [for (var i = 0; i < 4; i++) log.volumes['layer$i'] ?? 0]
        .where((v) => v > 0)
        .length;

void main() {
  test('画面の出入りで曲が切りかわる', () async {
    final log = Log();
    final m = MusicDirector(log);
    await m.enter('home');
    expect(log.loops['bgm'], 'audio/bgm_home.mp3');
    await m.enter(MusicDirector.fieldKey('math'));
    expect(log.loops['bgm'], 'audio/bgm_field_math.mp3');
    await m.leave('field_math');
    expect(log.loops['bgm'], 'audio/bgm_home.mp3');
    expect(MusicDirector.fieldKey('unknown'), 'home');
  });

  test('正解を続けるとパートが増え、まちがえると1つ減る', () async {
    final log = Log();
    final m = MusicDirector(log);
    await m.enter('home');
    await m.enter(MusicDirector.battle);
    expect(log.loops.containsKey('bgm'), isFalse);
    expect(log.loops['layer0'], 'audio/bgm_battle_piano.mp3');
    expect(audible(log), 1);
    await m.answer(correct: true, combo: 1);
    expect(audible(log), 2);
    await m.answer(correct: true, combo: 2);
    await m.answer(correct: true, combo: 3);
    expect(audible(log), 3);
    await m.answer(correct: true, combo: 5);
    expect(audible(log), 4);
    await m.answer(correct: false, combo: 0);
    expect(audible(log), 3);
    // もう一度正解しても、一気には戻らない（今のパート数より減らさない）
    await m.answer(correct: true, combo: 1);
    expect(audible(log), 3);
    await m.leave(MusicDirector.battle);
    expect(log.loops['bgm'], 'audio/bgm_home.mp3');
    expect(log.loops.containsKey('layer0'), isFalse);
  });

  test('ボス戦は最初から全パート', () async {
    final log = Log();
    final m = MusicDirector(log);
    await m.enter(MusicDirector.boss);
    expect(log.loops['layer3'], 'audio/bgm_boss_strings.mp3');
    expect(audible(log), 4);
  });

  test('設定で BGM・効果音を止められる', () async {
    final log = Log();
    final m = MusicDirector(log);
    await m.enter('home');
    await m.applySettings(const AppSettings(bgm: false, se: false));
    expect(log.loops, isEmpty);
    await m.se('se_tap');
    expect(log.played, isEmpty);
    await m.applySettings(const AppSettings());
    expect(log.loops['bgm'], 'audio/bgm_home.mp3');
    await m.se('se_tap');
    expect(log.played, ['audio/se_tap.mp3']);
  });

  test('使う音のファイルがすべてある', () {
    const keys = [
      'home', 'field_japanese', 'field_math', 'field_english', //
      'field_science', 'field_social', 'field_information',
    ];
    for (final k in keys) {
      expect(
        File('assets/${MusicDirector.bgmAsset(k)}').existsSync(),
        isTrue,
        reason: k,
      );
    }
    for (final music in [MusicDirector.battle, MusicDirector.boss]) {
      for (var i = 0; i < 4; i++) {
        final path = 'assets/${MusicDirector.layerAsset(music, i)}';
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    }
  });
}
