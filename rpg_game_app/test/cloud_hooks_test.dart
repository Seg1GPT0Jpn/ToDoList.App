import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/account/profile_repository.dart';
import 'package:rpg_game_app/data/prefs_progress_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('保存するとクラウド用のフックが呼ばれ、クラウドからの読み込みでは呼ばれない', () async {
    final repo = PrefsProgressRepository(await SharedPreferences.getInstance());
    final sent = <RpgProgress>[];
    repo.onSaved = (p) async => sent.add(p);

    final p = RpgProgress.initial.copyWith(clearedStageIds: {'a'});
    await repo.save(p);
    expect(sent.single.clearedStageIds, {'a'});

    await repo.replaceLocal(
      RpgProgress.initial.copyWith(clearedStageIds: {'b'}),
    );
    expect(sent, hasLength(1));
    expect((await repo.load()).clearedStageIds, {'b'});

    await repo.reset();
    expect(sent.last.clearedStageIds, isEmpty);
  });

  test('プロフィールも同じ', () async {
    final repo = ProfileRepository(await SharedPreferences.getInstance());
    final sent = <PlayerProfile>[];
    repo.onSaved = (p) async => sent.add(p);

    await repo.save(PlayerProfile.empty.copyWith(userName: 'たろう'));
    await repo.replaceLocal(PlayerProfile.empty.copyWith(userName: 'はなこ'));
    expect(sent.map((p) => p.userName), ['たろう']);
    expect(repo.load().userName, 'はなこ');
  });
}
