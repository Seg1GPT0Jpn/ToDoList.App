import 'dart:math';

import '../battle/question_deck.dart';
import '../models/question.dart';

/// 対戦のプレイヤー（0 = 下の人 / あなた、1 = 上の人 / CPU）
class VersusPlayer {
  VersusPlayer(this.name, this.maxHp) : hp = maxHp;

  final String name;
  final int maxHp;
  int hp;

  /// 正解した数
  int correct = 0;

  /// 連続正解（チェイン）
  int combo = 0;
  int maxCombo = 0;

  /// お手つき（まちがえた）数
  int misses = 0;

  bool get down => hp <= 0;
}

/// 1問の結果
class VersusTurn {
  const VersusTurn({
    required this.side,
    required this.question,
    required this.correct,
    required this.damage,
    required this.selfDamage,
    this.chosen,
    this.fast = false,
    this.combo = 0,
    this.timedOut = false,
    this.roundOver = false,
  });

  /// 答えた人（時間切れなら -1）
  final int side;
  final PresentedQuestion question;
  final bool correct;

  /// 相手に与えたダメージ
  final int damage;

  /// お手つきで自分が受けたダメージ
  final int selfDamage;
  final int? chosen;

  /// はやおしボーナスがついた
  final bool fast;
  final int combo;
  final bool timedOut;

  /// この問題は終わった（次の問題へ進む）
  final bool roundOver;
}

/// 早押しクイズ対戦のルール。
///
/// - 1問ずつ出題し、先に答えた人の答えで判定する
/// - 正解すると相手にダメージ（はやく答えるほど、続けて正解するほど大きい）
/// - まちがえると「お手つき」：自分に少しダメージ。その問題は相手だけが答えられる
/// - 2人ともまちがえるか時間切れなら、ダメージなしで次の問題
/// - どちらかの HP が 0 になるか、[rounds] 問が終わったら決着（HP が多いほうの勝ち）
class VersusMatch {
  VersusMatch({
    required List<QuizQuestion> questions,
    required List<String> names,
    this.maxHp = 100,
    this.rounds = 15,
    this.timeLimit = const Duration(seconds: 15),
    Random? random,
  })  : assert(names.length == 2),
        players = [for (final n in names) VersusPlayer(n, maxHp)],
        _deck = QuestionDeck(questions, random: random) {
    _current = _deck.draw();
  }

  /// 正解のもとのダメージ
  static const baseDamage = 18;

  /// はやおし（制限時間の3割以内）のボーナス
  static const fastBonus = 8;

  /// お手つきのダメージ
  static const missDamage = 6;

  final int maxHp;

  /// 最大の問題数
  final int rounds;
  final Duration timeLimit;
  final List<VersusPlayer> players;
  final QuestionDeck _deck;

  late PresentedQuestion _current;
  int _round = 1;

  /// この問題でお手つきした人
  final Set<int> _locked = {};
  final List<VersusTurn> turns = [];

  PresentedQuestion get current => _current;

  /// 何問目か（1始まり）
  int get round => _round;

  /// その人は、この問題でもう答えられないか
  bool isLocked(int side) => _locked.contains(side);

  bool get isOver => players.any((p) => p.down) || _round > rounds;

  /// 勝った人（引き分け・まだ決着していないなら null）
  int? get winner {
    if (!isOver) return null;
    final a = players[0], b = players[1];
    if (a.down && !b.down) return 1;
    if (b.down && !a.down) return 0;
    if (a.hp == b.hp) return null;
    return a.hp > b.hp ? 0 : 1;
  }

  /// [side] の人が [choice] を選んだ（[elapsed] は出題からの時間）
  VersusTurn answer(int side, int choice, {required Duration elapsed}) {
    if (isOver) throw StateError('対戦は終わっています');
    if (_locked.contains(side)) throw StateError('お手つきのあとは答えられません');
    final q = _current;
    final me = players[side];
    final you = players[1 - side];
    if (q.isCorrect(choice)) {
      me.correct++;
      me.combo++;
      me.maxCombo = max(me.maxCombo, me.combo);
      you.combo = 0;
      final fast = elapsed.inMilliseconds <= timeLimit.inMilliseconds * 0.3;
      final chain = 4 * (me.combo - 1);
      final int damage =
          baseDamage + (fast ? fastBonus : 0) + (chain > 12 ? 12 : chain);
      you.hp = max(0, you.hp - damage);
      final t = VersusTurn(
        side: side,
        question: q,
        correct: true,
        damage: damage,
        selfDamage: 0,
        chosen: choice,
        fast: fast,
        combo: me.combo,
        roundOver: true,
      );
      _next(t);
      return t;
    }
    me.misses++;
    me.combo = 0;
    me.hp = max(0, me.hp - missDamage);
    _locked.add(side);
    final over = _locked.length == 2 || me.down;
    final t = VersusTurn(
      side: side,
      question: q,
      correct: false,
      damage: 0,
      selfDamage: missDamage,
      chosen: choice,
      roundOver: over,
    );
    if (over) {
      _next(t);
    } else {
      turns.add(t);
    }
    return t;
  }

  /// [e] を今の状態で受け付けられるか（オンライン対戦で、先に届いた答えだけを通す）
  bool accepts(VersusEvent e) =>
      !isOver &&
      e.round == _round &&
      (e.side == -1 || (!_locked.contains(e.side) && e.choice != null));

  /// 記録された出来事を1つ進める（受け付けられないものは null）
  VersusTurn? apply(VersusEvent e) {
    if (!accepts(e)) return null;
    if (e.side == -1) return timeout();
    return answer(e.side, e.choice!, elapsed: Duration(milliseconds: e.ms));
  }

