import 'package:rpg_game/rpg_game.dart';

import 'duel_backend.dart';

/// 週替わり単語バトルの保存先。
///
/// 日程の設定はだれでも読めて、書けるのは管理者だけ。
/// 参加記録は1人1回：始めたときに作り、解き終わったら1回だけ点数を入れる。
abstract class ContestBackend {
  String? get userId;
  String? get email;

  bool get isAdmin => ContestRules.isAdmin(email);

  /// 日程の設定（まだなければはじめの設定）
  Future<ContestConfig> loadConfig();

  /// 日程の設定を保存する（管理者だけ）
  Future<void> saveConfig(ContestConfig config);

  /// 自分の参加記録（まだなら null）
  Future<ContestEntry?> mine(String roundId);

  /// 始める（1回だけ。もう始めていたら [DuelException]）
  Future<void> start(String roundId, String name);

  /// 解き終わった点数を入れる（1回だけ）
  Future<void> finish(String roundId, int correct, int score);

  /// 点数の高い順に [limit] 人
  Future<List<ContestEntry>> ranking(String roundId, {int limit = 100});

  /// 解き終わった人数と、自分より点数の高い人数（自分の順位 = 上の人数 + 1）
  Future<({int players, int above})> standing(String roundId, int score);
}

/// テストとサーバーのない版の、端末の中だけの保存先
class MemoryContestBackend extends ContestBackend {
  MemoryContestBackend({
    this.userId = 'me',
    this.email,
    ContestConfig? config,
    Map<String, Map<String, ContestEntry>>? entries,
  }) : config = config ?? ContestConfig.initial,
       entries = entries ?? {};

  @override
  final String? userId;
  @override
  final String? email;

  ContestConfig config;

  /// 回の ID → uid → 記録（テストでは何人かで同じものを使う）
  final Map<String, Map<String, ContestEntry>> entries;

  String _uid() => userId ?? (throw const DuelException(ContestText.needLogin));

  @override
  Future<ContestConfig> loadConfig() async => config;

  @override
  Future<void> saveConfig(ContestConfig c) async {
    if (!isAdmin) throw const DuelException('日程を変えられるのは管理者だけです');
    config = ContestConfig.fromMap(c.toMap());
  }

  @override
  Future<ContestEntry?> mine(String roundId) async => entries[roundId]?[_uid()];

  @override
  Future<void> start(String roundId, String name) async {
    final uid = _uid();
    final room = entries.putIfAbsent(roundId, () => {});
    if (room.containsKey(uid)) {
      throw const DuelException('このバトルは、もう挑戦ずみです');
    }
    room[uid] = ContestEntry(
      uid: uid,
      name: name,
      correct: 0,
      score: 0,
      done: false,
    );
  }

  @override
  Future<void> finish(String roundId, int correct, int score) async {
    final uid = _uid();
    final e = entries[roundId]?[uid];
    if (e == null || e.done) {
      throw const DuelException('結果を送れませんでした（挑戦ずみです）');
    }
    entries[roundId]![uid] = ContestEntry(
      uid: uid,
      name: e.name,
      correct: correct,
      score: score,
      done: true,
    );
  }

  @override
  Future<List<ContestEntry>> ranking(String roundId, {int limit = 100}) async =>
      ContestEntry.rank(entries[roundId]?.values ?? const [])
          .take(limit)
          .toList();

  @override
  Future<({int players, int above})> standing(String roundId, int score) async {
    final done = ContestEntry.rank(entries[roundId]?.values ?? const []);
    return (
      players: done.length,
      above: done.where((e) => e.score > score).length,
    );
  }
}

/// 画面に出す言葉
class ContestText {
  const ContestText._();

  static const title = '週替わり単語バトル';
  static const intro =
      'LEAP・EEVI を開いている人みんなで、同じ範囲・同じ問題の早押し4択で点数を競います。'
      'LEAP は毎週日曜、EEVI は毎週金曜（日本時間の0時〜24時）。1人1回だけです。';
  static const privacy = 'みんなに見えるのはニックネームと正解数・点数だけ。単語の中身はサーバーに送りません。';
  static const needLogin = '週替わり単語バトルは、Google でログインすると参加できます';
  static const noBackend = 'この版では、週替わり単語バトルは使えません（サーバーの設定がありません）';
}
