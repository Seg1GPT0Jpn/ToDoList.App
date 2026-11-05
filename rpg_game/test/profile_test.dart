import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

void main() {
  group('ユーザー名', () {
    test('1〜12文字ならOK（前後の空白は無視）', () {
      expect(PlayerProfile.validateName('つづり'), isNull);
      expect(PlayerProfile.validateName('  Tsuzuri  '), isNull);
      expect(PlayerProfile.validateName('あいうえおかきくけこさし'), isNull);
    });

    test('空・長すぎ・空白だけ・制御文字はだめ', () {
      expect(PlayerProfile.validateName(''), isNotNull);
      expect(PlayerProfile.validateName('   '), isNotNull);
      expect(PlayerProfile.validateName('　　'), isNotNull);
      expect(PlayerProfile.validateName('あいうえおかきくけこさしす'), isNotNull);
      expect(PlayerProfile.validateName('a\nb'), isNotNull);
    });

    test('名前がないときの表示名', () {
      expect(PlayerProfile.empty.displayName, '名無しの冒険者');
      expect(const PlayerProfile(userName: 'ゆう').displayName, 'ゆう');
    });
  });

  test('Google 連携の保存と解除', () {
    final linked = const PlayerProfile(userName: 'ゆう').copyWith(
      googleEmail: 'yu@example.com',
      googleDisplayName: 'Yu',
      linkedAt: DateTime.utc(2026, 9, 26),
    );
    expect(linked.isGoogleLinked, isTrue);
    final again = PlayerProfile.fromMap(linked.toMap());
    expect(again.toMap(), linked.toMap());
    final unlinked = again.copyWith(unlinkGoogle: true);
    expect(unlinked.isGoogleLinked, isFalse);
    expect(unlinked.userName, 'ゆう');
  });

  test('プロフィールはアカウント削除・バックアップの対象', () {
    expect(RpgFirestorePaths.userSubcollections, contains('rpg_profile'));
    expect(RpgFirestorePaths.profileDoc('u1'), 'users/u1/rpg_profile/main');
  });
}
