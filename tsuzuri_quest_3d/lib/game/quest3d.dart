import 'field3d.dart';

/// クエストの進み具合を判定するための材料（描画なし・純 Dart）
class QuestContext {
  const QuestContext({
    required this.talked,
    required this.defeated,
    required this.totalEnemies,
    required this.reviewWins,
    required this.mastered,
    this.defeatedIds = const {},
    this.flags = const {},
  });

  factory QuestContext.of(
    Field3DState s,
    Field3DRegion r, {
    required int mastered,
  }) {
    final normal = {
      for (final e in r.enemies)
        if (!e.boss) e.id,
    };
    return QuestContext(
      talked: s.talked,
      defeated: s.defeated.intersection(normal).length,
      totalEnemies: normal.length,
      reviewWins: s.reviewWins,
      mastered: mastered,
      defeatedIds: s.defeated,
      flags: s.flags,
    );
  }

  final Set<String> talked;

  /// たおした敵の数（ボスはのぞく）
  final int defeated;
  final int totalEnemies;

  /// たおした敵（ボスもふくむ）の ID
  final Set<String> defeatedIds;

  /// 解いたなぞ・開けた宝箱など
  final Set<String> flags;

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
    this.targetX,
    this.targetZ,
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

  /// 目的の場所（地図と画面の矢印に出す）。なければ null
  final double? targetX;
  final double? targetZ;
}

String _none(QuestContext _) => '';

/// 地域ごとのクエスト（順番に進む）
class QuestBook {
  const QuestBook({
    required this.giverId,
    required this.giverName,
    required this.chain,
    required this.allDoneText,
    this.autoReport = false,
  });

  /// クエストを渡す人
  final String giverId;
  final String giverName;
  final List<Quest3D> chain;

  /// すべて終わったときの目的の表示
  final String allDoneText;

  /// true なら、目的を達成したその場で報告したことにする（広い地図で村まで戻らなくてよい）。
  /// 最初のクエスト（話しかける）は話しかけたときに終わる
  final bool autoReport;

  /// 地域のクエスト
  static QuestBook forRegion(String regionId) =>
      regionId == 'land_v2' ? land : proto;

