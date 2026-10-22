import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/vocab/vocab_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<int> _sealed(String group) => VocabVault.seal(
  'テスト古文',
  [
    for (var i = 1; i <= 4; i++)
      VocabCard(id: 't$i', term: '語$i', meaning: '意味$i', group: group),
  ],
  'pw',
  worldId: 'japanese',
);

void main() {
  test('アプリの単語帳が新しくなったら、開いた単語帳の章も新しくなる', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final old = VocabStore.assetLoader;
    addTearDown(() => VocabStore.assetLoader = old);
    var data = _sealed('1〜50');
    VocabStore.assetLoader = (_) async => data;

    final store = VocabStore(prefs);
    // パスワードは大文字で入れても開ける
    final b = await store.unlock('テスト古文', 'PW');
    expect(b!.cards.first.group, '1〜50');
    expect(b.isTerms, isTrue);
    expect(await store.refreshOpened(), isFalse);

    data = _sealed('第11回（151〜180）');
    expect(await store.refreshOpened(), isTrue);
    expect(store.book(b.id)!.cards.first.group, '第11回（151〜180）');

    // 次に起動したときも新しい章のまま
    final again = VocabStore(prefs);
    expect(again.book(b.id)!.cards.first.group, '第11回（151〜180）');
  });
}
