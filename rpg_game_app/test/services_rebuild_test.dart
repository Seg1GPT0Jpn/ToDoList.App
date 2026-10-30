import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game_app/account/account_service.dart';
import 'package:rpg_game_app/account/profile_repository.dart';
import 'package:rpg_game_app/app/services.dart';
import 'package:rpg_game_app/app/settings.dart';
import 'package:rpg_game_app/app/usage_meter.dart';
import 'package:rpg_game_app/audio/music_director.dart';
import 'package:rpg_game_app/data/meta_store.dart';
import 'package:rpg_game_app/data/prefs_progress_repository.dart';
import 'package:rpg_game_app/study/exam_world_store.dart';
import 'package:rpg_game_app/study/personal_books.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'harness.dart';

class _Sink implements UsageSink {
  final sent = <String>[];
  @override
  Future<void> count(String day, String feature) async => sent.add(feature);
}

void main() {
  test('クラウドにつながって作りなおしても、記録の部品は同じものを使い、回数の送り先だけ差しこむ', () async {
    SharedPreferences.setMockInitialValues({});
    final p = await SharedPreferences.getInstance();
    final books = PersonalBooks(p);
    final repo = PrefsProgressRepository(p);
    final meta = MetaStore(p);
    final settings = SettingsStore.memory(const AppSettings());
    RpgServices make({UsageSink? sink}) => RpgServices(
      repository: repo,
      personalBooks: books,
      profiles: ProfileRepository(p),
      account: MockAccountService(),
      examWorlds: ExamWorldStore(p),
      meta: meta,
      settings: settings,
      music: MusicDirector(SilentAudio()),
      usageSink: sink,
      child: const SizedBox(),
    );
    final before = make();
    final sink = _Sink();
    final after = make(sink: sink);
    expect(identical(after.studyLog, before.studyLog), isTrue);
    expect(identical(after.mistakes, before.mistakes), isTrue);
    expect(identical(after.streak, before.streak), isTrue);
    expect(identical(after.homeFeatures, before.homeFeatures), isTrue);
    expect(identical(after.classroomStore, before.classroomStore), isTrue);
    expect(identical(after.usage, before.usage), isTrue);
    await before.usage.open('vocab');
    expect(sink.sent, ['vocab']);
    // 別の入れ物（PersonalBooks）を使うときは分ける
    final other = RpgServices(
      repository: repo,
      personalBooks: PersonalBooks(p),
      profiles: ProfileRepository(p),
      account: MockAccountService(),
      examWorlds: ExamWorldStore(p),
      meta: meta,
      settings: settings,
      music: MusicDirector(SilentAudio()),
      child: const SizedBox(),
    );
    expect(identical(other.studyLog, before.studyLog), isFalse);
  });
}
