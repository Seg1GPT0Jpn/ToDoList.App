import 'field3d.dart';

/// クエストの進み具合を判定するための材料（描画なし・純 Dart）
class QuestContext {
  const QuestContext({
    required this.talked,
    required this.defeated,
    required this.totalEnemies,
    required this.reviewWins,
    required this.mastered,
  });

  factory QuestContext.of(
    Field3DState s,
    Field3DRegion r, {
    required int mastered,
  }) => QuestContext(
    talked: s.talked,
    defeated: s.defeated.length,
    totalEnemies: r.enemies.length,
    reviewWins: s.reviewWins,
    mastered: mastered,
  );

  final Set<String> talked;
  final int defeated;
  final int totalEnemies;

  /// 復習スライムをたおした回数
  final int reviewWins;

  /// 習得した問題の数（間をあけて正解を重ねた問題。LearningRecord.masteredCount）
  final int mastered;
}

/// 案内人から受けるクエスト。目的を達成したら、案内人に報告すると報酬がもらえる
class Quest3D {
  const Quest3D({
    required this.id,
    required this.title,
    required this.goal,
    required this.giveLines,
    required this.doneLines,
    required this.rewardExp,
    required this.met,
    required this.progress,
    this.honor,
  });

  final String id;
  final String title;

  /// 画面に出す目的（短く）
  final String goal;

  /// 受けるときのせりふ
  final List<String> giveLines;

  /// 報告したときのせりふ
  final List<String> doneLines;
  final int rewardExp;

  /// 報酬の称号（なければ null）
  final String? honor;
  final bool Function(QuestContext c) met;

  /// 進み具合の表示（例：1/3）。なければ空
  final String Function(QuestContext c) progress;
}

String _none(QuestContext _) => '';

/// はじまりの草原のクエスト（順番に進む）
class QuestBook {
  QuestBook._();

  /// クエストを渡す人
  static const giverId = 'proto_guide';

  static final chain = <Quest3D>[
    Quest3D(
      id: 'q_hello',
      title: '冒険のはじまり',
      goal: '案内人ノートに話しかけよう',
      giveLines: const [],
      doneLines: const ['ようこそ、立体の草原へ！ ここでは、学んだぶんだけ冒険が進みます。'],
      rewardExp: 5,
      met: (c) => c.talked.contains(giverId),
      progress: _none,
    ),
    Quest3D(
      id: 'q_first',
      title: 'はじめてのバトル',
      goal: 'スライムを1体たおそう',
      giveLines: const [
        '草原には、問題を出してくるスライムがいます。',
        '近づいて「たたかう」。正解したら、えんぴつの剣をふって当てましょう。',
        'まちがえても大丈夫。答えと解説を読んでから、次の問題へ進めます。',
      ],
      doneLines: const ['おみごと！ 正解するほど、剣は強くなります。'],
      rewardExp: 10,
      met: (c) => c.defeated >= 1,
      progress: (c) => '${c.defeated.clamp(0, 1)}/1',
    ),
    Quest3D(
      id: 'q_all',
      title: '草原の見回り',
      goal: '草原のスライムを全部たおそう',
      giveLines: const ['草原には、英語・数学・社会のスライムがいます。', '苦手な教科も、1問ずつなら きっと進めます。'],
      doneLines: const ['草原が静かになりました。あなたは「草原の見張り番」です！'],
      rewardExp: 30,
      honor: '草原の見張り番',
      met: (c) => c.defeated >= c.totalEnemies,
      progress: (c) => '${c.defeated}/${c.totalEnemies}',
    ),
    Quest3D(
      id: 'q_review',
      title: 'わすれたころの復習',
      goal: '復習スライムを1体たおそう（次の日から現れる）',
      giveLines: const [
        '人は、覚えたことを少しずつ忘れます。だから、日をあけて もう一度。',
        'たおしたスライムは、復習の日が来ると「復習スライム」になって戻ってきます。',
        '明日以降に また草原へ来てください。',
      ],
      doneLines: const ['日をあけても答えられたなら、それは本当の力です！'],
      rewardExp: 30,
      honor: '復習の達人',
      met: (c) => c.reviewWins >= 1,
      progress: (c) => '${c.reviewWins.clamp(0, 1)}/1',
    ),
    Quest3D(
      id: 'q_master',
      title: '知識の根っこ',
      goal: '問題を10問「習得」しよう（日をあけて3回正解）',
      giveLines: const ['同じ問題に、日をあけて3回正解すると「習得」です。', '10問習得できたら、また報告してください。'],
      doneLines: const ['あなたの知識は、しっかり根をはりました。「知識の庭師」の称号をどうぞ！'],
      rewardExp: 60,
      honor: '知識の庭師',
      met: (c) => c.mastered >= 10,
      progress: (c) => '${c.mastered.clamp(0, 10)}/10',
    ),
  ];

  static Quest3D? byId(String id) {
    for (final q in chain) {
      if (q.id == id) return q;
    }
    return null;
  }

  /// いま取り組んでいるクエスト（全部終わったら null）
  static Quest3D? current(Set<String> done) {
    for (final q in chain) {
      if (!done.contains(q.id)) return q;
    }
    return null;
  }

  /// 報告できる（目的を達成している）か
  static bool reportable(Set<String> done, QuestContext c) =>
      current(done)?.met(c) ?? false;

  /// もらった称号（クエストの順）
  static List<String> honors(Set<String> done) => [
    for (final q in chain)
      if (done.contains(q.id) && q.honor != null) q.honor!,
  ];

  /// 画面に出す今の目的
  static String objective(Set<String> done, QuestContext c) {
    final q = current(done);
    if (q == null) return '草原のクエストはすべて達成！ 復習スライムで力をたもとう';
    if (q.met(c)) return '案内人ノートに報告しよう（${q.title}）';
    final p = q.progress(c);
    return p.isEmpty ? q.goal : '${q.goal}　$p';
  }

  /// 案内人と話したときの結果。達成していれば報告して次のクエストを受ける
  static QuestTalk talk(Set<String> done, QuestContext c) {
    final q = current(done);
    if (q == null) {
      return const QuestTalk(
        lines: ['草原のクエストは、すべて達成です。', '復習スライムが出たら、たおして知識をたもちましょう。'],
      );
    }
    if (!q.met(c)) {
      return QuestTalk(lines: q.giveLines.isEmpty ? [q.goal] : q.giveLines);
    }
    final nowDone = {...done, q.id};
    final next = current(nowDone);
    return QuestTalk(
      completed: q,
      lines: [
        ...q.doneLines,
        '【クエスト達成】${q.title}　経験値+${q.rewardExp}'
            '${q.honor == null ? '' : '　称号「${q.honor}」'}',
        if (next != null) ...[
          '【次のクエスト】${next.title}：${next.goal}',
          ...next.giveLines,
        ],
      ],
    );
  }
}

/// 案内人との会話の中身と、達成したクエスト
class QuestTalk {
  const QuestTalk({required this.lines, this.completed});

  final List<String> lines;
  final Quest3D? completed;
}
