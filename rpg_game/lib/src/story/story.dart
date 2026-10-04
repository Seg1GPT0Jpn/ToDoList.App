import '../data/catalog.dart';
import '../models/enemy.dart';
import '../models/rpg_progress.dart';
import '../models/stage.dart';

/// 教科の国ごとの物語
class WorldStory {
  const WorldStory({
    required this.worldId,
    required this.chapterTitle,
    required this.guardian,
    required this.guardianLook,
    required this.guardianColor,
    required this.fragment,
    required this.clearText,
  });

  final String worldId;

  /// 章の題（例：墨染めの森と沈黙の巨鳥）
  final String chapterTitle;

  /// その国の守護者（黒い霧に触れて狂気に呑まれ、国のボスになっている）
  final String guardian;

  /// 守護者の姿（enemy_painter の look）と色
  final String guardianLook;
  final int guardianColor;

  /// 正気にもどった守護者から託される「証」（5つそろうと天空の図書院がひらく）
  final String fragment;

  /// 国を救ったときの文
  final String clearText;
}

/// つづりクエストの世界の物語。
///
/// 世界の中心にそびえる大樹「アカデミア」。世界を調和させていた「理の輝石」が砕け散り、
/// その破片は黒い霧となって五つの国を侵食した。霧に触れた守護者たちは狂気に呑まれ、
/// 世界から「理解」が失われていく。残されたのは、まだ自らの文字を持たない見習い勇者と、
/// 白紙の聖典「スペル・グリモワール」だけだった。
///
/// 五つの国は好きな順に挑める。守護者を正気にもどして五つの証を集めると
/// 「天空の図書院」への光の柱があらわれ、虚無の霧ネブラとの決戦になる。
class Story {
  const Story._();

  static const title = '白紙の聖典と大樹アカデミア';

  static const prologue = [
    '世界の中心にそびえる大樹「アカデミア」。その幹に広がる無数の枝葉は、人々の知識や探求心と共鳴し、五つの豊かな国を抱えていた。',
    'かつて世界を調和させていた「理の輝石」が砕け散るまでは。',
    '砕けた石の破片は黒い霧へと変わり、五つの国を侵食した。霧に触れた守護者たちは狂気に呑まれ、世界から「理解」が失われていく。',
    '残されたのは、まだ自らの文字を持たない見習い勇者と、白紙の聖典「スペル・グリモワール」だけだった。',
    '剣で切り裂くのではない。乱れた理を正しく見極め、その真の名をグリモワールへ刻み直す――それが、世界を救う唯一の手段。',
    '五つの国へと続く転送門。どこから向かうかは、勇者自身の意志に委ねられている。',
  ];

  /// 国の順（第一章〜第五章。挑む順は自由）
  static const worlds = <WorldStory>[
    WorldStory(
      worldId: 'japanese',
      chapterTitle: '墨染めの森と沈黙の巨鳥',
      guardian: '巨鳥カラスバ',
      guardianLook: 'bird',
      guardianColor: 0xFF2A2A3A,
      fragment: '言霊の羽ペン',
      clearText: '純白の羽を取りもどしたカラスバから、柔らかな風を宿す「言霊の羽ペン」を託された。',
    ),
    WorldStory(
      worldId: 'math',
      chapterTitle: '狂った天秤と永久の歯車',
      guardian: 'カラクリ・ゴーレム',
      guardianLook: 'golem',
      guardianColor: 0xFF9C7A3C,
      fragment: '黄金の歯車',
      clearText: '等号は美しく結ばれた。ゴーレムの胸から、完璧な対称性を誇る「黄金の歯車」を受け取った。',
    ),
    WorldStory(
      worldId: 'english',
      chapterTitle: '閉ざされた海峡と孤独な怪獣',
      guardian: 'バベル・リヴァイアサン',
      guardianLook: 'leviathan',
      guardianColor: 0xFF2B5F8A,
      fragment: '通訳の羅針盤',
      clearText: '海は凪ぎ、嵐は消え去った。波間から「通訳の羅針盤」が託された。',
    ),
    WorldStory(
      worldId: 'science',
      chapterTitle: '乱れる天秤と暴走のキメラ',
      guardian: 'カオス・エレメンタル',
      guardianLook: 'dragon',
      guardianColor: 0xFF7A3FA0,
      fragment: '元素の天球儀',
      clearText: '混沌に安らぎがもどった。光の球は、四季の巡りを宿す「元素の天球儀」となった。',
    ),
    WorldStory(
      worldId: 'social',
      chapterTitle: '砂に埋もれる記憶と幽幻の騎士',
      guardian: 'クロノス・ナイト',
      guardianLook: 'knight',
      guardianColor: 0xFF6B5B45,
      fragment: '悠久の砂時計',
      clearText: '錆びた鎧が剥がれ、誇り高き黄金の甲冑が現れた。騎士は片膝をつき「悠久の砂時計」を差し出した。',
    ),
  ];

  static WorldStory of(String worldId) =>
      worlds.firstWhere((w) => w.worldId == worldId);

  /// その国のルートの最後のステージ（すべての道の果てで守護者に勝つと証が手に入る）
  static List<StageDef> finalsOf(String worldId) {
    final w = RpgCatalog.world(worldId);
    final last = <String, StageDef>{};
    for (final s in w.stages) {
      last[s.branch] = s;
    }
    return last.values.toList();
  }

  /// 手に入れた証（国の ID）
  static Set<String> fragments(RpgProgress p) => {
        for (final w in worlds)
          if (finalsOf(w.worldId)
              .every((s) => p.clearedStageIds.contains(s.id)))
            w.worldId,
      };

  /// 天空の図書院への扉がひらいたか
  static bool centerOpen(RpgProgress p) => fragments(p).length == worlds.length;

  static const centerStageId = 'world_center_final';

  /// 天空の図書院の決戦。5つの国の最後のボスの範囲すべてから出題する（小中学校の総まとめ）
  static StageDef centerStage() {
    final sets = <String>[];
    for (final w in worlds) {
      for (final s in finalsOf(w.worldId)) {
        for (final id in s.questionSetIds) {
          if (!sets.contains(id)) sets.add(id);
        }
      }
    }
    return StageDef(
      id: centerStageId,
      worldId: 'english',
      order: 1,
      name: '天空の図書院',
      region: '天空の図書院',
      isBoss: true,
      enemy: const EnemyDef(
        id: 'nebra',
        name: '虚無の霧ネブラ',
        maxHp: 2600,
        attack: 60,
        look: 'ghost',
        color: 0xFF4A4660,
        description:
            '天空の図書院の台座に渦巻く、底知れぬ黒い霧。「めんどくさい」「意味がない」という甘い毒を心に注ぎこむ。5教科すべての問いで立ちはだかる。',
        introLine: 'よくぞここまで無駄な足掻きを重ねたものだ。考えることをやめれば、どれほど楽になれるか。',
        defeatLine: '暗闇が……朝焼けの色に……染まっていく……。',
      ),
      questionSetIds: sets,
      expReward: 1000,
      timeLimitSeconds: 25,
      readingTimeLimitSeconds: 70,
      recommendedLevel: 40,
      grammarTheme: '小中学校の総まとめ（5教科）',
      vocabLevel: '全範囲',
    );
  }
}
