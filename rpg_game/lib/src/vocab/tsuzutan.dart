import 'dart:math';

import '../models/question.dart';
import '../study/sea_catalog.dart';
import '../study/word_list.dart';
import '../study/word_quiz_builder.dart';

part 'tsuzutan_lists.g.dart';

/// つづ単（公開版）の1冊（assets/words/<id>.json）。
class TsuzutanList {
  const TsuzutanList({
    required this.id,
    required this.title,
    required this.level,
    required this.count,
    required this.first,
    required this.last,
  });

  final String id;
  final String title;

  /// 1 基礎・2 標準・3 発展
  final int level;
  final int count;

  /// 最初と最後の語（アルファベット順に並べてある）
  final String first;
  final String last;

  String get description => '$count語（$first 〜 $last）';
}

/// つづ単（つづり単語集）の公開版。
///
/// 意味・例文・豆知識はすべて自作。市販教材の訳は含まない
/// （市販教材の訳を含む版は、パスワードで開く単語帳 tudutan だけにある）。
/// RPG・定期テストの海・模擬試験の空・単語の森で使う。
class Tsuzutan {
  const Tsuzutan._();

  static const levelNames = {1: '基礎', 2: '標準', 3: '発展'};

  static List<TsuzutanList> get lists => _lists;

  static List<TsuzutanList> ofLevel(int level) => [
        for (final l in _lists)
          if (l.level == level) l
      ];

  /// 定期テストの海・模擬試験の空に並べる単語帳
  static List<SeaWordBook> get seaBooks => [
        for (final l in _lists)
          SeaWordBook(id: l.id, title: l.title, description: l.description),
      ];

  /// RPG のエリアの語彙レベル（基礎・標準・難関など）に合うつづ単のレベル
  static List<int> levelsForStage(String vocabLevel) => switch (vocabLevel) {
        '基礎' => const [1],
        '標準' => const [1, 2],
        '難関' => const [2, 3],
        _ => const [1, 2, 3],
      };

  /// RPG のバトルに混ぜる単語問題（英→日・日→英あわせて約 [count] 問）。
  /// 学習記録に残せるよう、もとの単語帳ごとの問題セットで返す。
  static List<QuestionSet> battleSets(
    List<WordList> lists, {
    int count = 12,
    Random? random,
  }) {
    final rnd = random ?? Random();
    final usable = [
      for (final l in lists)
        if (l.words.length >= 4) l
    ];
    if (usable.isEmpty) return const [];
    final picked = <(WordList, WordQuizDirection), List<WordEntry>>{};
    for (var i = 0; i < count; i++) {
      final list = usable[rnd.nextInt(usable.length)];
      final w = list.words[rnd.nextInt(list.words.length)];
      final dir =
          rnd.nextBool() ? WordQuizDirection.enToJa : WordQuizDirection.jaToEn;
      final ws = picked.putIfAbsent((list, dir), () => []);
      if (!ws.contains(w)) ws.add(w);
    }
    return [
      for (final e in picked.entries)
        WordQuizBuilder(random: rnd)
            .build(e.key.$1, direction: e.key.$2, only: e.value),
    ];
  }
}
