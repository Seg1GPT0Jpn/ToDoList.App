import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game_app/app/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('問題のまとめファイルは最近使った教科だけを覚え、問題セットの一覧は覚えたままにする', () async {
    RpgServices.clearQuestionBundles();
    const worlds = [
      'english',
      'math',
      'japanese',
      'science',
      'social',
      'music',
    ];
    final counts = <String, Map<String, int>>{};
    for (final w in worlds) {
      counts[w] = await RpgServices.questionSetsOf(w);
      expect(counts[w], isNotEmpty, reason: w);
    }
    // 覚えているのは最近の4教科
    expect(RpgServices.cachedBundles, [
      'japanese',
      'science',
      'social',
      'music',
    ]);
    // 忘れた教科の問題も、読みなおして出せる（最近使ったものとして後ろに入る）
    final setId = counts['english']!.keys.first;
    expect(await RpgServices.loadQuestionAsset(setId), isNotNull);
    expect(RpgServices.cachedBundles, [
      'science',
      'social',
      'music',
      'english',
    ]);
    // 一覧は読みなおさない
    expect(
      identical(await RpgServices.questionSetsOf('math'), counts['math']),
      isTrue,
    );
    expect(RpgServices.cachedBundles.contains('math'), isFalse);
    RpgServices.clearQuestionBundles();
  });
}
