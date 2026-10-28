import '../models/rpg_progress.dart';

/// ホームの「冒険の手帳」に並ぶ機能。
///
/// はじめての人に一度に全部を見せると迷うので、冒険（クリアしたエリアの数）が
/// 進むにつれて少しずつ出す。設定の「すべての機能を表示」で、いつでも全部出せる。
enum HomeFeature {
  classroom('クラスルーム', 0),
  settings('設定', 0),
  reviewTower('復習の塔', 1),
  story('物語', 1),
  bestiary('魔物図鑑', 1),
  achievements('実績・称号', 1),
  gear('装備・職業', 2),
  wordForest('単語の森', 2),
  learningStatus('学習ステータス', 3),
  library('問題集・解説', 3),
  growth('成長と学習ルート', 3),
  versus('対戦モード', 5),
  commonTest('共通テスト遺跡', 5),
  sky('模擬試験の空', 5),
  comprehensive('総合演習', 5);

  const HomeFeature(this.label, this.clears);

  final String label;

  /// 出てくるのに必要な、クリアしたエリアの数
  final int clears;

  bool openFor(RpgProgress p) => p.clearedStageIds.length >= clears;

  static List<HomeFeature> open(RpgProgress p, {bool all = false}) => [
        for (final f in values)
          if (all || f.openFor(p)) f,
      ];

  /// まだ出ていない機能のうち、いちばん早く出るもの（なければ null）
  static HomeFeature? next(RpgProgress p) {
    HomeFeature? best;
    for (final f in values) {
      if (f.openFor(p)) continue;
      if (best == null || f.clears < best.clears) best = f;
    }
    return best;
  }
}
