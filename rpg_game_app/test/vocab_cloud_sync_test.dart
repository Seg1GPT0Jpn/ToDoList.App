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

  test('おもしろ声や入っていない声は選ばず、自然な英語の声を選ぶ', () {
    final apple = [
      {'name': 'Bad News', 'locale': 'en-US'},
      {'name': 'Albert', 'locale': 'en-US'},
      {'name': 'Samantha', 'locale': 'en-US'},
      {'name': 'Kyoko', 'locale': 'ja-JP'},
    ];
    expect(TtsSpeaker.pickVoice(apple, 'en-US')!['name'], 'Samantha');
    final android = [
      {
        'name': 'en-us-x-iob-local',
        'locale': 'en-US',
        'features': 'notInstalled',
      },
      {'name': 'en-us-x-tpf-local', 'locale': 'en-US', 'features': ''},
    ];
    expect(
      TtsSpeaker.pickVoice(android, 'en-US')!['name'],
      'en-us-x-tpf-local',
    );
    final chrome = [
      {'name': 'Microsoft Ayumi - Japanese', 'locale': 'ja-JP'},
      {'name': 'Google US English', 'locale': 'en-US'},
      {'name': 'Microsoft David - English', 'locale': 'en-US'},
    ];
    expect(TtsSpeaker.pickVoice(chrome, 'en-US')!['name'], 'Google US English');
  });

  test('単語帳の記号・日本語のメモは読み上げない', () {
    String c(String t) => SpeechText.clean(t, 'en-US');
    expect(c('take care of ～'), 'take care of');
    expect(c('look forward to ~ing'), 'look forward to doing');
    expect(c('as（接続詞）'), 'as');
    expect(c('be made (up) of'), 'be made up of');
    expect(c('remind sb of sth'), 'remind somebody of something');
    expect(c('affect / effect'), 'affect, effect');
    expect(
      c('If you are really determined ...'),
      'If you are really determined',
    );
    // 日本語の読み上げはそのまま
    expect(SpeechText.clean('りんご（果物）', 'ja-JP'), 'りんご（果物）');
  });

  group('2つのアプリ（つづりクエストと Light）で同時に使う', () {
    late Map<String, Map<String, dynamic>> cloud;
    late Set<String> lastWrites;
    VocabCloudSync sync() => VocabCloudSync(
      write: (id, data) async {
        lastWrites.add(id);
        cloud[id] = jsonDecode(jsonEncode(data));
      },
      readAll: () async => Map.of(cloud),
      delay: Duration.zero,
    );

    setUp(() {
      cloud = {};
      lastWrites = {};
    });

    test('片方で答えた分がもう片方にすぐ届き、送りなおしが続かない', () async {
      final full = await _store();
      final light = await _store();
      final a = sync(), b = sync();
      // フル版で答える → クラウドへ
      full
          .progress('leap')
          .record(
            cardId: '1',
            skill: VocabSkill.meaning,
            rating: Rating.good,
            now: now,
          );
      a.saved(full, 'leap');
      await a.flush();
      // Light がクラウドの変化を受けとる
      final changed = Set.of(lastWrites);
      lastWrites.clear();
      var redraws = 0;
      void count() => redraws++;
      VocabStore.changes.addListener(count);
      await b.apply(light, Map.of(cloud), changed: changed);
      VocabStore.changes.removeListener(count);
      expect(light.progress('leap').cards.keys, contains('1'));
      expect(redraws, greaterThan(0));
      await b.flush();
      // 同じ中身なので、Light からは送りかえさない
      expect(lastWrites, isEmpty);

      // Light でも答える → フル版に届く（どちらの答えも残る）
      light
          .progress('leap')
          .record(
            cardId: '2',
            skill: VocabSkill.meaning,
            rating: Rating.again,
            now: now,
          );
      b.saved(light, 'leap');
      await b.flush();
      final changed2 = Set.of(lastWrites);
      lastWrites.clear();
      await a.apply(full, Map.of(cloud), changed: changed2);
      await a.flush();
      expect(full.progress('leap').cards.keys, containsAll(['1', '2']));
      expect(lastWrites, isEmpty);
    });

    test('自分で作った単語帳は中身も届き、消すともう片方からも消える', () async {
      final full = await _store();
      final light = await _store();
      final a = sync(), b = sync();
      a.initBooks(full);
      b.initBooks(light);
      final book = await full.createBook('部活の単語');
      book.cards.add(VocabCard(id: 'c1', term: 'dribble', meaning: 'ドリブル'));
      await full.saveBooks();
      a.booksSaved(full);
      await a.flush();
      expect(
        cloud.keys.where((k) => k.startsWith(VocabCloudSync.bookPrefix)),
        hasLength(1),
      );
      await b.apply(light, Map.of(cloud), changed: Set.of(lastWrites));
      expect(light.book(book.id)?.cards.single.term, 'dribble');

      // フル版で消す → Light からも消える
      lastWrites.clear();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await full.deleteBook(book.id);
      a.booksSaved(full);
      await a.flush();
      await b.apply(light, Map.of(cloud), changed: Set.of(lastWrites));
      expect(light.book(book.id), isNull);
    });
  });
}
