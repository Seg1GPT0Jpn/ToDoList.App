import 'dart:math';

import '../models/enemy.dart';
import '../models/player_stats.dart';
import '../models/stage.dart';

/// 復習の塔。復習の予定が来た問題・苦手な問題だけで戦う。
///
/// 難しさはほどほど（8割正解できれば勝てる、5回まちがえると倒れる）。
/// 復習で正解した数が増えるほど、上の階へ進む。
class ReviewTower {
  const ReviewTower._();

  /// 1つの階を上るのに必要な、復習での正解数
  static const correctPerFloor = 10;

  static int floorOf(int reviewCorrect) => reviewCorrect ~/ correctPerFloor + 1;

  static const _looks = [
    'ghost', 'book', 'page', 'eraser', 'pencil', 'crayon', 'sticky', //
    'binder', 'compass', 'knight', 'golem', 'dragon',
  ];

  static StageDef stage({
    required int level,
    required int floor,
    required int questionCount,
    required String worldId,
    bool summit = false,
  }) {
    final player = PlayerStats.forLevel(level);
    final hits = max(3, (questionCount * 0.8).round());
    return StageDef(
      id: summit ? 'review_tower_summit' : 'review_tower_$floor',
      worldId: worldId,
      order: floor,
      name: '復習の塔 $floor 階',
      region: '復習の塔',
      isBoss: summit || floor % 5 == 0,
      expReward: 0,
      questionSetIds: const [],
      timeLimitSeconds: 25,
      readingTimeLimitSeconds: 60,
      grammarTheme: '復習',
      enemy: EnemyDef(
        id: 'review_guard_${floor % _looks.length}',
        name: summit
            ? '苦手克服の番人'
            : floor % 5 == 0
                ? '塔の番人（$floor 階）'
                : '忘却のかげ（$floor 階）',
        maxHp: player.attack * hits,
        attack: (player.maxHp / 5 + player.defense / 2).ceil(),
        look: _looks[floor % _looks.length],
        color: 0xFF5A4A7A,
        description: 'わすれかけた知識から生まれる魔物。思い出せば消えていく。',
        introLine: 'おぼえているかな？ わすれたことを、思い出させてあげよう…',
        defeatLine: 'ちゃんと思い出したね…また忘れたころに会おう…',
      ),
    );
  }
}
