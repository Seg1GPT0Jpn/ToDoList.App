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

  test('同梱の単語帳に例文が加わったら、開いた単語帳にも例文が入る', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final old = VocabStore.assetLoader;
    addTearDown(() => VocabStore.assetLoader = old);
    List<int> sealed({bool examples = false}) => VocabVault.seal('TEST', [
      VocabCard(
        id: '1',
        term: 'agree',
        meaning: '[自] 賛成する',
        example: examples ? 'I agree with you.' : '',
        examples: [
          if (examples)
            const VocabExample(sense: '賛成する', en: 'I agree with you.'),
        ],
      ),
    ], 'pw');
    var data = sealed();
    VocabStore.assetLoader = (_) async => data;
    final store = VocabStore(prefs);
    final b = await store.unlock('TEST', 'pw');
    expect(b!.cards.single.examples, isEmpty);
    data = sealed(examples: true);
    expect(await store.refreshOpened(), isTrue);
    expect(store.book(b.id)!.cards.single.hasExample, isTrue);
    expect(store.book(b.id)!.cards.single.examples, hasLength(1));
  });
}
