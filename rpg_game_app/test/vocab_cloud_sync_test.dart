import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/cloud/vocab_cloud_sync.dart';
import 'package:rpg_game_app/vocab/speech.dart';
import 'package:rpg_game_app/vocab/vocab_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<VocabStore> _store() async {
  SharedPreferences.setMockInitialValues({});
  return VocabStore(await SharedPreferences.getInstance());
}

void main() {
  final now = DateTime(2026, 10, 12, 9);

  test('アンインストールしても、ログインすればクラウドから学習記録が戻る', () async {
    final cloud = <String, Map<String, dynamic>>{};
    VocabCloudSync sync() => VocabCloudSync(
      write: (id, data) async => cloud[id] = jsonDecode(jsonEncode(data)),
      readAll: () async => Map.of(cloud),
      delay: Duration.zero,
    );

    // 1台目：LEAP を勉強する（似た単語の英単語はクラウドに送らない）
    final first = await _store();
    final up = sync();
    first.progress('leap')
      ..record(
        cardId: '12',
        skill: VocabSkill.meaning,
        rating: Rating.good,
        now: now,
      )
      ..record(
        cardId: '13',
        skill: VocabSkill.meaning,
        rating: Rating.again,
        now: now,
        reason: MistakeReason.confused,
        confusedWith: 'adapt',
      );
    up.saved(first, 'leap');
    await up.flush();
    expect(cloud.keys.every((k) => k.startsWith('leap~')), isTrue);
    expect(jsonEncode(cloud), isNot(contains('adapt')));

    // 入れ直した端末：記録は空 → ログインでもどる
    final again = await _store();
    expect(again.progress('leap').cards, isEmpty);
    await sync().pull(again);
    final p = again.progress('leap');
    expect(p.cards.keys, containsAll(['12', '13']));
    expect(p.days[BookProgress.dayKey(now)]!.answered, 2);
  });

  test('変わっていない文書は送りなおさない', () async {
    final writes = <String>[];
    final store = await _store();
    final s = VocabCloudSync(
      write: (id, _) async => writes.add(id),
      readAll: () async => {},
      delay: Duration.zero,
    );
    store
        .progress('eevi')
        .record(
          cardId: '1',
          skill: VocabSkill.meaning,
          rating: Rating.good,
          now: now,
        );
    s.saved(store, 'eevi');
    await s.flush();
    final firstRound = writes.length;
    s.saved(store, 'eevi');
    await s.flush();
    expect(writes.length, firstRound);
  });

  test('日本語の端末でも英語の声を選ぶ', () {
    final voices = [
      {'name': 'ja-jp-x-htm', 'locale': 'ja-JP'},
      {'name': 'en-gb-x-rjs', 'locale': 'en-GB'},
      {'name': 'en-us-x-sfg', 'locale': 'en-US'},
    ];
    expect(TtsSpeaker.pickVoice(voices, 'en-US')!['locale'], 'en-US');
    expect(TtsSpeaker.pickVoice(voices, 'en-AU')!['locale'], 'en-GB');
    expect(TtsSpeaker.pickVoice([voices.first], 'en-US'), isNull);
  });
}
