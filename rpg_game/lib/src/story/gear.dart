import '../learning/learning_record.dart';
import '../models/rpg_progress.dart';
import 'story.dart';

enum GearSlot {
  weapon('武器'),
  armor('防具'),
  accessory('アクセサリー');

  const GearSlot(this.label);
  final String label;
}

/// 装備。レア度を競うものではなく、学習内容と結びついた効果をもつ
/// （例：数学のバトルで与えるダメージ +15%）。
class GearDef {
  const GearDef({
    required this.id,
    required this.name,
    required this.slot,
    required this.description,
    required this.howToGet,
    this.attack = 0,
    this.defense = 0,
    this.subject,
    this.subjectRate = 0,
    this.extraSeconds = 0,
    this.level = 0,
  });

  final String id;
  final String name;
  final GearSlot slot;
  final String description;

  /// 手に入れ方
  final String howToGet;
  final int attack;
  final int defense;

  /// この教科のバトルで、与えるダメージが [subjectRate] ぶん増える
  final String? subject;
  final double subjectRate;

  /// 制限時間がのびる（秒）
  final int extraSeconds;

  /// このレベルになると手に入る（0 はレベルで手に入る装備ではない）
  final int level;

  static const all = <GearDef>[
    GearDef(
      id: 'wood_pen',
      name: '木のペン',
      slot: GearSlot.weapon,
      description: '攻撃 +2',
      howToGet: '最初から持っている',
      attack: 2,
    ),
    GearDef(
      id: 'silver_pen',
      name: '銀のペン',
      slot: GearSlot.weapon,
      description: '攻撃 +5',
      howToGet: 'Lv10 になると手に入る',
      attack: 5,
      level: 10,
    ),
    GearDef(
      id: 'gold_pen',
      name: '金のペン',
      slot: GearSlot.weapon,
      description: '攻撃 +9',
      howToGet: 'Lv25 になると手に入る',
      attack: 9,
      level: 25,
    ),
    GearDef(
      id: 'star_pen',
      name: '星のペン',
      slot: GearSlot.weapon,
      description: '攻撃 +14',
      howToGet: 'Lv40 になると手に入る',
      attack: 14,
      level: 40,
    ),
    GearDef(
      id: 'leather_cover',
      name: '革の表紙の鎧',
      slot: GearSlot.armor,
      description: '防御 +5',
      howToGet: 'Lv15 になると手に入る',
      defense: 5,
      level: 15,
    ),
    GearDef(
      id: 'hard_cover',
      name: '上製本の鎧',
      slot: GearSlot.armor,
      description: '防御 +10',
      howToGet: 'Lv35 になると手に入る',
      defense: 10,
      level: 35,
    ),
    GearDef(
      id: 'note_armor',
      name: 'ノートの鎧',
      slot: GearSlot.armor,
      description: '防御 +2',
      howToGet: '最初から持っている',
      defense: 2,
    ),
    GearDef(
      id: 'dict_sword',
      name: '辞書の剣',
      slot: GearSlot.weapon,
      description: '英語のバトルでダメージ +15%',
      howToGet: '英語の国で「ことばの欠片」を取りもどす',
      subject: 'english',
      subjectRate: 0.15,
    ),
    GearDef(
      id: 'flask_staff',
      name: 'フラスコの杖',
      slot: GearSlot.weapon,
      description: '理科のバトルでダメージ +15%',
      howToGet: '理の国で「ことわりの欠片」を取りもどす',
      subject: 'science',
      subjectRate: 0.15,
    ),
    GearDef(
      id: 'timeline_spear',
      name: '年表の槍',
      slot: GearSlot.weapon,
      description: '社会のバトルでダメージ +15%',
      howToGet: '時と地の国で「時の欠片」を取りもどす',
      subject: 'social',
      subjectRate: 0.15,
    ),
    GearDef(
      id: 'brush_blade',
      name: '筆の刀',
      slot: GearSlot.weapon,
      description: '国語のバトルでダメージ +15%',
      howToGet: '言の葉の国で「言の葉の欠片」を取りもどす',
      subject: 'japanese',
      subjectRate: 0.15,
    ),
    GearDef(
      id: 'formula_pen',
      name: '数式のペン',
      slot: GearSlot.weapon,
      description: '数学のバトルでダメージ +15%',
      howToGet: '数の国で「数の欠片」を取りもどす',
      subject: 'math',
      subjectRate: 0.15,
    ),
    GearDef(
      id: 'sticky_cape',
      name: '付箋のマント',
      slot: GearSlot.armor,
      description: '防御 +5',
      howToGet: '7日つづけて勉強する',
      defense: 5,
    ),
    GearDef(
      id: 'clock_brooch',
      name: '時計のブローチ',
      slot: GearSlot.accessory,
      description: '制限時間 +2秒',
      howToGet: '3日つづけて勉強する',
      extraSeconds: 2,
    ),
    GearDef(
      id: 'streak_crown',
      name: '継続の冠',
      slot: GearSlot.accessory,
      description: '攻撃 +4・防御 +4',
      howToGet: '30日つづけて勉強する',
      attack: 4,
      defense: 4,
    ),
  ];

  static GearDef byId(String id) => all.firstWhere((g) => g.id == id);

  static const starter = {'wood_pen', 'note_armor'};

