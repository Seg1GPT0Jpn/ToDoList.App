/// まちがいの種類（バトルでまちがえたあとに、本人が1タップで選ぶ）
enum MistakeKind {
  careless('うっかり', '計算・書きまちがい'),
  unknown('知らなかった', '覚えていない・忘れた'),
  misread('読みまちがい', '問題文・条件の読み落とし'),
  confused('勘違い', '似たものと取りちがえた');

  const MistakeKind(this.label, this.description);
  final String label;
  final String description;

  /// 種類ごとの、次にやること
  String get advice => switch (this) {
        careless => '答える前に、もう一度だけ見直す習慣を',
        unknown => '復習の塔と暗記カードで、もう一度覚えなおそう',
        misread => '問題文の条件に線を引くつもりで読もう',
        confused => '似ているものを「まぜて練習」で見分けよう',
      };
}

/// まちがいの種類の記録（教科ごと・日ごと）。
///
/// 選ぶのは任意（選ばなければ記録しない）。古い記録は [keepDays] 日で消す。
class MistakeLog {
  const MistakeLog([this.entries = const []]);

  static const empty = MistakeLog();
  static const keepDays = 90;

  /// （日、教科＝ワールド ID、種類）
  final List<(int, String, MistakeKind)> entries;

  MistakeLog add(String subject, MistakeKind kind, {required int day}) =>
      MistakeLog([
        for (final e in entries)
          if (e.$1 > day - keepDays) e,
        (day, subject, kind),
      ]);

  /// 種類ごとの回数（[since] の日から。[subject] を指定すればその教科だけ）
  Map<MistakeKind, int> counts({int since = 0, String? subject}) {
    final out = {for (final k in MistakeKind.values) k: 0};
    for (final (day, s, k) in entries) {
      if (day < since || (subject != null && s != subject)) continue;
      out[k] = out[k]! + 1;
    }
    return out;
  }

  /// いちばん多い種類（記録がなければ null）
  MistakeKind? top({int since = 0, String? subject}) {
    MistakeKind? best;
    var n = 0;
    counts(since: since, subject: subject).forEach((k, v) {
      if (v > n) {
        best = k;
        n = v;
      }
    });
    return best;
  }

  Map<String, dynamic> toMap() => {
        'v': 1,
        'e': [
          for (final (d, s, k) in entries) [d, s, k.name],
        ],
      };

  factory MistakeLog.fromMap(Map<String, dynamic> m) => MistakeLog([
        for (final raw in (m['e'] as List?) ?? const [])
          if (raw is List && raw.length == 3)
            for (final k in MistakeKind.values)
              if (k.name == raw[2]) ((raw[0] as num).toInt(), '${raw[1]}', k),
      ]);
}
