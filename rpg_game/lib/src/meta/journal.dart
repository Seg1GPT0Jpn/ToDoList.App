import '../learning/learning_record.dart';

/// バトルの種類
enum BattleMode {
  /// RPG のフィールドのバトル
  rpg,

  /// 定期テストの海
  sea,

  /// 試験対策ワールド
  exam,

  /// 復習の塔
  review,

  /// 亡霊との再戦
  ghost,

  /// 確認用
  trial,
}

/// 1回のバトルの報告。図鑑・実績・クエストの記録に使う
class BattleReport {
  const BattleReport({
    required this.mode,
    required this.subject,
    required this.enemyId,
    required this.look,
    required this.isBoss,
    required this.won,
    required this.correct,
    required this.answered,
    required this.maxCombo,
    this.setIds = const [],
  });

  final BattleMode mode;

  /// 教科（ワールド ID）
  final String subject;
  final String enemyId;
  final String look;
  final bool isBoss;
  final bool won;
  final int correct;
  final int answered;
  final int maxCombo;

  /// 出題した問題セット（クエストの対象判定用）
  final List<String> setIds;

  bool get perfect => won && answered > 0 && correct == answered;
}

/// その日のクエストの進み具合
class QuestState {
  const QuestState({
    this.day = 0,
    this.progress = const {},
    this.claimed = const {},
  });

  final int day;
  final Map<String, int> progress;
  final Set<String> claimed;

  Map<String, dynamic> toMap() => {
        'day': day,
        'progress': progress,
        'claimed': claimed.toList(),
      };

  factory QuestState.fromMap(Map<String, dynamic> m) => QuestState(
        day: (m['day'] as num?)?.toInt() ?? 0,
        progress: {
          for (final e in ((m['progress'] as Map?) ?? const {}).entries)
            e.key as String: (e.value as num).toInt(),
        },
        claimed: {
          for (final c in (m['claimed'] as List?) ?? const []) c as String,
        },
      );
}

/// 図鑑・実績・称号・クエスト・各種回数の記録。
///
/// 保存先は進行状況とは別（Firestore なら users/{uid}/rpg_journal/main）。
class PlayerJournal {
  const PlayerJournal({
    this.seen = const {},
    this.defeated = const {},
    this.seenLooks = const {},
    this.defeatedLooks = const {},
    this.achievements = const {},
    this.title = '',
    this.wins = 0,
    this.bossKills = 0,
    this.perfects = 0,
    this.seaWins = 0,
    this.reviewCorrect = 0,
    this.quest = const QuestState(),
  });

  static const empty = PlayerJournal();

  /// 出会った敵（敵 ID → 回数）
  final Map<String, int> seen;

  /// 倒した敵（敵 ID → 回数）
  final Map<String, int> defeated;

  /// 出会った種族（look → 回数）
  final Map<String, int> seenLooks;

  /// 倒した種族（look → 回数）
  final Map<String, int> defeatedLooks;

  /// 解除した実績（実績 ID → 解除した日）
  final Map<String, int> achievements;

  /// 表示中の称号（実績の名前）
  final String title;

  final int wins;
  final int bossKills;
  final int perfects;
  final int seaWins;
  final int reviewCorrect;
  final QuestState quest;

  PlayerJournal copyWith({
    Map<String, int>? seen,
    Map<String, int>? defeated,
    Map<String, int>? seenLooks,
    Map<String, int>? defeatedLooks,
    Map<String, int>? achievements,
    String? title,
    int? wins,
    int? bossKills,
    int? perfects,
    int? seaWins,
    int? reviewCorrect,
    QuestState? quest,
  }) =>
      PlayerJournal(
        seen: seen ?? this.seen,
        defeated: defeated ?? this.defeated,
        seenLooks: seenLooks ?? this.seenLooks,
        defeatedLooks: defeatedLooks ?? this.defeatedLooks,
        achievements: achievements ?? this.achievements,
        title: title ?? this.title,
        wins: wins ?? this.wins,
        bossKills: bossKills ?? this.bossKills,
        perfects: perfects ?? this.perfects,
        seaWins: seaWins ?? this.seaWins,
        reviewCorrect: reviewCorrect ?? this.reviewCorrect,
        quest: quest ?? this.quest,
      );

  static Map<String, int> _inc(Map<String, int> m, String key) => {
        ...m,
        key: (m[key] ?? 0) + 1,
      };

  /// バトルの結果を記録する（確認用のバトルは記録しない）
  PlayerJournal applyBattle(BattleReport r) {
    if (r.mode == BattleMode.trial) return this;
    var j = copyWith(
      seen: _inc(seen, r.enemyId),
      seenLooks: _inc(seenLooks, r.look),
    );
    if (r.won) {
      j = j.copyWith(
        defeated: _inc(j.defeated, r.enemyId),
        defeatedLooks: _inc(j.defeatedLooks, r.look),
        wins: j.wins + 1,
        bossKills: j.bossKills + (r.isBoss ? 1 : 0),
        perfects: j.perfects + (r.perfect ? 1 : 0),
        seaWins: j.seaWins + (r.mode == BattleMode.sea ? 1 : 0),
      );
    }
    if (r.mode == BattleMode.review) {
      j = j.copyWith(reviewCorrect: j.reviewCorrect + r.correct);
    }
    return j;
  }

  /// 実績の解除
  PlayerJournal unlock(Iterable<String> ids, int day) {
    final next = Map<String, int>.of(achievements);
    for (final id in ids) {
      next.putIfAbsent(id, () => day);
    }
    return copyWith(achievements: next);
  }

  Map<String, dynamic> toMap() => {
        'v': 1,
        'seen': seen,
        'defeated': defeated,
        'seenLooks': seenLooks,
        'defeatedLooks': defeatedLooks,
        'achievements': achievements,
        'title': title,
        'wins': wins,
        'bossKills': bossKills,
        'perfects': perfects,
        'seaWins': seaWins,
        'reviewCorrect': reviewCorrect,
        'quest': quest.toMap(),
      };

  static Map<String, int> _ints(Object? v) => {
        for (final e in ((v as Map?) ?? const {}).entries)
          e.key as String: (e.value as num).toInt(),
      };

  factory PlayerJournal.fromMap(Map<String, dynamic> m) => PlayerJournal(
        seen: _ints(m['seen']),
        defeated: _ints(m['defeated']),
        seenLooks: _ints(m['seenLooks']),
        defeatedLooks: _ints(m['defeatedLooks']),
        achievements: _ints(m['achievements']),
        title: m['title'] as String? ?? '',
        wins: (m['wins'] as num?)?.toInt() ?? 0,
        bossKills: (m['bossKills'] as num?)?.toInt() ?? 0,
        perfects: (m['perfects'] as num?)?.toInt() ?? 0,
        seaWins: (m['seaWins'] as num?)?.toInt() ?? 0,
        reviewCorrect: (m['reviewCorrect'] as num?)?.toInt() ?? 0,
        quest: QuestState.fromMap(
          Map<String, dynamic>.from((m['quest'] as Map?) ?? const {}),
        ),
      );

  /// 教科（ワールド ID）を問題セット ID から求める（LearningRecord と同じ規則）
  static String subjectOf(String setId) => LearningRecord.subjectOf(setId);
}