  /// 試作の草原（40m 四方）
  static final proto = QuestBook(
    giverId: 'proto_guide',
    giverName: '案内人ノート',
    allDoneText: '草原のクエストはすべて達成！ 復習スライムで力をたもとう',
    chain: <Quest3D>[
      Quest3D(
        id: 'q_hello',
        title: '冒険のはじまり',
        goal: '案内人ノートに話しかけよう',
        giveLines: const [],
        doneLines: const ['ようこそ、立体の草原へ！ ここでは、学んだぶんだけ冒険が進みます。'],
        rewardExp: 5,
        met: (c) => c.talked.contains('proto_guide'),
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
    ],
  );

  /// はじまりの大地（400m 四方）
  static final land = QuestBook(
    giverId: 'n1_chief',
    giverName: '村長ことのは',
    autoReport: true,
    allDoneText: '第 1 章のクエストはすべて達成！ 復習スライムで力をたもとう',
    chain: <Quest3D>[
      Quest3D(
        id: 'v_hello',
        title: '旅立ちのあいさつ',
        goal: '村長ことのはに話しかけよう',
        giveLines: const [],
        doneLines: const [
          'よく来たね。この大地では、学んだぶんだけ道がひらける。',
          '川の向こうの「星見の山」の遺跡に、次の地へ進む手がかりが眠っているそうだ。',
        ],
        rewardExp: 5,
        met: (c) => c.talked.contains('n1_chief'),
        progress: _none,
        targetX: 115,
        targetZ: 302,
      ),
      Quest3D(
        id: 'v_first',
        title: 'はじめてのバトル',
        goal: '村の東の草原で、スライムを1体たおそう',
        giveLines: const [
          '東の門を出た草原に、英語のスライムがいる。',
          '近づいて「たたかう」。正解したら、えんぴつの剣をふって当てるんだ。',
          '地図の★が目的の場所。目的を達成したら、その場でクエスト達成になるよ。',
        ],
        doneLines: const ['おみごと！ 正解するほど、剣は強くなる。'],
        rewardExp: 10,
        met: (c) => c.defeated >= 1,
        progress: (c) => '${c.defeated.clamp(0, 1)}/1',
        targetX: 162,
        targetZ: 290,
      ),
      Quest3D(
        id: 'v_bridge',
        title: '古橋の番人',
        goal: '古橋の番人をたおして、川をわたろう',
        giveLines: const [
          'メイン街道を北東へ進むと、川にかかる古橋がある。',
          '橋の手前には番人がいて、勝たないと橋はわたれない。手前の野営テントで記録しておこう。',
        ],
        doneLines: const ['番人が道をゆずった。川の東側を探検できる！'],
        rewardExp: 30,
        honor: '橋をわたる者',
        met: (c) => c.defeatedIds.contains('v_b1'),
        progress: _none,
        targetX: 200,
        targetZ: 210,
      ),
      Quest3D(
        id: 'v_stele',
        title: '石碑のなぞ',
        goal: '南東の石碑群で、石碑のなぞを解こう',
        giveLines: const [
          '橋をわたって南東へ。古代の石碑群に、岩場の洞窟の封印をとく手がかりがある。',
          '東道には理科のスライムがいる。会いたくなければ、川沿いの迂回路を通ろう。',
        ],
        doneLines: const ['洞窟の封印がとけた！ 東の岩場で確かめてみよう。'],
        rewardExp: 20,
        met: (c) => c.flags.contains('T3'),
        progress: _none,
        targetX: 290,
        targetZ: 330,
      ),
      Quest3D(
        id: 'v_summit',
        title: '遺跡の守護者',
        goal: '星見の山を登り、遺跡の守護者をたおそう',
        giveLines: const [
          '東詰から北へ、星見の登山道がのびている。中腹の踊り場をこえて山頂へ。',
          '山頂の闘技場に、遺跡の入口を守る守護者がいる。',
        ],
        doneLines: const ['守護者をたおした！ 遺跡の入口がひらいた。'],
        rewardExp: 60,
        honor: '星見の勇者',
        met: (c) => c.defeatedIds.contains('v_b2'),
        progress: _none,
        targetX: 335,
        targetZ: 102,
      ),
      Quest3D(
        id: 'v_temple',
        title: '星見の神殿',
        goal: '星見の神殿の祭壇をしらべよう',
        giveLines: const ['遺跡の奥に祭壇がある。しらべてみよう。'],
        doneLines: const ['第 1 章クリア！ 東の渓谷へのゲートが開いた。'],
        rewardExp: 30,
        honor: 'はじまりの大地の踏破者',
        met: (c) => c.flags.contains('T2'),
        progress: _none,
        targetX: 335,
        targetZ: 70,
      ),
      Quest3D(
        id: 'v_review',
        title: 'わすれたころの復習',
        goal: '復習スライムを1体たおそう（次の日から現れる）',
        giveLines: const [
          'たおしたスライムは、復習の日が来ると「復習スライム」になって戻ってくる。',
          '日をあけて答えられたら、それは本当の力だ。',
        ],
        doneLines: const ['日をあけても答えられた！'],
        rewardExp: 30,
        honor: '復習の達人',
        met: (c) => c.reviewWins >= 1,
        progress: (c) => '${c.reviewWins.clamp(0, 1)}/1',
      ),
      Quest3D(
        id: 'v_master',
        title: '知識の根っこ',
        goal: '問題を10問「習得」しよう（日をあけて3回正解）',
        giveLines: const ['同じ問題に、日をあけて3回正解すると「習得」だ。'],
        doneLines: const ['あなたの知識は、しっかり根をはった！'],
        rewardExp: 60,
        honor: '知識の庭師',
        met: (c) => c.mastered >= 10,
        progress: (c) => '${c.mastered.clamp(0, 10)}/10',
      ),
    ],
  );

  Quest3D? byId(String id) {
    for (final q in chain) {
      if (q.id == id) return q;
    }
    return null;
  }

  /// いま取り組んでいるクエスト（全部終わったら null）
  Quest3D? current(Set<String> done) {
    for (final q in chain) {
      if (!done.contains(q.id)) return q;
    }
    return null;
  }

  /// 報告できる（目的を達成している）か
  bool reportable(Set<String> done, QuestContext c) =>
      current(done)?.met(c) ?? false;

  /// もらった称号（クエストの順）
  List<String> honors(Set<String> done) => [
    for (final q in chain)
      if (done.contains(q.id) && q.honor != null) q.honor!,
  ];

  /// 画面に出す今の目的
  String objective(Set<String> done, QuestContext c) {
    final q = current(done);
    if (q == null) return allDoneText;
    if (q.met(c)) return '$giverNameに報告しよう（${q.title}）';
    final p = q.progress(c);
    return p.isEmpty ? q.goal : '${q.goal}　$p';
  }

  /// 達成したまま まだ報告していないクエストを、その場で報告する（[autoReport] のとき）。
  /// 達成したクエストを順に返す（同時に複数達成することもある）
  List<Quest3D> autoComplete(Set<String> done, QuestContext c) {
    if (!autoReport) return const [];
    final out = <Quest3D>[];
    var now = done;
    while (true) {
      final q = current(now);
      // 最初のクエスト（話しかける）は、話しかけたときの会話で終わらせる
      if (q == null || q == chain.first || !q.met(c)) break;
      out.add(q);
      now = {...now, q.id};
    }
    return out;
  }

  /// 案内人と話したときの結果。達成していれば報告して次のクエストを受ける
  QuestTalk talk(Set<String> done, QuestContext c) {
    final q = current(done);
    if (q == null) {
      return const QuestTalk(
        lines: ['クエストは、すべて達成です。', '復習スライムが出たら、たおして知識をたもちましょう。'],
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