  /// 時間切れ（だれも正解しなかった）
  VersusTurn timeout() {
    if (isOver) throw StateError('対戦は終わっています');
    final t = VersusTurn(
      side: -1,
      question: _current,
      correct: false,
      damage: 0,
      selfDamage: 0,
      timedOut: true,
      roundOver: true,
    );
    _next(t);
    return t;
  }

  void _next(VersusTurn t) {
    turns.add(t);
    _locked.clear();
    _round++;
    if (!isOver) _current = _deck.draw();
  }
}

/// CPU の強さ
enum CpuLevel {
  easy('かんたん', 0.55, 4.0, 7.0),
  normal('ふつう', 0.7, 2.5, 5.0),
  hard('つよい', 0.85, 1.5, 3.5),
  master('達人', 0.95, 1.0, 2.5);

  const CpuLevel(this.label, this.accuracy, this.minSeconds, this.maxSeconds);
  final String label;

  /// 正解する確率
  final double accuracy;

  /// 答えるまでの時間（秒）のはば
  final double minSeconds;
  final double maxSeconds;
}

/// CPU の考え方（いつ・何を答えるか）
class VersusCpu {
  VersusCpu(this.level, {Random? random}) : _random = random ?? Random();

  final CpuLevel level;
  final Random _random;

  /// この問題に答えるまでの時間
  Duration thinkTime(PresentedQuestion q) {
    // 長い問題ほど少し時間がかかる
    final long =
        (q.source.prompt.length + (q.source.sentence?.length ?? 0)) / 200;
    final s = level.minSeconds +
        _random.nextDouble() * (level.maxSeconds - level.minSeconds) +
        long;
    return Duration(milliseconds: (s * 1000).round());
  }

  /// 選ぶ答え（[level] の確率で正解する）
  int choose(PresentedQuestion q, {Set<int> avoid = const {}}) {
    if (_random.nextDouble() < level.accuracy) return q.correctIndex;
    final wrong = [
      for (var i = 0; i < q.choices.length; i++)
        if (i != q.correctIndex && !avoid.contains(i)) i,
    ];
    return wrong.isEmpty
        ? q.correctIndex
        : wrong[_random.nextInt(wrong.length)];
  }
}

/// オンライン対戦で送り合う出来事（答え、または時間切れ）。
///
/// 2人とも同じ問題と同じシード（[VersusMatch] の random）から対戦を組み立て、
/// 出来事を同じ順番で当てはめるので、どちらの端末でも同じ結果になる。
class VersusEvent {
  const VersusEvent({
    required this.round,
    required this.side,
    this.choice,
    this.ms = 0,
  });

  /// 時間切れ
  const VersusEvent.timeout(this.round)
      : side = -1,
        choice = null,
        ms = 0;

  /// 何問目の出来事か
  final int round;

  /// 答えた人（時間切れは -1）
  final int side;
  final int? choice;

  /// 出題から答えるまでの時間（ミリ秒）
  final int ms;

  Map<String, dynamic> toMap() => {
        'r': round,
        's': side,
        if (choice != null) 'c': choice,
        'ms': ms,
      };

  factory VersusEvent.fromMap(Map<String, dynamic> m) => VersusEvent(
        round: (m['r'] as num).toInt(),
        side: (m['s'] as num).toInt(),
        choice: (m['c'] as num?)?.toInt(),
        ms: (m['ms'] as num?)?.toInt() ?? 0,
      );

  /// これまでの出来事のうち、受け付けられるものだけを当てはめた対戦
  static VersusMatch replay(
    VersusMatch fresh,
    Iterable<VersusEvent> events,
  ) {
    for (final e in events) {
      fresh.apply(e);
    }
    return fresh;
  }
}

/// オンライン対戦の部屋の設定（部屋を作った人が決める）
class VersusRoomConfig {
  const VersusRoomConfig({
    required this.setIds,
    required this.seed,
    required this.rounds,
  });

  /// 出題に使う問題セット（この順番で読みこむ）
  final List<String> setIds;
  final int seed;
  final int rounds;

  Map<String, dynamic> toMap() => {
        'setIds': setIds,
        'seed': seed,
        'rounds': rounds,
      };

  factory VersusRoomConfig.fromMap(Map<String, dynamic> m) => VersusRoomConfig(
        setIds: List<String>.from(m['setIds'] as List? ?? const []),
        seed: (m['seed'] as num?)?.toInt() ?? 0,
        rounds: (m['rounds'] as num?)?.toInt() ?? 15,
      );
}

/// 対戦の記録（進行状況の fieldFlags に残す。実績の判定に使う）
class VersusRecords {
  const VersusRecords._();

  /// 対戦を最後まで遊んだ
  static const played = 'vs:played';

  /// CPU の「つよい」以上に勝った
  static const beatHard = 'vs:beat:hard';

  /// CPU の「達人」に勝った
  static const beatMaster = 'vs:beat:master';

  /// オンライン対戦で勝った
  static const onlineWin = 'vs:online:win';

  /// 必殺技を決めた
  static const specialHit = 'special:hit';

  /// 対戦が終わったときにつける記録
  static Set<String> after({
    required bool won,
    CpuLevel? cpu,
    bool online = false,
  }) =>
      {
        played,
        if (won && cpu != null && cpu.index >= CpuLevel.hard.index) beatHard,
        if (won && cpu == CpuLevel.master) beatMaster,
        if (won && online) onlineWin,
      };
}