  /// 欠片で手に入る装備（国 ID → 装備 ID）
  static const byFragment = {
    'english': 'dict_sword',
    'science': 'flask_staff',
    'social': 'timeline_spear',
    'japanese': 'brush_blade',
    'math': 'formula_pen',
  };
}

/// 職業。ずっと効く効果が1つだけつく（あとから何度でも変えられる）
enum JobDef {
  adventurer('冒険者', 'とくになし（まずはここから）'),
  warrior('戦士', '攻撃型：与えるダメージ +10%'),
  guardian('守護者', '防御型：受けるダメージ -15%'),
  sage('賢者', '弱点攻撃型：弱点をついたときのダメージがさらに +30%'),
  mage('魔導士', 'コンボ型：3連続正解から、ダメージがさらに +20%');

  const JobDef(this.label, this.description);
  final String label;
  final String description;

  static JobDef parse(String? name) =>
      values.where((j) => j.name == name).firstOrNull ?? adventurer;
}

/// 連続学習のごほうび（毎日の勉強を圧迫しない、ゆるいごほうび）
class StreakReward {
  const StreakReward({
    required this.id,
    required this.days,
    required this.label,
    this.cardId,
    this.gearId,
  });

  final String id;
  final int days;
  final String label;
  final String? cardId;
  final String? gearId;

  static const all = [
    StreakReward(
        id: 'streak3',
        days: 3,
        label: '時計のブローチ＋カード「時の砂」',
        cardId: 'time',
        gearId: 'clock_brooch'),
    StreakReward(
        id: 'streak7',
        days: 7,
        label: '付箋のマント＋カード「会心のペン」',
        cardId: 'critical',
        gearId: 'sticky_cape'),
    StreakReward(
        id: 'streak30', days: 30, label: '継続の冠（特別な装備）', gearId: 'streak_crown'),
  ];
}

/// 装備・職業・ごほうびの計算
class Gear {
  const Gear._();

  /// 持っている装備（最初の装備・欠片の装備・受け取ったごほうびの装備）
  static Set<String> owned(RpgProgress p) => {
        ...GearDef.starter,
        for (final g in GearDef.all)
          if (g.level > 0 && p.level >= g.level) g.id,
        for (final w in Story.fragments(p)) GearDef.byFragment[w]!,
        ...p.gear,
      };

  /// 装備しているもの（持っていないものは外す）
  static List<GearDef> equipped(RpgProgress p) {
    final have = owned(p);
    return [
      for (final slot in GearSlot.values)
        if (p.equipped[slot.name] case final id? when have.contains(id))
          GearDef.byId(id)
        // 選んでいなければ、レベルで手に入った一番よい装備をつける
        else if (slot == GearSlot.weapon || slot == GearSlot.armor)
          _bestByLevel(p, slot),
    ];
  }

  static GearDef _bestByLevel(RpgProgress p, GearSlot slot) {
    var best =
        GearDef.byId(slot == GearSlot.weapon ? 'wood_pen' : 'note_armor');
    for (final g in GearDef.all) {
      if (g.slot == slot && g.level > 0 && p.level >= g.level) {
        if (g.attack + g.defense > best.attack + best.defense) best = g;
      }
    }
    return best;
  }

  /// 受け取れる連続学習のごほうび
  static List<StreakReward> claimable(
      RpgProgress p, LearningRecord r, int today) {
    final streak = r.streakDays(today);
    return [
      for (final s in StreakReward.all)
        if (streak >= s.days && !p.claimedRewards.contains(s.id)) s,
    ];
  }

  /// ごほうびを受け取った進行状況
  static RpgProgress claim(RpgProgress p, StreakReward s) => p.copyWith(
        claimedRewards: {...p.claimedRewards, s.id},
        deck: s.cardId == null ? p.deck : [...p.deck, s.cardId!],
        gear: s.gearId == null ? p.gear : {...p.gear, s.gearId!},
      );

  /// バトルの補正（装備と職業）
  static BattleBonus bonusFor(RpgProgress p, String subject) {
    final gear = equipped(p);
    final job = JobDef.parse(p.job);
    return BattleBonus(
      attack: gear.fold(0, (a, g) => a + g.attack),
      defense: gear.fold(0, (a, g) => a + g.defense),
      attackRate: 1 +
          gear
              .where((g) => g.subject == subject)
              .fold(0.0, (a, g) => a + g.subjectRate) +
          (job == JobDef.warrior ? 0.1 : 0),
      damageTakenRate: job == JobDef.guardian ? 0.85 : 1,
      weaknessBonus: job == JobDef.sage ? 0.3 : 0,
      chainBonus: job == JobDef.mage ? 0.2 : 0,
      extraSeconds: gear.fold(0, (a, g) => a + g.extraSeconds),
    );
  }
}

/// バトルにかかる装備・職業の補正
class BattleBonus {
  const BattleBonus({
    this.attack = 0,
    this.defense = 0,
    this.attackRate = 1,
    this.damageTakenRate = 1,
    this.weaknessBonus = 0,
    this.chainBonus = 0,
    this.extraSeconds = 0,
  });

  static const none = BattleBonus();

  final int attack;
  final int defense;

  /// 正解したときのダメージの倍率
  final double attackRate;

  /// 受けるダメージの倍率
  final double damageTakenRate;

  /// 弱点の倍率に足す値
  final double weaknessBonus;

  /// 3連続正解から足す倍率
  final double chainBonus;
  final int extraSeconds;
}
